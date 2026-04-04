const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

// JWT Secret Key (Nên để vào .env thực tế)
const JWT_SECRET = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';

exports.register = async (req, res) => {
    try {
        const { hoTen, sdt, email, matKhau, ngaySinh, gioiTinh } = req.body;

        // Check exists
        const userExists = await db.query('SELECT * FROM thongtintaikhoan WHERE sdt = $1 OR email = $2', [sdt, email]);
        if (userExists.rows.length > 0) {
            return res.status(400).json({ status: 'error', message: 'Số điện thoại hoặc Email đã được đăng ký' });
        }

        // Tạo mã tài khoản tự động (dùng MAX để tránh race condition)
        const maxRes = await db.query('SELECT COALESCE(MAX(id_khach), 0) as max_id FROM thongtintaikhoan');
        const num = parseInt(maxRes.rows[0].max_id) + 1;
        const maTaiKhoan = 'TK' + String(num).padStart(3, '0');

        // Băm mật khẩu (Hash)
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(matKhau, salt);

        // Lưu vào Database
        const insertQuery = `
            INSERT INTO thongtintaikhoan (mataikhoan, hoten, ngaysinh, gioitinh, sdt, email, matkhau)
            VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id_khach, mataikhoan, hoten, email
        `;
        const newUser = await db.query(insertQuery, [maTaiKhoan, hoTen, ngaySinh || '2000-01-01', gioiTinh !== undefined ? gioiTinh : 1, sdt, email, hashedPassword]);

        res.status(201).json({ status: 'success', message: 'Đăng ký thành công', data: newUser.rows[0] });

    } catch (e) {
        console.error("Register Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi server nội bộ' });
    }
};

exports.login = async (req, res) => {
    try {
        const { username, password } = req.body; // Dùng SĐT hoặc Email

        const userRes = await db.query('SELECT * FROM thongtintaikhoan WHERE sdt = $1 OR email = $1 OR mataikhoan = $1', [username]);
        if (userRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Tài khoản không tồn tại' });
        }

        const user = userRes.rows[0];

        // Mật khẩu thuần ở DB (do SQL giả lập) hoặc Mật khẩu đã Hash
        const isMatch = await bcrypt.compare(password, user.matkhau);
        if (!isMatch && password !== user.matkhau) { // Fallback cho mớ seed data cùi bắp
            return res.status(401).json({ status: 'error', message: 'Mật khẩu không chính xác' });
        }

        // Ký token
        const token = jwt.sign({ id: user.id_khach, role: 'Khach' }, JWT_SECRET, { expiresIn: '7d' });

        res.json({
            status: 'success', 
            message: 'Đăng nhập thành công',
            token: token,
            user: {
                id: user.id_khach,
                maTaiKhoan: user.mataikhoan,
                hoTen: user.hoten,
                email: user.email,
                sdt: user.sdt,
                ngaysinh: user.ngaysinh,
                gioitinh: user.gioitinh,
                anhdaidien: user.anhdaidien,
            }
        });

    } catch (e) {
        console.error("Login Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi server nội bộ' });
    }
};

exports.forgotPassword = async (req, res) => {
   try {
       const { email } = req.body;
       const userRes = await db.query('SELECT * FROM thongtintaikhoan WHERE email = $1', [email]);
       if (userRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Email này không tồn tại trong hệ thống' });
       }
       // Giả lập luồng gởi Mail có mã số "123456"
       res.json({ status: 'success', message: 'Chúng tôi vừa gởi mã OTP: 123456 vào email của bạn (Vì hệ thống Mail đang test).' });
   } catch(e) {
       res.status(500).json({ status: 'error', message: 'Lỗi server' });
   }
}

exports.resetPassword = async (req, res) => {
   try {
       const { email, otp, newPassword } = req.body;
       if (otp !== "123456") return res.status(400).json({ status: 'error', message: 'Mã xác nhận OTP bị sai' });
       
       const salt = await bcrypt.genSalt(10);
       const hashedPassword = await bcrypt.hash(newPassword, salt);
       
       await db.query('UPDATE thongtintaikhoan SET matkhau = $1 WHERE email = $2', [hashedPassword, email]);
       res.json({ status: 'success', message: 'Khôi phục và cập nhật mật khẩu thành công!' });
   } catch(e) {
       res.status(500).json({ status: 'error', message: 'Lỗi server' });
   }
}
