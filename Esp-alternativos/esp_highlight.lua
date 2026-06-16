-- Módulo ESP Highlight - Versão Completa
local ESP_Highlight = {}

ESP_Highlight.Config = {
    TeamCheck = true,
    ShowEnemy = true,
    ShowAlly = false,
    EnemyColor = Color3.fromRGB(255, 50, 50),
    AllyColor = Color3.fromRGB(50, 255, 50)
}

local highlights = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function ESP_Highlight.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.Adornee = char
    highlight.Parent = char
    
    if player.Team == LocalPlayer.Team then
        highlight.FillColor = ESP_Highlight.Config.AllyColor
        highlight.Enabled = ESP_Highlight.Config.ShowAlly
    else
        highlight.FillColor = ESP_Highlight.Config.EnemyColor
        highlight.Enabled = ESP_Highlight.Config.ShowEnemy
    end
    
    highlights[player] = highlight
end

function ESP_Highlight.RemovePlayer(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
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
                        -- Atualiza cor baseado na vida
                        local healthPercent = hum.Health / hum.MaxHealth
                        if player.Team ~= LocalPlayer.Team then
                            hl.FillColor = Color3.fromRGB(
                                math.floor(255 * (1 - healthPercent)),
                                math.floor(255 * healthPercent),
                                0
                            )
                        end
                        
                        -- Team check
                        if ESP_Highlight.Config.TeamCheck then
                            if player.Team == LocalPlayer.Team then
                                hl.Enabled = ESP_Highlight.Config.ShowAlly
                            else
                                hl.Enabled = ESP_Highlight.Config.ShowEnemy
                            end
                        end
                    end
                else
                    ESP_Highlight.RemovePlayer(player)
                end
            else
                ESP_Highlight.RemovePlayer(player)
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
        ESP_Highlight.RemovePlayer(player)
    end)
end

return ESP_Highlight
