require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const db = require('./config/db');

// --- Routes Import ---
const authRoutes = require('./routes/authRoutes');
const movieRoutes = require('./routes/movieRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const userRoutes = require('./routes/userRoutes');
const concessionRoutes = require('./routes/concessionRoutes');
const adminRoutes = require('./routes/adminRoutes');
const notificationRoutes = require('./routes/notificationRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Tạo HTTP server để Socket.IO dùng chung cổng với Express
const server = http.createServer(app);

// Khởi tạo Socket.IO
const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
    // Cho phép cả polling và websocket (tương thích ngrok)
    transports: ['websocket', 'polling'],
});

// Export io để các controller có thể dùng
module.exports.io = io;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// --- Routing ---
app.use('/api/auth', authRoutes);
app.use('/api/movies', movieRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/users', userRoutes);
app.use('/api/concessions', concessionRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/notifications', notificationRoutes);

// TEST TRỰC TIẾP: Cập nhật poster
app.put('/api/admin/update-poster/:id', (req, res) => {
  const movieAdminController = require('./controllers/admin/movieAdminController');
  return movieAdminController.updateMoviePoster(req, res);
});

// API: Kiểm tra Health
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Backend is running on port ' + PORT });
});

// Middleware bắt lỗi 404 để debug (Đã dời xuống cuối để không chặn các API trên)
app.use((req, res, next) => {
  res.status(404).send(`Cannot ${req.method} ${req.url}`);
});

// API: Test Kết Nối Database
app.get('/api/test-db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as currentTime');
    res.json({ status: 'success', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ status: 'error', message: 'Không thể kết nối Database. Vui lòng kiểm tra DATABASE_URL trong .env', detail: error.message });
  }
});

// Khởi tạo Socket.IO seat handler
const { initSeatSocket } = require('./socket/seatSocket');
initSeatSocket(io);

const { startCleanupJob } = require('./utils/cleanupJob');

// Lắng nghe trên HTTP server (thay vì app.listen)
server.listen(PORT, '0.0.0.0', () => {
  startCleanupJob();
});
