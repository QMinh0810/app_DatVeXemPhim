import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';

class BookingViewModel extends ChangeNotifier {
  MovieModel? _selectedMovie;
  List<String> _selectedSeats = [];
  List<String> _bookedSeats = [];
  String _paymentMethod = 'momo';
  double _seatPrice = 100000.0;
  String? _selectedShowtimeId;
  String? _selectedTheaterName;
  String? _selectedRoomName;
  String? _selectedTimeDisplay;
  String? _selectedDateDisplay;
  bool _isLoading = false;
  String? _errorMessage;
  String? _bookingResult; // Mã đơn hàng sau khi đặt thành công

  MovieModel? get selectedMovie => _selectedMovie;
  List<String> get selectedSeats => _selectedSeats;
  List<String> get bookedSeats => _bookedSeats;
  String get paymentMethod => _paymentMethod;
  double get totalPrice => _selectedSeats.length * _seatPrice;
  String? get selectedShowtimeId => _selectedShowtimeId;
  String? get selectedTheaterName => _selectedTheaterName;
  String? get selectedRoomName => _selectedRoomName;
  String? get selectedTimeDisplay => _selectedTimeDisplay;
  String? get selectedDateDisplay => _selectedDateDisplay;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get bookingResult => _bookingResult;

  void selectMovie(MovieModel movie) {
    _selectedMovie = movie;
    _selectedSeats.clear();
    _bookingResult = null;
    _errorMessage = null;
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
    
    if (_selectedSeats.contains(seatName)) {
      _selectedSeats.remove(seatName);
    } else {
      _selectedSeats.add(seatName);
    }
    notifyListeners();
  }

  Future<void> fetchSeatMap() async {
    if (_selectedShowtimeId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final res = await ApiService.fetchSeats(_selectedShowtimeId!);
      if (res['status'] == 'success') {
        final List<dynamic> seatsList = res['data']['seats'];
        _bookedSeats = seatsList
            .where((seat) => seat['isBooked'] == true)
            .map<String>((seat) => seat['maghe'].toString())
            .toList();
      }
    } catch (e) {
      _errorMessage = 'Không thể tải sơ đồ ghế';
    }
    
    _isLoading = false;
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
      final response = await ApiService.createBooking(
        showtimeId: _selectedShowtimeId!,
        seatIds: _selectedSeats,
        paymentMethod: _paymentMethod,
      );

      _isLoading = false;

      if (response['status'] == 'success') {
        _bookingResult = response['data']?['maDonDatVe'] ?? 'OK';
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
    _selectedShowtimeId = null;
    _selectedTheaterName = null;
    _selectedRoomName = null;
    _selectedTimeDisplay = null;
    _selectedDateDisplay = null;
    _bookingResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}
