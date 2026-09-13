# 🐟 Bodoamat v2.0 - Roblox "Fish It!" QoL, Automation & Anti-Cheat Safe Hub

**Bodoamat v2.0** adalah skrip Luau otomatisasi dan peningkatan kenyamanan bermain (*Quality of Life*) terlengkap yang dibuat khusus untuk game **Fish It!** di Roblox.

Versi 2.0 hadir dengan arsitektur **Anti-BAC (Bacon Anti-Cheat Protected)** yang didesain secara khusus untuk mencegah tripwire deteksi client integrity (bebas kick **CODE BAC-6228 / Kode Eror 267**), serta dilengkapi dengan fitur teleport 14 pulau, proteksi auto-favorite ikan langka, Jesus walk (jalan di atas air), dan multi-mode fishing.

---

## ⚡ Fitur Utama v2.0

### 1. 🛡️ Keamanan Anti-BAC (Bacon Anti-Cheat Protected)
- **Nol Modifikasi Workspace Parts**:
  - FPS Booster membersihkan partikel visual, trail, beam, dan post-processing bloom tanpa merubah `Material`, `CastShadow`, atau komponen tubuh karakter sehingga tidak memicu tripwire integritas klien (**BAC-6228**).
- **Namecall Intercept Blocker**:
  - Memasang `hookmetamethod(game, "__namecall", ...)` yang menidurkan skrip lokal game saat mencoba memanggil cancel remotes (`RF/CancelFishingInputs`), mencegah klien game lokal menggagalkan atau melaporkan aktivitas memancing ke server.
- **Dynamic Server Time Validation**:
  - Mengirim parameter dinamis `workspace:GetServerTimeNow()` untuk sinkronisasi waktu jaringan yang valid.
- **Ultra GPU Saver Bebas Desync**:
  - Menggunakan `RunService:Set3dRenderingEnabled(false)` saat AFK. Render 3D kartu grafis dimatikan (suhu laptop/HP langsung dingin), namun physics tick tetap berjalan normal pada 60 fps tanpa memicu deteksi tick desync.
- **Auto Rejoin on Disconnect/Kick**:
  - Otomatis melakukan teleportasi ulang ke server jika terjadi gangguan koneksi atau modal kick.

### 2. 🎣 Mesin Memancing Multi-Mode (Triple-Mode Auto Fishing)
- **Mode Legit (Human Click Simulation)**:
  - 100% aman dan tidak terdeteksi karena murni menggunakan simulasi klik mouse dan aktivasi joran tanpa menyentuh remote function game.
- **Mode Fast (Safe Remote dengan Jitter)**:
  - Eksekusi remote langsung dengan jeda acak manusiawi (*random jitter*) untuk farming efisien yang tetap aman.
- **Mode Blatant (Instant Catch)**:
  - Multi-reel instan untuk grinding tangkapan massal dalam hitungan milidetik.
- **Auto Equip Joran**:
  - Otomatis mendeteksi dan memasang joran dari tas (*Backpack*) atau hotbar ke tangan karakter.

### 3. 🌟 Auto Favorite & Proteksi Ikan Langka
- Mengintegrasikan remote `RE/FavoriteItem` untuk mengunci otomatis ikan berharga tinggi (*Rare, Epic, Legendary, Mythic, Secret, Exotic*) di tas inventory sebelum siklus penjualan massal berjalan.
- Menjamin ikan legendaris dan langka tidak akan pernah terjual secara tidak sengaja.

### 4. 💰 Auto Sell Ikan Berkala
- Menjual hasil tangkapan secara otomatis setiap 45 detik ke merchant.
- Dilengkapi tombol manual instan "Jual Semua Ikan Sekarang".

### 5. 🗺️ Teleport 14 Lokasi Pulau & Secret Spots
Pindah lokasi seketika ke seluruh penjuru peta Fish It:
1. **Spawn Island**
2. **Sisyphus Statue**
3. **Coral Reefs**
4. **Esoteric Depths**
5. **Crater Island**
6. **Lost Isle**
7. **Weather Machine**
8. **Tropical Grove**
9. **Mount Hallow**
10. **Treasure Room**
11. **Kohana**
12. **Underground Cellar**
13. **Ancient Jungle**
14. **Sacred Temple**

### 6. 🏃 Mobilitas & Kemampuan Karakter
- **Walk On Water (Jesus Walk)**: Berjalan di atas permukaan air laut tanpa khawatir jatuh atau tenggelam.
- **Infinite Jump**: Melompat berkali-kali di udara secara bebas.
- **WalkSpeed Modifier**: Mengatur kecepatan lari karakter (16, 32, 64, hingga 120).

### 7. 🎨 Antarmuka Modern Mandiri (Native Standalone UI)
- Desain *Dark-Glassmorphism* modern tanpa dependency library eksternal (No Rayfield/WindUI) sehingga **100% stabil dan tidak akan pernah gagal load**.
- **6 Tab Navigasi**: *Memancing, Toko & Fav, Teleport, Mobilitas, Performa, dan Statistik*.
- **Tombol Floating Mobile (🐟)**: Mempermudah pemain Android/iOS membuka dan menutup menu.
- **Keybind PC**: Tekan tombol `RightShift` pada keyboard.

---

## 📂 Struktur Repositori

```
d:/PROGRAM/LuaRebel/
├── Bodoamat.luau               -- File All-in-One Mandiri Standalone (Siap dieksekusi)
├── README.md                   -- Dokumentasi & panduan penggunaan
├── src/                        -- Kode sumber modular
│   ├── Config.luau             -- Konfigurasi bawaan & preferensi tema
│   ├── Core/
│   │   ├── Network.luau        -- Pengelola remote sleitnick_net & Namecall blocker
│   │   └── State.luau          -- Manajemen status runtime & counter sesi
│   ├── Modules/
│   │   ├── AutoFish.luau       -- Mesin memancing (Legit, Fast, Blatant)
│   │   ├── AutoSell.luau       -- Otomasi penjualan & auto-favorite ikan langka
│   │   ├── Teleport.luau       -- Navigasi 14 lokasi pulau & secret spot
│   │   ├── Movement.luau       -- Walk on water, infinite jump, & speed modifier
│   │   ├── FpsBooster.luau     -- Pembersih visual aman anti-BAC & GPU Saver
│   │   └── AntiAfk.luau        -- Proteksi disconnect 20 menit & auto-rejoin
│   └── UI/
│       └── BodoamatGui.luau    -- Tampilan GUI native 6 tab
└── reference/                  -- Arsip riset skrip referensi
```

---

## 🚀 Cara Menjalankan

### Link Raw GitHub
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/iMango21/bodoamat/main/Bodoamat.luau"))()
```

### Langkah Penggunaan
1. Buka executor Roblox pilihan Anda (misalnya **Delta**, **Arceus X**, **Hydrogen**, **Wave**, **Codex**, dll.).
2. Masuk ke game **Fish It!** di Roblox.
3. Masukkan perintah loadstring di atas atau salin isi dari [`Bodoamat.luau`](file:///d:/PROGRAM/LuaRebel/Bodoamat.luau).
4. Tekan **Execute**.
5. Tekan `RightShift` (di PC) atau ketuk ikon `🐟` (di Mobile) untuk menampilkan/menyembunyikan menu.
