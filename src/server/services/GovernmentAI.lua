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

local currentThreatLevel = 1
local vaccineProgress = 0 -- 0 ถึง 100

-- รายชื่อระดับ Threat Level
GovernmentAI.THREAT_LEVELS = {
	[1] = { Name = "DEFCON 5 (Normal)", ResearchSpeed = 0, Color = Color3.fromRGB(100, 255, 100) },
	[2] = { Name = "DEFCON 4 (Investigating)", ResearchSpeed = 0.5, Color = Color3.fromRGB(255, 255, 100) },
	[3] = { Name = "DEFCON 3 (Lockdown)", ResearchSpeed = 1.5, Color = Color3.fromRGB(255, 150, 50) },
	[4] = { Name = "DEFCON 2 (Martial Law)", ResearchSpeed = 3.0, Color = Color3.fromRGB(255, 50, 50) },
}

function GovernmentAI.Init()
	print("[GovernmentAI] 🏛️ เริ่มต้นระบบ AI รัฐบาล...")

	-- เริ่ม Loop ตรวจจับและวิจัยวัคซีน
	task.spawn(GovernmentAI.StartLoop)

	print("[GovernmentAI] ✅ พร้อมใช้งาน!")
end

function GovernmentAI.StartLoop()
	while true do
		task.wait(1)

		-- 1. นับจำนวนสัตว์ที่ติดเชื้อใน Workspace
		local allNpcs = {}
		for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
			if npc:IsA("Model") and npc.Parent then
				table.insert(allNpcs, npc)
			end
		end

		local infectedCount = 0
		for _, npc in ipairs(allNpcs) do
			if npc:GetAttribute("IsInfected") then
				infectedCount += 1
			end
		end

		-- 2. คำนวณ Threat Level ตามจำนวนสัตว์ที่ติดเชื้อ
		local newThreat = 1
		if infectedCount >= 8 then
			newThreat = 4 -- Martial Law
		elseif infectedCount >= 4 then
			newThreat = 3 -- Lockdown
		elseif infectedCount >= 1 then
			newThreat = 2 -- Investigating
		else
			newThreat = 1 -- Normal
		end

		if newThreat ~= currentThreatLevel then
			currentThreatLevel = newThreat
			local threatData = GovernmentAI.THREAT_LEVELS[currentThreatLevel]
			print("[GovernmentAI] 🚨 ยกระดับ Threat Level:", threatData.Name)
			RemoteManager.FireAllClients(Constants.REMOTES.THREAT_LEVEL_CHANGED, currentThreatLevel, threatData.Name, threatData.Color)
			
			if currentThreatLevel >= 3 then
				RemoteManager.FireAllClients(Constants.REMOTES.NOTIFICATION, "🚨 รัฐบาลประกาศ " .. threatData.Name .. "! เร่งวิจัยวัคซีน!", "Warning")
			end
		end

		-- 3. คำนวณการวิจัย Vaccine (ทำงานเมื่อ Threat Level >= 2)
		local threatData = GovernmentAI.THREAT_LEVELS[currentThreatLevel]
		if threatData.ResearchSpeed > 0 then
			local baseSpeed = threatData.ResearchSpeed

			-- ตรวจสอบว่าผู้เล่นคนแรกมีสกิล Genetic Hardening หรือไม่ (หน่วงเวลาวิจัย)
			local firstPlayer = Players:GetPlayers()[1]
			if firstPlayer and MutationService.HasMutation(firstPlayer, "GENETIC_HARD") then
				baseSpeed *= 0.7 -- ช้าลง 30%
			end

			vaccineProgress = math.clamp(vaccineProgress + baseSpeed, 0, 100)
			RemoteManager.FireAllClients(Constants.REMOTES.VACCINE_PROGRESS_CHANGED, vaccineProgress)

			-- 4. เมื่อวิจัยวัคซีนครบ 100% -> ปล่อยวัคซีนรักษา!
			if vaccineProgress >= 100 then
				print("[GovernmentAI] 💉 ปล่อยวัคซีนสำเร็จ! ทำการรักษา NPC...")
				vaccineProgress = 0
				currentThreatLevel = 1
				RemoteManager.FireAllClients(Constants.REMOTES.VACCINE_PROGRESS_CHANGED, 0)
				RemoteManager.FireAllClients(Constants.REMOTES.THREAT_LEVEL_CHANGED, 1, GovernmentAI.THREAT_LEVELS[1].Name, GovernmentAI.THREAT_LEVELS[1].Color)

				local curedCount = 0
				local resistedCount = 0

				for _, npc in ipairs(allNpcs) do
					if npc:GetAttribute("IsInfected") then
						-- ตรวจสอบ Drug Resistance (โอกาสต้านทานวัคซีน 20%)
						if firstPlayer and MutationService.HasMutation(firstPlayer, "DRUG_RESIST_1") then
							if math.random(1, 100) <= 20 then
								resistedCount += 1
								continue
							end
						end

						-- ทำการรักษา
						npc:SetAttribute("IsInfected", false)
						npc:SetAttribute("InfectedBy", nil)
						npc:SetAttribute("LastDamageTime", nil)
						npc:SetAttribute("LastSpreadTime", nil)

						local ring = npc:FindFirstChild("AirborneRing")
						if ring then ring:Destroy() end

						local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
						if root then
							local tier = npc:GetAttribute("Tier") or 1
							local color = Color3.fromRGB(120, 120, 120)
							local emojiStr = "🐾"

							if tier == 1 then
								local animalName = npc:GetAttribute("AnimalType") or "RAT"
								local animalData = Constants.ANIMALS[animalName] or Constants.ANIMALS.RAT
								color = animalData.Color
								emojiStr = (animalData.Name == "Rat" and "🐭" or animalData.Name == "Bird" and "🐦" or animalData.Name == "Pig" and "🐷" or "🐵")
							else
								local humanName = npc:GetAttribute("HumanType") or "CITIZEN"
								local humanData = Constants.HUMANS[humanName] or Constants.HUMANS.CITIZEN
								color = humanData.Color
								emojiStr = (humanData.Name == "Citizen" and "🧍" or humanData.Name == "Scientist" and "👨‍🔬" or "👮")
							end

							root.Color = color
							root.Material = Enum.Material.SmoothPlastic

							local bg = root:FindFirstChild("VBreaker_Emoji")
							if bg then
								local label = bg:FindFirstChild("EmojiLabel")
								local statusLabel = bg:FindFirstChild("StatusLabel")
								local healthBg = bg:FindFirstChild("HealthBg")
								local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")

								if label then label.Text = emojiStr end
								if statusLabel then
									local immune = npc:GetAttribute("ImmuneStrength") or 10
									local maxHp = npc:GetAttribute("MaxHealth") or 100
									statusLabel.Text = "🛡️ " .. immune .. " | 💧 30% | HP: " .. maxHp
									statusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
								end
								if healthFill then
									healthFill.Size = UDim2.new(1, 0, 1, 0)
									healthFill.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
								end
							end
						end
						curedCount += 1
					end
				end

				-- แจ้งเตือนผู้เล่น
				if resistedCount > 0 then
					RemoteManager.FireAllClients(Constants.REMOTES.NOTIFICATION, "💊 วัคซีนถูกปล่อย! รักษา " .. curedCount .. " ตัว (ต้านทานได้ " .. resistedCount .. " ตัว!)", "Warning")
					RemoteManager.FireAllClients(Constants.REMOTES.VACCINE_DEPLOYED, true, curedCount, resistedCount)
				else
					RemoteManager.FireAllClients(Constants.REMOTES.NOTIFICATION, "💉 วัคซีนถูกปล่อย! สัตว์ที่ติดเชื้อถูกรักษาทั้งหมด!", "Warning")
					RemoteManager.FireAllClients(Constants.REMOTES.VACCINE_DEPLOYED, false, curedCount, 0)
				end
			end
		end
	end
end

return GovernmentAI
