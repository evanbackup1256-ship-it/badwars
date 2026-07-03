-- BadWars BedWars Micro Module
-- Place ID: 8560631822
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BedWars Micro] Loaded for place ' .. tostring(game.PlaceId))
end
