-- ============================================================
-- 🚀 ESP ULTRA - COMPLETO E MODERNO
-- Versão: 3.0 (COM PAINEL DE CONTROLE DEDICADO)
-- ============================================================

local ESP_ULTRA = {}

-- ============================================================
-- 📊 CONFIGURAÇÕES DO ESP (CONTROLADAS PELO PAINEL)
-- ============================================================
local CONFIG = {
    -- Elementos visuais
    Box = true,
    Name = true,
    Health = true,
    Circle = true,
    Tracer = false,
    Distance = true,
    Status = true,
    Skeleton = false,
    HeadDot = true,
    
    -- Transparências
    BoxTransparency = 0.3,
    NameTransparency = 0.4,
    CircleTransparency = 0.3,
    
    -- Tamanhos
    CircleRadius = 0.7,
    NameSize = 11,
    TextSize = 11,
    
    -- Distância máxima
    MaxDistance = 5000,
}

-- ============================================================
-- 🎨 CORES
-- ============================================================
local CORES = {
    INIMIGO = Color3.fromRGB(255, 80, 80),
    AMIGO = Color3.fromRGB(80, 255, 80),
    MARCADO = Color3.fromRGB(255, 200, 50),
    WHITELIST = Color3.fromRGB(100, 255, 150),
    PERTO = Color3.fromRGB(0, 255, 100),
    MEDIO = Color3.fromRGB(255, 200, 0),
    LONGE = Color3.fromRGB(255, 50, 50),
}

-- ============================================================
-- 🧠 FUNÇÃO DE STATUS
-- ============================================================
local function GetStatus(hum)
    if not hum then return "💀" end
    local hp = hum.Health / hum.MaxHealth
    if hp <= 0 then return "💀"
    elseif hp < 0.25 then return "⚠️"
    elseif hp < 0.5 then return "⚡"
    else return "✅" end
end

-- ============================================================
-- 🎨 FUNÇÃO DE COR INTELIGENTE
-- ============================================================
local function GetCorInteligente(player, dist, isTeammate, isWhitelisted, isMarked, Config)
    if isWhitelisted then return CORES.WHITELIST end
    if isMarked then return CORES.MARCADO end
    if isTeammate then return CORES.AMIGO end
    
    if dist < 50 then return CORES.PERTO
    elseif dist < 150 then return CORES.MEDIO
    else return CORES.LONGE end
end

-- ============================================================
-- 📦 CRIA DRAWINGS
-- ============================================================
function ESP_ULTRA.CriarDrawings(player, espDrawings)
    if espDrawings[player] then return end
    
    espDrawings[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        Circle = Drawing.new("Circle"),
        Distance = Drawing.new("Text"),
        Status = Drawing.new("Text"),
        HeadDot = Drawing.new("Circle"),
        Tracer = Drawing.new("Line"),
        customColor = nil,
        lastUpdate = 0
    }
    
    local d = espDrawings[player]
    
    -- === BOX ===
    d.Box.Filled = false
    d.Box.Thickness = 1.5
    d.Box.Transparency = CONFIG.BoxTransparency
    
    -- === NAME ===
    d.Name.Outline = true
    d.Name.OutlineColor = Color3.new(0, 0, 0)
    d.Name.Size = CONFIG.NameSize
    d.Name.Transparency = CONFIG.NameTransparency
    d.Name.Center = true
    
    -- === HEALTH ===
    d.HealthBar.Filled = true
    d.HealthBar.Thickness = 0.5
    d.HealthBarOutline.Filled = true
    d.HealthBarOutline.Thickness = 0.5
    d.HealthBarOutline.Transparency = 0.3
    
    -- === HEALTH TEXT ===
    d.HealthText.Outline = true
    d.HealthText.OutlineColor = Color3.new(0, 0, 0)
    d.HealthText.Size = 8
    d.HealthText.Center = true
    d.HealthText.Transparency = 0.4
    
    -- === CÍRCULO ===
    d.Circle.Thickness = 2
    d.Circle.Filled = false
    d.Circle.Transparency = CONFIG.CircleTransparency
    d.Circle.Visible = false
    d.Circle.ZIndex = 5
    
    -- === DISTÂNCIA ===
    d.Distance.Outline = true
    d.Distance.OutlineColor = Color3.new(0, 0, 0)
    d.Distance.Size = 9
    d.Distance.Transparency = 0.5
    d.Distance.Center = true
    
    -- === STATUS ===
    d.Status.Outline = true
    d.Status.OutlineColor = Color3.new(0, 0, 0)
    d.Status.Size = 12
    d.Status.Transparency = 0.3
    d.Status.Center = true
    
    -- === HEAD DOT ===
    d.HeadDot.Filled = true
    d.HeadDot.Radius = 3
    d.HeadDot.Transparency = 0.2
    
    -- === TRACER ===
    d.Tracer.Thickness = 1
    d.Tracer.Transparency = 0.5
    d.Tracer.Visible = false
end

-- ============================================================
-- 🔄 FUNÇÃO PARA ATUALIZAR CONFIGURAÇÕES
-- ============================================================
function ESP_ULTRA.AtualizarConfig(novaConfig)
    for k, v in pairs(novaConfig) do
        CONFIG[k] = v
    end
    print("⚙️ Configurações do ESP Ultra atualizadas!")
end

-- ============================================================
-- 🎯 ATUALIZA O ESP
-- ============================================================
function ESP_ULTRA.Atualizar(espDrawings, Players, LocalPlayer, Camera, Config, _STR, GetRootPart)
    if not Config.ESP.Enabled then
        for _, d in pairs(espDrawings) do
            d.Box.Visible = false
            d.Name.Visible = false
            d.HealthBar.Visible = false
            d.HealthBarOutline.Visible = false
            d.HealthText.Visible = false
            d.Circle.Visible = false
            d.Distance.Visible = false
            d.Status.Visible = false
            d.HeadDot.Visible = false
            d.Tracer.Visible = false
        end
        return
    end
    
    local localChar = LocalPlayer.Character
    if not localChar then return end
    
    for player, drawings in pairs(espDrawings) do
        -- ============================================================
        -- VALIDAÇÃO DO JOGADOR
        -- ============================================================
        if not player or not player.Parent then
            drawings.Box:Remove()
            drawings.Name:Remove()
            drawings.HealthBar:Remove()
            drawings.HealthBarOutline:Remove()
            drawings.HealthText:Remove()
            drawings.Circle:Remove()
            drawings.Distance:Remove()
            drawings.Status:Remove()
            drawings.HeadDot:Remove()
            drawings.Tracer:Remove()
            espDrawings[player] = nil
            continue
        end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and GetRootPart(char)
        local head = char and char:FindFirstChild("Head")
        
        if not char or not hum or hum.Health <= 0 or not root then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        -- ============================================================
        -- CÁLCULO DE DISTÂNCIA
        -- ============================================================
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > CONFIG.MaxDistance then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        -- Verifica se está atrás da câmera
        local dot = Camera.CFrame.LookVector:Dot((root.Position - Camera.CFrame.Position).Unit)
        if dot < -0.1 then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        -- Projeção na tela
        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        -- ============================================================
        -- VERIFICAÇÕES
        -- ============================================================
        local isWhitelisted = false
        for _, id in pairs(Config.Aimbot.Whitelist) do
            if id == player.UserId then isWhitelisted = true break end
        end
        
        local isTeammate = (player.Team == LocalPlayer.Team)
        local isMarked = false
        for _, id in pairs(Config.AI_Kill.KillList) do
            if id == player.UserId then isMarked = true break end
        end
        
        -- ============================================================
        -- CORES
        -- ============================================================
        local corEquipe = GetCorInteligente(player, dist, isTeammate, isWhitelisted, isMarked, Config)
        
        -- ============================================================
        -- POSIÇÕES
        -- ============================================================
        local topScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
        local bottomScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 4, 0))
        
        if not topScreen or not bottomScreen then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        local height = math.abs(topScreen.Y - bottomScreen.Y)
        local width = height * 0.6
        local boxPos = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
        
        -- Team Check
        if Config.ESP.TeamCheck and isTeammate and not isWhitelisted then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            drawings.HeadDot.Visible = false
            drawings.Tracer.Visible = false
            continue
        end
        
        -- ============================================================
        -- 📦 BOX
        -- ============================================================
        if CONFIG.Box and Config.ESP.Boxes then
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            drawings.Box.Color = corEquipe
            drawings.Box.Transparency = CONFIG.BoxTransparency
            drawings.Box.Visible = true
        else
            drawings.Box.Visible = false
        end
        
        -- ============================================================
        -- 📝 NAME
        -- ============================================================
        if CONFIG.Name and Config.ESP.Names then
            local status = GetStatus(hum)
            local nameText = player.Name
            
            if isMarked then
                nameText = "⚡ " .. nameText
            elseif isWhitelisted then
                nameText = "✦ " .. nameText
            end
            
            drawings.Name.Text = nameText
            drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 16)
            drawings.Name.Color = corEquipe
            drawings.Name.Size = CONFIG.NameSize
            drawings.Name.Transparency = CONFIG.NameTransparency
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ============================================================
        -- 💚 HEALTH
        -- ============================================================
        if CONFIG.Health and Config.ESP.Health then
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            
            local corVida
            if healthPercent > 0.6 then corVida = Color3.new(0, 1, 0)
            elseif healthPercent > 0.3 then corVida = Color3.new(1, 1, 0)
            else corVida = Color3.new(1, 0, 0) end
            
            drawings.HealthBarOutline.Size = Vector2.new(4, height)
            drawings.HealthBarOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
            drawings.HealthBarOutline.Color = Color3.new(0.1, 0.1, 0.1)
            drawings.HealthBarOutline.Visible = true
            
            drawings.HealthBar.Size = Vector2.new(2, height * healthPercent)
            drawings.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (height * (1 - healthPercent)))
            drawings.HealthBar.Color = corVida
            drawings.HealthBar.Visible = true
            
            drawings.HealthText.Text = math.floor(healthPercent * 100) .. "%"
            drawings.HealthText.Position = Vector2.new(pos.X, boxPos.Y - (CONFIG.Name and 32 or 16))
            drawings.HealthText.Color = corEquipe
            drawings.HealthText.Visible = true
        else
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
        end
        
        -- ============================================================
        -- ⭕ CÍRCULO (ESP LINES)
        -- ============================================================
        if CONFIG.Circle and Config.ESP.Lines then
            local raio = math.max(width, height) * CONFIG.CircleRadius
            drawings.Circle.Position = Vector2.new(pos.X, pos.Y)
            drawings.Circle.Radius = raio
            drawings.Circle.Color = corEquipe
            drawings.Circle.Thickness = 2
            drawings.Circle.Transparency = CONFIG.CircleTransparency
            drawings.Circle.Visible = true
        else
            drawings.Circle.Visible = false
        end
        
        -- ============================================================
        -- 📏 DISTÂNCIA
        -- ============================================================
        if CONFIG.Distance then
            drawings.Distance.Text = math.floor(dist) .. "m"
            drawings.Distance.Position = Vector2.new(pos.X, boxPos.Y + height + 10)
            drawings.Distance.Color = corEquipe
            drawings.Distance.Visible = true
        else
            drawings.Distance.Visible = false
        end
        
        -- ============================================================
        -- 📊 STATUS
        -- ============================================================
        if CONFIG.Status then
            local status = GetStatus(hum)
            drawings.Status.Text = status
            drawings.Status.Position = Vector2.new(pos.X, boxPos.Y - 30)
            drawings.Status.Color = corEquipe
            drawings.Status.Visible = true
        else
            drawings.Status.Visible = false
        end
        
        -- ============================================================
        -- 🎯 HEAD DOT
        -- ============================================================
        if CONFIG.HeadDot and head then
            local headPos, headOn = Camera:WorldToViewportPoint(head.Position)
            if headOn then
                drawings.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                drawings.HeadDot.Color = corEquipe
                drawings.HeadDot.Radius = 3
                drawings.HeadDot.Visible = true
            else
                drawings.HeadDot.Visible = false
            end
        else
            drawings.HeadDot.Visible = false
        end
        
        -- ============================================================
        -- 📍 TRACER
        -- ============================================================
        if CONFIG.Tracer then
            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
            drawings.Tracer.Color = corEquipe
            drawings.Tracer.Thickness = 1
            drawings.Tracer.Transparency = 0.5
            drawings.Tracer.Visible = true
        else
            drawings.Tracer.Visible = false
        end
    end
end

-- ============================================================
-- 🔧 FUNÇÃO PARA ALTERNAR CONFIGURAÇÕES
-- ============================================================
function ESP_ULTRA.Toggle(modo)
    if CONFIG[modo] ~= nil then
        CONFIG[modo] = not CONFIG[modo]
        print("⚙️ " .. modo .. " = " .. tostring(CONFIG[modo]))
        return CONFIG[modo]
    end
    return nil
end

-- ============================================================
-- 📊 FUNÇÃO PARA OBTER CONFIGURAÇÕES
-- ============================================================
function ESP_ULTRA.GetConfig()
    return CONFIG
end

return ESP_ULTRA
