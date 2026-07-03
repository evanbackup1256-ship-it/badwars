-- BadWars Bridge Duel Game Module
-- Place ID: 139566161526375
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Bridge Duel] Loaded for place ' .. tostring(game.PlaceId))
end

local bridge = {
	Game = 'Bridge Duel',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.bridgeDuel = bridge

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('Bridge Duel Active', 'Compact duel module ready', 4)
	end
end)
