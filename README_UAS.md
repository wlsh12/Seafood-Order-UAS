# Seafood Order — panduan UAS

Aplikasi mengambil katalog dengan `GET /menus` dari MockAPI. Keranjang, checkout,
dan riwayat pesanan disimpan secara lokal menggunakan SQLite.

## Menyiapkan MockAPI

Endpoint default aplikasi sudah disetel ke resource `menus` proyek Seafood Order:

```text
https://6afd25642a9c141d36b83a44.mockapi.io/api/v1/menus
```

Jika resource `menus` kosong, isi katalog dengan langkah berikut:

1. Buka resource `menus` di project **Seafood Order UAS**.
2. Tambahkan record satu per satu dengan field `name`, `category`, `price`,
   `description`, `image`, dan `available`.
3. Gunakan contoh-contoh record dari file `mockapi-menus.json` di folder project.
   `id` boleh dibuat otomatis oleh MockAPI.
4. Buka ulang aplikasi atau tekan tombol muat ulang di halaman utama.

Tidak perlu mengubah template endpoint berbayar. Jika URL resource berbeda,
ganti nilai pada perintah menjalankan di bawah. Aplikasi tidak membuat data menu
palsu ketika resource kosong atau request gagal.

## Menjalankan

Buka folder `september` yang berisi `pubspec.yaml` di Android Studio. Jalankan
`flutter pub get`, pilih perangkat Android, lalu jalankan `lib/main.dart`.
Untuk menjalankan lewat terminal dari folder project:

```bash
flutter pub get
flutter run
```

Untuk memakai URL berbeda dari endpoint default:

```bash
flutter run --dart-define=MENU_API_URL=https://<project-id>.mockapi.io/api/v1/menus
```

Setelah mengubah URL, hentikan lalu jalankan ulang aplikasi. Tombol refresh
meminta katalog kembali dari API. Di Android Studio, argumen opsional URL dapat
dimasukkan pada **Run Configuration → Additional run args**.

## Alur dan penyimpanan

- Menu dan harga dimuat dari API. Keranjang hanya menerima menu berstatus tersedia.
- Checkout memvalidasi alamat dan menyimpan tanggal pengiriman, pilihan alat
  makan, serta metode pembayaran yang dipilih sebagai catatan lokal.
- Pesanan dan item disimpan di SQLite pada perangkat yang menjalankan aplikasi.
- Pesanan tidak dikirim ke MockAPI; resource MockAPI hanya menyediakan katalog.
- Jika database versi lama sudah ada, migrasi menambahkan detail checkout dan
  mempertahankan pesanan sebelumnya.

Untuk menjalankan aplikasi dari source Android, permission internet sudah ada
di `android/app/src/main/AndroidManifest.xml`, termasuk pada build release.

## Demo akun, pembayaran, dan invoice

1. Pilih **Daftar akun** dan masukkan email serta kata sandi minimal 8 karakter.
   Akun tersimpan di perangkat ini. Gunakan menu **Akun → Keluar akun** untuk
   berganti akun. Saat aplikasi dibuka ulang, masuk kembali.
2. Tambahkan menu ke keranjang, buka Checkout, isi form dan centang konfirmasi.
   Pilih **QRIS** atau **Transfer Bank**, lalu tekan **Lanjut ke pembayaran**.
3. Periksa kode QR dan nominal. Kode QR berisi teks simulasi untuk demo UAS.
   Tekan **Selesaikan Pembayaran** untuk menyimpan pesanan atau **Batal**
   untuk kembali ke checkout. Jangan transfer uang.
4. Pilih **Buka invoice PDF** dari dialog sukses atau detail pesanan di
   Riwayat. Gunakan ikon bagikan pada pratinjau PDF untuk mengekspor file.

Migrasi SQLite versi 4 mempertahankan data lama tanpa pemilik sebagai arsip
lokal. Riwayat, keranjang, dan favorit yang terlihat setelah masuk hanya milik
akun aktif. Arsip versi lama tidak ditampilkan di akun baru.

| Bagian | File dan fungsi inti |
| --- | --- |
| Akun | `pages/login_page.dart` memvalidasi form. `services/local_auth.dart` membuat dan membandingkan hash PBKDF2 dengan salt acak. `main.dart` memuat keranjang akun saat login. |
| Pembayaran | `pages/demo_payment.dart` menampilkan instruksi dan QR simulasi. `checkout_page.dart` hanya meneruskan penyimpanan setelah pengguna mengonfirmasi simulasi. |
| SQLite | `services/app_database.dart` menyaring baris berdasarkan akun. `saveOrder()` menyimpan pesanan, item, dan pengosongan keranjang akun dalam satu transaksi. |
| PDF | `pages/invoice_page.dart` menghasilkan invoice dari harga item, tanggal, dan total pesanan yang tersimpan. Invoice mencantumkan status pesanan dan keterangan bahwa pembayaran tidak ditagihkan. |
