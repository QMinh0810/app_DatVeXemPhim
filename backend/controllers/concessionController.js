const db = require('../config/db');

// Lấy danh sách đồ ăn, thức uống, phụ kiện
exports.getItems = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM items WHERE is_available = TRUE');
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất hệ thống items' });
    }
};

// Lấy danh sách combo
exports.getCombos = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT c.*, 
                json_agg(
                    json_build_object(
                        'item_id', i.item_id,
                        'name', i.name,
                        'quantity', ci.quantity
                    )
                ) as items
            FROM combos c
            LEFT JOIN combo_items ci ON c.combo_id = ci.combo_id
            LEFT JOIN items i ON ci.item_id = i.item_id
            WHERE c.is_available = TRUE
            GROUP BY c.combo_id
        `);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất hệ thống combos' });
    }
};
