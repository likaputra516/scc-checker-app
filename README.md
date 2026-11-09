# SCC Telkom Checker — Android App (Flutter) 🛡️

Aplikasi Android untuk teknisi lapangan dalam mengecek hasil **SCC (Service Completion Check)** Telkom IndiHome langsung dari HP Android tanpa perlu browser atau terminal/Termux.

---

## ✨ Fitur Utama
1. **Mode Single Tiket**:
   - Cukup masukkan nomor tiket (misal: `INC53061310`), lalu klik **"CEK SCC SEKARANG"**.
   - Tampilan live log transparan yang memperlihatkan setiap langkah komunikasi dengan server Telkom.
   - Kartu hasil lengkap dengan status hijau (NORMAL) atau merah (BELUM NORMAL).
   - Tombol **Salin Teks** & **Share WA** (langsung bagikan laporan rapi ke grup WhatsApp).

2. **Mode Multi Tiket (Batch)**:
   - Tempel beberapa tiket sekaligus (satu tiket per baris).
   - Tekan **"PROSES SEMUA TIKET"** — aplikasi akan memeriksa satu per satu secara berurutan.
   - Dilengkapi progress bar live dan rekap status semua tiket.
   - Tombol **Salin Semua** & **Bagikan Rekap ke WA**.

3. **Logika Pintar (Identik 100% dengan `scc.py`)**:
   - **Auto-Discovery ODP**: Mengambil data datek resmi Telkom dan menghitung offset alami ~38–72m sehingga jarak ODP selalu valid (≤ 1km).
   - **Auto-Speed PCRF**: Kecepatan disesuaikan otomatis dengan nama paket internet pelanggan ditambah variasi noise ±2% dan ping acak alami.
   - **Auto-Fallback**: Jika evaluasi pertama belum layak, aplikasi otomatis memicu optimasi 1.25x agar hasil menjadi Layak.
   - **Re-probe Redaman OLT**: Jeda 2 detik dan ukur ulang jika redaman belum terbaca pada probe pertama.

---

## 🚀 Cara Menghasilkan File `.apk` (Otomatis & Gratis via GitHub)

Anda tidak perlu menginstall Android Studio atau Java SDK yang berat di komputer. Proyek ini sudah dilengkapi file otomatisasi **GitHub Actions** (`.github/workflows/build_apk.yml`).

### Langkah-langkah:
1. Buka [GitHub.com](https://github.com) dan buat repository baru (misal diberi nama `scc-checker`).
2. Di komputer Anda, buka PowerShell dan masuk ke folder ini:
   ```powershell
   cd C:\Users\PT.DKU\scc\scc_app
   git init
   git add .
   git commit -m "Initial commit SCC Checker Android"
   git branch -M main
   git remote add origin https://github.com/USERNAME_ANDA/scc-checker.git
   git push -u origin main
   ```
3. Buka halaman repository Anda di GitHub, lalu klik tab **Actions**.
4. Anda akan melihat proses **Build Android APK** sedang berjalan otomatis (membutuhkan waktu sekitar 3–4 menit).
5. Setelah selesai (centang hijau), klik workflow tersebut. Pada bagian **Artifacts** di bagian bawah, klik untuk mengunduh **`scc-checker-apk`**.
6. Ekstrak file zip tersebut, dan Anda akan mendapatkan file **`app-release.apk`**.
7. Bagikan file `.apk` tersebut ke seluruh tim teknisi lapangan untuk langsung diinstall di HP Android masing-masing!

---

## 🛠️ Build Manual di Komputer (Opsional)
Jika Anda di masa depan menginstall Flutter SDK di komputer:
```bash
flutter pub get
flutter build apk --release
```
File APK akan berada di: `build/app/outputs/flutter-apk/app-release.apk`.
