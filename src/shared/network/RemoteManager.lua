-- SurvivalRoleRoulette | RemoteManager (Shared)
-- ReplicatedStorage/Shared/RemoteManager.lua
-- จัดการสร้างและเข้าถึง RemoteEvents/RemoteFunctions แบบรวมศูนย์

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(script.Parent.Parent:WaitForChild("constants"):WaitForChild("Constants"))

local RemoteManager = {}

-- โฟลเดอร์เก็บ Remotes ทั้งหมดใน ReplicatedStorage
local remotesFolder: Folder

-- ============================================================
local remotesFolder: Folder? = nil

-- INIT: สร้างโฟลเดอร์และ RemoteEvents (เรียกจาก Server เท่านั้น)
-- ============================================================
function RemoteManager.Init()
	assert(RunService:IsServer(), "[RemoteManager] Init() ต้องเรียกจาก Server เท่านั้น!")
	print("[RemoteManager] 🚀 เริ่มต้นสร้าง RemoteEvents...")

	-- สร้างโฟลเดอร์ RemoteEvents ถ้ายังไม่มี
	remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "RemoteEvents"
		remotesFolder.Parent = ReplicatedStorage
		print("[RemoteManager] 📁 สร้างโฟลเดอร์ RemoteEvents ใหม่")
	end

	-- สร้าง RemoteEvent ทุกตัวตาม Constants.REMOTES
	local count = 0
	for _, remoteName in pairs(Constants.REMOTES) do
		if not remotesFolder:FindFirstChild(remoteName) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = remoteName
			remote.Parent = remotesFolder
			print("[RemoteManager] ✨ สร้าง RemoteEvent:", remoteName)
			count += 1
		end
	end

	print("[RemoteManager] ✅ สร้างเสร็จสิ้น!", count, "Events ใหม่ | รวมทั้งหมด:", #remotesFolder:GetChildren())
end

-- ============================================================
-- GET: เรียก RemoteEvent ตามชื่อ (ทั้ง Server และ Client ใช้ได้)
-- ============================================================
function RemoteManager.Get(remoteName: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	assert(folder, "[RemoteManager] ไม่พบโฟลเดอร์ RemoteEvents!")

	local remote = folder:WaitForChild(remoteName, 10)
	assert(remote, "[RemoteManager] ไม่พบ RemoteEvent: " .. remoteName)

	return remote
end

-- ============================================================
-- FIRE TO CLIENT (Server → Client)
-- ============================================================
function RemoteManager.FireClient(remoteName: string, player: Player, ...)
	local remote = RemoteManager.Get(remoteName)
	remote:FireClient(player, ...)
end

function RemoteManager.FireAllClients(remoteName: string, ...)
	local remote = RemoteManager.Get(remoteName)
	remote:FireAllClients(...)
end

-- ============================================================
-- FIRE TO SERVER (Client → Server)
-- ============================================================
function RemoteManager.FireServer(remoteName: string, ...)
	local remote = RemoteManager.Get(remoteName)
	remote:FireServer(...)
end

-- ============================================================
-- CONNECT (ผูก Handler)
-- ============================================================
function RemoteManager.OnServerEvent(remoteName: string, callback)
	local remote = RemoteManager.Get(remoteName)
	return remote.OnServerEvent:Connect(callback)
end

function RemoteManager.OnClientEvent(remoteName: string, callback)
	local remote = RemoteManager.Get(remoteName)
	return remote.OnClientEvent:Connect(callback)
end

return RemoteManager
