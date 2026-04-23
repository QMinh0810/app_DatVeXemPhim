const db = require('../config/db');

/**
 * Hàm giải phóng các ghế (vé) và đơn hàng ở trạng thái 'pending' 
 * đã quá thời gian giữ ghế (10 phút).
 */
const releaseExpiredSeats = async () => {
    try {
        // 1. Cập nhật trạng thái Vé (vexemphim) quá hạn sang 'cancelled'
        const expiredTicketsRes = await db.query(`
            UPDATE vexemphim 
            SET trangthai = 'cancelled' 
            WHERE trangthai = 'pending' 
              AND thoigianhethan < CURRENT_TIMESTAMP
            RETURNING madondatve
        `);

        if (expiredTicketsRes.rowCount > 0) {
            console.log(`[CleanupJob] Đã hủy ${expiredTicketsRes.rowCount} vé quá hạn.`);
            
            // 2. Cập nhật trạng thái Đơn hàng (dondatve) sang 'cancelled' 
            // Nếu tất cả các vé của đơn hàng đó đã bị hủy
            const orderIds = [...new Set(expiredTicketsRes.rows.map(r => r.madondatve))];
            
            for (const orderId of orderIds) {
                // Kiểm tra xem đơn hàng này còn vé nào đang 'pending' chưa hết hạn không
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
