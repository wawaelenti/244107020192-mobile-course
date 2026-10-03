import 'package:flutter/material.dart';

class AnnouncementPage extends StatelessWidget {
  final String id;

  const AnnouncementPage({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengumuman'),
      ),
      body: Center(
        child: Text(
          'ID Pengumuman: $id',
          style: const TextStyle(
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}