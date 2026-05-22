import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'home_screen.dart';
import 'payment_waiting_screen.dart';
import 'voucher_selector_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');

    return Consumer<BookingViewModel>(
      builder: (context, bookingVM, child) {
        final movie = bookingVM.selectedMovie;
        final seats = bookingVM.selectedSeats;

        if (movie == null || seats.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Thanh Toán')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    movie == null ? 'Chưa chọn phim' : 'Chưa chọn ghế',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Quay lại'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Thanh Toán', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 1,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THÔNG TIN GIAO DỊCH', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Phim: ${movie.title}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Rạp: ${bookingVM.selectedTheaterName ?? "Chưa rõ"}'),
                      Text('Phòng: ${bookingVM.selectedRoomName ?? "Chưa rõ"}'),
                      Text('Suất chiếu: ${bookingVM.selectedTimeDisplay ?? "--:--"} - ${bookingVM.selectedDateDisplay ?? "--/--/----"}'),
                      Text('Ghế: ${seats.map((id) => bookingVM.getSeatData(id)?.displayName ?? id).join(", ")}'),
                      if (bookingVM.selectedCombos.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Bắp nước:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...bookingVM.selectedCombos.entries.map((e) {
                          final combo = bookingVM.availableCombos.firstWhere((c) => c.comboId == e.key);
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Text('- ${combo.name} x${e.value}'),
                          );
                        }).toList(),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TẠM TÍNH:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(currencyFormat.format(bookingVM.subTotal)),
                        ],
                      ),
                      
                      // Rank Discount
                      if (bookingVM.bookingSummary?['uu_dai_rank'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hạng ${bookingVM.bookingSummary!['uu_dai_rank']['ten_rank']}:',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
                            ),
                            Text(
                              '- ${currencyFormat.format(bookingVM.bookingSummary!['uu_dai_rank']['sotien_giam_rank'])}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],

                      // Voucher Discount
                      if (bookingVM.bookingSummary?['voucher_ap_dung'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Voucher (${bookingVM.bookingSummary!['voucher_ap_dung']['mavoucher']}):',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green),
                            ),
                            Text(
                              '- ${currencyFormat.format(bookingVM.bookingSummary!['voucher_ap_dung']['sotien_duoc_giam'])}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ],
                        ),
                      ],

                      // If no summary yet but there's a selected voucher (fallback)
                      if (bookingVM.bookingSummary == null && bookingVM.discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GIẢM GIÁ:', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                            Text('- ${currencyFormat.format(bookingVM.discountAmount)}', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ],

                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TỔNG CỘNG:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormat.format(bookingVM.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE51937), fontSize: 18),
                          ),
                        ],
                      ),
                      
                      if (bookingVM.discountNotice.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    bookingVM.discountNotice,
                                    style: TextStyle(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Voucher Selection Row
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VoucherSelectorScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
                      ]
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, color: Color(0xFFEE4D2D)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Khuyến mãi / Voucher', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                        if (bookingVM.selectedVoucher != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF00BFA5)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              bookingVM.selectedVoucher!.title,
                              style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 11),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text('PHƯƠNG THỨC THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildPaymentMethod(bookingVM, 'momo', Icons.account_balance_wallet, 'Ví điện tử MoMo'),
                _buildPaymentMethod(bookingVM, 'vnpay', Icons.payment, 'Ví điện tử VNPay'),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: bookingVM.isLoading ? null : () async {
                final success = await bookingVM.submitBooking();
                
                if (success && context.mounted) {
                  // Nếu có URL thanh toán (VNPay/Momo), chuyển sang màn hình chờ thanh toán
                  if (bookingVM.paymentUrl != null && bookingVM.bookingResult != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentWaitingScreen(
                          bookingId: bookingVM.bookingResult!,
                          payUrl: bookingVM.paymentUrl!,
                          amount: bookingVM.totalPrice,
                        ),
                      ),
                    );
                  } else {
                    // Thanh toán khác hoặc không cần URL (ví dụ thanh toán tại quầy)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đặt vé thành công! Mã đơn: ${bookingVM.bookingResult}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    bookingVM.resetBooking();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(bookingVM.errorMessage ?? 'Đặt vé thất bại'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51937),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: bookingVM.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod(BookingViewModel bookingVM, String value, IconData icon, String title) {
    bool isSelected = bookingVM.paymentMethod == value;
    return GestureDetector(
      onTap: () => bookingVM.setPaymentMethod(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE51937).withOpacity(0.06) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFE51937) : Colors.grey[300]!,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFE51937).withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFE51937) : Colors.grey, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('Đang chọn', style: TextStyle(color: Color(0xFFE51937), fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFFE51937), size: 24)
          ],
        ),
      ),
    );
  }
}
