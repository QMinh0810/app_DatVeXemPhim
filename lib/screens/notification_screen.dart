import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data mapped from ThongBao SQL table
    final List<Map<String, dynamic>> notifications = [
      {
        'tieuDe': 'Đặt vé thành công!',
        'noiDung': 'Đơn hàng DUNE: HÀNH TINH CÁT 2 (Ghế F3, F4) đã thanh toán hoàn tất. Mã QR đã được gửi về ví.',
        'thoiDiemTB': '10/04/2024 10:15',
        'daXem': false,
        'icon': Icons.check_circle,
        'color': Colors.green,
      },
      {
        'tieuDe': 'Phim mới ra mắt: KUNG FU PANDA 4',
        'noiDung': 'Siêu phẩm hoạt hình Kung Fu Panda phần 4 đã chính thức khởi chiếu tại các rạp.',
        'thoiDiemTB': '08/03/2024 09:00',
        'daXem': true,
        'icon': Icons.movie,
        'color': const Color(0xFFE51937),
      },
      {
        'tieuDe': 'Ưu đãi giá vé VIP',
        'noiDung': 'Giảm ngay 20% khi mua ghế VIP qua ví VNPay từ đây đến cuối tháng.',
        'thoiDiemTB': '01/03/2024 15:30',
        'daXem': true,
        'icon': Icons.local_offer,
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộp Thư / Thông Báo', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return Container(
            color: notif['daXem'] ? Colors.white : Colors.blue.withValues(alpha: 0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: (notif['color'] as Color).withValues(alpha: 0.2),
                  child: Icon(notif['icon'] as IconData, color: notif['color'] as Color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notif['tieuDe'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: notif['daXem'] ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['noiDung'],
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['thoiDiemTB'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
