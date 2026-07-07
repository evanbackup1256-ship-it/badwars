-- BadWars BedWars Micro routes through the shared 6872274481 game module bundle.
-- main.lua maps this place id to badscript/games/bedwars/6872274481 - game/base.lua
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[BedWars Micro] Using shared BedWars game module bundle')
end

return {Game = 'BedWars Micro', PlaceId = game.PlaceId, Bundle = '6872274481 - game'}
