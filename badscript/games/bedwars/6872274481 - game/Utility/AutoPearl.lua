local Bad = shared.Bad or {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local store = (shared.Bad and shared.Bad.store) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local compat = Bad.BedWarsCompatibility or {}
local remotes = (shared.Bad and shared.Bad.remotes) or {}
local switchItem = (shared.Bad and shared.Bad.switchItem) or function() end
local prediction = (shared.Bad and shared.Bad.prediction) or {SolveTrajectory = function() return nil end}
local httpService = game:GetService('HttpService')
local lplr = game:GetService('Players').LocalPlayer
local gameCamera = workspace.CurrentCamera
local getItem = (shared.Bad and shared.Bad.getItem) or function() return nil end
local getNearGround = (shared.Bad and shared.Bad.getNearGround) or function() return nil end
local AntiFallPart = nil

local AutoPearl
local rayCheck = RaycastParams.new()
rayCheck.RespectCanCollide = true
local projectileRemote = {InvokeServer = function() end}
task.spawn(function()
	projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
end)

local function firePearl(pos, spot, item)
	switchItem(item.tool)
	local meta = bedwars.ProjectileMeta.telepearl
	local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)

	if calc then
		local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
		bedwars.ProjectileController:createLocalProjectile(meta, 'telepearl', 'telepearl', pos, nil, dir, {drawDurationSeconds = 1})
		projectileRemote:InvokeServer(item.tool, 'telepearl', 'telepearl', pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
	end

	if store.hand then
		switchItem(store.hand.tool)
	end
end

AutoPearl = Bad.Categories.Utility:CreateModule({
	Name = 'AutoPearl',
	Function = function(callback)
		if callback then
			local check
			repeat
				if entitylib.isAlive then
					local root = entitylib.character.RootPart
					local pearl = getItem('telepearl')
					rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
					rayCheck.CollisionGroup = root.CollisionGroup

					if pearl and root.Velocity.Y < -100 and not workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayCheck) then
						if not check then
							check = true
							local ground = getNearGround(20)

							if ground then
								firePearl(root.Position, ground, pearl)
							end
						end
					else
						check = false
					end
				end
				task.wait(0.1)
			until not AutoPearl.Enabled
		end
	end,
	Tooltip = 'Automatically throws a pearl onto nearby ground after\nfalling a certain distance.'
})





