# API Documentation — Web Admin & Cinema Manager

Tài liệu mô tả các API dành cho **Web Admin** (Quản lý rạp / Nhân viên) sử dụng chung Backend với ứng dụng đặt vé khách hàng.

---

## 1. Tổng quan

| Mục | Giá trị |
|-----|---------|
| **Base URL** | `http://localhost:3000` (hoặc `process.env.PORT`) |
| **Prefix Admin** | `/api/admin` |
| **Định dạng** | `application/json` |
| **Xác thực** | Bearer Token (JWT), trừ endpoint đăng nhập |

### 1.1. Vai trò (Role)

Hệ thống dùng bảng `nhanvien` với hai vai trò, **cùng quyền truy cập** tất cả API bên dưới (middleware `isAdmin` không phân quyền theo từng route):

| Vai trò DB (`vaitro`) | Role trong JWT | Mô tả |
|------------------------|----------------|--------|
| `Quản Lý` | `QuanLy` | Quản lý rạp (Cinema Manager) |
| Khác (Nhân viên) | `NhanVien` | Nhân viên quầy / vận hành |

### 1.2. Header xác thực

```http
Authorization: Bearer <token>
```

### 1.3. Cấu trúc phản hồi chung

**Thành công (JSON):**

```json
{
  "status": "success",
  "message": "...",
  "data": { }
}
```

Một số endpoint trả thêm `total` (số bản ghi) thay vì/ngoài `data`.

**Lỗi:**

```json
{
  "status": "error",
  "message": "Mô tả lỗi"
}
```

| HTTP | Ý nghĩa |
|------|---------|
| `400` | Thiếu/sai tham số, nghiệp vụ không hợp lệ |
| `401` | Không có token |
| `403` | Token sai/hết hạn hoặc không đủ quyền (`role` không phải `NhanVien` / `QuanLy`) |
| `404` | Không tìm thấy tài nguyên |
| `500` | Lỗi server |

### 1.4. Tài khoản mẫu (seed)

| Email | Mật khẩu | Vai trò |
|-------|----------|---------|
| `ql@nhom7.com` | `123456` | Quản Lý |

---

## 2. Xác thực (Auth)

### 2.1. Đăng nhập Admin / Cinema Manager

Đăng nhập cho nhân viên và quản lý rạp. **Không** cần header `Authorization`.

| | |
|---|---|
| **URL** | `POST /api/admin/login` |
| **Auth** | Không |

**Request body:**

```json
{
  "email": "ql@nhom7.com",
  "matKhau": "123456"
}
```

| Field | Kiểu | Bắt buộc | Mô tả |
|-------|------|----------|--------|
| `email` | string | Có | Email nhân viên |
| `matKhau` | string | Có | Mật khẩu (hỗ trợ bcrypt hoặc plain-text seed) |

**Response `200` — thành công:**

```json
{
  "status": "success",
  "message": "Đăng nhập quản lý thành công",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "staff": {
    "id": 1,
    "maNhanVien": "NV01",
    "hoTen": "Quản Lý Rạp",
    "email": "ql@nhom7.com",
    "vaiTro": "Quản Lý"
  }
}
```

**Payload JWT** (thời hạn 12h):

```json
{
  "id": 1,
  "maNhanVien": "NV01",
  "role": "QuanLy"
}
```

**Response lỗi:**

| Code | Message mẫu |
|------|-------------|
| `400` | `Vui lòng nhập email và mật khẩu` |
| `404` | `Tài khoản nhân viên không tồn tại` |
| `401` | `Mật khẩu không chính xác` |

---

## 3. Phim & Hashtag

> Tất cả endpoint từ mục này trở đi **bắt buộc** Bearer Token.

### 3.1. Cập nhật poster phim

| | |
|---|---|
| **URL** | `PUT /api/admin/update-poster/:id` |
| **`:id`** | `maphim` (VD: `P001`) |

**Request body:**

```json
{
  "poster_url": "https://image.tmdb.org/t/p/w500/example.jpg"
}
```

**Response `200`:**

```json
{
  "status": "success",
  "message": "Cập nhật poster thành công",
  "data": {
    "maphim": "P001",
    "tenphim": "DUNE: HÀNH TINH CÁT 2",
    "poster_url": "https://image.tmdb.org/t/p/w500/example.jpg"
  }
}
```

---

### 3.2. Gắn hashtag cho phim

| | |
|---|---|
| **URL** | `POST /api/admin/movies/:id/hashtags` |
| **`:id`** | `maphim` |

**Request body** (một trong hai cách):

```json
{
  "maHashtag": "HT01"
}
```

```json
{
  "tenHashTag": "#PhimHot"
}
```

| Field | Mô tả |
|-------|--------|
| `maHashtag` | Mã hashtag có sẵn |
| `tenHashTag` | Tên hashtag; tự tạo mã mới nếu chưa tồn tại (VD: `HT04`) |

**Response `201`:**

```json
{
  "status": "success",
  "message": "Gắn hashtag thành công",
  "data": {
    "maphim": "P001",
    "mahashtag": "HT01"
  }
}
```

**Lỗi:** `400` nếu hashtag đã gắn; `400` nếu thiếu cả `maHashtag` và `tenHashTag`.

---

### 3.3. Xóa hashtag khỏi phim

| | |
|---|---|
| **URL** | `DELETE /api/admin/movies/:id/hashtags/:hashtagId` |
| **`:id`** | `maphim` |
| **`:hashtagId`** | `mahashtag` |

**Response `200`:**

```json
{
  "status": "success",
  "message": "Xoá hashtag khỏi phim thành công"
}
```

---

## 4. Lịch chiếu (Showtimes)

### 4.1. Tạo lịch chiếu mới

Hệ thống **tự tính** `gioketthuc` = `gioChieu` + `thoiluong` phim + **15 phút** nghỉ. Kiểm tra trùng khung giờ trong cùng phòng.

| | |
|---|---|
| **URL** | `POST /api/admin/showtimes` |

**Request body** (hỗ trợ camelCase hoặc lowercase):

```json
{
  "maPhim": "P001",
  "maPhong": "PR01",
  "ngayChieu": "2024-05-15",
  "gioChieu": "2024-05-15T19:00:00",
  "giaVe": 120000
}
```

| Field | Bắt buộc | Mô tả |
|-------|----------|--------|
| `maPhim` / `maphim` | Có | Mã phim |
| `maPhong` / `maphong` | Có | Mã phòng |
| `ngayChieu` / `ngaychieu` | Có | Ngày chiếu |
| `gioChieu` / `giochieu` | Có | ISO 8601 hoặc `YYYY-MM-DD HH:mm:ss` |
| `giaVe` / `giave` | Có | Giá vé cơ bản (số nguyên) |

**Response `201`:**

```json
{
  "status": "success",
  "message": "Tạo lịch chiếu thành công. Giờ kết thúc tự động: ... (thời lượng 166 phút + 15 phút nghỉ)",
  "data": {
    "malichchieu": "LC-1716123456789",
    "ngaychieu": "2024-05-15T00:00:00.000Z",
    "giochieu": "2024-05-15T12:00:00.000Z",
    "gioketthuc": "2024-05-15T14:46:00.000Z",
    "giave": 120000,
    "maphim": "P001",
    "maphong": "PR01"
  }
}
```

**Response `400` — trùng lịch:**

```json
{
  "status": "error",
  "message": "Khung giờ này đã có lịch chiếu tại phòng đã chọn. Vui lòng chọn giờ khác.",
  "conflictWith": {
    "malichchieu": "LC001",
    "giochieu": "...",
    "gioketthuc": "..."
  }
}
```

---

## 5. Rạp, phòng & ghế

### 5.1. Danh sách phòng theo rạp

| | |
|---|---|
| **URL** | `GET /api/admin/theaters/:id/rooms` |
| **`:id`** | `marapphim` (VD: `R001`) |

**Response `200`:**

```json
{
  "status": "success",
  "total": 1,
  "data": [
    {
      "maphong": "PR01",
      "tenphong": "Phòng IMAX",
      "soluongghe": 64,
      "marapphim": "R001"
    }
  ]
}
```

---

### 5.2. Danh sách ghế theo phòng

| | |
|---|---|
| **URL** | `GET /api/admin/rooms/:id/seats` |
| **`:id`** | `maphong` |

**Response `200`:**

```json
{
  "status": "success",
  "room": {
    "maphong": "PR01",
    "tenphong": "Phòng IMAX",
    "soluongghe": 64,
    "marapphim": "R001",
    "tenrapphim": "Nhóm 7 Cinema Sư Vạn Hạnh"
  },
  "total": 4,
  "data": [
    {
      "maghe": "G001",
      "mahangghe": "A",
      "soghe": 1,
      "loaighe": "normal",
      "hesogiaghe": "1.0",
      "maphong": "PR01"
    }
  ]
}
```

---

### 5.3. Cập nhật loại ghế

Cập nhật loại ghế và **hệ số giá** tự động: `normal` → 1.0, `vip` → 1.5, `couple` → 2.0, `hỏng` → 0 (không đặt được).

| | |
|---|---|
| **URL** | `PUT /api/admin/seats/:maGhe/status` |
| **`:maGhe`** | Mã ghế (VD: `G001`, `PR01_A1`) |

**Request body:**

```json
{
  "loaiGhe": "vip"
}
```

| `loaiGhe` | Hệ số giá |
|-----------|-----------|
| `normal` | 1.0 |
| `vip` | 1.5 |
| `couple` | 2.0 |
| `hỏng` | 0 |

**Response `200`:**

```json
{
  "status": "success",
  "message": "Cập nhật ghế G001 thành loại 'vip' thành công",
  "data": {
    "maghe": "G001",
    "loaighe": "vip",
    "hesogiaghe": "1.5",
    "maphong": "PR01",
    "mahangghe": "A",
    "soghe": 1
  }
}
```

---

## 6. Khách hàng, đơn vé & thanh toán

### 6.1. Danh sách đơn đặt vé

| | |
|---|---|
| **URL** | `GET /api/admin/bookings` |

**Query parameters (tùy chọn):**

| Param | Mô tả |
|-------|--------|
| `movieId` | Lọc theo `maphim` |
| `theaterId` | Lọc theo `marapphim` |
| `status` | Trạng thái đơn: `pending`, `paid`, `cancelled` |

**Ví dụ:** `GET /api/admin/bookings?movieId=P001&status=paid`

**Response `200`:**

```json
{
  "status": "success",
  "total": 2,
  "data": [
    {
      "ma_ve": "VE123456",
      "madondatve": "DDV001",
      "ngaydatve": "2024-04-10T10:30:00.000Z",
      "tongtien": 200000,
      "trangthai_don": "paid",
      "id_khach": 1,
      "hoten": "Nguyễn Văn A",
      "email": "nguyenvana@gmail.com",
      "sdt": "0901234567",
      "maphim": "P001",
      "tenphim": "DUNE: HÀNH TINH CÁT 2",
      "maghe": "G001",
      "loaighe": "normal",
      "mahangghe": "A",
      "soghe": 1,
      "malichchieu": "LC001",
      "ngaychieu": "2024-04-10T00:00:00.000Z",
      "giochieu": "2024-04-10T11:00:00.000Z",
      "gioketthuc": "2024-04-10T13:46:00.000Z",
      "gia_ve_lichchieu": 100000,
      "gia_ve": 100000,
      "trangthai_ve": "active",
      "maphong": "PR01",
      "tenphong": "Phòng IMAX",
      "marapphim": "R001",
      "tenrapphim": "Nhóm 7 Cinema Sư Vạn Hạnh",
      "matthanhtoan": "PAY123456",
      "phuongthucthanhtoan": "vnpay",
      "trangthai_thanhtoan": "success"
    }
  ]
}
```

> Mỗi dòng tương ứng **một vé**; một đơn nhiều ghế sẽ có nhiều dòng cùng `madondatve`.

---

### 6.2. Danh sách khách hàng

| | |
|---|---|
| **URL** | `GET /api/admin/customers` |

**Response `200`:**

```json
{
  "status": "success",
  "total": 2,
  "data": [
    {
      "id_khach": 1,
      "mataikhoan": "TK001",
      "hoten": "Nguyễn Văn A",
      "ngaysinh": "1995-05-12T00:00:00.000Z",
      "gioitinh": 1,
      "sdt": "0901234567",
      "email": "nguyenvana@gmail.com",
      "anhdaidien": null,
      "ngaytao": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

---

### 6.3. Xóa khách hàng

| | |
|---|---|
| **URL** | `DELETE /api/admin/customers/:id` |
| **`:id`** | `id_khach` |

**Response `200`:**

```json
{
  "status": "success",
  "message": "Xoá khách hàng thành công"
}
```

**Lỗi:** `400` nếu còn đơn `pending` hoặc `paid`; `400` nếu vi phạm ràng buộc FK.

---

### 6.4. Cập nhật trạng thái thanh toán

Đồng bộ trạng thái đơn đặt vé:

| `trangthai` thanh toán | Trạng thái đơn (`dondatve`) |
|------------------------|------------------------------|
| `success` | `paid` |
| `failed` | `cancelled` (+ gửi thông báo in-app & email) |
| `pending` | `pending` |

| | |
|---|---|
| **URL** | `PUT /api/admin/payments/:id/status` |
| **`:id`** | `matthanhtoan` |

**Request body:**

```json
{
  "trangthai": "success"
}
```

**Response `200`:**

```json
{
  "status": "success",
  "message": "Cập nhật trạng thái thanh toán PAY123456 thành 'success' thành công",
  "data": {
    "matthanhtoan": "PAY123456",
    "phuongthucthanhtoan": "vnpay",
    "sotienthanhtoan": 200000,
    "trangthai": "success",
    "madondatve": "DDV001",
    "thoidiemthanhtoan": "2024-04-10T10:35:00.000Z"
  }
}
```

---

## 7. Đồ ăn, thức uống, phụ kiện & combo

### 7.1. Items (đồ ăn / nước / phụ kiện)

#### GET — Danh sách tất cả items (kể cả ngừng bán)

| | |
|---|---|
| **URL** | `GET /api/admin/items` |

**Response `200`:**

```json
{
  "status": "success",
  "total": 3,
  "data": [
    {
      "item_id": 1,
      "name": "Bắp Rang Bơ",
      "item_type": "food",
      "price": "55000",
      "image_url": null,
      "stock_quantity": 100,
      "unit": "phần",
      "is_available": true,
      "created_at": "2024-04-01T00:00:00.000Z"
    }
  ]
}
```

#### POST — Thêm item

| | |
|---|---|
| **URL** | `POST /api/admin/items` |

**Request body:**

```json
{
  "name": "Bắp Rang Bơ Phô Mai",
  "item_type": "food",
  "price": 55000,
  "image_url": "https://example.com/bap.jpg",
  "stock_quantity": 100,
  "unit": "phần"
}
```

| Field | Bắt buộc | Mô tả |
|-------|----------|--------|
| `name` | Có | Tên sản phẩm |
| `item_type` | Có | `food` \| `drink` \| `accessory` |
| `price` | Có | Giá (số) |
| `image_url` | Không | URL ảnh |
| `stock_quantity` | Không | Mặc định `0` |
| `unit` | Không | Đơn vị (VD: `ly`, `phần`) |

**Response `201`:**

```json
{
  "status": "success",
  "message": "Thêm sản phẩm thành công",
  "data": { "item_id": 4, "name": "Bắp Rang Bơ Phô Mai", "item_type": "food", "price": "55000", "..." : "..." }
}
```

#### PUT — Cập nhật item

| | |
|---|---|
| **URL** | `PUT /api/admin/items/:id` |
| **`:id`** | `item_id` |

**Request body** (gửi field cần đổi; field không gửi giữ nguyên):

```json
{
  "name": "Bắp Caramel",
  "price": 60000,
  "stock_quantity": 80,
  "is_available": false
}
```

**Response `200`:** `{ "status": "success", "message": "Cập nhật sản phẩm thành công", "data": { ... } }`

#### DELETE — Xóa item

| | |
|---|---|
| **URL** | `DELETE /api/admin/items/:id` |

**Response `200`:** `{ "status": "success", "message": "Xoá sản phẩm thành công" }`

---

### 7.2. Phụ kiện (Accessories)

API riêng nhưng thao tác trên bảng `items` với `item_type = 'accessory'`.

| Method | URL |
|--------|-----|
| `GET` | `/api/admin/accessories` |
| `POST` | `/api/admin/accessories` |
| `PUT` | `/api/admin/accessories/:id` |
| `DELETE` | `/api/admin/accessories/:id` |

**POST body** (tương tự item; `item_type` tự gán `accessory`):

```json
{
  "name": "Kính 3D",
  "price": 30000,
  "stock_quantity": 50
}
```

**GET response:** giống mục 7.1, chỉ items loại `accessory`.

---

### 7.3. Combos

#### GET — Danh sách combo (kèm thành phần)

| | |
|---|---|
| **URL** | `GET /api/admin/combos` |

**Response `200`:**

```json
{
  "status": "success",
  "total": 1,
  "data": [
    {
      "combo_id": 1,
      "name": "Combo 1 Bắp 2 Nước",
      "price": "99000",
      "description": "Siêu tiết kiệm",
      "image_url": "https://images.unsplash.com/...",
      "is_available": true,
      "items": [
        {
          "combo_item_id": 1,
          "item_id": 1,
          "name": "Bắp Rang Bơ",
          "quantity": 1
        },
        {
          "combo_item_id": 2,
          "item_id": 2,
          "name": "Coca Cola",
          "quantity": 2
        }
      ]
    }
  ]
}
```

#### POST — Tạo combo

| | |
|---|---|
| **URL** | `POST /api/admin/combos` |

**Request body:**

```json
{
  "name": "Combo 1 Bắp 2 Nước",
  "price": 99000,
  "description": "Siêu tiết kiệm cho 2 người",
  "image_url": "https://example.com/combo.jpg",
  "items": [
    { "item_id": 1, "quantity": 1 },
    { "item_id": 2, "quantity": 2 }
  ]
}
```

| Field | Bắt buộc |
|-------|----------|
| `name`, `price` | Có |
| `description`, `image_url` | Không (ảnh mặc định Unsplash nếu trống) |
| `items` | Không (có thể thêm sau bằng PUT) |

**Response `201`:**

```json
{
  "status": "success",
  "message": "Thêm combo thành công",
  "data": {
    "combo_id": 2,
    "name": "Combo 1 Bắp 2 Nước",
    "price": "99000",
    "description": "Siêu tiết kiệm cho 2 người",
    "image_url": "https://example.com/combo.jpg",
    "is_available": true
  }
}
```

#### PUT — Cập nhật combo

| | |
|---|---|
| **URL** | `PUT /api/admin/combos/:id` |

**Request body:**

```json
{
  "name": "Combo VIP",
  "price": 129000,
  "is_available": true,
  "items": [
    { "item_id": 1, "quantity": 2 },
    { "item_id": 3, "quantity": 1 }
  ]
}
```

> Nếu gửi `items`, hệ thống **xóa** toàn bộ `combo_items` cũ và thêm lại danh sách mới.

#### DELETE — Xóa combo

| | |
|---|---|
| **URL** | `DELETE /api/admin/combos/:id` |

---

### 7.4. POS — Bán đồ ăn tại quầy

#### POST — Tạo hóa đơn POS

Đơn có mã tiền tố `POS`, thanh toán tiền mặt, trạng thái `paid`. `id_khach` = `id` nhân viên đang đăng nhập.

| | |
|---|---|
| **URL** | `POST /api/admin/pos/concessions/book` |

**Request body:**

```json
{
  "concessions": [
    { "comboId": 1, "quantity": 2, "price": 99000 },
    { "comboId": 2, "quantity": 1, "price": 129000 }
  ]
}
```

| Field | Mô tả |
|-------|--------|
| `comboId` | `combo_id` |
| `quantity` | Số lượng |
| `price` | Đơn giá tại thời điểm bán |

**Response `201`:**

```json
{
  "status": "success",
  "message": "Thanh toán hoá đơn tại quầy thành công",
  "data": {
    "maDonDatVe": "POS1234567",
    "tongtien": 327000
  }
}
```

#### GET — Lịch sử đơn POS

| | |
|---|---|
| **URL** | `GET /api/admin/pos/concessions/orders` |

**Response `200`:**

```json
{
  "status": "success",
  "total": 1,
  "data": [
    {
      "madondatve": "POS1234567",
      "ngaydatve": "2024-04-10T14:00:00.000Z",
      "tongtien": 327000,
      "items": [
        {
          "combo_id": 1,
          "name": "Combo 1 Bắp 2 Nước",
          "quantity": 2,
          "unit_price": 99000
        }
      ]
    }
  ]
}
```

---

## 8. Thống kê & báo cáo

### 8.1. Số vé theo phim

| | |
|---|---|
| **URL** | `GET /api/admin/stats/bookings-by-movie` |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    {
      "maphim": "P001",
      "tenphim": "DUNE: HÀNH TINH CÁT 2",
      "poster_url": "https://...",
      "so_ve": 150,
      "tong_tien": 15000000
    }
  ]
}
```

> Chỉ tính vé thuộc đơn `paid`.

---

### 8.2. Số vé theo rạp

| | |
|---|---|
| **URL** | `GET /api/admin/stats/bookings-by-theater` |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    {
      "marapphim": "R001",
      "tenrapphim": "Nhóm 7 Cinema Sư Vạn Hạnh",
      "diachi": "Tầng 5, Vạn Hạnh Mall...",
      "so_ve": 200,
      "tong_tien": 20000000
    }
  ]
}
```

---

### 8.3. Doanh thu theo phim

| | |
|---|---|
| **URL** | `GET /api/admin/stats/revenue-by-movie` |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    {
      "maphim": "P001",
      "tenphim": "DUNE: HÀNH TINH CÁT 2",
      "so_ve": 150,
      "doanh_thu": 15000000
    }
  ]
}
```

---

### 8.4. Doanh thu theo ngày

| | |
|---|---|
| **URL** | `GET /api/admin/stats/daily-revenue` |

**Query (bắt buộc):**

| Param | Ví dụ | Mô tả |
|-------|-------|--------|
| `from` | `2024-04-01` | Ngày bắt đầu |
| `to` | `2024-04-30` | Ngày kết thúc |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    {
      "ngay": "2024-04-01T00:00:00.000Z",
      "tien_ban_ve": 5000000,
      "tien_fb": 0,
      "tien_hoan_huy": 200000,
      "doanh_thu_thuc_te": 4800000
    }
  ]
}
```

> `tien_fb` hiện trả `0` (chưa tích hợp F&B vào thống kê ngày).

---

### 8.5. Doanh thu 7 ngày gần nhất

| | |
|---|---|
| **URL** | `GET /api/admin/stats/weekly-revenue` |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    { "ngay": "2024-05-20", "nhan": "T2", "doanh_thu": 1200000 },
    { "ngay": "2024-05-21", "nhan": "T3", "doanh_thu": 0 },
    { "ngay": "2024-05-22", "nhan": "T4", "doanh_thu": 3500000 },
    { "ngay": "2024-05-23", "nhan": "T5", "doanh_thu": 2100000 },
    { "ngay": "2024-05-24", "nhan": "T6", "doanh_thu": 4800000 },
    { "ngay": "2024-05-25", "nhan": "T7", "doanh_thu": 6200000 },
    { "ngay": "2024-05-26", "nhan": "CN", "doanh_thu": 5100000 }
  ]
}
```

---

### 8.6. Tổng quan Dashboard (hôm nay)

| | |
|---|---|
| **URL** | `GET /api/admin/stats/dashboard-summary` |

**Response `200`:**

```json
{
  "status": "success",
  "data": {
    "totalRevenueToday": 5100000,
    "ticketSoldToday": 42,
    "moviesNowShowing": 3,
    "totalCustomersToday": 150,
    "hotMovies": [
      {
        "maphim": "P001",
        "tenphim": "DUNE: HÀNH TINH CÁT 2",
        "poster_url": "https://...",
        "so_ve": 120
      }
    ]
  }
}
```

| Field | Mô tả |
|-------|--------|
| `totalRevenueToday` | Tổng tiền đơn `paid` hôm nay |
| `ticketSoldToday` | Vé `active` phát hành hôm nay |
| `moviesNowShowing` | Phim `trangthai = 'now_showing'` |
| `totalCustomersToday` | Tổng số tài khoản khách (toàn hệ thống) |
| `hotMovies` | Top 5 phim theo số vé `paid` |

---

### 8.7. Xuất báo cáo tháng (XLSX)

| | |
|---|---|
| **URL** | `GET /api/admin/reports/monthly` |
| **Response** | File Excel (không phải JSON) |

**Query (bắt buộc):**

| Param | Ví dụ | Định dạng |
|-------|-------|-----------|
| `month` | `2024-04` | `YYYY-MM` |

**Response headers:**

```http
Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
Content-Disposition: attachment; filename=BaoCao_Thang_2024-04.xlsx
```

**Nội dung file (3 sheet):**

1. **Tổng Quan** — Tổng đơn, tổng vé, tổng doanh thu tháng  
2. **Doanh Thu Theo Phim** — Tên phim, số vé, doanh thu  
3. **Chi Tiết Vé** — Mã đơn, khách hàng, phim, ghế, giá, ngày đặt  

**Lỗi `400` (JSON):**

```json
{
  "status": "error",
  "message": "Vui lòng truyền tham số month theo định dạng YYYY-MM (VD: 2024-04)"
}
```

---

## 9. Đánh giá / bình luận

### 9.1. Danh sách bình luận theo phim

| | |
|---|---|
| **URL** | `GET /api/admin/movies/:id/reviews` |
| **`:id`** | `maphim` |

**Response `200`:**

```json
{
  "status": "success",
  "total": 2,
  "data": [
    {
      "mabinhluan": "BL001",
      "noidung": "Phim rất hay!",
      "danhgia": 5,
      "thoidiemdanhgia": "2024-04-05T08:00:00.000Z",
      "noidungreply": null,
      "id_nhanvien": null,
      "ten_khach": "Nguyễn Văn A",
      "email_khach": "nguyenvana@gmail.com",
      "anhdaidien": null,
      "ten_nhanvien_reply": null
    }
  ]
}
```

---

### 9.2. Trả lời bình luận (nhân viên / quản lý)

| | |
|---|---|
| **URL** | `POST /api/admin/reviews/:id/reply` |
| **`:id`** | `mabinhluan` |

**Request body:**

```json
{
  "noiDungReply": "Cảm ơn bạn đã ủng hộ rạp chiếu phim của chúng tôi!"
}
```

**Response `200`:**

```json
{
  "status": "success",
  "message": "Trả lời bình luận thành công",
  "data": {
    "mabinhluan": "BL001",
    "noidung": "Phim rất hay!",
    "danhgia": 5,
    "noidungreply": "Cảm ơn bạn đã ủng hộ rạp chiếu phim của chúng tôi!",
    "id_nhanvien": 1,
    "maphim": "P001",
    "id_khach": 1,
    "thoidiemdanhgia": "2024-04-05T08:00:00.000Z"
  }
}
```

---

### 9.3. Kiểm tra quyền đánh giá phim (Khách hàng)

Kiểm tra xem khách hàng có thể đánh giá phim hay không (phải mua vé và phim đã chiếu xong).

| | |
|---|---|
| **URL** | `GET /api/reviews/:movieId/can-review` |
| **`:movieId`** | `maphim` |
| **Auth** | Bearer Token |

**Response `200`:**

```json
{
  "status": "success",
  "canReview": true,
  "existingReview": {
    "noidung": "Phim hay",
    "danhgia": 8
  }
}
```

> `existingReview` sẽ là `null` nếu khách hàng chưa từng đánh giá phim này.

---

### 9.4. Danh sách bình luận theo phim (Khách hàng)

Xem tất cả các bình luận của phim từ phía người dùng (không cần đăng nhập).

| | |
|---|---|
| **URL** | `GET /api/reviews/:movieId` |
| **`:movieId`** | `maphim` |

**Response `200`:**

```json
{
  "status": "success",
  "data": [
    {
      "mabinhluan": "BL567890",
      "maphim": "P001",
      "noidung": "Phim xem rất bánh cuốn!",
      "danhgia": 9,
      "id_khach": 1,
      "thoidiemdanhgia": "2024-04-05T08:15:00.000Z",
      "noidungreply": null,
      "id_nhanvien": null,
      "hoten": "Nguyễn Văn A",
      "anhdaidien": null
    }
  ]
}
```

---

### 9.5. Đăng bình luận & đánh giá (Khách hàng)

Khách hàng đăng bình luận và điểm đánh giá cho một bộ phim. Nếu khách hàng đã từng đánh giá, hệ thống sẽ **cập nhật** bình luận cũ.

| | |
|---|---|
| **URL** | `POST /api/reviews/:movieId` |
| **`:movieId`** | `maphim` |
| **Auth** | Bearer Token |

**Request body:**

```json
{
  "noiDung": "Phim quá hay, đáng để xem lại lần nữa!",
  "danhGia": 10
}
```

| Field | Kiểu | Bắt buộc | Mô tả |
|-------|------|----------|--------|
| `noiDung` | string | Có | Nội dung bình luận |
| `danhGia` | number | Có | Điểm đánh giá (từ 1 đến 10) |

**Response `201` (Tạo mới) / `200` (Cập nhật):**

```json
{
  "status": "success",
  "message": "Cảm ơn bạn đã đánh giá phim",
  "data": {
    "mabinhluan": "BL567890",
    "maphim": "P001",
    "noidung": "Phim quá hay, đáng để xem lại lần nữa!",
    "danhgia": 10,
    "id_khach": 1,
    "thoidiemdanhgia": "2024-04-05T08:15:00.000Z"
  }
}
```

**Lỗi `403`:**

```json
{
  "status": "error",
  "message": "Bạn cần mua vé và xem phim trước khi đánh giá"
}
```

---

## 10. Bảng tóm tắt endpoint

| # | Method | Endpoint | Mô tả |
|---|--------|----------|--------|
| 1 | `POST` | `/api/admin/login` | Đăng nhập |
| 2 | `PUT` | `/api/admin/update-poster/:id` | Cập nhật poster |
| 3 | `POST` | `/api/admin/movies/:id/hashtags` | Gắn hashtag |
| 4 | `DELETE` | `/api/admin/movies/:id/hashtags/:hashtagId` | Gỡ hashtag |
| 5 | `POST` | `/api/admin/showtimes` | Tạo lịch chiếu |
| 6 | `GET` | `/api/admin/theaters/:id/rooms` | Phòng theo rạp |
| 7 | `GET` | `/api/admin/rooms/:id/seats` | Ghế theo phòng |
| 8 | `PUT` | `/api/admin/seats/:maGhe/status` | Đổi loại ghế |
| 9 | `GET` | `/api/admin/bookings` | Danh sách đơn/vé |
| 10 | `GET` | `/api/admin/customers` | Danh sách khách |
| 11 | `DELETE` | `/api/admin/customers/:id` | Xóa khách |
| 12 | `PUT` | `/api/admin/payments/:id/status` | Cập nhật thanh toán |
| 13 | `GET` | `/api/admin/items` | DS items |
| 14 | `POST` | `/api/admin/items` | Thêm item |
| 15 | `PUT` | `/api/admin/items/:id` | Sửa item |
| 16 | `DELETE` | `/api/admin/items/:id` | Xóa item |
| 17 | `GET` | `/api/admin/accessories` | DS phụ kiện |
| 18 | `POST` | `/api/admin/accessories` | Thêm phụ kiện |
| 19 | `PUT` | `/api/admin/accessories/:id` | Sửa phụ kiện |
| 20 | `DELETE` | `/api/admin/accessories/:id` | Xóa phụ kiện |
| 21 | `GET` | `/api/admin/combos` | DS combo |
| 22 | `POST` | `/api/admin/combos` | Tạo combo |
| 23 | `PUT` | `/api/admin/combos/:id` | Sửa combo |
| 24 | `DELETE` | `/api/admin/combos/:id` | Xóa combo |
| 25 | `POST` | `/api/admin/pos/concessions/book` | Hóa đơn POS |
| 26 | `GET` | `/api/admin/pos/concessions/orders` | Lịch sử POS |
| 27 | `GET` | `/api/admin/stats/bookings-by-movie` | Vé theo phim |
| 28 | `GET` | `/api/admin/stats/bookings-by-theater` | Vé theo rạp |
| 29 | `GET` | `/api/admin/stats/revenue-by-movie` | Doanh thu phim |
| 30 | `GET` | `/api/admin/stats/daily-revenue` | Doanh thu ngày |
| 31 | `GET` | `/api/admin/stats/weekly-revenue` | Doanh thu 7 ngày |
| 32 | `GET` | `/api/admin/stats/dashboard-summary` | Dashboard |
| 33 | `GET` | `/api/admin/reports/monthly` | Báo cáo XLSX |
| 34 | `GET` | `/api/admin/movies/:id/reviews` | Bình luận phim |
| 35 | `POST` | `/api/admin/reviews/:id/reply` | Trả lời bình luận |
| 36 | `GET` | `/api/reviews/:movieId` | Xem danh sách bình luận (Khách hàng) |
| 37 | `POST` | `/api/reviews/:movieId` | Đăng bình luận & đánh giá (Khách hàng) |

---

## 11. Ghi chú cho Web Admin

1. **API công khai phim** (đọc danh sách/chi tiết phim cho dropdown): dùng `/api/movies` — không nằm trong prefix admin; không cần token nhân viên.
2. **Phân quyền theo route:** Hiện tại `NhanVien` và `QuanLy` dùng chung 34 endpoint (trừ login). Nếu Web Admin cần giới hạn (VD: chỉ Quản lý xóa khách / xuất báo cáo), cần bổ sung middleware phía Backend.
3. **Cập nhật poster:** Route đăng ký tại `PUT /api/admin/update-poster/:id` (không nằm dưới `/movies/:id/poster`).
4. **Đổi trạng thái ghế:** Dùng đúng path `.../seats/:maGhe/status`, không bỏ `/status`.
5. **Socket.IO:** Backend hỗ trợ real-time ghế tại cùng cổng HTTP; Web Admin chọn ghế có thể tích hợp sau nếu cần.
6. Tài liệu kiểm thử nhanh bằng Postman: xem thêm `backend/admin_postman_guide.md`.

---

*Tài liệu sinh từ `backend/routes/adminRoutes.js` và các controller trong `backend/controllers/admin/`.*
