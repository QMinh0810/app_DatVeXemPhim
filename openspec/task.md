1. Trong seat_selection_screen.dart: hiển thị đầy đủ số ghế mặc định (12 hàng 8 cột, 6 hàng ghế thường, 2 hàng couple và 2 hàng vip ), những ghế không tồn tại trong database thì để màu xám đen (ghế hỏng)
2. Trong màn hình chính, sửa sử dụng hình google_logo.png trong folder lib/images/  làm icon cho nút đăng nhập bằng google
3. Nút đăng nhập bằng google trong màn hình login hiện tại bị lỗi, nhấn vào hiển thị thông báo "Lỗi kết nối tới google login"
4. Kiểm tra lại controller gọi api register, hiện tại dù hiện đăng ký thành công nhưng không gọi API, neon không nhận được thông tin gì dù test postman thì bình thường
5. Xoá data fake được mock trong phần thông báo
