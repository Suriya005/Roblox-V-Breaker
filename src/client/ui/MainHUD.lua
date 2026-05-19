-- V-Breaker | MainHUD (Client UI Module)
-- StarterPlayer/StarterPlayerScripts/Client/ui/MainHUD.lua
-- ระบบหน้าต่าง UI หลัก (Bio/DNA Points, Progress Bar, Pop-ups, Notifications)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local SettingsPanel = require(script.Parent:WaitForChild("SettingsPanel"))

local MainHUD = {}
MainHUD.ActiveComboLabel = nil

local player = Players.LocalPlayer

local screenGui
local bioLabel
local dnaLabel
local progressBar
local progressText
local tipLabel
local threatLabel
local vaccineBar
local vaccineText
local bossPanel
local bossNameLabel
local bossHealthBar
local bossHealthText

local prestigeBtn
local prestigePanel
local curPrestigeLabel
local curMultLabel
local nextMultLabel
local reqDnaLabel
local tokensLabel

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

	-- 8. แผงควบคุม AI รัฐบาล (Government Threat & Vaccine Panel - Top Left)
	local govPanel = Instance.new("Frame")
	govPanel.Name = "GovPanel"
	govPanel.Size = UDim2.new(0, 280, 0, 85)
	govPanel.Position = UDim2.new(0, 20, 0, 20)
	govPanel.BackgroundColor3 = Color3.fromRGB(25, 15, 15)
	govPanel.BackgroundTransparency = 0.25
	govPanel.Parent = screenGui

	local govCorner = Instance.new("UICorner")
	govCorner.CornerRadius = UDim.new(0, 12)
	govCorner.Parent = govPanel

	local govStroke = Instance.new("UIStroke")
	govStroke.Color = Color3.fromRGB(255, 100, 100)
	govStroke.Thickness = 2
	govStroke.Transparency = 0.2
	govStroke.Parent = govPanel

	threatLabel = Instance.new("TextLabel")
	threatLabel.Name = "ThreatLabel"
	threatLabel.Size = UDim2.new(1, -20, 0, 30)
	threatLabel.Position = UDim2.new(0, 10, 0, 10)
	threatLabel.Text = "🚨 Threat Level: DEFCON 5 (Normal)"
	threatLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	threatLabel.Font = Enum.Font.GothamBold
	threatLabel.TextSize = 14
	threatLabel.TextXAlignment = Enum.TextXAlignment.Left
	threatLabel.BackgroundTransparency = 1
	threatLabel.Parent = govPanel

	local threatStroke = Instance.new("UIStroke")
	threatStroke.Color = Color3.fromRGB(0, 0, 0)
	threatStroke.Thickness = 1.2
	threatStroke.Parent = threatLabel

	local vacBg = Instance.new("Frame")
	vacBg.Size = UDim2.new(1, -20, 0, 20)
	vacBg.Position = UDim2.new(0, 10, 0, 48)
	vacBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	vacBg.Parent = govPanel

	local vacCorner = Instance.new("UICorner")
	vacCorner.CornerRadius = UDim.new(0, 8)
	vacCorner.Parent = vacBg

	local vacStroke = Instance.new("UIStroke")
	vacStroke.Color = Color3.fromRGB(150, 50, 50)
	vacStroke.Thickness = 1
	vacStroke.Parent = vacBg

	vaccineBar = Instance.new("Frame")
	vaccineBar.Size = UDim2.new(0, 0, 1, 0)
	vaccineBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	vaccineBar.Parent = vacBg

	local vBarCorner = Instance.new("UICorner")
	vBarCorner.CornerRadius = UDim.new(0, 8)
	vBarCorner.Parent = vaccineBar

	vaccineText = Instance.new("TextLabel")
	vaccineText.Size = UDim2.new(1, 0, 1, 0)
	vaccineText.Text = "🧪 Vaccine Research: 0%"
	vaccineText.TextColor3 = Color3.fromRGB(255, 255, 255)
	vaccineText.Font = Enum.Font.GothamBold
	vaccineText.TextSize = 12
	vaccineText.BackgroundTransparency = 1
	vaccineText.Parent = vacBg

	local vTextStroke = Instance.new("UIStroke")
	vTextStroke.Color = Color3.fromRGB(0, 0, 0)
	vTextStroke.Thickness = 1
	vTextStroke.Parent = vaccineText

	-- 9. แผงหลอดเลือดบอสประจำโซน (Boss Health Panel - Top Center)
	bossPanel = Instance.new("Frame")
	bossPanel.Name = "BossPanel"
	bossPanel.Size = UDim2.new(0, 360, 0, 75)
	bossPanel.AnchorPoint = Vector2.new(0.5, 0)
	bossPanel.Position = UDim2.new(0.5, 0, 0, 70)
	bossPanel.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
	bossPanel.BackgroundTransparency = 0.2
	bossPanel.Visible = false -- ซ่อนไว้จนกว่าบอสจะเกิด
	bossPanel.Parent = screenGui

	local bossCorner = Instance.new("UICorner")
	bossCorner.CornerRadius = UDim.new(0, 12)
	bossCorner.Parent = bossPanel

	local bossStroke = Instance.new("UIStroke")
	bossStroke.Color = Color3.fromRGB(255, 215, 0) -- Gold Border
	bossStroke.Thickness = 2.5
	bossStroke.Transparency = 0.1
	bossStroke.Parent = bossPanel

	bossNameLabel = Instance.new("TextLabel")
	bossNameLabel.Name = "BossNameLabel"
	bossNameLabel.Size = UDim2.new(1, 0, 0, 30)
	bossNameLabel.Position = UDim2.new(0, 0, 0, 5)
	bossNameLabel.Text = "👑 BOSS: THUNDERCLAP"
	bossNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	bossNameLabel.Font = Enum.Font.GothamBold
	bossNameLabel.TextSize = 18
	bossNameLabel.BackgroundTransparency = 1
	bossNameLabel.Parent = bossPanel

	local bNameStroke = Instance.new("UIStroke")
	bNameStroke.Color = Color3.fromRGB(0, 0, 0)
	bNameStroke.Thickness = 1.2
	bNameStroke.Parent = bossNameLabel

	local bHpBg = Instance.new("Frame")
	bHpBg.Size = UDim2.new(1, -30, 0, 22)
	bHpBg.Position = UDim2.new(0, 15, 0, 40)
	bHpBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
	bHpBg.Parent = bossPanel

	local bHpBgCorner = Instance.new("UICorner")
	bHpBgCorner.CornerRadius = UDim.new(0, 8)
	bHpBgCorner.Parent = bHpBg

	local bHpStroke = Instance.new("UIStroke")
	bHpStroke.Color = Color3.fromRGB(150, 50, 50)
	bHpStroke.Thickness = 1.5
	bHpStroke.Parent = bHpBg

	bossHealthBar = Instance.new("Frame")
	bossHealthBar.Size = UDim2.new(1, 0, 1, 0)
	bossHealthBar.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	bossHealthBar.Parent = bHpBg

	local bBarCorner = Instance.new("UICorner")
	bBarCorner.CornerRadius = UDim.new(0, 8)
	bBarCorner.Parent = bossHealthBar

	bossHealthText = Instance.new("TextLabel")
	bossHealthText.Size = UDim2.new(1, 0, 1, 0)
	bossHealthText.Text = "1000 / 1000"
	bossHealthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	bossHealthText.Font = Enum.Font.GothamBold
	bossHealthText.TextSize = 14
	bossHealthText.BackgroundTransparency = 1
	bossHealthText.Parent = bHpBg

	local bTextStroke = Instance.new("UIStroke")
	bTextStroke.Color = Color3.fromRGB(0, 0, 0)
	bTextStroke.Thickness = 1.2
	bTextStroke.Parent = bossHealthText

	-- 10. ปุ่มและแผงควบคุมจุติ (Prestige Button & Panel)
	prestigeBtn = Instance.new("TextButton")
	prestigeBtn.Name = "PrestigeBtn"
	prestigeBtn.Size = UDim2.new(0, 120, 0, 40)
	prestigeBtn.AnchorPoint = Vector2.new(1, 1)
	prestigeBtn.Position = UDim2.new(1, -20, 1, -40)
	prestigeBtn.Text = "🔮 PRESTIGE"
	prestigeBtn.TextColor3 = Color3.fromRGB(255, 150, 255)
	prestigeBtn.Font = Enum.Font.GothamBold
	prestigeBtn.TextSize = 16
	prestigeBtn.BackgroundColor3 = Color3.fromRGB(30, 15, 30)
	prestigeBtn.BackgroundTransparency = 0.2
	prestigeBtn.Parent = screenGui

	local pBtnCorner = Instance.new("UICorner")
	pBtnCorner.CornerRadius = UDim.new(0, 8)
	pBtnCorner.Parent = prestigeBtn

	local pBtnStroke = Instance.new("UIStroke")
	pBtnStroke.Color = Color3.fromRGB(200, 100, 200)
	pBtnStroke.Thickness = 2
	pBtnStroke.Parent = prestigeBtn

	prestigePanel = Instance.new("Frame")
	prestigePanel.Name = "PrestigePanel"
	prestigePanel.Size = UDim2.new(0, 400, 0, 320)
	prestigePanel.AnchorPoint = Vector2.new(0.5, 0.5)
	prestigePanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	prestigePanel.BackgroundColor3 = Color3.fromRGB(25, 10, 25)
	prestigePanel.BackgroundTransparency = 0.15
	prestigePanel.Visible = false
	prestigePanel.Parent = screenGui

	local pPanelCorner = Instance.new("UICorner")
	pPanelCorner.CornerRadius = UDim.new(0, 16)
	pPanelCorner.Parent = prestigePanel

	local pPanelStroke = Instance.new("UIStroke")
	pPanelStroke.Color = Color3.fromRGB(255, 100, 255)
	pPanelStroke.Thickness = 3
	pPanelStroke.Parent = prestigePanel

	local pTitle = Instance.new("TextLabel")
	pTitle.Size = UDim2.new(1, 0, 0, 40)
	pTitle.Position = UDim2.new(0, 0, 0, 10)
	pTitle.Text = "🔮 PRESTIGE ASCENSION"
	pTitle.TextColor3 = Color3.fromRGB(255, 150, 255)
	pTitle.Font = Enum.Font.GothamBold
	pTitle.TextSize = 24
	pTitle.BackgroundTransparency = 1
	pTitle.Parent = prestigePanel

	curPrestigeLabel = Instance.new("TextLabel")
	curPrestigeLabel.Size = UDim2.new(1, -40, 0, 30)
	curPrestigeLabel.Position = UDim2.new(0, 20, 0, 60)
	curPrestigeLabel.Text = "Current Prestige: Level 0"
	curPrestigeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	curPrestigeLabel.Font = Enum.Font.GothamBold
	curPrestigeLabel.TextSize = 18
	curPrestigeLabel.BackgroundTransparency = 1
	curPrestigeLabel.Parent = prestigePanel

	curMultLabel = Instance.new("TextLabel")
	curMultLabel.Size = UDim2.new(1, -40, 0, 30)
	curMultLabel.Position = UDim2.new(0, 20, 0, 100)
	curMultLabel.Text = "Current Multiplier: 1.0x"
	curMultLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	curMultLabel.Font = Enum.Font.GothamBold
	curMultLabel.TextSize = 18
	curMultLabel.BackgroundTransparency = 1
	curMultLabel.Parent = prestigePanel

	nextMultLabel = Instance.new("TextLabel")
	nextMultLabel.Size = UDim2.new(1, -40, 0, 30)
	nextMultLabel.Position = UDim2.new(0, 20, 0, 140)
	nextMultLabel.Text = "Next Multiplier: 1.5x (+0.5x)"
	nextMultLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	nextMultLabel.Font = Enum.Font.GothamBold
	nextMultLabel.TextSize = 18
	nextMultLabel.BackgroundTransparency = 1
	nextMultLabel.Parent = prestigePanel

	reqDnaLabel = Instance.new("TextLabel")
	reqDnaLabel.Size = UDim2.new(1, -40, 0, 30)
	reqDnaLabel.Position = UDim2.new(0, 20, 0, 180)
	reqDnaLabel.Text = "Requirement: 5000 DNA Points"
	reqDnaLabel.TextColor3 = Color3.fromRGB(150, 210, 255)
	reqDnaLabel.Font = Enum.Font.GothamBold
	reqDnaLabel.TextSize = 18
	reqDnaLabel.BackgroundTransparency = 1
	reqDnaLabel.Parent = prestigePanel

	tokensLabel = Instance.new("TextLabel")
	tokensLabel.Size = UDim2.new(1, -40, 0, 30)
	tokensLabel.Position = UDim2.new(0, 20, 0, 220)
	tokensLabel.Text = "Reward: +1 Plague Token (Total: 0)"
	tokensLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	tokensLabel.Font = Enum.Font.GothamBold
	tokensLabel.TextSize = 18
	tokensLabel.BackgroundTransparency = 1
	tokensLabel.Parent = prestigePanel

	local confirmBtn = Instance.new("TextButton")
	confirmBtn.Size = UDim2.new(0, 180, 0, 45)
	confirmBtn.Position = UDim2.new(0.5, -90, 1, -55)
	confirmBtn.Text = "ASCEND (PRESTIGE)"
	confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	confirmBtn.Font = Enum.Font.GothamBold
	confirmBtn.TextSize = 16
	confirmBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 150)
	confirmBtn.Parent = prestigePanel

	local cBtnCorner = Instance.new("UICorner")
	cBtnCorner.CornerRadius = UDim.new(0, 8)
	cBtnCorner.Parent = confirmBtn

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -40, 0, 10)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	closeBtn.Parent = prestigePanel

	local clBtnCorner = Instance.new("UICorner")
	clBtnCorner.CornerRadius = UDim.new(0, 8)
	clBtnCorner.Parent = closeBtn

	-- Event Listeners
	prestigeBtn.MouseButton1Click:Connect(function()
		prestigePanel.Visible = not prestigePanel.Visible
	end)

	closeBtn.MouseButton1Click:Connect(function()
		prestigePanel.Visible = false
	end)

	confirmBtn.MouseButton1Click:Connect(function()
		RemoteManager.FireServer(Constants.REMOTES.REQUEST_PRESTIGE)
		prestigePanel.Visible = false
	end)

	-- Ambient Color Cycling on MainPanel UIStroke
	task.spawn(function()
		local hue = 0
		RunService.RenderStepped:Connect(function(dt)
			if not uiStroke or not mainPanel then return end
			hue = (hue + dt * 0.1) % 1
			local color = Color3.fromHSV(hue, 0.85, 1)
			uiStroke.Color = color
			if glowStroke then glowStroke.Color = color end
		end)
	end)

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

MainHUD.HasPunched = false

function MainHUD.HideTip()
	if not tipLabel then return end
	MainHUD.HasPunched = true
	local tween = TweenService:Create(tipLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1, BackgroundTransparency = 1})
	tween:Play()
	local border = tipLabel:FindFirstChild("BorderStroke")
	if border then TweenService:Create(border, TweenInfo.new(0.5), {Transparency = 1}):Play() end
	local textStroke = tipLabel:FindFirstChild("TextStroke")
	if textStroke then TweenService:Create(textStroke, TweenInfo.new(0.5), {Transparency = 1}):Play() end
end

function MainHUD.ShowNotification(message: string, notifType: string)
	if not tipLabel then return end
	
	-- ปรากฏตัวหนังสือขึ้นมาใหม่เผื่อโดนซ่อนไปแล้ว
	tipLabel.TextTransparency = 0
	tipLabel.BackgroundTransparency = 0.5
	local border = tipLabel:FindFirstChild("BorderStroke")
	if border then border.Transparency = 0 end
	local textStroke = tipLabel:FindFirstChild("TextStroke")
	if textStroke then textStroke.Transparency = 0 end

	tipLabel.Text = message
	
	local isWarning = notifType == "Warning"
	tipLabel.TextColor3 = isWarning and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	
	if border then
		border.Color = isWarning and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
	end

	-- เขย่าป้ายเตือนเบาๆ
	local startPos = tipLabel.Position
	local shakeTween = TweenService:Create(tipLabel, TweenInfo.new(0.05, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 3, true), {Position = startPos + UDim2.new(0, math.random(-10,10), 0, 0)})
	shakeTween:Play()

	task.wait(2.5)
	
	if MainHUD.HasPunched then
		MainHUD.HideTip()
	else
		tipLabel.Text = "🎯 คลิกซ้ายที่เป้าหมายเพื่อปล่อยไวรัสระบาด!"
		tipLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		if border then border.Color = Color3.fromRGB(255, 255, 100) end
	end
end

function MainHUD.ShowPopup(text: string, pos: Vector3, popupType: string)
	local pgui = player:FindFirstChild("PlayerGui")
	if not pgui or not screenGui then return end

	local isDna = popupType == "DNA"
	local isDamage = popupType == "Damage"

	-- Redirect numeric DNA notifications (+X DNA) to active combo text instead of standalone screen popups
	if isDna and MainHUD.ActiveComboLabel and MainHUD.ActiveComboLabel.Parent then
		local dnaAmount = tonumber(string.match(text, "%+(%d+)"))
		if dnaAmount then
			local label = MainHUD.ActiveComboLabel
			local dnaSubLabel = label:FindFirstChild("DnaSubLabel")
			if not dnaSubLabel then
				dnaSubLabel = Instance.new("TextLabel")
				dnaSubLabel.Name = "DnaSubLabel"
				dnaSubLabel.Size = UDim2.new(1, 0, 0, 30)
				dnaSubLabel.Position = UDim2.new(0, 5, 1, 0) -- วางด้านล่าง Combo พอดี
				dnaSubLabel.TextColor3 = Color3.fromRGB(150, 210, 255) -- สีฟ้าอ่อนของ DNA
				dnaSubLabel.Font = Enum.Font.GothamBold
				dnaSubLabel.TextSize = 22
				dnaSubLabel.TextXAlignment = Enum.TextXAlignment.Left
				dnaSubLabel.BackgroundTransparency = 1
				dnaSubLabel.Parent = label

				local subStroke = Instance.new("UIStroke")
				subStroke.Color = Color3.fromRGB(0, 0, 0)
				subStroke.Thickness = 2
				subStroke.Parent = dnaSubLabel
			end
			
			dnaSubLabel.Text = "🧬 +" .. dnaAmount .. " DNA"
			
			-- Juice animation: pulse scale/size slightly
			local tween = TweenService:Create(dnaSubLabel, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 28})
			tween:Play()
			
			return -- Skip standalone popup
		end
	end

	local color = isDna and Color3.fromRGB(150, 210, 255) or (isDamage and Color3.fromRGB(255, 100, 50) or Color3.fromRGB(50, 255, 50))

	if pos and pos ~= Vector3.zero then
		if not SettingsPanel.GetSetting("Popups") then return end
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
		label.TextSize = isDna and 36 or (isDamage and 24 or 28)
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

function MainHUD.UpdateThreatLevel(level: number, name: string, color: Color3)
	if not threatLabel then return end
	threatLabel.Text = "🚨 Threat Level: " .. name
	threatLabel.TextColor3 = color

	local tween = TweenService:Create(threatLabel, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, true), {TextSize = 16})
	tween:Play()
end

function MainHUD.UpdateVaccineProgress(progress: number)
	if not vaccineBar or not vaccineText then return end
	vaccineText.Text = string.format("🧪 Vaccine Research: %d%%", math.floor(progress))
	
	local targetScale = progress / 100
	local tween = TweenService:Create(vaccineBar, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Size = UDim2.new(targetScale, 0, 1, 0)})
	tween:Play()
end

function MainHUD.ShowBossBar(name: string, curHp: number, maxHp: number, color: Color3)
	if not bossPanel then return end
	bossPanel.Visible = true
	bossNameLabel.Text = "👑 BOSS: " .. string.upper(name)
	bossNameLabel.TextColor3 = color
	bossHealthText.Text = curHp .. " / " .. maxHp
	bossHealthBar.Size = UDim2.new(curHp / maxHp, 0, 1, 0)
	bossHealthBar.BackgroundColor3 = color

	local tween = TweenService:Create(bossPanel, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 70)})
	tween:Play()
end

function MainHUD.UpdateBossHealth(curHp: number, maxHp: number)
	if not bossPanel or not bossPanel.Visible then return end
	bossHealthText.Text = curHp .. " / " .. maxHp

	local targetScale = math.clamp(curHp / maxHp, 0, 1)
	local tween = TweenService:Create(bossHealthBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(targetScale, 0, 1, 0)})
	tween:Play()
end

function MainHUD.HideBossBar(name: string)
	if not bossPanel then return end
	bossPanel.Visible = false
	MainHUD.ShowPopup("👑 BOSS DEFEATED: " .. string.upper(name) .. "!", nil, "DNA")
end

function MainHUD.HideBossBarSilent()
	if not bossPanel then return end
	bossPanel.Visible = false
end

function MainHUD.UpdatePrestige(level: number, multiplier: number, tokens: number)
	if not curPrestigeLabel then return end
	curPrestigeLabel.Text = "Current Prestige: Level " .. level
	curMultLabel.Text = string.format("Current Multiplier: %.1fx", multiplier)
	nextMultLabel.Text = string.format("Next Multiplier: %.1fx (+%.1fx)", multiplier + Constants.PRESTIGE.BASE_MULTIPLIER_ADD, Constants.PRESTIGE.BASE_MULTIPLIER_ADD)
	tokensLabel.Text = "Reward: +1 Plague Token (Total: " .. tokens .. ")"
	reqDnaLabel.Text = "Requirement: " .. Constants.PRESTIGE.REQ_DNA .. " DNA Points"

	-- แสดงบนปุ่มด้วย
	if prestigeBtn then
		prestigeBtn.Text = "🔮 PRESTIGE " .. level
	end
end

function MainHUD.ShowCombo(comboCount: number)
	if not screenGui then return end

	local comboColor = Color3.fromRGB(255, 255, 0)
	if comboCount >= 50 then comboColor = Color3.fromRGB(180, 50, 255)
	elseif comboCount >= 25 then comboColor = Color3.fromRGB(255, 50, 50)
	elseif comboCount >= 10 then comboColor = Color3.fromRGB(255, 150, 50)
	end

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 60)
	label.AnchorPoint = Vector2.new(0, 1) -- มุมซ้ายล่าง
	label.Position = UDim2.new(0, 40 + math.random(-10, 10), 1, -160 + math.random(-10, 10))
	label.Text = "🔥 COMBO x" .. comboCount .. "!!!"
	label.TextColor3 = comboColor
	label.Font = Enum.Font.GothamBold
	label.TextSize = 80 -- เริ่มต้นเล็กลงจากเดิม (จาก 140 เป็น 80)
	label.Rotation = math.random(-10, 0) -- เอียงซ้ายนิดๆ
	label.TextXAlignment = Enum.TextXAlignment.Left -- ชิดข้อความไปทางซ้าย
	label.BackgroundTransparency = 1
	label.Parent = screenGui

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 3
	stroke.Parent = label

	-- บันทึก Reference ล่าสุดของป้าย Combo
	MainHUD.ActiveComboLabel = label

	-- อนิเมชันกระแทกหน้าจอ (เล็กลงไปที่ 48)
	local tween = TweenService:Create(label, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {TextSize = 48})
	tween:Play()

	task.delay(1.2, function()
		if label.Parent then
			local fade = TweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
			fade:Play()

			local subLabel = label:FindFirstChild("DnaSubLabel")
			if subLabel then
				local fadeSub = TweenService:Create(subLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1, TextStrokeTransparency = 1})
				fadeSub:Play()
			end

			fade.Completed:Connect(function()
				if MainHUD.ActiveComboLabel == label then
					MainHUD.ActiveComboLabel = nil
				end
				label:Destroy()
			end)
		else
			if MainHUD.ActiveComboLabel == label then
				MainHUD.ActiveComboLabel = nil
			end
			label:Destroy()
		end
	end)
end

function MainHUD.PlayIntroAnimation()
	local pgui = player:WaitForChild("PlayerGui")
	local introGui = Instance.new("ScreenGui")
	introGui.Name = "VBreaker_IntroAnimation"
	introGui.DisplayOrder = 999 -- อยู่บนสุด
	introGui.Parent = pgui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.fromRGB(5, 5, 10)
	bg.Parent = introGui

	local tube = Instance.new("TextLabel")
	tube.Size = UDim2.new(0, 300, 0, 300)
	tube.AnchorPoint = Vector2.new(0.5, 0.5)
	tube.Position = UDim2.new(0.5, 0, 0.5, -40)
	tube.Text = "🧪"
	tube.TextSize = 180
	tube.BackgroundTransparency = 1
	tube.Parent = bg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 60)
	label.Position = UDim2.new(0, 0, 0.5, 120)
	label.Text = "PREPARING VIRAL STRAIN..."
	label.TextColor3 = Color3.fromRGB(50, 255, 50)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 32
	label.BackgroundTransparency = 1
	label.Parent = bg

	-- 1. เขย่าหลอดทดลอง
	task.spawn(function()
		local startPos = tube.Position
		for i = 1, 15 do
			if not tube then return end
			tube.Position = startPos + UDim2.new(0, math.random(-15,15), 0, math.random(-15,15))
			task.wait(0.08)
		end
		if not tube then return end
		tube.Position = startPos

		-- 2. หลอดทดลองระเบิด (Explode)
		tube.Text = "💥"
		tube.TextSize = 250
		label.Text = "💥 VIRAL STRAIN RELEASED!!!"
		label.TextColor3 = Color3.fromRGB(255, 50, 50)

		-- Screen Shake
		local cam = workspace.CurrentCamera
		if cam and SettingsPanel.GetSetting("ScreenShake") then
			local origCFrame = cam.CFrame
			for i = 1, 10 do
				cam.CFrame = origCFrame * CFrame.new(math.random(-2,2), math.random(-2,2), 0)
				task.wait(0.05)
			end
			cam.CFrame = origCFrame
		end

		task.wait(0.5)

		-- 3. Character Slam-in (Camera Zoom-in จากมุมสูง)
		if player.Character and player.Character:FindFirstChild("Head") and cam then
			cam.CameraType = Enum.CameraType.Scriptable
			local headPos = player.Character.Head.Position
			cam.CFrame = CFrame.new(headPos + Vector3.new(0, 80, 40), headPos)

			local tween = TweenService:Create(cam, TweenInfo.new(1.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {CFrame = CFrame.new(headPos + Vector3.new(0, 10, 15), headPos)})
			tween:Play()
			tween.Completed:Connect(function()
				cam.CameraType = Enum.CameraType.Custom
			end)
		end

		-- Fade Out หน้าจอ Intro
		local fadeTween = TweenService:Create(bg, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		local fadeText1 = TweenService:Create(tube, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
		local fadeText2 = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
		fadeTween:Play() fadeText1:Play() fadeText2:Play()
		fadeTween.Completed:Connect(function() introGui:Destroy() end)
	end)
end

return MainHUD
