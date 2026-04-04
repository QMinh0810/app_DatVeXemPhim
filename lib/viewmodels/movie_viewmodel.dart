import 'package:flutter/material.dart';
import '../models/movie_model.dart';
import '../services/api_service.dart';

class MovieViewModel extends ChangeNotifier {
  List<MovieModel> _showingMovies = [];
  List<MovieModel> _comingSoonMovies = [];
  List<MovieModel> _hotMovies = [];
  List<MovieModel> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MovieModel> get showingMovies => _showingMovies;
  List<MovieModel> get comingSoonMovies => _comingSoonMovies;
  List<MovieModel> get hotMovies => _hotMovies;
  List<MovieModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Tải danh sách phim đang chiếu + sắp chiếu từ Backend
  Future<void> fetchMovies() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Gọi song song 2 API để tăng tốc
      final results = await Future.wait([
        ApiService.fetchMovies(status: 'showing'),
        ApiService.fetchMovies(status: 'coming_soon'),
      ]);

      _showingMovies = results[0]
          .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _comingSoonMovies = results[1]
          .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách phim. Kiểm tra kết nối Backend.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Tải danh sách phim HOT
  Future<void> fetchHotMovies() async {
    try {
      final data = await ApiService.fetchHotMovies();
      _hotMovies = data
          .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (e) {
      // Silent fail cho hot movies
    }
  }

  /// Tìm kiếm phim
  Future<void> searchMovies({String? name, String? genre}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.searchMovies(name: name, genre: genre);
      _searchResults = data
          .map((json) => MovieModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _errorMessage = 'Lỗi tìm kiếm phim';
    }

    _isLoading = false;
    notifyListeners();
  }
}
