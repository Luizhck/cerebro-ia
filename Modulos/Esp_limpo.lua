-- ============================================
-- ESP LIMPO (MINIMALISTA + CÍRCULO + TRANSPARENTE)
-- Versão: 1.4 (CORES MAIS FRACAS E CÍRCULO VISÍVEL)
-- ============================================

local ESP_LIMPO = {}

-- ============================================
-- CORES MINIMALISTAS (MAIS FRACAS)
-- ============================================
local CORES = {
    INIMIGO = Color3.fromRGB(200, 100, 100),   -- ⬅️ Vermelho mais fraco
    AMIGO = Color3.fromRGB(100, 200, 100),     -- ⬅️ Verde mais fraco
    MARCADO = Color3.fromRGB(255, 200, 100),   -- ⬅️ Amarelo mais fraco
    NPC = Color3.fromRGB(150, 150, 200),       -- ⬅️ Azul mais fraco
    WHITELIST = Color3.fromRGB(100, 200, 150), -- ⬅️ Verde menta
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
    
    -- === BOX MAIS TRANSPARENTE ===
    d.Box.Filled = false
    d.Box.Thickness = 1
    d.Box.Transparency = 0.6  -- ⬅️ MAIS TRANSPARENTE (era 0.3)
    
    -- === HEALTH BAR ===
    d.HealthBar.Filled = true
    d.HealthBar.Thickness = 0.5
    d.HealthBarOutline.Filled = true
    d.HealthBarOutline.Thickness = 0.5
    
    -- === NAME MENOR E MAIS TRANSPARENTE ===
    d.Name.Outline = true
    d.Name.OutlineColor = Color3.new(0, 0, 0)
    d.Name.Size = 10          -- ⬅️ MENOR (era 11)
    d.Name.Transparency = 0.5 -- ⬅️ MAIS TRANSPARENTE (era 0.4)
    d.Name.Center = true
    
    -- === HEALTH TEXT MENOR ===
    d.HealthText.Outline = true
    d.HealthText.OutlineColor = Color3.new(0, 0, 0)
    d.HealthText.Size = 8     -- ⬅️ MENOR (era 9)
    d.HealthText.Center = true
    d.HealthText.Transparency = 0.4
    
    -- === CÍRCULO AO REDOR (MAIS VISÍVEL) ===
    d.LineCircle.Thickness = 1.5
    d.LineCircle.Filled = false
    d.LineCircle.Transparency = 0.4  -- ⬅️ MENOS TRANSPARENTE (era 0.5)
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
        
        if not char or not hum or hum.Health <= 0 or not root then
            drawings.Box.Visible = false
            drawings.Name.Visible = false
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
            drawings.LineCircle.Visible = false
            continue
        end
        
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
        local isWhitelisted = false
        for _, id in pairs(Config.Aimbot.Whitelist) do
            if id == player.UserId then
                isWhitelisted = true
                break
            end
        end
        
        local isTeammate = (player.Team == LocalPlayer.Team)
        local teamColor = player.TeamColor.Color
        
        local isMarked = false
        for _, id in pairs(Config.AI_Kill.KillList) do
            if id == player.UserId then
                isMarked = true
                break
            end
        end
        
        -- ===== DEFINE CORES (MAIS FRACAS) =====
        local corEquipe
        
        if isWhitelisted then
            corEquipe = CORES.WHITELIST
        elseif isMarked then
            corEquipe = CORES.MARCADO
        elseif Config.ESP.UseGlobalColor and not Config.ESP.TeamCheck then
            local r = Config.ESP.GlobalColor.R / 255 * 0.7  -- ⬅️ 70% da cor global
            local g = Config.ESP.GlobalColor.G / 255 * 0.7
            local b = Config.ESP.GlobalColor.B / 255 * 0.7
            corEquipe = Color3.new(r, g, b)
        elseif isTeammate then
            corEquipe = CORES.AMIGO
        else
            -- ⬅️ COR DO TIME MAIS FRACA (70%)
            local r = teamColor.R * 0.7
            local g = teamColor.G * 0.7
            local b = teamColor.B * 0.7
            corEquipe = Color3.new(r, g, b)
        end
        
        -- ===== POSIÇÕES =====
        local topScreen = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
        local bottomScreen = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 4, 0))
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
            drawings.LineCircle.Visible = false
            continue
        end
        
        -- ===== BOX (MAIS TRANSPARENTE) =====
        if Config.ESP.Boxes then
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            drawings.Box.Color = corEquipe
            drawings.Box.Transparency = 0.6  -- ⬅️ MAIS TRANSPARENTE
            drawings.Box.Visible = true
        else
            drawings.Box.Visible = false
        end
        
        -- ===== NAME (MENOR E MAIS TRANSPARENTE) =====
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
            drawings.Name.Transparency = 0.5  -- ⬅️ MAIS TRANSPARENTE
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ===== HEALTH BAR =====
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
            drawings.HealthText.Transparency = 0.4
            drawings.HealthText.Visible = true
        else
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
        end
        
        -- ===== CÍRCULO AO REDOR (ESP LINES) =====
        if Config.ESP.Lines then
            local raio = math.max(width, height) * 0.7  -- ⬅️ MAIOR (era 0.6)
            drawings.LineCircle.Position = Vector2.new(pos.X, pos.Y)
            drawings.LineCircle.Radius = raio
            drawings.LineCircle.Color = corEquipe
            drawings.LineCircle.Thickness = 1.5
            drawings.LineCircle.Transparency = 0.4  -- ⬅️ MENOS TRANSPARENTE
            drawings.LineCircle.Visible = true
        else
            drawings.LineCircle.Visible = false
        end
    end
end

return ESP_LIMPO
