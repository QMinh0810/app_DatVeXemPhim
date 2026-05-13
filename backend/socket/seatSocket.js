const jwt = require('jsonwebtoken');
const seatLockService = require('../utils/seatLockService');

/**
 * Khởi tạo Socket.IO handlers cho màn hình chọn ghế
 * @param {import('socket.io').Server} io
 */
function initSeatSocket(io) {

    // Namespace riêng cho booking
    const bookingNS = io.of('/booking');

    // Middleware xác thực JWT cho Socket.IO
    bookingNS.use((socket, next) => {
        const auth = socket.handshake.auth;
        const token = auth?.token;
        console.log(`[Socket Debug] Handshake Auth:`, JSON.stringify(auth));
        console.log(`[Socket Debug] Token: ${token ? "Có" : "KHÔNG CÓ"}`);

        if (!token) {
            socket.userId = null;
            return next();
        }

        try {
            const secret = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';
            const decoded = jwt.verify(token, secret);
            socket.userId = String(decoded.id || decoded.userId || decoded.sub);
            console.log(`[Socket Debug] Xác thực thành công. UserId: ${socket.userId}`);
            next();
        } catch (err) {
            console.error(`[Socket Debug] Lỗi xác thực Token: ${err.message}`);
            socket.userId = null;
            next();
        }
    });

    bookingNS.on('connection', (socket) => {
        console.log(`[Socket] Client kết nối: ${socket.id} | userId: ${socket.userId || 'guest'}`);

        // ============================================================
        // EVENT: Join room theo suất chiếu
        // ============================================================
        socket.on('join_showtime', async ({ showtimeId }) => {
            if (!showtimeId) return;

            // Rời khỏi room cũ nếu đang ở
            if (socket.currentShowtime) {
                socket.leave(`showtime:${socket.currentShowtime}`);
            }

            socket.currentShowtime = String(showtimeId);
            socket.join(`showtime:${showtimeId}`);

            // Gửi trạng thái ghế hiện tại ngay khi join
            try {
                const lockedSeats = await seatLockService.getLockedSeats(showtimeId);
                socket.emit('initial_state', {
                    lockedSeats: lockedSeats.map(s => ({
                        seatId: s.seatId,
                        isYours: socket.userId && s.lockedBy === socket.userId,
                    }))
                });
            } catch (err) {
                console.error('[Socket] Lỗi lấy trạng thái ghế:', err.message);
            }

            console.log(`[Socket] ${socket.id} joined showtime:${showtimeId}`);
        });

        // ============================================================
        // EVENT: Lock ghế (người dùng tap chọn ghế)
        // ============================================================
        socket.on('lock_seat', async ({ showtimeId, seatId }) => {
            if (!socket.userId) {
                return socket.emit('lock_failed', { seatId, reason: 'Chưa đăng nhập' });
            }
            if (!showtimeId || !seatId) return;

            try {
                // Kiểm tra giới hạn 6 ghế
                const currentSeats = await seatLockService.getUserLockedSeats(showtimeId, socket.userId);
                if (currentSeats.length >= 6) {
                    return socket.emit('lock_failed', { 
                        seatId, 
                        reason: 'Bạn chỉ được chọn tối đa 6 ghế trong một lần đặt.' 
                    });
                }

                const success = await seatLockService.lockSeat(showtimeId, seatId, socket.userId);

                if (success) {
                    // Thông báo cho người lock: thành công
                    socket.emit('lock_success', { seatId });

                    // Broadcast đến TẤT CẢ người dùng khác trong cùng suất chiếu
                    socket.to(`showtime:${showtimeId}`).emit('seat_locked', {
                        seatId,
                        isYours: false,
                    });

                    console.log(`[Socket] 🔒 Ghế ${seatId} (suất ${showtimeId}) locked by user ${socket.userId}`);
                } else {
                    // Lock thất bại — ghế đã có người
                    socket.emit('lock_failed', {
                        seatId,
                        reason: 'Ghế vừa được người khác chọn. Vui lòng chọn ghế khác!'
                    });
                }
            } catch (err) {
                console.error('[Socket] Lỗi lock_seat:', err.message);
                socket.emit('lock_failed', { seatId, reason: 'Lỗi hệ thống' });
            }
        });

        // ============================================================
        // EVENT: Unlock ghế (người dùng tap bỏ chọn ghế)
        // ============================================================
        socket.on('unlock_seat', async ({ showtimeId, seatId }) => {
            if (!socket.userId || !showtimeId || !seatId) return;

            try {
                const success = await seatLockService.unlockSeat(showtimeId, seatId, socket.userId);

                if (success) {
                    // Broadcast đến tất cả người trong room
                    bookingNS.to(`showtime:${showtimeId}`).emit('seat_unlocked', { seatId });
                    console.log(`[Socket] 🔓 Ghế ${seatId} (suất ${showtimeId}) unlocked by user ${socket.userId}`);
                }
            } catch (err) {
                console.error('[Socket] Lỗi unlock_seat:', err.message);
            }
        });

        // ============================================================
        // EVENT: Heartbeat — gia hạn lock khi user vẫn đang chọn ghế
        // ============================================================
        socket.on('heartbeat', async ({ showtimeId }) => {
            if (!socket.userId || !showtimeId) return;
            try {
                await seatLockService.extendUserLocks(showtimeId, socket.userId);
            } catch (err) {
                // Silent fail — heartbeat không được block UI
            }
        });

        // ============================================================
        // EVENT: Disconnect — tự động unlock tất cả ghế user đang giữ
        // ============================================================
        socket.on('disconnect', async () => {
            console.log(`[Socket] Client ngắt kết nối: ${socket.id}`);
            
            if (socket.userId && socket.currentShowtime) {
                try {
                    // Kiểm tra xem user này có đơn hàng nào đang chờ thanh toán không
                    // Nếu có đơn hàng, chúng ta KHÔNG unlock ngay mà để TTL dọn dẹp
                    // giúp user có thể thoát app sang ví MoMo/VNPay mà không mất ghế.
                    const hasActiveBooking = await seatLockService.hasActiveBookingSession(socket.userId, socket.currentShowtime);
                    
                    if (!hasActiveBooking) {
                        console.log(`[Socket] Dọn dẹp ghế cho user ${socket.userId} (không có đơn hàng active)`);
                        const unlockedSeats = await seatLockService.unlockAllUserSeats(socket.currentShowtime, socket.userId);
                        
                        if (unlockedSeats && unlockedSeats.length > 0) {
                            bookingNS.to(`showtime:${socket.currentShowtime}`).emit('seats_unlocked_batch', {
                                seatIds: unlockedSeats
                            });
                            console.log(`[Socket] Auto-unlock ${unlockedSeats.length} ghế do user ${socket.userId} disconnect`);
                        }
                    } else {
                        console.log(`[Socket] Giữ nguyên ghế cho user ${socket.userId} (đang trong tiến trình thanh toán)`);
                    }
                } catch (err) {
                    console.error('[Socket] Lỗi auto-unlock khi disconnect:', err.message);
                }
            }
        });
    });

    // ============================================================
    // Helper: Broadcast seat confirmed (gọi từ bookingController sau khi thanh toán)
    // ============================================================
    function broadcastSeatsConfirmed(showtimeId, seatIds) {
        bookingNS.to(`showtime:${showtimeId}`).emit('seats_confirmed', { seatIds });
    }

    function broadcastSeatsUnlocked(showtimeId, seatIds) {
        bookingNS.to(`showtime:${showtimeId}`).emit('seats_unlocked_batch', { seatIds });
    }

    // Export helpers để dùng trong controller
    io._seatHelpers = { broadcastSeatsConfirmed, broadcastSeatsUnlocked };
}

module.exports = { initSeatSocket };
