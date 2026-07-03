-- BadWars Main v3.1 - URL-consistent Pipeline
repeat task.wait() until game:IsLoaded()
if shared.Bad then pcall(function() shared.Bad:Uninject() end) end
shared.BadSecurityStarted=nil

local os_clock=os.clock
local pipelineStart=os_clock()
local collectgarbage=collectgarbage

-- Error tracker
local __rtErrs=shared.__badwars_runtime_errors
if type(__rtErrs)~='table' then __rtErrs={}; shared.__badwars_runtime_errors=__rtErrs end
local function recordErr(mod,err) table.insert(__rtErrs,{module=tostring(mod),error=tostring(err),time=os_clock()}) end

-- URL configuration (consistent with entry.lua and loader.lua)
local CFG={repo='evanbackup1256-ship-it',name='badwars',branch='main'}
local function rawUrls(path)
	local repo=CFG.repo..'/'..CFG.name
	local p=path:gsub(' ','%%20')
	return {'https://github.com/'..repo..'/raw/'..CFG.branch..'/'..p,'https://raw.githubusercontent.com/'..repo..'/'..CFG.branch..'/'..p}
end

-- Safe helpers
local function typeName(v) return typeof(v) end
local function safeStr(v) if v==nil then return '' end; if type(v)~='table' then return tostring(v) end; local o,r=pcall(function() return table.concat(v,', ') end); if o then return r end; return '<table>' end
local function safeConcat(...) local r={}; for _,p in ipairs({...}) do table.insert(r,safeStr(p)) end; return table.concat(r) end

-- Feature state: ensures every option has {Enabled, Value, ...}
-- Profile data sometimes stores booleans instead of {Enabled=true}
local function normalize(v)
	if type(v)=='boolean' then return {Enabled=v} end
	if type(v)~='table' then return {Enabled=false} end
	return v
end
-- Safe option read: option.Value or option.Enabled with fallback
local function optVal(t,key,default)
	if type(t)~='table' then return default end
	local v=t[key]
	if v==nil then return default end
	return v
end
local function optEnabled(t,default)
	if type(t)~='table' then return default or false end
	if type(t.Enabled)=='boolean' then return t.Enabled end
	return default or false
end
-- Safe toggle/dropdown read (handles both table and saved boolean state)
local function safeOption(v)
	v=normalize(v)
	if type(v.Enabled)~='boolean' then v.Enabled=false end
	return v
end
-- Safe module reference: Bad.Modules.Fly.Enabled → check cascade
local function moduleEnabled(modName)
	if not shared.Bad or type(shared.Bad.Modules)~='table' then return false end
	local m=shared.Bad.Modules[modName]
	if type(m)~='table' then return false end
	return optEnabled(m,false)
end

local function ensureRuntimeCategories(api)
	if type(api)~='table' then return end
	api.Categories=type(api.Categories)=='table' and api.Categories or {}
	local function makeToggle(value) return {Enabled=value==nil and false or value} end
	local function ensureEvent(owner,key)
		if type(owner[key])~='table' or not owner[key].Event or type(owner[key].Fire)~='function' then
			owner[key]=Instance.new('BindableEvent')
			warn('BadWars: [PREFLIGHT] registered missing '..tostring(owner.Name or 'service')..'.'..key..' event')
			if type(api.Clean)=='function' then pcall(function() api:Clean(owner[key]) end) end
		end
	end
	api.Categories.Main=type(api.Categories.Main)=='table' and api.Categories.Main or {Type='ServiceCategory',Name='Main',Options={}}
	api.Categories.Main.Options=type(api.Categories.Main.Options)=='table' and api.Categories.Main.Options or {}
	api.Categories.Main.Options['GUI bind indicator']=normalize(api.Categories.Main.Options['GUI bind indicator'])
	api.Categories.Main.Options['Teams by server']=normalize(api.Categories.Main.Options['Teams by server'])
	api.Categories.Main.Options['Use team color']=normalize(api.Categories.Main.Options['Use team color'])

	api.Categories.Friends=type(api.Categories.Friends)=='table' and api.Categories.Friends or {Type='ServiceCategory',Name='Friends',Options={},ListEnabled={}}
	api.Categories.Friends.Options=type(api.Categories.Friends.Options)=='table' and api.Categories.Friends.Options or {}
	api.Categories.Friends.ListEnabled=type(api.Categories.Friends.ListEnabled)=='table' and api.Categories.Friends.ListEnabled or {}
	api.Categories.Friends.Options['Use friends']=normalize(api.Categories.Friends.Options['Use friends'])
	api.Categories.Friends.Options['Recolor visuals']=normalize(api.Categories.Friends.Options['Recolor visuals'])
	api.Categories.Friends.Options['Friends color']=type(api.Categories.Friends.Options['Friends color'])=='table' and api.Categories.Friends.Options['Friends color'] or {Hue=1,Sat=1,Value=1}
	ensureEvent(api.Categories.Friends,'Update')
	ensureEvent(api.Categories.Friends,'ColorUpdate')

	api.Categories.Targets=type(api.Categories.Targets)=='table' and api.Categories.Targets or {Type='ServiceCategory',Name='Targets',Options={},ListEnabled={}}
	api.Categories.Targets.Options=type(api.Categories.Targets.Options)=='table' and api.Categories.Targets.Options or {}
	api.Categories.Targets.ListEnabled=type(api.Categories.Targets.ListEnabled)=='table' and api.Categories.Targets.ListEnabled or {}
	ensureEvent(api.Categories.Targets,'Update')
end

-- Status & notify
local function setStatus(msg,isErr)
	if shared.BadStatus then pcall(function() shared.BadStatus(msg,isErr) end) end
end
local function notify(title,text,dur)
	pcall(function() game:GetService('StarterGui'):SetCore('SendNotification',{Title=safeStr(title),Text=safeStr(text),Duration=dur or 8}) end)
end
local __logHistory={}
local function logMod(stage,name,elapsed,success,detail)
	local key=safeStr(name)..'|'..safeStr(detail)
	if __logHistory[key] then __logHistory[key]=__logHistory[key]+1; return end
	__logHistory[key]=1
	local tag=success and'[OK]'or'[FAIL]'
	local msg=tag..' ['..stage..'] '..safeStr(name)
	if elapsed then msg=msg..' ('..string.format('%.3f',elapsed)..'s)' end
	if detail then msg=msg..' - '..safeStr(detail) end
	warn('BadWars: '..msg)
end

-- Download
local _loadstring
pcall(function() local g=getgenv; if type(g)=='function' then g=g() end; _loadstring=(g and g.loadstring) or loadstring end)
if not _loadstring then _loadstring=function(s) error('loadstring unavailable') end end
isfile=isfile or function(f) local s,r=pcall(readfile,f); return s and r~=nil and r~='' end
delfile=delfile or function(f) writefile(f,'') end
isfolder=isfolder or function() return false end
makefolder=makefolder or function() end
listfiles=listfiles or function() return {} end
readfile=readfile or function() return '' end
writefile=writefile or function() end
cloneref=cloneref or function(o) return o end
setthreadidentity=setthreadidentity or function() end
queue_on_teleport=queue_on_teleport or function() end

local function httpGetMulti(urls)
	for _,url in ipairs(urls) do
		local fn=(game and game.HttpGet)
		if type(fn)~='function' then
			local env=getgenv and type(getgenv)=='function' and getgenv()
			fn=env and env.HttpGet
		end
		if type(fn)=='function' then
			local ok,res=pcall(fn,game,url,true)
			if ok and type(res)=='string' and #res>0 then return res end
		end
		local ok,res=pcall(function()
			return cloneref(game:GetService('HttpService')):GetAsync(url,true)
		end)
		if ok and type(res)=='string' and #res>0 then return res end
	end
	return nil
end

local function httpGet(url) return httpGetMulti({url}) end
HttpGet=httpGet

local function isNotFoundBody(body)
	if type(body)~='string' then return false end
	local trimmed=body:match('^%s*(.-)%s*$')
	return trimmed=='404: Not Found' or trimmed=='{"message":"Not Found"}' or (#trimmed<200 and trimmed:find('"message"%s*:%s*"Not Found"')~=nil)
end

local function downloadFile(path)
	if not HttpGet then return nil,'HttpGet nil' end
	local cached=isfile(path) and readfile(path)
	if type(cached)=='string' and #cached>0 then return cached end
	setStatus('downloading '..tostring(path))
	local urls=rawUrls(path)
	local res=httpGetMulti(urls)
	if type(res)~='string' or #res==0 then return nil,'empty response from '..urls[1] end
	if isNotFoundBody(res) then return nil,'FILE NOT FOUND: '..urls[1] end
	if path:find('.lua') then res='-- BadWars by usingINales\n'..res end
	pcall(function() writefile(path,res) end)
	return res
end

local function splitLines(t) local r={}; for l in tostring(t):gmatch('[^\r\n]+') do l=l:match('^%s*(.-)%s*$'); if l~='' and not l:find('^#') then table.insert(r,l) end end; return r end

-- Universal module bundle builder (no pre-built bundle, builds from sources with pcall isolation)
local function buildBundle(name,basePath,manifestPath)
	local baseCode=downloadFile(basePath)
	if type(baseCode)~='string' or baseCode=='' then return nil,'missing base' end
	local parts={baseCode}
	local manifest=downloadFile(manifestPath)
	local preamble={
		'',
		'local __m_ok={}',
		'local __m_meta={}',
		'local __m_path_by_name={}',
		'local function __preflight_m(idx,path,category,moduleName,hasInit,hasUpdate)',
		'  local issues={}',
		'  if type(category)~="string" or category=="" then table.insert(issues,"category missing") end',
		'  if type(moduleName)~="string" or moduleName=="" then table.insert(issues,"name missing") end',
		'  if hasInit==nil then table.insert(issues,"enabled/init state unknown") end',
		'  if hasUpdate==nil then table.insert(issues,"update contract unknown") end',
		'  __m_meta[idx]={path=path,category=category,name=moduleName,hasInit=hasInit,hasUpdate=hasUpdate,issues=issues}',
		'  __m_path_by_name[moduleName]=path',
		'  if #issues>0 then warn("BadWars: [PREFLIGHT] "..path.." ("..tostring(moduleName).."): "..table.concat(issues,", ")) end',
		'end',
		'local function __postflight_m()',
		'  local bad=shared and shared.Bad',
		'  if type(bad)~="table" then warn("BadWars: [PREFLIGHT] Bad API missing after universal module registration"); return end',
		'  for _,meta in pairs(__m_meta) do',
		'    local mod=(bad.Modules and bad.Modules[meta.name]) or (bad.Legit and bad.Legit.Modules and bad.Legit.Modules[meta.name])',
		'    local issues={}',
		'    if not mod then table.insert(issues,"module not registered")',
		'    else',
		'      if type(mod.Category)~="string" or mod.Category=="" then table.insert(issues,"category missing") end',
		'      if type(mod.Name)~="string" or mod.Name=="" then table.insert(issues,"name missing") end',
		'      if type(mod.Enabled)~="boolean" then table.insert(issues,"enabled state invalid") end',
		'      if type(mod.Toggle)~="function" then table.insert(issues,"init/toggle function missing") end',
		'      if type(mod.Options)~="table" then table.insert(issues,"config/options invalid") end',
		'      if meta.hasUpdate==false then table.insert(issues,"required update function/event missing") end',
		'    end',
		'    if #issues>0 then warn("BadWars: [PREFLIGHT] "..tostring(meta.name).." @ "..tostring(meta.path)..": "..table.concat(issues,", ")) end',
		'  end',
		'end',
		'local function __run_m(idx,name,fn)',
		'  local ok,err=pcall(fn)',
		'  if not ok then',
		'    local meta=__m_meta[idx]',
		'    local label=meta and ((meta.name or "?").." @ "..(meta.path or name)) or name',
		'    warn("BadWars: [MODULE FAIL] "..label..": "..tostring(err))',
		'    if shared and shared.__badwars_runtime_errors then',
		'      table.insert(shared.__badwars_runtime_errors,{module=label,error=tostring(err)})',
		'    end',
		'  end',
		'  __m_ok[idx]=ok',
		'end',
		''
	}
	table.insert(parts,table.concat(preamble,'\n'))
	local loaded=0; local mi=1
	if type(manifest)=='string' then
		for _,mp in splitLines(manifest) do
			if mp~=basePath then
				setStatus('loading module: '..tostring(mp))
				local code=downloadFile(mp)
				if type(code)=='string' and code~='' then
					local category=code:match('Bad%.Categories%.([%w_]+)%s*:%s*CreateModule%s*%(') or (code:match('Bad%.Legit%s*:%s*CreateModule%s*%(') and 'Legit') or ''
					local moduleName=code:match("Name%s*=%s*'([^']+)'") or code:match('Name%s*=%s*"([^"]+)"') or mp:match('([^/\\]+)%.lua$') or mp
					local hasInit=code:find('CreateModule%s*%(',1,false)~=nil
					local requiresUpdate=code:find('%.Update',1,false)~=nil
					local hasUpdate=(not requiresUpdate) or code:find('Update%s*=',1,false)~=nil or code:find('BindableEvent',1,true)~=nil
					table.insert(parts,'\n__preflight_m('..tostring(mi)..','..string.format('%q',mp)..','..string.format('%q',category)..','..string.format('%q',moduleName)..','..tostring(hasInit)..','..tostring(hasUpdate)..')')
					table.insert(parts,'\n-- module '..tostring(mi)..': '..mp..'\n__run_m('..tostring(mi)..','..string.format('%q',mp)..',function()\n'..code..'\nend)')
					loaded=loaded+1; mi=mi+1
				end
			end
		end
	end
	setStatus('bundled '..tostring(loaded)..' '..tostring(name)..' modules')
	local summary='\n__postflight_m()\nlocal __ok=0;local __fail=0\nfor _,v in ipairs(__m_ok) do if v then __ok=__ok+1 else __fail=__fail+1 end end\nwarn("BadWars: [BUNDLE] '..tostring(name)..': "..__ok.." ok, "..__fail.." fail")'
	table.insert(parts,summary)
	return table.concat(parts,'\n')
end

-- Game module path map
local gamePaths={
	[606849621]='badscript/games/jailbreak/606849621 - main/base.lua',
	[893973440]='badscript/games/893973440 - flee the facility/base.lua',
	[6872265039]='badscript/games/bedwars/6872265039 - lobby/base.lua',
	[6872274481]='badscript/games/bedwars/6872274481 - game/base.lua',
	[8444591321]='badscript/games/bedwars/8444591321 - mega.lua',
	[8560631822]='badscript/games/bedwars/8560631822 - micro.lua',
	[77790193039862]='badscript/games/1.8arena/77790193039862 - game/base.lua',
	[80041634734121]='badscript/games/1.8arena/80041634734121 - duel.lua',
	[139566161526375]='badscript/games/bridge duel/139566161526375 - game/base.lua',
	[16483433878]='badscript/games/blocktales/16483433878 - blocktales/base.lua',
	[5938036553]='badscript/games/frontlines/5938036553 - game/base.lua',
	[155615604]='badscript/games/prison life/155615604 - main/base.lua',
	[115875349872417]='badscript/games/redliner/115875349872417 - game/base.lua',
	[8768229691]='badscript/games/skywars voxel/8768229691 - skywars game/base.lua',
	[8542259458]='badscript/games/skywars voxel/8542259458 - skywars lobby.lua',
}

local function gamePath(placeId) return gamePaths[tonumber(placeId)] or ('badscript/games/'..tostring(placeId)..'.lua') end

local function runGameMod(path,label)
	setStatus('loading game module: '..tostring(path))
	local start=os_clock()
	local code=downloadFile(path)
	if type(code)~='string' or code=='' then return false,'download failed' end
	local fn,err=_loadstring(code,tostring(game.PlaceId))
	if not fn then return false,err or 'compile failed' end
	local ok,runErr=pcall(fn)
	local el=os_clock()-start
	if not ok then logMod('Game',path,el,false,runErr); recordErr(path,runErr); return false,runErr end
	logMod('Game',path,el,true)
	return true
end

-- Health check
local function healthCheck()
	local issues={}; local warns={}
	if not shared.Bad then table.insert(issues,'Bad API nil'); return issues,warns end
	local B=shared.Bad
	if type(B.CreateNotification)~='function' then table.insert(issues,'CreateNotification missing') end
	if type(B.Save)~='function' then table.insert(issues,'Save missing') end
	if type(B.Load)~='function' then table.insert(issues,'Load missing') end
	if type(B.Clean)~='function' then table.insert(issues,'Clean missing') end
	if not B.Categories then table.insert(warns,'Categories missing')
	elseif not B.Categories.Main then table.insert(warns,'Main category missing') end
	if type(B.Modules)~='table' then table.insert(warns,'Modules missing') end
	if type(B.Libraries)~='table' then table.insert(warns,'Libraries missing') end
	pcall(function() collectgarbage('collect'); local m=collectgarbage('count'); if m>50000 then table.insert(warns,'High memory: '..string.format('%.1f',m)..' KB') end end)
	return issues,warns
end

-- Finish loading
local function finish()
	shared.Bad.Init=nil
	setStatus('loading profile')
	shared.Bad:Load()
	if not shared.BadReload then
		pcall(function()
			local cg=shared.Bad.gui and shared.Bad.gui.ScaledGui and shared.Bad.gui.ScaledGui.ClickGui
			if cg then cg.Visible=true; setStatus('ready - menu open') end
		end)
	end
	task.spawn(function() repeat shared.Bad:Save(); task.wait(10) until not shared.Bad.Loaded end)
	local teleported
	shared.Bad:Clean(shared.Bad.gui and shared.Bad.gui:FindFirstChild('LocalPlayer') and shared.Bad.gui:FindFirstChild('LocalPlayer').OnTeleport:Connect(function()
		if not teleported and not shared.BadIndependent then
			teleported=true
			local loaderUrls=rawUrls('badscript/loader.lua')
local script='shared.BadReload=true\nif shared.BadDeveloper then\nloadstring(readfile(\'badscript/loader.lua\'),\'loader\')()\nelse\nloadstring(game:HttpGet(\''..loaderUrls[1]..'\',true),\'loader\')()\nend'
			if shared.BadDeveloper then script='shared.BadDeveloper=true\n'..script end
			shared.Bad:Save()
			queue_on_teleport(script)
		end
	end) or function() end)
	if not shared.BadReload and shared.Bad.Categories and shared.Bad.Categories.Main and shared.Bad.Categories.Main.Options and shared.Bad.Categories.Main.Options['GUI bind indicator'] and shared.Bad.Categories.Main.Options['GUI bind indicator'].Enabled then
		shared.Bad:CreateNotification('BadWars','by usingINales | Press keybind to open GUI',6)
	end
end

-- ============ PIPELINE ============

-- Stage 1: Deps
setStatus('pipeline: dependencies')
local deps={'Players','RunService','UserInputService','TweenService','Lighting','HttpService','GuiService','ReplicatedStorage','TeleportService','MarketplaceService'}
local missing={}
for _,d in ipairs(deps) do
	local ok,sv=pcall(function() return game:GetService(d) end)
	if not ok or not sv then table.insert(missing,d) end
end
if #missing>0 then warn('BadWars: Missing services: '..table.concat(missing,', ')) end

-- Stage 2: Notify
pcall(function() game:GetService('StarterGui'):SetCore('SendNotification',{Title='BadWars',Text='by usingINales | Dev Mode Active',Duration=6}) end)

-- Stage 3: GUI Profile
local defaultGui='liquidbounce'
local validGuis={liquidbounce=true,new=true,old=true,rise=true,wurst=true}
local savedGui=isfile('badscript/profiles/gui.txt') and readfile('badscript/profiles/gui.txt') or ''
if not validGuis[savedGui] or savedGui=='new' or savedGui=='old' then writefile('badscript/profiles/gui.txt',defaultGui) end
local gui=readfile('badscript/profiles/gui.txt')
if not isfolder('badscript/assets/'..gui) then makefolder('badscript/assets/'..gui) end

-- Stage 4: Load GUI
setStatus('loading GUI')
local guiStart=os_clock()
local guiCode=downloadFile('badscript/guis/'..gui..'/gui.lua')
if type(guiCode)~='string' or guiCode=='' then error('GUI download failed',0) end
local guiFn,guiErr=_loadstring(guiCode,'gui')
if not guiFn then error('GUI compile: '..tostring(guiErr),0) end
local ok,api=pcall(guiFn)
if not ok or type(api)~='table' or type(api.CreateNotification)~='function' then error('GUI returned invalid API',0) end
shared.Bad=api
ensureRuntimeCategories(api)
logMod('GUI',gui,os_clock()-guiStart,true)
setStatus('GUI loaded')

-- Stage 5: Security
setStatus('pipeline: security')
local secStart=os_clock()
local secCode=downloadFile('badscript/security.lua')
if type(secCode)=='string' and secCode~='' then
	local secFn,secErr=_loadstring(secCode,'security')
	if secFn then
		local ok2,sec=pcall(secFn)
		if ok2 and type(sec)=='table' and type(sec.Start)=='function' then
			local verified,status=sec:Start(api)
			if verified then logMod('Security','security.lua',os_clock()-secStart,true,tostring(status)) end
		end
	end
end

-- Stage 6: Universal Modules
if not shared.BadIndependent then
	setStatus('pipeline: universal modules')
	local uniStart=os_clock()
	local uniCode,uniErr=buildBundle('universal','badscript/games/universal - base/base.lua','badscript/games/universal - base/files.txt')
	if type(uniCode)=='string' and uniCode~='' then
		local uniFn,uniCompile=_loadstring(uniCode,'universal')
		if uniFn then
			local ok3,runErr=pcall(uniFn)
			if not ok3 then setStatus('ERROR universal: '..tostring(runErr),true); recordErr('universal',runErr) end
		end
	else
		setStatus('WARNING: universal modules unavailable',true)
	end
	logMod('Universal','build',os_clock()-uniStart,true)
	setStatus('universal modules loaded')

	-- Stage 7: Game Module
	local gPath=gamePath(game.PlaceId)
	if isfile(gPath) or gamePaths[tonumber(game.PlaceId)] then
		runGameMod(gPath,isfile(gPath) and 'cached' or 'mapped')
	else
		setStatus('no game module for place '..tostring(game.PlaceId))
	end

	-- Stage 8: Finish
	setStatus('pipeline: finalizing')
	finish()

	-- Stage 9: Health Check
	local issues,warns=healthCheck()
	if #issues>0 then
		warn('BadWars: [HEALTH] Issues:')
		for _,i in ipairs(issues) do warn('  x '..i) end
	end
	if #warns>0 then
		warn('BadWars: [HEALTH] Warnings:')
		for _,w in ipairs(warns) do warn('  ! '..w) end
	end

	-- Stage 10: Summary
	local report=shared.__badwars_universal_report
	local uniFail=0
	if type(report)=='table' then
		local fc=type(report.failed)=='table' and #report.failed or 0
		if fc>0 then
			warn('BadWars: Failed modules:')
			for _,e in ipairs(report.failed) do warn('  x '..tostring(e.name)..' ['..tostring(e.error)..']') end
		end
		uniFail=fc
	end
	local rtCount=#__rtErrs
	local totalErr=#issues+uniFail+rtCount
	local el=os_clock()-pipelineStart
	if totalErr==0 then
		setStatus('ready - '..string.format('%.2f',el)..'s')
	else
		if rtCount>0 then for _,e in ipairs(__rtErrs) do warn('BadWars: [RUNTIME] '..tostring(e.module)..': '..tostring(e.error)) end end
		setStatus('loaded with '..totalErr..' issue(s) - '..string.format('%.2f',el)..'s',true)
	end
	warn('BadWars: Pipeline '..(totalErr==0 and 'OK' or 'ISSUES')..' in '..string.format('%.2f',el)..'s'..(totalErr>0 and ' ('..totalErr..' error(s))' or ''))
else
	shared.Bad.Init=finish
	setStatus('independent mode')
	return api
end
