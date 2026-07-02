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

local function createStatusLabel()
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
		statusLabel.Text = 'BadWars: starting loader...'
		statusLabel.Parent = statusGui
		local padding = Instance.new('UIPadding')
		padding.PaddingLeft = UDim.new(0, 12)
		padding.PaddingRight = UDim.new(0, 12)
		padding.Parent = statusLabel
	end
	shared.BadStatusGui = statusGui
	shared.BadStatus = function(message, isError)
		local text = 'BadWars: ' .. tostring(message)
		warn(text)
		if statusLabel then
			if not isError and tostring(message):find('ready', 1, true) then
				statusGui.Enabled = false
				return
			end
			statusGui.Enabled = true
			statusLabel.Text = text
			statusLabel.TextColor3 = isError and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(235, 245, 255)
		end
	end
	return shared.BadStatus
end

local setStatus = shared.BadStatus or createStatusLabel()
setStatus('starting loader')

local _loadstring
pcall(function()
	local g = getgenv
	if type(g) == 'function' then g = g() end
	_loadstring = (g and g.loadstring) or loadstring
end)
if not _loadstring then _loadstring = function(s) error("loadstring not available in executor") end end
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
			-- Fixed for self-hosted structure: use 'main' branch and full path
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path:gsub(' ', '%%20'), true)
		end)
		if not suc or (type(res) == 'string' and res:match('^%s*404:%s*Not Found%s*$')) then
			setStatus('ERROR downloading ' .. tostring(path) .. ': ' .. tostring(res), true)
			return nil, tostring(res)
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded, no watermark)\n' .. res
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

local badwarsCacheHeader = '-- BadWars by usingINales'
local vapeCacheHeader = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'

local function isGeneratedCache(contents)
	return type(contents) == 'string'
		and (
			contents:find(badwarsCacheHeader, 1, true) == 1
			or contents:find(vapeCacheHeader, 1, true) == 1
		)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfolder(file) then
			wipeFolder(file)
		end
		if isfile(file) and isGeneratedCache(readfile(file)) then
			delfile(file)
		end
	end
end

local function wipeAnyFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if isfolder(file) then
			wipeAnyFolder(file)
		elseif isfile(file) then
			delfile(file)
		end
	end
end

for _, folder in {'badscript', 'badscript/games', 'badscript/profiles', 'badscript/assets', 'badscript/libraries', 'badscript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local cacheVersion = 'badwars-bundle-universal-modules-2026-07-01-25'
local cacheVersionPath = 'badscript/profiles/cache-version.txt'
if (isfile(cacheVersionPath) and readfile(cacheVersionPath) or '') ~= cacheVersion then
	setStatus('clearing old cache')
	if isfile('badscript/main.lua') then delfile('badscript/main.lua') end
	if isfile('badscript/NewMainScript.lua') then delfile('badscript/NewMainScript.lua') end
	if isfile('badscript/security.lua') then delfile('badscript/security.lua') end
	if isfile('badscript/games/universal - base/base.lua') then delfile('badscript/games/universal - base/base.lua') end
	if isfile('badscript/games/universal - base/files.txt') then delfile('badscript/games/universal - base/files.txt') end
	wipeAnyFolder('badscript/assets')
	wipeFolder('badscript/games')
	wipeFolder('badscript/guis')
	wipeFolder('badscript/libraries')
	writefile(cacheVersionPath, cacheVersion)
end

-- Simplified for reliability: always use main branch, no fragile scraping
writefile('badscript/profiles/commit.txt', 'main')

setStatus('loading main.lua')
local mainCode = downloadFile('badscript/main.lua')
if type(mainCode) ~= 'string' or mainCode == '' then
	setStatus('ERROR: failed to download/read badscript/main.lua', true)
	error('Failed to download/read badscript/main.lua', 0)
end

setStatus('compiling main.lua')
local mainFunc, mainErr = _loadstring(mainCode, 'main')
if not mainFunc then
	setStatus('ERROR compiling main.lua: ' .. tostring(mainErr), true)
	error('Failed to compile badscript/main.lua: ' .. tostring(mainErr), 0)
end

setStatus('running main.lua')
local ok, result = xpcall(mainFunc, debug.traceback)
if not ok then
	setStatus('ERROR running main.lua: ' .. tostring(result), true)
	error(result, 0)
end

return result












