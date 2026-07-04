local old
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}

Bad.Categories.Blatant:CreateModule({
	Name = 'NoSlowdown',
	Function = function(callback)
		if not bedwars.SprintController then return end
		local modifier = pcall(function() return bedwars.SprintController:getMovementStatusModifier() end)
		if not modifier then return end
		if callback then
			old = modifier.addModifier
			modifier.addModifier = function(self, tab)
				if tab.moveSpeedMultiplier then
					tab.moveSpeedMultiplier = math.max(tab.moveSpeedMultiplier, 1)
				end
				return old(self, tab)
			end

			for i in modifier.modifiers do
				if (i.moveSpeedMultiplier or 1) < 1 then
					pcall(function() modifier:removeModifier(i) end)
				end
			end
		else
			if old then
				modifier.addModifier = old
			end
			old = nil
		end
	end,
	Tooltip = 'Prevents slowing down when using items.'
})





