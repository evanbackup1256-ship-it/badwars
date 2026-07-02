local function safeHttpGet(inst, url, nocache)
	local g = inst or game
	local httpget = g.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(g, url, nocache)
	end
	local httpService = cloneref(game:GetService("HttpService"))
	return httpService:GetAsync(url, nocache)
end
local mainapi = {
	Categories = {},
	GUIColor = {
		Hue = 0.46,
		Sat = 0.96,
		Value = 0.52
	},
	HeldKeybinds = {},
	Keybind = {'RightShift'},
	Loaded = false,
	Libraries = {},
	Modules = {},
	Place = game.PlaceId,
	Profile = 'default',
	Profiles = {},
	RainbowSpeed = {Value = 1},
	RainbowUpdateSpeed = {Value = 60},
	RainbowTable = {},
	Scale = {Value = 1},
	ThreadFix = setthreadidentity and true or false,
	ToggleNotifications = {},
	Version = '4.18',
	Windows = {},
	Logs = {},
	MaxLogs = 500,
	LogLevels = {Info = Color3.fromRGB(200, 200, 200), Success = Color3.fromRGB(100, 255, 100), Warning = Color3.fromRGB(255, 200, 100), Debug = Color3.fromRGB(150, 150, 255), Error = Color3.fromRGB(255, 100, 100)}
}

-- Custom log function (supports rich entries)
local function AddLog(level, message, stackOrExtra)
	if not mainapi.Logs then mainapi.Logs = {} end
	local entry
	if type(stackOrExtra) == 'table' and (stackOrExtra.preview or stackOrExtra.script or stackOrExtra.category) then
		entry = stackOrExtra
		entry.level = level or entry.level or 'Info'
		entry.message = message or entry.message or ''
		entry.time = entry.time or os.date('%H:%M:%S')
	else
		entry = {level = level, message = message, stack = stackOrExtra, time = os.date('%H:%M:%S')}
	end
	table.insert(mainapi.Logs, entry)
	if #mainapi.Logs > mainapi.MaxLogs then table.remove(mainapi.Logs, 1) end
	if mainapi.UpdateConsole then mainapi.UpdateConsole() end
end

local makeCompileLog

-- Rich compile error reporter (primary entry point for parser errors)
mainapi.CreateCompileError = function(scriptName, err, sourceCode, extra)
	local logEntry = makeCompileLog(scriptName, err, sourceCode)
	if extra then
		for k, v in pairs(extra) do logEntry[k] = v end
	end
	AddLog('Compile', logEntry.message, logEntry)
	-- Also surface via notification system with compile type
	mainapi:CreateNotification(
		'Compile Error • ' .. (logEntry.script or scriptName or 'script'),
		logEntry.message,
		12,
		'compile',
		logEntry
	)
end

-- Override for runtime errors
mainapi.CreateRuntimeError = function(title, text, stack)
	AddLog('Error', (title or 'Runtime Error') .. ': ' .. (text or ''), stack)
	mainapi:CreateNotification(title or 'Runtime Error', text or '', 8, 'runtime', stack)
end

-- Safe wrapper for module execution (now uses compile diagnostics when possible)
local function SafeRequire(moduleCode, name)
	local f, loadErr = loadstring(moduleCode, name or 'module')
	if not f then
		if mainapi.CreateCompileError then
			mainapi.CreateCompileError(name or 'module', loadErr, moduleCode)
		else
			AddLog('Compile', 'Module load failed: ' .. (name or 'unknown'), {rawError = loadErr})
		end
		return nil
	end
	local success, result = pcall(f)
	if not success then
		AddLog('Error', 'Module runtime error: ' .. (name or 'unknown'), result)
		if mainapi.CreateRuntimeError then mainapi.CreateRuntimeError(name or 'module', tostring(result)) end
		return nil
	end
	return result
end

-- ============================================================
-- Rich Compiler Diagnostics & IDE-like Error UI Helpers
-- ============================================================

-- Parse standard Roblox loadstring error: [string "Name"]:55: Message
local function parseCompileError(err)
	if type(err) ~= 'string' then
		return { script = 'unknown', line = 0, message = tostring(err), raw = err }
	end
	-- Common forms
	local scriptName, lineNum, msg = err:match('%[string ["\']?([^"\']+)["\']?%]:(%d+):%s*(.+)')
	if scriptName and lineNum then
		return { script = scriptName, line = tonumber(lineNum), message = msg, raw = err }
	end
	-- Fallback: file.lua:NN: msg or generic
	scriptName, lineNum, msg = err:match('([^:]+):(%d+):%s*(.+)')
	if scriptName and lineNum then
		return { script = scriptName, line = tonumber(lineNum), message = msg, raw = err }
	end
	-- Last resort
	local ln = err:match(':(%d+):')
	return { script = 'unknown', line = ln and tonumber(ln) or 0, message = err, raw = err }
end

-- Analyze message and (optionally) source line for friendly explanations + suggested fixes
local function analyzeLuaError(parsed, source)
	local msg = (parsed.message or ''):lower()
	local suggestions = {}
	local category = 'Syntax Error'
	local likely = ''

	if msg:find('malformed string') or msg:find('unfinished string') or msg:find('unfinished long string') then
		likely = 'Unterminated string literal.'
		table.insert(suggestions, 'Missing closing quotation mark ( " or \' ).')
		table.insert(suggestions, 'If the string spans lines, use long string [[ ... ]] syntax (and close it).')
		table.insert(suggestions, 'Check for literal newline inside "double" or \'single\' quoted string — Lua does not allow this without escaping or long-string form.')
		table.insert(suggestions, 'Escaped quote mismatch: use \\" inside "..." or \\\' inside \'...\'.')
		table.insert(suggestions, 'Possible missing closing bracket/paren after string concat: "foo" .. bar )')
	elseif msg:find('expected near') or msg:find("'=' expected near") then
		likely = 'Syntax near the reported token.'
		table.insert(suggestions, 'Missing comma, operator, or closing bracket/parenthesis.')
		table.insert(suggestions, 'Check for incomplete expression or statement on previous line.')
	elseif msg:find('unexpected symbol') or msg:find('expected') then
		likely = 'Unexpected token.'
		table.insert(suggestions, 'Look for stray characters, missing "end", or unbalanced ( [ { " \' .')
	elseif msg:find('\'end\' expected') or msg:find('block ends') then
		likely = 'Unclosed block (function/if/for/etc).'
		table.insert(suggestions, 'Add missing "end" to close the block started earlier.')
	elseif msg:find('unfinished') then
		likely = 'Unfinished construct.'
		table.insert(suggestions, 'Check brackets, quotes, and block terminators.')
	else
		table.insert(suggestions, 'Review the highlighted line and surrounding context for typos or missing tokens.')
	end

	-- Contextual help using source line if available
	local lineText = ''
	if source and parsed.line and parsed.line > 0 then
		local lines = {}
		for line in (source .. '\n'):gmatch('([^\r\n]*)\r?\n') do table.insert(lines, line) end
		lineText = lines[parsed.line] or ''
		if lineText:find('["\']') and (lineText:match('["\'].*["\']') == nil or select(2, lineText:gsub('["\']', '')) % 2 ~= 0) then
			table.insert(suggestions, 'The failing line appears to contain an odd number of quote characters.')
		end
		if lineText:find('%[%[') and not lineText:find('%]%]') then
			table.insert(suggestions, 'Detected [[ long string opener without matching ]].')
		end
	end

	return {
		likely = likely ~= '' and likely or nil,
		suggestions = suggestions,
		category = category,
		lineText = lineText
	}
end

-- Extract surrounding source lines for preview (e.g. errLine-3 .. errLine+3)
local function getCodePreview(source, errLine, contextLines)
	contextLines = contextLines or 3
	if not source or not errLine or errLine < 1 then return nil end
	local lines = {}
	for line in (source .. '\n'):gmatch('([^\r\n]*)\r?\n') do
		table.insert(lines, line)
	end
	local startL = math.max(1, errLine - contextLines)
	local endL = math.min(#lines, errLine + contextLines)
	local preview = {}
	for i = startL, endL do
		table.insert(preview, {
			num = i,
			text = lines[i] or '',
			isError = (i == errLine)
		})
	end
	return preview
end

-- Very lightweight Lua syntax highlighter returning RichText-compatible string for one line
local function highlightLua(line)
	if type(line) ~= 'string' then return tostring(line or '') end
	local s = line
	-- Escape for rich text first (order important)
	s = s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')

	-- Strings (double, single, long) — simple non-nested capture
	s = s:gsub('(%-%-%[=*%[.-%]=*%])', '<font color="#6A9955">%1</font>') -- long comment
	s = s:gsub('(%-%-.*)', '<font color="#6A9955">%1</font>') -- line comment (after strings less ideal)
	s = s:gsub('(".-")', '<font color="#CE9178">%1</font>')
	s = s:gsub("('.-')", '<font color="#CE9178">%1</font>')
	s = s:gsub('(%[%[.-%]%])', '<font color="#CE9178">%1</font>')

	-- Keywords
	local keywords = {'local','function','end','if','then','else','elseif','for','in','while','do','repeat','until','return','break','and','or','not','true','false','nil'}
	for _, kw in ipairs(keywords) do
		s = s:gsub('(%f[%w_])(' .. kw .. ')(%f[%W_])', '<font color="#569CD6">%1%2%3</font>')
	end

	-- Numbers
	s = s:gsub('(%f[%w_%.]%d+%.?%d*)(%f[%W_])', '<font color="#B5CEA8">%1</font>%2')

	-- Common builtins / globals hint
	s = s:gsub('(%f[%w_])(game|workspace|script|Instance|require|pcall|loadstring|table|string)(%f[%W_])', '<font color="#4EC9B0">%1%2%3</font>')

	return s
end

-- Create a compile error entry object (used by AddLog / direct)
function makeCompileLog(scriptName, err, sourceCode)
	local parsed = parseCompileError(err)
	parsed.script = scriptName or parsed.script
	local analysis = analyzeLuaError(parsed, sourceCode)
	local preview = getCodePreview(sourceCode, parsed.line, 3)
	return {
		level = 'Compile',
		message = parsed.message or tostring(err),
		time = os.date('%H:%M:%S'),
		script = parsed.script,
		line = parsed.line,
		rawError = err,
		source = sourceCode,
		preview = preview,
		suggestions = analysis.suggestions,
		likely = analysis.likely,
		category = 'Compile Error',
		expanded = false
	}
end

-- ============================================================
-- End Rich Diagnostics Helpers
-- ============================================================

local cloneref = cloneref or function(obj)
	return obj
end
local tweenService = cloneref(game:GetService('TweenService'))
local inputService = cloneref(game:GetService('UserInputService'))
local textService = cloneref(game:GetService('TextService'))
local guiService = cloneref(game:GetService('GuiService'))
local runService = cloneref(game:GetService('RunService'))
local httpService = cloneref(game:GetService('HttpService'))

local fontsize = Instance.new('GetTextBoundsParams')
fontsize.Width = math.huge
local notifications
local assetfunction = getcustomasset
local getcustomasset
local clickgui
local scaledgui
local toolblur
local tooltip
local scale
local gui

local color = {}
local tween = {
	tweens = {},
	tweenstwo = {}
}
local uipallet = {
	Main = Color3.fromRGB(26, 25, 26),
	Text = Color3.fromRGB(200, 200, 200),
	Font = Font.fromEnum(Enum.Font.Arial),
	FontSemiBold = Font.fromEnum(Enum.Font.Arial, Enum.FontWeight.SemiBold),
	Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
}

local getcustomassets = {
	['badscript/assets/new/add.png'] = 'rbxassetid://14368300605',
	['badscript/assets/new/alert.png'] = 'rbxassetid://14368301329',
	['badscript/assets/new/allowedicon.png'] = 'rbxassetid://14368302000',
	['badscript/assets/new/allowedtab.png'] = 'rbxassetid://14368302875',
	['badscript/assets/new/arrowmodule.png'] = 'rbxassetid://14473354880',
	['badscript/assets/new/back.png'] = 'rbxassetid://14368303894',
	['badscript/assets/new/bind.png'] = 'rbxassetid://14368304734',
	['badscript/assets/new/bindbkg.png'] = 'rbxassetid://14368305655',
	['badscript/assets/new/blatanticon.png'] = 'rbxassetid://14368306745',
	['badscript/assets/new/blockedicon.png'] = 'rbxassetid://14385669108',
	['badscript/assets/new/blockedtab.png'] = 'rbxassetid://14385672881',
	['badscript/assets/new/blur.png'] = 'rbxassetid://14898786664',
	['badscript/assets/new/blurnotif.png'] = 'rbxassetid://16738720137',
	['badscript/assets/new/close.png'] = 'rbxassetid://14368309446',
	['badscript/assets/new/closemini.png'] = 'rbxassetid://14368310467',
	['badscript/assets/new/colorpreview.png'] = 'rbxassetid://14368311578',
	['badscript/assets/new/combaticon.png'] = 'rbxassetid://14368312652',
	['badscript/assets/new/customsettings.png'] = 'rbxassetid://14403726449',
	['badscript/assets/new/discord.png'] = '',
	['badscript/assets/new/dots.png'] = 'rbxassetid://14368314459',
	['badscript/assets/new/edit.png'] = 'rbxassetid://14368315443',
	['badscript/assets/new/expandicon.png'] = 'rbxassetid://14368353032',
	['badscript/assets/new/expandright.png'] = 'rbxassetid://14368316544',
	['badscript/assets/new/expandup.png'] = 'rbxassetid://14368317595',
	['badscript/assets/new/friendstab.png'] = 'rbxassetid://14397462778',
	['badscript/assets/new/guisettings.png'] = 'rbxassetid://14368318994',
	['badscript/assets/new/guislider.png'] = 'rbxassetid://14368320020',
	['badscript/assets/new/guisliderrain.png'] = 'rbxassetid://14368321228',
	['badscript/assets/new/guiv4.png'] = 'rbxassetid://14368322199',
	['badscript/assets/new/guiBad.png'] = 'rbxassetid://14657521312',
	['badscript/assets/new/info.png'] = 'rbxassetid://14368324807',
	['badscript/assets/new/inventoryicon.png'] = 'rbxassetid://14928011633',
	['badscript/assets/new/legit.png'] = 'rbxassetid://14425650534',
	['badscript/assets/new/legittab.png'] = 'rbxassetid://14426740825',
	['badscript/assets/new/miniicon.png'] = 'rbxassetid://14368326029',
	['badscript/assets/new/notification.png'] = 'rbxassetid://16738721069',
	['badscript/assets/new/overlaysicon.png'] = 'rbxassetid://14368339581',
	['badscript/assets/new/overlaystab.png'] = 'rbxassetid://14397380433',
	['badscript/assets/new/pin.png'] = 'rbxassetid://14368342301',
	['badscript/assets/new/profilesicon.png'] = 'rbxassetid://14397465323',
	['badscript/assets/new/radaricon.png'] = 'rbxassetid://14368343291',
	['badscript/assets/new/rainbow_1.png'] = 'rbxassetid://14368344374',
	['badscript/assets/new/rainbow_2.png'] = 'rbxassetid://14368345149',
	['badscript/assets/new/rainbow_3.png'] = 'rbxassetid://14368345840',
	['badscript/assets/new/rainbow_4.png'] = 'rbxassetid://14368346696',
	['badscript/assets/new/range.png'] = 'rbxassetid://14368347435',
	['badscript/assets/new/rangearrow.png'] = 'rbxassetid://14368348640',
	['badscript/assets/new/rendericon.png'] = 'rbxassetid://14368350193',
	['badscript/assets/new/rendertab.png'] = 'rbxassetid://14397373458',
	['badscript/assets/new/search.png'] = 'rbxassetid://14425646684',
	['badscript/assets/new/targetinfoicon.png'] = 'rbxassetid://14368354234',
	['badscript/assets/new/targetnpc1.png'] = 'rbxassetid://14497400332',
	['badscript/assets/new/targetnpc2.png'] = 'rbxassetid://14497402744',
	['badscript/assets/new/targetplayers1.png'] = 'rbxassetid://14497396015',
	['badscript/assets/new/targetplayers2.png'] = 'rbxassetid://14497397862',
	['badscript/assets/new/targetstab.png'] = 'rbxassetid://14497393895',
	['badscript/assets/new/textguiicon.png'] = 'rbxassetid://14368355456',
	['badscript/assets/new/textv4.png'] = 'rbxassetid://14368357095',
	['badscript/assets/new/textBad.png'] = 'rbxassetid://14368358200',
	['badscript/assets/new/utilityicon.png'] = 'rbxassetid://14368359107',
	['badscript/assets/new/Bad.png'] = 'rbxassetid://14373395239',
	['badscript/assets/new/warning.png'] = 'rbxassetid://14368361552',
	['badscript/assets/new/worldicon.png'] = 'rbxassetid://14368362492'
}

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end

local getfontsize = function(text, size, font)
	fontsize.Text = text
	fontsize.Size = size
	if typeof(font) == 'Font' then
		fontsize.Font = font
	end
	return textService:GetTextBoundsAsync(fontsize)
end

local function addBlur(parent, notif)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('badscript/assets/new/'..(notif and 'blurnotif' or 'blur')..'.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent

	return blur
end

local function addCorner(parent, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = radius or UDim.new(0, 5)
	corner.Parent = parent

	return corner
end

local function addCloseButton(parent, offset)
	local close = Instance.new('ImageButton')
	close.Name = 'Close'
	close.Size = UDim2.fromOffset(24, 24)
	close.Position = UDim2.new(1, -35, 0, offset or 9)
	close.BackgroundColor3 = Color3.new(1, 1, 1)
	close.BackgroundTransparency = 1
	close.AutoButtonColor = false
	close.Image = getcustomasset('badscript/assets/new/close.png')
	close.ImageColor3 = color.Light(uipallet.Text, 0.2)
	close.ImageTransparency = 0.5
	close.Parent = parent
	addCorner(close, UDim.new(1, 0))

	close.MouseEnter:Connect(function()
		close.ImageTransparency = 0.3
		tween:Tween(close, uipallet.Tween, {
			BackgroundTransparency = 0.6
		})
	end)
	close.MouseLeave:Connect(function()
		close.ImageTransparency = 0.5
		tween:Tween(close, uipallet.Tween, {
			BackgroundTransparency = 1
		})
	end)

	return close
end

local function addMaid(object)
	object.Connections = {}
	function object:Clean(callback)
		if typeof(callback) == 'Instance' then
			table.insert(self.Connections, {
				Disconnect = function()
					callback:ClearAllChildren()
					callback:Destroy()
				end
			})
		elseif type(callback) == 'function' then
			table.insert(self.Connections, {
				Disconnect = callback
			})
		else
			table.insert(self.Connections, callback)
		end
	end
end

local function addTooltip(gui, text)
	if not text then return end

	local function tooltipMoved(x, y)
		local right = x + 16 + tooltip.Size.X.Offset > (scale.Scale * 1920)
		tooltip.Position = UDim2.fromOffset(
			(right and x - (tooltip.Size.X.Offset * scale.Scale) - 16 or x + 16) / scale.Scale,
			((y + 11) - (tooltip.Size.Y.Offset / 2)) / scale.Scale
		)
		tooltip.Visible = toolblur.Visible
	end

	gui.MouseEnter:Connect(function(x, y)
		local tooltipSize = getfontsize(text, tooltip.TextSize, uipallet.Font)
		tooltip.Size = UDim2.fromOffset(tooltipSize.X + 10, tooltipSize.Y + 10)
		tooltip.Text = text
		tooltipMoved(x, y)
	end)
	gui.MouseMoved:Connect(tooltipMoved)
	gui.MouseLeave:Connect(function()
		tooltip.Visible = false
	end)
end

local function checkKeybinds(compare, target, key)
	if type(target) == 'table' then
		if table.find(target, key) then
			for i, v in target do
				if not table.find(compare, v) then
					return false
				end
			end
			return true
		end
	end

	return false
end

local function createDownloader(text)
	if tostring(text):find('badscript/assets/', 1, true) then
		return
	end
	if mainapi.Loaded ~= true then
		local downloader = mainapi.Downloader
		if not downloader then
			downloader = Instance.new('TextLabel')
			downloader.Size = UDim2.new(1, 0, 0, 40)
			downloader.BackgroundTransparency = 1
			downloader.TextStrokeTransparency = 0
			downloader.TextSize = 20
			downloader.TextColor3 = Color3.new(1, 1, 1)
			downloader.FontFace = uipallet.Font
			downloader.Parent = mainapi.gui
			mainapi.Downloader = downloader
		end
		downloader.Text = 'Downloading '..text
	end
end

local function createMobileButton(buttonapi, position)
	local heldbutton = false
	local button = Instance.new('TextButton')
	button.Size = UDim2.fromOffset(40, 40)
	button.Position = UDim2.fromOffset(position.X, position.Y)
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	button.BackgroundTransparency = 0.5
	button.Text = buttonapi.Name
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.Font = Enum.Font.Gotham
	button.Parent = mainapi.gui
	local buttonconstraint = Instance.new('UITextSizeConstraint')
	buttonconstraint.MaxTextSize = 16
	buttonconstraint.Parent = button
	addCorner(button, UDim.new(1, 0))

	button.MouseButton1Down:Connect(function()
		heldbutton = true
		local holdtime, holdpos = tick(), inputService:GetMouseLocation()
		repeat
			heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 6
			task.wait()
		until (tick() - holdtime) > 1 or not heldbutton
		if heldbutton then
			buttonapi.Bind = {}
			button:Destroy()
		end
	end)
	button.MouseButton1Up:Connect(function()
		heldbutton = false
	end)
	button.MouseButton1Click:Connect(function()
		buttonapi:Toggle()
		button.BackgroundColor3 = buttonapi.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
	end)

	buttonapi.Bind = {Button = button}
end

local function downloadFile(path, func)
	local mapped = getcustomassets[path]
	if mapped ~= nil then
		return mapped
	end
	if not isfile(path) then
		createDownloader(path)
		local suc, res = pcall(function()
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path:gsub(' ', '%%20'), true)
		end)
		if not suc or res == '404: Not Found' then
			return getcustomassets[path] or ''
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded, no watermark)\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile or function() return '' end)(path)
end

getcustomasset = not inputService.TouchEnabled and assetfunction and function(path)
	local mapped = getcustomassets[path]
	if mapped ~= nil then
		return mapped
	end
	return downloadFile(path, assetfunction)
end or function(path)
	return getcustomassets[path] or ''
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function loopClean(tab)
	for i, v in tab do
		if type(v) == 'table' then
			loopClean(v)
		end
		tab[i] = nil
	end
end

local function loadJson(path)
	local suc, res = pcall(function()
		return httpService:JSONDecode(readfile(path))
	end)
	return suc and type(res) == 'table' and res or nil
end

local function makeDraggable(gui, window)
	gui.InputBegan:Connect(function(inputObj)
		if window and not window.Visible then return end
		if
			(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
			and (inputObj.Position.Y - gui.AbsolutePosition.Y < 40 or window)
		then
			local dragPosition = Vector2.new(
				gui.AbsolutePosition.X - inputObj.Position.X,
				gui.AbsolutePosition.Y - inputObj.Position.Y + guiService:GetGuiInset().Y
			) / scale.Scale

			local changed = inputService.InputChanged:Connect(function(input)
				if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
					local position = input.Position
					if inputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						dragPosition = (dragPosition // 3) * 3
						position = (position // 3) * 3
					end
					gui.Position = UDim2.fromOffset((position.X / scale.Scale) + dragPosition.X, (position.Y / scale.Scale) + dragPosition.Y)
				end
			end)

			local ended
			ended = inputObj.Changed:Connect(function()
				if inputObj.UserInputState == Enum.UserInputState.End then
					if changed then
						changed:Disconnect()
					end
					if ended then
						ended:Disconnect()
					end
				end
			end)
		end
	end)
end

local function randomString()
	local array = {}
	for i = 1, math.random(10, 100) do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return str:gsub('<[^<>]->', '')
end

do
	local res = isfile('badscript/profiles/color.txt') and loadJson('badscript/profiles/color.txt')
	if res then
		uipallet.Main = res.Main and Color3.fromRGB(unpack(res.Main)) or uipallet.Main
		uipallet.Text = res.Text and Color3.fromRGB(unpack(res.Text)) or uipallet.Text
		uipallet.Font = res.Font and Font.new(
			res.Font:find('rbxasset') and res.Font
			or string.format('rbxasset://fonts/families/%s.json', res.Font)
		) or uipallet.Font
		uipallet.FontSemiBold = Font.new(uipallet.Font.Family, Enum.FontWeight.SemiBold)
	end
	fontsize.Font = uipallet.Font
end

do
	function color.Dark(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v + num or v - num, 0, 1))
	end

	function color.Light(col, num)
		local h, s, v = col:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(select(3, uipallet.Main:ToHSV()) > 0.5 and v - num or v + num, 0, 1))
	end

	function mainapi:Color(h)
		local s = 0.75 + (0.15 * math.min(h / 0.03, 1))
		if h > 0.57 then
			s = 0.9 - (0.4 * math.min((h - 0.57) / 0.09, 1))
		end
		if h > 0.66 then
			s = 0.5 + (0.4 * math.min((h - 0.66) / 0.16, 1))
		end
		if h > 0.87 then
			s = 0.9 - (0.15 * math.min((h - 0.87) / 0.13, 1))
		end
		return h, s, 1
	end

	function mainapi:TextColor(h, s, v)
		if v >= 0.7 and (s < 0.6 or h > 0.04 and h < 0.56) then
			return Color3.new(0.19, 0.19, 0.19)
		end
		return Color3.new(1, 1, 1)
	end
end

do
	function tween:Tween(obj, tweeninfo, goal, tab)
		tab = tab or self.tweens
		if tab[obj] then
			tab[obj]:Cancel()
			tab[obj] = nil
		end

		if obj.Parent and obj.Visible then
			tab[obj] = tweenService:Create(obj, tweeninfo, goal)
			tab[obj].Completed:Once(function()
				if tab then
					tab[obj] = nil
					tab = nil
				end
			end)
			tab[obj]:Play()
		else
			for i, v in goal do
				obj[i] = v
			end
		end
	end

	function tween:Cancel(obj)
		if self.tweens[obj] then
			self.tweens[obj]:Cancel()
			self.tweens[obj] = nil
		end
	end
end

mainapi.Libraries = {
	color = color,
	getcustomasset = getcustomasset,
	getfontsize = getfontsize,
	tween = tween,
	uipallet = uipallet,
}

local components
components = {
--Components
	Divider = function(children, text)
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = children
		if text then
			local label = Instance.new('TextLabel')
			label.Name = 'DividerLabel'
			label.Size = UDim2.fromOffset(218, 27)
			label.BackgroundTransparency = 1
			label.Text = '          '..text:upper()
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = color.Dark(uipallet.Text, 0.43)
			label.TextSize = 9
			label.FontFace = uipallet.Font
			label.Parent = children
			divider.Position = UDim2.fromOffset(0, 26)
			divider.Parent = label
		end
	end
}

mainapi.Components = setmetatable(components, {
	__newindex = function(self, ind, func)
		for _, v in mainapi.Modules do
			rawset(v, 'Create'..ind, function(_, settings)
				return func(settings, v.Children, v)
			end)
		end

		if mainapi.Legit then
			for _, v in mainapi.Legit.Modules do
				rawset(v, 'Create'..ind, function(_, settings)
					return func(settings, v.Children, v)
				end)
			end
		end

		rawset(self, ind, func)
	end
})

local function registerSimpleComponent(name, func)
	mainapi.Components[name] = func
end

local function createOptionRow(settings, parent)
	local row = Instance.new('TextButton')
	row.Name = (settings.Name or 'Option')..'Option'
	row.Size = UDim2.fromOffset(220, 40)
	row.BackgroundColor3 = uipallet.Main
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = '          '..tostring(settings.Name or 'Option')
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = color.Dark(uipallet.Text, 0.16)
	row.TextSize = 14
	row.FontFace = uipallet.Font
	row.Parent = parent
	return row
end

local function currentGuiColor()
	local guiColor = mainapi.GUIColor
	return guiColor and guiColor.Hue or 0.46, guiColor and guiColor.Sat or 0.96, guiColor and guiColor.Value or 0.52
end

local function storeOption(owner, settings, api)
	api.Name = settings.Name
	owner.Options = owner.Options or {}
	if settings.Name then owner.Options[settings.Name] = api end
	return api
end

registerSimpleComponent('Button', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local row = createOptionRow(settings, parent)
	row.MouseButton1Click:Connect(function()
		task.spawn(settings.Function)
	end)
	return storeOption(owner, settings, {Type = 'Button', Object = row, Save = false})
end)

registerSimpleComponent('Toggle', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local api = {Type = 'Toggle', Enabled = false}
	local row = createOptionRow(settings, parent)
	local knob = Instance.new('Frame')
	knob.Name = 'Knob'
	knob.Size = UDim2.fromOffset(22, 12)
	knob.Position = UDim2.new(1, -32, 0, 14)
	knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
	knob.Parent = row
	addCorner(knob, UDim.new(1, 0))
	local dot = Instance.new('Frame')
	dot.Name = 'Dot'
	dot.Size = UDim2.fromOffset(8, 8)
	dot.Position = UDim2.fromOffset(2, 2)
	dot.BackgroundColor3 = uipallet.Main
	dot.Parent = knob
	addCorner(dot, UDim.new(1, 0))
	function api:SetValue(value, silent)
		self.Enabled = value == true
		local hue, sat, val = currentGuiColor()
		knob.BackgroundColor3 = self.Enabled and Color3.fromHSV(hue, sat, val) or color.Light(uipallet.Main, 0.14)
		dot.Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
		if not silent then settings.Function(self.Enabled) end
	end
	function api:Toggle()
		self:SetValue(not self.Enabled)
	end
	function api:Save(tab)
		tab[settings.Name] = {Enabled = self.Enabled}
	end
	function api:Load(tab)
		self:SetValue(tab and tab.Enabled, true)
	end
	row.MouseButton1Click:Connect(function() api:Toggle() end)
	api.Object = row
	storeOption(owner, settings, api)
	if settings.Default then api:SetValue(true) end
	return api
end)

registerSimpleComponent('Slider', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local api = {
		Type = 'Slider',
		Min = settings.Min or 0,
		Max = settings.Max or 100,
		Value = settings.Default or settings.Min or 0
	}
	local row = createOptionRow(settings, parent)
	local value = Instance.new('TextLabel')
	value.Name = 'Value'
	value.Size = UDim2.fromOffset(70, 40)
	value.Position = UDim2.new(1, -78, 0, 0)
	value.BackgroundTransparency = 1
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = color.Dark(uipallet.Text, 0.16)
	value.TextSize = 13
	value.FontFace = uipallet.Font
	value.Parent = row
	function api:SetValue(newValue, silent)
		self.Value = math.clamp(tonumber(newValue) or self.Value, self.Min, self.Max)
		value.Text = tostring(self.Value)
		if not silent then settings.Function(self.Value) end
	end
	function api:Save(tab)
		tab[settings.Name] = {Value = self.Value}
	end
	function api:Load(tab)
		self:SetValue(tab and tab.Value, true)
	end
	row.MouseButton1Click:Connect(function()
		local step = settings.Step or 1
		api:SetValue(api.Value + step > api.Max and api.Min or api.Value + step)
	end)
	api.Object = row
	storeOption(owner, settings, api)
	api:SetValue(api.Value, true)
	return api
end)

registerSimpleComponent('Dropdown', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local list = settings.List or settings.Values or {}
	local api = {Type = 'Dropdown', List = list, Value = settings.Default or list[1] or ''}
	local row = createOptionRow(settings, parent)
	local value = Instance.new('TextLabel')
	value.Name = 'Value'
	value.Size = UDim2.fromOffset(95, 40)
	value.Position = UDim2.new(1, -103, 0, 0)
	value.BackgroundTransparency = 1
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = color.Dark(uipallet.Text, 0.16)
	value.TextSize = 13
	value.FontFace = uipallet.Font
	value.Parent = row
	function api:SetValue(newValue, silent)
		self.Value = newValue or self.Value
		value.Text = tostring(self.Value)
		if not silent then settings.Function(self.Value) end
	end
	function api:Save(tab)
		tab[settings.Name] = {Value = self.Value}
	end
	function api:Load(tab)
		self:SetValue(tab and tab.Value, true)
	end
	row.MouseButton1Click:Connect(function()
		if #list <= 0 then return end
		local ind = table.find(list, api.Value) or 0
		api:SetValue(list[(ind % #list) + 1] or api.Value)
	end)
	api.Object = row
	storeOption(owner, settings, api)
	api:SetValue(api.Value, true)
	return api
end)

registerSimpleComponent('TextBox', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local api = {Type = 'TextBox', Value = settings.Default or ''}
	local row = createOptionRow(settings, parent)
	local box = Instance.new('TextBox')
	box.Name = 'Box'
	box.Size = UDim2.new(1, -20, 0, 24)
	box.Position = UDim2.fromOffset(10, 38)
	box.BackgroundTransparency = 0.9
	box.Text = tostring(api.Value)
	box.PlaceholderText = settings.Placeholder or ''
	box.TextColor3 = uipallet.Text
	box.TextSize = 13
	box.FontFace = uipallet.Font
	box.ClearTextOnFocus = false
	box.Parent = row
	row.Size = UDim2.fromOffset(220, 68)
	function api:SetValue(newValue, silent)
		self.Value = tostring(newValue or '')
		box.Text = self.Value
		if not silent then settings.Function(self.Value) end
	end
	function api:Save(tab)
		tab[settings.Name] = {Value = self.Value}
	end
	function api:Load(tab)
		self:SetValue(tab and tab.Value, true)
	end
	box.FocusLost:Connect(function()
		api:SetValue(box.Text)
	end)
	api.Object = row
	storeOption(owner, settings, api)
	return api
end)

registerSimpleComponent('TextList', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local api = {Type = 'TextList', List = settings.List or {}, ListEnabled = settings.ListEnabled or {}}
	local row = createOptionRow(settings, parent)
	function api:Save(tab)
		tab[settings.Name] = {List = self.List, ListEnabled = self.ListEnabled}
	end
	function api:Load(tab)
		self.List = tab and tab.List or self.List
		self.ListEnabled = tab and tab.ListEnabled or self.ListEnabled
	end
	api.Object = row
	return storeOption(owner, settings, api)
end)

registerSimpleComponent('ColorSlider', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local api = {
		Type = 'ColorSlider',
		Hue = settings.Hue or 0,
		Sat = settings.Sat or 1,
		Value = settings.Value or 1,
		Rainbow = false
	}
	local row = createOptionRow(settings, parent)
	local preview = Instance.new('Frame')
	preview.Name = 'Preview'
	preview.Size = UDim2.fromOffset(18, 18)
	preview.Position = UDim2.new(1, -28, 0, 11)
	preview.Parent = row
	addCorner(preview, UDim.new(1, 0))
	function api:SetValue(hue, sat, val, silent)
		self.Hue = tonumber(hue) or self.Hue
		self.Sat = tonumber(sat) or self.Sat
		self.Value = tonumber(val) or self.Value
		preview.BackgroundColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
		if not silent then settings.Function(self.Hue, self.Sat, self.Value, 1) end
	end
	function api:Color(hue, sat, val)
		self:SetValue(hue, sat, val, true)
	end
	function api:Save(tab)
		tab[settings.Name] = {Hue = self.Hue, Sat = self.Sat, Value = self.Value}
	end
	function api:Load(tab)
		if tab then self:SetValue(tab.Hue, tab.Sat, tab.Value, true) end
	end
	row.MouseButton1Click:Connect(function()
		api:SetValue((api.Hue + 0.08) % 1, api.Sat, api.Value)
	end)
	api.Object = row
	storeOption(owner, settings, api)
	api:SetValue(api.Hue, api.Sat, api.Value, true)
	return api
end)

registerSimpleComponent('Font', function(settings, parent, owner)
	settings.Function = settings.Function or function() end
	local fonts = settings.List or {'Arial', 'Gotham', 'Roboto', 'RobotoMono', 'SourceSans'}
	local defaultName = settings.Default or fonts[1] or 'Arial'
	if settings.Blacklist == defaultName then
		defaultName = fonts[2] or 'Gotham'
	end
	local api = {
		Type = 'Font',
		Value = Font.fromEnum(Enum.Font[defaultName] or Enum.Font.Arial),
		FontName = defaultName
	}
	local row = createOptionRow(settings, parent)
	local value = Instance.new('TextLabel')
	value.Name = 'Value'
	value.Size = UDim2.fromOffset(100, 40)
	value.Position = UDim2.new(1, -108, 0, 0)
	value.BackgroundTransparency = 1
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.TextColor3 = color.Dark(uipallet.Text, 0.16)
	value.TextSize = 13
	value.FontFace = uipallet.Font
	value.Parent = row
	function api:SetValue(fontName, silent)
		fontName = tostring(fontName or self.FontName)
		if settings.Blacklist == fontName then fontName = defaultName end
		self.FontName = fontName
		self.Value = Font.fromEnum(Enum.Font[fontName] or Enum.Font.Arial)
		value.Text = fontName
		if not silent then settings.Function(self.Value) end
	end
	function api:Save(tab)
		tab[settings.Name] = {Value = self.FontName}
	end
	function api:Load(tab)
		self:SetValue(tab and tab.Value, true)
	end
	row.MouseButton1Click:Connect(function()
		local ind = table.find(fonts, api.FontName) or 0
		api:SetValue(fonts[(ind % #fonts) + 1] or api.FontName)
	end)
	api.Object = row
	storeOption(owner, settings, api)
	api:SetValue(api.FontName, true)
	return api
end)

registerSimpleComponent('TwoSlider', function(settings, parent, owner)
	local api = mainapi.Components.Slider(settings, parent, owner)
	api.Type = 'TwoSlider'
	api.Value2 = settings.Default2 or settings.Default or api.Value
	return api
end)

registerSimpleComponent('Targets', function(settings, parent, owner)
	local api = mainapi.Components.TextList(settings, parent, owner)
	api.Type = 'Targets'
	api.Players = true
	api.NPCs = true
	return api
end)

registerSimpleComponent('HotbarList', function(settings, parent, owner)
	local api = mainapi.Components.TextList(settings, parent, owner)
	api.Type = 'HotbarList'
	return api
end)

task.spawn(function()
	repeat
		local hue = tick() * (0.2 * mainapi.RainbowSpeed.Value) % 1
		for _, v in mainapi.RainbowTable do
			if v.Type == 'GUISlider' then
				v:SetValue(mainapi:Color(hue))
			else
				v:SetValue(hue)
			end
		end
		task.wait(1 / mainapi.RainbowUpdateSpeed.Value)
	until mainapi.Loaded == nil
end)

function mainapi:BlurCheck()
	if self.ThreadFix then
		setthreadidentity(8)
		runService:SetRobloxGuiFocused((clickgui.Visible or guiService:GetErrorType() ~= Enum.ConnectionError.OK) and self.Blur.Enabled)
	end
end

addMaid(mainapi)

function mainapi:CreateGUI()
	local categoryapi = {
		Type = 'MainWindow',
		Buttons = {},
		Options = {}
	}

	local window = Instance.new('TextButton')
	window.Name = 'GUICategory'
	window.Position = UDim2.fromOffset(6, 60)
	window.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	window.AutoButtonColor = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local logo = Instance.new('ImageLabel')
	logo.Name = 'BadLogo'
	logo.Size = UDim2.fromOffset(62, 18)
	logo.Position = UDim2.fromOffset(11, 10)
	logo.BackgroundTransparency = 1
	logo.Image = getcustomasset('badscript/assets/new/guiBad.png')
	logo.ImageColor3 = select(3, uipallet.Main:ToHSV()) > 0.5 and uipallet.Text or Color3.new(1, 1, 1)
	logo.Parent = window
	local logov4 = Instance.new('ImageLabel')
	logov4.Name = 'V4Logo'
	logov4.Size = UDim2.fromOffset(28, 16)
	logov4.Position = UDim2.new(1, 1, 0, 1)
	logov4.BackgroundTransparency = 1
	logov4.Image = getcustomasset('badscript/assets/new/guiv4.png')
	logov4.Parent = logo
	local children = Instance.new('Frame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -33)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	local settingsbutton = Instance.new('TextButton')
	settingsbutton.Name = 'Settings'
	settingsbutton.Size = UDim2.fromOffset(40, 40)
	settingsbutton.Position = UDim2.new(1, -40, 0, 0)
	settingsbutton.BackgroundTransparency = 1
	settingsbutton.Text = ''
	settingsbutton.Parent = window
	addTooltip(settingsbutton, 'Open settings')
	local settingsicon = Instance.new('ImageLabel')
	settingsicon.Size = UDim2.fromOffset(14, 14)
	settingsicon.Position = UDim2.fromOffset(15, 12)
	settingsicon.BackgroundTransparency = 1
	settingsicon.Image = getcustomasset('badscript/assets/new/guisettings.png')
	settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	settingsicon.Parent = settingsbutton
	local discordbutton = Instance.new('ImageButton')
	discordbutton.Size = UDim2.fromOffset(16, 16)
	discordbutton.Position = UDim2.new(1, -56, 0, 11)
	discordbutton.BackgroundTransparency = 1
	discordbutton.Image = getcustomasset('badscript/assets/new/discord.png')
	discordbutton.Parent = window
	addTooltip(discordbutton, 'Join discord')
	local settingspane = Instance.new('TextButton')
	settingspane.Size = UDim2.fromScale(1, 1)
	settingspane.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	settingspane.AutoButtonColor = false
	settingspane.Visible = false
	settingspane.Text = ''
	settingspane.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -36, 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
	title.BackgroundTransparency = 1
	title.Text = 'Settings'
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = settingspane
	local close = addCloseButton(settingspane)
	local back = Instance.new('ImageButton')
	back.Name = 'Back'
	back.Size = UDim2.fromOffset(16, 16)
	back.Position = UDim2.fromOffset(11, 13)
	back.BackgroundTransparency = 1
	back.Image = getcustomasset('badscript/assets/new/back.png')
	back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	back.Parent = settingspane
	local settingsversion = Instance.new('TextLabel')
	settingsversion.Name = 'Version'
	settingsversion.Size = UDim2.new(1, 0, 0, 16)
	settingsversion.Position = UDim2.new(0, 0, 1, -16)
	settingsversion.BackgroundTransparency = 1
	settingsversion.Text = 'Bad '..mainapi.Version..' '..(
		isfile('badscript/profiles/commit.txt') and readfile('badscript/profiles/commit.txt'):sub(1, 6) or ''
	)..' '
	settingsversion.TextColor3 = color.Dark(uipallet.Text, 0.43)
	settingsversion.TextXAlignment = Enum.TextXAlignment.Right
	settingsversion.TextSize = 10
	settingsversion.FontFace = uipallet.Font
	settingsversion.Parent = settingspane
	addCorner(settingspane)
	local settingschildren = Instance.new('Frame')
	settingschildren.Name = 'Children'
	settingschildren.Size = UDim2.new(1, 0, 1, -57)
	settingschildren.Position = UDim2.fromOffset(0, 41)
	settingschildren.BackgroundColor3 = uipallet.Main
	settingschildren.BorderSizePixel = 0
	settingschildren.Parent = settingspane
	local settingswindowlist = Instance.new('UIListLayout')
	settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
	settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	settingswindowlist.Parent = settingschildren
	categoryapi.Object = window

	function categoryapi:CreateBind()
		local optionapi = {Bind = {'RightShift'}}

		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          Rebind GUI'
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		addTooltip(button, 'Change the bind of the GUI')
		local bind = Instance.new('TextButton')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -10, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Text = ''
		bind.Parent = button
		addTooltip(bind, 'Click to bind')
		addCorner(bind, UDim.new(0, 4))
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(12, 12)
		icon.Position = UDim2.new(0.5, -6, 0, 5)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('badscript/assets/new/bind.png')
		icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		icon.Parent = bind
		local label = Instance.new('TextLabel')
		label.Name = 'Text'
		label.Size = UDim2.fromScale(1, 1)
		label.Position = UDim2.fromOffset(0, 1)
		label.BackgroundTransparency = 1
		label.Visible = false
		label.Text = ''
		label.TextColor3 = color.Dark(uipallet.Text, 0.43)
		label.TextSize = 12
		label.FontFace = uipallet.Font
		label.Parent = bind

		function optionapi:SetBind(tab)
			mainapi.Keybind = #tab <= 0 and mainapi.Keybind or table.clone(tab)
			self.Bind = mainapi.Keybind
			if mainapi.BadButton then
				mainapi.BadButton:Destroy()
				mainapi.BadButton = nil
			end

			bind.Visible = true
			label.Visible = true
			icon.Visible = false
			label.Text = table.concat(mainapi.Keybind, ' + '):upper()
			bind.Size = UDim2.fromOffset(math.max(getfontsize(label.Text, label.TextSize, label.Font).X + 10, 20), 21)
		end

		bind.MouseEnter:Connect(function()
			label.Visible = false
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('badscript/assets/new/edit.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		bind.MouseLeave:Connect(function()
			label.Visible = true
			icon.Visible = not label.Visible
			icon.Image = getcustomasset('badscript/assets/new/bind.png')
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		bind.MouseButton1Click:Connect(function()
			mainapi.Binding = optionapi
		end)

		categoryapi.Options.Bind = optionapi

		return optionapi
	end

	function categoryapi:CreateButton(categorysettings)
		local optionapi = {
			Enabled = false,
			Index = getTableSize(categoryapi.Buttons)
		}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = (categorysettings.Icon and '                                 ' or '             ')..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = children
		local icon
		if categorysettings.Icon then
			icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = categorysettings.Size
			icon.Position = UDim2.fromOffset(13, 13)
			icon.BackgroundTransparency = 1
			icon.Image = categorysettings.Icon
			icon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
			icon.Parent = button
		end
		if categorysettings.Name == 'Profiles' then
			local label = Instance.new('TextLabel')
			label.Name = 'ProfileLabel'
			label.Size = UDim2.fromOffset(53, 24)
			label.Position = UDim2.new(1, -36, 0, 8)
			label.AnchorPoint = Vector2.new(1, 0)
			label.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
			label.Text = 'default'
			label.TextColor3 = color.Dark(uipallet.Text, 0.29)
			label.TextSize = 12
			label.FontFace = uipallet.Font
			label.Parent = button
			addCorner(label)
			mainapi.ProfileLabel = label
		end
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('badscript/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		optionapi.Name = categorysettings.Name
		optionapi.Icon = icon
		optionapi.Object = button

		function optionapi:Toggle()
			self.Enabled = not self.Enabled
			tween:Tween(arrow, uipallet.Tween, {
				Position = UDim2.new(1, self.Enabled and -14 or -20, 0, 16)
			})
			button.TextColor3 = self.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or uipallet.Text
			if icon then
				icon.ImageColor3 = button.TextColor3
			end
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			categorysettings.Window.Visible = self.Enabled
		end

		button.MouseEnter:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = uipallet.Text
				if buttonicon then buttonicon.ImageColor3 = uipallet.Text end
				button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		button.MouseLeave:Connect(function()
			if not optionapi.Enabled then
				button.TextColor3 = color.Dark(uipallet.Text, 0.16)
				if buttonicon then buttonicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
				button.BackgroundColor3 = uipallet.Main
			end
		end)
		button.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)

		categoryapi.Buttons[categorysettings.Name] = optionapi

		return optionapi
	end

	function categoryapi:CreateDivider(text)
		return components.Divider(children, text)
	end

	function categoryapi:CreateOverlayBar()
		local optionapi = {Toggles = {}}

		local bar = Instance.new('Frame')
		bar.Name = 'Overlays'
		bar.Size = UDim2.fromOffset(220, 36)
		bar.BackgroundColor3 = uipallet.Main
		bar.BorderSizePixel = 0
		bar.Parent = children
		components.Divider(bar)
		local button = Instance.new('ImageButton')
		button.Size = UDim2.fromOffset(24, 24)
		button.Position = UDim2.new(1, -29, 0, 7)
		button.BackgroundTransparency = 1
		button.AutoButtonColor = false
		button.Image = getcustomasset('badscript/assets/new/overlaysicon.png')
		button.ImageColor3 = color.Light(uipallet.Main, 0.37)
		button.Parent = bar
		addCorner(button, UDim.new(1, 0))
		addTooltip(button, 'Open overlays menu')
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local window = Instance.new('Frame')
		window.Size = UDim2.fromOffset(220, 42)
		window.Position = UDim2.fromScale(0, 1)
		window.BackgroundColor3 = uipallet.Main
		window.Parent = shadow
		addCorner(window)
		local icon = Instance.new('ImageLabel')
		icon.Name = 'Icon'
		icon.Size = UDim2.fromOffset(14, 12)
		icon.Position = UDim2.fromOffset(10, 13)
		icon.BackgroundTransparency = 1
		icon.Image = getcustomasset('badscript/assets/new/overlaystab.png')
		icon.ImageColor3 = uipallet.Text
		icon.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 38)
		title.Position = UDim2.fromOffset(36, 0)
		title.BackgroundTransparency = 1
		title.Text = 'Overlays'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 15
		title.FontFace = uipallet.Font
		title.Parent = window
		local close = addCloseButton(window, 7)
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, 37)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		divider.BorderSizePixel = 0
		divider.Parent = window
		local childrentoggle = Instance.new('Frame')
		childrentoggle.Position = UDim2.fromOffset(0, 38)
		childrentoggle.BackgroundTransparency = 1
		childrentoggle.Parent = window
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = childrentoggle

		function optionapi:CreateToggle(togglesettings)
			local toggleapi = {
				Enabled = false,
				Index = getTableSize(optionapi.Toggles)
			}

			local hovered = false
			local toggle = Instance.new('TextButton')
			toggle.Name = togglesettings.Name..'Toggle'
			toggle.Size = UDim2.new(1, 0, 0, 40)
			toggle.BackgroundTransparency = 1
			toggle.AutoButtonColor = false
			toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			toggle.TextXAlignment = Enum.TextXAlignment.Left
			toggle.TextColor3 = color.Dark(uipallet.Text, 0.16)
			toggle.TextSize = 14
			toggle.FontFace = uipallet.Font
			toggle.Parent = childrentoggle
			local icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = togglesettings.Size
			icon.Position = togglesettings.Position
			icon.BackgroundTransparency = 1
			icon.Image = togglesettings.Icon
			icon.ImageColor3 = uipallet.Text
			icon.Parent = toggle
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(22, 12)
			knob.Position = UDim2.new(1, -30, 0, 14)
			knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			knob.Parent = toggle
			addCorner(knob, UDim.new(1, 0))
			local knobmain = knob:Clone()
			knobmain.Size = UDim2.fromOffset(8, 8)
			knobmain.Position = UDim2.fromOffset(2, 2)
			knobmain.BackgroundColor3 = uipallet.Main
			knobmain.Parent = knob
			toggleapi.Object = toggle

			function toggleapi:Toggle()
				self.Enabled = not self.Enabled
				tween:Tween(knob, uipallet.Tween, {
					BackgroundColor3 = self.Enabled and Color3.fromHSV(
						mainapi.GUIColor.Hue,
						mainapi.GUIColor.Sat,
						mainapi.GUIColor.Value
					) or (hovered and color.Light(uipallet.Main, 0.37) or color.Light(uipallet.Main, 0.14))
				})
				tween:Tween(knobmain, uipallet.Tween, {
					Position = UDim2.fromOffset(self.Enabled and 12 or 2, 2)
				})
				togglesettings.Function(self.Enabled)
			end

			scale:GetPropertyChangedSignal('Scale'):Connect(function()
				toggle.Text = string.rep(' ', 33 * scale.Scale)..togglesettings.Name
			end)
			toggle.MouseEnter:Connect(function()
				hovered = true
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.37)
					})
				end
			end)
			toggle.MouseLeave:Connect(function()
				hovered = false
				if not toggleapi.Enabled then
					tween:Tween(knob, uipallet.Tween, {
						BackgroundColor3 = color.Light(uipallet.Main, 0.14)
					})
				end
			end)
			toggle.MouseButton1Click:Connect(function()
				toggleapi:Toggle()
			end)

			table.insert(optionapi.Toggles, toggleapi)

			return toggleapi
		end

		button.MouseEnter:Connect(function()
			button.ImageColor3 = uipallet.Text
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 0.9
			})
		end)
		button.MouseLeave:Connect(function()
			button.ImageColor3 = color.Light(uipallet.Main, 0.37)
			tween:Tween(button, uipallet.Tween, {
				BackgroundTransparency = 1
			})
		end)
		button.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.new(0, 0, 1, -(window.Size.Y.Offset))
			})
		end)
		close.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(window, uipallet.Tween, {
				Position = UDim2.fromScale(0, 1)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 605))
			childrentoggle.Size = UDim2.fromOffset(220, window.Size.Y.Offset - 5)
		end)

		mainapi.Overlays = optionapi

		return optionapi
	end

	function categoryapi:CreateSettingsDivider()
		components.Divider(settingschildren)
	end

	function categoryapi:CreateSettingsPane(categorysettings)
		local optionapi = {}

		local button = Instance.new('TextButton')
		button.Name = categorysettings.Name
		button.Size = UDim2.fromOffset(220, 40)
		button.BackgroundColor3 = uipallet.Main
		button.BorderSizePixel = 0
		button.AutoButtonColor = false
		button.Text = '          '..categorysettings.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.TextColor3 = color.Dark(uipallet.Text, 0.16)
		button.TextSize = 14
		button.FontFace = uipallet.Font
		button.Parent = settingschildren
		local arrow = Instance.new('ImageLabel')
		arrow.Name = 'Arrow'
		arrow.Size = UDim2.fromOffset(4, 8)
		arrow.Position = UDim2.new(1, -20, 0, 16)
		arrow.BackgroundTransparency = 1
		arrow.Image = getcustomasset('badscript/assets/new/expandright.png')
		arrow.ImageColor3 = color.Light(uipallet.Main, 0.37)
		arrow.Parent = button
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.fromScale(1, 1)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Visible = false
		settingspane.Text = ''
		settingspane.Parent = window
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -36, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 11)
		title.BackgroundTransparency = 1
		title.Text = categorysettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = settingspane
		local close = addCloseButton(settingspane)
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('badscript/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('Frame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -57)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.Parent = settingspane
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.BackgroundColor3 = Color3.new(1, 1, 1)
		divider.BackgroundTransparency = 0.928
		divider.BorderSizePixel = 0
		divider.Parent = settingschildren
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren

		for i, v in components do
			optionapi['Create'..i] = function(_, settings)
				return v(settings, settingschildren, categoryapi)
			end
		end

		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		button.MouseEnter:Connect(function()
			button.TextColor3 = uipallet.Text
			button.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		end)
		button.MouseLeave:Connect(function()
			button.TextColor3 = color.Dark(uipallet.Text, 0.16)
			button.BackgroundColor3 = uipallet.Main
		end)
		button.MouseButton1Click:Connect(function()
			settingspane.Visible = true
		end)
		close.MouseButton1Click:Connect(function()
			settingspane.Visible = false
		end)
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			window.Size = UDim2.fromOffset(220, 45 + windowlist.AbsoluteContentSize.Y / scale.Scale)
			for _, v in categoryapi.Buttons do
				if v.Icon then
					v.Object.Text = string.rep(' ', 33 * scale.Scale)..v.Name
				end
			end
		end)

		return optionapi
	end

	function categoryapi:CreateGUISlider(optionsettings)
		local optionapi = {
			Type = 'GUISlider',
			Notch = 4,
			Hue = 0.46,
			Sat = 0.96,
			Value = 0.52,
			Rainbow = false,
			CustomColor = false
		}
		local slidercolors = {
			Color3.fromRGB(250, 50, 56),
			Color3.fromRGB(242, 99, 33),
			Color3.fromRGB(252, 179, 22),
			Color3.fromRGB(5, 133, 104),
			Color3.fromRGB(47, 122, 229),
			Color3.fromRGB(126, 84, 217),
			Color3.fromRGB(232, 96, 152)
		}
		local slidercolorpos = {
			4,
			33,
			62,
			90,
			119,
			148,
			177
		}

		local function createSlider(name, gradientColor)
			local slider = Instance.new('TextButton')
			slider.Name = optionsettings.Name..'Slider'..name
			slider.Size = UDim2.fromOffset(220, 50)
			slider.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			slider.BorderSizePixel = 0
			slider.AutoButtonColor = false
			slider.Visible = false
			slider.Text = ''
			slider.Parent = settingschildren
			local title = Instance.new('TextLabel')
			title.Name = 'Title'
			title.Size = UDim2.fromOffset(60, 30)
			title.Position = UDim2.fromOffset(10, 2)
			title.BackgroundTransparency = 1
			title.Text = name
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.TextColor3 = color.Dark(uipallet.Text, 0.16)
			title.TextSize = 11
			title.FontFace = uipallet.Font
			title.Parent = slider
			local holder = Instance.new('Frame')
			holder.Name = 'Slider'
			holder.Size = UDim2.fromOffset(200, 2)
			holder.Position = UDim2.fromOffset(10, 37)
			holder.BackgroundColor3 = Color3.new(1, 1, 1)
			holder.BorderSizePixel = 0
			holder.Parent = slider
			local uigradient = Instance.new('UIGradient')
			uigradient.Color = gradientColor
			uigradient.Parent = holder
			local fill = holder:Clone()
			fill.Name = 'Fill'
			fill.Size = UDim2.fromScale(math.clamp(1, 0.04, 0.96), 1)
			fill.Position = UDim2.new()
			fill.BackgroundTransparency = 1
			fill.Parent = holder
			local knobframe = Instance.new('Frame')
			knobframe.Name = 'Knob'
			knobframe.Size = UDim2.fromOffset(24, 4)
			knobframe.Position = UDim2.fromScale(1, 0.5)
			knobframe.AnchorPoint = Vector2.new(0.5, 0.5)
			knobframe.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			knobframe.BorderSizePixel = 0
			knobframe.Parent = fill
			local knob = Instance.new('Frame')
			knob.Name = 'Knob'
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.fromScale(0.5, 0.5)
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.BackgroundColor3 = uipallet.Text
			knob.Parent = knobframe
			addCorner(knob, UDim.new(1, 0))
			if name == 'Custom color' then
				local reset = Instance.new('TextButton')
				reset.Size = UDim2.fromOffset(45, 20)
				reset.Position = UDim2.new(1, -52, 0, 5)
				reset.BackgroundTransparency = 1
				reset.Text = 'RESET'
				reset.TextColor3 = color.Dark(uipallet.Text, 0.16)
				reset.TextSize = 11
				reset.FontFace = uipallet.Font
				reset.Parent = slider
				reset.MouseButton1Click:Connect(function()
					optionapi:SetValue(nil, nil, nil, 4)
				end)
			end

			slider.InputBegan:Connect(function(inputObj)
				if
					(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
					and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
				then
					local changed = inputService.InputChanged:Connect(function(input)
						if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
							local value = math.clamp((input.Position.X - holder.AbsolutePosition.X) / holder.AbsoluteSize.X, 0, 1)
							optionapi:SetValue(
								name == 'Custom color' and value or nil,
								name == 'Saturation' and value or nil,
								name == 'Vibrance' and value or nil,
								name == 'Opacity' and value or nil
							)
						end
					end)

					local ended
					ended = inputObj.Changed:Connect(function()
						if inputObj.UserInputState == Enum.UserInputState.End then
							if changed then
								changed:Disconnect()
							end
							if ended then
								ended:Disconnect()
							end
						end
					end)
				end
			end)
			slider.MouseEnter:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(16, 16)
				})
			end)
			slider.MouseLeave:Connect(function()
				tween:Tween(knob, uipallet.Tween, {
					Size = UDim2.fromOffset(14, 14)
				})
			end)

			return slider
		end

		local slider = Instance.new('TextButton')
		slider.Name = optionsettings.Name..'Slider'
		slider.Size = UDim2.fromOffset(220, 50)
		slider.BackgroundTransparency = 1
		slider.AutoButtonColor = false
		slider.Text = ''
		slider.Parent = settingschildren
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.fromOffset(60, 30)
		title.Position = UDim2.fromOffset(10, 2)
		title.BackgroundTransparency = 1
		title.Text = optionsettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.16)
		title.TextSize = 11
		title.FontFace = uipallet.Font
		title.Parent = slider
		local holder = Instance.new('Frame')
		holder.Name = 'Slider'
		holder.Size = UDim2.fromOffset(200, 2)
		holder.Position = UDim2.fromOffset(10, 37)
		holder.BackgroundTransparency = 1
		holder.BorderSizePixel = 0
		holder.Parent = slider
		local colornum = 0
		for i, color in slidercolors do
			local colorframe = Instance.new('Frame')
			colorframe.Size = UDim2.fromOffset(27 + (((i + 1) % 2) == 0 and 1 or 0), 2)
			colorframe.Position = UDim2.fromOffset(colornum, 0)
			colorframe.BackgroundColor3 = color
			colorframe.BorderSizePixel = 0
			colorframe.Parent = holder
			colornum += (colorframe.Size.X.Offset + 1)
		end
		local preview = Instance.new('ImageButton')
		preview.Name = 'Preview'
		preview.Size = UDim2.fromOffset(12, 12)
		preview.Position = UDim2.new(1, -22, 0, 10)
		preview.BackgroundTransparency = 1
		preview.Image = getcustomasset('badscript/assets/new/colorpreview.png')
		preview.ImageColor3 = Color3.fromHSV(optionapi.Hue, 1, 1)
		preview.Parent = slider
		local valuebox = Instance.new('TextBox')
		valuebox.Name = 'Box'
		valuebox.Size = UDim2.fromOffset(60, 15)
		valuebox.Position = UDim2.new(1, -69, 0, 9)
		valuebox.BackgroundTransparency = 1
		valuebox.Visible = false
		valuebox.Text = ''
		valuebox.TextXAlignment = Enum.TextXAlignment.Right
		valuebox.TextColor3 = color.Dark(uipallet.Text, 0.16)
		valuebox.TextSize = 11
		valuebox.FontFace = uipallet.Font
		valuebox.ClearTextOnFocus = true
		valuebox.Parent = slider
		local expandbutton = Instance.new('TextButton')
		expandbutton.Name = 'Expand'
		expandbutton.Size = UDim2.fromOffset(17, 13)
		expandbutton.Position = UDim2.new(0, getfontsize(title.Text, title.TextSize, title.Font).X + 11, 0, 7)
		expandbutton.BackgroundTransparency = 1
		expandbutton.Text = ''
		expandbutton.Parent = slider
		local expandicon = Instance.new('ImageLabel')
		expandicon.Name = 'Expand'
		expandicon.Size = UDim2.fromOffset(9, 5)
		expandicon.Position = UDim2.fromOffset(4, 4)
		expandicon.BackgroundTransparency = 1
		expandicon.Image = getcustomasset('badscript/assets/new/expandicon.png')
		expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		expandicon.Parent = expandbutton
		local rainbow = Instance.new('TextButton')
		rainbow.Name = 'Rainbow'
		rainbow.Size = UDim2.fromOffset(12, 12)
		rainbow.Position = UDim2.new(1, -42, 0, 10)
		rainbow.BackgroundTransparency = 1
		rainbow.Text = ''
		rainbow.Parent = slider
		local rainbow1 = Instance.new('ImageLabel')
		rainbow1.Size = UDim2.fromOffset(12, 12)
		rainbow1.BackgroundTransparency = 1
		rainbow1.Image = getcustomasset('badscript/assets/new/rainbow_1.png')
		rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
		rainbow1.Parent = rainbow
		local rainbow2 = rainbow1:Clone()
		rainbow2.Image = getcustomasset('badscript/assets/new/rainbow_2.png')
		rainbow2.Parent = rainbow
		local rainbow3 = rainbow1:Clone()
		rainbow3.Image = getcustomasset('badscript/assets/new/rainbow_3.png')
		rainbow3.Parent = rainbow
		local rainbow4 = rainbow1:Clone()
		rainbow4.Image = getcustomasset('badscript/assets/new/rainbow_4.png')
		rainbow4.Parent = rainbow
		local knob = Instance.new('ImageLabel')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(26, 12)
		knob.Position = UDim2.fromOffset(slidercolorpos[4] - 3, -5)
		knob.BackgroundTransparency = 1
		knob.Image = getcustomasset('badscript/assets/new/guislider.png')
		knob.ImageColor3 = slidercolors[4]
		knob.Parent = holder
		optionsettings.Function = optionsettings.Function or function() end
		local rainbowTable = {}
		for i = 0, 1, 0.1 do
			table.insert(rainbowTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1)))
		end
		local colorSlider = createSlider('Custom color', ColorSequence.new(rainbowTable))
		local satSlider = createSlider('Saturation', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, optionapi.Value)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, 1, optionapi.Value))
		}))
		local vibSlider = createSlider('Vibrance', ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(optionapi.Hue, optionapi.Sat, 1))
		}))
		local normalknob = getcustomasset('badscript/assets/new/guislider.png')
		local rainbowknob = getcustomasset('badscript/assets/new/guisliderrain.png')
		local rainbowthread

		function optionapi:Save(tab)
			tab[optionsettings.Name] = {
				Hue = self.Hue,
				Sat = self.Sat,
				Value = self.Value,
				Notch = self.Notch,
				CustomColor = self.CustomColor,
				Rainbow = self.Rainbow
			}
		end

		function optionapi:Load(tab)
			if tab.Rainbow then
				self:Toggle()
			end
			if self.Rainbow or tab.CustomColor then
				self:SetValue(tab.Hue, tab.Sat, tab.Value)
			else
				self:SetValue(nil, nil, nil, tab.Notch)
			end
		end

		function optionapi:SetValue(h, s, v, n)
			if type(n) ~= 'number' then
				n = nil
			end

			if n then
				if self.Rainbow then
					self:Toggle()
				end
				self.CustomColor = false
				h, s, v = slidercolors[n]:ToHSV()
			else
				self.CustomColor = true
			end

			self.Hue = tonumber(h) or self.Hue or 0
			self.Sat = tonumber(s) or self.Sat or 1
			self.Value = tonumber(v) or self.Value or 1
			self.Notch = n
			preview.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
			satSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, self.Value)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, 1, self.Value))
			})
			vibSlider.Slider.UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(self.Hue, self.Sat, 1))
			})

			if self.Rainbow or self.CustomColor then
				knob.Image = rainbowknob
				knob.ImageColor3 = Color3.new(1, 1, 1)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[4] - 3, -5)
				})
			else
				knob.Image = normalknob
				knob.ImageColor3 = Color3.fromHSV(self.Hue, self.Sat, self.Value)
				tween:Tween(knob, uipallet.Tween, {
					Position = UDim2.fromOffset(slidercolorpos[n or 4] - 3, -5)
				})
			end

			if self.Rainbow then
				if h then
					colorSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
				end
				if s then
					satSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
				end
				if v then
					vibSlider.Slider.Fill.Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
				end
			else
				if h then
					tween:Tween(colorSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Hue, 0.04, 0.96), 1)
					})
				end
				if s then
					tween:Tween(satSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Sat, 0.04, 0.96), 1)
					})
				end
				if v then
					tween:Tween(vibSlider.Slider.Fill, uipallet.Tween, {
						Size = UDim2.fromScale(math.clamp(self.Value, 0.04, 0.96), 1)
					})
				end
			end
			optionsettings.Function(self.Hue, self.Sat, self.Value, 1)
		end

		function optionapi:Toggle()
			self.Rainbow = not self.Rainbow
			if rainbowthread then
				task.cancel(rainbowthread)
			end

			if self.Rainbow then
				knob.Image = rainbowknob
				table.insert(mainapi.RainbowTable, self)

				rainbow1.ImageColor3 = Color3.fromRGB(5, 127, 100)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = Color3.fromRGB(228, 125, 43)
					rainbowthread = task.delay(0.1, function()
						rainbow3.ImageColor3 = Color3.fromRGB(225, 46, 52)
						rainbowthread = nil
					end)
				end)
			else
				self:SetValue(nil, nil, nil, 4)
				knob.Image = normalknob
				local ind = table.find(mainapi.RainbowTable, self)
				if ind then
					table.remove(mainapi.RainbowTable, ind)
				end

				rainbow3.ImageColor3 = color.Light(uipallet.Main, 0.37)
				rainbowthread = task.delay(0.1, function()
					rainbow2.ImageColor3 = color.Light(uipallet.Main, 0.37)
					rainbowthread = task.delay(0.1, function()
						rainbow1.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end)
				end)
			end
		end

		expandbutton.MouseEnter:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
		end)
		expandbutton.MouseLeave:Connect(function()
			expandicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		end)
		expandbutton.MouseButton1Click:Connect(function()
			colorSlider.Visible = not colorSlider.Visible
			satSlider.Visible = colorSlider.Visible
			vibSlider.Visible = satSlider.Visible
			expandicon.Rotation = satSlider.Visible and 180 or 0
		end)
		preview.MouseButton1Click:Connect(function()
			preview.Visible = false
			valuebox.Visible = true
			valuebox:CaptureFocus()
			local text = Color3.fromHSV(optionapi.Hue, optionapi.Sat, optionapi.Value)
			valuebox.Text = math.round(text.R * 255)..', '..math.round(text.G * 255)..', '..math.round(text.B * 255)
		end)
		slider.InputBegan:Connect(function(inputObj)
			if
				(inputObj.UserInputType == Enum.UserInputType.MouseButton1 or inputObj.UserInputType == Enum.UserInputType.Touch)
				and (inputObj.Position.Y - slider.AbsolutePosition.Y) > (20 * scale.Scale)
			then
				local changed = inputService.InputChanged:Connect(function(input)
					if input.UserInputType == (inputObj.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch) then
						optionapi:SetValue(nil, nil, nil, math.clamp(math.round((input.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
					end
				end)

				local ended
				ended = inputObj.Changed:Connect(function()
					if inputObj.UserInputState == Enum.UserInputState.End then
						if changed then
							changed:Disconnect()
						end
						if ended then
							ended:Disconnect()
						end
					end
				end)
				optionapi:SetValue(nil, nil, nil, math.clamp(math.round((inputObj.Position.X - holder.AbsolutePosition.X) / scale.Scale / 27), 1, 7))
			end
		end)
		rainbow.MouseButton1Click:Connect(function()
			optionapi:Toggle()
		end)
		valuebox.FocusLost:Connect(function(enter)
			preview.Visible = true
			valuebox.Visible = false
			if enter then
				local commas = valuebox.Text:split(',')
				local suc, res = pcall(function()
					return tonumber(commas[1]) and Color3.fromRGB(
						tonumber(commas[1]),
						tonumber(commas[2]),
						tonumber(commas[3])
					) or Color3.fromHex(valuebox.Text)
				end)

				if suc then
					if optionapi.Rainbow then
						optionapi:Toggle()
					end
					optionapi:SetValue(res:ToHSV())
				end
			end
		end)

		optionapi.Object = slider
		categoryapi.Options[optionsettings.Name] = optionapi

		return optionapi
	end

	back.MouseEnter:Connect(function()
		back.ImageColor3 = uipallet.Text
	end)
	back.MouseLeave:Connect(function()
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	back.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	close.MouseButton1Click:Connect(function()
		settingspane.Visible = false
	end)
	discordbutton.MouseButton1Click:Connect(function()
		task.spawn(function()
			local body = httpService:JSONEncode({
				nonce = httpService:GenerateGUID(false),
				args = {
					invite = {code = '5gJqhQmrdS'},
					code = '5gJqhQmrdS'
				},
				cmd = 'INVITE_BROWSER'
			})

			for i = 1, 14 do
				task.spawn(function()
					request({
						Method = 'POST',
						Url = 'http://127.0.0.1:64'..(53 + i)..'/rpc?v=1',
						Headers = {
							['Content-Type'] = 'application/json',
							Origin = 'https://discord.com'
						},
						Body = body
					})
				end)
			end
		end)

		task.spawn(function()
			tooltip.Text = 'Copied!'
			setclipboard('https://discord.gg/VZEQJxMSnG')
		end)
	end)
	settingsbutton.MouseEnter:Connect(function()
		settingsicon.ImageColor3 = uipallet.Text
	end)
	settingsbutton.MouseLeave:Connect(function()
		settingsicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settingsbutton.MouseButton1Click:Connect(function()
		settingspane.Visible = true
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		window.Size = UDim2.fromOffset(220, 42 + windowlist.AbsoluteContentSize.Y / scale.Scale)
		for _, v in categoryapi.Buttons do
			if v.Icon then
				v.Object.Text = string.rep(' ', 36 * scale.Scale)..v.Name
			end
		end
	end)

	self.Categories.Main = categoryapi

	return categoryapi
end

function mainapi:CreateCategory(categorysettings)
	local categoryapi = {
		Type = 'Category',
		Expanded = false
	}

	local window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Category'
	window.Size = UDim2.fromOffset(220, 41)
	window.Position = UDim2.fromOffset(236, 60)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 20 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 18 and 40 or 33), 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 18)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('badscript/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 37)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	function categoryapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			Options = {},
			Bind = {},
			Index = getTableSize(mainapi.Modules),
			ExtraText = modulesettings.ExtraText,
			Name = modulesettings.Name,
			Category = categorysettings.Name
		}

		local hovered = false
		local modulebutton = Instance.new('TextButton')
		modulebutton.Name = modulesettings.Name
		modulebutton.Size = UDim2.fromOffset(220, 40)
		modulebutton.BackgroundColor3 = uipallet.Main
		modulebutton.BorderSizePixel = 0
		modulebutton.AutoButtonColor = false
		modulebutton.Text = '            '..modulesettings.Name
		modulebutton.TextXAlignment = Enum.TextXAlignment.Left
		modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
		modulebutton.TextSize = 14
		modulebutton.FontFace = uipallet.Font
		modulebutton.Parent = children
		local gradient = Instance.new('UIGradient')
		gradient.Rotation = 90
		gradient.Enabled = false
		gradient.Parent = modulebutton
		local modulechildren = Instance.new('Frame')
		local bind = Instance.new('TextButton')
		addTooltip(modulebutton, modulesettings.Tooltip)
		addTooltip(bind, 'Click to bind')
		bind.Name = 'Bind'
		bind.Size = UDim2.fromOffset(20, 21)
		bind.Position = UDim2.new(1, -36, 0, 9)
		bind.AnchorPoint = Vector2.new(1, 0)
		bind.BackgroundColor3 = Color3.new(1, 1, 1)
		bind.BackgroundTransparency = 0.92
		bind.BorderSizePixel = 0
		bind.AutoButtonColor = false
		bind.Visible = false
		bind.Text = ''
		addCorner(bind, UDim.new(0, 4))
		local bindicon = Instance.new('ImageLabel')
		bindicon.Name = 'Icon'
		bindicon.Size = UDim2.fromOffset(12, 12)
		bindicon.Position = UDim2.new(0.5, -6, 0, 5)
		bindicon.BackgroundTransparency = 1
		bindicon.Image = getcustomasset('badscript/assets/new/bind.png')
		bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
		bindicon.Parent = bind
		local bindtext = Instance.new('TextLabel')
		bindtext.Size = UDim2.fromScale(1, 1)
		bindtext.Position = UDim2.fromOffset(0, 1)
		bindtext.BackgroundTransparency = 1
		bindtext.Visible = false
		bindtext.Text = ''
		bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
		bindtext.TextSize = 12
		bindtext.FontFace = uipallet.Font
		bindtext.Parent = bind
		local bindcover = Instance.new('ImageLabel')
		bindcover.Name = 'Cover'
		bindcover.Size = UDim2.fromOffset(154, 40)
		bindcover.BackgroundTransparency = 1
		bindcover.Visible = false
		bindcover.Image = getcustomasset('badscript/assets/new/bindbkg.png')
		bindcover.ScaleType = Enum.ScaleType.Slice
		bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
		bindcover.Parent = modulebutton
		local bindcovertext = Instance.new('TextLabel')
		bindcovertext.Name = 'Text'
		bindcovertext.Size = UDim2.new(1, -10, 1, -3)
		bindcovertext.BackgroundTransparency = 1
		bindcovertext.Text = 'PRESS A KEY TO BIND'
		bindcovertext.TextColor3 = uipallet.Text
		bindcovertext.TextSize = 11
		bindcovertext.FontFace = uipallet.Font
		bindcovertext.Parent = bindcover
		bind.Parent = modulebutton
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(25, 40)
		dotsbutton.Position = UDim2.new(1, -25, 0, 0)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = modulebutton
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(3, 16)
		dots.Position = UDim2.fromOffset(4, 12)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('badscript/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		modulechildren.Name = modulesettings.Name..'Children'
		modulechildren.Size = UDim2.new(1, 0, 0, 0)
		modulechildren.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		modulechildren.BorderSizePixel = 0
		modulechildren.Visible = false
		modulechildren.Parent = children
		moduleapi.Children = modulechildren
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Parent = modulechildren
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.new(0, 0, 1, -1)
		divider.BackgroundColor3 = Color3.new(0.19, 0.19, 0.19)
		divider.BackgroundTransparency = 0.52
		divider.BorderSizePixel = 0
		divider.Visible = false
		divider.Parent = modulebutton
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:SetBind(tab, mouse)
			if tab.Mobile then
				createMobileButton(moduleapi, Vector2.new(tab.X, tab.Y))
				return
			end

			self.Bind = table.clone(tab)
			if mouse then
				bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO'
				bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
				task.delay(1, function()
					bindcover.Visible = false
				end)
			end

			if #tab <= 0 then
				bindtext.Visible = false
				bindicon.Visible = true
				bind.Size = UDim2.fromOffset(20, 21)
			else
				bind.Visible = true
				bindtext.Visible = true
				bindicon.Visible = false
				bindtext.Text = table.concat(tab, ' + '):upper()
				bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
			end
		end

		function moduleapi:Toggle(multiple)
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			self.Enabled = not self.Enabled
			divider.Visible = self.Enabled
			gradient.Enabled = self.Enabled
			modulebutton.TextColor3 = (hovered or modulechildren.Visible) and uipallet.Text or color.Dark(uipallet.Text, 0.16)
			modulebutton.BackgroundColor3 = (hovered or modulechildren.Visible) and color.Light(uipallet.Main, 0.02) or uipallet.Main
			dots.ImageColor3 = self.Enabled and Color3.fromRGB(50, 50, 50) or color.Light(uipallet.Main, 0.37)
			bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
			bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
			if not self.Enabled then
				for _, v in self.Connections do
					v:Disconnect()
				end
				table.clear(self.Connections)
			end
			if not multiple then
				mainapi:UpdateTextGUI()
			end
			task.spawn(modulesettings.Function, self.Enabled)
		end

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings, modulechildren, moduleapi)
			end
		end

		bind.MouseEnter:Connect(function()
			bindtext.Visible = false
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('badscript/assets/new/edit.png')
			if not moduleapi.Enabled then bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16) end
		end)
		bind.MouseLeave:Connect(function()
			bindtext.Visible = #moduleapi.Bind > 0
			bindicon.Visible = not bindtext.Visible
			bindicon.Image = getcustomasset('badscript/assets/new/bind.png')
			if not moduleapi.Enabled then
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
			end
		end)
		bind.MouseButton1Click:Connect(function()
			bindcovertext.Text = 'PRESS A KEY TO BIND'
			bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
			bindcover.Visible = true
			mainapi.Binding = moduleapi
		end)
		dotsbutton.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = uipallet.Text
			end
		end)
		dotsbutton.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
			end
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		dotsbutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		modulebutton.MouseEnter:Connect(function()
			hovered = true
			if not moduleapi.Enabled and not modulechildren.Visible then
				modulebutton.TextColor3 = uipallet.Text
				modulebutton.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseLeave:Connect(function()
			hovered = false
			if not moduleapi.Enabled and not modulechildren.Visible then
				modulebutton.TextColor3 = color.Dark(uipallet.Text, 0.16)
				modulebutton.BackgroundColor3 = uipallet.Main
			end
			bind.Visible = #moduleapi.Bind > 0 or hovered or modulechildren.Visible
		end)
		modulebutton.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		modulebutton.MouseButton2Click:Connect(function()
			modulechildren.Visible = not modulechildren.Visible
		end)
		if inputService.TouchEnabled then
			local heldbutton = false
			modulebutton.MouseButton1Down:Connect(function()
				heldbutton = true
				local holdtime, holdpos = tick(), inputService:GetMouseLocation()
				repeat
					heldbutton = (inputService:GetMouseLocation() - holdpos).Magnitude < 3
					task.wait()
				until (tick() - holdtime) > 1 or not heldbutton or not clickgui.Visible
				if heldbutton and clickgui.Visible then
					if mainapi.ThreadFix then
						setthreadidentity(8)
					end
					clickgui.Visible = false
					tooltip.Visible = false
					mainapi:BlurCheck()
					for _, mobileButton in mainapi.Modules do
						if mobileButton.Bind.Button then
							mobileButton.Bind.Button.Visible = true
						end
					end

					local touchconnection
					touchconnection = inputService.InputBegan:Connect(function(inputType)
						if inputType.UserInputType == Enum.UserInputType.Touch then
							if mainapi.ThreadFix then
								setthreadidentity(8)
							end
							createMobileButton(moduleapi, inputType.Position + Vector3.new(0, guiService:GetGuiInset().Y, 0))
							clickgui.Visible = true
							mainapi:BlurCheck()
							for _, mobileButton in mainapi.Modules do
								if mobileButton.Bind.Button then
									mobileButton.Bind.Button.Visible = false
								end
							end
							touchconnection:Disconnect()
						end
					end)
				end
			end)
			modulebutton.MouseButton1Up:Connect(function()
				heldbutton = false
			end)
		end
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			modulechildren.Size = UDim2.new(1, 0, 0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		moduleapi.Object = modulebutton
		mainapi.Modules[modulesettings.Name] = moduleapi

		local sorting = {}
		for _, v in mainapi.Modules do
			sorting[v.Category] = sorting[v.Category] or {}
			table.insert(sorting[v.Category], v.Name)
		end

		for _, sort in sorting do
			table.sort(sort)
			for i, v in sort do
				mainapi.Modules[v].Index = i
				mainapi.Modules[v].Object.LayoutOrder = i
				mainapi.Modules[v].Children.LayoutOrder = i
			end
		end

		return moduleapi
	end

	function categoryapi:Expand()
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		arrow.Rotation = self.Expanded and 0 or 180
		window.Size = UDim2.fromOffset(220, self.Expanded and math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601) or 41)
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end

	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(220, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		end
	end)

	categoryapi.Button = self.Categories.Main:CreateButton({
		Name = categorysettings.Name,
		Icon = categorysettings.Icon,
		Size = categorysettings.Size,
		Window = window
	})

	categoryapi.Object = window
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateOverlay(categorysettings)
	local window
	local categoryapi
	categoryapi = {
		Type = 'Overlay',
		Expanded = false,
		Button = self.Overlays:CreateToggle({
			Name = categorysettings.Name,
			Function = function(callback)
				window.Visible = callback and (clickgui.Visible or categoryapi.Pinned)
				if not callback then
					for _, v in categoryapi.Connections do
						v:Disconnect()
					end
					table.clear(categoryapi.Connections)
				end

				if categorysettings.Function then
					task.spawn(categorysettings.Function, callback)
				end
			end,
			Icon = categorysettings.Icon,
			Size = categorysettings.Size,
			Position = categorysettings.Position
		}),
		Pinned = false,
		Options = {}
	}

	window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'Overlay'
	window.Size = UDim2.fromOffset(categorysettings.CategorySize or 220, 41)
	window.Position = UDim2.fromOffset(240, 46)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = scaledgui
	local blur = addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 14 and 14 or 13))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -32, 0, 41)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 0)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local pin = Instance.new('ImageButton')
	pin.Name = 'Pin'
	pin.Size = UDim2.fromOffset(16, 16)
	pin.Position = UDim2.new(1, -47, 0, 12)
	pin.BackgroundTransparency = 1
	pin.AutoButtonColor = false
	pin.Image = getcustomasset('badscript/assets/new/pin.png')
	pin.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	pin.Parent = window
	local dotsbutton = Instance.new('TextButton')
	dotsbutton.Name = 'Dots'
	dotsbutton.Size = UDim2.fromOffset(17, 40)
	dotsbutton.Position = UDim2.new(1, -17, 0, 0)
	dotsbutton.BackgroundTransparency = 1
	dotsbutton.Text = ''
	dotsbutton.Parent = window
	local dots = Instance.new('ImageLabel')
	dots.Name = 'Dots'
	dots.Size = UDim2.fromOffset(3, 16)
	dots.Position = UDim2.fromOffset(4, 12)
	dots.BackgroundTransparency = 1
	dots.Image = getcustomasset('badscript/assets/new/dots.png')
	dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
	dots.Parent = dotsbutton
	local customchildren = Instance.new('Frame')
	customchildren.Name = 'CustomChildren'
	customchildren.Size = UDim2.new(1, 0, 0, 200)
	customchildren.Position = UDim2.fromScale(0, 1)
	customchildren.BackgroundTransparency = 1
	customchildren.Parent = window
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -41)
	children.Position = UDim2.fromOffset(0, 37)
	children.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children
	addMaid(categoryapi)

	function categoryapi:Expand(check)
		if check and not blur.Visible then return end
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		dots.ImageColor3 = self.Expanded and uipallet.Text or color.Light(uipallet.Main, 0.37)
		if self.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
		end
	end

	function categoryapi:Pin()
		self.Pinned = not self.Pinned
		pin.ImageColor3 = self.Pinned and uipallet.Text or color.Dark(uipallet.Text, 0.43)
	end

	function categoryapi:Update()
		window.Visible = self.Button.Enabled and (clickgui.Visible or self.Pinned)
		if self.Expanded then
			self:Expand()
		end
		if clickgui.Visible then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 41)
			window.BackgroundTransparency = 0
			blur.Visible = true
			icon.Visible = true
			title.Visible = true
			pin.Visible = true
			dotsbutton.Visible = true
		else
			window.Size = UDim2.fromOffset(window.Size.X.Offset, 0)
			window.BackgroundTransparency = 1
			blur.Visible = false
			icon.Visible = false
			title.Visible = false
			pin.Visible = false
			dotsbutton.Visible = false
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return v(optionsettings, children, categoryapi)
		end
	end

	dotsbutton.MouseEnter:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = uipallet.Text
		end
	end)
	dotsbutton.MouseLeave:Connect(function()
		if not children.Visible then
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end
	end)
	dotsbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand(true)
	end)
	dotsbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	pin.MouseButton1Click:Connect(function()
		categoryapi:Pin()
	end)
	window.MouseButton2Click:Connect(function()
		categoryapi:Expand(true)
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(window.Size.X.Offset, math.min(41 + windowlist.AbsoluteContentSize.Y / scale.Scale, 601))
		end
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
		categoryapi:Update()
	end))

	categoryapi:Update()
	categoryapi.Object = window
	categoryapi.Children = customchildren
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateCategoryList(categorysettings)
	local categoryapi = {
		Type = 'CategoryList',
		Expanded = false,
		List = {},
		ListEnabled = {},
		Objects = {},
		Options = {}
	}
	categorysettings.Color = categorysettings.Color or Color3.fromRGB(5, 134, 105)

	local window = Instance.new('TextButton')
	window.Name = categorysettings.Name..'CategoryList'
	window.Size = UDim2.fromOffset(220, 45)
	window.Position = UDim2.fromOffset(240, 46)
	window.BackgroundColor3 = uipallet.Main
	window.AutoButtonColor = false
	window.Visible = false
	window.Text = ''
	window.Parent = clickgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = categorysettings.Size
	icon.Position = categorysettings.Position or UDim2.fromOffset(12, (categorysettings.Size.X.Offset > 20 and 13 or 12))
	icon.BackgroundTransparency = 1
	icon.Image = categorysettings.Icon
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Size = UDim2.new(1, -(categorysettings.Size.X.Offset > 20 and 44 or 36), 0, 20)
	title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 12)
	title.BackgroundTransparency = 1
	title.Text = categorysettings.Name
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = uipallet.Text
	title.TextSize = 13
	title.FontFace = uipallet.Font
	title.Parent = window
	local arrowbutton = Instance.new('TextButton')
	arrowbutton.Name = 'Arrow'
	arrowbutton.Size = UDim2.fromOffset(40, 40)
	arrowbutton.Position = UDim2.new(1, -40, 0, 0)
	arrowbutton.BackgroundTransparency = 1
	arrowbutton.Text = ''
	arrowbutton.Parent = window
	local arrow = Instance.new('ImageLabel')
	arrow.Name = 'Arrow'
	arrow.Size = UDim2.fromOffset(9, 4)
	arrow.Position = UDim2.fromOffset(20, 19)
	arrow.BackgroundTransparency = 1
	arrow.Image = getcustomasset('badscript/assets/new/expandup.png')
	arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	arrow.Rotation = 180
	arrow.Parent = arrowbutton
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -45)
	children.Position = UDim2.fromOffset(0, 45)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.Visible = false
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local childrentwo = Instance.new('Frame')
	childrentwo.BackgroundTransparency = 1
	childrentwo.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	childrentwo.Visible = false
	childrentwo.Parent = children
	local settings = Instance.new('ImageButton')
	settings.Name = 'Settings'
	settings.Size = UDim2.fromOffset(16, 16)
	settings.Position = UDim2.new(1, -52, 0, 13)
	settings.BackgroundTransparency = 1
	settings.AutoButtonColor = false
	settings.Image = getcustomasset('badscript/assets/new/customsettings.png')
	settings.ImageColor3 = color.Dark(uipallet.Text, 0.43)
	settings.Parent = window
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 41)
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.Parent = window
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Padding = UDim.new(0, 3)
	windowlist.Parent = children
	local windowlisttwo = Instance.new('UIListLayout')
	windowlisttwo.SortOrder = Enum.SortOrder.LayoutOrder
	windowlisttwo.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlisttwo.Parent = childrentwo
	local addbkg = Instance.new('Frame')
	addbkg.Name = 'Add'
	addbkg.Size = UDim2.fromOffset(200, 31)
	addbkg.Position = UDim2.fromOffset(10, 45)
	addbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
	addbkg.Parent = children
	addCorner(addbkg)
	local addbox = addbkg:Clone()
	addbox.Size = UDim2.new(1, -2, 1, -2)
	addbox.Position = UDim2.fromOffset(1, 1)
	addbox.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	addbox.Parent = addbkg
	local addvalue = Instance.new('TextBox')
	addvalue.Size = UDim2.new(1, -35, 1, 0)
	addvalue.Position = UDim2.fromOffset(10, 0)
	addvalue.BackgroundTransparency = 1
	addvalue.Text = ''
	addvalue.PlaceholderText = categorysettings.Placeholder or 'Add entry...'
	addvalue.TextXAlignment = Enum.TextXAlignment.Left
	addvalue.TextColor3 = Color3.new(1, 1, 1)
	addvalue.TextSize = 15
	addvalue.FontFace = uipallet.Font
	addvalue.ClearTextOnFocus = false
	addvalue.Parent = addbkg
	local addbutton = Instance.new('ImageButton')
	addbutton.Name = 'AddButton'
	addbutton.Size = UDim2.fromOffset(16, 16)
	addbutton.Position = UDim2.new(1, -26, 0, 8)
	addbutton.BackgroundTransparency = 1
	addbutton.Image = getcustomasset('badscript/assets/new/add.png')
	addbutton.ImageColor3 = categorysettings.Color
	addbutton.ImageTransparency = 0.3
	addbutton.Parent = addbkg
	local cursedpadding = Instance.new('Frame')
	cursedpadding.Size = UDim2.fromOffset()
	cursedpadding.BackgroundTransparency = 1
	cursedpadding.Parent = children
	categorysettings.Function = categorysettings.Function or function() end

	function categoryapi:ChangeValue(val)
		if val then
			if categorysettings.Profiles then
				local ind = self:GetValue(val)
				if ind then
					if val ~= 'default' then
						table.remove(mainapi.Profiles, ind)
						if isfile('badscript/profiles/'..val..mainapi.Place..'.txt') and delfile then
							delfile('badscript/profiles/'..val..mainapi.Place..'.txt')
						end
					end
				else
					table.insert(mainapi.Profiles, {Name = val, Bind = {}})
				end
			else
				local ind = table.find(self.List, val)
				if ind then
					table.remove(self.List, ind)
					ind = table.find(self.ListEnabled, val)
					if ind then
						table.remove(self.ListEnabled, ind)
					end
				else
					table.insert(self.List, val)
					table.insert(self.ListEnabled, val)
				end
			end
		end

		categorysettings.Function()
		for _, v in self.Objects do
			v:Destroy()
		end
		table.clear(self.Objects)
		self.Selected = nil

		for i, v in (categorysettings.Profiles and mainapi.Profiles or self.List) do
			if categorysettings.Profiles then
				local object = Instance.new('TextButton')
				object.Name = v.Name
				object.Size = UDim2.fromOffset(200, 33)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
				addCorner(object)
				local objectstroke = Instance.new('UIStroke')
				objectstroke.Color = color.Light(uipallet.Main, 0.1)
				objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				objectstroke.Enabled = false
				objectstroke.Parent = object
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -10, 1, 0)
				objecttitle.Position = UDim2.fromOffset(10, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v.Name
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				local dotsbutton = Instance.new('TextButton')
				dotsbutton.Name = 'Dots'
				dotsbutton.Size = UDim2.fromOffset(25, 33)
				dotsbutton.Position = UDim2.new(1, -25, 0, 0)
				dotsbutton.BackgroundTransparency = 1
				dotsbutton.Text = ''
				dotsbutton.Parent = object
				local dots = Instance.new('ImageLabel')
				dots.Name = 'Dots'
				dots.Size = UDim2.fromOffset(3, 16)
				dots.Position = UDim2.fromOffset(10, 9)
				dots.BackgroundTransparency = 1
				dots.Image = getcustomasset('badscript/assets/new/dots.png')
				dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
				dots.Parent = dotsbutton
				local bind = Instance.new('TextButton')
				addTooltip(bind, 'Click to bind')
				bind.Name = 'Bind'
				bind.Size = UDim2.fromOffset(20, 21)
				bind.Position = UDim2.new(1, -30, 0, 6)
				bind.AnchorPoint = Vector2.new(1, 0)
				bind.BackgroundColor3 = Color3.new(1, 1, 1)
				bind.BackgroundTransparency = 0.92
				bind.BorderSizePixel = 0
				bind.AutoButtonColor = false
				bind.Visible = false
				bind.Text = ''
				addCorner(bind, UDim.new(0, 4))
				local bindicon = Instance.new('ImageLabel')
				bindicon.Name = 'Icon'
				bindicon.Size = UDim2.fromOffset(12, 12)
				bindicon.Position = UDim2.new(0.5, -6, 0, 5)
				bindicon.BackgroundTransparency = 1
				bindicon.Image = getcustomasset('badscript/assets/new/bind.png')
				bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
				bindicon.Parent = bind
				local bindtext = Instance.new('TextLabel')
				bindtext.Size = UDim2.fromScale(1, 1)
				bindtext.Position = UDim2.fromOffset(0, 1)
				bindtext.BackgroundTransparency = 1
				bindtext.Visible = false
				bindtext.Text = ''
				bindtext.TextColor3 = color.Dark(uipallet.Text, 0.43)
				bindtext.TextSize = 12
				bindtext.FontFace = uipallet.Font
				bindtext.Parent = bind
				bind.MouseEnter:Connect(function()
					bindtext.Visible = false
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('badscript/assets/new/edit.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				bind.MouseLeave:Connect(function()
					bindtext.Visible = #v.Bind > 0
					bindicon.Visible = not bindtext.Visible
					bindicon.Image = getcustomasset('badscript/assets/new/bind.png')
					if v.Name ~= mainapi.Profile then
						bindicon.ImageColor3 = color.Dark(uipallet.Text, 0.43)
					end
				end)
				local bindcover = Instance.new('ImageLabel')
				bindcover.Name = 'Cover'
				bindcover.Size = UDim2.fromOffset(154, 33)
				bindcover.BackgroundTransparency = 1
				bindcover.Visible = false
				bindcover.Image = getcustomasset('badscript/assets/new/bindbkg.png')
				bindcover.ScaleType = Enum.ScaleType.Slice
				bindcover.SliceCenter = Rect.new(0, 0, 141, 40)
				bindcover.Parent = object
				local bindcovertext = Instance.new('TextLabel')
				bindcovertext.Name = 'Text'
				bindcovertext.Size = UDim2.new(1, -10, 1, -3)
				bindcovertext.BackgroundTransparency = 1
				bindcovertext.Text = 'PRESS A KEY TO BIND'
				bindcovertext.TextColor3 = uipallet.Text
				bindcovertext.TextSize = 11
				bindcovertext.FontFace = uipallet.Font
				bindcovertext.Parent = bindcover
				bind.Parent = object
				dotsbutton.MouseEnter:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = uipallet.Text
					end
				end)
				dotsbutton.MouseLeave:Connect(function()
					if v.Name ~= mainapi.Profile then
						dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
					end
				end)
				dotsbutton.MouseButton1Click:Connect(function()
					if v.Name ~= mainapi.Profile then
						categoryapi:ChangeValue(v.Name)
					end
				end)
				object.MouseButton1Click:Connect(function()
					mainapi:Save(v.Name)
					mainapi:Load(true)
				end)
				object.MouseEnter:Connect(function()
					bind.Visible = true
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = true
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
					end
				end)
				object.MouseLeave:Connect(function()
					bind.Visible = #v.Bind > 0
					if v.Name ~= mainapi.Profile then
						objectstroke.Enabled = false
						objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.4)
					end
				end)

				local function bindFunction(self, tab, mouse)
					v.Bind = table.clone(tab)
					if mouse then
						bindcovertext.Text = #tab <= 0 and 'BIND REMOVED' or 'BOUND TO '..table.concat(tab, ' + '):upper()
						bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
						task.delay(1, function()
							bindcover.Visible = false
						end)
					end

					if #tab <= 0 then
						bindtext.Visible = false
						bindicon.Visible = true
						bind.Size = UDim2.fromOffset(20, 21)
					else
						bind.Visible = true
						bindtext.Visible = true
						bindicon.Visible = false
						bindtext.Text = table.concat(tab, ' + '):upper()
						bind.Size = UDim2.fromOffset(math.max(getfontsize(bindtext.Text, bindtext.TextSize, bindtext.Font).X + 10, 20), 21)
					end
				end

				bindFunction({}, v.Bind)
				bind.MouseButton1Click:Connect(function()
					bindcovertext.Text = 'PRESS A KEY TO BIND'
					bindcover.Size = UDim2.fromOffset(getfontsize(bindcovertext.Text, bindcovertext.TextSize).X + 20, 40)
					bindcover.Visible = true
					mainapi.Binding = {SetBind = bindFunction, Bind = v.Bind}
				end)
				if v.Name == mainapi.Profile then
					self.Selected = object
				end
				table.insert(self.Objects, object)
			else
				local enabled = table.find(self.ListEnabled, v)
				local object = Instance.new('TextButton')
				object.Name = v
				object.Size = UDim2.fromOffset(200, 32)
				object.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
				object.AutoButtonColor = false
				object.Text = ''
				object.Parent = children
				addCorner(object)
				local objectbkg = Instance.new('Frame')
				objectbkg.Name = 'BKG'
				objectbkg.Size = UDim2.new(1, -2, 1, -2)
				objectbkg.Position = UDim2.fromOffset(1, 1)
				objectbkg.BackgroundColor3 = uipallet.Main
				objectbkg.Visible = false
				objectbkg.Parent = object
				addCorner(objectbkg)
				local objectdot = Instance.new('Frame')
				objectdot.Name = 'Dot'
				objectdot.Size = UDim2.fromOffset(10, 11)
				objectdot.Position = UDim2.fromOffset(10, 12)
				objectdot.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.37)
				objectdot.Parent = object
				addCorner(objectdot, UDim.new(1, 0))
				local objectdotin = objectdot:Clone()
				objectdotin.Size = UDim2.fromOffset(8, 9)
				objectdotin.Position = UDim2.fromOffset(1, 1)
				objectdotin.BackgroundColor3 = enabled and categorysettings.Color or color.Light(uipallet.Main, 0.02)
				objectdotin.Parent = objectdot
				local objecttitle = Instance.new('TextLabel')
				objecttitle.Name = 'Title'
				objecttitle.Size = UDim2.new(1, -30, 1, 0)
				objecttitle.Position = UDim2.fromOffset(30, 0)
				objecttitle.BackgroundTransparency = 1
				objecttitle.Text = v
				objecttitle.TextXAlignment = Enum.TextXAlignment.Left
				objecttitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
				objecttitle.TextSize = 15
				objecttitle.FontFace = uipallet.Font
				objecttitle.Parent = object
				if mainapi.ThreadFix then
					setthreadidentity(8)
				end
				local close = Instance.new('ImageButton')
				close.Name = 'Close'
				close.Size = UDim2.fromOffset(16, 16)
				close.Position = UDim2.new(1, -23, 0, 8)
				close.BackgroundColor3 = Color3.new(1, 1, 1)
				close.BackgroundTransparency = 1
				close.AutoButtonColor = false
				close.Image = getcustomasset('badscript/assets/new/closemini.png')
				close.ImageColor3 = color.Light(uipallet.Text, 0.2)
				close.ImageTransparency = 0.5
				close.Parent = object
				addCorner(close, UDim.new(1, 0))
				close.MouseEnter:Connect(function()
					close.ImageTransparency = 0.3
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 0.6
					})
				end)
				close.MouseLeave:Connect(function()
					close.ImageTransparency = 0.5
					tween:Tween(close, uipallet.Tween, {
						BackgroundTransparency = 1
					})
				end)
				close.MouseButton1Click:Connect(function()
					categoryapi:ChangeValue(v)
				end)
				object.MouseEnter:Connect(function()
					objectbkg.Visible = true
				end)
				object.MouseLeave:Connect(function()
					objectbkg.Visible = false
				end)
				object.MouseButton1Click:Connect(function()
					local ind = table.find(self.ListEnabled, v)
					if ind then
						table.remove(self.ListEnabled, ind)
						objectdot.BackgroundColor3 = color.Light(uipallet.Main, 0.37)
						objectdotin.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
					else
						table.insert(self.ListEnabled, v)
						objectdot.BackgroundColor3 = categorysettings.Color
						objectdotin.BackgroundColor3 = categorysettings.Color
					end
					categorysettings.Function()
				end)
				table.insert(self.Objects, object)
			end
		end
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end

	function categoryapi:Expand()
		self.Expanded = not self.Expanded
		children.Visible = self.Expanded
		arrow.Rotation = self.Expanded and 0 or 180
		window.Size = UDim2.fromOffset(220, self.Expanded and math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611) or 45)
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end

	function categoryapi:GetValue(name)
		for i, v in mainapi.Profiles do
			if v.Name == name then
				return i
			end
		end
	end

	for i, v in components do
		categoryapi['Create'..i] = function(self, optionsettings)
			return v(optionsettings, childrentwo, categoryapi)
		end
	end

	addbutton.MouseEnter:Connect(function()
		addbutton.ImageTransparency = 0
	end)
	addbutton.MouseLeave:Connect(function()
		addbutton.ImageTransparency = 0.3
	end)
	addbutton.MouseButton1Click:Connect(function()
		if not table.find(categoryapi.List, addvalue.Text) then
			categoryapi:ChangeValue(addvalue.Text)
			addvalue.Text = ''
		end
	end)
	arrowbutton.MouseEnter:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(220, 220, 220)
	end)
	arrowbutton.MouseLeave:Connect(function()
		arrow.ImageColor3 = Color3.fromRGB(140, 140, 140)
	end)
	arrowbutton.MouseButton1Click:Connect(function()
		categoryapi:Expand()
	end)
	arrowbutton.MouseButton2Click:Connect(function()
		categoryapi:Expand()
	end)
	addvalue.FocusLost:Connect(function(enter)
		if enter and not table.find(categoryapi.List, addvalue.Text) then
			categoryapi:ChangeValue(addvalue.Text)
			addvalue.Text = ''
		end
	end)
	addvalue.MouseEnter:Connect(function()
		tween:Tween(addbkg, uipallet.Tween, {
			BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		})
	end)
	addvalue.MouseLeave:Connect(function()
		tween:Tween(addbkg, uipallet.Tween, {
			BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		})
	end)
	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	settings.MouseEnter:Connect(function()
		settings.ImageColor3 = uipallet.Text
	end)
	settings.MouseLeave:Connect(function()
		settings.ImageColor3 = color.Light(uipallet.Main, 0.37)
	end)
	settings.MouseButton1Click:Connect(function()
		childrentwo.Visible = not childrentwo.Visible
	end)
	window.InputBegan:Connect(function(inputObj)
		if inputObj.Position.Y < window.AbsolutePosition.Y + 41 and inputObj.UserInputType == Enum.UserInputType.MouseButton2 then
			categoryapi:Expand()
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		if categoryapi.Expanded then
			window.Size = UDim2.fromOffset(220, math.min(51 + windowlist.AbsoluteContentSize.Y / scale.Scale, 611))
		end
	end)
	windowlisttwo:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		childrentwo.Size = UDim2.fromOffset(220, windowlisttwo.AbsoluteContentSize.Y)
	end)

	categoryapi.Button = self.Categories.Main:CreateButton({
		Name = categorysettings.Name,
		Icon = categorysettings.CategoryIcon,
		Size = categorysettings.CategorySize,
		Window = window
	})

	categoryapi.Object = window
	self.Categories[categorysettings.Name] = categoryapi

	return categoryapi
end

function mainapi:CreateSearch()
	local searchbkg = Instance.new('Frame')
	searchbkg.Name = 'Search'
	searchbkg.Size = UDim2.fromOffset(220, 37)
	searchbkg.Position = UDim2.new(0.5, 0, 0, 13)
	searchbkg.AnchorPoint = Vector2.new(0.5, 0)
	searchbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
	searchbkg.Parent = clickgui
	local searchicon = Instance.new('ImageLabel')
	searchicon.Name = 'Icon'
	searchicon.Size = UDim2.fromOffset(14, 14)
	searchicon.Position = UDim2.new(1, -23, 0, 11)
	searchicon.BackgroundTransparency = 1
	searchicon.Image = getcustomasset('badscript/assets/new/search.png')
	searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
	searchicon.Parent = searchbkg
	local legiticon = Instance.new('ImageButton')
	legiticon.Name = 'Legit'
	legiticon.Size = UDim2.fromOffset(29, 16)
	legiticon.Position = UDim2.fromOffset(8, 11)
	legiticon.BackgroundTransparency = 1
	legiticon.Image = getcustomasset('badscript/assets/new/legit.png')
	legiticon.Parent = searchbkg
	local legitdivider = Instance.new('Frame')
	legitdivider.Name = 'LegitDivider'
	legitdivider.Size = UDim2.fromOffset(2, 12)
	legitdivider.Position = UDim2.fromOffset(43, 13)
	legitdivider.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
	legitdivider.BorderSizePixel = 0
	legitdivider.Parent = searchbkg
	addBlur(searchbkg)
	addCorner(searchbkg)
	local search = Instance.new('TextBox')
	search.Size = UDim2.new(1, -50, 0, 37)
	search.Position = UDim2.fromOffset(50, 0)
	search.BackgroundTransparency = 1
	search.Text = ''
	search.PlaceholderText = ''
	search.TextXAlignment = Enum.TextXAlignment.Left
	search.TextColor3 = uipallet.Text
	search.TextSize = 12
	search.FontFace = uipallet.Font
	search.ClearTextOnFocus = false
	search.Parent = searchbkg
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.new(1, 0, 1, -37)
	children.Position = UDim2.fromOffset(0, 34)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = searchbkg
	local divider = Instance.new('Frame')
	divider.Name = 'Divider'
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.fromOffset(0, 33)
	divider.BackgroundColor3 = Color3.new(1, 1, 1)
	divider.BackgroundTransparency = 0.928
	divider.BorderSizePixel = 0
	divider.Visible = false
	divider.Parent = searchbkg
	local windowlist = Instance.new('UIListLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
	windowlist.Parent = children

	children:GetPropertyChangedSignal('CanvasPosition'):Connect(function()
		divider.Visible = children.CanvasPosition.Y > 10 and children.Visible
	end)
	legiticon.MouseButton1Click:Connect(function()
		clickgui.Visible = false
		self.Legit.Window.Visible = true
		self.Legit.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
	end)
	search:GetPropertyChangedSignal('Text'):Connect(function()
		for _, v in children:GetChildren() do
			if v:IsA('TextButton') then
				v:Destroy()
			end
		end
		if search.Text == '' then return end

		for i, v in self.Modules do
			if i:lower():find(search.Text:lower()) then
				local button = v.Object:Clone()
				button.Bind:Destroy()
				button.MouseButton1Click:Connect(function()
					v:Toggle()
				end)

				button.MouseButton2Click:Connect(function()
					v.Object.Parent.Parent.Visible = true
					local frame = v.Object.Parent
					local highlight = Instance.new('Frame')
					highlight.Size = UDim2.fromScale(1, 1)
					highlight.BackgroundColor3 = Color3.new(1, 1, 1)
					highlight.BackgroundTransparency = 0.6
					highlight.BorderSizePixel = 0
					highlight.Parent = v.Object
					tween:Tween(highlight, TweenInfo.new(0.5), {
						BackgroundTransparency = 1
					})
					task.delay(0.5, highlight.Destroy, highlight)

					frame.CanvasPosition = Vector2.new(0, (v.Object.LayoutOrder * 40) - (math.min(frame.CanvasSize.Y.Offset, 600) / 2))
				end)

				button.Parent = children
				task.spawn(function()
					repeat
						for _, v2 in {'Text', 'TextColor3', 'BackgroundColor3'} do
							button[v2] = v.Object[v2]
						end
						button.UIGradient.Color = v.Object.UIGradient.Color
						button.UIGradient.Enabled = v.Object.UIGradient.Enabled
						button.Dots.Dots.ImageColor3 = v.Object.Dots.Dots.ImageColor3
						task.wait()
					until not button.Parent
				end)
			end
		end
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
		searchbkg.Size = UDim2.fromOffset(220, math.min(37 + windowlist.AbsoluteContentSize.Y / scale.Scale, 437))
	end)

	self.Legit.Icon = legiticon
end

function mainapi:CreateLegit()
	local legitapi = {Modules = {}}

	local window = Instance.new('Frame')
	window.Name = 'LegitGUI'
	window.Size = UDim2.fromOffset(700, 389)
	window.Position = UDim2.new(0.5, -350, 0.5, -194)
	window.BackgroundColor3 = uipallet.Main
	window.Visible = false
	window.Parent = scaledgui
	addBlur(window)
	addCorner(window)
	makeDraggable(window)
	local modal = Instance.new('TextButton')
	modal.BackgroundTransparency = 1
	modal.Text = ''
	modal.Modal = true
	modal.Parent = window
	local icon = Instance.new('ImageLabel')
	icon.Name = 'Icon'
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Position = UDim2.fromOffset(18, 13)
	icon.BackgroundTransparency = 1
	icon.Image = getcustomasset('badscript/assets/new/legittab.png')
	icon.ImageColor3 = uipallet.Text
	icon.Parent = window
	local close = addCloseButton(window)
	local children = Instance.new('ScrollingFrame')
	children.Name = 'Children'
	children.Size = UDim2.fromOffset(684, 340)
	children.Position = UDim2.fromOffset(14, 41)
	children.BackgroundTransparency = 1
	children.BorderSizePixel = 0
	children.ScrollBarThickness = 2
	children.ScrollBarImageTransparency = 0.75
	children.CanvasSize = UDim2.new()
	children.Parent = window
	local windowlist = Instance.new('UIGridLayout')
	windowlist.SortOrder = Enum.SortOrder.LayoutOrder
	windowlist.FillDirectionMaxCells = 4
	windowlist.CellSize = UDim2.fromOffset(163, 114)
	windowlist.CellPadding = UDim2.fromOffset(6, 5)
	windowlist.Parent = children
	legitapi.Window = window
	table.insert(mainapi.Windows, window)

	function legitapi:CreateModule(modulesettings)
		mainapi:Remove(modulesettings.Name)
		local moduleapi = {
			Enabled = false,
			Options = {},
			Name = modulesettings.Name,
			Legit = true
		}

		local module = Instance.new('TextButton')
		module.Name = modulesettings.Name
		module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
		module.Text = ''
		module.AutoButtonColor = false
		module.Parent = children
		addTooltip(module, modulesettings.Tooltip)
		addCorner(module)
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -16, 0, 20)
		title.Position = UDim2.fromOffset(16, 81)
		title.BackgroundTransparency = 1
		title.Text = modulesettings.Name
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = color.Dark(uipallet.Text, 0.31)
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = module
		local knob = Instance.new('Frame')
		knob.Name = 'Knob'
		knob.Size = UDim2.fromOffset(22, 12)
		knob.Position = UDim2.new(1, -57, 0, 14)
		knob.BackgroundColor3 = color.Light(uipallet.Main, 0.14)
		knob.Parent = module
		addCorner(knob, UDim.new(1, 0))
		local knobmain = knob:Clone()
		knobmain.Size = UDim2.fromOffset(8, 8)
		knobmain.Position = UDim2.fromOffset(2, 2)
		knobmain.BackgroundColor3 = uipallet.Main
		knobmain.Parent = knob
		local dotsbutton = Instance.new('TextButton')
		dotsbutton.Name = 'Dots'
		dotsbutton.Size = UDim2.fromOffset(14, 24)
		dotsbutton.Position = UDim2.new(1, -27, 0, 8)
		dotsbutton.BackgroundTransparency = 1
		dotsbutton.Text = ''
		dotsbutton.Parent = module
		local dots = Instance.new('ImageLabel')
		dots.Name = 'Dots'
		dots.Size = UDim2.fromOffset(2, 12)
		dots.Position = UDim2.fromOffset(6, 6)
		dots.BackgroundTransparency = 1
		dots.Image = getcustomasset('badscript/assets/new/dots.png')
		dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		dots.Parent = dotsbutton
		local shadow = Instance.new('TextButton')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 0, 1, -5)
		shadow.BackgroundColor3 = Color3.new()
		shadow.BackgroundTransparency = 1
		shadow.AutoButtonColor = false
		shadow.ClipsDescendants = true
		shadow.Visible = false
		shadow.Text = ''
		shadow.Parent = window
		addCorner(shadow)
		local settingspane = Instance.new('TextButton')
		settingspane.Size = UDim2.new(0, 220, 1, 0)
		settingspane.Position = UDim2.fromScale(1, 0)
		settingspane.BackgroundColor3 = uipallet.Main
		settingspane.AutoButtonColor = false
		settingspane.Text = ''
		settingspane.Parent = shadow
		local settingstitle = Instance.new('TextLabel')
		settingstitle.Name = 'Title'
		settingstitle.Size = UDim2.new(1, -36, 0, 20)
		settingstitle.Position = UDim2.fromOffset(36, 12)
		settingstitle.BackgroundTransparency = 1
		settingstitle.Text = modulesettings.Name
		settingstitle.TextXAlignment = Enum.TextXAlignment.Left
		settingstitle.TextColor3 = color.Dark(uipallet.Text, 0.16)
		settingstitle.TextSize = 13
		settingstitle.FontFace = uipallet.Font
		settingstitle.Parent = settingspane
		local back = Instance.new('ImageButton')
		back.Name = 'Back'
		back.Size = UDim2.fromOffset(16, 16)
		back.Position = UDim2.fromOffset(11, 13)
		back.BackgroundTransparency = 1
		back.Image = getcustomasset('badscript/assets/new/back.png')
		back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		back.Parent = settingspane
		addCorner(settingspane)
		local settingschildren = Instance.new('ScrollingFrame')
		settingschildren.Name = 'Children'
		settingschildren.Size = UDim2.new(1, 0, 1, -45)
		settingschildren.Position = UDim2.fromOffset(0, 41)
		settingschildren.BackgroundColor3 = uipallet.Main
		settingschildren.BorderSizePixel = 0
		settingschildren.ScrollBarThickness = 2
		settingschildren.ScrollBarImageTransparency = 0.75
		settingschildren.CanvasSize = UDim2.new()
		settingschildren.Parent = settingspane
		local settingswindowlist = Instance.new('UIListLayout')
		settingswindowlist.SortOrder = Enum.SortOrder.LayoutOrder
		settingswindowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		settingswindowlist.Parent = settingschildren
		if modulesettings.Size then
			local modulechildren = Instance.new('Frame')
			modulechildren.Size = modulesettings.Size
			modulechildren.BackgroundTransparency = 1
			modulechildren.Visible = false
			modulechildren.Parent = scaledgui
			makeDraggable(modulechildren, window)
			local objectstroke = Instance.new('UIStroke')
			objectstroke.Color = Color3.fromRGB(5, 134, 105)
			objectstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			objectstroke.Thickness = 0
			objectstroke.Parent = modulechildren
			moduleapi.Children = modulechildren
		end
		modulesettings.Function = modulesettings.Function or function() end
		addMaid(moduleapi)

		function moduleapi:Toggle()
			moduleapi.Enabled = not moduleapi.Enabled
			if moduleapi.Children then
				moduleapi.Children.Visible = moduleapi.Enabled
			end
			title.TextColor3 = moduleapi.Enabled and color.Light(uipallet.Text, 0.2) or color.Dark(uipallet.Text, 0.31)
			module.BackgroundColor3 = moduleapi.Enabled and color.Light(uipallet.Main, 0.05) or module.BackgroundColor3
			tween:Tween(knob, uipallet.Tween, {
				BackgroundColor3 = moduleapi.Enabled and Color3.fromHSV(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value) or color.Light(uipallet.Main, 0.14)
			})
			tween:Tween(knobmain, uipallet.Tween, {
				Position = UDim2.fromOffset(moduleapi.Enabled and 12 or 2, 2)
			})
			if not moduleapi.Enabled then
				for _, v in moduleapi.Connections do
					v:Disconnect()
				end
				table.clear(moduleapi.Connections)
			end
			task.spawn(modulesettings.Function, moduleapi.Enabled)
		end

		back.MouseEnter:Connect(function()
			back.ImageColor3 = uipallet.Text
		end)
		back.MouseLeave:Connect(function()
			back.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		back.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		dotsbutton.MouseButton1Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.new(1, -220, 0, 0)
			})
		end)
		dotsbutton.MouseEnter:Connect(function()
			dots.ImageColor3 = uipallet.Text
		end)
		dotsbutton.MouseLeave:Connect(function()
			dots.ImageColor3 = color.Light(uipallet.Main, 0.37)
		end)
		module.MouseEnter:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.05)
			end
		end)
		module.MouseLeave:Connect(function()
			if not moduleapi.Enabled then
				module.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end
		end)
		module.MouseButton1Click:Connect(function()
			moduleapi:Toggle()
		end)
		module.MouseButton2Click:Connect(function()
			shadow.Visible = true
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 0.5
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.new(1, -220, 0, 0)
			})
		end)
		shadow.MouseButton1Click:Connect(function()
			tween:Tween(shadow, uipallet.Tween, {
				BackgroundTransparency = 1
			})
			tween:Tween(settingspane, uipallet.Tween, {
				Position = UDim2.fromScale(1, 0)
			})
			task.wait(0.2)
			shadow.Visible = false
		end)
		settingswindowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			settingschildren.CanvasSize = UDim2.fromOffset(0, settingswindowlist.AbsoluteContentSize.Y / scale.Scale)
		end)

		for i, v in components do
			moduleapi['Create'..i] = function(_, optionsettings)
				return v(optionsettings, settingschildren, moduleapi)
			end
		end

		moduleapi.Object = module
		legitapi.Modules[modulesettings.Name] = moduleapi

		local sorting = {}
		for _, v in legitapi.Modules do
			table.insert(sorting, v.Name)
		end
		table.sort(sorting)

		for i, v in sorting do
			legitapi.Modules[v].Object.LayoutOrder = i
		end

		return moduleapi
	end

	local function visibleCheck()
		for _, v in legitapi.Modules do
			if v.Children then
				local visible = clickgui.Visible
				for _, v2 in self.Windows do
					visible = visible or v2.Visible
				end
				v.Children.Visible = (not visible or window.Visible) and v.Enabled
			end
		end
	end

	close.MouseButton1Click:Connect(function()
		window.Visible = false
		clickgui.Visible = true
	end)
	self:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(visibleCheck))
	window:GetPropertyChangedSignal('Visible'):Connect(function()
		self:UpdateGUI(self.GUIColor.Hue, self.GUIColor.Sat, self.GUIColor.Value)
		visibleCheck()
	end)
	windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / scale.Scale)
	end)

	self.Legit = legitapi

	return legitapi
end

function mainapi:CreateNotification(title, text, duration, type, stack)
	if not self.Notifications.Enabled then return end
	task.delay(0, function()
		if self.ThreadFix then
			setthreadidentity(8)
		end
		local isCompile = (type == 'compile')
		local isError = (type == 'alert' or type == 'runtime' or type == 'error' or isCompile)
		local container = isError and errorNotificationContainer or notifications
		local key = title .. '|' .. (text or ''):sub(1, 80)
		-- Group duplicate errors
		local existing = container:FindFirstChild(key)
		if existing then
			local count = existing:FindFirstChild('Count')
			if count then
				local num = (tonumber(count.Text:match('%d+')) or 1) + 1
				count.Text = num .. 'x'
			end
			return
		end

		-- Rich data if stack is our compile log entry
		local rich = (type == 'compile' or type == 'runtime') and typeof(stack) == 'table' and stack or nil
		local displayTitle = title or (isCompile and 'Compile Error' or 'Error')
		local displayMsg = text or ''
		local scriptBadge = rich and rich.script or nil
		local lineNum = rich and rich.line or nil

		local notif = Instance.new('Frame')
		notif.Name = key
		notif.Size = UDim2.new(1, 0, 0, isCompile and 92 or 70)
		notif.BackgroundColor3 = isCompile and Color3.fromRGB(55, 25, 15) or (isError and Color3.fromRGB(45, 20, 20) or Color3.fromRGB(30, 30, 30))
		notif.BorderSizePixel = 0
		notif.Parent = container
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = notif

		-- left accent bar for category
		local accent = Instance.new('Frame')
		accent.Size = UDim2.new(0, 4, 1, 0)
		accent.BackgroundColor3 = isCompile and Color3.fromRGB(255, 140, 60) or (isError and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(100, 180, 255))
		accent.BorderSizePixel = 0
		accent.Parent = notif
		local acorner = Instance.new('UICorner')
		acorner.CornerRadius = UDim.new(0, 8)
		acorner.Parent = accent

		-- shadow
		local shadow = Instance.new('ImageLabel')
		shadow.Name = 'Shadow'
		shadow.Size = UDim2.new(1, 12, 1, 12)
		shadow.Position = UDim2.fromOffset(-6, -6)
		shadow.BackgroundTransparency = 1
		shadow.Image = 'rbxassetid://5554236805'
		shadow.ImageColor3 = Color3.new(0, 0, 0)
		shadow.ImageTransparency = 0.6
		shadow.Parent = notif

		-- icon (use emoji text for dedicated compile icon + fallback assets)
		local icon
		if isCompile then
			icon = Instance.new('TextLabel')
			icon.Name = 'Icon'
			icon.Size = UDim2.fromOffset(22, 22)
			icon.Position = UDim2.fromOffset(12, 8)
			icon.BackgroundTransparency = 1
			icon.Text = '❌'
			icon.TextColor3 = Color3.fromRGB(255, 160, 80)
			icon.Font = Enum.Font.GothamBold
			icon.TextSize = 16
			icon.Parent = notif
		else
			icon = Instance.new('ImageLabel')
			icon.Name = 'Icon'
			icon.Size = UDim2.fromOffset(20, 20)
			icon.Position = UDim2.fromOffset(10, 8)
			icon.BackgroundTransparency = 1
			icon.Image = getcustomasset(isError and 'badscript/assets/new/alert.png' or 'badscript/assets/new/info.png')
			icon.Parent = notif
		end

		-- Script badge (styled label)
		local badgeX = isCompile and 38 or 36
		if scriptBadge then
			local badge = Instance.new('TextLabel')
			badge.Name = 'ScriptBadge'
			badge.Size = UDim2.fromOffset(math.min(110, #scriptBadge * 6 + 16), 16)
			badge.Position = UDim2.fromOffset(badgeX, 6)
			badge.BackgroundColor3 = Color3.fromRGB(70, 40, 25)
			badge.Text = tostring(scriptBadge)
			badge.TextColor3 = Color3.fromRGB(255, 200, 140)
			badge.Font = Enum.Font.GothamBold
			badge.TextSize = 10
			badge.TextXAlignment = Enum.TextXAlignment.Center
			badge.Parent = notif
			local bc = Instance.new('UICorner')
			bc.CornerRadius = UDim.new(0, 4)
			bc.Parent = badge
			badgeX = badgeX + badge.Size.X.Offset + 6
		end

		local titleLabel = Instance.new('TextLabel')
		titleLabel.Name = 'Title'
		titleLabel.Size = UDim2.new(1, -140, 0, 18)
		titleLabel.Position = UDim2.fromOffset(badgeX, 6)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = displayTitle .. (lineNum and (' @ line ' .. lineNum) or '')
		titleLabel.TextColor3 = isCompile and Color3.fromRGB(255, 170, 100) or (isError and Color3.fromRGB(255, 110, 110) or Color3.fromRGB(220, 220, 220))
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 12
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Parent = notif

		local textLabel = Instance.new('TextLabel')
		textLabel.Name = 'Text'
		textLabel.Size = UDim2.new(1, -16, 0, isCompile and 28 or 36)
		textLabel.Position = UDim2.fromOffset(10, 26)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = displayMsg
		textLabel.TextColor3 = Color3.fromRGB(220, 200, 190)
		textLabel.Font = Enum.Font.Gotham
		textLabel.TextSize = 11
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.Parent = notif

		-- Compile-specific: show 1-line hint + expand for details
		local detailLabel = Instance.new('TextLabel')
		detailLabel.Name = 'Detail'
		detailLabel.Size = UDim2.new(1, -16, 0, 0)
		detailLabel.Position = UDim2.fromOffset(10, 54)
		detailLabel.BackgroundTransparency = 1
		detailLabel.Text = (rich and rich.likely) or (isCompile and 'Click to view context & suggested fixes' or '')
		detailLabel.TextColor3 = Color3.fromRGB(180, 160, 140)
		detailLabel.Font = Enum.Font.Gotham
		detailLabel.TextSize = 9
		detailLabel.TextWrapped = true
		detailLabel.Visible = isCompile
		detailLabel.Parent = notif

		-- buttons
		local copyBtn = Instance.new('TextButton')
		copyBtn.Size = UDim2.fromOffset(50, 16)
		copyBtn.Position = UDim2.new(1, -110, 1, -20)
		copyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		copyBtn.Text = 'Copy'
		copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		copyBtn.Font = Enum.Font.Gotham
		copyBtn.TextSize = 9
		copyBtn.Parent = notif
		local corner1 = Instance.new('UICorner')
		corner1.CornerRadius = UDim.new(0, 3)
		corner1.Parent = copyBtn
		copyBtn.MouseButton1Click:Connect(function()
			local payload = displayMsg
			if rich then
				payload = (rich.category or 'Error') .. ': ' .. (rich.script or '') .. ':' .. (rich.line or '') .. '\n' .. (rich.message or displayMsg)
				if rich.rawError then payload = payload .. '\n\n' .. tostring(rich.rawError) end
			end
			setclipboard(payload)
		end)

		local dismissBtn = Instance.new('TextButton')
		dismissBtn.Size = UDim2.fromOffset(50, 16)
		dismissBtn.Position = UDim2.new(1, -55, 1, -20)
		dismissBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		dismissBtn.Text = 'Dismiss'
		dismissBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		dismissBtn.Font = Enum.Font.Gotham
		dismissBtn.TextSize = 9
		dismissBtn.Parent = notif
		local corner2 = Instance.new('UICorner')
		corner2.CornerRadius = UDim.new(0, 3)
		corner2.Parent = dismissBtn

		local expanded = false
		local function dismiss()
			if tween and tween.Tween then
				tween:Tween(notif, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(1, 0, 0, 0)})
			end
			task.wait(0.3)
			if notif and notif.Parent then notif:Destroy() end
		end
		dismissBtn.MouseButton1Click:Connect(dismiss)

		notif.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				expanded = not expanded
				if expanded and rich then
					-- show suggestions or raw in detail
					local detailText = ''
					if rich.likely then detailText = detailText .. rich.likely .. '\n' end
					if rich.suggestions and #rich.suggestions > 0 then
						detailText = detailText .. 'Suggestions:\n• ' .. table.concat(rich.suggestions, '\n• ')
					end
					if rich.preview and #rich.preview > 0 then
						detailText = detailText .. '\n[Context shown in Console]'
					end
					detailLabel.Text = detailText ~= '' and detailText or (rich.rawError or '')
					detailLabel.Size = UDim2.new(1, -16, 0, 68)
					detailLabel.Visible = true
					notif.Size = UDim2.new(1, 0, 0, 140)
				elseif expanded and stack then
					detailLabel.Text = tostring(stack)
					detailLabel.Size = UDim2.new(1, -16, 0, 50)
					detailLabel.Visible = true
					notif.Size = UDim2.new(1, 0, 0, 110)
				else
					detailLabel.Size = UDim2.new(1, -16, 0, 0)
					detailLabel.Visible = isCompile
					notif.Size = UDim2.new(1, 0, 0, isCompile and 92 or 70)
				end
			end
		end)

		-- entrance animation
		notif.Size = UDim2.new(1, 0, 0, 0)
		if tween and tween.Tween then
			tween:Tween(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, isCompile and 92 or 70)})
		end
		-- auto dismiss (keep in log history)
		local dismissTime = duration or (isCompile and 16 or (isError and 12 or 6))
		task.delay(dismissTime, dismiss)
	end)
end

function mainapi:CreateRuntimeError(title, text, stack)
	self:CreateNotification(title or 'Runtime Error', text or '', 10, 'runtime', stack)
end

function mainapi:Load(skipgui, profile)
	if not skipgui then
		self.GUIColor:SetValue(nil, nil, nil, 4)
	end
	local guidata = {}
	local savecheck = true

	if isfile('badscript/profiles/'..game.GameId..'.gui.txt') then
		guidata = loadJson('badscript/profiles/'..game.GameId..'.gui.txt')
		if not guidata then
			guidata = {Categories = {}}
			self:CreateNotification('Bad', 'Failed to load GUI settings.', 10, 'alert')
			savecheck = false
		end

		if not skipgui then
			self.Keybind = guidata.Keybind
			for i, v in guidata.Categories do
				local object = self.Categories[i]
				if not object then continue end
				if object.Options and v.Options then
					self:LoadOptions(object, v.Options)
				end
				if v.Enabled then
					object.Button:Toggle()
				end
				if v.Pinned then
					object:Pin()
				end
				if v.Expanded and object.Expand then
					object:Expand()
				end
				if v.List and (#object.List > 0 or #v.List > 0) then
					object.List = v.List or {}
					object.ListEnabled = v.ListEnabled or {}
					object:ChangeValue()
				end
				if v.Position then
					object.Object.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
				end
			end
		end
	end

	self.Profile = profile or guidata.Profile or 'default'
	self.Profiles = guidata.Profiles or {{
		Name = 'default', Bind = {}
	}}
	self.Categories.Profiles:ChangeValue()
	if self.ProfileLabel then
		self.ProfileLabel.Text = #self.Profile > 10 and self.Profile:sub(1, 10)..'...' or self.Profile
		self.ProfileLabel.Size = UDim2.fromOffset(getfontsize(self.ProfileLabel.Text, self.ProfileLabel.TextSize, self.ProfileLabel.Font).X + 16, 24)
	end

	if isfile('badscript/profiles/'..self.Profile..self.Place..'.txt') then
		local savedata = loadJson('badscript/profiles/'..self.Profile..self.Place..'.txt')
		if not savedata then
			savedata = {Categories = {}, Modules = {}, Legit = {}}
			self:CreateNotification('Bad', 'Failed to load '..self.Profile..' profile.', 10, 'alert')
			savecheck = false
		end

		for i, v in savedata.Categories do
			local object = self.Categories[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
			end
			if v.Pinned ~= object.Pinned then
				object:Pin()
			end
			if v.Expanded ~= nil and v.Expanded ~= object.Expanded then
				object:Expand()
			end
			if object.Button and (v.Enabled or false) ~= object.Button.Enabled then
				object.Button:Toggle()
			end
			if v.List and (#object.List > 0 or #v.List > 0) then
				object.List = v.List or {}
				object.ListEnabled = v.ListEnabled or {}
				object:ChangeValue()
			end
			object.Object.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
		end

		for i, v in savedata.Modules do
			local object = self.Modules[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
			end
			if v.Enabled ~= object.Enabled then
				if skipgui then
					if self.ToggleNotifications.Enabled then self:CreateNotification('Module Toggled', i.."<font color='#FFFFFF'> has been </font>"..(v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>").."<font color='#FFFFFF'>!</font>", 0.75) end
				end
				object:Toggle(true)
			end
			object:SetBind(v.Bind)
			object.Object.Bind.Visible = #v.Bind > 0
		end

		for i, v in savedata.Legit do
			local object = self.Legit.Modules[i]
			if not object then continue end
			if object.Options and v.Options then
				self:LoadOptions(object, v.Options)
			end
			if object.Enabled ~= v.Enabled then
				object:Toggle()
			end
			if v.Position and object.Children then
				object.Children.Position = UDim2.fromOffset(v.Position.X, v.Position.Y)
			end
		end

		self:UpdateTextGUI(true)
	else
		self:Save()
	end

	if self.Downloader then
		self.Downloader:Destroy()
		self.Downloader = nil
	end
	self.Loaded = savecheck
	self.Categories.Main.Options.Bind:SetBind(self.Keybind)

	if inputService.TouchEnabled and #self.Keybind == 1 and self.Keybind[1] == 'RightShift' then
		local button = Instance.new('TextButton')
		button.Size = UDim2.fromOffset(32, 32)
		button.Position = UDim2.new(1, -90, 0, 4)
		button.BackgroundColor3 = Color3.new()
		button.BackgroundTransparency = 0.5
		button.Text = ''
		button.Parent = gui
		local image = Instance.new('ImageLabel')
		image.Size = UDim2.fromOffset(26, 26)
		image.Position = UDim2.fromOffset(3, 3)
		image.BackgroundTransparency = 1
		image.Image = getcustomasset('badscript/assets/new/Bad.png')
		image.Parent = button
		local buttoncorner = Instance.new('UICorner')
		buttoncorner.Parent = button
		self.BadButton = button
		button.MouseButton1Click:Connect(function()
			if self.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in self.Windows do
				v.Visible = false
			end
			for _, mobileButton in self.Modules do
				if mobileButton.Bind.Button then
					mobileButton.Bind.Button.Visible = clickgui.Visible
				end
			end
			clickgui.Visible = not clickgui.Visible
			tooltip.Visible = false
			self:BlurCheck()
		end)
	end
end

function mainapi:LoadOptions(object, savedoptions)
	for i, v in savedoptions do
		local option = object.Options[i]
		if not option then continue end
		option:Load(v)
	end
end

function mainapi:Remove(obj)
	local tab = (self.Modules[obj] and self.Modules or self.Legit.Modules[obj] and self.Legit.Modules or self.Categories)
	if tab and tab[obj] then
		local newobj = tab[obj]
		if self.ThreadFix then
			setthreadidentity(8)
		end

		for _, v in {'Object', 'Children', 'Toggle', 'Button'} do
			local childobj = typeof(newobj[v]) == 'table' and newobj[v].Object or newobj[v]
			if typeof(childobj) == 'Instance' then
				childobj:Destroy()
				childobj:ClearAllChildren()
			end
		end

		loopClean(newobj)
		tab[obj] = nil
	end
end

function mainapi:Save(newprofile)
	if not self.Loaded then return end
	local guidata = {
		Categories = {},
		Profile = newprofile or self.Profile,
		Profiles = self.Profiles,
		Keybind = self.Keybind
	}
	local savedata = {
		Modules = {},
		Categories = {},
		Legit = {}
	}

	for i, v in self.Categories do
		(v.Type ~= 'Category' and i ~= 'Main' and savedata or guidata).Categories[i] = {
			Enabled = i ~= 'Main' and v.Button.Enabled or nil,
			Expanded = v.Type ~= 'Overlay' and v.Expanded or nil,
			Pinned = v.Pinned,
			Position = {X = v.Object.Position.X.Offset, Y = v.Object.Position.Y.Offset},
			Options = mainapi:SaveOptions(v, v.Options),
			List = v.List,
			ListEnabled = v.ListEnabled
		}
	end

	for i, v in self.Modules do
		savedata.Modules[i] = {
			Enabled = v.Enabled,
			Bind = v.Bind.Button and {Mobile = true, X = v.Bind.Button.Position.X.Offset, Y = v.Bind.Button.Position.Y.Offset} or v.Bind,
			Options = mainapi:SaveOptions(v, true)
		}
	end

	for i, v in self.Legit.Modules do
		savedata.Legit[i] = {
			Enabled = v.Enabled,
			Position = v.Children and {X = v.Children.Position.X.Offset, Y = v.Children.Position.Y.Offset} or nil,
			Options = mainapi:SaveOptions(v, v.Options)
		}
	end

	writefile('badscript/profiles/'..game.GameId..'.gui.txt', httpService:JSONEncode(guidata))
	writefile('badscript/profiles/'..self.Profile..self.Place..'.txt', httpService:JSONEncode(savedata))
end

function mainapi:SaveOptions(object, savedoptions)
	if not savedoptions then return end
	savedoptions = {}
	for _, v in object.Options do
		if not v.Save then continue end
		v:Save(savedoptions)
	end
	return savedoptions
end

function mainapi:Uninject()
	mainapi:Save()
	mainapi.Loaded = nil
	for _, v in self.Modules do
		if v.Enabled then
			v:Toggle()
		end
	end
	for _, v in self.Legit.Modules do
		if v.Enabled then
			v:Toggle()
		end
	end
	for _, v in self.Categories do
		if v.Type == 'Overlay' and v.Button.Enabled then
			v.Button:Toggle()
		end
	end
	for _, v in mainapi.Connections do
		pcall(function()
			v:Disconnect()
		end)
	end
	if mainapi.ThreadFix then
		setthreadidentity(8)
		clickgui.Visible = false
		mainapi:BlurCheck()
	end
	mainapi.gui:ClearAllChildren()
	mainapi.gui:Destroy()
	table.clear(mainapi.Connections)
	table.clear(mainapi.Libraries)
	loopClean(mainapi)
	shared.Bad = nil
	shared.Badreload = nil
	shared.BadIndependent = nil
end

gui = Instance.new('ScreenGui')
gui.Name = randomString()
gui.DisplayOrder = 9999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true
gui.OnTopOfCoreBlur = true
if mainapi.ThreadFix then
	gui.Parent = cloneref(game:GetService('CoreGui'))--(gethui and gethui()) or cloneref(game:GetService('CoreGui'))
else
	gui.Parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
	gui.ResetOnSpawn = false
end
mainapi:Clean(inputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F2 and mainapi.Console then
		mainapi.Console.Visible = not mainapi.Console.Visible
	end
end))
mainapi.gui = gui
scaledgui = Instance.new('Frame')
scaledgui.Name = 'ScaledGui'
scaledgui.Size = UDim2.fromScale(1, 1)
scaledgui.BackgroundTransparency = 1
scaledgui.Parent = gui
clickgui = Instance.new('Frame')
clickgui.Name = 'ClickGui'
clickgui.Size = UDim2.fromScale(1, 1)
clickgui.BackgroundTransparency = 1
clickgui.Visible = false
clickgui.Parent = scaledgui
local scarcitybanner = Instance.new('TextLabel')
scarcitybanner.Size = UDim2.fromScale(1, 0.02)
scarcitybanner.Position = UDim2.fromScale(0, 0.97)
scarcitybanner.BackgroundTransparency = 1
scarcitybanner.Text = 'The discord link has been fixed, click the discord icon to join.'
scarcitybanner.TextScaled = true
scarcitybanner.TextColor3 = Color3.new(1, 1, 1)
scarcitybanner.TextStrokeTransparency = 0.5
scarcitybanner.FontFace = uipallet.Font
scarcitybanner.Parent = clickgui
local modal = Instance.new('TextButton')
modal.BackgroundTransparency = 1
modal.Modal = true
modal.Text = ''
modal.Parent = clickgui
local cursor = Instance.new('ImageLabel')
cursor.Size = UDim2.fromOffset(64, 64)
cursor.BackgroundTransparency = 1
cursor.Visible = false
cursor.Image = 'rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png'
cursor.Parent = gui
notifications = Instance.new('Folder')
notifications.Name = 'Notifications'
notifications.Parent = scaledgui

-- Separate container for runtime error notifications
local errorNotificationContainer = Instance.new('Frame')
errorNotificationContainer.Name = 'ErrorNotifications'
errorNotificationContainer.Size = UDim2.new(0, 380, 1, -40)
errorNotificationContainer.Position = UDim2.new(1, -10, 0, 20)
errorNotificationContainer.BackgroundTransparency = 1
errorNotificationContainer.Parent = scaledgui
errorNotificationContainer.ZIndex = 10
local errorListLayout = Instance.new('UIListLayout')
errorListLayout.Parent = errorNotificationContainer
errorListLayout.SortOrder = Enum.SortOrder.LayoutOrder
errorListLayout.Padding = UDim.new(0, 5)
tooltip = Instance.new('TextLabel')
tooltip.Name = 'Tooltip'
tooltip.Position = UDim2.fromScale(-1, -1)
tooltip.ZIndex = 5
tooltip.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
tooltip.Visible = false
tooltip.Text = ''
tooltip.TextColor3 = color.Dark(uipallet.Text, 0.16)
tooltip.TextSize = 12
tooltip.FontFace = uipallet.Font
tooltip.Parent = scaledgui
toolblur = addBlur(tooltip)
addCorner(tooltip)
local toolstrokebkg = Instance.new('Frame')
toolstrokebkg.Size = UDim2.new(1, -2, 1, -2)
toolstrokebkg.Position = UDim2.fromOffset(1, 1)
toolstrokebkg.ZIndex = 6
toolstrokebkg.BackgroundTransparency = 1
toolstrokebkg.Parent = tooltip
local toolstroke = Instance.new('UIStroke')
toolstroke.Color = color.Light(uipallet.Main, 0.02)
toolstroke.Parent = toolstrokebkg
addCorner(toolstrokebkg, UDim.new(0, 4))
scale = Instance.new('UIScale')
scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
scale.Parent = scaledgui
mainapi.guiscale = scale
scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)

mainapi:Clean(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
	if mainapi.Scale.Enabled then
		scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
	end
end))

mainapi:Clean(scale:GetPropertyChangedSignal('Scale'):Connect(function()
	scaledgui.Size = UDim2.fromScale(1 / scale.Scale, 1 / scale.Scale)
	for _, v in scaledgui:GetDescendants() do
		if v:IsA('GuiObject') and v.Visible then
			v.Visible = false
			v.Visible = true
		end
	end
end))

mainapi:Clean(clickgui:GetPropertyChangedSignal('Visible'):Connect(function()
	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
	if clickgui.Visible and inputService.MouseEnabled then
		repeat
			local visibleCheck = clickgui.Visible
			for _, v in mainapi.Windows do
				visibleCheck = visibleCheck or v.Visible
			end
			if not visibleCheck then break end

			cursor.Visible = not inputService.MouseIconEnabled
			if cursor.Visible then
				local mouseLocation = inputService:GetMouseLocation()
				cursor.Position = UDim2.fromOffset(mouseLocation.X - 31, mouseLocation.Y - 32)
			end

			task.wait()
		until mainapi.Loaded == nil
		cursor.Visible = false
	end
end))

mainapi:CreateGUI()
mainapi.Categories.Main:CreateDivider()
mainapi:CreateCategory({
	Name = 'Combat',
	Icon = getcustomasset('badscript/assets/new/combaticon.png'),
	Size = UDim2.fromOffset(13, 14)
})
mainapi:CreateCategory({
	Name = 'Blatant',
	Icon = getcustomasset('badscript/assets/new/blatanticon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Render',
	Icon = getcustomasset('badscript/assets/new/rendericon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'Utility',
	Icon = getcustomasset('badscript/assets/new/utilityicon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'World',
	Icon = getcustomasset('badscript/assets/new/worldicon.png'),
	Size = UDim2.fromOffset(14, 14)
})
mainapi:CreateCategory({
	Name = 'Inventory',
	Icon = getcustomasset('badscript/assets/new/inventoryicon.png'),
	Size = UDim2.fromOffset(15, 14)
})
mainapi:CreateCategory({
	Name = 'Minigames',
	Icon = getcustomasset('badscript/assets/new/miniicon.png'),
	Size = UDim2.fromOffset(19, 12)
})
mainapi.Categories.Main:CreateDivider('misc')

--[[
	Friends
]]
local friends
local friendscolor = {
	Hue = 1,
	Sat = 1,
	Value = 1
}
local friendssettings = {
	Name = 'Friends',
	Icon = getcustomasset('badscript/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Color = Color3.fromRGB(5, 134, 105),
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
}
friends = mainapi:CreateCategoryList(friendssettings)
friends.Update = Instance.new('BindableEvent')
friends.ColorUpdate = Instance.new('BindableEvent')
friends:CreateToggle({
	Name = 'Recolor visuals',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
friendscolor = friends:CreateColorSlider({
	Name = 'Friends color',
	Darker = true,
	Function = function(hue, sat, val)
		for _, v in friends.Object.Children:GetChildren() do
			local dot = v:FindFirstChild('Dot')
			if dot and dot.BackgroundColor3 ~= color.Light(uipallet.Main, 0.37) then
				dot.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				dot.Dot.BackgroundColor3 = dot.BackgroundColor3
			end
		end
		friendssettings.Color = Color3.fromHSV(hue, sat, val)
		friends.ColorUpdate:Fire(hue, sat, val)
	end
})
friends:CreateToggle({
	Name = 'Use friends',
	Darker = true,
	Default = true,
	Function = function()
		friends.Update:Fire()
		friends.ColorUpdate:Fire(friendscolor.Hue, friendscolor.Sat, friendscolor.Value)
	end
})
mainapi:Clean(friends.Update)
mainapi:Clean(friends.ColorUpdate)

--[[
	Profiles
]]
mainapi:CreateCategoryList({
	Name = 'Profiles',
	Icon = getcustomasset('badscript/assets/new/profilesicon.png'),
	Size = UDim2.fromOffset(17, 10),
	Position = UDim2.fromOffset(12, 16),
	Placeholder = 'Type name',
	Profiles = true
})

--[[
	Targets
]]
local targets
targets = mainapi:CreateCategoryList({
	Name = 'Targets',
	Icon = getcustomasset('badscript/assets/new/friendstab.png'),
	Size = UDim2.fromOffset(17, 16),
	Placeholder = 'Roblox username',
	Function = function()
		targets.Update:Fire()
	end
})
targets.Update = Instance.new('BindableEvent')
mainapi:Clean(targets.Update)

mainapi:CreateLegit()
mainapi:CreateSearch()
mainapi.Categories.Main:CreateOverlayBar()
mainapi.Categories.Main:CreateSettingsDivider()

--[[
	General Settings
]]

local general = mainapi.Categories.Main:CreateSettingsPane({Name = 'General'})
mainapi.MultiKeybind = general:CreateToggle({
	Name = 'Enable Multi-Keybinding',
	Tooltip = 'Allows multiple keys to be bound to a module (eg. G + H)'
})
general:CreateButton({
	Name = 'Reset current profile',
	Function = function()
	mainapi.Save = function() end
		if isfile('badscript/profiles/'..mainapi.Profile..mainapi.Place..'.txt') and delfile then
			delfile('badscript/profiles/'..mainapi.Profile..mainapi.Place..'.txt')
		end
		shared.Badreload = true
		if shared.BadDeveloper then
			loadstring(readfile('badscript/loader.lua'), 'loader')()
		else
			loadstring(safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()
		end
	end,
	Tooltip = 'This will set your profile to the default settings of Bad'
})
general:CreateButton({
	Name = 'Self destruct',
	Function = function()
		mainapi:Uninject()
	end,
	Tooltip = 'Removes Bad from the current game'
})
general:CreateButton({
	Name = 'Reinject',
	Function = function()
		shared.Badreload = true
		if shared.BadDeveloper then
			loadstring(readfile('badscript/loader.lua'), 'loader')()
		else
			loadstring(safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()
		end
	end,
	Tooltip = 'Reloads Bad for debugging purposes'
})

--[[
	Module Settings
]]

local modules = mainapi.Categories.Main:CreateSettingsPane({Name = 'Modules'})
modules:CreateToggle({
	Name = 'Teams by server',
	Tooltip = 'Ignore players on your team designated by the server',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})
modules:CreateToggle({
	Name = 'Use team color',
	Tooltip = 'Uses the TeamColor property on players for render modules',
	Default = true,
	Function = function()
		if mainapi.Libraries.entity and mainapi.Libraries.entity.Running then
			mainapi.Libraries.entity.refresh()
		end
	end
})

--[[
	GUI Settings
]]

local guipane = mainapi.Categories.Main:CreateSettingsPane({Name = 'GUI'})
mainapi.Blur = guipane:CreateToggle({
	Name = 'Blur background',
	Function = function()
		mainapi:BlurCheck()
	end,
	Default = false,
	Tooltip = 'Blur the background of the GUI'
})
guipane:CreateToggle({
	Name = 'GUI bind indicator',
	Default = true,
	Tooltip = "Displays a message indicating your GUI upon injecting.\nI.E. 'Press RSHIFT to open GUI'"
})
guipane:CreateToggle({
	Name = 'Show tooltips',
	Function = function(enabled)
		tooltip.Visible = false
		toolblur.Visible = enabled
	end,
	Default = true,
	Tooltip = 'Toggles visibility of these'
})
guipane:CreateToggle({
	Name = 'Show legit mode',
	Function = function(enabled)
		clickgui.Search.Legit.Visible = enabled
		clickgui.Search.LegitDivider.Visible = enabled
		clickgui.Search.TextBox.Size = UDim2.new(1, enabled and -50 or -10, 0, 37)
		clickgui.Search.TextBox.Position = UDim2.fromOffset(enabled and 50 or 10, 0)
	end,
	Default = true,
	Tooltip = 'Shows the button to change to Legit Mode'
})
local scaleslider = {Object = {}, Value = 1}
mainapi.Scale = guipane:CreateToggle({
	Name = 'Auto rescale',
	Default = true,
	Function = function(callback)
		scaleslider.Object.Visible = not callback
		if callback then
			scale.Scale = math.max(gui.AbsoluteSize.X / 1920, 0.6)
		else
			scale.Scale = scaleslider.Value
		end
	end,
	Tooltip = 'Automatically rescales the gui using the screens resolution'
})
scaleslider = guipane:CreateSlider({
	Name = 'Scale',
	Min = 0.1,
	Max = 2,
	Decimal = 10,
	Function = function(val, final)
		if final and not mainapi.Scale.Enabled then
			scale.Scale = val
		end
	end,
	Default = 1,
	Darker = true,
	Visible = false
})
guipane:CreateDropdown({
	Name = 'GUI Theme',
	List = inputService.TouchEnabled and {'new', 'old'} or {'new', 'old', 'rise'},
	Function = function(val, mouse)
		if mouse then
			writefile('badscript/profiles/gui.txt', val)
			shared.Badreload = true
			if shared.BadDeveloper then
				loadstring(readfile('badscript/loader.lua'), 'loader')()
			else
				loadstring(safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()
			end
		end
	end,
	Tooltip = 'new - The newest Bad theme to since v4.05\nold - The Bad theme pre v4.05\nrise - Rise 6.0'
})
mainapi.RainbowMode = guipane:CreateDropdown({
	Name = 'Rainbow Mode',
	List = {'Normal', 'Gradient', 'Retro'},
	Tooltip = 'Normal - Smooth color fade\nGradient - Gradient color fade\nRetro - Static color'
})
mainapi.RainbowSpeed = guipane:CreateSlider({
	Name = 'Rainbow speed',
	Min = 0.1,
	Max = 10,
	Decimal = 10,
	Default = 1,
	Tooltip = 'Adjusts the speed of rainbow values'
})
mainapi.RainbowUpdateSpeed = guipane:CreateSlider({
	Name = 'Rainbow update rate',
	Min = 1,
	Max = 144,
	Default = 60,
	Tooltip = 'Adjusts the update rate of rainbow values',
	Suffix = 'hz'
})
guipane:CreateButton({
	Name = 'Reset GUI positions',
	Function = function()
		for _, v in mainapi.Categories do
			v.Object.Position = UDim2.fromOffset(6, 42)
		end
	end,
	Tooltip = 'This will reset your GUI back to default'
})
guipane:CreateButton({
	Name = 'Sort GUI',
	Function = function()
		local priority = {
			GUICategory = 1,
			CombatCategory = 2,
			BlatantCategory = 3,
			RenderCategory = 4,
			UtilityCategory = 5,
			WorldCategory = 6,
			InventoryCategory = 7,
			MinigamesCategory = 8,
			FriendsCategory = 9,
			ProfilesCategory = 10
		}
		local categories = {}
		for _, v in mainapi.Categories do
			if v.Type ~= 'Overlay' then
				table.insert(categories, v)
			end
		end
		table.sort(categories, function(a, b)
			return (priority[a.Object.Name] or 99) < (priority[b.Object.Name] or 99)
		end)

		local ind = 0
		for _, v in categories do
			if v.Object.Visible then
				v.Object.Position = UDim2.fromOffset(6 + (ind % 8 * 230), 60 + (ind > 7 and 360 or 0))
				ind += 1
			end
		end
	end,
	Tooltip = 'Sorts GUI'
})

--[[
	Notification Settings
]]

local notifpane = mainapi.Categories.Main:CreateSettingsPane({Name = 'Notifications'})
mainapi.Notifications = notifpane:CreateToggle({
	Name = 'Notifications',
	Function = function(enabled)
		if mainapi.ToggleNotifications.Object then
			mainapi.ToggleNotifications.Object.Visible = enabled
		end
	end,
	Tooltip = 'Shows notifications',
	Default = true
})
mainapi.ToggleNotifications = notifpane:CreateToggle({
	Name = 'Toggle alert',
	Tooltip = 'Notifies you if a module is enabled/disabled.',
	Default = true,
	Darker = true
})

mainapi.GUIColor = mainapi.Categories.Main:CreateGUISlider({
	Name = 'GUI Theme',
	Function = function(h, s, v)
		mainapi:UpdateGUI(h, s, v, true)
	end
})
mainapi.Categories.Main:CreateBind()

--[[
	Text GUI
]]

local textgui = mainapi:CreateOverlay({
	Name = 'Text GUI',
	Icon = getcustomasset('badscript/assets/new/textguiicon.png'),
	Size = UDim2.fromOffset(16, 12),
	Position = UDim2.fromOffset(12, 14),
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguisort = textgui:CreateDropdown({
	Name = 'Sort',
	List = {'Alphabetical', 'Length'},
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguifont = textgui:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguicolor
local textguicolordrop = textgui:CreateDropdown({
	Name = 'Color Mode',
	List = {'Match GUI color', 'Custom color'},
	Function = function(val)
		textguicolor.Object.Visible = val == 'Custom color'
		mainapi:UpdateTextGUI()
	end
})
textguicolor = textgui:CreateColorSlider({
	Name = 'Text GUI color',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
local BadTextScale = Instance.new('UIScale')
BadTextScale.Parent = textgui.Children
local textguiscale = textgui:CreateSlider({
	Name = 'Scale',
	Min = 0,
	Max = 2,
	Decimal = 10,
	Default = 1,
	Function = function(val)
		BadTextScale.Scale = val
		mainapi:UpdateTextGUI()
	end
})
local textguishadow = textgui:CreateToggle({
	Name = 'Shadow',
	Tooltip = 'Renders shadowed text.',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguigradientv4
local textguigradient = textgui:CreateToggle({
	Name = 'Gradient',
	Tooltip = 'Renders a gradient',
	Function = function(callback)
		textguigradientv4.Object.Visible = callback
		mainapi:UpdateTextGUI()
	end
})
textguigradientv4 = textgui:CreateToggle({
	Name = 'V4 Gradient',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
local textguianimations = textgui:CreateToggle({
	Name = 'Animations',
	Tooltip = 'Use animations on text gui',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguiwatermark = textgui:CreateToggle({
	Name = 'Watermark',
	Tooltip = 'Renders a Bad watermark',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguibackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local textguibackgroundtint = {Enabled = false}
local textguibackground = textgui:CreateToggle({
	Name = 'Render background',
	Function = function(callback)
		textguibackgroundtransparency.Object.Visible = callback
		textguibackgroundtint.Object.Visible = callback
		mainapi:UpdateTextGUI()
	end
})
textguibackgroundtransparency = textgui:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguibackgroundtint = textgui:CreateToggle({
	Name = 'Tint',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
local textguimoduleslist
local textguimodules = textgui:CreateToggle({
	Name = 'Hide modules',
	Tooltip = 'Allows you to blacklist certain modules from being shown.',
	Function = function(enabled)
		textguimoduleslist.Object.Visible = enabled
		mainapi:UpdateTextGUI()
	end
})
textguimoduleslist = textgui:CreateTextList({
	Name = 'Blacklist',
	Tooltip = 'Name of module to hide.',
	Icon = getcustomasset('badscript/assets/new/blockedicon.png'),
	Tab = getcustomasset('badscript/assets/new/blockedtab.png'),
	TabSize = UDim2.fromOffset(21, 16),
	Color = Color3.fromRGB(250, 50, 56),
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Visible = false,
	Darker = true
})
local textguirender = textgui:CreateToggle({
	Name = 'Hide render',
	Function = function()
		mainapi:UpdateTextGUI()
	end
})
local textguibox
local textguifontcustom
local textguicolorcustomtoggle
local textguicolorcustom
local textguitext = textgui:CreateToggle({
	Name = 'Add custom text',
	Function = function(enabled)
		textguibox.Object.Visible = enabled
		textguifontcustom.Object.Visible = enabled
		textguicolorcustomtoggle.Object.Visible = enabled
		textguicolorcustom.Object.Visible = textguicolorcustomtoggle.Enabled and enabled
		mainapi:UpdateTextGUI()
	end
})
textguibox = textgui:CreateTextBox({
	Name = 'Custom text',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguifontcustom = textgui:CreateFont({
	Name = 'Custom Font',
	Blacklist = 'Arial',
	Function = function()
		mainapi:UpdateTextGUI()
	end,
	Darker = true,
	Visible = false
})
textguicolorcustomtoggle = textgui:CreateToggle({
	Name = 'Set custom text color',
	Function = function(enabled)
		textguicolorcustom.Object.Visible = enabled
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})
textguicolorcustom = textgui:CreateColorSlider({
	Name = 'Color of custom text',
	Function = function()
		mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value)
	end,
	Darker = true,
	Visible = false
})

--[[
	Text GUI Objects
]]

local BadLabels = {}
local BadLogo = Instance.new('ImageLabel')
BadLogo.Name = 'Logo'
BadLogo.Size = UDim2.fromOffset(80, 21)
BadLogo.Position = UDim2.new(1, -142, 0, 3)
BadLogo.BackgroundTransparency = 1
BadLogo.BorderSizePixel = 0
BadLogo.Visible = false
BadLogo.BackgroundColor3 = Color3.new()
BadLogo.Image = getcustomasset('badscript/assets/new/textBad.png')
BadLogo.Parent = textgui.Children

local lastside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
mainapi:Clean(textgui.Children:GetPropertyChangedSignal('AbsolutePosition'):Connect(function()
	if mainapi.ThreadFix then
		setthreadidentity(8)
	end
	local newside = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
	if lastside ~= newside then
		lastside = newside
		mainapi:UpdateTextGUI()
	end
end))

local BadLogoV4 = Instance.new('ImageLabel')
BadLogoV4.Name = 'Logo2'
BadLogoV4.Size = UDim2.fromOffset(33, 18)
BadLogoV4.Position = UDim2.new(1, 1, 0, 1)
BadLogoV4.BackgroundColor3 = Color3.new()
BadLogoV4.BackgroundTransparency = 1
BadLogoV4.BorderSizePixel = 0
BadLogoV4.Image = getcustomasset('badscript/assets/new/textv4.png')
BadLogoV4.Parent = BadLogo
local BadLogoShadow = BadLogo:Clone()
BadLogoShadow.Position = UDim2.fromOffset(1, 1)
BadLogoShadow.ZIndex = 0
BadLogoShadow.Visible = true
BadLogoShadow.ImageColor3 = Color3.new()
BadLogoShadow.ImageTransparency = 0.65
BadLogoShadow.Parent = BadLogo
BadLogoShadow.Logo2.ZIndex = 0
BadLogoShadow.Logo2.ImageColor3 = Color3.new()
BadLogoShadow.Logo2.ImageTransparency = 0.65
local BadLogoGradient = Instance.new('UIGradient')
BadLogoGradient.Rotation = 90
BadLogoGradient.Parent = BadLogo
local BadLogoGradient2 = Instance.new('UIGradient')
BadLogoGradient2.Rotation = 90
BadLogoGradient2.Parent = BadLogoV4
local BadLabelCustom = Instance.new('TextLabel')
BadLabelCustom.Position = UDim2.fromOffset(5, 2)
BadLabelCustom.BackgroundTransparency = 1
BadLabelCustom.BorderSizePixel = 0
BadLabelCustom.Visible = false
BadLabelCustom.Text = ''
BadLabelCustom.TextSize = 25
BadLabelCustom.FontFace = textguifontcustom.Value
BadLabelCustom.RichText = true
local BadLabelCustomShadow = BadLabelCustom:Clone()
BadLabelCustom:GetPropertyChangedSignal('Position'):Connect(function()
	BadLabelCustomShadow.Position = UDim2.new(
		BadLabelCustom.Position.X.Scale,
		BadLabelCustom.Position.X.Offset + 1,
		0,
		BadLabelCustom.Position.Y.Offset + 1
	)
end)
BadLabelCustom:GetPropertyChangedSignal('FontFace'):Connect(function()
	BadLabelCustomShadow.FontFace = BadLabelCustom.FontFace
end)
BadLabelCustom:GetPropertyChangedSignal('Text'):Connect(function()
	BadLabelCustomShadow.Text = removeTags(BadLabelCustom.Text)
end)
BadLabelCustom:GetPropertyChangedSignal('Size'):Connect(function()
	BadLabelCustomShadow.Size = BadLabelCustom.Size
end)
BadLabelCustomShadow.TextColor3 = Color3.new()
BadLabelCustomShadow.TextTransparency = 0.65
BadLabelCustomShadow.Parent = textgui.Children
BadLabelCustom.Parent = textgui.Children
local BadLabelHolder = Instance.new('Frame')
BadLabelHolder.Name = 'Holder'
BadLabelHolder.Size = UDim2.fromScale(1, 1)
BadLabelHolder.Position = UDim2.fromOffset(5, 37)
BadLabelHolder.BackgroundTransparency = 1
BadLabelHolder.Parent = textgui.Children
local BadLabelSorter = Instance.new('UIListLayout')
BadLabelSorter.HorizontalAlignment = Enum.HorizontalAlignment.Right
BadLabelSorter.VerticalAlignment = Enum.VerticalAlignment.Top
BadLabelSorter.SortOrder = Enum.SortOrder.LayoutOrder
BadLabelSorter.Parent = BadLabelHolder

--[[
	Target Info
]]

local targetinfo
local targetinfoobj
local targetinfobcolor
targetinfoobj = mainapi:CreateOverlay({
	Name = 'Target Info',
	Icon = getcustomasset('badscript/assets/new/targetinfoicon.png'),
	Size = UDim2.fromOffset(14, 14),
	Position = UDim2.fromOffset(12, 14),
	CategorySize = 240,
	Function = function(callback)
		if callback then
			task.spawn(function()
				repeat
					targetinfo:UpdateInfo()
					task.wait()
				until not targetinfoobj.Button or not targetinfoobj.Button.Enabled
			end)
		end
	end
})

local targetinfobkg = Instance.new('Frame')
targetinfobkg.Size = UDim2.fromOffset(240, 89)
targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
targetinfobkg.BackgroundTransparency = 0.5
targetinfobkg.Parent = targetinfoobj.Children
local targetinfoblurobj = addBlur(targetinfobkg)
targetinfoblurobj.Visible = false
addCorner(targetinfobkg)
local targetinfoshot = Instance.new('ImageLabel')
targetinfoshot.Size = UDim2.fromOffset(26, 27)
targetinfoshot.Position = UDim2.fromOffset(19, 17)
targetinfoshot.BackgroundColor3 = uipallet.Main
targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420'
targetinfoshot.Parent = targetinfobkg
local targetinfoshotflash = Instance.new('Frame')
targetinfoshotflash.Size = UDim2.fromScale(1, 1)
targetinfoshotflash.BackgroundTransparency = 1
targetinfoshotflash.BackgroundColor3 = Color3.new(1, 0, 0)
targetinfoshotflash.Parent = targetinfoshot
addCorner(targetinfoshotflash)
local targetinfoshotblur = addBlur(targetinfoshot)
targetinfoshotblur.Visible = false
addCorner(targetinfoshot)
local targetinfoname = Instance.new('TextLabel')
targetinfoname.Size = UDim2.fromOffset(145, 20)
targetinfoname.Position = UDim2.fromOffset(54, 20)
targetinfoname.BackgroundTransparency = 1
targetinfoname.Text = 'Target name'
targetinfoname.TextXAlignment = Enum.TextXAlignment.Left
targetinfoname.TextYAlignment = Enum.TextYAlignment.Top
targetinfoname.TextScaled = true
targetinfoname.TextColor3 = color.Light(uipallet.Text, 0.4)
targetinfoname.TextStrokeTransparency = 1
targetinfoname.FontFace = uipallet.Font
local targetinfoshadow = targetinfoname:Clone()
targetinfoshadow.Position = UDim2.fromOffset(55, 21)
targetinfoshadow.TextColor3 = Color3.new()
targetinfoshadow.TextTransparency = 0.65
targetinfoshadow.Visible = false
targetinfoshadow.Parent = targetinfobkg
targetinfoname:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfoshadow.Size = targetinfoname.Size
end)
targetinfoname:GetPropertyChangedSignal('Text'):Connect(function()
	targetinfoshadow.Text = targetinfoname.Text
end)
targetinfoname:GetPropertyChangedSignal('FontFace'):Connect(function()
	targetinfoshadow.FontFace = targetinfoname.FontFace
end)
targetinfoname.Parent = targetinfobkg
local targetinfohealthbkg = Instance.new('Frame')
targetinfohealthbkg.Name = 'HealthBKG'
targetinfohealthbkg.Size = UDim2.fromOffset(200, 9)
targetinfohealthbkg.Position = UDim2.fromOffset(20, 56)
targetinfohealthbkg.BackgroundColor3 = uipallet.Main
targetinfohealthbkg.BorderSizePixel = 0
targetinfohealthbkg.Parent = targetinfobkg
addCorner(targetinfohealthbkg, UDim.new(1, 0))
local targetinfohealth = targetinfohealthbkg:Clone()
targetinfohealth.Size = UDim2.fromScale(0.8, 1)
targetinfohealth.Position = UDim2.new()
targetinfohealth.BackgroundColor3 = Color3.fromHSV(1 / 2.5, 0.89, 0.75)
targetinfohealth.Parent = targetinfohealthbkg
targetinfohealth:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealth.Visible = targetinfohealth.Size.X.Scale > 0.01
end)
local targetinfohealthextra = targetinfohealth:Clone()
targetinfohealthextra.Size = UDim2.new()
targetinfohealthextra.Position = UDim2.fromScale(1, 0)
targetinfohealthextra.AnchorPoint = Vector2.new(1, 0)
targetinfohealthextra.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
targetinfohealthextra.Visible = false
targetinfohealthextra.Parent = targetinfohealthbkg
targetinfohealthextra:GetPropertyChangedSignal('Size'):Connect(function()
	targetinfohealthextra.Visible = targetinfohealthextra.Size.X.Scale > 0.01
end)
local targetinfohealthblur = addBlur(targetinfohealthbkg)
targetinfohealthblur.SliceCenter = Rect.new(52, 31, 261, 510)
targetinfohealthblur.ImageColor3 = Color3.new()
targetinfohealthblur.Visible = false
local targetinfob = Instance.new('UIStroke')
targetinfob.Enabled = false
targetinfob.Color = Color3.fromHSV(0.44, 1, 1)
targetinfob.Parent = targetinfobkg

targetinfoobj:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function(val)
		targetinfoname.FontFace = val
	end
})
local targetinfobackgroundtransparency = {
	Value = 0.5,
	Object = {Visible = {}}
}
local targetinfodisplay = targetinfoobj:CreateToggle({
	Name = 'Use Displayname',
	Default = true
})
targetinfoobj:CreateToggle({
	Name = 'Render Background',
	Function = function(callback)
		targetinfobkg.BackgroundTransparency = callback and targetinfobackgroundtransparency.Value or 1
		targetinfoshadow.Visible = not callback
		targetinfoblurobj.Visible = callback
		targetinfohealthblur.Visible = not callback
		targetinfoshotblur.Visible = not callback
		targetinfobackgroundtransparency.Object.Visible = callback
	end,
	Default = true
})
targetinfobackgroundtransparency = targetinfoobj:CreateSlider({
	Name = 'Transparency',
	Min = 0,
	Max = 1,
	Default = 0.5,
	Decimal = 10,
	Function = function(val)
		targetinfobkg.BackgroundTransparency = val
	end,
	Darker = true
})
local targetinfocolor
local targetinfocolortoggle = targetinfoobj:CreateToggle({
	Name = 'Custom Color',
	Function = function(callback)
		targetinfocolor.Object.Visible = callback
		if callback then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, targetinfocolor.Value)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(targetinfocolor.Hue, targetinfocolor.Sat, math.max(targetinfocolor.Value - 0.1, 0.075))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		else
			targetinfobkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.1)
			targetinfoshot.BackgroundColor3 = uipallet.Main
			targetinfohealthbkg.BackgroundColor3 = uipallet.Main
		end
	end
})
targetinfocolor = targetinfoobj:CreateColorSlider({
	Name = 'Color',
	Function = function(hue, sat, val)
		hue, sat, val = tonumber(hue) or 0.44, tonumber(sat) or 1, tonumber(val) or 1
		if targetinfocolortoggle.Enabled then
			targetinfobkg.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			targetinfoshot.BackgroundColor3 = Color3.fromHSV(hue, sat, math.max(val - 0.1, 0))
			targetinfohealthbkg.BackgroundColor3 = targetinfoshot.BackgroundColor3
		end
	end,
	Darker = true,
	Visible = false
})
targetinfoobj:CreateToggle({
	Name = 'Border',
	Function = function(callback)
		targetinfob.Enabled = callback
		targetinfobcolor.Object.Visible = callback
	end
})
targetinfobcolor = targetinfoobj:CreateColorSlider({
	Name = 'Border Color',
	Function = function(hue, sat, val, opacity)
		hue, sat, val = tonumber(hue) or 0.44, tonumber(sat) or 1, tonumber(val) or 1
		opacity = tonumber(opacity) or 1
		targetinfob.Color = Color3.fromHSV(hue, sat, val)
		targetinfob.Transparency = 1 - opacity
	end,
	Darker = true,
	Visible = false
})

local lasthealth = 0
local lastmaxhealth = 0
targetinfo = {
	Targets = {},
	Object = targetinfobkg,
	UpdateInfo = function(self)
		local entitylib = mainapi.Libraries
		if not entitylib then return end

		for i, v in self.Targets do
			if v < tick() then
				self.Targets[i] = nil
			end
		end

		local v, highest = nil, tick()
		for i, check in self.Targets do
			if check > highest then
				v = i
				highest = check
			end
		end

		targetinfobkg.Visible = v ~= nil or mainapi.gui.ScaledGui.ClickGui.Visible
		if v then
			targetinfoname.Text = v.Player and (targetinfodisplay.Enabled and v.Player.DisplayName or v.Player.Name) or v.Character and v.Character.Name or targetinfoname.Text
			targetinfoshot.Image = 'rbxthumb://type=AvatarHeadShot&id='..(v.Player and v.Player.UserId or 1)..'&w=420&h=420'

			if not v.Character then
				v.Health = v.Health or 0
				v.MaxHealth = v.MaxHealth or 100
			end

			if v.Health ~= lasthealth or v.MaxHealth ~= lastmaxhealth then
				local percent = math.max(v.Health / v.MaxHealth, 0)
				tween:Tween(targetinfohealth, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(math.min(percent, 1), 1), BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
				})
				tween:Tween(targetinfohealthextra, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(math.clamp(percent - 1, 0, 0.8), 1)
				})
				if lasthealth > v.Health and self.LastTarget == v then
					tween:Cancel(targetinfoshotflash)
					targetinfoshotflash.BackgroundTransparency = 0.3
					tween:Tween(targetinfoshotflash, TweenInfo.new(0.5), {
						BackgroundTransparency = 1
					})
				end
				lasthealth = v.Health
				lastmaxhealth = v.MaxHealth
			end

			if not v.Character then table.clear(v) end
			self.LastTarget = v
		end
		return v
	end
}
mainapi.Libraries.targetinfo = targetinfo

function mainapi:UpdateTextGUI(afterload)
	if not afterload and not mainapi.Loaded then return end
	if textgui.Button.Enabled then
		local right = textgui.Children.AbsolutePosition.X > (gui.AbsoluteSize.X / 2)
		BadLogo.Visible = textguiwatermark.Enabled
		BadLogo.Position = right and UDim2.new(1 / BadTextScale.Scale, -113, 0, 6) or UDim2.fromOffset(0, 6)
		BadLogoShadow.Visible = textguishadow.Enabled
		BadLabelCustom.Text = textguibox.Value
		BadLabelCustom.FontFace = textguifontcustom.Value
		BadLabelCustom.Visible = BadLabelCustom.Text ~= '' and textguitext.Enabled
		BadLabelCustomShadow.Visible = BadLabelCustom.Visible and textguishadow.Enabled
		BadLabelSorter.HorizontalAlignment = right and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		BadLabelHolder.Size = UDim2.fromScale(1 / BadTextScale.Scale, 1)
		BadLabelHolder.Position = UDim2.fromOffset(right and 3 or 0, 11 + (BadLogo.Visible and BadLogo.Size.Y.Offset or 0) + (BadLabelCustom.Visible and 28 or 0) + (textguibackground.Enabled and 3 or 0))
		if BadLabelCustom.Visible then
			local size = getfontsize(removeTags(BadLabelCustom.Text), BadLabelCustom.TextSize, BadLabelCustom.FontFace)
			BadLabelCustom.Size = UDim2.fromOffset(size.X, size.Y)
			BadLabelCustom.Position = UDim2.new(right and 1 / BadTextScale.Scale or 0, right and -size.X or 0, 0, (BadLogo.Visible and 32 or 8))
		end

		local found = {}
		for _, v in BadLabels do
			if v.Enabled then
				table.insert(found, v.Object.Name)
			end
			v.Object:Destroy()
		end
		table.clear(BadLabels)

		local info = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
		for i, v in mainapi.Modules do
			if textguimodules.Enabled and table.find(textguimoduleslist.ListEnabled, i) then continue end
			if textguirender.Enabled and v.Category == 'Render' then continue end
			if v.Enabled or table.find(found, i) then
				local holder = Instance.new('Frame')
				holder.Name = i
				holder.Size = UDim2.fromOffset()
				holder.BackgroundTransparency = 1
				holder.ClipsDescendants = true
				holder.Parent = BadLabelHolder
				local holderbackground
				local holdercolorline
				if textguibackground.Enabled then
					holderbackground = Instance.new('Frame')
					holderbackground.Size = UDim2.new(1, 3, 1, 0)
					holderbackground.BackgroundColor3 = color.Dark(uipallet.Main, 0.15)
					holderbackground.BackgroundTransparency = textguibackgroundtransparency.Value
					holderbackground.BorderSizePixel = 0
					holderbackground.Parent = holder
					local holderline = Instance.new('Frame')
					holderline.Size = UDim2.new(1, 0, 0, 1)
					holderline.Position = UDim2.new(0, 0, 1, -1)
					holderline.BackgroundColor3 = Color3.new()
					holderline.BackgroundTransparency = 0.928 + (0.072 * math.clamp((textguibackgroundtransparency.Value - 0.5) / 0.5, 0, 1))
					holderline.BorderSizePixel = 0
					holderline.Parent = holderbackground
					local holderline2 = holderline:Clone()
					holderline2.Name = 'Line'
					holderline2.Position = UDim2.new()
					holderline2.Parent = holderbackground
					holdercolorline = Instance.new('Frame')
					holdercolorline.Size = UDim2.new(0, 2, 1, 0)
					holdercolorline.Position = right and UDim2.new(1, -5, 0, 0) or UDim2.new()
					holdercolorline.BorderSizePixel = 0
					holdercolorline.Parent = holderbackground
				end
				local holdertext = Instance.new('TextLabel')
				holdertext.Position = UDim2.fromOffset(right and 3 or 6, 2)
				holdertext.BackgroundTransparency = 1
				holdertext.BorderSizePixel = 0
				holdertext.Text = i..(v.ExtraText and " <font color='#A8A8A8'>"..v.ExtraText()..'</font>' or '')
				holdertext.TextSize = 15
				holdertext.FontFace = textguifont.Value
				holdertext.RichText = true
				local size = getfontsize(removeTags(holdertext.Text), holdertext.TextSize, holdertext.FontFace)
				holdertext.Size = UDim2.fromOffset(size.X, size.Y)
				if textguishadow.Enabled then
					local holderdrop = holdertext:Clone()
					holderdrop.Position = UDim2.fromOffset(holdertext.Position.X.Offset + 1, holdertext.Position.Y.Offset + 1)
					holderdrop.Text = removeTags(holdertext.Text)
					holderdrop.TextColor3 = Color3.new()
					holderdrop.Parent = holder
				end
				holdertext.Parent = holder
				local holdersize = UDim2.fromOffset(size.X + 10, size.Y + (textguibackground.Enabled and 5 or 3))
				if textguianimations.Enabled then
					if not table.find(found, i) then
						tween:Tween(holder, info, {
							Size = holdersize
						})
					else
						holder.Size = holdersize
						if not v.Enabled then
							tween:Tween(holder, info, {
								Size = UDim2.fromOffset()
							})
						end
					end
				else
					holder.Size = v.Enabled and holdersize or UDim2.fromOffset()
				end
				table.insert(BadLabels, {
					Object = holder,
					Text = holdertext,
					Background = holderbackground,
					Color = holdercolorline,
					Enabled = v.Enabled
				})
			end
		end

		if textguisort.Value == 'Alphabetical' then
			table.sort(BadLabels, function(a, b)
				return a.Text.Text < b.Text.Text
			end)
		else
			table.sort(BadLabels, function(a, b)
				return a.Text.Size.X.Offset > b.Text.Size.X.Offset
			end)
		end

		for i, v in BadLabels do
			if v.Color then
				v.Color.Parent.Line.Visible = i ~= 1
			end
			v.Object.LayoutOrder = i
		end
	end

	mainapi:UpdateGUI(mainapi.GUIColor.Hue, mainapi.GUIColor.Sat, mainapi.GUIColor.Value, true)
end

function mainapi:UpdateGUI(hue, sat, val, default)
	if mainapi.Loaded == nil then return end
	if not default and mainapi.GUIColor.Rainbow then return end
	if textgui.Button.Enabled then
		BadLogoGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
			ColorSequenceKeypoint.new(1, textguigradient.Enabled and Color3.fromHSV(mainapi:Color((hue - 0.075) % 1)) or Color3.fromHSV(hue, sat, val))
		})
		BadLogoGradient2.Color = textguigradient.Enabled and textguigradientv4.Enabled and BadLogoGradient.Color or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
		})
		BadLabelCustom.TextColor3 = textguicolorcustomtoggle.Enabled and Color3.fromHSV(textguicolorcustom.Hue, textguicolorcustom.Sat, textguicolorcustom.Value) or BadLogoGradient.Color.Keypoints[2].Value

		local customcolor = textguicolordrop.Value == 'Custom color' and Color3.fromHSV(textguicolor.Hue, textguicolor.Sat, textguicolor.Value) or nil
		for i, v in BadLabels do
			v.Text.TextColor3 = customcolor or (mainapi.GUIColor.Rainbow and Color3.fromHSV(mainapi:Color((hue - ((textguigradient and i + 2 or i) * 0.025)) % 1)) or BadLogoGradient.Color.Keypoints[2].Value)
			if v.Color then
				v.Color.BackgroundColor3 = v.Text.TextColor3
			end
			if textguibackgroundtint.Enabled and v.Background then
				v.Background.BackgroundColor3 = color.Dark(v.Text.TextColor3, 0.75)
			end
		end
	end

	if not clickgui.Visible and not mainapi.Legit.Window.Visible then return end
	local rainbow = mainapi.GUIColor.Rainbow and mainapi.RainbowMode.Value ~= 'Retro'

	for i, v in mainapi.Categories do
		if i == 'Main' then
			v.Object.BadLogo.V4Logo.ImageColor3 = Color3.fromHSV(hue, sat, val)
			for _, button in v.Buttons do
				if button.Enabled then
					button.Object.TextColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
					if button.Icon then
						button.Icon.ImageColor3 = button.Object.TextColor3
					end
				end
			end
		end

		if v.Options then
			for _, option in v.Options do
				if option.Color then
					option:Color(hue, sat, val, rainbow)
				end
			end
		end

		if v.Type == 'CategoryList' then
			v.Object.Children.Add.AddButton.ImageColor3 = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
			if v.Selected then
				v.Selected.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color(hue % 1)) or Color3.fromHSV(hue, sat, val)
				v.Selected.Title.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
				v.Selected.Dots.Dots.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.Icon.ImageColor3 = v.Selected.Title.TextColor3
				v.Selected.Bind.TextLabel.TextColor3 = v.Selected.Title.TextColor3
			end
		end
	end

	for _, button in mainapi.Modules do
		if button.Enabled then
			button.Object.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1)) or Color3.fromHSV(hue, sat, val)
			button.Object.TextColor3 = mainapi.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19) or mainapi:TextColor(hue, sat, val)
			button.Object.UIGradient.Enabled = rainbow and mainapi.RainbowMode.Value == 'Gradient'
			if button.Object.UIGradient.Enabled then
				button.Object.BackgroundColor3 = Color3.new(1, 1, 1)
				button.Object.UIGradient.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(mainapi:Color((hue - (button.Index * 0.025)) % 1))),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(mainapi:Color((hue - ((button.Index + 1) * 0.025)) % 1)))
				})
			end
			button.Object.Bind.Icon.ImageColor3 = button.Object.TextColor3
			button.Object.Bind.TextLabel.TextColor3 = button.Object.TextColor3
			button.Object.Dots.Dots.ImageColor3 = button.Object.TextColor3
		end

		for _, option in button.Options do
			if option.Color then
				option:Color(hue, sat, val, rainbow)
			end
		end
	end

	for i, v in mainapi.Overlays.Toggles do
		if v.Enabled then
			tween:Cancel(v.Object.Knob)
			v.Object.Knob.BackgroundColor3 = rainbow and Color3.fromHSV(mainapi:Color((hue - (i * 0.075)) % 1)) or Color3.fromHSV(hue, sat, val)
		end
	end

	if mainapi.Legit.Icon then
		mainapi.Legit.Icon.ImageColor3 = Color3.fromHSV(hue, sat, val)
	end

	if mainapi.Legit.Window.Visible then
		for _, v in mainapi.Legit.Modules do
			if v.Enabled then
				tween:Cancel(v.Object.Knob)
				v.Object.Knob.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			end

			for _, option in v.Options do
				if option.Color then
					option:Color(hue, sat, val, rainbow)
				end
			end
		end
	end
end

mainapi:Clean(notifications.ChildRemoved:Connect(function()
	for i, v in notifications:GetChildren() do
		if tween.Tween then
			tween:Tween(v, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {
				Position = UDim2.new(1, 0, 1, -(29 + (78 * i)))
			})
		end
	end
end))

mainapi:Clean(inputService.InputBegan:Connect(function(inputObj)
	if not inputService:GetFocusedTextBox() and inputObj.KeyCode ~= Enum.KeyCode.Unknown then
		table.insert(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
		if mainapi.Binding then return end

		if checkKeybinds(mainapi.HeldKeybinds, mainapi.Keybind, inputObj.KeyCode.Name) then
			if mainapi.ThreadFix then
				setthreadidentity(8)
			end
			for _, v in mainapi.Windows do
				v.Visible = false
			end
			clickgui.Visible = not clickgui.Visible
			tooltip.Visible = false
			mainapi:BlurCheck()
		end

		local toggled = false
		for i, v in mainapi.Modules do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) then
				toggled = true
				if mainapi.ToggleNotifications.Enabled then
					mainapi:CreateNotification('Module Toggled', i.."<font color='#FFFFFF'> has been </font>"..(not v.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>").."<font color='#FFFFFF'>!</font>", 0.75)
				end
				v:Toggle(true)
			end
		end
		if toggled then
			mainapi:UpdateTextGUI()
		end

		for _, v in mainapi.Profiles do
			if checkKeybinds(mainapi.HeldKeybinds, v.Bind, inputObj.KeyCode.Name) and v.Name ~= mainapi.Profile then
				mainapi:Save(v.Name)
				mainapi:Load(true)
				break
			end
		end
	end
end))

mainapi:Clean(inputService.InputEnded:Connect(function(inputObj)
	if not inputService:GetFocusedTextBox() and inputObj.KeyCode ~= Enum.KeyCode.Unknown then
		if mainapi.Binding then
			if not mainapi.MultiKeybind.Enabled then
				mainapi.HeldKeybinds = {inputObj.KeyCode.Name}
			end
			mainapi.Binding:SetBind(checkKeybinds(mainapi.HeldKeybinds, mainapi.Binding.Bind, inputObj.KeyCode.Name) and {} or mainapi.HeldKeybinds, true)
			mainapi.Binding = nil
		end
	end

	local ind = table.find(mainapi.HeldKeybinds, inputObj.KeyCode.Name)
	if ind then
		table.remove(mainapi.HeldKeybinds, ind)
	end
end))

-- Custom Developer Console for BadWars
local consoleFrame
local logScrolling
local logListLayout
local activeLogs = {}
local maxVisibleLogs = 100
local isPaused = false
local autoScroll = true
local currentFilter = 'All'
local searchTerm = ''

local function createConsole()
	if consoleFrame then return end
	activeLogs = mainapi.Logs or activeLogs
	consoleFrame = Instance.new('Frame')
	consoleFrame.Name = 'BadWarsConsole'
	consoleFrame.Size = UDim2.fromOffset(600, 400)
	consoleFrame.Position = UDim2.fromOffset(100, 100)
	consoleFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	consoleFrame.BorderSizePixel = 0
	consoleFrame.Visible = false
	consoleFrame.ZIndex = 100
	consoleFrame.Parent = scaledgui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = consoleFrame

	local shadow = Instance.new('ImageLabel')
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.fromOffset(-10, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = 'rbxassetid://5554236805'
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ZIndex = 99
	shadow.Parent = consoleFrame

	-- Title bar
	local titleBar = Instance.new('Frame')
	titleBar.Size = UDim2.new(1, 0, 0, 30)
	titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	titleBar.BorderSizePixel = 0
	titleBar.Parent = consoleFrame

	local titleCorner = Instance.new('UICorner')
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleBar

	local title = Instance.new('TextLabel')
	title.Size = UDim2.new(1, -200, 1, 0)
	title.Position = UDim2.fromOffset(10, 0)
	title.BackgroundTransparency = 1
	title.Text = 'BadWars Developer Console'
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	-- Buttons
	local buttonY = 5
	local btnWidth = 70
	local pauseButton
	local btns = {
		{name = 'Clear', func = function() table.clear(activeLogs); updateConsole() end},
		{name = 'Pause', func = function()
			isPaused = not isPaused
			if pauseButton then pauseButton.Text = isPaused and 'Resume' or 'Pause' end
		end},
		{name = 'Copy All', func = function() local t = ''; for _, l in activeLogs do t = t .. l.time .. ' [' .. l.level .. '] ' .. l.message .. '\n' end; setclipboard(t) end},
		{name = 'Filter', func = function() -- cycle filter
			local levels = {'All', 'Info', 'Success', 'Warning', 'Debug', 'Error'}
			local idx = table.find(levels, currentFilter) or 1
			currentFilter = levels[idx % #levels + 1]
			updateConsole()
		end},
		{name = 'Compact', func = function() -- toggle compact
			-- simple toggle size or something
		end}
	}
	for i, b in ipairs(btns) do
		local btn = Instance.new('TextButton')
		btn.Size = UDim2.fromOffset(btnWidth, 20)
		btn.Position = UDim2.fromOffset( titleBar.AbsoluteSize.X - (btnWidth + 5) * i , buttonY)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		btn.Text = b.name
		btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 11
		btn.Parent = titleBar
		if b.name == 'Pause' then pauseButton = btn end
		local bc = Instance.new('UICorner')
		bc.CornerRadius = UDim.new(0, 4)
		bc.Parent = btn
		btn.MouseButton1Click:Connect(b.func)
	end

	-- Search
	local searchBox = Instance.new('TextBox')
	searchBox.Size = UDim2.fromOffset(150, 20)
	searchBox.Position = UDim2.fromOffset(10, 35)
	searchBox.PlaceholderText = 'Search logs...'
	searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	searchBox.Font = Enum.Font.Gotham
	searchBox.TextSize = 11
	searchBox.Parent = consoleFrame
	local sc = Instance.new('UICorner')
	sc.CornerRadius = UDim.new(0, 4)
	sc.Parent = searchBox
	searchBox:GetPropertyChangedSignal('Text'):Connect(function()
		searchTerm = searchBox.Text
		updateConsole()
	end)

	-- Log area
	logScrolling = Instance.new('ScrollingFrame')
	logScrolling.Size = UDim2.new(1, -20, 1, -80)
	logScrolling.Position = UDim2.fromOffset(10, 60)
	logScrolling.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
	logScrolling.BorderSizePixel = 0
	logScrolling.ScrollBarThickness = 6
	logScrolling.Parent = consoleFrame

	logListLayout = Instance.new('UIListLayout')
	logListLayout.Parent = logScrolling
	logListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logListLayout.Padding = UDim.new(0, 2)

	-- Make draggable
	local dragging, dragInput, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = consoleFrame.Position
		end
	end)
	titleBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	inputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			consoleFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Resize handle (simple)
	local resize = Instance.new('TextButton')
	resize.Size = UDim2.fromOffset(20, 20)
	resize.Position = UDim2.new(1, -20, 1, -20)
	resize.Text = '⤡'
	resize.BackgroundTransparency = 1
	resize.TextColor3 = Color3.fromRGB(200, 200, 200)
	resize.Parent = consoleFrame
	-- add resize logic similar to drag if needed

	updateConsole = function()
		if not logScrolling then return end
		logScrolling:ClearAllChildren()
		local visible = 0
		for i = #activeLogs, math.max(1, #activeLogs - maxVisibleLogs), -1 do
			local log = activeLogs[i]
			if currentFilter ~= 'All' and log.level ~= currentFilter then continue end
			if searchTerm ~= '' and not (log.message:lower():find(searchTerm:lower()) or (log.stack and log.stack:lower():find(searchTerm:lower()))) then continue end
			visible = visible + 1
			if visible > maxVisibleLogs then break end
			local entry = Instance.new('TextButton')
			entry.Size = UDim2.new(1, 0, 0, 22)
			entry.BackgroundTransparency = 1
			entry.Text = ''
			entry.Parent = logScrolling
			local timeLabel = Instance.new('TextLabel')
			timeLabel.Size = UDim2.fromOffset(50, 20)
			timeLabel.Position = UDim2.fromOffset(5, 1)
			timeLabel.BackgroundTransparency = 1
			timeLabel.Text = log.time
			timeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
			timeLabel.Font = Enum.Font.Gotham
			timeLabel.TextSize = 10
			timeLabel.Parent = entry
			local levelLabel = Instance.new('TextLabel')
			levelLabel.Size = UDim2.fromOffset(60, 20)
			levelLabel.Position = UDim2.fromOffset(55, 1)
			levelLabel.BackgroundTransparency = 1
			levelLabel.Text = '[' .. log.level .. ']'
			levelLabel.TextColor3 = mainapi.LogLevels[log.level] or Color3.fromRGB(200, 200, 200)
			levelLabel.Font = Enum.Font.GothamBold
			levelLabel.TextSize = 10
			levelLabel.Parent = entry
			local msgLabel = Instance.new('TextLabel')
			msgLabel.Size = UDim2.new(1, -130, 1, 0)
			msgLabel.Position = UDim2.fromOffset(120, 1)
			msgLabel.BackgroundTransparency = 1
			msgLabel.Text = log.message
			msgLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
			msgLabel.Font = Enum.Font.Gotham
			msgLabel.TextSize = 11
			msgLabel.TextXAlignment = Enum.TextXAlignment.Left
			msgLabel.TextTruncate = Enum.TextTruncate.AtEnd
			msgLabel.Parent = entry
			entry.MouseButton1Click:Connect(function()
				if log.stack then
					print('--- Full Stack for ' .. log.message .. ' ---\n' .. log.stack)
					-- or expand in UI
				end
			end)
		end
		if autoScroll then
			logScrolling.CanvasPosition = Vector2.new(0, logScrolling.AbsoluteCanvasSize.Y)
		end
	end

	mainapi.UpdateConsole = updateConsole

	-- Toggle with key or button (example with RightShift for console too, or separate)
	-- For now, toggle with a key in input

	-- Add to mainapi for external use
	mainapi.Console = consoleFrame
	mainapi.AddLog = AddLog
	mainapi.ShowConsole = function() consoleFrame.Visible = not consoleFrame.Visible end

	-- Initial update
	updateConsole()
end

-- Call to init console when ready
task.delay(1, createConsole)

return mainapi



















