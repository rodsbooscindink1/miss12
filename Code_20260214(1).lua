-- Blox Fruits 自动攻击 · 完整版（防检测 + UI开关）
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Core = {}
local AttackLoop = nil

--=======================
-- 【1】基础防检测
--=======================
local function AntiDetect()
    -- 隐藏脚本环境
    local genv = getgenv()
    genv.script = nil
    genv.loadstring = nil
    
    -- 屏蔽远程监控
    for _, v in pairs(getconnections(game:GetService("ScriptContext").Error)) do
        v:Disable()
    end
    
    -- 清理垃圾回收痕迹
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" and rawget(v, "secure") then
            rawset(v, "secure", nil)
        end
    end
    
    -- 隐藏Remote调用日志
    local oldFire = Instance.new("RemoteEvent").FireServer
    hookfunction(oldFire, function(self, ...)
        return oldFire(self, ...)
    end)
    
    print("✅ 防检测已启动")
end
AntiDetect()

--=======================
-- 【2】UI开关面板
--=======================
local function CreateUI()
    -- 销毁旧UI避免重复
    if LocalPlayer.PlayerGui:FindFirstChild("AutoAttackUI") then
        LocalPlayer.PlayerGui.AutoAttackUI:Destroy()
    end

    local Gui = Instance.new("ScreenGui")
    Gui.Name = "AutoAttackUI"
    Gui.Parent = LocalPlayer.PlayerGui
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 160, 0, 50)
    MainFrame.Position = UDim2.new(0.02, 0, 0.2, 0)
    MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    MainFrame.BorderSizePixel = 0
    MainFrame.Corner = Instance.new("UICorner")
    MainFrame.Parent = Gui

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.TextColor3 = Color3.new(1,1,1)
    ToggleBtn.TextScaled = true
    ToggleBtn.Text = "🟢 自动攻击：已开启"
    ToggleBtn.Parent = MainFrame

    -- 配置
    local Config = {
        Enabled = true,
        AttackRange = 35,
        AttackDelay = 0.2
    }

    -- 开关逻辑
    ToggleBtn.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        if Config.Enabled then
            ToggleBtn.Text = "🟢 自动攻击：已开启"
        else
            ToggleBtn.Text = "🔴 自动攻击：已关闭"
        end
    end)

    return Config
end

local Config = CreateUI()

--=======================
-- 【3】核心组件加载
--=======================
local function WaitForChild(parent, name, t)
    local suc, obj = pcall(function()
        return parent:WaitForChild(name, t or 5)
    end)
    return suc and obj or nil
end

local function LoadCore()
    local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    Core.Char = Char
    Core.HRP = WaitForChild(Char, "HumanoidRootPart")
    Core.Hum = WaitForChild(Char, "Humanoid")
    Core.Remotes = WaitForChild(ReplicatedStorage, "Remotes")
    Core.MeleeHit = Core.Remotes and WaitForChild(Core.Remotes, "MeleeHit")
    Core.SwordHit = Core.Remotes and WaitForChild(Core.Remotes, "SwordHit")
    Core.NPCs = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Mobs")
    print("✅ 核心组件就绪")
end

--=======================
-- 【4】索敌
--=======================
local function GetTarget()
    if not Core.NPCs or not Core.HRP then return nil end
    local best, bestDist = nil, Config.AttackRange
    for _, npc in ip(Core.NPCs:GetChildren()) do
        local hum = npc:FindFirstChild("Humanoid")
        local root = npc:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and root then
            local dist = (root.Position - Core.HRP.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = npc
            end
        end
    end
    return best
end

--=======================
-- 【5】自动攻击
--=======================
local function AutoAttack()
    if not Config.Enabled or not Core.Remotes then return end
    local tar = GetTarget()
    if not tar then return end
    local hum = tar.Humanoid
    local root = tar.HumanoidRootPart

    if Core.MeleeHit then
        Core.MeleeHit:FireServer(hum, root.Position)
    end
    if Core.SwordHit then
        Core.SwordHit:FireServer(hum, root.Position)
    end
end

--=======================
-- 【6】启动
--=======================
LoadCore()

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1.2)
    LoadCore()
end)

-- 攻击循环
while task.wait(Config.AttackDelay) do
    AutoAttack()
end