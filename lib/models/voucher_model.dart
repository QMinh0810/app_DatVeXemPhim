enum UserRank { silver, gold, diamond }

extension UserRankExtension on UserRank {
  String get name {
    switch (this) {
      case UserRank.silver:
        return 'Bạc';
      case UserRank.gold:
        return 'Vàng';
      case UserRank.diamond:
        return 'Kim cương';
    }
  }

  String get id {
    switch (this) {
      case UserRank.silver:
        return 'SILVER';
      case UserRank.gold:
        return 'GOLD';
      case UserRank.diamond:
        return 'DIAMOND';
    }
  }
}

class VoucherModel {
  final String id;
  final String title;
  final String description;
  final double discountAmount;
  final double percentage; // 0.0 to 1.0 (e.g. 0.1 for 10%)
  final double minOrderValue;
  final double maxDiscount;
  final DateTime expiryDate;
  final String type; // 'shipping', 'discount', 'cashback'
  final UserRank minRank;
  final String? imageUrl;
  final bool isSelected;
  final bool isEligible;
  final String? reason;

  VoucherModel({
    required this.id,
    required this.title,
    required this.description,
    this.discountAmount = 0,
    this.percentage = 0,
    required this.minOrderValue,
    this.maxDiscount = double.infinity,
    required this.expiryDate,
    required this.type,
    required this.minRank,
    this.imageUrl,
    this.isSelected = false,
    this.isEligible = true,
    this.reason,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    UserRank rank = UserRank.silver;
    final rankStr = json['dieukien_rank']?.toString().toUpperCase() ?? 'TAT_CA_USER';
    if (rankStr == 'GOLD') rank = UserRank.gold;
    if (rankStr == 'DIAMOND') rank = UserRank.diamond;

    return VoucherModel(
      id: json['mavoucher']?.toString() ?? '',
      title: json['ten']?.toString() ?? '',
      description: json['mota']?.toString() ?? '',
      discountAmount: (json['sotien_giam'] ?? 0).toDouble(),
      percentage: (json['phantram_giam'] ?? 0).toDouble(),
      minOrderValue: (json['donhang_toithieu'] ?? 0).toDouble(),
      maxDiscount: (json['giam_toi_da'] ?? double.infinity).toDouble(),
      expiryDate: json['han_sudung'] != null 
          ? DateTime.tryParse(json['han_sudung'].toString()) ?? DateTime.now()
          : DateTime.now(),
      type: json['loai']?.toString() ?? 'discount',
      minRank: rank,
      isEligible: json['is_eligible'] ?? true,
      reason: json['reason']?.toString(),
    );
  }

  VoucherModel copyWith({bool? isSelected}) {
    return VoucherModel(
      id: id,
      title: title,
      description: description,
      discountAmount: discountAmount,
      percentage: percentage,
      minOrderValue: minOrderValue,
      maxDiscount: maxDiscount,
      expiryDate: expiryDate,
      type: type,
      minRank: minRank,
      imageUrl: imageUrl,
      isSelected: isSelected ?? this.isSelected,
      isEligible: isEligible,
      reason: reason,
    );
  }
}
