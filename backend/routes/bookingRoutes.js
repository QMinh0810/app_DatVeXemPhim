const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
// const { verifyToken } = require('../middleware/authMiddleware'); // Nếu có middleware Auth, có thể import

// Tuyến xem dữ liệu công khai (Rạp phim, Lịch chiếu, Ghế trống)
router.get('/theaters', bookingController.getTheaters);
router.get('/showtimes', bookingController.getShowtimes);
router.get('/showtimes/:showtimeId/seats', bookingController.getTheaterRoomsAndSeats);

// Tuyến xử lý giao dịch đặt vé (Nên được bảo vệ bởi Token)
// router.post('/book', verifyToken, bookingController.createBooking); // Thực tế sẽ bật cái này
router.post('/book', bookingController.createBooking); // Tạm mở cho test

module.exports = router;
