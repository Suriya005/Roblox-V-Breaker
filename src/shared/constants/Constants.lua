-- SurvivalRoleRoulette | Constants (Shared)
-- ReplicatedStorage/Shared/Constants.lua
-- ค่าคงที่ทั้งหมดของเกม ทั้ง Server และ Client ใช้ร่วมกัน

local Constants = {}

-- ============================================================
-- GAME SETTINGS
-- ============================================================
Constants.GAME = {
	MIN_PLAYERS       = 2,      -- จำนวนผู้เล่นขั้นต่ำเพื่อเริ่มเกม
	INTERMISSION_TIME = 20,     -- วินาทีรอใน Lobby ก่อนเริ่ม
	ROUND_TIME        = 600,    -- วินาทีในด่าน (10 นาที)
	TELEPORT_DELAY    = 3,      -- วินาทีรอก่อน Teleport เข้าด่าน
}

-- ============================================================
-- ROLES
-- ============================================================
Constants.ROLES = {
	INNOCENT = "Innocent",
	POLICE   = "Police",
	KILLER   = "Killer",
}

-- ============================================================
-- GAME STATES (สถานะของ State Machine)
-- ============================================================
Constants.STATES = {
	WAITING      = "Waiting",
	INTERMISSION = "Intermission",
	TELEPORT     = "Teleport",
	IN_GAME      = "InGame",
	END_GAME     = "EndGame",
}

-- ============================================================
-- REMOTE EVENTS NAMES (ชื่อ RemoteEvent ทั้งหมด)
-- ============================================================
Constants.REMOTES = {
	ASSIGN_ROLE        = "AssignRole",
	GAME_STATE_CHANGED = "GameStateChanged",
	TIMER_UPDATE       = "TimerUpdate",
	ROUND_RESULT       = "RoundResult",
	SHOW_NOTIFICATION  = "ShowNotification",
	PLAYER_DIED        = "PlayerDied",
	GUN_DROPPED        = "GunDropped",
	-- Weapon Actions (Client → Server)
	KNIFE_HIT          = "KnifeHit",    -- Client บอก Server ว่ากดใช้มีด
	GUN_SHOOT          = "GunShoot",    -- Client บอก Server ทิศยิง
	PICKUP_GUN         = "PickupGun",   -- Client เก็บปืนที่ดรอป
}

-- ============================================================
-- WIN CONDITIONS
-- ============================================================
Constants.WIN = {
	KILLER_WIN    = "KillerWin",
	INNOCENT_WIN  = "InnocentWin",
	TIME_UP       = "TimeUp",
}

-- ============================================================
-- WEAPONS
-- ============================================================
Constants.WEAPONS = {
	KNIFE_DAMAGE = 100, -- ดาเมจขวาน/มีดของ Killer (one-shot kill)
	GUN_DAMAGE   = 100, -- ดาเมจปืน Police (one-shot kill)
	GUN_RANGE    = 300, -- ระยะยิงปืน (studs)
}

return Constants
