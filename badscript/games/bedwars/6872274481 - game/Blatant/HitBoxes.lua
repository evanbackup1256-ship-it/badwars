local Mode
local Expand
local objects, set = {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local HitBoxes

local function createHitbox(ent)
	if ent and ent.Targetable and ent.Player and ent.RootPart and ent.Character then
		local hitbox = Instance.new('Part')
		hitbox.Size = Vector3.new(3, 6, 3) + Vector3.one * ((Expand and Expand.Value or 14.4) / 5)
		hitbox.Position = ent.RootPart.Position
		hitbox.CanCollide = false
		hitbox.Massless = true
		hitbox.Transparency = 1
		hitbox.Parent = ent.Character
		local weld = Instance.new('Motor6D')
		weld.Part0 = hitbox
		weld.Part1 = ent.RootPart
		weld.Parent = hitbox
		objects[ent] = hitbox
	end
end

HitBoxes = Bad.Categories.Blatant:CreateModule({
	Name = 'HitBoxes',
	Function = function(callback)
		if callback then
			if Mode and Mode.Value == 'Sword' then
				if bedwars.SwordController and bedwars.SwordController.swingSwordInRegion then
					pcall(function()
						debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, ((Expand and Expand.Value or 14.4) / 3))
					end)
				end
				set = true
			else
				if entitylib.Events then
					HitBoxes:Clean(entitylib.Events.EntityAdded:Connect(createHitbox))
					HitBoxes:Clean((entitylib.Events.EntityRemoved or entitylib.Events.EntityRemoving):Connect(function(ent)
						if objects[ent] then
							objects[ent]:Destroy()
							objects[ent] = nil
						end
					end))
				end
				for _, ent in entitylib.List do
					createHitbox(ent)
				end
			end
		else
			if set then
				if bedwars.SwordController and bedwars.SwordController.swingSwordInRegion then
					pcall(function()
						debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, 3.8)
					end)
				end
				set = nil
			end
			for _, part in objects do
				part:Destroy()
			end
			table.clear(objects)
		end
	end,
	Tooltip = 'Expands attack hitbox'
})
Mode = HitBoxes:CreateDropdown({
	Name = 'Mode',
	List = {'Sword', 'Player'},
	Function = function()
		if HitBoxes.Enabled then
			HitBoxes:Toggle()
			HitBoxes:Toggle()
		end
	end,
	Tooltip = 'Sword - Increases the range around you to hit entities\nPlayer - Increases the players hitbox'
})
Expand = HitBoxes:CreateSlider({
	Name = 'Expand amount',
	Min = 0,
	Max = 14.4,
	Default = 14.4,
	Decimal = 10,
	Function = function(val)
		if HitBoxes.Enabled then
			if Mode and Mode.Value == 'Sword' then
				if bedwars.SwordController and bedwars.SwordController.swingSwordInRegion then
					pcall(function()
						debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (val / 3))
					end)
				end
			else
				for _, part in objects do
					part.Size = Vector3.new(3, 6, 3) + Vector3.one * (val / 5)
				end
			end
		end
	end,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})





