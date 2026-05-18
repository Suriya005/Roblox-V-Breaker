-- V-Breaker | InfectionEngine (Server)
-- ServerScriptService/Server/services/InfectionEngine.lua
-- ระบบคำนวณการแพร่เชื้อ, วงแหวน Airborne, สถานะ Waterborne, และระบบลดเลือดจนตาย

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))
local MutationService = require(script.Parent:WaitForChild("MutationService"))

local InfectionEngine = {}

function InfectionEngine.Init()
	print("[InfectionEngine] 🚀 เริ่มต้นระบบ Infection Engine...")

	RemoteManager.OnServerEvent(Constants.REMOTES.REQUEST_INFECT, function(player, targetNpc)
		InfectionEngine.OnRequestInfect(player, targetNpc)
	end)

	task.spawn(InfectionEngine.StartLoop)

	print("[InfectionEngine] ✅ พร้อมใช้งาน!")
end

function InfectionEngine.OnRequestInfect(player: Player, targetNpc: Instance)
	if not targetNpc or not targetNpc:IsA("Model") then return end

	local isNpc = CollectionService:HasTag(targetNpc, "NPC") or targetNpc:FindFirstChild("Humanoid") ~= nil
	if not isNpc then return end

	local now = os.clock()
	local lastTime = targetNpc:GetAttribute("LastPlayerHitTime_" .. player.UserId) or 0
	if now - lastTime < 0.8 then return end -- ป้องกันการสแปมคลิกรัวจากผู้เล่น (Server Debounce แบบเงียบๆ)
	targetNpc:SetAttribute("LastPlayerHitTime_" .. player.UserId, now)

	if targetNpc:GetAttribute("IsInfected") then
		-- เป้าหมายติดเชื้ออยู่แล้ว ให้ทำการต่อยทำดาเมจ (Melee Damage) ทันที!
		local punchDamage = 20 + (MutationService.GetBossDPS(player) or 0)
		InfectionEngine.DamageNPC(targetNpc, player, punchDamage)
		return
	end

	-- เป้าหมายยังไม่ติดเชื้อ ปล่อยไวรัสทันที!
	InfectionEngine.InfectNPC(targetNpc, player.UserId)
end

function InfectionEngine.DamageNPC(targetNpc: Model, player: Player, damageAmount: number)
	local hp = targetNpc:GetAttribute("Health") or 100
	if hp <= 0 then return end -- ตายไปแล้ว

	hp -= damageAmount
	targetNpc:SetAttribute("Health", hp)
	targetNpc:SetAttribute("LastDamageTime", os.clock())

	local root = targetNpc:FindFirstChild("HumanoidRootPart") or targetNpc:FindFirstChildWhichIsA("BasePart")
	local pos = root and root.Position or Vector3.zero

	-- แสดง Pop-up ตัวเลข Damage ลอยขึ้น
	RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "-" .. damageAmount, pos, "Damage")

	-- อัปเดต UI หลอดเลือดบนหัว
	if root then
		local bg = root:FindFirstChild("VBreaker_Emoji")
		if bg then
			local statusLabel = bg:FindFirstChild("StatusLabel")
			local healthBg = bg:FindFirstChild("HealthBg")
			local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")
			
			local immune = targetNpc:GetAttribute("ImmuneStrength") or 10
			local maxHp = targetNpc:GetAttribute("MaxHealth") or 100
			local baseChance = player and MutationService.GetSpreadChance(player) or Constants.INFECTION.BASE_SPREAD_CHANCE

			if statusLabel then
				statusLabel.Text = "🛡️ " .. immune .. " | 💧 " .. baseChance .. "% | HP: " .. math.max(0, hp)
				statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
			end
			if healthFill then
				healthFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
			end
		end
	end

	local tier = targetNpc:GetAttribute("Tier") or 1
	if tier == 4 then
		local maxHp = targetNpc:GetAttribute("MaxHealth") or 100
		RemoteManager.FireAllClients(Constants.REMOTES.BOSS_HEALTH_CHANGED, math.max(0, hp), maxHp)
	end

	-- ตรวจสอบการตาย
	if hp <= 0 then
		targetNpc:SetAttribute("Health", 0)
		
		local bioReward = targetNpc:GetAttribute("BioPoints") or 1
		PlayerService.AddBioPoints(player, bioReward)
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "💀 KILL! +" .. bioReward .. " Bio", pos, "Bio")

		if tier == 4 then
			local dnaReward = targetNpc:GetAttribute("DnaPoints") or 10
			PlayerService.AddDnaPoints(player, dnaReward)
			RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🧬 BOSS KILL! +" .. dnaReward .. " DNA", pos + Vector3.new(0, 3, 0), "DNA")
			RemoteManager.FireAllClients(Constants.REMOTES.BOSS_DEFEATED, targetNpc:GetAttribute("BossType") or "Boss")
		end
		
		-- เล่นเอฟเฟกต์ตาย (Particle สลายตัวสีแดงเลือด)
		if root then
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxassetid://243660364"
			pe.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
			pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
			pe.Rate = 100
			pe.Speed = NumberRange.new(10, 20)
			pe.Lifetime = NumberRange.new(0.5, 1)
			pe.Parent = root
			pe:Emit(30)
		end
		
		task.delay(0.5, function()
			if targetNpc then targetNpc:Destroy() end
		end)
	end
end

function InfectionEngine.InfectNPC(targetNpc: Model, infectedByUserId: number)
	targetNpc:SetAttribute("IsInfected", true)
	targetNpc:SetAttribute("InfectedBy", infectedByUserId)
	targetNpc:SetAttribute("LastSpreadTime", os.clock())
	targetNpc:SetAttribute("LastDamageTime", os.clock())

	local tier = targetNpc:GetAttribute("Tier") or 1
	local tierData = Constants.TIERS[tier] or Constants.TIERS[1]
	local root = targetNpc:FindFirstChild("HumanoidRootPart") or targetNpc:FindFirstChildWhichIsA("BasePart")
	local player = Players:GetPlayerByUserId(infectedByUserId)

	-- เปลี่ยนสี Part เป็นสีเขียวเรืองแสง (Toxic Green)
	for _, part in ipairs(targetNpc:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = Color3.fromRGB(50, 220, 50)
			part.Material = Enum.Material.Neon
		end
	end

	-- ดึงค่าสเตตัสอัปเกรดของผู้เล่น
	local spreadRadius = player and MutationService.GetSpreadRadius(player) or Constants.INFECTION.BASE_SPREAD_RADIUS
	local baseChance = player and MutationService.GetSpreadChance(player) or Constants.INFECTION.BASE_SPREAD_CHANCE


	-- เปลี่ยนป้ายหน้าบนหัวเป็นหน้าป่วย และอัปเดตสถานะ Waterborne + Immune
	if root then
		local bg = root:FindFirstChild("VBreaker_Emoji")
		if bg then
			local label = bg:FindFirstChild("EmojiLabel")
			local statusLabel = bg:FindFirstChild("StatusLabel")
			local healthBg = bg:FindFirstChild("HealthBg")
			local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")

			local immune = targetNpc:GetAttribute("ImmuneStrength") or 10

			local npcName = targetNpc:GetAttribute("AnimalType") or targetNpc:GetAttribute("HumanType") or targetNpc:GetAttribute("MilitaryType") or targetNpc:GetAttribute("SupeType") or targetNpc:GetAttribute("BossType") or "NPC"
			if label then
				label.Text = "Infected " .. npcName
				label.TextColor3 = Color3.fromRGB(150, 255, 150)
			end
			if statusLabel then
				statusLabel.Text = "🛡️ " .. immune .. " | 💧 " .. baseChance .. "% | HP: 100"
				statusLabel.TextColor3 = Color3.fromRGB(255, 150, 150)
			end
			if healthFill then
				healthFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
			end
		end
	end

	-- มอบ Bio Points ให้ผู้เล่นที่เป็นเจ้าของเชื้อ
	if player then
		local bioPoints = tierData.BioPoints
		if tier == 1 then
			bioPoints *= MutationService.GetAnimalBioMultiplier(player)
		end
		
		local critChance = MutationService.GetCriticalInfectChance(player)
		local isCrit = false
		if critChance > 0 and math.random(1, 100) <= critChance then
			bioPoints *= 5
			isCrit = true
		end

		PlayerService.AddBioPoints(player, bioPoints)
		
		local pos = root and root.Position or Vector3.zero
		local popupText = isCrit and ("⚡ CRIT! +" .. bioPoints .. " Bio") or ("+" .. bioPoints .. " Bio")
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, popupText, pos, "Bio")
	end

	RemoteManager.FireAllClients(Constants.REMOTES.INFECTION_SPREAD, targetNpc, infectedByUserId)
	print("[InfectionEngine] 🦠 NPC ติดเชื้อ! Tier:", tier, "โดย User:", infectedByUserId)
end

function InfectionEngine.StartLoop()
	while true do
		task.wait(0.2)

		local now = os.clock()

		local allNpcs = {}
		for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
			if npc:IsA("Model") and npc.Parent then
				table.insert(allNpcs, npc)
			end
		end

		local infectedNpcs = {}
		local uninfectedNpcs = {}

		for _, npc in ipairs(allNpcs) do
			if npc:GetAttribute("IsInfected") then
				table.insert(infectedNpcs, npc)
			else
				table.insert(uninfectedNpcs, npc)
			end
		end

		-- อัปเดตป้ายสถานะของสัตว์ที่ยังไม่ติดเชื้อ (Uninfected NPCs) ให้แสดงโอกาสแพร่เชื้อปัจจุบันของผู้เล่น
		local firstPlayer = Players:GetPlayers()[1]
		local currentBaseChance = firstPlayer and MutationService.GetSpreadChance(firstPlayer) or Constants.INFECTION.BASE_SPREAD_CHANCE

		for _, uninfected in ipairs(uninfectedNpcs) do
			local root = uninfected:FindFirstChild("HumanoidRootPart") or uninfected:FindFirstChildWhichIsA("BasePart")
			if root then
				local bg = root:FindFirstChild("VBreaker_Emoji")
				if bg then
					local statusLabel = bg:FindFirstChild("StatusLabel")
					local immune = uninfected:GetAttribute("ImmuneStrength") or 10
					local maxHp = uninfected:GetAttribute("MaxHealth") or 100
					if statusLabel then
						statusLabel.Text = "🛡️ " .. immune .. " | 💧 " .. currentBaseChance .. "% | HP: " .. maxHp
					end
				end
			end
		end

		for _, infected in ipairs(infectedNpcs) do
			local infRoot = infected:FindFirstChild("HumanoidRootPart") or infected:FindFirstChildWhichIsA("BasePart")
			if not infRoot then continue end

			local infectedBy = infected:GetAttribute("InfectedBy")
			local player = infectedBy and Players:GetPlayerByUserId(infectedBy) or nil

			-- ดึงระยะแพร่กระจายและโอกาสแพร่เชื้อที่อัปเกรดแล้ว
			local spreadRadius = player and MutationService.GetSpreadRadius(player) or Constants.INFECTION.BASE_SPREAD_RADIUS
			local baseChance = player and MutationService.GetSpreadChance(player) or Constants.INFECTION.BASE_SPREAD_CHANCE


			-- ระบบลดเลือด (Health Drain) ทุกๆ 1 วินาที
			local lastDamage = infected:GetAttribute("LastDamageTime") or 0
			if now - lastDamage >= 1 then
				infected:SetAttribute("LastDamageTime", now)
				
				local hp = infected:GetAttribute("Health") or 100
				-- ลดเลือดพื้นฐาน 15 หน่วยต่อวินาที + โบนัสความเสียหายจากสกิล Fever/Lesions
				local dps = 15 + (player and MutationService.GetBossDPS(player) or 0)
				hp -= dps
				
				-- แสดงตัวเลข Damage ลอยขึ้นเหนือหัวสัตว์ (Juice & Spectacle)
				if player and infRoot then
					RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "-" .. dps, infRoot.Position, "Damage")
				end
				
				-- อัปเดต UI หลอดเลือดบนหัว
				local bg = infRoot:FindFirstChild("VBreaker_Emoji")
				if bg then
					local statusLabel = bg:FindFirstChild("StatusLabel")
					local healthBg = bg:FindFirstChild("HealthBg")
					local healthFill = healthBg and healthBg:FindFirstChild("HealthFill")
					
					local immune = infected:GetAttribute("ImmuneStrength") or 10
					local maxHp = infected:GetAttribute("MaxHealth") or 100
					local tier = infected:GetAttribute("Tier") or 1

					if statusLabel then
						statusLabel.Text = "🛡️ " .. immune .. " | 💧 " .. baseChance .. "% | HP: " .. math.max(0, hp)
						statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
					end
					if healthFill then
						healthFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
					end
					
					-- ถ้าเป็นบอส ให้ส่ง Event อัปเดต Boss Health Bar บน UI ของทุกคน
					if tier == 4 then
						RemoteManager.FireAllClients(Constants.REMOTES.BOSS_HEALTH_CHANGED, math.max(0, hp), maxHp)
					end
				end

				if hp <= 0 then
					infected:SetAttribute("Health", 0)
					local tier = infected:GetAttribute("Tier") or 1
					
					-- สัตว์/มนุษย์/บอสตาย! มอบ Bio Points และ DNA Points ให้ผู้เล่นที่เป็นเจ้าของเชื้อ
					if player then
						local bioReward = infected:GetAttribute("BioPoints") or 1
						PlayerService.AddBioPoints(player, bioReward)
						RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "💀 KILL! +" .. bioReward .. " Bio", infRoot.Position, "Bio")

						if tier == 4 then
							local dnaReward = infected:GetAttribute("DnaPoints") or 10
							PlayerService.AddDnaPoints(player, dnaReward)
							RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🧬 BOSS KILL! +" .. dnaReward .. " DNA", infRoot.Position + Vector3.new(0, 3, 0), "DNA")
							RemoteManager.FireAllClients(Constants.REMOTES.BOSS_DEFEATED, infected:GetAttribute("BossType") or "Boss")
						end
					end
					
					-- เล่นเอฟเฟกต์ตาย (Particle สลายตัวสีแดงเลือด)
					local pe = Instance.new("ParticleEmitter")
					pe.Texture = "rbxassetid://243660364"
					pe.Color = ColorSequence.new(Color3.fromRGB(255, 50, 50))
					pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
					pe.Rate = 100
					pe.Speed = NumberRange.new(10, 20)
					pe.Lifetime = NumberRange.new(0.5, 1)
					pe.Parent = infRoot
					pe:Emit(30)
					
					-- ลบโมเดลออกเพื่อให้ NPCSpawner สุ่มเกิดตัวใหม่มาให้ฟาร์มเรื่อยๆ
					task.delay(0.5, function()
						if infected then infected:Destroy() end
					end)
					continue
				else
					infected:SetAttribute("Health", hp)
				end
			end

			-- ตรวจสอบ Tick Rate ของเจ้าของเชื้อสำหรับการลามต่อ
			local lastSpread = infected:GetAttribute("LastSpreadTime") or 0
			local tickRate = player and MutationService.GetTickRate(player) or Constants.INFECTION.TICK_RATE
			
			if now - lastSpread < tickRate then continue end
			infected:SetAttribute("LastSpreadTime", now)

			for _, target in ipairs(uninfectedNpcs) do
				if target:GetAttribute("IsInfected") then continue end

				local tgtRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
				if not tgtRoot then continue end

				local dist = (infRoot.Position - tgtRoot.Position).Magnitude
				if dist <= spreadRadius then
					local tier = target:GetAttribute("Tier") or 1
					local tierData = Constants.TIERS[tier] or Constants.TIERS[1]
					local immune = tierData.ImmuneStrength

					local effectiveChance = math.clamp(baseChance - immune, 5, 100)
					
					if math.random(1, 100) <= effectiveChance then
						InfectionEngine.InfectNPC(target, infectedBy)
					end
				end
			end
		end
	end
end

return InfectionEngine
