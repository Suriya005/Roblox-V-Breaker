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

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_SPAWNED, function(name, curHp, maxHp, color)
	MainHUD.ShowBossBar(name, curHp, maxHp, color)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_HEALTH_CHANGED, function(curHp, maxHp)
	MainHUD.UpdateBossHealth(curHp, maxHp)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.BOSS_DEFEATED, function(name)
	MainHUD.HideBossBar(name)
end)

RemoteManager.OnClientEvent(Constants.REMOTES.ZONE_UNLOCKED, function(zoneName)
	local zoneTitles = {
		City = "🏙️ CITY ZONE UNLOCKED!",
		Military = "🪖 MILITARY BASE UNLOCKED!",
		Vought = "🦸‍♂️ VOUGHT HQ UNLOCKED!",
	}
	MainHUD.ShowPopup(zoneTitles[zoneName] or ("✨ " .. string.upper(zoneName) .. " UNLOCKED!"), nil, "DNA")
end)

RemoteManager.OnClientEvent(Constants.REMOTES.PRESTIGE_CHANGED, function(level, multiplier, tokens)
	MainHUD.UpdatePrestige(level, multiplier, tokens)
end)

-- 3. Player Input (คลิกปล่อยไวรัส)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.F then
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorWhichIsA("Model")
			if model and model ~= player.Character then
				RemoteManager.FireServer(Constants.REMOTES.REQUEST_INFECT, model)
			end
		end
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
