--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║            REBEL AUTO CLICKER - MULTI-TARGET EDITION          ║
    ║        Inspired by Android Auto Clicker (Automatic Tap)       ║
    ║        Full Luau Implementation for Roblox Environments       ║
    ╚═══════════════════════════════════════════════════════════════╝

    Fitur Utama:
    1. Floating Control Toolbar:
       - [ ▶ / ⏸ ] Play / Pause: Memulai dan menghentikan loop klik.
       - [  +  ] Tambah Titik Target: Menambahkan pin target baru (1, 2, 3, dst).
       - [  -  ] Hapus Titik: Menghapus pin target terakhir.
       - [  👁  ] Sembunyikan / Tampilkan Pin: Menyembunyikan pin visual saat berjalan.
       - [  ⚙  ] Pengaturan (Settings): Mengatur delay global/individual & anti-bot jitter.
       - [  ✕  ] Tutup (Close): Menutup script & membersihkan memori secara aman.
       - Toolbar bisa digeser (draggable) ke seluruh area layar (PC & Mobile Touch).

    2. Numbered Target Pins (Pin Target Bernomor):
       - Lingkaran target bernomor (1, 2, 3...) yang dapat di-drag bebas ke tombol game.
       - Indikator visual pulse (animasi berdenyut) saat target sedang diklik.
       - Klik pada pin target untuk mengatur delay/interval khusus titik tersebut.

    3. Resilient Virtual Input Dispatcher:
       - Simulasi klik multi-tier (game -> workspace -> fallback) via VirtualInputManager.
       - Clamping koordinat aman agar tidak keluar layar (Safe Screen Bounds).
       - Anti-Detection Humanize Jitter: Variasi acak timing (±ms) dan posisi (±px) agar aman dari anti-cheat.
       - Multi-Target Sequencing: Berurutan (Target 1 -> Delay 1 -> Target 2 -> Delay 2 ...).

    4. Clean Teardown & Safe UI Mounting:
       - Kompatibel dengan gethui(), CoreGui, dan PlayerGui.
       - Proteksi instance duplikat & pembersihan event listener lengkap saat ditutup.
]]

-- Tunggu game selesai dimuat jika belum
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Proteksi Instance Duplikat
local genv = (getgenv and getgenv()) or {}
if genv.__REBEL_AUTOCLICK_LOADED then
    pcall(function()
        if genv.__REBEL_AUTOCLICK_CLEANUP then
            genv.__REBEL_AUTOCLICK_CLEANUP()
        end
    end)
end
genv.__REBEL_AUTOCLICK_LOADED = true

-- ============================================================
-- 1. SERVICES & DEPENDENCIES
-- ============================================================
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local VirtualInputManager: any = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ============================================================
-- 2. HELPER VIEWPORT & SCREEN BOUNDS
-- ============================================================
local function getLiveViewportSize(): Vector2
    local cam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
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
    local minX = math.max(30, math.floor(topInset.X + 15))
    local maxX = math.max(minX + 100, math.floor(vp.X - bottomInset.X - 30))
    local minY = math.max(40, math.floor(topInset.Y + 20))
    local maxY = math.max(minY + 100, math.floor(vp.Y - bottomInset.Y - 30))
    return minX, maxX, minY, maxY
end

-- ============================================================
-- 3. TEMA WARNA & DESAIN UI
-- ============================================================
local Theme = {
    BarBg       = Color3.fromRGB(24, 26, 36),
    BarBorder   = Color3.fromRGB(48, 54, 74),
    ButtonBg    = Color3.fromRGB(36, 40, 56),
    ButtonHover = Color3.fromRGB(48, 54, 76),
    Accent      = Color3.fromRGB(0, 180, 255),
    AccentGlow  = Color3.fromRGB(0, 220, 255),
    Play        = Color3.fromRGB(46, 204, 113),
    Pause       = Color3.fromRGB(243, 156, 18),
    Remove      = Color3.fromRGB(231, 76, 60),
    Text        = Color3.fromRGB(245, 247, 250),
    TextSubtle  = Color3.fromRGB(150, 158, 175),
    TargetPin   = Color3.fromRGB(0, 180, 255),
    TargetInner = Color3.fromRGB(20, 24, 36),
    TargetPulse = Color3.fromRGB(46, 204, 113),
    CardBg      = Color3.fromRGB(28, 32, 46),
}

-- ============================================================
-- 4. TIPE DATA & MODEL STATE
-- ============================================================
export type TargetPoint = {
    id: number,
    pinFrame: Frame,
    pulseRing: Frame,
    numberLabel: TextLabel,
    delayMs: number,
    position: Vector2,
}

local State = {
    IsRunning = false,
    DefaultDelayMs = 250,      -- 250ms per target
    DefaultHoldMs = 45,        -- 45ms tap duration
    IsHumanize = true,         -- Randomized anti-bot timing
    JitterMs = 20,             -- ± ms
    JitterPx = 4,              -- ± px
    MaxCycles = 0,             -- 0 = Tak terbatas (Infinite)
    CurrentCycle = 0,
    ActiveTargetIndex = 1,
    PinsVisible = true,
    SettingsOpen = false,
    TotalClicks = 0,
    StartTime = os.time(),

    Targets = {} :: { TargetPoint },
    Connections = {} :: { RBXScriptConnection },
}

-- ============================================================
-- 5. ENGINE SIMULASI INPUT (VIRTUAL INPUT DISPATCHER)
-- ============================================================
local ClickEngine = {
    RunnerThread = nil :: thread?,
}

function ClickEngine:ExecuteTap(x: number, y: number, holdDurationMs: number): boolean
    local holdSec = math.clamp(holdDurationMs / 1000, 0.030, 0.080)
    local minX, maxX, minY, maxY = getSafeScreenBounds()
    local safeX = math.floor(math.clamp(x, minX, maxX))
    local safeY = math.floor(math.clamp(y, minY, maxY))
    local executed = false

    if VirtualInputManager then
        -- Tier 1: Standar C++ Engine DataModel Bridge
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, game, 0)
            task.wait(holdSec)
            VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, game, 0)
        end)

        -- Tier 2: Workspace Target Fallback
        if not ok then
            ok = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, workspace, 0)
                task.wait(holdSec)
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, workspace, 0)
            end)
        end

        -- Tier 3: Nil Target Fallback
        if not ok then
            ok = pcall(function()
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, true, (nil :: any), 0)
                task.wait(holdSec)
                VirtualInputManager:SendMouseButtonEvent(safeX, safeY, 0, false, (nil :: any), 0)
            end)
        end

        if ok then executed = true end
    end

    return executed
end

function ClickEngine:Start()
    if State.IsRunning then return end
    if #State.Targets == 0 then
        warn("[Rebel AutoClicker] Tidak ada titik target! Tambahkan target terlebih dahulu dengan tombol [+].")
        return
    end

    State.IsRunning = true
    State.CurrentCycle = 0
    State.ActiveTargetIndex = 1

    self.RunnerThread = task.spawn(function()
        while State.IsRunning do
            if #State.Targets == 0 then
                task.wait(0.5)
                continue
            end

            -- Loop berurutan melewati seluruh titik target (1 -> 2 -> 3 ...)
            for index, target in ipairs(State.Targets) do
                if not State.IsRunning then break end
                State.ActiveTargetIndex = index

                -- Hitung koordinat pusat pin target secara presisi
                local absPos = target.pinFrame.AbsolutePosition
                local absSize = target.pinFrame.AbsoluteSize
                local targetX = absPos.X + (absSize.X / 2)
                local targetY = absPos.Y + (absSize.Y / 2)

                local currentDelay = target.delayMs
                local currentHold = State.DefaultHoldMs

                -- Terapkan Anti-Detection Humanize Jitter jika aktif
                if State.IsHumanize then
                    local offsetPxX = math.random(-State.JitterPx, State.JitterPx)
                    local offsetPxY = math.random(-State.JitterPx, State.JitterPx)
                    local offsetMs = math.random(-State.JitterMs, State.JitterMs)
                    local holdOffset = math.random(-4, 6)

                    targetX += offsetPxX
                    targetY += offsetPxY
                    currentDelay = math.max(60, currentDelay + offsetMs)
                    currentHold = math.clamp(currentHold + holdOffset, 30, 80)
                end

                -- Animasi Visual Pulse pada Target Pin
                task.spawn(function()
                    if target.pulseRing and target.pulseRing.Parent then
                        target.pulseRing.Visible = true
                        target.pulseRing.Size = UDim2.new(1, 0, 1, 0)
                        target.pulseRing.BackgroundTransparency = 0.2
                        
                        local tween = TweenService:Create(
                            target.pulseRing,
                            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                            {
                                Size = UDim2.new(2.2, 0, 2.2, 0),
                                BackgroundTransparency = 1,
                            }
                        )
                        tween:Play()
                        tween.Completed:Connect(function()
                            if target.pulseRing then
                                target.pulseRing.Visible = false
                                target.pulseRing.Size = UDim2.new(1, 0, 1, 0)
                            end
                        end)
                    end
                end)

                -- Eksekusi Klik
                ClickEngine:ExecuteTap(targetX, targetY, currentHold)
                State.TotalClicks += 1

                -- Jeda waktu sebelum berpindah ke target selanjutnya
                task.wait(currentDelay / 1000)
            end

            State.CurrentCycle += 1
            if State.MaxCycles > 0 and State.CurrentCycle >= State.MaxCycles then
                ClickEngine:Stop()
                break
            end
        end
    end)
end

function ClickEngine:Stop()
    State.IsRunning = false
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

-- ============================================================
-- 6. USER INTERFACE BUILDER (SCREEN GUI & CONTROLLER)
-- ============================================================
local AppGui = {
    ScreenGui = nil :: ScreenGui?,
    Toolbar = nil :: Frame?,
    PlayBtn = nil :: TextButton?,
    PlayIcon = nil :: TextLabel?,
    PlayLabel = nil :: TextLabel?,
    SettingsModal = nil :: Frame?,
    TargetContainer = nil :: Frame?,
}

-- Safe ScreenGui Mounting (Anti CoreGui Detections)
function AppGui:GetMountContainer(): Instance
    local success, container = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        local cg = game:GetService("CoreGui")
        local isRobloxScript = pcall(function() return cg.Name end)
        if isRobloxScript then return cg end
        return LocalPlayer:WaitForChild("PlayerGui")
    end)
    if success and container then
        return container
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Helper Dragging Universal (Mouse & Touch Friendly)
local function applyUniversalDrag(frame: Frame, dragHandle: GuiObject?)
    local handle = dragHandle or frame
    local dragging = false
    local dragStart: Vector3 = Vector3.zero
    local startPos: UDim2 = UDim2.zero

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            local endConn: RBXScriptConnection? = nil
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if endConn then endConn:Disconnect() end
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            local vp = getLiveViewportSize()
            local minX, maxX, minY, maxY = getSafeScreenBounds()

            local newX = math.clamp(startPos.X.Offset + delta.X, 10, vp.X - frame.AbsoluteSize.X - 10)
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 20, vp.Y - frame.AbsoluteSize.Y - 20)

            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

-- ============================================================
-- 7. MANAJEMEN TITIK TARGET (ADD / REMOVE PIN)
-- ============================================================
function AppGui:AddTarget(customX: number?, customY: number?): TargetPoint
    local newId = #State.Targets + 1
    local vp = getLiveViewportSize()

    local defaultX = customX or math.floor(vp.X * 0.5 - 24 + (newId * 25))
    local defaultY = customY or math.floor(vp.Y * 0.45 - 24 + (newId * 20))

    -- Target Pin Frame (Bulat Bernomor)
    local pinFrame = Instance.new("Frame")
    pinFrame.Name = "TargetPin_" .. tostring(newId)
    pinFrame.Size = UDim2.new(0, 48, 0, 48)
    pinFrame.Position = UDim2.new(0, defaultX, 0, defaultY)
    pinFrame.BackgroundColor3 = Theme.TargetPin
    pinFrame.BackgroundTransparency = 0.15
    pinFrame.BorderSizePixel = 0
    pinFrame.ZIndex = 50
    pinFrame.Visible = State.PinsVisible
    pinFrame.Parent = self.TargetContainer

    local pinCorner = Instance.new("UICorner")
    pinCorner.CornerRadius = UDim.new(1, 0) -- Lingkaran bulat sempurna
    pinCorner.Parent = pinFrame

    local pinStroke = Instance.new("UIStroke")
    pinStroke.Color = Color3.fromRGB(255, 255, 255)
    pinStroke.Thickness = 2
    pinStroke.Transparency = 0.2
    pinStroke.Parent = pinFrame

    -- Inner Dark Center Circle
    local innerCircle = Instance.new("Frame")
    innerCircle.Size = UDim2.new(0, 36, 0, 36)
    innerCircle.Position = UDim2.new(0.5, -18, 0.5, -18)
    innerCircle.BackgroundColor3 = Theme.TargetInner
    innerCircle.BackgroundTransparency = 0.1
    innerCircle.BorderSizePixel = 0
    innerCircle.ZIndex = 51
    innerCircle.Parent = pinFrame

    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(1, 0)
    innerCorner.Parent = innerCircle

    -- Crosshair Center Point
    local crossX = Instance.new("Frame")
    crossX.Size = UDim2.new(0, 8, 0, 2)
    crossX.Position = UDim2.new(0.5, -4, 0.5, -1)
    crossX.BackgroundColor3 = Theme.AccentGlow
    crossX.BorderSizePixel = 0
    crossX.ZIndex = 52
    crossX.Parent = innerCircle

    local crossY = Instance.new("Frame")
    crossY.Size = UDim2.new(0, 2, 0, 8)
    crossY.Position = UDim2.new(0.5, -1, 0.5, -4)
    crossY.BackgroundColor3 = Theme.AccentGlow
    crossY.BorderSizePixel = 0
    crossY.ZIndex = 52
    crossY.Parent = innerCircle

    -- Target Number Badge
    local numLabel = Instance.new("TextLabel")
    numLabel.Size = UDim2.new(1, 0, 1, 0)
    numLabel.BackgroundTransparency = 1
    numLabel.Text = tostring(newId)
    numLabel.TextColor3 = Theme.Text
    numLabel.TextSize = 14
    numLabel.Font = Enum.Font.GothamBold
    numLabel.ZIndex = 53
    numLabel.Parent = innerCircle

    -- Visual Pulse Ring (Animasi Berdenyut Saat Ditekan)
    local pulseRing = Instance.new("Frame")
    pulseRing.Size = UDim2.new(1, 0, 1, 0)
    pulseRing.Position = UDim2.new(0.5, 0, 0.5, 0)
    pulseRing.AnchorPoint = Vector2.new(0.5, 0.5)
    pulseRing.BackgroundColor3 = Theme.TargetPulse
    pulseRing.BackgroundTransparency = 1
    pulseRing.BorderSizePixel = 0
    pulseRing.Visible = false
    pulseRing.ZIndex = 49
    pulseRing.Parent = pinFrame

    local pulseCorner = Instance.new("UICorner")
    pulseCorner.CornerRadius = UDim.new(1, 0)
    pulseCorner.Parent = pulseRing

    -- Dragging Handler untuk Pin Target
    applyUniversalDrag(pinFrame)

    -- Quick Edit Delay Dialog jika pin diklik
    local clickTime = 0
    pinFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickTime = os.clock()
        end
    end)

    pinFrame.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            -- Jika hanya tap singkat (bukan drag), buka dialog pengeditan cepat
            if (os.clock() - clickTime) < 0.25 then
                self:OpenQuickDelayDialog(newId)
            end
        end
    end)

    local targetObj: TargetPoint = {
        id = newId,
        pinFrame = pinFrame,
        pulseRing = pulseRing,
        numberLabel = numLabel,
        delayMs = State.DefaultDelayMs,
        position = Vector2.new(defaultX, defaultY),
    }

    table.insert(State.Targets, targetObj)
    self:UpdateStatusText()
    return targetObj
end

function AppGui:RemoveLastTarget()
    if #State.Targets == 0 then return end
    local last = table.remove(State.Targets, #State.Targets)
    if last and last.pinFrame then
        last.pinFrame:Destroy()
    end
    self:UpdateStatusText()
end

function AppGui:ClearAllTargets()
    for _, t in ipairs(State.Targets) do
        if t.pinFrame then
            t.pinFrame:Destroy()
        end
    end
    table.clear(State.Targets)
    self:UpdateStatusText()
end

function AppGui:SetPinsVisibility(visible: boolean)
    State.PinsVisible = visible
    for _, t in ipairs(State.Targets) do
        if t.pinFrame then
            t.pinFrame.Visible = visible
        end
    end
end

-- ============================================================
-- 8. DIALOG PENGATURAN CEPAT INDIVIDUAL PIN
-- ============================================================
function AppGui:OpenQuickDelayDialog(targetId: number)
    local target = State.Targets[targetId]
    if not target then return end

    local existing = self.ScreenGui:FindFirstChild("QuickDelayDialog")
    if existing then existing:Destroy() end

    local dialog = Instance.new("Frame")
    dialog.Name = "QuickDelayDialog"
    dialog.Size = UDim2.new(0, 220, 0, 130)
    dialog.Position = UDim2.new(0, target.pinFrame.AbsolutePosition.X - 85, 0, target.pinFrame.AbsolutePosition.Y - 140)
    dialog.BackgroundColor3 = Theme.CardBg
    dialog.BorderSizePixel = 0
    dialog.ZIndex = 80
    dialog.Parent = self.ScreenGui

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 10)
    dCorner.Parent = dialog

    local dStroke = Instance.new("UIStroke")
    dStroke.Color = Theme.Accent
    dStroke.Thickness = 1.5
    dStroke.Parent = dialog

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 10, 0, 8)
    title.BackgroundTransparency = 1
    title.Text = "Pengaturan Target #" .. tostring(targetId)
    title.TextColor3 = Theme.Text
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.ZIndex = 81
    title.Parent = dialog

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 32)
    box.Position = UDim2.new(0, 10, 0, 40)
    box.BackgroundColor3 = Theme.BarBg
    box.Text = tostring(target.delayMs)
    box.TextColor3 = Theme.AccentGlow
    box.TextSize = 13
    box.Font = Enum.Font.GothamBold
    box.ZIndex = 81
    box.Parent = dialog

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 6)
    boxCorner.Parent = box

    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.46, 0, 0, 28)
    saveBtn.Position = UDim2.new(0, 10, 0, 85)
    saveBtn.BackgroundColor3 = Theme.Play
    saveBtn.Text = "Simpan"
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Font = Enum.Font.GothamBold
    saveBtn.TextSize = 11
    saveBtn.ZIndex = 81
    saveBtn.Parent = dialog

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(0, 6)
    sCorner.Parent = saveBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.46, 0, 0, 28)
    closeBtn.Position = UDim2.new(0.54, 0, 0, 85)
    closeBtn.BackgroundColor3 = Theme.ButtonBg
    closeBtn.Text = "Batal"
    closeBtn.TextColor3 = Theme.TextSubtle
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.TextSize = 11
    closeBtn.ZIndex = 81
    closeBtn.Parent = dialog

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = closeBtn

    saveBtn.MouseButton1Click:Connect(function()
        local val = tonumber(box.Text)
        if val and val >= 20 then
            target.delayMs = math.floor(val)
        end
        dialog:Destroy()
    end)

    closeBtn.MouseButton1Click:Connect(function()
        dialog:Destroy()
    end)
end

-- ============================================================
-- 9. PEMBUATAN FLOATING TOOLBAR (KONTROL MELAYANG)
-- ============================================================
function AppGui:Create()
    local mount = self:GetMountContainer()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RebelAutoClickerGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 99999
    screenGui.Parent = mount
    self.ScreenGui = screenGui

    -- Container untuk seluruh titik target
    local targetContainer = Instance.new("Frame")
    targetContainer.Name = "TargetContainer"
    targetContainer.Size = UDim2.new(1, 0, 1, 0)
    targetContainer.BackgroundTransparency = 1
    targetContainer.Parent = screenGui
    self.TargetContainer = targetContainer

    -- FLOATING CONTROL TOOLBAR (Gaya Android Auto Clicker)
    local toolbar = Instance.new("Frame")
    toolbar.Name = "AutoClickerToolbar"
    toolbar.Size = UDim2.new(0, 52, 0, 260)
    toolbar.Position = UDim2.new(0, 25, 0.35, 0)
    toolbar.BackgroundColor3 = Theme.BarBg
    toolbar.BorderSizePixel = 0
    toolbar.ZIndex = 60
    toolbar.Parent = screenGui
    self.Toolbar = toolbar

    local tbCorner = Instance.new("UICorner")
    tbCorner.CornerRadius = UDim.new(0, 26)
    tbCorner.Parent = toolbar

    local tbStroke = Instance.new("UIStroke")
    tbStroke.Color = Theme.BarBorder
    tbStroke.Thickness = 1.5
    tbStroke.Parent = toolbar

    -- Drag Handle Icon di Paling Atas Toolbar
    local dragPill = Instance.new("Frame")
    dragPill.Size = UDim2.new(0, 20, 0, 4)
    dragPill.Position = UDim2.new(0.5, -10, 0, 8)
    dragPill.BackgroundColor3 = Theme.TextSubtle
    dragPill.BackgroundTransparency = 0.5
    dragPill.BorderSizePixel = 0
    dragPill.ZIndex = 61
    dragPill.Parent = toolbar

    local dpCorner = Instance.new("UICorner")
    dpCorner.CornerRadius = UDim.new(1, 0)
    dpCorner.Parent = dragPill

    applyUniversalDrag(toolbar)

    -- Layout Vertikal untuk Tombol Toolbar
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = toolbar

    -- Helper Pembuat Tombol Bundar Toolbar
    local function createToolButton(name: string, symbol: string, bgColor: Color3, callback: () -> ()): TextButton
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(0, 38, 0, 38)
        btn.BackgroundColor3 = bgColor
        btn.BorderSizePixel = 0
        btn.Text = symbol
        btn.TextColor3 = Theme.Text
        btn.TextSize = 18
        btn.Font = Enum.Font.GothamBold
        btn.ZIndex = 62
        btn.Parent = toolbar

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn

        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Theme.BarBorder
        btnStroke.Thickness = 1
        btnStroke.Parent = btn

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- 1. Tombol Play / Pause
    self.PlayBtn = createToolButton("PlayBtn", "▶", Theme.Play, function()
        if #State.Targets == 0 then
            self:AddTarget()
        end
        ClickEngine:Toggle()
        self:UpdatePlayButtonVisual()
    end)

    -- 2. Tombol Tambah Titik Target (+)
    createToolButton("AddBtn", "+", Theme.ButtonBg, function()
        self:AddTarget()
    end)

    -- 3. Tombol Hapus Titik Terakhir (-)
    createToolButton("RemoveBtn", "—", Theme.ButtonBg, function()
        self:RemoveLastTarget()
    end)

    -- 4. Tombol Hide / Show Pins (👁)
    local eyeBtn: TextButton
    eyeBtn = createToolButton("EyeBtn", "👁", Theme.ButtonBg, function()
        self:SetPinsVisibility(not State.PinsVisible)
        eyeBtn.TextColor3 = State.PinsVisible and Theme.Text or Theme.TextSubtle
    end)

    -- 5. Tombol Pengaturan (⚙)
    createToolButton("SettingsBtn", "⚙", Theme.ButtonBg, function()
        self:ToggleSettingsModal()
    end)

    -- 6. Tombol Close (✕)
    createToolButton("CloseBtn", "✕", Theme.Remove, function()
        self:Destroy()
    end)

    -- Buat Modal Pengaturan Lengkap
    self:BuildSettingsModal()

    -- Tambahkan 1 titik target bawaan saat pertama kali terbuka
    self:AddTarget()

    print("[Rebel AutoClicker] Multi-Target Edition berhasil dimuat!")
end

function AppGui:UpdatePlayButtonVisual()
    if not self.PlayBtn then return end
    if State.IsRunning then
        self.PlayBtn.Text = "⏸"
        self.PlayBtn.BackgroundColor3 = Theme.Pause
    else
        self.PlayBtn.Text = "▶"
        self.PlayBtn.BackgroundColor3 = Theme.Play
    end
end

-- ============================================================
-- 10. MODAL PENGATURAN LENGKAP (SETTINGS PANEL)
-- ============================================================
function AppGui:BuildSettingsModal()
    local modal = Instance.new("Frame")
    modal.Name = "SettingsModal"
    modal.Size = UDim2.new(0, 290, 0, 320)
    modal.Position = UDim2.new(0.5, -145, 0.5, -160)
    modal.BackgroundColor3 = Theme.CardBg
    modal.BorderSizePixel = 0
    modal.Visible = false
    modal.ZIndex = 70
    modal.Parent = self.ScreenGui
    self.SettingsModal = modal

    local mCorner = Instance.new("UICorner")
    mCorner.CornerRadius = UDim.new(0, 12)
    mCorner.Parent = modal

    local mStroke = Instance.new("UIStroke")
    mStroke.Color = Theme.BarBorder
    mStroke.Thickness = 1.5
    mStroke.Parent = modal

    applyUniversalDrag(modal)

    -- Header Modal
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Theme.BarBg
    header.BorderSizePixel = 0
    header.ZIndex = 71
    header.Parent = modal

    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0, 12)
    hCorner.Parent = header

    local hTitle = Instance.new("TextLabel")
    hTitle.Size = UDim2.new(1, -50, 1, 0)
    hTitle.Position = UDim2.new(0, 14, 0, 0)
    hTitle.BackgroundTransparency = 1
    hTitle.Text = "PENGATURAN AUTO CLICKER"
    hTitle.TextColor3 = Theme.Text
    hTitle.TextSize = 12
    hTitle.Font = Enum.Font.GothamBold
    hTitle.TextXAlignment = Enum.TextXAlignment.Left
    hTitle.ZIndex = 72
    hTitle.Parent = header

    local closeMBtn = Instance.new("TextButton")
    closeMBtn.Size = UDim2.new(0, 30, 0, 30)
    closeMBtn.Position = UDim2.new(1, -35, 0.5, -15)
    closeMBtn.BackgroundColor3 = Theme.ButtonBg
    closeMBtn.Text = "✕"
    closeMBtn.TextColor3 = Theme.TextSubtle
    closeMBtn.Font = Enum.Font.GothamBold
    closeMBtn.TextSize = 13
    closeMBtn.ZIndex = 72
    closeMBtn.Parent = header

    local cmCorner = Instance.new("UICorner")
    cmCorner.CornerRadius = UDim.new(1, 0)
    cmCorner.Parent = closeMBtn

    closeMBtn.MouseButton1Click:Connect(function()
        modal.Visible = false
    end)

    -- Isi Pengaturan (Form)
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -24, 1, -55)
    content.Position = UDim2.new(0, 12, 0, 48)
    content.BackgroundTransparency = 1
    content.ZIndex = 71
    content.Parent = modal

    local cLayout = Instance.new("UIListLayout")
    cLayout.Padding = UDim.new(0, 10)
    cLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cLayout.Parent = content

    -- 1. Default Interval / Delay
    local intRow = Instance.new("Frame")
    intRow.Size = UDim2.new(1, 0, 0, 50)
    intRow.BackgroundColor3 = Theme.BarBg
    intRow.BorderSizePixel = 0
    intRow.ZIndex = 72
    intRow.Parent = content

    local irCorner = Instance.new("UICorner")
    irCorner.CornerRadius = UDim.new(0, 8)
    irCorner.Parent = intRow

    local intLabel = Instance.new("TextLabel")
    intLabel.Size = UDim2.new(0.65, 0, 1, 0)
    intLabel.Position = UDim2.new(0, 10, 0, 0)
    intLabel.BackgroundTransparency = 1
    intLabel.Text = "Interval Default (ms):\n<font size='9' color='#969eaf'>Waktu jeda per titik klik</font>"
    intLabel.TextColor3 = Theme.Text
    intLabel.TextSize = 11
    intLabel.RichText = true
    intLabel.Font = Enum.Font.Gotham
    intLabel.TextXAlignment = Enum.TextXAlignment.Left
    intLabel.ZIndex = 73
    intLabel.Parent = intRow

    local intBox = Instance.new("TextBox")
    intBox.Size = UDim2.new(0.28, 0, 0, 30)
    intBox.Position = UDim2.new(0.68, 0, 0.5, -15)
    intBox.BackgroundColor3 = Theme.CardBg
    intBox.Text = tostring(State.DefaultDelayMs)
    intBox.TextColor3 = Theme.AccentGlow
    intBox.TextSize = 12
    intBox.Font = Enum.Font.GothamBold
    intBox.ZIndex = 73
    intBox.Parent = intRow

    local ibCorner = Instance.new("UICorner")
    ibCorner.CornerRadius = UDim.new(0, 6)
    ibCorner.Parent = intBox

    intBox.FocusLost:Connect(function()
        local val = tonumber(intBox.Text)
        if val and val >= 20 then
            State.DefaultDelayMs = math.floor(val)
        else
            intBox.Text = tostring(State.DefaultDelayMs)
        end
    end)

    -- 2. Anti-Detection Humanize Jitter
    local jitRow = Instance.new("Frame")
    jitRow.Size = UDim2.new(1, 0, 0, 50)
    jitRow.BackgroundColor3 = Theme.BarBg
    jitRow.BorderSizePixel = 0
    jitRow.ZIndex = 72
    jitRow.Parent = content

    local jrCorner = Instance.new("UICorner")
    jrCorner.CornerRadius = UDim.new(0, 8)
    jrCorner.Parent = jitRow

    local jitLabel = Instance.new("TextLabel")
    jitLabel.Size = UDim2.new(0.65, 0, 1, 0)
    jitLabel.Position = UDim2.new(0, 10, 0, 0)
    jitLabel.BackgroundTransparency = 1
    jitLabel.Text = "Anti-Bot Jitter:\n<font size='9' color='#969eaf'>Variasi acak (±ms, ±px)</font>"
    jitLabel.TextColor3 = Theme.Text
    jitLabel.TextSize = 11
    jitLabel.RichText = true
    jitLabel.Font = Enum.Font.Gotham
    jitLabel.TextXAlignment = Enum.TextXAlignment.Left
    jitLabel.ZIndex = 73
    jitLabel.Parent = jitRow

    local jitBtn = Instance.new("TextButton")
    jitBtn.Size = UDim2.new(0.28, 0, 0, 30)
    jitBtn.Position = UDim2.new(0.68, 0, 0.5, -15)
    jitBtn.BackgroundColor3 = State.IsHumanize and Theme.Play or Theme.ButtonBg
    jitBtn.Text = State.IsHumanize and "ON" or "OFF"
    jitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    jitBtn.TextSize = 11
    jitBtn.Font = Enum.Font.GothamBold
    jitBtn.ZIndex = 73
    jitBtn.Parent = jitRow

    local jbCorner = Instance.new("UICorner")
    jbCorner.CornerRadius = UDim.new(0, 6)
    jbCorner.Parent = jitBtn

    jitBtn.MouseButton1Click:Connect(function()
        State.IsHumanize = not State.IsHumanize
        jitBtn.Text = State.IsHumanize and "ON" or "OFF"
        jitBtn.BackgroundColor3 = State.IsHumanize and Theme.Play or Theme.ButtonBg
    end)

    -- 3. Live Status & Statistik Sesi
    local statBox = Instance.new("Frame")
    statBox.Size = UDim2.new(1, 0, 0, 105)
    statBox.BackgroundColor3 = Theme.BarBg
    statBox.BorderSizePixel = 0
    statBox.ZIndex = 72
    statBox.Parent = content

    local sbCorner = Instance.new("UICorner")
    sbCorner.CornerRadius = UDim.new(0, 8)
    sbCorner.Parent = statBox

    local statLabel = Instance.new("TextLabel")
    statLabel.Size = UDim2.new(1, -16, 1, -16)
    statLabel.Position = UDim2.new(0, 10, 0, 8)
    statLabel.BackgroundTransparency = 1
    statLabel.TextColor3 = Theme.Text
    statLabel.TextSize = 10
    statLabel.Font = Enum.Font.Gotham
    statLabel.TextXAlignment = Enum.TextXAlignment.Left
    statLabel.TextYAlignment = Enum.TextYAlignment.Top
    statLabel.RichText = true
    statLabel.ZIndex = 73
    statLabel.Parent = statBox

    -- Background Updater untuk Label Statistik
    task.spawn(function()
        while screenGui.Parent do
            local elapsed = os.time() - State.StartTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = elapsed % 60
            local timeStr = string.format("%02d:%02d:%02d", h, m, s)

            local statusStr = State.IsRunning and "<font color='#2ecc71'>BERJALAN</font>" or "<font color='#f39c12'>STANDBY</font>"
            statLabel.Text = string.format(
                "• <b>Status Engine:</b> %s\n" ..
                "• <b>Jumlah Titik Target:</b> <font color='#00d2ff'>%d titik</font>\n" ..
                "• <b>Target Aktif Sekarang:</b> #%d\n" ..
                "• <b>Total Klik Terkirim:</b> <font color='#00d2ff'>%d</font>\n" ..
                "• <b>Durasi Sesi:</b> %s",
                statusStr, #State.Targets, State.ActiveTargetIndex, State.TotalClicks, timeStr
            )
            task.wait(0.5)
        end
    end)
end

function AppGui:ToggleSettingsModal()
    if self.SettingsModal then
        self.SettingsModal.Visible = not self.SettingsModal.Visible
    end
end

function AppGui:UpdateStatusText()
    -- Sinkronisasi visual
end

-- ============================================================
-- 11. CLEAN TEARDOWN (PEMBERSIHAN TOTAL MEMORI)
-- ============================================================
function AppGui:Destroy()
    ClickEngine:Stop()

    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(State.Connections)

    self:ClearAllTargets()

    if self.ScreenGui then
        pcall(function() self.ScreenGui:Destroy() end)
        self.ScreenGui = nil
    end

    genv.__REBEL_AUTOCLICK_LOADED = nil
    genv.__REBEL_AUTOCLICK_CLEANUP = nil
    print("[Rebel AutoClicker] Ditutup dan memori dibersihkan.")
end

genv.__REBEL_AUTOCLICK_CLEANUP = function()
    AppGui:Destroy()
end

-- ============================================================
-- 12. RUN SCRIPT
-- ============================================================
AppGui:Create()

return {
    ClickEngine = ClickEngine,
    State = State,
    AppGui = AppGui,
}
