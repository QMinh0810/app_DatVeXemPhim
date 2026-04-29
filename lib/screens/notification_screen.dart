import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hộp Thư / Thông Báo', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'Bạn chưa có thông báo nào',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.separated(
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
