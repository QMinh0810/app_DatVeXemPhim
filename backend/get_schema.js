// Lưu file này là: backend/get_schema.js
const { Client } = require('pg');

// Sửa lại Connection String của Neon DB của bạn vào đây
const connectionString = 'postgresql://neondb_owner:npg_m2z4fFZjQIyl@ep-cool-field-a1jhgki6-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

const client = new Client({ connectionString });

async function getKhungDatabase() {
    await client.connect();

    // Lấy thông tin các bảng
    const tables = await client.query(`
        SELECT table_name, column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        ORDER BY table_name, ordinal_position;
    `);

    let currentTable = '';
    for (let row of tables.rows) {
        if (currentTable !== row.table_name) {
            console.log(`\n--- BẢNG: ${row.table_name} ---`);
            currentTable = row.table_name;
        }
        console.log(`- Cột: ${row.column_name} | Kiểu dữ liệu: ${row.data_type}`);
    }

    await client.end();
}

getKhungDatabase().catch(console.error);
