-- V-Breaker | NPCSpawner (Server)
-- ServerScriptService/Server/services/NPCSpawner.lua
-- ระบบสุ่มเกิด NPC สัตว์ Tier 1 พร้อมระบบ AI, หลอดเลือด (HP Bar), และเกิดใหม่เมื่อตาย

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))

local NPCSpawner = {}

local MAX_ANIMALS = 25
local MAX_HUMANS = 15

function NPCSpawner.GetZoneLimits(spawnArea: Part)
	local minZ = math.floor(spawnArea.Position.Z - (spawnArea.Size.Z / 2) + 10)
	local maxZ = math.floor(spawnArea.Position.Z + (spawnArea.Size.Z / 2) - 10)

	local minX, maxX
	if spawnArea.Name == "ForestZone_SpawnArea" then
		minX, maxX = -40, 45
	elseif spawnArea.Name == "CityZone_SpawnArea" then
		minX, maxX = 65, 155
	elseif spawnArea.Name == "MilitaryBase_SpawnArea" then
		minX, maxX = 175, 265
	elseif spawnArea.Name == "VoughtHQ_SpawnArea" then
		minX, maxX = 285, 375
	else
		minX = math.floor(spawnArea.Position.X - (spawnArea.Size.X / 2) + 10)
		maxX = math.floor(spawnArea.Position.X + (spawnArea.Size.X / 2) - 10)
	end

	return minX, maxX, minZ, maxZ
end

function NPCSpawner.Init()
	print("[NPCSpawner] 🚀 เริ่มต้นระบบ NPC Spawner (Tier 1 & Tier 2)...")

	-- 1. จัดการโฟลเดอร์และทำความสะอาดตัวเก่า
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = workspace
	else
		for _, child in ipairs(npcsFolder:GetChildren()) do
			child:Destroy()
		end
	end

	-- 2. สร้างพื้นที่ Spawn (Forest Zone และ City Zone)
	local spawnArea = workspace:FindFirstChild("ForestZone_SpawnArea")
	if not spawnArea then
		spawnArea = Instance.new("Part")
		spawnArea.Name = "ForestZone_SpawnArea"
		spawnArea.Size = Vector3.new(100, 1, 100)
		spawnArea.Position = Vector3.new(0, 0, -60)
		spawnArea.Anchored = true
		spawnArea.CanCollide = true
		spawnArea.Color = Color3.fromRGB(34, 139, 34) -- Forest Green
		spawnArea.Transparency = 0.8
		spawnArea.Material = Enum.Material.SmoothPlastic
		spawnArea.Parent = workspace
		print("[NPCSpawner] 🌲 สร้างพื้นที่ Forest Zone Spawn Area")
	end

	local citySpawnArea = workspace:FindFirstChild("CityZone_SpawnArea")
	if not citySpawnArea then
		citySpawnArea = Instance.new("Part")
		citySpawnArea.Name = "CityZone_SpawnArea"
		citySpawnArea.Size = Vector3.new(100, 1, 100)
		citySpawnArea.Position = Vector3.new(110, 0, -60)
		citySpawnArea.Anchored = true
		citySpawnArea.CanCollide = true
		citySpawnArea.Color = Color3.fromRGB(128, 128, 128) -- City Concrete Grey
		citySpawnArea.Transparency = 0.8
		citySpawnArea.Material = Enum.Material.SmoothPlastic
		citySpawnArea.Parent = workspace
		print("[NPCSpawner] 🏙️ สร้างพื้นที่ City Zone Spawn Area")
	end

	local militarySpawnArea = workspace:FindFirstChild("MilitaryBase_SpawnArea")
	if not militarySpawnArea then
		militarySpawnArea = Instance.new("Part")
		militarySpawnArea.Name = "MilitaryBase_SpawnArea"
		militarySpawnArea.Size = Vector3.new(100, 1, 100)
		militarySpawnArea.Position = Vector3.new(220, 0, -60)
		militarySpawnArea.Anchored = true
		militarySpawnArea.CanCollide = true
		militarySpawnArea.Color = Color3.fromRGB(85, 107, 47) -- Camo Green
		militarySpawnArea.Transparency = 0.8
		militarySpawnArea.Material = Enum.Material.SmoothPlastic
		militarySpawnArea.Parent = workspace
		print("[NPCSpawner] 🪖 สร้างพื้นที่ Military Base Spawn Area")
	end

	local voughtSpawnArea = workspace:FindFirstChild("VoughtHQ_SpawnArea")
	if not voughtSpawnArea then
		voughtSpawnArea = Instance.new("Part")
		voughtSpawnArea.Name = "VoughtHQ_SpawnArea"
		voughtSpawnArea.Size = Vector3.new(100, 1, 100)
		voughtSpawnArea.Position = Vector3.new(330, 0, -60)
		voughtSpawnArea.Anchored = true
		voughtSpawnArea.CanCollide = true
		voughtSpawnArea.Color = Color3.fromRGB(25, 25, 112) -- Vought Dark Blue
		voughtSpawnArea.Transparency = 0.8
		voughtSpawnArea.Material = Enum.Material.SmoothPlastic
		voughtSpawnArea.Parent = workspace
		print("[NPCSpawner] 🦸‍♂️ สร้างพื้นที่ Vought HQ Spawn Area")
	end

	-- 3. เริ่มลูปสุ่มเกิดอัตโนมัติ
	task.spawn(function()
		NPCSpawner.StartSpawnerLoop(spawnArea, citySpawnArea, militarySpawnArea, voughtSpawnArea, npcsFolder)
	end)

	print("[NPCSpawner] ✅ พร้อมใช้งาน!")
end

function NPCSpawner.StartSpawnerLoop(spawnArea: Part, citySpawnArea: Part, militarySpawnArea: Part, voughtSpawnArea: Part, npcsFolder: Folder)
	local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
	while true do
		task.wait(0.5)

		local animalCount = 0
		local humanCount = 0
		local militaryCount = 0
		local supeCount = 0
		for _, child in ipairs(npcsFolder:GetChildren()) do
			local tier = child:GetAttribute("Tier")
			local mType = child:GetAttribute("MilitaryType")
			local sType = child:GetAttribute("SupeType")
			if tier == 1 then
				animalCount += 1
			elseif tier == 2 then
				humanCount += 1
			elseif tier == 3 then
				if mType then militaryCount += 1 end
				if sType then supeCount += 1 end
			end
		end

		-- สุ่มเกิดสัตว์ป่า (Tier 1)
		if animalCount < MAX_ANIMALS then
			local spawnAmount = (animalCount < MAX_ANIMALS / 2) and 2 or 1
			for i = 1, spawnAmount do
				if animalCount >= MAX_ANIMALS then break end

				local roll = math.random(1, 100)
				local animalData

				if roll <= Constants.ANIMALS.RAT.SpawnWeight then
					animalData = Constants.ANIMALS.RAT
				elseif roll <= Constants.ANIMALS.RAT.SpawnWeight + Constants.ANIMALS.PIG.SpawnWeight then
					animalData = Constants.ANIMALS.PIG
				else
					animalData = Constants.ANIMALS.MONKEY
				end

				NPCSpawner.SpawnAnimal(animalData, spawnArea, npcsFolder)
				animalCount += 1
			end
		end

		-- สุ่มเกิดมนุษย์ (Tier 2 - City Zone)
		if PlayerService.IsZoneUnlocked("City") and humanCount < MAX_HUMANS then
			local spawnAmount = (humanCount < MAX_HUMANS / 2) and 2 or 1
			for i = 1, spawnAmount do
				if humanCount >= MAX_HUMANS then break end

				local roll = math.random(1, 100)
				local humanData

				if roll <= Constants.HUMANS.CITIZEN.SpawnWeight then
					humanData = Constants.HUMANS.CITIZEN
				elseif roll <= Constants.HUMANS.CITIZEN.SpawnWeight + Constants.HUMANS.SCIENTIST.SpawnWeight then
					humanData = Constants.HUMANS.SCIENTIST
				else
					humanData = Constants.HUMANS.POLICE
				end

				NPCSpawner.SpawnHuman(humanData, citySpawnArea, npcsFolder)
				humanCount += 1
			end
		end

		-- สุ่มเกิดทหาร (Tier 3 - Military Base)
		if PlayerService.IsZoneUnlocked("Military") and militaryCount < 10 then
			local spawnAmount = (militaryCount < 5) and 2 or 1
			for i = 1, spawnAmount do
				if militaryCount >= 10 then break end
				local roll = math.random(1, 100)
				local milData = (roll <= Constants.MILITARY.SOLDIER.SpawnWeight) and Constants.MILITARY.SOLDIER or Constants.MILITARY.TANK
				NPCSpawner.SpawnMilitary(milData, militarySpawnArea, npcsFolder)
				militaryCount += 1
			end
		end

		-- สุ่มเกิดซุปเปอร์ฮีโร่ (Tier 3 - Vought HQ)
		if PlayerService.IsZoneUnlocked("Vought") and supeCount < 10 then
			local spawnAmount = (supeCount < 5) and 2 or 1
			for i = 1, spawnAmount do
				if supeCount >= 10 then break end
				local roll = math.random(1, 100)
				local supeData = (roll <= Constants.SUPES.ELITE.SpawnWeight) and Constants.SUPES.ELITE or Constants.SUPES.HERO
				NPCSpawner.SpawnSupe(supeData, voughtSpawnArea, npcsFolder)
				supeCount += 1
			end
		end
	end
end

function NPCSpawner.SpawnAnimal(animalData: table, spawnArea: Part, npcsFolder: Folder)
	local petsFolder = workspace:FindFirstChild("Animals/Pets")
	local templateName = "Bunny"
	if animalData.Name == "Pig" then templateName = "Pig"
	elseif animalData.Name == "Monkey" then templateName = "Dog"
	end

	local templateModel = petsFolder and petsFolder:FindFirstChild(templateName)
	local model
	local rootPart

	if templateModel then
		model = templateModel:Clone()
		model.Name = animalData.Name .. "_" .. math.random(1000, 9999)
		
		local mainPart = model:FindFirstChild(templateName) or model:FindFirstChildWhichIsA("BasePart")
		
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = mainPart and mainPart.Size or animalData.Size
		rootPart.CFrame = mainPart and mainPart.CFrame or CFrame.new()
		rootPart.Transparency = 1
		rootPart.Anchored = true
		rootPart.CanCollide = false
		rootPart.Parent = model

		model.PrimaryPart = rootPart

		for _, child in ipairs(model:GetChildren()) do
			if child:IsA("BasePart") and child ~= rootPart then
				child.Anchored = false
				child.CanCollide = false
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = rootPart
				weld.Part1 = child
				weld.Parent = rootPart
			end
		end
	else
		model = Instance.new("Model")
		model.Name = animalData.Name .. "_" .. math.random(1000, 9999)
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Size = animalData.Size
		rootPart.Anchored = true
		rootPart.CanCollide = false
		rootPart.Color = animalData.Color
		rootPart.Material = Enum.Material.SmoothPlastic
		rootPart.Parent = model
		model.PrimaryPart = rootPart
	end

	model:SetAttribute("Tier", 1)
	model:SetAttribute("ImmuneStrength", animalData.Immune)
	model:SetAttribute("BioPoints", animalData.BioPoints)
	model:SetAttribute("AnimalType", animalData.Name)
	model:SetAttribute("IsInfected", false)
	model:SetAttribute("Health", 100)
	model:SetAttribute("MaxHealth", 100)

	CollectionService:AddTag(model, "NPC")

	-- สร้าง BillboardGui ด้านบนหัว (Emoji + Status + Health Bar)
	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 180, 0, 95)
	bg.StudsOffset = Vector3.new(0, animalData.Size.Y / 2 + 2.5, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 40)
	label.Text = animalData.Name
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.BackgroundTransparency = 1
	label.Parent = bg

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 1.5
	nameStroke.Parent = label

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 20)
	statusLabel.Position = UDim2.new(0, 0, 0, 45)
	statusLabel.Text = "🛡️ " .. animalData.Immune .. " | 💧 30% | HP: 100"
	statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 14
	statusLabel.BackgroundTransparency = 1
	statusLabel.Parent = bg

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.5
	stroke.Parent = statusLabel

	-- หลอดเลือด (Health Bar)
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

	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)
	local randX = math.random(minX, maxX)
	local randZ = math.random(minZ, maxZ)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + animalData.Size.Y / 2

	if animalData.CanFly then
		spawnY += math.random(12, 25)
	end

	model.Parent = npcsFolder
	model:PivotTo(CFrame.new(randX, spawnY, randZ))

	-- เริ่ม AI Loop
	task.spawn(function()
		NPCSpawner.AnimalAILoop(model, animalData, spawnArea)
	end)
end

function NPCSpawner.AnimalAILoop(model: Model, animalData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		
		label.Text = isInfected and ("Infected " .. animalData.Name) or animalData.Name
		label.TextColor3 = isInfected and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 255, 255)

		local targetPos = Vector3.zero

		-- AI พฤติกรรมลิง: หนีเมื่อเจอคนติดเชื้อ
		if animalData.Name == "Monkey" and not isInfected then
			local npcsFolder = workspace:FindFirstChild("NPCs")
			local nearestInfected = nil
			local minDist = 30 -- รัศมีมองเห็น 30 studs

			if npcsFolder then
				for _, npc in ipairs(npcsFolder:GetChildren()) do
					if npc ~= model and npc:GetAttribute("IsInfected") then
						local otherRoot = npc.PrimaryPart
						if otherRoot then
							local dist = (otherRoot.Position - rootPart.Position).Magnitude
							if dist < minDist then
								minDist = dist
								nearestInfected = otherRoot
							end
						end
					end
				end
			end

			if nearestInfected then
				local flatSelf = Vector3.new(rootPart.Position.X, 0, rootPart.Position.Z)
				local flatTarget = Vector3.new(nearestInfected.Position.X, 0, nearestInfected.Position.Z)
				local dirAway = (flatSelf - flatTarget).Unit
				targetPos = rootPart.Position + dirAway * 25
			end
		end

		local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + animalData.Size.Y / 2

		if targetPos == Vector3.zero then
			local randX = math.random(minX, maxX)
			local randZ = math.random(minZ, maxZ)
			local targetY = fixedGroundY

			if animalData.CanFly then
				targetY += math.random(12, 25)
			end

			targetPos = Vector3.new(randX, targetY, randZ)
		else
			local clampX = math.clamp(targetPos.X, minX, maxX)
			local clampZ = math.clamp(targetPos.Z, minZ, maxZ)
			local targetY = animalData.CanFly and targetPos.Y or fixedGroundY
			targetPos = Vector3.new(clampX, targetY, clampZ)
		end

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = isInfected and animalData.Speed * 0.7 or animalData.Speed
		local travelTime = dist / speed

		if travelTime > 0 then
			local lookPos = animalData.CanFly and targetPos or Vector3.new(targetPos.X, fixedGroundY, targetPos.Z)
			local goalCFrame = CFrame.new(targetPos, targetPos + (lookPos - rootPart.Position))

			local startTime = os.clock()
			local startCFrame = rootPart.CFrame
			local animSpeed = animalData.CanFly and 6 or 14 -- บินกระพือช้าๆ วิ่งกระโดดเร็วๆ
			local bobHeight = animalData.CanFly and 0.4 or 1.2
			local tiltAngle = math.rad(12)

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

		task.wait(math.random(1, 3))
	end
end

function NPCSpawner.SpawnHuman(humanData: table, spawnArea: Part, npcsFolder: Folder)
	local model = Instance.new("Model")
	model.Name = humanData.Name .. "_" .. math.random(1000, 9999)
	model:SetAttribute("Tier", 2)
	model:SetAttribute("ImmuneStrength", humanData.Immune)
	model:SetAttribute("BioPoints", humanData.BioPoints)
	model:SetAttribute("HumanType", humanData.Name)
	model:SetAttribute("IsInfected", false)
	model:SetAttribute("Health", 200) -- มนุษย์เลือด 200
	model:SetAttribute("MaxHealth", 200)

	CollectionService:AddTag(model, "NPC")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = humanData.Size
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Color = humanData.Color
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	-- สร้าง BillboardGui
	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 200, 0, 100)
	bg.StudsOffset = Vector3.new(0, humanData.Size.Y / 2 + 3, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 45)
	label.Text = humanData.Name
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	statusLabel.Text = "🛡️ " .. humanData.Immune .. " | 💧 30% | HP: 200"
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
	healthBg.Size = UDim2.new(0, 120, 0, 12)
	healthBg.Position = UDim2.new(0.5, -60, 0, 75)
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

	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)
	local randX = math.random(minX, maxX)
	local randZ = math.random(minZ, maxZ)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + humanData.Size.Y / 2

	model.Parent = npcsFolder
	model:PivotTo(CFrame.new(randX, spawnY, randZ))

	task.spawn(function()
		NPCSpawner.HumanAILoop(model, humanData, spawnArea)
	end)
end

function NPCSpawner.HumanAILoop(model: Model, humanData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		
		label.Text = isInfected and ("Infected " .. humanData.Name) or humanData.Name
		label.TextColor3 = isInfected and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 255, 255)

		local targetPos = Vector3.zero
		local npcsFolder = workspace:FindFirstChild("NPCs")
		local nearestInfected = nil
		local minDist = 40 -- ระยะมองเห็น 40 studs

		if npcsFolder then
			for _, npc in ipairs(npcsFolder:GetChildren()) do
				if npc ~= model and npc:GetAttribute("IsInfected") then
					local otherRoot = npc.PrimaryPart
					if otherRoot then
						local dist = (otherRoot.Position - rootPart.Position).Magnitude
						if dist < minDist then
							minDist = dist
							nearestInfected = otherRoot
						end
					end
				end
			end
		end

		local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + humanData.Size.Y / 2

		if humanData.Name == "Police" then
			if not isInfected and nearestInfected then
				local flatSelf = Vector3.new(rootPart.Position.X, fixedGroundY, rootPart.Position.Z)
				local flatTarget = Vector3.new(nearestInfected.Position.X, fixedGroundY, nearestInfected.Position.Z)
				local dirTowards = (flatTarget - flatSelf).Unit
				targetPos = flatSelf + dirTowards * 15
			elseif isInfected then
				local randX = math.random(minX, maxX)
				local randZ = math.random(minZ, maxZ)
				targetPos = Vector3.new(randX, fixedGroundY, randZ)
			end
		else
			if isInfected then
				local randX = math.random(minX, maxX)
				local randZ = math.random(minZ, maxZ)
				targetPos = Vector3.new(randX, fixedGroundY, randZ)
			elseif not isInfected and nearestInfected then
				local flatSelf = Vector3.new(rootPart.Position.X, fixedGroundY, rootPart.Position.Z)
				local flatTarget = Vector3.new(nearestInfected.Position.X, fixedGroundY, nearestInfected.Position.Z)
				local dirAway = (flatSelf - flatTarget).Unit
				targetPos = flatSelf + dirAway * 30
			end
		end

		if targetPos == Vector3.zero then
			local randX = math.random(minX, maxX)
			local randZ = math.random(minZ, maxZ)
			targetPos = Vector3.new(randX, fixedGroundY, randZ)
		else
			local clampX = math.clamp(targetPos.X, minX, maxX)
			local clampZ = math.clamp(targetPos.Z, minZ, maxZ)
			targetPos = Vector3.new(clampX, fixedGroundY, clampZ)
		end

		local dist = (targetPos - rootPart.Position).Magnitude
		local speedMultiplier = 1
		if humanData.Name == "Police" and isInfected then
			speedMultiplier = 0.6
		elseif humanData.Name == "Police" and not isInfected and nearestInfected then
			speedMultiplier = 1.3
		elseif isInfected or nearestInfected then
			speedMultiplier = 1.5
		end

		local speed = humanData.Speed * speedMultiplier
		local travelTime = dist / speed

		if travelTime > 0 then
			local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
			if flatLookDir.Magnitude > 0 then
				flatLookDir = flatLookDir.Unit
			else
				flatLookDir = rootPart.CFrame.LookVector
			end
			local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)

			local startTime = os.clock()
			local startCFrame = rootPart.CFrame
			local animSpeed = 12
			local bobHeight = 1.0
			local tiltAngle = math.rad(10)

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

		task.wait(math.random(1, 3))
	end
end

function NPCSpawner.SpawnMilitary(milData: table, spawnArea: Part, npcsFolder: Folder)
	local model = Instance.new("Model")
	model.Name = milData.Name .. "_" .. math.random(1000, 9999)
	model:SetAttribute("Tier", 3)
	model:SetAttribute("ImmuneStrength", milData.Immune)
	model:SetAttribute("BioPoints", milData.BioPoints)
	model:SetAttribute("MilitaryType", milData.Name)
	model:SetAttribute("IsInfected", false)
	model:SetAttribute("Health", 300)
	model:SetAttribute("MaxHealth", 300)

	CollectionService:AddTag(model, "NPC")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = milData.Size
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Color = milData.Color
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 200, 0, 100)
	bg.StudsOffset = Vector3.new(0, milData.Size.Y / 2 + 3, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 45)
	label.Text = milData.Name
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	statusLabel.Text = "🛡️ " .. milData.Immune .. " | 💧 30% | HP: 300"
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
	healthBg.Size = UDim2.new(0, 120, 0, 12)
	healthBg.Position = UDim2.new(0.5, -60, 0, 75)
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

	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)
	local randX = math.random(minX, maxX)
	local randZ = math.random(minZ, maxZ)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + milData.Size.Y / 2

	model.Parent = npcsFolder
	model:PivotTo(CFrame.new(randX, spawnY, randZ))

	task.spawn(function()
		NPCSpawner.MilitaryAILoop(model, milData, spawnArea)
	end)
end

function NPCSpawner.SpawnSupe(supeData: table, spawnArea: Part, npcsFolder: Folder)
	local model = Instance.new("Model")
	model.Name = supeData.Name .. "_" .. math.random(1000, 9999)
	model:SetAttribute("Tier", 3)
	model:SetAttribute("ImmuneStrength", supeData.Immune)
	model:SetAttribute("BioPoints", supeData.BioPoints)
	model:SetAttribute("SupeType", supeData.Name)
	model:SetAttribute("IsInfected", false)
	model:SetAttribute("Health", 500)
	model:SetAttribute("MaxHealth", 500)

	CollectionService:AddTag(model, "NPC")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = supeData.Size
	rootPart.Anchored = true
	rootPart.CanCollide = false
	rootPart.Color = supeData.Color
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	local bg = Instance.new("BillboardGui")
	bg.Name = "VBreaker_Emoji"
	bg.Size = UDim2.new(0, 200, 0, 100)
	bg.StudsOffset = Vector3.new(0, supeData.Size.Y / 2 + 3, 0)
	bg.AlwaysOnTop = true
	bg.MaxDistance = 100

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 0, 45)
	label.Text = supeData.Name
	label.TextSize = 28
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	statusLabel.Text = "🛡️ " .. supeData.Immune .. " | 💧 30% | HP: 500"
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
	healthBg.Size = UDim2.new(0, 120, 0, 12)
	healthBg.Position = UDim2.new(0.5, -60, 0, 75)
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

	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)
	local randX = math.random(minX, maxX)
	local randZ = math.random(minZ, maxZ)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + supeData.Size.Y / 2

	if supeData.CanFly then
		spawnY += math.random(15, 30)
	end

	model.Parent = npcsFolder
	model:PivotTo(CFrame.new(randX, spawnY, randZ))

	task.spawn(function()
		NPCSpawner.SupeAILoop(model, supeData, spawnArea, supeData.CanFly, spawnY)
	end)
end

function NPCSpawner.MilitaryAILoop(model: Model, milData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)
	local fixedGroundY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + milData.Size.Y / 2

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		label.Text = isInfected and ("Infected " .. milData.Name) or milData.Name
		label.TextColor3 = isInfected and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 255, 255)

		local randX = math.random(minX, maxX)
		local randZ = math.random(minZ, maxZ)
		local targetPos = Vector3.new(randX, fixedGroundY, randZ)

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = milData.Speed * (isInfected and 0.6 or 1.0)
		local travelTime = dist / speed

		if travelTime > 0 then
			local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
			if flatLookDir.Magnitude > 0 then flatLookDir = flatLookDir.Unit else flatLookDir = rootPart.CFrame.LookVector end
			local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)

			local startTime = os.clock()
			local startCFrame = rootPart.CFrame
			local animSpeed = milData.Name == "Tank" and 8 or 12 -- รถถังขยับหนักแน่น ทหารวิ่งกระฉับกระเฉง
			local bobHeight = milData.Name == "Tank" and 0.5 or 1.0
			local tiltAngle = math.rad(milData.Name == "Tank" and 5 or 10)

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
		task.wait(math.random(1, 3))
	end
end

function NPCSpawner.SupeAILoop(model: Model, supeData: table, spawnArea: Part, canFly: boolean, spawnY: number)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("VBreaker_Emoji"):WaitForChild("EmojiLabel")
	local minX, maxX, minZ, maxZ = NPCSpawner.GetZoneLimits(spawnArea)

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		label.Text = isInfected and ("Infected " .. supeData.Name) or supeData.Name
		label.TextColor3 = isInfected and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 255, 255)

		local randX = math.random(minX, maxX)
		local randZ = math.random(minZ, maxZ)
		local targetY = canFly and (spawnArea.Position.Y + spawnArea.Size.Y / 2 + supeData.Size.Y / 2 + math.random(15, 30)) or spawnY
		local targetPos = Vector3.new(randX, targetY, randZ)

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = supeData.Speed * (isInfected and 0.5 or 1.0)
		local travelTime = dist / speed

		if travelTime > 0 then
			local flatLookDir = Vector3.new(targetPos.X - rootPart.Position.X, 0, targetPos.Z - rootPart.Position.Z)
			if flatLookDir.Magnitude > 0 then flatLookDir = flatLookDir.Unit else flatLookDir = rootPart.CFrame.LookVector end
			local goalCFrame = CFrame.new(targetPos, targetPos + flatLookDir)

			local startTime = os.clock()
			local startCFrame = rootPart.CFrame
			local animSpeed = canFly and 6 or 12
			local bobHeight = canFly and 0.4 or 1.0
			local tiltAngle = math.rad(canFly and 8 or 10)

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
		task.wait(math.random(1, 3))
	end
end

return NPCSpawner
