# Verifikasi review AI vs keputusan teknis

Ruang lingkup: PR #3 (`chore/static-analysis` -> `develop`), terutama workflow CI dan aplikasi `07-week-7-clean-architecture/campus_notify`.

## Bukti verifikasi

- `flutter analyze`: `No issues found!`
- `flutter test`: 11 test lulus (`All tests passed!`).
- `dart format --output=none --set-exit-if-changed lib test`: `Formatted 26 files (0 changed)`.
- `rg -n 'note_data_providers|GetNotes|Provider<NoteRepository>' .../presentation/providers/note_providers.dart .../data/providers/note_data_providers.dart` menemukan bahwa `note_providers.dart` mengimpor `../../data/providers/note_data_providers.dart` dan membuat `GetNotes` dari `noteRepositoryProvider`.
- `rg -n 'package:(flutter|dio|sqflite|firebase)' .../domain`: tidak menemukan import tersebut di domain. Usulan di bawah tidak memindahkan import framework/infrastruktur ke domain.
- `.github/workflows/ci.yml` menjalankan `flutter pub get`, `flutter analyze`, dan `flutter test`; tidak ada langkah formatter atau pemeriksaan aturan dependency.
- GitHub check `verify` pada PR ini berstatus `success`. CI hijau tidak membuktikan batas arsitektur atau format diperiksa.

## Kandidat temuan AI dan keputusan

### 1. Presentation notes mengimpor provider dari data

**Level: saran — terkonfirmasi; bukan regresi perilaku yang diperkenalkan PR.**

**Bukti:** `lib/features/notes/presentation/providers/note_providers.dart` mengimpor provider dari `features/notes/data` dan menggunakannya untuk membangun use case. Arah itu melanggar dependency rule feature-first: presentation seharusnya bergantung pada domain, bukan implementasi data. Temuan ini sudah ditandai sebagai tindak lanjut di `08-week-8-mid-project-review/docs/review-checklist.md`. Tidak ada import Flutter, Dio, atau SQLite dari domain.

**Usulan:** jadikan repository provider sebagai kontrak yang dipakai presentation, lalu ikat implementasi repository hanya di composition root (`main.dart`/`ProviderScope` override). Domain tetap hanya mengetahui interface.

```dart
// presentation/providers/note_providers.dart
import '../../domain/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (_) => throw StateError('noteRepositoryProvider must be overridden'),
);

final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);
```

```dart
// composition root: imports data implementation dan presentation provider
ProviderScope(
  overrides: [
    noteRepositoryProvider.overrideWith(
      (_) => NoteRepositoryImpl(openDb: openNotesDb),
    ),
  ],
  child: const App(),
);
```

**Keputusan:** catat sebagai saran arsitektur untuk tindak lanjut, bukan blocker PR ini: perubahan PR pada Dart adalah format/import spacing saja, sedangkan batas tersebut telah ada sebelum perubahan ini.

### 2. CI belum melindungi dependency rule

**Level: saran — terkonfirmasi sebagai celah pengujian.**

**Bukti:** pemindaian source menemukan pelanggaran pada poin 1, sementara analyzer dan 11 test tetap lulus. Workflow baru hanya menjalankan analyzer dan test, sehingga pemeriksaan yang ada tidak mencegah pelanggaran dependency rule tersebut kembali.

**Usulan:** setelah menetapkan aturan dependency yang ingin dijaga, tambahkan test arsitektur atau pemeriksaan CI yang gagal untuk import `data` dari `presentation` (dan import framework/infrastruktur di `domain`). Jangan membuat domain mengimpor Flutter, Dio, SQLite, maupun Riverpod.

```yaml
# Contoh pemeriksaan sederhana di workflow Linux; sesuaikan glob dengan aturan repo.
- name: Check notes layer boundaries
  run: |
    ! grep -R -n -E "features/notes/data" lib/features/notes/presentation
    ! grep -R -n -E "package:(flutter|dio|sqflite|firebase)" lib/features/notes/domain
```

**Keputusan:** layak ditambahkan sebagai tindak lanjut. Contoh di atas adalah guard sederhana, bukan pengganti desain injection pada poin 1.

### 3. CI tidak memastikan Dart terformat

**Level: saran — terkonfirmasi sebagai celah workflow.**

**Bukti:** langkah workflow berakhir setelah `flutter analyze` dan `flutter test`; tidak ada pemanggilan `dart format`. Analyzer tidak menjamin seluruh perubahan mematuhi hasil formatter. Saat ini formatter lokal mengonfirmasi 26 file tidak memerlukan perubahan.

**Usulan:**

```yaml
- run: dart format --output=none --set-exit-if-changed lib test
```

**Keputusan:** tambahkan pemeriksaan ini bila CI memang dimaksudkan menjaga format, tetapi tidak ada masalah format yang terbukti pada versi PR saat diverifikasi.

### 4. CI mengikuti channel Flutter `stable` yang bergerak

**Level: saran — risiko reproduksibilitas terkonfirmasi dari konfigurasi; belum ada kegagalan aktual.**

**Bukti:** workflow menggunakan `subosito/flutter-action@v2` dengan `channel: stable`, bukan versi Flutter tertentu. Dengan demikian, commit yang sama dapat diuji dengan toolchain berbeda ketika channel stable diperbarui.

**Usulan:** pin versi yang benar-benar sudah diverifikasi dan perbarui secara terencana, misalnya:

```yaml
with:
  flutter-version: ${{ vars.FLUTTER_VERSION }}
```

Set `FLUTTER_VERSION` ke versi Flutter proyek yang sudah diuji. Versi Dart minimum di `pubspec.yaml` bukan versi Flutter, jadi jangan menyalin angka SDK Dart sebagai versi Flutter.

**Keputusan:** saran reliabilitas, bukan blocker; tidak ada bukti bahwa workflow PR saat ini gagal karena toolchain.

### 5. “Constructor satu baris lebih sulit dibaca; kembalikan ke multiline”

**Level: saran — ditolak sebagai nitpick style.**

**Bukti:** diff mengubah bentuk constructor/widget dan pemanggilan serupa, sedangkan `dart format --output=none --set-exit-if-changed lib test` melaporkan 0 file berubah. Tidak ada perubahan perilaku yang ditunjukkan test/analyzer.

**Usulan AI:** mempertahankan format multiline secara manual.

**Keputusan:** tolak; ini hanya preferensi format yang seharusnya diputuskan formatter/CI, bukan temuan correctness atau arsitektur. Tidak perlu potongan kode perbaikan.

## Keputusan akhir

Tidak ditemukan regresi runtime pada perubahan Dart yang diformat; analyzer dan seluruh test lulus. Dua masalah arsitektur/CI yang nyata (dependency presentation -> data dan tidak adanya guard arsitektur) perlu ditindaklanjuti, ditambah pemeriksaan format dan pinning toolchain untuk memperkuat CI. Tidak ada perubahan aplikasi yang diterapkan dalam review ini.
