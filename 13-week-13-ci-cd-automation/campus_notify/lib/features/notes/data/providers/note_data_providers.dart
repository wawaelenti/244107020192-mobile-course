import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/cached_note_repository.dart';
import '../repositories/platform_note_repository.dart';

final noteRepositoryProvider = Provider<CachedNoteRepository>((ref) {
  return CachedNoteRepository(createPlatformNoteRepository());
});
