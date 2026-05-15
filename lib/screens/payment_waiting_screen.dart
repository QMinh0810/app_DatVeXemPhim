import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'order_tickets_screen.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final String bookingId;
  final String payUrl;
  final double amount;

  const PaymentWaitingScreen({
    super.key,
    required this.bookingId,
    required this.payUrl,
    required this.amount,
  });

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;
  int _remainingSeconds = 600; // Mặc định 10 phút, sẽ update từ API
  bool _isPaid = false;
  bool _isExpired = false;
  bool _isCancelling = false;
  bool _isLoadingTarget = false;
  String _currentStatus = 'Đang chờ xử lý...';

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startCountdown();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _checkStatus();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkStatus();
    });
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _isExpired = true;
        });
        _stopTimers();
      }
    });
  }

  void _stopTimers() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _checkStatus() async {
    final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
    try {
      final res = await bookingVM.checkBookingStatus(widget.bookingId);
      if (!mounted) return;

      final status = (res['status'] ?? '').toString().toLowerCase();
      
      setState(() {
        if (status == 'paid' || status == 'đã thanh toán' || status == 'success') {
          _currentStatus = 'Đã thanh toán';
        } else if (status == 'pending') {
          _currentStatus = 'Đang chờ xử lý...';
        } else if (status == 'cancelled' || status == 'hủy') {
          _currentStatus = 'Đã hủy';
        } else if (res['message'] != null) {
          _currentStatus = res['message'];
        }
      });

      if (status == 'paid' || status == 'đã thanh toán' || status == 'success') {
        _stopTimers();
        setState(() {
          _isPaid = true;
        });
        
        // Chờ 3 giây để người dùng thấy Tick xanh, sau đó chuyển màn hình
        Future.delayed(const Duration(seconds: 3), () {
          _navigateToOrderDetail();
        });
      } else if (res['isExpired'] == true || status == 'cancelled' || status == 'hủy') {
        _stopTimers();
        setState(() {
          _isExpired = true;
        });
      } else if (res['remainingSeconds'] != null) {
        setState(() {
          _remainingSeconds = res['remainingSeconds'];
        });
      }
    } catch (e) {
      debugPrint('Polling error: $e');
      if (mounted) {
        setState(() {
          _currentStatus = 'Lỗi kết nối máy chủ';
        });
      }
    }
  }

  Future<void> _navigateToOrderDetail() async {
    if (!mounted) return;
    setState(() => _isLoadingTarget = true);
    try {
      // Vì API backend chưa có endpoint lấy 1 đơn hàng theo ID, ta sẽ lấy history và filter
      final history = await ApiService.fetchBookingHistory();
      final order = history.firstWhere(
        (h) => h['maDonDatVe'] == widget.bookingId,
        orElse: () => null,
      );

      if (order != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTicketsScreen(order: order),
          ),
        );
      } else {
        // Fallback về trang chủ nếu không tìm thấy đơn hàng
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<bool> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy giao dịch?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này không? Ghế của bạn sẽ được giải phóng ngay lập tức.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('KHÔNG', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('HỦY ĐƠN', style: TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isCancelling = true);
      final bookingVM = Provider.of<BookingViewModel>(context, listen: false);
      final success = await bookingVM.cancelBooking(widget.bookingId);
      if (mounted) {
        setState(() => _isCancelling = false);
        if (success) {
          _stopTimers();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể hủy đơn hàng lúc này.')),
          );
          return false;
        }
      }
    }
    return false;
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaid) return _buildSuccessUI();
    if (_isExpired) return _buildExpiredUI();

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return PopScope(
      canPop: false, // Ngăn chặn tự động thoát
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _handleCancel();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Thanh Toán', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: _handleCancel,
          ),
          actions: [
            TextButton(
              onPressed: _handleCancel,
              child: const Text(
                'Hủy thanh toán',
                style: TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            )
          ],
        ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Banking style Countdown
                  SizedBox(
                    height: 180,
                    width: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 160,
                          width: 160,
                          child: CircularProgressIndicator(
                            value: _remainingSeconds / 600,
                            strokeWidth: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE51937)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Hết hạn sau', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_remainingSeconds),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Payment Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TỔNG TIỀN THANH TOÁN', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          currencyFormat.format(widget.amount),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE51937)),
                        ),
                        const Divider(height: 32),
                        _buildSummaryItem('Mã đơn hàng', widget.bookingId),
                        const SizedBox(height: 12),
                        _buildSummaryItem('Trạng thái', _currentStatus, color: _currentStatus == 'Đã thanh toán' ? Colors.green[700] : Colors.orange[700]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Information Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.grey))),
                      SizedBox(width: 12),
                      Text('Vui lòng hoàn tất thanh toán trên ứng dụng Ví', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom Action
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final uri = Uri.parse(widget.payUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE51937),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('MỞ ỨNG DỤNG THANH TOÁN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      _checkStatus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đang cập nhật trạng thái mới nhất...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE51937)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('KIỂM TRA THANH TOÁN', style: TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSummaryItem(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        Text(value, style: TextStyle(color: color ?? const Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSuccessUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 90),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Thanh toán thành công!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Giao dịch của bạn đã được xác nhận.\nĐang chuyển đến chi tiết vé...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  if (_isLoadingTarget)
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE51937))),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Mã đơn: ${widget.bookingId}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildExpiredUI() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_off_outlined, color: Colors.grey, size: 64),
              ),
              const SizedBox(height: 32),
              const Text(
                'Giao dịch hết hạn',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rất tiếc, thời gian thanh toán đã hết hoặc đơn hàng bị hủy. Các ghế bạn chọn đã được giải phóng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<BookingViewModel>().resetBooking();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('QUAY LẠI TRANG CHỦ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
