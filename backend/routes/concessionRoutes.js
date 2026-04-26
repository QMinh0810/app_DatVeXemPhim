const express = require('express');
const router = express.Router();
const concessionController = require('../controllers/concessionController');

// Không cần authenticate để xem danh sách món ăn/combo
router.get('/items', concessionController.getItems);
router.get('/combos', concessionController.getCombos);

module.exports = router;
