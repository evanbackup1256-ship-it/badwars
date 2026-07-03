-- BadWars SkyWars Voxel Game Module
-- Place ID: 8768229691
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[SkyWars Voxel] Loaded for place ' .. tostring(game.PlaceId))
end

local skywars = {
	Game = 'SkyWars Voxel',
	PlaceId = game.PlaceId,
	Status = 'active',
	Mode = 'game'
}

Bad.skywars = skywars

task.spawn(function()
	task.wait(2)
	local ws = game:GetService('Workspace')
	pcall(function()
		for _, child in ws:GetChildren() do
			if child:IsA('Model') and child.Name:find('Map') then
				skywars.Map = child.Name
				break
			end
		end
	end)
	if Bad.CreateNotification then
		Bad:CreateNotification('SkyWars Voxel Active', 'Game mode detected | Map: ' .. (skywars.Map or 'unknown'), 4)
	end
end)
