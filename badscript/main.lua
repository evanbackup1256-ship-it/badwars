repeat task.wait() until game:IsLoaded()
if shared.Bad then shared.Bad:Uninject() end
shared.BadSecurityStarted = nil

-- Custom splash by usingINales for BadWars
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "BadWars",
		Text = "by usingINales | Dev Mode Active",
		Duration = 6
	})
end)

local Bad
local function setStatus(message, isError)
	if shared.BadStatus then
		shared.BadStatus(message, isError)
	end
end
local function notify(title, text, duration)
	pcall(function()
		setStatus('showing startup notification')
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = tostring(title or "BadWars"),
			Text = tostring(text or ""),
			Duration = duration or 8
		})
	end)
end
local oldLoadstring
pcall(function()
	local g = getgenv
	if type(g) == 'function' then g = g() end
	oldLoadstring = (g and g.loadstring) or loadstring
end)
if not oldLoadstring then oldLoadstring = function(...) error("loadstring not available in executor") end end
local loadstring = function(...)
	local realLoad = oldLoadstring or function() return nil, "loadstring not available" end
	local res, err = realLoad(...)
	if err then
		if Bad and type(Bad.CreateNotification) == 'function' then
			pcall(function()
				Bad:CreateNotification('BadWars', 'Failed to load : '..tostring(err), 30, 'alert')
			end)
		else
			warn('BadWars loadstring failed: ' .. tostring(err))
		end
	end
	return res, err
end
isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
delfile = delfile or function(file)
	writefile(file, '')
end
isfolder = isfolder or function() return false end
makefolder = makefolder or function() end
listfiles = listfiles or function() return {} end
readfile = readfile or function() return '' end
writefile = writefile or function() end
cloneref = cloneref or function(obj) return obj end
setthreadidentity = setthreadidentity or function() end
queue_on_teleport = queue_on_teleport or function() end
local function safeHttpGet(inst, url, nocache)
	local g = inst or game
	local httpget = g.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(g, url, nocache)
	end
	local httpService = cloneref(game:GetService('HttpService'))
	return httpService:GetAsync(url, nocache)
end
HttpGet = safeHttpGet
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not HttpGet or not game then
		setStatus('ERROR: HttpGet or game is nil for ' .. tostring(path), true)
		warn('BadWars: HttpGet or game is nil for ' .. tostring(path))
		return nil, 'HttpGet or game is nil'
	end
	local cached = isfile(path) and readfile(path) or nil
	if type(cached) ~= 'string' or cached == '' then
		setStatus('downloading ' .. tostring(path))
		local suc, res = pcall(function()
			-- Fixed: direct main + full path under badscript/
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path:gsub(' ', '%%20'), true)
		end)
		if not suc or (type(res) == 'string' and res:match('^%s*404:%s*Not Found%s*$')) then
			setStatus('ERROR downloading ' .. tostring(path) .. ': ' .. tostring(res), true)
			return nil, tostring(res)
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded)\n' .. res
		end
		writefile(path, res)
		cached = res
	end
	if type(cached) ~= 'string' or cached == '' then
		setStatus('ERROR empty file: ' .. tostring(path), true)
		return nil, 'empty file: ' .. tostring(path)
	end
	setStatus('loaded ' .. tostring(path))
	return func and func(path) or cached
end

local function finishLoading()
	Bad.Init = nil
	setStatus('loading saved GUI/profile')
	Bad:Load()
	if not shared.Badreload then
		pcall(function()
			local clickgui = Bad.gui and Bad.gui.ScaledGui and Bad.gui.ScaledGui.ClickGui
			if clickgui then
				clickgui.Visible = true
				setStatus('ready - menu opened')
			end
		end)
	end
	task.spawn(function()
		repeat
			Bad:Save()
			task.wait(10)
		until not Bad.Loaded
	end)

	local teleportedServers
	Bad:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.BadIndependent) then
			teleportedServers = true
			local teleportScript = table.concat({
				'shared.Badreload = true',
				'if shared.BadDeveloper then',
				"	loadstring(readfile('badscript/loader.lua'), 'loader')()",
				'else',
				"	loadstring(game:HttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()",
				'end'
			}, '\n')
			if shared.BadDeveloper then
				teleportScript = 'shared.BadDeveloper = true\n'..teleportScript
			end
			if shared.BadCustomProfile then
				teleportScript = 'shared.BadCustomProfile = "'..shared.BadCustomProfile..'"\n'..teleportScript
			end
			Bad:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.Badreload then
		if not Bad.Categories then return end
		if Bad.Categories.Main.Options['GUI bind indicator'].Enabled then
			Bad:CreateNotification('BadWars', 'by usingINales | Press keybind to open GUI', 6)
		end
	end
end

if not isfile('badscript/profiles/gui.txt') then
	writefile('badscript/profiles/gui.txt', 'new')
end
local gui = readfile('badscript/profiles/gui.txt')

if not isfolder('badscript/assets/'..gui) then
	makefolder('badscript/assets/'..gui)
end
local guiPath = 'badscript/guis/'..gui..'/gui.lua'
setStatus('loading GUI: ' .. tostring(gui))
local guiCode, guiDownloadErr = downloadFile(guiPath)
if type(guiCode) ~= 'string' or guiCode == '' then
	local msg = 'GUI download failed: ' .. tostring(guiDownloadErr or guiPath)
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars', msg, 12)
	error(msg, 0)
end
setStatus('compiling GUI: ' .. tostring(gui))
local guiFunc, guiCompileErr = loadstring(guiCode, 'gui')
if not guiFunc then
	local msg = 'GUI compile failed: ' .. tostring(guiCompileErr)
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars', msg, 12)
	error(msg, 0)
end
setStatus('running GUI: ' .. tostring(gui))
local ok, guiResult = pcall(guiFunc)
if not ok then
	local msg = 'GUI runtime failed: ' .. tostring(guiResult)
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars', msg, 12)
	error(msg, 0)
end
if not guiResult or not guiResult.CreateNotification then
	local msg = 'GUI returned invalid API'
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars', msg, 12)
	error(msg, 0)
end
Bad = guiResult
shared.Bad = Bad
setStatus('GUI API loaded')

setStatus('loading security gate')
local securityCode, securityDownloadErr = downloadFile('badscript/security.lua')
local securityFunc, securityErr
if securityCode then
	setStatus('compiling security gate')
	securityFunc, securityErr = loadstring(securityCode, 'security')
else
	securityErr = securityDownloadErr
end
if not securityFunc then
	local msg = 'Security gate failed to load' .. (securityErr and (': ' .. tostring(securityErr)) or '')
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars Security', msg, 12)
	error(msg, 0)
end
setStatus('running security gate')
local securityOk, security = pcall(securityFunc)
if not securityOk or type(security) ~= 'table' or type(security.Start) ~= 'function' then
	local msg = 'Security gate returned invalid API: ' .. tostring(security)
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars Security', msg, 12)
	error(msg, 0)
end
local verified, securityStatus = security:Start(Bad)
if not verified then
	local msg = 'Security denied load: ' .. tostring(securityStatus or security.Status)
	setStatus('ERROR: ' .. msg, true)
	notify('BadWars Security', msg, 12)
	error(msg, 0)
end
setStatus('security verified: ' .. tostring(securityStatus or security.Status))

if not shared.BadIndependent then
	setStatus('loading universal modules')
	local uniCode, uniDownloadErr = downloadFile('badscript/games/universal - base/base.lua')
	local uni, uniErr
	if uniCode then
		setStatus('compiling universal modules')
		uni, uniErr = loadstring(uniCode, 'universal')
	else
		uniErr = uniDownloadErr
	end
	if uni then 
		setStatus('running universal modules')
		local ok, err = pcall(uni)
		if not ok then
			setStatus('ERROR universal runtime: ' .. tostring(err), true)
			if AddLog then AddLog('Error', 'Universal load failed: ' .. tostring(err), debug.traceback()) end
		end
	else 
		local msg = 'Failed to load universal' .. (uniErr and (': ' .. tostring(uniErr)) or '')
		setStatus('ERROR: ' .. msg, true)
		warn(msg)
		if AddLog then AddLog('Error', msg, debug.traceback()) end
	end
	if isfile('badscript/games/'..game.PlaceId..'.lua') then
		setStatus('loading cached game module: ' .. tostring(game.PlaceId))
		local modCode = readfile('badscript/games/'..game.PlaceId..'.lua')
		local mod, modErr
		if modCode then
			setStatus('compiling cached game module')
			mod, modErr = loadstring(modCode, tostring(game.PlaceId))
		end
		if mod then 
			setStatus('running cached game module')
			local ok, err = pcall(mod, ...)
			if not ok then
				setStatus('ERROR game module runtime: ' .. tostring(err), true)
				if AddLog then AddLog('Error', 'Game module load failed: ' .. tostring(err), debug.traceback()) end
			end
		else
			local msg = 'Failed to load game module' .. (modErr and (': ' .. tostring(modErr)) or '')
			setStatus('ERROR: ' .. msg, true)
			warn(msg)
		end
	else
		if not shared.BadDeveloper then
			setStatus('checking game module: ' .. tostring(game.PlaceId))
			local suc, res = pcall(function()
				return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				setStatus('downloading game module: ' .. tostring(game.PlaceId))
				local modCode = downloadFile('badscript/games/'..game.PlaceId..'.lua')
				local mod, modErr
				if modCode then
					setStatus('compiling game module')
					mod, modErr = loadstring(modCode, tostring(game.PlaceId))
				end
				if mod then 
					setStatus('running game module')
					local ok, err = pcall(mod, ...)
					if not ok then
						setStatus('ERROR game module runtime: ' .. tostring(err), true)
						if AddLog then AddLog('Error', 'Game module load failed: ' .. tostring(err), debug.traceback()) end
					end
				else
					local msg = 'Failed to load game module' .. (modErr and (': ' .. tostring(modErr)) or '')
					setStatus('ERROR: ' .. msg, true)
					warn(msg)
				end
			else
				setStatus('no game module found; finishing universal load')
			end
		end
	end
	setStatus('finishing load')
	finishLoading()
else
	Bad.Init = finishLoading
	setStatus('independent mode ready')
	return Bad
end












