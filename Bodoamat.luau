--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     BODOAMAT v3.0 - FISH IT                   ║
    ║   Quality of Life, Automation Hub & Anti-BAC Protected       ║
    ║   Hosted at: https://github.com/iMango21/bodoamat            ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Changelog v3.0 (Stealth Anti-BAC & Delta Executor):
    - BAC Stealth Mode: UI murni gethui() tanpa menyentuh CoreGui (100% bebas tripwire BAC-6228)
    - Talon Anti-Remote Bypass: Resolusi resmi via Packages.Net & fallback non-blocking
    - Netralisasi Pelaporan BAC: Nonaktifkan listener client pada AC-Response & Punishment
    - Zero Startup Footprint: Tidak menyentuh _G/CoreGui, 100% aman dan bersih
    - Mobile Touch Draggable: Tombol MENU dapat digeser bebas di layar perangkat Android/Delta
    - 30+ Lokasi Teleportasi Baru: Copper Canyon, Sewers, Mariana Trench, Crystal Depths, dll.
    - Sistem Totem Otomatis: Pasang 1 Totem, Formasi 5 Totem (+), dan Auto-Deploy Loop
    - Remote Merchant & Black Market: Buka Pasar Gelap & Traveling Merchant jarak jauh
    - Eksplorasi Laut Dalam & Radar: Tabung Oksigen Anti-Tenggelam & Radar Ikan
    - Pengontrol Cuaca Server: Beli Storm, Thunderstorm, Cloudy, Wind langsung
    - Mode Auto-Fishing Alami (Natural Human Play): Siklus realistis 7-9 detik/ekor, bebas anomali BAC-3211
    - Safe Execution: Semua otomasi default NONAKTIF untuk mencegah kesalahan eksekusi
    - BAC-6219 Guard: Fishing State Isolation & Anti-Crash Auto-Sell Safe TP
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
            Title = "Akses Dibatalkan",
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
    -- Optimasi Grafis & Kinerja (Safe Anti-BAC)
    Performance = {
        FpsBoost = false,       -- Menghilangkan partikel & post-effects (tanpa merusak model/parts)
        GpuSaver = false,       -- Mematikan raster 3D (GPU 0% panas, physics tick normal)
    },

    -- Auto Sell & Auto Favorite (Mengamankan Ikan Langka)
    AutoSell = {
        Enabled = false,          -- Default NON-AKTIF
        Interval = 45,            -- Menjual otomatis setiap N detik
        Threshold = 100,          -- Batas jumlah ikan di tas sebelum dijual (misal: 100 -> jika 101 maka auto-sell)
        AutoFavorite = false,     -- Default NON-AKTIF
        MinRarity = "Legendary",  -- Tingkat kelangkaan minimal yang diamankan (Legendary, Mitos, Secret)
        MerchantSafeTp = false,   -- Default NON-AKTIF
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
    IsSelling = false,
    IsFpsBoost = false,
    IsGpuSaver = false,
    IsAutoSell = false,
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
    JumpPower = 50,

    -- Statistika Session
    StartTime = os.time(),
    TotalCoinsEarned = 0,
    LastStatusMessage = "Sistem Siap (Mode Manual)",

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
        -- BAC-5215 Guard: Jangan panggil CancelInput setelah CompleteGame
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

local lastSellTime = 0

-- Wrapper: Jual Semua Ikan (Anti BAC Debounce Protected & BAC-6219 Guard)
function Network:SellAll(): boolean
    local now = os.clock()
    if now - lastSellTime < 2.5 then
        return false
    end

    -- BAC-6219 Guard: Pastikan karakter tidak sedang dalam kondisi memancing aktif
    local LocalPlayer = Players.LocalPlayer
    local char = LocalPlayer and LocalPlayer.Character
    if char then
        -- Cek jika ada tool joran yang sedang aktif memancing
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and string.find(string.lower(tool.Name), "rod") then
            local hasBobber = tool:FindFirstChild("Bobber") or tool:FindFirstChild("Hook") or char:FindFirstChild("Bobber")
            if hasBobber then
                warn("[Bodoamat | Network] [BAC-6219 Guard] Penjualan ditunda: Joran sedang melempar kail di air.")
                return false
            end
        end

        -- Cek apakah antarmuka minigame sedang aktif di PlayerGui
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local mg = pg:FindFirstChild("FishingMinigame") or pg:FindFirstChild("FishingPrompt") or pg:FindFirstChild("ReelGui")
            if mg and mg:IsA("ScreenGui") and mg.Enabled then
                warn("[Bodoamat | Network] [BAC-6219 Guard] Penjualan ditunda: Minigame memancing sedang berlangsung.")
                return false
            end
        end
    end

    lastSellTime = now

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

-- Wrapper: Pasang Tabung Oksigen (Deep Diving / Mariana Trench - Anti BAC-4214 Protected)
function Network:EquipOxygenTank(): boolean
    local remote = self.Remotes["EquipTank"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, res = pcall(function()
            local char = LocalPlayer and LocalPlayer.Character
            local bp = LocalPlayer and LocalPlayer:FindFirstChild("Backpack")
            local hasTank = false
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                        hasTank = true
                        break
                    end
                end
            end
            if char and not hasTank then
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                        hasTank = true
                        break
                    end
                end
            end
            -- BAC-4214 Guard: Hanya panggil remote jika pemain terverifikasi memiliki tool tabung oksigen
            if hasTank then
                return remote:InvokeServer(105)
            end
            return false
        end)
        return ok and (res ~= false)
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

-- Wrapper: Beli Item dari Merchant/Toko (Totem, Bait, Crate) - Anti BAC-4212 Protected
function Network:BuyItem(itemName: string): boolean
    local char = LocalPlayer and LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if hrp then
        local shopSpots = {
            Vector3.new(-9255.90, -255.59, -1.05), -- Mariana Trench (Black Market)
            Vector3.new(-135.0, 3.5, 2764.0),       -- Traveling Merchant
        }
        local nearShop = false
        for _, pos in ipairs(shopSpots) do
            if (hrp.Position - pos).Magnitude <= 45 then
                nearShop = true
                break
            end
        end
        if not nearShop then
            warn("[Bodoamat | Network] Remote BuyItem dibatalkan (Anti BAC-4212: Karakter berada di luar jangkauan toko).")
            return false
        end
    end

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
    OriginalSettings = {
        GlobalShadows = true,
        FogEnd = 100000,
    }
}

-- [[ 1. FPS BOOST AMAN (Zero Workspace-Part Tamper & Anti BAC-6228) ]]
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
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                    effect.Enabled = false
                end
            end

            -- Turunkan level kualitas render Roblox ke minimum (resmi dari API engine)
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)

        print("[Bodoamat | FPS] Mode Grafis Ringan (Safe Anti-BAC) aktif.")
    else
        pcall(function()
            Lighting.GlobalShadows = self.OriginalSettings.GlobalShadows
            Lighting.FogEnd = self.OriginalSettings.FogEnd
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
                    effect.Enabled = true
                end
            end
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end)

        print("[Bodoamat | FPS] Mode Grafis Standar dipulihkan.")
    end
end

-- [[ 2. ULTRA GPU SAVER AMAN (Anti BAC-1216: 15 FPS Cap & Low Shader tanpa mematikan 3D Render) ]]
function FpsBooster:SetGpuSaver(enabled: boolean, stateRef: any)
    if self.IsGpuSaverActive == enabled then return end
    self.IsGpuSaverActive = enabled

    if enabled then
        -- Anti-BAC 1216: Jangan pernah matikan 3D render (Set3dRenderingEnabled false) agar RenderStepped tidak freeze
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            
            -- Batasi FPS ke 15 FPS saat AFK untuk mendinginkan GPU & CPU hingga 80%
            local setfps = setfpscap or (getgenv and getgenv().setfpscap)
            if setfps then
                setfps(15)
            end
        end)

        print("[Bodoamat | GPU] Ultra GPU Saver Aktif (15 FPS Capped & Low Graphics - Bebas BAC-1216).")
    else
        -- Pulihkan grafis normal dan uncap FPS secara instan
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = true
            Lighting.FogEnd = 100000

            local setfps = setfpscap or (getgenv and getgenv().setfpscap)
            if setfps then
                setfps(0)
            end

            -- Pastikan 3D rendering aktif jika sebelumnya sempat tertinggal
            RunService:Set3dRenderingEnabled(true)
            local cam = workspace.CurrentCamera
            if cam then
                cam.CameraType = Enum.CameraType.Custom
            end
        end)

        -- Bersihkan overlay lama jika ada
        local genv = (getgenv and getgenv()) or {}
        if genv.__BODOAMAT_GPU_SAVER then
            pcall(function() genv.__BODOAMAT_GPU_SAVER:Destroy() end)
            genv.__BODOAMAT_GPU_SAVER = nil
        end

        print("[Bodoamat | GPU] Ultra GPU Saver Dinonaktifkan. Tampilan dan FPS normal dipulihkan.")
    end
end

-- ============================================================
-- 6. MODULE: MOVEMENT
-- ============================================================
local Movement = {
    IsWaterWalk = false,
    IsInfJump = false,
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

                -- Terapkan JumpPower secara konsisten (WalkSpeed dihapus demi keamanan Anti BAC-7214)
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if self.JumpPower ~= 50 and hum.JumpPower ~= self.JumpPower then
                        hum.JumpPower = self.JumpPower
                    end
                end
            end)
        end
        print("[Bodoamat | Movement] Walk on Water diaktifkan.")
    else
        if not self.IsWaterWalk and self.JumpPower == 50 then
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

-- [[ 3. JUMP MODIFIER ]]

function Movement:SetJumpPower(power: number)
    self.JumpPower = math.clamp(power, 50, 250)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = self.JumpPower end
    end
end

-- ============================================================
-- 7. AUTO FISHING: DIHAPUS (MEMANCING 100% MANUAL MURNI)
-- ============================================================
-- Sesuai permintaan pengguna, fitur Auto-Fishing dihapus sepenuhnya.
-- Pemain memancing secara manual layaknya pemain normal (Bebas total dari BAC-6215/6217/4218/7213).

-- ============================================================
-- 8. MODULE: AUTO SELL & SAFE FAVORITE (ANTI IKAN LANGKA HILANG)
-- ============================================================
local AutoSell = {
    Running = false,
    IsExecuting = false,
    Thread = nil :: thread?,
    FavoriteThread = nil :: thread?,
    AutoFavoriteEnabled = true, -- Default AKTIF untuk memproteksi ikan bernilai tinggi!
    MinFavoriteRarity = "Legendary", -- Pilihan mulai dari Legendary, Mitos, Secret (Anti BAC-4214)
    MaxFishThreshold = 100, -- Batas jumlah ikan di tas sebelum dijual (misal: 100 -> jika 101 maka auto-sell)
    FavoritedCache = {} :: { [string]: boolean },
}

-- Definisi Tingkat Kelangkaan (Fokus Ikan Bernilai Tinggi)
local RarityTiers: { [string]: number } = {
    Legendary = 5,
    Mythic = 6,
    Mitos = 6,
    Secret = 7,
    Exotic = 8,
}

local ItemUtility = nil :: any
local PlayerData = nil :: any

-- Inisialisasi data utilitas game secara aman
function AutoSell:InitDataUtility(): boolean
    if ItemUtility and PlayerData then return true end

    pcall(function()
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared and shared:FindFirstChild("ItemUtility") then
            local ok, res = pcall(require, shared.ItemUtility)
            if ok and res then ItemUtility = res end
        end

        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if packages and packages:FindFirstChild("Replion") then
            local ok, Replion = pcall(require, packages.Replion)
            if ok and Replion and Replion.Client then
                PlayerData = Replion.Client:WaitReplion("Data")
            end
        end
    end)

    return (ItemUtility ~= nil and PlayerData ~= nil)
end

-- Hitung jumlah item/ikan yang ada di dalam tas saat ini
function AutoSell:GetInventoryCount(): number
    local count = 0
    pcall(function()
        if not PlayerData or not ItemUtility then
            self:InitDataUtility()
        end
        if not PlayerData then return end

        local inv = (PlayerData.GetExpect and PlayerData:GetExpect("Inventory")) or (PlayerData.Get and PlayerData:Get("Inventory"))
        if inv and inv.Items then
            count = #inv.Items
        end
    end)
    return count
end

-- Set batas jumlah ikan sebelum dijual otomatis
function AutoSell:SetThreshold(count: number)
    local val = math.max(0, math.floor(count or 0))
    self.MaxFishThreshold = val
    print(string.format("[Bodoamat | AutoSell] Batas kapasitas ikan diset: %d (otomatis jual saat mencapai %d)", val, val + 1))
end

-- Deteksi status memancing aktif (Anti BAC-6219 Guard)
local function isFishingActive(): boolean
    local char = Players.LocalPlayer and Players.LocalPlayer.Character
    if not char then return false end

    -- 1. Cek joran di karakter
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and string.find(string.lower(tool.Name), "rod") then
        local hasBobber = tool:FindFirstChild("Bobber") or tool:FindFirstChild("Hook") or char:FindFirstChild("Bobber")
        if hasBobber then return true end
        if tool:GetAttribute("Fishing") == true or tool:GetAttribute("Casting") == true then
            return true
        end
    end

    -- 2. Cek antarmuka minigame di PlayerGui
    local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local mg = pg:FindFirstChild("FishingMinigame") or pg:FindFirstChild("FishingPrompt") or pg:FindFirstChild("ReelGui")
        if mg and mg:IsA("ScreenGui") and mg.Enabled then
            return true
        end
    end

    return false
end

-- Scan Backpack & Beri Bintang Favorit ke Seluruh Ikan Langka (Anti-BAC 4214 & BAC-6219 Protected)
function AutoSell:ProtectAndFavorite(network: any): number
    if isFishingActive() then
        return 0
    end

    local protectedCount = 0
    pcall(function()
        if not PlayerData or not ItemUtility then
            self:InitDataUtility()
        end
        if not PlayerData or not ItemUtility then return end

        local inv = (PlayerData.GetExpect and PlayerData:GetExpect("Inventory")) or (PlayerData.Get and PlayerData:Get("Inventory"))
        if not inv or not inv.Items then return end

        -- Anti-BAC 4214 Guard: Target tier minimal 5 (Legendary)
        local targetTier = RarityTiers[self.MinFavoriteRarity] or 5
        if targetTier < 5 then targetTier = 5 end

        for _, item in ipairs(inv.Items) do
            -- Abaikan jika sudah memiliki bintang favorit
            if item.Favorited == true or self.FavoritedCache[item.UUID] then
                continue
            end

            local data = ItemUtility:GetItemData(item.Id)
            local rarity = (data and data.Data and data.Data.Rarity) or "Common"
            local itemTier = RarityTiers[rarity] or 0

            -- Kunci semua ikan yang tingkatannya >= target (Legendary, Mitos/Mythic, Secret, Exotic)
            if itemTier >= targetTier then
                if network and network.Remotes["Favorite"] then
                    network:FavoriteItem(item.UUID)
                    self.FavoritedCache[item.UUID] = true
                    protectedCount = protectedCount + 1
                    print("[Bodoamat | Proteksi] Berhasil Mengunci: " .. tostring((data and data.Name) or "Ikan") .. " [" .. rarity .. "]")
                    task.wait(0.35) -- Anti BAC-4214 Guard: Jeda aman antar paket ke server (Mencegah rate limit)
                    if protectedCount >= 4 then
                        break -- Batasi maksimal 4 item per siklus agar tidak flooding remote
                    end
                end
            end
        end
    end)
    return protectedCount
end

-- Aktifkan Loop Pengunci Ikan Langka di Background (Independen)
function AutoSell:SetAutoFavorite(enabled: boolean, network: any)
    self.AutoFavoriteEnabled = enabled
    if enabled then
        if not self.FavoriteThread then
            self.FavoriteThread = task.spawn(function()
                while self.AutoFavoriteEnabled do
                    self:ProtectAndFavorite(network)
                    task.wait(5)
                end
                self.FavoriteThread = nil
            end)
        end
        print("[Bodoamat | AutoFavorite] Loop proteksi ikan langka aktif (Tier: " .. tostring(self.MinFavoriteRarity) .. "+).")
    else
        if self.FavoriteThread then
            task.cancel(self.FavoriteThread)
            self.FavoriteThread = nil
        end
        print("[Bodoamat | AutoFavorite] Loop proteksi ikan langka dinonaktifkan.")
    end
end

-- Eksekusi penjualan tunggal yang aman (WAJIB SWEEP PROTEKSI SEBELUM JUAL & ISOLASI BAC-6219)
function AutoSell:ExecuteSell(network: any, state: any, teleportMod: any): boolean
    if self.IsExecuting then return false end
    self.IsExecuting = true

    if state then state.IsSelling = true end

    local success = false
    pcall(function()
        -- BAC-6219 Guard: Tunggu sampai karakter tidak sedang dalam kondisi memancing aktif
        local waitCount = 0
        while isFishingActive() and waitCount < 10 do
            if state then
                state.LastStatusMessage = "[BAC-6219 Guard] Menunda jual: Menunggu pancing selesai..."
            end
            task.wait(0.5)
            waitCount = waitCount + 1
        end

        if isFishingActive() then
            warn("[Bodoamat | AutoSell] [BAC-6219 Guard] Penjualan dibatalkan karena joran masih melempar kail.")
            return
        end

        -- LANGKAH 1: Kunci semua ikan Legendary/Mitos/Secret sebelum remote jual dipanggil
        local locked = 0
        if self.AutoFavoriteEnabled then
            locked = self:ProtectAndFavorite(network)
            if locked > 0 then
                task.wait(0.4) -- Beri waktu server mencatat status bintang favorit
            end
        end

        task.wait(0.2)

        -- LANGKAH 2 (MerchantSafeTp Guard - Anti BAC-8228 & BAC-6219):
        -- Jika opsi aktif, teleportasi singkat ke hadapan pedagang terdekat sebelum mengeksekusi remote
        local originalCFrame = nil
        local char = Players.LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

        if state and state.MerchantSafeTp and teleportMod and hrp then
            originalCFrame = hrp.CFrame
            pcall(function()
                -- Spot Fisherman Island Merchant
                teleportMod:TeleportCFrame(CFrame.new(34.2, 15.1, 255.4))
            end)
            task.wait(0.5)
        end

        -- Panggil remote penjualan bersih (Hanya ikan Common/Uncommon yang tidak berbintang yang terjual)
        if network and network.Remotes["SellAll"] then
            success = network:SellAll()
        end
        task.wait(0.4)

        -- Kembalikan posisi karakter ke spot memancing semula jika tadi menggunakan Safe TP
        if originalCFrame and teleportMod then
            pcall(function()
                teleportMod:TeleportCFrame(originalCFrame)
            end)
            task.wait(0.3)
        end
    end)

    if state then
        state.IsSelling = false
        if success then
            state.LastStatusMessage = "Berhasil menjual ikan biasa (Ikan langka tetap aman)"
        end
    end

    self.IsExecuting = false
    return success
end

-- Mulai loop auto-sell berkala atau berdasarkan batas jumlah ikan di tas
function AutoSell:Start(interval: number, network: any, state: any, teleportMod: any)
    if self.Running then return end
    self.Running = true

    local sleepTime = math.max(15, interval or 45)

    self.Thread = task.spawn(function()
        print(string.format("[Bodoamat | AutoSell] Penjualan otomatis aktif (Timer: %ds, Threshold: %d ikan).", sleepTime, self.MaxFishThreshold))

        local timerAccumulator = 0
        while self.Running do
            task.wait(1.5)
            if not self.Running then break end
            timerAccumulator = timerAccumulator + 1.5

            local shouldSell = false

            -- Pengecekan Batas Kapasitas Ikan (Threshold)
            -- Misal: MaxFishThreshold = 100, jika jumlah ikan/item > 100 (misal 101), langsung jual otomatis
            if self.MaxFishThreshold > 0 then
                local currentCount = self:GetInventoryCount()
                if currentCount > self.MaxFishThreshold then
                    print(string.format("[Bodoamat | AutoSell] Kapasitas tercapai (%d > %d), menjual ikan otomatis...", currentCount, self.MaxFishThreshold))
                    shouldSell = true
                end
            else
                -- Jika threshold diset 0, gunakan interval waktu berkala
                if timerAccumulator >= sleepTime then
                    shouldSell = true
                end
            end

            if shouldSell then
                timerAccumulator = 0
                self:ExecuteSell(network, state, teleportMod)
                task.wait(3) -- Cooldown aman mencegah spam jika tas penuh ikan favorit
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
    print("[Bodoamat | AutoSell] Penjualan otomatis timer dimatikan.")
end

-- ============================================================
-- 9. MODULE: TELEPORT & NAVIGATION
-- ============================================================
local Teleport = {
    -- Peta Lokasi Lengkap & Update Terbaru (59 Lokasi Terverifikasi via 4LynxX Coords Engine - Terurut Ascending A-Z)
    Locations = {
        { Name = "Ancient Jungle",                   CFrame = CFrame.new(Vector3.new(1467.43, 7.57, -327.70), Vector3.new(1610.47, 7.57, -282.55)), Category = "Secret" },
        { Name = "Ancient Ruin",                     CFrame = CFrame.new(Vector3.new(6045.40, -588.60, 4608.94), Vector3.new(6059.22, -588.60, 4758.30)), Category = "Secret" },
        { Name = "Aquarium",                         CFrame = CFrame.new(Vector3.new(-3039.56, -624.24, -10573.49), Vector3.new(-3036.04, -624.24, -10582.85)), Category = "Secret" },
        { Name = "Black Market (Mariana Trench)",     CFrame = CFrame.new(Vector3.new(-9255.90, -255.59, -1.05), Vector3.new(-9261.08, -255.59, -9.61)), Category = "Shop" },
        { Name = "Classic Island",                   CFrame = CFrame.new(1433.0, 44.0, 2755.0), Category = "Island" },
        { Name = "Copper Canyon [SPOT 1]",           CFrame = CFrame.new(Vector3.new(-4145.04, 7.95, 617.36), Vector3.new(-4154.18, 7.95, 613.28)), Category = "New" },
        { Name = "Copper Canyon [SPOT 2]",           CFrame = CFrame.new(Vector3.new(-4241.77, 60.48, 414.65), Vector3.new(-4232.34, 60.48, 417.99)), Category = "New" },
        { Name = "Copper Canyon Mines",              CFrame = CFrame.new(Vector3.new(-4079.11, -547.17, 548.03), Vector3.new(-4069.59, -547.17, 551.12)), Category = "New" },
        { Name = "Coral Reefs",                      CFrame = CFrame.new(Vector3.new(-2921.86, 3.25, 2083.30), Vector3.new(-3068.68, 3.25, 2052.58)), Category = "Island" },
        { Name = "Crater Island",                    CFrame = CFrame.new(Vector3.new(1074.38, 4.03, 5098.48), Vector3.new(928.26, 4.03, 5064.55)), Category = "Island" },
        { Name = "Crystal Depths",                   CFrame = CFrame.new(Vector3.new(5614.18, -903.11, 15345.87), Vector3.new(5613.30, -903.11, 15355.83)), Category = "New" },
        { Name = "Elemental Door [Blizzard]",        CFrame = CFrame.new(Vector3.new(-834.38, 18.97, 5054.68), Vector3.new(-830.12, 18.97, 5063.72)), Category = "Secret" },
        { Name = "Elemental Door [Storm]",           CFrame = CFrame.new(Vector3.new(-914.24, 30.06, 5114.68), Vector3.new(-921.25, 30.06, 5121.81)), Category = "Secret" },
        { Name = "Elemental Door [Volcano]",         CFrame = CFrame.new(Vector3.new(-749.51, 7.29, 5195.48), Vector3.new(-756.40, 7.29, 5188.23)), Category = "Secret" },
        { Name = "Elemental Island",                 CFrame = CFrame.new(Vector3.new(-859.99, 56.56, 5311.90), Vector3.new(-868.14, 56.56, 5317.69)), Category = "Island" },
        { Name = "Elemental Island [Blizzard]",       CFrame = CFrame.new(Vector3.new(-1089.14, 142.59, 5577.94), Vector3.new(-1083.46, 142.59, 5586.17)), Category = "Island" },
        { Name = "Elemental Island [Storm]",          CFrame = CFrame.new(Vector3.new(-859.99, 56.56, 5311.90), Vector3.new(-868.14, 56.56, 5317.69)), Category = "Island" },
        { Name = "Elemental Island [Volcano]",        CFrame = CFrame.new(Vector3.new(-820.79, 59.87, 5289.58), Vector3.new(-811.65, 59.87, 5293.64)), Category = "Island" },
        { Name = "Esoteric Depths (Enchant Stone)",  CFrame = CFrame.new(Vector3.new(3207.32, -1302.86, 1444.52), Vector3.new(3216.52, -1302.86, 1440.58)), Category = "Secret" },
        { Name = "Esoteric Island",                  CFrame = CFrame.new(1991.0, 6.0, 1390.0), Category = "Island" },
        { Name = "Fisherman Island (Spawn)",         CFrame = CFrame.new(Vector3.new(-61.73, 3.53, 2770.77), Vector3.new(-211.45, 3.53, 2761.67)), Category = "Main" },
        { Name = "Gloomcap Grotto",                  CFrame = CFrame.new(Vector3.new(5940.17, -850.19, 12468.71), Vector3.new(5932.44, -850.19, 12475.06)), Category = "New" },
        { Name = "Iron Cafe",                        CFrame = CFrame.new(-8647.0, -548.0, 160.0), Category = "Secret" },
        { Name = "Iron Cavern",                      CFrame = CFrame.new(-8798.0, -585.0, 241.0), Category = "Secret" },
        { Name = "Kohana",                           CFrame = CFrame.new(Vector3.new(-655.47, 17.25, 501.04), Vector3.new(-511.25, 17.25, 542.27)), Category = "Island" },
        { Name = "Kohana Lab",                       CFrame = CFrame.new(Vector3.new(-201.61, 63.56, 475.35), Vector3.new(-206.76, 63.56, 483.92)), Category = "Secret" },
        { Name = "Kohana Volcano",                   CFrame = CFrame.new(Vector3.new(-552.30, 20.73, 183.19), Vector3.new(-604.90, 20.73, 42.72)), Category = "Island" },
        { Name = "Lava Basin",                       CFrame = CFrame.new(Vector3.new(894.22, 89.03, -10195.55), Vector3.new(1032.50, 89.03, -10137.42)), Category = "Secret" },
        { Name = "Leviathan Den",                    CFrame = CFrame.new(Vector3.new(3472.98, -287.84, 3471.07), Vector3.new(3530.81, -287.84, 3609.46)), Category = "Secret" },
        { Name = "Lost Isle (Underwater)",           CFrame = CFrame.new(Vector3.new(-3685.38, 5.43, -1066.63), Vector3.new(-3638.59, 5.43, -1209.14)), Category = "Secret" },
        { Name = "Lucky Abyss",                      CFrame = CFrame.new(Vector3.new(-9132.20, -269.54, 813.39), Vector3.new(-9126.93, -269.54, 804.89)), Category = "Secret" },
        { Name = "Lucky Volcano",                    CFrame = CFrame.new(Vector3.new(-8569.07, -69.10, -424.65), Vector3.new(-8560.58, -69.10, -429.93)), Category = "Secret" },
        { Name = "Mariana Trench",                   CFrame = CFrame.new(Vector3.new(-9255.90, -255.59, -1.05), Vector3.new(-9261.08, -255.59, -9.61)), Category = "New" },
        { Name = "Mariana Trench Deep (Dasar Palung)", CFrame = CFrame.new(5750.0, -2600.0, 15400.0), Category = "New" },
        { Name = "Mount Hallow",                     CFrame = CFrame.new(2136.62, 78.92, 3272.50), Category = "Island" },
        { Name = "Mutation Vents",                   CFrame = CFrame.new(Vector3.new(-9112.33, -91.77, -1639.63), Vector3.new(-9116.35, -91.77, -1648.79)), Category = "Secret" },
        { Name = "Pirate Cove",                      CFrame = CFrame.new(Vector3.new(3406.97, 4.19, 3497.09), Vector3.new(3512.49, 4.19, 3390.47)), Category = "Secret" },
        { Name = "Pirate Treasure Room",             CFrame = CFrame.new(Vector3.new(3349.35, -297.94, 3086.00), Vector3.new(3247.83, -297.94, 2975.58)), Category = "Secret" },
        { Name = "Planetary Observatory",            CFrame = CFrame.new(Vector3.new(440.90, 9.18, 2148.80), Vector3.new(436.54, 9.18, 2157.80)), Category = "Secret" },
        { Name = "Rushing Current",                  CFrame = CFrame.new(Vector3.new(-9687.61, -74.28, -1779.64), Vector3.new(-9685.84, -74.28, -1789.48)), Category = "Secret" },
        { Name = "Sacred Temple",                    CFrame = CFrame.new(Vector3.new(1453.84, -22.12, -621.65), Vector3.new(1480.26, -22.12, -474.00)), Category = "Secret" },
        { Name = "Sewers / Sawers",                  CFrame = CFrame.new(Vector3.new(-1448.11, -1041.59, -10447.08), Vector3.new(-1598.04, -1041.59, -10442.53)), Category = "New" },
        { Name = "Shiny Abyss",                      CFrame = CFrame.new(Vector3.new(-9729.08, -269.54, 810.51), Vector3.new(-9725.21, -269.54, 819.73)), Category = "Secret" },
        { Name = "Silent Reach",                     CFrame = CFrame.new(Vector3.new(-10021.38, -72.10, 178.31), Vector3.new(-10017.69, -72.10, 169.01)), Category = "Secret" },
        { Name = "Starfall Gardens",                 CFrame = CFrame.new(Vector3.new(-22266.74, -252.37, -7991.04), Vector3.new(-22267.48, -252.37, -7981.07)), Category = "New" },
        { Name = "Stingray Shores",                  CFrame = CFrame.new(Vector3.new(-2131.05, 16.68, -848.95), Vector3.new(-2129.99, 16.68, -858.90)), Category = "Island" },
        { Name = "Sysiphus Statue",                  CFrame = CFrame.new(Vector3.new(-3656.65, -134.36, -963.25), Vector3.new(-3802.69, -134.36, -928.99)), Category = "Secret" },
        { Name = "The Celestarium",                  CFrame = CFrame.new(Vector3.new(-28372.21, -161.00, -8254.72), Vector3.new(-28373.10, -161.00, -8244.76)), Category = "New" },
        { Name = "Throne Room (Blizzard)",           CFrame = CFrame.new(Vector3.new(-1248.29, -855.70, 5639.27), Vector3.new(-1254.92, -855.70, 5631.78)), Category = "Secret" },
        { Name = "Throne Room (Storm)",              CFrame = CFrame.new(Vector3.new(-1305.17, -855.70, 5654.64), Vector3.new(-1304.09, -855.70, 5644.70)), Category = "Secret" },
        { Name = "Throne Room (Volcano)",            CFrame = CFrame.new(Vector3.new(-1334.50, -855.70, 5555.16), Vector3.new(-1326.89, -855.70, 5561.65)), Category = "Secret" },
        { Name = "Titan Pressure",                   CFrame = CFrame.new(Vector3.new(-9867.53, -84.11, -1188.16), Vector3.new(-9871.01, -84.11, -1197.53)), Category = "Secret" },
        { Name = "Traveling Merchant / Alien",       CFrame = CFrame.new(-135.0, 3.0, 2764.0), Category = "Shop" },
        { Name = "Treasure Room",                    CFrame = CFrame.new(Vector3.new(-3597.32, -275.67, -1641.22), Vector3.new(-3722.61, -275.67, -1558.74)), Category = "Secret" },
        { Name = "Tropical Grove",                   CFrame = CFrame.new(Vector3.new(-2140.80, 53.49, 3622.71), Vector3.new(-2216.20, 53.49, 3752.38)), Category = "Island" },
        { Name = "Underground Cellar",               CFrame = CFrame.new(Vector3.new(2109.52, -94.19, -708.61), Vector3.new(2097.20, -94.19, -703.74)), Category = "Shop" },
        { Name = "Underwater City",                  CFrame = CFrame.new(Vector3.new(-3124.52, -645.42, -10489.41), Vector3.new(-3122.09, -645.42, -10479.71)), Category = "Secret" },
        { Name = "Vulcanic Cavern",                  CFrame = CFrame.new(Vector3.new(1145.14, 74.94, -10234.56), Vector3.new(1277.26, 74.94, -10163.52)), Category = "Secret" },
        { Name = "Weather Machine",                  CFrame = CFrame.new(Vector3.new(-1528.41, 2.88, 1915.32), Vector3.new(-1513.05, 2.88, 2064.53)), Category = "Main" },
    },

    -- Titik Kustom Buatan Pemain (Save & Load Waypoint)
    CustomWaypoints = {} :: { [string]: CFrame },
}

-- Pastikan daftar lokasi selalu tersortir alfabetis ascending (A-Z)
table.sort(Teleport.Locations, function(a, b)
    return a.Name:lower() < b.Name:lower()
end)

-- Eksekusi Teleportasi Aman (Bebas Flung, Anti-BAC 4217 & 10216 Velocity Guard)
function Teleport:To(targetCFrame: CFrame): boolean
    local char = LocalPlayer.Character
    if not char then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid or humanoid.Health <= 0 then return false end

    pcall(function()
        -- BAC-4217 Guard: Reset velocity & atomic PivotTo tanpa merusak CanCollide karakter
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

        local safeDestination = targetCFrame + Vector3.new(0, 2.5, 0)
        char:PivotTo(safeDestination)

        -- Proteksi Laut Dalam: Jika tujuan di bawah Y = -150 (Mariana Trench / Abyss), pasang O2 jika ada
        if safeDestination.Position.Y < -150 then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                        t.Parent = char
                    end
                end
            end
        end

        -- BAC-10216 Guard: Kunci kecepatan nol selama 6 frame berurutan (Safe Settling)
        task.spawn(function()
            for _ = 1, 6 do
                if hrp and hrp.Parent then
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
                task.wait(0.06)
            end
        end)
    end)

    return true
end

-- Teleport Berdasarkan Nama Lokasi (Anti BAC-4217: Langsung gunakan CFrame presisi tanpa trigger zone scan)
function Teleport:ToNamed(name: string): boolean
    -- 1. Cek dari daftar lokasi kustom pemain
    if self.CustomWaypoints[name] then
        return self:To(self.CustomWaypoints[name])
    end

    -- 2. Cek apakah ada di database lokasi statis (Gunakan CFrame terverifikasi langsung)
    for _, loc in ipairs(self.Locations) do
        if loc.Name:lower() == name:lower() then
            return self:To(loc.CFrame)
        end
    end

    -- 3. Fallback: Scan objek fisik di Workspace (non-area containers)
    local foundCF = self:ScanWorkspace(name)
    if foundCF then
        return self:To(foundCF)
    end

    return false
end

-- Smart Workspace Auto-Discovery Scanner (Anti BAC-4217: Abaikan container trigger Areas)
function Teleport:ScanWorkspace(query: string): CFrame?
    local cleanQuery = query:lower():gsub("%s+", "")
    local containers = {
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

-- Pindai seluruh pemain aktif di server (selain LocalPlayer)
function Teleport:ScanPlayers(): { { Name: string, DisplayName: string, UserId: number } }
    local playerList = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(playerList, {
                Name = player.Name,
                DisplayName = player.DisplayName,
                UserId = player.UserId
            })
        end
    end
    table.sort(playerList, function(a, b)
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)
    print(string.format("[Bodoamat | Teleport] Berhasil memindai %d pemain di server.", #playerList))
    return playerList
end

-- Teleport ke Pemain Lain di Server (Pilihan dari Scanner Dropdown)
function Teleport:ToPlayer(targetName: string): boolean
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and (player.Name:lower() == targetName:lower() or player.DisplayName:lower() == targetName:lower()) then
            local targetChar = player.Character
            local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
            if targetHrp then
                -- Tempatkan 4 studs di samping dengan orientasi menghadap target (mencegah clipping hitbox)
                local safePos = targetHrp.Position + Vector3.new(4, 1.5, 4)
                return self:To(CFrame.new(safePos, targetHrp.Position))
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
    print("[Bodoamat | Teleport] Berhasil menyimpan waypoint kustom: " .. cleanName)
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
        print("[Bodoamat | Totem] Totem tidak ditemukan di inventory atau tas!")
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
        print("[Bodoamat | Totem] Berhasil menempatkan totem: " .. totemTool.Name)
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

    print("[Bodoamat | Totem] Selesai formasi 5 Totem. Total terpasang: " .. tostring(deployedCount))
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
local Merchant = {
    IsOxygenActive = false,
    AntiDrownThread = nil :: thread?,
    IsRadarActive = false,
    RadarFolder = nil :: Folder?,
    RadarThread = nil :: thread?,
    ReturnGui = nil :: ScreenGui?,
}

-- Daftar Item Populer Toko & Merchant (Bait & Crates dihapus demi keamanan Anti BAC-7214)
Merchant.Items = {
    Totem = { "Luck Totem", "Shiny Totem", "Mutation Totem" },
    Weather = { "Storm", "Thunderstorm", "Blizzard", "Sandstorm", "Cloudy", "Wind" }
}

-- Buka Menu Toko / Black Market via Smart Teleport & Auto-Trigger Prompt
function Merchant:OpenRemoteShop(keyword: string?, network: any?): boolean
    local target = (keyword or "merchant"):lower()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then
        print("[Bodoamat | Merchant] Karakter tidak ditemukan.")
        return false
    end

    local savedSpot = hrp.CFrame
    local targetCFrame = nil
    local shopName = "Pedagang"

    if target:find("black") or target:find("market") or target:find("mariana") or target:find("gelap") then
        targetCFrame = CFrame.new(Vector3.new(-9255.90, -255.59, -1.05), Vector3.new(-9261.08, -255.59, -9.61))
        shopName = "Black Market (Mariana Trench)"
        -- Aktifkan proteksi O2 & Anti-Drown saat belanja di Mariana Trench
        pcall(function()
            self:StartAntiDrown()
            if network and network.EquipOxygenTank then
                network:EquipOxygenTank()
            end
            local bp = LocalPlayer:FindFirstChild("Backpack")
            if bp and char then
                for _, t in ipairs(bp:GetChildren()) do
                    if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                        t.Parent = char
                    end
                end
            end
        end)
    elseif target:find("cellar") then
        targetCFrame = CFrame.new(Vector3.new(2109.52, -94.19, -708.61), Vector3.new(2097.20, -94.19, -703.74))
        shopName = "Underground Cellar"
    else
        targetCFrame = CFrame.new(Vector3.new(-135.0, 3.5, 2764.0), Vector3.new(-140.0, 3.5, 2768.0))
        shopName = "Traveling Merchant (Pedagang Keliling)"
    end

    print("[Bodoamat | Merchant] Membuka " .. shopName .. "...")

    -- 1. Pindah ke lokasi toko secara aman (PivotTo + velocity reset anti-BAC)
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(targetCFrame + Vector3.new(0, 2.5, 0))
    end)

    -- 2. Tampilkan widget kembali ke spot memancing (Bebas BAC-4212: Tanpa trigger prompt buatan/bypass)
    self:ShowReturnWidget(shopName, savedSpot)

    return true
end

-- Widget banner kembali ke spot memancing semula setelah selesai belanja (Bebas BAC-4212)
function Merchant:ShowReturnWidget(shopTitle: string, returnCFrame: CFrame)
    if self.ReturnGui then
        self.ReturnGui:Destroy()
        self.ReturnGui = nil
    end

    local safeParent = nil
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then safeParent = h end
    end
    if not safeParent then
        safeParent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "Bodoamat_MerchantReturn"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100001
    gui.Parent = safeParent
    self.ReturnGui = gui

    local banner = Instance.new("Frame")
    banner.Size = UDim2.new(0, 440, 0, 84)
    banner.Position = UDim2.new(0.5, -220, 0, 20)
    banner.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    banner.BorderSizePixel = 0
    banner.Active = true
    banner.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = banner

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 180, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    stroke.Parent = banner

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 20)
    titleLbl.Position = UDim2.new(0, 10, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = shopTitle .. " (Sedang Dikunjungi)"
    titleLbl.TextColor3 = Color3.fromRGB(0, 215, 255)
    titleLbl.TextSize = 12
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextXAlignment = Enum.TextXAlignment.Center
    titleLbl.Parent = banner

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.new(1, -20, 0, 16)
    subLbl.Position = UDim2.new(0, 10, 0, 26)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "Tekan [E] atau tap pada NPC untuk belanja • Klik tombol jika sudah selesai"
    subLbl.TextColor3 = Color3.fromRGB(170, 180, 205)
    subLbl.TextSize = 10
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextXAlignment = Enum.TextXAlignment.Center
    subLbl.Parent = banner

    -- Tombol Kembali ke Spot Mancing
    local returnBtn = Instance.new("TextButton")
    returnBtn.Size = UDim2.new(0.68, -12, 0, 30)
    returnBtn.Position = UDim2.new(0, 10, 0, 46)
    returnBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 220)
    returnBtn.Text = "Selesai (Kembali ke Spot Mancing)"
    returnBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    returnBtn.TextSize = 11
    returnBtn.Font = Enum.Font.GothamBold
    returnBtn.Parent = banner

    local rCorner = Instance.new("UICorner")
    rCorner.CornerRadius = UDim.new(0, 6)
    rCorner.Parent = returnBtn

    returnBtn.MouseButton1Click:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
            if char and hrp and returnCFrame then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                char:PivotTo(returnCFrame + Vector3.new(0, 1.5, 0))
            end
        end)
        gui:Destroy()
        self.ReturnGui = nil
        print("[Bodoamat | Merchant] Berhasil kembali ke spot memancing semula.")
    end)

    -- Tombol Tetap Disini (Close Banner)
    local stayBtn = Instance.new("TextButton")
    stayBtn.Size = UDim2.new(0.32, -12, 0, 30)
    stayBtn.Position = UDim2.new(0.68, 4, 0, 46)
    stayBtn.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
    stayBtn.Text = "Tetap Disini"
    stayBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
    stayBtn.TextSize = 11
    stayBtn.Font = Enum.Font.GothamMedium
    stayBtn.Parent = banner

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = stayBtn

    stayBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        self.ReturnGui = nil
    end)
end

-- Beli Item Spesifik via Network Remote (Dengan Proteksi Jarak Anti BAC-4212)
function Merchant:BuyItem(itemName: string, network: any): boolean
    if not network then return false end

    -- Anti BAC-4212 Guard: Verifikasi pemain berdiri dekat lokasi toko/pedagang
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end

    local nearShop = false
    local shopSpots = {
        Vector3.new(-9255.90, -255.59, -1.05), -- Mariana Trench (Black Market)
        Vector3.new(-135.0, 3.5, 2764.0),       -- Traveling Merchant
    }
    for _, pos in ipairs(shopSpots) do
        if (hrp.Position - pos).Magnitude <= 45 then
            nearShop = true
            break
        end
    end

    if not nearShop then
        print("[Bodoamat | Merchant] Pembelian remote dicegah demi keamanan Anti BAC-4212. Buka toko langsung untuk belanja!")
        return false
    end

    local success = network:BuyItem(itemName)
    if success then
        print("[Bodoamat | Merchant] Berhasil membeli item: " .. itemName)
    else
        print("[Bodoamat | Merchant] Pembelian gagal atau koin tidak mencukupi: " .. itemName)
    end
    return success
end

-- Refresh Stok Merchant (Dengan Proteksi Jarak Anti BAC-4212)
function Merchant:RefreshStock(network: any): boolean
    if not network then return false end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end

    local nearShop = false
    local shopSpots = {
        Vector3.new(-9255.90, -255.59, -1.05),
        Vector3.new(-135.0, 3.5, 2764.0),
    }
    for _, pos in ipairs(shopSpots) do
        if (hrp.Position - pos).Magnitude <= 45 then
            nearShop = true
            break
        end
    end

    if not nearShop then
        print("[Bodoamat | Merchant] Refresh stok remote dicegah demi keamanan Anti BAC-4212.")
        return false
    end

    return network:RefreshMerchant()
end

-- Pasang Tabung Oksigen Laut Dalam (Mariana Trench & Lost Isle)
function Merchant:EquipOxygen(network: any): boolean
    self.IsOxygenActive = true

    -- 1. Panggil Remote Server dengan ID item 105 (Diving Gear) jika ada
    if network and network.EquipOxygenTank then
        pcall(function()
            network:EquipOxygenTank()
        end)
    end

    -- 2. Pasang Tool Oxygen dari Backpack ke Karakter jika ada
    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if char and bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                    t.Parent = char
                end
            end
        end
    end)

    -- 3. Aktifkan Sistem Proteksi Anti-Tenggelam (Anti-Drown)
    self:StartAntiDrown()
    print("[Bodoamat | Laut Dalam] Tabung Oksigen & Anti-Tenggelam Aktif! Karakter aman dari kehabisan nafas.")
    return true
end

-- Lepas Tabung Oksigen & Nonaktifkan Anti-Tenggelam
function Merchant:UnequipOxygen(): boolean
    self.IsOxygenActive = false

    -- Kembalikan Tool Oxygen ke Backpack
    pcall(function()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if char and bp then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                    t.Parent = bp
                end
            end
        end
    end)

    self:StopAntiDrown()
    print("[Bodoamat | Laut Dalam] Tabung Oksigen & Anti-Tenggelam Dinonaktifkan.")
    return true
end

function Merchant:StartAntiDrown()
    if self.AntiDrownThread then return end
    self.IsOxygenActive = true

    self.AntiDrownThread = task.spawn(function()
        while self.IsOxygenActive do
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hum and hrp then
                        -- Pasang tool oksigen ke karakter jika belum terpasang
                        local bp = LocalPlayer:FindFirstChild("Backpack")
                        if bp then
                            for _, t in ipairs(bp:GetChildren()) do
                                if t:IsA("Tool") and (string.find(t.Name:lower(), "oxygen") or string.find(t.Name:lower(), "tank") or string.find(t.Name:lower(), "diving")) then
                                    t.Parent = char
                                end
                            end
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)
end

function Merchant:StopAntiDrown()
    self.IsOxygenActive = false
    if self.AntiDrownThread then
        task.cancel(self.AntiDrownThread)
        self.AntiDrownThread = nil
    end
end

-- Aktifkan/Matikan Radar Ikan (Safe Client-Side ESP - Bebas BAC-5212)
function Merchant:ToggleRadar(arg1: any, arg2: any): boolean
    local enabled = true
    if type(arg1) == "boolean" then
        enabled = arg1
    elseif type(arg2) == "boolean" then
        enabled = arg2
    end
    self.IsRadarActive = enabled

    if enabled then
        self:StartRadar()
        print("[Bodoamat | Radar] Radar Ikan Visual Klien Aktif (Bebas BAC-5212).")
    else
        self:StopRadar()
        print("[Bodoamat | Radar] Radar Ikan: Nonaktif.")
    end
    return true
end

-- Radar Visual Klien: Menampilkan penanda lokasi spot mancing & event air terdekat
function Merchant:StartRadar()
    if self.RadarThread then return end
    self.IsRadarActive = true

    -- Buat container penanda radar
    local safeParent = nil
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then safeParent = h end
    end
    if not safeParent then
        safeParent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local radarFolder = Instance.new("Folder")
    radarFolder.Name = "Bodoamat_RadarMarkers"
    radarFolder.Parent = safeParent
    self.RadarFolder = radarFolder

    -- Daftar Spot Mancing Utama untuk Radar
    local keyFishingSpots = {
        { Name = "Coral Reef (Karang Tropis)", Pos = Vector3.new(-1200, 5, 800) },
        { Name = "Sunken Ship (Kapal Karam)", Pos = Vector3.new(1800, -80, 2400) },
        { Name = "Atlantis Ruins", Pos = Vector3.new(-3200, -350, -1800) },
        { Name = "Mariana Trench (Palung Dalam)", Pos = Vector3.new(-9255, -255, -1) },
        { Name = "Volcanic Island", Pos = Vector3.new(4500, 15, -3100) },
        { Name = "Lost Isle", Pos = Vector3.new(-6500, 10, 5200) },
    }

    self.RadarThread = task.spawn(function()
        while self.IsRadarActive do
            pcall(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local playerPos = hrp.Position

                -- 1. Deteksi Event Props / Ripple terdekat di Workspace
                local propsFolder = Workspace:FindFirstChild("Props")
                if propsFolder then
                    for _, prop in ipairs(propsFolder:GetChildren()) do
                        local propPos = nil
                        if prop:IsA("BasePart") then
                            propPos = prop.Position
                        elseif prop:IsA("Model") and prop.PrimaryPart then
                            propPos = prop.PrimaryPart.Position
                        elseif prop:IsA("Model") and prop:FindFirstChildWhichIsA("BasePart") then
                            propPos = prop:FindFirstChildWhichIsA("BasePart").Position
                        end

                        if propPos then
                            local dist = math.floor((playerPos - propPos).Magnitude)
                            if dist < 2000 then
                                local markerName = "Event_" .. prop.Name
                                local existing = radarFolder:FindFirstChild(markerName)
                                if not existing then
                                    local bb = Instance.new("BillboardGui")
                                    bb.Name = markerName
                                    bb.Size = UDim2.new(0, 160, 0, 32)
                                    bb.AlwaysOnTop = true
                                    bb.MaxDistance = 2500
                                    bb.Adornee = (prop:IsA("BasePart") and prop) or (prop:IsA("Model") and prop:FindFirstChildWhichIsA("BasePart"))
                                    bb.Parent = radarFolder

                                    local lbl = Instance.new("TextLabel")
                                    lbl.Name = "DistLabel"
                                    lbl.Size = UDim2.new(1, 0, 1, 0)
                                    lbl.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
                                    lbl.BackgroundTransparency = 0.2
                                    lbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                                    lbl.TextSize = 11
                                    lbl.Font = Enum.Font.GothamBold
                                    lbl.Text = string.format("%s\n[%dm]", prop.Name, dist)
                                    lbl.Parent = bb

                                    local c = Instance.new("UICorner")
                                    c.CornerRadius = UDim.new(0, 6)
                                    c.Parent = lbl
                                else
                                    local lbl = existing:FindFirstChild("DistLabel")
                                    if lbl and lbl:IsA("TextLabel") then
                                        lbl.Text = string.format("%s\n[%dm]", prop.Name, dist)
                                    end
                                end
                            end
                        end
                    end
                end

                -- 2. Update Marker Spot Mancing Utama
                for _, spot in ipairs(keyFishingSpots) do
                    local dist = math.floor((playerPos - spot.Pos).Magnitude)
                    local markerName = "Spot_" .. spot.Name:gsub("%s+", "_")
                    local existing = radarFolder:FindFirstChild(markerName)

                    if dist < 4000 then
                        if not existing then
                            local markerPart = Instance.new("Part")
                            markerPart.Name = markerName .. "_Anchor"
                            markerPart.Size = Vector3.new(1, 1, 1)
                            markerPart.Position = spot.Pos + Vector3.new(0, 15, 0)
                            markerPart.Anchored = true
                            markerPart.CanCollide = false
                            markerPart.Transparency = 1
                            markerPart.Parent = radarFolder

                            local bb = Instance.new("BillboardGui")
                            bb.Name = markerName
                            bb.Size = UDim2.new(0, 180, 0, 30)
                            bb.AlwaysOnTop = true
                            bb.MaxDistance = 5000
                            bb.Adornee = markerPart
                            bb.Parent = radarFolder

                            local lbl = Instance.new("TextLabel")
                            lbl.Name = "DistLabel"
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
                            lbl.BackgroundTransparency = 0.25
                            lbl.TextColor3 = Color3.fromRGB(0, 210, 255)
                            lbl.TextSize = 11
                            lbl.Font = Enum.Font.GothamBold
                            lbl.Text = string.format("%s\n[%dm]", spot.Name, dist)
                            lbl.Parent = bb

                            local c = Instance.new("UICorner")
                            c.CornerRadius = UDim.new(0, 6)
                            c.Parent = lbl
                        else
                            local lbl = existing:FindFirstChild("DistLabel")
                            if lbl and lbl:IsA("TextLabel") then
                                lbl.Text = string.format("%s\n[%dm]", spot.Name, dist)
                            end
                        end
                    elseif existing then
                        existing:Destroy()
                        local anchor = radarFolder:FindFirstChild(markerName .. "_Anchor")
                        if anchor then anchor:Destroy() end
                    end
                end
            end)
            task.wait(1.5)
        end
    end)
end

function Merchant:StopRadar()
    self.IsRadarActive = false
    if self.RadarThread then
        task.cancel(self.RadarThread)
        self.RadarThread = nil
    end
    if self.RadarFolder then
        self.RadarFolder:Destroy()
        self.RadarFolder = nil
    end
end

-- Beli Cuaca Server
function Merchant:SetWeather(weatherName: string, network: any): boolean
    if not network then return false end
    local success = network:PurchaseWeather(weatherName)
    if success then
        print("[Bodoamat | Cuaca] Berhasil memicu event cuaca: " .. weatherName)
    end
    return success
end

-- ============================================================
-- 12. UI: BODOAMAT GUI
-- ============================================================
local BodoamatGui = {
    ScreenGui = nil :: ScreenGui?,
    MainFrame = nil :: Frame?,
    CurrentTab = "Movement",
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
    if genv.__BODOAMAT_GPU_SAVER then
        pcall(function()
            genv.__BODOAMAT_GPU_SAVER:Destroy()
        end)
        genv.__BODOAMAT_GPU_SAVER = nil
    end

    -- Pulihkan rendering 3D otomatis dan uncap FPS jika sebelumnya tertinggal dalam mode GPU Saver
    pcall(function()
        RunService:Set3dRenderingEnabled(true)
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        local setfps = setfpscap or (genv and genv.setfpscap)
        if setfps then setfps(0) end
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
        end
    end)

    -- Bersihkan sisa GUI lama dari container jika ada
    pcall(function()
        local container = getSafeGuiContainer()
        if container then
            local oldGpu = container:FindFirstChild("Bodoamat_GpuSaver")
            if oldGpu then oldGpu:Destroy() end
            local oldHud = container:FindFirstChild("FishItHUD")
            if oldHud then oldHud:Destroy() end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local oldGpu = pg:FindFirstChild("Bodoamat_GpuSaver")
            if oldGpu then oldGpu:Destroy() end
        end
    end)

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

    -- 3. Frame Jendela Utama (Ukuran lebih lega dan mendukung Maximize)
    local cam = Workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    local initW = math.min(640, math.max(560, vp.X - 40))
    local initH = math.min(480, math.max(420, vp.Y - 40))

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, initW, 0, initH)
    mainFrame.Position = UDim2.new(0.5, -math.floor(initW / 2), 0.5, -math.floor(initH / 2))
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
    titleLabel.Text = config.UI.Title .. " v3.0"
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
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -74, 0, 9)
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

    -- Tombol Maximize / Perbesar Tampilan (Sebelah kanan dari tombol X)
    local maxBtn = Instance.new("TextButton")
    maxBtn.Name = "MaximizeButton"
    maxBtn.Size = UDim2.new(0, 30, 0, 30)
    maxBtn.Position = UDim2.new(1, -38, 0, 9)
    maxBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
    maxBtn.Text = "□"
    maxBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    maxBtn.TextSize = 15
    maxBtn.Font = Enum.Font.GothamBold
    maxBtn.Parent = header

    local maxCorner = Instance.new("UICorner")
    maxCorner.CornerRadius = UDim.new(0, 6)
    maxCorner.Parent = maxBtn

    local isMaximized = false
    maxBtn.MouseButton1Click:Connect(function()
        isMaximized = not isMaximized
        local currentCam = Workspace.CurrentCamera
        local currentVp = (currentCam and currentCam.ViewportSize) or Vector2.new(1280, 720)
        if isMaximized then
            local targetW = math.min(880, currentVp.X - 30)
            local targetH = math.min(620, currentVp.Y - 30)
            mainFrame.Size = UDim2.new(0, targetW, 0, targetH)
            mainFrame.Position = UDim2.new(0.5, -math.floor(targetW / 2), 0.5, -math.floor(targetH / 2))
            maxBtn.Text = "❐"
            maxBtn.TextColor3 = Color3.fromRGB(255, 180, 50)
            state.LastStatusMessage = "GUI diperbesar (Maximized)"
        else
            local targetW = math.min(640, math.max(560, currentVp.X - 40))
            local targetH = math.min(480, math.max(420, currentVp.Y - 40))
            mainFrame.Size = UDim2.new(0, targetW, 0, targetH)
            mainFrame.Position = UDim2.new(0.5, -math.floor(targetW / 2), 0.5, -math.floor(targetH / 2))
            maxBtn.Text = "□"
            maxBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
            state.LastStatusMessage = "GUI ukuran normal"
        end
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
        { Id = "Movement", Label = "Local Player" },
        { Id = "Selling",  Label = "Selling" },
        { Id = "Totem",    Label = "Totem" },
        { Id = "Teleport", Label = "Teleport" },
        { Id = "Optimasi", Label = "Optimasi" },
        { Id = "Status",   Label = "Status" },
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
    -- ISI KONTEN TAB 1: TOKO & JUAL
    -- ==========================================
    local sellPage = self.Tabs["Selling"]

    createToggle(sellPage, "Auto Sell Ikan", "Menjual hasil tangkapan otomatis secara berkala atau saat kapasitas tercapai", state.IsAutoSell, function(val)
        state:Set("IsAutoSell", val)
        if val then
            modules.AutoSell:Start(config.AutoSell.Interval, modules.Network, state, modules.Teleport)
        else
            modules.AutoSell:Stop()
        end
    end)

    -- Input Kapasitas Ikan (Threshold Auto-Sell: misal 100 -> jika 101 otomatis jual)
    local thresholdCard = Instance.new("Frame")
    thresholdCard.Size = UDim2.new(1, -4, 0, 48)
    thresholdCard.BackgroundColor3 = config.UI.Theme.CardBg
    thresholdCard.BorderSizePixel = 0
    thresholdCard.Parent = sellPage

    local tCorner = Instance.new("UICorner")
    tCorner.CornerRadius = UDim.new(0, 8)
    tCorner.Parent = thresholdCard

    local tLabel = Instance.new("TextLabel")
    tLabel.Size = UDim2.new(1, -110, 0, 20)
    tLabel.Position = UDim2.new(0, 12, 0, 6)
    tLabel.BackgroundTransparency = 1
    tLabel.Text = "Batas Jumlah Ikan (Threshold Auto Sell)"
    tLabel.TextColor3 = config.UI.Theme.Text
    tLabel.TextSize = 11
    tLabel.Font = Enum.Font.GothamBold
    tLabel.TextXAlignment = Enum.TextXAlignment.Left
    tLabel.Parent = thresholdCard

    local tSub = Instance.new("TextLabel")
    tSub.Size = UDim2.new(1, -110, 0, 14)
    tSub.Position = UDim2.new(0, 12, 0, 26)
    tSub.BackgroundTransparency = 1
    tSub.Text = "Contoh: 100 (Ikan ke-101 otomatis terjual)"
    tSub.TextColor3 = config.UI.Theme.TextSubtle
    tSub.TextSize = 9
    tSub.Font = Enum.Font.Gotham
    tSub.TextXAlignment = Enum.TextXAlignment.Left
    tSub.Parent = thresholdCard

    local tBox = Instance.new("TextBox")
    tBox.Size = UDim2.new(0, 85, 0, 30)
    tBox.Position = UDim2.new(1, -97, 0, 9)
    tBox.BackgroundColor3 = Color3.fromRGB(35, 38, 52)
    tBox.BorderSizePixel = 0
    tBox.Text = tostring(modules.AutoSell.MaxFishThreshold or (config.AutoSell and config.AutoSell.Threshold) or 100)
    tBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    tBox.PlaceholderText = "100"
    tBox.PlaceholderColor3 = Color3.fromRGB(130, 135, 150)
    tBox.TextSize = 12
    tBox.Font = Enum.Font.GothamBold
    tBox.ClearTextOnFocus = false
    tBox.Parent = thresholdCard

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 6)
    tbCorner.Parent = tBox

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = config.UI.Theme.Border
    tbStroke.Thickness = 1
    tbStroke.Parent = tBox

    tBox.FocusLost:Connect(function()
        local num = tonumber(tBox.Text)
        if num and num >= 0 then
            num = math.floor(num)
            modules.AutoSell:SetThreshold(num)
            if config.AutoSell then config.AutoSell.Threshold = num end
            tBox.Text = tostring(num)
        else
            tBox.Text = tostring(modules.AutoSell.MaxFishThreshold)
        end
    end)


    createToggle(sellPage, "Auto Favorite Ikan Langka", "Mengunci otomatis ikan bernilai tinggi (Legendary/Mitos/Secret) agar tidak terjual", modules.AutoSell.AutoFavoriteEnabled, function(val)
        state:Set("IsAutoFavorite", val)
        modules.AutoSell:SetAutoFavorite(val, modules.Network)
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
    rTitle.Text = "Tingkat Kelangkaan Minimal yang Diamankan"
    rTitle.TextColor3 = config.UI.Theme.Text
    rTitle.TextSize = 11
    rTitle.Font = Enum.Font.GothamBold
    rTitle.TextXAlignment = Enum.TextXAlignment.Left
    rTitle.Parent = rarityCard

    local rButtons = {}
    local rList = { "Legendary", "Mitos", "Secret" }
    local rContainer = Instance.new("Frame")
    rContainer.Size = UDim2.new(1, -24, 0, 28)
    rContainer.Position = UDim2.new(0, 12, 0, 28)
    rContainer.BackgroundTransparency = 1
    rContainer.Parent = rarityCard

    local rLayout = Instance.new("UIListLayout")
    rLayout.FillDirection = Enum.FillDirection.Horizontal
    rLayout.Padding = UDim.new(0, 6)
    rLayout.Parent = rContainer

    for _, rName in ipairs(rList) do
        local rBtn = Instance.new("TextButton")
        rBtn.Size = UDim2.new(0.32, 0, 1, 0)
        rBtn.BackgroundColor3 = (modules.AutoSell.MinFavoriteRarity == rName) and config.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        rBtn.Text = rName
        rBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        rBtn.TextSize = 10
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
            print("[Bodoamat] Min Favorite Rarity diset ke: " .. rName .. "+")
        end)
    end

    createActionButton(sellPage, "Kunci / Amankan Ikan Langka Sekarang", "Scan isi tas & kunci ikan sesuai tier yang dipilih (Legendary/Mitos/Secret)", function()
        local count = modules.AutoSell:ProtectAndFavorite(modules.Network)
        print("[Bodoamat | Proteksi] Selesai scan: " .. tostring(count) .. " ikan baru diamankan.")
    end)

    local sellDebounce = false
    createActionButton(sellPage, "Jual Semua Ikan Sekarang (Aman Ikan Langka)", "Otomatis mengunci ikan sesuai tier yang dipilih sebelum menjual", function()
        if sellDebounce then return end
        sellDebounce = true
        modules.AutoSell:ExecuteSell(modules.Network, state, modules.Teleport)
        task.wait(2.5)
        sellDebounce = false
    end)

    createSectionHeader(sellPage, "TOKO & BLACK MARKET (KUNJUNGAN AMAN)")

    createActionButton(sellPage, "Buka Black Market (Mariana Trench)", "Kunjungi Black Market di Mariana Trench secara aman, auto pakai O2 & kembali dengan 1 klik", function()
        modules.Merchant:OpenRemoteShop("blackmarket", modules.Network)
    end)

    createActionButton(sellPage, "Buka Pedagang Keliling (Traveling Merchant)", "Kunjungi Kapal Pedagang Alien secara aman, belanja langsung di NPC & kembali dengan 1 klik", function()
        modules.Merchant:OpenRemoteShop("traveling", modules.Network)
    end)

    -- ==========================================
    -- ISI KONTEN TAB 3: TOTEM & LAUT DALAM
    -- ==========================================
    local totemPage = self.Tabs["Totem"]

    createSectionHeader(totemPage, "KELOLA & PASANG TOTEM")

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

    createSectionHeader(totemPage, "EKSPLORASI LAUT DALAM & RADAR")

    createToggle(totemPage, "Tabung Oksigen Laut Dalam", "Aktifkan O2 tank agar tidak tenggelam di Mariana Trench & Lost Isle", state.IsOxygenEquipped, function(val)
        state:Set("IsOxygenEquipped", val)
        if val then
            modules.Merchant:EquipOxygen(modules.Network)
        else
            modules.Merchant:UnequipOxygen()
        end
    end)

    createToggle(totemPage, "Fishing Radar (Deteksi Ikan)", "Menampilkan posisi dan rarity ikan di sekitar air (Bebas BAC-5212)", state.IsRadar, function(val)
        state:Set("IsRadar", val)
        modules.Merchant:ToggleRadar(val, modules.Network)
    end)

    createSectionHeader(totemPage, "KONTROL CUACA SERVER")

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

    createSectionHeader(tpPage, "TELEPORT KE PEMAIN LAIN")

    -- Scanner Pemain & Dropdown Teleport
    local playerScanCard = Instance.new("Frame")
    playerScanCard.Size = UDim2.new(1, -4, 0, 0)
    playerScanCard.AutomaticSize = Enum.AutomaticSize.Y
    playerScanCard.BackgroundColor3 = config.UI.Theme.CardBg
    playerScanCard.BorderSizePixel = 0
    playerScanCard.Parent = tpPage

    local psCorner = Instance.new("UICorner")
    psCorner.CornerRadius = UDim.new(0, 8)
    psCorner.Parent = playerScanCard

    local psPadding = Instance.new("UIPadding")
    psPadding.PaddingTop = UDim.new(0, 8)
    psPadding.PaddingBottom = UDim.new(0, 8)
    psPadding.PaddingLeft = UDim.new(0, 10)
    psPadding.PaddingRight = UDim.new(0, 10)
    psPadding.Parent = playerScanCard

    local psLayout = Instance.new("UIListLayout")
    psLayout.Padding = UDim.new(0, 6)
    psLayout.SortOrder = Enum.SortOrder.LayoutOrder
    psLayout.Parent = playerScanCard

    -- Baris Atas: Label & Tombol Scan Player
    local topRow = Instance.new("Frame")
    topRow.Size = UDim2.new(1, 0, 0, 28)
    topRow.BackgroundTransparency = 1
    topRow.LayoutOrder = 1
    topRow.Parent = playerScanCard

    local psTitle = Instance.new("TextLabel")
    psTitle.Size = UDim2.new(1, -110, 1, 0)
    psTitle.BackgroundTransparency = 1
    psTitle.Text = "Scanner Pemain Aktif"
    psTitle.TextColor3 = config.UI.Theme.Text
    psTitle.TextSize = 11
    psTitle.Font = Enum.Font.GothamBold
    psTitle.TextXAlignment = Enum.TextXAlignment.Left
    psTitle.Parent = topRow

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, 100, 1, 0)
    scanBtn.Position = UDim2.new(1, -100, 0, 0)
    scanBtn.BackgroundColor3 = config.UI.Theme.Accent
    scanBtn.Text = "Scan Player"
    scanBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    scanBtn.TextSize = 10
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.Parent = topRow

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 6)
    sbCorner.Parent = scanBtn

    -- Label Status Hasil Scan
    local scanStatusLbl = Instance.new("TextLabel")
    scanStatusLbl.Size = UDim2.new(1, 0, 0, 14)
    scanStatusLbl.BackgroundTransparency = 1
    scanStatusLbl.Text = "Klik 'Scan Player' untuk mendeteksi pemain di server"
    scanStatusLbl.TextColor3 = config.UI.Theme.TextSubtle
    scanStatusLbl.TextSize = 10
    scanStatusLbl.Font = Enum.Font.Gotham
    scanStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    scanStatusLbl.LayoutOrder = 2
    scanStatusLbl.Parent = playerScanCard

    -- Dropdown Trigger Button
    local selectedPlayerName = ""
    local isDropdownOpen = false

    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Size = UDim2.new(1, 0, 0, 30)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(32, 36, 48)
    dropdownBtn.Text = "  Pilih Pemain (Klik Scan)..."
    dropdownBtn.TextColor3 = Color3.fromRGB(200, 205, 220)
    dropdownBtn.TextSize = 11
    dropdownBtn.Font = Enum.Font.GothamMedium
    dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropdownBtn.LayoutOrder = 3
    dropdownBtn.Parent = playerScanCard

    local ddCorner = Instance.new("UICorner")
    ddCorner.CornerRadius = UDim.new(0, 6)
    ddCorner.Parent = dropdownBtn

    local arrowLbl = Instance.new("TextLabel")
    arrowLbl.Size = UDim2.new(0, 24, 1, 0)
    arrowLbl.Position = UDim2.new(1, -26, 0, 0)
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Text = "▼"
    arrowLbl.TextColor3 = config.UI.Theme.TextSubtle
    arrowLbl.TextSize = 10
    arrowLbl.Font = Enum.Font.GothamBold
    arrowLbl.Parent = dropdownBtn

    -- Dropdown Scrollable List Menu
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Size = UDim2.new(1, 0, 0, 110)
    dropdownList.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    dropdownList.BorderSizePixel = 0
    dropdownList.ScrollBarThickness = 3
    dropdownList.ScrollBarImageColor3 = config.UI.Theme.Accent
    dropdownList.Visible = false
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdownList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    dropdownList.LayoutOrder = 4
    dropdownList.Parent = playerScanCard

    local ddlCorner = Instance.new("UICorner")
    ddlCorner.CornerRadius = UDim.new(0, 6)
    ddlCorner.Parent = dropdownList

    local ddlPadding = Instance.new("UIPadding")
    ddlPadding.PaddingTop = UDim.new(0, 4)
    ddlPadding.PaddingBottom = UDim.new(0, 4)
    ddlPadding.PaddingLeft = UDim.new(0, 4)
    ddlPadding.PaddingRight = UDim.new(0, 4)
    ddlPadding.Parent = dropdownList

    local ddlLayout = Instance.new("UIListLayout")
    ddlLayout.Padding = UDim.new(0, 3)
    ddlLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ddlLayout.Parent = dropdownList

    -- Tombol Teleport ke Pemain
    local tpExecBtn = Instance.new("TextButton")
    tpExecBtn.Size = UDim2.new(1, 0, 0, 30)
    tpExecBtn.BackgroundColor3 = config.UI.Theme.Success
    tpExecBtn.Text = "Teleport ke Pemain Terpilih"
    tpExecBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpExecBtn.TextSize = 11
    tpExecBtn.Font = Enum.Font.GothamBold
    tpExecBtn.LayoutOrder = 5
    tpExecBtn.Parent = playerScanCard

    local teCorner = Instance.new("UICorner")
    teCorner.CornerRadius = UDim.new(0, 6)
    teCorner.Parent = tpExecBtn

    -- Handler Toggle Dropdown
    dropdownBtn.MouseButton1Click:Connect(function()
        isDropdownOpen = not isDropdownOpen
        dropdownList.Visible = isDropdownOpen
        arrowLbl.Text = isDropdownOpen and "▲" or "▼"
    end)

    -- Handler Scan Player
    scanBtn.MouseButton1Click:Connect(function()
        local playersList = modules.Teleport:ScanPlayers()
        for _, child in ipairs(dropdownList:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end

        if #playersList == 0 then
            scanStatusLbl.Text = "Tidak ada pemain lain di server."
            scanStatusLbl.TextColor3 = Color3.fromRGB(240, 160, 60)
            dropdownBtn.Text = "  (Server Kosong)"
            selectedPlayerName = ""
            return
        end

        scanStatusLbl.Text = string.format("Ditemukan %d pemain aktif di server.", #playersList)
        scanStatusLbl.TextColor3 = config.UI.Theme.Success

        for _, pInfo in ipairs(playersList) do
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(1, -4, 0, 24)
            pBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
            pBtn.Text = "  " .. pInfo.DisplayName .. " (@" .. pInfo.Name .. ")"
            pBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
            pBtn.TextSize = 10
            pBtn.Font = Enum.Font.GothamMedium
            pBtn.TextXAlignment = Enum.TextXAlignment.Left
            pBtn.Parent = dropdownList

            local pbCorner = Instance.new("UICorner")
            pbCorner.CornerRadius = UDim.new(0, 4)
            pbCorner.Parent = pBtn

            pBtn.MouseButton1Click:Connect(function()
                selectedPlayerName = pInfo.Name
                dropdownBtn.Text = "  " .. pInfo.DisplayName .. " (@" .. pInfo.Name .. ")"
                isDropdownOpen = false
                dropdownList.Visible = false
                arrowLbl.Text = "▼"
            end)
        end

        -- Otomatis set pemain pertama jika belum memilih
        if selectedPlayerName == "" and #playersList > 0 then
            selectedPlayerName = playersList[1].Name
            dropdownBtn.Text = "  " .. playersList[1].DisplayName .. " (@" .. playersList[1].Name .. ")"
        end
    end)

    -- Handler Tombol Teleport
    tpExecBtn.MouseButton1Click:Connect(function()
        if selectedPlayerName == "" then
            scanStatusLbl.Text = "Silakan klik 'Scan Player' dan pilih pemain!"
            scanStatusLbl.TextColor3 = Color3.fromRGB(240, 80, 80)
            return
        end

        local ok = modules.Teleport:ToPlayer(selectedPlayerName)
        if ok then
            state.LastStatusMessage = "TP ke pemain: " .. selectedPlayerName
            scanStatusLbl.Text = "Berhasil teleport ke @" .. selectedPlayerName
            scanStatusLbl.TextColor3 = config.UI.Theme.Success
        else
            scanStatusLbl.Text = "Gagal TP: Pemain @" .. selectedPlayerName .. " tidak ditemukan/mati"
            scanStatusLbl.TextColor3 = Color3.fromRGB(240, 80, 80)
        end
    end)


    createSectionHeader(tpPage, "SIMPAN TITIK KUSTOM (WAYPOINT)")
    createTextInput(tpPage, "Beri nama titik kustom...", "Simpan Posisi", function(wpName)
        modules.Teleport:SaveCurrentPosition(wpName)
        state.LastStatusMessage = "Waypoint tersimpan: " .. wpName
    end)

    createSectionHeader(tpPage, "DAFTAR LOKASI RESMI (SEMUA ZONA)")

    local locContainer = Instance.new("Frame")
    locContainer.Size = UDim2.new(1, 0, 0, 0)
    locContainer.AutomaticSize = Enum.AutomaticSize.Y
    locContainer.BackgroundTransparency = 1
    locContainer.Parent = tpPage

    local lcLayout = Instance.new("UIListLayout")
    lcLayout.Padding = UDim.new(0, 5)
    lcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    lcLayout.Parent = locContainer

    -- Pastikan daftar selalu terurut ascending A-Z
    table.sort(modules.Teleport.Locations, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    for _, loc in ipairs(modules.Teleport.Locations) do
        local tpCard = Instance.new("Frame")
        tpCard.Size = UDim2.new(1, -4, 0, 34)
        tpCard.BackgroundColor3 = config.UI.Theme.CardBg
        tpCard.BorderSizePixel = 0
        tpCard.Parent = locContainer

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 6)
        cCorner.Parent = tpCard

        local locLabel = Instance.new("TextLabel")
        locLabel.Size = UDim2.new(1, -85, 1, 0)
        locLabel.Position = UDim2.new(0, 10, 0, 0)
        locLabel.BackgroundTransparency = 1
        locLabel.Text = loc.Name
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
                state.LastStatusMessage = "Teleport ke " .. loc.Name
            end
        end)
    end

    -- ==========================================
    -- ISI KONTEN TAB: LOCAL PLAYER (MOVEMENT)
    -- ==========================================
    local movePage = self.Tabs["Movement"]

    createSectionHeader(movePage, "MOVEMENT")

    createToggle(movePage, "Walk On Water (Jesus Walk)", "Berjalan di atas permukaan air laut tanpa jatuh", state.IsWaterWalk, function(val)
        state:Set("IsWaterWalk", val)
        modules.Movement:SetWaterWalk(val)
    end)

    createToggle(movePage, "Infinite Jump", "Lompat bebas di udara tanpa batas", state.IsInfJump, function(val)
        state:Set("IsInfJump", val)
        modules.Movement:SetInfiniteJump(val)
    end)

    createTextInput(movePage, "Kekuatan lompatan (50 - 250)...", "Set Jump Power", function(val)
        local num = tonumber(val)
        if num then
            modules.Movement:SetJumpPower(num)
            state.LastStatusMessage = "Jump Power diset: " .. tostring(num)
        end
    end)



    -- ==========================================
    -- ISI KONTEN TAB 6: OPTIMASI & PERFORMA
    -- ==========================================
    local optPage = self.Tabs["Optimasi"]

    createToggle(optPage, "FPS Booster (Safe Anti-BAC)", "Menonaktifkan partikel berat & bloom (Tanpa tamper parts)", state.IsFpsBoost, function(val)
        state:Set("IsFpsBoost", val)
        modules.FpsBooster:SetFpsBoost(val)
    end)

    createToggle(optPage, "Ultra GPU Saver (AFK Safe)", "Turunkan FPS ke 15 & grafis ringan saat AFK (Bebas BAC-1216)", state.IsGpuSaver, function(val)
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
            local o2Status = state.IsOxygenEquipped and "<font color='#2ecc71'>Aktif</font>" or "<font color='#e74c3c'>Mati</font>"
            local radarStatus = state.IsRadar and "<font color='#2ecc71'>Aktif</font>" or "<font color='#e74c3c'>Mati</font>"

            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
            local posStr = hrp and string.format("%.1f, %.1f, %.1f", hrp.Position.X, hrp.Position.Y, hrp.Position.Z) or "N/A"

            statText.Text = string.format(
                "<b>INFORMASI LIVE SESSION:</b>\n\n" ..
                "• <b>Durasi Sesi:</b> <font color='#00d2ff'>%s</font>\n" ..
                "• <b>Mode Memancing:</b> <font color='#2ecc71'>Manual Alami (Bebas BAC)</font>\n" ..
                "• <b>Proteksi Ikan Langka:</b> <font color='#2ecc71'>Aktif (Tier %s+)</font>\n" ..
                "• <b>Tabung Oksigen:</b> %s | <b>Radar:</b> %s\n" ..
                "• <b>Posisi Karakter:</b> <font color='#9b59b6'>%s</font>\n" ..
                "• <b>Status Sistem:</b> %s\n\n" ..
                "<b>STATUS KEAMANAN (ANTI-BAC):</b>\n" ..
                "• <b>Fishing BAC Guard:</b> <font color='#2ecc71'>100%% Aman (Manual Murni)</font>\n" ..
                "• <b>Fishing State Guard:</b> <font color='#2ecc71'>Aktif (BAC-6219 Guard)</font>\n" ..
                "• <b>Safe Sell Guard:</b> <font color='#2ecc71'>Aktif (Auto-Favorite Sebelum Jual)</font>\n" ..
                "• <b>Workspace Part Tamper:</b> <font color='#2ecc71'>Dihapus (BAC-6228 Guard)</font>\n" ..
                "• <b>GPU Saver Mode:</b> <font color='#2ecc71'>Engine Raster Standby</font>",
                elapsed, tostring(state.MinFavoriteRarity or "Rare"), o2Status, radarStatus, posStr, tostring(state.LastStatusMessage or "Siap")
            )
            task.wait(1)
        end
    end)

    -- 6. Tombol Floating Buka/Tutup GUI untuk Mobile (Touch Draggable)
    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "AppFloatingBtn"
    mobileBtn.Size = UDim2.new(0, 56, 0, 30)
    mobileBtn.Position = UDim2.new(0, 20, 0.5, -15)
    mobileBtn.BackgroundColor3 = config.UI.Theme.CardBg
    mobileBtn.Text = "MENU"
    mobileBtn.TextColor3 = config.UI.Theme.Text
    mobileBtn.TextSize = 11
    mobileBtn.Font = Enum.Font.GothamBold
    mobileBtn.Active = true
    mobileBtn.Parent = screenGui

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 6)
    mbCorner.Parent = mobileBtn

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = config.UI.Theme.Accent
    mbStroke.Thickness = 1.2
    mbStroke.Parent = mobileBtn

    -- Logika Dragging Tombol Mobile
    local mbDragging, mbDragStart, mbStartPos, mbHasMoved
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

    UserInputService.InputChanged:Connect(function(input)
        if mbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - mbDragStart
            if delta.Magnitude > 5 then
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
    self:SwitchTab("Movement", config)

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
    print("BODOAMAT v3.0 (Stealth Anti-BAC / Delta) - Memulai...")
    print("================================================")

    -- Buat Tampilan GUI Secara Instan (0 Detik)
    BodoamatGui:Create(Config, State, Modules)

    -- Inisialisasi Jaringan Stealth di Background (Non-blocking)
    task.spawn(function()
        Network:Init()
    end)

    print("[Bodoamat v3.0] Berhasil dimuat! Tekan RightShift atau sentuh tombol MENU untuk membuka menu.")
end

Init()
return Modules
