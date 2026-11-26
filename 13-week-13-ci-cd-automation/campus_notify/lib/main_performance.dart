import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import 'features/notes/data/providers/note_data_providers.dart';
import 'features/notes/data/repositories/cached_note_repository.dart';
import 'features/notes/data/repositories/json_note_repository.dart';
import 'features/notes/presentation/page/note_page.dart';
import 'features/notes/presentation/providers/note_providers.dart';
import 'features/notes/presentation/widgets/notes_list.dart';

/// Entry khusus eksperimen web: data sintetis terpisah dari catatan pengguna.
void main() {
  const key = 'campus_notify.performance.notes.v1';
  final storage = web.window.localStorage;
  // Dataset identik pada setiap reload; tidak menyentuh storage aplikasi utama.
  storage.setItem(
    key,
    jsonEncode(
      List.generate(
        500,
        (i) => {
          'id': i + 1,
          'title': 'Catatan ${i.toString().padLeft(3, '0')} — Optimasi Flutter',
          'body': List.filled(
            18,
            'Catatan praktikum performa: ukur build, layout, cache, dan memory dengan skenario yang sama.',
          ).join('\n'),
          'updated_at': DateTime.utc(
            2026,
            11,
            12,
          ).subtract(Duration(minutes: i)).toIso8601String(),
          'dirty': 0,
        },
      ),
    ),
  );
  final source = JsonNoteRepository(
    read: () => storage.getItem(key),
    write: (value) => storage.setItem(key, value),
  );
  final baseline = Uri.base.queryParameters['variant'] == 'before';
  runApp(
    ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          CachedNoteRepository(source, enabled: !baseline),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campus Notify — Performance Lab',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: PerformanceLab(baseline: baseline, source: source),
      ),
    ),
  );
}

class PerformanceLab extends ConsumerStatefulWidget {
  const PerformanceLab({
    super.key,
    required this.baseline,
    required this.source,
  });
  final bool baseline;
  final JsonNoteRepository source;

  @override
  ConsumerState<PerformanceLab> createState() => _PerformanceLabState();
}

class _PerformanceLabState extends ConsumerState<PerformanceLab> {
  final _scroll = ScrollController();
  late final JSFunction _runHandler;
  late final JSFunction _memoryHandler;
  bool _running = false;
  String _status = 'Siap — 500 catatan, data uji terpisah';

  @override
  void initState() {
    super.initState();
    _runHandler = ((web.Event _) {
      unawaited(_runScenario());
    }).toJS;
    _memoryHandler = ((web.Event _) {
      unawaited(_memoryScenario());
    }).toJS;
    web.window.addEventListener('week11-run', _runHandler);
    web.window.addEventListener('week11-memory', _memoryHandler);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(notesProvider.future);
      web.document.body!.setAttribute('data-week11', 'ready');
    });
  }

  Future<void> _navigateDetail() async {
    final notes = await ref.read(notesProvider.future);
    if (!mounted) return;
    final navigation = openNoteDetail(context, notes.first);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    Navigator.of(context).pop();
    await navigation;
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _memoryScenario() async {
    if (_running) return;
    setState(() => _running = true);
    web.document.body!.setAttribute('data-week11', 'memory-running');
    for (var i = 0; i < 5; i++) {
      await _navigateDetail();
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _status = 'Memory: detail–kembali 5× selesai';
    });
    web.document.body!.setAttribute('data-week11', 'memory-done');
  }

  Future<void> _runScenario() async {
    if (_running) return;
    setState(() => _running = true);
    web.document.body!.setAttribute('data-week11', 'running');
    web.window.performance.mark('week11:scenario:start');
    final notes = await ref.read(notesProvider.future);
    await WidgetsBinding.instance.endOfFrame;
    _scroll.jumpTo(0);
    await _scroll.animateTo(
      2400,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.linear,
    );
    await _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 1200),
      curve: Curves.linear,
    );
    await _navigateDetail();
    // Jalur refresh memakai invalidasi yang sama dengan RefreshIndicator; CDP menguji
    // gesture secara terpisah. Jalur ini memakai invalidasi yang sama.
    ref.read(noteRepositoryProvider).invalidate();
    ref.invalidate(notesProvider);
    await ref.read(notesProvider.future);
    final readsBefore = widget.source.sourceReads;
    final timer = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      await ref.read(noteRepositoryProvider).fetchNotes();
    }
    timer.stop();
    final result = {
      'variant': widget.baseline ? 'before' : 'after',
      'items': notes.length,
      'sourceReadsFor20Calls': widget.source.sourceReads - readsBefore,
      'repository20CallsMs': timer.elapsedMicroseconds / 1000,
    };
    web.window.localStorage.setItem('week11.result', jsonEncode(result));
    web.window.performance.mark('week11:scenario:end');
    web.window.performance.measure(
      'week11:scenario',
      'week11:scenario:start'.toJS,
      'week11:scenario:end',
    );
    if (!mounted) return;
    setState(() {
      _running = false;
      _status =
          'Selesai — 20 pembacaan: ${result['sourceReadsFor20Calls']} akses sumber, ${result['repository20CallsMs']} ms';
    });
    web.document.body!.setAttribute('data-week11', 'done');
  }

  @override
  void dispose() {
    web.window.removeEventListener('week11-run', _runHandler);
    web.window.removeEventListener('week11-memory', _memoryHandler);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Campus Notify · ${widget.baseline ? 'Sebelum' : 'Sesudah'} optimasi',
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : _runScenario,
          child: const Text('Jalankan skenario'),
        ),
        TextButton(
          onPressed: _running ? null : _memoryScenario,
          child: const Text('Navigasi 5×'),
        ),
      ],
    ),
    body: Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.speed),
                const SizedBox(width: 12),
                Expanded(child: Text(_status)),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            'Praktikum Week 11 · Chrome profile · daftar → scroll → detail → kembali → refresh',
          ),
        ),
        Expanded(
          child: NotesPage(baseline: widget.baseline, controller: _scroll),
        ),
      ],
    ),
  );
}
