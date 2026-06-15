-- Hitbox Extender Plugin para LRMODS Combat
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
    if game.GameId == 504234221 then
        teamModule = require(ReplicatedStorage.Scripts.Modules.PlayerModule)
    end
    if game.GameId == 1934496708 then
        teamModule = require(Workspace:WaitForChild("Teams"))
    end
end)

-- Função para adicionar jogador (mesma lógica do original)
local function addPlayer(player)
    players[player] = {}
    local playerIdx = players[player]
    local playerChar = player.Character
    local defaultProperties = {}

    -- Verificação de time (mesma lógica completa do original)
    local function isTeammate()
        -- [Cole aqui toda a lógica de isTeammate do código original]
        -- (Mantida exatamente igual para compatibilidade com todos os jogos)
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
        return (Settings.IgnoreOwnTeam and isTeammate()) or
               (Settings.IgnorePlayers[player.Name]) or
               (player.Team and Settings.IgnoreTeams[player.Team.Name])
    end

    -- Sistema de hooks (mantido do original)
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

    -- Conexões de eventos
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
    
    -- Retorna o painel de configuração
    CreateConfigPanel = function(parent)
        -- Cria o painel flutuante de configuração
        local Panel = Instance.new("Frame")
        Panel.Size = UDim2.new(0, 250, 0, 300)
        Panel.Position = UDim2.new(0.5, -125, 0.5, -150)
        Panel.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Panel.BorderSizePixel = 0
        Panel.Visible = false
        Panel.ZIndex = 1000
        Panel.Parent = parent
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 10)
        Corner.Parent = Panel
        
        -- Título
        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -30, 0, 30)
        Title.Position = UDim2.new(0, 15, 0, 5)
        Title.BackgroundTransparency = 1
        Title.Text = "🎯 Hitbox Extender"
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 14
        Title.ZIndex = 1001
        Title.Parent = Panel
        
        -- Botão Fechar
        local Close = Instance.new("TextButton")
        Close.Size = UDim2.new(0, 20, 0, 20)
        Close.Position = UDim2.new(1, -25, 0, 8)
        Close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Close.Text = "✕"
        Close.TextColor3 = Color3.fromRGB(255, 255, 255)
        Close.Font = Enum.Font.GothamBold
        Close.TextSize = 10
        Close.ZIndex = 1001
        Close.Parent = Panel
        Close.MouseButton1Click:Connect(function()
            Panel.Visible = false
        end)
        
        -- Conteúdo scrollável
        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.new(1, -20, 1, -45)
        Scroll.Position = UDim2.new(0, 10, 0, 40)
        Scroll.BackgroundTransparency = 1
        Scroll.ScrollBarThickness = 3
        Scroll.ZIndex = 1001
        Scroll.Parent = Panel
        
        local List = Instance.new("UIListLayout")
        List.Padding = UDim.new(0, 5)
        List.Parent = Scroll
        List:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, List.AbsoluteContentSize.Y + 10)
        end)
        
        -- Função helper para criar toggles
        local function AddToggle(name, default, callback)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 35)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            
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
            Btn.Size = UDim2.new(0, 40, 0, 20)
            Btn.Position = UDim2.new(1, -45, 0.5, -10)
            Btn.Text = default and "ON" or "OFF"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.BackgroundColor3 = default and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
            Btn.Font = Enum.Font.GothamBold
            Btn.TextSize = 10
            Btn.ZIndex = 1003
            Btn.Parent = Frame
            
            local active = default
            Btn.MouseButton1Click:Connect(function()
                active = not active
                Btn.Text = active and "ON" or "OFF"
                Btn.BackgroundColor3 = active and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(70, 70, 70)
                callback(active)
            end)
            
            return {Frame = Frame, Btn = Btn}
        end
        
        -- Função helper para criar sliders
        local function AddSlider(name, min, max, default, callback)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, 0, 0, 45)
            Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            Frame.ZIndex = 1002
            Frame.Parent = Scroll
            
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -10, 0, 18)
            Label.Position = UDim2.new(0, 5, 0, 3)
            Label.BackgroundTransparency = 1
            Label.Text = name .. ": " .. default
            Label.TextColor3 = Color3.fromRGB(200, 200, 200)
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 10
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.ZIndex = 1003
            Label.Parent = Frame
            
            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1, -20, 0, 6)
            Bar.Position = UDim2.new(0, 10, 0, 32)
            Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            Bar.ZIndex = 1003
            Bar.Parent = Frame
            
            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            Fill.ZIndex = 1004
            Fill.Parent = Bar
            
            local Drag = Instance.new("TextButton")
            Drag.Size = UDim2.new(1, 0, 1, 0)
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
                    local value = min + (max - min) * percent
                    value = math.floor(value * 10) / 10
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
        
        -- Dropdown de partes do corpo
        local PartsFrame = Instance.new("Frame")
        PartsFrame.Size = UDim2.new(1, 0, 0, 120)
        PartsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        PartsFrame.ZIndex = 1002
        PartsFrame.Parent = Scroll
        
        local PartsLabel = Instance.new("TextLabel")
        PartsLabel.Size = UDim2.new(1, -10, 0, 18)
        PartsLabel.Position = UDim2.new(0, 5, 0, 3)
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
        
        local yOffset = 22
        for _, partName in pairs(bodyParts) do
            local PartToggle = Instance.new("Frame")
            PartToggle.Size = UDim2.new(0.45, -5, 0, 22)
            PartToggle.Position = UDim2.new(yOffset > 22 and 0.5 or 0, 5, 0, yOffset)
            PartToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            PartToggle.ZIndex = 1003
            PartToggle.Parent = PartsFrame
            
            local PartBtn = Instance.new("TextButton")
            PartBtn.Size = UDim2.new(1, 0, 1, 0)
            PartBtn.BackgroundTransparency = 1
            PartBtn.Text = partName
            PartBtn.TextColor3 = selectedParts[partName] and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(180, 180, 180)
            PartBtn.Font = Enum.Font.Gotham
            PartBtn.TextSize = 9
            PartBtn.ZIndex = 1004
            PartBtn.Parent = PartToggle
            
            PartBtn.MouseButton1Click:Connect(function()
                if selectedParts[partName] then
                    selectedParts[partName] = nil
                    PartBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                else
                    selectedParts[partName] = true
                    PartBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
                end
                
                local partsList = {}
                for k, _ in pairs(selectedParts) do
                    table.insert(partsList, k)
                end
                HitboxAPI.SetBodyParts(partsList)
            end)
            
            if partName == "Right Arm" or partName == "Right Leg" then
                yOffset = yOffset + 24
            end
        end
        
        return Panel
    end
}

-- Finaliza
getgenv().HitboxPluginLoaded = true

return HitboxAPI
