## ADDED Requirements

### Requirement: Màn hình đổi mật khẩu
Hệ thống SHALL cung cấp màn hình đổi mật khẩu với 3 trường nhập liệu (mật khẩu hiện tại, mật khẩu mới, xác nhận mật khẩu mới) và nút "THAY ĐỔI MẬT KHẨU". Thiết kế theo `source_images/ChangePasswordScreen.jpg`: nền trắng, border dạng underline, icon eye toggle cho mỗi trường.

#### Scenario: Hiển thị màn hình
- **WHEN** user nhấn "Thay đổi mật khẩu" từ ProfileScreen
- **THEN** hệ thống điều hướng đến ChangePasswordScreen với AppBar tiêu đề "Thay đổi mật khẩu"

#### Scenario: Đổi mật khẩu thành công
- **WHEN** user nhập đúng mật khẩu hiện tại, mật khẩu mới hợp lệ, xác nhận khớp, và nhấn nút
- **THEN** hệ thống gọi API `PUT /api/users/change-password`, hiển thị SnackBar thành công và quay về màn hình trước

#### Scenario: Mật khẩu xác nhận không khớp
- **WHEN** user nhập mật khẩu mới và xác nhận không giống nhau
- **THEN** hệ thống hiển thị thông báo lỗi "Mật khẩu xác nhận không khớp" mà không gọi API

#### Scenario: Mật khẩu hiện tại sai
- **WHEN** API trả về lỗi xác thực mật khẩu cũ
- **THEN** hệ thống hiển thị SnackBar lỗi với thông báo từ server

### Requirement: API backend đổi mật khẩu
Backend SHALL cung cấp endpoint `PUT /api/users/change-password` yêu cầu JWT, nhận `{oldPassword, newPassword}`, verify mật khẩu cũ với bcrypt, hash mật khẩu mới và cập nhật DB.

#### Scenario: Đổi mật khẩu thành công phía server
- **WHEN** request hợp lệ với JWT đúng và oldPassword khớp
- **THEN** server cập nhật mật khẩu và trả `{status: "success", message: "Đổi mật khẩu thành công"}`

#### Scenario: Mật khẩu cũ không đúng
- **WHEN** oldPassword không khớp với hash trong DB
- **THEN** server trả HTTP 400 `{status: "error", message: "Mật khẩu hiện tại không đúng"}`
