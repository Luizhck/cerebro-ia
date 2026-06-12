local n = 0
for _, p in pairs(game:GetService("Players"):GetPlayers()) do
    if p ~= game.Players.LocalPlayer and p.Character then
        local head = p.Character:FindFirstChild("Head")
        if head then
            head.Size = Vector3.new(15, 15, 15)
            head.Transparency = 0.5
            head.CanCollide = false
            n = n + 1
        end
    end
end
return "Hitbox " .. n .. " expandida! 🎯"
