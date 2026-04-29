## 1. Dọn dẹp UI thông tin tài khoản & đăng nhập

- [x] 1.1 Sửa `login_screen.dart`: đổi label "Mã tài khoản / SĐT / Email" → "SĐT / Email"
- [x] 1.2 Sửa `account_info_screen.dart`: xoá khối "MÃ TÀI KHOẢN" (field `_maTaiKhoan`, title, TextFormField)
- [x] 1.3 Sửa `account_info_screen.dart`: khoá readOnly cho trường SĐT và Email, xoá 2 field này khỏi payload `updateProfile`

## 2. Sửa màu ghế không khả dụng

- [x] 2.1 Sửa `seat_selection_screen.dart`: đổi `_brokenColor` từ `0xFF424242` → `0xFFBDBDBD`
- [x] 2.2 Sửa `seat_selection_screen.dart`: cập nhật legend "Hỏng" → "Không khả dụng"

## 3. Bộ lọc rạp trong ShowtimeScreen

- [x] 3.1 Sửa `showtime_screen.dart`: thêm state `_selectedTheater` và collect danh sách rạp từ `_showtimes`
- [x] 3.2 Sửa `showtime_screen.dart`: thêm hàng filter chip "Tất cả" + tên các rạp phía trên list suất chiếu
- [x] 3.3 Sửa `showtime_screen.dart`: áp dụng filter cho ListView dựa trên `_selectedTheater`

## 4. Tìm kiếm & lọc thể loại trong MovieListScreen

- [x] 4.1 Chuyển `movie_list_screen.dart` từ `StatelessWidget` → `StatefulWidget`
- [x] 4.2 Thêm `TextEditingController _searchController` và state `String? _selectedGenre`
- [x] 4.3 Thêm thanh tìm kiếm (TextField với icon search/clear) phía trên danh sách
- [x] 4.4 Thêm hàng chip lọc thể loại (ScrollView ngang), ẩn nếu không có genres
- [x] 4.5 Áp dụng logic filter: lọc `allMovies` theo query và genre, hiển thị "Không tìm thấy" nếu rỗng

## 5. Backend API đổi mật khẩu

- [x] 5.1 Thêm hàm `changePassword` vào `backend/controllers/userController.js`
- [x] 5.2 Thêm route `router.put('/change-password', verifyToken, userController.changePassword)` vào `backend/routes/userRoutes.js`
- [x] 5.3 Thêm method `ApiService.changePassword(oldPassword, newPassword)` vào `lib/services/api_service.dart`

## 6. Màn hình đổi mật khẩu (Flutter)

- [x] 6.1 Tạo file `lib/screens/change_password_screen.dart` với UI theo `ChangePasswordScreen.jpg`
- [x] 6.2 Kết nối nút "Thay đổi mật khẩu" trong `profile_screen.dart` navigate đến `ChangePasswordScreen`

## 7. Màn hình thông tin phim chi tiết (Flutter)

- [x] 7.1 Tạo file `lib/screens/movie_info_screen.dart` với UI theo `MovieInfo.jpg`
- [x] 7.2 Sửa `movie_list_screen.dart`: thêm điều hướng từ tên/poster phim đến `MovieInfoScreen`
- [x] 7.3 Sửa `lib/widgets/movie_card.dart`: thêm điều hướng đến `MovieInfoScreen` khi nhấn vào card

## 8. Sửa lỗi hiển thị Phim Hot
- [x] 8.1 Sửa typo `now_showing` thành `showing` trong `movieController.js`
- [x] 8.2 Sửa typo `now_showing` thành `showing` trong `movie_viewmodel.dart`
