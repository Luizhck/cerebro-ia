local Players = game:GetService("Players")
local char = Players.LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then return "Sem personagem" end

if hrp:FindFirstChild("FlyBV") then
    hrp.FlyBV:Destroy()
    hrp.FlyBG:Destroy()
    return "Fly desativado! 🛬"
else
    local bv = Instance.new("BodyVelocity", hrp)
    bv.Name = "FlyBV"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    local bg = Instance.new("BodyGyro", hrp)
    bg.Name = "FlyBG"
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    return "Fly ativado! 🛫"
end
