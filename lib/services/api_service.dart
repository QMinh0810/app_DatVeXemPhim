import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Android Emulator dùng 10.0.2.2 thay cho localhost
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Lưu trữ JWT Token sau khi đăng nhập
  static String? _token;

  static String? get token => _token;
  static void setToken(String? t) => _token = t;

  // Header mặc định cho mọi request
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ==================== AUTH ====================

  /// Đăng nhập bằng SĐT hoặc Email
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  /// Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register({
    required String hoTen,
    required String sdt,
    required String email,
    required String matKhau,
    String? ngaySinh,
    int? gioiTinh,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'hoTen': hoTen,
        'sdt': sdt,
        'email': email,
        'matKhau': matKhau,
        'ngaySinh': ngaySinh,
        'gioiTinh': gioiTinh,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Quên mật khẩu
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    return jsonDecode(res.body);
  }

  /// Reset mật khẩu
  static Future<Map<String, dynamic>> resetPassword(String email, String otp, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
    );
    return jsonDecode(res.body);
  }

  // ==================== MOVIES ====================

  /// Lấy danh sách phim theo trạng thái (showing, coming_soon)
  static Future<List<dynamic>> fetchMovies({String? status}) async {
    String url = '$baseUrl/movies';
    if (status != null) url += '?status=$status';

    final res = await http.get(Uri.parse(url), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Lấy phim HOT
  static Future<List<dynamic>> fetchHotMovies() async {
    final res = await http.get(Uri.parse('$baseUrl/movies/hot'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Xem chi tiết 1 phim
  static Future<Map<String, dynamic>?> fetchMovieById(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/movies/$id'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'];
  }

  /// Tìm kiếm phim
  static Future<List<dynamic>> searchMovies({String? name, String? genre}) async {
    final params = <String, String>{};
    if (name != null) params['name'] = name;
    if (genre != null) params['genre'] = genre;
    final uri = Uri.parse('$baseUrl/movies/search').replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  // ==================== SHOWTIMES & BOOKING ====================

  /// Lấy lịch chiếu (lọc theo ngày, rạp, phim)
  static Future<List<dynamic>> fetchShowtimes({String? date, String? theaterId, String? movieId}) async {
    final params = <String, String>{};
    if (date != null) params['date'] = date;
    if (theaterId != null) params['theaterId'] = theaterId;
    if (movieId != null) params['movieId'] = movieId;
    final uri = Uri.parse('$baseUrl/bookings/showtimes').replace(queryParameters: params);

    final res = await http.get(uri, headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Lấy sơ đồ ghế ngồi của 1 suất chiếu
  static Future<Map<String, dynamic>> fetchSeats(String showtimeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bookings/showtimes/$showtimeId/seats'),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  /// Đặt vé
  static Future<Map<String, dynamic>> createBooking({
    required String showtimeId,
    required List<String> seatIds,
    String paymentMethod = 'momo',
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bookings/book'),
      headers: _headers,
      body: jsonEncode({
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'paymentMethod': paymentMethod,
      }),
    );
    return jsonDecode(res.body);
  }

  // ==================== REVIEWS ====================

  /// Xem bình luận của 1 phim
  static Future<List<dynamic>> fetchReviews(String movieId) async {
    final res = await http.get(Uri.parse('$baseUrl/reviews/$movieId'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Đăng bình luận
  static Future<Map<String, dynamic>> postReview(String movieId, String noiDung, int danhGia) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reviews/$movieId'),
      headers: _headers,
      body: jsonEncode({'noiDung': noiDung, 'danhGia': danhGia}),
    );
    return jsonDecode(res.body);
  }

  // ==================== USER PROFILE & HISTORY ====================

  /// Lấy thông tin cá nhân
  static Future<Map<String, dynamic>> fetchProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/users/profile'), headers: _headers);
    return jsonDecode(res.body);
  }

  /// Cập nhật Profile
  static Future<Map<String, dynamic>> updateProfile({
    String? hoTen,
    String? ngaySinh,
    int? gioiTinh,
    String? anhDaiDien,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: _headers,
      body: jsonEncode({
        if (hoTen != null) 'hoTen': hoTen,
        if (ngaySinh != null) 'ngaySinh': ngaySinh,
        if (gioiTinh != null) 'gioiTinh': gioiTinh,
        if (anhDaiDien != null) 'anhDaiDien': anhDaiDien,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Xem lịch sử đặt vé
  static Future<List<dynamic>> fetchBookingHistory() async {
    final res = await http.get(Uri.parse('$baseUrl/users/history'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/change-password'),
      headers: _headers,
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    return jsonDecode(res.body);
  }

  // ==================== GOOGLE LOGIN ====================

  /// Đăng nhập bằng Google ID Token
  static Future<Map<String, dynamic>> googleLogin(String idToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google-login'),
      headers: _headers,
      body: jsonEncode({'idToken': idToken}),
    );
    final responseData = jsonDecode(res.body);
    if (responseData['status'] == 'success') {
      _token = responseData['token'];
    }
    return responseData;
  }

  // ==================== NOTIFICATIONS ====================

  /// Lấy danh sách thông báo của người dùng
  static Future<List<dynamic>> fetchNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data'] ?? [];
  }

  /// Lấy số lượng thông báo chưa đọc
  static Future<int> getUnreadCount() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: _headers);
    final body = jsonDecode(res.body);
    return body['data']?['unreadCount'] ?? 0;
  }

  /// Đánh dấu một thông báo là đã đọc
  static Future<Map<String, dynamic>> markNotificationAsRead(String id) async {
    final res = await http.put(Uri.parse('$baseUrl/notifications/$id/read'), headers: _headers);
    return jsonDecode(res.body);
  }

  /// Đánh dấu tất cả thông báo là đã đọc
  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final res = await http.put(Uri.parse('$baseUrl/notifications/read-all'), headers: _headers);
    return jsonDecode(res.body);
  }

  /// Xóa một thông báo cụ thể
  static Future<Map<String, dynamic>> deleteNotification(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/notifications/$id'), headers: _headers);
    return jsonDecode(res.body);
  }

  /// Xóa tất cả thông báo
  static Future<Map<String, dynamic>> deleteAllNotifications() async {
    final res = await http.delete(Uri.parse('$baseUrl/notifications/all'), headers: _headers);
    return jsonDecode(res.body);
  }
}
