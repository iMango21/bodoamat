--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                 BODOAMAT - NEON KEY SYSTEM                    ║
    ║     Cyberpunk Glassmorphism Authentication Interface         ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

local LINK = "https://link-target.net/1417470/g6eKEoq2bJV9"
local MAIN_SCRIPT = "https://raw.githubusercontent.com/iMango21/bodoamat/main/Bodoamat.luau"

-- Kunci otorisasi (default: "aluksx")
local KEY = string.reverse("xskula")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local genv = (getgenv and getgenv()) or {}
if genv.__BODOAMAT_KEY_SYSTEM then
    pcall(function() genv.__BODOAMAT_KEY_SYSTEM:Destroy() end)
end

local targetParent = nil
if gethui then
    targetParent = gethui()
elseif LocalPlayer:FindFirstChild("PlayerGui") then
    targetParent = LocalPlayer.PlayerGui
else
    targetParent = game:GetService("CoreGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "BodoamatKeySystem"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = targetParent
genv.__BODOAMAT_KEY_SYSTEM = gui

local function copyToClipboard(text: string)
    local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
    if fn then
        pcall(fn, text)
    end
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 420, 0, 310)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -155)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = mainFrame

local border = Instance.new("UIStroke")
border.Color = Color3.fromRGB(0, 255, 200)
border.Transparency = 0.5
border.Thickness = 1.5
border.Parent = mainFrame

for i = 1, 10 do
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0, i * 30)
    line.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
    line.BackgroundTransparency = 0.96
    line.BorderSizePixel = 0
    line.Parent = mainFrame
end

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(1, 0, 0, 3)
accentBar.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
accentBar.BorderSizePixel = 0
accentBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 15)
title.BackgroundTransparency = 1
title.Text = ">> BODOAMAT TERMINAL <<"
title.TextColor3 = Color3.fromRGB(0, 255, 200)
title.TextSize = 18
title.Font = Enum.Font.Code
title.Parent = mainFrame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(1, 0, 0, 20)
subtitle.Position = UDim2.new(0, 0, 0, 52)
subtitle.BackgroundTransparency = 1
subtitle.Text = "// ENTER AUTHORIZATION KEY //"
subtitle.TextColor3 = Color3.fromRGB(110, 120, 140)
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Code
subtitle.Parent = mainFrame

local inputContainer = Instance.new("Frame")
inputContainer.Name = "InputContainer"
inputContainer.Size = UDim2.new(0.85, 0, 0, 46)
inputContainer.Position = UDim2.new(0.075, 0, 0.36, 0)
inputContainer.BackgroundColor3 = Color3.fromRGB(5, 6, 12)
inputContainer.BackgroundTransparency = 0.2
inputContainer.BorderSizePixel = 0
inputContainer.Parent = mainFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 4)
inputCorner.Parent = inputContainer

local inputBorder = Instance.new("UIStroke")
inputBorder.Color = Color3.fromRGB(0, 255, 200)
inputBorder.Transparency = 0.6
inputBorder.Thickness = 1
inputBorder.Parent = inputContainer

local cursor = Instance.new("Frame")
cursor.Size = UDim2.new(0, 2, 0, 18)
cursor.Position = UDim2.new(0, 12, 0.5, -9)
cursor.BackgroundColor3 = Color3.fromRGB(0, 255, 200)
cursor.BorderSizePixel = 0
cursor.Parent = inputContainer

task.spawn(function()
    while mainFrame and mainFrame.Parent do
        cursor.Visible = not cursor.Visible
        task.wait(0.5)
    end
end)

local inputBox = Instance.new("TextBox")
inputBox.Name = "KeyInput"
inputBox.Size = UDim2.new(1, -28, 1, 0)
inputBox.Position = UDim2.new(0, 20, 0, 0)
inputBox.BackgroundTransparency = 1
inputBox.Text = ""
inputBox.PlaceholderText = "ENTER_KEY_HERE..."
inputBox.TextColor3 = Color3.fromRGB(0, 255, 200)
inputBox.PlaceholderColor3 = Color3.fromRGB(0, 180, 140)
inputBox.TextSize = 14
inputBox.Font = Enum.Font.Code
inputBox.ClearTextOnFocus = false
inputBox.TextXAlignment = Enum.TextXAlignment.Left
inputBox.Parent = inputContainer

local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(0.85, 0, 0, 44)
buttonContainer.Position = UDim2.new(0.075, 0, 0.58, 0)
buttonContainer.BackgroundTransparency = 1
buttonContainer.Parent = mainFrame

local getKeyBtn = Instance.new("TextButton")
getKeyBtn.Name = "GetKeyBtn"
getKeyBtn.Size = UDim2.new(0.48, -4, 1, 0)
getKeyBtn.Position = UDim2.new(0, 0, 0, 0)
getKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 24, 32)
getKeyBtn.BackgroundTransparency = 0.3
getKeyBtn.Text = "[ GET KEY ]"
getKeyBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
getKeyBtn.TextSize = 13
getKeyBtn.Font = Enum.Font.Code
getKeyBtn.Parent = buttonContainer

local getKeyCorner = Instance.new("UICorner")
getKeyCorner.CornerRadius = UDim.new(0, 4)
getKeyCorner.Parent = getKeyBtn

local getKeyBorder = Instance.new("UIStroke")
getKeyBorder.Color = Color3.fromRGB(0, 255, 200)
getKeyBorder.Transparency = 0.5
getKeyBorder.Thickness = 1
getKeyBorder.Parent = getKeyBtn

local checkKeyBtn = Instance.new("TextButton")
checkKeyBtn.Name = "CheckKeyBtn"
checkKeyBtn.Size = UDim2.new(0.48, -4, 1, 0)
checkKeyBtn.Position = UDim2.new(0.52, 4, 0, 0)
checkKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 32, 24)
checkKeyBtn.BackgroundTransparency = 0.3
checkKeyBtn.Text = "[ AUTH ]"
checkKeyBtn.TextColor3 = Color3.fromRGB(0, 255, 200)
checkKeyBtn.TextSize = 13
checkKeyBtn.Font = Enum.Font.Code
checkKeyBtn.Parent = buttonContainer

local checkKeyCorner = Instance.new("UICorner")
checkKeyCorner.CornerRadius = UDim.new(0, 4)
checkKeyCorner.Parent = checkKeyBtn

local checkKeyBorder = Instance.new("UIStroke")
checkKeyBorder.Color = Color3.fromRGB(0, 255, 200)
checkKeyBorder.Transparency = 0.5
checkKeyBorder.Thickness = 1
checkKeyBorder.Parent = checkKeyBtn

local statusFrame = Instance.new("Frame")
statusFrame.Name = "StatusFrame"
statusFrame.Size = UDim2.new(0.85, 0, 0, 32)
statusFrame.Position = UDim2.new(0.075, 0, 0.80, 0)
statusFrame.BackgroundColor3 = Color3.fromRGB(5, 6, 12)
statusFrame.BackgroundTransparency = 0.3
statusFrame.BorderSizePixel = 0
statusFrame.Visible = false
statusFrame.Parent = mainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 4)
statusCorner.Parent = statusFrame

local statusBorder = Instance.new("UIStroke")
statusBorder.Color = Color3.fromRGB(0, 255, 200)
statusBorder.Transparency = 0.6
statusBorder.Thickness = 1
statusBorder.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, -16, 1, 0)
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(0, 255, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Code
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame

local statusThread = nil
local function showStatus(message: string, color: Color3, duration: number?)
    if statusThread then
        task.cancel(statusThread)
        statusThread = nil
    end

    statusFrame.Visible = true
    statusLabel.Text = ">> " .. message
    statusLabel.TextColor3 = color
    statusBorder.Color = color

    if duration then
        statusThread = task.delay(duration, function()
            statusFrame.Visible = false
            statusThread = nil
        end)
    end
end

getKeyBtn.MouseEnter:Connect(function()
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 48, 64)
    getKeyBorder.Transparency = 0.1
end)
getKeyBtn.MouseLeave:Connect(function()
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 24, 32)
    getKeyBorder.Transparency = 0.5
end)

checkKeyBtn.MouseEnter:Connect(function()
    checkKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 60, 48)
    checkKeyBorder.Transparency = 0.1
end)
checkKeyBtn.MouseLeave:Connect(function()
    checkKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 32, 24)
    checkKeyBorder.Transparency = 0.5
end)

getKeyBtn.MouseButton1Click:Connect(function()
    copyToClipboard(LINK)
    showStatus("LINK TERSALIN KE CLIPBOARD!", Color3.fromRGB(0, 255, 200), 2.5)
end)

checkKeyBtn.MouseButton1Click:Connect(function()
    local enteredKey = inputBox.Text:gsub("%s+", ""):lower()
    
    if enteredKey == KEY:lower() then
        showStatus("AKSES DITERIMA - MEMUAT BODOAMAT...", Color3.fromRGB(0, 255, 120))
        task.wait(0.6)
        
        gui:Destroy()
        genv.__BODOAMAT_KEY_SYSTEM = nil
        
        local loadSuccess, loadErr = pcall(function()
            if isfile and readfile and isfile("Bodoamat.luau") then
                loadstring(readfile("Bodoamat.luau"))()
            else
                loadstring(game:HttpGet(MAIN_SCRIPT, true))()
            end
        end)
        
        if not loadSuccess then
            warn("[KeySystem Error] Gagal memuat script: " .. tostring(loadErr))
        end
    else
        showStatus("KUNCI SALAH / TIDAK VALID!", Color3.fromRGB(255, 70, 70), 4)
        inputBox.Text = ""
    end
end)

inputBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        checkKeyBtn.MouseButton1Click:Fire()
    end
end)
