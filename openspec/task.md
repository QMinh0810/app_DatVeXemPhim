Danh sách chỉnh sửa:

**C. Tạo Lịch chiếu Mới**
*   **Phương thức:** `POST`
*   **URL:** `http://localhost:3000/api/admin/showtimes`
*   **Body (raw -> JSON):**
    ```json
    {
        "maPhim": "P001",
        "maPhong": "PR01",
        "ngayChieu": "2024-05-15",
        "gioChieu": "2024-05-15 19:00:00",
        "gioKetThuc": "2024-05-15 21:30:00",
        "giaVe": 120000
    }

    --- chỉ chọn ngày giờ bắt đầu, giờ kết thức = thời lượng phim +15 phút

### 4.2. Quản lý Phòng Rạp & Ghế

**A. Tạo lại sơ đồ ghế**
*   **Phương thức:** `PUT`
*   **URL:** `http://localhost:3000/api/admin/rooms/PR01/seats` *(Thay PR01 bằng mã phòng)*
*   **Body (raw -> JSON):**
    ```json
    {
        "soHang": 10,
        "soCot": 12
    }
    ```

    --- bỏ phần tạo lại sơ đồ ghế


    --- Thêm chức năng chỉnh sửa trạng thái ghế theo sơ đồ (Kiểm tra lại xem đã tồn tại chưa)
    - hiện tại tôi đang xem xét ghế theo lịch chiếu đã đặt chưa bằng cách ghép các table lại xem trong lịch chiếu đó, tại phòng đó có tồn tại vé đó chưa, thêm chức năng xử lý việc chỉnh sửa trạng thái ghế ( trống, đã đặt, ghế hỏng (ghế hỏng thì phần loại ghế không còn là normal hay vip nữa mà là hỏng, ghế hỏng thì không thể đặt được))
    --- sửa lại database thêm phần loai_ghe = 'hỏng'

    ### 4.4. Thống Kê & Báo Cáo

**A. Thống kê vé theo Phim**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/stats/bookings-by-movie`

--- yêu cầu gửi: Mã Vé, tên khách hàng, Phim, Ghế, ngày chiếu, tổng tiền, trạng thái, 
--- thêm chức năng thay đổi thông tin thanh toán của user gồm (đã thanh toán/ chờ thanh toán/ đã huỷ) (bên user từng có chức năng xác nhận thanh toán, bỏ nó đi)
--- sửa trên database: thêm trạng thái 'pending' cho thông tin thanh toán
CONSTRAINT
thongtinthanhtoan_trangthai_check
CHECK
(((trangthai)::text = ANY ((ARRAY['success'::character varying, 'failed'::character varying])::text[])))


**B. Doanh thu theo Phim**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/stats/revenue-by-movie`
---sửa lại thay vì dùng số đơn thì dùng số vé để thể hiện chính xác số lượng lượt xem


--- thêm chức năng thống kê doanh thu theo ngày (ngày, tiền bán vé, tiền F&B (tiền thu được từ các combo hoặc các items riêng lẻ), tiền hoàn huỷ vé, doanh thu thực tế)

**C. Xuất Báo cáo PDF Hàng Tháng**
*   **Phương thức:** `GET`
*   **URL:** `http://localhost:3000/api/admin/reports/monthly?month=2024-04` *(Đổi tháng/năm cho phù hợp với data của bạn)*
---xuất báo cáo bỏ phần pdf, xuất bằng xlsx

**B. Cập nhật thông tin khách**
*   **Phương thức:** `PUT`
*   **URL:** `http://localhost:3000/api/admin/customers/1` *(Thay 1 bằng id_khach)*
*   **Body (raw -> JSON):**
    ```json
    {
        "hoTen": "Nguyễn Văn Test Sửa",
        "sdt": "0999888777"
    }
---bỏ chức năng cập nhật thông tin khách của quản lý