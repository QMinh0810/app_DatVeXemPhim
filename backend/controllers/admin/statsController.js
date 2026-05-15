const db = require('../../config/db');
const ExcelJS = require('exceljs');

/**
 * Số lượt đặt vé theo phim
 * GET /api/admin/stats/bookings-by-movie
 */
exports.bookingsByMovie = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT p.maphim, p.tenphim, p.poster_url,
                   COUNT(v.mavexemphim)::int as so_ve,
                   COALESCE(SUM(v.giave), 0)::int as tong_tien
            FROM phim p
            LEFT JOIN lichchieu lc ON p.maphim = lc.maphim
            LEFT JOIN vexemphim v ON lc.malichchieu = v.malichchieu
            LEFT JOIN dondatve d ON v.madondatve = d.madondatve AND d.trangthai = 'paid'
            GROUP BY p.maphim, p.tenphim, p.poster_url
            ORDER BY so_ve DESC
        `);

        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error("Stats bookings-by-movie Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi thống kê theo phim' });
    }
};

/**
 * Số lượt đặt vé theo rạp
 * GET /api/admin/stats/bookings-by-theater
 */
exports.bookingsByTheater = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT r.marapphim, r.tenrapphim, r.diachi,
                   COUNT(v.mavexemphim)::int as so_ve,
                   COALESCE(SUM(v.giave), 0)::int as tong_tien
            FROM rapphim r
            LEFT JOIN phongrapphim pr ON r.marapphim = pr.marapphim
            LEFT JOIN lichchieu lc ON pr.maphong = lc.maphong
            LEFT JOIN vexemphim v ON lc.malichchieu = v.malichchieu
            LEFT JOIN dondatve d ON v.madondatve = d.madondatve AND d.trangthai = 'paid'
            GROUP BY r.marapphim, r.tenrapphim, r.diachi
            ORDER BY so_ve DESC
        `);

        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error("Stats bookings-by-theater Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi thống kê theo rạp' });
    }
};

/**
 * Doanh thu theo từng phim (dùng số vé thay vì số đơn)
 * GET /api/admin/stats/revenue-by-movie
 */
exports.revenueByMovie = async (req, res) => {
    console.log("Stats: Fetching revenue by movie...");
    try {
        const result = await db.query(`
            SELECT p.maphim, p.tenphim,
                   COUNT(v.mavexemphim)::int as so_ve,
                   COALESCE(SUM(v.giave), 0)::int as doanh_thu
            FROM phim p
            LEFT JOIN lichchieu lc ON p.maphim = lc.maphim
            LEFT JOIN vexemphim v ON lc.malichchieu = v.malichchieu
            LEFT JOIN dondatve d ON v.madondatve = d.madondatve AND d.trangthai = 'paid'
            GROUP BY p.maphim, p.tenphim
            ORDER BY doanh_thu DESC
        `);
        console.log(`Stats: Found ${result.rows.length} movies in stats.`);

        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error("Stats revenue-by-movie Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi thống kê doanh thu' });
    }
};

/**
 * Thống kê doanh thu theo ngày
 * GET /api/admin/stats/daily-revenue?from=2024-04-01&to=2024-04-30
 * Trả về: ngày, tiền bán vé, tiền F&B, tiền hoàn huỷ vé, doanh thu thực tế
 */
exports.dailyRevenueStats = async (req, res) => {
    try {
        const { from, to } = req.query;

        if (!from || !to) {
            return res.status(400).json({
                status: 'error',
                message: 'Vui lòng cung cấp tham số from và to (VD: from=2024-04-01&to=2024-04-30)'
            });
        }

        // 1. Tiền bán vé theo ngày (chỉ tính đơn paid)
        const ticketRevenueQuery = `
            SELECT 
                DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') as ngay,
                COALESCE(SUM(CASE WHEN d.trangthai = 'paid' THEN d.tongtien ELSE 0 END), 0) as tien_ban_ve,
                COALESCE(SUM(CASE WHEN d.trangthai = 'cancelled' THEN d.tongtien ELSE 0 END), 0) as tien_hoan_huy
            FROM dondatve d
            WHERE DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') BETWEEN $1 AND $2
            GROUP BY DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh')
            ORDER BY ngay
        `;
        const ticketRes = await db.query(ticketRevenueQuery, [from, to]);

        // 2. Tiền F&B theo ngày (nếu có bảng order_items hoặc tương tự)
        // Hiện tại chưa có bảng liên kết đơn hàng với items/combos,
        // nên tạm thời trả 0 cho tiền F&B. Khi có bảng, sẽ cập nhật query.
        const dailyData = ticketRes.rows.map(row => ({
            ngay: row.ngay,
            tien_ban_ve: parseInt(row.tien_ban_ve),
            tien_fb: 0, // TODO: Cập nhật khi có bảng đơn hàng F&B
            tien_hoan_huy: parseInt(row.tien_hoan_huy),
            doanh_thu_thuc_te: parseInt(row.tien_ban_ve) - parseInt(row.tien_hoan_huy)
        }));

        res.json({ status: 'success', data: dailyData });
    } catch (e) {
        console.error("Daily Revenue Stats Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi thống kê doanh thu theo ngày' });
    }
};

/**
 * Doanh thu 7 ngày gần nhất (cho biểu đồ cột tuần)
 * GET /api/admin/stats/weekly-revenue
 * Trả về: mảng 7 phần tử { ngay, nhan (T2-CN), doanh_thu }
 */
exports.weeklyRevenueStats = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT
                DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') as ngay,
                EXTRACT(DOW FROM d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') as thu_trong_tuan,
                COALESCE(SUM(CASE WHEN d.trangthai = 'paid' THEN d.tongtien ELSE 0 END), 0) as doanh_thu
            FROM dondatve d
            WHERE DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') >= CURRENT_DATE - INTERVAL '6 days'
              AND DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') <= CURRENT_DATE
            GROUP BY DATE(d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh'), EXTRACT(DOW FROM d.ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh')
            ORDER BY ngay ASC
        `);

        // Tạo mảng 7 ngày (T2 -> CN) đầy đủ, kể cả ngày không có doanh thu
        const dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        const revenueMap = {};
        result.rows.forEach(row => {
            revenueMap[row.ngay.toISOString().split('T')[0]] = {
                nhan: dayLabels[parseInt(row.thu_trong_tuan)],
                doanh_thu: parseInt(row.doanh_thu)
            };
        });

        // Đảm bảo 7 ngày đều có dữ liệu
        const sevenDays = [];
        for (let i = 6; i >= 0; i--) {
            const date = new Date();
            date.setDate(date.getDate() - i);
            const dateStr = date.toISOString().split('T')[0];
            const dow = date.getDay();
            sevenDays.push({
                ngay: dateStr,
                nhan: dayLabels[dow],
                doanh_thu: revenueMap[dateStr]?.doanh_thu ?? 0
            });
        }

        res.json({ status: 'success', data: sevenDays });
    } catch (e) {
        console.error("Weekly Revenue Stats Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi thống kê doanh thu theo tuần' });
    }
};

/**
 * Xuất báo cáo XLSX hàng tháng
 * GET /api/admin/reports/monthly?month=2024-04
 */
exports.monthlyReport = async (req, res) => {
    try {
        const { month } = req.query; // Format: YYYY-MM

        if (!month || !/^\d{4}-\d{2}$/.test(month)) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng truyền tham số month theo định dạng YYYY-MM (VD: 2024-04)' });
        }

        const [year, mon] = month.split('-');

        // 1. Lấy thông tin tổng quan
        const summaryQuery = `
            SELECT 
                COUNT(DISTINCT d.madondatve) as tong_don,
                COUNT(v.mavexemphim) as tong_ve,
                COALESCE(SUM(CASE WHEN d.trangthai = 'paid' THEN d.tongtien ELSE 0 END), 0) as tong_doanh_thu
            FROM dondatve d
            LEFT JOIN vexemphim v ON d.madondatve = v.madondatve
            WHERE EXTRACT(YEAR FROM d.ngaydatve) = $1
              AND EXTRACT(MONTH FROM d.ngaydatve) = $2
        `;
        const summaryRes = await db.query(summaryQuery, [year, mon]);
        const summary = summaryRes.rows[0];

        // 2. Lấy chi tiết doanh thu theo phim
        const detailQuery = `
            SELECT p.tenphim,
                   COUNT(v.mavexemphim) as so_ve,
                   COALESCE(SUM(v.giave), 0) as doanh_thu
            FROM dondatve d
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            WHERE d.trangthai = 'paid'
              AND EXTRACT(YEAR FROM d.ngaydatve) = $1
              AND EXTRACT(MONTH FROM d.ngaydatve) = $2
            GROUP BY p.tenphim
            ORDER BY doanh_thu DESC
        `;
        const detailRes = await db.query(detailQuery, [year, mon]);

        // 3. Lấy danh sách vé chi tiết
        const ticketQuery = `
            SELECT d.madondatve, d.ngaydatve, d.tongtien, d.trangthai,
                   t.hoten, t.email,
                   p.tenphim, lc.ngaychieu, lc.giochieu,
                   v.maghe, v.giave as gia_ve
            FROM dondatve d
            JOIN thongtintaikhoan t ON d.id_khach = t.id_khach
            JOIN vexemphim v ON d.madondatve = v.madondatve
            JOIN lichchieu lc ON v.malichchieu = lc.malichchieu
            JOIN phim p ON lc.maphim = p.maphim
            WHERE d.trangthai = 'paid'
              AND EXTRACT(YEAR FROM d.ngaydatve) = $1
              AND EXTRACT(MONTH FROM d.ngaydatve) = $2
            ORDER BY d.ngaydatve DESC
        `;
        const ticketRes = await db.query(ticketQuery, [year, mon]);

        // 4. Tạo file XLSX bằng ExcelJS
        const workbook = new ExcelJS.Workbook();
        workbook.creator = 'Nhom 7 Cinema';
        workbook.created = new Date();

        // ===== Sheet 1: TỔNG QUAN =====
        const sheetSummary = workbook.addWorksheet('Tổng Quan');
        
        // Tiêu đề
        sheetSummary.mergeCells('A1:D1');
        const titleCell = sheetSummary.getCell('A1');
        titleCell.value = `BÁO CÁO DOANH THU THÁNG ${mon}/${year}`;
        titleCell.font = { size: 16, bold: true, color: { argb: 'FFFFFF' } };
        titleCell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5496' } };
        titleCell.alignment = { horizontal: 'center' };

        sheetSummary.addRow([]);
        sheetSummary.addRow(['Tổng số đơn đặt vé:', parseInt(summary.tong_don)]);
        sheetSummary.addRow(['Tổng số vé bán ra:', parseInt(summary.tong_ve)]);
        sheetSummary.addRow(['Tổng doanh thu (VND):', parseInt(summary.tong_doanh_thu)]);

        // Style cho cột
        sheetSummary.getColumn(1).width = 25;
        sheetSummary.getColumn(2).width = 20;

        // ===== Sheet 2: DOANH THU THEO PHIM =====
        const sheetDetail = workbook.addWorksheet('Doanh Thu Theo Phim');
        
        sheetDetail.columns = [
            { header: 'Tên Phim', key: 'tenphim', width: 35 },
            { header: 'Số Vé', key: 'so_ve', width: 12 },
            { header: 'Doanh Thu (VND)', key: 'doanh_thu', width: 20 },
        ];

        // Style header
        sheetDetail.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' } };
        sheetDetail.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5496' } };

        for (const row of detailRes.rows) {
            sheetDetail.addRow({
                tenphim: row.tenphim,
                so_ve: parseInt(row.so_ve),
                doanh_thu: parseInt(row.doanh_thu)
            });
        }

        // Dòng tổng cộng
        const totalRow = sheetDetail.addRow({
            tenphim: 'TỔNG CỘNG',
            so_ve: detailRes.rows.reduce((sum, r) => sum + parseInt(r.so_ve), 0),
            doanh_thu: detailRes.rows.reduce((sum, r) => sum + parseInt(r.doanh_thu), 0)
        });
        totalRow.font = { bold: true };

        // ===== Sheet 3: CHI TIẾT VÉ =====
        const sheetTickets = workbook.addWorksheet('Chi Tiết Vé');
        
        sheetTickets.columns = [
            { header: 'STT', key: 'stt', width: 6 },
            { header: 'Mã Đơn', key: 'madondatve', width: 12 },
            { header: 'Khách Hàng', key: 'hoten', width: 22 },
            { header: 'Email', key: 'email', width: 28 },
            { header: 'Phim', key: 'tenphim', width: 30 },
            { header: 'Ngày Chiếu', key: 'ngaychieu', width: 14 },
            { header: 'Giờ Chiếu', key: 'giochieu', width: 14 },
            { header: 'Ghế', key: 'maghe', width: 10 },
            { header: 'Giá Vé (VND)', key: 'gia_ve', width: 15 },
            { header: 'Tổng Tiền (VND)', key: 'tongtien', width: 15 },
            { header: 'Ngày Đặt', key: 'ngaydatve', width: 14 },
        ];

        // Style header
        sheetTickets.getRow(1).font = { bold: true, color: { argb: 'FFFFFF' } };
        sheetTickets.getRow(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: '2F5496' } };

        ticketRes.rows.forEach((t, index) => {
            sheetTickets.addRow({
                stt: index + 1,
                madondatve: t.madondatve,
                hoten: t.hoten,
                email: t.email,
                tenphim: t.tenphim,
                ngaychieu: t.ngaychieu ? new Date(t.ngaychieu).toLocaleDateString('vi-VN') : 'N/A',
                giochieu: t.giochieu ? new Date(t.giochieu).toLocaleTimeString('vi-VN') : 'N/A',
                maghe: t.maghe,
                gia_ve: parseInt(t.gia_ve),
                tongtien: parseInt(t.tongtien),
                ngaydatve: t.ngaydatve ? new Date(t.ngaydatve).toLocaleDateString('vi-VN') : 'N/A',
            });
        });

        // Set response headers cho file XLSX
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', `attachment; filename=BaoCao_Thang_${month}.xlsx`);

        await workbook.xlsx.write(res);
        res.end();

    } catch (e) {
        console.error("Monthly Report Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi xuất báo cáo' });
    }
};

/**
 * Tổng quan Dashboard (hôm nay)
 * GET /api/admin/stats/dashboard-summary
 */
exports.dashboardSummary = async (req, res) => {
    try {
        const today = new Date().toISOString().split('T')[0];

        // 1. Doanh thu hôm nay
        const revenueRes = await db.query(
            "SELECT COALESCE(SUM(tongtien), 0)::int as total FROM dondatve WHERE DATE(ngaydatve AT TIME ZONE 'Asia/Ho_Chi_Minh') = $1 AND trangthai = 'paid'",
            [today]
        );

        // 2. Vé bán hôm nay (theo thời gian phát hành vé)
        const ticketsRes = await db.query(
            "SELECT COUNT(*)::int as total FROM vexemphim WHERE DATE(thoigianphathanh) = $1 AND trangthai = 'active'",
            [today]
        );

        // 3. Phim đang chiếu (theo trạng thái now_showing)
        const moviesRes = await db.query(
            "SELECT COUNT(*)::int as total FROM phim WHERE trangthai = 'now_showing'"
        );

        // 4. Tổng khách hàng
        const customersRes = await db.query("SELECT COUNT(*)::int as total FROM thongtintaikhoan");

        // 5. Phim hot (dựa trên số vé bán ra)
        const hotMoviesRes = await db.query(`
            SELECT p.maphim, p.tenphim, p.poster_url, COUNT(v.mavexemphim)::int as so_ve
            FROM phim p
            JOIN lichchieu lc ON p.maphim = lc.maphim
            JOIN vexemphim v ON lc.malichchieu = v.malichchieu
            JOIN dondatve d ON v.madondatve = d.madondatve AND d.trangthai = 'paid'
            GROUP BY p.maphim, p.tenphim, p.poster_url
            ORDER BY so_ve DESC
            LIMIT 5
        `);

        res.json({
            status: 'success',
            data: {
                totalRevenueToday: revenueRes.rows[0].total,
                ticketSoldToday: ticketsRes.rows[0].total,
                moviesNowShowing: moviesRes.rows[0].total,
                totalCustomersToday: customersRes.rows[0].total,
                hotMovies: hotMoviesRes.rows
            }
        });
    } catch (e) {
        console.error("Dashboard Summary Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi tải dữ liệu tổng quan' });
    }
};
