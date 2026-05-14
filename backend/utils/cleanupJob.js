const redis = require('./redisClient');
const seatLockService = require('./seatLockService');

/**
 * Cleanup Job mới: Scan Redis để tìm ghế hết hạn lock
 * 
 * Redis TTL tự động xóa keys khi hết hạn. Tuy nhiên, Upstash free tier
 * không hỗ trợ Keyspace Notifications. Do đó, job này scan mỗi 30 giây
 * để phát hiện session hết hạn và broadcast Socket.IO thông báo ghế đã giải phóng.
 *
 * LƯU Ý: Vì dùng TTL, ghế sẽ tự unlock khi key hết hạn. Job này chỉ:
 * 1. Log cho monitoring
 * 2. Dọn dẹp user:seats keys nếu seat keys đã expire
 */
const cleanupExpiredSessions = async () => {
    try {
        // Scan tất cả booking sessions đang tồn tại
        const sessionKeys = await seatLockService.scanKeys('booking:session:*');
        
        if (sessionKeys.length > 0) {
            console.log(`[CleanupJob] ${sessionKeys.length} booking session(s) đang active trong Redis`);
        }

        // Scan user seat tracking keys để dọn dẹp orphan
        const userSeatKeys = await seatLockService.scanKeys('user:seats:*');
        
        for (const userKey of userSeatKeys) {
            const seatIds = await redis.smembers(userKey);
            
            if (seatIds.length === 0) {
                // Key rỗng → xóa
                await redis.del(userKey);
                continue;
            }

            // Lấy showtimeId từ key pattern: user:seats:{showtimeId}:{userId}
            const parts = userKey.split(':');
            const showtimeId = parts[2];

            // Kiểm tra xem các seat lock keys có còn tồn tại không
            let allExpired = true;
            for (const seatId of seatIds) {
                const exists = await redis.exists(`seat:lock:${showtimeId}:${seatId}`);
                if (exists) {
                    allExpired = false;
                    break;
                }
            }

            if (allExpired) {
                // Tất cả seat locks đã expire nhưng user:seats key chưa → dọn dẹp
                await redis.del(userKey);
                console.log(`[CleanupJob] Dọn dẹp orphan user:seats key cho showtime ${showtimeId}`);

                // Broadcast ghế đã được giải phóng
                try {
                    const io = require('../server').io;
                    if (io && io._seatHelpers) {
                        io._seatHelpers.broadcastSeatsUnlocked(showtimeId, seatIds);
                    }
                } catch {}
            }
        }
    } catch (e) {
        console.error('[CleanupJob] Lỗi cleanup:', e.message);
    }
};

// Khởi chạy Job mỗi 30 giây
const startCleanupJob = () => {
    console.log('🧹 Cleanup Job đã được kích hoạt (Chạy mỗi 30 giây — Redis mode)');
    setInterval(cleanupExpiredSessions, 30000);
    // Chạy lần đầu sau 5 giây (chờ Redis kết nối xong)
    setTimeout(cleanupExpiredSessions, 5000);
};

module.exports = { startCleanupJob };
