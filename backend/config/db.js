const { Pool } = require('pg');
require('dotenv').config();

const isCloudDB = process.env.DATABASE_URL && (
  process.env.DATABASE_URL.includes('neon.tech') || 
  process.env.DATABASE_URL.includes('render.com') || 
  process.env.DB_SSL === 'true'
);

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isCloudDB ? { rejectUnauthorized: false } : false
});

pool.on('error', (err, client) => {
  console.error('Lỗi kịch bản Database ngẫu nhiên:', err);
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  connect: () => pool.connect(),
};
