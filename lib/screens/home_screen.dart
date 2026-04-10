import 'package:flutter/material.dart';
import '../widgets/promo_slider.dart';
import '../widgets/movie_list.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/horizontal_image_list.dart';
import 'dummy_screen.dart';
import 'profile_screen.dart';
import 'my_tickets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Render content based on selected tab
  Widget _buildBody() {
    if (_selectedIndex == 0) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PromoSlider(),
            const SizedBox(height: 16),
            const MovieList(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Bạn cần hỗ trợ gì?',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const HorizontalImageList(
              title: 'Tin mới & Ưu đãi',
              imageUrls: [
                'https://image.tmdb.org/t/p/w500/8Y43POKjjKDGI9MH89NW0NAzzp8.jpg',
                'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg',
                'https://upload.wikimedia.org/wikipedia/vi/a/a8/Mai_2024_poster.jpg',
              ],
              imageWidth: 260,
              imageHeight: 140,
            ),
            const SizedBox(height: 24),
            const HorizontalImageList(
              title: 'CGV eGift',
              imageUrls: [
                'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
                'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg',
              ],
              imageWidth: 200,
              imageHeight: 120,
            ),
            const SizedBox(height: 24),
            const HorizontalImageList(
              title: 'Video',
              imageUrls: [
                'https://image.tmdb.org/t/p/w500/8Y43POKjjKDGI9MH89NW0NAzzp8.jpg',
                'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
              ],
              imageWidth: 240,
              imageHeight: 135,
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      return const ProfileScreen(); // Thành viên
    } else if (_selectedIndex == 2) {
      return const DummyScreen(title: 'Hệ thống Rạp');
    } else if (_selectedIndex == 3) {
      return const MyTicketsScreen(); // Vé của tôi
    } else {
      return const DummyScreen(title: 'Mở rộng');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0 ? const CustomAppBar() : null, // Only show custom app bar on home tab
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE51937),
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Thành viên'),
          BottomNavigationBarItem(icon: Icon(Icons.local_movies_outlined), label: 'Rạp'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num_outlined), label: 'Vé của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Mở rộng'),
        ],
      ),
    );
  }
}
