import 'package:flutter/material.dart';
import '../widgets/promo_slider.dart';
import '../widgets/feature_grid.dart';
import '../widgets/movie_list.dart';
import '../widgets/custom_app_bar.dart';
import 'dummy_screen.dart';
import 'movie_list_screen.dart';
import 'profile_screen.dart';

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
      return const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PromoSlider(),
            SizedBox(height: 16),
            MovieList(),
            SizedBox(height: 24),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      return const MovieListScreen();
    } else if (_selectedIndex == 2) {
      return const DummyScreen(title: 'Rạp Phim');
    } else {
      return const ProfileScreen();
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
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'Phim'),
          BottomNavigationBarItem(icon: Icon(Icons.local_activity), label: 'Rạp phim'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }
}
