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

   ![Ini Pada Mobile Phone](/02-week-2-declarative-ui-responsive-design/screenshots/praktikum-layar-mobile.jpeg) 4. Tambahkan Semantics atau label yang bermakna pada elemen yang penting bagi screen reader.
