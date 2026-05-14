const redis = require('./redisClient');

const TTL = parseInt(process.env.SEAT_LOCK_TTL) || 300; // 5 phút

// ============================================================
// Key Helpers
// ============================================================
const seatKey = (showtimeId, seatId) => `seat:lock:${showtimeId}:${seatId}`;
const sessionKey = (sessionId) => `booking:session:${sessionId}`;
const userSeatsKey = (showtimeId, userId) => `user:seats:${showtimeId}:${userId}`;

// ============================================================
// SEAT LOCK OPERATIONS
// ============================================================

/**
 * Lock 1 ghế bằng Lua script atomic (tránh race condition)
 * @returns {boolean} true nếu lock thành công, false nếu đã có người lock
 */
async function lockSeat(showtimeId, seatId, userId) {
    const key = seatKey(showtimeId, seatId);

    // Lua script: SET NX EX — atomic operation, tránh race condition
    const luaScript = `
        local existing = redis.call('GET', KEYS[1])
        if existing == false then
            redis.call('SET', KEYS[1], ARGV[1], 'EX', ARGV[2])
            redis.call('SADD', KEYS[2], ARGV[3])
            redis.call('EXPIRE', KEYS[2], ARGV[2])
            return 1
        elseif existing == ARGV[1] then
            -- Đã lock bởi cùng user → gia hạn TTL
            redis.call('EXPIRE', KEYS[1], ARGV[2])
            return 1
        else
            return 0
        end
    `;

    const result = await redis.eval(
        luaScript,
        2,
        key,
        userSeatsKey(showtimeId, userId),
        userId,
        String(TTL),
        seatId
    );

    return result === 1;
}

/**
 * Unlock 1 ghế — chỉ cho phép nếu đúng userId (tránh unlock ghế người khác)
 * @returns {boolean} true nếu unlock thành công
 */
async function unlockSeat(showtimeId, seatId, userId) {
    const key = seatKey(showtimeId, seatId);

    const luaScript = `
        local existing = redis.call('GET', KEYS[1])
        if existing == ARGV[1] then
            redis.call('DEL', KEYS[1])
            redis.call('SREM', KEYS[2], ARGV[2])
            return 1
        else
            return 0
        end
    `;

    const result = await redis.eval(
        luaScript,
        2,
        key,
        userSeatsKey(showtimeId, userId),
        userId,
        seatId
    );

    return result === 1;
}

/**
 * Unlock tất cả ghế của 1 user trong 1 suất chiếu (dùng khi cancel/timeout)
 */
async function unlockAllUserSeats(showtimeId, userId) {
    const userKey = userSeatsKey(showtimeId, userId);
    const seatIds = await redis.smembers(userKey);

    if (seatIds.length === 0) return [];

    const pipeline = redis.pipeline();
    for (const seatId of seatIds) {
        pipeline.del(seatKey(showtimeId, seatId));
    }
    pipeline.del(userKey);
    await pipeline.exec();

    return seatIds; // Trả về danh sách ghế đã unlock để broadcast
}

/**
 * Lấy danh sách tất cả ghế đang bị lock trong 1 suất chiếu
 * @returns {Array<{seatId, lockedBy}>}
 */
async function getLockedSeats(showtimeId) {
    // Scan keys theo pattern seat:lock:{showtimeId}:*
    const pattern = `seat:lock:${showtimeId}:*`;
    const keys = await scanKeys(pattern);

    if (keys.length === 0) return [];

    const pipeline = redis.pipeline();
    for (const key of keys) {
        pipeline.get(key);
    }
    const values = await pipeline.exec();

    return keys.map((key, index) => ({
        seatId: key.split(':').pop(), // Lấy phần cuối của key
        lockedBy: values[index][1],   // userId
    }));
}

/**
 * Lấy danh sách ghế user đang giữ trong 1 suất chiếu
 */
async function getUserLockedSeats(showtimeId, userId) {
    const userKey = userSeatsKey(showtimeId, userId);
    return await redis.smembers(userKey);
}

/**
 * Gia hạn TTL cho tất cả ghế của user (gọi khi user bắt đầu thanh toán)
 */
async function extendUserLocks(showtimeId, userId) {
    const userKey = userSeatsKey(showtimeId, userId);
    const seatIds = await redis.smembers(userKey);

    if (seatIds.length === 0) return false;

    const pipeline = redis.pipeline();
    for (const seatId of seatIds) {
        pipeline.expire(seatKey(showtimeId, seatId), TTL);
    }
    pipeline.expire(userKey, TTL);
    await pipeline.exec();

    return true;
}

// ============================================================
// BOOKING SESSION OPERATIONS
// ============================================================

/**
 * Lưu thông tin đơn đặt vé tạm thời vào Redis
 */
async function createTempBooking(sessionId, data) {
    const key = sessionKey(sessionId);
    await redis.set(key, JSON.stringify(data), 'EX', TTL);
    return sessionId;
}

/**
 * Lấy thông tin đơn đặt vé tạm thời
 */
async function getTempBooking(sessionId) {
    const key = sessionKey(sessionId);
    const raw = await redis.get(key);
    if (!raw) return null;
    try {
        return JSON.parse(raw);
    } catch {
        return null;
    }
}

/**
 * Xóa đơn đặt vé tạm thời (sau khi persist hoặc cancel)
 */
async function deleteTempBooking(sessionId) {
    const key = sessionKey(sessionId);
    await redis.del(key);
}

/**
 * Gia hạn TTL cho session khi bắt đầu thanh toán
 */
async function extendSession(sessionId) {
    const key = sessionKey(sessionId);
    return await redis.expire(key, TTL);
}

// ============================================================
// HELPER: Scan Redis keys theo pattern (tránh dùng KEYS trực tiếp)
// ============================================================
async function scanKeys(pattern) {
    const keys = [];
    let cursor = '0';
    do {
        const [nextCursor, found] = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
        cursor = nextCursor;
        keys.push(...found);
    } while (cursor !== '0');
    return keys;
}

/**
 * Kiểm tra xem user có đơn hàng nào đang chờ thanh toán cho suất chiếu này không
 */
async function hasActiveBookingSession(userId, showtimeId) {
    const pattern = 'booking:session:*';
    const sessionKeys = await scanKeys(pattern);
    
    if (sessionKeys.length === 0) return false;

    for (const key of sessionKeys) {
        const raw = await redis.get(key);
        if (raw) {
            try {
                const data = JSON.parse(raw);
                if (data.userId == userId && data.showtimeId == showtimeId) {
                    return true;
                }
            } catch {}
        }
    }
    return false;
}

module.exports = {
    lockSeat,
    unlockSeat,
    unlockAllUserSeats,
    getLockedSeats,
    getUserLockedSeats,
    extendUserLocks,
    createTempBooking,
    getTempBooking,
    deleteTempBooking,
    extendSession,
    scanKeys,
    hasActiveBookingSession,
    TTL,
};
