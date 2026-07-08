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

-- Polyfills for all executors (including Solora, Arceus X, Delta, etc.)
readfile=readfile or function()return''end
writefile=writefile or function()end
isfile=isfile or function(f)local s,r=pcall(readfile,f)return s and r~=nil and r~=''end
local __nativeDelfile=type(delfile)=='function'
delfile=delfile or function()return false,'delfile unavailable'end
isfolder=isfolder or function()return false end
makefolder=makefolder or function()end
listfiles=listfiles or function()return{}end
cloneref=cloneref or clonereference or function(o)return o end
setthreadidentity=setthreadidentity or function()end
queue_on_teleport=queue_on_teleport or queueonteleport or function()end

-- task library polyfill for older executors
if not task then
    task = {}
    task.wait = wait or function(t) return wait(t) end
    task.spawn = spawn or coroutine.wrap or function(f) coroutine.wrap(f)() end
    task.delay = delay or function(t,f) spawn(function() wait(t) f() end) end
    task.cancel = function() end -- no-op for older executors
    task.defer = spawn or function(f) coroutine.wrap(f)() end
end

-- tick() fallback
if not tick then
    tick = os.clock
end

-- debug library safety
if not debug then
    debug = {}
end
if not debug.traceback then
    debug.traceback = function(msg) return tostring(msg or "") end
end

-- getgenv fallback
if not getgenv then
    getgenv = function() return _G end
end

-- loadstring fallback
if not loadstring then
    loadstring = load or function(code) error("loadstring unavailable") end
end

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
	local worker=task.spawn(function()
		ok,result=pcall(callback)
		done=true
	end)
	local started=os.clock()
	while not done and os.clock()-started<(timeout or 12) do
		task.wait(0.03)
	end
	if not done then
		pcall(task.cancel,worker)
		return false,'timeout'
	end
	return ok,result
end

local isNotFoundBody

local function httpGet(urls)
	for _,url in ipairs(urls) do
		local fn
		pcall(function()fn=game and game.HttpGet end)
		if type(fn)~='function' then
			local env=getgenv and type(getgenv)=='function' and getgenv()
			fn=env and env.HttpGet
		end
		if type(fn)=='function' then
			local ok,res=callWithTimeout(function()return fn(game,url,true)end,12)
			if ok and type(res)=='string' and #res>0 and not isNotFoundBody(res) then return res,url end
		end
		local ok,res=callWithTimeout(function()
			return cloneref(game:GetService('HttpService')):GetAsync(url,true)
		end,12)
		if ok and type(res)=='string' and #res>0 and not isNotFoundBody(res) then return res,url end
	end
	return nil,nil
end

isNotFoundBody = function(body)
	if type(body)~='string' then return false end
	local trimmed=body:match('^%s*(.-)%s*$')
	return trimmed=='404: Not Found' or trimmed=='{"message":"Not Found"}' or (#trimmed<200 and trimmed:find('"message"%s*:%s*"Not Found"')~=nil)
end

-- BADWARS_LOADER_PRESENTATION_V2_BEGIN
local statusGui
local statusCard
local statusBackdrop
local statusTitle
local statusMessage
local statusMeta
local progressFill
local progressGlow
local progressValue
local elapsedLabel
local stateDot
local statusChipText
local statusAccent
local statusAccentGradient
local progressGradient
local openConsoleButton
local statusCardScale
local statusCardStroke
local phaseMarkers = {}

local statusProgress = 0.03
local statusError = false
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local loaderDismissScheduled = false
local MINIMUM_VISIBLE_SECONDS = 1.35

local loaderTweenService = cloneref(game:GetService("TweenService"))

local COLORS = {
    backdrop = Color3.fromRGB(7, 9, 13),
    card = Color3.fromRGB(15, 18, 24),
    cardSecondary = Color3.fromRGB(18, 22, 29),
    surface = Color3.fromRGB(23, 28, 36),
    surfaceHover = Color3.fromRGB(29, 35, 45),
    border = Color3.fromRGB(57, 67, 82),
    divider = Color3.fromRGB(42, 49, 61),
    text = Color3.fromRGB(242, 245, 248),
    textSoft = Color3.fromRGB(181, 190, 201),
    textMuted = Color3.fromRGB(112, 123, 138),
    textFaint = Color3.fromRGB(78, 88, 103),
    accent = Color3.fromRGB(76, 217, 162),
    accentBright = Color3.fromRGB(116, 238, 191),
    accentDark = Color3.fromRGB(35, 133, 99),
    warning = Color3.fromRGB(244, 183, 74),
    warningSoft = Color3.fromRGB(255, 205, 116),
}

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

    return nil
end

local function loaderCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function loaderStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function loaderGradient(parent, color, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = color
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

local function isTerminalStatus(message)
    local lower = string.lower(tostring(message or ""))
    return lower == "ready"
        or string.sub(lower, 1, 7) == "ready -"
        or string.find(lower, "launch complete", 1, true) ~= nil
        or string.find(lower, "loader complete", 1, true) ~= nil
end

local function resolveStatusProgress(message)
    local lower = string.lower(tostring(message or ""))

    if isTerminalStatus(lower) then
        return 1
    end

    local stages = {
        { "initialized", 0.06 },
        { "cache setup", 0.13 },
        { "cache cleared", 0.18 },
        { "self-test", 0.24 },
        { "validating orchestrator", 0.31 },
        { "url validation passed", 0.39 },
        { "compiled ok", 0.5 },
        { "executing main", 0.59 },
        { "interface", 0.67 },
        { "core modules", 0.75 },
        { "universal", 0.82 },
        { "game module", 0.88 },
        { "profile", 0.93 },
        { "validation passed", 0.98 },
        { "finalizing", 0.98 },
    }

    for _, stage in ipairs(stages) do
        if string.find(lower, stage[1], 1, true) then
            return stage[2]
        end
    end

    return math.min(statusProgress + 0.022, 0.98)
end

local function friendlyStage(message)
    local lower = string.lower(tostring(message or ""))

    if string.find(lower, "initialized", 1, true) then
        return "Initializing"
    elseif string.find(lower, "cache setup", 1, true) then
        return "Preparing local cache"
    elseif string.find(lower, "cache cleared", 1, true) then
        return "Refreshing cached files"
    elseif string.find(lower, "stale gui cache", 1, true) then
        return "Refreshing interface files"
    elseif string.find(lower, "self-test", 1, true) then
        return "Running startup checks"
    elseif string.find(lower, "validating orchestrator", 1, true) then
        return "Verifying source"
    elseif string.find(lower, "url validation passed", 1, true) then
        return "Source verified"
    elseif string.find(lower, "compiled ok", 1, true) then
        return "Runtime prepared"
    elseif string.find(lower, "executing main", 1, true) then
        return "Launching BadWars"
    elseif string.find(lower, "pipeline: validation", 1, true) then
        return "Final verification"
    elseif string.find(lower, "validation passed", 1, true) then
        return "Startup verified"
    elseif isTerminalStatus(lower) then
        return "Ready"
    end

    local text = tostring(message or "Working")
    text = text:gsub("^pipeline:%s*", "")
    text = text:gsub("^loading%s+", "Loading ")
    text = text:gsub("^downloading%s+", "Downloading ")
    text = text:gsub("^validating%s+", "Checking ")
    text = text:gsub("^finalizing%s*", "Finishing")
    return text
end

local function statusDetail(message)
    local lower = string.lower(tostring(message or ""))

    if string.find(lower, "initialized", 1, true) then
        return "Establishing the loader environment and compatibility services."
    elseif string.find(lower, "cache setup", 1, true) then
        return "Preparing local folders and checking saved components."
    elseif string.find(lower, "cache cleared", 1, true) then
        return "Outdated resources were removed so the newest build can load cleanly."
    elseif string.find(lower, "stale gui cache", 1, true) then
        return "Replacing an older interface build with the current version."
    elseif string.find(lower, "self-test", 1, true) then
        return "Checking required services before the main runtime starts."
    elseif string.find(lower, "validating orchestrator", 1, true) then
        return "Confirming that the main startup source is available and valid."
    elseif string.find(lower, "url validation passed", 1, true) then
        return "The startup source responded successfully and is ready to compile."
    elseif string.find(lower, "compiled ok", 1, true) then
        return "The main runtime compiled successfully with no blocking syntax errors."
    elseif string.find(lower, "executing main", 1, true) then
        return "Starting the interface, modules, profiles, and game-specific systems."
    elseif string.find(lower, "pipeline: validation", 1, true) then
        return "Reviewing module results and checking for startup issues."
    elseif string.find(lower, "validation passed", 1, true) then
        return "All required startup checks completed successfully."
    elseif isTerminalStatus(lower) then
        return "BadWars is loaded and ready to use."
    end

    return tostring(message or "Working")
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

local function updatePhaseMarkers(progress, isError)
    local activeColor = isError and COLORS.warning or COLORS.accent
    local activeText = isError and COLORS.warningSoft or COLORS.textSoft
    local phaseThresholds = { 0.03, 0.36, 0.68, 0.96 }

    for index, marker in ipairs(phaseMarkers) do
        local active = progress >= phaseThresholds[index]
        if marker.dot then
            loaderTween(marker.dot, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = active and activeColor or COLORS.surface,
                BackgroundTransparency = active and 0 or 0.1,
            })
        end
        if marker.label then
            loaderTween(marker.label, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                TextColor3 = active and activeText or COLORS.textFaint,
            })
        end
    end
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

    statusBackdrop = Instance.new("CanvasGroup")
    statusBackdrop.Name = "Backdrop"
    statusBackdrop.Size = UDim2.fromScale(1, 1)
    statusBackdrop.BackgroundColor3 = COLORS.backdrop
    statusBackdrop.BackgroundTransparency = 0.28
    statusBackdrop.BorderSizePixel = 0
    statusBackdrop.GroupTransparency = 1
    statusBackdrop.Parent = statusGui

    loaderGradient(statusBackdrop, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 11, 16)),
        ColorSequenceKeypoint.new(0.55, Color3.fromRGB(10, 13, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 7, 11)),
    }), 115)

    local ambientGlow = Instance.new("Frame")
    ambientGlow.Name = "AmbientGlow"
    ambientGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    ambientGlow.Position = UDim2.fromScale(0.5, 0.5)
    ambientGlow.Size = UDim2.fromOffset(620, 390)
    ambientGlow.BackgroundColor3 = COLORS.accentDark
    ambientGlow.BackgroundTransparency = 0.91
    ambientGlow.BorderSizePixel = 0
    ambientGlow.Parent = statusBackdrop
    loaderCorner(ambientGlow, 999)

    local loaderViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local loaderWidth = math.clamp(loaderViewport.X - 32, 352, 540)
    local loaderHeight = math.clamp(loaderViewport.Y - 40, 286, 304)

    local shadowBack = Instance.new("Frame")
    shadowBack.Name = "ShadowBack"
    shadowBack.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowBack.Position = UDim2.fromScale(0.5, 0.514)
    shadowBack.Size = UDim2.fromOffset(loaderWidth + 22, loaderHeight + 22)
    shadowBack.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowBack.BackgroundTransparency = 0.72
    shadowBack.BorderSizePixel = 0
    shadowBack.Parent = statusBackdrop
    loaderCorner(shadowBack, 22)

    local shadowNear = Instance.new("Frame")
    shadowNear.Name = "ShadowNear"
    shadowNear.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowNear.Position = UDim2.fromScale(0.5, 0.507)
    shadowNear.Size = UDim2.fromOffset(loaderWidth + 8, loaderHeight + 8)
    shadowNear.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowNear.BackgroundTransparency = 0.42
    shadowNear.BorderSizePixel = 0
    shadowNear.Parent = statusBackdrop
    loaderCorner(shadowNear, 18)

    statusCard = Instance.new("CanvasGroup")
    statusCard.Name = "Loader"
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.512)
    statusCard.Size = UDim2.fromOffset(loaderWidth, loaderHeight)
    statusCard.BackgroundColor3 = COLORS.card
    statusCard.BackgroundTransparency = 0.01
    statusCard.BorderSizePixel = 0
    statusCard.GroupTransparency = 1
    statusCard.ClipsDescendants = true
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 16)
    statusCardStroke = loaderStroke(statusCard, COLORS.border, 0.42, 1)

    loaderGradient(statusCard, ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.cardSecondary),
        ColorSequenceKeypoint.new(0.55, COLORS.card),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 16, 21)),
    }), 105)

    statusCardScale = Instance.new("UIScale")
    statusCardScale.Name = "MotionScale"
    statusCardScale.Scale = 0.965
    statusCardScale.Parent = statusCard

    statusAccent = Instance.new("Frame")
    statusAccent.Name = "TopAccent"
    statusAccent.Size = UDim2.new(1, 0, 0, 2)
    statusAccent.BackgroundColor3 = COLORS.accent
    statusAccent.BorderSizePixel = 0
    statusAccent.Parent = statusCard
    statusAccentGradient = loaderGradient(statusAccent, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 151, 113)),
        ColorSequenceKeypoint.new(0.5, COLORS.accentBright),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 151, 113)),
    }), 0)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Position = UDim2.fromOffset(20, 19)
    header.Size = UDim2.new(1, -40, 0, 48)
    header.BackgroundTransparency = 1
    header.Parent = statusCard

    local logo = Instance.new("Frame")
    logo.Name = "Logo"
    logo.Size = UDim2.fromOffset(42, 42)
    logo.Position = UDim2.fromOffset(0, 1)
    logo.BackgroundColor3 = COLORS.surface
    logo.BorderSizePixel = 0
    logo.Parent = header
    loaderCorner(logo, 12)
    loaderStroke(logo, COLORS.border, 0.46, 1)
    loaderGradient(logo, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 39, 47)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 25, 32)),
    }), 135)

    local logoAccent = Instance.new("Frame")
    logoAccent.Name = "Accent"
    logoAccent.AnchorPoint = Vector2.new(0.5, 1)
    logoAccent.Position = UDim2.new(0.5, 0, 1, -5)
    logoAccent.Size = UDim2.fromOffset(18, 3)
    logoAccent.BackgroundColor3 = COLORS.accent
    logoAccent.BorderSizePixel = 0
    logoAccent.Parent = logo
    loaderCorner(logoAccent, 99)

    local logoText = Instance.new("TextLabel")
    logoText.Name = "Letter"
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Font = Enum.Font.GothamBold
    logoText.Text = "B"
    logoText.TextSize = 20
    logoText.TextColor3 = COLORS.text
    logoText.Parent = logo

    local brand = Instance.new("TextLabel")
    brand.Name = "Brand"
    brand.Position = UDim2.fromOffset(54, 1)
    brand.Size = UDim2.new(1, -176, 0, 24)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamBold
    brand.Text = "BadWars"
    brand.TextSize = 18
    brand.TextColor3 = COLORS.text
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.TextTruncate = Enum.TextTruncate.AtEnd
    brand.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Position = UDim2.fromOffset(54, 25)
    subtitle.Size = UDim2.new(1, -176, 0, 17)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "Secure runtime initialization"
    subtitle.TextSize = 10
    subtitle.TextColor3 = COLORS.textMuted
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    subtitle.Parent = header

    local versionPill = Instance.new("Frame")
    versionPill.Name = "VersionPill"
    versionPill.AnchorPoint = Vector2.new(1, 0)
    versionPill.Position = UDim2.new(1, 0, 0, 4)
    versionPill.Size = UDim2.fromOffset(102, 28)
    versionPill.BackgroundColor3 = COLORS.surface
    versionPill.BackgroundTransparency = 0.08
    versionPill.BorderSizePixel = 0
    versionPill.Parent = header
    loaderCorner(versionPill, 9)
    loaderStroke(versionPill, COLORS.border, 0.56, 1)

    stateDot = Instance.new("Frame")
    stateDot.Name = "State"
    stateDot.AnchorPoint = Vector2.new(0, 0.5)
    stateDot.Position = UDim2.new(0, 10, 0.5, 0)
    stateDot.Size = UDim2.fromOffset(7, 7)
    stateDot.BackgroundColor3 = COLORS.accent
    stateDot.BorderSizePixel = 0
    stateDot.Parent = versionPill
    loaderCorner(stateDot, 99)

    statusChipText = Instance.new("TextLabel")
    statusChipText.Name = "Label"
    statusChipText.Position = UDim2.fromOffset(24, 0)
    statusChipText.Size = UDim2.new(1, -30, 1, 0)
    statusChipText.BackgroundTransparency = 1
    statusChipText.Font = Enum.Font.GothamSemibold
    statusChipText.Text = "STARTING"
    statusChipText.TextSize = 9
    statusChipText.TextColor3 = COLORS.textSoft
    statusChipText.TextXAlignment = Enum.TextXAlignment.Left
    statusChipText.Parent = versionPill

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Position = UDim2.fromOffset(20, 80)
    divider.Size = UDim2.new(1, -40, 0, 1)
    divider.BackgroundColor3 = COLORS.divider
    divider.BackgroundTransparency = 0.28
    divider.BorderSizePixel = 0
    divider.Parent = statusCard

    local contentTop = 98

    statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "Stage"
    statusTitle.Position = UDim2.fromOffset(20, contentTop)
    statusTitle.Size = UDim2.new(1, -40, 0, 27)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Font = Enum.Font.GothamSemibold
    statusTitle.Text = "Initializing"
    statusTitle.TextSize = 16
    statusTitle.TextColor3 = COLORS.text
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.TextTruncate = Enum.TextTruncate.AtEnd
    statusTitle.Parent = statusCard

    statusMessage = Instance.new("TextLabel")
    statusMessage.Name = "Detail"
    statusMessage.Position = UDim2.fromOffset(20, contentTop + 31)
    statusMessage.Size = UDim2.new(1, -40, 0, 34)
    statusMessage.BackgroundTransparency = 1
    statusMessage.Font = Enum.Font.Gotham
    statusMessage.Text = "Establishing the loader environment and compatibility services."
    statusMessage.TextSize = 10
    statusMessage.TextColor3 = COLORS.textMuted
    statusMessage.TextXAlignment = Enum.TextXAlignment.Left
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextWrapped = true
    statusMessage.TextTruncate = Enum.TextTruncate.AtEnd
    statusMessage.Parent = statusCard

    local progressHeaderY = contentTop + 77

    local progressCaption = Instance.new("TextLabel")
    progressCaption.Name = "ProgressCaption"
    progressCaption.Position = UDim2.fromOffset(20, progressHeaderY)
    progressCaption.Size = UDim2.fromOffset(130, 17)
    progressCaption.BackgroundTransparency = 1
    progressCaption.Font = Enum.Font.GothamSemibold
    progressCaption.Text = "STARTUP PROGRESS"
    progressCaption.TextSize = 8
    progressCaption.TextColor3 = COLORS.textFaint
    progressCaption.TextXAlignment = Enum.TextXAlignment.Left
    progressCaption.Parent = statusCard

    progressValue = Instance.new("TextLabel")
    progressValue.Name = "ProgressValue"
    progressValue.AnchorPoint = Vector2.new(1, 0)
    progressValue.Position = UDim2.new(1, -20, 0, progressHeaderY - 1)
    progressValue.Size = UDim2.fromOffset(48, 18)
    progressValue.BackgroundTransparency = 1
    progressValue.Font = Enum.Font.GothamBold
    progressValue.Text = "3%"
    progressValue.TextSize = 10
    progressValue.TextColor3 = COLORS.textSoft
    progressValue.TextXAlignment = Enum.TextXAlignment.Right
    progressValue.Parent = statusCard

    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.Position = UDim2.fromOffset(20, progressHeaderY + 23)
    track.Size = UDim2.new(1, -40, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(25, 30, 38)
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = statusCard
    loaderCorner(track, 99)
    loaderStroke(track, COLORS.border, 0.72, 1)

    progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.fromScale(statusProgress, 1)
    progressFill.BackgroundColor3 = COLORS.accent
    progressFill.BorderSizePixel = 0
    progressFill.ClipsDescendants = true
    progressFill.Parent = track
    loaderCorner(progressFill, 99)

    progressGradient = loaderGradient(progressFill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.accentDark),
        ColorSequenceKeypoint.new(0.55, COLORS.accent),
        ColorSequenceKeypoint.new(1, COLORS.accentBright),
    }), 0)

    progressGlow = Instance.new("Frame")
    progressGlow.Name = "Glow"
    progressGlow.AnchorPoint = Vector2.new(1, 0.5)
    progressGlow.Position = UDim2.new(1, 0, 0.5, 0)
    progressGlow.Size = UDim2.fromOffset(22, 14)
    progressGlow.BackgroundColor3 = COLORS.accentBright
    progressGlow.BackgroundTransparency = 0.52
    progressGlow.BorderSizePixel = 0
    progressGlow.Parent = progressFill
    loaderCorner(progressGlow, 99)

    local phases = Instance.new("Frame")
    phases.Name = "Phases"
    phases.Position = UDim2.fromOffset(20, progressHeaderY + 40)
    phases.Size = UDim2.new(1, -40, 0, 18)
    phases.BackgroundTransparency = 1
    phases.Parent = statusCard

    local phaseNames = { "SETUP", "VERIFY", "LOAD", "READY" }
    phaseMarkers = {}

    for index, phaseName in ipairs(phaseNames) do
        local holder = Instance.new("Frame")
        holder.Name = phaseName
        holder.Position = UDim2.new((index - 1) / 4, 0, 0, 0)
        holder.Size = UDim2.new(0.25, 0, 1, 0)
        holder.BackgroundTransparency = 1
        holder.Parent = phases

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Position = UDim2.fromOffset(0, 4)
        dot.Size = UDim2.fromOffset(6, 6)
        dot.BackgroundColor3 = index == 1 and COLORS.accent or COLORS.surface
        dot.BackgroundTransparency = index == 1 and 0 or 0.1
        dot.BorderSizePixel = 0
        dot.Parent = holder
        loaderCorner(dot, 99)

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Position = UDim2.fromOffset(12, 0)
        label.Size = UDim2.new(1, -14, 0, 14)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamSemibold
        label.Text = phaseName
        label.TextSize = 7
        label.TextColor3 = index == 1 and COLORS.textSoft or COLORS.textFaint
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = holder

        phaseMarkers[index] = {
            dot = dot,
            label = label,
        }
    end

    local footerY = loaderHeight - 38

    local footerDivider = Instance.new("Frame")
    footerDivider.Name = "FooterDivider"
    footerDivider.Position = UDim2.fromOffset(20, footerY - 10)
    footerDivider.Size = UDim2.new(1, -40, 0, 1)
    footerDivider.BackgroundColor3 = COLORS.divider
    footerDivider.BackgroundTransparency = 0.46
    footerDivider.BorderSizePixel = 0
    footerDivider.Parent = statusCard

    statusMeta = Instance.new("TextLabel")
    statusMeta.Name = "Meta"
    statusMeta.Position = UDim2.fromOffset(20, footerY)
    statusMeta.Size = UDim2.new(1, -190, 0, 20)
    statusMeta.BackgroundTransparency = 1
    statusMeta.Font = Enum.Font.Gotham
    statusMeta.Text = "Protected startup session"
    statusMeta.TextSize = 9
    statusMeta.TextColor3 = COLORS.textFaint
    statusMeta.TextXAlignment = Enum.TextXAlignment.Left
    statusMeta.TextTruncate = Enum.TextTruncate.AtEnd
    statusMeta.Parent = statusCard

    elapsedLabel = Instance.new("TextLabel")
    elapsedLabel.Name = "Elapsed"
    elapsedLabel.AnchorPoint = Vector2.new(1, 0)
    elapsedLabel.Position = UDim2.new(1, -20, 0, footerY)
    elapsedLabel.Size = UDim2.fromOffset(72, 20)
    elapsedLabel.BackgroundTransparency = 1
    elapsedLabel.Font = Enum.Font.Code
    elapsedLabel.Text = "0.0s"
    elapsedLabel.TextSize = 9
    elapsedLabel.TextColor3 = COLORS.textFaint
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right
    elapsedLabel.Parent = statusCard

    openConsoleButton = Instance.new("TextButton")
    openConsoleButton.Name = "Diagnostics"
    openConsoleButton.AnchorPoint = Vector2.new(1, 0)
    openConsoleButton.Position = UDim2.new(1, -20, 0, footerY - 6)
    openConsoleButton.Size = UDim2.fromOffset(124, 29)
    openConsoleButton.BackgroundColor3 = COLORS.surface
    openConsoleButton.BackgroundTransparency = 0.02
    openConsoleButton.BorderSizePixel = 0
    openConsoleButton.AutoButtonColor = false
    openConsoleButton.Font = Enum.Font.GothamSemibold
    openConsoleButton.Text = "Open diagnostics"
    openConsoleButton.TextSize = 9
    openConsoleButton.TextColor3 = COLORS.warningSoft
    openConsoleButton.Visible = false
    openConsoleButton.Parent = statusCard
    loaderCorner(openConsoleButton, 9)
    local consoleStroke = loaderStroke(openConsoleButton, COLORS.warning, 0.44, 1)

    openConsoleButton.MouseEnter:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.surfaceHover,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.18,
        })
    end)

    openConsoleButton.MouseLeave:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.surface,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.44,
        })
    end)

    openConsoleButton.Activated:Connect(function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    loaderTween(statusBackdrop, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        GroupTransparency = 0,
    })
    loaderTween(statusCard, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        GroupTransparency = 0,
        Position = UDim2.fromScale(0.5, 0.5),
    })
    loaderTween(statusCardScale, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Scale = 1,
    })

    task.spawn(function()
        while statusGui and statusGui.Parent do
            if elapsedLabel and elapsedLabel.Parent then
                elapsedLabel.Text = string.format("%.1fs", os.clock() - loaderCreatedAt)
            end
            task.wait(0.2)
        end
    end)

    task.spawn(function()
        while statusGui and statusGui.Parent and stateDot and stateDot.Parent do
            loaderTween(stateDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.46,
            })
            task.wait(0.72)
            loaderTween(stateDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0,
            })
            task.wait(0.72)
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

    local accent = statusError and COLORS.warning or COLORS.accent
    local accentBright = statusError and COLORS.warningSoft or COLORS.accentBright

    if statusTitle then
        statusTitle.Text = statusError and "Startup needs attention" or friendlyStage(message)
        statusTitle.TextColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if statusMessage then
        statusMessage.Text = statusError
            and "BadWars could not finish startup. Open diagnostics to review the reported issue."
            or statusDetail(message)
        statusMessage.TextColor3 = statusError and COLORS.textSoft or COLORS.textMuted
    end

    if statusMeta then
        statusMeta.Text = statusError and "Startup paused for diagnostics" or "Protected startup session"
    end

    if statusChipText then
        statusChipText.Text = statusError and "ATTENTION" or (terminal and "READY" or "STARTING")
        statusChipText.TextColor3 = statusError and COLORS.warningSoft or COLORS.textSoft
    end

    if stateDot then
        stateDot.BackgroundColor3 = accent
    end

    if statusAccent then
        statusAccent.BackgroundColor3 = accent
    end

    if statusAccentGradient then
        statusAccentGradient.Color = statusError
            and ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(151, 103, 34)),
                ColorSequenceKeypoint.new(0.5, COLORS.warningSoft),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(151, 103, 34)),
            })
            or ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 151, 113)),
                ColorSequenceKeypoint.new(0.5, COLORS.accentBright),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(42, 151, 113)),
            })
    end

    if statusCardStroke then
        loaderTween(statusCardStroke, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Color = statusError and COLORS.warning or COLORS.border,
            Transparency = statusError and 0.28 or 0.42,
        })
    end

    if progressFill then
        progressFill.BackgroundColor3 = accent
        loaderTween(
            progressFill,
            TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Size = UDim2.fromScale(math.clamp(statusProgress, 0.03, 1), 1) }
        )
    end

    if progressGradient then
        progressGradient.Color = statusError
            and ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(151, 103, 34)),
                ColorSequenceKeypoint.new(0.55, COLORS.warning),
                ColorSequenceKeypoint.new(1, COLORS.warningSoft),
            })
            or ColorSequence.new({
                ColorSequenceKeypoint.new(0, COLORS.accentDark),
                ColorSequenceKeypoint.new(0.55, COLORS.accent),
                ColorSequenceKeypoint.new(1, COLORS.accentBright),
            })
    end

    if progressGlow then
        progressGlow.BackgroundColor3 = accentBright
    end

    if progressValue then
        progressValue.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
        progressValue.TextColor3 = statusError and COLORS.warningSoft or COLORS.textSoft
    end

    updatePhaseMarkers(statusProgress, statusError)

    if openConsoleButton then
        openConsoleButton.Visible = statusError
    end

    if elapsedLabel then
        elapsedLabel.Visible = not statusError
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
            statusMessage.Text = "BadWars is loaded and ready to use."
        end

        local visibleFor = os.clock() - loaderCreatedAt
        local hold = math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.4

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
                TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {
                    GroupTransparency = 1,
                    Position = UDim2.fromScale(0.5, 0.49),
                }
            )
            loaderTween(
                statusCardScale,
                TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { Scale = 0.98 }
            )
            loaderTween(
                statusBackdrop,
                TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                { GroupTransparency = 1 }
            )

            task.delay(0.24, function()
                if generation == loaderStatusGeneration and statusGui and statusGui.Parent then
                    statusGui:Destroy()
                    shared.BadStatusGui = nil
                end
            end)
        end)
    end
end

local setStatus = shared.BadStatus
setStatus("pipeline: initialized")
-- BADWARS_LOADER_PRESENTATION_V2_END
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
local function wipeGen(p) if isfolder(p) then for _,f in listfiles(p) do if f:find('loader') then continue end;if isfolder(f) then wipeGen(f) end;if isfile(f) then local c=readfile(f);if type(c)=='string' and c~='' and (c:find('-- BadWars',1,true)==1 or c:find('--This watermark',1,true)==1) and __nativeDelfile then pcall(delfile,f) end end end end end

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
	for _,f in {'badscript/main.lua','badscript/NewMainScript.lua'} do if isfile(f) then pcall(delfile,f) end end
	wipeAny('badscript/assets');wipeGen('badscript/games');wipeGen('badscript/libraries')
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
local ok,result=xpcall(fn,function(err) local d=shared.BadDiagnostics; local hasTraceback=type(debug)=="table" and type(debug.traceback)=="function" return d and d:Traceback(err,2) or (hasTraceback and debug.traceback(tostring(err),2) or tostring(err)) end)
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
return result
