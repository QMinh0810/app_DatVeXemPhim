import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/movie_model.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'showtime_screen.dart';

class MovieInfoScreen extends StatelessWidget {
  final MovieModel movie;

  const MovieInfoScreen({super.key, required this.movie});

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _openTrailer(BuildContext context) async {
    final url = movie.trailerUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer chưa được cập nhật')),
      );
      return;
    }
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trailer')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã có lỗi xảy ra khi mở trailer')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phim',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Trailer Thumbnail Area ---
                  _buildTrailerThumbnail(context),

                  // --- Poster + Title + Date + Duration ---
                  _buildMovieHeader(),

                  const Divider(height: 1, color: Color(0xFFE0E0E0)),

                  // --- Description ---
                  _buildDescription(),

                  const Divider(height: 1, color: Color(0xFFE0E0E0)),

                  // --- Detail Table ---
                  _buildDetailTable(),

                  const SizedBox(height: 100), // space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomButton(context),
    );
  }

  /// Trailer thumbnail with play button overlay
  Widget _buildTrailerThumbnail(BuildContext context) {
    return GestureDetector(
      onTap: () => _openTrailer(context),
      child: SizedBox(
        width: double.infinity,
        height: 220,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.movie, size: 80, color: Colors.white54),
              ),
            ),
            // Dark overlay
            Container(color: Colors.black.withOpacity(0.35)),
            // Play button
            Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.85),
                ),
                child: const Icon(Icons.play_arrow, size: 36, color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Poster on left, title + date/duration on right
  Widget _buildMovieHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster thumbnail (overlapping the trailer area)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              width: 120,
              height: 170,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  movie.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Title + info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Date & Duration row
                Row(
                  children: [
                    _buildChip(Icons.calendar_today_outlined,
                        '${movie.releaseDate.day.toString().padLeft(2, '0')}/${movie.releaseDate.month.toString().padLeft(2, '0')}/${movie.releaseDate.year}'),
                    const SizedBox(width: 10),
                    _buildChip(Icons.access_time_outlined, _formatDuration(movie.duration)),
                  ],
                ),
                const SizedBox(height: 8),
                // Rating badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: movie.ratingLimit >= 16 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    movie.ratingLimit > 0 ? 'T${movie.ratingLimit}' : 'P',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Chip with icon + text (date, duration)
  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[350]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  /// Movie description section
  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movie.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
          ),
        ],
      ),
    );
  }

  /// Detail table: Kiểm duyệt, Thể loại, Đạo diễn, Diễn viên
  Widget _buildDetailTable() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDetailRow('Kiểm duyệt', movie.ratingLimit > 0
              ? 'T${movie.ratingLimit} - Phim được phổ biến đến người xem từ đủ ${movie.ratingLimit} tuổi trở lên.'
              : 'P - Phim được phổ biến đến mọi đối tượng.'),
          const SizedBox(height: 12),
          _buildDetailRow('Thể loại', movie.genres.isNotEmpty ? movie.genres.join(', ') : 'Đang cập nhật'),
          const SizedBox(height: 12),
          _buildDetailRow('Đạo diễn', movie.directors.isNotEmpty ? movie.directors.join(', ') : 'Đang cập nhật'),
          const SizedBox(height: 12),
          _buildDetailRow('Diễn viên', movie.actors.isNotEmpty ? movie.actors.join(', ') : 'Đang cập nhật'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
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
          ),
          child: const Text(
            'ĐẶT VÉ',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
