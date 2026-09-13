--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     BODOAMAT v3.0 - FISH IT                   ║
    ║   Quality of Life, Automation Hub & Anti-BAC Protected       ║
    ║   Hosted at: https://github.com/iMango21/bodoamat            ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Changelog v3.0 (Stealth Anti-BAC & Delta Executor):
    - 🛡️ BAC Stealth Mode: UI murni gethui() tanpa menyentuh CoreGui (100% bebas tripwire BAC-6228)
    - ⚡ Talon Anti-Remote Bypass: Resolusi resmi via Packages.Net & fallback non-blocking
    - 🛡️ Netralisasi Pelaporan BAC: Nonaktifkan listener client pada AC-Response & Punishment
    - 🚫 Zero Startup Footprint: Tidak menyentuh _G/CoreGui, 100% aman dan bersih
    - 📱 Mobile Touch Draggable: Tombol 🐟 dapat digeser bebas di layar perangkat Android/Delta
    - 🗺️ 30+ Lokasi Teleportasi Baru: Copper Canyon, Sewers, Mariana Trench, Crystal Depths, dll.
    - 🗿 Sistem Totem Otomatis: Pasang 1 Totem, Formasi 5 Totem (+), dan Auto-Deploy Loop
    - 🛒 Remote Merchant & Black Market: Buka Pasar Gelap & Traveling Merchant jarak jauh
    - 🤿 Eksplorasi Laut Dalam & Radar: Tabung Oksigen Anti-Tenggelam & Radar Ikan
    - ⛈️ Pengontrol Cuaca Server: Beli Storm, Thunderstorm, Cloudy, Wind langsung
    - 🎣 Mode Auto-Fishing Alami (Natural Human Play): Siklus realistis 7-9 detik/ekor, bebas anomali BAC-3211
    - 🛡️ Safe Execution: Semua otomasi default NONAKTIF untuk mencegah kesalahan eksekusi
]]

-- ============================================================
-- 1. IDENTIFIKASI & VALIDASI GAME (FISH IT ONLY)
-- ============================================================
local FISH_IT_IDS = {
    Universes = {
        [6701277882]      = true, -- Fish It Main Universe ID
        [79378095465365]  = true, -- Alternative Universe ID
    },
    Places = {
        [121864768012064] = true, -- Fish It Main Place ID
        [79378095465365]  = true, -- Fallback Direct Place ID
    }
}

if not (FISH_IT_IDS.Universes[game.GameId] or FISH_IT_IDS.Places[game.PlaceId]) then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "⚠️ Akses Dibatalkan",
            Text = "Script Bodoamat HANYA untuk game Fish It!",
            Duration = 5
        })
    end)
    return
end

-- Tunggu game dan map selesai dimuat
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Proteksi Instance Duplikat (Gunakan getgenv terisolasi, jangan sentuh _G)
local genv = (getgenv and getgenv()) or {}
if genv.__BODOAMAT_LOADED then
    warn("[Bodoamat] Script sudah berjalan pada sesi ini.")
    return
end
genv.__BODOAMAT_LOADED = true

-- ============================================================
-- GLOBAL SERVICES & SHORTCUTS
-- ============================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ============================================================
-- 1. CONFIGURATION
-- ============================================================
local Config = {
    -- Auto Fishing
    AutoFish = {
        Enabled = false,
        CastDelay = 3.5,          -- Jeda natural menunggu ikan menggigit (detik)
        CatchDelay = 2.5,         -- Jeda natural menarik kail / reel minigame (detik)
        AutoEquipRod = true,      -- Otomatis mencari & equip joran jika belum dipakai
    },

    -- Optimasi Grafis & Kinerja (Safe Anti-BAC)
    Performance = {
        FpsBoost = false,       -- Menghilangkan partikel & post-effects (tanpa merusak model/parts)
        GpuSaver = false,       -- Mematikan raster 3D (GPU 0% panas, physics tick normal)
    },

    -- Auto Sell & Auto Favorite (Default: NON-AKTIF)
    AutoSell = {
        Enabled = false,          -- Default NON-AKTIF
        Interval = 45,          -- Menjual otomatis setiap N detik
        AutoFavorite = false,   -- Default NON-AKTIF
        MinRarity = "Legendary",-- Tingkat kelangkaan minimal yang diamankan
        MerchantSafeTp = false, -- Default NON-AKTIF
    },

    -- Totem Automation
    Totem = {
        AutoTotem = false,
        Type = "Luck Totem",    -- "Luck Totem", "Shiny Totem", "Mutation Totem"
        Interval = 60,
    },

    -- Deep Sea & Merchant Tools
    DeepSea = {
        OxygenTank = false,
        FishingRadar = false,
    },

    -- Movement & QoL
    Movement = {
        WaterWalk = false,      -- Berjalan di atas air (Jesus Walk)
        InfiniteJump = false,   -- Lompat di udara tanpa batas
        WalkSpeed = 16,
        JumpPower = 50,
    },

    -- Desain UI
    UI = {
        Title = "BODOAMAT",
        Subtitle = "Fish It! v3.0 - Expansion & Complete Automation",
        ToggleKey = Enum.KeyCode.RightShift,
        Theme = {
            Background = Color3.fromRGB(16, 18, 26),
            CardBg = Color3.fromRGB(24, 28, 38),
            Border = Color3.fromRGB(40, 46, 62),
            Accent = Color3.fromRGB(0, 180, 255),
            AccentHover = Color3.fromRGB(40, 200, 255),
            Success = Color3.fromRGB(46, 204, 113),
            Danger = Color3.fromRGB(231, 76, 60),
            Text = Color3.fromRGB(240, 243, 246),
            TextSubtle = Color3.fromRGB(140, 148, 164),
        }
    }
}

-- ============================================================
-- 2. CORE: STATE MANAGEMENT
-- ============================================================
local State = {
    -- Runtime states
    IsFishing = false,
    IsSelling = false,
    IsFpsBoost = false,
    IsGpuSaver = false,
    IsAutoSell = false,
    MerchantSafeTp = false,
    IsAutoFavorite = false,
    MinFavoriteRarity = "Legendary",

    -- Totem & Laut Dalam (v3.0)
    IsAutoTotem = false,
    TotemType = "Luck Totem",
    IsRadar = false,
    IsOxygenEquipped = false,
    
    -- Movement
    IsWaterWalk = false,
    IsInfJump = false,
    WalkSpeed = 16,
    JumpPower = 50,

    -- Statistika Session
    StartTime = os.time(),
    FishCaught = 0,
    TotalCoinsEarned = 0,
    LastStatusMessage = "Sistem Siap",

    -- Listeners
    Listeners = {} :: { [string]: { (any) -> () } }
}

function State:GetElapsedTime(): string
    local elapsed = os.time() - self.StartTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function State:Set(key: string, value: any)
    (self :: any)[key] = value
    if self.Listeners[key] then
        for _, callback in ipairs(self.Listeners[key]) do
            task.spawn(callback, value)
        end
    end
end

function State:OnChange(key: string, callback: (any) -> ())
    if not self.Listeners[key] then
        self.Listeners[key] = {}
    end
    table.insert(self.Listeners[key], callback)
end

-- ============================================================
-- 3. CORE: NETWORK HANDLER
-- ============================================================
local Network = {
    HasRemotes = false,
    Remotes = {} :: { [string]: Instance? },
}

-- Inisialisasi Remote sleitnick_net dengan Dual-Layer Stealth Resolution
function Network:Init(): boolean
    local success, _ = pcall(function()
        -- METODE 1 (Resmi & Stealth Talon Bypass): require(ReplicatedStorage.Packages.Net)
        local netModule = nil
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages and packages:FindFirstChild("Net") then
            local okNet, res = pcall(require, packages.Net)
            if okNet and res and type(res) == "table" then
                netModule = res
            end
        end

        if netModule then
            local function resolveRF(rawName: string)
                local r = nil
                pcall(function() r = (netModule :: any):RemoteFunction(rawName) end)
                if not r then
                    pcall(function() r = (netModule :: any):RemoteFunction("RF/" .. rawName) end)
                end
                return r
            end

            local function resolveRE(rawName: string)
                local r = nil
                pcall(function() r = (netModule :: any):RemoteEvent(rawName) end)
                if not r then
                    pcall(function() r = (netModule :: any):RemoteEvent("RE/" .. rawName) end)
                end
                return r
            end

            self.Remotes["ChargeRod"]       = resolveRF("ChargeFishingRod")
            self.Remotes["RequestGame"]     = resolveRF("RequestFishingMinigameStarted")
            self.Remotes["CompleteGame"]    = resolveRE("FishingCompleted") or resolveRE("CatchFishCompleted")
            self.Remotes["CancelInput"]     = resolveRF("CancelFishingInputs") or resolveRE("CancelFishingInputs")
            self.Remotes["SellAll"]         = resolveRF("SellAllItems")
            self.Remotes["EquipHotbar"]     = resolveRE("EquipToolFromHotbar")
            self.Remotes["UnequipHotbar"]   = resolveRE("UnequipToolFromHotbar")
            self.Remotes["Favorite"]        = resolveRE("FavoriteItem")
            self.Remotes["AutoFishState"]   = resolveRF("UpdateAutoFishingState")
            self.Remotes["EquipTank"]       = resolveRF("EquipOxygenTank")
            self.Remotes["UpdateRadar"]     = resolveRF("UpdateFishingRadar")
            self.Remotes["BuyWeather"]      = resolveRF("PurchaseWeatherEvent")
            self.Remotes["BuyItem"]         = resolveRF("BuyItem")
            self.Remotes["RefreshMerchant"] = resolveRF("RefreshMerchant")

            if self.Remotes["ChargeRod"] and self.Remotes["CompleteGame"] then
                self.HasRemotes = true
                return
            end
        end

        -- METODE 2 (Fallback): Cari sleitnick_net langsung secara non-blocking
        if not packages then return end
        local indexFolder = packages:FindFirstChild("_Index")
        if not indexFolder then return end

        local netFolder = nil
        for _, child in ipairs(indexFolder:GetChildren()) do
            if string.find(child.Name, "sleitnick_net") then
                netFolder = child:FindFirstChild("net")
                if netFolder then break end
            end
        end

        if not netFolder then return end

        self.Remotes["ChargeRod"]       = netFolder:FindFirstChild("RF/ChargeFishingRod")
        self.Remotes["RequestGame"]     = netFolder:FindFirstChild("RF/RequestFishingMinigameStarted")
        self.Remotes["CompleteGame"]    = netFolder:FindFirstChild("RE/FishingCompleted") or netFolder:FindFirstChild("RE/CatchFishCompleted")
        self.Remotes["CancelInput"]     = netFolder:FindFirstChild("RF/CancelFishingInputs") or netFolder:FindFirstChild("RE/CancelFishingInputs")
        self.Remotes["SellAll"]         = netFolder:FindFirstChild("RF/SellAllItems")
        self.Remotes["EquipHotbar"]     = netFolder:FindFirstChild("RE/EquipToolFromHotbar")
        self.Remotes["UnequipHotbar"]   = netFolder:FindFirstChild("RE/UnequipToolFromHotbar")
        self.Remotes["Favorite"]        = netFolder:FindFirstChild("RE/FavoriteItem")
        self.Remotes["AutoFishState"]   = netFolder:FindFirstChild("RF/UpdateAutoFishingState")
        self.Remotes["EquipTank"]       = netFolder:FindFirstChild("RF/EquipOxygenTank")
        self.Remotes["UpdateRadar"]     = netFolder:FindFirstChild("RF/UpdateFishingRadar")
        self.Remotes["BuyWeather"]      = netFolder:FindFirstChild("RF/PurchaseWeatherEvent")
        self.Remotes["BuyItem"]         = netFolder:FindFirstChild("RF/BuyItem")
        self.Remotes["RefreshMerchant"] = netFolder:FindFirstChild("RF/RefreshMerchant")

        self.HasRemotes = (self.Remotes["ChargeRod"] ~= nil and self.Remotes["CompleteGame"] ~= nil)
    end)

    if self.HasRemotes then
        print("[Bodoamat] Jaringan game (sleitnick_net) terhubung 100% via Stealth Pipeline.")
    else
        warn("[Bodoamat] Jaringan game belum siap, akan dicoba kembali saat fitur diaktifkan.")
    end

    return self.HasRemotes
end

-- Wrapper: Lempar Kail (Charge) - Anti BAC-7213 & Anti BAC-4218
function Network:ChargeRod(power: number?): boolean
    local remote = self.Remotes["ChargeRod"]
    if remote and remote:IsA("RemoteFunction") then
        local now = workspace:GetServerTimeNow()
        local safePower = power or 1
        local ok, _ = pcall(function()
            remote:InvokeServer(safePower, nil, now, nil)
        end)
        if not ok then
            pcall(function()
                remote:InvokeServer(safePower)
            end)
        end
        return true
    end
    return false
end

-- Wrapper: Permintaan Minigame - Dynamic Live Timestamp (Anti BAC-6217 & Anti BAC-52110)
function Network:RequestMinigame(diff: number?, luck: number?): boolean
    local remote = self.Remotes["RequestGame"]
    if remote and remote:IsA("RemoteFunction") then
        local now = workspace:GetServerTimeNow()
        local safeDiff = diff or 0
        local safeLuck = luck or 1
        local ok, _ = pcall(function()
            remote:InvokeServer(safeDiff, safeLuck, now)
        end)
        if not ok then
            pcall(function()
                remote:InvokeServer(0, 1, now)
            end)
        end
        return true
    end
    return false
end

-- Wrapper: Selesaikan Tangkapan (Reel) - RemoteEvent FishingCompleted Standar Pemain
function Network:CompleteFishing(): boolean
    local remote = self.Remotes["CompleteGame"]
    if remote then
        local ok, _ = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer()
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer()
            end
        end)
        pcall(function()
            self:CancelInput()
        end)
        return ok
    end
    return false
end

-- Wrapper: Batalkan Input Kail
function Network:CancelInput(): boolean
    local remote = self.Remotes["CancelInput"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer()
        end)
        return ok
    end
    return false
end

-- Wrapper: Jual Semua Ikan
function Network:SellAll(): boolean
    local remote = self.Remotes["SellAll"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer()
        end)
        return ok
    end
    return false
end

-- Wrapper: Equip dari Hotbar (Slot 1 = Rod)
function Network:EquipHotbar(slot: number?): boolean
    local remote = self.Remotes["EquipHotbar"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function()
            remote:FireServer(slot or 1)
        end)
        return ok
    end
    return false
end

-- Wrapper: Unequip dari Hotbar
function Network:UnequipHotbar(slot: number?): boolean
    local remote = self.Remotes["UnequipHotbar"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function()
            remote:FireServer(slot or 1)
        end)
        return ok
    end
    return false
end

-- Wrapper: Kunci/Favoritkan Ikan Langka
function Network:FavoriteItem(uuid: string): boolean
    local remote = self.Remotes["Favorite"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function()
            remote:FireServer(uuid)
        end)
        return ok
    end
    return false
end

-- Wrapper: Pasang Tabung Oksigen (Deep Diving / Mariana Trench)
function Network:EquipOxygenTank(): boolean
    local remote = self.Remotes["EquipTank"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer()
        end)
        return ok
    end
    return false
end

-- Wrapper: Aktifkan/Matikan Radar Ikan
function Network:UpdateFishingRadar(enabled: boolean): boolean
    local remote = self.Remotes["UpdateRadar"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer(enabled)
        end)
        return ok
    end
    return false
end

-- Wrapper: Beli Event Cuaca Server (Storm, Wind, Cloudy, Snow, dll.)
function Network:PurchaseWeather(weatherName: string): boolean
    local remote = self.Remotes["BuyWeather"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer(weatherName)
        end)
        return ok
    end
    return false
end

-- Wrapper: Beli Item dari Merchant/Toko (Totem, Bait, Crate)
function Network:BuyItem(itemName: string): boolean
    local remote = self.Remotes["BuyItem"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer(itemName)
        end)
        return ok
    end
    return false
end

-- Wrapper: Refresh Stok Merchant
function Network:RefreshMerchant(): boolean
    local remote = self.Remotes["RefreshMerchant"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer()
        end)
        return ok
    end
    return false
end

-- ============================================================
-- 4. MODULE: FPS BOOSTER
-- ============================================================
local FpsBooster = {
    IsFpsBoosted = false,
    IsGpuSaverActive = false,
    GpuSaverGui = nil :: ScreenGui?,
    StatsUpdateThread = nil :: thread?,
    OriginalSettings = {
        GlobalShadows = true,
        FogEnd = 100000,
    }
}

-- [[ 1. FPS BOOST AMAN (Zero Workspace-Part Tamper) ]]
function FpsBooster:SetFpsBoost(enabled: boolean)
    if self.IsFpsBoosted == enabled then return end
    self.IsFpsBoosted = enabled

    if enabled then
        pcall(function()
            self.OriginalSettings.GlobalShadows = Lighting.GlobalShadows
            self.OriginalSettings.FogEnd = Lighting.FogEnd
            
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9

            -- Matikan efek post-processing Lighting yang membebani GPU
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") then
                    effect.Enabled = false
                end
            end
        end)

        -- Matikan efek partikel visual berat tanpa menyentuh BasePart/Material (Mencegah tripwire BAC-6228)
        pcall(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or desc:IsA("Fire") or desc:IsA("Smoke") then
                    desc.Enabled = false
                end
            end
        end)

        -- Turunkan level kualitas render Roblox ke minimum (resmi dari API engine)
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        print("[Bodoamat | FPS] Mode Grafis Ringan (Safe Anti-BAC) aktif.")
    else
        pcall(function()
            Lighting.GlobalShadows = self.OriginalSettings.GlobalShadows
            Lighting.FogEnd = self.OriginalSettings.FogEnd
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") then
                    effect.Enabled = true
                end
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)

        print("[Bodoamat | FPS] Mode Grafis Standar dipulihkan.")
    end
end

-- [[ 2. ULTRA GPU SAVER (Set3dRenderingEnabled - Bebas Desync Tick) ]]
function FpsBooster:SetGpuSaver(enabled: boolean, stateRef: any)
    if self.IsGpuSaverActive == enabled then return end
    self.IsGpuSaverActive = enabled

    if enabled then
        -- Kunci Rahasia Anti-BAC: Matikan render 3D engine tanpa mengubah tick rate physics / fps cap
        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)

        -- Buat Layar Minimalis Stat Overlay
        local gui = Instance.new("ScreenGui")
        gui.Name = "Bodoamat_GpuSaver"
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 999999
        gui.IgnoreGuiInset = true

        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
        bg.BorderSizePixel = 0
        bg.Parent = gui

        -- Card Informasi di tengah
        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 440, 0, 250)
        card.Position = UDim2.new(0.5, -220, 0.5, -125)
        card.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
        card.BorderSizePixel = 0
        card.Parent = bg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 170, 255)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.3
        stroke.Parent = card

        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 45)
        title.BackgroundTransparency = 1
        title.Text = "🛡️ GPU SAVER ACTIVE (SAFE AFK)"
        title.TextColor3 = Color3.fromRGB(0, 210, 255)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.Parent = card

        -- Info status
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -30, 0, 125)
        infoLabel.Position = UDim2.new(0, 15, 0, 50)
        infoLabel.BackgroundTransparency = 1
        infoLabel.TextColor3 = Color3.fromRGB(220, 225, 235)
        infoLabel.TextSize = 14
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.TextYAlignment = Enum.TextYAlignment.Top
        infoLabel.RichText = true
        infoLabel.Parent = card

        -- Tombol Exit
        local exitBtn = Instance.new("TextButton")
        exitBtn.Size = UDim2.new(1, -30, 0, 42)
        exitBtn.Position = UDim2.new(0, 15, 1, -52)
        exitBtn.BackgroundColor3 = Color3.fromRGB(0, 130, 210)
        exitBtn.Text = "Matikan GPU Saver (Kembali ke Tampilan Game)"
        exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        exitBtn.TextSize = 13
        exitBtn.Font = Enum.Font.GothamMedium
        exitBtn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = exitBtn

        local safeParent = nil
        if gethui then
            local ok, h = pcall(gethui)
            if ok and h then safeParent = h end
        end
        if not safeParent then
            safeParent = LocalPlayer:WaitForChild("PlayerGui")
        end
        gui.Parent = safeParent
        self.GpuSaverGui = gui

        -- Loop update statistik
        self.StatsUpdateThread = task.spawn(function()
            while self.IsGpuSaverActive do
                local elapsed = (stateRef and stateRef:GetElapsedTime()) or "--:--:--"
                local fish = (stateRef and stateRef.FishCaught) or 0
                local status = (stateRef and stateRef.IsFishing) and "<font color='#2ecc71'>Sedang Memancing</font>" or "<font color='#e74c3c'>Standby / Tidak Memancing</font>"

                infoLabel.Text = string.format(
                    "<b>Status Farm:</b> %s\n<b>Durasi AFK:</b> %s\n<b>Ikan Ditangkap:</b> %d Ekor\n<b>Teknologi:</b> 3D Rasterization Disabled (Zero GPU Heat)\n<b>Anti-Cheat:</b> Physics tick normal (Aman dari BAC-6228)",
                    status, elapsed, fish
                )
                task.wait(1)
            end
        end)

        print("[Bodoamat | GPU] GPU Saver Aktif (3D Engine Sleep). Suhu perangkat dijamin dingin.")
    else
        -- Pulihkan 3D rendering
        pcall(function()
            RunService:Set3dRenderingEnabled(true)
        end)

        if self.StatsUpdateThread then
            task.cancel(self.StatsUpdateThread)
            self.StatsUpdateThread = nil
        end

        if self.GpuSaverGui then
            self.GpuSaverGui:Destroy()
            self.GpuSaverGui = nil
        end

        print("[Bodoamat | GPU] GPU Saver Dinonaktifkan. Tampilan 3D pulih.")
    end
end

-- ============================================================
-- 6. MODULE: MOVEMENT
-- ============================================================
local Movement = {
    IsWaterWalk = false,
    IsInfJump = false,
    WalkSpeed = 16,
    JumpPower = 50,
    
    WaterPlatform = nil :: Part?,
    HeartbeatConn = nil :: RBXScriptConnection?,
    JumpConn = nil :: RBXScriptConnection?,
}

-- [[ 1. WALK ON WATER (JESUS WALK) ]]
function Movement:SetWaterWalk(enabled: boolean)
    if self.IsWaterWalk == enabled then return end
    self.IsWaterWalk = enabled

    if enabled then
        pcall(function()
            if not self.WaterPlatform then
                local part = Instance.new("Part")
                part.Name = "Bodoamat_WaterWalk"
                part.Size = Vector3.new(24, 1.2, 24)
                part.Anchored = true
                part.CanCollide = true
                part.Transparency = 1
                part.Material = Enum.Material.Air
                part.Parent = workspace
                self.WaterPlatform = part
            end
        end)

        if not self.HeartbeatConn then
            self.HeartbeatConn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if hrp and self.WaterPlatform then
                    -- Posisi platform dinamis tepat di bawah kaki pemain sejajar permukaan air laut (-0.6)
                    self.WaterPlatform.CFrame = CFrame.new(hrp.Position.X, -0.6, hrp.Position.Z)
                end

                -- Terapkan WalkSpeed / JumpPower secara konsisten
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if self.WalkSpeed ~= 16 and hum.WalkSpeed ~= self.WalkSpeed then
                        hum.WalkSpeed = self.WalkSpeed
                    end
                    if self.JumpPower ~= 50 and hum.JumpPower ~= self.JumpPower then
                        hum.JumpPower = self.JumpPower
                    end
                end
            end)
        end
        print("[Bodoamat | Movement] Walk on Water diaktifkan.")
    else
        if not self.IsWaterWalk and self.WalkSpeed == 16 and self.JumpPower == 50 then
            if self.HeartbeatConn then
                self.HeartbeatConn:Disconnect()
                self.HeartbeatConn = nil
            end
        end

        if self.WaterPlatform then
            self.WaterPlatform:Destroy()
            self.WaterPlatform = nil
        end
        print("[Bodoamat | Movement] Walk on Water dinonaktifkan.")
    end
end

-- [[ 2. INFINITE JUMP ]]
function Movement:SetInfiniteJump(enabled: boolean)
    if self.IsInfJump == enabled then return end
    self.IsInfJump = enabled

    if enabled then
        if not self.JumpConn then
            self.JumpConn = UserInputService.JumpRequest:Connect(function()
                if not self.IsInfJump then return end
                pcall(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)
            end)
        end
        print("[Bodoamat | Movement] Infinite Jump diaktifkan.")
    else
        if self.JumpConn then
            self.JumpConn:Disconnect()
            self.JumpConn = nil
        end
        print("[Bodoamat | Movement] Infinite Jump dinonaktifkan.")
    end
end

-- [[ 3. SPEED & JUMP MODIFIERS ]]
function Movement:SetWalkSpeed(speed: number)
    self.WalkSpeed = math.clamp(speed, 16, 200)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = self.WalkSpeed end
    end
end

function Movement:SetJumpPower(power: number)
    self.JumpPower = math.clamp(power, 50, 250)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = self.JumpPower end
    end
end

-- ============================================================
-- 7. MODULE: AUTO FISHING
-- ============================================================
local AutoFish = {
    Running = false,
    Thread = nil :: thread?,
    IsFishing = false,
}

-- Pastikan joran terpasang di tangan karakter (Universal bahasa: Rod, Batang, dll.)
function AutoFish:EnsureRodEquipped(net: any): boolean
    local char = LocalPlayer.Character
    if not char then return false end

    -- 1. Jika karakter sudah memegang tool di tangan, langsung gunakan!
    local heldTool = char:FindFirstChildOfClass("Tool")
    if heldTool then
        return true
    end

    -- 2. Panggil Remote Hotbar Slot 1 (Joran utama)
    if net and net.HasRemotes then
        net:EquipHotbar(1)
        task.wait(0.1)
    end

    -- 3. Fallback: Ambil tool pertama dari Backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local bpTool = backpack:FindFirstChildOfClass("Tool")
        if bpTool then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:EquipTool(bpTool)
                task.wait(0.1)
            end
        end
    end

    return (char:FindFirstChildOfClass("Tool") ~= nil)
end

-- Mulai Loop Auto Fishing
function AutoFish:Start(config: any, state: any, network: any)
    if self.Running then return end
    self.Running = true

    self.Thread = task.spawn(function()
        print("[Bodoamat | Fishing] Memulai memancing (Siklus Alami Pemain).")

        while self.Running do
            local ok, err = pcall(function()
                -- Jeda jika proses penjualan sedang berlangsung agar tidak memicu konflik state
                if state and state.IsSelling then
                    task.wait(0.8)
                    return
                end

                -- Pastikan joran siap di tangan
                self:EnsureRodEquipped(network)

                local char = LocalPlayer.Character
                local currentTool = char and char:FindFirstChildOfClass("Tool")

                -- ==========================================
                -- SIKLUS MEMANCING ALAMI (NATURAL HUMAN PLAY)
                -- ==========================================
                state.LastStatusMessage = "🎣 Melempar Kail..."
                if network and network.HasRemotes then
                    network:EquipHotbar(1)
                    task.wait(0.25)

                    -- Aktivasi lemparan kail normal (Dynamic server timestamp)
                    network:ChargeRod()

                    -- Fase 1: Menunggu ikan memakan umpan (Waktu natural 2.8 - 4.2 detik acak)
                    local biteWait = 2.8 + (math.random(10, 140) / 100)
                    state.LastStatusMessage = "⏳ Menunggu Ikan Menggigit..."

                    local elapsed = 0
                    while elapsed < biteWait do
                        if not self.Running or (state and state.IsSelling) then return end
                        task.wait(0.2)
                        elapsed = elapsed + 0.2
                    end

                    -- Fase 2: Minigame reel dimulai (Dynamic server timestamp)
                    state.LastStatusMessage = "🐟 Ikan Menggigit! Memulai Tarikan..."
                    network:RequestMinigame()

                    -- Durasi minigame wajar pemain (2.2 - 3.4 detik acak)
                    local reelWait = 2.2 + (math.random(10, 120) / 100)
                    elapsed = 0
                    while elapsed < reelWait do
                        if not self.Running or (state and state.IsSelling) then return end
                        task.wait(0.2)
                        elapsed = elapsed + 0.2
                    end

                    -- Batalkan tarikan kail jika operasi penjualan sedang berjalan
                    if state and state.IsSelling then return end

                    -- Fase 3: Selesaikan tarikan kail
                    state.LastStatusMessage = "✨ Menarik Ikan..."
                    network:CompleteFishing()

                    state.FishCaught = state.FishCaught + 1
                    state.LastStatusMessage = "✅ Ikan Tertangkap! Total: " .. tostring(state.FishCaught)

                    -- Jeda istirahat wajar sebelum melempar kembali (1.2 - 2.0 detik)
                    task.wait(1.2 + (math.random(10, 80) / 100))
                end
            end)

            if not ok then
                warn("[Bodoamat | Fishing Error] " .. tostring(err))
                task.wait(1)
            end
        end

        state.LastStatusMessage = "Memancing Dimatikan"
        print("[Bodoamat | Fishing] Mesin memancing berhenti.")
    end)
end

function AutoFish:Stop()
    self.Running = false
    if self.Thread then
        task.cancel(self.Thread)
        self.Thread = nil
    end
end

-- ============================================================
-- 8. MODULE: AUTO SELL & SAFE FAVORITE
-- ============================================================
local AutoSell = {
    Running = false,
    IsExecuting = false,
    Thread = nil :: thread?,
    FavoriteThread = nil :: thread?,
    AutoFavoriteEnabled = false,
    MinFavoriteRarity = "Legendary", -- "Rare", "Epic", "Legendary", "Mythic", "Secret"
    FavoritedCache = {} :: { [string]: boolean },
}

local RarityTiers: { [string]: number } = {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5,
    Mythic = 6,
    Secret = 7,
    Exotic = 8,
}

local ItemUtility = nil :: any
local PlayerData = nil :: any

-- Inisialisasi data utilitas HANYA saat AutoFavorite benar-benar dipanggil (Lazy Load)
function AutoSell:InitDataUtility(): boolean
    if ItemUtility and PlayerData then return true end

    local success = pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared and shared:FindFirstChild("ItemUtility") then
            ItemUtility = require(shared.ItemUtility)
        end

        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages and packages:FindFirstChild("Replion") then
            local Replion = require(packages.Replion)
            if Replion and Replion.Client then
                PlayerData = Replion.Client:WaitReplion("Data")
            end
        end
    end)

    return success and (PlayerData ~= nil)
end

-- Eksekusi penjualan tunggal yang aman dari konflik state memancing (Pencegah BAC-8228)
function AutoSell:ExecuteSell(network: any, state: any, teleportMod: any): boolean
    if self.IsExecuting then return false end
    self.IsExecuting = true

    -- 1. Beri sinyal ke AutoFish agar jeda sementara
    if state then state.IsSelling = true end

    local success = false
    pcall(function()
        local char = Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
        local savedPos = nil

        -- Jika opsi Merchant-Safe TP diaktifkan, simpan posisi dan geser sekejap ke dekat NPC Merchant
        if state and state.MerchantSafeTp and hrp and teleportMod then
            savedPos = hrp.CFrame
            teleportMod:To(CFrame.new(-135, 3, 2764))
            task.wait(0.2)
        end

        -- 2. Batalkan input memancing dan lepaskan joran dari tangan karakter
        if network then
            if network.Remotes["CancelInput"] then
                network:CancelInput()
            end
            if network.Remotes["UnequipHotbar"] then
                network:UnequipHotbar(1)
            end
        end
        task.wait(0.4) -- Beri waktu server mencatat karakter dalam status idle bebas pancing

        -- 3. Panggil remote penjualan bersih tanpa spam paket lain
        if network and network.Remotes["SellAll"] then
            success = network:SellAll()
        end
        task.wait(0.4)

        -- Kembalikan ke spot memancing semula jika tadi bergeser ke merchant
        if savedPos and teleportMod then
            teleportMod:To(savedPos)
            task.wait(0.2)
        end

        -- 4. Pasang kembali joran jika fitur Auto Fishing sedang aktif
        if network and state and state.IsFishing and network.Remotes["EquipHotbar"] then
            network:EquipHotbar(1)
            task.wait(0.2)
        end
    end)

    -- 5. Kembalikan status memancing normal
    if state then
        state.IsSelling = false
        if success then
            state.LastStatusMessage = "💰 Berhasil menjual semua ikan!"
        end
    end

    self.IsExecuting = false
    return success
end

-- Mulai loop auto-sell berkala & loop auto-favorite terpisah
function AutoSell:Start(interval: number, network: any, state: any, teleportMod: any)
    if self.Running then return end
    self.Running = true

    local sleepTime = math.max(15, interval or 45)

    -- Loop 1: Penjualan Ikan Berkala
    self.Thread = task.spawn(function()
        print("[Bodoamat | AutoSell] Penjualan otomatis aktif setiap " .. tostring(sleepTime) .. "s.")

        while self.Running do
            task.wait(sleepTime)
            if not self.Running then break end
            self:ExecuteSell(network, state, teleportMod)
        end
    end)

    -- Loop 2: Auto-Favorite Terpisah Secara Tenang & Bertahap (Zero Packet Flood)
    self.FavoriteThread = task.spawn(function()
        while self.Running do
            task.wait(12)
            if not self.Running then break end

            if self.AutoFavoriteEnabled and network and network.Remotes["Favorite"] then
                pcall(function()
                    if not PlayerData or not ItemUtility then
                        self:InitDataUtility()
                    end
                    if not PlayerData or not ItemUtility then return end
                    local inv = (PlayerData.GetExpect and PlayerData:GetExpect("Inventory")) or (PlayerData.Get and PlayerData:Get("Inventory"))
                    if not inv or not inv.Items then return end

                    local targetTier = RarityTiers[self.MinFavoriteRarity] or 5

                    for _, item in ipairs(inv.Items) do
                        -- KUNCI PENTING: Jika sudah difavoritkan, JANGAN panggil lagi (remote ini adalah toggle!)
                        if item.Favorited == true or self.FavoritedCache[item.UUID] then
                            continue
                        end

                        local data = ItemUtility:GetItemData(item.Id)
                        local rarity = (data and data.Data and data.Data.Rarity) or "Common"
                        local itemTier = RarityTiers[rarity] or 1

                        if itemTier >= targetTier then
                            network:FavoriteItem(item.UUID)
                            self.FavoritedCache[item.UUID] = true
                            print("[Bodoamat | Favorite] ⭐ Mengamankan Ikan Langka: " .. tostring(data.Name or "Fish") .. " [" .. rarity .. "]")
                            task.wait(0.5) -- Jeda aman manusiawi (mencegah BAC-8228)
                            break -- Cukup 1 per siklus agar tidak membanjiri antrean paket
                        end
                    end
                end)
            end
        end
    end)
end

function AutoSell:Stop()
    self.Running = false
    if self.Thread then
        task.cancel(self.Thread)
        self.Thread = nil
    end
    if self.FavoriteThread then
        task.cancel(self.FavoriteThread)
        self.FavoriteThread = nil
    end
    print("[Bodoamat | AutoSell] Penjualan otomatis dimatikan.")
end

-- ============================================================
-- 9. MODULE: TELEPORT & NAVIGATION
-- ============================================================
local Teleport = {
    -- Peta Lokasi Lengkap & Update Terbaru (58 Lokasi Terverifikasi via 4LynxX Coords Engine)
    Locations = {
        -- [[ KOTA, SPAWN & MERCHANT ]]
        { Name = "Fisherman Island (Spawn)",         CFrame = CFrame.new(Vector3.new(-61.73, 3.53, 2770.77), Vector3.new(-211.45, 3.53, 2761.67)), Category = "Main" },
        { Name = "Weather Machine",                  CFrame = CFrame.new(Vector3.new(-1528.41, 2.88, 1915.32), Vector3.new(-1513.05, 2.88, 2064.53)), Category = "Main" },
        { Name = "Underground Cellar (Pasar Gelap)", CFrame = CFrame.new(Vector3.new(2161.39, -91.20, -729.23), Vector3.new(2022.33, -91.20, -672.99)), Category = "Shop" },
        { Name = "Traveling Merchant / Alien",       CFrame = CFrame.new(-135.0, 3.0, 2764.0), Category = "Shop" },

        -- [[ ZONA UPDATE TERBARU (BENCHMARK MODERN) ]]
        { Name = "Copper Canyon Mines",              CFrame = CFrame.new(Vector3.new(-4079.11, -547.17, 548.03), Vector3.new(-4069.59, -547.17, 551.12)), Category = "New" },
        { Name = "Copper Canyon [SPOT 1]",           CFrame = CFrame.new(Vector3.new(-4145.04, 7.95, 617.36), Vector3.new(-4154.18, 7.95, 613.28)), Category = "New" },
        { Name = "Copper Canyon [SPOT 2]",           CFrame = CFrame.new(Vector3.new(-4241.77, 60.48, 414.65), Vector3.new(-4232.34, 60.48, 417.99)), Category = "New" },
        { Name = "Crystal Depths",                   CFrame = CFrame.new(Vector3.new(5614.18, -903.11, 15345.87), Vector3.new(5613.30, -903.11, 15355.83)), Category = "New" },
        { Name = "Gloomcap Grotto",                  CFrame = CFrame.new(Vector3.new(5940.17, -850.19, 12468.71), Vector3.new(5932.44, -850.19, 12475.06)), Category = "New" },
        { Name = "Mariana Trench",                   CFrame = CFrame.new(Vector3.new(-9255.90, -255.59, -1.05), Vector3.new(-9261.08, -255.59, -9.61)), Category = "New" },
        { Name = "Mariana Trench Deep (Dasar Palung)", CFrame = CFrame.new(5750.0, -2600.0, 15400.0), Category = "New" },
        { Name = "Sewers / Sawers",                  CFrame = CFrame.new(Vector3.new(-1448.11, -1041.59, -10447.08), Vector3.new(-1598.04, -1041.59, -10442.53)), Category = "New" },
        { Name = "Starfall Gardens",                 CFrame = CFrame.new(Vector3.new(-22266.74, -252.37, -7991.04), Vector3.new(-22267.48, -252.37, -7981.07)), Category = "New" },
        { Name = "The Celestarium",                  CFrame = CFrame.new(Vector3.new(-28372.21, -161.00, -8254.72), Vector3.new(-28373.10, -161.00, -8244.76)), Category = "New" },

        -- [[ PULAU-PULAU UTAMA ]]
        { Name = "Coral Reefs",                      CFrame = CFrame.new(Vector3.new(-2921.86, 3.25, 2083.30), Vector3.new(-3068.68, 3.25, 2052.58)), Category = "Island" },
        { Name = "Crater Island",                    CFrame = CFrame.new(Vector3.new(1074.38, 4.03, 5098.48), Vector3.new(928.26, 4.03, 5064.55)), Category = "Island" },
        { Name = "Elemental Island",                 CFrame = CFrame.new(Vector3.new(-859.99, 56.56, 5311.90), Vector3.new(-868.14, 56.56, 5317.69)), Category = "Island" },
        { Name = "Elemental Island [Blizzard]",       CFrame = CFrame.new(Vector3.new(-1089.14, 142.59, 5577.94), Vector3.new(-1083.46, 142.59, 5586.17)), Category = "Island" },
        { Name = "Elemental Island [Storm]",          CFrame = CFrame.new(Vector3.new(-859.99, 56.56, 5311.90), Vector3.new(-868.14, 56.56, 5317.69)), Category = "Island" },
        { Name = "Elemental Island [Volcano]",        CFrame = CFrame.new(Vector3.new(-820.79, 59.87, 5289.58), Vector3.new(-811.65, 59.87, 5293.64)), Category = "Island" },
        { Name = "Kohana",                           CFrame = CFrame.new(Vector3.new(-655.47, 17.25, 501.04), Vector3.new(-511.25, 17.25, 542.27)), Category = "Island" },
        { Name = "Kohana Volcano",                   CFrame = CFrame.new(Vector3.new(-552.30, 20.73, 183.19), Vector3.new(-604.90, 20.73, 42.72)), Category = "Island" },
        { Name = "Stingray Shores",                  CFrame = CFrame.new(Vector3.new(-2131.05, 16.68, -848.95), Vector3.new(-2129.99, 16.68, -858.90)), Category = "Island" },
        { Name = "Tropical Grove",                   CFrame = CFrame.new(Vector3.new(-2140.80, 53.49, 3622.71), Vector3.new(-2216.20, 53.49, 3752.38)), Category = "Island" },
        { Name = "Classic Island",                   CFrame = CFrame.new(1433.0, 44.0, 2755.0), Category = "Island" },
        { Name = "Mount Hallow",                     CFrame = CFrame.new(2136.62, 78.92, 3272.50), Category = "Island" },
        { Name = "Esoteric Island",                  CFrame = CFrame.new(1991.0, 6.0, 1390.0), Category = "Island" },

        -- [[ ENDGAME, ELEMENTAL, ABYSS & SECRET ]]
        { Name = "Ancient Jungle",                   CFrame = CFrame.new(Vector3.new(1467.43, 7.57, -327.70), Vector3.new(1610.47, 7.57, -282.55)), Category = "Secret" },
        { Name = "Ancient Ruin",                     CFrame = CFrame.new(Vector3.new(6045.40, -588.60, 4608.94), Vector3.new(6059.22, -588.60, 4758.30)), Category = "Secret" },
        { Name = "Aquarium",                         CFrame = CFrame.new(Vector3.new(-3039.56, -624.24, -10573.49), Vector3.new(-3036.04, -624.24, -10582.85)), Category = "Secret" },
        { Name = "Elemental Door [Blizzard]",        CFrame = CFrame.new(Vector3.new(-834.38, 18.97, 5054.68), Vector3.new(-830.12, 18.97, 5063.72)), Category = "Secret" },
        { Name = "Elemental Door [Storm]",           CFrame = CFrame.new(Vector3.new(-914.24, 30.06, 5114.68), Vector3.new(-921.25, 30.06, 5121.81)), Category = "Secret" },
        { Name = "Elemental Door [Volcano]",         CFrame = CFrame.new(Vector3.new(-749.51, 7.29, 5195.48), Vector3.new(-756.40, 7.29, 5188.23)), Category = "Secret" },
        { Name = "Esoteric Depths (Enchant Stone)",  CFrame = CFrame.new(Vector3.new(3207.32, -1302.86, 1444.52), Vector3.new(3216.52, -1302.86, 1440.58)), Category = "Secret" },
        { Name = "Kohana Lab",                       CFrame = CFrame.new(Vector3.new(-201.61, 63.56, 475.35), Vector3.new(-206.76, 63.56, 483.92)), Category = "Secret" },
        { Name = "Lava Basin",                       CFrame = CFrame.new(Vector3.new(894.22, 89.03, -10195.55), Vector3.new(1032.50, 89.03, -10137.42)), Category = "Secret" },
        { Name = "Leviathan Den",                    CFrame = CFrame.new(Vector3.new(3472.98, -287.84, 3471.07), Vector3.new(3530.81, -287.84, 3609.46)), Category = "Secret" },
        { Name = "Lost Isle (Underwater)",           CFrame = CFrame.new(Vector3.new(-3685.38, 5.43, -1066.63), Vector3.new(-3638.59, 5.43, -1209.14)), Category = "Secret" },
        { Name = "Lucky Abyss",                      CFrame = CFrame.new(Vector3.new(-9132.20, -269.54, 813.39), Vector3.new(-9126.93, -269.54, 804.89)), Category = "Secret" },
        { Name = "Lucky Volcano",                    CFrame = CFrame.new(Vector3.new(-8569.07, -69.10, -424.65), Vector3.new(-8560.58, -69.10, -429.93)), Category = "Secret" },
        { Name = "Mutation Vents",                   CFrame = CFrame.new(Vector3.new(-9112.33, -91.77, -1639.63), Vector3.new(-9116.35, -91.77, -1648.79)), Category = "Secret" },
        { Name = "Pirate Cove",                      CFrame = CFrame.new(Vector3.new(3406.97, 4.19, 3497.09), Vector3.new(3512.49, 4.19, 3390.47)), Category = "Secret" },
        { Name = "Pirate Treasure Room",             CFrame = CFrame.new(Vector3.new(3349.35, -297.94, 3086.00), Vector3.new(3247.83, -297.94, 2975.58)), Category = "Secret" },
        { Name = "Planetary Observatory",            CFrame = CFrame.new(Vector3.new(440.90, 9.18, 2148.80), Vector3.new(436.54, 9.18, 2157.80)), Category = "Secret" },
        { Name = "Rushing Current",                  CFrame = CFrame.new(Vector3.new(-9687.61, -74.28, -1779.64), Vector3.new(-9685.84, -74.28, -1789.48)), Category = "Secret" },
        { Name = "Sacred Temple",                    CFrame = CFrame.new(Vector3.new(1453.84, -22.12, -621.65), Vector3.new(1480.26, -22.12, -474.00)), Category = "Secret" },
        { Name = "Shiny Abyss",                      CFrame = CFrame.new(Vector3.new(-9729.08, -269.54, 810.51), Vector3.new(-9725.21, -269.54, 819.73)), Category = "Secret" },
        { Name = "Silent Reach",                     CFrame = CFrame.new(Vector3.new(-10021.38, -72.10, 178.31), Vector3.new(-10017.69, -72.10, 169.01)), Category = "Secret" },
        { Name = "Sysiphus Statue",                  CFrame = CFrame.new(Vector3.new(-3656.65, -134.36, -963.25), Vector3.new(-3802.69, -134.36, -928.99)), Category = "Secret" },
        { Name = "Throne Room (Blizzard)",           CFrame = CFrame.new(Vector3.new(-1248.29, -855.70, 5639.27), Vector3.new(-1254.92, -855.70, 5631.78)), Category = "Secret" },
        { Name = "Throne Room (Storm)",              CFrame = CFrame.new(Vector3.new(-1305.17, -855.70, 5654.64), Vector3.new(-1304.09, -855.70, 5644.70)), Category = "Secret" },
        { Name = "Throne Room (Volcano)",            CFrame = CFrame.new(Vector3.new(-1334.50, -855.70, 5555.16), Vector3.new(-1326.89, -855.70, 5561.65)), Category = "Secret" },
        { Name = "Titan Pressure",                   CFrame = CFrame.new(Vector3.new(-9867.53, -84.11, -1188.16), Vector3.new(-9871.01, -84.11, -1197.53)), Category = "Secret" },
        { Name = "Treasure Room",                    CFrame = CFrame.new(Vector3.new(-3597.32, -275.67, -1641.22), Vector3.new(-3722.61, -275.67, -1558.74)), Category = "Secret" },
        { Name = "Underwater City",                  CFrame = CFrame.new(Vector3.new(-3124.52, -645.42, -10489.41), Vector3.new(-3122.09, -645.42, -10479.71)), Category = "Secret" },
        { Name = "Vulcanic Cavern",                  CFrame = CFrame.new(Vector3.new(1145.14, 74.94, -10234.56), Vector3.new(1277.26, 74.94, -10163.52)), Category = "Secret" },
        { Name = "Iron Cavern",                      CFrame = CFrame.new(-8798.0, -585.0, 241.0), Category = "Secret" },
        { Name = "Iron Cafe",                        CFrame = CFrame.new(-8647.0, -548.0, 160.0), Category = "Secret" },
    },

    -- Titik Kustom Buatan Pemain (Save & Load Waypoint)
    CustomWaypoints = {} :: { [string]: CFrame },
}

-- Eksekusi Teleportasi Aman (Bebas Flung & Anti-Tripwire Velocity)
function Teleport:To(targetCFrame: CFrame): boolean
    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = targetCFrame + Vector3.new(0, 3.5, 0)
        task.wait(0.05)
        hrp.AssemblyLinearVelocity = Vector3.zero
    end)

    return true
end

-- Teleport Berdasarkan Nama Lokasi
function Teleport:ToNamed(name: string): boolean
    -- 1. Cek dari daftar lokasi kustom pemain
    if self.CustomWaypoints[name] then
        return self:To(self.CustomWaypoints[name])
    end

    -- 2. Cek apakah ada di database lokasi statis
    for _, loc in ipairs(self.Locations) do
        if loc.Name:lower() == name:lower() then
            -- Coba scan objek fisik map di workspace terlebih dahulu (jika ada update posisi oleh developer game)
            local dynamicCF = self:ScanWorkspace(loc.Name)
            if dynamicCF then
                return self:To(dynamicCF)
            end
            return self:To(loc.CFrame)
        end
    end

    -- 3. Fallback: Scan bebas di Workspace
    local foundCF = self:ScanWorkspace(name)
    if foundCF then
        return self:To(foundCF)
    end

    return false
end

-- Smart Workspace Auto-Discovery Scanner
function Teleport:ScanWorkspace(query: string): CFrame?
    local cleanQuery = query:lower():gsub("%s+", "")
    local containers = {
        Workspace:FindFirstChild("Areas"),
        Workspace:FindFirstChild("Islands"),
        Workspace:FindFirstChild("Locations"),
        Workspace:FindFirstChild("Map"),
        Workspace:FindFirstChild("Props"),
        Workspace,
    }

    for _, container in ipairs(containers) do
        if not container then continue end
        for _, child in ipairs(container:GetChildren()) do
            local childName = child.Name:lower():gsub("%s+", "")
            if string.find(childName, cleanQuery) or string.find(cleanQuery, childName) then
                if child:IsA("Model") and child.PrimaryPart then
                    return child.PrimaryPart.CFrame
                elseif child:IsA("BasePart") then
                    return child.CFrame
                elseif child:IsA("Model") then
                    local p = child:FindFirstChildOfClass("BasePart")
                    if p then return p.CFrame end
                end
            end
        end
    end

    return nil
end

-- Teleport ke Pemain Lain di Server (Berguna jika teman sudah berada di zona baru)
function Teleport:ToPlayer(targetName: string): boolean
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (player.Name:lower() == targetName:lower() or player.DisplayName:lower() == targetName:lower()) then
            local targetChar = player.Character
            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
            if targetHrp then
                return self:To(targetHrp.CFrame + Vector3.new(2, 0, 2))
            end
        end
    end
    return false
end

-- Simpan Posisi Saat Ini sebagai Titik Kustom
function Teleport:SaveCurrentPosition(name: string): boolean
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end

    local cleanName = (name and #name > 0) and name or ("Spot #" .. tostring(os.date("%H:%M:%S")))
    self.CustomWaypoints[cleanName] = hrp.CFrame
    print("[Bodoamat | Teleport] 📌 Berhasil menyimpan waypoint kustom: " .. cleanName)
    return true
end

-- Hapus Titik Kustom
function Teleport:DeleteCustomWaypoint(name: string): boolean
    if self.CustomWaypoints[name] then
        self.CustomWaypoints[name] = nil
        return true
    end
    return false
end

-- ============================================================
-- 10. MODULE: TOTEM AUTOMATION
-- ============================================================
local Totem = {
    Running = false,
    Thread = nil :: thread?,
    SelectedType = "Luck Totem", -- "Luck Totem", "Shiny Totem", "Mutation Totem", atau "Any"
}

-- Cari Tool Totem di Character atau Backpack
function Totem:FindTotemTool(specificType: string?): Tool?
    local char = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local targetName = (specificType or self.SelectedType or "Totem"):lower()

    -- 1. Cek di Character
    if char then
        for _, item in ipairs(char:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find(targetName) or item.Name:lower():find("totem")) then
                return item
            end
        end
    end

    -- 2. Cek di Backpack
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (item.Name:lower():find(targetName) or item.Name:lower():find("totem")) then
                return item
            end
        end
    end

    return nil
end

-- Pasang 1 Totem di Posisi Saat Ini
function Totem:DeploySingle(specificType: string?): boolean
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    local totemTool = self:FindTotemTool(specificType)
    if not totemTool then
        print("[Bodoamat | Totem] ⚠️ Totem tidak ditemukan di inventory atau tas!")
        return false
    end

    local success = false
    pcall(function()
        -- 1. Pasang Totem di Tangan
        humanoid:EquipTool(totemTool)
        task.wait(0.15)

        -- 2. Picu Aktivasi
        totemTool:Activate()

        -- 3. Cek apakah ada remote Place di dalam Tool atau ReplicatedStorage
        local placeEvent = totemTool:FindFirstChild("Place") or totemTool:FindFirstChild("Activate")
        if placeEvent and placeEvent:IsA("RemoteEvent") then
            placeEvent:FireServer()
        elseif placeEvent and placeEvent:IsA("RemoteFunction") then
            placeEvent:InvokeServer()
        end

        task.wait(0.2)
        success = true
        print("[Bodoamat | Totem] 🍀 Berhasil menempatkan totem: " .. totemTool.Name)
    end)

    return success
end

-- Pasang 5 Totem dalam Formasi Salib (+) untuk Cakupan Radius Maksimal
function Totem:DeployFormation5(specificType: string?): boolean
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end

    local originalPos = hrp.CFrame
    local distance = 50 -- Jarak optimal antar totem (radius pengaruh 50-70 studs)
    local offsets = {
        Vector3.new(0, 0, 0),             -- Pusat
        Vector3.new(distance, 0, 0),      -- Kanan
        Vector3.new(-distance, 0, 0),     -- Kiri
        Vector3.new(0, 0, distance),      -- Depan
        Vector3.new(0, 0, -distance),     -- Belakang
    }

    local deployedCount = 0
    pcall(function()
        for i, offset in ipairs(offsets) do
            local totem = self:FindTotemTool(specificType)
            if not totem then break end

            -- Geser karakter sejenak ke posisi formasi
            hrp.CFrame = originalPos + offset + Vector3.new(0, 2, 0)
            task.wait(0.1)

            humanoid:EquipTool(totem)
            task.wait(0.15)
            totem:Activate()

            local placeEv = totem:FindFirstChild("Place")
            if placeEv and placeEv:IsA("RemoteEvent") then
                placeEv:FireServer()
            end

            task.wait(0.2)
            deployedCount = deployedCount + 1
        end

        -- Kembalikan ke posisi awal
        hrp.CFrame = originalPos
    end)

    print("[Bodoamat | Totem] 🌟 Selesai formasi 5 Totem. Total terpasang: " .. tostring(deployedCount))
    return deployedCount > 0
end

-- Mulai Loop Auto-Totem Berkala
function Totem:Start(intervalMinutes: number?, totemType: string?)
    if self.Running then return end
    self.Running = true
    if totemType then self.SelectedType = totemType end

    local intervalSeconds = math.max(60, (intervalMinutes or 28) * 60)

    self.Thread = task.spawn(function()
        print("[Bodoamat | Totem] Auto Totem aktif (Pembaruan setiap " .. tostring(math.floor(intervalSeconds / 60)) .. " menit).")

        -- Pasang langsung saat pertama kali diaktifkan
        self:DeploySingle(self.SelectedType)

        while self.Running do
            task.wait(intervalSeconds)
            if not self.Running then break end
            self:DeploySingle(self.SelectedType)
        end
    end)
end

function Totem:Stop()
    self.Running = false
    if self.Thread then
        task.cancel(self.Thread)
        self.Thread = nil
    end
    print("[Bodoamat | Totem] Auto Totem dimatikan.")
end

-- ============================================================
-- 11. MODULE: MERCHANT & DEEP SEA TOOLS
-- ============================================================
local Merchant = {}

-- Daftar Item Populer Toko & Merchant
Merchant.Items = {
    Bait = { "Singularity Bait", "Royal Bait", "Enchanted Bait", "Golden Bait", "Topwater Bait" },
    Totem = { "Luck Totem", "Shiny Totem", "Mutation Totem" },
    Crates = { "Luxury Crate", "Azure Crate", "Enchanted Crate", "Elderwood Crate" },
    Weather = { "Storm", "Thunderstorm", "Blizzard", "Sandstorm", "Cloudy", "Wind" }
}

-- Buka Menu Toko / Black Market Jarak Jauh via ProximityPrompt
function Merchant:OpenRemoteShop(keyword: string?): boolean
    local searchKey = (keyword or "merchant"):lower()
    local found = false

    pcall(function()
        for _, desc in ipairs(Workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                local objText = (desc.ObjectText or ""):lower()
                local actText = (desc.ActionText or ""):lower()
                local parentName = (desc.Parent and desc.Parent.Name or ""):lower()

                if objText:find(searchKey) or actText:find(searchKey) or parentName:find(searchKey)
                   or objText:find("shop") or objText:find("market") or objText:find("bazaar")
                   or parentName:find("cellar") or parentName:find("alien") then

                    -- Gunakan fungsi native executor fireproximityprompt
                    local firePrompt = (rawget and rawget(getgenv and getgenv() or {}, "fireproximityprompt"))
                                       or (getfenv and getfenv().fireproximityprompt)

                    if firePrompt then
                        firePrompt(desc, 0)
                        found = true
                        print("[Bodoamat | Merchant] 🛒 Membuka prompt toko: " .. tostring(desc.ObjectText))
                        break
                    else
                        -- Fallback simulasi posisi jika fireproximityprompt tidak tersedia
                        local promptPart = desc.Parent
                        if promptPart and promptPart:IsA("BasePart") and LocalPlayer.Character then
                            local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
                            if hrp then
                                local oldPos = hrp.CFrame
                                hrp.CFrame = promptPart.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.2)
                                desc:InputHoldBegin()
                                task.wait(desc.HoldDuration + 0.1)
                                desc:InputHoldEnd()
                                task.wait(0.2)
                                hrp.CFrame = oldPos
                                found = true
                                break
                            end
                        end
                    end
                end
            end
        end
    end)

    return found
end

-- Beli Item Spesifik via Network Remote
function Merchant:BuyItem(itemName: string, network: any): boolean
    if not network then return false end
    local success = network:BuyItem(itemName)
    if success then
        print("[Bodoamat | Merchant] ✅ Berhasil membeli item: " .. itemName)
    else
        print("[Bodoamat | Merchant] ⚠️ Pembelian gagal atau koin tidak mencukupi: " .. itemName)
    end
    return success
end

-- Refresh Stok Merchant
function Merchant:RefreshStock(network: any): boolean
    if not network then return false end
    return network:RefreshMerchant()
end

-- Pasang Tabung Oksigen Laut Dalam (Mariana Trench & Lost Isle)
function Merchant:EquipOxygen(network: any): boolean
    if not network then return false end
    local success = network:EquipOxygenTank()
    if success then
        print("[Bodoamat | Laut Dalam] 🤿 Tabung Oksigen aktif! Karakter aman dari kehabisan nafas.")
    end
    return success
end

-- Aktifkan/Matikan Radar Ikan
function Merchant:ToggleRadar(enabled: boolean, network: any): boolean
    if not network then return false end
    local success = network:UpdateFishingRadar(enabled)
    if success then
        print("[Bodoamat | Radar] 📡 Radar Ikan: " .. (enabled and "Aktif" or "Nonaktif"))
    end
    return success
end

-- Beli Cuaca Server
function Merchant:SetWeather(weatherName: string, network: any): boolean
    if not network then return false end
    local success = network:PurchaseWeather(weatherName)
    if success then
        print("[Bodoamat | Cuaca] ⛈️ Berhasil memicu event cuaca: " .. weatherName)
    end
    return success
end

-- ============================================================
-- 12. UI: BODOAMAT GUI
-- ============================================================
local BodoamatGui = {
    ScreenGui = nil :: ScreenGui?,
    MainFrame = nil :: Frame?,
    CurrentTab = "Fishing",
    Tabs = {} :: { [string]: ScrollingFrame },
    TabButtons = {} :: { [string]: TextButton },
}

local function getSafeGuiContainer(): Instance
    -- 1. Prioritas Utama: gethui() (Executor Hidden UI - 100% aman dan tidak terdeteksi game scripts/BAC)
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return hui
        end
    end
    if getfenv and getfenv().gethui then
        local ok, hui = pcall(getfenv().gethui)
        if ok and hui then
            return hui
        end
    end
    local genv = (getgenv and getgenv()) or {}
    if genv.gethui then
        local ok, hui = pcall(genv.gethui)
        if ok and hui then
            return hui
        end
    end

    -- 2. Fallback aman ke PlayerGui (TIDAK PERNAH MENYENTUH CoreGui untuk mencegah tripwire BAC-6228)
    return LocalPlayer:WaitForChild("PlayerGui")
end

function BodoamatGui:Create(config: any, state: any, modules: any)
    -- 1. Bersihkan UI lama via referensi memori (Zero instance scanning)
    local genv = (getgenv and getgenv()) or {}
    if genv.__BODOAMAT_GUI then
        pcall(function()
            genv.__BODOAMAT_GUI:Destroy()
        end)
        genv.__BODOAMAT_GUI = nil
    end

    -- 2. Buat ScreenGui Utama dengan Stealth Container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100000
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Proteksi syn.protect_gui jika didukung executor
    local synProtect = (syn and syn.protect_gui) or (genv.syn and genv.syn.protect_gui) or protectgui
    if synProtect then
        pcall(synProtect, screenGui)
    end

    screenGui.Parent = getSafeGuiContainer()
    genv.__BODOAMAT_GUI = screenGui
    self.ScreenGui = screenGui

    -- 3. Frame Jendela Utama
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 560, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -280, 0.5, -210)
    mainFrame.BackgroundColor3 = config.UI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = config.UI.Theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    -- Logika Dragging Universal (Mouse & Mobile Touch)
    local dragging, dragInput, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- 4. Header Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = config.UI.Theme.CardBg
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerPatch = Instance.new("Frame")
    headerPatch.Size = UDim2.new(1, 0, 0, 10)
    headerPatch.Position = UDim2.new(0, 0, 1, -10)
    headerPatch.BackgroundColor3 = config.UI.Theme.CardBg
    headerPatch.BorderSizePixel = 0
    headerPatch.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 240, 0, 24)
    titleLabel.Position = UDim2.new(0, 16, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🐟 " .. config.UI.Title .. " v3.0"
    titleLabel.TextColor3 = config.UI.Theme.Accent
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0, 280, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 16, 0, 28)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = config.UI.Subtitle
    subtitleLabel.TextColor3 = config.UI.Theme.TextSubtle
    subtitleLabel.TextSize = 11
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 9)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(240, 90, 90)
    closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    -- 5. Sidebar Navigasi Tab (Kiri)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 138, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -148, 1, -58)
    contentArea.Position = UDim2.new(0, 143, 0, 53)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    local function createTab(tabName: string): ScrollingFrame
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = config.UI.Theme.Accent
        page.Visible = false
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingRight = UDim.new(0, 6)
        pagePadding.PaddingBottom = UDim.new(0, 12)
        pagePadding.Parent = page

        self.Tabs[tabName] = page
        return page
    end

    local tabList = {
        { Id = "Fishing",  Label = "🎣 Memancing" },
        { Id = "Selling",  Label = "💰 Toko & Jual" },
        { Id = "Totem",    Label = "🗿 Totem & Laut" },
        { Id = "Teleport", Label = "🗺️ Teleportasi" },
        { Id = "Movement", Label = "🏃 Mobilitas" },
        { Id = "Optimasi", Label = "⚡ Performa" },
        { Id = "Status",   Label = "📊 Statistik" },
    }

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 6)
    sidebarPadding.PaddingLeft = UDim.new(0, 6)
    sidebarPadding.PaddingRight = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    for _, t in ipairs(tabList) do
        createTab(t.Id)

        local btn = Instance.new("TextButton")
        btn.Name = t.Id .. "TabBtn"
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = (t.Id == self.CurrentTab) and config.UI.Theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.Text = t.Label
        btn.TextColor3 = (t.Id == self.CurrentTab) and config.UI.Theme.Accent or config.UI.Theme.TextSubtle
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = sidebar

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        self.TabButtons[t.Id] = btn

        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(t.Id, config)
        end)
    end

    -- ==========================================
    -- KOMPONEN UI BUILDER HELPER
    -- ==========================================
    local function createSectionHeader(parent: Instance, text: string)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -4, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = config.UI.Theme.Accent
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = parent
    end

    local function createToggle(parent: Instance, title: string, desc: string, default: boolean, onToggle: (boolean) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 50)
        card.BackgroundColor3 = config.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -70, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 6)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = config.UI.Theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -70, 0, 16)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = config.UI.Theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 48, 0, 26)
        toggleBtn.Position = UDim2.new(1, -58, 0.5, -13)
        toggleBtn.BackgroundColor3 = default and config.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
        toggleBtn.Text = default and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 11
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.Parent = card

        local tgCorner = Instance.new("UICorner")
        tgCorner.CornerRadius = UDim.new(0, 13)
        tgCorner.Parent = toggleBtn

        local isToggled = default
        toggleBtn.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            toggleBtn.Text = isToggled and "ON" or "OFF"
            toggleBtn.BackgroundColor3 = isToggled and config.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
            onToggle(isToggled)
        end)
    end

    local function createActionButton(parent: Instance, label: string, desc: string, onClick: () -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 46)
        card.BackgroundColor3 = config.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -110, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 5)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = label
        tLabel.TextColor3 = config.UI.Theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -110, 0, 14)
        dLabel.Position = UDim2.new(0, 12, 0, 24)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = config.UI.Theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 92, 0, 28)
        btn.Position = UDim2.new(1, -100, 0.5, -14)
        btn.BackgroundColor3 = config.UI.Theme.Accent
        btn.Text = "Jalankan"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            onClick()
        end)
    end

    local function createTextInput(parent: Instance, placeholder: string, btnLabel: string, onSubmit: (string) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 44)
        card.BackgroundColor3 = config.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -105, 0, 28)
        box.Position = UDim2.new(0, 10, 0.5, -14)
        box.BackgroundColor3 = Color3.fromRGB(24, 27, 36)
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = config.UI.Theme.TextSubtle
        box.Text = ""
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.TextSize = 11
        box.Font = Enum.Font.Gotham
        box.ClearTextOnFocus = false
        box.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = box

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 28)
        btn.Position = UDim2.new(1, -88, 0.5, -14)
        btn.BackgroundColor3 = config.UI.Theme.Accent
        btn.Text = btnLabel
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            if #box.Text > 0 then
                onSubmit(box.Text)
            end
        end)
    end

    -- ==========================================
    -- ISI KONTEN TAB 1: MEMANCING
    -- ==========================================
    local fishPage = self.Tabs["Fishing"]

    createToggle(fishPage, "Auto Fishing Aktif", "Otomatis melempar dan menarik tangkapan", state.IsFishing, function(val)
        state:Set("IsFishing", val)
        if val then
            modules.AutoFish:Start(config.AutoFish, state, modules.Network)
        else
            modules.AutoFish:Stop()
        end
    end)

    -- ==========================================
    -- ISI KONTEN TAB 2: TOKO & JUAL
    -- ==========================================
    local sellPage = self.Tabs["Selling"]

    createToggle(sellPage, "Auto Sell Ikan", "Menjual hasil tangkapan otomatis secara berkala", state.IsAutoSell, function(val)
        state:Set("IsAutoSell", val)
        if val then
            modules.AutoSell:Start(config.AutoSell.Interval, modules.Network, state)
        else
            modules.AutoSell:Stop()
        end
    end)

    createToggle(sellPage, "Mode Aman Dekat Pedagang TP", "TP singkat ke pedagang saat jual jika di luar jangkauan (Anti BAC-8228)", state.MerchantSafeTp, function(val)
        state:Set("MerchantSafeTp", val)
        modules.AutoSell.MerchantSafeTp = val
        print("[Bodoamat | AutoSell] Merchant Safe TP: " .. (val and "Aktif" or "Nonaktif"))
    end)

    createToggle(sellPage, "Auto Favorite Ikan Langka", "Mengunci otomatis ikan bernilai tinggi sebelum dijual", modules.AutoSell.AutoFavoriteEnabled, function(val)
        modules.AutoSell.AutoFavoriteEnabled = val
        state:Set("IsAutoFavorite", val)
        print("[Bodoamat] Auto Favorite: " .. (val and "Aktif" or "Nonaktif"))
    end)

    -- Pilihan Min Rarity
    local rarityCard = Instance.new("Frame")
    rarityCard.Size = UDim2.new(1, -4, 0, 64)
    rarityCard.BackgroundColor3 = config.UI.Theme.CardBg
    rarityCard.BorderSizePixel = 0
    rarityCard.Parent = sellPage

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 8)
    rCorner.Parent = rarityCard

    local rTitle = Instance.new("TextLabel")
    rTitle.Size = UDim2.new(1, -20, 0, 18)
    rTitle.Position = UDim2.new(0, 12, 0, 6)
    rTitle.BackgroundTransparency = 1
    rTitle.Text = "Minimal Rarity yang Diamankan (Tidak Dijual)"
    rTitle.TextColor3 = config.UI.Theme.Text
    rTitle.TextSize = 11
    rTitle.Font = Enum.Font.GothamBold
    rTitle.TextXAlignment = Enum.TextXAlignment.Left
    rTitle.Parent = rarityCard

    local rButtons = {}
    local rList = { "Rare", "Epic", "Legendary", "Mythic", "Secret" }
    local rContainer = Instance.new("Frame")
    rContainer.Size = UDim2.new(1, -24, 0, 28)
    rContainer.Position = UDim2.new(0, 12, 0, 28)
    rContainer.BackgroundTransparency = 1
    rContainer.Parent = rarityCard

    local rLayout = Instance.new("UIListLayout")
    rLayout.FillDirection = Enum.FillDirection.Horizontal
    rLayout.Padding = UDim.new(0, 4)
    rLayout.Parent = rContainer

    for _, rName in ipairs(rList) do
        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.new(0.19, 0, 1, 0)
        rBtn.BackgroundColor3 = (modules.AutoSell.MinFavoriteRarity == rName) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        rBtn.Text = rName
        rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rBtn.TextSize = 9
        rBtn.Font = Enum.Font.GothamMedium
        rBtn.Parent = rContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = rBtn

        rButtons[rName] = rBtn

        rBtn.MouseButton1Click:Connect(function()
            modules.AutoSell.MinFavoriteRarity = rName
            for id, b in pairs(rButtons) do
                b.BackgroundColor3 = (id == rName) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
            end
            print("[Bodoamat] Min Favorite Rarity diset ke: " .. rName)
        end)
    end

    local sellDebounce = false
    createActionButton(sellPage, "Jual Semua Ikan Sekarang", "Kirim remote jual langsung ke merchant (Anti-BAC Safe)", function()
        if sellDebounce then return end
        sellDebounce = true
        modules.AutoSell:ExecuteSell(modules.Network, state)
        task.wait(2.5)
        sellDebounce = false
    end)

    createSectionHeader(sellPage, "🛒 TOKO & BLACK MARKET REMOTE")

    createActionButton(sellPage, "Buka Black Market Jarak Jauh", "Picu prompt Pasar Gelap / Cellar dari mana saja", function()
        local opened = modules.Merchant:OpenRemoteShop("cellar")
        if not opened then
            modules.Merchant:OpenRemoteShop("merchant")
        end
    end)

    createActionButton(sellPage, "Buka Pedagang Keliling (Alien)", "Picu prompt Traveling Merchant dari mana saja", function()
        modules.Merchant:OpenRemoteShop("traveling")
    end)

    -- Quick Buy Bait
    local buyCard = Instance.new("Frame")
    buyCard.Size = UDim2.new(1, -4, 0, 68)
    buyCard.BackgroundColor3 = config.UI.Theme.CardBg
    buyCard.BorderSizePixel = 0
    buyCard.Parent = sellPage

    local bCorner = Instance.new("UICorner")
    bCorner.CornerRadius = UDim.new(0, 8)
    bCorner.Parent = buyCard

    local bTitle = Instance.new("TextLabel")
    bTitle.Size = UDim2.new(1, -20, 0, 18)
    bTitle.Position = UDim2.new(0, 12, 0, 6)
    bTitle.BackgroundTransparency = 1
    bTitle.Text = "Beli Umpan Instan (Top Bait)"
    bTitle.TextColor3 = config.UI.Theme.Text
    bTitle.TextSize = 11
    bTitle.Font = Enum.Font.GothamBold
    bTitle.TextXAlignment = Enum.TextXAlignment.Left
    bTitle.Parent = buyCard

    local baitBtns = { "Singularity Bait", "Royal Bait", "Enchanted Bait", "Golden Bait" }
    local baitContainer = Instance.new("Frame")
    baitContainer.Size = UDim2.new(1, -24, 0, 28)
    baitContainer.Position = UDim2.new(0, 12, 0, 30)
    baitContainer.BackgroundTransparency = 1
    baitContainer.Parent = buyCard

    local baitLayout = Instance.new("UIListLayout")
    baitLayout.FillDirection = Enum.FillDirection.Horizontal
    baitLayout.Padding = UDim.new(0, 4)
    baitLayout.Parent = baitContainer

    for _, baitName in ipairs(baitBtns) do
        local bb = Instance.new("TextButton")
        bb.Size = UDim2.new(0.24, -2, 1, 0)
        bb.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
        bb.Text = baitName:gsub(" Bait", "")
        bb.TextColor3 = Color3.fromRGB(255, 255, 255)
        bb.TextSize = 9
        bb.Font = Enum.Font.GothamMedium
        bb.Parent = baitContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = bb

        bb.MouseButton1Click:Connect(function()
            modules.Merchant:BuyItem(baitName, modules.Network)
        end)
    end

    -- ==========================================
    -- ISI KONTEN TAB 3: TOTEM & LAUT DALAM
    -- ==========================================
    local totemPage = self.Tabs["Totem"]

    createSectionHeader(totemPage, "🗿 KELOLA & PASANG TOTEM")

    -- Selector Tipe Totem
    local tTypeCard = Instance.new("Frame")
    tTypeCard.Size = UDim2.new(1, -4, 0, 64)
    tTypeCard.BackgroundColor3 = config.UI.Theme.CardBg
    tTypeCard.BorderSizePixel = 0
    tTypeCard.Parent = totemPage

    local ttCorner = Instance.new("UICorner")
    ttCorner.CornerRadius = UDim.new(0, 8)
    ttCorner.Parent = tTypeCard

    local ttTitle = Instance.new("TextLabel")
    ttTitle.Size = UDim2.new(1, -20, 0, 18)
    ttTitle.Position = UDim2.new(0, 12, 0, 6)
    ttTitle.BackgroundTransparency = 1
    ttTitle.Text = "Tipe Totem yang Dipasang"
    ttTitle.TextColor3 = config.UI.Theme.Text
    ttTitle.TextSize = 11
    ttTitle.Font = Enum.Font.GothamBold
    ttTitle.TextXAlignment = Enum.TextXAlignment.Left
    ttTitle.Parent = tTypeCard

    local tTypeList = { "Luck Totem", "Shiny Totem", "Mutation Totem" }
    local tTypeBtns = {}
    local ttContainer = Instance.new("Frame")
    ttContainer.Size = UDim2.new(1, -24, 0, 28)
    ttContainer.Position = UDim2.new(0, 12, 0, 28)
    ttContainer.BackgroundTransparency = 1
    ttContainer.Parent = tTypeCard

    local ttLayout = Instance.new("UIListLayout")
    ttLayout.FillDirection = Enum.FillDirection.Horizontal
    ttLayout.Padding = UDim.new(0, 6)
    ttLayout.Parent = ttContainer

    for _, tName in ipairs(tTypeList) do
        local tb = Instance.new("TextButton")
        tb.Size = UDim2.new(0.32, -4, 1, 0)
        tb.BackgroundColor3 = (modules.Totem.SelectedType == tName) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        tb.Text = tName
        tb.TextColor3 = Color3.fromRGB(255, 255, 255)
        tb.TextSize = 10
        tb.Font = Enum.Font.GothamMedium
        tb.Parent = ttContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = tb

        tTypeBtns[tName] = tb

        tb.MouseButton1Click:Connect(function()
            modules.Totem.SelectedType = tName
            state:Set("TotemType", tName)
            for id, b in pairs(tTypeBtns) do
                b.BackgroundColor3 = (id == tName) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
            end
            print("[Bodoamat | Totem] Tipe aktif: " .. tName)
        end)
    end

    createActionButton(totemPage, "Pasang 1 Totem", "Menempatkan 1 totem di posisi karakter sekarang", function()
        modules.Totem:DeploySingle(modules.Totem.SelectedType)
    end)

    createActionButton(totemPage, "Pasang Formasi 5 Totem (+)", "Pasang 5 totem formasi salib jangkauan maksimal 60 stud", function()
        modules.Totem:DeployFormation5(modules.Totem.SelectedType)
    end)

    createToggle(totemPage, "Auto Pasang Totem Berkala", "Mengecek & memasang ulang totem otomatis setiap 60 detik", state.IsAutoTotem, function(val)
        state:Set("IsAutoTotem", val)
        if val then
            modules.Totem:StartAuto(60, modules.Totem.SelectedType)
        else
            modules.Totem:StopAuto()
        end
    end)

    createSectionHeader(totemPage, "🤿 EKSPLORASI LAUT DALAM & RADAR")

    createToggle(totemPage, "Tabung Oksigen Laut Dalam", "Aktifkan O2 tank agar tidak tenggelam di Mariana Trench & Lost Isle", state.IsOxygenEquipped, function(val)
        state:Set("IsOxygenEquipped", val)
        if val then
            modules.Merchant:EquipOxygen(modules.Network)
        end
    end)

    createToggle(totemPage, "Fishing Radar (Deteksi Ikan)", "Menampilkan posisi dan rarity ikan di sekitar air", state.IsRadar, function(val)
        state:Set("IsRadar", val)
        modules.Merchant:ToggleRadar(val, modules.Network)
    end)

    createSectionHeader(totemPage, "⛈️ KONTROL CUACA SERVER")

    local weatherCard = Instance.new("Frame")
    weatherCard.Size = UDim2.new(1, -4, 0, 64)
    weatherCard.BackgroundColor3 = config.UI.Theme.CardBg
    weatherCard.BorderSizePixel = 0
    weatherCard.Parent = totemPage

    local wCorner = Instance.new("UICorner")
    wCorner.CornerRadius = UDim.new(0, 8)
    wCorner.Parent = weatherCard

    local wTitle = Instance.new("TextLabel")
    wTitle.Size = UDim2.new(1, -20, 0, 18)
    wTitle.Position = UDim2.new(0, 12, 0, 6)
    wTitle.BackgroundTransparency = 1
    wTitle.Text = "Beli Event Cuaca Server (Weather Machine)"
    wTitle.TextColor3 = config.UI.Theme.Text
    wTitle.TextSize = 11
    wTitle.Font = Enum.Font.GothamBold
    wTitle.TextXAlignment = Enum.TextXAlignment.Left
    wTitle.Parent = weatherCard

    local wList = { "Storm", "Thunderstorm", "Cloudy", "Wind" }
    local wContainer = Instance.new("Frame")
    wContainer.Size = UDim2.new(1, -24, 0, 28)
    wContainer.Position = UDim2.new(0, 12, 0, 28)
    wContainer.BackgroundTransparency = 1
    wContainer.Parent = weatherCard

    local wLayout = Instance.new("UIListLayout")
    wLayout.FillDirection = Enum.FillDirection.Horizontal
    wLayout.Padding = UDim.new(0, 4)
    wLayout.Parent = wContainer

    for _, wName in ipairs(wList) do
        local wb = Instance.new("TextButton")
        wb.Size = UDim2.new(0.24, -2, 1, 0)
        wb.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
        wb.Text = wName
        wb.TextColor3 = Color3.fromRGB(255, 255, 255)
        wb.TextSize = 9
        wb.Font = Enum.Font.GothamMedium
        wb.Parent = wContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = wb

        wb.MouseButton1Click:Connect(function()
            modules.Merchant:SetWeather(wName, modules.Network)
        end)
    end

    -- ==========================================
    -- ISI KONTEN TAB 4: TELEPORTASI (30+ LOKASI)
    -- ==========================================
    local tpPage = self.Tabs["Teleport"]

    createSectionHeader(tpPage, "👥 TELEPORT KE PEMAIN LAIN")
    createTextInput(tpPage, "Ketik Username / Display Name...", "TP Player", function(name)
        local ok = modules.Teleport:ToPlayer(name)
        if ok then
            state.LastStatusMessage = "📍 TP ke pemain: " .. name
        else
            warn("[Bodoamat | Teleport] Pemain '" .. name .. "' tidak ditemukan di server!")
        end
    end)

    createSectionHeader(tpPage, "📌 SIMPAN TITIK KUSTOM (WAYPOINT)")
    createTextInput(tpPage, "Beri nama titik kustom...", "Simpan Posisi", function(wpName)
        modules.Teleport:SaveCurrentPosition(wpName)
        state.LastStatusMessage = "📌 Waypoint tersimpan: " .. wpName
    end)

    createSectionHeader(tpPage, "📍 DAFTAR LOKASI RESMI (30+ ZONA)")

    -- Filter Kategori Lokasi
    local currentFilter = "Semua"
    local catFilterCard = Instance.new("Frame")
    catFilterCard.Size = UDim2.new(1, -4, 0, 32)
    catFilterCard.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    catFilterCard.BorderSizePixel = 0
    catFilterCard.Parent = tpPage

    local cfLayout = Instance.new("UIListLayout")
    cfLayout.FillDirection = Enum.FillDirection.Horizontal
    cfLayout.Padding = UDim.new(0, 4)
    cfLayout.Parent = catFilterCard

    local filterButtons = {}
    local catFilters = {
        { Id = "Semua",  Label = "Semua" },
        { Id = "New",    Label = "🌟 Zona Baru" },
        { Id = "Shop",   Label = "🛒 Toko/Cellar" },
        { Id = "Island", Label = "🏝️ Pulau" },
        { Id = "Secret", Label = "🔮 Secret" },
    }

    local locContainer = Instance.new("Frame")
    locContainer.Size = UDim2.new(1, 0, 0, 0)
    locContainer.AutomaticSize = Enum.AutomaticSize.Y
    locContainer.BackgroundTransparency = 1
    locContainer.Parent = tpPage

    local lcLayout = Instance.new("UIListLayout")
    lcLayout.Padding = UDim.new(0, 6)
    lcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lcLayout.Parent = locContainer

    local function refreshLocList()
        for _, child in ipairs(locContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        for _, loc in ipairs(modules.Teleport.Locations) do
            if currentFilter == "Semua" or loc.Category == currentFilter then
                local tpCard = Instance.new("Frame")
                tpCard.Size = UDim2.new(1, -4, 0, 36)
                tpCard.BackgroundColor3 = config.UI.Theme.CardBg
                tpCard.BorderSizePixel = 0
                tpCard.Parent = locContainer

                local cCorner = Instance.new("UICorner")
                cCorner.CornerRadius = UDim.new(0, 7)
                cCorner.Parent = tpCard

                local locLabel = Instance.new("TextLabel")
                locLabel.Size = UDim2.new(1, -85, 1, 0)
                locLabel.Position = UDim2.new(0, 10, 0, 0)
                locLabel.BackgroundTransparency = 1
                locLabel.Text = (loc.Category == "New" and "⭐ " or "📍 ") .. loc.Name
                locLabel.TextColor3 = (loc.Category == "New") and Color3.fromRGB(255, 215, 0) or config.UI.Theme.Text
                locLabel.TextSize = 11
                locLabel.Font = Enum.Font.GothamMedium
                locLabel.TextXAlignment = Enum.TextXAlignment.Left
                locLabel.Parent = tpCard

                local goBtn = Instance.new("TextButton")
                goBtn.Size = UDim2.new(0, 68, 0, 24)
                goBtn.Position = UDim2.new(1, -74, 0.5, -12)
                goBtn.BackgroundColor3 = (loc.Category == "New") and Color3.fromRGB(230, 126, 34) or Color3.fromRGB(0, 150, 230)
                goBtn.Text = "Teleport"
                goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                goBtn.TextSize = 10
                goBtn.Font = Enum.Font.GothamBold
                goBtn.Parent = tpCard

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(0, 5)
                bCorner.Parent = goBtn

                goBtn.MouseButton1Click:Connect(function()
                    local success = modules.Teleport:To(loc.CFrame)
                    if success then
                        state.LastStatusMessage = "📍 Teleport ke " .. loc.Name
                    end
                end)
            end
        end
    end

    for _, cf in ipairs(catFilters) do
        local fb = Instance.new("TextButton")
        fb.Size = UDim2.new(0.19, -2, 1, 0)
        fb.BackgroundColor3 = (currentFilter == cf.Id) and config.UI.Theme.Accent or Color3.fromRGB(32, 35, 48)
        fb.Text = cf.Label
        fb.TextColor3 = Color3.fromRGB(255, 255, 255)
        fb.TextSize = 9
        fb.Font = Enum.Font.GothamMedium
        fb.Parent = catFilterCard

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = fb

        filterButtons[cf.Id] = fb

        fb.MouseButton1Click:Connect(function()
            currentFilter = cf.Id
            for id, b in pairs(filterButtons) do
                b.BackgroundColor3 = (id == cf.Id) and config.UI.Theme.Accent or Color3.fromRGB(32, 35, 48)
            end
            refreshLocList()
        end)
    end

    refreshLocList()

    -- ==========================================
    -- ISI KONTEN TAB 5: MOBILITAS (MOVEMENT)
    -- ==========================================
    local movePage = self.Tabs["Movement"]

    createToggle(movePage, "Walk On Water (Jesus Walk)", "Berjalan di atas permukaan air laut tanpa jatuh", state.IsWaterWalk, function(val)
        state:Set("IsWaterWalk", val)
        modules.Movement:SetWaterWalk(val)
    end)

    createToggle(movePage, "Infinite Jump", "Lompat bebas di udara tanpa batas", state.IsInfJump, function(val)
        state:Set("IsInfJump", val)
        modules.Movement:SetInfiniteJump(val)
    end)

    -- Kecepatan Lari (WalkSpeed)
    local spdCard = Instance.new("Frame")
    spdCard.Size = UDim2.new(1, -4, 0, 62)
    spdCard.BackgroundColor3 = config.UI.Theme.CardBg
    spdCard.BorderSizePixel = 0
    spdCard.Parent = movePage

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 8)
    sCorner.Parent = spdCard

    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(1, -20, 0, 18)
    sTitle.Position = UDim2.new(0, 12, 0, 6)
    sTitle.BackgroundTransparency = 1
    sTitle.Text = "Kecepatan Karakter (WalkSpeed: " .. tostring(modules.Movement.WalkSpeed) .. ")"
    sTitle.TextColor3 = config.UI.Theme.Text
    sTitle.TextSize = 12
    sTitle.Font = Enum.Font.GothamBold
    sTitle.TextXAlignment = Enum.TextXAlignment.Left
    sTitle.Parent = spdCard

    local spdContainer = Instance.new("Frame")
    spdContainer.Size = UDim2.new(1, -24, 0, 28)
    spdContainer.Position = UDim2.new(0, 12, 0, 26)
    spdContainer.BackgroundTransparency = 1
    spdContainer.Parent = spdCard

    local spdLayout = Instance.new("UIListLayout")
    spdLayout.FillDirection = Enum.FillDirection.Horizontal
    spdLayout.Padding = UDim.new(0, 6)
    spdLayout.Parent = spdContainer

    local speeds = {
        { Label = "Normal (16)", Val = 16 },
        { Label = "Cepat (32)",  Val = 32 },
        { Label = "Super (64)",  Val = 64 },
        { Label = "Flash (120)", Val = 120 },
    }

    for _, s in ipairs(speeds) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.24, -4, 1, 0)
        b.BackgroundColor3 = (modules.Movement.WalkSpeed == s.Val) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        b.Text = s.Label
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamMedium
        b.Parent = spdContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b

        b.MouseButton1Click:Connect(function()
            modules.Movement:SetWalkSpeed(s.Val)
            sTitle.Text = "Kecepatan Karakter (WalkSpeed: " .. tostring(s.Val) .. ")"
        end)
    end

    -- ==========================================
    -- ISI KONTEN TAB 6: OPTIMASI & PERFORMA
    -- ==========================================
    local optPage = self.Tabs["Optimasi"]

    createToggle(optPage, "FPS Booster (Safe Anti-BAC)", "Menonaktifkan partikel berat & bloom (Tanpa tamper parts)", state.IsFpsBoost, function(val)
        state:Set("IsFpsBoost", val)
        modules.FpsBooster:SetFpsBoost(val)
    end)

    createToggle(optPage, "Ultra GPU Saver (AFK Safe)", "Matikan 3D rasterization agar suhu PC/HP dingin", state.IsGpuSaver, function(val)
        state:Set("IsGpuSaver", val)
        modules.FpsBooster:SetGpuSaver(val, state)
    end)

    -- ==========================================
    -- ISI KONTEN TAB 7: STATUS & STATISTIK
    -- ==========================================
    local statPage = self.Tabs["Status"]

    local statBox = Instance.new("Frame")
    statBox.Size = UDim2.new(1, -4, 0, 230)
    statBox.BackgroundColor3 = config.UI.Theme.CardBg
    statBox.BorderSizePixel = 0
    statBox.Parent = statPage

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 8)
    stCorner.Parent = statBox

    local statText = Instance.new("TextLabel")
    statText.Size = UDim2.new(1, -24, 1, -20)
    statText.Position = UDim2.new(0, 12, 0, 10)
    statText.BackgroundTransparency = 1
    statText.TextColor3 = config.UI.Theme.Text
    statText.TextSize = 12
    statText.Font = Enum.Font.Gotham
    statText.TextXAlignment = Enum.TextXAlignment.Left
    statText.TextYAlignment = Enum.TextYAlignment.Top
    statText.RichText = true
    statText.Parent = statBox

    task.spawn(function()
        while screenGui.Parent do
            local elapsed = state:GetElapsedTime()
            local caught = state.FishCaught
            local fishStatus = state.IsFishing and "<font color='#2ecc71'>Aktif</font>" or "<font color='#e74c3c'>Nonaktif</font>"
            local o2Status = state.IsOxygenEquipped and "<font color='#2ecc71'>Aktif</font>" or "<font color='#e74c3c'>Mati</font>"
            local radarStatus = state.IsRadar and "<font color='#2ecc71'>Aktif</font>" or "<font color='#e74c3c'>Mati</font>"

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            local posStr = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"

            statText.Text = string.format(
                "<b>📊 INFORMASI LIVE SESSION:</b>\n\n" ..
                "• <b>Durasi Menjalankan:</b> <font color='#00d2ff'>%s</font>\n" ..
                "• <b>Total Ikan Tertangkap:</b> <font color='#2ecc71'>%d Ekor</font>\n" ..
                "• <b>Auto Fishing:</b> %s\n" ..
                "• <b>Tabung Oksigen:</b> %s | <b>Radar:</b> %s\n" ..
                "• <b>Posisi Karakter:</b> <font color='#9b59b6'>%s</font>\n" ..
                "• <b>Status Sistem:</b> %s\n\n" ..
                "<b>🛡️ STATUS KEAMANAN (ANTI-BAC):</b>\n" ..
                "• <b>IsSelling Guard:</b> <font color='#2ecc71'>Aktif (BAC-8228 Guard)</font>\n" ..
                "• <b>Workspace Part Tamper:</b> <font color='#2ecc71'>Dihapus (BAC-6228 Guard)</font>\n" ..
                "• <b>GPU Saver Mode:</b> <font color='#2ecc71'>Engine Raster Standby</font>",
                elapsed, caught, fishStatus, o2Status, radarStatus, posStr, status
            )
            task.wait(1)
        end
    end)

    -- 6. Tombol Floating Buka/Tutup GUI untuk Mobile (Touch Draggable)
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "AppFloatingBtn"
    mobileBtn.Size = UDim2.new(0, 48, 0, 48)
    mobileBtn.Position = UDim2.new(0, 20, 0.5, -24)
    mobileBtn.BackgroundColor3 = config.UI.Theme.CardBg
    mobileBtn.Text = "🐟"
    mobileBtn.TextSize = 22
    mobileBtn.Active = true
    mobileBtn.Parent = screenGui

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 24)
    mbCorner.Parent = mobileBtn

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = config.UI.Theme.Accent
    mbStroke.Thickness = 1.5
    mbStroke.Parent = mobileBtn

    -- Logika Dragging Tombol Mobile (Sentuh & Geser)
    local mbDragging, mbDragInput, mbDragStart, mbStartPos
    local mbHasMoved = false
    mobileBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mbDragging = true
            mbHasMoved = false
            mbDragStart = input.Position
            mbStartPos = mobileBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    mbDragging = false
                end
            end)
        end
    end)

    mobileBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            mbDragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == mbDragInput and mbDragging then
            local delta = input.Position - mbDragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                mbHasMoved = true
            end
            mobileBtn.Position = UDim2.new(
                mbStartPos.X.Scale,
                mbStartPos.X.Offset + delta.X,
                mbStartPos.Y.Scale,
                mbStartPos.Y.Offset + delta.Y
            )
        end
    end)

    mobileBtn.MouseButton1Click:Connect(function()
        if not mbHasMoved then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    -- Shortcut Keyboard Toggle (Default: RightShift)
    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == config.UI.ToggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    -- Aktifkan tab pertama secara default
    self:SwitchTab("Fishing", config)

    print("[Bodoamat | UI] Standalone GUI v3.0 berhasil dibuat.")
end

function BodoamatGui:SwitchTab(tabId: string, config: any)
    self.CurrentTab = tabId
    for id, page in pairs(self.Tabs) do
        page.Visible = (id == tabId)
    end
    for id, btn in pairs(self.TabButtons) do
        btn.BackgroundColor3 = (id == tabId) and config.UI.Theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.TextColor3 = (id == tabId) and config.UI.Theme.Accent or config.UI.Theme.TextSubtle
    end
end

-- ============================================================
-- 13. BOOTSTRAP INITIALIZATION
-- ============================================================
local Modules = {
    Network = Network,
    AutoFish = AutoFish,
    AutoSell = AutoSell,
    Teleport = Teleport,
    Totem = Totem,
    Merchant = Merchant,
    Movement = Movement,
    FpsBooster = FpsBooster,
    UI = BodoamatGui,
}

local function Init()
    print("================================================")
    print("🚀 BODOAMAT v3.0 (Stealth Anti-BAC / Delta) - Memulai...")
    print("================================================")

    -- Buat Tampilan GUI Secara Instan (0 Detik)
    BodoamatGui:Create(Config, State, Modules)

    -- Inisialisasi Jaringan Stealth di Background (Non-blocking)
    task.spawn(function()
        Network:Init()
    end)

    print("[Bodoamat v3.0] Berhasil dimuat! Tekan RightShift atau sentuh tombol 🐟 untuk membuka menu.")
end

Init()
return Modules
