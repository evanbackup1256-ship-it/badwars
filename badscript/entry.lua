-- BadWars by usingINales
-- Entirely MINE. Custom dev build.
shared.BadWarsDev = true
shared.usingINales = true

local function safeHttpGet(url)
	local httpget = game.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(game, url, true)
	end
	return game:GetService('HttpService'):GetAsync(url, true)
end

local g = getgenv
if type(g) == 'function' then g = g() end

local ls = loadstring or (g and g.loadstring)
if not ls then
	error('loadstring not available in executor', 0)
end

local loaderCode = safeHttpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua')
local loaderFunc, loaderErr = ls(loaderCode, 'badwars-loader')
if not loaderFunc then
	error('Failed to compile badscript/loader.lua: ' .. tostring(loaderErr), 0)
end

return loaderFunc()









