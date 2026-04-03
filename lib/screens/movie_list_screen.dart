import 'package:flutter/material.dart';
import 'seat_selection_screen.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy movies local scope
    final List<Map<String, dynamic>> allMovies = [
      {
        'title': 'DUNE: HÀNH TINH CÁT 2',
        'rating': 'T16',
        'genre': 'Hành Động, Viễn Tưởng',
        'duration': '166 Phút',
        'release': '01/03/2024',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg',
      },
      {
        'title': 'KUNG FU PANDA 4',
        'rating': 'P',
        'genre': 'Hoạt Hình, Gia Đình',
        'duration': '94 Phút',
        'release': '08/03/2024',
        'imageUrl': 'https://image.tmdb.org/t/p/w500/kDp1vUBnMpe8ak4rjgl3cLELqjU.jpg',
      },
      {
        'title': 'MAI',
        'rating': 'T18',
        'genre': 'Tình Cảm, Tâm Lý',
        'duration': '131 Phút',
        'release': '10/02/2024',
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/vi/a/a8/Mai_2024_poster.jpg',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phim Đang Chiếu', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: ListView.separated(
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
                  movie['imageUrl'],
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
                      movie['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: movie['rating'].toString().contains('18') || movie['rating'].toString().contains('16')
                                ? Colors.red
                                : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            movie['rating'],
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
                    Text('Thể loại: ${movie['genre']}', style: const TextStyle(fontSize: 14)),
                    Text('Thời lượng: ${movie['duration']}', style: const TextStyle(fontSize: 14)),
                    Text('Khởi chiếu: ${movie['release']}', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SeatSelectionScreen()),
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
              )
            ],
          );
        },
      ),
    );
  }
}
