-- BadWars 1.8 Arena Game Module
-- Place ID: 77790193039862
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[1.8 Arena] Loaded for place ' .. tostring(game.PlaceId))
end

local arena = {
	Game = '1.8 Arena',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.arena = arena

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('1.8 Arena Active', 'Game-specific features loaded', 4)
	end
end)
