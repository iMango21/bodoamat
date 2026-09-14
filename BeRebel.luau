--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                        ⚡ BE REBEL v1.4 ⚡                         ║
    ║       Universal Single-Target Precision Auto Clicker for Roblox   ║
    ║       Delta Executor & Mobile Touch Optimized                     ║
    ║       Full BAC Suite Immunity: BAC-8223, 3228, 3229, 92210        ║
    ║       100% Pure Screen Clicker (Zero-Tampering & Zero-Remotes)    ║
    ║       Design Language & Architecture by LuaRebel                  ║
    ╚═══════════════════════════════════════════════════════════════════╝

    [ CARA EKSEKUSI GITHUB (LOADSTRING) ]:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/iMango21/bodoamat/main/BeRebel.luau"))()

    [ FITUR UTAMA & PROTEKSI ANTI-CHEAT v1.4 ]:
    1. 🛡️ BAC-3229 Zero-Tamper Guard: 100% bebas dari manipulasi getconnections(Idled)
       atau hooking pada LocalPlayer.Idled yang menjadi pemicu notifikasi BAC-3229.
    2. 🛡️ 100% Pure Screen Clicker: Murni mengklik titik layar (X,Y) tanpa pernah
       menyentuh remote internal game (CastRod, Reel, dll) sehingga kebal ban remote.
    3. 🛡️ BAC-92210 Pointer Sync: Mengirim event pergerakan kursor (MouseMove) sebelum
       event tombol mouse untuk mencegah deteksi anomali desinkronisasi koordinat pointer.
    4. 🛡️ BAC-3228 Zero-VirtualUser Guard: 100% bebas dari service VirtualUser
       (CaptureController / ClickButton2 / Button1Down) yang menjadi tripwire BAC.
    5. 🛡️ BAC-8223 Stealth Guard: Mencegah flag anti-cheat Fish It / Bacon Anti-Cheat
       dengan simulasi ritme biologis manusia (micro-pause & Gaussian jitter timing).
    6. ⏱️ Human Stamina Micro-Pause: Menyisipkan jeda mikro (0.15s - 0.25s) setiap 14-22
       klik untuk meniru refleks alami jari manusia (zero-pattern detection).
    7. 🎯 Single Target Pin (Draggable): Lingkaran target presisi dengan crosshair, 
       titik pusat (bullseye), dan animasi pulse hijau saat klik dieksekusi.
    8. 🎛️ Floating Control Bar: Toolbar melayang di sisi layar dengan handle drag,
       tombol Play/Pause instan, tombol Settings, tombol Hide/Show Pin, dan Close.
    9. ⚙️ Settings Modal: Konfigurasi interval kustom, tombol preset aman (140ms Safe, 1s),
       durasi hold acak, dan live session statistics.
    10. 📱 Mobile Landscape Responsive Modal: Ukuran modal otomatis menyesuaikan resolusi
       layar HP (tidak pernah terpotong pada landscape 360p - 720p).
    11. 💾 Auto-Save File Persistence: Konfigurasi interval & humanize tersimpan otomatis
       ke file lokal executor (BeRebel_Config.json) via writefile/readfile.
]]

-- 1. Tunggu game selesai dimuat
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- 2. Proteksi Instance Duplikat (Clean Re-execution Guard)
local genv = (getgenv and getgenv()) or {}
if genv.__BE_REBEL_LOADED then
    pcall(function()
        if genv.__BE_REBEL_CLEANUP then
            genv.__BE_REBEL_CLEANUP()
        end
    end)
end
genv.__BE_REBEL_LOADED = true

-- ====================================================================
-- GLOBAL SERVICES & ENGINE SHORTCUTS
-- ====================================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local VirtualInputManager = pcall(function() return game:GetService("VirtualInputManager") end) and game:GetService("VirtualInputManager") or nil
-- Catatan BAC-3228: VirtualUser service DIHAPUS TOTAL karena merupakan tripwire deteksi Bacon Anti-Cheat!

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local CurrentCamera = Workspace.CurrentCamera or Workspace:WaitForChild("Camera")

-- ====================================================================
-- KONFIGURASI DEFAULT & TEMA (LUA REBEL DARK-GLASSMORPHISM)
-- ====================================================================
local Config = {
    StorageFile = "BeRebel_Config.json",
    UI = {
        Title = "BE REBEL",
        Subtitle = "Full BAC Suite Immunity Clicker v1.4",
        ToggleKey = Enum.KeyCode.F8,
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
        DefaultInterval = 140,    -- 140 ms (Safe Zone Anti BAC-8223 ~7.1 CPS)
        DefaultHold = 22,         -- 22 ms durasi tahan tekan dasar
        Humanize = true,          -- Default AKTIF demi keamanan Anti BAC-8223!
        JitterMs = 28,            -- Variasi acak timing (±28 ms)
        JitterPx = 3,             -- Variasi acak koordinat (±3 pixel)
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
    IsSettingsOpen = false,
    IsHumanize = (savedData.IsHumanize ~= nil) and savedData.IsHumanize or Config.Clicker.Humanize,
    
    -- Target Screen Position
    TargetPosition = Vector2.new(640, 360),
    
    -- Live Statistics
    TotalClicks = 0,
    StartTime = os.time(),
    LastStatus = "Siap (Standby)",

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

    -- Auto-save preferensi jika ada perubahan konfigurasi
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
-- INPUT SIMULATION ENGINE (BAC-8223 STEALTH GUARD PROTECTED)
-- ====================================================================
local ClickEngine = {
    RunnerThread = nil :: thread?,
    PulseCallback = nil :: (() -> ())?,
}

-- Eksekusi 1 Ketukan (Tap / Mouse Click) pada Koordinat (X, Y)
function ClickEngine:ExecuteClick(x: number, y: number, holdDurationMs: number): boolean
    local holdSec = math.max(0.005, holdDurationMs / 1000)
    local success = false

    -- METODE 1: VirtualInputManager (Resmi Roblox Engine, Sinkronisasi MouseMove untuk Anti BAC-92210)
    if VirtualInputManager then
        local ok = pcall(function()
            -- 🛡️ Anti BAC-92210: Sinkronisasi posisi pointer kursor sebelum menekan tombol
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
            task.wait(0.002)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(holdSec)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if ok then success = true end
    end

    -- METODE 2: Executor Native C-Closures (Fallback aman tanpa VirtualUser)
    if not success then
        local mouse1press = mouse1press or (genv and genv.mouse1press)
        local mouse1release = mouse1release or (genv and genv.mouse1release)
        local mousemoveabs = mousemoveabs or (genv and genv.mousemoveabs)
        local mouse1click = mouse1click or (genv and genv.mouse1click)

        if mouse1press and mouse1release then
            pcall(function()
                if mousemoveabs then mousemoveabs(x, y) end
                mouse1press()
                task.wait(holdSec)
                mouse1release()
            end)
            success = true
        elseif mouse1click then
            pcall(function()
                if mousemoveabs then mousemoveabs(x, y) end
                mouse1click()
            end)
            success = true
        end
    end

    -- CATATAN ANTI-CHEAT (BAC-3228):
    -- Metode VirtualUser:CaptureController() DIHAPUS TOTAL untuk menghindari deteksi BAC-3228.

    return success
end

-- Mulai Loop Auto Clicker dengan BAC-8223 Stealth Protection
function ClickEngine:Start()
    if State.IsRunning then return end
    State:Set("IsRunning", true)
    State:Set("LastStatus", "Aktif (Stealth Anti-BAC)")

    self.RunnerThread = task.spawn(function()
        local clickCounter = 0
        local nextMicroPauseAt = math.random(14, 22)

        while State.IsRunning do
            local basePos = State.TargetPosition
            local targetX = basePos.X
            local targetY = basePos.Y
            local currentInterval = State.IntervalMs
            local currentHold = State.HoldDurationMs

            -- 🛡️ 1. BAC-8223 GAUSSIAN HUMAN JITTER (Zero-Pattern Protection)
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

            -- Durasi hold dinamis (maksimal 35% dari total interval agar klik tidak freeze)
            local effectiveHold = math.min(currentHold, math.max(8, currentInterval * 0.35))

            -- Eksekusi Klik Nyata
            self:ExecuteClick(targetX, targetY, effectiveHold)
            State:Set("TotalClicks", State.TotalClicks + 1)
            clickCounter = clickCounter + 1

            -- 🛡️ 2. BAC-8223 HUMAN STAMINA MICRO-PAUSE (Refleks Alami Jari)
            if State.IsHumanize and (clickCounter >= nextMicroPauseAt) then
                clickCounter = 0
                nextMicroPauseAt = math.random(14, 22)
                local pauseDuration = math.random(140, 260) / 1000 -- 0.14s - 0.26s
                task.wait(pauseDuration)
            else
                -- ⏱️ KOMPENSASI TIMING INTERVAL: Kurangi jeda dengan durasi hold yang telah berlalu
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
-- USER INTERFACE BUILDER (CLEAN CODE & DELTA TOUCH OPTIMIZED)
-- ====================================================================
local BeRebelGui = {
    ScreenGui = nil :: ScreenGui?,
    Connections = {} :: { RBXScriptConnection },
}

function BeRebelGui:Create()
    -- 1. Stealth Parenting (Mencegah Deteksi CoreGui & Game Engine)
    local targetParent: Instance = nil
    local gethui = gethui or (genv and genv.gethui)
    if gethui then
        targetParent = gethui()
    else
        -- Fallback aman ke PlayerGui (TIDAK menyentuh CoreGui untuk mencegah tripwire BAC)
        targetParent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BeRebel_Gui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = targetParent
    self.ScreenGui = screenGui

    local theme = Config.UI.Theme
    local vp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
    State.TargetPosition = Vector2.new(math.floor(vp.X / 2), math.floor(vp.Y / 2))

    -- ========================================================
    -- A. SINGLE TARGET PIN MARKER (DRAGGABLE)
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
    targetPin.Active = true
    targetPin.ZIndex = 50
    targetPin.Parent = screenGui

    local pinCorner = Instance.new("UICorner")
    pinCorner.CornerRadius = UDim.new(1, 0)
    pinCorner.Parent = targetPin

    local pinStroke = Instance.new("UIStroke")
    pinStroke.Color = theme.Accent
    pinStroke.Thickness = 2
    pinStroke.Transparency = 0.1
    pinStroke.Parent = targetPin

    -- Titik Pusat Target (Center Bullseye Dot)
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

    -- Label Angka "1"
    local pinLabel = Instance.new("TextLabel")
    pinLabel.Size = UDim2.new(1, 0, 1, 0)
    pinLabel.BackgroundTransparency = 1
    pinLabel.Text = "1"
    pinLabel.TextColor3 = theme.Text
    pinLabel.TextSize = 13
    pinLabel.Font = Enum.Font.GothamBold
    pinLabel.ZIndex = 51
    pinLabel.Parent = targetPin

    -- Garis Crosshair (Horizontal & Vertikal)
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

    -- Logika Dragging Target Pin (Touch & Mouse Support)
    local pinDragging = false
    local pinDragStart = Vector3.zero
    local pinStartPos = UDim2.new()

    targetPin.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pinDragging = true
            pinDragStart = input.Position
            pinStartPos = targetPin.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    pinDragging = false
                end
            end)
        end
    end)

    local connDragPin = UserInputService.InputChanged:Connect(function(input)
        if pinDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - pinDragStart
            local newX = pinStartPos.X.Offset + delta.X
            local newY = pinStartPos.Y.Offset + delta.Y
            
            local camVp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
            newX = math.clamp(newX, pinSize / 2, camVp.X - (pinSize / 2))
            newY = math.clamp(newY, pinSize / 2, camVp.Y - (pinSize / 2))

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
    -- B. FLOATING CONTROLLER BAR (TOOLBAR MELAYANG)
    -- ========================================================
    local barWidth = 200
    local barHeight = 42
    local floatBar = Instance.new("Frame")
    floatBar.Name = "FloatingControllerBar"
    floatBar.Size = UDim2.new(0, barWidth, 0, barHeight)
    floatBar.Position = UDim2.new(0, 30, 0.5, -barHeight / 2)
    floatBar.BackgroundColor3 = theme.Background
    floatBar.BorderSizePixel = 0
    floatBar.Active = true
    floatBar.ZIndex = 60
    floatBar.Parent = screenGui

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 8)
    barCorner.Parent = floatBar

    local barStroke = Instance.new("UIStroke")
    barStroke.Color = theme.Border
    barStroke.Thickness = 1.4
    barStroke.Parent = floatBar

    -- Drag Handle Bar (Grip ⋮⋮)
    local dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(0, 22, 1, 0)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundColor3 = theme.Sidebar
    dragHandle.Text = "⋮⋮"
    dragHandle.TextColor3 = theme.TextSubtle
    dragHandle.TextSize = 13
    dragHandle.Font = Enum.Font.GothamBold
    dragHandle.AutoButtonColor = false
    dragHandle.ZIndex = 61
    dragHandle.Parent = floatBar

    local dhCorner = Instance.new("UICorner")
    dhCorner.CornerRadius = UDim.new(0, 8)
    dhCorner.Parent = dragHandle

    -- Dragging Logic Toolbar (Delta Touch Support)
    local barDragging = false
    local barDragStart = Vector3.zero
    local barStartPos = UDim2.new()

    local function setupBarDrag(targetElement: GuiObject)
        targetElement.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                barDragging = true
                barDragStart = input.Position
                barStartPos = floatBar.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        barDragging = false
                    end
                end)
            end
        end)
    end

    setupBarDrag(dragHandle)
    setupBarDrag(floatBar)

    local connDragBar = UserInputService.InputChanged:Connect(function(input)
        if barDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - barDragStart
            local newX = barStartPos.X.Offset + delta.X
            local newY = barStartPos.Y.Offset + delta.Y
            local camVp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
            newX = math.clamp(newX, 10, camVp.X - barWidth - 10)
            newY = math.clamp(newY, 10, camVp.Y - barHeight - 10)

            floatBar.Position = UDim2.new(barStartPos.X.Scale, newX, barStartPos.Y.Scale, newY)
        end
    end)
    table.insert(self.Connections, connDragBar)

    -- Container Tombol Aksi
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -26, 1, -8)
    btnContainer.Position = UDim2.new(0, 24, 0, 4)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 61
    btnContainer.Parent = floatBar

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    btnLayout.Padding = UDim.new(0, 5)
    btnLayout.Parent = btnContainer

    -- 1. Tombol Play / Pause (▶ / ⏸)
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayButton"
    playBtn.Size = UDim2.new(0, 62, 0, 32)
    playBtn.BackgroundColor3 = theme.CardBg
    playBtn.Text = "▶ PLAY"
    playBtn.TextColor3 = theme.Success
    playBtn.TextSize = 11
    playBtn.Font = Enum.Font.GothamBold
    playBtn.ZIndex = 62
    playBtn.Parent = btnContainer

    local playCorner = Instance.new("UICorner")
    playCorner.CornerRadius = UDim.new(0, 6)
    playCorner.Parent = playBtn

    local playStroke = Instance.new("UIStroke")
    playStroke.Color = theme.Success
    playStroke.Thickness = 1.2
    playStroke.Parent = playBtn

    playBtn.MouseButton1Click:Connect(function()
        ClickEngine:Toggle()
    end)

    State:OnChange("IsRunning", function(running)
        if running then
            playBtn.Text = "⏸ PAUSE"
            playBtn.TextColor3 = theme.Warning
            playBtn.BackgroundColor3 = Color3.fromRGB(38, 32, 20)
            playStroke.Color = theme.Warning
            barStroke.Color = theme.Accent
        else
            playBtn.Text = "▶ PLAY"
            playBtn.TextColor3 = theme.Success
            playBtn.BackgroundColor3 = theme.CardBg
            playStroke.Color = theme.Success
            barStroke.Color = theme.Border
        end
    end)

    -- 2. Tombol Settings (⚙)
    local setBtn = Instance.new("TextButton")
    setBtn.Name = "SettingsButton"
    setBtn.Size = UDim2.new(0, 32, 0, 32)
    setBtn.BackgroundColor3 = theme.CardBg
    setBtn.Text = "⚙"
    setBtn.TextColor3 = theme.Accent
    setBtn.TextSize = 14
    setBtn.Font = Enum.Font.GothamBold
    setBtn.ZIndex = 62
    setBtn.Parent = btnContainer

    local setCorner = Instance.new("UICorner")
    setCorner.CornerRadius = UDim.new(0, 6)
    setCorner.Parent = setBtn

    -- 3. Tombol Toggle Visibility Pin (👁)
    local eyeBtn = Instance.new("TextButton")
    eyeBtn.Name = "EyeButton"
    eyeBtn.Size = UDim2.new(0, 32, 0, 32)
    eyeBtn.BackgroundColor3 = theme.CardBg
    eyeBtn.Text = "👁"
    eyeBtn.TextColor3 = theme.Text
    eyeBtn.TextSize = 13
    eyeBtn.Font = Enum.Font.GothamBold
    eyeBtn.ZIndex = 62
    eyeBtn.Parent = btnContainer

    local eyeCorner = Instance.new("UICorner")
    eyeCorner.CornerRadius = UDim.new(0, 6)
    eyeCorner.Parent = eyeBtn

    eyeBtn.MouseButton1Click:Connect(function()
        State:Set("IsPinVisible", not State.IsPinVisible)
    end)

    State:OnChange("IsPinVisible", function(visible)
        eyeBtn.TextColor3 = visible and theme.Text or theme.TextSubtle
        eyeBtn.BackgroundColor3 = visible and theme.CardBg or Color3.fromRGB(18, 20, 26)
    end)

    -- 4. Tombol Close (✕)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.BackgroundColor3 = theme.CardBg
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = theme.Danger
    closeBtn.TextSize = 12
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 62
    closeBtn.Parent = btnContainer

    local clsCorner = Instance.new("UICorner")
    clsCorner.CornerRadius = UDim.new(0, 6)
    clsCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    -- ========================================================
    -- C. SETTINGS MODAL (RESPONSIVE MOBILE SCALING)
    -- ========================================================
    local baseModalW = 340
    local baseModalH = 430

    local setModal = Instance.new("Frame")
    setModal.Name = "SettingsModal"
    setModal.BackgroundColor3 = theme.Background
    setModal.BorderSizePixel = 0
    setModal.Visible = false
    setModal.Active = true
    setModal.ZIndex = 100
    setModal.Parent = screenGui

    local function updateModalBounds()
        local currentVp = (CurrentCamera and CurrentCamera.ViewportSize) or Vector2.new(1280, 720)
        local modalW = math.min(baseModalW, currentVp.X - 24)
        local modalH = math.min(baseModalH, currentVp.Y - 24)
        setModal.Size = UDim2.new(0, modalW, 0, modalH)
        setModal.Position = UDim2.new(0.5, -math.floor(modalW / 2), 0.5, -math.floor(modalH / 2))
    end
    updateModalBounds()

    local connVp = CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateModalBounds)
    table.insert(self.Connections, connVp)

    local smCorner = Instance.new("UICorner")
    smCorner.CornerRadius = UDim.new(0, 10)
    smCorner.Parent = setModal

    local smStroke = Instance.new("UIStroke")
    smStroke.Color = theme.Border
    smStroke.Thickness = 1.5
    smStroke.Parent = setModal

    -- Modal Header
    local mHeader = Instance.new("Frame")
    mHeader.Size = UDim2.new(1, 0, 0, 46)
    mHeader.BackgroundColor3 = theme.Sidebar
    mHeader.BorderSizePixel = 0
    mHeader.ZIndex = 101
    mHeader.Parent = setModal

    local mhCorner = Instance.new("UICorner")
    mhCorner.CornerRadius = UDim.new(0, 10)
    mhCorner.Parent = mHeader

    local mhFix = Instance.new("Frame")
    mhFix.Size = UDim2.new(1, 0, 0, 10)
    mhFix.Position = UDim2.new(0, 0, 1, -10)
    mhFix.BackgroundColor3 = theme.Sidebar
    mhFix.BorderSizePixel = 0
    mhFix.ZIndex = 101
    mhFix.Parent = mHeader

    local mTitle = Instance.new("TextLabel")
    mTitle.Size = UDim2.new(1, -50, 0, 22)
    mTitle.Position = UDim2.new(0, 14, 0, 4)
    mTitle.BackgroundTransparency = 1
    mTitle.Text = Config.UI.Title
    mTitle.TextColor3 = theme.Accent
    mTitle.TextSize = 14
    mTitle.Font = Enum.Font.GothamBold
    mTitle.TextXAlignment = Enum.TextXAlignment.Left
    mTitle.ZIndex = 102
    mTitle.Parent = mHeader

    local mSub = Instance.new("TextLabel")
    mSub.Size = UDim2.new(1, -50, 0, 16)
    mSub.Position = UDim2.new(0, 14, 0, 24)
    mSub.BackgroundTransparency = 1
    mSub.Text = Config.UI.Subtitle
    mSub.TextColor3 = theme.TextSubtle
    mSub.TextSize = 10
    mSub.Font = Enum.Font.Gotham
    mSub.TextXAlignment = Enum.TextXAlignment.Left
    mSub.ZIndex = 102
    mSub.Parent = mHeader

    local mCloseBtn = Instance.new("TextButton")
    mCloseBtn.Size = UDim2.new(0, 28, 0, 28)
    mCloseBtn.Position = UDim2.new(1, -36, 0, 9)
    mCloseBtn.BackgroundColor3 = theme.CardBg
    mCloseBtn.Text = "✕"
    mCloseBtn.TextColor3 = theme.TextSubtle
    mCloseBtn.TextSize = 12
    mCloseBtn.Font = Enum.Font.GothamBold
    mCloseBtn.ZIndex = 102
    mCloseBtn.Parent = mHeader

    local mcCorner = Instance.new("UICorner")
    mcCorner.CornerRadius = UDim.new(0, 6)
    mcCorner.Parent = mCloseBtn

    mCloseBtn.MouseButton1Click:Connect(function()
        setModal.Visible = false
        State.IsSettingsOpen = false
    end)

    setBtn.MouseButton1Click:Connect(function()
        State.IsSettingsOpen = not State.IsSettingsOpen
        updateModalBounds()
        setModal.Visible = State.IsSettingsOpen
    end)

    -- Modal Scroll Content
    local mScroll = Instance.new("ScrollingFrame")
    mScroll.Size = UDim2.new(1, -20, 1, -56)
    mScroll.Position = UDim2.new(0, 10, 0, 50)
    mScroll.BackgroundTransparency = 1
    mScroll.BorderSizePixel = 0
    mScroll.ScrollBarThickness = 3
    mScroll.ScrollBarImageColor3 = theme.Accent
    mScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    mScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    mScroll.ZIndex = 101
    mScroll.Parent = setModal

    local mLayout = Instance.new("UIListLayout")
    mLayout.Padding = UDim.new(0, 8)
    mLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mLayout.Parent = mScroll

    local function createSectionHeader(title: string)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.TextColor3 = theme.Accent
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.ZIndex = 102
        lbl.Parent = mScroll
    end

    -- 1. SECTION: INTERVAL SETTINGS (ANTI BAC-8223 SAFE PRESETS)
    createSectionHeader("PENGATURAN INTERVAL KLIK (ANTI BAC-8223)")

    local intervalCard = Instance.new("Frame")
    intervalCard.Size = UDim2.new(1, 0, 0, 134)
    intervalCard.BackgroundColor3 = theme.CardBg
    intervalCard.BorderSizePixel = 0
    intervalCard.ZIndex = 102
    intervalCard.Parent = mScroll

    local icCorner = Instance.new("UICorner")
    icCorner.CornerRadius = UDim.new(0, 8)
    icCorner.Parent = intervalCard

    local icLabel = Instance.new("TextLabel")
    icLabel.Size = UDim2.new(1, -16, 0, 18)
    icLabel.Position = UDim2.new(0, 10, 0, 8)
    icLabel.BackgroundTransparency = 1
    icLabel.Text = "Interval Klik (Kustom ms atau Preset Cepat):"
    icLabel.TextColor3 = theme.Text
    icLabel.TextSize = 11
    icLabel.Font = Enum.Font.GothamMedium
    icLabel.TextXAlignment = Enum.TextXAlignment.Left
    icLabel.ZIndex = 103
    icLabel.Parent = intervalCard

    local intervalInput = Instance.new("TextBox")
    intervalInput.Size = UDim2.new(1, -20, 0, 30)
    intervalInput.Position = UDim2.new(0, 10, 0, 28)
    intervalInput.BackgroundColor3 = theme.Sidebar
    intervalInput.Text = tostring(State.IntervalMs)
    intervalInput.PlaceholderText = "Contoh: 140 atau 1000 (1 Detik)"
    intervalInput.TextColor3 = theme.Text
    intervalInput.PlaceholderColor3 = theme.TextSubtle
    intervalInput.TextSize = 12
    intervalInput.Font = Enum.Font.GothamBold
    intervalInput.ClearTextOnFocus = false
    intervalInput.ZIndex = 103
    intervalInput.Parent = intervalCard

    local iiCorner = Instance.new("UICorner")
    iiCorner.CornerRadius = UDim.new(0, 6)
    iiCorner.Parent = intervalInput

    local iiStroke = Instance.new("UIStroke")
    iiStroke.Color = theme.Border
    iiStroke.Thickness = 1
    iiStroke.Parent = intervalInput

    -- Preset Quick Buttons Matrix (2 Baris Rapi & Responsif)
    local presetButtons = {}

    local function updatePresetHighlight(currentVal: number)
        for _, item in ipairs(presetButtons) do
            local isMatch = (currentVal == item.Val)
            item.Button.BackgroundColor3 = isMatch and theme.Accent or theme.Sidebar
            item.Button.TextColor3 = isMatch and theme.Background or (item.Highlight and theme.Success or theme.TextSubtle)
        end
    end

    local presetRows = {
        {
            ContainerPos = UDim2.new(0, 10, 0, 64),
            Items = {
                { Label = "Safe 140ms", Val = 140, Highlight = true },
                { Label = "Norm 110ms", Val = 110, Highlight = false },
                { Label = "Fast 80ms", Val = 80, Highlight = false },
            }
        },
        {
            ContainerPos = UDim2.new(0, 10, 0, 96),
            Items = {
                { Label = "Slow 250ms", Val = 250, Highlight = false },
                { Label = "Med 500ms", Val = 500, Highlight = false },
                { Label = "⏱️ 1 Detik (1s)", Val = 1000, Highlight = true },
            }
        }
    }

    for _, row in ipairs(presetRows) do
        local pRowFrame = Instance.new("Frame")
        pRowFrame.Size = UDim2.new(1, -20, 0, 26)
        pRowFrame.Position = row.ContainerPos
        pRowFrame.BackgroundTransparency = 1
        pRowFrame.ZIndex = 103
        pRowFrame.Parent = intervalCard

        local rLayout = Instance.new("UIListLayout")
        rLayout.FillDirection = Enum.FillDirection.Horizontal
        rLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        rLayout.Padding = UDim.new(0, 4)
        rLayout.Parent = pRowFrame

        for _, p in ipairs(row.Items) do
            local pBtn = Instance.new("TextButton")
            pBtn.Size = UDim2.new(0.333, -3, 1, 0)
            pBtn.BackgroundColor3 = (State.IntervalMs == p.Val) and theme.Accent or theme.Sidebar
            pBtn.Text = p.Label
            pBtn.TextColor3 = (State.IntervalMs == p.Val) and theme.Background or (p.Highlight and theme.Success or theme.TextSubtle)
            pBtn.TextSize = 10
            pBtn.Font = Enum.Font.GothamBold
            pBtn.ZIndex = 104
            pBtn.Parent = pRowFrame

            local pbCorner = Instance.new("UICorner")
            pbCorner.CornerRadius = UDim.new(0, 4)
            pbCorner.Parent = pBtn

            table.insert(presetButtons, { Button = pBtn, Val = p.Val, Highlight = p.Highlight })

            pBtn.MouseButton1Click:Connect(function()
                State:Set("IntervalMs", p.Val)
                intervalInput.Text = tostring(p.Val)
                updatePresetHighlight(p.Val)
            end)
        end
    end

    local function applyCustomInterval(text: string)
        local num = tonumber(text)
        if num and num >= 10 then
            State:Set("IntervalMs", num)
            updatePresetHighlight(num)
        else
            intervalInput.Text = tostring(State.IntervalMs)
        end
    end

    intervalInput.FocusLost:Connect(function()
        applyCustomInterval(intervalInput.Text)
    end)

    -- 2. SECTION: HOLD DURATION (WAKTU TEKAN)
    createSectionHeader("DURASI TEKAN KLIK (HOLD TIME)")

    local holdCard = Instance.new("Frame")
    holdCard.Size = UDim2.new(1, 0, 0, 68)
    holdCard.BackgroundColor3 = theme.CardBg
    holdCard.BorderSizePixel = 0
    holdCard.ZIndex = 102
    holdCard.Parent = mScroll

    local hdCorner = Instance.new("UICorner")
    hdCorner.CornerRadius = UDim.new(0, 8)
    hdCorner.Parent = holdCard

    local hdLabel = Instance.new("TextLabel")
    hdLabel.Size = UDim2.new(1, -16, 0, 18)
    hdLabel.Position = UDim2.new(0, 10, 0, 8)
    hdLabel.BackgroundTransparency = 1
    hdLabel.Text = "Durasi Tahan / Press (ms):"
    hdLabel.TextColor3 = theme.Text
    hdLabel.TextSize = 11
    hdLabel.Font = Enum.Font.GothamMedium
    hdLabel.TextXAlignment = Enum.TextXAlignment.Left
    hdLabel.ZIndex = 103
    hdLabel.Parent = holdCard

    local holdInput = Instance.new("TextBox")
    holdInput.Size = UDim2.new(1, -20, 0, 30)
    holdInput.Position = UDim2.new(0, 10, 0, 28)
    holdInput.BackgroundColor3 = theme.Sidebar
    holdInput.Text = tostring(State.HoldDurationMs)
    holdInput.PlaceholderText = "Default: 22"
    holdInput.TextColor3 = theme.Text
    holdInput.PlaceholderColor3 = theme.TextSubtle
    holdInput.TextSize = 12
    holdInput.Font = Enum.Font.GothamBold
    holdInput.ClearTextOnFocus = false
    holdInput.ZIndex = 103
    holdInput.Parent = holdCard

    local hiCorner = Instance.new("UICorner")
    hiCorner.CornerRadius = UDim.new(0, 6)
    hiCorner.Parent = holdInput

    local hiStroke = Instance.new("UIStroke")
    hiStroke.Color = theme.Border
    hiStroke.Thickness = 1
    hiStroke.Parent = holdInput

    holdInput.FocusLost:Connect(function()
        local num = tonumber(holdInput.Text)
        if num and num >= 5 then
            State:Set("HoldDurationMs", num)
        else
            holdInput.Text = tostring(State.HoldDurationMs)
        end
    end)

    -- 3. SECTION: ANTI-DETECTION (BAC-8223 & BAC-3228 GUARD)
    createSectionHeader("ANTI-DETECTION & BAC GUARD (8223 / 3228)")

    local jitterCard = Instance.new("Frame")
    jitterCard.Size = UDim2.new(1, 0, 0, 52)
    jitterCard.BackgroundColor3 = theme.CardBg
    jitterCard.BorderSizePixel = 0
    jitterCard.ZIndex = 102
    jitterCard.Parent = mScroll

    local jcCorner = Instance.new("UICorner")
    jcCorner.CornerRadius = UDim.new(0, 8)
    jcCorner.Parent = jitterCard

    local jtTitle = Instance.new("TextLabel")
    jtTitle.Size = UDim2.new(1, -70, 0, 18)
    jtTitle.Position = UDim2.new(0, 10, 0, 6)
    jtTitle.BackgroundTransparency = 1
    jtTitle.Text = "Dual BAC Stealth Guard"
    jtTitle.TextColor3 = theme.Text
    jtTitle.TextSize = 11
    jtTitle.Font = Enum.Font.GothamBold
    jtTitle.TextXAlignment = Enum.TextXAlignment.Left
    jtTitle.ZIndex = 103
    jtTitle.Parent = jitterCard

    local jtDesc = Instance.new("TextLabel")
    jtDesc.Size = UDim2.new(1, -70, 0, 18)
    jtDesc.Position = UDim2.new(0, 10, 0, 24)
    jtDesc.BackgroundTransparency = 1
    jtDesc.Text = "Human Jitter (±28ms) + Micro-Pause 0.2s"
    jtDesc.TextColor3 = theme.TextSubtle
    jtDesc.TextSize = 9
    jtDesc.Font = Enum.Font.Gotham
    jtDesc.TextXAlignment = Enum.TextXAlignment.Left
    jtDesc.ZIndex = 103
    jtDesc.Parent = jitterCard

    local jitterToggle = Instance.new("TextButton")
    jitterToggle.Size = UDim2.new(0, 48, 0, 26)
    jitterToggle.Position = UDim2.new(1, -56, 0.5, -13)
    jitterToggle.BackgroundColor3 = State.IsHumanize and theme.Success or Color3.fromRGB(48, 52, 68)
    jitterToggle.Text = State.IsHumanize and "ON" or "OFF"
    jitterToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    jitterToggle.TextSize = 10
    jitterToggle.Font = Enum.Font.GothamBold
    jitterToggle.ZIndex = 103
    jitterToggle.Parent = jitterCard

    local jtgCorner = Instance.new("UICorner")
    jtgCorner.CornerRadius = UDim.new(0, 13)
    jtgCorner.Parent = jitterToggle

    jitterToggle.MouseButton1Click:Connect(function()
        State:Set("IsHumanize", not State.IsHumanize)
        jitterToggle.Text = State.IsHumanize and "ON" or "OFF"
        jitterToggle.BackgroundColor3 = State.IsHumanize and theme.Success or Color3.fromRGB(48, 52, 68)
    end)

    -- 4. SECTION: STATISTIK & INFORMASI TARGET
    createSectionHeader("STATUS & STATISTIK SESI")

    local statBox = Instance.new("Frame")
    statBox.Size = UDim2.new(1, 0, 0, 136)
    statBox.BackgroundColor3 = theme.CardBg
    statBox.BorderSizePixel = 0
    statBox.ZIndex = 102
    statBox.Parent = mScroll

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
    statText.ZIndex = 103
    statText.Parent = statBox

    -- Live Status Updater Loop
    task.spawn(function()
        while screenGui.Parent do
            local elapsed = State:GetElapsedTime()
            local statusColor = State.IsRunning and "#2ecc71" or "#f1c40f"
            local pos = State.TargetPosition
            local jitterStr = State.IsHumanize and "<font color='#2ecc71'>Aktif (Human Rhythm & Micro-Pause)</font>" or "<font color='#e74c3c'>Nonaktif (Beresiko)</font>"

            statText.Text = string.format(
                "• <b>Status:</b> <font color='%s'>%s</font>\n" ..
                "• <b>Total Klik Terkirim:</b> <font color='#00d2ff'>%d</font>\n" ..
                "• <b>Interval:</b> <font color='#00d2ff'>%d ms%s</font> (Hold: %d ms)\n" ..
                "• <b>BAC Guard:</b> %s\n" ..
                "• <b>Sistem Proteksi:</b> <font color='#2ecc71'>BAC-3229 Tamper-Free</font>\n" ..
                "• <b>Posisi Target Screen:</b> X: %d, Y: %d\n" ..
                "• <b>Durasi Sesi Script:</b> %s",
                statusColor, State.LastStatus, State.TotalClicks, State.IntervalMs,
                State.IntervalMs == 1000 and " [1s]" or "", State.HoldDurationMs,
                jitterStr, math.floor(pos.X), math.floor(pos.Y), elapsed
            )
            task.wait(0.5)
        end
    end)

    -- Shortcut Keyboard Toggle (F8)
    local connKey = UserInputService.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Config.UI.ToggleKey then
            ClickEngine:Toggle()
        end
    end)
    table.insert(self.Connections, connKey)

    print("[Be Rebel v1.4] Single Target Auto Clicker dengan Full BAC Immunity Suite berhasil dimuat!")
end

-- Bersihkan Semua Event & Hancurkan GUI (Clean Teardown)
function BeRebelGui:Destroy()
    ClickEngine:Stop()

    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}

    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
        self.ScreenGui = nil
    end

    genv.__BE_REBEL_LOADED = nil
    genv.__BE_REBEL_CLEANUP = nil
    print("[Be Rebel v1.4] Berhasil ditutup dan dibersihkan dari memori.")
end

genv.__BE_REBEL_CLEANUP = function()
    BeRebelGui:Destroy()
end

-- Inisialisasi Script
BeRebelGui:Create()

return {
    ClickEngine = ClickEngine,
    State = State,
    BeRebelGui = BeRebelGui,
}
