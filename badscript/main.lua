repeat task.wait() until game:IsLoaded()
if shared.Bad then shared.Bad:Uninject() end

-- Custom splash by usingINales for BadWars
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "BadWars",
		Text = "by usingINales | Dev Mode Active",
		Duration = 6
	})
end)

local Bad
local oldLoadstring = (getgenv and getgenv().loadstring) or function(...) error("loadstring not available") end
local loadstring = function(...)
	local res, err = oldLoadstring(...)
	if err and Bad then
		Bad:CreateNotification('BadWars', 'Failed to load : '..err, 30, 'alert')
	end
	return res
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
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Fixed: direct main + full path under badscript/
			return game:HttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
		end)
		if not suc or (type(res) == 'string' and (res == '404: Not Found' or res:find('404'))) then
			return nil
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded)\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()
	Bad.Init = nil
	Bad:Load()
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
			local teleportScript = [[
				shared.Badreload = true
				if shared.BadDeveloper then
					loadstring(readfile('badscript/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()
				end
			]]
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
Bad = loadstring(downloadFile('badscript/guis/'..gui..'/gui.lua'), 'gui')()
if not Bad or not Bad.CreateNotification then
	Bad = {CreateNotification = function(t,...) print("BadWars dummy notif:", ...) end, Load = function() end, Save = function() end, Clean = function() end, Uninject = function() end }
end
shared.Bad = Bad

if not shared.BadIndependent then
	local uni = loadstring(downloadFile('badscript/games/universal - base/base.lua'), 'universal')
if uni then uni() else warn("Failed to load universal") end
	if isfile('badscript/games/'..game.PlaceId..'.lua') then
		local mod = loadstring(readfile('badscript/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))
		if mod then mod(...) else warn("Failed to load game module") end
	else
		if not shared.BadDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				local mod = loadstring(downloadFile('badscript/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))
				if mod then mod(...) else warn("Failed to load game module") end
			end
		end
	end
	finishLoading()
else
	Bad.Init = finishLoading
	return Bad
end








