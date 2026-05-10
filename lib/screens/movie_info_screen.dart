import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/movie_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'showtime_screen.dart';
import 'package:intl/intl.dart';

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

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
      // Fallback: If not a valid Youtube URL, try opening in browser
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở video này')),
          );
        }
      }
      return;
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85), // Lightbox effect
      builder: (context) => _TrailerDialog(videoId: videoId),
    );
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

                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  
                  // --- Review Button ---
                  _buildReviewSection(context),

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
          if (movie.directors.isNotEmpty)
            _buildDirectorsList()
          else
            _buildDetailRow('Đạo diễn', 'Đang cập nhật'),
          const SizedBox(height: 24),
          if (movie.actors.isNotEmpty)
            _buildActorsList()
          else
            _buildDetailRow('Diễn viên', 'Đang cập nhật'),
        ],
      ),
    );
  }

  Widget _buildDirectorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đạo diễn',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movie.directors.length,
            itemBuilder: (context, index) {
              final director = movie.directors[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(director)}&background=random&color=fff&size=128',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      director,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActorsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diễn viên',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115, // Đã tăng chiều cao để tránh lỗi Overflow khi tên xuống dòng
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movie.actors.length,
            itemBuilder: (context, index) {
              final actor = movie.actors[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(actor)}&background=random&color=fff&size=128',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actor,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

  Widget _buildReviewSection(BuildContext context) {
    return InkWell(
      onTap: () => _showReviewBottomSheet(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Đánh giá & Bình luận',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Bình luận', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: FutureBuilder<List<dynamic>>(
                      future: ApiService.fetchReviews(movie.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Chưa có bình luận nào.'));
                        }

                        final reviews = snapshot.data!.map((json) => ReviewModel.fromJson(json)).toList();

                        return ListView.separated(
                          controller: controller,
                          itemCount: reviews.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                          itemBuilder: (context, index) {
                            final review = reviews[index];
                            DateTime? time;
                            try {
                              time = DateTime.parse(review.thoiDiemDanhGia);
                            } catch (_) {}

                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: review.anhDaiDien != null && review.anhDaiDien!.isNotEmpty
                                        ? NetworkImage(review.anhDaiDien!)
                                        : NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(review.hoTen)}&background=random'),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              review.hoTen,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            if (time != null)
                                              Text(
                                                DateFormat('dd/MM/yyyy HH:mm').format(time),
                                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text('${review.danhGia}/10', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          review.noiDung,
                                          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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

class _TrailerDialog extends StatefulWidget {
  final String videoId;
  const _TrailerDialog({Key? key, required this.videoId}) : super(key: key);

  @override
  State<_TrailerDialog> createState() => _TrailerDialogState();
}

class _TrailerDialogState extends State<_TrailerDialog> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    // Khôi phục lại màn hình dọc khi tắt video
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE51937),
      ),
      builder: (context, player) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(
                    width: screenWidth * 0.95, // Chiếm 95% chiều ngang màn hình
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Giữ tỉ lệ 16:9 chuẩn
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: player,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
