/// Model biểu diễn thông tin Diễn viên hoặc Đạo diễn (kèm ảnh đại diện)
class PersonInfo {
  final String name;
  final String? avatarUrl;

  PersonInfo({required this.name, this.avatarUrl});

  factory PersonInfo.fromJson(Map<String, dynamic> json) {
    return PersonInfo(
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

class MovieModel {
  final String id;
  final String title;
  final String description;
  final int duration;
  final DateTime releaseDate;
  final int ratingLimit;
  final String posterUrl;
  final String? trailerUrl;
  final List<String> genres;
  final List<PersonInfo> directors;
  final List<PersonInfo> actors;
  final String status;

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
    required this.directors,
    required this.actors,
    required this.status,
  });

  /// Parse JSON từ Backend API (các field snake_case từ PostgreSQL)
  factory MovieModel.fromJson(Map<String, dynamic> json) {
    // Parse directors: hỗ trợ cả dạng Object mới và String cũ (backward compat)
    List<PersonInfo> parsePersonList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) return PersonInfo.fromJson(e);
          return PersonInfo(name: e.toString());
        }).toList();
      }
      return [];
    }

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
      genres: (json['genres'] as List?)?.map((e) => e.toString()).toList() ?? [],
      directors: parsePersonList(json['directors']),
      actors: parsePersonList(json['actors']),
      status: json['trangthai'] ?? 'now_showing',
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
    List<PersonInfo>? directors,
    List<PersonInfo>? actors,
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
      directors: directors ?? this.directors,
      actors: actors ?? this.actors,
      status: status ?? this.status,
    );
  }
}
