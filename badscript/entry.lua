-- BadWars by usingINales
-- Entry point
shared.BadWarsDev = true
shared.usingINales = true

-- URL configuration
local BASE_REPO = 'evanbackup1256-ship-it'
local BASE_REPO_NAME = 'badwars'
local BASE_BRANCH = 'main'
local LOADER_PATH = 'badscript/loader.lua'
local LOADER_URL = 'https://raw.githubusercontent.com/' .. BASE_REPO .. '/' .. BASE_REPO_NAME .. '/' .. BASE_BRANCH .. '/' .. LOADER_PATH

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

-- URL diagnostics
warn('BadWars: [URL DIAGNOSTICS]')
warn('  Repository:   ' .. BASE_REPO .. '/' .. BASE_REPO_NAME)
warn('  Branch:       ' .. BASE_BRANCH)
warn('  File:         ' .. LOADER_PATH)
warn('  Raw URL:      ' .. LOADER_URL)

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

-- Fetch loader with validation
local loaderCode = httpGet(LOADER_URL)
if loaderCode == nil then
	local msg = 'BadWars: httpGet returned nil for ' .. LOADER_URL
	warn(msg); error(msg, 0)
end
if type(loaderCode) ~= 'string' or loaderCode == '' then
	local msg = 'BadWars: empty response from ' .. LOADER_URL
	warn(msg); error(msg, 0)
end
if loaderCode:find('404: Not Found', 1, true) then
	local msg = 'FILE NOT FOUND: ' .. LOADER_PATH .. ' does not exist at ' .. LOADER_URL
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