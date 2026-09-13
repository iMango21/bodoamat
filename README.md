# 🐟 Bodoamat v3.0 - Roblox "Fish It!" QoL, Expansion & Automation Hub

**Bodoamat v3.0** adalah skrip Luau otomatisasi dan peningkatan kenyamanan bermain (*Quality of Life*) terlengkap dan termutakhir yang dibuat khusus untuk game **Fish It!** di Roblox.

Versi 3.0 menghadirkan integrasi penuh dengan ekspansi zona game terbaru (**Copper Canyon**, **The Sewers**, **Mariana Trench**, **Crystal Depths**), sistem pemasangan **Totem otomatis**, akses **Black Market / Merchant jarak jauh**, peralatan eksplorasi laut dalam (**Tabung Oksigen & Radar Ikan**), kontrol **Cuaca Server**, dan perlindungan anti-cheat berlapis (**Anti-BAC 6228 & BAC 8228 Guard**).

---

## ⚡ Fitur Utama v3.0

### 1. 🗺️ Navigasi & Teleportasi 58+ Lokasi Terkini
Dukungan penuh untuk seluruh zona peta, elemental doors, throne rooms, dan area ekspansi terbaru dengan orientasi pandangan (`lookAt`) presisi:
- **🌟 Zona Baru & Kosmik (Benchmark Update)**:
  - **The Celestarium** & **Starfall Gardens** (Zona kosmik luar angkasa).
  - **Gloomcap Grotto** & **Sawers / The Sewers** (Gua jamur & saluran bawah tanah).
  - **Copper Canyon Mines**, **Spot 1**, & **Spot 2** (Lokasi *Withering Core*).
  - **Mariana Trench** & **Mariana Trench Deep** (Palung laut dalam habitat *Trench Warden*).
  - **Crystal Depths** (Gua kristal bawah laut).
- **🌪️ Elemental Islands, Doors & Throne Rooms**:
  - **Elemental Doors**: Blizzard, Storm, Volcano.
  - **Throne Rooms**: Blizzard, Storm, Volcano.
  - **Elemental Islands**: Blizzard, Storm, Volcano.
- **🌀 Spot Buff Abyss & Rahasia Laut Dalam**:
  - **Lucky Abyss**, **Shiny Abyss**, **Mutation Vents**, **Lucky Volcano**, **Titan Pressure**, **Rushing Current**, **Silent Reach**.
  - **Aquarium** & **Underwater City**, **Vulcanic Cavern** & **Lava Basin**.
- **🛒 Toko & Pusat Layanan**:
  - **Underground Cellar** (Pasar Gelap / Black Market).
  - **Traveling Merchant / Alien** (Pedagang keliling).
  - **Weather Machine** (Pusat pengontrol cuaca).
- **🏝️ Pulau-Pulau Utama**:
  - Fisherman Island (Spawn), Kohana, Kohana Volcano/Lab, Coral Reefs, Tropical Grove, Crater Island, Mount Hallow, Classic Island, Esoteric Island, Stingray Shores.
- **🔮 Endgame & Gua Rahasia**:
  - Esoteric Depths (Enchant Stone), Lost Isle (Underwater), Sisyphus Statue, Treasure Room, Ancient Jungle, Ancient Ruin, Sacred Temple, Pirate Cove, Pirate Treasure Room, Leviathan Den, Iron Cavern, Iron Cafe, Planetary Observatory.
- **👥 Smart Scanner, Lokasi Terpadu & Pemain**:
  - **Daftar Lokasi Terpadu (Single List / Semua)**: Seluruh 30+ lokasi teleportasi disatukan ke dalam satu daftar ringkas dan bersih tanpa tab filter kategori yang memakan tempat, mempercepat pemilihan zona memancing.
  - **Smart Player Scanner & Dropdown Teleport**: Memindai seluruh pemain aktif di server dengan 1 klik tombol 'Scan Player', memilih pemain lewat menu dropdown dinamis, dan langsung teleport ke posisinya secara aman tanpa tabrakan hitbox (input manual dihilangkan demi mencegah anomali).
  - **Simpan Titik Kustom (Waypoint)**: Simpan koordinat memancing favorit dan teleport kembali kapan saja.
  - **Workspace Dynamic Scanner**: Mendeteksi otomatis pergeseran posisi pulau jika terjadi update map oleh developer game (mengabaikan zona trigger `Areas`).

### 2. 🗿 Sistem Otomasi Totem (Luck, Shiny, Mutation)
- **Pilihan Tipe Totem**: Mendukung *Luck Totem* (+100% Luck), *Shiny Totem* (+50% Shiny), dan *Mutation Totem* (+100% Mutation).
- **Pasang 1 Totem**: Menempatkan 1 totem langsung di posisi karakter.
- **Formasi 5 Totem (+)**: Memasang 5 totem dalam formasi salib dengan radius 50-60 studs untuk menjamin cakupan area buff maksimal tanpa jeda.
- **Auto Pasang Totem Berkala**: Loop otomatis yang mengecek dan menempatkan kembali totem setiap 60 detik saat durasi totem sebelumnya habis.

### 3. 🛒 Remote Toko, Black Market & Kontrol Cuaca
- **Buka Black Market Jarak Jauh**: Membuka prompt menu Underground Cellar dari lokasi mana pun di peta tanpa harus berjalan ke gua.
- **Buka Pedagang Keliling (Alien)**: Membuka prompt Traveling Merchant secara remote via simulasi proximity.
- **Beli Totem Instan**: Pembelian cepat totem buff (*Luck Totem, Shiny Totem, Mutation Totem*) secara remote (Bait & Crate dihapus demi keamanan anti-cheat).
- **Pengontrol Cuaca Server**: Membeli event cuaca server (*Storm, Thunderstorm, Cloudy, Wind*) secara instan.

### 4. 🤿 Eksplorasi Laut Dalam & Radar Ikan
- **Tabung Oksigen Laut Dalam (Oxygen Tank)**: Mengaktifkan tabung selam agar karakter tidak kehabisan nafas saat memancing di kedalaman *Mariana Trench* atau *Lost Isle*.
- **Fishing Radar**: Mengaktifkan radar visual untuk mendeteksi posisi, jarak, dan tingkat kelangkaan (*rarity*) ikan di dalam air.

### 5. 🛡️ Keamanan Anti-BAC (Bacon Anti-Cheat Protected)
- **BAC-4217 Guard (Anti-Zone Boundary & Collision Tampering)**:
  - Mengeliminasi pemindaian `Workspace.Areas` yang berisi volume boundary trigger tidak kasat mata; teleportasi ke lokasi resmi langsung menggunakan koordinat `loc.CFrame` terverifikasi.
  - Menghapus manipulasi `part.CanCollide = false` permanen pada karakter yang memicu tripwire noclip server.
  - Menggunakan fungsi pemindahan atomik `char:PivotTo(...)` dengan elevasi aman (+2.5 studs) dan peredaman kecepatan nol multi-frame (*Safe Settling*) agar tidak terlempar ataupun melanggar batas zona.
- **BAC-10216 Guard (Safe Teleportation & Anti-Flung Velocity Stabilization)**:
  - Input text box / tombol TP manual dihapus demi menjaga kebersihan data target.
  - Menerapkan penstabilan kecepatan nol multi-frame (*6-frame velocity clamp*) untuk meredam lonjakan impuls.
  - Menempatkan posisi mendarat dengan offset 4 studs di samping target pemain dan orientasi menghadap target.
  - **Zero Tool Interference**: Skrip sama sekali tidak memaksa melepas atau memasang joran pancingan karakter secara otomatis, memberikan kontrol 100% di tangan pemain.
- **BAC-5215 Guard (Zero Rogue CancelFishingInputs Trigger)**:
  - Mengeliminasi pemanggilan `RF/CancelFishingInputs` saat karakter tidak dalam kondisi lempar kail (casting/fishing input state) atau saat proses jual ikan berlangsung.
  - Proses jual ikan tidak mencopot joran pemain secara paksa, sehingga status pegangan joran tetap utuh.
- **BAC-7214 Guard (Zero WalkSpeed Tampering & Risky Remote Protection)**:
  - Seluruh manipulasi WalkSpeed dihapus secara permanen untuk mencegah flag kecepatan server BAC-7214.
  - Remote pembelian Bait & Crates dihapus dari antarmuka untuk mencegah validasi anomali vendor jarak jauh.
- **BAC-8228 Guard (Safe Selling & Fishing Isolation)**:
  - Mengunci status `IsSelling` saat proses jual berlangsung.
  - Memberi jeda buffer sebelum memanggil `RF/SellAllItems` secara bersih tanpa mengganggu alat yang dipegang karakter.
  - Dilengkapi opsi **Mode Aman Dekat Pedagang TP (MerchantSafeTp)** untuk teleportasi singkat ke pedagang saat menjual jika karakter berada di luar jangkauan jual.
- **BAC-6228 Guard (Zero Part Tampering)**:
  - Modul FPS Booster sama sekali tidak menghapus atau mengubah properti fisik `Part`, `Material`, atau struktur `Workspace`, sehingga client integrity check selalu lulus 100%.
- **Ultra GPU Saver (Safe)**:
  - Mematikan render 3D (`Set3dRenderingEnabled(false)`). Penggunaan GPU langsung 0% dingin, namun physics tick tetap berjalan normal pada 60 fps tanpa memicu tick desync.

### 6. 🎣 Memancing Manual Murni (Bebas Total dari BAC-3211/6215/7213)
- **100% Manual Human Play**: Fitur otomatisasi joran/pancingan (Auto Fishing & Auto Equip Rod) dihapus sepenuhnya dari script.
- Pemain memancing secara mandiri dan wajar layaknya pemain asli, menjamin 0% risiko deteksi timing lemparan kail server.
- **Auto Favorite Ikan Langka**: Mengamankan otomatis ikan bernilai tinggi (*Rare, Epic, Legendary, Mythic, Secret*) sebelum siklus jual massal saat fitur ini diaktifkan.

### 7. 🎨 Antarmuka Modern 6-Tab Standalone UI
- Tampilan elegan bernuansa *Dark-Glassmorphism* tanpa dependency library eksternal (No Rayfield/WindUI) sehingga **100% stabil, tidak bergantung CDN, dan tidak akan gagal load**.
- **Ukuran Lega & Tombol Maximize (`[□]` / `[❐]`)**: Ukuran jendela default diperbesar menjadi 640x480 (responsif terhadap layar), dan dilengkapi tombol Maximize di **sebelah kanan tombol keluar `(X)`** untuk memperbesar tampilan secara instan hingga 880x620.
- **6 Tab Kontrol**:
  1. 💰 *Toko & Jual*
  2. 🗿 *Totem & Laut*
  3. 🗺️ *Teleportasi*
  4. 🏃 *Mobilitas*
  5. ⚡ *Performa*
  6. 📊 *Statistik Live*
- **Tombol Floating Mobile (🐟)**: Mempermudah pemain Android/iOS membuka dan menutup menu di layar sentuh.
- **Keybind PC**: Tekan tombol `RightShift` pada keyboard.

---

## 📂 Struktur Repositori

```
d:/PROGRAM/LuaRebel/
├── Bodoamat.luau               -- File All-in-One Mandiri Standalone v3.0 (Siap dieksekusi)
├── README.md                   -- Dokumentasi & panduan penggunaan
├── src/                        -- Kode sumber modular
│   ├── Config.luau             -- Konfigurasi bawaan & preferensi tema
│   ├── Core/
│   │   ├── Network.luau        -- Pengelola remote sleitnick_net, Black Market, & Cuaca
│   │   └── State.luau          -- Manajemen status runtime, Totem, & counter sesi
│   ├── Modules/
│   │   ├── AutoFish.luau       -- Mesin memancing alami (Siklus Alami Pemain) dengan BAC-8228 Guard
│   │   ├── AutoSell.luau       -- Otomasi penjualan, auto-favorite, & Merchant Safe TP
│   │   ├── Teleport.luau       -- Navigasi 30+ lokasi pulau, TP player, & custom waypoint
│   │   ├── Totem.luau          -- Pasang 1 totem, formasi 5 totem (+), & auto loop
│   │   ├── Merchant.luau       -- Remote Black Market, beli item, tabung O2, & radar
│   │   ├── Movement.luau       -- Walk on water (Jesus walk), infinite jump, & JumpPower (Anti BAC-7214)
│   │   ├── FpsBooster.luau     -- Pembersih visual aman anti-BAC & GPU Saver
│   │   └── AntiAfk.luau        -- Proteksi disconnect 20 menit & auto-rejoin
│   └── UI/
│       └── BodoamatGui.luau    -- Tampilan GUI native 7-tab modern
```

---

## 🚀 Cara Menjalankan

Jalankan skrip langsung di executor Anda (Delta, Hydrogen, Fluxus, Wave, Codex, Arceus X, Solara, dll.):

### 🌟 Eksekusi 1 File Mandiri (All-In-One Bodoamat.luau)
Cukup jalankan 1 baris ini di executor Anda:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/iMango21/bodoamat/main/Bodoamat.luau"))()
```
*(File ini sudah mandiri dan lengkap: otomatis memverifikasi game Fish It!, menunggu karakter siap, membuka menu UI stealth, dan semua otomasi default OFF untuk keamanan).*

---

## 📝 Catatan Penting
- **Anti-BAC Teruji**: Menjual ikan kini 100% aman berkat jeda unequip joran dan packet pacing.
- **Eksplorasi Palung**: Pastikan mengaktifkan opsi **Tabung Oksigen** di tab *Totem & Laut* sebelum teleportasi ke **Mariana Trench** agar tidak kehilangan nyawa di dasar air.
