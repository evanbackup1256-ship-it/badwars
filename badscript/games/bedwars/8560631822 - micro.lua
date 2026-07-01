local Bad = shared.Bad
local g = getgenv; if type(g) == 'function' then g = g() end; local _loadstring = (g and g.loadstring) or function(s) error("loadstring not available in executor") end
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
			return HttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
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

Bad.Place = 6872274481
if isfile('badscript/games/'..Bad.Place..'.lua') then
	loadstring(readfile('badscript/games/'..Bad.Place..'.lua'), 'bedwars')()
else
	if not shared.BadDeveloper then
		local suc, res = pcall(function()
			return HttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/profiles/commit.txt')..'/games/'..Bad.Place..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('badscript/games/'..Bad.Place..'.lua'), 'bedwars')()
		end
	end
end






















