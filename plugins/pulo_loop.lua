local args = ...
local valor = tonumber(args) or 100
local Players = game:GetService("Players")

if _G.JumpLoop then
    _G.JumpLoop = false
    task.wait(0.1)
end

_G.JumpLoop = true

task.spawn(function()
    while _G.JumpLoop do
        pcall(function()
            local char = Players.LocalPlayer.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then
                h.JumpPower = valor
            end
        end)
        task.wait(0.3)
    end
end)

return "Loop de pulo: " .. valor .. " 🔄"
