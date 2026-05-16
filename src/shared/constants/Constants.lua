-- V-Breaker | Constants (Shared)
-- ReplicatedStorage/Shared/constants/Constants.lua
-- ค่าคงที่ทั้งหมดของเกม V-Breaker ทั้ง Server และ Client ใช้ร่วมกัน

local Constants = {}

-- ============================================================
-- GAME / INFECTION SETTINGS
-- ============================================================
Constants.INFECTION = {
	BASE_SPREAD_RADIUS = 15,     -- ระยะแพร่กระจายเชื้อเริ่มต้น (studs)
	BASE_SPREAD_CHANCE = 30,     -- โอกาสแพร่เชื้อเริ่มต้น (30%)
	TICK_RATE          = 1,      -- ความถี่ในการคำนวณแพร่เชื้อ (วินาที)
	DEFAULT_COOLDOWN   = 2,      -- คูลดาวน์การกดปล่อยไวรัสของเล่น (วินาที)
}

-- ============================================================
-- NPC TIERS & STATS
-- ============================================================
Constants.TIERS = {
	[1] = { Name = "Animal", ImmuneStrength = 10,  BioPoints = 1 },
	[2] = { Name = "Human",  ImmuneStrength = 50,  BioPoints = 5 },
	[3] = { Name = "Supe",   ImmuneStrength = 200, BioPoints = 50 },
	[4] = { Name = "Boss",   ImmuneStrength = 1000, BioPoints = 500 },
}

-- ============================================================
-- TIER 1 ANIMAL TYPES & AI CONFIG
-- ============================================================
Constants.ANIMALS = {
	RAT = { Name = "Rat", Speed = 18, Immune = 5, BioPoints = 1, SpawnWeight = 50, Color = Color3.fromRGB(120, 120, 120), Size = Vector3.new(2, 1.2, 3), CanFly = false },
	BIRD = { Name = "Bird", Speed = 22, Immune = 8, BioPoints = 2, SpawnWeight = 25, Color = Color3.fromRGB(100, 180, 240), Size = Vector3.new(2, 1, 2), CanFly = true },
	PIG = { Name = "Pig", Speed = 12, Immune = 15, BioPoints = 3, SpawnWeight = 15, Color = Color3.fromRGB(255, 180, 200), Size = Vector3.new(3, 2.5, 4), CanFly = false },
	MONKEY = { Name = "Monkey", Speed = 20, Immune = 12, BioPoints = 2, SpawnWeight = 10, Color = Color3.fromRGB(139, 69, 19), Size = Vector3.new(2.5, 3, 2.5), CanFly = false },
}

-- ============================================================
-- REMOTE EVENTS NAMES (ชื่อ RemoteEvent ทั้งหมด)
-- ============================================================
Constants.REMOTES = {
	-- Client → Server
	REQUEST_INFECT     = "RequestInfect",     -- ผู้เล่นกดคลิกปล่อยไวรัสใส่ NPC
	
	-- Server → Client
	INFECTION_SPREAD   = "InfectionSpread",   -- แจ้ง Client ว่ามี NPC ติดเชื้อ (เพื่อเล่น Particle/Sound)
	BIO_POINTS_CHANGED = "BioPointsChanged",  -- อัปเดต Bio Points ของผู้เล่น
	DNA_POINTS_CHANGED = "DnaPointsChanged",  -- อัปเดต DNA Points ของผู้เล่น
	SHOW_POPUP         = "ShowPopup",         -- แสดง Pop-up ตัวเลขกลางจอ (เช่น +1 Bio, Combo x5)
	NOTIFICATION       = "Notification",      -- แสดงข้อความแจ้งเตือนระบบ
}

return Constants
