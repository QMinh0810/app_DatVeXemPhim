const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const db = require('../config/db');
const emailService = require('../utils/emailService');

const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

// JWT Secret Key (Nên để vào .env thực tế)
const JWT_SECRET = process.env.JWT_SECRET || 'NHOM7_SECRET_KEY';

// Bộ nhớ tạm lưu trữ OTP (Key: email, Value: { otp, expiresAt })
const otpStore = new Map();

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

       // 1. Sinh mã OTP ngẫu nhiên 6 chữ số
       const otp = Math.floor(100000 + Math.random() * 900000).toString();
       
       // 2. Thiết lập thời gian hết hạn (5 phút)
       const expiresAt = Date.now() + 5 * 60 * 1000;

       // 3. Lưu vào bộ nhớ tạm
       otpStore.set(email, { otp, expiresAt });

       // 4. Gửi Email thực tế
       const emailSent = await emailService.sendOTPEmail(email, otp);

       res.json({ 
           status: 'success', 
           message: emailSent 
            ? `Chúng tôi đã gửi mã xác nhận vào email của bạn.` 
            : `Hệ thống không thể gửi email lúc này, vui lòng thử lại sau. (OTP Debug: ${otp})`,
           debug_otp: otp, // Giữ để dễ test
           expiresIn: '5 minutes'
       });
   } catch(e) {
       console.error("Forgot Password Error:", e);
       res.status(500).json({ status: 'error', message: 'Lỗi server' });
   }
}

exports.resetPassword = async (req, res) => {
   try {
       const { email, otp, newPassword } = req.body;

       // 1. Kiểm tra xem có yêu cầu reset cho email này không
       const storedData = otpStore.get(email);
       if (!storedData) {
           return res.status(400).json({ status: 'error', message: 'Không tìm thấy yêu cầu khôi phục mật khẩu cho email này' });
       }

       // 2. Kiểm tra mã OTP
       if (storedData.otp !== otp) {
           return res.status(400).json({ status: 'error', message: 'Mã xác nhận OTP không chính xác' });
       }

       // 3. Kiểm tra hết hạn
       if (Date.now() > storedData.expiresAt) {
           otpStore.delete(email); // Xóa mã đã hết hạn
           return res.status(400).json({ status: 'error', message: 'Mã OTP đã hết hạn (5 phút). Vui lòng yêu cầu mã mới.' });
       }
       
       // 4. Mã hóa mật khẩu mới
       const salt = await bcrypt.genSalt(10);
       const hashedPassword = await bcrypt.hash(newPassword, salt);
       
       // 5. Cập nhật vào DB
       await db.query('UPDATE thongtintaikhoan SET matkhau = $1 WHERE email = $2', [hashedPassword, email]);

       // 6. Xóa OTP sau khi dùng thành công (One-time use)
       otpStore.delete(email);

       res.json({ status: 'success', message: 'Khôi phục và cập nhật mật khẩu thành công!' });
   } catch(e) {
       console.error("Reset Password Error:", e);
       res.status(500).json({ status: 'error', message: 'Lỗi server' });
   }
}


exports.googleLogin = async (req, res) => {
    try {
        const { idToken } = req.body;
        if (!idToken) return res.status(400).json({ status: 'error', message: 'Thiếu ID Token' });

        // 1. Xác thực Token với Google
        // Mảng các Client ID được phép (Chấp nhận cả Web và Android)
        const allowedClients = [
            process.env.GOOGLE_CLIENT_ID,
            "356822372175-2otcs9de40p96rudrprs00o3bb1shdds.apps.googleusercontent.com" // Android ID
        ];

        console.log("=> Đang xác thực ID Token với Audience mong muốn:", allowedClients);

        const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: allowedClients, // Truyền mảng để chấp nhận nhiều ID
        });
        const payload = ticket.getPayload();
        const { email, name, picture, sub: googleId } = payload;

        // 2. Kiểm tra user đã tồn tại chưa (qua email)
        let userRes = await db.query('SELECT * FROM thongtintaikhoan WHERE email = $1', [email]);
        let user;

        if (userRes.rows.length === 0) {
            // 3. Nếu chưa có, tạo user mới
            const maxRes = await db.query('SELECT COALESCE(MAX(id_khach), 0) as max_id FROM thongtintaikhoan');
            const num = parseInt(maxRes.rows[0].max_id) + 1;
            const maTaiKhoan = 'GG' + String(num).padStart(3, '0');

            const insertQuery = `
                INSERT INTO thongtintaikhoan (mataikhoan, hoten, email, anhdaidien, matkhau, sdt, ngaysinh)
                VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *
            `;
            // matkhau để trống hoặc random vì login qua Google, SĐT tạm để googleId hoặc trống
            const newUser = await db.query(insertQuery, [maTaiKhoan, name, email, picture, 'GOOGLE_AUTH_EXTERNAL', 'GG_' + googleId.slice(-8), '2000-01-01']);
            user = newUser.rows[0];
        } else {
            user = userRes.rows[0];
        }

        // 4. Ký token JWT
        const token = jwt.sign({ id: user.id_khach, role: 'Khach' }, JWT_SECRET, { expiresIn: '7d' });

        res.json({
            status: 'success',
            message: 'Đăng nhập Google thành công',
            token: token,
            user: {
                id: user.id_khach,
                maTaiKhoan: user.mataikhoan,
                hoTen: user.hoten,
                email: user.email,
                anhdaidien: user.anhdaidien
            }
        });

    } catch (e) {
        console.error("Google Login Error:", e.message);
        res.status(401).json({ status: 'error', message: 'Xác thực Google thất bại', detail: e.message });
    }
};

