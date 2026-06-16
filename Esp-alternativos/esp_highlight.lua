-- Módulo ESP Highlight - Cor do Time
local ESP_Highlight = {}

ESP_Highlight.Config = {
    TeamCheck = true,
    ShowEnemy = true,
    ShowAlly = false,
    UseTeamColor = true
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
    else
        if player.Team == LocalPlayer.Team then
            highlight.FillColor = Color3.fromRGB(50, 255, 50)
        else
            highlight.FillColor = Color3.fromRGB(255, 50, 50)
        end
    end
    
    if player.Team == LocalPlayer.Team then
        highlight.Enabled = ESP_Highlight.Config.ShowAlly
    else
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

function ESP_Highlight.RemoveAll()
    for player, hl in pairs(highlights) do
        pcall(function() hl:Destroy() end)
    end
    highlights = {}
end

function ESP_Highlight.Stop()
    ESP_Highlight.RemoveAll()
end

function ESP_Highlight.Render(Players, LocalPlayer, Camera)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if not highlights[player] then ESP_Highlight.AddPlayer(player) end
                    
                    local hl = highlights[player]
                    if hl then
                        if ESP_Highlight.Config.UseTeamColor then
                            local teamColor = GetTeamColor(player)
                            hl.FillColor = teamColor
                            hl.OutlineColor = teamColor
                        end
                        
                        local healthPercent = hum.Health / hum.MaxHealth
                        hl.FillTransparency = 0.3 + (1 - healthPercent) * 0.4
                        
                        if ESP_Highlight.Config.TeamCheck then
                            if player.Team == LocalPlayer.Team then
                                hl.Enabled = ESP_Highlight.Config.ShowAlly
                            else
                                hl.Enabled = ESP_Highlight.Config.ShowEnemy
                            end
                        else
                            hl.Enabled = true
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
    Players.PlayerRemoving:Connect(function(player) ESP_Highlight.RemovePlayer(player) end)
end

return ESP_Highlight
