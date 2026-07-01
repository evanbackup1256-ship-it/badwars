local function safeHttpGet(inst, url, nocache)
	local g = inst or game
	local httpget = g.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(g, url, nocache)
	end
	local httpService = cloneref(game:GetService("HttpService"))
	return httpService:GetAsync(url, nocache)
end
local Bad = shared.Bad
local g = getgenv; if type(g) == 'function' then g = g() end; local _loadstring = (g and g.loadstring) or function(s) error("loadstring not available in executor") end
local _loadstring = (getgenv and getgenv().loadstring) or loadstring or function(s) error("loadstring not available in executor") end
local loadstring = function(...)
	local res, err = _loadstring(...)
	if err and Bad then
		Bad:CreateNotification('Bad', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--
		end
		writefile(path, res)
	end
	return (func or readfile or function() return '' end)(path)
end

Bad.Place = 77790193039862
if isfile('badscript/games/'..Bad.Place..'.lua') then
	loadstring(readfile('badscript/games/'..Bad.Place..'.lua'), '1.8arena')()
else
	if not shared.BadDeveloper then
		local suc, res = pcall(function()
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/profiles/commit.txt')..'/games/'..Bad.Place..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('badscript/games/'..Bad.Place..'.lua'), '1.8arena')()
		end
	end
end




























