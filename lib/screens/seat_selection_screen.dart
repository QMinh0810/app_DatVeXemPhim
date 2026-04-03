import 'package:flutter/material.dart';
import 'payment_screen.dart'; // We will skip combo and go to payment

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final int rows = 8;
  final int cols = 8;
  final List<String> selectedSeats = [];

  Widget _buildSeat(int row, int col) {
    String seatName = '${String.fromCharCode(65 + row)}${col + 1}';
    bool isSelected = selectedSeats.contains(seatName);

    // Mock booked seats
    bool isBooked = (row == 3 && (col == 3 || col == 4));
    // Mock VIP seats (middle rows)
    bool isVip = (row >= 4 && row <= 6);
    // Mock Sweetbox / Couple (last row)
    bool isCouple = (row == 7);

    Color seatColor = Colors.grey[400]!;
    if (isBooked) seatColor = Colors.black26;
    else if (isSelected) seatColor = const Color(0xFFE51937);
    else if (isVip) seatColor = Colors.pink[200]!;
    else if (isCouple) seatColor = Colors.red[900]!;

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
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? Border.all(color: Colors.red, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: isBooked 
            ? const Icon(Icons.close, size: 16, color: Colors.white)
            : Text(seatName, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                  ),
                  itemCount: rows * cols,
                  itemBuilder: (context, index) {
                    int r = index ~/ cols;
                    int c = index % cols;
                    return _buildSeat(r, c);
                  },
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
