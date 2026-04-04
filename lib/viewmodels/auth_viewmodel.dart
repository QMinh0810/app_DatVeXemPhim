import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthViewModel extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);

      if (response['status'] == 'success') {
        // Lưu JWT Token
        _token = response['token'];
        ApiService.setToken(_token);

        // Parse user data
        final userData = response['user'];
        _currentUser = UserModel.fromJson(userData);
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      _errorMessage = 'Không thể kết nối máy chủ. Vui lòng kiểm tra Backend đang chạy.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String hoTen,
    required String sdt,
    required String email,
    required String matKhau,
    String? ngaySinh,
    int? gioiTinh,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.register(
        hoTen: hoTen,
        sdt: sdt,
        email: email,
        matKhau: matKhau,
        ngaySinh: ngaySinh,
        gioiTinh: gioiTinh,
      );

      _isLoading = false;
      notifyListeners();

      if (response['status'] == 'success') {
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Đăng ký thất bại';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Không thể kết nối máy chủ.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    ApiService.setToken(null);
    notifyListeners();
  }
}
