import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/booking_viewmodel.dart';
import '../services/api_service.dart';
import 'seat_selection_screen.dart';

class ShowtimeScreen extends StatefulWidget {
  const ShowtimeScreen({super.key});

  @override
  State<ShowtimeScreen> createState() => _ShowtimeScreenState();
}

class _ShowtimeScreenState extends State<ShowtimeScreen> {
  List<dynamic> _showtimes = [];
  List<String> _theaters = [];
  String? _selectedTheater;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShowtimes();
  }

  Future<void> _loadShowtimes() async {
    final bookingVM = context.read<BookingViewModel>();
    final movieId = bookingVM.selectedMovie?.id;

    if (movieId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chưa chọn phim';
      });
      return;
    }

    try {
      final data = await ApiService.fetchShowtimes(movieId: movieId);
      final theaterSet = <String>{};
      for (final st in data) {
        final name = st['tenraphim']?.toString();
        if (name != null && name.isNotEmpty) theaterSet.add(name);
      }
      setState(() {
        _showtimes = data;
        _theaters = theaterSet.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch chiếu';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final movie = bookingVM.selectedMovie;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn Suất Chiếu', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin phim
          if (movie != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      movie.posterUrl,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60, height: 90, color: Colors.grey[300],
                        child: const Icon(Icons.movie),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(movie.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('${movie.duration} phút', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Bộ lọc rạp
          if (_theaters.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: _selectedTheater == null,
                      selectedColor: const Color(0xFFE51937),
                      labelStyle: TextStyle(
                        color: _selectedTheater == null ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _selectedTheater = null),
                    ),
                  ),
                  ..._theaters.map((theater) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(theater),
                      selected: _selectedTheater == theater,
                      selectedColor: const Color(0xFFE51937),
                      labelStyle: TextStyle(
                        color: _selectedTheater == theater ? Colors.white : Colors.black87,
                      ),
                      onSelected: (_) => setState(() => _selectedTheater = theater),
                    ),
                  )),
                ],
              ),
            ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('LỊCH CHIẾU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),

          // Danh sách suất chiếu
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)))
                    : _showtimes.isEmpty
                        ? const Center(child: Text('Chưa có suất chiếu cho phim này', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : Builder(builder: (context) {
                            final filtered = _selectedTheater == null
                                ? _showtimes
                                : _showtimes.where((st) => st['tenraphim'] == _selectedTheater).toList();
                            if (filtered.isEmpty) {
                              return const Center(child: Text('Không có suất chiếu cho rạp này', style: TextStyle(color: Colors.grey, fontSize: 16)));
                            }
                            return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final st = filtered[index];
                              final showtimeId = st['malichchieu'] ?? '';
                              final theaterName = st['tenraphim'] ?? 'Rạp chưa rõ';
                              final roomName = st['tenphong'] ?? '';
                              final price = (st['giave'] ?? 0);
                              
                              // Parse giờ chiếu
                              String timeDisplay = '';
                              if (st['giochieu'] != null) {
                                final dt = DateTime.tryParse(st['giochieu'].toString());
                                if (dt != null) {
                                  timeDisplay = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                }
                              }
                              String dateDisplay = '';
                              if (st['ngaychieu'] != null) {
                                final dt = DateTime.tryParse(st['ngaychieu'].toString());
                                if (dt != null) {
                                  dateDisplay = '${dt.day}/${dt.month}/${dt.year}';
                                }
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    bookingVM.selectShowtime(
                                      showtimeId,
                                      price.toDouble(),
                                      theaterName: theaterName,
                                      roomName: roomName,
                                      timeDisplay: timeDisplay,
                                      dateDisplay: dateDisplay,
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SeatSelectionScreen()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Khung giờ
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE51937),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(timeDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                              Text(dateDisplay, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Thông tin rạp
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(theaterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 4),
                                              Text(roomName, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VNĐ',
                                                style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                          }),
          ),
        ],
      ),
    );
  }
}
