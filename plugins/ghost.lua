local char = game.Players.LocalPlayer.Character
if not char then return "Sem personagem" end
local isGhost = char:FindFirstChild("Head") and char.Head.Transparency == 0
for _, p in pairs(char:GetDescendants()) do
    if p:IsA("BasePart") then
        p.Transparency = isGhost and 1 or 0
    end
end
return isGhost and "Invisível! 👻" or "Visível! ✅"
