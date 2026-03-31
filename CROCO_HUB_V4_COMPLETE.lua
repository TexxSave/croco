-- 🐊 CROCO HUB V4 ULTIMATE - Interface Moderne + Toutes les fonctions 🐊

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootpart = character:WaitForChild("HumanoidRootPart")

-- ========================================
-- VARIABLES & SETTINGS
-- ========================================

local settings = {
    redESP = false,
    rainbowESP = false,
    espTransparency = 0.4,
    aimbot = false,
    aimbotLock = false,
    autoShoot = false,
    triggerBot = false,
    aimbotFOV = 200,
    aimbotSmooth = 3,
    targetPart = "Head",
    showFOV = true,
    noclip = false,
    infiniteJump = false,
    speedEnabled = false,
    walkSpeed = 16,
    fly = false,
    flySpeed = 50,
    jumpPower = 50,
    fullbright = false,
    noFog = false,
    fovChanger = false,
    fovValue = 70,
    thirdPerson = false,
    antiAFK = false,
    spinbot = false,
    spinSpeed = 10,
    theme = "Green"
}

local connections = {}
local highlights = {}
local lockedTarget = nil
local fovCircle = nil
local isRightClickHeld = false
local rainbowHue = 0
local flyConnection = nil

local originalValues = {
    walkSpeed = humanoid.WalkSpeed,
    jumpPower = humanoid.JumpPower,
    fov = camera.FieldOfView
}

-- Thèmes
local themes = {
    Green = Color3.fromRGB(40, 200, 80),
    Blue = Color3.fromRGB(41, 128, 255),
    Red = Color3.fromRGB(255, 60, 60),
    Purple = Color3.fromRGB(138, 43, 226)
}

local currentTheme = themes[settings.theme]

-- ========================================
-- SAUVEGARDE
-- ========================================

local function saveSettings()
    pcall(function()
        writefile("croco_v4_config.json", HttpService:JSONEncode(settings))
    end)
end

local function loadSettings()
    if isfile and isfile("croco_v4_config.json") then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile("croco_v4_config.json"))
        end)
        if success and data then
            for k, v in pairs(data) do
                settings[k] = v
            end
        end
    end
end

loadSettings()
currentTheme = themes[settings.theme] or themes.Green

-- ========================================
-- NOTIFICATIONS
-- ========================================

local activeNotifs = 0

local function notify(title, msg, duration)
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.ResetOnSpawn = false
    NotifGui.DisplayOrder = 999999999
    pcall(function()
        if gethui then
            NotifGui.Parent = gethui()
        else
            NotifGui.Parent = CoreGui
        end
    end)
    
    local Notif = Instance.new("Frame")
    Notif.Size = UDim2.new(0, 300, 0, 70)
    Notif.Position = UDim2.new(1, 320, 0, 20 + (activeNotifs * 80))
    Notif.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Notif.BorderSizePixel = 0
    Notif.Parent = NotifGui
    
    Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 10)
    local Stroke = Instance.new("UIStroke", Notif)
    Stroke.Color = currentTheme
    Stroke.Thickness = 2
    
    local Icon = Instance.new("TextLabel")
    Icon.Size = UDim2.new(0, 40, 0, 40)
    Icon.Position = UDim2.new(0, 10, 0.5, -20)
    Icon.BackgroundTransparency = 1
    Icon.Text = "🐊"
    Icon.Font = Enum.Font.GothamBold
    Icon.TextSize = 28
    Icon.TextColor3 = currentTheme
    Icon.Parent = Notif
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 0, 22)
    Title.Position = UDim2.new(0, 55, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Notif
    
    local Msg = Instance.new("TextLabel")
    Msg.Size = UDim2.new(1, -60, 0, 28)
    Msg.Position = UDim2.new(0, 55, 0, 36)
    Msg.BackgroundTransparency = 1
    Msg.Text = msg
    Msg.Font = Enum.Font.Gotham
    Msg.TextSize = 12
    Msg.TextColor3 = Color3.fromRGB(180, 180, 180)
    Msg.TextXAlignment = Enum.TextXAlignment.Left
    Msg.TextWrapped = true
    Msg.Parent = Notif
    
    activeNotifs = activeNotifs + 1
    
    TweenService:Create(Notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -320, 0, 20 + ((activeNotifs - 1) * 80))
    }):Play()
    
    task.delay(duration or 3, function()
        TweenService:Create(Notif, TweenInfo.new(0.3), {
            Position = UDim2.new(1, 320, 0, 20 + ((activeNotifs - 1) * 80))
        }):Play()
        task.wait(0.4)
        activeNotifs = activeNotifs - 1
        NotifGui:Destroy()
    end)
end

-- ========================================
-- CLEANUP
-- ========================================

local function cleanup()
    for _, conn in pairs(connections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, hl in pairs(highlights) do
        pcall(function() hl:Destroy() end)
    end
    if flyConnection then
        flyConnection:Disconnect()
    end
    connections = {}
    highlights = {}
    lockedTarget = nil
    
    if humanoid then
        humanoid.WalkSpeed = originalValues.walkSpeed
        humanoid.JumpPower = originalValues.jumpPower
    end
    camera.FieldOfView = originalValues.fov
end

-- ========================================
-- GUI MODERNE
-- ========================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CrocoHubV4"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999999

pcall(function()
    if gethui then
        ScreenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    else
        ScreenGui.Parent = CoreGui
    end
end)

-- Frame principale
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 600, 0, 450)
Main.Position = UDim2.new(0.5, -300, 0.5, -225)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = currentTheme
MainStroke.Thickness = 3

-- TitleBar
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 55)
TitleBar.BackgroundColor3 = currentTheme
TitleBar.BorderSizePixel = 0

Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)
local TitleFix = Instance.new("Frame", TitleBar)
TitleFix.Size = UDim2.new(1, 0, 0, 28)
TitleFix.Position = UDim2.new(0, 0, 1, -28)
TitleFix.BackgroundColor3 = currentTheme
TitleFix.BorderSizePixel = 0

local Logo = Instance.new("TextLabel", TitleBar)
Logo.Size = UDim2.new(0, 45, 0, 45)
Logo.Position = UDim2.new(0, 12, 0.5, -22)
Logo.BackgroundTransparency = 1
Logo.Text = "🐊"
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 32
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(0, 200, 0, 28)
Title.Position = UDim2.new(0, 62, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "CROCO HUB V4"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextXAlignment = Enum.TextXAlignment.Left

local Sub = Instance.new("TextLabel", TitleBar)
Sub.Size = UDim2.new(0, 200, 0, 14)
Sub.Position = UDim2.new(0, 62, 0, 34)
Sub.BackgroundTransparency = 1
Sub.Text = "Ultimate Edition"
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 11
Sub.TextColor3 = Color3.fromRGB(255, 255, 255)
Sub.TextTransparency = 0.4
Sub.TextXAlignment = Enum.TextXAlignment.Left

-- Boutons contrôle
local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Size = UDim2.new(0, 35, 0, 35)
MinBtn.Position = UDim2.new(1, -85, 0.5, -17)
MinBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
MinBtn.Text = "─"
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0.5, -17)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
CloseBtn.Text = "✕"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Tabs
local TabContainer = Instance.new("Frame", Main)
TabContainer.Size = UDim2.new(0, 140, 1, -70)
TabContainer.Position = UDim2.new(0, 10, 0, 60)
TabContainer.BackgroundTransparency = 1

-- Content
local Content = Instance.new("ScrollingFrame", Main)
Content.Size = UDim2.new(1, -165, 1, -75)
Content.Position = UDim2.new(0, 155, 0, 65)
Content.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = currentTheme
Content.CanvasSize = UDim2.new(0, 0, 0, 0)

Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 10)

local ContentList = Instance.new("UIListLayout", Content)
ContentList.Padding = UDim.new(0, 8)
ContentList.SortOrder = Enum.SortOrder.LayoutOrder

ContentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Content.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 10)
end)

-- ========================================
-- COMPOSANTS UI
-- ========================================

local function createToggle(text, default, callback)
    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(1, -20, 0, 42)
    Toggle.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Content
    
    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel", Toggle)
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Btn = Instance.new("TextButton", Toggle)
    Btn.Size = UDim2.new(0, 45, 0, 22)
    Btn.Position = UDim2.new(1, -55, 0.5, -11)
    Btn.BackgroundColor3 = default and currentTheme or Color3.fromRGB(50, 50, 55)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)
    
    local Circle = Instance.new("Frame", Btn)
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = default and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.BorderSizePixel = 0
    
    Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)
    
    local enabled = default
    
    Btn.MouseButton1Click:Connect(function()
        enabled = not enabled
        callback(enabled)
        
        TweenService:Create(Btn, TweenInfo.new(0.2), {
            BackgroundColor3 = enabled and currentTheme or Color3.fromRGB(50, 50, 55)
        }):Play()
        
        TweenService:Create(Circle, TweenInfo.new(0.2), {
            Position = enabled and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
    end)
    
    return Toggle
end

local function createSlider(text, min, max, default, suffix, callback)
    local Slider = Instance.new("Frame")
    Slider.Size = UDim2.new(1, -20, 0, 58)
    Slider.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Slider.BorderSizePixel = 0
    Slider.Parent = Content
    
    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 8)
    
    local Label = Instance.new("TextLabel", Slider)
    Label.Size = UDim2.new(0.7, 0, 0, 18)
    Label.Position = UDim2.new(0, 12, 0, 8)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 14
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local ValueBox = Instance.new("TextLabel", Slider)
    ValueBox.Size = UDim2.new(0, 55, 0, 18)
    ValueBox.Position = UDim2.new(1, -67, 0, 8)
    ValueBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    ValueBox.Text = tostring(default) .. (suffix or "")
    ValueBox.Font = Enum.Font.GothamBold
    ValueBox.TextSize = 12
    ValueBox.TextColor3 = currentTheme
    
    Instance.new("UICorner", ValueBox).CornerRadius = UDim.new(0, 5)
    
    local Track = Instance.new("Frame", Slider)
    Track.Size = UDim2.new(1, -24, 0, 5)
    Track.Position = UDim2.new(0, 12, 1, -16)
    Track.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    Track.BorderSizePixel = 0
    
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)
    
    local Fill = Instance.new("Frame", Track)
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = currentTheme
    Fill.BorderSizePixel = 0
    
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)
    
    local Thumb = Instance.new("Frame", Track)
    Thumb.Size = UDim2.new(0, 12, 0, 12)
    Thumb.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel = 0
    
    Instance.new("UICorner", Thumb).CornerRadius = UDim.new(1, 0)
    
    local dragging = false
    
    local function update(value)
        value = math.clamp(math.floor(value), min, max)
        local percent = (value - min) / (max - min)
        
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        Thumb.Position = UDim2.new(percent, -6, 0.5, -6)
        ValueBox.Text = tostring(value) .. (suffix or "")
        
        callback(value)
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local percent = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            update(min + (percent * (max - min)))
        end
    end)
    
    Track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
            update(min + (percent * (max - min)))
        end
    end)
    
    return Slider
end

local function createButton(text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 42)
    Btn.BackgroundColor3 = currentTheme
    Btn.Text = text
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.AutoButtonColor = false
    Btn.Parent = Content
    
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -22, 0, 40)}):Play()
        task.wait(0.1)
        TweenService:Create(Btn, TweenInfo.new(0.1), {Size = UDim2.new(1, -20, 0, 42)}):Play()
        callback()
    end)
    
    return Btn
end

local function createDivider(text)
    local Div = Instance.new("Frame")
    Div.Size = UDim2.new(1, -20, 0, 25)
    Div.BackgroundTransparency = 1
    Div.Parent = Content
    
    local Line = Instance.new("Frame", Div)
    Line.Size = UDim2.new(1, 0, 0, 2)
    Line.Position = UDim2.new(0, 0, 0.5, -1)
    Line.BackgroundColor3 = currentTheme
    Line.BorderSizePixel = 0
    
    if text then
        local Lbl = Instance.new("TextLabel", Div)
        Lbl.Size = UDim2.new(0, 0, 1, 0)
        Lbl.Position = UDim2.new(0.5, 0, 0, 0)
        Lbl.AnchorPoint = Vector2.new(0.5, 0)
        Lbl.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        Lbl.Text = "  " .. text .. "  "
        Lbl.Font = Enum.Font.GothamBold
        Lbl.TextSize = 12
        Lbl.TextColor3 = currentTheme
        Lbl.AutomaticSize = Enum.AutomaticSize.X
    end
    
    return Div
end

-- ========================================
-- FONCTIONS COMPLETE DU V3
-- ========================================

createDivider("ESP")
createToggle("Red ESP", settings.redESP, function(enabled)
    settings.redESP = enabled
    saveSettings()
    if enabled then
        settings.rainbowESP = false
        notify("ESP", "Red ESP enabled", 2)
        local function addESP(plr)
            if plr == player then return end
            local function onCharacter(char)
                task.wait(0.1)
                if not char then return end
                if highlights[plr] then
                    pcall(function() highlights[plr]:Destroy() end)
                end
                local highlight = Instance.new("Highlight")
                highlight.Name = "CrocoESP"
                highlight.Adornee = char
                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(200, 0, 0)
                highlight.FillTransparency = settings.espTransparency
                highlight.OutlineTransparency = 0
                highlight.Parent = char
                highlights[plr] = highlight
            end
            if plr.Character then onCharacter(plr.Character) end
            plr.CharacterAdded:Connect(onCharacter)
        end
        for _, plr in pairs(Players:GetPlayers()) do addESP(plr) end
        table.insert(connections, Players.PlayerAdded:Connect(addESP))
    else
        for _, hl in pairs(highlights) do pcall(function() hl:Destroy() end) end
        highlights = {}
    end
end)

createToggle("Rainbow ESP", settings.rainbowESP, function(enabled)
    settings.rainbowESP = enabled
    saveSettings()
    if enabled then
        settings.redESP = false
        notify("ESP", "Rainbow ESP enabled", 2)
        local function addRainbowESP(plr)
            if plr == player then return end
            local function onCharacter(char)
                task.wait(0.1)
                if not char then return end
                if highlights[plr] then pcall(function() highlights[plr]:Destroy() end) end
                local highlight = Instance.new("Highlight")
                highlight.Name = "CrocoESP"
                highlight.Adornee = char
                highlight.FillColor = Color3.fromHSV(0, 1, 1)
                highlight.OutlineColor = Color3.fromHSV(0, 1, 0.8)
                highlight.FillTransparency = settings.espTransparency
                highlight.OutlineTransparency = 0
                highlight.Parent = char
                highlights[plr] = highlight
            end
            if plr.Character then onCharacter(plr.Character) end
            plr.CharacterAdded:Connect(onCharacter)
        end
        for _, plr in pairs(Players:GetPlayers()) do addRainbowESP(plr) end
        table.insert(connections, Players.PlayerAdded:Connect(addRainbowESP))
        table.insert(connections, RunService.RenderStepped:Connect(function()
            if settings.rainbowESP then
                rainbowHue = (rainbowHue + 0.005) % 1
                for _, hl in pairs(highlights) do
                    if hl and hl.Parent then
                        hl.FillColor = Color3.fromHSV(rainbowHue, 1, 1)
                        hl.OutlineColor = Color3.fromHSV(rainbowHue, 1, 0.8)
                    end
                end
            end
        end))
    else
        for _, hl in pairs(highlights) do pcall(function() hl:Destroy() end) end
        highlights = {}
    end
end)

createSlider("ESP Transparency", 0, 100, settings.espTransparency * 100, "%", function(value)
    settings.espTransparency = value / 100
    saveSettings()
    for _, hl in pairs(highlights) do
        if hl and hl.Parent then
            hl.FillTransparency = settings.espTransparency
        end
    end
end)

createDivider("Aimbot")
createToggle("Aimbot Lock Only", settings.aimbotLock, function(enabled)
    settings.aimbotLock = enabled
    saveSettings()
    if enabled then
        settings.aimbot = false
        notify("Aimbot", "Lock mode enabled", 2)
        if not fovCircle then
            fovCircle = Drawing.new("Circle")
            fovCircle.Visible = true
            fovCircle.Thickness = 2.5
            fovCircle.Color = Color3.fromRGB(100, 150, 255)
            fovCircle.Transparency = 1
            fovCircle.NumSides = 100
            fovCircle.Radius = settings.aimbotFOV
            fovCircle.Filled = false
        end
        table.insert(connections, RunService.RenderStepped:Connect(function()
            if settings.aimbotLock and fovCircle and settings.showFOV then
                local screenSize = camera.ViewportSize
                fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
                fovCircle.Radius = settings.aimbotFOV
                fovCircle.Visible = true
            end
        end))
    else
        if fovCircle then fovCircle.Visible = false end
        lockedTarget = nil
    end
end)

createToggle("Aimbot Lock + Shoot", settings.aimbot, function(enabled)
    settings.aimbot = enabled
    saveSettings()
    if enabled then
        settings.aimbotLock = false
        settings.autoShoot = true
        notify("Aimbot", "Lock + Shoot enabled", 2)
        if not fovCircle then
            fovCircle = Drawing.new("Circle")
            fovCircle.Visible = true
            fovCircle.Thickness = 2.5
            fovCircle.Color = Color3.fromRGB(40, 200, 80)
            fovCircle.Transparency = 1
            fovCircle.NumSides = 100
            fovCircle.Radius = settings.aimbotFOV
            fovCircle.Filled = false
        end
        table.insert(connections, RunService.RenderStepped:Connect(function()
            if settings.aimbot and fovCircle and settings.showFOV then
                local screenSize = camera.ViewportSize
                fovCircle.Position = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
                fovCircle.Radius = settings.aimbotFOV
                fovCircle.Visible = true
            end
        end))
    else
        if fovCircle then fovCircle.Visible = false end
        lockedTarget = nil
    end
end)

createToggle("Trigger Bot", settings.triggerBot, function(enabled)
    settings.triggerBot = enabled
    saveSettings()
end)

createToggle("Show FOV Circle", settings.showFOV, function(enabled)
    settings.showFOV = enabled
    saveSettings()
    if fovCircle then
        fovCircle.Visible = enabled and (settings.aimbot or settings.aimbotLock)
    end
end)

createSlider("FOV Size", 50, 600, settings.aimbotFOV, "px", function(value)
    settings.aimbotFOV = value
    saveSettings()
    if fovCircle then fovCircle.Radius = value end
end)

createSlider("Smoothness", 1, 20, settings.aimbotSmooth, "", function(value)
    settings.aimbotSmooth = value
    saveSettings()
end)

createDivider("Movement")
createToggle("Noclip", settings.noclip, function(enabled)
    settings.noclip = enabled
    saveSettings()
end)

createToggle("Infinite Jump", settings.infiniteJump, function(enabled)
    settings.infiniteJump = enabled
    saveSettings()
end)

createToggle("Speed Hack", settings.speedEnabled, function(enabled)
    settings.speedEnabled = enabled
    saveSettings()
    if enabled then
        notify("Movement", "Speed enabled", 2)
        humanoid.WalkSpeed = settings.walkSpeed
    else
        humanoid.WalkSpeed = originalValues.walkSpeed
    end
end)

createSlider("Walk Speed", 16, 500, settings.walkSpeed, "", function(value)
    settings.walkSpeed = value
    saveSettings()
    if settings.speedEnabled and humanoid then
        humanoid.WalkSpeed = value
    end
end)

createToggle("Fly", settings.fly, function(enabled)
    settings.fly = enabled
    saveSettings()
    if enabled then
        notify("Movement", "Flight enabled", 2)
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.zero
        bv.Parent = rootpart
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.P = 10000
        bg.D = 500
        bg.Parent = rootpart
        flyConnection = RunService.Heartbeat:Connect(function()
            if not settings.fly then return end
            local cam = camera
            local moveDir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
            if moveDir.Magnitude > 0 then
                bv.Velocity = moveDir.Unit * settings.flySpeed
            else
                bv.Velocity = Vector3.zero
            end
            bg.CFrame = cam.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        if rootpart:FindFirstChild("BodyVelocity") then rootpart.BodyVelocity:Destroy() end
        if rootpart:FindFirstChild("BodyGyro") then rootpart.BodyGyro:Destroy() end
    end
end)

createSlider("Fly Speed", 10, 500, settings.flySpeed, "", function(value)
    settings.flySpeed = value
    saveSettings()
end)

createSlider("Jump Power", 50, 500, settings.jumpPower, "", function(value)
    settings.jumpPower = value
    saveSettings()
    if humanoid then humanoid.JumpPower = value end
end)

createDivider("Visuals")
createToggle("FullBright", settings.fullbright, function(enabled)
    settings.fullbright = enabled
    saveSettings()
    local lighting = game:GetService("Lighting")
    if enabled then
        notify("Visuals", "FullBright enabled", 2)
        lighting.Brightness = 2
        lighting.ClockTime = 14
        lighting.FogEnd = 100000
        lighting.GlobalShadows = false
        lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        lighting.Brightness = 1
        lighting.ClockTime = 12
        lighting.FogEnd = 100000
        lighting.GlobalShadows = true
    end
end)

createToggle("No Fog", settings.noFog, function(enabled)
    settings.noFog = enabled
    saveSettings()
    local lighting = game:GetService("Lighting")
    if enabled then
        lighting.FogEnd = 100000
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v.Density = 0 end
        end
    else
        lighting.FogEnd = 500
    end
end)

createToggle("FOV Changer", settings.fovChanger, function(enabled)
    settings.fovChanger = enabled
    saveSettings()
    if enabled then
        camera.FieldOfView = settings.fovValue
    else
        camera.FieldOfView = originalValues.fov
    end
end)

createSlider("FOV Value", 70, 120, settings.fovValue, "°", function(value)
    settings.fovValue = value
    saveSettings()
    if settings.fovChanger then camera.FieldOfView = value end
end)

createToggle("Force Third Person", settings.thirdPerson, function(enabled)
    settings.thirdPerson = enabled
    saveSettings()
    if enabled then
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 5
    else
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 0.5
    end
end)

createDivider("Misc")
createToggle("Anti-AFK", settings.antiAFK, function(enabled)
    settings.antiAFK = enabled
    saveSettings()
    if enabled then
        table.insert(connections, RunService.Heartbeat:Connect(function()
            if settings.antiAFK then
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end
        end))
    end
end)

createToggle("Spinbot", settings.spinbot, function(enabled)
    settings.spinbot = enabled
    saveSettings()
end)

createSlider("Spin Speed", 1, 50, settings.spinSpeed, "", function(value)
    settings.spinSpeed = value
    saveSettings()
end)

createDivider("Actions")
createButton("🔓 Unlock All Items", function()
    notify("Unlock All", "Attempting...", 2)
    task.spawn(function()
        local success = 0
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local possibleEvents = {"UnlockItem", "BuyItem", "PurchaseItem", "UnlockWeapon", "UnlockSkin"}
            for _, eventName in pairs(possibleEvents) do
                local event = RS:FindFirstChild(eventName, true)
                if event and event:IsA("RemoteEvent") then
                    local testArgs = {{"all"}, {true}, {999999}}
                    for _, args in pairs(testArgs) do
                        pcall(function() event:FireServer(unpack(args)) success = success + 1 end)
                    end
                end
            end
        end)
        if success > 0 then
            notify("Unlock All", "Success!", 2)
        else
            notify("Unlock All", "Failed", 2)
        end
    end)
end)

createButton("🔫 Give All Weapons", function()
    notify("Weapons", "Attempting...", 2)
    task.spawn(function()
        local count = 0
        pcall(function()
            local RS = game:GetService("ReplicatedStorage")
            local weapons = RS:FindFirstChild("Weapons") or RS:FindFirstChild("Tools")
            if weapons then
                for _, weapon in pairs(weapons:GetChildren()) do
                    pcall(function() 
                        local clone = weapon:Clone() 
                        clone.Parent = player.Backpack 
                        count = count + 1 
                    end)
                end
            end
        end)
        if count > 0 then
            notify("Weapons", "Gave " .. count .. " weapons!", 2)
        else
            notify("Weapons", "No weapons found", 2)
        end
    end)
end)

createButton("💰 Max Money", function()
    notify("Money", "Attempting...", 2)
    task.spawn(function()
        local count = 0
        pcall(function()
            if player:FindFirstChild("leaderstats") then
                for _, stat in pairs(player.leaderstats:GetChildren()) do
                    if stat:IsA("IntValue") or stat:IsA("NumberValue") then
                        local names = stat.Name:lower()
                        if names:find("money") or names:find("cash") or names:find("coin") then
                            pcall(function() stat.Value = 999999999 count = count + 1 end)
                        end
                    end
                end
            end
        end)
        if count > 0 then
            notify("Money", "Maxed!", 2)
        else
            notify("Money", "Failed", 2)
        end
    end)
end)

-- ========================================
-- FONCTIONS AIMBOT
-- ========================================

local function getClosestPlayerInFOV()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local targetPart = plr.Character:FindFirstChild(settings.targetPart)
            local humanoid = plr.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (screenPos2D - screenCenter).Magnitude
                    if distance <= settings.aimbotFOV and distance < shortestDistance then
                        closestPlayer = plr
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    return closestPlayer
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightClickHeld = true
        if settings.aimbot or settings.aimbotLock then
            lockedTarget = getClosestPlayerInFOV()
        end
    end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightClickHeld = false
        lockedTarget = nil
    end
end))

-- ========================================
-- LOOPS PRINCIPAUX
-- ========================================

table.insert(connections, RunService.RenderStepped:Connect(function()
    if settings.aimbotLock and isRightClickHeld then
        if not lockedTarget or not lockedTarget.Character then
            lockedTarget = getClosestPlayerInFOV()
        end
        if lockedTarget and lockedTarget.Character then
            local targetPart = lockedTarget.Character:FindFirstChild(settings.targetPart)
            local hum = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                local targetPos = targetPart.Position
                local currentCFrame = camera.CFrame
                local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / settings.aimbotSmooth)
            else
                lockedTarget = nil
            end
        end
    end
    if settings.aimbot and isRightClickHeld then
        if not lockedTarget or not lockedTarget.Character then
            lockedTarget = getClosestPlayerInFOV()
        end
        if lockedTarget and lockedTarget.Character then
            local targetPart = lockedTarget.Character:FindFirstChild(settings.targetPart)
            local hum = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                local targetPos = targetPart.Position
                local currentCFrame = camera.CFrame
                local targetCFrame = CFrame.new(currentCFrame.Position, targetPos)
                camera.CFrame = currentCFrame:Lerp(targetCFrame, 1 / settings.aimbotSmooth)
                if settings.autoShoot then
                    pcall(function() mouse1click() end)
                end
            else
                lockedTarget = nil
            end
        end
    end
    if settings.triggerBot then
        local mouseTarget = player:GetMouse().Target
        if mouseTarget then
            local targetPlayer = Players:GetPlayerFromCharacter(mouseTarget.Parent)
            if targetPlayer and targetPlayer ~= player then
                pcall(function() mouse1click() end)
            end
        end
    end
end))

table.insert(connections, RunService.Stepped:Connect(function()
    if settings.noclip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end))

table.insert(connections, UserInputService.JumpRequest:Connect(function()
    if settings.infiniteJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

table.insert(connections, RunService.Heartbeat:Connect(function()
    if settings.speedEnabled and humanoid then
        humanoid.WalkSpeed = settings.walkSpeed
    end
end))

local spinAngle = 0
table.insert(connections, RunService.RenderStepped:Connect(function()
    if settings.spinbot and rootpart then
        spinAngle = spinAngle + settings.spinSpeed
        rootpart.CFrame = rootpart.CFrame * CFrame.Angles(0, math.rad(spinAngle), 0)
    end
end))

table.insert(connections, player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootpart = char:WaitForChild("HumanoidRootPart")
    originalValues.walkSpeed = humanoid.WalkSpeed
    originalValues.jumpPower = humanoid.JumpPower
end))

-- ========================================
-- CONTRÔLES
-- ========================================

local isMinimized = false

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 600, 0, 55)}):Play()
        MinBtn.Text = "+"
    else
        TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 600, 0, 450)}):Play()
        MinBtn.Text = "─"
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    cleanup()
    saveSettings()
    if fovCircle then fovCircle:Remove() end
    ScreenGui:Destroy()
    notify("Croco Hub", "Closed!", 2)
end)

ScreenGui.Destroying:Connect(function()
    cleanup()
    if fovCircle then fovCircle:Remove() end
end)

-- ========================================
-- NOTIFICATION DE BIENVENUE
-- ========================================

notify("🐊 Croco Hub V4", "Welcome! All features loaded", 3)

print("🐊 CROCO HUB V4 ULTIMATE loaded!")
print("━━━━━━━━━━━━━━━━━━━━━━━━")
print("✨ Interface moderne")
print("✅ Toutes les fonctions V3")
print("💾 Sauvegarde auto")
print("🔔 Notifications")
print("━━━━━━━━━━━━━━━━━━━━━━━━")
