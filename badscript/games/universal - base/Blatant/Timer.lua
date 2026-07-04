local Timer
local Value

Timer = Bad.Categories.Blatant:CreateModule({
	Name = 'Timer',
	Function = function(callback)
		if callback then
			local canStep = type(workspace.StepPhysics) == 'function'
				and type(runService.Pause) == 'function'
				and type(runService.Run) == 'function'
			if not canStep then
				notif('Timer', 'step physics is unavailable in this executor/client', 6, 'warning')
				Timer:Toggle()
				return
			end
			if type(setfflag) == 'function' then
				pcall(setfflag, 'SimEnableStepPhysics', 'True')
				pcall(setfflag, 'SimEnableStepPhysicsSelective', 'True')
			end

			Timer:Clean(runService.RenderStepped:Connect(function(dt)
				if Value.Value > 1 then
					local root = entitylib and entitylib.character and entitylib.character.RootPart
					if not root then return end
					runService:Pause()
					workspace:StepPhysics(dt * (Value.Value - 1), {root})
					runService:Run()
				end
			end))
		end
	end,
	Tooltip = 'Change the game speed.'
})
Value = Timer:CreateSlider({
	Name = 'Value',
	Min = 1,
	Max = 3,
	Decimal = 10
})





