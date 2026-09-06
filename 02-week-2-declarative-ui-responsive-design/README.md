### NAMA : Wawa Elent Irawanti

### NIM : 244107020192

### KELAS : TI-3H

## Praktikum: layout sederhana (warm-up)

![](/02-week-2-declarative-ui-responsive-design/screenshots/WhatsApp%20Image%202026-09-05%20at%2012.27.12.jpeg)

### Eksperimen warm-up

1. Hapus Expanded pada baris nama, lalu amati peringatan overflow atau perilaku layout-nya; kembalikan setelah itu.
   = Jika Expanded dihapus, column tidak lagi dipaksa menggunakan ruang yang tersedia. Jika teks terlalu panjang, teks dapat keluar(overflow) dari batas card karena row harus menyesuaikan seluruh isi child.

2. Ganti mainAxisSize: MainAxisSize.min menjadi nilai default dan amati perubahan tinggi kartu.
   = Column akan berusaha menggunakan seluruh tinggi ruang yang tersedia. Akibatnya, tinggi ProfileCard dapat menjadi lebih besar dan tidak lagi hanya mengikuti tinggi isi kontennya.

3. Tambahkan satu baris data (misal Email) menggunakan pola Row + Expanded yang sama.
   ![](/02-week-2-declarative-ui-responsive-design/screenshots/praktikum-add-email.jpeg)

## Praktikum: dashboard responsif

![](/02-week-2-declarative-ui-responsive-design/screenshots/praktikum-dashboard-responsif.jpeg)

### Eksperimen layout

1. Ubah breakpoint dari 700 menjadi nilai lain dan amati perubahan jumlah kolom.
2. Ubah themeMode menjadi ThemeMode.dark, lalu kembalikan ke ThemeMode.system.
3. Uji aplikasi dengan ukuran layar emulator yang berbeda.
   ![Ini Pada Tablet](/02-week-2-declarative-ui-responsive-design/screenshots/tablet-responsif.png)

   ![Ini Pada Mobile Phone](/02-week-2-declarative-ui-responsive-design/screenshots/praktikum-layar-mobile.jpeg)

4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.

## Tugas dan AI design exploration

## Tugas utama

Kembangkan dashboard menjadi halaman Academic Overview dengan ketentuan:

<li>Memiliki header profil dan minimal empat kartu informasi.
<li>Menggunakan Row, Column, Expanded, dan Container.
<li>Menampilkan satu kolom pada layar sempit dan dua kolom pada layar lebar.
<li>Menyediakan light theme dan dark theme yang tetap terbaca, dengan toggle tema (misal CupertinoSwitch atau Switch.adaptive).
<li>Memiliki label aksesibilitas untuk informasi atau tombol penting.
<li>Menyertakan screenshot layar sempit dan lebar pada folder screenshots/.

![](/02-week-2-declarative-ui-responsive-design/screenshots/tugas-mobile-preview.jpeg)

## AI Prompt Challenge

<li>Prompt desain. Ajukan prompt ini (atau variasinya): "Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya."
<li>Prompt penguatan konsep. "Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya."
<li>Verification prompt. Minta AI mengaudit hasilnya sendiri: "Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"
<li>Dokumentasikan. Simpan prompt, output penting, keputusan yang dipilih, alasan teknis, dan bukti verifikasi (test/screenshots) di README tugas minggu ini.
<p>Hasil Prompt ada di</p>
![](/02-week-2-declarative-ui-responsive-design/screenshots/prompt.md)

## Refactoring challenge

<li>Ekstrak kartu informasi menjadi widget reusable (misal InfoCard) yang menerima title dan value, sehingga tidak ada duplikasi widget.
<li>Ganti warna dan ukuran yang di-hardcode dengan Theme.of(context) agar mengikuti tema terang/gelap secara otomatis.
<li>Pindahkan breakpoint ke satu konstanta bernama (misal const kWideBreakpoint = 700;) agar hanya didefinisikan satu kali.
<li>Jalankan flutter analyze dan pastikan tidak ada error maupun warning baru.

![Tampilan Mobile](/02-week-2-declarative-ui-responsive-design/screenshots/refactoring-mobile-preview.jpeg)

##