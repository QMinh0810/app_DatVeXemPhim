import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final Map<String, dynamic> order;

  const TicketDetailScreen({super.key, required this.ticket, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background for premium feel
      appBar: AppBar(
        title: const Text('Chi Tiết Vé', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Ticket Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Top Section: Movie Poster & Basic Info
                    _buildTopSection(),
                    
                    // Dashed Line with Cutouts
                    _buildDashedDivider(),
                    
                    // Bottom Section: QR Code & Detailed Info
                    _buildBottomSection(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Back Button or Action
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE51937),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'QUAY LẠI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Movie Poster (Small)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              order['posterUrl'] ?? '',
              width: 100,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(width: 100, height: 150, color: Colors.grey[300], child: const Icon(Icons.movie, size: 50, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 16),
          // Movie Name
          Text(
            order['tenPhim'] ?? 'Tên phim',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          // Cinema Name & Address
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order['tenRapPhim'] ?? 'Rạp phim',
                  style: const TextStyle(color: Color(0xFFE51937), fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              if (order['diaChi'] != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    order['diaChi'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Row(
      children: [
        Transform.translate(offset: const Offset(-10, 0), child: _buildCutout()),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => const SizedBox(
                    width: 5,
                    height: 1,
                    child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE9ECEF))),
                  ),
                ),
              );
            },
          ),
        ),
        Transform.translate(offset: const Offset(10, 0), child: _buildCutout()),
      ],
    );
  }

  Widget _buildCutout() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Info Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Ngày', order['ngayChieu'] ?? ''),
              _buildInfoItem('Giờ', order['gioChieu'] ?? ''),
              _buildInfoItem('Phòng', order['tenPhong'] ?? ''),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
               _buildInfoItem('Ghế', ticket['tenGhe'] ?? ''),
               _buildInfoItem('Mã vé', ticket['maVe'].toString()),
            ],
          ),
          const SizedBox(height: 30),
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE9ECEF)),
              boxShadow: const [
                BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 4))
              ]
            ),
            child: QrImageView(
              data: ticket['qrCode'] ?? ticket['maVe'].toString(),
              version: QrVersions.auto,
              size: 180.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A1A)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Quét mã này tại quầy để nhận vé',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
