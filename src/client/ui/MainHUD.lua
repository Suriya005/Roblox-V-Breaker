-- V-Breaker | MainHUD (Client UI Module)
-- StarterPlayer/StarterPlayerScripts/Client/ui/MainHUD.lua
-- ระบบหน้าต่าง UI หลัก (Bio/DNA Points, Progress Bar, Pop-ups, Notifications)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))

local MainHUD = {}
local player = Players.LocalPlayer

local screenGui
local bioLabel
local dnaLabel
local progressBar
local progressText
local tipLabel

-- Threshold จาก PlayerService สำหรับคำนวณหลอด Progress
local BIO_TO_DNA_THRESHOLD = 50

function MainHUD.Init()
	print("[MainHUD] 🎨 เริ่มต้นสร้างระบบ Main HUD...")

	local playerGui = player:WaitForChild("PlayerGui")
	
	-- ลบตัวเก่าออกถ้ามี (เพื่อความสะอาดตอนเทสซ้ำ)
	local oldGui = playerGui:FindFirstChild("VBreaker_MainHUD")
	if oldGui then oldGui:Destroy() end

	-- ลบ Prototype HUD เก่าออกด้วย
	local protoGui = playerGui:FindFirstChild("VBreaker_PrototypeHUD")
	if protoGui then protoGui:Destroy() end

	-- 1. สร้าง ScreenGui หลัก
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VBreaker_MainHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- 2. แผงควบคุมหลัก (Main Panel - Bottom Center)
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 320, 0, 130)
	mainPanel.AnchorPoint = Vector2.new(0.5, 1)
	mainPanel.Position = UDim2.new(0.5, 0, 1, -40)
	mainPanel.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	mainPanel.BackgroundTransparency = 0.25
	mainPanel.Parent = screenGui

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0, 16)
	uiCorner.Parent = mainPanel

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(50, 220, 50) -- Toxic Green Border
	uiStroke.Thickness = 2.5
	uiStroke.Transparency = 0.1
	uiStroke.Parent = mainPanel

	-- เพิ่มเงาสะท้อน (Glow Effect)
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(50, 255, 50)
	glowStroke.Thickness = 6
	glowStroke.Transparency = 0.8
	glowStroke.Parent = mainPanel

	-- 3. ป้ายชื่อเกม (Title)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Position = UDim2.new(0, 0, 0, 5)
	titleLabel.Text = "🦠 V-BREAKER : INFECTION ENGINE"
	titleLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 16
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = mainPanel

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1
	titleStroke.Parent = titleLabel

	-- 4. ป้าย Bio Points
	bioLabel = Instance.new("TextLabel")
	bioLabel.Name = "BioLabel"
	bioLabel.Size = UDim2.new(1, -30, 0, 30)
	bioLabel.Position = UDim2.new(0, 15, 0, 35)
	bioLabel.Text = "🧫 Bio Points: 0"
	bioLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bioLabel.Font = Enum.Font.GothamBold
	bioLabel.TextSize = 18
	bioLabel.TextXAlignment = Enum.TextXAlignment.Left
	bioLabel.BackgroundTransparency = 1
	bioLabel.Parent = mainPanel

	local bioStroke = Instance.new("UIStroke")
	bioStroke.Color = Color3.fromRGB(0, 0, 0)
	bioStroke.Thickness = 1.2
	bioStroke.Parent = bioLabel

	-- 5. ป้าย DNA Points
	dnaLabel = Instance.new("TextLabel")
	dnaLabel.Name = "DnaLabel"
	dnaLabel.Size = UDim2.new(1, -30, 0, 30)
	dnaLabel.Position = UDim2.new(0, 15, 0, 65)
	dnaLabel.Text = "🧬 DNA Points: 0"
	dnaLabel.TextColor3 = Color3.fromRGB(150, 210, 255)
	dnaLabel.Font = Enum.Font.GothamBold
	dnaLabel.TextSize = 18
	dnaLabel.TextXAlignment = Enum.TextXAlignment.Left
	dnaLabel.BackgroundTransparency = 1
	dnaLabel.Parent = mainPanel

	local dnaStroke = Instance.new("UIStroke")
	dnaStroke.Color = Color3.fromRGB(0, 0, 0)
	dnaStroke.Thickness = 1.2
	dnaStroke.Parent = dnaLabel

	-- 6. หลอด Progress Bar สู่ DNA ถัดไป
	local progressBg = Instance.new("Frame")
	progressBg.Size = UDim2.new(1, -30, 0, 16)
	progressBg.Position = UDim2.new(0, 15, 0, 100)
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	progressBg.Parent = mainPanel

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 8)
	bgCorner.Parent = progressBg

	local progressStroke = Instance.new("UIStroke")
	progressStroke.Color = Color3.fromRGB(100, 100, 120)
	progressStroke.Thickness = 1
	progressStroke.Parent = progressBg

	progressBar = Instance.new("Frame")
	progressBar.Size = UDim2.new(0, 0, 1, 0)
	progressBar.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
	progressBar.Parent = progressBg

	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 8)
	barCorner.Parent = progressBar

	progressText = Instance.new("TextLabel")
	progressText.Size = UDim2.new(1, 0, 1, 0)
	progressText.Text = "Next DNA: 0 / 50"
	progressText.TextColor3 = Color3.fromRGB(255, 255, 255)
	progressText.Font = Enum.Font.GothamBold
	progressText.TextSize = 12
	progressText.BackgroundTransparency = 1
	progressText.Parent = progressBg

	local pTextStroke = Instance.new("UIStroke")
	pTextStroke.Color = Color3.fromRGB(0, 0, 0)
	pTextStroke.Thickness = 1
	pTextStroke.Parent = progressText

	-- 7. ป้ายแจ้งเตือนคำแนะนำ (Tip / Notification - Top Center)
	tipLabel = Instance.new("TextLabel")
	tipLabel.Size = UDim2.new(0, 400, 0, 40)
	tipLabel.AnchorPoint = Vector2.new(0.5, 0)
	tipLabel.Position = UDim2.new(0.5, 0, 0, 20)
	tipLabel.Text = "🎯 คลิกซ้ายที่เป้าหมายเพื่อปล่อยไวรัสระบาด!"
	tipLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	tipLabel.Font = Enum.Font.GothamBold
	tipLabel.TextSize = 18
	tipLabel.BackgroundTransparency = 0.5
	tipLabel.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
	tipLabel.Parent = screenGui

	local tipCorner = Instance.new("UICorner")
	tipCorner.CornerRadius = UDim.new(0, 8)
	tipCorner.Parent = tipLabel

	-- เส้นขอบกล่องข้อความ (Border)
	local tipBorder = Instance.new("UIStroke")
	tipBorder.Name = "BorderStroke"
	tipBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tipBorder.Color = Color3.fromRGB(255, 255, 100)
	tipBorder.Thickness = 1.5
	tipBorder.Parent = tipLabel

	-- เส้นขอบตัวหนังสือ (Text Outline เพื่อความคมชัด)
	local tipTextStroke = Instance.new("UIStroke")
	tipTextStroke.Name = "TextStroke"
	tipTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	tipTextStroke.Color = Color3.fromRGB(0, 0, 0)
	tipTextStroke.Thickness = 1.2
	tipTextStroke.Parent = tipLabel

	print("[MainHUD] ✅ สร้าง Main HUD สมบูรณ์!")
end

function MainHUD.UpdateBio(bio: number)
	if not bioLabel then return end
	bioLabel.Text = "🧫 Bio Points: " .. bio

	-- Animate ขยายตัวอักษรและเด้งกลับ (Juice Effect)
	local tween = TweenService:Create(bioLabel, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 24})
	tween:Play()

	-- อัปเดตหลอด Progress Bar
	local currentProgress = bio % BIO_TO_DNA_THRESHOLD
	local targetScale = currentProgress / BIO_TO_DNA_THRESHOLD
	progressText.Text = "Next DNA: " .. currentProgress .. " / " .. BIO_TO_DNA_THRESHOLD

	local barTween = TweenService:Create(progressBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(targetScale, 0, 1, 0)})
	barTween:Play()
end

function MainHUD.UpdateDna(dna: number)
	if not dnaLabel then return end
	dnaLabel.Text = "🧬 DNA Points: " .. dna

	-- Animate ขยายตัวอักษรและเปลี่ยนสีชั่วคราว
	local tween = TweenService:Create(dnaLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 26})
	tween:Play()
end

function MainHUD.ShowNotification(message: string, notifType: string)
	if not tipLabel then return end
	tipLabel.Text = message
	
	local isWarning = notifType == "Warning"
	tipLabel.TextColor3 = isWarning and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	
	local border = tipLabel:FindFirstChild("BorderStroke")
	if border then
		border.Color = isWarning and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	end

	-- เขย่าป้ายเตือนเบาๆ
	local startPos = tipLabel.Position
	local shakeTween = TweenService:Create(tipLabel, TweenInfo.new(0.05, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 3, true), {Position = startPos + UDim2.new(0, math.random(-10,10), 0, 0)})
	shakeTween:Play()

	task.wait(2.5)
	tipLabel.Text = "🎯 คลิกซ้ายที่เป้าหมายเพื่อปล่อยไวรัสระบาด!"
	tipLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	if border then border.Color = Color3.fromRGB(255, 255, 100) end
end

function MainHUD.ShowPopup(text: string, pos: Vector3, popupType: string)
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui or not screenGui then return end

	local isDna = popupType == "DNA"
	local color = isDna and Color3.fromRGB(150, 210, 255) or Color3.fromRGB(50, 255, 50)

	if pos and pos ~= Vector3.zero then
		-- สร้าง BillboardGui ลอยขึ้นจากตำแหน่ง NPC
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 180, 0, 60)
		billboard.StudsOffsetWorldSpace = pos + Vector3.new(math.random(-2,2), math.random(2,4), math.random(-2,2))
		billboard.AlwaysOnTop = true

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.Text = text
		label.TextColor3 = color
		label.Font = Enum.Font.GothamBold
		label.TextSize = isDna and 36 or 28
		label.BackgroundTransparency = 1
		label.Rotation = math.random(-12, 12) -- หมุนเล็กน้อยเพื่อความสะใจ
		label.Parent = billboard
		
		local popStroke = Instance.new("UIStroke")
		popStroke.Color = Color3.fromRGB(0, 0, 0)
		popStroke.Thickness = 1.5
		popStroke.Parent = label
		
		billboard.Parent = pgui

		-- อนิเมชันลอยขึ้นและจางหาย
		local tweenPos = TweenService:Create(billboard, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 6, 0)})
		local tweenAlpha = TweenService:Create(label, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
		
		tweenPos:Play()
		tweenAlpha:Play()
		tweenPos.Completed:Connect(function() billboard:Destroy() end)
	else
		-- ถ้าไม่มี pos ให้เด้งกลางจอ (เช่น โบนัสใหญ่)
		local screenPopup = Instance.new("TextLabel")
		screenPopup.Size = UDim2.new(0, 400, 0, 100)
		screenPopup.AnchorPoint = Vector2.new(0.5, 0.5)
		screenPopup.Position = UDim2.new(0.5, 0, 0.4, 0)
		screenPopup.Text = text
		screenPopup.TextColor3 = color
		screenPopup.Font = Enum.Font.GothamBold
		screenPopup.TextSize = 48
		screenPopup.BackgroundTransparency = 1
		screenPopup.Parent = screenGui

		local popStroke = Instance.new("UIStroke")
		popStroke.Color = Color3.fromRGB(0, 0, 0)
		popStroke.Thickness = 2
		popStroke.Parent = screenPopup

		local tween = TweenService:Create(screenPopup, TweenInfo.new(1.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.25, 0), TextTransparency = 1, TextSize = 64})
		tween:Play()
		tween.Completed:Connect(function() screenPopup:Destroy() end)
	end
end

return MainHUD
