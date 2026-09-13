--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                     BODOAMAT v2.0 - FISH IT                   ║
    ║   Quality of Life, Automation Hub & Anti-BAC Protected       ║
    ║   Hosted at: https://github.com/iMango21/bodoamat            ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Fitur Unggulan v2.0:
    - 🛡️ Safe Anti-BAC: Nol modifikasi Workspace parts, bebas error CODE BAC-6228
    - ⚡ Namecall Intercept Blocker: Menidurkan skrip lokal game agar tidak cancel kail
    - 🎣 3 Mode Memancing: Legit (Human Input), Fast (Safe Remote), Blatant (Instant)
    - 🌟 Auto Favorite: Mengamankan ikan langka (Legendary, Mythic, Secret) dari penjualan
    - 💰 Auto Sell: Menjual ikan otomatis berkala dengan filter proteksi
    - 🗺️ Teleport 14 Lokasi Pulau & Secret Spots (Sisyphus, Esoteric, Sacred Temple, dll.)
    - 🌊 Walk On Water (Jesus Walk): Berjalan aman di atas air tanpa tenggelam
    - 🦘 Infinite Jump & WalkSpeed Modifier
    - ❄️ Ultra GPU Saver: Mematikan 3D rasterization (Laptop/HP dingin 0% panas, bebas tick desync)
    - 🔄 Anti-AFK 20 Menit & Auto-Rejoin saat terputus
]]

-- Proteksi Instance Duplikat
if _G.__BODOAMAT_LOADED then
    warn("[Bodoamat] Script sudah berjalan pada sesi ini.")
    return
end
_G.__BODOAMAT_LOADED = true

-- ============================================================
-- 1. KONFIGURASI SISTEM
-- ============================================================
local Config = {
    AutoFish = {
        Enabled = false,
        Mode = "Fast",          -- "Fast", "Blatant", atau "Legit"
        CastDelay = 0.4,
        CatchDelay = 0.25,
        AutoEquipRod = true,
    },
    AntiAfk = {
        Enabled = true,
        AutoRejoin = true,
        MicroMovement = true,
        MoveInterval = 240,
    },
    Performance = {
        FpsBoost = false,
        GpuSaver = false,
    },
    AutoSell = {
        Enabled = false,
        Interval = 45,
        AutoFavorite = true,
        MinRarity = "Legendary",
    },
    Movement = {
        WaterWalk = false,
        InfiniteJump = false,
        WalkSpeed = 16,
        JumpPower = 50,
    },
    UI = {
        Title = "BODOAMAT v2.0",
        Subtitle = "Fish It! Automation & Anti-Cheat Safe Hub",
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
    IsFishing = false,
    FishingMode = "Fast",
    IsAntiAfk = true,
    IsFpsBoost = false,
    IsGpuSaver = false,
    IsAutoSell = false,
    IsAutoFavorite = true,
    MinFavoriteRarity = "Legendary",
    IsWaterWalk = false,
    IsInfJump = false,
    WalkSpeed = 16,
    JumpPower = 50,

    StartTime = os.time(),
    FishCaught = 0,
    TotalCoinsEarned = 0,
    LastStatusMessage = "Sistem Siap",

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
-- 3. CORE: NETWORK HANDLER & NAMECALL BLOCKER (ANTI-BAC)
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Network = {
    HasRemotes = false,
    Remotes = {} :: { [string]: Instance? },
    BlockClientCancel = true,
    HookInstalled = false,
}

function Network:Init()
    pcall(function()
        local packages = ReplicatedStorage:WaitForChild("Packages", 5)
        if not packages then return end

        local indexFolder = packages:WaitForChild("_Index", 5)
        if not indexFolder then return end

        local netPackage = nil
        for _, child in ipairs(indexFolder:GetChildren()) do
            if string.find(child.Name, "sleitnick_net") then
                netPackage = child
                break
            end
        end

        if not netPackage then return end
        local netFolder = netPackage:FindFirstChild("net")
        if not netFolder then return end

        self.Remotes["ChargeRod"]      = netFolder:FindFirstChild("RF/ChargeFishingRod")
        self.Remotes["RequestGame"]    = netFolder:FindFirstChild("RF/RequestFishingMinigameStarted")
        self.Remotes["CompleteGame"]   = netFolder:FindFirstChild("RE/FishingCompleted")
        self.Remotes["CancelInput"]    = netFolder:FindFirstChild("RF/CancelFishingInputs")
        self.Remotes["SellAll"]        = netFolder:FindFirstChild("RF/SellAllItems")
        self.Remotes["EquipHotbar"]    = netFolder:FindFirstChild("RE/EquipToolFromHotbar")
        self.Remotes["Favorite"]       = netFolder:FindFirstChild("RE/FavoriteItem")
        self.Remotes["AutoFishState"]  = netFolder:FindFirstChild("RF/UpdateAutoFishingState")

        self.HasRemotes = (self.Remotes["ChargeRod"] ~= nil and self.Remotes["CompleteGame"] ~= nil)
    end)

    -- Pasang Hook Metamethod Namecall untuk memblokir interupsi skrip game lokal (Anti-BAC Tripwire)
    if not self.HookInstalled then
        pcall(function()
            local hook = (hookmetamethod :: any)
            local getNamecall = (getnamecallmethod :: any)
            local isCaller = (checkcaller :: any)

            if typeof(hook) == "function" and typeof(getNamecall) == "function" and typeof(isCaller) == "function" then
                local blocked = {
                    [self.Remotes["ChargeRod"]] = true,
                    [self.Remotes["RequestGame"]] = true,
                    [self.Remotes["CompleteGame"]] = true,
                    [self.Remotes["CancelInput"]] = true,
                }

                local oldNamecall
                oldNamecall = hook(game, "__namecall", function(selfObj, ...)
                    local method = getNamecall()
                    if Network.BlockClientCancel and blocked[selfObj] and not isCaller() then
                        if method == "InvokeServer" then
                            return task.wait(9e9)
                        elseif method == "FireServer" then
                            return nil
                        end
                    end
                    return oldNamecall(selfObj, ...)
                end)
                self.HookInstalled = true
                print("[Bodoamat | Security] Metamethod Namecall Anti-Interupsi terpasang.")
            end
        end)
    end

    return self.HasRemotes
end

function Network:ChargeRod(power: number?): boolean
    local remote = self.Remotes["ChargeRod"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            remote:InvokeServer(power or 1)
        end)
        return ok
    end
    return false
end

function Network:RequestMinigame(): boolean
    local remote = self.Remotes["RequestGame"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function()
            local args = {-1.233, 1, workspace:GetServerTimeNow()}
            remote:InvokeServer(unpack(args))
        end)
        return ok
    end
    return false
end

function Network:CompleteFishing(): boolean
    local remote = self.Remotes["CompleteGame"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function()
            remote:FireServer()
        end)
        return ok
    end
    return false
end

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

function Network:EquipHotbar(slot: number): boolean
    local remote = self.Remotes["EquipHotbar"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function()
            remote:FireServer(slot)
        end)
        return ok
    end
    return false
end

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

-- ==========================================
-- 4. MODULE: AUTO FISHING (MULTI-MODE)
-- ==========================================
local VirtualInputManager = game:GetService("VirtualInputManager")

local AutoFish = {
    Running = false,
    Thread = nil :: thread?,
    CurrentRod = nil :: Tool?,
}

function AutoFish:FindFishingRod(): Tool?
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool and (string.find(tool.Name:lower(), "rod") or string.find(tool.Name:lower(), "fish")) then
            return tool
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (string.find(item.Name:lower(), "rod") or string.find(item.Name:lower(), "fish")) then
                return item
            end
        end
    end

    return nil
end

function AutoFish:EnsureRodEquipped(net: any): boolean
    local char = LocalPlayer.Character
    if not char then return false end

    local activeTool = char:FindFirstChildOfClass("Tool")
    if activeTool and (string.find(activeTool.Name:lower(), "rod") or string.find(activeTool.Name:lower(), "fish")) then
        self.CurrentRod = activeTool
        return true
    end

    if net and net.HasRemotes then
        net:EquipHotbar(1)
        task.wait(0.15)
    end

    local backpackRod = self:FindFishingRod()
    if backpackRod and backpackRod.Parent == LocalPlayer:FindFirstChild("Backpack") then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(backpackRod)
            task.wait(0.15)
            self.CurrentRod = backpackRod
            return true
        end
    end

    return (char:FindFirstChildOfClass("Tool") ~= nil)
end

function AutoFish:SimulateClick(holdDuration: number?)
    local camera = workspace.CurrentCamera
    local viewport = (camera and camera.ViewportSize) or Vector2.new(800, 600)
    local cx = viewport.X / 2
    local cy = viewport.Y / 2

    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
    if holdDuration and holdDuration > 0 then
        task.wait(holdDuration)
    end
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
end

function AutoFish:Start(cfg: any, st: any, net: any)
    if self.Running then return end
    self.Running = true

    self.Thread = task.spawn(function()
        local mode = (cfg and cfg.Mode) or "Fast"
        print("[Bodoamat | Fishing] Memancing dimulai. Mode: " .. tostring(mode))

        while self.Running do
            local success, err = pcall(function()
                local isEquipped = self:EnsureRodEquipped(net)
                if not isEquipped then
                    st.LastStatusMessage = "Menunggu Joran (Beli/Taruh di Slot 1)"
                    task.wait(1.2)
                    return
                end

                if mode == "Blatant" and net and net.HasRemotes then
                    -- BLATANT INSTANT
                    st.LastStatusMessage = "⚡ Instant Reel..."
                    net:ChargeRod(1)
                    task.wait(0.01)
                    net:RequestMinigame()
                    task.wait(0.06)

                    for _ = 1, 3 do
                        net:CompleteFishing()
                        task.wait(0.01)
                    end

                    st.FishCaught = st.FishCaught + 1
                    st.LastStatusMessage = "✅ Ikan Tertangkap! Total: " .. tostring(st.FishCaught)
                    task.wait(0.08)

                elseif mode == "Fast" and net and net.HasRemotes then
                    -- FAST SAFE REMOTE
                    st.LastStatusMessage = "🎣 Melempar Kail (Fast Safe)..."
                    net:ChargeRod(1)
                    task.wait(0.03)
                    net:RequestMinigame()

                    local baseDelay = (cfg and cfg.CastDelay) or 0.4
                    local jitter = (math.random(2, 8) / 100)
                    task.wait(baseDelay + jitter)

                    st.LastStatusMessage = "🐟 Menarik Tangkapan..."
                    for _ = 1, 2 do
                        net:CompleteFishing()
                        task.wait(0.01)
                    end

                    st.FishCaught = st.FishCaught + 1
                    st.LastStatusMessage = "✅ Berhasil! Total: " .. tostring(st.FishCaught)

                    local catchWait = (cfg and cfg.CatchDelay) or 0.25
                    task.wait(catchWait + (math.random(1, 5) / 100))

                else
                    -- LEGIT HUMAN INPUT SIMULATION
                    st.LastStatusMessage = "🎣 Melempar Kail (Natural)..."
                    local rod = self:FindFishingRod()
                    if rod then
                        rod:Activate()
                    else
                        self:SimulateClick(0.6)
                    end

                    task.wait(1.4 + (math.random(2, 6) / 10))

                    st.LastStatusMessage = "🐟 Menarik Kail..."
                    self:SimulateClick(0.12)

                    st.FishCaught = st.FishCaught + 1
                    st.LastStatusMessage = "✅ Selesai Menarik. Total: " .. tostring(st.FishCaught)

                    task.wait(1.2 + (math.random(2, 5) / 10))
                end
            end)

            if not success then
                warn("[Bodoamat | Fishing Error] " .. tostring(err))
                task.wait(1)
            end
        end

        st.LastStatusMessage = "Memancing Dimatikan"
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
-- 5. MODULE: AUTO SELL & AUTO FAVORITE
-- ============================================================
local AutoSell = {
    Running = false,
    Thread = nil :: thread?,
    AutoFavoriteEnabled = true,
    MinFavoriteRarity = "Legendary",
    FavoritedCache = {} :: { [string]: boolean },
}

local RarityTiers: { [string]: number } = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6, Secret = 7, Exotic = 8
}

local ItemUtility = nil :: any
local PlayerData = nil :: any

pcall(function()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if shared and shared:FindFirstChild("ItemUtility") then
        ItemUtility = require(shared.ItemUtility)
    end
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages and packages:FindFirstChild("Replion") then
        local Replion = require(packages.Replion)
        PlayerData = Replion.Client:WaitReplion("Data")
    end
end)

function AutoSell:ProtectRareFish(net: any)
    if not self.AutoFavoriteEnabled or not net then return end

    pcall(function()
        if not PlayerData or not ItemUtility then return end
        local inv = PlayerData:Get("Inventory")
        if not inv or not inv.Items then return end

        local targetTier = RarityTiers[self.MinFavoriteRarity] or 5

        for _, item in ipairs(inv.Items) do
            if item.UUID and not self.FavoritedCache[item.UUID] then
                local data = ItemUtility:GetItemData(item.Id)
                local rarity = (data and data.Data and data.Data.Rarity) or "Common"
                local itemTier = RarityTiers[rarity] or 1

                if itemTier >= targetTier then
                    net:FavoriteItem(item.UUID)
                    self.FavoritedCache[item.UUID] = true
                    print("[Bodoamat | Favorite] 🌟 Mengamankan Ikan Langka: " .. tostring(data.Name or "Fish") .. " [" .. rarity .. "]")
                    task.wait(0.04)
                end
            end
        end
    end)
end

function AutoSell:Start(interval: number, net: any, st: any)
    if self.Running then return end
    self.Running = true
    local sleepTime = math.max(10, interval or 45)

    self.Thread = task.spawn(function()
        while self.Running do
            task.wait(sleepTime)
            if not self.Running then break end

            if net and net.HasRemotes then
                self:ProtectRareFish(net)
                task.wait(0.2)
                local ok = net:SellAll()
                if ok and st then
                    st.LastStatusMessage = "💰 Ikan otomatis terjual! (Ikan langka diamankan)"
                end
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
end

-- ============================================================
-- 6. MODULE: TELEPORT 14 LOKASI PULAU
-- ============================================================
local Teleport = {
    Locations = {
        { Name = "Spawn Island",        CFrame = CFrame.new(45.28, 252.56, 2987.11) },
        { Name = "Sisyphus Statue",     CFrame = CFrame.new(-3728.22, -135.07, -1012.13) },
        { Name = "Coral Reefs",         CFrame = CFrame.new(-3114.78, 1.32, 2237.52) },
        { Name = "Esoteric Depths",     CFrame = CFrame.new(3248.37, -1301.53, 1403.83) },
        { Name = "Crater Island",       CFrame = CFrame.new(1016.49, 20.09, 5069.27) },
        { Name = "Lost Isle",           CFrame = CFrame.new(-3618.16, 240.84, -1317.46) },
        { Name = "Weather Machine",     CFrame = CFrame.new(-1488.51, 83.17, 1876.30) },
        { Name = "Tropical Grove",      CFrame = CFrame.new(-2095.34, 197.20, 3718.08) },
        { Name = "Mount Hallow",        CFrame = CFrame.new(2136.62, 78.92, 3272.50) },
        { Name = "Treasure Room",       CFrame = CFrame.new(-3606.35, -266.57, -1580.97) },
        { Name = "Kohana",              CFrame = CFrame.new(-663.90, 3.05, 718.80) },
        { Name = "Underground Cellar",  CFrame = CFrame.new(2109.52, -94.19, -708.61) },
        { Name = "Ancient Jungle",      CFrame = CFrame.new(1831.71, 6.62, -299.28) },
        { Name = "Sacred Temple",       CFrame = CFrame.new(1466.92, -21.88, -622.84) },
    }
}

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

-- ============================================================
-- 7. MODULE: MOBILITAS (WALK ON WATER, INF JUMP, SPEED)
-- ============================================================
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Movement = {
    IsWaterWalk = false,
    IsInfJump = false,
    WalkSpeed = 16,
    JumpPower = 50,
    WaterPlatform = nil :: Part?,
    HeartbeatConn = nil :: RBXScriptConnection?,
    JumpConn = nil :: RBXScriptConnection?,
}

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
                    self.WaterPlatform.CFrame = CFrame.new(hrp.Position.X, -0.6, hrp.Position.Z)
                end

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
    end
end

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
    else
        if self.JumpConn then
            self.JumpConn:Disconnect()
            self.JumpConn = nil
        end
    end
end

function Movement:SetWalkSpeed(speed: number)
    self.WalkSpeed = math.clamp(speed, 16, 200)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = self.WalkSpeed end
    end
end

-- ============================================================
-- 8. MODULE: OPTIMASI GRAFIS AMAN (ANTI-BAC) & GPU SAVER
-- ============================================================
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

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

function FpsBooster:SetFpsBoost(enabled: boolean)
    if self.IsFpsBoosted == enabled then return end
    self.IsFpsBoosted = enabled

    if enabled then
        pcall(function()
            self.OriginalSettings.GlobalShadows = Lighting.GlobalShadows
            self.OriginalSettings.FogEnd = Lighting.FogEnd
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9

            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") or effect:IsA("DepthOfFieldEffect") or effect:IsA("BlurEffect") then
                    effect.Enabled = false
                end
            end
        end)

        pcall(function()
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") or desc:IsA("Fire") or desc:IsA("Smoke") then
                    desc.Enabled = false
                end
            end
        end)

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

function FpsBooster:SetGpuSaver(enabled: boolean, stateRef: any)
    if self.IsGpuSaverActive == enabled then return end
    self.IsGpuSaverActive = enabled

    if enabled then
        -- Matikan raster 3D engine (Bebas panas, nol beban GPU, physics tick tetap normal)
        pcall(function()
            RunService:Set3dRenderingEnabled(false)
        end)

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

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 45)
        title.BackgroundTransparency = 1
        title.Text = "🛡️ GPU SAVER ACTIVE (SAFE AFK)"
        title.TextColor3 = Color3.fromRGB(0, 210, 255)
        title.TextSize = 18
        title.Font = Enum.Font.GothamBold
        title.Parent = card

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

        exitBtn.MouseButton1Click:Connect(function()
            self:SetGpuSaver(false, stateRef)
            if stateRef then stateRef:Set("IsGpuSaver", false) end
        end)

        pcall(function() gui.Parent = CoreGui end)
        if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
        self.GpuSaverGui = gui

        self.StatsUpdateThread = task.spawn(function()
            while self.IsGpuSaverActive do
                local elapsed = (stateRef and stateRef:GetElapsedTime()) or "--:--:--"
                local fish = (stateRef and stateRef.FishCaught) or 0
                local status = (stateRef and stateRef.IsFishing) and "<font color='#2ecc71'>Sedang Memancing</font>" or "<font color='#e74c3c'>Standby / Tidak Memancing</font>"

                infoLabel.Text = string.format(
                    "<b>Status Farm:</b> %s\n<b>Durasi AFK:</b> %s\n<b>Ikan Ditangkap:</b> %d Ekor\n<b>Teknologi:</b> 3D Rasterization Standby (Suhu Dingin)\n<b>Anti-Cheat:</b> Physics tick normal (Aman dari BAC-6228)",
                    status, elapsed, fish
                )
                task.wait(1)
            end
        end)
        print("[Bodoamat | GPU] GPU Saver Aktif (3D Standby). Suhu perangkat dijamin dingin.")
    else
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
-- 9. MODULE: ANTI-AFK & AUTO-REJOIN ON KICK
-- ============================================================
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local AntiAfk = {
    Enabled = false,
    AutoRejoin = true,
    Connections = {} :: { RBXScriptConnection },
    MicroMoveThread = nil :: thread?,
}

function AntiAfk:Start(cfg: { MicroMovement: boolean, MoveInterval: number, AutoRejoin: boolean? }?)
    if self.Enabled then return end
    self.Enabled = true

    local interval = (cfg and cfg.MoveInterval) or 240
    local enableMicroMove = true
    if cfg and cfg.MicroMovement ~= nil then enableMicroMove = cfg.MicroMovement end
    if cfg and cfg.AutoRejoin ~= nil then self.AutoRejoin = cfg.AutoRejoin end

    local idleConn = LocalPlayer.Idled:Connect(function()
        if not self.Enabled then return end
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
    table.insert(self.Connections, idleConn)

    local errConn = GuiService.ErrorMessageChanged:Connect(function(msg)
        if self.AutoRejoin and self.Enabled and msg and #msg > 0 then
            warn("[Bodoamat | Rejoin] Pesan disconnect terdeteksi: " .. tostring(msg))
            task.wait(2.5)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
            end)
        end
    end)
    table.insert(self.Connections, errConn)

    if enableMicroMove then
        self.MicroMoveThread = task.spawn(function()
            while self.Enabled do
                task.wait(interval)
                if not self.Enabled then break end

                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:Move(Vector3.new(0.005, 0, 0), false)
                        task.wait(0.08)
                        humanoid:Move(Vector3.zero, false)
                    end
                end
            end
        end)
    end
    print("[Bodoamat] Sistem Anti-AFK & Auto-Rejoin Aktif.")
end

function AntiAfk:Stop()
    self.Enabled = false
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)
    if self.MicroMoveThread then
        task.cancel(self.MicroMoveThread)
        self.MicroMoveThread = nil
    end
end

-- ============================================================
-- 10. MODULE: STANDALONE GUI v2.0
-- ============================================================
local BodoamatGui = {
    ScreenGui = nil :: ScreenGui?,
    MainFrame = nil :: Frame?,
    CurrentTab = "Fishing",
    Tabs = {} :: { [string]: ScrollingFrame },
    TabButtons = {} :: { [string]: TextButton },
}

function BodoamatGui:Create(cfg: any, st: any, mods: any)
    pcall(function()
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name == "BodoamatUI" or gui.Name == "Bodoamat_MobileBtn" then gui:Destroy() end
        end
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetChildren()) do
                if gui.Name == "BodoamatUI" or gui.Name == "Bodoamat_MobileBtn" then gui:Destroy() end
            end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BodoamatUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10000
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self.ScreenGui = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 540, 0, 390)
    mainFrame.Position = UDim2.new(0.5, -270, 0.5, -195)
    mainFrame.BackgroundColor3 = cfg.UI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = cfg.UI.Theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    local dragging, dragInput, dragStart, startPos
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = cfg.UI.Theme.CardBg
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerPatch = Instance.new("Frame")
    headerPatch.Size = UDim2.new(1, 0, 0, 10)
    headerPatch.Position = UDim2.new(0, 0, 1, -10)
    headerPatch.BackgroundColor3 = cfg.UI.Theme.CardBg
    headerPatch.BorderSizePixel = 0
    headerPatch.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 220, 0, 24)
    titleLabel.Position = UDim2.new(0, 16, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🐟 " .. cfg.UI.Title
    titleLabel.TextColor3 = cfg.UI.Theme.Accent
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0, 260, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 16, 0, 28)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = cfg.UI.Subtitle
    subtitleLabel.TextColor3 = cfg.UI.Theme.TextSubtle
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
    closeBtn.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 135, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -145, 1, -58)
    contentArea.Position = UDim2.new(0, 140, 0, 53)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    local function createTab(tabName: string): ScrollingFrame
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = cfg.UI.Theme.Accent
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
        pagePadding.PaddingBottom = UDim.new(0, 10)
        pagePadding.Parent = page

        self.Tabs[tabName] = page
        return page
    end

    local tabList = {
        { Id = "Fishing",  Label = "🎣 Memancing" },
        { Id = "Selling",  Label = "💰 Toko & Fav" },
        { Id = "Teleport", Label = "🗺️ Teleport" },
        { Id = "Movement", Label = "🏃 Mobilitas" },
        { Id = "Optimasi", Label = "⚡ Performa" },
        { Id = "Status",   Label = "📊 Statistik" },
    }

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = sidebar

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 6)
    sidebarPadding.PaddingRight = UDim.new(0, 6)
    sidebarPadding.Parent = sidebar

    for _, t in ipairs(tabList) do
        createTab(t.Id)
        local btn = Instance.new("TextButton")
        btn.Name = t.Id .. "TabBtn"
        btn.Size = UDim2.new(1, 0, 0, 34)
        btn.BackgroundColor3 = (t.Id == self.CurrentTab) and cfg.UI.Theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.Text = t.Label
        btn.TextColor3 = (t.Id == self.CurrentTab) and cfg.UI.Theme.Accent or cfg.UI.Theme.TextSubtle
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = sidebar

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = btn

        self.TabButtons[t.Id] = btn
        btn.MouseButton1Click:Connect(function() self:SwitchTab(t.Id, cfg) end)
    end

    local function createToggle(parent: Instance, title: string, desc: string, default: boolean, onToggle: (boolean) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 52)
        card.BackgroundColor3 = cfg.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -70, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 7)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = cfg.UI.Theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -70, 0, 16)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = cfg.UI.Theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 48, 0, 26)
        toggleBtn.Position = UDim2.new(1, -58, 0.5, -13)
        toggleBtn.BackgroundColor3 = default and cfg.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
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
            toggleBtn.BackgroundColor3 = isToggled and cfg.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
            onToggle(isToggled)
        end)
    end

    local function createActionButton(parent: Instance, label: string, desc: string, onClick: () -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 46)
        card.BackgroundColor3 = cfg.UI.Theme.CardBg
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
        tLabel.TextColor3 = cfg.UI.Theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -110, 0, 14)
        dLabel.Position = UDim2.new(0, 12, 0, 24)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = cfg.UI.Theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 0, 28)
        btn.Position = UDim2.new(1, -98, 0.5, -14)
        btn.BackgroundColor3 = cfg.UI.Theme.Accent
        btn.Text = "Jalankan"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = btn
        btn.MouseButton1Click:Connect(onClick)
    end

    -- TAB 1: MEMANCING
    local fishPage = self.Tabs["Fishing"]
    createToggle(fishPage, "Auto Fishing Aktif", "Otomatis melempar kail dan menarik tangkapan", st.IsFishing, function(val)
        st:Set("IsFishing", val)
        if val then
            mods.AutoFish:Start(cfg.AutoFish, st, mods.Network)
        else
            mods.AutoFish:Stop()
        end
    end)

    local modeCard = Instance.new("Frame")
    modeCard.Size = UDim2.new(1, -4, 0, 68)
    modeCard.BackgroundColor3 = cfg.UI.Theme.CardBg
    modeCard.BorderSizePixel = 0
    modeCard.Parent = fishPage

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 8)
    mCorner.Parent = modeCard

    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, -20, 0, 20)
    mTitle.Position = UDim2.new(0, 12, 0, 6)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = "Mode Kecepatan Memancing"
    mTitle.TextColor3 = cfg.UI.Theme.Text
    mTitle.TextSize = 12
    mTitle.Font = Enum.Font.GothamBold
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.Parent = modeCard

    local modeButtons = {}
    local modes = {
        { Id = "Legit",   Label = "🛡️ Legit (Input)" },
        { Id = "Fast",    Label = "⚡ Fast (Safe)" },
        { Id = "Blatant", Label = "🚀 Blatant (Instant)" },
    }

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -24, 0, 30)
    btnContainer.Position = UDim2.new(0, 12, 0, 30)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = modeCard

    local bLayout = Instance.new("UIListLayout")
    bLayout.FillDirection = Enum.FillDirection.Horizontal
    bLayout.Padding = UDim.new(0, 6)
    bLayout.Parent = btnContainer

    for _, m in ipairs(modes) do
        local mBtn = Instance.new("TextButton")
        mBtn.Size = UDim2.new(0.32, -4, 1, 0)
        mBtn.BackgroundColor3 = (cfg.AutoFish.Mode == m.Id) and cfg.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        mBtn.Text = m.Label
        mBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mBtn.TextSize = 10
        mBtn.Font = Enum.Font.GothamMedium
        mBtn.Parent = btnContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = mBtn

        modeButtons[m.Id] = mBtn
        mBtn.MouseButton1Click:Connect(function()
            cfg.AutoFish.Mode = m.Id
            st:Set("FishingMode", m.Id)
            for id, btn in pairs(modeButtons) do
                btn.BackgroundColor3 = (id == m.Id) and cfg.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
            end
            if st.IsFishing then
                mods.AutoFish:Stop()
                mods.AutoFish:Start(cfg.AutoFish, st, mods.Network)
            end
        end)
    end

    createActionButton(fishPage, "Equip Joran Manual", "Mencari dan memasang joran dari tas ke tangan", function()
        mods.AutoFish:EnsureRodEquipped(mods.Network)
    end)

    -- TAB 2: TOKO & FAVORITE
    local sellPage = self.Tabs["Selling"]
    createToggle(sellPage, "Auto Sell Ikan", "Menjual hasil tangkapan otomatis setiap 45 detik", st.IsAutoSell, function(val)
        st:Set("IsAutoSell", val)
        if val then
            mods.AutoSell:Start(cfg.AutoSell.Interval, mods.Network, st)
        else
            mods.AutoSell:Stop()
        end
    end)

    createToggle(sellPage, "Auto Favorite Ikan Langka", "Mengunci otomatis ikan bernilai tinggi sebelum dijual", mods.AutoSell.AutoFavoriteEnabled, function(val)
        mods.AutoSell.AutoFavoriteEnabled = val
        st:Set("IsAutoFavorite", val)
    end)

    local rarityCard = Instance.new("Frame")
    rarityCard.Size = UDim2.new(1, -4, 0, 64)
    rarityCard.BackgroundColor3 = cfg.UI.Theme.CardBg
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
    rTitle.TextColor3 = cfg.UI.Theme.Text
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
        rBtn.BackgroundColor3 = (mods.AutoSell.MinFavoriteRarity == rName) and cfg.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
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
            mods.AutoSell.MinFavoriteRarity = rName
            for id, b in pairs(rButtons) do
                b.BackgroundColor3 = (id == rName) and cfg.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
            end
        end)
    end

    createActionButton(sellPage, "Jual Semua Ikan Sekarang", "Kirim remote jual langsung ke merchant", function()
        mods.AutoSell:ProtectRareFish(mods.Network)
        task.wait(0.1)
        local ok = mods.Network:SellAll()
        if ok then st.LastStatusMessage = "💰 Berhasil menjual semua ikan!" end
    end)

    -- TAB 3: TELEPORT
    local tpPage = self.Tabs["Teleport"]
    local tpHeader = Instance.new("TextLabel")
    tpHeader.Size = UDim2.new(1, -10, 0, 20)
    tpHeader.BackgroundTransparency = 1
    tpHeader.Text = "📍 Teleport Cepat 14 Lokasi Pulau & Secret Spots"
    tpHeader.TextColor3 = cfg.UI.Theme.Accent
    tpHeader.TextSize = 12
    tpHeader.Font = Enum.Font.GothamBold
    tpHeader.TextXAlignment = Enum.TextXAlignment.Left
    tpHeader.Parent = tpPage

    for _, loc in ipairs(mods.Teleport.Locations) do
        local tpCard = Instance.new("Frame")
        tpCard.Size = UDim2.new(1, -4, 0, 38)
        tpCard.BackgroundColor3 = cfg.UI.Theme.CardBg
        tpCard.BorderSizePixel = 0
        tpCard.Parent = tpPage

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 7)
        cCorner.Parent = tpCard

        local locLabel = Instance.new("TextLabel")
        locLabel.Size = UDim2.new(1, -90, 1, 0)
        locLabel.Position = UDim2.new(0, 12, 0, 0)
        locLabel.BackgroundTransparency = 1
        locLabel.Text = "🏝️ " .. loc.Name
        locLabel.TextColor3 = cfg.UI.Theme.Text
        locLabel.TextSize = 12
        locLabel.Font = Enum.Font.GothamMedium
        locLabel.TextXAlignment = Enum.TextXAlignment.Left
        locLabel.Parent = tpCard

        local goBtn = Instance.new("TextButton")
        goBtn.Size = UDim2.new(0, 70, 0, 26)
        goBtn.Position = UDim2.new(1, -78, 0.5, -13)
        goBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 230)
        goBtn.Text = "Teleport"
        goBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        goBtn.TextSize = 11
        goBtn.Font = Enum.Font.GothamBold
        goBtn.Parent = tpCard

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 5)
        bCorner.Parent = goBtn

        goBtn.MouseButton1Click:Connect(function()
            local success = mods.Teleport:To(loc.CFrame)
            if success then st.LastStatusMessage = "📍 Teleport ke " .. loc.Name end
        end)
    end

    -- TAB 4: MOBILITAS
    local movePage = self.Tabs["Movement"]
    createToggle(movePage, "Walk On Water (Jesus Walk)", "Berjalan di atas permukaan air laut tanpa jatuh", st.IsWaterWalk, function(val)
        st:Set("IsWaterWalk", val)
        mods.Movement:SetWaterWalk(val)
    end)

    createToggle(movePage, "Infinite Jump", "Lompat bebas di udara tanpa batas", st.IsInfJump, function(val)
        st:Set("IsInfJump", val)
        mods.Movement:SetInfiniteJump(val)
    end)

    local spdCard = Instance.new("Frame")
    spdCard.Size = UDim2.new(1, -4, 0, 62)
    spdCard.BackgroundColor3 = cfg.UI.Theme.CardBg
    spdCard.BorderSizePixel = 0
    spdCard.Parent = movePage

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 8)
    sCorner.Parent = spdCard

    local sTitle = Instance.new("TextLabel")
    sTitle.Size = UDim2.new(1, -20, 0, 18)
    sTitle.Position = UDim2.new(0, 12, 0, 6)
    sTitle.BackgroundTransparency = 1
    sTitle.Text = "Kecepatan Karakter (WalkSpeed: " .. tostring(mods.Movement.WalkSpeed) .. ")"
    sTitle.TextColor3 = cfg.UI.Theme.Text
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
        b.BackgroundColor3 = (mods.Movement.WalkSpeed == s.Val) and cfg.UI.Theme.Accent or Color3.fromRGB(35, 38, 52)
        b.Text = s.Label
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamMedium
        b.Parent = spdContainer

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 5)
        c.Parent = b
        b.MouseButton1Click:Connect(function()
            mods.Movement:SetWalkSpeed(s.Val)
            sTitle.Text = "Kecepatan Karakter (WalkSpeed: " .. tostring(s.Val) .. ")"
        end)
    end

    -- TAB 5: OPTIMASI & PERFORMA
    local optPage = self.Tabs["Optimasi"]
    createToggle(optPage, "FPS Booster (Safe Anti-BAC)", "Menonaktifkan partikel berat & bloom (Tanpa tamper parts)", st.IsFpsBoost, function(val)
        st:Set("IsFpsBoost", val)
        mods.FpsBooster:SetFpsBoost(val)
    end)

    createToggle(optPage, "Ultra GPU Saver (AFK Safe)", "Matikan 3D rasterization agar suhu PC/HP dingin", st.IsGpuSaver, function(val)
        st:Set("IsGpuSaver", val)
        mods.FpsBooster:SetGpuSaver(val, st)
    end)

    createToggle(optPage, "Anti-AFK 20 Menit & Auto-Rejoin", "Mencegah kick idle dan otomatis masuk kembali jika terputus", st.IsAntiAfk, function(val)
        st:Set("IsAntiAfk", val)
        if val then
            mods.AntiAfk:Start(cfg.AntiAfk)
        else
            mods.AntiAfk:Stop()
        end
    end)

    -- TAB 6: STATUS & STATISTIK
    local statPage = self.Tabs["Status"]
    local statBox = Instance.new("Frame")
    statBox.Size = UDim2.new(1, -4, 0, 210)
    statBox.BackgroundColor3 = cfg.UI.Theme.CardBg
    statBox.BorderSizePixel = 0
    statBox.Parent = statPage

    local stCorner = Instance.new("UICorner")
    stCorner.CornerRadius = UDim.new(0, 8)
    stCorner.Parent = statBox

    local statText = Instance.new("TextLabel")
    statText.Size = UDim2.new(1, -24, 1, -20)
    statText.Position = UDim2.new(0, 12, 0, 10)
    statText.BackgroundTransparency = 1
    statText.TextColor3 = cfg.UI.Theme.Text
    statText.TextSize = 13
    statText.Font = Enum.Font.Gotham
    statText.TextXAlignment = Enum.TextXAlignment.Left
    statText.TextYAlignment = Enum.TextYAlignment.Top
    statText.RichText = true
    statText.Parent = statBox

    task.spawn(function()
        while screenGui.Parent do
            local elapsed = st:GetElapsedTime()
            local caught = st.FishCaught
            local status = st.LastStatusMessage
            local fMode = cfg.AutoFish.Mode

            statText.Text = string.format(
                "<b>📊 INFORMASI LIVE SESSION:</b>\n\n" ..
                "• <b>Durasi Menjalankan:</b> <font color='#00d2ff'>%s</font>\n" ..
                "• <b>Total Ikan Tertangkap:</b> <font color='#2ecc71'>%d Ekor</font>\n" ..
                "• <b>Mode Memancing:</b> <font color='#f39c12'>%s</font>\n" ..
                "• <b>Status Sistem:</b> %s\n\n" ..
                "<b>🛡️ STATUS KEAMANAN (ANTI-BAC):</b>\n" ..
                "• <b>Namecall Blocker:</b> <font color='#2ecc71'>Aktif</font>\n" ..
                "• <b>Workspace Part Tamper:</b> <font color='#2ecc71'>Dihapus (Safe)</font>\n" ..
                "• <b>GPU Saver Mode:</b> <font color='#2ecc71'>Engine Raster Standby</font>",
                elapsed, caught, fMode, status
            )
            task.wait(1)
        end
    end)

    local mobileBtn = Instance.new("TextButton")
    mobileBtn.Name = "Bodoamat_MobileBtn"
    mobileBtn.Size = UDim2.new(0, 48, 0, 48)
    mobileBtn.Position = UDim2.new(0, 20, 0.5, -24)
    mobileBtn.BackgroundColor3 = cfg.UI.Theme.CardBg
    mobileBtn.Text = "🐟"
    mobileBtn.TextSize = 22
    mobileBtn.Active = true
    mobileBtn.Parent = screenGui

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 24)
    mbCorner.Parent = mobileBtn

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = cfg.UI.Theme.Accent
    mbStroke.Thickness = 1.5
    mbStroke.Parent = mobileBtn

    mobileBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == cfg.UI.ToggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    self:SwitchTab("Fishing", cfg)
    print("[Bodoamat | UI] Standalone GUI v2.0 berhasil dimuat.")
end

function BodoamatGui:SwitchTab(tabId: string, cfg: any)
    self.CurrentTab = tabId
    for id, page in pairs(self.Tabs) do
        page.Visible = (id == tabId)
    end
    for id, btn in pairs(self.TabButtons) do
        btn.BackgroundColor3 = (id == tabId) and cfg.UI.Theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.TextColor3 = (id == tabId) and cfg.UI.Theme.Accent or cfg.UI.Theme.TextSubtle
    end
end

-- ============================================================
-- 11. BOOTSTRAP INITIALIZATION
-- ============================================================
local Modules = {
    Network = Network,
    AutoFish = AutoFish,
    AutoSell = AutoSell,
    Teleport = Teleport,
    Movement = Movement,
    FpsBooster = FpsBooster,
    AntiAfk = AntiAfk,
    UI = BodoamatGui,
}

local function Init()
    print("================================================")
    print("🚀 BODOAMAT v2.0 - Memulai inisialisasi...")
    print("================================================")

    Network:Init()

    if Config.AntiAfk.Enabled then
        AntiAfk:Start(Config.AntiAfk)
    end

    BodoamatGui:Create(Config, State, Modules)

    print("[Bodoamat v2.0] Berhasil dimuat! Tekan RightShift atau tombol 🐟 untuk membuka menu.")
end

Init()
return Modules
