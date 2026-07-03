-- BadWars Prison Life Main Module
-- Place ID: 155615604
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Prison Life] Game module loaded for place ' .. tostring(game.PlaceId))
end

local prison = {
	Game = 'Prison Life',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.prisonLife = prison

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('Prison Life Active', 'Game-specific features loaded', 4)
	end
end)
