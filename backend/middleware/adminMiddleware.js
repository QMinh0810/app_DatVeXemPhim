const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';

/**
 * Middleware xác thực Token và kiểm tra quyền Admin (Nhân viên / Quản lý)
 * Token phải chứa role = 'NhanVien' hoặc 'QuanLy'
 */
const isAdmin = (req, res, next) => {
  const authHeader = req.headers['authorization'];

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ status: 'error', message: 'Không tìm thấy Token. Vui lòng đăng nhập.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET);

    // Kiểm tra role phải là nhân viên hoặc quản lý
    if (!decoded.role || !['NhanVien', 'QuanLy'].includes(decoded.role)) {
      return res.status(403).json({ status: 'error', message: 'Bạn không có quyền truy cập chức năng quản lý.' });
    }

    req.admin = decoded; // Gắn thông tin admin vào request
    next();
  } catch (error) {
    console.error('Admin Verify Token Error:', error.message);
    return res.status(403).json({ status: 'error', message: 'Token không hợp lệ hoặc đã hết hạn.' });
  }
};

module.exports = { isAdmin };
