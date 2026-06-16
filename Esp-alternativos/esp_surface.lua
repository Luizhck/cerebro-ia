-- Módulo ESP SurfaceGui (3D) - Versão Completa
local ESP_Surface = {}

ESP_Surface.Config = {
    MaxDistance = 500,
    TextSize = 12,
    ShowHealth = true,
    ShowDistance = true,
    TeamCheck = true
}

local surfaces = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function ESP_Surface.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.Adornee = head
    sg.Parent = head
    sg.Enabled = true
    
    -- Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = player.TeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = ESP_Surface.Config.TextSize
    nameLabel.Parent = sg
    
    -- Vida
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "100%"
    healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 10
    healthLabel.Parent = sg
    
    surfaces[player] = {
        Gui = sg,
        Name = nameLabel,
        Health = healthLabel
    }
end

function ESP_Surface.RemovePlayer(player)
    if surfaces[player] then
        surfaces[player].Gui:Destroy()
        surfaces[player] = nil
    end
end

function ESP_Surface.Render(Players, LocalPlayer, Camera)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                local hum = player.Character:FindFirstChildOfClass("Humanoid")
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                
                if hum and hrp and hum.Health > 0 then
                    if not surfaces[player] then
                        ESP_Surface.AddPlayer(player)
                    end
                    
                    local data = surfaces[player]
                    if data then
                        -- Atualiza vida
                        local healthPercent = math.floor((hum.Health / hum.MaxHealth) * 100)
                        data.Health.Text = healthPercent .. "%"
                        data.Health.TextColor3 = Color3.fromRGB(
                            math.floor(255 * (1 - healthPercent/100)),
                            math.floor(255 * (healthPercent/100)),
                            0
                        )
                        
                        -- Team check
                        if ESP_Surface.Config.TeamCheck and player.Team == LocalPlayer.Team then
                            data.Gui.Enabled = false
                        else
                            data.Gui.Enabled = true
                        end
                        
                        -- Distância
                        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                        if dist > ESP_Surface.Config.MaxDistance then
                            data.Gui.Enabled = false
                        end
                        
                        -- Nome
                        local tool = player.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            data.Name.Text = player.Name .. " [" .. tool.Name .. "]"
                        else
                            data.Name.Text = player.Name
                        end
                    end
                else
                    ESP_Surface.RemovePlayer(player)
                end
            else
                ESP_Surface.RemovePlayer(player)
            end
        end
    end
end

function ESP_Surface.Start()
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
