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

// Lấy danh sách combo (kèm thông tin items bên trong)
exports.getCombos = async (req, res) => {
    try {
        const result = await db.query(`
            SELECT c.*,
                COALESCE(json_agg(
                    json_build_object(
                        'item_id', i.item_id,
                        'name', i.name,
                        'quantity', ci.quantity
                    )
                ) FILTER (WHERE ci.combo_item_id IS NOT NULL), '[]') as items
            FROM combos c
            LEFT JOIN combo_items ci ON c.combo_id = ci.combo_id
            LEFT JOIN items i ON ci.item_id = i.item_id
            WHERE c.is_available = TRUE
            GROUP BY c.combo_id
            ORDER BY c.combo_id
        `);
        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất hệ thống combos' });
    }
};

/**
 * Lưu danh sách combo đã chọn vào đơn hàng
 * POST /api/concessions/order
 * Headers: Authorization: Bearer <token>
 * Body: {
 *   madondatve: "DV001",
 *   items: [{ combo_id: 1, quantity: 2 }, ...]
 * }
 */
exports.createConcessionOrder = async (req, res) => {
    const client = await db.connect();
    try {
        const { madondatve, items } = req.body;

        if (!madondatve || !items || items.length === 0) {
            return res.status(400).json({
                status: 'error',
                message: 'Vui lòng cung cấp madondatve và danh sách combo'
            });
        }

        // Kiểm tra đơn đặt vé tồn tại và thuộc về user đang đăng nhập
        const orderCheck = await client.query(
            'SELECT madondatve, id_khach FROM dondatve WHERE madondatve = $1',
            [madondatve]
        );
        if (orderCheck.rowCount === 0) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn đặt vé' });
        }

        await client.query('BEGIN');

        // Xóa các combo cũ của đơn này (nếu có), để cho phép cập nhật
        await client.query('DELETE FROM order_concessions WHERE madondatve = $1', [madondatve]);

        let totalComboPrice = 0;

        for (const item of items) {
            if (!item.combo_id || !item.quantity || item.quantity <= 0) continue;

            // Lấy giá combo hiện tại
            const comboRes = await client.query(
                'SELECT combo_id, price FROM combos WHERE combo_id = $1 AND is_available = TRUE',
                [item.combo_id]
            );
            if (comboRes.rowCount === 0) continue;

            const unitPrice = comboRes.rows[0].price;
            totalComboPrice += unitPrice * item.quantity;

            await client.query(
                'INSERT INTO order_concessions (madondatve, combo_id, quantity, unit_price) VALUES ($1, $2, $3, $4)',
                [madondatve, item.combo_id, item.quantity, unitPrice]
            );
        }

        // Cộng tiền combo vào tongTien của đơn đặt vé
        await client.query(
            'UPDATE dondatve SET tongtien = tongtien + $1 WHERE madondatve = $2',
            [totalComboPrice, madondatve]
        );

        await client.query('COMMIT');

        res.status(201).json({
            status: 'success',
            message: 'Đã lưu danh sách combo thành công',
            data: { madondatve, totalComboPrice }
        });
    } catch (e) {
        await client.query('ROLLBACK');
        console.error('Create Concession Order Error:', e);
        res.status(500).json({ status: 'error', message: 'Lỗi khi lưu đơn combo' });
    } finally {
        client.release();
    }
};

/**
 * Lấy danh sách combo đã đặt theo mã đơn
 * GET /api/concessions/order/:madondatve
 */
exports.getConcessionOrder = async (req, res) => {
    try {
        const { madondatve } = req.params;
        const result = await db.query(`
            SELECT oc.id, oc.quantity, oc.unit_price,
                c.combo_id, c.name, c.description, c.image_url,
                (oc.quantity * oc.unit_price) as subtotal
            FROM order_concessions oc
            JOIN combos c ON oc.combo_id = c.combo_id
            WHERE oc.madondatve = $1
        `, [madondatve]);

        res.json({ status: 'success', data: result.rows });
    } catch (e) {
        console.error(e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất đơn combo' });
    }
};
