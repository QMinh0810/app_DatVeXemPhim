import 'package:flutter/material.dart';
import 'seat_selection_screen.dart';

class ShowtimeSelectionScreen extends StatefulWidget {
  const ShowtimeSelectionScreen({super.key});

  @override
  State<ShowtimeSelectionScreen> createState() => _ShowtimeSelectionScreenState();
}

class _ShowtimeSelectionScreenState extends State<ShowtimeSelectionScreen> {
  int _selectedDateIndex = 0;
  
  final List<String> dates = ['Hôm nay', 'Ngày mai', 'T6\n22/03', 'T7\n23/03', 'CN\n24/03'];

  // Mock data for cinemas and showtimes
  final List<Map<String, dynamic>> cinemas = [
    {
      'name': 'CGV Vincom Mega Mall Grand Park',
      'distance': '4.5km',
      'formats': [
        {
          'type': '2D Phụ Đề Việt',
          'times': ['12:40', '15:10', '18:30', '21:10', '23:20']
        },
        {
          'type': 'IMAX Phụ Đề Việt',
          'times': ['14:00', '19:30']
        }
      ]
    },
    {
      'name': 'CGV Vincom Đồng Khởi',
      'distance': '12km',
      'formats': [
        {
          'type': '2D Phụ Đề Việt',
          'times': ['10:00', '13:00', '16:00', '19:00']
        }
      ]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('DUNE: HÀNH TINH CÁT 2', style: TextStyle(color: Colors.black, fontSize: 16)),
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
                children: List.generate(dates.length, (index) {
                  bool isSelected = _selectedDateIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDateIndex = index;
                      });
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
                        dates[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Cinema List
          Expanded(
            child: ListView.builder(
              itemCount: cinemas.length,
              itemBuilder: (context, index) {
                final cinema = cinemas[index];
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
                              cinema['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              Text(cinema['distance'], style: const TextStyle(color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Showtimes grouped by format
                      ...List.generate(cinema['formats'].length, (fmtIndex) {
                        final format = cinema['formats'][fmtIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              format['type'],
                              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: List.generate(format['times'].length, (timeIndex) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const SeatSelectionScreen()),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      format['times'][timeIndex],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
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
}
