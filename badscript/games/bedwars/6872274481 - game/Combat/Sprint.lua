local Sprint
local old
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local inputService = game:GetService('UserInputService')
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}

Sprint = Bad.Categories.Combat:CreateModule({
	Name = 'Sprint',
	Function = function(callback)
		if bedwars.SprintController then
			if callback then
				if inputService.TouchEnabled then 
					pcall(function() 
						if lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('MobileUI') then
							lplr.PlayerGui.MobileUI['4'].Visible = false 
						end
					end) 
				end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					pcall(function() bedwars.SprintController:startSprinting() end)
					return call
				end
				if entitylib.Events then
					Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() 
						task.delay(0.1, function() 
							pcall(function() bedwars.SprintController:stopSprinting() end)
						end) 
					end))
				end
				pcall(function() bedwars.SprintController:stopSprinting() end)
			else
				if inputService.TouchEnabled then 
					pcall(function() 
						if lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('MobileUI') then
							lplr.PlayerGui.MobileUI['4'].Visible = true 
						end
					end) 
				end
				if old then
					bedwars.SprintController.stopSprinting = old
				end
				pcall(function() bedwars.SprintController:stopSprinting() end)
			end
		end
	end,
	Tooltip = 'Sets your sprinting to true.'
})





