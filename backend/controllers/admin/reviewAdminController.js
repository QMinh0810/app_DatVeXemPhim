const db = require('../../config/db');

/**
 * Xem danh sách bình luận theo phim (Admin)
 * GET /api/admin/movies/:id/reviews
 */
exports.getReviewsByMovie = async (req, res) => {
    try {
        const { id } = req.params; // maPhim

        const result = await db.query(`
            SELECT b.mabinhluan, b.noidung, b.danhgia, b.thoidiemdanhgia,
                   b.noidungreply, b.id_nhanvien,
                   t.hoten as ten_khach, t.email as email_khach, t.anhdaidien,
                   nv.hoten as ten_nhanvien_reply
            FROM binhluan b
            JOIN thongtintaikhoan t ON b.id_khach = t.id_khach
            LEFT JOIN nhanvien nv ON b.id_nhanvien = nv.id_nhanvien
            WHERE b.maphim = $1
            ORDER BY b.thoidiemdanhgia DESC
        `, [id]);

        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error("Get Reviews Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất bình luận' });
    }
};

/**
 * Trả lời bình luận từ nhân viên
 * POST /api/admin/reviews/:id/reply
 * Body: { noiDungReply }
 */
exports.replyReview = async (req, res) => {
    try {
        const { id } = req.params; // maBinhLuan
        const { noiDungReply } = req.body;
        const adminId = req.admin.id; // id_nhanvien từ middleware isAdmin

        if (!noiDungReply || noiDungReply.trim() === '') {
            return res.status(400).json({ status: 'error', message: 'Vui lòng nhập nội dung trả lời' });
        }

        // Kiểm tra bình luận tồn tại
        const checkRes = await db.query('SELECT * FROM binhluan WHERE mabinhluan = $1', [id]);
        if (checkRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy bình luận' });
        }

        // Cập nhật nội dung reply và id nhân viên
        const result = await db.query(`
            UPDATE binhluan 
            SET noidungreply = $1, id_nhanvien = $2
            WHERE mabinhluan = $3
            RETURNING *
        `, [noiDungReply, adminId, id]);

        res.json({ status: 'success', message: 'Trả lời bình luận thành công', data: result.rows[0] });
    } catch (e) {
        console.error("Reply Review Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi trả lời bình luận' });
    }
};
