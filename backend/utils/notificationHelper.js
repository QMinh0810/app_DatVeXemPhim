const db = require('../config/db');

/**
 * Helper dùng chung: Tạo thông báo in-app cho người dùng.
 * Bắt lỗi nội bộ để không ảnh hưởng luồng chính.
 * @param {object} opts
 * @param {number} opts.userId   - id_khach
 * @param {string} opts.tieuDe  - Tiêu đề thông báo
 * @param {string} opts.noiDung - Nội dung chi tiết
 * @param {string} [opts.maDonDatVe] - Mã đơn đặt vé (nullable)
 * @param {string} [opts.maPhim]     - Mã phim (nullable)
 */
const createNotification = async ({ userId, tieuDe, noiDung, maDonDatVe = null, maPhim = null }) => {
    try {
        const maThongBao = 'TB' + Date.now().toString().slice(-8);
        await db.query(
            `INSERT INTO thongbao (mathongbao, tieude, noidung, trangthai, thoidiemtb, ngaytao, id_khach, madondatve, maphim)
             VALUES ($1, $2, $3, 'unread', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $4, $5, $6)`,
            [maThongBao, tieuDe, noiDung, userId, maDonDatVe, maPhim]
        );
    } catch (err) {
        console.error('Lỗi tạo thông báo (non-critical):', err.message);
    }
};

module.exports = { createNotification };
