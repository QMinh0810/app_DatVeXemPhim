const db = require('../config/db');

// Lấy danh sách phim theo trạng thái (showing, coming_soon)
exports.getMovies = async (req, res) => {
    try {
        const { status } = req.query; // 'showing' hoặc 'coming_soon'
        let query = 'SELECT * FROM phim';
        let params = [];

        // Nếu có truyền status lên thì Lọc
        if (status) {
            query += ' WHERE trangthai = $1';
            params.push(status);
        }

        const result = await db.query(query, params);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy danh sách phim' });
    }
};

// Lấy danh sách phim đang HOT (Giả lập việc xếp tự động theo lượt xem hoặc ngẫu nhiên)
exports.getHotMovies = async (req, res) => {
    try {
        // Mocking: Lấy ngẫu nhiên vài bộ phim đang chiếu làm phim HOT
        const result = await db.query("SELECT * FROM phim WHERE trangthai = 'showing' ORDER BY RANDOM() LIMIT 5");
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy phim Hot' });
    }
}

// Xem thông tin chi tiết của 1 bộ phim
exports.getMovieById = async (req, res) => {
    try {
        const { id } = req.params;
        const result = await db.query('SELECT * FROM phim WHERE maphim = $1', [id]);
        
        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy phim' });
        }
        res.json({ status: 'success', data: result.rows[0] });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất dữ liệu Phim' });
    }
};

// Tìm kiếm phim theo tên, thể loại
exports.searchMovies = async (req, res) => {
    try {
        const { name, genre } = req.query;
        let query = 'SELECT p.* FROM phim p ';
        let conditions = [];
        let params = [];
        let paramIndex = 1;

        if (genre) {
            // Join qua bảng trung gian Phim_TheLoai
            query += ' JOIN phim_theloai pt ON p.maphim = pt.maphim JOIN theloai t ON pt.matheloai = t.matheloai ';
            conditions.push(`t.tentheloai ILIKE $${paramIndex}`);
            params.push(`%${genre}%`);
            paramIndex++;
        }

        if (name) {
            conditions.push(`p.tenphim ILIKE $${paramIndex}`);
            params.push(`%${name}%`);
            paramIndex++;
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }

        const result = await db.query(query, params);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi máy chủ tìm kiếm' });
    }
};
