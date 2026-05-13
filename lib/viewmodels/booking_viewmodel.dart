import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';
import '../models/combo_model.dart';

/// Model đại diện cho 1 ghế ngồi từ API
class SeatData {
  final String maghe;
  final String mahangghe; // Ký tự hàng: A, B, C...
  final int soghe;         // Số ghế: 1, 2, 3...
  final String loaighe;    // 'normal', 'vip', 'couple', 'hỏng'
  final double hesogiaghe; // Hệ số nhân giá vé
  final bool isBooked;     // Đã được đặt chưa

  SeatData({
    required this.maghe,
    required this.mahangghe,
    required this.soghe,
    required this.loaighe,
    required this.hesogiaghe,
    required this.isBooked,
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
    );
  }
}

class BookingViewModel extends ChangeNotifier {
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

  /// Tính tổng tiền vé và combo
  double get totalPrice {
    return ticketTotalPrice + comboTotalPrice;
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
    notifyListeners();
  }

  void toggleSeat(String seatName) {
    if (_bookedSeats.contains(seatName)) return;
    
    // Kiểm tra ghế hỏng
    final seatData = getSeatData(seatName);
    if (seatData != null && seatData.isBroken) return;
    
    if (_selectedSeats.contains(seatName)) {
      _selectedSeats.remove(seatName);
    } else {
      _selectedSeats.add(seatName);
    }
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
}
