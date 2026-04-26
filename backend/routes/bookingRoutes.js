const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { verifyToken } = require('../middleware/authMiddleware');

// Tuyến xem dữ liệu công khai (Rạp phim, Lịch chiếu, Ghế trống)
router.get('/theaters', bookingController.getTheaters);
router.get('/showtimes', bookingController.getShowtimes);
router.get('/showtimes/:showtimeId/seats', bookingController.getTheaterRoomsAndSeats);

// Tuyến xử lý giao dịch đặt vé (Đã bảo vệ bởi Token)
router.post('/book', verifyToken, bookingController.createBooking); 
// Đã bỏ: router.post('/confirm-payment') - Việc xác nhận thanh toán giờ do Admin xử lý qua PUT /api/admin/payments/:id/status

module.exports = router;
