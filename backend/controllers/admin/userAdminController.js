const bcrypt = require('bcrypt');
const db = require('../../config/db');

/**
 * GET /api/admin/users
 * Danh sách nhân viên + khách hàng (format thống nhất cho Web Admin)
 */
exports.getAllUsers = async (req, res) => {
  try {
    const [staffRes, customerRes] = await Promise.all([
      db.query(`
        SELECT id_nhanvien, manhanvien, hoten, email, sdt, vaitro, ngaytao
        FROM nhanvien
        ORDER BY ngaytao DESC
      `),
      db.query(`
        SELECT id_khach, mataikhoan, hoten, email, sdt, trangthai, ngaytao
        FROM thongtintaikhoan
        ORDER BY ngaytao DESC
      `),
    ]);

    const staff = staffRes.rows.map((nv) => ({
      id: nv.manhanvien,
      id_nhanvien: nv.id_nhanvien,
      hoten: nv.hoten,
      email: nv.email,
      sdt: nv.sdt,
      vaitro: nv.vaitro,
      ngaytao: nv.ngaytao,
      loai: 'nhanvien',
      trangthai: 'active',
    }));

    const customers = customerRes.rows.map((kh) => ({
      id: kh.mataikhoan,
      id_khach: kh.id_khach,
      hoten: kh.hoten,
      email: kh.email,
      sdt: kh.sdt,
      vaitro: 'user',
      ngaytao: kh.ngaytao,
      loai: 'khach',
      trangthai: kh.trangthai,
    }));

    const allUsers = [...staff, ...customers].sort(
      (a, b) => new Date(b.ngaytao) - new Date(a.ngaytao)
    );

    res.json({
      status: 'success',
      total: allUsers.length,
      data: allUsers,
    });
  } catch (e) {
    console.error('Get All Users Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi lấy danh sách người dùng' });
  }
};

/**
 * PUT /api/admin/users/:id
 * Body: { hoten, sdt, vaitro }
 */
exports.updateUser = async (req, res) => {
  const { id } = req.params;
  const { hoten, sdt, vaitro } = req.body;

  try {
    const staffRes = await db.query(
      'SELECT * FROM nhanvien WHERE manhanvien = $1',
      [id]
    );
    if (staffRes.rows.length > 0) {
      if (vaitro === 'user') {
        return res.status(400).json({
          status: 'error',
          message: 'Không thể chuyển quyền nhân viên sang User.',
        });
      }

      const updated = await db.query(
        `UPDATE nhanvien
         SET hoten = COALESCE($1, hoten),
             sdt = COALESCE($2, sdt),
             vaitro = COALESCE($3, vaitro),
             ngaycapnhat = NOW()
         WHERE manhanvien = $4
         RETURNING *`,
        [hoten, sdt, vaitro, id]
      );

      return res.json({
        status: 'success',
        message: 'Cập nhật nhân viên thành công',
        data: updated.rows[0],
      });
    }

    const khachRes = await db.query(
      'SELECT * FROM thongtintaikhoan WHERE mataikhoan = $1',
      [id]
    );
    if (khachRes.rows.length > 0) {
      if (vaitro && vaitro !== 'user') {
        return res.status(400).json({
          status: 'error',
          message: 'Không thể cấp quyền Admin cho tài khoản khách hàng.',
        });
      }

      const updated = await db.query(
        `UPDATE thongtintaikhoan
         SET hoten = COALESCE($1, hoten),
             sdt = COALESCE($2, sdt),
             ngaycapnhat = NOW()
         WHERE mataikhoan = $3
         RETURNING *`,
        [hoten, sdt, id]
      );

      return res.json({
        status: 'success',
        message: 'Cập nhật khách hàng thành công',
        data: updated.rows[0],
      });
    }

    return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
  } catch (e) {
    console.error('Update User Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi cập nhật người dùng' });
  }
};

/**
 * PUT /api/admin/users/:id/status
 * Body: { trangthai } — chỉ áp dụng khách hàng
 */
exports.updateUserStatus = async (req, res) => {
  const { id } = req.params;
  const { trangthai } = req.body;

  if (!trangthai) {
    return res.status(400).json({ status: 'error', message: 'Thiếu trạng thái' });
  }

  try {
    const khachRes = await db.query(
      'SELECT id_khach FROM thongtintaikhoan WHERE mataikhoan = $1',
      [id]
    );

    if (khachRes.rows.length > 0) {
      const updated = await db.query(
        `UPDATE thongtintaikhoan SET trangthai = $1, ngaycapnhat = NOW()
         WHERE mataikhoan = $2 RETURNING *`,
        [trangthai, id]
      );
      return res.json({
        status: 'success',
        message: 'Cập nhật trạng thái thành công',
        data: updated.rows[0],
      });
    }

    const staffRes = await db.query(
      'SELECT id_nhanvien FROM nhanvien WHERE manhanvien = $1',
      [id]
    );
    if (staffRes.rows.length > 0) {
      return res.status(400).json({
        status: 'error',
        message: 'Tài khoản nhân viên không hỗ trợ thay đổi trạng thái.',
      });
    }

    return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
  } catch (e) {
    console.error('Update User Status Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi cập nhật trạng thái' });
  }
};

/**
 * PUT /api/admin/users/:id/password
 * Body: { matkhauMoi }
 */
exports.changeUserPassword = async (req, res) => {
  const { id } = req.params;
  const { matkhauMoi } = req.body;

  if (!matkhauMoi) {
    return res.status(400).json({ status: 'error', message: 'Thiếu mật khẩu mới' });
  }

  try {
    const hashed = await bcrypt.hash(matkhauMoi, 10);

    const staffRes = await db.query(
      'SELECT id_nhanvien FROM nhanvien WHERE manhanvien = $1',
      [id]
    );
    if (staffRes.rows.length > 0) {
      await db.query(
        'UPDATE nhanvien SET matkhau = $1, ngaycapnhat = NOW() WHERE manhanvien = $2',
        [hashed, id]
      );
      return res.json({ status: 'success', message: 'Đổi mật khẩu nhân viên thành công' });
    }

    const khachRes = await db.query(
      'SELECT id_khach FROM thongtintaikhoan WHERE mataikhoan = $1',
      [id]
    );
    if (khachRes.rows.length > 0) {
      await db.query(
        'UPDATE thongtintaikhoan SET matkhau = $1, ngaycapnhat = NOW() WHERE mataikhoan = $2',
        [hashed, id]
      );
      return res.json({ status: 'success', message: 'Đổi mật khẩu khách hàng thành công' });
    }

    return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
  } catch (e) {
    console.error('Change Password Error:', e);
    res.status(500).json({ status: 'error', message: 'Lỗi đổi mật khẩu' });
  }
};

/**
 * DELETE /api/admin/users/:id
 * Xóa khách (mataikhoan) hoặc nhân viên (manhanvien) nếu không còn ràng buộc
 */
exports.deleteUser = async (req, res) => {
  const { id } = req.params;

  try {
    const khachRes = await db.query(
      'SELECT id_khach FROM thongtintaikhoan WHERE mataikhoan = $1',
      [id]
    );
    if (khachRes.rows.length > 0) {
      return exports._deleteCustomerById(req, res, khachRes.rows[0].id_khach);
    }

    const staffRes = await db.query(
      'SELECT id_nhanvien FROM nhanvien WHERE manhanvien = $1',
      [id]
    );
    if (staffRes.rows.length > 0) {
      const idNv = staffRes.rows[0].id_nhanvien;
      if (idNv === req.admin?.id) {
        return res.status(400).json({
          status: 'error',
          message: 'Không thể xóa tài khoản đang đăng nhập.',
        });
      }

      await db.query('DELETE FROM nhanvien WHERE id_nhanvien = $1', [idNv]);
      return res.json({ status: 'success', message: 'Xóa nhân viên thành công' });
    }

    return res.status(404).json({ status: 'error', message: 'Không tìm thấy người dùng' });
  } catch (e) {
    console.error('Delete User Error:', e);
    if (e.code === '23503') {
      return res.status(400).json({
        status: 'error',
        message: 'Không thể xóa vì còn dữ liệu liên quan.',
      });
    }
    res.status(500).json({ status: 'error', message: 'Lỗi xóa người dùng' });
  }
};

exports._deleteCustomerById = async (req, res, idKhach) => {
  const activeOrders = await db.query(
    `SELECT COUNT(*)::int AS cnt FROM dondatve
     WHERE id_khach = $1 AND trangthai IN ('pending', 'paid')`,
    [idKhach]
  );

  if (parseInt(activeOrders.rows[0].cnt, 10) > 0) {
    return res.status(400).json({
      status: 'error',
      message: 'Không thể xóa khách hàng vì còn đơn pending/paid.',
    });
  }

  await db.query('DELETE FROM thongtintaikhoan WHERE id_khach = $1', [idKhach]);
  return res.json({ status: 'success', message: 'Xóa khách hàng thành công' });
};
