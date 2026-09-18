-- =====================================================
--    SOLARA FIXED & VERIFIED NEVERLOSE PRISON LIFE
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Чистка старых элементов UI при перезапуске
for _, oldGui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
    if oldGui.Name == "NeverlosePrisonBase" then oldGui:Destroy() end
end

-- ================= GLOBAL CONFIGURATION =================
local Settings = {
    MenuKey = Enum.KeyCode.M,       
    AimKey = Enum.KeyCode.Q,        
    AimEnabled = true,
    FovRadius = 150,                
    Smoothing = 0.20,               
    TargetPart = "Head",
    MaxTracers = 20,                
    
    Colors = {
        Guards = Color3.fromRGB(0, 120, 255),
        Inmates = Color3.fromRGB(255, 130, 0),
        Criminals = Color3.fromRGB(255, 10, 50)
    }
}
-- =======================================================

local isMenuOpen = true
local isAimActive = false
local isBindingAim = false
local isBindingMenu = false

local TargetsCache = {} 
local Tracers = {}

-- ЗАЩИТА: Проверяем, поддерживает ли Solara API рисования прямо сейчас
local FOVCircle = nil
if pcall(function() return Drawing and Drawing.new end) then
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.Color = Color3.fromRGB(80, 80, 90)
    FOVCircle.Filled = false
    FOVCircle.Visible = true
else
    print("[Solara Warning]: Drawing API (FOV Circle) is currently unsupported or disabled.")
end

local function removeTracer(player)
    if Tracers[player] then
        pcall(function() Tracers[player]:Remove() end)
        Tracers[player] = nil
    end
end

-- Применение шейдеров
local function applyNeverloseShaders()
    Lighting.FogEnd = 600
    Lighting.FogStart = 30
    Lighting.FogColor = Color3.fromRGB(12, 16, 28)
    
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    Lighting.ClockTime = 0 
end
pcall(applyNeverloseShaders) -- Заворачиваем в pcall, чтобы не крашило при отсутствии прав

-- Проверка целей
local function checkPlayerStatus(player)
    if not player or not player.Parent or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name or ""
    local targetTeam = player.Team and player.Team.Name or ""
    if myTeam == targetTeam then return false end 
    
    if myTeam == "Guards" then
        if targetTeam == "Criminals" then
            return true
        elseif targetTeam == "Inmates" then
            if player.Character:FindFirstChildOfClass("Tool") then 
                return true 
            end
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos = root.Position
                if pos.X > 600 or pos.X < 50 or pos.Z > 2400 or pos.Z < 2200 then
                    return true 
                end
            end
        end
    else
        if targetTeam == "Guards" then return true end
    end
    return false
end

-- Оптимизированный поток проверки целей (10 раз в секунду)
task.spawn(function()
    while true do
        local tempCache = {}
        local allPlayers = Players:GetPlayers()
        
        for i = 1, #allPlayers do
            local p = allPlayers[i]
            if p ~= LocalPlayer and checkPlayerStatus(p) then
                table.insert(tempCache, p)
            else
                removeTracer(p)
            end
        end
        TargetsCache = tempCache
        task.wait(0.1)
    end
end)

-- Поиск игрока в FOV
local function getClosestPlayerInFov()
    local closestTarget = nil
    local shortestDistance = math.huge

    for i = 1, #TargetsCache do
        local player = TargetsCache[i]
        if player and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character[Settings.TargetPart].Position)
            if onScreen then
                local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
                local targetScreenPosition = Vector2.new(screenPos.X, screenPos.Y)
                local fovDistance = (mousePosition - targetScreenPosition).Magnitude

                if fovDistance < Settings.FovRadius and fovDistance < shortestDistance then
                    shortestDistance = fovDistance
                    closestTarget = player
                end
            end
        end
    end
    return closestTarget
end

-- СОЗДАНИЕ ИНТЕРФЕЙСА (ИСПРАВЛЕНЫ ВСЕ ОПЕЧАТКИ)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeverlosePrisonBase"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 17)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(30, 32, 45)
UIStroke.Thickness = 1.2
UIStroke.Parent = MainFrame

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(7, 8, 12)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 8)
SidebarCorner.Parent = Sidebar

local LogoLabel = Instance.new("TextLabel")
LogoLabel.Size = UDim2.new(1, 0, 0, 40)
LogoLabel.BackgroundTransparency = 1
LogoLabel.Text = "NEVERLOSE.CC"
LogoLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
LogoLabel.Font = Enum.Font.GothamBold
LogoLabel.TextSize = 12
LogoLabel.Parent = Sidebar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -140, 1, -20)
ContentFrame.Position = UDim2.new(0, 140, 0, 10)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local AimGrid = Instance.new("Frame")
AimGrid.Size = UDim2.new(0, 360, 0, 140)
AimGrid.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
AimGrid.Parent = ContentFrame

local GridCorner = Instance.new("UICorner")
GridCorner.CornerRadius = UDim.new(0, 6)
GridCorner.Parent = AimGrid

local GridStroke = Instance.new("UIStroke")
GridStroke.Color = Color3.fromRGB(25, 27, 38)
GridStroke.Parent = AimGrid

local AimTitle = Instance.new("TextLabel")
AimTitle.Size = UDim2.new(1, 0, 0, 25)
AimTitle.Position = UDim2.new(0, 10, 0, 5)
AimTitle.BackgroundTransparency = 1
AimTitle.Text = "Aimbot Settings"
AimTitle.TextColor3 = Color3.fromRGB(200, 200, 205)
AimTitle.Font = Enum.Font.GothamBold
AimTitle.TextSize = 11
AimTitle.TextXAlignment = Enum.TextXAlignment.Left
AimTitle.Parent = AimGrid

-- ИСПРАВЛЕНО: Кнопка бинда аима использует верную переменную
local BindMenuBtn = Instance.new("TextButton")
BindMenuBtn.Size = UDim2.new(0, 160, 0, 28)
BindMenuBtn.Position = UDim2.new(0, 10, 0, 40)
BindMenuBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
BindMenuBtn.Text = "Aim Key: " .. Settings.AimKey.Name
BindMenuBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
BindMenuBtn.Font = Enum.Font.GothamBold
BindMenuBtn.TextSize = 11
BindMenuBtn.Parent = AimGrid

local BtnCorner1 = Instance.new("UICorner")
BtnCorner1.CornerRadius = UDim.new(0, 4)
BtnCorner1.Parent = BindMenuBtn

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 160, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 80)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "STATUS: LOCK READY"
StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
StatusLabel.Font = Enum.Font.GothamSemibold
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = AimGrid

-- ИСПРАВЛЕНО: Кнопка бинда меню использует верную переменную без лишних букв
local BindMenuKeyBtn = Instance.new("TextButton")
BindMenuKeyBtn.Size = UDim2.new(0, 160, 0, 28)
BindMenuKeyBtn.Position = UDim2.new(0, 190, 0, 40)
BindMenuKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
BindMenuKeyBtn.Text = "Menu Key: " .. Settings.MenuKey.Name
BindMenuKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
BindMenuKeyBtn.Font = Enum.Font.GothamBold
BindMenuKeyBtn.TextSize = 11
BindMenuKeyBtn.Parent = AimGrid

local BtnCorner2 = Instance.new("UICorner")
BtnCorner2.CornerRadius = UDim.new(0, 4)
BtnCorner2.Parent = BindMenuKeyBtn

local function toggleMenu(open)
    isMenuOpen = open
    local targetSize = open and UDim2.new(0, 520, 0, 340) or UDim2.new(0, 520, 0, 0)
    local tweenSize = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
    tweenSize:Play()
    MainFrame.Visible = true
    if not open then
        task.wait(0.2)
        if not isMenuOpen then MainFrame.Visible = false end
    end
end

BindMenuBtn.MouseButton1Click:Connect(function()
    isBindingAim = true
    BindMenuBtn.Text = "Press key..."
end)

BindMenuKeyBtn.MouseButton1Click:Connect(function()
    isBindingMenu = true
    BindMenuKeyBtn.Text = "Press key..."
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    
    if isBindingAim and input.UserInputType == Enum.UserInputType.Keyboard then
        Settings.AimKey = input.KeyCode
        BindMenuBtn.Text = "Aim Key: " .. Settings.AimKey.Name
        isBindingAim = false
        return
    end

    if isBindingMenu and input.UserInputType == Enum.UserInputType.Keyboard then
        Settings.MenuKey = input.KeyCode
        BindMenuKeyBtn.Text = "Menu Key: " .. Settings.MenuKey.Name
        isBindingMenu = false
        return
    end

    if input.KeyCode == Settings.MenuKey then
        toggleMenu(not isMenuOpen)
    end

    if Settings.AimEnabled and input.KeyCode == Settings.AimKey then
        isAimActive = not isAimActive
        if isAimActive then
            StatusLabel.Text = "STATUS: AIM BOT ACTIVE"
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        else
            StatusLabel.Text = "STATUS: LOCK READY"
            StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        end
    end
end)

-- ГЛАВНЫЙ ЦИКЛ ОБНОВЛЕНИЯ
RunService.RenderStepped:Connect(function()
    -- Безопасное обновление круга FOV (если поддерживается софтом)
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
    end

    if isAimActive and Settings.AimEnabled then
        local target = getClosestPlayerInFov()
        if target and target.Character and target.Character:FindFirstChild(Settings.TargetPart) then
            local targetPosition = target.Character[Settings.TargetPart].Position
            local lookAtCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(lookAtCFrame, Settings.Smoothing)
        end
    end

    -- Отрисовка трейсеров с защитой Drawing API
    local renderedLines = 0
    for i = 1, #TargetsCache do
        local player = TargetsCache[i]
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and renderedLines < Settings.MaxTracers then
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            
            if onScreen then
                renderedLines = renderedLines + 1
                
                -- Безопасное создание линии
                if not Tracers[player] then
                    local success, newLine = pcall(function() return Drawing.new("Line") end)
                    if success and newLine then
                        newLine.Thickness = 1.5
                        newLine.Transparency = 0.8
                        Tracers[player] = newLine
                    end
                end
                
                local line = Tracers[player]
                if line then
                    line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    line.To = Vector2.new(screenPos.X, screenPos.Y)
                    
                    local tName = player.Team and player.Team.Name or ""
                    if tName == "Guards" then
                        line.Color = Settings.Colors.Guards
                    elseif tName == "Inmates" then
                        line.Color = Settings.Colors.Inmates
                    elseif tName == "Criminals" then
                        line.Color = Settings.Colors.Criminals
                    else
                        line.Color = Color3.fromRGB(150, 150, 150)
                    end
                    line.Visible = true
                end
            else
                removeTracer(player)
            end
        else
            removeTracer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(removeTracer)
