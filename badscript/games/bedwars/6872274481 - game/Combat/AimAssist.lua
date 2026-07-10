local Bad = shared.Bad or {}
local AimAssist
local Targets
local Sort
local AimSpeed
local Distance
local AngleSlider
local StrafeIncrease
local KillauraTarget
local ClickAim
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local runService = game:GetService('RunService')
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local targetinfo = (shared.Bad and shared.Bad.targetinfo) or {Targets = {}}
local sortmethods = (shared.Bad and shared.Bad.sortmethods) or {}
local inputService = game:GetService('UserInputService')
local store = (shared.Bad and shared.Bad.store) or {}
local gameCamera = workspace.CurrentCamera

AimAssist = Bad.Categories.Combat:CreateModule({
	Name = 'AimAssist',
	Function = function(callback)
		if callback then
			AimAssist:Clean(runService.Heartbeat:Connect(function(dt)
				if entitylib.isAlive and entitylib.character and entitylib.character.RootPart and store.hand and store.hand.toolType == 'sword' then
					local swingCheck = true
					if bedwars.SwordController then
						pcall(function() swingCheck = (tick() - (bedwars.SwordController.lastSwing or 0)) < 0.4 end)
					end
					if ((not ClickAim or not ClickAim.Enabled) or swingCheck) then
						local ent
						if not KillauraTarget or not KillauraTarget.Enabled then
							ent = entitylib.EntityPosition({
								Range = Distance and Distance.Value or 30,
								Part = 'RootPart',
								Wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled,
								Players = Targets and Targets.Players and Targets.Players.Enabled,
								NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled,
								Sort = sortmethods[Sort and Sort.Value or 'Distance']
							})
						else
							ent = store.KillauraTarget
						end

						if ent and ent.RootPart then
							local delta = (ent.RootPart.Position - entitylib.character.RootPart.Position)
							local flatDelta = delta * Vector3.new(1, 0, 1)
							local dot = localfacing:Dot(flatDelta.Unit)
							local angle = math.acos(math.clamp(dot, -1, 1))
							if angle >= (math.rad(AngleSlider and AngleSlider.Value or 70) / 2) then return end
							if targetinfo and targetinfo.Targets then targetinfo.Targets[ent] = tick() + 1 end
							local strafeBonus = (StrafeIncrease and StrafeIncrease.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 10 or 0)
							local aimSpeed = (AimSpeed and AimSpeed.Value or 6) + strafeBonus
							pcall(function()
								gameCamera.CFrame = gameCamera.CFrame:Lerp(CFrame.lookAt(gameCamera.CFrame.p, ent.RootPart.Position), aimSpeed * dt)
							end)
						end
					end
				end
			end))
		end
	end,
	Tooltip = 'Smoothly aims to closest valid target with sword'
})
Targets = AimAssist:CreateTargets({
	Players = true,
	Walls = true
})
local methods = {'Damage', 'Distance'}
for i in sortmethods do
	if not table.find(methods, i) then
		table.insert(methods, i)
	end
end
Sort = AimAssist:CreateDropdown({
	Name = 'Target Mode',
	List = methods
})
AimSpeed = AimAssist:CreateSlider({
	Name = 'Aim Speed',
	Min = 1,
	Max = 20,
	Default = 6
})
Distance = AimAssist:CreateSlider({
	Name = 'Distance',
	Min = 1,
	Max = 30,
	Default = 30,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
AngleSlider = AimAssist:CreateSlider({
	Name = 'Max angle',
	Min = 1,
	Max = 360,
	Default = 70
})
ClickAim = AimAssist:CreateToggle({
	Name = 'Click Aim',
	Default = true
})
KillauraTarget = AimAssist:CreateToggle({
	Name = 'Use killaura target'
})
StrafeIncrease = AimAssist:CreateToggle({Name = 'Strafe increase'})





