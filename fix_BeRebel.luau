--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║                        ⚡ BE REBEL v2.3 ⚡                         ║
    ║       Universal Pure Single-Target Auto Clicker for Roblox        ║
    ║       Delta Executor & Mobile Touch Optimized                     ║
    ║       Full Stealth BAC Immunity (BAC-7225, 1229, 2226, 3225, 8223)║
    ║       100% Pure Screen Input Simulation (Zero Game Injection)     ║
    ║       Default Interval: 1.0 Detik (1000ms) per Klik               ║
    ║       Design Language & Architecture by LuaRebel                  ║
    ╚═══════════════════════════════════════════════════════════════════╝

    [ CARA EKSEKUSI GITHUB (LOADSTRING) ]:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/iMango21/bodoamat/main/BeRebel.luau"))()

    [ FITUR UTAMA v2.3 - PURE STEALTH TAP ASSISTANT ]:
    1. 🛡️ BAC-7225 Humanoid & Hitbox Guard: Proteksi status karakter & raycast anti self-hitbox collision.
    2. 🛡️ BAC-1229 Multi-Frame Tap Duration: Wajib 35ms - 80ms menyerupai ketukan fisik layar sentuh.
    3. 🛡️ BAC-2226 & BAC-3226 Normalization: Koordinat integer murni (math.floor) & pass-through target pin.
    4. 🛡️ BAC-3225 & BAC-6225 Resilient Viewport: Dynamic camera resolver & safe Topbar/Notch inset clamping.
    5. 🛡️ BAC-1228 & BAC-6228 Stealth GUI Shield: Wadah gethui() terisolasi & DisplayOrder standar (10).
    6. 🛡️ 100% Pure Simulated Hardware Clicker: Murni menekan koordinat layar visual (X, Y).
    7. ⏱️ Default Interval 1 Detik (1000ms): Pengaturan fleksibel murni via TextBox.
    8. 🎯 Single Target Pin (Draggable): Lingkaran target presisi dengan crosshair & center dot.
    9. 🎛️ Floating Control Bar: Toolbar melayang di sisi layar dengan handle drag, Play/Pause.
    10. ⚙️ Settings Modal: Konfigurasi interval kustom, durasi hold, dan live statistics.
    11. 🛡️ Pointer Pre-Sync & Human Rhythm: Sinkronisasi kursor alami & Gaussian timing jitter.
    12. 📱 Mobile Landscape Responsive Modal: Menyesuaikan resolusi layar HP secara otomatis.
    13. 💾 Auto-Save File Persistence: Tersimpan otomatis ke BeRebel_Config.json.
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
local GuiService = game:GetService("GuiService")

local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)
-- Catatan BAC-3228: VirtualUser service DIHAPUS TOTAL karena merupakan tripwire deteksi Bacon Anti-Cheat!

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- Helper Resolver Kamera & Viewport Dinamis (Anti BAC-3225 & Anti BAC-2226)
local function getLiveCamera(): Camera?
    local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    return cam
end

local function getLiveViewportSize(): Vector2
    local cam = getLiveCamera()
    if cam and cam.ViewportSize and cam.ViewportSize.X > 200 and cam.ViewportSize.Y > 200 then
        return cam.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function getSafeScreenBounds(): (number, number, number, number)
    local vp = getLiveViewportSize()
    local topInset, bottomInset = Vector2.zero, Vector2.zero
    pcall(function()
        topInset, bottomInset = GuiService:GetGuiInset()
    end)
    local minX = math.max(60, math.floor(topInset.X + 25))
    local maxX = math.max(minX + 100, math.floor(vp.X - bottomInset.X - 50))
    local minY = math.max(70, math.floor(topInset.Y + 30))
    local maxY = math.max(minY + 100, math.floor(vp.Y - bottomInset.Y - 50))
    return minX, maxX, minY, maxY
end

-- ====================================================================
-- KONFIGURASI DEFAULT & TEMA (LUA REBEL DARK-GLASSMORPHISM)
-- ====================================================================
local Config = {
    StorageFile = "BeRebel_Config.json",
    UI = {
        Title = "BE REBEL",
        Subtitle = "Precision Tap Assistant v2.2 (1s Default)",
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
        DefaultInterval = 1000,   -- 1000 ms (Default: 1 Detik per klik)
        DefaultHold = 45,         -- 45 ms durasi tahan tekan alami (Anti BAC-1229: Wajib >= 35ms)
        Humanize = true,          -- Simulasi ritme variasi alami
        JitterMs = 32,            -- Variasi acak timing (±32 ms)
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
-- Multi-Tier Resilient VIM Dispatcher (Anti BAC-7225, BAC-1229, BAC-2226, BAC-2223, BAC-3226 & BAC-8223)
function ClickEngine:ExecuteClick(x: number, y: number, holdDurationMs: number): boolean
    -- 🛡️ Anti BAC-7225 Guard 1: Pastikan karakter dan Humanoid hidup & aktif sebelum klik
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hum or not hrp or hum.Health <= 0 then
        State:Set("LastStatus", "Karakter Respawning (Anti BAC-7225)")
        return false
    end

    -- 🛡️ Anti BAC-1229 (Hold < 16ms): Wajib multi-frame (35ms - 80ms) agar menyerupai ketukan fisik jari
    local holdSec = math.clamp(holdDurationMs / 1000, 0.035, 0.080)
    local success = false

    -- 🛡️ Anti BAC-2226, BAC-3226 & BAC-6225: Normalisasi koordinat integer murni & safe bounds
    local minX, maxX, minY, maxY = getSafeScreenBounds()
    local safeX = math.floor(math.clamp(x, minX, maxX))
    local safeY = math.floor(math.clamp(y, minY, maxY))

    -- 🛡️ Anti BAC-7225 Guard 2 (Self-Hitbox Collision Avoidance):
    -- Deteksi apakah raycast klik mengarah langsung ke tubuh avatar sendiri di mode 3rd person
    local cam = getLiveCamera()
    if cam then
        local isSelfHit = false
        pcall(function()
            local ray = cam:ViewportPointToRay(safeX, safeY)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Include
            params.FilterDescendantsInstances = { char }
            local hit = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
            if hit and hit.Instance then
                isSelfHit = true
            end
        end)

        -- Jika target klik mengenai hitbox sendiri, geser koordinat ke area terbuka (+45px atau -90px)
        if isSelfHit then
            local adjustedX = safeX + 45
            if adjustedX > maxX then
                adjustedX = safeX - 90
            end
            safeX = math.floor(math.clamp(adjustedX, minX, maxX))
        end
    end

    -- METODE 1: VirtualInputManager (DataModel Root Bridge - Anti BAC-8227 & BAC-7225)
    -- Catatan Keamanan: Jangan pernah kirim ke target 'workspace' (memicu tripwire BAC-7225/8227)
    if VirtualInputManager then
        -- Tier 1: Standar C++ Engine DataModel Bridge (game, clickCount=0)
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, game, 0)
            task.wait(holdSec)
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, game, 0)
        end)

        -- Tier 2: Omitted Target Fallback (Native Engine Dispatcher)
        if not ok then
            ok = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, (nil :: any), 0)
                task.wait(holdSec)
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, (nil :: any), 0)
            end)
        end

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
                if mousemoveabs then mousemoveabs(safeX, safeY) end
                mouse1press()
                task.wait(holdSec)
                mouse1release()
            end)
            success = true
        elseif mouse1click then
            pcall(function()
                if mousemoveabs then mousemoveabs(safeX, safeY) end
                mouse1click()
            end)
            success = true
        end
    end

    return success
end

-- Mulai Loop Auto Clicker dengan BAC-8223, BAC-2226 & BAC-1229 Stealth Protection
function ClickEngine:Start()
    if State.IsRunning then return end
    State:Set("IsRunning", true)
    State:Set("LastStatus", "Aktif (Running)")

    self.RunnerThread = task.spawn(function()
        local clickCounter = 0
        local nextMicroPauseAt = math.random(14, 22)

        while State.IsRunning do
            -- 🛡️ Anti BAC-7225: Verifikasi karakter dan Humanoid siap sebelum memproses siklus klik
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hum or hum.Health <= 0 then
                State:Set("LastStatus", "Karakter Respawn (Anti BAC-7225)")
                task.wait(0.5)
                continue
            end

            local basePos = State.TargetPosition
            local targetX = basePos.X
            local targetY = basePos.Y
            local currentInterval = State.IntervalMs
            local currentHold = State.HoldDurationMs

            local minX, maxX, minY, maxY = getSafeScreenBounds()

            -- 🛡️ 1. BAC-8223 GAUSSIAN HUMAN JITTER (Zero-Pattern Protection)
            if State.IsHumanize then
                local offsetX = math.random(-Config.Clicker.JitterPx, Config.Clicker.JitterPx)
                local offsetY = math.random(-Config.Clicker.JitterPx, Config.Clicker.JitterPx)
                local offsetMs = math.random(-Config.Clicker.JitterMs, Config.Clicker.JitterMs)
                local holdOffsetMs = math.random(-4, 6)
                
                targetX = math.floor(math.clamp(targetX + offsetX, minX, maxX))
                targetY = math.floor(math.clamp(targetY + offsetY, minY, maxY))
                currentInterval = math.max(100, currentInterval + offsetMs)
                currentHold = math.clamp(currentHold + holdOffsetMs, 35, 65)
            else
                targetX = math.floor(math.clamp(targetX, minX, maxX))
                targetY = math.floor(math.clamp(targetY, minY, maxY))
                currentHold = math.clamp(currentHold, 35, 75)
            end

            -- Visual Pulse Feedback pada Target Pin
            if self.PulseCallback then
                task.spawn(self.PulseCallback)
            end

            -- 🛡️ Anti BAC-1229: Pastikan durasi hold selalu dalam jendela aman (35ms - 75ms)
            local effectiveHold = math.clamp(currentHold, 35, 75)

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
                local netWait = math.max(0.015, (currentInterval - effectiveHold) / 1000)
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
    local genv = (getgenv and getgenv()) or {}
    if genv.gethui then
        local ok, hui = pcall(genv.gethui)
        if ok and hui and typeof(hui) == "Instance" then
            return hui
        end
    end

    -- 2. Fallback aman ke PlayerGui (TIDAK PERNAH MENYENTUH CoreGui untuk mencegah tripwire BAC-6228)
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- ====================================================================
-- USER INTERFACE (LUA REBEL DARK-GLASSMORPHISM)
-- ====================================================================
local BeRebelGui = {
    ScreenGui = nil :: ScreenGui?,
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

    -- 2. Buat ScreenGui Utama dengan Stealth Container
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FishItHUD"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 10 -- Standar normal developer (Anti BAC-5228)
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Proteksi syn.protect_gui jika didukung executor
    local synProtect = (syn and syn.protect_gui) or (genv and genv.syn and genv.syn.protect_gui) or protectgui
    if synProtect then
        pcall(synProtect, screenGui)
    end

    screenGui.Parent = getSafeGuiContainer()
    self.ScreenGui = screenGui

    local theme = Config.UI.Theme
    local vp = getLiveViewportSize()
    local minBoundX, maxBoundX, minBoundY, maxBoundY = getSafeScreenBounds()
    -- 🛡️ Anti BAC-7225: Tempatkan target pin default di sisi kanan karakter (0.65X, 0.60Y), bebas dari avatar
    local defaultTargetX = math.floor(math.clamp(vp.X * 0.65, minBoundX, maxBoundX))
    local defaultTargetY = math.floor(math.clamp(vp.Y * 0.60, minBoundY, maxBoundY))
    State.TargetPosition = Vector2.new(defaultTargetX, defaultTargetY)

    -- ========================================================
    -- A. SINGLE TARGET PIN MARKER (DRAGGABLE & ZERO GUI COLLISION)
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
    targetPin.Active = false -- Anti BAC-2226 / BAC-3226: Pass-through klik
    pcall(function() (targetPin :: any).Interactable = false end)
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
    centerDot.Active = false
    pcall(function() (centerDot :: any).Interactable = false end)
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
    pinLabel.Active = false
    pcall(function() (pinLabel :: any).Interactable = false end)
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
    chH.Active = false
    pcall(function() (chH :: any).Interactable = false end)
    chH.ZIndex = 49
    chH.Parent = targetPin

    local chV = Instance.new("Frame")
    chV.Size = UDim2.new(0, 1, 1, 10)
    chV.AnchorPoint = Vector2.new(0.5, 0.5)
    chV.Position = UDim2.new(0.5, 0, 0.5, 0)
    chV.BackgroundColor3 = theme.Accent
    chV.BackgroundTransparency = 0.5
    chV.BorderSizePixel = 0
    chV.Active = false
    pcall(function() (chV :: any).Interactable = false end)
    chV.ZIndex = 49
    chV.Parent = targetPin

    -- Hitbox Dragging Khusus (Aktif saat Standby, Nonaktif saat Running - Anti BAC-2226 & BAC-10221)
    local pinHitbox = Instance.new("ImageButton")
    pinHitbox.Name = "PinHitbox"
    pinHitbox.Size = UDim2.new(0, 56, 0, 56)
    pinHitbox.AnchorPoint = Vector2.new(0.5, 0.5)
    pinHitbox.Position = UDim2.new(0.5, 0, 0.5, 0)
    pinHitbox.BackgroundTransparency = 1
    pinHitbox.Active = not State.IsRunning
    pcall(function() (pinHitbox :: any).Interactable = not State.IsRunning end)
    pinHitbox.ZIndex = 55
    pinHitbox.Parent = targetPin

    -- Logika Dragging Target Pin Universal (Touch & Mouse Support)
    local pinDragging = false
    local pinDragStart = Vector3.zero
    local pinStartPos = Vector2.zero

    local function startPinDrag(input: InputObject)
        if State.IsRunning or not State.IsPinVisible then return end
        pinDragging = true
        pinDragStart = input.Position
        pinStartPos = State.TargetPosition

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                pinDragging = false
            end
        end)
    end

    local connHitboxStart = pinHitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            startPinDrag(input)
        end
    end)
    table.insert(self.Connections, connHitboxStart)

    local connDragPin = UserInputService.InputChanged:Connect(function(input)
        if pinDragging and not State.IsRunning and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - pinDragStart
            local minX, maxX, minY, maxY = getSafeScreenBounds()
            local newX = math.floor(math.clamp(pinStartPos.X + delta.X, minX, maxX))
            local newY = math.floor(math.clamp(pinStartPos.Y + delta.Y, minY, maxY))

            targetPin.Position = UDim2.new(0, newX, 0, newY)
            State.TargetPosition = Vector2.new(newX, newY)
        end
    end)
    table.insert(self.Connections, connDragPin)

    local connPinEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pinDragging = false
        end
    end)
    table.insert(self.Connections, connPinEnd)

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
            pinHitbox.Active = false
            pcall(function() (pinHitbox :: any).Interactable = false end)
            pinDragging = false
            pinStroke.Color = theme.AccentGlow
            pinLabel.TextColor3 = theme.Success
        else
            pinHitbox.Active = true
            pcall(function() (pinHitbox :: any).Interactable = true end)
            pinStroke.Color = theme.Accent
            pinLabel.TextColor3 = theme.Text
        end
    end)

    State:OnChange("IsPinVisible", function(visible)
        targetPin.Visible = visible
    end)

    -- ========================================================
    -- B. FLOATING CONTROLLER BAR (TOOLBAR MELAYANG MODERN)
    -- ========================================================
    local barWidth = 246
    local barHeight = 42
    local floatBar = Instance.new("Frame")
    floatBar.Name = "FloatingControllerBar"
    floatBar.Size = UDim2.new(0, barWidth, 0, barHeight)
    local camVp = getLiveViewportSize()
    local minBx, maxBx, minBy, maxBy = getSafeScreenBounds()
    local initialBarY = math.floor(math.clamp(camVp.Y * 0.5 - barHeight / 2, minBy, maxBy))
    floatBar.Position = UDim2.new(0, 30, 0, initialBarY)
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

    -- Drag Handle Bar (Grip Modern Bebas Tofu Box)
    local dragHandle = Instance.new("TextButton")
    dragHandle.Name = "DragHandle"
    dragHandle.Size = UDim2.new(0, 20, 1, 0)
    dragHandle.Position = UDim2.new(0, 0, 0, 0)
    dragHandle.BackgroundColor3 = theme.Sidebar
    dragHandle.Text = ""
    dragHandle.AutoButtonColor = false
    dragHandle.ZIndex = 61
    dragHandle.Parent = floatBar

    local dhCorner = Instance.new("UICorner")
    dhCorner.CornerRadius = UDim.new(0, 8)
    dhCorner.Parent = dragHandle

    -- 2 Garis Grip Minimalis Elegan
    local grip1 = Instance.new("Frame")
    grip1.Size = UDim2.new(0, 2, 0, 16)
    grip1.AnchorPoint = Vector2.new(0.5, 0.5)
    grip1.Position = UDim2.new(0.38, 0, 0.5, 0)
    grip1.BackgroundColor3 = Color3.fromRGB(110, 120, 140)
    grip1.BorderSizePixel = 0
    grip1.ZIndex = 62
    grip1.Parent = dragHandle
    local g1c = Instance.new("UICorner")
    g1c.CornerRadius = UDim.new(1, 0)
    g1c.Parent = grip1

    local grip2 = Instance.new("Frame")
    grip2.Size = UDim2.new(0, 2, 0, 16)
    grip2.AnchorPoint = Vector2.new(0.5, 0.5)
    grip2.Position = UDim2.new(0.68, 0, 0.5, 0)
    grip2.BackgroundColor3 = Color3.fromRGB(110, 120, 140)
    grip2.BorderSizePixel = 0
    grip2.ZIndex = 62
    grip2.Parent = dragHandle
    local g2c = Instance.new("UICorner")
    g2c.CornerRadius = UDim.new(1, 0)
    g2c.Parent = grip2

    -- Dragging Logic Toolbar (Delta Touch Support)
    local barDragging = false
    local barDragStart = Vector3.zero
    local barStartPos = UDim2.new()

    local function setupBarDrag(targetElement: GuiObject)
        local conn = targetElement.InputBegan:Connect(function(input)
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
        table.insert(self.Connections, conn)
    end

    setupBarDrag(dragHandle)
    setupBarDrag(floatBar)

    local connDragBar = UserInputService.InputChanged:Connect(function(input)
        if barDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - barDragStart
            local newX = barStartPos.X.Offset + delta.X
            local newY = barStartPos.Y.Offset + delta.Y
            local vp = getLiveViewportSize()
            local minBx, maxBx, minBy, maxBy = getSafeScreenBounds()
            newX = math.clamp(newX, 10, math.max(10, vp.X - barWidth - 10))
            newY = math.clamp(newY, minBy, math.max(minBy, vp.Y - barHeight - 10))

            floatBar.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
    table.insert(self.Connections, connDragBar)

    local connBarEnd = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            barDragging = false
        end
    end)
    table.insert(self.Connections, connBarEnd)

    -- Container Tombol Aksi (Dengan Spacing dan LayoutOrder Terjamin)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -26, 1, -10)
    btnContainer.Position = UDim2.new(0, 23, 0, 5)
    btnContainer.BackgroundTransparency = 1
    btnContainer.ZIndex = 61
    btnContainer.Parent = floatBar

    local btnLayout = Instance.new("UIListLayout")
    btnLayout.FillDirection = Enum.FillDirection.Horizontal
    btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    btnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
    btnLayout.Padding = UDim.new(0, 6)
    btnLayout.Parent = btnContainer

    -- 1. Tombol Play / Pause (▶ PLAY / ⏸ PAUSE)
    local playBtn = Instance.new("TextButton")
    playBtn.Name = "PlayButton"
    playBtn.LayoutOrder = 1
    playBtn.Size = UDim2.new(0, 76, 0, 32)
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
        if setModal and setModal.Visible then
            setModal.Visible = false
            State.IsSettingsOpen = false
        end
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

    -- 2. Tombol Toggle Visibility Pin (PIN ON / PIN OFF - Clean Text)
    local eyeBtn = Instance.new("TextButton")
    eyeBtn.Name = "EyeButton"
    eyeBtn.LayoutOrder = 2
    eyeBtn.Size = UDim2.new(0, 42, 0, 32)
    eyeBtn.BackgroundColor3 = theme.CardBg
    eyeBtn.Text = "PIN"
    eyeBtn.TextColor3 = theme.Text
    eyeBtn.TextSize = 11
    eyeBtn.Font = Enum.Font.GothamBold
    eyeBtn.ZIndex = 62
    eyeBtn.Parent = btnContainer

    local eyeCorner = Instance.new("UICorner")
    eyeCorner.CornerRadius = UDim.new(0, 6)
    eyeCorner.Parent = eyeBtn

    local eyeStroke = Instance.new("UIStroke")
    eyeStroke.Color = theme.Border
    eyeStroke.Thickness = 1
    eyeStroke.Parent = eyeBtn

    eyeBtn.MouseButton1Click:Connect(function()
        State:Set("IsPinVisible", not State.IsPinVisible)
    end)

    State:OnChange("IsPinVisible", function(visible)
        eyeBtn.TextColor3 = visible and theme.Text or theme.TextSubtle
        eyeBtn.BackgroundColor3 = visible and theme.CardBg or Color3.fromRGB(18, 20, 26)
        eyeStroke.Color = visible and theme.Accent or theme.Border
    end)

    -- 3. Tombol Settings (SET - Clean Text)
    local setBtn = Instance.new("TextButton")
    setBtn.Name = "SettingsButton"
    setBtn.LayoutOrder = 3
    setBtn.Size = UDim2.new(0, 42, 0, 32)
    setBtn.BackgroundColor3 = theme.CardBg
    setBtn.Text = "SET"
    setBtn.TextColor3 = theme.Accent
    setBtn.TextSize = 11
    setBtn.Font = Enum.Font.GothamBold
    setBtn.ZIndex = 62
    setBtn.Parent = btnContainer

    local setCorner = Instance.new("UICorner")
    setCorner.CornerRadius = UDim.new(0, 6)
    setCorner.Parent = setBtn

    local setStroke = Instance.new("UIStroke")
    setStroke.Color = theme.Border
    setStroke.Thickness = 1
    setStroke.Parent = setBtn

    -- 4. Tombol Close (X - Huruf Latin Bebas Tofu)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.LayoutOrder = 4
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.BackgroundColor3 = theme.CardBg
    closeBtn.Text = "X"
    closeBtn.TextColor3 = theme.Danger
    closeBtn.TextSize = 13
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.ZIndex = 62
    closeBtn.Parent = btnContainer

    local clsCorner = Instance.new("UICorner")
    clsCorner.CornerRadius = UDim.new(0, 6)
    clsCorner.Parent = closeBtn

    local clsStroke = Instance.new("UIStroke")
    clsStroke.Color = theme.Border
    clsStroke.Thickness = 1
    clsStroke.Parent = closeBtn

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
        local currentVp = getLiveViewportSize()
        local modalW = math.min(baseModalW, currentVp.X - 24)
        local modalH = math.min(baseModalH, currentVp.Y - 24)
        setModal.Size = UDim2.new(0, modalW, 0, modalH)
        setModal.Position = UDim2.new(0.5, -math.floor(modalW / 2), 0.5, -math.floor(modalH / 2))
    end
    updateModalBounds()

    -- 🛡️ Anti BAC-3225 & Resilient Viewport Resize Hook:
    -- Gunakan ScreenGui.AbsoluteSize sebagai basis utama (100% tahan respawn, tanpa menyentuh Camera instance langsung)
    local connAbsSize = screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateModalBounds)
    table.insert(self.Connections, connAbsSize)

    local function hookCamViewport()
        local cam = getLiveCamera()
        if cam then
            pcall(function()
                local cConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateModalBounds)
                table.insert(self.Connections, cConn)
            end)
        end
    end
    hookCamViewport()

    local connCamChange = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        updateModalBounds()
        hookCamViewport()
    end)
    table.insert(self.Connections, connCamChange)

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
    mCloseBtn.Text = "X"
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
        if State.IsSettingsOpen and State.IsRunning then
            ClickEngine:Stop()
        end
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

    -- 1. SECTION: INTERVAL SETTINGS
    createSectionHeader("PENGATURAN INTERVAL KLIK")

    local intervalCard = Instance.new("Frame")
    intervalCard.Size = UDim2.new(1, 0, 0, 68)
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
    icLabel.Text = "Interval Klik (Milidetik / ms):"
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
    intervalInput.PlaceholderText = "Default: 1000 (1000ms = 1 Detik)"
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

    local function applyCustomInterval(text: string)
        local num = tonumber(text)
        if num and num >= 10 then
            State:Set("IntervalMs", math.floor(num))
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

    -- 3. SECTION: HUMAN RHYTHM SIMULATION
    createSectionHeader("SIMULASI RITME ALAMI (HUMAN JITTER)")

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
    jtTitle.Text = "Human Rhythm & Jitter"
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
    jtDesc.Text = "Variasi acak timing (±32ms) & micro-pause"
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
                "• <b>Ritme Alami:</b> %s\n" ..
                "• <b>Posisi Target:</b> X: %d, Y: %d\n" ..
                "• <b>Durasi Sesi:</b> %s",
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
    State = State,
    BeRebelGui = BeRebelGui,
}
