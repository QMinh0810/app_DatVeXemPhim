/**
 * Script thực thi các lệnh ALTER TABLE / CREATE TABLE
 * Chạy: node backend/alter_db.js
 */
const db = require('./config/db');

async function alterDB() {
    try {
        console.log("=== BẮT ĐẦU ALTER DATABASE ===");

        // 1. Thêm loại ghế 'hỏng'
        console.log("1. Cập nhật constraint loaiGhe...");
        await db.query("ALTER TABLE ghengoi DROP CONSTRAINT IF EXISTS ghengoi_loaighe_check");
        await db.query("ALTER TABLE ghengoi ADD CONSTRAINT ghengoi_loaighe_check CHECK (loaighe IN ('normal', 'vip', 'couple', 'hỏng'))");
        console.log("   ✅ Đã thêm loại ghế 'hỏng'");

        // 2. Thêm trạng thái thanh toán 'pending'
        console.log("2. Cập nhật constraint trạng thái thanh toán...");
        await db.query("ALTER TABLE thongtinthanhtoan DROP CONSTRAINT IF EXISTS thongtinthanhtoan_trangthai_check");
        await db.query("ALTER TABLE thongtinthanhtoan ADD CONSTRAINT thongtinthanhtoan_trangthai_check CHECK (trangthai IN ('success', 'failed', 'pending'))");
        console.log("   ✅ Đã thêm trạng thái thanh toán 'pending'");

        // 3. Thêm urlanhdaidien cho daodien và dienvien
        console.log("3. Thêm cột urlanhdaidien cho daodien và dienvien...");
        await db.query("ALTER TABLE daodien ADD COLUMN IF NOT EXISTS urlanhdaidien VARCHAR(500)");
        await db.query("ALTER TABLE dienvien ADD COLUMN IF NOT EXISTS urlanhdaidien VARCHAR(500)");
        console.log("   ✅ Đã thêm cột urlanhdaidien");

        // 4. Thêm cột unit cho items
        console.log("4. Thêm cột unit cho items...");
        await db.query("ALTER TABLE items ADD COLUMN IF NOT EXISTS unit VARCHAR(50)");
        console.log("   ✅ Đã thêm cột unit cho items");

        // 5. Tạo bảng order_concessions để lưu combo đồ ăn đặt kèm vé
        console.log("5. Tạo bảng order_concessions...");
        await db.query(`
            CREATE TABLE IF NOT EXISTS order_concessions (
                id SERIAL PRIMARY KEY,
                madondatve VARCHAR(10) NOT NULL,
                combo_id INTEGER NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 1,
                unit_price INTEGER NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                CONSTRAINT fk_oc_dondatve FOREIGN KEY (madondatve) REFERENCES dondatve(madondatve) ON DELETE CASCADE,
                CONSTRAINT fk_oc_combo FOREIGN KEY (combo_id) REFERENCES combos(combo_id)
            )
        `);
        console.log("   ✅ Đã tạo bảng order_concessions");

        // 6. Thêm cột trangthai cho thongtintaikhoan (active/disabled)
        console.log("6. Thêm cột trangthai cho thongtintaikhoan...");
        await db.query("ALTER TABLE thongtintaikhoan ADD COLUMN IF NOT EXISTS trangthai VARCHAR(20) DEFAULT 'active' NOT NULL");
        await db.query("ALTER TABLE thongtintaikhoan DROP CONSTRAINT IF EXISTS thongtintaikhoan_trangthai_check");
        await db.query("ALTER TABLE thongtintaikhoan ADD CONSTRAINT thongtintaikhoan_trangthai_check CHECK (trangthai IN ('active', 'disabled'))");
        console.log("   ✅ Đã thêm cột trangthai cho thongtintaikhoan");

        console.log("\n✅ ALTER DATABASE HOÀN THÀNH!");
        process.exit(0);
    } catch (e) {
        console.error("❌ LỖI ALTER DATABASE:", e);
        process.exit(1);
    }
}

alterDB();
