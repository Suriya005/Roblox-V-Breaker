-- V-Breaker | MutationTree (Shared)
-- ReplicatedStorage/Shared/constants/MutationTree.lua
-- ข้อมูลสายต้นไม้กลายพันธุ์ (Mutation Tree) ทั้งหมด

local MutationTree = {}

MutationTree.CATEGORIES = {
	TRANSMISSION = "Transmission", -- การแพร่กระจาย
	SYMPTOMS     = "Symptoms",     -- อาการของโรค
	ABILITIES    = "Abilities",    -- ความสามารถและความต้านทาน
}

MutationTree.MUTATIONS = {
	-- ==========================================
	-- 1. TRANSMISSION (การแพร่กระจาย)
	-- ==========================================
	AIRBORNE_1 = {
		Id = "AIRBORNE_1",
		Name = "Airborne I",
		Category = MutationTree.CATEGORIES.TRANSMISSION,
		Cost = 5,
		Currency = "DNA",
		Desc = "เพิ่มรัศมีการแพร่กระจายเชื้อ +5 studs",
		EffectType = "SpreadRadius",
		EffectValue = 5,
		Req = nil, -- ไม่มีเงื่อนไข (เริ่มต้นซื้อได้เลย)
		Icon = "💨",
	},
	AIRBORNE_2 = {
		Id = "AIRBORNE_2",
		Name = "Airborne II",
		Category = MutationTree.CATEGORIES.TRANSMISSION,
		Cost = 15,
		Currency = "DNA",
		Desc = "เพิ่มรัศมีการแพร่กระจายเชื้อ +10 studs",
		EffectType = "SpreadRadius",
		EffectValue = 10,
		Req = "AIRBORNE_1",
		Icon = "🌪️",
	},
	WATERBORNE_1 = {
		Id = "WATERBORNE_1",
		Name = "Waterborne I",
		Category = MutationTree.CATEGORIES.TRANSMISSION,
		Cost = 10,
		Currency = "DNA",
		Desc = "เพิ่มโอกาสแพร่เชื้อสำเร็จ +15%",
		EffectType = "SpreadChance",
		EffectValue = 15,
		Req = nil,
		Icon = "💧",
	},
	WATERBORNE_2 = {
		Id = "WATERBORNE_2",
		Name = "Waterborne II",
		Category = MutationTree.CATEGORIES.TRANSMISSION,
		Cost = 25,
		Currency = "DNA",
		Desc = "เพิ่มโอกาสแพร่เชื้อสำเร็จ +25%",
		EffectType = "SpreadChance",
		EffectValue = 25,
		Req = "WATERBORNE_1",
		Icon = "🌊",
	},
	ZOONOTIC = {
		Id = "ZOONOTIC",
		Name = "Zoonotic Shift",
		Category = MutationTree.CATEGORIES.TRANSMISSION,
		Cost = 20,
		Currency = "DNA",
		Desc = "รับโบนัส Bio Points x2 เมื่อติดเชื้อสัตว์ (Tier 1)",
		EffectType = "BioMultiplier_Animal",
		EffectValue = 2,
		Req = "AIRBORNE_1",
		Icon = "🐾",
	},

	-- ==========================================
	-- 2. SYMPTOMS (อาการของโรค)
	-- ==========================================
	COUGHING = {
		Id = "COUGHING",
		Name = "Coughing",
		Category = MutationTree.CATEGORIES.SYMPTOMS,
		Cost = 10,
		Currency = "DNA",
		Desc = "ลดเวลา Tick Rate ลง 0.2 วินาที (เชื้อระบาดเร็วขึ้น)",
		EffectType = "TickRateReduction",
		EffectValue = 0.2,
		Req = nil,
		Icon = "🗣️",
	},
	SNEEZING = {
		Id = "SNEEZING",
		Name = "Sneezing",
		Category = MutationTree.CATEGORIES.SYMPTOMS,
		Cost = 30,
		Currency = "DNA",
		Desc = "ลดเวลา Tick Rate ลงอีก 0.3 วินาที (รวมเป็นลด 0.5s)",
		EffectType = "TickRateReduction",
		EffectValue = 0.3,
		Req = "COUGHING",
		Icon = "🤧",
	},
	FEVER = {
		Id = "FEVER",
		Name = "Fever",
		Category = MutationTree.CATEGORIES.SYMPTOMS,
		Cost = 15,
		Currency = "DNA",
		Desc = "เพิ่มความเสียหายต่อวินาที (DPS) +10 สำหรับทำลายบอส",
		EffectType = "BossDPS",
		EffectValue = 10,
		Req = nil,
		Icon = "🔥",
	},
	LESIONS = {
		Id = "LESIONS",
		Name = "Skin Lesions",
		Category = MutationTree.CATEGORIES.SYMPTOMS,
		Cost = 35,
		Currency = "DNA",
		Desc = "เพิ่มความเสียหายต่อวินาที (DPS) +25 สำหรับทำลายบอส",
		EffectType = "BossDPS",
		EffectValue = 25,
		Req = "FEVER",
		Icon = "💥",
	},
	CYTOKINE = {
		Id = "CYTOKINE",
		Name = "Cytokine Storm",
		Category = MutationTree.CATEGORIES.SYMPTOMS,
		Cost = 50,
		Currency = "DNA",
		Desc = "ปลดล็อกโอกาส 10% ติดเชื้อแบบคริติคอล (รับ Bio Points x5)",
		EffectType = "CriticalInfectChance",
		EffectValue = 10, -- 10% chance for x5 bio
		Req = "SNEEZING",
		Icon = "⚡",
	},

	-- ==========================================
	-- 3. ABILITIES / RESISTANCE (ความสามารถ/ต้านทาน)
	-- ==========================================
	DRUG_RESIST_1 = {
		Id = "DRUG_RESIST_1",
		Name = "Drug Resistance I",
		Category = MutationTree.CATEGORIES.ABILITIES,
		Cost = 15,
		Currency = "DNA",
		Desc = "ลดผลกระทบจาก Vaccine ของรัฐบาลลง 20%",
		EffectType = "VaccineResistance",
		EffectValue = 20,
		Req = nil,
		Icon = "💊",
	},
	GENETIC_HARD = {
		Id = "GENETIC_HARD",
		Name = "Genetic Hardening",
		Category = MutationTree.CATEGORIES.ABILITIES,
		Cost = 30,
		Currency = "DNA",
		Desc = "เพิ่มเวลาที่รัฐบาลใช้ในการวิจัยวัคซีน +30%",
		EffectType = "ResearchSlowdown",
		EffectValue = 30,
		Req = "DRUG_RESIST_1",
		Icon = "🛡️",
	},
	VCORRUPTOR = {
		Id = "VCORRUPTOR",
		Name = "V-Corruptor",
		Category = MutationTree.CATEGORIES.ABILITIES,
		Cost = 75,
		Currency = "DNA",
		Desc = "เจาะเกราะป้องกันของ Supe และ Boss ได้ 50%",
		EffectType = "SupeArmorPenetration",
		EffectValue = 50,
		Req = "GENETIC_HARD",
		Icon = "💉",
	},
}

return MutationTree
