-- BadWars SkyWars Voxel Lobby Module
-- Place ID: 8542259458
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[SkyWars Lobby] Loaded for place ' .. tostring(game.PlaceId))
end
