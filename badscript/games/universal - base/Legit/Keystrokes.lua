local Keystrokes
local Style
local Color
local keys, holder = {}

local function getColorHue()
	if Color and type(Color.Hue) == 'number' then return Color.Hue end
	return 0.44
end

local function getColorSat()
	if Color and type(Color.Sat) == 'number' then return Color.Sat end
	return 1
end

local function getColorVal()
	if Color and type(Color.Value) == 'number' then return Color.Value end
	return 1
end

local function getColorOpacity()
	if Color and type(Color.Opacity) == 'number' then return math.clamp(Color.Opacity, 0, 1) end
	return 0.5
end

local function getColor3()
	return Color3.fromHSV(getColorHue(), getColorSat(), getColorVal())
end

local function createKeystroke(keybutton, pos, pos2, text)
	if keys[keybutton] then
		pcall(function()
			keys[keybutton].Key:Destroy()
		end)
		keys[keybutton] = nil
	end

	local key = Instance.new('Frame')
	key.Size = keybutton == Enum.KeyCode.Space and UDim2.new(0, 110, 0, 24) or UDim2.new(0, 34, 0, 36)
	key.BackgroundColor3 = getColor3()
	key.BackgroundTransparency = 1 - getColorOpacity()
	key.Position = pos
	key.Name = keybutton.Name
	key.Parent = holder
	local keytext = Instance.new('TextLabel')
	keytext.BackgroundTransparency = 1
	keytext.Size = UDim2.fromScale(1, 1)
	keytext.Font = Enum.Font.Gotham
	keytext.Text = text or keybutton.Name
	keytext.TextXAlignment = Enum.TextXAlignment.Left
	keytext.TextYAlignment = Enum.TextYAlignment.Top
	keytext.Position = pos2
	keytext.TextSize = keybutton == Enum.KeyCode.Space and 18 or 15
	keytext.TextColor3 = Color3.new(1, 1, 1)
	keytext.Parent = key
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = key

	keys[keybutton] = {Key = key, Pressed = false}
end

local function updateKey(inputType)
	if not inputType or not inputType.KeyCode then return end
	local key = keys[inputType.KeyCode]
	if key and key.Key and key.Key.Parent then
		if key.Tween then
			pcall(function() key.Tween:Cancel() end)
		end

		if key.Tween2 then
			pcall(function() key.Tween2:Cancel() end)
		end

		local pressed = inputType.UserInputState == Enum.UserInputState.Begin
		key.Pressed = pressed
		if tweenService then
			pcall(function()
				key.Tween = tweenService:Create(key.Key, TweenInfo.new(0.1), {
					BackgroundColor3 = pressed and Color3.new(1, 1, 1) or getColor3(),
					BackgroundTransparency = pressed and 0 or (1 - getColorOpacity())
				})
				key.Tween2 = tweenService:Create(key.Key.TextLabel, TweenInfo.new(0.1), {
					TextColor3 = pressed and Color3.new() or Color3.new(1, 1, 1)
				})
				key.Tween:Play()
				key.Tween2:Play()
			end)
		end
	end
end

Keystrokes = Bad.Legit:CreateModule({
	Name = 'Keystrokes',
	Function = function(callback)
		if callback then
			if not holder or not holder.Parent then
				pcall(function()
					holder = Instance.new('Frame')
					holder.Size = UDim2.fromScale(1, 1)
					holder.BackgroundTransparency = 1
					if Keystrokes.Children then
						holder.Parent = Keystrokes.Children
					end
				end)
			end
			createKeystroke(Enum.KeyCode.W, UDim2.new(0, 38, 0, 0), UDim2.new(0, 6, 0, 5), Style and Style.Value == 'Arrow' and '↑' or nil)
			createKeystroke(Enum.KeyCode.S, UDim2.new(0, 38, 0, 42), UDim2.new(0, 8, 0, 5), Style and Style.Value == 'Arrow' and '↓' or nil)
			createKeystroke(Enum.KeyCode.A, UDim2.new(0, 0, 0, 42), UDim2.new(0, 7, 0, 5), Style and Style.Value == 'Arrow' and '←' or nil)
			createKeystroke(Enum.KeyCode.D, UDim2.new(0, 76, 0, 42), UDim2.new(0, 8, 0, 5), Style and Style.Value == 'Arrow' and '→' or nil)

			if inputService then
				Keystrokes:Clean(inputService.InputBegan:Connect(updateKey))
				Keystrokes:Clean(inputService.InputEnded:Connect(updateKey))
			end
		end
	end,
	Size = UDim2.fromOffset(110, 176),
	Tooltip = 'Shows movement keys onscreen'
})
holder = Instance.new('Frame')
holder.Size = UDim2.fromScale(1, 1)
holder.BackgroundTransparency = 1
if Keystrokes.Children then
	holder.Parent = Keystrokes.Children
end
Style = Keystrokes:CreateDropdown({
	Name = 'Key Style',
	List = {'Keyboard', 'Arrow'},
	Function = function()
		if Keystrokes.Enabled then
			Keystrokes:Toggle()
			Keystrokes:Toggle()
		end
	end
})
Color = Keystrokes:CreateColorSlider({
	Name = 'Color',
	DefaultValue = 0,
	DefaultOpacity = 0.5,
	Function = function(hue, sat, val, opacity)
		local safeHue = type(hue) == 'number' and hue or 0.44
		local safeSat = type(sat) == 'number' and sat or 1
		local safeVal = type(val) == 'number' and val or 1
		local safeOpacity = type(opacity) == 'number' and math.clamp(opacity, 0, 1) or 0.5
		for _, v in keys do
			if v and v.Key and v.Key.Parent and not v.Pressed then
				v.Key.BackgroundColor3 = Color3.fromHSV(safeHue, safeSat, safeVal)
				v.Key.BackgroundTransparency = 1 - safeOpacity
			end
		end
	end
})
Keystrokes:CreateToggle({
	Name = 'Show Spacebar',
	Function = function(callback)
		if Keystrokes.Children then
			Keystrokes.Children.Size = UDim2.fromOffset(110, callback and 107 or 78)
		end

		if callback then
			createKeystroke(Enum.KeyCode.Space, UDim2.new(0, 0, 0, 83), UDim2.new(0, 25, 0, -10), '______')
		else
			if keys[Enum.KeyCode.Space] and keys[Enum.KeyCode.Space].Key then
				pcall(function() keys[Enum.KeyCode.Space].Key:Destroy() end)
				keys[Enum.KeyCode.Space] = nil
			end
		end
	end,
	Default = true
})





