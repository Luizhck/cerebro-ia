local char = game.Players.LocalPlayer.Character
if not char then return "Sem personagem" end
for _, p in pairs(char:GetDescendants()) do
    if p:IsA("BasePart") then
        p.CanCollide = false
    end
end
return "NoClip ativado! 👻"
