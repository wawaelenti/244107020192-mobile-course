# Verifikasi AI: FCM

## Temuan implementasi

- `firebaseMessagingBackgroundHandler` adalah fungsi top-level dengan `@pragma('vm:entry-point')`. Handler hanya menginisialisasi Firebase dan tidak menggunakan `BuildContext`, widget, atau router.
- Token saat ini dan setiap nilai dari `onTokenRefresh` dikirim memakai `POST /devices` dengan body `{"token": "..."}`. Request menggunakan API client yang mengambil access token dari secure storage. Kegagalan jaringan/HTTP dicatat tanpa mencetak token.
- `onMessage` menampilkan notifikasi melalui `flutter_local_notifications`. Presentasi otomatis FCM di iOS dimatikan agar tidak menimbulkan banner ganda.
- Tap FCM background ditangani oleh `onMessageOpenedApp`; tap FCM terminated oleh `getInitialMessage`; foreground menggunakan callback local notification. `getNotificationAppLaunchDetails` juga menangani app launch dari local notification.
- Rute notifikasi divalidasi sebelum diteruskan ke `appRouter.go`. Rute yang diterima hanya `/` dan `/pengumuman/{id}`; URL eksternal dan rute tidak dikenal diabaikan. Callback navigasi tidak membutuhkan `BuildContext`.
- FCM token tidak di-hardcode dan tidak dicetak. VAPID key web dibaca dari `--dart-define=FCM_VAPID_KEY`; VAPID key adalah public key, bukan secret. URL backend dibaca dari `--dart-define=API_BASE_URL`. Backend contoh tetap perlu diganti dengan URL API aktual.

## Matriks pengujian tap notifikasi

Payload uji: `route=/pengumuman/3` dan `id=3`.

| Kondisi aplikasi saat notifikasi diterima | Jalur yang diperiksa | Hasil yang diharapkan | Hasil uji perangkat |
|---|---|---|---|
| Foreground | `onMessage` → local notification → `onDidReceiveNotificationResponse` | Tap membuka `/pengumuman/3` | Belum diuji pada perangkat/emulator |
| Background | `onMessageOpenedApp` | Tap membuka `/pengumuman/3` | Belum diuji pada perangkat/emulator |
| Terminated | `getInitialMessage` (FCM) atau `getNotificationAppLaunchDetails` (local) | Tap membuka `/pengumuman/3` | Belum diuji pada perangkat/emulator |

`campus_notify/test/notification_route_test.dart` memeriksa penerimaan rute aplikasi yang didukung dan penolakan rute eksternal/tidak dikenal. Tes unit ini bukan pengganti uji end-to-end. Banner, izin OS, serta tap untuk setiap lifecycle tetap perlu diverifikasi di perangkat Android/iOS dengan konfigurasi Firebase/APNs yang valid.

## Perbedaan platform dan keputusan final

- **Android 13+**: izin notifikasi diminta saat runtime lewat `FirebaseMessaging.requestPermission()`. Local notification memakai channel Android `pengumuman`. Android versi lama tidak menampilkan dialog izin runtime Android 13.
- **iOS**: izin alert/badge/sound diminta lewat `requestPermission`; capability APNs dan konfigurasi Firebase/APNs harus aktif. Presentasi otomatis saat foreground dimatikan lalu satu local notification ditampilkan manual.
- **Web**: VAPID key diberikan lewat `--dart-define=FCM_VAPID_KEY=...`; subscription topic dari SDK client dilewati di Web.
- Keputusan final adalah menggunakan notifikasi lokal manual untuk foreground agar tampil konsisten dan tidak membuat banner ganda di iOS, serta mengirim token saat awal dan saat refresh agar backend selalu menerima token terbaru. URL API dan VAPID key dipasok saat run, bukan ditanam sebagai token aplikasi.

Jalankan dari folder `campus_notify` dengan konfigurasi lingkungan yang sesuai:

```powershell
flutter run --dart-define=API_BASE_URL=https://api.example.edu --dart-define=FCM_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
flutter test test/notification_route_test.dart
```
