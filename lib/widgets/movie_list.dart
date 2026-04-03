import 'package:flutter/material.dart';
import 'movie_card.dart';

class MovieList extends StatelessWidget {
  const MovieList({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE51937),
            tabs: [
              Tab(text: 'Đang chiếu'),
              Tab(text: 'Đặc biệt'),
              Tab(text: 'Sắp chiếu'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380, // Height for movie card including button
            child: TabBarView(
              children: [
                _buildMovieCarousel(),
                const Center(child: Text("Không có dữ liệu phim đặc biệt")),
                const Center(child: Text("Không có dữ liệu phim sắp chiếu")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCarousel() {
    final List<Map<String, String>> movies = [
      {
        'title': 'DUNE: HÀNH TINH CÁT 2',
        'rating': 'T16',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg',
      },
      {
        'title': 'KUNG FU PANDA 4',
        'rating': 'P',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
      },
      {
        'title': 'MAI',
        'rating': 'T18',
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/vi/a/a8/Mai_2024_poster.jpg',
      },
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: MovieCard(
            title: movies[index]['title']!,
            rating: movies[index]['rating']!,
            imageUrl: movies[index]['imageUrl']!,
          ),
        );
      },
    );
  }
}
