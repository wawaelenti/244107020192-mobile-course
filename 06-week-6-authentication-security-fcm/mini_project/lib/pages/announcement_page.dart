import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnnouncementPage extends StatelessWidget {
  const AnnouncementPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Detail pengumuman'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEAFF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Color(0xFF2764C5),
              size: 76,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PENGUMUMAN KAMPUS',
            style: TextStyle(
              color: Color(0xFF2764C5),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Informasi penting untuk mahasiswa',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'ID pengumuman: $id',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Silakan periksa detail pengumuman dan jadwal terbaru melalui '
            'portal akademik kampus. Notifikasi ini dikirim untuk membantu '
            'mahasiswa mendapatkan informasi tepat waktu.',
            style: TextStyle(fontSize: 16, height: 1.7),
          ),
          const SizedBox(height: 24),
          const Card(
            elevation: 0,
            color: Colors.white,
            child: ListTile(
              leading: Icon(Icons.calendar_month_outlined),
              title: Text('Diterbitkan oleh Biro Akademik'),
              subtitle: Text('Informasi resmi kampus'),
            ),
          ),
        ],
      ),
    );
  }
}
