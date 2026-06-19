-- ============================================
-- ESP LIMPO (MINIMALISTA + CÍRCULO)
-- Versão: 1.0
-- Desenvolvido por: LRMODS
-- ============================================

local ESP_LIMPO = {}

-- ============================================
-- CORES MINIMALISTAS
-- ============================================
local CORES = {
    INIMIGO = Color3.fromRGB(255, 80, 80),      -- Vermelho suave
    AMIGO = Color3.fromRGB(80, 255, 80),        -- Verde suave
    MARCADO = Color3.fromRGB(255, 200, 50),     -- Amarelo
    NPC = Color3.fromRGB(180, 180, 255),        -- Azul claro
    WHITELIST = Color3.fromRGB(100, 255, 150),  -- Verde menta
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
        LineCircle = Drawing.new("Circle"),  -- ⬅️ Círculo ao redor (em vez de tracer)
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
    d.LineCircle.Thickness = 1
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
        local isWhitelisted = table.find(Config.Aimbot.Whitelist, player.UserId)
        local isTeammate = (player.Team == LocalPlayer.Team)
        local isMarked = table.find(Config.AI_Kill.KillList, player.UserId)
        
        -- ===== CORES MINIMALISTAS =====
        local corEquipe
        if isWhitelisted then
            corEquipe = CORES.WHITELIST
        elseif isMarked then
            corEquipe = CORES.MARCADO
        elseif Config.ESP.UseGlobalColor and not Config.ESP.TeamCheck then
            corEquipe = Color3RGB(Config.ESP.GlobalColor.R, Config.ESP.GlobalColor.G, Config.ESP.GlobalColor.B)
        elseif isTeammate then
            corEquipe = CORES.AMIGO
        else
            corEquipe = CORES.INIMIGO
        end
        
      -- ===== POSIÇÕES =====
local topWorld = root.Position + Vector3New(0, 3, 0)
local bottomWorld = root.Position - Vector3New(0, 4, 0)
local topScreen = Camera:WorldToViewportPoint(topWorld)
local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)

-- ⬅️ VERIFICAÇÃO PARA EVITAR ERRO
if not topScreen or not bottomScreen then
    drawings.Box.Visible = false
    drawings.Name.Visible = false
    drawings.HealthBar.Visible = false
    drawings.HealthBarOutline.Visible = false
    drawings.HealthText.Visible = false
    drawings.LineCircle.Visible = false
    continue
end

local height = math.abs(topScreen.Y - bottomScreen.Y)
local width = height * 0.6
local boxPos = Vector2New(pos.X - width / 2, pos.Y - height / 2)
        
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
        
        -- ===== BOX SEMI-TRANSPARENTE =====
        if Config.ESP.Boxes then
            drawings.Box.Size = Vector2New(width, height)
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
            drawings.Name.Position = Vector2New(pos.X, boxPos.Y - 14)
            drawings.Name.Color = corEquipe
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ===== HEALTH BAR (GRADIENTE SUAVE) =====
        if Config.ESP.Health then
            local healthPercent = mathClamp(hum.Health / hum.MaxHealth, 0, 1)
            
            drawings.HealthBarOutline.Size = Vector2New(3, height)
            drawings.HealthBarOutline.Position = Vector2New(boxPos.X - 4, boxPos.Y)
            drawings.HealthBarOutline.Color = Color3.new(0.2, 0.2, 0.2)
            drawings.HealthBarOutline.Visible = true
            
            drawings.HealthBar.Size = Vector2New(2, height * healthPercent)
            drawings.HealthBar.Position = Vector2New(boxPos.X - 3, boxPos.Y + (height * (1 - healthPercent)))
            
            -- Gradiente: Verde -> Amarelo -> Vermelho
            local h = healthPercent
            drawings.HealthBar.Color = Color3.new(1 - h, h, 0)
            drawings.HealthBar.Visible = true
            
            drawings.HealthText.Text = math.floor(healthPercent * 100) .. "%"
            drawings.HealthText.Position = Vector2New(pos.X, boxPos.Y - (Config.ESP.Names and 28 or 14))
            drawings.HealthText.Color = corEquipe
            drawings.HealthText.Visible = true
        else
            drawings.HealthBar.Visible = false
            drawings.HealthBarOutline.Visible = false
            drawings.HealthText.Visible = false
        end
        
        -- ===== CÍRCULO AO REDOR (EM VEZ DE TRACER) =====
        if Config.ESP.Lines then
            local raio = math.max(width, height) * 0.6
            drawings.LineCircle.Position = Vector2New(pos.X, pos.Y)
            drawings.LineCircle.Radius = raio
            drawings.LineCircle.Color = corEquipe
            drawings.LineCircle.Visible = true
        else
            drawings.LineCircle.Visible = false
        end
    end
end

return ESP_LIMPO
