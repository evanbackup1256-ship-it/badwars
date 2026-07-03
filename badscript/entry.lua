-- BadWars by usingINales
-- Entry point
shared.BadWarsDev = true
shared.usingINales = true

local CFG={repo='evanbackup1256-ship-it',name='badwars',branch='main'}
local LOADER_PATH='badscript/loader.lua'

-- Try two URL formats: github.com/raw/ first, raw.githubusercontent.com fallback
local function rawUrl(path)
	local repo=CFG.repo..'/'..CFG.name
	local p=path:gsub(' ','%%20')
	return {'https://github.com/'..repo..'/raw/'..CFG.branch..'/'..p,'https://raw.githubusercontent.com/'..repo..'/'..CFG.branch..'/'..p}
end

local function httpGet(urls)
	for _,url in ipairs(urls) do
		local fn=(game and game.HttpGet)
		if type(fn)~='function' then
			local env=getgenv and type(getgenv)=='function' and getgenv()
			fn=env and env.HttpGet
		end
		if type(fn)=='function' then
			local ok,res=pcall(fn,game,url,true)
			if ok and type(res)=='string' and #res>0 then return res,url end
		end
		local ok,res=pcall(function()
			return cloneref(game:GetService('HttpService')):GetAsync(url,true)
		end)
		if ok and type(res)=='string' and #res>0 then return res,url end
	end
	return nil,nil
end

warn('BadWars: [URL DIAGNOSTICS]')
local urls=rawUrl(LOADER_PATH)
warn('  Repository:   '..CFG.repo..'/'..CFG.name)
warn('  Branch:       '..CFG.branch)
warn('  File:         '..LOADER_PATH)
warn('  URLs to try:')
for i,u in ipairs(urls) do warn('    ['..i..'] '..u) end

local ls=loadstring or (function() local g=getgenv;if type(g)=='function'then g=g()end;return g and g.loadstring end)()
if type(ls)~='function' then local m='BadWars: loadstring not available';warn(m);error(m,0) end

local loaderCode,usedUrl=httpGet(urls)
if loaderCode==nil then
	local m='BadWars: All HTTP methods failed for all URL formats.'
	warn(m);error(m,0)
end
if type(loaderCode)~='string' or loaderCode=='' then
	local m='BadWars: Empty response from all URL formats.'
	warn(m);error(m,0)
end
-- Check for 404 in both GitHub raw format and API format
if loaderCode:find('404: Not Found',1,true) or loaderCode:find('"message":"Not Found"',1,true) then
	warn('BadWars: [404 RESPONSE BODY - first 500 chars]')
	warn(loaderCode:sub(1,500))
	warn('BadWars: [END 404 BODY]')
	local m='FILE NOT FOUND at '..tostring(usedUrl)
	warn(m);error(m,0)
end
warn('BadWars: Downloaded from '..tostring(usedUrl)..' ('..#loaderCode..' bytes)')

local loaderFunc,loaderErr=ls(loaderCode,'badwars-loader')
if not loaderFunc then local m='BadWars: compile error: '..tostring(loaderErr);warn(m);error(m,0) end

local ok,result=xpcall(loaderFunc,debug.traceback)
if not ok then local m='BadWars: Loader error: '..tostring(result);warn(m);error(m,0) end

return result
