-- BadWars Frontlines Game Module
-- Place ID: 5938036553
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Frontlines] Loaded for place ' .. tostring(game.PlaceId))
end

local frontlines = {
	Game = 'Frontlines',
	PlaceId = game.PlaceId,
	Status = 'active'
}

Bad.frontlines = frontlines

task.spawn(function()
	task.wait(2)
	if Bad.CreateNotification then
		Bad:CreateNotification('Frontlines Active', 'Game-specific features loaded', 4)
	end
end)
