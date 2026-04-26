import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await ApiService.fetchBookingHistory();
      if (mounted) {
        setState(() {
          // Chỉ hiển thị các đơn vé đã thanh toán thành công (trangThai == 'paid')
          _history = history.where((h) => h['trangThai'] == 'paid' || h['trangThai'] == 'completed').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử vé';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Vé Của Tôi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _history.isEmpty
            ? const Center(child: Text('Bạn chưa có vé nào'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final ticket = _history[index];
                  // parse dateTime để so sánh xem phim đã chiếu chưa
                  bool isUpcoming = true;
                  String dateDisplay = ticket['ngayChieu']?.toString().split('T')[0] ?? '';
                  String timeDisplay = ticket['gioChieu'] ?? '';
                  
                  if (dateDisplay.isNotEmpty && timeDisplay.isNotEmpty) {
                    try {
                       final dt = DateTime.parse('${dateDisplay}T$timeDisplay');
                       if (dt.isBefore(DateTime.now())) {
                         isUpcoming = false;
                       }
                    } catch (_) {}
                  }

                  String seats = '';
                  if (ticket['tickets'] != null) {
                    seats = (ticket['tickets'] as List).map((t) => t['maGhe']).join(', ');
                  }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              children: [
                // Ticket Image (Poster)
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                  child: Image.network(
                    ticket['posterUrl'] ?? '',
                    width: 100,
                    height: 160,
                    fit: BoxFit.cover,
                    color: isUpcoming ? null : Colors.black.withOpacity(0.5),
                    colorBlendMode: isUpcoming ? null : BlendMode.darken,
                    errorBuilder: (c, e, s) => Container(width: 100, height: 160, color: Colors.grey[300]),
                  ),
                ),
                // Ticket Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(ticket['tenPhim'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis,)),
                            if (isUpcoming) const Icon(Icons.qr_code_2, color: Color(0xFFE51937))
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$timeDisplay - $dateDisplay', style: TextStyle(color: isUpcoming ? const Color(0xFFE51937) : Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(ticket['tenRapPhim'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Phòng: ${ticket['tenPhong'] ?? ''} | Ghế: $seats', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: isUpcoming ? Colors.green : Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUpcoming ? 'SẮP CHIẾU' : 'ĐÃ XEM',
                            style: TextStyle(color: isUpcoming ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
