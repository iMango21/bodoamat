--!strict
-- ====================================================================
--                      PROJECT BODOAMAT
--         Roblox Fish It! Automation & Quality of Life Hub
--                      Versi: 1.0.0 (Production)
-- ====================================================================
-- Fitur:
--  ✓ Auto Fishing (Fast Remote & Natural Simulation Dual Mode)
--  ✓ Anti-AFK 20-Minute Kick Prevention & Server Micro-movement
--  ✓ FPS Booster (No Shadows, Flat Materials, No Heavy VFX)
--  ✓ Ultra GPU Saver (AFK Black Screen & 15 FPS Throttle for overnight)
--  ✓ Auto Sell All Fish Periodically
--  ✓ 100% Native Standalone UI (No external downloads, zero lag)
-- ====================================================================

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

-- ====================================================================
-- [1. CORE SERVICES]
-- ====================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- [2. KONFIGURASI SISTEM]
-- ====================================================================
local Config = {
    AutoFish = {
        Enabled = false,
        Mode = "Fast",          -- "Fast" (Remote) atau "Legit" (Natural Input)
        CastDelay = 0.5,        -- Jeda sebelum menarik ikan (detik)
        CatchDelay = 0.2,       -- Jeda sebelum melempar kail berikutnya (detik)
        AutoEquipRod = true,
    },
    AntiAfk = {
        Enabled = true,
        MicroMovement = true,
        MoveInterval = 300,
    },
    Performance = {
        FpsBoost = false,
        GpuSaver = false,
        TargetFps = 15,
    },
    AutoSell = {
        Enabled = false,
        Interval = 60,
    },
    UI = {
        Title = "BODOAMAT",
        Subtitle = "Fish It! Automation & QoL Hub",
        ToggleKey = Enum.KeyCode.RightShift,
        Theme = {
            Background = Color3.fromRGB(18, 20, 28),
            CardBg = Color3.fromRGB(26, 29, 40),
            Border = Color3.fromRGB(45, 50, 68),
            Accent = Color3.fromRGB(0, 170, 255),
            Success = Color3.fromRGB(46, 204, 113),
            Danger = Color3.fromRGB(231, 76, 60),
            Text = Color3.fromRGB(240, 243, 246),
            TextSubtle = Color3.fromRGB(140, 148, 164),
        }
    }
}

-- ====================================================================
-- [3. STATE MANAGEMENT]
-- ====================================================================
local State = {
    IsFishing = false,
    FishingMode = "Fast",
    IsAntiAfk = true,
    IsFpsBoost = false,
    IsGpuSaver = false,
    IsAutoSell = false,
    StartTime = os.time(),
    FishCaught = 0,
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

-- ====================================================================
-- [4. NETWORK MANAGER (sleitnick_net)]
-- ====================================================================
local Network = {
    HasRemotes = false,
    Remotes = {} :: { [string]: Instance? }
}

function Network:Init()
    pcall(function()
        local packages = ReplicatedStorage:FindFirstChild("Packages")
        if not packages then return end
        local indexFolder = packages:FindFirstChild("_Index")
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

        self.Remotes["ChargeRod"]    = netFolder:FindFirstChild("RF/ChargeFishingRod")
        self.Remotes["RequestGame"]  = netFolder:FindFirstChild("RF/RequestFishingMinigameStarted")
        self.Remotes["CompleteGame"] = netFolder:FindFirstChild("RE/FishingCompleted")
        self.Remotes["CancelInput"]  = netFolder:FindFirstChild("RF/CancelFishingInputs")
        self.Remotes["SellAll"]      = netFolder:FindFirstChild("RF/SellAllItems")
        self.Remotes["EquipHotbar"]  = netFolder:FindFirstChild("RE/EquipToolFromHotbar")

        self.HasRemotes = (self.Remotes["ChargeRod"] ~= nil and self.Remotes["CompleteGame"] ~= nil)
    end)

    if self.HasRemotes then
        print("[Bodoamat] Jaringan game (sleitnick_net) terhubung.")
    else
        warn("[Bodoamat] Remote jaringan tidak ditemukan, fallback ke input klik simulasi.")
    end
    return self.HasRemotes
end

function Network:ChargeRod(power: number?): boolean
    local remote = self.Remotes["ChargeRod"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function() remote:InvokeServer(power or 1755848498.4834) end)
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
        local ok, _ = pcall(function() remote:FireServer() end)
        return ok
    end
    return false
end

function Network:SellAll(): boolean
    local remote = self.Remotes["SellAll"]
    if remote and remote:IsA("RemoteFunction") then
        local ok, _ = pcall(function() remote:InvokeServer() end)
        return ok
    end
    return false
end

function Network:EquipHotbar(slot: number): boolean
    local remote = self.Remotes["EquipHotbar"]
    if remote and remote:IsA("RemoteEvent") then
        local ok, _ = pcall(function() remote:FireServer(slot) end)
        return ok
    end
    return false
end

Network:Init()

-- ====================================================================
-- [5. MODUL ANTI-AFK]
-- ====================================================================
local AntiAfk = {
    Enabled = false,
    Connections = {} :: { RBXScriptConnection },
    MicroMoveThread = nil :: thread?
}

function AntiAfk:Start(config: any)
    if self.Enabled then return end
    self.Enabled = true

    -- Proteksi Idled default Roblox (Kick 20 menit)
    local idleConn = LocalPlayer.Idled:Connect(function()
        if not self.Enabled then return end
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
        print("[Bodoamat] Anti-AFK dipicu: Input aman tersimulasi.")
    end)
    table.insert(self.Connections, idleConn)

    -- Pergerakan mikro berkala (mencegah pendeteksian server)
    if config.MicroMovement then
        self.MicroMoveThread = task.spawn(function()
            while self.Enabled do
                task.wait(config.MoveInterval or 300)
                if not self.Enabled then break end
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        humanoid:Move(Vector3.new(0.01, 0, 0), false)
                        task.wait(0.1)
                        humanoid:Move(Vector3.new(0, 0, 0), false)
                    end
                end
            end
        end)
    end
    print("[Bodoamat] Proteksi Anti-AFK aktif.")
end

function AntiAfk:Stop()
    self.Enabled = false
    for _, conn in ipairs(self.Connections) do conn:Disconnect() end
    table.clear(self.Connections)
    if self.MicroMoveThread then
        task.cancel(self.MicroMoveThread)
        self.MicroMoveThread = nil
    end
    print("[Bodoamat] Proteksi Anti-AFK nonaktif.")
end

-- ====================================================================
-- [6. MODUL OPTIMASI GRAFIS & GPU SAVER]
-- ====================================================================
local FpsBooster = {
    IsFpsBoosted = false,
    IsGpuSaverActive = false,
    DescendantConnection = nil :: RBXScriptConnection?,
    GpuSaverGui = nil :: ScreenGui?,
    StatsUpdateThread = nil :: thread?,
    OriginalSettings = { GlobalShadows = true, FogEnd = 100000 }
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
                if effect:IsA("PostEffect") then effect.Enabled = false end
            end
        end)

        local function optimizePart(obj: Instance)
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.CastShadow = false
                obj.Reflectance = 0
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") then
                obj.Enabled = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            end
        end

        for _, desc in ipairs(Workspace:GetDescendants()) do optimizePart(desc) end
        self.DescendantConnection = Workspace.DescendantAdded:Connect(function(child)
            task.wait()
            optimizePart(child)
        end)
        print("[Bodoamat] FPS Boost diaktifkan.")
    else
        if self.DescendantConnection then
            self.DescendantConnection:Disconnect()
            self.DescendantConnection = nil
        end
        pcall(function()
            Lighting.GlobalShadows = self.OriginalSettings.GlobalShadows
            Lighting.FogEnd = self.OriginalSettings.FogEnd
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then effect.Enabled = true end
            end
        end)
        print("[Bodoamat] FPS Boost dinonaktifkan.")
    end
end

function FpsBooster:SetGpuSaver(enabled: boolean, stateRef: any, targetFps: number?)
    if self.IsGpuSaverActive == enabled then return end
    self.IsGpuSaverActive = enabled
    local fpsCap = targetFps or 15

    if enabled then
        pcall(function()
            local setfps = (getgenv and (getgenv() :: any).setfpscap) or (setfpscap :: any)
            if typeof(setfps) == "function" then setfps(fpsCap) end
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
        card.Size = UDim2.new(0, 420, 0, 240)
        card.Position = UDim2.new(0.5, -210, 0.5, -120)
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
        title.Text = "🛡️ GPU SAVER ACTIVE"
        title.TextColor3 = Color3.fromRGB(0, 210, 255)
        title.TextSize = 20
        title.Font = Enum.Font.GothamBold
        title.Parent = card

        local infoLabel = Instance.new("TextLabel")
        infoLabel.Size = UDim2.new(1, -30, 0, 110)
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
        exitBtn.Size = UDim2.new(1, -30, 0, 40)
        exitBtn.Position = UDim2.new(0, 15, 1, -50)
        exitBtn.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
        exitBtn.Text = "Matikan GPU Saver (Kembali ke Game)"
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
                local status = (stateRef and stateRef.IsFishing) and "<font color='#2ecc71'>Sedang Memancing</font>" or "<font color='#e74c3c'>Tidak Memancing</font>"
                infoLabel.Text = string.format(
                    "<b>Status Farm:</b> %s\n<b>Durasi AFK:</b> %s\n<b>Ikan Tertangkap:</b> %d Ekor\n<b>Mode FPS:</b> Dibatasi (%d FPS) agar perangkat dingin",
                    status, elapsed, fish, fpsCap
                )
                task.wait(1)
            end
        end)
    else
        pcall(function()
            local setfps = (getgenv and (getgenv() :: any).setfpscap) or (setfpscap :: any)
            if typeof(setfps) == "function" then setfps(0) end
        end)
        if self.StatsUpdateThread then
            task.cancel(self.StatsUpdateThread)
            self.StatsUpdateThread = nil
        end
        if self.GpuSaverGui then
            self.GpuSaverGui:Destroy()
            self.GpuSaverGui = nil
        end
    end
end

-- ====================================================================
-- [7. MODUL AUTO FISHING ENGINE]
-- ====================================================================
local AutoFish = {
    Running = false,
    Thread = nil :: thread?,
    CurrentRod = nil :: Tool?
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

function AutoFish:EnsureRodEquipped(): boolean
    local char = LocalPlayer.Character
    if not char then return false end
    local activeTool = char:FindFirstChildOfClass("Tool")
    if activeTool and (string.find(activeTool.Name:lower(), "rod") or string.find(activeTool.Name:lower(), "fish")) then
        self.CurrentRod = activeTool
        return true
    end

    if Network.HasRemotes then
        Network:EquipHotbar(1)
        task.wait(0.2)
    end

    local backpackRod = self:FindFishingRod()
    if backpackRod and backpackRod.Parent == LocalPlayer:FindFirstChild("Backpack") then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(backpackRod)
            task.wait(0.2)
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
    if holdDuration and holdDuration > 0 then task.wait(holdDuration) end
    VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
end

function AutoFish:Start()
    if self.Running then return end
    self.Running = true

    self.Thread = task.spawn(function()
        print("[Bodoamat] Mesin memancing aktif (" .. tostring(Config.AutoFish.Mode) .. ").")

        while self.Running do
            local success, err = pcall(function()
                local isEquipped = self:EnsureRodEquipped()
                if not isEquipped then
                    State.LastStatusMessage = "Menunggu Joran (Pindahkan ke Slot 1/Tas)"
                    task.wait(1.5)
                    return
                end

                if Config.AutoFish.Mode == "Fast" and Network.HasRemotes then
                    -- Mode 1: Fast Direct Remote
                    State.LastStatusMessage = "🎣 Melempar Kail (Fast Remote)..."
                    Network:ChargeRod(1755848498.4834)
                    task.wait(0.02)
                    Network:RequestMinigame()
                    task.wait(Config.AutoFish.CastDelay or 0.5)

                    State.LastStatusMessage = "🐟 Menarik Hasil Tangkapan..."
                    for _ = 1, 3 do
                        Network:CompleteFishing()
                        task.wait(0.01)
                    end

                    State.FishCaught = State.FishCaught + 1
                    State.LastStatusMessage = "✅ Ikan Tertangkap! Total: " .. tostring(State.FishCaught)
                    task.wait(Config.AutoFish.CatchDelay or 0.2)
                else
                    -- Mode 2: Natural Click Simulation
                    State.LastStatusMessage = "🎣 Melempar Kail (Natural Click)..."
                    local rod = self:FindFishingRod()
                    if rod then rod:Activate() else self:SimulateClick(0.7) end

                    task.wait(1.2 + (math.random(1, 4) / 10))
                    State.LastStatusMessage = "🐟 Menarik Kail..."
                    self:SimulateClick(0.1)

                    State.FishCaught = State.FishCaught + 1
                    State.LastStatusMessage = "✅ Selesai Menarik. Total: " .. tostring(State.FishCaught)
                    task.wait(1.0 + (math.random(2, 5) / 10))
                end
            end)

            if not success then
                warn("[Bodoamat | Fishing Error] " .. tostring(err))
                task.wait(1)
            end
        end
        State.LastStatusMessage = "Memancing Dimatikan"
    end)
end

function AutoFish:Stop()
    self.Running = false
    if self.Thread then
        task.cancel(self.Thread)
        self.Thread = nil
    end
end

-- ====================================================================
-- [8. MODUL AUTO SELL]
-- ====================================================================
local AutoSell = {
    Running = false,
    Thread = nil :: thread?
}

function AutoSell:Start(interval: number)
    if self.Running then return end
    self.Running = true
    local sleepTime = math.max(10, interval or 60)

    self.Thread = task.spawn(function()
        while self.Running do
            task.wait(sleepTime)
            if not self.Running then break end
            if Network.HasRemotes then
                local success = Network:SellAll()
                if success then
                    State.LastStatusMessage = "💰 Ikan terjual otomatis ke toko!"
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

-- ====================================================================
-- [9. STANDALONE NATIVE GUI]
-- ====================================================================
local function BuildGui()
    -- Bersihkan GUI lama jika ada
    pcall(function()
        for _, gui in ipairs(CoreGui:GetChildren()) do
            if gui.Name == "BodoamatUI" or gui.Name == "Bodoamat_MobileBtn" or gui.Name == "Bodoamat_GpuSaver" then
                gui:Destroy()
            end
        end
        local pGui = LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetChildren()) do
                if gui.Name == "BodoamatUI" or gui.Name == "Bodoamat_MobileBtn" or gui.Name == "Bodoamat_GpuSaver" then
                    gui:Destroy()
                end
            end
        end
    end)

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BodoamatUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10000

    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, 520, 0, 360)
    mainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
    mainFrame.BackgroundColor3 = Config.UI.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Config.UI.Theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    -- Dragging Logic
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

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = Config.UI.Theme.CardBg
    header.BorderSizePixel = 0
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerPatch = Instance.new("Frame")
    headerPatch.Size = UDim2.new(1, 0, 0, 10)
    headerPatch.Position = UDim2.new(0, 0, 1, -10)
    headerPatch.BackgroundColor3 = Config.UI.Theme.CardBg
    headerPatch.BorderSizePixel = 0
    headerPatch.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 0, 24)
    titleLabel.Position = UDim2.new(0, 16, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🐟 " .. Config.UI.Title
    titleLabel.TextColor3 = Config.UI.Theme.Accent
    titleLabel.TextSize = 17
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0, 250, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 16, 0, 28)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = Config.UI.Subtitle
    subtitleLabel.TextColor3 = Config.UI.Theme.TextSubtle
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

    -- Sidebar & Content
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 130, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = mainFrame

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 10)
    sidebarPadding.PaddingLeft = UDim.new(0, 8)
    sidebarPadding.PaddingRight = UDim.new(0, 8)
    sidebarPadding.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = sidebar

    local contentArea = Instance.new("Frame")
    contentArea.Size = UDim2.new(1, -140, 1, -58)
    contentArea.Position = UDim2.new(0, 135, 0, 53)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = mainFrame

    local Tabs = {}
    local TabButtons = {}

    local function createTab(tabId: string): ScrollingFrame
        local page = Instance.new("ScrollingFrame")
        page.Name = tabId .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Config.UI.Theme.Accent
        page.Visible = false
        page.Parent = contentArea

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        Tabs[tabId] = page
        return page
    end

    local tabList = {
        { Id = "Fishing", Label = "🎣 Memancing" },
        { Id = "Optimasi", Label = "⚡ Performa" },
        { Id = "Utilitas", Label = "🛡️ Utilitas" },
        { Id = "Status", Label = "📊 Statistik" },
    }

    local function switchTab(selectedId: string)
        for name, page in pairs(Tabs) do page.Visible = (name == selectedId) end
        for name, btn in pairs(TabButtons) do
            if name == selectedId then
                btn.BackgroundColor3 = Config.UI.Theme.CardBg
                btn.TextColor3 = Config.UI.Theme.Accent
            else
                btn.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
                btn.TextColor3 = Config.UI.Theme.TextSubtle
            end
        end
    end

    for _, t in ipairs(tabList) do
        createTab(t.Id)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
        btn.Text = t.Label
        btn.TextColor3 = Config.UI.Theme.TextSubtle
        btn.TextSize = 13
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = sidebar

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 10)
        pad.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = btn

        TabButtons[t.Id] = btn
        btn.MouseButton1Click:Connect(function() switchTab(t.Id) end)
    end

    -- UI Builder Helper
    local function createToggle(parent: Instance, title: string, desc: string, default: boolean, onToggle: (boolean) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, 56)
        card.BackgroundColor3 = Config.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -70, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 8)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = Config.UI.Theme.Text
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -70, 0, 16)
        dLabel.Position = UDim2.new(0, 12, 0, 28)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = Config.UI.Theme.TextSubtle
        dLabel.TextSize = 11
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 50, 0, 26)
        toggleBtn.Position = UDim2.new(1, -62, 0.5, -13)
        toggleBtn.BackgroundColor3 = default and Config.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
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
            toggleBtn.BackgroundColor3 = isToggled and Config.UI.Theme.Success or Color3.fromRGB(48, 52, 68)
            onToggle(isToggled)
        end)
    end

    local function createActionButton(parent: Instance, label: string, desc: string, onClick: () -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -6, 0, 48)
        card.BackgroundColor3 = Config.UI.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -110, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 6)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = label
        tLabel.TextColor3 = Config.UI.Theme.Text
        tLabel.TextSize = 13
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -110, 0, 14)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = Config.UI.Theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.Parent = card

        local actionBtn = Instance.new("TextButton")
        actionBtn.Size = UDim2.new(0, 90, 0, 30)
        actionBtn.Position = UDim2.new(1, -100, 0.5, -15)
        actionBtn.BackgroundColor3 = Config.UI.Theme.Accent
        actionBtn.Text = "Jalankan"
        actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        actionBtn.TextSize = 12
        actionBtn.Font = Enum.Font.GothamBold
        actionBtn.Parent = card

        local aCorner = Instance.new("UICorner")
        aCorner.CornerRadius = UDim.new(0, 6)
        aCorner.Parent = actionBtn

        actionBtn.MouseButton1Click:Connect(onClick)
    end

    -- [TAB 1: MEMANCING]
    local fishingPage = Tabs["Fishing"]
    createToggle(fishingPage, "Otomatis Memancing (Auto Fish)", "Menjalankan siklus lempar & tangkap ikan", Config.AutoFish.Enabled, function(val)
        Config.AutoFish.Enabled = val
        State:Set("IsFishing", val)
        if val then AutoFish:Start() else AutoFish:Stop() end
    end)

    createToggle(fishingPage, "Mode Super Cepat (Direct Remote)", "Menggunakan koneksi jaringan game langsung", (Config.AutoFish.Mode == "Fast"), function(val)
        Config.AutoFish.Mode = val and "Fast" or "Legit"
        State:Set("FishingMode", Config.AutoFish.Mode)
        if Config.AutoFish.Enabled then
            AutoFish:Stop()
            AutoFish:Start()
        end
    end)

    createActionButton(fishingPage, "Equip Joran Manual", "Cari joran di tas dan pasang ke tangan", function()
        local ok = AutoFish:EnsureRodEquipped()
        State.LastStatusMessage = ok and "Joran terpasang!" or "Joran tidak ditemukan!"
    end)

    -- [TAB 2: PERFORMA & FPS]
    local optPage = Tabs["Optimasi"]
    createToggle(optPage, "FPS Booster (Grafis Ringan)", "Matikan bayangan, partikel, & efek berat", Config.Performance.FpsBoost, function(val)
        Config.Performance.FpsBoost = val
        State:Set("IsFpsBoost", val)
        FpsBooster:SetFpsBoost(val)
    end)

    createToggle(optPage, "Ultra GPU Saver (AFK Overlay)", "Layar hitam hemat daya & batas 15 FPS untuk AFK", Config.Performance.GpuSaver, function(val)
        Config.Performance.GpuSaver = val
        State:Set("IsGpuSaver", val)
        FpsBooster:SetGpuSaver(val, State, Config.Performance.TargetFps)
    end)

    -- [TAB 3: UTILITAS]
    local utilPage = Tabs["Utilitas"]
    createToggle(utilPage, "Anti-AFK Proteksi 20 Menit", "Mencegah kick bawaan Roblox saat idle", Config.AntiAfk.Enabled, function(val)
        Config.AntiAfk.Enabled = val
        State:Set("IsAntiAfk", val)
        if val then AntiAfk:Start(Config.AntiAfk) else AntiAfk:Stop() end
    end)

    createToggle(utilPage, "Auto Jual Ikan Berkala", "Menjual semua ikan otomatis setiap " .. tostring(Config.AutoSell.Interval) .. " detik", Config.AutoSell.Enabled, function(val)
        Config.AutoSell.Enabled = val
        State:Set("IsAutoSell", val)
        if val then AutoSell:Start(Config.AutoSell.Interval) else AutoSell:Stop() end
    end)

    createActionButton(utilPage, "Jual Semua Ikan Sekarang", "Eksekusi remote jual seluruh hasil pancingan", function()
        if Network.HasRemotes then
            local ok = Network:SellAll()
            State.LastStatusMessage = ok and "Ikan terjual ke toko!" or "Gagal memanggil remote toko!"
        else
            State.LastStatusMessage = "Remote toko tidak ditemukan!"
        end
    end)

    -- [TAB 4: STATISTIK]
    local statPage = Tabs["Status"]
    local statCard = Instance.new("Frame")
    statCard.Size = UDim2.new(1, -6, 0, 160)
    statCard.BackgroundColor3 = Config.UI.Theme.CardBg
    statCard.BorderSizePixel = 0
    statCard.Parent = statPage

    local scCorner = Instance.new("UICorner")
    scCorner.CornerRadius = UDim.new(0, 10)
    scCorner.Parent = statCard

    local statText = Instance.new("TextLabel")
    statText.Size = UDim2.new(1, -24, 1, -20)
    statText.Position = UDim2.new(0, 12, 0, 10)
    statText.BackgroundTransparency = 1
    statText.TextColor3 = Config.UI.Theme.Text
    statText.TextSize = 13
    statText.Font = Enum.Font.Gotham
    statText.TextXAlignment = Enum.TextXAlignment.Left
    statText.TextYAlignment = Enum.TextYAlignment.Top
    statText.RichText = true
    statText.Parent = statCard

    task.spawn(function()
        while screenGui.Parent do
            local elapsed = State:GetElapsedTime()
            local statusColor = State.IsFishing and "#2ecc71" or "#e74c3c"
            local statusText = State.IsFishing and "Aktif Berjalan" or "Nonaktif"

            statText.Text = string.format([[
<b>STATISTIK FARMING SESI INI:</b>

⏱️ <b>Waktu Berjalan:</b> %s
🐟 <b>Ikan Tertangkap:</b> %d Ekor
⚙️ <b>Status Memancing:</b> <font color="%s">%s</font>
🛡️ <b>Anti-AFK:</b> <font color="%s">%s</font>
⚡ <b>Mode Grafis:</b> %s
📢 <b>Log Terakhir:</b> %s
]],
                elapsed,
                State.FishCaught,
                statusColor,
                statusText,
                State.IsAntiAfk and "#2ecc71" or "#e74c3c",
                State.IsAntiAfk and "Melindungi" or "Mati",
                State.IsFpsBoost and "FPS Boost Aktif" or "Normal",
                State.LastStatusMessage or "-"
            )
            task.wait(1)
        end
    end)

    -- Mobile floating button
    local mobileToggleBtn = Instance.new("TextButton")
    mobileToggleBtn.Name = "Bodoamat_MobileBtn"
    mobileToggleBtn.Size = UDim2.new(0, 42, 0, 42)
    mobileToggleBtn.Position = UDim2.new(0, 15, 0.5, -21)
    mobileToggleBtn.BackgroundColor3 = Config.UI.Theme.CardBg
    mobileToggleBtn.Text = "🐟"
    mobileToggleBtn.TextSize = 22
    mobileToggleBtn.Parent = screenGui

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(1, 0)
    mCorner.Parent = mobileToggleBtn

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Config.UI.Theme.Accent
    mStroke.Thickness = 1.5
    mStroke.Parent = mobileToggleBtn

    mobileToggleBtn.MouseButton1Click:Connect(function() mainFrame.Visible = not mainFrame.Visible end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Config.UI.ToggleKey then mainFrame.Visible = not mainFrame.Visible end
    end)

    switchTab("Fishing")
end

-- ====================================================================
-- [10. INISIALISASI UTAMA]
-- ====================================================================
AntiAfk:Start(Config.AntiAfk)
BuildGui()

print("======================================================")
print("✨ [Bodoamat] Berhasil dimuat!")
print("🎮 Tekan 'RightShift' atau klik tombol ikan 🐟 untuk buka UI.")
print("======================================================")
