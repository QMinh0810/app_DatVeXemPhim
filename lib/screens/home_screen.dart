import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/movie_viewmodel.dart';
import '../widgets/promo_slider.dart';
import '../widgets/feature_grid.dart';
import '../widgets/movie_list.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/horizontal_image_list.dart';

import 'dummy_screen.dart';
import 'movie_list_screen.dart';
import 'profile_screen.dart';
import 'theater_screen.dart';

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
      return RefreshIndicator(
        onRefresh: () async {
          await context.read<MovieViewModel>().fetchMovies();
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PromoSlider(),
              SizedBox(height: 16),
              MovieList(),
              SizedBox(height: 24),
              HorizontalImageList(
                title: 'Tin mới & Ưu đãi',
                imageUrls: [
                  'lib/images/event1.jpg',
                  'lib/images/event2.png',
                  'lib/images/event3.jpg',
                  'lib/images/event4.jpg',
                ],
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      );
    } else if (_selectedIndex == 1) {
      return const MovieListScreen();
    } else if (_selectedIndex == 2) {
      return const TheaterScreen();
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
