-- V-Breaker | ClientMain (Entry Point)
-- StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua

print("[ClientMain] 🚀 เริ่มต้นระบบ Client V-Breaker...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local MainHUD = require(script.Parent:WaitForChild("ui"):WaitForChild("MainHUD"))
local MutationShop = require(script.Parent:WaitForChild("ui"):WaitForChild("MutationShop"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 1. Initialize UI
MainHUD.Init()
MutationShop.Init()

-- 2. Connect Remote Events
RemoteManager.OnClientEvent(Constants.REMOTES.BIO_POINTS_CHANGED, function(newBio)
	MainHUD.UpdateBio(newBio)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.DNA_POINTS_CHANGED, function(newDna)
	MainHUD.UpdateDna(newDna)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.NOTIFICATION, function(message, notifType)
	MainHUD.ShowNotification(message, notifType)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.SHOW_POPUP, function(text, pos, popupType)
	MainHUD.ShowPopup(text, pos, popupType)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.SYNC_MUTATIONS, function(mutationsTable)
	MutationShop.OnSyncMutations(mutationsTable)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.MUTATION_UNLOCKED, function(mutationId)
	MutationShop.OnMutationUnlocked(mutationId)
end)

local comboCount = 0
local lastComboTime = 0

RemoteManager.OnClientEvent(Constants.REMOTES.INFECTION_SPREAD, function(targetModel, infectedByUserId)
	if not targetModel then return end

	-- 1. Combo Tracking
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

	-- 2. Hit Freeze (60ms)
	if player.Character then
		local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			local animator = hum:FindFirstChildWhichIsA("Animator") or hum
			local tracks = animator:GetPlayingAnimationTracks()
			for _, track in ipairs(tracks) do
				track:AdjustSpeed(0)
			end
			task.delay(0.06, function()
				for _, track in ipairs(tracks) do
					track:AdjustSpeed(1)
				end
			end)
		end
	end

	-- เล่น Particle สีเขียวเรืองแสง
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
	if root then
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxassetid://243660364" -- สปอร์เรืองแสง
		pe.Color = ColorSequence.new(Color3.fromRGB(50, 255, 50))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
		pe.Rate = 25
		pe.Speed = NumberRange.new(6, 12)
		pe.Lifetime = NumberRange.new(1, 2)
		pe.SpreadAngle = Vector2.new(45, 45)
		pe.Parent = root

		-- ลบ Particle เมื่อเวลาผ่านไป 3 วินาที
		task.delay(3, function()
			if pe then pe.Enabled = false task.wait(2) pe:Destroy() end
		end)
	end
end)

RemoteManager.OnClientEvent(Constants.REMOTES.THREAT_LEVEL_CHANGED, function(level, name, color)
	MainHUD.UpdateThreatLevel(level, name, color)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.VACCINE_PROGRESS_CHANGED, function(progress)
	MainHUD.UpdateVaccineProgress(progress)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.VACCINE_DEPLOYED, function(hasResistance, curedCount, resistedCount)
	if hasResistance then
		MainHUD.ShowPopup("💊 VACCINE DEPLOYED! (20% Resisted)", nil, "DNA")
	else
		MainHUD.ShowPopup("💉 VACCINE DEPLOYED! Cured All!", nil, "Damage")
	end
end)

local activeBossModel = nil
local activeBossData = nil
local isBossBarVisible = false

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_SPAWNED, function(model, name, curHp, maxHp, color)
	activeBossModel = model
	activeBossData = {name = name, curHp = curHp, maxHp = maxHp, color = color}
	isBossBarVisible = false
	-- ไม่โชว์หลอดเลือดทันที จะให้ Heartbeat เช็คระยะก่อน
end)

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_HEALTH_CHANGED, function(curHp, maxHp)
	if activeBossData then
		activeBossData.curHp = curHp
		activeBossData.maxHp = maxHp
	end
	if isBossBarVisible then
		MainHUD.UpdateBossHealth(curHp, maxHp)
	end
end)

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_DEFEATED, function(name)
	activeBossModel = nil
	activeBossData = nil
	isBossBarVisible = false
	MainHUD.HideBossBar(name)
end)

-- ระบบเช็คระยะห่างบอสเพื่อโชว์/ซ่อนหลอดเลือดบอส (Distance-based UI)
local RunService = game:GetService("RunService")
RunService.Heartbeat:Connect(function()
	if activeBossModel and activeBossModel.PrimaryPart and player.Character and player.Character.PrimaryPart then
		local dist = (activeBossModel.PrimaryPart.Position - player.Character.PrimaryPart.Position).Magnitude
		if dist <= 120 then -- ระยะแสดงหลอดเลือดบอส (120 studs)
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

-- ระบบจัดการกำแพงเลเซอร์กั้นโซน (Laser Fences)
local mapDeco = workspace:WaitForChild("MapDecorations", 5)
local fences = {
	City = mapDeco and mapDeco:WaitForChild("LaserFence_55", 5),
	Military = mapDeco and mapDeco:WaitForChild("LaserFence_165", 5),
	Vought = mapDeco and mapDeco:WaitForChild("LaserFence_275", 5),
}

-- ตั้งค่าเริ่มต้นให้กำแพงทั้งหมดเปิดใช้งาน (CanCollide = true, สีแดงเรืองแสง)
for zone, fence in pairs(fences) do
	if fence and fence:IsA("BasePart") then
		fence.CanCollide = true
		fence.Transparency = 0.5
		fence.Material = Enum.Material.Neon
		fence.Color = Color3.fromRGB(255, 0, 0)
	end
end

local function unlockZoneFence(zoneName)
	local fence = fences[zoneName]
	if fence and fence:IsA("BasePart") then
		fence.CanCollide = false
		local TweenService = game:GetService("TweenService")
		local tween = TweenService:Create(fence, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1})
		tween:Play()
	end
end

RemoteManager.OnClientEvent(Constants.REMOTES.ZONE_UNLOCKED, function(zoneName)
	local zoneTitles = {
		City = "🏙️ CITY ZONE UNLOCKED!",
		Military = "🪖 MILITARY BASE UNLOCKED!",
		Vought = "🦸‍♂️ VOUGHT HQ UNLOCKED!",
	}
	MainHUD.ShowPopup(zoneTitles[zoneName] or ("✨ " .. string.upper(zoneName) .. " UNLOCKED!"), nil, "DNA")
	unlockZoneFence(zoneName)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.PRESTIGE_CHANGED, function(level, multiplier, tokens)
	MainHUD.UpdatePrestige(level, multiplier, tokens)
end)

-- 3. Player Input (ระบบต่อยจริง Active Melee Hitbox / Punch to Infect & Damage)
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local isPunching = false
local HITBOX_RADIUS = 4.5 -- รัศมีปะทะหมัดจากมือ (studs)
local currentPunchTrack = nil
local lastPunchTime = 0

local function loadPunchAnimation(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		local animator = hum:WaitForChild("Animator", 5) or hum
		local rs = game:GetService("ReplicatedStorage")
		local animFolder = rs:WaitForChild("SharedAnimations", 5)
		if animFolder then
			local combatFolder = animFolder:WaitForChild("Combat", 5)
			if combatFolder then
				local punchSeq = combatFolder:WaitForChild("R15PunchSeq", 5)
				if punchSeq and punchSeq:IsA("KeyframeSequence") then
					local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
					local success, hashId = pcall(function()
						return KeyframeSequenceProvider:RegisterKeyframeSequence(punchSeq)
					end)
					
					if success and hashId then
						local anim = Instance.new("Animation")
						anim.AnimationId = hashId
						currentPunchTrack = animator:LoadAnimation(anim)
						-- บังคับให้เป็น Action Priority เพื่อทับท่าเดิน/ท่ายืน
						currentPunchTrack.Priority = Enum.AnimationPriority.Action4
					end
				end
			end
		end
	end
end

if player.Character then loadPunchAnimation(player.Character) end
player.CharacterAdded:Connect(function(char)
	currentPunchTrack = nil
	loadPunchAnimation(char)
end)


UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		local now = os.clock()
		if now - lastPunchTime < 1.0 then return end -- คูลดาวน์ 1 วินาที
		lastPunchTime = now

		if isPunching then return end
		isPunching = true

		if not MainHUD.HasPunched then
			MainHUD.HideTip()
		end

		local char = player.Character
		if not char then isPunching = false return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then isPunching = false return end

		-- ค้นหาชิ้นส่วนมือ (Hand/Arm Part) สำหรับเช็ค Hitbox
		local rightHand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm") or char:FindFirstChild("RightLowerArm") or root
		local leftHand = char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftLowerArm") or root

		-- 1. เล่น Animation ต่อย (ดึงจาก Toolslash)
		if currentPunchTrack then
			currentPunchTrack:Play()
		end

		-- 2. เล่นเสียงสวิงหมัด (Punch Swing Sound)
		local swingSound = Instance.new("Sound")
		swingSound.SoundId = "rbxassetid://131237241" -- เสียงสวิงหมัด
		swingSound.Volume = 0.8
		swingSound.PlayOnRemove = true
		swingSound.Parent = root
		swingSound:Destroy()

		-- 3. สร้างเอฟเฟกต์หมัดพิษเรืองแสง (Toxic Fist Glow) คลุมที่มือ
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

		-- สร้างคลื่นหมัดพิษนำทาง (Toxic Wave) เพื่อความอลังการควบคู่กัน
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
		local tween = TweenService:Create(punchWave, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = goalCFrame,
			Size = Vector3.new(5, 5, 2),
			Transparency = 1
		})
		tween:Play()
		tween.Completed:Connect(function()
			punchWave:Destroy()
		end)

		-- 4. ระบบ Active Melee Hitbox Loop (วนลูปเช็คการชนของมือในช่วงออกหมัด 0.35 วินาที)
		local hitTargets = {} -- ป้องกันฮิตซ้ำในหมัดเดียว
		local startTime = os.clock()
		local connection = nil

		connection = RunService.Heartbeat:Connect(function()
			if os.clock() - startTime >= 0.35 then
				if connection then connection:Disconnect() end
				if fistGlow then fistGlow:Destroy() end
				isPunching = false
				return
			end

			-- ตรวจจับการชนจากตำแหน่งมือทั้งสองข้าง (Active Hand Proximity Check)
			for _, npc in ipairs(CollectionService:GetTagged("NPC")) do
				if hitTargets[npc] then continue end -- เคยฮิตไปแล้วในหมัดนี้

				local targetRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
				if not targetRoot then continue end

				local distRight = (targetRoot.Position - rightHand.Position).Magnitude
				local distLeft = (targetRoot.Position - leftHand.Position).Magnitude

				if distRight <= HITBOX_RADIUS or distLeft <= HITBOX_RADIUS then
					hitTargets[npc] = true -- บันทึกว่าโดนต่อยแล้ว

					-- เล่นเสียงต่อยโดน (Hit Sound) ที่ตำแหน่งมือ
					local hitSound = Instance.new("Sound")
					hitSound.SoundId = "rbxassetid://12222216" -- เสียงต่อยโดน
					hitSound.Volume = 1.0
					hitSound.PlayOnRemove = true
					hitSound.Parent = rightHand
					hitSound:Destroy()

					-- สร้างเอฟเฟกต์กระแทก (Impact Flash) ที่จุดปะทะ
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

					-- ส่งคำสั่งแพร่เชื้อ/ทำดาเมจไปยัง Server
					RemoteManager.FireServer(Constants.REMOTES.REQUEST_INFECT, npc)
				end
			end
		end)
	end
end)

-- 4. Ambient Airborne Toxic Spores
local function setupAmbientSpores(char)
	local root = char:WaitForChild("HumanoidRootPart", 5)
	if root then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "AmbientToxicSpores"
		pe.Texture = "rbxassetid://243660364"
		pe.Color = ColorSequence.new(Color3.fromRGB(50, 255, 50))
		pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 1.2), NumberSequenceKeypoint.new(1, 0)})
		pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 1)})
		pe.Rate = 15
		pe.Speed = NumberRange.new(1, 3)
		pe.Lifetime = NumberRange.new(5, 8)
		pe.SpreadAngle = Vector2.new(360, 360)
		pe.Parent = root
	end
end

if player.Character then setupAmbientSpores(player.Character) end
player.CharacterAdded:Connect(setupAmbientSpores)

-- 5. Play Intro Animation (Slam-in + Test Tube Explode)
MainHUD.PlayIntroAnimation()

print("[ClientMain] ✅ ระบบ Client ทำงานสมบูรณ์!")
