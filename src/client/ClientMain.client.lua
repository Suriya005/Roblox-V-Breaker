-- V-Breaker | ClientMain (Entry Point)
-- StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua
-- เอกสาร/สคริปต์หลักสำหรับควบคุมระบบฝั่งไคลเอนต์ (Client Entry Point)

print("[ClientMain] 🚀 เริ่มต้นระบบ Client V-Breaker...")

-- ==============================================================================
-- 1. SERVICES (การดึงบริการต่างๆ ของ Roblox มาใช้งาน)
-- ==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

-- ==============================================================================
-- 2. MODULES & CONSTANTS (การนำเข้าโมดูลและค่าคงที่ของระบบ)
-- ==============================================================================
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local MainHUD = require(script.Parent:WaitForChild("ui"):WaitForChild("MainHUD"))
local MutationShop = require(script.Parent:WaitForChild("ui"):WaitForChild("MutationShop"))
local SettingsPanel = require(script.Parent:WaitForChild("ui"):WaitForChild("SettingsPanel"))

-- ==============================================================================
-- 3. STATE VARIABLES (ตัวแปรควบคุมสถานะของตัวผู้เล่นในฝั่ง Client)
-- ==============================================================================
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character
local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")

-- ตัวแปรสถานะระบบต่อยและการทำคอมโบ (Combat & Combo States)
local comboCount = 0
local lastComboTime = 0
local isPunching = false
local HITBOX_RADIUS = 4.5 -- รัศมีระยะต่อยโดน (studs)
local currentPunchTrack = nil
local lastPunchTime = 0

-- ตัวแปรสถานะการเคลื่อนที่ (Movement States)
local DEFAULT_WALK_SPEED = 16
local SPRINT_WALK_SPEED = 26
local isSprinting = false
local lastDashTime = 0
local DASH_COOLDOWN = 1.5 -- คูลดาวน์การแดชพุ่งวาร์ป (วินาที)

-- ตัวแปรสถานะการสู้บอสประจำโซน (Boss Battle States)
local activeBossModel = nil
local activeBossData = nil
local isBossBarVisible = false

-- ==============================================================================
-- 4. CHARACTER INITIALIZATION (ระบบจัดการตอนตัวละครโหลด/เกิดใหม่)
-- ==============================================================================

-- ฟังก์ชันดึงอนิเมชันท่าต่อย R15
local function loadPunchAnimation(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		local animator = hum:WaitForChild("Animator", 5) or hum
		local animFolder = ReplicatedStorage:WaitForChild("SharedAnimations", 5)
		if animFolder then
			local combatFolder = animFolder:WaitForChild("Combat", 5)
			if combatFolder then
				local punchSeq = combatFolder:WaitForChild("R15PunchSeq", 5)
				if punchSeq and punchSeq:IsA("KeyframeSequence") then
					local success, hashId = pcall(function()
						return KeyframeSequenceProvider:RegisterKeyframeSequence(punchSeq)
					end)
					
					if success and hashId then
						local anim = Instance.new("Animation")
						anim.AnimationId = hashId
						currentPunchTrack = animator:LoadAnimation(anim)
						currentPunchTrack.Priority = Enum.AnimationPriority.Action4 -- กำหนด Priority สูงสุดเพื่อเอาชนะท่าเดิน
					end
				end
			end
		end
	end
end

-- ฟังก์ชันติดตั้งละอองไอพิษสปอร์รอบตัวผู้เล่น (Ambient Spores)
local function setupAmbientSpores(char)
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if root then
		-- ตรวจสอบและลบของเก่าหากติดตัวมา
		local oldPE = root:FindFirstChild("AmbientToxicSpores")
		if oldPE then oldPE:Destroy() end

		local pe = Instance.new("ParticleEmitter")
		pe.Name = "AmbientToxicSpores"
		pe.Texture = "rbxassetid://243660364" -- รูปภาพสปอร์เรืองแสง
		pe.Color = ColorSequence.new(Color3.fromRGB(50, 255, 50))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 1.2), NumberSequenceKeypoint.new(1, 0)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1)})
		pe.Rate = 15
		pe.Speed = NumberRange.new(1, 3)
		pe.Lifetime = NumberRange.new(5, 8)
		pe.SpreadAngle = Vector2.new(360, 360)
		pe.Enabled = SettingsPanel.GetSetting("Particles") -- เช็คการเปิด/ปิดพาร์ทิเคิลจากแผงควบคุม
		pe.Parent = root
	end
end

-- ฟังก์ชันอัปเดตความเร็วเดิน/วิ่ง
local function updateWalkSpeed()
	if humanoid then
		humanoid.WalkSpeed = isSprinting and SPRINT_WALK_SPEED or DEFAULT_WALK_SPEED
	end
end

-- ฟังก์ชันจัดการทุกอย่างเมื่อตัวละครเข้าเกมหรือสปอว์นใหม่ (Centralized Character Setup)
local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	
	-- 1. รีเซ็ตสถานะวิ่งเร็วกลับมาปกติ
	isSprinting = false
	updateWalkSpeed()
	
	-- 2. โหลดอนิเมชันสำหรับออกหมัดต่อย
	currentPunchTrack = nil
	loadPunchAnimation(char)
	
	-- 3. สปอว์นพาร์ทิเคิลละอองพิษรอบตัว
	setupAmbientSpores(char)
end

-- เรียกใช้สำหรับครั้งแรกที่ตัวละครเข้าเกม
if player.Character then
	task.spawn(onCharacterAdded, player.Character)
end
-- ผูก Event ตรวจจับตัวละครเกิดใหม่ในครั้งถัดไป
player.CharacterAdded:Connect(onCharacterAdded)

-- ==============================================================================
-- 5. INITIALIZE UI (การเริ่มต้นสร้าง UI ต่างๆ ขึ้นหน้าจอ)
-- ==============================================================================
MainHUD.Init()
MutationShop.Init()
SettingsPanel.Init()

-- ==============================================================================
-- 6. NETWORK COMMUNICATIONS (การดักรับเหตุการณ์ต่างๆ จากฝั่ง Server)
-- ==============================================================================

-- ตรวจรับข้อมูลอัปเดตแต้ม Bio Points
RemoteManager.OnClientEvent(Constants.REMOTES.BIO_POINTS_CHANGED, function(newBio)
	MainHUD.UpdateBio(newBio)
end)

-- ตรวจรับข้อมูลอัปเดตแต้ม DNA Points
RemoteManager.OnClientEvent(Constants.REMOTES.DNA_POINTS_CHANGED, function(newDna)
	MainHUD.UpdateDna(newDna)
end)

-- ตรวจรับข้อความแจ้งเตือนสำคัญของเซิร์ฟเวอร์
RemoteManager.OnClientEvent(Constants.REMOTES.NOTIFICATION, function(message, notifType)
	MainHUD.ShowNotification(message, notifType)
end)

-- ตรวจรับคำสั่งสปอว์นป๊อปอัปดาเมจหรือข้อมูลสำคัญ (เช่น ดาเมจ หรือ DNA ที่ได้รับ)
RemoteManager.OnClientEvent(Constants.REMOTES.SHOW_POPUP, function(text, pos, popupType)
	MainHUD.ShowPopup(text, pos, popupType)
end)

-- รับข้อมูลการเปิดใช้งาน Mutation ที่เคยซื้อไปแล้วมาซิงค์กับฝั่ง Client
RemoteManager.OnClientEvent(Constants.REMOTES.SYNC_MUTATIONS, function(mutationsTable)
	MutationShop.OnSyncMutations(mutationsTable)
end)

-- รับสัญญาณแจ้งเตือนว่าผู้เล่นทำการปลดล็อก Mutation ใหม่สำเร็จ
RemoteManager.OnClientEvent(Constants.REMOTES.MUTATION_UNLOCKED, function(mutationId)
	MutationShop.OnMutationUnlocked(mutationId)
end)

-- ตรวจรับสัญญาณเมื่อการแพร่กระจายไวรัสเกิดขึ้น (Infection Event) เพื่อเล่นเอฟเฟกต์ Game Feel
RemoteManager.OnClientEvent(Constants.REMOTES.INFECTION_SPREAD, function(targetModel, infectedByUserId)
	if not targetModel then return end

	-- 1. ระบบนับ Combo (ดักนับถ้าติดเชื้อต่อเนื่องห่างกันไม่เกิน 4 วินาที)
	local now = os.clock()
	if now - lastComboTime <= 4.0 then
		comboCount += 1
	else
		comboCount = 1
	end
	lastComboTime = now

	if comboCount >= 2 then
		MainHUD.ShowCombo(comboCount)
	end

	-- 2. ระบบหยุดอนิเมชันชั่วคราว (Hit Freeze 60ms) เพื่อเพิ่มแรงปะทะทางใจ
	if player.Character then
		local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			local animator = hum:FindFirstChildWhichIsA("Animator") or hum
			local tracks = animator:GetPlayingAnimationTracks()
			for _, track in ipairs(tracks) do
				track:AdjustSpeed(0) -- หยุดความเร็วอนิเมชันทั้งหมดเป็น 0
			end
			task.delay(0.06, function()
				for _, track in ipairs(tracks) do
					track:AdjustSpeed(1) -- คืนค่าความเร็วอนิเมชันกลับเป็น 1
				end
			end)
		end
	end

	-- 3. เล่นเอฟเฟกต์พาร์ทิเคิลระเบิดละอองเขียวตรงเหยื่อที่ติดเชื้อ (Infection Impact Green Glow)
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
	if root and SettingsPanel.GetSetting("Particles") then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxassetid://243660364"
		pe.Color = ColorSequence.new(Color3.fromRGB(50, 255, 50))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
		pe.Rate = 25
		pe.Speed = NumberRange.new(6, 12)
		pe.Lifetime = NumberRange.new(1, 2)
		pe.SpreadAngle = Vector2.new(45, 45)
		pe.Parent = root

		-- ปิดและเคลียร์พาร์ทิเคิลออกอย่างนุ่มนวลหลังพ่นเสร็จ
		task.delay(3, function()
			if pe then 
				pe.Enabled = false 
				task.wait(2) 
				pe:Destroy() 
			end
		end)
	end
end)

-- อัปเดตข้อมูลระดับภัยคุกคามของรัฐบาลประจำโซน (Threat Level / DEFCON)
RemoteManager.OnClientEvent(Constants.REMOTES.THREAT_LEVEL_CHANGED, function(level, name, color)
	MainHUD.UpdateThreatLevel(level, name, color)
end)

-- อัปเดตข้อมูลความคืบหน้าการพัฒนาวัคซีนประจำโซน (Vaccine Progress)
RemoteManager.OnClientEvent(Constants.REMOTES.VACCINE_PROGRESS_CHANGED, function(progress)
	MainHUD.UpdateVaccineProgress(progress)
end)

-- แจ้งข่าวเตือนวัคซีนระดับโซนถูกปล่อยลงพื้นที่
RemoteManager.OnClientEvent(Constants.REMOTES.VACCINE_DEPLOYED, function(hasResistance, curedCount, resistedCount)
	if hasResistance then
		MainHUD.ShowPopup("💊 VACCINE DEPLOYED! (20% Resisted)", nil, "DNA")
	else
		MainHUD.ShowPopup("💉 VACCINE DEPLOYED! Cured All!", nil, "Damage")
	end
end)

-- อัปเดตพลังการจุติสะสม (Prestige System Update)
RemoteManager.OnClientEvent(Constants.REMOTES.PRESTIGE_CHANGED, function(level, multiplier, tokens)
	MainHUD.UpdatePrestige(level, multiplier, tokens)
end)

-- ==============================================================================
-- 7. ZONE BOSS BATTLES (ระบบบอสประจำโซนและการดึงข้อมูลบาร์เลือดอิงตามระยะทาง)
-- ==============================================================================

-- ตรวจจับบอสโซนเกิด
RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_SPAWNED, function(model, name, curHp, maxHp, color)
	activeBossModel = model
	activeBossData = {name = name, curHp = curHp, maxHp = maxHp, color = color}
	isBossBarVisible = false
	-- หมายเหตุ: จะไม่แสดงหลอดเลือดทันที แต่ใช้ Heartbeat เช็คความใกล้เพื่อเปิด/ปิด UI ให้เหมาะสม
end)

-- ตรวจรับความเปลี่ยนแปลงของเลือดบอส
RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_HEALTH_CHANGED, function(curHp, maxHp)
	if activeBossData then
		activeBossData.curHp = curHp
		activeBossData.maxHp = maxHp
	end
	if isBossBarVisible then
		MainHUD.UpdateBossHealth(curHp, maxHp)
	end
end)

-- ตรวจรับสัญญาณเมื่อบอสถูกจำกัดลง
RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_DEFEATED, function(name)
	activeBossModel = nil
	activeBossData = nil
	isBossBarVisible = false
	MainHUD.HideBossBar(name)
end)

-- รันลูปตรวจวัดระยะทางระหว่างตัวเรากับบอสเพื่อแสดงหลอดเลือดใหญ่บนหน้าจอ (เปิดเฉพาะระยะ 120 studs)
RunService.Heartbeat:Connect(function()
	if activeBossModel and activeBossModel.PrimaryPart and player.Character and player.Character.PrimaryPart then
		local dist = (activeBossModel.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
		if dist <= 120 then
			if not isBossBarVisible then
				isBossBarVisible = true
				MainHUD.ShowBossBar(activeBossData.name, activeBossData.curHp, activeBossData.maxHp, activeBossData.color)
			end
		else
			if isBossBarVisible then
				isBossBarVisible = false
				MainHUD.HideBossBarSilent()
			end
		end
	end
end)

-- ==============================================================================
-- 8. ENVIRONMENT LASER FENCES (ระบบควบคุมกำแพงเลเซอร์กั้นความคืบหน้าของโซน)
-- ==============================================================================
local mapDeco = workspace:WaitForChild("MapDecorations", 5)
local fences = {
	City = mapDeco and mapDeco:WaitForChild("LaserFence_55", 5),
	Military = mapDeco and mapDeco:WaitForChild("LaserFence_165", 5),
	Vought = mapDeco and mapDeco:WaitForChild("LaserFence_275", 5),
}

-- ตั้งค่าทางเดินเลเซอร์ให้ทึบและมีกายภาพบล็อกการเคลื่อนที่ตอนเริ่มเกม
for zone, fence in pairs(fences) do
	if fence and fence:IsA("BasePart") then
		fence.CanCollide = true
		fence.Transparency = 0.5
		fence.Material = Enum.Material.Neon
		fence.Color = Color3.fromRGB(255, 0, 0) -- เลเซอร์สีแดงอันตราย
	end
end

-- ฟังก์ชันเล่นอนิเมชันเปิดรั้วแสงเมื่อปลดโซนสำเร็จ
local function unlockZoneFence(zoneName)
	local fence = fences[zoneName]
	if fence and fence:IsA("BasePart") then
		fence.CanCollide = false
		local tween = TweenService:Create(fence, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
		tween:Play()
	end
end

-- ดักรับเหตุการณ์เมื่อเซิร์ฟเวอร์แจ้งว่าปลดล็อกโซนแผนที่ใหม่สำเร็จ
RemoteManager.OnClientEvent(Constants.REMOTES.ZONE_UNLOCKED, function(zoneName)
	local zoneTitles = {
		City = "🏙️ CITY ZONE UNLOCKED!",
		Military = "🪖 MILITARY BASE UNLOCKED!",
		Vought = "🦸‍♂️ VOUGHT HQ UNLOCKED!",
	}
	MainHUD.ShowPopup(zoneTitles[zoneName] or ("✨ " .. string.upper(zoneName) .. " UNLOCKED!"), nil, "DNA")
	unlockZoneFence(zoneName)
end)

-- ==============================================================================
-- 9. COMBAT SYSTEM: ACTIVE MELEE HITBOX (ระบบควบคุมการสวิงหมัดต่อยและดักจับการชน)
-- ==============================================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- ตรวจจับการกดคลิกซ้ายเมาส์หรือการกดปุ่ม F เพื่อออกหมัด
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		local now = os.clock()
		if now - lastPunchTime < 1.0 then return end -- คูลดาวน์หมัด 1 วินาที
		lastPunchTime = now

		if isPunching then return end
		isPunching = true

		-- ซ่อนคำแนะนำสอนเล่นสำหรับการต่อยครั้งแรก
		if not MainHUD.HasPunched then
			MainHUD.HideTip()
		end

		local char = player.Character
		if not char then isPunching = false return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then isPunching = false return end

		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or root
		local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftLowerArm") or root

		-- 1. เล่นอนิเมชันสวิงหมัด
		if currentPunchTrack then
			currentPunchTrack:Play()
		end

		-- 2. เล่นเสียงสวิงลม (Punch Swing Sound)
		if SettingsPanel.GetSetting("SFX") then
			local swingSound = Instance.new("Sound")
			swingSound.SoundId = "rbxassetid://131237241"
			swingSound.Volume = 0.8
			swingSound.PlayOnRemove = true
			swingSound.Parent = root
			swingSound:Destroy()
		end

		-- 3. สร้างเอฟเฟกต์เรืองแสงที่ตัวหมัด (Toxic Fist Glow)
		local fistGlow = Instance.new("Part")
		fistGlow.Name = "ToxicFistGlow"
		fistGlow.Size = Vector3.new(1.5, 1.5, 1.5)
		fistGlow.Color = Color3.fromRGB(50, 255, 100)
		fistGlow.Material = Enum.Material.Neon
		fistGlow.Transparency = 0.4
		fistGlow.CanCollide = false
		fistGlow.Massless = true
		
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Parent = fistGlow

		fistGlow.CFrame = rightHand.CFrame
		fistGlow.Parent = char

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rightHand
		weld.Part1 = fistGlow
		weld.Parent = fistGlow

		-- สร้างคลื่นหมัดพิษกระแทกไปข้างหน้า (Toxic Punch Wave)
		local punchWave = Instance.new("Part")
		punchWave.Name = "ToxicPunchWave"
		punchWave.Size = Vector3.new(3, 3, 1)
		punchWave.Color = Color3.fromRGB(50, 255, 100)
		punchWave.Material = Enum.Material.Neon
		punchWave.Transparency = 0.5
		punchWave.Anchored = true
		punchWave.CanCollide = false
		punchWave.Massless = true
		
		local waveMesh = Instance.new("SpecialMesh")
		waveMesh.MeshType = Enum.MeshType.Sphere
		waveMesh.Parent = punchWave

		punchWave.CFrame = root.CFrame * CFrame.new(0, 0, -2)
		punchWave.Parent = workspace

		local goalCFrame = root.CFrame * CFrame.new(0, 0, -10)
		local waveTween = TweenService:Create(punchWave, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = goalCFrame,
			Size = Vector3.new(5, 5, 2),
			Transparency = 1
		})
		waveTween:Play()
		waveTween.Completed:Connect(function()
			punchWave:Destroy()
		end)

		-- 4. รันระบบ Active Hitbox เช็คการปะทะ (ต่อเนื่อง 0.35 วินาทีในช่วงออกหมัด)
		local hitTargets = {}
		local punchStart = os.clock()
		local connection = nil

		connection = RunService.Heartbeat:Connect(function()
			if os.clock() - punchStart >= 0.35 then
				if connection then connection:Disconnect() end
				if fistGlow then fistGlow:Destroy() end
				isPunching = false
				return
			end

			-- ตรวจจับระยะห่างของมือจากตำแหน่ง NPC
			for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
				if hitTargets[npc] then continue end

				local targetRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
				if not targetRoot then continue end

				local distRight = (targetRoot.Position - rightHand.Position).Magnitude
				local distLeft = (targetRoot.Position - leftHand.Position).Magnitude

				-- ถ้ามือขวาหรือซ้ายอยู่ใกล้ตัวละครเป้าหมายในระยะเช็ค
				if distRight <= HITBOX_RADIUS or distLeft <= HITBOX_RADIUS then
					hitTargets[npc] = true

					-- เล่นเสียงปะทะต่อยโดน (Impact Hit Sound)
					if SettingsPanel.GetSetting("SFX") then
						local hitSound = Instance.new("Sound")
						hitSound.SoundId = "rbxassetid://12222216"
						hitSound.Volume = 1.0
						hitSound.PlayOnRemove = true
						hitSound.Parent = rightHand
						hitSound:Destroy()
					end

					-- สร้างแฟลชประกายต่อยปะทะ (Impact Spark Flash)
					local impact = Instance.new("Part")
					impact.Size = Vector3.new(2, 2, 2)
					impact.Color = Color3.fromRGB(255, 255, 100)
					impact.Material = Enum.Material.Neon
					impact.Anchored = true
					impact.CanCollide = false
					impact.CFrame = CFrame.new((rightHand.Position + targetRoot.Position) / 2)
					impact.Parent = workspace

					local impMesh = Instance.new("SpecialMesh")
					impMesh.MeshType = Enum.MeshType.Sphere
					impMesh.Parent = impact

					local impTween = TweenService:Create(impact, TweenInfo.new(0.15), {Size = Vector3.new(4, 4, 4), Transparency = 1})
					impTween:Play()
					impTween.Completed:Connect(function() impact:Destroy() end)

					-- ส่งเหตุการณ์ขึ้นระบบ Server เพื่อลงทะเบียนการโจมตี/แพร่เชื้อ
					RemoteManager.FireServer(Constants.REMOTES.REQUEST_INFECT, npc)
				end
			end
		end)
	end
end)

-- ==============================================================================
-- 10. MOVEMENT SYSTEM: SPRINT (LeftShift) & WARP DASH (Q)
-- ==============================================================================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- ระบบกดค้าง Shift เพื่อวิ่งเร็ว (Sprint Start)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = true
		updateWalkSpeed()
		
		-- ซูมกล้องออกแบบถอยภาพยืดเพื่อความรู้สึกเร็ว (Camera Zoom Out FOV 80)
		local camera = workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 80}):Play()
		end
	end

	-- ระบบกด Q เพื่อพุ่งวาร์ปแดชระยะสั้น (40-stud Warp Dash)
	if input.KeyCode == Enum.KeyCode.Q then
		local now = os.clock()
		if now - lastDashTime >= DASH_COOLDOWN then
			if not character or not humanoid or humanoid.Health <= 0 then return end
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if not rootPart then return end

			lastDashTime = now

			-- 1. คำนวณทิศทางการแดชพุ่งอิงตามปุ่มควบคุม (ถ้ากำลังเดินจะพุ่งตามทิศนั้น ถ้าอยู่เฉยๆ จะพุ่งตามหน้าตัวละคร)
			local moveDirection = humanoid.MoveDirection
			local dashDirection
			if moveDirection.Magnitude > 0 then
				dashDirection = moveDirection.Unit
			else
				dashDirection = rootPart.CFrame.LookVector
			end
			dashDirection = Vector3.new(dashDirection.X, 0, dashDirection.Z).Unit

			-- 2. เล่นเสียงการแดชและ FOV กล้องขยายเพื่อความสะใจ (Juice)
			if SettingsPanel.GetSetting("SFX") then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://9114223193" -- futuristic swoosh sound
				sound.Volume = 0.5
				sound.Parent = rootPart
				sound:Play()
				Debris:AddItem(sound, 1.5)
			end

			local camera = workspace.CurrentCamera
			if camera then
				local startFOV = camera.FieldOfView
				TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {FieldOfView = startFOV + 20}):Play()
			end

			-- 3. ตรวจสอบสิ่งกีดขวางแนวพุ่งด้วย Raycast (Raycast Collision Safety Check)
			-- เว้นไม่ทำการเช็คชนกับตัวเราเอง, เพื่อนร่วมห้อง และโฟลเดอร์มอนสเตอร์ทั่วไป
			local excludeList = {character}
			local npcsFolder = workspace:FindFirstChild("NPCs")
			if npcsFolder then
				table.insert(excludeList, npcsFolder)
			end
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= player and otherPlayer.Character then
					table.insert(excludeList, otherPlayer.Character)
				end
			end

			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = excludeList
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude

			local startPos = rootPart.Position
			local rayDirection = dashDirection * 40
			local targetPos = startPos + rayDirection

			-- วนลูปสแกนทะลุกรณียิงชนสิ่งของตกแต่งโปร่งแสง (เช่นใบไม้ ทริกเกอร์โซน ที่ไม่มีกายภาพชน CanCollide = false)
			local currentStart = startPos
			local currentDir = rayDirection
			local iterations = 0

			while iterations < 5 do
				local result = workspace:Raycast(currentStart, currentDir, raycastParams)
				if not result then break end

				if result.Instance.CanCollide then
					-- ชนกำแพงทึบ! ล็อกปลายทางและหยุดเผื่อไว้ก่อนถึงผนัง 2.5 studs กันตัวติดในกำแพง
					targetPos = result.Position - dashDirection * 2.5
					break
				else
					-- ทะลุสิ่งของทั่วไป ย้ายจุดสแกนต่อถัดไปเล็กน้อย
					local hitPos = result.Position
					currentStart = hitPos + dashDirection * 0.1
					currentDir = (startPos + rayDirection) - currentStart
					if currentDir.Magnitude <= 0.1 then break end
				end
				iterations += 1
			end

			-- 4. สร้างเอฟเฟกต์อนุภาคสายลมตามหลังระยะทางที่พุ่ง (Dash Trail Particles)
			local trailPE = Instance.new("ParticleEmitter")
			trailPE.Name = "DashTrail"
			trailPE.Texture = "rbxassetid://243660364"
			trailPE.Color = ColorSequence.new(Color3.fromRGB(150, 255, 150))
			trailPE.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.8)})
			trailPE.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
			trailPE.Speed = NumberRange.new(5, 10)
			trailPE.Lifetime = NumberRange.new(0.3, 0.6)
			trailPE.Rate = 250
			trailPE.Parent = rootPart

			-- 5. ล็อกฟิสิกส์ตัวละครเป็น Anchored และวาร์ป CFrame ไปยังจุดหมายผ่าน Tween เพื่อความราบรื่นสุดของมุมกล้อง
			rootPart.Anchored = true
			
			local targetCFrame = CFrame.new(targetPos) * (rootPart.CFrame - rootPart.CFrame.Position)
			local dashTween = TweenService:Create(rootPart, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
			dashTween:Play()

			-- เมื่อพุ่งตัวเสร็จสิ้น ให้ปล่อยการควบคุมตัวละครคืนสู่ระบบฟิสิกส์ปกติ
			dashTween.Completed:Connect(function()
				rootPart.Anchored = false
				trailPE.Enabled = false
				Debris:AddItem(trailPE, 0.8)
			end)
		end
	end
end)

-- ตรวจการปล่อยปุ่มควบคุม (Shift) เพื่อลดความเร็วลงมาเป็นปกติ
UserInputService.InputEnded:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isSprinting = false
		updateWalkSpeed()

		-- ซูมกล้องเข้ากลับคืนสู่ระยะปกติ (Field of View 70)
		local camera = workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {FieldOfView = 70}):Play()
		end
	end
end)

-- ==============================================================================
-- 11. INTRO ANIMATION (การรันอนิเมชันเปิดตัวหน้าจอเริ่มต้นเกม)
-- ==============================================================================
MainHUD.PlayIntroAnimation()

print("[ClientMain] ✅ ระบบ Client ทำงานสมบูรณ์!")
