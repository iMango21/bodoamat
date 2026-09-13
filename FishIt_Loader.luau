--!strict
--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║           FISH IT! - STEALTH ANTI-BAC DEDICATED LOADER        ║
    ║   Game-Specific Entry Point & Multi-Layer Anti-Cheat Guard    ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Fitur Keamanan Anti-BAC & Roblox Anti-Cheat:
    1. Game Lock: Hanya dapat dieksekusi di Fish It! (Universe/Place ID).
    2. Zero Memory Flagging: Tidak merusak _G/shared, terlindungi via getgenv.
    3. Game & Character Readiness: Mencegah desync flag akibat eksekusi prematur.
    4. BAC Neutralizer: Mematikan remote pelaporan AC-Response & BAC-Log.
    5. UI Stealth Isolation: Mengutamakan gethui() / protectgui agar tidak di-scan game.
    6. Protected Execution: Memuat payload melalui pcall terisolasi dengan auto-recovery.
]]

-- ============================================================
-- 1. IDENTIFIKASI & VALIDASI GAME (FISH IT ONLY)
-- ============================================================
local FISH_IT_IDS = {
    Universes = {
        [6701277882]      = true, -- Fish It Main Universe ID (Verified via Lynxx Hub)
        [79378095465365]  = true, -- Fish It Sub/Alternative Universe ID (Meng Hub)
    },
    Places = {
        [121864768012064] = true, -- Fish It Main Place
        [79378095465365]  = true, -- Fallback Direct Place ID
    }
}

local currentPlaceId = game.PlaceId
local currentUniverseId = game.GameId

local isFishIt = FISH_IT_IDS.Universes[currentUniverseId] or FISH_IT_IDS.Places[currentPlaceId]

if not isFishIt then
    -- Notifikasi aman tanpa memicu crash atau kick kasar yang memancing kecurigaan log
    local notify = function(title: string, text: string)
        pcall(function()
            local StarterGui = game:GetService("StarterGui")
            StarterGui:SetCore("SendNotification", {
                Title = title,
                Text = text,
                Duration = 7
            })
        end)
    end

    notify("⚠️ Script Batal Dimuat", "Script ini dikhususkan HANYA untuk Fish It! (Place: " .. tostring(currentPlaceId) .. ")")
    warn("[Loader Security] Pembatalan eksekusi: Game saat ini (" .. tostring(currentPlaceId) .. ") bukan Fish It!.")
    return
end

-- ============================================================
-- 2. ANTI-DUPLIKASI & ISOLASI ENVIRONMENT
-- ============================================================
local genv = (getgenv and getgenv()) or {}
if genv.__FISHIT_LOADER_RUNNING then
    warn("[Loader Security] Instance script sudah aktif di memori.")
    return
end
genv.__FISHIT_LOADER_RUNNING = true

-- ============================================================
-- 3. STATE READINESS CHECK (ANTI-DESYNC TRIPWIRE)
-- ============================================================
-- Mencegah injeksi mendadak saat map/karakter belum selesai memuat (pemicu flag BAC)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
    LocalPlayer.CharacterAdded:Wait()
    local char = LocalPlayer.Character
    if char then
        char:WaitForChild("HumanoidRootPart", 10)
    end
end

-- Jeda stabilisasi awal agar thread client selesai melakukan handshake dengan server
task.wait(0.5)

-- ============================================================
-- 4. BAC (BACON ANTI-CHEAT) NEUTRALIZATION SHIELD
-- ============================================================
local function NeutralizeAntiCheat()
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local getconns = (getconnections and getconnections)
            or (getfenv and getfenv().getconnections)
            or (genv and genv.getconnections)

        -- Daftar remote telemetri pelaporan yang sering dipakai BAC/game anti-cheat
        local acRemotes = {
            "AC-Response",
            "Punishment",
            "BAC-Log",
            "ClientCheck",
            "BAC_Kick",
            "SecurityPing",
            "IntegrityCheck"
        }

        for _, remoteName in ipairs(acRemotes) do
            local target = ReplicatedStorage:FindFirstChild(remoteName)
            if target then
                if target:IsA("RemoteEvent") and getconns then
                    local conns = getconns(target.OnClientEvent)
                    if conns then
                        for _, conn in ipairs(conns) do
                            pcall(function() conn:Disable() end)
                        end
                    end
                elseif target:IsA("RemoteFunction") then
                    pcall(function()
                        target.OnClientInvoke = function(...) return nil end
                    end)
                end
            end
        end
    end)
end

NeutralizeAntiCheat()

-- ============================================================
-- 5. STEALTH PAYLOAD LOADER
-- ============================================================
local function SafeNotify(title: string, desc: string)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = desc,
            Duration = 5
        })
    end)
end

SafeNotify("🛡️ Fish It Stealth Guard", "Anti-Cheat dinetralisasi. Memuat sistem...")

-- Eksekusi aman file script utama
local success, err = pcall(function()
    -- Prioritas 1: Jika file Bodoamat / script utama tersedia secara lokal di executor
    local isLocalFile = false
    if isfile and readfile then
        local localPaths = { "Bodoamat.luau", "LuaRebel/Bodoamat.luau", "bodoamat.lua" }
        for _, path in ipairs(localPaths) do
            if isfile(path) then
                loadstring(readfile(path))()
                isLocalFile = true
                break
            end
        end
    end

    -- Prioritas 2: Muat dari repository GitHub Anda (iMango21/bodoamat)
    if not isLocalFile then
        local GITHUB_PAYLOAD_URL = "https://raw.githubusercontent.com/iMango21/bodoamat/main/Bodoamat.luau"
        
        local scriptContent = game:HttpGet(GITHUB_PAYLOAD_URL)
        if scriptContent and #scriptContent > 0 then
            loadstring(scriptContent)()
        else
            error("Gagal mengunduh script payload dari repository iMango21/bodoamat.")
        end
    end
end)

if not success then
    warn("[Loader Error] Terjadi kesalahan saat memuat payload: " .. tostring(err))
    SafeNotify("❌ Error Memuat", "Gagal memuat script Fish It! Periksa konsol F9.")
    genv.__FISHIT_LOADER_RUNNING = nil
end
