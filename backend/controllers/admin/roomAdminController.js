const db = require('../../config/db');

/**
 * Cập nhật loại ghế (trạng thái ghế)
 * PUT /api/admin/seats/:maGhe
 * Body: { loaiGhe } - giá trị: 'normal', 'vip', 'couple', 'hỏng'
 * 
 * Ghế 'hỏng' sẽ có hệ số giá = 0 và không thể đặt được.
 * Khi chuyển từ 'hỏng' về loại khác, hệ số giá sẽ tự động cập nhật theo loại ghế mới.
 */
exports.updateSeatType = async (req, res) => {
    try {
        const { maGhe } = req.params;
        const { loaiGhe } = req.body;

        if (!loaiGhe) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng cung cấp loaiGhe' });
        }

        const validTypes = ['normal', 'vip', 'couple', 'hỏng'];
        if (!validTypes.includes(loaiGhe)) {
            return res.status(400).json({
                status: 'error',
                message: `loaiGhe không hợp lệ. Giá trị cho phép: ${validTypes.join(', ')}`
            });
        }

        // Kiểm tra ghế tồn tại
        const checkRes = await db.query('SELECT * FROM ghengoi WHERE maghe = $1', [maGhe]);
        if (checkRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy ghế với mã: ' + maGhe });
        }

        // Xác định hệ số giá theo loại ghế
        let heSoGiaGhe = 1.0;
        switch (loaiGhe) {
            case 'vip': heSoGiaGhe = 1.5; break;
            case 'couple': heSoGiaGhe = 2.0; break;
            case 'hỏng': heSoGiaGhe = 0; break;
            default: heSoGiaGhe = 1.0; // normal
        }

        const result = await db.query(
            'UPDATE ghengoi SET loaighe = $1, hesogiaghe = $2 WHERE maghe = $3 RETURNING *',
            [loaiGhe, heSoGiaGhe, maGhe]
        );

        res.json({
            status: 'success',
            message: `Cập nhật ghế ${maGhe} thành loại '${loaiGhe}' thành công`,
            data: result.rows[0]
        });
    } catch (e) {
        console.error("Update Seat Type Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi cập nhật loại ghế' });
    }
};

/**
 * Lấy danh sách ghế theo phòng chiếu
 * GET /api/admin/rooms/:id/seats
 */
exports.getSeatsByRoom = async (req, res) => {
    try {
        const { id } = req.params; // maPhong
        
        // 1. Lấy thông tin phòng và rạp
        const roomInfoRes = await db.query(`
            SELECT pr.*, r.tenrapphim 
            FROM phongrapphim pr
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE pr.maphong = $1
        `, [id]);

        if (roomInfoRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy phòng chiếu' });
        }

        // 2. Lấy danh sách ghế
        const result = await db.query(
            'SELECT * FROM ghengoi WHERE maphong = $1 ORDER BY mahangghe, soghe',
            [id]
        );

        res.json({
            status: 'success',
            room: roomInfoRes.rows[0],
            total: result.rowCount,
            data: result.rows
        });
    } catch (e) {
        console.error("Get Seats By Room Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi lấy danh sách ghế' });
    }
};
