-- BadWars Jailbreak Game Module
-- Place ID: 606849621
local Bad = shared.Bad
if not Bad then return end

if Bad.AddLog then
	Bad:AddLog('Info', '[Jailbreak] Game module loaded for place ' .. tostring(game.PlaceId))
end

local jailbreak = {
	Game = 'Jailbreak',
	PlaceId = game.PlaceId,
	Modules = {},
	Status = 'active'
}

Bad.jailbreak = jailbreak

local function setupAntiCheat()
	local Players = game:GetService('Players')
	local lp = Players.LocalPlayer
	if not lp then return end

	pcall(function()
		if not shared.BadIndependent then
			task.wait(2)
			if Bad.CreateNotification then
				Bad:CreateNotification('Jailbreak Ready', 'Game-specific features activated', 4)
			end
		end
	end)
end

pcall(setupAntiCheat)
