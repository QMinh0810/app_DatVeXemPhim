const db = require('../config/db');

// Map rank names to priority numbers for comparison
const RANK_PRIORITY = {
    'BRONZE': 0,
    'MEMBER': 0,
    'SILVER': 1,
    'GOLD': 2,
    'DIAMOND': 3
};

// Map rank names to friendly Vietnamese names
const RANK_NAMES_VI = {
    'BRONZE': 'Đồng',
    'MEMBER': 'Đồng',
    'SILVER': 'Bạc',
    'GOLD': 'Vàng',
    'DIAMOND': 'Kim Cương'
};

// Map rank names to discount rates
const RANK_DISCOUNT_RATES = {
    'BRONZE': 0.00,
    'MEMBER': 0.00,
    'SILVER': 0.05, // 5%
    'GOLD': 0.10,   // 10%
    'DIAMOND': 0.18 // 18%
};

/**
 * 1. Lấy thông tin cấp bậc hiện tại của User
 */
async function getUserRankInfo(userId) {
    const userRes = await db.query(
        'SELECT hang_thanh_vien, tong_chi_tieu FROM thongtintaikhoan WHERE id_khach = $1',
        [userId]
    );
    if (userRes.rows.length === 0) {
        return { rank: 'BRONZE', totalSpent: 0 };
    }
    const user = userRes.rows[0];
    return {
        rank: user.hang_thanh_vien || 'BRONZE',
        totalSpent: parseFloat(user.tong_chi_tieu || 0)
    };
}

/**
 * 2. API: Lấy danh sách Voucher khả dụng cho người dùng
 * GET /api/vouchers/available
 */
exports.getAvailableVouchers = async (req, res) => {
    try {
        const userId = req.user.id;
        const totalPrice = parseFloat(req.query.totalPrice || 0);
        const showtimeId = req.query.showtimeId || null;

        // A. Lấy thông tin rank của khách hàng
        const { rank: userRank, totalSpent } = await getUserRankInfo(userId);

        // B. Lấy thông tin phim từ showtimeId nếu được truyền lên
        let maphim = null;
        if (showtimeId) {
            const showtimeRes = await db.query(
                'SELECT maphim FROM lichchieu WHERE malichchieu = $1',
                [showtimeId]
            );
            if (showtimeRes.rows.length > 0) {
                maphim = showtimeRes.rows[0].maphim;
            }
        }

        // C. Lấy danh sách toàn bộ các voucher đang ACTIVE và trong thời hạn sử dụng
        const vouchersQuery = `
            SELECT * FROM khuyen_mai 
            WHERE trang_thai = 'ACTIVE' 
              AND ngay_bat_dau <= CURRENT_TIMESTAMP 
              AND ngay_ket_thuc >= CURRENT_TIMESTAMP
            ORDER BY created_at DESC
        `;
        const vouchersRes = await db.query(vouchersQuery);
        const availableVouchers = [];

        // D. Lặp qua từng voucher và đánh giá tính hợp lệ
        for (const voucher of vouchersRes.rows) {
            let isEligible = true;
            let reason = null;

            // 1. Kiểm tra giới hạn số lượng còn lại
            if (voucher.so_luong_ma > 0 && voucher.so_luong_da_dung >= voucher.so_luong_ma) {
                isEligible = false;
                reason = 'Mã giảm giá này đã hết lượt sử dụng';
            }

            // 2. Kiểm tra xem khách hàng này đã dùng mã này chưa (Đảm bảo mỗi khách chỉ được dùng 1 lần)
            if (isEligible) {
                const historyRes = await db.query(
                    'SELECT COUNT(*) FROM lich_su_khuyen_mai WHERE id_khuyen_mai = $1 AND id_khach = $2',
                    [voucher.id, userId]
                );
                const usedCount = parseInt(historyRes.rows[0].count);
                if (usedCount >= 1) {
                    isEligible = false;
                    reason = 'Bạn đã sử dụng mã giảm giá này rồi';
                }
            }

            // 3. Kiểm tra điều kiện Cấp bậc (Rank)
            // Nếu ap_dung_user không phải TAT_CA_USER, nó là yêu cầu rank (SILVER, GOLD, DIAMOND)
            if (isEligible && voucher.ap_dung_user && voucher.ap_dung_user !== 'TAT_CA_USER') {
                const reqPriority = RANK_PRIORITY[voucher.ap_dung_user] || 0;
                const userPriority = RANK_PRIORITY[userRank] || 0;

                if (userPriority < reqPriority) {
                    isEligible = false;
                    const reqRankName = RANK_NAMES_VI[voucher.ap_dung_user] || voucher.ap_dung_user;
                    reason = `Chưa đạt hạng ${reqRankName} (Hạng hiện tại: ${RANK_NAMES_VI[userRank]})`;
                }
            }

            // 4. Kiểm tra số tiền đơn hàng tối thiểu
            if (isEligible && totalPrice > 0 && voucher.gia_tri_don_hang_toi_thieu > 0) {
                if (totalPrice < parseFloat(voucher.gia_tri_don_hang_toi_thieu)) {
                    isEligible = false;
                    const gap = parseFloat(voucher.gia_tri_don_hang_toi_thieu) - totalPrice;
                    reason = `Bạn cần mua thêm ${gap.toLocaleString('vi-VN')}đ để áp dụng mã này`;
                }
            }

            // 5. Kiểm tra điều kiện Phim (nếu voucher giới hạn cho một số phim cụ thể)
            if (isEligible && voucher.ap_dung_cho === 'PHIM_CU_THE' && maphim) {
                const phimRes = await db.query(
                    'SELECT 1 FROM khuyen_mai_phim WHERE id_khuyen_mai = $1 AND maphim = $2',
                    [voucher.id, maphim]
                );
                if (phimRes.rows.length === 0) {
                    isEligible = false;
                    reason = 'Mã này không áp dụng cho bộ phim bạn đã chọn';
                }
            }

            // E. Map dữ liệu trả về theo đúng định dạng UI yêu cầu
            availableVouchers.push({
                mavoucher: voucher.ma_khuyen_mai,
                ten: voucher.ten_khuyen_mai,
                mota: voucher.mo_ta,
                sotien_giam: voucher.loai_giam === 'TIEN' ? parseFloat(voucher.gia_tri_giam) : 0,
                phantram_giam: voucher.loai_giam === 'PHAN_TRAM' ? parseFloat(voucher.gia_tri_giam) / 100 : 0.0,
                donhang_toithieu: parseFloat(voucher.gia_tri_don_hang_toi_thieu),
                han_sudung: voucher.ngay_ket_thuc,
                dieukien_rank: voucher.ap_dung_user,
                is_eligible: isEligible,
                ...(reason && { reason }) // Chỉ đính kèm trường reason nếu không đủ điều kiện
            });
        }

        res.json({
            status: 'success',
            user_rank: {
                rank: userRank,
                ten_rank: RANK_NAMES_VI[userRank],
                tong_chi_tieu: totalSpent,
                chiet_khau_tu_dong: RANK_DISCOUNT_RATES[userRank]
            },
            available_vouchers: availableVouchers
        });
    } catch (e) {
        console.error("Available Vouchers Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi truy xuất danh sách Voucher' });
    }
};

/**
 * 3. API: Áp dụng thử mã Voucher và trả về Tóm tắt hóa đơn
 * POST /api/vouchers/apply
 */
exports.applyVoucher = async (req, res) => {
    try {
        const userId = req.user.id;
        const { mavoucher, tam_tinh, showtimeId } = req.body;

        if (tam_tinh === undefined || tam_tinh === null || isNaN(tam_tinh)) {
            return res.status(400).json({ status: 'error', message: 'Tạm tính không hợp lệ' });
        }

        const subtotal = parseFloat(tam_tinh);

        // A. Lấy thông tin hạng khách hàng hiện tại
        const { rank: userRank } = await getUserRankInfo(userId);

        // B. Tính ưu đãi Rank tự động (Luôn áp dụng)
        const rankDiscountRate = RANK_DISCOUNT_RATES[userRank] || 0.00;
        const sotienGiamRank = Math.round(subtotal * rankDiscountRate);

        // C. Khai báo biến lưu kết quả Voucher
        let appliedVoucher = null;
        let sotienDuocGiamVoucher = 0;

        // D. Nếu người dùng có chọn áp dụng Voucher
        if (mavoucher) {
            // 1. Tìm voucher trong DB
            const voucherRes = await db.query(
                `SELECT * FROM khuyen_mai 
                 WHERE ma_khuyen_mai = $1 
                   AND trang_thai = 'ACTIVE' 
                   AND ngay_bat_dau <= CURRENT_TIMESTAMP 
                   AND ngay_ket_thuc >= CURRENT_TIMESTAMP`,
                [mavoucher]
            );

            if (voucherRes.rows.length === 0) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Mã giảm giá không tồn tại, đã hết hạn hoặc ngưng hoạt động'
                });
            }

            const voucher = voucherRes.rows[0];

            // 2. Kiểm tra giới hạn số lượng còn lại
            if (voucher.so_luong_ma > 0 && voucher.so_luong_da_dung >= voucher.so_luong_ma) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Mã giảm giá này đã hết lượt sử dụng'
                });
            }

            // 3. Kiểm tra xem user này đã dùng mã này chưa (Chỉ được dùng 1 lần duy nhất)
            const historyRes = await db.query(
                'SELECT COUNT(*) FROM lich_su_khuyen_mai WHERE id_khuyen_mai = $1 AND id_khach = $2',
                [voucher.id, userId]
            );
            if (parseInt(historyRes.rows[0].count) >= 1) {
                return res.status(400).json({
                    status: 'error',
                    message: 'Bạn đã sử dụng mã giảm giá này rồi'
                });
            }

            // 4. Kiểm tra điều kiện Cấp bậc (Rank)
            if (voucher.ap_dung_user && voucher.ap_dung_user !== 'TAT_CA_USER') {
                const reqPriority = RANK_PRIORITY[voucher.ap_dung_user] || 0;
                const userPriority = RANK_PRIORITY[userRank] || 0;

                if (userPriority < reqPriority) {
                    const reqRankName = RANK_NAMES_VI[voucher.ap_dung_user] || voucher.ap_dung_user;
                    return res.status(400).json({
                        status: 'error',
                        message: `Mã giảm giá này yêu cầu cấp bậc tối thiểu là hạng ${reqRankName}`
                    });
                }
            }

            // 5. Kiểm tra giá trị đơn hàng tối thiểu
            const donhangToithieu = parseFloat(voucher.gia_tri_don_hang_toi_thieu);
            if (subtotal < donhangToithieu) {
                const gap = donhangToithieu - subtotal;
                return res.status(400).json({
                    status: 'error',
                    message: `Bạn cần mua thêm ${gap.toLocaleString('vi-VN')}đ để áp dụng mã này`
                });
            }

            // 6. Kiểm tra điều kiện Phim
            if (voucher.ap_dung_cho === 'PHIM_CU_THE' && showtimeId) {
                const showtimeRes = await db.query('SELECT maphim FROM lichchieu WHERE malichchieu = $1', [showtimeId]);
                if (showtimeRes.rows.length > 0) {
                    const maphim = showtimeRes.rows[0].maphim;
                    const phimRes = await db.query(
                        'SELECT 1 FROM khuyen_mai_phim WHERE id_khuyen_mai = $1 AND maphim = $2',
                        [voucher.id, maphim]
                    );
                    if (phimRes.rows.length === 0) {
                        return res.status(400).json({
                            status: 'error',
                            message: 'Mã giảm giá này không áp dụng cho bộ phim bạn đã chọn'
                        });
                    }
                }
            }

            // 7. Tính số tiền giảm giá của Voucher
            if (voucher.loai_giam === 'TIEN') {
                sotienDuocGiamVoucher = parseFloat(voucher.gia_tri_giam);
            } else if (voucher.loai_giam === 'PHAN_TRAM') {
                sotienDuocGiamVoucher = Math.round(subtotal * (parseFloat(voucher.gia_tri_giam) / 100));
                const giamToiDa = parseFloat(voucher.giam_toi_da);
                if (giamToiDa > 0 && sotienDuocGiamVoucher > giamToiDa) {
                    sotienDuocGiamVoucher = giamToiDa;
                }
            }

            appliedVoucher = {
                mavoucher: voucher.ma_khuyen_mai,
                ten: voucher.ten_khuyen_mai,
                sotien_duoc_giam: sotienDuocGiamVoucher
            };
        }

        // E. Đảm bảo tổng số tiền giảm không vượt quá Tạm tính
        let totalDiscount = sotienGiamRank + sotienDuocGiamVoucher;
        if (totalDiscount > subtotal) {
            sotienDuocGiamVoucher = subtotal - sotienGiamRank;
            if (appliedVoucher) {
                appliedVoucher.sotien_duoc_giam = sotienDuocGiamVoucher;
            }
            totalDiscount = subtotal;
        }

        const tongThanhToan = subtotal - totalDiscount;

        // F. Xây dựng câu thông báo ưu đãi hấp dẫn
        let thongBaoUuDai = '';
        if (rankDiscountRate > 0) {
            thongBaoUuDai += `Hạng ${RANK_NAMES_VI[userRank]} giảm ${(rankDiscountRate * 100)}% (-${sotienGiamRank.toLocaleString('vi-VN')}đ). `;
        }
        if (appliedVoucher) {
            thongBaoUuDai += `Bạn đã tiết kiệm được ${sotienDuocGiamVoucher.toLocaleString('vi-VN')}đ nhờ Voucher!`;
        } else {
            thongBaoUuDai += rankDiscountRate > 0 ? 'Thêm mã voucher để nhận thêm ưu đãi.' : 'Hãy thăng hạng hoặc áp dụng voucher để tiết kiệm chi phí.';
        }

        res.json({
            status: 'success',
            booking_summary: {
                tam_tinh: subtotal,
                uu_dai_rank: rankDiscountRate > 0 ? {
                    rank: userRank,
                    ten_rank: RANK_NAMES_VI[userRank],
                    phantram_giam: rankDiscountRate,
                    sotien_giam_rank: sotienGiamRank
                } : null,
                voucher_ap_dung: appliedVoucher,
                phi_thanh_toan: 0,
                tong_thanh_toan: tongThanhToan,
                thong_bao_uu_dai: thongBaoUuDai.trim()
            }
        });
    } catch (e) {
        console.error("Apply Voucher Error:", e);
        res.status(500).json({ status: 'error', message: 'Lỗi máy chủ khi áp dụng mã giảm giá' });
    }
};

// Export internal helper functions for reuse in bookingController
exports.internalCalculateDiscount = async (userId, subtotal, mavoucher, maphim) => {
    // 1. Lấy thông tin rank
    const { rank: userRank } = await getUserRankInfo(userId);
    const rankDiscountRate = RANK_DISCOUNT_RATES[userRank] || 0.00;
    const sotienGiamRank = Math.round(subtotal * rankDiscountRate);

    let voucherId = null;
    let sotienDuocGiamVoucher = 0;
    let appliedVoucherCode = null;

    if (mavoucher) {
        const voucherRes = await db.query(
            `SELECT * FROM khuyen_mai 
             WHERE ma_khuyen_mai = $1 
               AND trang_thai = 'ACTIVE' 
               AND ngay_bat_dau <= CURRENT_TIMESTAMP 
               AND ngay_ket_thuc >= CURRENT_TIMESTAMP`,
            [mavoucher]
        );

        if (voucherRes.rows.length > 0) {
            const voucher = voucherRes.rows[0];
            let isEligible = true;

            // Kiểm tra số lượng
            if (voucher.so_luong_ma > 0 && voucher.so_luong_da_dung >= voucher.so_luong_ma) {
                isEligible = false;
            }

            // Kiểm tra dùng 1 lần
            if (isEligible) {
                const historyRes = await db.query(
                    'SELECT COUNT(*) FROM lich_su_khuyen_mai WHERE id_khuyen_mai = $1 AND id_khach = $2',
                    [voucher.id, userId]
                );
                if (parseInt(historyRes.rows[0].count) >= 1) {
                    isEligible = false;
                }
            }

            // Kiểm tra Rank
            if (isEligible && voucher.ap_dung_user && voucher.ap_dung_user !== 'TAT_CA_USER') {
                const reqPriority = RANK_PRIORITY[voucher.ap_dung_user] || 0;
                const userPriority = RANK_PRIORITY[userRank] || 0;
                if (userPriority < reqPriority) {
                    isEligible = false;
                }
            }

            // Kiểm tra tối thiểu
            if (isEligible && subtotal < parseFloat(voucher.gia_tri_don_hang_toi_thieu)) {
                isEligible = false;
            }

            // Kiểm tra phim
            if (isEligible && voucher.ap_dung_cho === 'PHIM_CU_THE' && maphim) {
                const phimRes = await db.query(
                    'SELECT 1 FROM khuyen_mai_phim WHERE id_khuyen_mai = $1 AND maphim = $2',
                    [voucher.id, maphim]
                );
                if (phimRes.rows.length === 0) {
                    isEligible = false;
                }
            }

            if (isEligible) {
                voucherId = voucher.id;
                appliedVoucherCode = voucher.ma_khuyen_mai;
                if (voucher.loai_giam === 'TIEN') {
                    sotienDuocGiamVoucher = parseFloat(voucher.gia_tri_giam);
                } else if (voucher.loai_giam === 'PHAN_TRAM') {
                    sotienDuocGiamVoucher = Math.round(subtotal * (parseFloat(voucher.gia_tri_giam) / 100));
                    const giamToiDa = parseFloat(voucher.giam_toi_da);
                    if (giamToiDa > 0 && sotienDuocGiamVoucher > giamToiDa) {
                        sotienDuocGiamVoucher = giamToiDa;
                    }
                }
            }
        }
    }

    let totalDiscount = sotienGiamRank + sotienDuocGiamVoucher;
    if (totalDiscount > subtotal) {
        sotienDuocGiamVoucher = subtotal - sotienGiamRank;
        totalDiscount = subtotal;
    }

    const finalAmount = subtotal - totalDiscount;

    return {
        rank: userRank,
        rankDiscountRate,
        sotienGiamRank,
        voucherId,
        appliedVoucherCode,
        sotienDuocGiamVoucher,
        totalDiscount,
        finalAmount
    };
};
