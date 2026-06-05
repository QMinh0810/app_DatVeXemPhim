const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/:movieId/can-review', verifyToken, reviewController.checkCanReview);
router.get('/:movieId', reviewController.getReviews);
router.post('/:movieId', verifyToken, reviewController.postReview);

module.exports = router;
