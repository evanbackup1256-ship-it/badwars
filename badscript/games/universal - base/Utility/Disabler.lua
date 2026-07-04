local Disabler

local function characterAdded(char)
	if not char or not char.RootPart then return end
	for _, v in getconnections and getconnections(char.RootPart:GetPropertyChangedSignal('CFrame')) or {} do
		if hookfunction and v and v.Function then
			hookfunction(v.Function, function() end)
		end
	end

	for _, v in getconnections and getconnections(char.RootPart:GetPropertyChangedSignal('Velocity')) or {} do
		if hookfunction and v and v.Function then
			hookfunction(v.Function, function() end)
		end
	end
end

Disabler = Bad.Categories.Utility:CreateModule({
	Name = 'Disabler',
	Function = function(callback)
		if callback then
			Disabler:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
			if entitylib.isAlive and entitylib.character then
				characterAdded(entitylib.character)
			end
		end
	end,
	Tooltip = 'Disables GetPropertyChangedSignal detections for movement'
})





