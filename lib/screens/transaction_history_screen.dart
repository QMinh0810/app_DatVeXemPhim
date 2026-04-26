import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
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
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử giao dịch';
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
        title: const Text('Lịch Sử Giao Dịch', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
          : _history.isEmpty
            ? const Center(child: Text('Bạn chưa có giao dịch nào'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final tx = _history[index];
                  bool isSuccess = tx['trangThai'] == 'paid' || tx['trangThai'] == 'completed';
                  bool isCancelled = tx['trangThai'] == 'cancelled';
                  
                  String dateDisplay = '';
                  if (tx['ngayDatVe'] != null) {
                    try {
                      final dt = DateTime.parse(tx['ngayDatVe']);
                      dateDisplay = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                    } catch (_) {
                      dateDisplay = tx['ngayDatVe'];
                    }
                  }

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mã ĐH: ${tx['maDonDatVe']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green[50] : (isCancelled ? Colors.red[50] : Colors.orange[50]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSuccess ? 'Thành công' : (isCancelled ? 'Đã huỷ' : 'Đang chờ'),
                        style: TextStyle(
                          color: isSuccess ? Colors.green[800] : (isCancelled ? Colors.red[800] : Colors.orange[800]),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(tx['tenPhim'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(dateDisplay, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                // Row(
                //   children: [
                //     const Icon(Icons.payment, size: 16, color: Colors.grey),
                //     const SizedBox(width: 8),
                //     Text('Qua ${tx['phuongThuc'] ?? 'MoMo'}', style: const TextStyle(color: Colors.grey)),
                //   ],
                // ),
                // const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(color: Colors.black87)),
                    Text('${tx['tongTien']} VNĐ', style: TextStyle(fontWeight: FontWeight.bold, color: isSuccess ? const Color(0xFFE51937) : Colors.grey, fontSize: 16)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
