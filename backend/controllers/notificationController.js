const db = require('../config/db');

// =====================================================
// Lấy danh sách thông báo của người dùng (mới nhất lên đầu)
// =====================================================
exports.getNotifications = async (req, res) => {
    try {
        const userId = req.user.id;

        const query = `
            SELECT 
                tb.mathongbao,
                tb.tieude,
                tb.noidung,
                tb.trangthai,
                tb.thoidiemtb,
                tb.thoidiemxem,
                tb.madondatve,
                tb.maphim,
                p.tenphim,
                p.poster_url
            FROM thongbao tb
            LEFT JOIN phim p ON tb.maphim = p.maphim
            WHERE tb.id_khach = $1
            ORDER BY tb.thoidiemtb DESC
        `;

        const result = await db.query(query, [userId]);

        res.json({
            status: 'success',
            data: result.rows.map(row => ({
                maThongBao: row.mathongbao,
                tieuDe: row.tieude,
                noiDung: row.noidung,
                trangThai: row.trangthai,
                thoiDiemTB: row.thoidiemtb,
                thoiDiemXem: row.thoidiemxem,
                maDonDatVe: row.madondatve,
                phim: row.maphim ? {
                    maPhim: row.maphim,
                    tenPhim: row.tenphim,
                    posterUrl: row.poster_url
                } : null
            }))
        });
    } catch (e) {
        console.error('Lỗi getNotifications:', e);
        res.status(500).json({ status: 'error', message: 'Không thể tải danh sách thông báo' });
    }
};

// =====================================================
// Lấy số lượng thông báo chưa đọc
// =====================================================
exports.getUnreadCount = async (req, res) => {
    try {
        const userId = req.user.id;

        const result = await db.query(
            `SELECT COUNT(*) as count FROM thongbao WHERE id_khach = $1 AND trangthai = 'unread'`,
            [userId]
        );

        res.json({
            status: 'success',
            data: { unreadCount: parseInt(result.rows[0].count, 10) }
        });
    } catch (e) {
        console.error('Lỗi getUnreadCount:', e);
        res.status(500).json({ status: 'error', message: 'Không thể lấy số thông báo chưa đọc' });
    }
};

// =====================================================
// Đánh dấu một thông báo là đã đọc
// =====================================================
exports.markAsRead = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id } = req.params;

        const result = await db.query(
            `UPDATE thongbao 
             SET trangthai = 'read', thoidiemxem = CURRENT_TIMESTAMP 
             WHERE mathongbao = $1 AND id_khach = $2
             RETURNING mathongbao`,
            [id, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy thông báo hoặc không có quyền thực hiện' });
        }

        res.json({ status: 'success', message: 'Đã đánh dấu đã đọc' });
    } catch (e) {
        console.error('Lỗi markAsRead:', e);
        res.status(500).json({ status: 'error', message: 'Không thể cập nhật trạng thái thông báo' });
    }
};

// =====================================================
// Đánh dấu TẤT CẢ thông báo là đã đọc
// =====================================================
exports.markAllAsRead = async (req, res) => {
    try {
        const userId = req.user.id;

        await db.query(
            `UPDATE thongbao 
             SET trangthai = 'read', thoidiemxem = CURRENT_TIMESTAMP 
             WHERE id_khach = $1 AND trangthai = 'unread'`,
            [userId]
        );

        res.json({ status: 'success', message: 'Đã đánh dấu tất cả thông báo là đã đọc' });
    } catch (e) {
        console.error('Lỗi markAllAsRead:', e);
        res.status(500).json({ status: 'error', message: 'Không thể cập nhật trạng thái thông báo' });
    }
};

// =====================================================
// Xóa một thông báo cụ thể
// =====================================================
exports.deleteNotification = async (req, res) => {
    try {
        const userId = req.user.id;
        const { id } = req.params;

        const result = await db.query(
            `DELETE FROM thongbao WHERE mathongbao = $1 AND id_khach = $2 RETURNING mathongbao`,
            [id, userId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy thông báo hoặc không có quyền xóa' });
        }

        res.json({ status: 'success', message: 'Đã xóa thông báo thành công' });
    } catch (e) {
        console.error('Lỗi deleteNotification:', e);
        res.status(500).json({ status: 'error', message: 'Không thể xóa thông báo' });
    }
};

// =====================================================
// Xóa TẤT CẢ thông báo của người dùng hiện tại
// =====================================================
exports.deleteAllNotifications = async (req, res) => {
    try {
        const userId = req.user.id;

        await db.query(`DELETE FROM thongbao WHERE id_khach = $1`, [userId]);

        res.json({ status: 'success', message: 'Đã xóa tất cả thông báo thành công' });
    } catch (e) {
        console.error('Lỗi deleteAllNotifications:', e);
        res.status(500).json({ status: 'error', message: 'Không thể xóa tất cả thông báo' });
    }
};
