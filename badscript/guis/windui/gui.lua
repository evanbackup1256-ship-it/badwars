-- BADWARS_WINDUI_INTEGRATION-- WindUI adapter with centralized legacy compatibility layer.

local cloneref = cloneref or clonereference or function(value)return valueend

local HttpService = cloneref(game("HttpService"))

local d = {Categories = {},Modules = {},Overlays = {},Libraries = {},Profiles = {},Connections = {},Resources = {},GUIColor = { Hue = 0.02, Sat = 0.95, Value = 0.98 },Version = "WindUI-Adapter-2.1",PremiumBuild = false,Name = "BadWars-WindUI",Visible = false,Destroyed = false,}

local function pack(...)return { n = select("#", ...), ... }end

local function unpackPacked(values)return table.unpack(values, 1, values.n)end

local function safeCall(callback, ...)if type(callback) ~= "function" thenreturn trueendlocal args = pack(...)return xpcall(function()return callback(unpackPacked(args))end, function(message)return debug.traceback(tostring(message), 2)end)end

local function firstNonNil(...)for index = 1, select("#", ...) dolocal value = select(index, ...)if value ~= nil thenreturn valueendendreturn nilend

local function shallowCopy(source)local result = {}if type(source) == "table" thenfor key, value in pairs(source) doresult[key] = valueendendreturn resultend

local function cloneValue(value, seen)if type(value) ~= "table" thenreturn valueendseen = seen or {}if seen[value] thenreturn seen[value]endlocal result = {}seen[value] = resultfor key, item in pairs(value) doresult[cloneValue(key, seen)] = cloneValue(item, seen)endreturn resultend

local function valuesEqual(left, right, seen)if left == right thenreturn trueendif type(left) ~= type(right) or type(left) ~= "table" thenreturn falseendseen = seen or {}seen[left] = seen[left] or {}if seen[left][right] thenreturn trueendseen[left][right] = truefor key, value in pairs(left) doif not valuesEqual(value, right[key], seen) thenreturn falseendendfor key in pairs(right) doif left[key] == nil thenreturn falseendendreturn trueend

local function sanitizeName(value)value = tostring(value or "unnamed")value = value("[^%w%-%./]", "")value = value("+", "")return value(1, 120)end

local function normalizeDescription(settings)return firstNonNil(settings.Desc, settings.Description, settings.Tooltip, "")end

local function normalizeKey(value)if typeof(value) == "EnumItem" thenreturn value.Nameendreturn tostring(value or "F")end

local function normalizeColor(value)if typeof(value) == "Color3" thenreturn valueendif type(value) == "string" thenlocal cleaned = value("#", "")local ok, color = pcall(Color3.fromHex, cleaned)if ok thenreturn colorendendif type(value) == "table" thenlocal hue = firstNonNil(value.Hue, value.H, value.h, value[1])local sat = firstNonNil(value.Sat, value.Saturation, value.S, value.s, value[2])local val = firstNonNil(value.Value, value.Brightness, value.V, value.v, value[3])if type(hue) == "number" and type(sat) == "number" and type(val) == "number" thenreturn Color3.fromHSV(hue, sat, val)endlocal red = firstNonNil(value.R, value.r)local green = firstNonNil(value.G, value.g)local blue = firstNonNil(value.B, value.b)if type(red) == "number" and type(green) == "number" and type(blue) == "number" thenif red > 1 or green > 1 or blue > 1 thenreturn Color3.fromRGB(red, green, blue)endreturn Color3.new(red, green, blue)endendreturn Color3.fromRGB(255, 45, 74)end

local function isConnection(value)return typeof(value) == "RBXScriptConnection"or (type(value) == "table" and type(value.Disconnect) == "function")end

local function setObjectVisible(object, visible)if typeof(object) == "Instance" thenpcall(function()object.Visible = visibleend)endend

local function findWindowMain(window)if type(window) ~= "table" or type(window.UIElements) ~= "table" thenreturn nilendreturn window.UIElements.Mainend

local function forEachOpenButton(window, callback)if type(window) ~= "table" or type(window.UIElements) ~= "table" thenreturnendfor key, value in pairs(window.UIElements) dolocal keyText = tostring(key)()local valueName = typeof(value) == "Instance" and value.Name() or ""if keyText("open", 1, true) or valueName("open", 1, true) thencallback(value)endendif type(window.OpenButtonMain) == "table" thencallback(window.OpenButtonMain.Main)callback(window.OpenButtonMain.Button)endend

local function compileSource(source, chunkName)if type(loadstring) ~= "function" thenreturn nil, "loadstring is unavailable"endlocal compiled, compileError = loadstring(source, chunkName)if not compiled thenreturn nil, compileErrorendlocal ok, result = pcall(compiled)if not ok thenreturn nil, resultendreturn resultend

local function loadWindUI()local failures = {}local localPaths = {"badscript/guis/windui/WindUI.lua","badscript/guis/windui/WindUI_compat.lua",}

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

local WindUI = loadWindUI()if type(WindUI.CreateWindow) ~= "function" thenerror("WindUI loaded, but CreateWindow is missing")end

d.WindUI = WindUI

pcall(function()WindUI.TransparencyValue = 0.08WindUI("BadWars")end)

local Window = WindUI({Title = "BadWars",Author = "Runtime Loader",Icon = "swords",Folder = "BadWars",NewElements = true,HideSearchBar = false,ScrollBarEnabled = true,AutoScale = false,Resizable = true,Size = UDim2.new(0, 760, 0, 540),MinSize = Vector2.new(560, 380),MaxSize = Vector2.new(1000, 760),ToggleKey = Enum.KeyCode.RightShift,OpenButton = {Title = "BadWars",Enabled = true,Draggable = true,Scale = 0.55,Color = ColorSequence.new(Color3.fromHex("#FF2D4A"), Color3.fromHex("#FF6B35")),},Topbar = {Height = 50,ButtonsType = "Mac",},})

if type(Window) ~= "table" thenerror("WindUI failed to create the BadWars window")end

d.Window = Window

pcall(function()Window(0.94)end)

d.gui = typeof(WindUI.ScreenGui) == "Instance" and WindUI.ScreenGuior (typeof(findWindowMain(Window)) == "Instance" and findWindowMain(Window))or Window

local function setWindowHidden(hidden)local main = findWindowMain(Window)if typeof(main) == "Instance" thenpcall(function()main.Visible = not hiddenif main("CanvasGroup") thenmain.GroupTransparency = hidden and 1 or 0endend)endforEachOpenButton(Window, function(object)setObjectVisible(object, not hidden)end)end

setWindowHidden(true)

pcall(function()Window({Title = "v2.1",Icon = "badge-check",Color = Color3.fromHex("#FF2D4A"),Border = true,})end)

local Tabs = {}d.Tabs = Tabs

local tabMetadata = {General = { Icon = "home", Desc = "Quick actions and loader script" },Modules = { Icon = "list", Desc = "Module health and status" },Blatant = { Icon = "flame", Desc = "High-visibility modules" },Combat = { Icon = "sword", Desc = "Combat enhancements" },Render = { Icon = "eye", Desc = "Visuals and ESP" },Utility = { Icon = "wrench", Desc = "Automation tools" },World = { Icon = "globe", Desc = "Movement and world" },Minigames = { Icon = "gamepad-2", Desc = "Minigame modules" },Legit = { Icon = "user-check", Desc = "Legit modules" },Friends = { Icon = "users", Desc = "Friend settings" },Targets = { Icon = "crosshair", Desc = "Target config" },Notifications = { Icon = "bell", Desc = "Event history" },Settings = { Icon = "settings", Desc = "Appearance and profiles" },}

local function ensureTab(name, metadata)name = tostring(name or "Misc")if Tabs[name] thenreturn Tabs[name]endmetadata = metadata or tabMetadata[name] or {}local tab = Window({Title = name,Icon = metadata.Icon or "folder",Desc = metadata.Desc or (name .. " modules"),})Tabs[name] = tabreturn tabend

for _, name in ipairs({"General", "Modules", "Blatant", "Combat", "Render", "Utility", "World","Minigames", "Legit", "Friends", "Targets", "Notifications", "Settings",}) doensureTab(name)end

-- ─── Modules Tab ───Tabs.Modules({Title = "Module Browser",Desc = "Modules are grouped by category. Each module is sandboxed — failures are isolated and recorded.",})Tabs.Modules({Title = "Controls",Desc = "RightShift toggles the window. Options sync with legacy module objects and persist via profile flags.",})

local moduleHealthProgresslocal moduleHealthLabellocal modulesLoaded = 0local modulesTotal = 0

local function updateModuleHealth(ready, total)modulesLoaded = readymodulesTotal = totalif moduleHealthProgress and type(moduleHealthProgress.Set) == "function" thenlocal pct = total > 0 and math.floor((ready / total) * 100 + 0.5) or 0pcall(moduleHealthProgress.Set, moduleHealthProgress, pct)endif moduleHealthLabel and type(moduleHealthLabel.SetDesc) == "function" thenpcall(moduleHealthLabel.SetDesc, moduleHealthLabel, string.format("%d / %d modules loaded", ready, total))endend

moduleHealthProgress = Tabs.Modules({Title = "Module Health",Desc = "Real-time loading progress",Value = { Min = 0, Max = 100, Default = 0 },DisplayMode = "Percent",Animate = true,})

moduleHealthLabel = Tabs.Modules({Title = "Status",Desc = "Waiting for modules to load...",})

-- Real-time module trackingtask.spawn(function()local lastCount = 0while not d.Destroyed dotask.wait(0.5)

	-- Count registered modules
	local currentCount = 0
	for _ in pairs(d.Modules) do
		currentCount += 1
	end
	
	-- Update if changed
	if currentCount ~= lastCount then
		lastCount = currentCount
		-- Estimate total (universal + game modules, typically 70-100)
		local estimatedTotal = math.max(currentCount, 70)
		updateModuleHealth(currentCount, estimatedTotal)
	end
	
	-- Stop if we've loaded a reasonable amount
	if currentCount >= 50 then
		task.wait(2)
		-- Final update with actual health data
		local B = shared.Bad
		if B and type(B.GetBedWarsModuleHealth) == "function" then
			local report = B:GetBedWarsModuleHealth()
			if type(report) == "table" and report.Total and report.Total > 0 then
				updateModuleHealth(report.Ready or 0, report.Total)
				return
			end
		end
		return
	end
end

end)

-- ─── Notifications Tab ───local notificationLog = {}local MAX_NOTIFICATION_LOG = 60local notificationsEnabled = truelocal notificationParagraph

local function formatNotificationLog()local lines = {}for index = 1, math.min(#notificationLog, 20) dolocal entry = notificationLog[index]lines[index] = string.format("[%s] %s — %s", entry.time, entry.title, entry.text)endreturn #lines > 0 and table.concat(lines, "\n") or "No notifications yet."end

local function refreshNotificationTab()local content = formatNotificationLog()if notificationParagraph thenlocal ok = pcall(function()if type(notificationParagraph.SetDesc) == "function" thennotificationParagraph(content)elseif type(notificationParagraph.Set) == "function" thennotificationParagraph(content)endend)if ok thenreturnend-- Old paragraph is broken, destroy it and recreatepcall(function()if type(notificationParagraph.Destroy) == "function" thennotificationParagraph()endend)notificationParagraph = nilendnotificationParagraph = Tabs.Notifications({Title = "Event Log",Desc = content,})end

local function normalizeNotificationArguments(self, title, text, duration, notificationType)if self ~= d thennotificationType = durationduration = texttext = titletitle = selfendreturn tostring(title or "BadWars"), tostring(text or ""), tonumber(duration) or 5, tostring(notificationType or "info")end

function d.CreateNotification(self, title, text, duration, notificationType)title, text, duration, notificationType = normalizeNotificationArguments(self, title, text, duration, notificationType)local entry = {time = os.date("%X"),title = title,text = text,type = notificationType,}table.insert(notificationLog, 1, entry)if #notificationLog > MAX_NOTIFICATION_LOG thentable.remove(notificationLog)endrefreshNotificationTab()

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

function d.PushNotification(title, text, notificationType)return d(title, text, 5, notificationType)end

Tabs.Notifications({Title = "Notification System",Desc = "Toasts and the persistent event log share one notification pipeline.",})Tabs.Notifications({Title = "Clear Notifications",Icon = "trash",Callback = function()table.clear(notificationLog)refreshNotificationTab()end,})Tabs.Notifications({Title = "Show Toast Notifications",Value = true,Flag = "settings/notifications_enabled",Callback = function(value)notificationsEnabled = value == trueend,})Tabs.Notifications()refreshNotificationTab()

-- ─── Core helpers ───local function reportCallbackError(context, err)d("Module Error", tostring(context) .. ": " .. tostring(err), 7, "error")end

local function runUserCallback(context, callback, ...)local ok, result = safeCall(callback, ...)if not ok thenreportCallbackError(context, result)endreturn ok, resultend

local function setControlValue(control, value, ...)if type(control) ~= "table" thenreturn falseendlocal args = pack(...)local candidates = { "SetValue", "SetState", "Set", "Select", "Update" }for _, methodName in ipairs(candidates) dolocal method = control[methodName]if type(method) == "function" thenlocal ok = pcall(function()method(control, value, unpackPacked(args))end)if ok thenreturn trueendendendreturn falseend

local function setControlVisible(control, visible)if type(control) ~= "table" thenreturnendif type(control.SetVisible) == "function" thenpcall(control.SetVisible, control, visible)returnendlocal target = control.ElementFrameif typeof(target) ~= "Instance" and type(control.UIElements) == "table" thentarget = control.UIElements.MainendsetObjectVisible(target, visible)end

local function destroyControl(control)if type(control) == "table" and type(control.Destroy) == "function" thenpcall(control.Destroy, control)endend

-- ─── Option API ───local function makeOptionApi(spec)spec = spec or {}local api = {Name = tostring(spec.Name or "Option"),Type = tostring(spec.Type or "Option"),Value = cloneValue(spec.Value),Default = cloneValue(spec.Value),Object = nil,Enabled = spec.Type == "Toggle" and spec.Value == true or nil,Visible = true,Destroyed = false,}local callback = spec.Callbacklocal callbackOnSet = spec.CallbackOnSet ~= false

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

local function enableDotAndColon(object, methodName)local original = object[methodName]if type(original) ~= "function" thenreturnendobject[methodName] = function(first, ...)if first == object thenreturn original(object, ...)endreturn original(object, first, ...)endend

local function registerOption(module, name, option)local baseName = tostring(name or option.Name or option.Type)local uniqueName = baseNamelocal suffix = 2while module.Options[uniqueName] and module.Options[uniqueName] ~= option douniqueName = baseName .. " " .. suffixsuffix += 1endoption.Name = uniqueNamemodule.Options[uniqueName] = optionreturn optionend

local function makeFlag(categoryName, moduleName, optionName)return sanitizeName(string.format("%s/%s/%s", categoryName, moduleName, optionName))end

local function resolveFlag(module, settings, optionName)if module.NoSave or settings.NoSave thenreturn nilendreturn settings.Flag or makeFlag(module.Category, module.Name, optionName)end

-- ─── Control creators ───local function createToggleOption(module, section, settings)settings = settings or {}local initial = firstNonNil(settings.Default, settings.Value, settings.Enabled, false) == truelocal option = makeOptionApi({Name = settings.Name or "Toggle",Type = "Toggle",Value = initial,Callback = settings.Function or settings.Callback,})option.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Value = initial,Flag = resolveFlag(module, settings, option.Name),Callback = function(value)option:_FromControl(value == true)end,})return registerOption(module, option.Name, option)end

local function createSliderOption(module, section, settings)settings = settings or {}local minimum = tonumber(firstNonNil(settings.Min, settings.MinValue, settings.Minimum, 0)) or 0local maximum = tonumber(firstNonNil(settings.Max, settings.MaxValue, settings.Maximum, 100)) or 100if maximum < minimum thenminimum, maximum = maximum, minimumendlocal initial = tonumber(firstNonNil(settings.Default, settings.Value, settings.Current, minimum)) or minimuminitial = math.clamp(initial, minimum, maximum)local option = makeOptionApi({Name = settings.Name or "Slider",Type = "Slider",Value = initial,Callback = settings.Function or settings.Callback,})option.Min = minimumoption.Max = maximumoption.Step = tonumber(firstNonNil(settings.Step, settings.Increment, settings.Round, 1)) or 1option.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Value = { Min = minimum, Max = maximum, Default = initial },Step = option.Step,Flag = resolveFlag(module, settings, option.Name),Callback = function(value)option:_FromControl(value)end,})function option(value)value = tonumber(value) or option.Minoption.Min = valueif type(option.Object) == "table" and type(option.Object.SetMin) == "function" thenpcall(option.Object.SetMin, option.Object, value)endreturn optionendfunction option(value)value = tonumber(value) or option.Maxoption.Max = valueif type(option.Object) == "table" and type(option.Object.SetMax) == "function" thenpcall(option.Object.SetMax, option.Object, value)endreturn optionendreturn registerOption(module, option.Name, option)end

local function createDropdownOption(module, section, settings)settings = settings or {}local values = shallowCopy(firstNonNil(settings.List, settings.Values, settings.Options, {}))local multi = firstNonNil(settings.Multi, settings.Multiple, settings.Multiselect, false) == truelocal initial = firstNonNil(settings.Default, settings.Value, settings.Selected)if initial == nil theninitial = multi and {} or values[1]endlocal option = makeOptionApi({Name = settings.Name or "Dropdown",Type = "Dropdown",Value = initial,Callback = settings.Function or settings.Callback,})option.List = valuesoption.Values = valuesoption.Multi = multioption.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Values = values,Value = initial,Multi = multi,AllowNone = settings.AllowNone,SearchBarEnabled = firstNonNil(settings.Search, settings.Searchable, settings.SearchBarEnabled, false),Flag = resolveFlag(module, settings, option.Name),Callback = function(value)option:_FromControl(value)end,})function option(newValues, selected, silent)newValues = type(newValues) == "table" and shallowCopy(newValues) or {}option.List = newValuesoption.Values = newValuesif type(option.Object) == "table" thenif type(option.Object.SetValues) == "function" thenpcall(option.Object.SetValues, option.Object, newValues, selected)elseif type(option.Object.Refresh) == "function" thenpcall(option.Object.Refresh, option.Object, newValues)endendif selected ~= nil thenoption(selected, silent)endreturn optionendoption.Refresh = option.SetListreturn registerOption(module, option.Name, option)end

local function createColorOption(module, section, settings, hsvCallback)settings = settings or {}local initialColor = normalizeColor(firstNonNil(settings.Default, settings.Value, settings.Color))local initialTransparency = tonumber(firstNonNil(settings.Transparency, settings.Opacity and (1 - settings.Opacity), 0)) or 0local hue, sat, val = initialColor()local option = makeOptionApi({Name = settings.Name or "Color",Type = hsvCallback and "ColorSlider" or "Colorpicker",Value = initialColor,Callback = nil,CallbackOnSet = false,})option.Hue = hueoption.Sat = satoption.Saturation = satoption.Brightness = valoption.Color = initialColoroption.Opacity = 1 - initialTransparencyoption.Transparency = initialTransparencylocal userCallback = settings.Function or settings.Callback

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

local function createKeybindOption(module, section, settings)settings = settings or {}local initial = normalizeKey(firstNonNil(settings.Default, settings.Value, settings.Key, "F"))local option = makeOptionApi({Name = settings.Name or "Keybind",Type = "Keybind",Value = initial,Callback = settings.Function or settings.Callback,CallbackOnSet = false,AlwaysCallback = true,})option.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Value = initial,CanChange = settings.CanChange ~= false,Blacklist = settings.Blacklist,Flag = resolveFlag(module, settings, option.Name),Callback = function(key)option.Value = normalizeKey(option.Object and option.Object.Value or key)runUserCallback(option.Name, settings.Function or settings.Callback, key)end,})-- Safe keybind label tracking — wrapped in deep pcall to survive WindUI structure changespcall(function()if type(option.Object) ~= "table" or type(option.Object.UIElements) ~= "table" thenreturnendlocal kb = option.Object.UIElements.Keybindif type(kb) ~= "table" or type(kb.Frame) ~= "table" thenreturnendlocal inner = kb.Frame.Frame or kb.Frameif type(inner) ~= "table" or typeof(inner.TextLabel) ~= "Instance" thenreturnendlocal label = inner.TextLabellocal connection = label("Text")(function()local text = tostring(label.Text or "")if text ~= "" and text ~= "..." thenoption.Value = normalizeKey(option.Object.Value or text)endend)table.insert(d.Resources, connection)end)function option(value, silent)option.Value = normalizeKey(value)setControlValue(option.Object, option.Value)if silent ~= true and settings.OnChanged thenrunUserCallback(option.Name .. " changed", settings.OnChanged, option.Value)endreturn optionendoption.Set = option.SetValuereturn registerOption(module, option.Name, option)end

local function createInputOption(module, section, settings)settings = settings or {}local initial = tostring(firstNonNil(settings.Default, settings.Value, settings.Text, ""))local option = makeOptionApi({Name = settings.Name or "Input",Type = "Input",Value = initial,Callback = settings.Function or settings.Callback,})option.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Value = initial,Placeholder = firstNonNil(settings.Placeholder, settings.PlaceholderText, "Enter text..."),ClearTextOnFocus = settings.ClearTextOnFocus,Type = settings.Type,Flag = resolveFlag(module, settings, option.Name),Callback = function(value)option:_FromControl(value)end,})return registerOption(module, option.Name, option)end

local function createTwoSliderOption(module, section, settings)settings = settings or {}local minimum = tonumber(firstNonNil(settings.Min, settings.MinValue, 0)) or 0local maximum = tonumber(firstNonNil(settings.Max, settings.MaxValue, 100)) or 100if maximum < minimum thenminimum, maximum = maximum, minimumendlocal initialMin = math.clamp(tonumber(firstNonNil(settings.DefaultMin, settings.ValueMin, minimum)) or minimum, minimum, maximum)local initialMax = math.clamp(tonumber(firstNonNil(settings.DefaultMax, settings.ValueMax, maximum)) or maximum, minimum, maximum)if initialMax < initialMin theninitialMin, initialMax = initialMax, initialMinendlocal option = {Name = tostring(settings.Name or "Range"),Type = "TwoSlider",ValueMin = initialMin,ValueMax = initialMax,Min = minimum,Max = maximum,Visible = true,Destroyed = false,}local userCallback = settings.Function or settings.Callbacklocal setting = falselocal minControllocal maxControl

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

local function createTextListOption(module, section, settings)settings = settings or {}local initial = cloneValue(firstNonNil(settings.Default, settings.Value, settings.List, {}))if type(initial) ~= "table" theninitial = {}endlocal option = makeOptionApi({Name = settings.Name or "Text List",Type = "TextList",Value = initial,Callback = settings.Function or settings.Callback,CallbackOnSet = false,})option.List = option.Valueoption.ObjectList = option.Valueoption.Object = section({Title = option.Name,Desc = normalizeDescription(settings),Placeholder = firstNonNil(settings.Placeholder, "Enter text and press Enter"),Value = "",Callback = function(value)value = tostring(value or "")if value ~= "" thenoption(value)setControlValue(option.Object, "")endend,})

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

local function createFontOption(module, section, settings)settings = settings or {}local fonts = firstNonNil(settings.List, settings.Values, {"Gotham", "Arial", "SourceSans", "Roboto", "Ubuntu", "Fantasy", "Code", "Highway",})settings.List = fontssettings.Default = firstNonNil(settings.Default, settings.Value, fonts[1])return createDropdownOption(module, section, settings)end

local function createTargetsOption(module, section, settings)settings = settings or {}local labels = {}local defaults = {}local function addTarget(label, enabled)table.insert(labels, label)defaults[label] = enabled ~= falseendif settings.Players ~= false then addTarget("Players", settings.Players) endif settings.NPCs or settings.NPC then addTarget("NPCs", true) endif settings.Friends ~= false then addTarget("Friends", settings.Friends) endif settings.Walls ~= nil then addTarget("Walls", settings.Walls) endif #labels == 0 thenaddTarget("Players", true)addTarget("NPCs", true)addTarget("Friends", true)endlocal selected = {}for _, label in ipairs(labels) doif defaults[label] then table.insert(selected, label) endendlocal option = {Name = tostring(settings.Name or "Targets"),Type = "Targets",Value = defaults,Visible = true,Destroyed = false,}for label, enabled in pairs(defaults) dooption[label] = enabledendlocal userCallback = settings.Function or settings.Callback

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

-- ─── Category system ───local categoryIcons = {Combat = "sword",Blatant = "flame",Render = "eye",Utility = "wrench",World = "globe",Minigames = "gamepad-2",Legit = "user-check",Friends = "users",Targets = "crosshair",}

local function createCategoryObject(name, iconName, suppliedTab)name = tostring(name or "Misc")if d.Categories[name] and d.Categories[name].Type ~= "ServiceCategory" thenreturn d.Categories[name]endlocal tab = suppliedTab or ensureTab(name, { Icon = iconName or categoryIcons[name] or "folder" })local category = {Name = name,Type = "Category",Tab = tab,Modules = {},Options = {},}

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

function d.CreateCategory(self, config)if self ~= d thenconfig = selfendconfig = type(config) == "table" and config or { Name = config }return createCategoryObject(config.Name or "Misc", config.Icon)end

for _, categoryName in ipairs({ "Combat", "Blatant", "Render", "Utility", "World", "Minigames", "Legit", "Friends", "Targets" }) docreateCategoryObject(categoryName, categoryIcons[categoryName])end

d.Legit = d.Categories.Legit

function d.CreateOverlay(self, settings)if self ~= d then settings = self endsettings = settings or {}local name = tostring(settings.Name or "Overlay")if d.Overlays[name] thenreturn d.Overlays[name]endlocal overlay = d.Categories.Render(settings)d.Overlays[name] = overlayreturn overlayend

-- ─── Main category (legacy compat) ───local mainCategory = {Type = "ServiceCategory",Name = "Main",Options = {},Modules = {},}d.Categories.Main = mainCategory

local function createMainToggle(name, default, callback)local option = makeOptionApi({ Name = name, Type = "Toggle", Value = default, Callback = callback })option.Object = Tabs.General({Title = name,Value = default,Flag = sanitizeName("main/" .. name),Callback = function(value)option:_FromControl(value == true)end,})-- Store under BOTH keys so legacy code finds it regardless of casingmainCategory.Options[name] = optionmainCategory.Options[string.lower(name)] = optionreturn optionend

-- Legacy keys: main.lua references "GUI bind indicator" (lowercase b, i)mainCategory.Options["GUI bind indicator"] = createMainToggle("GUI Bind Indicator", true)mainCategory.Options["Teams by server"] = createMainToggle("Teams by server", false)mainCategory.Options["Use team color"] = createMainToggle("Use team color", true)

function mainCategory(settings)settings = settings or {}return Tabs.General({Title = settings.Name or "Action",Desc = normalizeDescription(settings),Icon = settings.Icon,Callback = function()runUserCallback(settings.Name or "Main action", settings.Function or settings.Callback)end,})end

function mainCategory(settings)settings = settings or {}local name = tostring(settings.Name or "Option")if mainCategory.Options[name] thenreturn mainCategory.Options[name]endlocal option = createMainToggle(name, firstNonNil(settings.Default, settings.Value, false) == true, settings.Function or settings.Callback)mainCategory.Options[name] = optionreturn optionend

-- ─── General Tab ───Tabs.General({Title = "BadWars v2.1",Desc = "Runtime loader for Roblox. RightShift to toggle.",})

Tabs.General()

Tabs.General({Title = "Loader Script",Code = 'loadstring(game("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()',CanCopied = true,})

Tabs.General()

-- Quick actions sectionlocal quickActionsSection = Tabs.General({Title = "Quick Actions",Opened = true,Box = true,})

quickActionsSection({Title = "Copy Loader",Icon = "copy",Desc = "Copy loader to clipboard",Callback = function()local loader = 'loadstring(game("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()'pcall(function()if type(setclipboard) == "function" then setclipboard(loader)elseif type(toclipboard) == "function" then toclipboard(loader) endend)d("BadWars", "Loader copied", 3, "success")end,})

quickActionsSection({Title = "Uninject",Icon = "x",Desc = "Remove all modules and close",Callback = function()local dialog = Window({Title = "Uninject BadWars?",Content = "This will remove all modules and close the interface.",Buttons = {{ Title = "Cancel", Variant = "Secondary", Callback = function() end },{Title = "Uninject",Variant = "Primary",Callback = function()d("BadWars", "Uninjecting...", 2, "warning")task.defer(function() d() end)end,},},})if type(dialog) == "table" and type(dialog.Show) == "function" thendialog()endend,})

quickActionsSection({Title = "Reload",Icon = "refresh-cw",Desc = "Restart BadWars",Callback = function()d("BadWars", "Reloading...", 2, "info")shared.BadReload = truetask.defer(function()local ok, err = pcall(function()if shared.BadDeveloper and type(readfile) == "function" thenlocal source = readfile("badscript/loader.lua")assert(type(source) == "string", "loader.lua could not be read")assert(loadstring(source, "@badscript/loader.lua"))()elseassert(loadstring(game("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true), "@BadWarsLoader"))()endend)if not ok thend("Reload Error", tostring(err), 7, "error")endend)end,})

-- ─── Settings Tab ───local currentProfileName = "default"local function getConfigManager()return type(Window) == "table" and Window.ConfigManager or nilend

local function saveProfile(name)name = sanitizeName(name or currentProfileName)currentProfileName = nameif type(Window.SaveConfig) == "function" thenlocal ok, success, result = pcall(Window.SaveConfig, Window, name)if ok then return success ~= false, result endendlocal manager = getConfigManager()if not manager then return false, "Config manager unavailable" endlocal config = manager(name)if type(config) ~= "table" or type(config.Save) ~= "function" thenconfig = manager(name, true)endif not config then return false, "Unable to create profile" endconfig()return true, config()end

local function loadProfile(name)name = sanitizeName(name or currentProfileName)currentProfileName = nameif type(Window.LoadConfig) == "function" thenlocal ok, success, result = pcall(Window.LoadConfig, Window, name)if ok then return success ~= false, result endendlocal manager = getConfigManager()if not manager then return false, "Config manager unavailable" endlocal config = manager(name)if type(config) ~= "table" or type(config.Load) ~= "function" thenconfig = manager(name, true)endif not config then return false, "Unable to create profile" endconfig()return config()end

-- Appearance sectionlocal appearanceSection = Tabs.Settings({Title = "Appearance",Opened = true,Box = true,})

appearanceSection({Title = "UI Transparency",Desc = "Glass effect",Value = true,Flag = "settings/transparency",Callback = function(value)WindUI.TransparencyValue = value and 0.08 or 0pcall(function()if type(Window.ToggleTransparency) == "function" thenWindow(value)endend)end,})

-- UI Scale with progress indicatorlocal uiScaleProgress = appearanceSection({Title = "UI Scale",Desc = "Current scale",Value = { Min = 65, Max = 125, Default = 94 },DisplayMode = "Value",Format = function(value)return string.format("%.0f%%", value)end,Width = 200,Animate = true,})

appearanceSection({Title = "Adjust Scale",Value = { Min = 65, Max = 125, Default = 94 },Step = 5,Callback = function(value)local scale = value / 100pcall(function() Window(scale) end)if uiScaleProgress and type(uiScaleProgress.Set) == "function" thenpcall(uiScaleProgress.Set, uiScaleProgress, value)endend,})

-- Profile sectionlocal profileSection = Tabs.Settings({Title = "Profiles",Opened = true,Box = true,})

profileSection({Title = "Profile Name",Value = currentProfileName,Placeholder = "default",Callback = function(value)if tostring(value or "") ~= "" thencurrentProfileName = sanitizeName(value)endend,})

profileSection({Title = "Save Profile",Icon = "save",Desc = "Save current settings",Callback = function()local ok, result = saveProfile(currentProfileName)d("Profiles", ok and ("Saved '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")end,})

profileSection({Title = "Load Profile",Icon = "folder-open",Desc = "Load settings",Callback = function()local ok, result = loadProfile(currentProfileName)d("Profiles", ok and ("Loaded '" .. currentProfileName .. "'") or tostring(result), 4, ok and "success" or "error")end,})

profileSection({Title = "Reset Profile",Icon = "trash",Desc = "Delete saved settings",Callback = function()local dialog = Window({Title = "Reset Profile?",Content = "Clear all saved settings for '" .. currentProfileName .. "'.",Buttons = {{ Title = "Cancel", Variant = "Secondary", Callback = function() end },{Title = "Reset",Variant = "Primary",Callback = function()if type(readfile) == "function" and type(delfile) == "function" thenlocal configPath = "BadWars/" .. sanitizeName(currentProfileName) .. ".json"if isfile(configPath) thenpcall(delfile, configPath)d("Profiles", "Profile reset", 3, "success")elsed("Profiles", "No saved profile", 3, "warning")endendend,},},})if type(dialog) == "table" and type(dialog.Show) == "function" thendialog()endend,})

-- ─── API methods ───function d.Save(self, target)if self ~= d then target = self endreturn saveProfile(type(target) == "string" and target or currentProfileName)end

function d.Load(self, saved)if self ~= d then saved = self endreturn loadProfile(type(saved) == "string" and saved or currentProfileName)end

function d.Change()return dend

function d.Clean(self, resource)if self ~= d then resource = self endif resource ~= nil thentable.insert(d.Resources, resource)if isConnection(resource) thentable.insert(d.Connections, resource)endendreturn resourceend

function d.CreateDialog(self, settings)if self ~= d then settings = self endsettings = settings or {}local dialog = Window({Title = settings.Title or "Dialog",Icon = settings.Icon,IconThemed = settings.IconThemed,Content = settings.Content or settings.Desc or "",Buttons = settings.Buttons or {},})return dialogend

function d.CreatePopup(self, settings)if self ~= d then settings = self endsettings = settings or {}local popup = WindUI({Title = settings.Title or "Popup",Icon = settings.Icon,Content = settings.Content or settings.Desc or "",Buttons = settings.Buttons or {},})return popupend

function d.RefreshScrollCanvases()local roots = { WindUI.ScreenGui, WindUI.DropdownGui, WindUI.NotificationGui }for _, root in ipairs(roots) doif typeof(root) == "Instance" thenfor _, descendant in ipairs(root()) doif descendant("ScrollingFrame") thenpcall(function()if descendant.AutomaticCanvasSize == Enum.AutomaticSize.None thendescendant.AutomaticCanvasSize = Enum.AutomaticSize.Yendend)endendendendreturn trueend

function d.WaitForModuleReadiness()return not d.Destroyedend

function d.FinalizeInitialLayout()d()return trueend

-- ── Show / Hide / Toggle / Uninject ───local firstLoadDone = false

function d.Show(self)if self ~= d then return d() endif d.Destroyed then return false endd.Visible = true

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

function d.Hide(self)if self ~= d then return d() endif d.Destroyed then return false endd.Visible = falsepcall(function()if type(Window.Close) == "function" then Window() endend)pcall(function()if type(Window.Hide) == "function" then Window() endend)setWindowHidden(true)return trueend

function d.Toggle(self)if self ~= d then return d() endif d.Visible then return d() endreturn d()end

function d.Uninject(self)if self ~= d then return d() endif d.Destroyed then return false endd.Destroyed = trued.Visible = false

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

-- ─── Shared registration ───if shared thenshared.BadGUI = dif shared.Bad == nil thenshared.Bad = delseif type(shared.Bad) == "table" thenshared.Bad.CreateNotification = function(...)return d(...)endshared.Bad.GUI = dendend

return d
