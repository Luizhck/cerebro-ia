local args = ...
local valor = tonumber(args) or 50
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Se já existe um loop, para ele
if _G.SpeedLoop then
    _G.SpeedLoop = false
    task.wait(0.1)
end

_G.SpeedLoop = true
local hum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

task.spawn(function()
    while _G.SpeedLoop do
        pcall(function()
            local char = Players.LocalPlayer.Character
            local h = char and char:FindFirstChildOfClass("Humanoid")
            if h then
                h.WalkSpeed = valor
            end
        end)
        task.wait(0.3)
    end
end)

return "Loop de velocidade: " .. valor .. " 🔄 (diga 'parar loop' para cancelar)"
