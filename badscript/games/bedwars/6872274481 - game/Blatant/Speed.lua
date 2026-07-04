local Speed
local Value
local WallCheck
local AutoJump
local AlwaysJump
local rayCheck = RaycastParams.new()
rayCheck.RespectCanCollide = true
local frictionTable = {}
local updateVelocity = function() end
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local runService = game:GetService('RunService')
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local getSpeed = (shared.Bad and shared.Bad.getSpeed) or function() return 0 end
local Fly, InfiniteFly, LongJump, Attacking
local AntiFallDirection

Speed = Bad.Categories.Blatant:CreateModule({
	Name = 'Speed',
	Function = function(callback)
		frictionTable.Speed = callback or nil
		updateVelocity()
		pcall(function()
			if bedwars.WindWalkerController and bedwars.WindWalkerController.updateSpeed then
				debug.setconstant(bedwars.WindWalkerController.updateSpeed, 7, callback and 'constantSpeedMultiplier' or 'moveSpeedMultiplier')
			end
		end)

		if callback then
			Speed:Clean(runService.PreSimulation:Connect(function(dt)
				if bedwars.StatefulEntityKnockbackController then
					bedwars.StatefulEntityKnockbackController.lastImpulseTime = callback and math.huge or time()
				end
				if entitylib.isAlive and entitylib.character and entitylib.character.RootPart and entitylib.character.Humanoid and not (Fly and Fly.Enabled) and not (InfiniteFly and InfiniteFly.Enabled) and not (LongJump and LongJump.Enabled) and (isnetworkowner and isnetworkowner(entitylib.character.RootPart) or true) then
					local state = entitylib.character.Humanoid:GetState()
					if state == Enum.HumanoidStateType.Climbing then return end

					local root = entitylib.character.RootPart
					local velo = getSpeed()
					local moveDirection = AntiFallDirection or entitylib.character.Humanoid.MoveDirection
					local destination = (moveDirection * math.max((Value and Value.Value or 23) - velo, 0) * dt)

					if WallCheck and WallCheck.Enabled then
						rayCheck.FilterDescendantsInstances = {lplr.Character, game:GetService('Workspace').CurrentCamera}
						rayCheck.CollisionGroup = root.CollisionGroup
						local ray = workspace:Raycast(root.Position, destination, rayCheck)
						if ray then
							destination = ((ray.Position + ray.Normal) - root.Position)
						end
					end

					root.CFrame += destination
					root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
					if AutoJump and AutoJump.Enabled and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed) and moveDirection ~= Vector3.zero and (Attacking or (AlwaysJump and AlwaysJump.Enabled)) then
						entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
					end
				end
			end))
		end
	end,
	ExtraText = function()
		return 'Heatseeker'
	end,
	Tooltip = 'Increases your movement with various methods.'
})
Value = Speed:CreateSlider({
	Name = 'Speed',
	Min = 1,
	Max = 23,
	Default = 23,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
WallCheck = Speed:CreateToggle({
	Name = 'Wall Check',
	Default = true
})
AutoJump = Speed:CreateToggle({
	Name = 'AutoJump',
	Function = function(callback)
		if AlwaysJump and AlwaysJump.Object then
			AlwaysJump.Object.Visible = callback
		end
	end
})
AlwaysJump = Speed:CreateToggle({
	Name = 'Always Jump',
	Visible = false,
	Darker = true
})





