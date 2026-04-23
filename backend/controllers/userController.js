const db = require('../config/db');

// Lấy thông tin cá nhân
exports.getProfile = async (req, res) => {
    try {
        const userId = req.user.id; // Lấy trực tiếp từ Token đã xác thực

        const result = await db.query('SELECT id_khach, mataikhoan, hoten, ngaysinh, gioitinh, sdt, email, anhdaidien, ngaytao FROM thongtintaikhoan WHERE id_khach = $1', [userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
        }

        res.json({ status: 'success', data: result.rows[0] });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy thông tin profile' });
    }
};

// Cập nhật thông tin cá nhân
exports.updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { hoTen, ngaySinh, gioiTinh, anhDaiDien, sdt, email } = req.body;

        // 1. Kiểm tra xem có phải tài khoản Google không (để chặn đổi email)
        const userCheck = await db.query('SELECT mataikhoan FROM thongtintaikhoan WHERE id_khach = $1', [userId]);
        if (userCheck.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
        }

        const isGoogleUser = userCheck.rows[0].mataikhoan.toLowerCase().startsWith('gg');

        // 2. Thực hiện cập nhật
        const updateQuery = `
            UPDATE thongtintaikhoan 
            SET hoten = COALESCE($1, hoten), 
                ngaysinh = COALESCE($2, ngaysinh), 
                gioitinh = COALESCE($3, gioitinh), 
                anhdaidien = COALESCE($4, anhdaidien),
                sdt = COALESCE($5, sdt),
                email = CASE 
                    WHEN $7 = true THEN email -- Nếu là gg thì giữ nguyên email cũ
                    ELSE COALESCE($6, email) 
                END,
                ngaycapnhat = CURRENT_TIMESTAMP
            WHERE id_khach = $8
            RETURNING id_khach, mataikhoan, hoten, email, sdt, anhdaidien
        `;
        
        const result = await db.query(updateQuery, [hoTen, ngaySinh, gioiTinh, anhDaiDien, sdt, email, isGoogleUser, userId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Cập nhật thất bại' });
        }

        res.json({ status: 'success', message: 'Cập nhật thông tin thành công', data: result.rows[0] });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi cập nhật profile' });
    }
};

// Xem lịch sử đặt vé
exports.getBookingHistory = async (req, res) => {
    try {
        const userId = req.user.id;

        const query = `
            SELECT d.madondatve, d.tongtien, d.trangthai as order_status, d.ngaydatve,
                   v.mavexemphim, v.giave as ticket_price, v.maghe, v.trangthai as ticket_status, v.qrcode,
                   lc.ngaychieu, lc.giochieu,
                   p.tenphim, p.poster_url,
                   r.tenrapphim, pr.tenphong
            FROM dondatve d
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            WHERE d.id_khach = $1
            ORDER BY d.ngaydatve DESC
        `;

        const result = await db.query(query, [userId]);

        // Tổ chức lại dữ liệu theo đơn hàng
        const history = [];
        const orders = {};

        result.rows.forEach(row => {
            if (!orders[row.madondatve]) {
                orders[row.madondatve] = {
                    maDonDatVe: row.madondatve,
                    tongTien: row.tongtien,
                    trangThai: row.order_status,
                    ngayDatVe: row.ngaydatve,
                    tenPhim: row.tenphim,
                    posterUrl: row.poster_url,
                    tenRapPhim: row.tenraphim,
                    tenPhong: row.tenphong,
                    ngayChieu: row.ngaychieu,
                    gioChieu: row.giochieu,
                    tickets: []
                };
                history.push(orders[row.madondatve]);
            }
            orders[row.madondatve].tickets.push({
                maVe: row.mavexemphim,
                giaVe: row.ticket_price,
                maGhe: row.maghe,
                trangThai: row.ticket_status,
                qrCode: row.qrcode
            });
        });

        res.json({ status: 'success', data: history });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy lịch sử đặt vé' });
    }
};
