lên kế hoạch chi tiết để phát triển tính năng sau:
- cập nhật API  hiển thị thêm ảnh đại diện của diễn viên, đạo diễn trong phần chi tiết phim (dùng url trong database) (hiện tại đã hiển thị tên, có khung ảnh nhưng chưa gọi ảnh, cần lưu ý hiển thị đúng tên diễn viên, đạo diễn ứng với mã của họ)
- tạo API xử lý đặt combo, lưu combo đồ ăn đặt vào table order_concessions
- tạo API xử lý đổ thông tin các combo vào combo_selection_screen, thông tin hiển thị gồm tên combo, giá tiền, description (mô tả), sô lượng lựa chọn( đã có UI, có thể đọc UI để biết UI nó hiện gì) 
- xử lý để hiển thị đúng danh sách các combo đồ ăn đã chọn và đúng số tiền đã chọn trong combo
- đổi workflow đặt vé: từ chọn lịch chiếu --> chọn ghế --> thanh toán thành
    chọn lịch chiếu --> chọn ghế --> chọn combo đồ ăn --> thanh toán
đã có screen chọn combo đồ ăn là combo_selection_screen
- tích hợp API đặt combo đồ ăn vào
- chỉnh sửa table thongtintaikhoan, thêm cột trangthai, active và disable, chỉnh sửa logic để phần auth các tài khoản bị disable không thể đăng nhập hay quên mật khẩu


