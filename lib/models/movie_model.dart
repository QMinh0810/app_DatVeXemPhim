class MovieModel {
  final String id;
  final String title;
  final String description;
  final int duration; // Số phút
  final DateTime releaseDate;
  final int ratingLimit; // Ví dụ: 16, 18, 0 (không giới hạn)
  final String posterUrl;
  final String? trailerUrl;
  final List<String> genres;
  final String status; // 'showing' hoặc 'coming_soon'

  MovieModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.releaseDate,
    required this.ratingLimit,
    required this.posterUrl,
    this.trailerUrl,
    required this.genres,
    required this.status,
  });

  /// Parse JSON từ Backend API (các field snake_case từ PostgreSQL)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      id: json['maphim'] ?? '',
      title: json['tenphim'] ?? '',
      description: json['mota'] ?? '',
      duration: json['thoiluong'] ?? 0,
      releaseDate: json['ngayramat'] != null
          ? DateTime.tryParse(json['ngayramat'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ratingLimit: json['gioihantuoi'] ?? 0,
      posterUrl: json['poster_url'] ?? '',
      trailerUrl: json['trailer_url'],
      genres: [], // Genres cần JOIN riêng, tạm để rỗng
      status: json['trangthai'] ?? 'showing',
    );
  }

  MovieModel copyWith({
    String? id,
    String? title,
    String? description,
    int? duration,
    DateTime? releaseDate,
    int? ratingLimit,
    String? posterUrl,
    String? trailerUrl,
    List<String>? genres,
    String? status,
  }) {
    return MovieModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      releaseDate: releaseDate ?? this.releaseDate,
      ratingLimit: ratingLimit ?? this.ratingLimit,
      posterUrl: posterUrl ?? this.posterUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      genres: genres ?? this.genres,
      status: status ?? this.status,
    );
  }
}
