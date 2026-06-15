-- ============================================
-- HITBOX EXTENDER PLUGIN - MOBILE OTIMIZADO
-- ============================================

if getgenv().HitboxPluginLoaded ~= nil then
    return
end
getgenv().HitboxPluginLoaded = false

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not getgenv().MTAPIMutex then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RectangularObject/MT-Api-v2/main/__source/mt-api%20v2.lua", true))()
    end)
end

local Settings = {
    Enabled = false,
    Size = 10,
    Transparency = 0.5,
    BodyParts = {"HumanoidRootPart"},
    CustomPartName = "HeadHB",
    SitCheck = true,
    FFCheck = true,
    IgnoreOwnTeam = true,
    IgnorePlayers = {},
    IgnoreTeams = {},
    CollisionsEnabled = false
}

local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local lPlayer = Players.LocalPlayer
local players = {}
local teamModule = nil

local function updatePlayers()
    if not getgenv().HitboxPluginLoaded then return end
    if not Settings.Enabled then return end
    for _, v in pairs(players) do
        task.spawn(function()
            pcall(v.Update, v)
        end)
    end
end

pcall(function()
    if game.GameId == 504234221 then
        teamModule = require(ReplicatedStorage.Scripts.Modules.PlayerModule)
    end
    if game.GameId == 1934496708 then
        teamModule = require(Workspace:WaitForChild("Teams"))
    end
end)

local function addPlayer(player)
    players[player] = {}
    local playerIdx = players[player]
    local playerChar = player.Character
    local defaultProperties = {}

    local function isTeammate()
        if game.GameId == 718936923 then
            if not lPlayer.Character or not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return true end
            return lPlayer.Character.HumanoidRootPart.Color == playerChar.HumanoidRootPart.Color
        elseif game.PlaceId == 633284182 then
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("TeamValue") then return true end
            return lPlayer.PlayerData.TeamValue.Value == player.PlayerData.TeamValue.Value
        elseif game.PlaceId == 2029250188 then
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        elseif game.PlaceId == 2978450615 then
            return getrenv()._G.PlayerProfiles.Data[lPlayer.Name].Team == getrenv()._G.PlayerProfiles.Data[player.Name].Team
        elseif game.GameId == 1934496708 then
            if Workspace.FriendlyFire.Value then return false end
            return (not player.Team or player.Team.Name == "LOBBY" or lPlayer.Team.Name == "LOBBY" or player.Team.Name == "Admin" or lPlayer.Team == player.Team) or
            teamModule[lPlayer.Team.Name] == teamModule[player.Team.Name] or
            ((teamModule[lPlayer.Team.Name] == "CI" and teamModule[player.Team.Name] == "CD") or
            (teamModule[player.Team.Name] == "CI" and teamModule[lPlayer.Team.Name] == "CD"))
        elseif game.PlaceId == 2622527242 then
            if not player.Team or player.Team.Name == "Intro" or player.Team.Name == "Spectator" or player.Team.Name == "Not Playing" or lPlayer.Team == player.Team then return true end
            local function classifyTeam(teamName)
                if teamName == "Class-D Personnel" or teamName == "Chaos Insurgency" then return "Chads" end
                if teamName == "Facility Personnel" or teamName == "Security Department" or teamName == "Mobile Task Force" then return "Crayon Eaters" end
                if teamName == "SCPs" or teamName == "Serpent's Hand" then return "Menaces to Society" end
                if teamName == "Global Occult Coalition" then return "Who?" end
                if teamName == "Unusual Incidents Unit" then return "Who2?" end
                return nil
            end
            local selfTeam = classifyTeam(lPlayer.Team.Name)
            local playerTeam = classifyTeam(player.Team.Name)
            if selfTeam == "Who2?" or playerTeam == "Who2?" then
                if selfTeam == "Crayon Eaters" or playerTeam == "Crayon Eaters" or selfTeam == "Who?" or playerTeam == "Who?" then
                    return true
                end
            end
            return selfTeam == playerTeam
        elseif game.PlaceId == 8770868695 then
            if not lPlayer.Character or not playerChar or not player.Team or player.Team.Name == "Dead" or player.Team.Name == "Inactive" then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        elseif game.PlaceId == 5884786982 then
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.name ~= "Killer" and playerChar.Name ~= "Killer"
        elseif game.GameId == 2162282815 then
            if not player:FindFirstChild("SelectedTeam") then return true end
            return player.SelectedTeam.Value == lPlayer.SelectedTeam.Value
        elseif game.PlaceId == 1240644540 then
            if not teamModule or not teamModule.IsPlayerSurvivor then return true end
            return teamModule.IsPlayerSurvivor(nil, player) == true and teamModule.IsPlayerSurvivor(nil, lPlayer) == true
        elseif game.PlaceId == 10236714118 then
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("Team") then return true end
            return lPlayer.PlayerData.Team.Value == player.PlayerData.Team.Value
        end
        return lPlayer.Team == player.Team
    end

    local function isDead()
        if not playerChar then return true end
        local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
        if game.PlaceId == 6172932937 then
            return player.ragdolled.Value
        elseif game.GameId == 718936923 then
            return playerChar:FindFirstChild("Dead") ~= nil
        end
        return humanoid and humanoid:GetState() == Enum.HumanoidStateType.Dead
    end

    local function isSitting()
        local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
        return Settings.SitCheck and humanoid and humanoid.Sit == true
    end

    local function isFFed()
        if not playerChar then return false end
        if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
            return playerChar.Head.Material == Enum.Material.ForceField
        end
        local ff = playerChar:FindFirstChildWhichIsA("ForceField")
        return Settings.FFCheck and ff and ff.Visible == true
    end

    local function isIgnored()
        if not playerChar then return true end
        local teamIgnored = player.Team and Settings.IgnoreTeams[player.Team.Name]
        local playerIgnored = Settings.IgnorePlayers[player.Name]
        local sameTeam = Settings.IgnoreOwnTeam and isTeammate()
        return teamIgnored or playerIgnored or sameTeam
    end

    local debounce = false
    local function setup(part)
        defaultProperties[part.Name] = {
            Size = part.Size,
            Transparency = part.Transparency,
            Massless = part.Massless,
            CanCollide = part.CanCollide
        }
        
        local props = defaultProperties[part.Name]
        local getSizeHook = part:AddGetHook("Size", props.Size)
        local getTransparencyHook = part:AddGetHook("Transparency", props.Transparency)
        local getMasslessHook = part:AddGetHook("Massless", props.Massless)
        local getCanCollideHook = part:AddGetHook("CanCollide", props.CanCollide)
        
        local setSizeHook = part:AddSetHook("Size", function(_, value)
            props.Size = value
            getSizeHook:Modify("Size", props.Size)
            if Settings.Enabled then
                return Vector3.new(Settings.Size, Settings.Size, Settings.Size)
            end
            return props.Size
        end)
        
        local setTransparencyHook = part:AddSetHook("Transparency", function(_, value)
            props.Transparency = value
            getTransparencyHook:Modify("Transparency", props.Transparency)
            if Settings.Enabled then
                return Settings.Transparency
            end
            return props.Transparency
        end)
        
        local setMasslessHook = part:AddSetHook("Massless", function(_, value)
            props.Massless = value
            getMasslessHook:Modify("Massless", props.Massless)
            if Settings.Enabled and part.Name ~= "HumanoidRootPart" then
                return true
            end
            return props.Massless
        end)
        
        local setCanCollideHook = part:AddSetHook("CanCollide", function(_, value)
            props.CanCollide = value
            getCanCollideHook:Modify("CanCollide", props.CanCollide)
            if Settings.Enabled and not Settings.CollisionsEnabled then
                if part.Name == "Head" or part.Name == "HumanoidRootPart" then
                    return false
                end
            end
            return props.CanCollide
        end)
        
        part.Destroying:Connect(function()
            getSizeHook:Remove()
            getTransparencyHook:Remove()
            getMasslessHook:Remove()
            getCanCollideHook:Remove()
            setSizeHook:Remove()
            setTransparencyHook:Remove()
            setMasslessHook:Remove()
            setCanCollideHook:Remove()
        end)
    end

    local function isActive(part)
        local name = part.Name
        for _, partName in pairs(Settings.BodyParts) do
            if string.match(name, partName) or 
               (partName == "Custom Part" and string.match(name, Settings.CustomPartName)) or
               (partName == "Left Arm" and string.match(name, "Left") and (string.match(name, "Arm") or string.match(name, "Hand"))) or
               (partName == "Right Arm" and string.match(name, "Right") and (string.match(name, "Arm") or string.match(name, "Hand"))) or
               (partName == "Left Leg" and string.match(name, "Left") and (string.match(name, "Leg") or string.match(name, "Foot"))) or
               (partName == "Right Leg" and string.match(name, "Right") and (string.match(name, "Leg") or string.match(name, "Foot"))) then
                return true
            end
        end
        return false
    end

    local function resize(part)
        if not defaultProperties[part.Name] then
            setup(part)
        end
        
        if Settings.Enabled and isActive(part) and not isIgnored() and not isSitting() and not isFFed() and not isDead() then
            part.Massless = part.Name ~= "HumanoidRootPart"
            part.CanCollide = Settings.CollisionsEnabled and defaultProperties[part.Name].CanCollide or false
            part.Size = Vector3.new(Settings.Size, Settings.Size, Settings.Size)
            part.Transparency = Settings.Transparency
        else
            if defaultProperties[part.Name] then
                part.Massless = defaultProperties[part.Name].Massless
                part.CanCollide = defaultProperties[part.Name].CanCollide
                part.Size = defaultProperties[part.Name].Size
                part.Transparency = defaultProperties[part.Name].Transparency
            end
        end
    end

    function playerIdx:Update()
        if not playerChar then return end
        debounce = true
        for _, v in pairs(playerChar:GetChildren()) do
            if v:IsA("BasePart") then
                resize(v)
            end
        end
        debounce = false
    end

    player.CharacterAdded:Connect(function(character)
        playerChar = character
        defaultProperties = {}
        task.wait(0.5)
        playerIdx:Update()
        
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            humanoid.StateChanged:Connect(function(_, newState)
                if newState == Enum.HumanoidStateType.Dead then
                    playerIdx:Update()
                end
            end)
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        defaultProperties = {}
    end)
    
    player:GetPropertyChangedSignal("Team"):Connect(function()
        playerIdx:Update()
    end)
end

local function removePlayer(player)
    players[player] = nil
end

for _, player in pairs(Players:GetPlayers()) do
    if player ~= lPlayer then
        addPlayer(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= lPlayer then
        addPlayer(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayer(player)
end)

lPlayer:GetAttributeChangedSignal("Team"):Connect(updatePlayers)
lPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    updatePlayers()
end)

task.spawn(function()
    while getgenv().HitboxPluginLoaded do
        if Settings.Enabled then
            updatePlayers()
        end
        task.wait(2)
    end
end)

-- ============================================
-- API
-- ============================================
local HitboxAPI = {
    Toggle = function(state)
        Settings.Enabled = state
        updatePlayers()
    end,
    
    SetSize = function(size)
        Settings.Size = math.clamp(size, 2, 100)
        updatePlayers()
    end,
    
    SetTransparency = function(transparency)
        Settings.Transparency = math.clamp(transparency, 0, 1)
        updatePlayers()
    end,
    
    SetBodyParts = function(parts)
        Settings.BodyParts = parts
        updatePlayers()
    end,
    
    SetCustomPartName = function(name)
        Settings.CustomPartName = name
        updatePlayers()
    end,
    
    SetIgnoreOwnTeam = function(state)
        Settings.IgnoreOwnTeam = state
        updatePlayers()
    end,
    
    SetSitCheck = function(state)
        Settings.SitCheck = state
        updatePlayers()
    end,
    
    SetFFCheck = function(state)
        Settings.FFCheck = state
        updatePlayers()
    end,
    
    SetCollisions = function(state)
        Settings.CollisionsEnabled = state
        updatePlayers()
    end,
    
    IgnorePlayer = function(playerName)
        Settings.IgnorePlayers[playerName] = true
        updatePlayers()
    end,
    
    UnignorePlayer = function(playerName)
        Settings.IgnorePlayers[playerName] = nil
        updatePlayers()
    end,
    
    ClearIgnoredPlayers = function()
        Settings.IgnorePlayers = {}
        updatePlayers()
    end,
    
    IgnoreTeam = function(teamName)
        Settings.IgnoreTeams[teamName] = true
        updatePlayers()
    end,
    
    UnignoreTeam = function(teamName)
        Settings.IgnoreTeams[teamName] = nil
        updatePlayers()
    end,
    
    ClearIgnoredTeams = function()
        Settings.IgnoreTeams = {}
        updatePlayers()
    end,
    
    GetSettings = function()
        return Settings
    end,
    
    ForceUpdate = function()
        updatePlayers()
    end,
    
    GetPlayers = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lPlayer then
                table.insert(list, p.Name)
            end
        end
        return list
    end,
    
    GetTeams = function()
        local list = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lPlayer and p.Team then
                list[p.Team.Name] = true
            end
        end
        local teams = {}
        for name, _ in pairs(list) do
            table.insert(teams, name)
        end
        return teams
    end,
    
    -- ============================================
    -- PAINEL OTIMIZADO PARA CELULAR
    -- ============================================
    CreateConfigPanel = function(parent)
        local Panel = Instance.new("Frame")
        Panel.Size = UDim2.new(0, 280, 0, 380)
        Panel.Position = UDim2.new(0.5, -140, 0.5, -190)
        Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Panel.BorderSizePixel = 0
        Panel.Visible = false
        Panel.ZIndex = 1000
        Panel.Active = true
        Panel.Draggable = true
        Panel.Parent = parent
        
        Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 10)
        
        -- Título
        local TitleBar = Instance.new("Frame")
        TitleBar.Size = UDim2.new(1, 0, 0, 35)
        TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        TitleBar.ZIndex = 1001
        TitleBar.Parent = Panel
        Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
        
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -40, 1, 0)
        Title.Position = UDim2.new(0, 12, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "🎯 Hitbox Extender"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 1002
        Title.Parent = TitleBar
        
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 26, 0, 26)
        Close.Position = UDim2.new(1, -30, 0, 4)
        Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Close.Text = "✕"
        Close.TextColor3 = Color3.fromRGB(255, 255, 255)
        Close.Font = Enum.Font.GothamBold
        Close.TextSize = 12
        Close.ZIndex = 1002
        Close.Parent = TitleBar
        Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 13)
        Close.MouseButton1Click:Connect(function()
            Panel.Visible = false
        end)
        
        -- Scroll
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.new(1, -16, 1, -45)
        Scroll.Position = UDim2.new(0, 8, 0, 40)
        Scroll.BackgroundTransparency = 1
        Scroll.ScrollBarThickness = 4
        Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
        Scroll.ZIndex = 1001
        Scroll.Parent = Panel
        
        local List = Instance.new("UIListLayout")
        List.Padding = UDim.new(0, 6)
        List.Parent = Scroll
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 10)
        end)
        
        -- ============================================
        -- HELPER: Toggle (funciona em mobile)
        -- ============================================
        local function AddToggle(name, default, callback)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 40)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -55, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 1003
            Label.Parent = Frame
            
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 48, 0, 24)
            Btn.Position = UDim2.new(1, -54, 0.5, -12)
            Btn.Text = default and "ON" or "OFF"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 11
            Btn.ZIndex = 1003
            Btn.Parent = Frame
            Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 5)
            
            local active = default
            Btn.MouseButton1Click:Connect(function()
                active = not active
                Btn.Text = active and "ON" or "OFF"
                Btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
                callback(active)
            end)
            
            -- Suporte a toque (mobile)
            Btn.TouchTap:Connect(function()
                active = not active
                Btn.Text = active and "ON" or "OFF"
                Btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
                callback(active)
            end)
        end
        
        -- ============================================
        -- HELPER: Slider com botões +/- (MOBILE)
        -- ============================================
        local function AddSlider(name, min, max, default, step, callback)
            local step = step or 1
            
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 50)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
            
            -- Label com valor
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -110, 1, 0)
            Label.Position = UDim2.new(0, 10, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name .. ": " .. default
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 1003
            Label.Parent = Frame
            
            local currentValue = default
            
            -- Botão -
            local MinusBtn = Instance.new("TextButton")
            MinusBtn.Size = UDim2.new(0, 30, 0, 30)
            MinusBtn.Position = UDim2.new(1, -100, 0.5, -15)
            MinusBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
            MinusBtn.Text = "−"
            MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            MinusBtn.Font = Enum.Font.GothamBold
            MinusBtn.TextSize = 18
            MinusBtn.ZIndex = 1003
            MinusBtn.Parent = Frame
            Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 5)
            
            -- Botão +
            local PlusBtn = Instance.new("TextButton")
            PlusBtn.Size = UDim2.new(0, 30, 0, 30)
            PlusBtn.Position = UDim2.new(1, -35, 0.5, -15)
            PlusBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            PlusBtn.Text = "+"
            PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            PlusBtn.Font = Enum.Font.GothamBold
            PlusBtn.TextSize = 18
            PlusBtn.ZIndex = 1003
            PlusBtn.Parent = Frame
            Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 5)
            
            local function updateValue(newValue)
                currentValue = math.clamp(newValue, min, max)
                Label.Text = name .. ": " .. currentValue
                callback(currentValue)
            end
            
            -- Clique normal (PC)
            MinusBtn.MouseButton1Click:Connect(function()
                updateValue(currentValue - step)
            end)
            PlusBtn.MouseButton1Click:Connect(function()
                updateValue(currentValue + step)
            end)
            
            -- Toque (Mobile)
            MinusBtn.TouchTap:Connect(function()
                updateValue(currentValue - step)
            end)
            PlusBtn.TouchTap:Connect(function()
                updateValue(currentValue + step)
            end)
            
            -- Segurar para ajuste rápido (funciona em ambos)
            local holding = nil
            local holdSpeed = 0.15
            
            MinusBtn.MouseButton1Down:Connect(function()
                holding = "minus"
                task.spawn(function()
                    while holding == "minus" do
                        updateValue(currentValue - step)
                        task.wait(holdSpeed)
                        holdSpeed = math.max(0.03, holdSpeed * 0.9)
                    end
                    holdSpeed = 0.15
                end)
            end)
            
            PlusBtn.MouseButton1Down:Connect(function()
                holding = "plus"
                task.spawn(function()
                    while holding == "plus" do
                        updateValue(currentValue + step)
                        task.wait(holdSpeed)
                        holdSpeed = math.max(0.03, holdSpeed * 0.9)
                    end
                    holdSpeed = 0.15
                end)
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    holding = nil
                end
            end)
        end
        
        -- ============================================
        -- SEÇÕES
        -- ============================================
        local function AddSection(text)
            local Section = Instance.new("TextLabel")
            Section.Size = UDim2.new(1, 0, 0, 22)
            Section.BackgroundTransparency = 1
            Section.Text = "  " .. text
            Section.TextColor3 = Color3.fromRGB(100, 200, 255)
            Section.Font = Enum.Font.GothamBold
            Section.TextSize = 10
            Section.TextXAlignment = Enum.TextXAlignment.Left
            Section.ZIndex = 1002
            Section.Parent = Scroll
        end
        
        -- ============================================
        -- CONTEÚDO
        -- ============================================
        
        AddSection("🎯 PRINCIPAL")
        AddToggle("Ativar Hitbox", Settings.Enabled, function(state)
            HitboxAPI.Toggle(state)
        end)
        AddSlider("Tamanho", 2, 100, Settings.Size, 2, function(value)
            HitboxAPI.SetSize(value)
        end)
        AddSlider("Transparência", 0, 1, Settings.Transparency, 0.1, function(value)
            HitboxAPI.SetTransparency(value)
        end)
        
        AddSection("🦴 PARTES DO CORPO")
        local PartsFrame = Instance.new("Frame")
        PartsFrame.Size = UDim2.new(1, 0, 0, 130)
        PartsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        PartsFrame.ZIndex = 1002
        PartsFrame.Parent = Scroll
        Instance.new("UICorner", PartsFrame).CornerRadius = UDim.new(0, 6)
        
        local bodyParts = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
        local selectedParts = {}
        for _, v in pairs(Settings.BodyParts) do
            selectedParts[v] = true
        end
        
        for i, partName in pairs(bodyParts) do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            
            local PartToggle = Instance.new("Frame")
            PartToggle.Size = UDim2.new(0.45, -8, 0, 26)
            PartToggle.Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 8 or 4, 0, 5 + row * 32)
            PartToggle.BackgroundColor3 = selectedParts[partName] and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(50, 50, 60)
            PartToggle.ZIndex = 1003
            PartToggle.Parent = PartsFrame
            Instance.new("UICorner", PartToggle).CornerRadius = UDim.new(0, 5)
            
            local PartBtn = Instance.new("TextButton")
            PartBtn.Size = UDim2.new(1, 0, 1, 0)
            PartBtn.BackgroundTransparency = 1
            PartBtn.Text = partName
            PartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            PartBtn.Font = Enum.Font.Gotham
            PartBtn.TextSize = 10
            PartBtn.ZIndex = 1004
            PartBtn.Parent = PartToggle
            
            PartBtn.MouseButton1Click:Connect(function()
                if selectedParts[partName] then
                    selectedParts[partName] = nil
                    PartToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                else
                    selectedParts[partName] = true
                    PartToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                end
                
                local partsList = {}
                for k, _ in pairs(selectedParts) do
                    table.insert(partsList, k)
                end
                if #partsList == 0 then
                    partsList = {"HumanoidRootPart"}
                    selectedParts["HumanoidRootPart"] = true
                end
                HitboxAPI.SetBodyParts(partsList)
            end)
            
            PartBtn.TouchTap:Connect(function()
                if selectedParts[partName] then
                    selectedParts[partName] = nil
                    PartToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
                else
                    selectedParts[partName] = true
                    PartToggle.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                end
                
                local partsList = {}
                for k, _ in pairs(selectedParts) do
                    table.insert(partsList, k)
                end
                if #partsList == 0 then
                    partsList = {"HumanoidRootPart"}
                    selectedParts["HumanoidRootPart"] = true
                end
                HitboxAPI.SetBodyParts(partsList)
            end)
        end
        
        AddSection("🚫 IGNORAR")
        AddToggle("Ignorar Aliados", Settings.IgnoreOwnTeam, function(state)
            HitboxAPI.SetIgnoreOwnTeam(state)
        end)
        AddToggle("Ignorar Sentados", Settings.SitCheck, function(state)
            HitboxAPI.SetSitCheck(state)
        end)
        AddToggle("Ignorar ForceField", Settings.FFCheck, function(state)
            HitboxAPI.SetFFCheck(state)
        end)
        
        AddSection("💥 COLISÕES")
        AddToggle("Ativar Colisões", Settings.CollisionsEnabled, function(state)
            HitboxAPI.SetCollisions(state)
        end)
        
        return Panel
    end
}

getgenv().HitboxPluginLoaded = true
return HitboxAPI
