-- BADWARS_WINDUI_INTEGRATION
-- Modern WindUI powered GUI adapter for seamless integration with BadWars modules.
-- Tabs: General, Blatant, Combat, Render, Utility, World, Minigames, Legit, Notifications, Settings
-- Full compatibility for CreateModule + CreateToggle / Dropdown / Slider / Color / Keybind / Targets etc.
-- Notifications, dropdowns, and state fully synced with backend modules + profiles.

local cloneref = cloneref or function(x) return x end

local WindUI
do
	local success, result = pcall(function()
		-- Prefer local bundled when available (via readfile in exploit env)
		if type(readfile) == "function" and type(isfile) == "function" then
			local p = "badscript/guis/windui/WindUI.lua"
			if isfile(p) then
				local src = readfile(p)
				if src and #src > 10000 then
					return loadstring(src, "WindUI")()
				end
			end
		end
		-- Fallback to GitHub dist (for first run / no filesystem)
		local urls = {
			"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
			"https://github.com/Footagesus/WindUI/raw/main/dist/main.lua",
		}
		for _, url in ipairs(urls) do
			local ok, body = pcall(function()
				if game and game.HttpGet then
					return game:HttpGet(url, true)
				end
				return game:GetService("HttpService"):GetAsync(url, true)
			end)
			if ok and body and #body > 10000 then
				return loadstring(body, "WindUI")()
			end
		end
		error("Failed to load WindUI")
	end)
	WindUI = result
end

if not WindUI or type(WindUI.CreateWindow) ~= "function" then
	error("WindUI failed to initialize")
end

-- Branding + theme
WindUI.TransparencyValue = 0.08
WindUI:SetTheme("Dark")

-- spr for custom heavy animations (loaded by main)
local spr = shared.BadWarsSpr

local Window = WindUI:CreateWindow({
	Title = "BadWars",
	Author = "Premium • Roblox",
	Icon = "swords", -- lucide icon or "target"
	Folder = "BadWars",
	NewElements = true,
	HideSearchBar = false,
	ToggleKey = Enum.KeyCode.RightShift, -- common for these UIs, changeable in Settings later
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

-- Do NOT show the main control center until the loader has fully finished (modules registered, etc.)
pcall(function()
	if Window.Close then
		Window:Close()
	elseif Window.Toggle then
		Window:Toggle()
	end
end)

-- Extra hide to ensure UI does not appear until loader calls Show()
pcall(function()
	if Window and Window.UIElements and Window.UIElements.Main then
		Window.UIElements.Main.Visible = false
		Window.UIElements.Main.GroupTransparency = 1
	end
	-- Try to hide OpenButton if present
	if Window and Window.UIElements then
		for k, v in pairs(Window.UIElements) do
			if v and typeof(v) == "Instance" and (k:lower():find("open") or (v.Name or ""):lower():find("open")) then
				v.Visible = false
			end
		end
	end
end)

-- Additional safety: many modules expect certain top level options to exist immediately
pcall(function()
	d.Categories = d.Categories or {}
	d.Modules = d.Modules or {}
end)

-- Add version tag
pcall(function()
	Window:Tag({
		Title = "v2 • WindUI",
		Icon = "badge-check",
		Color = Color3.fromHex("#22c55e"),
		Border = true,
	})
end)

-- Tabs definition (matches user request + common categories)
local Tabs = {}

Tabs.General = Window:Tab({ Title = "General", Icon = "home", Desc = "Core settings & quick actions" })
Tabs.Modules = Window:Tab({ Title = "Modules", Icon = "list", Desc = "All modules at a glance (search + toggle)" })
Tabs.Modules:Paragraph({
	Title = "Module Browser",
	Content = "Use the top search bar or jump to the category tabs (Blatant / Combat / Render / etc). All toggles, dropdowns and options are live-synced. Sections group options per module for clarity.",
})
Tabs.Modules:Space()
Tabs.Modules:Paragraph({
	Title = "Tips",
	Content = "Toggle modules on/off. Use keybinds, dropdowns for modes, sliders for values. Changes sync instantly to the script logic. Config saves via WindUI (Folder=BadWars).",
})
Tabs.Modules:Button({
	Title = "Jump to Blatant (see sidebar tabs)",
	Callback = function()
		pcall(function() WindUI:Notify({ Title = "BadWars", Content = "Use the left sidebar or top tabs to switch to Blatant", Duration = 3 }) end)
	end,
})
Tabs.Modules:Button({
	Title = "Jump to Render",
	Callback = function()
		pcall(function() WindUI:Notify({ Title = "BadWars", Content = "Use the left sidebar or top tabs to switch to Render", Duration = 3 }) end)
	end,
})
Tabs.Blatant = Window:Tab({ Title = "Blatant", Icon = "flame", Desc = "High visibility / strong modules" })
Tabs.Combat = Window:Tab({ Title = "Combat", Icon = "sword", Desc = "PvP tools" })
Tabs.Render = Window:Tab({ Title = "Render", Icon = "eye", Desc = "Visuals & ESP" })
Tabs.Utility = Window:Tab({ Title = "Utility", Icon = "wrench", Desc = "Helpers & automation" })
Tabs.World = Window:Tab({ Title = "World", Icon = "globe", Desc = "Environment & movement" })
Tabs.Minigames = Window:Tab({ Title = "Minigames", Icon = "gamepad-2", Desc = "Minigame specific" })
Tabs.Legit = Window:Tab({ Title = "Legit", Icon = "user-check", Desc = "Semi-legit features" })
Tabs.Notifications = Window:Tab({ Title = "Notifications", Icon = "bell", Desc = "Event log & alerts" })
Tabs.Settings = Window:Tab({ Title = "Settings", Icon = "settings", Desc = "UI & profile management" })

-- Ensure all expected category tabs exist early (for dynamic module registration)
for _, catName in ipairs({"Combat", "Blatant", "Render", "Utility", "World", "Minigames", "Legit", "Friends", "Targets"}) do
	if not Tabs[catName] then
		Tabs[catName] = Window:Tab({ Title = catName, Icon = "folder", Desc = catName .. " modules" })
	end
end

-- Internal state
local d = {} -- the returned API object, mirrors old gui API
d.Categories = {}
d.Modules = {}
d.Overlays = {}
d.Libraries = {}
d.Profiles = {}
d.Connections = {}
d.GUIColor = { Hue = 0.02, Sat = 0.95, Value = 0.98 } -- red-ish accent matching BadWars

local notificationLog = {}
local MAX_NOTIF_LOG = 60
local notifParagraph

-- Helper to refresh notifications tab content (define BEFORE CreateNotification to avoid nil upvalue issues)
local function refreshNotifTab()
	if not Tabs.Notifications then return end
	local lines = {}
	for i = 1, math.min(#notificationLog, 20) do
		local n = notificationLog[i]
		table.insert(lines, string.format("[%s] %s — %s", n.time, n.title, n.text))
	end
	local content = table.concat(lines, "\n")
	if notifParagraph then
		pcall(function()
			if notifParagraph.SetDesc then
				notifParagraph:SetDesc(content ~= "" and content or "Notifications stream here and as beautiful WindUI toasts.")
			elseif notifParagraph.Set then
				notifParagraph:Set({ Content = content ~= "" and content or "Notifications stream here and as beautiful WindUI toasts." })
			end
		end)
	else
		notifParagraph = Tabs.Notifications:Paragraph({
			Title = "Event Log",
			Desc = content ~= "" and content or "Notifications stream here and as beautiful WindUI toasts.",
		})
	end
end

-- Notification integration (seamless with WindUI + tab log)
function d:CreateNotification(title, text, duration, ntype)
	title = tostring(title or "BadWars")
	text = tostring(text or "")
	duration = tonumber(duration) or 5
	ntype = ntype or "info"

	-- Native WindUI toast - beautiful and reliable
	local iconMap = {
		info = "info",
		warning = "alert-triangle",
		error = "x-octagon",
		success = "check-circle",
	}
	pcall(function()
		if WindUI and WindUI.Notify then
			WindUI:Notify({
				Title = title,
				Content = text,
				Icon = iconMap[ntype] or "bell",
				Duration = duration,
			})
		end
	end)

	-- Also log into the Notifications tab for history / sync
	local entry = {
		time = os.date("%X"),
		title = title,
		text = text,
		type = ntype,
	}
	table.insert(notificationLog, 1, entry)
	if #notificationLog > MAX_NOTIF_LOG then
		table.remove(notificationLog)
	end

	refreshNotifTab()

	return entry
end

d.CreateNotification = d.CreateNotification

Tabs.Notifications:Paragraph({
	Title = "Notification System",
	Content = "All script notifications appear as WindUI toasts + logged here. Seamless with module events, errors, and status.",
})
Tabs.Notifications:Button({
	Title = "Clear Notifications",
	Icon = "trash",
	Callback = function()
		notificationLog = {}
		refreshNotifTab()
	end,
})
Tabs.Notifications:Toggle({
	Title = "Toggle Notifications",
	Value = true,
	Callback = function(v) end,
})
Tabs.Notifications:Space({})

-- Initial log paragraph (refresh will manage updates)
refreshNotifTab()

-- Helper exposed for other systems to push notifs programmatically
d.PushNotification = function(title, text, ntype)
	return d:CreateNotification(title, text, 5, ntype)
end

refreshNotifTab()

-- Settings tab basics
Tabs.Settings:Toggle({
	Title = "UI Transparency",
	Desc = "Slight acrylic blur effect",
	Value = true,
	Callback = function(v)
		WindUI.TransparencyValue = v and 0.08 or 0
	end,
})

Tabs.Settings:Slider({
	Title = "UI Scale",
	Desc = "Adjust window scale",
	Value = { Min = 0.6, Max = 1.4, Default = 1.0 },
	Step = 0.05,
	Callback = function(val)
		pcall(function() Window:SetUIScale(val) end)
	end,
})

Tabs.Settings:Toggle({
	Title = "Rainbow Mode",
	Desc = "Global rainbow accents (if supported by visuals)",
	Value = false,
	Callback = function(v)
		d:CreateNotification("Settings", "Rainbow " .. (v and "enabled" or "disabled"), 2)
	end,
})

Tabs.Settings:Slider({
	Title = "Rainbow Speed",
	Value = { Min = 1, Max = 20, Default = 5 },
	Step = 1,
	Callback = function(v) end,
})

Tabs.Settings:Space()

Tabs.Settings:Button({
	Title = "Save Current Profile",
	Icon = "save",
	Callback = function()
		pcall(function()
			Window:SaveConfig()
			d:CreateNotification("BadWars", "Profile saved (WindUI + BadWars config)", 3, "success")
		end)
	end,
})

Tabs.Settings:Button({
	Title = "Load Profile",
	Icon = "folder-open",
	Callback = function()
		pcall(function()
			Window:LoadConfig()
			d:CreateNotification("BadWars", "Profile loaded", 3, "info")
		end)
	end,
})

Tabs.Settings:Button({
	Title = "Reinject / Reload",
	Icon = "refresh-cw",
	Callback = function()
		d:CreateNotification("BadWars", "Reloading...", 2)
		shared.BadReload = true
		if shared.BadDeveloper and readfile then
			loadstring(readfile("badscript/loader.lua"))()
		else
			loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true))()
		end
	end,
})

Tabs.Settings:Space()
Tabs.Settings:Paragraph({
	Title = "Notifications",
	Content = "Notification prefs live in the Notifications tab. All toasts use WindUI for modern look.",
})

-- Core category + module compatibility layer
-- This makes existing modules (Killaura etc) "just work"

local function makeOptionApi(initialValue, onChange)
	local api = { Value = initialValue }
	function api:SetValue(v, ...)
		api.Value = v
		if type(onChange) == "function" then
			pcall(onChange, v, ...)
		end
		return api
	end
	function api:Save() end
	function api:Load() end
	api.SetCallback = function(_, cb) onChange = cb end
	return api
end

local function createCategoryObj(name, iconName)
	local tab = Tabs[name]
	if not tab then
		tab = Window:Tab({ Title = name, Icon = iconName or "folder" })
		Tabs[name] = tab
	end

	local cat = {
		Name = name,
		Tab = tab,
		Modules = {},
	}

	function cat:CreateModule(settings)
		settings = settings or {}
		local modName = settings.Name or "Unnamed"
		local fn = settings.Function or function() end

		local mod = {
			Name = modName,
			Enabled = false,
			Options = {},
			Bind = settings.Bind or {},
			Function = fn,
			ExtraText = settings.ExtraText,
			Category = name,
			NoSave = settings.NoSave,
		}

		-- Use a Section per module for much better organization and design
		local modSection = tab:Section({
			Title = modName,
			Desc = settings.Tooltip or settings.Description or "",
			Opened = true,
		})

		-- Main toggle for the module inside its section
		local modToggle = modSection:Toggle({
			Title = "Enabled",
			Desc = "Toggle this module",
			Value = false,
			Callback = function(state)
				mod.Enabled = state == true
				task.spawn(function()
					local ok, err = pcall(fn, mod.Enabled)
					if not ok then
						d:CreateNotification("Module Error", modName .. ": " .. tostring(err), 6, "error")
					end
				end)
			end,
		})

		mod.Object = modToggle
		mod.SetEnabled = function(_, state)
			mod.Enabled = state
			pcall(function() modToggle:Set(state) end)
			pcall(fn, state)
		end

		d.Modules[modName] = mod
		cat.Modules[modName] = mod

		-- Attach creator helpers that modules expect. Now add to the module's Section
		local function attachElementCreator(elementType)
			return function(_, opt)
				opt = opt or {}
				local elName = opt.Name or (elementType .. "_" .. #mod.Options)

				local created
				if elementType == "Toggle" then
					created = modSection:Toggle({
						Title = opt.Name or "Option",
						Desc = opt.Desc or opt.Tooltip,
						Value = (opt.Default ~= nil and opt.Default) or (opt.Value ~= nil and opt.Value) or false,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = v
							if type(opt.Function) == "function" then pcall(opt.Function, v) end
						end,
					})
					-- Add legacy .Toggle() method for compatibility with old module code that calls element:Toggle()
					local origApi = makeOptionApi( (opt.Default ~= nil and opt.Default) or (opt.Value ~= nil and opt.Value) or false , opt.Function)
					origApi.Object = created
					origApi.Toggle = function(self)
						local new = not (self.Value or false)
						self.Value = new
						pcall(function()
							if created and created.Set then created:Set(new) end
						end)
						if type(opt.Function) == "function" then pcall(opt.Function, new) end
						return self
					end
					mod.Options[elName] = origApi
					return origApi
				elseif elementType == "Slider" then
					local minV = opt.Min or opt.MinValue or 0
					local maxV = opt.Max or opt.MaxValue or 100
					local defV = opt.Default or opt.Value or minV
					created = modSection:Slider({
						Title = opt.Name or "Slider",
						Desc = opt.Desc,
						Value = { Min = minV, Max = maxV, Default = defV },
						Step = opt.Step or 1,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = v
							if type(opt.Function) == "function" then pcall(opt.Function, v) end
						end,
					})
				elseif elementType == "Dropdown" then
					created = modSection:Dropdown({
						Title = opt.Name or "Dropdown",
						Desc = opt.Desc,
						Values = opt.List or opt.Options or { "Option1", "Option2" },
						Value = opt.Default or opt.Value,
						Multi = opt.Multi or false,
						SearchBarEnabled = opt.Search or false,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = v
							if type(opt.Function) == "function" then pcall(opt.Function, v) end
						end,
					})
				elseif elementType == "Color" or elementType == "ColorSlider" then
					created = modSection:Colorpicker({
						Title = opt.Name or "Color",
						Default = opt.Default or Color3.fromRGB(255, 0, 80),
						Callback = function(c)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = c
							if type(opt.Function) == "function" then pcall(opt.Function, c) end
						end,
					})
				elseif elementType == "Keybind" then
					created = modSection:Keybind({
						Title = opt.Name or "Keybind",
						Desc = opt.Desc,
						Default = opt.Default or opt.Value,
						Callback = function(k)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = k
							if type(opt.Function) == "function" then pcall(opt.Function, k) end
						end,
					})
				elseif elementType == "Input" or elementType == "TextBox" then
					created = modSection:Input({
						Title = opt.Name or "Input",
						Placeholder = opt.Placeholder or "",
						Default = opt.Default or "",
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = v
							if type(opt.Function) == "function" then pcall(opt.Function, v) end
						end,
					})
				elseif elementType == "TwoSlider" then
					-- Emulate TwoSlider with two Sliders for min/max (common for CPS, velocity, etc.)
					local minV = opt.Min or opt.MinValue or 0
					local maxV = opt.Max or opt.MaxValue or 100
					local defMin = opt.DefaultMin or opt.Min or minV
					local defMax = opt.DefaultMax or opt.Max or maxV
					local minSlider = modSection:Slider({
						Title = (opt.Name or "Range") .. " Min",
						Value = { Min = minV, Max = maxV, Default = defMin },
						Step = opt.Step or 1,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].ValueMin = v
							if type(opt.Function) == "function" then pcall(opt.Function, v, mod.Options[elName].ValueMax) end
						end,
					})
					local maxSlider = modSection:Slider({
						Title = (opt.Name or "Range") .. " Max",
						Value = { Min = minV, Max = maxV, Default = defMax },
						Step = opt.Step or 1,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].ValueMax = v
							if type(opt.Function) == "function" then pcall(opt.Function, mod.Options[elName].ValueMin, v) end
						end,
					})
					created = { MinSlider = minSlider, MaxSlider = maxSlider } -- for object ref
					mod.Options[elName] = {
						ValueMin = defMin,
						ValueMax = defMax,
						Object = created,
						SetValue = function(self, mn, mx)
							self.ValueMin = mn
							self.ValueMax = mx
							pcall(function() minSlider:Set(mn) end)
							pcall(function() maxSlider:Set(mx) end)
						end
					}
					return mod.Options[elName]
				elseif elementType == "TextList" then
					-- Basic emulation for TextList (e.g. AutoToxic messages). Use Input + display
					created = modSection:Input({
						Title = opt.Name or "Add to list",
						Placeholder = "Enter text and press enter (basic list)",
						Default = "",
						Callback = function(v)
							if v and v ~= "" then
								mod.Options[elName] = mod.Options[elName] or { Value = {} }
								table.insert(mod.Options[elName].Value, v)
								d:CreateNotification("List Updated", modName .. " added: " .. v, 3)
								if type(opt.Function) == "function" then pcall(opt.Function, mod.Options[elName].Value) end
							end
						end,
					})
					mod.Options[elName] = makeOptionApi(opt.Default or {}, opt.Function)
					mod.Options[elName].Object = created
					mod.Options[elName].Value = mod.Options[elName].Value or {}
					return mod.Options[elName]
				elseif elementType == "Font" then
					-- Emulate Font with dropdown of common Roblox fonts
					local fonts = {"Gotham", "Arial", "SourceSans", "Roboto", "Ubuntu", "Fantasy", "Code", "Highway"}
					created = modSection:Dropdown({
						Title = opt.Name or "Font",
						Options = fonts,
						Callback = function(v)
							mod.Options[elName] = mod.Options[elName] or {}
							mod.Options[elName].Value = v
							if type(opt.Function) == "function" then pcall(opt.Function, v) end
						end,
					})
				else
					-- Fallback
					created = modSection:Paragraph({
						Title = opt.Name or elementType,
						Content = opt.Desc or "",
					})
				end

				local optApi = makeOptionApi(opt.Default or opt.Value, opt.Function)
				optApi.Object = created
				mod.Options[elName] = optApi
				return optApi
			end
		end

		-- Attach all common creators
		mod.CreateToggle = attachElementCreator("Toggle")
		mod.CreateSlider = attachElementCreator("Slider")
		mod.CreateDropdown = attachElementCreator("Dropdown")
		mod.CreateColorSlider = attachElementCreator("Color")
		mod.CreateColorpicker = attachElementCreator("Color")
		mod.CreateKeybind = attachElementCreator("Keybind")
		mod.CreateInput = attachElementCreator("Input")
		mod.CreateTextBox = attachElementCreator("Input")
		mod.CreateTwoSlider = attachElementCreator("TwoSlider")
		mod.CreateTextList = attachElementCreator("TextList")
		mod.CreateFont = attachElementCreator("Font")
		mod.CreateButton = function(_, opt)
			return modSection:Button({
				Title = opt.Name or "Action",
				Icon = opt.Icon,
				Callback = opt.Function or function() end,
			})
		end

		-- Improved Targets support
		mod.CreateTargets = function(_, opt)
			opt = opt or {}
			local list = {}
			if opt.Players ~= false then table.insert(list, "Players") end
			if opt.NPCs or opt.NPC then table.insert(list, "NPCs") end
			if opt.Friends ~= false then table.insert(list, "Friends") end
			if opt.Walls then table.insert(list, "Walls") end
			if #list == 0 then list = {"Players", "NPCs", "Friends", "All"} end
			local initial = {}
			for _, k in ipairs(list) do initial[k] = true end
			local dd = modSection:Dropdown({
				Title = opt.Name or "Targets",
				Values = list,
				Multi = true,
				Callback = function(selected)
					local val = {}
					for _, s in ipairs(selected or {}) do val[s] = true end
					mod.Options.Targets = mod.Options.Targets or {}
					mod.Options.Targets.Value = val
					-- also expose flags directly for legacy module code
					for _, k in ipairs(list) do mod.Options.Targets[k] = val[k] or false end
					if type(opt.Function) == "function" then pcall(opt.Function, val) end
				end,
			})
			local api = makeOptionApi(initial, opt.Function)
			api.Object = dd
			-- expose flags
			for _, k in ipairs(list) do api[k] = initial[k] end
			mod.Options.Targets = api
			return api
		end

		mod.SetExtraText = function(_, txt)
			mod.ExtraText = txt
			-- Could enhance section desc
			pcall(function() modSection:SetDesc(txt or "") end)
		end

		return mod
	end

	-- Support sub module categories (Inventory, Minigames under World etc.)
	function cat:CreateModuleCategory(subSettings)
		local subName = subSettings.Name
		local subTab = Tabs[subName] or Window:Tab({ Title = subName, Icon = "folder" })
		Tabs[subName] = subTab

		local subCat = { Name = subName, Tab = subTab, Modules = {} }
		function subCat:CreateModule(s)
			-- delegate to same logic but on the sub tab
			local m = cat:CreateModule(s)
			-- also register under this sub
			subCat.Modules[s.Name] = m
			return m
		end
		return subCat
	end

	function cat:CreateDivider() end -- no-op for WindUI

	d.Categories[name] = cat
	return cat
end

-- Create the primary categories expected by modules
d.CreateCategory = function(self, cfg)
	-- legacy path sometimes used
	return createCategoryObj(cfg.Name, cfg.Icon and "folder" or nil)
end

createCategoryObj("Combat", "sword")
createCategoryObj("Blatant", "flame")
createCategoryObj("Render", "eye")
createCategoryObj("Utility", "wrench")
createCategoryObj("World", "globe")
createCategoryObj("Minigames", "gamepad-2")
createCategoryObj("Legit", "user-check")

-- Legacy structure some modules / bootstrap expect
d.Legit = d.Legit or { Modules = {}, CreateModule = function(_, s) return d.Categories.Legit:CreateModule(s) end }
d.Overlays = d.Overlays or {}

-- Optional: support Bad:CreateOverlay used in some modules
function d:CreateOverlay(settings)
	local name = (settings and settings.Name) or "Overlay"
	local ov = d.Categories.Render:CreateModule(settings or { Name = name })
	d.Overlays[name] = ov
	return ov
end

-- Also ensure Main / Friends / Targets exist for the bootstrap code in main.lua
d.Categories.Main = d.Categories.Main or {
	Type = "ServiceCategory",
	Name = "Main",
	Options = {
		["GUI bind indicator"] = { Enabled = true },
		["Teams by server"] = { Enabled = false },
		["Use team color"] = { Enabled = true },
	},
}
-- Legacy buttons on Main (e.g. Uninject in old GUI) route to General tab
d.Categories.Main.CreateButton = function(_, opt)
	return (Tabs.General or Tabs.Settings):Button({
		Title = opt.Name or "Action",
		Icon = opt.Icon,
		Callback = opt.Function or function() end,
	})
end
d.Categories.Main.CreateToggle = function(_, opt)
	return (Tabs.General or Tabs.Settings):Toggle({
		Title = opt.Name or "Option",
		Value = opt.Default or false,
		Callback = opt.Function or function() end,
	})
end
d.Categories.Friends = d.Categories.Friends or createCategoryObj("Friends", "users")
d.Categories.Targets = d.Categories.Targets or createCategoryObj("Targets", "crosshair")

-- Minimal Clean support expected by some bootstrap paths
d.Connections = d.Connections or {}
function d:Clean(conn)
	if conn and typeof(conn) == "RBXScriptConnection" or type(conn) == "table" and conn.Disconnect then
		table.insert(d.Connections, conn)
	end
end
d.Clean = d.Clean

-- General quick actions
Tabs.General:Button({
	Title = "Uninject / Self Destruct",
	Icon = "x",
	Callback = function()
		d:CreateNotification("BadWars", "Uninjecting...", 2)
		pcall(function() Window:Destroy() end)
		if d.Uninject then d:Uninject() end
	end,
})

Tabs.General:Toggle({
	Title = "GUI Bind Indicator",
	Value = true,
	Callback = function(v)
		if d.Categories.Main and d.Categories.Main.Options then
			d.Categories.Main.Options["GUI bind indicator"] = { Enabled = v }
		end
	end,
})

Tabs.General:Toggle({
	Title = "Teams by server",
	Value = false,
	Callback = function(v)
		if d.Categories.Main and d.Categories.Main.Options then
			d.Categories.Main.Options["Teams by server"] = { Enabled = v }
		end
	end,
})

Tabs.General:Toggle({
	Title = "Use team color",
	Value = true,
	Callback = function(v)
		if d.Categories.Main and d.Categories.Main.Options then
			d.Categories.Main.Options["Use team color"] = { Enabled = v }
		end
	end,
})

-- Additional General options that main.lua expects
if d.Categories.Main and type(d.Categories.Main) == "table" then
	d.Categories.Main.Options = d.Categories.Main.Options or {}
	d.Categories.Main.Options["Teams by server"] = { Enabled = false }
	d.Categories.Main.Options["Use team color"] = { Enabled = true }
end

Tabs.General:Space()
Tabs.General:Paragraph({
	Title = "Quick Info",
	Content = "Use RightShift (or configured key) to toggle the UI. All module changes are live and profile-persisted.",
})

-- Profile / config helpers used by main
function d.Save(self, target)
	pcall(function() Window:SaveConfig() end)
end

function d.Load(self, saved)
	pcall(function() Window:LoadConfig() end)
end

function d.Change() end

function d.Uninject()
	-- Best effort cleanup
	pcall(function()
		for _, c in pairs(d.Connections or {}) do pcall(function() c:Disconnect() end) end
	end)
	pcall(function() Window:Destroy() end)
	if shared then shared.Bad = nil end
end

d.RefreshScrollCanvases = function() end -- not needed

-- Finalize and return the API exactly like the old gui did
d.gui = Window -- expose for debug
d.Window = Window
d.WindUI = WindUI
d.Version = "WindUI-Adapter-1.0"
d.PremiumBuild = true
d.Name = "BadWars-WindUI"

-- Control visibility + welcome toast/log: loader/main calls :Show() ONLY after full bootstrap finishes
function d:Show()
	pcall(function()
		if Window and Window.UIElements and Window.UIElements.Main then
			Window.UIElements.Main.Visible = true
			Window.UIElements.Main.GroupTransparency = 0
		end
		if Window and Window.Open then
			Window:Open()
		elseif Window and Window.Toggle then
			Window:Toggle()
		end
		-- Show any open button
		if Window and Window.UIElements then
			for k, v in pairs(Window.UIElements) do
				if v and typeof(v) == "Instance" and (k:lower():find("open") or (v.Name or ""):lower():find("open")) then
					v.Visible = true
				end
			end
		end
		-- Heavy custom animation using spr for open
		if spr and Window and Window.UIElements and Window.UIElements.Main then
			local main = Window.UIElements.Main
			-- Spring the transparency and perhaps size for nice feel
			spr.target(main, 0.7, 4, { GroupTransparency = 0 })
		end
	end)
	pcall(function()
		d:CreateNotification("BadWars", "WindUI integrated. All modules, dropdowns, and notifications are now powered by WindUI.", 7, "success")
		refreshNotifTab()
	end)
end
d.Show = d.Show

-- Expose a couple of useful things on shared for modules
if shared then
	shared.Bad = shared.Bad or {}
	shared.Bad.CreateNotification = function(...) return d:CreateNotification(...) end
end

-- Legacy shims so old bootstrap code in main.lua (showInterface etc.) doesn't explode on WindUI
d.WaitForModuleReadiness = d.WaitForModuleReadiness or function() end
d.FinalizeInitialLayout = d.FinalizeInitialLayout or function() end

-- If some old code does api.gui:FindFirstChild etc., provide a safe no-op table
if not d.gui or type(d.gui) ~= "table" then
	d.gui = d.Window or {}
end

return d
