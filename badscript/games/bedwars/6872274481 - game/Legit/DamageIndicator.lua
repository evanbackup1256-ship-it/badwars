local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local DamageIndicator
local FontOption
local Color = {Hue = 0.44, Sat = 1, Value = 1, Opacity = 0.5}
local Size
local Anchor
local Stroke
local compat = Bad.BedWarsCompatibility or {}
local indicatorFunc = bedwars.DamageIndicator or (compat and compat.DamageIndicator)
local suc, tab = false, {}
if type(indicatorFunc) == "function" then
	if compat.SafeGetUpvalue then
		suc, tab = compat:SafeGetUpvalue(indicatorFunc, 2)
	else
		suc, tab = pcall(debug.getupvalue, indicatorFunc, 2)
	end
end
tab = (suc and type(tab) == "table") and tab or {}
local oldvalues, oldfont = {}

local function setFontConstant(fontName)
	if not indicatorFunc or not compat then return end
	local font = Enum.Font[fontName]
	if font then
		compat:SafeSetConstant(indicatorFunc, 86, font)
	end
end

local function setStrokeConstant(enabled)
	if not indicatorFunc or not compat then return end
	compat:SafeSetConstant(indicatorFunc, 119, enabled and 'Thickness' or 'Enabled')
end

DamageIndicator = Bad.Legit:CreateModule({
	Name = 'Damage Indicator',
	Function = function(callback)
		if not indicatorFunc then
			if compat then
				compat:Unavailable(DamageIndicator, 'Damage indicator API is unavailable in this BedWars build.')
			end
			return
		end
		if callback then
			oldvalues = table.clone(tab)
			local ok, font = compat:SafeGetConstant(indicatorFunc, 86)
			oldfont = ok and font or nil
			setFontConstant(FontOption.Value)
			setStrokeConstant(Stroke.Enabled)
			tab.strokeThickness = Stroke.Enabled and 1 or false
			tab.textSize = Size.Value
			tab.blowUpSize = Size.Value
			tab.blowUpDuration = 0
			tab.baseColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			tab.blowUpCompleteDuration = 0
			tab.anchoredDuration = Anchor.Value
		else
			for i, v in oldvalues do
				tab[i] = v
			end
			if oldfont ~= nil then
				compat:SafeSetConstant(indicatorFunc, 86, oldfont)
			end
			compat:SafeSetConstant(indicatorFunc, 119, 'Thickness')
		end
	end,
	Tooltip = 'Customize the damage indicator'
})
local fontitems = {'GothamBlack'}
for _, v in Enum.Font:GetEnumItems() do
	if v.Name ~= 'GothamBlack' then
		table.insert(fontitems, v.Name)
	end
end
FontOption = DamageIndicator:CreateDropdown({
	Name = 'Font',
	List = fontitems,
	Function = function(val)
		if DamageIndicator.Enabled then
			setFontConstant(val)
		end
	end
})
Color = DamageIndicator:CreateColorSlider({
	Name = 'Color',
	DefaultHue = 0,
	Function = function(hue, sat, val)
		if DamageIndicator.Enabled then
			tab.baseColor = Color3.fromHSV(hue, sat, val)
		end
	end
})
Size = DamageIndicator:CreateSlider({
	Name = 'Size',
	Min = 1,
	Max = 32,
	Default = 32,
	Function = function(val)
		if DamageIndicator.Enabled then
			tab.textSize = val
			tab.blowUpSize = val
		end
	end
})
Anchor = DamageIndicator:CreateSlider({
	Name = 'Anchor',
	Min = 0,
	Max = 1,
	Decimal = 10,
	Function = function(val)
		if DamageIndicator.Enabled then
			tab.anchoredDuration = val
		end
	end
})
Stroke = DamageIndicator:CreateToggle({
	Name = 'Stroke',
	Function = function(callback)
		if DamageIndicator.Enabled then
			setStrokeConstant(callback)
			tab.strokeThickness = callback and 1 or false
		end
	end
})