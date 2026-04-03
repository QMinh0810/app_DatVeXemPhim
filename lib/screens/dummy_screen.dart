import 'package:flutter/material.dart';

class DummyScreen extends StatelessWidget {
  final String title;

  const DummyScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Text(
          'Màn hình $title đang được phát triển...',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
