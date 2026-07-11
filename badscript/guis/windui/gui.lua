-- BADWARS_WINDUI_INTEGRATION
-- WindUI adapter with centralized legacy compatibility layer.

local cloneref = cloneref or clonereference or function(value)
	return value
end

local HttpService = cloneref(game:GetService("HttpService"))

local d = {
	Categories = {},
	Modules = {},
	Overlays = {},
	Libraries = {},
	Profiles = {},
	Connections = {},
	Resources = {},
	GUIColor = { Hue = 0.02, Sat = 0.95, Value = 0.98 },
	Version = "WindUI-Adapter-3.0",
	PremiumBuild = false,
	Name = "BadWars-WindUI-V3",
	Visible = false,
	Destroyed = false,
}

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
	WindUI.TransparencyValue = 0.03
	WindUI:SetTheme("BadWars")
end)

local Window = WindUI:CreateWindow({
	Title = "BadWars",
	Author = "Control Center",
	Icon = "swords",
	IconRadius = 10,
	Folder = "BadWars",
	NewElements = true,
	HideSearchBar = false,
	ScrollBarEnabled = false,
	AutoScale = false,
	Resizable = true,
	Transparent = false,
	Acrylic = false,
	HidePanelBackground = false,
	ShadowTransparency = 0.34,
	Size = UDim2.new(0, 920, 0, 620),
	MinSize = Vector2.new(680, 460),
	MaxSize = Vector2.new(1180, 820),
	SideBarWidth = 232,
	Radius = 18,
	ElementsRadius = 12,
	Padding = 16,
	Gap = 8,
	ElementPadding = 10,
	SectionHeaderSize = 44,
	SectionTitleSize = 17,
	SectionDescSize = 13,
	TopBarButtonIconSize = 12,
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = "BadWars",
		Enabled = true,
		Draggable = true,
		Scale = 0.58,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#FF335F")),
			ColorSequenceKeypoint.new(0.55, Color3.fromHex("#FF6A3D")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#8B5CF6")),
		}),
	},
	Topbar = {
		Height = 56,
		ButtonsType = "Mac",
	},
})
if type(Window) ~= "table" then
	error("WindUI failed to create the BadWars window")
end

d.Window = Window

pcall(function()
	Window:SetUIScale(0.96)
end)

d.gui = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui
	or (typeof(findWindowMain(Window)) == "Instance" and findWindowMain(Window))
	or Window

-- BADWARS_VISUAL_REVAMP_V5
-- BADWARS_UNIVERSAL_UI_V6
local UserInputService = cloneref(game:GetService("UserInputService"))
local GuiService = cloneref(game:GetService("GuiService"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local TextService = cloneref(game:GetService("TextService"))
local Workspace = cloneref(game:GetService("Workspace"))

local REVAMP = {
	Canvas = Color3.fromHex("#090B10"),
	Panel = Color3.fromHex("#0F1219"),
	Raised = Color3.fromHex("#151A24"),
	Border = Color3.fromHex("#2A3040"),
	Accent = Color3.fromHex("#FF335F"),
	AccentWarm = Color3.fromHex("#FF6A3D"),
	AccentCool = Color3.fromHex("#8B5CF6"),
	Text = Color3.fromHex("#F8FAFC"),
	Muted = Color3.fromHex("#98A2B3"),
	Scroll = Color3.fromHex("#697386"),
}

local CUSTOMIZATION_DEFAULTS = {
	Preset = "BadWars",
	PlatformPreset = "Auto",
	Canvas = REVAMP.Canvas,
	Panel = REVAMP.Panel,
	Raised = REVAMP.Raised,
	Border = REVAMP.Border,
	Accent = REVAMP.Accent,
	AccentWarm = REVAMP.AccentWarm,
	AccentCool = REVAMP.AccentCool,
	Text = REVAMP.Text,
	Muted = REVAMP.Muted,
	Scroll = REVAMP.Scroll,
	Scale = 0.96,
	WindowWidth = 920,
	WindowHeight = 620,
	SidebarWidth = 232,
	WindowRadius = 18,
	ElementRadius = 12,
	Spacing = 8,
	Transparency = 0.03,
	ScrollbarThickness = 3,
	TooltipDelay = 0.03,
	ShowScrollbars = true,
	ShowAccentRail = true,
	ShowSidebarDivider = true,
	InstantTooltips = true,
	SafeArea = true,
	GamepadNavigation = true,
	LargeTouchTargets = true,
	HighContrast = false,
}

local CUSTOM = {}
for key, value in pairs(CUSTOMIZATION_DEFAULTS) do
	CUSTOM[key] = value
end

local THEME_PRESETS = {
	BadWars = {
		Canvas = Color3.fromHex("#090B10"),
		Panel = Color3.fromHex("#0F1219"),
		Raised = Color3.fromHex("#151A24"),
		Border = Color3.fromHex("#2A3040"),
		Accent = Color3.fromHex("#FF335F"),
		AccentWarm = Color3.fromHex("#FF6A3D"),
		AccentCool = Color3.fromHex("#8B5CF6"),
		Text = Color3.fromHex("#F8FAFC"),
		Muted = Color3.fromHex("#98A2B3"),
		Scroll = Color3.fromHex("#697386"),
	},
	Midnight = {
		Canvas = Color3.fromHex("#05070D"),
		Panel = Color3.fromHex("#0A1020"),
		Raised = Color3.fromHex("#111B31"),
		Border = Color3.fromHex("#263754"),
		Accent = Color3.fromHex("#4F8CFF"),
		AccentWarm = Color3.fromHex("#22D3EE"),
		AccentCool = Color3.fromHex("#8B5CF6"),
		Text = Color3.fromHex("#EEF6FF"),
		Muted = Color3.fromHex("#8EA3C0"),
		Scroll = Color3.fromHex("#4D6383"),
	},
	Ember = {
		Canvas = Color3.fromHex("#100806"),
		Panel = Color3.fromHex("#1A0F0B"),
		Raised = Color3.fromHex("#281610"),
		Border = Color3.fromHex("#503026"),
		Accent = Color3.fromHex("#FF4D2E"),
		AccentWarm = Color3.fromHex("#FFB020"),
		AccentCool = Color3.fromHex("#FF2D7A"),
		Text = Color3.fromHex("#FFF5EE"),
		Muted = Color3.fromHex("#C6A394"),
		Scroll = Color3.fromHex("#805346"),
	},
	Violet = {
		Canvas = Color3.fromHex("#090610"),
		Panel = Color3.fromHex("#120B20"),
		Raised = Color3.fromHex("#1C1230"),
		Border = Color3.fromHex("#3E2C5D"),
		Accent = Color3.fromHex("#A855F7"),
		AccentWarm = Color3.fromHex("#EC4899"),
		AccentCool = Color3.fromHex("#6366F1"),
		Text = Color3.fromHex("#FAF5FF"),
		Muted = Color3.fromHex("#B7A1CA"),
		Scroll = Color3.fromHex("#70568A"),
	},
	Ocean = {
		Canvas = Color3.fromHex("#041014"),
		Panel = Color3.fromHex("#071B22"),
		Raised = Color3.fromHex("#0C2933"),
		Border = Color3.fromHex("#1B4D5C"),
		Accent = Color3.fromHex("#06B6D4"),
		AccentWarm = Color3.fromHex("#2DD4BF"),
		AccentCool = Color3.fromHex("#3B82F6"),
		Text = Color3.fromHex("#ECFEFF"),
		Muted = Color3.fromHex("#8DB8C2"),
		Scroll = Color3.fromHex("#3D7482"),
	},
	Monochrome = {
		Canvas = Color3.fromHex("#080808"),
		Panel = Color3.fromHex("#111111"),
		Raised = Color3.fromHex("#1B1B1B"),
		Border = Color3.fromHex("#3B3B3B"),
		Accent = Color3.fromHex("#F5F5F5"),
		AccentWarm = Color3.fromHex("#BDBDBD"),
		AccentCool = Color3.fromHex("#737373"),
		Text = Color3.fromHex("#FAFAFA"),
		Muted = Color3.fromHex("#A3A3A3"),
		Scroll = Color3.fromHex("#666666"),
	},
}

local revampObjects = {}
local tooltipBound = setmetatable({}, { __mode = "k" })
local navigationBound = setmetatable({}, { __mode = "k" })
local currentPlatform = "Desktop"
local tooltipToken = 0
local activeTooltipTarget = nil
local cameraConnection = nil

local function trackUniversalResource(resource)
	if resource ~= nil then
		table.insert(d.Resources, resource)
	end
	return resource
end

local function selectionName(value)
	if type(value) == "table" then
		return tostring(value.Title or value.Name or value.Value or "")
	end
	return tostring(value or "")
end

local function createRevampOutline(parent, radius)
	if typeof(parent) ~= "Instance" or not parent:IsA("GuiObject") then
		return nil
	end

	local outline = parent:FindFirstChild("BadWarsRevampOutline")
	if not outline or not outline:IsA("Frame") then
		if outline then
			outline:Destroy()
		end

		outline = Instance.new("Frame")
		outline.Name = "BadWarsRevampOutline"
		outline.Size = UDim2.fromScale(1, 1)
		outline.BackgroundTransparency = 1
		outline.BorderSizePixel = 0
		outline.Active = false
		outline.Selectable = false
		outline.ZIndex = 1000
		outline.Parent = parent
	end

	local corner = outline:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = outline

	local stroke = outline:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = CUSTOM.Border
	stroke.Thickness = CUSTOM.HighContrast and 2 or 1
	stroke.Transparency = CUSTOM.HighContrast and 0 or 0.12
	stroke.Parent = outline

	revampObjects.Outline = outline
	revampObjects.OutlineCorner = corner
	revampObjects.OutlineStroke = stroke
	return outline
end

local function createAccentRail(parent)
	if typeof(parent) ~= "Instance" or not parent:IsA("GuiObject") then
		return nil
	end

	local rail = parent:FindFirstChild("BadWarsAccentRail")
	if not rail or not rail:IsA("Frame") then
		if rail then
			rail:Destroy()
		end

		rail = Instance.new("Frame")
		rail.Name = "BadWarsAccentRail"
		rail.Size = UDim2.new(1, -36, 0, 3)
		rail.Position = UDim2.new(0, 18, 0, 0)
		rail.BackgroundColor3 = Color3.new(1, 1, 1)
		rail.BorderSizePixel = 0
		rail.Active = false
		rail.Selectable = false
		rail.ZIndex = 1001
		rail.Parent = parent
	end

	local corner = rail:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = rail

	local gradient = rail:FindFirstChildWhichIsA("UIGradient") or Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CUSTOM.Accent),
		ColorSequenceKeypoint.new(0.52, CUSTOM.AccentWarm),
		ColorSequenceKeypoint.new(1, CUSTOM.AccentCool),
	})
	gradient.Parent = rail

	rail.Visible = CUSTOM.ShowAccentRail
	revampObjects.AccentRail = rail
	revampObjects.AccentGradient = gradient
	return rail
end

local function createSidebarDivider(parent)
	if typeof(parent) ~= "Instance" or not parent:IsA("GuiObject") then
		return nil
	end

	local divider = parent:FindFirstChild("BadWarsSidebarDivider")
	if not divider or not divider:IsA("Frame") then
		if divider then
			divider:Destroy()
		end

		divider = Instance.new("Frame")
		divider.Name = "BadWarsSidebarDivider"
		divider.Size = UDim2.new(0, 1, 1, -80)
		divider.BackgroundTransparency = 0.34
		divider.BorderSizePixel = 0
		divider.Active = false
		divider.Selectable = false
		divider.ZIndex = 8
		divider.Parent = parent
	end

	divider.Position = UDim2.new(0, CUSTOM.SidebarWidth, 0, 64)
	divider.BackgroundColor3 = CUSTOM.Border
	divider.Visible = CUSTOM.ShowSidebarDivider
	revampObjects.SidebarDivider = divider
	return divider
end

local mainVisual = findWindowMain(Window)
local visualRoot = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui or mainVisual

local function hasScrollableAncestor(object)
	local parent = object and object.Parent
	while typeof(parent) == "Instance" do
		if parent:IsA("ScrollingFrame") then
			return true
		end
		if parent == visualRoot then
			break
		end
		parent = parent.Parent
	end
	return false
end

local function isAuxiliaryScrollFrame(object)
	local name = string.lower(object.Name)
	if name:find("sidebar", 1, true)
		or name:find("dropdown", 1, true)
		or name:find("menu", 1, true)
		or name:find("search", 1, true)
		or name:find("result", 1, true)
		or name:find("tooltip", 1, true)
		or name:find("notification", 1, true)
	then
		return true
	end

	local parent = object.Parent
	for _ = 1, 5 do
		if typeof(parent) ~= "Instance" then
			break
		end

		local parentName = string.lower(parent.Name)
		if parentName:find("dropdown", 1, true)
			or parentName:find("menu", 1, true)
			or parentName:find("search", 1, true)
			or parentName:find("sidebar", 1, true)
		then
			return true
		end
		parent = parent.Parent
	end

	return false
end

local function applyScrollbarStyle(object)
	if not object:IsA("ScrollingFrame") then
		return
	end

	local hidden = hasScrollableAncestor(object) or isAuxiliaryScrollFrame(object)
	pcall(function()
		object.ElasticBehavior = Enum.ElasticBehavior.Never
		object.ScrollBarImageColor3 = CUSTOM.Scroll
		object.ScrollBarImageTransparency = hidden or not CUSTOM.ShowScrollbars and 1 or 0.18
		object.ScrollBarThickness = hidden or not CUSTOM.ShowScrollbars and 0 or CUSTOM.ScrollbarThickness
	end)
end

local function applyRevampTypography(object)
	if not (
		object:IsA("TextLabel")
		or object:IsA("TextButton")
		or object:IsA("TextBox")
	) then
		return
	end

	pcall(function()
		local lowerName = string.lower(object.Name)
		local weight = Enum.FontWeight.Medium
		if object.TextSize >= 16 or lowerName:find("title", 1, true) then
			weight = Enum.FontWeight.SemiBold
		end

		if lowerName:find("code", 1, true) then
			object.FontFace = Font.fromEnum(Enum.Font.Code)
		else
			object.FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				weight,
				Enum.FontStyle.Normal
			)
		end
		object.TextStrokeTransparency = 1
	end)
end

local function applyCornerCustomization(object)
	if not object:IsA("UICorner") then
		return
	end

	pcall(function()
		if object.CornerRadius.Scale ~= 0 then
			return
		end

		local parent = object.Parent
		if parent == mainVisual or parent == revampObjects.Outline then
			object.CornerRadius = UDim.new(0, CUSTOM.WindowRadius)
		elseif typeof(parent) == "Instance" and parent:IsA("GuiObject") then
			local minimumSide = math.min(parent.AbsoluteSize.X, parent.AbsoluteSize.Y)
			if minimumSide > 24 then
				object.CornerRadius = UDim.new(0, math.min(CUSTOM.ElementRadius, math.floor(minimumSide / 2)))
			end
		end
	end)
end

local function applySpacingCustomization(object)
	if not object:IsA("UIListLayout") then
		return
	end

	pcall(function()
		if object.FillDirection == Enum.FillDirection.Vertical
			and object.Padding.Scale == 0
			and object.Padding.Offset <= 24
		then
			object.Padding = UDim.new(0, CUSTOM.Spacing)
		end
	end)
end

local function makeNavigable(object)
	if not object:IsA("GuiButton") and not object:IsA("TextBox") then
		return
	end

	pcall(function()
		object.Selectable = true
	end)

	navigationBound[object] = true
end

local function applyRevampInstance(object)
	if typeof(object) ~= "Instance" then
		return
	end

	if object:IsA("ScrollingFrame") then
		applyScrollbarStyle(object)
	elseif object:IsA("UIStroke") then
		pcall(function()
			object.LineJoinMode = Enum.LineJoinMode.Round
		end)
	elseif object:IsA("GuiButton") then
		pcall(function()
			object.AutoButtonColor = false
		end)
	end

	applyRevampTypography(object)
	applyCornerCustomization(object)
	applySpacingCustomization(object)
	makeNavigable(object)
end

local function buildCustomTheme()
	local border = CUSTOM.HighContrast and CUSTOM.Text or CUSTOM.Border
	local muted = CUSTOM.HighContrast and CUSTOM.Text:Lerp(CUSTOM.Canvas, 0.22) or CUSTOM.Muted
	local panelTransparency = math.clamp(CUSTOM.Transparency, 0, 0.4)
	local elementTransparency = math.clamp(CUSTOM.Transparency + 0.03, 0, 0.45)

	return {
		Name = "BadWarsCustom",
		Accent = CUSTOM.Accent,
		Dialog = CUSTOM.Panel,
		Outline = border,
		Text = CUSTOM.Text,
		Placeholder = muted,
		Background = CUSTOM.Canvas,
		Button = CUSTOM.Raised,
		Icon = CUSTOM.Text,
		Toggle = CUSTOM.Accent,
		Slider = CUSTOM.Accent,
		Checkbox = CUSTOM.Accent,
		PanelBackground = CUSTOM.Panel,
		PanelBackgroundTransparency = panelTransparency,
		LabelBackground = CUSTOM.Raised,
		LabelBackgroundTransparency = elementTransparency,
		ElementBackground = CUSTOM.Raised,
		ElementBackgroundTransparency = elementTransparency,
		Primary = CUSTOM.Accent,
		TabBackground = CUSTOM.Panel,
		TabBackgroundHover = CUSTOM.Raised,
		TabBackgroundActive = CUSTOM.Raised,
		DropdownBackground = CUSTOM.Panel,
		WindowShadow = CUSTOM.Canvas,
		White = CUSTOM.Text,
	}
end

local function applyCustomTheme()
	local theme = buildCustomTheme()
	pcall(function()
		if type(WindUI.AddTheme) == "function" then
			WindUI:AddTheme(theme)
		end
		if type(WindUI.SetTheme) == "function" then
			WindUI:SetTheme(theme.Name)
		end
	end)

	if revampObjects.AccentGradient then
		revampObjects.AccentGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, CUSTOM.Accent),
			ColorSequenceKeypoint.new(0.52, CUSTOM.AccentWarm),
			ColorSequenceKeypoint.new(1, CUSTOM.AccentCool),
		})
	end

	if revampObjects.OutlineStroke then
		revampObjects.OutlineStroke.Color = CUSTOM.HighContrast and CUSTOM.Text or CUSTOM.Border
		revampObjects.OutlineStroke.Thickness = CUSTOM.HighContrast and 2 or 1
		revampObjects.OutlineStroke.Transparency = CUSTOM.HighContrast and 0 or 0.12
	end

	if revampObjects.SidebarDivider then
		revampObjects.SidebarDivider.BackgroundColor3 = CUSTOM.Border
	end
end

local function applySafeArea()
	local enabled = CUSTOM.SafeArea == true
	for _, gui in ipairs({
		WindUI.ScreenGui,
		WindUI.DropdownGui,
		WindUI.NotificationGui,
		WindUI.TooltipGui,
	}) do
		if typeof(gui) == "Instance" and gui:IsA("ScreenGui") then
			pcall(function()
				gui.ScreenInsets = enabled and Enum.ScreenInsets.DeviceSafeInsets or Enum.ScreenInsets.None
				gui.ClipToDeviceSafeArea = enabled
			end)
		end
	end
end

local function detectPlatform()
	local lastInput = UserInputService:GetLastInputType()
	if lastInput.Name:find("Gamepad", 1, true) then
		return "Console"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	end
	if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
		return "Console"
	end
	return "Desktop"
end

local function resolvePlatform()
	if CUSTOM.PlatformPreset ~= "Auto" then
		return CUSTOM.PlatformPreset
	end
	return detectPlatform()
end

local function updateSidebarWidth(width)
	width = math.max(150, math.floor(width + 0.5))
	Window.SideBarWidth = width

	local sideBarContainer = type(Window.UIElements) == "table" and Window.UIElements.SideBarContainer
	if typeof(sideBarContainer) == "Instance" and sideBarContainer:IsA("GuiObject") then
		sideBarContainer.Size = UDim2.new(
			0,
			width,
			sideBarContainer.Size.Y.Scale,
			sideBarContainer.Size.Y.Offset
		)
	end

	local mainBar = type(Window.UIElements) == "table" and Window.UIElements.MainBar
	if typeof(mainBar) == "Instance" and mainBar:IsA("GuiObject") then
		mainBar.Size = UDim2.new(
			1,
			-width,
			mainBar.Size.Y.Scale,
			mainBar.Size.Y.Offset
		)
	end

	if revampObjects.SidebarDivider then
		revampObjects.SidebarDivider.Position = UDim2.new(0, width, 0, 64)
	end
end

local function applyResponsiveLayout()
	if typeof(mainVisual) ~= "Instance" or not mainVisual:IsA("GuiObject") then
		return
	end

	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local platform = resolvePlatform()
	currentPlatform = platform

	local width = CUSTOM.WindowWidth
	local height = CUSTOM.WindowHeight
	local scale = CUSTOM.Scale
	local sidebarWidth = CUSTOM.SidebarWidth

	if platform == "Mobile" then
		width = math.max(320, viewport.X - 20)
		height = math.max(360, viewport.Y - 28)
		scale = math.clamp(math.min(viewport.X / 900, viewport.Y / 640), 0.72, 0.94) * CUSTOM.Scale
		sidebarWidth = math.clamp(math.floor(width * 0.29), 156, 205)
	elseif platform == "Console" then
		width = math.clamp(math.floor(viewport.X * 0.88), 720, 1180)
		height = math.clamp(math.floor(viewport.Y * 0.82), 480, 820)
		scale = math.clamp(math.min(viewport.X / 1280, viewport.Y / 720), 0.92, 1.12) * CUSTOM.Scale
		sidebarWidth = math.clamp(CUSTOM.SidebarWidth, 210, 280)
	elseif platform == "Compact" then
		width = math.clamp(CUSTOM.WindowWidth, 640, 820)
		height = math.clamp(CUSTOM.WindowHeight, 420, 600)
		scale = math.clamp(CUSTOM.Scale, 0.72, 1)
		sidebarWidth = math.clamp(CUSTOM.SidebarWidth, 170, 215)
	else
		width = math.clamp(CUSTOM.WindowWidth, 640, 1280)
		height = math.clamp(CUSTOM.WindowHeight, 420, 900)
		scale = math.clamp(CUSTOM.Scale, 0.7, 1.3)
		sidebarWidth = math.clamp(CUSTOM.SidebarWidth, 180, 300)
	end

	pcall(function()
		mainVisual.AnchorPoint = Vector2.new(0.5, 0.5)
		mainVisual.Position = UDim2.fromScale(0.5, 0.5)
		mainVisual.Size = UDim2.fromOffset(width, height)
	end)

	pcall(function()
		if type(Window.SetUIScale) == "function" then
			Window:SetUIScale(scale)
		end
	end)

	updateSidebarWidth(sidebarWidth)
end

local function applyVisualCustomization()
	WindUI.TransparencyValue = math.clamp(CUSTOM.Transparency, 0, 0.4)
	applyCustomTheme()
	applySafeArea()
	applyResponsiveLayout()

	if revampObjects.OutlineCorner then
		revampObjects.OutlineCorner.CornerRadius = UDim.new(0, CUSTOM.WindowRadius)
	end
	if revampObjects.AccentRail then
		revampObjects.AccentRail.Visible = CUSTOM.ShowAccentRail
	end
	if revampObjects.SidebarDivider then
		revampObjects.SidebarDivider.Visible = CUSTOM.ShowSidebarDivider
	end

	if typeof(visualRoot) == "Instance" then
		for _, descendant in ipairs(visualRoot:GetDescendants()) do
			applyRevampInstance(descendant)
		end
	end
end

local function applyThemePreset(name)
	local preset = THEME_PRESETS[name]
	if not preset then
		return false
	end

	CUSTOM.Preset = name
	for key, value in pairs(preset) do
		CUSTOM[key] = value
	end
	applyVisualCustomization()
	return true
end

local function disableNativeTooltips()
	local candidates = {
		WindUI.TooltipGui,
		typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui:FindFirstChild("ToolTips", true) or nil,
		typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui:FindFirstChild("Tooltips", true) or nil,
	}

	for _, candidate in ipairs(candidates) do
		if typeof(candidate) == "Instance" then
			if candidate:IsA("ScreenGui") then
				candidate.Enabled = false
			elseif candidate:IsA("GuiObject") then
				candidate.Visible = false
			else
				for _, child in ipairs(candidate:GetChildren()) do
					child:Destroy()
				end
				trackUniversalResource(candidate.ChildAdded:Connect(function(child)
					child:Destroy()
				end))
			end
		end
	end
end

local tooltipFrame
local tooltipLabel
local tooltipStroke

local function createInstantTooltip()
	if typeof(WindUI.ScreenGui) ~= "Instance" then
		return
	end

	tooltipFrame = Instance.new("Frame")
	tooltipFrame.Name = "BadWarsInstantTooltip"
	tooltipFrame.AnchorPoint = Vector2.new(0, 0)
	tooltipFrame.Size = UDim2.fromOffset(180, 38)
	tooltipFrame.BackgroundColor3 = CUSTOM.Panel
	tooltipFrame.BackgroundTransparency = 0.02
	tooltipFrame.BorderSizePixel = 0
	tooltipFrame.Visible = false
	tooltipFrame.Active = false
	tooltipFrame.Selectable = false
	tooltipFrame.ZIndex = 10000
	tooltipFrame.Parent = WindUI.ScreenGui

	local corner = Instance.new("UICorner")
	corner.Name = "TooltipCorner"
	corner.CornerRadius = UDim.new(0, CUSTOM.ElementRadius)
	corner.Parent = tooltipFrame

	tooltipStroke = Instance.new("UIStroke")
	tooltipStroke.Name = "TooltipStroke"
	tooltipStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tooltipStroke.LineJoinMode = Enum.LineJoinMode.Round
	tooltipStroke.Color = CUSTOM.Border
	tooltipStroke.Thickness = 1
	tooltipStroke.Transparency = 0.08
	tooltipStroke.Parent = tooltipFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 9)
	padding.PaddingBottom = UDim.new(0, 9)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent = tooltipFrame

	tooltipLabel = Instance.new("TextLabel")
	tooltipLabel.Name = "TooltipText"
	tooltipLabel.Size = UDim2.fromScale(1, 1)
	tooltipLabel.BackgroundTransparency = 1
	tooltipLabel.TextColor3 = CUSTOM.Text
	tooltipLabel.TextSize = 14
	tooltipLabel.TextWrapped = true
	tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
	tooltipLabel.TextYAlignment = Enum.TextYAlignment.Center
	tooltipLabel.FontFace = Font.new(
		"rbxasset://fonts/families/GothamSSm.json",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	)
	tooltipLabel.ZIndex = tooltipFrame.ZIndex + 1
	tooltipLabel.Parent = tooltipFrame

	revampObjects.Tooltip = tooltipFrame
	revampObjects.TooltipCorner = corner
end

local function cleanTooltipText(text)
	text = tostring(text or "")
	text = text:gsub("^%s+", ""):gsub("%s+$", "")
	text = text:gsub("%s+", " ")
	return text
end

local function extractTooltipText(target)
	if typeof(target) ~= "Instance" then
		return nil
	end

	local attributed = cleanTooltipText(target:GetAttribute("BadWarsTooltip"))
	if attributed ~= "" then
		return attributed
	end

	local fallback
	local current = target
	for _ = 1, 4 do
		if typeof(current) ~= "Instance" then
			break
		end

		for _, descendant in ipairs(current:GetDescendants()) do
			if descendant:IsA("TextLabel") then
				local text = cleanTooltipText(descendant.Text)
				if text ~= "" then
					local lowerName = string.lower(descendant.Name)
					if lowerName:find("desc", 1, true)
						or lowerName:find("description", 1, true)
						or lowerName:find("subtitle", 1, true)
						or lowerName:find("hint", 1, true)
					then
						return text
					end
					if not fallback or #text > #fallback then
						fallback = text
					end
				end
			end
		end

		current = current.Parent
	end

	if fallback and #fallback >= 8 then
		return fallback
	end
	return nil
end

local function positionTooltip(target, pointer)
	if not tooltipFrame or not tooltipFrame.Visible then
		return
	end

	local camera = Workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local position

	if typeof(pointer) == "Vector2" then
		position = pointer + Vector2.new(14, 18)
	elseif typeof(pointer) == "Vector3" then
		position = Vector2.new(pointer.X + 14, pointer.Y + 18)
	elseif typeof(target) == "Instance" and target:IsA("GuiObject") then
		position = target.AbsolutePosition + Vector2.new(target.AbsoluteSize.X + 10, 4)
	else
		local mouse = UserInputService:GetMouseLocation()
		position = mouse + Vector2.new(14, 18)
	end

	local width = tooltipFrame.AbsoluteSize.X
	local height = tooltipFrame.AbsoluteSize.Y
	local x = math.clamp(position.X, 8, math.max(8, viewport.X - width - 8))
	local y = math.clamp(position.Y, 8, math.max(8, viewport.Y - height - 8))
	tooltipFrame.Position = UDim2.fromOffset(x, y)
end

local function hideInstantTooltip()
	tooltipToken += 1
	activeTooltipTarget = nil
	if tooltipFrame then
		tooltipFrame.Visible = false
	end
end

local function showInstantTooltip(target, pointer)
	if not CUSTOM.InstantTooltips or not tooltipFrame then
		return
	end

	local text = extractTooltipText(target)
	if not text then
		return
	end

	tooltipToken += 1
	local token = tooltipToken
	activeTooltipTarget = target

	task.delay(math.max(0, CUSTOM.TooltipDelay), function()
		if token ~= tooltipToken or activeTooltipTarget ~= target or not target.Parent then
			return
		end

		local bounds = TextService:GetTextSize(
			text,
			14,
			Enum.Font.GothamMedium,
			Vector2.new(320, 500)
		)
		tooltipFrame.Size = UDim2.fromOffset(
			math.clamp(bounds.X + 24, 150, 344),
			math.clamp(bounds.Y + 18, 36, 140)
		)
		tooltipFrame.BackgroundColor3 = CUSTOM.Panel
		tooltipLabel.TextColor3 = CUSTOM.Text
		tooltipLabel.Text = text
		tooltipStroke.Color = CUSTOM.HighContrast and CUSTOM.Text or CUSTOM.Border
		revampObjects.TooltipCorner.CornerRadius = UDim.new(0, CUSTOM.ElementRadius)
		tooltipFrame.Visible = true
		positionTooltip(target, pointer)
	end)
end

local function bindInstantTooltip(object)
	if tooltipBound[object] or not object:IsA("GuiButton") then
		return
	end

	tooltipBound[object] = true
	trackUniversalResource(object.MouseEnter:Connect(function()
		showInstantTooltip(object)
	end))
	trackUniversalResource(object.MouseLeave:Connect(function()
		if activeTooltipTarget == object then
			hideInstantTooltip()
		end
	end))
	trackUniversalResource(object.SelectionGained:Connect(function()
		showInstantTooltip(object)
	end))
	trackUniversalResource(object.SelectionLost:Connect(function()
		if activeTooltipTarget == object then
			hideInstantTooltip()
		end
	end))
	trackUniversalResource(object.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			showInstantTooltip(object, input.Position)
		end
	end))
end

local selectionFrame
local selectionStroke

local function createSelectionFrame()
	if typeof(WindUI.ScreenGui) ~= "Instance" then
		return
	end

	selectionFrame = Instance.new("Frame")
	selectionFrame.Name = "BadWarsGamepadSelection"
	selectionFrame.BackgroundTransparency = 1
	selectionFrame.BorderSizePixel = 0
	selectionFrame.Visible = false
	selectionFrame.Active = false
	selectionFrame.Selectable = false
	selectionFrame.ZIndex = 9998
	selectionFrame.Parent = WindUI.ScreenGui

	local corner = Instance.new("UICorner")
	corner.Name = "SelectionCorner"
	corner.CornerRadius = UDim.new(0, CUSTOM.ElementRadius + 2)
	corner.Parent = selectionFrame

	selectionStroke = Instance.new("UIStroke")
	selectionStroke.Name = "SelectionStroke"
	selectionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	selectionStroke.LineJoinMode = Enum.LineJoinMode.Round
	selectionStroke.Color = CUSTOM.Accent
	selectionStroke.Thickness = 2
	selectionStroke.Transparency = 0
	selectionStroke.Parent = selectionFrame

	revampObjects.Selection = selectionFrame
	revampObjects.SelectionCorner = corner
end

local function updateSelectionFrame()
	if not selectionFrame then
		return
	end

	local selected = GuiService.SelectedObject
	if not CUSTOM.GamepadNavigation
		or typeof(selected) ~= "Instance"
		or not selected:IsA("GuiObject")
		or not selected.Visible
	then
		selectionFrame.Visible = false
		return
	end

	selectionFrame.Position = UDim2.fromOffset(
		selected.AbsolutePosition.X - 3,
		selected.AbsolutePosition.Y - 3
	)
	selectionFrame.Size = UDim2.fromOffset(
		selected.AbsoluteSize.X + 6,
		selected.AbsoluteSize.Y + 6
	)
	selectionStroke.Color = CUSTOM.Accent
	revampObjects.SelectionCorner.CornerRadius = UDim.new(0, CUSTOM.ElementRadius + 2)
	selectionFrame.Visible = true
end

local function collectSidebarButtons()
	local results = {}
	local sidebar = type(Window.UIElements) == "table" and Window.UIElements.SideBar
	if typeof(sidebar) ~= "Instance" then
		return results
	end

	for _, descendant in ipairs(sidebar:GetDescendants()) do
		if descendant:IsA("GuiButton")
			and descendant.Visible
			and descendant.Active
		then
			table.insert(results, descendant)
		end
	end

	table.sort(results, function(left, right)
		if left.LayoutOrder == right.LayoutOrder then
			return left.AbsolutePosition.Y < right.AbsolutePosition.Y
		end
		return left.LayoutOrder < right.LayoutOrder
	end)
	return results
end

local function cycleSidebar(direction)
	local buttons = collectSidebarButtons()
	if #buttons == 0 then
		return
	end

	local selected = GuiService.SelectedObject
	local index = table.find(buttons, selected) or (direction > 0 and 0 or 1)
	index = ((index - 1 + direction) % #buttons) + 1
	GuiService.SelectedObject = buttons[index]
	updateSelectionFrame()
end

local function focusSearch()
	if typeof(visualRoot) ~= "Instance" then
		return
	end

	for _, descendant in ipairs(visualRoot:GetDescendants()) do
		if descendant:IsA("TextBox") then
			local lowerName = string.lower(descendant.Name)
			local placeholder = string.lower(descendant.PlaceholderText or "")
			if lowerName:find("search", 1, true) or placeholder:find("search", 1, true) then
				descendant:CaptureFocus()
				return
			end
		end
	end
end

local ACTION_TOGGLE = "BadWarsUniversalToggle"
local ACTION_BACK = "BadWarsUniversalBack"
local ACTION_PREVIOUS = "BadWarsUniversalPrevious"
local ACTION_NEXT = "BadWarsUniversalNext"
local ACTION_SEARCH = "BadWarsUniversalSearch"

local function universalInputAction(actionName, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if not CUSTOM.GamepadNavigation then
		return Enum.ContextActionResult.Pass
	end

	if actionName == ACTION_TOGGLE then
		task.defer(function()
			if type(d.Toggle) == "function" then
				d:Toggle()
			end
		end)
		return Enum.ContextActionResult.Sink
	elseif actionName == ACTION_BACK then
		local focused = UserInputService:GetFocusedTextBox()
		if focused then
			focused:ReleaseFocus()
		elseif d.Visible and type(d.Hide) == "function" then
			d:Hide()
		else
			hideInstantTooltip()
		end
		return Enum.ContextActionResult.Sink
	elseif actionName == ACTION_PREVIOUS then
		cycleSidebar(-1)
		return Enum.ContextActionResult.Sink
	elseif actionName == ACTION_NEXT then
		cycleSidebar(1)
		return Enum.ContextActionResult.Sink
	elseif actionName == ACTION_SEARCH then
		focusSearch()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

local function bindUniversalInput()
	pcall(function()
		GuiService.GuiNavigationEnabled = CUSTOM.GamepadNavigation
		GuiService.AutoSelectGuiEnabled = CUSTOM.GamepadNavigation
	end)

	ContextActionService:BindActionAtPriority(
		ACTION_TOGGLE,
		universalInputAction,
		false,
		3000,
		Enum.KeyCode.ButtonStart,
		Enum.KeyCode.ButtonSelect
	)
	ContextActionService:BindActionAtPriority(
		ACTION_BACK,
		universalInputAction,
		false,
		3000,
		Enum.KeyCode.ButtonB
	)
	ContextActionService:BindActionAtPriority(
		ACTION_PREVIOUS,
		universalInputAction,
		false,
		3000,
		Enum.KeyCode.ButtonL1
	)
	ContextActionService:BindActionAtPriority(
		ACTION_NEXT,
		universalInputAction,
		false,
		3000,
		Enum.KeyCode.ButtonR1
	)
	ContextActionService:BindActionAtPriority(
		ACTION_SEARCH,
		universalInputAction,
		false,
		3000,
		Enum.KeyCode.ButtonY
	)

	trackUniversalResource(function()
		for _, actionName in ipairs({
			ACTION_TOGGLE,
			ACTION_BACK,
			ACTION_PREVIOUS,
			ACTION_NEXT,
			ACTION_SEARCH,
		}) do
			pcall(ContextActionService.UnbindAction, ContextActionService, actionName)
		end
	end)
end

local function bindCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if camera then
		cameraConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			applyResponsiveLayout()
			updateSelectionFrame()
			if activeTooltipTarget then
				positionTooltip(activeTooltipTarget)
			end
		end)
		trackUniversalResource(cameraConnection)
	end
end

createRevampOutline(mainVisual, CUSTOM.WindowRadius)
createAccentRail(mainVisual)
createSidebarDivider(mainVisual)
disableNativeTooltips()
createInstantTooltip()
createSelectionFrame()
bindUniversalInput()
bindCamera()

if typeof(visualRoot) == "Instance" then
	for _, descendant in ipairs(visualRoot:GetDescendants()) do
		applyRevampInstance(descendant)
		bindInstantTooltip(descendant)
	end

	trackUniversalResource(visualRoot.DescendantAdded:Connect(function(descendant)
		task.defer(function()
			if descendant.Parent then
				applyRevampInstance(descendant)
				bindInstantTooltip(descendant)
			end
		end)
	end))
end

trackUniversalResource(UserInputService.LastInputTypeChanged:Connect(function()
	if CUSTOM.PlatformPreset == "Auto" then
		applyResponsiveLayout()
	end
end))

trackUniversalResource(UserInputService.InputChanged:Connect(function(input)
	if tooltipFrame and tooltipFrame.Visible
		and input.UserInputType == Enum.UserInputType.MouseMovement
	then
		positionTooltip(activeTooltipTarget, input.Position)
	end
end))

trackUniversalResource(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	updateSelectionFrame()
end))

trackUniversalResource(Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindCamera()
	applyResponsiveLayout()
end))

d.Customization = CUSTOM
d.CustomizationDefaults = CUSTOMIZATION_DEFAULTS
d.ThemePresets = THEME_PRESETS
d.ApplyCustomization = applyVisualCustomization
d.SetPlatformPreset = function(_, preset)
	CUSTOM.PlatformPreset = tostring(preset or "Auto")
	applyVisualCustomization()
	return CUSTOM.PlatformPreset
end
d.SetThemePreset = function(_, preset)
	return applyThemePreset(tostring(preset or "BadWars"))
end

applyVisualCustomization()
local function setWindowHidden(hidden)
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
		Title = "v3.0",
		Icon = "badge-check",
		Color = Color3.fromHex("#FF335F"),
		Border = true,
	})
	Window:Tag({
		Title = "STABLE",
		Icon = "check",
		Color = Color3.fromHex("#22C55E"),
		Border = true,
	})
end)

local Tabs = {}
d.Tabs = Tabs

local tabMetadata = {
	General = { Icon = "home", Desc = "Dashboard, loader, and core controls" },
	Modules = { Icon = "list", Desc = "Runtime health and module diagnostics" },
	Blatant = { Icon = "flame", Desc = "High-impact gameplay modules" },
	Combat = { Icon = "sword", Desc = "Combat targeting and assistance" },
	Render = { Icon = "eye", Desc = "Visual overlays and world rendering" },
	Utility = { Icon = "wrench", Desc = "Automation and quality-of-life tools" },
	World = { Icon = "globe", Desc = "Movement and environment controls" },
	Minigames = { Icon = "gamepad-2", Desc = "Mode-specific modules and helpers" },
	Legit = { Icon = "user-check", Desc = "Low-profile assistance modules" },
	Friends = { Icon = "users", Desc = "Friend protection and player lists" },
	Targets = { Icon = "crosshair", Desc = "Target selection and filtering" },
	Notifications = { Icon = "bell", Desc = "Runtime alerts and event history" },
	Settings = { Icon = "settings", Desc = "Interface, scale, and profiles" },
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
-- Modules Tab
Tabs.Modules:Paragraph({
	Title = "Runtime Overview",
	Desc = "A focused view of module loading, health, and interface controls.",
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

local runtimeHealthSection = Tabs.Modules:Section({
	Title = "Runtime Health",
	Desc = "Live registration status for the active module set",
	Icon = "badge-check",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

moduleHealthProgress = runtimeHealthSection:ProgressBar({
	Title = "Module Readiness",
	Desc = "Modules available to the current game runtime",
	Value = { Min = 0, Max = 100, Default = 0 },
	DisplayMode = "Percent",
	Animate = true,
	Width = 220,
})

moduleHealthLabel = runtimeHealthSection:Paragraph({
	Title = "Registration Status",
	Desc = "Waiting for modules to load...",
})

local runtimeControlsSection = Tabs.Modules:Section({
	Title = "Interface Controls",
	Desc = "Essential shortcuts and persistence behavior",
	Icon = "settings",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

runtimeControlsSection:Paragraph({
	Title = "RightShift",
	Desc = "Show or hide the control center without disabling active modules.",
})

runtimeControlsSection:Paragraph({
	Title = "Profiles",
	Desc = "Compatible module options persist through the active profile manager.",
})

-- Real-time module tracking-- Real-time module tracking
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

local function registerOption(module, name, option)
	local baseName = tostring(name or option.Name or option.Type)
	local uniqueName = baseName
	local suffix = 2
	while module.Options[uniqueName] and module.Options[uniqueName] ~= option do
		uniqueName = baseName .. " " .. suffix
		suffix += 1
	end
	option.Name = uniqueName
	module.Options[uniqueName] = option
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
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
	return registerOption(module, option.Name, option)
end

local function createFontOption(module, section, settings)
	settings = settings or {}
	local fonts = firstNonNil(settings.List, settings.Values, {
		"Gotham", "Arial", "SourceSans", "Roboto", "Ubuntu", "Fantasy", "Code", "Highway",
	})
	settings.List = fonts
	settings.Default = firstNonNil(settings.Default, settings.Value, fonts[1])
	return createDropdownOption(module, section, settings)
end

local function createTargetsOption(module, section, settings)
	settings = settings or {}
	local labels = {}
	local defaults = {}
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
		Value = defaults,
		Visible = true,
		Destroyed = false,
	}
	for label, enabled in pairs(defaults) do
		option[label] = enabled
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
		for label, enabled in pairs(map) do option[label] = enabled end
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
				if value[label] == true or table.find(value, label) then
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
	return registerOption(module, option.Name, option)
end

-- ─── Category system ───
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
			Desc = baseDescription ~= "" and baseDescription or (name .. " module"),
			Icon = settings.Icon or iconName or categoryIcons[name],
			Opened = settings.Opened == true or settings.Expanded == true,
			Box = settings.Box ~= false,
			BoxBorder = settings.BoxBorder ~= false,
			TextSize = 17,
			DescTextSize = 13,
			FontWeight = Enum.FontWeight.SemiBold,
			DescFontWeight = Enum.FontWeight.Medium,
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
			return registerOption(module, option.Name, option)
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

function d.CreateOverlay(self, settings)
	if self ~= d then settings = self end
	settings = settings or {}
	local name = tostring(settings.Name or "Overlay")
	if d.Overlays[name] then
		return d.Overlays[name]
	end
	local overlay = d.Categories.Render:CreateModule(settings)
	d.Overlays[name] = overlay
	return overlay
end

-- ─── Main category (legacy compat) ───
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
	Title = "BadWars Control Center",
	Desc = "A structured interface for modules, profiles, runtime health, and player configuration. Press RightShift to toggle.",
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
	Desc = "Common loader and session actions",
	Icon = "swords",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
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
	Title = "Interface",
	Desc = "Scale, transparency, and visual density",
	Icon = "settings",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

local customizationControls = {}
local syncingCustomization = false

local function updateCustomizationControl(control, value, ...)
	if type(control) == "table" then
		setControlValue(control, value, ...)
	end
end

local function syncCustomizationControls()
	if syncingCustomization then
		return
	end
	syncingCustomization = true

	updateCustomizationControl(customizationControls.ThemePreset, CUSTOM.Preset)
	updateCustomizationControl(customizationControls.PlatformPreset, CUSTOM.PlatformPreset)
	updateCustomizationControl(customizationControls.Accent, CUSTOM.Accent)
	updateCustomizationControl(customizationControls.AccentWarm, CUSTOM.AccentWarm)
	updateCustomizationControl(customizationControls.AccentCool, CUSTOM.AccentCool)
	updateCustomizationControl(customizationControls.Canvas, CUSTOM.Canvas)
	updateCustomizationControl(customizationControls.Panel, CUSTOM.Panel)
	updateCustomizationControl(customizationControls.Raised, CUSTOM.Raised)
	updateCustomizationControl(customizationControls.Border, CUSTOM.Border)
	updateCustomizationControl(customizationControls.Text, CUSTOM.Text)
	updateCustomizationControl(customizationControls.Muted, CUSTOM.Muted)
	updateCustomizationControl(customizationControls.Scroll, CUSTOM.Scroll)
	updateCustomizationControl(customizationControls.Scale, math.floor(CUSTOM.Scale * 100 + 0.5))
	updateCustomizationControl(customizationControls.WindowWidth, CUSTOM.WindowWidth)
	updateCustomizationControl(customizationControls.WindowHeight, CUSTOM.WindowHeight)
	updateCustomizationControl(customizationControls.SidebarWidth, CUSTOM.SidebarWidth)
	updateCustomizationControl(customizationControls.WindowRadius, CUSTOM.WindowRadius)
	updateCustomizationControl(customizationControls.ElementRadius, CUSTOM.ElementRadius)
	updateCustomizationControl(customizationControls.Spacing, CUSTOM.Spacing)
	updateCustomizationControl(customizationControls.Transparency, math.floor(CUSTOM.Transparency * 100 + 0.5))
	updateCustomizationControl(customizationControls.ScrollbarThickness, CUSTOM.ScrollbarThickness)
	updateCustomizationControl(customizationControls.TooltipDelay, math.floor(CUSTOM.TooltipDelay * 1000 + 0.5))
	updateCustomizationControl(customizationControls.ShowScrollbars, CUSTOM.ShowScrollbars)
	updateCustomizationControl(customizationControls.ShowAccentRail, CUSTOM.ShowAccentRail)
	updateCustomizationControl(customizationControls.ShowSidebarDivider, CUSTOM.ShowSidebarDivider)
	updateCustomizationControl(customizationControls.InstantTooltips, CUSTOM.InstantTooltips)
	updateCustomizationControl(customizationControls.SafeArea, CUSTOM.SafeArea)
	updateCustomizationControl(customizationControls.GamepadNavigation, CUSTOM.GamepadNavigation)
	updateCustomizationControl(customizationControls.LargeTouchTargets, CUSTOM.LargeTouchTargets)
	updateCustomizationControl(customizationControls.HighContrast, CUSTOM.HighContrast)

	syncingCustomization = false
end

local platformSection = Tabs.Settings:Section({
	Title = "Platform and Input",
	Desc = "Responsive presets for desktop, touch, Xbox, and PlayStation controllers",
	Icon = "gamepad-2",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

customizationControls.PlatformPreset = platformSection:Dropdown({
	Title = "Platform Preset",
	Desc = "Auto adapts to the most recently used input device",
	Values = { "Auto", "Desktop", "Mobile", "Console", "Compact" },
	Value = CUSTOM.PlatformPreset,
	Flag = "settings/platform_preset",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.PlatformPreset = selectionName(value)
		applyVisualCustomization()
	end,
})

customizationControls.GamepadNavigation = platformSection:Toggle({
	Title = "Gamepad Navigation",
	Desc = "Xbox and PlayStation: Start toggles, B/Circle closes, L1/R1 changes tabs, Y/Triangle focuses search",
	Value = CUSTOM.GamepadNavigation,
	Flag = "settings/gamepad_navigation",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.GamepadNavigation = value == true
		pcall(function()
			GuiService.GuiNavigationEnabled = CUSTOM.GamepadNavigation
			GuiService.AutoSelectGuiEnabled = CUSTOM.GamepadNavigation
		end)
		updateSelectionFrame()
	end,
})

customizationControls.SafeArea = platformSection:Toggle({
	Title = "Device Safe Area",
	Desc = "Keeps controls clear of mobile notches, rounded screens, and console overscan",
	Value = CUSTOM.SafeArea,
	Flag = "settings/device_safe_area",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.SafeArea = value == true
		applySafeArea()
	end,
})

customizationControls.LargeTouchTargets = platformSection:Toggle({
	Title = "Touch-Friendly Sizing",
	Desc = "Uses the responsive mobile scale and larger usable controls",
	Value = CUSTOM.LargeTouchTargets,
	Flag = "settings/large_touch_targets",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.LargeTouchTargets = value == true
		applyResponsiveLayout()
	end,
})

customizationControls.InstantTooltips = platformSection:Toggle({
	Title = "Instant Tooltips",
	Desc = "Replaces WindUI's delayed tooltip layer",
	Value = CUSTOM.InstantTooltips,
	Flag = "settings/instant_tooltips",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.InstantTooltips = value == true
		if not CUSTOM.InstantTooltips then
			hideInstantTooltip()
		end
	end,
})

customizationControls.TooltipDelay = platformSection:Slider({
	Title = "Tooltip Delay",
	Desc = "Delay in milliseconds; 0 displays immediately",
	Value = { Min = 0, Max = 300, Default = math.floor(CUSTOM.TooltipDelay * 1000 + 0.5) },
	Step = 10,
	Flag = "settings/tooltip_delay",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.TooltipDelay = math.clamp(tonumber(value) or 0, 0, 300) / 1000
	end,
})

local themeSection = Tabs.Settings:Section({
	Title = "Theme Studio",
	Desc = "Every major interface color can be changed independently",
	Icon = "eye",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

customizationControls.ThemePreset = themeSection:Dropdown({
	Title = "Color Preset",
	Values = { "BadWars", "Midnight", "Ember", "Violet", "Ocean", "Monochrome" },
	Value = CUSTOM.Preset,
	Flag = "settings/theme_preset",
	Callback = function(value)
		if syncingCustomization then return end
		local name = selectionName(value)
		if applyThemePreset(name) then
			syncCustomizationControls()
		end
	end,
})

local function addColorControl(key, title, description, flag)
	customizationControls[key] = themeSection:Colorpicker({
		Title = title,
		Desc = description,
		Default = CUSTOM[key],
		Flag = flag,
		Callback = function(color)
			if syncingCustomization then return end
			if typeof(color) == "Color3" then
				CUSTOM[key] = color
				CUSTOM.Preset = "Custom"
				applyVisualCustomization()
			end
		end,
	})
end

addColorControl("Accent", "Primary Accent", "Toggles, selections, and focus indicators", "settings/color_accent")
addColorControl("AccentWarm", "Secondary Accent", "Middle color in the branded accent rail", "settings/color_accent_warm")
addColorControl("AccentCool", "Tertiary Accent", "Final color in gradients and highlights", "settings/color_accent_cool")
addColorControl("Canvas", "Window Background", "Deepest background layer", "settings/color_canvas")
addColorControl("Panel", "Panel Background", "Sidebar, tooltips, dialogs, and panels", "settings/color_panel")
addColorControl("Raised", "Element Background", "Cards, controls, buttons, and inputs", "settings/color_raised")
addColorControl("Border", "Border Color", "Window, card, and tooltip outlines", "settings/color_border")
addColorControl("Text", "Primary Text", "Titles, values, and selected navigation", "settings/color_text")
addColorControl("Muted", "Muted Text", "Descriptions and secondary labels", "settings/color_muted")
addColorControl("Scroll", "Scrollbar Color", "The single primary content scrollbar", "settings/color_scroll")

customizationControls.HighContrast = themeSection:Toggle({
	Title = "High Contrast",
	Desc = "Brighter text and stronger borders for visibility",
	Value = CUSTOM.HighContrast,
	Flag = "settings/high_contrast",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.HighContrast = value == true
		applyVisualCustomization()
	end,
})

customizationControls.ShowAccentRail = themeSection:Toggle({
	Title = "Accent Rail",
	Desc = "Show the three-color brand rail across the top",
	Value = CUSTOM.ShowAccentRail,
	Flag = "settings/show_accent_rail",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.ShowAccentRail = value == true
		applyVisualCustomization()
	end,
})

customizationControls.ShowSidebarDivider = themeSection:Toggle({
	Title = "Sidebar Divider",
	Desc = "Show the separator between navigation and content",
	Value = CUSTOM.ShowSidebarDivider,
	Flag = "settings/show_sidebar_divider",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.ShowSidebarDivider = value == true
		applyVisualCustomization()
	end,
})

local layoutSection = Tabs.Settings:Section({
	Title = "Layout and Density",
	Desc = "Customize scale, dimensions, curvature, spacing, opacity, and scrolling",
	Icon = "settings",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
})

customizationControls.Scale = layoutSection:Slider({
	Title = "UI Scale",
	Value = { Min = 70, Max = 130, Default = math.floor(CUSTOM.Scale * 100 + 0.5) },
	Step = 2,
	Flag = "settings/ui_scale",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.Scale = math.clamp(value / 100, 0.7, 1.3)
		applyResponsiveLayout()
	end,
})

customizationControls.WindowWidth = layoutSection:Slider({
	Title = "Window Width",
	Value = { Min = 640, Max = 1280, Default = CUSTOM.WindowWidth },
	Step = 10,
	Flag = "settings/window_width",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.WindowWidth = value
		applyResponsiveLayout()
	end,
})

customizationControls.WindowHeight = layoutSection:Slider({
	Title = "Window Height",
	Value = { Min = 420, Max = 900, Default = CUSTOM.WindowHeight },
	Step = 10,
	Flag = "settings/window_height",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.WindowHeight = value
		applyResponsiveLayout()
	end,
})

customizationControls.SidebarWidth = layoutSection:Slider({
	Title = "Sidebar Width",
	Value = { Min = 170, Max = 300, Default = CUSTOM.SidebarWidth },
	Step = 2,
	Flag = "settings/sidebar_width",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.SidebarWidth = value
		applyResponsiveLayout()
	end,
})

customizationControls.WindowRadius = layoutSection:Slider({
	Title = "Window Radius",
	Value = { Min = 6, Max = 30, Default = CUSTOM.WindowRadius },
	Step = 1,
	Flag = "settings/window_radius",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.WindowRadius = value
		applyVisualCustomization()
	end,
})

customizationControls.ElementRadius = layoutSection:Slider({
	Title = "Control Radius",
	Value = { Min = 4, Max = 24, Default = CUSTOM.ElementRadius },
	Step = 1,
	Flag = "settings/element_radius",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.ElementRadius = value
		applyVisualCustomization()
	end,
})

customizationControls.Spacing = layoutSection:Slider({
	Title = "Vertical Spacing",
	Value = { Min = 2, Max = 18, Default = CUSTOM.Spacing },
	Step = 1,
	Flag = "settings/vertical_spacing",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.Spacing = value
		applyVisualCustomization()
	end,
})

customizationControls.Transparency = layoutSection:Slider({
	Title = "Surface Transparency",
	Desc = "0 is opaque; 40 is the lightest supported glass effect",
	Value = { Min = 0, Max = 40, Default = math.floor(CUSTOM.Transparency * 100 + 0.5) },
	Step = 1,
	Flag = "settings/surface_transparency",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.Transparency = math.clamp(value / 100, 0, 0.4)
		applyVisualCustomization()
	end,
})

customizationControls.ShowScrollbars = layoutSection:Toggle({
	Title = "Show Content Scrollbar",
	Desc = "Only one scrollbar is shown for the primary content pane",
	Value = CUSTOM.ShowScrollbars,
	Flag = "settings/show_scrollbars",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.ShowScrollbars = value == true
		applyVisualCustomization()
	end,
})

customizationControls.ScrollbarThickness = layoutSection:Slider({
	Title = "Scrollbar Thickness",
	Value = { Min = 1, Max = 8, Default = CUSTOM.ScrollbarThickness },
	Step = 1,
	Flag = "settings/scrollbar_thickness",
	Callback = function(value)
		if syncingCustomization then return end
		CUSTOM.ScrollbarThickness = value
		applyVisualCustomization()
	end,
})

layoutSection:Button({
	Title = "Reset Visual Settings",
	Icon = "refresh-cw",
	Desc = "Restore every visual, input, color, and layout setting",
	Callback = function()
		for key, value in pairs(CUSTOMIZATION_DEFAULTS) do
			CUSTOM[key] = value
		end
		applyVisualCustomization()
		syncCustomizationControls()
		d:CreateNotification("Customization", "Visual settings restored", 3, "success")
	end,
})
-- Profile section
local profileSection = Tabs.Settings:Section({
	Title = "Profiles",
	Desc = "Save, load, and reset configuration sets",
	Icon = "folder",
	Opened = true,
	Box = true,
	BoxBorder = true,
	TextSize = 17,
	DescTextSize = 13,
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
	Title = "Friend Protection",
	Desc = "Control how friends are treated by active modules",
	Icon = "users",
	Opened = true,
	Box = true,
	BoxBorder = true,
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
	Title = "Server Players",
	Desc = "Manage protected players in the current server",
	Icon = "user-check",
	Opened = true,
	Box = true,
	BoxBorder = true,
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
	Title = "Target Rules",
	Desc = "Configure target selection behavior",
	Icon = "crosshair",
	Opened = true,
	Box = true,
	BoxBorder = true,
})

local targetsCategory = d.Categories.Targets

targetsSection:Divider()

local targetsListSection = Tabs.Targets:Section({
	Title = "Server Targets",
	Desc = "Select priority targets in the current server",
	Icon = "crosshair",
	Opened = true,
	Box = true,
	BoxBorder = true,
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

	pcall(function()
		if type(Window.Open) == "function" then Window:Open() end
	end)
	pcall(function()
		if type(Window.Show) == "function" then Window:Show() end
	end)

	setWindowHidden(false)

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
