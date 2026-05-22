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
  final double percentage; // 0.0 to 1.0
  final double minOrderValue;
  final double maxDiscount;
  final DateTime expiryDate;
  final String type; // 'shipping', 'discount', 'cashback'
  final UserRank minRank;
  final String? imageUrl;
  final bool isSelected;

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
  });

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
    );
  }
}
