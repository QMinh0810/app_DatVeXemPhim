require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./config/db');

// --- Routes Import ---
const authRoutes = require('./routes/authRoutes');
const movieRoutes = require('./routes/movieRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const userRoutes = require('./routes/userRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// --- Routing ---
app.use('/api/auth', authRoutes);
app.use('/api/movies', movieRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/users', userRoutes);

// API: Kiểm tra Health
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend is running on port ' + PORT });
});

// API: Test Kết Nối Database
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as currentTime');
    res.json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    console.error('Lỗi khi kết nối DB:', error.message);
    res.status(500).json({ status: 'error', message: 'Không thể kết nối Database. Vui lòng kiểm tra DATABASE_URL trong .env', detail: error.message });
  }
});

const { startCleanupJob } = require('./utils/cleanupJob');
// Lắng nghe cổng Mạng
app.listen(PORT, () => {
  console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
  startCleanupJob(); // Kích hoạt dọn dẹp ghế hết hạn
});
