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

// Hàm phụ trợ kiểm tra user có quyền review không
const checkUserCanReviewDb = async (userId, movieId) => {
    const query = `
        SELECT 1
        FROM dondatve d
        JOIN vexemphim v ON d.madondatve = v.madondatve
        JOIN lichchieu l ON v.malichchieu = l.malichchieu
        WHERE d.id_khach = $1
          AND l.maphim = $2
          AND d.trangthai = 'paid'
          AND l.gioketthuc < NOW()
        LIMIT 1
    `;
    const result = await db.query(query, [userId, movieId]);
    return result.rows.length > 0;
};

// Kiểm tra quyền review (API)
exports.checkCanReview = async (req, res) => {
    try {
        const { movieId } = req.params;
        const userId = req.user.id;

        const canReview = await checkUserCanReviewDb(userId, movieId);
        
        // Kiểm tra xem đã review chưa để lấy nội dung cũ
        let existingReview = null;
        if (canReview) {
            const reviewRes = await db.query(
                'SELECT noidung, danhgia FROM binhluan WHERE maphim = $1 AND id_khach = $2',
                [movieId, userId]
            );
            if (reviewRes.rows.length > 0) {
                existingReview = reviewRes.rows[0];
            }
        }

        res.json({
            status: 'success',
            canReview,
            existingReview
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi kiểm tra quyền đánh giá' });
    }
};

// Đăng bình luận và điểm đánh giá
exports.postReview = async (req, res) => {
    try {
        const { movieId } = req.params;
        const { noiDung, danhGia } = req.body;
        const userId = req.user.id; 

        if (danhGia < 1 || danhGia > 10) {
            return res.status(400).json({ status: 'error', message: 'Điểm đánh giá phải từ 1 đến 10' });
        }

        // Kiểm tra điều kiện
        const canReview = await checkUserCanReviewDb(userId, movieId);
        if (!canReview) {
            return res.status(403).json({ status: 'error', message: 'Bạn cần mua vé và xem phim trước khi đánh giá' });
        }

        // Kiểm tra đã review chưa
        const checkExisting = await db.query(
            'SELECT mabinhluan FROM binhluan WHERE maphim = $1 AND id_khach = $2',
            [movieId, userId]
        );

        let result;
        if (checkExisting.rows.length > 0) {
            // Update
            const updateQuery = `
                UPDATE binhluan 
                SET noidung = $1, danhgia = $2, thoidiemdanhgia = CURRENT_TIMESTAMP
                WHERE maphim = $3 AND id_khach = $4
                RETURNING *
            `;
            const updateRes = await db.query(updateQuery, [noiDung, danhGia, movieId, userId]);
            result = updateRes.rows[0];
            res.status(200).json({ status: 'success', message: 'Cập nhật đánh giá thành công', data: result });
        } else {
            // Insert
            const maBinhLuan = 'BL' + Date.now().toString().slice(-6);
            const insertQuery = `
                INSERT INTO binhluan (mabinhluan, maphim, noidung, danhgia, id_khach)
                VALUES ($1, $2, $3, $4, $5) RETURNING *
            `;
            const insertRes = await db.query(insertQuery, [maBinhLuan, movieId, noiDung, danhGia, userId]);
            result = insertRes.rows[0];
            res.status(201).json({ status: 'success', message: 'Cảm ơn bạn đã đánh giá phim', data: result });
        }
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi phát sinh khi đăng bình luận' });
    }
}
