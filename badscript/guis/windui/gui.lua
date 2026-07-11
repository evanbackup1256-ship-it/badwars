-- BADWARS_WINDUI_INTEGRATION
-- WindUI adapter with centralized legacy compatibility layer.

local cloneref = cloneref or clonereference or function(value)
	return value
end

local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local TextService = cloneref(game:GetService("TextService"))

local d = {
	Categories = {},
	Modules = {},
	Overlays = {},
	Libraries = {},
	Profiles = {},
	Connections = {},
	Resources = {},
	GUIColor = { Hue = 0.02, Sat = 0.95, Value = 0.98 },
	Version = "WindUI-Adapter-2.1",
	PremiumBuild = false,
	Name = "BadWars-WindUI",
	Visible = false,
	Destroyed = false,
}

-- BADWARS_RUNTIME_COMPAT_V28
local BUILTIN_ASSET_FALLBACK = "rbxassetid://130359823580534"
local BUILTIN_ASSETS = {
	["add.png"] = "rbxassetid://14368300605",
	["alert.png"] = "rbxassetid://14368301329",
	["allowedicon.png"] = "rbxassetid://14368302000",
	["allowedtab.png"] = "rbxassetid://14368302875",
	["arrowmodule.png"] = "rbxassetid://14473354880",
	["back.png"] = "rbxassetid://14368303894",
	["bind.png"] = "rbxassetid://14368304734",
	["bindbkg.png"] = "rbxassetid://14368305655",
	["blatanticon.png"] = "rbxassetid://14368306745",
	["blockedicon.png"] = "rbxassetid://14385669108",
	["blockedtab.png"] = "rbxassetid://14385672881",
	["blur.png"] = "rbxassetid://14898786664",
	["blurnotif.png"] = "rbxassetid://16738720137",
	["close.png"] = "rbxassetid://14368309446",
	["closemini.png"] = "rbxassetid://14368310467",
	["colorpreview.png"] = "rbxassetid://14368311578",
	["combaticon.png"] = "rbxassetid://14368312652",
	["customsettings.png"] = "rbxassetid://14403726449",
	["dots.png"] = "rbxassetid://14368314459",
	["edit.png"] = "rbxassetid://14368315443",
	["expandicon.png"] = "rbxassetid://14368353032",
	["expandright.png"] = "rbxassetid://14368316544",
	["expandup.png"] = "rbxassetid://14368317595",
	["friendstab.png"] = "rbxassetid://14397462778",
	["guisettings.png"] = "rbxassetid://14368318994",
	["guislider.png"] = "rbxassetid://14368320020",
	["guisliderrain.png"] = "rbxassetid://14368321228",
	["guiv4.png"] = "rbxassetid://14368322199",
	["guivape.png"] = "rbxassetid://14657521312",
	["info.png"] = "rbxassetid://14368324807",
	["inventoryicon.png"] = "rbxassetid://14928011633",
	["legit.png"] = "rbxassetid://14425650534",
	["legittab.png"] = "rbxassetid://14426740825",
	["miniicon.png"] = "rbxassetid://14368326029",
	["notification.png"] = "rbxassetid://16738721069",
	["overlaysicon.png"] = "rbxassetid://14368339581",
	["overlaystab.png"] = "rbxassetid://14397380433",
	["pin.png"] = "rbxassetid://14368342301",
	["profilesicon.png"] = "rbxassetid://14397465323",
	["radaricon.png"] = "rbxassetid://14368343291",
	["rainbow_1.png"] = "rbxassetid://14368344374",
	["rainbow_2.png"] = "rbxassetid://14368345149",
	["rainbow_3.png"] = "rbxassetid://14368345840",
	["rainbow_4.png"] = "rbxassetid://14368346696",
	["range.png"] = "rbxassetid://14368347435",
	["rangearrow.png"] = "rbxassetid://14368348640",
	["rendericon.png"] = "rbxassetid://14368350193",
	["rendertab.png"] = "rbxassetid://14397373458",
	["search.png"] = "rbxassetid://14425646684",
	["targetinfoicon.png"] = "rbxassetid://14368354234",
	["targetnpc1.png"] = "rbxassetid://14497400332",
	["targetnpc2.png"] = "rbxassetid://14497402744",
	["targetplayers1.png"] = "rbxassetid://14497396015",
	["targetplayers2.png"] = "rbxassetid://14497397862",
	["targetstab.png"] = "rbxassetid://14497393895",
	["textguiicon.png"] = "rbxassetid://14368355456",
	["textv4.png"] = "rbxassetid://14368357095",
	["textvape.png"] = "rbxassetid://14368358200",
	["utilityicon.png"] = "rbxassetid://14368359107",
	["vape.png"] = "rbxassetid://14373395239",
	["warning.png"] = "rbxassetid://14368361552",
	["worldicon.png"] = "rbxassetid://14368362492",
}

local nativeGetCustomAsset = type(getcustomasset) == "function" and getcustomasset
	or (type(getsynasset) == "function" and getsynasset)
	or nil

local function compatGetCustomAsset(path)
	path = tostring(path or "")
	if nativeGetCustomAsset then
		local shouldTry = true
		if type(isfile) == "function" then
			local ok, exists = pcall(isfile, path)
			shouldTry = ok and exists == true
		end
		if shouldTry then
			local ok, result = pcall(nativeGetCustomAsset, path)
			if ok and type(result) == "string" and result ~= "" then
				return result
			end
		end
	end

	local filename = path:match("([^/\\]+)$")
	return BUILTIN_ASSETS[path] or BUILTIN_ASSETS[filename] or BUILTIN_ASSET_FALLBACK
end

local executorEnvironment = type(getgenv) == "function" and getgenv() or _G
if type(executorEnvironment) == "table" and type(executorEnvironment.getcustomasset) ~= "function" then
	executorEnvironment.getcustomasset = compatGetCustomAsset
end

local textBoundsParams
pcall(function()
	textBoundsParams = Instance.new("GetTextBoundsParams")
	textBoundsParams.Width = math.huge
end)

local function normalizeFontFace(font)
	if typeof(font) == "Font" then
		return font
	end
	if typeof(font) == "EnumItem" then
		local ok, converted = pcall(Font.fromEnum, font)
		if ok then return converted end
	end
	return Font.fromEnum(Enum.Font.Gotham)
end

local function compatGetFontSize(text, size, font)
	text = tostring(text or "")
	size = tonumber(size) or 14
	font = normalizeFontFace(font)

	if textBoundsParams then
		local ok, bounds = pcall(function()
			textBoundsParams.Text = text
			textBoundsParams.Size = size
			textBoundsParams.Font = font
			return TextService:GetTextBoundsAsync(textBoundsParams)
		end)
		if ok and typeof(bounds) == "Vector2" then
			return bounds
		end
	end

	local ok, bounds = pcall(function()
		return TextService:GetTextSize(text, size, Enum.Font.Gotham, Vector2.new(100000, 100000))
	end)
	return ok and bounds or Vector2.new(math.max(1, #text * size * 0.5), size + 4)
end

local compatTween = {
	Active = setmetatable({}, { __mode = "k" }),
}

function compatTween:Tween(object, tweenInfo, properties)
	if typeof(object) ~= "Instance" or type(properties) ~= "table" then
		return nil
	end
	local previous = self.Active[object]
	if previous then pcall(previous.Cancel, previous) end
	local ok, created = pcall(TweenService.Create, TweenService, object, tweenInfo, properties)
	if not ok or not created then
		for property, value in pairs(properties) do
			pcall(function() object[property] = value end)
		end
		return nil
	end
	self.Active[object] = created
	created.Completed:Connect(function()
		if self.Active[object] == created then
			self.Active[object] = nil
		end
	end)
	created:Play()
	return created
end

function compatTween:Cancel(object)
	local active = self.Active[object]
	if active then
		pcall(active.Cancel, active)
		self.Active[object] = nil
	end
end

d.Libraries.getcustomasset = compatGetCustomAsset
d.Libraries.getfontsize = compatGetFontSize
d.Libraries.tween = compatTween
d.Libraries.targetinfo = type(d.Libraries.targetinfo) == "table" and d.Libraries.targetinfo or {}
d.ThreadFix = type(setthreadidentity) == "function"
d.Scale = type(d.Scale) == "table" and d.Scale or { Value = 1 }
d.MotionEnabled = true
d.MotionIntensity = 1
local function pack(...)
	return { n = select("#", ...), ... }
end

local function unpackPacked(values)
	return table.unpack(values, 1, values.n)
end

local function safeCall(callback, ...)
	if type(callback) ~= "function" then
		return true
	end
	local args = pack(...)
	return xpcall(function()
		return callback(unpackPacked(args))
	end, function(message)
		return debug.traceback(tostring(message), 2)
	end)
end

local function firstNonNil(...)
	for index = 1, select("#", ...) do
		local value = select(index, ...)
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function shallowCopy(source)
	local result = {}
	if type(source) == "table" then
		for key, value in pairs(source) do
			result[key] = value
		end
	end
	return result
end

local function cloneValue(value, seen)
	if type(value) ~= "table" then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local result = {}
	seen[value] = result
	for key, item in pairs(value) do
		result[cloneValue(key, seen)] = cloneValue(item, seen)
	end
	return result
end

local function valuesEqual(left, right, seen)
	if left == right then
		return true
	end
	if type(left) ~= type(right) or type(left) ~= "table" then
		return false
	end
	seen = seen or {}
	seen[left] = seen[left] or {}
	if seen[left][right] then
		return true
	end
	seen[left][right] = true
	for key, value in pairs(left) do
		if not valuesEqual(value, right[key], seen) then
			return false
		end
	end
	for key in pairs(right) do
		if left[key] == nil then
			return false
		end
	end
	return true
end

local function sanitizeName(value)
	value = tostring(value or "unnamed")
	value = value:gsub("[^%w%-%._/]", "_")
	value = value:gsub("_+", "_")
	return value:sub(1, 120)
end

local function normalizeDescription(settings)
	return firstNonNil(settings.Desc, settings.Description, settings.Tooltip, "")
end

local function normalizeKey(value)
	if typeof(value) == "EnumItem" then
		return value.Name
	end
	return tostring(value or "F")
end

local function normalizeColor(value)
	if typeof(value) == "Color3" then
		return value
	end
	if type(value) == "string" then
		local cleaned = value:gsub("#", "")
		local ok, color = pcall(Color3.fromHex, cleaned)
		if ok then
			return color
		end
	end
	if type(value) == "table" then
		local hue = firstNonNil(value.Hue, value.H, value.h, value[1])
		local sat = firstNonNil(value.Sat, value.Saturation, value.S, value.s, value[2])
		local val = firstNonNil(value.Value, value.Brightness, value.V, value.v, value[3])
		if type(hue) == "number" and type(sat) == "number" and type(val) == "number" then
			return Color3.fromHSV(hue, sat, val)
		end
		local red = firstNonNil(value.R, value.r)
		local green = firstNonNil(value.G, value.g)
		local blue = firstNonNil(value.B, value.b)
		if type(red) == "number" and type(green) == "number" and type(blue) == "number" then
			if red > 1 or green > 1 or blue > 1 then
				return Color3.fromRGB(red, green, blue)
			end
			return Color3.new(red, green, blue)
		end
	end
	return Color3.fromRGB(255, 45, 74)
end

local function isConnection(value)
	return typeof(value) == "RBXScriptConnection"
		or (type(value) == "table" and type(value.Disconnect) == "function")
end

local function setObjectVisible(object, visible)
	if typeof(object) == "Instance" then
		pcall(function()
			object.Visible = visible
		end)
	end
end

local function findWindowMain(window)
	if type(window) ~= "table" or type(window.UIElements) ~= "table" then
		return nil
	end
	return window.UIElements.Main
end

local function forEachOpenButton(window, callback)
	if type(window) ~= "table" or type(window.UIElements) ~= "table" then
		return
	end
	for key, value in pairs(window.UIElements) do
		local keyText = tostring(key):lower()
		local valueName = typeof(value) == "Instance" and value.Name:lower() or ""
		if keyText:find("open", 1, true) or valueName:find("open", 1, true) then
			callback(value)
		end
	end
	if type(window.OpenButtonMain) == "table" then
		callback(window.OpenButtonMain.Main)
		callback(window.OpenButtonMain.Button)
	end
end

local function compileSource(source, chunkName)
	if type(loadstring) ~= "function" then
		return nil, "loadstring is unavailable"
	end
	local compiled, compileError = loadstring(source, chunkName)
	if not compiled then
		return nil, compileError
	end
	local ok, result = pcall(compiled)
	if not ok then
		return nil, result
	end
	return result
end

local function loadWindUI()
	local failures = {}
	local localPaths = {
		"badscript/guis/windui/WindUI.lua",
		"badscript/guis/windui/WindUI_compat.lua",
	}

	if type(readfile) == "function" and type(isfile) == "function" then
		for _, path in ipairs(localPaths) do
			if isfile(path) then
				local ok, source = pcall(readfile, path)
				if ok and type(source) == "string" and #source > 10000 then
					local library, loadError = compileSource(source, "@" .. path)
					if type(library) == "table" then
						return library
					end
					table.insert(failures, path .. ": " .. tostring(loadError))
				else
					table.insert(failures, path .. ": invalid or unreadable source")
				end
			end
		end
	end

	local urls = {
		"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
		"https://github.com/Footagesus/WindUI/raw/main/dist/main.lua",
	}
	for _, url in ipairs(urls) do
		local ok, body = pcall(function()
			if game and type(game.HttpGet) == "function" then
				return game:HttpGet(url, true)
			end
			return HttpService:GetAsync(url, true)
		end)
		if ok and type(body) == "string" and #body > 10000 then
			local library, loadError = compileSource(body, "@WindUI")
			if type(library) == "table" then
				return library
			end
			table.insert(failures, url .. ": " .. tostring(loadError))
		else
			table.insert(failures, url .. ": download failed")
		end
	end

	error("Failed to load WindUI:\n" .. table.concat(failures, "\n"))
end

local WindUI = loadWindUI()
if type(WindUI.CreateWindow) ~= "function" then
	error("WindUI loaded, but CreateWindow is missing")
end

d.WindUI = WindUI

pcall(function()
	WindUI.TransparencyValue = 0.08
	WindUI:SetTheme("BadWars")
end)

local Window = WindUI:CreateWindow({
	Title = "BadWars",
	Author = "Runtime Loader",
	Icon = "swords",
	Folder = "BadWars",
	NewElements = true,
	HideSearchBar = false,
	ScrollBarEnabled = true,
	AutoScale = false,
	Resizable = true,
	Size = UDim2.new(0, 760, 0, 540),
	MinSize = Vector2.new(560, 380),
	MaxSize = Vector2.new(1000, 760),
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = "BadWars",
		Enabled = true,
		Draggable = true,
		Scale = 0.55,
		Color = ColorSequence.new(Color3.fromHex("#FF2D4A"), Color3.fromHex("#FF6B35")),
	},
	Topbar = {
		Height = 50,
		ButtonsType = "Mac",
	},
})

if type(Window) ~= "table" then
	error("WindUI failed to create the BadWars window")
end

d.Window = Window

pcall(function()
	Window:SetUIScale(0.94)
end)

-- BADWARS_SAFE_VISUAL_MOTION_V2
d.ScreenGui = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui or nil

local compatibilityRoot = Instance.new("Frame")
compatibilityRoot.Name = "BadWarsCompatibilityRoot"
compatibilityRoot.Size = UDim2.fromScale(1, 1)
compatibilityRoot.BackgroundTransparency = 1
compatibilityRoot.BorderSizePixel = 0
compatibilityRoot.Active = false
compatibilityRoot.ClipsDescendants = false

local rootParent = d.ScreenGui
if typeof(rootParent) ~= "Instance" then
	rootParent = typeof(findWindowMain(Window)) == "Instance" and findWindowMain(Window) or nil
end
if rootParent then
	compatibilityRoot.Parent = rootParent
end

local compatibilityScaledGui = Instance.new("Frame")
compatibilityScaledGui.Name = "ScaledGui"
compatibilityScaledGui.Size = UDim2.fromScale(1, 1)
compatibilityScaledGui.BackgroundTransparency = 1
compatibilityScaledGui.BorderSizePixel = 0
compatibilityScaledGui.Active = false
compatibilityScaledGui.Parent = compatibilityRoot

local compatibilityClickGui = Instance.new("Frame")
compatibilityClickGui.Name = "ClickGui"
compatibilityClickGui.Size = UDim2.fromScale(1, 1)
compatibilityClickGui.BackgroundTransparency = 1
compatibilityClickGui.BorderSizePixel = 0
compatibilityClickGui.Active = false
compatibilityClickGui.Visible = false
compatibilityClickGui.Parent = compatibilityScaledGui

d.gui = compatibilityRoot
d.CompatibilityRoot = compatibilityRoot
d.ScaledGui = compatibilityScaledGui
d.ClickGui = compatibilityClickGui
d.MotionEnabled = d.MotionEnabled ~= false
d.MotionIntensity = tonumber(d.MotionIntensity) or 1

local motionTweens = setmetatable({}, { __mode = "k" })
local motionBound = setmetatable({}, { __mode = "k" })
local activeRipples = setmetatable({}, { __mode = "k" })
local motionObjectCount = 0
local MAX_MOTION_OBJECTS = 900

local function trackResource(resource)
	if resource ~= nil then
		table.insert(d.Resources, resource)
	end
	return resource
end

local function motionDuration(base)
	return math.max(0.04, base / math.max(0.55, tonumber(d.MotionIntensity) or 1))
end

local function motionTween(object, channelOrDuration, durationOrProperties, propertiesOrStyle, styleOrDirection, direction)
	if typeof(object) ~= "Instance" or not object.Parent then
		return nil
	end

	local channel
	local duration
	local properties
	local style

	if type(channelOrDuration) == "string" then
		channel = channelOrDuration
		duration = tonumber(durationOrProperties) or 0.15
		properties = propertiesOrStyle
		style = styleOrDirection
	else
		channel = "default"
		duration = tonumber(channelOrDuration) or 0.15
		properties = durationOrProperties
		style = propertiesOrStyle
		direction = styleOrDirection
	end

	if type(properties) ~= "table" then
		return nil
	end

	local channels = motionTweens[object]
	if not channels then
		channels = {}
		motionTweens[object] = channels
	end

	local previous = channels[channel]
	if previous then
		pcall(previous.Cancel, previous)
		channels[channel] = nil
	end

	if d.MotionEnabled == false then
		for property, value in pairs(properties) do
			pcall(function()
				object[property] = value
			end)
		end
		return nil
	end

	local ok, tween = pcall(
		TweenService.Create,
		TweenService,
		object,
		TweenInfo.new(
			motionDuration(duration),
			style or Enum.EasingStyle.Quint,
			direction or Enum.EasingDirection.Out
		),
		properties
	)

	if not ok or not tween then
		return nil
	end

	channels[channel] = tween
	tween.Completed:Connect(function()
		if channels[channel] == tween then
			channels[channel] = nil
		end
	end)
	tween:Play()
	return tween
end

local function ensureMotionScale(object)
	if typeof(object) ~= "Instance" or not object:IsA("GuiObject") then
		return nil
	end

	local existing = object:FindFirstChild("BadWarsMotionScale")
	if existing and existing:IsA("UIScale") then
		return existing
	end

	if object:FindFirstChildWhichIsA("UIScale") then
		return nil
	end

	local scale = Instance.new("UIScale")
	scale.Name = "BadWarsMotionScale"
	scale.Scale = 1
	scale.Parent = object
	return scale
end

local function findRoundedSurface(button)
	local current = button
	for _ = 1, 6 do
		if typeof(current) ~= "Instance" or not current:IsA("GuiObject") then
			break
		end

		local corner = current:FindFirstChildWhichIsA("UICorner")
		if corner then
			return current, corner
		end

		local parent = current.Parent
		if typeof(parent) ~= "Instance" or not parent:IsA("GuiObject") then
			break
		end
		current = parent
	end

	return button, nil
end

local function getMotionStroke(button)
	local surface, corner = findRoundedSurface(button)
	if not corner then
		return nil, surface, nil
	end

	local oldStroke = button:FindFirstChild("BadWarsMotionStroke")
	if oldStroke and oldStroke.Parent ~= surface then
		oldStroke:Destroy()
	end

	local stroke = surface:FindFirstChild("BadWarsMotionStroke")
	if not stroke or not stroke:IsA("UIStroke") then
		if stroke then
			stroke:Destroy()
		end

		stroke = Instance.new("UIStroke")
		stroke.Name = "BadWarsMotionStroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Thickness = 1
		stroke.Color = Color3.new(1, 1, 1)
		stroke.Transparency = 1
		stroke.Parent = surface
	end

	return stroke, surface, corner
end

local function getRippleLayer(button, cornerSource)
	local layer = button:FindFirstChild("BadWarsRippleClip")
	if not layer or not layer:IsA("Frame") then
		if layer then
			layer:Destroy()
		end

		layer = Instance.new("Frame")
		layer.Name = "BadWarsRippleClip"
		layer.Size = UDim2.fromScale(1, 1)
		layer.Position = UDim2.fromScale(0, 0)
		layer.BackgroundTransparency = 1
		layer.BorderSizePixel = 0
		layer.ClipsDescendants = true
		layer.Active = false
		layer.Selectable = false
		layer.ZIndex = button.ZIndex
		layer.Parent = button
	end

	local layerCorner = layer:FindFirstChild("BadWarsRippleCorner")
	if cornerSource then
		if not layerCorner or not layerCorner:IsA("UICorner") then
			if layerCorner then
				layerCorner:Destroy()
			end

			layerCorner = Instance.new("UICorner")
			layerCorner.Name = "BadWarsRippleCorner"
			layerCorner.Parent = layer
		end
		layerCorner.CornerRadius = cornerSource.CornerRadius
	elseif layerCorner then
		layerCorner:Destroy()
	end

	return layer
end

local function createRipple(button, inputPosition, cornerSource)
	if d.MotionEnabled == false or not button.Parent then
		return
	end
	if button.AbsoluteSize.X <= 1 or button.AbsoluteSize.Y <= 1 then
		return
	end

	local old = activeRipples[button]
	if old and old.Parent then
		old:Destroy()
	end

	local layer = getRippleLayer(button, cornerSource)
	local localPosition = Vector2.new(
		button.AbsoluteSize.X * 0.5,
		button.AbsoluteSize.Y * 0.5
	)

	if typeof(inputPosition) == "Vector3" then
		localPosition = Vector2.new(
			math.clamp(inputPosition.X - button.AbsolutePosition.X, 0, button.AbsoluteSize.X),
			math.clamp(inputPosition.Y - button.AbsolutePosition.Y, 0, button.AbsoluteSize.Y)
		)
	end

	local ripple = Instance.new("Frame")
	ripple.Name = "BadWarsMotionRipple"
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.fromOffset(localPosition.X, localPosition.Y)
	ripple.Size = UDim2.fromOffset(0, 0)
	ripple.BackgroundColor3 = Color3.new(1, 1, 1)
	ripple.BackgroundTransparency = 0.84
	ripple.BorderSizePixel = 0
	ripple.ZIndex = layer.ZIndex
	ripple.Parent = layer
	activeRipples[button] = ripple

	local rippleCorner = Instance.new("UICorner")
	rippleCorner.CornerRadius = UDim.new(1, 0)
	rippleCorner.Parent = ripple

	local diameter = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.25
	motionTween(
		ripple,
		"ripple",
		0.26,
		{
			Size = UDim2.fromOffset(diameter, diameter),
			BackgroundTransparency = 1,
		}
	)

	task.delay(motionDuration(0.3), function()
		if activeRipples[button] == ripple then
			activeRipples[button] = nil
		end
		if ripple.Parent then
			ripple:Destroy()
		end
	end)
end

local function collectVisualChildren(button)
	local icons = {}
	local labels = {}

	for _, descendant in ipairs(button:GetDescendants()) do
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			if #icons < 3 then
				table.insert(icons, descendant)
			end
		elseif descendant:IsA("TextLabel") then
			if #labels < 3 then
				table.insert(labels, descendant)
			end
		end
	end

	return icons, labels
end

local function bindMotionButton(button)
	if motionBound[button] or motionObjectCount >= MAX_MOTION_OBJECTS then
		return
	end
	if button:GetAttribute("BadWarsNoMotion") == true then
		return
	end

	motionBound[button] = true
	motionObjectCount += 1

	local scale = ensureMotionScale(button)
	local stroke, _, cornerSource = getMotionStroke(button)
	local icons, labels = collectVisualChildren(button)
	local hovered = false
	local pressed = false

	local originalIconTransparency = {}
	for _, icon in ipairs(icons) do
		originalIconTransparency[icon] = icon.ImageTransparency
	end

	local originalTextTransparency = {}
	for _, label in ipairs(labels) do
		originalTextTransparency[label] = label.TextTransparency
	end

	local function setState(state)
		local targetScale = 1
		local borderTransparency = 1
		local borderThickness = 1
		local iconTransparencyOffset = 0
		local textTransparencyOffset = 0

		if state == "hovered" then
			targetScale = 1.008
			borderTransparency = 0.82
			iconTransparencyOffset = -0.08
			textTransparencyOffset = -0.035
		elseif state == "pressed" then
			targetScale = 0.985
			borderTransparency = 0.62
			borderThickness = 1.15
			iconTransparencyOffset = -0.12
			textTransparencyOffset = -0.055
		end

		if scale then
			motionTween(scale, "button-scale", state == "pressed" and 0.07 or 0.15, {
				Scale = targetScale,
			})
		end

		if stroke then
			motionTween(stroke, "button-border", state == "pressed" and 0.07 or 0.15, {
				Transparency = borderTransparency,
				Thickness = borderThickness,
			})
		end

		for _, icon in ipairs(icons) do
			if icon.Parent then
				motionTween(icon, "icon-emphasis", 0.14, {
					ImageTransparency = math.clamp(
						(originalIconTransparency[icon] or 0) + iconTransparencyOffset,
						0,
						1
					),
				})
			end
		end

		for _, label in ipairs(labels) do
			if label.Parent then
				motionTween(label, "text-emphasis", 0.14, {
					TextTransparency = math.clamp(
						(originalTextTransparency[label] or 0) + textTransparencyOffset,
						0,
						1
					),
				})
			end
		end
	end

	trackResource(button.MouseEnter:Connect(function()
		hovered = true
		if not pressed then
			setState("hovered")
		end
	end))

	trackResource(button.MouseLeave:Connect(function()
		hovered = false
		if not pressed then
			setState("idle")
		end
	end))

	trackResource(button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end
		if pressed then
			return
		end

		pressed = true
		setState("pressed")
		createRipple(button, input.Position, cornerSource)
	end))

	trackResource(button.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		pressed = false
		setState(hovered and "hovered" or "idle")
	end))

	trackResource(button.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			local ripple = activeRipples[button]
			if ripple and ripple.Parent then
				ripple:Destroy()
			end
			activeRipples[button] = nil
			motionBound[button] = nil
		end
	end))
end

local function animatePassiveObject(object)
	if not object:IsA("CanvasGroup") then
		return
	end

	local name = string.lower(object.Name)
	if not (
		name:find("notification", 1, true)
		or name:find("dialog", 1, true)
		or name:find("popup", 1, true)
		or name:find("dropdown", 1, true)
	) then
		return
	end

	local scale = ensureMotionScale(object)
	local targetTransparency = object.GroupTransparency

	if scale then
		scale.Scale = 0.975
		motionTween(scale, "passive-scale", 0.16, { Scale = 1 })
	end

	object.GroupTransparency = math.min(1, targetTransparency + 0.35)
	motionTween(object, "passive-fade", 0.15, {
		GroupTransparency = targetTransparency,
	})
end

local function bindMotionObject(object)
	if typeof(object) ~= "Instance" then
		return
	end

	if object:IsA("GuiButton") then
		bindMotionButton(object)
	elseif object:IsA("CanvasGroup") then
		task.defer(animatePassiveObject, object)
	end
end

local function attachMotionRoot(root)
	if typeof(root) ~= "Instance" then
		return
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		bindMotionObject(descendant)
	end

	trackResource(root.DescendantAdded:Connect(bindMotionObject))
end

local function animateWindowMotion()
	local main = findWindowMain(Window)
	if typeof(main) ~= "Instance" or not main:IsA("GuiObject") then
		return
	end

	local scale = ensureMotionScale(main)
	if scale then
		scale.Scale = 0.985
		motionTween(scale, "window-scale", 0.18, { Scale = 1 })
	end

	if main:IsA("CanvasGroup") then
		main.GroupTransparency = 1
		motionTween(main, "window-fade", 0.15, {
			GroupTransparency = 0,
		})
	end
end

task.defer(function()
	attachMotionRoot(d.ScreenGui)
	attachMotionRoot(WindUI.DropdownGui)
	attachMotionRoot(WindUI.NotificationGui)
end)local function setWindowHidden(hidden)
	local main = findWindowMain(Window)
	if typeof(main) == "Instance" then
		pcall(function()
			main.Visible = not hidden
			if main:IsA("CanvasGroup") then
				main.GroupTransparency = hidden and 1 or 0
			end
		end)
	end
	forEachOpenButton(Window, function(object)
		setObjectVisible(object, not hidden)
	end)
end

setWindowHidden(true)

pcall(function()
	Window:Tag({
		Title = "v2.1",
		Icon = "badge-check",
		Color = Color3.fromHex("#FF2D4A"),
		Border = true,
	})
end)

local Tabs = {}
d.Tabs = Tabs

local tabMetadata = {
	General = { Icon = "home", Desc = "Quick actions and loader script" },
	Modules = { Icon = "list", Desc = "Module health and status" },
	Blatant = { Icon = "flame", Desc = "High-visibility modules" },
	Combat = { Icon = "sword", Desc = "Combat enhancements" },
	Render = { Icon = "eye", Desc = "Visuals and ESP" },
	Utility = { Icon = "wrench", Desc = "Automation tools" },
	World = { Icon = "globe", Desc = "Movement and world" },
	Minigames = { Icon = "gamepad-2", Desc = "Minigame modules" },
	Legit = { Icon = "user-check", Desc = "Legit modules" },
	Friends = { Icon = "users", Desc = "Friend settings" },
	Targets = { Icon = "crosshair", Desc = "Target config" },
	Notifications = { Icon = "bell", Desc = "Event history" },
	Settings = { Icon = "settings", Desc = "Appearance and profiles" },
}

local function ensureTab(name, metadata)
	name = tostring(name or "Misc")
	if Tabs[name] then
		return Tabs[name]
	end
	metadata = metadata or tabMetadata[name] or {}
	local tab = Window:Tab({
		Title = name,
		Icon = metadata.Icon or "folder",
		Desc = metadata.Desc or (name .. " modules"),
	})
	Tabs[name] = tab
	return tab
end

for _, name in ipairs({
	"General", "Modules", "Blatant", "Combat", "Render", "Utility", "World",
	"Minigames", "Legit", "Friends", "Targets", "Notifications", "Settings",
}) do
	ensureTab(name)
end

-- ─── Modules Tab ───
Tabs.Modules:Paragraph({
	Title = "Module Browser",
	Desc = "Modules are grouped by category. Each module is sandboxed — failures are isolated and recorded.",
})
Tabs.Modules:Paragraph({
	Title = "Controls",
	Desc = "RightShift toggles the window. Options sync with legacy module objects and persist via profile flags.",
})

local moduleHealthProgress
local moduleHealthLabel
local modulesLoaded = 0
local modulesTotal = 0

local function updateModuleHealth(ready, total)
	modulesLoaded = ready
	modulesTotal = total
	if moduleHealthProgress and type(moduleHealthProgress.Set) == "function" then
		local pct = total > 0 and math.floor((ready / total) * 100 + 0.5) or 0
		pcall(moduleHealthProgress.Set, moduleHealthProgress, pct)
	end
	if moduleHealthLabel and type(moduleHealthLabel.SetDesc) == "function" then
		pcall(moduleHealthLabel.SetDesc, moduleHealthLabel, string.format("%d / %d modules loaded", ready, total))
	end
end

moduleHealthProgress = Tabs.Modules:ProgressBar({
	Title = "Module Health",
	Desc = "Real-time loading progress",
	Value = { Min = 0, Max = 100, Default = 0 },
	DisplayMode = "Percent",
	Animate = true,
})

moduleHealthLabel = Tabs.Modules:Paragraph({
	Title = "Status",
	Desc = "Waiting for modules to load...",
})

-- Real-time module tracking
task.spawn(function()
	local lastCount = 0
	local finalReportDone = false
	while not d.Destroyed do
		task.wait(0.5)
		
		-- Get actual health data from Bad API
		local B = shared.Bad
		if B and type(B.GetBedWarsModuleHealth) == "function" then
			local report = B:GetBedWarsModuleHealth()
			if type(report) == "table" and report.Total and report.Total > 0 then
				updateModuleHealth(report.Ready or 0, report.Total)
				if not finalReportDone then
					finalReportDone = true
				end
				-- Keep updating for a while to catch late-loading modules
				if (report.Ready or 0) >= (report.Total or 0) then
					return
				end
				continue
			end
		end
		
		-- Fallback: count registered modules in adapter
		local currentCount = 0
		for _ in pairs(d.Modules) do
			currentCount += 1
		end
		
		if currentCount ~= lastCount then
			lastCount = currentCount
			-- Use actual count as both loaded and total (no guessing)
			updateModuleHealth(currentCount, currentCount)
		end
		
		-- Stop polling once we have a reasonable amount of modules
		if currentCount >= 50 then
			task.wait(3)
			-- One final check
			if B and type(B.GetBedWarsModuleHealth) == "function" then
				local report = B:GetBedWarsModuleHealth()
				if type(report) == "table" and report.Total and report.Total > 0 then
					updateModuleHealth(report.Ready or 0, report.Total)
				end
			end
			return
		end
	end
end)

-- ─── Notifications Tab ───
local notificationLog = {}
local MAX_NOTIFICATION_LOG = 60
local notificationsEnabled = true
local notificationParagraph

local function formatNotificationLog()
	local lines = {}
	for index = 1, math.min(#notificationLog, 20) do
		local entry = notificationLog[index]
		lines[index] = string.format("[%s] %s — %s", entry.time, entry.title, entry.text)
	end
	return #lines > 0 and table.concat(lines, "\n") or "No notifications yet."
end

local function refreshNotificationTab()
	local content = formatNotificationLog()
	if notificationParagraph then
		local ok = pcall(function()
			if type(notificationParagraph.SetDesc) == "function" then
				notificationParagraph:SetDesc(content)
			elseif type(notificationParagraph.Set) == "function" then
				notificationParagraph:Set(content)
			end
		end)
		if ok then
			return
		end
		-- Old paragraph is broken, destroy it and recreate
		pcall(function()
			if type(notificationParagraph.Destroy) == "function" then
				notificationParagraph:Destroy()
			end
		end)
		notificationParagraph = nil
	end
	notificationParagraph = Tabs.Notifications:Paragraph({
		Title = "Event Log",
		Desc = content,
	})
end

local function normalizeNotificationArguments(self, title, text, duration, notificationType)
	if self ~= d then
		notificationType = duration
		duration = text
		text = title
		title = self
	end
	return tostring(title or "BadWars"), tostring(text or ""), tonumber(duration) or 5, tostring(notificationType or "info")
end

function d.CreateNotification(self, title, text, duration, notificationType)
	title, text, duration, notificationType = normalizeNotificationArguments(self, title, text, duration, notificationType)
	local entry = {
		time = os.date("%X"),
		title = title,
		text = text,
		type = notificationType,
	}
	table.insert(notificationLog, 1, entry)
	if #notificationLog > MAX_NOTIFICATION_LOG then
		table.remove(notificationLog)
	end
	refreshNotificationTab()

	if notificationsEnabled and not d.Destroyed then
		local iconMap = {
			info = "info",
			warning = "alert-triangle",
			error = "x-octagon",
			success = "check-circle",
		}
		pcall(function()
			WindUI:Notify({
				Title = title,
				Content = text,
				Icon = iconMap[notificationType] or "bell",
				Duration = duration,
			})
		end)
	end
	return entry
end

function d.PushNotification(title, text, notificationType)
	return d:CreateNotification(title, text, 5, notificationType)
end

Tabs.Notifications:Paragraph({
	Title = "Notification System",
	Desc = "Toasts and the persistent event log share one notification pipeline.",
})
Tabs.Notifications:Button({
	Title = "Clear Notifications",
	Icon = "trash",
	Callback = function()
		table.clear(notificationLog)
		refreshNotificationTab()
	end,
})
Tabs.Notifications:Toggle({
	Title = "Show Toast Notifications",
	Value = true,
	Flag = "settings/notifications_enabled",
	Callback = function(value)
		notificationsEnabled = value == true
	end,
})
Tabs.Notifications:Space()
refreshNotificationTab()

-- ─── Core helpers ───
local function reportCallbackError(context, err)
	d:CreateNotification("Module Error", tostring(context) .. ": " .. tostring(err), 7, "error")
end

local function runUserCallback(context, callback, ...)
	local ok, result = safeCall(callback, ...)
	if not ok then
		reportCallbackError(context, result)
	end
	return ok, result
end

local function setControlValue(control, value, ...)
	if type(control) ~= "table" then
		return false
	end
	local args = pack(...)
	local candidates = { "SetValue", "SetState", "Set", "Select", "Update" }
	for _, methodName in ipairs(candidates) do
		local method = control[methodName]
		if type(method) == "function" then
			local ok = pcall(function()
				method(control, value, unpackPacked(args))
			end)
			if ok then
				return true
			end
		end
	end
	return false
end

local function setControlVisible(control, visible)
	if type(control) ~= "table" then
		return
	end

	if type(control.SetVisible) == "function" then
		pcall(control.SetVisible, control, visible)
		return
	end

	local target = control.ElementFrame
	if typeof(target) ~= "Instance" and type(control.UIElements) == "table" then
		target = control.UIElements.Main
	end

	setObjectVisible(target, visible)
end
local function destroyControl(control)
	if type(control) == "table" and type(control.Destroy) == "function" then
		pcall(control.Destroy, control)
	end
end

-- ─── Option API ───
local function makeOptionApi(spec)
	spec = spec or {}
	local api = {
		Name = tostring(spec.Name or "Option"),
		Type = tostring(spec.Type or "Option"),
		Value = cloneValue(spec.Value),
		Default = cloneValue(spec.Value),
		Object = nil,
		Enabled = spec.Type == "Toggle" and spec.Value == true or nil,
		Visible = true,
		Destroyed = false,
	}
	local callback = spec.Callback
	local callbackOnSet = spec.CallbackOnSet ~= false

	local function assignValue(value)
		api.Value = cloneValue(value)
		if api.Type == "Toggle" then
			api.Enabled = value == true
		end
	end

	function api:_FromControl(value, ...)
		if api.Destroyed then
			return api
		end
		local changed = not valuesEqual(api.Value, value)
		assignValue(value)
		if changed or spec.AlwaysCallback then
			runUserCallback(api.Name, callback, value, ...)
		end
		return api
	end

	function api:SetValue(value, silent, ...)
		if api.Destroyed then
			return api
		end
		local changed = not valuesEqual(api.Value, value)
		assignValue(value)
		setControlValue(api.Object, value, ...)
		if changed and silent ~= true and callbackOnSet then
			runUserCallback(api.Name, callback, value, ...)
		end
		return api
	end

	api.Set = api.SetValue
	api.SetState = api.SetValue
	api.Update = api.SetValue

	function api:GetValue()
		return api.Value
	end

	function api:Toggle()
		return api:SetValue(not (api.Value == true))
	end

	function api:SetCallback(newCallback)
		if type(newCallback) == "function" then
			callback = newCallback
		end
		return api
	end

	function api:SetVisible(visible)
		api.Visible = visible ~= false
		setControlVisible(api.Object, api.Visible)
		return api
	end

	function api:Save()
		return cloneValue(api.Value)
	end

	function api:Load(value, silent)
		return api:SetValue(value, silent)
	end

	function api:Destroy()
		if not api.Destroyed then
			api.Destroyed = true
			destroyControl(api.Object)
			api.Object = nil
		end
	end

	return api
end

local function enableDotAndColon(object, methodName)
	local original = object[methodName]
	if type(original) ~= "function" then
		return
	end
	object[methodName] = function(first, ...)
		if first == object then
			return original(object, ...)
		end
		return original(object, first, ...)
	end
end

-- BADWARS_OPTION_COMPAT_V2
local visibilityApplying = setmetatable({}, { __mode = "k" })

local function installLegacyVisibilityProxy(option)
	local control = option.Object
	if type(control) ~= "table" or rawget(control, "__BadWarsVisibilityProxy") then
		return
	end

	local currentMetatable = getmetatable(control)
	if currentMetatable ~= nil and type(currentMetatable) ~= "table" then
		return
	end

	local previousIndex = currentMetatable and currentMetatable.__index
	local previousNewIndex = currentMetatable and currentMetatable.__newindex
	local proxy = {}
	if currentMetatable then
		for key, value in pairs(currentMetatable) do proxy[key] = value end
	end

	if rawget(control, "Visible") ~= nil then
		option.Visible = rawget(control, "Visible") ~= false
		rawset(control, "Visible", nil)
	end

	proxy.__index = function(target, key)
		if key == "Visible" then
			return option.Visible ~= false
		end
		if type(previousIndex) == "function" then
			return previousIndex(target, key)
		elseif type(previousIndex) == "table" then
			return previousIndex[key]
		end
		return rawget(target, key)
	end

	proxy.__newindex = function(target, key, value)
		if key == "Visible" then
			option.Visible = value ~= false
			if not visibilityApplying[target] then
				visibilityApplying[target] = true
				setControlVisible(target, option.Visible)
				visibilityApplying[target] = nil
			end
			return
		end
		if type(previousNewIndex) == "function" then
			return previousNewIndex(target, key, value)
		elseif type(previousNewIndex) == "table" then
			previousNewIndex[key] = value
			return
		end
		rawset(target, key, value)
	end

	local ok = pcall(setmetatable, control, proxy)
	if ok then
		rawset(control, "__BadWarsVisibilityProxy", true)
	end
end

local function registerOption(module, name, option, settings)
	settings = settings or {}
	local baseName = tostring(name or option.Name or option.Type)
	local uniqueName = baseName
	local suffix = 2
	while module.Options[uniqueName] and module.Options[uniqueName] ~= option do
		uniqueName = baseName .. " " .. suffix
		suffix += 1
	end
	option.Name = uniqueName
	option.Visible = settings.Visible ~= false
	module.Options[uniqueName] = option
	installLegacyVisibilityProxy(option)
	if option.Visible == false then
		task.defer(function()
			if not option.Destroyed then setControlVisible(option.Object, false) end
		end)
	end
	return option
end
local function makeFlag(categoryName, moduleName, optionName)
	return sanitizeName(string.format("%s/%s/%s", categoryName, moduleName, optionName))
end

local function resolveFlag(module, settings, optionName)
	if module.NoSave or settings.NoSave then
		return nil
	end
	return settings.Flag or makeFlag(module.Category, module.Name, optionName)
end

-- ─── Control creators ───
local function createToggleOption(module, section, settings)
	settings = settings or {}
	local initial = firstNonNil(settings.Default, settings.Value, settings.Enabled, false) == true
	local option = makeOptionApi({
		Name = settings.Name or "Toggle",
		Type = "Toggle",
		Value = initial,
		Callback = settings.Function or settings.Callback,
	})
	option.Object = section:Toggle({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Value = initial,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(value)
			option:_FromControl(value == true)
		end,
	})
	return registerOption(module, option.Name, option, settings)
end

local function createSliderOption(module, section, settings)
	settings = settings or {}
	local minimum = tonumber(firstNonNil(settings.Min, settings.MinValue, settings.Minimum, 0)) or 0
	local maximum = tonumber(firstNonNil(settings.Max, settings.MaxValue, settings.Maximum, 100)) or 100
	if maximum < minimum then
		minimum, maximum = maximum, minimum
	end
	local initial = tonumber(firstNonNil(settings.Default, settings.Value, settings.Current, minimum)) or minimum
	initial = math.clamp(initial, minimum, maximum)
	local option = makeOptionApi({
		Name = settings.Name or "Slider",
		Type = "Slider",
		Value = initial,
		Callback = settings.Function or settings.Callback,
	})
	option.Min = minimum
	option.Max = maximum
	option.Step = tonumber(firstNonNil(settings.Step, settings.Increment, settings.Round, 1)) or 1
	option.Object = section:Slider({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Value = { Min = minimum, Max = maximum, Default = initial },
		Step = option.Step,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(value)
			option:_FromControl(value)
		end,
	})
	function option:SetMin(value)
		value = tonumber(value) or option.Min
		option.Min = value
		if type(option.Object) == "table" and type(option.Object.SetMin) == "function" then
			pcall(option.Object.SetMin, option.Object, value)
		end
		return option
	end
	function option:SetMax(value)
		value = tonumber(value) or option.Max
		option.Max = value
		if type(option.Object) == "table" and type(option.Object.SetMax) == "function" then
			pcall(option.Object.SetMax, option.Object, value)
		end
		return option
	end
	return registerOption(module, option.Name, option, settings)
end

local function createDropdownOption(module, section, settings)
	settings = settings or {}
	local values = shallowCopy(firstNonNil(settings.List, settings.Values, settings.Options, {}))
	local multi = firstNonNil(settings.Multi, settings.Multiple, settings.Multiselect, false) == true
	local initial = firstNonNil(settings.Default, settings.Value, settings.Selected)
	if initial == nil then
		initial = multi and {} or values[1]
	end
	local option = makeOptionApi({
		Name = settings.Name or "Dropdown",
		Type = "Dropdown",
		Value = initial,
		Callback = settings.Function or settings.Callback,
	})
	option.List = values
	option.Values = values
	option.Multi = multi
	option.Object = section:Dropdown({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Values = values,
		Value = initial,
		Multi = multi,
		AllowNone = settings.AllowNone,
		SearchBarEnabled = firstNonNil(settings.Search, settings.Searchable, settings.SearchBarEnabled, false),
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(value)
			option:_FromControl(value)
		end,
	})
	function option:SetList(newValues, selected, silent)
		newValues = type(newValues) == "table" and shallowCopy(newValues) or {}
		option.List = newValues
		option.Values = newValues
		if type(option.Object) == "table" then
			if type(option.Object.SetValues) == "function" then
				pcall(option.Object.SetValues, option.Object, newValues, selected)
			elseif type(option.Object.Refresh) == "function" then
				pcall(option.Object.Refresh, option.Object, newValues)
			end
		end
		if selected ~= nil then
			option:SetValue(selected, silent)
		end
		return option
	end
	option.Refresh = option.SetList
	return registerOption(module, option.Name, option, settings)
end

local function createColorOption(module, section, settings, hsvCallback)
	settings = settings or {}
	local initialColor = normalizeColor(firstNonNil(settings.Default, settings.Value, settings.Color))
	local initialTransparency = tonumber(firstNonNil(settings.Transparency, settings.Opacity and (1 - settings.Opacity), 0)) or 0
	local hue, sat, val = initialColor:ToHSV()
	local option = makeOptionApi({
		Name = settings.Name or "Color",
		Type = hsvCallback and "ColorSlider" or "Colorpicker",
		Value = initialColor,
		Callback = nil,
		CallbackOnSet = false,
	})
	option.Hue = hue
	option.Sat = sat
	option.Saturation = sat
	option.Brightness = val
	option.Color = initialColor
	option.Opacity = 1 - initialTransparency
	option.Transparency = initialTransparency
	local userCallback = settings.Function or settings.Callback

	local function applyColor(color, transparency, silent, updateControl)
		color = normalizeColor(color)
		transparency = tonumber(transparency)
		if transparency == nil then
			transparency = option.Transparency or 0
		end
		local h, s, v = color:ToHSV()
		local changed = not valuesEqual(option.Value, color) or option.Transparency ~= transparency
		option.Value = color
		option.Color = color
		option.Hue = h
		option.Sat = s
		option.Saturation = s
		option.Brightness = v
		option.Transparency = transparency
		option.Opacity = 1 - transparency
		if updateControl then
			setControlValue(option.Object, color, transparency)
		end
		if changed and silent ~= true then
			if hsvCallback then
				runUserCallback(option.Name, userCallback, h, s, v, option.Opacity)
			else
				runUserCallback(option.Name, userCallback, color, transparency)
			end
		end
		return option
	end

	option.Object = section:Colorpicker({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Default = initialColor,
		Transparency = initialTransparency,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(color, transparency)
			applyColor(color, transparency, false, false)
		end,
	})

	function option:SetValue(value, satValue, brightnessValue, opacityOrSilent, silent)
		if type(value) == "number" and type(satValue) == "number" and type(brightnessValue) == "number" then
			local opacity = type(opacityOrSilent) == "number" and opacityOrSilent or option.Opacity
			return applyColor(Color3.fromHSV(value, satValue, brightnessValue), 1 - opacity, silent == true, true)
		end
		local isSilent = opacityOrSilent == true
		local transparency = type(satValue) == "number" and satValue or option.Transparency
		return applyColor(value, transparency, isSilent, true)
	end
	option.Set = option.SetValue
	return registerOption(module, option.Name, option, settings)
end

local function createKeybindOption(module, section, settings)
	settings = settings or {}
	local initial = normalizeKey(firstNonNil(settings.Default, settings.Value, settings.Key, "F"))
	local option = makeOptionApi({
		Name = settings.Name or "Keybind",
		Type = "Keybind",
		Value = initial,
		Callback = settings.Function or settings.Callback,
		CallbackOnSet = false,
		AlwaysCallback = true,
	})
	option.Object = section:Keybind({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Value = initial,
		CanChange = settings.CanChange ~= false,
		Blacklist = settings.Blacklist,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(key)
			option.Value = normalizeKey(option.Object and option.Object.Value or key)
			runUserCallback(option.Name, settings.Function or settings.Callback, key)
		end,
	})
	-- Safe keybind label tracking — wrapped in deep pcall to survive WindUI structure changes
	pcall(function()
		if type(option.Object) ~= "table" or type(option.Object.UIElements) ~= "table" then
			return
		end
		local kb = option.Object.UIElements.Keybind
		if type(kb) ~= "table" or type(kb.Frame) ~= "table" then
			return
		end
		local inner = kb.Frame.Frame or kb.Frame
		if type(inner) ~= "table" or typeof(inner.TextLabel) ~= "Instance" then
			return
		end
		local label = inner.TextLabel
		local connection = label:GetPropertyChangedSignal("Text"):Connect(function()
			local text = tostring(label.Text or "")
			if text ~= "" and text ~= "..." then
				option.Value = normalizeKey(option.Object.Value or text)
			end
		end)
		table.insert(d.Resources, connection)
	end)
	function option:SetValue(value, silent)
		option.Value = normalizeKey(value)
		setControlValue(option.Object, option.Value)
		if silent ~= true and settings.OnChanged then
			runUserCallback(option.Name .. " changed", settings.OnChanged, option.Value)
		end
		return option
	end
	option.Set = option.SetValue
	return registerOption(module, option.Name, option, settings)
end

local function createInputOption(module, section, settings)
	settings = settings or {}
	local initial = tostring(firstNonNil(settings.Default, settings.Value, settings.Text, ""))
	local option = makeOptionApi({
		Name = settings.Name or "Input",
		Type = "Input",
		Value = initial,
		Callback = settings.Function or settings.Callback,
	})
	option.Object = section:Input({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Value = initial,
		Placeholder = firstNonNil(settings.Placeholder, settings.PlaceholderText, "Enter text..."),
		ClearTextOnFocus = settings.ClearTextOnFocus,
		Type = settings.Type,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(value)
			option:_FromControl(value)
		end,
	})
	return registerOption(module, option.Name, option, settings)
end

local function createTwoSliderOption(module, section, settings)
	settings = settings or {}
	local minimum = tonumber(firstNonNil(settings.Min, settings.MinValue, 0)) or 0
	local maximum = tonumber(firstNonNil(settings.Max, settings.MaxValue, 100)) or 100
	if maximum < minimum then
		minimum, maximum = maximum, minimum
	end
	local initialMin = math.clamp(tonumber(firstNonNil(settings.DefaultMin, settings.ValueMin, minimum)) or minimum, minimum, maximum)
	local initialMax = math.clamp(tonumber(firstNonNil(settings.DefaultMax, settings.ValueMax, maximum)) or maximum, minimum, maximum)
	if initialMax < initialMin then
		initialMin, initialMax = initialMax, initialMin
	end
	local option = {
		Name = tostring(settings.Name or "Range"),
		Type = "TwoSlider",
		ValueMin = initialMin,
		ValueMax = initialMax,
		Min = minimum,
		Max = maximum,
		Visible = true,
		Destroyed = false,
	}
	local userCallback = settings.Function or settings.Callback
	local setting = false
	local minControl
	local maxControl

	local function emit(silent)
		if silent ~= true then
			runUserCallback(option.Name, userCallback, option.ValueMin, option.ValueMax)
		end
	end

	minControl = section:Slider({
		Title = option.Name .. " Min",
		Desc = normalizeDescription(settings),
		Value = { Min = minimum, Max = maximum, Default = initialMin },
		Step = settings.Step or 1,
		Flag = resolveFlag(module, settings, option.Name .. "_min"),
		Callback = function(value)
			if setting then return end
			option.ValueMin = math.min(value, option.ValueMax)
			emit(false)
		end,
	})
	maxControl = section:Slider({
		Title = option.Name .. " Max",
		Value = { Min = minimum, Max = maximum, Default = initialMax },
		Step = settings.Step or 1,
		Flag = resolveFlag(module, settings, option.Name .. "_max"),
		Callback = function(value)
			if setting then return end
			option.ValueMax = math.max(value, option.ValueMin)
			emit(false)
		end,
	})
	option.Object = { MinSlider = minControl, MaxSlider = maxControl }

	function option:SetValue(valueMin, valueMax, silent)
		valueMin = math.clamp(tonumber(valueMin) or option.ValueMin, minimum, maximum)
		valueMax = math.clamp(tonumber(valueMax) or option.ValueMax, minimum, maximum)
		if valueMax < valueMin then
			valueMin, valueMax = valueMax, valueMin
		end
		local changed = valueMin ~= option.ValueMin or valueMax ~= option.ValueMax
		option.ValueMin, option.ValueMax = valueMin, valueMax
		setting = true
		setControlValue(minControl, valueMin)
		setControlValue(maxControl, valueMax)
		setting = false
		if changed then emit(silent) end
		return option
	end
	option.Set = option.SetValue
	function option:SetVisible(visible)
		option.Visible = visible ~= false
		setControlVisible(minControl, option.Visible)
		setControlVisible(maxControl, option.Visible)
		return option
	end
	function option:Save()
		return { ValueMin = option.ValueMin, ValueMax = option.ValueMax }
	end
	function option:Load(value, silent)
		if type(value) == "table" then
			return option:SetValue(value.ValueMin or value[1], value.ValueMax or value[2], silent)
		end
		return option
	end
	function option:Destroy()
		if not option.Destroyed then
			option.Destroyed = true
			destroyControl(minControl)
			destroyControl(maxControl)
		end
	end
	return registerOption(module, option.Name, option, settings)
end

local function createTextListOption(module, section, settings)
	settings = settings or {}
	local initial = cloneValue(firstNonNil(settings.Default, settings.Value, settings.List, {}))
	if type(initial) ~= "table" then
		initial = {}
	end
	local option = makeOptionApi({
		Name = settings.Name or "Text List",
		Type = "TextList",
		Value = initial,
		Callback = settings.Function or settings.Callback,
		CallbackOnSet = false,
	})
	option.List = option.Value
	option.ObjectList = option.Value
	option.ListEnabled = option.Value -- BADWARS_TEXTLIST_LISTENABLED_V1
	option.Object = section:Input({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Placeholder = firstNonNil(settings.Placeholder, "Enter text and press Enter"),
		Value = "",
		Callback = function(value)
			value = tostring(value or "")
			if value ~= "" then
				option:Add(value)
				setControlValue(option.Object, "")
			end
		end,
	})

	local function syncList(silent)
		option.List = option.Value
		option.ObjectList = option.Value
	option.ListEnabled = option.Value -- BADWARS_TEXTLIST_LISTENABLED_V1
		if silent ~= true then
			runUserCallback(option.Name, settings.Function or settings.Callback, option.Value)
		end
	end

	function option:Add(value, silent)
		value = tostring(value or "")
		if value ~= "" and not table.find(option.Value, value) then
			table.insert(option.Value, value)
			syncList(silent)
		end
		return option
	end
	function option:Remove(value, silent)
		local index = type(value) == "number" and value or table.find(option.Value, value)
		if index and option.Value[index] ~= nil then
			table.remove(option.Value, index)
			syncList(silent)
		end
		return option
	end
	function option:Clear(silent)
		table.clear(option.Value)
		syncList(silent)
		return option
	end
	function option:SetValue(values, silent)
		option.Value = type(values) == "table" and cloneValue(values) or {}
		syncList(silent)
		return option
	end
	option.Set = option.SetValue
	return registerOption(module, option.Name, option, settings)
end

-- BADWARS_FONT_COMPAT_V2
local function createFontOption(module, section, settings)
	settings = settings or {}
	local sourceFonts = firstNonNil(settings.List, settings.Values, {
		"Gotham", "Arial", "SourceSans", "Roboto", "Ubuntu", "Fantasy", "Code", "Highway",
	})
	local blacklist = settings.Blacklist
	local fonts = {}

	local function blocked(name)
		if type(blacklist) == "string" then
			return name == blacklist
		end
		return type(blacklist) == "table" and table.find(blacklist, name) ~= nil
	end

	for _, name in ipairs(sourceFonts) do
		name = tostring(name)
		if not blocked(name) and Enum.Font[name] then
			table.insert(fonts, name)
		end
	end
	if #fonts == 0 then fonts = { "Gotham", "Arial" } end

	local function resolveFont(value)
		if typeof(value) == "Font" then
			return value, fonts[1]
		end
		if typeof(value) == "EnumItem" then
			local ok, converted = pcall(Font.fromEnum, value)
			return ok and converted or Font.fromEnum(Enum.Font.Gotham), value.Name
		end
		local name = tostring(value or fonts[1])
		if not Enum.Font[name] then name = fonts[1] end
		local ok, converted = pcall(Font.fromEnum, Enum.Font[name])
		return ok and converted or Font.fromEnum(Enum.Font.Gotham), name
	end

	local initialFont, initialName = resolveFont(firstNonNil(settings.Default, settings.Value, fonts[1]))
	local option = makeOptionApi({
		Name = settings.Name or "Font",
		Type = "Font",
		Value = initialFont,
		Callback = nil,
		CallbackOnSet = false,
	})
	option.List = fonts
	option.Font = initialFont
	local userCallback = settings.Function or settings.Callback

	option.Object = section:Dropdown({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Values = fonts,
		Value = initialName,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(value)
			local font, fontName = resolveFont(value)
			option.Value = font
			option.Font = font
			option.Selected = fontName
			runUserCallback(option.Name, userCallback, font)
		end,
	})

	function option:SetValue(value, silent)
		local font, fontName = resolveFont(value)
		local changed = option.Value ~= font
		option.Value = font
		option.Font = font
		option.Selected = fontName
		setControlValue(option.Object, fontName)
		if changed and silent ~= true then
			runUserCallback(option.Name, userCallback, font)
		end
		return option
	end
	option.Set = option.SetValue

	return registerOption(module, option.Name, option, settings)
end
-- BADWARS_TARGETS_COMPAT_V2
local function createTargetsOption(module, section, settings)
	settings = settings or {}
	local labels = {}
	local defaults = {}
	local wrappers = {}

	local function addTarget(label, enabled)
		table.insert(labels, label)
		defaults[label] = enabled ~= false
	end

	if settings.Players ~= false then addTarget("Players", settings.Players) end
	if settings.NPCs or settings.NPC then addTarget("NPCs", true) end
	if settings.Friends ~= false then addTarget("Friends", settings.Friends) end
	if settings.Walls ~= nil then addTarget("Walls", settings.Walls) end
	if #labels == 0 then
		addTarget("Players", true)
		addTarget("NPCs", true)
		addTarget("Friends", true)
	end

	local selected = {}
	for _, label in ipairs(labels) do
		if defaults[label] then table.insert(selected, label) end
	end

	local option = {
		Name = tostring(settings.Name or "Targets"),
		Type = "Targets",
		Value = cloneValue(defaults),
		Visible = settings.Visible ~= false,
		Destroyed = false,
	}

	for label, enabled in pairs(defaults) do
		wrappers[label] = { Enabled = enabled, Value = enabled }
		option[label] = wrappers[label]
	end

	local userCallback = settings.Function or settings.Callback

	local function fromSelected(current, silent)
		local map = {}
		for _, label in ipairs(labels) do map[label] = false end
		for _, value in ipairs(type(current) == "table" and current or {}) do
			local label = type(value) == "table" and value.Title or value
			if map[label] ~= nil then map[label] = true end
		end

		local changed = not valuesEqual(option.Value, map)
		option.Value = map
		for label, enabled in pairs(map) do
			local wrapper = wrappers[label] or { Enabled = false, Value = false }
			wrapper.Enabled = enabled
			wrapper.Value = enabled
			wrappers[label] = wrapper
			option[label] = wrapper
		end
		if changed and silent ~= true then
			runUserCallback(option.Name, userCallback, map)
		end
	end

	option.Object = section:Dropdown({
		Title = option.Name,
		Desc = normalizeDescription(settings),
		Values = labels,
		Value = selected,
		Multi = true,
		AllowNone = true,
		Flag = resolveFlag(module, settings, option.Name),
		Callback = function(current)
			fromSelected(current, false)
		end,
	})

	function option:SetValue(value, silent)
		local newSelected = {}
		if type(value) == "table" then
			for _, label in ipairs(labels) do
				local candidate = value[label]
				local enabled = type(candidate) == "table" and candidate.Enabled == true or candidate == true
				if enabled or table.find(value, label) then
					table.insert(newSelected, label)
				end
			end
		end
		fromSelected(newSelected, silent)
		setControlValue(option.Object, newSelected)
		return option
	end
	option.Set = option.SetValue

	function option:SetVisible(visible)
		option.Visible = visible ~= false
		setControlVisible(option.Object, option.Visible)
		return option
	end

	function option:Save()
		return cloneValue(option.Value)
	end

	function option:Load(value, silent)
		return option:SetValue(value, silent)
	end

	function option:Destroy()
		if not option.Destroyed then
			option.Destroyed = true
			destroyControl(option.Object)
		end
	end

	return registerOption(module, option.Name, option, settings)
end
local categoryIcons = {
	Combat = "sword",
	Blatant = "flame",
	Render = "eye",
	Utility = "wrench",
	World = "globe",
	Minigames = "gamepad-2",
	Legit = "user-check",
	Friends = "users",
	Targets = "crosshair",
}

local function createCategoryObject(name, iconName, suppliedTab)
	name = tostring(name or "Misc")
	if d.Categories[name] and d.Categories[name].Type ~= "ServiceCategory" then
		return d.Categories[name]
	end
	local tab = suppliedTab or ensureTab(name, { Icon = iconName or categoryIcons[name] or "folder" })
	local category = {
		Name = name,
		Type = "Category",
		Tab = tab,
		Modules = {},
		Options = {},
	}

	function category:CreateModule(settings)
		settings = settings or {}
		local moduleName = tostring(settings.Name or "Unnamed")
		if category.Modules[moduleName] then
			return category.Modules[moduleName]
		end
		local moduleCallback = settings.Function or settings.Callback or function() end
		local module = {
			Name = moduleName,
			Category = name,
			Enabled = firstNonNil(settings.Default, settings.Enabled, false) == true,
			Options = {},
			Connections = {},
			Bind = type(settings.Bind) == "table" and settings.Bind or { Value = settings.Bind },
			Function = moduleCallback,
			ExtraText = settings.ExtraText,
			NoSave = settings.NoSave,
			Destroyed = false,
		}
		local baseDescription = normalizeDescription(settings)
		local section = tab:Section({
			Title = moduleName,
			Desc = baseDescription,
			Opened = settings.Opened ~= false and settings.Expanded ~= false,
			Box = settings.Box,
		})
		module.Section = section

		local function setEnabled(state, sourceIsControl, silent)
			state = state == true
			if module.Destroyed or module.Enabled == state then
				return module
			end
			module.Enabled = state
			if not sourceIsControl then
				setControlValue(module.Object, state)
			end
			if silent ~= true then
				task.spawn(function()
					runUserCallback(moduleName, moduleCallback, state)
				end)
			end
			return module
		end

		module.Object = section:Toggle({
			Title = "Enabled",
			Desc = "Enable or disable " .. moduleName,
			Value = module.Enabled,
			Flag = (settings.NoSave and nil or (settings.Flag or sanitizeName(name .. "/" .. moduleName .. "/enabled"))),
			Callback = function(state)
				setEnabled(state, true, false)
			end,
		})

		function module:SetEnabled(state, silent)
			return setEnabled(state, false, silent)
		end
		module.SetState = module.SetEnabled
		function module:Toggle(silent)
			return module:SetEnabled(not module.Enabled, silent)
		end
		function module:SetExtraText(text)
			module.ExtraText = text
			local description = baseDescription
			if text ~= nil and tostring(text) ~= "" then
				description = description ~= "" and (description .. " \u{2022} " .. tostring(text)) or tostring(text)
			end
			pcall(function()
				if type(section.SetDesc) == "function" then section:SetDesc(description) end
			end)
			return module
		end
		function module:Clean(resource)
			if resource ~= nil then table.insert(module.Connections, resource) end
			return resource
		end
		function module:Destroy()
			if module.Destroyed then return end
			module.Destroyed = true
			if module.Enabled then
				module.Enabled = false
				runUserCallback(moduleName, moduleCallback, false)
			end
			for _, option in pairs(module.Options) do
				if type(option) == "table" and type(option.Destroy) == "function" then
					pcall(option.Destroy, option)
				end
			end
			for index = #module.Connections, 1, -1 do
				local resource = module.Connections[index]
				if isConnection(resource) then
					pcall(resource.Disconnect, resource)
				elseif type(resource) == "function" then
					pcall(resource)
				elseif type(resource) == "table" and type(resource.Destroy) == "function" then
					pcall(resource.Destroy, resource)
				end
			end
			pcall(function() if type(section.Destroy) == "function" then section:Destroy() end end)
			category.Modules[moduleName] = nil
			-- Remove from d.Modules using both keys
			d.Modules[name .. "/" .. moduleName] = nil
			-- Only remove short key if it still points to this module
			if d.Modules[moduleName] == module then
				d.Modules[moduleName] = nil
			end
		end

		function module:CreateToggle(optionSettings)
			return createToggleOption(module, section, optionSettings)
		end
		function module:CreateSlider(optionSettings)
			return createSliderOption(module, section, optionSettings)
		end
		function module:CreateDropdown(optionSettings)
			return createDropdownOption(module, section, optionSettings)
		end
		function module:CreateColorSlider(optionSettings)
			return createColorOption(module, section, optionSettings, true)
		end
		function module:CreateColorpicker(optionSettings)
			return createColorOption(module, section, optionSettings, false)
		end
		module.CreateColorPicker = module.CreateColorpicker
		function module:CreateKeybind(optionSettings)
			return createKeybindOption(module, section, optionSettings)
		end
		function module:CreateInput(optionSettings)
			return createInputOption(module, section, optionSettings)
		end
		module.CreateTextBox = module.CreateInput
		function module:CreateTwoSlider(optionSettings)
			return createTwoSliderOption(module, section, optionSettings)
		end
		function module:CreateTextList(optionSettings)
			return createTextListOption(module, section, optionSettings)
		end
		function module:CreateFont(optionSettings)
			return createFontOption(module, section, optionSettings)
		end
		function module:CreateTargets(optionSettings)
			return createTargetsOption(module, section, optionSettings)
		end
		function module:CreateButton(optionSettings)
			optionSettings = optionSettings or {}
			local button = section:Button({
				Title = optionSettings.Name or "Action",
				Desc = normalizeDescription(optionSettings),
				Icon = optionSettings.Icon,
				Callback = function()
					runUserCallback(optionSettings.Name or moduleName, optionSettings.Function or optionSettings.Callback)
				end,
			})
			return {
				Name = optionSettings.Name or "Action",
				Type = "Button",
				Object = button,
				Press = function()
					runUserCallback(optionSettings.Name or moduleName, optionSettings.Function or optionSettings.Callback)
				end,
				Destroy = function()
					destroyControl(button)
				end,
			}
		end
		function module:CreateParagraph(optionSettings)
			optionSettings = optionSettings or {}
			return section:Paragraph({
				Title = optionSettings.Name or optionSettings.Title or "Info",
				Desc = firstNonNil(optionSettings.Desc, optionSettings.Content, optionSettings.Text, ""),
			})
		end
		module.CreateLabel = module.CreateParagraph
		function module:CreateDivider()
			return section:Divider({})
		end
		function module:CreateSpace()
			return section:Space({})
		end
		function module:CreateProgressBar(optionSettings)
			optionSettings = optionSettings or {}
			local minimum = tonumber(firstNonNil(optionSettings.Min, optionSettings.MinValue, 0)) or 0
			local maximum = tonumber(firstNonNil(optionSettings.Max, optionSettings.MaxValue, 100)) or 100
			if maximum < minimum then minimum, maximum = maximum, minimum end
			local initial = tonumber(firstNonNil(optionSettings.Default, optionSettings.Value, optionSettings.Current, minimum)) or minimum
			initial = math.clamp(initial, minimum, maximum)
			local option = makeOptionApi({
				Name = optionSettings.Name or "Progress",
				Type = "ProgressBar",
				Value = initial,
				Callback = nil,
				CallbackOnSet = false,
			})
			option.Min = minimum
			option.Max = maximum
			option.Object = section:ProgressBar({
				Title = option.Name,
				Desc = normalizeDescription(optionSettings),
				Value = { Min = minimum, Max = maximum, Default = initial },
				ShowValue = optionSettings.ShowValue,
				DisplayMode = optionSettings.DisplayMode or "Percent",
				Format = optionSettings.Format,
				Animate = optionSettings.Animate ~= false,
				Indeterminate = optionSettings.Indeterminate == true,
				IndeterminateText = optionSettings.IndeterminateText,
				Speed = optionSettings.Speed,
				Width = optionSettings.Width,
				ValueWidth = optionSettings.ValueWidth,
			})
			function option:SetValue(value)
				value = math.clamp(tonumber(value) or option.Value, minimum, maximum)
				option.Value = value
				if type(option.Object) == "table" and type(option.Object.Set) == "function" then
					pcall(option.Object.Set, option.Object, value)
				end
				return option
			end
			option.Set = option.SetValue
			function option:GetValue()
				if type(option.Object) == "table" and type(option.Object.Get) == "function" then
					return option.Object:Get()
				end
				return option.Value
			end
			function option:GetPercentage()
				if type(option.Object) == "table" and type(option.Object.GetPercentage) == "function" then
					return option.Object:GetPercentage()
				end
				return ((option.Value - minimum) / (maximum - minimum)) * 100
			end
			function option:SetRange(min, max)
				option.Min = min
				option.Max = max
				if type(option.Object) == "table" and type(option.Object.SetRange) == "function" then
					pcall(option.Object.SetRange, option.Object, min, max)
				end
				return option
			end
			return registerOption(module, option.Name, option, settings)
		end
		function module:CreateCode(optionSettings)
			optionSettings = optionSettings or {}
			local codeObj = section:Code({
				Title = optionSettings.Name or optionSettings.Title,
				Code = tostring(optionSettings.Code or optionSettings.Content or ""),
				CodeSize = optionSettings.CodeSize,
				CanCopied = optionSettings.CanCopied ~= false,
				Height = optionSettings.Height,
				OnCopy = optionSettings.OnCopy,
			})
			return {
				Name = optionSettings.Name or optionSettings.Title or "Code",
				Type = "Code",
				Object = codeObj,
				SetCode = function(self, code)
					if type(codeObj) == "table" and type(codeObj.SetCode) == "function" then
						pcall(codeObj.SetCode, codeObj, code)
					end
				end,
				Destroy = function()
					destroyControl(codeObj)
				end,
			}
		end
		function module:CreateImage(optionSettings)
			optionSettings = optionSettings or {}
			local imageObj = section:Image({
				Image = tostring(optionSettings.Image or optionSettings.Url or ""),
				AspectRatio = optionSettings.AspectRatio or "16:9",
				Radius = optionSettings.Radius,
			})
			return {
				Name = optionSettings.Name or "Image",
				Type = "Image",
				Object = imageObj,
				Destroy = function()
					destroyControl(imageObj)
				end,
			}
		end

		for _, methodName in ipairs({
			"SetEnabled", "Toggle", "SetExtraText", "Clean", "Destroy",
			"CreateToggle", "CreateSlider", "CreateDropdown", "CreateColorSlider",
			"CreateColorpicker", "CreateKeybind", "CreateInput", "CreateTextBox",
			"CreateTwoSlider", "CreateTextList", "CreateFont", "CreateTargets",
			"CreateButton", "CreateParagraph", "CreateLabel", "CreateDivider", "CreateSpace",
			"CreateProgressBar", "CreateCode", "CreateImage",
		}) do
			enableDotAndColon(module, methodName)
		end
		module.SetState = module.SetEnabled
		module.CreateColorPicker = module.CreateColorpicker

		category.Modules[moduleName] = module
		-- Store under qualified key only (no duplicate short key to prevent double-processing)
		d.Modules[name .. "/" .. moduleName] = module
				-- BADWARS_SHORT_MODULE_ALIASES_V1
		if d.Modules[moduleName] == nil or d.Modules[moduleName].Destroyed then
			d.Modules[moduleName] = module
		end
		return module
	end

	function category:CreateModuleCategory(settings)
		settings = type(settings) == "table" and settings or { Name = settings }
		local subName = tostring(settings.Name or (name .. " Subcategory"))
		return createCategoryObject(subName, settings.Icon or "folder", ensureTab(subName, {
			Icon = settings.Icon or "folder",
			Desc = settings.Desc or settings.Description or (subName .. " modules"),
		}))
	end

	function category:CreateDivider()
		return tab:Divider({})
	end
	function category:CreateSpace()
		return tab:Space({})
	end
	function category:CreateButton(settings)
		settings = settings or {}
		return tab:Button({
			Title = settings.Name or "Action",
			Desc = normalizeDescription(settings),
			Icon = settings.Icon,
			Callback = function()
				runUserCallback(settings.Name or name, settings.Function or settings.Callback)
			end,
		})
	end
	function category:CreateToggle(settings)
		local serviceModule = category.Modules.__Options
		if not serviceModule then
			serviceModule = category:CreateModule({ Name = "Options", NoSave = true, Opened = true })
			category.Modules.__Options = serviceModule
		end
		return serviceModule:CreateToggle(settings)
	end
	function category:CreateProgressBar(settings)
		settings = settings or {}
		local minimum = tonumber(firstNonNil(settings.Min, settings.MinValue, 0)) or 0
		local maximum = tonumber(firstNonNil(settings.Max, settings.MaxValue, 100)) or 100
		if maximum < minimum then minimum, maximum = maximum, minimum end
		local initial = tonumber(firstNonNil(settings.Default, settings.Value, minimum)) or minimum
		initial = math.clamp(initial, minimum, maximum)
		return tab:ProgressBar({
			Title = settings.Name or "Progress",
			Desc = normalizeDescription(settings),
			Value = { Min = minimum, Max = maximum, Default = initial },
			ShowValue = settings.ShowValue,
			DisplayMode = settings.DisplayMode or "Percent",
			Format = settings.Format,
			Animate = settings.Animate ~= false,
			Indeterminate = settings.Indeterminate == true,
			IndeterminateText = settings.IndeterminateText,
			Speed = settings.Speed,
			Width = settings.Width,
			ValueWidth = settings.ValueWidth,
		})
	end
	function category:CreateCode(settings)
		settings = settings or {}
		return tab:Code({
			Title = settings.Name or settings.Title,
			Code = tostring(settings.Code or settings.Content or ""),
			CodeSize = settings.CodeSize,
			CanCopied = settings.CanCopied ~= false,
			Height = settings.Height,
			OnCopy = settings.OnCopy,
		})
	end
	function category:CreateImage(settings)
		settings = settings or {}
		return tab:Image({
			Image = tostring(settings.Image or settings.Url or ""),
			AspectRatio = settings.AspectRatio or "16:9",
			Radius = settings.Radius,
		})
	end
	function category:CreateHStack()
		return tab:HStack()
	end
	function category:CreateVStack()
		return tab:VStack()
	end

	for _, methodName in ipairs({
		"CreateModule", "CreateModuleCategory", "CreateDivider", "CreateSpace", "CreateButton", "CreateToggle",
		"CreateProgressBar", "CreateCode", "CreateImage", "CreateHStack", "CreateVStack",
	}) do
		enableDotAndColon(category, methodName)
	end

	d.Categories[name] = category
	return category
end

function d.CreateCategory(self, config)
	if self ~= d then
		config = self
	end
	config = type(config) == "table" and config or { Name = config }
	return createCategoryObject(config.Name or "Misc", config.Icon)
end

for _, categoryName in ipairs({ "Combat", "Blatant", "Render", "Utility", "World", "Minigames", "Legit", "Friends", "Targets" }) do
	createCategoryObject(categoryName, categoryIcons[categoryName])
end

d.Legit = d.Categories.Legit

-- BADWARS_OVERLAY_RUNTIME_V2
local overlayNextY = 86
local overlayColumnOffset = 24
local overlayColumnWidth = 246

local function createOverlayCanvas()
	local ok, canvas = pcall(Instance.new, "CanvasGroup")
	if ok and canvas then return canvas end
	return Instance.new("Frame")
end

local function resolveOverlaySize(name, settings)
	if settings.OverlaySize and typeof(settings.OverlaySize) == "UDim2" then
		return settings.OverlaySize
	end
	if tonumber(settings.CategorySize) and tonumber(settings.ContentHeight) then
		return UDim2.fromOffset(
			math.max(40, tonumber(settings.CategorySize)),
			math.max(24, tonumber(settings.ContentHeight))
		)
	end
	if name == "Radar" then
		return UDim2.fromOffset(220, 220)
	end
	if name == "Session Info" then
		return UDim2.fromOffset(230, 130)
	end
	return UDim2.fromOffset(160, 54)
end

local function placeOverlay(root)
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local height = math.max(40, root.Size.Y.Offset)
	local width = math.max(100, root.Size.X.Offset)
	if overlayNextY + height > math.max(360, viewport.Y - 36) then
		overlayNextY = 86
		overlayColumnOffset += math.max(overlayColumnWidth, width + 18)
	end
	root.AnchorPoint = Vector2.new(1, 0)
	root.Position = UDim2.new(1, -overlayColumnOffset, 0, overlayNextY)
	overlayNextY += height + 14
end

local function bindOverlayDrag(module, root, scale)
	local dragging = false
	local dragInput
	local dragStart
	local startPosition
	local hovered = false

	local function settle()
		dragging = false
		dragInput = nil
		dragStart = nil
		startPosition = nil
		root.Rotation = 0

		if scale then
			motionTween(
				scale,
				"overlay-scale",
				0.15,
				{ Scale = hovered and 1.01 or 1 }
			)
		end
	end

	module:Clean(root.MouseEnter:Connect(function()
		hovered = true
		if not dragging and scale then
			motionTween(scale, "overlay-scale", 0.14, { Scale = 1.01 })
		end
	end))

	module:Clean(root.MouseLeave:Connect(function()
		hovered = false
		if not dragging and scale then
			motionTween(scale, "overlay-scale", 0.16, { Scale = 1 })
		end
	end))

	module:Clean(root.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local absolute = root.AbsolutePosition
		root.AnchorPoint = Vector2.zero
		root.Position = UDim2.fromOffset(absolute.X, absolute.Y)
		root.Rotation = 0
		dragging = true
		dragStart = input.Position
		startPosition = root.Position

		if scale then
			motionTween(scale, "overlay-scale", 0.08, { Scale = 1.018 })
		end
	end))

	module:Clean(root.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end))

	module:Clean(UserInputService.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput or not dragStart or not startPosition then
			return
		end

		local delta = input.Position - dragStart
		local viewport = workspace.CurrentCamera
			and workspace.CurrentCamera.ViewportSize
			or Vector2.new(1280, 720)
		local maxX = math.max(0, viewport.X - root.AbsoluteSize.X)
		local maxY = math.max(0, viewport.Y - root.AbsoluteSize.Y)
		local targetX = math.clamp(startPosition.X.Offset + delta.X, 0, maxX)
		local targetY = math.clamp(startPosition.Y.Offset + delta.Y, 0, maxY)

		root.Position = UDim2.fromOffset(targetX, targetY)
		root.Rotation = 0
	end))

	module:Clean(UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			settle()
		end
	end))
end
function d.CreateOverlay(self, settings)
	if self ~= d then settings = self end
	settings = settings or {}
	local name = tostring(settings.Name or "Overlay")
	if d.Overlays[name] then
		return d.Overlays[name]
	end

	local overlay = d.Categories.Render:CreateModule(settings)
	local root = createOverlayCanvas()
	root.Name = sanitizeName(name) .. "_Overlay"
	root.Size = resolveOverlaySize(name, settings)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.Active = true
	root.Selectable = false
	root.ClipsDescendants = false
	root.Visible = overlay.Enabled == true
	root.ZIndex = 500
	if root:IsA("CanvasGroup") then
		root.GroupTransparency = overlay.Enabled and 0 or 1
	end
	root.Parent = compatibilityRoot
	placeOverlay(root)

	local scale = ensureMotionScale(root)
	if scale then scale.Scale = overlay.Enabled and 1 or 0.88 end

	overlay.Children = root
	overlay.Root = root
	overlay.Window = root
	overlay.Button = overlay
	overlay.CustomOverlay = settings.CustomOverlay == true
	overlay.Pinned = settings.Pinned == true
	overlay.OverlaySettings = settings

	local visualEpoch = 0
	local function setOverlayVisual(enabled, instant)
		visualEpoch += 1
		local epoch = visualEpoch
		root.Rotation = 0

		if enabled then
			root.Visible = true
			if scale then
				scale.Scale = instant and 1 or 0.975
				motionTween(
					scale,
					"overlay-visibility-scale",
					instant and 0.01 or 0.18,
					{ Scale = 1 }
				)
			end
			if root:IsA("CanvasGroup") then
				root.GroupTransparency = instant and 0 or 1
				motionTween(
					root,
					"overlay-visibility-fade",
					instant and 0.01 or 0.15,
					{ GroupTransparency = 0 }
				)
			end
		else
			if scale then
				motionTween(
					scale,
					"overlay-visibility-scale",
					instant and 0.01 or 0.14,
					{ Scale = 0.98 }
				)
			end
			if root:IsA("CanvasGroup") then
				motionTween(
					root,
					"overlay-visibility-fade",
					instant and 0.01 or 0.13,
					{ GroupTransparency = 1 }
				)
			end
			task.delay(instant and 0 or motionDuration(0.15), function()
				if visualEpoch == epoch and not overlay.Enabled and root.Parent then
					root.Visible = false
					root.Rotation = 0
				end
			end)
		end
	end
	local originalSetEnabled = overlay.SetEnabled
	local originalDestroy = overlay.Destroy

	function overlay:SetEnabled(state, silent)
		state = state == true
		if state then setOverlayVisual(true, false) end
		local result = originalSetEnabled(overlay, state, silent)
		if not state then setOverlayVisual(false, false) end
		return result
	end
	overlay.SetState = overlay.SetEnabled

	function overlay:Toggle(silent)
		return overlay:SetEnabled(not overlay.Enabled, silent)
	end

	function overlay:SetPosition(position)
		if typeof(position) == "UDim2" then
			root.Position = position
		end
		return overlay
	end

	function overlay:GetPosition()
		return root.Position
	end

	function overlay:SetVisible(visible)
		setOverlayVisual(visible == true, false)
		return overlay
	end

	function overlay:Destroy()
		if root.Parent then root:Destroy() end
		d.Overlays[name] = nil
		return originalDestroy(overlay)
	end

	bindOverlayDrag(overlay, root, scale)
	overlay:Clean(root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = math.max(descendant.ZIndex, root.ZIndex + 1)
		end
	end))

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = math.max(descendant.ZIndex, root.ZIndex + 1)
		end
	end

	d.Overlays[name] = overlay
	setOverlayVisual(overlay.Enabled, true)
	return overlay
end
local mainCategory = {
	Type = "ServiceCategory",
	Name = "Main",
	Options = {},
	Modules = {},
}
d.Categories.Main = mainCategory

local function createMainToggle(name, default, callback)
	local option = makeOptionApi({ Name = name, Type = "Toggle", Value = default, Callback = callback })
	option.Object = Tabs.General:Toggle({
		Title = name,
		Value = default,
		Flag = sanitizeName("main/" .. name),
		Callback = function(value)
			option:_FromControl(value == true)
		end,
	})
	-- Store under BOTH keys so legacy code finds it regardless of casing
	mainCategory.Options[name] = option
	mainCategory.Options[string.lower(name)] = option
	return option
end

-- Legacy keys: main.lua references "GUI bind indicator" (lowercase b, i)
mainCategory.Options["GUI bind indicator"] = createMainToggle("GUI Bind Indicator", true)
mainCategory.Options["Teams by server"] = createMainToggle("Teams by server", false)
mainCategory.Options["Use team color"] = createMainToggle("Use team color", true)

function mainCategory:CreateButton(settings)
	settings = settings or {}
	return Tabs.General:Button({
		Title = settings.Name or "Action",
		Desc = normalizeDescription(settings),
		Icon = settings.Icon,
		Callback = function()
			runUserCallback(settings.Name or "Main action", settings.Function or settings.Callback)
		end,
	})
end

function mainCategory:CreateToggle(settings)
	settings = settings or {}
	local name = tostring(settings.Name or "Option")
	if mainCategory.Options[name] then
		return mainCategory.Options[name]
	end
	local option = createMainToggle(name, firstNonNil(settings.Default, settings.Value, false) == true, settings.Function or settings.Callback)
	mainCategory.Options[name] = option
	return option
end

-- ─── General Tab ───
Tabs.General:Paragraph({
	Title = "BadWars v2.1",
	Desc = "Runtime loader for Roblox. RightShift to toggle.",
})

Tabs.General:Divider()

Tabs.General:Code({
	Title = "Loader Script",
	Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()',
	CanCopied = true,
})

Tabs.General:Divider()

-- Quick actions section
local quickActionsSection = Tabs.General:Section({
	Title = "Quick Actions",
	Opened = true,
	Box = true,
})

quickActionsSection:Button({
	Title = "Copy Loader",
	Icon = "copy",
	Desc = "Copy loader to clipboard",
	Callback = function()
		local loader = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()'
		pcall(function()
			if type(setclipboard) == "function" then setclipboard(loader)
			elseif type(toclipboard) == "function" then toclipboard(loader) end
		end)
		d:CreateNotification("BadWars", "Loader copied", 3, "success")
	end,
})

quickActionsSection:Button({
	Title = "Uninject",
	Icon = "x",
	Desc = "Remove all modules and close",
	Callback = function()
		local dialog = Window:Dialog({
			Title = "Uninject BadWars?",
			Content = "This will remove all modules and close the interface.",
			Buttons = {
				{ Title = "Cancel", Variant = "Secondary", Callback = function() end },
				{
					Title = "Uninject",
					Variant = "Primary",
					Callback = function()
						d:CreateNotification("BadWars", "Uninjecting...", 2, "warning")
						task.defer(function() d:Uninject() end)
					end,
				},
			},
		})
		if type(dialog) == "table" and type(dialog.Show) == "function" then
			dialog:Show()
		end
	end,
})

quickActionsSection:Button({
	Title = "Reload",
	Icon = "refresh-cw",
	Desc = "Restart BadWars",
	Callback = function()
		d:CreateNotification("BadWars", "Reloading...", 2, "info")
		shared.BadReload = true
		task.defer(function()
			local ok, err = pcall(function()
				if shared.BadDeveloper and type(readfile) == "function" then
					local source = readfile("badscript/loader.lua")
					assert(type(source) == "string", "loader.lua could not be read")
					assert(loadstring(source, "@badscript/loader.lua"))()
				else
					assert(loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true), "@BadWarsLoader"))()
				end
			end)
			if not ok then
				d:CreateNotification("Reload Error", tostring(err), 7, "error")
			end
		end)
	end,
})

-- ─── Settings Tab ───
local currentProfileName = "default"
local function getConfigManager()
	return type(Window) == "table" and Window.ConfigManager or nil
end

local function saveProfile(name)
	name = sanitizeName(name or currentProfileName)
	currentProfileName = name
	if type(Window.SaveConfig) == "function" then
		local ok, success, result = pcall(Window.SaveConfig, Window, name)
		if ok then return success ~= false, result end
	end
	local manager = getConfigManager()
	if not manager then return false, "Config manager unavailable" end
	local config = manager:GetConfig(name)
	if type(config) ~= "table" or type(config.Save) ~= "function" then
		config = manager:CreateConfig(name, true)
	end
	if not config then return false, "Unable to create profile" end
	config:SetAsCurrent()
	return true, config:Save()
end

local function loadProfile(name)
	name = sanitizeName(name or currentProfileName)
	currentProfileName = name
	if type(Window.LoadConfig) == "function" then
		local ok, success, result = pcall(Window.LoadConfig, Window, name)
		if ok then return success ~= false, result end
	end
	local manager = getConfigManager()
	if not manager then return false, "Config manager unavailable" end
	local config = manager:GetConfig(name)
	if type(config) ~= "table" or type(config.Load) ~= "function" then
		config = manager:CreateConfig(name, true)
	end
	if not config then return false, "Unable to create profile" end
	config:SetAsCurrent()
	return config:Load()
end

-- Appearance section
local appearanceSection = Tabs.Settings:Section({
	Title = "Appearance",
	Opened = true,
	Box = true,
})

-- BADWARS_MOTION_SETTINGS_V1
appearanceSection:Toggle({
	Title = "Extreme Motion",
	Desc = "CSS-like hover, press, reveal, popup, and overlay animations",
	Value = true,
	Flag = "settings/extreme_motion",
	Callback = function(value)
		d.MotionEnabled = value == true
	end,
})

appearanceSection:Slider({
	Title = "Motion Intensity",
	Desc = "Controls animation speed and emphasis",
	Value = { Min = 50, Max = 150, Default = 100 },
	Step = 5,
	Flag = "settings/motion_intensity",
	Callback = function(value)
		d.MotionIntensity = math.clamp((tonumber(value) or 100) / 100, 0.5, 1.5)
	end,
})
appearanceSection:Toggle({
	Title = "UI Transparency",
	Desc = "Glass effect",
	Value = true,
	Flag = "settings/transparency",
	Callback = function(value)
		WindUI.TransparencyValue = value and 0.08 or 0
		pcall(function()
			if type(Window.ToggleTransparency) == "function" then
				Window:ToggleTransparency(value)
			end
		end)
	end,
})

-- UI Scale with progress indicator
local uiScaleProgress = appearanceSection:ProgressBar({
	Title = "UI Scale",
	Desc = "Current scale",
	Value = { Min = 65, Max = 125, Default = 94 },
	DisplayMode = "Value",
	Format = function(value)
		return string.format("%.0f%%", value)
	end,
	Width = 200,
	Animate = true,
})

appearanceSection:Slider({
	Title = "Adjust Scale",
	Value = { Min = 65, Max = 125, Default = 94 },
	Step = 5,
	Callback = function(value)
		local scale = value / 100
		pcall(function() Window:SetUIScale(scale) end)
		if uiScaleProgress and type(uiScaleProgress.Set) == "function" then
			pcall(uiScaleProgress.Set, uiScaleProgress, value)
		end
	end,
})

-- Profile section
local profileSection = Tabs.Settings:Section({
	Title = "Profiles",
	Opened = true,
	Box = true,
})

profileSection:Input({
	Title = "Profile Name",
	Value = currentProfileName,
	Placeholder = "default",
	Callback = function(value)
		if tostring(value or "") ~= "" then
			currentProfileName = sanitizeName(value)
		end
	end,
})

profileSection:Button({
	Title = "Save Profile",
	Icon = "save",
	Desc = "Save current settings",
	Callback = function()
		local ok, result = saveProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and ("Saved '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")
	end,
})

profileSection:Button({
	Title = "Load Profile",
	Icon = "folder-open",
	Desc = "Load settings",
	Callback = function()
		local ok, result = loadProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and ("Loaded '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")
	end,
})

profileSection:Button({
	Title = "Reset Profile",
	Icon = "trash",
	Desc = "Delete saved settings",
	Callback = function()
		local dialog = Window:Dialog({
			Title = "Reset Profile?",
			Content = "Clear all saved settings for '" .. currentProfileName .. "'.",
			Buttons = {
				{ Title = "Cancel", Variant = "Secondary", Callback = function() end },
				{
					Title = "Reset",
					Variant = "Primary",
					Callback = function()
						if type(readfile) == "function" and type(delfile) == "function" then
							local configPath = "BadWars/" .. sanitizeName(currentProfileName) .. ".json"
							if isfile(configPath) then
								pcall(delfile, configPath)
								d:CreateNotification("Profiles", "Profile reset", 3, "success")
							else
								d:CreateNotification("Profiles", "No saved profile", 3, "warning")
							end
						end
					end,
				},
			},
		})
		if type(dialog) == "table" and type(dialog.Show) == "function" then
			dialog:Show()
		end
	end,
})

-- ─── Friends Tab ───
Tabs.Friends:Paragraph({
	Title = "Friends",
	Desc = "Mark players as friends to protect them from combat modules.",
})

local friendsSection = Tabs.Friends:Section({
	Title = "Settings",
	Opened = true,
	Box = true,
})

local friendsCategory = d.Categories.Friends

friendsSection:Toggle({
	Title = "Use Friends",
	Desc = "Enable friend protection",
	Value = false,
	Flag = "friends/use",
	Callback = function(value)
		if friendsCategory and friendsCategory.Options then
			friendsCategory.Options["Use friends"] = friendsCategory.Options["Use friends"] or {}
			friendsCategory.Options["Use friends"].Enabled = value
		end
	end,
})

friendsSection:Toggle({
	Title = "Recolor Visuals",
	Desc = "Change friend color in ESP",
	Value = false,
	Flag = "friends/recolor",
	Callback = function(value)
		if friendsCategory and friendsCategory.Options then
			friendsCategory.Options["Recolor visuals"] = friendsCategory.Options["Recolor visuals"] or {}
			friendsCategory.Options["Recolor visuals"].Enabled = value
		end
	end,
})

friendsSection:Divider()

local friendsListSection = Tabs.Friends:Section({
	Title = "Player List",
	Opened = true,
	Box = true,
})

local friendsListLabel = friendsListSection:Paragraph({
	Title = "Server Players",
	Desc = "Click a player to toggle friend status",
})

local friendButtons = {}

local function refreshFriendsList()
	for _, btn in ipairs(friendButtons) do
		pcall(function() btn:Destroy() end)
	end
	friendButtons = {}

	local players = game:GetService("Players"):GetPlayers()
	local listEnabled = (friendsCategory and friendsCategory.ListEnabled) or {}

	for _, player in ipairs(players) do
		local isFriend = table.find(listEnabled, player.Name) and true or false
		local btn = friendsListSection:Button({
			Title = player.Name .. (isFriend and " [FRIEND]" or ""),
			Desc = isFriend and "Remove from friends" or "Add as friend",
			Icon = isFriend and "user-check" or "user-plus",
			Callback = function()
				if not friendsCategory then return end
				friendsCategory.ListEnabled = friendsCategory.ListEnabled or {}
				local idx = table.find(friendsCategory.ListEnabled, player.Name)
				if idx then
					table.remove(friendsCategory.ListEnabled, idx)
				else
					table.insert(friendsCategory.ListEnabled, player.Name)
				end
				if friendsCategory.Update then
					pcall(friendsCategory.Update.Fire, friendsCategory.Update)
				end
				refreshFriendsList()
				d:CreateNotification("Friends", isFriend and ("Removed " .. player.Name) or ("Added " .. player.Name .. " as friend"), 3, "success")
			end,
		})
		table.insert(friendButtons, btn)
	end
end

friendsListSection:Button({
	Title = "Refresh Player List",
	Icon = "refresh-cw",
	Desc = "Update the server player list",
	Callback = refreshFriendsList,
})

task.defer(refreshFriendsList)

game:GetService("Players").PlayerAdded:Connect(function()
	task.defer(refreshFriendsList)
end)
game:GetService("Players").PlayerRemoving:Connect(function()
	task.defer(refreshFriendsList)
end)

-- ─── Targets Tab ───
Tabs.Targets:Paragraph({
	Title = "Targets",
	Desc = "Mark specific players as targets for combat modules.",
})

local targetsSection = Tabs.Targets:Section({
	Title = "Settings",
	Opened = true,
	Box = true,
})

local targetsCategory = d.Categories.Targets

targetsSection:Divider()

local targetsListSection = Tabs.Targets:Section({
	Title = "Player List",
	Opened = true,
	Box = true,
})

local targetsListLabel = targetsListSection:Paragraph({
	Title = "Server Players",
	Desc = "Click a player to toggle target status",
})

local targetButtons = {}

local function refreshTargetsList()
	for _, btn in ipairs(targetButtons) do
		pcall(function() btn:Destroy() end)
	end
	targetButtons = {}

	local players = game:GetService("Players"):GetPlayers()
	local listEnabled = (targetsCategory and targetsCategory.ListEnabled) or {}

	for _, player in ipairs(players) do
		local isTarget = table.find(listEnabled, player.Name) and true or false
		local btn = targetsListSection:Button({
			Title = player.Name .. (isTarget and " [TARGET]" or ""),
			Desc = isTarget and "Remove from targets" or "Add as target",
			Icon = isTarget and "crosshair" or "circle",
			Callback = function()
				if not targetsCategory then return end
				targetsCategory.ListEnabled = targetsCategory.ListEnabled or {}
				local idx = table.find(targetsCategory.ListEnabled, player.Name)
				if idx then
					table.remove(targetsCategory.ListEnabled, idx)
				else
					table.insert(targetsCategory.ListEnabled, player.Name)
				end
				if targetsCategory.Update then
					pcall(targetsCategory.Update.Fire, targetsCategory.Update)
				end
				refreshTargetsList()
				d:CreateNotification("Targets", isTarget and ("Removed " .. player.Name) or ("Added " .. player.Name .. " as target"), 3, "success")
			end,
		})
		table.insert(targetButtons, btn)
	end
end

targetsListSection:Button({
	Title = "Refresh Player List",
	Icon = "refresh-cw",
	Desc = "Update the server player list",
	Callback = refreshTargetsList,
})

task.defer(refreshTargetsList)

game:GetService("Players").PlayerAdded:Connect(function()
	task.defer(refreshTargetsList)
end)
game:GetService("Players").PlayerRemoving:Connect(function()
	task.defer(refreshTargetsList)
end)

-- ─── API methods ───
function d.Save(self, target)
	if self ~= d then target = self end
	return saveProfile(type(target) == "string" and target or currentProfileName)
end

function d.Load(self, saved)
	if self ~= d then saved = self end
	return loadProfile(type(saved) == "string" and saved or currentProfileName)
end

function d.Change()
	return d
end

function d.Clean(self, resource)
	if self ~= d then resource = self end
	if resource ~= nil then
		table.insert(d.Resources, resource)
		if isConnection(resource) then
			table.insert(d.Connections, resource)
		end
	end
	return resource
end

function d.CreateDialog(self, settings)
	if self ~= d then settings = self end
	settings = settings or {}
	local dialog = Window:Dialog({
		Title = settings.Title or "Dialog",
		Icon = settings.Icon,
		IconThemed = settings.IconThemed,
		Content = settings.Content or settings.Desc or "",
		Buttons = settings.Buttons or {},
	})
	return dialog
end

function d.CreatePopup(self, settings)
	if self ~= d then settings = self end
	settings = settings or {}
	local popup = WindUI:Popup({
		Title = settings.Title or "Popup",
		Icon = settings.Icon,
		Content = settings.Content or settings.Desc or "",
		Buttons = settings.Buttons or {},
	})
	return popup
end

function d.RefreshScrollCanvases()
	local roots = { WindUI.ScreenGui, WindUI.DropdownGui, WindUI.NotificationGui }
	for _, root in ipairs(roots) do
		if typeof(root) == "Instance" then
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("ScrollingFrame") then
					pcall(function()
						if descendant.AutomaticCanvasSize == Enum.AutomaticSize.None then
							descendant.AutomaticCanvasSize = Enum.AutomaticSize.Y
						end
					end)
				end
			end
		end
	end
	return true
end

function d.WaitForModuleReadiness()
	return not d.Destroyed
end

function d.FinalizeInitialLayout()
	d:RefreshScrollCanvases()
	return true
end

-- ── Show / Hide / Toggle / Uninject ───
local firstLoadDone = false

function d.Show(self)
	if self ~= d then return d:Show() end
	if d.Destroyed then return false end
	d.Visible = true
	compatibilityClickGui.Visible = true -- BADWARS_SHOW_MOTION_V1

	pcall(function()
		if type(Window.Open) == "function" then Window:Open() end
	end)
	pcall(function()
		if type(Window.Show) == "function" then Window:Show() end
	end)

	setWindowHidden(false)
	animateWindowMotion()

	task.defer(function()
		if d.Visible and not d.Destroyed then
			setWindowHidden(false)
			local main = findWindowMain(Window)
			if typeof(main) == "Instance" then
				pcall(function() main.Visible = true end)
			end
		end
	end)

	if not firstLoadDone then
		firstLoadDone = true
		d:CreateNotification("BadWars", "Interface ready. RightShift to toggle.", 4, "success")
		task.defer(function()
			if d.Destroyed then return end
			local popup = WindUI:Popup({
				Title = "Welcome to BadWars",
				Content = "Your loader is ready. Use RightShift to toggle the interface. Check the Modules tab for a health overview of all loaded features.",
				Buttons = {
					{ Title = "Got it", Variant = "Primary", Callback = function() end },
				},
			})
		end)
	end
	return true
end

function d.Hide(self)
	if self ~= d then return d:Hide() end
	if d.Destroyed then return false end
	d.Visible = false
	compatibilityClickGui.Visible = false
	pcall(function()
		if type(Window.Close) == "function" then Window:Close() end
	end)
	pcall(function()
		if type(Window.Hide) == "function" then Window:Hide() end
	end)
	setWindowHidden(true)
	return true
end

function d.Toggle(self)
	if self ~= d then return d:Toggle() end
	if d.Visible then return d:Hide() end
	return d:Show()
end

function d.Uninject(self)
	if self ~= d then return d:Uninject() end
	if d.Destroyed then return false end
	d.Destroyed = true
	d.Visible = false

	-- Disable all modules (iterate unique entries only)
	local processed = {}
	for key, module in pairs(d.Modules) do
		if type(module) == "table" and not processed[module] then
			processed[module] = true
			if module.Enabled and type(module.SetEnabled) == "function" then
				pcall(module.SetEnabled, module, false)
			end
		end
	end

	-- Clean all resources
	for index = #d.Resources, 1, -1 do
		local resource = d.Resources[index]
		if isConnection(resource) then
			pcall(resource.Disconnect, resource)
		elseif type(resource) == "function" then
			pcall(resource)
		elseif type(resource) == "table" and type(resource.Destroy) == "function" then
			pcall(resource.Destroy, resource)
		elseif typeof(resource) == "Instance" then
			pcall(resource.Destroy, resource)
		end
		d.Resources[index] = nil
	end
	table.clear(d.Connections)

	-- Destroy categories and their modules
	for _, category in pairs(d.Categories) do
		if type(category) == "table" then
			for _, module in pairs(category.Modules or {}) do
				if type(module) == "table" and type(module.Destroy) == "function" then
					pcall(module.Destroy, module)
				end
			end
		end
	end

	-- Destroy the window
	pcall(function()
		if type(Window.Destroy) == "function" then Window:Destroy() end
	end)

	-- Clean up shared references
	if shared then
		if shared.Bad == d then shared.Bad = nil end
		if shared.BadGUI == d then shared.BadGUI = nil end
	end
	return true
end

-- ─── Shared registration ───
if shared then
	shared.BadGUI = d
	if shared.Bad == nil then
		shared.Bad = d
	elseif type(shared.Bad) == "table" then
		shared.Bad.CreateNotification = function(...)
			return d:CreateNotification(...)
		end
		shared.Bad.GUI = d
	end
end

return d
