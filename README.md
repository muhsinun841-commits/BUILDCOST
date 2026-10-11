# BUILDCOST V3 — Paket perbaikan fitur inti

Paket ini disiapkan dari sumber yang dikirim. Fitur AI tetap ditunda sampai alur inti stabil.

## Pembaruan yang disertakan
- Form proyek dengan validasi nama, panjang, dan lebar.
- Pratinjau visual konsep bangunan sederhana yang berubah mengikuti jenis bangunan, konsep desain, dan jumlah lantai. Ini hanya pratinjau konseptual, bukan gambar kerja/struktur.
- Template RAB awal berbeda untuk jalan dan jembatan; jenis bangunan lain menggunakan template bangunan umum.
- Input angka lebih toleran untuk format desimal titik atau koma dan format ribuan Indonesia.
- Pengaturan persentase cadangan biaya pada form proyek.
- Tambah, edit, hapus item RAB; progress proyek; database material; ubah nama pengguna.
- Ekspor/cetak PDF dan ekspor Excel `.xlsx` untuk dibagikan.
- Dialog konfirmasi saat menghapus proyek.
- Ikon aplikasi BUILDCOST navy-biru-oranye.
- GitHub Actions membangun APK release dan mengunggah artifact `buildcost-v3-apk`.

## Cara memasang ke repository GitHub
1. Unduh dan ekstrak ZIP ini.
2. Salin seluruh isi folder ke root repository BUILDCOST, termasuk folder tersembunyi `.github` dan `.gitignore`.
3. Pastikan `lib/main.dart`, `pubspec.yaml`, `.github/workflows/build.yml`, dan `assets/icon/buildcost_icon.png` ada di lokasi yang benar.
4. Commit dan push ke branch `main` (atau buka Actions dan jalankan workflow manual).
5. Buka tab **Actions**, pilih workflow **Build BUILDCOST Full APK**, lalu unduh artifact **buildcost-v3-apk** jika proses berhasil.

## Catatan penting
- Paket ini belum bisa diklaim lolos build karena Flutter SDK tidak tersedia di lingkungan penyusunan ini. Periksa hasil workflow GitHub Actions sebelum memasang APK.
- Harga dan volume RAB adalah perkiraan awal untuk membantu perencanaan, bukan penawaran final atau pengganti perhitungan tenaga profesional. Sesuaikan dengan gambar kerja, spesifikasi teknis, lokasi, dan harga aktual.
- Preview desain merupakan ilustrasi 2D sederhana, bukan desain arsitektur 3D, gambar kerja, analisis struktur, atau dokumen perizinan.
- Data proyek/material disimpan lokal pada perangkat melalui SharedPreferences; belum ada sinkronisasi cloud atau login akun online.
- Fitur AI sengaja belum diaktifkan.
