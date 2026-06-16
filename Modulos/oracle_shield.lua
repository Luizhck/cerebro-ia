-- =============================================
-- 🛡️ ORACLE SHIELD - DETECTOR PASSIVO SEGURO
-- Versão 3.0 - Detector COMPLETO de Anti-Cheats
-- =============================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local pcall = pcall
local tick = tick
local os_date = os.date

-- =============================================
-- 📦 ESTRUTURA SEGURA
-- =============================================

local OracleShield = {
    MemoryFile = "oracle_shield_brain.json",
    LastSave = 0,
    SaveInterval = 60,
    
    DNA = {
        ScanFrequency = 30,
        LearningRate = 0.3,
        DiscountFactor = 0.9,
        ExplorationRate = 0.2
    },
    
    QTable = {},
    KnownCheats = {},
    History = {},
    
    Metrics = {
        TotalScans = 0,
        Discoveries = 0,
        RiskLevel = 0,
        Confidence = 0.5
    },
    
    Actions = {"Scan", "DeepScan", "Adapt", "Ignore"}
}

-- =============================================
-- 💾 SISTEMA DE MEMÓRIA OTIMIZADO
-- =============================================

local function SaveBrain()
    local now = tick()
    if now - OracleShield.LastSave < OracleShield.SaveInterval then return end
    OracleShield.LastSave = now
    
    pcall(function()
        if writefile then
            local data = {
                SessionId = game.JobId,
                PlaceId = game.PlaceId,
                DNA = OracleShield.DNA,
                QTable = OracleShield.QTable,
                Metrics = OracleShield.Metrics,
                KnownCheats = OracleShield.KnownCheats,
                LastUpdate = os_date("%Y-%m-%d %H:%M:%S")
            }
            writefile(OracleShield.MemoryFile, HttpService:JSONEncode(data))
        end
    end)
end

local function LoadBrain()
    local loaded = false
    
    pcall(function()
        if isfile and isfile(OracleShield.MemoryFile) then
            local data = HttpService:JSONDecode(readfile(OracleShield.MemoryFile))
            
            if data.PlaceId and data.PlaceId == game.PlaceId then
                if data.KnownCheats then OracleShield.KnownCheats = data.KnownCheats end
                if data.QTable then OracleShield.QTable = data.QTable end
                if data.Metrics then 
                    for k, v in pairs(data.Metrics) do 
                        OracleShield.Metrics[k] = v 
                    end 
                end
                loaded = true
                
                local knownCount = 0
                for _ in pairs(OracleShield.KnownCheats) do knownCount = knownCount + 1 end
                print("🧠 Oracle Shield carregou " .. knownCount .. " anti-cheats da memória")
            else
                print("🔄 Jogo diferente! Iniciando aprendizado do zero...")
                OracleShield.KnownCheats = {}
                OracleShield.QTable = {}
                OracleShield.Metrics = {TotalScans = 0, Discoveries = 0, RiskLevel = 0, Confidence = 0.5}
            end
        else
            print("🔄 Primeira execução! Iniciando aprendizado...")
        end
    end)
    
    if not loaded then
        print("✅ Pronto para detectar anti-cheats!")
    end
end

-- =============================================
-- 🔬 DETECTOR PASSIVO COMPLETO
-- =============================================

local PassiveDetector = {
    
    -- 1. Criação de Objetos
    ObjectCreation = function()
        local blocked = {}
        local tests = {"RemoteEvent", "RemoteFunction", "Script", "LocalScript", "ModuleScript"}
        
        for _, class in ipairs(tests) do
            local success = pcall(function()
                local obj = Instance.new(class)
                obj:Destroy()
            end)
            
            if not success then
                table.insert(blocked, {
                    name = "Anti-" .. class .. " Creation",
                    risk = 0.3,
                    type = "creation"
                })
            end
        end
        
        return blocked
    end,
    
    -- 2. Execução de Código
    CodeExecution = function()
        local blocked = {}
        
        if loadstring then
            local success = pcall(function()
                local fn = loadstring("return true")
                if fn then fn() end
            end)
            
            if not success then
                table.insert(blocked, {
                    name = "Anti-Code Execution",
                    risk = 0.6,
                    type = "execution"
                })
            end
        else
            table.insert(blocked, {
                name = "Anti-loadstring (Removido)",
                risk = 0.7,
                type = "execution"
            })
        end
        
        -- Verifica getfenv
        if getfenv then
            local success = pcall(function() getfenv() end)
            if not success then
                table.insert(blocked, {
                    name = "Anti-getfenv",
                    risk = 0.6,
                    type = "execution"
                })
            end
        end
        
        return blocked
    end,
    
    -- 3. Acesso a Serviços
    ServiceAccess = function()
        local blocked = {}
        local services = {"CoreGui", "CorePackages", "RobloxReplicatedStorage", "RobloxGui"}
        
        for _, serviceName in ipairs(services) do
            local success = pcall(function()
                local service = game:GetService(serviceName)
                if service then
                    local children = service:GetChildren()
                    local count = #children
                end
            end)
            
            if not success then
                table.insert(blocked, {
                    name = "Protected: " .. serviceName,
                    risk = 0.5,
                    type = "service"
                })
            end
        end
        
        return blocked
    end,
    
    -- 4. Propriedades do Jogo
    GameProperties = function()
        local blocked = {}
        
        -- Gravidade
        local success1 = pcall(function()
            local gravity = Workspace.Gravity
        end)
        
        if not success1 then
            table.insert(blocked, {
                name = "Anti-Property Access",
                risk = 0.4,
                type = "property"
            })
        end
        
        -- Iluminação
        local success2 = pcall(function()
            local lighting = game:GetService("Lighting")
            local time = lighting.ClockTime
        end)
        
        if not success2 then
            table.insert(blocked, {
                name = "Anti-Lighting Access",
                risk = 0.3,
                type = "property"
            })
        end
        
        -- Metatable
        local success3 = pcall(function()
            local mt = getrawmetatable and getrawmetatable(game)
        end)
        
        if not success3 then
            table.insert(blocked, {
                name = "Anti-Metatable Access",
                risk = 0.8,
                type = "metatable"
            })
        end
        
        return blocked
    end,
    
    -- 5. Nomes Suspeitos
    SuspiciousNames = function()
        local blocked = {}
        local suspiciousNames = {
            "Dex", "Explorer", "ScriptHub", "Hack", "Cheat",
            "Synapse", "Krnl", "Fluxus", "Oxygen", "Electron"
        }
        
        for _, name in ipairs(suspiciousNames) do
            local found = false
            pcall(function()
                if CoreGui:FindFirstChild(name) then found = true end
                if LocalPlayer:FindFirstChild(name) then found = true end
                if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild(name) then found = true end
            end)
            
            if found then
                table.insert(blocked, {
                    name = "Anti-" .. name .. " Detection",
                    risk = 0.7,
                    type = "detection"
                })
            end
        end
        
        return blocked
    end,
    
    -- 6. Anti-Hook
   HookProtection = function()
    local blocked = {}
    
    if hookfunction then
        local success = pcall(function()
            local testFn = function() return true end
            local hookFn = function(...) return testFn(...) end
            -- NÃO hookar print! Usar função local
            local old = hookfunction(testFn, hookFn)
        end)
        
        if not success then
            table.insert(blocked, {
                name = "Anti-HookFunction",
                risk = 0.8,
                type = "hook"
            })
        end
    end
    
    return blocked
end,

    
    -- 7. Anti-Fly
    AntiFly = function()
        local blocked = {}
        
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local success = pcall(function()
                    local state = humanoid:GetState()
                end)
                
                if not success then
                    table.insert(blocked, {
                        name = "Anti-Fly (Humanoid Protegido)",
                        risk = 0.7,
                        type = "anti_exploit"
                    })
                end
            end
            
            local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local success = pcall(function()
                    local vel = rootPart.Velocity
                end)
                
                if not success then
                    table.insert(blocked, {
                        name = "Anti-Fly (Velocity Protegido)",
                        risk = 0.6,
                        type = "anti_exploit"
                    })
                end
            end
        end
        
        return blocked
    end,
    
  -- 8. Anti-Teleport (REFORÇADO)
AntiTeleport = function()
    local blocked = {}
    
    if LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        -- Teste 1: Acesso ao CFrame
        if rootPart then
            local success1 = pcall(function()
                local cf = rootPart.CFrame
                local pos = rootPart.Position
                local rot = rootPart.Rotation
            end)
            
            if not success1 then
                table.insert(blocked, {
                    name = "Anti-Teleport (CFrame Protegido)",
                    risk = 0.9,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 2: Modificação do CFrame
            local success2 = pcall(function()
                local oldCFrame = rootPart.CFrame
                rootPart.CFrame = oldCFrame + Vector3.new(0, 1, 0)
                rootPart.CFrame = oldCFrame
            end)
            
            if not success2 then
                table.insert(blocked, {
                    name = "Anti-Teleport (CFrame Mod Bloqueado)",
                    risk = 0.95,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 3: Modificação da Position
            local success3 = pcall(function()
                local oldPos = rootPart.Position
                rootPart.Position = oldPos + Vector3.new(0, 1, 0)
                rootPart.Position = oldPos
            end)
            
            if not success3 then
                table.insert(blocked, {
                    name = "Anti-Teleport (Position Mod Bloqueado)",
                    risk = 0.9,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 4: AssemblyLinearVelocity (usado em teleports)
            local success4 = pcall(function()
                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end)
            
            if not success4 then
                table.insert(blocked, {
                    name = "Anti-Teleport (Velocity Protegido)",
                    risk = 0.85,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 5: Anchored (usado para travar no ar)
            local success5 = pcall(function()
                local oldAnchor = rootPart.Anchored
                rootPart.Anchored = true
                rootPart.Anchored = oldAnchor
            end)
            
            if not success5 then
                table.insert(blocked, {
                    name = "Anti-Teleport (Anchored Bloqueado)",
                    risk = 0.8,
                    type = "anti_teleport"
                })
            end
        end
        
        -- Teste 6: Humanoid Seat (usado para teleport em veículos)
        if humanoid then
            local success6 = pcall(function()
                local seat = humanoid.SeatPart
            end)
            
            if not success6 then
                table.insert(blocked, {
                    name = "Anti-Teleport (Seat Protegido)",
                    risk = 0.7,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 7: Humanoid RootPart
            local success7 = pcall(function()
                local rp = humanoid.RootPart
            end)
            
            if not success7 then
                table.insert(blocked, {
                    name = "Anti-Teleport (RootPart Protegido)",
                    risk = 0.85,
                    type = "anti_teleport"
                })
            end
            
            -- Teste 8: MoveTo (usado para teleport)
            local success8 = pcall(function()
                humanoid:MoveTo(Vector3.new(0, 0, 0))
            end)
            
            if not success8 then
                table.insert(blocked, {
                    name = "Anti-Teleport (MoveTo Bloqueado)",
                    risk = 0.9,
                    type = "anti_teleport"
                })
            end
        end
        
        -- Teste 9: TweenService (usado para teleports suaves)
        local success9 = pcall(function()
            local tween = game:GetService("TweenService")
            local info = TweenInfo.new(0.1)
        end)
        
        if not success9 then
            table.insert(blocked, {
                name = "Anti-Teleport (TweenService Protegido)",
                risk = 0.7,
                type = "anti_teleport"
            })
        end
        
        -- Teste 10: Verifica RemoteEvents de teleporte
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local teleportRemotes = {"Teleport", "TP", "Warp", "Jump", "Move", "Transport"}
            
            for _, obj in ipairs(rs:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = obj.Name:lower()
                    for _, keyword in ipairs(teleportRemotes) do
                        if name:find(keyword:lower()) then
                            table.insert(blocked, {
                                name = "Anti-Teleport (Remote: " .. obj.Name .. ")",
                                risk = 0.75,
                                type = "anti_teleport"
                            })
                            break
                        end
                    end
                end
            end
        end)
        
        -- Teste 11: Verifica se há anti-teleport por distância máxima
        if rootPart then
            local success11 = pcall(function()
                -- Tenta mover 1000 studs (teleport longo)
                local oldPos = rootPart.Position
                rootPart.CFrame = CFrame.new(oldPos + Vector3.new(1000, 0, 0))
                rootPart.CFrame = CFrame.new(oldPos)
            end)
            
            if not success11 then
                table.insert(blocked, {
                    name = "Anti-Teleport (Distância Máxima Bloqueada)",
                    risk = 0.95,
                    type = "anti_teleport"
                })
            end
        end
    end
    
    -- Teste 12: Verifica CharacterAdded (usado para detectar teleports)
    local success12 = pcall(function()
        local conn = LocalPlayer.CharacterAdded:Connect(function() end)
        conn:Disconnect()
    end)
    
    if not success12 then
        table.insert(blocked, {
            name = "Anti-Teleport (CharacterAdded Monitorado)",
            risk = 0.8,
            type = "anti_teleport"
        })
    end
    
    return blocked
end,
    
    -- 9. Anti-Speed Hack (REFORÇADO)
AntiSpeed = function()
    local blocked = {}
    
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        -- Teste 1: Acesso ao WalkSpeed
        if humanoid then
            local success1 = pcall(function()
                local ws = humanoid.WalkSpeed
            end)
            
            if not success1 then
                table.insert(blocked, {
                    name = "Anti-Speed (WalkSpeed Protegido)",
                    risk = 0.7,
                    type = "anti_speed"
                })
            end
            
            -- Teste 2: Modificação do WalkSpeed
            local success2 = pcall(function()
                local oldWS = humanoid.WalkSpeed
                humanoid.WalkSpeed = 20
                humanoid.WalkSpeed = oldWS
            end)
            
            if not success2 then
                table.insert(blocked, {
                    name = "Anti-Speed (WalkSpeed Mod Bloqueado)",
                    risk = 0.85,
                    type = "anti_speed"
                })
            end
            
            -- Teste 3: Acesso ao JumpPower
            local success3 = pcall(function()
                local jp = humanoid.JumpPower
            end)
            
            if not success3 then
                table.insert(blocked, {
                    name = "Anti-Speed (JumpPower Protegido)",
                    risk = 0.6,
                    type = "anti_speed"
                })
            end
            
            -- Teste 4: Modificação do JumpPower
            local success4 = pcall(function()
                local oldJP = humanoid.JumpPower
                humanoid.JumpPower = 60
                humanoid.JumpPower = oldJP
            end)
            
            if not success4 then
                table.insert(blocked, {
                    name = "Anti-Speed (JumpPower Mod Bloqueado)",
                    risk = 0.75,
                    type = "anti_speed"
                })
            end
            
            -- Teste 5: Acesso ao HipHeight
            local success5 = pcall(function()
                local hh = humanoid.HipHeight
            end)
            
            if not success5 then
                table.insert(blocked, {
                    name = "Anti-Speed (HipHeight Protegido)",
                    risk = 0.5,
                    type = "anti_speed"
                })
            end
            
            -- Teste 6: Modificação do HipHeight
            local success6 = pcall(function()
                local oldHH = humanoid.HipHeight
                humanoid.HipHeight = 3
                humanoid.HipHeight = oldHH
            end)
            
            if not success6 then
                table.insert(blocked, {
                    name = "Anti-Speed (HipHeight Mod Bloqueado)",
                    risk = 0.65,
                    type = "anti_speed"
                })
            end
            
            -- Teste 7: PlatformStand (usado em speed hacks)
            local success7 = pcall(function()
                local ps = humanoid.PlatformStand
            end)
            
            if not success7 then
                table.insert(blocked, {
                    name = "Anti-Speed (PlatformStand Protegido)",
                    risk = 0.55,
                    type = "anti_speed"
                })
            end
            
            -- Teste 8: AutoRotate (usado em speed hacks)
            local success8 = pcall(function()
                local ar = humanoid.AutoRotate
                humanoid.AutoRotate = false
                humanoid.AutoRotate = true
            end)
            
            if not success8 then
                table.insert(blocked, {
                    name = "Anti-Speed (AutoRotate Protegido)",
                    risk = 0.6,
                    type = "anti_speed"
                })
            end
            
            -- Teste 9: UseJumpPower
            local success9 = pcall(function()
                local ujp = humanoid.UseJumpPower
                humanoid.UseJumpPower = false
                humanoid.UseJumpPower = true
            end)
            
            if not success9 then
                table.insert(blocked, {
                    name = "Anti-Speed (UseJumpPower Protegido)",
                    risk = 0.55,
                    type = "anti_speed"
                })
            end
        end
        
        -- Teste 10: Velocity da RootPart
        if rootPart then
            local success10 = pcall(function()
                local vel = rootPart.Velocity
            end)
            
            if not success10 then
                table.insert(blocked, {
                    name = "Anti-Speed (Velocity Protegido)",
                    risk = 0.7,
                    type = "anti_speed"
                })
            end
            
            -- Teste 11: Modificação da Velocity
            local success11 = pcall(function()
                local oldVel = rootPart.Velocity
                rootPart.Velocity = Vector3.new(0, 0, 0)
                rootPart.Velocity = oldVel
            end)
            
            if not success11 then
                table.insert(blocked, {
                    name = "Anti-Speed (Velocity Mod Bloqueado)",
                    risk = 0.85,
                    type = "anti_speed"
                })
            end
            
            -- Teste 12: AssemblyLinearVelocity
            local success12 = pcall(function()
                local alv = rootPart.AssemblyLinearVelocity
                rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end)
            
            if not success12 then
                table.insert(blocked, {
                    name = "Anti-Speed (AssemblyVelocity Protegido)",
                    risk = 0.8,
                    type = "anti_speed"
                })
            end
            
            -- Teste 13: AssemblyAngularVelocity
            local success13 = pcall(function()
                local aav = rootPart.AssemblyAngularVelocity
            end)
            
            if not success13 then
                table.insert(blocked, {
                    name = "Anti-Speed (AngularVelocity Protegido)",
                    risk = 0.65,
                    type = "anti_speed"
                })
            end
        end
        
        -- Teste 14: BodyVelocity/BodyGyro (usados em speed hacks)
        local success14 = pcall(function()
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(400000, 0, 400000)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv:Destroy()
        end)
        
        if not success14 then
            table.insert(blocked, {
                name = "Anti-Speed (BodyVelocity Bloqueado)",
                risk = 0.9,
                type = "anti_speed"
            })
        end
        
        -- Teste 15: BodyGyro
        local success15 = pcall(function()
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(400000, 0, 400000)
            bg.CFrame = CFrame.new()
            bg:Destroy()
        end)
        
        if not success15 then
            table.insert(blocked, {
                name = "Anti-Speed (BodyGyro Bloqueado)",
                risk = 0.85,
                type = "anti_speed"
            })
        end
        
        -- Teste 16: Verifica Remotes de velocidade
        pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local speedRemotes = {"Speed", "Velocity", "WalkSpeed", "Boost", "Sprint", "Accelerate", "Dash"}
            
            for _, obj in ipairs(rs:GetDescendants()) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    local name = obj.Name:lower()
                    for _, keyword in ipairs(speedRemotes) do
                        if name:find(keyword:lower()) then
                            table.insert(blocked, {
                                name = "Anti-Speed (Remote: " .. obj.Name .. ")",
                                risk = 0.7,
                                type = "anti_speed"
                            })
                            break
                        end
                    end
                end
            end
        end)
        
        -- Teste 17: Verifica se há monitor de velocidade (limite máximo)
        if humanoid then
            local success17 = pcall(function()
                humanoid.WalkSpeed = 500  -- Tenta velocidade absurda
                humanoid.WalkSpeed = 16   -- Restaura
            end)
            
            if not success17 then
                table.insert(blocked, {
                    name = "Anti-Speed (Limite Máximo Bloqueado)",
                    risk = 0.9,
                    type = "anti_speed"
                })
            end
        end
    end
    
    return blocked
end,
    
    -- 10. Anti-God Mode
    AntiGod = function()
        local blocked = {}
        
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local success = pcall(function()
                    local hp = humanoid.Health
                end)
                
                if not success then
                    table.insert(blocked, {
                        name = "Anti-God Mode (Health Protegido)",
                        risk = 0.7,
                        type = "anti_exploit"
                    })
                end
                
                local success2 = pcall(function()
                    local mh = humanoid.MaxHealth
                end)
                
                if not success2 then
                    table.insert(blocked, {
                        name = "Anti-God Mode (MaxHealth Protegido)",
                        risk = 0.7,
                        type = "anti_exploit"
                    })
                end
            end
        end
        
        return blocked
    end,
    
    -- 11. Anti-ESP/Wallhack
    AntiESP = function()
        local blocked = {}
        
        -- Highlight
        local success1 = pcall(function()
            local highlight = Instance.new("Highlight")
            highlight:Destroy()
        end)
        
        if not success1 then
            table.insert(blocked, {
                name = "Anti-ESP (Highlight Bloqueado)",
                risk = 0.6,
                type = "anti_exploit"
            })
        end
        
        -- BoxHandleAdornment
        local success2 = pcall(function()
            local box = Instance.new("BoxHandleAdornment")
            box:Destroy()
        end)
        
        if not success2 then
            table.insert(blocked, {
                name = "Anti-ESP (Adornments Bloqueados)",
                risk = 0.6,
                type = "anti_exploit"
            })
        end
        
        -- BillboardGui
        local success3 = pcall(function()
            local bill = Instance.new("BillboardGui")
            bill:Destroy()
        end)
        
        if not success3 then
            table.insert(blocked, {
                name = "Anti-ESP (BillboardGui Bloqueado)",
                risk = 0.5,
                type = "anti_exploit"
            })
        end
        
        return blocked
    end,
    
    -- 12. Anti-NoClip
    AntiNoClip = function()
        local blocked = {}
        
        if LocalPlayer.Character then
            local success = pcall(function()
                for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                    if part:IsA("BasePart") then
                        local cc = part.CanCollide
                    end
                end
            end)
            
            if not success then
                table.insert(blocked, {
                    name = "Anti-NoClip (CanCollide Protegido)",
                    risk = 0.5,
                    type = "anti_exploit"
                })
            end
        end
        
        return blocked
    end,
    
    -- 13. Anti-Infinite Jump
    AntiInfiniteJump = function()
        local blocked = {}
        
        if LocalPlayer.Character then
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local success = pcall(function()
                    local jp = humanoid.JumpPower
                end)
                
                if not success then
                    table.insert(blocked, {
                        name = "Anti-Infinite Jump (JumpPower Protegido)",
                        risk = 0.4,
                        type = "anti_exploit"
                    })
                end
            end
        end
        
        return blocked
    end,
    
    -- 14. Anti-Remote Spy
    AntiRemoteSpy = function()
        local blocked = {}
        
        local success = pcall(function()
            local remotes = game:GetService("ReplicatedStorage"):GetDescendants()
            for _, remote in ipairs(remotes) do
                if remote:IsA("RemoteEvent") then
                    local conn = remote.OnClientEvent:Connect(function() end)
                    conn:Disconnect()
                    break
                end
            end
        end)
        
        if not success then
            table.insert(blocked, {
                name = "Anti-Remote Spy",
                risk = 0.6,
                type = "anti_exploit"
            })
        end
        
        return blocked
    end,
    
    -- 15. Anti-Debug
    AntiDebug = function()
        local blocked = {}
        
        local success1 = pcall(function()
            if debug then
                debug.info(1, "l")
            end
        end)
        
        if not success1 then
            table.insert(blocked, {
                name = "Anti-Debug (debug.info Bloqueado)",
                risk = 0.8,
                type = "anti_exploit"
            })
        end
        
        local success2 = pcall(function()
            if debug then
                debug.traceback()
            end
        end)
        
        if not success2 then
            table.insert(blocked, {
                name = "Anti-Debug (traceback Bloqueado)",
                risk = 0.8,
                type = "anti_exploit"
            })
        end
        
        return blocked
    end,
    
    -- 16. Anti-Client Mod
    AntiClientMod = function()
        local blocked = {}
        
        local success = pcall(function()
            game:GetService("RunService"):Set3dRenderingEnabled(false)
            game:GetService("RunService"):Set3dRenderingEnabled(true)
        end)
        
        if not success then
            table.insert(blocked, {
                name = "Anti-Client Modification",
                risk = 0.9,
                type = "anti_exploit"
            })
        end
        
        return blocked
    end,
    -- 17. Anti-Aimbot
AntiAimbot = function()
    local blocked = {}
    
    -- Verifica se a câmera é protegida
    local success1 = pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            local cf = cam.CFrame
            local look = cam.CFrame.LookVector
        end
    end)
    
    if not success1 then
        table.insert(blocked, {
            name = "Anti-Aimbot (Câmera Protegida)",
            risk = 0.9,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue modificar a câmera
    local success2 = pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CameraType = Enum.CameraType.Custom
        end
    end)
    
    if not success2 then
        table.insert(blocked, {
            name = "Anti-Aimbot (CameraType Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue acessar posição de outros jogadores
    local success3 = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local pos = head.Position
                    break
                end
            end
        end
    end)
    
    if not success3 then
        table.insert(blocked, {
            name = "Anti-Aimbot (Posição de Jogadores Protegida)",
            risk = 0.7,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se o mouse é protegido
    local success4 = pcall(function()
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            local hit = mouse.Hit
            local target = mouse.Target
        end
    end)
    
    if not success4 then
        table.insert(blocked, {
            name = "Anti-Aimbot (Mouse Protegido)",
            risk = 0.7,
            type = "anti_exploit"
        })
    end
    
    -- Verifica WorldToViewport (usado para aimbot)
    local success5 = pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = cam:WorldToViewportPoint(head.Position)
            end
        end
    end)
    
    if not success5 then
        table.insert(blocked, {
            name = "Anti-Aimbot (WorldToViewport Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    return blocked
end,

-- 18. Anti-Hitbox Expander
AntiHitbox = function()
    local blocked = {}
    
    -- Verifica se consegue acessar partes do corpo
    local success1 = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                local parts = player.Character:GetChildren()
                for _, part in ipairs(parts) do
                    if part:IsA("BasePart") then
                        local size = part.Size
                        break
                    end
                end
                break
            end
        end
    end)
    
    if not success1 then
        table.insert(blocked, {
            name = "Anti-Hitbox (Partes do Corpo Protegidas)",
            risk = 0.6,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue modificar tamanho de partes
    local success2 = pcall(function()
        if LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local oldSize = head.Size
                head.Size = Vector3.new(10, 10, 10)
                head.Size = oldSize
            end
        end
    end)
    
    if not success2 then
        table.insert(blocked, {
            name = "Anti-Hitbox (Size Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue acessar Transparência
    local success3 = pcall(function()
        if LocalPlayer.Character then
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then
                local trans = head.Transparency
            end
        end
    end)
    
    if not success3 then
        table.insert(blocked, {
            name = "Anti-Hitbox (Transparency Protegido)",
            risk = 0.6,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue modificar CanCollide
    local success4 = pcall(function()
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    local cc = part.CanCollide
                    break
                end
            end
        end
    end)
    
    if not success4 then
        table.insert(blocked, {
            name = "Anti-Hitbox (CanCollide Protegido)",
            risk = 0.5,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue acessar MeshId (hitbox customizada)
    local success5 = pcall(function()
        if LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("MeshPart") then
                    local meshId = part.MeshId
                    break
                end
            end
        end
    end)
    
    if not success5 then
        table.insert(blocked, {
            name = "Anti-Hitbox (MeshPart Protegido)",
            risk = 0.5,
            type = "anti_exploit"
        })
    end
    
    return blocked
end,

-- 19. Anti-Silent Aim (CORRIGIDO)
AntiSilentAim = function()
    local blocked = {}
    
    -- Verifica se consegue acessar remotamente partes de jogadores
    local success1 = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local hp = humanoid.Health
                    break
                end
            end
        end
    end)
    
    if not success1 then
        table.insert(blocked, {
            name = "Anti-Silent Aim (Health de Inimigos Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    -- Verifica Raycast (usado para silent aim)
    local success2 = pcall(function()
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        local origin = Vector3.new(0, 0, 0)
        local direction = Vector3.new(0, 100, 0)
        
        local result = Workspace:Raycast(origin, direction, rayParams)
    end)
    
    if not success2 then
        table.insert(blocked, {
            name = "Anti-Silent Aim (Raycast Protegido)",
            risk = 0.9,
            type = "anti_exploit"
        })
    end
    
    return blocked
end,

-- 20. Anti-Trigger Bot
AntiTriggerBot = function()
    local blocked = {}
    
    -- Verifica se consegue detectar mouse
    local success1 = pcall(function()
        local mouse = LocalPlayer:GetMouse()
        if mouse then
            local target = mouse.Target
        end
    end)
    
    if not success1 then
        table.insert(blocked, {
            name = "Anti-Trigger Bot (Mouse Target Protegido)",
            risk = 0.7,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue usar UserInputService
    local success2 = pcall(function()
        local uis = game:GetService("UserInputService")
        local mouseLocation = uis:GetMouseLocation()
    end)
    
    if not success2 then
        table.insert(blocked, {
            name = "Anti-Trigger Bot (Input Protegido)",
            risk = 0.6,
            type = "anti_exploit"
        })
    end
    
    return blocked
end,

-- 21. Anti-Prediction (usado em aimbot avançado)
AntiPrediction = function()
    local blocked = {}
    
    -- Verifica se consegue acessar velocidade de outros jogadores
    local success1 = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local vel = rootPart.Velocity
                    break
                end
            end
        end
    end)
    
    if not success1 then
        table.insert(blocked, {
            name = "Anti-Prediction (Velocity de Inimigos Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    -- Verifica se consegue acessar CFrame de outros
    local success2 = pcall(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local cf = head.CFrame
                    break
                end
            end
        end
    end)
    
    if not success2 then
        table.insert(blocked, {
            name = "Anti-Prediction (CFrame de Inimigos Protegido)",
            risk = 0.8,
            type = "anti_exploit"
        })
    end
    
    return blocked
end,
-- 22. Detector de Conexões Suspeitas (Anti-Fly/Anti-Teleport)
ConnectionMonitor = function()
    local blocked = {}
    
    if LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        
        -- Verificar conexões na RootPart (CFrame = Teleport/Fly)
        if rootPart and getconnections then
            -- Monitora CFrame (usado para detectar teleport/fly)
            local cframeConns = getconnections(rootPart:GetPropertyChangedSignal("CFrame"))
            local externalConns = 0
            
            for _, conn in ipairs(cframeConns) do
                if conn.Enabled and conn.Function then
                    -- Verifica se NÃO é do Roblox (sistema)
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") and not fnString:find("Animate") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Teleport/Fly (CFrame Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.7 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
            
            -- Monitora Velocity (usado para detectar fly/speed)
            local velConns = getconnections(rootPart:GetPropertyChangedSignal("Velocity"))
            externalConns = 0
            
            for _, conn in ipairs(velConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") and not fnString:find("Control") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Fly/Speed (Velocity Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.7 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
            
            -- Monitora Position (detecção geral de movimento)
            local posConns = getconnections(rootPart:GetPropertyChangedSignal("Position"))
            externalConns = 0
            
            for _, conn in ipairs(posConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Movement (Position Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.6 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
        end
        
        -- Verificar conexões no Humanoid (Health/WalkSpeed/JumpPower)
        if humanoid and getconnections then
            -- Monitora Health (God Mode)
            local healthConns = getconnections(humanoid:GetPropertyChangedSignal("Health"))
            local externalConns = 0
            
            for _, conn in ipairs(healthConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") and not fnString:find("Animate") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-God Mode (Health Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.8 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
            
            -- Monitora WalkSpeed (Speed Hack)
            local speedConns = getconnections(humanoid:GetPropertyChangedSignal("WalkSpeed"))
            externalConns = 0
            
            for _, conn in ipairs(speedConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") and not fnString:find("Animate") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Speed (WalkSpeed Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.7 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
            
            -- Monitora JumpPower
            local jumpConns = getconnections(humanoid:GetPropertyChangedSignal("JumpPower"))
            externalConns = 0
            
            for _, conn in ipairs(jumpConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Jump (JumpPower Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.6 + (externalConns * 0.05),
                    type = "connection_monitor"
                })
            end
        end
    end
    
    return blocked
end,

-- 23. Detector de Remotes Suspeitos
RemoteScanner = function()
    local blocked = {}
    
    local suspiciousNames = {
        "Check", "Validation", "Physics", "Ack", "Report",
        "AntiCheat", "AntiFly", "AntiSpeed", "AntiTeleport",
        "Integrity", "Monitor", "Watch", "Detect", "Scan",
        "Verify", "Proof", "Challenge", "Response", "Heartbeat"
    }
    
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:GetDescendants()
        local suspiciousRemotes = {}
        
        for _, obj in ipairs(remotes) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                
                -- Verifica nomes suspeitos
                for _, suspicious in ipairs(suspiciousNames) do
                    if name:find(suspicious:lower()) then
                        if not suspiciousRemotes[suspicious] then
                            suspiciousRemotes[suspicious] = 0
                        end
                        suspiciousRemotes[suspicious] = suspiciousRemotes[suspicious] + 1
                    end
                end
                
                -- Verifica nomes aleatórios (padrão de ofuscação)
                local randomPattern = 0
                for i = 1, #name do
                    local char = name:sub(i, i)
                    if char == "l" or char == "I" or char == "|" then
                        randomPattern = randomPattern + 1
                    end
                end
                
                if randomPattern > #name * 0.5 and #name > 8 then
                    if not suspiciousRemotes["Ofuscado"] then
                        suspiciousRemotes["Ofuscado"] = 0
                    end
                    suspiciousRemotes["Ofuscado"] = suspiciousRemotes["Ofuscado"] + 1
                end
            end
        end
        
        -- Reportar remotes suspeitos
        for category, count in pairs(suspiciousRemotes) do
            if count > 0 then
                table.insert(blocked, {
                    name = "Remotes " .. category .. " (" .. count .. " encontrados)",
                    risk = math.min(0.9, 0.4 + (count * 0.1)),
                    type = "remote_scanner"
                })
            end
        end
    end)
    
    return blocked
end,
-- 24. Detector de Anti-Aimbot por Metadados
AntiAimbotMeta = function()
    local blocked = {}
    
    -- Verifica se há scripts que monitoram o ângulo da câmera
    if getconnections then
        local cam = Workspace.CurrentCamera
        if cam then
            -- Monitora mudanças na câmera (usado por anti-aimbot)
            local cframeConns = getconnections(cam:GetPropertyChangedSignal("CFrame"))
            local externalConns = 0
            
            for _, conn in ipairs(cframeConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") and not fnString:find("Camera") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Aimbot (Câmera Monitorada - " .. externalConns .. " conexões)",
                    risk = 0.8 + (externalConns * 0.05),
                    type = "aimbot_meta"
                })
            end
            
            -- Monitora CameraType (anti-aimbot bloqueia Scriptable)
            local camTypeConns = getconnections(cam:GetPropertyChangedSignal("CameraType"))
            externalConns = 0
            
            for _, conn in ipairs(camTypeConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-Aimbot (CameraType Monitorado - " .. externalConns .. " conexões)",
                    risk = 0.7 + (externalConns * 0.05),
                    type = "aimbot_meta"
                })
            end
        end
    end
    
    -- Verifica remotes relacionados a aimbot
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:GetDescendants()
        local aimbotRemotes = {"Aimbot", "AimCheck", "AngleCheck", "Shot", "Bullet", "Hit"}
        
        for _, obj in ipairs(remotes) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                for _, keyword in ipairs(aimbotRemotes) do
                    if name:find(keyword:lower()) then
                        table.insert(blocked, {
                            name = "Possível Anti-Aimbot (Remote: " .. obj.Name .. ")",
                            risk = 0.7,
                            type = "aimbot_meta"
                        })
                        break
                    end
                end
            end
        end
    end)
    
    return blocked
end,
-- 25. Detector de Anti-ESP por Metadados
AntiESPMeta = function()
    local blocked = {}
    
    -- Verifica remotes relacionados a ESP/Wallhack
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:GetDescendants()
        local espRemotes = {"ESP", "Wall", "Wallhack", "Highlight", "Cham", "Outline", "ESP", "Vision", "Render"}
        
        for _, obj in ipairs(remotes) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                for _, keyword in ipairs(espRemotes) do
                    if name:find(keyword:lower()) then
                        table.insert(blocked, {
                            name = "Possível Anti-ESP (Remote: " .. obj.Name .. ")",
                            risk = 0.7,
                            type = "esp_meta"
                        })
                        break
                    end
                end
            end
        end
    end)
    
    -- Verifica se há scripts monitorando Adornee/Parent (usado por ESP)
    if getconnections and LocalPlayer.Character then
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head then
            local parentConns = getconnections(head:GetPropertyChangedSignal("Parent"))
            local externalConns = 0
            
            for _, conn in ipairs(parentConns) do
                if conn.Enabled and conn.Function then
                    local fnString = tostring(conn.Function)
                    if not fnString:find("PlayerScripts") then
                        externalConns = externalConns + 1
                    end
                end
            end
            
            if externalConns > 0 then
                table.insert(blocked, {
                    name = "Anti-ESP (Head Monitorada - " .. externalConns .. " conexões)",
                    risk = 0.6 + (externalConns * 0.05),
                    type = "esp_meta"
                })
            end
        end
    end
    
    -- Verifica se consegue criar BillboardGui (usado por ESP)
    local success = pcall(function()
        local bill = Instance.new("BillboardGui")
        bill.AlwaysOnTop = true
        bill:Destroy()
    end)
    
    if not success then
        table.insert(blocked, {
            name = "Anti-ESP (AlwaysOnTop Bloqueado)",
            risk = 0.7,
            type = "esp_meta"
        })
    end
    
    return blocked
end,
-- 26. Detector de Tags e Attributes Suspeitos
TagScanner = function()
    local blocked = {}
    
    -- Verifica tags no Workspace
    pcall(function()
        -- Procura por tags de anti-cheat
        if Workspace:FindFirstChild("AntiCheat") then
            table.insert(blocked, {
                name = "Anti-Cheat Detectado (Tag: AntiCheat no Workspace)",
                risk = 0.9,
                type = "tag_scan"
            })
        end
        
        if Workspace:FindFirstChild("Security") then
            table.insert(blocked, {
                name = "Anti-Cheat Detectado (Tag: Security no Workspace)",
                risk = 0.8,
                type = "tag_scan"
            })
        end
        
        -- Verifica pastas ocultas
        local hiddenFolders = {"__AC", "__SEC", "__ANTICHEAT", "__PROTECT"}
        for _, folderName in ipairs(hiddenFolders) do
            if Workspace:FindFirstChild(folderName) then
                table.insert(blocked, {
                    name = "Anti-Cheat Pastas Ocultas: " .. folderName,
                    risk = 0.9,
                    type = "tag_scan"
                })
            end
        end
    end)
    
    -- Verifica Attributes no LocalPlayer
    pcall(function()
        if LocalPlayer:GetAttribute("IsVerified") ~= nil then
            table.insert(blocked, {
                name = "Sistema de Verificação Detectado (IsVerified)",
                risk = 0.7,
                type = "tag_scan"
            })
        end
        
        if LocalPlayer:GetAttribute("AntiCheat") ~= nil then
            table.insert(blocked, {
                name = "Anti-Cheat Attribute no Jogador",
                risk = 0.8,
                type = "tag_scan"
            })
        end
    end)
    
    -- Verifica nomes de scripts no ReplicatedStorage
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local suspiciousScripts = {"Anti", "Cheat", "Fly", "Speed", "Aimbot", "ESP", "Detect", "Monitor"}
        
        for _, obj in ipairs(rs:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
                local name = obj.Name:lower()
                for _, keyword in ipairs(suspiciousScripts) do
                    if name:find(keyword:lower()) then
                        table.insert(blocked, {
                            name = "Script Anti-Cheat: " .. obj.Name,
                            risk = 0.8,
                            type = "tag_scan"
                        })
                        break
                    end
                end
            end
        end
    end)
    
    return blocked
end,
-- 27. HCI Analysis (Interação Humano-Computador)
HCIAnalysis = function()
    local blocked = {}
    
    -- Verifica se o mouse existe
    local mouse = LocalPlayer:GetMouse()
    if mouse then
        -- Analisar movimento do mouse (entropia)
        local mouseHistory = {}
        local lastMousePos = Vector2.new(mouse.X, mouse.Y)
        local startTime = tick()
        
        -- Coletar amostras por 1 segundo
        while tick() - startTime < 1 do
            local currentPos = Vector2.new(mouse.X, mouse.Y)
            local delta = (currentPos - lastMousePos).Magnitude
            
            if delta > 0 then
                table.insert(mouseHistory, {
                    pos = currentPos,
                    delta = delta,
                    time = tick()
                })
            end
            
            lastMousePos = currentPos
            task.wait(0.05)
        end
        
        -- Analisar padrões
        if #mouseHistory > 10 then
            -- Calcular entropia do movimento
            local totalDistance = 0
            local angleChanges = 0
            local prevAngle = nil
            
            for i = 2, #mouseHistory do
                local dx = mouseHistory[i].pos.X - mouseHistory[i-1].pos.X
                local dy = mouseHistory[i].pos.Y - mouseHistory[i-1].pos.Y
                totalDistance = totalDistance + math.sqrt(dx*dx + dy*dy)
                
                local angle = math.atan2(dy, dx)
                if prevAngle then
                    local angleDelta = math.abs(angle - prevAngle)
                    if angleDelta > 0.5 then
                        angleChanges = angleChanges + 1
                    end
                end
                prevAngle = angle
            end
            
            -- Movimento muito linear = aimbot
            if angleChanges < 3 and totalDistance > 100 then
                table.insert(blocked, {
                    name = "HCI: Movimento Linear Detectado (Possível Aimbot)",
                    risk = 0.7,
                    type = "hci_analysis"
                })
            end
            
            -- Reação muito rápida = não é humano
            local avgDelta = totalDistance / #mouseHistory
            if avgDelta > 50 then
                table.insert(blocked, {
                    name = "HCI: Velocidade de Mouse Anormal",
                    risk = 0.6,
                    type = "hci_analysis"
                })
            end
        end
    end
    
    return blocked
end,

-- 28. Memory Integrity (Detecção de Injeção)
MemoryIntegrity = function()
    local blocked = {}
    
    -- Verifica se há hooks na metatable
    pcall(function()
        if getrawmetatable then
            local mt = getrawmetatable(game)
            
            -- Verificar __namecall
            if mt and mt.__namecall then
                local nc = tostring(mt.__namecall)
                if nc:find("function") and not nc:find("PlayerScripts") then
                    table.insert(blocked, {
                        name = "Memória: Hook no __namecall Detectado",
                        risk = 0.9,
                        type = "memory_integrity"
                    })
                end
            end
            
            -- Verificar __index
            if mt and mt.__index then
                local idx = tostring(mt.__index)
                if idx:find("function") and not idx:find("PlayerScripts") then
                    table.insert(blocked, {
                        name = "Memória: Hook no __index Detectado",
                        risk = 0.8,
                        type = "memory_integrity"
                    })
                end
            end
        end
    end)
    
    -- Verifica NaN (injeção de código malicioso)
    pcall(function()
        local testValue = 0 / 0
        if testValue ~= testValue then
            -- NaN detectado, possível injeção
            table.insert(blocked, {
                name = "Memória: NaN Detection (Possível Injeção)",
                risk = 0.7,
                type = "memory_integrity"
            })
        end
    end)
    
    return blocked
end,

-- 29. Decoy System (Iscas para Anti-Cheats)
DecoySystem = function()
    local blocked = {}
    
    -- Criar um RemoteEvent falso como isca
    pcall(function()
        local decoyRemote = Instance.new("RemoteEvent")
        decoyRemote.Name = "__AntiCheat_Decoy"
        decoyRemote.Parent = nil  -- Não coloca em lugar nenhum
        
        -- Se algum script tentar acessar, é suspeito
        local connectionCount = 0
        local conn = decoyRemote.OnServerEvent:Connect(function()
            connectionCount = connectionCount + 1
        end)
        
        -- Verificar após 2 segundos
        task.wait(2)
        
        if connectionCount > 0 then
            table.insert(blocked, {
                name = "Decoy: RemoteEvent Falso Ativado!",
                risk = 0.9,
                type = "decoy_system"
            })
        end
        
        conn:Disconnect()
        decoyRemote:Destroy()
    end)
    
    -- Criar um NPC invisível como isca
    pcall(function()
        local decoyNPC = Instance.new("Model")
        decoyNPC.Name = "__NPC_Decoy"
        
        -- Se algum script tentar acessar este NPC
        task.wait(1)
        
        if decoyNPC.Parent then
            table.insert(blocked, {
                name = "Decoy: NPC Falso Detectado!",
                risk = 0.8,
                type = "decoy_system"
            })
        end
        
        decoyNPC:Destroy()
    end)
    
    return blocked
end,

-- 30. Network Behavior (Anomalias de Rede)
NetworkBehavior = function()
    local blocked = {}
    
    -- Monitorar spikes de remotes
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local remotes = rs:GetDescendants()
        local remoteEvents = {}
        
        for _, obj in ipairs(remotes) do
            if obj:IsA("RemoteEvent") then
                remoteEvents[obj] = 0
            end
        end
        
        -- Verificar se há muitos remotes (spike)
        if #remotes > 100 then
            table.insert(blocked, {
                name = "Rede: Muitos RemoteEvents (" .. #remotes .. ")",
                risk = 0.6,
                type = "network_behavior"
            })
        end
        
        -- Verificar dessincronização
        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
        if ping > 200 then
            table.insert(blocked, {
                name = "Rede: Ping Alto Detectado (" .. ping .. "ms)",
                risk = 0.4,
                type = "network_behavior"
            })
        end
    end)
    
    return blocked
end
}

-- =============================================
-- 🧠 Q-LEARNING
-- =============================================

local function GetState()
    local knownCount = 0
    local totalRisk = 0
    
    for _, cheat in pairs(OracleShield.KnownCheats) do
        knownCount = knownCount + 1
        totalRisk = totalRisk + (cheat.risk or 0)
    end
    
    local avgRisk = knownCount > 0 and (totalRisk / knownCount) or 0
    
    local riskLevel = "low"
    if avgRisk > 0.6 then riskLevel = "critical"
    elseif avgRisk > 0.4 then riskLevel = "high"
    elseif avgRisk > 0.2 then riskLevel = "medium"
    end
    
    return string.format("%s_%d", riskLevel, knownCount)
end

function OracleShield.ChooseAction()
    local state = GetState()
    
    if not OracleShield.QTable[state] then
        OracleShield.QTable[state] = {}
        for _, action in ipairs(OracleShield.Actions) do
            OracleShield.QTable[state][action] = 0
        end
    end
    
    if math.random() < OracleShield.DNA.ExplorationRate then
        return OracleShield.Actions[math.random(1, #OracleShield.Actions)], state
    else
        local bestAction, bestValue = nil, -math.huge
        for action, value in pairs(OracleShield.QTable[state]) do
            if value > bestValue then
                bestValue = value
                bestAction = action
            end
        end
        return bestAction or OracleShield.Actions[1], state
    end
end

function OracleShield.Learn(state, action, reward, nextState)
    if not OracleShield.QTable[nextState] then
        OracleShield.QTable[nextState] = {}
        for _, act in ipairs(OracleShield.Actions) do
            OracleShield.QTable[nextState][act] = 0
        end
    end
    
    local currentQ = OracleShield.QTable[state][action] or 0
    local maxNextQ = 0
    
    for _, value in pairs(OracleShield.QTable[nextState]) do
        maxNextQ = math.max(maxNextQ, value)
    end
    
    local newQ = currentQ + OracleShield.DNA.LearningRate * (
        reward + OracleShield.DNA.DiscountFactor * maxNextQ - currentQ
    )
    
    OracleShield.QTable[state][action] = newQ
    
    table.insert(OracleShield.History, {
        time = tick(),
        state = state,
        action = action,
        reward = reward
    })
    
    return newQ
end

-- =============================================
-- 🔍 SCAN PRINCIPAL
-- =============================================

function OracleShield.Scan(deepScan)
    local startTime = tick()
    local allDetected = {}
    
    -- Scans normais (sempre rodam)
    for detectorName, detectorFn in pairs(PassiveDetector) do
        local success, results = pcall(detectorFn)
        if success and results then
            for _, result in ipairs(results) do
                allDetected[result.name] = result
            end
        end
    end
    
    -- ⚡ DEEP SCAN: Testes adicionais que só rodam no modo profundo
    if deepScan then
        -- Scan extra de serviços
        local extraServices = {"RobloxGui", "CorePackages"}
        for _, serviceName in ipairs(extraServices) do
            local success = pcall(function()
                local service = game:GetService(serviceName)
                if service then
                    local children = service:GetChildren()
                end
            end)
            
            if not success then
                allDetected["Deep: " .. serviceName] = {
                    name = "Deep: " .. serviceName .. " Protegido",
                    risk = 0.7,
                    type = "deep_scan"
                }
            end
        end
        
        -- Scan de conexões remotas
        local successRemote = pcall(function()
            local rs = game:GetService("ReplicatedStorage")
            local remotes = rs:GetDescendants()
            local remoteCount = 0
            for _, obj in ipairs(remotes) do
                if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                    remoteCount = remoteCount + 1
                    if remoteCount > 50 then break end
                end
            end
        end)
        
        if not successRemote then
            allDetected["Deep: ReplicatedStorage"] = {
                name = "Deep: ReplicatedStorage Protegido",
                risk = 0.8,
                type = "deep_scan"
            }
        end
    end
    
    -- Processar descobertas
    local newDiscoveries = 0
    
    for name, detection in pairs(allDetected) do
        if not OracleShield.KnownCheats[name] then
            OracleShield.KnownCheats[name] = {
                risk = detection.risk,
                type = detection.type,
                firstSeen = tick(),
                count = 1,
                confidence = 0.3
            }
            newDiscoveries = newDiscoveries + 1
            OracleShield.Metrics.Discoveries = OracleShield.Metrics.Discoveries + 1
            print("  🛡️ DESCOBERTO: " .. name .. " (Risco: " .. (detection.risk * 100) .. "%)")
        else
            OracleShield.KnownCheats[name].count = (OracleShield.KnownCheats[name].count or 0) + 1
            OracleShield.KnownCheats[name].confidence = math.min(1, (OracleShield.KnownCheats[name].confidence or 0) + 0.1)
        end
    end
    
    OracleShield.Metrics.TotalScans = OracleShield.Metrics.TotalScans + 1
    
    if newDiscoveries == 0 then
        OracleShield.Metrics.Confidence = math.min(1, OracleShield.Metrics.Confidence + 0.05)
    end
    
    local totalRisk = 0
    local knownCount = 0
    for _, cheat in pairs(OracleShield.KnownCheats) do
        totalRisk = totalRisk + cheat.risk
        knownCount = knownCount + 1
    end
    OracleShield.Metrics.RiskLevel = knownCount > 0 and (totalRisk / knownCount) or 0
    
    local duration = tick() - startTime
    
    return {
        newDiscoveries = newDiscoveries,
        totalDetected = knownCount,
        duration = duration,
        deepScan = deepScan
    }
end
function OracleShield.FreshScan()
    print("🔄 Resetando e re-escanando TUDO...")
    
    OracleShield.KnownCheats = {}
    OracleShield.Metrics = {TotalScans = 0, Discoveries = 0, RiskLevel = 0, Confidence = 0.5}
    
    pcall(function()
        if isfile and isfile(OracleShield.MemoryFile) then
            if delfile then delfile(OracleShield.MemoryFile) end
        end
    end)
    
    print("🔍 Escaneando...")
    local result = OracleShield.Scan(true)
    print("✅ Scan completo! " .. result.totalDetected .. " anti-cheats detectados.")
    
    -- Mostrar resultado SEM chamar ShowReport
    for name, cheat in pairs(OracleShield.KnownCheats) do
        print("  🛡️ " .. name .. " (Risco: " .. math.floor(cheat.risk * 100) .. "%)")
    end
end
-- =============================================
-- 📊 RELATÓRIO COMPLETO
-- =============================================

function OracleShield.ShowReport()
    local knownCount = 0
    local totalRisk = 0
    
    for _, cheat in pairs(OracleShield.KnownCheats) do
        knownCount = knownCount + 1
        totalRisk = totalRisk + (cheat.risk or 0)
    end
    
    local avgRisk = knownCount > 0 and (totalRisk / knownCount) or 0
    
    print("╔══════════════════════════════════════╗")
    print("║  🛡️ ORACLE SHIELD v3.0             ║")
    print("║  Anti-cheats: " .. string.format("%-20d", knownCount) .. "║")
    print("║  Risco: " .. string.format("%-26.1f", avgRisk * 100) .. "%║")
    print("║  Confiança: " .. string.format("%-22.1f", OracleShield.Metrics.Confidence * 100) .. "%║")
    print("║  Scans: " .. string.format("%-25d", OracleShield.Metrics.TotalScans) .. "║")
    print("╚══════════════════════════════════════╝")
    
    if knownCount > 0 then
        local sorted = {}
        for name, cheat in pairs(OracleShield.KnownCheats) do
            table.insert(sorted, {name = name, risk = cheat.risk, count = cheat.count or 0})
        end
        
        table.sort(sorted, function(a, b) return a.risk > b.risk end)
        
        print("\n🔥 TOP 10 RISCOS:")
        for i = 1, math.min(10, #sorted) do
            local r = sorted[i]
            print(string.format("  %2d. %-40s %.0f%% [%dx]", i, r.name:sub(1, 40), r.risk * 100, r.count))
        end
    end
    
    print("\n🛡️ RESUMO:")
    if avgRisk > 0.7 then
        print("  ⚫ CRÍTICO: Jogo extremamente protegido!")
    elseif avgRisk > 0.5 then
        print("  🔴 ALTO: Muitas proteções ativas.")
    elseif avgRisk > 0.3 then
        print("  🟡 MODERADO: Proteções médias.")
    else
        print("  🟢 BAIXO: Jogo pouco protegido.")
    end
end

-- =============================================
-- 🔄 LOOP PRINCIPAL
-- =============================================

task.spawn(function()
    print("🛡️ Oracle Shield v3.0 - Detector COMPLETO")
    print("   ✅ " .. (function() local c = 0; for _ in pairs(PassiveDetector) do c = c + 1 end; return c end)() .. " detectores ativos")
    
    task.wait(3)
    
    while true do
        local action, state = OracleShield.ChooseAction()
        local result = nil
        local reward = 0
        
        if action == "Scan" then
            result = OracleShield.Scan(false)
            reward = result.totalDetected * 0.1
        elseif action == "DeepScan" then
            result = OracleShield.Scan(true)
            reward = result.totalDetected * 0.15
        elseif action == "Adapt" then
            if OracleShield.Metrics.RiskLevel > 0.6 then
                OracleShield.DNA.ScanFrequency = math.max(15, OracleShield.DNA.ScanFrequency - 10)
                reward = 0.2
            else
                OracleShield.DNA.ScanFrequency = math.min(60, OracleShield.DNA.ScanFrequency + 5)
                reward = 0.1
            end
        elseif action == "Ignore" then
            reward = OracleShield.Metrics.Confidence > 0.7 and 0.05 or -0.1
        end
        
        local nextState = GetState()
        OracleShield.Learn(state, action, reward, nextState)
        
        SaveBrain()
        
        if result and result.newDiscoveries > 0 then
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "🛡️ Oracle Shield",
                    Text = result.newDiscoveries .. " nova(s) proteção(ões) detectada(s)!",
                    Duration = 4
                })
            end)
        end
        
        task.wait(OracleShield.DNA.ScanFrequency)
    end
end)

-- =============================================
-- 🚀 INICIALIZAÇÃO
-- =============================================

LoadBrain()
getgenv().OracleShield = OracleShield

task.spawn(function()
    task.wait(2)
    print("🔍 Executando primeiro scan...")
    local result = OracleShield.Scan(true)
    print("✅ " .. result.totalDetected .. " anti-cheats detectados!")
    OracleShield.ShowReport()
end)

print("✅ Oracle Shield v3.0 PRONTO!")
print("📋 OracleShield.ShowReport() - Relatório")
print("📋 OracleShield.Scan() - Scan manual")
print("📋 OracleShield.FreshScan() - Re-scan do zero")
