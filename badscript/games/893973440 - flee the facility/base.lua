-- BadWars Flee The Facility Game Module
-- Place ID: 893973440
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Flee The Facility] Loaded for place ' .. tostring(game.PlaceId))
end

local ftf = {
	Game = 'Flee The Facility',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.fleeTheFacility = ftf

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('Flee The Facility Active', 'Game-specific features loaded', 4)
	end
end)
