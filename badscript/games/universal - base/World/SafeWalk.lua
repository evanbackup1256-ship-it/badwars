local rayCheck = RaycastParams.new()
rayCheck.RespectCanCollide = true
local playerModule, oldMoveFunction

Bad.Categories.World:CreateModule({
	Name = 'SafeWalk',
	Function = function(callback)
		if callback then
			if not playerModule then
				local suc = pcall(function() 
					playerModule = require(lplr and lplr.PlayerScripts and lplr.PlayerScripts:FindFirstChild('PlayerModule') and lplr.PlayerScripts.PlayerModule).controls 
				end)
				if not suc then playerModule = {} end
			end
			
			oldMoveFunction = playerModule.moveFunction
			playerModule.moveFunction = function(self, vec, face)
				if entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
					rayCheck.FilterDescendantsInstances = {lplr and lplr.Character, gameCamera}
					local root = entitylib.character.RootPart
					local movedir = root.Position + vec
					local ray = workspace:Raycast(movedir, Vector3.new(0, -15, 0), rayCheck)
					if not ray then
						local check = workspace:Blockcast(root.CFrame, Vector3.new(3, 1, 3), Vector3.new(0, -((entitylib.character.HipHeight or 2) + 1), 0), rayCheck)
						if check then
							vec = (check.Instance:GetClosestPointOnSurface(movedir) - root.Position) * Vector3.new(1, 0, 1)
						end
					end
				end

				return oldMoveFunction and oldMoveFunction(self, vec, face)
			end
		else
			if playerModule and oldMoveFunction then
				playerModule.moveFunction = oldMoveFunction
			end
		end
	end,
	Tooltip = 'Prevents you from walking off the edge of parts'
})





