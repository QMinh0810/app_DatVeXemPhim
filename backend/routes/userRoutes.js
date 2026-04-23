const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

// Cấu hình các route (Tất cả yêu cầu Token)
router.get('/profile', verifyToken, userController.getProfile);
router.put('/profile', verifyToken, userController.updateProfile);
router.get('/history', verifyToken, userController.getBookingHistory);

module.exports = router;
