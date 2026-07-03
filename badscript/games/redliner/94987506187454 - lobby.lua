-- BadWars Redliner Lobby Module
-- Place ID: 94987506187454
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Redliner Lobby] Loaded for place ' .. tostring(game.PlaceId))
end
