-- BadWars Loader v4.0 - Production Reliable
-- Each stage must succeed before the next begins
local loaderStart = os.clock()

-- Stage 0: Executor API Polyfills
-- These must be available for the loader to function
isfile = isfile or function(f) local s,r=pcall(readfile,f) return s and r~=nil and r~='' end
delfile = delfile or function(f) writefile(f,'') end
isfolder = isfolder or function() return false end
makefolder = makefolder or function() end
listfiles = listfiles or function() return {} end
readfile = readfile or function() return '' end
writefile = writefile or function() end
cloneref = cloneref or function(o) return o end
setthreadidentity = setthreadidentity or function() end
queue_on_teleport = queue_on_teleport or function() end
local collectgarbage = collectgarbage

-- HTTP GET — returns (responseBody, errorMessage)
-- Tries multiple methods in order of reliability
local function httpGet(url)
	local g = game
	-- Method 1: game:HttpGet (most executors support this)
	local ok1, res1 = pcall(function() return g:HttpGet(url, true) end)
	if ok1 and type(res1) == 'string' and #res1 > 0 then return res1 end

	-- Method 2: getgenv().HttpGet
	local ok2, res2 = pcall(function()
		local env = getgenv()
		if type(env.HttpGet) == 'function' then return env.HttpGet(g, url, true) end
		return nil, 'no HttpGet in env'
	end)
	if ok2 and type(res2) == 'string' and #res2 > 0 then return res2 end

	-- Method 3: HttpService:GetAsync
	local ok3, res3 = pcall(function()
		local hs = cloneref(g:GetService('HttpService'))
		return hs:GetAsync(url, true)
	end)
	if ok3 and type(res3) == 'string' and #res3 > 0 then return res3 end

	-- All methods failed — collect diagnostics
	local reasons = {}
	if not ok1 then table.insert(reasons, 'game.HttpGet: ' .. tostring(res1)) end
	if not ok2 then table.insert(reasons, 'getenv.HttpGet: ' .. tostring(res2)) end
	if not ok3 then table.insert(reasons, 'HttpService: ' .. tostring(res3)) end
	return nil, table.concat(reasons, ' | ')
end
HttpGet = httpGet

-- Stage 1: Status GUI — shows pipeline progress
local statusGui, statusLabel
pcall(function()
	local parent = cloneref(game:GetService('CoreGui'))
	local old = parent:FindFirstChild('BadWarsLoaderStatus')
	if old then old:Destroy() end
	statusGui = Instance.new('ScreenGui')
	statusGui.Name = 'BadWarsLoaderStatus'
	statusGui.DisplayOrder = 10000000
	statusGui.IgnoreGuiInset = true
	statusGui.ResetOnSpawn = false
	statusGui.Parent = parent
end)
if not statusGui then
	pcall(function()
		local parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
		local old = parent:FindFirstChild('BadWarsLoaderStatus')
		if old then old:Destroy() end
		statusGui = Instance.new('ScreenGui')
		statusGui.Name = 'BadWarsLoaderStatus'
		statusGui.DisplayOrder = 10000000
		statusGui.IgnoreGuiInset = true
		statusGui.ResetOnSpawn = false
		statusGui.Parent = parent
	end)
end
if statusGui then
	statusLabel = Instance.new('TextLabel')
	statusLabel.Name = 'Status'
	statusLabel.Size = UDim2.new(0, 680, 0, 88)
	statusLabel.Position = UDim2.fromOffset(12, 92)
	statusLabel.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
	statusLabel.BackgroundTransparency = 0.15
	statusLabel.BorderSizePixel = 0
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextColor3 = Color3.fromRGB(235, 245, 255)
	statusLabel.TextWrapped = true
	statusLabel.Text = 'BadWars: initializing...'
	statusLabel.Parent = statusGui
	local pad = Instance.new('UIPadding')
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = statusLabel
end
shared.BadStatusGui = statusGui
shared.BadStatus = function(msg, isErr)
	local text = 'BadWars: ' .. tostring(msg)
	warn(text)
	if statusLabel then
		if not isErr and tostring(msg):find('ready', 1, true) then
			statusGui.Enabled = false
			return
		end
		statusGui.Enabled = true
		statusLabel.Text = text
		statusLabel.TextColor3 = isErr and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(235, 245, 255)
	end
end
local setStatus = shared.BadStatus
setStatus('pipeline: status gui ready')

-- Runtime error accumulator
local __rtErrs = shared.__badwars_runtime_errors
if type(__rtErrs) ~= 'table' then __rtErrs = {}; shared.__badwars_runtime_errors = __rtErrs end
local function recordErr(mod, msg)
	table.insert(__rtErrs, {module = tostring(mod), error = tostring(msg), time = os.clock()})
	warn('BadWars: [ERROR] ' .. tostring(mod) .. ': ' .. tostring(msg))
end

-- Stage 2: Loadstring availability
setStatus('pipeline: checking loadstring')
local _loadstring
pcall(function()
	local g = getgenv
	if type(g) == 'function' then g = g() end
	_loadstring = (g and g.loadstring) or loadstring
end)
if type(_loadstring) ~= 'function' then
	local msg = 'loadstring is not available in this executor. Cannot continue.'
	setStatus('ERROR: ' .. msg, true); error(msg, 0)
end

-- Stage 3: Cache setup and integrity
setStatus('pipeline: cache setup')
for _, dir in {'badscript', 'badscript/games', 'badscript/profiles', 'badscript/assets', 'badscript/libraries', 'badscript/guis'} do
	if not isfolder(dir) then makefolder(dir) end
end

local function wipeAny(path)
	if not isfolder(path) then return end
	for _, f in listfiles(path) do
		if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end
	end
end
local function wipeCache(path)
	if not isfolder(path) then return end
	for _, f in listfiles(path) do
		if f:find('loader') then continue end
		if isfolder(f) then wipeCache(f) end
		if isfile(f) then
			local c = readfile(f)
			if type(c) == 'string' and (c:find('-- BadWars', 1, true) == 1 or c:find('--This watermark', 1, true) == 1) then
				delfile(f)
			end
		end
	end
end

-- Cache version forces full re-download when changed
local cacheVersion = 'badwars-v4-reliable'
local cacheFilePath = 'badscript/profiles/cache-version.txt'
local existingVer = (isfile(cacheFilePath) and readfile(cacheFilePath)) or ''
if existingVer ~= cacheVersion then
	setStatus('cache version changed; clearing old cache')
	for _, f in {'badscript/main.lua', 'badscript/NewMainScript.lua', 'badscript/security.lua'} do
		if isfile(f) then delfile(f) end
	end
	wipeAny('badscript/assets')
	wipeCache('badscript/games')
	wipeCache('badscript/guis')
	wipeCache('badscript/libraries')
	writefile(cacheFilePath, cacheVersion)
end
writefile('badscript/profiles/commit.txt', 'main')

-- Stage 4: Download main.lua with full diagnostics
setStatus('pipeline: downloading main orchestrator')
local MAIN_URL = 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/main.lua'
local mainCode
local mainDownloadErr

-- Try HTTP download
local raw, errMsg = httpGet(MAIN_URL)
if type(raw) == 'string' and #raw > 0 then
	-- Validate: GitHub raw endpoints return 404 pages as HTML, not the file
	if raw:find('404: Not Found', 1, true) or raw:find('Not Found', 1, true) and #raw < 500 then
		mainDownloadErr = 'URL returned 404 - file not found at: ' .. MAIN_URL
	else
		mainCode = '-- BadWars by usingINales\n' .. raw
		-- Cache to disk
		pcall(function() writefile('badscript/main.lua', mainCode) end)
	end
else
	mainDownloadErr = errMsg or 'HTTP request returned empty response'
end

-- Fallback: try cached copy
if type(mainCode) ~= 'string' or #mainCode == 0 then
	local cached = isfile('badscript/main.lua') and readfile('badscript/main.lua') or ''
	if type(cached) == 'string' and #cached > 100 then
		setStatus('using cached main.lua as fallback')
		mainCode = cached
		recordErr('loader', 'download failed, using cache: ' .. (mainDownloadErr or 'unknown'))
	else
		local fatalMsg = 'Failed to download main.lua: ' .. (mainDownloadErr or 'unknown error')
		setStatus('ERROR: ' .. fatalMsg, true)
		recordErr('loader', fatalMsg)
		error(fatalMsg, 0)
	end
end

-- Stage 5: Verify main.lua is valid Lua
setStatus('pipeline: verifying main.lua')
local mainFunc, mainCompileErr = _loadstring(mainCode, 'main')
if not mainFunc then
	local fatalMsg = 'Failed to compile main.lua: ' .. tostring(mainCompileErr)
	setStatus('ERROR: ' .. fatalMsg, true)
	recordErr('loader', fatalMsg)
	error(fatalMsg, 0)
end

-- Stage 6: Execute main.lua
setStatus('pipeline: executing main orchestrator')
local execOk, execResult = xpcall(mainFunc, debug.traceback)
if not execOk then
	local fatalMsg = 'main.lua runtime error: ' .. tostring(execResult)
	setStatus('ERROR: ' .. fatalMsg, true)
	recordErr('loader', fatalMsg)
	error(fatalMsg, 0)
end

-- Stage 7: Post-execution validation
setStatus('pipeline: validation')
local issues = {}

-- Validate shared.Bad
if not shared.Bad then
	table.insert(issues, 'shared.Bad is nil — GUI did not initialize')
else
	local B = shared.Bad
	if type(B.CreateNotification) ~= 'function' then table.insert(issues, 'Bad.CreateNotification is not a function') end
	if type(B.Modules) ~= 'table' then table.insert(issues, 'Bad.Modules is not a table') end
end

-- Validate universal module report
local report = shared.__badwars_universal_report
if type(report) == 'table' and type(report.failed) == 'table' and #report.failed > 0 then
	for _, entry in ipairs(report.failed) do
		table.insert(issues, 'Module [' .. tostring(entry.name) .. '] failed: ' .. tostring(entry.error))
	end
end

-- Validate runtime errors
if #__rtErrs > 0 then
	for _, e in ipairs(__rtErrs) do
		table.insert(issues, 'Runtime error [' .. tostring(e.module) .. ']: ' .. tostring(e.error))
	end
end

-- Report
if #issues > 0 then
	warn('BadWars: [VALIDATION] ' .. #issues .. ' issue(s):')
	for _, i in ipairs(issues) do warn('  ! ' .. i) end
	setStatus(#issues .. ' issue(s) found', true)
else
	setStatus('validation passed')
end

-- Pipeline complete
local elapsed = os.clock() - loaderStart
local msg = 'Loader complete in ' .. string.format('%.2f', elapsed) .. 's'
if #issues > 0 then msg = msg .. ' (' .. #issues .. ' issue(s))' end
warn('BadWars: ' .. msg)

return execResult