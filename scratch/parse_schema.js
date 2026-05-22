const fs = require('fs');
const path = require('path');

const schemaPath = path.join(__dirname, '../db_schema.md');
const outputPath = path.join(__dirname, '../thiet_ke_cac_bang.txt');

const content = fs.readFileSync(schemaPath, 'utf8');

// Parse markdown to tables
const lines = content.split('\n');
const tables = [];
let currentTable = null;

for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  if (line.startsWith('## Bảng:')) {
    const tableName = line.replace('## Bảng:', '').replace(/`/g, '').trim();
    currentTable = { name: tableName, columns: [] };
    tables.push(currentTable);
  } else if (currentTable && line.startsWith('|') && !line.includes('Tên Cột') && !line.includes(':---')) {
    const parts = line.split('|').map(p => p.trim()).filter(p => p !== '');
    if (parts.length >= 3) {
      const colName = parts[0].replace(/`/g, '');
      const dataType = parts[1].replace(/`/g, '');
      const allowNull = parts[2].replace(/`/g, '');
      currentTable.columns.push({ colName, dataType, allowNull });
    }
  }
}

// Function to check if a column is likely a PK
function isPK(tableName, colName) {
  const lowerCol = colName.toLowerCase();
  const lowerTable = tableName.toLowerCase();
  
  // Composite keys or specific lookup mappings
  if (lowerTable === 'phim_daodien' && (lowerCol === 'maphim' || lowerCol === 'madaodien')) return true;
  if (lowerTable === 'phim_dienvien' && (lowerCol === 'maphim' || lowerCol === 'madienvien')) return true;
  if (lowerTable === 'phim_hashtag' && (lowerCol === 'maphim' || lowerCol === 'mahashtag')) return true;
  if (lowerTable === 'phim_theloai' && (lowerCol === 'maphim' || lowerCol === 'matheloai')) return true;
  if (lowerTable === 'rapphim_nhanvien' && (lowerCol === 'id_nhanvien' || lowerCol === 'marapphim')) return true;
  
  if (lowerCol === 'id' || lowerCol === 'id_' + lowerTable) return true;
  if (lowerCol === 'ma' + lowerTable) return true;
  
  // Specific exceptions
  if (lowerTable === 'combo_items' && lowerCol === 'combo_item_id') return true;
  if (lowerTable === 'combos' && lowerCol === 'combo_id') return true;
  if (lowerTable === 'daodien' && lowerCol === 'madaodien') return true;
  if (lowerTable === 'dienvien' && lowerCol === 'madienvien') return true;
  if (lowerTable === 'dondatve' && lowerCol === 'madondatve') return true;
  if (lowerTable === 'ghengoi' && lowerCol === 'maghe') return true;
  if (lowerTable === 'hashtag' && lowerCol === 'mahashtag') return true;
  if (lowerTable === 'items' && lowerCol === 'item_id') return true;
  if (lowerTable === 'lichchieu' && lowerCol === 'malichchieu') return true;
  if (lowerTable === 'nhanvien' && lowerCol === 'id_nhanvien') return true;
  if (lowerTable === 'order_concessions' && lowerCol === 'id_order_concession') return true;
  if (lowerTable === 'phim' && lowerCol === 'maphim') return true;
  if (lowerTable === 'phongrapphim' && lowerCol === 'maphong') return true;
  if (lowerTable === 'rapphim' && lowerCol === 'marapphim') return true;
  if (lowerTable === 'theloai' && lowerCol === 'matheloai') return true;
  if (lowerTable === 'thongbao' && lowerCol === 'mathongbao') return true;
  if (lowerTable === 'thongtintaikhoan' && lowerCol === 'id_khach') return true;
  if (lowerTable === 'thongtinthanhtoan' && lowerCol === 'mathanhtoan') return true;
  if (lowerTable === 'vexemphim' && lowerCol === 'mavexemphim') return true;
  if (lowerTable === 'binhluan' && lowerCol === 'mabinhluan') return true;

  return false;
}

let output = '';
tables.forEach((table, index) => {
  output += `2.4.${index + 1}\tBảng ${table.name}\n\n`;
  output += `Name\tData Type\tAllow Nulls\n`;
  table.columns.forEach(col => {
    let typeStr = col.dataType;
    let nullStr = col.allowNull === 'YES' ? 'Yes' : 'Not Null';
    if (isPK(table.name, col.colName)) {
      typeStr += ' (PK)';
      nullStr = 'Primary Key';
    }
    output += `${col.colName}\t${typeStr}\t${nullStr}\n`;
  });
  output += '\n';
});

fs.writeFileSync(outputPath, output, 'utf8');
console.log('Done!');
