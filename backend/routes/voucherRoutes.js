const express = require('express');
const router = express.Router();
const voucherController = require('../controllers/voucherController');
const { verifyToken } = require('../middleware/authMiddleware');

// Lấy danh sách Voucher khả dụng cho người dùng khi đặt vé (được bảo vệ)
router.get('/available', verifyToken, voucherController.getAvailableVouchers);

// Áp dụng thử mã giảm giá để xem Booking Summary tạm tính (được bảo vệ)
router.post('/apply', verifyToken, voucherController.applyVoucher);

module.exports = router;
