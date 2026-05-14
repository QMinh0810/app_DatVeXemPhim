const db = require('./config/db');

async function seed() {
    try {
        const maDon = 'TEST' + Math.floor(Math.random() * 10000).toString();
        const idKhach = 3; // Lấy từ kết quả query trước
        const maGhe = 'G001';
        const maLichChieu = 'LC001';

        await db.query("INSERT INTO dondatve (madondatve, tongtien, trangthai, id_khach) VALUES ($1, $2, $3, $4)", 
            [maDon, 1000, 'pending', idKhach]);
        
        await db.query("INSERT INTO vexemphim (mavexemphim, trangthai, thoigianphathanh, thoigianhethan, giave, maghe, malichchieu, madondatve) VALUES ($1, $2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP + interval '10 minutes', $3, $4, $5, $6)", 
            [maDon + 'V', 'pending', 1000, maGhe, maLichChieu, maDon]);

        console.log(`Đã tạo đơn hàng test: ${maDon}`);
    } catch (e) {
        console.error("Lỗi seed:", e.message);
    } finally {
        process.exit();
    }
}

seed();
