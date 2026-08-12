local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
-- ===================== CONFIG =====================
local Config = {
ESPEnabled = true,
ShowMurderer = true,
ShowSheriff = true,
ShowInnocent = false,
ShowGun = true,
ShowSelf = false,
NameESP = true,
BoxESP = true,
AutoShoot = false,
ShowGetGun = false,
}
local ESPObjects = {}
local ShootBtn, GetGunBtn
local CurrentTab = "ESP"
-- ===================== CORE HELPERS =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KawasakiHub_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
local function corner(obj, r)
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, r or 8)
c.Parent = obj
return c
end
local function stroke(obj, color, thick)
local s = Instance.new("UIStroke")
s.Color = color or Color3.fromRGB(50, 110, 220)
s.Thickness = thick or 1
s.Transparency = 0.3
s.Parent = obj
return s
end
local function tween(obj, props, t)
TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end
-- ===================== GAME LOGIC =====================
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
return nil, nil
end
local function findGunDrop()
for _, obj in ipairs(Workspace:GetDescendants()) do
if obj:IsA("Tool") and obj.Name == "Gun" and obj.Parent == Workspace then
return obj
end
end
return Workspace:FindFirstChild("Gun") or Workspace:FindFirstChild("GunDrop")
end
-- ===================== ESP LOGIC =====================
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
local name = Instance.new("TextLabel")
name.Size = UDim2.new(1, 0, 0, 18)
name.BackgroundTransparency = 1
name.Font = Enum.Font.GothamBold
name.TextSize = 13
name.TextStrokeTransparency = 0.5
name.Parent = bb
local role = Instance.new("TextLabel")
role.Size = UDim2.new(1, 0, 0, 16)
role.Position = UDim2.new(0, 0, 0, 17)
role.BackgroundTransparency = 1
role.Font = Enum.Font.Gotham
role.TextSize = 11
role.TextStrokeTransparency = 0.5
role.Parent = bb
local hl = Instance.new("Highlight")
hl.FillTransparency = 0.7
hl.OutlineTransparency = 0.2
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
show, color = true, Color3.fromRGB(255, 55, 55)
elseif role == "Sheriff" and Config.ShowSheriff then
show, color = true, Color3.fromRGB(55, 125, 255)
elseif role == "Innocent" and Config.ShowInnocent then
show, color = true, Color3.fromRGB(50, 220, 90)
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
d.highlight.Enabled = Config.BoxESP
else
if ESPObjects[plr] then
ESPObjects[plr].billboard.Enabled = false
ESPObjects[plr].highlight.Enabled = false
end
end
end
if Config.ShowGun then
local gun = findGunDrop()
if gun then
if not ESPObjects["gun"] then
local bb = Instance.new("BillboardGui")
bb.Size = UDim2.new(0, 120, 0, 30)
bb.AlwaysOnTop = true
bb.StudsOffset = Vector3.new(0, 2, 0)
local lbl = Instance.new("TextLabel")
lbl.Size = UDim2.new(1, 0, 1, 0)
lbl.BackgroundTransparency = 1
lbl.Text = "GUN DROP"
lbl.TextColor3 = Color3.fromRGB(255, 200, 0)
lbl.Font = Enum.Font.GothamBold
lbl.TextSize = 13
lbl.TextStrokeTransparency = 0.4
lbl.Parent = bb
ESPObjects["gun"] = {billboard = bb, label = lbl}
end
local d = ESPObjects["gun"]
local targetPart = gun:IsA("BasePart") and gun or gun:FindFirstChildWhichIsA("BasePart")
if targetPart then
d.billboard.Adornee = targetPart
d.billboard.Parent = gun
d.billboard.Enabled = true
end
elseif ESPObjects["gun"] then
ESPObjects["gun"].billboard.Enabled = false
end
end
end
-- ===================== COMBAT ACTIONS =====================
local function shoot()
local murd, root = findMurderer()
if not root then return end
local char = LocalPlayer.Character
if not char then return end
local gun = char:FindFirstChild("Gun") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Gun"))
if not gun then return end
-- Equip gun instantly
if gun.Parent == LocalPlayer.Backpack then
gun.Parent = char
task.wait(0.02)
end
-- Silent Aim: fire remote directly without VIM or camera manip
pcall(function()
local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage
for _, r in ipairs(remotes:GetDescendants()) do
if r:IsA("RemoteEvent") then
local n = r.Name:lower()
if n:find("shoot") or n:find("fire") or n:find("gun") then
-- MM2 usually takes target position as argument
r:FireServer(root.Position)
break
end
end
end
end)
end
local function getGun()
local gun = findGunDrop()
if not gun then return end
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end
local root = char.HumanoidRootPart
-- Aggressive touch logic: hit every part in the drop model
for _, part in ipairs(gun:GetDescendants()) do
if part:IsA("BasePart") then
pcall(function()
firetouchinterest(root, part, 0)
task.wait(0.01)
firetouchinterest(root, part, 1)
end)
elseif part:IsA("ProximityPrompt") then
pcall(function() fireproximityprompt(part) end)
end
end
-- In case it's a single part, not a model
if gun:IsA("BasePart") then
pcall(function()
firetouchinterest(root, gun, 0)
task.wait(0.01)
firetouchinterest(root, gun, 1)
end)
end
end
-- ===================== FIXED MOBILE BUTTONS =====================
local function createFixedButton(text, pos, callback)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 75, 0, 75)
btn.Position = pos
btn.AnchorPoint = Vector2.new(0.5, 0.5)
btn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
btn.BackgroundTransparency = 0.15
btn.Text = text
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.ZIndex = 1000
btn.Parent = ScreenGui
corner(btn, 16)
stroke(btn, Color3.fromRGB(60, 130, 255), 1.8)
btn.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
tween(btn, {BackgroundColor3 = Color3.fromRGB(45, 110, 240)}, 0.1)
callback()
end
end)
btn.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
tween(btn, {BackgroundColor3 = Color3.fromRGB(18, 18, 26)}, 0.15)
end
end)
return btn
end
ShootBtn = createFixedButton("SHOOT", UDim2.new(0.82, 0, 0.48, 0), shoot)
GetGunBtn = createFixedButton("GET GUN", UDim2.new(0.82, 0, 0.65, 0), getGun)
ShootBtn.Visible = false
GetGunBtn.Visible = false -- Hidden by default now
local function refreshButtons()
ShootBtn.Visible = Config.AutoShoot and isSheriff()
GetGunBtn.Visible = Config.ShowGetGun
end
-- ===================== MAIN GUI (KITAGAWA STYLE) =====================
-- 1. Top Pill Button
local TopPill = Instance.new("TextButton")
TopPill.Size = UDim2.new(0, 160, 0, 32)
TopPill.Position = UDim2.new(0.5, -80, 0, 12)
TopPill.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TopPill.Text = "KawasakiHub"
TopPill.TextColor3 = Color3.fromRGB(220, 230, 255)
TopPill.Font = Enum.Font.GothamBold
TopPill.TextSize = 13
TopPill.ZIndex = 500
TopPill.Parent = ScreenGui
corner(TopPill, 16)
stroke(TopPill, Color3.fromRGB(60, 120, 240), 1.2)
local PillSub = Instance.new("TextLabel")
PillSub.Size = UDim2.new(0, 40, 1, 0)
PillSub.Position = UDim2.new(1, -48, 0, 0)
PillSub.BackgroundTransparency = 1
PillSub.Text = "Hub"
PillSub.TextColor3 = Color3.fromRGB(75, 140, 255)
PillSub.Font = Enum.Font.GothamBold
PillSub.TextSize = 13
PillSub.Parent = TopPill
-- 2. Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 560, 0, 360)
Main.Position = UDim2.new(0.5, -280, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ZIndex = 100
Main.Parent = ScreenGui
corner(Main, 12)
stroke(Main, Color3.fromRGB(35, 35, 50), 1)
TopPill.MouseButton1Click:Connect(function()
Main.Visible = not Main.Visible
end)
-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 150, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main
corner(Sidebar, 12)
local LogoTitle = Instance.new("TextLabel")
LogoTitle.Size = UDim2.new(1, -16, 0, 30)
LogoTitle.Position = UDim2.new(0, 12, 0, 12)
LogoTitle.BackgroundTransparency = 1
LogoTitle.Text = "KawasakiHub"
LogoTitle.TextColor3 = Color3.fromRGB(220, 230, 255)
LogoTitle.Font = Enum.Font.GothamBold
LogoTitle.TextSize = 15
LogoTitle.TextXAlignment = Enum.TextXAlignment.Left
LogoTitle.Parent = Sidebar
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -16, 1, -110)
TabContainer.Position = UDim2.new(0, 8, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar
local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = TabContainer
local UserCard = Instance.new("Frame")
UserCard.Size = UDim2.new(1, -16, 0, 42)
UserCard.Position = UDim2.new(0, 8, 1, -50)
UserCard.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
UserCard.Parent = Sidebar
corner(UserCard, 8)
local UserName = Instance.new("TextLabel")
UserName.Size = UDim2.new(1, -10, 0, 16)
UserName.Position = UDim2.new(0, 8, 0, 6)
UserName.BackgroundTransparency = 1
UserName.Text = LocalPlayer.Name
UserName.TextColor3 = Color3.fromRGB(210, 220, 240)
UserName.Font = Enum.Font.GothamBold
UserName.TextSize = 11
UserName.TextXAlignment = Enum.TextXAlignment.Left
UserName.Parent = UserCard
local UserSub = Instance.new("TextLabel")
UserSub.Size = UDim2.new(1, -10, 0, 14)
UserSub.Position = UDim2.new(0, 8, 0, 22)
UserSub.BackgroundTransparency = 1
UserSub.Text = "@Kawasaki"
UserSub.TextColor3 = Color3.fromRGB(80, 120, 200)
UserSub.Font = Enum.Font.Gotham
UserSub.TextSize = 10
UserSub.TextXAlignment = Enum.TextXAlignment.Left
UserSub.Parent = UserCard
-- Content Areas
local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -160, 1, -20)
ContentArea.Position = UDim2.new(0, 155, 0, 10)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = Main
local Tabs = {}
local Pages = {}
local function createTab(name)
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, 0, 0, 32)
btn.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
btn.Text = "  " .. name
btn.TextColor3 = Color3.fromRGB(140, 150, 175)
btn.Font = Enum.Font.GothamSemibold
btn.TextSize = 12
btn.TextXAlignment = Enum.TextXAlignment.Left
btn.Parent = TabContainer
corner(btn, 6)
local page = Instance.new("ScrollingFrame")
page.Size = UDim2.new(1, 0, 1, 0)
page.BackgroundTransparency = 1
page.ScrollBarThickness = 2
page.ScrollBarImageColor3 = Color3.fromRGB(60, 120, 240)
page.Visible = false
page.Parent = ContentArea
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 6)
lay.Parent = page
Tabs[name] = btn
Pages[name] = page
btn.MouseButton1Click:Connect(function()
for n, b in pairs(Tabs) do
local sel = (n == name)
tween(b, {BackgroundColor3 = sel and Color3.fromRGB(28, 28, 40) or Color3.fromRGB(10, 10, 15)}, 0.12)
b.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 150, 175)
end
for n, p in pairs(Pages) do
p.Visible = (n == name)
end
end)
return page
end
local ESPPage = createTab("ESP")
local CombatPage = createTab("Combat")
local MiscPage = createTab("Misc")
-- Toggle Generator
local function addToggle(parent, title, default, callback)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, -10, 0, 38)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
frame.Parent = parent
corner(frame, 8)
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -60, 1, 0)
label.Position = UDim2.new(0, 12, 0, 0)
label.BackgroundTransparency = 1
label.Text = title
label.TextColor3 = Color3.fromRGB(210, 220, 240)
label.Font = Enum.Font.Gotham
label.TextSize = 12
label.TextXAlignment = Enum.TextXAlignment.Left
label.Parent = frame
local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0, 38, 0, 20)
btn.Position = UDim2.new(1, -48, 0.5, -10)
btn.BackgroundColor3 = default and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(35, 35, 48)
btn.Text = ""
btn.Parent = frame
corner(btn, 10)
local circle = Instance.new("Frame")
circle.Size = UDim2.new(0, 14, 0, 14)
circle.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
circle.Parent = btn
corner(circle, 7)
local state = default
btn.MouseButton1Click:Connect(function()
state = not state
tween(btn, {BackgroundColor3 = state and Color3.fromRGB(50, 120, 255) or Color3.fromRGB(35, 35, 48)}, 0.12)
tween(circle, {Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)}, 0.12)
callback(state)
end)
end
-- Toggles Setup
addToggle(ESPPage, "Enable ESP", true, function(v) Config.ESPEnabled = v end)
addToggle(ESPPage, "Murderer ESP", true, function(v) Config.ShowMurderer = v end)
addToggle(ESPPage, "Sheriff ESP", true, function(v) Config.ShowSheriff = v end)
addToggle(ESPPage, "Innocent ESP", false, function(v) Config.ShowInnocent = v end)
addToggle(ESPPage, "Name ESP", true, function(v) Config.NameESP = v end)
addToggle(ESPPage, "3D Box / Highlight", true, function(v) Config.BoxESP = v end)
addToggle(ESPPage, "Drop Gun ESP", true, function(v) Config.ShowGun = v end)
addToggle(CombatPage, "Auto Shoot (Sheriff)", false, function(v)
Config.AutoShoot = v
refreshButtons()
end)
addToggle(CombatPage, "Show 'Get Gun' Button", false, function(v)
Config.ShowGetGun = v
refreshButtons()
end)
-- Default Tab Setup
Pages["ESP"].Visible = true
Tabs["ESP"].BackgroundColor3 = Color3.fromRGB(28, 28, 40)
Tabs["ESP"].TextColor3 = Color3.fromRGB(255, 255, 255)
-- Main Loop
RunService.RenderStepped:Connect(function()
updateESP()
refreshButtons()
end)
