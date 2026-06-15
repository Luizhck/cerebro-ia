-- Hitbox Extender Plugin para LRMODS Combat
-- Versão: 1.0 Completa
-- Chamado via: loadstring(game:HttpGet("URL_DO_GITHUB"))()

if getgenv().HitboxPluginLoaded ~= nil then
    return {error = "Hitbox já está carregado!"}
end
getgenv().HitboxPluginLoaded = false

-- Aguarda o jogo carregar
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Carrega dependência MT-Api
if not getgenv().MTAPIMutex then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RectangularObject/MT-Api-v2/main/__source/mt-api%20v2.lua", true))()
    end)
end

-- Configurações padrão
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

-- Serviços
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local lPlayer = Players.LocalPlayer
local players = {}
local teamModule = nil

-- Função de atualização
local function updatePlayers()
    if not getgenv().HitboxPluginLoaded then return end
    if not Settings.Enabled then return end
    for _, v in pairs(players) do
        task.spawn(function()
            pcall(v.Update, v)
        end)
    end
end

-- Inicializa módulos específicos de jogos
pcall(function()
    if game.GameId == 504234221 then -- Vampire Hunters 3
        teamModule = require(ReplicatedStorage.Scripts.Modules.PlayerModule)
    end
    if game.GameId == 1934496708 then -- Project: SCP
        teamModule = require(Workspace:WaitForChild("Teams"))
    end
end)

-- Função para adicionar jogador
local function addPlayer(player)
    players[player] = {}
    local playerIdx = players[player]
    local playerChar = player.Character
    local defaultProperties = {}

    -- ============================================
    -- LÓGICA COMPLETA DE DETECÇÃO DE TIMES
    -- ============================================
    local function isTeammate()
        -- Neighborhood War
        if game.GameId == 718936923 then
            if not lPlayer.Character or not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return true end
            return lPlayer.Character.HumanoidRootPart.Color == playerChar.HumanoidRootPart.Color
        
        -- Fireteam
        elseif game.PlaceId == 633284182 then
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("TeamValue") then return true end
            return lPlayer.PlayerData.TeamValue.Value == player.PlayerData.TeamValue.Value
        
        -- Q-Clash
        elseif game.PlaceId == 2029250188 then
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        
        -- Paintball Reloaded
        elseif game.PlaceId == 2978450615 then
            return getrenv()._G.PlayerProfiles.Data[lPlayer.Name].Team == getrenv()._G.PlayerProfiles.Data[player.Name].Team
        
        -- Project: SCP
        elseif game.GameId == 1934496708 then
            if Workspace.FriendlyFire.Value then return false end
            return (not player.Team or player.Team.Name == "LOBBY" or lPlayer.Team.Name == "LOBBY" or player.Team.Name == "Admin" or lPlayer.Team == player.Team) or
            teamModule[lPlayer.Team.Name] == teamModule[player.Team.Name] or
            ((teamModule[lPlayer.Team.Name] == "CI" and teamModule[player.Team.Name] == "CD") or
            (teamModule[player.Team.Name] == "CI" and teamModule[lPlayer.Team.Name] == "CD"))
        
        -- SCP rBreach
        elseif game.PlaceId == 2622527242 then
            if not player.Team or player.Team.Name == "Intro" or player.Team.Name == "Spectator" or player.Team.Name == "Not Playing" or lPlayer.Team == player.Team then return true end
            local lPlayerTeamName = lPlayer.Team.Name
            local playerTeamName = player.Team.Name
            local selfTeam, playerTeam
            
            local function classifyTeam(teamName)
                if teamName == "Class-D Personnel" or teamName == "Chaos Insurgency" then return "Chads" end
                if teamName == "Facility Personnel" or teamName == "Security Department" or teamName == "Mobile Task Force" then return "Crayon Eaters" end
                if teamName == "SCPs" or teamName == "Serpent's Hand" then return "Menaces to Society" end
                if teamName == "Global Occult Coalition" then return "Who?" end
                if teamName == "Unusual Incidents Unit" then return "Who2?" end
                return nil
            end
            
            selfTeam = classifyTeam(lPlayerTeamName)
            playerTeam = classifyTeam(playerTeamName)
            
            if selfTeam == "Who2?" or playerTeam == "Who2?" then
                if selfTeam == "Crayon Eaters" or playerTeam == "Crayon Eaters" or selfTeam == "Who?" or playerTeam == "Who?" then
                    return true
                end
            end
            return selfTeam == playerTeam
        
        -- Anomalous Activities: First Contact
        elseif game.PlaceId == 8770868695 then
            if not lPlayer.Character or not playerChar or not player.Team or player.Team.Name == "Dead" or player.Team.Name == "Inactive" then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        
        -- Escape The Darkness
        elseif game.PlaceId == 5884786982 then
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.name ~= "Killer" and playerChar.Name ~= "Killer"
        
        -- Rush Point
        elseif game.GameId == 2162282815 then
            if not player:FindFirstChild("SelectedTeam") then return true end
            return player.SelectedTeam.Value == lPlayer.SelectedTeam.Value
        
        -- Vampire Hunters 3
        elseif game.PlaceId == 1240644540 then
            if not teamModule or not teamModule.IsPlayerSurvivor then return true end
            return teamModule.IsPlayerSurvivor(nil, player) == true and teamModule.IsPlayerSurvivor(nil, lPlayer) == true
        
        -- Return of Humans vs Zombies
        elseif game.PlaceId == 10236714118 then
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("Team") then return true end
            return lPlayer.PlayerData.Team.Value == player.PlayerData.Team.Value
        
        -- Energy Assault
        elseif game.PlaceId == 6172932937 then
            if not player.Team or not lPlayer.Team then return true end
            return player.Team == lPlayer.Team
        
        -- Town
        elseif game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
            if not player.Team or not lPlayer.Team then return true end
            return player.Team == lPlayer.Team
        
        -- Critical Strike
        elseif game.PlaceId == 111311599 then
            if not player.Team or not lPlayer.Team then return true end
            return player.Team == lPlayer.Team
        end
        
        -- Padrão: compara times
        return lPlayer.Team == player.Team
    end

    -- Verificações de estado
    local function isDead()
        if not playerChar then return true end
        local humanoid = playerChar:FindFirstChildWhichIsA("Humanoid")
        if game.PlaceId == 6172932937 then -- Energy Assault
            return player.ragdolled.Value
        elseif game.GameId == 718936923 then -- Neighborhood War
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
        if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then -- town
            return playerChar.Head.Material == Enum.Material.ForceField
        end
        local ff = playerChar:FindFirstChildWhichIsA("ForceField")
        return Settings.FFCheck and ff and ff.Visible == true
    end

    local function isIgnored()
        if not playerChar then return true end
        return (Settings.IgnoreOwnTeam and isTeammate()) or
               (Settings.IgnorePlayers[player.Name]) or
               (player.Team and Settings.IgnoreTeams[player.Team.Name])
    end

    -- Sistema de hooks
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
            part.Massless = defaultProperties[part.Name].Massless
            part.CanCollide = defaultProperties[part.Name].CanCollide
            part.Size = defaultProperties[part.Name].Size
            part.Transparency = defaultProperties[part.Name].Transparency
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

    -- Conexões de eventos do jogador
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

-- Remove jogador
local function removePlayer(player)
    players[player] = nil
end

-- Inicializa jogadores existentes
for _, player in pairs(Players:GetPlayers()) do
    if player ~= lPlayer then
        addPlayer(player)
    end
end

-- Conexões globais
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

-- Atualização periódica (a cada 2 segundos) para garantir sincronia
task.spawn(function()
    while getgenv().HitboxPluginLoaded do
        if Settings.Enabled then
            updatePlayers()
        end
        task.wait(2)
    end
end)

-- API de controle
local HitboxAPI = {
    Toggle = function(state)
        Settings.Enabled = state
        updatePlayers()
        return Settings.Enabled
    end,
    
    SetSize = function(size)
        Settings.Size = math.clamp(size, 2, 100)
        updatePlayers()
        return Settings.Size
    end,
    
    SetTransparency = function(transparency)
        Settings.Transparency = math.clamp(transparency, 0, 1)
        updatePlayers()
        return Settings.Transparency
    end,
    
    SetBodyParts = function(parts)
        Settings.BodyParts = parts
        updatePlayers()
    end,
    
    SetIgnoreOwnTeam = function(state)
        Settings.IgnoreOwnTeam = state
        updatePlayers()
    end,
    
    SetCollisions = function(state)
        Settings.CollisionsEnabled = state
        updatePlayers()
    end,
    
    GetSettings = function()
        return Settings
    end,
    
    ForceUpdate = function()
        updatePlayers()
    end,
    
    -- Retorna o painel de configuração
    CreateConfigPanel = function(parent)
        local Panel = Instance.new("Frame")
        Panel.Size = UDim2.new(0, 250, 0, 320)
        Panel.Position = UDim2.new(0.5, -125, 0.5, -160)
        Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Panel.BorderSizePixel = 0
        Panel.Visible = false
        Panel.ZIndex = 1000
        Panel.Active = true
        Panel.Draggable = true
        Panel.Parent = parent
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 10)
        Corner.Parent = Panel
        
        -- Título
        local TitleBar = Instance.new("Frame")
        TitleBar.Size = UDim2.new(1, 0, 0, 30)
        TitleBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        TitleBar.ZIndex = 1001
        TitleBar.Parent = Panel
        
        local TitleCorner = Instance.new("UICorner")
        TitleCorner.CornerRadius = UDim.new(0, 10)
        TitleCorner.Parent = TitleBar
        
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -30, 1, 0)
        Title.Position = UDim2.new(0, 12, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "🎯 Hitbox Extender"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 13
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 1002
        Title.Parent = TitleBar
        
        -- Botão Fechar
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 22, 0, 22)
        Close.Position = UDim2.new(1, -26, 0, 4)
        Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Close.Text = "✕"
        Close.TextColor3 = Color3.fromRGB(255, 255, 255)
        Close.Font = Enum.Font.GothamBold
        Close.TextSize = 11
        Close.ZIndex = 1002
        Close.Parent = TitleBar
        
        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 11)
        closeCorner.Parent = Close
        
        Close.MouseButton1Click:Connect(function()
            Panel.Visible = false
        end)
        
        -- Conteúdo scrollável
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.new(1, -16, 1, -40)
        Scroll.Position = UDim2.new(0, 8, 0, 35)
        Scroll.BackgroundTransparency = 1
        Scroll.ScrollBarThickness = 3
        Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 200, 255)
        Scroll.ZIndex = 1001
        Scroll.Parent = Panel
        
        local List = Instance.new("UIListLayout")
        List.Padding = UDim.new(0, 5)
        List.Parent = Scroll
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 10)
        end)
        
        -- Helper: Toggle
        local function AddToggle(name, default, callback)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 35)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = Frame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 1, 0)
            Label.Position = UDim2.new(0, 8, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name
            Label.TextColor3 = Color3.fromRGB(255, 255, 255)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 11
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 1003
            Label.Parent = Frame
            
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 42, 0, 20)
            Btn.Position = UDim2.new(1, -48, 0.5, -10)
            Btn.Text = default and "ON" or "OFF"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 10
            Btn.ZIndex = 1003
            Btn.Parent = Frame
            
            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 4)
            btnCorner.Parent = Btn
            
            local active = default
            Btn.MouseButton1Click:Connect(function()
                active = not active
                Btn.Text = active and "ON" or "OFF"
                Btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
                callback(active)
            end)
        end
        
        -- Helper: Slider
        local function AddSlider(name, min, max, default, callback)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 50)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 6)
            frameCorner.Parent = Frame
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 20)
            Label.Position = UDim2.new(0, 8, 0, 3)
            Label.BackgroundTransparency = 1
            Label.Text = name .. ": " .. default
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 10
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 1003
            Label.Parent = Frame
            
            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 8)
            Bar.Position = UDim2.new(0, 10, 0, 35)
            Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            Bar.ZIndex = 1003
            Bar.Parent = Frame
            
            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 4)
            barCorner.Parent = Bar
            
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            Fill.ZIndex = 1004
            Fill.Parent = Bar
            
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 4)
            fillCorner.Parent = Fill
            
            local Drag = Instance.new("TextButton")
            Drag.Size = UDim2.new(1, 0, 2, 0)
            Drag.Position = UDim2.new(0, 0, 0.5, -8)
            Drag.BackgroundTransparency = 1
            Drag.Text = ""
            Drag.ZIndex = 1005
            Drag.Parent = Bar
            
            local dragging = false
            Drag.MouseButton1Down:Connect(function()
                dragging = true
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            game:GetService("UserInputService").InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
                    local percent = math.clamp((mousePos.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    local value = math.floor((min + (max - min) * percent) * 10) / 10
                    Fill.Size = UDim2.new(percent, 0, 1, 0)
                    Label.Text = name .. ": " .. value
                    callback(value)
                end
            end)
        end
        
        -- Toggles e Sliders
        AddToggle("Ativar Hitbox", Settings.Enabled, function(state)
            HitboxAPI.Toggle(state)
        end)
        
        AddSlider("Tamanho", 2, 100, Settings.Size, function(value)
            HitboxAPI.SetSize(value)
        end)
        
        AddSlider("Transparência", 0, 1, Settings.Transparency, function(value)
            HitboxAPI.SetTransparency(value)
        end)
        
        AddToggle("Ignorar Aliados", Settings.IgnoreOwnTeam, function(state)
            HitboxAPI.SetIgnoreOwnTeam(state)
        end)
        
        AddToggle("Colisões", Settings.CollisionsEnabled, function(state)
            HitboxAPI.SetCollisions(state)
        end)
        
        -- Seção de partes do corpo
        local PartsFrame = Instance.new("Frame")
        PartsFrame.Size = UDim2.new(1, 0, 0, 125)
        PartsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        PartsFrame.ZIndex = 1002
        PartsFrame.Parent = Scroll
        
        local partsCorner = Instance.new("UICorner")
        partsCorner.CornerRadius = UDim.new(0, 6)
        partsCorner.Parent = PartsFrame
        
        local PartsLabel = Instance.new("TextLabel")
        PartsLabel.Size = UDim2.new(1, -10, 0, 20)
        PartsLabel.Position = UDim2.new(0, 8, 0, 3)
        PartsLabel.BackgroundTransparency = 1
        PartsLabel.Text = "Partes do Corpo:"
        PartsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        PartsLabel.Font = Enum.Font.GothamBold
        PartsLabel.TextSize = 10
        PartsLabel.TextXAlignment = Enum.TextXAlignment.Left
        PartsLabel.ZIndex = 1003
        PartsLabel.Parent = PartsFrame
        
        local bodyParts = {"Head", "HumanoidRootPart", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
        local selectedParts = {["HumanoidRootPart"] = true}
        
        local col = 0
        local row = 0
        for i, partName in pairs(bodyParts) do
            col = (i - 1) % 2
            row = math.floor((i - 1) / 2)
            
            local PartToggle = Instance.new("Frame")
            PartToggle.Size = UDim2.new(0.45, -8, 0, 22)
            PartToggle.Position = UDim2.new(col == 0 and 0 or 0.5, col == 0 and 8 or 4, 0, 25 + row * 26)
            PartToggle.BackgroundColor3 = selectedParts[partName] and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(50, 50, 60)
            PartToggle.ZIndex = 1003
            PartToggle.Parent = PartsFrame
            
            local partCorner = Instance.new("UICorner")
            partCorner.CornerRadius = UDim.new(0, 4)
            partCorner.Parent = PartToggle
            
            local PartBtn = Instance.new("TextButton")
            PartBtn.Size = UDim2.new(1, 0, 1, 0)
            PartBtn.BackgroundTransparency = 1
            PartBtn.Text = partName
            PartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            PartBtn.Font = Enum.Font.Gotham
            PartBtn.TextSize = 9
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
                    -- Atualiza visual
                    for _, child in pairs(PartsFrame:GetChildren()) do
                        if child:IsA("Frame") and child:FindFirstChildOfClass("TextButton") then
                            local btn = child:FindFirstChildOfClass("TextButton")
                            if btn and btn.Text == "HumanoidRootPart" then
                                child.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
                            end
                        end
                    end
                end
                HitboxAPI.SetBodyParts(partsList)
            end)
        end
        
        return Panel
    end,
    
    -- Destruir plugin
    Destroy = function()
        getgenv().HitboxPluginLoaded = false
        Settings.Enabled = false
        updatePlayers()
        players = {}
        Settings = {}
    end
}

-- Finaliza
getgenv().HitboxPluginLoaded = true

return HitboxAPI
