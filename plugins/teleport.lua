local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local args = ...
local nomeAlvo = args or ""

local char = LocalPlayer.Character
if not char then return "❌ Sem personagem!" end

local hrp = char:FindFirstChild("HumanoidRootPart")
if not hrp then return "❌ Sem HumanoidRootPart!" end

-- Se não tem nome, vai para o jogador mais próximo
if nomeAlvo == "" then
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
        if alvoHrp then
            hrp.CFrame = alvoHrp.CFrame + Vector3.new(0, 3, 0)
            return "📍 Teleportado para " .. maisProximo.Name .. "!"
        end
    end
    
    return "❌ Nenhum jogador encontrado!"
end

-- 🔍 PROCURA JOGADOR pelo nome
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

-- 🗺️ PROCURA LUGARES (spawns, construções, objetos)
local lugaresEncontrados = {}

for _, obj in pairs(Workspace:GetDescendants()) do
    pcall(function()
        local nome = obj.Name:lower()
        local busca = nomeAlvo:lower()
        
        -- Spawns
        if nome:find("spawn") and busca:find("spawn") then
            if obj:IsA("BasePart") then
                table.insert(lugaresEncontrados, {nome = obj.Name, pos = obj.Position})
            end
        end
        
        -- Construções
        if nome:find("house") or nome:find("casa") or nome:find("building") or nome:find("predio") or
           nome:find("base") or nome:find("tower") or nome:find("torre") then
            if busca:find("casa") or busca:find("house") or busca:find("predio") or 
               busca:find("building") or busca:find("base") or busca:find("torre") then
                if obj:IsA("Model") and obj.PrimaryPart then
                    table.insert(lugaresEncontrados, {nome = obj.Name, pos = obj.PrimaryPart.Position})
                end
            end
        end
        
        -- Objetos específicos por nome
        if nome:find(busca) and obj:IsA("BasePart") then
            table.insert(lugaresEncontrados, {nome = obj.Name, pos = obj.Position})
        end
    end)
end

-- Vai para o primeiro lugar encontrado
if #lugaresEncontrados > 0 then
    local lugar = lugaresEncontrados[1]
    hrp.CFrame = CFrame.new(lugar.pos + Vector3.new(0, 5, 0))
    return "📍 Teleportado para " .. lugar.nome .. "!"
end

return "❌ '" .. nomeAlvo .. "' não encontrado!"
