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
		warn('BadWars: HttpGet or game is nil for ' .. tostring(path))
		return ''
	end
	if not isfile(path) then
		local suc, res = pcall(function()
			-- Fixed: direct main + full path under badscript/
			return HttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path, true)
		end)
		if not suc or (type(res) == 'string' and (res == '404: Not Found' or res:find('404'))) then
			return nil
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded)\n' .. res
		end
		writefile(path, res)
	end
	return (func or readfile or function() return '' end)(path)
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
					loadstring(HttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua', true), 'loader')()
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
local guiCode = downloadFile('badscript/guis/'..gui..'/gui.lua')
local guiFunc = guiCode and loadstring(guiCode, 'gui')
local ok, guiResult = pcall(function() return guiFunc and guiFunc() end)
if not ok then
	AddLog and AddLog('Error', 'GUI load failed: ' .. tostring(guiResult), debug.traceback())
end
Bad = ok and guiResult or nil
if not Bad or not Bad.CreateNotification then
	Bad = {
		CreateNotification = function(t,...) print("BadWars dummy notif:", ...) end,
		Load = function() end,
		Save = function() end,
		Clean = function() end,
		Uninject = function() end,
		Libraries = {tween = function() end, targetinfo = {}, getfontsize = function() return 0 end, getcustomasset = function(s) return s end},
		gui = {ScaledGui = {ClickGui = {Visible = false}}}
	}
end
shared.Bad = Bad

if not shared.BadIndependent then
	local uniCode = downloadFile('badscript/games/universal - base/base.lua')
	local uni = uniCode and loadstring(uniCode, 'universal')
	if uni then 
		local ok, err = pcall(uni)
		if not ok then AddLog and AddLog('Error', 'Universal load failed: ' .. tostring(err), debug.traceback()) end
	else 
		warn("Failed to load universal") 
	end
	if isfile('badscript/games/'..game.PlaceId..'.lua') then
		local modCode = readfile('badscript/games/'..game.PlaceId..'.lua')
		local mod = modCode and loadstring(modCode, tostring(game.PlaceId))
		if mod then 
			local ok, err = pcall(mod, ...)
			if not ok then AddLog and AddLog('Error', 'Game module load failed: ' .. tostring(err), debug.traceback()) end
		else warn("Failed to load game module") end
	else
		if not shared.BadDeveloper then
			local suc, res = pcall(function()
				return HttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				local modCode = downloadFile('badscript/games/'..game.PlaceId..'.lua')
				local mod = modCode and loadstring(modCode, tostring(game.PlaceId))
				if mod then 
					local ok, err = pcall(mod, ...)
					if not ok then AddLog and AddLog('Error', 'Game module load failed: ' .. tostring(err), debug.traceback()) end
				else warn("Failed to load game module") end
			end
		end
	end
	finishLoading()
else
	Bad.Init = finishLoading
	return Bad
end











