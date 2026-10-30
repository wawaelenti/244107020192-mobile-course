# AI log - Praktikum 1: Prompt dan context engineering

## Tujuan

Menulis prompt lima slot dan memilih konteks secukupnya untuk tugas search
judul catatan pada project `week5_offline_notes`. Praktikum ini berfokus pada
prompt; implementasi search disimpan untuk Praktikum 2.

## Prompt buruk

```text
Buatkan search notes yang keren.
```

Prompt ini tidak menentukan peran, arsitektur, batas perubahan, empty state,
atau bentuk hasil yang bisa diverifikasi.

## Prompt final (prompt mentah)

```text
Peran: senior Flutter developer.
Konteks: project week5_offline_notes menggunakan Flutter, Riverpod, dan
SQLite (sqflite). Halaman catatan membaca data melalui NoteRepository.
Model Note memiliki field title, body, updatedAt, dan dirty. Aplikasi harus
tetap dapat membaca serta mengelola catatan secara offline.
Tugas: rancang fitur pencarian berdasarkan judul catatan dan empty state
ketika tidak ada judul yang cocok.
Batas: jangan panggil SQLite dari widget, jangan ubah repository atau fitur
offline yang tidak diperlukan, dan batasi perubahan hanya pada search.
Output: usulan file yang perlu diubah, implementasi ringkas, minimal satu
test untuk hasil cocok dan satu test untuk hasil kosong, serta langkah uji
manual. Jelaskan asumsi yang belum pasti dan jangan mengarang API/package.
```

## Konteks yang dipilih

Struktur relevan:

```text
lib/
  data/
    local/note.dart
    repositories/note_repository.dart
  pages/notes_page.dart
  widgets/note_tile.dart
```

Kontrak repository yang ditempel:

```dart
Future<List<Note>> fetchNotes();
Future<Note> addNote({required String title, String body = ''});
Future<void> deleteNote(int id);
Future<int> countDirty();
```

Model yang relevan:

```dart
final String title;
final String body;
```

Versi dependency yang relevan dari `pubspec.yaml`:

```yaml
flutter_riverpod: ^3.4.3
sqflite: ^2.4.4
```

Konteks sengaja dibatasi pada halaman catatan, model, kontrak repository,
struktur folder, dan dependency yang berhubungan. Tidak menyertakan seluruh
repository, token, API key, password, atau data pribadi.

## Output Praktikum 1

Output tahap ini adalah prompt lima slot di atas dan konteks yang dipilih.
Tidak ada kode search atau test implementasi yang dibuat sebagai bagian
Praktikum 1; keduanya merupakan pekerjaan Praktikum 2.

## Evaluasi prompt

| Kriteria | Hasil |
| --- | --- |
| Peran jelas | Senior Flutter developer |
| Konteks konkret | Riverpod, SQLite, `NoteRepository`, field `Note`, dan kebutuhan offline |
| Tugas terukur | Search berdasarkan judul dengan empty state |
| Batas perubahan | Tidak mengakses SQLite dari widget dan tidak mengubah fitur lain |
| Output dapat diverifikasi | File/implementasi yang diusulkan, dua test, dan langkah uji manual |

Prompt final lebih spesifik daripada prompt buruk, menghindari pengiriman
secret, dan memberi AI kontrak nyata dari project alih-alih meminta asumsi API.
