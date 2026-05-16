-- V-Breaker | PlayerService (Server)
-- ServerScriptService/Server/services/PlayerService.lua
-- จัดการข้อมูลผู้เล่น (Bio Points, DNA Points) เบื้องต้น (Prototype Phase)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))

local PlayerService = {}
local playerData = {}

-- Threshold สำหรับแปลง Bio Points เป็น DNA Points
local BIO_TO_DNA_THRESHOLD = 50
local DNA_REWARD_AMOUNT = 5

function PlayerService.Init()
	print("[PlayerService] 🚀 เริ่มต้นระบบจัดการข้อมูลผู้เล่น...")

	Players.PlayerAdded:Connect(function(player)
		PlayerService.OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerService.OnPlayerRemoving(player)
	end)

	-- สำหรับผู้เล่นที่อยู่ในเกมอยู่แล้วตอนสคริปต์รัน
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerService.OnPlayerAdded(player)
	end

	RemoteManager.OnServerEvent(Constants.REMOTES.REQUEST_PRESTIGE, function(player)
		PlayerService.Prestige(player)
	end)

	print("[PlayerService] ✅ พร้อมใช้งาน!")
end

function PlayerService.OnPlayerAdded(player: Player)
	playerData[player.UserId] = {
		BioPoints = 500, -- ให้แต้มเริ่มต้น 500 แต้มสำหรับเทส
		DnaPoints = 500, -- ให้แต้มเริ่มต้น 500 แต้มสำหรับเทส
		TotalBioEarned = 0, -- ใช้คำนวณ DNA Points
		LifetimeBioEarned = 0, -- ใช้คำนวณปลดล็อกโซนแผนที่ (Map Progression)
		LastInfectTime = 0, -- คูลดาวน์ปล่อยไวรัส
		UnlockedZones = { Forest = true, City = false, Military = false, Vought = false },
		PrestigeLevel = 0,
		PrestigeMultiplier = 1.0,
		PlagueTokens = 0,
	}
	
	-- ส่งค่าเริ่มต้นให้ Client
	task.wait(1)
	if player.Parent then
		RemoteManager.FireClient(Constants.REMOTES.BIO_POINTS_CHANGED, player, 500)
		RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, 500)
		RemoteManager.FireClient(Constants.REMOTES.PRESTIGE_CHANGED, player, 0, 1.0, 0)
	end
end

function PlayerService.OnPlayerRemoving(player: Player)
	playerData[player.UserId] = nil
end

function PlayerService.GetData(player: Player)
	return playerData[player.UserId]
end

function PlayerService.IsZoneUnlocked(zoneName: string): boolean
	if zoneName == "Forest" then return true end
	for _, data in pairs(playerData) do
		if data.UnlockedZones and data.UnlockedZones[zoneName] then
			return true
		end
	end
	return false
end

function PlayerService.AddBioPoints(player: Player, amount: number)
	local data = playerData[player.UserId]
	if not data then return end

	-- คำนวณ Multiplier จาก Prestige
	local finalAmount = math.floor(amount * (data.PrestigeMultiplier or 1.0))
	data.BioPoints += finalAmount
	data.TotalBioEarned += finalAmount
	data.LifetimeBioEarned = (data.LifetimeBioEarned or 0) + finalAmount

	RemoteManager.FireClient(Constants.REMOTES.BIO_POINTS_CHANGED, player, data.BioPoints)

	-- ตรวจสอบเงื่อนไขได้รับ DNA Points
	if data.TotalBioEarned >= BIO_TO_DNA_THRESHOLD then
		local multiples = math.floor(data.TotalBioEarned / BIO_TO_DNA_THRESHOLD)
		data.TotalBioEarned = data.TotalBioEarned % BIO_TO_DNA_THRESHOLD
		
		local dnaReward = multiples * DNA_REWARD_AMOUNT
		PlayerService.AddDnaPoints(player, dnaReward)
		
		-- แจ้งเตือนได้รับ DNA
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "+" .. dnaReward .. " DNA!", nil, "DNA")
	end

	-- ตรวจสอบปลดล็อกโซนแผนที่ (Map Progression)
	if data.LifetimeBioEarned >= 1000 and not data.UnlockedZones.City then
		data.UnlockedZones.City = true
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "🏙️ ปลดล็อกโซนใหม่: CITY ZONE!", "Warning")
		RemoteManager.FireClient(Constants.REMOTES.ZONE_UNLOCKED, player, "City")
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🏙️ CITY ZONE UNLOCKED!", nil, "DNA")
	end

	if data.LifetimeBioEarned >= 5000 and not data.UnlockedZones.Military then
		data.UnlockedZones.Military = true
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "🪖 ปลดล็อกโซนใหม่: MILITARY BASE!", "Warning")
		RemoteManager.FireClient(Constants.REMOTES.ZONE_UNLOCKED, player, "Military")
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🪖 MILITARY BASE UNLOCKED!", nil, "DNA")
	end

	if data.LifetimeBioEarned >= 20000 and not data.UnlockedZones.Vought then
		data.UnlockedZones.Vought = true
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "🦸‍♂️ ปลดล็อกโซนใหม่: VOUGHT HQ!", "Warning")
		RemoteManager.FireClient(Constants.REMOTES.ZONE_UNLOCKED, player, "Vought")
		RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🦸‍♂️ VOUGHT HQ UNLOCKED!", nil, "DNA")
	end
end

function PlayerService.AddDnaPoints(player: Player, amount: number)
	local data = playerData[player.UserId]
	if not data then return end

	data.DnaPoints += amount
	RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, data.DnaPoints)
end

function PlayerService.DeductDnaPoints(player: Player, amount: number): boolean
	local data = playerData[player.UserId]
	if not data or data.DnaPoints < amount then return false end

	data.DnaPoints -= amount
	RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, data.DnaPoints)
	return true
end

function PlayerService.DeductBioPoints(player: Player, amount: number): boolean
	local data = playerData[player.UserId]
	if not data or data.BioPoints < amount then return false end

	data.BioPoints -= amount
	RemoteManager.FireClient(Constants.REMOTES.BIO_POINTS_CHANGED, player, data.BioPoints)
	return true
end

function PlayerService.CanInfect(player: Player): boolean
	local data = playerData[player.UserId]
	if not data then return false end

	local now = os.clock()
	if now - data.LastInfectTime >= Constants.INFECTION.DEFAULT_COOLDOWN then
		data.LastInfectTime = now
		return true
	end
	return false
end

function PlayerService.Prestige(player: Player)
	local data = playerData[player.UserId]
	if not data then return end

	local reqDna = Constants.PRESTIGE.REQ_DNA
	if data.DnaPoints < reqDna then
		RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "❌ แต้ม DNA ไม่พอสำหรับการจุติ! (ต้องการ " .. reqDna .. " DNA)", "Warning")
		return
	end

	-- หักแต้มและรีเซ็ตความคืบหน้า
	data.BioPoints = 0
	data.DnaPoints = 0
	data.TotalBioEarned = 0
	data.LifetimeBioEarned = 0
	data.UnlockedZones = { Forest = true, City = false, Military = false, Vought = false }

	-- เพิ่มระดับจุติ, Multiplier และ Plague Tokens
	data.PrestigeLevel = (data.PrestigeLevel or 0) + 1
	data.PrestigeMultiplier = 1.0 + (data.PrestigeLevel * Constants.PRESTIGE.BASE_MULTIPLIER_ADD)
	data.PlagueTokens = (data.PlagueTokens or 0) + Constants.PRESTIGE.BASE_TOKENS_REWARD

	-- รีเซ็ต Mutation (ถ้ามี MutationService)
	local MutationService = require(script.Parent:WaitForChild("MutationService"))
	if MutationService.ResetMutations then
		MutationService.ResetMutations(player)
	end

	-- อัปเดต Client
	RemoteManager.FireClient(Constants.REMOTES.BIO_POINTS_CHANGED, player, data.BioPoints)
	RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, data.DnaPoints)
	RemoteManager.FireClient(Constants.REMOTES.PRESTIGE_CHANGED, player, data.PrestigeLevel, data.PrestigeMultiplier, data.PlagueTokens)
	RemoteManager.FireClient(Constants.REMOTES.NOTIFICATION, player, "🔮 จุติสำเร็จ! ขึ้นสู่ระดับ " .. data.PrestigeLevel .. " (Multiplier " .. data.PrestigeMultiplier .. "x)", "Success")
	RemoteManager.FireClient(Constants.REMOTES.SHOW_POPUP, player, "🔮 PRESTIGE " .. data.PrestigeLevel .. "!", nil, "DNA")

	print("[PlayerService] 🔮 ผู้เล่น " .. player.Name .. " ทำการจุติเป็นระดับ " .. data.PrestigeLevel)
end

return PlayerService
