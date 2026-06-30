local Bad = shared.Bad
local loadstring = function(...)
	local res, err = loadstring(...)
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
			return game:HttpGet('https://raw.githubusercontent.com/usingINales/badwars/'..readfile('badscript/profiles/commit.txt')..'/'..select(1, path:gsub('badscript/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

Bad.Place = 5938036553
if isfile('badscript/games/'..Bad.Place..'.lua') then
	loadstring(readfile('badscript/games/'..Bad.Place..'.lua'), 'frontlines')()
else
	if not shared.BadDeveloper then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/usingINales/badwars/'..readfile('badscript/profiles/commit.txt')..'/games/'..Bad.Place..'.lua', true)
		end)
		if suc and res ~= '404: Not Found' then
			loadstring(downloadFile('badscript/games/'..Bad.Place..'.lua'), 'frontlines')()
		end
	end
end


