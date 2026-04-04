const db = require('../config/db');

// Xem tất cả bình luận của 1 phim
exports.getReviews = async (req, res) => {
    try {
        const { movieId } = req.params;
        const query = `
            SELECT b.*, t.hoten, t.anhdaidien 
            FROM binhluan b 
            JOIN thongtintaikhoan t ON b.id_khach = t.id_khach 
            WHERE b.maphim = $1 
            ORDER BY b.thoidiemdanhgia DESC
        `;
        const result = await db.query(query, [movieId]);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất bình luận' });
    }
};

// Đăng bình luận và điểm đánh giá
exports.postReview = async (req, res) => {
    try {
        const { movieId } = req.params;
        const { noiDung, danhGia } = req.body;
        // mock userId nếu chưa code bảo vệ Authenticate bằng JWT
        const userId = req.user ? req.user.id : 1; 

        if (danhGia < 1 || danhGia > 10) {
            return res.status(400).json({ status: 'error', message: 'Điểm đánh giá phải từ 1 đến 10' });
        }

        // Sinh mã ngẫu nhiên cho Bình luận
        const maBinhLuan = 'BL' + Date.now().toString().slice(-6);

        const insertQuery = `
            INSERT INTO binhluan (mabinhluan, maphim, noidung, danhgia, id_khach)
            VALUES ($1, $2, $3, $4, $5) RETURNING *
        `;
        
        const result = await db.query(insertQuery, [maBinhLuan, movieId, noiDung, danhGia, userId]);
        res.status(201).json({ status: 'success', message: 'Cảm ơn bạn đã đánh giá phim', data: result.rows[0] });

    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi phát sinh khi đăng bình luận' });
    }
}
