class NotificationModel {
  final String maThongBao;
  final String tieuDe;
  final String noiDung;
  final String trangThai; // 'unread' | 'read'
  final DateTime thoiDiemTB;
  final String? maDonDatVe;
  final String? maPhim;
  final String? tenPhim;
  final String? posterUrl;

  NotificationModel({
    required this.maThongBao,
    required this.tieuDe,
    required this.noiDung,
    required this.trangThai,
    required this.thoiDiemTB,
    this.maDonDatVe,
    this.maPhim,
    this.tenPhim,
    this.posterUrl,
  });

  bool get isUnread => trangThai == 'unread';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final phim = json['phim'];
    return NotificationModel(
      maThongBao: json['maThongBao']?.toString() ?? '',
      tieuDe: json['tieuDe']?.toString() ?? '',
      noiDung: json['noiDung']?.toString() ?? '',
      trangThai: json['trangThai']?.toString() ?? 'unread',
      thoiDiemTB: (DateTime.tryParse(json['thoiDiemTB']?.toString() ?? '') ?? DateTime.now())
          .toLocal()
          .add(const Duration(hours: 7)), // Fix cho lỗi lệch múi giờ 7 tiếng từ Backend
      maDonDatVe: json['maDonDatVe']?.toString(),
      maPhim: phim?['maPhim']?.toString(),
      tenPhim: phim?['tenPhim']?.toString(),
      posterUrl: phim?['posterUrl']?.toString(),
    );
  }
}
