const axios = require('axios');

const TMDB_API_KEY = process.env.TMDB_API_KEY;
const BASE_URL = 'https://api.themoviedb.org/3';

const tmdbService = {
  getMovieDetails: async (tmdbId) => {
    const response = await axios.get(`${BASE_URL}/movie/${tmdbId}`, {
      params: {
        api_key: TMDB_API_KEY,
        append_to_response: 'videos,credits',
        language: 'vi-VN',
      },
    });
    return response.data;
  },

  getTrending: async () => {
    const response = await axios.get(`${BASE_URL}/trending/movie/day`, {
      params: { api_key: TMDB_API_KEY, language: 'vi-VN' },
    });
    return response.data.results || [];
  },

  search: async (query) => {
    const response = await axios.get(`${BASE_URL}/search/movie`, {
      params: { api_key: TMDB_API_KEY, query, language: 'vi-VN' },
    });
    return response.data.results || [];
  },

  getTrailerUrl: (videos) => {
    if (!videos?.results) return '';
    const trailer = videos.results.find(
      (v) => v.type === 'Trailer' && v.site === 'YouTube'
    );
    return trailer ? `https://www.youtube.com/watch?v=${trailer.key}` : '';
  },
};

module.exports = tmdbService;
