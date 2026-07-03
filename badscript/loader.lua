-- BadWars Loader v3.0 - Reliable Pipeline
local loaderStart = os.clock()
local collectgarbage = collectgarbage

-- Stage 0: Executor API Polyfills
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

local function httpGet(url)
	local g = game
	local fn = g.HttpGet or (getgenv and type(getgenv)=='function' and getgenv().HttpGet)
	if fn then return fn(g,url,true) end
	pcall(function() return cloneref(g:GetService('HttpService')):GetAsync(url,true) end)
	return nil
end
HttpGet = httpGet

-- Stage 1: Status GUI
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
		statusGui=Instance.new('ScreenGui'); statusGui.Name='BadWarsLoaderStatus'; statusGui.DisplayOrder=10000000; statusGui.IgnoreGuiInset=true; statusGui.ResetOnSpawn=false
		statusGui.Parent=p
	end)
end
if statusGui then
	statusLabel=Instance.new('TextLabel')
	statusLabel.Name='Status'; statusLabel.Size=UDim2.new(0,680,0,88); statusLabel.Position=UDim2.fromOffset(12,92)
	statusLabel.BackgroundColor3=Color3.fromRGB(15,18,24); statusLabel.BackgroundTransparency=0.15; statusLabel.BorderSizePixel=0
	statusLabel.Font=Enum.Font.GothamBold; statusLabel.TextSize=14; statusLabel.TextXAlignment=Enum.TextXAlignment.Left
	statusLabel.TextColor3=Color3.fromRGB(235,245,255); statusLabel.TextWrapped=true
	statusLabel.Text='BadWars: initializing pipeline...'
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
local setStatus=shared.BadStatus
setStatus('pipeline: status gui ready')

-- Runtime error tracker
local errors = shared.__badwars_runtime_errors
if type(errors)~='table' then errors={}; shared.__badwars_runtime_errors=errors end
local function recordErr(mod,err)
	table.insert(errors,{module=tostring(mod),error=tostring(err),time=os.clock()})
	warn('BadWars: [ERROR] '..tostring(mod)..': '..tostring(err))
end

-- Stage 2: Loadstring Setup
local _loadstring
pcall(function()
	local g=getgenv; if type(g)=='function' then g=g() end
	_loadstring=(g and g.loadstring) or loadstring
end)
if not _loadstring then _loadstring=function(s) error('loadstring unavailable') end end

-- Stage 3: Cache Management  
local function wipeFolder(path)
	if not isfolder(path) then return end
	for _,f in listfiles(path) do
		if f:find('loader') then continue end
		if isfolder(f) then wipeFolder(f) end
		if isfile(f) then
			local c=readfile(f)
			if type(c)=='string' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) then delfile(f) end
		end
	end
end
local function wipeAny(path)
	if not isfolder(path) then return end
	for _,f in listfiles(path) do
		if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end
	end
end

for _,dir in {'badscript','badscript/games','badscript/profiles','badscript/assets','badscript/libraries','badscript/guis'} do
	if not isfolder(dir) then makefolder(dir) end
end

-- Cache version check
setStatus('pipeline: cache integrity')
local cacheVer='badwars-v4-reliable'
local cachePath='badscript/profiles/cache-version.txt'
if (isfile(cachePath) and readfile(cachePath) or '')~=cacheVer then
	setStatus('clearing old cache')
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua','badscript/security.lua'} do if isfile(f) then delfile(f) end end
	wipeAny('badscript/assets'); wipeFolder('badscript/games'); wipeFolder('badscript/guis'); wipeFolder('badscript/libraries')
	writefile(cachePath,cacheVer)
end
writefile('badscript/profiles/commit.txt','main')

-- Stage 4: Download main.lua
setStatus('pipeline: downloading main orchestrator')
local mainCode
local dlOk, dlErr = pcall(function()
	local raw = httpGet('https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/main.lua')
	if type(raw)~='string' or raw=='' or raw:match('404') then error('Failed to download main.lua') end
	mainCode='-- BadWars by usingINales\n'..raw
	writefile('badscript/main.lua',mainCode)
end)
if not dlOk or type(mainCode)~='string' or mainCode=='' then
	setStatus('ERROR: '..tostring(dlErr),true); error(tostring(dlErr),0)
end

-- Stage 5: Compile and execute main.lua
setStatus('pipeline: compiling main')
local mainFunc, mainErr = _loadstring(mainCode,'main')
if not mainFunc then setStatus('ERROR compile: '..tostring(mainErr),true); error(tostring(mainErr),0) end

setStatus('pipeline: executing main')
local ok, result = xpcall(mainFunc,debug.traceback)
if not ok then setStatus('ERROR runtime: '..tostring(result),true); recordErr('main.lua',result) end

-- Stage 6: Post-Load Validation
setStatus('pipeline: validation')
local issues={}
local function check(name,cond)
	if not cond then table.insert(issues,name..' check failed') end
end
check('Bad',shared.Bad~=nil)
if shared.Bad then
	check('Bad.CreateNotification',type(shared.Bad.CreateNotification)=='function')
	check('Bad.Modules',type(shared.Bad.Modules)=='table')
	check('Bad.gui',typeof(shared.Bad.gui)=='Instance')
end
local report=shared.__badwars_universal_report
if type(report)=='table' then
	local fc=type(report.failed)=='table' and #report.failed or 0
	if fc>0 then
		for _,e in ipairs(report.failed) do table.insert(issues,'Module ['..tostring(e.name)..']: '..tostring(e.error)) end
	end
end
if type(errors)=='table' and #errors>0 then
	for _,e in ipairs(errors) do table.insert(issues,'Runtime ['..tostring(e.module)..']: '..tostring(e.error)) end
end

if #issues>0 then
	warn('BadWars: [VALIDATION] '..#issues..' issue(s):')
	for _,i in ipairs(issues) do warn('  ! '..i) end
	setStatus(#issues..' issue(s) found',true)
else
	setStatus('validation passed')
end

local elapsed=os.clock()-loaderStart
local final='Loader complete in '..string.format('%.2f',elapsed)..'s'
if #issues>0 then final=final..' ('..#issues..' issue(s))' end
warn('BadWars: '..final)

return result