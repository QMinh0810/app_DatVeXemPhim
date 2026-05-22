const db = require('./config/db');

async function seedVouchers() {
    try {
        console.log("=== BẮT ĐẦU SEED VOUCHER ===");

        // Xóa sạch các voucher cũ nếu có để tránh trùng lặp khi chạy lại
        console.log("Cập nhật CHECK constraint cho bảng khuyen_mai...");
        await db.query("ALTER TABLE khuyen_mai DROP CONSTRAINT IF EXISTS khuyen_mai_ap_dung_user_check");
        await db.query("ALTER TABLE khuyen_mai ADD CONSTRAINT khuyen_mai_ap_dung_user_check CHECK (ap_dung_user IN ('TAT_CA_USER', 'SILVER', 'GOLD', 'DIAMOND'))");
        await db.query("ALTER TABLE khuyen_mai DROP CONSTRAINT IF EXISTS khuyen_mai_loai_giam_check");
        await db.query("ALTER TABLE khuyen_mai ADD CONSTRAINT khuyen_mai_loai_giam_check CHECK (loai_giam IN ('TIEN', 'PHAN_TRAM'))");

        await db.query("DELETE FROM khuyen_mai_phim");
        await db.query("DELETE FROM khuyen_mai");

        console.log("1. Đang nạp danh sách Khuyến mãi...");
        
        // Ngày bắt đầu: 1 ngày trước
        const ngayBatDau = new Date();
        ngayBatDau.setDate(ngayBatDau.getDate() - 1);
        
        // Ngày kết thúc: 30 ngày sau
        const ngayKetThuc = new Date();
        ngayKetThuc.setDate(ngayKetThuc.getDate() + 30);
        
        // Ngày hết hạn quá khứ
        const ngayHetHanQuaKhu = new Date();
        ngayHetHanQuaKhu.setDate(ngayHetHanQuaKhu.getDate() - 5);

        // Nạp Voucher
        const vouchers = [
            {
                ma: 'GIAM50K',
                ten: 'Mã giảm giá hè Vàng',
                mota: 'Giảm 50.000đ cho đơn hàng từ 200k (Yêu cầu hạng VÀNG trở lên)',
                loai_giam: 'TIEN',
                gia_tri: 50000,
                giam_toi_da: 50000,
                min_spend: 200000,
                so_luong: 100,
                ap_dung_user: 'GOLD',
                ngay_bd: ngayBatDau,
                ngay_kt: ngayKetThuc,
                ap_dung_cho: 'TAT_CA_PHIM'
            },
            {
                ma: 'GIAM100K',
                ten: 'Siêu ưu đãi Kim Cương',
                mota: 'Giảm 100.000đ cho đơn hàng từ 500k (Yêu cầu hạng KIM CƯƠNG trở lên)',
                loai_giam: 'TIEN',
                gia_tri: 100000,
                giam_toi_da: 100000,
                min_spend: 500000,
                so_luong: 50,
                ap_dung_user: 'DIAMOND',
                ngay_bd: ngayBatDau,
                ngay_kt: ngayKetThuc,
                ap_dung_cho: 'TAT_CA_PHIM'
            },
            {
                ma: 'GIAM20K',
                ten: 'Quà tặng hạng Bạc',
                mota: 'Giảm 20.000đ cho đơn hàng từ 100k (Yêu cầu hạng BẠC trở lên)',
                loai_giam: 'TIEN',
                gia_tri: 20000,
                giam_toi_da: 20000,
                min_spend: 100000,
                so_luong: 200,
                ap_dung_user: 'SILVER',
                ngay_bd: ngayBatDau,
                ngay_kt: ngayKetThuc,
                ap_dung_cho: 'TAT_CA_PHIM'
            },
            {
                ma: 'CHAOHOCKY',
                ten: 'Chào học kỳ mới',
                mota: 'Giảm 10% tối đa 30k cho đơn hàng từ 80k (Áp dụng toàn bộ thành viên)',
                loai_giam: 'PHAN_TRAM',
                gia_tri: 10, // 10%
                giam_toi_da: 30000,
                min_spend: 80000,
                so_luong: 500,
                ap_dung_user: 'TAT_CA_USER',
                ngay_bd: ngayBatDau,
                ngay_kt: ngayKetThuc,
                ap_dung_cho: 'TAT_CA_PHIM'
            },
            {
                ma: 'PHIMHOT',
                ten: 'Ưu đãi Dune 2',
                mota: 'Giảm 30.000đ cho đơn hàng từ 150k chỉ dành cho phim DUNE 2',
                loai_giam: 'TIEN',
                gia_tri: 30000,
                giam_toi_da: 30000,
                min_spend: 150000,
                so_luong: 100,
                ap_dung_user: 'TAT_CA_USER',
                ngay_bd: ngayBatDau,
                ngay_kt: ngayKetThuc,
                ap_dung_cho: 'PHIM_CU_THE' // Giới hạn phim cụ thể
            },
            {
                ma: 'HEHET',
                ten: 'Ưu đãi hết hạn',
                mota: 'Ưu đãi đặc biệt đã hết hạn sử dụng',
                loai_giam: 'TIEN',
                gia_tri: 50000,
                giam_toi_da: 50000,
                min_spend: 100000,
                so_luong: 10,
                ap_dung_user: 'TAT_CA_USER',
                ngay_bd: ngayHetHanQuaKhu,
                ngay_kt: ngayHetHanQuaKhu,
                ap_dung_cho: 'TAT_CA_PHIM'
            }
        ];

        for (const v of vouchers) {
            const result = await db.query(
                `INSERT INTO khuyen_mai (
                    ma_khuyen_mai, ten_khuyen_mai, mo_ta, loai_giam, gia_tri_giam, giam_toi_da, 
                    gia_tri_don_hang_toi_thieu, so_luong_ve_toi_thieu, so_luong_ma, so_luong_da_dung, 
                    so_lan_dung_toi_da_moi_user, ngay_bat_dau, ngay_ket_thuc, ap_dung_cho, ap_dung_user, trang_thai
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, 1, $8, 0, 1, $9, $10, $11, $12, 'ACTIVE') RETURNING id`,
                [
                    v.ma, v.ten, v.mota, v.loai_giam, v.gia_tri, v.giam_toi_da, 
                    v.min_spend, v.so_luong, v.ngay_bd, v.ngay_kt, v.ap_dung_cho, v.ap_dung_user
                ]
            );
            
            const voucherId = result.rows[0].id;
            
            // Nếu áp dụng cho phim cụ thể, nạp liên kết vào khuyen_mai_phim
            if (v.ap_dung_cho === 'PHIM_CU_THE') {
                // Seed cho phim DUNE 2 (mã phim 'P001' từ database_seed.sql)
                console.log(`   🔗 Đang gán phim P001 vào Voucher ${v.ma}...`);
                await db.query(
                    `INSERT INTO khuyen_mai_phim (id_khuyen_mai, maphim) VALUES ($1, 'P001')`,
                    [voucherId]
                );
            }
        }

        console.log("✅ SEED VOUCHER THÀNH CÔNG!");
        process.exit(0);
    } catch (e) {
        console.error("❌ LỖI SEED VOUCHER:", e);
        process.exit(1);
    }
}

seedVouchers();
