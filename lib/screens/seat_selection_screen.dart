import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'payment_screen.dart'; 

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().fetchSeatMap();
    });
  }

  // ============= Định nghĩa màu ghế =============
  // Ghế thường: xanh lam
  static const Color _normalColor = Color(0xFF2196F3);
  // Ghế VIP: đỏ
  static const Color _vipColor = Color(0xFFE53935);
  // Ghế Couple: hồng
  static const Color _coupleColor = Color(0xFFE91E63);
  // Ghế hỏng/không tồn tại: xám nhạt
  static const Color _brokenColor = Color(0xFFBDBDBD);
  // Ghế đã đặt: xám nhạt
  static const Color _bookedColor = Color(0xFF9E9E9E);
  // Ghế đang chọn: xanh lá cây
  static const Color _selectedColor = Color(0xFF4CAF50);

  /// Lấy màu ghế dựa trên loại ghế
  Color _getSeatColor(SeatData seat, bool isSelected) {
    if (seat.isBroken) return _brokenColor;
    if (seat.isBooked) return _bookedColor;
    if (isSelected) return _selectedColor;

    switch (seat.loaighe) {
      case 'vip':
        return _vipColor;
      case 'couple':
        return _coupleColor;
      case 'normal':
      default:
        return _normalColor;
    }
  }

  /// Lấy icon cho ghế
  IconData? _getSeatIcon(SeatData seat) {
    if (seat.isBroken) return Icons.block;
    if (seat.isBooked) return Icons.close;
    if (seat.loaighe == 'couple') return Icons.favorite;
    if (seat.loaighe == 'vip') return Icons.star;
    return null;
  }

  Widget _buildSeat(BuildContext context, BookingViewModel bookingVM, SeatData seat) {
    final isSelected = bookingVM.selectedSeats.contains(seat.maghe);
    final seatColor = _getSeatColor(seat, isSelected);
    final canTap = seat.isSelectable;
    final icon = _getSeatIcon(seat);

    return GestureDetector(
      onTap: canTap ? () => bookingVM.toggleSeat(seat.maghe) : null,
      child: AspectRatio(
        aspectRatio: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: Colors.white, width: 2)
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _selectedColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.8)),
              Text(
                seat.displayName,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white.withValues(alpha: seat.isBroken ? 0.5 : 1.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ô trống khi không có ghế tại vị trí
  Widget _buildEmptySeat() {
    return Container(
      margin: const EdgeInsets.all(3),
    );
  }

  /// Format giá tiền VNĐ
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingVM, child) {
        final movie = bookingVM.selectedMovie;
        
        if (bookingVM.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chọn Ghế', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black),
              elevation: 1,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final rows = bookingVM.seatRows;
        final maxCols = bookingVM.maxCols;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chọn Ghế', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 1,
          ),
          body: Column(
            children: [
              // Màn hình (Screen)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'MÀN HÌNH',
                    style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                ),
              ),
              
              // Sơ đồ ghế ngồi
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: rows.map((rowName) {
                        return Row(
                          children: [
                            // Label hàng (A, B, C...)
                            SizedBox(
                              width: 24,
                              child: Text(
                                rowName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            // Các ghế trong hàng
                            ...List.generate(maxCols, (colIndex) {
                              final seat = bookingVM.getSeatAt(rowName, colIndex + 1);
                              if (seat == null) return Expanded(child: _buildEmptySeat());
                              return Expanded(child: _buildSeat(context, bookingVM, seat));
                            }),
                            // Label hàng bên phải
                            SizedBox(
                              width: 24,
                              child: Text(
                                rowName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // Số cột ở dưới
              if (maxCols > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    children: List.generate(maxCols, (i) {
                      return Expanded(
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              const SizedBox(height: 8),
              
              // Chú thích (Legend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildLegendItem(_normalColor, 'Thường'),
                    _buildLegendItem(_vipColor, 'VIP'),
                    _buildLegendItem(_coupleColor, 'Couple'),
                    _buildLegendItem(_brokenColor, 'Không khả dụng'),
                    _buildLegendItem(_bookedColor, 'Đã đặt'),
                    _buildLegendItem(_selectedColor, 'Đang chọn'),
                  ],
                ),
              ),
            ],
          ),
          // Thanh thông tin đặt vé ở dưới
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie?.title ?? 'Chưa chọn phim',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bookingVM.selectedSeats.isNotEmpty 
                              ? 'Ghế: ${bookingVM.selectedSeats.map((id) {
                                  final s = bookingVM.getSeatData(id);
                                  return s?.displayName ?? id;
                                }).join(', ')}' 
                              : 'Chưa chọn ghế',
                          style: TextStyle(
                            color: bookingVM.selectedSeats.isNotEmpty ? _selectedColor : Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bookingVM.selectedSeats.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${_formatPrice(bookingVM.totalPrice)} VNĐ',
                              style: const TextStyle(
                                color: Color(0xFFE51937),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: bookingVM.selectedSeats.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PaymentScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE51937),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: const Text('TIẾP TỤC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
