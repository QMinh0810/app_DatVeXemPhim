import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields mapped to DB
  int _gender = 1; // 1: Nam, 0: Nữ
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle('HỌ TÊN'),
              TextFormField(
                decoration: _inputDecoration('Nhập họ và tên đầy đủ'),
              ),
              const SizedBox(height: 16),

              _buildTitle('NGÀY SINH'),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: _inputDecoration('Chọn ngày sinh').copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                  child: Text(_selectedDate != null 
                    ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" 
                    : 'Nhấn để chọn',
                    style: TextStyle(color: _selectedDate != null ? Colors.black : Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTitle('GIỚI TÍNH'),
              Row(
                children: [
                  Radio<int>(value: 1, groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                  const Text('Nam'),
                  const SizedBox(width: 24),
                  Radio<int>(value: 0, groupValue: _gender, onChanged: (v) => setState(() => _gender = v!)),
                  const Text('Nữ'),
                ],
              ),
              const SizedBox(height: 16),

              _buildTitle('SỐ ĐIỆN THOẠI'),
              TextFormField(
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Nhập SĐT của bạn'),
              ),
              const SizedBox(height: 16),

              _buildTitle('EMAIL'),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Nhập địa chỉ Email'),
              ),
              const SizedBox(height: 16),

              _buildTitle('MẬT KHẨU'),
              TextFormField(
                obscureText: true,
                decoration: _inputDecoration('Nhập mật khẩu (tối thiểu 6 ký tự)'),
              ),
              const SizedBox(height: 16),

              _buildTitle('XÁC NHẬN MẬT KHẨU'),
              TextFormField(
                obscureText: true,
                decoration: _inputDecoration('Nhập lại mật khẩu'),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  // TODO: Save to DB mapping
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context); // Go back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE51937),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('HOÀN TẤT ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
