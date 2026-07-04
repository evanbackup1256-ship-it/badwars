local FOV
local Value
local oldfov

FOV = Bad.Legit:CreateModule({
	Name = 'FOV',
	Function = function(callback)
		if callback then
			oldfov = gameCamera and gameCamera.FieldOfView
			repeat
				if gameCamera then
					gameCamera.FieldOfView = Value and Value.Value or 70
				end
				task.wait()
			until not FOV or not FOV.Enabled
		else
			if gameCamera and oldfov then
				gameCamera.FieldOfView = oldfov
			end
		end
	end,
	Tooltip = 'Adjusts camera vision'
})
Value = FOV:CreateSlider({
	Name = 'FOV',
	Min = 30,
	Max = 120
})





