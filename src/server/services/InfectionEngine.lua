-- V-Breaker | InfectionEngine (Server)
-- ServerScriptService/Server/services/InfectionEngine.lua
-- ระบบคำนวณการแพร่เชื้อไวรัสและสะสม Bio Points (Prototype Phase)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))

local InfectionEngine = {}

function InfectionEngine.Init()
	print("[InfectionEngine] 🚀 เริ่มต้นระบบ Infection Engine...")

	-- รับคำสั่งจาก Client เมื่อผู้เล่นกดปล่อยไวรัสใส่ NPC
	RemoteManager.OnServerEvent(Constants.REMOTES.REQUEST_INFECT, function(player, targetNpc)
		InfectionEngine.OnRequestInfect(player, targetNpc)
	end)

	-- เริ่มลูปคำนวณการแพร่กระจายเชื้ออัตโนมัติ
	task.spawn(InfectionEngine.StartLoop)

	print("[InfectionEngine] ✅ พร้อมใช้งาน!")
end

function InfectionEngine.OnRequestInfect(player: Player, targetNpc: Instance)
	if not PlayerService.CanInfect(player) then
		-- ติดคูลดาวน์
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "ไวรัสกำลังคูลดาวน์!", "Warning")
		return
	end

	if not targetNpc or not targetNpc:IsA("Model") then return end

	-- ตรวจสอบว่าเป็น NPC หรือไม่ (เช็คจาก Tag หรือ Humanoid)
	local isNpc = CollectionService:HasTag(targetNpc, "NPC") or targetNpc:FindFirstChild("Humanoid") ~= nil
	if not isNpc then return end

	-- ตรวจสอบว่าติดเชื้ออยู่แล้วหรือไม่
	if targetNpc:GetAttribute("IsInfected") then
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "เป้าหมายติดเชื้ออยู่แล้ว!", "Warning")
		return
	end

	-- ทำการติดเชื้อให้เป้าหมายแรก
	InfectionEngine.InfectNPC(targetNpc, player.UserId)
end

function InfectionEngine.InfectNPC(targetNpc: Model, infectedByUserId: number)
	targetNpc:SetAttribute("IsInfected", true)
	targetNpc:SetAttribute("InfectedBy", infectedByUserId)

	-- ดึงข้อมูล Tier
	local tier = targetNpc:GetAttribute("Tier") or 1
	local tierData = Constants.TIERS[tier] or Constants.TIERS[1]

	-- เปลี่ยนสี Part เป็นสีเขียวเรืองแสง (Toxic Green)
	for _, part in ipairs(targetNpc:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = Color3.fromRGB(50, 220, 50)
			part.Material = Enum.Material.Neon
		end
	end

	-- มอบ Bio Points ให้ผู้เล่นที่เป็นเจ้าของเชื้อ
	local player = Players:GetPlayerByUserId(infectedByUserId)
	if player then
		PlayerService.AddBioPoints(player, tierData.BioPoints)
		
		-- แจ้ง Client ให้แสดง Pop-up Bio Points
		local root = targetNpc:FindFirstChild("HumanoidRootPart") or targetNpc:FindFirstChildWhichIsA("BasePart")
		local pos = root and root.Position or Vector3.zero
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "+" .. tierData.BioPoints .. " Bio", pos, "Bio")
	end

	-- แจ้งทุก Client ให้เล่น Particle / Sound / Screen Shake
	RemoteManager.FireAllClients(Constants.REMOTES.INFECTION_SPREAD, targetNpc, infectedByUserId)
	print("[InfectionEngine] 🦠 NPC ติดเชื้อ! Tier:", tier, "โดย User:", infectedByUserId)
end

function InfectionEngine.StartLoop()
	while true do
		task.wait(Constants.INFECTION.TICK_RATE)

		-- ค้นหา NPC ทั้งหมดใน Workspace
		local allNpcs = {}
		local npcsFolder = workspace:FindFirstChild("NPCs")
		
		if npcsFolder then
			for _, npc in ipairs(npcsFolder:GetChildren()) do
				if npc:IsA("Model") then table.insert(allNpcs, npc) end
			end
		else
			-- ถ้าไม่มีโฟลเดอร์ NPCs ให้หาจาก Workspace ที่มี Tag หรือ Humanoid
			for _, obj in ipairs(workspace:GetChildren()) do
				if obj:IsA("Model") and (CollectionService:HasTag(obj, "NPC") or obj:FindFirstChild("Humanoid")) then
					table.insert(allNpcs, obj)
				end
			end
		end

		-- แยกกลุ่มติดเชื้อ และ ไม่ติดเชื้อ
		local infectedNpcs = {}
		local uninfectedNpcs = {}

		for _, npc in ipairs(allNpcs) do
			if npc:GetAttribute("IsInfected") then
				table.insert(infectedNpcs, npc)
			else
				table.insert(uninfectedNpcs, npc)
			end
		end

		-- ลูปแพร่เชื้อจาก Infected → Uninfected
		for _, infected in ipairs(infectedNpcs) do
			local infRoot = infected:FindFirstChild("HumanoidRootPart") or infected:FindFirstChildWhichIsA("BasePart")
			if not infRoot then continue end

			local infectedBy = infected:GetAttribute("InfectedBy")

			for _, target in ipairs(uninfectedNpcs) do
				-- ตรวจสอบว่าเป้าหมายยังไม่ติดเชื้อ (ป้องกันการติดซ้ำในลูปเดียวกัน)
				if target:GetAttribute("IsInfected") then continue end

				local tgtRoot = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
				if not tgtRoot then continue end

				-- ตรวจสอบระยะทาง
				local dist = (infRoot.Position - tgtRoot.Position).Magnitude
				if dist <= Constants.INFECTION.BASE_SPREAD_RADIUS then
					-- คำนวณโอกาสติดเชื้อ
					local tier = target:GetAttribute("Tier") or 1
					local tierData = Constants.TIERS[tier] or Constants.TIERS[1]
					local immune = tierData.ImmuneStrength

					-- สูตรคำนวณโอกาส: โอกาสพื้นฐาน - (Immune / 10)
					local effectiveChance = math.clamp(Constants.INFECTION.BASE_SPREAD_CHANCE - (immune / 10), 5, 100)
					
					if math.random(1, 100) <= effectiveChance then
						InfectionEngine.InfectNPC(target, infectedBy)
					end
				end
			end
		end
	end
end

return InfectionEngine
