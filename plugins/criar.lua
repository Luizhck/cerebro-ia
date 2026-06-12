local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
if hrp then
    local p = Instance.new("Part", workspace)
    p.Size = Vector3.new(5, 5, 5)
    p.Position = hrp.Position + hrp.CFrame.LookVector * 5
    p.Anchored = true
    p.BrickColor = BrickColor.random()
    return "Criado! 🏗️"
end
return "Erro: sem personagem"
