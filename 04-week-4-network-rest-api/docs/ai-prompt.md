User: di project week4_api, Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:

- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error
  ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
  Jelaskan setiap bagian kode dalam komentar.

GitHub Copilot: Saya akan menelusuri struktur `week4_api`, terutama `main.dart`, `pubspec.yaml`, dan pola test yang sudah ada. Hipotesis awal saya: perubahan paling kecil adalah menambah model, repository/provider, dependency Dio dan Riverpod, lalu test terisolasi untuk parsing JSON; validasi termurahnya adalah menjalankan test Flutter yang menyentuh `fromJson`.

Dependency yang diminta ternyata sudah tersedia di `pubspec.yaml`, dan aplikasi sudah memakai `ProviderScope`. Saya akan cek pola halaman/data serta test bawaan agar penempatan repository/provider mengikuti struktur lokal, lalu langsung menambahkan slice kode dan test parsing null/missing field.

Kode lokal sudah memiliki pola yang tepat: `Dio` provider terpusat, repository post, dan `AsyncNotifier` dengan `AsyncError`. Saya akan meniru pola itu untuk comments, tetapi memperketat pemetaan status 404/500 dan timeout 10 detik di repository, serta membuat provider dapat menerima `postId` melalui family agar endpoint persis `/comments?postId={id}`.

Hipotesis teruji dari struktur lokal: provider comments sebaiknya memakai `FamilyAsyncNotifier`, karena `postId` adalah input provider, sedangkan repository tetap menerima `Dio`. Edit berikut menambah tiga file terfokus dan satu unit test; setelah itu saya akan menjalankan test unit tersebut terlebih dahulu sebelum mengecek analyzer.

Generating patch (156 lines) in , , ,

Implementasi inti sudah masuk. Sekarang saya menjalankan unit test parsing yang baru dibuat; hasil ini akan langsung membedakan apakah tipe model dan fallback null-safe sudah cocok dengan SDK/Dart yang dipakai proyek sebelum saya menyentuh validasi yang lebih luas.

Running tests...

Test runner terintegrasi dilewati oleh lingkungan, jadi saya lanjutkan dengan perintah Flutter langsung dari folder `week4_api` untuk memperoleh validasi yang sama. Setelah itu saya cek analyzer agar signature Riverpod 3 dan `Dio` tidak menyisakan error tipe.

Ran terminal command: Set-Location "e:\Kuliah\Website\244107020192-mobile-course\04-week-4-network-rest-api\week4_api"; flutter test test/comment_test.dart

Perintah terminal juga dilewati oleh lingkungan, jadi saya tidak akan menganggap test lulus tanpa bukti. Saya tetap melakukan pemeriksaan statis pada file yang disentuh; bila ada error analyzer, saya perbaiki, dan pada penutup saya tandai jelas bahwa runtime test belum dijalankan.

Checked , , , , no problems found

Pemeriksaan statis pada seluruh file baru bersih. Saya melihat satu penyederhanaan lokal sebelum finalisasi: proyek sudah punya `dioProvider` bersama di `data/providers.dart`, sehingga provider comments tidak perlu membuat instance Dio kedua; saya akan pakai dependency yang sudah ada lalu ulangi pemeriksaan statis.

Generating patch (19 lines) in

```

```

Checked , no problems found

Selesai di project `week4_api`.

Perubahan:

- Model null-safe: `comment.dart`
- Repository Dio dengan endpoint `/comments?postId={id}` dan timeout 10 detik: `comment_repository.dart`
- `AsyncNotifierProvider.family` serta pesan error timeout, koneksi, 404, dan 500: `comment_providers.dart`
- Unit test `Comment.fromJson` dengan field hilang: `comment_test.dart`

Pemeriksaan analyzer bersih. Test runtime tidak dijalankan karena tool eksekusi dilewati oleh lingkungan.

Made changes.
