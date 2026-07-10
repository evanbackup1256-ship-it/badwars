local Bad = shared.Bad or {}
local Value
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}

Reach = Bad.Categories.Combat:CreateModule({
	Name = 'Reach',
	Function = function(callback)
		if bedwars.CombatConstant then
			pcall(function()
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and (Value and Value.Value or 18) + 2 or 14.4
			end)
		end
	end,
	Tooltip = 'Extends attack reach'
})
Value = Reach:CreateSlider({
	Name = 'Range',
	Min = 0,
	Max = 18,
	Default = 18,
	Function = function(val)
		if Reach.Enabled and bedwars.CombatConstant then
			pcall(function()
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end)
		end
	end,
	Suffix = function(val)
		return val == 1 and 'stud' or 'studs'
	end
})





