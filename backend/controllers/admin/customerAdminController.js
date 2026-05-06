const db = require('../../config/db');
const { createNotification } = require('../../utils/notificationHelper');
const emailService = require('../../utils/emailService');

/**
 * Xem danh sách đơn đặt vé (kèm thông tin chi tiết: Mã Vé, tên khách hàng, Phim, Ghế, ngày chiếu, tổng tiền, trạng thái)
 * GET /api/admin/bookings
 * Query: ?movieId=...&theaterId=...&status=...
 */
exports.getBookings = async (req, res) => {
    try {
        const { movieId, theaterId, status } = req.query;

        let query = `
            SELECT 
                v.mavexemphim as ma_ve,
                d.madondatve,
                d.ngaydatve,
                d.tongtien,
                d.trangthai as trangthai_don,
                t.id_khach,
                t.hoten,
                t.email,
                t.sdt,
                p.maphim,
                p.tenphim,
                v.maghe,
                g.loaighe,
                g.mahangghe,
                g.soghe,
                lc.malichchieu,
                lc.ngaychieu,
                lc.giochieu,
                lc.gioketthuc,
                lc.giave as gia_ve_lichchieu,
                v.giave as gia_ve,
                v.trangthai as trangthai_ve,
                pr.maphong,
                pr.tenphong,
                r.marapphim,
                r.tenrapphim,
                tt.mathanhtoan,
                tt.phuongthucthanhtoan,
                tt.trangthai as trangthai_thanhtoan
            FROM vexemphim v
            JOIN dondatve d ON v.madondatve = d.madondatve
            JOIN thongtintaikhoan t ON d.id_khach = t.id_khach
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            JOIN ghengoi g ON v.maghe = g.maghe
            JOIN phongrapphim pr ON lc.maphong = pr.maphong
            JOIN rapphim r ON pr.marapphim = r.marapphim
            LEFT JOIN thongtinthanhtoan tt ON d.madondatve = tt.madondatve
        `;

        let conditions = [];
        let params = [];
        let paramIndex = 1;

        if (movieId) {
            conditions.push(`p.maphim = $${paramIndex}`);
            params.push(movieId);
            paramIndex++;
        }
        if (theaterId) {
            conditions.push(`r.marapphim = $${paramIndex}`);
            params.push(theaterId);
            paramIndex++;
        }
        if (status) {
            conditions.push(`d.trangthai = $${paramIndex}`);
            params.push(status);
            paramIndex++;
        }

        if (conditions.length > 0) {
            query += ' WHERE ' + conditions.join(' AND ');
        }

        query += ' ORDER BY d.ngaydatve DESC';

        const result = await db.query(query, params);

        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error("Get Bookings Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất danh sách đơn đặt vé' });
    }
};

/**
 * Xem danh sách và số lượng khách hàng
 * GET /api/admin/customers
 */
exports.getCustomers = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT id_khach, mataikhoan, hoten, ngaysinh, gioitinh, sdt, email, anhdaidien, ngaytao
            FROM thongtintaikhoan
            ORDER BY ngaytao DESC
        `);

        res.json({
            status: 'success',
            total: result.rowCount,
            data: result.rows
        });
    } catch (e) {
        console.error("Get Customers Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất danh sách khách hàng' });
    }
};

/**
 * Xoá khách hàng
 * DELETE /api/admin/customers/:id
 */
exports.deleteCustomer = async (req, res) => {
    try {
        const { id } = req.params;

        // Kiểm tra khách hàng tồn tại
        const checkRes = await db.query('SELECT * FROM thongtintaikhoan WHERE id_khach = $1', [id]);
        if (checkRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy khách hàng' });
        }

        // Kiểm tra khách có đơn đặt vé nào đang pending hoặc paid không
        const activeOrdersRes = await db.query(
            "SELECT COUNT(*) as cnt FROM dondatve WHERE id_khach = $1 AND trangthai IN ('pending', 'paid')", [id]
        );
        if (parseInt(activeOrdersRes.rows[0].cnt) > 0) {
            return res.status(400).json({
                status: 'error',
                message: 'Không thể xoá khách hàng này vì vẫn còn đơn đặt vé đang hoạt động.'
            });
        }

        await db.query('DELETE FROM thongtintaikhoan WHERE id_khach = $1', [id]);

        res.json({ status: 'success', message: 'Xoá khách hàng thành công' });
    } catch (e) {
        console.error("Delete Customer Error:", e);
        // Nếu lỗi FK constraint, trả thông báo thân thiện
        if (e.code === '23503') {
            return res.status(400).json({ status: 'error', message: 'Không thể xoá vì khách hàng có dữ liệu liên quan (bình luận, đặt vé...). Hãy xoá dữ liệu liên quan trước.' });
        }
        res.status(500).json({ status: 'error', message: 'Lỗi khi xoá khách hàng' });
    }
};

/**
 * Thay đổi trạng thái thanh toán
 * PUT /api/admin/payments/:id/status
 * Body: { trangthai } - giá trị: 'success', 'failed', 'pending'
 */
exports.updatePaymentStatus = async (req, res) => {
    try {
        const { id } = req.params; // maThanhToan
        const { trangthai } = req.body;

        if (!trangthai) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng cung cấp trạng thái mới' });
        }

        const validStatuses = ['success', 'failed', 'pending'];
        if (!validStatuses.includes(trangthai)) {
            return res.status(400).json({
                status: 'error',
                message: `Trạng thái không hợp lệ. Giá trị cho phép: ${validStatuses.join(', ')}`
            });
        }

        // Kiểm tra bản ghi thanh toán tồn tại
        const checkRes = await db.query('SELECT * FROM thongtinthanhtoan WHERE mathanhtoan = $1', [id]);
        if (checkRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy bản ghi thanh toán với mã: ' + id });
        }

        const result = await db.query(
            'UPDATE thongtinthanhtoan SET trangthai = $1 WHERE mathanhtoan = $2 RETURNING *',
            [trangthai, id]
        );

        // Nếu thanh toán thành công -> cập nhật đơn đặt vé sang 'paid'
        // Nếu thanh toán thất bại -> cập nhật đơn đặt vé sang 'cancelled' và gửi thông báo
        const maDonDatVe = result.rows[0].madondatve;
        if (trangthai === 'success') {
            await db.query("UPDATE dondatve SET trangthai = 'paid' WHERE madondatve = $1", [maDonDatVe]);
        } else if (trangthai === 'failed') {
            await db.query("UPDATE dondatve SET trangthai = 'cancelled' WHERE madondatve = $1", [maDonDatVe]);

            // Gửi thông báo in-app + email bất đồng bộ (không block response)
            (async () => {
                try {
                    // Lấy thông tin đầy đủ để gửi thông báo và email
                    const cancelInfoRes = await db.query(`
                        SELECT 
                            d.id_khach,
                            d.tongtien,
                            t.email,
                            t.hoten,
                            p.maphim,
                            p.tenphim,
                            r.tenrapphim,
                            pr.tenphong,
                            lc.ngaychieu,
                            lc.giochieu
                        FROM dondatve d
                        JOIN thongtintaikhoan t ON d.id_khach = t.id_khach
                        JOIN vexemphim v ON d.madondatve = v.madondatve
                        JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
                        JOIN phim p ON lc.maphim = p.maphim
                        JOIN phongrapphim pr ON lc.maphong = pr.maphong
                        JOIN rapphim r ON pr.marapphim = r.marapphim
                        WHERE d.madondatve = $1
                        LIMIT 1
                    `, [maDonDatVe]);

                    if (cancelInfoRes.rows.length > 0) {
                        const info = cancelInfoRes.rows[0];
                        const tongTienFormat = Number(info.tongtien).toLocaleString('vi-VN');

                        // 1. Thông báo in-app
                        await createNotification({
                            userId: info.id_khach,
                            tieuDe: 'Đơn hàng đã bị huỷ bởi hệ thống 🚫',
                            noiDung: `Đơn hàng ${maDonDatVe} tại ${info.tenrapphim} đã bị huỷ. Số tiền hoàn lại: ${tongTienFormat} VNĐ sẽ được xử lý trong 3-5 ngày làm việc.`,
                            maDonDatVe,
                            maPhim: info.maphim
                        });

                        // 2. Gửi Email thông báo huỷ
                        if (info.email) {
                            const gioChieuStr = info.giochieu instanceof Date
                                ? info.giochieu.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
                                : String(info.giochieu);
                            const ngayChieuStr = info.ngaychieu instanceof Date
                                ? info.ngaychieu.toLocaleDateString('vi-VN')
                                : String(info.ngaychieu);

                            await emailService.sendBookingCancelledEmail(info.email, {
                                maDonDatVe,
                                tenPhim: info.tenphim,
                                tongTien: info.tongtien,
                                tenRapPhim: info.tenrapphim,
                                tenPhong: info.tenphong,
                                ngayChieu: ngayChieuStr,
                                gioChieu: gioChieuStr
                            });
                        }
                    }
                } catch (err) {
                    console.error('Lỗi gửi thông báo huỷ đơn (non-critical):', err.message);
                }
            })();
        } else if (trangthai === 'pending') {
            await db.query("UPDATE dondatve SET trangthai = 'pending' WHERE madondatve = $1", [maDonDatVe]);
        }

        res.json({
            status: 'success',
            message: `Cập nhật trạng thái thanh toán ${id} thành '${trangthai}' thành công`,
            data: result.rows[0]
        });
    } catch (e) {
        console.error("Update Payment Status Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi cập nhật trạng thái thanh toán' });
    }
};
