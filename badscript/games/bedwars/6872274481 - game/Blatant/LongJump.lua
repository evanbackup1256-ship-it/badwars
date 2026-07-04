local Value
local CameraDir
local start
local JumpTick, JumpSpeed, Direction = tick(), 0
local projectileRemote = {InvokeServer = function() end}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local runService = game:GetService('RunService')
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local httpService = game:GetService('HttpService')
local replicatedStorage = game:GetService('ReplicatedStorage')
local frictionTable = {}
local updateVelocity = function() end
local getItem = (shared.Bad and shared.Bad.getItem) or function() return nil end
local switchItem = (shared.Bad and shared.Bad.switchItem) or function() return false end
local getPlacedBlock = (shared.Bad and shared.Bad.getPlacedBlock) or function() return nil end
local BadEvents = (shared.Bad and shared.Bad.BadEvents) or {}
local store = (shared.Bad and shared.Bad.store) or {}
task.spawn(function()
	pcall(function()
		if bedwars.Client and remotes and remotes.FireProjectile then
			projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
		end
	end)
end)

local function launchProjectile(item, pos, proj, speed, dir)
	if not pos then return end

	pos = pos - dir * 0.1
	local shootPosition = (CFrame.lookAlong(pos, Vector3.new(0, -speed, 0)) * CFrame.new(Vector3.new(-(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelX or 0), -(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelY or 0), -(bedwars.BowConstantsTable and bedwars.BowConstantsTable.RelZ or 0))))
	switchItem(item.tool, 0)
	task.wait(0.1)
	if bedwars.ProjectileController and bedwars.ProjectileMeta then
		pcall(function()
			bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta[proj], proj, proj, shootPosition.Position, '', shootPosition.LookVector * speed, {drawDurationSeconds = 1})
		end)
	end
	local res = pcall(function() return projectileRemote:InvokeServer(item.tool, proj, proj, shootPosition.Position, pos, shootPosition.LookVector * speed, httpService:GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045) end)
	if res then
		if bedwars.ItemMeta and bedwars.ItemMeta[item.itemType] and bedwars.ItemMeta[item.itemType].projectileSource and bedwars.ItemMeta[item.itemType].projectileSource.launchSound then
			local shoot = bedwars.ItemMeta[item.itemType].projectileSource.launchSound
			shoot = shoot and shoot[math.random(1, #shoot)] or nil
			if shoot and bedwars.SoundManager then
				pcall(function() bedwars.SoundManager:playSound(shoot) end)
			end
		end
	end
end

local LongJumpMethods = {
	cannon = function(_, pos, dir)
		if not pos then return end
		pos = pos - Vector3.new(0, ((entitylib.character and entitylib.character.HipHeight or 2) + ((entitylib.character and entitylib.character.RootPart and entitylib.character.RootPart.Size.Y / 2) or 1.5)) - 3, 0)
		local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
		if bedwars.placeBlock then pcall(function() bedwars.placeBlock(rounded, 'cannon', false) end) end

		task.delay(0, function()
			local block, blockpos = getPlacedBlock(rounded)
			if block and block.Name == 'cannon' and entitylib.character and entitylib.character.RootPart and (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
				local breaktype = bedwars.ItemMeta and bedwars.ItemMeta[block.Name] and bedwars.ItemMeta[block.Name].block and bedwars.ItemMeta[block.Name].block.breakType
				local tool = store.tools and store.tools[breaktype]
				if tool then
					switchItem(tool.tool)
				end

				if bedwars.Client and remotes and remotes.CannonAim then
					pcall(function()
						bedwars.Client:Get(remotes.CannonAim):SendToServer({
							cannonBlockPos = blockpos,
							lookVector = dir
						})
					end)
				end

				local broken = 0.1
				if bedwars.BlockController then
					pcall(function()
						if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
							broken = 0.4
							if bedwars.breakBlock then bedwars.breakBlock(block, true, true) end
						end
					end)
				end

				task.delay(broken, function()
					for _ = 1, 3 do
						local call = false
						if bedwars.Client and remotes and remotes.CannonLaunch then
							pcall(function() call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos}) end)
						end
						if call then
							if bedwars.breakBlock then bedwars.breakBlock(block, true, true) end
							JumpSpeed = 5.25 * (Value and Value.Value or 37)
							JumpTick = tick() + 2.3
							Direction = Vector3.new(dir.X, 0, dir.Z).Unit
							break
						end
						task.wait(0.1)
					end
				end)
			end
		end)
	end,
	cat = function(_, _, dir)
		if BadEvents.CatPounce then
			LongJump:Clean(BadEvents.CatPounce.Event:Connect(function()
				JumpSpeed = 4 * (Value and Value.Value or 37)
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
				if entitylib.character and entitylib.character.RootPart then
					entitylib.character.RootPart.Velocity = Vector3.zero
				end
			end))
		end

		if bedwars.AbilityController then
			local canUse = false
			pcall(function() canUse = bedwars.AbilityController:canUseAbility('CAT_POUNCE') end)
			if not canUse then
				repeat task.wait() until (pcall(function() return bedwars.AbilityController:canUseAbility('CAT_POUNCE') end)) or not (LongJump and LongJump.Enabled)
			end

			canUse = false
			pcall(function() canUse = bedwars.AbilityController:canUseAbility('CAT_POUNCE') end)
			if canUse and LongJump and LongJump.Enabled then
				pcall(function() bedwars.AbilityController:useAbility('CAT_POUNCE') end)
			end
		end
	end,
	fireball = function(item, pos, dir)
		launchProjectile(item, pos, 'fireball', 60, dir)
	end,
	grappling_hook = function(item, pos, dir)
		launchProjectile(item, pos, 'grappling_hook_projectile', 140, dir)
	end,
	jade_hammer = function(item, _, dir)
		if bedwars.AbilityController then
			local canUse = false
			pcall(function() canUse = bedwars.AbilityController:canUseAbility(item.itemType..'_jump') end)
			if not canUse then
				repeat task.wait() until (pcall(function() return bedwars.AbilityController:canUseAbility(item.itemType..'_jump') end)) or not (LongJump and LongJump.Enabled)
			end

			canUse = false
			pcall(function() canUse = bedwars.AbilityController:canUseAbility(item.itemType..'_jump') end)
			if canUse and LongJump and LongJump.Enabled then
				pcall(function() bedwars.AbilityController:useAbility(item.itemType..'_jump') end)
				JumpSpeed = 1.4 * (Value and Value.Value or 37)
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
			end
		end
	end,
	tnt = function(item, pos, dir)
		if not pos then return end
		pos = pos - Vector3.new(0, ((entitylib.character and entitylib.character.HipHeight or 2) + ((entitylib.character and entitylib.character.RootPart and entitylib.character.RootPart.Size.Y / 2) or 1.5)) - 3, 0)
		local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
		if start then
			start = Vector3.new(rounded.X, start.Y, rounded.Z) + (dir * (item.itemType == 'pirate_gunpowder_barrel' and 2.6 or 0.2))
		end
		if bedwars.placeBlock then pcall(function() bedwars.placeBlock(rounded, item.itemType, false) end) end
	end,
	wood_dao = function(item, pos, dir)
		local canDash = false
		if lplr.Character then
			canDash = (lplr.Character:GetAttribute('CanDashNext') or 0) > workspace:GetServerTimeNow()
		end
		local canUseDash = false
		if bedwars.AbilityController then
			pcall(function() canUseDash = bedwars.AbilityController:canUseAbility('dash') end)
		end
		if canDash or not canUseDash then
			repeat task.wait() until (not ((lplr.Character:GetAttribute('CanDashNext') or 0) > workspace:GetServerTimeNow())) and (pcall(function() return bedwars.AbilityController:canUseAbility('dash') end)) or not (LongJump and LongJump.Enabled)
		end

		if LongJump and LongJump.Enabled then
			if bedwars.SwordController then
				pcall(function() bedwars.SwordController.lastAttack = workspace:GetServerTimeNow() end)
			end
			switchItem(item.tool, 0.1)
			local events = replicatedStorage:FindFirstChild('events-@easy-games/game-core:shared/game-core-networking@getEvents.Events')
			if events then
				pcall(function() events.useAbility:FireServer('dash', {
					direction = dir,
					origin = pos,
					weapon = item.itemType
				}) end)
			end
			JumpSpeed = 4.5 * (Value and Value.Value or 37)
			JumpTick = tick() + 2.4
			Direction = Vector3.new(dir.X, 0, dir.Z).Unit
		end
	end
}
for _, v in {'stone_dao', 'iron_dao', 'diamond_dao', 'emerald_dao'} do
	LongJumpMethods[v] = LongJumpMethods.wood_dao
end
LongJumpMethods.void_axe = LongJumpMethods.jade_hammer
LongJumpMethods.siege_tnt = LongJumpMethods.tnt
LongJumpMethods.pirate_gunpowder_barrel = LongJumpMethods.tnt

LongJump = Bad.Categories.Blatant:CreateModule({
	Name = 'LongJump',
	Function = function(callback)
		frictionTable.LongJump = callback or nil
		updateVelocity()
		if callback then
			if BadEvents.EntityDamageEvent then
				LongJump:Clean(BadEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and damageTable.fromEntity == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = 0
						if bedwars.KnockbackUtil then
							pcall(function()
								knockbackBoost = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
									vertical = 0,
									horizontal = (damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal or 1)
								}).Magnitude * 1.1
							end)
						end

						if knockbackBoost >= JumpSpeed then
							local pos = damageTable.fromPosition and Vector3.new(damageTable.fromPosition.X, damageTable.fromPosition.Y, damageTable.fromPosition.Z) or (damageTable.fromEntity and damageTable.fromEntity.PrimaryPart and damageTable.fromEntity.PrimaryPart.Position)
							if not pos then return end
							local vec = (entitylib.character.RootPart.Position - pos)
							JumpSpeed = knockbackBoost
							JumpTick = tick() + 2.5
							Direction = Vector3.new(vec.X, 0, vec.Z).Unit
						end
					end
				end))
			end
			if BadEvents.GrapplingHookFunctions then
				LongJump:Clean(BadEvents.GrapplingHookFunctions.Event:Connect(function(dataTable)
					if dataTable.hookFunction == 'PLAYER_IN_TRANSIT' then
						local vec = entitylib.character.RootPart.CFrame.LookVector
						JumpSpeed = 2.5 * (Value and Value.Value or 37)
						JumpTick = tick() + 2.5
						Direction = Vector3.new(vec.X, 0, vec.Z).Unit
					end
				end))
			end

			start = entitylib.isAlive and entitylib.character and entitylib.character.RootPart and entitylib.character.RootPart.Position or nil
			LongJump:Clean(runService.PreSimulation:Connect(function(dt)
				local root = entitylib.isAlive and entitylib.character and entitylib.character.RootPart or nil

				if root and (isnetworkowner and isnetworkowner(root) or true) then
					if JumpTick > tick() then
						root.AssemblyLinearVelocity = Direction * ((getSpeed and getSpeed() or 0) + ((JumpTick - tick()) > 1.1 and JumpSpeed or 0)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
						if entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and not start then
							root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - 23), 0)
						else
							root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
						end
						start = nil
					else
						if start then
							root.CFrame = CFrame.lookAlong(start, root.CFrame.LookVector)
						end
						root.AssemblyLinearVelocity = Vector3.zero
						JumpSpeed = 0
					end
				else
					start = nil
				end
			end))

			if store.hand and LongJumpMethods[store.hand.tool.Name] then
				task.spawn(LongJumpMethods[store.hand.tool.Name], getItem(store.hand.tool.Name), start, (CameraDir and CameraDir.Enabled and game:GetService('Workspace').CurrentCamera or (entitylib.character and entitylib.character.RootPart)).CFrame.LookVector)
				return
			end

			for i, v in LongJumpMethods do
				local item = getItem(i)
				if item or store.equippedKit == i then
					task.spawn(v, item, start, (CameraDir and CameraDir.Enabled and game:GetService('Workspace').CurrentCamera or (entitylib.character and entitylib.character.RootPart)).CFrame.LookVector)
					break
				end
			end
		else
			JumpTick = tick()
			Direction = nil
			JumpSpeed = 0
		end
	end,
	ExtraText = function()
		return 'Heatseeker'
	end,
	Tooltip = 'Lets you jump farther'
})
Value = LongJump:CreateSlider({
	Name = 'Speed',
	Min = 1,
	Max = 37,
	Default = 37,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})
CameraDir = LongJump:CreateToggle({
	Name = 'Camera Direction'
})





