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

	print("[PlayerService] ✅ พร้อมใช้งาน!")
end

function PlayerService.OnPlayerAdded(player: Player)
	playerData[player.UserId] = {
		BioPoints = 0,
		DnaPoints = 0,
		TotalBioEarned = 0, -- ใช้คำนวณ DNA Points
		LastInfectTime = 0, -- คูลดาวน์ปล่อยไวรัส
	}
	
	-- ส่งค่าเริ่มต้นให้ Client
	task.wait(1)
	if player.Parent then
		RemoteManager.FireClient(Constants.REMOTES.BIO_POINTS_CHANGED, player, 0)
		RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, 0)
	end
end

function PlayerService.OnPlayerRemoving(player: Player)
	playerData[player.UserId] = nil
end

function PlayerService.GetData(player: Player)
	return playerData[player.UserId]
end

function PlayerService.AddBioPoints(player: Player, amount: number)
	local data = playerData[player.UserId]
	if not data then return end

	data.BioPoints += amount
	data.TotalBioEarned += amount

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
end

function PlayerService.AddDnaPoints(player: Player, amount: number)
	local data = playerData[player.UserId]
	if not data then return end

	data.DnaPoints += amount
	RemoteManager.FireClient(Constants.REMOTES.DNA_POINTS_CHANGED, player, data.DnaPoints)
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

return PlayerService
