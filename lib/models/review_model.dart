class ReviewModel {
  final String maBinhLuan;
  final String noiDung;
  final int danhGia;
  final String thoiDiemDanhGia;
  final String hoTen;
  final String? anhDaiDien;

  ReviewModel({
    required this.maBinhLuan,
    required this.noiDung,
    required this.danhGia,
    required this.thoiDiemDanhGia,
    required this.hoTen,
    this.anhDaiDien,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      maBinhLuan: json['mabinhluan']?.toString() ?? '',
      noiDung: json['noidung']?.toString() ?? '',
      danhGia: int.tryParse(json['danhgia']?.toString() ?? '10') ?? 10,
      thoiDiemDanhGia: json['thoidiemdanhgia']?.toString() ?? '',
      hoTen: json['hoten']?.toString() ?? 'Khách',
      anhDaiDien: json['anhdaidien']?.toString(),
    );
  }
}
