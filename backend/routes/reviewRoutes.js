const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');

router.get('/:movieId', reviewController.getReviews);
router.post('/:movieId', reviewController.postReview);

module.exports = router;
