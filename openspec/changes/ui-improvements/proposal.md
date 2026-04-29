## Why

Giao diện người dùng hiện tại hiển thị một số thông tin thừa (mã tài khoản), thiếu tính năng lọc/tìm kiếm phim, và còn thiếu các màn hình quan trọng (đổi mật khẩu, thông tin phim chi tiết). Cần chuẩn hóa UI theo đúng bản thiết kế đã duyệt và cải thiện trải nghiệm người dùng.

## What Changes

- Bỏ hiển thị "Mã tài khoản" khỏi label đăng nhập (`login_screen.dart`) và trang thông tin tài khoản (`account_info_screen.dart`)
- Khoá các trường SĐT và Email trong trang thông tin tài khoản (không cho phép sửa)
- Thêm thanh tìm kiếm và bộ lọc thể loại vào màn hình danh sách phim (`movie_list_screen.dart`)
- Thêm bộ lọc theo rạp vào màn hình chọn suất chiếu (`showtime_screen.dart`)
- Tạo mới màn hình đổi mật khẩu theo thiết kế (`ChangePasswordScreen.jpg`)
- Tạo mới màn hình thông tin phim chi tiết theo thiết kế (`MovieInfo.jpg`)
- Sửa màu ghế không khả dụng (hỏng/không tồn tại trong DB) thành màu xám đồng nhất trong sơ đồ ghế
- Thêm backend API endpoint đổi mật khẩu (`PUT /api/users/change-password`)

## Capabilities

### New Capabilities

- `change-password`: Màn hình đổi mật khẩu với 3 trường (mật khẩu cũ, mới, xác nhận) và API backend tương ứng
- `movie-info`: Màn hình thông tin chi tiết phim với banner, mô tả, bảng metadata và nút đặt vé
- `movie-search-filter`: Tìm kiếm phim theo tên và lọc theo thể loại trong danh sách phim
- `showtime-theater-filter`: Bộ lọc theo rạp trong màn hình chọn suất chiếu

### Modified Capabilities

<!-- Không có thay đổi requirements cấp spec cho các capability hiện tại -->

## Impact

- **Flutter screens**: `login_screen.dart`, `account_info_screen.dart`, `movie_list_screen.dart`, `showtime_screen.dart`, `seat_selection_screen.dart`, `profile_screen.dart`
- **Flutter screens mới**: `change_password_screen.dart`, `movie_info_screen.dart`
- **Flutter widgets**: `movie_card.dart` (thêm navigate to movie info)
- **Backend**: `backend/routes/userRoutes.js`, `backend/controllers/userController.js` (thêm endpoint change-password)
- **API service**: `lib/services/api_service.dart` (thêm method `changePassword`)
