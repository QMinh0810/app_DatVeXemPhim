const fs = require('fs');
const path = require('path');
const db = require('./config/db');

async function migrate() {
    try {
        console.log("=== BẮT ĐẦU KỊCH BẢN MIGRATE ===");
        
        let schemaSql = fs.readFileSync(path.join(__dirname, '../script_sql.md'), 'utf-8');
        schemaSql = schemaSql.replace(/```sql/gi, '').replace(/```/gi, '');

        schemaSql = schemaSql
            .replace(/\[/g, '')
            .replace(/\]/g, '')
            .replace(/N'/g, "'")
            .replace(/\bInteger IDENTITY\(1,1\)/gi, 'SERIAL')
            .replace(/\bDatetime\b/gi, 'TIMESTAMP')
            .replace(/\bNvarchar\(\d+\)/gi, 'VARCHAR(500)')
            .replace(/\bVarchar\(\d+\)/gi, 'VARCHAR(500)')
            .replace(/\bChar\(\d+\)/gi, 'VARCHAR(50)')
            .replace(/\bBit\b/gi, 'SMALLINT')
            .replace(/\bFloat\b/gi, 'NUMERIC')
            .replace(/\bGETDATE\(\)/gi, 'CURRENT_TIMESTAMP');

        let schemaQueries = schemaSql.split(/\bgo\b/i).map(q => q.trim()).filter(q => q !== '');

        let seedSql = fs.readFileSync(path.join(__dirname, '../database_seed.sql'), 'utf-8');
        seedSql = seedSql
            .replace(/\[/g, '')
            .replace(/\]/g, '')
            .replace(/N'/g, "'");
            
        let seedQueries = seedSql.split(';').map(q => q.trim()).filter(q => q !== '');

        console.log("=> Đang drop tất cả Object cũ (nếu có)...");
        // Lấy danh sách bảng để DROP (tùy chọn an toàn nhất: drop schema public cascade)
        await db.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');

        console.log("1. Đang xây dựng cấu trúc các Bảng (Create Tables)...");
        for (let q of schemaQueries) {
             if (q.startsWith("Set quoted_identifier") || q.startsWith(".")) continue;
             try {
                 await db.query(q);
             } catch (e) {
                 console.error("LỖI TẠI CÂU LỆNH:", q);
                 throw e;
             }
        }

        console.log("2. Đang nạp Dữ liệu tĩnh (Seed Data)...");
        for (let sq of seedQueries) {
            if (sq.startsWith("SELECT")) continue; // Bỏ qua câu SELECT cuối
            await db.query(sq);
        }
        
        console.log("✅ Migrate CHÍNH THỨC HOÀN THÀNH 100%!");
        process.exit(0);

    } catch (e) {
        console.error("❌ LỖI MIGRATE:", e);
        process.exit(1);
    }
}

migrate();
