const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';

/**
 * Middleware xác thực Token Bearer
 */
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ status: 'error', message: 'Không tìm thấy Token. Vui lòng đăng nhập.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded; // Gắn thông tin id, role vào request
    next();
  } catch (error) {
    console.error('Verify Token Error:', error.message);
    return res.status(403).json({ status: 'error', message: 'Token không hợp lệ hoặc đã hết hạn.' });
  }
};

module.exports = {
  verifyToken
};
