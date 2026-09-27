import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data.dart';
import '../note.dart';
import '../providers.dart';
import 'note_editor_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref
          .read(preferencesRepositoryProvider)
          .saveLastOpened(DateTime.now());
      ref.invalidate(lastOpenedProvider);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openEditor([Note? note]) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => NoteEditorPage(note: note)));
    if (saved == true) {
      ref.invalidate(notesProvider);
      ref.invalidate(pendingSyncCountProvider);
    }
  }

  Future<void> _sync() async {
    try {
      final count = await ref.read(notesRepositoryProvider).syncNotes();
      ref.invalidate(notesProvider);
      ref.invalidate(pendingSyncCountProvider);
      if (mounted) {
        _message(
          count == 0
              ? 'Tidak ada perubahan untuk disinkronkan.'
              : '$count perubahan dikirim ke server demo.',
        );
      }
    } on SyncException catch (error) {
      ref.invalidate(pendingSyncCountProvider);
      if (mounted) {
        _message(
          '${error.synced} terkirim, ${error.failed} masih menunggu koneksi.',
        );
      }
    } on Exception {
      if (mounted) {
        _message('Sync gagal. Catatan tetap tersimpan dan berstatus dirty.');
      }
    }
  }

  Future<void> _delete(Note note) async {
    if (note.id == null) return;
    await ref.read(notesRepositoryProvider).deleteNote(note.id!);
    ref.invalidate(notesProvider);
    ref.invalidate(pendingSyncCountProvider);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final lastOpened = ref.watch(lastOpenedProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lembar', style: TextStyle(fontWeight: FontWeight.w800)),
            Text(
              lastOpened == null
                  ? 'Ruang catatan offline'
                  : 'Terakhir dibuka ${_formatDate(lastOpened)}',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: darkMode ? 'Gunakan tema terang' : 'Gunakan tema gelap',
            onPressed: () => ref
                .read(themeControllerProvider.notifier)
                .setDarkMode(!darkMode),
            icon: Icon(
              darkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabs,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                labelColor: colors.onPrimary,
                unselectedLabelColor: colors.onSurfaceVariant,
                tabs: const [
                  Tab(text: 'Catatan'),
                  Tab(text: 'Bacaan'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildNotes(colors), _buildReadings(colors)],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Catatan baru'),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNotes(ColorScheme colors) {
    final pending = ref.watch(pendingSyncCountProvider);
    final notesAsync = ref.watch(notesProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notesProvider);
        await ref.read(notesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ruang pikiran',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Disimpan di perangkat ini',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              pending.when(
                data: (count) => _SyncButton(count: count, onPressed: _sync),
                loading: () => const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => IconButton(
                  onPressed: _sync,
                  tooltip: 'Coba sinkronkan',
                  icon: const Icon(Icons.sync),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (value) =>
                setState(() => _query = value.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Cari judul atau isi catatan',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),
          notesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _StateMessage(
              icon: Icons.storage_outlined,
              title: 'Catatan belum dapat dibuka',
              detail: '$error',
            ),
            data: (notes) {
              final visible = notes
                  .where(
                    (note) =>
                        note.title.toLowerCase().contains(_query) ||
                        note.body.toLowerCase().contains(_query),
                  )
                  .toList();
              if (visible.isEmpty) {
                return _StateMessage(
                  icon: _query.isEmpty ? Icons.edit_note : Icons.search_off,
                  title: _query.isEmpty
                      ? 'Mulai dengan satu catatan'
                      : 'Tidak ada hasil',
                  detail: _query.isEmpty
                      ? 'Catatan baru tetap tersedia saat perangkat offline.'
                      : 'Coba kata kunci yang berbeda.',
                );
              }
              return Column(
                children: [
                  for (final note in visible)
                    _NoteCard(
                      note: note,
                      onTap: () => _openEditor(note),
                      onDelete: () => _delete(note),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadings(ColorScheme colors) {
    final readings = ref.watch(readingsProvider);
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(notesRepositoryProvider).fetchReadings(refresh: true);
        ref.invalidate(readingsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bacaan pilihan',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Icon(Icons.offline_pin_outlined, color: colors.primary),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Cache lokal ditampilkan lebih dulu; tarik ke bawah untuk memperbarui.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          readings.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _StateMessage(
              icon: Icons.wifi_off,
              title: 'Belum ada cache bacaan',
              detail:
                  'Sambungkan internet sekali untuk mengunduh bacaan. Detail: $error',
            ),
            data: (items) => items.isEmpty
                ? const _StateMessage(
                    icon: Icons.menu_book_outlined,
                    title: 'Belum ada bacaan tersimpan',
                    detail: 'Tarik ke bawah saat online untuk mengisi cache.',
                  )
                : Column(
                    children: [
                      for (final item in items) _ReadingCard(item: item),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: onPressed,
    icon: Icon(
      count > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
      size: 18,
    ),
    label: Text(count > 0 ? 'Sync $count' : 'Tersinkron'),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.body.isEmpty ? 'Belum ada isi' : note.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          _formatDate(note.updatedAt),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 10),
                        _DirtyBadge(dirty: note.dirty),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Hapus catatan',
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DirtyBadge extends StatelessWidget {
  const _DirtyBadge({required this.dirty});
  final bool dirty;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: dirty ? const Color(0xFFFFE8D8) : const Color(0xFFDDF3E8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      dirty ? 'Belum sync' : 'Tersinkron',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: dirty ? const Color(0xFF9A4A12) : const Color(0xFF236844),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.item});
  final ReadingItem item;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(item.body, maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text(
            'TERSIMPAN OFFLINE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 38, color: colors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day}/${date.month}/${date.year} ${date.hour}:$minute';
}
