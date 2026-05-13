import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedDateIndex = 0; // 0 is "Tất cả", 1-9 are specific dates
  
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _generateDates();
    _loadShowtimes();
  }

  void _generateDates() {
    final now = DateTime.now();
    // Logic: Bắt đầu từ Thứ 7 tuần trước, cập nhật sang tuần mới khi đến Chủ Nhật
    // Công thức: startDate = now - ((weekday % 7) + 1)
    // Ví dụ: CN (7%7=0) -> lùi 1 ngày = Thứ 7 hôm qua. T2 (1%7=1) -> lùi 2 ngày = Thứ 7 tuần trước.
    final startSaturday = now.subtract(Duration(days: (now.weekday % 7) + 1));
    _dates = List.generate(9, (index) => startSaturday.add(Duration(days: index)));
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

    setState(() => _isLoading = true);

    try {
      String? selectedDateStr;
      if (_selectedDateIndex > 0) {
        selectedDateStr = DateFormat('yyyy-MM-dd').format(_dates[_selectedDateIndex - 1]);
      }
      
      final theaterId = bookingVM.selectedTheaterId;
      final data = await ApiService.fetchShowtimes(movieId: movieId, date: selectedDateStr, theaterId: theaterId);
      
      // Lọc bỏ lịch chiếu quá khứ (không hiển thị suất chiếu đã qua)
      final now = DateTime.now();
      final filteredData = (data as List).where((st) {
        if (st['giochieu'] == null) return false;
        final dt = DateTime.tryParse(st['giochieu'].toString());
        if (dt == null) return false;
        return dt.isAfter(now);
      }).toList();

      setState(() {
        _showtimes = filteredData;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải lịch chiếu';
      });
    }
  }

  Map<String, List<dynamic>> _groupShowtimesByCinema() {
    final Map<String, List<dynamic>> grouped = {};
    for (var st in _showtimes) {
      final cinemaName = st['tenrapphim'] ?? st['tenRapPhim'] ?? st['TENRAPPHIM'] ?? 'Rạp chưa rõ';
      if (!grouped.containsKey(cinemaName)) {
        grouped[cinemaName] = [];
      }
      grouped[cinemaName]!.add(st);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final bookingVM = context.watch<BookingViewModel>();
    final movie = bookingVM.selectedMovie;
    final groupedCinemas = _groupShowtimesByCinema();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(movie?.title.toUpperCase() ?? 'CHỌN SUẤT CHIẾU', 
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Nút "Tất cả"
                  _buildDateItem(0, 'Tất cả'),
                  // Danh sách 9 ngày
                  ...List.generate(_dates.length, (index) {
                    final date = _dates[index];
                    final dateFormatted = DateFormat('yyyy-MM-dd').format(date);
                    
                    String label;
                    if (dateFormatted == todayStr) {
                      label = 'Hôm nay\n${DateFormat('dd/MM').format(date)}';
                    } else {
                      label = '${_getWeekdayLabel(date.weekday)}\n${DateFormat('dd/MM').format(date)}';
                    }
                    
                    return _buildDateItem(index + 1, label);
                  }),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Showtimes List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE51937)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)))
                    : groupedCinemas.isEmpty
                        ? const Center(child: Text('Không có suất chiếu cho lựa chọn này', style: TextStyle(color: Colors.grey, fontSize: 16)))
                        : ListView.builder(
                            itemCount: groupedCinemas.length,
                            itemBuilder: (context, index) {
                              final cinemaName = groupedCinemas.keys.elementAt(index);
                              final showtimes = groupedCinemas[cinemaName]!;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                color: Colors.white,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cinema Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cinemaName,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const Row(
                                          children: [
                                            Icon(Icons.location_on, size: 16, color: Colors.grey),
                                            Text('Gần đây', style: TextStyle(color: Colors.grey)),
                                          ],
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    const Text(
                                      '2D Phụ Đề Việt',
                                      style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: showtimes.map((st) {
                                        final showtimeId = st['malichchieu'] ?? '';
                                        final roomName = st['tenphong'] ?? st['tenPhong'] ?? st['TENPHONG'] ?? 'Phòng chưa rõ';
                                        final price = (st['giave'] ?? 0);
                                        
                                        // Parse giờ chiếu
                                        String timeDisplay = '';
                                        String dateLabel = '';
                                        if (st['giochieu'] != null) {
                                          final dt = DateTime.tryParse(st['giochieu'].toString());
                                          if (dt != null) {
                                            timeDisplay = DateFormat('HH:mm').format(dt);
                                            dateLabel = DateFormat('dd/MM').format(dt);
                                          }
                                        }

                                        return InkWell(
                                          onTap: () {
                                            bookingVM.selectShowtime(
                                              showtimeId,
                                              price.toDouble(),
                                              theaterName: cinemaName,
                                              roomName: roomName,
                                              timeDisplay: timeDisplay,
                                              dateDisplay: dateLabel,
                                            );
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const SeatSelectionScreen()),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  timeDisplay,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                ),
                                                // Hiển thị thêm ngày nếu đang ở chế độ "Tất cả"
                                                if (_selectedDateIndex == 0)
                                                  Text(dateLabel, style: const TextStyle(fontSize: 10, color: Colors.black45)),
                                                Text(
                                                  '${(price/1000).toStringAsFixed(0)}K',
                                                  style: const TextStyle(fontSize: 10, color: Color(0xFFE51937)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              );
                            },
                          ),
          )
        ],
      ),
    );
  }

  Widget _buildDateItem(int index, String label) {
    bool isSelected = _selectedDateIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDateIndex = index;
        });
        _loadShowtimes();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE51937) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFE51937) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }
}
