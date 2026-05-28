const express = require('express');
const router = express.Router();
const ticketWebController = require('../controllers/ticketWebController');

router.get('/:ticketCode', ticketWebController.renderTicket);

module.exports = router;
