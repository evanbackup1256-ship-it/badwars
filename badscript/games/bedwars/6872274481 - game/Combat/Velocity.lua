local Velocity
local Horizontal
local Vertical
local Chance
local TargetCheck
local rand, old = Random.new()
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}

Velocity = Bad.Categories.Combat:CreateModule({
	Name = 'Velocity',
	Function = function(callback)
		if bedwars.KnockbackUtil then
			if callback then
				old = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					if rand:NextNumber(0, 100) > (Chance and Chance.Value or 100) then return end
					local check = true
					if TargetCheck and TargetCheck.Enabled then
						check = entitylib.EntityPosition({
							Range = 50,
							Part = 'RootPart',
							Players = true
						})
					end

					if check then
						knockback = knockback or {}
						if (Horizontal and Horizontal.Value or 0) == 0 and (Vertical and Vertical.Value or 0) == 0 then return end
						knockback.horizontal = (knockback.horizontal or 1) * ((Horizontal and Horizontal.Value or 0) / 100)
						knockback.vertical = (knockback.vertical or 1) * ((Vertical and Vertical.Value or 0) / 100)
					end
					
					return old(root, mass, dir, knockback, ...)
				end
			else
				if old then
					bedwars.KnockbackUtil.applyKnockback = old
				end
			end
		end
	end,
	Tooltip = 'Reduces knockback taken'
})
Horizontal = Velocity:CreateSlider({
	Name = 'Horizontal',
	Min = 0,
	Max = 100,
	Default = 0,
	Suffix = '%'
})
Vertical = Velocity:CreateSlider({
	Name = 'Vertical',
	Min = 0,
	Max = 100,
	Default = 0,
	Suffix = '%'
})
Chance = Velocity:CreateSlider({
	Name = 'Chance',
	Min = 0,
	Max = 100,
	Default = 100,
	Suffix = '%'
})
TargetCheck = Velocity:CreateToggle({Name = 'Only when targeting'})





