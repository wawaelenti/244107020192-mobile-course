# Campus Notify · Week 12

Buka **Catatan offline** dari beranda, lalu tekan **Tambah catatan**. Judul wajib diisi dan spasi di awal serta akhir judul dibuang sebelum penyimpanan. Isi catatan boleh kosong. Setelah catatan disimpan, pengguna kembali ke daftar dan bisa membuka detailnya.

## Skenario pengujian

| Skenario | Perilaku yang diharapkan | Pengujian |
| --- | --- | --- |
| Daftar awal kosong | Halaman menampilkan pesan “Belum ada catatan.” dan tombol tambah. | Widget |
| Judul kosong atau hanya whitespace | Formulir menampilkan pesan validasi. Operasi penyimpanan tidak dipanggil. | Unit dan widget |
| Judul satu karakter dan isi kosong (kasus tepi) | Judul diterima setelah dirapikan dan isi tersimpan sebagai string kosong. | Unit |
| Judul valid dengan spasi di awal dan akhir | Judul disimpan setelah dirapikan, isi tetap utuh, dan catatan langsung muncul di daftar. | Unit, widget, dan integrasi |
| Repository gagal menyimpan | Pesan kegagalan tampil, masukan tetap ada, dan pengguna bisa mencoba lagi. Daftar tidak bertambah selama penyimpanan gagal. | Unit dan widget |
| Repository gagal membaca | Use case meneruskan kegagalan; UI menampilkan pesan dan tombol Coba Lagi. Setelah repository pulih, tombol tersebut memuat ulang daftar. | Unit dan widget |
| Simpan ditekan berulang saat operasi belum selesai | Hanya satu operasi simpan dipanggil, tombol dan input dinonaktifkan selama menunggu, lalu tepat satu catatan muncul. | Widget |
| Menambahkan catatan saat data JSON sudah ada | Catatan sebelumnya tetap utuh setelah dibaca ulang dan setiap catatan memiliki ID berbeda. | Unit repository JSON |
| Membaca dan menyimpan melalui repository SQLite | Kolom database dipetakan ke entitas, query meminta urutan terbaru, isi kosong tetap valid, dan ID hasil insert dikembalikan. | Unit dengan fake database |
| Query atau insert SQLite gagal | Repository mengembalikan `LocalFailure`, tanpa catatan sukses palsu. | Unit dengan fake database |
| Buat dan buka catatan dari beranda | Navigasi beranda → daftar → formulir → daftar → detail berjalan. Judul dan isi dapat dibaca melalui repository baru, tampil di detail, lalu tombol kembali membuka daftar. | Widget alur aplikasi dan integrasi |

## Susunan test suite

- [Unit test penambahan catatan](test/add_note_test.dart) dan [unit test pembacaan daftar](test/get_notes_test.dart) dikelompokkan berdasarkan use case. Keduanya memakai [fake repository](test/support/fake_note_repository.dart) dengan hasil sukses dan kegagalan yang bisa ditentukan oleh setiap test.
- [Widget test](test/notes_screen_test.dart) membuat fake dan cache baru untuk setiap skenario agar data dan kegagalan tidak terbawa ke test berikutnya.
- [Integration test](integration_test/app_test.dart) memakai widget aplikasi, navigasi, Riverpod, cache, use case, dan repository JSON asli. Sesi login dan media penyimpanan JSON disediakan dari memori agar pengujian tidak bergantung pada jaringan atau data perangkat. Pengujian ini tidak mencakup inisialisasi Firebase, login ke server, atau plugin SQLite perangkat.
- [Widget test alur aplikasi](test/app_flow_test.dart) menjalankan [skenario yang sama](test/support/notes_app_flow.dart) tanpa emulator. Pemeriksaan ini masuk dalam `flutter test`; eksekusinya tidak menggantikan verifikasi integrasi pada perangkat.
- [Unit test repository SQLite](test/note_repository_impl_test.dart) memakai repository produksi dan fake `Database` pada batas plugin. Test memeriksa nilai kolom, ID, serta kegagalan query/insert, tanpa membuka database perangkat.

## Menjalankan pemeriksaan

Jalankan dari folder ini. Unit test, widget test, dan alur aplikasi dapat diperiksa tanpa emulator:

```powershell
flutter pub get
flutter test
flutter test --coverage
flutter analyze
```

Untuk menjalankan alur aplikasi saja tanpa emulator:

```powershell
flutter test test/app_flow_test.dart
```

Untuk verifikasi integrasi pada perangkat, sambungkan HP Android dan gunakan ID dari `flutter devices`. Tidak perlu menyalakan emulator:

```powershell
flutter devices
flutter test integration_test/app_test.dart -d <device_id>
```

Jika sebuah test gagal, baca nama test dan kondisi yang gagal di keluarannya. Jalankan kembali test terkait secara terpisah, lalu jalankan suite lengkap dengan urutan acak untuk memeriksa ketergantungan pada urutan atau data bersama:

```powershell
flutter test --test-randomize-ordering-seed=20261126
```

Setiap pengujian fitur catatan memakai repository, cache, dan data memori baru. Suite catatan tidak mengakses jaringan. Test autentikasi bawaan memakai server loopback lokal dengan port dinamis, sedangkan test AI memakai HTTP mock sehingga keduanya tidak memerlukan internet.

## Cakupan pengujian dan tinjauan perilaku

Jalankan dari folder `campus_notify`:

```powershell
flutter test --coverage
```

Laporan unit dan widget tersimpan di `coverage/lcov.info`. Folder `coverage` merupakan keluaran lokal yang diabaikan Git; ringkasan hasil dan peninjauannya dicatat di README ini. Integration test perangkat tidak masuk ke laporan tersebut. Untuk membaca rincian per file di PowerShell:

```powershell
Select-String -Path coverage/lcov.info -Pattern '^SF:|^LF:|^LH:'
```

`SF` adalah file sumber, `LF` jumlah baris yang diukur, dan `LH` jumlah baris yang dijalankan. Persentase dihitung dari `LH / LF × 100`. Angka ini menggambarkan cakupan baris pada file yang tercatat di LCOV, bukan cakupan seluruh cabang, seluruh kode aplikasi, atau seluruh perilaku.

Tinjauan awal menghasilkan tiga tambahan yang memeriksa hasil nyata:

- Repository SQLite tercatat 0/14 baris. Test baru memeriksa pemetaan kolom, ID hasil insert, isi kosong, dan penanganan error. Fake memverifikasi kontrak repository dengan database; mesin SQLite asli tetap perlu diverifikasi pada perangkat.
- Repository JSON tercatat 27/35 baris. Jalur saat sudah ada catatan belum diperiksa. Test baru menyimpan dua catatan, membaca melalui instance baru, lalu memeriksa kedua isi dan ID yang berbeda agar penambahan tidak menghilangkan data sebelumnya.
- Halaman tambah sudah tercatat 45/45 baris, tetapi itu belum membuktikan keamanan ketukan berulang. Widget test baru menahan penyimpanan dengan `Completer`, menekan Simpan dua kali sebelum frame berikutnya, dan memeriksa satu pemanggilan repository serta tepat satu catatan tersimpan.

Cabang penting lain sudah diperiksa: validasi sebelum akses repository, kegagalan simpan yang mempertahankan input, coba lagi setelah kegagalan baca, cache kedaluwarsa, kegagalan yang tidak disimpan dalam cache, dan hasil baca lama yang tidak boleh menimpa hasil refresh. Tidak ada test yang ditambahkan hanya untuk menjalankan baris tanpa memeriksa hasil.

Ringkasan laporan akhir setelah penambahan enam test:

| Ruang lingkup dalam LCOV | Baris dijalankan / diukur | Cakupan baris |
| --- | --- | --- |
| Seluruh file `lib` yang tercatat | 410 / 1.056 | 38,83% |
| Fitur catatan (`lib/features/notes`) | 204 / 222 | 91,89% |
| Use case `AddNote` dan `GetNotes` | 10 / 10 | 100% |
| Repository cache | 21 / 21 | 100% |
| Repository JSON | 35 / 35 | 100% |
| Repository SQLite dengan fake database | 14 / 14 | 100% |
| Halaman tambah catatan | 45 / 45 | 100% |
| Halaman daftar catatan | 20 / 24 | 83,33% |
| Widget daftar dan detail | 23 / 27 | 85,19% |
| Pembukaan database dan factory platform native | 0 / 8 | 0% |

Cakupan keseluruhan lebih rendah karena LCOV juga mencatat fitur lain, seperti chat AI, login, dan push notification, sedangkan tugas ini berfokus pada catatan. File yang tidak tercatat di LCOV tidak masuk penyebut. Nilai 100% pada repository atau halaman tambah tidak berarti seluruh cabang dan kondisi waktu sudah diperiksa; contoh ketukan Simpan berulang di atas menunjukkan alasan tinjauan perilaku tetap dibutuhkan.

## Hasil pemeriksaan

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter test --reporter expanded` sebelum pelengkapan | 27 test lulus. |
| `flutter test --reporter expanded --test-randomize-ordering-seed=20261126` pada praktikum awal | 32 test lulus, termasuk alur aplikasi tanpa emulator. |
| `flutter test --coverage --reporter expanded` sebelum lanjutan tugas | 32 test lulus; laporan awal berhasil dibuat. |
| `flutter test --coverage --reporter expanded --test-randomize-ordering-seed=20261126` setelah lanjutan tugas | 38 test lulus; laporan akhir `coverage/lcov.info` berhasil dibuat. |
| `flutter analyze` | Lulus: `No issues found!`. |
| `flutter test integration_test/app_test.dart -d android` | Exit code `1` Skenario yang sama lulus melalui `test/app_flow_test.dart`. |

## Refleksi

### Bug apa yang paling mungkin terlewat tanpa pengujian yang ditulis?

Bug yang paling mungkin terlewat adalah catatan tersimpan dua kali ketika pengguna menekan Simpan berulang saat penyimpanan lambat. Pada percobaan manual dengan data memori, penyimpanan terlalu cepat sehingga masalah ini sulit terlihat. Test memakai `Completer` untuk menahan operasi dan memeriksa hanya satu pemanggilan repository serta satu catatan yang muncul setelah operasi selesai.

Risiko lain adalah input hilang setelah penyimpanan gagal, daftar tetap kosong karena cache tidak diperbarui, atau catatan lama tertimpa saat menambah catatan JSON. Test memeriksa input tetap ada, keberhasilan mencoba ulang, kemunculan data di daftar, dan isi dua catatan setelah dibaca melalui repository baru. Cakupan baris tinggi sendiri tidak menjamin perilaku tersebut benar.

### Bagian mana yang perlu fake, dan bagaimana fake membuat pengujian lebih konsisten?

Batas akses data perlu fake. `FakeNoteRepository` menyediakan daftar di memori, kegagalan baca/simpan yang bisa ditentukan, penghitung operasi simpan, serta `beforeSave` yang dapat ditahan dengan `Completer`. Setiap test membuat instance baru sehingga data, error, dan cache tidak terbawa ke test lain. Waktu penyelesaian operasi ditentukan oleh test tanpa menunggu timer atau jaringan.

Pada unit test repository produksi, fake `Database` mengembalikan baris dan ID yang diketahui atau melempar error query/insert. Dengan begitu, pemetaan data dan penanganan kegagalan bisa diuji tanpa plugin SQLite. Pada alur aplikasi, `TokenStore` menyediakan sesi login uji dan callback penyimpanan JSON memakai memori; navigasi tidak bergantung pada login server atau isi penyimpanan perangkat. Sebagai konsekuensinya, perilaku plugin asli tetap membutuhkan pengujian perangkat.

### Apa perbedaan nilai pengujian widget dan integrasi pada fitur ini?

Widget test memeriksa tampilan dan respons interaksi secara cepat dan terkontrol: keadaan kosong, pesan validasi, input tetap ada saat gagal, tombol Coba Lagi, dan tombol Simpan yang terkunci selama menunggu. Fake memudahkan reproduksi kegagalan dan kondisi waktu yang sulit dibuat secara manual.

Integration test menjalankan alur beberapa bagian aplikasi pada perangkat melalui beranda, formulir, use case, cache, repository JSON, daftar, dan detail. Nilainya adalah memeriksa kerja sama bagian-bagian tersebut dengan binding integrasi dan runtime perangkat. Skenario yang sama juga dijalankan sebagai widget test tanpa emulator untuk memberi umpan balik cepat, tetapi itu belum membuktikan eksekusi integrasi pada perangkat. Dalam tugas ini, integration test Android belum dapat berjalan karena perangkat tidak tersedia; Firebase dan SQLite asli juga belum dicakup oleh skenario integrasi tersebut.
