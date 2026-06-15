-- Hitbox Extender sem GUI - Baseado no FurryHBE
-- Todas as funções de hitbox mantidas, sem ESP/Chams

if getgenv().HitboxLoaded ~= nil then
    return
end
getgenv().HitboxLoaded = false

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not getgenv().MTAPIMutex then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/RectangularObject/MT-Api-v2/main/__source/mt-api%20v2.lua", true))()
end

-- Configurações (valores padrão do código original)
local Settings = {
    Toggled = true,
    Size = 10,
    Transparency = 0.5,
    CustomPartName = "HeadHB",
    BodyParts = {"HumanoidRootPart"},
    SitCheck = true,
    FFCheck = true,
    IgnorePlayers = {},
    IgnoreOwnTeam = true,
    IgnoreTeams = {},
    CollisionsEnabled = false
}

-- Serviços
local Teams = game:GetService("Teams")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local lPlayer = Players.LocalPlayer
local players = {}
local teamModule = nil

-- Atualiza todos os jogadores
local function updatePlayers()
    if not getgenv().HitboxLoaded then return end
    for _, v in pairs(players) do
        task.spawn(function()
            v:Update()
        end)
    end
end

-- Inicialização de módulos específicos de jogos
if game.GameId == 504234221 then -- Vampire Hunters 3
    teamModule = require(ReplicatedStorage.Scripts.Modules.PlayerModule)
end
if game.GameId == 1934496708 then -- Project: SCP
    teamModule = require(Workspace:WaitForChild("Teams"))
end

-- Função para adicionar jogador
local function addPlayer(player)
    players[player] = {}
    local playerIdx = players[player]
    local playerChar = player.Character
    local defaultProperties = {}

    -- Verifica se é companheiro de time
    local function isTeammate()
        if game.GameId == 718936923 then -- Neighborhood War
            if not lPlayer.Character or not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return true end
            return lPlayer.Character.HumanoidRootPart.Color == playerChar.HumanoidRootPart.Color
        elseif game.PlaceId == 633284182 then -- Fireteam
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("TeamValue") then return true end
            return lPlayer.PlayerData.TeamValue.Value == player.PlayerData.TeamValue.Value
        elseif game.PlaceId == 2029250188 then -- Q-Clash
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        elseif game.PlaceId == 2978450615 then -- Paintball Reloaded
            return getrenv()._G.PlayerProfiles.Data[lPlayer.Name].Team == getrenv()._G.PlayerProfiles.Data[player.Name].Team
        elseif game.GameId == 1934496708 then -- Project: SCP
            if Workspace.FriendlyFire.Value then return false end
            return (not player.Team or player.Team.Name == "LOBBY" or lPlayer.Team.Name == "LOBBY" or player.Team.Name == "Admin" or lPlayer.Team == player.Team) or
            teamModule[lPlayer.Team.Name] == teamModule[player.Team.Name] or
            ((teamModule[lPlayer.Team.Name] == "CI" and teamModule[player.Team.Name] == "CD") or
            (teamModule[player.Team.Name] == "CI" and teamModule[lPlayer.Team.Name] == "CD"))
        elseif game.PlaceId == 2622527242 then -- SCP rBreach
            if not player.Team or player.Team.Name == "Intro" or player.Team.Name == "Spectator" or player.Team.Name == "Not Playing" or lPlayer.Team == player.Team then return true end
            local lPlayerTeamName = lPlayer.Team.Name
            local playerTeamName = player.Team.Name
            local selfTeam, playerTeam
            -- Classificação de times
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
        elseif game.PlaceId == 8770868695 then -- Anomalous Activities: First Contact
            if not lPlayer.Character or not playerChar or not player.Team or player.Team.Name == "Dead" or player.Team.Name == "Inactive" then return true end
            return lPlayer.Character.Parent == playerChar.Parent
        elseif game.PlaceId == 5884786982 then -- Escape The Darkness
            if not lPlayer.Character or not playerChar then return true end
            return lPlayer.Character.name ~= "Killer" and playerChar.Name ~= "Killer"
        elseif game.GameId == 2162282815 then -- Rush Point
            if not player:FindFirstChild("SelectedTeam") then return true end
            return player.SelectedTeam.Value == lPlayer.SelectedTeam.Value
        elseif game.PlaceId == 1240644540 then -- Vampire Hunters 3
            if not teamModule or not teamModule.IsPlayerSurvivor then return true end
            return teamModule.IsPlayerSurvivor(nil, player) == true and teamModule.IsPlayerSurvivor(nil, lPlayer) == true
        elseif game.PlaceId == 10236714118 then -- Return of Humans vs Zombies
            if not player:FindFirstChild("PlayerData") or not player.PlayerData:FindFirstChild("Team") then return true end
            return lPlayer.PlayerData.Team.Value == player.PlayerData.Team.Value
        end
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
        return Settings.SitCheck and humanoid ~= nil and humanoid.Sit == true
    end

    local function isFFed()
        if not playerChar then return false end
        if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then -- town
            return playerChar.Head.Material == Enum.Material.ForceField
        end
        local ff = playerChar:FindFirstChildWhichIsA("ForceField")
        return Settings.FFCheck and ff ~= nil and ff.Visible == true
    end

    local function isIgnored()
        if not playerChar then return true end
        return (Settings.IgnoreOwnTeam and isTeammate()) or
               (Settings.IgnoreTeams[player.Team and player.Team.Name or ""]) or
               (Settings.IgnorePlayers[player.Name])
    end

    -- Configuração de hooks
    local debounce = false
    local function setup(part)
        defaultProperties[part.Name] = {
            Size = part.Size,
            Transparency = part.Transparency,
            Massless = part.Massless,
            CanCollide = part.CanCollide,
            CollisionGroupId = part.CollisionGroupId
        }
        
        local props = defaultProperties[part.Name]
        local getSizeHook = part:AddGetHook("Size", props.Size)
        local getTransparencyHook = part:AddGetHook("Transparency", props.Transparency)
        local getMasslessHook = part:AddGetHook("Massless", props.Massless)
        local getCanCollideHook = part:AddGetHook("CanCollide", props.CanCollide)
        
        local setSizeHook = part:AddSetHook("Size", function(_, value)
            props.Size = value
            getSizeHook:Modify("Size", props.Size)
            if Settings.Toggled then
                return Vector3.new(Settings.Size, Settings.Size, Settings.Size)
            end
            return props.Size
        end)
        
        local setTransparencyHook = part:AddSetHook("Transparency", function(_, value)
            props.Transparency = value
            getTransparencyHook:Modify("Transparency", props.Transparency)
            if Settings.Toggled then
                return Settings.Transparency
            end
            return props.Transparency
        end)
        
        local setMasslessHook = part:AddSetHook("Massless", function(_, value)
            props.Massless = value
            getMasslessHook:Modify("Massless", props.Massless)
            if Settings.Toggled and part.Name ~= "HumanoidRootPart" then
                return true
            end
            return props.Massless
        end)
        
        local setCanCollideHook = part:AddSetHook("CanCollide", function(_, value)
            props.CanCollide = value
            getCanCollideHook:Modify("CanCollide", props.CanCollide)
            if Settings.Toggled and not Settings.CollisionsEnabled then
                if part.Name == "Head" or part.Name == "HumanoidRootPart" then
                    return false
                end
            end
            return props.CanCollide
        end)
        
        local changed = part.Changed:Connect(function(property)
            if debounce then return end
            if props[property] and props[property] ~= part[property] then
                props[property] = part[property]
                playerIdx:Update()
            end
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
            changed:Disconnect()
        end)
    end

    -- Verifica se uma parte deve ser expandida
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

    -- Redimensiona uma parte
    local function resize(part)
        if not defaultProperties[part.Name] then
            setup(part)
        end
        
        if Settings.Toggled and isActive(part) and not isIgnored() and not isSitting() and not isFFed() and not isDead() then
            if part.Name ~= "HumanoidRootPart" then
                part.Massless = true
            end
            
            if not Settings.CollisionsEnabled then
                part.CanCollide = false
            else
                part.CanCollide = defaultProperties[part.Name].CanCollide
            end
            
            part.Size = Vector3.new(Settings.Size, Settings.Size, Settings.Size)
            part.Transparency = Settings.Transparency
            
            if part.Name == "Head" then
                local face = part:FindFirstChild("face")
                if face then
                    face.Transparency = Settings.Transparency
                end
            end
        else
            part.Massless = defaultProperties[part.Name].Massless
            part.CanCollide = defaultProperties[part.Name].CanCollide
            part.Size = defaultProperties[part.Name].Size
            part.Transparency = defaultProperties[part.Name].Transparency
            
            if part.Name == "Head" then
                local face = part:FindFirstChild("face")
                if face then
                    face.Transparency = defaultProperties["Head"].Transparency
                end
            end
        end
    end

    -- Atualiza o jogador
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

    -- Espera o personagem carregar completamente
    local function WaitForFullChar(char)
        local startTime = tick()
        local humanoid = char:FindFirstChildWhichIsA("Humanoid")
        if not humanoid then
            repeat
                if char == nil then return false end
                humanoid = char:FindFirstChildWhichIsA("Humanoid")
                task.wait()
            until humanoid or tick()-startTime >= 2
        end
        
        local loaded = false
        startTime = tick()
        repeat
            local limbs = 0
            for _, v in pairs(char:GetChildren()) do
                if humanoid:GetLimb(v) ~= Enum.Limb.Unknown then
                    limbs += 1
                end
            end
            if limbs == 6 or limbs == 15 then
                loaded = true
            end
            task.wait()
        until loaded or tick()-startTime >= 3
        
        return true
    end

    -- Conexões de eventos
    player.CharacterAdded:Connect(function(character)
        playerChar = character
        defaultProperties = {}
        
        if WaitForFullChar(character) then
            playerIdx:Update()
            
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                    if humanoid.Health <= 0 then
                        playerIdx:Update()
                    end
                end)
                
                humanoid.StateChanged:Connect(function(_, newState)
                    if newState == Enum.HumanoidStateType.Dead then
                        playerIdx:Update()
                    end
                end)
            end
            
            if character:FindFirstChildWhichIsA("ForceField") then
                playerIdx:Update()
            end
            
            character.ChildAdded:Connect(function(child)
                if game.GameId == 718936923 and child.Name == "Dead" then
                    playerIdx:Update()
                    return
                end
                if child:IsA("ForceField") then
                    playerIdx:Update()
                end
            end)
            
            character.ChildRemoved:Connect(function(child)
                if child:IsA("ForceField") then
                    playerIdx:Update()
                end
            end)
            
            if game.PlaceId == 4991214437 or game.PlaceId == 6652350934 then
                local head = playerChar:FindFirstChild("Head")
                if head then
                    head:GetPropertyChangedSignal("Material"):Connect(function()
                        playerIdx:Update()
                    end)
                end
            end
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        if playerIdx then
            defaultProperties = {}
        end
    end)
    
    player:GetPropertyChangedSignal("Team"):Connect(function()
        playerIdx:Update()
    end)
    
    -- Eventos específicos de jogos
    if game.PlaceId == 6172932937 then -- Energy Assault
        local ragdolled = player:WaitForChild("ragdolled")
        if ragdolled then
            ragdolled.Changed:Connect(function()
                playerIdx:Update()
            end)
        end
    end
    
    if game.GameId == 1934496708 then -- Project: SCP
        local ff = Workspace:WaitForChild("FriendlyFire")
        if ff then
            ff.Changed:Connect(function()
                playerIdx:Update()
            end)
        end
    end
    
    if game.GameId == 2162282815 then -- Rush Point
        local mapFolder = Workspace:WaitForChild("MapFolder")
        local gamePlayers = mapFolder:WaitForChild("Players")
        for _, v in pairs(gamePlayers:GetChildren()) do
            if v.Name == player.Name then
                playerChar = v
            end
        end
        gamePlayers.ChildAdded:Connect(function(v)
            if v.Name == player.Name then
                playerChar = v
            end
        end)
    end
end

-- Remove um jogador
local function removePlayer(player)
    if not players[player] then return end
    Settings.IgnorePlayers[player.Name] = nil
    players[player] = nil
end

-- Inicializa jogadores existentes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= lPlayer then
        addPlayer(player)
    end
end

-- Conexões de eventos globais
Players.PlayerAdded:Connect(function(player)
    addPlayer(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayer(player)
end)

lPlayer:GetAttributeChangedSignal("Team"):Connect(function()
    updatePlayers()
end)

lPlayer.CharacterAdded:Connect(function()
    updatePlayers()
end)

-- Bypass anti-cheat para Critical Strike
if game.PlaceId == 111311599 then
    local anticheat = game:GetService("ReplicatedFirst")["Serverbased AntiCheat"]
    local sValue = lPlayer:WaitForChild("SValue")
    
    local function constructAnticheatString()
        return "CS-" .. math.random(11111, 99999) .. "-" .. math.random(1111, 9999) .. "-" .. math.random(111111, 999999) .. math.random(1111111, 9999999) .. (sValue.Value * 6) ^ 2 + 18
    end
    
    task.spawn(function()
        while true do
            task.wait(2)
            game:GetService("ReplicatedStorage").ACDetect:FireServer(sValue.Value, constructAnticheatString())
        end
    end)
    
    anticheat.Disabled = true
end

-- Funções públicas para controle externo
local HitboxController = {
    -- Ativar/Desativar
    Toggle = function(state)
        Settings.Toggled = state
        updatePlayers()
    end,
    
    -- Configurar tamanho
    SetSize = function(size)
        Settings.Size = math.clamp(size, 2, 100)
        updatePlayers()
    end,
    
    -- Configurar transparência
    SetTransparency = function(transparency)
        Settings.Transparency = math.clamp(transparency, 0, 1)
        updatePlayers()
    end,
    
    -- Configurar partes do corpo
    SetBodyParts = function(parts)
        Settings.BodyParts = parts
        updatePlayers()
    end,
    
    -- Configurar parte customizada
    SetCustomPart = function(partName)
        Settings.CustomPartName = partName
        updatePlayers()
    end,
    
    -- Ignorar jogador específico
    IgnorePlayer = function(playerName)
        Settings.IgnorePlayers[playerName] = true
        updatePlayers()
    end,
    
    -- Deixar de ignorar jogador
    UnignorePlayer = function(playerName)
        Settings.IgnorePlayers[playerName] = nil
        updatePlayers()
    end,
    
    -- Configurar ignorar próprio time
    SetIgnoreOwnTeam = function(state)
        Settings.IgnoreOwnTeam = state
        updatePlayers()
    end,
    
    -- Ignorar time específico
    IgnoreTeam = function(teamName)
        Settings.IgnoreTeams[teamName] = true
        updatePlayers()
    end,
    
    -- Deixar de ignorar time
    UnignoreTeam = function(teamName)
        Settings.IgnoreTeams[teamName] = nil
        updatePlayers()
    end,
    
    -- Configurar colisões
    SetCollisions = function(state)
        Settings.CollisionsEnabled = state
        updatePlayers()
    end,
    
    -- Configurar verificação de sentado
    SetSitCheck = function(state)
        Settings.SitCheck = state
        updatePlayers()
    end,
    
    -- Configurar verificação de forcefield
    SetFFCheck = function(state)
        Settings.FFCheck = state
        updatePlayers()
    end,
    
    -- Obter configurações atuais
    GetSettings = function()
        return Settings
    end,
    
    -- Forçar atualização
    ForceUpdate = function()
        updatePlayers()
    end
}

-- Finaliza carregamento
getgenv().HitboxLoaded = true
updatePlayers()

-- Retorna o controller para uso externo
return HitboxController
