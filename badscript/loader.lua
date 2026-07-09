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
                if ok and type(result) == "string" and #result >= 50 and result ~= "404: Not Found" then
                    -- Validate it's actually Lua content, not an HTML error page
                    local trimmed = result:match("^%s*(.-)%s*$")
                    local isValid = trimmed:find("function", 1, true) or trimmed:find("local ", 1, true) or trimmed:find("--", 1, true)
                    local isHtml = trimmed:find("<!DOCTYPE", 1, true) or trimmed:find("<html", 1, true)
                    if isValid and not isHtml then
                        source = result
                        sourceName = url
                        break
                    end
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
-- BadWars Loader
-- Dual-format URL fallback + all diagnostics

local loaderStart=os.clock()

-- Polyfills for all executors (including Solora, Arceus X, Delta, Wave, Xeno, etc.)
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

-- HTTP polyfill: discover all available request functions
local __httpFunctions = {}
pcall(function()
    -- game.HttpGet (Roblox native, some executors)
    if game and type(game.HttpGet) == 'function' then
        table.insert(__httpFunctions, {name='game.HttpGet', type='roblox', fn=function(url)
            return game:HttpGet(url, true)
        end})
    end
end)
pcall(function()
    -- getgenv().HttpGet
    local env = type(getgenv)=='function' and getgenv() or nil
    if type(env)=='table' and type(env.HttpGet)=='function' then
        local genvFn = env.HttpGet
        table.insert(__httpFunctions, {name='getgenv.HttpGet', type='roblox', fn=function(url)
            return genvFn(game, url, true)
        end})
    end
end)
pcall(function()
    -- HttpService:GetAsync
    local svc = cloneref(game:GetService('HttpService'))
    if svc and type(svc.GetAsync)=='function' then
        table.insert(__httpFunctions, {name='HttpService.GetAsync', type='roblox', fn=function(url)
            return svc:GetAsync(url, true)
        end})
    end
end)
-- request() - Xeno, Solora, Wave, Arceus X, Delta, Hydrogen, Electron, Krnl, etc.
pcall(function()
    if type(request)=='function' then
        table.insert(__httpFunctions, {name='request', type='generic', fn=function(url)
            local result = request({Url=url, Method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
        -- Also try lowercase format
        table.insert(__httpFunctions, {name='request(lowercase)', type='generic', fn=function(url)
            local result = request({url=url, method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
        -- Also try simple URL format
        table.insert(__httpFunctions, {name='request(simple)', type='generic', fn=function(url)
            local result = request(url)
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
    end
end)
-- http_request() - some executors
pcall(function()
    if type(http_request)=='function' then
        table.insert(__httpFunctions, {name='http_request', type='generic', fn=function(url)
            local result = http_request({Url=url, Method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
    end
end)
-- syn.request() - Synapse X
pcall(function()
    if type(syn)=='table' and type(syn.request)=='function' then
        local synReq = syn.request
        table.insert(__httpFunctions, {name='syn.request', type='generic', fn=function(url)
            local result = synReq({Url=url, Method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
    end
end)
-- syn.http_request() - Synapse X (older)
pcall(function()
    if type(syn)=='table' and type(syn.http_request)=='function' then
        local synHttpReq = syn.http_request
        table.insert(__httpFunctions, {name='syn.http_request', type='generic', fn=function(url)
            local result = synHttpReq({Url=url, Method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
    end
end)
-- syn.http_get() - Synapse X (oldest)
pcall(function()
    if type(syn)=='table' and type(syn.http_get)=='function' then
        local synHttpGet = syn.http_get
        table.insert(__httpFunctions, {name='syn.http_get', type='generic', fn=function(url)
            return synHttpGet(url)
        end})
    end
end)
-- fluxus.request() - Fluxus
pcall(function()
    if type(fluxus)=='table' and type(fluxus.request)=='function' then
        local fluxusReq = fluxus.request
        table.insert(__httpFunctions, {name='fluxus.request', type='generic', fn=function(url)
            local result = fluxusReq({Url=url, Method='GET'})
            if type(result)=='table' then
                return result.Body or result.body or result
            end
            return result
        end})
    end
end)
-- fluxus.http_get() - Fluxus (older)
pcall(function()
    if type(fluxus)=='table' and type(fluxus.http_get)=='function' then
        local fluxusHttpGet = fluxus.http_get
        table.insert(__httpFunctions, {name='fluxus.http_get', type='generic', fn=function(url)
            return fluxusHttpGet(url)
        end})
    end
end)
-- getgenv().request / getgenv().http_request
pcall(function()
    local env = type(getgenv)=='function' and getgenv() or nil
    if type(env)=='table' then
        if type(env.request)=='function' then
            local genvReq = env.request
            table.insert(__httpFunctions, {name='getgenv.request', type='generic', fn=function(url)
                local result = genvReq({Url=url, Method='GET'})
                if type(result)=='table' then
                    return result.Body or result.body or result
                end
                return result
            end})
        end
        if type(env.http_request)=='function' then
            local genvHttpReq = env.http_request
            table.insert(__httpFunctions, {name='getgenv.http_request', type='generic', fn=function(url)
                local result = genvHttpReq({Url=url, Method='GET'})
                if type(result)=='table' then
                    return result.Body or result.body or result
                end
                return result
            end})
        end
    end
end)

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
		pcall(function() task.cancel(worker) end)
		return false,'timeout'
	end
	return ok,result
end

local isNotFoundBody
local isRateLimited
local isCorruptedBody

local function httpGet(urls)
	for _,url in ipairs(urls) do
		for _,httpFn in ipairs(__httpFunctions) do
			local ok,res=callWithTimeout(function()
				return httpFn.fn(url)
			end,15)
			if ok and type(res)=='string' and #res>=50 and not isNotFoundBody(res) and not isRateLimited(res) and not isCorruptedBody(res) then
				return res,url
			end
		end
	end
	return nil,nil
end

isCorruptedBody = function(body)
	if type(body) ~= 'string' or #body < 50 then return true end
	local trimmed = body:match('^%s*(.-)%s*$')
	if trimmed:find('<!DOCTYPE', 1, true) or trimmed:find('<html', 1, true) then return true end
	if not trimmed:find('function', 1, true) and not trimmed:find('local ', 1, true) and not trimmed:find('--', 1, true) then
		if trimmed:find('<', 1, true) and trimmed:find('>', 1, true) then return true end
	end
	local nonPrintable = 0
	for i = 1, math.min(#body, 200) do
		local c = body:byte(i)
		if c and (c < 32 and c ~= 10 and c ~= 13 and c ~= 9) then
			nonPrintable = nonPrintable + 1
		end
	end
	if nonPrintable > 10 then return true end
	return false
end

isNotFoundBody = function(body)
	if type(body)~='string' then return false end
	local trimmed=body:match('^%s*(.-)%s*$')
	return trimmed=='404: Not Found' or trimmed=='{"message":"Not Found"}' or (#trimmed<200 and trimmed:find('"message"%s*:%s*"Not Found"')~=nil)
end

isRateLimited = function(body)
	if type(body) ~= 'string' then return false end
	local trimmed = body:match('^%s*(.-)%s*$')
	if trimmed:find('429', 1, true) and #trimmed < 300 then return true end
	if trimmed:find('rate limit', 1, true) and #trimmed < 500 then return true end
	if trimmed:find('abuse detection', 1, true) then return true end
	if trimmed:find('<!DOCTYPE', 1, true) or trimmed:find('<html', 1, true) then return true end
	if #trimmed < 200 and trimmed:find('"message"%s*:') and not trimmed:find('"message"%s*:%s*"Not Found"') then return true end
	return false
end

-- BADWARS_LOADER_PRESENTATION_V4_BEGIN
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
local statusChipText
local statusAccent
local openConsoleButton
local statusCardScale
local statusCardStroke
local phaseMarkers = {}

local statusProgress = 0.03
local statusError = false
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local loaderDismissScheduled = false
local MINIMUM_VISIBLE_SECONDS = 1.25

local loaderTweenService = cloneref(game:GetService("TweenService"))

local COLORS = {
    backdrop = Color3.fromRGB(2, 4, 7),
    background = Color3.fromRGB(5, 9, 13),
    dialog = Color3.fromRGB(8, 13, 18),
    accent = Color3.fromRGB(11, 17, 23),
    element = Color3.fromRGB(12, 18, 24),
    elementHover = Color3.fromRGB(19, 29, 38),
    button = Color3.fromRGB(16, 16, 16),
    outline = Color3.fromRGB(73, 94, 110),
    text = Color3.fromRGB(241, 245, 248),
    placeholder = Color3.fromRGB(103, 117, 131),
    icon = Color3.fromRGB(116, 130, 143),
    sliderIcon = Color3.fromRGB(86, 101, 114),
    primary = Color3.fromRGB(66, 214, 153),
    primarySoft = Color3.fromRGB(120, 230, 180),
    toggle = Color3.fromRGB(66, 214, 153),
    warning = Color3.fromRGB(239, 177, 72),
    warningSoft = Color3.fromRGB(251, 191, 36),
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
        return "Starting compatibility services and preparing the runtime."
    elseif string.find(lower, "cache setup", 1, true) then
        return "Checking local folders and previously downloaded components."
    elseif string.find(lower, "cache cleared", 1, true) then
        return "Removing outdated resources before loading the current build."
    elseif string.find(lower, "stale gui cache", 1, true) then
        return "Replacing an older interface build with the latest version."
    elseif string.find(lower, "self-test", 1, true) then
        return "Checking required services before the main runtime starts."
    elseif string.find(lower, "validating orchestrator", 1, true) then
        return "Confirming that the main startup source is available and valid."
    elseif string.find(lower, "url validation passed", 1, true) then
        return "The startup source is available and ready to compile."
    elseif string.find(lower, "compiled ok", 1, true) then
        return "The main runtime compiled successfully."
    elseif string.find(lower, "executing main", 1, true) then
        return "Starting the interface, modules, profiles, and game systems."
    elseif string.find(lower, "pipeline: validation", 1, true) then
        return "Reviewing startup results and checking for reported issues."
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
    local activeColor = isError and COLORS.warning or COLORS.primary
    local activeText = isError and COLORS.warningSoft or COLORS.text
    local thresholds = { 0.03, 0.36, 0.68, 0.96 }

    for index, marker in ipairs(phaseMarkers) do
        local active = progress >= thresholds[index]

        if marker.dot then
            loaderTween(marker.dot, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = active and activeColor or COLORS.element,
                BackgroundTransparency = active and 0 or 0.12,
            })
        end

        if marker.label then
            loaderTween(marker.label, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                TextColor3 = active and activeText or COLORS.placeholder,
                TextTransparency = active and 0 or 0.28,
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

    statusBackdrop = Instance.new("Frame")
    statusBackdrop.Name = "Backdrop"
    statusBackdrop.Size = UDim2.fromScale(1, 1)
    statusBackdrop.BackgroundColor3 = COLORS.backdrop
    statusBackdrop.BackgroundTransparency = 0.46
    statusBackdrop.BorderSizePixel = 0
    statusBackdrop.Parent = statusGui

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local loaderWidth = math.clamp(viewport.X - 28, 320, 560)
    local loaderHeight = math.clamp(viewport.Y - 40, 320, 340)

    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Position = UDim2.fromScale(0.5, 0.515)
    shadow.Size = UDim2.fromOffset(loaderWidth + 18, loaderHeight + 18)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.Parent = statusBackdrop
    loaderCorner(shadow, 18)

    statusCard = Instance.new("Frame")
    statusCard.Name = "Window"
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.Position = UDim2.fromScale(0.5, 0.514)
    statusCard.Size = UDim2.fromOffset(loaderWidth, loaderHeight)
    statusCard.BackgroundColor3 = COLORS.background
    statusCard.BackgroundTransparency = 0.005
    statusCard.BorderSizePixel = 0
    statusCard.ClipsDescendants = true
    statusCard.Parent = statusGui
    loaderCorner(statusCard, 18)
    statusCardStroke = loaderStroke(statusCard, COLORS.outline, 0.34, 1)

    statusCardScale = Instance.new("UIScale")
    statusCardScale.Name = "MotionScale"
    statusCardScale.Scale = 0.94
    statusCardScale.Parent = statusCard

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 64)
    topbar.BackgroundColor3 = Color3.fromRGB(8, 13, 18)
    topbar.BackgroundTransparency = 0
    topbar.BorderSizePixel = 0
    topbar.Parent = statusCard

    local appIcon = Instance.new("Frame")
    appIcon.Name = "Icon"
    appIcon.Position = UDim2.fromOffset(16, 14)
    appIcon.Size = UDim2.fromOffset(36, 36)
    appIcon.BackgroundColor3 = COLORS.element
    appIcon.BorderSizePixel = 0
    appIcon.Parent = topbar
    loaderCorner(appIcon, 10)
    loaderStroke(appIcon, COLORS.outline, 0.78, 1)

    local iconGlyph = Instance.new("TextLabel")
    iconGlyph.Name = "Glyph"
    iconGlyph.Size = UDim2.fromScale(1, 1)
    iconGlyph.BackgroundTransparency = 1
    iconGlyph.Font = Enum.Font.GothamBold
    iconGlyph.Text = "B"
    iconGlyph.TextSize = 17
    iconGlyph.TextColor3 = COLORS.text
    iconGlyph.Parent = appIcon

    local brand = Instance.new("TextLabel")
    brand.Name = "Title"
    brand.Position = UDim2.fromOffset(64, 13)
    brand.Size = UDim2.new(1, -190, 0, 21)
    brand.BackgroundTransparency = 1
    brand.Font = Enum.Font.GothamSemibold
    brand.Text = "BadWars"
    brand.TextSize = 15
    brand.TextColor3 = COLORS.text
    brand.TextXAlignment = Enum.TextXAlignment.Left
    brand.TextTruncate = Enum.TextTruncate.AtEnd
    brand.Parent = topbar

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Position = UDim2.fromOffset(64, 34)
    subtitle.Size = UDim2.new(1, -190, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "runtime loader"
    subtitle.TextSize = 10
    subtitle.TextColor3 = COLORS.placeholder
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    subtitle.Parent = topbar

    local statusChip = Instance.new("Frame")
    statusChip.Name = "Status"
    statusChip.AnchorPoint = Vector2.new(1, 0.5)
    statusChip.Position = UDim2.new(1, -16, 0.5, 0)
    statusChip.Size = UDim2.fromOffset(96, 28)
    statusChip.BackgroundColor3 = COLORS.accent
    statusChip.BorderSizePixel = 0
    statusChip.Parent = topbar
    loaderCorner(statusChip, 9)
    loaderStroke(statusChip, COLORS.outline, 0.78, 1)

    stateDot = Instance.new("Frame")
    stateDot.Name = "Dot"
    stateDot.AnchorPoint = Vector2.new(0, 0.5)
    stateDot.Position = UDim2.new(0, 11, 0.5, 0)
    stateDot.Size = UDim2.fromOffset(7, 7)
    stateDot.BackgroundColor3 = COLORS.primary
    stateDot.BorderSizePixel = 0
    stateDot.Parent = statusChip
    loaderCorner(stateDot, 99)

    statusChipText = Instance.new("TextLabel")
    statusChipText.Name = "Text"
    statusChipText.Position = UDim2.fromOffset(25, 0)
    statusChipText.Size = UDim2.new(1, -31, 1, 0)
    statusChipText.BackgroundTransparency = 1
    statusChipText.Font = Enum.Font.GothamSemibold
    statusChipText.Text = "LOADING"
    statusChipText.TextSize = 8
    statusChipText.TextColor3 = COLORS.text
    statusChipText.TextXAlignment = Enum.TextXAlignment.Left
    statusChipText.Parent = statusChip

    local topbarDivider = Instance.new("Frame")
    topbarDivider.Name = "Divider"
    topbarDivider.Position = UDim2.new(0, 0, 1, -1)
    topbarDivider.Size = UDim2.new(1, 0, 0, 1)
    topbarDivider.BackgroundColor3 = COLORS.outline
    topbarDivider.BackgroundTransparency = 0.66
    topbarDivider.BorderSizePixel = 0
    topbarDivider.Parent = topbar

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Position = UDim2.fromOffset(14, 76)
    content.Size = UDim2.new(1, -28, 1, -90)
    content.BackgroundColor3 = COLORS.dialog
    content.BorderSizePixel = 0
    content.Parent = statusCard
    loaderCorner(content, 12)
    loaderStroke(content, COLORS.outline, 0.66, 1)

    local statusPanel = Instance.new("Frame")
    statusPanel.Name = "CurrentStatus"
    statusPanel.Position = UDim2.fromOffset(12, 12)
    statusPanel.Size = UDim2.new(1, -24, 0, 78)
    statusPanel.BackgroundColor3 = COLORS.element
    statusPanel.BorderSizePixel = 0
    statusPanel.Parent = content
    loaderCorner(statusPanel, 10)

    local statusIcon = Instance.new("Frame")
    statusIcon.Name = "StatusIcon"
    statusIcon.Position = UDim2.fromOffset(12, 18)
    statusIcon.Size = UDim2.fromOffset(40, 40)
    statusIcon.BackgroundColor3 = COLORS.accent
    statusIcon.BorderSizePixel = 0
    statusIcon.Parent = statusPanel
    loaderCorner(statusIcon, 10)
    loaderStroke(statusIcon, COLORS.outline, 0.62, 1)

    statusAccent = Instance.new("Frame")
    statusAccent.Name = "Accent"
    statusAccent.AnchorPoint = Vector2.new(0.5, 0.5)
    statusAccent.Position = UDim2.fromScale(0.5, 0.5)
    statusAccent.Size = UDim2.fromOffset(10, 10)
    statusAccent.BackgroundColor3 = COLORS.primary
    statusAccent.BorderSizePixel = 0
    statusAccent.Parent = statusIcon
    loaderCorner(statusAccent, 99)

    statusTitle = Instance.new("TextLabel")
    statusTitle.Name = "Stage"
    statusTitle.Position = UDim2.fromOffset(64, 15)
    statusTitle.Size = UDim2.new(1, -76, 0, 21)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Font = Enum.Font.GothamSemibold
    statusTitle.Text = "Initializing"
    statusTitle.TextSize = 14
    statusTitle.TextColor3 = COLORS.text
    statusTitle.TextXAlignment = Enum.TextXAlignment.Left
    statusTitle.TextTruncate = Enum.TextTruncate.AtEnd
    statusTitle.Parent = statusPanel

    statusMessage = Instance.new("TextLabel")
    statusMessage.Name = "Description"
    statusMessage.Position = UDim2.fromOffset(64, 37)
    statusMessage.Size = UDim2.new(1, -76, 0, 29)
    statusMessage.BackgroundTransparency = 1
    statusMessage.Font = Enum.Font.Gotham
    statusMessage.Text = "Starting compatibility services and preparing the runtime."
    statusMessage.TextSize = 9
    statusMessage.TextColor3 = COLORS.placeholder
    statusMessage.TextXAlignment = Enum.TextXAlignment.Left
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextWrapped = true
    statusMessage.TextTruncate = Enum.TextTruncate.AtEnd
    statusMessage.Parent = statusPanel

    local progressArea = Instance.new("Frame")
    progressArea.Name = "ProgressArea"
    progressArea.Position = UDim2.fromOffset(12, 102)
    progressArea.Size = UDim2.new(1, -24, 0, 82)
    progressArea.BackgroundTransparency = 1
    progressArea.Parent = content

    local progressCaption = Instance.new("TextLabel")
    progressCaption.Name = "Caption"
    progressCaption.Size = UDim2.new(1, -60, 0, 17)
    progressCaption.BackgroundTransparency = 1
    progressCaption.Font = Enum.Font.GothamSemibold
    progressCaption.Text = "Loading"
    progressCaption.TextSize = 10
    progressCaption.TextColor3 = COLORS.text
    progressCaption.TextXAlignment = Enum.TextXAlignment.Left
    progressCaption.Parent = progressArea

    progressValue = Instance.new("TextLabel")
    progressValue.Name = "Value"
    progressValue.AnchorPoint = Vector2.new(1, 0)
    progressValue.Position = UDim2.new(1, 0, 0, 0)
    progressValue.Size = UDim2.fromOffset(54, 17)
    progressValue.BackgroundTransparency = 1
    progressValue.Font = Enum.Font.GothamSemibold
    progressValue.Text = "3%"
    progressValue.TextSize = 10
    progressValue.TextColor3 = COLORS.placeholder
    progressValue.TextXAlignment = Enum.TextXAlignment.Right
    progressValue.Parent = progressArea

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Position = UDim2.fromOffset(0, 26)
    track.Size = UDim2.new(1, 0, 0, 7)
    track.BackgroundColor3 = COLORS.element
    track.BorderSizePixel = 0
    track.ClipsDescendants = true
    track.Parent = progressArea
    loaderCorner(track, 99)

    progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.fromScale(statusProgress, 1)
    progressFill.BackgroundColor3 = COLORS.primary
    progressFill.BorderSizePixel = 0
    progressFill.Parent = track
    loaderCorner(progressFill, 99)

    local phases = Instance.new("Frame")
    phases.Name = "Phases"
    phases.Position = UDim2.fromOffset(0, 45)
    phases.Size = UDim2.new(1, 0, 0, 24)
    phases.BackgroundTransparency = 1
    phases.Parent = progressArea

    local phaseNames = { "Setup", "Verify", "Load", "Ready" }
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
        dot.Position = UDim2.fromOffset(0, 7)
        dot.Size = UDim2.fromOffset(6, 6)
        dot.BackgroundColor3 = index == 1 and COLORS.primary or COLORS.element
        dot.BackgroundTransparency = index == 1 and 0 or 0.12
        dot.BorderSizePixel = 0
        dot.Parent = holder
        loaderCorner(dot, 99)

        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Position = UDim2.fromOffset(12, 2)
        label.Size = UDim2.new(1, -14, 0, 17)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.Text = phaseName
        label.TextSize = 9
        label.TextColor3 = index == 1 and COLORS.text or COLORS.placeholder
        label.TextTransparency = index == 1 and 0 or 0.28
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = holder

        phaseMarkers[index] = {
            dot = dot,
            label = label,
        }
    end

    local footer = Instance.new("Frame")
    footer.Name = "Footer"
    footer.AnchorPoint = Vector2.new(0, 1)
    footer.Position = UDim2.new(0, 12, 1, -12)
    footer.Size = UDim2.new(1, -24, 0, 32)
    footer.BackgroundTransparency = 1
    footer.Parent = content

    local footerDivider = Instance.new("Frame")
    footerDivider.Name = "Divider"
    footerDivider.Size = UDim2.new(1, 0, 0, 1)
    footerDivider.BackgroundColor3 = COLORS.outline
    footerDivider.BackgroundTransparency = 0.66
    footerDivider.BorderSizePixel = 0
    footerDivider.Parent = footer

    statusMeta = Instance.new("TextLabel")
    statusMeta.Name = "Meta"
    statusMeta.Position = UDim2.fromOffset(0, 10)
    statusMeta.Size = UDim2.new(1, -150, 0, 18)
    statusMeta.BackgroundTransparency = 1
    statusMeta.Font = Enum.Font.Gotham
    statusMeta.Text = "secure startup"
    statusMeta.TextSize = 9
    statusMeta.TextColor3 = COLORS.placeholder
    statusMeta.TextXAlignment = Enum.TextXAlignment.Left
    statusMeta.TextTruncate = Enum.TextTruncate.AtEnd
    statusMeta.Parent = footer

    elapsedLabel = Instance.new("TextLabel")
    elapsedLabel.Name = "Elapsed"
    elapsedLabel.AnchorPoint = Vector2.new(1, 0)
    elapsedLabel.Position = UDim2.new(1, 0, 0, 10)
    elapsedLabel.Size = UDim2.fromOffset(70, 18)
    elapsedLabel.BackgroundTransparency = 1
    elapsedLabel.Font = Enum.Font.Code
    elapsedLabel.Text = "0.0s"
    elapsedLabel.TextSize = 9
    elapsedLabel.TextColor3 = COLORS.placeholder
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right
    elapsedLabel.Parent = footer

    openConsoleButton = Instance.new("TextButton")
    openConsoleButton.Name = "Diagnostics"
    openConsoleButton.AnchorPoint = Vector2.new(1, 0)
    openConsoleButton.Position = UDim2.new(1, 0, 0, 6)
    openConsoleButton.Size = UDim2.fromOffset(132, 26)
    openConsoleButton.BackgroundColor3 = COLORS.element
    openConsoleButton.BorderSizePixel = 0
    openConsoleButton.AutoButtonColor = false
    openConsoleButton.Font = Enum.Font.GothamSemibold
    openConsoleButton.Text = "Open diagnostics"
    openConsoleButton.TextSize = 9
    openConsoleButton.TextColor3 = COLORS.text
    openConsoleButton.Visible = false
    openConsoleButton.Parent = footer
    loaderCorner(openConsoleButton, 8)
    local consoleStroke = loaderStroke(openConsoleButton, COLORS.outline, 0.62, 1)

    openConsoleButton.MouseEnter:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.075, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.elementHover,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.075, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.44,
        })
    end)

    openConsoleButton.MouseLeave:Connect(function()
        loaderTween(openConsoleButton, TweenInfo.new(0.075, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.element,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.075, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.62,
        })
    end)

    openConsoleButton.Activated:Connect(function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    loaderTween(statusCard, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.fromScale(0.5, 0.5),
    })
    loaderTween(statusCardScale, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
            loaderTween(stateDot, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.42,
            })
            task.wait(0.67)
            loaderTween(stateDot, TweenInfo.new(0.65, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0,
            })
            task.wait(0.67)
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

    local activeColor = statusError and COLORS.warning or COLORS.primary
    local activeSoft = statusError and COLORS.warningSoft or COLORS.primarySoft

    if statusTitle then
        statusTitle.Text = statusError and "Startup needs attention" or friendlyStage(message)
        statusTitle.TextColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if statusMessage then
        statusMessage.Text = statusError
            and "BadWars could not finish startup. Open diagnostics to review the reported issue."
            or statusDetail(message)
        statusMessage.TextColor3 = COLORS.placeholder
    end

    if statusMeta then
        statusMeta.Text = statusError and "startup paused" or "secure startup"
    end

    if statusChipText then
        statusChipText.Text = statusError and "ATTENTION" or (terminal and "READY" or "LOADING")
        statusChipText.TextColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if stateDot then
        stateDot.BackgroundColor3 = activeColor
    end

    if statusAccent then
        statusAccent.BackgroundColor3 = activeColor
    end

    if statusCardStroke then
        statusCardStroke.Color = COLORS.outline
        statusCardStroke.Transparency = 0.34
    end

    if progressFill then
        progressFill.BackgroundColor3 = activeColor
        loaderTween(progressFill, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(math.clamp(statusProgress, 0.03, 1), 1),
        })
    end

    if progressValue then
        progressValue.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
        progressValue.TextColor3 = statusError and activeSoft or COLORS.placeholder
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
        local hold = math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.34

        task.delay(hold, function()
            if generation ~= loaderStatusGeneration
                or statusError
                or not statusGui
                or not statusGui.Parent
            then
                loaderDismissScheduled = false
                return
            end

            loaderTween(statusCard, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.fromScale(0.5, 0.49),
                BackgroundTransparency = 0.08,
            })
            loaderTween(statusCardScale, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Scale = 0.97,
            })
            loaderTween(statusBackdrop, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            })

            task.delay(0.22, function()
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
-- BADWARS_LOADER_PRESENTATION_V4_END
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

local cacheVersion = 'badwars-v16-windui-2026-07-08-03'
local cacheFile = 'badscript/profiles/cache-version.txt'
local function isCurrentGuiCache(contents)
    return type(contents) == "string"
        and contents:find("BADWARS_WINDUI_INTEGRATION", 1, true) ~= nil
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
