-- ============================================
-- ESP LIMPO (MINIMALISTA + CÍRCULO)
-- Versão: 1.3 (COMPLETA - COM TEAM COLOR E LINES)
-- ============================================

local ESP_LIMPO = {}

-- ============================================
-- CORES MINIMALISTAS
-- ============================================
local CORES = {
    INIMIGO = Color3.fromRGB(255, 80, 80),
    AMIGO = Color3.fromRGB(80, 255, 80),
    MARCADO = Color3.fromRGB(255, 200, 50),
    NPC = Color3.fromRGB(180, 180, 255),
    WHITELIST = Color3.fromRGB(100, 255, 150),
}

-- ============================================
-- CRIA DRAWINGS PARA UM JOGADOR
-- ============================================
function ESP_LIMPO.CriarDrawings(player, espDrawings)
    if espDrawings[player] then return end
    
    espDrawings[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        LineCircle = Drawing.new("Circle"),
        customColor = nil,
        lastUpdate = 0
    }
    
    local d = espDrawings[player]
    
    -- === BOX SEMI-TRANSPARENTE ===
    d.Box.Filled = false
    d.Box.Thickness = 1.5
    d.Box.Transparency = 0.3
    
    -- === HEALTH BAR ===
    d.HealthBar.Filled = true
    d.HealthBar.Thickness = 0.5
    d.HealthBarOutline.Filled = true
    d.HealthBarOutline.Thickness = 0.5
    
    -- === NAME (PEQUENO E TRANSPARENTE) ===
    d.Name.Outline = true
    d.Name.OutlineColor = Color3.new(0, 0, 0)
    d.Name.Size = 11
    d.Name.Transparency = 0.4
    d.Name.Center = true
    
    -- === HEALTH TEXT ===
    d.HealthText.Outline = true
    d.HealthText.OutlineColor = Color3.new(0, 0, 0)
    d.HealthText.Size = 9
    d.HealthText.Center = true
    d.HealthText.Transparency = 0.3
    
    -- === CÍRCULO AO REDOR ===
    d.LineCircle.Thickness = 1.5
    d.LineCircle.Filled = false
    d.LineCircle.Transparency = 0.5
    d.LineCircle.Visible = false
end

-- ============================================
-- ATUALIZA O ESP (ESTILO LIMPO)
-- ============================================
function ESP_LIMPO.Atualizar(espDrawings, Players, LocalPlayer, Camera, Config, _STR, GetRootPart)
    if not Config.ESP.Enabled then
        for _, d in pairs(espDrawings) do
            d.Box.Visible = false
            d.Name.Visible = false
            d.HealthBar.Visible = false
            d.HealthBarOutline.Visible = false
            d.HealthText.Visible = false
            d.LineCircle.Visible = false
        end
        return
    end
    
    local localChar = LocalPlayer.Character
    if not localChar then return end
    
    for player, drawings in pairs(espDrawings) do
        -- Verifica se o player ainda existe
        if not player or not player.Parent then
            drawings.Box:Remove()
            drawings.Name:Remove()
            drawings.HealthBar:Remove()
            drawings.HealthBarOutline:Remove()
            drawings.HealthText:Remove()
            drawings.LineCircle:Remove()
            espDrawings[player] = nil
            continue
        end
        
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and GetRootPart(char)
        
        -- Validação
        if not char or not hum or hum.Health <= 0 or not root then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.LineCircle.Visible = false
            continue
        end
        
        -- Distância
        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > Config.ESP.ESPMaxDistance then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.LineCircle.Visible = false
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
            drawings.LineCircle.Visible = false
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
            drawings.LineCircle.Visible = false
            continue
        end
        
        -- ===== VERIFICAÇÕES =====
        -- ✅ WHITELIST (Amigos)
        local isWhitelisted = false
        for _, id in pairs(Config.Aimbot.Whitelist) do
            if id == player.UserId then
                isWhitelisted = true
                break
            end
        end
        
        -- ✅ TEAM CHECK (Cor do time)
        local isTeammate = (player.Team == LocalPlayer.Team)
        local teamColor = player.TeamColor.Color  -- ⬅️ COR DO TIME
        
        -- ✅ KILL LIST (Alvos marcados)
        local isMarked = false
        for _, id in pairs(Config.AI_Kill.KillList) do
            if id == player.UserId then
                isMarked = true
                break
            end
        end
        
        -- ===== DEFINE CORES (COM TEAM COLOR) =====
        local corEquipe
        
        -- AMIGO (WHITELIST) - VERDE
        if isWhitelisted then
            corEquipe = CORES.WHITELIST
        -- ALVO MARCADO - AMARELO
        elseif isMarked then
            corEquipe = CORES.MARCADO
        -- COR GLOBAL (se ativado)
        elseif Config.ESP.UseGlobalColor and not Config.ESP.TeamCheck then
            corEquipe = Color3RGB(Config.ESP.GlobalColor.R, Config.ESP.GlobalColor.G, Config.ESP.GlobalColor.B)
        -- TIME (usa a cor do time do jogador)
        elseif isTeammate then
            corEquipe = CORES.AMIGO
        else
            -- ⬅️ USA A COR DO TIME DO INIMIGO!
            corEquipe = teamColor
        end
        
        -- ===== POSIÇÕES =====
        local topScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
        local bottomScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 4, 0))
        local height = math.abs(topScreen.Y - bottomScreen.Y)
        local width = height * 0.6
        local boxPos = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
        
        -- Team Check: Se for time e NÃO estiver na whitelist, NÃO mostra
        if Config.ESP.TeamCheck and isTeammate and not isWhitelisted then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.LineCircle.Visible = false
            continue
        end
        
        -- ===== BOX SEMI-TRANSPARENTE =====
        if Config.ESP.Boxes then
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            drawings.Box.Color = corEquipe
            drawings.Box.Visible = true
        else
            drawings.Box.Visible = false
        end
        
        -- ===== NAME (PEQUENO E TRANSPARENTE) =====
        if Config.ESP.Names then
            local nameText = player.Name
            if isMarked then
                nameText = "⚡ " .. nameText
            elseif isWhitelisted then
                nameText = "✦ " .. nameText
            end
            
            if Config.ESP.ShowWeapon then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    nameText = nameText .. " " .. tool.Name
                end
            end
            
            drawings.Name.Text = nameText
            drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 14)
            drawings.Name.Color = corEquipe
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ===== HEALTH BAR (GRADIENTE SUAVE) =====
        if Config.ESP.Health then
            local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            
            drawings.HealthBarOutline.Size = Vector2.new(3, height)
            drawings.HealthBarOutline.Position = Vector2.new(boxPos.X - 4, boxPos.Y)
            drawings.HealthBarOutline.Color = Color3.new(0.2, 0.2, 0.2)
            drawings.HealthBarOutline.Visible = true
            
            drawings.HealthBar.Size = Vector2.new(2, height * healthPercent)
            drawings.HealthBar.Position = Vector2.new(boxPos.X - 3, boxPos.Y + (height * (1 - healthPercent)))
            drawings.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            drawings.HealthBar.Visible = true
            
            drawings.HealthText.Text = math.floor(healthPercent * 100) .. "%"
            drawings.HealthText.Position = Vector2.new(pos.X, boxPos.Y - (Config.ESP.Names and 28 or 14))
            drawings.HealthText.Color = corEquipe
            drawings.HealthText.Visible = true
        else
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
        end
        
        -- ===== CÍRCULO AO REDOR (ESP LINES) =====
        -- ✅ AGORA FUNCIONA COM Config.ESP.Lines!
        if Config.ESP.Lines then
            local raio = math.max(width, height) * 0.6
            drawings.LineCircle.Position = Vector2.new(pos.X, pos.Y)
            drawings.LineCircle.Radius = raio
            drawings.LineCircle.Color = corEquipe
            drawings.LineCircle.Thickness = 1.5
            drawings.LineCircle.Transparency = 0.5
            drawings.LineCircle.Visible = true
        else
            drawings.LineCircle.Visible = false
        end
    end
end

return ESP_LIMPO
