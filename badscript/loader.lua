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
	local repo=CFG.repo..'/'..CFG.name
	local p=path:gsub(' ','%%20')
	return {'https://github.com/'..repo..'/raw/'..CFG.branch..'/'..p,'https://raw.githubusercontent.com/'..repo..'/'..CFG.branch..'/'..p}
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

local function isNotFoundBody(body)
	if type(body)~='string' then return false end
	local trimmed=body:match('^%s*(.-)%s*$')
	return trimmed=='404: Not Found' or trimmed=='{"message":"Not Found"}' or (#trimmed<200 and trimmed:find('"message"%s*:%s*"Not Found"')~=nil)
end

-- Status GUI (Premium)
local statusGui
local statusCard
local statusLabel
local stageLabel
local detailLabel
local percentLabel
local progressFill
local progressGlow
local spinner
local statusProgress = 0
local statusError = false
local loaderTweenService = cloneref(game:GetService('TweenService'))

local function loaderTween(object, info, properties)
    if not object or not object.Parent then return nil end
    local ok, tween = pcall(function()
        return loaderTweenService:Create(object, info, properties)
    end)
    if ok and tween then
        tween:Play()
        return tween
    end
    for property, value in pairs(properties) do
        pcall(function() object[property] = value end)
    end
end

local function loaderCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function loaderStroke(parent, color, transparency, thickness)
    local stroke = Instance.new('UIStroke')
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.LineJoinMode = Enum.LineJoinMode.Round
    stroke.Color = color
    stroke.Transparency = transparency
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function resolveStatusProgress(message)
    local lower = string.lower(tostring(message or ''))
    local stages = {
        {'cache setup', 0.08},
        {'cache cleared', 0.12},
        {'self-test', 0.16},
        {'validating orchestrator', 0.22},
        {'url validation passed', 0.30},
        {'compiled ok', 0.38},
        {'executing main', 0.44},
        {'dependencies', 0.49},
        {'selecting current gui', 0.54},
        {'loading gui', 0.59},
        {'gui loaded', 0.66},
        {'loading universal', 0.72},
        {'universal modules ready', 0.80},
        {'game module', 0.86},
        {'loading profile', 0.92},
        {'finalizing', 0.96},
        {'validation passed', 0.98},
        {'ready', 1},
        {'loader complete', 1},
    }
    for _, stage in ipairs(stages) do
        if string.find(lower, stage[1], 1, true) then
            return stage[2]
        end
    end
    return math.min(math.max(statusProgress + 0.012, 0.02), 0.97)
end

local function createPremiumLoader()
    pcall(function()
        local old = shared.BadStatusGui
        if old and typeof(old) == 'Instance' then old:Destroy() end
    end)

    local parent
    pcall(function()
        if type(gethui) == 'function' then parent = gethui() end
    end)
    if not parent then
        pcall(function() parent = cloneref(game:GetService('CoreGui')) end)
    end
    if not parent then
        pcall(function() parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui end)
    end
    if not parent then return end

    local old = parent:FindFirstChild('BadWarsLoaderStatus')
    if old then old:Destroy() end

    statusGui = Instance.new('ScreenGui')
    statusGui.Name = 'BadWarsLoaderStatus'
    statusGui.DisplayOrder = 10000000
    statusGui.IgnoreGuiInset = true
    statusGui.ResetOnSpawn = false
    statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    statusGui.Parent = parent

    local backdrop = Instance.new('Frame')
    backdrop.Name = 'Backdrop'
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(3, 6, 10)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 1
    backdrop.Parent = statusGui
    loaderTween(backdrop, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.32,
    })

    statusCard = Instance.new('Frame')
    statusCard.Name = 'PremiumLoader'
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.5)
    statusCard.Size = UDim2.fromOffset(460, 246)
    statusCard.BackgroundColor3 = Color3.fromRGB(11, 15, 22)
    statusCard.BorderSizePixel = 0
    statusCard.ClipsDescendants = false
    statusCard.ZIndex = 10
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 16)
    local cardStroke = loaderStroke(statusCard, Color3.fromRGB(57, 75, 96), 0.18, 1)

    local cardScale = Instance.new('UIScale')
    cardScale.Scale = 0.92
    cardScale.Parent = statusCard
    loaderTween(cardScale, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 30, 42)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 17, 25)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 10, 15)),
    })
    gradient.Rotation = 90
    gradient.Parent = statusCard

    local accent = Instance.new('Frame')
    accent.Name = 'Accent'
    accent.Size = UDim2.new(1, -32, 0, 2)
    accent.Position = UDim2.fromOffset(16, 1)
    accent.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    accent.BorderSizePixel = 0
    accent.ZIndex = 12
    accent.Parent = statusCard
    loaderCorner(accent, 99)
    local accentGradient = Instance.new('UIGradient')
    accentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 125, 255)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(16, 213, 165)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(121, 75, 255)),
    })
    accentGradient.Parent = accent

    local logo = Instance.new('TextLabel')
    logo.Name = 'Logo'
    logo.Size = UDim2.fromOffset(240, 34)
    logo.Position = UDim2.fromOffset(28, 24)
    logo.BackgroundTransparency = 1
    logo.Font = Enum.Font.GothamBold
    logo.Text = 'BADWARS'
    logo.TextSize = 26
    logo.TextColor3 = Color3.fromRGB(245, 249, 255)
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.ZIndex = 13
    logo.Parent = statusCard

    local edition = Instance.new('TextLabel')
    edition.Size = UDim2.fromOffset(260, 20)
    edition.Position = UDim2.fromOffset(29, 56)
    edition.BackgroundTransparency = 1
    edition.Font = Enum.Font.GothamMedium
    edition.Text = 'PREMIUM MODULE SYSTEM'
    edition.TextSize = 11
    edition.TextColor3 = Color3.fromRGB(104, 124, 150)
    edition.TextXAlignment = Enum.TextXAlignment.Left
    edition.ZIndex = 13
    edition.Parent = statusCard

    spinner = Instance.new('TextLabel')
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.Position = UDim2.new(1, -42, 0, 47)
    spinner.Size = UDim2.fromOffset(28, 28)
    spinner.BackgroundColor3 = Color3.fromRGB(20, 28, 39)
    spinner.BackgroundTransparency = 0.08
    spinner.Font = Enum.Font.GothamBold
    spinner.Text = '>'
    spinner.TextSize = 18
    spinner.TextColor3 = Color3.fromRGB(16, 213, 165)
    spinner.ZIndex = 13
    spinner.Parent = statusCard
    loaderCorner(spinner, 9)
    loaderStroke(spinner, Color3.fromRGB(57, 75, 96), 0.42, 1)

    stageLabel = Instance.new('TextLabel')
    stageLabel.Name = 'Stage'
    stageLabel.Size = UDim2.new(1, -56, 0, 24)
    stageLabel.Position = UDim2.fromOffset(28, 92)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Font = Enum.Font.GothamSemibold
    stageLabel.Text = 'INITIALIZING'
    stageLabel.TextSize = 13
    stageLabel.TextColor3 = Color3.fromRGB(235, 241, 250)
    stageLabel.TextXAlignment = Enum.TextXAlignment.Left
    stageLabel.ZIndex = 13
    stageLabel.Parent = statusCard

    statusLabel = Instance.new('TextLabel')
    statusLabel.Name = 'Status'
    statusLabel.Size = UDim2.new(1, -56, 0, 44)
    statusLabel.Position = UDim2.fromOffset(28, 116)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = 'Preparing the loader...'
    statusLabel.TextSize = 14
    statusLabel.TextWrapped = true
    statusLabel.TextColor3 = Color3.fromRGB(170, 184, 202)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.ZIndex = 13
    statusLabel.Parent = statusCard

    local progressTrack = Instance.new('Frame')
    progressTrack.Name = 'ProgressTrack'
    progressTrack.Size = UDim2.new(1, -96, 0, 8)
    progressTrack.Position = UDim2.fromOffset(28, 180)
    progressTrack.BackgroundColor3 = Color3.fromRGB(29, 39, 53)
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = 13
    progressTrack.Parent = statusCard
    loaderCorner(progressTrack, 99)
    loaderStroke(progressTrack, Color3.fromRGB(57, 75, 96), 0.65, 1)

    progressFill = Instance.new('Frame')
    progressFill.Name = 'Progress'
    progressFill.Size = UDim2.fromScale(0.02, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 14
    progressFill.Parent = progressTrack
    loaderCorner(progressFill, 99)
    local fillGradient = Instance.new('UIGradient')
    fillGradient.Color = accentGradient.Color
    fillGradient.Parent = progressFill

    progressGlow = Instance.new('Frame')
    progressGlow.AnchorPoint = Vector2.new(1, 0.5)
    progressGlow.Position = UDim2.fromScale(1, 0.5)
    progressGlow.Size = UDim2.fromOffset(16, 16)
    progressGlow.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    progressGlow.BackgroundTransparency = 0.52
    progressGlow.BorderSizePixel = 0
    progressGlow.ZIndex = 15
    progressGlow.Parent = progressFill
    loaderCorner(progressGlow, 99)

    percentLabel = Instance.new('TextLabel')
    percentLabel.Size = UDim2.fromOffset(58, 24)
    percentLabel.Position = UDim2.new(1, -74, 0, 171)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = Enum.Font.GothamSemibold
    percentLabel.Text = '2%'
    percentLabel.TextSize = 12
    percentLabel.TextColor3 = Color3.fromRGB(200, 211, 225)
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.ZIndex = 13
    percentLabel.Parent = statusCard

    detailLabel = Instance.new('TextLabel')
    detailLabel.Size = UDim2.new(1, -56, 0, 24)
    detailLabel.Position = UDim2.fromOffset(28, 205)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Font = Enum.Font.Code
    detailLabel.Text = 'secure initialization / waiting for pipeline'
    detailLabel.TextSize = 11
    detailLabel.TextColor3 = Color3.fromRGB(87, 105, 129)
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.ZIndex = 13
    detailLabel.Parent = statusCard

    task.spawn(function()
        while spinner and spinner.Parent do
            loaderTween(spinner, TweenInfo.new(0.34, Enum.EasingStyle.Linear), {Rotation = spinner.Rotation + 90})
            task.wait(0.34)
        end
    end)

    shared.BadStatusGui = statusGui
end

createPremiumLoader()

shared.BadStatus = function(msg, isErr)
    local message = tostring(msg or 'Working...')
    warn('BadWars: '..message)
    statusError = isErr == true
    statusProgress = math.max(statusProgress, resolveStatusProgress(message))

    if not statusGui or not statusGui.Parent then return end
    statusGui.Enabled = true

    local accentColor = statusError and Color3.fromRGB(255, 91, 104) or Color3.fromRGB(16, 213, 165)
    local upper = string.upper(message)
    if #upper > 34 then upper = string.sub(upper, 1, 34)..'...' end

    if stageLabel then
        stageLabel.Text = statusError and 'PIPELINE ERROR' or upper
        stageLabel.TextColor3 = statusError and Color3.fromRGB(255, 126, 136) or Color3.fromRGB(235, 241, 250)
    end
    if statusLabel then
        statusLabel.Text = message
        statusLabel.TextColor3 = statusError and Color3.fromRGB(255, 145, 153) or Color3.fromRGB(170, 184, 202)
    end
    if detailLabel then
        detailLabel.Text = statusError and 'review the reported stage before retrying' or 'downloading / validating / registering components'
    end
    if progressFill then
        progressFill.BackgroundColor3 = accentColor
        loaderTween(progressFill, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(math.clamp(statusProgress, 0.02, 1), 1),
        })
    end
    if progressGlow then progressGlow.BackgroundColor3 = accentColor end
    if spinner then spinner.TextColor3 = accentColor end
    if percentLabel then percentLabel.Text = tostring(math.floor(statusProgress * 100 + 0.5))..'%' end
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

-- Roblox update watch integration
local function watchRobloxUpdates()
  task.spawn(function()
    local badStatus=shared.BadStatus
    if type(badStatus)~='function' then return end
    while true do
      task.wait(300)
      local ok,res=pcall(function()
        local api='https://api.github.com/repos/evanbackup1256-ship-it/badwars/raw/main/badscript/profiles/roblox-version.txt'
        local httpService=cloneref(game:GetService('HttpService'))
        local body=httpService:GetAsync(api,true)
        return body
      end)
      if ok and type(res)=='string' and #res>0 then
        local success,currentVersion=pcall(function()
          return cloneref(game:GetService('HttpService')):JSONDecode(res or '{}')
        end)
        if success and type(currentVersion)=='table' then
          shared.BadWarsStatusApi=currentVersion
          if type(badStatus)=='function' then
            badStatus('Roblox update watch: '..tostring(currentVersion.status or 'ok'))
          end
        end
      end
    end
  end)
end
watchRobloxUpdates()
shared.BadWarsStatusApi={status='ok'}

-- Cache setup
setStatus('pipeline: cache setup')
for _,d in {'badscript','badscript/games','badscript/profiles','badscript/assets','badscript/libraries','badscript/guis'} do
	if not isfolder(d) then makefolder(d) end
end
local function wipeAny(p) if isfolder(p) then for _,f in listfiles(p) do if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end end end end
local function wipeGen(p) if isfolder(p) then for _,f in listfiles(p) do if f:find('loader') then continue end;if isfolder(f) then wipeGen(f) end;if isfile(f) then local c=readfile(f);if type(c)=='string' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) then delfile(f) end end end end end

local cacheVersion = 'badwars-premium-stability-2026-07-04-07'
local cacheFile = 'badscript/profiles/cache-version.txt'
if (isfile(cacheFile) and readfile(cacheFile) or '') ~= cacheVersion then
	setStatus('cache cleared (version mismatch)')
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua'} do if isfile(f) then delfile(f) end end
	wipeAny('badscript/assets');wipeGen('badscript/games');wipeGen('badscript/guis');wipeGen('badscript/libraries')
	writefile(cacheFile,cacheVersion)
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
	local m='ERROR empty file: Empty response for '..ORCH_PATH
	setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
if isNotFoundBody(raw) then
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
warn('BadWars: '..final) setStatus(final,#issues>0) if statusCard and #issues == 0 then task.wait(0.22) loaderTween(statusCard,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{BackgroundTransparency=1}) task.delay(0.22,function() if statusGui then statusGui:Destroy() end end) end return result
