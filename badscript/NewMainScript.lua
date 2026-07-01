local function safeHttpGet(inst, url, nocache)
	local g = inst or game
	local httpget = g.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(g, url, nocache)
	end
	local httpService = cloneref(game:GetService("HttpService"))
	return httpService:GetAsync(url, nocache)
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

local g = getgenv; if type(g) == 'function' then g = g() end; local _loadstring = (g and g.loadstring) or loadstring or function(s) error("loadstring not available in executor") end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Fixed for self-hosted: direct main branch + full path
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
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
		if isfile(file) and isGeneratedCache(readfile(file)) then
			delfile(file)
		end
	end
end

for _, folder in {'badscript', 'badscript/games', 'badscript/profiles', 'badscript/assets', 'badscript/libraries', 'badscript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local cacheVersion = 'badwars-main-syntax-fix-2026-06-30-2'
local cacheVersionPath = 'badscript/profiles/cache-version.txt'
if (isfile(cacheVersionPath) and readfile(cacheVersionPath) or '') ~= cacheVersion then
	if isfile('badscript/main.lua') then delfile('badscript/main.lua') end
	if isfile('badscript/loader.lua') then delfile('badscript/loader.lua') end
	wipeFolder('badscript/games')
	wipeFolder('badscript/guis')
	wipeFolder('badscript/libraries')
	writefile(cacheVersionPath, cacheVersion)
end

if not shared.BadDeveloper then
	local _, subbed = pcall(function()
		return safeHttpGet(game, 'https://github.com/evanbackup1256-ship-it/badwars')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('badscript/profiles/commit.txt') and readfile('badscript/profiles/commit.txt') or '') ~= commit then
		wipeFolder('badscript/games')
		wipeFolder('badscript/guis')
		wipeFolder('badscript/libraries')
	end
	writefile('badscript/profiles/commit.txt', commit)
end

game:GetService("StarterGui"):SetCore("SendNotification", {
	Title = "BadWars",
	Text = "Entirely by usingINales - Dev Build",
	Duration = 4
})

local mainCode = downloadFile('badscript/main.lua')
if type(mainCode) ~= 'string' or mainCode == '' then
	error('Failed to download/read badscript/main.lua', 0)
end

local mainFunc, mainErr = _loadstring(mainCode, 'main')
if not mainFunc then
	error('Failed to compile badscript/main.lua: ' .. tostring(mainErr), 0)
end

return mainFunc()












