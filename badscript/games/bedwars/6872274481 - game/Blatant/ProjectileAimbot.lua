local TargetPart
local Targets
local FOV
local OtherProjectiles
local rayCheck = RaycastParams.new()
rayCheck.FilterType = Enum.RaycastFilterType.Include
pcall(function()
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
end)
local old
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local targetinfo = (shared.Bad and shared.Bad.targetinfo) or {Targets = {}}
local prediction = (shared.Bad and shared.Bad.libraries and shared.Bad.libraries.prediction) or {}
local collectionService = game:GetService('CollectionService')

local ProjectileAimbot = Bad.Categories.Blatant:CreateModule({
	Name = 'ProjectileAimbot',
	Function = function(callback)
		if callback then
			if bedwars.ProjectileController and bedwars.ProjectileController.calculateImportantLaunchValues then
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
					local self, projmeta, worldmeta, origin, shootpos = ...
					local plr = entitylib.EntityMouse({
						Part = 'RootPart',
						Range = FOV and FOV.Value or 1000,
						Players = Targets and Targets.Players and Targets.Players.Enabled,
						NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled,
						Wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled,
						Origin = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					})

					if plr then
						local pos = shootpos or (self and self.getLaunchPosition and self:getLaunchPosition(origin))
						if not pos then
							return old(...)
						end

						if (not OtherProjectiles or not OtherProjectiles.Enabled) and projmeta and projmeta.projectile and not projmeta.projectile:find('arrow') then
							return old(...)
						end

						local meta = projmeta and projmeta.getProjectileMeta and projmeta:getProjectileMeta()
						if not meta then return old(...) end
						local lifetime = (worldmeta and meta.predictionLifetimeSec) or meta.lifetimeSec or 3
						local gravity = (meta.gravitationalAcceleration or 196.2) * (projmeta.gravityMultiplier or 1)
						local projSpeed = meta.launchVelocity or 100
						local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or (projmeta.fromPositionOffset or Vector3.zero))
						local balloons = plr.Character and plr.Character:GetAttribute('InflatedBalloons')
						local playerGravity = workspace.Gravity

						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end

						if plr.Character and plr.Character.PrimaryPart then
							pcall(function()
								if plr.Character.PrimaryPart:FindFirstChild('rbxassetid://8200754399') then
									playerGravity = 6
								end
							end)
						end

						if plr.Player and plr.Player:GetAttribute('IsOwlTarget') then
							pcall(function()
								for _, owl in collectionService:GetTagged('Owl') do
									if owl:GetAttribute('Target') == plr.Player.UserId and owl:GetAttribute('Status') == 2 then
										playerGravity = 0
									end
								end
							end)
						end

						local targetPartName = TargetPart and TargetPart.Value or 'RootPart'
						local targetPart = plr[targetPartName]
						if not targetPart then return old(...) end

						local newlook = CFrame.new(offsetpos, targetPart.Position) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelX or 0, bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelY or 0, bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelZ or 0))
						local calc = prediction.SolveTrajectory and prediction.SolveTrajectory(newlook.p, projSpeed, gravity, targetPart.Position, projmeta.projectile == 'telepearl' and Vector3.zero or targetPart.Velocity, playerGravity, plr.HipHeight or 2, plr.Jumping and 42.6 or nil, rayCheck)
						if calc then
							if targetinfo and targetinfo.Targets then targetinfo.Targets[plr] = tick() + 1 end
							return {
								initialVelocity = CFrame.new(newlook.Position, calc).LookVector * projSpeed,
								positionFrom = offsetpos,
								deltaT = lifetime,
								gravitationalAcceleration = gravity,
								drawDurationSeconds = 5
							}
						end
					end

					return old(...)
				end
			end
		else
			if old and bedwars.ProjectileController then
				bedwars.ProjectileController.calculateImportantLaunchValues = old
			end
		end
	end,
	Tooltip = 'Silently adjusts your aim towards the enemy'
})
Targets = ProjectileAimbot:CreateTargets({
	Players = true,
	Walls = true
})
TargetPart = ProjectileAimbot:CreateDropdown({
	Name = 'Part',
	List = {'RootPart', 'Head'}
})
FOV = ProjectileAimbot:CreateSlider({
	Name = 'FOV',
	Min = 1,
	Max = 1000,
	Default = 1000
})
OtherProjectiles = ProjectileAimbot:CreateToggle({
	Name = 'Other Projectiles',
	Default = true
})





