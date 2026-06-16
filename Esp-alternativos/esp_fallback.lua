-- Módulo ESP Fallback (Console) - Último Recurso
local ESP_Fallback = {}

ESP_Fallback.Config = {
    MaxDistance = 200,
    ShowHealth = true,
    ShowDistance = true,
    ShowWeapon = true,
    TeamCheck = true
}

function ESP_Fallback.Render(Players, LocalPlayer, Camera)
    local count = 0
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                
                if dist <= ESP_Fallback.Config.MaxDistance then
                    -- Team check
                    if ESP_Fallback.Config.TeamCheck and player.Team == LocalPlayer.Team then
                        continue
                    end
                    
                    local info = "[ESP] " .. player.Name
                    
                    if ESP_Fallback.Config.ShowDistance then
                        info = info .. " | " .. math.floor(dist) .. "m"
                    end
                    
                    if ESP_Fallback.Config.ShowHealth then
                        info = info .. " | HP: " .. math.floor(hum.Health)
                    end
                    
                    if ESP_Fallback.Config.ShowWeapon then
                        local tool = player.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            info = info .. " | " .. tool.Name
                        end
                    end
                    
                    print(info)
                    count = count + 1
                end
            end
        end
    end
    
    if count > 0 then
        print("[ESP] " .. count .. " jogadores detectados")
    end
end

function ESP_Fallback.Start()
    print("[ESP Fallback] Modo console ativado!")
    print("[ESP Fallback] Pressione F9 para ver os jogadores")
end

return ESP_Fallback
