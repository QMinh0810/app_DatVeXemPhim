import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/movie_viewmodel.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../models/movie_model.dart';
import 'showtime_screen.dart';
import 'movie_info_screen.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedGenre;
  bool _isFilterVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MovieModel> _filterMovies(List<MovieModel> movies) {
    return movies.where((movie) {
      final matchesSearch = _searchQuery.isEmpty ||
          movie.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGenre = _selectedGenre == null ||
          movie.genres.contains(_selectedGenre);
      return matchesSearch && matchesGenre;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieViewModel>(
      builder: (context, movieVM, child) {
        final allMovies = movieVM.allMovies;
        final allGenres = <String>{};
        for (final movie in allMovies) {
          allGenres.addAll(movie.genres);
        }
        final genreList = allGenres.toList()..sort();
        final filtered = _filterMovies(allMovies);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Phim Đang Chiếu', style: TextStyle(color: Colors.black)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 0,
          ),
          body: Column(
            children: [
              // Thanh tìm kiếm + Nút lọc
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm phim...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _isFilterVisible ? const Color(0xFFE51937) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.filter_alt_outlined, 
                          color: _isFilterVisible ? Colors.white : Colors.black87
                        ),
                        onPressed: () {
                          setState(() {
                            _isFilterVisible = !_isFilterVisible;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Bộ lọc thể loại (Hiện ra dưới dạng khung bo góc)
              if (_isFilterVisible && genreList.isNotEmpty)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lọc theo thể loại',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => setState(() => _isFilterVisible = false),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Tất cả'),
                            selected: _selectedGenre == null,
                            selectedColor: const Color(0xFFE51937),
                            labelStyle: TextStyle(
                              color: _selectedGenre == null ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedGenre = null;
                                _isFilterVisible = false;
                              });
                            },
                          ),
                          ...genreList.map((genre) => ChoiceChip(
                            label: Text(genre),
                            selected: _selectedGenre == genre,
                            selectedColor: const Color(0xFFE51937),
                            labelStyle: TextStyle(
                              color: _selectedGenre == genre ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedGenre = genre;
                                _isFilterVisible = false;
                              });
                            },
                          )),
                        ],
                      ),
                    ],
                  ),
                ),

              // Danh sách phim
              Expanded(
                child: allMovies.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              'Không tìm thấy phim nào',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 32),
                            itemBuilder: (context, index) {
                              final movie = filtered[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MovieInfoScreen(movie: movie),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
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
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MovieInfoScreen(movie: movie),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            movie.title,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                          ),
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
                                            onPressed: (movie.status == 'now_showing' || movie.status == 'showing') 
                                              ? () {
                                                  context.read<BookingViewModel>().selectMovie(movie);
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(builder: (context) => const ShowtimeScreen()),
                                                  );
                                                }
                                              : null,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: (movie.status == 'now_showing' || movie.status == 'showing') 
                                                  ? const Color(0xFFE51937) 
                                                  : Colors.grey,
                                              disabledBackgroundColor: Colors.grey[400],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                            ),
                                            child: Text(
                                              (movie.status == 'now_showing' || movie.status == 'showing') ? 'ĐẶT VÉ' : 'SẮP CHIẾU', 
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
