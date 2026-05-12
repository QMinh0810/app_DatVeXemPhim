const db = require('../config/db');
const { createNotification } = require('./notificationHelper');

/**
 * Hàm giải phóng các ghế (vé) và đơn hàng ở trạng thái 'pending'
 * đã quá thời gian giữ ghế (2 phút).
 * Đồng thời gửi thông báo in-app cho người dùng bị ảnh hưởng.
 */
const releaseExpiredSeats = async () => {
    try {
        // 1. Lấy danh sách đơn hàng sắp bị huỷ TRƯỚC KHI cập nhật
        //    để có thể gửi thông báo kèm thông tin chi tiết
        const expiredOrdersInfoRes = await db.query(`
            SELECT DISTINCT
                d.madondatve,
                d.id_khach,
                d.tongtien,
                p.maphim,
                p.tenphim,
                r.tenrapphim
            FROM vexemphim v
            JOIN dondatve d ON v.madondatve = d.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE v.trangthai = 'pending'
              AND v.thoigianhethan < CURRENT_TIMESTAMP
              AND d.trangthai = 'pending'
        `);

        // 2. Cập nhật trạng thái Vé (vexemphim) quá hạn sang 'cancelled'
        const expiredTicketsRes = await db.query(`
            UPDATE vexemphim 
            SET trangthai = 'cancelled' 
            WHERE trangthai = 'pending' 
              AND thoigianhethan < CURRENT_TIMESTAMP
            RETURNING madondatve
        `);

        if (expiredTicketsRes.rowCount > 0) {
            console.log(`[CleanupJob] Đã hủy ${expiredTicketsRes.rowCount} vé quá hạn.`);

            // 3. Cập nhật trạng thái Đơn hàng (dondatve) sang 'cancelled'
            //    nếu tất cả vé của đơn hàng đó đã bị hủy
            const orderIds = [...new Set(expiredTicketsRes.rows.map(r => r.madondatve))];

            for (const orderId of orderIds) {
                // Kiểm tra xem đơn hàng còn vé pending chưa hết hạn không
                const checkStillPending = await db.query(`
                    SELECT 1 FROM vexemphim 
                    WHERE madondatve = $1 AND trangthai = 'pending'
                `, [orderId]);

                if (checkStillPending.rowCount === 0) {
                    await db.query(`
                        UPDATE dondatve 
                        SET trangthai = 'cancelled' 
                        WHERE madondatve = $1 AND trangthai = 'pending'
                    `, [orderId]);
                    console.log(`[CleanupJob] Đã hủy đơn hàng ${orderId} do hết hạn giữ ghế.`);

                    // 4. Gửi thông báo in-app cho người dùng
                    const orderInfo = expiredOrdersInfoRes.rows.find(r => r.madondatve === orderId);
                    if (orderInfo) {
                        const tongTienFormat = Number(orderInfo.tongtien).toLocaleString('vi-VN');
                        await createNotification({
                            userId: orderInfo.id_khach,
                            tieuDe: 'Đơn hàng đã bị huỷ (Hết hạn) ⏳',
                            noiDung: `Đơn hàng ${orderId} cho phim "${orderInfo.tenphim}" tại ${orderInfo.tenrapphim} đã bị huỷ do bạn chưa thanh toán đúng hạn. Số tiền hoàn lại: ${tongTienFormat} VNĐ.`,
                            maDonDatVe: orderId,
                            maPhim: orderInfo.maphim
                        });
                    }
                }
            }
        }
    } catch (e) {
        console.error('[CleanupJob] Lỗi khi thực hiện dọn dẹp:', e.message);
    }
};

// Khởi chạy Job mỗi 1 phút (60000ms)
const startCleanupJob = () => {
    console.log('🚀 Cleanup Job đã được kích hoạt (Chạy mỗi 1 phút)');
    setInterval(releaseExpiredSeats, 60000);
    // Chạy thử lần đầu ngay khi khởi động
    releaseExpiredSeats();
};

module.exports = { startCleanupJob };
