-- V-Breaker | ClientMain (Entry Point)
-- StarterPlayer/StarterPlayerScripts/Client/ClientMain.client.lua

print("[ClientMain] 🚀 เริ่มต้นระบบ Client V-Breaker...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("constants"):WaitForChild("Constants"))
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
local MainHUD = require(script.Parent:WaitForChild("ui"):WaitForChild("MainHUD"))

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- 1. Initialize UI
MainHUD.Init()

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

RemoteManager.OnClientEvent(Constants.REMOTES.INFECTION_SPREAD, function(targetModel, infectedByUserId)
	if not targetModel then return end

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

print("[ClientMain] ✅ ระบบ Client ทำงานสมบูรณ์!")
