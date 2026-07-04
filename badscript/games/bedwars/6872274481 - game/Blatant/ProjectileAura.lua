local ProjectileAura
local Targets
local Range
local List
local rayCheck = RaycastParams.new()
rayCheck.FilterType = Enum.RaycastFilterType.Include
local projectileRemote = {InvokeServer = function() end}
local FireDelays = {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local targetinfo = (shared.Bad and shared.Bad.targetinfo) or {Targets = {}}
local prediction = (shared.Bad and shared.Bad.libraries and shared.Bad.libraries.prediction) or {}
local httpService = game:GetService('HttpService')
local switchItem = (shared.Bad and shared.Bad.switchItem) or function() return false end
local store = (shared.Bad and shared.Bad.store) or {}
task.spawn(function()
	pcall(function()
		if bedwars.Client and remotes and remotes.FireProjectile then
			projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
		end
	end)
end)

local function getAmmo(check)
	if not store or not store.inventory or not store.inventory.inventory or not store.inventory.inventory.items then return nil end
	for _, item in store.inventory.inventory.items do
		if check and check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
			return item.itemType
		end
	end
end

local function getProjectiles()
	local items = {}
	if not store or not store.inventory or not store.inventory.inventory or not store.inventory.inventory.items then return items end
	for _, item in store.inventory.inventory.items do
		if bedwars.ItemMeta then
			local proj = bedwars.ItemMeta[item.itemType] and bedwars.ItemMeta[item.itemType].projectileSource
			local ammo = proj and getAmmo(proj)
			if ammo and List and List.ListEnabled and table.find(List.ListEnabled, ammo) then
				table.insert(items, {
					item,
					ammo,
					proj.projectileType and proj.projectileType(ammo),
					proj
				})
			end
		end
	end
	return items
end

ProjectileAura = Bad.Categories.Blatant:CreateModule({
	Name = 'ProjectileAura',
	Function = function(callback)
		if callback then
			repeat
				if bedwars.SwordController then
					pcall(function()
						if (workspace:GetServerTimeNow() - (bedwars.SwordController.lastAttack or 0)) > 0.5 then
							local ent = entitylib.EntityPosition({
								Part = 'RootPart',
								Range = Range and Range.Value or 50,
								Players = Targets and Targets.Players and Targets.Players.Enabled,
								NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled,
								Wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled
							})

							if ent and ent.RootPart and entitylib.character and entitylib.character.RootPart then
								local pos = entitylib.character.RootPart.Position
								for _, data in getProjectiles() do
									local item, ammo, projectile, itemMeta = unpack(data)
									if (FireDelays[item.itemType] or 0) < tick() then
										rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
										if bedwars.ProjectileMeta then
											local meta = bedwars.ProjectileMeta[projectile]
											if meta then
												local projSpeed = meta.launchVelocity or 100
												local gravity = meta.gravitationalAcceleration or 196.2
												local calc = prediction.SolveTrajectory and prediction.SolveTrajectory(pos, projSpeed, gravity, ent.RootPart.Position, ent.RootPart.Velocity, workspace.Gravity, ent.HipHeight or 2, ent.Jumping and 42.6 or nil, rayCheck)
												if calc then
													if targetinfo and targetinfo.Targets then targetinfo.Targets[ent] = tick() + 1 end
													local switched = switchItem(item.tool)

													task.spawn(function()
														local dir = CFrame.lookAt(pos, calc).LookVector
														local id = httpService:GenerateGUID(true)
														local shootPosition = (CFrame.new(pos, calc) * CFrame.new(Vector3.new(-(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelX or 0), -(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelY or 0), -(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelZ or 0)))).Position
														if bedwars.ProjectileController then
															pcall(function() bedwars.ProjectileController:createLocalProjectile(meta, ammo, projectile, shootPosition, id, dir * projSpeed, {drawDurationSeconds = 1}) end)
														end
														local res = pcall(function() return projectileRemote:InvokeServer(item.tool, ammo, projectile, shootPosition, pos, dir * projSpeed, id, {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045) end)
														if not res then
															FireDelays[item.itemType] = tick()
														else
															if itemMeta and itemMeta.launchSound then
																local shoot = itemMeta.launchSound[math.random(1, #itemMeta.launchSound)]
																if shoot and bedwars.SoundManager then
																	pcall(function() bedwars.SoundManager:playSound(shoot) end)
																end
															end
														end
													end)

													FireDelays[item.itemType] = tick() + (itemMeta and itemMeta.fireDelaySec or 0.5)
													if switched then
														task.wait(0.05)
													end
												end
											end
										end
									end
								end
							end
						end
					end)
				end
				task.wait(0.1)
			until not ProjectileAura or not ProjectileAura.Enabled
		end
	end,
	Tooltip = 'Shoots people around you'
})
Targets = ProjectileAura:CreateTargets({
	Players = true,
	Walls = true
})
List = ProjectileAura:CreateTextList({
	Name = 'Projectiles',
	Default = {'arrow', 'snowball'}
})
Range = ProjectileAura:CreateSlider({
	Name = 'Range',
	Min = 1,
	Max = 50,
	Default = 50,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})





