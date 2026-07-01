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

local _loadstring
pcall(function()
	local g = getgenv
	if type(g) == 'function' then g = g() end
	_loadstring = (g and g.loadstring) or loadstring
end)
if not _loadstring then _loadstring = function(s) error("loadstring not available in executor") end end
local function downloadFile(path, func)
	if not HttpGet or not game then
		warn('BadWars: HttpGet or game is nil for ' .. tostring(path))
		return nil, 'HttpGet or game is nil'
	end
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Fixed for self-hosted structure: use 'main' branch and full path
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path:gsub(' ', '%%20'), true)
		end)
		if not suc or (type(res) == 'string' and res:match('^%s*404:%s*Not Found%s*$')) then
			return nil, tostring(res)
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded, no watermark)\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile or function() return '' end)(path)
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

local cacheVersion = 'badwars-real-gui-assets-2026-06-30-8'
local cacheVersionPath = 'badscript/profiles/cache-version.txt'
if (isfile(cacheVersionPath) and readfile(cacheVersionPath) or '') ~= cacheVersion then
	if isfile('badscript/main.lua') then delfile('badscript/main.lua') end
	if isfile('badscript/NewMainScript.lua') then delfile('badscript/NewMainScript.lua') end
	if isfile('badscript/games/universal - base/base.lua') then delfile('badscript/games/universal - base/base.lua') end
	wipeAnyFolder('badscript/assets')
	wipeFolder('badscript/games')
	wipeFolder('badscript/guis')
	wipeFolder('badscript/libraries')
	writefile(cacheVersionPath, cacheVersion)
end

-- Simplified for reliability: always use main branch, no fragile scraping
writefile('badscript/profiles/commit.txt', 'main')

local mainCode = downloadFile('badscript/main.lua')
if type(mainCode) ~= 'string' or mainCode == '' then
	error('Failed to download/read badscript/main.lua', 0)
end

local mainFunc, mainErr = _loadstring(mainCode, 'main')
if not mainFunc then
	error('Failed to compile badscript/main.lua: ' .. tostring(mainErr), 0)
end

return mainFunc()












