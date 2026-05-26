const db = require('../config/db');
const emailService = require('../utils/emailService');
const { createNotification } = require('../utils/notificationHelper');
const vnpayService = require('../utils/vnpayService');
const momoService = require('../utils/momoService');
const seatLockService = require('../utils/seatLockService');
const voucherController = require('./voucherController');
// io được require lazy để tránh circular dependency
function getIO() { try { return require('../server').io; } catch { return null; } }

// Lấy danh sách Rạp phim
exports.getTheaters = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM rapphim');
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất hệ thống Rạp' });
    }
}

// Lấy chi tiết Phòng rạp và Danh sách Ghế
exports.getTheaterRoomsAndSeats = async (req, res) => {
    try {
        const { showtimeId } = req.params;
        
        // 1. Lấy thông tin Lịch chiếu -> JOIN để lấy Tên Phòng và Tên Rạp
        const showtimeQuery = `
            SELECT lc.*, pr.tenphong, r.tenrapphim, r.diachi
            FROM lichchieu lc
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE lc.malichchieu = $1
        `;
        const showtimeRes = await db.query(showtimeQuery, [showtimeId]);
        if (showtimeRes.rows.length === 0) return res.status(404).json({ status: 'error', message: 'Không tìm thấy suất chiếu' });
        
        const showtime = showtimeRes.rows[0];
        
        // 2. Lấy danh sách ghế của phòng đó
        const seatsRes = await db.query('SELECT * FROM ghengoi WHERE maphong = $1 ORDER BY mahangghe, soghe', [showtime.maphong]);
        
        // 3. Lấy ghế ĐÃ ĐẶT từ DB (chỉ active)
        const queryBookedSeats = `
            SELECT v.maghe 
            FROM vexemphim v
            WHERE v.malichchieu = $1 
              AND v.trangthai = 'active'
        `;
        const bookedSeatsRes = await db.query(queryBookedSeats, [showtimeId]);
        const bookedSeatIds = bookedSeatsRes.rows.map(row => row.maghe);

        // 4. Lấy ghế đang bị LOCK trong Redis (đang trong quá trình chọn)
        let lockedSeats = [];
        try {
            lockedSeats = await seatLockService.getLockedSeats(showtimeId);
        } catch (redisErr) {
            console.warn('[Redis] Không lấy được locked seats, bỏ qua:', redisErr.message);
        }
        const lockedMap = {};
        lockedSeats.forEach(ls => { lockedMap[ls.seatId] = ls.lockedBy; });

        // Lấy userId từ token nếu có (để phân biệt ghế mình lock vs người khác)
        const currentUserId = req.user ? String(req.user.id) : null;

        // 5. Map trạng thái ghế (merge DB + Redis)
        const seats = seatsRes.rows.map(seat => {
            const seatId = seat.maghe;
            const isBookedDB = bookedSeatIds.includes(seatId);
            const lockedBy = lockedMap[seatId];
            const isLockedByMe = currentUserId && lockedBy === currentUserId;
            const isLockedByOther = !!lockedBy && !isLockedByMe;
            return {
                ...seat,
                isBooked: isBookedDB || isLockedByOther, // Ghế DB active OR bị người khác lock
                isLockedByMe,     // Ghế mình đang giữ (màu xanh chọn)
                isLockedByOther,  // Ghế người khác đang giữ (màu cam)
            };
        });

        res.json({
            status: 'success',
            data: {
                showtime: showtime,
                seats: seats
            }
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất hệ thống Ghế ngồi' });
    }
}

// Lấy Lịch chiếu phim (Có thể lọc theo Ngày, theo Rạp, theo Phim)
exports.getShowtimes = async (req, res) => {
    try {
        const { date, theaterId, movieId } = req.query;
        let query = `
            SELECT lc.*, p.tenphim, r.tenrapphim, pr.tenphong 
            FROM lichchieu lc
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
        `;
        let conditions = [];
        let params = [];
        let paramIndex = 1;

        if (date) {
            conditions.push(`DATE(lc.ngaychieu) = $${paramIndex}`);
            params.push(date);
            paramIndex++;
        }

        if (theaterId) {
            conditions.push(`r.marapphim = $${paramIndex}`);
            params.push(theaterId);
            paramIndex++;
        }

        if (movieId) {
            conditions.push(`lc.maphim = $${paramIndex}`);
            params.push(movieId);
            paramIndex++;
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }
        
        query += ' ORDER BY lc.ngaychieu, lc.giochieu';

        const result = await db.query(query, params);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất lịch chiếu' });
    }
};

// API: Tạo Đơn Đặt Vé (Redis-based — KHÔNG write DB cho đến khi thanh toán thành công)
exports.createBooking = async (req, res) => {
    try {
        const { showtimeId, seatIds, paymentMethod, concessions, mavoucher } = req.body;
        const userId = String(req.user.id);

        if (!seatIds || seatIds.length === 0) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng chọn ít nhất 1 ghế' });
        }

        if (seatIds.length > 6) {
            return res.status(400).json({ status: 'error', message: 'Bạn chỉ được chọn tối đa 6 ghế' });
        }

        // 1. Xác minh tất cả ghế đang được lock bởi user này trong Redis
        const userLockedSeats = await seatLockService.getUserLockedSeats(showtimeId, userId);
        const missingLocks = seatIds.filter(id => !userLockedSeats.includes(id));
        
        if (missingLocks.length > 0) {
            return res.status(400).json({ 
                status: 'error', 
                message: `Ghế ${missingLocks.join(', ')} chưa được lock. Vui lòng chọn lại ghế!` 
            });
        }

        // 2. Kiểm tra ghế trong DB (đã active chưa — double check)
        const checkSeatsQuery = `
            SELECT v.maghe FROM vexemphim v
            WHERE v.malichchieu = $1 AND v.maghe = ANY($2::varchar[]) AND v.trangthai = 'active'
        `;
        const checkSeatsRes = await db.query(checkSeatsQuery, [showtimeId, seatIds]);
        if (checkSeatsRes.rows.length > 0) {
            return res.status(400).json({ status: 'error', message: 'Một số ghế đã được đặt. Vui lòng chọn ghế khác!' });
        }

        // 3. Tính tiền vé (READ-ONLY từ DB)
        const showtimeRes = await db.query('SELECT giave, maphim FROM lichchieu WHERE malichchieu = $1', [showtimeId]);
        if (showtimeRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy suất chiếu' });
        }
        const basePrice = showtimeRes.rows[0].giave;
        const maphim = showtimeRes.rows[0].maphim;

        const seatRes = await db.query('SELECT maghe, hesogiaghe FROM ghengoi WHERE maghe = ANY($1::varchar[])', [seatIds]);
        if (seatRes.rows.length !== seatIds.length) {
            return res.status(400).json({ status: 'error', message: 'Một hoặc nhiều ghế không hợp lệ.' });
        }

        let ticketPriceTotal = 0;
        const seatPrices = {};
        for (let sId of seatIds) {
            let seat = seatRes.rows.find(s => String(s.maghe).trim() === String(sId).trim());
            if (!seat) {
                return res.status(400).json({ status: 'error', message: `Không tìm thấy thông tin giá cho ghế: ${sId}` });
            }
            const price = basePrice * seat.hesogiaghe;
            ticketPriceTotal += price;
            seatPrices[sId] = price;
        }

        // 4. Tính tiền bắp nước (READ-ONLY từ DB)
        let concessionPrice = 0;
        let concessionDetails = [];
        if (concessions && concessions.length > 0) {
            for (let c of concessions) {
                if (c.comboId) {
                    const comboRes = await db.query('SELECT price FROM combos WHERE combo_id = $1', [c.comboId]);
                    if (comboRes.rows.length > 0) {
                        const price = comboRes.rows[0].price;
                        concessionPrice += price * c.quantity;
                        concessionDetails.push({ ...c, price });
                    }
                } else if (c.itemId) {
                    const itemRes = await db.query('SELECT price FROM items WHERE item_id = $1', [c.itemId]);
                    if (itemRes.rows.length > 0) {
                        const price = itemRes.rows[0].price;
                        concessionPrice += price * c.quantity;
                        concessionDetails.push({ ...c, price });
                    }
                }
            }
        }

        const subtotal = ticketPriceTotal + concessionPrice;

        // 4.5. Tính toán giảm giá Voucher và Rank
        const discountResult = await voucherController.internalCalculateDiscount(userId, subtotal, mavoucher, maphim);

        // Nếu người dùng nhập mã voucher nhưng không áp dụng thành công được (voucher không hợp lệ/đủ điều kiện)
        if (mavoucher && !discountResult.appliedVoucherCode) {
            const voucherRes = await db.query(
                `SELECT * FROM khuyen_mai WHERE ma_khuyen_mai = $1`,
                [mavoucher]
            );
            if (voucherRes.rows.length === 0) {
                return res.status(400).json({ status: 'error', message: 'Mã giảm giá không tồn tại hoặc đã hết hạn' });
            }
            const v = voucherRes.rows[0];
            if (v.trang_thai !== 'ACTIVE' || new Date(v.ngay_bat_dau) > new Date() || new Date(v.ngay_ket_thuc) < new Date()) {
                return res.status(400).json({ status: 'error', message: 'Mã giảm giá đã hết hạn hoặc ngưng hoạt động' });
            }
            if (v.so_luong_ma > 0 && v.so_luong_da_dung >= v.so_luong_ma) {
                return res.status(400).json({ status: 'error', message: 'Mã giảm giá này đã hết lượt sử dụng' });
            }
            // Check usage
            const historyRes = await db.query(
                'SELECT COUNT(*) FROM lich_su_khuyen_mai WHERE id_khuyen_mai = $1 AND id_khach = $2',
                [v.id, userId]
            );
            if (parseInt(historyRes.rows[0].count) >= 1) {
                return res.status(400).json({ status: 'error', message: 'Bạn đã sử dụng mã giảm giá này rồi' });
            }
            // Check rank
            if (v.ap_dung_user && v.ap_dung_user !== 'TAT_CA_USER') {
                const RANK_PRIORITY = { 'BRONZE': 0, 'MEMBER': 0, 'SILVER': 1, 'GOLD': 2, 'DIAMOND': 3 };
                const RANK_NAMES_VI = { 'BRONZE': 'Đồng', 'MEMBER': 'Đồng', 'SILVER': 'Bạc', 'GOLD': 'Vàng', 'DIAMOND': 'Kim Cương' };
                const { rank: userRank } = await voucherController.getUserRankInfo(userId);
                const reqPriority = RANK_PRIORITY[v.ap_dung_user] || 0;
                const userPriority = RANK_PRIORITY[userRank] || 0;
                if (userPriority < reqPriority) {
                    const reqRankName = RANK_NAMES_VI[v.ap_dung_user] || v.ap_dung_user;
                    return res.status(400).json({ status: 'error', message: `Mã giảm giá này yêu cầu cấp bậc tối thiểu là hạng ${reqRankName}` });
                }
            }
            // Check min spend
            if (subtotal < parseFloat(v.gia_tri_don_hang_toi_thieu)) {
                const gap = parseFloat(v.gia_tri_don_hang_toi_thieu) - subtotal;
                return res.status(400).json({ status: 'error', message: `Bạn cần mua thêm ${gap.toLocaleString('vi-VN')}đ để áp dụng mã này` });
            }
            // Check movie
            if (v.ap_dung_cho === 'PHIM_CU_THE' && maphim) {
                const phimRes = await db.query(
                    'SELECT 1 FROM khuyen_mai_phim WHERE id_khuyen_mai = $1 AND maphim = $2',
                    [v.id, maphim]
                );
                if (phimRes.rows.length === 0) {
                    return res.status(400).json({ status: 'error', message: 'Mã giảm giá này không áp dụng cho bộ phim bạn đã chọn' });
                }
            }
            return res.status(400).json({ status: 'error', message: 'Mã giảm giá không hợp lệ cho đơn hàng này' });
        }

        const totalPrice = discountResult.finalAmount;

        // 5. Sinh mã đơn hàng (dùng làm sessionId cho payment gateway)
        const maDonDatVe = 'DON' + Date.now().toString().slice(-6);

        // 6. Lưu session tạm vào Redis (KHÔNG write DB)
        const sessionData = {
            maDonDatVe,
            userId,
            showtimeId,
            seatIds,
            seatPrices,
            basePrice,
            concessionDetails,
            totalPrice,
            originalTotalPrice: subtotal,
            ticketPriceTotal,
            concessionPrice,
            paymentMethod: paymentMethod || 'momo',
            createdAt: new Date().toISOString(),
            // Thêm các thông tin ưu đãi để lưu khi thanh toán thành công
            voucherId: discountResult.voucherId,
            appliedVoucherCode: discountResult.appliedVoucherCode,
            sotienDuocGiamVoucher: discountResult.sotienDuocGiamVoucher,
            userRank: discountResult.rank,
            rankDiscountRate: discountResult.rankDiscountRate,
            sotienGiamRank: discountResult.sotienGiamRank,
            totalDiscount: discountResult.totalDiscount
        };
        await seatLockService.createTempBooking(maDonDatVe, sessionData);

        // 7. Gia hạn TTL cho các seat locks (đảm bảo ghế không hết hạn trước khi thanh toán xong)
        await seatLockService.extendUserLocks(showtimeId, userId);

        // 8. Tạo URL thanh toán
        let paymentUrl = null;
        if (paymentMethod === 'vnpay') {
            const ipAddr = req.headers['x-forwarded-for'] || 
                           req.connection?.remoteAddress || 
                           req.socket?.remoteAddress || '127.0.0.1';
            paymentUrl = vnpayService.buildPaymentUrl(
                maDonDatVe, totalPrice,
                `Thanh toan ve xem phim DON ${maDonDatVe}`, ipAddr
            );
        } else if (paymentMethod === 'momo') {
            paymentUrl = await momoService.createPaymentUrl(
                maDonDatVe, totalPrice,
                `Thanh toan ve xem phim DON ${maDonDatVe}`
            );
        }

        // Đã dời thông báo sang sau khi thanh toán thành công để tránh lỗi Foreign Key

                const TTL = seatLockService.TTL;
        // Kiểm tra có yêu cầu preview (lưu và trả về đơn ngay) không
        const preview = req.query.preview === 'true' || req.query.preview === '1';
        if (preview) {
            // Gọi hàm cập nhật đơn vào DB ngay lập tức (không cần chờ IPN)
            await updateOrderAfterPayment(maDonDatVe, 'TEST_TRANS');
            // Lấy thông tin đơn đã lưu
            const orderRes = await db.query('SELECT * FROM dondatve WHERE madondatve = $1', [maDonDatVe]);
            const orderData = orderRes.rows[0] || {};
            return res.status(201).json({
                status: 'success',
                message: `Đơn hàng đã được tạo và lưu (preview).`,
                data: {
                    maDonDatVe,
                    totalPrice,
                    paymentUrl,
                    expiresAt: new Date(Date.now() + TTL * 1000).toISOString(),
                    order: orderData
                }
            });
        }
        // Trường hợp không preview – trả về thông tin giữ ghế và URL thanh toán như bình thường
        res.status(201).json({ 
            status: 'success', 
            message: `Giữ ghế thành công! Vui lòng hoàn tất thanh toán trong ${Math.floor(TTL/60)} phút.`, 
            data: { 
                maDonDatVe,
                totalPrice,
                paymentUrl,
                expiresAt: new Date(Date.now() + TTL * 1000).toISOString()
            } 
        });

    } catch (e) {
        console.error("Booking Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi giao dịch đặt vé' });
    }
};

// API: Xác nhận thanh toán (Chuyển trạng thái từ pending sang active)
exports.confirmPayment = async (req, res) => {
    const client = await db.connect();
    try {
        const { maThanhToan } = req.body;
        
        if (!maThanhToan) {
            return res.status(400).json({ status: 'error', message: 'Thiếu mã thanh toán' });
        }

        await client.query('BEGIN');

        // 1. Tìm thông tin thanh toán và đơn hàng liên quan
        const paymentCheckQuery = `
            SELECT t.madondatve, t.sotienthanhtoan 
            FROM thongtinthanhtoan t
            JOIN dondatve d ON t.madondatve = d.madondatve
            WHERE t.mathanhtoan = $1 AND t.trangthai = 'pending' AND d.id_khach = $2
        `;
        const paymentRes = await client.query(paymentCheckQuery, [maThanhToan, req.user.id]);

        if (paymentRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy thông tin thanh toán hoặc đã được xử lý' });
        }

        const maDonDatVe = paymentRes.rows[0].madondatve;

        // 2. Cập nhật trạng thái Thanh toán
        await client.query(
            "UPDATE thongtinthanhtoan SET trangthai = 'success', thoidiemthanhtoan = CURRENT_TIMESTAMP WHERE mathanhtoan = $1",
            [maThanhToan]
        );

        // 3. Cập nhật trạng thái Đơn đặt vé
        const updateDonRes = await client.query(
            "UPDATE dondatve SET trangthai = 'paid' WHERE madondatve = $1 AND trangthai = 'pending' RETURNING *",
            [maDonDatVe]
        );

        if (updateDonRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng tương ứng hoặc đã được xử lý' });
        }

        // 4. Cập nhật trạng thái các Vé thuộc đơn hàng
        await client.query(
            "UPDATE vexemphim SET trangthai = 'active' WHERE madondatve = $1",
            [maDonDatVe]
        );

        await client.query('COMMIT');

        // Gửi Email thông báo (Chạy async sau khi đã commit thành công)
        (async () => {
            try {
                const bookingDetailsQuery = `
                    SELECT d.madondatve, d.tongtien, t.email,
                           p.tenphim, p.poster_url,
                           lc.ngaychieu, lc.giochieu,
                           r.tenrapphim, pr.tenphong,
                           string_agg(v.maghe, ', ') as seats
                    FROM dondatve d
                    JOIN thongtintaikhoan t ON d.id_khach = t.id_khach
                    JOIN vexemphim v ON d.madondatve = v.madondatve
                    JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
                    JOIN phim p ON lc.maphim = p.maphim
                    JOIN phongrapphim pr ON lc.maphong = pr.maphong
                    JOIN rapphim r ON pr.marapphim = r.marapphim
                    WHERE d.madondatve = $1
                    GROUP BY d.madondatve, d.tongtien, t.email, p.tenphim, p.poster_url, lc.ngaychieu, lc.giochieu, r.tenrapphim, pr.tenphong
                `;
                const detailsRes = await db.query(bookingDetailsQuery, [maDonDatVe]);
                
                if (detailsRes.rows.length > 0) {
                    const d = detailsRes.rows[0];
                    await emailService.sendBookingSuccessEmail(d.email, {
                        maDonDatVe: d.madondatve,
                        tenPhim: d.tenphim,
                        ngayChieu: d.ngaychieu instanceof Date ? d.ngaychieu.toLocaleDateString('vi-VN') : d.ngaychieu,
                        gioChieu: d.giochieu instanceof Date ? d.giochieu.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : d.giochieu,
                        tenRapPhim: d.tenrapphim,
                        tenPhong: d.tenphong,
                        seats: d.seats.split(', '),
                        tongTien: d.tongtien,
                        poster_url: d.poster_url
                    });
                }
            } catch (err) {
                console.error("Async Email Error:", err);
            }
        })();

        res.json({ 
            status: 'success', 
            message: 'Thanh toán và xác nhận đặt vé thành công!',
            data: updateDonRes.rows[0]
        });

    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Confirm Payment Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi xác nhận thanh toán' });
    } finally {
        client.release();
    }
};

// VNPay Return: Xử lý sau khi người dùng thanh toán xong và được redirect về Web/App
exports.vnpayReturn = async (req, res) => {
    try {
        console.log("--- VNPAY RETURN RECEIVED ---", req.query);
        const verify = vnpayService.verifyReturnUrl(req.query);
        
        if (verify.isSuccess) {
            const { vnp_TxnRef, vnp_TransactionNo, vnp_ResponseCode } = req.query;
            
            if (vnp_ResponseCode === '00') {
                // Cập nhật Database ngay tại đây làm phương án dự phòng cho IPN
                await updateOrderAfterPayment(vnp_TxnRef, vnp_TransactionNo);
                console.log(`VNPay Return Success: Order ${vnp_TxnRef} updated via Return URL.`);
            }

            res.send(`
                <html>
                    <body style="text-align: center; padding-top: 50px; font-family: sans-serif;">
                        <h1 style="color: green;">Thanh toán VNPay thành công!</h1>
                        <p>Đơn hàng ${vnp_TxnRef} đã được xử lý.</p>
                        <p>Bạn có thể đóng trình duyệt này và quay lại ứng dụng.</p>
                        <script>
                            setTimeout(() => {
                                window.close();
                            }, 3000);
                        </script>
                    </body>
                </html>
            `);
        } else {
            res.send(`
                <html>
                    <body style="text-align: center; padding-top: 50px; font-family: sans-serif;">
                        <h1 style="color: red;">Thanh toán VNPay thất bại</h1>
                        <p>Lỗi: ${verify.message}</p>
                        <a href="/">Quay về trang chủ</a>
                    </body>
                </html>
            `);
        }
    } catch (e) {
        console.error("VNPay Return Error:", e);
        res.status(500).send("Lỗi xử lý kết quả VNPay");
    }
};

// VNPay IPN: Xử lý thông báo server-to-server từ VNPay (QUAN TRỌNG)
exports.vnpayIpn = async (req, res) => {
    console.log("--- VNPAY IPN RECEIVED ---");
    console.log("Query Params:", JSON.stringify(req.query, null, 2));
    
    const client = await db.connect();
    try {
        const verify = vnpayService.verifyReturnUrl(req.query);
        console.log("Verify Result:", verify);
        
        if (!verify.isSuccess) {
            console.error("VNPAY IPN Checksum Failed");
            return res.status(200).json({ RspCode: '97', Message: 'Checksum failed' });
        }

        const { vnp_TxnRef, vnp_Amount, vnp_ResponseCode, vnp_TransactionNo } = req.query;
        const maDonDatVe = vnp_TxnRef;
        const amount = parseInt(vnp_Amount) / 100;

        await client.query('BEGIN');

        // 1. Kiểm tra đơn hàng có tồn tại không
        const orderRes = await client.query('SELECT * FROM dondatve WHERE madondatve = $1', [maDonDatVe]);
        if (orderRes.rows.length === 0) {
            await client.query('ROLLBACK');
            return res.status(200).json({ RspCode: '01', Message: 'Order not found' });
        }
        const order = orderRes.rows[0];

        // 2. Kiểm tra số tiền có khớp không
        if (parseInt(order.tongtien) !== amount) {
            await client.query('ROLLBACK');
            return res.status(200).json({ RspCode: '04', Message: 'Invalid amount' });
        }

        // 3. Kiểm tra trạng thái đơn hàng (tránh xử lý trùng)
        if (order.trangthai !== 'pending') {
            await client.query('ROLLBACK');
            return res.status(200).json({ RspCode: '02', Message: 'Order already confirmed' });
        }

        // 4. Cập nhật trạng thái dựa trên vnp_ResponseCode
        if (vnp_ResponseCode === '00') {
            await client.query('COMMIT');
            // Dùng hàm chung để cập nhật
            await updateOrderAfterPayment(maDonDatVe, vnp_TransactionNo);
            return res.status(200).json({ RspCode: '00', Message: 'Confirm Success' });
        } else {
            // Thanh toán thất bại
            await client.query(
                "UPDATE thongtinthanhtoan SET trangthai = 'failed', paymentgatewaytransactionid = $1 WHERE madondatve = $2",
                [vnp_TransactionNo, maDonDatVe]
            );
            await client.query('COMMIT');
            return res.status(200).json({ RspCode: '00', Message: 'Confirm Success (Payment Failed)' });
        }

    } catch (e) {
        if (client) await client.query('ROLLBACK');
        console.error("VNPay IPN Error:", e);
        res.status(500).json({ RspCode: '99', Message: 'Unknown error' });
    } finally {
        if (client) client.release();
    }
};

// Helper function để xử lý các việc sau khi thanh toán thành công
async function handlePostPaymentActions(maDonDatVe, userId) {
    try {
        // 1. Tạo thông báo
        const notifInfoRes = await db.query(`
            SELECT lc.maphim, p.tenphim, r.tenrapphim
            FROM dondatve d
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE d.madondatve = $1
            LIMIT 1
        `, [maDonDatVe]);
        
        if (notifInfoRes.rows.length > 0) {
            const { maphim, tenphim, tenrapphim } = notifInfoRes.rows[0];
            await createNotification({
                userId,
                tieuDe: 'Thanh toán thành công! 🎉',
                noiDung: `Vé phim "${tenphim}" tại ${tenrapphim} đã được xác nhận. Mã đơn: ${maDonDatVe}. Chúc bạn xem phim vui vẻ!`,
                maDonDatVe,
                maPhim: maphim
            });
        }

        // 2. Gửi Email
        const bookingDetailsQuery = `
            SELECT d.madondatve, d.tongtien, t.email,
                   p.tenphim, p.poster_url,
                   lc.ngaychieu, lc.giochieu,
                   r.tenrapphim, pr.tenphong,
                   string_agg(v.maghe, ', ') as seats
            FROM dondatve d
            JOIN thongtintaikhoan t ON d.id_khach = t.id_khach
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE d.madondatve = $1
            GROUP BY d.madondatve, d.tongtien, t.email, p.tenphim, p.poster_url, lc.ngaychieu, lc.giochieu, r.tenrapphim, pr.tenphong
        `;
        const detailsRes = await db.query(bookingDetailsQuery, [maDonDatVe]);
        
        if (detailsRes.rows.length > 0) {
            const d = detailsRes.rows[0];
            await emailService.sendBookingSuccessEmail(d.email, {
                maDonDatVe: d.madondatve,
                tenPhim: d.tenphim,
                ngayChieu: d.ngaychieu instanceof Date ? d.ngaychieu.toLocaleDateString('vi-VN') : d.ngaychieu,
                gioChieu: d.giochieu instanceof Date ? d.giochieu.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : d.giochieu,
                tenRapPhim: d.tenrapphim,
                tenPhong: d.tenphong,
                seats: d.seats.split(', '),
                tongTien: d.tongtien,
                poster_url: d.poster_url
            });
        }
    } catch (err) {
        console.error('Lỗi xử lý hậu thanh toán:', err.message);
    }
}

/**
 * Xử lý khi MoMo điều hướng người dùng quay lại Website
 */
exports.momoReturn = async (req, res) => {
    try {
        console.log("--- MOMO RETURN ---", req.query);
        const isValid = momoService.verifySignature(req.query);
        
        if (!isValid) {
            return res.send("Chữ ký không hợp lệ!");
        }

        const { resultCode, orderId, message, transId } = req.query;

        if (resultCode == '0') {
            res.send(`
                <html>
                    <body style="text-align: center; padding-top: 50px; font-family: sans-serif;">
                        <h1 style="color: green;">Thanh toán MoMo thành công!</h1>
                        <p>Đơn hàng <b>${orderId}</b> đã được ghi nhận.</p>
                        <p>Bạn có thể quay lại ứng dụng để xem vé.</p>
                        <button onclick="window.close()" style="padding: 10px 20px; background: #ae2070; color: white; border: none; border-radius: 5px; cursor: pointer;">Đóng trình duyệt</button>
                    </body>
                </html>
            `);
        } else {
            // Xử lý khi người dùng hủy hoặc lỗi
            await handlePaymentFailure(orderId, transId, resultCode, message);
            
            let statusMessage = "Thanh toán thất bại hoặc đã bị hủy";
            if (resultCode == '1006') {
                statusMessage = "Bạn đã hủy giao dịch MoMo";
            }

            res.send(`
                <html>
                    <body style="text-align: center; padding-top: 50px; font-family: sans-serif;">
                        <h1 style="color: #ae2070;">${statusMessage}</h1>
                        <p>Mã đơn hàng: <b>${orderId}</b></p>
                        <p>Lý do: ${message || 'Giao dịch không thành công'}</p>
                        <p>Ghế của bạn đã được giải phóng. Vui lòng thực hiện đặt lại nếu muốn.</p>
                        <button onclick="window.close()" style="padding: 10px 20px; background: #333; color: white; border: none; border-radius: 5px; cursor: pointer;">Quay lại ứng dụng</button>
                    </body>
                </html>
            `);
        }
    } catch (error) {
        console.error("MoMo Return Error:", error);
        res.status(500).send("Lỗi hệ thống khi xử lý MoMo Return");
    }
};

/**
 * Xử lý IPN từ MoMo (Server-to-Server)
 */
exports.momoIpn = async (req, res) => {
    try {
        console.log("--- MOMO IPN ---", req.body);
        const isValid = momoService.verifySignature(req.body);

        if (!isValid) {
            console.error("MoMo IPN Signature Invalid");
            return res.status(400).json({ message: "Invalid signature" });
        }

        const { orderId, resultCode, amount, transId, message } = req.body;

        if (resultCode == '0') {
            // Thanh toán thành công -> Cập nhật DB
            await updateOrderAfterPayment(orderId, transId);
            console.log(`MoMo IPN Success: Order ${orderId} marked as paid.`);
        } else {
            // Thanh toán thất bại hoặc người dùng hủy
            await handlePaymentFailure(orderId, transId, resultCode, message);
            console.log(`MoMo IPN Failed/Cancelled: Order ${orderId} with code ${resultCode} - ${message}`);
        }

        // MoMo yêu cầu trả về HTTP 204 hoặc JSON
        res.status(204).send();
    } catch (error) {
        console.error("MoMo IPN Error:", error);
        res.status(500).json({ message: "Internal Server Error" });
    }
};

// Kiểm tra trạng thái đơn hàng (Polling cho Frontend)
exports.checkBookingStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query(`
            SELECT trangthai, ngaydatve, tongtien 
            FROM dondatve 
            WHERE madondatve = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Không tìm thấy đơn hàng" });
        }

        const booking = result.rows[0];
        
        // Tính toán thời gian còn lại (giới hạn 10 phút = 600 giây)
        const timeoutSeconds = 600;
        const startTime = new Date(booking.ngaydatve).getTime();
        const now = new Date().getTime();
        const elapsedSeconds = Math.floor((now - startTime) / 1000);
        const remainingSeconds = Math.max(0, timeoutSeconds - elapsedSeconds);

        res.json({
            madondatve: id,
            status: booking.trangthai, // 'pending', 'paid', hoặc 'cancelled'
            amount: booking.tongtien,
            remainingSeconds: remainingSeconds,
            isExpired: remainingSeconds <= 0 && booking.trangthai === 'pending'
        });
    } catch (error) {
        console.error("Check Status Error:", error);
        res.status(500).json({ message: "Lỗi kiểm tra trạng thái: " + error.message });
    }
};

/**
 * Hàm dùng chung để cập nhật trạng thái đơn hàng sau khi thanh toán thành công
 * LUỒNG MỚI: Đọc session từ Redis → INSERT vào PostgreSQL → Xóa Redis → Broadcast Socket
 */
async function updateOrderAfterPayment(maDonDatVe, transId) {
    // 1. Lấy session từ Redis
    const session = await seatLockService.getTempBooking(maDonDatVe);
    if (!session) {
        console.error(`[updateOrderAfterPayment] Không tìm thấy session Redis cho ${maDonDatVe}`);
        // Có thể session đã expire — kiểm tra DB xem đã persist chưa
        const existingOrder = await db.query('SELECT 1 FROM dondatve WHERE madondatve = $1', [maDonDatVe]);
        if (existingOrder.rows.length > 0) {
            console.log(`[updateOrderAfterPayment] Đơn ${maDonDatVe} đã tồn tại trong DB — bỏ qua.`);
            return true;
        }
        throw new Error(`Session ${maDonDatVe} không tồn tại trong Redis và DB`);
    }

    const { 
        userId, 
        showtimeId, 
        seatIds, 
        seatPrices, 
        basePrice, 
        concessionDetails, 
        totalPrice, 
        paymentMethod,
        voucherId,
        sotienDuocGiamVoucher
    } = session;

    const client = await db.connect();
    try {
        await client.query('BEGIN');

        // 2. INSERT đơn đặt vé vào DB (trạng thái: paid ngay luôn)
        await client.query(
            `INSERT INTO dondatve (madondatve, tongtien, trangthai, id_khach) VALUES ($1, $2, 'paid', $3)`,
            [maDonDatVe, totalPrice, userId]
        );

        // 3. INSERT thông tin thanh toán (trạng thái: success)
        const maThanhToan = 'PAY' + Date.now().toString().slice(-6);
        await client.query(
            `INSERT INTO thongtinthanhtoan (mathanhtoan, phuongthucthanhtoan, sotienthanhtoan, trangthai, madondatve, paymentgatewaytransactionid, thoidiemthanhtoan)
             VALUES ($1, $2, $3, 'success', $4, $5, CURRENT_TIMESTAMP)`,
            [maThanhToan, paymentMethod || 'momo', totalPrice, maDonDatVe, transId]
        );

        // 4. INSERT vé xem phim (trạng thái: active ngay luôn)
        // Lấy thời gian chiếu để tính toán thoigianhethan và thông tin phim/suất chiếu/rạp/phòng
        const showtimeRes = await client.query(
            `SELECT lc.ngaychieu, TO_CHAR(lc.giochieu, 'HH24:MI') as giochieu, p.tenphim, pr.tenphong, r.tenrapphim
             FROM lichchieu lc
             JOIN phim p ON lc.maphim = p.maphim
             JOIN phongrapphim pr ON lc.maphong = pr.maphong
             JOIN rapphim r ON pr.marapphim = r.marapphim
             WHERE lc.malichchieu = $1`,
            [showtimeId]
        );
        const startTime = showtimeRes.rows[0]?.ngaychieu || new Date();
        const gioChieu = showtimeRes.rows[0]?.giochieu || '';
        const tenPhim = showtimeRes.rows[0]?.tenphim || '';
        const tenPhong = showtimeRes.rows[0]?.tenphong || '';
        const tenRapPhim = showtimeRes.rows[0]?.tenrapphim || '';
        const expireTime = new Date(new Date(startTime).getTime() + 3 * 60 * 60 * 1000); // Hết hạn sau 3h từ lúc chiếu

        // Query thêm tên ghế từ ghengoi
        const seatInfoRes = await client.query(
            `SELECT maghe, (mahangghe || soghe) as tenghe FROM ghengoi WHERE maghe = ANY($1::varchar[])`,
            [seatIds]
        );
        const seatMap = {};
        seatInfoRes.rows.forEach(row => {
            seatMap[row.maghe] = row.tenghe;
        });

        for (let i = 0; i < seatIds.length; i++) {
            const maVe = 'VE' + Date.now().toString().slice(-4) + i;
            const ticketPrice = seatPrices[seatIds[i]] || basePrice;
            const tenGhe = seatMap[seatIds[i]] || seatIds[i];
            const qrData = JSON.stringify({
                "Tên rạp": tenRapPhim,
                "Phòng chiếu": tenPhong,
                "Tên phim": tenPhim,
                "Mã vé": maVe,
                "Tên ghế": tenGhe,
                "Giờ chiếu": gioChieu
            }, null, 2);
            await client.query(
                `INSERT INTO vexemphim (mavexemphim, qrcode, giave, maghe, malichchieu, madondatve, trangthai, thoigianhethan)
                 VALUES ($1, $2, $3, $4, $5, $6, 'active', $7)`,
                [maVe, qrData, ticketPrice, seatIds[i], showtimeId, maDonDatVe, expireTime]
            );
        }

        // 5. INSERT bắp nước nếu có
        if (concessionDetails && concessionDetails.length > 0) {
            for (let c of concessionDetails) {
                await client.query(
                    `INSERT INTO order_concessions (madondatve, combo_id, quantity, unit_price) VALUES ($1, $2, $3, $4)`,
                    [maDonDatVe, c.comboId, c.quantity, c.price]
                );
            }
        }

        // 5.5. Nếu có sử dụng voucher, lưu lịch sử sử dụng và cập nhật số lượt dùng của voucher
        if (voucherId) {
            await client.query(
                `INSERT INTO lich_su_khuyen_mai (id_khuyen_mai, id_khach, madondatve, gia_tri_giam_thuc_te, ngay_su_dung)
                 VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)`,
                [voucherId, userId, maDonDatVe, sotienDuocGiamVoucher || 0]
            );
            await client.query(
                `UPDATE khuyen_mai SET so_luong_da_dung = so_luong_da_dung + 1 WHERE id = $1`,
                [voucherId]
            );
        }

        // 5.6. Cộng dồn doanh thu chi tiêu cho User và cập nhật Rank tự động
        await client.query(
            `UPDATE thongtintaikhoan SET tong_chi_tieu = tong_chi_tieu + $1 WHERE id_khach = $2`,
            [totalPrice, userId]
        );

        const spendRes = await client.query(
            `SELECT tong_chi_tieu FROM thongtintaikhoan WHERE id_khach = $1`,
            [userId]
        );

        if (spendRes.rows.length > 0) {
            const currentSpent = parseFloat(spendRes.rows[0].tong_chi_tieu || 0);
            let nextRank = 'BRONZE';
            if (currentSpent >= 20000000) {
                nextRank = 'DIAMOND';
            } else if (currentSpent >= 10000000) {
                nextRank = 'GOLD';
            } else if (currentSpent >= 3000000) {
                nextRank = 'SILVER';
            }

            await client.query(
                `UPDATE thongtintaikhoan SET hang_thanh_vien = $1 WHERE id_khach = $2`,
                [nextRank, userId]
            );
        }

        await client.query('COMMIT');

        // 6. Xóa session + unlock ghế trong Redis
        await seatLockService.deleteTempBooking(maDonDatVe);
        // Không unlockAllUserSeats vì ghế đã confirmed — chỉ xóa seat keys
        for (const seatId of seatIds) {
            try { await require('../utils/redisClient').del(`seat:lock:${showtimeId}:${seatId}`); } catch {}
        }
        try { await require('../utils/redisClient').del(`user:seats:${showtimeId}:${userId}`); } catch {}

        // 7. Broadcast Socket.IO
        const io = getIO();
        if (io && io._seatHelpers) {
            io._seatHelpers.broadcastSeatsConfirmed(showtimeId, seatIds);
        }

        // 8. Gửi thông báo và email (không chặn luồng chính)
        handlePostPaymentActions(maDonDatVe, userId).catch(err => console.error("Post Payment Actions Error:", err));

        return true;
    } catch (e) {
        if (client) await client.query('ROLLBACK');
        console.error("updateOrderAfterPayment Error:", e);
        throw e;
    } finally {
        client.release();
    }
}

/**
 * Hàm dùng chung để xử lý khi thanh toán thất bại hoặc người dùng hủy
 * LUỒNG MỚI: Xóa Redis session + unlock ghế + broadcast socket. KHÔNG cần update DB.
 */
async function handlePaymentFailure(maDonDatVe, transId, resultCode, message) {
    try {
        // 1. Lấy session từ Redis
        const session = await seatLockService.getTempBooking(maDonDatVe);
        
        if (session) {
            const { userId, showtimeId, seatIds } = session;

            // 2. Unlock tất cả ghế trong Redis
            const unlockedSeats = await seatLockService.unlockAllUserSeats(showtimeId, userId);

            // 3. Xóa session tạm
            await seatLockService.deleteTempBooking(maDonDatVe);

            // 4. Broadcast Socket.IO — ghế đã được giải phóng
            const io = getIO();
            if (io && io._seatHelpers) {
                io._seatHelpers.broadcastSeatsUnlocked(showtimeId, unlockedSeats.length > 0 ? unlockedSeats : seatIds);
            }

            // 5. Gửi thông báo cho user
            const showtimeInfoRes = await db.query(`
                SELECT p.tenphim, r.tenrapphim, p.maphim
                FROM lichchieu lc
                JOIN phim p ON lc.maphim = p.maphim
                JOIN phongrapphim pr ON lc.maphong = pr.maphong
                JOIN rapphim r ON pr.marapphim = r.marapphim
                WHERE lc.malichchieu = $1
            `, [showtimeId]);

            if (showtimeInfoRes.rows.length > 0) {
                const { tenphim, tenrapphim, maphim } = showtimeInfoRes.rows[0];
                await createNotification({
                    userId,
                    tieuDe: 'Thanh toán không thành công ❌',
                    noiDung: `Giao dịch cho đơn ${maDonDatVe} (Phim: ${tenphim}) đã bị hủy. Ghế đã được giải phóng.`,
                    maDonDatVe,
                    maPhim: maphim
                });
            }

            console.log(`[handlePaymentFailure] Đã cleanup session ${maDonDatVe}, unlock ${unlockedSeats.length} ghế`);
        } else {
            console.warn(`[handlePaymentFailure] Không tìm thấy session Redis cho ${maDonDatVe} — có thể đã expire`);
        }

        return true;
    } catch (e) {
        console.error("handlePaymentFailure Error:", e);
        throw e;
    }
}

/**
 * API Controller: Cho phép người dùng chủ động hủy đơn hàng từ App
 * LUỒNG MỚI: Xóa Redis session + unlock ghế. Không cần update DB.
 */
exports.cancelBooking = async (req, res) => {
    const { id } = req.params; // id = maDonDatVe (sessionId)
    const userId = String(req.user.id);

    try {
        // 1. Kiểm tra session có tồn tại trong Redis không
        const session = await seatLockService.getTempBooking(id);

        if (!session) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng hoặc đã hết hạn' });
        }

        // 2. Xác minh đúng user (bảo mật)
        if (String(session.userId) !== userId) {
            return res.status(403).json({ status: 'error', message: 'Bạn không có quyền hủy đơn này' });
        }

        // 3. Gọi hàm helper để xử lý hủy
        await handlePaymentFailure(id, 'USER_CANCEL_IN_APP', 1006, 'Người dùng chủ động hủy từ ứng dụng');

        return res.json({ 
            status: 'success', 
            message: 'Đơn hàng đã được hủy thành công, ghế đã được giải phóng.' 
        });

    } catch (error) {
        console.error("Lỗi cancelBooking:", error);
        return res.status(500).json({ status: 'error', message: 'Lỗi hệ thống khi hủy đơn hàng' });
    }
};

/**
 * Tra cứu vé bằng QR Code (hỗ trợ cả JSON mới và mã vé/QR cũ)
 */
exports.getTicketByQRCode = async (req, res) => {
    try {
        const { qrCode } = req.params;
        if (!qrCode) {
            return res.status(400).json({ status: 'error', message: 'Thiếu mã QR Code' });
        }

        let maVe = null;
        try {
            const decoded = decodeURIComponent(qrCode);
            const parsed = JSON.parse(decoded);
            if (parsed) {
                maVe = parsed.maVe || parsed["Mã vé"] || parsed["mave"] || parsed["mã vé"];
            }
        } catch (e) {
            try {
                const parsed = JSON.parse(qrCode);
                if (parsed) {
                    maVe = parsed.maVe || parsed["Mã vé"] || parsed["mave"] || parsed["mã vé"];
                }
            } catch (err) {}
        }

        // Truy vấn thông tin vé, rạp, phòng chiếu, ghế và phim để trả về đầy đủ
        const query = `
            SELECT v.mavexemphim as "maVe", v.trangthai, v.giave, v.qrcode,
                   (g.mahangghe || g.soghe) as "tenGhe",
                   p.tenphim as "tenPhim",
                   TO_CHAR(lc.giochieu, 'HH24:MI') as "gioChieu",
                   r.tenrapphim as "tenRapPhim",
                   r.diachi as "diaChi",
                   pr.tenphong as "tenPhong",
                   TO_CHAR(lc.ngaychieu, 'YYYY-MM-DD') as "ngayChieu"
            FROM vexemphim v
            LEFT JOIN ghengoi g ON v.maghe = g.maghe
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE ${maVe ? 'v.mavexemphim = $1' : '(v.qrcode = $1 OR v.mavexemphim = $1)'}
        `;

        const param = maVe || qrCode;
        const result = await db.query(query, [param]);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy vé tương ứng với QR Code này' });
        }

        res.json({
            status: 'success',
            data: result.rows[0]
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi server khi tra cứu vé' });
    }
};

