## ADDED Requirements

### Requirement: Tìm kiếm phim theo tên
Hệ thống SHALL cung cấp ô tìm kiếm trong MovieListScreen để lọc danh sách phim theo tên (case-insensitive, phía client).

#### Scenario: Tìm kiếm ra kết quả
- **WHEN** user nhập từ khoá vào ô tìm kiếm
- **THEN** hệ thống lọc và hiển thị các phim có tên chứa từ khoá đó

#### Scenario: Tìm kiếm không có kết quả
- **WHEN** user nhập từ khoá không khớp bất kỳ phim nào
- **THEN** hệ thống hiển thị thông báo "Không tìm thấy phim nào"

#### Scenario: Xoá tìm kiếm
- **WHEN** user xoá hết nội dung ô tìm kiếm
- **THEN** hệ thống hiển thị lại toàn bộ danh sách phim

### Requirement: Lọc phim theo thể loại
Hệ thống SHALL cung cấp bộ lọc dạng chip ngang trong MovieListScreen để lọc phim theo thể loại, chỉ hiển thị khi có dữ liệu thể loại.

#### Scenario: Chọn thể loại
- **WHEN** user nhấn vào một chip thể loại
- **THEN** hệ thống hiển thị chỉ những phim thuộc thể loại đó (kết hợp với từ khoá tìm kiếm nếu có)

#### Scenario: Bỏ chọn thể loại
- **WHEN** user nhấn lại vào chip thể loại đang chọn hoặc nhấn "Tất cả"
- **THEN** hệ thống bỏ filter thể loại và hiển thị tất cả phim (vẫn giữ từ khoá tìm kiếm)

#### Scenario: Không có dữ liệu thể loại
- **WHEN** tất cả phim đều có `genres` rỗng
- **THEN** hệ thống ẩn hàng chip thể loại, không crash
