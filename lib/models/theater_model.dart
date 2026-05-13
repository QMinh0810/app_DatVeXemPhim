class TheaterModel {
  final String id;
  final String name;
  final String address;

  TheaterModel({
    required this.id,
    required this.name,
    required this.address,
  });

  factory TheaterModel.fromJson(Map<String, dynamic> json) {
    return TheaterModel(
      id: json['marapphim']?.toString() ?? '',
      name: json['tenrapphim']?.toString() ?? '',
      address: json['diachi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'marapphim': id,
      'tenrapphim': name,
      'diachi': address,
    };
  }
}
