const db = require('../config/db');
const emailService = require('../utils/emailService');
const { createNotification } = require('../utils/notificationHelper');
const vnpayService = require('../utils/vnpayService');
const momoService = require('../utils/momoService');

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
        
        // 3. Lấy danh sách ghế ĐÃ ĐƯỢC ĐẶT hoặc ĐANG GIỮ chưa hết hạn
        const queryBookedSeats = `
            SELECT v.maghe 
            FROM vexemphim v
            WHERE v.malichchieu = $1 
              AND v.trangthai != 'cancelled'
              AND (v.trangthai = 'active' OR v.thoigianhethan > CURRENT_TIMESTAMP)
        `;
        const bookedSeatsRes = await db.query(queryBookedSeats, [showtimeId]);
        const bookedSeatIds = bookedSeatsRes.rows.map(row => row.maghe);

        // Map trạng thái ghế
        const seats = seatsRes.rows.map(seat => ({
            ...seat,
            isBooked: bookedSeatIds.includes(seat.maghe)
        }));

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

// API: Tạo Đơn Đặt Vé (Bao gồm Xử lý Transaction khóa ghế)
exports.createBooking = async (req, res) => {
    // Để gọi được hàm này, User bắt buộc phải truyền Token (lấy từ Header)
    // Giả sử middleware đã inject `req.user`
    
    // Khởi tạo Transaction (Bảo toàn dữ liệu)
    const client = await db.connect();

    try {
        const { showtimeId, seatIds, paymentMethod, concessions } = req.body;
        // Lấy userId từ Token (Bắt buộc)
        const userId = req.user.id; 

        if (!seatIds || seatIds.length === 0) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng chọn ít nhất 1 ghế' });
        }

        await client.query('BEGIN'); // Bắt đầu lock DB

        // 1. Kiểm tra ghế đã ai đặt chưa hoặc có ai đang giữ (Pending) chưa hết hạn
        const checkSeatsQuery = `
            SELECT g.maghe 
            FROM vexemphim v
            JOIN ghengoi g ON v.maghe = g.maghe
            WHERE v.malichchieu = $1 
              AND g.maghe = ANY($2::varchar[]) 
              AND v.trangthai != 'cancelled'
              AND (v.trangthai = 'active' OR v.thoigianhethan > CURRENT_TIMESTAMP)
        `;
        const checkSeatsRes = await client.query(checkSeatsQuery, [showtimeId, seatIds]);
        
        if (checkSeatsRes.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: 'error', message: 'Một số ghế bạn chọn đã có người đặt hoặc đang được giữ. Vui lòng chọn ghế khác!' });
        }

        // 2. Tính tiền (dựa vào giaVe của Lịch chiếu & heSoGiaGhe)
        const showtimeRes = await client.query('SELECT giave FROM lichchieu WHERE malichchieu = $1', [showtimeId]);
        const basePrice = showtimeRes.rows[0].giave;

        const seatRes = await client.query('SELECT maghe, hesogiaghe FROM ghengoi WHERE maghe = ANY($1::varchar[])', [seatIds]);
        
        if (seatRes.rows.length !== seatIds.length) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: 'error', message: 'Một hoặc nhiều ghế không hợp lệ.' });
        }

        let ticketPriceTotal = 0;
        for (let sId of seatIds) {
            let seat = seatRes.rows.find(s => String(s.maghe).trim() === String(sId).trim());
            if (!seat) {
                await client.query('ROLLBACK');
                return res.status(400).json({ status: 'error', message: `Không tìm thấy thông tin giá cho ghế: ${sId}` });
            }
            ticketPriceTotal += (basePrice * seat.hesogiaghe);
        }

        // 2.5 Tính tiền bắp nước (concessions)
        let concessionPrice = 0;
        let concessionDetails = [];

        if (concessions && concessions.length > 0) {
            for (let c of concessions) {
                if (c.itemId) {
                    const itemRes = await client.query('SELECT price FROM items WHERE item_id = $1', [c.itemId]);
                    if (itemRes.rows.length > 0) {
                        const price = itemRes.rows[0].price;
                        concessionPrice += price * c.quantity;
                        concessionDetails.push({ ...c, price });
                    }
                } else if (c.comboId) {
                    const comboRes = await client.query('SELECT price FROM combos WHERE combo_id = $1', [c.comboId]);
                    if (comboRes.rows.length > 0) {
                        const price = comboRes.rows[0].price;
                        concessionPrice += price * c.quantity;
                        concessionDetails.push({ ...c, price });
                    }
                }
            }
        }

        let totalPrice = ticketPriceTotal + concessionPrice;

        // 3. Sinh mã Đơn Hàng
        const maDonDatVe = 'DON' + Date.now().toString().slice(-6);

        // 4. Tạo Đơn Đặt Vé (Trạng thái: pending)
        const insertDonQuery = `
            INSERT INTO dondatve (madondatve, tongtien, trangthai, id_khach)
            VALUES ($1, $2, 'pending', $3) RETURNING *
        `;
        await client.query(insertDonQuery, [maDonDatVe, totalPrice, userId]);

        // 4.5 Tạo thông tin bắp nước
        if (concessionDetails.length > 0) {
            for (let c of concessionDetails) {
                await client.query(`
                    INSERT INTO order_concessions (madondatve, combo_id, quantity, unit_price)
                    VALUES ($1, $2, $3, $4)
                `, [maDonDatVe, c.comboId, c.quantity, c.price]);
            }
        }

        // 5. Tạo thông tin thanh toán (Trạng thái: pending)
        const maThanhToan = 'PAY' + Date.now().toString().slice(-6);
        const insertPaymentQuery = `
            INSERT INTO thongtinthanhtoan (mathanhtoan, phuongthucthanhtoan, sotienthanhtoan, trangthai, madondatve, paymentgatewaytransactionid)
            VALUES ($1, $2, $3, 'pending', $4, '')
        `;
        await client.query(insertPaymentQuery, [maThanhToan, paymentMethod || 'momo', totalPrice, maDonDatVe]);

        // 6. Tạo Vé Xem Phim (Trạng thái: pending, Giữ trong 10 phút)
        for (let i = 0; i < seatIds.length; i++) {
            let maVe = 'VE' + Date.now().toString().slice(-4) + i;
            let targetSeat = seatRes.rows.find(s => String(s.maghe).trim() === String(seatIds[i]).trim());
            if (!targetSeat) {
                await client.query('ROLLBACK');
                return res.status(400).json({ status: 'error', message: `Lỗi xử lý vé: Không tìm thấy ghế ${seatIds[i]}` });
            }
            let ticketPrice = basePrice * targetSeat.hesogiaghe;
            
            // Giữ ghế trong 2 phút
            let expireTime = new Date(Date.now() + 2 * 60 * 1000).toISOString();

            await client.query(`
                INSERT INTO vexemphim (mavexemphim, qrcode, thoigianhethan, giave, maghe, malichchieu, madondatve, trangthai)
                VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending')
            `, [maVe, 'HOLD_' + maVe, expireTime, ticketPrice, seatIds[i], showtimeId, maDonDatVe]);
        }

        // 6. (Bỏ qua phần thanh toán ngay lập tức theo Workflow mới)

        // Hoàn tất lưu dữ liệu
        await client.query('COMMIT');

        // --- XỬ LÝ THANH TOÁN VNPAY ---
        let paymentUrl = null;
        if (paymentMethod === 'vnpay') {
            const ipAddr = req.headers['x-forwarded-for'] || 
                           req.connection.remoteAddress || 
                           req.socket.remoteAddress || 
                           req.connection.socket.remoteAddress;
            
            paymentUrl = vnpayService.buildPaymentUrl(
                maDonDatVe,
                totalPrice,
                `Thanh toan ve xem phim DON ${maDonDatVe}`,
                ipAddr
            );
        } else if (paymentMethod === 'momo') {
            paymentUrl = await momoService.createPaymentUrl(
                maDonDatVe,
                totalPrice,
                `Thanh toan ve xem phim DON ${maDonDatVe}`
            );
        }

        // Tạo thông báo: Đặt vé thành công (giữ chỗ)
        const showtimeInfoRes = await db.query(`
            SELECT lc.maphim, p.tenphim, r.tenrapphim
            FROM lichchieu lc
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE lc.malichchieu = $1
        `, [showtimeId]);
        if (showtimeInfoRes.rows.length > 0) {
            const { maphim, tenphim, tenrapphim } = showtimeInfoRes.rows[0];
            await createNotification({
                userId,
                tieuDe: 'Đặt vé thành công! 🎬',
                noiDung: `Bạn đã giữ ${seatIds.length} ghế cho phim "${tenphim}" tại ${tenrapphim}. Mã đơn: ${maDonDatVe}. Vui lòng thanh toán trong 2 phút.`,
                maDonDatVe,
                maPhim: maphim
            });
        }

        res.status(201).json({ 
            status: 'success', 
            message: 'Giữ ghế thành công! Vui lòng hoàn tất thanh toán trong 2 phút.', 
            data: { 
                maDonDatVe, 
                maThanhToan,
                totalPrice,
                paymentUrl, // Trả về URL thanh toán VNPay nếu có
                expiresAt: new Date(Date.now() + 2 * 60 * 1000).toISOString()
            } 
        });

    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Booking Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi giao dịch đặt vé' });
    } finally {
        client.release();
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

        // Tạo thông báo: Thanh toán và xác nhận vé thành công
        (async () => {
            try {
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
                        userId: req.user.id,
                        tieuDe: 'Thanh toán thành công! 🎉',
                        noiDung: `Vé phim "${tenphim}" tại ${tenrapphim} đã được xác nhận. Mã đơn: ${maDonDatVe}. Chúc bạn xem phim vui vẻ!`,
                        maDonDatVe,
                        maPhim: maphim
                    });
                }
            } catch (err) {
                console.error('Lỗi tạo thông báo thanh toán (non-critical):', err.message);
            }
        })();

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
            SELECT trangthai, thoidiemdat, tongtien 
            FROM dondatve 
            WHERE madondatve = $1
        `, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ message: "Không tìm thấy đơn hàng" });
        }

        const booking = result.rows[0];
        
        // Tính toán thời gian còn lại (giới hạn 10 phút = 600 giây)
        const timeoutSeconds = 600;
        const startTime = new Date(booking.thoidiemdat).getTime();
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
        res.status(500).json({ message: "Lỗi kiểm tra trạng thái" });
    }
};

/**
 * Hàm dùng chung để cập nhật trạng thái đơn hàng sau khi thanh toán thành công
 */
async function updateOrderAfterPayment(maDonDatVe, transId) {
    const client = await db.connect();
    try {
        await client.query('BEGIN');

        // 1. Cập nhật bảng thongtinthanhtoan
        await client.query(
            "UPDATE thongtinthanhtoan SET trangthai = 'success', paymentgatewaytransactionid = $1, thoidiemthanhtoan = CURRENT_TIMESTAMP WHERE madondatve = $2",
            [transId, maDonDatVe]
        );

        // 2. Cập nhật trạng thái đơn hàng dondatve
        await client.query(
            "UPDATE dondatve SET trangthai = 'paid' WHERE madondatve = $1",
            [maDonDatVe]
        );

        // 3. Kích hoạt tất cả vé thuộc đơn hàng này
        await client.query(
            "UPDATE vexemphim SET trangthai = 'active' WHERE madondatve = $1",
            [maDonDatVe]
        );

        // Lấy ID khách để gửi thông báo
        const orderRes = await client.query('SELECT id_khach FROM dondatve WHERE madondatve = $1', [maDonDatVe]);
        const id_khach = orderRes.rows[0]?.id_khach;

        await client.query('COMMIT');

        // 4. Gửi thông báo và email (không chặn luồng chính)
        if (id_khach) {
            handlePostPaymentActions(maDonDatVe, id_khach).catch(err => console.error("Post Payment Actions Error:", err));
        }

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
 */
async function handlePaymentFailure(maDonDatVe, transId, resultCode, message) {
    const client = await db.connect();
    try {
        await client.query('BEGIN');

        // 1. Cập nhật bảng thongtinthanhtoan
        await client.query(
            "UPDATE thongtinthanhtoan SET trangthai = 'failed', paymentgatewaytransactionid = $1 WHERE madondatve = $2",
            [transId || `ERR_${resultCode}`, maDonDatVe]
        );

        // 2. Cập nhật trạng thái đơn hàng dondatve (chỉ khi đang pending)
        await client.query(
            "UPDATE dondatve SET trangthai = 'cancelled' WHERE madondatve = $1 AND (trangthai = 'pending' OR TRIM(trangthai) = 'pending')",
            [maDonDatVe]
        );

        // 3. Hủy tất cả vé thuộc đơn hàng này (chỉ khi chưa cancelled)
        await client.query(
            "UPDATE vexemphim SET trangthai = 'cancelled' WHERE madondatve = $1 AND (trangthai != 'cancelled' AND TRIM(trangthai) != 'cancelled')",
            [maDonDatVe]
        );

        // Lấy thông tin khách hàng để gửi thông báo
        const orderInfoRes = await client.query(`
            SELECT d.id_khach, p.tenphim, r.tenrapphim, p.maphim
            FROM dondatve d
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE d.madondatve = $1
            LIMIT 1
        `, [maDonDatVe]);

        if (orderInfoRes.rows.length > 0) {
            const { id_khach, tenphim, tenrapphim, maphim } = orderInfoRes.rows[0];
            await createNotification({
                userId: id_khach,
                tieuDe: 'Thanh toán không thành công ❌',
                noiDung: `Giao dịch cho đơn hàng ${maDonDatVe} (Phim: ${tenphim}) đã bị hủy hoặc thất bại. Ghế của bạn đã được giải phóng.`,
                maDonDatVe,
                maPhim: maphim
            });
        }

        await client.query('COMMIT');
        return true;
    } catch (e) {
        if (client) await client.query('ROLLBACK');
        console.error("handlePaymentFailure Error:", e);
        throw e;
    } finally {
        client.release();
    }
}

/**
 * API Controller: Cho phép người dùng chủ động hủy đơn hàng từ App
 */
exports.cancelBooking = async (req, res) => {
    const { id } = req.params;
    // const userIdFromToken = req.user.id; // Có thể dùng để bảo mật thêm

    const client = await db.connect();
    try {
        // 1. Kiểm tra đơn hàng có tồn tại
        const orderRes = await client.query(
            "SELECT trangthai FROM dondatve WHERE madondatve = $1",
            [id]
        );

        if (orderRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
        }

        const order = orderRes.rows[0];

        // 2. Chỉ cho phép hủy nếu đang ở trạng thái pending
        const currentStatus = (order.trangthai || '').trim();
        if (currentStatus !== 'pending') {
            return res.status(400).json({ 
                status: 'error', 
                message: `Không thể hủy đơn hàng đang ở trạng thái: ${currentStatus}` 
            });
        }

        // 3. Gọi hàm helper để xử lý hủy tập trung
        await handlePaymentFailure(id, 'USER_CANCEL_IN_APP', 1006, 'Người dùng chủ động hủy từ ứng dụng');

        return res.json({ 
            status: 'success', 
            message: 'Đơn hàng đã được hủy thành công, ghế đã được giải phóng.' 
        });

    } catch (error) {
        console.error("Lỗi cancelBooking:", error);
        return res.status(500).json({ status: 'error', message: 'Lỗi hệ thống khi hủy đơn hàng' });
    } finally {
        client.release();
    }
};

