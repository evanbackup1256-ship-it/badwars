local Sprint
local old

Sprint = Bad.Categories.Combat:CreateModule({
	Name = 'Sprint',
	Function = function(callback)
		if not bedwars.SprintController or type(bedwars.SprintController.stopSprinting) ~= 'function' or type(bedwars.SprintController.startSprinting) ~= 'function' then
			if callback then notif('Sprint', 'Sprint controller is not loaded yet.', 5, 'warning') end
			return
		end
		if callback then
			if inputService and inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
			old = bedwars.SprintController.stopSprinting
			bedwars.SprintController.stopSprinting = function(...)
				local call = old(...)
				pcall(function() bedwars.SprintController:startSprinting() end)
				return call
			end
			if entitylib.Events and entitylib.Events.LocalAdded then
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function()
					pcall(function() bedwars.SprintController:stopSprinting() end)
				end))
			end
			pcall(function() bedwars.SprintController:stopSprinting() end)
		else
			if inputService and inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
			if old then bedwars.SprintController.stopSprinting = old end
			pcall(function() bedwars.SprintController:stopSprinting() end)
		end
	end,
	Tooltip = 'Sets your sprinting to true.'
})





