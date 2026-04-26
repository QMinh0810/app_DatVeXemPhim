const db = require('../config/db');
const emailService = require('../utils/emailService');

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
        
        // 1. Lấy thông tin Lịch chiếu -> Lấy được mã Phòng
        const showtimeRes = await db.query('SELECT * FROM lichchieu WHERE malichchieu = $1', [showtimeId]);
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
                const thanhTien = c.price * c.quantity;
                await client.query(`
                    INSERT INTO order_concessions (madondatve, item_id, combo_id, so_luong, gia_luc_mua, thanh_tien)
                    VALUES ($1, $2, $3, $4, $5, $6)
                `, [maDonDatVe, c.itemId || null, c.comboId || null, c.quantity, c.price, thanhTien]);
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
            
            // Giữ ghế trong 10 phút
            let expireTime = new Date(Date.now() + 10 * 60 * 1000).toISOString();

            await client.query(`
                INSERT INTO vexemphim (mavexemphim, qrcode, thoigianhethan, giave, maghe, malichchieu, madondatve, trangthai)
                VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending')
            `, [maVe, 'HOLD_' + maVe, expireTime, ticketPrice, seatIds[i], showtimeId, maDonDatVe]);
        }

        // 6. (Bỏ qua phần thanh toán ngay lập tức theo Workflow mới)

        // Hoàn tất lưu dữ liệu
        await client.query('COMMIT');

        res.status(201).json({ 
            status: 'success', 
            message: 'Giữ ghế thành công! Vui lòng hoàn tất thanh toán trong 10 phút.', 
            data: { 
                maDonDatVe, 
                maThanhToan,
                totalPrice,
                expiresAt: new Date(Date.now() + 10 * 60 * 1000).toISOString()
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

        // 3. Gửi Email thông báo (Chạy async sau khi đã commit thành công)
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

