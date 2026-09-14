# 🐟 Bodoamat v3.0 - Roblox "Fish It!" QoL, Expansion & Automation Hub

**Bodoamat v3.0** adalah skrip Luau otomatisasi dan peningkatan kenyamanan bermain (*Quality of Life*) terlengkap dan termutakhir yang dibuat khusus untuk game **Fish It!** di Roblox.

Versi 3.0 menghadirkan integrasi penuh dengan ekspansi zona game terbaru (**Copper Canyon**, **The Sewers**, **Mariana Trench**, **Crystal Depths**), sistem pemasangan **Totem otomatis**, akses **Black Market / Merchant jarak jauh**, peralatan eksplorasi laut dalam (**Tabung Oksigen & Radar Ikan**), kontrol **Cuaca Server**, dan perlindungan anti-cheat berlapis (**Anti-BAC 6228 & BAC 8228 Guard**).

---

## ⚡ Fitur Utama v3.0

### 1. 🗺️ Navigasi & Teleportasi 59 Lokasi Terurut Ascending (A - Z)
Dukungan penuh untuk seluruh zona peta, elemental doors, throne rooms, dan area ekspansi terbaru dengan daftar terurut rapi secara alfabetis ascending (A - Z) dari *Ancient Jungle* hingga *Weather Machine*:
- **🌟 Urutan Lokasi Lengkap (59 Spot Ascending A-Z)**:
  - Tersusun rapi dari A sampai Z untuk memudahkan pencarian instan tanpa perlu scrolling acak.
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
  - **Black Market (Mariana Trench)** & **Underground Cellar** (Pasar Gelap palung laut & bunker rahasia).
  - **Traveling Merchant / Alien** (Pedagang keliling).
  - **Weather Machine** (Pusat pengontrol cuaca).
- **🏝️ Pulau-Pulau Utama**:
  - Fisherman Island (Spawn), Kohana, Kohana Volcano/Lab, Coral Reefs, Tropical Grove, Crater Island, Mount Hallow, Classic Island, Esoteric Island, Stingray Shores.
- **🔮 Endgame & Gua Rahasia**:
  - Esoteric Depths (Enchant Stone), Lost Isle (Underwater), Sisyphus Statue, Treasure Room, Ancient Jungle, Ancient Ruin, Sacred Temple, Pirate Cove, Pirate Treasure Room, Leviathan Den, Iron Cavern, Iron Cafe, Planetary Observatory.
- **👥 Smart Scanner, Lokasi Terpadu & Pemain**:
  - **Daftar Lokasi Terpadu (Single List Ascending A-Z)**: Seluruh 59 lokasi teleportasi disatukan ke dalam satu daftar ringkas dan bersih yang otomatis tersortir A-Z, mempercepat pemilihan zona memancing.
  - **Smart Player Scanner & Dropdown Teleport**: Memindai seluruh pemain aktif di server dengan 1 klik tombol 'Scan Player', memilih pemain lewat menu dropdown dinamis, dan langsung teleport ke posisinya secara aman tanpa tabrakan hitbox (input manual dihilangkan demi mencegah anomali).
  - **Simpan Titik Kustom (Waypoint)**: Simpan koordinat memancing favorit dan teleport kembali kapan saja.
  - **Workspace Dynamic Scanner**: Mendeteksi otomatis pergeseran posisi pulau jika terjadi update map oleh developer game (mengabaikan zona trigger `Areas`).

### 2. 🗿 Sistem Otomasi Totem (Luck, Shiny, Mutation)
- **Pilihan Tipe Totem**: Mendukung *Luck Totem* (+100% Luck), *Shiny Totem* (+50% Shiny), dan *Mutation Totem* (+100% Mutation).
- **Pasang 1 Totem**: Menempatkan 1 totem langsung di posisi karakter.
- **Formasi 5 Totem (+)**: Memasang 5 totem dalam formasi salib dengan radius 50-60 studs untuk menjamin cakupan area buff maksimal tanpa jeda.
- **Auto Pasang Totem Berkala**: Loop otomatis yang mengecek dan menempatkan kembali totem setiap 60 detik saat durasi totem sebelumnya habis.

### 3. 🛒 Kunjungan Toko & Black Market Aman (Bebas BAC-4212)
- **Kunjungan Black Market Aman**: Teleportasi langsung ke hadapan pedagang Black Market di Mariana Trench dengan auto proteksi O2 dan tombol kembali 1-klik.
- **Kunjungan Pedagang Keliling (Traveling Merchant)**: Teleportasi aman ke kapal pedagang alien untuk belanja langsung di NPC secara wajar tanpa memicu tripwire interaksi.
- **Bebas Manipulasi ProximityPrompt**: Menghapus total fungsi buatan `fireproximityprompt` dan hold bypass yang memicu peringatan anti-cheat server `BAC-4212`.
- **Pengontrol Cuaca Server**: Membeli event cuaca server (*Storm, Thunderstorm, Cloudy, Wind*) secara terverifikasi.

### 4. 🤿 Eksplorasi Laut Dalam & Radar Ikan
- **Tabung Oksigen Laut Dalam (Oxygen Tank)**: Mengaktifkan tabung selam aman (dengan verifikasi kepemilikan item di inventaris) agar karakter tidak kehabisan nafas di kedalaman tanpa memicu tripwire `BAC-4214`.
- **Fishing Radar**: Mengaktifkan radar visual untuk mendeteksi posisi, jarak, dan tingkat kelangkaan (*rarity*) ikan di dalam air.

### 5. 🛡️ Keamanan Anti-BAC (Bacon Anti-Cheat Protected)
- **BAC-4212 Guard (Zero ProximityPrompt & Remote Shop Manipulation)**:
  - Mengeliminasi pemanggilan fungsi tiruan `fireproximityprompt(prompt, 0)` dan manipulasi engine `InputHoldBegin()` yang memicu deteksi instan interaksi NPC.
  - Menghapus pemindaian agresif `Workspace:GetDescendants()` saat mengunjungi toko.
  - Menghapus fitur remote buy Totem tanpa tatap muka demi mencegah anomali verifikasi jarak NPC; pemain cukup berbelanja langsung di hadapan pedagang lalu menekan tombol kembali 1-klik.
- **BAC-4214 Guard (Rate-Limit & Inventory Verification)**:
  - Membatasi penguncian favorit ikan maksimal 4 item per pass dengan jeda aman 0.35s ke server, hanya untuk tier tinggi (*Legendary, Mitos, Secret*).
  - Menambahkan verifikasi kepemilikan tool sebelum memanggil `RF/EquipOxygenTank(105)` ke server.
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
- **BAC-6219 Guard (Fishing State Isolation & Anti-Conflict Inventory Protection)**:
  - Mengisolasi pemanggilan transaksi inventaris (`RF/SellAllItems` dan `RE/FavoriteItem`) agar tidak pernah dieksekusi saat pemain sedang memancing aktif (joran melempar kail dengan bobber di air atau minigame UI sedang berlangsung), yang merupakan pemicu utama kode anti-cheat `BAC-6219`.
  - Dilengkapi verifikasi status memancing multi-layer (`isFishingActive`) dengan mekanisme auto-wait hingga 5 detik sebelum mengeksekusi penjualan otomatis, memastikan siklus tangkapan selesai terlebih dahulu.
  - Mengintegrasikan opsi **Mode Aman Dekat Pedagang TP (MerchantSafeTp)** secara penuh: menteleportasikan karakter ke hadapan pedagang secara instan saat menjual lalu mengembalikannya ke posisi memancing semula.
  - Meningkatkan debounce transaksi penjualan menjadi 2.5 detik untuk mencegah flood remote function.
- **BAC-8228 Guard (Safe Selling & Fishing Isolation)**:
  - Mengunci status `IsSelling` saat proses jual berlangsung.
  - Memberi jeda buffer sebelum memanggil `RF/SellAllItems` secara bersih tanpa mengganggu alat yang dipegang karakter.
  - Dilengkapi opsi **Mode Aman Dekat Pedagang TP (MerchantSafeTp)** untuk teleportasi singkat ke pedagang saat menjual jika karakter berada di luar jangkauan jual.
- **BAC-1216 Guard (Safe Render Pipeline & Anti-Black Screen)**:
  - Mengeliminasi pemanggilan `RunService:Set3dRenderingEnabled(false)` yang mematikan pipeline render 3D dan menyebabkan `RenderStepped` membeku (*frame freeze*), penyebab langsung munculnya peringatan anti-cheat `BAC-1216`.
  - Menerapkan sistem pemulihan instan grafis 3D dan kamera saat skrip dimuat maupun saat GPU Saver dinonaktifkan.
- **Ultra GPU Saver (Safe Anti-BAC 1216 & Low Temp)**:
  - Mengurangi beban GPU dan CPU hingga 80-90% dengan membatasi framerate AFK ke 15 FPS (`setfpscap(15)`) dan menurunkan shader ke level terendah, tanpa mematikan render 3D ataupun membuat layar hitam permanen.
  - Saat dinonaktifkan, kualitas grafis dan FPS langsung kembali normal 100% secara instan.

### 6. Memancing Manual Murni & Auto-Sell Cerdas (Bebas BAC)
- **100% Manual Human Play**: Fitur otomatisasi joran/pancingan (Auto Fishing & Auto Equip Rod) dihapus sepenuhnya dari script.
- Pemain memancing secara mandiri dan wajar layaknya pemain asli, menjamin 0% risiko deteksi timing lemparan kail server.
- **Auto-Sell Batas Kapasitas Ikan (Threshold Input)**: Dilengkapi kolom input/textbox angka jumlah ikan pada tab *Selling* (misal diisi 100, maka saat ikan ke-101 tertangkap, script langsung otomatis mengeksekusi penjualan tanpa harus menunggu timer).
- **Auto Favorite Ikan Langka**: Mengamankan otomatis ikan bernilai tinggi (*Legendary, Mitos, Secret*) sebelum siklus jual massal saat fitur ini diaktifkan.

### 7. Antarmuka Minimalis Elegan & Clean Typography (Bebas Icon / Emoji)
- Tampilan modern bernuansa *Dark-Glassmorphism* tanpa icon/emoji yang mengalihkan perhatian, dirancang simpel namun tetap elegan dengan tipografi bersih (*clean typography*) dan aksen warna tematik.
- **Ukuran Lega & Tombol Maximize (`[□]` / `[❐]`)**: Ukuran jendela default diperbesar menjadi 640x480 (responsif terhadap layar), dan dilengkapi tombol Maximize di sebelah tombol keluar `(X)` untuk memperbesar tampilan secara instan hingga 880x620.
- **6 Tab Kontrol Bersih (Local Player Pertama)**:
  1. *Local Player* (Id: `Movement` - Walk On Water, Infinite Jump, Jump Power)
  2. *Selling* (Toko, Black Market, Auto-Sell & Auto-Favorite)
  3. *Totem* (Deploy Totem, Oksigen Laut Dalam, Radar, & Cuaca)
  4. *Teleport* (Scanner Pemain & 59 Lokasi Terurut A-Z)
  5. *Optimasi* (GPU Saver & FPS Booster)
  6. *Status* (Statistik Live Sesi & Status Keamanan Anti-BAC)
- **Tombol Floating Mobile (`MENU`)**: Badge tombol minimalis elegan bertuliskan `MENU` yang dapat digeser bebas (*touch draggable*) di layar perangkat Android/iOS untuk membuka/menutup antarmuka.
- **Keybind PC**: Tekan tombol `RightShift` pada keyboard.

### 8. Tab Local Player & Movement (Desain Atomic Hub)
- Tab pertama di sidebar **Local Player** (Id: `Movement`) mengusung kartu section **MOVEMENT**:
  - `Walk On Water (Jesus Walk)`: Berjalan di atas permukaan air laut tanpa jatuh.
  - `Infinite Jump`: Lompat bebas di udara tanpa batas.
  - `Set Jump Power`: Input box numerik (50 - 250) aman dari tripwire anti-cheat *BAC-7214*.

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
│       └── BodoamatGui.luau    -- Tampilan GUI native 6-tab modern (Local Player di posisi pertama)
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
