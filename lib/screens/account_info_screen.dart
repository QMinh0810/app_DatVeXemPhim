import 'package:flutter/material.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Nguyễn Văn A');
  final TextEditingController _phoneController = TextEditingController(text: '0901234567');
  final TextEditingController _emailController = TextEditingController(text: 'nguyenvana@gmail.com');
  
  int _gender = 1; // 1: Nam, 0: Nữ
  DateTime _selectedDate = DateTime(1995, 5, 12);

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông Tin Tài Khoản', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar Section
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE51937),
                    child: Text('A', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.grey, size: 24),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildTitle('MÃ TÀI KHOẢN'),
            TextFormField(
              initialValue: 'TK001',
              readOnly: true,
              style: const TextStyle(color: Colors.grey),
              decoration: _inputDecoration().copyWith(fillColor: Colors.grey[100]),
            ),
            const SizedBox(height: 16),

            _buildTitle('HỌ VÀ TÊN'),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            _buildTitle('NGÀY SINH'),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: _inputDecoration().copyWith(suffixIcon: const Icon(Icons.calendar_today)),
                child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
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

            _buildTitle('SỐ ĐIỆN THOẠI'), // Có thể Readonly tùy nghiệp vụ
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            _buildTitle('EMAIL'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cập nhật thông tin thành công!'), backgroundColor: Colors.green),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE51937),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CẬP NHẬT THÔNG TIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 40),
          ],
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50], // Giao diện trắng sáng
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
