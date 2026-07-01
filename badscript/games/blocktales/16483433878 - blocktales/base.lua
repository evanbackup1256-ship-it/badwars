local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local replicatedFirst = cloneref(game:GetService('ReplicatedFirst'))
local collectionService = cloneref(game:GetService('CollectionService'))
local runService = cloneref(game:GetService('RunService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local Bad = shared.Bad
local entitylib = Bad.Libraries.entity
local targetinfo = Bad.Libraries.targetinfo
local bt = {}

local function notif(...)
	return Bad:CreateNotification(...)
end

run(function()
	bt = {
		Ambassador = require(replicatedFirst.Ambassador),
		BattleClient = getsenv(lplr.PlayerScripts.Battle.BattleClient),
		Enemy = require(replicatedFirst.Classes.Entities.Enemy),
		Network = require(replicatedFirst.Network),
		Shucky = require(replicatedFirst.Modules.Shucky),
		Variables = require(replicatedFirst.Variables)
	}

	Bad:Clean(function()
		table.clear(bt)
	end)
end)

for _, v in {'AimAssist', 'Reach', 'SilentAim', 'TriggerBot', 'AntiFall', 'HitBoxes', 'Invisible', 'Jesus', 'Killaura', 'TargetStrafe', 'AntiRagdoll', 'Disabler', 'MurderMystery', 'Freecam', 'ChatSpammer', 'SpinBot'} do
	Bad:Remove(v)
end




