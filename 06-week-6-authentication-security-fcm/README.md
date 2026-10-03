### NAMA : Wawa Elent Irawanti

### NIM : 244107020192

### KELAS : TI-3H

## Praktikum 1: Login + secure storage + token refresh


|                Login Page                 |                Home Page                |
| :---------------------------------------: | :-------------------------------------: |
| ![Login Page](screenshots/login_page.png) | ![Home Page](screenshots/home_page.png) |

<li> Halaman Login digunakan untuk melakukan autentikasi menggunakan email dan password. Setelah berhasil, pengguna akan diarahkan ke halaman utama. Jika login gagal, sistem menampilkan pesan kesalahan dan pengguna tetap berada di halaman login.  </li><br>

<li> Halaman Utama dapat diakses setelah login berhasil. Access token dan refresh token disimpan menggunakan secure storage, serta pengguna dapat melakukan logout untuk menghapus token dan kembali ke halaman login.  </li><br>

## Praktikum 2: FCM, permission, dan token lifecycle

1. Notification Permission

<p align="center"><img src="screenshots/notification_permission.png"></p>

<li> Menampilkan permission notifikasi pada browser dan memastikan permission berhasil diberikan. </li><br>

2. FCM Token

<p align="center"><img src="screenshots/fcm_token.png"></p>

<li> Menampilkan FCM registration token yang berhasil diperoleh dari aplikasi Flutter. </li><br>

3. Firebase Console Test Notification

<p align="center"><img src="screenshots/fcm_console.png"></p>

<li> Menampilkan campaign/test notification yang dibuat melalui Firebase Console. </li><br>

4. Foreground Notification

<p align="center"><img src="screenshots/fcm_foreground.png"></p>

<li> Notifikasi berhasil diterima ketika aplikasi Flutter sedang aktif/terbuka. </li><br>

5. Background Notification

<p align="center"><img src="screenshots/fcm_background.png"></p>

<li> Notifikasi berhasil diterima ketika aplikasi masih berjalan tetapi browser tidak sedang aktif digunakan. </li><br>

6. Terminated Notification

<p align="center"><img src="screenshots/fcm_terminated.png"></p>

<li> Pengujian penerimaan notifikasi ketika halaman aplikasi Flutter sudah ditutup. </li><br>

## Praktikum 3: Payload, tiga app state, klik dan topik

1. Notification dengan Payload Data

<p align="center"><img src="screenshots/custom_data.png"></p>

<li> Notification dikirim melalui Firebase Console dengan tambahan Custom Data berupa route dan id. </li><br>

2. Notification Diterima

<p align="center"><img src="screenshots/prak3_notification.png"></p>

<li> Setelah notification dikirim melalui Firebase Console, notification berhasil diterima pada browser Chrome. </li><br>

3. Navigation ke Halaman Pengumuman

<p align="center"><img src="screenshots/announcement_page.png"></p>

<li> Data route digunakan untuk menentukan halaman tujuan. Pada Flutter Web, route dapat diakses melalui /#/pengumuman/3. Halaman tujuan berhasil menampilkan ID pengumuman berdasarkan data id yang dikirim.</li><br>

