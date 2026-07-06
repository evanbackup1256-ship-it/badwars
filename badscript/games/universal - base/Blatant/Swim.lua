local Swim
local terrain = cloneref(workspace:FindFirstChildWhichIsA('Terrain'))
local lastpos

local function clearLastRegion()
	if not terrain or not lastpos then
		lastpos = nil
		return
	end
	pcall(function()
		terrain:ReplaceMaterial(lastpos, 4, Enum.Material.Water, Enum.Material.Air)
	end)
	lastpos = nil
end

Swim = Bad.Categories.Blatant:CreateModule({
	Name = 'Swim',
	Function = function(callback)
		if callback then
			Swim:Clean(runService.PreSimulation:Connect(function()
				if not (entitylib.isAlive and entitylib.character and entitylib.character.RootPart and entitylib.character.Humanoid) then return end
				local root = entitylib.character.RootPart
				local moving = entitylib.character.Humanoid.MoveDirection ~= Vector3.zero
				local space = inputService and inputService:IsKeyDown(Enum.KeyCode.Space)
				if terrain then
					local factor = (moving or space) and Vector3.new(6, 6, 6) or Vector3.new(2, 1, 2)
					local pos = root.Position - Vector3.new(0, 1, 0)
					local newpos = Region3.new(pos - factor, pos + factor):ExpandToGrid(4)
					clearLastRegion()
					terrain:FillRegion(newpos, 4, Enum.Material.Water)
					lastpos = newpos
				end
			end))
		else
			clearLastRegion()
		end
	end,
	Tooltip = 'Lets you swim midair'
})
