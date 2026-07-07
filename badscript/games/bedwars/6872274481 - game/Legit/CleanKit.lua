local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}

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





