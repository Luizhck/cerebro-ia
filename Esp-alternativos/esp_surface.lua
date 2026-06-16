local ESP_Surface = {}

ESP_Surface.Config = {
    TextSize = 15
}

local surfaces = {}

function ESP_Surface.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.Adornee = head
    sg.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = player.Name
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.TextSize = ESP_Surface.Config.TextSize
    label.Parent = sg
    
    surfaces[player] = sg
end

function ESP_Surface.RemovePlayer(player)
    if surfaces[player] then
        surfaces[player]:Destroy()
        surfaces[player] = nil
    end
end

function ESP_Surface.Render(Players, LocalPlayer, Camera)
    -- SurfaceGui é automático
end

function ESP_Surface.Start()
    local Players = game:GetService("Players")
    
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            ESP_Surface.AddPlayer(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        ESP_Surface.RemovePlayer(player)
    end)
end

return ESP_Surface
