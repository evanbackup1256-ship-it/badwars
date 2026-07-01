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

local _loadstring = (getgenv and getgenv().loadstring) or function(s) error("loadstring not available in executor") end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Fixed for self-hosted structure: use 'main' branch and full path
			return game:HttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
		end)
		if not suc or (type(res) == 'string' and (res == '404: Not Found' or res:find('404'))) then
			return nil
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded, no watermark)\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--
			delfile(file)
		end
	end
end

for _, folder in {'badscript', 'badscript/games', 'badscript/profiles', 'badscript/assets', 'badscript/libraries', 'badscript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

-- Simplified for reliability: always use main branch, no fragile scraping
writefile('badscript/profiles/commit.txt', 'main')

return _loadstring(downloadFile('badscript/main.lua'), 'main')()








