import 'voucher_model.dart';

class UserModel {
  final String id;
  final String fullName;
  final DateTime dob;
  final int gender; // 1: Nam, 0: Nữ
  final String phone;
  final String email;
  final String? avatarUrl;
  final UserRank rank;

  UserModel({
    required this.id,
    required this.fullName,
    required this.dob,
    required this.gender,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.rank = UserRank.silver,
  });

  /// Parse JSON từ Backend API response (login trả user object)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRank rank = UserRank.silver;
    final rankStr = (json['rank'] ?? json['hang'] ?? '').toString().toUpperCase();
    if (rankStr == 'GOLD' || rankStr == 'VÀNG') rank = UserRank.gold;
    if (rankStr == 'DIAMOND' || rankStr == 'KIM CƯƠNG') rank = UserRank.diamond;

    return UserModel(
      id: json['maTaiKhoan'] ?? json['mataikhoan'] ?? '',
      fullName: json['hoTen'] ?? json['hoten'] ?? '',
      dob: json['ngaysinh'] != null
          ? DateTime.tryParse(json['ngaysinh'].toString()) ?? DateTime(2000, 1, 1)
          : DateTime(2000, 1, 1),
      gender: json['gioitinh'] ?? 1,
      phone: json['sdt'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['anhdaidien'],
      rank: rank,
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    DateTime? dob,
    int? gender,
    String? phone,
    String? email,
    String? avatarUrl,
    UserRank? rank,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
    );
  }
}
