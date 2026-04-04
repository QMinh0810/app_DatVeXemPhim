const db = require('../config/db');

// Lấy danh sách Rạp phim
exports.getTheaters = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM raphim');
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
        
        // 3. Lấy danh sách ghế ĐÃ ĐƯỢC ĐẶT trong suất chiếu này
        const bookedSeatsRes = await db.query('SELECT maghe FROM vexemphim WHERE malichchieu = $1 AND trangthai != $2', [showtimeId, 'cancelled']);
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
            SELECT lc.*, p.tenphim, r.tenraphim, pr.tenphong 
            FROM lichchieu lc
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongraphim pr ON lc.maphong = pr.maphong
            JOIN raphim r ON pr.marapphim = r.marapphim
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
        const { showtimeId, seatIds, paymentMethod } = req.body;
        // mock user ID nếu chưa có (vì tạm chưa check JWT test gắt)
        const userId = req.user ? req.user.id : 1; 

        if (!seatIds || seatIds.length === 0) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng chọn ít nhất 1 ghế' });
        }

        await client.query('BEGIN'); // Bắt đầu lock DB

        // 1. Kiểm tra ghế đã ai đặt chưa (TRONG CÙNG LỊCH CHIẾU)
        const checkSeatsQuery = `
            SELECT maghe FROM vexemphim 
            WHERE malichchieu = $1 AND maghe = ANY($2::varchar[]) AND trangthai != 'cancelled'
        `;
        const checkSeatsRes = await client.query(checkSeatsQuery, [showtimeId, seatIds]);
        
        if (checkSeatsRes.rows.length > 0) {
            await client.query('ROLLBACK');
            return res.status(400).json({ status: 'error', message: 'Ghế bạn chọn đã có người khác nhanh tay đặt mất!' });
        }

        // 2. Tính tiền (dựa vào giaVe của Lịch chiếu & heSoGiaGhe)
        const showtimeRes = await client.query('SELECT giave FROM lichchieu WHERE malichchieu = $1', [showtimeId]);
        const basePrice = showtimeRes.rows[0].giave;

        const seatRes = await client.query('SELECT maghe, hesogiaghe FROM ghengoi WHERE maghe = ANY($1::varchar[])', [seatIds]);
        
        let totalPrice = 0;
        seatRes.rows.forEach(seat => {
            totalPrice += (basePrice * seat.hesogiaghe);
        });

        // 3. Sinh mã Đơn Hàng (Ví dụ: DON-{timestamp})
        const maDonDatVe = 'DON' + Date.now().toString().slice(-6);

        // 4. Tạo Đơn Đặt Vé (DonDatVe)
        const insertDonQuery = `
            INSERT INTO dondatve (madondatve, tongtien, trangthai, id_khach)
            VALUES ($1, $2, 'paid', $3) RETURNING *
        `;
        await client.query(insertDonQuery, [maDonDatVe, totalPrice, userId]);

        // 5. Tạo Vé Xem Phim (Từng ghế = 1 vé chiếu)
        for (let i = 0; i < seatIds.length; i++) {
            let maVe = 'VE' + Date.now().toString().slice(-4) + i;
            let targetSeat = seatRes.rows.find(s => s.maghe === seatIds[i]);
            let ticketPrice = basePrice * targetSeat.hesogiaghe;
            
            // Hết hạn = 3 tiếng sau khi đặt
            let expireTime = new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString();

            await client.query(`
                INSERT INTO vexemphim (mavexemphim, qrcode, thoigianhethan, giave, maghe, malichchieu, madondatve, trangthai)
                VALUES ($1, $2, $3, $4, $5, $6, $7, 'active')
            `, [maVe, 'QR_CODE_MOCK_' + maVe, expireTime, ticketPrice, seatIds[i], showtimeId, maDonDatVe]);
        }

        // 6. Ghi chú log Thanh Toán
        const maThanhToan = 'PAY' + Date.now().toString().slice(-5);
        await client.query(`
            INSERT INTO thongtinthanhtoan (mathanhtoan, phuongthucthanhtoan, paymentgatewaytransactionid, sotienthanhtoan, trangthai, madondatve)
            VALUES ($1, $2, $3, $4, 'success', $5)
        `, [maThanhToan, paymentMethod || 'momo', 'MOCK_TRANS_ID', totalPrice, maDonDatVe]);

        // Hoàn tất lưu dữ liệu
        await client.query('COMMIT');

        res.status(201).json({ status: 'success', message: 'Đặt vé và Thanh toán MOCK thành công', data: { maDonDatVe, totalPrice } });

    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Booking Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi giao dịch đặt vé' });
    } finally {
        client.release();
    }
};
