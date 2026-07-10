local TargetStrafe
local Targets
local SearchRange
local StrafeRange
local YFactor
local rayCheck = RaycastParams.new()
rayCheck.RespectCanCollide = true
local module, old
local ang = 0
local oldent = nil

TargetStrafe = Bad.Categories.Blatant:CreateModule({
	Name = 'TargetStrafe',
	Function = function(callback)
		if callback then
			if not module then
				local suc = pcall(function() module = require(lplr and lplr.PlayerScripts and lplr.PlayerScripts:FindFirstChild('PlayerModule') and lplr.PlayerScripts.PlayerModule).controls end)
				if not suc then
					module = {}
				end
			end

			old = module.moveFunction
			local flymod = Bad and Bad.Modules and Bad.Modules.Fly or {Enabled = false}
			module.moveFunction = function(self, vec, face)
				local wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled
				local ent = inputService and not inputService:IsKeyDown(Enum.KeyCode.S) and entitylib.EntityPosition({
					Range = SearchRange and SearchRange.Value or 24,
					Wallcheck = wallcheck,
					Part = 'RootPart',
					Players = Targets and Targets.Players and Targets.Players.Enabled,
					NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled
				})

				if ent and ent.RootPart and entitylib.character and entitylib.character.RootPart then
					local root = entitylib.character.RootPart
					local targetPos = ent.RootPart.Position
					rayCheck.FilterDescendantsInstances = {lplr and lplr.Character, gameCamera, ent.Character}
					rayCheck.CollisionGroup = root.CollisionGroup

					if flymod.Enabled or workspace:Raycast(targetPos, Vector3.new(0, -70, 0), rayCheck) then
						local factor, localPosition = 0, root.Position
						if ent ~= oldent then
							ang = math.deg(select(2, CFrame.lookAt(targetPos, localPosition):ToEulerAnglesYXZ()))
						end

						local yFactor = math.abs(localPosition.Y - targetPos.Y) * ((YFactor and YFactor.Value or 100) / 100)
						local entityPos = Vector3.new(targetPos.X, localPosition.Y, targetPos.Z)
						local newPos = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * ((StrafeRange and StrafeRange.Value or 18) - yFactor))
						local startRay, endRay = entityPos, newPos

						if not wallcheck and workspace:Raycast(targetPos, (localPosition - targetPos), rayCheck) then
							startRay, endRay = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * (entityPos - localPosition).Magnitude), entityPos
						end

						local ray = workspace:Blockcast(CFrame.new(startRay), Vector3.new(1, (entitylib.character.HipHeight or 2) + (root.Size.Y / 2), 1), (endRay - startRay), rayCheck)
						if (localPosition - newPos).Magnitude < 3 or ray then
							factor = (8 - math.min((localPosition - newPos).Magnitude, 3))
							if ray then
								newPos = ray.Position + (ray.Normal * 1.5)
								factor = (localPosition - newPos).Magnitude > 3 and 0 or factor
							end
						end

						if not flymod.Enabled and not workspace:Raycast(newPos, Vector3.new(0, -70, 0), rayCheck) then
							newPos = entityPos
							factor = 40
						end

						ang += factor % 360
						vec = ((newPos - localPosition) * Vector3.new(1, 0, 1)).Unit
						vec = vec == vec and vec or Vector3.zero
						TargetStrafeVector = vec
					else
						ent = nil
					end
				end

				TargetStrafeVector = ent and vec or nil
				oldent = ent

				return old and old(self, vec, face)
			end
		else
			if module and old then
				module.moveFunction = old
			end
			TargetStrafeVector = nil
		end
	end,
	Tooltip = 'Automatically strafes around the opponent'
})
Targets = TargetStrafe:CreateTargets({
	Players = true,
	Walls = true
})
SearchRange = TargetStrafe:CreateSlider({
	Name = 'Search Range',
	Min = 1,
	Max = 30,
	Default = 24,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
StrafeRange = TargetStrafe:CreateSlider({
	Name = 'Strafe Range',
	Min = 1,
	Max = 30,
	Default = 18,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
YFactor = TargetStrafe:CreateSlider({
	Name = 'Y Factor',
	Min = 0,
	Max = 100,
	Default = 100,
	Suffix = '%'
})





