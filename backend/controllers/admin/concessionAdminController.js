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

// ======================== ACCESSORIES ========================

/**
 * Lấy tất cả phụ kiện (items với item_type = 'accessory')
 * GET /api/admin/accessories
 */
exports.getAllAccessories = async (req, res) => {
    try {
        const result = await db.query("SELECT * FROM items WHERE item_type = 'accessory' ORDER BY created_at DESC");
        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất phụ kiện' });
    }
};

/**
 * Thêm phụ kiện mới
 * POST /api/admin/accessories
 */
exports.createAccessory = async (req, res) => {
    req.body.item_type = 'accessory';
    return exports.createItem(req, res);
};

/**
 * Chỉnh sửa phụ kiện
 * PUT /api/admin/accessories/:id
 */
exports.updateAccessory = async (req, res) => {
    req.body.item_type = 'accessory';
    return exports.updateItem(req, res);
};

/**
 * Xoá phụ kiện
 * DELETE /api/admin/accessories/:id
 */
exports.deleteAccessory = async (req, res) => {
    return exports.deleteItem(req, res);
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
        const defaultImageUrl = "https://images.unsplash.com/photo-1572177191856-3cde618dee1f?q=80&w=500&auto=format&fit=crop";
        const finalImageUrl = image_url && image_url.trim() !== '' ? image_url : defaultImageUrl;

        const comboRes = await client.query(
            'INSERT INTO combos (name, price, description, image_url) VALUES ($1, $2, $3, $4) RETURNING *',
            [name, price, description || null, finalImageUrl]
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

// ======================== POS CONCESSIONS ========================

/**
 * Đặt đồ ăn độc lập tại quầy (POS)
 * POST /api/admin/pos/concessions/book
 * Body: { concessions: [{ comboId, quantity, price }] }
 */
exports.createPOSConcessionOrder = async (req, res) => {
    const client = await db.connect();
    try {
        const { concessions } = req.body;

        if (!concessions || concessions.length === 0) {
            return res.status(400).json({ status: 'error', message: 'Vui lòng chọn ít nhất 1 món' });
        }

        await client.query('BEGIN');

        // 1. Tính tổng tiền
        let tongtien = 0;
        for (let c of concessions) {
            tongtien += (c.price * c.quantity);
        }

        // 2. Sinh mã đơn đặt vé đặc biệt cho POS (tiền tố POS)
        const maDonDatVe = 'POS' + Date.now().toString().slice(-7);

        // 3. Insert dondatve (id_khach = req.admin.id - nhân viên quầy)
        await client.query(
            `INSERT INTO dondatve (madondatve, tongtien, trangthai, id_khach) VALUES ($1, $2, 'paid', $3)`,
            [maDonDatVe, tongtien, req.admin.id]
        );

        // 4. Insert thongtinthanhtoan (Mặc định cash do không cần lưu chi tiết)
        const maThanhToan = 'PAY' + Date.now().toString().slice(-6);
        await client.query(
            `INSERT INTO thongtinthanhtoan (mathanhtoan, phuongthucthanhtoan, sotienthanhtoan, trangthai, madondatve, thoidiemthanhtoan)
             VALUES ($1, $2, $3, 'success', $4, CURRENT_TIMESTAMP)`,
            [maThanhToan, 'cash', tongtien, maDonDatVe]
        );

        // 5. Insert order_concessions
        for (let c of concessions) {
            await client.query(
                `INSERT INTO order_concessions (madondatve, combo_id, quantity, unit_price) VALUES ($1, $2, $3, $4)`,
                [maDonDatVe, c.comboId, c.quantity, c.price]
            );
        }

        await client.query('COMMIT');

        res.status(201).json({ 
            status: 'success', 
            message: 'Thanh toán hoá đơn tại quầy thành công', 
            data: { maDonDatVe, tongtien } 
        });

    } catch (e) {
        await client.query('ROLLBACK');
        console.error("Create POS Order Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi tạo hoá đơn tại quầy' });
    } finally {
        client.release();
    }
};

/**
 * Xem lịch sử đơn hàng tại quầy (không có vé phim)
 * GET /api/admin/pos/concessions/orders
 */
exports.getPOSConcessionOrders = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT d.madondatve, d.ngaydatve, d.tongtien,
                   COALESCE(
                       json_agg(
                           json_build_object(
                               'combo_id', oc.combo_id,
                               'name', c.name,
                               'quantity', oc.quantity,
                               'unit_price', oc.unit_price
                           )
                       ) FILTER (WHERE oc.combo_id IS NOT NULL), '[]'
                   ) as items
            FROM dondatve d
            LEFT JOIN order_concessions oc ON d.madondatve = oc.madondatve
            LEFT JOIN combos c ON oc.combo_id = c.combo_id
            WHERE d.madondatve LIKE 'POS%'
            GROUP BY d.madondatve, d.ngaydatve, d.tongtien
            ORDER BY d.ngaydatve DESC
        `);

        res.json({ status: 'success', total: result.rowCount, data: result.rows });
    } catch (e) {
        console.error("Get POS Orders Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất lịch sử đơn hàng tại quầy' });
    }
};
