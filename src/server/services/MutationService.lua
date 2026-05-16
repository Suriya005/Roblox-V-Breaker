-- V-Breaker | MutationService (Server)
-- ServerScriptService/Server/services/MutationService.lua
-- จัดการระบบปลดล็อกและเก็บข้อมูล Mutation ของผู้เล่น

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local MutationTree = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("MutationTree"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local PlayerService = require(script.Parent:WaitForChild("PlayerService"))

local MutationService = {}
local playerMutations = {} -- [userId] = { [mutationId] = true }

function MutationService.Init()
	print("[MutationService] 🚀 เริ่มต้นระบบจัดการ Mutation...")

	Players.PlayerAdded:Connect(function(player)
		MutationService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		MutationService.OnPlayerRemoving(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		MutationService.OnPlayerAdded(player)
	end

	-- รับคำสั่งซื้อ Mutation จาก Client
	RemoteManager.OnServerEvent(Constants.REMOTES.BUY_MUTATION, function(player, mutationId)
		MutationService.BuyMutation(player, mutationId)
	end)

	print("[MutationService] ✅ พร้อมใช้งาน!")
end

function MutationService.OnPlayerAdded(player: Player)
	playerMutations[player.UserId] = {}
	
	-- ส่งข้อมูล Mutation ปัจจุบันให้ Client
	task.wait(1)
	if player.Parent then
		RemoteManager.FireClient(Constants.REMOTES.SYNC_MUTATIONS, player, playerMutations[player.UserId])
	end
end

function MutationService.OnPlayerRemoving(player: Player)
	playerMutations[player.UserId] = nil
end

function MutationService.ResetMutations(player: Player)
	playerMutations[player.UserId] = {}
	if player.Parent then
		RemoteManager.FireClient(Constants.REMOTES.SYNC_MUTATIONS, player, playerMutations[player.UserId])
	end
	print("[MutationService] 🔄 รีเซ็ต Mutation ของผู้เล่น " .. player.Name .. " (Prestige)")
end

function MutationService.BuyMutation(player: Player, mutationId: string)
	local muts = playerMutations[player.UserId]
	if not muts then return end

	-- 1. ตรวจสอบว่ามี Mutation นี้ในระบบหรือไม่
	local mutData = MutationTree.MUTATIONS[mutationId]
	if not mutData then
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "❌ ไม่พบข้อมูล Mutation นี้!", "Warning")
		return
	end

	-- 2. ตรวจสอบว่าเคยซื้อไปแล้วหรือยัง
	if muts[mutationId] then
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "❌ คุณปลดล็อก Mutation นี้ไปแล้ว!", "Warning")
		return
	end

	-- 3. ตรวจสอบเงื่อนไข (Prerequisite)
	if mutData.Req and not muts[mutData.Req] then
		local reqData = MutationTree.MUTATIONS[mutData.Req]
		local reqName = reqData and reqData.Name or mutData.Req
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "❌ ต้องปลดล็อก " .. reqName .. " ก่อน!", "Warning")
		return
	end

	-- 4. ตรวจสอบและหักแต้มสกุลเงิน
	local success = false
	if mutData.Currency == "DNA" then
		success = PlayerService.DeductDnaPoints(player, mutData.Cost)
	else
		success = PlayerService.DeductBioPoints(player, mutData.Cost)
	end

	if not success then
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "❌ แต้ม " .. mutData.Currency .. " ไม่พอ!", "Warning")
		return
	end

	-- 5. ทำการปลดล็อกสำเร็จ
	muts[mutationId] = true
	RemoteManager.FireClient(Constants.REMOTES.MUTATION_UNLOCKED, player, mutationId)
	RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "🧬 ปลดล็อก " .. mutData.Name .. " สำเร็จ!", "Success")
	RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "MUTATION UNLOCKED!", nil, "DNA")
end

-- ============================================================
-- HELPER METHODS สำหรับ SERVICE อื่นๆ (เช่น InfectionEngine)
-- ============================================================

function MutationService.HasMutation(player: Player, mutationId: string): boolean
	local muts = playerMutations[player.UserId]
	return muts and muts[mutationId] or false
end

function MutationService.GetSpreadRadius(player: Player): number
	local muts = playerMutations[player.UserId]
	if not muts then return Constants.INFECTION.BASE_SPREAD_RADIUS end

	local radius = Constants.INFECTION.BASE_SPREAD_RADIUS
	if muts.AIRBORNE_1 then radius += MutationTree.MUTATIONS.AIRBORNE_1.EffectValue end
	if muts.AIRBORNE_2 then radius += MutationTree.MUTATIONS.AIRBORNE_2.EffectValue end
	return radius
end

function MutationService.GetSpreadChance(player: Player): number
	local muts = playerMutations[player.UserId]
	if not muts then return Constants.INFECTION.BASE_SPREAD_CHANCE end

	local chance = Constants.INFECTION.BASE_SPREAD_CHANCE
	if muts.WATERBORNE_1 then chance += MutationTree.MUTATIONS.WATERBORNE_1.EffectValue end
	if muts.WATERBORNE_2 then chance += MutationTree.MUTATIONS.WATERBORNE_2.EffectValue end
	return chance
end

function MutationService.GetTickRate(player: Player): number
	local muts = playerMutations[player.UserId]
	if not muts then return Constants.INFECTION.TICK_RATE end

	local rate = Constants.INFECTION.TICK_RATE
	if muts.COUGHING then rate -= MutationTree.MUTATIONS.COUGHING.EffectValue end
	if muts.SNEEZING then rate -= MutationTree.MUTATIONS.SNEEZING.EffectValue end
	return math.max(0.2, rate) -- ไม่ให้ต่ำกว่า 0.2 วินาที
end

function MutationService.GetAnimalBioMultiplier(player: Player): number
	local muts = playerMutations[player.UserId]
	if muts and muts.ZOONOTIC then
		return MutationTree.MUTATIONS.ZOONOTIC.EffectValue
	end
	return 1
end

function MutationService.GetCriticalInfectChance(player: Player): number
	local muts = playerMutations[player.UserId]
	if muts and muts.CYTOKINE then
		return MutationTree.MUTATIONS.CYTOKINE.EffectValue
	end
	return 0
end

function MutationService.GetBossDPS(player: Player): number
	local muts = playerMutations[player.UserId]
	if not muts then return 0 end

	local dps = 0
	if muts.FEVER then dps += MutationTree.MUTATIONS.FEVER.EffectValue end
	if muts.LESIONS then dps += MutationTree.MUTATIONS.LESIONS.EffectValue end
	return dps
end

return MutationService
