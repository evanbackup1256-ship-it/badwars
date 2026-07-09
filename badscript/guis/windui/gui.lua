-- BADWARS_WINDUI_INTEGRATION
-- BADWARS_WINDUI_ADAPTER_V3
-- WindUI V8 adapter with centralized legacy compatibility and lifecycle management.

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
	Version = "WindUI-Adapter-3.0.0",
	AdapterVersion = "3.0.0",
	WindUIVersion = "unknown",
	SmartUIVersion = "unknown",
	WindUISource = "unknown",
	CompatibilityMode = false,
	PremiumBuild = false,
	Name = "BadWars-WindUI",
	Visible = false,
	Ready = false,
	BootState = "loading",
	Destroyed = false,
	LastAudit = nil,
}

local function pack(...)
	return { n = select("#", ...), ... }
end

local function unpackPacked(values)
	return table.unpack(values, 1, values.n)
end

local function safeTraceback(message, level)
	if type(debug) == "table" and type(debug.traceback) == "function" then
		return debug.traceback(tostring(message), level or 2)
	end
	return tostring(message)
end

local function safeCall(callback, ...)
	if type(callback) ~= "function" then
		return true
	end
	local args = pack(...)
	return xpcall(function()
		return callback(unpackPacked(args))
	end, function(message)
		return safeTraceback(message, 2)
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

local function validateSource(source)
	if type(source) ~= "string" or #source < 10000 then
		return false, "source is empty or too small"
	end
	if #source > 8000000 then
		return false, "source is unexpectedly large"
	end
	local trimmed = source:match("^%s*(.-)%s*$")
	local lower = string.lower(trimmed:sub(1, 500))
	if lower:find("<!doctype", 1, true) or lower:find("<html", 1, true) then
		return false, "received HTML instead of Luau"
	end
	if trimmed == "404: Not Found" or trimmed:find('"message"%s*:%s*"Not Found"') then
		return false, "source was not found"
	end
	return true
end

local function compileSource(source, chunkName)
	if type(loadstring) ~= "function" then
		return nil, "loadstring is unavailable"
	end
	local valid, validationError = validateSource(source)
	if not valid then
		return nil, validationError
	end
	local compiled, compileError = loadstring(source, chunkName)
	if not compiled then
		return nil, compileError
	end
	local ok, result = xpcall(compiled, function(message)
		return safeTraceback(message, 2)
	end)
	if not ok then
		return nil, result
	end
	if type(result) ~= "table" or type(result.CreateWindow) ~= "function" then
		return nil, "source did not return a valid WindUI library"
	end
	return result
end

local function readLocalSource(path)
	if type(readfile) ~= "function" or type(isfile) ~= "function" then
		return nil, "filesystem APIs are unavailable"
	end
	local existsOk, exists = pcall(isfile, path)
	if not existsOk or not exists then
		return nil, "file does not exist"
	end
	local readOk, contents = pcall(readfile, path)
	if not readOk then
		return nil, contents
	end
	return contents
end

local function downloadSource(url)
	local attempts = {
		function()
			if game and type(game.HttpGet) == "function" then
				return game:HttpGet(url, true)
			end
		end,
		function()
			return HttpService:GetAsync(url, true)
		end,
	}
	local lastError = "no HTTP method succeeded"
	for _, attempt in ipairs(attempts) do
		local ok, result = pcall(attempt)
		if ok and type(result) == "string" then
			return result
		end
		if not ok then
			lastError = tostring(result)
		end
	end
	return nil, lastError
end

local function loadWindUI()
	local failures = {}
	local localPaths = {
		"badscript/guis/windui/WindUI-BadWars-Tooltip-Restoration-V8.lua",
		"badscript/guis/windui/WindUI_v8.lua",
		"badscript/guis/windui/WindUI.lua",
		"badscript/guis/windui/WindUI_compat.lua",
	}

	for _, path in ipairs(localPaths) do
		local body, readError = readLocalSource(path)
		if type(body) == "string" then
			local library, loadError = compileSource(body, "@" .. path)
			if type(library) == "table" then
				d.WindUISource = path
				return library
			end
			table.insert(failures, path .. ": " .. tostring(loadError))
		elseif readError ~= "file does not exist" and readError ~= "filesystem APIs are unavailable" then
			table.insert(failures, path .. ": " .. tostring(readError))
		end
	end

	local urls = {
		"https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/guis/windui/WindUI.lua",
		"https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/guis/windui/WindUI-BadWars-Tooltip-Restoration-V8.lua",
		"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
	}

	for _, url in ipairs(urls) do
		local body, downloadError = downloadSource(url)
		if type(body) == "string" then
			local library, loadError = compileSource(body, "@WindUI:" .. url)
			if type(library) == "table" then
				d.WindUISource = url
				return library
			end
			table.insert(failures, url .. ": " .. tostring(loadError))
		else
			table.insert(failures, url .. ": " .. tostring(downloadError))
		end
	end

	error("Failed to load WindUI:\n" .. table.concat(failures, "\n"))
end

local WindUI = loadWindUI()
if type(WindUI.CreateWindow) ~= "function" then
	error("WindUI loaded, but CreateWindow is missing")
end

d.WindUI = WindUI
d.WindUIVersion = tostring(WindUI.Version or "unknown")
d.SmartUIVersion = type(WindUI.SmartUI) == "table" and tostring(WindUI.SmartUI.Version or "unknown") or "unavailable"
d.CompatibilityMode = d.SmartUIVersion == "unavailable"

pcall(function()
	WindUI.TransparencyValue = 0.08
	if type(WindUI.SetTheme) == "function" then
		WindUI:SetTheme("BadWars")
	end
	if type(WindUI.SetMotionScale) == "function" then
		WindUI:SetMotionScale(0.9)
	end
	if type(WindUI.RepairUI) == "function" then
		WindUI:RepairUI()
	end
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
	Size = UDim2.new(0, 740, 0, 520),
	MinSize = Vector2.new(520, 360),
	MaxSize = Vector2.new(1040, 780),
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

local function syncGuiReferences()
	d.RootGui = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGui or nil
	d.ScaledGui = typeof(WindUI.ScaledGui) == "Instance" and WindUI.ScaledGui
		or (d.RootGui and d.RootGui:FindFirstChild("ScaledGui"))
	d.ClickGui = typeof(WindUI.ClickGui) == "Instance" and WindUI.ClickGui
		or (d.ScaledGui and d.ScaledGui:FindFirstChild("ClickGui"))
	d.gui = d.RootGui
		or (typeof(findWindowMain(Window)) == "Instance" and findWindowMain(Window))
		or Window
	return d.gui
end

local function setCompatibilityRootVisible(visible)
	syncGuiReferences()
	for _, object in ipairs({ d.ScaledGui, d.ClickGui }) do
		if typeof(object) == "Instance" and object:IsA("GuiObject") then
			pcall(function()
				object.Visible = visible ~= false
			end)
		end
	end
end

local bootstrapHidden = true
local function setBootstrapHidden(hidden)
	bootstrapHidden = hidden == true
	local main = findWindowMain(Window)
	if typeof(main) == "Instance" then
		pcall(function()
			main.Visible = not bootstrapHidden
			if main:IsA("CanvasGroup") then
				main.GroupTransparency = bootstrapHidden and 1 or 0
			end
		end)
	end
	forEachOpenButton(Window, function(object)
		setObjectVisible(object, not bootstrapHidden)
	end)
end

syncGuiReferences()

pcall(function()
	if type(Window.SetUIScale) == "function" then
		Window:SetUIScale(0.94)
	elseif type(WindUI.SetUIScale) == "function" then
		WindUI:SetUIScale(0.94)
	end
end)

setBootstrapHidden(true)

pcall(function()
	Window:Tag({
		Title = "Adapter v3 · UI v8",
		Icon = "badge-check",
		Color = Color3.fromHex("#FF2D4A"),
		Border = true,
	})
end)

local function closeAllPopups()
	if type(WindUI.CloseAllPopups) == "function" then
		pcall(WindUI.CloseAllPopups, WindUI)
		return
	end
	for _, active in ipairs({ WindUI.ActiveDropdown, WindUI.ActiveTooltip }) do
		if type(active) == "table" and type(active.Close) == "function" then
			pcall(active.Close, active)
		end
	end
	WindUI.ActiveDropdown = nil
	WindUI.ActiveTooltip = nil
	WindUI.ActiveTooltipSource = nil
end

if type(Window.OnOpen) == "function" then
	Window:OnOpen(function()
		d.Visible = true
		setCompatibilityRootVisible(true)
		task.defer(function()
			if not d.Destroyed and type(Window.RefreshLayout) == "function" then
				pcall(Window.RefreshLayout, Window)
			end
		end)
	end)
end

if type(Window.OnClose) == "function" then
	Window:OnClose(function()
		d.Visible = false
		closeAllPopups()
	end)
end

if type(Window.OnDestroy) == "function" then
	Window:OnDestroy(function()
		d.Visible = false
		d.Destroyed = true
		d.Ready = false
		d.BootState = "destroyed"
	end)
end

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
	local lastCount = -1
	local stablePasses = 0
	while not d.Destroyed do
		task.wait(d.Ready and 1 or 0.4)

		local currentCount = 0
		local seen = {}
		for _, module in pairs(d.Modules) do
			if type(module) == "table" and not seen[module] then
				seen[module] = true
				currentCount += 1
			end
		end

		local report
		local runtime = type(shared) == "table" and shared.Bad or nil
		if type(runtime) == "table" and type(runtime.GetBedWarsModuleHealth) == "function" then
			local ok, result = pcall(runtime.GetBedWarsModuleHealth, runtime)
			if ok and type(result) == "table" then
				report = result
			end
		end

		if report and tonumber(report.Total) and tonumber(report.Total) > 0 then
			updateModuleHealth(tonumber(report.Ready) or currentCount, tonumber(report.Total))
		elseif currentCount ~= lastCount then
			if moduleHealthLabel and type(moduleHealthLabel.SetDesc) == "function" then
				pcall(moduleHealthLabel.SetDesc, moduleHealthLabel, string.format("%d modules registered", currentCount))
			end
			if moduleHealthProgress and type(moduleHealthProgress.Set) == "function" then
				pcall(moduleHealthProgress.Set, moduleHealthProgress, d.Ready and 100 or math.min(95, currentCount))
			end
		end

		if currentCount == lastCount then
			stablePasses += 1
		else
			stablePasses = 0
			lastCount = currentCount
		end

		if d.Ready and stablePasses >= 6 then
			return
		end
	end
end)

-- ─── Notifications Tab ───
local notificationLog = {}
local MAX_NOTIFICATION_LOG = 60
local notificationsEnabled = true
local notificationParagraph
local notificationRefreshQueued = false
local recentNotifications = {}

local function formatNotificationLog()
	local lines = {}
	for index = 1, math.min(#notificationLog, 20) do
		local entry = notificationLog[index]
		lines[index] = string.format("[%s] %s — %s", entry.time, entry.title, entry.text)
	end
	return #lines > 0 and table.concat(lines, "\n") or "No notifications yet."
end

local function refreshNotificationTab()
	if notificationRefreshQueued then
		return
	end
	notificationRefreshQueued = true
	task.defer(function()
		notificationRefreshQueued = false
		if d.Destroyed then
			return
		end
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
	end)
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
	text = text:sub(1, 2000)

	local key = title .. "\0" .. text .. "\0" .. notificationType
	local now = os.clock()
	local recent = recentNotifications[key]
	if recent and now - recent.time < 0.75 then
		return recent.entry
	end

	local entry = {
		time = os.date("%X"),
		title = title,
		text = text,
		type = notificationType,
	}
	recentNotifications[key] = { time = now, entry = entry }

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
				Duration = math.clamp(duration, 1, 30),
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
	local message = tostring(context) .. ": " .. tostring(err)
	if type(shared) == "table"
		and type(shared.BadDiagnostics) == "table"
		and type(shared.BadDiagnostics.RecordRuntime) == "function"
	then
		pcall(shared.BadDiagnostics.RecordRuntime, shared.BadDiagnostics, "WindUI.Adapter", message, {
			subsystem = "WindUIAdapter",
			stage = "callback",
			traceback = tostring(err),
		})
	end
	d:CreateNotification("Module Error", message, 7, "error")
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
	option.Step = math.max(tonumber(firstNonNil(settings.Step, settings.Increment, settings.Round, 1)) or 1, 0.000001)
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
			local corrected = math.min(tonumber(value) or option.ValueMin, option.ValueMax)
			option.ValueMin = corrected
			if corrected ~= value then
				setting = true
				setControlValue(minControl, corrected)
				setting = false
			end
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
			local corrected = math.max(tonumber(value) or option.ValueMax, option.ValueMin)
			option.ValueMax = corrected
			if corrected ~= value then
				setting = true
				setControlValue(maxControl, corrected)
				setting = false
			end
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
			if d.Modules[moduleName] == module then
				d.Modules[moduleName] = nil
			end
			if d.Overlays[moduleName] == module then
				d.Overlays[moduleName] = nil
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
				local span = maximum - minimum
				return span == 0 and 100 or ((option.Value - minimum) / span) * 100
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
		if type(d.SetUIScale) == "function" then
			d:SetUIScale(scale)
		else
			pcall(function() Window:SetUIScale(scale) end)
		end
		if uiScaleProgress and type(uiScaleProgress.Set) == "function" then
			pcall(uiScaleProgress.Set, uiScaleProgress, value)
		end
	end,
})

appearanceSection:Toggle({
	Title = "Compact Layout",
	Desc = "Use denser spacing on smaller displays",
	Value = false,
	Flag = "settings/compact_layout",
	Callback = function(value)
		if type(Window.SetCompactMode) == "function" then
			pcall(Window.SetCompactMode, Window, value == true)
		end
	end,
})

appearanceSection:Toggle({
	Title = "Reduced Motion",
	Desc = "Shorten animations without disabling feedback",
	Value = false,
	Flag = "settings/reduced_motion",
	Callback = function(value)
		d:SetReducedMotion(value == true)
	end,
})

appearanceSection:Toggle({
	Title = "Performance Mode",
	Desc = "Reduce expensive visual effects and animation duration",
	Value = false,
	Flag = "settings/performance_mode",
	Callback = function(value)
		d:SetPerformanceMode(value == true)
	end,
})

appearanceSection:Slider({
	Title = "Sidebar Width",
	Desc = "Adjust navigation width",
	Value = { Min = 120, Max = 260, Default = 180 },
	Step = 10,
	Flag = "settings/sidebar_width",
	Callback = function(value)
		if type(Window.SetSidebarWidth) == "function" then
			pcall(Window.SetSidebarWidth, Window, value)
		end
	end,
})

appearanceSection:Button({
	Title = "Repair Interface",
	Icon = "wrench",
	Desc = "Reflow sections, repair scroll canvases, and clear stale popups",
	Callback = function()
		local report = d:RepairUI()
		local fixed = type(report) == "table" and tonumber(report.Fixed) or 0
		d:CreateNotification("Interface", "Repair completed · " .. tostring(fixed or 0) .. " fix(es)", 4, "success")
	end,
})

appearanceSection:Button({
	Title = "Reset Layout",
	Icon = "rotate-ccw",
	Desc = "Restore the default scale, size, and position",
	Callback = function()
		d:ResetLayout()
		if uiScaleProgress and type(uiScaleProgress.Set) == "function" then
			pcall(uiScaleProgress.Set, uiScaleProgress, 94)
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

function d.CloseAllPopups()
	closeAllPopups()
	return true
end

function d.RefreshScrollCanvases()
	local roots = {
		WindUI.ScreenGui,
		WindUI.DropdownGui,
		WindUI.NotificationGui,
		WindUI.TooltipGui,
	}
	for _, root in ipairs(roots) do
		if typeof(root) == "Instance" then
			for _, descendant in ipairs(root:GetDescendants()) do
				if descendant:IsA("ScrollingFrame") then
					pcall(function()
						descendant.ElasticBehavior = Enum.ElasticBehavior.Never
						if descendant.ScrollingDirection ~= Enum.ScrollingDirection.X then
							descendant.ScrollBarThickness = 0
							descendant.ScrollBarImageTransparency = 1
						end
						local layout = descendant:FindFirstChildOfClass("UIListLayout")
							or descendant:FindFirstChildOfClass("UIGridLayout")
						if layout then
							local horizontal = layout:IsA("UIListLayout")
								and layout.FillDirection == Enum.FillDirection.Horizontal
							descendant.AutomaticCanvasSize = horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
						end
					end)
				end
			end
		end
	end
	if type(WindUI.RepairUI) == "function" then
		pcall(WindUI.RepairUI, WindUI)
	end
	return true
end

function d.RefreshLayout()
	if d.Destroyed then
		return false
	end
	d:CloseAllPopups()
	d:RefreshScrollCanvases()
	if type(Window.RefreshLayout) == "function" then
		pcall(Window.RefreshLayout, Window)
	end
	if type(Window.BringIntoView) == "function" then
		pcall(Window.BringIntoView, Window)
	end
	return true
end

function d.AuditUI(self, autoFix)
	if self ~= d then
		autoFix = self
	end
	local report
	if type(WindUI.AuditUI) == "function" then
		local ok, result = pcall(WindUI.AuditUI, WindUI, autoFix == true)
		if ok then report = result end
	elseif type(Window.Audit) == "function" then
		local ok, result = pcall(Window.Audit, Window, autoFix == true)
		if ok then report = result end
	end
	d.LastAudit = report
	return report
end

function d.RepairUI()
	d:CloseAllPopups()
	local report
	if type(WindUI.RepairUI) == "function" then
		local ok, result = pcall(WindUI.RepairUI, WindUI)
		if ok then report = result end
	else
		report = d:AuditUI(true)
	end
	d:RefreshLayout()
	d.LastAudit = report
	return report
end

function d.SetUIScale(self, scale)
	if self ~= d then scale = self end
	scale = math.clamp(tonumber(scale) or 0.94, 0.65, 1.25)
	if type(Window.SetUIScale) == "function" then
		pcall(Window.SetUIScale, Window, scale)
	elseif type(WindUI.SetUIScale) == "function" then
		pcall(WindUI.SetUIScale, WindUI, scale)
	end
	return scale
end

function d.SetReducedMotion(self, enabled)
	if self ~= d then enabled = self end
	if type(WindUI.SetReducedMotion) == "function" then
		pcall(WindUI.SetReducedMotion, WindUI, enabled == true)
	elseif type(WindUI.SetMotionScale) == "function" then
		pcall(WindUI.SetMotionScale, WindUI, enabled and 0.35 or 0.9)
	end
	return d
end

function d.SetPerformanceMode(self, enabled)
	if self ~= d then enabled = self end
	if type(WindUI.SetPerformanceMode) == "function" then
		pcall(WindUI.SetPerformanceMode, WindUI, enabled == true)
	end
	return d
end

function d.ResetLayout()
	d:CloseAllPopups()
	if type(Window.ResetLayout) == "function" then
		pcall(Window.ResetLayout, Window)
	elseif type(WindUI.ResetLayout) == "function" then
		pcall(WindUI.ResetLayout, WindUI)
	end
	d:SetUIScale(0.94)
	return d:RefreshLayout()
end

function d.WaitForModuleReadiness(self, timeout)
	if self ~= d then timeout = self end
	if d.Destroyed then return false end
	if d.Ready or timeout == nil then
		return not d.Destroyed
	end
	local deadline = os.clock() + math.max(tonumber(timeout) or 0, 0)
	repeat
		task.wait(0.05)
	until d.Ready or d.Destroyed or os.clock() >= deadline
	return d.Ready and not d.Destroyed
end

function d.FinalizeInitialLayout()
	if d.Destroyed then return false end
	d.BootState = "finalizing"
	d:RefreshLayout()
	d:AuditUI(true)
	d.Ready = true
	d.BootState = "ready"
	return true
end

-- ── Show / Hide / Toggle / Uninject ───
local firstLoadDone = false

function d.Show(self)
	if self ~= d then return d:Show() end
	if d.Destroyed then return false end

	bootstrapHidden = false
	setCompatibilityRootVisible(true)
	setBootstrapHidden(false)
	d.Visible = true

	if type(WindUI.SetVisible) == "function" then
		pcall(WindUI.SetVisible, WindUI, true)
	elseif type(Window.Open) == "function" then
		pcall(Window.Open, Window)
	elseif type(Window.Show) == "function" then
		pcall(Window.Show, Window)
	end

	task.defer(function()
		if d.Visible and not d.Destroyed then
			d:RefreshLayout()
		end
	end)

	if not firstLoadDone then
		firstLoadDone = true
		d:CreateNotification("BadWars", "Interface ready · RightShift toggles the window", 4, "success")
	end
	return true
end

function d.Hide(self)
	if self ~= d then return d:Hide() end
	if d.Destroyed then return false end

	d.Visible = false
	d:CloseAllPopups()
	if type(WindUI.SetVisible) == "function" then
		pcall(WindUI.SetVisible, WindUI, false)
	elseif type(Window.Close) == "function" then
		pcall(Window.Close, Window)
	elseif type(Window.Hide) == "function" then
		pcall(Window.Hide, Window)
	end
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

	d:CloseAllPopups()
	WindUI.__V8MaintenanceToken = nil
	WindUI.__V7MaintenanceToken = nil

	pcall(function()
		if type(Window.Destroy) == "function" then
			Window:Destroy()
		elseif type(WindUI.Destroy) == "function" then
			WindUI:Destroy()
		end
	end)

	pcall(function()
		if type(WindUI.DisconnectGlobalSignals) == "function" then
			WindUI:DisconnectGlobalSignals()
		end
	end)

	for _, root in ipairs({
		WindUI.ScreenGui,
		WindUI.NotificationGui,
		WindUI.DropdownGui,
		WindUI.TooltipGui,
	}) do
		if typeof(root) == "Instance" and root.Parent then
			pcall(root.Destroy, root)
		end
	end

	table.clear(d.Modules)
	table.clear(d.Overlays)
	table.clear(d.Categories)
	d.Ready = false
	d.BootState = "destroyed"

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
	shared.BadWindUI = WindUI
	shared.BadWindUIAdapter = d
	if shared.Bad == nil then
		shared.Bad = d
	elseif type(shared.Bad) == "table" then
		shared.Bad.CreateNotification = function(...)
			return d:CreateNotification(...)
		end
		shared.Bad.GUI = d
		shared.Bad.WindUI = WindUI
	end
end

task.defer(function()
	if not d.Destroyed then
		d:FinalizeInitialLayout()
	end
end)

return d
