local run = function(func)
	local ok, err = pcall(func)
	if not ok and shared.Bad and type(shared.Bad.CreateNotification) == 'function' then
		shared.Bad:CreateNotification('BedWars Lobby', 'Lobby services are not loaded yet.', 5, 'warning')
		warn('BadWars: [BedWars Lobby] service init failed: '..tostring(err))
	end
end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local Bad = shared.Bad
if not Bad then return end

local entitylib = Bad.Libraries and Bad.Libraries.entity or {Events = {}}
local sessioninfo = Bad.Libraries and Bad.Libraries.sessioninfo
local bedwars = {}

Bad.bedwarsLobby = {
	Game = 'BedWars Lobby',
	PlaceId = game.PlaceId,
	Status = 'loading'
}
Bad.bedwars = bedwars

local function notif(...)
	return Bad:CreateNotification(...)
end

run(function()
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit then break end
		task.wait()
	until KnitInit

	if Knit and not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			if Knit and Knit.Controllers then
				rawset(self, ind, Knit.Controllers[ind])
			end
			return rawget(self, ind)
		end
	})

	Bad.bedwars = bedwars
	Bad.bedwarsLobby.Status = 'ready'

	if sessioninfo and type(sessioninfo.AddItem) == 'function' then
		pcall(function()
			sessioninfo:AddItem('Kills')
			sessioninfo:AddItem('Beds')
			sessioninfo:AddItem('Wins')
			sessioninfo:AddItem('Games')
		end)
	end

	Bad:Clean(function()
		table.clear(bedwars)
	end)
end)
