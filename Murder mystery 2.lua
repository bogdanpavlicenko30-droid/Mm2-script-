--[[
    KawasakiHub — Murder Mystery 2
    made by @quakks
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ===================== CONFIG =====================
local Config = {
    ESPEnabled = false,
    ShowMurderer = true,
    ShowSheriff = true,
    ShowInnocent = false,
    ShowGun = true,
    ShowSelf = false,
    NameESP = true,
    BoxESP = false,

    AutoShoot = false,
}

local ESPObjects = {}
local ShootBtn, GetGunBtn
local CurrentTab = "ESP"
local Started = false

-- ===================== HELPERS =====================
local function safeParent(gui)
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 130, 255)
    s.Thickness = thick or 1
    s.Transparency = 0.4
    s.Parent = obj
    return s
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- ===================== ROLE =====================
local function getRole(plr)
    if not plr or not plr.Character then return "Unknown" end
    local char = plr.Character
    local bp = plr:FindFirstChild("Backpack")

    if char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then
        return "Murderer"
    end
    if char:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function isSheriff()
    return getRole(LocalPlayer) == "Sheriff"
end

local function findMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and getRole(p) == "Murderer" then
            local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if root then return p, root end
        end
    end
end

local function findGunDrop()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent == Workspace then
            return obj
        end
    end
    return Workspace:FindFirstChild("Gun") or Workspace:FindFirstChild("GunDrop")
end

-- ===================== ESP =====================
local function clearESP()
    for _, d in pairs(ESPObjects) do
        if d.billboard then d.billboard:Destroy() end
        if d.highlight then d.highlight:Destroy() end
    end
    table.clear(ESPObjects)
end

local function createPlayerESP(plr)
    if ESPObjects[plr] then return end

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 40)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.MaxDistance = 600

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0, 18)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextSize = 13
    name.TextStrokeTransparency = 0.4
    name.Parent = bb

    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0, 16)
    role.Position = UDim2.new(0, 0, 0, 17)
    role.BackgroundTransparency = 1
    role.Font = Enum.Font.Gotham
    role.TextSize = 12
    role.TextStrokeTransparency = 0.5
    role.Parent = bb

    local hl = Instance.new("Highlight")
    hl.FillTransparency = 0.75
    hl.OutlineTransparency = 0.15
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    ESPObjects[plr] = {billboard = bb, name = name, role = role, highlight = hl}
end

local function updateESP()
    if not Config.ESPEnabled then
        clearESP()
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer and not Config.ShowSelf then
            if ESPObjects[plr] then
                ESPObjects[plr].billboard.Enabled = false
                ESPObjects[plr].highlight.Enabled = false
            end
            continue
        end

        local role = getRole(plr)
        local show, color = false, Color3.fromRGB(200, 200, 200)

        if role == "Murderer" and Config.ShowMurderer then
            show, color = true, Color3.fromRGB(255, 60, 60)
        elseif role == "Sheriff" and Config.ShowSheriff then
            show, color = true, Color3.fromRGB(60, 130, 255)
        elseif role == "Innocent" and Config.ShowInnocent then
            show, color = true, Color3.fromRGB(80, 220, 100)
        end

        if show and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if not ESPObjects[plr] then createPlayerESP(plr) end
            local d = ESPObjects[plr]
            d.billboard.Adornee = plr.Character.HumanoidRootPart
            d.billboard.Parent = plr.Character
            d.billboard.Enabled = Config.NameESP
            d.name.Text = plr.Name
            d.name.TextColor3 = color
            d.role.Text = role
            d.role.TextColor3 = color

            d.highlight.Parent = plr.Character
            d.highlight.FillColor = color
            d.highlight.OutlineColor = color
            d.highlight.Enabled = Config.BoxESP or true
        else
            if ESPObjects[plr] then
                ESPObjects[plr].billboard.Enabled = false
                ESPObjects[plr].highlight.Enabled = false
            end
        end
    end

    -- Gun
    if Config.ShowGun then
        local gun = findGunDrop()
        if gun then
            if not ESPObjects["gun"] then
                local bb = Instance.new("BillboardGui")
                bb.Size = UDim2.new(0, 100, 0, 28)
                bb.AlwaysOnTop = true
                bb.StudsOffset = Vector3.new(0, 2, 0)
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = "GUN"
                lbl.TextColor3 = Color3.fromRGB(255, 200, 50)
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 14
                lbl.TextStrokeTransparency = 0.3
                lbl.Parent = bb
                ESPObjects["gun"] = {billboard = bb, label = lbl}
            end
            local d = ESPObjects["gun"]
            d.billboard.Adornee = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
            d.billboard.Parent = gun
            d.billboard.Enabled = true
        elseif ESPObjects["gun"] then
            ESPObjects["gun"].billboard.Enabled = false
        end
    end
end

-- ===================== COMBAT =====================
local function shoot()
    if not isSheriff() then return end
    local murd, root = findMurderer()
    if not root then return end

    local char = LocalPlayer.Character
    if not char then return end

    local gun = char:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun"))
    if gun and gun.Parent == LocalPlayer.Backpack then
        gun.Parent = char
        task.wait(0.06)
    end

    Camera.CFrame = CFrame.new(Camera.CFrame.Position, root.Position)

    pcall(function()
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

    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
        task.wait(0.04)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
    end)
end

local function getGun()
    local gun = findGunDrop()
    if not gun then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    pcall(function()
        local handle = gun:IsA("Tool") and gun:FindFirstChild("Handle") or gun
        if handle then
            firetouchinterest(char.HumanoidRootPart, handle, 0)
            task.wait(0.04)
            firetouchinterest(char.HumanoidRootPart, handle, 1)
        end
    end)
    pcall(function()
        if gun:IsA("Tool") then gun.Parent = LocalPlayer.Backpack end
    end)
end

-- ===================== FIXED BUTTONS (Mobile safe) =====================
local function makeFixedBtn(text, pos, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 86, 0, 86)
    b.Position = pos
    b.AnchorPoint = Vector2.new(0.5, 0.5)
    b.BackgroundColor3 = Color3.fromRGB(20, 20, 32)
    b.BackgroundTransparency = 0.1
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.ZIndex = 100
    b.Parent = ScreenGui
    corner(b, 14)
    stroke(b, Color3.fromRGB(70, 140, 255), 1.6)

    b.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tween(b, {BackgroundColor3 = Color3.fromRGB(50, 120, 255)}, 0.1)
        end
    end)
    b.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tween(b, {BackgroundColor3 = Color3.fromRGB(20, 20, 32)}, 0.15)
            callback()
        end
    end)
    return b
end

local function refreshButtons()
    if Config.AutoShoot and isSheriff() then
        if not ShootBtn then
            ShootBtn = makeFixedBtn("SHOOT", UDim2.new(0.85, 0, 0.52, 0), shoot)
        end
        ShootBtn.Visible = true
    elseif ShootBtn then
        ShootBtn.Visible = false
    end

    if not GetGunBtn then
        GetGunBtn = makeFixedBtn("GET GUN", UDim2.new(0.85, 0, 0.68, 0), getGun)
    end
    GetGunBtn.Visible = true
end

-- ===================== GUI (Kitagawa style) =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KawasakiHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
safeParent(ScreenGui)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 520, 0, 380)
Main.Position = UDim2.new(0.5, -260, 0.5, -190)
Main.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
corner(Main, 12)
stroke(Main, Color3.fromRGB(50, 110, 255), 1.2)

-- Left Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
corner(Sidebar, 12)

local SideMask = Instance.new("Frame")
SideMask.Size = UDim2.new(0, 20, 1, 0)
SideMask.Position = UDim2.new(1, -20, 0, 0)
SideMask.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
SideMask.BorderSizePixel = 0
SideMask.Parent = Sidebar

-- Logo / Title
local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, -16, 0, 40)
Logo.Position = UDim2.new(0, 12, 0, 12)
Logo.BackgroundTransparency = 1
Logo.Text = "KawasakiHub"
Logo.TextColor3 = Color3.fromRGB(220, 230, 255)
Logo.Font = Enum.Font.GothamBold
Logo.TextSize = 16
Logo.TextXAlignment = Enum.TextXAlignment.Left
Logo.Parent = Sidebar

local LogoSub = Instance.new("TextLabel")
LogoSub.Size = UDim2.new(1, -16, 0, 16)
LogoSub.Position = UDim2.new(0, 12, 0, 36)
LogoSub.BackgroundTransparency = 1
LogoSub.Text = "made by @quakks"
LogoSub.TextColor3 = Color3.fromRGB(90, 130, 220)
LogoSub.Font = Enum.Font.Gotham
LogoSub.TextSize = 11
LogoSub.TextXAlignment = Enum.TextXAlignment.Left
LogoSub.Parent = Sidebar

-- Tab buttons
local TabList = Instance.new("Frame")
TabList.Size = UDim2.new(1, -16, 1, -110)
TabList.Position = UDim2.new(0, 8, 0, 60)
TabList.BackgroundTransparency = 1
TabList.Parent = Sidebar

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = TabList

local Tabs = {}
local Contents = {}

local function addTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    btn.Text = "  " .. name
    btn.TextColor3 = Color3.fromRGB(160, 170, 195)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = TabList
    corner(btn, 7)

    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -180, 1, -70)
    content.Position = UDim2.new(0, 172, 0, 58)
    content.BackgroundTransparency = 1
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(60, 120, 255)
    content.BorderSizePixel = 0
    content.CanvasSize = UDim2.new(0, 0, 0, 350)
    content.Visible = false
    content.Parent = Main

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 6)
    lay.Parent = content

    Tabs[name] = btn
    Contents[name] = content

    btn.MouseButton1Click:Connect(function()
        CurrentTab = name
        for n, b in pairs(Tabs) do
            local selected = n == name
            tween(b, {BackgroundColor3 = selected and Color3.fromRGB(35, 90, 220) or Color3.fromRGB(12, 12, 18)}, 0.18)
            b.TextColor3 = selected and Color3.new(1, 1, 1) or Color3.fromRGB(160, 170, 195)
        end
        for n, c in pairs(Contents) do
            c.Visible = (n == name)
        end
    end)

    return content
end

local ESPContent = addTab("ESP")
local CombatContent = addTab("Combat")
local MiscContent = addTab("Misc")

-- Bottom user
local UserFrame = Instance.new("Frame")
UserFrame.Size = UDim2.new(1, -16, 0, 42)
UserFrame.Position = UDim2.new(0, 8, 1, -52)
UserFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
UserFrame.Parent = Sidebar
corner(UserFrame, 8)

local UserName = Instance.new("TextLabel")
UserName.Size = UDim2.new(1, -12, 0, 18)
UserName.Position = UDim2.new(0, 10, 0, 5)
UserName.BackgroundTransparency = 1
UserName.Text = LocalPlayer.Name
UserName.TextColor3 = Color3.fromRGB(210, 215, 235)
UserName.Font = Enum.Font.GothamSemibold
UserName.TextSize = 12
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.Parent = UserFrame

local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -12, 0, 14)
UserSub.Position = UDim2.new(0, 10, 0, 22)
UserSub.BackgroundTransparency = 1
UserSub.Text = "@quakks"
UserSub.TextColor3 = Color3.fromRGB(100, 140, 220)
UserSub.Font = Enum.Font.Gotham
UserSub.TextSize = 11
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.Parent = UserFrame

-- Close
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 28, 0, 28)
Close.Position = UDim2.new(1, -38, 0, 12)
Close.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
Close.Text = "×"
Close.TextColor3 = Color3.fromRGB(220, 90, 90)
Close.Font = Enum.Font.GothamBold
Close.TextSize = 16
Close.Parent = Main
corner(Close, 6)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Header title (right side)
local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(0, 200, 0, 30)
HeaderTitle.Position = UDim2.new(0, 172, 0, 14)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Text = "ESP"
HeaderTitle.TextColor3 = Color3.fromRGB(220, 230, 255)
HeaderTitle.Font = Enum.Font.GothamBold
HeaderTitle.TextSize = 16
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = Main

-- Toggle helper
local function addToggle(parent, text, default, cb)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    f.Parent = parent
    corner(f, 8)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -60, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(210, 215, 235)
    l.Font = Enum.Font.Gotham
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f

    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 42, 0, 22)
    b.Position = UDim2.new(1, -52, 0.5, -11)
    b.BackgroundColor3 = default and Color3.fromRGB(45, 120, 255) or Color3.fromRGB(40, 40, 55)
    b.Text = ""
    b.Parent = f
    corner(b, 11)

    local c = Instance.new("Frame")
    c.Size = UDim2.new(0, 16, 0, 16)
    c.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    c.BackgroundColor3 = Color3.new(1, 1, 1)
    c.Parent = b
    corner(c, 8)

    local state = default
    b.MouseButton1Click:Connect(function()
        state = not state
        tween(b, {BackgroundColor3 = state and Color3.fromRGB(45, 120, 255) or Color3.fromRGB(40, 40, 55)}, 0.15)
        tween(c, {Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}, 0.15)
        cb(state)
    end)
end

-- ESP toggles
addToggle(ESPContent, "Enable ESP", false, function(v) Config.ESPEnabled = v end)
addToggle(ESPContent, "Murderer ESP", true, function(v) Config.ShowMurderer = v end)
addToggle(ESPContent, "Sheriff ESP", true, function(v) Config.ShowSheriff = v end)
addToggle(ESPContent, "Innocent ESP", false, function(v) Config.ShowInnocent = v end)
addToggle(ESPContent, "Name ESP", true, function(v) Config.NameESP = v end)
addToggle(ESPContent, "Box / Highlight", true, function(v) Config.BoxESP = v end)
addToggle(ESPContent, "Drop Gun ESP", true, function(v) Config.ShowGun = v end)
addToggle(ESPContent, "Show Self", false, function(v) Config.ShowSelf = v end)

-- Combat
addToggle(CombatContent, "Auto Shoot (Sheriff)", false, function(v)
    Config.AutoShoot = v
    refreshButtons()
end)

local tip = Instance.new("TextLabel")
tip.Size = UDim2.new(1, -10, 0, 70)
tip.BackgroundTransparency = 1
tip.Text = "Когда включено — справа появится\nкнопка SHOOT.\nОна зафиксирована и не двигается\nвместе с джойстиком."
tip.TextColor3 = Color3.fromRGB(130, 140, 170)
tip.Font = Enum.Font.Gotham
tip.TextSize = 12
tip.TextWrapped = true
tip.TextXAlignment = Enum.TextXAlignment.Left
tip.Parent = CombatContent

-- Misc
addToggle(MiscContent, "RightShift — скрыть меню", true, function() end)

-- Start screen
local StartOverlay = Instance.new("Frame")
StartOverlay.Size = UDim2.new(1, 0, 1, 0)
StartOverlay.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
StartOverlay.Parent = Main
corner(StartOverlay, 12)

local StartTitle = Instance.new("TextLabel")
StartTitle.Size = UDim2.new(1, 0, 0, 30)
StartTitle.Position = UDim2.new(0, 0, 0.35, 0)
StartTitle.BackgroundTransparency = 1
StartTitle.Text = "KawasakiHub"
StartTitle.TextColor3 = Color3.fromRGB(220, 230, 255)
StartTitle.Font = Enum.Font.GothamBold
StartTitle.TextSize = 22
StartTitle.Parent = StartOverlay

local StartSub = Instance.new("TextLabel")
StartSub.Size = UDim2.new(1, 0, 0, 20)
StartSub.Position = UDim2.new(0, 0, 0.35, 32)
StartSub.BackgroundTransparency = 1
StartSub.Text = "made by @quakks"
StartSub.TextColor3 = Color3.fromRGB(90, 130, 220)
StartSub.Font = Enum.Font.Gotham
StartSub.TextSize = 13
StartSub.Parent = StartOverlay

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0, 160, 0, 40)
StartBtn.Position = UDim2.new(0.5, -80, 0.55, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(45, 110, 255)
StartBtn.Text = "НАЧАТЬ"
StartBtn.TextColor3 = Color3.new(1, 1, 1)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 15
StartBtn.Parent = StartOverlay
corner(StartBtn, 8)

StartBtn.MouseButton1Click:Connect(function()
    Started = true
    tween(StartOverlay, {BackgroundTransparency = 1}, 0.3)
    task.delay(0.3, function() StartOverlay:Destroy() end)
    Contents["ESP"].Visible = true
    Tabs["ESP"].BackgroundColor3 = Color3.fromRGB(35, 90, 220)
    Tabs["ESP"].TextColor3 = Color3.new(1, 1, 1)
    HeaderTitle.Text = "ESP"
    refreshButtons()
end)

-- Tab header update
for name, btn in pairs(Tabs) do
    btn.MouseButton1Click:Connect(function()
        HeaderTitle.Text = name
    end)
end

-- Loops
RunService.RenderStepped:Connect(function()
    if not Started then return end
    updateESP()
    refreshButtons()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

print("[KawasakiHub] loaded | made by @quakks")
