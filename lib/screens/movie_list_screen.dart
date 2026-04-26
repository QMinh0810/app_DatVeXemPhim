import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/movie_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'showtime_screen.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieViewModel>(
      builder: (context, movieVM, child) {
        final allMovies = movieVM.allMovies;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phim Đang Chiếu', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
          ),
          body: allMovies.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: allMovies.length,
                  separatorBuilder: (context, index) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final movie = allMovies[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            movie.posterUrl,
                            width: 120,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 120,
                              height: 180,
                              color: Colors.grey[300],
                              child: const Icon(Icons.movie, size: 40),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: movie.ratingLimit >= 16
                                          ? Colors.red
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      movie.ratingLimit > 0 ? 'T${movie.ratingLimit}' : 'P',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('2D', style: TextStyle(fontSize: 12, color: Colors.black54)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Thể loại: ${movie.genres.join(", ")}', style: const TextStyle(fontSize: 14)),
                              Text('Thời lượng: ${movie.duration} Phút', style: const TextStyle(fontSize: 14)),
                              Text('Khởi chiếu: ${movie.releaseDate.day}/${movie.releaseDate.month}/${movie.releaseDate.year}', style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<BookingViewModel>().selectMovie(movie);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ShowtimeScreen()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE51937),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: const Text('ĐẶT VÉ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
