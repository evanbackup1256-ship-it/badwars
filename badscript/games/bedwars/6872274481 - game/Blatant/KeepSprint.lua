local bedwars = (shared.Bad and shared.Bad.bedwars) or {}

Bad.Categories.Blatant:CreateModule({
	Name = 'KeepSprint',
	Function = function(callback)
		if bedwars.SprintController then
			if bedwars.SprintController.startSprinting then
				pcall(function()
					debug.setconstant(bedwars.SprintController.startSprinting, 5, callback and 'blockSprinting' or 'blockSprint')
				end)
			end
			if bedwars.SprintController.stopSprinting then
				pcall(function() bedwars.SprintController:stopSprinting() end)
			end
		end
	end,
	Tooltip = 'Lets you sprint with a speed potion.'
})





