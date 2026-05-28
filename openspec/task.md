[Thay Đổi Kiến Trúc]
LUỒNG CŨ (Hiện tại)
QR Code
   ↓
Chứa toàn bộ dữ liệu JSON của vé
   ↓
Scanner đọc và parse JSON trực tiếp
   ↓
Hiển thị thông tin vé
LUỒNG MỚI (Chuyên nghiệp như CGV)
QR Code
   ↓
Chỉ chứa ticketCode hoặc token bảo mật
   ↓
Scanner quét mã
   ↓
Gọi API backend
   ↓
Backend kiểm tra vé
   ↓
Trả về đầy đủ thông tin vé
   ↓
Hiển thị giao diện vé đẹp
[Thay Đổi Backend]
[CHỈNH SỬA] bookingController.js
Thay đổi cách tạo QR Code
CŨ
qrData = JSON.stringify({
  movieName,
  seat,
  room,
  showtime
})
MỚI

QR chỉ chứa:

ticketCode

Ví dụ:

VE24780

hoặc token bảo mật:

8fd2a91bc7e1
[THÊM MỚI] API kiểm tra vé
API mới
GET /api/tickets/scan/:ticketCode
Chức năng
Tìm vé theo ticketCode
Kiểm tra:
vé có tồn tại không
đã thanh toán chưa
hết hạn chưa
đã sử dụng chưa
Trả về đầy đủ thông tin vé
Ví dụ response
{
  "success": true,
  "ticket": {
    "movieName": "Avengers",
    "cinema": "CGV AEON",
    "date": "2026-05-24",
    "time": "19:30",
    "room": "Room 5",
    "seat": "B7",
    "ticketCode": "VE24780"
  }
}
[CHỈNH SỬA] getTicketByQRCode
CŨ
Đọc dữ liệu JSON từ QR
MỚI
Nhận ticketCode/token từ QR
Kiểm tra dữ liệu trong database
Trả về thông tin vé
[Thay Đổi Flutter App]
[CHỈNH SỬA] pubspec.yaml

Thêm package:

mobile_scanner: ^5.0.0
Có thể thêm để UI đẹp hơn
flutter_animate:
google_fonts:
[THÊM MỚI] scanner_screen.dart
Chức năng

Tạo màn hình quét QR chuyên nghiệp.

Giao diện scanner

Bao gồm:

nền tối
khung quét ở giữa
animation scan line
nút bật flash
rung khi quét thành công
Luồng mới
CŨ
Quét QR
   ↓
Đọc JSON trực tiếp
MỚI
Quét QR
   ↓
Lấy ticketCode/token
   ↓
Gọi ApiService.scanTicket()
   ↓
Nhận dữ liệu từ backend
   ↓
Mở TicketDetailScreen
Ví dụ logic
final code = barcode.rawValue;

final response = await ApiService.scanTicket(code);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => TicketDetailScreen(
      ticket: response.ticket,
    ),
  ),
);
[CHỈNH SỬA] api_service.dart
Thêm API mới
scanTicket(String ticketCode)
API gọi tới
GET /api/tickets/scan/{ticketCode}
[CHỈNH SỬA] ticket_detail_screen.dart
THIẾT KẾ LẠI TOÀN BỘ UI

Mục tiêu:
Giao diện giống:

CGV
Galaxy Cinema
Tix
Cinepolis
Cấu trúc UI
Background
#121212
Card vé chính
Thẻ màu trắng bo góc

Bao gồm:

bo góc lớn
hiệu ứng lỗ xé 2 bên
shadow nhẹ
animation mượt
Phần trên cùng
Tên phim lớn

Ví dụ:

AVENGERS: ENDGAME

Style:

in hoa
chữ đậm
phong cách điện ảnh
Badge tên rạp

Ví dụ:

CGV AEON MALL

Thiết kế badge đỏ dạng pill.

Grid thông tin vé

Bao gồm:

Ngày
Giờ
Phòng
Ghế
Mã vé

Ví dụ:

DATE    24 MAY
TIME    19:30
ROOM    5
SEAT    B7
Phần QR phía dưới

Hiển thị:

ảnh QR
ticketCode phía dưới QR
Hỗ trợ trạng thái vé

Các trạng thái:

VALID
USED
EXPIRED
CANCELLED

Màu:

xanh lá
đỏ
xám
[CHỈNH SỬA] custom_app_bar.dart
Thêm nút Scan QR

Đi tới:

ScannerScreen()

Có thể dùng:

icon scan góc phải
floating button
[Cải Thiện Bảo Mật]
KHÔNG lưu toàn bộ dữ liệu trong QR

Lý do:

dễ fake
dễ sửa
không an toàn
khó mở rộng
Nội dung QR nên chứa
Khuyên dùng
ticketCode
Tốt hơn
token mã hóa / UUID

Ví dụ:

a8f91cd2-7b33-41b1-a0a1
[Tính Năng Có Thể Nâng Cấp Sau]

Có thể thêm:

check-in realtime
chống quét nhiều lần
cache offline
Apple Wallet / Google Wallet
QR động
token hết hạn
[Kế Hoạch Kiểm Thử]
Kiểm tra màn hình vé
mở vé có sẵn
kiểm tra UI hiển thị
Kiểm tra scanner
quét QR hợp lệ
gọi backend
mở TicketDetailScreen
Vé không hợp lệ

Hiển thị:

Invalid ticket
Vé đã dùng

Hiển thị:

Ticket already used
Kết Luận

Nên dùng mô hình:

QR → ticketCode/token → API → lấy dữ liệu → render UI

Vì:

giống hệ thống CGV thực tế
bảo mật hơn
chuyên nghiệp hơn
dễ mở rộng sau này.

tóm tắt:
QR Code
   ↓
Chỉ chứa ticketCode hoặc token bảo mật
   ↓
Scanner quét mã
   ↓
Gọi API backend
   ↓
Backend kiểm tra vé
   ↓
Trả về đầy đủ thông tin vé
   ↓
Hiển thị giao diện vé đẹp