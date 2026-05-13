# Hệ Thống Đặt Vé Xem Phim Real-time (Flutter & Node.js)

Hệ thống hỗ trợ đặt vé xem phim trực tuyến với tính năng **giữ ghế thời gian thực (Real-time Seat Locking)**, tích hợp thanh toán MoMo, VNPay và thông báo qua Email.

---

## 🛠 Yêu Cầu Hệ Thống

### Môi trường phát triển
*   **Flutter SDK**: ^3.0.0
*   **Node.js**: ^18.0.0 (Ưu tiên bản LTS)
*   **PostgreSQL**: Cơ sở dữ liệu chính (Sử dụng Neon.tech hoặc Local)
*   **Redis (Upstash)**: Quản lý lock ghế và session tạm
*   **ngrok**: Dùng để công khai Server Local ra Internet (cần thiết cho thanh toán MoMo/VNPay)

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Dự Án

Dự án này đã bao gồm file cấu hình môi trường `.env`, bạn có thể chạy ngay sau khi cài đặt các thư viện cần thiết.

### 1. Cấu hình ngrok (Bắt buộc cho thanh toán)
Để nhận được phản hồi từ MoMo/VNPay về máy tính của bạn, bạn cần ngrok:
1.  Tải ngrok tại [ngrok.com](https://ngrok.com/download) và đăng ký tài khoản miễn phí.
2.  Chạy lệnh sau để mở cổng 3000:
    ```powershell
    ngrok http 3000
    ```
3.  Copy địa chỉ `https://...ngrok-free.dev` vừa hiện ra để cập nhật vào các bước tiếp theo.

### 2. Thiết lập Backend (Node.js)
Dự án **không** bao gồm thư mục `node_modules`. Bạn cần chạy lệnh sau để tự động cài đặt tất cả các thư viện cần thiết (như `nodemon`, `axios`, `vnpay`, `socket.io`,...):
```powershell
cd backend
npm install
```

**Cấu hình .env**:
File `backend/.env` đã có sẵn các cấu hình Sandbox cho MoMo, VNPay và Redis. 
> [!IMPORTANT]
> Nếu bạn thay đổi địa chỉ Ngrok, bạn phải cập nhật lại các biến `VNP_RETURN_URL`, `MOMO_REDIRECT_URL` và `MOMO_IPN_URL` trong file này để nhận được kết quả thanh toán.

### 2. Thiết lập Frontend (Flutter)
Tải các gói thư viện Flutter:
```powershell
flutter pub get
```

**Lưu ý về Máy ảo (Emulator)**:
Nếu máy ảo chạy chậm hoặc bị lỗi kết nối, hãy chạy App bằng lệnh tắt engine đồ họa Impeller:
```powershell
flutter run --no-impeller
```

---

## 📖 Tính Năng Real-time (Socket.IO + Redis)

*   **Cơ chế Lock ghế**: Khi User chọn ghế, một khóa tạm thời (TTL 5 phút) được tạo trên Redis. 
*   **Đồng bộ tức thì**: Trạng thái ghế (Màu xanh: của bạn, Màu cam: người khác đang giữ) được cập nhật tới tất cả thiết bị qua Socket.IO.
*   **Giới hạn đặt vé**: Mỗi tài khoản chỉ được giữ tối đa **6 ghế** trong một lần giao dịch.
*   **An toàn thanh toán**: Nếu người dùng thoát App để mở ví MoMo/VNPay, ghế vẫn được giữ an toàn nhờ cơ chế kiểm tra Session Active.

---

## 🛠 Cách Chạy Toàn Bộ Hệ Thống

1.  **Khởi động Backend**:
    ```powershell
    cd backend
    npm run dev
    ```
2.  **Khởi động App**:
    ```powershell
    flutter run
    ```
    *(Hoặc F5 trong VS Code)*

---

## ⚠️ Lưu Ý Bảo Mật
Dự án hiện đang chứa thông tin `JWT_SECRET` và các `API Key` thanh toán trong file `.env` được đẩy lên Git. 
*   **Với mục đích học tập**: Bạn có thể sử dụng ngay các tài khoản Sandbox có sẵn.
*   **Với mục đích thực tế**: **BẮT BUỘC** phải đưa `.env` vào `.gitignore` và thay thế bằng các Key thật có bảo mật cao.

---

## 📦 Danh Sách Thư Viện Chính
*   **Backend**: `express`, `socket.io`, `ioredis`, `pg`, `jsonwebtoken`, `vnpay`.
*   **Frontend**: `provider`, `socket_io_client`, `http`, `google_sign_in`, `url_launcher`.
