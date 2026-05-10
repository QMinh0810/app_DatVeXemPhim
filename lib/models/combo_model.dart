class ComboData {
  final int comboId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  ComboData({
    required this.comboId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  factory ComboData.fromJson(Map<String, dynamic> json) {
    return ComboData(
      comboId: json['combo_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url']?.toString() ?? '',
    );
  }
}
