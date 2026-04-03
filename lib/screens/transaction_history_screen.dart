import 'package:flutter/material.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data mô phỏng bảng DonDatVe và ThongTinThanhToan
    final List<Map<String, dynamic>> transactions = [
      {
        'maThanhToan': 'TT001',
        'maDonDatVe': 'DDV001',
        'ngayDat': '10/04/2024 10:15',
        'phuongThuc': 'VNPay',
        'tongTien': 200000,
        'trangThai': 'success',
        'tenPhim': 'DUNE: HÀNH TINH CÁT 2',
      },
      {
        'maThanhToan': 'TT002',
        'maDonDatVe': 'DDV002',
        'ngayDat': '05/03/2024 14:20',
        'phuongThuc': 'MoMo',
        'tongTien': 150000,
        'trangThai': 'success',
        'tenPhim': 'MAI',
      },
      {
        'maThanhToan': 'TT003',
        'maDonDatVe': 'DDV003',
        'ngayDat': '01/03/2024 09:00',
        'phuongThuc': 'VNPay',
        'tongTien': 180000,
        'trangThai': 'cancelled',
        'tenPhim': 'KUNG FU PANDA 4',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          bool isSuccess = tx['trangThai'] == 'success';

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
                    Text('Mã TT: ${tx['maThanhToan']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSuccess ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSuccess ? 'Thành công' : 'Đã huỷ',
                        style: TextStyle(
                          color: isSuccess ? Colors.green[800] : Colors.red[800],
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
                    Text(tx['ngayDat'], style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.payment, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Qua ${tx['phuongThuc']}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
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
