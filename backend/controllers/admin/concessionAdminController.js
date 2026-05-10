const db = require('../../config/db');

// ======================== ITEMS (Đồ ăn / Thức uống / Phụ kiện) ========================

/**
 * Lấy tất cả items (Admin - bao gồm cả unavailable)
 * GET /api/admin/items
 */
exports.getAllItems = async (req, res) => {
    try {
        const result = await db.query('SELECT * FROM items ORDER BY created_at DESC');
        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất items' });
    }
};

/**
 * Thêm item mới
 * POST /api/admin/items
 * Body: { name, item_type, price, image_url, stock_quantity }
 */
exports.createItem = async (req, res) => {
    try {
        const { name, item_type, price, image_url, stock_quantity, unit } = req.body;

        if (!name || !item_type || !price) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng nhập name, item_type và price' });
        }

        if (!['food', 'drink', 'accessory'].includes(item_type)) {
            return res.status(400).json({ status: 'error', message: 'item_type phải là food, drink hoặc accessory' });
        }

        const result = await db.query(
            'INSERT INTO items (name, item_type, price, image_url, stock_quantity, unit) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
            [name, item_type, price, image_url || null, stock_quantity || 0, unit || null]
        );

        res.status(201).json({ status: 'success', message: 'Thêm sản phẩm thành công', data: result.rows[0] });
    } catch (e) {
        console.error("Create Item Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi thêm sản phẩm' });
    }
};

/**
 * Chỉnh sửa item
 * PUT /api/admin/items/:id
 */
exports.updateItem = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, item_type, price, image_url, stock_quantity, is_available, unit } = req.body;

        const result = await db.query(`
            UPDATE items SET
                name = COALESCE($1, name),
                item_type = COALESCE($2, item_type),
                price = COALESCE($3, price),
                image_url = COALESCE($4, image_url),
                stock_quantity = COALESCE($5, stock_quantity),
                is_available = COALESCE($6, is_available),
                unit = COALESCE($7, unit)
            WHERE item_id = $8 RETURNING *
        `, [name, item_type, price, image_url, stock_quantity, is_available, unit, id]);

        if (result.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy sản phẩm' });
        }

        res.json({ status: 'success', message: 'Cập nhật sản phẩm thành công', data: result.rows[0] });
    } catch (e) {
        console.error("Update Item Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi cập nhật sản phẩm' });
    }
};

/**
 * Xoá item
 * DELETE /api/admin/items/:id
 */
exports.deleteItem = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query('DELETE FROM items WHERE item_id = $1 RETURNING *', [id]);

        if (result.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy sản phẩm' });
        }

        res.json({ status: 'success', message: 'Xoá sản phẩm thành công' });
    } catch (e) {
        console.error("Delete Item Error:", e);
        if (e.code === '23503') {
            return res.status(400).json({ status: 'error', message: 'Không thể xoá vì sản phẩm đang được sử dụng trong đơn hàng hoặc combo.' });
        }
        res.status(500).json({ status: 'error', message: 'Lỗi khi xoá sản phẩm' });
    }
};

// ======================== COMBOS ========================

/**
 * Lấy tất cả combos (Admin - bao gồm cả unavailable)
 * GET /api/admin/combos
 */
exports.getAllCombos = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT c.*,
                COALESCE(json_agg(
                    json_build_object(
                        'combo_item_id', ci.combo_item_id,
                        'item_id', i.item_id,
                        'name', i.name,
                        'quantity', ci.quantity
                    )
                ) FILTER (WHERE ci.combo_item_id IS NOT NULL), '[]') as items
            FROM combos c
            LEFT JOIN combo_items ci ON c.combo_id = ci.combo_id
            LEFT JOIN items i ON ci.item_id = i.item_id
            GROUP BY c.combo_id
            ORDER BY c.combo_id
        `);
        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất combos' });
    }
};

/**
 * Thêm combo mới
 * POST /api/admin/combos
 * Body: { name, price, description, image_url, items: [{ item_id, quantity }] }
 */
exports.createCombo = async (req, res) => {
    const client = await db.connect();
    try {
        const { name, price, description, image_url, items } = req.body;

        if (!name || !price) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng nhập name và price' });
        }

        await client.query('BEGIN');

        // 1. Tạo combo
        const comboRes = await client.query(
            'INSERT INTO combos (name, price, description, image_url) VALUES ($1, $2, $3, $4) RETURNING *',
            [name, price, description || null, image_url || null]
        );
        const combo = comboRes.rows[0];

        // 2. Thêm các items vào combo
        if (items && items.length > 0) {
            for (let item of items) {
                await client.query(
                    'INSERT INTO combo_items (combo_id, item_id, quantity) VALUES ($1, $2, $3)',
                    [combo.combo_id, item.item_id, item.quantity || 1]
                );
            }
        }

        await client.query('COMMIT');

        res.status(201).json({ status: 'success', message: 'Thêm combo thành công', data: combo });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Create Combo Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi thêm combo' });
    } finally {
        client.release();
    }
};

/**
 * Chỉnh sửa combo
 * PUT /api/admin/combos/:id
 * Body: { name, price, description, image_url, is_available, items: [{ item_id, quantity }] }
 */
exports.updateCombo = async (req, res) => {
    const client = await db.connect();
    try {
        const { id } = req.params;
        const { name, price, description, image_url, is_available, items } = req.body;

        await client.query('BEGIN');

        // 1. Cập nhật thông tin combo
        const result = await client.query(`
            UPDATE combos SET
                name = COALESCE($1, name),
                price = COALESCE($2, price),
                description = COALESCE($3, description),
                image_url = COALESCE($4, image_url),
                is_available = COALESCE($5, is_available)
            WHERE combo_id = $6 RETURNING *
        `, [name, price, description, image_url, is_available, id]);

        if (result.rowCount === 0) {
            await client.query('ROLLBACK');
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy combo' });
        }

        // 2. Nếu có danh sách items mới -> xoá cũ, thêm mới
        if (items && items.length > 0) {
            await client.query('DELETE FROM combo_items WHERE combo_id = $1', [id]);
            for (let item of items) {
                await client.query(
                    'INSERT INTO combo_items (combo_id, item_id, quantity) VALUES ($1, $2, $3)',
                    [id, item.item_id, item.quantity || 1]
                );
            }
        }

        await client.query('COMMIT');

        res.json({ status: 'success', message: 'Cập nhật combo thành công', data: result.rows[0] });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Update Combo Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi cập nhật combo' });
    } finally {
        client.release();
    }
};

/**
 * Xoá combo
 * DELETE /api/admin/combos/:id
 */
exports.deleteCombo = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await db.query('DELETE FROM combos WHERE combo_id = $1 RETURNING *', [id]);

        if (result.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy combo' });
        }

        res.json({ status: 'success', message: 'Xoá combo thành công' });
    } catch (e) {
        console.error("Delete Combo Error:", e);
        if (e.code === '23503') {
            return res.status(400).json({ status: 'error', message: 'Không thể xoá vì combo đang được sử dụng trong đơn hàng.' });
        }
        res.status(500).json({ status: 'error', message: 'Lỗi khi xoá combo' });
    }
};
