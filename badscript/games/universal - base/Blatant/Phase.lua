local Mode
local StudLimit = {Object = {}}
local rayCheck = RaycastParams.new()
rayCheck.RespectCanCollide = true
local overlapCheck = OverlapParams.new()
overlapCheck.MaxParts = 9e9
local modified, fflag = {}
local teleported
local phaseCharacter

local function grabClosestNormal(ray)
	local partCF, mag, closest = ray.Instance.CFrame, 0, Enum.NormalId.Top

	for _, normal in Enum.NormalId:GetEnumItems() do
		local dot = partCF:VectorToWorldSpace(Vector3.fromNormalId(normal)):Dot(ray.Normal)
		if dot > mag then
			mag, closest = dot, normal
		end
	end

	return Vector3.fromNormalId(closest).X ~= 0 and 'X' or 'Z'
end

local Functions = {
	Part = function()
		if not entitylib.character or not entitylib.character.RootPart then return function() end end
		local chars = {gameCamera, lplr and lplr.Character}
		for _, v in entitylib.List do
			if v and v.Character then
				table.insert(chars, v.Character)
			end
		end
		overlapCheck.FilterDescendantsInstances = chars

		local parts = workspace:GetPartBoundsInBox(entitylib.character.RootPart.CFrame + Vector3.new(0, 1, 0), entitylib.character.RootPart.Size + Vector3.new(7, entitylib.character.HipHeight or 2, 7), overlapCheck)
		for _, part in parts do
			if part.CanCollide and (not (Spider and Spider.Enabled) or SpiderShift) then
				modified[part] = true
				part.CanCollide = false
			end
		end

		for _, part in parts do
			if part:IsA('BasePart') and part.CanCollide and (not (Spider and Spider.Enabled) or SpiderShift) then
				modified[part] = true
				part.CanCollide = false
			end
		end

		return function()
			for part in modified do
				part.CanCollide = (Spider and Spider.Enabled) and not SpiderShift
			end
		end
	end,
	Character = function()
		local character = entitylib.character and entitylib.character.Character
		if not character or character == phaseCharacter then return end
		phaseCharacter = character

		for _, part in character:GetDescendants() do
			if part:IsA('BasePart') and part.CanCollide then
				modified[part] = true
				part.CanCollide = false
			end
		end
	end,
	CFrame = function()
		if not entitylib.character or not entitylib.character.RootPart or not entitylib.character.Head or not entitylib.character.Humanoid then return end
		local chars = {gameCamera, lplr and lplr.Character}
		for _, v in entitylib.List do
			if v and v.Character then
				table.insert(chars, v.Character)
			end
		end
		rayCheck.FilterDescendantsInstances = chars
		overlapCheck.FilterDescendantsInstances = chars

		local ray = workspace:Raycast(entitylib.character.Head.CFrame.Position, entitylib.character.Humanoid.MoveDirection * 1.1, rayCheck)
		if ray and (not (Spider and Spider.Enabled) or SpiderShift) then
			local phaseDirection = grabClosestNormal(ray)
			if ray.Instance.Size[phaseDirection] <= (StudLimit and StudLimit.Value or 5) then
				local root = entitylib.character.RootPart
				local dest = root.CFrame + (ray.Normal * (-(ray.Instance.Size[phaseDirection]) - (root.Size.X / 1.5)))

				if #workspace:GetPartBoundsInBox(dest, Vector3.one, overlapCheck) <= 0 then
					if Mode and Mode.Value == 'Motor' then
						motorMove(root, dest)
					else
						root.CFrame = dest
					end
				end
			end
		end
	end,
	FFlag = function()
		if teleported or type(setfflag) ~= 'function' then
			fflag = nil
			return
		end
		setfflag('AssemblyExtentsExpansionStudHundredth', '-10000')
		fflag = true
	end
}
Functions.Motor = Functions.CFrame

Phase = Bad.Categories.Blatant:CreateModule({
	Name = 'Phase',
	Function = function(callback)
		if callback then
			Phase:Clean(runService.Stepped:Connect(function()
				if entitylib.isAlive then
					local handler = Functions[Mode and Mode.Value]
					if type(handler) == 'function' then
						handler()
					end
				end
			end))

			if Mode.Value == 'FFlag' then
				Phase:Clean(lplr.OnTeleport:Connect(function()
					teleported = true
					if type(setfflag) == 'function' then
						setfflag('AssemblyExtentsExpansionStudHundredth', '30')
					end
				end))
			end
		else
			if fflag and type(setfflag) == 'function' then
				setfflag('AssemblyExtentsExpansionStudHundredth', '30')
			end
			for part in modified do
				part.CanCollide = true
			end
			table.clear(modified)
			phaseCharacter = nil
			fflag = nil
		end
	end,
	Tooltip = 'Lets you Phase/Clip through walls. (Hold shift to use Phase over spider)'
})
Mode = Phase:CreateDropdown({
	Name = 'Mode',
	List = {'Part', 'Character', 'CFrame', 'Motor', 'FFlag'},
	Function = function(val)
		StudLimit.Object.Visible = val == 'CFrame' or val == 'Motor'
		if fflag and type(setfflag) == 'function' then
			setfflag('AssemblyExtentsExpansionStudHundredth', '30')
		end
		for part in modified do
			part.CanCollide = true
		end
		table.clear(modified)
		phaseCharacter = nil
		fflag = nil
	end,
	Tooltip = 'Part - Modifies parts collision status around you\nCharacter - Modifies the local collision status of the character\nCFrame - Teleports you past parts\nMotor - Same as CFrame with a bypass\nFFlag - Directly adjusts all physics collisions'
})
StudLimit = Phase:CreateSlider({
	Name = 'Wall Size',
	Min = 1,
	Max = 20,
	Default = 5,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end,
	Darker = true,
	Visible = false
})





