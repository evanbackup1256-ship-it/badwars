repeat task.wait() until game:IsLoaded()
if shared.Bad then pcall(function() shared.Bad:Uninject() end) end
shared.BadSecurityStarted = nil

local collectgarbage = collectgarbage
local os_clock = os.clock
local pipelineStart = os_clock()

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
		pcall(function() shared.BadStatus(message, isError) end)
	end
end

local function notify(title, text, duration)
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = tostring(title or "BadWars"),
			Text = tostring(text or ""),
			Duration = duration or 8
		})
	end)
end

local function logModule(stage, name, elapsed, success, detail)
	local tag = success and '[SUCCESS]' or '[ERROR]'
	local msg = tag .. ' [' .. stage .. '] ' .. tostring(name)
	if elapsed then msg = msg .. ' (' .. string.format('%.3f', elapsed) .. 's)' end
	if detail then msg = msg .. ' - ' .. tostring(detail) end
	warn('BadWars: ' .. msg)
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

local function splitLines(text)
	local lines = {}
	for line in tostring(text or ''):gmatch('[^\r\n]+') do
		line = line:match('^%s*(.-)%s*$')
		if line ~= '' and not line:find('^#') then
			table.insert(lines, line)
		end
	end
	return lines
end

local function loadLuaBundle(name, basePath, manifestPath)
	local baseCode, baseErr = downloadFile(basePath)
	if type(baseCode) ~= 'string' or baseCode == '' then
		return nil, baseErr or ('missing base: ' .. tostring(basePath))
	end

	local parts = {baseCode}
	local manifestCode, manifestErr = downloadFile(manifestPath)
	if type(manifestCode) ~= 'string' or manifestCode == '' then
		return table.concat(parts, '\n'), manifestErr
	end

	local loaded = 0
	for _, modulePath in splitLines(manifestCode) do
		if modulePath ~= basePath then
			setStatus('loading ' .. tostring(name) .. ' module: ' .. tostring(modulePath))
			local moduleCode, moduleErr = downloadFile(modulePath)
			if type(moduleCode) == 'string' and moduleCode ~= '' then
				table.insert(parts, '\n-- bundled ' .. modulePath .. '\n' .. moduleCode)
				loaded += 1
			else
				setStatus('WARNING skipped ' .. tostring(modulePath) .. ': ' .. tostring(moduleErr), false)
			end
		end
	end
	setStatus('bundled ' .. tostring(loaded) .. ' ' .. tostring(name) .. ' modules')
	return table.concat(parts, '\n')
end

local function loadPrebuiltBundle(name, bundlePath, basePath, manifestPath)
	local bundleCode, bundleErr = downloadFile(bundlePath)
	if type(bundleCode) == 'string' and bundleCode ~= '' then
		setStatus('loaded prebuilt ' .. tostring(name) .. ' bundle')
		return bundleCode
	end
	setStatus('WARNING prebuilt ' .. tostring(name) .. ' bundle unavailable; building from manifest: ' .. tostring(bundleErr), false)
	return loadLuaBundle(name, basePath, manifestPath)
end

local gameModulePaths = {
	[606849621] = 'badscript/games/jailbreak/606849621 - main/base.lua',
	[893973440] = 'badscript/games/893973440 - flee the facility/base.lua',
	[6872265039] = 'badscript/games/bedwars/6872265039 - lobby/base.lua',
	[6872274481] = 'badscript/games/bedwars/6872274481 - game/base.lua',
	[8444591321] = 'badscript/games/bedwars/8444591321 - mega.lua',
	[8560631822] = 'badscript/games/bedwars/8560631822 - micro.lua',
	[77790193039862] = 'badscript/games/1.8arena/77790193039862 - game/base.lua',
	[80041634734121] = 'badscript/games/1.8arena/80041634734121 - duel.lua',
	[139566161526375] = 'badscript/games/bridge duel/139566161526375 - game/base.lua',
	[16483433878] = 'badscript/games/blocktales/16483433878 - blocktales/base.lua',
	[106431012459431] = 'badscript/games/blocktales/106431012459431 - battle sim.lua',
	[5938036553] = 'badscript/games/frontlines/5938036553 - game/base.lua',
	[123804558118054] = 'badscript/games/frontlines/123804558118054 - versus.lua',
	[131465939650733] = 'badscript/games/frontlines/131465939650733 - versus ffa.lua',
	[83413351472244] = 'badscript/games/frontlines/83413351472244 - versus ffa2.lua',
	[155615604] = 'badscript/games/prison life/155615604 - main/base.lua',
	[135564683255158] = 'badscript/games/prison life/135564683255158 - vc servers.lua',
	[115875349872417] = 'badscript/games/redliner/115875349872417 - game/base.lua',
	[126691165749976] = 'badscript/games/redliner/126691165749976 - 1v1.lua',
	[94987506187454] = 'badscript/games/redliner/94987506187454 - lobby.lua',
	[8768229691] = 'badscript/games/skywars voxel/8768229691 - skywars game/base.lua',
	[8542259458] = 'badscript/games/skywars voxel/8542259458 - skywars lobby.lua',
	[8542275097] = 'badscript/games/skywars voxel/8542275097 - skywars solo.lua',
	[8592115909] = 'badscript/games/skywars voxel/8592115909 - skywars duos.lua',
	[13246639586] = 'badscript/games/skywars voxel/13246639586 - skywars bridge.lua',
	[8951451142] = 'badscript/games/skywars voxel/8951451142 - skywars egg squad.lua'
}

local function resolveGameModulePath(placeId)
	local numericPlaceId = tonumber(placeId)
	return gameModulePaths[numericPlaceId] or ('badscript/games/' .. tostring(placeId) .. '.lua')
end

local function runGameModule(modulePath, sourceLabel, ...)
	setStatus('loading ' .. tostring(sourceLabel) .. ' game module: ' .. tostring(modulePath))
	local modStart = os_clock()
	local modCode, modDownloadErr = downloadFile(modulePath)
	if type(modCode) ~= 'string' or modCode == '' then
		return false, modDownloadErr or ('missing game module: ' .. tostring(modulePath))
	end

	setStatus('compiling game module: ' .. tostring(modulePath))
	local mod, modErr = loadstring(modCode, tostring(game.PlaceId))
	if not mod then
		return false, modErr or 'compile failed'
	end

	setStatus('running game module: ' .. tostring(modulePath))
	local ok, err = pcall(mod, ...)
	local elapsed = os_clock() - modStart
	if not ok then
		logModule('Game Module', modulePath, elapsed, false, err)
		return false, err
	end

	logModule('Game Module', modulePath, elapsed, true)
	setStatus('game module ready: ' .. tostring(modulePath))
	return true
end

local function performHealthCheck()
	setStatus('running health checks')
	local issues = {}
	local warnings = {}

	if not Bad then
		table.insert(issues, 'Bad API is nil')
		return issues, warnings
	end

	if type(Bad.CreateNotification) ~= 'function' then
		table.insert(issues, 'CreateNotification missing')
	end
	if type(Bad.Save) ~= 'function' then
		table.insert(issues, 'Save missing')
	end
	if type(Bad.Load) ~= 'function' then
		table.insert(issues, 'Load missing')
	end
	if type(Bad.Clean) ~= 'function' then
		table.insert(issues, 'Clean missing')
	end

	if not Bad.Categories then
		table.insert(warnings, 'Categories table missing')
	elseif not Bad.Categories.Main then
		table.insert(warnings, 'Main category missing')
	end

	if not Bad.gui then
		table.insert(warnings, 'GUI object missing')
	else
		pcall(function()
			if not Bad.gui:FindFirstChild('ScaledGui') then
				table.insert(warnings, 'ScaledGui missing')
			end
		end)
	end

	if not Bad.Modules then
		table.insert(warnings, 'Modules table missing')
	else
		local count = 0
		for _ in Bad.Modules do count += 1 end
		if count == 0 then
			table.insert(warnings, 'No modules registered')
		end
	end

	if not Bad.Libraries then
		table.insert(warnings, 'Libraries table missing')
	end

	pcall(function()
		collectgarbage('collect')
		local memKB = collectgarbage('count')
		if memKB > 50000 then
			table.insert(warnings, 'High memory usage: ' .. string.format('%.1f', memKB) .. ' KB')
		end
	end)

	return issues, warnings
end

local function finishLoading()
	Bad.Init = nil
	setStatus('loading saved GUI/profile')
	Bad:Load()
	if not shared.BadReload then
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
				'shared.BadReload = true',
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

	if not shared.BadReload then
		if not Bad.Categories then return end
		if Bad.Categories.Main.Options and Bad.Categories.Main.Options['GUI bind indicator'] and Bad.Categories.Main.Options['GUI bind indicator'].Enabled then
			Bad:CreateNotification('BadWars', 'by usingINales | Press keybind to open GUI', 6)
		end
	end
end

local function validateDependencies()
	setStatus('validating dependencies')
	local deps = {
		{ name = 'Players', ok = pcall(function() game:GetService('Players') end) },
		{ name = 'RunService', ok = pcall(function() game:GetService('RunService') end) },
		{ name = 'UserInputService', ok = pcall(function() game:GetService('UserInputService') end) },
		{ name = 'TweenService', ok = pcall(function() game:GetService('TweenService') end) },
		{ name = 'Lighting', ok = pcall(function() game:GetService('Lighting') end) },
		{ name = 'HttpService', ok = pcall(function() game:GetService('HttpService') end) },
		{ name = 'GuiService', ok = pcall(function() game:GetService('GuiService') end) },
		{ name = 'ReplicatedStorage', ok = pcall(function() game:GetService('ReplicatedStorage') end) },
		{ name = 'TeleportService', ok = pcall(function() game:GetService('TeleportService') end) },
		{ name = 'MarketplaceService', ok = pcall(function() game:GetService('MarketplaceService') end) },
		{ name = 'pcall', ok = type(pcall) == 'function' },
		{ name = 'task', ok = type(task) == 'table' },
		{ name = 'loadstring', ok = type(loadstring) == 'function' },
		{ name = 'Instance', ok = type(Instance) == 'userdata' },
		{ name = 'game', ok = type(game) == 'userdata' },
		{ name = 'workspace', ok = type(workspace) == 'userdata' },
	}

	local missing = {}
	for _, dep in deps do
		if not dep.ok then
			table.insert(missing, dep.name)
		end
	end

	if #missing > 0 then
		warn('BadWars: [WARN] Missing dependencies: ' .. table.concat(missing, ', '))
	end

	local allOk = true
	for _, dep in deps do
		if not dep.ok then
			allOk = false
			break
		end
	end

	return allOk, missing
end

-- ============================================================
-- PIPELINE STAGES
-- ============================================================

-- Stage 1: Dependency Scan
local depsOk, missingDeps = validateDependencies()
if not depsOk then
	warn('BadWars: Critical dependencies missing - proceeding with degraded mode')
end

-- Stage 2: Integrity Check
local integrityStart = os_clock()

-- Stage 3: GUI Profile Selection
if (not isfile('badscript/profiles/gui.txt')) or readfile('badscript/profiles/gui.txt') ~= 'new' then
	setStatus('selecting current GUI profile')
	writefile('badscript/profiles/gui.txt', 'new')
end
local gui = readfile('badscript/profiles/gui.txt')

if not isfolder('badscript/assets/'..gui) then
	makefolder('badscript/assets/'..gui)
end

-- Stage 4: Module Discovery & Validation (already done via gameModulePaths)

-- Stage 5: Compilation & Registration - GUI
local guiPath = 'badscript/guis/'..gui..'/gui.lua'
local guiStart = os_clock()
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
logModule('GUI', gui, os_clock() - guiStart, true)
setStatus('GUI API loaded')

-- Stage 6: Security
local secStart = os_clock()
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
logModule('Security', 'security.lua', os_clock() - secStart, true, tostring(securityStatus or security.Status))
setStatus('security verified: ' .. tostring(securityStatus or security.Status))

-- Stage 7: Universal Modules
if not shared.BadIndependent then
	local uniStart = os_clock()
	setStatus('loading universal modules')
	local uniCode, uniDownloadErr = loadPrebuiltBundle('universal', 'badscript/games/universal - base/bundle.lua', 'badscript/games/universal - base/base.lua', 'badscript/games/universal - base/files.txt')
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
			logModule('Universal', 'bundle.lua', os_clock() - uniStart, false, tostring(err))
		else
			logModule('Universal', 'bundle.lua', os_clock() - uniStart, true)
			setStatus('universal modules ready')
		end
	else
		local msg = 'Failed to load universal' .. (uniErr and (': ' .. tostring(uniErr)) or '')
		setStatus('ERROR: ' .. msg, true)
		warn('BadWars: ' .. msg)
		logModule('Universal', 'bundle.lua', os_clock() - uniStart, false, msg)
	end

	-- Stage 8: Game Module
	local modulePath = resolveGameModulePath(game.PlaceId)
	if shared.BadDeveloper or gameModulePaths[tonumber(game.PlaceId)] or isfile(modulePath) then
		runGameModule(modulePath, isfile(modulePath) and 'cached' or 'mapped', ...)
	else
		setStatus('universal active; no game-specific module found for place ' .. tostring(game.PlaceId))
	end

	-- Stage 9: Post Initialization & Health Check
	setStatus('post-initialization')
	finishLoading()

	local issues, warnings = performHealthCheck()
	if #issues > 0 then
		warn('BadWars: [HEALTH] Critical issues:')
		for _, issue in issues do
			warn('  ✗ ' .. issue)
		end
	end
	if #warnings > 0 then
		warn('BadWars: [HEALTH] Warnings:')
		for _, warning in warnings do
			warn('  ⚠ ' .. warning)
		end
	end

	-- Stage 10: Ready
	local pipelineElapsed = os_clock() - pipelineStart
	setStatus('ready - loaded in ' .. string.format('%.2f', pipelineElapsed) .. 's')
	warn('BadWars: Pipeline complete in ' .. string.format('%.2f', pipelineElapsed) .. 's')
else
	Bad.Init = finishLoading
	setStatus('independent mode ready')
	return Bad
end
