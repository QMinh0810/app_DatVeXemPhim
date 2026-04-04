const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false // Bắt buộc khi dùng Neon Database
  }
});

pool.on('error', (err, client) => {
  console.error('Lỗi kịch bản Database ngẫu nhiên:', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  connect: () => pool.connect(),
};
