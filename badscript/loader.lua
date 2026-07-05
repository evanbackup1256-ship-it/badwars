-- BADWARS_DIAGNOSTICS_BOOTSTRAP_BEGIN
do
    shared = type(shared) == "table" and shared or {}
    shared.__badwars_diagnostic_buffer = type(shared.__badwars_diagnostic_buffer) == "table"
        and shared.__badwars_diagnostic_buffer
        or {}

    local function __badwarsBuffer(level, message, context)
        context = type(context) == "table" and context or {}
        table.insert(shared.__badwars_diagnostic_buffer, {
            severity = level or "ERROR",
            message = tostring(message),
            traceback = context.traceback,
            subsystem = context.subsystem or "Bootstrap",
            module = context.module,
            file = context.file,
            stage = context.stage or "bootstrap",
            fatal = context.fatal == true,
            caught = context.caught ~= false,
            native = context.native ~= false,
        })
    end

    local function __badwarsLoadDiagnostics()
        if type(shared.BadDiagnostics) == "table" then
            return shared.BadDiagnostics
        end

        local source
        local sourceName = "badscript/libraries/diagnostics.lua"

        if type(isfile) == "function" and type(readfile) == "function" then
            local ok, present = pcall(isfile, sourceName)
            if ok and present then
                local readOk, contents = pcall(readfile, sourceName)
                if readOk and type(contents) == "string" and contents ~= "" then
                    source = contents
                elseif not readOk then
                    __badwarsBuffer("WARN", contents, {
                        subsystem = "BootstrapFilesystem",
                        file = sourceName,
                    })
                end
            end
        end

        if not source then
            local urls = {
                "https://github.com/evanbackup1256-ship-it/badwars/raw/main/badscript/libraries/diagnostics.lua",
                "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/libraries/diagnostics.lua",
            }
            for _, url in ipairs(urls) do
                local ok, result = pcall(function()
                    local fn = game and game.HttpGet
                    if type(fn) == "function" then
                        return fn(game, url, true)
                    end
                    local service = game:GetService("HttpService")
                    return service:GetAsync(url, true)
                end)
                if ok and type(result) == "string" and result ~= "" and result ~= "404: Not Found" then
                    source = result
                    sourceName = url
                    break
                elseif not ok then
                    __badwarsBuffer("WARN", result, {
                        subsystem = "BootstrapHTTP",
                        file = url,
                    })
                end
            end
        end

        if type(source) ~= "string" or source == "" then
            __badwarsBuffer("ERROR", "Unable to load diagnostics.lua", {
                subsystem = "Bootstrap",
                file = sourceName,
                fatal = false,
            })
            return nil
        end

        local env = getgenv and type(getgenv) == "function" and getgenv() or nil
        local compiler = (env and env.loadstring) or loadstring
        if type(compiler) ~= "function" then
            __badwarsBuffer("ERROR", "loadstring unavailable while loading diagnostics", {
                subsystem = "BootstrapCompiler",
                file = sourceName,
                fatal = true,
            })
            return nil
        end

        local fn, compileError = compiler(source, "@badscript/libraries/diagnostics.lua")
        if not fn then
            __badwarsBuffer("FATAL", compileError, {
                subsystem = "BootstrapCompiler",
                file = sourceName,
                fatal = true,
            })
            return nil
        end

        local ok, result = xpcall(fn, function(err)
            if debug and type(debug.traceback) == "function" then
                return debug.traceback(tostring(err), 2)
            end
            return tostring(err)
        end)
        if not ok then
            __badwarsBuffer("FATAL", result, {
                subsystem = "BootstrapRuntime",
                file = sourceName,
                traceback = result,
                fatal = true,
            })
            return nil
        end
        return result
    end

    __badwarsLoadDiagnostics()
end
-- BADWARS_DIAGNOSTICS_BOOTSTRAP_END-- BadWars Loader v6.1
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

-- BADWARS_LOADER_PRESENTATION_V1_BEGIN
-- Status GUI: restrained application-style loader.
local statusGui
local statusCard
local statusBackdrop
local statusTitle
local statusMessage
local statusMeta
local progressFill
local progressValue
local elapsedLabel
local stateDot
local openConsoleButton

local statusProgress = 0.03
local statusError = false
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local loaderDismissScheduled = false
local MINIMUM_VISIBLE_SECONDS = 1.2

local loaderTweenService = cloneref(game:GetService("TweenService"))

local function loaderTween(object, info, properties)
    if not object or not object.Parent then
        return nil
    end

    local ok, tween = pcall(function()
        return loaderTweenService:Create(object, info, properties)
    end)

    if ok and tween then
        tween:Play()
        return tween
    end

    for property, value in pairs(properties) do
        pcall(function()
            object[property] = value
        end)
    end
end

local function loaderCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function loaderStroke(parent, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function isTerminalStatus(message)
    local lower = string.lower(tostring(message or ""))
    return lower == "ready"
        or string.sub(lower, 1, 7) == "ready -"
        or string.find(lower, "launch complete", 1, true) ~= nil
end

local function resolveStatusProgress(message)
    local lower = string.lower(tostring(message or ""))

    if isTerminalStatus(lower) then
        return 1
    end

    local stages = {
        { "cache", 0.12 },
        { "self-test", 0.2 },
        { "validating", 0.28 },
        { "downloading", 0.36 },
        { "interface", 0.55 },
        { "core modules", 0.7 },
        { "universal", 0.78 },
        { "game module", 0.86 },
        { "profile", 0.93 },
        { "finalizing", 0.97 },
    }

    for _, stage in ipairs(stages) do
        if string.find(lower, stage[1], 1, true) then
            return stage[2]
        end
    end

    return math.min(statusProgress + 0.025, 0.98)
end

local function friendlyStage(message)
    local text = tostring(message or "Working")
    text = text:gsub("^pipeline:%s*", "")
    text = text:gsub("^loading%s+", "Loading ")
    text = text:gsub("^downloading%s+", "Downloading ")
    text = text:gsub("^validating%s+", "Checking ")
    text = text:gsub("^finalizing%s*", "Finishing")
    return text
end

local function getLoaderParent()
    local parent

    pcall(function()
        if type(gethui) == "function" then
            parent = gethui()
        end
    end)

    if not parent then
        pcall(function()
            parent = cloneref(game:GetService("CoreGui"))
        end)
    end

    if not parent then
        pcall(function()
            parent = cloneref(game:GetService("Players")).LocalPlayer.PlayerGui
        end)
    end

    return parent
end

local function createLoader()
    pcall(function()
        if shared.BadStatusGui and typeof(shared.BadStatusGui) == "Instance" then
            shared.BadStatusGui:Destroy()
        end
    end)

    local parent = getLoaderParent()
    if not parent then
        return
    end

    pcall(function()
        local old = parent:FindFirstChild("BadWarsLoaderStatus")
        if old then
            old:Destroy()
        end
    end)

    statusGui = Instance.new("ScreenGui")
    statusGui.Name = "BadWarsLoaderStatus"
    statusGui.DisplayOrder = 10000000
    statusGui.IgnoreGuiInset = true
    statusGui.ResetOnSpawn = false
    statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    statusGui.Parent = parent

    statusBackdrop = Instance.new("Frame")
    statusBackdrop.Size = UDim2.fromScale(1, 1)
    statusBackdrop.BackgroundColor3 = Color3.fromRGB(4, 5, 7)
    statusBackdrop.BackgroundTransparency = 1
    statusBackdrop.BorderSizePixel = 0
    statusBackdrop.Parent = statusGui

    statusCard = Instance.new("Frame")
    statusCard.Name = "Loader"
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.505)
    statusCard.Size = UDim2.fromOffset(430, 184)
    statusCard.BackgroundColor3 = Color3.fromRGB(15, 17, 21)
    statusCard.BackgroundTransparency = 1
    statusCard.BorderSizePixel = 0
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 8)
    loaderStroke(statusCard, Color3.fromRGB(51, 55, 64), 0.28)

    local scale = Instance.new("UIScale")
    scale.Name = "OpenScale"
    scale.Scale = 0.98
    scale.Parent = statusCard

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 48)
    header.BackgroundColor3 = Color3.fromRGB(18, 20, 25)
    header.BorderSizePixel = 0
    header.Parent = statusCard

    local headerLine = Instance.new("Frame")
    headerLine.AnchorPoint = Vector2.new(0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, 0)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.BackgroundColor3 = Color3.fromRGB(44, 47, 55)
    headerLine.BackgroundTransparency = 0.35
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header

    local brand = Instance.new("TextLabel")
    brand.Position = UDim2.fromOffset(18, 0)
    brand.Size = UDim2.new(1, -110, 1, 0)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamSemibold
    brand.Text = "BadWars"
    brand.TextSize = 15
    brand.TextColor3 = Color3.fromRGB(237, 239, 243)
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Parent = header

    local loaderLabel = Instance.new("TextLabel")
    loaderLabel.AnchorPoint = Vector2.new(1, 0.5)
    loaderLabel.Position = UDim2.new(1, -18, 0.5, 0)
    loaderLabel.Size = UDim2.fromOffset(70, 20)
    loaderLabel.BackgroundTransparency = 1
    loaderLabel.Font = Enum.Font.Code
    loaderLabel.Text = "loader"
    loaderLabel.TextSize = 10
    loaderLabel.TextColor3 = Color3.fromRGB(104, 110, 122)
    loaderLabel.TextXAlignment = Enum.TextXAlignment.Right
    loaderLabel.Parent = header

    stateDot = Instance.new("Frame")
    stateDot.Position = UDim2.fromOffset(18, 67)
    stateDot.Size = UDim2.fromOffset(7, 7)
    stateDot.BackgroundColor3 = Color3.fromRGB(70, 196, 150)
    stateDot.BorderSizePixel = 0
    stateDot.Parent = statusCard
    loaderCorner(stateDot, 99)

    statusTitle = Instance.new("TextLabel")
    statusTitle.Position = UDim2.fromOffset(34, 58)
    statusTitle.Size = UDim2.new(1, -52, 0, 24)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Font = Enum.Font.GothamMedium
    statusTitle.Text = "Starting"
    statusTitle.TextSize = 14
    statusTitle.TextColor3 = Color3.fromRGB(217, 220, 226)
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.TextTruncate = Enum.TextTruncate.AtEnd
    statusTitle.Parent = statusCard

    statusMessage = Instance.new("TextLabel")
    statusMessage.Position = UDim2.fromOffset(18, 86)
    statusMessage.Size = UDim2.new(1, -36, 0, 32)
    statusMessage.BackgroundTransparency = 1
    statusMessage.Font = Enum.Font.Code
    statusMessage.Text = "Preparing loader"
    statusMessage.TextSize = 10
    statusMessage.TextColor3 = Color3.fromRGB(111, 117, 129)
    statusMessage.TextXAlignment = Enum.TextXAlignment.Left
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextWrapped = true
    statusMessage.Parent = statusCard

    local track = Instance.new("Frame")
    track.Position = UDim2.fromOffset(18, 132)
    track.Size = UDim2.new(1, -70, 0, 4)
    track.BackgroundColor3 = Color3.fromRGB(34, 37, 44)
    track.BorderSizePixel = 0
    track.Parent = statusCard
    loaderCorner(track, 99)

    progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.fromScale(statusProgress, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(70, 196, 150)
    progressFill.BorderSizePixel = 0
    progressFill.Parent = track
    loaderCorner(progressFill, 99)

    progressValue = Instance.new("TextLabel")
    progressValue.AnchorPoint = Vector2.new(1, 0.5)
    progressValue.Position = UDim2.new(1, -18, 0, 134)
    progressValue.Size = UDim2.fromOffset(42, 18)
    progressValue.BackgroundTransparency = 1
    progressValue.Font = Enum.Font.Code
    progressValue.Text = "3%"
    progressValue.TextSize = 10
    progressValue.TextColor3 = Color3.fromRGB(128, 134, 146)
    progressValue.TextXAlignment = Enum.TextXAlignment.Right
    progressValue.Parent = statusCard

    statusMeta = Instance.new("TextLabel")
    statusMeta.Position = UDim2.fromOffset(18, 151)
    statusMeta.Size = UDim2.new(1, -118, 0, 18)
    statusMeta.BackgroundTransparency = 1
    statusMeta.Font = Enum.Font.Code
    statusMeta.Text = "bootstrap"
    statusMeta.TextSize = 10
    statusMeta.TextColor3 = Color3.fromRGB(89, 95, 106)
    statusMeta.TextXAlignment = Enum.TextXAlignment.Left
    statusMeta.TextTruncate = Enum.TextTruncate.AtEnd
    statusMeta.Parent = statusCard

    elapsedLabel = Instance.new("TextLabel")
    elapsedLabel.AnchorPoint = Vector2.new(1, 0)
    elapsedLabel.Position = UDim2.new(1, -18, 0, 151)
    elapsedLabel.Size = UDim2.fromOffset(82, 18)
    elapsedLabel.BackgroundTransparency = 1
    elapsedLabel.Font = Enum.Font.Code
    elapsedLabel.Text = "0.0s"
    elapsedLabel.TextSize = 10
    elapsedLabel.TextColor3 = Color3.fromRGB(89, 95, 106)
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right
    elapsedLabel.Parent = statusCard

    openConsoleButton = Instance.new("TextButton")
    openConsoleButton.AnchorPoint = Vector2.new(1, 1)
    openConsoleButton.Position = UDim2.new(1, -18, 1, -13)
    openConsoleButton.Size = UDim2.fromOffset(92, 26)
    openConsoleButton.BackgroundColor3 = Color3.fromRGB(28, 30, 36)
    openConsoleButton.BackgroundTransparency = 0.04
    openConsoleButton.BorderSizePixel = 0
    openConsoleButton.AutoButtonColor = false
    openConsoleButton.Font = Enum.Font.GothamMedium
    openConsoleButton.Text = "Open console"
    openConsoleButton.TextSize = 10
    openConsoleButton.TextColor3 = Color3.fromRGB(203, 207, 214)
    openConsoleButton.Visible = false
    openConsoleButton.Parent = statusCard
    loaderCorner(openConsoleButton, 5)
    loaderStroke(openConsoleButton, Color3.fromRGB(64, 68, 78), 0.42)

    openConsoleButton.Activated:Connect(function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    loaderTween(
        statusBackdrop,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.32 }
    )
    loaderTween(
        statusCard,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {
            BackgroundTransparency = 0,
            Position = UDim2.fromScale(0.5, 0.5),
        }
    )
    loaderTween(
        scale,
        TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Scale = 1 }
    )

    task.spawn(function()
        while statusGui and statusGui.Parent do
            if elapsedLabel then
                elapsedLabel.Text = string.format("%.1fs", os.clock() - loaderCreatedAt)
            end
            task.wait(0.1)
        end
    end)

    shared.BadStatusGui = statusGui
end

createLoader()

shared.BadStatus = function(msg, isErr)
    local message = tostring(msg or "Working")
    local terminal = isTerminalStatus(message)

    loaderStatusGeneration += 1
    local generation = loaderStatusGeneration

    statusError = isErr == true
    loaderDismissScheduled = false

    if terminal and not statusError then
        statusProgress = 1
    else
        statusProgress = math.max(statusProgress, resolveStatusProgress(message))
    end

    if not statusGui or not statusGui.Parent then
        return
    end

    statusGui.Enabled = true

    local accent = statusError
        and Color3.fromRGB(239, 105, 116)
        or Color3.fromRGB(70, 196, 150)

    if statusTitle then
        statusTitle.Text = statusError and "Loading failed" or friendlyStage(message)
        statusTitle.TextColor3 = statusError
            and Color3.fromRGB(239, 122, 132)
            or Color3.fromRGB(217, 220, 226)
    end

    if statusMessage then
        statusMessage.Text = message
        statusMessage.TextColor3 = statusError
            and Color3.fromRGB(211, 137, 144)
            or Color3.fromRGB(111, 117, 129)
    end

    if statusMeta then
        statusMeta.Text = statusError and "The loader is paused at this step" or "startup"
    end

    if stateDot then
        stateDot.BackgroundColor3 = accent
    end

    if progressFill then
        progressFill.BackgroundColor3 = accent
        loaderTween(
            progressFill,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.fromScale(math.clamp(statusProgress, 0.03, 1), 1) }
        )
    end

    if progressValue then
        progressValue.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
    end

    if openConsoleButton then
        openConsoleButton.Visible = statusError
    end

    if statusError then
        return
    end

    if terminal then
        loaderDismissScheduled = true

        if statusTitle then
            statusTitle.Text = "Ready"
        end

        if statusMessage then
            statusMessage.Text = "BadWars finished loading."
        end

        local visibleFor = os.clock() - loaderCreatedAt
        local hold = math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.28

        task.delay(hold, function()
            if generation ~= loaderStatusGeneration
                or statusError
                or not statusGui
                or not statusGui.Parent
            then
                loaderDismissScheduled = false
                return
            end

            loaderTween(
                statusCard,
                TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {
                    BackgroundTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.492),
                }
            )
            loaderTween(
                statusBackdrop,
                TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { BackgroundTransparency = 1 }
            )

            task.delay(0.2, function()
                if generation == loaderStatusGeneration and statusGui and statusGui.Parent then
                    statusGui:Destroy()
                end
            end)
        end)
    end
end

local setStatus = shared.BadStatus
setStatus("pipeline: ready")
-- BADWARS_LOADER_PRESENTATION_V1_END
-- Error tracking
local __rtErrs=shared.__badwars_runtime_errors
if type(__rtErrs)~='table' then __rtErrs={};shared.__badwars_runtime_errors=__rtErrs end
local function recordErr(mod,msg) local trace=shared.BadDiagnostics and shared.BadDiagnostics:Traceback(msg,3) or tostring(msg) table.insert(__rtErrs,{module=tostring(mod),error=tostring(msg),traceback=trace,time=os.clock()}) if shared.BadDiagnostics then shared.BadDiagnostics:RecordRuntime(mod,msg,{subsystem='Loader',file='badscript/loader.lua',traceback=trace}) else warn('BadWars: [ERROR] '..tostring(mod)..': '..tostring(msg)) end end

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

local cacheVersion = 'badwars-site-runtime-overhaul-2026-07-05-01'
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
local ok,result=xpcall(fn,function(err) local d=shared.BadDiagnostics return d and d:Traceback(err,2) or ((debug and debug.traceback) and debug.traceback(tostring(err),2) or tostring(err)) end)
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
 setStatus(final,#issues>0) if statusCard and #issues == 0 and not shared.__badwars_fatal_error then task.wait(0.22) loaderTween(statusCard,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{BackgroundTransparency=1}) task.delay(0.22,function() if statusGui then statusGui:Destroy() end end) end return result
