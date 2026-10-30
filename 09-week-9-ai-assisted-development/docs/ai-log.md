# AI log - Praktikum 1, 2, dan 3

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

| Langkah                                   | Hasil                                                                                                                                                        |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Membaca perubahan dan memeriksa asumsi    | Filter menerima judul via callback; tidak menyimpan query dan tidak mengakses database.                                                                      |
| Memeriksa import domain                   | `filter_notes.dart` tidak memiliki import Flutter, Dio, SQLite, atau data layer.                                                                             |
| Memeriksa API                             | Menggunakan `trim`, `toLowerCase`, `contains`, callback Dart, dan API Flutter/Riverpod yang sudah dipakai project; tidak menambah dependency.                |
| `flutter analyze`                         | Lulus: `No issues found!`.                                                                                                                                   |
| Test berhasil dan test gagal untuk search | Test awal case-sensitive gagal; setelah perbaikan seluruh 9 test pada `flutter test` lulus, termasuk hasil cocok, kosong, tak cocok, dan empty state widget. |
| Uji manual query kosong/cocok/tidak cocok | Tidak dijalankan karena project tidak boleh dijalankan dalam sesi ini. Langkah uji disediakan di README.                                                     |

### Keputusan

| Saran                                             | Keputusan | Alasan                                                                                                              |
| ------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------- |
| Letakkan filter pada fungsi domain murni.         | Terima    | Mudah diuji secara unit dan tidak mencampur filter dengan UI/database.                                              |
| Simpan query ke SQLite atau SharedPreferences.    | Tolak     | Query pencarian hanya state sementara UI, bukan data catatan atau preferensi.                                       |
| Gunakan exact/case-sensitive match.               | Tolak     | Test query `belanja` terhadap judul dengan variasi kapitalisasi gagal; pencarian lowercase sesuai kebutuhan search. |
| Bedakan database kosong dari hasil search kosong. | Terima    | Pengguna mendapat pesan yang sesuai untuk belum memiliki catatan vs tidak menemukan kecocokan.                      |

## Privasi

Tidak ada token FCM, JWT, API key, password, atau kredensial yang digunakan.

## Praktikum 3 - Debug dan refactor

### Reproduksi dan akar masalah

Langkah reproduksi: siapkan judul `Belanja Mingguan` dan `Catatan belanja`,
lalu cari `belanja`. Draft awal memakai `String.contains` langsung, yang
case-sensitive. Karena itu hanya `Catatan belanja` yang cocok, sedangkan
`Belanja Mingguan` terlewat.

Test merah `filter mengabaikan huruf besar dan kecil` mereproduksi bug:
hasil aktual berisi 1 catatan, padahal hasil yang benar 2. Akar masalah ada
pada normalisasi teks yang tidak dilakukan sebelum pencocokan, bukan pada
repository atau penyimpanan SQLite. Perbaikan: trim query, ubah query dan
judul ke lowercase, lalu jalankan ulang test.

### Refactor dan batas layer

Review terhadap kode:

- `filterNotes` adalah fungsi murni kecil di `lib/domain/filter_notes.dart`.
  Panjangnya di bawah 40 baris dan mencakup hanya aturan pencarian.
- Fungsi menerima `titleOf` sebagai callback generik; domain tidak perlu
  mengimpor `Note`, Flutter, Riverpod, Dio, atau SQLite.
- `NotesPage` memegang input query dan rendering; baca/hapus catatan tetap
  melalui provider dan repository seperti sebelumnya.
- Tidak ada pemanggilan database di widget, dan skema/fitur offline tidak
  disentuh.

Pemisahan fungsi domain sudah dibuat saat implementasi Praktikum 2 agar
verifikasi search bisa dilakukan melalui unit test. Pada Praktikum 3, hasil
tersebut ditinjau kembali terhadap batas layer dan challenge refactor; tidak
ditambahkan abstraksi/notifier baru karena query adalah state input sementara
UI dan logika filter sudah terisolasi serta dapat diuji.

### Verifikasi akhir Praktikum 3

| Pemeriksaan                           | Hasil                                                                                                                                      |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `flutter analyze`                     | Lulus, tidak ada issue.                                                                                                                    |
| `dart format --set-exit-if-changed .` | Tidak selesai karena path generated yang hilang di `build/`. Pemeriksaan format terfokus pada file Dart yang diubah lulus tanpa perubahan. |
| `flutter test`                        | Lulus, seluruh 9 test berhasil.                                                                                                            |
| Menjalankan aplikasi / uji manual     | Tidak dilakukan sesuai permintaan; yang dijalankan hanya analyze, pemeriksaan format, dan test akhir.                                      |

### Keputusan refactor

| Temuan/saran                                                          | Keputusan  | Alasan teknis                                                                                                           |
| --------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------------------------------- |
| Pencocokan langsung case-sensitive dapat melewatkan hasil             | Diperbaiki | Test merah membuktikan bug; normalisasi lowercase menghasilkan dua hasil sesuai ekspektasi.                             |
| Pindahkan aturan filter ke fungsi domain yang murni                   | Terima     | Unit test tidak perlu widget atau database, dan import layer tetap bersih.                                              |
| Pindahkan query sementara ke penyimpanan atau buat abstraksi tambahan | Tolak      | Query bukan data persisten dan filter telah terisolasi; abstraksi ekstra tidak memberi manfaat untuk lingkup fitur ini. |

## AI Challenge - review kode search

### Prompt review

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### Output review AI

Tidak ditemukan blocker. Tiga temuan/saran:

1. **Saran (sedang) - cakupan widget test kurang.** Test widget yang ada hanya
   memastikan empty state saat query tidak cocok. Belum ada test yang
   membuktikan hasil cocok benar-benar tampil pada UI atau tombol clear
   mengembalikan seluruh catatan. Jika filter unit lulus tetapi wiring UI salah,
   test lama tidak akan menangkapnya.
2. **Saran (rendah) - biaya filter per input.** Setiap perubahan query
   memeriksa semua judul dan memanggil `toLowerCase`; untuk koleksi sangat besar
   hal ini berpotensi menambah kerja di UI. Pertimbangkan mengukur performa
   sebelum memindahkan query ke storage.
3. **Saran (rendah) - state query lokal halaman.** `_searchQuery` berada di
   state `NotesPage`, sehingga tidak dibagikan atau dipertahankan saat halaman
   dibuat ulang. Gunakan Riverpod jika kelak query perlu dipakai lintas halaman
   atau dipulihkan.

### Verifikasi temuan dan perbaikan

Temuan 1 dikonfirmasi dengan memeriksa `test/notes_search_test.dart`: test
widget sebelum perubahan hanya menguji hasil tidak cocok. Unit test filter
memang sudah menguji hasil cocok, tetapi tidak membuktikan bahwa input,
filtering, dan rendering widget terhubung benar.

Perbaikan: menambah widget test
`pencarian cocok dan tombol clear memulihkan daftar`. Test memakai repository
palsu, mencari `week 9`, memeriksa hanya `Week 9` terlihat, lalu menekan tombol
clear dan memeriksa `Week 9` serta `Week 6` keduanya kembali. Ini menutup gap
yang ditemukan tanpa menyentuh database atau menjalankan aplikasi.

### Tabel usulan-vs-keputusan per file

| File                           | Usulan review                                                                           | Keputusan                                  | Alasan / bukti                                                                                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------- | ------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/domain/filter_notes.dart` | Jaga filter sebagai aturan domain terpisah dan pertimbangkan optimasi untuk list besar. | Terima pemisahan; tolak optimasi sekarang. | Fungsi murni mudah diuji dan bebas import UI/storage. Belum ada profil atau ukuran data yang membuktikan perlu optimasi.                                 |
| `lib/pages/notes_page.dart`    | Pindahkan query ke Riverpod bila state perlu dibagikan antarhalaman.                    | Tolak untuk kebutuhan sekarang.            | Query hanya input sementara di satu halaman; widget mengelola input/rendering dan memanggil fungsi domain. Tidak ada kebutuhan persistensi atau sharing. |
| `test/search_filter_test.dart` | Pertahankan test unit untuk hasil cocok, kosong, dan tak cocok.                         | Terima.                                    | Test ini mengisolasi aturan filter dari UI dan repository.                                                                                               |
| `test/notes_search_test.dart`  | Tambahkan test UI untuk hasil cocok dan clear.                                          | Terima + refactor.                         | Kekurangan coverage terbukti; widget test baru menguji hasil pencarian dan pemulihan daftar setelah clear.                                               |
| `README.md`                    | Ringkas hasil AI Challenge dan hasil verifikasi.                                        | Terima + dokumentasikan.                   | README merangkum hasil dan merujuk ke catatan review lengkap ini.                                                                                        |
| `docs/ai-log.md`               | Simpan prompt, output review, bukti, dan keputusan.                                     | Terima + dokumentasikan.                   | Menjadi catatan audit tugas praktikum; tidak mengubah perilaku aplikasi.                                                                                 |

## Refactoring Challenge dan checklist verifikasi

### Refactor

Fungsi search yang semula berpotensi bercampur di widget diisolasi pada
`lib/domain/filter_notes.dart`:

```dart
List<T> filterNotes<T>(
  List<T> notes,
  String query,
  String Function(T) titleOf,
)
```

Fungsi kecil ini memangkas aturan search menjadi unit yang bisa diuji tanpa
widget, Riverpod, atau database. Callback `titleOf` menjaga domain tetap
agnostik terhadap model `Note`. `NotesPage` tetap mengatur input dan tampilan;
fitur tambah, hapus, dan sync tidak ikut dipindahkan karena bukan lingkup
refactor search.

Pemisahan ini memenuhi tujuan mengecilkan hasil AI menjadi fungsi/use case
terfokus. Bukan seluruh `NotesPage` yang harus kurang dari 80 baris: halaman
tersebut memiliki tanggung jawab lain yang sudah berada di luar aturan filter.

### Batas import

- `lib/domain/filter_notes.dart` tidak mengimpor Flutter, Riverpod, Dio,
  SQLite, atau `data/`.
- `lib/pages/notes_page.dart` memanggil fungsi domain untuk filter; akses baca,
  hapus, dan sync tetap melalui provider/repository yang sudah ada.
- `test/search_filter_test.dart` memverifikasi aturan domain tanpa database.
- `test/notes_search_test.dart` memakai fake repository untuk widget test.

### Checklist verifikasi mandiri

- [x] Prompt lima slot dan konteks project tercatat di bagian Praktikum 1.
- [x] Search berada pada fungsi domain murni yang ringkas dan teruji.
- [x] Tidak ada import lintas layer pada fungsi domain.
- [x] `flutter analyze` lulus tanpa issue.
- [x] `flutter test test/search_filter_test.dart`: 3 test lulus.
- [x] `flutter test test/notes_search_test.dart`: 2 widget test lulus.
- [x] `flutter test`: semua 9 test lulus.
- [x] Satu temuan AI terbukti melalui test dan diperbaiki; satu saran ditolak
  dengan alasan teknis pada tabel AI Challenge.
- [x] Mampu menjelaskan aturan filter: trim query; query kosong menghasilkan
  semua catatan; selain itu, judul dan query dibandingkan secara lowercase.
- [x] Screenshot `flutter analyze` dan `flutter test` tersedia di folder
  screenshots dan ditautkan pada README.

### Perintah dan hasil aktual

```powershell
flutter analyze
# No issues found!

flutter test test/search_filter_test.dart
# All tests passed! (3 tests)

flutter test test/notes_search_test.dart
# All tests passed! (2 widget tests)

flutter test
# All tests passed! (9 tests)
```

Pemeriksaan format untuk source dan test fitur juga lulus tanpa perubahan.
Screenshot bukti analyze dan test tersedia di folder `screenshots` dan
ditautkan dari README. Aplikasi tidak dijalankan.
