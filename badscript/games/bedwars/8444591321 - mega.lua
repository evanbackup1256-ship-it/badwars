-- BadWars BedWars Mega Module
-- Place ID: 8444591321
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BedWars Mega] Loaded for place ' .. tostring(game.PlaceId))
end

return {Game = 'BedWars Mega', PlaceId = game.PlaceId}
