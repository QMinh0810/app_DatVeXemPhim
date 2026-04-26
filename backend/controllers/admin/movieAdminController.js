const db = require('../../config/db');

/**
 * Gắn hashtag cho phim
 * POST /api/admin/movies/:id/hashtags
 * Body: { maHashtag } hoặc { tenHashTag } (tạo mới nếu chưa tồn tại)
 */
exports.addHashtagToMovie = async (req, res) => {
    try {
        const { id } = req.params; // maPhim
        const { maHashtag, tenHashTag } = req.body;

        let hashtagId = maHashtag;

        // Nếu truyền tenHashTag mà không truyền maHashtag -> tạo mới hoặc tìm existing
        if (!hashtagId && tenHashTag) {
            // Kiểm tra hashtag đã tồn tại chưa
            const existingRes = await db.query('SELECT mahashtag FROM hashtag WHERE tenhashtag = $1', [tenHashTag]);
            
            if (existingRes.rows.length > 0) {
                hashtagId = existingRes.rows[0].mahashtag;
            } else {
                // Tạo mã hashtag mới
                const maxRes = await db.query("SELECT COUNT(*) as cnt FROM hashtag");
                hashtagId = 'HT' + String(parseInt(maxRes.rows[0].cnt) + 1).padStart(2, '0');
                await db.query('INSERT INTO hashtag (mahashtag, tenhashtag) VALUES ($1, $2)', [hashtagId, tenHashTag]);
            }
        }

        if (!hashtagId) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng truyền maHashtag hoặc tenHashTag' });
        }

        // Kiểm tra đã gắn chưa
        const checkRes = await db.query('SELECT * FROM phim_hashtag WHERE maphim = $1 AND mahashtag = $2', [id, hashtagId]);
        if (checkRes.rows.length > 0) {
            return res.status(400).json({ status: 'error', message: 'Hashtag này đã được gắn cho phim' });
        }

        await db.query('INSERT INTO phim_hashtag (maphim, mahashtag) VALUES ($1, $2)', [id, hashtagId]);

        res.status(201).json({ status: 'success', message: 'Gắn hashtag thành công', data: { maphim: id, mahashtag: hashtagId } });
    } catch (e) {
        console.error("Add Hashtag Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi gắn hashtag cho phim' });
    }
};

/**
 * Xoá hashtag khỏi phim
 * DELETE /api/admin/movies/:id/hashtags/:hashtagId
 */
exports.removeHashtagFromMovie = async (req, res) => {
    try {
        const { id, hashtagId } = req.params;

        const result = await db.query('DELETE FROM phim_hashtag WHERE maphim = $1 AND mahashtag = $2 RETURNING *', [id, hashtagId]);

        if (result.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy liên kết hashtag-phim này' });
        }

        res.json({ status: 'success', message: 'Xoá hashtag khỏi phim thành công' });
    } catch (e) {
        console.error("Remove Hashtag Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi xoá hashtag' });
    }
};
