import 'package:flutter/material.dart';

class HorizontalImageList extends StatelessWidget {
  final String title;
  final List<String> imageUrls;
  final double imageHeight;
  final double imageWidth;
  final double borderRadius;

  const HorizontalImageList({
    super.key,
    required this.title,
    required this.imageUrls,
    this.imageHeight = 120,
    this.imageWidth = 200,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'TẤT CẢ',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: imageHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Image.network(
                  imageUrls[index],
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: imageWidth,
                    height: imageHeight,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.image)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
