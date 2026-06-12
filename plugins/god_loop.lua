local Players = game:GetService("Players")

if _G.GodLoop then
    _G.GodLoop = false
    task.wait(0.1)
end

_G.GodLoop = true

task.spawn(function()
    while _G.GodLoop do
        pcall(function()
            local char = Players.LocalPlayer.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then
                h.MaxHealth = 99999
                h.Health = 99999
            end
        end)
        task.wait(0.5)
    end
end)

return "God Mode infinito! 🛡️"
