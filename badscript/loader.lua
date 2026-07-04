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

-- Status GUI (Premium v7)
local statusGui
local statusCard
local statusLabel
local stageLabel
local detailLabel
local percentLabel
local progressFill
local progressGlow
local spinner
local chipFrames = {}
local shimmer
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
        {'cache', 0.08}, {'self-test', 0.16}, {'validating orchestrator', 0.22}, {'downloading', 0.3}, {'loading premium interface', 0.48}, {'interface ready', 0.58}, {'loading core modules', 0.72}, {'game module', 0.84}, {'loading profile', 0.92}, {'finalizing', 0.97}, {'ready', 1},
    }
    for _, stage in ipairs(stages) do
        if string.find(lower, stage[1], 1, true) then return stage[2] end
    end
    return math.min(math.max(statusProgress + 0.012, 0.02), 0.98)
end

local function updateChips()
    local labels = {'BOOT', 'MODULES', 'PROFILE'}
    local thresholds = {0.24, 0.78, 0.94}
    for index, frame in ipairs(chipFrames) do
        local active = statusProgress >= thresholds[index] and not statusError
        frame.BackgroundTransparency = active and 0.12 or 0.84
        frame.BackgroundColor3 = active and Color3.fromRGB(16, 213, 165) or Color3.fromRGB(30, 39, 53)
        local text = frame:FindFirstChild('Label')
        if text then
            text.Text = labels[index]
            text.TextColor3 = active and Color3.fromRGB(7, 14, 20) or Color3.fromRGB(122, 140, 164)
        end
    end
end

local function createPremiumLoader()
    pcall(function()
        local old = shared.BadStatusGui
        if old and typeof(old) == 'Instance' then old:Destroy() end
    end)

    local parent
    pcall(function() if type(gethui) == 'function' then parent = gethui() end end)
    if not parent then pcall(function() parent = cloneref(game:GetService('CoreGui')) end) end
    if not parent then pcall(function() parent = cloneref(game:GetService('Players')).LocalPlayer.PlayerGui end) end
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
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(2, 6, 10)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.Parent = statusGui
    loaderTween(backdrop, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.28})

    statusCard = Instance.new('Frame')
    statusCard.Name = 'PremiumLoader'
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.5)
    statusCard.Size = UDim2.fromOffset(520, 286)
    statusCard.BackgroundColor3 = Color3.fromRGB(9, 14, 21)
    statusCard.BorderSizePixel = 0
    statusCard.ClipsDescendants = true
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 18)
    loaderStroke(statusCard, Color3.fromRGB(54, 72, 94), 0.2, 1)

    local cardScale = Instance.new('UIScale')
    cardScale.Scale = 0.94
    cardScale.Parent = statusCard
    loaderTween(cardScale, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})

    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 28, 40)),
        ColorSequenceKeypoint.new(0.54, Color3.fromRGB(10, 15, 23)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 10, 16)),
    })
    gradient.Rotation = 90
    gradient.Parent = statusCard

    local accent = Instance.new('Frame')
    accent.Size = UDim2.new(1, -28, 0, 2)
    accent.Position = UDim2.fromOffset(14, 1)
    accent.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    accent.BorderSizePixel = 0
    accent.Parent = statusCard
    loaderCorner(accent, 99)
    local accentGradient = Instance.new('UIGradient')
    accentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 128, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(16, 213, 165)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(115, 78, 255)),
    })
    accentGradient.Parent = accent

    local logo = Instance.new('TextLabel')
    logo.Size = UDim2.fromOffset(250, 34)
    logo.Position = UDim2.fromOffset(28, 26)
    logo.BackgroundTransparency = 1
    logo.Font = Enum.Font.GothamBold
    logo.Text = 'BADWARS V1'
    logo.TextSize = 26
    logo.TextColor3 = Color3.fromRGB(245, 249, 255)
    logo.TextXAlignment = Enum.TextXAlignment.Left
    logo.Parent = statusCard

    local edition = Instance.new('TextLabel')
    edition.Size = UDim2.fromOffset(280, 20)
    edition.Position = UDim2.fromOffset(29, 57)
    edition.BackgroundTransparency = 1
    edition.Font = Enum.Font.GothamMedium
    edition.Text = 'PREMIUM LAUNCH SYSTEM'
    edition.TextSize = 11
    edition.TextColor3 = Color3.fromRGB(102, 122, 147)
    edition.TextXAlignment = Enum.TextXAlignment.Left
    edition.Parent = statusCard

    spinner = Instance.new('TextLabel')
    spinner.AnchorPoint = Vector2.new(0.5, 0.5)
    spinner.Position = UDim2.new(1, -44, 0, 47)
    spinner.Size = UDim2.fromOffset(30, 30)
    spinner.BackgroundColor3 = Color3.fromRGB(20, 28, 39)
    spinner.BackgroundTransparency = 0.06
    spinner.Font = Enum.Font.GothamBold
    spinner.Text = '>'
    spinner.TextSize = 18
    spinner.TextColor3 = Color3.fromRGB(16, 213, 165)
    spinner.Parent = statusCard
    loaderCorner(spinner, 10)
    loaderStroke(spinner, Color3.fromRGB(56, 73, 95), 0.42, 1)

    local chipHolder = Instance.new('Frame')
    chipHolder.Size = UDim2.new(1, -56, 0, 26)
    chipHolder.Position = UDim2.fromOffset(28, 86)
    chipHolder.BackgroundTransparency = 1
    chipHolder.Parent = statusCard
    local chipLayout = Instance.new('UIListLayout')
    chipLayout.FillDirection = Enum.FillDirection.Horizontal
    chipLayout.Padding = UDim.new(0, 8)
    chipLayout.Parent = chipHolder

    for _, label in ipairs({'BOOT', 'MODULES', 'PROFILE'}) do
        local chip = Instance.new('Frame')
        chip.Size = UDim2.fromOffset(78, 24)
        chip.BackgroundColor3 = Color3.fromRGB(30, 39, 53)
        chip.BackgroundTransparency = 0.84
        chip.BorderSizePixel = 0
        chip.Parent = chipHolder
        loaderCorner(chip, 999)
        loaderStroke(chip, Color3.fromRGB(55, 72, 92), 0.72, 1)
        local txt = Instance.new('TextLabel')
        txt.Name = 'Label'
        txt.Size = UDim2.fromScale(1, 1)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamSemibold
        txt.Text = label
        txt.TextSize = 10
        txt.TextColor3 = Color3.fromRGB(122, 140, 164)
        txt.Parent = chip
        table.insert(chipFrames, chip)
    end

    stageLabel = Instance.new('TextLabel')
    stageLabel.Size = UDim2.new(1, -56, 0, 24)
    stageLabel.Position = UDim2.fromOffset(28, 124)
    stageLabel.BackgroundTransparency = 1
    stageLabel.Font = Enum.Font.GothamSemibold
    stageLabel.Text = 'INITIALIZING'
    stageLabel.TextSize = 13
    stageLabel.TextColor3 = Color3.fromRGB(235, 241, 250)
    stageLabel.TextXAlignment = Enum.TextXAlignment.Left
    stageLabel.Parent = statusCard

    statusLabel = Instance.new('TextLabel')
    statusLabel.Size = UDim2.new(1, -56, 0, 48)
    statusLabel.Position = UDim2.fromOffset(28, 149)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = 'Preparing your premium BadWars session...'
    statusLabel.TextSize = 14
    statusLabel.TextWrapped = true
    statusLabel.TextColor3 = Color3.fromRGB(170, 184, 202)
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.Parent = statusCard

    local progressTrack = Instance.new('Frame')
    progressTrack.Size = UDim2.new(1, -96, 0, 10)
    progressTrack.Position = UDim2.fromOffset(28, 220)
    progressTrack.BackgroundColor3 = Color3.fromRGB(26, 36, 49)
    progressTrack.BorderSizePixel = 0
    progressTrack.Parent = statusCard
    loaderCorner(progressTrack, 999)
    loaderStroke(progressTrack, Color3.fromRGB(56, 73, 95), 0.68, 1)

    progressFill = Instance.new('Frame')
    progressFill.Size = UDim2.fromScale(0.02, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = progressTrack
    loaderCorner(progressFill, 999)
    local fillGradient = Instance.new('UIGradient')
    fillGradient.Color = accentGradient.Color
    fillGradient.Parent = progressFill

    shimmer = Instance.new('Frame')
    shimmer.Size = UDim2.fromOffset(60, 20)
    shimmer.Position = UDim2.fromOffset(-80, -5)
    shimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shimmer.BackgroundTransparency = 0.78
    shimmer.BorderSizePixel = 0
    shimmer.Parent = progressFill
    local shimmerGradient = Instance.new('UIGradient')
    shimmerGradient.Rotation = 24
    shimmerGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1, 1),
    })
    shimmerGradient.Parent = shimmer
    loaderCorner(shimmer, 999)

    progressGlow = Instance.new('Frame')
    progressGlow.AnchorPoint = Vector2.new(1, 0.5)
    progressGlow.Position = UDim2.fromScale(1, 0.5)
    progressGlow.Size = UDim2.fromOffset(16, 16)
    progressGlow.BackgroundColor3 = Color3.fromRGB(16, 213, 165)
    progressGlow.BackgroundTransparency = 0.54
    progressGlow.BorderSizePixel = 0
    progressGlow.Parent = progressFill
    loaderCorner(progressGlow, 99)

    percentLabel = Instance.new('TextLabel')
    percentLabel.Size = UDim2.fromOffset(58, 24)
    percentLabel.Position = UDim2.new(1, -74, 0, 211)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Font = Enum.Font.GothamSemibold
    percentLabel.Text = '2%'
    percentLabel.TextSize = 12
    percentLabel.TextColor3 = Color3.fromRGB(200, 211, 225)
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = statusCard

    detailLabel = Instance.new('TextLabel')
    detailLabel.Size = UDim2.new(1, -56, 0, 24)
    detailLabel.Position = UDim2.fromOffset(28, 244)
    detailLabel.BackgroundTransparency = 1
    detailLabel.Font = Enum.Font.Code
    detailLabel.Text = 'secure launch / polished UI / minimal logging'
    detailLabel.TextSize = 11
    detailLabel.TextColor3 = Color3.fromRGB(87, 105, 129)
    detailLabel.TextXAlignment = Enum.TextXAlignment.Left
    detailLabel.Parent = statusCard

    task.spawn(function()
        while spinner and spinner.Parent do
            loaderTween(spinner, TweenInfo.new(0.34, Enum.EasingStyle.Linear), {Rotation = spinner.Rotation + 90})
            task.wait(0.34)
        end
    end)

    task.spawn(function()
        while shimmer and shimmer.Parent do
            shimmer.Position = UDim2.fromOffset(-80, -5)
            loaderTween(shimmer, TweenInfo.new(0.72, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 20, 0, -5)})
            task.wait(0.86)
        end
    end)

    shared.BadStatusGui = statusGui
    updateChips()
end

createPremiumLoader()

shared.BadStatus = function(msg, isErr)
    local message = tostring(msg or 'Working...')
    statusError = isErr == true
    statusProgress = math.max(statusProgress, resolveStatusProgress(message))

    if not statusGui or not statusGui.Parent then return end
    statusGui.Enabled = true

    local accentColor = statusError and Color3.fromRGB(255, 91, 104) or Color3.fromRGB(16, 213, 165)
    local upper = string.upper(message)
    if #upper > 34 then upper = string.sub(upper, 1, 34) .. '...' end

    if stageLabel then
        stageLabel.Text = statusError and 'PIPELINE ERROR' or upper
        stageLabel.TextColor3 = statusError and Color3.fromRGB(255, 126, 136) or Color3.fromRGB(235, 241, 250)
    end
    if statusLabel then
        statusLabel.Text = message
        statusLabel.TextColor3 = statusError and Color3.fromRGB(255, 145, 153) or Color3.fromRGB(170, 184, 202)
    end
    if detailLabel then
        detailLabel.Text = statusError and 'review the failing stage, then retry' or 'secure launch / premium UI / minimal logging'
    end
    if progressFill then
        progressFill.BackgroundColor3 = accentColor
        loaderTween(progressFill, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(math.clamp(statusProgress, 0.02, 1), 1),
        })
    end
    if progressGlow then progressGlow.BackgroundColor3 = accentColor end
    if spinner then spinner.TextColor3 = accentColor end
    if percentLabel then percentLabel.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. '%' end
    updateChips()

    if statusProgress >= 1 and not statusError and statusGui and statusGui.Parent then
        task.delay(0.35, function()
            if statusCard and statusCard.Parent then
                loaderTween(statusCard, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {BackgroundTransparency = 1})
            end
            task.delay(0.3, function()
                pcall(function()
                    if statusGui then statusGui:Destroy() end
                end)
            end)
        end)
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
