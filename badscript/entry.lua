-- BadWars by usingINales
-- Entry point for minimal execution environments
shared.BadWarsDev = true
shared.usingINales = true

local function safeHttpGet(url)
	local httpget = (game and game.HttpGet)
	if type(httpget) ~= 'function' then
		httpget = (getgenv and type(getgenv) == 'function' and getgenv().HttpGet)
	end
	if type(httpget) == 'function' then
		return httpget(game, url, true)
	end
	pcall(function()
		local httpService = game:GetService('HttpService')
		if httpService then
			return httpService:GetAsync(url, true)
		end
	end)
	return nil
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
	local msg = 'BadWars: loadstring not available in this executor'
	warn(msg)
	error(msg, 0)
end

local loaderCode = safeHttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua')
if type(loaderCode) ~= 'string' or loaderCode == '' then
	local msg = 'BadWars: Failed to fetch loader from GitHub'
	warn(msg)
	error(msg, 0)
end

local loaderFunc, loaderErr = ls(loaderCode, 'badwars-loader')
if not loaderFunc then
	local msg = 'BadWars: Failed to compile loader: ' .. tostring(loaderErr)
	warn(msg)
	error(msg, 0)
end

local ok, result = xpcall(loaderFunc, debug.traceback)
if not ok then
	local msg = 'BadWars: Loader runtime error: ' .. tostring(result)
	warn(msg)
	error(msg, 0)
end

return result
