import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationViewModel extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollTimer;
  int _lastKnownUnreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Gọi khi user đăng nhập - bắt đầu poll badge count mỗi 30s
  void startPolling() {
    refreshUnreadCount();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshUnreadCount();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  // =====================================================
  // Làm mới badge số thông báo chưa đọc (nhẹ, không reload list)
  // =====================================================
  Future<void> refreshUnreadCount() async {
    try {
      final count = await ApiService.getUnreadCount();
      // Nếu có thông báo mới → rung chuông
      if (count > _lastKnownUnreadCount && _lastKnownUnreadCount >= 0) {
        _triggerVibration();
      }
      _lastKnownUnreadCount = count;
      _unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Bỏ qua lỗi poll nền - không làm ảnh hưởng UX
    }
  }

  // =====================================================
  // Tải toàn bộ danh sách thông báo (khi mở màn hình)
  // =====================================================
  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final raw = await ApiService.fetchNotifications();
      _notifications = raw
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
      _unreadCount = _notifications.where((n) => n.isUnread).length;
      _lastKnownUnreadCount = _unreadCount;
    } catch (e) {
      _errorMessage = 'Không thể tải thông báo. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // =====================================================
  // Đánh dấu một thông báo đã đọc
  // =====================================================
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.maThongBao == id);
    if (idx == -1 || !_notifications[idx].isUnread) return;

    // Optimistic update
    _notifications[idx] = NotificationModel(
      maThongBao: _notifications[idx].maThongBao,
      tieuDe: _notifications[idx].tieuDe,
      noiDung: _notifications[idx].noiDung,
      trangThai: 'read',
      thoiDiemTB: _notifications[idx].thoiDiemTB,
      maDonDatVe: _notifications[idx].maDonDatVe,
      maPhim: _notifications[idx].maPhim,
      tenPhim: _notifications[idx].tenPhim,
      posterUrl: _notifications[idx].posterUrl,
    );
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await ApiService.markNotificationAsRead(id);
    } catch (_) {
      // Nếu API lỗi, reload lại để đồng bộ
      await loadNotifications();
    }
  }

  // =====================================================
  // Đánh dấu tất cả đã đọc
  // =====================================================
  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      _notifications = _notifications.map((n) => NotificationModel(
        maThongBao: n.maThongBao,
        tieuDe: n.tieuDe,
        noiDung: n.noiDung,
        trangThai: 'read',
        thoiDiemTB: n.thoiDiemTB,
        maDonDatVe: n.maDonDatVe,
        maPhim: n.maPhim,
        tenPhim: n.tenPhim,
        posterUrl: n.posterUrl,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // =====================================================
  // Xóa một thông báo
  // =====================================================
  Future<void> deleteNotification(String id) async {
    final removed = _notifications.firstWhere(
      (n) => n.maThongBao == id,
      orElse: () => NotificationModel(
        maThongBao: '',
        tieuDe: '',
        noiDung: '',
        trangThai: 'read',
        thoiDiemTB: DateTime.now(),
      ),
    );

    _notifications.removeWhere((n) => n.maThongBao == id);
    if (removed.isUnread && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await ApiService.deleteNotification(id);
    } catch (_) {
      await loadNotifications();
    }
  }

  // =====================================================
  // Xóa tất cả thông báo
  // =====================================================
  Future<void> deleteAll() async {
    try {
      await ApiService.deleteAllNotifications();
      _notifications = [];
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  // =====================================================
  // Rung chuông khi có thông báo mới
  // =====================================================
  Future<void> _triggerVibration() async {
    try {
      final canVibrate = await Vibration.hasVibrator();
      if (canVibrate == true) {
        Vibration.vibrate(pattern: [0, 100, 50, 100]);
      }
    } catch (_) {}
  }
}
