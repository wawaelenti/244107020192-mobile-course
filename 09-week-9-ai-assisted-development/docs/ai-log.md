# AI log - Praktikum 1 dan 2

Project: `week5_offline_notes`, Flutter dengan Riverpod `^3.4.3` dan SQLite
(`sqflite ^2.4.4`).

## Praktikum 1 - Prompt dan context engineering

### Prompt buruk

```text
Buatkan search notes yang keren.
```

Tidak menjelaskan peran, konteks, batas perubahan, empty state, maupun bentuk
hasil yang bisa diverifikasi.

### Prompt final lima slot

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

Konteks yang dipilih: `lib/pages/notes_page.dart`,
`lib/data/local/note.dart`, `lib/data/repositories/note_repository.dart`,
struktur folder relevan, dan versi dependency. Repository menyediakan
`fetchNotes()`, `addNote()`, `deleteNote()`, dan `countDirty()`. Tidak ada
secret, token, password, atau seluruh isi repository yang disertakan.

## Praktikum 2 - Generate dan verifikasi search

### Prompt Praktikum 2

```text
Peran: senior Flutter developer.
Konteks: lanjutkan week5_offline_notes. NotesPage adalah ConsumerWidget
Riverpod yang membaca List<Note> dari notesProvider. Note memiliki title.
Pertahankan data lokal/offline dan pola repository yang ada.
Tugas: tambahkan pencarian berdasarkan judul catatan dan empty state jika
query tidak cocok.
Batas: pencarian case-insensitive, query kosong menampilkan semua catatan,
jangan panggil SQLite dari UI, jangan ubah repository/schema atau fitur lain.
Pastikan fungsi filter murni di lib/domain tanpa import Flutter, Dio, atau
SQLite. Tulis unit test untuk judul cocok dan tidak cocok serta widget test
empty state.
Output: perubahan ringkas, test, dan langkah verifikasi.
```

### Output awal AI dan verifikasi

Draft awal filter mencari teks dengan pencocokan case-sensitive:

```dart
return notes
    .where((note) => titleOf(note).contains(normalizedQuery))
    .toList();
```

Test merah dibuat sebelum memperbaiki draft: judul `Belanja Mingguan` dan
`Catatan belanja` dicari dengan query `belanja`. Test awal gagal karena hanya
1 catatan yang ditemukan, padahal diharapkan 2. Filter kemudian dinormalisasi
ke lowercase pada query dan judul.

### Implementasi yang diterima

- `lib/domain/filter_notes.dart`: fungsi generik `filterNotes<T>` menerima
  daftar dan callback untuk mengambil judul. Domain tidak mengimpor model data
  atau package UI/storage.
- `lib/pages/notes_page.dart`: mengelola query dan menampilkan hasil; empty
  state pencarian dibedakan dari state database kosong.
- `test/search_filter_test.dart`: menguji kecocokan case-insensitive, query
  kosong, dan query yang tidak cocok.
- `test/notes_search_test.dart`: menguji pesan empty state tanpa mengakses
  database asli (menggunakan repository palsu).

### Enam langkah verifikasi

| Langkah | Hasil |
| --- | --- |
| Membaca perubahan dan memeriksa asumsi | Filter menerima judul via callback; tidak menyimpan query dan tidak mengakses database. |
| Memeriksa import domain | `filter_notes.dart` tidak memiliki import Flutter, Dio, SQLite, atau data layer. |
| Memeriksa API | Menggunakan `trim`, `toLowerCase`, `contains`, callback Dart, dan API Flutter/Riverpod yang sudah dipakai project; tidak menambah dependency. |
| `flutter analyze` | Lulus: `No issues found!`. |
| Test berhasil dan test gagal untuk search | Test awal case-sensitive gagal; setelah perbaikan seluruh 8 test pada `flutter test` lulus, termasuk hasil cocok, kosong, tak cocok, dan empty state widget. |
| Uji manual query kosong/cocok/tidak cocok | Tidak dijalankan karena project tidak boleh dijalankan dalam sesi ini. Langkah uji disediakan di README. |

### Keputusan

| Saran | Keputusan | Alasan |
| --- | --- | --- |
| Letakkan filter pada fungsi domain murni. | Terima | Mudah diuji secara unit dan tidak mencampur filter dengan UI/database. |
| Simpan query ke SQLite atau SharedPreferences. | Tolak | Query pencarian hanya state sementara UI, bukan data catatan atau preferensi. |
| Gunakan exact/case-sensitive match. | Tolak | Test query `belanja` terhadap judul dengan variasi kapitalisasi gagal; pencarian lowercase sesuai kebutuhan search. |
| Bedakan database kosong dari hasil search kosong. | Terima | Pengguna mendapat pesan yang sesuai untuk belum memiliki catatan vs tidak menemukan kecocokan. |

## Privasi

Tidak ada token FCM, JWT, API key, password, atau kredensial yang digunakan.
