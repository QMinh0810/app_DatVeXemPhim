const db = require('../config/db');
const bcrypt = require('bcrypt');

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

// Xem lịch sử đặt vé (có phân trang)
// Query params: page (default 1), limit (default 10), status (vd: 'paid', 'cancelled')
exports.getBookingHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, parseInt(req.query.limit) || 10));
        const status = req.query.status; // undefined = lấy tất cả trạng thái
        const offset = (page - 1) * limit;

        // Xây dựng điều kiện lọc trạng thái
        const params = [userId];
        let statusCondition = '';
        if (status) {
            // Hỗ trợ nhiều status cách nhau bởi dấu phẩy, vd: status=paid,completed
            const statusList = status.split(',').map(s => s.trim()).filter(Boolean);
            if (statusList.length === 1) {
                params.push(statusList[0]);
                statusCondition = `AND d.trangthai = $${params.length}`;
            } else if (statusList.length > 1) {
                params.push(statusList);
                statusCondition = `AND d.trangthai = ANY($${params.length})`;
            }
        }

        // Query đếm tổng số đơn hàng (để tính totalPages)
        const countQuery = `
            SELECT COUNT(DISTINCT d.madondatve) as total
            FROM dondatve d
            WHERE d.id_khach = $1
            ${statusCondition}
        `;
        const countResult = await db.query(countQuery, params);
        const total = parseInt(countResult.rows[0].total) || 0;
        const totalPages = Math.ceil(total / limit);

        // Query lấy danh sách đơn phân trang
        // Dùng subquery để lấy đúng page theo đơn hàng trước, rồi join vé
        const pageParams = [...params, limit, offset];
        const pageParamOffset = params.length;
        const dataQuery = `
            WITH paginated_orders AS (
                SELECT DISTINCT d.madondatve, d.ngaydatve
                FROM dondatve d
                WHERE d.id_khach = $1
                ${statusCondition}
                ORDER BY d.ngaydatve DESC
                LIMIT $${pageParamOffset + 1} OFFSET $${pageParamOffset + 2}
            )
            SELECT d.madondatve, d.tongtien, d.trangthai as order_status, d.ngaydatve,
                   v.mavexemphim, v.giave as ticket_price, v.maghe, v.trangthai as ticket_status, v.qrcode,
                   (g.mahangghe || g.soghe) as tenghe,
                   TO_CHAR(lc.ngaychieu, 'YYYY-MM-DD') as ngaychieu,
                   TO_CHAR(lc.giochieu, 'HH24:MI') as giochieu,
                   p.tenphim, p.poster_url,
                   r.tenrapphim, r.diachi, pr.tenphong
            FROM paginated_orders po
            JOIN dondatve d ON d.madondatve = po.madondatve
            JOIN vexemphim v ON d.madondatve = v.madondatve
            LEFT JOIN ghengoi g ON v.maghe = g.maghe
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            ORDER BY d.ngaydatve DESC
        `;

        const result = await db.query(dataQuery, pageParams);

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
                    tenRapPhim: row.tenrapphim,
                    diaChi: row.diachi,
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
                tenGhe: row.tenghe,
                trangThai: row.ticket_status,
                qrCode: row.qrcode
            });
        });

        res.json({
            status: 'success',
            data: history,
            pagination: {
                total,
                page,
                limit,
                totalPages,
                hasMore: page < totalPages
            }
        });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi lấy lịch sử đặt vé' });
    }
};

// Đổi mật khẩu
exports.changePassword = async (req, res) => {
    try {
        const userId = req.user.id;
        const { oldPassword, newPassword } = req.body;

        // 1. Lấy thông tin user hiện tại
        const result = await db.query('SELECT matkhau, mataikhoan FROM thongtintaikhoan WHERE id_khach = $1', [userId]);
        if (result.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
        }

        const user = result.rows[0];

        // 2. Chặn nếu là tài khoản Google (không có mật khẩu cục bộ)
        if (user.mataikhoan.toLowerCase().startsWith('gg')) {
            return res.status(400).json({ status: 'error', message: 'Tài khoản Google không hỗ trợ đổi mật khẩu theo cách này' });
        }

        // 3. Kiểm tra mật khẩu cũ
        const isMatch = await bcrypt.compare(oldPassword, user.matkhau);
        if (!isMatch && oldPassword !== user.matkhau) {
            return res.status(401).json({ status: 'error', message: 'Mật khẩu cũ không chính xác' });
        }

        // 4. Hash mật khẩu mới
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);

        // 5. Cập nhật vào DB
        await db.query('UPDATE thongtintaikhoan SET matkhau = $1 WHERE id_khach = $2', [hashedPassword, userId]);

        res.json({ status: 'success', message: 'Đổi mật khẩu thành công' });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi server khi đổi mật khẩu' });
    }
};
