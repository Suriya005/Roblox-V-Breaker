-- V-Breaker | ClientMain (Entry Point)
-- StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua

print("[ClientMain] 🚀 เริ่มต้นระบบ Client V-Breaker...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- ============================================================
-- 1. สร้าง UI ชั่วคราวสำหรับทดสอบ (Prototype HUD)
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VBreaker_PrototypeHUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainPanel = Instance.new("Frame")
mainPanel.Size = UDim2.new(0, 250, 0, 100)
mainPanel.Position = UDim2.new(0.5, -125, 1, -120)
mainPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainPanel.BackgroundTransparency = 0.2
mainPanel.BorderSizePixel = 2
mainPanel.BorderColor3 = Color3.fromRGB(50, 220, 50)
mainPanel.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 10)
uiCorner.Parent = mainPanel

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Text = "🦠 V-Breaker (Prototype)"
titleLabel.TextColor3 = Color3.fromRGB(50, 220, 50)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.BackgroundTransparency = 1
titleLabel.Parent = mainPanel

local bioLabel = Instance.new("TextLabel")
bioLabel.Size = UDim2.new(1, -20, 0, 30)
bioLabel.Position = UDim2.new(0, 10, 0, 35)
bioLabel.Text = "🧫 Bio Points: 0"
bioLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bioLabel.Font = Enum.Font.Gotham
bioLabel.TextSize = 16
bioLabel.TextXAlignment = Enum.TextXAlignment.Left
bioLabel.BackgroundTransparency = 1
bioLabel.Parent = mainPanel

local dnaLabel = Instance.new("TextLabel")
dnaLabel.Size = UDim2.new(1, -20, 0, 30)
dnaLabel.Position = UDim2.new(0, 10, 0, 65)
dnaLabel.Text = "🧬 DNA Points: 0"
dnaLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
dnaLabel.Font = Enum.Font.Gotham
equilibriumTextSize = 16
dnaLabel.TextSize = equilibriumTextSize
dnaLabel.TextXAlignment = Enum.TextXAlignment.Left
dnaLabel.BackgroundTransparency = 1
dnaLabel.Parent = mainPanel

local tipLabel = Instance.new("TextLabel")
tipLabel.Size = UDim2.new(0, 300, 0, 30)
tipLabel.Position = UDim2.new(0.5, -150, 1, -160)
tipLabel.Text = "คลิกซ้ายที่ NPC / กล่อง เพื่อปล่อยไวรัส!"
tipLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
tipLabel.Font = Enum.Font.Gotham
tipLabel.TextSize = 14
tipLabel.BackgroundTransparency = 1
tipLabel.Parent = screenGui

-- ============================================================
-- 2. เชื่อมต่อ Remote Events (รับข้อมูลจาก Server)
-- ============================================================
RemoteManager.OnClientEvent(Constants.REMOTES.BIO_POINTS_CHANGED, function(newBio)
	bioLabel.Text = "🧫 Bio Points: " .. newBio
	-- Animate ขยายลดขนาดเบาๆ
	local ts = TweenService:Create(bioLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 20})
	ts:Play()
end)

RemoteManager.OnClientEvent(Constants.REMOTES.DNA_POINTS_CHANGED, function(newDna)
	dnaLabel.Text = "🧬 DNA Points: " .. newDna
	local ts = TweenService:Create(dnaLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 20})
	ts:Play()
end)

RemoteManager.OnClientEvent(Constants.REMOTES.NOTIFICATION, function(message, notifType)
	print("[Notification]", message)
	-- แสดงข้อความเตือนชั่วคราว
	tipLabel.Text = message
	tipLabel.TextColor3 = notifType == "Warning" and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	task.wait(2)
	tipLabel.Text = "คลิกซ้ายที่ NPC / กล่อง เพื่อปล่อยไวรัส!"
	tipLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.SHOW_POPUP, function(text, pos, popupType)
	-- สร้าง Pop-up ตัวเลขลอยขึ้น
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.AlwaysOnTop = true
	
	if pos and pos ~= Vector3.zero then
		billboard.Adornee = nil
		-- สุ่มตำแหน่งกระจายเล็กน้อย
		billboard.StudsOffsetWorldSpace = pos + Vector3.new(math.random(-2,2), math.random(2,4), math.random(-2,2))
	else
		-- ถ้าไม่มี pos ให้แสดงกลางจอ
		local screenPopup = Instance.new("TextLabel")
		screenPopup.Size = UDim2.new(0, 300, 0, 100)
		screenPopup.Position = UDim2.new(0.5, -150, 0.3, -50)
		screenPopup.Text = text
		screenPopup.TextColor3 = popupType == "DNA" and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(50, 220, 50)
		screenPopup.Font = Enum.Font.GothamBold
		screenPopup.TextSize = 36
		screenPopup.BackgroundTransparency = 1
		screenPopup.Parent = screenGui

		local tween = TweenService:Create(screenPopup, TweenInfo.new(1.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.2, -50), TextTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function() screenPopup:Destroy() end)
		return
	end

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Text = text
	textLabel.TextColor3 = popupType == "DNA" and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(50, 220, 50)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 24
	textLabel.BackgroundTransparency = 1
	textLabel.Parent = billboard
	billboard.Parent = pgui

	local tween = TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 4, 0)})
	local tweenAlpha = TweenService:Create(textLabel, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1})
	tween:Play()
	tweenAlpha:Play()
	tween.Completed:Connect(function() billboard:Destroy() end)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.INFECTION_SPREAD, function(targetModel, infectedByUserId)
	if not targetModel then return end

	-- เล่น Particle สีเขียวเรืองแสง
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
	if root then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxassetid://243660364" -- สปอร์เรืองแสง
		pe.Color = ColorSequence.new(Color3.fromRGB(50, 255, 50))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
		pe.Rate = 20
		pe.Speed = NumberRange.new(5, 10)
		pe.Lifetime = NumberRange.new(1, 2)
		pe.SpreadAngle = Vector2.new(45, 45)
		pe.Parent = root

		-- ลบ Particle เมื่อเวลาผ่านไป 3 วินาที
		task.delay(3, function()
			if pe then pe.Enabled = false task.wait(2) pe:Destroy() end
		end)
	end
end)

-- ============================================================
-- 3. ระบบส่งคำสั่งคลิกปล่อยไวรัส (Player Input)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		local target = mouse.Target
		if target then
			-- หา Model ที่เป็นพ่อของ Part นี้
			local model = target:FindFirstAncestorWhichIsA("Model")
			if model and model ~= player.Character then
				RemoteManager.FireServer(Constants.REMOTES.REQUEST_INFECT, model)
			end
		end
	end
end)

print("[ClientMain] ✅ ระบบ Client พร้อมทำงาน!")
