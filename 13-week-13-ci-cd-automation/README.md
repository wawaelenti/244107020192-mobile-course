# Week 13 · CI/CD Automation

Praktikum ini melanjutkan [Campus Notify dari Week 12](../12-week-12-testing-quality-assurance/README.md). Source aplikasi dan test disalin ke [campus_notify](campus_notify), tanpa cache, dependency hasil unduhan, atau keluaran build. Fitur yang diuji tetap **Catatan offline**.

## Workflow Flutter CI

Konfigurasi workflow berada di [`.github/workflows/flutter-ci.yml`](../.github/workflows/flutter-ci.yml) pada root repository. GitHub Actions membaca workflow dari folder tersebut; menaruhnya hanya di dalam folder Week 13 tidak akan mengaktifkannya.

Repository ini memakai `main` sebagai default branch dan `develop` untuk pengerjaan. Workflow berjalan ketika ada push ke salah satu branch tersebut, pull request dengan tujuan salah satu branch tersebut, atau pemicu manual `workflow_dispatch`.

Push tag yang cocok dengan `v*` juga memicu workflow. Langkah validasi menolak tag yang berbeda dari versi aplikasi di `pubspec.yaml` sebelum pemeriksaan dan build dilanjutkan.

Pemicu manual baru tersedia setelah file workflow ada di default branch `main`, sesuai aturan GitHub Actions. Push ke `develop` dapat memicu CI tanpa menunggu penggabungan ke `main`.

Job `test-and-build` mengikuti nama pada contoh praktikum dan berjalan di `ubuntu-latest`. Semua langkah `run` memakai direktori `13-week-13-ci-cd-automation/campus_notify`, tempat `pubspec.yaml` berada. Urutannya:

1. Checkout repository melalui `actions/checkout@v4`.
2. Siapkan Java 17 Temurin melalui `actions/setup-java@v4` untuk toolchain Android.
3. Siapkan Flutter channel `stable` melalui `subosito/flutter-action@v2`.
4. Jalankan `flutter pub get`.
5. Validasi versi dan tag: `dart run tool/check_version.dart`.
6. Periksa format: `dart format --output=none --set-exit-if-changed .`.
7. Analisis statis: `flutter analyze --fatal-infos`.
8. Unit dan widget test serta laporan cakupan: `flutter test --coverage`.
9. Build APK release: `flutter build apk --release`, dengan konfigurasi publik dari GitHub Variables.
10. Build AAB release: `flutter build appbundle --release`, dengan konfigurasi publik yang sama.
11. Simpan kedua hasil build sebagai artefak `android-builds-<versi>-<build>` melalui `actions/upload-artifact@v4`, dengan retensi tujuh hari dan `if-no-files-found: error`.

Izin workflow dibatasi ke `contents: read`. Pengaturan concurrency membatalkan run sebelumnya ketika run baru untuk workflow dan ref yang sama dimulai. Pemeriksaan berjalan berurutan dan kegagalan menghentikan job; tidak ada `continue-on-error` atau langkah yang menutupi exit code.

Job menjalankan build setelah format, analisis, dan test berhasil. Unit dan widget test berjalan tanpa emulator; cakupan ditulis ke `campus_notify/coverage/lcov.info` dalam direktori Week 13.

## Build dan penyimpanan APK/AAB

Perintah lokal, dijalankan dari folder `13-week-13-ci-cd-automation/campus_notify`:

```powershell
flutter build apk --release
flutter build appbundle --release
```

| Hasil | Lokasi relatif terhadap project Flutter | Kegunaan |
| --- | --- | --- |
| APK | `build/app/outputs/flutter-apk/app-release.apk` | Instalasi langsung dan uji internal. |
| AAB | `build/app/outputs/bundle/release/app-release.aab` | Format distribusi untuk alur Google Play. |

`defaults.run.working-directory` hanya berlaku pada langkah `run`, sehingga langkah `uses: actions/upload-artifact@v4` memakai path dari root repository. Kedua path upload diawali `13-week-13-ci-cd-automation/campus_notify/`, bukan hanya `build/`. Upload berjalan setelah kedua build berhasil. Jika tidak ada file yang ditemukan, langkah upload gagal sesuai `if-no-files-found: error`.

Setelah run berhasil di GitHub, buka **Actions → Flutter CI → pilih run → Artifacts → android-builds-1.0.0-2** untuk mengunduh arsip build versi saat ini. Nama artefak mengikuti versi dan build number di `pubspec.yaml`; untuk versi berikutnya namanya ikut berubah. Retensi artefak ditetapkan selama tujuh hari. APK/AAB lokal berada di folder `build` yang diabaikan Git; binary tidak dimasukkan ke source repository.

Build release saat ini memakai debug signing sesuai `android/app/build.gradle.kts`, dan application ID masih `com.example.campus_notify`. Sebelum distribusi produksi, signing release, identitas dan konfigurasi aplikasi/Firebase, izin aplikasi, serta pengujian perangkat perlu ditinjau. Build sukses belum membuktikan kesiapan publikasi. Workflow ini tidak menjalankan integration test perangkat dan tidak mengunggah aplikasi ke Play Store.

## Versioning dan tag rilis

Versi aktif di `campus_notify/pubspec.yaml` adalah **`1.0.0+2`**. Versi aplikasi tetap `1.0.0` karena perilaku fitur belum berubah; build number dinaikkan dari `1` menjadi `2` untuk paket berikutnya. APK/AAB lokal yang berhasil dibuat pada tahap sebelumnya masih merupakan **`1.0.0+1`**, bukan build `2`. CI berikutnya akan membangun ulang dari versi aktif.

Format `1.2.0+15` berarti versi aplikasi `1.2.0` dan build number `15`. Pada Android, konfigurasi Gradle mengambilnya melalui `flutter.versionName` dan `flutter.versionCode`.

| Perubahan | Aturan | Contoh versi |
| --- | --- | --- |
| Perubahan tidak kompatibel | Naikkan major. | `1.2.0+15` → `2.0.0+16` |
| Fitur baru yang kompatibel | Naikkan minor. | `1.2.0+15` → `1.3.0+16` |
| Perbaikan yang kompatibel | Naikkan patch. | `1.2.0+15` → `1.2.1+16` |
| Paket baru dengan versi aplikasi sama | Naikkan build number sebelum unggahan baru. | `1.2.0+15` → `1.2.0+16` |

Ikuti [Semantic Versioning](https://semver.org/) untuk versi aplikasi. Build number merupakan penghitung distribusi yang dinaikkan untuk setiap unggahan paket baru. Tool CI memvalidasi format dan kecocokan tag, tetapi tidak membaca riwayat unggahan Google Play; kenaikan penghitung tetap dicatat di `pubspec.yaml` sebelum commit.

[Tool pemeriksaan versi](campus_notify/tool/check_version.dart) memakai field `version` dari YAML sebagai sumber tunggal. Tool menolak versi tidak valid, build number hilang/nonpositif, serta tag yang tidak cocok. Tag memakai versi aplikasi tanpa suffix build: `1.2.0+15` memakai tag **`v1.2.0`**, bukan `v1.2.0+15`. Versi prerelease seperti `1.2.0-rc.1+15` juga didukung.

Untuk memeriksa kandidat tag saat ini tanpa membuat tag Git, jalankan dari folder project:

```powershell
dart run tool/check_version.dart
dart run tool/check_version.dart --ref=refs/tags/v1.0.0
```

Skenario format dan kecocokan tag diperiksa oleh [unit test versioning](campus_notify/test/version_test.dart). Pada CI, versi/build ditulis ke log dan output langkah, SHA sumber dicatat melalui `GITHUB_SHA`, lalu nama artefak dibentuk dari hasil validasi. Dengan demikian, tag, commit pada halaman run, log versi, dan artefak `android-builds-1.0.0-2` dapat dicocokkan.

### Membuat tag setelah pemeriksaan lulus

1. Ubah versi/build number sesuai perubahan, jalankan pemeriksaan lokal, lalu commit dan push source ke branch pengerjaan.
2. Tunggu **Flutter CI** pada commit tersebut lulus seluruh langkah, termasuk build dan upload artefak. Periksa SHA commit pada halaman run, bukan hanya status hijau dari commit sebelumnya.
3. Buat annotated tag pada SHA yang telah diverifikasi, lalu push tag. Contoh untuk versi aktif, dijalankan dari root repository setelah mengganti nilai SHA:

```powershell
$verifiedCommit = 'GANTI_DENGAN_SHA_COMMIT_YANG_CI_NYA_LULUS'
git show --no-patch --oneline $verifiedCommit
git tag -a v1.0.0 $verifiedCommit -m "Campus Notify 1.0.0"
git push origin v1.0.0
```

4. Push tag memicu pemeriksaan dan build kembali. Jika tag tidak cocok dengan versi di commit tersebut, job berhenti pada langkah **Check version and tag**.

Tag rilis yang sudah dipublikasikan tidak dipindahkan ke commit lain. Untuk rilis baru, naikkan versi/build number lalu buat tag baru sesuai versi aplikasinya. Pemeriksaan kecocokan tag tidak membuktikan bahwa commit pernah lolos CI; langkah verifikasi SHA sebelum membuat tag tetap wajib.

Belum ada tag rilis yang dibuat pada tahap ini: perubahan Week 13 masih lokal dan belum memiliki run CI GitHub yang dapat dijadikan bukti kelulusan. Build serta validasi lokal tidak dicatat sebagai pengganti kelulusan pipeline pada commit yang akan ditag.

## Rahasia dan konfigurasi

### Konfigurasi publik

URL API dan nama environment biasanya merupakan konfigurasi publik. URL yang memuat password atau query token tetap mengandung rahasia dan tidak boleh dijadikan konfigurasi publik. [AppConfig](campus_notify/lib/config/app_config.dart) membaca `API_BASE_URL` dan `APP_ENV` dari deklarasi environment Dart. Provider API menggunakan `AppConfig.apiBaseUrl`; nama environment tersedia sebagai konstanta konfigurasi dan tidak mengubah tampilan aplikasi.

| Nama | Default | Pengaturan CI |
| --- | --- | --- |
| `API_BASE_URL` | `https://example-campus-api.test` | GitHub Actions Variable `API_BASE_URL` |
| `APP_ENV` | `development` | GitHub Actions Variable `APP_ENV` |

Atur nilai publik melalui **Settings → Secrets and variables → Actions → Variables**. Workflow memasukkannya ke environment proses sebagai `PUBLIC_API_BASE_URL` dan `PUBLIC_APP_ENV`, lalu meneruskannya melalui `--dart-define` pada kedua build. Nilai default dipakai jika variable belum disetel. Nilai dikutip melalui environment shell, bukan disisipkan langsung sebagai kode shell.

Untuk build lokal dari folder project, gunakan [contoh JSON berisi konfigurasi publik](campus_notify/config/public.example.json):

```powershell
flutter build apk --release --dart-define-from-file=config/public.example.json
flutter build appbundle --release --dart-define-from-file=config/public.example.json
```

JSON tersebut boleh disimpan di repository karena hanya berisi URL contoh dan nama environment. Aplikasi tidak otomatis membaca file `.env`; konfigurasi contoh di atas diteruskan oleh perintah build.

Nilai `--dart-define`, termasuk yang berasal dari file JSON, dapat diekstrak dari aplikasi klien. Jangan memasukkan token privat, password, kunci layanan AI milik server, atau material signing ke dalamnya. Obfuscation juga bukan enkripsi atau tempat menyimpan rahasia, sesuai [batasan resmi Flutter](https://docs.flutter.dev/deployment/obfuscate#limitations-and-warnings).

### Penyimpanan secrets dan log

Token privat, password, dan material signing disimpan melalui [GitHub Actions Secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets). Untuk signing produksi, gunakan **environment secrets** pada environment rilis terproteksi, bukan variable publik atau file di repository. Nilai secret tidak diperlukan untuk unit/widget test project ini.

| Data | Tempat yang sesuai |
| --- | --- |
| URL API dan label environment | GitHub Variables atau konfigurasi publik dalam source. |
| Token layanan privat/password untuk otomasi tepercaya | GitHub Actions Secrets dengan cakupan seperlunya. |
| Keystore upload, password keystore, password key, alias signing produksi | Environment Secrets khusus rilis produksi. |
| Token sesi pengguna di perangkat | Penyimpanan runtime `TokenStore`, bukan build define atau konfigurasi CI. |

Workflow `Flutter CI` saat ini tidak mereferensikan `secrets.*`, tidak memakai `pull_request_target`, dan tidak menerima keystore produksi. Job hanya memiliki izin `contents: read`; checkout memakai `persist-credentials: false` sehingga credential Git tidak dipertahankan untuk langkah build. Artefak hanya mengambil dua path APK/AAB, bukan seluruh workspace atau direktori signing.

Jangan mencetak nilai secret melalui `echo`, `print`, `set -x`, dump environment, header Authorization, atau isi `key.properties`. Jangan meneruskannya ke build/test dari pull request, action pihak ketiga yang belum ditinjau, atau proses lain yang tidak dipercaya. Secret diberikan melalui environment hanya pada langkah tepercaya yang memerlukannya. Fitur masking GitHub membantu log, tetapi tidak menggantikan aturan ini; nilai yang diubah atau di-encode tetap dapat bocor.

`.gitignore` project mencakup `.env`, variasi `.env.*`, folder `secrets`, `key.properties`, keystore/JKS, material PEM/P12/PFX, dan nama file service account yang umum. File contoh `.env.example` dapat dilacak jika hanya berisi placeholder. Aturan ignore tidak menghapus file yang sudah dilacak atau membersihkan riwayat Git. Jika secret pernah tercommit, cabut/rotasi credential tersebut; mengabaikan filenya saja tidak cukup.

### Rilis bertanda tangan yang dibatasi

Ikuti [panduan signing Android resmi Flutter](https://docs.flutter.dev/deployment/android#sign-the-app). Alur berikut merupakan rancangan rilis terpisah; workflow produksi dan environment secrets belum dibuat atau diaktifkan pada repository GitHub.

1. Siapkan environment GitHub `android-production` melalui **Settings → Environments**. Batasi tag deployment yang diizinkan dan gunakan required reviewers/proteksi yang tersedia. Menuliskan nama `environment` di YAML saja tidak memasang proteksi; pengaturan GitHub harus disiapkan lebih dahulu. Lihat [dokumentasi environment GitHub](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).
2. Simpan material upload signing pada environment tersebut dengan nama `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, dan `ANDROID_KEY_ALIAS`. Base64 hanya pengodean file, bukan enkripsi; hasilnya tetap diperlakukan sebagai secret. Jangan mengirim nilai-nilai ini ke percakapan atau menaruhnya pada source.
3. Workflow rilis terpisah menggunakan pemicu manual `workflow_dispatch`, hanya menerima ref tag versi yang sesuai, dan memverifikasi bahwa commit tag berasal dari source tepercaya serta telah lulus CI. Workflow tersebut tidak memiliki pemicu pull request dan tidak melakukan checkout kode PR pada job yang mengakses secrets.
4. Pisahkan job verifikasi tanpa secrets dari job signing. Job signing bergantung pada verifikasi yang lulus dan menggunakan environment `android-production`. Tinjau action/dependency yang dijalankan; berikan secrets hanya ke langkah signing/build yang memerlukannya.
5. Decode keystore ke `$RUNNER_TEMP`, lalu buat `android/key.properties` sementara tanpa menampilkan isinya. Konfigurasi signing Gradle harus mengikuti panduan Flutter, membaca properti sementara tersebut, dan gagal jika material rilis tidak lengkap. Jangan memakai fallback debug signing untuk job yang dilabeli produksi.
6. Unggah hanya APK/AAB hasilnya. Hapus file keystore/properti sementara melalui langkah cleanup `if: always()` setelah job, dan jangan memasukkannya ke artefak atau cache.

CI praktikum tetap menghasilkan build internal dengan debug signing. Signing produksi belum dijalankan, belum ada nilai secret yang diisikan ke GitHub melalui pekerjaan ini, dan belum ada aplikasi yang dikirim ke Play Store.

## Pemeriksaan lokal

Jalankan dari root repository:

```powershell
cd 13-week-13-ci-cd-automation/campus_notify
flutter pub get
dart run tool/check_version.dart
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
```

Jika format gagal, perbaiki format lalu jalankan kembali pemeriksaan:

```powershell
dart format .
dart format --output=none --set-exit-if-changed .
```

Tinjau perubahan format dengan `git diff` sebelum commit. Pemeriksaan format, analisis, dan test tetap dipertahankan dalam workflow.

## Hasil pemeriksaan lokal

Pemeriksaan dijalankan di folder project Week 13 menggunakan Flutter `3.47.5` dan Dart `3.13.4` pada Windows:

| Pemeriksaan | Hasil |
| --- | --- |
| `flutter pub get` | Lulus, dependency berhasil disiapkan. |
| `dart run tool/check_version.dart` | Exit code `0`: versi aktif `1.0.0+2`, kandidat tag `v1.0.0`. |
| `dart run tool/check_version.dart --ref=refs/tags/v1.0.0` | Exit code `0`: kandidat tag sesuai versi aplikasi. Tidak membuat tag Git. |
| `dart run tool/check_version.dart --ref=refs/tags/v1.0.1` | Exit code `1` sesuai skenario negatif: tag berbeda berhasil ditolak. |
| `dart format --output=none --set-exit-if-changed .` | Exit code `0`: 51 file diperiksa, 0 berubah. |
| `flutter analyze --fatal-infos` | Exit code `0`: `No issues found!`. |
| `flutter test --coverage` | Exit code `0`: 45 test lulus, termasuk tujuh test versioning; laporan `campus_notify/coverage/lcov.info` terbentuk. |
| `flutter build apk --release` pada tahap build sebelumnya | Exit code `0`: APK `1.0.0+1` terbentuk di path yang dikonfigurasi, ukuran sekitar 39,7 MB. |
| `flutter build appbundle --release` pada tahap build sebelumnya | Exit code `0`: AAB `1.0.0+1` terbentuk di path yang dikonfigurasi, ukuran sekitar 40,8 MB. |
| Validasi YAML workflow | Trigger branch/tag, izin, direktori project, urutan pemeriksaan/build, serta nama artefak dari output validasi versi berhasil diperiksa. |
| Pemeriksaan batas secrets CI | Job hanya memakai Variables publik, tidak mereferensikan `secrets.*`, checkout tidak menyimpan credential, dan artefak hanya mengambil APK/AAB. |
| Pemeriksaan ignore | Sepuluh contoh path file sensitif diabaikan Git; `config/public.example.json` tetap dapat dilacak. Tidak membuat credential sungguhan. |
| Pemeriksaan konfigurasi kompilasi | Probe Dart sementara berhasil memeriksa default dan override `API_BASE_URL`/`APP_ENV` dengan URL contoh; probe telah dihapus. |
| Pemindaian pola credential privat | 79 file source kandidat diperiksa untuk pola private key, token GitHub, dan field private key service account; tidak ditemukan kecocokan. Pemeriksaan ini terbatas, bukan audit seluruh riwayat Git atau semua jenis credential. |

Fitur aplikasi tetap mengikuti Week 12, dengan URL API yang kini membaca konfigurasi build publik. Week 13 menambahkan `AppConfig`, contoh konfigurasi JSON publik, tool/test versioning, dependency development `yaml`, dokumentasi CI, serta aturan ignore sesi compiler dan material rahasia. Direktori `.dart_tool`, `.gradle`, `.kotlin`, `build`, dan `coverage` diabaikan Git.

Hasil di atas berasal dari pemeriksaan lokal, bukan hasil run GitHub Actions. Setelah workflow dikirim ke GitHub, periksa tab **Actions → Flutter CI** untuk memastikan runner Ubuntu dengan Flutter stable juga menyelesaikan seluruh langkah. Emulator tidak digunakan.

Kedua file hasil build lokal ditemukan pada path upload yang dikonfigurasi. Struktur arsip APK/AAB diperiksa untuk memastikan manifest, DEX, dan kode Flutter hasil kompilasi tersedia; pemeriksaan ini tidak menggantikan instalasi serta pengujian di perangkat. Build lokal memakai Java 25 bawaan Android Studio, sedangkan CI menyiapkan Java 17 sesuai [kebutuhan minimum AGP 9.1](https://developer.android.com/build/releases/agp-9-1-0-release-notes). Build lokal berhasil dengan warning kompatibilitas KGP dari `firebase_core`; kompatibilitas dependency perlu ditinjau saat memperbarui Flutter.

## Referensi

- [Sintaks workflow dan working directory GitHub Actions](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax).
- [Konfigurasi Flutter stable melalui flutter-action](https://github.com/subosito/flutter-action).
- [Setup Java untuk GitHub Actions](https://github.com/actions/setup-java).
- [Upload artefak dan masa retensi](https://github.com/actions/upload-artifact/tree/v4).
- [Build dan release Android dengan Flutter](https://docs.flutter.dev/deployment/android).
- [Semantic Versioning](https://semver.org/).
- [GitHub Actions Secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets).
- [Proteksi environment GitHub](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).
- [Deklarasi environment saat kompilasi Dart](https://dart.dev/libraries/core/environment-declarations).
