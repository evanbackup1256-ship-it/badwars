-- BadWars Loader v5.0
local loaderStart = os.clock()
local collectgarbage = collectgarbage

-- Polyfills
isfile = isfile or function(f) local s,r=pcall(readfile,f) return s and r~=nil and r~='' end
delfile = delfile or function(f) writefile(f,'') end
isfolder = isfolder or function() return false end
makefolder = makefolder or function() end
listfiles = listfiles or function() return {} end
readfile = readfile or function() return '' end
writefile = writefile or function() end
cloneref = cloneref or function(o) return o end
setthreadidentity = setthreadidentity or function() end
queue_on_teleport = queue_on_teleport or function() end

-- httpGet: matches entry.lua's pattern exactly
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

-- Status GUI
local statusGui, statusLabel
pcall(function()
	local p = cloneref(game:GetService('CoreGui'))
	local o = p:FindFirstChild('BadWarsLoaderStatus')
	if o then o:Destroy() end
	statusGui = Instance.new('ScreenGui')
	statusGui.Name='BadWarsLoaderStatus'; statusGui.DisplayOrder=10000000; statusGui.IgnoreGuiInset=true; statusGui.ResetOnSpawn=false
	statusGui.Parent=p
end)
if not statusGui then
	pcall(function()
		local p = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
		local o = p:FindFirstChild('BadWarsLoaderStatus')
		if o then o:Destroy() end
		statusGui = Instance.new('ScreenGui')
		statusGui.Name='BadWarsLoaderStatus'; statusGui.DisplayOrder=10000000; statusGui.IgnoreGuiInset=true; statusGui.ResetOnSpawn=false
		statusGui.Parent=p
	end)
end
if statusGui then
	statusLabel = Instance.new('TextLabel')
	statusLabel.Name='Status'; statusLabel.Size=UDim2.new(0,680,0,88); statusLabel.Position=UDim2.fromOffset(12,92)
	statusLabel.BackgroundColor3=Color3.fromRGB(15,18,24); statusLabel.BackgroundTransparency=0.15; statusLabel.BorderSizePixel=0
	statusLabel.Font=Enum.Font.GothamBold; statusLabel.TextSize=14; statusLabel.TextXAlignment=Enum.TextXAlignment.Left
	statusLabel.TextColor3=Color3.fromRGB(235,245,255); statusLabel.TextWrapped=true
	statusLabel.Text='BadWars: initializing...'
	statusLabel.Parent=statusGui
	local pad=Instance.new('UIPadding'); pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12); pad.Parent=statusLabel
end
shared.BadStatusGui=statusGui
shared.BadStatus=function(msg,isErr)
	local t='BadWars: '..tostring(msg); warn(t)
	if statusLabel then
		if not isErr and tostring(msg):find('ready',1,true) then statusGui.Enabled=false; return end
		statusGui.Enabled=true; statusLabel.Text=t; statusLabel.TextColor3=isErr and Color3.fromRGB(255,120,120) or Color3.fromRGB(235,245,255)
	end
end
local setStatus = shared.BadStatus
setStatus('pipeline: ready')

-- Error tracking
local __rtErrs = shared.__badwars_runtime_errors
if type(__rtErrs)~='table' then __rtErrs={}; shared.__badwars_runtime_errors=__rtErrs end
local function recordErr(mod,msg) table.insert(__rtErrs,{module=tostring(mod),error=tostring(msg),time=os.clock()}); warn('BadWars: [ERROR] '..tostring(mod)..': '..tostring(msg)) end

-- Loadstring
setStatus('pipeline: checking loadstring')
local _loadstring
pcall(function() local g=getgenv; if type(g)=='function' then g=g() end; _loadstring=(g and g.loadstring) or loadstring end)
if type(_loadstring)~='function' then local m='loadstring unavailable'; setStatus('ERROR: '..m,true); error(m,0) end

-- Cache setup
setStatus('pipeline: cache setup')
for _,d in {'badscript','badscript/games','badscript/profiles','badscript/assets','badscript/libraries','badscript/guis'} do
	if not isfolder(d) then makefolder(d) end
end
local function wipeAny(p) if isfolder(p) then for _,f in listfiles(p) do if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end end end end
local function wipeGen(p) if isfolder(p) then for _,f in listfiles(p) do if f:find('loader') then continue end; if isfolder(f) then wipeGen(f) end; if isfile(f) then local c=readfile(f); if type(c)=='string' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) then delfile(f) end end end end end

local cacheVer='badwars-v5-diagnostic'
local cacheFile='badscript/profiles/cache-version.txt'
if (isfile(cacheFile) and readfile(cacheFile) or '')~=cacheVer then
	setStatus('cache cleared (version mismatch)')
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua','badscript/security.lua'} do if isfile(f) then delfile(f) end end
	wipeAny('badscript/assets'); wipeGen('badscript/games'); wipeGen('badscript/guis'); wipeGen('badscript/libraries')
	writefile(cacheFile,cacheVer)
end
writefile('badscript/profiles/commit.txt','main')

-- Download main.lua with full diagnostics
setStatus('pipeline: downloading main orchestrator')
local MAIN_URL = 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/main.lua'
setStatus('download URL: ' .. MAIN_URL)
local raw = httpGet(MAIN_URL)
if type(raw) == 'string' and #raw > 0 then
	setStatus('download OK: ' .. #raw .. ' bytes')
	-- Validate: GitHub raw 404 pages contain "404: Not Found"
	if raw:find('404: Not Found', 1, true) then
		recordErr('loader', 'URL returned 404: ' .. MAIN_URL)
		raw = nil
	else
		local header = '-- BadWars by usingINales\n'
		local code = header .. raw
		pcall(function() writefile('badscript/main.lua', code) end)
		-- Compile-check before executing
		local fn, cerr = _loadstring(code, 'main')
		if fn then
			setStatus('main.lua compiled OK')
			setStatus('pipeline: executing main orchestrator')
			local ok, result = xpcall(fn, debug.traceback)
			if not ok then
				local m = 'main.lua runtime error: ' .. tostring(result)
				setStatus('ERROR: ' .. m, true); recordErr('loader', m); error(m, 0)
			end
			-- Post-execution validation
			setStatus('pipeline: validation')
			local issues = {}
			if not shared.Bad then table.insert(issues, 'shared.Bad is nil') end
			local report = shared.__badwars_universal_report
			if type(report)=='table' and type(report.failed)=='table' and #report.failed>0 then
				for _,e in ipairs(report.failed) do table.insert(issues,'Module ['..tostring(e.name)..']: '..tostring(e.error)) end
			end
			if #__rtErrs>0 then for _,e in ipairs(__rtErrs) do table.insert(issues,'Runtime ['..tostring(e.module)..']: '..tostring(e.error)) end end
			if #issues>0 then
				warn('BadWars: [VALIDATION] '..#issues..' issue(s):')
				for _,i in ipairs(issues) do warn('  ! '..i) end
				setStatus(#issues..' issue(s) found',true)
			else
				setStatus('validation passed')
			end
			local el=os.clock()-loaderStart
			local final='Loader complete in '..string.format('%.2f',el)..'s'
			if #issues>0 then final=final..' ('..#issues..' issue(s))' end
			warn('BadWars: '..final)
			return result
		else
			raw = nil
			recordErr('loader', 'main.lua compile failed: ' .. tostring(cerr))
		end
	end
else
	recordErr('loader', 'httpGet returned nil for: ' .. MAIN_URL)
end

-- Fallback to cache
setStatus('trying cached main.lua')
local cached = isfile('badscript/main.lua') and readfile('badscript/main.lua') or ''
if type(cached) == 'string' and #cached > 100 then
	local fn, cerr = _loadstring(cached, 'main')
	if fn then
		setStatus('using cached main.lua')
		setStatus('pipeline: executing')
		local ok, result = xpcall(fn, debug.traceback)
		if not ok then setStatus('ERROR: '..tostring(result),true); recordErr('loader',tostring(result)); error(tostring(result),0) end
		warn('BadWars: Loader complete (cached) in '..string.format('%.2f',os.clock()-loaderStart)..'s')
		return result
	end
end

-- Fatal: nothing works
local m = 'Failed to download main.lua from GitHub. Check that the URL is accessible and your executor supports HTTP requests.'
setStatus('ERROR: '..m,true)
recordErr('loader', m)
error(m, 0)