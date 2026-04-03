import 'package:flutter/material.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data mô phỏng bảng VeXemPhim, LichChieu, RapPhim
    final List<Map<String, dynamic>> tickets = [
      {
        'maVe': 'VX001',
        'tenPhim': 'DUNE: HÀNH TINH CÁT 2',
        'ngayChieu': '10/04/2024',
        'gioChieu': '18:00',
        'rapPhim': 'Nhóm 7 Cinema Sư Vạn Hạnh',
        'phong': 'PR01',
        'ghe': 'F3, F4',
        'trangThai': 'upcoming', // upcoming, passed
        'imageUrl': 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2TGbiROox.jpg',
      },
      {
        'maVe': 'VX002',
        'tenPhim': 'MAI',
        'ngayChieu': '06/03/2024',
        'gioChieu': '20:15',
        'rapPhim': 'Nhóm 7 Cinema Gò Vấp',
        'phong': 'PR03',
        'ghe': 'H5, H6',
        'trangThai': 'passed',
        'imageUrl': 'https://upload.wikimedia.org/wikipedia/vi/a/a8/Mai_2024_poster.jpg',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Vé Của Tôi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          bool isUpcoming = ticket['trangThai'] == 'upcoming';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Row(
              children: [
                // Ticket Image (Poster)
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                  child: Image.network(
                    ticket['imageUrl'],
                    width: 100,
                    height: 160,
                    fit: BoxFit.cover,
                    color: isUpcoming ? null : Colors.black.withOpacity(0.5),
                    colorBlendMode: isUpcoming ? null : BlendMode.darken,
                    errorBuilder: (c, e, s) => Container(width: 100, height: 160, color: Colors.grey[300]),
                  ),
                ),
                // Ticket Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text(ticket['tenPhim'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis,)),
                            if (isUpcoming) const Icon(Icons.qr_code_2, color: Color(0xFFE51937))
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${ticket['gioChieu']} - ${ticket['ngayChieu']}', style: TextStyle(color: isUpcoming ? const Color(0xFFE51937) : Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(ticket['rapPhim'], style: const TextStyle(color: Colors.black87, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('Phòng: ${ticket['phong']} | Ghế: ${ticket['ghe']}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: isUpcoming ? Colors.green : Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isUpcoming ? 'SẮP CHIẾU' : 'ĐÃ XEM',
                            style: TextStyle(color: isUpcoming ? Colors.green : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
