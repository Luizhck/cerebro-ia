local Players = game:GetService("Players")

if _G.AutoFarmLoop then
    _G.AutoFarmLoop = false
    task.wait(0.1)
end

_G.AutoFarmLoop = true

task.spawn(function()
    while _G.AutoFarmLoop do
        pcall(function()
            local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, obj in pairs(workspace:GetDescendants()) do
                if not _G.AutoFarmLoop then break end
                if obj:IsA("Tool") and obj.Parent == workspace then
                    hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.3)
                    pcall(function() obj.Parent = Players.LocalPlayer.Backpack end)
                end
            end
        end)
        task.wait(1)
    end
end)

return "AutoFarm iniciado! 🔄"
