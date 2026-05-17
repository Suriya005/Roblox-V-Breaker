-- V-Breaker | BossManager (Server)
-- ServerScriptService/Server/services/BossManager.lua
-- ระบบจัดการบอสประจำโซน (Thunderclap, Inferno, Vortex, SUPREME)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))

local BossManager = {}
BossManager.ActiveBoss = nil

-- ลำดับของบอสที่จะสุ่มเกิด
local BOSS_ORDER = {
	Constants.BOSSES.THUNDERCLAP,
	Constants.BOSSES.INFERNO,
	Constants.BOSSES.VORTEX,
	Constants.BOSSES.SUPREME,
}

local currentBossIndex = 1

function BossManager.Init()
	print("[BossManager] ⚔️ เริ่มต้นระบบ Boss Manager...")

	-- เริ่มลูปเช็คและสุ่มเกิดบอสประจำโซน
	task.spawn(BossManager.StartBossLoop)

	print("[BossManager] ✅ พร้อมใช้งาน!")
end

function BossManager.StartBossLoop()
	while true do
		task.wait(30) -- เช็คทุกๆ 30 วินาที

		-- ถ้ายังไม่มีบอสในฉาก ให้ทำการสุ่มเกิดบอสตัวถัดไปตามลำดับโซน
		if not BossManager.ActiveBoss or not BossManager.ActiveBoss.Parent then
			local bossData = BOSS_ORDER[currentBossIndex]
			if bossData then
				-- ตรวจสอบว่า Zone ของบอสนั้นปลดล็อกหรือยัง
				local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
				if not PlayerService.IsZoneUnlocked(bossData.Zone) then
					-- ถ้าโซนยังไม่ปลดล็อก ให้วนกลับไปเกิดบอสตัวแรก (Thunderclap) แทน
					currentBossIndex = 1
					bossData = BOSS_ORDER[1]
				end

				-- เลือกพื้นที่เกิดตาม Zone
				local spawnAreaName = (bossData.Zone == "Forest" and "ForestZone_SpawnArea" or bossData.Zone == "City" and "CityZone_SpawnArea" or bossData.Zone == "Military" and "MilitaryBase_SpawnArea" or "VoughtHQ_SpawnArea")
				local spawnArea = workspace:FindFirstChild(spawnAreaName) or workspace:FindFirstChild("ForestZone_SpawnArea")

				if spawnArea then
					BossManager.SpawnBoss(bossData, spawnArea)
				end
			end
		end
	end
end

function BossManager.SpawnBoss(bossData: table, spawnArea: Part)
	print("[BossManager] 👑 บอสปรากฏตัว: " .. bossData.Name .. " (" .. bossData.Zone .. " Zone)")

	local model = Instance.new("Model")
	model.Name = "BOSS_" .. bossData.Name
	model:SetAttribute("Tier", 4)
	model:SetAttribute("ImmuneStrength", bossData.Immune)
	model:SetAttribute("BioPoints", bossData.BioPoints)
	model:SetAttribute("DnaPoints", bossData.DnaPoints)
	model:SetAttribute("BossType", bossData.Name)
	model:SetAttribute("IsInfected", false)
	model:SetAttribute("Health", bossData.Health)
	model:SetAttribute("MaxHealth", bossData.Health)

	CollectionService:AddTag(model, "NPC")
	CollectionService:AddTag(model, "Boss")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = bossData.Size
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Color = bossData.Color
	rootPart.Material = Enum.Material.Neon -- บอสเรืองแสงดูอลังการ
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	-- สร้าง BillboardGui อลังการสำหรับบอส
	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 250, 0, 120)
	bg.StudsOffset = Vector3.new(0, bossData.Size.Y / 2 + 4, 0)
	bg.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 55)
	label.Text = bossData.Emoji or "👑"
	label.TextSize = 50
	label.BackgroundTransparency = 1
	label.Parent = bg

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 25)
	statusLabel.Position = UDim2.new(0, 0, 0, 60)
	statusLabel.Text = "👑 " .. bossData.Name .. " | 🛡️ " .. bossData.Immune .. " | HP: " .. bossData.Health
	statusLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 16
	statusLabel.BackgroundTransparency = 1
	statusLabel.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.Parent = statusLabel

	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0, 160, 0, 16)
	healthBg.Position = UDim2.new(0.5, -80, 0, 90)
	healthBg.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
	healthBg.Parent = bg

	local hCorner1 = Instance.new("UICorner")
	hCorner1.CornerRadius = UDim.new(1, 0)
	hCorner1.Parent = healthBg

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- บอสหลอดเลือดแดงเดือด
	healthFill.Parent = healthBg

	local hCorner2 = Instance.new("UICorner")
	hCorner2.CornerRadius = UDim.new(1, 0)
	hCorner2.Parent = healthFill

	bg.Parent = rootPart

	-- ตำแหน่งเกิด
	local halfX = spawnArea.Size.X / 2
	local halfZ = spawnArea.Size.Z / 2
	local randX = spawnArea.Position.X + math.random(-halfX + 20, halfX - 20)
	local randZ = spawnArea.Position.Z + math.random(-halfZ + 20, halfZ - 20)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + bossData.Size.Y / 2

	rootPart.CFrame = CFrame.new(randX, spawnY, randZ)
	model.Parent = workspace

	BossManager.ActiveBoss = model

	-- ส่ง Event แจ้งเตือน Client ทุกคนว่าบอสเกิดแล้ว พร้อมส่ง Model ไปด้วยเพื่อเช็คระยะ
	RemoteManager.FireAllClients(Constants.REMOTES.BOSS_SPAWNED, model, bossData.Name, bossData.Health, bossData.Health, bossData.Color)

	-- เริ่ม Boss AI Loop
	task.spawn(function()
		BossManager.BossAILoop(model, bossData, spawnArea)
	end)
end

function BossManager.BossAILoop(model: Model, bossData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local statusLabel = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("StatusLabel")

	local halfX = spawnArea.Size.X / 2
	local halfZ = spawnArea.Size.Z / 2
	local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + bossData.Size.Y / 2

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		local hp = model:GetAttribute("Health") or bossData.Health

		label.Text = isInfected and "🤢" or (bossData.Emoji or "👑")

		-- AI บอส: เดินลาดตระเวนอย่างสง่างาม หรือพุ่งเข้าหาเป้าหมาย
		local targetPos = Vector3.zero
		local randX = spawnArea.Position.X + math.random(-halfX + 20, halfX - 20)
		local randZ = spawnArea.Position.Z + math.random(-halfZ + 20, halfZ - 20)
		targetPos = Vector3.new(randX, fixedGroundY, randZ)

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = bossData.Speed
		local travelTime = dist / speed

		if travelTime > 0 then
			local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
			if flatLookDir.Magnitude > 0 then
				flatLookDir = flatLookDir.Unit
			else
				flatLookDir = rootPart.CFrame.LookVector
			end
			local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)
			local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = goalCFrame})
			tween:Play()
			task.wait(travelTime)
		end

		-- บอสใช้สกิลพิเศษ (Ability Spectacle)
		if model.Parent and rootPart and not isInfected then
			print("[BossManager] ⚡ บอส " .. bossData.Name .. " ใช้สกิล: " .. bossData.Ability)
			-- เล่นเอฟเฟกต์สกิลบอส (เช่น ปล่อยสายฟ้า หรือระเบิดไฟรอบตัว)
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxassetid://243660364"
			pe.Color = ColorSequence.new(bossData.Color)
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 5), NumberSequenceKeypoint.new(1, 0)})
			pe.Rate = 200
			pe.Speed = NumberRange.new(20, 40)
			pe.Lifetime = NumberRange.new(0.5, 1)
			pe.Parent = rootPart
			pe:Emit(50)
			task.delay(1, function() if pe then pe:Destroy() end end)
		end

		task.wait(math.random(2, 4))
	end

	-- เมื่อบอสถูกกำจัด ให้สลับไปบอสตัวถัดไป
	if BossManager.ActiveBoss == model then
		BossManager.ActiveBoss = nil
		print("[BossManager] 💀 บอส " .. bossData.Name .. " ถูกกำจัดแล้ว!")
		RemoteManager.FireAllClients(Constants.REMOTES.BOSS_DEFEATED, bossData.Name)

		currentBossIndex = (currentBossIndex % #BOSS_ORDER) + 1
	end
end

return BossManager
