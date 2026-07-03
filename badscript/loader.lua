-- BadWars Loader v6.1
-- Dual-format URL fallback + all diagnostics

local loaderStart=os.clock()

-- Polyfills
isfile=isfile or function(f)local s,r=pcall(readfile,f)return s and r~=nil and r~=''end
delfile=delfile or function(f)writefile(f,'')end
isfolder=isfolder or function()return false end
makefolder=makefolder or function()end
listfiles=listfiles or function()return{}end
readfile=readfile or function()return''end
writefile=writefile or function()end
cloneref=cloneref or function(o)return o end
setthreadidentity=setthreadidentity or function()end
queue_on_teleport=queue_on_teleport or function()end

-- Config
local CFG={repo='evanbackup1256-ship-it',name='badwars',branch='main',folder='badscript',file='main.lua'}
local function rawUrls(path)
	local r=CFG.repo..'/'..CFG.name..'/'..CFG.branch..'/'
	return {'https://github.com/'..r..'raw/'..path,'https://raw.githubusercontent.com/'..r..path}
end
local ORCH_PATH=CFG.folder..'/'..CFG.file

-- httpGet: tries all URLs, returns (content, used_url)
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

-- Status GUI
local statusGui,statusLabel
pcall(function()
	local p=cloneref(game:GetService('CoreGui'))
	local o=p:FindFirstChild('BadWarsLoaderStatus')
	if o then o:Destroy() end
	statusGui=Instance.new('ScreenGui')
	statusGui.Name='BadWarsLoaderStatus';statusGui.DisplayOrder=10000000;statusGui.IgnoreGuiInset=true;statusGui.ResetOnSpawn=false
	statusGui.Parent=p
end)
if not statusGui then
	pcall(function()
		local p=cloneref(game:GetService('Players')).LocalPlayer.PlayerGui
		local o=p:FindFirstChild('BadWarsLoaderStatus')
		if o then o:Destroy() end
		statusGui=Instance.new('ScreenGui')
		statusGui.Name='BadWarsLoaderStatus';statusGui.DisplayOrder=10000000;statusGui.IgnoreGuiInset=true;statusGui.ResetOnSpawn=false
		statusGui.Parent=p
	end)
end
if statusGui then
	statusLabel=Instance.new('TextLabel')
	statusLabel.Name='Status';statusLabel.Size=UDim2.new(0,680,0,88);statusLabel.Position=UDim2.fromOffset(12,92)
	statusLabel.BackgroundColor3=Color3.fromRGB(15,18,24);statusLabel.BackgroundTransparency=0.15;statusLabel.BorderSizePixel=0
	statusLabel.Font=Enum.Font.GothamBold;statusLabel.TextSize=14;statusLabel.TextXAlignment=Enum.TextXAlignment.Left
	statusLabel.TextColor3=Color3.fromRGB(235,245,255);statusLabel.TextWrapped=true
	statusLabel.Text='BadWars: initializing...';statusLabel.Parent=statusGui
	local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,12);pad.PaddingRight=UDim.new(0,12);pad.Parent=statusLabel
end
shared.BadStatusGui=statusGui
shared.BadStatus=function(msg,isErr)
	local t='BadWars: '..tostring(msg);warn(t)
	if statusLabel then
		if not isErr and tostring(msg):find('ready',1,true) then statusGui.Enabled=false;return end
		statusGui.Enabled=true;statusLabel.Text=t;statusLabel.TextColor3=isErr and Color3.fromRGB(255,120,120) or Color3.fromRGB(235,245,255)
	end
end
local setStatus=shared.BadStatus
setStatus('pipeline: ready')

-- Error tracking
local __rtErrs=shared.__badwars_runtime_errors
if type(__rtErrs)~='table' then __rtErrs={};shared.__badwars_runtime_errors=__rtErrs end
local function recordErr(mod,msg) table.insert(__rtErrs,{module=tostring(mod),error=tostring(msg),time=os.clock()});warn('BadWars: [ERROR] '..tostring(mod)..': '..tostring(msg)) end

-- Loadstring
local _loadstring
pcall(function()local g=getgenv;if type(g)=='function'then g=g()end;_loadstring=(g and g.loadstring)or loadstring end)
if type(_loadstring)~='function' then local m='loadstring unavailable';setStatus('ERROR: '..m,true);error(m,0) end

-- Cache setup
setStatus('pipeline: cache setup')
for _,d in {'badscript','badscript/games','badscript/profiles','badscript/assets','badscript/libraries','badscript/guis'} do
	if not isfolder(d) then makefolder(d) end
end
local function wipeAny(p) if isfolder(p) then for _,f in listfiles(p) do if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end end end end
local function wipeGen(p) if isfolder(p) then for _,f in listfiles(p) do if f:find('loader') then continue end;if isfolder(f) then wipeGen(f) end;if isfile(f) then local c=readfile(f);if type(c)=='string' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) then delfile(f) end end end end end

local cacheVer='badwars-v6-1-dual-url'
local cacheFile='badscript/profiles/cache-version.txt'
if (isfile(cacheFile) and readfile(cacheFile) or '')~=cacheVer then
	setStatus('cache cleared (version mismatch)')
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua','badscript/security.lua'} do if isfile(f) then delfile(f) end end
	wipeAny('badscript/assets');wipeGen('badscript/games');wipeGen('badscript/guis');wipeGen('badscript/libraries')
	writefile(cacheFile,cacheVer)
end
writefile('badscript/profiles/commit.txt','main')

-- ========== SELF-TEST ==========
setStatus('pipeline: self-test')
local urls=rawUrls(ORCH_PATH)
warn('BadWars: [URL DIAGNOSTICS]')
warn('  Repository:   '..CFG.repo..'/'..CFG.name)
warn('  Branch:       '..CFG.branch)
warn('  Folder:       '..CFG.folder)
warn('  File:         '..CFG.file)
warn('  Full path:    '..ORCH_PATH)
warn('  URLs to try:')
for i,u in ipairs(urls) do warn('    ['..i..'] '..u) end

setStatus('validating orchestrator URL')
local raw,usedUrl=httpGet(urls)
if raw==nil then
	local m='All HTTP methods failed for '..ORCH_PATH
	setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
if type(raw)~='string' or raw=='' then
	local m='Empty response for '..ORCH_PATH
	setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
if raw:find('404: Not Found',1,true) or raw:find('"message":"Not Found"',1,true) then
	warn('BadWars: [404 RESPONSE BODY - first 500 chars]')
	warn(raw:sub(1,500))
	warn('BadWars: [END 404 BODY]')
	local m='FILE NOT FOUND. Repo: '..CFG.repo..'/'..CFG.name..' Branch: '..CFG.branch..' Path: '..ORCH_PATH..' URL: '..tostring(usedUrl)
	warn('BadWars: '..m);setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
setStatus('URL validation passed: '..#raw..' bytes from '..tostring(usedUrl))

-- Download & compile
local header='-- BadWars by usingINales\n'
local code=header..raw
pcall(function()writefile('badscript/main.lua',code)end)

local fn,cerr=_loadstring(code,'main')
if not fn then local m='main.lua compile: '..tostring(cerr);setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0) end
setStatus('main.lua compiled OK')

-- Execute
setStatus('pipeline: executing main orchestrator')
local ok,result=xpcall(fn,debug.traceback)
if not ok then local m='main.lua runtime: '..tostring(result);setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0) end

-- Validation
setStatus('pipeline: validation')
local issues={}
if not shared.Bad then table.insert(issues,'shared.Bad is nil') end
local report=shared.__badwars_universal_report
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