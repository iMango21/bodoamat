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
- **👥 Smart Scanner & Pemain**:
  - **Teleport ke Pemain**: Cukup ketik nama pemain di server untuk langsung teleport ke posisinya.
  - **Simpan Titik Kustom (Waypoint)**: Simpan koordinat memancing favorit dan teleport kembali kapan saja.
  - **Workspace Dynamic Scanner**: Mendeteksi otomatis pergeseran posisi pulau jika terjadi update map oleh developer game.

### 2. 🗿 Sistem Otomasi Totem (Luck, Shiny, Mutation)
- **Pilihan Tipe Totem**: Mendukung *Luck Totem* (+100% Luck), *Shiny Totem* (+50% Shiny), dan *Mutation Totem* (+100% Mutation).
- **Pasang 1 Totem**: Menempatkan 1 totem langsung di posisi karakter.
- **Formasi 5 Totem (+)**: Memasang 5 totem dalam formasi salib dengan radius 50-60 studs untuk menjamin cakupan area buff maksimal tanpa jeda.
- **Auto Pasang Totem Berkala**: Loop otomatis yang mengecek dan menempatkan kembali totem setiap 60 detik saat durasi totem sebelumnya habis.

### 3. 🛒 Remote Toko, Black Market & Kontrol Cuaca
- **Buka Black Market Jarak Jauh**: Membuka prompt menu Underground Cellar dari lokasi mana pun di peta tanpa harus berjalan ke gua.
- **Buka Pedagang Keliling (Alien)**: Membuka prompt Traveling Merchant secara remote via simulasi proximity.
- **Refresh Stok Merchant**: Memperbarui barang dagangan pedagang langsung via remote network.
- **Beli Umpan Instan**: Pembelian cepat umpan terbaik (*Singularity Bait, Royal Bait, Enchanted Bait, Golden Bait*).
- **Pengontrol Cuaca Server**: Membeli event cuaca server (*Storm, Thunderstorm, Cloudy, Wind*) secara instan.

### 4. 🤿 Eksplorasi Laut Dalam & Radar Ikan
- **Tabung Oksigen Laut Dalam (Oxygen Tank)**: Mengaktifkan tabung selam agar karakter tidak kehabisan nafas saat memancing di kedalaman *Mariana Trench* atau *Lost Isle*.
- **Fishing Radar**: Mengaktifkan radar visual untuk mendeteksi posisi, jarak, dan tingkat kelangkaan (*rarity*) ikan di dalam air.

### 5. 🛡️ Keamanan Anti-BAC (Bacon Anti-Cheat Protected)
- **BAC-8228 Guard (Safe Selling & Fishing Isolation)**:
  - Mengunci status `IsSelling` saat proses jual berlangsung.
  - Menghentikan input pancing (`CancelFishingInputs`), mencopot joran ke tas (*unequip*), memberi jeda buffer 0.4 detik sebelum memanggil `RF/SellAllItems`, lalu memasang kembali joran setelah selesai.
  - Dilengkapi opsi **Mode Aman Dekat Pedagang TP (MerchantSafeTp)** untuk teleportasi singkat ke pedagang saat menjual jika karakter berada di luar jangkauan jual.
- **BAC-6228 Guard (Zero Part Tampering)**:
  - Modul FPS Booster sama sekali tidak menghapus atau mengubah properti fisik `Part`, `Material`, atau struktur `Workspace`, sehingga client integrity check selalu lulus 100%.
- **Ultra GPU Saver (AFK Safe)**:
  - Mematikan render 3D (`Set3dRenderingEnabled(false)`) saat ditinggal tidur/AFK. Penggunaan GPU langsung 0% dingin, namun physics tick tetap berjalan normal pada 60 fps tanpa memicu tick desync.
- **Anti-AFK 20 Menit & Auto-Rejoin**:
  - Mencegah Roblox Idle Kick 20 menit dan otomatis menyambung kembali ke server jika jaringan terputus.

### 6. 🎣 Mesin Memancing Alami (Natural Human Play - Bebas BAC-3211)
- **Mode Normal / Alami**: Memancing dengan siklus waktu realistis seorang manusia (7 - 9 detik per ikan):
  - Fase 1: Menunggu umpan dimakan (2.8 - 4.2 detik acak).
  - Fase 2: Minigame reel realistis (2.2 - 3.4 detik acak).
  - Fase 3: Tarik kail dan jeda istirahat natural (1.2 - 2.0 detik).
  - Menghilangkan mode tidak wajar (Fast/Blatant) yang dapat memicu rate-limit BAC-3211 pada server.
- **Aman Ditinggal AFK (24/7)**: Fitur Anti-AFK dapat diaktifkan kapan saja via menu UI (default: nonaktif untuk keamanan saat baru join). Mengintegrasikan `VirtualUser` idle intercept, micro-movement setiap 2 menit, serta `Auto-Rejoin` otomatis jika terjadi disconnect.
- **Konfigurasi Aman (Default Nonaktif)**: Seluruh fitur otomasi (mancing, jual, totem, mobilitas, anti-afk) bermula dalam status **OFF** saat skrip dieksekusi untuk menghindari kesalahan eksekusi. User memiliki kontrol penuh untuk menyalakan fitur yang diinginkan melalui menu UI.
- **Auto Favorite Ikan Langka**: Mengamankan otomatis ikan bernilai tinggi (*Rare, Epic, Legendary, Mythic, Secret*) sebelum siklus jual massal saat fitur ini diaktifkan.

### 7. 🎨 Antarmuka Modern 7-Tab Standalone UI
- Tampilan elegan bernuansa *Dark-Glassmorphism* tanpa dependency library eksternal (No Rayfield/WindUI) sehingga **100% stabil, tidak bergantung CDN, dan tidak akan gagal load**.
- **7 Tab Kontrol**:
  1. 🎣 *Memancing*
  2. 💰 *Toko & Jual*
  3. 🗿 *Totem & Laut*
  4. 🗺️ *Teleportasi*
  5. 🏃 *Mobilitas*
  6. ⚡ *Performa*
  7. 📊 *Statistik Live*
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
│   │   ├── Movement.luau       -- Walk on water (Jesus walk), infinite jump, & walkspeed
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
