-- ============================================
-- ESP LIMPO (VERSÃO SIMPLIFICADA)
-- ============================================
local ESP_LIMPO = {}

function ESP_LIMPO.CriarDrawings(player, espDrawings)
    if espDrawings[player] then return end
    
    espDrawings[player] = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        HealthText = Drawing.new("Text"),
        LineCircle = Drawing.new("Circle"),
    }
    
    local d = espDrawings[player]
    d.Box.Filled = false
    d.Box.Thickness = 1.5
    d.Box.Transparency = 0.3
    d.HealthBar.Filled = true
    d.HealthBarOutline.Filled = true
    d.Name.Outline = true
    d.Name.Size = 11
    d.Name.Center = true
    d.HealthText.Outline = true
    d.HealthText.Size = 9
    d.HealthText.Center = true
    d.LineCircle.Thickness = 1
    d.LineCircle.Filled = false
    d.LineCircle.Transparency = 0.5
end

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
        
        -- ⬅️ CORES
        local corEquipe
        if player.Team == LocalPlayer.Team then
            corEquipe = Color3.fromRGB(80, 255, 80)
        else
            corEquipe = Color3.fromRGB(255, 80, 80)
        end
        
        -- ⬅️ POSIÇÕES
        local topWorld = root.Position + Vector3.new(0, 3, 0)
        local bottomWorld = root.Position - Vector3.new(0, 4, 0)
        local topScreen = Camera:WorldToViewportPoint(topWorld)
        local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)
        
        -- ⬅️ VERIFICAÇÃO DE SEGURANÇA
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
        local boxPos = Vector2.new(pos.X - width / 2, pos.Y - height / 2)
        
        -- ⬅️ BOX
        if Config.ESP.Boxes then
            drawings.Box.Size = Vector2.new(width, height)
            drawings.Box.Position = boxPos
            drawings.Box.Color = corEquipe
            drawings.Box.Visible = true
        else
            drawings.Box.Visible = false
        end
        
        -- ⬅️ NAME
        if Config.ESP.Names then
            drawings.Name.Text = player.Name
            drawings.Name.Position = Vector2.new(pos.X, boxPos.Y - 14)
            drawings.Name.Color = corEquipe
            drawings.Name.Visible = true
        else
            drawings.Name.Visible = false
        end
        
        -- ⬅️ HEALTH
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
        
        -- ⬅️ CÍRCULO
        if Config.ESP.Lines then
            local raio = math.max(width, height) * 0.6
            drawings.LineCircle.Position = Vector2.new(pos.X, pos.Y)
            drawings.LineCircle.Radius = raio
            drawings.LineCircle.Color = corEquipe
            drawings.LineCircle.Visible = true
        else
            drawings.LineCircle.Visible = false
        end
    end
end

return ESP_LIMPO
