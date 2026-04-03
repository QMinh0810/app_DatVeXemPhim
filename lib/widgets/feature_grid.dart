import 'package:flutter/material.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> features = [
      {'icon': Icons.favorite, 'title': 'SWEETBOX'},
      {'icon': Icons.screenshot_monitor, 'title': 'IMAX'},
      {'icon': Icons.control_camera, 'title': '4DX'},
      {'icon': Icons.maps_home_work_outlined, 'title': 'THUÊ RẠP'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: features.map((feature) {
          return Column(
            mainAxisSize: MainAxisSize.min, // Fix potential layout unbounded height
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature['title'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
