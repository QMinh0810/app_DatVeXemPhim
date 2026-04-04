class BookingModel {
  final String? id;
  final String movieId;
  final String theaterName;
  final String showtime; // Chuỗi hiển thị hoặc DateTime
  final List<String> selectedSeats;
  final double totalPrice;
  final String paymentMethod;
  final String status; // 'pending', 'completed', 'cancelled'

  BookingModel({
    this.id,
    required this.movieId,
    required this.theaterName,
    required this.showtime,
    required this.selectedSeats,
    required this.totalPrice,
    required this.paymentMethod,
    this.status = 'pending',
  });

  /// Parse JSON từ Backend API response
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['madondatve'] ?? json['maDonDatVe'] ?? '',
      movieId: json['maphim'] ?? '',
      theaterName: json['tenraphim'] ?? 'Nhóm 7 Cinema',
      showtime: json['giochieu'] ?? '',
      selectedSeats: (json['seats'] as List<dynamic>?)
              ?.map((s) => s.toString())
              .toList() ??
          [],
      totalPrice: (json['tongtien'] ?? json['totalPrice'] ?? 0).toDouble(),
      paymentMethod: json['phuongthucthanhtoan'] ?? 'momo',
      status: json['trangthai'] ?? 'pending',
    );
  }

  BookingModel copyWith({
    String? id,
    String? movieId,
    String? theaterName,
    String? showtime,
    List<String>? selectedSeats,
    double? totalPrice,
    String? paymentMethod,
    String? status,
  }) {
    return BookingModel(
      id: id ?? this.id,
      movieId: movieId ?? this.movieId,
      theaterName: theaterName ?? this.theaterName,
      showtime: showtime ?? this.showtime,
      selectedSeats: selectedSeats ?? this.selectedSeats,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }
}
