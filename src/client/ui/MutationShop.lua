-- V-Breaker | MutationShop (Client UI Module)
-- StarterPlayer/StarterPlayerScripts/Client/ui/MutationShop.lua
-- หน้าต่างร้านค้าอัปเกรดสายพันธุ์ไวรัส (Mutation Shop)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local MutationTree = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("MutationTree"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))

local MutationShop = {}
local player = Players.LocalPlayer

local screenGui
local shopWindow
local toggleBtn
local scrollingFrame
local currentTab = MutationTree.CATEGORIES.TRANSMISSION
local clientMutations = {} -- [mutationId] = true

local cardFrames = {} -- เก็บอ้างอิง Card เพื่อใช้อัปเดตสถานะปุ่ม

function MutationShop.Init()
	print("[MutationShop] 🎨 เริ่มต้นสร้างระบบหน้าต่าง Mutation Shop...")

	local playerGui = player:WaitForChild("PlayerGui")
	
	local oldGui = playerGui:FindFirstChild("VBreaker_MutationShop")
	if oldGui then oldGui:Destroy() end

	-- 1. สร้าง ScreenGui
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "VBreaker_MutationShop"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- 2. ปุ่มเปิดร้านค้า (Toggle Button - Right Side)
	toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "OpenShopBtn"
	toggleBtn.Size = UDim2.new(0, 160, 0, 45)
	toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
	toggleBtn.Position = UDim2.new(1, -20, 0.5, 0)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toggleBtn.BackgroundTransparency = 0.2
	toggleBtn.Text = "🧬 Mutation Shop"
	toggleBtn.TextColor3 = Color3.fromRGB(150, 210, 255)
	toggleBtn.Font = Enum.Font.GothamBold
	toggleBtn.TextSize = 16
	toggleBtn.Parent = screenGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 12)
	btnCorner.Parent = toggleBtn

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(100, 200, 255)
	btnStroke.Thickness = 2
	btnStroke.Parent = toggleBtn

	local btnTextStroke = Instance.new("UIStroke")
	btnTextStroke.Color = Color3.fromRGB(0, 0, 0)
	btnTextStroke.Thickness = 1
	btnTextStroke.Parent = toggleBtn

	-- 3. หน้าต่างร้านค้าหลัก (Shop Window - Center)
	shopWindow = Instance.new("Frame")
	shopWindow.Name = "ShopWindow"
	shopWindow.Size = UDim2.new(0, 650, 0, 450)
	shopWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	shopWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
	shopWindow.BackgroundTransparency = 0.15
	shopWindow.Visible = false -- ซ่อนไว้ก่อน
	shopWindow.Parent = screenGui

	local windowCorner = Instance.new("UICorner")
	windowCorner.CornerRadius = UDim.new(0, 16)
	windowCorner.Parent = shopWindow

	local windowStroke = Instance.new("UIStroke")
	windowStroke.Color = Color3.fromRGB(100, 200, 255)
	windowStroke.Thickness = 2.5
	windowStroke.Parent = shopWindow

	local glowStroke = Instance.new("UIStroke")
	glowStroke.Color = Color3.fromRGB(100, 200, 255)
	glowStroke.Thickness = 8
	glowStroke.Transparency = 0.7
	glowStroke.Parent = shopWindow

	local windowScale = Instance.new("UIScale")
	windowScale.Name = "WindowScale"
	windowScale.Scale = 0.5
	windowScale.Parent = shopWindow

	-- 4. แถบหัวข้อ (Title Bar)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 40)
	titleLabel.Position = UDim2.new(0, 20, 0, 10)
	titleLabel.Text = "🧬 VIRAL MUTATION TREE"
	titleLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = shopWindow

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = titleLabel

	-- ปุ่มปิด (Close Button)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 40)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -15, 0, 10)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.Parent = shopWindow

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(0, 0, 0)
	closeStroke.Thickness = 1.5
	closeStroke.Parent = closeBtn

	-- 5. แถบ Tab ตัวเลือกหมวดหมู่ (Tabs Container)
	local tabsContainer = Instance.new("Frame")
	tabsContainer.Size = UDim2.new(1, -40, 0, 40)
	tabsContainer.Position = UDim2.new(0, 20, 0, 60)
	tabsContainer.BackgroundTransparency = 1
	tabsContainer.Parent = shopWindow

	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Padding = UDim.new(0, 15)
	tabLayout.Parent = tabsContainer

	local tabList = {
		{ Name = "Transmission", Label = "💨 Transmission" },
		{ Name = "Symptoms", Label = "🔥 Symptoms" },
		{ Name = "Abilities", Label = "🛡️ Abilities" },
	}

	for i, tabInfo in ipairs(tabList) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = tabInfo.Name .. "Tab"
		tabBtn.Size = UDim2.new(0, 190, 1, 0)
		tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
		tabBtn.Text = tabInfo.Label
		tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
		tabBtn.Font = Enum.Font.GothamBold
		tabBtn.TextSize = 16
		tabBtn.LayoutOrder = i
		tabBtn.Parent = tabsContainer

		local tCorner = Instance.new("UICorner")
		tCorner.CornerRadius = UDim.new(0, 8)
		tCorner.Parent = tabBtn

		local tStroke = Instance.new("UIStroke")
		tStroke.Color = Color3.fromRGB(100, 100, 120)
		tStroke.Thickness = 1.5
		tStroke.Parent = tabBtn

		local tTextStroke = Instance.new("UIStroke")
		tTextStroke.Color = Color3.fromRGB(0, 0, 0)
		tTextStroke.Thickness = 1
		tTextStroke.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			MutationShop.SwitchTab(tabInfo.Name)
		end)
	end

	-- 6. พื้นที่แสดงรายการการ์ด (ScrollingFrame)
	scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, -40, 1, -130)
	scrollingFrame.Position = UDim2.new(0, 20, 0, 110)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.Parent = shopWindow

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 295, 0, 120)
	gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
	gridLayout.SortOrder = Enum.SortOrder.Name
	gridLayout.Parent = scrollingFrame

	-- 7. เหตุการณ์ปุ่มเปิด/ปิดหน้าต่าง
	toggleBtn.MouseButton1Click:Connect(function()
		MutationShop.ToggleWindow()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		MutationShop.ToggleWindow(false)
	end)

	-- 8. เริ่มต้นสร้างการ์ดและเลือก Tab แรก
	MutationShop.BuildCards()
	MutationShop.SwitchTab(currentTab)

	print("[MutationShop] ✅ สร้างหน้าต่าง Mutation Shop สมบูรณ์!")
end

function MutationShop.ToggleWindow(forceState)
	local targetVisible = forceState ~= nil and forceState or not shopWindow.Visible
	local windowScale = shopWindow:FindFirstChild("WindowScale")
	if not windowScale then return end
	
	if targetVisible then
		windowScale.Scale = 0.5
		shopWindow.Visible = true
		TweenService:Create(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	else
		local tween = TweenService:Create(windowScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.5})
		tween:Play()
		tween.Completed:Connect(function() shopWindow.Visible = false end)
	end
end

function MutationShop.SwitchTab(tabName: string)
	currentTab = tabName

	-- อัปเดตสีปุ่ม Tab
	local tabsContainer = shopWindow:FindFirstChild("TabsContainer") or shopWindow:FindFirstChildWhichIsA("Frame")
	for _, btn in ipairs(tabsContainer:GetChildren()) do
		if btn:IsA("TextButton") then
			local isActive = btn.Name == tabName .. "Tab"
			btn.BackgroundColor3 = isActive and Color3.fromRGB(50, 50, 70) or Color3.fromRGB(30, 30, 42)
			btn.TextColor3 = isActive and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(200, 200, 200)
			btn.UIStroke.Color = isActive and Color3.fromRGB(100, 200, 255) or Color3.fromRGB(100, 100, 120)
		end
	end

	-- กรองแสดงเฉพาะการ์ดในหมวดที่เลือก
	for mutId, card in pairs(cardFrames) do
		local mutData = MutationTree.MUTATIONS[mutId]
		if mutData then
			card.Visible = mutData.Category == tabName
		end
	end
	
	MutationShop.UpdateAllCards()
end

function MutationShop.BuildCards()
	-- ลบของเก่าออกก่อน (ถ้ามี)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	table.clear(cardFrames)

	-- สร้างการ์ดสำหรับทุก Mutation
	for mutId, mutData in pairs(MutationTree.MUTATIONS) do
		local card = Instance.new("Frame")
		card.Name = mutData.Name -- ใช้ชื่อเพื่อจัดเรียง
		card.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
		card.Parent = scrollingFrame

		local cCorner = Instance.new("UICorner")
		cCorner.CornerRadius = UDim.new(0, 12)
		cCorner.Parent = card

		local cStroke = Instance.new("UIStroke")
		cStroke.Color = Color3.fromRGB(80, 80, 100)
		cStroke.Thickness = 1.5
		cStroke.Parent = card

		-- Icon
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Size = UDim2.new(0, 40, 0, 40)
		iconLabel.Position = UDim2.new(0, 10, 0, 10)
		iconLabel.Text = mutData.Icon or "🧬"
		iconLabel.TextSize = 28
		iconLabel.BackgroundTransparency = 1
		iconLabel.Parent = card

		-- Name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -65, 0, 25)
		nameLabel.Position = UDim2.new(0, 55, 0, 10)
		nameLabel.Text = mutData.Name
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.BackgroundTransparency = 1
		nameLabel.Parent = card

		local nStroke = Instance.new("UIStroke")
		nStroke.Color = Color3.fromRGB(0, 0, 0)
		nStroke.Thickness = 1
		nStroke.Parent = nameLabel

		-- Description
		local descLabel = Instance.new("TextLabel")
		descLabel.Size = UDim2.new(1, -65, 0, 35)
		descLabel.Position = UDim2.new(0, 55, 0, 35)
		descLabel.Text = mutData.Desc
		descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextSize = 12
		descLabel.TextWrapped = true
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.TextYAlignment = Enum.TextYAlignment.Top
		descLabel.BackgroundTransparency = 1
		descLabel.Parent = card

		local dStroke = Instance.new("UIStroke")
		dStroke.Color = Color3.fromRGB(0, 0, 0)
		dStroke.Thickness = 1
		dStroke.Parent = descLabel

		-- ปุ่ม Buy
		local buyBtn = Instance.new("TextButton")
		buyBtn.Name = "BuyBtn"
		buyBtn.Size = UDim2.new(1, -20, 0, 35)
		buyBtn.Position = UDim2.new(0, 10, 0, 75)
		buyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
		buyBtn.Text = "Buy : " .. mutData.Cost .. " " .. mutData.Currency
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Font = Enum.Font.GothamBold
		buyBtn.TextSize = 14
		buyBtn.Parent = card

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = buyBtn

		local bStroke = Instance.new("UIStroke")
		bStroke.Color = Color3.fromRGB(0, 0, 0)
		bStroke.Thickness = 1.5
		bStroke.Parent = buyBtn

		local bTextStroke = Instance.new("UIStroke")
		bTextStroke.Color = Color3.fromRGB(0, 0, 0)
		bTextStroke.Thickness = 1
		bTextStroke.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			-- ส่งคำสั่งซื้อไป Server
			RemoteManager.FireServer(Constants.REMOTES.BUY_MUTATION, mutId)
		end)

		cardFrames[mutId] = card
	end
end

function MutationShop.UpdateAllCards()
	for mutId, card in pairs(cardFrames) do
		local mutData = MutationTree.MUTATIONS[mutId]
		local buyBtn = card:FindFirstChild("BuyBtn")
		if not mutData or not buyBtn then continue end

		local isUnlocked = clientMutations[mutId] or false
		local reqMet = not mutData.Req or (clientMutations[mutData.Req] or false)

		if isUnlocked then
			buyBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
			buyBtn.Text = "✓ UNLOCKED"
			buyBtn.Active = false
			buyBtn.AutoButtonColor = false
		elseif not reqMet then
			local reqData = MutationTree.MUTATIONS[mutData.Req]
			local reqName = reqData and reqData.Name or mutData.Req
			buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
			buyBtn.Text = "🔒 Req: " .. reqName
			buyBtn.Active = false
			buyBtn.AutoButtonColor = false
		else
			buyBtn.BackgroundColor3 = mutData.Currency == "DNA" and Color3.fromRGB(150, 100, 255) or Color3.fromRGB(50, 150, 255)
			buyBtn.Text = "Buy : " .. mutData.Cost .. " " .. mutData.Currency
			buyBtn.Active = true
			buyBtn.AutoButtonColor = true
		end
	end
end

function MutationShop.OnSyncMutations(mutationsTable)
	clientMutations = mutationsTable or {}
	MutationShop.UpdateAllCards()
end

function MutationShop.OnMutationUnlocked(mutationId)
	clientMutations[mutationId] = true
	MutationShop.UpdateAllCards()
end

return MutationShop
