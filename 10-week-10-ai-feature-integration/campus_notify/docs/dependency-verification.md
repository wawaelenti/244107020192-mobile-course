# Verifikasi Dependency

## 1. Verifikasi Repository

```powershell
rg -n --glob '*.dart' 'abstract class NoteRepository|class NoteRepositoryImpl implements NoteRepository' lib\features\notes
```

Hasil menunjukkan `NoteRepository` berada di domain dan `NoteRepositoryImpl` berada di data. Exit code `0`.

## 2. Verifikasi Import Domain

```powershell
rg -n --glob '*.dart' 'package:(flutter|dio|sqflite|firebase)' lib\features\notes\domain
```

Tidak ditemukan baris yang cocok. Exit code `1` menunjukkan tidak ada hasil yang sesuai dengan pola pencarian.

## 3. Verifikasi Dependency Riverpod

```powershell
rg -n --glob '*.dart' 'NoteRepositoryImpl|noteRepositoryProvider|ref\.watch\((getNotesProvider|notesProvider)\)' lib\features\notes
```

Hasil menunjukkan provider data membangun repository dan halaman menggunakan `notesProvider`. Namun, provider presentation masih mengimpor provider data sehingga arah dependency perlu dirapikan.

## 4. Bukti Pengujian

### Struktur Folder

![Struktur folder Praktikum 3](/screenshot/Praktikum%203%20-%20Struktur%20folder.png)

### Hasil Pemeriksaan dan Pengujian

| Pemeriksaan | Hasil | Bukti |
|---|---|---|
| Domain | Tidak ditemukan import yang cocok dengan pola pencarian. | ![Pengecekan domain](/screenshot/Praktikum%203%20-%20Cek%20layer%20domain.png) |
| Presentation | Halaman menggunakan provider, tetapi provider presentation masih mengimpor provider data. | ![Pengecekan presentation](/screenshot/Praktikum%203%20-%20Cek%20layer%20presentation.png) |
| Flutter Analyze | Berhasil dijalankan. | ![Flutter Analyze](/screenshot/Praktikum%203%20-%20Flutter%20analyze.png) |
| Flutter Test | Seluruh pengujian berhasil. | ![Flutter Test](/screenshot/Praktikum%203%20-%20Flutter%20test.png) |

## Kesimpulan

Pemeriksaan menunjukkan bahwa repository notes telah dipisahkan sesuai layer dan domain tidak memiliki import yang cocok dengan pola pencarian. Riverpod digunakan untuk mengelola dependency dan state. Pengujian analisis statis serta test berhasil, tetapi pemeriksaan ini belum mencakup seluruh fitur auth dan announcements.