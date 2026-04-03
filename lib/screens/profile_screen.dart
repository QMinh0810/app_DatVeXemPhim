import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'account_info_screen.dart';
import 'transaction_history_screen.dart';
import 'my_tickets_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tài Khoản', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE51937),
                    child: Text('A', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nguyễn Văn A', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Thành viên thân thiết', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Menu
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuItem(
                    Icons.history, 
                    'Lịch sử giao dịch', 
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()));
                    }
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    Icons.local_activity, 
                    'Vé của tôi', 
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MyTicketsScreen()));
                    }
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(
                    Icons.person_outline, 
                    'Thông tin tài khoản', 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
                      );
                    }
                  ),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.lock_outline, 'Thay đổi mật khẩu', onTap: () {}),
                  const Divider(height: 1),
                  _buildMenuItem(Icons.settings, 'Cài đặt ứng dụng', onTap: () {}),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Logout
            Container(
              color: Colors.white,
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Color(0xFFE51937)),
                title: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ?? () {},
    );
  }
}
