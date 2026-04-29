## ADDED Requirements

### Requirement: Màn hình thông tin phim chi tiết
Hệ thống SHALL cung cấp màn hình `MovieInfoScreen` hiển thị thông tin đầy đủ của một bộ phim, thiết kế theo `source_images/MovieInfo.jpg`: banner ảnh phim full-width với nút play, overlay poster nhỏ + tên phim, ngày chiếu, thời lượng, mô tả (truncatable), bảng metadata, và nút "ĐẶT VÉ" cố định ở dưới.

#### Scenario: Điều hướng từ danh sách phim
- **WHEN** user nhấn vào poster/tên phim trong MovieListScreen hoặc MovieCard
- **THEN** hệ thống điều hướng đến MovieInfoScreen với MovieModel được truyền vào

#### Scenario: Hiển thị thông tin cơ bản
- **WHEN** MovieInfoScreen được mở
- **THEN** hệ thống hiển thị: banner ảnh phim, tên phim, ngày ra mắt (format dd/mm/yyyy), thời lượng (N giờ M phút), mô tả phim, kiểm duyệt (T16/T18/P), thể loại

#### Scenario: Mở rộng mô tả
- **WHEN** user nhấn "Chi tiết" trong phần mô tả
- **THEN** hệ thống hiển thị toàn bộ nội dung mô tả thay vì bị cắt ngắn

#### Scenario: Thông tin chưa có
- **WHEN** MovieModel không có thông tin đạo diễn/diễn viên/ngôn ngữ
- **THEN** hệ thống hiển thị "Đang cập nhật" thay vì crash hoặc để trống

#### Scenario: Đặt vé từ màn hình thông tin phim
- **WHEN** user nhấn nút "ĐẶT VÉ" ở cuối màn hình
- **THEN** hệ thống gọi `BookingViewModel.selectMovie(movie)` và điều hướng đến ShowtimeScreen
