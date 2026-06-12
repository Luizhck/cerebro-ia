local n = 0
for _, o in pairs(workspace:GetDescendants()) do
    if o:IsA("Tool") and o.Parent == workspace then
        o.Parent = game.Players.LocalPlayer.Backpack
        n = n + 1
    end
end
return n .. " armas coletadas! 🔫"
