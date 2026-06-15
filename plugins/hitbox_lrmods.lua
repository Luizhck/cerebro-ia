-- ============================================
-- CARD DO HITBOX NA ABA PLUGINS
-- ============================================

-- Carrega o Hitbox Plugin
local HitboxPlugin = nil
local HitboxPanel = nil
local HitboxFrame = nil
local HitboxStatus = nil
local HitboxBorder = nil

-- Frame principal do card
HitboxFrame = Instance.new("Frame")
HitboxFrame.Size = UDim2.new(1, 0, 0, 40)
HitboxFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
HitboxFrame.BorderSizePixel = 1
HitboxFrame.BorderColor3 = Color3.fromRGB(60, 60, 70)
HitboxFrame.Parent = PluginsScroll

local HitboxCorner = Instance.new("UICorner")
HitboxCorner.CornerRadius = UDim.new(0, 8)
HitboxCorner.Parent = HitboxFrame

-- Ícone
local HitboxIcon = Instance.new("TextLabel")
HitboxIcon.Size = UDim2.new(0, 30, 1, 0)
HitboxIcon.Position = UDim2.new(0, 5, 0, 0)
HitboxIcon.BackgroundTransparency = 1
HitboxIcon.Text = "🎯"
HitboxIcon.TextSize = 18
HitboxIcon.ZIndex = 2
HitboxIcon.Parent = HitboxFrame

-- Nome
local HitboxName = Instance.new("TextLabel")
HitboxName.Size = UDim2.new(1, -130, 1, 0)
HitboxName.Position = UDim2.new(0, 38, 0, 0)
HitboxName.BackgroundTransparency = 1
HitboxName.Text = "Hitbox Extender"
HitboxName.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxName.Font = Enum.Font.GothamBold
HitboxName.TextSize = 12
HitboxName.TextXAlignment = Enum.TextXAlignment.Left
HitboxName.ZIndex = 2
HitboxName.Parent = HitboxFrame

-- Status (ON/OFF)
HitboxStatus = Instance.new("TextLabel")
HitboxStatus.Size = UDim2.new(0, 40, 0, 20)
HitboxStatus.Position = UDim2.new(1, -90, 0.5, -10)
HitboxStatus.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
HitboxStatus.BackgroundTransparency = 0
HitboxStatus.Text = "OFF"
HitboxStatus.TextColor3 = Color3.fromRGB(255, 100, 100)
HitboxStatus.Font = Enum.Font.GothamBold
HitboxStatus.TextSize = 10
HitboxStatus.ZIndex = 2
HitboxStatus.Parent = HitboxFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 4)
StatusCorner.Parent = HitboxStatus

-- Botão Configurar
local HitboxConfigBtn = Instance.new("TextButton")
HitboxConfigBtn.Size = UDim2.new(0, 35, 0, 28)
HitboxConfigBtn.Position = UDim2.new(1, -42, 0.5, -14)
HitboxConfigBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
HitboxConfigBtn.Text = "⚙️"
HitboxConfigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HitboxConfigBtn.Font = Enum.Font.GothamBold
HitboxConfigBtn.TextSize = 14
HitboxConfigBtn.ZIndex = 2
HitboxConfigBtn.Parent = HitboxFrame

local ConfigCorner = Instance.new("UICorner")
ConfigCorner.CornerRadius = UDim.new(0, 6)
ConfigCorner.Parent = HitboxConfigBtn

-- Efeito hover no botão configurar
HitboxConfigBtn.MouseEnter:Connect(function()
    HitboxConfigBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
end)

HitboxConfigBtn.MouseLeave:Connect(function()
    HitboxConfigBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
end)

-- Efeito hover no card inteiro
HitboxFrame.MouseEnter:Connect(function()
    if HitboxStatus.Text == "OFF" then
        HitboxFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    end
end)

HitboxFrame.MouseLeave:Connect(function()
    if HitboxStatus.Text == "OFF" then
        HitboxFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    end
end)

-- Função para atualizar o status visual
local function UpdateHitboxStatus()
    if HitboxPlugin and HitboxStatus and HitboxFrame then
        local settings = HitboxPlugin.GetSettings()
        local isOn = settings.Enabled
        
        -- Atualiza texto e cor do status
        HitboxStatus.Text = isOn and "ON" or "OFF"
        HitboxStatus.TextColor3 = isOn and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(255, 100, 100)
        HitboxStatus.BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 100, 0.3) or Color3.fromRGB(50, 50, 60)
        
        -- Atualiza borda do card
        HitboxFrame.BorderColor3 = isOn and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(60, 60, 70)
        HitboxFrame.BorderSizePixel = isOn and 2 or 1
        
        -- Atualiza fundo do card
        HitboxFrame.BackgroundColor3 = isOn and Color3.fromRGB(30, 50, 35) or Color3.fromRGB(35, 35, 45)
        
        -- Atualiza cor do botão configurar
        HitboxConfigBtn.BackgroundColor3 = isOn and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(60, 60, 70)
    end
end

-- Carrega o plugin
task.spawn(function()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/hitbox_plugin.lua"))()
    end)
    
    if success and result and result.CreateConfigPanel then
        HitboxPlugin = result
        
        -- Cria o painel de configuração (invisível)
        HitboxPanel = HitboxPlugin.CreateConfigPanel(MainGui)
        
        -- Atualiza status inicial
        UpdateHitboxStatus()
        
        -- Loop de atualização do status
        task.spawn(function()
            while task.wait(0.3) do
                UpdateHitboxStatus()
            end
        end)
    else
        -- Mostra erro no card
        HitboxStatus.Text = "ERR"
        HitboxStatus.TextColor3 = Color3.fromRGB(255, 80, 80)
        HitboxFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
        HitboxConfigBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    end
end)

-- Clique no card inteiro alterna ON/OFF
HitboxFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if HitboxPlugin then
            local settings = HitboxPlugin.GetSettings()
            HitboxPlugin.Toggle(not settings.Enabled)
            UpdateHitboxStatus()
        end
    end
end)

-- Botão configurar abre o painel
HitboxConfigBtn.MouseButton1Click:Connect(function()
    if HitboxPanel then
        HitboxPanel.Visible = not HitboxPanel.Visible
    end
end)
