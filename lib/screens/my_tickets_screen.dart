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
  final List<dynamic> _tickets = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _hasMore = true;
  String? _errorMessage;
  int _page = 1;
  static const int _limit = 10;

  // Lọc paid,completed ở server — không cần filter client-side nữa
  static const String _statusFilter = 'paid,completed';

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchTickets();
    }
  }

  Future<void> _fetchTickets() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.fetchBookingHistory(
        page: _page,
        limit: _limit,
        status: _statusFilter,
      );

      if (!mounted) return;

      final newItems = (result['data'] as List?) ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['hasMore'] as bool? ?? false;

      setState(() {
        _tickets.addAll(newItems);
        _hasMore = hasMore;
        _page++;
        _isLoading = false;
        _isFirstLoad = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải lịch sử vé';
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  /// Kéo xuống để tải lại từ đầu
  Future<void> _onRefresh() async {
    setState(() {
      _tickets.clear();
      _page = 1;
      _hasMore = true;
      _errorMessage = null;
      _isFirstLoad = true;
    });
    await _fetchTickets();
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
      body: _isFirstLoad
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _tickets.isEmpty
              ? _buildErrorView()
              : _tickets.isEmpty
                  ? const Center(child: Text('Bạn chưa có vé nào'))
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _tickets.length) {
                            return _buildListFooter();
                          }
                          return _buildTicketCard(_tickets[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Đã hiển thị tất cả ${_tickets.length} vé',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTicketCard(dynamic ticket) {
    // Parse ngayChieu + gioChieu để xác định phim đã chiếu chưa
    bool isUpcoming = true;
    String dateDisplay = ticket['ngayChieu']?.toString().split('T')[0] ?? '';
    String timeDisplay = ticket['gioChieu'] ?? '';

    if (dateDisplay.isNotEmpty && timeDisplay.isNotEmpty) {
      try {
        final dt = DateTime.parse('${dateDisplay}T$timeDisplay').toLocal();
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
            // Poster phim
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
            // Thông tin vé
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
                    // Giờ & Ngày chiếu
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_filled,
                          size: 14,
                          color: isUpcoming ? const Color(0xFFE51937) : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_formatTime(ticket['gioChieu'])} - ${_formatDate(ticket['ngayChieu'])}',
                            style: TextStyle(
                              color: isUpcoming ? const Color(0xFFE51937) : Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Rạp & Địa chỉ
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${ticket['tenRapPhim'] ?? 'N/A'} | ${ticket['diaChi'] != null && ticket['diaChi'].toString() != 'null' ? ticket['diaChi'] : ''}',
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Phòng & Ghế
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
                    // Badge trạng thái
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
  }

  String _formatDate(dynamic date) {
    if (date == null || date.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(date.toString()).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return date.toString().split('T')[0];
    }
  }

  String _formatTime(dynamic time) {
    if (time == null || time.toString().isEmpty) return '';
    try {
      final dt = DateTime.parse(time.toString()).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return time.toString();
    }
  }
}
