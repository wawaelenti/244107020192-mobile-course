### NAMA : Wawa Elent Irawanti

### NIM : 244107020192

### KELAS : TI-3H

## Praktikum 2: Provider dan error handling

## Uji tiga skenario error

1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.

|                   Tampilan Loading                    |                      Tampilan Internet Normal                      |
| :---------------------------------------------------: | :----------------------------------------------------------------: |
| ![tampilan loading](screenshots/tampilan_loading.png) | ![tampilan internet normal](screenshots/hasil_internet_normal.png) |

= Hasil pengamatan: Saat internet normal, aplikasi menampilkan loading terlebih dahulu. Setelah proses selesai, data berhasil diambil dari API dan menampilkan 100 posts.

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.

|                      Tampilan Mode Pesawat                      |                      Tampilan Internet Normal                      |
| :-------------------------------------------------------------: | :----------------------------------------------------------------: |
| ![tampilan mode pesawat](screenshots/tampilan_mode_pesawat.png) | ![tampilan internet normal](screenshots/hasil_internet_normal.png) |

= Hasil pengamatan: Saat internet normal, aplikasi menampilkan loading lalu berhasil menampilkan 100 posts. Saat internet dimatikan, muncul pesan error dan tombol Coba lagi, kemudian data dapat dimuat kembali setelah internet aktif. Saat baseUrl diubah menjadi URL yang salah, aplikasi menampilkan pesan error koneksi.

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.

   Untuk pengujian ubah sementara menjadi URL yang salah seperti code di bawah ini:

   <p align="center"><img src="screenshots/url_salah.png"></p><br>

|                     Tampilan URL Salah                     |                            Tampilan URL Benar                             |
| :--------------------------------------------------------: | :-----------------------------------------------------------------------: |
| ![tampilan loading](screenshots/tampilan_mode_pesawat.png) | ![tampilan dengan internet normal](screenshots/hasil_internet_normal.png) |

= Hasil pengamatan: Saat baseUrl diubah menjadi URL yang salah, aplikasi menampilkan pesan error koneksi karena tidak dapat mengambil data dari API. Setelah baseUrl dikembalikan ke URL yang benar, data dapat dimuat kembali.

## Praktikum 3: Pagination dasar

1. Halaman 1 tampil dulu, awalnya muncul 10 post, jika melakukan scroll ke bawah muncul loading kecil lalu muncul data berikutnya otomatis muncul

<p align="center"><img src="screenshots/halaman1.png" width="280" height="580"></p>
