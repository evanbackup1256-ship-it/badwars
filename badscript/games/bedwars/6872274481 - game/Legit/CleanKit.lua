local Bad = shared.Bad or {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local store = (shared.Bad and shared.Bad.store) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local compat = Bad.BedWarsCompatibility or {}
local lplr = game:GetService('Players').LocalPlayer

local CleanKit
local oldSpawnOrb

CleanKit = Bad.Legit:CreateModule({
	Name = 'Clean Kit',
	Function = function(callback)
		local controller = bedwars.WindWalkerController
		if callback then
			if controller and type(controller.spawnOrb) == 'function' then
				oldSpawnOrb = controller.spawnOrb
				controller.spawnOrb = function() end
			end
			local zephyreffect = lplr.PlayerGui:FindFirstChild('WindWalkerEffect', true)
			if zephyreffect then
				zephyreffect.Visible = false
			end
		elseif controller and oldSpawnOrb then
			controller.spawnOrb = oldSpawnOrb
			oldSpawnOrb = nil
		end
	end,
	Tooltip = 'Removes zephyr status indicator'
})





