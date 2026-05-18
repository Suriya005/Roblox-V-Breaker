-- V-Breaker | GovernmentAI (Server Service)
-- ServerScriptService/Server/services/GovernmentAI.lua
-- ระบบ AI รัฐบาล: ตรวจจับการระบาด, ยกระดับ Threat Level, และวิจัย Vaccine

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local MutationService = require(script.Parent:WaitForChild("MutationService"))

local GovernmentAI = {}

-- ข้อมูลสถานะของแต่ละโซน
GovernmentAI.ZoneStates = {
	Forest = { ThreatLevel = 1, VaccineProgress = 0, Name = "Forest Zone", MinX = -50, MaxX = 55, SpawnAreaName = "ForestZone_SpawnArea" },
	City = { ThreatLevel = 1, VaccineProgress = 0, Name = "City Zone", MinX = 55, MaxX = 165, SpawnAreaName = "CityZone_SpawnArea" },
	Military = { ThreatLevel = 1, VaccineProgress = 0, Name = "Military Base", MinX = 165, MaxX = 275, SpawnAreaName = "MilitaryBase_SpawnArea" },
	Vought = { ThreatLevel = 1, VaccineProgress = 0, Name = "Vought HQ", MinX = 275, MaxX = 400, SpawnAreaName = "VoughtHQ_SpawnArea" },
}

-- รายชื่อระดับ Threat Level
GovernmentAI.THREAT_LEVELS = {
	[1] = { Name = "DEFCON 5 (Normal)", ResearchSpeed = 0, Color = Color3.fromRGB(100, 255, 100) },
	[2] = { Name = "DEFCON 4 (Investigating)", ResearchSpeed = 0.5, Color = Color3.fromRGB(255, 255, 100) },
	[3] = { Name = "DEFCON 3 (Lockdown)", ResearchSpeed = 1.5, Color = Color3.fromRGB(255, 150, 50) },
	[4] = { Name = "DEFCON 2 (Martial Law)", ResearchSpeed = 3.0, Color = Color3.fromRGB(255, 50, 50) },
}

function GovernmentAI.Init()
	print("[GovernmentAI] 🏛️ เริ่มต้นระบบ AI รัฐบาล (แยก 4 โซน + Doctor AI)...")
	task.spawn(GovernmentAI.StartLoop)
	print("[GovernmentAI] ✅ พร้อมใช้งาน!")
end

function GovernmentAI.GetZoneKey(pos)
	if not pos then return "Forest" end
	local x = pos.X
	if x < 55 then return "Forest"
	elseif x < 165 then return "City"
	elseif x < 275 then return "Military"
	else return "Vought" end
end

function GovernmentAI.StartLoop()
	while true do
		task.wait(1)

		-- 1. ดึง NPC ทั้งหมดที่ไม่ใช่หมอ
		local allNpcs = {}
		for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
			if npc:IsA("Model") and npc.Parent and not npc:GetAttribute("IsDoctor") then
				table.insert(allNpcs, npc)
			end
		end

		-- แยก NPC และการติดเชื้อตามโซน
		local zoneNpcs = { Forest = {}, City = {}, Military = {}, Vought = {} }
		local zoneInfected = { Forest = 0, City = 0, Military = 0, Vought = 0 }

		for _, npc in ipairs(allNpcs) do
			local root = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
			if root then
				local zKey = GovernmentAI.GetZoneKey(root.Position)
				if zoneNpcs[zKey] then
					table.insert(zoneNpcs[zKey], npc)
					if npc:GetAttribute("IsInfected") then
						zoneInfected[zKey] += 1
					end
				end
			end
		end

		local firstPlayer = Players:GetPlayers()[1]

		-- 2. คำนวณ Threat Level และ Vaccine Progress ของแต่ละโซน
		for zKey, zData in pairs(GovernmentAI.ZoneStates) do
			local infectedCount = zoneInfected[zKey]
			local newThreat = 1
			if infectedCount >= 8 then newThreat = 4
			elseif infectedCount >= 4 then newThreat = 3
			elseif infectedCount >= 1 then newThreat = 2
			else newThreat = 1 end

			if newThreat ~= zData.ThreatLevel then
				zData.ThreatLevel = newThreat
				local threatInfo = GovernmentAI.THREAT_LEVELS[zData.ThreatLevel]
				print("[GovernmentAI] 🚨 [" .. zData.Name .. "] ยกระดับ Threat Level:", threatInfo.Name)

				if zData.ThreatLevel >= 3 then
					RemoteManager.FireAllClients(Constants.REMOTES.NOTIFICATION, "🚨 รัฐบาลประกาศ " .. threatInfo.Name .. " ใน " .. zData.Name .. "! เร่งส่งทีมแพทย์!", "Warning")
				end
			end

			-- วิจัย/เตรียมส่งหมอ (ทำงานเมื่อ Threat Level >= 2)
			local threatInfo = GovernmentAI.THREAT_LEVELS[zData.ThreatLevel]
			if threatInfo.ResearchSpeed > 0 then
				local baseSpeed = threatInfo.ResearchSpeed
				if firstPlayer and MutationService.HasMutation(firstPlayer, "GENETIC_HARD") then
					baseSpeed *= 0.7
				end

				zData.VaccineProgress = math.clamp(zData.VaccineProgress + baseSpeed, 0, 100)

				-- เมื่อครบ 100% -> เรียกหมอมาฮีลและรักษาโรค!
				if zData.VaccineProgress >= 100 then
					print("[GovernmentAI] 👨‍🔬 [" .. zData.Name .. "] เตรียมทีมแพทย์สำเร็จ! ทำการส่ง Doctor ลงพื้นที่...")
					zData.VaccineProgress = 0
					zData.ThreatLevel = 1
					
					RemoteManager.FireAllClients(Constants.REMOTES.NOTIFICATION, "👨‍🔬 ทีมแพทย์ฉุกเฉินถูกส่งลงพื้นที่ใน " .. zData.Name .. " แล้ว!", "Warning")
					
					-- เสก Doctor ลงมาในโซน
					task.spawn(GovernmentAI.SpawnDoctor, zKey, zData)
				end
			end
		end

		-- 3. ส่งข้อมูลอัปเดตให้ผู้เล่นแต่ละคนตามโซนที่เขากำลังยืนอยู่
		for _, plr in ipairs(Players:GetPlayers()) do
			local char = plr.Character
			local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
			local plrZoneKey = "Forest"
			if root then
				plrZoneKey = GovernmentAI.GetZoneKey(root.Position)
			end

			local myZoneData = GovernmentAI.ZoneStates[plrZoneKey]
			local myThreatInfo = GovernmentAI.THREAT_LEVELS[myZoneData.ThreatLevel]
			local displayTitle = myZoneData.Name .. " - " .. myThreatInfo.Name

			RemoteManager.FireClient(Constants.REMOTES.THREAT_LEVEL_CHANGED, plr, myZoneData.ThreatLevel, displayTitle, myThreatInfo.Color)
			RemoteManager.FireClient(Constants.REMOTES.VACCINE_PROGRESS_CHANGED, plr, myZoneData.VaccineProgress)
		end
	end
end

function GovernmentAI.SpawnDoctor(zKey, zData)
	local spawnArea = workspace:FindFirstChild(zData.SpawnAreaName)
	if not spawnArea then return end

	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then return end

	-- สร้าง Model หมอ
	local model = Instance.new("Model")
	model.Name = "Doctor"
	model:SetAttribute("IsDoctor", true)
	model:SetAttribute("Tier", 2)
	model:SetAttribute("Health", 300)
	model:SetAttribute("MaxHealth", 300)
	model:SetAttribute("ImmuneStrength", 50)
	model:SetAttribute("IsInfected", false)

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(3.5, 5.2, 3.5)
	rootPart.Anchored = true
	rootPart.CanCollide = true
	rootPart.Color = Color3.fromRGB(240, 240, 255) -- ชุดกาวน์สีขาวสะอาด
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Parent = model
	model.PrimaryPart = rootPart

	-- สร้างป้ายบนหัว
	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 200, 0, 100)
	bg.StudsOffset = Vector3.new(0, 5.5, 0)
	bg.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 45)
	label.Text = "Doctor"
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(100, 200, 255)
	label.BackgroundTransparency = 1
	label.Parent = bg

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 1.5
	nameStroke.Parent = label

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0, 50)
	statusLabel.Text = "🛡️ 50 | 💧 30% | HP: 300"
	statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 14
	statusLabel.BackgroundTransparency = 1
	statusLabel.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.5
	stroke.Parent = statusLabel

	local healthBg = Instance.new("Frame")
	healthBg.Name = "HealthBg"
	healthBg.Size = UDim2.new(0, 100, 0, 10)
	healthBg.Position = UDim2.new(0.5, -50, 0, 70)
	healthBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	healthBg.Parent = bg

	local hCorner1 = Instance.new("UICorner")
	hCorner1.CornerRadius = UDim.new(1, 0)
	hCorner1.Parent = healthBg

	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, 0, 1, 0)
	healthFill.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
	healthFill.Parent = healthBg

	local hCorner2 = Instance.new("UICorner")
	hCorner2.CornerRadius = UDim.new(1, 0)
	hCorner2.Parent = healthFill

	bg.Parent = rootPart
	CollectionService:AddTag(model, "NPC")

	local minX = zData.MinX
	local maxX = zData.MaxX
	local minZ = math.floor(spawnArea.Position.Z - (spawnArea.Size.Z / 2) + 10)
	local maxZ = math.floor(spawnArea.Position.Z + (spawnArea.Size.Z / 2) - 10)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + 2.6

	model.Parent = npcsFolder
	model:PivotTo(CFrame.new(math.random(minX, maxX), spawnY, math.random(minZ, maxZ)))

	-- เริ่ม AI Doctor Loop
	task.spawn(GovernmentAI.DoctorAILoop, model, zData, spawnArea)
end

function GovernmentAI.DoctorAILoop(model, zData, spawnArea)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji", 5) and rootPart.VBreaker_Emoji:WaitForChild("EmojiLabel", 5)
	local minX = zData.MinX
	local maxX = zData.MaxX
	local minZ = math.floor(spawnArea.Position.Z - (spawnArea.Size.Z / 2) + 10)
	local maxZ = math.floor(spawnArea.Position.Z + (spawnArea.Size.Z / 2) - 10)
	local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + 2.6

	local firstPlayer = Players:GetPlayers()[1]

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		
		if isInfected then
			if label then
				label.Text = "Infected Doctor"
				label.TextColor3 = Color3.fromRGB(150, 255, 150)
			end
			rootPart.Color = Color3.fromRGB(50, 220, 50)
			rootPart.Material = Enum.Material.Neon
			
			local randX = math.random(minX, maxX)
			local randZ = math.random(minZ, maxZ)
			GovernmentAI.MoveDoctorTo(model, Vector3.new(randX, fixedGroundY, randZ), 12)
			task.wait(math.random(1, 3))
			continue
		end

		if label then
			label.Text = "Doctor"
			label.TextColor3 = Color3.fromRGB(100, 200, 255)
		end
		rootPart.Color = Color3.fromRGB(240, 240, 255)
		rootPart.Material = Enum.Material.SmoothPlastic

		-- ค้นหา NPC ที่ติดเชื้อในโซน
		local npcsFolder = workspace:FindFirstChild("NPCs")
		local targetToHeal = nil
		local minDist = 80 -- ระยะมองเห็น 80 studs

		if npcsFolder then
			for _, npc in ipairs(npcsFolder:GetChildren()) do
				if npc ~= model and npc:GetAttribute("IsInfected") then
					local targetRoot = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart")
					if targetRoot then
						local x = targetRoot.Position.X
						if x >= minX and x <= maxX then
							local dist = (targetRoot.Position - rootPart.Position).Magnitude
							if dist < minDist then
								minDist = dist
								targetToHeal = npc
							end
						end
					end
				end
			end
		end

		if targetToHeal then
			local targetRoot = targetToHeal.PrimaryPart or targetToHeal:FindFirstChild("HumanoidRootPart")
			if targetRoot then
				local dest = Vector3.new(targetRoot.Position.X, fixedGroundY, targetRoot.Position.Z)
				GovernmentAI.MoveDoctorTo(model, dest, 16) -- หมอวิ่งเร็ว 16 studs/sec

				if (targetRoot.Position - rootPart.Position).Magnitude <= 8 then
					local resisted = false
					if firstPlayer and MutationService.HasMutation(firstPlayer, "DRUG_RESIST_1") then
						if math.random(1, 100) <= 20 then
							resisted = true
						end
					end

					if resisted then
						RemoteManager.FireAllClients(Constants.REMOTES.SHOW_POPUP, nil, "💊 RESISTED!", targetRoot.Position, "Warning")
					else
						targetToHeal:SetAttribute("IsInfected", false)
						targetToHeal:SetAttribute("InfectedBy", nil)
						targetToHeal:SetAttribute("LastDamageTime", nil)
						targetToHeal:SetAttribute("LastSpreadTime", nil)

						local maxHp = targetToHeal:GetAttribute("MaxHealth") or 100
						targetToHeal:SetAttribute("Health", maxHp)

						local tier = targetToHeal:GetAttribute("Tier") or 1
						local color = Color3.fromRGB(120, 120, 120)
						local npcName = targetToHeal:GetAttribute("AnimalType") or targetToHeal:GetAttribute("HumanType") or targetToHeal:GetAttribute("MilitaryType") or targetToHeal:GetAttribute("SupeType") or targetToHeal:GetAttribute("BossType") or "NPC"
						
						if tier == 1 then
							local animalName = targetToHeal:GetAttribute("AnimalType") or "RAT"
							local animalData = Constants.ANIMALS[animalName] or Constants.ANIMALS.RAT
							color = animalData.Color
						else
							local humanName = targetToHeal:GetAttribute("HumanType") or "CITIZEN"
							local humanData = Constants.HUMANS[humanName] or Constants.HUMANS.CITIZEN
							color = humanData.Color
						end

						targetRoot.Color = color
						targetRoot.Material = Enum.Material.SmoothPlastic

						local bg = targetRoot:FindFirstChild("VBreaker_Emoji")
						if bg then
							local tLabel = bg:FindFirstChild("EmojiLabel")
							local statusLabel = bg:FindFirstChild("StatusLabel")
							local healthBg = bg:FindFirstChild("HealthBg")
							local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")

							if tLabel then
								tLabel.Text = npcName
								tLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
							end
							if statusLabel then
								local immune = targetToHeal:GetAttribute("ImmuneStrength") or 10
								statusLabel.Text = "🛡️ " .. immune .. " | 💧 30% | HP: " .. maxHp
								statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
							end
							if healthFill then
								healthFill.Size = UDim2.new(1, 0, 1, 0)
								healthFill.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
							end
						end

						RemoteManager.FireAllClients(Constants.REMOTES.SHOW_POPUP, nil, "✨ CURED & HEALED!", targetRoot.Position, "Bio")
						print("[GovernmentAI] 👨‍🔬 Doctor รักษาสำเร็จ:", npcName)
					end
				end
			end
		else
			local randX = math.random(minX, maxX)
			local randZ = math.random(minZ, maxZ)
			GovernmentAI.MoveDoctorTo(model, Vector3.new(randX, fixedGroundY, randZ), 10)
		end

		task.wait(math.random(1, 2))
	end
end

function GovernmentAI.MoveDoctorTo(model, targetPos, speed)
	local rootPart = model.PrimaryPart
	if not rootPart then return end

	local dist = (targetPos - rootPart.Position).Magnitude
	local travelTime = dist / speed

	if travelTime > 0 then
		local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
		if flatLookDir.Magnitude > 0 then flatLookDir = flatLookDir.Unit else flatLookDir = rootPart.CFrame.LookVector end
		local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)

		local startTime = os.clock()
		local startCFrame = rootPart.CFrame
		local animSpeed = 12
		local bobHeight = 0.8
		local tiltAngle = math.rad(8)

		local elapsed = 0
		while elapsed < travelTime and model.Parent and rootPart.Parent do
			elapsed = os.clock() - startTime
			local alpha = math.clamp(elapsed / travelTime, 0, 1)
			local baseCFrame = startCFrame:Lerp(goalCFrame, alpha)
			
			local bob = math.abs(math.sin(elapsed * animSpeed)) * bobHeight
			local tilt = math.sin(elapsed * animSpeed) * tiltAngle
			
			rootPart.CFrame = baseCFrame * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, tilt)
			task.wait()
		end

		if model.Parent and rootPart.Parent then
			rootPart.CFrame = goalCFrame
		end
	end
end

return GovernmentAI
