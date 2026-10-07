import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_controller.dart';
import '../routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.auth, required this.tokenPreview, super.key});

  final AuthController auth;
  final ValueListenable<String?> tokenPreview;

  static const _announcements = [
    (
      id: '2026-101',
      title: 'Jadwal Ujian Tengah Semester',
      category: 'Akademik',
      date: 'Hari ini · 09.30',
      icon: Icons.event_available,
    ),
    (
      id: '2026-102',
      title: 'Pendaftaran Beasiswa Prestasi',
      category: 'Kemahasiswaan',
      date: 'Kemarin · 14.15',
      icon: Icons.school_outlined,
    ),
    (
      id: '2026-103',
      title: 'Pemeliharaan jaringan kampus',
      category: 'Informasi',
      date: '2 Okt · 11.00',
      icon: Icons.wifi_tethering,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Campus Notify',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF183D70), Color(0xFF3677D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUSAT INFORMASI KAMPUS',
                  style: TextStyle(
                    color: Color(0xFFD5E6FF),
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Tetap terhubung\n dengan kampus.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Pengumuman penting langsung di genggamanmu.',
                  style: TextStyle(color: Color(0xFFE5EFFF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengumuman terbaru',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => context.go(
                  AppRoutes.announcementById(_announcements.first.id),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final announcement in _announcements)
            Card(
              elevation: 0,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.primary,
                  child: Icon(announcement.icon),
                ),
                title: Text(
                  announcement.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${announcement.category}  ·  ${announcement.date}',
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    context.go(AppRoutes.announcementById(announcement.id)),
              ),
            ),
          const SizedBox(height: 10),
          ValueListenableBuilder<String?>(
            valueListenable: tokenPreview,
            builder: (context, preview, _) {
              if (preview == null) return const SizedBox.shrink();
              return _StatusCard(
                icon: Icons.phonelink_lock,
                title: 'Token perangkat (disamarkan)',
                detail: preview,
              );
            },
          ),
          const SizedBox(height: 10),
          const _StatusCard(
            icon: Icons.topic_outlined,
            title: 'Topik langganan',
            detail: 'pengumuman-kampus',
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2764C5)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
      ),
    );
  }
}
