local args = ...
local alvo = args or ""
local n = 0
for _, o in pairs(workspace:GetDescendants()) do
    pcall(function()
        if o:IsA("Part") and o.Name:lower():find(alvo:lower()) then
            o:Destroy()
            n = n + 1
        end
    end)
end
return n .. " '" .. alvo .. "' removidos! 💣"
