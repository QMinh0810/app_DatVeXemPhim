# Hướng dẫn Kiểm thử API Quản trị (Admin) bằng Postman

Tài liệu này cung cấp hướng dẫn chi tiết cách thiết lập và gọi các API dành cho App Quản Lý rạp chiếu phim bằng Postman (Đã được cập nhật theo cấu trúc Backend mới nhất).

## 1. Thiết lập Ban đầu (Môi trường - Environment)

Để kiểm thử dễ dàng hơn, bạn nên tạo một Environment trong Postman và thêm biến `token_admin`.
1. Mở Postman, chọn mục **Environments** (biểu tượng con mắt ở góc trên bên phải hoặc tab ở sidebar trái).
2. Nhấn **+ (Add)** để tạo môi trường mới, đặt tên là `Nhom7 Cinema`.
3. Thêm một biến (Variable) mới có tên: `token_admin` (Giá trị hiện tại để trống).
4. Đảm bảo bạn đã chọn môi trường `Nhom7 Cinema` (ở dropdown góc trên bên phải).

---

## 2. Lấy Token Đăng nhập (Bắt buộc)

Tất cả các API quản lý (ngoại trừ login) đều yêu cầu phải có Token hợp lệ của Nhân viên hoặc Quản lý.

*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/login`
*   **Body (raw -> JSON):**
    ```json
    {
        "email": "ql@nhom7.com",
        "matKhau": "123456"
    }
    ```
    *(Sử dụng email `ql@nhom7.com` vì đây là data mẫu (seed data) đã có trong database)*
*   **Sau khi gọi thành công:**
    Bạn sẽ nhận được một chuỗi Token (trong trường `token`). Hãy copy chuỗi này.
    *Mẹo Postman:* Bạn có thể vào tab **Tests** của request Login này và dán dòng code sau để tự động lưu Token vào biến môi trường:
    ```javascript
    var jsonData = pm.response.json();
    if(jsonData.token){
        pm.environment.set("token_admin", jsonData.token);
    }
    ```

---

## 3. Cấu hình xác thực cho các API khác (Authorization)

Từ bước này trở đi, cho mọi API bên dưới, bạn **bắt buộc** phải cấu hình Authorization như sau:
1.  Chuyển sang tab **Authorization** của request.
2.  Chọn Type là **Bearer Token**.
3.  Ở ô Token, nhập `{{token_admin}}` (nếu bạn dùng biến môi trường như bước 1) hoặc dán trực tiếp chuỗi Token vừa copy ở bước 2 vào đây.

---

## 4. Hướng dẫn chi tiết từng nhóm API

*(Lưu ý: Thay `http://localhost:3000` bằng port thực tế của bạn nếu khác)*

### 4.1. Quản lý Phim & Lịch chiếu

**A. Gắn Hashtag cho Phim**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/movies/P001/hashtags` *(Thay P001 bằng mã phim)*
*   **Body (raw -> JSON):**
    ```json
    {
        "tenHashTag": "#PhimHayNhat2024"
    }
    ```

**B. Xóa Hashtag khỏi Phim**
*   **Phương thức:** `DELETE`
*   **URL:** `http://localhost:3000/api/admin/movies/P001/hashtags/HT01`

**C. Tạo Lịch chiếu Mới**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/showtimes`
*   **Body (raw -> JSON):**
    ```json
    {
        "maPhim": "P001",
        "maPhong": "PR01",
        "ngayChieu": "2024-05-15",
        "gioChieu": "2024-05-15 19:00:00",
        "giaVe": 120000
    }
    ```
    *(Hệ thống sẽ tự động tính `gioKetThuc = gioChieu + thoiLuong + 15 phút` dựa vào dữ liệu phim)*

### 4.2. Quản lý Phòng Rạp & Ghế

**A. Xem danh sách ghế theo phòng**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/rooms/PR01/seats` *(Thay PR01 bằng mã phòng)*

**B. Cập nhật trạng thái/loại ghế**
*   **Phương thức:** `PUT`
*   **URL:** `http://localhost:3000/api/admin/seats/PR01_A1` *(Thay PR01_A1 bằng mã ghế)*
*   **Body (raw -> JSON):**
    ```json
    {
        "loaiGhe": "hỏng"
    }
    ```
    *(Các giá trị hợp lệ: `normal`, `vip`, `couple`, `hỏng`)*

### 4.3. Quản lý Đồ Ăn, Phụ Kiện (Items) & Combos

**A. Thêm Item (Đồ ăn/Nước)**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/items`
*   **Body (raw -> JSON):**
    ```json
    {
        "name": "Bắp Rang Bơ Phô Mai",
        "item_type": "food",
        "price": 55000,
        "stock_quantity": 100
    }
    ```
    *(item_type chỉ nhận 1 trong 3 giá trị: `food`, `drink`, `accessory`)*

**B. Tạo Combo mới**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/combos`
*   **Body (raw -> JSON):**
    ```json
    {
        "name": "Combo 1 Bắp 2 Nước",
        "price": 99000,
        "description": "Siêu tiết kiệm cho 2 người",
        "items": [
            { "item_id": 1, "quantity": 1 },
            { "item_id": 2, "quantity": 2 }
        ]
    }
    ```

### 4.4. Thống Kê & Báo Cáo

**A. Thống kê vé theo Phim**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/stats/bookings-by-movie`

**B. Doanh thu theo Phim (dựa trên số vé)**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/stats/revenue-by-movie`

**C. Thống kê doanh thu theo ngày**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/stats/daily-revenue?from=2024-04-01&to=2024-04-30`

**D. Xuất Báo cáo XLSX Hàng Tháng**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/reports/monthly?month=2024-04` *(Đổi tháng/năm cho phù hợp với data của bạn)*
*   *Lưu ý Postman:* Để xem file XLSX, nhấn vào nút mũi tên cạnh nút **Send**, chọn **Send and Download**, lưu file ra máy và mở bằng phần mềm như Microsoft Excel hoặc Google Sheets.

### 4.5. Quản lý Khách Hàng, Đơn Vé & Thanh Toán

**A. Danh sách khách hàng**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/customers`

**B. Xem danh sách đơn đặt vé (Đầy đủ chi tiết)**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/bookings`
*   *(Có thể thêm query params: `?movieId=P001` hoặc `?status=paid`)*

**C. Cập nhật trạng thái thanh toán (Cho Quản lý)**
*   **Phương thức:** `PUT`
*   **URL:** `http://localhost:3000/api/admin/payments/PAY123456/status` *(Thay bằng mathanhtoan của đơn)*
*   **Body (raw -> JSON):**
    ```json
    {
        "trangthai": "success"
    }
    ```
    *(Các trạng thái hợp lệ: `success`, `failed`, `pending`. Khi đổi sang `success`, đơn vé sẽ tự động thành `paid`)*

### 4.6. Đánh giá (Bình Luận)

**A. Xem bình luận của một phim**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/movies/P001/reviews`

**B. Nhân viên trả lời bình luận**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/reviews/BL123456/reply` *(Thay BL123456 bằng mã bình luận thực tế lấy được từ API A)*
*   **Body (raw -> JSON):**
    ```json
    {
        "noiDungReply": "Cảm ơn bạn đã ủng hộ rạp chiếu phim của chúng tôi. Hẹn gặp lại bạn lần sau!"
    }
    ```
