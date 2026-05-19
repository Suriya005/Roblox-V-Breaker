-- V-Breaker | BossManager (Server)
-- ServerScriptService/Server/services/BossManager.lua
-- ระบบจัดการบอสประจำโซน (Thunderclap, Inferno, Vortex, SUPREME)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))

local BossManager = {}
BossManager.ActiveBosses = {
	Forest = nil,
	City = nil,
	Military = nil,
	Vought = nil,
}

BossManager.BOSS_CONFIGS = {
	Forest = Constants.BOSSES.THUNDERCLAP,
	City = Constants.BOSSES.INFERNO,
	Military = Constants.BOSSES.VORTEX,
	Vought = Constants.BOSSES.SUPREME,
}

function BossManager.Init()
	print("[BossManager] ⚔️ เริ่มต้นระบบ Boss Manager (เกิดแยก 4 โซน)...")

	-- เริ่มลูปเช็คและสุ่มเกิดบอสประจำโซน
	task.spawn(BossManager.StartBossLoop)
	-- เริ่มลูปซิงค์ข้อมูลบอสให้ผู้เล่นตามโซนที่เขายืนอยู่
	task.spawn(BossManager.StartClientSyncLoop)

	print("[BossManager] ✅ พร้อมใช้งาน!")
end

function BossManager.StartBossLoop()
	local PlayerService = require(script.Parent:WaitForChild("PlayerService"))

	while true do
		task.wait(30) -- เช็คการเกิดของบอสทุกๆ 30 วินาที

		for zoneKey, bossData in pairs(BossManager.BOSS_CONFIGS) do
			-- ตรวจสอบว่าโซนนั้นปลดล็อกหรือยัง (Forest ปลดล็อกตั้งแต่เริ่ม)
			local isUnlocked = (zoneKey == "Forest") or PlayerService.IsZoneUnlocked(bossData.Zone)

			if isUnlocked then
				-- ถ้ายังไม่มีบอสในโซนนั้น ให้ทำการสุ่มเกิด
				if not BossManager.ActiveBosses[zoneKey] or not BossManager.ActiveBosses[zoneKey].Parent then
					local spawnAreaName = (zoneKey == "Forest" and "ForestZone_SpawnArea" or zoneKey == "City" and "CityZone_SpawnArea" or zoneKey == "Military" and "MilitaryBase_SpawnArea" or "VoughtHQ_SpawnArea")
					local spawnArea = workspace:FindFirstChild(spawnAreaName)

					if spawnArea then
						BossManager.SpawnBoss(zoneKey, bossData, spawnArea)
					end
				end
			end
		end
	end
end

function BossManager.StartClientSyncLoop()
	local lastZoneMap = {} -- บันทึกโซนล่าสุดของผู้เล่นแต่ละคน

	while true do
		task.wait(0.5)

		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			local char = plr.Character
			local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
			if root then
				local x = root.Position.X
				local currentZone = "Forest"
				if x < 55 then currentZone = "Forest"
				elseif x < 165 then currentZone = "City"
				elseif x < 275 then currentZone = "Military"
				else currentZone = "Vought" end

				local myBoss = BossManager.ActiveBosses[currentZone]
				local oldZone = lastZoneMap[plr]

				-- ถ้าผู้เล่นเปลี่ยนโซน หรือเพิ่งเข้ามา
				if currentZone ~= oldZone then
					lastZoneMap[plr] = currentZone
					if myBoss and myBoss.Parent then
						local bossData = BossManager.BOSS_CONFIGS[currentZone]
						local curHp = myBoss:GetAttribute("Health") or bossData.Health
						local maxHp = myBoss:GetAttribute("MaxHealth") or bossData.Health
						RemoteManager.FireClient(Constants.REMOTES.BOSS_SPAWNED, plr, myBoss, bossData.Name, curHp, maxHp, bossData.Color)
					else
						RemoteManager.FireClient(Constants.REMOTES.BOSS_DEFEATED, plr, "CLEAR_ZONE_BOSS")
					end
				else
					-- ถ้าอยู่โซนเดิมและมีบอส ให้ซิงค์เลือด
					if myBoss and myBoss.Parent then
						local curHp = myBoss:GetAttribute("Health") or 1000
						local maxHp = myBoss:GetAttribute("MaxHealth") or 1000
						RemoteManager.FireClient(Constants.REMOTES.BOSS_HEALTH_CHANGED, plr, curHp, maxHp)
					end
				end
			end
		end
	end
end

function BossManager.SpawnBoss(zoneKey: string, bossData: table, spawnArea: Part)
	print("[BossManager] 👑 บอสประจำโซนปรากฏตัว: " .. bossData.Name .. " (" .. zoneKey .. " Zone)")

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
	rootPart.Material = Enum.Material.Neon
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	-- สร้าง BillboardGui อลังการสำหรับบอส
	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 250, 0, 120)
	bg.StudsOffset = Vector3.new(0, bossData.Size.Y / 2 + 4, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 150

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 55)
	label.Text = bossData.Name
	label.TextSize = 36
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.BackgroundTransparency = 1
	label.Parent = bg

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Parent = label

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 25)
	statusLabel.Position = UDim2.new(0, 0, 0, 60)
	statusLabel.Text = "🛡️ " .. bossData.Immune .. " | HP: " .. bossData.Health
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
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

	BossManager.ActiveBosses[zoneKey] = model

	-- ส่ง Event แจ้งเตือน Client ทุกคนที่อยู่ในโซนนั้นว่าบอสเกิดแล้ว
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		local char = plr.Character
		local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
		if root then
			local x = root.Position.X
			local pZone = "Forest"
			if x < 55 then pZone = "Forest"
			elseif x < 165 then pZone = "City"
			elseif x < 275 then pZone = "Military"
			else pZone = "Vought" end

			if pZone == zoneKey then
				RemoteManager.FireClient(Constants.REMOTES.BOSS_SPAWNED, plr, model, bossData.Name, bossData.Health, bossData.Health, bossData.Color)
			end
		end
	end

	-- เริ่ม Boss AI Loop
	task.spawn(function()
		BossManager.BossAILoop(zoneKey, model, bossData, spawnArea)
	end)
end

function BossManager.BossAILoop(zoneKey: string, model: Model, bossData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local statusLabel = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("StatusLabel")

	local halfX = spawnArea.Size.X / 2
	local halfZ = spawnArea.Size.Z / 2
	local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + bossData.Size.Y / 2

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		local hp = model:GetAttribute("Health") or bossData.Health

		label.Text = isInfected and ("Infected " .. bossData.Name) or bossData.Name
		label.TextColor3 = isInfected and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 215, 0)

		-- AI บอส: เดินลาดตระเวนอย่างสง่างาม
		local targetPos = Vector3.zero
		local randX = spawnArea.Position.X + math.random(-halfX + 20, halfX - 20)
		local randZ = spawnArea.Position.Z + math.random(-halfZ + 20, halfZ - 20)
		targetPos = Vector3.new(randX, fixedGroundY, randZ)

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = bossData.Speed
		local travelTime = dist / speed

		if travelTime > 0 then
			local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
			if flatLookDir.Magnitude > 0 then flatLookDir = flatLookDir.Unit else flatLookDir = rootPart.CFrame.LookVector end
			local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)
			local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = goalCFrame})
			tween:Play()
			task.wait(travelTime)
		end

		-- บอสใช้สกิลพิเศษ
		if model.Parent and rootPart and not isInfected then
			print("[BossManager] ⚡ บอส " .. bossData.Name .. " ใช้สกิล: " .. bossData.Ability)
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

	-- เมื่อบอสถูกกำจัด
	if BossManager.ActiveBosses[zoneKey] == model then
		BossManager.ActiveBosses[zoneKey] = nil
		print("[BossManager] 💀 บอสประจำโซน " .. bossData.Name .. " ถูกกำจัดแล้ว!")
		
		-- แจ้งเตือน Client ทุกคนที่อยู่ในโซนนั้นว่าบอสถูกกำจัด
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			local char = plr.Character
			local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
			if root then
				local x = root.Position.X
				local pZone = "Forest"
				if x < 55 then pZone = "Forest"
				elseif x < 165 then pZone = "City"
				elseif x < 275 then pZone = "Military"
				else pZone = "Vought" end

				if pZone == zoneKey then
					RemoteManager.FireClient(Constants.REMOTES.BOSS_DEFEATED, plr, bossData.Name)
				end
			end
		end
	end
end

return BossManager
