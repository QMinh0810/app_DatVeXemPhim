import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ticket_detail_screen.dart';

class OrderTicketsScreen extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderTicketsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final tickets = order['tickets'] as List<dynamic>;
    final bool isUpcoming = _checkIfUpcoming(order['ngayChieu'], order['gioChieu']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Đơn Hàng #${order['maDonDatVe']}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Order Summary Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D000000),
                  offset: Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['tenPhim'] ?? 'Tên phim',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Color(0xFFE51937)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['tenRapPhim'] ?? 'N/A'} - ${order['tenPhong'] ?? ''}',
                            style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (order['diaChi'] != null && order['diaChi'].toString() != 'null')
                             Text(
                               order['diaChi'],
                               style: const TextStyle(color: Colors.grey, fontSize: 12),
                               maxLines: 1,
                               overflow: TextOverflow.ellipsis,
                             ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFFE51937)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_formatTime(order['gioChieu'])} - ${_formatDate(order['ngayChieu'])}',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách vé (${tickets.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF495057),
                  ),
                ),
                if (!isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'ĐÃ XEM',
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _buildTicketCard(context, ticket, isUpcoming);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Map<String, dynamic> ticket, bool isUpcoming) {
    final bool isCancelled = order['trangThai'] == 'cancelled';
    final bool isAccessible = isUpcoming && !isCancelled;

    return GestureDetector(
      onTap: () {
        if (isAccessible) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailScreen(ticket: ticket, order: order),
            ),
          );
        } else if (!isUpcoming && !isCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phim đã chiếu xong, không thể xem chi tiết vé'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Opacity(
          opacity: isAccessible ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Ticket Icon/Visual
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isAccessible ? const Color(0xFFFFF0F3) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.confirmation_number,
                    color: isAccessible ? const Color(0xFFE51937) : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Ticket Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ghế: ${ticket['tenGhe']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212529),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã vé: ${ticket['maVe']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ticket['giaVe']} đ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isAccessible ? const Color(0xFFE51937) : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isAccessible)
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xFFADB5BD),
                      )
                    else
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return date.toString().split('T')[0];
    }
  }

  String _formatTime(dynamic time) {
    if (time == null || time.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(time.toString());
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return time.toString();
    }
  }

  bool _checkIfUpcoming(dynamic date, dynamic time) {
    if (date == null || time == null) return true;
    try {
      final dateStr = date.toString().split('T')[0];
      final dt = DateTime.parse('${dateStr}T$time');
      return dt.isAfter(DateTime.now());
    } catch (_) {
      return true;
    }
  }
}
