-- BadWars Redliner Game Module
-- Place ID: 115875349872417
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Redliner] Loaded for place ' .. tostring(game.PlaceId))
end

local redliner = {
	Game = 'Redliner',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.redliner = redliner

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('Redliner Active', 'Game-specific features loaded', 4)
	end
end)
