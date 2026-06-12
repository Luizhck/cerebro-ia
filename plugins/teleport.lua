-- Recebe o argumento (nome do alvo)
local args = ...
local nomeAlvo = tostring(args or "")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local char = LocalPlayer.Character
if not char then return "❌ Sem personagem!" end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return "❌ Sem HumanoidRootPart!" end

-- Se não tem nome, vai para o mais próximo
if nomeAlvo == "" or nomeAlvo == "nil" then
    local maisProximo = nil
    local menorDist = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local alvoHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if alvoHrp then
                local dist = (hrp.Position - alvoHrp.Position).Magnitude
                if dist < menorDist then
                    menorDist = dist
                    maisProximo = p
                end
            end
        end
    end
    
    if maisProximo then
        local alvoHrp = maisProximo.Character:FindFirstChild("HumanoidRootPart")
        hrp.CFrame = alvoHrp.CFrame + Vector3.new(0, 3, 0)
        return "📍 Teleportado para " .. maisProximo.Name .. "!"
    end
    
    return "❌ Nenhum jogador encontrado!"
end

-- Procura jogador
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character then
        local nome = p.Name:lower()
        local busca = nomeAlvo:lower()
        
        if nome:find(busca) or busca:find(nome) then
            local alvoHrp = p.Character:FindFirstChild("HumanoidRootPart")
            if alvoHrp then
                hrp.CFrame = alvoHrp.CFrame + Vector3.new(0, 3, 0)
                return "📍 Teleportado para " .. p.Name .. "!"
            end
        end
    end
end

-- Procura lugares
for _, obj in pairs(Workspace:GetDescendants()) do
    pcall(function()
        if obj:IsA("BasePart") and obj.Name:lower():find(nomeAlvo:lower()) then
            hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 5, 0))
            return "📍 Teleportado para " .. obj.Name .. "!"
        end
    end)
end

return "❌ '" .. nomeAlvo .. "' não encontrado!"
