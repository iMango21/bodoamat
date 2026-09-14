--!strict
--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                       ⚡ BE REBEL v3.1.1 ⚡                           ║
    ║       Universal Screen Assistant & Hub (Bodoamat UI/UX)         ║
    ║       Delta Executor Android Pure Screen Hardware Simulator     ║
    ║       BAC Stealth Immunity (Bebas BAC-2225/8226/2223/1224/2226) ║
    ║       Floating Quick-Bar: [MENU] + [▶ PLAY / ⏸ PAUSE]            ║
    ║       Active Tab: Local Player Movement (WaterWalk & InfJump)   ║
    ║       Pixel-Perfect Pin & Screen Inset Synchronization          ║
    ║       Default Interval: 1.0 Detik (1000ms) per Klik             ║
    ║       Design Language: Bodoamat Dark-Glassmorphism Hub          ║
    ╚══════════════════════════════════════════════════════════════════╝

    [ CARA EKSEKUSI GITHUB (LOADSTRING ANTI-CACHE) ]:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/iMango21/bodoamat/main/BeRebel.luau?t=" .. tostring(os.time())))()
]]

-- 1. Tunggu game selesai dimuat
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 2. Proteksi Instance Duplikat (Clean Re-execution Guard)
local genv = (getgenv and getgenv()) or {}
if genv.__RB_SESSION_ACTIVE then
    pcall(function()
        if genv.__RB_SESSION_CLEANUP then
            genv.__RB_SESSION_CLEANUP()
        end
    end)
end
genv.__RB_SESSION_ACTIVE = true

-- ====================================================================
-- GLOBAL SERVICES & ENGINE SHORTCUTS
-- ====================================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local CurrentCamera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- ====================================================================
-- KONFIGURASI TEMA (BODOAMAT DARK-GLASSMORPHISM)
-- ====================================================================
local Config = {
    StorageFile = "BeRebel_Config.json",
    UI = {
        Title = "BE REBEL",
        Subtitle = "Universal Screen Assistant & QoL Hub v3.1.1",
        ToggleKey = Enum.KeyCode.RightShift,
        Theme = {
            Background  = Color3.fromRGB(16, 18, 26),
            CardBg      = Color3.fromRGB(24, 28, 38),
            CardHover   = Color3.fromRGB(32, 38, 52),
            Sidebar     = Color3.fromRGB(20, 22, 30),
            Border      = Color3.fromRGB(40, 46, 62),
            Accent      = Color3.fromRGB(0, 180, 255),
            AccentHover = Color3.fromRGB(40, 200, 255),
            AccentGlow  = Color3.fromRGB(0, 220, 255),
            Success     = Color3.fromRGB(46, 204, 113),
            Warning     = Color3.fromRGB(241, 196, 15),
            Danger      = Color3.fromRGB(231, 76, 60),
            Text        = Color3.fromRGB(240, 243, 246),
            TextSubtle  = Color3.fromRGB(140, 148, 164),
        }
    },
    Clicker = {
        DefaultInterval = 1000,   -- 1000 ms (1 Detik per klik)
        DefaultHold = 28,         -- 28 ms press duration
        Humanize = true,          -- Anti-bot timing & coordinate jitter
        JitterMs = 32,            -- ±32 ms
        JitterPx = 3,             -- ±3 pixel offset
    }
}

-- ====================================================================
-- STORAGE PERSISTENCE (AUTO-SAVE / AUTO-LOAD JSON)
-- ====================================================================
local Storage = {}

function Storage:Load(): { [string]: any }?
    local isfile = isfile or (genv and genv.isfile)
    local readfile = readfile or (genv and genv.readfile)
    
    if isfile and readfile and isfile(Config.StorageFile) then
        local ok, content = pcall(readfile, Config.StorageFile)
        if ok and type(content) == "string" and #content > 0 then
            local okJson, data = pcall(function()
                return HttpService:JSONDecode(content)
            end)
            if okJson and type(data) == "table" then
                return data
            end
        end
    end
    return nil
end

function Storage:Save(data: { [string]: any })
    local writefile = writefile or (genv and genv.writefile)
    if writefile then
        pcall(function()
            local encoded = HttpService:JSONEncode(data)
            writefile(Config.StorageFile, encoded)
        end)
    end
end

-- ====================================================================
-- STATE MANAGEMENT (REAKTIF & TERISOLASI)
-- ====================================================================
local savedData = Storage:Load() or {}

local State = {
    IsRunning = false,
    IntervalMs = savedData.IntervalMs or Config.Clicker.DefaultInterval,
    HoldDurationMs = savedData.HoldDurationMs or Config.Clicker.DefaultHold,
    IsPinVisible = true,
    IsHumanize = (savedData.IsHumanize ~= nil) and savedData.IsHumanize or Config.Clicker.Humanize,
    
    -- Target Screen Position (Tengah Layar Default)
    TargetPosition = Vector2.new(640, 360),
    
    -- Live Statistics
    TotalClicks = 0,
    StartTime = os.time(),
    LastStatus = "Siap (Standby)",

    -- Tab State
    CurrentTab = "Clicker",

    -- Movement State
    IsWaterWalk = false,
    IsInfJump = false,
    WalkSpeed = 16,
    JumpPower = 50,

    -- Event Listeners Registry
    Listeners = {} :: { [string]: { (any) -> () } }
}

function State:Set(key: string, value: any)
    (self :: any)[key] = value
    if self.Listeners[key] then
        for _, callback in ipairs(self.Listeners[key]) do
            task.spawn(callback, value)
        end
    end

    if key == "IntervalMs" or key == "HoldDurationMs" or key == "IsHumanize" then
        Storage:Save({
            IntervalMs = self.IntervalMs,
            HoldDurationMs = self.HoldDurationMs,
            IsHumanize = self.IsHumanize,
        })
    end
end

function State:OnChange(key: string, callback: (any) -> ())
    if not self.Listeners[key] then
        self.Listeners[key] = {}
    end
    table.insert(self.Listeners[key], callback)
end

function State:GetElapsedTime(): string
    local elapsed = os.time() - self.StartTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    local seconds = elapsed % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

-- ====================================================================
-- MODULE: LOCAL PLAYER & MOVEMENT (BODOAMAT v3.0 ENGINE)
-- ====================================================================
local MovementModule = {
    IsWaterWalk = false,
    IsInfJump = false,
    JumpPower = 50,
    WalkSpeed = 16,
    
    WaterPlatform = nil :: Part?,
    HeartbeatConn = nil :: RBXScriptConnection?,
    JumpConn = nil :: RBXScriptConnection?,
}

-- 1. Walk on Water (Jesus Walk)
function MovementModule:SetWaterWalk(enabled: boolean)
    if self.IsWaterWalk == enabled then return end
    self.IsWaterWalk = enabled
    State:Set("IsWaterWalk", enabled)

    if enabled then
        pcall(function()
            if not self.WaterPlatform then
                local part = Instance.new("Part")
                part.Name = "TerrainWaterPlate"
                part.Size = Vector3.new(24, 1.2, 24)
                part.Anchored = true
                part.CanCollide = true
                part.Transparency = 1
                part.Material = Enum.Material.Air
                part.Archivable = false
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
                    -- Platform sejajar di bawah kaki karakter di permukaan air laut (-0.6)
                    self.WaterPlatform.CFrame = CFrame.new(hrp.Position.X, -0.6, hrp.Position.Z)
                end

                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if self.JumpPower ~= 50 and hum.JumpPower ~= self.JumpPower then
                        hum.JumpPower = self.JumpPower
                    end
                    if self.WalkSpeed ~= 16 and hum.WalkSpeed ~= self.WalkSpeed then
                        hum.WalkSpeed = self.WalkSpeed
                    end
                end
            end)
        end
    else
        if not self.IsWaterWalk and self.JumpPower == 50 and self.WalkSpeed == 16 then
            if self.HeartbeatConn then
                self.HeartbeatConn:Disconnect()
                self.HeartbeatConn = nil
            end
        end

        if self.WaterPlatform then
            pcall(function() self.WaterPlatform:Destroy() end)
            self.WaterPlatform = nil
        end
    end
end

-- 2. Infinite Jump
function MovementModule:SetInfiniteJump(enabled: boolean)
    if self.IsInfJump == enabled then return end
    self.IsInfJump = enabled
    State:Set("IsInfJump", enabled)

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

-- 3. Custom JumpPower
function MovementModule:SetJumpPower(power: number)
    self.JumpPower = math.clamp(power, 50, 250)
    State:Set("JumpPower", self.JumpPower)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = self.JumpPower end
    end
end

-- 4. Custom WalkSpeed
function MovementModule:SetWalkSpeed(speed: number)
    self.WalkSpeed = math.clamp(speed, 16, 150)
    State:Set("WalkSpeed", self.WalkSpeed)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = self.WalkSpeed end
    end
end

function MovementModule:Cleanup()
    self:SetWaterWalk(false)
    self:SetInfiniteJump(false)
    if self.HeartbeatConn then
        self.HeartbeatConn:Disconnect()
        self.HeartbeatConn = nil
    end
    if self.JumpConn then
        self.JumpConn:Disconnect()
        self.JumpConn = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end
end

-- ====================================================================
-- INPUT SIMULATION ENGINE (PURE HARDWARE SCREEN CLICKING - ZERO TOOL HOOK)
-- ====================================================================
local ClickEngine = {
    RunnerThread = nil :: thread?,
    PulseCallback = nil :: (() -> ())?,
}

-- Eksekusi 1 Ketukan Hardware Layar (Prioritas: VirtualInputManager clickCount=1 + Full Coordinate Mapping)
function ClickEngine:ExecuteClick(x: number, y: number, holdDurationMs: number): boolean
    local holdSec = math.max(0.018, holdDurationMs / 1000)
    local executed = false

    -- 1. Validasi & Clamping Koordinat Layar Nyata (Mencegah Flag BAC-2225 dari Koordinat 0,0)
    local camVp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    local safeX = math.clamp(x, 10, math.max(20, camVp.X - 10))
    local safeY = math.clamp(y, 10, math.max(20, camVp.Y - 10))

    -- LAPISAN 1: ROBLOX ENGINE VIRTUAL INPUT (Prioritas Utama: 100% Native & Anti-Cheat Proof)
    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, game, 1)
            task.wait(holdSec)
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, game, 1)
        end)
        if ok then
            executed = true
        end
    end

    -- LAPISAN 2: EXECUTOR NATIVE C-CLOSURES DENGAN PENETAPAN POSISI KURSOR (Fallback Khusus)
    if not executed then
        local mousemoveabs = mousemoveabs or (genv and genv.mousemoveabs) or (genv and genv.movemouseabs) or (genv and genv.mouseto)
        if mousemoveabs then
            pcall(function() mousemoveabs(safeX, safeY) end)
        end

        local touchclick = touchclick or (genv and genv.touchclick)
        local tap = tap or (genv and genv.tap)
        local mouse1press = mouse1press or (genv and genv.mouse1press)
        local mouse1release = mouse1release or (genv and genv.mouse1release)
        local mouse1click = mouse1click or (genv and genv.mouse1click)

        if touchclick then
            pcall(function() touchclick(safeX, safeY) end)
            executed = true
        elseif tap then
            pcall(function() tap(safeX, safeY) end)
            executed = true
        elseif mouse1press and mouse1release then
            pcall(function()
                mouse1press()
                task.wait(holdSec)
                mouse1release()
            end)
            executed = true
        elseif mouse1click then
            pcall(function() mouse1click() end)
            executed = true
        end
    end

    return executed
end

-- Mulai Loop Auto Clicker
function ClickEngine:Start()
    if State.IsRunning then return end
    State:Set("IsRunning", true)
    State:Set("LastStatus", "Aktif (Running)")

    self.RunnerThread = task.spawn(function()
        local clickCounter = 0
        local nextMicroPauseAt = math.random(14, 22)

        while State.IsRunning do
            local basePos = State.TargetPosition
            local targetX = basePos.X
            local targetY = basePos.Y
            local currentInterval = State.IntervalMs
            local currentHold = State.HoldDurationMs

            -- 1. GAUSSIAN HUMAN JITTER (Timing & Posisi Alami)
            if State.IsHumanize then
                local offsetX = math.random(-Config.Clicker.JitterPx, Config.Clicker.JitterPx)
                local offsetY = math.random(-Config.Clicker.JitterPx, Config.Clicker.JitterPx)
                local offsetMs = math.random(-Config.Clicker.JitterMs, Config.Clicker.JitterMs)
                local holdOffsetMs = math.random(-6, 8)
                
                local camSize = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
                targetX = math.clamp(targetX + offsetX, 10, camSize.X - 10)
                targetY = math.clamp(targetY + offsetY, 10, camSize.Y - 10)
                currentInterval = math.max(65, currentInterval + offsetMs)
                currentHold = math.clamp(currentHold + holdOffsetMs, 8, 38)
            end

            -- Visual Pulse Feedback pada Target Pin
            if self.PulseCallback then
                task.spawn(self.PulseCallback)
            end

            -- Durasi hold dinamis
            local effectiveHold = math.min(currentHold, math.max(8, currentInterval * 0.35))

            -- Eksekusi Klik Nyata pada Layar
            self:ExecuteClick(targetX, targetY, effectiveHold)
            State:Set("TotalClicks", State.TotalClicks + 1)
            clickCounter = clickCounter + 1

            -- 2. HUMAN STAMINA MICRO-PAUSE (Refleks Jari Manusia)
            if State.IsHumanize and (clickCounter >= nextMicroPauseAt) then
                clickCounter = 0
                nextMicroPauseAt = math.random(14, 22)
                local pauseDuration = math.random(140, 260) / 1000
                task.wait(pauseDuration)
            else
                local netWait = math.max(0.002, (currentInterval - effectiveHold) / 1000)
                task.wait(netWait)
            end
        end
    end)
end

-- Hentikan Loop Auto Clicker
function ClickEngine:Stop()
    if not State.IsRunning then return end
    State:Set("IsRunning", false)
    State:Set("LastStatus", "Dijeda (Paused)")

    if self.RunnerThread then
        task.cancel(self.RunnerThread)
        self.RunnerThread = nil
    end
end

function ClickEngine:Toggle()
    if State.IsRunning then
        self:Stop()
    else
        self:Start()
    end
end

-- ====================================================================
-- STEALTH CONTAINER & GUI ENGINE (BODOAMAT ARCHITECTURE)
-- ====================================================================
local function getSafeGuiContainer(): Instance
    -- 1. Prioritas Utama: gethui() (Executor Hidden UI - 100% aman & terisolasi dari BAC-6228)
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui and typeof(hui) == "Instance" then
            return hui
        end
    end
    if getfenv and getfenv().gethui then
        local ok, hui = pcall(getfenv().gethui)
        if ok and hui and typeof(hui) == "Instance" then
            return hui
        end
    end
    local genvRef = (getgenv and getgenv()) or {}
    if genvRef.gethui then
        local ok, hui = pcall(genvRef.gethui)
        if ok and hui and typeof(hui) == "Instance" then
            return hui
        end
    end

    -- 2. Fallback aman ke PlayerGui (TIDAK PERNAH MENYENTUH CoreGui untuk mencegah tripwire BAC-6228)
    return LocalPlayer:WaitForChild("PlayerGui")
end

local BeRebelGui = {
    ScreenGui = nil :: ScreenGui?,
    MainFrame = nil :: Frame?,
    FloatingBar = nil :: Frame?,
    MenuBtn = nil :: TextButton?,
    PlayBtn = nil :: TextButton?,
    TargetPin = nil :: Frame?,
    CurrentTab = "Clicker",
    Tabs = {} :: { [string]: ScrollingFrame },
    TabButtons = {} :: { [string]: TextButton },
    Connections = {} :: { any },
}

function BeRebelGui:Create()
    -- 1. Bersihkan sisa GUI lama dari container jika ada
    pcall(function()
        local container = getSafeGuiContainer()
        if container then
            local oldHud = container:FindFirstChild("FishItHUD")
            if oldHud then oldHud:Destroy() end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            local oldHud = pg:FindFirstChild("FishItHUD")
            if oldHud then oldHud:Destroy() end
        end
    end)

    -- 2. Buat ScreenGui Utama dengan Stealth Container & Fullscreen Inset Sync
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 100000
    screenGui.IgnoreGuiInset = true -- Sinkronisasi 1:1 Koordinat Layar dengan Mouse/Touch
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Proteksi syn.protect_gui jika didukung executor
    local synProtect = (syn and syn.protect_gui) or (genv.syn and genv.syn.protect_gui) or protectgui
    if synProtect then
        pcall(synProtect, screenGui)
    end

    screenGui.Parent = getSafeGuiContainer()
    self.ScreenGui = screenGui

    local theme = Config.UI.Theme
    local vp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    State.TargetPosition = Vector2.new(math.floor(vp.X / 2), math.floor(vp.Y / 2))

    -- ========================================================
    -- A. FLOATING DOCK BAR: [ MENU ] + [ ▶ PLAY / ⏸ PAUSE ]
    -- ========================================================
    local floatBar = Instance.new("Frame")
    floatBar.Name = "AppFloatingBar"
    floatBar.Size = UDim2.new(0, 142, 0, 32)
    floatBar.Position = UDim2.new(0, 20, 0.5, -16)
    floatBar.BackgroundTransparency = 1
    floatBar.Active = true
    floatBar.ZIndex = 80
    floatBar.Parent = screenGui
    self.FloatingBar = floatBar

    local floatLayout = Instance.new("UIListLayout")
    floatLayout.FillDirection = Enum.FillDirection.Horizontal
    floatLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    floatLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    floatLayout.Padding = UDim.new(0, 6)
    floatLayout.SortOrder = Enum.SortOrder.LayoutOrder
    floatLayout.Parent = floatBar

    -- 1. Tombol MENU
    local menuBtn = Instance.new("TextButton")
    menuBtn.Name = "AppMenuBtn"
    menuBtn.Size = UDim2.new(0, 58, 0, 32)
    menuBtn.BackgroundColor3 = theme.CardBg
    menuBtn.Text = "MENU"
    menuBtn.TextColor3 = theme.Text
    menuBtn.TextSize = 11
    menuBtn.Font = Enum.Font.GothamBold
    menuBtn.Active = true
    menuBtn.ZIndex = 81
    menuBtn.LayoutOrder = 1
    menuBtn.Parent = floatBar
    self.MenuBtn = menuBtn

    local mbCorner = Instance.new("UICorner")
    mbCorner.CornerRadius = UDim.new(0, 8)
    mbCorner.Parent = menuBtn

    local mbStroke = Instance.new("UIStroke")
    mbStroke.Color = theme.Accent
    mbStroke.Thickness = 1.2
    mbStroke.Parent = menuBtn

    -- 2. Tombol PLAY / PAUSE (Di samping tombol MENU)
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "AppPlayBtn"
    playBtn.Size = UDim2.new(0, 76, 0, 32)
    playBtn.BackgroundColor3 = Color3.fromRGB(24, 36, 44)
    playBtn.Text = "▶ PLAY"
    playBtn.TextColor3 = theme.Success
    playBtn.TextSize = 11
    playBtn.Font = Enum.Font.GothamBold
    playBtn.Active = true
    playBtn.ZIndex = 81
    playBtn.LayoutOrder = 2
    playBtn.Parent = floatBar
    self.PlayBtn = playBtn

    local pbCorner = Instance.new("UICorner")
    pbCorner.CornerRadius = UDim.new(0, 8)
    pbCorner.Parent = playBtn

    local pbStroke = Instance.new("UIStroke")
    pbStroke.Color = theme.Success
    pbStroke.Thickness = 1.2
    pbStroke.Parent = playBtn

    -- Logika Dragging Seluruh Floating Dock Bar (Sentuh & Geser)
    local fbDragging, fbDragInput, fbDragStart, fbStartPos
    local fbHasMoved = false

    local function setupDockDrag(btnInstance: GuiButton)
        local connStart = btnInstance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fbDragging = true
                fbHasMoved = false
                fbDragStart = input.Position
                fbStartPos = floatBar.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        fbDragging = false
                    end
                end)
            end
        end)
        table.insert(self.Connections, connStart)

        local connChange = btnInstance.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                fbDragInput = input
            end
        end)
        table.insert(self.Connections, connChange)
    end

    setupDockDrag(menuBtn)
    setupDockDrag(playBtn)

    local connDockMove = UserInputService.InputChanged:Connect(function(input)
        if input == fbDragInput and fbDragging then
            local delta = input.Position - fbDragStart
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                fbHasMoved = true
            end
            floatBar.Position = UDim2.new(
                fbStartPos.X.Scale,
                fbStartPos.X.Offset + delta.X,
                fbStartPos.Y.Scale,
                fbStartPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(self.Connections, connDockMove)

    -- Handler Klik Tombol Floating Bar
    menuBtn.MouseButton1Click:Connect(function()
        if not fbHasMoved and self.MainFrame then
            self.MainFrame.Visible = not self.MainFrame.Visible
        end
    end)

    playBtn.MouseButton1Click:Connect(function()
        if not fbHasMoved then
            ClickEngine:Toggle()
        end
    end)

    State:OnChange("IsRunning", function(running)
        if running then
            playBtn.Text = "⏸ PAUSE"
            playBtn.TextColor3 = theme.Warning
            playBtn.BackgroundColor3 = Color3.fromRGB(38, 32, 20)
            pbStroke.Color = theme.Warning
        else
            playBtn.Text = "▶ PLAY"
            playBtn.TextColor3 = theme.Success
            playBtn.BackgroundColor3 = Color3.fromRGB(24, 36, 44)
            pbStroke.Color = theme.Success
        end
    end)

    -- ========================================================
    -- B. SINGLE TARGET PIN MARKER (PIXEL-PERFECT SYNCED)
    -- ========================================================
    local pinSize = 46
    local targetPin = Instance.new("Frame")
    targetPin.Name = "TargetPin"
    targetPin.Size = UDim2.new(0, pinSize, 0, pinSize)
    targetPin.AnchorPoint = Vector2.new(0.5, 0.5)
    targetPin.Position = UDim2.new(0, State.TargetPosition.X, 0, State.TargetPosition.Y)
    targetPin.BackgroundColor3 = theme.Background
    targetPin.BackgroundTransparency = 0.35
    targetPin.BorderSizePixel = 0
    targetPin.Active = false -- Click Passthrough: Tidak menyerap klik, langsung tembus ke game
    targetPin.ZIndex = 50
    targetPin.Parent = screenGui
    self.TargetPin = targetPin

    local pinCorner = Instance.new("UICorner")
    pinCorner.CornerRadius = UDim.new(1, 0)
    pinCorner.Parent = targetPin

    local pinStroke = Instance.new("UIStroke")
    pinStroke.Color = theme.Accent
    pinStroke.Thickness = 2
    pinStroke.Transparency = 0.1
    pinStroke.Parent = targetPin

    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Size = UDim2.new(0, 8, 0, 8)
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.BackgroundColor3 = theme.AccentGlow
    centerDot.BorderSizePixel = 0
    centerDot.ZIndex = 52
    centerDot.Parent = targetPin

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    local pinLabel = Instance.new("TextLabel")
    pinLabel.Size = UDim2.new(1, 0, 1, 0)
    pinLabel.BackgroundTransparency = 1
    pinLabel.Text = "1"
    pinLabel.TextColor3 = theme.Text
    pinLabel.TextSize = 13
    pinLabel.Font = Enum.Font.GothamBold
    pinLabel.ZIndex = 51
    pinLabel.Parent = targetPin

    local chH = Instance.new("Frame")
    chH.Size = UDim2.new(1, 10, 0, 1)
    chH.AnchorPoint = Vector2.new(0.5, 0.5)
    chH.Position = UDim2.new(0.5, 0, 0.5, 0)
    chH.BackgroundColor3 = theme.Accent
    chH.BackgroundTransparency = 0.5
    chH.BorderSizePixel = 0
    chH.ZIndex = 49
    chH.Parent = targetPin

    local chV = Instance.new("Frame")
    chV.Size = UDim2.new(0, 1, 1, 10)
    chV.AnchorPoint = Vector2.new(0.5, 0.5)
    chV.Position = UDim2.new(0.5, 0, 0.5, 0)
    chV.BackgroundColor3 = theme.Accent
    chV.BackgroundTransparency = 0.5
    chV.BorderSizePixel = 0
    chV.ZIndex = 49
    chV.Parent = targetPin

    -- Dragging Target Pin (Pixel-Perfect Cursor / Touch Center Tracking)
    local pinDragging = false

    local connPinStart = targetPin.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pinDragging = true

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    pinDragging = false
                end
            end)
        end
    end)
    table.insert(self.Connections, connPinStart)

    local connDragPin = UserInputService.InputChanged:Connect(function(input)
        if pinDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local camVp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
            local newX = math.clamp(input.Position.X, pinSize / 2, camVp.X - (pinSize / 2))
            local newY = math.clamp(input.Position.Y, pinSize / 2, camVp.Y - (pinSize / 2))

            targetPin.Position = UDim2.new(0, newX, 0, newY)
            State.TargetPosition = Vector2.new(newX, newY)
        end
    end)
    table.insert(self.Connections, connDragPin)

    -- Visual Pulse Feedback
    ClickEngine.PulseCallback = function()
        pcall(function()
            pinStroke.Color = theme.Success
            pinStroke.Thickness = 3
            centerDot.BackgroundColor3 = theme.Success
            task.wait(0.04)
            pinStroke.Color = State.IsRunning and theme.AccentGlow or theme.Accent
            pinStroke.Thickness = 2
            centerDot.BackgroundColor3 = theme.AccentGlow
        end)
    end

    State:OnChange("IsRunning", function(running)
        if running then
            pinStroke.Color = theme.AccentGlow
            pinLabel.TextColor3 = theme.Success
        else
            pinStroke.Color = theme.Accent
            pinLabel.TextColor3 = theme.Text
        end
    end)

    State:OnChange("IsPinVisible", function(visible)
        targetPin.Visible = visible
    end)

    -- ========================================================
    -- C. JENDELA UTAMA HUB (BODOAMAT MAIN WINDOW)
    -- ========================================================
    local initW = math.min(620, math.max(540, vp.X - 40))
    local initH = math.min(460, math.max(400, vp.Y - 40))

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.new(0, initW, 0, initH)
    mainFrame.Position = UDim2.new(0.5, -math.floor(initW / 2), 0.5, -math.floor(initH / 2))
    mainFrame.BackgroundColor3 = theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.ClipsDescendants = true
    mainFrame.ZIndex = 60
    mainFrame.Parent = screenGui
    self.MainFrame = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = theme.Border
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    -- Logika Dragging MainWindow (Header & Frame Drag)
    local winDragging, winDragInput, winDragStart, winStartPos
    local connWinStart = mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            winDragging = true
            winDragStart = input.Position
            winStartPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    winDragging = false
                end
            end)
        end
    end)
    table.insert(self.Connections, connWinStart)

    local connWinChange = mainFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            winDragInput = input
        end
    end)
    table.insert(self.Connections, connWinChange)

    local connWinMove = UserInputService.InputChanged:Connect(function(input)
        if input == winDragInput and winDragging then
            local delta = input.Position - winDragStart
            mainFrame.Position = UDim2.new(
                winStartPos.X.Scale,
                winStartPos.X.Offset + delta.X,
                winStartPos.Y.Scale,
                winStartPos.Y.Offset + delta.Y
            )
        end
    end)
    table.insert(self.Connections, connWinMove)

    -- Header Bar
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = theme.CardBg
    header.BorderSizePixel = 0
    header.ZIndex = 61
    header.Parent = mainFrame

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 12)
    headerCorner.Parent = header

    local headerPatch = Instance.new("Frame")
    headerPatch.Size = UDim2.new(1, 0, 0, 10)
    headerPatch.Position = UDim2.new(0, 0, 1, -10)
    headerPatch.BackgroundColor3 = theme.CardBg
    headerPatch.BorderSizePixel = 0
    headerPatch.ZIndex = 61
    headerPatch.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 240, 0, 22)
    titleLabel.Position = UDim2.new(0, 16, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = Config.UI.Title .. " v3.1"
    titleLabel.TextColor3 = theme.Accent
    titleLabel.TextSize = 15
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 62
    titleLabel.Parent = header

    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0, 280, 0, 16)
    subtitleLabel.Position = UDim2.new(0, 16, 0, 26)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = Config.UI.Subtitle
    subtitleLabel.TextColor3 = theme.TextSubtle
    subtitleLabel.TextSize = 10
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.ZIndex = 62
    subtitleLabel.Parent = header

    -- ========================================================
    -- SWAPPED HEADER BUTTONS: [ MAXIMIZE □ ] (LEFT) & [ EXIT X ] (RIGHT)
    -- ========================================================

    -- 1. Tombol Maximize / Perbesar Tampilan (□ / ❐) -> Posisi KIRI (-74)
    local maxBtn = Instance.new("TextButton")
    maxBtn.Name = "MaximizeButton"
    maxBtn.Size = UDim2.new(0, 30, 0, 30)
    maxBtn.Position = UDim2.new(1, -74, 0, 9)
    maxBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
    maxBtn.Text = "□"
    maxBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    maxBtn.TextSize = 15
    maxBtn.Font = Enum.Font.GothamBold
    maxBtn.ZIndex = 62
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
            local targetW = math.min(840, currentVp.X - 30)
            local targetH = math.min(580, currentVp.Y - 30)
            mainFrame.Size = UDim2.new(0, targetW, 0, targetH)
            mainFrame.Position = UDim2.new(0.5, -math.floor(targetW / 2), 0.5, -math.floor(targetH / 2))
            maxBtn.Text = "❐"
            maxBtn.TextColor3 = Color3.fromRGB(255, 180, 50)
        else
            local targetW = math.min(620, math.max(540, currentVp.X - 40))
            local targetH = math.min(460, math.max(400, currentVp.Y - 40))
            mainFrame.Size = UDim2.new(0, targetW, 0, targetH)
            mainFrame.Position = UDim2.new(0.5, -math.floor(targetW / 2), 0.5, -math.floor(targetH / 2))
            maxBtn.Text = "□"
            maxBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
        end
    end)

    -- 2. Tombol Close X -> Posisi KANAN (-38)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 9)
    closeBtn.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(240, 90, 90)
    closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 62
    closeBtn.Parent = header

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
    end)

    -- ========================================================
    -- D. SIDEBAR NAVIGASI TAB (KIRI)
    -- ========================================================
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 138, 1, -48)
    sidebar.Position = UDim2.new(0, 0, 0, 48)
    sidebar.BackgroundColor3 = theme.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ZIndex = 61
    sidebar.Parent = mainFrame

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -148, 1, -58)
    contentArea.Position = UDim2.new(0, 143, 0, 53)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex = 61
    contentArea.Parent = mainFrame

    local function createTab(tabName: string): ScrollingFrame
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = theme.Accent
        page.Visible = false
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ZIndex = 62
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
        { Id = "Clicker",   Label = "🎯 Auto Clicker" },
        { Id = "Movement",  Label = "🏃 Local Player" },
        { Id = "Selling",   Label = "💰 Auto Selling" },
        { Id = "Teleport",  Label = "📍 Teleportasi" },
        { Id = "Status",    Label = "📊 Status & Sesi" },
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
        btn.BackgroundColor3 = (t.Id == self.CurrentTab) and theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.Text = t.Label
        btn.TextColor3 = (t.Id == self.CurrentTab) and theme.Accent or theme.TextSubtle
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamMedium
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 62
        btn.Parent = sidebar

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 8)
        pad.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = btn

        self.TabButtons[t.Id] = btn

        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(t.Id)
        end)
    end

    -- ========================================================
    -- KOMPONEN UI BUILDER HELPER (BODOAMAT CARDS)
    -- ========================================================
    local function createSectionHeader(parent: Instance, text: string)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -4, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = theme.Accent
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 63
        lbl.Parent = parent
    end

    local function createToggleCard(parent: Instance, title: string, desc: string, default: boolean, onToggle: (boolean) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 50)
        card.BackgroundColor3 = theme.CardBg
        card.BorderSizePixel = 0
        card.ZIndex = 63
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -70, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 6)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 64
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -70, 0, 16)
        dLabel.Position = UDim2.new(0, 12, 0, 26)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.ZIndex = 64
        dLabel.Parent = card

        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Size = UDim2.new(0, 48, 0, 26)
        toggleBtn.Position = UDim2.new(1, -58, 0.5, -13)
        toggleBtn.BackgroundColor3 = default and theme.Success or Color3.fromRGB(48, 52, 68)
        toggleBtn.Text = default and "ON" or "OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 11
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.ZIndex = 64
        toggleBtn.Parent = card

        local tgCorner = Instance.new("UICorner")
        tgCorner.CornerRadius = UDim.new(0, 13)
        tgCorner.Parent = toggleBtn

        local isToggled = default
        toggleBtn.MouseButton1Click:Connect(function()
            isToggled = not isToggled
            toggleBtn.Text = isToggled and "ON" or "OFF"
            toggleBtn.BackgroundColor3 = isToggled and theme.Success or Color3.fromRGB(48, 52, 68)
            onToggle(isToggled)
        end)
    end

    local function createInputCard(parent: Instance, title: string, desc: string, defaultText: string, placeholder: string, onFocusLost: (string) -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 68)
        card.BackgroundColor3 = theme.CardBg
        card.BorderSizePixel = 0
        card.ZIndex = 63
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -20, 0, 18)
        tLabel.Position = UDim2.new(0, 12, 0, 6)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = title
        tLabel.TextColor3 = theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 64
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -20, 0, 14)
        dLabel.Position = UDim2.new(0, 12, 0, 24)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = theme.TextSubtle
        dLabel.TextSize = 9
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.ZIndex = 64
        dLabel.Parent = card

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(1, -24, 0, 24)
        textBox.Position = UDim2.new(0, 12, 0, 38)
        textBox.BackgroundColor3 = theme.Sidebar
        textBox.Text = defaultText
        textBox.PlaceholderText = placeholder
        textBox.TextColor3 = theme.Text
        textBox.PlaceholderColor3 = theme.TextSubtle
        textBox.TextSize = 11
        textBox.Font = Enum.Font.GothamBold
        textBox.ClearTextOnFocus = false
        textBox.ZIndex = 64
        textBox.Parent = card

        local tbCorner = Instance.new("UICorner")
        tbCorner.CornerRadius = UDim.new(0, 6)
        tbCorner.Parent = textBox

        local tbStroke = Instance.new("UIStroke")
        tbStroke.Color = theme.Border
        tbStroke.Thickness = 1
        tbStroke.Parent = textBox

        textBox.FocusLost:Connect(function()
            onFocusLost(textBox.Text)
        end)
    end

    local function createActionButton(parent: Instance, label: string, desc: string, btnText: string, onClick: () -> ())
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -4, 0, 48)
        card.BackgroundColor3 = theme.CardBg
        card.BorderSizePixel = 0
        card.ZIndex = 63
        card.Parent = parent

        local cCorner = Instance.new("UICorner")
        cCorner.CornerRadius = UDim.new(0, 8)
        cCorner.Parent = card

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -110, 0, 20)
        tLabel.Position = UDim2.new(0, 12, 0, 5)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = label
        tLabel.TextColor3 = theme.Text
        tLabel.TextSize = 12
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.ZIndex = 64
        tLabel.Parent = card

        local dLabel = Instance.new("TextLabel")
        dLabel.Size = UDim2.new(1, -110, 0, 16)
        dLabel.Position = UDim2.new(0, 12, 0, 25)
        dLabel.BackgroundTransparency = 1
        dLabel.Text = desc
        dLabel.TextColor3 = theme.TextSubtle
        dLabel.TextSize = 10
        dLabel.Font = Enum.Font.Gotham
        dLabel.TextXAlignment = Enum.TextXAlignment.Left
        dLabel.ZIndex = 64
        dLabel.Parent = card

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 90, 0, 30)
        btn.Position = UDim2.new(1, -98, 0.5, -15)
        btn.BackgroundColor3 = theme.Sidebar
        btn.Text = btnText
        btn.TextColor3 = theme.Accent
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 64
        btn.Parent = card

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 6)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = theme.Border
        bStroke.Thickness = 1
        bStroke.Parent = btn

        btn.MouseButton1Click:Connect(onClick)
    end

    -- ========================================================
    -- TAB 1: 🎯 AUTO CLICKER (AKTIF & BERFUNGSI PENUH)
    -- ========================================================
    local clickerPage = self.Tabs["Clicker"]

    -- Hero Control Card: Play / Pause Sync Status
    local heroCard = Instance.new("Frame")
    heroCard.Size = UDim2.new(1, -4, 0, 64)
    heroCard.BackgroundColor3 = theme.CardBg
    heroCard.BorderSizePixel = 0
    heroCard.ZIndex = 63
    heroCard.Parent = clickerPage

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 8)
    hCorner.Parent = heroCard

    local hStroke = Instance.new("UIStroke")
    hStroke.Color = theme.Accent
    hStroke.Thickness = 1.2
    hStroke.Parent = heroCard

    local hTitle = Instance.new("TextLabel")
    hTitle.Size = UDim2.new(1, -120, 0, 22)
    hTitle.Position = UDim2.new(0, 14, 0, 10)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "Status Ketukan Layar"
    hTitle.TextColor3 = theme.Text
    hTitle.TextSize = 13
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 64
    hTitle.Parent = heroCard

    local hStatus = Instance.new("TextLabel")
    hStatus.Size = UDim2.new(1, -120, 0, 18)
    hStatus.Position = UDim2.new(0, 14, 0, 32)
    hStatus.BackgroundTransparency = 1
    hStatus.Text = "Standby (1.0s Default per klik)"
    hStatus.TextColor3 = theme.Success
    hStatus.TextSize = 11
    hStatus.Font = Enum.Font.GothamMedium
    hStatus.TextXAlignment = Enum.TextXAlignment.Left
    hStatus.ZIndex = 64
    hStatus.Parent = heroCard

    local mainPlayBtn = Instance.new("TextButton")
    mainPlayBtn.Size = UDim2.new(0, 96, 0, 38)
    mainPlayBtn.Position = UDim2.new(1, -110, 0.5, -19)
    mainPlayBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 48)
    mainPlayBtn.Text = "▶ PLAY"
    mainPlayBtn.TextColor3 = theme.Success
    mainPlayBtn.TextSize = 12
    mainPlayBtn.Font = Enum.Font.GothamBold
    mainPlayBtn.ZIndex = 64
    mainPlayBtn.Parent = heroCard

    local mpCorner = Instance.new("UICorner")
    mpCorner.CornerRadius = UDim.new(0, 8)
    mpCorner.Parent = mainPlayBtn

    local mpStroke = Instance.new("UIStroke")
    mpStroke.Color = theme.Success
    mpStroke.Thickness = 1.4
    mpStroke.Parent = mainPlayBtn

    mainPlayBtn.MouseButton1Click:Connect(function()
        ClickEngine:Toggle()
    end)

    State:OnChange("IsRunning", function(running)
        if running then
            mainPlayBtn.Text = "⏸ PAUSE"
            mainPlayBtn.TextColor3 = theme.Warning
            mainPlayBtn.BackgroundColor3 = Color3.fromRGB(38, 32, 20)
            mpStroke.Color = theme.Warning
            hStatus.Text = "Berjalan: Mengetuk target layar..."
            hStatus.TextColor3 = theme.Warning
        else
            mainPlayBtn.Text = "▶ PLAY"
            mainPlayBtn.TextColor3 = theme.Success
            mainPlayBtn.BackgroundColor3 = Color3.fromRGB(28, 38, 48)
            mpStroke.Color = theme.Success
            hStatus.Text = "Standby (Siap digunakan)"
            hStatus.TextColor3 = theme.Success
        end
    end)

    createSectionHeader(clickerPage, "PENGATURAN TIMING KLIK")

    -- 1. Interval Input TextBox
    createInputCard(
        clickerPage,
        "Interval Klik (Milidetik / ms)",
        "Waktu jeda antar ketukan (1000ms = 1 Detik). Ubah dengan mengetik angka.",
        tostring(State.IntervalMs),
        "Default: 1000",
        function(text)
            local num = tonumber(text)
            if num and num >= 10 then
                State:Set("IntervalMs", math.floor(num))
            end
        end
    )

    -- 2. Durasi Tahan / Hold Time
    createInputCard(
        clickerPage,
        "Durasi Tekan / Hold Time (ms)",
        "Berapa lama layar ditekan sebelum dilepas (Default: 28 ms).",
        tostring(State.HoldDurationMs),
        "Default: 28",
        function(text)
            local num = tonumber(text)
            if num and num >= 5 then
                State:Set("HoldDurationMs", math.floor(num))
            end
        end
    )

    createSectionHeader(clickerPage, "RITME & VISUAL PIN TARGET")

    -- 3. Human Rhythm Toggle
    createToggleCard(
        clickerPage,
        "Human Rhythm & Timing Jitter",
        "Variasi acak alami (±32ms) dan stamina micro-pause agar aman.",
        State.IsHumanize,
        function(val)
            State:Set("IsHumanize", val)
        end
    )

    -- 4. Pin Visibility Toggle
    createToggleCard(
        clickerPage,
        "Tampilkan Pin Target di Layar",
        "Sembunyikan lingkaran target (#1) jika ingin layar lebih bersih.",
        State.IsPinVisible,
        function(val)
            State:Set("IsPinVisible", val)
        end
    )

    -- ========================================================
    -- TAB 2: 🏃 LOCAL PLAYER (ACTIVE MOVEMENT ENGINE BODOAMAT)
    -- ========================================================
    local movementPage = self.Tabs["Movement"]

    createSectionHeader(movementPage, "PERGERAKAN & LOMPATAN (BODOAMAT v3.0)")
    
    createToggleCard(
        movementPage,
        "Walk On Water (Jesus Walk)",
        "Berjalan di atas permukaan air laut tanpa tenggelam.",
        MovementModule.IsWaterWalk,
        function(val)
            MovementModule:SetWaterWalk(val)
        end
    )

    createToggleCard(
        movementPage,
        "Infinite Jump",
        "Lompat bebas di udara tanpa menyentuh tanah.",
        MovementModule.IsInfJump,
        function(val)
            MovementModule:SetInfiniteJump(val)
        end
    )

    createInputCard(
        movementPage,
        "Kustom WalkSpeed",
        "Kecepatan jalan karakter (Default: 16, Maks: 150).",
        tostring(MovementModule.WalkSpeed),
        "Contoh: 32",
        function(text)
            local num = tonumber(text)
            if num then
                MovementModule:SetWalkSpeed(num)
            end
        end
    )

    createInputCard(
        movementPage,
        "Kustom JumpPower",
        "Kekuatan lompatan karakter (Default: 50, Maks: 250).",
        tostring(MovementModule.JumpPower),
        "Contoh: 100",
        function(text)
            local num = tonumber(text)
            if num then
                MovementModule:SetJumpPower(num)
            end
        end
    )

    -- ========================================================
    -- TAB 3: 💰 AUTO SELLING (FRONTEND READY UNTUK EKSPANSI)
    -- ========================================================
    local sellingPage = self.Tabs["Selling"]

    createSectionHeader(sellingPage, "OTOMASI PENJUALAN ITEM")
    createToggleCard(sellingPage, "Enable Auto Selling", "Menjual item/ikan otomatis saat tas penuh.", false, function(v) end)
    createInputCard(sellingPage, "Batas Threshold Tas", "Jual otomatis saat jumlah item di tas mencapai nilai ini.", "1000", "Default: 1000", function(t) end)
    createActionButton(sellingPage, "Mode Penjualan", "Pilihan metode penjualan saat siklus berlangsung.", "With Limit", function() end)
    createActionButton(sellingPage, "Amankan Kelangkaan Minimal", "Ikan dengan rarity ini ke atas tidak akan dijual.", "Legendary", function() end)

    -- ========================================================
    -- TAB 4: 📍 TELEPORTASI (FRONTEND READY UNTUK EKSPANSI)
    -- ========================================================
    local teleportPage = self.Tabs["Teleport"]

    createSectionHeader(teleportPage, "LOKASI TELEPORT CEPAT")
    createActionButton(teleportPage, "Safe Island / Hub Utama", "Teleportasi ke dermaga utama pulau aman.", "Teleport", function() end)
    createActionButton(teleportPage, "Merchant & Pasar", "Teleportasi ke area pedagang joran & umpan.", "Teleport", function() end)
    createActionButton(teleportPage, "Laut Dalam (Deep Ocean)", "Teleportasi ke area pemancingan laut lepas.", "Teleport", function() end)
    createActionButton(teleportPage, "Gua Tersembunyi", "Teleportasi ke spot mancing rahasia.", "Teleport", function() end)

    -- ========================================================
    -- TAB 5: 📊 STATUS & SESI SCRIPT
    -- ========================================================
    local statusPage = self.Tabs["Status"]

    createSectionHeader(statusPage, "INFORMASI SESI & HARDWARE")

    local statBox = Instance.new("Frame")
    statBox.Size = UDim2.new(1, -4, 0, 160)
    statBox.BackgroundColor3 = theme.CardBg
    statBox.BorderSizePixel = 0
    statBox.ZIndex = 63
    statBox.Parent = statusPage

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 8)
    sbCorner.Parent = statBox

    local statText = Instance.new("TextLabel")
    statText.Size = UDim2.new(1, -16, 1, -16)
    statText.Position = UDim2.new(0, 10, 0, 8)
    statText.BackgroundTransparency = 1
    statText.TextColor3 = theme.Text
    statText.TextSize = 11
    statText.Font = Enum.Font.Gotham
    statText.TextXAlignment = Enum.TextXAlignment.Left
    statText.TextYAlignment = Enum.TextYAlignment.Top
    statText.RichText = true
    statText.ZIndex = 64
    statText.Parent = statBox

    -- Live Status Updater Loop
    task.spawn(function()
        while screenGui.Parent do
            local elapsed = State:GetElapsedTime()
            local statusColor = State.IsRunning and "#2ecc71" or "#f1c40f"
            local pos = State.TargetPosition
            local jitterStr = State.IsHumanize and "<font color='#2ecc71'>Aktif (±32ms Jitter & Micro-Pause)</font>" or "<font color='#e74c3c'>Nonaktif</font>"

            statText.Text = string.format(
                "• <b>Status Clicker:</b> <font color='%s'>%s</font>\n" ..
                "• <b>Total Klik Terkirim:</b> <font color='#00d2ff'>%d</font>\n" ..
                "• <b>Interval Aktif:</b> <font color='#00d2ff'>%d ms</font> (Hold: %d ms)\n" ..
                "• <b>Ritme Manusia:</b> %s\n" ..
                "• <b>Posisi Target Screen:</b> X: %d, Y: %d\n" ..
                "• <b>Water Walk:</b> %s | <b>Inf Jump:</b> %s\n" ..
                "• <b>Durasi Sesi Script:</b> %s\n" ..
                "• <b>Arsitektur:</b> <font color='#2ecc71'>BeRebel Mobile Hub v3.1</font>",
                statusColor, State.LastStatus, State.TotalClicks, State.IntervalMs,
                State.HoldDurationMs, jitterStr, math.floor(pos.X), math.floor(pos.Y),
                MovementModule.IsWaterWalk and "<font color='#2ecc71'>ON</font>" or "<font color='#e74c3c'>OFF</font>",
                MovementModule.IsInfJump and "<font color='#2ecc71'>ON</font>" or "<font color='#e74c3c'>OFF</font>",
                elapsed
            )
            task.wait(0.5)
        end
    end)

    -- Shortcut Keyboard Toggle (Default: RightShift)
    local connKey = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Config.UI.ToggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)
    table.insert(self.Connections, connKey)

    -- Aktifkan tab pertama secara default
    self:SwitchTab("Clicker")
end

function BeRebelGui:SwitchTab(tabId: string)
    self.CurrentTab = tabId
    for id, page in pairs(self.Tabs) do
        page.Visible = (id == tabId)
    end
    for id, btn in pairs(self.TabButtons) do
        btn.BackgroundColor3 = (id == tabId) and Config.UI.Theme.CardBg or Color3.fromRGB(20, 22, 30)
        btn.TextColor3 = (id == tabId) and Config.UI.Theme.Accent or Config.UI.Theme.TextSubtle
    end
end

-- Bersihkan Semua Event & Hancurkan GUI (Clean Teardown)
function BeRebelGui:Destroy()
    ClickEngine:Stop()
    MovementModule:Cleanup()

    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}

    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
        self.ScreenGui = nil
    end

    genv.__RB_SESSION_ACTIVE = nil
    genv.__RB_SESSION_CLEANUP = nil
end

genv.__RB_SESSION_CLEANUP = function()
    BeRebelGui:Destroy()
end

-- Inisialisasi Script
BeRebelGui:Create()

return {
    ClickEngine = ClickEngine,
    MovementModule = MovementModule,
    State = State,
    BeRebelGui = BeRebelGui,
}
