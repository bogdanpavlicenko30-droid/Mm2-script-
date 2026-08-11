--[[
    Murder Mystery 2 — Premium Utility
    made by @quakks
    High quality GUI + ESP + Sheriff tools
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ===================== CONFIG =====================
local Config = {
    -- ESP
    ESPEnabled = false,
    ShowSelf = false,
    ShowMurderer = true,
    ShowSheriff = true,
    ShowInnocent = false,
    ShowGun = true,
    ESPMaxDistance = 500,
    MurdererColor = Color3.fromRGB(255, 50, 50),
    SheriffColor = Color3.fromRGB(50, 120, 255),
    InnocentColor = Color3.fromRGB(80, 220, 100),
    GunColor = Color3.fromRGB(255, 200, 50),

    -- Combat
    AutoShoot = false,
    ShootFOV = 180,
}

local ESPObjects = {}
local Connections = {}
local Started = false
local ShootButton = nil
local GetGunButton = nil

-- ===================== UTILS =====================
local function safeParent(gui)
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function createCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function createStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 130, 255)
    s.Thickness = thickness or 1.2
    s.Transparency = 0.35
    s.Parent = parent
    return s
end

local function tween(obj, props, time, style)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- ===================== ROLE DETECTION =====================
local function getRole(player)
    if not player or not player.Character then return "Unknown" end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")

    -- Knife = Murderer
    if char:FindFirstChild("Knife") or (backpack and backpack:FindFirstChild("Knife")) then
        return "Murderer"
    end
    -- Gun = Sheriff
    if char:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then
        return "Sheriff"
    end

    -- Fallback through values / attributes (common in MM2)
    local roleVal = player:FindFirstChild("Role") or player:FindFirstChild("role") or char:FindFirstChild("Role")
    if roleVal and roleVal:IsA("StringValue") then
        local r = roleVal.Value:lower()
        if r:find("murder") then return "Murderer" end
        if r:find("sheriff") then return "Sheriff" end
        if r:find("innocent") then return "Innocent" end
    end

    return "Innocent"
end

local function isLocalSheriff()
    return getRole(LocalPlayer) == "Sheriff"
end

local function findMurderer()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and getRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            return plr
        end
    end
    return nil
end

local function findDroppedGun()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent == Workspace then
            return obj
        end
        if obj:IsA("BasePart") and obj.Name:lower():find("gun") and obj.Parent == Workspace then
            return obj
        end
    end
    -- Common gun drop locations
    local gun = Workspace:FindFirstChild("GunDrop") or Workspace:FindFirstChild("Gun")
    if gun then return gun end
    return nil
end

-- ===================== ESP SYSTEM =====================
local function clearESP()
    for _, data in pairs(ESPObjects) do
        if data.box then data.box:Destroy() end
        if data.name then data.name:Destroy() end
        if data.tracer then data.tracer:Destroy() end
        if data.highlight then data.highlight:Destroy() end
    end
    table.clear(ESPObjects)
end

local function createESP(player)
    if ESPObjects[player] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "QuakksESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.MaxDistance = Config.ESPMaxDistance

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.4
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.Parent = billboard

    local roleLabel = Instance.new("TextLabel")
    roleLabel.Size = UDim2.new(1, 0, 0, 18)
    roleLabel.Position = UDim2.new(0, 0, 0, 18)
    roleLabel.BackgroundTransparency = 1
    roleLabel.Text = "..."
    roleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    roleLabel.TextStrokeTransparency = 0.5
    roleLabel.Font = Enum.Font.Gotham
    roleLabel.TextSize = 12
    roleLabel.Parent = billboard

    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.2
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    ESPObjects[player] = {
        box = billboard,
        name = nameLabel,
        role = roleLabel,
        highlight = highlight
    }
end

local function updateESP()
    if not Config.ESPEnabled then
        clearESP()
        return
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer and not Config.ShowSelf then
            if ESPObjects[player] then
                if ESPObjects[player].box then ESPObjects[player].box.Enabled = false end
                if ESPObjects[player].highlight then ESPObjects[player].highlight.Enabled = false end
            end
            continue
        end

        local role = getRole(player)
        local show = false
        local color = Config.InnocentColor

        if role == "Murderer" and Config.ShowMurderer then
            show = true
            color = Config.MurdererColor
        elseif role == "Sheriff" and Config.ShowSheriff then
            show = true
            color = Config.SheriffColor
        elseif role == "Innocent" and Config.ShowInnocent then
            show = true
            color = Config.InnocentColor
        end

        if show and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if not ESPObjects[player] then
                createESP(player)
            end
            local data = ESPObjects[player]
            data.box.Adornee = player.Character.HumanoidRootPart
            data.box.Parent = player.Character
            data.box.Enabled = true
            data.name.Text = player.Name
            data.role.Text = role
            data.role.TextColor3 = color
            data.name.TextColor3 = color

            data.highlight.Parent = player.Character
            data.highlight.FillColor = color
            data.highlight.OutlineColor = color
            data.highlight.Enabled = true
        else
            if ESPObjects[player] then
                if ESPObjects[player].box then ESPObjects[player].box.Enabled = false end
                if ESPObjects[player].highlight then ESPObjects[player].highlight.Enabled = false end
            end
        end
    end

    -- Gun ESP
    if Config.ShowGun then
        local gun = findDroppedGun()
        if gun then
            if not ESPObjects["GunDrop"] then
                local bb = Instance.new("BillboardGui")
                bb.Name = "GunESP"
                bb.AlwaysOnTop = true
                bb.Size = UDim2.new(0, 120, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2, 0)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Text = "GUN DROP"
                label.TextColor3 = Config.GunColor
                label.TextStrokeTransparency = 0.3
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.Parent = bb

                ESPObjects["GunDrop"] = {box = bb, label = label}
            end
            local data = ESPObjects["GunDrop"]
            data.box.Adornee = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
            data.box.Parent = gun
            data.box.Enabled = true
        else
            if ESPObjects["GunDrop"] and ESPObjects["GunDrop"].box then
                ESPObjects["GunDrop"].box.Enabled = false
            end
        end
    end
end

-- ===================== COMBAT =====================
local function shootMurderer()
    if not isLocalSheriff() then return end
    local murderer = findMurderer()
    if not murderer or not murderer.Character then return end
    local root = murderer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Equip gun if needed
    local char = LocalPlayer.Character
    if not char then return end
    local gun = char:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun"))
    if gun and gun.Parent == LocalPlayer.Backpack then
        gun.Parent = char
        task.wait(0.05)
    end

    -- Aim + shoot
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)

    pcall(function()
        -- Common MM2 shoot methods
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        for _, r in ipairs(remotes:GetDescendants()) do
            if r:IsA("RemoteEvent") then
                local n = r.Name:lower()
                if n:find("shoot") or n:find("fire") or n:find("gun") then
                    r:FireServer(root.Position)
                    break
                end
            end
        end
    end)

    -- Fallback key / mouse
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

local function getGunDrop()
    local gun = findDroppedGun()
    if not gun then return end

    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    -- Instant pickup attempts
    pcall(function()
        local handle = gun:IsA("Tool") and gun:FindFirstChild("Handle") or gun
        if handle then
            firetouchinterest(char.HumanoidRootPart, handle, 0)
            task.wait(0.03)
            firetouchinterest(char.HumanoidRootPart, handle, 1)
        end
    end)

    pcall(function()
        if gun:IsA("Tool") then
            gun.Parent = LocalPlayer.Backpack
        end
    end)

    -- Remote fallback
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
        for _, r in ipairs(remotes:GetDescendants()) do
            if r:IsA("RemoteEvent") and (r.Name:lower():find("gun") or r.Name:lower():find("pick")) then
                r:FireServer()
                break
            end
        end
    end)
end

-- ===================== MOBILE FIXED BUTTONS =====================
local function createFixedButton(text, position, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 90, 0, 90)
    btn.Position = position
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    btn.BackgroundTransparency = 0.15
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    btn.TextWrapped = true
    btn.ZIndex = 50
    btn.Parent = ScreenGui
    createCorner(btn, 12)
    createStroke(btn, Color3.fromRGB(60, 140, 255), 1.5)

    -- Important: prevent mobile movement interference
    btn.Active = true
    btn.Selectable = false

    local pressing = false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            pressing = true
            tween(btn, {BackgroundColor3 = Color3.fromRGB(45, 110, 255)}, 0.1)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if pressing then
                pressing = false
                tween(btn, {BackgroundColor3 = Color3.fromRGB(25, 25, 40)}, 0.15)
                callback()
            end
        end
    end)

    return btn
end

local function updateCombatButtons()
    if Config.AutoShoot and isLocalSheriff() then
        if not ShootButton then
            -- Fixed position (right side, middle) — does not follow joystick
            ShootButton = createFixedButton("SHOOT", UDim2.new(0.82, 0, 0.55, 0), shootMurderer)
        end
        ShootButton.Visible = true
    else
        if ShootButton then
            ShootButton.Visible = false
        end
    end

    if not GetGunButton then
        GetGunButton = createFixedButton("GET GUN", UDim2.new(0.82, 0, 0.72, 0), getGunDrop)
    end
    GetGunButton.Visible = true
end

-- ===================== GUI =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "QuakksMM2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 380, 0, 460)
Main.Position = UDim2.new(0.5, -190, 0.5, -230)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
createCorner(Main, 14)
createStroke(Main, Color3.fromRGB(55, 120, 255), 1.4)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
Header.BorderSizePixel = 0
Header.Parent = Main
createCorner(Header, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 0, 24)
Title.Position = UDim2.new(0, 18, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "made by @quakks"
Title.TextColor3 = Color3.fromRGB(170, 195, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Sub = Instance.new("TextLabel")
Sub.Size = UDim2.new(1, -80, 0, 16)
Sub.Position = UDim2.new(0, 18, 0, 28)
Sub.BackgroundTransparency = 1
Sub.Text = "Murder Mystery 2"
Sub.TextColor3 = Color3.fromRGB(90, 140, 255)
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 12
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(220, 90, 90)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = Header
createCorner(CloseBtn, 7)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -76, 0, 11)
MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(180, 190, 210)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = Header
createCorner(MinBtn, 7)

-- Start Button
local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 200, 0, 46)
StartBtn.Position = UDim2.new(0.5, -100, 0.5, -23)
StartBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 255)
StartBtn.Text = "НАЧАТЬ"
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 17
StartBtn.Parent = Main
createCorner(StartBtn, 10)

-- Tabs
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -24, 0, 36)
TabBar.Position = UDim2.new(0, 12, 0, 62)
TabBar.BackgroundTransparency = 1
TabBar.Visible = false
TabBar.Parent = Main

local Tabs = {}
local CurrentTab = "ESP"
local TabContents = {}

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(160, 170, 200)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.Parent = TabBar
    createCorner(btn, 8)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -24, 1, -115)
    content.Position = UDim2.new(0, 12, 0, 105)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(60, 120, 255)
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 400)
    content.Visible = false
    content.Parent = Main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    Tabs[name] = btn
    TabContents[name] = content

    btn.MouseButton1Click:Connect(function()
        CurrentTab = name
        for n, b in pairs(Tabs) do
            tween(b, {BackgroundColor3 = n == name and Color3.fromRGB(45, 110, 255) or Color3.fromRGB(22, 22, 32)}, 0.2)
            b.TextColor3 = n == name and Color3.new(1, 1, 1) or Color3.fromRGB(160, 170, 200)
        end
        for n, c in pairs(TabContents) do
            c.Visible = (n == name)
        end
    end)

    return content
end

local ESPTab = createTab("ESP")
local CombatTab = createTab("Combat")
local SettingsTab = createTab("Settings")

-- Layout tabs
Tabs["ESP"].Position = UDim2.new(0, 0, 0, 0)
Tabs["Combat"].Position = UDim2.new(0, 118, 0, 0)
Tabs["Settings"].Position = UDim2.new(0, 236, 0, 0)

-- Toggle creator
local function addToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.Parent = parent
    createCorner(frame, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(210, 215, 235)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BackgroundColor3 = default and Color3.fromRGB(45, 120, 255) or Color3.fromRGB(40, 40, 55)
    btn.Text = ""
    btn.Parent = frame
    createCorner(btn, 11)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.Parent = btn
    createCorner(circle, 8)

    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(btn, {BackgroundColor3 = state and Color3.fromRGB(45, 120, 255) or Color3.fromRGB(40, 40, 55)}, 0.18)
        tween(circle, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.18)
        callback(state)
    end)
end

local function addSlider(parent, text, min, max, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 50)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.Parent = parent
    createCorner(frame, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 18)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(210, 215, 235)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -28, 0, 5)
    bar.Position = UDim2.new(0, 14, 0, 32)
    bar.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    bar.Parent = frame
    createCorner(bar, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(45, 120, 255)
    fill.Parent = bar
    createCorner(fill, 3)

    local dragging = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            label.Text = text .. ": " .. val
            callback(val)
        end
    end)
end

-- ESP Tab content
addToggle(ESPTab, "Enable ESP", false, function(v) Config.ESPEnabled = v end)
addToggle(ESPTab, "Show Myself", false, function(v) Config.ShowSelf = v end)
addToggle(ESPTab, "Show Murderer", true, function(v) Config.ShowMurderer = v end)
addToggle(ESPTab, "Show Sheriff", true, function(v) Config.ShowSheriff = v end)
addToggle(ESPTab, "Show Innocent", false, function(v) Config.ShowInnocent = v end)
addToggle(ESPTab, "Show Dropped Gun", true, function(v) Config.ShowGun = v end)
addSlider(ESPTab, "Max Distance", 100, 1000, 500, function(v) Config.ESPMaxDistance = v end)

-- Combat Tab
addToggle(CombatTab, "Auto Shoot (Sheriff)", false, function(v)
    Config.AutoShoot = v
    updateCombatButtons()
end)
addSlider(CombatTab, "Shoot FOV", 60, 300, 180, function(v) Config.ShootFOV = v end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 0, 60)
info.BackgroundTransparency = 1
info.Text = "Когда Auto Shoot включен —\nна экране появится кнопка SHOOT.\nОна зафиксирована и не ездит\nвместе с джойстиком."
info.TextColor3 = Color3.fromRGB(140, 150, 180)
info.Font = Enum.Font.Gotham
info.TextSize = 12
info.TextWrapped = true
info.Parent = CombatTab

-- Settings
addToggle(SettingsTab, "RightShift — скрыть GUI", true, function() end)

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(1, 0, 0, 40)
credit.BackgroundTransparency = 1
credit.Text = "made by @quakks\nPremium MM2 Utility"
credit.TextColor3 = Color3.fromRGB(100, 120, 180)
credit.Font = Enum.Font.Gotham
credit.TextSize = 12
credit.Parent = SettingsTab

-- Start logic
StartBtn.MouseButton1Click:Connect(function()
    Started = true
    StartBtn:Destroy()
    TabBar.Visible = true
    TabContents["ESP"].Visible = true
    Tabs["ESP"].BackgroundColor3 = Color3.fromRGB(45, 110, 255)
    Tabs["ESP"].TextColor3 = Color3.new(1, 1, 1)
    Title.Text = "Murder Mystery 2"
    Sub.Text = "made by @quakks"
    updateCombatButtons()
end)

-- Minimize
local minimized = false
local fullSize = Main.Size
MinBtn.MouseButton1Click:Connect(function()
    if not Started then return end
    minimized = not minimized
    if minimized then
        tween(Main, {Size = UDim2.new(0, 380, 0, 52)}, 0.25)
        TabBar.Visible = false
        for _, c in pairs(TabContents) do c.Visible = false end
        MinBtn.Text = "+"
    else
        tween(Main, {Size = fullSize}, 0.25)
        TabBar.Visible = true
        TabContents[CurrentTab].Visible = true
        MinBtn.Text = "–"
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    if not Started then return end
    updateESP()
    updateCombatButtons()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

print("[@quakks] MM2 Premium loaded")
