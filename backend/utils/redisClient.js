require('dotenv').config();
const Redis = require('ioredis');

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

// Tạo Redis client với TLS support cho Upstash (rediss://)
const redis = new Redis(REDIS_URL, {
    tls: REDIS_URL.startsWith('rediss://') ? {
        rejectUnauthorized: false
    } : undefined,
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
        if (times > 5) {
            console.error('[Redis] Không thể kết nối sau 5 lần thử');
            return null; // Dừng retry
        }
        return Math.min(times * 200, 2000); // Tăng dần: 200, 400, 600... ms
    },
    lazyConnect: false,
});

redis.on('connect', () => {
    console.log('✅ [Redis] Kết nối Upstash thành công');
});

redis.on('error', (err) => {
    console.error('[Redis] Lỗi kết nối:', err.message);
});

redis.on('reconnecting', () => {
    console.log('[Redis] Đang kết nối lại...');
});

module.exports = redis;
