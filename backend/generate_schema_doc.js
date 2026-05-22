const { Client } = require('pg');
const fs = require('fs');
const path = require('path');

const connectionString = 'postgresql://neondb_owner:npg_m2z4fFZjQIyl@ep-cool-field-a1jhgki6-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';
const client = new Client({ connectionString });

async function main() {
    await client.connect();
    
    // Query columns
    const columnsRes = await client.query(`
        SELECT 
            table_name, 
            column_name, 
            data_type, 
            is_nullable, 
            column_default
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        ORDER BY table_name, ordinal_position;
    `);

    // Organize by table
    const db = {};
    for (let row of columnsRes.rows) {
        if (!db[row.table_name]) {
            db[row.table_name] = [];
        }
        db[row.table_name].push(row);
    }

    let markdown = `# Cấu Trúc Database (Schema) - Neon DB\n\n`;
    markdown += `*Danh sách chi tiết các bảng, cột, kiểu dữ liệu trong cơ sở dữ liệu.*\n\n`;

    for (let tableName in db) {
        markdown += `## Bảng: \`${tableName}\`\n\n`;
        markdown += `| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |\n`;
        markdown += `| :--- | :--- | :--- | :--- |\n`;
        for (let col of db[tableName]) {
            markdown += `| \`${col.column_name}\` | \`${col.data_type}\` | \`${col.is_nullable}\` | \`${col.column_default || ''}\` |\n`;
        }
        markdown += `\n`;
    }

    const outputPath = path.join(__dirname, '..', 'db_schema.md');
    fs.writeFileSync(outputPath, markdown, 'utf-8');
    console.log(`Đã xuất cấu trúc database ra file: db_schema.md`);
    await client.end();
}

main().catch(console.error);
