import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'order_tickets_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final List<dynamic> _history = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;      // Đang tải trang hiện tại
  bool _isFirstLoad = true;     // Lần tải đầu tiên
  bool _hasMore = true;         // Còn trang tiếp theo không
  String? _errorMessage;
  int _page = 1;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Kích hoạt tải thêm khi còn 200px đến cuối danh sách
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      final result = await ApiService.fetchBookingHistory(
        page: _page,
        limit: _limit,
      );

      if (!mounted) return;

      final newItems = (result['data'] as List?) ?? [];
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = pagination?['hasMore'] as bool? ?? false;

      setState(() {
        _history.addAll(newItems);
        _hasMore = hasMore;
        _page++;
        _isLoading = false;
        _isFirstLoad = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải lịch sử giao dịch';
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  /// Kéo xuống để tải lại từ đầu
  Future<void> _onRefresh() async {
    setState(() {
      _history.clear();
      _page = 1;
      _hasMore = true;
      _errorMessage = null;
      _isFirstLoad = true;
    });
    await _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _isFirstLoad
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null && _history.isEmpty
              ? _buildErrorView()
              : _history.isEmpty
                  ? const Center(child: Text('Bạn chưa có giao dịch nào'))
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        // +1 cho loading indicator hoặc "end of list" ở cuối
                        itemCount: _history.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          // Item cuối cùng: loading / hết dữ liệu
                          if (index == _history.length) {
                            return _buildListFooter();
                          }

                          final tx = _history[index];
                          return _buildTransactionCard(tx);
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
            'Đã hiển thị tất cả ${_history.length} giao dịch',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTransactionCard(dynamic tx) {
    bool isSuccess = tx['trangThai'] == 'paid' || tx['trangThai'] == 'completed';
    bool isCancelled = tx['trangThai'] == 'cancelled';

    String dateDisplay = '';
    if (tx['ngayDatVe'] != null) {
      try {
        final dt = DateTime.parse(tx['ngayDatVe']).toLocal();
        dateDisplay = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {
        dateDisplay = tx['ngayDatVe'];
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTicketsScreen(order: tx),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mã ĐH: ${tx['maDonDatVe']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green[50]
                        : (isCancelled ? Colors.red[50] : Colors.orange[50]),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSuccess ? 'Thành công' : (isCancelled ? 'Đã huỷ' : 'Đang chờ'),
                    style: TextStyle(
                      color: isSuccess
                          ? Colors.green[800]
                          : (isCancelled ? Colors.red[800] : Colors.orange[800]),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              tx['tenPhim'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(dateDisplay, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền', style: TextStyle(color: Colors.black87)),
                Text(
                  '${tx['tongTien']} VNĐ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? const Color(0xFFE51937) : Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
