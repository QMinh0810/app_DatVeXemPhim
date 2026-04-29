## Context

Ứng dụng đặt vé xem phim Flutter + Node.js/Express + PostgreSQL (Neon). Frontend dùng MVVM với Provider. Tất cả API call qua `ApiService` (static). Backend chưa có endpoint đổi mật khẩu. Thiết kế tham chiếu từ `source_images/ChangePasswordScreen.jpg` và `source_images/MovieInfo.jpg`.

## Goals / Non-Goals

**Goals:**
- Xoá thông tin thừa (mã tài khoản) khỏi UI
- Thêm tìm kiếm/lọc phim phía client (không gọi thêm API)
- Thêm bộ lọc rạp phía client trong showtime screen
- Tạo 2 màn hình mới: đổi mật khẩu, thông tin phim
- Đồng nhất màu ghế không khả dụng thành xám
- Thêm backend endpoint `PUT /api/users/change-password`

**Non-Goals:**
- Không thêm phân trang hay lazy load
- Không thay đổi data model hoặc cấu trúc DB
- Không implement tính năng upload avatar
- Không thêm animation phức tạp

## Decisions

**D1: Tìm kiếm/lọc phim — phía client**
Dùng filter trên `allMovies` đã có trong `MovieViewModel` thay vì gọi `ApiService.searchMovies()`. Lý do: danh sách phim đã load sẵn, tránh network round-trip mỗi khi user gõ.

**D2: `movie_list_screen.dart` — chuyển sang `StatefulWidget`**
Cần state cho `_searchQuery` và `_selectedGenre`. Alternatives: dùng `ValueNotifier` local — không cần thiết, `StatefulWidget` đủ đơn giản.

**D3: Genres trong `MovieModel` hiện tại luôn là `[]`**
Field `genres` trong `MovieModel.fromJson()` trả mảng rỗng (comment "Genres cần JOIN riêng"). Bộ lọc thể loại sẽ collect genres từ dữ liệu thực tế; nếu rỗng sẽ không hiển thị chip filter. Không thay đổi API/model.

**D4: Backend endpoint đổi mật khẩu**
Thêm `PUT /api/users/change-password` vào `userRoutes.js`. Yêu cầu JWT. Verify mật khẩu cũ bằng `bcrypt.compare`, hash mới bằng `bcrypt.hash`, UPDATE vào DB. Trả `{status, message}`.

**D5: `MovieInfoScreen` — nhận `MovieModel` qua constructor**
Truyền `MovieModel` trực tiếp, không cần ViewModel riêng. Thông tin đạo diễn/diễn viên/ngôn ngữ chưa có trong model → hiển thị "Đang cập nhật".

**D6: Màu ghế không khả dụng**
Đổi `_brokenColor` từ `0xFF424242` (xám đen) sang `0xFFBDBDBD` (xám nhạt) để phân biệt rõ với ghế đã đặt (`0xFF9E9E9E`). Cả ghế hỏng lẫn ghế synthetic (không trong DB) đều dùng màu này vì `getSeatAt()` đã trả `loaighe: 'hỏng'` cho vị trí không tồn tại.

## Risks / Trade-offs

- **[Risk] Genres rỗng → filter thể loại không hoạt động** → Mitigation: Ẩn filter chip nếu không có genre nào. Ghi note để sau này fix API join genres.
*thể loại đang được nối trong table phim_theloai, cần update lại API movie để join table này
- **[Risk] `MovieInfoScreen` thiếu data (đạo diễn, diễn viên)** → Mitigation: Hiển thị placeholder "Đang cập nhật", không crash.
*Thông tin đạo diễn/diễn viên cần được lưu trong table Phim_daoDien/Phim_dienVien , kiểm tra lại phần này

-trong UI chi tiết phim, thêm phần thông tin đạo diễn và diễn viên vào,lấy thông tin đạo diễn/diễn viên từ table Phim_dienVien thông qua API movie, đồng thời thêm cả thể loại phim vào qua table phim_theloai giống ở trên
- sửa UI chi tiết phim, poster phim hiện tại đổi thành trailer (lấy url từ API)
. đọc lại ảnh trong source_images/MovieInfo.jpg để nắm lại design: để poster thành 1 ảnh nhỏ ở góc trên bên trái, bên phải nó là ngày ra mắt (ngayramat trong table phim) + thời lượng phim (thoiLuong trong table phim nhưng được đổi sang giờ + phút -- trong database chỉ có số phút) , khi bấm vào trailer gọi api youtube để hiện trailer 


- sửa UI thông tin thanh toán ( payment_screen.dart) phần thông tin số ghế đổi từ mã ghế sang số ghế (Ví dụ: A1,A2,A3...), tương tự trong UI vé của tôi (my_tickets_screen.dart) cũng đổi số ghế từ mã ghế sang số ghế (Ví dụ: A1,A2,A3...)

- trong UI chọn ghế (seat_selection_screen.dart) chỉnh lai UI hiển thị ghế, khoá sao cho kích thước của các ô ghế là giống nhau, hiện tại các ghế thường vì không có kí hiêu trái tim ( ghế couple) và hình ngôi sao (ghế VIP) nên nó bị méo, cần chỉnh sửa lại cho cân đối

- trongUI home_screen.dart lấy lại logic API của phim đang chiếu cũ, sau khi sửa ban nãy thì các phần phim đang chiếu đã mất (trạng thái now_showing trong datbase)


