local ESP_Fallback = {}

function ESP_Fallback.Render(Players, LocalPlayer, Camera)
    -- ESP mínimo - só mostra nomes no console
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                if dist < 100 then
                    print("[ESP Fallback] " .. player.Name .. " - " .. math.floor(dist) .. "m")
                end
            end
        end
    end
end

function ESP_Fallback.Start()
    print("[ESP Fallback] Iniciado!")
end

return ESP_Fallback
