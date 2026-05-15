import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'combo_selection_screen.dart'; 
import 'package:intl/intl.dart';
import 'dart:async';

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

  @override
  void dispose() {
    super.dispose();
  }

  // ============= Định nghĩa màu sắc & Style =============
  static const Color _brandColor = Color(0xFFE51937);
  static const Color _selectedColor = Color(0xFF5CC00F);
  static const Color _bookedColor = Color(0xFFCED4DA);
  static const Color _lockedByOtherColor = Color(0xFFADB5BD);
  static const Color _vipColor = Color(0xFFFFA000);
  static const Color _coupleColor = Color(0xFFD81B60);
  static const Color _normalColor = Colors.white;
  static const Color _seatBorderColor = Color(0xFFE9ECEF);
  static const Color _brokenColor = Color(0xFFF8F9FA);

  Color _getSeatColor(SeatData seat, bool isSelected) {
    if (seat.isBroken) return _brokenColor;
    if (seat.isBooked) return _bookedColor;
    if (seat.isLockedByMe || isSelected) return _selectedColor;
    if (seat.isLockedByOther) return _lockedByOtherColor;

    switch (seat.loaighe) {
      case 'vip': return _vipColor;
      case 'couple': return _coupleColor;
      default: return _normalColor;
    }
  }

  Widget _buildSeat(BuildContext context, BookingViewModel bookingVM, SeatData seat) {
    final isSelected = bookingVM.selectedSeats.contains(seat.maghe);
    final seatColor = _getSeatColor(seat, isSelected);
    final bool isSpecial = seat.loaighe == 'vip';
    final bool isAvailable = seat.isSelectable && !seat.isLockedByOther;

    return GestureDetector(
      onTap: seat.isSelectable ? () => bookingVM.toggleSeat(seat.maghe) : null,
      child: Container(
        margin: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(4.5),
          border: Border.all(
            color: (isSelected || seat.isLockedByMe) 
                ? _selectedColor 
                : (seat.isBooked || seat.isLockedByOther) 
                    ? Colors.transparent 
                    : isSpecial ? _vipColor : const Color(0xFFE9ECEF),
            width: 1.2,
          ),
          boxShadow: (isSelected || seat.isLockedByMe) ? [
            BoxShadow(color: _selectedColor.withOpacity(0.3), blurRadius: 4, spreadRadius: 1)
          ] : null,
        ),
        alignment: Alignment.center,
        child: Visibility(
          visible: !seat.isBooked && !seat.isLockedByOther && !seat.isBroken,
          replacement: seat.isBooked 
            ? const Icon(Icons.close, size: 8, color: Colors.white70) 
            : const SizedBox(),
          child: Text(
            seat.displayName,
            style: TextStyle(
              fontSize: 7.5, 
              color: (isSelected || isSpecial || seat.isLockedByMe) ? Colors.white : Colors.black45, 
              fontWeight: FontWeight.bold
            ),
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
      child: Container(
        margin: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isSelected || seat.isLockedByMe) ? _selectedColor : const Color(0xFFE9ECEF),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, size: 10, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              seat.displayName,
              style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingViewModel>(
      builder: (context, bookingVM, child) {
        if (bookingVM.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(_brandColor))),
          );
        }

        final rows = bookingVM.seatRows;
        final maxCols = bookingVM.maxCols;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Column(
              children: [
                Text(bookingVM.selectedMovie?.title ?? 'Chọn ghế', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                Text('${bookingVM.selectedTheaterName} | ${bookingVM.selectedRoomName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(onPressed: () => bookingVM.fetchSeatMap(), icon: const Icon(Icons.refresh, size: 20)),
            ],
          ),
          body: PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) bookingVM.releaseSeats();
            },
            child: Column(
              children: [
                // Screen Visual
                const SizedBox(height: 10),
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _brandColor.withOpacity(0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9ECEF),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: _brandColor.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('MÀN HÌNH', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 4)),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
  
                // Sơ đồ ghế
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 2.0,
                    boundaryMargin: const EdgeInsets.all(40),
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: rows.map((rowName) {
                                bool isCoupleRow = false;
                                for (int col = 1; col <= maxCols; col++) {
                                  final seat = bookingVM.getSeatAt(rowName, col);
                                  if (seat != null && seat.loaighe == 'couple') {
                                    isCoupleRow = true;
                                    break;
                                  }
                                }
        
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 25, child: Text(rowName, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                      ...(isCoupleRow 
                                        ? List.generate(maxCols ~/ 2, (index) {
                                            int col = index + 1;
                                            final seat = bookingVM.getSeatAt(rowName, col);
                                            Widget seatWidget = seat != null 
                                                ? SizedBox(width: 70, height: 35, child: _buildCoupleSeat(context, bookingVM, seat))
                                                : const SizedBox(width: 70, height: 35);
                                            return [seatWidget];
                                          }).expand((x) => x).toList()
                                        : List.generate(maxCols, (colIndex) {
                                            int col = colIndex + 1;
                                            final seat = bookingVM.getSeatAt(rowName, col);
                                            Widget seatWidget = seat != null 
                                                ? SizedBox(width: 35, height: 35, child: _buildSeat(context, bookingVM, seat))
                                                : const SizedBox(width: 35, height: 35);
                                            
                                            if (col == 4) {
                                              return [seatWidget, const SizedBox(width: 20)];
                                            }
                                            return [seatWidget];
                                          }).expand((x) => x).toList()
                                      ),
                                      SizedBox(width: 25, child: Text(rowName, textAlign: TextAlign.right, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
  
                _buildLegend(),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(bookingVM),
        );
      },
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(_normalColor, 'Thường', hasBorder: true),
              _legendItem(_vipColor, 'VIP'),
              _legendItem(_coupleColor, 'Couple'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legendItem(_bookedColor, 'Đã mua'),
              _legendItem(_selectedColor, 'Đang chọn'),
              _legendItem(_lockedByOtherColor, 'Đang giữ'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, {bool hasBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14, 
          height: 14, 
          decoration: BoxDecoration(
            color: color, 
            borderRadius: BorderRadius.circular(3),
            border: hasBorder ? Border.all(color: const Color(0xFFE9ECEF)) : null,
          )
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomBar(BookingViewModel bookingVM) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
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
                    ? 'Chưa chọn ghế' 
                    : '${bookingVM.selectedSeats.length} ghế: ${bookingVM.selectedSeats.map((id) => bookingVM.getSeatData(id)?.displayName ?? id).join(', ')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(bookingVM.totalPrice),
                  style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: bookingVM.selectedSeats.isEmpty ? null : () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ComboSelectionScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('TIẾP TỤC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

}
