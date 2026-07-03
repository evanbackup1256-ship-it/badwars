-- BadWars BlockTales Module
-- Place ID: 16483433878
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BlockTales] Loaded for place ' .. tostring(game.PlaceId))
end

local blocktales = {
	Game = 'BlockTales',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.blocktales = blocktales

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('BlockTales Active', 'Game-specific features loaded', 4)
	end
end)
