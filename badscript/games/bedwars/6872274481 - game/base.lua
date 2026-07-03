-- BadWars BedWars Game Module (Main Game)
-- Place ID: 6872274481
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BedWars] Game module loaded for place ' .. tostring(game.PlaceId))
end

local bedwars = {
	Game = 'BedWars',
	PlaceId = game.PlaceId,
	Phase = 'loading',
	Map = 'unknown',
	Teams = {},
	Modules = {}
}

Bad.bedwars = bedwars

local Players = game:GetService('Players')
local lp = Players.LocalPlayer
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local function detectMap()
	pcall(function()
		local ws = game:GetService('Workspace')
		for _, child in ws:GetChildren() do
			if child:IsA('Model') and child.Name ~= lp.Name then
				bedwars.Map = child.Name
				break
			end
		end
	end)
end

local function detectPhase()
	pcall(function()
		if ReplicatedStorage:FindFirstChild('GameInProgress') then
			bedwars.Phase = 'game'
		else
			bedwars.Phase = 'lobby'
		end
		if Bad.AddLog then
			Bad:AddLog('Info', '[BedWars] Detected phase: ' .. bedwars.Phase .. ', Map: ' .. bedwars.Map)
		end
		if Bad.CreateNotification then
			Bad:CreateNotification('BedWars Active', 'Map: ' .. bedwars.Map .. ' | Phase: ' .. bedwars.Phase, 5)
		end
	end)
end

local function monitorPhaseChange()
	local lastPhase = bedwars.Phase
	local phaseConnection
	phaseConnection = RunService.Heartbeat:Connect(function()
		if not Bad or not Bad.Loaded then
			if phaseConnection then pcall(function() phaseConnection:Disconnect() end) end
			return
		end
		pcall(function()
			if ReplicatedStorage:FindFirstChild('GameInProgress') then
				bedwars.Phase = 'game'
			else
				if bedwars.Phase == 'game' then
					bedwars.Phase = 'lobby'
					bedwars.Map = 'unknown'
					if Bad.AddLog then
						Bad:AddLog('Info', '[BedWars] Game ended, returning to lobby')
					end
				end
				bedwars.Phase = 'lobby'
			end
		end)
	end)
	if Bad and type(Bad.Clean) == 'function' then
		Bad:Clean(phaseConnection)
	end
end

task.spawn(function()
	task.wait(3)
	pcall(detectMap)
	pcall(detectPhase)
	pcall(monitorPhaseChange)
end)
