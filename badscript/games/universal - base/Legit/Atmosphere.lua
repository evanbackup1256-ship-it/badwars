local Atmosphere
local Toggles = {}
local newobjects, oldobjects = {}, {}
local apidump = {
	Sky = {
		SkyboxUp = 'Text',
		SkyboxDn = 'Text',
		SkyboxLf = 'Text',
		SkyboxRt = 'Text',
		SkyboxFt = 'Text',
		SkyboxBk = 'Text',
		SunTextureId = 'Text',
		SunAngularSize = 'Number',
		MoonTextureId = 'Text',
		MoonAngularSize = 'Number',
		StarCount = 'Number'
	},
	Atmosphere = {
		Color = 'Color',
		Decay = 'Color',
		Density = 'Number',
		Offset = 'Number',
		Glare = 'Number',
		Haze = 'Number'
	},
	BloomEffect = {
		Intensity = 'Number',
		Size = 'Number',
		Threshold = 'Number'
	},
	DepthOfFieldEffect = {
		FarIntensity = 'Number',
		FocusDistance = 'Number',
		InFocusRadius = 'Number',
		NearIntensity = 'Number'
	},
	SunRaysEffect = {
		Intensity = 'Number',
		Spread = 'Number'
	},
	ColorCorrectionEffect = {
		TintColor = 'Color',
		Saturation = 'Number',
		Contrast = 'Number',
		Brightness = 'Number'
	}
}

local defaultTextures = {
	Sky = {
		SkyboxUp = 'rbxassetid://6444884337',
		SkyboxDn = 'rbxassetid://6444884785',
		SkyboxLf = 'rbxassetid://6444884337',
		SkyboxRt = 'rbxassetid://6444884337',
		SkyboxFt = 'rbxassetid://6444884337',
		SkyboxBk = 'rbxassetid://6444884337',
		SunTextureId = 'rbxassetid://6196665106',
		SunAngularSize = '11',
		MoonTextureId = 'rbxassetid://6444884337',
		MoonAngularSize = '11',
		StarCount = '3000'
	},
	Atmosphere = {
		Color = {Hue = 0.5, Sat = 0.1, Value = 0.8},
		Decay = {Hue = 0.5, Sat = 0.3, Value = 0.7},
		Density = '0.3',
		Offset = '0',
		Glare = '0',
		Haze = '1'
	},
	BloomEffect = {
		Intensity = '0.5',
		Size = '24',
		Threshold = '0.9'
	},
	DepthOfFieldEffect = {
		FarIntensity = '0.15',
		FocusDistance = '100',
		InFocusRadius = '50',
		NearIntensity = '0'
	},
	SunRaysEffect = {
		Intensity = '0.1',
		Spread = '0.6'
	},
	ColorCorrectionEffect = {
		TintColor = {Hue = 0, Sat = 0, Value = 1},
		Saturation = '0',
		Contrast = '0',
		Brightness = '0'
	}
}

local function removeObject(v)
	if not table.find(newobjects, v) then
		local toggle = Toggles[v.ClassName]
		if toggle and toggle.Toggle and toggle.Toggle.Enabled then
			if v.Parent then
				table.insert(oldobjects, v)
				v.Parent = game
			end
		end
	end
end

local function refreshAtmosphere()
	if not Atmosphere.Enabled then return end
	for _, v in newobjects do
		v:Destroy()
	end
	table.clear(newobjects)

	for i, toggle in Toggles do
		if toggle.Toggle and toggle.Toggle.Enabled then
			local obj = Instance.new(i)
			for i2, v2 in toggle.Objects do
				if v2.Type == 'ColorSlider' then
					obj[i2] = Color3.fromHSV(v2.Hue, v2.Sat, v2.Value)
				else
					obj[i2] = apidump[i] and apidump[i][i2] ~= 'Number' and v2.Value or tonumber(v2.Value) or 0
				end
			end
			obj.Parent = lightingService
			table.insert(newobjects, obj)
		end
	end
end

Atmosphere = Bad.Legit:CreateModule({
	Name = 'Atmosphere',
	Function = function(callback)
		if callback then
			if lightingService then
				for _, v in lightingService:GetChildren() do
					removeObject(v)
				end

				Atmosphere:Clean(lightingService.ChildAdded:Connect(function(v)
					task.defer(removeObject, v)
				end))
			end

			refreshAtmosphere()
		else
			for _, v in newobjects do
				v:Destroy()
			end

			if lightingService then
				for _, v in oldobjects do
					v.Parent = lightingService
				end
			end

			table.clear(newobjects)
			table.clear(oldobjects)
		end
	end,
	Tooltip = 'Custom lighting objects'
})
for i, v in apidump do
	Toggles[i] = {Objects = {}}
	Toggles[i].Toggle = Atmosphere:CreateToggle({
		Name = i,
		Function = function(callback)
			if Atmosphere.Enabled then
				refreshAtmosphere()
			end

			for _, toggle in Toggles[i].Objects do
				toggle.Object.Visible = callback
			end
		end
	})

	for i2, v2 in v do
		local defaults = defaultTextures[i] and defaultTextures[i][i2]
		if v2 == 'Text' or v2 == 'Number' then
			Toggles[i].Objects[i2] = Atmosphere:CreateTextBox({
				Name = i2,
				Function = function(enter)
					if Atmosphere.Enabled and enter then
						refreshAtmosphere()
					end
				end,
				Darker = true,
				Default = defaults or (v2 == 'Number' and '0' or ''),
				Visible = false
			})
		elseif v2 == 'Color' then
			Toggles[i].Objects[i2] = Atmosphere:CreateColorSlider({
				Name = i2,
				Function = function()
					if Atmosphere.Enabled then
						refreshAtmosphere()
					end
				end,
				Darker = true,
				Visible = false,
				Default = defaults or {Hue = 0, Sat = 0, Value = 1}
			})
		end
	end
end
