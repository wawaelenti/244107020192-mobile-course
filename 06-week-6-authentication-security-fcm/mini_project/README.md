# Campus Notify

Aplikasi Flutter mini project week 6 untuk login, menjaga sesi, dan membuka
pengumuman dari push notification Firebase Cloud Messaging (FCM).

## Fitur

- Login demo (default) dan opsi endpoint autentikasi backend.
- Route guard: semua halaman selain `/login` mensyaratkan access token.
- Access/refresh token disimpan dengan `flutter_secure_storage`.
- Dio mengirim `Authorization: Bearer ...`, me-refresh sesi pada respons 401,
  dan mengulang request maksimal satu kali. Refresh yang ditolak (401/403)
  menghapus sesi; gangguan jaringan tidak menghapus token.
- Meminta izin notifikasi, mengirim token FCM awal dan setiap perubahan token
  ke `POST /devices`, serta subscribe `pengumuman-kampus` pada perangkat mobile.
- Payload kombinasi `notification` + `data`; ketukan notifikasi membuka
  `/pengumuman/:id` saat app foreground, background, atau terminated.
- Token yang tampil di halaman utama disamarkan.

## Menjalankan

```sh
cd 06-week-6-authentication-security-fcm/mini_project
flutter pub get
flutter run
```

Mode login demo menerima email apa saja yang mengandung `@` dan kata sandi
minimal 6 karakter. Untuk memakai API:

```sh
flutter run \
  --dart-define=USE_MOCK_AUTH=false \
  --dart-define=API_BASE_URL=https://api.example.ac.id
```

Backend autentikasi mengembalikan objek `accessToken` dan `refreshToken` dari
`POST /auth/login` dan `POST /auth/refresh`. Endpoint pendaftaran perangkat
menerima `POST /devices` dengan body `{"token":"<FCM token>"}` dan header
Bearer access token. Jika `API_BASE_URL` kosong, token ditampilkan secara
terpotong tetapi tidak dikirim.

## Konfigurasi Firebase / FCM

Firebase diinisialisasi menggunakan konfigurasi yang diberikan untuk project
`campus-notify-cc71e` di `lib/firebase_options.dart`. Kartu status setup tidak
ditampilkan di halaman utama; detail error tetap dicatat pada log aplikasi.

1. Untuk Android, pastikan aplikasi Android yang didaftarkan di Firebase cocok
   dengan package `com.example.mini_project`, lalu letakkan `google-services.json`
   dari project yang sama di `android/app/`. Gradle mengaktifkan Google
   Services plugin hanya saat file konfigurasi ada.
2. Untuk iOS, letakkan `GoogleService-Info.plist` di `ios/Runner/`, aktifkan
   Push Notifications dan Background Modes (Remote notifications) di
   capability aplikasi, lalu unggah APNs key/certificate ke Firebase Console.
3. Untuk web, konfigurasi Firebase sudah diambil dari
   `lib/firebase_options.dart`. Ambil **Web Push certificates / VAPID public
   key** dari Firebase Console → Project settings → Cloud Messaging, lalu
   jalankan:

   ```sh
   flutter run -d chrome --dart-define=FCM_VAPID_KEY=<VAPID_PUBLIC_KEY>
   ```

   Service worker FCM berada di `web/firebase-messaging-sw.js`.
4. Kirim FCM data message dengan `notification.title`, `notification.body`,
   dan `data.id` (atau `data.route` bernilai `/pengumuman/<id>`). Token yang
   didapat aplikasi akan subscribe ke topik `pengumuman-kampus` pada Android
   dan iOS. Topic messaging tidak didukung oleh Firebase Messaging Web SDK.
5. Untuk pengujian manual gunakan perangkat fisik/emulator yang terdaftar pada
   Firebase. Aplikasi tetap dapat dipakai untuk menguji login demo dan route
   jika layanan Firebase atau izin notifikasi tidak tersedia; error dicatat di
   log aplikasi dan tidak ditampilkan sebagai kartu pada Home.

## Uji penerimaan notifikasi

| App state | Tindakan | Hasil yang diharapkan | Hasil eksekusi |
|---|---|---|---|
| Foreground | Kirim pesan `notification` + `data.id`; ketuk banner lokal | Banner tampil dan membuka `/pengumuman/<id>` | Belum diuji: perlu Firebase project dan perangkat FCM |
| Background | Pindahkan aplikasi ke background; kirim pesan lalu ketuk notifikasi sistem | Aplikasi aktif dan membuka `/pengumuman/<id>` | Belum diuji: perlu Firebase project dan perangkat FCM |
| Terminated | Force-stop/tutup proses; kirim pesan lalu ketuk notifikasi | Aplikasi mulai dan membuka `/pengumuman/<id>` | Belum diuji: perlu Firebase project dan perangkat FCM |

Deep link akan lebih dulu dialihkan ke `/login` ketika belum ada sesi; setelah
login, pengguna dikembalikan ke halaman pengumuman yang diminta.

## Bukti screenshot

Simpan screenshot asli dari perangkat uji (jangan gunakan token penuh) pada
folder `screenshots/` dengan nama berikut:

- `token-terpotong.png` — Home menampilkan token perangkat yang disamarkan.
- `foreground-banner.png` — banner notifikasi ketika app sedang terbuka.
- `background-banner.png` — notifikasi ketika app di background.
- `terminated-banner.png` — notifikasi ketika app ditutup.
- `deep-link-pengumuman.png` — halaman pengumuman setelah ketukan notifikasi.

Screenshot perlu diambil setelah project Firebase dikonfigurasi dan notifikasi
diuji pada perangkat. Jangan pernah menyimpan atau membagikan token FCM lengkap.

## Test

```sh
flutter test
```

Test mencakup parsing route payload dan keberhasilan/kegagalan refresh sesi.
