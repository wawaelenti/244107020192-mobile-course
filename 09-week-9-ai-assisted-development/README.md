# Week 9 - Praktikum 1 dan 2

Project praktikum menggunakan `week5_offline_notes` dari Week 5. Praktikum 1
berfokus pada prompt dan context engineering; Praktikum 2 menghasilkan fitur
pencarian judul catatan dan verifikasinya.

## Praktikum 1: Prompt dan context engineering

Prompt memakai lima slot: peran, konteks, tugas, batas, dan output. Konteks
dibatasi ke halaman catatan, `NoteRepository`, model `Note`, dan versi dependency
yang relevan. Prompt mentah dan catatan konteks ada di
[docs/ai-log.md](./docs/ai-log.md).

## Praktikum 2: Search judul

- Pencarian dilakukan pada daftar catatan yang dimuat melalui repository lokal.
- Pencocokan judul tidak peka huruf besar/kecil dan mengabaikan spasi di awal
  atau akhir query.
- Query kosong menampilkan semua catatan.
- Jika database berisi catatan tetapi tidak ada judul cocok, tampil empty state
  `Tidak ada catatan yang cocok`. Jika database kosong, pesan awal
  `Belum ada catatan` tetap digunakan.
- Fungsi filter berada di `lib/domain/filter_notes.dart`, generik, dan tidak
  mengimpor Flutter, Dio, SQLite, atau layer data.
- Tidak ada perubahan pada repository, schema SQLite, atau fitur offline.

### Bukti hasil Praktikum 2

| Query kosong                                                                     | Hasil pencarian                                                                            | Tidak ada hasil                                                                       |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| ![Query kosong menampilkan semua catatan](./screenshots/prak2_empty-string.jpeg) | ![Pencarian judul menampilkan catatan yang cocok](./screenshots/prak2_success-search.jpeg) | ![Query yang tidak cocok menampilkan empty state](./screenshots/prak2_not-found.jpeg) |

### Menjalankan verifikasi

```powershell
cd week5_offline_notes
flutter analyze
flutter test
```

Test mencakup pencarian case-insensitive, query kosong, query tak cocok, dan
empty state pada halaman catatan.

### Hasil verifikasi

- `flutter analyze`: lulus, tidak ada issue.
- `flutter test`: lulus, 8 test berhasil.
- `dart format --set-exit-if-changed` pada file Dart yang diubah: lulus.
- Aplikasi tidak dijalankan; uji manual belum dilakukan sesuai permintaan.

### Uji manual

Jalankan project sendiri bila siap untuk menguji:

1. Query kosong: semua catatan muncul.
2. Query yang cocok, termasuk beda kapitalisasi: judul terkait muncul.
3. Query yang tidak cocok: empty state `Tidak ada catatan yang cocok` muncul.

Project tidak dijalankan selama pengerjaan ini sesuai permintaan.
