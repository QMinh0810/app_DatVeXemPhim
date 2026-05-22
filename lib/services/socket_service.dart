import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';

class SocketService {
  static IO.Socket? _socket;
  
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? get socket => _socket;

  // Lấy socketUrl từ baseUrl của ApiService (bỏ /api)
  String get _socketUrl {
    final baseUrl = ApiService.baseUrl;
    return baseUrl.replaceAll('/api', '');
  }

  /// Khởi tạo và kết nối Socket.IO
  void connect() {
    final currentToken = ApiService.token;
    
    // Nếu đã kết nối nhưng token thay đổi (vd: vừa đăng nhập) thì disconnect để kết nối lại
    if (_socket != null && _socket!.connected) {
      final lastToken = _socket!.auth?['token'];
      if (lastToken == currentToken) return;
      print('🔄 [Socket] Token thay đổi, đang kết nối lại...');
      _socket!.disconnect();
    }

    final url = _socketUrl;
    print('🔌 [Socket] Kết nối tới: $url/booking');
    print('🔑 [Socket] Token sử dụng: ${currentToken != null ? currentToken.substring(0, 10) + "..." : "NULL"}');

    _socket = IO.io('$url/booking', {
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
      'reconnection': true,
      'auth': {
        'token': currentToken,
      },
    });

    _socket!.onConnect((_) {
      print('✅ [Socket] Đã kết nối thành công (ID: ${_socket!.id})');
    });

    _socket!.onDisconnect((_) {
      print('❌ [Socket] Đã ngắt kết nối');
    });

    _socket!.onConnectError((err) {
      print('⚠️ [Socket] Lỗi kết nối: $err');
    });

    _socket!.onAny((event, data) {
      print('📡 [Socket Event] $event: $data');
    });
  }

  /// Ngắt kết nối
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  // ============================================================
  // EMITTERS (Gửi sự kiện lên Server)
  // ============================================================

  /// Join vào room của suất chiếu
  void joinShowtime(String showtimeId) {
    _socket?.emit('join_showtime', {'showtimeId': showtimeId});
  }

  /// Lock ghế (khi người dùng chọn)
  void lockSeat(String showtimeId, String seatId) {
    _socket?.emit('lock_seat', {'showtimeId': showtimeId, 'seatId': seatId});
  }

  /// Unlock ghế (khi người dùng bỏ chọn)
  void unlockSeat(String showtimeId, String seatId) {
    _socket?.emit('unlock_seat', {'showtimeId': showtimeId, 'seatId': seatId});
  }

  /// Gửi heartbeat để duy trì lock
  void sendHeartbeat(String showtimeId) {
    _socket?.emit('heartbeat', {'showtimeId': showtimeId});
  }

  // ============================================================
  // LISTENERS (Đăng ký lắng nghe sự kiện từ Server)
  // ============================================================

  void onInitialState(Function(dynamic) callback) {
    _socket?.on('initial_state', callback);
  }

  void onSeatLocked(Function(dynamic) callback) {
    _socket?.on('seat_locked', callback);
  }

  void onSeatUnlocked(Function(dynamic) callback) {
    _socket?.on('seat_unlocked', callback);
  }

  void onSeatsUnlockedBatch(Function(dynamic) callback) {
    _socket?.on('seats_unlocked_batch', callback);
  }

  void onSeatsConfirmed(Function(dynamic) callback) {
    _socket?.on('seats_confirmed', callback);
  }

  void onLockSuccess(Function(dynamic) callback) {
    _socket?.on('lock_success', callback);
  }

  void onLockFailed(Function(dynamic) callback) {
    _socket?.on('lock_failed', callback);
  }

  void onUpdateLockTimer(Function(dynamic) callback) {
    _socket?.on('update_lock_timer', callback);
  }

  /// Hủy đăng ký tất cả listeners cho một suất chiếu (tránh rò rỉ bộ nhớ)
  void clearListeners() {
    _socket?.off('initial_state');
    _socket?.off('seat_locked');
    _socket?.off('seat_unlocked');
    _socket?.off('seats_unlocked_batch');
    _socket?.off('seats_confirmed');
    _socket?.off('lock_success');
    _socket?.off('lock_failed');
    _socket?.off('update_lock_timer');
  }
}
