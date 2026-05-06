import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../models/notification_model.dart';
import 'transaction_history_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationViewModel>().loadNotifications();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  IconData _getIcon(String tieuDe) {
    if (tieuDe.contains('Thanh toán') || tieuDe.contains('xác nhận')) return Icons.check_circle_outline;
    if (tieuDe.contains('Đặt vé')) return Icons.confirmation_number_outlined;
    return Icons.notifications_outlined;
  }

  Color _getIconColor(String tieuDe) {
    if (tieuDe.contains('Thanh toán') || tieuDe.contains('xác nhận')) return Colors.green;
    if (tieuDe.contains('Đặt vé')) return const Color(0xFFE51937);
    return Colors.blueAccent;
  }

  void _onTapNotification(BuildContext context, NotificationModel notif) {
    // Đánh dấu đã đọc
    context.read<NotificationViewModel>().markAsRead(notif.maThongBao);

    // Deep link: nếu có đơn hàng → chuyển sang màn hình lịch sử
    if (notif.maDonDatVe != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
      );
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa tất cả?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tất cả thông báo sẽ bị xóa vĩnh viễn. Bạn có chắc không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa hết', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<NotificationViewModel>().deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationViewModel>(
      builder: (context, notifVM, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thông Báo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                if (notifVM.unreadCount > 0)
                  Text('${notifVM.unreadCount} chưa đọc', style: const TextStyle(color: Color(0xFFE51937), fontSize: 12)),
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              if (notifVM.notifications.isNotEmpty) ...[
                // Đánh dấu tất cả đã đọc
                TextButton(
                  onPressed: () => notifVM.markAllAsRead(),
                  child: const Text('Đọc hết', style: TextStyle(color: Color(0xFFE51937), fontSize: 13)),
                ),
                // Xóa tất cả
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.black54),
                  tooltip: 'Xóa tất cả',
                  onPressed: () => _confirmDeleteAll(context),
                ),
              ],
            ],
          ),
          body: notifVM.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE51937)))
              : notifVM.errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(notifVM.errorMessage!, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => notifVM.loadNotifications(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE51937)),
                          ),
                        ],
                      ),
                    )
                  : notifVM.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Bạn chưa có thông báo nào', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFE51937),
                          onRefresh: () => notifVM.loadNotifications(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: notifVM.notifications.length,
                            separatorBuilder: (context2, idx2) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final notif = notifVM.notifications[index];
                              final iconColor = _getIconColor(notif.tieuDe);
                              return Dismissible(
                                key: Key(notif.maThongBao),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                                ),
                                onDismissed: (_) => notifVM.deleteNotification(notif.maThongBao),
                                child: GestureDetector(
                                  onTap: () => _onTapNotification(context, notif),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: notif.isUnread
                                          ? const Color(0xFFE51937).withValues(alpha: 0.04)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Icon / Poster
                                          Container(
                                            width: 46,
                                            height: 46,
                                            decoration: BoxDecoration(
                                              color: iconColor.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: notif.posterUrl != null && notif.posterUrl!.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.network(
                                                      notif.posterUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, e, s) => Icon(_getIcon(notif.tieuDe), color: iconColor, size: 24),
                                                    ),
                                                  )
                                                : Icon(_getIcon(notif.tieuDe), color: iconColor, size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          // Content
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notif.tieuDe,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: notif.isUnread ? FontWeight.bold : FontWeight.w500,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                    ),
                                                    // Chấm đỏ nếu chưa đọc
                                                    if (notif.isUnread)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFE51937),
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notif.noiDung,
                                                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _formatTime(notif.thoiDiemTB),
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        );
      },
    );
  }
}
