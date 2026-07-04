local HighJump
local Mode
local Value
local AutoDisable

local function jump()
	if not entitylib.isAlive or not entitylib.character or not entitylib.character.Humanoid or not entitylib.character.RootPart then return end
	local state = entitylib.character.Humanoid:GetState()

	if state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed then
		local root = entitylib.character.RootPart

		if Mode and Mode.Value == 'Velocity' then
			entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, Value and Value.Value or 50, root.AssemblyLinearVelocity.Z)
		elseif Mode and Mode.Value == 'Impulse' then
			entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.delay(0, function()
				root:ApplyImpulse(Vector3.new(0, (Value and Value.Value or 50) - root.AssemblyLinearVelocity.Y, 0) * root.AssemblyMass)
			end)
		else
			local yLevel = math.max((Value and Value.Value or 50) - entitylib.character.Humanoid.JumpHeight, 0)

			repeat
				root.CFrame += Vector3.new(0, yLevel * 0.016, 0)
				yLevel = yLevel - (workspace.Gravity * 0.016)

				if Mode and Mode.Value == 'CFrame' then
					task.wait()
				end
			until yLevel <= 0
		end
	end
end

HighJump = Bad.Categories.Blatant:CreateModule({
	Name = 'HighJump',
	Function = function(callback)
		if callback then
			if AutoDisable and AutoDisable.Enabled then
				jump()
				HighJump:Toggle()
			else
				HighJump:Clean(runService.RenderStepped:Connect(function()
					if inputService and not inputService:GetFocusedTextBox() and inputService:IsKeyDown(Enum.KeyCode.Space) then
						jump()
					end
				end))
			end
		end
	end,
	ExtraText = function()
		return Mode.Value
	end,
	Tooltip = 'Lets you jump higher'
})
Mode = HighJump:CreateDropdown({
	Name = 'Mode',
	List = {'Impulse', 'Velocity', 'CFrame', 'Instant'},
	Tooltip = 'Velocity - Uses smooth movement to boost you upward\nImpulse - Same as velocity while using forces instead\nCFrame - Directly adjusts the position upward\nInstant - Teleports you to the peak of the jump'
})
Value = HighJump:CreateSlider({
	Name = 'Velocity',
	Min = 1,
	Max = 150,
	Default = 50,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
AutoDisable = HighJump:CreateToggle({
	Name = 'Auto Disable',
	Default = true
})





