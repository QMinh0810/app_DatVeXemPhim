1. sửa lại UI seat_selection_screen.dart trong phần chọn ghế, lấy lai UI cũ, thêm phần lối đi ở giữa và và nối các ghế trong hàng có ghế đôi
2. trong UI forgot_password_screen.dart
- thêm 1 ô cho phép nhập mã otp, ô này nhỏ hơn ô nhập email, bên trái ô nhập otp có 1 nút 'Gửi mã OTP', gán API forgot_password  cho nút 'Gửi mã OTP'
- thêm nút xác nhận OTP, điền API xác nhận quên mật khẩu /auth/reset-password nhưng gửi mật khẩu là 1 ký tự '9' là được, nếu OTP sai thì thông báo, nếu đúng thì chuyển sang trang đổi mật khẩu với tokken ID của tài khoản email đó (lên kế hoạch chi tiết cho phần này) 