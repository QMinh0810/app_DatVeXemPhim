import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/movie_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import '../viewmodels/booking_viewmodel.dart';
import 'showtime_screen.dart';

class MovieInfoScreen extends StatefulWidget {
  final MovieModel movie;

  const MovieInfoScreen({super.key, required this.movie});

  @override
  State<MovieInfoScreen> createState() => _MovieInfoScreenState();
}

class _MovieInfoScreenState extends State<MovieInfoScreen> {
  bool _isDescriptionExpanded = false;

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  Future<void> _openTrailer(BuildContext context) async {
    final url = widget.movie.trailerUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer chưa được cập nhật')),
      );
      return;
    }

    final videoId = YoutubePlayer.convertUrlToId(url);
    if (videoId == null) {
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
      barrierColor: Colors.black.withOpacity(0.85),
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
                  _buildTrailerThumbnail(context),
                  _buildMovieHeader(),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildDescription(),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildDetailTable(),
                  const Divider(height: 1, color: Color(0xFFE0E0E0)),
                  _buildReviewSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomButton(context),
    );
  }

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
              widget.movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                child: const Icon(Icons.movie, size: 80, color: Colors.white54),
              ),
            ),
            Container(color: Colors.black.withOpacity(0.35)),
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

  Widget _buildMovieHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  widget.movie.posterUrl,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildChip(Icons.calendar_today_outlined,
                        '${widget.movie.releaseDate.day.toString().padLeft(2, '0')}/${widget.movie.releaseDate.month.toString().padLeft(2, '0')}/${widget.movie.releaseDate.year}'),
                    const SizedBox(width: 10),
                    _buildChip(Icons.access_time_outlined, _formatDuration(widget.movie.duration)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.movie.ratingLimit >= 16 ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.movie.ratingLimit > 0 ? 'T${widget.movie.ratingLimit}' : 'P',
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

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.movie.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
            maxLines: _isDescriptionExpanded ? null : 3,
            overflow: _isDescriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                  style: const TextStyle(
                    color: Color(0xFFE51937),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFFE51937),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTable() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Kiểm duyệt', widget.movie.ratingLimit > 0
              ? 'T${widget.movie.ratingLimit} - Phim được phổ biến đến người xem từ đủ ${widget.movie.ratingLimit} tuổi trở lên.'
              : 'P - Phim được phổ biến đến mọi đối tượng.'),
          const SizedBox(height: 12),
          _buildDetailRow('Thể loại', widget.movie.genres.isNotEmpty ? widget.movie.genres.join(', ') : 'Đang cập nhật'),
          const SizedBox(height: 20),
          if (widget.movie.directors.isNotEmpty) _buildPersonsList(title: 'Đạo diễn', persons: widget.movie.directors),
          const SizedBox(height: 20),
          if (widget.movie.actors.isNotEmpty) _buildPersonsList(title: 'Diễn viên', persons: widget.movie.actors),
        ],
      ),
    );
  }

  /// Danh sách diễn viên / đạo diễn dạng cuộn ngang với ảnh thật từ DB
  Widget _buildPersonsList({required String title, required List<PersonInfo> persons}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 115,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: persons.length,
            itemBuilder: (context, index) {
              final person = persons[index];
              // Ưu tiên dùng ảnh thật từ DB, fallback về ui-avatars nếu null/rỗng
              final hasRealAvatar = person.avatarUrl != null && person.avatarUrl!.isNotEmpty;
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: hasRealAvatar
                          ? NetworkImage(person.avatarUrl!)
                          : NetworkImage(
                              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(person.name)}&background=random&color=fff&size=128',
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      person.name,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showReviewBottomSheet(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE51937)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.rate_review_outlined, color: Color(0xFFE51937), size: 20),
              SizedBox(width: 8),
              Text(
                'Xem đánh giá',
                style: TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, controller) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'Đánh giá phim',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<dynamic>>(
                    future: ApiService.fetchReviews(widget.movie.id),
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
                                      : NetworkImage(
                                          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(review.hoTen)}&background=random'),
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
                                          Text('${review.danhGia}/10',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
            context.read<BookingViewModel>().selectMovie(widget.movie);
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
                    width: screenWidth * 0.95,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
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


