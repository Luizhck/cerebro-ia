local args = ...
local valor = tonumber(args) or 50
local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then
    hum.WalkSpeed = valor
    return "Velocidade: " .. valor .. " ⚡"
end
return "Erro: sem personagem"
