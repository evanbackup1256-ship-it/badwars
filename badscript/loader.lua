-- BADWARS_UI_V13_PREMIUM_OVERHAUL
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
-- BADWARS_DIAGNOSTICS_BOOTSTRAP_END
-- BadWars Loader v19.0 Obsidian Overhaul
-- Dual-format URL fallback + all diagnostics

local loaderStart=os.clock()

-- Polyfills
isfile=isfile or function(f)local s,r=pcall(readfile,f)return s and r~=nil and r~=''end
local __nativeDelfile=type(delfile)=='function'
delfile=delfile or function()return false,'delfile unavailable'end
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
    local query='?bwui=v19-ui-repair-5-2'
    return {
        'https://github.com/'..repo..'/raw/'..CFG.branch..'/'..p..query,
        'https://raw.githubusercontent.com/'..repo..'/'..CFG.branch..'/'..p..query
    }
end
local ORCH_PATH=CFG.folder..'/'..CFG.file

-- httpGet: tries all URLs, returns (content, used_url)
local function callWithTimeout(callback, timeout)
	local done=false
	local ok=false
	local result
	task.spawn(function()
		ok,result=pcall(callback)
		done=true
	end)
	local started=os.clock()
	while not done and os.clock()-started<(timeout or 12) do
		task.wait(0.03)
	end
	if not done then
		return false,'timeout'
	end
	return ok,result
end

local function httpGet(urls)
	for _,url in ipairs(urls) do
		local fn=(game and game.HttpGet)
		if type(fn)~='function' then
			local env=getgenv and type(getgenv)=='function' and getgenv()
			fn=env and env.HttpGet
		end
		if type(fn)=='function' then
			local ok,res=callWithTimeout(function()return fn(game,url,true)end,12)
			if ok and type(res)=='string' and #res>0 then return res,url end
		end
		local ok,res=callWithTimeout(function()
			return cloneref(game:GetService('HttpService')):GetAsync(url,true)
		end,12)
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
local statusCardScale

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
    statusBackdrop.Name = "Backdrop"
    statusBackdrop.Size = UDim2.fromScale(1, 1)
    statusBackdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 12) -- match WindUI dark
    statusBackdrop.BackgroundTransparency = 0.45
    statusBackdrop.BorderSizePixel = 0
    statusBackdrop.Parent = statusGui

    local loaderViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local loaderWidth = math.clamp(loaderViewport.X - 28, 344, 504)

    statusCard = Instance.new("CanvasGroup")
    statusCard.Name = "Loader"
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.505)
    statusCard.Size = UDim2.fromOffset(loaderWidth, 232)
    statusCard.BackgroundColor3 = Color3.fromRGB(16, 16, 16) -- WindUI Dark Background
    statusCard.BackgroundTransparency = 0.02
    statusCard.BorderSizePixel = 0
    statusCard.GroupTransparency = 1
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 14)
    loaderStroke(statusCard, Color3.fromRGB(40, 40, 45), 0.25)

    statusCardScale = Instance.new("UIScale")
    statusCardScale.Name = "MotionScale"
    statusCardScale.Scale = 0.975
    statusCardScale.Parent = statusCard

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Position = UDim2.fromOffset(18, 18)
    accent.Size = UDim2.fromOffset(4, 36)
    accent.BackgroundColor3 = Color3.fromRGB(255, 51, 85) -- BadWars red accent to match WindUI branding
    accent.BorderSizePixel = 0
    accent.Parent = statusCard
    loaderCorner(accent, 99)

    local brand = Instance.new("TextLabel")
    brand.Position = UDim2.fromOffset(34, 16)
    brand.Size = UDim2.new(1, -92, 0, 24)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamBold
    brand.Text = "BadWars"
    brand.TextSize = 18
    brand.TextColor3 = Color3.fromRGB(244, 247, 250)
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.Parent = statusCard

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(34, 38)
    subtitle.Size = UDim2.new(1, -92, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "Preparing your control center"
    subtitle.TextSize = 10
    subtitle.TextColor3 = Color3.fromRGB(116, 130, 145)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = statusCard

    stateDot = Instance.new("Frame")
    stateDot.Name = "State"
    stateDot.AnchorPoint = Vector2.new(1, 0.5)
    stateDot.Position = UDim2.new(1, -20, 0, 35)
    stateDot.Size = UDim2.fromOffset(8, 8)
    stateDot.BackgroundColor3 = Color3.fromRGB(66, 214, 153)
    stateDot.BorderSizePixel = 0
    stateDot.Parent = statusCard
    loaderCorner(stateDot, 99)

    local divider = Instance.new("Frame")
    divider.Position = UDim2.fromOffset(18, 68)
    divider.Size = UDim2.new(1, -36, 0, 1)
    divider.BackgroundColor3 = Color3.fromRGB(43, 54, 65)
    divider.BackgroundTransparency = 0.45
    divider.BorderSizePixel = 0
    divider.Parent = statusCard

    statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "Stage"
    statusTitle.Position = UDim2.fromOffset(18, 84)
    statusTitle.Size = UDim2.new(1, -36, 0, 25)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Font = Enum.Font.GothamSemibold
    statusTitle.Text = "Starting"
    statusTitle.TextSize = 15
    statusTitle.TextColor3 = Color3.fromRGB(226, 232, 238)
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.TextTruncate = Enum.TextTruncate.AtEnd
    statusTitle.Parent = statusCard

    statusMessage = Instance.new("TextLabel")
    statusMessage.Name = "Detail"
    statusMessage.Position = UDim2.fromOffset(18, 112)
    statusMessage.Size = UDim2.new(1, -36, 0, 30)
    statusMessage.BackgroundTransparency = 1
    statusMessage.Font = Enum.Font.Gotham
    statusMessage.Text = "Starting interface services"
    statusMessage.TextSize = 10
    statusMessage.TextColor3 = Color3.fromRGB(119, 132, 147)
    statusMessage.TextXAlignment = Enum.TextXAlignment.Left
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextWrapped = true
    statusMessage.TextTruncate = Enum.TextTruncate.AtEnd
    statusMessage.Parent = statusCard

    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.Position = UDim2.fromOffset(18, 154)
    track.Size = UDim2.new(1, -78, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(28, 37, 46)
    track.BorderSizePixel = 0
    track.Parent = statusCard
    loaderCorner(track, 99)

    progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.fromScale(statusProgress, 1)
    progressFill.BackgroundColor3 = Color3.fromRGB(51, 199, 89) -- WindUI green for progress
    progressFill.BorderSizePixel = 0
    progressFill.Parent = track
    loaderCorner(progressFill, 99)

    progressValue = Instance.new("TextLabel")
    progressValue.AnchorPoint = Vector2.new(1, 0.5)
    progressValue.Position = UDim2.new(1, -18, 0, 156)
    progressValue.Size = UDim2.fromOffset(48, 20)
    progressValue.BackgroundTransparency = 1
    progressValue.Font = Enum.Font.GothamSemibold
    progressValue.Text = "3%"
    progressValue.TextSize = 10
    progressValue.TextColor3 = Color3.fromRGB(144, 157, 170)
    progressValue.TextXAlignment = Enum.TextXAlignment.Right
    progressValue.Parent = statusCard

    statusMeta = Instance.new("TextLabel")
    statusMeta.Position = UDim2.fromOffset(18, 178)
    statusMeta.Size = UDim2.new(1, -150, 0, 18)
    statusMeta.BackgroundTransparency = 1
    statusMeta.Font = Enum.Font.Gotham
    statusMeta.Text = "Startup in progress"
    statusMeta.TextSize = 9
    statusMeta.TextColor3 = Color3.fromRGB(83, 96, 109)
    statusMeta.TextXAlignment = Enum.TextXAlignment.Left
    statusMeta.TextTruncate = Enum.TextTruncate.AtEnd
    statusMeta.Parent = statusCard

    elapsedLabel = Instance.new("TextLabel")
    elapsedLabel.AnchorPoint = Vector2.new(1, 0)
    elapsedLabel.Position = UDim2.new(1, -18, 0, 178)
    elapsedLabel.Size = UDim2.fromOffset(72, 18)
    elapsedLabel.BackgroundTransparency = 1
    elapsedLabel.Font = Enum.Font.Code
    elapsedLabel.Text = "0.0s"
    elapsedLabel.TextSize = 9
    elapsedLabel.TextColor3 = Color3.fromRGB(83, 96, 109)
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right
    elapsedLabel.Parent = statusCard

    openConsoleButton = Instance.new("TextButton")
    openConsoleButton.AnchorPoint = Vector2.new(1, 1)
    openConsoleButton.Position = UDim2.new(1, -18, 1, -16)
    openConsoleButton.Size = UDim2.fromOffset(118, 30)
    openConsoleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 33) -- match WindUI element bg
    openConsoleButton.BackgroundTransparency = 0.03
    openConsoleButton.BorderSizePixel = 0
    openConsoleButton.AutoButtonColor = false
    openConsoleButton.Font = Enum.Font.GothamSemibold
    openConsoleButton.Text = "Open diagnostics"
    openConsoleButton.TextSize = 10
    openConsoleButton.TextColor3 = Color3.fromRGB(220, 226, 232)
    openConsoleButton.Visible = false
    openConsoleButton.Parent = statusCard
    loaderCorner(openConsoleButton, 8)
    local consoleStroke = loaderStroke(openConsoleButton, Color3.fromRGB(78, 92, 107), 0.48)

    openConsoleButton.MouseEnter:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(29, 40, 50),
        })
        loaderTween(consoleStroke, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.2,
        })
    end)
    openConsoleButton.MouseLeave:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(22, 30, 38),
        })
        loaderTween(consoleStroke, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.48,
        })
    end)
    openConsoleButton.Activated:Connect(function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    loaderTween(statusBackdrop, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.38,
    })
    loaderTween(statusCard, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.5),
    })
    loaderTween(statusCardScale, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Scale = 1,
    })

    task.spawn(function()
        while statusGui and statusGui.Parent do
            if elapsedLabel then
                elapsedLabel.Text = string.format("%.1fs", os.clock() - loaderCreatedAt)
            end
            task.wait(0.25)
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
        statusTitle.Text = statusError and "Unable to finish loading" or friendlyStage(message)
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
        statusMeta.Text = statusError and "Startup paused - open diagnostics for details" or "Startup in progress"
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
            statusMessage.Text = "Everything is ready."
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
                TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {
                    GroupTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.494),
                }
            )
            loaderTween(
                statusCardScale,
                TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { Scale = 0.985 }
            )
            loaderTween(
                statusBackdrop,
                TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
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
setStatus("pipeline: initialized")
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
  local token={}
  shared.__badwars_update_watch=token
  task.spawn(function()
    local badStatus=shared.BadStatus
    if type(badStatus)~='function' then return end
    while shared.__badwars_update_watch==token do
      task.wait(300)
      if shared.__badwars_update_watch~=token then return end
      local ok,res=pcall(function()
        local api='https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/profiles/roblox-version.txt'
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
local function wipeAny(p) if isfolder(p) and __nativeDelfile then for _,f in listfiles(p) do if isfolder(f) then wipeAny(f) elseif isfile(f) then delfile(f) end end end end
local function wipeGen(p) if isfolder(p) then for _,f in listfiles(p) do if f:find('loader') then continue end;if isfolder(f) then wipeGen(f) end;if isfile(f) then local c=readfile(f);if type(c)=='string' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) and __nativeDelfile then delfile(f) end end end end end

local cacheVersion = 'badwars-v13-premium-2026-07-06-01'
local cacheFile = 'badscript/profiles/cache-version.txt'
local function isCurrentGuiCache(contents)
    return type(contents) == "string"
        and contents:find("BADWARS_UI_V13_PREMIUM_OVERHAUL", 1, true) ~= nil
        and contents:find("BADWARS_UI_QUALITY_RUNTIME_V5_BEGIN", 1, true) ~= nil
        and contents:find("BADWARS_FUSION_DESIGN_RUNTIME_V21_BEGIN", 1, true) == nil
end
local function invalidateStaleGuiCache()
	-- Legacy new/gui + also protect the new WindUI gui from aggressive wipes
	local paths = {'badscript/guis/new/gui.lua'}
	for _, p in ipairs(paths) do
		if isfile(p) and not isCurrentGuiCache(readfile(p)) then
			setStatus('clearing stale GUI cache')
			if __nativeDelfile then
				pcall(delfile, p)
			end
			if isfile(p) and type(writefile)=='function' then
				pcall(writefile, p, '')
			end
		end
	end
end
if (isfile(cacheFile) and readfile(cacheFile) or '') ~= cacheVersion then
	setStatus('cache cleared (version mismatch)')
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua'} do if isfile(f) then delfile(f) end end
	wipeAny('badscript/assets');wipeGen('badscript/games');wipeGen('badscript/libraries')
	-- Keep windui gui (new modern UI). Only wipe legacy new/ if present.
	if isfolder('badscript/guis/new') then wipeGen('badscript/guis/new') end
	writefile(cacheFile,cacheVersion)
end
invalidateStaleGuiCache()
writefile('badscript/profiles/commit.txt','main')

-- ========== SELF-TEST ==========
setStatus('pipeline: self-test')
local urls=rawUrls(ORCH_PATH)
local function emitUrlDiagnostics()
	warn('BadWars: [URL DIAGNOSTICS]')
	warn('  Repository:   '..CFG.repo..'/'..CFG.name)
	warn('  Branch:       '..CFG.branch)
	warn('  Folder:       '..CFG.folder)
	warn('  File:         '..CFG.file)
	warn('  Full path:    '..ORCH_PATH)
	warn('  URLs to try:')
	for i,u in ipairs(urls) do warn('    ['..i..'] '..u) end
end

setStatus('validating orchestrator URL')
local raw,usedUrl=httpGet(urls)
if raw==nil then
	emitUrlDiagnostics()
	local m='All HTTP methods failed for '..ORCH_PATH
	setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
if type(raw)~='string' or raw=='' then
	emitUrlDiagnostics()
	local m='ERROR empty file: Empty response for '..ORCH_PATH
	setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0)
end
if isNotFoundBody(raw) then
	emitUrlDiagnostics()
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
 setStatus(final,#issues>0)
if #issues == 0 and not shared.__badwars_fatal_error then
	task.wait(0.22)
	if statusCard and statusCard.Parent then
		loaderTween(statusCard,TweenInfo.new(0.2,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{BackgroundTransparency=1})
	end
	task.delay(0.22,function()
		if statusGui and statusGui.Parent then
			statusGui:Destroy()
		end
		shared.BadStatusGui = nil
	end)
end
return result
