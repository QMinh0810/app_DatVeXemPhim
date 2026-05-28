const db = require('../../config/db');
const tmdbService = require('../../utils/tmdbService');

const movieListQuery = `
  SELECT p.*,
    COALESCE(
      array_remove(array_agg(DISTINCT h.tenhashtag), NULL),
      ARRAY[]::varchar[]
    ) AS hashtags
  FROM phim p
  LEFT JOIN phim_hashtag ph ON p.maphim = ph.maphim
  LEFT JOIN hashtag h ON ph.mahashtag = h.mahashtag
`;

/**
 * GET /api/admin/movies
 * Danh sách phim cho Web Admin (kèm hashtag)
 */
exports.getAllMovies = async (req, res) => {
  try {
    const result = await db.query(
      `${movieListQuery} GROUP BY p.maphim ORDER BY p.duoctaongay DESC`
    );
    res.json({ status: 'success', total: result.rowCount, data: result.rows });
  } catch (e) {
    console.error('Get All Movies Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi lấy danh sách phim' });
  }
};

/**
 * GET /api/admin/movies/tmdb/trending
 */
exports.getTMDBTrending = async (req, res) => {
  try {
    if (!process.env.TMDB_API_KEY) {
      return res.status(500).json({
        status: 'error',
        message: 'Chưa cấu hình TMDB_API_KEY trong .env',
      });
    }
    const movies = await tmdbService.getTrending();
    res.json(movies);
  } catch (e) {
    console.error('TMDB Trending Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi lấy phim trending từ TMDB' });
  }
};

/**
 * GET /api/admin/movies/tmdb/search?query=...
 */
exports.searchTMDB = async (req, res) => {
  try {
    const { query } = req.query;
    if (!query) {
      return res.json([]);
    }
    if (!process.env.TMDB_API_KEY) {
      return res.status(500).json({
        status: 'error',
        message: 'Chưa cấu hình TMDB_API_KEY trong .env',
      });
    }
    const movies = await tmdbService.search(query);
    res.json(movies);
  } catch (e) {
    console.error('TMDB Search Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi tìm kiếm TMDB' });
  }
};

/**
 * POST /api/admin/movies/import-tmdb
 * Body: { tmdb_id, duoctaoboi }
 */
exports.importFromTMDB = async (req, res) => {
  const { tmdb_id, duoctaoboi } = req.body;

  if (!tmdb_id) {
    return res.status(400).json({ status: 'error', message: 'Thiếu tmdb_id' });
  }

  const client = await db.connect();

  try {
    await client.query('BEGIN');

    const existing = await client.query(
      'SELECT maphim FROM phim WHERE tmdb_id = $1',
      [String(tmdb_id)]
    );
    if (existing.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        status: 'error',
        message: 'Phim này đã tồn tại trong hệ thống',
      });
    }

    const movieDetails = await tmdbService.getMovieDetails(tmdb_id);
    const trailer_url = tmdbService.getTrailerUrl(movieDetails.videos);
    const maphim = `P-${tmdb_id}-${Date.now()}`;

    const insertPhim = await client.query(
      `INSERT INTO phim (
        maphim, tmdb_id, tenphim, ngayramat, mota, thoiluong, gioihantuoi,
        poster_url, trailer_url, trangthai, duoctaoboi
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING *`,
      [
        maphim,
        String(tmdb_id),
        String(movieDetails.title || 'Chưa có tên'),
        movieDetails.release_date || new Date().toISOString().split('T')[0],
        String(movieDetails.overview || ''),
        Number(movieDetails.runtime || 120),
        movieDetails.adult ? 18 : 13,
        movieDetails.poster_path
          ? `https://image.tmdb.org/t/p/w500${movieDetails.poster_path}`
          : '',
        trailer_url,
        'pending',
        String(duoctaoboi || 'Admin'),
      ]
    );

    const newPhim = insertPhim.rows[0];

    if (movieDetails.genres?.length) {
      const uniqueGenres = Array.from(
        new Map(movieDetails.genres.map((g) => [g.id, g])).values()
      );
      for (const genre of uniqueGenres) {
        let genreRow = await client.query(
          'SELECT matheloai FROM theloai WHERE tentheloai = $1',
          [genre.name]
        );
        let matheloai;
        if (genreRow.rows.length === 0) {
          matheloai = `TL-${genre.id}`;
          await client.query(
            'INSERT INTO theloai (matheloai, tentheloai) VALUES ($1, $2)',
            [matheloai, genre.name]
          );
        } else {
          matheloai = genreRow.rows[0].matheloai;
        }
        await client.query(
          `INSERT INTO phim_theloai (maphim, matheloai) VALUES ($1, $2)
           ON CONFLICT (maphim, matheloai) DO NOTHING`,
          [maphim, matheloai]
        );
      }
    }

    if (movieDetails.credits?.cast) {
      const uniqueActors = Array.from(
        new Map(movieDetails.credits.cast.map((a) => [a.id, a])).values()
      ).slice(0, 5);

      for (const actor of uniqueActors) {
        let actorRow = await client.query(
          'SELECT madienvien FROM dienvien WHERE tendienvien = $1',
          [actor.name]
        );
        let madienvien;
        if (actorRow.rows.length === 0) {
          madienvien = `DV-${actor.id}`;
          await client.query(
            `INSERT INTO dienvien (madienvien, tendienvien, quoctich, urlanhdaidien)
             VALUES ($1, $2, '', $3)`,
            [
              madienvien,
              actor.name,
              actor.profile_path
                ? `https://image.tmdb.org/t/p/w500${actor.profile_path}`
                : null,
            ]
          );
        } else {
          madienvien = actorRow.rows[0].madienvien;
        }
        await client.query(
          `INSERT INTO phim_dienvien (madienvien, maphim) VALUES ($1, $2)
           ON CONFLICT (madienvien, maphim) DO NOTHING`,
          [madienvien, maphim]
        );
      }
    }

    if (movieDetails.credits?.crew) {
      const directors = movieDetails.credits.crew.filter(
        (p) => p.job === 'Director'
      );
      const uniqueDirectors = Array.from(
        new Map(directors.map((d) => [d.id, d])).values()
      );

      for (const director of uniqueDirectors) {
        let dirRow = await client.query(
          'SELECT madaodien FROM daodien WHERE tendaodien = $1',
          [director.name]
        );
        let madaodien;
        if (dirRow.rows.length === 0) {
          madaodien = `DD-${director.id}`;
          await client.query(
            `INSERT INTO daodien (madaodien, tendaodien, urlanhdaidien)
             VALUES ($1, $2, $3)`,
            [
              madaodien,
              director.name,
              director.profile_path
                ? `https://image.tmdb.org/t/p/w500${director.profile_path}`
                : null,
            ]
          );
        } else {
          madaodien = dirRow.rows[0].madaodien;
        }
        await client.query(
          `INSERT INTO phim_daodien (maphim, madaodien) VALUES ($1, $2)
           ON CONFLICT (maphim, madaodien) DO NOTHING`,
          [maphim, madaodien]
        );
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      status: 'success',
      message: 'Nhập phim từ TMDB thành công',
      data: newPhim,
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Import TMDB Error:', e);
    res.status(500).json({
      status: 'error',
      message: 'Lỗi nhập phim từ TMDB',
      detail: e.message,
    });
  } finally {
    client.release();
  }
};

/**
 * PUT /api/admin/movies/:id
 */
exports.updateMovie = async (req, res) => {
  const { id } = req.params;
  const {
    tenphim,
    mota,
    thoiluong,
    ngayramat,
    gioihantuoi,
    poster_url,
    trailer_url,
    trangthai,
  } = req.body;

  try {
    const result = await db.query(
      `UPDATE phim SET
        tenphim = COALESCE($1, tenphim),
        mota = COALESCE($2, mota),
        thoiluong = COALESCE($3, thoiluong),
        ngayramat = COALESCE($4, ngayramat),
        gioihantuoi = COALESCE($5, gioihantuoi),
        poster_url = COALESCE($6, poster_url),
        trailer_url = COALESCE($7, trailer_url),
        trangthai = COALESCE($8, trangthai)
       WHERE maphim = $9
       RETURNING *`,
      [
        tenphim,
        mota,
        thoiluong != null ? parseInt(thoiluong, 10) : null,
        ngayramat,
        gioihantuoi != null ? parseInt(gioihantuoi, 10) : null,
        poster_url,
        trailer_url,
        trangthai,
        id,
      ]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ status: 'error', message: 'Không tìm thấy phim' });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật phim thành công',
      data: result.rows[0],
    });
  } catch (e) {
    console.error('Update Movie Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi cập nhật phim' });
  }
};

/**
 * DELETE /api/admin/movies/:id
 */
exports.deleteMovie = async (req, res) => {
  const { id } = req.params;
  const client = await db.connect();

  try {
    const lichRes = await client.query(
      'SELECT COUNT(*)::int AS cnt FROM lichchieu WHERE maphim = $1',
      [id]
    );
    if (parseInt(lichRes.rows[0].cnt, 10) > 0) {
      return res.status(400).json({
        status: 'error',
        message: `Không thể xóa phim vì còn ${lichRes.rows[0].cnt} suất chiếu.`,
      });
    }

    await client.query('BEGIN');
    await client.query('DELETE FROM binhluan WHERE maphim = $1', [id]);
    await client.query('DELETE FROM phim_hashtag WHERE maphim = $1', [id]);
    await client.query('DELETE FROM phim_theloai WHERE maphim = $1', [id]);
    await client.query('DELETE FROM phim_dienvien WHERE maphim = $1', [id]);
    await client.query('DELETE FROM phim_daodien WHERE maphim = $1', [id]);
    await client.query('DELETE FROM khuyen_mai_phim WHERE maphim = $1', [id]);
    const del = await client.query('DELETE FROM phim WHERE maphim = $1 RETURNING maphim', [
      id,
    ]);
    await client.query('COMMIT');

    if (del.rowCount === 0) {
      return res.status(404).json({ status: 'error', message: 'Không tìm thấy phim' });
    }

    res.json({ status: 'success', message: 'Đã xóa phim thành công' });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Delete Movie Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi xóa phim' });
  } finally {
    client.release();
  }
};

/**
 * POST /api/admin/movies/:id/hashtags
 */
exports.addHashtagToMovie = async (req, res) => {
  try {
    const { id } = req.params;
    const { maHashtag, tenHashTag } = req.body;

    let hashtagId = maHashtag;

    if (!hashtagId && tenHashTag) {
      const existingRes = await db.query(
        'SELECT mahashtag FROM hashtag WHERE tenhashtag = $1',
        [tenHashTag]
      );

      if (existingRes.rows.length > 0) {
        hashtagId = existingRes.rows[0].mahashtag;
      } else {
        const maxRes = await db.query('SELECT COUNT(*)::int AS cnt FROM hashtag');
        hashtagId = `HT${String(parseInt(maxRes.rows[0].cnt, 10) + 1).padStart(2, '0')}`;
        await db.query(
          'INSERT INTO hashtag (mahashtag, tenhashtag) VALUES ($1, $2)',
          [hashtagId, tenHashTag]
        );
      }
    }

    if (!hashtagId) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng truyền maHashtag hoặc tenHashTag',
      });
    }

    const checkRes = await db.query(
      'SELECT 1 FROM phim_hashtag WHERE maphim = $1 AND mahashtag = $2',
      [id, hashtagId]
    );
    if (checkRes.rows.length > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Hashtag này đã được gắn cho phim',
      });
    }

    await db.query(
      'INSERT INTO phim_hashtag (maphim, mahashtag) VALUES ($1, $2)',
      [id, hashtagId]
    );

    res.status(201).json({
      status: 'success',
      message: 'Gắn hashtag thành công',
      data: { maphim: id, mahashtag: hashtagId },
    });
  } catch (e) {
    console.error('Add Hashtag Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi khi gắn hashtag cho phim' });
  }
};

/**
 * DELETE /api/admin/movies/:id/hashtags/:hashtagId
 */
exports.removeHashtagFromMovie = async (req, res) => {
  try {
    const { id, hashtagId } = req.params;

    const result = await db.query(
      'DELETE FROM phim_hashtag WHERE maphim = $1 AND mahashtag = $2 RETURNING *',
      [id, hashtagId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy liên kết hashtag-phim này',
      });
    }

    res.json({ status: 'success', message: 'Xoá hashtag khỏi phim thành công' });
  } catch (e) {
    console.error('Remove Hashtag Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi khi xoá hashtag' });
  }
};

/**
 * PUT /api/admin/update-poster/:id
 */
exports.updateMoviePoster = async (req, res) => {
  try {
    const { id } = req.params;
    const { poster_url } = req.body;

    if (!poster_url) {
      return res.status(400).json({
        status: 'error',
        message: 'Vui lòng cung cấp poster_url',
      });
    }

    const result = await db.query(
      'UPDATE phim SET poster_url = $1 WHERE maphim = $2 RETURNING maphim, tenphim, poster_url',
      [poster_url, id]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({
        status: 'error',
        message: 'Không tìm thấy phim có mã: ' + id,
      });
    }

    res.json({
      status: 'success',
      message: 'Cập nhật poster thành công',
      data: result.rows[0],
    });
  } catch (e) {
    console.error('Update Movie Poster Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi khi cập nhật poster' });
  }
};
