const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../../config/db');

const JWT_SECRET = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';

/**
 * Đăng nhập cho Nhân viên / Quản lý
 * POST /api/admin/login
 * Body: { email, matKhau }
 */
exports.login = async (req, res) => {
    try {
        const { email, matKhau } = req.body;

        if (!email || !matKhau) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng nhập email và mật khẩu' });
        }

        // Tìm nhân viên theo email
        const staffRes = await db.query('SELECT * FROM nhanvien WHERE email = $1', [email]);

        if (staffRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Tài khoản nhân viên không tồn tại' });
        }

        const staff = staffRes.rows[0];

        // So sánh mật khẩu (hỗ trợ cả bcrypt hash và plain-text cho seed data)
        let isMatch = false;
        try {
            isMatch = await bcrypt.compare(matKhau, staff.matkhau);
        } catch (e) {
            // Nếu hash không hợp lệ thì fallback so sánh trực tiếp
        }

        if (!isMatch && matKhau !== staff.matkhau) {
            return res.status(401).json({ status: 'error', message: 'Mật khẩu không chính xác' });
        }

        // Ký token với role từ bảng nhanvien
        const role = staff.vaitro === 'Quản Lý' ? 'QuanLy' : 'NhanVien';
        const token = jwt.sign(
            { id: staff.id_nhanvien, maNhanVien: staff.manhanvien, role: role },
            JWT_SECRET,
            { expiresIn: '12h' }
        );

        res.json({
            status: 'success',
            message: 'Đăng nhập quản lý thành công',
            token: token,
            staff: {
                id: staff.id_nhanvien,
                maNhanVien: staff.manhanvien,
                hoTen: staff.hoten,
                email: staff.email,
                vaiTro: staff.vaitro
            }
        });

    } catch (e) {
        console.error("Admin Login Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi server nội bộ' });
    }
};
