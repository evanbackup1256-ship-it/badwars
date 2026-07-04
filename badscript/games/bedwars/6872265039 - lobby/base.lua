-- BadWars BedWars Lobby Module
-- Place ID: 6872265039
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BedWars Lobby] Loaded for place ' .. tostring(game.PlaceId))
end

local lobby = {
	Game = 'BedWars Lobby',
	PlaceId = game.PlaceId,
	Status = 'waiting'
}

Bad.bedwarsLobby = lobby

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('BedWars Lobby', 'Waiting for game match...', 4)
	end
end)

return lobby
