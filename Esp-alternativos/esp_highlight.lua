-- Módulo ESP Highlight - Cor do Time (SIMPLIFICADO)
local ESP_Highlight = {}

ESP_Highlight.Config = {
    TeamCheck = true,       -- Se TRUE, mostra APENAS inimigos
    UseTeamColor = true     -- Usa cor real do time
}

local highlights = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetTeamColor(player)
    if player.Team then return player.TeamColor.Color end
    return Color3.fromRGB(255, 50, 50)
end

function ESP_Highlight.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Adornee = char
    highlight.Parent = char
    
    if ESP_Highlight.Config.UseTeamColor then
        local teamColor = GetTeamColor(player)
        highlight.FillColor = teamColor
        highlight.OutlineColor = teamColor
    end
    
    -- ✅ TeamCheck: se ativado, mostra só inimigos
    if ESP_Highlight.Config.TeamCheck and player.Team == LocalPlayer.Team then
        highlight.Enabled = false  -- Aliado = escondido
    else
        highlight.Enabled = true   -- Inimigo = mostrado
    end
    
    highlights[player] = highlight
end

function ESP_Highlight.Remove(player, stopAll)
    if stopAll then
        for p, hl in pairs(highlights) do
            pcall(function() hl:Destroy() end)
        end
        highlights = {}
    elseif player then
        if highlights[player] then
            highlights[player]:Destroy()
            highlights[player] = nil
        end
    end
end

function ESP_Highlight.Render(Players, LocalPlayer, Camera)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not highlights[player] then 
                        ESP_Highlight.AddPlayer(player) 
                    end
                    
                    local hl = highlights[player]
                    if hl then
                        -- Atualiza cor do time
                        if ESP_Highlight.Config.UseTeamColor then
                            local teamColor = GetTeamColor(player)
                            hl.FillColor = teamColor
                            hl.OutlineColor = teamColor
                        end
                        
                        -- Transparência baseada na vida
                        local healthPercent = hum.Health / hum.MaxHealth
                        hl.FillTransparency = 0.3 + (1 - healthPercent) * 0.4
                        
                        -- ✅ TeamCheck: esconde aliados
                        if ESP_Highlight.Config.TeamCheck then
                            hl.Enabled = (player.Team ~= LocalPlayer.Team)
                        else
                            hl.Enabled = true  -- Mostra todos
                        end
                    end
                else
                    ESP_Highlight.Remove(player)
                end
            else
                ESP_Highlight.Remove(player)
            end
        end
    end
end

function ESP_Highlight.Start()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            ESP_Highlight.AddPlayer(player)
        end)
    end)
    Players.PlayerRemoving:Connect(function(player) 
        ESP_Highlight.Remove(player) 
    end)
end

ESP_Highlight.Stop = function() ESP_Highlight.Remove(nil, true) end
ESP_Highlight.RemoveAll = function() ESP_Highlight.Remove(nil, true) end

return ESP_Highlight
