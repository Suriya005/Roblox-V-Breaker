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
	RAT = { Name = "Rat", Speed = 18, Immune = 5, BioPoints = 1, SpawnWeight = 60, Color = Color3.fromRGB(120, 120, 120), Size = Vector3.new(2, 1.2, 3), CanFly = false },
	PIG = { Name = "Pig", Speed = 12, Immune = 15, BioPoints = 3, SpawnWeight = 25, Color = Color3.fromRGB(255, 180, 200), Size = Vector3.new(3, 2.5, 4), CanFly = false },
	MONKEY = { Name = "Monkey", Speed = 20, Immune = 12, BioPoints = 2, SpawnWeight = 15, Color = Color3.fromRGB(139, 69, 19), Size = Vector3.new(2.5, 3, 2.5), CanFly = false },
}

-- ============================================================
-- TIER 2 HUMAN TYPES & AI CONFIG
-- ============================================================
Constants.HUMANS = {
	CITIZEN = { Name = "Citizen", Speed = 16, Immune = 30, BioPoints = 5, SpawnWeight = 60, Color = Color3.fromRGB(200, 150, 100), Size = Vector3.new(3, 5, 3), CanFly = false },
	SCIENTIST = { Name = "Scientist", Speed = 14, Immune = 50, BioPoints = 8, SpawnWeight = 25, Color = Color3.fromRGB(240, 240, 240), Size = Vector3.new(3, 5, 3), CanFly = false },
	POLICE = { Name = "Police", Speed = 18, Immune = 75, BioPoints = 10, SpawnWeight = 15, Color = Color3.fromRGB(50, 50, 200), Size = Vector3.new(3.5, 5.5, 3.5), CanFly = false },
}

-- ============================================================
-- TIER 4 BOSS TYPES & ABILITIES CONFIG
-- ============================================================
Constants.BOSSES = {
	THUNDERCLAP = { Name = "Thunderclap", Zone = "Forest", Speed = 14, Immune = 100, Health = 1000, BioPoints = 100, DnaPoints = 10, Color = Color3.fromRGB(255, 255, 0), Size = Vector3.new(5, 8, 5), Emoji = "⚡", Ability = "LightningStrike" },
	INFERNO     = { Name = "Inferno",     Zone = "City",   Speed = 16, Immune = 250, Health = 2500, BioPoints = 250, DnaPoints = 25, Color = Color3.fromRGB(255, 100, 0), Size = Vector3.new(6, 9, 6), Emoji = "🔥", Ability = "Firestorm" },
	VORTEX      = { Name = "Vortex",      Zone = "Military",Speed= 18, Immune = 500, Health = 5000, BioPoints = 500, DnaPoints = 50, Color = Color3.fromRGB(100, 100, 255), Size = Vector3.new(7, 10, 7), Emoji = "🌪️", Ability = "WindGust" },
	SUPREME     = { Name = "SUPREME",     Zone = "Vought", Speed = 20, Immune = 1000,Health = 10000,BioPoints = 2000,DnaPoints = 200, Color = Color3.fromRGB(255, 0, 0), Size = Vector3.new(8, 12, 8), Emoji = "🦸‍♂️", Ability = "LaserEyes" },
}

-- ============================================================
-- TIER 3 MILITARY & SUPES TYPES & AI CONFIG
-- ============================================================
Constants.MILITARY = {
	SOLDIER = { Name = "Soldier", Speed = 16, Immune = 120, BioPoints = 25, SpawnWeight = 70, Color = Color3.fromRGB(85, 107, 47), Size = Vector3.new(3.5, 5.5, 3.5), CanFly = false },
	TANK    = { Name = "Tank",    Speed = 10, Immune = 250, BioPoints = 60, SpawnWeight = 30, Color = Color3.fromRGB(50, 60, 30), Size = Vector3.new(8, 7, 10), CanFly = false },
}

Constants.SUPES = {
	ELITE   = { Name = "Elite",   Speed = 22, Immune = 400, BioPoints = 120, SpawnWeight = 70, Color = Color3.fromRGB(180, 20, 20), Size = Vector3.new(4, 6, 4), CanFly = true },
	HERO    = { Name = "Hero",    Speed = 28, Immune = 750, BioPoints = 300, SpawnWeight = 30, Color = Color3.fromRGB(218, 165, 32), Size = Vector3.new(4.5, 6.5, 4.5), CanFly = true },
}

-- ============================================================
-- REMOTE EVENTS NAMES (ชื่อ RemoteEvent ทั้งหมด)
-- ============================================================
Constants.REMOTES = {
	-- Client → Server
	REQUEST_INFECT     = "RequestInfect",     -- ผู้เล่นกดคลิกปล่อยไวรัสใส่ NPC
	BUY_MUTATION       = "BuyMutation",       -- ผู้เล่นกดซื้ออัปเกรด Mutation
	
	-- Server → Client
	INFECTION_SPREAD   = "InfectionSpread",   -- แจ้ง Client ว่ามี NPC ติดเชื้อ (เพื่อเล่น Particle/Sound)
	BIO_POINTS_CHANGED = "BioPointsChanged",  -- อัปเดต Bio Points ของผู้เล่น
	DNA_POINTS_CHANGED = "DnaPointsChanged",  -- อัปเดต DNA Points ของผู้เล่น
	SHOW_POPUP         = "ShowPopup",         -- แสดง Pop-up ตัวเลขกลางจอ (เช่น +1 Bio, Combo x5)
	NOTIFICATION       = "Notification",      -- แสดงข้อความแจ้งเตือนระบบ
	MUTATION_UNLOCKED  = "MutationUnlocked",  -- แจ้ง Client ว่าปลดล็อก Mutation สำเร็จ
	SYNC_MUTATIONS     = "SyncMutations",     -- ส่งข้อมูล Mutation ทั้งหมดที่ผู้เล่นมีตอนเข้าเกม
	THREAT_LEVEL_CHANGED = "ThreatLevelChanged", -- อัปเดต Threat Level ของรัฐบาล
	VACCINE_PROGRESS_CHANGED = "VaccineProgressChanged", -- อัปเดต % การวิจัยวัคซีน
	VACCINE_DEPLOYED   = "VaccineDeployed",   -- แจ้งเตือนเมื่อวัคซีนถูกปล่อย
	BOSS_SPAWNED       = "BossSpawned",       -- แจ้ง Client ว่าบอสเกิด (เพื่อโชว์ Boss Health Bar)
	BOSS_HEALTH_CHANGED= "BossHealthChanged", -- อัปเดตเลือดบอสบน UI
	BOSS_DEFEATED      = "BossDefeated",      -- แจ้งเตือนเมื่อบอสถูกกำจัด
	ZONE_UNLOCKED      = "ZoneUnlocked",      -- แจ้ง Client ว่าปลดล็อกโซนใหม่สำเร็จ
	REQUEST_PRESTIGE   = "RequestPrestige",   -- Client กดปุ่มยืนยันการจุติ
	PRESTIGE_CHANGED   = "PrestigeChanged",   -- Server ส่งสถานะจุติใหม่ให้ Client
}

-- ============================================================
-- PRESTIGE SETTINGS
-- ============================================================
Constants.PRESTIGE = {
	REQ_DNA            = 5000,   -- ใช้ DNA Points ในการจุติ
	BASE_MULTIPLIER_ADD= 0.5,    -- เพิ่ม Multiplier +0.5x ต่อระดับจุติ
	BASE_TOKENS_REWARD = 1,      -- ได้รับ Plague Tokens +1 ต่อระดับจุติ
}

return Constants
