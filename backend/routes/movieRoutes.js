const express = require('express');
const router = express.Router();
const movieController = require('../controllers/movieController');

router.get('/hot', movieController.getHotMovies);
router.get('/search', movieController.searchMovies);
router.get('/', movieController.getMovies);
router.get('/:id', movieController.getMovieById);

module.exports = router;
