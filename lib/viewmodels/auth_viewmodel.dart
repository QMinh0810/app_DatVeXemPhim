import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../models/voucher_model.dart';

class AuthViewModel extends ChangeNotifier {
  static bool _googleSignInInitialized = false;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('jwt_token')) return;

    _token = prefs.getString('jwt_token');
    ApiService.setToken(_token);

    try {
      final res = await ApiService.fetchProfile();
      if (res['status'] == 'success' || res['data'] != null) {
        _currentUser = UserModel.fromJson(res['data'] ?? res['user'] ?? res);
        notifyListeners();
      } else {
        // Token might be expired
        await logout();
      }
    } catch (e) {
      // Offline or server down, keep token but don't fetch user
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_googleSignInInitialized) {
        // Cần serverClientId (Web Client ID từ Google Console) để nhận được idToken
        await GoogleSignIn.instance.initialize(
          serverClientId: '356822372175-3l82628c5iefji9gu9llp04o0tfs9i7j.apps.googleusercontent.com',
        );
        _googleSignInInitialized = true;
      }

      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile', 'openid'],
      );

      if (account == null) {
        _isLoading = false;
        notifyListeners();
        return; // Người dùng hủy đăng nhập
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null) {
        _errorMessage = 'Không lấy được Token từ Google. Vui lòng kiểm tra cấu hình serverClientId.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await ApiService.googleLogin(auth.idToken!);
      if (response['status'] == 'success') {
        _token = response['token'];
        ApiService.setToken(_token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);

        final userData = response['user'];
        _currentUser = UserModel.fromJson(userData);
      } else {
        _errorMessage = response['message'] ?? 'Đăng nhập Google thất bại';
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _isLoading = false;
        notifyListeners();
        return; // User canceled
      }
      _errorMessage = 'Lỗi kết nối Google: ${e.code}';
    } catch (e) {
      _errorMessage = 'Lỗi không xác định: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);

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

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    ApiService.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    
  notifyListeners();
  }

  /// For testing purposes: Manually set the current user's rank
  void setRank(UserRank rank) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(rank: rank);
      notifyListeners();
    }
  }
}
