local Keystrokes
local Style
local Color
local ShowSpacebar

local keys = {}
local holder

local PremiumKeystrokesBuild = "2026.07.04.8.2"

local NORMAL_BACKGROUND = Color3.fromRGB(14, 20, 29)
local NORMAL_TEXT = Color3.fromRGB(218, 227, 240)
local MUTED_TEXT = Color3.fromRGB(155, 171, 192)
local BORDER_COLOR = Color3.fromRGB(68, 86, 109)

local function getColorHue()
	if Color and type(Color.Hue) == "number" then
		return Color.Hue
	end
	return 0.44
end

local function getColorSat()
	if Color and type(Color.Sat) == "number" then
		return Color.Sat
	end
	return 0.82
end

local function getColorVal()
	if Color and type(Color.Value) == "number" then
		return Color.Value
	end
	return 0.92
end

local function getColor3()
	return Color3.fromHSV(
		getColorHue(),
		getColorSat(),
		getColorVal()
	)
end

local function getPressedTextColor(accent)
	local luminance =
		(accent.R * 0.2126)
		+ (accent.G * 0.7152)
		+ (accent.B * 0.0722)

	return luminance > 0.58
		and Color3.fromRGB(7, 12, 18)
		or Color3.fromRGB(245, 249, 255)
end

local function tween(object, info, properties)
	if not object or not object.Parent then
		return nil
	end

	if tweenService then
		local success, created = pcall(function()
			return tweenService:Create(object, info, properties)
		end)

		if success and created then
			created:Play()
			return created
		end
	end

	for property, value in pairs(properties) do
		pcall(function()
			object[property] = value
		end)
	end

	return nil
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "KeyStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = 1
	stroke.Color = getColor3()
	stroke.Transparency = 0.72
	stroke.Parent = parent
	return stroke
end

local function ensureHolder()
	if holder and holder.Parent then
		return holder
	end

	holder = Instance.new("Frame")
	holder.Name = "KeystrokeGrid"
	holder.Size = UDim2.fromScale(1, 1)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ClipsDescendants = true

	if Keystrokes and Keystrokes.Children then
		holder.Parent = Keystrokes.Children
	end

	return holder
end

local function destroyKeys()
	for _, entry in pairs(keys) do
		pcall(function()
			if entry.Tween then
				entry.Tween:Cancel()
			end
			if entry.Key then
				entry.Key:Destroy()
			end
		end)
	end

	table.clear(keys)
end

local function applyKeyState(entry, pressed, instant)
	if not entry or not entry.Key or not entry.Key.Parent then
		return
	end

	entry.Pressed = pressed

	if entry.Tween then
		pcall(function()
			entry.Tween:Cancel()
		end)
	end

	local accent = getColor3()
	local duration = instant and 0 or (pressed and 0.085 or 0.14)
	local info = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)

	local backgroundTween = tween(entry.Key, info, {
		BackgroundColor3 = pressed and accent or NORMAL_BACKGROUND,
		BackgroundTransparency = pressed and 0.08 or 0.04,
	})

	tween(entry.Stroke, info, {
		Color = pressed and accent or accent:Lerp(BORDER_COLOR, 0.56),
		Transparency = pressed and 0.08 or 0.64,
	})

	tween(entry.Label, info, {
		TextColor3 = pressed
			and getPressedTextColor(accent)
			or NORMAL_TEXT,
	})

	tween(entry.Scale, info, {
		Scale = pressed and 0.94 or 1,
	})

	tween(entry.Highlight, info, {
		BackgroundColor3 = pressed
			and Color3.fromRGB(255, 255, 255)
			or accent,
		BackgroundTransparency = pressed and 0.74 or 0.58,
	})

	entry.Tween = backgroundTween
end

local function createKeystroke(
	keyCode,
	position,
	size,
	text,
	isSpacebar
)
	local previous = keys[keyCode]
	if previous and previous.Key then
		previous.Key:Destroy()
	end

	local key = Instance.new("Frame")
	key.Name = keyCode.Name
	key.Size = size
	key.Position = position
	key.BackgroundColor3 = NORMAL_BACKGROUND
	key.BackgroundTransparency = 0.04
	key.BorderSizePixel = 0
	key.ClipsDescendants = true
	key.Parent = ensureHolder()
	addCorner(key, isSpacebar and 7 or 9)

	local stroke = addStroke(key)

	local gradient = Instance.new("UIGradient")
	gradient.Name = "SurfaceGradient"
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(26, 35, 48)
		),
		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(10, 15, 22)
		),
	})
	gradient.Rotation = 90
	gradient.Parent = key

	local highlight = Instance.new("Frame")
	highlight.Name = "Highlight"
	highlight.Size = UDim2.new(1, -10, 0, 1)
	highlight.Position = UDim2.fromOffset(5, 1)
	highlight.BackgroundColor3 = getColor3()
	highlight.BackgroundTransparency = 0.58
	highlight.BorderSizePixel = 0
	highlight.ZIndex = 2
	highlight.Parent = key
	addCorner(highlight, 99)

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text or keyCode.Name
	label.TextColor3 = NORMAL_TEXT
	label.TextSize = isSpacebar and 9 or 13
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Font = isSpacebar
		and Enum.Font.GothamBold
		or Enum.Font.GothamMedium
	label.ZIndex = 3
	label.Parent = key

	local scale = Instance.new("UIScale")
	scale.Name = "PressScale"
	scale.Scale = 1
	scale.Parent = key

	keys[keyCode] = {
		Key = key,
		Label = label,
		Stroke = stroke,
		Scale = scale,
		Highlight = highlight,
		Pressed = false,
	}

	applyKeyState(keys[keyCode], false, true)
end

local function keyText(keyCode)
	local useArrows = Style and Style.Value == "Arrow"
	if not useArrows then
		return keyCode.Name
	end

	local arrows = {
		[Enum.KeyCode.W] = "↑",
		[Enum.KeyCode.A] = "←",
		[Enum.KeyCode.S] = "↓",
		[Enum.KeyCode.D] = "→",
	}

	return arrows[keyCode] or keyCode.Name
end

local function rebuildKeys()
	destroyKeys()
	ensureHolder()

	createKeystroke(
		Enum.KeyCode.W,
		UDim2.fromOffset(46, 20),
		UDim2.fromOffset(34, 30),
		keyText(Enum.KeyCode.W),
		false
	)

	createKeystroke(
		Enum.KeyCode.A,
		UDim2.fromOffset(8, 56),
		UDim2.fromOffset(34, 30),
		keyText(Enum.KeyCode.A),
		false
	)

	createKeystroke(
		Enum.KeyCode.S,
		UDim2.fromOffset(46, 56),
		UDim2.fromOffset(34, 30),
		keyText(Enum.KeyCode.S),
		false
	)

	createKeystroke(
		Enum.KeyCode.D,
		UDim2.fromOffset(84, 56),
		UDim2.fromOffset(34, 30),
		keyText(Enum.KeyCode.D),
		false
	)

	if ShowSpacebar and ShowSpacebar.Enabled then
		createKeystroke(
			Enum.KeyCode.Space,
			UDim2.fromOffset(8, 96),
			UDim2.fromOffset(110, 16),
			"SPACE",
			true
		)
	end
end

local function setKeyState(keyCode, pressed)
	local entry = keys[keyCode]
	if entry then
		applyKeyState(entry, pressed, false)
	end
end

Keystrokes = Bad.Legit:CreateModule({
	Name = "Keystrokes",
	Function = function(callback)
		if callback then
			rebuildKeys()

			if inputService then
				Keystrokes:Clean(
					inputService.InputBegan:Connect(
						function(input)
							if input and input.KeyCode then
								setKeyState(
									input.KeyCode,
									true
								)
							end
						end
					)
				)

				Keystrokes:Clean(
					inputService.InputEnded:Connect(
						function(input)
							if input and input.KeyCode then
								setKeyState(
									input.KeyCode,
									false
								)
							end
						end
					)
				)
			end
		else
			for _, entry in pairs(keys) do
				applyKeyState(entry, false, true)
			end
		end
	end,
	Size = UDim2.fromOffset(126, 122),
	Tooltip = "Shows premium movement keys onscreen",
})

ensureHolder()

Style = Keystrokes:CreateDropdown({
	Name = "Key Style",
	List = { "Keyboard", "Arrow" },
	Function = function()
		if Keystrokes.Enabled then
			rebuildKeys()
		end
	end,
})

Color = Keystrokes:CreateColorSlider({
	Name = "Accent",
	DefaultValue = 0.44,
	DefaultOpacity = 0.9,
	Function = function()
		for _, entry in pairs(keys) do
			applyKeyState(
				entry,
				entry.Pressed,
				true
			)
		end
	end,
})

ShowSpacebar = Keystrokes:CreateToggle({
	Name = "Show Spacebar",
	Function = function(callback)
		if Keystrokes.Children then
			Keystrokes.Children.Size =
				UDim2.fromOffset(
					126,
					callback and 122 or 94
				)
		end

		if Keystrokes.Enabled then
			rebuildKeys()
		end
	end,
	Default = true,
})
