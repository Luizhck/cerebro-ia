-- ============================================================
-- 🚀 ESP ULTRA - O MELHOR ESP QUE VOCÊ JÁ VIU!
-- Versão: 2.0 (COMPLETO, MODERNO E OTIMIZADO)
-- ============================================================

local ESP_ULTRA = {}

-- ============================================================
-- 🎨 SISTEMA DE CORES INTELIGENTE
-- ============================================================
local CORES = {
    -- Cores base (suaves)
    INIMIGO = Color3.fromRGB(255, 80, 80),
    AMIGO = Color3.fromRGB(80, 255, 80),
    MARCADO = Color3.fromRGB(255, 200, 50),
    NPC = Color3.fromRGB(150, 150, 255),
    WHITELIST = Color3.fromRGB(100, 255, 150),
    
    -- Cores de status
    BAIXA_VIDA = Color3.fromRGB(255, 50, 50),
    MEDIA_VIDA = Color3.fromRGB(255, 200, 50),
    ALTA_VIDA = Color3.fromRGB(50, 255, 50),
    
    -- Cores de distância
    PERTO = Color3.fromRGB(0, 255, 100),
    MEDIO = Color3.fromRGB(255, 200, 0),
    LONGE = Color3.fromRGB(255, 50, 50),
    
    -- Cores de destaque
    HEADSHOT = Color3.fromRGB(255, 0, 255),
    KILL = Color3.fromRGB(255, 255, 0),
}

-- ============================================================
-- 📊 CONFIGURAÇÕES DO ESP
-- ============================================================
local CONFIG = {
    Box = { Ativo = true, Transparencia = 0.3, Espessura = 1.5 },
    Name = { Ativo = true, Tamanho = 12, Transparencia = 0.4 },
    Health = { Ativo = true, Largura = 4, Transparencia = 0.3 },
    Circle = { Ativo = true, Raio = 0.7, Espessura = 2, Transparencia = 0.3 },
    Tracer = { Ativo = false, Espessura = 1, Transparencia = 0.5 },
    Distance = { Ativo = true, Tamanho = 9, Transparencia = 0.5 },
    Weapon = { Ativo = true, Tamanho = 9, Transparencia = 0.5 },
    Status = { Ativo = true, Tamanho = 9, Transparencia = 0.5 },
    Skeleton = { Ativo = false, Espessura = 1, Transparencia = 0.4 },
    Glow = { Ativo = false, Intensidade = 0.3 },
}

-- ============================================================
-- 🎨 FUNÇÃO DE CRIAÇÃO DE DRAWINGS
-- ============================================================
function ESP_ULTRA.CriarDrawings(player, espDrawings)
    if espDrawings[player] then return end
    
    espDrawings[player] = {
        -- Desenhos base
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        
        -- Círculo ao redor
        Circle = Drawing.new("Circle"),
        
        -- Tracer (linha do rodapé)
        Tracer = Drawing.new("Line"),
        
        -- Distância
        Distance = Drawing.new("Text"),
        
        -- Status (Vivo/Morto)
        Status = Drawing.new("Text"),
        
        -- Chams (opcional)
        Chams = nil,
        
        customColor = nil,
        lastUpdate = 0
    }
    
    local d = espDrawings[player]
    
    -- === BOX ===
    d.Box.Filled = false
    d.Box.Thickness = CONFIG.Box.Espessura
    d.Box.Transparency = CONFIG.Box.Transparencia
    
    -- === NAME ===
    d.Name.Outline = true
    d.Name.OutlineColor = Color3.new(0, 0, 0)
    d.Name.Size = CONFIG.Name.Tamanho
    d.Name.Transparency = CONFIG.Name.Transparencia
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
    d.Circle.Thickness = CONFIG.Circle.Espessura
    d.Circle.Filled = false
    d.Circle.Transparency = CONFIG.Circle.Transparencia
    d.Circle.Visible = false
    d.Circle.ZIndex = 5
    
    -- === TRACER ===
    d.Tracer.Thickness = CONFIG.Tracer.Espessura
    d.Tracer.Transparency = CONFIG.Tracer.Transparencia
    d.Tracer.Visible = false
    d.Tracer.ZIndex = 1
    
    -- === DISTÂNCIA ===
    d.Distance.Outline = true
    d.Distance.OutlineColor = Color3.new(0, 0, 0)
    d.Distance.Size = CONFIG.Distance.Tamanho
    d.Distance.Transparency = CONFIG.Distance.Transparencia
    d.Distance.Center = true
    
    -- === STATUS ===
    d.Status.Outline = true
    d.Status.OutlineColor = Color3.new(0, 0, 0)
    d.Status.Size = CONFIG.Status.Tamanho
    d.Status.Transparency = CONFIG.Status.Transparencia
    d.Status.Center = true
end

-- ============================================================
-- 🧠 FUNÇÃO INTELIGENTE DE CORES
-- ============================================================
local function GetCorInteligente(player, hum, dist, isTeammate, isWhitelisted, isMarked, Config)
    -- Prioridade: Whitelist > Marcado > Cor Global > Time > Inimigo
    if isWhitelisted then
        return CORES.WHITELIST
    elseif isMarked then
        return CORES.MARCADO
    elseif Config.ESP.UseGlobalColor and not Config.ESP.TeamCheck then
        return Color3RGB(Config.ESP.GlobalColor.R, Config.ESP.GlobalColor.G, Config.ESP.GlobalColor.B)
    elseif isTeammate then
        return CORES.AMIGO
    end
    
    -- Cor baseada na distância (para inimigos)
    if dist < 50 then
        return CORES.PERTO
    elseif dist < 150 then
        return CORES.MEDIO
    else
        return CORES.LONGE
    end
end

-- ============================================================
-- 📊 FUNÇÃO DE STATUS
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
-- 🎯 ATUALIZA O ESP - FUNÇÃO PRINCIPAL
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
            d.Tracer.Visible = false
            d.Distance.Visible = false
            d.Status.Visible = false
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
            drawings.Tracer:Remove()
            drawings.Distance:Remove()
            drawings.Status:Remove()
            espDrawings[player] = nil
            continue
        end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and GetRootPart(char)
        
        if not char or not hum or hum.Health <= 0 or not root then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            continue
        end
        
        -- ============================================================
        -- CÁLCULO DE DISTÂNCIA E VISIBILIDADE
        -- ============================================================
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > Config.ESP.ESPMaxDistance then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.Circle.Visible = false
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
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
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
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
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
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
        -- CORES INTELIGENTES
        -- ============================================================
        local corEquipe = GetCorInteligente(player, hum, dist, isTeammate, isWhitelisted, isMarked, Config)
        
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
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
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
            drawings.Tracer.Visible = false
            drawings.Distance.Visible = false
            drawings.Status.Visible = false
            continue
        end
        
        -- ============================================================
        -- 🎨 DESENHO DO BOX
        -- ============================================================
        if CONFIG.Box.Ativo and Config.ESP.Boxes then
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            drawings.Box.Color = corEquipe
            drawings.Box.Transparency = CONFIG.Box.Transparencia
            drawings.Box.Visible = true
        else
            drawings.Box.Visible = false
        end
        
        -- ============================================================
        -- 📝 NAME COM STATUS
        -- ============================================================
        if CONFIG.Name.Ativo and Config.ESP.Names then
            local status = GetStatus(hum)
            local nameText = status .. " " .. player.Name
            
            if isMarked then
                nameText = "⚡ " .. nameText
            elseif isWhitelisted then
                nameText = "✦ " .. nameText
            end
            
            if CONFIG.Weapon.Ativo and Config.ESP.ShowWeapon then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    nameText = nameText .. " [" .. tool.Name .. "]"
                end
            end
            
            drawings.Name.Text = nameText
            drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 18)
            drawings.Name.Color = corEquipe
            drawings.Name.Transparency = CONFIG.Name.Transparencia
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ============================================================
        -- 💚 HEALTH BAR INTELIGENTE
        -- ============================================================
        if CONFIG.Health.Ativo and Config.ESP.Health then
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            
            -- Cor da barra baseada na vida
            local corVida
            if healthPercent > 0.6 then
                corVida = CORES.ALTA_VIDA
            elseif healthPercent > 0.3 then
                corVida = CORES.MEDIA_VIDA
            else
                corVida = CORES.BAIXA_VIDA
            end
            
            -- Outline
            drawings.HealthBarOutline.Size = Vector2.new(4, height)
            drawings.HealthBarOutline.Position = Vector2.new(boxPos.X - 6, boxPos.Y)
            drawings.HealthBarOutline.Color = Color3.new(0.1, 0.1, 0.1)
            drawings.HealthBarOutline.Transparency = 0.2
            drawings.HealthBarOutline.Visible = true
            
            -- Barra
            drawings.HealthBar.Size = Vector2.new(2, height * healthPercent)
            drawings.HealthBar.Position = Vector2.new(boxPos.X - 5, boxPos.Y + (height * (1 - healthPercent)))
            drawings.HealthBar.Color = corVida
            drawings.HealthBar.Transparency = CONFIG.Health.Transparencia
            drawings.HealthBar.Visible = true
            
            -- Texto
            drawings.HealthText.Text = math.floor(healthPercent * 100) .. "%"
            drawings.HealthText.Position = Vector2.new(pos.X, boxPos.Y - (CONFIG.Name.Ativo and Config.ESP.Names and 34 or 16))
            drawings.HealthText.Color = corEquipe
            drawings.HealthText.Transparency = 0.4
            drawings.HealthText.Visible = true
        else
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
        end
        
        -- ============================================================
        -- ⭕ CÍRCULO AO REDOR (ESP LINES MODERNO)
        -- ============================================================
        if CONFIG.Circle.Ativo and Config.ESP.Lines then
            local raio = math.max(width, height) * CONFIG.Circle.Raio
            drawings.Circle.Position = Vector2.new(pos.X, pos.Y)
            drawings.Circle.Radius = raio
            drawings.Circle.Color = corEquipe
            drawings.Circle.Thickness = CONFIG.Circle.Espessura
            drawings.Circle.Transparency = CONFIG.Circle.Transparencia
            drawings.Circle.Visible = true
        else
            drawings.Circle.Visible = false
        end
        
        -- ============================================================
        -- 📏 DISTÂNCIA
        -- ============================================================
        if CONFIG.Distance.Ativo then
            drawings.Distance.Text = math.floor(dist) .. "m"
            drawings.Distance.Position = Vector2.new(pos.X, boxPos.Y + height + 10)
            drawings.Distance.Color = corEquipe
            drawings.Distance.Transparency = CONFIG.Distance.Transparencia
            drawings.Distance.Visible = true
        else
            drawings.Distance.Visible = false
        end
        
        -- ============================================================
        -- 📍 TRACER (LINHA DO RODAPÉ) - DESATIVADO POR PADRÃO
        -- ============================================================
        if CONFIG.Tracer.Ativo then
            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            drawings.Tracer.To = Vector2.new(pos.X, pos.Y)
            drawings.Tracer.Color = corEquipe
            drawings.Tracer.Thickness = CONFIG.Tracer.Espessura
            drawings.Tracer.Transparency = CONFIG.Tracer.Transparencia
            drawings.Tracer.Visible = true
        else
            drawings.Tracer.Visible = false
        end
        
        -- ============================================================
        -- 📊 STATUS (VIVO/MORTO/BAIXA VIDA)
        -- ============================================================
        if CONFIG.Status.Ativo then
            local status = GetStatus(hum)
            local corStatus = corEquipe
            if status == "⚠️" then corStatus = CORES.BAIXA_VIDA end
            if status == "💀" then corStatus = Color3.new(0.3, 0.3, 0.3) end
            
            drawings.Status.Text = status
            drawings.Status.Position = Vector2.new(pos.X, boxPos.Y - 30)
            drawings.Status.Color = corStatus
            drawings.Status.Transparency = CONFIG.Status.Transparencia
            drawings.Status.Visible = true
        else
            drawings.Status.Visible = false
        end
    end
end

-- ============================================================
-- 🚀 FUNÇÃO PARA ALTERNAR CONFIGURAÇÕES (OPCIONAL)
-- ============================================================
function ESP_ULTRA.Toggle(modo, valor)
    if CONFIG[modo] then
        if type(CONFIG[modo]) == "table" then
            for k, v in pairs(valor) do
                CONFIG[modo][k] = v
            end
        else
            CONFIG[modo] = valor
        end
        return true
    end
    return false
end

return ESP_ULTRA
