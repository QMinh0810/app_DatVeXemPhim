const express = require('express');
const router = express.Router();
const concessionController = require('../controllers/concessionController');
const { verifyToken } = require('../middleware/authMiddleware');

// Không cần authenticate để xem danh sách món ăn/combo
router.get('/items', concessionController.getItems);
router.get('/combos', concessionController.getCombos);

// Đặt combo kèm vé (cần đăng nhập)
router.post('/order', verifyToken, concessionController.createConcessionOrder);
router.get('/order/:madondatve', verifyToken, concessionController.getConcessionOrder);

module.exports = router;
