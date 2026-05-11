const db = require('../config/db');

// Helper để build câu SELECT phim với đầy đủ thông tin actors/directors (kèm avatar)
const movieSelectQuery = `
    SELECT p.*,
        COALESCE(
            array_remove(
                array_agg(DISTINCT t.tentheloai),
                NULL
            ), ARRAY[]::varchar[]
        ) as genres,
        COALESCE(
            json_agg(DISTINCT jsonb_build_object(
                'name', dd.tendaodien,
                'avatar_url', dd.urlanhdaidien
            )) FILTER (WHERE dd.madaodien IS NOT NULL),
            '[]'
        ) as directors,
        COALESCE(
            json_agg(DISTINCT jsonb_build_object(
                'name', dv.tendienvien,
                'avatar_url', dv.urlanhdaidien
            )) FILTER (WHERE dv.madienvien IS NOT NULL),
            '[]'
        ) as actors
    FROM phim p
    LEFT JOIN phim_theloai pt ON p.maphim = pt.maphim
    LEFT JOIN theloai t ON pt.matheloai = t.matheloai
    LEFT JOIN phim_daodien pdd ON p.maphim = pdd.maphim
    LEFT JOIN daodien dd ON pdd.madaodien = dd.madaodien
    LEFT JOIN phim_dienvien pdv ON p.maphim = pdv.maphim
    LEFT JOIN dienvien dv ON pdv.madienvien = dv.madienvien
`;

// Lấy danh sách phim theo trạng thái (showing, coming_soon)
exports.getMovies = async (req, res) => {
    try {
        const { status } = req.query;
        let query = movieSelectQuery;
        let params = [];

        if (status) {
            query += ' WHERE p.trangthai = $1';
            params.push(status);
        }

        query += ' GROUP BY p.maphim';

        const result = await db.query(query, params);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy danh sách phim' });
    }
};

// Lấy danh sách phim đang HOT
exports.getHotMovies = async (req, res) => {
    try {
        const query = `
            ${movieSelectQuery}
            JOIN phim_hashtag ph ON p.maphim = ph.maphim
            JOIN hashtag h ON ph.mahashtag = h.mahashtag
            WHERE REPLACE(LOWER(h.tenhashtag), ' ', '') ILIKE $1
            AND p.trangthai IN ('showing', 'now_showing')
            GROUP BY p.maphim
            LIMIT 5
        `;
        const result = await db.query(query, ['%phimhot%']);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy phim Hot' });
    }
};

// Xem thông tin chi tiết của 1 bộ phim
exports.getMovieById = async (req, res) => {
    try {
        const { id } = req.params;
        const query = `${movieSelectQuery} WHERE p.maphim = $1 GROUP BY p.maphim`;
        const result = await db.query(query, [id]);

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
        let query = movieSelectQuery;
        let conditions = [];
        let params = [];
        let paramIndex = 1;

        if (genre) {
            conditions.push(`p.maphim IN (SELECT pt2.maphim FROM phim_theloai pt2 JOIN theloai t2 ON pt2.matheloai = t2.matheloai WHERE t2.tentheloai ILIKE $${paramIndex})`);
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

        query += ' GROUP BY p.maphim';

        const result = await db.query(query, params);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi máy chủ tìm kiếm' });
    }
};
