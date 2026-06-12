local args = ...
local nome = args or ""
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

if not hrp then return "Sem personagem" end

-- Primeiro tenta achar pelo nome
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character and p.Name:lower():find(nome:lower()) then
        local hrp2 = p.Character:FindFirstChild("HumanoidRootPart")
        if hrp2 then
            hrp.CFrame = hrp2.CFrame + Vector3.new(0, 3, 0)
            return "Teleportado para " .. p.Name .. "! 📍"
        end
    end
end

-- Se não achou, vai para o mais próximo
local maisProximo = nil
local menorDist = math.huge
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local dist = (hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude
        if dist < menorDist then
            menorDist = dist
            maisProximo = p
        end
    end
end

if maisProximo then
    hrp.CFrame = maisProximo.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    return "Teleportado para " .. maisProximo.Name .. " (mais próximo)! 📍"
end

return "Nenhum jogador encontrado"
