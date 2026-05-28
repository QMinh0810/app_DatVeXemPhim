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
const userAdminController = require('../controllers/admin/userAdminController');

// ==================== AUTH (Không cần isAdmin) ====================
router.post('/login', adminAuthController.login);

// ==================== Tất cả route bên dưới yêu cầu isAdmin ====================
router.use(isAdmin);

// ==================== DASHBOARD (statsController) ====================
// GET /stats/dashboard-summary, /stats/weekly-revenue, ...

// ==================== QUẢN LÝ PHIM (TMDB + CRUD) ====================
router.get('/movies', movieAdminController.getAllMovies);
router.get('/movies/tmdb/trending', movieAdminController.getTMDBTrending);
router.get('/movies/tmdb/search', movieAdminController.searchTMDB);
router.post('/movies/import-tmdb', movieAdminController.importFromTMDB);
router.put('/movies/:id', movieAdminController.updateMovie);
router.delete('/movies/:id', movieAdminController.deleteMovie);

router.put('/update-poster/:id', movieAdminController.updateMoviePoster);
router.post('/movies/:id/hashtags', movieAdminController.addHashtagToMovie);
router.delete('/movies/:id/hashtags/:hashtagId', movieAdminController.removeHashtagFromMovie);

// ==================== QUẢN LÝ NGƯỜI DÙNG (Nhân viên + Khách) ====================
router.get('/users', userAdminController.getAllUsers);
router.put('/users/:id', userAdminController.updateUser);
router.put('/users/:id/status', userAdminController.updateUserStatus);
router.put('/users/:id/password', userAdminController.changeUserPassword);
router.delete('/users/:id', userAdminController.deleteUser);

// ==================== LỊCH CHIẾU ====================
router.post('/showtimes', showtimeAdminController.createShowtime);

// ==================== PHÒNG RẠP & GHẾ ====================
// Xem danh sách ghế theo phòng
router.get('/rooms/:id/seats', roomAdminController.getSeatsByRoom);
// Xem danh sách phòng theo rạp
router.get('/theaters/:id/rooms', roomAdminController.getRoomsByTheater);
// Cập nhật loại ghế (normal/vip/couple/hỏng)
router.put('/seats/:maGhe/status', roomAdminController.updateSeatType);

// ==================== KHÁCH HÀNG & ĐƠN VÉ ====================
router.get('/bookings', customerAdminController.getBookings);
router.get('/customers', customerAdminController.getCustomers);
// Đã bỏ: PUT /customers/:id (updateCustomer)
router.delete('/customers/:id', customerAdminController.deleteCustomer);

// ==================== THANH TOÁN ====================
router.put('/payments/:id/status', customerAdminController.updatePaymentStatus);

// ==================== ĐỒ ĂN, PHỤ KIỆN & COMBO ====================
// --- Items chung (Có thể dùng cho food, drink) ---
router.get('/items', concessionAdminController.getAllItems);
router.post('/items', concessionAdminController.createItem);
router.put('/items/:id', concessionAdminController.updateItem);
router.delete('/items/:id', concessionAdminController.deleteItem);

// --- Phụ kiện riêng ---
router.get('/accessories', concessionAdminController.getAllAccessories);
router.post('/accessories', concessionAdminController.createAccessory);
router.put('/accessories/:id', concessionAdminController.updateAccessory);
router.delete('/accessories/:id', concessionAdminController.deleteAccessory);

// --- Combos ---
router.get('/combos', concessionAdminController.getAllCombos);
router.post('/combos', concessionAdminController.createCombo);
router.put('/combos/:id', concessionAdminController.updateCombo);
router.delete('/combos/:id', concessionAdminController.deleteCombo);

// --- POS Độc lập ---
router.post('/pos/concessions/book', concessionAdminController.createPOSConcessionOrder);
router.get('/pos/concessions/orders', concessionAdminController.getPOSConcessionOrders);

// ==================== THỐNG KÊ & BÁO CÁO ====================
router.get('/stats/bookings-by-movie', statsController.bookingsByMovie);
router.get('/stats/bookings-by-theater', statsController.bookingsByTheater);
router.get('/stats/revenue-by-movie', statsController.revenueByMovie);
router.get('/stats/daily-revenue', statsController.dailyRevenueStats);
router.get('/stats/weekly-revenue', statsController.weeklyRevenueStats);
router.get('/stats/dashboard-summary', statsController.dashboardSummary);
router.get('/reports/monthly', statsController.monthlyReport);

// ==================== ĐÁNH GIÁ ====================
router.get('/movies/:id/reviews', reviewAdminController.getReviewsByMovie);
router.post('/reviews/:id/reply', reviewAdminController.replyReview);

module.exports = router;
