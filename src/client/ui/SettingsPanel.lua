-- V-Breaker | SettingsPanel (Client UI Module)
-- StarterPlayer/StarterPlayerScripts/Client/ui/SettingsPanel.lua
-- ระบบตั้งค่าพื้นฐาน (เสียงเอฟเฟกต์, กราฟิก/พาร์ทิเคิล, หน้าจอสั่น, ตัวเลขคะแนนลอย)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SettingsPanel = {}
local player = Players.LocalPlayer

local screenGui
local settingsWindow
local toggleBtn
local settingToggles = {} -- [settingName] = TextButton

-- 1. ค่าเริ่มต้นของ Settings
SettingsPanel.Settings = {
	SFX = true,
	Particles = true,
	ScreenShake = true,
	Popups = true
}

-- โหลดข้อมูลเบื้องต้นหรือใช้ค่า Default
function SettingsPanel.GetSetting(name)
	if SettingsPanel.Settings[name] == nil then
		return true
	end
	return SettingsPanel.Settings[name]
end

function SettingsPanel.Init()
	print("[SettingsPanel] ⚙️ เริ่มต้นสร้างระบบ Settings Panel...")

	local playerGui = player:WaitForChild("PlayerGui")
	
	local oldGui = playerGui:FindFirstChild("VBreaker_Settings")
	if oldGui then oldGui:Destroy() end

	-- 1. สร้าง ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VBreaker_Settings"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- 2. ปุ่มเปิด Settings (⚙️ Gear Button - ข้างปุ่ม Prestige)
	toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "OpenSettingsBtn"
	toggleBtn.Size = UDim2.new(0, 50, 0, 40)
	toggleBtn.AnchorPoint = Vector2.new(1, 1)
	toggleBtn.Position = UDim2.new(1, -150, 1, -40) -- วางข้างซ้ายของปุ่ม Prestige (ระยะห่างพอดี)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.Text = "⚙️"
	toggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 20
	toggleBtn.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = toggleBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(150, 150, 150)
	btnStroke.Thickness = 2
	btnStroke.Parent = toggleBtn

	-- 3. หน้าต่างตั้งค่าหลัก (Settings Window - Center)
	settingsWindow = Instance.new("Frame")
	settingsWindow.Name = "SettingsWindow"
	settingsWindow.Size = UDim2.new(0, 380, 0, 320)
	settingsWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	settingsWindow.BackgroundTransparency = 0.15
	settingsWindow.Visible = false
	settingsWindow.Parent = screenGui

	local windowCorner = Instance.new("UICorner")
	windowCorner.CornerRadius = UDim.new(0, 16)
	windowCorner.Parent = settingsWindow

	local windowStroke = Instance.new("UIStroke")
	windowStroke.Color = Color3.fromRGB(150, 150, 150)
	windowStroke.Thickness = 2.5
	windowStroke.Parent = settingsWindow

	-- เงาสะท้อนเรืองแสงสีเทา/ขาวพรีเมียม (Premium Metallic Glow)
	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(200, 200, 220)
	glowStroke.Thickness = 6
	glowStroke.Transparency = 0.85
	glowStroke.Parent = settingsWindow

	local windowScale = Instance.new("UIScale")
	windowScale.Name = "WindowScale"
	windowScale.Scale = 0.5
	windowScale.Parent = settingsWindow

	-- 4. หัวข้อหลัก (Title)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 40)
	titleLabel.Position = UDim2.new(0, 20, 0, 15)
	titleLabel.Text = "⚙️ SYSTEM SETTINGS"
	titleLabel.TextColor3 = Color3.fromRGB(220, 220, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = settingsWindow

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = titleLabel

	-- ปุ่มปิด (Close Button)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -15, 0, 15)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.Parent = settingsWindow

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(0, 0, 0)
	closeStroke.Thickness = 1.5
	closeStroke.Parent = closeBtn

	-- 5. รายการตั้งค่า (Settings List Container)
	local settingsList = Instance.new("Frame")
	settingsList.Name = "SettingsList"
	settingsList.Size = UDim2.new(1, -40, 1, -80)
	settingsList.Position = UDim2.new(0, 20, 0, 65)
	settingsList.BackgroundTransparency = 1
	settingsList.Parent = settingsWindow

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 12)
	listLayout.Parent = settingsList

	local settingsConfig = {
		{ Key = "SFX", Name = "เสียงเอฟเฟกต์ (SFX Sounds)", Icon = "🔊" },
		{ Key = "Particles", Name = "พาร์ทิเคิลสปอร์ (Particles)", Icon = "✨" },
		{ Key = "ScreenShake", Name = "หน้าจอสั่น (Screen Shake)", Icon = "📳" },
		{ Key = "Popups", Name = "ตัวเลขคะแนนลอย (Damage Popups)", Icon = "💬" },
	}

	for i, config in ipairs(settingsConfig) do
		local row = Instance.new("Frame")
		row.Name = config.Key .. "Row"
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		row.BackgroundTransparency = 0.4
		row.LayoutOrder = i
		row.Parent = settingsList

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Color = Color3.fromRGB(50, 50, 60)
		rowStroke.Thickness = 1
		rowStroke.Parent = row

		-- ป้ายชื่อตัวเลือกตั้งค่า
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -110, 1, 0)
		label.Position = UDim2.new(0, 12, 0, 0)
		label.Text = config.Icon .. "  " .. config.Name
		label.TextColor3 = Color3.fromRGB(230, 230, 230)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 14
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.BackgroundTransparency = 1
		label.Parent = row

		local labelStroke = Instance.new("UIStroke")
		labelStroke.Color = Color3.fromRGB(0, 0, 0)
		labelStroke.Thickness = 1
		labelStroke.Parent = label

		-- ปุ่มเปิด/ปิด (Toggle Button)
		local toggle = Instance.new("TextButton")
		toggle.Name = "ToggleBtn"
		toggle.Size = UDim2.new(0, 80, 0, 28)
		toggle.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Position = UDim2.new(1, -10, 0.5, 0)
		toggle.Font = Enum.Font.GothamBold
		toggle.TextSize = 12
		toggle.Parent = row

		local toggleCorner = Instance.new("UICorner")
		toggleCorner.CornerRadius = UDim.new(0, 6)
		toggleCorner.Parent = toggle

		local toggleStroke = Instance.new("UIStroke")
		toggleStroke.Color = Color3.fromRGB(0, 0, 0)
		toggleStroke.Thickness = 1
		toggleStroke.Parent = toggle

		-- ตั้งค่าเหตุการณ์ปุ่มและสถานะเริ่มต้น
		settingToggles[config.Key] = toggle
		SettingsPanel.UpdateToggleUI(config.Key)

		toggle.MouseButton1Click:Connect(function()
			SettingsPanel.Toggle(config.Key)
		end)
	end

	-- 6. เชื่อมต่อปุ่มเปิด/ปิดหน้าต่าง
	toggleBtn.MouseButton1Click:Connect(function()
		SettingsPanel.ToggleWindow()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		SettingsPanel.ToggleWindow(false)
	end)

	-- Hover Animation สำหรับปุ่มตั้งค่าและปุ่มปิด
	local function addHoverAnimation(btn, hoverStrokeColor)
		local origColor = btn.BackgroundColor3
		local stroke = btn:FindFirstChildOfClass("UIStroke")
		local origStrokeColor = stroke and stroke.Color or Color3.fromRGB(0,0,0)

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = origColor:Lerp(Color3.new(1,1,1), 0.15)}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), {Color = hoverStrokeColor}):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = origColor}):Play()
			if stroke then
				TweenService:Create(stroke, TweenInfo.new(0.15), {Color = origStrokeColor}):Play()
			end
		end)
	end

	addHoverAnimation(toggleBtn, Color3.fromRGB(255, 255, 255))
	addHoverAnimation(closeBtn, Color3.fromRGB(255, 100, 100))
end

function SettingsPanel.ToggleWindow(forceState)
	local targetVisible = forceState ~= nil and forceState or not settingsWindow.Visible
	local windowScale = settingsWindow:FindFirstChild("WindowScale")
	if not windowScale then return end

	-- เล่นเสียงคลิกเมื่อเปิด/ปิด
	SettingsPanel.PlayClickSound()

	if targetVisible then
		windowScale.Scale = 0.5
		settingsWindow.Visible = true
		TweenService:Create(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	else
		local tween = TweenService:Create(windowScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.5})
		tween:Play()
		tween.Completed:Connect(function() settingsWindow.Visible = false end)
	end
end

function SettingsPanel.Toggle(key)
	SettingsPanel.Settings[key] = not SettingsPanel.Settings[key]
	SettingsPanel.UpdateToggleUI(key)
	SettingsPanel.PlayClickSound()

	-- ตรวจจับกรณีปิด/เปิดสปอร์หมอกเพื่อให้มีผลทันทีกับสปอร์รอบตัวผู้เล่น
	if key == "Particles" then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				local pe = root:FindFirstChild("AmbientToxicSpores")
				if pe then
					pe.Enabled = SettingsPanel.Settings[key]
				end
			end
		end
	end
end

function SettingsPanel.UpdateToggleUI(key)
	local toggle = settingToggles[key]
	if not toggle then return end

	local isEnabled = SettingsPanel.Settings[key]
	
	-- อัปเดตสีและข้อความ
	if isEnabled then
		toggle.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
		toggle.Text = "ON"
		toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	else
		toggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		toggle.Text = "OFF"
		toggle.TextColor3 = Color3.fromRGB(180, 180, 180)
	end

	-- อนิเมชันตัวอักษรเด้งเบาๆ ตอนกดสวิตช์
	local tween = TweenService:Create(toggle, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {TextSize = 15})
	tween:Play()
end

function SettingsPanel.PlayClickSound()
	if not SettingsPanel.Settings.SFX then return end
	
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://131237241" -- เสียงป๊อปคลิกสวิงเบาๆ
	sound.Volume = 0.4
	sound.PlayOnRemove = true
	sound.Parent = player.Character or workspace
	sound:Destroy()
end

return SettingsPanel
