# Cấu Trúc Database (Schema) - Neon DB

*Danh sách chi tiết các bảng, cột, kiểu dữ liệu trong cơ sở dữ liệu.*

## Bảng: `binhluan`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `mabinhluan` | `character varying` | `NO` | `` |
| `maphim` | `character varying` | `NO` | `` |
| `noidung` | `character varying` | `YES` | `` |
| `danhgia` | `integer` | `NO` | `` |
| `thoidiemdanhgia` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `id_khach` | `integer` | `NO` | `` |
| `id_nhanvien` | `integer` | `YES` | `` |
| `noidungreply` | `character varying` | `YES` | `` |

## Bảng: `combo_items`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `combo_item_id` | `integer` | `NO` | `nextval('combo_items_combo_item_id_seq'::regclass)` |
| `combo_id` | `integer` | `YES` | `` |
| `item_id` | `integer` | `YES` | `` |
| `quantity` | `integer` | `YES` | `1` |

## Bảng: `combos`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `combo_id` | `integer` | `NO` | `nextval('combos_combo_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `` |
| `price` | `integer` | `NO` | `` |
| `description` | `text` | `YES` | `` |
| `image_url` | `text` | `YES` | `` |
| `is_available` | `boolean` | `YES` | `true` |

## Bảng: `daodien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `madaodien` | `character varying` | `NO` | `` |
| `tendaodien` | `character varying` | `NO` | `` |
| `ngaysinh` | `timestamp without time zone` | `YES` | `` |
| `quoctich` | `character varying` | `YES` | `` |
| `urlanhdaidien` | `text` | `YES` | `` |

## Bảng: `dienvien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `madienvien` | `character varying` | `NO` | `` |
| `tendienvien` | `character varying` | `NO` | `` |
| `ngaysinh` | `timestamp without time zone` | `YES` | `` |
| `quoctich` | `character varying` | `YES` | `` |
| `urlanhdaidien` | `text` | `YES` | `` |

## Bảng: `dondatve`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `madondatve` | `character varying` | `NO` | `` |
| `ngaydatve` | `timestamp with time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `tongtien` | `integer` | `NO` | `0` |
| `trangthai` | `character varying` | `NO` | `'pending'::character varying` |
| `id_khach` | `integer` | `NO` | `` |

## Bảng: `ghengoi`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maghe` | `character varying` | `NO` | `` |
| `mahangghe` | `character varying` | `NO` | `` |
| `soghe` | `integer` | `NO` | `` |
| `loaighe` | `character varying` | `NO` | `` |
| `hesogiaghe` | `numeric` | `NO` | `1` |
| `maphong` | `character varying` | `NO` | `` |

## Bảng: `hashtag`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `mahashtag` | `character varying` | `NO` | `` |
| `tenhashtag` | `character varying` | `NO` | `` |

## Bảng: `items`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `item_id` | `integer` | `NO` | `nextval('items_item_id_seq'::regclass)` |
| `name` | `character varying` | `NO` | `` |
| `item_type` | `character varying` | `NO` | `` |
| `price` | `integer` | `NO` | `` |
| `image_url` | `text` | `YES` | `` |
| `stock_quantity` | `integer` | `YES` | `0` |
| `is_available` | `boolean` | `YES` | `true` |
| `created_at` | `timestamp without time zone` | `YES` | `CURRENT_TIMESTAMP` |
| `unit` | `character varying` | `YES` | `'thùng'::character varying` |

## Bảng: `khuyen_mai`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('khuyen_mai_id_seq'::regclass)` |
| `ma_khuyen_mai` | `character varying` | `NO` | `` |
| `ten_khuyen_mai` | `character varying` | `NO` | `` |
| `mo_ta` | `text` | `YES` | `` |
| `loai_giam` | `character varying` | `NO` | `` |
| `gia_tri_giam` | `numeric` | `NO` | `` |
| `giam_toi_da` | `numeric` | `YES` | `` |
| `gia_tri_don_hang_toi_thieu` | `numeric` | `YES` | `0` |
| `so_luong_ve_toi_thieu` | `integer` | `YES` | `1` |
| `so_luong_ma` | `integer` | `YES` | `` |
| `so_luong_da_dung` | `integer` | `YES` | `0` |
| `so_lan_dung_toi_da_moi_user` | `integer` | `YES` | `1` |
| `ngay_bat_dau` | `timestamp without time zone` | `NO` | `` |
| `ngay_ket_thuc` | `timestamp without time zone` | `NO` | `` |
| `ap_dung_cho` | `character varying` | `YES` | `'TAT_CA_PHIM'::character varying` |
| `ap_dung_user` | `character varying` | `YES` | `'TAT_CA_USER'::character varying` |
| `trang_thai` | `character varying` | `YES` | `'ACTIVE'::character varying` |
| `created_at` | `timestamp without time zone` | `YES` | `CURRENT_TIMESTAMP` |
| `updated_at` | `timestamp without time zone` | `YES` | `CURRENT_TIMESTAMP` |

## Bảng: `khuyen_mai_phim`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('khuyen_mai_phim_id_seq'::regclass)` |
| `id_khuyen_mai` | `integer` | `NO` | `` |
| `maphim` | `character varying` | `NO` | `` |

## Bảng: `khuyen_mai_user`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('khuyen_mai_user_id_seq'::regclass)` |
| `id_khuyen_mai` | `integer` | `NO` | `` |
| `id_khach` | `integer` | `NO` | `` |

## Bảng: `lich_su_khuyen_mai`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id` | `integer` | `NO` | `nextval('lich_su_khuyen_mai_id_seq'::regclass)` |
| `id_khuyen_mai` | `integer` | `NO` | `` |
| `id_khach` | `integer` | `NO` | `` |
| `madondatve` | `character varying` | `NO` | `` |
| `gia_tri_giam_thuc_te` | `numeric` | `NO` | `` |
| `ngay_su_dung` | `timestamp without time zone` | `YES` | `CURRENT_TIMESTAMP` |

## Bảng: `lichchieu`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `malichchieu` | `character varying` | `NO` | `` |
| `ngaychieu` | `timestamp without time zone` | `NO` | `` |
| `giochieu` | `timestamp without time zone` | `NO` | `` |
| `gioketthuc` | `timestamp without time zone` | `NO` | `` |
| `giave` | `integer` | `NO` | `` |
| `maphim` | `character varying` | `NO` | `` |
| `maphong` | `character varying` | `NO` | `` |

## Bảng: `nhanvien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id_nhanvien` | `integer` | `NO` | `nextval('nhanvien_id_nhanvien_seq'::regclass)` |
| `manhanvien` | `character varying` | `NO` | `` |
| `hoten` | `character varying` | `NO` | `` |
| `ngaysinh` | `timestamp without time zone` | `NO` | `` |
| `gioitinh` | `smallint` | `YES` | `` |
| `sdt` | `character varying` | `NO` | `` |
| `email` | `character varying` | `NO` | `` |
| `matkhau` | `character varying` | `NO` | `` |
| `anhdaidien` | `character varying` | `YES` | `` |
| `vaitro` | `character varying` | `NO` | `` |
| `ngaytao` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `ngaycapnhat` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |

## Bảng: `order_concessions`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id_order_concession` | `integer` | `NO` | `nextval('order_concessions_id_order_concession_seq'::regclass)` |
| `madondatve` | `character varying` | `NO` | `` |
| `item_id` | `integer` | `YES` | `` |
| `combo_id` | `integer` | `YES` | `` |
| `quantity` | `integer` | `NO` | `1` |
| `unit_price` | `integer` | `NO` | `` |
| `thanh_tien` | `integer` | `YES` | `` |
| `created_at` | `timestamp without time zone` | `YES` | `CURRENT_TIMESTAMP` |

## Bảng: `phim`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maphim` | `character varying` | `NO` | `` |
| `tenphim` | `character varying` | `NO` | `` |
| `ngayramat` | `timestamp without time zone` | `NO` | `` |
| `mota` | `text` | `NO` | `` |
| `thoiluong` | `integer` | `NO` | `` |
| `gioihantuoi` | `integer` | `NO` | `` |
| `poster_url` | `character varying` | `NO` | `` |
| `trailer_url` | `character varying` | `NO` | `` |
| `trangthai` | `character varying` | `NO` | `'coming_soon'::character varying` |
| `duoctaoboi` | `character varying` | `NO` | `` |
| `duoctaongay` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `tmdb_id` | `character varying` | `YES` | `` |

## Bảng: `phim_daodien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maphim` | `character varying` | `NO` | `` |
| `madaodien` | `character varying` | `NO` | `` |

## Bảng: `phim_dienvien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `madienvien` | `character varying` | `NO` | `` |
| `maphim` | `character varying` | `NO` | `` |

## Bảng: `phim_hashtag`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maphim` | `character varying` | `NO` | `` |
| `mahashtag` | `character varying` | `NO` | `` |

## Bảng: `phim_theloai`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maphim` | `character varying` | `NO` | `` |
| `matheloai` | `character varying` | `NO` | `` |

## Bảng: `phongrapphim`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `maphong` | `character varying` | `NO` | `` |
| `tenphong` | `character varying` | `NO` | `` |
| `soluongghe` | `integer` | `YES` | `` |
| `marapphim` | `character varying` | `NO` | `` |

## Bảng: `rapphim`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `marapphim` | `character varying` | `NO` | `` |
| `tenrapphim` | `character varying` | `NO` | `` |
| `diachi` | `character varying` | `NO` | `` |

## Bảng: `rapphim_nhanvien`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id_nhanvien` | `integer` | `NO` | `` |
| `marapphim` | `character varying` | `NO` | `` |

## Bảng: `theloai`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `matheloai` | `character varying` | `NO` | `` |
| `tentheloai` | `character varying` | `NO` | `` |
| `mota` | `character varying` | `YES` | `` |

## Bảng: `thongbao`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `mathongbao` | `character varying` | `NO` | `` |
| `noidung` | `character varying` | `NO` | `` |
| `thoidiemtb` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `trangthai` | `character varying` | `YES` | `` |
| `tieude` | `character varying` | `NO` | `` |
| `ngaytao` | `timestamp without time zone` | `NO` | `` |
| `thoidiemxem` | `timestamp without time zone` | `YES` | `` |
| `id_khach` | `integer` | `NO` | `` |
| `madondatve` | `character varying` | `NO` | `` |
| `maphim` | `character varying` | `NO` | `` |

## Bảng: `thongtintaikhoan`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `id_khach` | `integer` | `NO` | `nextval('thongtintaikhoan_id_khach_seq'::regclass)` |
| `mataikhoan` | `character varying` | `NO` | `` |
| `hoten` | `character varying` | `NO` | `` |
| `ngaysinh` | `timestamp without time zone` | `NO` | `` |
| `gioitinh` | `smallint` | `YES` | `` |
| `sdt` | `character varying` | `NO` | `` |
| `email` | `character varying` | `NO` | `` |
| `matkhau` | `character varying` | `NO` | `` |
| `anhdaidien` | `character varying` | `YES` | `` |
| `ngaytao` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `ngaycapnhat` | `timestamp without time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `trangthai` | `character varying` | `NO` | `'active'::character varying` |

## Bảng: `thongtinthanhtoan`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `mathanhtoan` | `character varying` | `NO` | `` |
| `phuongthucthanhtoan` | `character varying` | `NO` | `` |
| `paymentgatewaytransactionid` | `character varying` | `YES` | `` |
| `sotienthanhtoan` | `integer` | `NO` | `` |
| `thoidiemthanhtoan` | `timestamp with time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `trangthai` | `character varying` | `NO` | `` |
| `madondatve` | `character varying` | `NO` | `` |

## Bảng: `vexemphim`

| Tên Cột | Kiểu Dữ Liệu | Cho phép Null | Giá trị mặc định |
| :--- | :--- | :--- | :--- |
| `mavexemphim` | `character varying` | `NO` | `` |
| `qrcode` | `character varying` | `YES` | `` |
| `thoigianphathanh` | `timestamp with time zone` | `NO` | `CURRENT_TIMESTAMP` |
| `trangthai` | `character varying` | `NO` | `` |
| `thoigianhethan` | `timestamp without time zone` | `NO` | `` |
| `giave` | `integer` | `NO` | `` |
| `maghe` | `character varying` | `NO` | `` |
| `malichchieu` | `character varying` | `NO` | `` |
| `madondatve` | `character varying` | `NO` | `` |

