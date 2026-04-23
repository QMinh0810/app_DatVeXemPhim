import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/movie_model.dart';
import '../viewmodels/movie_viewmodel.dart';
import 'movie_card.dart';

class MovieList extends StatefulWidget {
  const MovieList({super.key});

  @override
  State<MovieList> createState() => _MovieListState();
}

class _MovieListState extends State<MovieList> {
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MovieViewModel>().fetchMovies();
      context.read<MovieViewModel>().fetchHotMovies();
    });
  }

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
              Tab(text: 'Phim Hot'),
              Tab(text: 'Sắp chiếu'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 380, // Height for movie card including button
            child: TabBarView(
              children: [
                _buildMovieCarousel(context, 'showing'),
                _buildMovieCarousel(context, 'hot'),
                _buildMovieCarousel(context, 'coming_soon'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCarousel(BuildContext context, String listType) {
    return Consumer<MovieViewModel>(
      builder: (context, movieVM, child) {
        if (movieVM.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        List<MovieModel> movies = [];
        if (listType == 'showing') {
          movies = movieVM.showingMovies;
        } else if (listType == 'hot') {
          movies = movieVM.hotMovies;
        } else if (listType == 'coming_soon') {
          movies = movieVM.comingSoonMovies;
        }

        if (movies.isEmpty) {
          return const Center(child: Text("Không có phim nào"));
        }

        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: MovieCard(
                title: movie.title,
                rating: movie.ratingLimit > 0 ? 'T${movie.ratingLimit}' : 'P',
                imageUrl: movie.posterUrl,
                movie: movie,
              ),
            );
          },
        );
      },
    );
  }
}
