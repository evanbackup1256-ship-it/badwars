local Invisible
local oldcf
local animtrack
local oldroot

local function animationTrickery()
	if entitylib.isAlive and entitylib.character and entitylib.character.Humanoid then
		local isR15 = entitylib.character.Humanoid.RigType == Enum.HumanoidRigType.R15
		local anim = Instance.new('Animation')
		anim.AnimationId = 'rbxassetid://'..(isR15 and '18537363391' or '215384594')
		local animator = entitylib.character.Humanoid:FindFirstChildOfClass('Animator')
		if animator then
			animtrack = animator:LoadAnimation(anim)
			animtrack.Priority = Enum.AnimationPriority.Action4
			animtrack:Play(0, 0.001, 0)
		end
		anim:Destroy()

		task.delay(0, function()
			if animtrack then
				animtrack.TimePosition = isR15 and 0.77 or 0.38
			end
		end)
	end
end

Invisible = Bad.Categories.Blatant:CreateModule({
	Name = 'Invisible',
	Function = function(callback)
		if callback then
			animationTrickery()

			oldcf = nil
			local bindKey = httpService:GenerateGUID(true)
			runService:BindToRenderStep(bindKey, 0, function()
				if entitylib.isAlive and oldcf and entitylib.character and entitylib.character.RootPart then
					entitylib.character.RootPart.CFrame = oldcf
					if animtrack then
						animtrack:AdjustWeight(0.001)
					end
				end
			end)

			Invisible:Clean(function()
				runService:UnbindFromRenderStep(bindKey)
			end)

			Invisible:Clean(runService.Heartbeat:Connect(function(dt)
				if entitylib.isAlive and entitylib.character and entitylib.character.RootPart and entitylib.character.Humanoid then
					local isR15 = entitylib.character.Humanoid.RigType == Enum.HumanoidRigType.R15
					local root = entitylib.character.RootPart
					local cf = root.CFrame - Vector3.new(0, (entitylib.character.Humanoid.HipHeight or 2) + (root.Size.Y / 2) - 1, 0)
					oldcf = root.CFrame

					root.CFrame = cf * CFrame.Angles(math.rad(isR15 and 180 or 90), 0, 0)
					if animtrack then
						animtrack:AdjustWeight(100)
					end
				end
			end))

			Invisible:Clean(entitylib.Events.LocalAdded:Connect(function(char)
				if char and char.Humanoid then
					local animator = char.Humanoid:FindFirstChildOfClass('Animator')
					if animator and Invisible.Enabled then
						oldroot = nil
						Invisible:Toggle()
						Invisible:Toggle()
					end
				end
			end))
		else
			if animtrack then
				animtrack:Stop()
				animtrack:Destroy()
			end

			if entitylib.isAlive and oldcf and entitylib.character and entitylib.character.RootPart then
				entitylib.character.RootPart.CFrame = oldcf
			end
		end
	end,
	Tooltip = 'Turns you invisible.'
})





