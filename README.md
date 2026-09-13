# 🐟 Bodoamat - Roblox "Fish It!" QoL & Automation Hub

**Bodoamat** adalah skrip Luau otomatisasi dan peningkatan kenyamanan bermain (*Quality of Life*) yang dibuat khusus untuk game **Fish It!** di Roblox.

Dirancang dengan arsitektur **Native Standalone**, skrip ini **tidak memerlukan unduhan library eksternal** dari internet (seperti Rayfield/WindUI) sehingga **100% stabil, sangat ringan, dan tidak akan pernah gagal load**.

---

## ⚡ Fitur Utama

### 1. 🎣 Mesin Memancing Otomatis (Dual-Mode Auto Fishing)
- **Mode Cepat (Direct Remote)**:
  - Terintegrasi langsung dengan framework jaringan `sleitnick/net` pada game Fish It (`RF/ChargeFishingRod`, `RF/RequestFishingMinigameStarted`, dan `RE/FishingCompleted`).
  - Menangkap ikan dalam hitungan milidetik secara instan.
- **Mode Natural (Input Simulation)**:
  - Menggunakan simulasi klik kursor natural (`VirtualInputManager` & `Tool:Activate`) untuk pemain yang menginginkan gaya bermain santai dan tidak mencolok.
- **Auto Equip Joran**:
  - Otomatis mendeteksi dan menggunakan joran dari tas (*Backpack*) jika joran belum terpasang di tangan.

### 2. 🛡️ Proteksi Penuh Anti-AFK
- **Mencegah Disconnect 20 Menit**:
  - Menghubungkan langsung ke event `Players.LocalPlayer.Idled` menggunakan `VirtualUser` untuk membatalkan kick idle dari Roblox engine secara otomatis.
- **Server-Side Micro-Movement**:
  - Mensimulasikan pergerakan mikro karakter setiap 5 menit agar tidak terdeteksi oleh sistem pengecek idle buatan game.

### 3. ⚡ Pengoptimal Grafis & Ultra GPU Saver
- **FPS Booster (Mode Grafis Rendah)**:
  - Menonaktifkan bayangan global (`GlobalShadows = false`), efek post-processing (`Bloom`, `SunRays`, `DepthOfField`), partikel kabut, dan trail.
  - Mengubah seluruh tekstur part menjadi `SmoothPlastic` dan menyembunyikan partikel berat.
  - Secara otomatis membersihkan objek baru yang muncul saat game berjalan (`Workspace.DescendantAdded`).
- **Ultra GPU Saver (Layar AFK Hitam Hemat Daya)**:
  - Menampilkan overlay status elegan di layar (Durasi AFK, total ikan tertangkap, status bot).
  - Membatasi rendering klien ke **15 FPS** (jika executor mendukung `setfpscap`), membuat suhu CPU/GPU laptop atau PC tetap **sangat dingin** saat farming semalaman.

### 4. 💰 Auto Jual Ikan Berkala
- Memanggil remote penjualan `RF/SellAllItems` setiap interval waktu tertentu (default: 60 detik).
- Terdapat tombol instan untuk menjual seluruh isi tas seketika.

### 5. 🎨 Antarmuka Mandiri Modern (Native UI)
- Desain *Dark-Glassmorphism* modern dengan aksen cyan glowing.
- Mendukung kontrol sentuh (*touchscreen*) untuk pemain **Mobile / Android** serta kontrol mouse drag untuk **PC**.
- **Tombol Floating Mobile (🐟)**: Mudah membuka/menutup UI di layar sentuh.
- **Keybind PC**: Tekan tombol `RightShift` untuk membuka atau menyembunyikan menu.
- Pemantauan statistik sesi secara real-time.

---

## 📂 Struktur Repositori

```
d:/PROGRAM/LuaRebel/
├── Bodoamat.luau               -- File All-in-One Mandiri (Siap dieksekusi langsung)
├── README.md                   -- Dokumentasi & panduan penggunaan
├── src/                        -- Kode sumber modular
│   ├── Config.luau             -- Konfigurasi bawaan dan pengaturan tema
│   ├── Core/
│   │   ├── Network.luau        -- Pengelola koneksi remote sleitnick_net
│   │   └── State.luau          -- Manajemen status runtime & counter sesi
│   ├── Modules/
│   │   ├── AutoFish.luau       -- Logika memancing (Fast Remote & Natural)
│   │   ├── AntiAfk.luau        -- Proteksi disconnect 20 menit & micro-move
│   │   ├── FpsBooster.luau     -- Pembersih grafis & GPU Saver AFK Screen
│   │   └── AutoSell.luau       -- Otomasi penjualan ikan berkala
│   └── UI/
│       └── BodoamatGui.luau    -- Tampilan GUI mandiri
└── reference/                  -- Arsip skrip referensi hasil riset
```

---

## 🚀 Cara Menjalankan

### Cara 1: Menggunakan File Tunggal `Bodoamat.luau` (Direkomendasikan)
1. Buka executor Roblox pilihan Anda (misalnya **Delta**, **Arceus X**, **Hydrogen**, **Wave**, dll.).
2. Masuk ke game **Fish It!** di Roblox.
3. Salin seluruh isi kode dari file [`Bodoamat.luau`](file:///d:/PROGRAM/LuaRebel/Bodoamat.luau).
4. Tempel ke dalam tab executor dan tekan tombol **Execute**.
5. Antarmuka menu **Bodoamat** akan langsung muncul di layar.

### Cara 2: Menutup & Membuka Menu
- **PC / Keyboard**: Tekan tombol keyboard `RightShift`.
- **Mobile / Touchscreen**: Ketuk ikon mengapung ikan `🐟` di sebelah kiri layar.

---

## ⚙️ Ringkasan Tab Menu

| Tab | Fitur Utama |
| :--- | :--- |
| **🎣 Memancing** | Toggle Auto Fish, Toggle Mode Super Cepat (Remote) vs Mode Natural, Tombol Equip Joran Manual. |
| **⚡ Performa** | Toggle FPS Booster (Grafis Ringan), Toggle Ultra GPU Saver (Layar AFK Hitam). |
| **🛡️ Utilitas** | Toggle Proteksi Anti-AFK 20 Menit, Toggle Auto Jual Berkala, Tombol Jual Semua Sekarang. |
| **📊 Statistik** | Tampilan real-time durasi waktu berjalan, total ikan ditangkap, dan log status terakhir. |

---

*Dibuat untuk kenyamanan dan stabilitas optimal saat bermain Fish It di Roblox.*
