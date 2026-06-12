local args = ...
local valor = tonumber(args) or 100
local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then
    hum.JumpPower = valor
    return "Pulo: " .. valor .. " 🦘"
end
return "Erro: sem personagem"
