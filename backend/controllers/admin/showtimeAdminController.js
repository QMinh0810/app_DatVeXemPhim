const db = require('../../config/db');

/**
 * Tạo lịch chiếu mới (Phân bổ phim vào phòng)
 * POST /api/admin/showtimes
 * Body: { maPhim, maPhong, ngayChieu, gioChieu, giaVe }
 * gioKetThuc sẽ được TỰ ĐỘNG TÍNH = gioChieu + thoiLuong phim + 15 phút
 */
exports.createShowtime = async (req, res) => {
    try {
        const { maPhim, maPhong, ngayChieu, gioChieu, giaVe } = req.body;

        if (!maPhim || !maPhong || !ngayChieu || !gioChieu || !giaVe) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng điền đầy đủ thông tin: maPhim, maPhong, ngayChieu, gioChieu, giaVe' });
        }

        // 1. Lấy thời lượng phim từ bảng Phim
        const phimRes = await db.query('SELECT thoiluong FROM phim WHERE maphim = $1', [maPhim]);
        if (phimRes.rows.length === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy phim với mã: ' + maPhim });
        }
        const thoiLuong = parseInt(phimRes.rows[0].thoiluong); // phút

        // 2. Tự động tính giờ kết thúc = giờ chiếu + thời lượng phim + 15 phút nghỉ
        const gioChieuDate = new Date(gioChieu);
        const gioKetThucDate = new Date(gioChieuDate.getTime() + (thoiLuong + 15) * 60 * 1000);
        const gioKetThuc = gioKetThucDate.toISOString();

        // 3. Kiểm tra trùng lịch chiếu (chồng chéo giờ tại cùng phòng)
        const overlapQuery = `
            SELECT * FROM lichchieu 
            WHERE maphong = $1 
              AND ngaychieu::date = $2::date
              AND (
                ($3::timestamp < gioketthuc AND $4::timestamp > giochieu)
              )
        `;
        const overlapRes = await db.query(overlapQuery, [maPhong, ngayChieu, gioChieu, gioKetThuc]);

        if (overlapRes.rows.length > 0) {
            return res.status(400).json({
                status: 'error',
                message: 'Khung giờ này đã có lịch chiếu tại phòng đã chọn. Vui lòng chọn giờ khác.',
                conflictWith: overlapRes.rows[0]
            });
        }

        // 4. Sinh mã lịch chiếu
        const maxRes = await db.query("SELECT COUNT(*) as cnt FROM lichchieu");
        const maLichChieu = 'LC' + String(parseInt(maxRes.rows[0].cnt) + 1).padStart(3, '0');

        // 5. Insert
        const insertQuery = `
            INSERT INTO lichchieu (malichchieu, ngaychieu, giochieu, gioketthuc, giave, maphim, maphong)
            VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *
        `;
        const result = await db.query(insertQuery, [maLichChieu, ngayChieu, gioChieu, gioKetThuc, giaVe, maPhim, maPhong]);

        res.status(201).json({
            status: 'success',
            message: `Tạo lịch chiếu thành công. Giờ kết thúc tự động: ${gioKetThucDate.toLocaleString('vi-VN')} (thời lượng ${thoiLuong} phút + 15 phút nghỉ)`,
            data: result.rows[0]
        });
    } catch (e) {
        console.error("Create Showtime Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi tạo lịch chiếu' });
    }
};
