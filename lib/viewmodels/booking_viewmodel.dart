import 'package:flutter/material.dart';
import 'dart:async';
import '../models/booking_model.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../models/combo_model.dart';
import '../services/socket_service.dart';
import '../models/voucher_model.dart';

/// Model đại diện cho 1 ghế ngồi từ API
class SeatData {
  final String maghe;
  final String mahangghe; // Ký tự hàng: A, B, C...
  final int soghe;         // Số ghế: 1, 2, 3...
  final String loaighe;    // 'normal', 'vip', 'couple', 'hỏng'
  final double hesogiaghe; // Hệ số nhân giá vé
  final bool isBooked;     // Đã được đặt chưa (trong DB)
  final bool isLockedByMe; // Ghế mình đang giữ tạm (trong Redis)
  final bool isLockedByOther; // Ghế người khác đang giữ (trong Redis)

  SeatData({
    required this.maghe,
    required this.mahangghe,
    required this.soghe,
    required this.loaighe,
    required this.hesogiaghe,
    required this.isBooked,
    this.isLockedByMe = false,
    this.isLockedByOther = false,
  });

  /// Tên hiển thị: VD "A1", "B3"
  String get displayName => '$mahangghe$soghe';

  /// Ghế có bị hỏng không
  bool get isBroken => loaighe == 'hỏng';

  /// Có thể chọn được không (không bị hỏng và chưa đặt)
  bool get isSelectable => !isBroken && !isBooked;

  factory SeatData.fromJson(Map<String, dynamic> json) {
    return SeatData(
      maghe: json['maghe']?.toString() ?? '',
      mahangghe: json['mahangghe']?.toString().trim().toUpperCase() ?? '',
      soghe: int.tryParse(json['soghe']?.toString() ?? '0') ?? 0,
      loaighe: json['loaighe']?.toString().trim().toLowerCase() ?? 'hỏng', 
      hesogiaghe: double.tryParse(json['hesogiaghe']?.toString() ?? '1') ?? 1.0,
      isBooked: json['isBooked'] == true,
      isLockedByMe: json['isLockedByMe'] == true,
      isLockedByOther: json['isLockedByOther'] == true,
    );
  }
}



class BookingViewModel extends ChangeNotifier {
  final SocketService _socketService = SocketService();
  Timer? _heartbeatTimer;
  Timer? _countdownTimer;
  int _secondsRemaining = 300;
  bool _timerActive = false;

  int get secondsRemaining => _secondsRemaining;
  bool get timerActive => _timerActive;

  void syncCountdown(int msRemaining) {
    if (msRemaining <= 0) {
      stopCountdown();
      releaseSeats(); // Giải phóng ghế khi hết thời gian
      return;
    }
    
    _secondsRemaining = (msRemaining / 1000).floor();
    _timerActive = true;
    _countdownTimer?.cancel();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        stopCountdown();
        releaseSeats(); // Giải phóng ghế khi hết thời gian
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void stopCountdown() {
    _countdownTimer?.cancel();
    _timerActive = false;
    _secondsRemaining = 300;
    notifyListeners();
  }

  MovieModel? _selectedMovie;
  final List<String> _selectedSeats = [];
  List<String> _bookedSeats = [];
  List<SeatData> _seatMap = []; // Full seat data từ API
  String _paymentMethod = 'momo';
  double _seatPrice = 100000.0; // Giá vé cơ sở từ lịch chiếu
  String? _selectedShowtimeId;
  String? _selectedTheaterId;
  String? _selectedTheaterName;
  String? _selectedRoomName;
  String? _selectedTimeDisplay;
  String? _selectedDateDisplay;
  bool _isLoading = false;
  String? _errorMessage;
  String? _bookingResult; // Mã đơn hàng sau khi đặt thành công
  String? _paymentUrl;    // URL thanh toán (VNPay/Momo) nếu có
  
  // Vouchers
  VoucherModel? _selectedVoucher;
  List<VoucherModel> _mockVouchers = [];
  
  // Combos
  List<ComboData> _availableCombos = [];
  Map<int, int> _selectedCombos = {}; // comboId -> quantity
  
  MovieModel? get selectedMovie => _selectedMovie;
  List<String> get selectedSeats => _selectedSeats;
  List<String> get bookedSeats => _bookedSeats;
  List<SeatData> get seatMap => _seatMap;
  String get paymentMethod => _paymentMethod;
  double get basePrice => _seatPrice;
  String? get selectedShowtimeId => _selectedShowtimeId;
  String? get selectedTheaterId => _selectedTheaterId;
  String? get selectedTheaterName => _selectedTheaterName;
  String? get selectedRoomName => _selectedRoomName;
  String? get selectedTimeDisplay => _selectedTimeDisplay;
  String? get selectedDateDisplay => _selectedDateDisplay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get bookingResult => _bookingResult;
  String? get paymentUrl => _paymentUrl;
  List<ComboData> get availableCombos => _availableCombos;
  Map<int, int> get selectedCombos => _selectedCombos;
  VoucherModel? get selectedVoucher => _selectedVoucher;
  List<VoucherModel> get availableVouchers => _mockVouchers;

  /// Tính tổng tiền vé và combo (chưa trừ voucher)
  double get subTotal {
    return ticketTotalPrice + comboTotalPrice;
  }

  /// Tổng tiền cuối cùng sau khi trừ voucher
  double get totalPrice {
    return subTotal - discountAmount;
  }

  /// Số tiền được giảm
  double get discountAmount {
    if (_selectedVoucher == null) return 0;
    
    double discount = 0;
    if (_selectedVoucher!.percentage > 0) {
      discount = subTotal * _selectedVoucher!.percentage;
      if (discount > _selectedVoucher!.maxDiscount) {
        discount = _selectedVoucher!.maxDiscount;
      }
    } else {
      discount = _selectedVoucher!.discountAmount;
    }
    
    // Đảm bảo không giảm quá tổng tiền
    return discount > subTotal ? subTotal : discount;
  }

  /// Tổng tiền riêng phần vé
  double get ticketTotalPrice {
    double total = 0;
    for (final seatName in _selectedSeats) {
      final seatData = _seatMap.firstWhere(
        (s) => s.maghe == seatName,
        orElse: () => SeatData(
          maghe: seatName, mahangghe: '', soghe: 0,
          loaighe: 'normal', hesogiaghe: 1.0, isBooked: false,
        ),
      );
      total += _seatPrice * seatData.hesogiaghe;
    }
    return total;
  }

  /// Tổng tiền riêng phần combo đồ ăn
  double get comboTotalPrice {
    double total = 0;
    _selectedCombos.forEach((comboId, quantity) {
      final combo = _availableCombos.firstWhere(
        (c) => c.comboId == comboId,
        orElse: () => ComboData(comboId: 0, name: '', description: '', price: 0, imageUrl: ''),
      );
      total += combo.price * quantity;
    });
    return total;
  }

  /// Lấy SeatData từ maghe
  SeatData? getSeatData(String maghe) {
    try {
      return _seatMap.firstWhere((s) => s.maghe == maghe);
    } catch (_) {
      return null;
    }
  }

  /// Lấy danh sách các hàng ghế cố định (11 hàng)
  List<String> get seatRows {
    return ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K'];
  }

  /// Lấy số cột cố định (8 cột)
  int get maxCols {
    return 8;
  }

  /// Lấy ghế tại vị trí hàng + cột cụ thể
  SeatData? getSeatAt(String row, int col) {
    try {
      return _seatMap.firstWhere((s) => s.mahangghe == row && s.soghe == col);
    } catch (_) {
      // Nếu không có trong DB thì tự động coi là ghế hỏng để giữ khung sơ đồ đầy đủ
      return SeatData(
        maghe: '${row}_$col',
        mahangghe: row,
        soghe: col,
        loaighe: 'hỏng',
        hesogiaghe: 0.0,
        isBooked: false,
      );
    }
  }

  void selectMovie(MovieModel movie) {
    _selectedMovie = movie;
    _selectedSeats.clear();
    _bookingResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void selectTheater(String theaterId, String theaterName) {
    _selectedTheaterId = theaterId;
    _selectedTheaterName = theaterName;
    notifyListeners();
  }

  void selectShowtime(String showtimeId, double basePrice, {String? theaterName, String? roomName, String? timeDisplay, String? dateDisplay}) {
    _selectedShowtimeId = showtimeId;
    _seatPrice = basePrice;
    _selectedTheaterName = theaterName;
    _selectedRoomName = roomName;
    _selectedTimeDisplay = timeDisplay;
    _selectedDateDisplay = dateDisplay;
    _selectedSeats.clear();
    
    // Khởi tạo socket khi chọn suất chiếu
    initSocket(showtimeId);
    
    notifyListeners();
  }

  // ============================================================
  // SOCKET.IO LOGIC
  // ============================================================

  void initSocket(String showtimeId) {
    // Reset timer cũ trước khi khởi tạo socket mới
    stopCountdown();
    _socketService.connect();
    _socketService.clearListeners();
    
    // Join room
    _socketService.joinShowtime(showtimeId);

    // Lắng nghe trạng thái ban đầu
    _socketService.onInitialState((data) {
      final List lockedSeats = data['lockedSeats'] ?? [];
      _selectedSeats.clear();
      
      for (var s in lockedSeats) {
        final String sid = s['seatId'];
        final bool isYours = s['isYours'] == true;
        
        if (isYours) {
          _selectedSeats.add(sid);
        }
        // Update seatMap status
        _updateSeatLockStatus(sid, isLockedByMe: isYours, isLockedByOther: !isYours);
      }
      notifyListeners();
    });

    // Lắng nghe khi có người khác lock ghế
    _socketService.onSeatLocked((data) {
      final String sid = data['seatId'];
      _updateSeatLockStatus(sid, isLockedByOther: true);
      notifyListeners();
    });

    // Lắng nghe khi ghế được giải phóng
    _socketService.onSeatUnlocked((data) {
      final String sid = data['seatId'];
      _updateSeatLockStatus(sid, isLockedByMe: false, isLockedByOther: false);
      
      // Nếu là ghế mình đang chọn mà bị server unlock (hết hạn)
      if (_selectedSeats.contains(sid)) {
        _selectedSeats.remove(sid);
      }
      notifyListeners();
    });

    // Lắng nghe unlock hàng loạt
    _socketService.onSeatsUnlockedBatch((data) {
      final List sids = data['seatIds'] ?? [];
      for (var sid in sids) {
        _updateSeatLockStatus(sid, isLockedByMe: false, isLockedByOther: false);
        _selectedSeats.remove(sid);
      }
      notifyListeners();
    });

    // Lắng nghe khi ghế được xác nhận mua thành công
    _socketService.onSeatsConfirmed((data) {
      final List sids = data['seatIds'] ?? [];
      for (var sid in sids) {
        _updateSeatConfirmed(sid);
      }
      notifyListeners();
    });

    // Xử lý khi mình lock thành công
      _socketService.onLockSuccess((data) {
        final String sid = data['seatId'];
        // Use default 5 min (300000 ms) if backend didn't send timeout
        final int earliestTimeoutMs = (data['earliestTimeoutMs'] ?? 300000) as int;

        if (!_selectedSeats.contains(sid)) {
          _selectedSeats.add(sid);
        }
        _updateSeatLockStatus(sid, isLockedByMe: true);

        // Always start or update timer – if it's the first lock or a shorter timeout
        final int currentMs = _secondsRemaining * 1000;
        if (currentMs == 0 || earliestTimeoutMs <= currentMs) {
          syncCountdown(earliestTimeoutMs);
        }

        notifyListeners();
      });

    // Lắng nghe cập nhật thời gian timer khi hủy ghế
      _socketService.onUpdateLockTimer((data) {
        // If backend provides a timeout, update; otherwise stop timer
        final int earliestTimeoutMs = data['earliestTimeoutMs'] ?? 0;
        if (earliestTimeoutMs > 0) {
          // Update countdown to the new earliest timeout, even if it's later
          syncCountdown(earliestTimeoutMs);
        } else {
          stopCountdown();
        }
      });

    // Xử lý khi mình lock thất bại (ví dụ tranh chấp)
    _socketService.onLockFailed((data) {
      final String sid = data['seatId'];
      final String reason = data['reason'] ?? 'Ghế không khả dụng';
      
      _selectedSeats.remove(sid);
      _errorMessage = reason;
      
      // Refresh lại seat map để đồng bộ
      fetchSeatMap(silent: true);
      notifyListeners();
    });

    // Bắt đầu Heartbeat để duy trì lock (mỗi 1 phút)
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _socketService.sendHeartbeat(showtimeId);
    });
  }

  void _updateSeatLockStatus(String maghe, {bool? isLockedByMe, bool? isLockedByOther}) {
    final index = _seatMap.indexWhere((s) => s.maghe == maghe);
    if (index != -1) {
      final old = _seatMap[index];
      _seatMap[index] = SeatData(
        maghe: old.maghe,
        mahangghe: old.mahangghe,
        soghe: old.soghe,
        loaighe: old.loaighe,
        hesogiaghe: old.hesogiaghe,
        isBooked: old.isBooked,
        isLockedByMe: isLockedByMe ?? old.isLockedByMe,
        isLockedByOther: isLockedByOther ?? old.isLockedByOther,
      );
    }
  }

  void _updateSeatConfirmed(String maghe) {
    final index = _seatMap.indexWhere((s) => s.maghe == maghe);
    if (index != -1) {
      final old = _seatMap[index];
      _seatMap[index] = SeatData(
        maghe: old.maghe,
        mahangghe: old.mahangghe,
        soghe: old.soghe,
        loaighe: old.loaighe,
        hesogiaghe: old.hesogiaghe,
        isBooked: true, // Chuyển hẳn sang trạng thái đã bán
        isLockedByMe: false,
        isLockedByOther: false,
      );
      if (!_bookedSeats.contains(maghe)) {
        _bookedSeats.add(maghe);
      }
      _selectedSeats.remove(maghe);
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _countdownTimer?.cancel();
    _socketService.disconnect();
    super.dispose();
  }

  /// Giải phóng tất cả ghế đang chọn và ngắt kết nối socket (gọi khi thoát màn hình chọn ghế)
  void releaseSeats() {
    print('🧹 [BookingViewModel] Giải phóng ghế và ngắt kết nối socket');
    _heartbeatTimer?.cancel();
    stopCountdown();
    
    // Nếu có showtimeId, gửi unlock từng cái (hoặc server tự xử lý khi disconnect)
    // Ở đây ta chọn disconnect để server tự dọn dẹp theo logic auto-unlock
    _socketService.disconnect();
    
    // Xóa danh sách ghế đang chọn tại local
    for (var seatId in _selectedSeats) {
      _updateSeatLockStatus(seatId, isLockedByMe: false);
    }
    _selectedSeats.clear();
    
    notifyListeners();
  }

  void toggleSeat(String seatName) {
    if (_bookedSeats.contains(seatName)) return;
    
    final seatData = getSeatData(seatName);
    if (seatData == null || seatData.isBroken) return;
    if (seatData.isLockedByOther) {
      _errorMessage = 'Ghế này đang được người khác giữ';
      notifyListeners();
      return;
    }

    if (_selectedSeats.contains(seatName)) {
      // 1. Phản hồi nhanh: Xóa khỏi danh sách chọn ngay
      _selectedSeats.remove(seatName);
      _updateSeatLockStatus(seatName, isLockedByMe: false);
      
      // 2. Gửi lệnh tới server
      _socketService.unlockSeat(_selectedShowtimeId!, seatName);

      // Nếu không còn ghế nào được chọn thì dừng timer
      if (_selectedSeats.isEmpty) {
        stopCountdown(); 
      }
    } else {
      // KIỂM TRA GIỚI HẠN 6 GHẾ
      if (_selectedSeats.length >= 6) {
        _errorMessage = 'Bạn chỉ được chọn tối đa 6 ghế';
        notifyListeners();
        return;
      }

      // 1. Phản hồi nhanh: Thêm vào danh sách chọn ngay (màu xanh)
      _selectedSeats.add(seatName);
      _updateSeatLockStatus(seatName, isLockedByMe: true);

      // 2. Gửi lệnh tới server
      _socketService.lockSeat(_selectedShowtimeId!, seatName);
    }
    _errorMessage = null; // Clear error cũ
    notifyListeners();
  }

  // Combo Selection Methods
  void addCombo(int comboId) {
    _selectedCombos[comboId] = (_selectedCombos[comboId] ?? 0) + 1;
    notifyListeners();
  }

  void removeCombo(int comboId) {
    if (_selectedCombos.containsKey(comboId) && _selectedCombos[comboId]! > 0) {
      _selectedCombos[comboId] = _selectedCombos[comboId]! - 1;
      if (_selectedCombos[comboId] == 0) {
        _selectedCombos.remove(comboId);
      }
      notifyListeners();
    }
  }

  int getComboQuantity(int comboId) {
    return _selectedCombos[comboId] ?? 0;
  }

  void selectVoucher(VoucherModel? voucher) {
    _selectedVoucher = voucher;
    notifyListeners();
  }

  void fetchVouchers(UserRank userRank) {
    // Mock data for vouchers based on Shopee style
    _mockVouchers = [
      VoucherModel(
        id: 'SILVER_10',
        title: 'Bạc: Giảm 10%',
        description: 'Dành cho hạng Bạc. Giảm tối đa 20k cho đơn từ 100k',
        percentage: 0.1,
        maxDiscount: 20000,
        minOrderValue: 100000,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        type: 'discount',
        minRank: UserRank.silver,
      ),
      VoucherModel(
        id: 'GOLD_20',
        title: 'Vàng: Giảm 20%',
        description: 'Dành cho hạng Vàng. Giảm tối đa 50k cho đơn từ 150k',
        percentage: 0.2,
        maxDiscount: 50000,
        minOrderValue: 150000,
        expiryDate: DateTime.now().add(const Duration(days: 10)),
        type: 'discount',
        minRank: UserRank.gold,
      ),
      VoucherModel(
        id: 'DIAMOND_35',
        title: 'Kim Cương: Giảm 35%',
        description: 'Dành cho hạng Kim Cương. Giảm tối đa 100k cho đơn từ 200k',
        percentage: 0.35,
        maxDiscount: 100000,
        minOrderValue: 200000,
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        type: 'discount',
        minRank: UserRank.diamond,
      ),
      VoucherModel(
        id: 'FREESHIP',
        title: 'Miễn phí vận chuyển',
        description: 'Giảm tối đa 15k phí bắp nước đơn từ 50k',
        discountAmount: 15000,
        minOrderValue: 50000,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        type: 'shipping',
        minRank: UserRank.silver,
      ),
    ];

    // Filter by rank: users can see vouchers of their rank and lower
    _mockVouchers = _mockVouchers.where((v) => userRank.index >= v.minRank.index).toList();
    notifyListeners();
  }

  Future<void> fetchCombos() async {
    try {
      final res = await ApiService.fetchCombos();
      _availableCombos = res.map<ComboData>((json) => ComboData.fromJson(json)).toList();
    } catch (e) {
      print('Failed to fetch combos: $e');
    }
    
    // Dummy combo để test nếu rỗng
    if (_availableCombos.isEmpty) {
      _availableCombos = [
        ComboData(
          comboId: 999,
          name: 'Combo Khổng Lồ',
          description: '1 Bắp vị tự chọn lớn + 2 ly Nước ngọt khổng lồ',
          price: 109000,
          imageUrl: 'https://bhdstar.vn/wp-content/uploads/2023/08/BHD-Star-Combo-2.png',
        ),
        ComboData(
          comboId: 1000,
          name: 'Combo Cặp Đôi',
          description: '1 Bắp phô mai lớn + 2 ly Nước ngọt vừa',
          price: 89000,
          imageUrl: 'https://bhdstar.vn/wp-content/uploads/2023/08/BHD-Star-Combo-1.png',
        )
      ];
    }
    notifyListeners();
  }

  Future<void> fetchSeatMap({bool silent = false}) async {
    if (_selectedShowtimeId == null) return;
    
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }
    
    try {
      final res = await ApiService.fetchSeats(_selectedShowtimeId!);
      if (res['status'] == 'success') {
        final List<dynamic> seatsList = res['data']['seats'];
        final Map<String, dynamic> showtimeInfo = res['data']['showtime'] ?? {};
        
        // Cập nhật thông tin rạp/phòng từ API (hỗ trợ nhiều định dạng key)
        _selectedTheaterName = showtimeInfo['tenrapphim'] ?? 
                               showtimeInfo['tenRapPhim'] ?? 
                               showtimeInfo['TENRAPPHIM'] ?? 
                               _selectedTheaterName;
                               
        _selectedRoomName = showtimeInfo['tenphong'] ?? 
                             showtimeInfo['tenPhong'] ?? 
                             showtimeInfo['TENPHONG'] ?? 
                             _selectedRoomName;

        // Parse full seat data
        _seatMap = seatsList.map<SeatData>((seat) => SeatData.fromJson(seat)).toList();
        
        // Cập nhật danh sách ghế đã đặt
        _bookedSeats = _seatMap
            .where((seat) => seat.isBooked)
            .map<String>((seat) => seat.maghe)
            .toList();

        // Xóa các ghế vừa bị người khác đặt khỏi danh sách đang chọn của mình
        _selectedSeats.removeWhere((seatId) => _bookedSeats.contains(seatId));
      }
    } catch (e) {
      if (!silent) _errorMessage = 'Không thể tải sơ đồ ghế';
    }
    
    if (!silent) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  /// Gửi đơn đặt vé lên Backend (thay thế hàm createBooking cũ)
  Future<bool> submitBooking() async {
    if (_selectedMovie == null || _selectedSeats.isEmpty || _selectedShowtimeId == null) {
      _errorMessage = 'Vui lòng chọn phim, suất chiếu và ghế ngồi';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> concessions = _selectedCombos.entries.map((e) {
        return {
          'comboId': e.key,
          'quantity': e.value,
        };
      }).toList();

      final response = await ApiService.createBooking(
        showtimeId: _selectedShowtimeId!,
        seatIds: _selectedSeats,
        paymentMethod: _paymentMethod,
        concessions: concessions.isNotEmpty ? concessions : null,
      );

      _isLoading = false;

      if (response['status'] == 'success') {
        _bookingResult = response['data']?['maDonDatVe'] ?? 'OK';
        _paymentUrl = response['data']?['paymentUrl']; // Lấy URL thanh toán từ backend
        notifyListeners();
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đặt vé thất bại';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể kết nối máy chủ để đặt vé.';
      notifyListeners();
      return false;
    }
  }

  /// Gửi đơn combo đồ ăn lên server (gọi sau submitBooking thành công)
  Future<void> submitConcessionOrder() async {
    if (_bookingResult == null || _selectedCombos.isEmpty) return;
    try {
      final items = _selectedCombos.entries
          .map((e) => {'combo_id': e.key, 'quantity': e.value})
          .toList();
      await ApiService.createConcessionOrder(
        madondatve: _bookingResult!,
        items: items,
      );
    } catch (e) {
      // Log lỗi nhưng không block UX — combo order fail nên silent
      debugPrint('submitConcessionOrder error: $e');
    }
  }

  /// Giữ lại hàm cũ cho tương thích ngược (nếu UI gọi)
  BookingModel? createBooking() {
    if (_selectedMovie == null || _selectedSeats.isEmpty) return null;

    return BookingModel(
      movieId: _selectedMovie!.id,
      theaterName: 'Nhóm 7 Cinema Sư Vạn Hạnh',
      showtime: '18:00 - 10/04/2024',
      selectedSeats: List.from(_selectedSeats),
      totalPrice: totalPrice,
      paymentMethod: _paymentMethod,
    );
  }

  void resetBooking() {
    _heartbeatTimer?.cancel();
    _socketService.disconnect();
    _selectedSeats.clear();
    _bookedSeats.clear();
    _seatMap.clear();
    _selectedShowtimeId = null;
    _selectedTheaterId = null;
    _selectedTheaterName = null;
    _selectedRoomName = null;
    _selectedTimeDisplay = null;
    _selectedDateDisplay = null;
    _bookingResult = null;
    _paymentUrl = null;
    _errorMessage = null;
    _selectedCombos.clear();
    notifyListeners();
  }

  /// Kiểm tra trạng thái đơn hàng (Polling)
  Future<Map<String, dynamic>> checkBookingStatus(String id) async {
    return await ApiService.getBookingStatus(id);
  }

  /// Hủy đơn hàng chủ động
  Future<bool> cancelBooking(String id) async {
    try {
      final res = await ApiService.cancelBooking(id);
      return res['status'] == 'success';
    } catch (e) {
      return false;
    }
  }
}
