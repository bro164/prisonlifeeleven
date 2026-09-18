local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

for _, oldGui in ipairs(LocalPlayer:WaitForChild("PlayerGui"):GetChildren()) do
    if oldGui.Name == "NeverlosePrisonEn" then oldGui:Destroy() end
end

local Settings = {
    MenuKey = Enum.KeyCode.M,       
    AimKey = Enum.KeyCode.Q,        
    AimEnabled = true,
    FovRadius = 150,                
    Smoothing = 0.20,               
    TargetPart = "Head",
    MaxTracers = 20,
    TracerThickness = 0.05,
    CurrentTab = "Aimbot",
    
    Colors = {
        Guards = Color3.fromRGB(0, 120, 255),
        Inmates = Color3.fromRGB(255, 130, 0),
        Criminals = Color3.fromRGB(255, 10, 50)
    }
}

local isMenuOpen = true
local isAimActive = false
local isBindingAim = false
local isBindingMenu = false

local TargetsCache = {} 
local Tracers = {}

local function createBeamTracer(player, targetPart)
    if Tracers[player] then return end
    
    local beam = Instance.new("Beam")
    local attachment0 = Instance.new("Attachment")
    local attachment1 = Instance.new("Attachment")
    
    attachment0.Name = "TStart"
    attachment1.Name = "TEnd"
    
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        attachment0.Parent = LocalPlayer.Character.HumanoidRootPart
    else
        attachment0.Parent = workspace.Terrain
    end
    attachment1.Parent = targetPart
    
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Width0 = Settings.TracerThickness
    beam.Width1 = Settings.TracerThickness
    beam.FaceCamera = true
    beam.Transparency = NumberSequence.new(0.2)
    beam.Parent = workspace.Terrain
    
    Tracers[player] = {Beam = beam, A0 = attachment0, A1 = attachment1}
end

local function removeTracer(player)
    if Tracers[player] then
        if Tracers[player].Beam then Tracers[player].Beam:Destroy() end
        if Tracers[player].A0 then Tracers[player].A0:Destroy() end
        if Tracers[player].A1 then Tracers[player].A1:Destroy() end
        Tracers[player] = nil
    end
end

local function applyNeverloseShaders()
    Lighting.FogEnd = 600
    Lighting.FogStart = 30
    Lighting.FogColor = Color3.fromRGB(12, 16, 28)
    
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Sky") then obj:Destroy() end
    end
    Lighting.ClockTime = 0 
end
pcall(applyNeverloseShaders)

local function isVisible(targetPart, targetCharacter)
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Head") then 
        return false 
    end
    local startPos = Camera.CFrame.Position
    local direction = targetPart.Position - startPos
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, targetCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local raycastResult = workspace:Raycast(startPos, direction, raycastParams)
    if not raycastResult then return true end
    
    if raycastResult.Instance and raycastResult.Instance:IsA("BasePart") and raycastResult.Instance.Anchored == false then
        return true
    end
    return false
end

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
            if player.Character:FindFirstChildOfClass("Tool") then return true end
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

local function getClosestPlayerInFov()
    local closestTarget = nil
    local shortestDistance = math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = LocalPlayer.Character.HumanoidRootPart.Position

    for i = 1, #TargetsCache do
        local player = TargetsCache[i]
        if player and player.Character and player.Character:FindFirstChild(Settings.TargetPart) then
            local targetPart = player.Character[Settings.TargetPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            
            if onScreen then
                local mousePosition = Vector2.new(Mouse.X, Mouse.Y)
                local targetScreenPosition = Vector2.new(screenPos.X, screenPos.Y)
                local fovDistance = (mousePosition - targetScreenPosition).Magnitude

                if fovDistance < Settings.FovRadius then
                    if isVisible(targetPart, player.Character) then
                        local distance3D = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
                        if distance3D < shortestDistance then
                            shortestDistance = distance3D
                            closestTarget = player
                        end
                    end
                end
            end
        end
    end
    return closestTarget
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NeverlosePrisonEn"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 360)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -180)
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
LogoLabel.Size = UDim2.new(1, 0, 0, 45)
LogoLabel.BackgroundTransparency = 1
LogoLabel.Text = "NEVERLOSE.CC"
LogoLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
LogoLabel.Font = Enum.Font.GothamBold
LogoLabel.TextSize = 13
LogoLabel.Parent = Sidebar

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 1, -50)
TabContainer.Position = UDim2.new(0, 0, 0, 50)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = TabContainer

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -150, 1, -20)
ContentFrame.Position = UDim2.new(0, 140, 0, 10)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Parent = MainFrame

local AimbotPage = Instance.new("Frame")
AimbotPage.Size = UDim2.new(1, 0, 1, 0)
AimbotPage.BackgroundTransparency = 1
AimbotPage.Visible = true
AimbotPage.Parent = ContentFrame

local VisualsPage = Instance.new("Frame")
VisualsPage.Size = UDim2.new(1, 0, 1, 0)
VisualsPage.BackgroundTransparency = 1
VisualsPage.Visible = false
VisualsPage.Parent = ContentFrame

local KeybindsPage = Instance.new("Frame")
KeybindsPage.Size = UDim2.new(1, 0, 1, 0)
KeybindsPage.BackgroundTransparency = 1
KeybindsPage.Visible = false
KeybindsPage.Parent = ContentFrame

local AimGrid = Instance.new("Frame")
AimGrid.Size = UDim2.new(1, 0, 0, 150)
AimGrid.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
AimGrid.Parent = AimbotPage

local GridCorner1 = Instance.new("UICorner")
GridCorner1.CornerRadius = UDim.new(0, 6)
GridCorner1.Parent = AimGrid

local GridStroke1 = Instance.new("UIStroke")
GridStroke1.Color = Color3.fromRGB(25, 27, 38)
GridStroke1.Parent = AimGrid

local AimTitle = Instance.new("TextLabel")
AimTitle.Size = UDim2.new(1, 0, 0, 30)
AimTitle.Position = UDim2.new(0, 15, 0, 5)
AimTitle.BackgroundTransparency = 1
AimTitle.Text = "Aimbot Configuration"
AimTitle.TextColor3 = Color3.fromRGB(220, 220, 225)
AimTitle.Font = Enum.Font.GothamBold
AimTitle.TextSize = 12
AimTitle.TextXAlignment = Enum.TextXAlignment.Left
AimTitle.Parent = AimGrid

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0, 200, 0, 30)
StatusLabel.Position = UDim2.new(0, 15, 0, 45)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "AIMBOT: DEACTIVATED"

    StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
    StatusLabel.Font = Enum.Font.GothamSemibold
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = AimGrid

    local FovLabel = Instance.new("TextLabel")
    FovLabel.Size = UDim2.new(0, 200, 0, 20)
    FovLabel.Position = UDim2.new(0, 15, 0, 85)
    FovLabel.BackgroundTransparency = 1
    FovLabel.Text = "FOV Lock Radius: " .. Settings.FovRadius
    FovLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
    FovLabel.Font = Enum.Font.Gotham
    FovLabel.TextSize = 11
    FovLabel.TextXAlignment = Enum.TextXAlignment.Left
    FovLabel.Parent = AimGrid

    local FovBox = Instance.new("TextBox")
    FovBox.Size = UDim2.new(0, 100, 0, 25)
    FovBox.Position = UDim2.new(0, 15, 0, 110)
    FovBox.BackgroundColor3 = Color3.fromRGB(25, 27, 38)
    FovBox.Text = tostring(Settings.FovRadius)
    FovBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    FovBox.Font = Enum.Font.Gotham
    FovBox.TextSize = 11
    FovBox.Parent = AimGrid

    local FovBoxCorner = Instance.new("UICorner")
    FovBoxCorner.CornerRadius = UDim.new(0, 4)
    FovBoxCorner.Parent = FovBox

    FovBox.FocusLost:Connect(function()
        local num = tonumber(FovBox.Text)
        if num then
            Settings.FovRadius = math.clamp(num, 10, 600)
            FovLabel.Text = "FOV Lock Radius: " .. Settings.FovRadius
        else
            FovBox.Text = tostring(Settings.FovRadius)
        end
    end)

    local VisGrid = Instance.new("Frame")
    VisGrid.Size = UDim2.new(1, 0, 0, 160)
    VisGrid.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    VisGrid.Parent = VisualsPage

    local GridCorner2 = Instance.new("UICorner")
    GridCorner2.CornerRadius = UDim.new(0, 6)
    GridCorner2.Parent = VisGrid

    local GridStroke2 = Instance.new("UIStroke")
    GridStroke2.Color = Color3.fromRGB(25, 27, 38)
    GridStroke2.Parent = VisGrid

    local VisTitle = Instance.new("TextLabel")
    VisTitle.Size = UDim2.new(1, 0, 0, 30)
    VisTitle.Position = UDim2.new(0, 15, 0, 5)
    VisTitle.BackgroundTransparency = 1
    VisTitle.Text = "Tracers Settings"
    VisTitle.TextColor3 = Color3.fromRGB(220, 220, 225)
    VisTitle.Font = Enum.Font.GothamBold
    VisTitle.TextSize = 12
    VisTitle.TextXAlignment = Enum.TextXAlignment.Left
    VisTitle.Parent = VisGrid

    local ThickLabel = Instance.new("TextLabel")
    ThickLabel.Size = UDim2.new(0, 200, 0, 20)
    ThickLabel.Position = UDim2.new(0, 15, 0, 40)
    ThickLabel.BackgroundTransparency = 1
    ThickLabel.Text = "Line Thickness: " .. Settings.TracerThickness
    ThickLabel.TextColor3 = Color3.fromRGB(150, 150, 155)
    ThickLabel.Font = Enum.Font.Gotham
    ThickLabel.TextSize = 11
    ThickLabel.TextXAlignment = Enum.TextXAlignment.Left
    ThickLabel.Parent = VisGrid

    local ThickBox = Instance.new("TextBox")
    ThickBox.Size = UDim2.new(0, 100, 0, 25)
    ThickBox.Position = UDim2.new(0, 15, 0, 65)
    ThickBox.BackgroundColor3 = Color3.fromRGB(25, 27, 38)
    ThickBox.Text = tostring(Settings.TracerThickness)
    ThickBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ThickBox.Font = Enum.Font.Gotham
    ThickBox.TextSize = 11
    ThickBox.Parent = VisGrid

    local ThickBoxCorner = Instance.new("UICorner")
    ThickBoxCorner.CornerRadius = UDim.new(0, 4)
    ThickBoxCorner.Parent = ThickBox

    ThickBox.FocusLost:Connect(function()
        local num = tonumber(ThickBox.Text)
        if num then
            Settings.TracerThickness = math.clamp(num, 0.01, 0.5)
            ThickLabel.Text = "Line Thickness: " .. Settings.TracerThickness
            for _, tData in pairs(Tracers) do
                if tData.Beam then
                    tData.Beam.Width0 = Settings.TracerThickness
                    tData.Beam.Width1 = Settings.TracerThickness
                end
            end
        else
            ThickBox.Text = tostring(Settings.TracerThickness)
        end
    end)

    local ColorsLabel = Instance.new("TextLabel")
    ColorsLabel.Size = UDim2.new(0, 200, 0, 20)
    ColorsLabel.Position = UDim2.new(0, 15, 0, 105)
    ColorsLabel.BackgroundTransparency = 1
    ColorsLabel.Text = "Team colors are allocated dynamically"
    ColorsLabel.TextColor3 = Color3.fromRGB(0, 170, 255)
    ColorsLabel.Font = Enum.Font.GothamSemibold
    ColorsLabel.TextSize = 11
    ColorsLabel.TextXAlignment = Enum.TextXAlignment.Left
    ColorsLabel.Parent = VisGrid

    local BindGrid = Instance.new("Frame")
    BindGrid.Size = UDim2.new(1, 0, 0, 150)
    BindGrid.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    BindGrid.Parent = KeybindsPage

    local GridCorner3 = Instance.new("UICorner")
    GridCorner3.CornerRadius = UDim.new(0, 6)
    GridCorner3.Parent = BindGrid

    local GridStroke3 = Instance.new("UIStroke")
    GridStroke3.Color = Color3.fromRGB(25, 27, 38)
    GridStroke3.Parent = BindGrid

    local BindTitle = Instance.new("TextLabel")
    BindTitle.Size = UDim2.new(1, 0, 0, 30)
    BindTitle.Position = UDim2.new(0, 15, 0, 5)
    BindTitle.BackgroundTransparency = 1
    BindTitle.Text = "Keybinds Manager"
    BindTitle.TextColor3 = Color3.fromRGB(220, 220, 225)
    BindTitle.Font = Enum.Font.GothamBold
    BindTitle.TextSize = 12
    BindTitle.TextXAlignment = Enum.TextXAlignment.Left
    BindTitle.Parent = BindGrid

    local BindAimBtn = Instance.new("TextButton")
    BindAimBtn.Size = UDim2.new(0, 160, 0, 30)
    BindAimBtn.Position = UDim2.new(0, 15, 0, 45)
    BindAimBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
    BindAimBtn.Text = "Aim Key: " .. Settings.AimKey.Name
    BindAimBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
    BindAimBtn.Font = Enum.Font.GothamBold
    BindAimBtn.TextSize = 11
    BindAimBtn.Parent = BindGrid

    local BC1 = Instance.new("UICorner")
    BC1.CornerRadius = UDim.new(0, 4)
    BC1.Parent = BindAimBtn

    local BindMenuKeyBtn = Instance.new("TextButton")
    BindMenuKeyBtn.Size = UDim2.new(0, 160, 0, 30)
    BindMenuKeyBtn.Position = UDim2.new(0, 15, 0, 90)
    BindMenuKeyBtn.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
    BindMenuKeyBtn.Text = "Menu Key: " .. Settings.MenuKey.Name
    BindMenuKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
    BindMenuKeyBtn.Font = Enum.Font.GothamBold
    BindMenuKeyBtn.TextSize = 11
    BindMenuKeyBtn.Parent = BindGrid

    local BC2 = Instance.new("UICorner")
    BC2.CornerRadius = UDim.new(0, 4)
    BC2.Parent = BindMenuKeyBtn

    local function createTabButton(name, layoutOrder)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 35)
        btn.BackgroundTransparency = 1
        btn.Text = "  " .. name
        btn.TextColor3 = (Settings.CurrentTab == name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 135)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 11
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = layoutOrder
        btn.Parent = TabContainer
        
        btn.MouseButton1Click:Connect(function()
            Settings.CurrentTab = name
            AimbotPage.Visible = (name == "Aimbot")
            VisualsPage.Visible = (name == "Visuals")
            KeybindsPage.Visible = (name == "Keybinds")
            
            for _, child in ipairs(TabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = (child.Text == "  " .. name) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 135)
                end
            end
        end)
    end

    createTabButton("Aimbot", 1)
    createTabButton("Visuals", 2)
    createTabButton("Keybinds", 3)

    local function toggleMenu(open)
        isMenuOpen = open
        local targetSize = open and UDim2.new(0, 540, 0, 360) or UDim2.new(0, 540, 0, 0)
        local tweenSize = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize})
        tweenSize:Play()
        MainFrame.Visible = true
        if not open then
            task.wait(0.2)
            if not isMenuOpen then MainFrame.Visible = false end
        end
    end

    BindAimBtn.MouseButton1Click:Connect(function()
        isBindingAim = true
        BindAimBtn.Text = "Press key..."
    end)

    BindMenuKeyBtn.MouseButton1Click:Connect(function()
        isBindingMenu = true
        BindMenuKeyBtn.Text = "Press key..."
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if isBindingAim and input.UserInputType == Enum.UserInputType.Keyboard then
            Settings.AimKey = input.KeyCode
            BindAimBtn.Text = "Aim Key: " .. Settings.AimKey.Name
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
                StatusLabel.Text = "STATUS: DEACTIVATED"
                StatusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
            end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if isAimActive and Settings.AimEnabled then
            local target = getClosestPlayerInFov()
            if target and target.Character and target.Character:FindFirstChild(Settings.TargetPart) then
                local targetPosition = target.Character[Settings.TargetPart].Position
            local lookAtCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)
            Camera.CFrame = Camera.CFrame:Lerp(lookAtCFrame, Settings.Smoothing)
        end
    end

    local renderedLines = 0
    for i = 1, #TargetsCache do
        local player = TargetsCache[i]
        if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and renderedLines < Settings.MaxTracers then
            local _, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            
            if onScreen then
                renderedLines = renderedLines + 1
                if not Tracers[player] then
                    createBeamTracer(player, player.Character.HumanoidRootPart)
                end
                
                local data = Tracers[player]
                if data and data.Beam then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        data.A0.Parent = LocalPlayer.Character.HumanoidRootPart
                    else
                        data.A0.Parent = workspace.Terrain
                    end
                    
                    local tName = player.Team and player.Team.Name or ""
                    local chosenColor = Color3.fromRGB(150, 150, 150)
                    if tName == "Guards" then
                        chosenColor = Settings.Colors.Guards
                    elseif tName == "Inmates" then
                        chosenColor = Settings.Colors.Inmates
                    elseif tName == "Criminals" then
                        chosenColor = Settings.Colors.Criminals
                    end
                    
                    data.Beam.Color = ColorSequence.new(chosenColor)
                    data.Beam.Width0 = Settings.TracerThickness
                    data.Beam.Width1 = Settings.TracerThickness
                    data.Beam.Enabled = true
                end
            else
                if Tracers[player] and Tracers[player].Beam then
                    Tracers[player].Beam.Enabled = false
                end
            end
        else
            removeTracer(player)
        end
    end
end)

Players.PlayerRemoving:Connect(removeTracer)
