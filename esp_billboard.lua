-- Módulo ESP BillboardGui (3D) - Versão Completa
local ESP_Billboard = {}

ESP_Billboard.Config = {
    MaxDistance = 500,
    TextSize = 14,
    ShowHealth = true,
    ShowDistance = true,
    ShowWeapon = true,
    TeamCheck = true
}

local billboards = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function GetTeamColor(player)
    if player.Team then
        return player.TeamColor.Color
    end
    return Color3.fromRGB(255, 255, 255)
end

function ESP_Billboard.AddPlayer(player)
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 200, 0, 80)
    bill.AlwaysOnTop = true
    bill.MaxDistance = ESP_Billboard.Config.MaxDistance
    bill.Adornee = head
    bill.Parent = head
    
    -- Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, ESP_Billboard.Config.TextSize)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = GetTeamColor(player)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = bill
    
    -- Barra de vida
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, 0, 0, 4)
    healthBar.Position = UDim2.new(0, 0, 0, ESP_Billboard.Config.TextSize + 2)
    healthBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBar.Parent = bill
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.Parent = healthBar
    
    -- Distância
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, ESP_Billboard.Config.TextSize - 2)
    distLabel.Position = UDim2.new(0, 0, 0, ESP_Billboard.Config.TextSize + 8)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distLabel.TextStrokeTransparency = 0
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.Parent = bill
    
    billboards[player] = {
        Bill = bill,
        Name = nameLabel,
        Health = healthFill,
        Dist = distLabel
    }
end

function ESP_Billboard.RemovePlayer(player)
    if billboards[player] then
        billboards[player].Bill:Destroy()
        billboards[player] = nil
    end
end

function ESP_Billboard.UpdatePlayer(player)
    local data = billboards[player]
    if not data then return end
    
    local char = player.Character
    if not char then
        ESP_Billboard.RemovePlayer(player)
        return
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not hrp then
        ESP_Billboard.RemovePlayer(player)
        return
    end
    
    -- Atualiza cor do nome
    data.Name.TextColor3 = GetTeamColor(player)
    
    -- Atualiza barra de vida
    local healthPercent = hum.Health / hum.MaxHealth
    data.Health.Size = UDim2.new(healthPercent, 0, 1, 0)
    data.Health.BackgroundColor3 = Color3.fromRGB(
        math.floor(255 * (1 - healthPercent)),
        math.floor(255 * healthPercent),
        0
    )
    
    -- Atualiza distância
    local myChar = LocalPlayer.Character
    if myChar then
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        if myHRP then
            local dist = (myHRP.Position - hrp.Position).Magnitude
            data.Dist.Text = math.floor(dist) .. "m"
        end
    end
    
    -- Atualiza nome com arma
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and ESP_Billboard.Config.ShowWeapon then
        data.Name.Text = player.Name .. " [" .. tool.Name .. "]"
    else
        data.Name.Text = player.Name
    end
    
    -- Verifica time
    if ESP_Billboard.Config.TeamCheck and player.Team == LocalPlayer.Team then
        data.Bill.Enabled = false
    else
        data.Bill.Enabled = true
    end
    
    -- Verifica distância
    local cameraDist = (workspace.CurrentCamera.CFrame.Position - hrp.Position).Magnitude
    if cameraDist > ESP_Billboard.Config.MaxDistance then
        data.Bill.Enabled = false
    end
    
    -- Verifica se está vivo
    if hum.Health <= 0 then
        ESP_Billboard.RemovePlayer(player)
    end
end

function ESP_Billboard.Render(Players, LocalPlayer, Camera)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character then
                if not billboards[player] then
                    ESP_Billboard.AddPlayer(player)
                end
                ESP_Billboard.UpdatePlayer(player)
            else
                ESP_Billboard.RemovePlayer(player)
            end
        end
    end
end

function ESP_Billboard.Start()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            task.wait(0.5)
            ESP_Billboard.AddPlayer(player)
        end)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        ESP_Billboard.RemovePlayer(player)
    end)
end

return ESP_Billboard
