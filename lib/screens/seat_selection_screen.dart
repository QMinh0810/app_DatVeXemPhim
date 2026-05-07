import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'payment_screen.dart'; 
import 'package:intl/intl.dart';
import 'dart:async';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().fetchSeatMap();
    });
    
    // Thiết lập tự động làm mới mỗi 10 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        context.read<BookingViewModel>().fetchSeatMap(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // ============= Định nghĩa màu ghế =============
  static const Color _normalColor = Color(0xFF2196F3);
  static const Color _vipColor = Color(0xFFE53935);
  static const Color _coupleColor = Color(0xFFE91E63);
  static const Color _brokenColor = Color(0xFFBDBDBD);
  static const Color _bookedColor = Color(0xFF9E9E9E);
  static const Color _selectedColor = Color(0xFF4CAF50);

  Color _getSeatColor(SeatData seat, bool isSelected) {
    if (seat.isBroken) return _brokenColor;
    if (seat.isBooked) return _bookedColor;
    if (isSelected) return _selectedColor;

    switch (seat.loaighe) {
      case 'vip': return _vipColor;
      case 'couple': return _coupleColor;
      default: return _normalColor;
    }
  }

  Widget _buildSeat(BuildContext context, BookingViewModel bookingVM, SeatData seat) {
    final isSelected = bookingVM.selectedSeats.contains(seat.maghe);
    final seatColor = _getSeatColor(seat, isSelected);
    
    return GestureDetector(
      onTap: seat.isSelectable ? () => bookingVM.toggleSeat(seat.maghe) : null,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            seat.displayName,
            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildCoupleSeat(BuildContext context, BookingViewModel bookingVM, SeatData seat) {
    final isSelected = bookingVM.selectedSeats.contains(seat.maghe);
    final seatColor = _getSeatColor(seat, isSelected);

    return GestureDetector(
      onTap: seat.isSelectable ? () => bookingVM.toggleSeat(seat.maghe) : null,
      child: AspectRatio(
        aspectRatio: 2.0,
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: seatColor,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: Text(
            seat.displayName,
            style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingVM, child) {
        if (bookingVM.isLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chọn Ghế', style: TextStyle(color: Colors.black))),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final rows = bookingVM.seatRows;
        final maxCols = bookingVM.maxCols;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chọn Ghế', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: Column(
            children: [
              // Màn hình
              const SizedBox(height: 20),
              const Center(child: Text('MÀN HÌNH', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 8))),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 60),
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
              
              const SizedBox(height: 30),

              // Sơ đồ ghế
              Expanded(
                child: InteractiveViewer(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: rows.map((rowName) {
                        // Kiểm tra xem hàng này có phải hàng ghế đôi không dựa trên dữ liệu thực tế
                        bool isCoupleRow = false;
                        for (int col = 1; col <= maxCols; col++) {
                          final seat = bookingVM.getSeatAt(rowName, col);
                          if (seat != null && seat.loaighe == 'couple') {
                            isCoupleRow = true;
                            break;
                          }
                        }

                        return Row(
                          children: [
                            // Label trái
                            SizedBox(width: 20, child: Text(rowName, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                            
                            // Các cột ghế
                            ...(isCoupleRow 
                              ? List.generate(maxCols ~/ 2, (index) {
                                  int col = index + 1;
                                  final seat = bookingVM.getSeatAt(rowName, col);
                                  
                                  Widget seatWidget = seat != null 
                                      ? _buildCoupleSeat(context, bookingVM, seat) 
                                      : const SizedBox();
                                      
                                  // Chèn lối đi sau ghế thứ 2
                                  if (index == 1) { 
                                    return [
                                      Expanded(flex: 2, child: seatWidget),
                                      const SizedBox(width: 24),
                                    ];
                                  }
                                  return [Expanded(flex: 2, child: seatWidget)];
                                }).expand((x) => x).toList()
                              : List.generate(maxCols, (colIndex) {
                                  int col = colIndex + 1;
                                  final seat = bookingVM.getSeatAt(rowName, col);
                                  
                                  Widget seatWidget = seat != null 
                                      ? _buildSeat(context, bookingVM, seat) 
                                      : const SizedBox();
                                  
                                  // Chèn lối đi ở giữa (sau cột 4)
                                  if (col == 4) {
                                    return [
                                      Expanded(child: seatWidget),
                                      const SizedBox(width: 24), // Lối đi giữa
                                    ];
                                  }

                                  return [Expanded(child: seatWidget)];
                                }).expand((x) => x).toList()
                            ),

                            // Label phải
                            SizedBox(width: 20, child: Text(rowName, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              _buildLegend(),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(bookingVM),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _legendItem(_normalColor, 'Thường'),
          _legendItem(_vipColor, 'VIP'),
          _legendItem(_coupleColor, 'Couple'),
          _legendItem(_bookedColor, 'Đã đặt'),
          _legendItem(_selectedColor, 'Đang chọn'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }

  Widget _buildBottomBar(BookingViewModel bookingVM) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookingVM.selectedSeats.isEmpty 
                      ? 'CHƯA CHỌN GHẾ' 
                      : 'GHẾ: ${bookingVM.selectedSeats.map((id) => bookingVM.getSeatData(id)?.displayName ?? id).join(', ')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${NumberFormat('#,###').format(bookingVM.totalPrice)} VNĐ',
                    style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: bookingVM.selectedSeats.isEmpty ? null : () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51937),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
