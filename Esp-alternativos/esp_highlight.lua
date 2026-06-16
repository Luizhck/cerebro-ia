local ESP_Highlight = {}

ESP_Highlight.Config = {
    FillColor = Color3.fromRGB(255, 0, 0),
    OutlineColor = Color3.fromRGB(255, 255, 255)
}

local highlights = {}

function ESP_Highlight.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP_Highlight.Config.FillColor
    highlight.OutlineColor = ESP_Highlight.Config.OutlineColor
    highlight.FillTransparency = 0.5
    highlight.Adornee = char
    highlight.Parent = char
    
    highlights[player] = highlight
end

function ESP_Highlight.RemovePlayer(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end
end

function ESP_Highlight.Render(Players, LocalPlayer, Camera)
    -- Highlight é automático
end

function ESP_Highlight.Start()
    local Players = game:GetService("Players")
    
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
