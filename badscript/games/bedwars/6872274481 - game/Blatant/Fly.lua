local Fly
local LongJump
run(function()
	local Value
	local VerticalValue
	local WallCheck
	local PopBalloons
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local up, down, old = 0, 0

	local function safeGetAttribute(char, attr)
		if not char then return 0 end
		local val = char:GetAttribute(attr)
		return type(val) == 'number' and val or 0
	end

	Fly = Bad.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			frictionTable.Fly = callback or nil
			updateVelocity()
			if callback then
				up, down, old = 0, 0, nil
				if bedwars and bedwars.BalloonController then
					old = bedwars.BalloonController.deflateBalloon
					bedwars.BalloonController.deflateBalloon = function() end
				end
				local tpTick, tpToggle, oldy = tick(), true

				if lplr.Character and safeGetAttribute(lplr.Character, 'InflatedBalloons') == 0 and getItem and getItem('balloon') then
					if bedwars and bedwars.BalloonController then
						pcall(function() bedwars.BalloonController:inflateBalloon() end)
					end
				end
				if lplr.Character then
					local charAttr = lplr.Character:GetAttribute('InflatedBalloons')
					local charEvents = lplr.Character
					if charEvents then
						Fly:Clean(charEvents:GetAttributeChangedSignal('InflatedBalloons'):Connect(function()
							if safeGetAttribute(lplr.Character, 'InflatedBalloons') == 0 and getItem and getItem('balloon') then
								if bedwars and bedwars.BalloonController then
									pcall(function() bedwars.BalloonController:inflateBalloon() end)
								end
							end
						end))
					end
				end
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not (InfiniteFly and InfiniteFly.Enabled) and isnetworkowner(entitylib.character.RootPart) then
						local flyAllowed = (safeGetAttribute(lplr.Character, 'InflatedBalloons') > 0) or (store and store.matchState == 2)
						local mass = (1.5 + (flyAllowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)) + ((up + down) * VerticalValue.Value)
						local root, moveDirection = entitylib.character.RootPart, entitylib.character.Humanoid.MoveDirection
						local velo = getSpeed and getSpeed() or 0
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
						local filterInstances = {lplr.Character, gameCamera}
						if AntiFallPart then table.insert(filterInstances, AntiFallPart) end
						rayCheck.FilterDescendantsInstances = filterInstances
						rayCheck.CollisionGroup = root.CollisionGroup

						if WallCheck.Enabled then
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end

						if not flyAllowed then
							if tpToggle then
								local airleft = (tick() - entitylib.character.AirTime)
								if airleft > 2 then
									if not oldy then
										local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
										if ray and TP.Enabled then
											tpToggle = false
											oldy = root.Position.Y
											tpTick = tick() + 0.11
											root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
										end
									end
								end
							else
								if oldy then
									if tpTick < tick() then
										local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
										root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
										tpToggle = true
										oldy = nil
									else
										mass = 0
									end
								end
							end
						end

						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, mass, 0)
					end
				end))
				Fly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				Fly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local touchGui = lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('TouchGui')
						local touchControl = touchGui and touchGui:FindFirstChild('TouchControlFrame')
						local jumpButton = touchControl and touchControl:FindFirstChild('JumpButton')
						if jumpButton then
							Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
								up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
							end))
						end
					end)
				end
			else
				if old and bedwars and bedwars.BalloonController then
					bedwars.BalloonController.deflateBalloon = old
				end
				if PopBalloons.Enabled and entitylib.isAlive and safeGetAttribute(lplr.Character, 'InflatedBalloons') > 0 then
					if bedwars and bedwars.BalloonController then
						for _ = 1, 3 do
							pcall(function() bedwars.BalloonController:deflateBalloon() end)
						end
					end
				end
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Fly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	PopBalloons = Fly:CreateToggle({
		Name = 'Pop Balloons',
		Default = true
	})
	TP = Fly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)
