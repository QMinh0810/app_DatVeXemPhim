const express = require('express');
const router = express.Router();
const { isAdmin } = require('../middleware/adminMiddleware');

// --- Controllers ---
const adminAuthController = require('../controllers/admin/adminAuthController');
const movieAdminController = require('../controllers/admin/movieAdminController');
const showtimeAdminController = require('../controllers/admin/showtimeAdminController');
const roomAdminController = require('../controllers/admin/roomAdminController');
const customerAdminController = require('../controllers/admin/customerAdminController');
const concessionAdminController = require('../controllers/admin/concessionAdminController');
const statsController = require('../controllers/admin/statsController');
const reviewAdminController = require('../controllers/admin/reviewAdminController');

// ==================== AUTH (Không cần isAdmin) ====================
router.post('/login', adminAuthController.login);

// ==================== Tất cả route bên dưới yêu cầu isAdmin ====================
router.use(isAdmin);

// ==================== PHIM & HASHTAG ====================
router.post('/movies/:id/hashtags', movieAdminController.addHashtagToMovie);
router.delete('/movies/:id/hashtags/:hashtagId', movieAdminController.removeHashtagFromMovie);

// ==================== LỊCH CHIẾU ====================
router.post('/showtimes', showtimeAdminController.createShowtime);

// ==================== PHÒNG RẠP & GHẾ ====================
// Xem danh sách ghế theo phòng
router.get('/rooms/:id/seats', roomAdminController.getSeatsByRoom);
// Cập nhật loại ghế (normal/vip/couple/hỏng)
router.put('/seats/:maGhe', roomAdminController.updateSeatType);

// ==================== KHÁCH HÀNG & ĐƠN VÉ ====================
router.get('/bookings', customerAdminController.getBookings);
router.get('/customers', customerAdminController.getCustomers);
// Đã bỏ: PUT /customers/:id (updateCustomer)
router.delete('/customers/:id', customerAdminController.deleteCustomer);

// ==================== THANH TOÁN ====================
router.put('/payments/:id/status', customerAdminController.updatePaymentStatus);

// ==================== ĐỒ ĂN & COMBO ====================
router.get('/items', concessionAdminController.getAllItems);
router.post('/items', concessionAdminController.createItem);
router.put('/items/:id', concessionAdminController.updateItem);
router.delete('/items/:id', concessionAdminController.deleteItem);

router.get('/combos', concessionAdminController.getAllCombos);
router.post('/combos', concessionAdminController.createCombo);
router.put('/combos/:id', concessionAdminController.updateCombo);
router.delete('/combos/:id', concessionAdminController.deleteCombo);

// ==================== THỐNG KÊ & BÁO CÁO ====================
router.get('/stats/bookings-by-movie', statsController.bookingsByMovie);
router.get('/stats/bookings-by-theater', statsController.bookingsByTheater);
router.get('/stats/revenue-by-movie', statsController.revenueByMovie);
router.get('/stats/daily-revenue', statsController.dailyRevenueStats);
router.get('/reports/monthly', statsController.monthlyReport);

// ==================== ĐÁNH GIÁ ====================
router.get('/movies/:id/reviews', reviewAdminController.getReviewsByMovie);
router.post('/reviews/:id/reply', reviewAdminController.replyReview);

module.exports = router;
