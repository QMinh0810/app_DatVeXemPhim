/**
 * Route tương thích Web Admin cũ: /api/phim/*
 * TMDB browse: không cần token | Import: cần isAdmin
 */
const express = require('express');
const router = express.Router();
const { isAdmin } = require('../middleware/adminMiddleware');
const movieAdminController = require('../controllers/admin/movieAdminController');

router.get('/tmdb/trending', movieAdminController.getTMDBTrending);
router.get('/tmdb/search', movieAdminController.searchTMDB);

router.post('/import', isAdmin, movieAdminController.importFromTMDB);
router.get('/', isAdmin, movieAdminController.getAllMovies);
router.put('/:id', isAdmin, movieAdminController.updateMovie);
router.delete('/:id', isAdmin, movieAdminController.deleteMovie);

module.exports = router;
