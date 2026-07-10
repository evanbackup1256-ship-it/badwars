local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local compat = Bad.BedWarsCompatibility or {}

local HitFix = Bad.Legit:CreateModule({
	Name = 'HitFix',
	Function = function(callback)
		local sword = bedwars.SwordController
		local swing = sword and sword.swingSwordAtMouse
		if type(swing) ~= 'function' then
			if compat.Unavailable then
				compat:Unavailable(HitFix or {}, 'Sword swing API is unavailable in this BedWars build.')
			end
			return
		end
		if compat.SafeSetConstant then
			compat:SafeSetConstant(swing, 23, callback and 'raycast' or 'Raycast')
		end
		if compat.SafeSetupValue then
			compat:SafeSetupValue(swing, 4, callback and (bedwars.QueryUtil or workspace) or workspace)
		end
	end,
	Tooltip = 'Changes the raycast function to the correct one'
})