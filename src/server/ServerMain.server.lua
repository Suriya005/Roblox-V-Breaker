-- V-Breaker | ServerMain (Entry Point)
-- ServerScriptService/Server/ServerMain.server.lua

print("[ServerMain] 🚀 เริ่มต้นระบบ Server V-Breaker...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = script.Parent

-- 1. Initialize Network (Remotes)
local RemoteManager = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("network"):WaitForChild("RemoteManager"))
RemoteManager.Init()

-- 2. Initialize Services
local PlayerService = require(Server:WaitForChild("services"):WaitForChild("PlayerService"))
PlayerService.Init()

local InfectionEngine = require(Server:WaitForChild("services"):WaitForChild("InfectionEngine"))
InfectionEngine.Init()

local NPCSpawner = require(Server:WaitForChild("services"):WaitForChild("NPCSpawner"))
NPCSpawner.Init()

print("[ServerMain] ✅ ระบบ Server ทำงานสมบูรณ์!")
