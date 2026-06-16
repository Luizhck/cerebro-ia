-- Módulo ESP Drawing (Externo)
local ESP_Drawing = {}

ESP_Drawing.Config = {
    BoxThickness = 1,
    NameSize = 13,
    HealthBarWidth = 2
}

local drawings = {}

function ESP_Drawing.AddPlayer(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Filled = false
    box.Thickness = ESP_Drawing.Config.BoxThickness
    
    local name = Drawing.new("Text")
    name.Visible = false
    name.Size = ESP_Drawing.Config.NameSize
    name.Center = true
    name.Outline = true
    
    local health = Drawing.new("Square")
    health.Visible = false
    health.Filled = true
    
    drawings[player] = {Box = box, Name = name, Health = health}
end

function ESP_Drawing.RemovePlayer(player)
    if drawings[player] then
        for _, drawing in pairs(drawings[player]) do
            drawing:Remove()
        end
        drawings[player] = nil
    end
end

function ESP_Drawing.Render(Players, LocalPlayer, Camera)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        local head = player.Character:FindFirstChild("Head")
        
        if not hrp or not hum or hum.Health <= 0 then
            ESP_Drawing.RemovePlayer(player)
            continue
        end
        
        if not drawings[player] then
            ESP_Drawing.AddPlayer(player)
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        local d = drawings[player]
        
        if onScreen then
            d.Box.Visible = true
            d.Box.Position = Vector2.new(pos.X - 25, pos.Y - 50)
            d.Box.Size = Vector2.new(50, 100)
            d.Box.Color = Color3.fromRGB(255, 0, 0)
            
            d.Name.Visible = true
            d.Name.Text = player.Name
            d.Name.Position = Vector2.new(pos.X, pos.Y - 55)
            d.Name.Color = Color3.fromRGB(255, 255, 255)
            
            d.Health.Visible = true
            d.Health.Size = Vector2.new(2, 100 * (hum.Health / hum.MaxHealth))
            d.Health.Position = Vector2.new(pos.X - 30, pos.Y - 50)
            d.Health.Color = Color3.fromRGB(0, 255, 0)
        else
            d.Box.Visible = false
            d.Name.Visible = false
            d.Health.Visible = false
        end
    end
end

function ESP_Drawing.Start()
    local Players = game:GetService("Players")
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(1)
            ESP_Drawing.AddPlayer(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        ESP_Drawing.RemovePlayer(player)
    end)
end

return ESP_Drawing
