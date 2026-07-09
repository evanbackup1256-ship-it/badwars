-- BADWARS_WINDUI_INTEGRATION
-- WindUI adapter with a centralized legacy compatibility layer.
-- Existing module behavior is preserved; this file only translates GUI APIs and lifecycle state.

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
	Version = "WindUI-Adapter-2.0",
	PremiumBuild = false,
	Name = "BadWars-WindUI",
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
	return Color3.fromRGB(255, 48, 88)
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
	WindUI:SetTheme("Dark")
end)

local Window = WindUI:CreateWindow({
	Title = "BadWars",
	Author = "Roblox",
	Icon = "swords",
	Folder = "BadWars",
	NewElements = true,
	HideSearchBar = false,
	ScrollBarEnabled = true,
	AutoScale = false,
	Resizable = true,
	Size = UDim2.new(0, 680, 0, 500),
	MinSize = Vector2.new(520, 340),
	MaxSize = Vector2.new(920, 680),
	ToggleKey = Enum.KeyCode.RightShift,
	OpenButton = {
		Title = "BadWars",
		Enabled = true,
		Draggable = true,
		Scale = 0.55,
		Color = ColorSequence.new(Color3.fromHex("#FF3355"), Color3.fromHex("#FF8800")),
	},
	Topbar = {
		Height = 46,
		ButtonsType = "Mac",
	},
})

if type(Window) ~= "table" then
	error("WindUI failed to create the BadWars window")
end

d.Window = Window

pcall(function()
	Window:SetUIScale(0.9)
end)

d.gui = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui
	or (typeof(findWindowMain(Window)) == "Instance" and findWindowMain(Window))
	or Window

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
task.defer(function()
	task.wait()
	if not d.Visible and not d.Destroyed then
		setWindowHidden(true)
	end
end)

pcall(function()
	Window:Tag({
		Title = "v2 • WindUI",
		Icon = "badge-check",
		Color = Color3.fromHex("#22c55e"),
		Border = true,
	})
end)

local Tabs = {}
d.Tabs = Tabs

local tabMetadata = {
	General = { Icon = "home", Desc = "Core settings and quick actions" },
	Modules = { Icon = "list", Desc = "Module browser and usage help" },
	Blatant = { Icon = "flame", Desc = "High-visibility modules" },
	Combat = { Icon = "sword", Desc = "Combat modules" },
	Render = { Icon = "eye", Desc = "Visuals and overlays" },
	Utility = { Icon = "wrench", Desc = "Helpers and automation" },
	World = { Icon = "globe", Desc = "World and movement modules" },
	Minigames = { Icon = "gamepad-2", Desc = "Minigame-specific modules" },
	Legit = { Icon = "user-check", Desc = "Lower-profile modules" },
	Friends = { Icon = "users", Desc = "Friend configuration" },
	Targets = { Icon = "crosshair", Desc = "Target configuration" },
	Notifications = { Icon = "bell", Desc = "Notification history" },
	Settings = { Icon = "settings", Desc = "Interface and profile management" },
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

Tabs.Modules:Paragraph({
	Title = "Module Browser",
	Desc = "Modules are grouped by category. Each module uses a collapsed section by default to reduce layout work and execution lag.",
})
Tabs.Modules:Paragraph({
	Title = "Controls",
	Desc = "RightShift toggles the window. Options are synchronized with their legacy module objects and can be persisted with profile flags.",
})

local moduleHealthProgress
local function updateModuleHealthProgress(ready, total)
	if moduleHealthProgress then
		local pct = total > 0 and math.floor((ready / total) * 100 + 0.5) or 0
		if type(moduleHealthProgress.Set) == "function" then
			pcall(moduleHealthProgress.Set, moduleHealthProgress, pct)
		end
	end
end

moduleHealthProgress = Tabs.Modules:ProgressBar({
	Title = "Module Health",
	Desc = "Percentage of modules loaded successfully",
	Value = { Min = 0, Max = 100, Default = 0 },
	DisplayMode = "Percent",
	Animate = true,
})

-- Update health progress after modules load
task.defer(function()
	task.wait(2)
	local B = shared.Bad
	if B and type(B.GetBedWarsModuleHealth) == "function" then
		local report = B:GetBedWarsModuleHealth()
		if type(report) == "table" and report.Total then
			updateModuleHealthProgress(report.Ready or 0, report.Total)
		end
	end
end)

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
			-- WindUI invokes this when the bound key is pressed.
			option.Value = normalizeKey(option.Object and option.Object.Value or key)
			runUserCallback(option.Name, settings.Function or settings.Callback, key)
		end,
	})
	pcall(function()
		local label = option.Object.UIElements.Keybind.Frame.Frame.TextLabel
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
				description = description ~= "" and (description .. " • " .. tostring(text)) or tostring(text)
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
			if d.Modules[moduleName] == module then d.Modules[moduleName] = nil end
			d.Modules[name .. "/" .. moduleName] = nil
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
		d.Modules[name .. "/" .. moduleName] = module
		if d.Modules[moduleName] == nil then
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

local mainCategory = {
	Type = "ServiceCategory",
	Name = "Main",
	Options = {},
	Modules = {},
}
d.Categories.Main = mainCategory

local generalModule = {
	Name = "General",
	Category = "Main",
	Options = mainCategory.Options,
}

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
	mainCategory.Options[name] = option
	return option
end

mainCategory.Options["GUI bind indicator"] = createMainToggle("GUI Bind Indicator", true)
mainCategory.Options["Teams by server"] = createMainToggle("Teams by server", false)
mainCategory.Options["Use team color"] = createMainToggle("Use team color", true)
-- Preserve exact legacy keys and casing.
mainCategory.Options["GUI bind indicator"] = mainCategory.Options["GUI Bind Indicator"] or mainCategory.Options["GUI bind indicator"]

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

Tabs.General:Button({
	Title = "Uninject / Self Destruct",
	Icon = "x",
	Callback = function()
		local dialog = Window:Dialog({
			Title = "Uninject BadWars?",
			Content = "This will remove all modules and close the interface. This action cannot be undone.",
			Buttons = {
				{
					Title = "Cancel",
					Variant = "Secondary",
					Callback = function() end,
				},
				{
					Title = "Uninject",
					Variant = "Primary",
					Callback = function()
						d:CreateNotification("BadWars", "Uninjecting...", 2, "warning")
						task.defer(function()
							d:Uninject()
						end)
					end,
				},
			},
		})
		if type(dialog) == "table" and type(dialog.Show) == "function" then
			dialog:Show()
		end
	end,
})
Tabs.General:Space()
Tabs.General:Paragraph({
	Title = "Quick Info",
	Desc = "Use RightShift to toggle the interface. Module sections stay collapsed until opened, reducing startup layout cost.",
})

-- Loader script display
Tabs.General:Code({
	Title = "Loader Script",
	Code = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()',
	CanCopied = true,
})

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
	if not manager then return false, "Config manager is unavailable" end
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
	if not manager then return false, "Config manager is unavailable" end
	local config = manager:GetConfig(name)
	if type(config) ~= "table" or type(config.Load) ~= "function" then
		config = manager:CreateConfig(name, true)
	end
	if not config then return false, "Unable to create profile" end
	config:SetAsCurrent()
	return config:Load()
end

Tabs.Settings:Toggle({
	Title = "UI Transparency",
	Desc = "Use WindUI's transparent surface treatment",
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
Tabs.Settings:Slider({
	Title = "UI Scale",
	Desc = "Adjust the interface without automatic resize overrides",
	Value = { Min = 0.65, Max = 1.25, Default = 0.9 },
	Step = 0.05,
	Flag = "settings/ui_scale",
	Callback = function(value)
		pcall(function() Window:SetUIScale(value) end)
	end,
})

-- UI Scale progress indicator
local uiScaleProgress = Tabs.Settings:ProgressBar({
	Title = "UI Scale",
	Desc = "Current interface scale",
	Value = { Min = 65, Max = 125, Default = 90 },
	DisplayMode = "Value",
	Format = function(value)
		return string.format("%.0f%%", value)
	end,
	Width = 200,
	Animate = true,
})

-- Sync slider to progress bar
local uiScaleSlider = Tabs.Settings:Slider({
	Title = "Adjust Scale",
	Value = { Min = 65, Max = 125, Default = 90 },
	Step = 5,
	Callback = function(value)
		local scale = value / 100
		pcall(function() Window:SetUIScale(scale) end)
		if uiScaleProgress and type(uiScaleProgress.Set) == "function" then
			pcall(uiScaleProgress.Set, uiScaleProgress, value)
		end
	end,
})
Tabs.Settings:Input({
	Title = "Profile Name",
	Value = currentProfileName,
	Placeholder = "default",
	Callback = function(value)
		if tostring(value or "") ~= "" then
			currentProfileName = sanitizeName(value)
		end
	end,
})
Tabs.Settings:Button({
	Title = "Save Current Profile",
	Icon = "save",
	Callback = function()
		local ok, result = saveProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and ("Saved '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")
	end,
})
Tabs.Settings:Button({
	Title = "Load Profile",
	Icon = "folder-open",
	Callback = function()
		local ok, result = loadProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and ("Loaded '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")
	end,
})

-- Profile management HStack
local profileHStack = Tabs.Settings:HStack()
profileHStack:Button({
	Title = "Save",
	Icon = "save",
	Callback = function()
		local ok, result = saveProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and "Saved" or tostring(result), 3, ok and "success" or "error")
	end,
})
profileHStack:Button({
	Title = "Load",
	Icon = "folder-open",
	Callback = function()
		local ok, result = loadProfile(currentProfileName)
		d:CreateNotification("Profiles", ok and "Loaded" or tostring(result), 3, ok and "success" or "error")
	end,
})
profileHStack:Button({
	Title = "Reset",
	Icon = "trash",
	Callback = function()
		local dialog = Window:Dialog({
			Title = "Reset Profile?",
			Content = "This will clear all saved settings for '" .. currentProfileName .. "'.",
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
Tabs.Settings:Button({
	Title = "Reinject / Reload",
	Icon = "refresh-cw",
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

local welcomeShown = false
function d.Show(self)
	if self ~= d then return d:Show() end
	if d.Destroyed then return false end
	d.Visible = true

	-- Try multiple methods to open the WindUI window
	pcall(function()
		if type(Window.Open) == "function" then Window:Open() end
	end)
	pcall(function()
		if type(Window.Show) == "function" then Window:Show() end
	end)

	setWindowHidden(false)

	-- Ensure visibility after a frame
	task.defer(function()
		if d.Visible and not d.Destroyed then
			setWindowHidden(false)
			-- Also try direct instance visibility
			local main = findWindowMain(Window)
			if typeof(main) == "Instance" then
				pcall(function() main.Visible = true end)
			end
		end
	end)

	if not welcomeShown then
		welcomeShown = true
		d:CreateNotification("BadWars", "Interface ready. RightShift to toggle.", 4, "success")

		-- Show welcome popup on first load
		local popup = WindUI:Popup({
			Title = "Welcome to BadWars",
			Content = "Your loader is ready. Use RightShift to toggle the interface. Check the Modules tab for a health overview of all loaded features.",
			Buttons = {
				{
					Title = "Got it",
					Variant = "Primary",
					Callback = function() end,
				},
			},
		})
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

	for _, module in pairs(d.Modules) do
		if type(module) == "table" and module.Enabled and type(module.SetEnabled) == "function" then
			pcall(module.SetEnabled, module, false)
		end
	end

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

	pcall(function()
		if type(Window.Destroy) == "function" then Window:Destroy() end
	end)
	if shared then
		if shared.Bad == d then shared.Bad = nil end
		if shared.BadGUI == d then shared.BadGUI = nil end
	end
	return true
end

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
