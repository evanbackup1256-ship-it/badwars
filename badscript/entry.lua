-- BadWars by usingINales
-- Entry point
shared.BadWarsDev = true
shared.usingINales = true

-- HTTP GET that actually returns the result
local function httpGet(url)
	local fn = (game and game.HttpGet)
	if type(fn) ~= 'function' then
		local env = getgenv and type(getgenv) == 'function' and getgenv()
		fn = env and env.HttpGet
	end
	if type(fn) == 'function' then
		local ok, res = pcall(fn, game, url, true)
		if ok and type(res) == 'string' and #res > 0 then return res end
	end
	local ok, res = pcall(function()
		return game:GetService('HttpService'):GetAsync(url, true)
	end)
	if ok and type(res) == 'string' and #res > 0 then return res end
	return nil, 'all HTTP methods failed'
end

local g = getgenv
if type(g) == 'function' then
	local ok, res = pcall(g)
	if ok then g = res else g = nil end
else
	g = nil
end

local ls = loadstring or (g and g.loadstring)
if type(ls) ~= 'function' then
	local msg = 'BadWars: loadstring not available'
	warn(msg); error(msg, 0)
end

local loaderCode = httpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua')
if type(loaderCode) ~= 'string' or loaderCode == '' then
	local msg = 'BadWars: Failed to fetch loader'
	warn(msg); error(msg, 0)
end

local loaderFunc, loaderErr = ls(loaderCode, 'badwars-loader')
if not loaderFunc then
	local msg = 'BadWars: Failed to compile loader: ' .. tostring(loaderErr)
	warn(msg); error(msg, 0)
end

local ok, result = xpcall(loaderFunc, debug.traceback)
if not ok then
	local msg = 'BadWars: Loader error: ' .. tostring(result)
	warn(msg); error(msg, 0)
end

return result