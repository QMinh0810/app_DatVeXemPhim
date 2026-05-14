import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'order_tickets_screen.dart';

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
                    seats = (ticket['tickets'] as List).map((t) => t['tenGhe'] ?? t['maGhe']).join(', ');
                  }

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderTicketsScreen(order: ticket),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Ticket Image (Poster)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Image.network(
                      ticket['posterUrl'] ?? '',
                      width: 110,
                      height: 165,
                      fit: BoxFit.cover,
                      color: isUpcoming ? null : Colors.black.withOpacity(0.5),
                      colorBlendMode: isUpcoming ? null : BlendMode.darken,
                      errorBuilder: (c, e, s) => Container(
                        width: 110,
                        height: 165,
                        color: Colors.grey[200],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    ),
                  ),
                  // Ticket Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  ticket['tenPhim'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isUpcoming)
                                const Icon(Icons.qr_code_2, color: Color(0xFFE51937), size: 20),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Time & Date
                          Row(
                            children: [
                              Icon(Icons.access_time_filled, size: 14, color: isUpcoming ? const Color(0xFFE51937) : Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                '${ticket['gioChieu']} - ${ticket['ngayChieu']}',
                                style: TextStyle(
                                  color: isUpcoming ? const Color(0xFFE51937) : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Cinema & Address
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${ticket['tenRapPhim']} | ${ticket['diaChi'] ?? ''}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Room & Seats
                          Row(
                            children: [
                              const Icon(Icons.chair, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'P: ${ticket['tenPhong'] ?? ''} | Ghế: $seats',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isUpcoming ? const Color(0xFFE8F5E9) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isUpcoming ? 'SẮP CHIẾU' : 'ĐÃ XEM',
                              style: TextStyle(
                                color: isUpcoming ? Colors.green[700] : Colors.grey[600],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
