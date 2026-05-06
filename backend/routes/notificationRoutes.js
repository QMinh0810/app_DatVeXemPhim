const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { verifyToken } = require('../middleware/authMiddleware');

// Tất cả route đều yêu cầu đăng nhập
router.use(verifyToken);

// Lấy danh sách thông báo
router.get('/', notificationController.getNotifications);

// Lấy số lượng thông báo chưa đọc (đặt TRƯỚC /:id để tránh conflict)
router.get('/unread-count', notificationController.getUnreadCount);

// Đánh dấu tất cả đã đọc
router.put('/read-all', notificationController.markAllAsRead);

// Xóa tất cả thông báo (đặt TRƯỚC /:id để tránh conflict)
router.delete('/all', notificationController.deleteAllNotifications);

// Đánh dấu một thông báo là đã đọc
router.put('/:id/read', notificationController.markAsRead);

// Xóa một thông báo cụ thể
router.delete('/:id', notificationController.deleteNotification);

module.exports = router;
