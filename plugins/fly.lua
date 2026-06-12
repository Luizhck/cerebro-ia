local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

-- Se já estiver voando, desativa
if hrp:FindFirstChild("FlyBV") then
    hrp.FlyBV:Destroy()
    hrp.FlyBG:Destroy()
    return "Fly DESATIVADO! 🛬"
end

-- BodyVelocity para mover
local bv = Instance.new("BodyVelocity")
bv.Name = "FlyBV"
bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
bv.Velocity = Vector3.zero
bv.Parent = hrp

-- BodyGyro para estabilizar
local bg = Instance.new("BodyGyro")
bg.Name = "FlyBG"
bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
bg.CFrame = hrp.CFrame
bg.Parent = hrp

-- Loop de controle
local flyConnection
flyConnection = RunService.RenderStepped:Connect(function()
    if not hrp:FindFirstChild("FlyBV") then
        flyConnection:Disconnect()
        return
    end
    
    local direction = Vector3.zero
    local camera = workspace.CurrentCamera
    
    -- Controles PC
    if UIS:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift) then 
        direction = direction - Vector3.new(0, 1, 0) 
    end
    
    -- Controles Mobile (joystick)
    if UIS.TouchEnabled then
        local moveVector = UIS:GetMoveVector()
        if moveVector.Magnitude > 0 then
            direction = direction + (camera.CFrame.RightVector * moveVector.X)
            direction = direction + (camera.CFrame.LookVector * moveVector.Y)
        end
    end
    
    local speed = 50
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then
        speed = 100
    end
    
    if direction.Magnitude > 0 then
        bv.Velocity = direction.Unit * speed
    else
        bv.Velocity = Vector3.new(0, 0.5, 0) -- Flutua parado
    end
end)

return "Fly ATIVADO! 🛫\nWASD = Mover | Space = Subir | Shift = Descer | Ctrl = Turbo"
