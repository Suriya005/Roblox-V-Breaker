-- V-Breaker | NPCSpawner (Server)
-- ServerScriptService/Server/services/NPCSpawner.lua
-- ระบบสุ่มเกิด NPC สัตว์ Tier 1 และ AI เดินสุ่ม/หนี (Prototype Phase)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))

local NPCSpawner = {}

local MAX_ANIMALS = 15
local EMOJIS = { Rat = "🐭", Bird = "🐦", Pig = "🐷", Monkey = "🐵" }

function NPCSpawner.Init()
	print("[NPCSpawner] 🚀 เริ่มต้นระบบ NPC Spawner (Tier 1)...")

	-- 1. จัดการโฟลเดอร์และทำความสะอาดตัวเก่า
	local npcsFolder = workspace:FindFirstChild("NPCs")
	if not npcsFolder then
		npcsFolder = Instance.new("Folder")
		npcsFolder.Name = "NPCs"
		npcsFolder.Parent = workspace
	else
		-- ลบตัว Dummy เก่าออกเพื่อใช้ตัวใหม่ที่มี AI
		for _, child in ipairs(npcsFolder:GetChildren()) do
			child:Destroy()
		end
	end

	-- 2. สร้างพื้นที่ Spawn (Forest Zone Area)
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

	-- 3. เริ่มลูปสุ่มเกิดอัตโนมัติ
	task.spawn(function()
		NPCSpawner.StartSpawnerLoop(spawnArea, npcsFolder)
	end)

	print("[NPCSpawner] ✅ พร้อมใช้งาน!")
end

function NPCSpawner.StartSpawnerLoop(spawnArea: Part, npcsFolder: Folder)
	while true do
		task.wait(2)

		local currentCount = #npcsFolder:GetChildren()
		if currentCount < MAX_ANIMALS then
			-- สุ่มเลือกชนิดสัตว์ตาม SpawnWeight
			local roll = math.random(1, 100)
			local animalData

			if roll <= Constants.ANIMALS.RAT.SpawnWeight then
				animalData = Constants.ANIMALS.RAT
			elseif roll <= Constants.ANIMALS.RAT.SpawnWeight + Constants.ANIMALS.BIRD.SpawnWeight then
				animalData = Constants.ANIMALS.BIRD
			elseif roll <= Constants.ANIMALS.RAT.SpawnWeight + Constants.ANIMALS.BIRD.SpawnWeight + Constants.ANIMALS.PIG.SpawnWeight then
				animalData = Constants.ANIMALS.PIG
			else
				animalData = Constants.ANIMALS.MONKEY
			end

			NPCSpawner.SpawnAnimal(animalData, spawnArea, npcsFolder)
		end
	end
end

function NPCSpawner.SpawnAnimal(animalData: table, spawnArea: Part, npcsFolder: Folder)
	local model = Instance.new("Model")
	model.Name = animalData.Name .. "_" .. math.random(1000, 9999)
	model:SetAttribute("Tier", 1)
	model:SetAttribute("ImmuneStrength", animalData.Immune)
	model:SetAttribute("BioPoints", animalData.BioPoints)
	model:SetAttribute("AnimalType", animalData.Name)
	model:SetAttribute("IsInfected", false)

	CollectionService:AddTag(model, "NPC")

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = animalData.Size
	rootPart.Anchored = true
	rootPart.CanCollide = false -- ป้องกัน Physics Lag
	rootPart.Color = animalData.Color
	rootPart.Material = Enum.Material.SmoothPlastic
	rootPart.Parent = model

	model.PrimaryPart = rootPart

	-- สร้าง Emoji ด้านบนหัว (Humor & Identity)
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 60, 0, 60)
	bg.StudsOffset = Vector3.new(0, animalData.Size.Y / 2 + 1.5, 0)
	bg.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Name = "EmojiLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Text = EMOJIS[animalData.Name] or "🐾"
	label.TextSize = 36
	label.BackgroundTransparency = 1
	label.Parent = bg
	bg.Parent = rootPart

	-- คำนวณตำแหน่งเริ่มต้น
	local halfX = spawnArea.Size.X / 2
	local halfZ = spawnArea.Size.Z / 2
	local randX = spawnArea.Position.X + math.random(-halfX + 10, halfX - 10)
	local randZ = spawnArea.Position.Z + math.random(-halfZ + 10, halfZ - 10)
	local spawnY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + animalData.Size.Y / 2

	if animalData.CanFly then
		spawnY += math.random(12, 25)
	end

	rootPart.CFrame = CFrame.new(randX, spawnY, randZ)
	model.Parent = npcsFolder

	-- เริ่ม AI Loop
	task.spawn(function()
		NPCSpawner.AnimalAILoop(model, animalData, spawnArea)
	end)
end

function NPCSpawner.AnimalAILoop(model: Model, animalData: table, spawnArea: Part)
	local rootPart = model.PrimaryPart
	local label = rootPart:WaitForChild("BillboardGui"):WaitForChild("EmojiLabel")

	local halfX = spawnArea.Size.X / 2
	local halfZ = spawnArea.Size.Z / 2

	while model.Parent and rootPart and rootPart.Parent do
		local isInfected = model:GetAttribute("IsInfected")
		
		-- อัปเดต Emoji ตามสถานะ (Expression Reactive)
		label.Text = isInfected and "🤢" or (EMOJIS[animalData.Name] or "🐾")

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
				-- วิ่งหนีไปทิศตรงข้าม
				local dirAway = (rootPart.Position - nearestInfected.Position).Unit
				targetPos = rootPart.Position + dirAway * 25
			end
		end

		-- ถ้าไม่มีเป้าหมายวิ่งหนี ให้สุ่มเดินตามปกติ
		if targetPos == Vector3.zero then
			local randX = spawnArea.Position.X + math.random(-halfX + 10, halfX - 10)
			local randZ = spawnArea.Position.Z + math.random(-halfZ + 10, halfZ - 10)
			local targetY = spawnArea.Position.Y + spawnArea.Size.Y / 2 + animalData.Size.Y / 2

			if animalData.CanFly then
				targetY += math.random(12, 25)
			end

			targetPos = Vector3.new(randX, targetY, randZ)
		else
			-- ป้องกันวิ่งออกนอกพื้นที่ Spawn Area
			local clampX = math.clamp(targetPos.X, spawnArea.Position.X - halfX + 10, spawnArea.Position.X + halfX - 10)
			local clampZ = math.clamp(targetPos.Z, spawnArea.Position.Z - halfZ + 10, spawnArea.Position.Z + halfZ - 10)
			targetPos = Vector3.new(clampX, targetPos.Y, clampZ)
		end

		local dist = (targetPos - rootPart.Position).Magnitude
		local speed = isInfected and animalData.Speed * 0.7 or animalData.Speed
		local travelTime = dist / speed

		if travelTime > 0 then
			local lookPos = animalData.CanFly and targetPos or Vector3.new(targetPos.X, rootPart.Position.Y, targetPos.Z)
			local goalCFrame = CFrame.new(targetPos, targetPos + (lookPos - rootPart.Position))

			local tween = TweenService:Create(rootPart, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = goalCFrame})
			tween:Play()
			task.wait(travelTime)
		end

		-- หยุดพักก่อนเดินต่อ
		task.wait(math.random(1, 3))
	end
end

return NPCSpawner
