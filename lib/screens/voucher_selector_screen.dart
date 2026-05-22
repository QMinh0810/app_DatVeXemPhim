import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/voucher_model.dart';
import '../widgets/voucher_card.dart';

class VoucherSelectorScreen extends StatefulWidget {
  const VoucherSelectorScreen({super.key});

  @override
  State<VoucherSelectorScreen> createState() => _VoucherSelectorScreenState();
}

class _VoucherSelectorScreenState extends State<VoucherSelectorScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
      bookingVM.fetchVouchers(authVM.currentUser?.rank ?? UserRank.silver);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Chọn Voucher', style: TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFFEE4D2D)),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, color: Colors.grey),
          )
        ],
      ),
      body: Column(
        children: [
          // Search/Input Code bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập mã voucher',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.grey[600],
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    minimumSize: const Size(80, 40),
                  ),
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // VIP Ticket Banner (The "Shopee VIP" equivalent)
          Consumer<AuthViewModel>(
            builder: (context, authVM, child) {
              final rank = authVM.currentUser?.rank ?? UserRank.silver;
              Color rankColor = const Color(0xFFEE4D2D);
              if (rank == UserRank.gold) rankColor = const Color(0xFFFFB300);
              if (rank == UserRank.diamond) rankColor = const Color(0xFF1E88E5);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [rankColor.withOpacity(0.1), Colors.white],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border.all(color: rankColor.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: rankColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HẠNG ${rank.name.toUpperCase()}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nhận Voucher giảm đến ${rank == UserRank.diamond ? "35%" : rank == UserRank.gold ? "20%" : "10%"} cho thành viên ${rank.name}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Voucher List
          Expanded(
            child: Consumer<BookingViewModel>(
              builder: (context, bookingVM, child) {
                final vouchers = bookingVM.availableVouchers;
                
                if (vouchers.isEmpty) {
                  return const Center(
                    child: Text('Không có voucher khả dụng'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: vouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = vouchers[index];
                    final isSelected = bookingVM.selectedVoucher?.id == voucher.id;
                    
                    return VoucherCard(
                      voucher: voucher,
                      isSelected: isSelected,
                      onTap: () {
                        if (isSelected) {
                          bookingVM.selectVoucher(null);
                        } else {
                          bookingVM.selectVoucher(voucher);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Consumer<BookingViewModel>(
                    builder: (context, bookingVM, child) {
                      return Text(
                        bookingVM.selectedVoucher != null 
                          ? 'Đã chọn 1 voucher' 
                          : 'Vui lòng chọn voucher',
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEE4D2D),
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('Đồng ý', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
