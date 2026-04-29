## ADDED Requirements

### Requirement: Bộ lọc rạp trong màn hình chọn suất chiếu
Hệ thống SHALL cung cấp bộ lọc dạng chip ngang trong ShowtimeScreen để lọc suất chiếu theo rạp phim, phía client dựa trên dữ liệu đã tải.

#### Scenario: Hiển thị danh sách rạp
- **WHEN** danh sách suất chiếu được tải thành công
- **THEN** hệ thống hiển thị hàng chip gồm "Tất cả" và tên các rạp có suất chiếu (không trùng lặp)

#### Scenario: Chọn lọc theo rạp
- **WHEN** user nhấn vào chip tên rạp
- **THEN** hệ thống chỉ hiển thị suất chiếu của rạp đó

#### Scenario: Bỏ chọn rạp
- **WHEN** user nhấn chip "Tất cả"
- **THEN** hệ thống hiển thị tất cả suất chiếu

#### Scenario: Chỉ có một rạp
- **WHEN** tất cả suất chiếu đều ở cùng một rạp
- **THEN** hệ thống vẫn hiển thị chip filter (có "Tất cả" và tên rạp đó) để nhất quán UI
