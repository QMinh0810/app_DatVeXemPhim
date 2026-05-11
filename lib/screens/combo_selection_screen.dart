import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../models/combo_model.dart';
import 'payment_screen.dart';

class ComboSelectionScreen extends StatefulWidget {
  const ComboSelectionScreen({super.key});

  @override
  State<ComboSelectionScreen> createState() => _ComboSelectionScreenState();
}

class _ComboSelectionScreenState extends State<ComboSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingViewModel>().fetchCombos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Bắp Nước', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Consumer<BookingViewModel>(
        builder: (context, bookingVM, child) {
          if (bookingVM.availableCombos.isEmpty) {
            return const Center(child: Text('Chưa có danh sách bắp nước.'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookingVM.availableCombos.length,
            itemBuilder: (context, index) {
              final combo = bookingVM.availableCombos[index];
              final quantity = bookingVM.getComboQuantity(combo.comboId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  children: [
                    // Hình ảnh
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: combo.imageUrl.isNotEmpty
                            ? Image.network(
                                combo.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                              )
                            : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Thông tin combo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            combo.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat('#,###').format(combo.price) + ' VNĐ',
                            style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (combo.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              combo.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Nút tăng giảm
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 0 ? () => bookingVM.removeCombo(combo.comboId) : null,
                          icon: Icon(Icons.remove_circle_outline, color: quantity > 0 ? const Color(0xFFE51937) : Colors.grey),
                        ),
                        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          onPressed: () => bookingVM.addCombo(combo.comboId),
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE51937)),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<BookingViewModel>(
        builder: (context, bookingVM, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (bookingVM.selectedCombos.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Danh sách đã chọn:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: SingleChildScrollView(
                      child: Column(
                        children: bookingVM.selectedCombos.entries.map((e) {
                          final c = bookingVM.availableCombos.firstWhere(
                            (combo) => combo.comboId == e.key,
                            orElse: () => ComboData(comboId: 0, name: 'Unknown', description: '', price: 0, imageUrl: ''),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text('${c.name} (x${e.value})', style: const TextStyle(fontSize: 13))),
                                Text('${NumberFormat('#,###').format(c.price * e.value)} đ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TỔNG CỘNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            '${NumberFormat('#,###').format(bookingVM.totalPrice)} VNĐ',
                            style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE51937),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
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
