local Freecam
local Value
local randomkey, module, old = httpService:GenerateGUID(false)

Freecam = Bad.Categories.World:CreateModule({
	Name = 'Freecam',
	Function = function(callback)
		if callback then
			repeat
				task.wait(0.1)
				if gameCamera then
					for _, v in getconnections and getconnections(gameCamera:GetPropertyChangedSignal('CameraType')) or {} do
						if v and v.Function then
							module = debug.getupvalue(v.Function, 1)
						end
					end
				end
			until module or not Freecam or not Freecam.Enabled

			if module and module.activeCameraController and Freecam.Enabled then
				old = module.activeCameraController.GetSubjectPosition
				local camPos = old(module.activeCameraController) or Vector3.zero
				module.activeCameraController.GetSubjectPosition = function()
					return camPos
				end

				Freecam:Clean(runService.PreSimulation:Connect(function(dt)
					if inputService and not inputService:GetFocusedTextBox() and gameCamera then
						local forward = (inputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (inputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
						local side = (inputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + (inputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
						local up = (inputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0) + (inputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
						dt = dt * (inputService:IsKeyDown(Enum.KeyCode.LeftShift) and 0.25 or 1)
						camPos = (CFrame.lookAlong(camPos, gameCamera.CFrame.LookVector) * CFrame.new(Vector3.new(side, up, forward) * ((Value and Value.Value or 50) * dt))).Position
					end
				end))

				if contextService then
					contextService:BindActionAtPriority('FreecamKeyboard'..randomkey, function()
						return Enum.ContextActionResult.Sink
					end, false, Enum.ContextActionPriority.High.Value,
						Enum.KeyCode.W,
						Enum.KeyCode.A,
						Enum.KeyCode.S,
						Enum.KeyCode.D,
						Enum.KeyCode.E,
						Enum.KeyCode.Q,
						Enum.KeyCode.Up,
						Enum.KeyCode.Down
					)
				end
			end
		else
			pcall(function()
				if contextService then
					contextService:UnbindAction('FreecamKeyboard'..randomkey)
				end
			end)
			if module and old then
				module.activeCameraController.GetSubjectPosition = old
				module = nil
				old = nil
			end
		end
	end,
	Tooltip = 'Lets you fly and clip through walls freely\nwithout moving your player server-sided.'
})
Value = Freecam:CreateSlider({
	Name = 'Speed',
	Min = 1,
	Max = 150,
	Default = 50,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})





