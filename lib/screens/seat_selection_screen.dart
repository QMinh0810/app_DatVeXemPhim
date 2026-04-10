import 'package:flutter/material.dart';
import 'payment_screen.dart'; // We will skip combo and go to payment

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final int rows = 12; // Thay đổi số lượng ghế
  final int cols = 14; 
  final List<String> selectedSeats = [];

  Widget _buildSeat(int row, int col, [bool isCoupleRow = false]) {
    String seatName = isCoupleRow 
        ? 'SW${col + 1}' // Tên ghế Sweetbox (Couple)
        : '${String.fromCharCode(65 + row)}${col + 1}';
    bool isSelected = selectedSeats.contains(seatName);

    // Mock booked seats
    bool isBooked = (row == 5 && (col == 6 || col == 7)) || (row == 8 && (col == 4 || col == 5));
    // Mock VIP seats (middle rows)
    bool isVip = (row >= 6 && row <= 9);
    // Mock Sweetbox / Couple
    bool isCouple = isCoupleRow;

    Color seatColor = Colors.grey[400]!;
    if (isBooked) seatColor = Colors.black26;
    else if (isSelected) seatColor = const Color(0xFFE51937);
    else if (isVip) seatColor = Colors.pink[200]!;
    else if (isCouple) seatColor = Colors.red[900]!;

    // Tính toán kích thước ghế để ghế couple vừa bằng 2 ghế thường gộp lại
    double seatWidth = isCouple ? 70.0 : 32.0; 

    return GestureDetector(
      onTap: isBooked ? null : () {
        setState(() {
          if (isSelected) {
            selectedSeats.remove(seatName);
          } else {
            selectedSeats.add(seatName);
          }
        });
      },
      child: Container(
        width: seatWidth,
        height: 32,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: isBooked 
            ? const Icon(Icons.close, size: 14, color: Colors.white)
            : Text(
                seatName, 
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Ghế', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Screen shape
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
          
          Expanded(
            child: InteractiveViewer(
              constrained: false, // Giúp các ghế không bị co rút cắt xén khi quá nhỏ
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 3.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(rows, (row) {
                    bool isCoupleRow = (row == 11);
                    int colsInRow = isCoupleRow ? cols ~/ 2 : cols;
                    
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(colsInRow, (col) {
                        Widget seat = _buildSeat(row, col, isCoupleRow);
                        
                        // Tạo lối đi (aisle) ngang 40px ở giữa rạp
                        if (!isCoupleRow && col == 6) {
                          // Chia đều 7 ghế trái, 7 ghế phải
                          return Row(mainAxisSize: MainAxisSize.min, children: [seat, const SizedBox(width: 40)]);
                        } else if (isCoupleRow && col == 2) {
                          // Hàng Couple (7 ghế), chia 3 ghế trái, 4 ghế phải để bảo toàn tổng chiều rộng
                          return Row(mainAxisSize: MainAxisSize.min, children: [seat, const SizedBox(width: 40)]);
                        }
                        
                        return seat;
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
          
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.grey[400]!, 'Thường'),
                _buildLegendItem(Colors.pink[200]!, 'VIP'),
                _buildLegendItem(Colors.red[900]!, 'Couple'),
                _buildLegendItem(const Color(0xFFE51937), 'Đang chọn'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DUNE: HÀNH TINH CÁT 2', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    selectedSeats.isNotEmpty 
                        ? 'Ghế: ${selectedSeats.join(', ')}' 
                        : 'Chưa chọn ghế',
                    style: TextStyle(color: selectedSeats.isNotEmpty ? const Color(0xFFE51937) : Colors.grey),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: selectedSeats.isEmpty ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE51937),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text('TIẾP TỤC', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
