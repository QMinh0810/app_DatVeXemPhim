import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'change_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isSendingOTP = false;

  void _sendOTP() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Vui lòng nhập Email hoặc SĐT', isError: true);
      return;
    }

    setState(() => _isSendingOTP = true);

    try {
      final response = await ApiService.forgotPassword(email);
      if (mounted) {
        if (response['status'] == 'success') {
          _showSnackBar(response['message'] ?? 'Mã OTP đã được gửi!', isError: false);
        } else {
          _showSnackBar(response['message'] ?? 'Gửi OTP thất bại', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối server', isError: true);
    } finally {
      if (mounted) setState(() => _isSendingOTP = false);
    }
  }

  void _verifyOTPAndReset() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (email.isEmpty || otp.isEmpty) {
      _showSnackBar('Vui lòng điền đủ Email và mã OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gửi mật khẩu mặc định là '9' theo yêu cầu
      final response = await ApiService.resetPassword(email, otp, '9');
      
      if (mounted) {
        if (response['status'] == 'success') {
          _showSnackBar('Xác thực OTP thành công!', isError: false);
          // Chuyển sang màn hình đổi mật khẩu
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
          );
        } else {
          _showSnackBar(response['message'] ?? 'Mã OTP không chính xác', isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi hệ thống', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Quên mật khẩu', style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset, size: 80, color: Color(0xFFE51937)),
              const SizedBox(height: 24),
              const Text(
                'Khôi phục mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhập email để nhận mã OTP, sau đó xác nhận để đặt lại mật khẩu mới.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Email Input
              _buildTextField(
                controller: _emailController,
                label: 'Email / SĐT',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              // OTP Input with Send Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _otpController,
                      label: 'Mã OTP',
                      icon: Icons.vpn_key_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSendingOTP ? null : _sendOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE51937),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSendingOTP 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gửi OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              // Confirm Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTPAndReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE51937),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('XÁC NHẬN OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
