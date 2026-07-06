-- BADWARS_UI_V19_OBSIDIAN_OVERHAUL
-- BADWARS_UI_SEMANTIC_FIX_V2
-- BADWARS_LOCAL_REGISTER_REPAIR_V2
-- BADWARS_ADAPTIVE_UI_REWRITE_V1
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
-- BadWars Obsidian UI | adaptive, interruptible, low-overhead
local a = shared.BadWarsLoader
assert(a ~= nil and type(a) == "table", "[BadWars GUI]: BadWarsLoader is invalid :c")
local __guiwarn = warn
local GUI_VERBOSE_LOGS = false
local function bwarn(...)
    if GUI_VERBOSE_LOGS then
        __guiwarn(...)
    end
end
local b = a:setupDecoratedCustomSignal("GUILIBRARY_INTERNAL")
local c = function(c)
    return b(`TOGGLE_CUSTOM_SIGNAL_{tostring(c)}`)
end
local d = {
    GUIColor = {
        Hue = 0.46,
        Sat = 0.74,
        Value = 0.92,
    },
    HeldKeybinds = {},
    Keybind = { "RightShift" },
    Loaded = false,
    Libraries = {},
    Place = game.PlaceId,
    Profile = "default",
    Profiles = {},
    RainbowSpeed = { Value = 1 },
    RainbowUpdateSpeed = { Value = 45 },
    RainbowTable = {},
    Scale = { Value = 1 },
    ThreadFix = not shared.CheatEngineMode
            and setthreadidentity ~= nil
            and type(setthreadidentity) == "function"
            and true
        or false,
    ToggleNotifications = {},
    FavoriteNotifications = {},
    BindNotifications = {},
    Version = "19.0",
    PremiumBuild = "2026.07.06-V19-OBSIDIAN-OVERHAUL",
    Windows = {},
    Indicators = {},
    _PendingModuleCallbacks = 0,
    _InitialLayoutReady = false,
    _SuppressEntryAnimation = true,
    ProfilesEnabled = false,
    TutorialEnabled = false,
    MotionLibrary = shared.BadWarsSpr,
}
d.DefaultColor = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
for e, f in
    {
        "PreloadEvent",
        "GUIColorChanged",
        "SelfDestructEvent",
        "VisibilityChanged",
        "OnLoadEvent",
        "ProfileChangedEvent",
        "MainGuiSettingsOpenedEvent",
    }
do
    if d[f] then
        continue
    end
    d[f] = b(f)
end
for e, f in { "Categories", "Modules", "Overlays" } do
    if d[f] == nil then
        d[f] = {}
    end
end
d.libraries = setmetatable(d.Libraries, {
    __index = function(e, f)
        local g = d.Libraries[f]
        if g then
            rawset(e, f, g)
        end
        return g
    end,
    __newindex = function(e, f, g)
        if not d.Libraries[f] then
            d.Libraries[f] = g
        end
        rawset(e, f, g)
    end,
})
function d.connectOnLoad(e, f)
    e.loadconns = e.loadconns or {}
    if f == nil then
        return
    end
    if type(f) ~= "function" then
        return
    end
    if e.loadconns[tostring(f)] then
        return
    end
    e.loadconns[tostring(f)] = f
end
function d.onload(e)
    if not e.loadconns then
        return
    end
    e.ProfileChangedEvent:Fire()
    for f, g in e.loadconns do
        task.spawn(pcall, g, d)
        e.loadconns[f] = nil
    end
end

local e = cloneref or function(e)
    return e
end
local f = setmetatable({}, {
    __index = function(f, g)
        local h, i = pcall(function()
            local h = game:GetService(g)
            if not h then
                error(`Service {tostring(g)} not found!`)
                return
            end
            return e(h)
        end)
        if not h then
            a:report({
                type = "Services-gui-api",
                err = i,
                args = { g },
            })
        else
            rawset(f, g, i)
        end
        return h and i
    end,
})
local g = f.TweenService
local h = f.UserInputService
local i = f.TextService
local j = f.GuiService
local k = f.RunService
local l = f.HttpService

d.isMobile = h.TouchEnabled and not h.KeyboardEnabled

d.AliasesConfig = { KitESP = {
    "ElderESP",
    "OrbESP",
    "BeeESP",
    "MetalESP",
} }

local m = {}
local n = {
    tweens = {},
    tweenstwo = {},
    completionConnections = setmetatable({}, { __mode = "k" }),
    springProperties = setmetatable({}, { __mode = "k" }),
}
local baseFont = Font.fromEnum(Enum.Font.Gotham)
local o = {
    -- Obsidian design system: neutral graphite surfaces with a single live accent.
    Main = Color3.fromRGB(5, 8, 12),
    MainSoft = Color3.fromRGB(8, 12, 17),
    Text = Color3.fromRGB(218, 227, 235),
    TextStrong = Color3.fromRGB(248, 251, 253),
    Surface = Color3.fromRGB(13, 19, 25),
    SurfaceSoft = Color3.fromRGB(16, 23, 30),
    SurfaceHover = Color3.fromRGB(22, 32, 42),
    Elevated = Color3.fromRGB(18, 27, 35),
    ElevatedHover = Color3.fromRGB(27, 40, 51),
    Border = Color3.fromRGB(34, 47, 59),
    BorderStrong = Color3.fromRGB(67, 91, 108),
    MutedText = Color3.fromRGB(157, 174, 189),
    FaintText = Color3.fromRGB(92, 110, 126),
    Danger = Color3.fromRGB(255, 102, 124),
    Warning = Color3.fromRGB(255, 198, 92),
    Success = Color3.fromRGB(75, 222, 168),
    Shadow = Color3.fromRGB(0, 1, 3),
    RadiusSmall = UDim.new(0, 8),
    Radius = UDim.new(0, 12),
    RadiusLarge = UDim.new(0, 18),
    Font = baseFont,
    FontSemiBold = Font.new(baseFont.Family, Enum.FontWeight.SemiBold),
    FontBold = Font.new(baseFont.Family, Enum.FontWeight.Bold),
    TweenPress = TweenInfo.new(0.032, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    TweenFast = TweenInfo.new(0.055, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Tween = TweenInfo.new(0.085, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TweenSlow = TweenInfo.new(0.125, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TweenSpring = TweenInfo.new(0.105, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    TweenBack = TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    SpringInteractive = { Damping = 1, Frequency = 26, Public = false, TweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out) },
    SpringPanel = { Damping = 1, Frequency = 22, Public = true },
    SpringSoft = { Damping = 0.98, Frequency = 19, Public = true },
}

local UI_WINDOW_WIDTH = d.isMobile and 268 or 282
local UI_HEADER_HEIGHT = d.isMobile and 56 or 58
local UI_MODULE_ROW_HEIGHT = d.isMobile and 54 or 48
local UI_NAV_ROW_HEIGHT = d.isMobile and 52 or 46
local UI_WINDOW_GAP = 16

local function getTableSize(p)
    if type(p) ~= "table" then
        return 0
    end
    local q = 0
    for r in p do
        q += 1
    end
    return q
end

local function loopClean(p, q)
    if type(p) ~= "table" then
        return
    end
    q = q or {}
    if q[p] then
        return
    end
    q[p] = true

    local r = {
        ModuleCategory = true,
        CategoryApi = true,
    }

    for s, t in pairs(p) do
        if not r[s] and type(t) == "table" then
            loopClean(t, q)
        end
        p[s] = nil
    end
end

local function addMaid(p)
    p.Connections = {}
    p._maidSeen = setmetatable({}, { __mode = "k" })
    p._maidCleaning = false

    local function createCleanupHandle(resource)
        local cleaned = false
        return {
            Disconnect = function()
                if cleaned then
                    return
                end
                cleaned = true

                local resourceType = typeof(resource)
                if resourceType == "RBXScriptConnection" then
                    if resource.Connected then
                        resource:Disconnect()
                    end
                elseif resourceType == "Instance" then
                    resource:Destroy()
                elseif resourceType == "thread" then
                    pcall(task.cancel, resource)
                elseif type(resource) == "function" then
                    resource()
                elseif type(resource) == "table" or type(resource) == "userdata" then
                    local method = resource.Disconnect or resource.Destroy or resource.Cleanup or resource.Clean
                    if type(method) == "function" then
                        method(resource)
                    end
                end
            end,
        }
    end

    function p.Clean(owner, resource)
        if resource == nil then
            return nil
        end

        local resourceType = typeof(resource)
        local supported = resourceType == "RBXScriptConnection"
            or resourceType == "Instance"
            or resourceType == "thread"
            or type(resource) == "function"
            or type(resource) == "table"
            or type(resource) == "userdata"
        if not supported then
            return resource
        end

        if owner._maidSeen[resource] then
            return resource
        end
        owner._maidSeen[resource] = true

        table.insert(owner.Connections, createCleanupHandle(resource))
        return resource
    end

    function p.Cleanup(owner)
        if owner._maidCleaning then
            return
        end
        owner._maidCleaning = true

        local handles = owner.Connections
        owner.Connections = {}
        for index = #handles, 1, -1 do
            pcall(function()
                handles[index]:Disconnect()
            end)
            handles[index] = nil
        end

        owner._maidSeen = setmetatable({}, { __mode = "k" })
        owner._maidCleaning = false
    end
end
addMaid(d)

local function connectDeferredPropertyChanged(instance, propertyName, callback, delaySeconds)
    local queued = false
    local running = false
    delaySeconds = tonumber(delaySeconds) or 0.03

    local function run()
        if running then
            queued = true
            return
        end
        running = true
        local ok, err = xpcall(callback, function(callbackError)
            if debug and type(debug.traceback) == "function" then
                return debug.traceback(tostring(callbackError), 2)
            end
            return tostring(callbackError)
        end)
        running = false
        if not ok then
            a:report({
                type = "gui-deferred-property",
                err = err,
                args = { tostring(propertyName), tostring(instance) },
                notifyBlacklisted = true,
            })
        end
        if queued then
            queued = false
            task.delay(delaySeconds, run)
        end
    end

    return instance:GetPropertyChangedSignal(propertyName):Connect(function()
        if queued then
            return
        end
        queued = true
        task.delay(delaySeconds, function()
            queued = false
            run()
        end)
    end)
end

local function loadJson(p, q)
    local r, s = pcall(function()
        local r = q and p or readfile(p)
        return l:JSONDecode(r)
    end)
    return r and type(s) == "table" and s or nil
end

local function decode(p)
    return loadJson(p, true)
end

local function encode(p)
    local q, r = pcall(function()
        return l:JSONEncode(p)
    end)
    if not q then
        bwarn(`[encode]: {tostring(r)}`)
    end
    return q and r
end

local activeTextFlickers = setmetatable({}, { __mode = "k" })
local activeImageFlickers = setmetatable({}, { __mode = "k" })

local function flickerTextEffect(p, q, r)
    if not p or not p.Parent then
        return
    end
    local previous = activeTextFlickers[p]
    if previous then
        pcall(task.cancel, previous)
    end

    activeTextFlickers[p] = task.spawn(function()
        if q == true and p.Parent and p.TextTransparency == 0 then
            n:Tween(p, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                TextTransparency = 1,
            })
            task.wait(0.12)
        end
        if not p.Parent then
            return
        end
        if r ~= nil then
            p.Text = r
        end
        n:Tween(p, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = q and 0 or 1,
        })
        activeTextFlickers[p] = nil
    end)
end

local function flickerImageEffect(p, q, r)
    if not p or not (p:IsA("ImageButton") or p:IsA("ImageLabel")) then
        return
    end

    q = math.max(tonumber(q) or 0.5, 0)
    r = math.max(tonumber(r) or 0.15, 0.03)

    local previous = activeImageFlickers[p]
    if previous then
        pcall(previous.cleanup)
    end

    local originalColor = p.ImageColor3
    local originalTransparency = p.ImageTransparency
    local scale = Instance.new("UIScale")
    scale.Name = "BadWarsFlickerScale"
    scale.Scale = 1
    scale.Parent = p

    local finished = false
    local thread
    local function cleanup()
        if finished then
            return
        end
        finished = true
        if thread and coroutine.running() ~= thread then
            pcall(task.cancel, thread)
        end
        if p and p.Parent then
            pcall(function()
                p.ImageColor3 = originalColor
                p.ImageTransparency = originalTransparency
            end)
        end
        if scale and scale.Parent then
            pcall(function()
                scale:Destroy()
            end)
        end
        activeImageFlickers[p] = nil
    end

    activeImageFlickers[p] = { cleanup = cleanup }
    thread = task.spawn(function()
        n:Tween(scale, TweenInfo.new(r, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.14 })
        local started = os.clock()
        while not finished and p.Parent and os.clock() - started < q do
            n:Tween(p, TweenInfo.new(r, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = 0,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
            })
            task.wait(r)
            if finished or not p.Parent then
                break
            end
            n:Tween(p, TweenInfo.new(r, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                ImageTransparency = originalTransparency,
                ImageColor3 = originalColor,
            })
            task.wait(r)
        end

        if not finished and scale.Parent then
            n:Tween(scale, TweenInfo.new(r, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
            task.wait(r)
        end
        cleanup()
    end)
end

local function Color3ToHex(p)
    local q = math.floor(p.R * 255)
    local r = math.floor(p.G * 255)
    local s = math.floor(p.B * 255)
    return string.format("#%02x%02x%02x", q, r, s)
end

local function hsv(p, q, r)
    local s, t = pcall(function()
        return Color3.fromHSV(p, q, r)
    end)
    return s, t
end

local function str(p)
    return tostring(p)
end

local function tblcheck(p)
    return (p ~= nil and type(p) == "table")
end

local function num(p)
    if p == nil then
        return p
    end
    return tonumber(p)
end

local function count(p)
    if type(p) ~= "table" then
        return 0
    end
    local q = 0
    for r, s in p do
        q = q + 1
    end
    return q
end

local function wrap(p)
    return a:wrap(p, {
        name = "wrap:api",
    })
end
d.wrap = wrap

local function connectDoubleClick(p, q, s)
    local t = 0
    s = s or 0.25
    if not (q ~= nil and type(q) == "function") then
        q = function() end
    else
        d.wrap(q)
    end

    p.Activated:Connect(function()
        local u = tick()
        if u - t <= s then
            q()
        end

        t = u
    end)
end
d.connectDoubleClick = connectDoubleClick

function d.SetAliases(p, q, s)
    local t = p.Modules[q]
    if not t then
        p.AliasesConfig[q] = s
        return
    end
    t.Aliases = s
    t.SearchKeys = { t.Name }
    for u, v in s do
        table.insert(t.SearchKeys, v)
    end
end

local function connectguicolorchange(p, q)
    p = wrap(p)
    local s
    if type(p) == "function" then
        p(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        s = d.GUIColorChanged.Event:Connect(p)
    else
        p.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        s = d.GUIColorChanged.Event:Connect(function(t, u, v)
            p.BackgroundColor3 = Color3.fromHSV(t, u, v)
        end)
    end
    if q and type(p) == "function" then
        d:Clean(s)
        return {
            run = function()
                p(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            end,
            conn = s,
        }
    end
    return s
end
d.connectguicolorchange = connectguicolorchange

d.GuiColorSyncAPI = {}
function d.setupguicolorsync(p, q, s, t)
    if not (t ~= nil and type(t) == "function") then
        t = function() end
    else
        t = wrap(t)
    end
    if not tblcheck(q) then
        a:throw(`[setupguicolorsync]: api invalid! {tostring(q)}`)
        return
    end
    if not (tblcheck(s) and tblcheck(s.Color1)) then
        a:throw(`[setupguicolorsync]: options invalid! {tostring(s)}`)
        return
    end

    local u, v, w = s.Color1, s.Color2, s.Color3
    local x = false

    local y = function() end

    local z
    q.Name = q.Name or l:GenerateGUID(false)
    z = p.GuiColorSyncAPI[q.Name]
        or q:CreateToggle({
            Name = "GUI Color Sync",
            Function = function(A)
                t(A)
                if A then
                    y()
                end
            end,
            Tooltip = s.Tooltip or "Syncs with the gui theme color",
            Default = s.Default,
        })
    p.GuiColorSyncAPI[q.Name] = z

    for A, B in { u, v, w } do
        B:ConnectCallback(function()
            if z.Enabled and not x then
                if p.CreateNotification then
                    p:CreateNotification(
                        `GUI Sync - {q.Name}`,
                        "GUI color sync was disabled because a linked color was changed manually.",
                        5,
                        "info"
                    )
                end
                z:Toggle()
            end
        end)
    end

    y = connectguicolorchange(function(A, B, C)
        if not z.Enabled then
            return
        end
        local D = { Hue = A, Sat = B, Value = C }

        x = true

        if w then
            local E = D

            if s.Color1HueShift then
                local F = (A + s.Color1HueShift) % 1
                E = { Hue = F, Sat = B, Value = C }
            end
            local F = (A + (s.Color2HueShift or 0.1)) % 1
            local G = (A + (s.Color3HueShift or 0.2)) % 1
            local H = { Hue = F, Sat = B, Value = C }
            local I = { Hue = G, Sat = B, Value = C }

            u:SetValue(E.Hue, E.Sat, E.Value)
            v:SetValue(H.Hue, H.Sat, H.Value)
            w:SetValue(I.Hue, I.Sat, I.Value)
        elseif v then
            local E = D
            local F = (A + (s.Color2HueShift or 0.1)) % 1
            local G = { Hue = F, Sat = B, Value = C }

            u:SetValue(E.Hue, E.Sat, E.Value)
            v:SetValue(G.Hue, G.Sat, G.Value)
        else
            if s.Color1HueShift then
                local E = (A + s.Color1HueShift) % 1
                D = { Hue = E, Sat = B, Value = C }
            end
            u:SetValue(D.Hue, D.Sat, D.Value)
        end

        x = false
    end, true).run

    return z
end

local function connectvisibilitychange(p)
    return d.VisibilityChanged.Event:Connect(p)
end
d.connectvisibilitychange = connectvisibilitychange

local p = Instance.new("GetTextBoundsParams")
p.Width = math.huge
local q
local s
local t = getcustomasset
local u
local v
local w
local x
local y
local z
local tooltipStroke
local tooltipScale
local tooltipAccent
local tooltipFollowConnection
local tooltipGeneration = 0
local tooltipTarget
local A
local B

local C = {
    ["badscript/assets/new/add.png"] = "rbxassetid://14368300605",
    ["badscript/assets/new/alert.png"] = "rbxassetid://14368301329",
    ["badscript/assets/new/allowedicon.png"] = "rbxassetid://14368302000",
    ["badscript/assets/new/allowedtab.png"] = "rbxassetid://14368302875",
    ["badscript/assets/new/arrowmodule.png"] = "rbxassetid://14473354880",
    ["badscript/assets/new/back.png"] = "rbxassetid://14368303894",
    ["badscript/assets/new/bind.png"] = "rbxassetid://14368304734",
    ["badscript/assets/new/bindbkg.png"] = "rbxassetid://14368305655",
    ["badscript/assets/new/blatanticon.png"] = "rbxassetid://14368306745",
    ["badscript/assets/new/blockedicon.png"] = "rbxassetid://14385669108",
    ["badscript/assets/new/blockedtab.png"] = "rbxassetid://14385672881",
    ["badscript/assets/new/blur.png"] = "rbxassetid://14898786664",
    ["badscript/assets/new/blurnotif.png"] = "rbxassetid://16738720137",
    ["badscript/assets/new/close.png"] = "rbxassetid://14368309446",
    ["badscript/assets/new/closemini.png"] = "rbxassetid://14368310467",
    ["badscript/assets/new/colorpreview.png"] = "rbxassetid://14368311578",
    ["badscript/assets/new/combaticon.png"] = "rbxassetid://14368312652",
    ["badscript/assets/new/customsettings.png"] = "rbxassetid://14403726449",
    ["badscript/assets/new/discord.png"] = "",
    ["badscript/assets/new/dots.png"] = "rbxassetid://14368314459",
    ["badscript/assets/new/edit.png"] = "rbxassetid://14368315443",
    ["badscript/assets/new/expandicon.png"] = "rbxassetid://14368353032",
    ["badscript/assets/new/expandright.png"] = "rbxassetid://14368316544",
    ["badscript/assets/new/expandup.png"] = "rbxassetid://14368317595",
    ["badscript/assets/new/friendstab.png"] = "rbxassetid://14397462778",
    ["badscript/assets/new/guisettings.png"] = "rbxassetid://14368318994",
    ["badscript/assets/new/guislider.png"] = "rbxassetid://14368320020",
    ["badscript/assets/new/guisliderrain.png"] = "rbxassetid://14368321228",
    ["badscript/assets/new/guiv4.png"] = "rbxassetid://14368322199",
    ["badscript/assets/new/guivape.png"] = "rbxassetid://14657521312",
    ["badscript/assets/new/info.png"] = "rbxassetid://14368324807",
    ["badscript/assets/new/inventoryicon.png"] = "rbxassetid://14928011633",
    ["badscript/assets/new/legit.png"] = "rbxassetid://14425650534",
    ["badscript/assets/new/legittab.png"] = "rbxassetid://14426740825",
    ["badscript/assets/new/miniicon.png"] = "rbxassetid://14368326029",
    ["badscript/assets/new/notification.png"] = "rbxassetid://16738721069",
    ["badscript/assets/new/overlaysicon.png"] = "rbxassetid://14368339581",
    ["badscript/assets/new/overlaystab.png"] = "rbxassetid://14397380433",
    ["badscript/assets/new/pin.png"] = "rbxassetid://14368342301",
    ["badscript/assets/new/profilesicon.png"] = "rbxassetid://14397465323",
    ["badscript/assets/new/radaricon.png"] = "rbxassetid://14368343291",
    ["badscript/assets/new/rainbow_1.png"] = "rbxassetid://14368344374",
    ["badscript/assets/new/rainbow_2.png"] = "rbxassetid://14368345149",
    ["badscript/assets/new/rainbow_3.png"] = "rbxassetid://14368345840",
    ["badscript/assets/new/rainbow_4.png"] = "rbxassetid://14368346696",
    ["badscript/assets/new/range.png"] = "rbxassetid://14368347435",
    ["badscript/assets/new/rangearrow.png"] = "rbxassetid://14368348640",
    ["badscript/assets/new/rendericon.png"] = "rbxassetid://14368350193",
    ["badscript/assets/new/rendertab.png"] = "rbxassetid://14397373458",
    ["badscript/assets/new/search.png"] = "rbxassetid://14425646684",
    ["badscript/assets/new/targetinfoicon.png"] = "rbxassetid://14368354234",
    ["badscript/assets/new/targetnpc1.png"] = "rbxassetid://14497400332",
    ["badscript/assets/new/targetnpc2.png"] = "rbxassetid://14497402744",
    ["badscript/assets/new/targetplayers1.png"] = "rbxassetid://14497396015",
    ["badscript/assets/new/targetplayers2.png"] = "rbxassetid://14497397862",
    ["badscript/assets/new/targetstab.png"] = "rbxassetid://14497393895",
    ["badscript/assets/new/textguiicon.png"] = "rbxassetid://14368355456",
    ["badscript/assets/new/textv4.png"] = "rbxassetid://14368357095",
    ["badscript/assets/new/textvape.png"] = "rbxassetid://14368358200",
    ["badscript/assets/new/utilityicon.png"] = "rbxassetid://14368359107",
    ["badscript/assets/new/vape.png"] = "rbxassetid://14373395239",
    ["badscript/assets/new/warning.png"] = "rbxassetid://14368361552",
    ["badscript/assets/new/worldicon.png"] = "rbxassetid://14368362492",
    ["badscript/assets/new/star.png"] = "rbxassetid://137405505909578",
}

local D = isfile
    or function(D)
        local E, F = pcall(function()
            return readfile(D)
        end)
        return E and F ~= nil and F ~= ""
    end


local fileIOState = {
    failures = 0,
    blockedUntil = 0,
    lastReport = {},
    warnedUnavailable = false,
}

local function ensureFolderTree(path)
    if type(makefolder) ~= "function" then
        return false
    end

    local folder = tostring(path or ""):match("^(.*)[/\\][^/\\]+$")
    if not folder or folder == "" then
        return true
    end

    local current = ""
    for segment in folder:gmatch("[^/\\]+") do
        current = current == "" and segment or (current .. "/" .. segment)
        local exists = false
        if type(isfolder) == "function" then
            local ok, result = pcall(isfolder, current)
            exists = ok and result == true
        end
        if not exists then
            local ok = pcall(makefolder, current)
            if not ok then
                return false
            end
        end
    end

    return true
end

local function reportFileIssue(path, err, context)
    local now = os.clock()
    local key = tostring(path) .. "\31" .. tostring(err)
    local last = fileIOState.lastReport[key] or 0
    if now - last < 12 then
        return
    end
    fileIOState.lastReport[key] = now

    local diagnostics = shared.BadDiagnostics
    if type(diagnostics) == "table" and type(diagnostics.Warn) == "function" then
        diagnostics:Warn(
            "File write skipped: " .. tostring(path),
            {
                subsystem = "GUIFileSystem",
                file = tostring(path),
                stage = tostring(context or "runtime"),
                details = tostring(err),
                native = false,
            }
        )
    elseif GUI_VERBOSE_LOGS then
        bwarn("[BadWars FileSystem]", tostring(path), tostring(err))
    end
end

local function safeWriteFile(path, contents, context)
    path = tostring(path or "")
    if path == "" then
        return false, "empty path"
    end

    local now = os.clock()
    if now < fileIOState.blockedUntil then
        return false, "file writes temporarily paused"
    end

    if type(writefile) ~= "function" then
        if not fileIOState.warnedUnavailable then
            fileIOState.warnedUnavailable = true
            reportFileIssue(path, "writefile is unavailable", context)
        end
        return false, "writefile is unavailable"
    end

    ensureFolderTree(path)

    local ok, err = pcall(writefile, path, tostring(contents or ""))
    if ok then
        fileIOState.failures = 0
        fileIOState.blockedUntil = 0
        return true
    end

    fileIOState.failures += 1
    if fileIOState.failures >= 2 then
        fileIOState.blockedUntil = now + 30
    end

    reportFileIssue(path, err, context)
    return false, tostring(err)
end

d.SafeWriteFile = safeWriteFile

local E = function(E, F, G, H)
    local fontSize = tonumber(F) or 14
    if fontSize ~= fontSize or fontSize <= 0 or fontSize == math.huge or fontSize == -math.huge then
        fontSize = 14
    end

    local maxWidth = tonumber(H) or math.huge
    if maxWidth ~= maxWidth or maxWidth <= 0 then
        maxWidth = math.huge
    end

    local ok, text = pcall(tostring, E or "")
    if not ok or type(text) ~= "string" then
        text = ""
    end

    local averageGlyphWidth = fontSize * 0.56
    local unwrappedWidth = math.max(1, #text * averageGlyphWidth)
    local width = maxWidth == math.huge and unwrappedWidth or math.min(maxWidth, math.max(1, unwrappedWidth))
    local wrappedLines = 1
    if maxWidth ~= math.huge and maxWidth > 0 then
        local charsPerLine = math.max(1, math.floor(maxWidth / averageGlyphWidth))
        wrappedLines = math.max(1, math.ceil(#text / charsPerLine))
    end

    local height = math.max(fontSize, wrappedLines * fontSize * 1.22)

    if type(Vector2) == "table" and type(Vector2.new) == "function" then
        return Vector2.new(width, height)
    end
    return { X = width, Y = height }
end
local function addCorner(F, G)
    local H = F:FindFirstChildOfClass("UICorner")
    if not H then
        H = Instance.new("UICorner")
        H.Parent = F
    end
    H.CornerRadius = G or o.Radius
    return H
end

local function addStroke(F, G, H, I, J)
    local K
    if J then
        K = F:FindFirstChild(J)
    end
    if not K or not K:IsA("UIStroke") then
        K = Instance.new("UIStroke")
        K.Name = J or "Stroke"
        K.Parent = F
    end
    K.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    K.LineJoinMode = Enum.LineJoinMode.Round
    K.Color = G or o.Border
    K.Transparency = H == nil and 0.7 or H
    K.Thickness = I or 1
    return K
end

local function addScale(F)
    local G = F:FindFirstChild("InteractionScale")
    if not G or not G:IsA("UIScale") then
        G = Instance.new("UIScale")
        G.Name = "InteractionScale"
        G.Scale = 1
        G.Parent = F
    end
    return G
end

local function addShadow(F, G)
    local H = F:FindFirstChild("SoftShadow")
    if H and H:IsA("ImageLabel") then
        return H
    end

    H = Instance.new("ImageLabel")
    H.Name = "SoftShadow"
    H.Size = UDim2.new(1, G and 26 or 20, 1, G and 26 or 20)
    H.Position = UDim2.fromOffset(G and -13 or -10, G and -13 or -10)
    H.BackgroundTransparency = 1
    H.Image = u("badscript/assets/new/" .. (G and "blurnotif" or "blur") .. ".png")
    H.ImageColor3 = o.Shadow
    H.ImageTransparency = G and 0.72 or 0.78
    H.ScaleType = Enum.ScaleType.Slice
    H.SliceCenter = Rect.new(52, 31, 261, 502)
    H.ZIndex = math.max(F.ZIndex - 1, 0)
    H.Parent = F
    return H
end

local function addBlur(F, G)
    return addShadow(F, G)
end

local function getV9AccentPair()
    local primary = Color3.fromHSV(
        d.GUIColor.Hue,
        d.GUIColor.Sat,
        d.GUIColor.Value
    )
    local secondary = primary:Lerp(Color3.fromRGB(103, 132, 168), 0.62)
    return primary, secondary
end

local function addSurfaceGradient(F, G)
    local H = F:FindFirstChild("SurfaceGradient")
    if not H or not H:IsA("UIGradient") then
        H = Instance.new("UIGradient")
        H.Name = "SurfaceGradient"
        H.Parent = F
    end

    H.Color = G
        or ColorSequence.new({
            ColorSequenceKeypoint.new(0, o.SurfaceSoft),
            ColorSequenceKeypoint.new(0.44, o.Surface),
            ColorSequenceKeypoint.new(1, o.MainSoft),
        })
    H.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.01),
        NumberSequenceKeypoint.new(0.5, 0.045),
        NumberSequenceKeypoint.new(1, 0.18),
    })
    H.Rotation = 112
    return H
end

local function addAccentLine(F, G)
    local H = F:FindFirstChild("AccentLine")
    if not H or not H:IsA("Frame") then
        H = Instance.new("Frame")
        H.Name = "AccentLine"
        H.BorderSizePixel = 0
        H.ZIndex = F.ZIndex + 4
        H.Parent = F
        addCorner(H, UDim.new(1, 0))

        connectguicolorchange(function()
            if H.Parent then
                H.BackgroundColor3 = Color3.fromHSV(
                    d.GUIColor.Hue,
                    d.GUIColor.Sat,
                    d.GUIColor.Value
                )
            end
        end)
    end

    H.Size = UDim2.fromOffset(46, G or 2)
    H.Position = UDim2.fromOffset(16, 1)
    H.BackgroundColor3 = Color3.fromHSV(
        d.GUIColor.Hue,
        d.GUIColor.Sat,
        d.GUIColor.Value
    )
    H.BackgroundTransparency = 0.08
    return H
end

local function addV9Chrome(F, label)
    -- Quiet inner chrome: one highlight and one depth edge, with no animated clutter.
    local top = F:FindFirstChild("ObsidianTopEdge")
    if not top then
        top = Instance.new("Frame")
        top.Name = "ObsidianTopEdge"
        top.Size = UDim2.new(1, -24, 0, 1)
        top.Position = UDim2.fromOffset(12, 1)
        top.BackgroundColor3 = o.TextStrong
        top.BackgroundTransparency = 0.91
        top.BorderSizePixel = 0
        top.ZIndex = F.ZIndex + 3
        top.Parent = F
    end

    local bottom = F:FindFirstChild("ObsidianDepthEdge")
    if not bottom then
        bottom = Instance.new("Frame")
        bottom.Name = "ObsidianDepthEdge"
        bottom.AnchorPoint = Vector2.new(0, 1)
        bottom.Position = UDim2.new(0, 12, 1, -1)
        bottom.Size = UDim2.new(1, -24, 0, 1)
        bottom.BackgroundColor3 = o.Shadow
        bottom.BackgroundTransparency = 0.34
        bottom.BorderSizePixel = 0
        bottom.ZIndex = F.ZIndex + 3
        bottom.Parent = F
    end

    return top
end

local function addV9Sweep(F)
    return nil
end

local function playV9Sweep(sweep)
    return
end

local function bindPremiumMotion(F, G, H, I)
    if not F:IsA("GuiButton") or F:GetAttribute("PremiumMotion") then
        return
    end
    F:SetAttribute("PremiumMotion", true)

    local J = addScale(G or F)
    local K = H
    local L = I or {}
    local hovered = false
    local pressed = false

    local function updateMotion()
        local targetScale
        if pressed then
            targetScale = L.PressScale or 0.985
        elseif hovered then
            targetScale = L.HoverScale or 1.004
        else
            targetScale = 1
        end

        n:Spring(J, o.SpringInteractive, {
            Scale = targetScale,
        })

        if K then
            n:Tween(K, o.TweenFast, {
                Color = hovered
                        and (L.HoverStroke or Color3.fromHSV(
                            d.GUIColor.Hue,
                            d.GUIColor.Sat,
                            d.GUIColor.Value
                        ))
                    or (L.NormalStroke or o.Border),
                Transparency = hovered
                        and (L.HoverTransparency or 0.28)
                    or (L.NormalTransparency or 0.68),
            })
        end
    end

    F.MouseEnter:Connect(function()
        hovered = true
        updateMotion()
    end)

    F.MouseLeave:Connect(function()
        hovered = false
        pressed = false
        updateMotion()
    end)

    F.MouseButton1Down:Connect(function()
        pressed = true
        updateMotion()
    end)

    F.MouseButton1Up:Connect(function()
        pressed = false
        updateMotion()
    end)
end

local function addCloseButton(F, G)
    local H = Instance.new("ImageButton")
    H.Name = "Close"
    H.Size = UDim2.fromOffset(27, 27)
    H.Position = UDim2.new(1, -38, 0, G or 8)
    H.BackgroundColor3 = o.Danger
    H.BackgroundTransparency = 0.88
    H.BorderSizePixel = 0
    H.AutoButtonColor = false
    H.Image = u("badscript/assets/new/close.png")
    H.ImageColor3 = o.MutedText
    H.ImageTransparency = 0.04
    H.Parent = F
    addCorner(H, o.RadiusSmall)
    local I = addStroke(H, o.Danger, 0.72, 1, "CloseStroke")
    bindPremiumMotion(H, H, I, {
        HoverScale = 1.04,
        PressScale = 0.94,
        HoverStroke = o.Danger,
        NormalStroke = o.Danger,
        HoverTransparency = 0.22,
        NormalTransparency = 0.72,
    })

    H.MouseEnter:Connect(function()
        n:Tween(H, o.TweenFast, {
            BackgroundTransparency = 0.72,
            ImageColor3 = o.TextStrong,
        })
    end)
    H.MouseLeave:Connect(function()
        n:Tween(H, o.TweenFast, {
            BackgroundTransparency = 0.88,
            ImageColor3 = o.MutedText,
        })
    end)

    return H
end

local getGuiScale
local clampGuiObjectToViewport
local setGuiAbsolutePosition

local function isEffectivelyVisible(target)
    local current = target
    while current and current ~= B do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end
    return target ~= nil and target.Parent ~= nil
end

local function tooltipInterfaceVisible()
    if v and v.Visible then
        return true
    end

    for _, window in ipairs(d.Windows) do
        if
            typeof(window) == "Instance"
            and window:IsA("GuiObject")
            and window.Visible
        then
            return true
        end
    end

    return false
end

local function stopTooltipFollow()
    if tooltipFollowConnection then
        tooltipFollowConnection:Disconnect()
        tooltipFollowConnection = nil
    end
end

local function getTooltipPosition()
    if not z or not z.Parent then
        return nil
    end

    local scale = getGuiScale()
    local viewport =
        (B and B.AbsoluteSize or workspace.CurrentCamera.ViewportSize)
        / scale
    local mouse = h:GetMouseLocation() / scale
    local width = z.Size.X.Offset
    local height = z.Size.Y.Offset
    local padding = 10
    local gap = 14

    local desiredX = mouse.X + gap
    if desiredX + width > viewport.X - padding then
        desiredX = mouse.X - width - gap
    end

    local desiredY = mouse.Y + 10
    if desiredY + height > viewport.Y - padding then
        desiredY = mouse.Y - height - 10
    end

    return UDim2.fromOffset(
        math.clamp(
            desiredX,
            padding,
            math.max(padding, viewport.X - width - padding)
        ),
        math.clamp(
            desiredY,
            padding,
            math.max(padding, viewport.Y - height - padding)
        )
    )
end

local function positionTooltip(smooth)
    if not z or not z.Parent or not z.Visible then
        return
    end

    local targetPosition = getTooltipPosition()
    if not targetPosition then
        return
    end

    if smooth then
        z.Position = UDim2.fromOffset(
            z.Position.X.Offset
                + ((targetPosition.X.Offset - z.Position.X.Offset) * 0.48),
            z.Position.Y.Offset
                + ((targetPosition.Y.Offset - z.Position.Y.Offset) * 0.48)
        )
    else
        z.Position = targetPosition
    end
end

local function ensureTooltipFollow()
    if tooltipFollowConnection then
        return
    end

    tooltipFollowConnection = k.RenderStepped:Connect(function()
        local target = tooltipTarget

        if
            not target
            or not target.Parent
            or not isEffectivelyVisible(target)
            or not tooltipInterfaceVisible()
            or d.TooltipsEnabled == false
        then
            if z and z.Visible then
                z.Visible = false
            end
            d._tooltipOwner = nil
            tooltipTarget = nil
            stopTooltipFollow()
            return
        end

        positionTooltip(true)
    end)
end

local function hideTooltip(immediate)
    tooltipGeneration += 1
    d._tooltipOwner = nil
    tooltipTarget = nil

    if not z or not z.Parent then
        stopTooltipFollow()
        return
    end

    local generation = tooltipGeneration

    if immediate or not d.Loaded then
        stopTooltipFollow()
        z.Visible = false
        z.TextTransparency = 1
        z.BackgroundTransparency = 1

        if tooltipStroke then
            tooltipStroke.Transparency = 1
        end
        if y then
            y.ImageTransparency = 1
        end
        if tooltipAccent then
            tooltipAccent.BackgroundTransparency = 1
        end
        if tooltipScale then
            tooltipScale.Scale = 0.99
        end
        return
    end

    local transition = TweenInfo.new(
        0.045,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.In
    )

    local fadeTween = n:Tween(z, transition, {
        TextTransparency = 1,
        BackgroundTransparency = 1,
    })

    if tooltipStroke then
        n:Tween(tooltipStroke, transition, {
            Transparency = 1,
        })
    end

    if y then
        n:Tween(y, transition, {
            ImageTransparency = 1,
        })
    end

    if tooltipAccent then
        n:Tween(tooltipAccent, transition, {
            BackgroundTransparency = 1,
        })
    end

    if tooltipScale then
        n:Tween(tooltipScale, transition, {
            Scale = 0.99,
        })
    end

    local function finishHide()
        if
            generation == tooltipGeneration
            and d._tooltipOwner == nil
            and z
            and z.Parent
        then
            z.Visible = false
            stopTooltipFollow()
        end
    end

    if fadeTween then
        fadeTween.Completed:Once(finishHide)
    else
        task.delay(0.05, finishHide)
    end
end

d.HideTooltip = hideTooltip

local function showTooltip(ownerToken, target, tooltipText)
    tooltipGeneration += 1
    d._tooltipOwner = ownerToken
    tooltipTarget = target

    if
        not target
        or not target.Parent
        or not isEffectivelyVisible(target)
        or d.TooltipsEnabled == false
        or not tooltipInterfaceVisible()
        or not z
        or not z.Parent
    then
        return
    end

    local scale = getGuiScale()
    local viewport =
        (B and B.AbsoluteSize or workspace.CurrentCamera.ViewportSize)
        / scale
    local maxWidth = math.clamp(viewport.X * 0.28, 190, 340)
    local bounds = E(
        tooltipText,
        z.TextSize,
        o.Font,
        maxWidth - 26
    ) or Vector2.new(maxWidth - 26, z.TextSize + 4)

    local targetSize = UDim2.fromOffset(
        math.min(maxWidth, math.max(100, bounds.X + 28)),
        math.max(32, bounds.Y + 16)
    )

    local alreadyVisible =
        z.Visible
        and z.TextTransparency < 0.9
        and z.BackgroundTransparency < 0.9

    z.Text = tooltipText
    z.TextColor3 = o.TextStrong
    z.Visible = true

    if alreadyVisible then
        n:Tween(
            z,
            TweenInfo.new(
                0.055,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Size = targetSize,
                TextTransparency = 0,
                BackgroundTransparency = 0.04,
            }
        )
    else
        z.Size = targetSize
        z.TextTransparency = 1
        z.BackgroundColor3 = o.Elevated
        z.BackgroundTransparency = 1

        if tooltipStroke then
            tooltipStroke.Transparency = 1
        end
        if y then
            y.ImageTransparency = 1
        end
        if tooltipAccent then
            tooltipAccent.BackgroundTransparency = 1
        end
        if tooltipScale then
            tooltipScale.Scale = 0.99
        end

        n:Tween(
            z,
            TweenInfo.new(
                0.065,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                TextTransparency = 0,
                BackgroundTransparency = 0.04,
            }
        )
    end

    if tooltipStroke then
        n:Tween(
            tooltipStroke,
            TweenInfo.new(
                0.065,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Transparency = 0.48,
            }
        )
    end

    if y then
        n:Tween(
            y,
            TweenInfo.new(
                0.065,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                ImageTransparency = 0.82,
            }
        )
    end

    if tooltipAccent then
        n:Tween(
            tooltipAccent,
            TweenInfo.new(
                0.065,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                BackgroundTransparency = 0.08,
            }
        )
    end

    if tooltipScale then
        n:Tween(
            tooltipScale,
            TweenInfo.new(
                0.065,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Scale = 1,
            }
        )
    end

    positionTooltip(false)
    ensureTooltipFollow()
end

local function addTooltip(F, G)
    if d.isMobile or not G or not F then
        return
    end

    G = tostring(G)
    local ownerToken = {}
    local connections = {}

    connections[1] = F.MouseEnter:Connect(function()
        showTooltip(ownerToken, F, G)
    end)

    connections[2] = F.MouseLeave:Connect(function()
        local leaveGeneration = tooltipGeneration
        task.delay(0.035, function()
            if
                leaveGeneration == tooltipGeneration
                and d._tooltipOwner == ownerToken
            then
                hideTooltip(false)
            end
        end)
    end)

    connections[3] = F:GetPropertyChangedSignal("Visible"):Connect(function()
        if not F.Visible and d._tooltipOwner == ownerToken then
            hideTooltip(true)
        end
    end)

    F.Destroying:Once(function()
        if d._tooltipOwner == ownerToken then
            hideTooltip(true)
        end

        for index, connection in connections do
            pcall(function()
                connection:Disconnect()
            end)
            connections[index] = nil
        end
    end)
end

d.addTooltip = addTooltip

local function applyToggleAccent(toggleApi, hue, saturation, value, rainbow, index)
    if type(toggleApi) ~= "table" then
        return false
    end

    if type(toggleApi.Color) == "function" then
        local success = pcall(toggleApi.Color, toggleApi, hue, saturation, value, rainbow)
        if success then
            return true
        end
    end

    local object = toggleApi.Object
    if typeof(object) ~= "Instance" then
        return false
    end

    local accent = rainbow and Color3.fromHSV(d:Color((hue - ((index or 0) * 0.075)) % 1))
        or Color3.fromHSV(hue, saturation, value)
    local track = object:FindFirstChild("Track", true)
    local knob = object:FindFirstChild("Knob", true)
    local frame = object:FindFirstChild("Frame", true)

    if toggleApi.Enabled then
        if track and track:IsA("GuiObject") then
            n:Cancel(track)
            track.BackgroundColor3 = accent
        end
        if knob and knob:IsA("GuiObject") then
            n:Cancel(knob)
            knob.BackgroundColor3 = o.TextStrong
        end
        if frame and frame:IsA("GuiObject") then
            n:Cancel(frame)
            frame.BackgroundColor3 = accent
        end
    end

    return track ~= nil or knob ~= nil or frame ~= nil
end

local function checkKeybinds(F, G, H)
    if type(G) == "table" then
        if table.find(G, H) then
            for I, J in G do
                if not table.find(F, J) then
                    return false
                end
            end
            return true
        end
    end

    return false
end

local function createMobileButton(F, G)
    local H = false
    local I = Instance.new("TextButton")

    I.Size = UDim2.fromOffset(52, 52)
    I.Position = UDim2.fromOffset(G.X, G.Y)
    I.AnchorPoint = Vector2.new(0.5, 0.5)
    I.BackgroundColor3 = F.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
    I.BackgroundTransparency = 0.4
    I.Text = F.Name
    I.TextColor3 = Color3.new(1, 1, 1)
    I.TextScaled = true
    I.Font = Enum.Font.GothamBold
    I.Parent = d.gui
    local J = Instance.new("UITextSizeConstraint")
    J.MaxTextSize = 18
    J.Parent = I
    addCorner(I, UDim.new(1, 0))

    I.MouseButton1Down:Connect(function()
        H = true
        local K, L = tick(), h:GetMouseLocation()
        repeat
            H = (h:GetMouseLocation() - L).Magnitude < 6
            task.wait(0.05)
        until (tick() - K) > 1 or not H
        if H then
            F.Bind = {}
            I:Destroy()
        end
    end)
    I.MouseButton1Up:Connect(function()
        H = false
    end)
    I.Activated:Connect(function()
        F:Toggle()
        local K = F.Enabled and Color3.new(0, 0.7, 0) or Color3.new()
        I.BackgroundColor3 = K

        local L = Instance.new("UIScale")
        L.Scale = 1
        L.Parent = I
        n:Tween(L, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.18 })
        task.delay(0.1, function()
            n:Tween(L, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 1 })
            task.delay(0.15, function()
                pcall(function()
                    L:Destroy()
                end)
            end)
        end)
    end)

    F.Bind = { Button = I }
end

d.http_function = function(F)
    if F == nil then
        return
    end
    F = tostring(F)
    local G, H = pcall(function()
        return { game:HttpGet(F) }
    end)
    if not (G ~= nil and G == true and H ~= nil and type(H) == "table") then
        return
    end
    if H[1] ~= nil and H[1] == game then
        return H[4]
    else
        return H[1]
    end
end

local F = function(F, G, H)
    local I, J
    task.spawn(function()
        I, J = pcall(function()
            return F()
        end)
    end)
    G = G or 5
    local K = tick()
    repeat
        task.wait()
    until I ~= nil or tick() - K >= G
    if I == nil then
        I = false
        J = "TIMEOUT_EXCEEDED"
    end
    if not I and shared.VoidDev then
        bwarn(debug.traceback(J))
    end
    if H ~= nil then
        return H(I, J)
    end
    return I, J
end

local G = shared.CACHED_ICON_LIBRARY
if not G then
    F(function()
        local H, I = pcall(function()
            local H =
                loadstring(d.http_function("https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"))()
            H.SetIconsType("lucide")
            return H
        end)
        if not H then
            pcall(function()
                d:CreateNotification("BadWars | Icons", "Failure loading custom icons :c", 5, "alert")
            end)
            bwarn(`[Icons Failure]: {tostring(I)}`)
        end
        G = H and I or nil
        shared.CACHED_ICON_LIBRARY = G
    end, 3)
end
local iconCache = {}
local missingIconWarnings = {}

local function getCustomIcon(H)
    if not G then
        return false
    end
    local I, J = pcall(function()
        return G.GetIcon(H)
    end)
    if not I then
        if not missingIconWarnings[H] then
            missingIconWarnings[H] = true
            bwarn(`[getCustomIcon Failure]: {tostring(H)} -> {tostring(J)}`)
        end
        return false
    end
    return type(J) == "string" and J ~= "" and J or false
end

u = function(H, I)
    H = tostring(H or "")
    local cacheKey = (I and "icon:" or "asset:") .. H
    if iconCache[cacheKey] then
        return iconCache[cacheKey]
    end

    if I then
        local customIcon = getCustomIcon(H)
        if customIcon then
            iconCache[cacheKey] = customIcon
            return customIcon
        end
        return ""
    end

    local bundled = C[H]
    if type(bundled) == "string" and bundled ~= "" then
        iconCache[cacheKey] = bundled
        return bundled
    end

    local customIcon = getCustomIcon(H)
    if customIcon then
        iconCache[cacheKey] = customIcon
        return customIcon
    end

    if type(t) == "function" and H ~= "" and D(H) then
        local success, result = pcall(t, H)
        if success and type(result) == "string" and result ~= "" then
            iconCache[cacheKey] = result
            return result
        end
        if not success and not missingIconWarnings[H] then
            missingIconWarnings[H] = true
            bwarn(`[Asset Failure]: {H} -> {tostring(result)}`)
        end
    end

    return ""
end

getGuiScale = function()
    return math.max(A and A.Scale or 1, 0.05)
end

clampGuiObjectToViewport = function(guiObject, desiredAbsolute)
    local camera = workspace.CurrentCamera
    local viewport = (B and B.AbsoluteSize)
        or (camera and camera.ViewportSize)
        or Vector2.new(1920, 1080)
    local size = guiObject.AbsoluteSize
    local margin = d.isMobile and 4 or 8

    local minX
    local maxX
    if size.X <= viewport.X - (margin * 2) then
        minX = margin
        maxX = math.max(margin, viewport.X - size.X - margin)
    else
        minX = math.min(margin, viewport.X - size.X - margin)
        maxX = margin
    end

    local minY
    local maxY
    if size.Y <= viewport.Y - (margin * 2) then
        minY = margin
        maxY = math.max(margin, viewport.Y - size.Y - margin)
    else
        minY = math.min(margin, viewport.Y - size.Y - margin)
        maxY = margin
    end

    return Vector2.new(
        math.clamp(desiredAbsolute.X, minX, maxX),
        math.clamp(desiredAbsolute.Y, minY, maxY)
    )
end

setGuiAbsolutePosition = function(guiObject, absolutePosition)
    local parent = guiObject.Parent
    if not parent then
        return
    end
    local scale = getGuiScale()
    local parentAbsolute = parent:IsA("GuiObject") and parent.AbsolutePosition or Vector2.zero
    local size = guiObject.AbsoluteSize / scale
    local anchor = guiObject.AnchorPoint
    guiObject.Position = UDim2.fromOffset(
        (absolutePosition.X - parentAbsolute.X) / scale + (size.X * anchor.X),
        (absolutePosition.Y - parentAbsolute.Y) / scale + (size.Y * anchor.Y)
    )
end


-- BADWARS_ADAPTIVE_LAYOUT_ENGINE_V1_BEGIN
local LayoutIntelligence = {
    objects = setmetatable({}, { __mode = "k" }),
    metadata = setmetatable({}, { __mode = "k" }),
    activeObject = nil,
    registrationCounter = 0,
    dirty = false,
    resolveQueued = false,
    resolving = false,
    started = false,
    margin = d.isMobile and 6 or 8,
    stepInterval = 0.12,
    lastStep = 0,
}

d.LayoutIntelligence = LayoutIntelligence
d.LayoutAI = LayoutIntelligence

local function layoutRect(position, size)
    return {
        X = position.X,
        Y = position.Y,
        Width = math.max(0, size.X),
        Height = math.max(0, size.Y),
    }
end

local function layoutRectsOverlap(left, right, margin)
    margin = margin or 0
    return left.X < right.X + right.Width + margin
        and left.X + left.Width + margin > right.X
        and left.Y < right.Y + right.Height + margin
        and left.Y + left.Height + margin > right.Y
end

function LayoutIntelligence:_isVisible(object)
    return typeof(object) == "Instance"
        and object:IsA("GuiObject")
        and object.Parent ~= nil
        and object.Visible
        and object.AbsoluteSize.X > 1
        and object.AbsoluteSize.Y > 1
        and isEffectivelyVisible(object)
end

function LayoutIntelligence:_visibleObjects(exclude)
    local objects = {}

    for object in pairs(self.objects) do
        if object ~= exclude and self:_isVisible(object) and object:GetAttribute("AllowUIOverlap") ~= true then
            objects[#objects + 1] = object
        end
    end

    table.sort(objects, function(left, right)
        local leftMeta = self.metadata[left]
        local rightMeta = self.metadata[right]
        return (leftMeta and leftMeta.Order or 0) < (rightMeta and rightMeta.Order or 0)
    end)

    return objects
end

function LayoutIntelligence:_reservedRects()
    local rects = {}

    local function collect(folder)
        if not folder or not folder.Parent then
            return
        end

        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("GuiObject") and child.Visible and child.AbsoluteSize.X > 1 and child.AbsoluteSize.Y > 1 then
                rects[#rects + 1] = layoutRect(child.AbsolutePosition, child.AbsoluteSize)
            end
        end
    end

    collect(q)
    collect(s)
    return rects
end

function LayoutIntelligence:_blockerRects(exclude)
    local rects = self:_reservedRects()

    for _, object in ipairs(self:_visibleObjects(exclude)) do
        rects[#rects + 1] = layoutRect(object.AbsolutePosition, object.AbsoluteSize)
    end

    return rects
end

function LayoutIntelligence:_positionIsFree(object, position, blockers)
    local candidate = layoutRect(position, object.AbsoluteSize)

    for _, blocker in ipairs(blockers) do
        if layoutRectsOverlap(candidate, blocker, self.margin) then
            return false
        end
    end

    return true
end

function LayoutIntelligence:_addCandidate(candidates, seen, object, position)
    local clamped = clampGuiObjectToViewport(object, position)
    local key = tostring(math.floor(clamped.X + 0.5)) .. ":" .. tostring(math.floor(clamped.Y + 0.5))

    if not seen[key] then
        seen[key] = true
        candidates[#candidates + 1] = clamped
    end
end

function LayoutIntelligence:_findSafeAgainst(object, desired, blockers, maxRadius)
    desired = clampGuiObjectToViewport(object, desired)
    if self:_positionIsFree(object, desired, blockers) then
        return desired, true
    end

    local size = object.AbsoluteSize
    local candidates = {}
    local seen = {}

    self:_addCandidate(candidates, seen, object, desired)

    for _, blocker in ipairs(blockers) do
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X - size.X - self.margin, desired.Y)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X + blocker.Width + self.margin, desired.Y)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(desired.X, blocker.Y - size.Y - self.margin)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(desired.X, blocker.Y + blocker.Height + self.margin)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X - size.X - self.margin, blocker.Y - size.Y - self.margin)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X + blocker.Width + self.margin, blocker.Y - size.Y - self.margin)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X - size.X - self.margin, blocker.Y + blocker.Height + self.margin)
        )
        self:_addCandidate(
            candidates,
            seen,
            object,
            Vector2.new(blocker.X + blocker.Width + self.margin, blocker.Y + blocker.Height + self.margin)
        )
    end

    local radiusLimit = math.max(24, tonumber(maxRadius) or 320)
    local radius = 20
    while radius <= radiusLimit do
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(radius, 0))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(-radius, 0))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(0, radius))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(0, -radius))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(radius, radius))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(-radius, radius))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(radius, -radius))
        self:_addCandidate(candidates, seen, object, desired + Vector2.new(-radius, -radius))
        radius += 20
    end

    table.sort(candidates, function(left, right)
        return (left - desired).Magnitude < (right - desired).Magnitude
    end)

    for _, candidate in ipairs(candidates) do
        if self:_positionIsFree(object, candidate, blockers) then
            return candidate, true
        end
    end

    return desired, false
end

function LayoutIntelligence:Register(object, options)
    if typeof(object) ~= "Instance" or not object:IsA("GuiObject") then
        return object
    end

    if self.objects[object] then
        return object
    end

    options = type(options) == "table" and options or {}
    self.registrationCounter += 1
    self.objects[object] = true
    self.metadata[object] = {
        Order = tonumber(options.Priority) or self.registrationCounter,
        LastSafe = object.AbsolutePosition,
        ResizeThread = nil,
    }
    object:SetAttribute("AdaptiveLayoutManaged", true)

    local function request()
        self:RequestResolve()
    end

    local function requestAfterResize()
        local metadata = self.metadata[object]
        if not metadata then
            return
        end
        if metadata.ResizeThread then
            pcall(task.cancel, metadata.ResizeThread)
        end
        metadata.ResizeThread = task.delay(0.08, function()
            local current = self.metadata[object]
            if current == metadata then
                current.ResizeThread = nil
                self:RequestResolve()
            end
        end)
    end

    d:Clean(object:GetPropertyChangedSignal("Visible"):Connect(request))
    d:Clean(object:GetPropertyChangedSignal("AbsoluteSize"):Connect(requestAfterResize))
    object.Destroying:Once(function()
        self:Unregister(object)
    end)

    task.defer(request)
    return object
end

function LayoutIntelligence:Unregister(object)
    local metadata = self.metadata[object]
    if metadata and metadata.ResizeThread then
        pcall(task.cancel, metadata.ResizeThread)
        metadata.ResizeThread = nil
    end

    self.objects[object] = nil
    self.metadata[object] = nil

    if self.activeObject == object then
        self.activeObject = nil
    end
end

function LayoutIntelligence:BeginDrag(object)
    self:Register(object)
    self.activeObject = object

    local metadata = self.metadata[object]
    if metadata then
        if metadata.ResizeThread then
            pcall(task.cancel, metadata.ResizeThread)
            metadata.ResizeThread = nil
        end
        metadata.LastSafe = object.AbsolutePosition
    end
end

function LayoutIntelligence:UpdateDrag(object, desired)
    self:Register(object)

    -- Pointer movement stays direct. Collision resolution is deferred until
    -- release so drag input never performs an O(n^2) layout search per frame.
    local safe = clampGuiObjectToViewport(object, desired)
    local metadata = self.metadata[object]
    if metadata then
        metadata.LastSafe = safe
    end
    return safe
end

function LayoutIntelligence:EndDrag(object)
    if self.activeObject == object then
        self.activeObject = nil
    end

    local metadata = self.metadata[object]
    if metadata and self:_isVisible(object) then
        metadata.LastSafe = object.AbsolutePosition
    end

    self:RequestResolve()
end

function LayoutIntelligence:HasOverlap()
    local objects = self:_visibleObjects()
    local reserved = self:_reservedRects()

    for index, object in ipairs(objects) do
        local rect = layoutRect(object.AbsolutePosition, object.AbsoluteSize)

        for _, reservedRect in ipairs(reserved) do
            if layoutRectsOverlap(rect, reservedRect, self.margin) then
                return true
            end
        end

        for otherIndex = index + 1, #objects do
            local other = objects[otherIndex]
            local otherRect = layoutRect(other.AbsolutePosition, other.AbsoluteSize)
            if layoutRectsOverlap(rect, otherRect, self.margin) then
                return true
            end
        end
    end

    return false
end

function LayoutIntelligence:ResolveAll()
    if self.resolving or self.activeObject then
        return
    end

    self.resolving = true
    local blockers = self:_reservedRects()
    local objects = self:_visibleObjects()

    for _, object in ipairs(objects) do
        local current = clampGuiObjectToViewport(object, object.AbsolutePosition)
        local safe = current

        if not self:_positionIsFree(object, current, blockers) then
            safe = select(1, self:_findSafeAgainst(object, current, blockers, 520))
        end

        if (safe - object.AbsolutePosition).Magnitude > 0.5 then
            setGuiAbsolutePosition(object, safe)
        end

        local metadata = self.metadata[object]
        if metadata then
            metadata.LastSafe = safe
        end

        blockers[#blockers + 1] = layoutRect(safe, object.AbsoluteSize)
    end

    self.dirty = false
    self.resolving = false
end

function LayoutIntelligence:RequestResolve()
    self.dirty = true
    if self.resolveQueued then
        return
    end

    self.resolveQueued = true
    task.defer(function()
        self.resolveQueued = false
        if self.dirty then
            self:ResolveAll()
        end
    end)
end

function LayoutIntelligence:Start()
    if self.started then
        return
    end
    self.started = true
    -- Layout work is event-driven through RequestResolve. A permanent
    -- Heartbeat listener made idle UI pay a cost even when nothing moved.
end
-- BADWARS_ADAPTIVE_LAYOUT_ENGINE_V1_END

local function bindDirectDrag(handle, target, visibleGuard, headerOnly)
    local activeInput
    local moveConnection
    local endConnection
    local beganConnection
    local dragState

    LayoutIntelligence:Register(target)

    local function stopDragging()
        if activeInput and target.Parent then
            local safe = clampGuiObjectToViewport(target, target.AbsolutePosition)
            setGuiAbsolutePosition(target, safe)
            LayoutIntelligence:EndDrag(target)
        end

        activeInput = nil
        dragState = nil

        if moveConnection then
            moveConnection:Disconnect()
            moveConnection = nil
        end
        if endConnection then
            endConnection:Disconnect()
            endConnection = nil
        end
    end

    beganConnection = handle.InputBegan:Connect(function(input)
        if visibleGuard and not visibleGuard.Visible then
            return
        end

        local inputType = input.UserInputType
        if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
            return
        end

        if headerOnly and input.Position.Y - target.AbsolutePosition.Y > 40 * getGuiScale() then
            return
        end

        stopDragging()
        activeInput = input
        LayoutIntelligence:BeginDrag(target)

        local scale = getGuiScale()
        local parent = target.Parent
        local parentAbsolute = parent and parent:IsA("GuiObject") and parent.AbsolutePosition or Vector2.zero
        local targetSize = target.AbsoluteSize / scale
        local targetAnchor = target.AnchorPoint
        local startPointer = input.Position
        local startAbsolute = target.AbsolutePosition
        local viewport = (B and B.AbsoluteSize)
            or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
            or Vector2.new(1920, 1080)
        local margin = d.isMobile and 4 or 8

        local minX = target.AbsoluteSize.X <= viewport.X - (margin * 2)
            and margin
            or math.min(margin, viewport.X - target.AbsoluteSize.X - margin)
        local maxX = target.AbsoluteSize.X <= viewport.X - (margin * 2)
            and math.max(margin, viewport.X - target.AbsoluteSize.X - margin)
            or margin
        local minY = target.AbsoluteSize.Y <= viewport.Y - (margin * 2)
            and margin
            or math.min(margin, viewport.Y - target.AbsoluteSize.Y - margin)
        local maxY = target.AbsoluteSize.Y <= viewport.Y - (margin * 2)
            and math.max(margin, viewport.Y - target.AbsoluteSize.Y - margin)
            or margin

        dragState = {
            Scale = scale,
            ParentAbsolute = parentAbsolute,
            Size = targetSize,
            Anchor = targetAnchor,
            StartPointer = startPointer,
            StartAbsolute = startAbsolute,
            MinX = minX,
            MaxX = maxX,
            MinY = minY,
            MaxY = maxY,
            Mouse = inputType == Enum.UserInputType.MouseButton1,
            ExpectedMovement = inputType == Enum.UserInputType.MouseButton1
                    and Enum.UserInputType.MouseMovement
                or Enum.UserInputType.Touch,
        }

        moveConnection = h.InputChanged:Connect(function(changed)
            local state = dragState
            if not activeInput
                or not state
                or changed.UserInputType ~= state.ExpectedMovement
                or (not state.Mouse and changed ~= activeInput)
                or not target.Parent
            then
                return
            end

            local delta = changed.Position - state.StartPointer
            if state.Mouse and h:IsKeyDown(Enum.KeyCode.LeftShift) then
                delta = Vector3.new(
                    math.round(delta.X / 3) * 3,
                    math.round(delta.Y / 3) * 3,
                    delta.Z
                )
            end

            local absoluteX = math.clamp(state.StartAbsolute.X + delta.X, state.MinX, state.MaxX)
            local absoluteY = math.clamp(state.StartAbsolute.Y + delta.Y, state.MinY, state.MaxY)

            target.Position = UDim2.fromOffset(
                (absoluteX - state.ParentAbsolute.X) / state.Scale + (state.Size.X * state.Anchor.X),
                (absoluteY - state.ParentAbsolute.Y) / state.Scale + (state.Size.Y * state.Anchor.Y)
            )
        end)

        endConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End
                or input.UserInputState == Enum.UserInputState.Cancel
            then
                stopDragging()
            end
        end)
    end)

    target.Destroying:Once(function()
        stopDragging()
        LayoutIntelligence:Unregister(target)
        if beganConnection then
            beganConnection:Disconnect()
        end
    end)
end

local function makeDraggable(H, I)
    bindDirectDrag(H, H, I, not I)
end

local function makeDraggable2(H, I)
    bindDirectDrag(H, I, I, false)
end

local function setupMobileSwipeDismiss(H, I)
    if not d.isMobile then
        return
    end
    local J
    local K = 80

    H.InputBegan:Connect(function(L)
        if L.UserInputType == Enum.UserInputType.Touch then
            J = L.Position.X
        end
    end)
    H.InputEnded:Connect(function(L)
        if L.UserInputType == Enum.UserInputType.Touch and J then
            local M = J - L.Position.X
            if M >= K then
                pcall(I)
            end
            J = nil
        end
    end)
end
d.setupMobileSwipeDismiss = setupMobileSwipeDismiss

local function setupGuiMoveCheck(H, I)
    local startPosition
    local began = H.InputBegan:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            startPosition = I.AbsolutePosition
        end
    end)
    local ended = H.InputEnded:Connect(function(input)
        if
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            -- Keep the last start position long enough for the matching Activated callback.
        end
    end)
    H.Destroying:Once(function()
        began:Disconnect()
        ended:Disconnect()
    end)
    return function()
        if not startPosition then
            return true
        end
        return (I.AbsolutePosition - startPosition).Magnitude < 3
    end
end

local function randomString()
    local H = {}
    for I = 1, math.random(10, 100) do
        H[I] = string.char(math.random(32, 126))
    end
    return table.concat(H)
end

local function removeTags(H)
    H = H:gsub("<br%s*/>", "\n")
    return H:gsub("<[^<>]->", "")
end

do
    local H = D("badscript/profiles/color.txt") and loadJson("badscript/profiles/color.txt")
    if H then
        o.Main = H.Main and Color3.fromRGB(unpack(H.Main)) or o.Main
        o.Text = H.Text and Color3.fromRGB(unpack(H.Text)) or o.Text
        if H.Font then
            local fontPath = H.Font:find("rbxasset") and H.Font
                or string.format("rbxasset://fonts/families/%s.json", H.Font)
            local success, loadedFont = pcall(Font.new, fontPath)
            if success and typeof(loadedFont) == "Font" then
                o.Font = loadedFont
            end
        end
        o.FontSemiBold = Font.new(o.Font.Family, Enum.FontWeight.SemiBold)
    end
    p.Font = o.Font
end

do
    function m.Dark(H, I)
        local J, K, L = H:ToHSV()
        return Color3.fromHSV(J, K, math.clamp(select(3, o.Main:ToHSV()) > 0.5 and L + I or L - I, 0, 1))
    end

    function m.Light(H, I)
        local J, K, L = H:ToHSV()
        return Color3.fromHSV(J, K, math.clamp(select(3, o.Main:ToHSV()) > 0.5 and L - I or L + I, 0, 1))
    end

    function d.Color(H, I)
        local J = 0.75 + (0.15 * math.min(I / 0.03, 1))
        if I > 0.57 then
            J = 0.9 - (0.4 * math.min((I - 0.57) / 0.09, 1))
        end
        if I > 0.66 then
            J = 0.5 + (0.4 * math.min((I - 0.66) / 0.16, 1))
        end
        if I > 0.87 then
            J = 0.9 - (0.15 * math.min((I - 0.87) / 0.13, 1))
        end
        return I, J, 1
    end

    function d.TextColor(H, I, J, K)
        if K >= 0.7 and (J < 0.6 or I > 0.04 and I < 0.56) then
            return Color3.new(0.19, 0.19, 0.19)
        end
        return Color3.new(1, 1, 1)
    end
end

do
    local function disconnectTweenCompletion(H, tween)
        local connection = H.completionConnections[tween]
        if connection then
            connection:Disconnect()
            H.completionConnections[tween] = nil
        end
    end

    local function createMotionState()
        return {
            __MotionState = true,
            Tweens = {},
            Properties = {},
            Targets = {},
        }
    end

    local function stateIsEmpty(state)
        return next(state.Tweens) == nil
    end

    local function removeTweenFromState(H, instance, registry, state, tween, preserve)
        local targets = state.Targets[tween]
        if preserve and targets and instance.Parent then
            for property, value in pairs(targets) do
                if not preserve[property] then
                    pcall(function()
                        instance[property] = value
                    end)
                end
            end
        end

        disconnectTweenCompletion(H, tween)
        pcall(function()
            tween:Cancel()
        end)

        state.Tweens[tween] = nil
        state.Targets[tween] = nil
        for property, activeTween in pairs(state.Properties) do
            if activeTween == tween then
                state.Properties[property] = nil
            end
        end

        if stateIsEmpty(state) and registry[instance] == state then
            registry[instance] = nil
        end
    end

    function n.Tween(H, I, J, K, L, M, N)
        if type(L) == "boolean" then
            M = L
            L = nil
        end

        if type(J) == "table" and K == nil then
            K = J
            J = o.Tween
        elseif typeof(J) ~= "TweenInfo" then
            J = o.Tween
        end

        if typeof(I) ~= "Instance" or type(K) ~= "table" then
            return nil
        end

        local motionLibrary = d.MotionLibrary
        local activeSprings = H.springProperties[I]
        if activeSprings and type(motionLibrary) == "table" and type(motionLibrary.stop) == "function" then
            for property in pairs(K) do
                if activeSprings[property] then
                    pcall(motionLibrary.stop, I, property)
                    activeSprings[property] = nil
                end
            end
            if next(activeSprings) == nil then
                H.springProperties[I] = nil
            end
        end

        local needsTween = false
        for property, targetValue in pairs(K) do
            local readable, currentValue = pcall(function()
                return I[property]
            end)
            if not readable or currentValue ~= targetValue then
                needsTween = true
                break
            end
        end
        if not needsTween then
            return nil
        end

        L = L or H.tweens
        local state = L[I]
        if type(state) ~= "table" or state.__MotionState ~= true then
            if state then
                disconnectTweenCompletion(H, state)
                pcall(function()
                    state:Cancel()
                end)
            end
            state = createMotionState()
            L[I] = state
        end

        local replacing = {}
        local toCancel = {}
        for property in pairs(K) do
            replacing[property] = true
            local activeTween = state.Properties[property]
            if activeTween then
                toCancel[activeTween] = true
            end
        end

        for activeTween in pairs(toCancel) do
            removeTweenFromState(H, I, L, state, activeTween, replacing)
        end

        if not I.Parent then
            pcall(function()
                for property, value in pairs(K) do
                    I[property] = value
                end
            end)
            if stateIsEmpty(state) and L[I] == state then
                L[I] = nil
            end
            return nil
        end

        local created, tween = pcall(function()
            return g:Create(I, J, K)
        end)
        if not created then
            a:report({
                type = "gui-tween",
                err = tween,
                args = { I, J, K },
                notifyBlacklisted = true,
            })

            pcall(function()
                for property, value in pairs(K) do
                    I[property] = value
                end
            end)

            if stateIsEmpty(state) and L[I] == state then
                L[I] = nil
            end
            return nil
        end

        state.Tweens[tween] = true
        state.Targets[tween] = K
        for property in pairs(K) do
            state.Properties[property] = tween
        end

        local connection
        connection = tween.Completed:Connect(function(playbackState)
            if not state.Tweens[tween] then
                disconnectTweenCompletion(H, tween)
                return
            end

            state.Tweens[tween] = nil
            state.Targets[tween] = nil
            for property, activeTween in pairs(state.Properties) do
                if activeTween == tween then
                    state.Properties[property] = nil
                end
            end
            disconnectTweenCompletion(H, tween)

            if playbackState == Enum.PlaybackState.Completed and not N then
                pcall(function()
                    for property, value in pairs(K) do
                        I[property] = value
                    end
                end)
            end

            if stateIsEmpty(state) and L[I] == state then
                L[I] = nil
            end
        end)
        H.completionConnections[tween] = connection

        if not M then
            tween:Play()
        end
        return tween
    end
    n.tween = n.Tween

    function n.Spring(H, I, J, K)
        if typeof(I) ~= "Instance" or type(K) ~= "table" then
            return false
        end

        local profile = type(J) == "table" and J or o.SpringInteractive
        if profile.Public ~= true then
            H:Tween(I, profile.TweenInfo or o.TweenFast, K)
            return false
        end

        local damping = tonumber(profile.Damping) or 1
        local frequency = tonumber(profile.Frequency) or 20
        local motionLibrary = d.MotionLibrary

        if type(motionLibrary) ~= "table"
            or type(motionLibrary.target) ~= "function"
            or type(motionLibrary.stop) ~= "function"
        then
            H:Tween(I, profile.TweenInfo or o.TweenFast, K)
            return false
        end

        for property in pairs(K) do
            H:Cancel(I, H.tweens, property)
        end

        local activeSprings = H.springProperties[I]
        if not activeSprings then
            activeSprings = {}
            H.springProperties[I] = activeSprings
        end
        for property in pairs(K) do
            activeSprings[property] = true
        end

        local ok, err = pcall(
            motionLibrary.target,
            I,
            damping,
            frequency,
            K
        )
        if not ok then
            a:report({
                type = "gui-spring",
                err = err,
                args = { I, profile, K },
                notifyBlacklisted = true,
            })
            H.springProperties[I] = nil
            H:Tween(I, profile.TweenInfo or o.TweenFast, K)
            return false
        end

        return true
    end
    n.spring = n.Spring

    function n.Cancel(H, I, L, property)
        local motionLibrary = d.MotionLibrary
        local activeSprings = H.springProperties[I]
        if activeSprings and type(motionLibrary) == "table" and type(motionLibrary.stop) == "function" then
            if property ~= nil then
                if activeSprings[property] then
                    pcall(motionLibrary.stop, I, property)
                    activeSprings[property] = nil
                end
            else
                pcall(motionLibrary.stop, I)
                H.springProperties[I] = nil
            end
            if activeSprings and next(activeSprings) == nil then
                H.springProperties[I] = nil
            end
        end

        L = L or H.tweens
        local state = L[I]
        if not state then
            return
        end

        if type(state) ~= "table" or state.__MotionState ~= true then
            disconnectTweenCompletion(H, state)
            pcall(function()
                state:Cancel()
            end)
            if L[I] == state then
                L[I] = nil
            end
            return
        end

        if property ~= nil then
            local tween = state.Properties[property]
            if tween then
                removeTweenFromState(H, I, L, state, tween)
            end
            return
        end

        local active = {}
        for tween in pairs(state.Tweens) do
            active[#active + 1] = tween
        end
        for _, tween in ipairs(active) do
            removeTweenFromState(H, I, L, state, tween)
        end
        if L[I] == state then
            L[I] = nil
        end
    end
    n.cancel = n.Cancel
end

d.Libraries = {
    color = m,
    getcustomasset = u,
    getfontsize = E,
    tween = n,
    spr = d.MotionLibrary,
    uipallet = o,
}

local H
H = {
    Button = function(I, J, K)
        local L = {
            Name = I.Name,
            Visible = I.Visible == nil or I.Visible,
        }

        local M = Instance.new("TextButton")
        M.Name = I.Name .. "Button"
        M.Size = UDim2.new(1, 0, 0, d.isMobile and 50 or 42)
        M.BackgroundTransparency = 1
        M.BorderSizePixel = 0
        M.AutoButtonColor = false
        M.Visible = L.Visible
        M.Text = ""
        M.Parent = J
        M:GetPropertyChangedSignal("Visible"):Connect(function()
            L.Visible = M.Visible
        end)
        addTooltip(M, I.Tooltip)

        local N = Instance.new("Frame")
        N.Name = "Card"
        N.Size = UDim2.new(1, -16, 1, -8)
        N.Position = UDim2.fromOffset(8, 4)
        N.BackgroundColor3 = o.Elevated
        N.BorderSizePixel = 0
        N.ClipsDescendants = true
        N.Parent = M
        addCorner(N, o.Radius)
        addSurfaceGradient(N)
        local O = addStroke(N, o.Border, 0.54, 1, "ButtonStroke")

        local P = Instance.new("Frame")
        P.Name = "Accent"
        P.Size = UDim2.new(0, 3, 0.55, 0)
        P.AnchorPoint = Vector2.new(0, 0.5)
        P.Position = UDim2.new(0, 0, 0.5, 0)
        P.BorderSizePixel = 0
        P.Parent = N
        addCorner(P, UDim.new(1, 0))
        connectguicolorchange(function(Q, R, S)
            P.BackgroundColor3 = Color3.fromHSV(Q, R, S)
        end)

        local Q = Instance.new("TextLabel")
        Q.Name = "Label"
        Q.Size = UDim2.new(1, -28, 1, 0)
        Q.Position = UDim2.fromOffset(18, 0)
        Q.BackgroundTransparency = 1
        Q.Text = tostring(I.Name)
        Q.TextXAlignment = Enum.TextXAlignment.Left
        Q.TextColor3 = o.Text
        Q.TextSize = d.isMobile and 15 or 14
        Q.FontFace = o.FontSemiBold
        Q.Parent = N

        local R = Instance.new("TextLabel")
        R.Name = "Arrow"
        R.Size = UDim2.fromOffset(18, 18)
        R.Position = UDim2.new(1, -27, 0.5, -9)
        R.BackgroundTransparency = 1
        R.Text = ">"
        R.TextColor3 = o.FaintText
        R.TextSize = 20
        R.FontFace = o.FontSemiBold
        R.Parent = N

        I.Function = I.Function and wrap(I.Function) or function() end

        function L.SetVisible(S, T)
            if T == nil then
                T = not L.Visible
            end
            M.Visible = T
        end

        local scale = addScale(N)
        M.MouseEnter:Connect(function()
            n:Tween(N, o.TweenFast, {
                BackgroundColor3 = o.ElevatedHover,
            })
            n:Tween(O, o.TweenFast, {
                Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
                Transparency = 0.16,
            })
            n:Tween(R, o.TweenFast, {
                TextColor3 = o.Text,
                Position = UDim2.new(1, -24, 0.5, -9),
            })
            n:Spring(scale, o.SpringInteractive, { Scale = 1.006 })
        end)
        M.MouseLeave:Connect(function()
            n:Tween(N, o.TweenFast, {
                BackgroundColor3 = o.Elevated,
            })
            n:Tween(O, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.54,
            })
            n:Tween(R, o.TweenFast, {
                TextColor3 = o.FaintText,
                Position = UDim2.new(1, -27, 0.5, -9),
            })
            n:Spring(scale, o.SpringInteractive, { Scale = 1 })
        end)
        M.MouseButton1Down:Connect(function()
            n:Spring(scale, o.SpringInteractive, { Scale = 0.985 })
        end)
        M.MouseButton1Up:Connect(function()
            n:Spring(scale, o.SpringInteractive, { Scale = 1.006 })
        end)
        M.Activated:Connect(I.Function)

        L.Object = M
        L.Label = Q
        return L
    end,
    ColorSlider = function(I, J, K)
        if I.Color then
            I.DefaultHue, I.DefaultSat, I.DefaultValue = I.Color:ToHSV()
        end
        local L = {
            Type = "ColorSlider",
            Hue = I.DefaultHue or 0.44,
            Sat = I.DefaultSat or 1,
            Value = I.DefaultValue or 1,
            Opacity = I.DefaultOpacity or 1,
            Rainbow = false,
            Index = 0,
        }

        local function createSlider(M, N)
            local O = Instance.new("TextButton")
            O.Name = I.Name .. "Slider" .. M
            O.Size = UDim2.new(1, 0, 0, 50)
            O.BackgroundColor3 = m.Dark(J.BackgroundColor3, I.Darker and 0.02 or 0)
            O.BorderSizePixel = 0
            O.AutoButtonColor = false
            O.Visible = false
            O.Text = ""
            O.Parent = J
            local P = Instance.new("TextLabel")
            P.Name = "Title"
            P.Size = UDim2.fromOffset(60, 30)
            P.Position = UDim2.fromOffset(10, 2)
            P.BackgroundTransparency = 1
            P.Text = M
            P.TextXAlignment = Enum.TextXAlignment.Left
            P.TextColor3 = o.MutedText
            P.TextSize = 11
            P.FontFace = o.Font
            P.Parent = O
            local Q = Instance.new("Frame")
            Q.Name = "Slider"
            Q.Size = UDim2.new(1, -20, 0, 2)
            Q.Position = UDim2.fromOffset(10, 37)
            Q.BackgroundColor3 = Color3.new(1, 1, 1)
            Q.BorderSizePixel = 0
            Q.Parent = O
            local R = Instance.new("UIGradient")
            R.Color = N
            R.Parent = Q
            local S = Q:Clone()
            S.Name = "Fill"
            S.Size = UDim2.fromScale(
                math.clamp(M == "Saturation" and L.Sat or M == "Vibrance" and L.Value or L.Opacity, 0.04, 0.96),
                1
            )
            S.Position = UDim2.new()
            S.BackgroundTransparency = 1
            S.Parent = Q
            local T = Instance.new("Frame")
            T.Name = "Knob"
            T.Size = UDim2.fromOffset(24, 4)
            T.Position = UDim2.fromScale(1, 0.5)
            T.AnchorPoint = Vector2.new(0.5, 0.5)
            T.BackgroundColor3 = O.BackgroundColor3
            T.BorderSizePixel = 0
            T.Parent = S
            local U = Instance.new("Frame")
            U.Name = "Knob"
            U.Size = UDim2.fromOffset(14, 14)
            U.Position = UDim2.fromScale(0.5, 0.5)
            U.AnchorPoint = Vector2.new(0.5, 0.5)
            U.BackgroundColor3 = o.Text
            U.Parent = T
            addCorner(U, UDim.new(1, 0))

            O.InputBegan:Connect(function(V)
                if
                    (V.UserInputType == Enum.UserInputType.MouseButton1 or V.UserInputType == Enum.UserInputType.Touch)
                    and (V.Position.Y - O.AbsolutePosition.Y) > (20 * A.Scale)
                then
                    local W = h.InputChanged:Connect(function(W)
                        if
                            W.UserInputType
                            == (
                                V.UserInputType == Enum.UserInputType.MouseButton1
                                    and Enum.UserInputType.MouseMovement
                                or Enum.UserInputType.Touch
                            )
                        then
                            L:SetValue(
                                nil,
                                M == "Saturation"
                                        and math.clamp((W.Position.X - Q.AbsolutePosition.X) / Q.AbsoluteSize.X, 0, 1)
                                    or nil,
                                M == "Vibrance"
                                        and math.clamp((W.Position.X - Q.AbsolutePosition.X) / Q.AbsoluteSize.X, 0, 1)
                                    or nil,
                                M == "Opacity"
                                        and math.clamp((W.Position.X - Q.AbsolutePosition.X) / Q.AbsoluteSize.X, 0, 1)
                                    or nil
                            )
                            if L._InternalCallback then
                                L._InternalCallback()
                            end
                        end
                    end)

                    local X
                    X = V.Changed:Connect(function()
                        if V.UserInputState == Enum.UserInputState.End then
                            if W then
                                W:Disconnect()
                            end
                            if X then
                                X:Disconnect()
                            end
                        end
                    end)
                end
            end)
            O.MouseEnter:Connect(function()
                n:Tween(U, o.Tween, {
                    Size = UDim2.fromOffset(16, 16),
                })
            end)
            O.MouseLeave:Connect(function()
                n:Tween(U, o.Tween, {
                    Size = UDim2.fromOffset(14, 14),
                })
            end)

            return O
        end

        local M = Instance.new("TextButton")
        M.Name = I.Name .. "Slider"
        M.Size = UDim2.new(1, 0, 0, 50)
        M.BackgroundColor3 = m.Dark(J.BackgroundColor3, I.Darker and 0.02 or 0)
        M.BorderSizePixel = 0
        M.AutoButtonColor = false
        M.Visible = I.Visible == nil or I.Visible
        M.Text = ""
        M.Parent = J
        addTooltip(M, I.Tooltip)
        local N = Instance.new("TextLabel")
        N.Name = "Title"
        N.Size = UDim2.fromOffset(60, 30)
        N.Position = UDim2.fromOffset(10, 2)
        N.BackgroundTransparency = 1
        N.Text = I.Name
        N.TextXAlignment = Enum.TextXAlignment.Left
        N.TextColor3 = o.MutedText
        N.TextSize = 11
        N.FontFace = o.Font
        N.Parent = M
        local O = Instance.new("TextBox")
        O.Name = "Box"
        O.Size = UDim2.fromOffset(60, 15)
        O.Position = UDim2.new(1, -69, 0, 9)
        O.BackgroundTransparency = 1
        O.Visible = false
        O.Text = ""
        O.TextXAlignment = Enum.TextXAlignment.Right
        O.TextColor3 = o.MutedText
        O.TextSize = 11
        O.FontFace = o.Font
        O.ClearTextOnFocus = true
        O.Parent = M
        local P = Instance.new("Frame")
        P.Name = "Slider"
        P.Size = UDim2.new(1, -20, 0, 2)
        P.Position = UDim2.fromOffset(10, 39)
        P.BackgroundColor3 = Color3.new(1, 1, 1)
        P.BorderSizePixel = 0
        P.Parent = M
        local Q = {}
        for R = 0, 1, 0.1 do
            table.insert(Q, ColorSequenceKeypoint.new(R, Color3.fromHSV(R, 1, 1)))
        end
        local R = Instance.new("UIGradient")
        R.Color = ColorSequence.new(Q)
        R.Parent = P
        local S = P:Clone()
        S.Name = "Fill"
        S.Size = UDim2.fromScale(math.clamp(L.Hue, 0, 1), 1)
        S.Position = UDim2.new()
        S.BackgroundTransparency = 1
        S.Parent = P
        local T = Instance.new("ImageButton")
        T.Name = "Preview"
        T.Size = UDim2.fromOffset(12, 12)
        T.Position = UDim2.new(1, -22, 0, 10)
        T.BackgroundTransparency = 1
        T.Image = u("badscript/assets/new/colorpreview.png")
        T.ImageColor3 = Color3.fromHSV(L.Hue, L.Sat, L.Value)
        T.ImageTransparency = 1 - L.Opacity
        T.Parent = M
        local U = Instance.new("TextButton")
        U.Name = "Expand"
        U.Size = UDim2.fromOffset(17, 13)
        U.Position = UDim2.new(0, i:GetTextSize(N.Text, N.TextSize, N.Font, Vector2.new(1000, 1000)).X + 11, 0, 7)
        U.BackgroundTransparency = 1
        U.Text = ""
        U.Parent = M
        local V = Instance.new("ImageLabel")
        V.Name = "Expand"
        V.Size = UDim2.fromOffset(9, 5)
        V.Position = UDim2.fromOffset(4, 4)
        V.BackgroundTransparency = 1
        V.Image = u("badscript/assets/new/expandicon.png")
        V.ImageColor3 = m.Dark(o.Text, 0.43)
        V.Parent = U
        local W = Instance.new("TextButton")
        W.Name = "Rainbow"
        W.Size = UDim2.fromOffset(12, 12)
        W.Position = UDim2.new(1, -42, 0, 10)
        W.BackgroundTransparency = 1
        W.Text = ""
        W.Parent = M
        local X = Instance.new("ImageLabel")
        X.Size = UDim2.fromOffset(12, 12)
        X.BackgroundTransparency = 1
        X.Image = u("badscript/assets/new/rainbow_1.png")
        X.ImageColor3 = m.Light(o.Main, 0.37)
        X.Parent = W
        local Y = X:Clone()
        Y.Image = u("badscript/assets/new/rainbow_2.png")
        Y.Parent = W
        local Z = X:Clone()
        Z.Image = u("badscript/assets/new/rainbow_3.png")
        Z.Parent = W
        local _ = X:Clone()
        _.Image = u("badscript/assets/new/rainbow_4.png")
        _.Parent = W
        local aa = Instance.new("Frame")
        aa.Name = "Knob"
        aa.Size = UDim2.fromOffset(24, 4)
        aa.Position = UDim2.fromScale(1, 0.5)
        aa.AnchorPoint = Vector2.new(0.5, 0.5)
        aa.BackgroundColor3 = M.BackgroundColor3
        aa.BorderSizePixel = 0
        aa.Parent = S
        local ab = Instance.new("Frame")
        ab.Name = "Knob"
        ab.Size = UDim2.fromOffset(14, 14)
        ab.Position = UDim2.fromScale(0.5, 0.5)
        ab.AnchorPoint = Vector2.new(0.5, 0.5)
        ab.BackgroundColor3 = o.Text
        ab.Parent = aa
        addCorner(ab, UDim.new(1, 0))
        I.Function = I.Function or function() end

        if K.OptionsVisibilityChanged ~= nil then
            K.OptionsVisibilityChanged:Connect(function(ac)
                if ac == nil then
                    ac = J.Visible
                end
                n:Tween(ab, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                    Size = ac and UDim2.fromOffset(14, 14) or UDim2.fromOffset(0, 0),
                })
            end)
        end

        local ac = createSlider(
            "Saturation",
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, L.Value)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(L.Hue, 1, L.Value)),
            })
        )
        local ad = createSlider(
            "Vibrance",
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(L.Hue, L.Sat, 1)),
            })
        )
        local ae = createSlider(
            "Opacity",
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, m.Dark(o.Main, 0.02)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(L.Hue, L.Sat, L.Value)),
            })
        )

        function L.Save(af, ag)
            ag[I.Name] = {
                Hue = af.Hue,
                Sat = af.Sat,
                Value = af.Value,
                Opacity = af.Opacity,
                Rainbow = af.Rainbow,
            }
        end

        function L.Load(af, ag)
            if ag.Rainbow ~= af.Rainbow then
                af:Toggle()
            end
            if af.Hue ~= ag.Hue or af.Sat ~= ag.Sat or af.Value ~= ag.Value or af.Opacity ~= ag.Opacity then
                af:SetValue(ag.Hue, ag.Sat, ag.Value, ag.Opacity, false)
            end
        end

        function L.ConnectCallback(af, ag)
            if not (ag ~= nil and type(ag) == "function") then
                return
            end
            if L._InternalCallback and shared.VoidDev then
                bwarn(debug.traceback(`Overriding InternalCallback!!!`))
            end
            L._InternalCallback = wrap(ag)
        end

        function L.SetValue(af, ag, ah, ai, aj, ak)
            if ag ~= nil then
                af.Hue = math.clamp(tonumber(ag) or af.Hue, 0, 1)
            end
            if ah ~= nil then
                af.Sat = math.clamp(tonumber(ah) or af.Sat, 0, 1)
            end
            if ai ~= nil then
                af.Value = math.clamp(tonumber(ai) or af.Value, 0, 1)
            end
            if aj ~= nil then
                af.Opacity = math.clamp(tonumber(aj) or af.Opacity, 0, 1)
            end
            T.ImageColor3 = Color3.fromHSV(af.Hue, af.Sat, af.Value)
            T.ImageTransparency = 1 - af.Opacity
            ac.Slider.UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, af.Value)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(af.Hue, 1, af.Value)),
            })
            ad.Slider.UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(af.Hue, af.Sat, 1)),
            })
            ae.Slider.UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, m.Dark(o.Main, 0.02)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(af.Hue, af.Sat, af.Value)),
            })

            if af.Rainbow then
                S.Size = UDim2.fromScale(math.clamp(af.Hue, 0, 1), 1)
            else
                n:Tween(S, o.Tween, {
                    Size = UDim2.fromScale(math.clamp(af.Hue, 0, 1), 1),
                })
            end

            if ah then
                n:Tween(ac.Slider.Fill, o.Tween, {
                    Size = UDim2.fromScale(math.clamp(af.Sat, 0, 1), 1),
                })
            end
            if ai then
                n:Tween(ad.Slider.Fill, o.Tween, {
                    Size = UDim2.fromScale(math.clamp(af.Value, 0, 1), 1),
                })
            end
            if aj then
                n:Tween(ae.Slider.Fill, o.Tween, {
                    Size = UDim2.fromScale(math.clamp(af.Opacity, 0, 1), 1),
                })
            end

            if not ak then
                I.Function(af.Hue, af.Sat, af.Value, af.Opacity)
            end
        end

        function L.ToColor(af)
            return Color3.fromHSV(af.Hue, af.Sat, af.Value)
        end

        function L.Toggle(af)
            af.Rainbow = not af.Rainbow
            if af.Rainbow then
                if not table.find(d.RainbowTable, af) then
                    table.insert(d.RainbowTable, af)
                end
                X.ImageColor3 = Color3.fromRGB(5, 127, 100)
                task.delay(0.1, function()
                    if not af.Rainbow then
                        return
                    end
                    Y.ImageColor3 = Color3.fromRGB(228, 125, 43)
                    task.delay(0.1, function()
                        if not af.Rainbow then
                            return
                        end
                        Z.ImageColor3 = Color3.fromRGB(225, 46, 52)
                    end)
                end)
            else
                local ag = table.find(d.RainbowTable, af)
                if ag then
                    table.remove(d.RainbowTable, ag)
                end
                Z.ImageColor3 = m.Light(o.Main, 0.37)
                task.delay(0.1, function()
                    if af.Rainbow then
                        return
                    end
                    Y.ImageColor3 = m.Light(o.Main, 0.37)
                    task.delay(0.1, function()
                        if af.Rainbow then
                            return
                        end
                        X.ImageColor3 = m.Light(o.Main, 0.37)
                    end)
                end)
            end
        end

        local af = tick()
        T.Activated:Connect(function()
            T.Visible = false
            O.Visible = true
            O:CaptureFocus()
            local ag = Color3.fromHSV(L.Hue, L.Sat, L.Value)
            O.Text = math.round(ag.R * 255) .. ", " .. math.round(ag.G * 255) .. ", " .. math.round(ag.B * 255)
        end)

        if d.isMobile then
            M.Size = UDim2.new(1, 0, 0, 58)
        end
        M.InputBegan:Connect(function(ag)
            if
                (ag.UserInputType == Enum.UserInputType.MouseButton1 or ag.UserInputType == Enum.UserInputType.Touch)
                and (ag.Position.Y - M.AbsolutePosition.Y) > (20 * A.Scale)
            then
                if af > tick() then
                    L:Toggle()
                end
                af = tick() + 0.3
                local ah = h.InputChanged:Connect(function(ah)
                    if
                        ah.UserInputType
                        == (
                            ag.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement
                            or Enum.UserInputType.Touch
                        )
                    then
                        L:SetValue(
                            math.clamp((ah.Position.X - P.AbsolutePosition.X) / P.AbsoluteSize.X, 0, 1),
                            nil,
                            nil,
                            nil,
                            true
                        )
                        if L._InternalCallback then
                            L._InternalCallback()
                        end
                    end
                end)

                local ai
                ai = ag.Changed:Connect(function()
                    if ag.UserInputState == Enum.UserInputState.End then
                        if ah then
                            ah:Disconnect()
                        end
                        if ai then
                            ai:Disconnect()
                        end
                    end
                end)
            end
        end)
        M.MouseEnter:Connect(function()
            n:Tween(ab, o.Tween, {
                Size = UDim2.fromOffset(16, 16),
            })
        end)
        M.MouseLeave:Connect(function()
            n:Tween(ab, o.Tween, {
                Size = UDim2.fromOffset(14, 14),
            })
        end)
        M:GetPropertyChangedSignal("Visible"):Connect(function()
            ac.Visible = V.Rotation == 180 and M.Visible
            ad.Visible = ac.Visible
            ae.Visible = ac.Visible
        end)
        U.MouseEnter:Connect(function()
            V.ImageColor3 = m.Dark(o.Text, 0.16)
        end)
        U.MouseLeave:Connect(function()
            V.ImageColor3 = m.Dark(o.Text, 0.43)
        end)
        U.Activated:Connect(function()
            ac.Visible = not ac.Visible
            ad.Visible = ac.Visible
            ae.Visible = ac.Visible
            V.Rotation = ac.Visible and 180 or 0
        end)
        W.Activated:Connect(function()
            L:Toggle()
        end)
        O.FocusLost:Connect(function(ag)
            T.Visible = true
            O.Visible = false
            if ag then
                local components = O.Text:split(",")
                local ai, aj = pcall(function()
                    if #components == 3 then
                        local red = tonumber(components[1])
                        local green = tonumber(components[2])
                        local blue = tonumber(components[3])
                        if not red or not green or not blue then
                            error("invalid RGB value")
                        end
                        return Color3.fromRGB(
                            math.clamp(red, 0, 255),
                            math.clamp(green, 0, 255),
                            math.clamp(blue, 0, 255)
                        )
                    end
                    local hex = O.Text:gsub("#", "")
                    if not hex:match("^[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$") then
                        error("invalid hex value")
                    end
                    return Color3.fromHex(hex)
                end)
                if ai and aj then
                    if L.Rainbow then
                        L:Toggle()
                    end
                    L:SetValue(aj:ToHSV())
                    if L._InternalCallback then
                        L._InternalCallback()
                    end
                end
            end
        end)

        M.Destroying:Once(function()
            local index = table.find(d.RainbowTable, L)
            if index then
                table.remove(d.RainbowTable, index)
            end
        end)
        L.Object = M
        K.Options[I.Name] = L

        return L
    end,
    Dropdown = function(settings, parent, owner)
        settings.List = settings.List or settings.Values or {}
        settings.Default = settings.Default or settings.Value
        settings.Function = settings.Function or function() end

        local function containsValue(list, value)
            for _, item in ipairs(list) do
                if item == value then
                    return true
                end
            end
            return false
        end

        local initialValue =
            containsValue(settings.List, settings.Default)
                and settings.Default
            or settings.List[1]
            or "None"

        local api = {
            Type = "Dropdown",
            Value = initialValue,
            Index = 0,
        }

        local baseSize =
            settings.Size
            or UDim2.new(1, 0, 0, d.isMobile and 48 or 42)

        local root = Instance.new("TextButton")
        root.Name = tostring(settings.Name) .. "Dropdown"
        root.Size = baseSize
        root.BackgroundTransparency = 1
        root.BorderSizePixel = 0
        root.AutoButtonColor = false
        root.Visible = settings.Visible == nil or settings.Visible
        root.Text = ""
        root.ClipsDescendants = false
        root.Parent = parent
        addTooltip(root, settings.Tooltip or settings.Name)

        local background = Instance.new("Frame")
        background.Name = "BKG"
        background.Size = UDim2.new(
            1,
            -16,
            0,
            baseSize.Y.Offset - 7
        )
        background.Position = UDim2.fromOffset(8, 3)
        background.BackgroundColor3 =
            settings.Darker and o.MainSoft or o.Surface
        background.BackgroundTransparency = 0.08
        background.BorderSizePixel = 0
        background.Parent = root
        addCorner(background, o.Radius)

        local stroke = addStroke(
            background,
            o.Border,
            0.78,
            1,
            "DropdownStroke"
        )

        local button = Instance.new("TextButton")
        button.Name = "Dropdown"
        button.Size = UDim2.new(1, -2, 1, -2)
        button.Position = UDim2.fromOffset(1, 1)
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.Parent = background
        addCorner(button, o.RadiusSmall)

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -42, 1, 0)
        title.Position = UDim2.fromOffset(13, 0)
        title.BackgroundTransparency = 1
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = o.MutedText
        title.TextSize = d.isMobile and 14 or 13
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.FontFace = o.FontSemiBold
        title.Parent = button

        local arrow = Instance.new("ImageLabel")
        arrow.Name = "Arrow"
        arrow.Size = UDim2.fromOffset(5, 9)
        arrow.Position = UDim2.new(1, -20, 0.5, -4)
        arrow.BackgroundTransparency = 1
        arrow.Image = u("badscript/assets/new/expandright.png")
        arrow.ImageColor3 = o.FaintText
        arrow.Rotation = 90
        arrow.Parent = button

        local popup
        local popupScale
        local popupStroke
        local search
        local scroll
        local noResults
        local outsideConnection
        local scrollConnection
        local popupGeneration = 0
        local popupOpen = false
        local rowHeight = d.isMobile and 44 or 34
        local maxRows = 7
        local poolSize = maxRows + 2
        local rowButtons = {}
        local rowRails = {}
        local rowBindings = setmetatable({}, { __mode = "k" })
        local hoveredRows = setmetatable({}, { __mode = "k" })
        local filtered = {}
        local dropdownTransition = TweenInfo.new(
            0.075,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        )

        local function updateTitle()
            title.Text =
                tostring(settings.Name)
                .. "   "
                .. tostring(api.Value)
        end

        local function pointInObject(point, object)
            if not object or not object.Parent or not object.Visible then
                return false
            end

            local position = object.AbsolutePosition
            local size = object.AbsoluteSize

            return point.X >= position.X
                and point.X <= position.X + size.X
                and point.Y >= position.Y
                and point.Y <= position.Y + size.Y
        end

        local function applyRowVisual(option, animate)
            local entry = rowBindings[option]
            if not entry then
                return
            end

            local selected = entry.Value == api.Value
            local hovered = hoveredRows[option] == true
            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            local target = {
                BackgroundColor3 = hovered and o.SurfaceHover
                    or (selected and o.Elevated or o.Surface),
                BackgroundTransparency = hovered and 0.02
                    or (selected and 0.08 or 0.34),
                TextColor3 = hovered and o.TextStrong
                    or (selected and o.Text or o.MutedText),
            }

            option.FontFace = selected and o.FontSemiBold or o.Font
            local rail = rowRails[option]
            if rail then
                rail.Visible = selected
                rail.BackgroundColor3 = accent
            end

            if animate then
                n:Tween(option, o.TweenFast, target)
            else
                for property, value in pairs(target) do
                    option[property] = value
                end
            end
        end

        local function updateVirtualRows(animate)
            if not scroll then
                return
            end

            local firstIndex = math.max(
                1,
                math.floor(scroll.CanvasPosition.Y / rowHeight) + 1
            )

            for poolIndex, option in ipairs(rowButtons) do
                local dataIndex = firstIndex + poolIndex - 1
                local entry = filtered[dataIndex]
                rowBindings[option] = entry

                if entry then
                    option.Visible = true
                    option.Position = UDim2.fromOffset(
                        2,
                        (dataIndex - 1) * rowHeight
                    )
                    option.Text = "   " .. entry.Display
                    applyRowVisual(option, animate == true)
                else
                    option.Visible = false
                    hoveredRows[option] = nil
                end
            end
        end

        local function positionPopup(height)
            if not popup or not popup.Parent then
                return
            end

            local scale = math.max(A.Scale, 0.01)
            local rootPosition = root.AbsolutePosition
            local rootSize = root.AbsoluteSize
            local rootOrigin = w.AbsolutePosition
            local viewportWidth = B.AbsoluteSize.X / scale
            local viewportHeight = B.AbsoluteSize.Y / scale
            local popupWidth = math.clamp(
                math.max(
                    188,
                    (rootSize.X / scale) - 12
                ),
                188,
                math.max(188, viewportWidth - 16)
            )
            local x = (rootPosition.X - rootOrigin.X) / scale + 8
            local belowY =
                (rootPosition.Y - rootOrigin.Y) / scale
                + (rootSize.Y / scale)
                - 2
            local aboveY =
                (rootPosition.Y - rootOrigin.Y) / scale
                - height
                + 2

            x = math.clamp(
                x,
                8,
                math.max(8, viewportWidth - popupWidth - 8)
            )

            local y =
                belowY + height <= viewportHeight - 8
                    and belowY
                or math.max(8, aboveY)

            popup.Position = UDim2.fromOffset(x, y)
            popup.Size = UDim2.fromOffset(popupWidth, height)
        end

        local function rebuildFiltered(query)
            table.clear(filtered)
            query = tostring(query or ""):lower()
            for _, item in ipairs(settings.List) do
                local display = tostring(item)
                if query == ""
                    or string.find(display:lower(), query, 1, true) ~= nil
                then
                    filtered[#filtered + 1] = {
                        Value = item,
                        Display = display,
                    }
                end
            end
        end

        local function refreshPopup(query, keepScroll)
            if not popup then
                return
            end

            rebuildFiltered(query)
            local showSearch =
                settings.Search == true
                or (
                    settings.Search ~= false
                    and #settings.List > maxRows
                )
            local searchHeight = showSearch and 36 or 0
            search.Visible = showSearch
            scroll.Position = UDim2.fromOffset(
                5,
                5 + searchHeight
            )

            local visibleCount = #filtered
            local rows = math.max(
                1,
                math.min(maxRows, visibleCount)
            )
            local listHeight = rows * rowHeight
            local popupHeight = 10 + searchHeight + listHeight

            noResults.Visible = visibleCount == 0
            scroll.Size = UDim2.new(
                1,
                -10,
                0,
                listHeight
            )
            scroll.CanvasSize = UDim2.fromOffset(
                0,
                math.max(rowHeight, visibleCount * rowHeight)
            )

            if not keepScroll then
                local selectedIndex
                for index, entry in ipairs(filtered) do
                    if entry.Value == api.Value then
                        selectedIndex = index
                        break
                    end
                end

                if selectedIndex then
                    local targetY = math.max(
                        0,
                        (selectedIndex - 3) * rowHeight
                    )
                    local maxY = math.max(
                        0,
                        visibleCount * rowHeight - listHeight
                    )
                    scroll.CanvasPosition = Vector2.new(
                        0,
                        math.clamp(targetY, 0, maxY)
                    )
                else
                    scroll.CanvasPosition = Vector2.zero
                end
            else
                local maxY = math.max(
                    0,
                    visibleCount * rowHeight - listHeight
                )
                scroll.CanvasPosition = Vector2.new(
                    0,
                    math.clamp(scroll.CanvasPosition.Y, 0, maxY)
                )
            end

            positionPopup(popupHeight)
            updateVirtualRows(false)
        end

        local function ensurePopup()
            if popup and popup.Parent then
                return
            end

            popup = Instance.new("CanvasGroup")
            popup.Name = tostring(settings.Name) .. "DropdownPopup"
            popup.Size = UDim2.fromOffset(188, rowHeight + 10)
            popup.BackgroundColor3 = o.MainSoft
            popup.BackgroundTransparency = 0.005
            popup.GroupTransparency = 1
            popup.BorderSizePixel = 0
            popup.ZIndex = 20000
            popup.Visible = false
            popup.Active = false
            popup.Interactable = false
            popup.Parent = w
            addCorner(popup, o.RadiusLarge)
            popupStroke = addStroke(
                popup,
                o.BorderStrong,
                0.58,
                1,
                "DropdownPopupStroke"
            )
            popupScale = addScale(popup)
            popupScale.Scale = 0.975
            addShadow(popup, true)
            addSurfaceGradient(popup)
            addV9Chrome(popup)

            local accentLine = Instance.new("Frame")
            accentLine.Name = "Accent"
            accentLine.Size = UDim2.new(1, -20, 0, 2)
            accentLine.Position = UDim2.fromOffset(10, 0)
            accentLine.BackgroundColor3 = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            accentLine.BackgroundTransparency = 0.18
            accentLine.BorderSizePixel = 0
            accentLine.ZIndex = 20003
            accentLine.Parent = popup
            addCorner(accentLine, UDim.new(1, 0))
            connectguicolorchange(function(hue, saturation, value)
                if accentLine.Parent then
                    accentLine.BackgroundColor3 =
                        Color3.fromHSV(hue, saturation, value)
                end
            end)

            search = Instance.new("TextBox")
            search.Name = "SearchBar"
            search.Size = UDim2.new(1, -12, 0, 29)
            search.Position = UDim2.fromOffset(6, 5)
            search.BackgroundColor3 = o.MainSoft
            search.BackgroundTransparency = 0.08
            search.BorderSizePixel = 0
            search.PlaceholderText = "Search options"
            search.PlaceholderColor3 = o.FaintText
            search.Text = ""
            search.TextColor3 = o.Text
            search.TextSize = d.isMobile and 14 or 13
            search.FontFace = o.Font
            search.ClearTextOnFocus = false
            search.ZIndex = 20002
            search.Parent = popup
            addCorner(search, o.RadiusSmall)
            addStroke(
                search,
                o.Border,
                0.78,
                1,
                "DropdownSearchStroke"
            )

            scroll = Instance.new("ScrollingFrame")
            scroll.Name = "Scroll"
            scroll.Position = UDim2.fromOffset(5, 5)
            scroll.Size = UDim2.new(1, -10, 0, rowHeight)
            scroll.BackgroundTransparency = 1
            scroll.BorderSizePixel = 0
            scroll.ScrollBarImageColor3 = o.BorderStrong
            scroll.ScrollBarImageTransparency =
                d.isMobile and 0.24 or 0.62
            scroll.ScrollBarThickness =
                d.isMobile and 6 or 3
            scroll.VerticalScrollBarInset =
                Enum.ScrollBarInset.ScrollBar
            scroll.ElasticBehavior =
                Enum.ElasticBehavior.Never
            scroll.AutomaticCanvasSize =
                Enum.AutomaticSize.None
            scroll.CanvasSize = UDim2.new()
            scroll.ScrollingDirection =
                Enum.ScrollingDirection.Y
            scroll.ZIndex = 20001
            scroll.Parent = popup

            noResults = Instance.new("TextLabel")
            noResults.Name = "NoResults"
            noResults.Size = UDim2.new(1, 0, 0, rowHeight)
            noResults.BackgroundTransparency = 1
            noResults.Text = "No matching options"
            noResults.TextColor3 = o.MutedText
            noResults.TextSize = d.isMobile and 14 or 13
            noResults.FontFace = o.Font
            noResults.Visible = false
            noResults.ZIndex = 20002
            noResults.Parent = scroll

            for index = 1, poolSize do
                local option = Instance.new("TextButton")
                option.Name = "VirtualOption_" .. tostring(index)
                option.Size = UDim2.new(
                    1,
                    -4,
                    0,
                    rowHeight - 2
                )
                option.BackgroundColor3 = o.Surface
                option.BackgroundTransparency = 0.18
                option.BorderSizePixel = 0
                option.AutoButtonColor = false
                option.Text = ""
                option.TextColor3 = o.MutedText
                option.TextXAlignment = Enum.TextXAlignment.Left
                option.TextSize = d.isMobile and 14 or 13
                option.FontFace = o.Font
                option.Visible = false
                option.ZIndex = 20002
                option.Parent = scroll
                addCorner(option, o.RadiusSmall)

                local rail = Instance.new("Frame")
                rail.Name = "SelectedRail"
                rail.Size = UDim2.fromOffset(2, 16)
                rail.AnchorPoint = Vector2.new(0, 0.5)
                rail.Position = UDim2.new(0, 1, 0.5, 0)
                rail.BorderSizePixel = 0
                rail.Visible = false
                rail.ZIndex = option.ZIndex + 1
                rail.Parent = option
                addCorner(rail, UDim.new(1, 0))

                rowButtons[index] = option
                rowRails[option] = rail

                if not d.isMobile then
                    option.MouseEnter:Connect(function()
                        hoveredRows[option] = true
                        applyRowVisual(option, true)
                    end)
                    option.MouseLeave:Connect(function()
                        hoveredRows[option] = nil
                        applyRowVisual(option, true)
                    end)
                end

                option.Activated:Connect(function()
                    local entry = rowBindings[option]
                    if entry then
                        api:SetValue(entry.Value, true)
                    end
                end)
            end

            search:GetPropertyChangedSignal("Text"):Connect(function()
                if popupOpen then
                    refreshPopup(search.Text, false)
                end
            end)

            scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
                updateVirtualRows(false)
            end)
        end

        local function closeDropdown(instant)
            popupGeneration += 1
            local closeGeneration = popupGeneration
            popupOpen = false

            if outsideConnection then
                outsideConnection:Disconnect()
                outsideConnection = nil
            end
            if scrollConnection then
                scrollConnection:Disconnect()
                scrollConnection = nil
            end
            if d._OpenDropdown == closeDropdown then
                d._OpenDropdown = nil
            end

            if instant then
                arrow.Rotation = 90
                arrow.ImageColor3 = o.FaintText
                background.BackgroundColor3 =
                    settings.Darker and o.MainSoft or o.Surface
                background.BackgroundTransparency = 0.08
                stroke.Color = o.Border
                stroke.Transparency = 0.78
            else
                n:Tween(arrow, dropdownTransition, {
                    Rotation = 90,
                    ImageColor3 = o.FaintText,
                })
                n:Tween(background, dropdownTransition, {
                    BackgroundColor3 =
                        settings.Darker and o.MainSoft or o.Surface,
                    BackgroundTransparency = 0.08,
                })
                n:Tween(stroke, dropdownTransition, {
                    Color = o.Border,
                    Transparency = 0.78,
                })
            end

            if not popup or not popup.Parent then
                return
            end

            popup.Active = false
            popup.Interactable = false

            if instant or not d.Loaded then
                popup.Visible = false
                popup.GroupTransparency = 1
                popupScale.Scale = 0.985
                return
            end

            local fade = n:Tween(popup, dropdownTransition, {
                GroupTransparency = 1,
                BackgroundTransparency = 0.08,
            })
            n:Spring(popupScale, o.SpringInteractive, {
                Scale = 0.985,
            })
            n:Tween(popupStroke, dropdownTransition, {
                Transparency = 0.82,
            })

            local function finishClose()
                if popup
                    and popup.Parent
                    and not popupOpen
                    and closeGeneration == popupGeneration
                then
                    popup.Visible = false
                end
            end

            if fade then
                fade.Completed:Once(finishClose)
            else
                finishClose()
            end
        end

        local function openDropdown()
            if popupOpen then
                closeDropdown()
                return
            end

            if d._OpenDropdown and d._OpenDropdown ~= closeDropdown then
                pcall(d._OpenDropdown)
            end

            ensurePopup()
            popupGeneration += 1
            popupOpen = true
            d._OpenDropdown = closeDropdown

            refreshPopup(search.Text, false)
            popup.Visible = true
            popup.Active = true
            popup.Interactable = true
            popup.GroupTransparency = 0.08
            popup.BackgroundTransparency = 0.08
            popupScale.Scale = 0.985
            popupStroke.Transparency = 0.82

            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            n:Tween(arrow, dropdownTransition, {
                Rotation = 270,
                ImageColor3 = accent,
            })
            n:Tween(background, dropdownTransition, {
                BackgroundColor3 = o.SurfaceHover,
                BackgroundTransparency = 0.02,
            })
            n:Tween(stroke, dropdownTransition, {
                Color = accent:Lerp(o.BorderStrong, 0.58),
                Transparency = 0.38,
            })
            n:Tween(popup, dropdownTransition, {
                GroupTransparency = 0,
                BackgroundTransparency = 0.02,
            })
            n:Spring(popupScale, o.SpringInteractive, {
                Scale = 1,
            })
            n:Tween(popupStroke, dropdownTransition, {
                Color = accent:Lerp(o.BorderStrong, 0.72),
                Transparency = 0.48,
            })

            local scrollingParent = parent
            while
                scrollingParent
                and not scrollingParent:IsA("ScrollingFrame")
            do
                scrollingParent = scrollingParent.Parent
            end

            if scrollingParent then
                scrollConnection =
                    scrollingParent:GetPropertyChangedSignal(
                        "CanvasPosition"
                    ):Connect(function()
                        closeDropdown(true)
                    end)
            end

            outsideConnection = h.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Escape then
                    closeDropdown()
                    return
                end

                if input.UserInputType
                        == Enum.UserInputType.MouseButton1
                    or input.UserInputType
                        == Enum.UserInputType.Touch
                then
                    local point = input.Position
                    if not pointInObject(point, root)
                        and not pointInObject(point, popup)
                    then
                        closeDropdown()
                    end
                end
            end)
        end

        function api.Save(self, target)
            if not settings.NoSave then
                target[settings.Name] = {
                    Value = self.Value,
                }
            end
        end

        function api.Load(self, saved)
            if settings.NoSave or type(saved) ~= "table" then
                return
            end
            self:SetValue(saved.Value, false)
        end

        function api.Change(self, newList, suppressCallback)
            settings.List =
                type(newList) == "table" and newList or {}

            local desired =
                containsValue(settings.List, self.Value)
                    and self.Value
                or settings.List[1]
                or "None"

            self:SetValue(desired, not suppressCallback)
            if popup then
                refreshPopup(search.Text, false)
            end
        end

        function api.SetValues(self, newList, newValue)
            settings.List =
                type(newList) == "table" and newList or {}

            local desired =
                newValue ~= nil and newValue or self.Value

            if not containsValue(settings.List, desired) then
                desired = settings.List[1] or "None"
            end

            self:SetValue(desired, false)
            if popup then
                refreshPopup(search.Text, false)
            end
        end

        function api.SetCallback(self, callback)
            if type(callback) == "function" then
                settings.Function = callback
            end
        end

        function api.SetValue(self, value, fromUser)
            local selected =
                containsValue(settings.List, value)
                    and value
                or settings.List[1]
                or "None"

            local changed = self.Value ~= selected
            self.Value = selected
            updateTitle()

            if popup then
                refreshPopup(search.Text, true)
            end
            closeDropdown()

            if changed or fromUser then
                settings.Function(self.Value, fromUser)
            end
        end

        updateTitle()
        button.Activated:Connect(openDropdown)

        root.MouseEnter:Connect(function()
            if popupOpen then
                return
            end

            n:Tween(background, o.TweenFast, {
                BackgroundColor3 = o.SurfaceHover,
                BackgroundTransparency = 0.03,
            })
            n:Tween(stroke, o.TweenFast, {
                Color = o.BorderStrong,
                Transparency = 0.58,
            })
        end)

        root.MouseLeave:Connect(function()
            if popupOpen then
                return
            end

            n:Tween(background, o.TweenFast, {
                BackgroundColor3 =
                    settings.Darker and o.MainSoft or o.Surface,
                BackgroundTransparency = 0.08,
            })
            n:Tween(stroke, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.78,
            })
        end)

        root.Destroying:Once(function()
            closeDropdown(true)
            if popup and popup.Parent then
                popup:Destroy()
            end
        end)

        api.Object = root
        owner.Options[settings.Name] = api
        return api
    end,
    Font = function(settings, parent, owner)
        settings.Function = settings.Function or function() end
        local blocked = {}
        if type(settings.Blacklist) == "string" then
            blocked[settings.Blacklist] = true
        elseif type(settings.Blacklist) == "table" then
            for _, name in settings.Blacklist do
                blocked[tostring(name)] = true
            end
        end

        local choices = {}
        for _, fontItem in Enum.Font:GetEnumItems() do
            if fontItem ~= Enum.Font.Unknown and not blocked[fontItem.Name] then
                choices[#choices + 1] = fontItem.Name
            end
        end
        table.sort(choices)
        choices[#choices + 1] = "Custom"

        local defaultName = settings.Default
        if not table.find(choices, defaultName) then
            defaultName = table.find(choices, "Gotham") and "Gotham" or choices[1]
        end
        local api = { Value = o.Font }
        local dropdown
        local assetBox

        local function setEnumFont(name, notify)
            local enumFont = Enum.Font[name]
            if not enumFont or enumFont == Enum.Font.Unknown then
                return false
            end
            local success, font = pcall(Font.fromEnum, enumFont)
            if success and typeof(font) == "Font" then
                api.Value = font
                if notify ~= false then
                    settings.Function(api.Value)
                end
                return true
            end
            return false
        end

        local function setCustomFont(value, notify)
            local assetId = tonumber(value)
            if not assetId then
                return false
            end
            local success, font = pcall(Font.fromId, assetId)
            if success and typeof(font) == "Font" then
                api.Value = font
                if notify ~= false then
                    settings.Function(api.Value)
                end
                return true
            end
            return false
        end

        dropdown = H.Dropdown({
            Name = settings.Name,
            List = choices,
            Function = function(selected)
                assetBox.Object.Visible = selected == "Custom" and dropdown.Object.Visible
                if selected == "Custom" then
                    setCustomFont(assetBox.Value)
                else
                    setEnumFont(selected)
                end
            end,
            Darker = settings.Darker,
            Visible = settings.Visible,
            Default = defaultName,
        }, parent, owner)
        api.Object = dropdown.Object

        assetBox = H.TextBox({
            Name = settings.Name .. " Asset",
            Placeholder = "font asset id",
            Function = function(value)
                if dropdown.Value == "Custom" then
                    setCustomFont(value)
                end
            end,
            Visible = false,
            Darker = true,
        }, parent, owner)

        dropdown.Object:GetPropertyChangedSignal("Visible"):Connect(function()
            assetBox.Object.Visible = dropdown.Object.Visible and dropdown.Value == "Custom"
        end)
        if defaultName and defaultName ~= "Custom" then
            setEnumFont(defaultName, false)
        end
        return api
    end,
    Slider = function(settings, parent, owner)
        settings.Min = tonumber(settings.Min) or 0
        settings.Max = tonumber(settings.Max) or settings.Min
        if settings.Max < settings.Min then
            settings.Min, settings.Max = settings.Max, settings.Min
        end
        settings.Decimal = math.max(tonumber(settings.Decimal) or 1, 0.000001)
        settings.Function = settings.Function or function() end

        local function clampValue(value)
            value = tonumber(value)
            if not value or value ~= value or value == math.huge or value == -math.huge then
                return nil
            end
            local rounded = math.floor(value * settings.Decimal + 0.5) / settings.Decimal
            return math.clamp(rounded, settings.Min, settings.Max)
        end

        local function ratioFor(value)
            local range = settings.Max - settings.Min
            if range <= 0 then
                return 0
            end
            return math.clamp((value - settings.Min) / range, 0, 1)
        end

        local initial = clampValue(settings.Default) or settings.Min
        local api = {
            Type = "Slider",
            Value = initial,
            Max = settings.Max,
            Index = getTableSize(owner.Options),
        }

        local root = Instance.new("TextButton")
        root.Name = tostring(settings.Name) .. "Slider"
        root.Size = UDim2.new(1, 0, 0, d.isMobile and 58 or 50)
        root.BackgroundTransparency = 1
        root.BorderSizePixel = 0
        root.AutoButtonColor = false
        root.Visible = settings.Visible == nil or settings.Visible
        root.Text = ""
        root.Parent = parent
        addTooltip(root, settings.Tooltip)

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -100, 0, 26)
        title.Position = UDim2.fromOffset(12, 2)
        title.BackgroundTransparency = 1
        title.Text = tostring(settings.Name)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = o.MutedText
        title.TextSize = d.isMobile and 13 or 12
        title.FontFace = o.FontSemiBold
        title.Parent = root

        local valueButton = Instance.new("TextButton")
        valueButton.Name = "Value"
        valueButton.Size = UDim2.fromOffset(82, 22)
        valueButton.Position = UDim2.new(1, -92, 0, 4)
        valueButton.BackgroundColor3 = o.MainSoft
        valueButton.BackgroundTransparency = 0
        valueButton.BorderSizePixel = 0
        valueButton.TextXAlignment = Enum.TextXAlignment.Center
        valueButton.TextColor3 = o.Text
        valueButton.TextSize = d.isMobile and 13 or 11
        valueButton.FontFace = o.FontSemiBold
        valueButton.Parent = root
        addCorner(valueButton, o.RadiusSmall)
        addStroke(valueButton, o.Border, 0.68, 1, "ValueStroke")

        local valueBox = Instance.new("TextBox")
        valueBox.Name = "Box"
        valueBox.Size = valueButton.Size
        valueBox.Position = valueButton.Position
        valueBox.BackgroundColor3 = o.Surface
        valueBox.BackgroundTransparency = 0
        valueBox.Visible = false
        valueBox.TextXAlignment = Enum.TextXAlignment.Center
        valueBox.TextColor3 = o.Text
        valueBox.TextSize = d.isMobile and 13 or 11
        valueBox.FontFace = o.Font
        valueBox.ClearTextOnFocus = false
        valueBox.Parent = root
        addCorner(valueBox, o.RadiusSmall)
        addStroke(valueBox, Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value), 0.25, 1, "ValueBoxStroke")

        local track = Instance.new("Frame")
        track.Name = "Slider"
        track.Size = UDim2.new(1, -24, 0, 5)
        track.Position = UDim2.new(0, 12, 1, -14)
        track.BackgroundColor3 = o.Elevated
        track.BorderSizePixel = 0
        track.Parent = root
        addCorner(track, UDim.new(1, 0))
        addStroke(track, o.Border, 0.72, 1, "TrackStroke")

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.Size = UDim2.fromScale(ratioFor(api.Value), 1)
        fill.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        fill.BorderSizePixel = 0
        fill.Parent = track
        addCorner(fill, UDim.new(1, 0))
        local fillGradient = Instance.new("UIGradient")
        fillGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromHSV(d.GUIColor.Hue, math.max(d.GUIColor.Sat - 0.18, 0), d.GUIColor.Value)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, math.min(d.GUIColor.Value + 0.22, 1))
            ),
        })
        fillGradient.Parent = fill

        local knobHolder = Instance.new("Frame")
        knobHolder.Name = "KnobHolder"
        knobHolder.Size = UDim2.fromOffset(1, 1)
        knobHolder.Position = UDim2.fromScale(1, 0.5)
        knobHolder.AnchorPoint = Vector2.new(0.5, 0.5)
        knobHolder.BackgroundTransparency = 1
        knobHolder.Parent = fill
        local knob = Instance.new("Frame")
        knob.Name = "Knob"
        knob.Size = UDim2.fromOffset(d.isMobile and 18 or 14, d.isMobile and 18 or 14)
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.fromScale(0.5, 0.5)
        knob.BackgroundColor3 = o.TextStrong
        knob.Parent = knobHolder
        addCorner(knob, UDim.new(1, 0))
        local knobStroke = Instance.new("UIStroke")
        knobStroke.Color = fill.BackgroundColor3
        knobStroke.Thickness = 2
        knobStroke.Transparency = 0.12
        knobStroke.Parent = knob
        local knobScale = addScale(knob)

        local function formatValue(value)
            local suffix = settings.Suffix
                    and " " .. tostring(
                        type(settings.Suffix) == "function" and settings.Suffix(value) or settings.Suffix
                    )
                or ""
            return tostring(value) .. suffix
        end

        local function updateVisual(instant)
            local properties = { Size = UDim2.fromScale(ratioFor(api.Value), 1) }
            if instant then
                fill.Size = properties.Size
            else
                n:Tween(fill, o.Tween, properties)
            end
            valueButton.Text = formatValue(api.Value)
        end
        updateVisual(true)

        function api.Save(self, target)
            target[settings.Name] = { Value = self.Value, Max = self.Max }
        end
        function api.Load(self, saved)
            if type(saved) ~= "table" then
                return
            end
            local value = saved.Value == saved.Max and saved.Max ~= self.Max and self.Max or saved.Value
            self:SetValue(value, nil, true)
        end
        function api.Color(self, hue, saturation, value, rainbow)
            fill.BackgroundColor3 = rainbow and Color3.fromHSV(d:Color((hue - (self.Index * 0.075)) % 1))
                or Color3.fromHSV(hue, saturation, value)
            knobStroke.Color = fill.BackgroundColor3
            fillGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, math.max(saturation - 0.18, 0), value)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, saturation, math.min(value + 0.22, 1))),
            })
        end
        function api.SetValue(self, value, ratio, final)
            local validated = clampValue(value)
            if validated == nil then
                return false
            end
            local changed = self.Value ~= validated
            self.Value = validated
            if ratio ~= nil then
                fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
            else
                updateVisual(false)
            end
            valueButton.Text = formatValue(self.Value)
            if changed or final then
                settings.Function(self.Value, final)
            end
            return true
        end

        local dragging = false
        root.InputBegan:Connect(function(input)
            local inputType = input.UserInputType
            if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
                return
            end
            if input.Position.Y - root.AbsolutePosition.Y <= 20 * getGuiScale() then
                return
            end
            dragging = true
            local expectedMovement = inputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement
                or Enum.UserInputType.Touch
            local function update(position, final)
                local ratio = track.AbsoluteSize.X > 0
                        and math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    or 0
                local value = settings.Min + (settings.Max - settings.Min) * ratio
                api:SetValue(value, ratio, final)
            end
            update(input.Position, false)
            local moveConnection = h.InputChanged:Connect(function(changed)
                if dragging and changed.UserInputType == expectedMovement then
                    update(changed.Position, false)
                end
            end)
            local endConnection
            endConnection = input.Changed:Connect(function()
                if
                    input.UserInputState == Enum.UserInputState.End
                    or input.UserInputState == Enum.UserInputState.Cancel
                then
                    dragging = false
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    api:SetValue(api.Value, nil, true)
                end
            end)
        end)

        root.MouseEnter:Connect(function()
            n:Spring(knobScale, o.SpringInteractive, { Scale = 1.14 })
            n:Tween(track, o.TweenFast, { BackgroundColor3 = o.ElevatedHover })
            n:Tween(title, o.TweenFast, { TextColor3 = o.Text })
        end)
        root.MouseLeave:Connect(function()
            n:Spring(knobScale, o.SpringInteractive, { Scale = 1 })
            n:Tween(track, o.TweenFast, { BackgroundColor3 = o.Elevated })
            n:Tween(title, o.TweenFast, { TextColor3 = o.MutedText })
        end)
        valueButton.Activated:Connect(function()
            valueButton.Visible = false
            valueBox.Visible = true
            valueBox.Text = tostring(api.Value)
            valueBox:CaptureFocus()
        end)
        valueBox.FocusLost:Connect(function(submitted)
            valueButton.Visible = true
            valueBox.Visible = false
            if submitted and not api:SetValue(valueBox.Text, nil, true) then
                valueBox.Text = tostring(api.Value)
            end
        end)

        api.Object = root
        owner.Options[settings.Name] = api
        return api
    end,
    Targets = function(aa, ab, ac)
        local ad = {
            Type = "Targets",
            Index = getTableSize(ac.Options),
        }

        local ae = Instance.new("TextButton")
        ae.Name = "Targets"
        ae.Size = UDim2.new(1, 0, 0, 50)
        ae.BackgroundColor3 = m.Dark(ab.BackgroundColor3, aa.Darker and 0.02 or 0)
        ae.BorderSizePixel = 0
        ae.AutoButtonColor = false
        ae.Visible = aa.Visible == nil or aa.Visible
        ae.Text = ""
        ae.Parent = ab
        addTooltip(ae, aa.Tooltip)
        local af = Instance.new("Frame")
        af.Name = "BKG"
        af.Size = UDim2.new(1, -20, 1, -9)
        af.Position = UDim2.fromOffset(10, 4)
        af.BackgroundColor3 = m.Light(o.Main, 0.034)
        af.Parent = ae
        addCorner(af, UDim.new(0, 4))
        local ag = Instance.new("TextButton")
        ag.Name = "TextList"
        ag.Size = UDim2.new(1, -2, 1, -2)
        ag.Position = UDim2.fromOffset(1, 1)
        ag.BackgroundColor3 = o.Main
        ag.AutoButtonColor = false
        ag.Text = ""
        ag.Parent = af
        local ah = Instance.new("TextLabel")
        ah.Name = "Title"
        ah.Size = UDim2.new(1, -5, 0, 15)
        ah.Position = UDim2.fromOffset(5, 6)
        ah.BackgroundTransparency = 1
        ah.Text = "Target:"
        ah.TextXAlignment = Enum.TextXAlignment.Left
        ah.TextColor3 = m.Dark(o.Text, 0.16)
        ah.TextSize = 15
        ah.TextTruncate = Enum.TextTruncate.AtEnd
        ah.FontFace = o.Font
        ah.Parent = ag
        local ai = ah:Clone()
        ai.Name = "Items"
        ai.Position = UDim2.fromOffset(5, 21)
        ai.Text = "Ignore none"
        ai.TextColor3 = m.Dark(o.Text, 0.16)
        ai.TextSize = 11
        ai.Parent = ag
        addCorner(ag, UDim.new(0, 4))
        local aj = Instance.new("Frame")
        aj.Size = UDim2.fromOffset(65, 12)
        aj.Position = UDim2.fromOffset(52, 8)
        aj.BackgroundTransparency = 1
        aj.Parent = ag
        local I = Instance.new("UIListLayout")
        I.FillDirection = Enum.FillDirection.Horizontal
        I.Padding = UDim.new(0, 6)
        I.Parent = aj
        local J = Instance.new("TextButton")
        J.Name = "TargetsTextWindow"
        J.Size = UDim2.fromOffset(220, 145)
        J.BackgroundColor3 = o.Main
        J.BorderSizePixel = 0
        J.AutoButtonColor = false
        J.Visible = false
        J.Text = ""
        J.Parent = v
        ad.Window = J
        addBlur(J)
        addCorner(J)
        local K = Instance.new("ImageLabel")
        K.Name = "Icon"
        K.Size = UDim2.fromOffset(18, 12)
        K.Position = UDim2.fromOffset(10, 15)
        K.BackgroundTransparency = 1
        K.Image = u("badscript/assets/new/targetstab.png")
        K.Parent = J
        local L = Instance.new("TextLabel")
        L.Name = "Title"
        L.Size = UDim2.new(1, -36, 0, 20)
        L.Position = UDim2.fromOffset(math.abs(L.Size.X.Offset), 11)
        L.BackgroundTransparency = 1
        L.Text = "Target settings"
        L.TextXAlignment = Enum.TextXAlignment.Left
        L.TextColor3 = o.Text
        L.TextSize = 13
        L.FontFace = o.Font
        L.Parent = J
        local M = addCloseButton(J)
        aa.Function = aa.Function or function() end

        function ad.Save(N, O)
            O.Targets = {
                Players = N.Players.Enabled,
                NPCs = N.NPCs.Enabled,
                Invisible = N.Invisible.Enabled,
                Walls = N.Walls.Enabled,
            }
        end

        function ad.Load(N, O)
            if N.Players.Enabled ~= O.Players then
                N.Players:Toggle()
            end
            if N.NPCs.Enabled ~= O.NPCs then
                N.NPCs:Toggle()
            end
            if N.Invisible.Enabled ~= O.Invisible then
                N.Invisible:Toggle()
            end
            if N.Walls.Enabled ~= O.Walls then
                N.Walls:Toggle()
            end
        end

        function ad.Color(N, O, P, Q, R)
            local accent = R and Color3.fromHSV(d:Color((O - (N.Index * 0.075)) % 1)) or Color3.fromHSV(O, P, Q)
            af.BackgroundColor3 = accent

            if N.Players.Enabled and N.Players.Frame then
                n:Cancel(N.Players.Frame)
                N.Players.Frame.BackgroundColor3 = accent
            end
            if N.NPCs.Enabled and N.NPCs.Frame then
                n:Cancel(N.NPCs.Frame)
                N.NPCs.Frame.BackgroundColor3 = accent
            end

            applyToggleAccent(N.Invisible, O, P, Q, R, N.Index)
            applyToggleAccent(N.Walls, O, P, Q, R, N.Index)
        end

        ad.Players = H.TargetsButton({
            Position = UDim2.fromOffset(11, 45),
            Icon = u("badscript/assets/new/targetplayers1.png"),
            IconSize = UDim2.fromOffset(15, 16),
            IconParent = aj,
            ToolIcon = u("badscript/assets/new/targetplayers2.png"),
            ToolSize = UDim2.fromOffset(11, 12),
            Tooltip = "Players",
            Function = aa.Function,
        }, J, aj)
        ad.NPCs = H.TargetsButton({
            Position = UDim2.fromOffset(112, 45),
            Icon = u("badscript/assets/new/targetnpc1.png"),
            IconSize = UDim2.fromOffset(12, 16),
            IconParent = aj,
            ToolIcon = u("badscript/assets/new/targetnpc2.png"),
            ToolSize = UDim2.fromOffset(9, 12),
            Tooltip = "NPCs",
            Function = aa.Function,
        }, J, aj)
        ad.Invisible = H.Toggle({
            Name = "Ignore invisible",
            Function = function()
                local N = "none"
                if ad.Invisible.Enabled then
                    N = "invisible"
                end
                if ad.Walls.Enabled then
                    N = N == "none" and "behind walls" or N .. ", behind walls"
                end
                ai.Text = "Ignore " .. N
                aa.Function()
            end,
        }, J, { Options = {} })
        ad.Invisible.Object.Position = UDim2.fromOffset(0, 81)
        ad.Walls = H.Toggle({
            Name = "Ignore behind walls",
            Function = function()
                local N = "none"
                if ad.Invisible.Enabled then
                    N = "invisible"
                end
                if ad.Walls.Enabled then
                    N = N == "none" and "behind walls" or N .. ", behind walls"
                end
                ai.Text = "Ignore " .. N
                aa.Function()
            end,
        }, J, { Options = {} })
        ad.Walls.Object.Position = UDim2.fromOffset(0, 111)
        if aa.Players then
            ad.Players:Toggle()
        end
        if aa.NPCs then
            ad.NPCs:Toggle()
        end
        if aa.Invisible then
            ad.Invisible:Toggle()
        end
        if aa.Walls then
            ad.Walls:Toggle()
        end

        M.Activated:Connect(function()
            J.Visible = false
        end)
        ag.Activated:Connect(function()
            J.Visible = not J.Visible
            n:Cancel(af)
            af.BackgroundColor3 = J.Visible and Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                or m.Light(o.Main, 0.37)
        end)
        ae.MouseEnter:Connect(function()
            if not ad.Window.Visible then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = m.Light(o.Main, 0.37),
                })
            end
        end)
        ae.MouseLeave:Connect(function()
            if not ad.Window.Visible then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = m.Light(o.Main, 0.034),
                })
            end
        end)
        connectDeferredPropertyChanged(ae, "AbsolutePosition", function()
            if d.ThreadFix then
                setthreadidentity(8)
            end
            local N = (ae.AbsolutePosition + Vector2.new(0, 60)) / A.Scale
            local targetPosition = UDim2.fromOffset(N.X + 220, N.Y)
            if J.Position ~= targetPosition then
                J.Position = targetPosition
            end
        end)

        ad.Object = ae
        ac.Options.Targets = ad

        return ad
    end,
    TargetsButton = function(aa, ab, ac)
        local ad = { Enabled = false }

        local ae = Instance.new("TextButton")
        ae.Size = UDim2.fromOffset(98, 31)
        ae.Position = aa.Position
        ae.BackgroundColor3 = m.Light(o.Main, 0.05)
        ae.AutoButtonColor = false
        ae.Visible = aa.Visible == nil or aa.Visible
        ae.Text = ""
        ae.Parent = ab
        addCorner(ae)
        addTooltip(ae, aa.Tooltip)
        local af = Instance.new("Frame")
        af.Size = UDim2.new(1, -2, 1, -2)
        af.Position = UDim2.fromOffset(1, 1)
        af.BackgroundColor3 = o.Main
        af.Parent = ae
        addCorner(af)
        local ag = Instance.new("ImageLabel")
        ag.Size = aa.IconSize
        ag.Position = UDim2.fromScale(0.5, 0.5)
        ag.AnchorPoint = Vector2.new(0.5, 0.5)
        ag.BackgroundTransparency = 1
        ag.Image = aa.Icon
        ag.ImageColor3 = m.Light(o.Main, 0.37)
        ag.Parent = af
        aa.Function = aa.Function or function() end
        local ah

        function ad.Toggle(ai)
            ai.Enabled = not ai.Enabled
            n:Tween(af, o.Tween, {
                BackgroundColor3 = ai.Enabled and Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                    or o.Main,
            })
            n:Tween(ag, o.Tween, {
                ImageColor3 = ai.Enabled and Color3.new(1, 1, 1) or m.Light(o.Main, 0.37),
            })
            if ah then
                ah:Destroy()
            end
            if ai.Enabled then
                ah = Instance.new("ImageLabel")
                ah.Size = aa.ToolSize
                ah.BackgroundTransparency = 1
                ah.Image = aa.ToolIcon
                ah.ImageColor3 = o.Text
                ah.Parent = aa.IconParent
            end
            aa.Function(ai.Enabled)
        end

        ae.MouseEnter:Connect(function()
            if not ad.Enabled then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value - 0.25),
                })
                n:Tween(ag, o.Tween, {
                    ImageColor3 = Color3.new(1, 1, 1),
                })
            end
        end)
        ae.MouseLeave:Connect(function()
            if not ad.Enabled then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = o.Main,
                })
                n:Tween(ag, o.Tween, {
                    ImageColor3 = m.Light(o.Main, 0.37),
                })
            end
        end)
        ae.Activated:Connect(function()
            ad:Toggle()
        end)

        ad.Object = ae
        ad.Frame = af
        ad.Icon = ag

        return ad
    end,
    TextBox = function(aa, ab, ac)
        local ad = {
            Type = "TextBox",
            Value = aa.Default or "",
            Index = 0,
        }

        local ae = Instance.new("TextButton")
        ae.Name = aa.Name .. "TextBox"
        ae.Size = UDim2.new(1, 0, 0, d.isMobile and 68 or 62)
        ae.BackgroundTransparency = 1
        ae.BorderSizePixel = 0
        ae.AutoButtonColor = false
        ae.Visible = aa.Visible == nil or aa.Visible
        ae.Text = ""
        ae.Parent = ab
        addTooltip(ae, aa.Tooltip)

        local af = Instance.new("TextLabel")
        af.Name = "Title"
        af.Size = UDim2.new(1, -20, 0, 22)
        af.Position = UDim2.fromOffset(10, 2)
        af.BackgroundTransparency = 1
        af.Text = tostring(aa.Name)
        af.TextXAlignment = Enum.TextXAlignment.Left
        af.TextColor3 = o.FaintText
        af.TextSize = d.isMobile and 13 or 12
        af.FontFace = o.FontSemiBold
        af.Parent = ae

        local ag = Instance.new("Frame")
        ag.Name = "BKG"
        ag.Size = UDim2.new(1, -16, 0, d.isMobile and 36 or 32)
        ag.Position = UDim2.fromOffset(8, 26)
        ag.BackgroundColor3 = aa.Darker and o.MainSoft or o.Surface
        ag.BorderSizePixel = 0
        ag.Parent = ae
        addCorner(ag, o.Radius)
        local ah = addStroke(ag, o.Border, 0.82, 1, "TextBoxStroke")

        local ai = Instance.new("TextBox")
        ai.Name = "Input"
        ai.Size = UDim2.new(1, -24, 1, 0)
        ai.Position = UDim2.fromOffset(12, 0)
        ai.BackgroundTransparency = 1
        ai.Text = tostring(aa.Default or "")
        ai.PlaceholderText = tostring(aa.Placeholder or "Type a value")
        ai.TextXAlignment = Enum.TextXAlignment.Left
        ai.TextColor3 = o.Text
        ai.PlaceholderColor3 = o.FaintText
        ai.TextSize = d.isMobile and 14 or 13
        ai.FontFace = o.Font
        ai.ClearTextOnFocus = false
        ai.Parent = ag

        local aj = Instance.new("Frame")
        aj.Name = "FocusLine"
        aj.Size = UDim2.new(0, 0, 0, 2)
        aj.Position = UDim2.new(0, 0, 1, -2)
        aj.BorderSizePixel = 0
        aj.Parent = ag
        addCorner(aj, UDim.new(1, 0))
        connectguicolorchange(function(ak, al, am)
            aj.BackgroundColor3 = Color3.fromHSV(ak, al, am)
        end)

        aa.Function = aa.Function or function() end
        local updatingText = false

        function ad.Save(ak, al)
            al[aa.Name] = { Value = ak.Value }
        end

        function ad.Load(ak, al)
            if type(al) == "table" and ak.Value ~= al.Value then
                ak:SetValue(al.Value)
            end
        end

        function ad.SetValue(ak, al, am)
            local value = tostring(al or "")
            local changed = ak.Value ~= value
            ak.Value = value
            if ai.Text ~= value then
                updatingText = true
                ai.Text = value
                updatingText = false
            end
            if changed or am ~= nil then
                aa.Function(ak.Value, am)
            end
        end

        ae.Activated:Connect(function()
            ai:CaptureFocus()
        end)

        ae.MouseEnter:Connect(function()
            if ai:IsFocused() then
                return
            end
            n:Tween(ag, o.TweenFast, {
                BackgroundColor3 = aa.Darker and m.Light(o.MainSoft, 0.04) or o.SurfaceHover,
            })
            n:Tween(ah, o.TweenFast, {
                Color = o.BorderStrong,
                Transparency = 0.66,
            })
            n:Tween(af, o.TweenFast, {
                TextColor3 = o.FaintText,
            })
        end)

        ae.MouseLeave:Connect(function()
            if ai:IsFocused() then
                return
            end
            n:Tween(ag, o.TweenFast, {
                BackgroundColor3 = aa.Darker and o.MainSoft or o.Surface,
            })
            n:Tween(ah, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.76,
            })
            n:Tween(af, o.TweenFast, {
                TextColor3 = o.FaintText,
            })
        end)

        ai.Focused:Connect(function()
            n:Tween(ag, o.TweenFast, {
                BackgroundColor3 = aa.Darker and m.Light(o.MainSoft, 0.05) or o.SurfaceHover,
            })
            n:Tween(ah, o.TweenFast, {
                Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
                Transparency = 0.52,
            })
            n:Tween(aj, o.Tween, {
                Size = UDim2.new(1, 0, 0, 2),
            })
            n:Tween(af, o.TweenFast, {
                TextColor3 = o.TextStrong,
            })
        end)

        ai.FocusLost:Connect(function(submitted)
            ad:SetValue(ai.Text, submitted)
            n:Tween(ag, o.TweenFast, {
                BackgroundColor3 = aa.Darker and o.MainSoft or o.Surface,
            })
            n:Tween(ah, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.76,
            })
            n:Tween(aj, o.TweenFast, {
                Size = UDim2.new(0, 0, 0, 2),
            })
            n:Tween(af, o.TweenFast, {
                TextColor3 = o.MutedText,
            })
        end)

        ai:GetPropertyChangedSignal("Text"):Connect(function()
            if not updatingText then
                ad:SetValue(ai.Text, false)
            end
        end)

        ad.Object = ae
        ac.Options[aa.Name] = ad
        return ad
    end,
    TextList = function(aa, ab, ac)
        local ad = {
            Type = "TextList",
            List = aa.Default or {},
            ListEnabled = aa.Default or {},
            Objects = {},
            Window = { Visible = false },
            Index = getTableSize(ac.Options),
        }
        aa.Color = aa.Color or Color3.fromRGB(5, 134, 105)

        local ae = Instance.new("TextButton")
        ae.Name = aa.Name .. "TextList"
        ae.Size = UDim2.new(1, 0, 0, 50)
        ae.BackgroundColor3 = m.Dark(ab.BackgroundColor3, aa.Darker and 0.02 or 0)
        ae.BorderSizePixel = 0
        ae.AutoButtonColor = false
        ae.Visible = aa.Visible == nil or aa.Visible
        ae.Text = ""
        ae.Parent = ab
        addTooltip(ae, aa.Tooltip)
        local af = Instance.new("Frame")
        af.Name = "BKG"
        af.Size = UDim2.new(1, -20, 1, -9)
        af.Position = UDim2.fromOffset(10, 4)
        af.BackgroundColor3 = m.Light(o.Main, 0.034)
        af.Parent = ae
        addCorner(af, UDim.new(0, 4))
        local ag = Instance.new("TextButton")
        ag.Name = "TextList"
        ag.Size = UDim2.new(1, -2, 1, -2)
        ag.Position = UDim2.fromOffset(1, 1)
        ag.BackgroundColor3 = o.Main
        ag.AutoButtonColor = false
        ag.Text = ""
        ag.Parent = af
        local ah = Instance.new("ImageLabel")
        ah.Name = "Icon"
        ah.Size = UDim2.fromOffset(14, 12)
        ah.Position = UDim2.fromOffset(10, 14)
        ah.BackgroundTransparency = 1
        ah.Image = aa.Icon or u("badscript/assets/new/allowedicon.png")
        ah.Parent = ag
        local ai = Instance.new("TextLabel")
        ai.Name = "Title"
        ai.Size = UDim2.new(1, -35, 0, 15)
        ai.Position = UDim2.fromOffset(35, 6)
        ai.BackgroundTransparency = 1
        ai.Text = aa.Name
        ai.TextXAlignment = Enum.TextXAlignment.Left
        ai.TextColor3 = m.Dark(o.Text, 0.16)
        ai.TextSize = 15
        ai.TextTruncate = Enum.TextTruncate.AtEnd
        ai.FontFace = o.Font
        ai.Parent = ag
        local aj = ai:Clone()
        aj.Name = "Amount"
        aj.Size = UDim2.new(1, -13, 0, 15)
        aj.Position = UDim2.fromOffset(0, 6)
        aj.Text = "0"
        aj.TextXAlignment = Enum.TextXAlignment.Right
        aj.Parent = ag
        local I = ai:Clone()
        I.Name = "Items"
        I.Position = UDim2.fromOffset(35, 21)
        I.Text = "None"
        I.TextColor3 = m.Dark(o.Text, 0.43)
        I.TextSize = 11
        I.Parent = ag
        addCorner(ag, UDim.new(0, 4))

        local J = 400
        local K = 85
        local L = 35
        local M = math.floor((J - K) / L)

        local N = Instance.new("TextButton")
        N.Name = aa.Name .. "TextWindow"
        N.Size = UDim2.fromOffset(220, K)
        N.BackgroundColor3 = o.Main
        N.BorderSizePixel = 0
        N.AutoButtonColor = false
        N.Visible = false
        N.Text = ""
        N.ClipsDescendants = true
        N.Parent = ac.Legit and d.Legit.Window or v
        ad.Window = N
        addBlur(N)
        addCorner(N)

        local O = Instance.new("ImageLabel")
        O.Name = "Icon"
        O.Size = aa.TabSize or UDim2.fromOffset(19, 16)
        O.Position = UDim2.fromOffset(10, 13)
        O.BackgroundTransparency = 1
        O.Image = aa.Tab or u("badscript/assets/new/allowedtab.png")
        O.Parent = N
        local P = Instance.new("TextLabel")
        P.Name = "Title"
        P.Size = UDim2.new(1, -36, 0, 20)
        P.Position = UDim2.fromOffset(math.abs(P.Size.X.Offset), 11)
        P.BackgroundTransparency = 1
        P.Text = aa.Name
        P.TextXAlignment = Enum.TextXAlignment.Left
        P.TextColor3 = o.Text
        P.TextSize = 13
        P.FontFace = o.Font
        P.Parent = N
        local Q = addCloseButton(N)

        local R = Instance.new("Frame")
        R.Name = "Add"
        R.Size = UDim2.fromOffset(200, 31)
        R.Position = UDim2.fromOffset(10, 45)
        R.BackgroundColor3 = m.Light(o.Main, 0.02)
        R.Parent = N
        addCorner(R)
        local S = R:Clone()
        S.Size = UDim2.new(1, -2, 1, -2)
        S.Position = UDim2.fromOffset(1, 1)
        S.BackgroundColor3 = m.Dark(o.Main, 0.02)
        S.Parent = R
        local T = Instance.new("TextBox")
        T.Size = UDim2.new(1, -35, 1, 0)
        T.Position = UDim2.fromOffset(10, 0)
        T.BackgroundTransparency = 1
        T.Text = ""
        T.PlaceholderText = aa.Placeholder or "Add entry..."
        T.TextXAlignment = Enum.TextXAlignment.Left
        T.TextColor3 = Color3.new(1, 1, 1)
        T.TextSize = 15
        T.FontFace = o.Font
        T.ClearTextOnFocus = false
        T.Parent = R
        local U = Instance.new("ImageButton")
        U.Name = "AddButton"
        U.Size = UDim2.fromOffset(16, 16)
        U.Position = UDim2.new(1, -26, 0, 8)
        U.BackgroundTransparency = 1
        U.Image = u("badscript/assets/new/add.png")
        U.ImageColor3 = aa.Color
        U.ImageTransparency = 0.3
        U.Parent = R

        local V = Instance.new("Frame")
        V.Name = "SearchBKG"
        V.Size = UDim2.fromOffset(200, 31)
        V.Position = UDim2.fromOffset(10, 82)
        V.BackgroundColor3 = m.Light(o.Main, 0.02)
        V.Parent = N
        addCorner(V)
        local W = V:Clone()
        W.Size = UDim2.new(1, -2, 1, -2)
        W.Position = UDim2.fromOffset(1, 1)
        W.BackgroundColor3 = m.Dark(o.Main, 0.02)
        W.Parent = V
        local X = Instance.new("TextBox")
        X.Name = "SearchBox"
        X.Size = UDim2.new(1, -20, 1, 0)
        X.Position = UDim2.fromOffset(10, 0)
        X.BackgroundTransparency = 1
        X.Text = ""
        X.PlaceholderText = "Search..."
        X.TextXAlignment = Enum.TextXAlignment.Left
        X.TextColor3 = Color3.new(1, 1, 1)
        X.TextSize = 13
        X.FontFace = o.Font
        X.ClearTextOnFocus = false
        X.Parent = V
        addTooltip(V, "Type to search entries")

        local Y = Instance.new("ScrollingFrame")
        Y.Name = "ItemScroll"
        Y.Size = UDim2.fromOffset(200, 0)
        Y.Position = UDim2.fromOffset(10, 119)
        Y.BackgroundTransparency = 1
        Y.BorderSizePixel = 0
        Y.ScrollBarThickness = 4
        Y.ScrollBarImageTransparency = 0.5
        Y.CanvasSize = UDim2.new(0, 0, 0, 0)
        Y.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Y.ScrollingDirection = Enum.ScrollingDirection.Y
        Y.Parent = N

        local Z = Instance.new("TextLabel")
        Z.Name = "NoResults"
        Z.Size = UDim2.new(1, 0, 0, 40)
        Z.Position = UDim2.fromOffset(0, 0)
        Z.BackgroundTransparency = 1
        Z.Text = "No Results Found"
        Z.TextColor3 = Color3.fromRGB(150, 150, 150)
        Z.TextSize = 13
        Z.FontFace = o.Font
        Z.Visible = false
        Z.Parent = Y

        aa.Function = aa.Function or function() end

        function ad.Save(_, ak)
            ak[aa.Name] = {
                List = _.List,
                ListEnabled = _.ListEnabled,
            }
        end

        function ad.Load(ak, _)
            ak.List = _.List or {}
            ak.ListEnabled = _.ListEnabled or {}
            ak:ChangeValue()
        end

        function ad.Color(ak, _, al, am, an)
            if N.Visible then
                af.BackgroundColor3 = an and Color3.fromHSV(d:Color((_ - (ak.Index * 0.075)) % 1))
                    or Color3.fromHSV(_, al, am)
            end
        end

        local ak = ""

        function ad.UpdateWindowSize(al, am)
            local an = math.min(am, M) * L
            local _ = 119 + an

            Y.Size = UDim2.fromOffset(200, an)

            n:Tween(N, o.Tween, {
                Size = UDim2.fromOffset(220, _),
            })
        end

        function ad.FilterItems(al, am)
            ak = am:lower()
            local an = 0

            for _, ao in al.Objects do
                local ap = ao.Name:lower()
                local aq = ak == "" or ap:find(ak, 1, true)

                if aq then
                    an = an + 1
                    ao.Position = UDim2.fromOffset(0, (an - 1) * L)

                    ao.Visible = true
                    n:Tween(ao, TweenInfo.new(0.15), {
                        BackgroundTransparency = 0,
                    })
                    for ar, as in ao:GetDescendants() do
                        if as:IsA("TextLabel") then
                            n:Tween(as, TweenInfo.new(0.15), {
                                TextTransparency = 0,
                            })
                        elseif as:IsA("ImageButton") or as:IsA("ImageLabel") then
                            n:Tween(as, TweenInfo.new(0.15), {
                                ImageTransparency = as.Name == "AddButton" and 0.3 or 0.5,
                            })
                        elseif as:IsA("Frame") and as.Name ~= "BKG" then
                            n:Tween(as, TweenInfo.new(0.15), {
                                BackgroundTransparency = 0,
                            })
                        end
                    end
                else
                    n:Tween(ao, TweenInfo.new(0.15), {
                        BackgroundTransparency = 1,
                    })
                    for ar, as in ao:GetDescendants() do
                        if as:IsA("TextLabel") then
                            n:Tween(as, TweenInfo.new(0.15), {
                                TextTransparency = 1,
                            })
                        elseif as:IsA("ImageButton") or as:IsA("ImageLabel") then
                            n:Tween(as, TweenInfo.new(0.15), {
                                ImageTransparency = 1,
                            })
                        elseif as:IsA("Frame") then
                            n:Tween(as, TweenInfo.new(0.15), {
                                BackgroundTransparency = 1,
                            })
                        end
                    end
                    task.delay(0.15, function()
                        ao.Visible = false
                    end)
                end
            end

            Z.Visible = an == 0 and #al.List > 0
            al:UpdateWindowSize(an == 0 and 1 or an)
        end

        function ad.ChangeValue(al, am)
            if am then
                local an = table.find(al.List, am)
                if an then
                    table.remove(al.List, an)
                    an = table.find(al.ListEnabled, am)
                    if an then
                        table.remove(al.ListEnabled, an)
                    end
                else
                    table.insert(al.List, am)
                    table.insert(al.ListEnabled, am)
                end
            end

            aa.Function(al.List)
            for an, ao in al.Objects do
                ao:Destroy()
            end
            table.clear(al.Objects)
            aj.Text = #al.List

            local an = "None"
            for ao, ap in al.ListEnabled do
                if ao == 1 then
                    an = ""
                end
                an = an .. (ao == 1 and ap or ", " .. ap)
            end
            I.Text = an

            for ao, ap in al.List do
                local aq = table.find(al.ListEnabled, ap)
                local ar = Instance.new("TextButton")
                ar.Name = ap
                ar.Size = UDim2.fromOffset(200, 32)
                ar.Position = UDim2.fromOffset(0, (ao - 1) * L)
                ar.BackgroundColor3 = m.Light(o.Main, 0.02)
                ar.AutoButtonColor = false
                ar.Text = ""
                ar.Parent = Y
                addCorner(ar)
                local as = Instance.new("Frame")
                as.Name = "BKG"
                as.Size = UDim2.new(1, -2, 1, -2)
                as.Position = UDim2.fromOffset(1, 1)
                as.BackgroundColor3 = o.Main
                as.Visible = false
                as.Parent = ar
                addCorner(as)
                local _ = Instance.new("Frame")
                _.Name = "Dot"
                _.Size = UDim2.fromOffset(10, 11)
                _.Position = UDim2.fromOffset(10, 12)
                _.BackgroundColor3 = aq and aa.Color or m.Light(o.Main, 0.37)
                _.Parent = ar
                addCorner(_, UDim.new(1, 0))
                local at = _:Clone()
                at.Size = UDim2.fromOffset(8, 9)
                at.Position = UDim2.fromOffset(1, 1)
                at.BackgroundColor3 = aq and aa.Color or m.Light(o.Main, 0.02)
                at.Parent = _
                local au = Instance.new("TextLabel")
                au.Name = "Title"
                au.Size = UDim2.new(1, -30, 1, 0)
                au.Position = UDim2.fromOffset(30, 0)
                au.BackgroundTransparency = 1
                au.Text = ap
                au.TextXAlignment = Enum.TextXAlignment.Left
                au.TextColor3 = m.Dark(o.Text, 0.16)
                au.TextSize = 15
                au.FontFace = o.Font
                au.Parent = ar
                local av = Instance.new("ImageButton")
                av.Name = "Close"
                av.Size = UDim2.fromOffset(16, 16)
                av.Position = UDim2.new(1, -26, 0, 8)
                av.BackgroundColor3 = Color3.new(1, 1, 1)
                av.BackgroundTransparency = 1
                av.AutoButtonColor = false
                av.Image = u("badscript/assets/new/closemini.png")
                av.ImageColor3 = m.Light(o.Text, 0.2)
                av.ImageTransparency = 0.5
                av.Parent = ar
                addCorner(av, UDim.new(1, 0))

                av.MouseEnter:Connect(function()
                    av.ImageTransparency = 0.3
                    n:Tween(av, o.Tween, {
                        BackgroundTransparency = 0.6,
                    })
                end)
                av.MouseLeave:Connect(function()
                    av.ImageTransparency = 0.5
                    n:Tween(av, o.Tween, {
                        BackgroundTransparency = 1,
                    })
                end)
                av.Activated:Connect(function()
                    al:ChangeValue(ap)
                    al:FilterItems(ak)
                end)
                ar.MouseEnter:Connect(function()
                    as.Visible = true
                end)
                ar.MouseLeave:Connect(function()
                    as.Visible = false
                end)
                ar.Activated:Connect(function()
                    local aw = table.find(al.ListEnabled, ap)
                    if aw then
                        table.remove(al.ListEnabled, aw)
                        _.BackgroundColor3 = m.Light(o.Main, 0.37)
                        at.BackgroundColor3 = m.Light(o.Main, 0.02)
                    else
                        table.insert(al.ListEnabled, ap)
                        _.BackgroundColor3 = aa.Color
                        at.BackgroundColor3 = aa.Color
                    end

                    local ax = "None"
                    for ay, az in al.ListEnabled do
                        if ay == 1 then
                            ax = ""
                        end
                        ax = ax .. (ay == 1 and az or ", " .. az)
                    end

                    I.Text = ax
                    aa.Function()
                end)

                table.insert(al.Objects, ar)
            end

            al:FilterItems(ak)
        end

        X:GetPropertyChangedSignal("Text"):Connect(function()
            ad:FilterItems(X.Text)
        end)

        X.MouseEnter:Connect(function()
            n:Tween(V, o.Tween, {
                BackgroundColor3 = m.Light(o.Main, 0.14),
            })
        end)
        X.MouseLeave:Connect(function()
            n:Tween(V, o.Tween, {
                BackgroundColor3 = m.Light(o.Main, 0.02),
            })
        end)

        U.MouseEnter:Connect(function()
            U.ImageTransparency = 0
        end)
        U.MouseLeave:Connect(function()
            U.ImageTransparency = 0.3
        end)
        U.Activated:Connect(function()
            if not table.find(ad.List, T.Text) then
                if T.Text == "" or T.Text == "Invalid Entry!" then
                    d:CreateNotification("BadWars", "You need to specify a value!", 3)
                    flickerTextEffect(T, true, "Invalid Entry!")
                    task.delay(0.5, function()
                        flickerTextEffect(T, true, "")
                    end)
                    return
                end
                ad:ChangeValue(T.Text)
                T.Text = ""
                X.Text = ""
            end
        end)
        T.FocusLost:Connect(function(al)
            if al and not table.find(ad.List, T.Text) and T.Text ~= "" then
                ad:ChangeValue(T.Text)
                T.Text = ""
                X.Text = ""
            end
        end)
        T.MouseEnter:Connect(function()
            n:Tween(R, o.Tween, {
                BackgroundColor3 = m.Light(o.Main, 0.14),
            })
        end)
        T.MouseLeave:Connect(function()
            n:Tween(R, o.Tween, {
                BackgroundColor3 = m.Light(o.Main, 0.02),
            })
        end)
        Q.Activated:Connect(function()
            N.Visible = false
            X.Text = ""
        end)
        ag.Activated:Connect(function()
            N.Visible = not N.Visible
            if not N.Visible then
                X.Text = ""
            end
            n:Cancel(af)
            af.BackgroundColor3 = N.Visible and Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                or m.Light(o.Main, 0.37)
        end)
        ae.MouseEnter:Connect(function()
            if not ad.Window.Visible then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = m.Light(o.Main, 0.37),
                })
            end
        end)
        ae.MouseLeave:Connect(function()
            if not ad.Window.Visible then
                n:Tween(af, o.Tween, {
                    BackgroundColor3 = m.Light(o.Main, 0.034),
                })
            end
        end)
        local function refreshDropdownPosition()
            if d.ThreadFix then
                setthreadidentity(8)
            end
            local al = (ae.AbsolutePosition - (ac.Legit and d.Legit.Window.AbsolutePosition or -j:GetGuiInset()))
                / A.Scale
            local targetPosition = UDim2.fromOffset(al.X + 220, al.Y)
            if N.Position ~= targetPosition then
                N.Position = targetPosition
            end
        end
        connectDeferredPropertyChanged(ae, "AbsolutePosition", refreshDropdownPosition)

        if aa.Default then
            ad:ChangeValue()
        end
        ad.Object = ae
        ac.Options[aa.Name] = ad

        return ad
    end,
    Toggle = function(aa, ab, ac)
        local ad = {
            Type = "Toggle",
            Enabled = false,
            Index = getTableSize(ac.Options),
            Name = aa.Name,
            Toggled = c(`{tostring(aa.Name)}_{tostring(ac.Name)}`),
        }

        local ae = false
        local af = Instance.new("TextButton")
        af.Name = aa.Name .. "Toggle"
        af.Size = UDim2.new(1, 0, 0, d.isMobile and 46 or 40)
        af.BackgroundTransparency = 1
        af.BorderSizePixel = 0
        af.AutoButtonColor = false
        af.Visible = aa.Visible == nil or aa.Visible
        af.Text = ""
        af.Parent = ab
        addTooltip(af, aa.Tooltip)

        local ag = Instance.new("Frame")
        ag.Name = "Card"
        ag.Size = UDim2.new(1, -16, 1, -6)
        ag.Position = UDim2.fromOffset(8, 3)
        ag.BackgroundColor3 = aa.Darker and o.MainSoft or o.Surface
        ag.BorderSizePixel = 0
        ag.ClipsDescendants = true
        ag.Parent = af
        addCorner(ag, o.Radius)
        local ah = addStroke(ag, o.Border, 0.72, 1, "ToggleStroke")

        local ai = Instance.new("TextLabel")
        ai.Name = "Title"
        ai.Size = UDim2.new(1, -72, 1, 0)
        ai.Position = UDim2.fromOffset(14, 0)
        ai.BackgroundTransparency = 1
        ai.Text = tostring(aa.Name)
        ai.TextXAlignment = Enum.TextXAlignment.Left
        ai.TextColor3 = o.MutedText
        ai.TextSize = d.isMobile and 15 or 14
        ai.FontFace = o.Font
        ai.Parent = ag

        local aj = Instance.new("Frame")
        aj.Name = "Track"
        aj.Size = UDim2.fromOffset(d.isMobile and 42 or 38, d.isMobile and 24 or 22)
        aj.Position = UDim2.new(1, -(d.isMobile and 54 or 50), 0.5, -(d.isMobile and 12 or 11))
        aj.BackgroundColor3 = o.Elevated
        aj.BorderSizePixel = 0
        aj.Parent = ag
        addCorner(aj, UDim.new(1, 0))
        local ak = addStroke(aj, o.Border, 0.58, 1, "TrackStroke")

        local al = Instance.new("Frame")
        al.Name = "Knob"
        al.Size = UDim2.fromOffset(d.isMobile and 18 or 16, d.isMobile and 18 or 16)
        al.Position = UDim2.fromOffset(3, 3)
        al.BackgroundColor3 = o.MutedText
        al.BorderSizePixel = 0
        al.Parent = aj
        addCorner(al, UDim.new(1, 0))
        local am = addStroke(al, o.Main, 0.5, 1, "KnobStroke")
        local an = addScale(ag)

        aa.Function = aa.Function or function() end

        local function accentColor()
            local rainbow = d.GUIColor.Rainbow and d.RainbowMode and d.RainbowMode.Value ~= "Retro"
            if rainbow then
                return Color3.fromHSV(d:Color((d.GUIColor.Hue - (ad.Index * 0.075)) % 1))
            end
            return Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        end

        local function applyVisual(instant)
            local accent = accentColor()
            local knobX = ad.Enabled and (aj.Size.X.Offset - al.Size.X.Offset - 3) or 3
            local trackColor = ad.Enabled and accent or (ae and o.ElevatedHover or o.Elevated)
            local cardColor = ad.Enabled and o.SurfaceSoft
                or (ae and o.SurfaceHover or (aa.Darker and o.MainSoft or o.Surface))
            local titleColor = ad.Enabled and o.TextStrong or (ae and o.Text or o.MutedText)
            local strokeColor = ad.Enabled and accent or (ae and o.BorderStrong or o.Border)
            local strokeTransparency = ad.Enabled and 0.2 or (ae and 0.45 or 0.72)

            if instant then
                aj.BackgroundColor3 = trackColor
                al.Position = UDim2.fromOffset(knobX, 3)
                al.BackgroundColor3 = ad.Enabled and o.TextStrong or o.MutedText
                ag.BackgroundColor3 = cardColor
                ai.TextColor3 = titleColor
                ah.Color = strokeColor
                ah.Transparency = strokeTransparency
                ak.Color = ad.Enabled and accent or o.Border
                ak.Transparency = ad.Enabled and 0.28 or 0.58
                return
            end

            n:Tween(aj, o.Tween, {
                BackgroundColor3 = trackColor,
            })
            n:Tween(al, o.Tween, {
                Position = UDim2.fromOffset(knobX, 3),
                BackgroundColor3 = ad.Enabled and o.TextStrong or o.MutedText,
            })
            n:Tween(ag, o.TweenFast, {
                BackgroundColor3 = cardColor,
            })
            n:Tween(ai, o.TweenFast, {
                TextColor3 = titleColor,
            })
            n:Tween(ah, o.TweenFast, {
                Color = strokeColor,
                Transparency = strokeTransparency,
            })
            n:Tween(ak, o.TweenFast, {
                Color = ad.Enabled and accent or o.Border,
                Transparency = ad.Enabled and 0.28 or 0.58,
            })
        end

        function ad.Save(ao, ap)
            ap[aa.Name] = { Enabled = ao.Enabled }
        end

        function ad.Load(ao, ap)
            if type(ap) == "table" and ao.Enabled ~= ap.Enabled then
                ao:Toggle()
            end
        end

        function ad.Color(ao, ap, aq, ar, as)
            if ao.Enabled then
                local accent = as and Color3.fromHSV(d:Color((ap - (ao.Index * 0.075)) % 1))
                    or Color3.fromHSV(ap, aq, ar)
                aj.BackgroundColor3 = accent
                ah.Color = accent
                ak.Color = accent
            end
        end

        function ad.Toggle(ao)
            ao.Enabled = not ao.Enabled
            ao.Toggled:Fire()
            applyVisual(false)
            aa.Function(ao.Enabled)
        end

        function ad.SetValue(ao, ap)
            if ap == nil then
                ap = not ao.Enabled
            end
            if ao.Enabled == ap then
                return
            end
            ao:Toggle()
        end

        af.MouseEnter:Connect(function()
            ae = true
            applyVisual(false)
            n:Spring(an, o.SpringInteractive, { Scale = 1.008 })
        end)
        af.MouseLeave:Connect(function()
            ae = false
            applyVisual(false)
            n:Spring(an, o.SpringInteractive, { Scale = 1 })
        end)
        af.MouseButton1Down:Connect(function()
            n:Spring(an, o.SpringInteractive, { Scale = 0.988 })
        end)
        af.MouseButton1Up:Connect(function()
            n:Spring(an, o.SpringInteractive, { Scale = ae and 1.008 or 1 })
        end)
        af.Activated:Connect(function()
            ad:Toggle()
        end)

        if aa.Default then
            if aa.NoDefaultCallback then
                ad.Enabled = true
                applyVisual(true)
            else
                ad:Toggle()
            end
        else
            applyVisual(true)
        end

        ad.Object = af
        ac.Options[aa.Name] = ad
        return ad
    end,
    TwoSlider = function(settings, parent, owner)
        settings.Min = tonumber(settings.Min) or 0
        settings.Max = tonumber(settings.Max) or settings.Min
        if settings.Max < settings.Min then
            settings.Min, settings.Max = settings.Max, settings.Min
        end
        settings.Decimal = math.max(tonumber(settings.Decimal) or 1, 0.000001)
        settings.Function = settings.Function or function() end

        local function normalize(value)
            local range = settings.Max - settings.Min
            return range > 0 and math.clamp((value - settings.Min) / range, 0, 1) or 0
        end
        local function validate(value)
            value = tonumber(value)
            if not value or value ~= value or value == math.huge or value == -math.huge then
                return nil
            end
            return math.clamp(math.floor(value * settings.Decimal + 0.5) / settings.Decimal, settings.Min, settings.Max)
        end

        local defaultMin = validate(settings.DefaultMin) or settings.Min
        local defaultMax = validate(settings.DefaultMax) or settings.Max
        if defaultMin > defaultMax then
            defaultMin, defaultMax = defaultMax, defaultMin
        end
        local api = {
            Type = "TwoSlider",
            ValueMin = defaultMin,
            ValueMax = defaultMax,
            Max = settings.Max,
            Index = getTableSize(owner.Options),
        }

        local root = Instance.new("TextButton")
        root.Name = tostring(settings.Name) .. "Slider"
        root.Size = UDim2.new(1, 0, 0, d.isMobile and 58 or 50)
        root.BackgroundColor3 = m.Dark(parent.BackgroundColor3, settings.Darker and 0.02 or 0)
        root.BorderSizePixel = 0
        root.AutoButtonColor = false
        root.Visible = settings.Visible == nil or settings.Visible
        root.Text = ""
        root.Parent = parent
        addTooltip(root, settings.Tooltip)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -150, 0, 26)
        title.Position = UDim2.fromOffset(10, 2)
        title.BackgroundTransparency = 1
        title.Text = tostring(settings.Name)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = m.Dark(o.Text, 0.12)
        title.TextSize = d.isMobile and 13 or 11
        title.FontFace = o.Font
        title.Parent = root

        local minButton = Instance.new("TextButton")
        minButton.Size = UDim2.fromOffset(62, 22)
        minButton.Position = UDim2.new(1, -139, 0, 4)
        minButton.BackgroundTransparency = 1
        minButton.TextXAlignment = Enum.TextXAlignment.Right
        minButton.TextColor3 = m.Dark(o.Text, 0.12)
        minButton.TextSize = d.isMobile and 13 or 11
        minButton.FontFace = o.Font
        minButton.Parent = root
        local maxButton = minButton:Clone()
        maxButton.Position = UDim2.new(1, -72, 0, 4)
        maxButton.Parent = root

        local minBox = Instance.new("TextBox")
        minBox.Size = minButton.Size
        minBox.Position = minButton.Position
        minBox.BackgroundColor3 = o.Surface
        minBox.Visible = false
        minBox.TextColor3 = o.Text
        minBox.TextXAlignment = Enum.TextXAlignment.Right
        minBox.TextSize = minButton.TextSize
        minBox.FontFace = o.Font
        minBox.ClearTextOnFocus = false
        minBox.Parent = root
        addCorner(minBox, UDim.new(0, 5))
        local maxBox = minBox:Clone()
        maxBox.Position = maxButton.Position
        maxBox.Parent = root

        local track = Instance.new("Frame")
        track.Name = "Slider"
        track.Size = UDim2.new(1, -20, 0, 4)
        track.Position = UDim2.new(0, 10, 1, -13)
        track.BackgroundColor3 = m.Light(o.Main, 0.06)
        track.BorderSizePixel = 0
        track.Parent = root
        addCorner(track, UDim.new(1, 0))
        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        fill.BorderSizePixel = 0
        fill.Parent = track
        addCorner(fill, UDim.new(1, 0))

        local function createKnob(name)
            local knob = Instance.new("Frame")
            knob.Name = name
            knob.Size = UDim2.fromOffset(d.isMobile and 18 or 14, d.isMobile and 18 or 14)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.BackgroundColor3 = fill.BackgroundColor3
            knob.Parent = track
            addCorner(knob, UDim.new(1, 0))
            local stroke = Instance.new("UIStroke")
            stroke.Color = o.Main
            stroke.Thickness = 2
            stroke.Parent = knob
            return knob
        end
        local minKnob = createKnob("KnobMin")
        local maxKnob = createKnob("KnobMax")

        local function updateVisual(instant)
            local minRatio = normalize(api.ValueMin)
            local maxRatio = normalize(api.ValueMax)
            local position = UDim2.fromScale(minRatio, 0)
            local size = UDim2.fromScale(math.max(0, maxRatio - minRatio), 1)
            if instant then
                fill.Position = position
                fill.Size = size
            else
                n:Tween(fill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { Position = position, Size = size })
            end
            minKnob.Position = UDim2.fromScale(minRatio, 0.5)
            maxKnob.Position = UDim2.fromScale(maxRatio, 0.5)
            minButton.Text = tostring(api.ValueMin)
            maxButton.Text = tostring(api.ValueMax)
        end
        updateVisual(true)

        function api.Save(self, target)
            target[settings.Name] = { ValueMin = self.ValueMin, ValueMax = self.ValueMax }
        end
        function api.Load(self, saved)
            if type(saved) ~= "table" then
                return
            end
            self:SetValue(false, saved.ValueMin, false)
            self:SetValue(true, saved.ValueMax, true)
        end
        function api.Color(self, hue, saturation, value, rainbow)
            fill.BackgroundColor3 = rainbow and Color3.fromHSV(d:Color((hue - (self.Index * 0.075)) % 1))
                or Color3.fromHSV(hue, saturation, value)
            minKnob.BackgroundColor3 = fill.BackgroundColor3
            maxKnob.BackgroundColor3 = fill.BackgroundColor3
        end
        function api.GetRandomValue(self)
            return Random.new():NextNumber(self.ValueMin, self.ValueMax)
        end
        function api.SetValue(self, setMax, value, final)
            local validated = validate(value)
            if validated == nil then
                return false
            end
            local changed = false
            if setMax then
                validated = math.max(validated, self.ValueMin)
                changed = self.ValueMax ~= validated
                self.ValueMax = validated
            else
                validated = math.min(validated, self.ValueMax)
                changed = self.ValueMin ~= validated
                self.ValueMin = validated
            end
            updateVisual(false)
            if changed or final then
                settings.Function(self.ValueMin, self.ValueMax, final)
            end
            return true
        end

        root.InputBegan:Connect(function(input)
            local inputType = input.UserInputType
            if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
                return
            end
            if input.Position.Y - root.AbsolutePosition.Y <= 20 * getGuiScale() then
                return
            end
            local clickedRatio = track.AbsoluteSize.X > 0
                    and math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                or 0
            local setMax = math.abs(clickedRatio - normalize(api.ValueMax))
                <= math.abs(clickedRatio - normalize(api.ValueMin))
            local expectedMovement = inputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement
                or Enum.UserInputType.Touch
            local function update(position, final)
                local ratio = track.AbsoluteSize.X > 0
                        and math.clamp((position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    or 0
                api:SetValue(setMax, settings.Min + (settings.Max - settings.Min) * ratio, final)
            end
            update(input.Position, false)
            local moveConnection = h.InputChanged:Connect(function(changed)
                if changed.UserInputType == expectedMovement then
                    update(changed.Position, false)
                end
            end)
            local endConnection
            endConnection = input.Changed:Connect(function()
                if
                    input.UserInputState == Enum.UserInputState.End
                    or input.UserInputState == Enum.UserInputState.Cancel
                then
                    moveConnection:Disconnect()
                    endConnection:Disconnect()
                    update(input.Position, true)
                end
            end)
        end)

        minButton.Activated:Connect(function()
            minButton.Visible = false
            minBox.Visible = true
            minBox.Text = tostring(api.ValueMin)
            minBox:CaptureFocus()
        end)
        maxButton.Activated:Connect(function()
            maxButton.Visible = false
            maxBox.Visible = true
            maxBox.Text = tostring(api.ValueMax)
            maxBox:CaptureFocus()
        end)
        minBox.FocusLost:Connect(function(submitted)
            minButton.Visible = true
            minBox.Visible = false
            if submitted and not api:SetValue(false, minBox.Text, true) then
                minBox.Text = tostring(api.ValueMin)
            end
        end)
        maxBox.FocusLost:Connect(function(submitted)
            maxButton.Visible = true
            maxBox.Visible = false
            if submitted and not api:SetValue(true, maxBox.Text, true) then
                maxBox.Text = tostring(api.ValueMax)
            end
        end)

        api.Object = root
        owner.Options[settings.Name] = api
        return api
    end,
    Divider = function(aa, ab)
        if ab then
            local ad = Instance.new("Frame")
            ad.Name = "DividerLabel"
            ad.Size = UDim2.new(1, -16, 0, 30)
            ad.BackgroundTransparency = 1
            ad.Parent = aa

            local ae = Instance.new("TextLabel")
            ae.Name = "Title"
            ae.Size = UDim2.new(1, -28, 1, 0)
            ae.Position = UDim2.fromOffset(14, 0)
            ae.BackgroundTransparency = 1
            ae.Text = tostring(ab):upper()
            ae.TextXAlignment = Enum.TextXAlignment.Left
            ae.TextColor3 = o.FaintText
            ae.TextSize = 10
            ae.FontFace = o.FontSemiBold
            ae.Parent = ad

            local af = Instance.new("Frame")
            af.Name = "Line"
            af.Size = UDim2.new(1, -16, 0, 1)
            af.Position = UDim2.new(0, 8, 1, -1)
            af.BackgroundColor3 = o.Border
            af.BackgroundTransparency = 0.76
            af.BorderSizePixel = 0
            af.Parent = ad
            return ad
        end

        local ac = Instance.new("Frame")
        ac.Name = "Divider"
        ac.Size = UDim2.new(1, -16, 0, 1)
        ac.Position = UDim2.fromOffset(8, 0)
        ac.BackgroundColor3 = o.Border
        ac.BackgroundTransparency = 0.82
        ac.BorderSizePixel = 0
        ac.Parent = aa
        return ac
    end,
}

local function premiumizeComponent(componentName, api)
    if type(api) ~= "table" or typeof(api.Object) ~= "Instance" then
        return api
    end

    local root = api.Object
    if not root:IsA("GuiObject") or root:GetAttribute("PremiumComponentStyled") then
        return api
    end
    root:SetAttribute("PremiumComponentStyled", true)

    local shouldCardStyle = componentName == "TextList"
        or componentName == "Targets"
        or componentName == "TargetsButton"
        or componentName == "TwoSlider"
        or componentName == "ColorSlider"
        or componentName == "Font"

    if shouldCardStyle then
        root.BackgroundTransparency = 1
        root.BorderSizePixel = 0
    end

    local card = root:FindFirstChild("BKG") or root:FindFirstChild("TextList") or root:FindFirstChild("Slider")

    if card and card:IsA("GuiObject") and shouldCardStyle then
        card.BackgroundColor3 = o.Surface
        card.BorderSizePixel = 0
        addCorner(card, o.Radius)
        addStroke(card, o.Border, 0.68, 1, "PremiumComponentStroke")
    end

    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("TextLabel") then
            if
                descendant.FontFace.Weight ~= Enum.FontWeight.Bold
                and descendant.FontFace.Weight ~= Enum.FontWeight.SemiBold
            then
                descendant.FontFace = o.Font
            end
            if descendant.Name == "Title" then
                descendant.TextColor3 = o.MutedText
            elseif descendant.Name == "Items" or descendant.Name == "Value" then
                descendant.TextColor3 = o.FaintText
            end
        elseif descendant:IsA("TextBox") then
            descendant.FontFace = o.Font
            descendant.TextColor3 = o.Text
            descendant.PlaceholderColor3 = o.FaintText
        elseif descendant:IsA("ScrollingFrame") then
            descendant.ScrollBarImageColor3 = o.BorderStrong
            descendant.ScrollBarImageTransparency = 0.35
            descendant.ScrollBarThickness = d.isMobile and 7 or 3
        elseif descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
            if descendant.ImageColor3 == Color3.new(1, 1, 1) then
                descendant.ImageColor3 = o.MutedText
            end
        end
    end

    return api
end

for aa, ab in H do
    local ac = ab
    H[aa] = function(ad, ...)
        local ae = { ... }
        if type(ad) ~= "table" then
            return ac(ad, unpack(ae))
        end
        ad.Function = a:wrap(ad.Function, {
            type = "component",
            component = tostring(aa),
            name = ad.Name,
        })
        local result = ac(ad, unpack(ae))
        return premiumizeComponent(tostring(aa), result)
    end
end

d.Components = setmetatable(H, {
    __newindex = function(aa, ab, ac)
        for ad, ae in d.Modules do
            rawset(ae, "Create" .. ab, function(af, ag)
                return ac(ag, ae.Children, ae)
            end)
            rawset(ae, "Add" .. ab, function(af, ag)
                return ac(ag, ae.Children, ae)
            end)
        end

        if d.Legit then
            for ad, ae in d.Legit.Modules do
                rawset(ae, "Create" .. ab, function(af, ag)
                    return ac(ag, ae.Children, ae)
                end)
                rawset(ae, "Add" .. ab, function(af, ag)
                    return ac(ag, ae.Children, ae)
                end)
            end
        end

        rawset(aa, ab, ac)
    end,
})

task.spawn(function()
    while d.Loaded ~= nil do
        if #d.RainbowTable == 0 then
            task.wait(0.2)
            continue
        end

        local speed = math.max(tonumber(d.RainbowSpeed.Value) or 1, 0)
        local hue = tick() * (0.2 * speed) % 1

        for index = #d.RainbowTable, 1, -1 do
            local picker = d.RainbowTable[index]
            local dead = type(picker) ~= "table"
                or type(picker.SetValue) ~= "function"
                or (picker.Object and picker.Object.Parent == nil)

            if dead then
                table.remove(d.RainbowTable, index)
            else
                local success = pcall(function()
                    if picker.Type == "GUISlider" then
                        picker:SetValue(
                            d:Color(hue),
                            nil,
                            nil,
                            nil,
                            true
                        )
                    else
                        picker:SetValue(
                            hue,
                            nil,
                            nil,
                            nil,
                            nil,
                            true
                        )
                    end
                end)

                if not success then
                    table.remove(d.RainbowTable, index)
                end
            end
        end

        local updateRate = math.clamp(
            tonumber(d.RainbowUpdateSpeed.Value) or 45,
            1,
            60
        )
        task.wait(1 / updateRate)
    end
end)

function d.BlurCheck(aa) end

function d.CreateGUI(aa)
    local ab = {
        Type = "MainWindow",
        Buttons = {},
        Options = {},
    }

    local ac = Instance.new("TextButton")
    ac.Name = "GUICategory"
    ac.Position = UDim2.fromOffset(6, 60)
    ac.BackgroundColor3 = o.Main
    ac.BackgroundTransparency = 0.005
    ac.AutoButtonColor = false
    ac.Text = ""
    ac.Parent = v
    addShadow(ac)
    addCorner(ac, o.RadiusLarge)
    local mainStroke = addStroke(ac, o.BorderStrong, 0.46, 1, "MainStroke")
    addSurfaceGradient(ac)
    local mainAccent = addAccentLine(ac, 2)
    addV9Chrome(ac)
    local mainScale = addScale(ac)
    makeDraggable(ac)

    ac:GetPropertyChangedSignal("Visible"):Connect(function()
        if not ac.Visible then
            return
        end

        mainScale.Scale = 1
        mainAccent.BackgroundTransparency = 0.08

        if d._InitialLayoutReady and not d._SuppressEntryAnimation then
            mainScale.Scale = 0.992
            n:Spring(mainScale, o.SpringPanel, { Scale = 1 })
        end
    end)

    local ad = Instance.new("TextLabel")
    ad.Name = "BrandLogo"
    ad.Size = UDim2.fromOffset(148, 26)
    ad.Position = UDim2.fromOffset(16, 9)
    ad.BackgroundTransparency = 1
    ad.Text = "BadWars"
    ad.TextColor3 = o.TextStrong
    ad.TextSize = 19
    ad.TextXAlignment = Enum.TextXAlignment.Left
    ad.FontFace = o.FontBold
    ad.Parent = ac

    local brandSub = Instance.new("TextLabel")
    brandSub.Name = "BrandSub"
    brandSub.Size = UDim2.fromOffset(156, 12)
    brandSub.Position = UDim2.fromOffset(16, 32)
    brandSub.BackgroundTransparency = 1
    brandSub.Text = "CONTROL CENTER"
    brandSub.TextColor3 = o.FaintText
    brandSub.TextSize = 8
    brandSub.TextXAlignment = Enum.TextXAlignment.Left
    brandSub.FontFace = o.FontBold
    brandSub.Parent = ac
    local localPlayer = f.Players.LocalPlayer

    local playerCard = Instance.new("Frame")
    playerCard.Name = "PlayerCard"
    playerCard.Size = UDim2.fromOffset(UI_WINDOW_WIDTH - 24, 58)
    playerCard.Position = UDim2.fromOffset(12, 50)
    playerCard.BackgroundColor3 = o.Surface
    playerCard.BackgroundTransparency = 0.05
    playerCard.BorderSizePixel = 0
    playerCard.ClipsDescendants = true
    playerCard.Parent = ac
    addCorner(playerCard, o.Radius)
    local playerCardStroke = addStroke(
        playerCard,
        o.Border,
        0.68,
        1,
        "PlayerCardStroke"
    )

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.Size = UDim2.fromOffset(38, 38)
    avatar.Position = UDim2.fromOffset(10, 10)
    avatar.BackgroundColor3 = o.Elevated
    avatar.BorderSizePixel = 0
    avatar.Image = "rbxthumb://type=AvatarHeadShot&id="
        .. tostring(localPlayer.UserId)
        .. "&w=150&h=150"
    avatar.Parent = playerCard
    addCorner(avatar, UDim.new(1, 0))
    addStroke(avatar, o.BorderStrong, 0.62, 1, "AvatarStroke")

    local onlineDot = Instance.new("Frame")
    onlineDot.Name = "Online"
    onlineDot.Size = UDim2.fromOffset(7, 7)
    onlineDot.AnchorPoint = Vector2.new(0.5, 0.5)
    onlineDot.Position = UDim2.new(0, 43, 1, -9)
    onlineDot.BackgroundColor3 = Color3.fromHSV(
        d.GUIColor.Hue,
        d.GUIColor.Sat,
        d.GUIColor.Value
    )
    onlineDot.BorderSizePixel = 0
    onlineDot.ZIndex = avatar.ZIndex + 2
    onlineDot.Parent = playerCard
    addCorner(onlineDot, UDim.new(1, 0))
    addStroke(onlineDot, o.Main, 0, 2, "OnlineStroke")

    local displayName = Instance.new("TextLabel")
    displayName.Name = "DisplayName"
    displayName.Size = UDim2.new(1, -68, 0, 20)
    displayName.Position = UDim2.fromOffset(58, 9)
    displayName.BackgroundTransparency = 1
    displayName.Text = localPlayer.DisplayName
    displayName.TextColor3 = o.TextStrong
    displayName.TextSize = 13
    displayName.TextTruncate = Enum.TextTruncate.AtEnd
    displayName.TextXAlignment = Enum.TextXAlignment.Left
    displayName.FontFace = o.FontSemiBold
    displayName.Parent = playerCard

    local userName = Instance.new("TextLabel")
    userName.Name = "Username"
    userName.Size = UDim2.new(1, -68, 0, 16)
    userName.Position = UDim2.fromOffset(58, 30)
    userName.BackgroundTransparency = 1
    userName.Text = "@" .. localPlayer.Name
    userName.TextColor3 = o.FaintText
    userName.TextSize = 9
    userName.TextTruncate = Enum.TextTruncate.AtEnd
    userName.TextXAlignment = Enum.TextXAlignment.Left
    userName.FontFace = o.Font
    userName.Parent = playerCard

    connectguicolorchange(function(hue, saturation, value)
        if onlineDot.Parent then
            onlineDot.BackgroundColor3 = Color3.fromHSV(
                hue,
                saturation,
                value
            )
        end
    end)

    playerCard.MouseEnter:Connect(function()
        n:Tween(playerCard, o.TweenFast, {
            BackgroundColor3 = o.SurfaceHover,
        })
        n:Tween(playerCardStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.66,
        })
    end)

    playerCard.MouseLeave:Connect(function()
        n:Tween(playerCard, o.TweenFast, {
            BackgroundColor3 = o.Surface,
        })
        n:Tween(playerCardStroke, o.TweenFast, {
            Color = o.Border,
            Transparency = 0.82,
        })
    end)

    local af = Instance.new("ScrollingFrame")
    af.Name = "Children"
    af.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, 320)
    af.Position = UDim2.fromOffset(0, 116)
    af.BackgroundTransparency = 1
    af.BorderSizePixel = 0
    af.CanvasSize = UDim2.new()
    af.AutomaticCanvasSize = Enum.AutomaticSize.None
    af.ScrollingDirection = Enum.ScrollingDirection.Y
    af.ScrollingEnabled = true
    af.ElasticBehavior = Enum.ElasticBehavior.Never
    af.ScrollBarThickness = d.isMobile and 7 or 3
    af.ScrollBarImageColor3 = o.BorderStrong
    af.ScrollBarImageTransparency = d.isMobile and 0.28 or 0.58
    af.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    af.Parent = ac
    local ag = Instance.new("UIListLayout")
    ag.SortOrder = Enum.SortOrder.LayoutOrder
    ag.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ag.Padding = UDim.new(0, 5)
    ag.Parent = af
    local ah = Instance.new("TextButton")
    ah.Name = "Settings"
    ah.Size = UDim2.fromOffset(40, 40)
    ah.Position = UDim2.new(1, -46, 0, 7)
    ah.BackgroundTransparency = 1
    ah.Text = ""
    ah.Parent = ac
    addTooltip(ah, "Open settings")
    addCorner(ah, o.RadiusSmall)
    local settingsStroke = addStroke(ah, o.Border, 1, 1, "SettingsStroke")
    bindPremiumMotion(ah, ah, settingsStroke, {
        HoverScale = 1.04,
        PressScale = 0.94,
        HoverTransparency = 0.35,
        NormalTransparency = 1,
    })
    local ai = Instance.new("ImageLabel")
    ai.Size = UDim2.fromOffset(14, 14)
    ai.Position = UDim2.fromOffset(12, 11)
    ai.BackgroundTransparency = 1
    ai.Image = u("badscript/assets/new/guisettings.png")
    ai.ImageColor3 = m.Light(o.Main, 0.37)
    ai.Parent = ah
    local aj = Instance.new("TextButton")
    aj.Name = "DiscordInvite"
    aj.Size = UDim2.fromOffset(206, 36)
    aj.AnchorPoint = Vector2.new(0.5, 1)
    aj.Position = UDim2.new(0.5, 0, 1, -18)
    aj.BackgroundColor3 = o.MainSoft
    aj.BackgroundTransparency = 0.03
    aj.BorderSizePixel = 0
    aj.AutoButtonColor = false
    aj.Text = ""
    aj.ClipsDescendants = false
    aj.ZIndex = 1200
    aj.Parent = w
    addCorner(aj, UDim.new(1, 0))
    addSurfaceGradient(aj)
    addShadow(aj)

    local discordStroke = addStroke(
        aj,
        o.BorderStrong,
        0.5,
        1,
        "DiscordStroke"
    )

    local discordAccent = Instance.new("Frame")
    discordAccent.Name = "Accent"
    discordAccent.Size = UDim2.fromOffset(6, 6)
    discordAccent.AnchorPoint = Vector2.new(0.5, 0.5)
    discordAccent.Position = UDim2.fromOffset(20, 18)
    discordAccent.BorderSizePixel = 0
    discordAccent.BackgroundColor3 =
        Color3.fromHSV(
            d.GUIColor.Hue,
            d.GUIColor.Sat,
            d.GUIColor.Value
        )
    discordAccent.ZIndex = aj.ZIndex + 2
    discordAccent.Parent = aj
    addCorner(discordAccent, UDim.new(1, 0))

    local discordLabel = Instance.new("TextLabel")
    discordLabel.Name = "Label"
    discordLabel.Size = UDim2.new(1, -52, 1, 0)
    discordLabel.Position = UDim2.fromOffset(38, 0)
    discordLabel.BackgroundTransparency = 1
    discordLabel.Text = "Copy Discord invite"
    discordLabel.TextColor3 = o.TextStrong
    discordLabel.TextSize = 12
    discordLabel.TextXAlignment = Enum.TextXAlignment.Left
    discordLabel.FontFace = o.FontSemiBold
    discordLabel.ZIndex = aj.ZIndex + 3
    discordLabel.Parent = aj

    local discordChevron = Instance.new("ImageLabel")
    discordChevron.Name = "Chevron"
    discordChevron.Size = UDim2.fromOffset(5, 9)
    discordChevron.AnchorPoint = Vector2.new(1, 0.5)
    discordChevron.Position = UDim2.new(1, -17, 0.5, 0)
    discordChevron.BackgroundTransparency = 1
    discordChevron.Image = u("badscript/assets/new/expandright.png")
    discordChevron.ImageColor3 = o.FaintText
    discordChevron.ZIndex = aj.ZIndex + 3
    discordChevron.Parent = aj

    connectguicolorchange(function(hue, saturation, value)
        if discordAccent.Parent then
            discordAccent.BackgroundColor3 =
                Color3.fromHSV(hue, saturation, value)
        end
    end)

    addTooltip(aj, "Copy https://discord.gg/K2TQx4vyR7")
    local ak = Instance.new("TextButton")
    ak.Size = UDim2.fromScale(1, 1)
    ak.BackgroundColor3 = o.MainSoft
    ak.AutoButtonColor = false
    ak.Visible = false
    ak.Text = ""
    ak.Parent = ac
    local al = Instance.new("TextLabel")
    al.Name = "Title"
    al.Size = UDim2.new(1, -36, 0, 20)
    al.Position = UDim2.fromOffset(math.abs(al.Size.X.Offset), 11)
    al.BackgroundTransparency = 1
    al.Text = "Settings"
    al.TextXAlignment = Enum.TextXAlignment.Left
    al.TextColor3 = o.TextStrong
    al.TextSize = 13
    al.FontFace = o.FontSemiBold
    al.Parent = ak
    local am = addCloseButton(ak)
    local an = Instance.new("ImageButton")
    an.Name = "Back"
    an.Size = UDim2.fromOffset(16, 16)
    an.Position = UDim2.fromOffset(11, 13)
    an.BackgroundTransparency = 1
    an.Image = u("badscript/assets/new/back.png")
    an.ImageColor3 = m.Light(o.Main, 0.37)
    an.Parent = ak
    addCorner(ak, o.RadiusLarge)
    addStroke(ak, o.Border, 0.32, 1)
    local ap = Instance.new("ScrollingFrame")
    ap.Name = "Children"
    ap.Size = UDim2.new(1, 0, 1, -57)
    ap.Position = UDim2.fromOffset(0, 41)
    ap.BackgroundColor3 = o.MainSoft
    ap.BorderSizePixel = 0
    ap.CanvasSize = UDim2.new()
    ap.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ap.ScrollingDirection = Enum.ScrollingDirection.Y
    ap.ElasticBehavior = Enum.ElasticBehavior.Never
    ap.ScrollBarThickness = d.isMobile and 6 or 2
    ap.ScrollBarImageColor3 = o.BorderStrong
    ap.ScrollBarImageTransparency = d.isMobile and 0.28 or 0.5
    ap.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    ap.Parent = ak
    local aq = Instance.new("UIListLayout")
    aq.SortOrder = Enum.SortOrder.LayoutOrder
    aq.HorizontalAlignment = Enum.HorizontalAlignment.Center
    aq.Padding = UDim.new(0, 4)
    aq.Parent = ap
    local settingsLandingPadding = Instance.new("UIPadding")
    settingsLandingPadding.PaddingTop = UDim.new(0, 2)
    settingsLandingPadding.PaddingBottom = UDim.new(0, 18)
    settingsLandingPadding.Parent = ap
    local function setScrollEnabledIfSupported(object, enabled)
        if object and object:IsA("ScrollingFrame") then
            object.ScrollingEnabled = enabled
        end
    end
    ab.Object = ac

    function ab.CreateBind(ar)
        local as = { Bind = { "RightShift" } }

        local at = Instance.new("TextButton")
        at.Size = UDim2.new(1, -12, 0, 42)
        at.BackgroundColor3 = o.Surface
        at.BorderSizePixel = 0
        at.AutoButtonColor = false
        at.Text = "Rebind GUI"
        at.TextXAlignment = Enum.TextXAlignment.Left
        at.TextColor3 = o.MutedText
        at.TextSize = 13
        at.FontFace = o.FontSemiBold
        at.Parent = ap
        addCorner(at, o.Radius)
        local bindRowStroke = addStroke(
            at,
            o.Border,
            0.84,
            1,
            "SettingsRowStroke"
        )
        local bindPadding = Instance.new("UIPadding")
        bindPadding.PaddingLeft = UDim.new(0, 14)
        bindPadding.Parent = at
        addTooltip(at, "Change the bind of the GUI")
        local au = Instance.new("TextButton")
        au.Name = "Bind"
        au.Size = UDim2.fromOffset(72, 24)
        au.Position = UDim2.new(1, -10, 0.5, -12)
        au.AnchorPoint = Vector2.new(1, 0)
        au.BackgroundColor3 = o.MainSoft
        au.BackgroundTransparency = 0.05
        au.BorderSizePixel = 0
        au.AutoButtonColor = false
        au.Text = ""
        au.Parent = at
        addTooltip(au, "Click to bind")
        addCorner(au, o.RadiusSmall)
        local bindButtonStroke = addStroke(
            au,
            o.Border,
            0.72,
            1,
            "BindButtonStroke"
        )
        local av = Instance.new("ImageLabel")
        av.Name = "Icon"
        av.Size = UDim2.fromOffset(12, 12)
        av.Position = UDim2.new(0.5, -6, 0, 5)
        av.BackgroundTransparency = 1
        av.Image = u("badscript/assets/new/bind.png")
        av.ImageColor3 = o.MutedText
        av.Parent = au
        local aw = Instance.new("TextLabel")
        aw.Name = "Text"
        aw.Size = UDim2.fromScale(1, 1)
        aw.Position = UDim2.fromOffset(0, 1)
        aw.BackgroundTransparency = 1
        aw.Visible = false
        aw.Text = ""
        aw.TextColor3 = o.MutedText
        aw.TextSize = 12
        aw.FontFace = o.Font
        aw.Parent = au

        function as.SetBind(ax, ay)
            d.Keybind = #ay <= 0 and d.Keybind or table.clone(ay)
            ax.Bind = d.Keybind
            if d.MobileToggleButton then
                d.MobileToggleButton:Destroy()
                d.MobileToggleButton = nil
            end

            au.Visible = true
            aw.Visible = true
            av.Visible = false
            aw.Text = table.concat(d.Keybind, " + "):upper()
            au.Size = UDim2.fromOffset(math.max(E(aw.Text, aw.TextSize, aw.Font).X + 10, 20), 21)
        end

        au.MouseEnter:Connect(function()
            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            aw.Visible = false
            av.Visible = true
            av.Image = u("badscript/assets/new/edit.png")
            av.ImageColor3 = accent
            n:Tween(au, o.TweenFast, { BackgroundColor3 = o.SurfaceHover })
            n:Tween(bindButtonStroke, o.TweenFast, {
                Color = accent,
                Transparency = 0.56,
            })
        end)
        au.MouseLeave:Connect(function()
            aw.Visible = true
            av.Visible = false
            av.Image = u("badscript/assets/new/bind.png")
            av.ImageColor3 = o.MutedText
            n:Tween(au, o.TweenFast, { BackgroundColor3 = o.MainSoft })
            n:Tween(bindButtonStroke, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.72,
            })
        end)
        au.Activated:Connect(function()
            table.clear(d.HeldKeybinds)
            d.Binding = as
        end)

        ab.Options.Bind = as

        return as
    end

    function ab.CreateButton(ar, as)
        local at = {
            Enabled = false,
            Index = getTableSize(ab.Buttons),
        }

        local au = Instance.new("TextButton")
        au.Name = as.Name
        au.Size = UDim2.new(1, -14, 0, UI_NAV_ROW_HEIGHT)
        au.BackgroundColor3 = o.Surface
        au.BackgroundTransparency = 0.14
        au.BorderSizePixel = 0
        au.AutoButtonColor = false
        au.Text = (as.Icon and "          " or "    ") .. tostring(as.Name)
        au.TextXAlignment = Enum.TextXAlignment.Left
        au.TextColor3 = o.MutedText
        au.TextSize = 14
        au.FontFace = o.FontSemiBold
        au.ClipsDescendants = true
        au.Parent = af
        addCorner(au, o.Radius)
        local avStroke = addStroke(au, o.Border, 0.88, 1, "NavigationStroke")
        local avScale = addScale(au)
        local avSweep = addV9Sweep(au)

        local avRail = Instance.new("Frame")
        avRail.Name = "ActiveRail"
        avRail.Size = UDim2.new(0, 2, 1, -18)
        avRail.Position = UDim2.fromOffset(0, 8)
        avRail.BackgroundTransparency = 0.16
        avRail.BorderSizePixel = 0
        avRail.Visible = false
        avRail.Parent = au
        addCorner(avRail, UDim.new(1, 0))
        connectguicolorchange(function(ax, ay, az)
            avRail.BackgroundColor3 = Color3.fromHSV(ax, ay, az)
            if at.Enabled then
                avStroke.Color = avRail.BackgroundColor3
            end
        end)

        local av
        if as.Icon then
            av = Instance.new("ImageLabel")
            av.Name = "Icon"
            av.Size = as.Size
            av.Position = UDim2.fromOffset(14, 13)
            av.BackgroundTransparency = 1
            av.Image = as.Icon
            av.ImageColor3 = o.MutedText
            av.Parent = au
        end

        if as.Name == "Profiles" then
            local aw = Instance.new("TextLabel")
            aw.Name = "ProfileLabel"
            aw.Size = UDim2.fromOffset(58, 24)
            aw.Position = UDim2.new(1, -35, 0.5, -12)
            aw.AnchorPoint = Vector2.new(1, 0)
            aw.BackgroundColor3 = o.MainSoft
            aw.Text = "default"
            aw.TextColor3 = o.MutedText
            aw.TextSize = 11
            aw.FontFace = o.FontSemiBold
            aw.Parent = au
            addCorner(aw, o.RadiusSmall)
            addStroke(aw, o.Border, 0.72, 1, "ProfileStroke")
            d.ProfileLabel = aw
        end

        local aw = Instance.new("ImageLabel")
        aw.Name = "Arrow"
        aw.Size = UDim2.fromOffset(5, 9)
        aw.Position = UDim2.new(1, -20, 0.5, -4)
        aw.BackgroundTransparency = 1
        aw.Image = u("badscript/assets/new/expandright.png")
        aw.ImageColor3 = o.FaintText
        aw.Parent = au

        at.Name = as.Name
        at.Icon = av
        at.Object = au

        local function applyNavigationVisual()
            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            local dimAccent = accent:Lerp(o.MutedText, 0.62)
            local activeText = accent:Lerp(o.TextStrong, 0.8)
            avRail.Visible = at.Enabled
            n:Tween(au, o.TweenFast, {
                BackgroundColor3 = at.Enabled and o.Elevated or o.Surface,
                BackgroundTransparency = at.Enabled and 0.03 or 0.14,
                TextColor3 = at.Enabled and activeText or o.MutedText,
            })
            n:Tween(avStroke, o.TweenFast, {
                Color = at.Enabled and dimAccent or o.Border,
                Transparency = at.Enabled and 0.58 or 0.88,
            })
            n:Tween(aw, o.TweenFast, {
                Position = UDim2.new(1, at.Enabled and -17 or -20, 0.5, -4),
                ImageColor3 = at.Enabled and dimAccent or o.FaintText,
            })
            if av then
                n:Tween(av, o.TweenFast, {
                    ImageColor3 = at.Enabled and dimAccent or o.MutedText,
                })
            end
        end

        function at.Toggle(ax, ay)
            if ay ~= nil then
                if ay == ax.Enabled then
                    return
                end
                ax.Enabled = ay
            else
                ax.Enabled = not ax.Enabled
            end
            applyNavigationVisual()
            as.Window.Visible = ax.Enabled
        end

        if as.Default and not at.Enabled then
            at:Toggle()
        else
            applyNavigationVisual()
        end

        if not d.isMobile then
            au.MouseEnter:Connect(function()
                local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                local hoverAccent = accent:Lerp(o.TextStrong, 0.78)
                n:Tween(au, o.TweenFast, {
                    BackgroundColor3 = o.SurfaceHover,
                    BackgroundTransparency = 0.01,
                    TextColor3 = hoverAccent,
                })
                n:Tween(avStroke, o.TweenFast, {
                    Color = accent:Lerp(o.BorderStrong, 0.55),
                    Transparency = at.Enabled and 0.66 or 0.78,
                })
                n:Tween(aw, o.TweenFast, { ImageColor3 = hoverAccent })
                if av then
                    n:Tween(av, o.TweenFast, { ImageColor3 = hoverAccent })
                end
                if at.Enabled then
                    playV9Sweep(avSweep)
                end
                n:Spring(avScale, o.SpringInteractive, { Scale = 1.006 })
            end)
            au.MouseLeave:Connect(function()
                applyNavigationVisual()
                n:Spring(avScale, o.SpringInteractive, { Scale = 1 })
            end)
            au.MouseButton1Down:Connect(function()
                n:Spring(avScale, o.SpringInteractive, { Scale = 0.996 })
            end)
            au.MouseButton1Up:Connect(function()
                n:Spring(avScale, o.SpringInteractive, { Scale = 1.006 })
            end)
        end

        au.Activated:Connect(function()
            at:Toggle()
        end)

        if as.Window and as.Window.GetPropertyChangedSignal then
            d:Clean(as.Window:GetPropertyChangedSignal("Visible"):Connect(function()
                local visible = as.Window.Visible == true
                if at.Enabled ~= visible then
                    at.Enabled = visible
                    applyNavigationVisual()
                end
            end))
        end

        ab.Buttons[as.Name] = at
        return at
    end

    function ab.CreateDivider(ar, as)
        return H.Divider(af, as)
    end

    function ab.CreateSettingsDivider(ar)
        H.Divider(ap)
    end

    function ab.CreateSettingsPane(ar, as)
        local at = {}
        local transition = TweenInfo.new(
            0.14,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )

        local au = Instance.new("TextButton")
        au.Name = as.Name
        au.Size = UDim2.new(1, -12, 0, 42)
        au.BackgroundColor3 = o.Surface
        au.BorderSizePixel = 0
        au.AutoButtonColor = false
        au.Text = ""
        au.ClipsDescendants = true
        au.Parent = ap
        addCorner(au, o.Radius)
        local rowStroke = addStroke(
            au,
            o.Border,
            0.84,
            1,
            "SettingsRowStroke"
        )

        local av = Instance.new("TextLabel")
        av.Name = "Title"
        av.Size = UDim2.new(1, -62, 1, 0)
        av.Position = UDim2.fromOffset(14, 0)
        av.BackgroundTransparency = 1
        av.Text = as.Name
        av.TextXAlignment = Enum.TextXAlignment.Left
        av.TextColor3 = o.MutedText
        av.TextSize = 13
        av.FontFace = o.FontSemiBold
        av.Parent = au

        local arrow = Instance.new("ImageLabel")
        arrow.Name = "Arrow"
        arrow.Size = UDim2.fromOffset(5, 9)
        arrow.Position = UDim2.new(1, -20, 0.5, -4)
        arrow.BackgroundTransparency = 1
        arrow.Image = u("badscript/assets/new/expandright.png")
        arrow.ImageColor3 = o.FaintText
        arrow.Parent = au

        local aw = Instance.new("Frame")
        aw.Name = as.Name .. "SettingsPane"
        aw.Size = UDim2.fromScale(1, 1)
        aw.Position = UDim2.fromOffset(0, 0)
        aw.ClipsDescendants = true
        aw.BackgroundColor3 = o.MainSoft
        aw.BackgroundTransparency = 0.01
        aw.BorderSizePixel = 0
        aw.Visible = false
        aw.Active = false
        aw.ZIndex = 520
        aw.Parent = ac
        addCorner(aw, o.RadiusLarge)
        addSurfaceGradient(aw)
        local paneStroke = addStroke(
            aw,
            o.BorderStrong,
            1,
            1,
            "SettingsPaneStroke"
        )
        local paneShadow = addShadow(aw, true)
        paneShadow.ImageTransparency = 1
        local paneScale = addScale(aw)
        paneScale.Scale = 0.985

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 48)
        header.BackgroundColor3 = o.MainSoft
        header.BackgroundTransparency = 0.08
        header.BorderSizePixel = 0
        header.ZIndex = 521
        header.Parent = aw

        local back = Instance.new("ImageButton")
        back.Name = "Back"
        back.Size = UDim2.fromOffset(28, 28)
        back.Position = UDim2.fromOffset(8, 10)
        back.BackgroundColor3 = o.Surface
        back.BackgroundTransparency = 0.08
        back.BorderSizePixel = 0
        back.AutoButtonColor = false
        back.Image = u("badscript/assets/new/back.png")
        back.ImageColor3 = o.MutedText
        back.ZIndex = 523
        back.Parent = header
        addCorner(back, o.RadiusSmall)
        local backStroke = addStroke(back, o.Border, 0.78, 1, "BackStroke")

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -82, 0, 22)
        title.Position = UDim2.fromOffset(45, 13)
        title.BackgroundTransparency = 1
        title.Text = as.Name
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = o.TextStrong
        title.TextSize = 14
        title.FontFace = o.FontSemiBold
        title.ZIndex = 522
        title.Parent = header

        local close = addCloseButton(header, 10)
        close.ZIndex = 523

        local divider = Instance.new("Frame")
        divider.Name = "Divider"
        divider.Size = UDim2.new(1, -20, 0, 1)
        divider.Position = UDim2.fromOffset(10, 47)
        divider.BackgroundColor3 = o.Border
        divider.BackgroundTransparency = 0.68
        divider.BorderSizePixel = 0
        divider.ZIndex = 522
        divider.Parent = aw

        local children = Instance.new("ScrollingFrame")
        children.Name = "Children"
        children.Size = UDim2.new(1, -12, 1, -60)
        children.Position = UDim2.fromOffset(6, 54)
        children.BackgroundTransparency = 1
        children.BorderSizePixel = 0
        children.ScrollBarThickness = 2
        children.ScrollBarImageColor3 = o.BorderStrong
        children.ScrollBarImageTransparency = 0.42
        children.ScrollingDirection = Enum.ScrollingDirection.Y
        children.ElasticBehavior = Enum.ElasticBehavior.Never
        children.CanvasSize = UDim2.new()
        children.ZIndex = 521
        children.Parent = aw

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 6)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Parent = children

        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, 2)
        padding.PaddingBottom = UDim.new(0, 16)
        padding.Parent = children

        for L, M in H do
    at["Create" .. L] = function(N, O)
        local control = M(O, children, ab)
        local rootControl =
            typeof(control) == "Instance"
                and control
                or (
                    type(control) == "table"
                    and (
                        control.Object
                        or control.Frame
                        or control.Button
                        or control.Instance
                    )
                )

        if
            typeof(rootControl) == "Instance"
            and rootControl:IsA("GuiObject")
        then
            local function promote(instance)
                if instance:IsA("GuiObject") then
                    instance.ZIndex = math.max(instance.ZIndex, 524)
                end
            end

            promote(rootControl)

            for _, descendant in ipairs(rootControl:GetDescendants()) do
                promote(descendant)
            end

            local addedConnection
            addedConnection = rootControl.DescendantAdded:Connect(promote)

            rootControl.Destroying:Once(function()
                if addedConnection then
                    addedConnection:Disconnect()
                    addedConnection = nil
                end
            end)
        end

        return control
    end

    at["Add" .. L] = at["Create" .. L]
end

        -- BADWARS_SETTINGS_PAGE_MANAGER_V3
        d._SettingsPageState = d._SettingsPageState or {
            Current = nil,
            Generation = 0,
        }
        d._SettingsPaneClosers = d._SettingsPaneClosers
            or setmetatable({}, { __mode = "k" })

        local function cancelPaneTweens()
            n:Cancel(aw)
            n:Cancel(paneScale)
            n:Cancel(paneStroke)
            n:Cancel(paneShadow)
        end

        local function setPaneVisible(visible, instant)
            local state = d._SettingsPageState
            state.Generation += 1
            local generation = state.Generation

            if d.HideTooltip then
                d.HideTooltip(true)
            end

            if d._OpenDropdown then
                pcall(d._OpenDropdown, true)
                d._OpenDropdown = nil
            end

            cancelPaneTweens()

            if visible then
                local currentPane = state.Current
                if currentPane and currentPane ~= aw and currentPane.Parent then
                    local closer = d._SettingsPaneClosers[currentPane]
                    if type(closer) == "function" then
                        closer(false, true)
                    else
                        currentPane.Visible = false
                        currentPane.Active = false
                        pcall(function()
                            currentPane.Interactable = false
                        end)
                    end
                end

                state.Current = aw
                d._OpenSettingsPane = aw

                ap.Visible = false
                ap.Active = false
                setScrollEnabledIfSupported(ap, false)
                pcall(function()
                    ap.Interactable = false
                end)

                aw.Visible = true
                aw.Active = true
                pcall(function()
                    aw.Interactable = true
                end)

                -- The page is placed into a valid final render state before
                -- animation so an interrupted tween can never leave it blank.
                aw.BackgroundTransparency = 0.01
                paneScale.Scale = (instant or not d.Loaded) and 1 or 0.992
                paneStroke.Transparency = (instant or not d.Loaded) and 0.5 or 0.8
                paneShadow.ImageTransparency = (instant or not d.Loaded) and 0.82 or 0.92

                if instant or not d.Loaded then
                    return
                end

                n:Spring(paneScale, o.SpringPanel, { Scale = 1 })
                n:Tween(paneStroke, transition, { Transparency = 0.5 })
                n:Tween(paneShadow, transition, { ImageTransparency = 0.82 })
                return
            end

            aw.Active = false
            pcall(function()
                aw.Interactable = false
            end)

            local function finishClose()
                if generation ~= state.Generation then
                    return
                end

                aw.Visible = false
                paneScale.Scale = 1
                paneStroke.Transparency = 0.5
                paneShadow.ImageTransparency = 0.82

                if state.Current == aw then
                    state.Current = nil
                end
                if d._OpenSettingsPane == aw then
                    d._OpenSettingsPane = nil
                end

                local restoreMain = ak.Visible and state.Current == nil
                ap.Visible = restoreMain
                ap.Active = restoreMain
                setScrollEnabledIfSupported(ap, restoreMain)
                pcall(function()
                    ap.Interactable = restoreMain
                end)
            end

            if instant or not d.Loaded then
                finishClose()
                return
            end

            local closeTween = n:Tween(paneScale, transition, { Scale = 0.992 })
            n:Tween(paneStroke, transition, { Transparency = 0.82 })
            n:Tween(paneShadow, transition, { ImageTransparency = 0.94 })

            if closeTween then
                closeTween.Completed:Once(finishClose)
            else
                finishClose()
            end
        end

        d._SettingsPaneClosers[aw] = setPaneVisible

        aw.Destroying:Once(function()
            if d._SettingsPaneClosers then
                d._SettingsPaneClosers[aw] = nil
            end
            if d._SettingsPageState and d._SettingsPageState.Current == aw then
                d._SettingsPageState.Current = nil
            end
            if d._OpenSettingsPane == aw then
                d._OpenSettingsPane = nil
            end
        end)
        local function refreshSettingsCanvas()
            task.defer(function()
                if not children or not children.Parent then
                    return
                end
                local contentHeight = layout.AbsoluteContentSize.Y
                local padTop = padding.PaddingTop.Offset
                local padBottom = padding.PaddingBottom.Offset
                children.CanvasSize = UDim2.fromOffset(
                    0,
                    contentHeight + padTop + padBottom + 8
                )
            end)
        end

        connectDeferredPropertyChanged(layout, "AbsoluteContentSize", refreshSettingsCanvas)
        task.defer(refreshSettingsCanvas)

        au.MouseEnter:Connect(function()
            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            n:Tween(au, o.TweenFast, { BackgroundColor3 = o.SurfaceHover })
            n:Tween(rowStroke, o.TweenFast, {
                Color = accent,
                Transparency = 0.68,
            })
            n:Tween(av, o.TweenFast, {
                TextColor3 = accent:Lerp(o.MutedText, 0.28),
            })
            n:Tween(arrow, o.TweenFast, {
                ImageColor3 = accent:Lerp(o.MutedText, 0.28),
            })
        end)
        au.MouseLeave:Connect(function()
            n:Tween(au, o.TweenFast, { BackgroundColor3 = o.Surface })
            n:Tween(rowStroke, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.84,
            })
            n:Tween(av, o.TweenFast, { TextColor3 = o.MutedText })
            n:Tween(arrow, o.TweenFast, { ImageColor3 = o.FaintText })
        end)

        back.MouseEnter:Connect(function()
            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            n:Tween(back, o.TweenFast, {
                BackgroundColor3 = o.SurfaceHover,
                ImageColor3 = accent,
            })
            n:Tween(backStroke, o.TweenFast, {
                Color = accent,
                Transparency = 0.58,
            })
        end)
        back.MouseLeave:Connect(function()
            n:Tween(back, o.TweenFast, {
                BackgroundColor3 = o.Surface,
                ImageColor3 = o.MutedText,
            })
            n:Tween(backStroke, o.TweenFast, {
                Color = o.Border,
                Transparency = 0.78,
            })
        end)

        au.Activated:Connect(function()
            setPaneVisible(true)
        end)
        back.Activated:Connect(function()
            setPaneVisible(false)
        end)
        close.Activated:Connect(function()
            setPaneVisible(false)
        end)

        at.Object = au
        at.Window = aw
        at.SetVisible = setPaneVisible
        return at
    end


local function restyleLegacySettingsControl(instance)
    if not instance or not instance.Parent then
        return
    end

    local parent = instance.Parent
    local inSettings = parent == ap
        or parent.Name == "Children"
        or parent:IsDescendantOf(ap)

    if not inSettings then
        return
    end

    if instance:IsA("TextButton") and instance.Name:find("Slider") then
        instance.BackgroundColor3 = o.Surface
        instance.BackgroundTransparency = 0
        instance.BorderSizePixel = 0
        addCorner(instance, o.Radius)
        if not instance:FindFirstChild("SettingsSliderStroke") then
            addStroke(
                instance,
                o.Border,
                0.86,
                1,
                "SettingsSliderStroke"
            )
        end
    elseif instance:IsA("TextLabel") and instance.Name == "Title" then
        instance.TextColor3 = o.MutedText
        instance.FontFace = o.FontSemiBold
    end
end

for _, descendant in ipairs(ap:GetDescendants()) do
    restyleLegacySettingsControl(descendant)
end

d:Clean(ap.DescendantAdded:Connect(function(descendant)
    task.defer(restyleLegacySettingsControl, descendant)
end))

    function ab.CreateGUISlider(ar, as)
        local at = {
            Type = "GUISlider",
            Notch = 4,
            Hue = 0.46,
            Sat = 0.96,
            Value = 0.52,
            Rainbow = false,
            CustomColor = false,
        }
        local au = {
            Color3.fromRGB(250, 50, 56),
            Color3.fromRGB(242, 99, 33),
            Color3.fromRGB(252, 179, 22),
            Color3.fromRGB(5, 133, 104),
            Color3.fromRGB(47, 122, 229),
            Color3.fromRGB(126, 84, 217),
            Color3.fromRGB(232, 96, 152),
        }
        local av = {
            4,
            33,
            62,
            90,
            119,
            148,
            177,
        }

        local function createSlider(aw, ax)
            local ay = Instance.new("TextButton")
            ay.Name = as.Name .. "Slider" .. aw
            ay.Size = UDim2.fromOffset(220, 50)
            ay.BackgroundColor3 = m.Dark(o.Main, 0.02)
            ay.BorderSizePixel = 0
            ay.AutoButtonColor = false
            ay.Visible = false
            ay.Text = ""
            ay.Parent = ap
            local az = Instance.new("TextLabel")
            az.Name = "Title"
            az.Size = UDim2.fromOffset(60, 30)
            az.Position = UDim2.fromOffset(10, 2)
            az.BackgroundTransparency = 1
            az.Text = aw
            az.TextXAlignment = Enum.TextXAlignment.Left
            az.TextColor3 = o.MutedText
            az.TextSize = 11
            az.FontFace = o.Font
            az.Parent = ay
            local I = Instance.new("Frame")
            I.Name = "Slider"
            I.Size = UDim2.fromOffset(200, 2)
            I.Position = UDim2.fromOffset(10, 37)
            I.BackgroundColor3 = Color3.new(1, 1, 1)
            I.BorderSizePixel = 0
            I.Parent = ay
            local J = Instance.new("UIGradient")
            J.Color = ax
            J.Parent = I
            local K = I:Clone()
            K.Name = "Fill"
            K.Size = UDim2.fromScale(1, 1)
            K.Position = UDim2.new()
            K.BackgroundTransparency = 1
            K.Parent = I
            local L = Instance.new("Frame")
            L.Name = "Knob"
            L.Size = UDim2.fromOffset(24, 4)
            L.Position = UDim2.fromScale(1, 0.5)
            L.AnchorPoint = Vector2.new(0.5, 0.5)
            L.BackgroundColor3 = m.Dark(o.Main, 0.02)
            L.BorderSizePixel = 0
            L.Parent = K
            local M = Instance.new("Frame")
            M.Name = "Knob"
            M.Size = UDim2.fromOffset(14, 14)
            M.Position = UDim2.fromScale(0.5, 0.5)
            M.AnchorPoint = Vector2.new(0.5, 0.5)
            M.BackgroundColor3 = o.Text
            M.Parent = L
            addCorner(M, UDim.new(1, 0))
            if aw == "Custom color" then
                local N = Instance.new("TextButton")
                N.Size = UDim2.fromOffset(45, 20)
                N.Position = UDim2.new(1, -52, 0, 5)
                N.BackgroundTransparency = 1
                N.Text = "RESET"
                N.TextColor3 = o.MutedText
                N.TextSize = 11
                N.FontFace = o.Font
                N.Parent = ay
                N.Activated:Connect(function()
                    at:SetValue(nil, nil, nil, 4)
                end)
            end

            ay.InputBegan:Connect(function(N)
                if
                    (N.UserInputType == Enum.UserInputType.MouseButton1 or N.UserInputType == Enum.UserInputType.Touch)
                    and (N.Position.Y - ay.AbsolutePosition.Y) > (20 * A.Scale)
                then
                    local O = h.InputChanged:Connect(function(O)
                        if
                            O.UserInputType
                            == (
                                N.UserInputType == Enum.UserInputType.MouseButton1
                                    and Enum.UserInputType.MouseMovement
                                or Enum.UserInputType.Touch
                            )
                        then
                            local P = math.clamp((O.Position.X - I.AbsolutePosition.X) / I.AbsoluteSize.X, 0, 1)
                            at:SetValue(
                                aw == "Custom color" and P or nil,
                                aw == "Saturation" and P or nil,
                                aw == "Vibrance" and P or nil,
                                aw == "Opacity" and P or nil
                            )
                        end
                    end)

                    local P
                    P = N.Changed:Connect(function()
                        if N.UserInputState == Enum.UserInputState.End then
                            if O then
                                O:Disconnect()
                            end
                            if P then
                                P:Disconnect()
                            end
                        end
                    end)
                end
            end)
            ay.MouseEnter:Connect(function()
                n:Tween(M, o.Tween, {
                    Size = UDim2.fromOffset(16, 16),
                })
            end)
            ay.MouseLeave:Connect(function()
                n:Tween(M, o.Tween, {
                    Size = UDim2.fromOffset(14, 14),
                })
            end)

            return ay
        end

        local aw = Instance.new("TextButton")
        aw.Name = as.Name .. "Slider"
        aw.Size = UDim2.fromOffset(220, 50)
        aw.BackgroundTransparency = 1
        aw.AutoButtonColor = false
        aw.Text = ""
        aw.Parent = ap
        local ax = Instance.new("TextLabel")
        ax.Name = "Title"
        ax.Size = UDim2.fromOffset(60, 30)
        ax.Position = UDim2.fromOffset(10, 2)
        ax.BackgroundTransparency = 1
        ax.Text = as.Name
        ax.TextXAlignment = Enum.TextXAlignment.Left
        ax.TextColor3 = o.MutedText
        ax.TextSize = 11
        ax.FontFace = o.Font
        ax.Parent = aw
        local ay = Instance.new("Frame")
        ay.Name = "Slider"
        ay.Size = UDim2.fromOffset(200, 2)
        ay.Position = UDim2.fromOffset(10, 37)
        ay.BackgroundTransparency = 1
        ay.BorderSizePixel = 0
        ay.Parent = aw
        local az = 0
        for I, J in au do
            local K = Instance.new("Frame")
            K.Size = UDim2.fromOffset(27 + (((I + 1) % 2) == 0 and 1 or 0), 2)
            K.Position = UDim2.fromOffset(az, 0)
            K.BackgroundColor3 = J
            K.BorderSizePixel = 0
            K.Parent = ay
            az += (K.Size.X.Offset + 1)
        end
        local I = Instance.new("ImageButton")
        I.Name = "Preview"
        I.Size = UDim2.fromOffset(12, 12)
        I.Position = UDim2.new(1, -22, 0, 10)
        I.BackgroundTransparency = 1
        I.Image = u("badscript/assets/new/colorpreview.png")
        I.ImageColor3 = Color3.fromHSV(at.Hue, 1, 1)
        I.Parent = aw
        local J = Instance.new("TextBox")
        J.Name = "Box"
        J.Size = UDim2.fromOffset(60, 15)
        J.Position = UDim2.new(1, -69, 0, 9)
        J.BackgroundTransparency = 1
        J.Visible = false
        J.Text = ""
        J.TextXAlignment = Enum.TextXAlignment.Right
        J.TextColor3 = o.MutedText
        J.TextSize = 11
        J.FontFace = o.Font
        J.ClearTextOnFocus = true
        J.Parent = aw
        local K = Instance.new("TextButton")
        K.Name = "Expand"
        K.Size = UDim2.fromOffset(17, 13)
        K.Position = UDim2.new(0, E(ax.Text, ax.TextSize, ax.Font).X + 11, 0, 7)
        K.BackgroundTransparency = 1
        K.Text = ""
        K.Parent = aw
        local L = Instance.new("ImageLabel")
        L.Name = "Expand"
        L.Size = UDim2.fromOffset(9, 5)
        L.Position = UDim2.fromOffset(4, 4)
        L.BackgroundTransparency = 1
        L.Image = u("badscript/assets/new/expandicon.png")
        L.ImageColor3 = m.Dark(o.Text, 0.43)
        L.Parent = K
        local M = Instance.new("TextButton")
        M.Name = "Rainbow"
        M.Size = UDim2.fromOffset(12, 12)
        M.Position = UDim2.new(1, -42, 0, 10)
        M.BackgroundTransparency = 1
        M.Text = ""
        M.Parent = aw
        local N = Instance.new("ImageLabel")
        N.Size = UDim2.fromOffset(12, 12)
        N.BackgroundTransparency = 1
        N.Image = u("badscript/assets/new/rainbow_1.png")
        N.ImageColor3 = m.Light(o.Main, 0.37)
        N.Parent = M
        local O = N:Clone()
        O.Image = u("badscript/assets/new/rainbow_2.png")
        O.Parent = M
        local P = N:Clone()
        P.Image = u("badscript/assets/new/rainbow_3.png")
        P.Parent = M
        local Q = N:Clone()
        Q.Image = u("badscript/assets/new/rainbow_4.png")
        Q.Parent = M
        local R = Instance.new("ImageLabel")
        R.Name = "Knob"
        R.Size = UDim2.fromOffset(26, 12)
        R.Position = UDim2.fromOffset(av[4] - 3, -5)
        R.BackgroundTransparency = 1
        R.Image = u("badscript/assets/new/guislider.png")
        R.ImageColor3 = au[4]
        R.Parent = ay
        as.Function = as.Function or function() end
        local S = {}
        for T = 0, 1, 0.1 do
            table.insert(S, ColorSequenceKeypoint.new(T, Color3.fromHSV(T, 1, 1)))
        end
        local T = createSlider("Custom color", ColorSequence.new(S))
        local U = createSlider(
            "Saturation",
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, at.Value)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(at.Hue, 1, at.Value)),
            })
        )
        local V = createSlider(
            "Vibrance",
            ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(at.Hue, at.Sat, 1)),
            })
        )
        local W = u("badscript/assets/new/guislider.png")
        local X = u("badscript/assets/new/guisliderrain.png")
        local Y

        function at.Save(Z, _)
            _[as.Name] = {
                Hue = Z.Hue,
                Sat = Z.Sat,
                Value = Z.Value,
                Notch = Z.Notch,
                CustomColor = Z.CustomColor,
                Rainbow = Z.Rainbow,
            }
        end

        function at.Load(Z, _)
            if _.Rainbow then
                Z:Toggle()
            end
            if Z.Rainbow or _.CustomColor then
                Z:SetValue(_.Hue, _.Sat, _.Value)
            else
                Z:SetValue(nil, nil, nil, _.Notch)
            end
        end

        function at.SetValue(Z, _, aA, aB, aC, aD)
            if type(aC) ~= "number" or aC % 1 ~= 0 or aC < 1 or aC > #au then
                aC = nil
            end
            if aC then
                if Z.Rainbow then
                    Z:Toggle()
                end
                Z.CustomColor = false
                _, aA, aB = au[aC]:ToHSV()
            else
                Z.CustomColor = true
            end

            if _ ~= nil then
                Z.Hue = math.clamp(tonumber(_) or Z.Hue, 0, 1)
            end
            if aA ~= nil then
                Z.Sat = math.clamp(tonumber(aA) or Z.Sat, 0, 1)
            end
            if aB ~= nil then
                Z.Value = math.clamp(tonumber(aB) or Z.Value, 0, 1)
            end
            Z.Notch = aC
            I.ImageColor3 = Color3.fromHSV(Z.Hue, Z.Sat, Z.Value)
            U.Slider.UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, Z.Value)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(Z.Hue, 1, Z.Value)),
            })
            V.Slider.UIGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(Z.Hue, Z.Sat, 1)),
            })

            if Z.Rainbow or Z.CustomColor then
                R.Image = X
                R.ImageColor3 = Color3.new(1, 1, 1)
                n:Tween(R, o.Tween, {
                    Position = UDim2.fromOffset(av[4] - 3, -5),
                })
            else
                R.Image = W
                R.ImageColor3 = Color3.fromHSV(Z.Hue, Z.Sat, Z.Value)
                n:Tween(R, o.Tween, {
                    Position = UDim2.fromOffset(av[aC or 4] - 3, -5),
                })
            end

            if Z.Rainbow then
                if _ then
                    T.Slider.Fill.Size = UDim2.fromScale(math.clamp(Z.Hue, 0, 1), 1)
                end
                if aA then
                    U.Slider.Fill.Size = UDim2.fromScale(math.clamp(Z.Sat, 0, 1), 1)
                end
                if aB then
                    V.Slider.Fill.Size = UDim2.fromScale(math.clamp(Z.Value, 0, 1), 1)
                end
            else
                if _ then
                    n:Tween(T.Slider.Fill, o.Tween, {
                        Size = UDim2.fromScale(math.clamp(Z.Hue, 0, 1), 1),
                    })
                end
                if aA then
                    n:Tween(U.Slider.Fill, o.Tween, {
                        Size = UDim2.fromScale(math.clamp(Z.Sat, 0, 1), 1),
                    })
                end
                if aB then
                    n:Tween(V.Slider.Fill, o.Tween, {
                        Size = UDim2.fromScale(math.clamp(Z.Value, 0, 1), 1),
                    })
                end
            end
            if not aD then
                as.Function(Z.Hue, Z.Sat, Z.Value)
            end
        end

        function at.ToColor(aA)
            return Color3.fromHSV(aA.Hue, aA.Sat, aA.Value)
        end

        function at.Toggle(aA)
            aA.Rainbow = not aA.Rainbow
            if Y then
                task.cancel(Y)
            end

            if aA.Rainbow then
                R.Image = X
                if not table.find(d.RainbowTable, aA) then
                    table.insert(d.RainbowTable, aA)
                end

                N.ImageColor3 = Color3.fromRGB(5, 127, 100)
                Y = task.delay(0.1, function()
                    O.ImageColor3 = Color3.fromRGB(228, 125, 43)
                    Y = task.delay(0.1, function()
                        P.ImageColor3 = Color3.fromRGB(225, 46, 52)
                        Y = nil
                    end)
                end)
            else
                aA:SetValue(nil, nil, nil, 4)
                R.Image = W
                local aB = table.find(d.RainbowTable, aA)
                if aB then
                    table.remove(d.RainbowTable, aB)
                end

                P.ImageColor3 = m.Light(o.Main, 0.37)
                Y = task.delay(0.1, function()
                    O.ImageColor3 = m.Light(o.Main, 0.37)
                    Y = task.delay(0.1, function()
                        N.ImageColor3 = m.Light(o.Main, 0.37)
                    end)
                end)
            end
        end

        K.MouseEnter:Connect(function()
            L.ImageColor3 = m.Dark(o.Text, 0.16)
        end)
        K.MouseLeave:Connect(function()
            L.ImageColor3 = m.Dark(o.Text, 0.43)
        end)
        K.Activated:Connect(function()
            T.Visible = not T.Visible
            U.Visible = T.Visible
            V.Visible = U.Visible
            L.Rotation = U.Visible and 180 or 0
        end)
        I.Activated:Connect(function()
            I.Visible = false
            J.Visible = true
            J:CaptureFocus()
            local aA = Color3.fromHSV(at.Hue, at.Sat, at.Value)
            J.Text = math.round(aA.R * 255) .. ", " .. math.round(aA.G * 255) .. ", " .. math.round(aA.B * 255)
        end)
        aw.InputBegan:Connect(function(aA)
            if
                (aA.UserInputType == Enum.UserInputType.MouseButton1 or aA.UserInputType == Enum.UserInputType.Touch)
                and (aA.Position.Y - aw.AbsolutePosition.Y) > (20 * A.Scale)
            then
                local aB = h.InputChanged:Connect(function(aB)
                    if
                        aB.UserInputType
                        == (
                            aA.UserInputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement
                            or Enum.UserInputType.Touch
                        )
                    then
                        at:SetValue(
                            nil,
                            nil,
                            nil,
                            math.clamp(math.round((aB.Position.X - ay.AbsolutePosition.X) / A.Scale / 27), 1, 7)
                        )
                    end
                end)

                local aC
                aC = aA.Changed:Connect(function()
                    if aA.UserInputState == Enum.UserInputState.End then
                        if aB then
                            aB:Disconnect()
                        end
                        if aC then
                            aC:Disconnect()
                        end
                    end
                end)
                at:SetValue(
                    nil,
                    nil,
                    nil,
                    math.clamp(math.round((aA.Position.X - ay.AbsolutePosition.X) / A.Scale / 27), 1, 7)
                )
            end
        end)
        M.Activated:Connect(function()
            at:Toggle()
        end)
        J.FocusLost:Connect(function(aA)
            I.Visible = true
            J.Visible = false
            if aA then
                local components = J.Text:split(",")
                local aC, Z = pcall(function()
                    if #components == 3 then
                        local red = tonumber(components[1])
                        local green = tonumber(components[2])
                        local blue = tonumber(components[3])
                        if not red or not green or not blue then
                            error("invalid RGB value")
                        end
                        return Color3.fromRGB(
                            math.clamp(red, 0, 255),
                            math.clamp(green, 0, 255),
                            math.clamp(blue, 0, 255)
                        )
                    end
                    local hex = J.Text:gsub("#", "")
                    if not hex:match("^[%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F][%da-fA-F]$") then
                        error("invalid hex value")
                    end
                    return Color3.fromHex(hex)
                end)

                if aC and Z then
                    if at.Rainbow then
                        at:Toggle()
                    end
                    at:SetValue(Z:ToHSV())
                end
            end
        end)

        aw.Destroying:Once(function()
            local index = table.find(d.RainbowTable, at)
            if index then
                table.remove(d.RainbowTable, index)
            end
        end)
        at.Object = aw
        ab.Options[as.Name] = at

        return at
    end

    local function restoreSettingsRows()
        -- Restore only the landing container. Individual controls retain their
        -- own intentional Visible state (for example conditional color rows).
        ap.Visible = true
        ap.Active = true
        setScrollEnabledIfSupported(ap, true)
        pcall(function()
            ap.Interactable = true
        end)
    end

    local function setSettingsVisible(visible)
    if d._OpenDropdown then
        pcall(d._OpenDropdown, true)
        d._OpenDropdown = nil
    end

    if d._OpenModuleOptions then
        pcall(d._OpenModuleOptions, true)
        d._OpenModuleOptions = nil
    end

    if d._OpenLegitOptions then
        pcall(d._OpenLegitOptions, true)
        d._OpenLegitOptions = nil
    end

    if d.HideTooltip then
        d.HideTooltip(true)
    end

    if not visible and d._OpenSettingsPane then
        local closer =
            d._SettingsPaneClosers
            and d._SettingsPaneClosers[d._OpenSettingsPane]

        if type(closer) == "function" then
            closer(false, true)
        else
            d._OpenSettingsPane.Visible = false
            d._OpenSettingsPane.Active = false
            d._OpenSettingsPane = nil
            if d._SettingsPageState then
                d._SettingsPageState.Current = nil
                d._SettingsPageState.Generation += 1
            end
        end
    end

    if visible then
        restoreSettingsRows()
    end

    ak.Visible = visible
    playerCard.Visible = not visible
    onlineDot.Visible = not visible
    af.Visible = not visible
    aj.Visible = not visible
    if aj and aj.Parent then
        aj.Visible = not visible
    end

    if visible then
        restoreSettingsRows()
    end
end

ak:GetPropertyChangedSignal("Visible"):Connect(function()
    local mainVisible = not ak.Visible
    playerCard.Visible = mainVisible
    onlineDot.Visible = mainVisible
    af.Visible = mainVisible
    aj.Visible = mainVisible
end)

    an.MouseEnter:Connect(function()
        an.ImageColor3 = o.Text
    end)
    an.MouseLeave:Connect(function()
        an.ImageColor3 = m.Light(o.Main, 0.37)
    end)
    an.Activated:Connect(function()
        setSettingsVisible(false)
    end)
    am.Activated:Connect(function()
        setSettingsVisible(false)
    end)
    aj.MouseEnter:Connect(function()
        local accent =
            Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )

        n:Tween(aj, o.TweenFast, {
            BackgroundColor3 = o.SurfaceHover,
        })
        n:Tween(discordStroke, o.TweenFast, {
            Color = accent,
            Transparency = 0.28,
        })
        n:Tween(discordLabel, o.TweenFast, {
            TextColor3 = accent:Lerp(o.TextStrong, 0.24),
        })
        n:Tween(discordChevron, o.TweenFast, {
            ImageColor3 = accent,
            Position = UDim2.new(1, -12, 0.5, 0),
        })
    end)

    aj.MouseLeave:Connect(function()
        n:Tween(aj, o.TweenFast, {
            BackgroundColor3 = o.MainSoft,
        })
        n:Tween(discordStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.5,
        })
        n:Tween(discordLabel, o.TweenFast, {
            TextColor3 = o.TextStrong,
        })
        n:Tween(discordChevron, o.TweenFast, {
            ImageColor3 = o.FaintText,
            Position = UDim2.new(1, -15, 0.5, 0),
        })
    end)

    aj.Activated:Connect(function()
        local invite = "https://discord.gg/K2TQx4vyR7"
        local copied = false

        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard(invite)
                copied = true
            elseif type(toclipboard) == "function" then
                toclipboard(invite)
                copied = true
            end
        end)

        local previousText = discordLabel.Text
        discordLabel.Text = copied and "INVITE COPIED" or "DISCORD INVITE"
        task.delay(1.1, function()
            if discordLabel.Parent then
                discordLabel.Text = previousText
            end
        end)

        if d.CreateNotification then
            d:CreateNotification(
                "BadWars",
                copied
                    and "Discord invite copied to clipboard."
                    or invite,
                5,
                copied and "success" or "info"
            )
        end
    end)
    ah.MouseEnter:Connect(function()
        ai.ImageColor3 = o.TextStrong
        n:Tween(ah, o.TweenFast, { BackgroundTransparency = 0.86, BackgroundColor3 = o.ElevatedHover })
        n:Tween(settingsStroke, o.TweenFast, {
            Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
            Transparency = 0.3,
        })
    end)
    ah.MouseLeave:Connect(function()
        ai.ImageColor3 = o.MutedText
        n:Tween(ah, o.TweenFast, { BackgroundTransparency = 1 })
        n:Tween(settingsStroke, o.TweenFast, {
            Color = o.Border,
            Transparency = 1,
        })
    end)
    ah.Activated:Connect(function()
        d.MainGuiSettingsOpenedEvent:Fire()
        setSettingsVisible(true)
    end)
    local refreshingMainWindowSize = false
    local mainWindowRefreshQueued = false
    local mainWindowRefreshPending = false
    local function refreshMainWindowSize()
        if refreshingMainWindowSize then
            mainWindowRefreshQueued = true
            return
        end
        refreshingMainWindowSize = true

        local ok, err = xpcall(function()
            if aa.ThreadFix then
                setthreadidentity(8)
            end

            local scale = math.max(A.Scale, 0.01)
            local contentHeight = math.max(
                0,
                ag.AbsoluteContentSize.Y / scale
            )
            local viewportHeight = math.max(
                180,
                (B.AbsoluteSize.Y / scale) - 148
            )
            local visibleHeight = math.min(
                contentHeight + 8,
                viewportHeight
            )

            local targetCanvasSize = UDim2.fromOffset(
                0,
                contentHeight + 8
            )
            if af.CanvasSize ~= targetCanvasSize then
                af.CanvasSize = targetCanvasSize
            end

            local targetScrollerSize = UDim2.fromOffset(
                UI_WINDOW_WIDTH,
                math.max(100, visibleHeight)
            )
            if af.Size ~= targetScrollerSize then
                af.Size = targetScrollerSize
            end

            local targetWindowSize = UDim2.fromOffset(
                UI_WINDOW_WIDTH,
                120 + math.max(100, visibleHeight)
            )
            if ac.Size ~= targetWindowSize then
                ac.Size = targetWindowSize
            end

            local maxCanvasY = math.max(
                0,
                af.AbsoluteCanvasSize.Y - af.AbsoluteWindowSize.Y
            )
            local targetCanvasPosition = Vector2.new(
                0,
                math.clamp(af.CanvasPosition.Y, 0, maxCanvasY)
            )
            if af.CanvasPosition ~= targetCanvasPosition then
                af.CanvasPosition = targetCanvasPosition
            end

            for _, buttonApi in ab.Buttons do
                if buttonApi.Icon then
                    local targetText =
                        string.rep(" ", 36 * A.Scale)
                        .. buttonApi.Name
                    if buttonApi.Object.Text ~= targetText then
                        buttonApi.Object.Text = targetText
                    end
                end
            end
        end, function(refreshErr)
            if debug and type(debug.traceback) == "function" then
                return debug.traceback(tostring(refreshErr), 2)
            end
            return tostring(refreshErr)
        end)

        refreshingMainWindowSize = false

        if not ok then
            a:report({
                type = "gui-main-window-refresh",
                err = err,
                args = { tostring(ab and ab.Type or "Main") },
                notifyBlacklisted = true,
            })
        end

        if mainWindowRefreshQueued then
            mainWindowRefreshQueued = false
            task.delay(0.03, refreshMainWindowSize)
        end
    end

    local function queueMainWindowSizeRefresh()
        mainWindowRefreshQueued = true
        if mainWindowRefreshPending then
            return
        end
        mainWindowRefreshPending = true
        task.delay(0.03, function()
            mainWindowRefreshPending = false
            mainWindowRefreshQueued = false
            refreshMainWindowSize()
        end)
    end

    connectDeferredPropertyChanged(ag, "AbsoluteContentSize", queueMainWindowSizeRefresh)
    B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        queueMainWindowSizeRefresh()
    end)
    A:GetPropertyChangedSignal("Scale"):Connect(function()
        queueMainWindowSizeRefresh()
    end)
    task.defer(queueMainWindowSizeRefresh)

    ab.MainGui = af

    aa.Categories.Main = ab

    return ab
end

function d.CreateCategory(aa, ab)
    local previousCategory = aa.Categories[ab.Name]
    if previousCategory and previousCategory.Object then
        pcall(function()
            previousCategory.Object:Destroy()
        end)
    end

    local ac = {
        Type = "Category",
        OriginalCategory = true,
        Expanded = false,
    }

    local ad = Instance.new("TextButton")
    ad.Name = ab.Name .. "Category"
    ad.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, UI_HEADER_HEIGHT)
    ad.Position = UDim2.fromOffset(250, 60)
    ad.BackgroundColor3 = o.Main
    ad.BackgroundTransparency = 0.005
    ad.AutoButtonColor = false
    ad.Visible = false
    ad.Text = ""
    ad.ClipsDescendants = true
    ad.Parent = v
    addShadow(ad)
    addCorner(ad, o.RadiusLarge)
    local categoryStroke = addStroke(ad, o.BorderStrong, 0.44, 1, "CategoryStroke")
    addSurfaceGradient(ad)
    local categoryAccent = addAccentLine(ad, 2)
    addV9Chrome(ad)
    local categoryScale = addScale(ad)
    local categorySweep = addV9Sweep(ad)

    local headerSurface = Instance.new("Frame")
    headerSurface.Name = "HeaderSurface"
    headerSurface.Size = UDim2.new(1, 0, 0, UI_HEADER_HEIGHT)
    headerSurface.Position = UDim2.fromOffset(0, 0)
    headerSurface.BackgroundColor3 = o.MainSoft
    headerSurface.BackgroundTransparency = 0.015
    headerSurface.BorderSizePixel = 0
    headerSurface.ZIndex = ad.ZIndex + 10
    headerSurface.Parent = ad
    addCorner(headerSurface, o.RadiusLarge)

    local ae = Instance.new("ImageLabel")
    ae.Name = "Icon"
    ae.Size = ab.Size
    ae.Position = UDim2.fromOffset(16, (ae.Size.X.Offset > 20 and 17 or 16))
    ae.BackgroundTransparency = 1
    ae.Image = ab.Icon
    ae.ImageColor3 = o.MutedText
    ae.ZIndex = headerSurface.ZIndex + 2
    ae.Parent = headerSurface
    local af = Instance.new("TextLabel")
    af.Name = "Title"
    af.Size = UDim2.new(1, -(ab.Size.X.Offset > 18 and 44 or 37), 1, 0)
    af.Position = UDim2.fromOffset(math.abs(af.Size.X.Offset) + 2, 0)
    af.BackgroundTransparency = 1
    af.Text = ab.Name
    af.TextXAlignment = Enum.TextXAlignment.Left
    af.TextColor3 = o.MutedText
    af.TextSize = 14
    af.FontFace = o.FontSemiBold
    af.ZIndex = headerSurface.ZIndex + 2
    af.Parent = headerSurface

    local categorySub = Instance.new("TextLabel")
    categorySub.Name = "Subtitle"
    categorySub.Size = UDim2.new(1, -56, 0, 11)
    categorySub.Position = UDim2.fromOffset(
        math.abs(af.Size.X.Offset) + 2,
        27
    )
    categorySub.BackgroundTransparency = 1
    categorySub.Text = "MODULES"
    categorySub.TextColor3 = o.FaintText
    categorySub.TextSize = 8
    categorySub.TextXAlignment = Enum.TextXAlignment.Left
    categorySub.FontFace = o.FontBold
    categorySub.Visible = true
    categorySub.ZIndex = headerSurface.ZIndex + 2
    categorySub.Parent = headerSurface

    local ag = Instance.new("TextButton")
    ag.Name = "Arrow"

    ag.Size = UDim2.new(1, 0, 0, UI_HEADER_HEIGHT)
    ag.Position = UDim2.fromOffset(0, 0)
    ag.BackgroundTransparency = 1
    ag.Text = ""
    ag.ZIndex = headerSurface.ZIndex + 3
    ag.Parent = headerSurface
    makeDraggable2(ag, ad)
    local ah = setupGuiMoveCheck(ag, ad)
    local ai = Instance.new("ImageLabel")
    ai.Name = "Arrow"
    ai.Size = UDim2.fromOffset(9, 4)

    ai.Position = UDim2.new(1, -24, 0, 21)
    ai.BackgroundTransparency = 1
    ai.Image = u("badscript/assets/new/expandup.png")
    ai.ImageColor3 = Color3.fromRGB(140, 140, 140)
    ai.Rotation = 180
    ai.ZIndex = ag.ZIndex + 1
    ai.Parent = ag
    local aj = Instance.new("ScrollingFrame")
    aj.Name = "Children"
    aj.Size = UDim2.new(1, 0, 1, -UI_HEADER_HEIGHT)
    aj.Position = UDim2.fromOffset(0, UI_HEADER_HEIGHT)
    aj.BackgroundTransparency = 1
    aj.BorderSizePixel = 0
    aj.Visible = false

    aj.ScrollBarThickness = d.isMobile and 7 or 3
    aj.ScrollBarImageColor3 = o.BorderStrong
    aj.ScrollBarImageTransparency = d.isMobile and 0.28 or 0.58
    aj.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    aj.ScrollingDirection = Enum.ScrollingDirection.Y
    aj.AutomaticCanvasSize = Enum.AutomaticSize.None
    aj.ElasticBehavior = Enum.ElasticBehavior.Never
    aj.CanvasSize = UDim2.new()
    aj.ClipsDescendants = true
    aj.ZIndex = ad.ZIndex + 1
    aj.Parent = ad
    local ak = Instance.new("Frame")
    ak.Name = "Divider"
    ak.Size = UDim2.new(1, -20, 0, 1)
    ak.Position = UDim2.fromOffset(10, UI_HEADER_HEIGHT)
    ak.BackgroundColor3 = Color3.new(1, 1, 1)
    ak.BackgroundTransparency = 0.928
    ak.BorderSizePixel = 0
    ak.Visible = false
    ak.Parent = ad
    local al = Instance.new("UIListLayout")
    al.SortOrder = Enum.SortOrder.LayoutOrder
    al.HorizontalAlignment = Enum.HorizontalAlignment.Center
    al.Padding = UDim.new(0, 5)
    al.Parent = aj

    local function updateCategoryVisual(hovered, instant)
        local accent = Color3.fromHSV(
            d.GUIColor.Hue,
            d.GUIColor.Sat,
            d.GUIColor.Value
        )
        local active = ac.Expanded or hovered
        local textAccent = accent:Lerp(o.TextStrong, 0.42)
        local iconColor = ac.Expanded
                and accent:Lerp(o.TextStrong, 0.16)
            or (hovered and textAccent or o.MutedText)
        local titleColor = ac.Expanded
                and o.TextStrong
            or (hovered and textAccent or o.MutedText)
        local headerColor = hovered
                and o.SurfaceHover
            or (ac.Expanded and o.Elevated or o.MainSoft)
        local strokeColor = active
                and accent:Lerp(o.BorderStrong, 0.68)
            or o.Border
        local strokeTransparency = hovered
                and 0.46
            or (ac.Expanded and 0.58 or 0.8)
        local accentTransparency = active and 0.08 or 0.58

        if instant then
            ae.ImageColor3 = iconColor
            af.TextColor3 = titleColor
            headerSurface.BackgroundColor3 = headerColor
            categoryStroke.Color = strokeColor
            categoryStroke.Transparency = strokeTransparency
            categoryAccent.BackgroundTransparency = accentTransparency
            return
        end

        n:Tween(ae, o.TweenFast, { ImageColor3 = iconColor })
        n:Tween(af, o.TweenFast, { TextColor3 = titleColor })
        n:Tween(headerSurface, o.TweenFast, {
            BackgroundColor3 = headerColor,
            BackgroundTransparency = hovered and 0 or 0.03,
        })
        n:Tween(categoryStroke, o.TweenFast, {
            Color = strokeColor,
            Transparency = strokeTransparency,
        })
        n:Tween(categoryAccent, o.TweenFast, {
            BackgroundTransparency = accentTransparency,
        })
    end

    function ac.CreateModule(am, an)
        an.Function = an.Function or function() end
        an.Function = a:wrap(an.Function, {
            type = "module",
            name = an.Name,
            category = ab.Name,
        })
        d:Remove(an.Name)
        local ao = {
            Enabled = false,
            Options = {},
            Bind = {},
            NoSave = an.NoSave,
            Index = getTableSize(d.Modules),
            ExtraText = an.ExtraText,
            Name = an.Name,
            Category = ab.Name,
            SavingID = an.SavingID,
            Toggled = c(`{tostring(an.Name)}_{tostring(ac.Name)}_{tostring(an.SavingID)}_{tostring(an.ExtraText)}`),
        }
        an.Tooltip = an.Tooltip or an.Name

        local ap = an.DisplayName or an.Name
        local aq = false
        local ar = Instance.new("TextButton")
        ar.Name = an.Name
        ar.Size = UDim2.new(1, -14, 0, UI_MODULE_ROW_HEIGHT)
        ar.BackgroundColor3 = o.Surface
        ar.BackgroundTransparency = 0.08
        ar.BorderSizePixel = 0
        ar.AutoButtonColor = false
        ar.ClipsDescendants = true
        ar.Text = "     " .. ap
        ar.TextXAlignment = Enum.TextXAlignment.Left
        ar.TextColor3 = o.MutedText
        ar.TextSize = d.isMobile and 15 or 14
        ar.FontFace = o.FontSemiBold
        ar.Parent = aj
        addCorner(ar, o.Radius)
        local moduleStroke = addStroke(ar, o.Border, 0.76, 1, "ModuleStroke")
        local moduleScale = addScale(ar)
        local moduleSweep = addV9Sweep(ar)

        local moduleKeyline = Instance.new("Frame")
        moduleKeyline.Name = "ModuleKeyline"
        moduleKeyline.Size = UDim2.new(1, -20, 0, 1)
        moduleKeyline.Position = UDim2.new(0, 10, 1, -1)
        moduleKeyline.BackgroundColor3 = o.Border
        moduleKeyline.BackgroundTransparency = 1
        moduleKeyline.BorderSizePixel = 0
        moduleKeyline.ZIndex = ar.ZIndex + 1
        moduleKeyline.Parent = ar

        local activeRail = Instance.new("Frame")
        activeRail.Name = "ActiveRail"
        activeRail.Size = UDim2.fromOffset(3, 22)
        activeRail.AnchorPoint = Vector2.new(0, 0.5)
        activeRail.Position = UDim2.new(0, 1, 0.5, 0)
        activeRail.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        activeRail.BorderSizePixel = 0
        activeRail.Visible = false
        activeRail.ZIndex = ar.ZIndex + 1
        activeRail.Parent = ar
        addCorner(activeRail, UDim.new(1, 0))

        local activeHalo = Instance.new("Frame")
        activeHalo.Name = "ActiveHalo"
        activeHalo.Size = UDim2.fromOffset(0, 0)
        activeHalo.AnchorPoint = Vector2.new(0, 0.5)
        activeHalo.Position = activeRail.Position
        activeHalo.BackgroundTransparency = 1
        activeHalo.Visible = false
        activeHalo.ZIndex = ar.ZIndex + 1
        activeHalo.Parent = ar
        addCorner(activeHalo, UDim.new(1, 0))
        local activeHaloStroke = addStroke(
            activeHalo,
            activeRail.BackgroundColor3,
            0.54,
            1,
            "ActiveHaloStroke"
        )

        activeRail:GetPropertyChangedSignal("Visible"):Connect(function()
            activeHalo.Visible = activeRail.Visible
        end)

        connectguicolorchange(function(hue, saturation, value)
            local accent = Color3.fromHSV(hue, saturation, value)
            activeRail.BackgroundColor3 = accent
            activeHaloStroke.Color = accent
            if ao.Enabled then
                moduleStroke.Color = o.BorderStrong
            end
        end)
        local as = Instance.new("UIGradient")
        as.Rotation = 90
        as.Enabled = false
        as.Parent = ar
        local at = Instance.new("CanvasGroup")
        local au = Instance.new("TextButton")
        addTooltip(ar, an.Tooltip)
        addTooltip(au, "Click to bind")
        au.Name = "Bind"

        au.Size = UDim2.fromOffset(20, 21)
        au.Position = UDim2.new(1, -36, 0, 9)
        if d.isMobile then
            au.Visible = false
        end
        au.AnchorPoint = Vector2.new(1, 0)
        au.BackgroundColor3 = Color3.new(1, 1, 1)
        au.BackgroundTransparency = 0.92
        au.BorderSizePixel = 0
        au.AutoButtonColor = false
        au.Visible = false
        au.Text = ""
        addCorner(au, UDim.new(0, 4))
        local av = Instance.new("ImageLabel")
        av.Name = "Icon"
        av.Size = UDim2.fromOffset(12, 12)
        av.Position = UDim2.new(0.5, -6, 0, 5)
        av.BackgroundTransparency = 1
        av.Image = u("badscript/assets/new/bind.png")
        av.ImageColor3 = m.Dark(o.Text, 0.43)
        av.Parent = au
        local aw = Instance.new("TextLabel")
        aw.Size = UDim2.fromScale(1, 1)
        aw.Position = UDim2.fromOffset(0, 1)
        aw.BackgroundTransparency = 1
        aw.Visible = false
        aw.Text = ""
        aw.TextColor3 = m.Dark(o.Text, 0.43)
        aw.TextSize = 12
        aw.FontFace = o.Font
        aw.Parent = au
        local ax = Instance.new("ImageLabel")
        ax.Name = "Cover"
        ax.Size = UDim2.fromOffset(154, 40)
        ax.BackgroundTransparency = 1
        ax.Visible = false
        ax.Image = u("badscript/assets/new/bindbkg.png")
        ax.ScaleType = Enum.ScaleType.Slice
        ax.SliceCenter = Rect.new(0, 0, 141, 40)
        ax.Parent = ar
        local ay = Instance.new("TextLabel")
        ay.Name = "Text"
        ay.Size = UDim2.new(1, -10, 1, -3)
        ay.BackgroundTransparency = 1
        ay.Text = "PRESS A KEY TO BIND"
        ay.TextColor3 = o.Text
        ay.TextSize = 11
        ay.FontFace = o.Font
        ay.Parent = ax
        au.Parent = ar

        local az = au:Clone()
        az.Parent = ar
        az.Name = "Star"
        az.Icon.Image = u("badscript/assets/new/star.png")
        az.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        az.Visible = false
        az.BackgroundTransparency = 0
        az.Position = UDim2.new(1, -70, 0, 9)
        addTooltip(az, "Click to favorite")

        local aA = Instance.new("UIStroke")
        aA.Name = "FavoriteStroke"
        aA.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        aA.Transparency = 1
        aA.Thickness = 0
        aA.Enabled = false
        aA.Parent = ar
        local aB = aA

        connectvisibilitychange(function()
            aB.Enabled = false
        end)
        ao.InternalAddOnChange = Instance.new("BindableEvent")
        ao.InternalAddOnChange.Event:Connect(function()
            az.Position = au.Visible and UDim2.new(1, -70, 0, 9) or UDim2.new(1, -36, 0, 9)
        end)
        au:GetPropertyChangedSignal("Visible"):Connect(function()
            ao.InternalAddOnChange:Fire()
        end)

        function d.SortAllModules()
            local grouped = {}

            for _, module in pairs(d.Modules or {}) do
                if type(module) == "table" and module.Object and module.Object.Parent then
                    local category = tostring(module.Category or "Other")
                    grouped[category] = grouped[category] or {}
                    table.insert(grouped[category], module)
                end
            end

            for _, modules in pairs(grouped) do
                table.sort(modules, function(left, right)
                    local leftFavorite = left.StarActive == true
                    local rightFavorite = right.StarActive == true
                    if leftFavorite ~= rightFavorite then
                        return leftFavorite
                    end

                    local leftName = string.lower(tostring(left.Name or ""))
                    local rightName = string.lower(tostring(right.Name or ""))
                    if leftName == rightName then
                        return tostring(left.Name or "") < tostring(right.Name or "")
                    end
                    return leftName < rightName
                end)

                for index, module in ipairs(modules) do
                    module.Index = index
                    if module.Object then
                        module.Object.LayoutOrder = index * 2
                    end
                    if module.Children then
                        module.Children.LayoutOrder = (index * 2) + 1
                    end
                end
            end

            local legitModules = {}
            for _, module in pairs(d.Legit and d.Legit.Modules or {}) do
                if type(module) == "table" and module.Object and module.Object.Parent then
                    table.insert(legitModules, module)
                end
            end
            table.sort(legitModules, function(left, right)
                return string.lower(tostring(left.Name or "")) < string.lower(tostring(right.Name or ""))
            end)
            for index, module in ipairs(legitModules) do
                module.Object.LayoutOrder = index
            end
        end

        local function updateModuleSorting()
            d:SortAllModules()
        end

        for aC, I in { az, au } do
            I:GetPropertyChangedSignal("Visible"):Connect(function()
                if I.Visible and an.Premium then
                    I.Visible = false
                end
            end)
        end

        ao.StarActive = false
        function ao.ToggleStar(aC, I)
            if an.Premium then
                ao.StarActive = false
            else
                ao.StarActive = not ao.StarActive
            end
            az.BackgroundColor3 = ao.StarActive and Color3.fromRGB(255, 255, 127) or Color3.fromRGB(255, 255, 255)
            aB.Enabled = false
            az.Visible = ao.StarActive or aq or at.Visible
            if not I then
                if d.FavoriteNotifications ~= nil and d.FavoriteNotifications.Enabled then
                    d:CreateNotification(
                        "Module Favorite",
                        tostring(an.Name)
                            .. "<font color='#FFFFFF'> has been </font>"
                            .. (ao.StarActive and "<font color='#FAFF5A'>Favorited</font>" or "<font color='#FF5A5A'>Unfaved</font>")
                            .. "<font color='#FFFFFF'>!</font>",
                        0.75
                    )
                end
            end
            ao.InternalAddOnChange:Fire()
            updateModuleSorting()
        end
        if an.Star and not an.Premium then
            ao:ToggleStar(true)
        end

        local aC = Instance.new("TextButton")
        aC.Name = "Dots"

        aC.Size = d.isMobile and UDim2.fromOffset(44, 40) or UDim2.fromOffset(25, 40)
        aC.Position = d.isMobile and UDim2.new(1, -44, 0, 0) or UDim2.new(1, -25, 0, 0)
        aC.BackgroundColor3 = o.Elevated
        aC.BackgroundTransparency = 1
        aC.BorderSizePixel = 0
        aC.Text = ""
        aC.Parent = ar
        addCorner(aC, o.RadiusSmall)
        local I = Instance.new("ImageLabel")
        I.Name = "Dots"
        I.Size = UDim2.fromOffset(3, 16)

        I.Position = d.isMobile and UDim2.fromOffset(20, 12) or UDim2.fromOffset(4, 12)
        I.BackgroundTransparency = 1
        I.Image = u("badscript/assets/new/dots.png")
        I.ImageColor3 = m.Light(o.Main, 0.37)
        I.Parent = aC
        at.Name = an.Name .. "Children"
        at.Size = UDim2.new(1, -12, 0, 0)
        at.BackgroundColor3 = o.MainSoft
        at.BorderSizePixel = 0
        at.Visible = false
        at.GroupTransparency = 1
        at.Parent = aj
        addCorner(at, o.Radius)
        local optionsStroke = addStroke(
            at,
            o.Border,
            1,
            1,
            "OptionsStroke"
        )
        ao.Children = at
        local J = Instance.new("UIListLayout")
        J.SortOrder = Enum.SortOrder.LayoutOrder
        J.HorizontalAlignment = Enum.HorizontalAlignment.Center
        J.Padding = UDim.new(0, 1)
        J.Parent = at
        local K = Instance.new("Frame")
        K.Name = "Divider"
        K.Size = UDim2.new(1, 0, 0, 1)
        K.Position = UDim2.new(0, 0, 1, -1)
        K.BackgroundColor3 = o.BorderStrong
        K.BackgroundTransparency = 0.86
        K.BorderSizePixel = 0
        K.Visible = false
        K.Parent = ar
        an.Function = an.Function or function() end
        addMaid(ao)

        local L
        local M
        local optionsOpen = false
        local optionsAnimationId = 0

        ao.OptionsVisibilityChanged =
            a.createCustomSignal(`OPTIONS_VISIBILITY_CHANGE_{tostring(an.Name)}_{tostring(ab.Name)}`)

        local closeOptions
        local lastOptionsToggle = 0
        local optionsTransition = TweenInfo.new(
            0.13,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )

        local function openOptions()
            if optionsOpen then
                return
            end

            if d.HideTooltip then
                d.HideTooltip(true)
            end

            if d._OpenDropdown then
                pcall(d._OpenDropdown, true)
                d._OpenDropdown = nil
            end

            if
                d._OpenModuleOptions
                and d._OpenModuleOptions ~= closeOptions
            then
                pcall(d._OpenModuleOptions, true)
            end

            d._OpenModuleOptions = closeOptions
            optionsAnimationId += 1
            local animationId = optionsAnimationId
            optionsOpen = true

            if L then
                L:Cancel()
                L = nil
            end
            if M then
                M:Cancel()
                M = nil
            end

            local preservedCanvasPosition =
                aj.CanvasPosition

            at.Visible = true
            at.GroupTransparency = 1
            at.Size = UDim2.new(1, -12, 0, 0)

            task.defer(function()
                if aj and aj.Parent then
                    aj.CanvasPosition =
                        preservedCanvasPosition
                end
            end)
            optionsStroke.Transparency = 1
            ao.OptionsVisibilityChanged:Fire(true)

            local targetHeight = math.max(
                J.AbsoluteContentSize.Y / A.Scale,
                0
            )

            L = n:Tween(at, optionsTransition, {
                Size = UDim2.new(1, -12, 0, targetHeight),
                GroupTransparency = 0,
            })
            n:Tween(optionsStroke, optionsTransition, {
                Transparency = 0.92,
            })

            if L then
                L.Completed:Once(function()
                    if animationId == optionsAnimationId then
                        L = nil
                    end
                end)
            end
        end

        closeOptions = function(instant)
            if not optionsOpen and not at.Visible then
                if d._OpenModuleOptions == closeOptions then
                    d._OpenModuleOptions = nil
                end
                return
            end

            optionsAnimationId += 1
            local animationId = optionsAnimationId
            optionsOpen = false

            if d._OpenModuleOptions == closeOptions then
                d._OpenModuleOptions = nil
            end

            if L then
                L:Cancel()
                L = nil
            end
            if M then
                M:Cancel()
                M = nil
            end

            local function finishClose()
                if
                    animationId == optionsAnimationId
                    and not optionsOpen
                then
                    at.Visible = false
                    at.GroupTransparency = 1
                    at.Size = UDim2.new(1, -12, 0, 0)
                    optionsStroke.Transparency = 1
                    ao.OptionsVisibilityChanged:Fire(false)
                    M = nil
                end
            end

            if instant or not d.Loaded then
                finishClose()
                return
            end

            M = n:Tween(at, optionsTransition, {
                Size = UDim2.new(1, -12, 0, 0),
                GroupTransparency = 1,
            })
            n:Tween(optionsStroke, optionsTransition, {
                Transparency = 1,
            })

            if M then
                M.Completed:Once(function(playbackState)
                    if playbackState == Enum.PlaybackState.Completed then
                        finishClose()
                    end
                end)
            else
                finishClose()
            end
        end

        local function toggleOptions()
            local now = os.clock()
            if now - lastOptionsToggle < 0.06 then
                return
            end
            lastOptionsToggle = now

            if optionsOpen then
                closeOptions(false)
            else
                openOptions()
            end
        end

        function ao.SetBind(N, O, P, Q)
            if O.Mobile then
                createMobileButton(ao, Vector2.new(O.X, O.Y))
                return
            end

            N.Bind = table.clone(O)
            if P then
                ay.Text = #O <= 0 and "BIND REMOVED" or "BOUND TO"
                ax.Size = UDim2.fromOffset(E(ay.Text, ay.TextSize).X + 20, 40)
                task.delay(1, function()
                    ax.Visible = false
                end)
            end

            if #O <= 0 then
                aw.Visible = false
                av.Visible = true
                au.Size = UDim2.fromOffset(20, 21)
            else
                au.Visible = true
                aw.Visible = true
                av.Visible = false
                aw.Text = table.concat(O, " + "):upper()
                au.Size = UDim2.fromOffset(math.max(E(aw.Text, aw.TextSize, aw.Font).X + 10, 20), 21)
            end

            local R = ay.Text

            if R == "BOUND TO" then
                R = ([[Bound to (<b><font color="#ffffff">%s</font></b>)]]):format(tostring(aw.Text))
            elseif R == "BIND REMOVED" then
                R = "Bind Removed"
            else
                R = nil
            end

            if R ~= nil and an.Name ~= nil then
                d:CreateNotification(an.Name, R, 1.5, "info")
            end
            if #O > 0 and not Q then
                d:CheckBounds(aw.Text, ao.Name)
            end
            ao.InternalAddOnChange:Fire()
        end

        function ao.Toggle(N, O)
            if d.ThreadFix then
                setthreadidentity(8)
            end
            N.Enabled = not N.Enabled
            N.Toggled:Fire()

            if d.isMobile then
                pcall(function()
                    game:GetService("HapticService")
                        :SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0.3)
                    task.delay(0.06, function()
                        pcall(game.GetService, game, "HapticService")
                        game:GetService("HapticService")
                            :SetMotor(Enum.UserInputType.Gamepad1, Enum.VibrationMotor.Small, 0)
                    end)
                end)
            end
            K.Visible = true
            as.Enabled = false
            activeRail.Visible = N.Enabled

            local accent = Color3.fromHSV(
                d.GUIColor.Hue,
                d.GUIColor.Sat,
                d.GUIColor.Value
            )
            local enabledSurface = o.Elevated:Lerp(accent, 0.08)
            local enabledText = accent:Lerp(o.TextStrong, 0.78)
            n:Tween(ar, o.TweenFast, {
                BackgroundColor3 = N.Enabled
                        and enabledSurface
                    or ((aq or optionsOpen) and o.SurfaceHover or o.Surface),
                BackgroundTransparency = N.Enabled
                        and 0.02
                    or ((aq or optionsOpen) and 0.04 or 0.16),
                TextColor3 = N.Enabled
                        and enabledText
                    or ((aq or optionsOpen) and o.Text or o.MutedText),
            })
            n:Tween(moduleStroke, o.TweenFast, {
                Color = N.Enabled
                        and accent:Lerp(o.BorderStrong, 0.45)
                    or o.Border,
                Transparency = N.Enabled
                        and 0.48
                    or ((aq or optionsOpen) and 0.68 or 0.88),
            })
            n:Spring(moduleScale, o.SpringInteractive, { Scale = 1 })

            activeHalo.BackgroundTransparency = N.Enabled and 0.72 or 1
            activeHaloStroke.Transparency = N.Enabled and 0.32 or 1
            I.ImageColor3 = N.Enabled and accent or o.FaintText
            av.ImageColor3 = N.Enabled and enabledText or o.FaintText
            aw.TextColor3 = N.Enabled and enabledText or o.FaintText
            if not N.Enabled then
                for P, Q in N.Connections do
                    if type(Q) == "function" then
                        pcall(Q)
                    else
                        pcall(function()
                            Q:Disconnect()
                        end)
                    end
                end
                table.clear(N.Connections)
            end
            if not O then
                d:UpdateTextGUI()
            end
            local desiredState = N.Enabled
            N._ToggleSerial = (N._ToggleSerial or 0) + 1
            local toggleSerial = N._ToggleSerial

            d._PendingModuleCallbacks += 1
            local callbackFinished = false

            local function finishCallback()
                if callbackFinished then
                    return
                end

                callbackFinished = true
                d._PendingModuleCallbacks = math.max(
                    0,
                    d._PendingModuleCallbacks - 1
                )
            end

            local callbackThread = coroutine.create(function()
                local trace = debug and debug.traceback
                    or function(err)
                        return tostring(err)
                    end

                local callbackOk, callbackError = xpcall(function()
                    an.Function(desiredState)
                end, trace)

                if not callbackOk then
                    a:report({
                        type = "module-toggle-callback",
                        err = callbackError,
                        args = { tostring(an.Name), desiredState },
                    })

                    if desiredState then
                        pcall(function()
                            d:CreateNotification(
                                "Module Error",
                                tostring(an.Name)
                                    .. " failed to enable.",
                                5,
                                "alert"
                            )
                        end)

                        task.defer(function()
                            if
                                N.Enabled == desiredState
                                and N._ToggleSerial == toggleSerial
                            then
                                N:Toggle(true)
                            end
                        end)
                    end
                end

                finishCallback()
            end)

            local started, startError =
                coroutine.resume(callbackThread)

            if not started then
                finishCallback()
                a:report({
                    type = "module-toggle-start",
                    err = startError,
                    args = { tostring(an.Name), desiredState },
                })

                if desiredState then
                    task.defer(function()
                        if
                            N.Enabled == desiredState
                            and N._ToggleSerial == toggleSerial
                        then
                            N:Toggle(true)
                        end
                    end)
                end
            end
        end

        for N, O in H do
            ao["Create" .. N] = function(P, Q)
                return O(Q, at, ao)
            end
            ao["Add" .. N] = ao["Create" .. N]
        end

        if not d.isMobile then
            au.MouseEnter:Connect(function()
                aw.Visible = false
                av.Visible = not aw.Visible
                av.Image = u("badscript/assets/new/edit.png")
                if not ao.Enabled then
                    av.ImageColor3 = m.Dark(o.Text, 0.16)
                end
            end)
            au.MouseLeave:Connect(function()
                aw.Visible = #ao.Bind > 0
                av.Visible = not aw.Visible
                av.Image = u("badscript/assets/new/bind.png")
                if not ao.Enabled then
                    av.ImageColor3 = m.Dark(o.Text, 0.43)
                end
            end)
        end
        au.Activated:Connect(function()
            ay.Text = "PRESS A KEY TO BIND"
            ax.Size = UDim2.fromOffset(E(ay.Text, ay.TextSize).X + 20, 40)
            ax.Visible = true
            table.clear(d.HeldKeybinds)
            d.Binding = ao
        end)
        az.Activated:Connect(function()
            ao:ToggleStar()
        end)
        if not d.isMobile then
            aC.MouseEnter:Connect(function()
                n:Tween(aC, o.TweenFast, {
                    BackgroundTransparency = 0.35,
                })
                I.ImageColor3 = o.Text
            end)

            aC.MouseLeave:Connect(function()
                n:Tween(aC, o.TweenFast, {
                    BackgroundTransparency = 1,
                })
                I.ImageColor3 = ao.Enabled and o.Text or m.Light(o.Main, 0.37)
            end)
        end
        aC.Activated:Connect(function()
            ao._SuppressPrimaryUntil = os.clock() + 0.12
            toggleOptions()
        end)

        if not d.isMobile then
            ar.MouseEnter:Connect(function()
                aq = true
                playV9Sweep(moduleSweep)
                local accent = Color3.fromHSV(
                    d.GUIColor.Hue,
                    d.GUIColor.Sat,
                    d.GUIColor.Value
                )
                if not ao.Enabled and not optionsOpen then
                    n:Tween(ar, o.TweenFast, {
                        BackgroundColor3 = o.SurfaceHover,
                        BackgroundTransparency = 0.03,
                        TextColor3 = o.Text,
                    })
                    n:Tween(moduleStroke, o.TweenFast, {
                        Color = o.BorderStrong,
                        Transparency = 0.6,
                    })
                elseif ao.Enabled then
                    n:Tween(ar, o.TweenFast, {
                        BackgroundTransparency = 0,
                    })
                    n:Tween(moduleStroke, o.TweenFast, {
                        Color = accent:Lerp(o.BorderStrong, 0.42),
                        Transparency = 0.4,
                    })
                end

                n:Spring(moduleScale, o.SpringInteractive, { Scale = 1.004 })
                au.Visible = #ao.Bind > 0 or aq or optionsOpen
                az.Visible = ao.StarActive or aq or optionsOpen
            end)

            ar.MouseLeave:Connect(function()
                aq = false
                local accent = Color3.fromHSV(
                    d.GUIColor.Hue,
                    d.GUIColor.Sat,
                    d.GUIColor.Value
                )
                if not ao.Enabled and not optionsOpen then
                    n:Tween(ar, o.TweenFast, {
                        BackgroundColor3 = o.Surface,
                        BackgroundTransparency = 0.16,
                        TextColor3 = o.MutedText,
                    })
                    n:Tween(moduleStroke, o.TweenFast, {
                        Color = o.Border,
                        Transparency = 0.88,
                    })
                elseif ao.Enabled then
                    n:Tween(ar, o.TweenFast, {
                        BackgroundTransparency = 0.02,
                    })
                    n:Tween(moduleStroke, o.TweenFast, {
                        Color = accent:Lerp(o.BorderStrong, 0.45),
                        Transparency = 0.48,
                    })
                end

                n:Spring(moduleScale, o.SpringInteractive, {
                    Scale = 1,
                })
                au.Visible = #ao.Bind > 0 or aq or optionsOpen
                az.Visible = ao.StarActive or aq or optionsOpen
            end)

            ar.MouseButton1Down:Connect(function()
                n:Spring(moduleScale, o.SpringInteractive, { Scale = 0.99 })
            end)

            ar.MouseButton1Up:Connect(function()
                n:Spring(moduleScale, o.SpringInteractive, {
                    Scale = aq and 1.004 or 1,
                })
            end)
        end
        at:GetPropertyChangedSignal("Visible"):Connect(function()
            local N = at.Visible
            if N then
                if count(ao.Options) <= 0 then
                    d:CreateNotification(
                        "BadWars",
                        `<font color="#ff8080"><b>No options found</b></font> for <font color="#7db8ff"><b>{tostring(
                            an.Name
                        )}</b></font> :c`,
                        3
                    )
                    closeOptions(true)
                end
            end
        end)
        ar.Activated:Connect(function(inputObject)
            if
                os.clock() < (ao._SuppressPrimaryUntil or 0)
                or ao._PrimaryClickBusy
                or (
                    inputObject
                    and inputObject.UserInputType
                        == Enum.UserInputType.MouseButton2
                )
            then
                return
            end

            ao._PrimaryClickBusy = true
            task.delay(0.075, function()
                ao._PrimaryClickBusy = false
            end)

            if d.isMobile then
                local N = Instance.new("Frame")
                N.Size = UDim2.fromScale(1, 1)
                N.BackgroundColor3 = Color3.new(1, 1, 1)
                N.BackgroundTransparency = 0.85
                N.BorderSizePixel = 0
                N.ZIndex = ar.ZIndex + 1
                N.Parent = ar
                addCorner(N, UDim.new(0, 4))
                local rippleTween = n:Tween(N, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = 1,
                })
                if rippleTween then
                    rippleTween.Completed:Once(function()
                        pcall(function()
                            N:Destroy()
                        end)
                    end)
                else
                    N:Destroy()
                end
            end
            ao:Toggle()
        end)
        ar.MouseButton2Click:Connect(function()
            ao._SuppressPrimaryUntil = os.clock() + 0.12

            if d.HideTooltip then
                d.HideTooltip(true)
            end

            toggleOptions()
        end)

        ar.Destroying:Once(function()
            closeOptions(true)
        end)
        if d.isMobile then
            local N = false
            local O

            ar.MouseButton1Down:Connect(function()
                N = true
                local P, Q = tick(), h:GetMouseLocation()
                local R = 0.75

                local S = Instance.new("Frame")
                S.Name = "HoldProgress"
                S.Size = UDim2.new(0, 0, 0, 3)
                S.Position = UDim2.new(0, 0, 1, -3)
                S.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                S.BorderSizePixel = 0
                S.Parent = ar

                n:Tween(S, TweenInfo.new(R, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 0, 3) })

                repeat
                    N = (h:GetMouseLocation() - Q).Magnitude < 10
                    task.wait(0.05)
                until (tick() - P) > R or not N or not v.Visible or d.Loaded == nil

                if S and S.Parent then
                    S:Destroy()
                end

                if N and v.Visible then
                    if d.ThreadFix then
                        setthreadidentity(8)
                    end

                    O = Instance.new("Frame")
                    O.Name = "BindingOverlay"
                    O.Size = UDim2.fromScale(1, 1)
                    O.Position = UDim2.fromScale(0, 0)
                    O.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    O.BackgroundTransparency = 0.5
                    O.BorderSizePixel = 0
                    O.ZIndex = 1000
                    O.Parent = v.Parent

                    local T = Instance.new("TextLabel")
                    T.Size = UDim2.fromScale(0.8, 0.2)
                    T.Position = UDim2.fromScale(0.5, 0.4)
                    T.AnchorPoint = Vector2.new(0.5, 0.5)
                    T.BackgroundColor3 = m.Dark(o.Main, 0.1)
                    T.BackgroundTransparency = 0
                    T.BorderSizePixel = 0
                    T.Text = "TAP ANYWHERE TO SET BUTTON POSITION"
                    T.TextColor3 = o.Text
                    T.TextSize = 18
                    T.TextWrapped = true
                    T.FontFace = o.Font
                    T.Parent = O

                    addCorner(T, UDim.new(0, 8))

                    local U = Instance.new("TextLabel")
                    U.Size = UDim2.fromScale(0.8, 0.1)
                    U.Position = UDim2.fromScale(0.5, 0.55)
                    U.AnchorPoint = Vector2.new(0.5, 0)
                    U.BackgroundTransparency = 1
                    U.Text = "Module: " .. an.Name
                    U.TextColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, 1)
                    U.TextSize = 14
                    U.FontFace = o.Font
                    U.Parent = O

                    local V = n:Tween(
                        T,
                        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true),
                        { TextTransparency = 0.3 }
                    )

                    v.Visible = false
                    z.Visible = false
                    d:BlurCheck()

                    for W, X in d.Modules do
                        if X.Bind.Button then
                            X.Bind.Button.Visible = true
                            X.Bind.Button.BackgroundTransparency = 0.7
                        end
                    end

                    local W
                    W = h.InputBegan:Connect(function(X)
                        if X.UserInputType == Enum.UserInputType.Touch then
                            if d.ThreadFix then
                                setthreadidentity(8)
                            end

                            if V then
                                V:Cancel()
                            end
                            if O then
                                O:Destroy()
                            end

                            createMobileButton(ao, X.Position + Vector3.new(0, j:GetGuiInset().Y, 0))

                            d:CreateNotification(
                                "Mobile Bind Created",
                                "<font color='#FFFFFF'>Button for </font><font color='#7db8ff'><b>"
                                    .. an.Name
                                    .. "</b></font><font color='#FFFFFF'> has been placed!</font>",
                                2
                            )

                            v.Visible = true
                            d:BlurCheck()

                            for Y, Z in d.Modules do
                                if Z.Bind.Button then
                                    Z.Bind.Button.Visible = false
                                    Z.Bind.Button.BackgroundTransparency = 0
                                end
                            end

                            W:Disconnect()
                        end
                    end)

                    local X

                    X = task.delay(15, function()
                        if W then
                            W:Disconnect()
                        end
                        if O then
                            O:Destroy()
                        end
                        if V then
                            V:Cancel()
                        end

                        v.Visible = true
                        d:BlurCheck()

                        for Y, Z in d.Modules do
                            if Z.Bind.Button then
                                Z.Bind.Button.Visible = false
                                Z.Bind.Button.BackgroundTransparency = 0
                            end
                        end

                        d:CreateNotification(
                            "Binding Cancelled",
                            "<font color='#ff8080'>Mobile bind timed out</font>",
                            2
                        )
                    end)
                else
                    if S and S.Parent then
                        S:Destroy()
                    end
                end
            end)

            ar.MouseButton1Up:Connect(function()
                N = false
            end)
        end
        connectDeferredPropertyChanged(J, "AbsoluteContentSize", function()
            if d.ThreadFix then
                setthreadidentity(8)
            end
            local targetSize = UDim2.new(1, -12, 0, J.AbsoluteContentSize.Y / A.Scale)
            if at.Size ~= targetSize then
                at.Size = targetSize
            end
        end)

        function ao.SetVisible(N, O)
            if O == nil then
                O = not N.Object.Visible
            end
            N.Object.Visible = O
        end

        ao.Object = ar
        ao.Children = at
        ao.CategoryApi = ac

        ao.Aliases = an.Aliases or d.AliasesConfig[an.Name] or {}

        ao.SearchKeys = { an.Name }
        for N, O in ao.Aliases do
            table.insert(ao.SearchKeys, O)
        end
        d.Modules[an.SavingID or an.Name] = ao

        updateModuleSorting()

        function ao.Restart(N)
            if N.Enabled then
                N:Toggle()
                task.wait(0.1)
                if N.Enabled then
                    return
                end
                N:Toggle()
            end
        end

        return ao
    end

    local categoryAnimationId = 0
    local renderedExpanded = ac.Expanded == true

    local function getExpandedCategoryHeight()
        local scale = math.max(A.Scale, 0.01)
        local contentHeight = math.max(
            0,
            al.AbsoluteContentSize.Y / scale
        )
        local viewportLimit = math.max(
            160,
            (B.AbsoluteSize.Y / scale) - 96
        )

        return math.min(
            UI_HEADER_HEIGHT + contentHeight + 8,
            viewportLimit,
            606
        )
    end

    local function refreshCategoryLayout(instant)
        categoryAnimationId += 1
        local animationId = categoryAnimationId
        local stateChanged = renderedExpanded ~= ac.Expanded
        renderedExpanded = ac.Expanded

        local targetHeight = ac.Expanded
            and getExpandedCategoryHeight()
            or UI_HEADER_HEIGHT

        aj.CanvasSize = UDim2.fromOffset(
            0,
            math.max(
                0,
                al.AbsoluteContentSize.Y
                    / math.max(A.Scale, 0.01)
                    + 8
            )
        )

        aj.ScrollingEnabled =
            ac.Expanded
            and aj.CanvasSize.Y.Offset
                > math.max(0, targetHeight - UI_HEADER_HEIGHT)

        local currentHeight = ad.Size.Y.Offset
        local needsResize =
            math.abs(currentHeight - targetHeight) > 0.5

        if instant or not d.Loaded or d._SuppressEntryAnimation then
            ad.ClipsDescendants = true
            ad.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, targetHeight)
            ai.Rotation = ac.Expanded and 0 or 180
            aj.Visible = ac.Expanded
        else
            ad.ClipsDescendants = true

            if ac.Expanded then
                aj.Visible = true
            end

            if stateChanged then
                n:Tween(ai, o.TweenSlow, {
                    Rotation = ac.Expanded and 0 or 180,
                })
            else
                ai.Rotation = ac.Expanded and 0 or 180
            end

            local sizeTween
            if needsResize then
                sizeTween = n:Tween(ad, o.TweenSlow, {
                    Size = UDim2.fromOffset(UI_WINDOW_WIDTH, targetHeight),
                })
            else
                ad.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, targetHeight)
            end

            local function finishCategoryTransition()
                if animationId ~= categoryAnimationId then
                    return
                end

                aj.Visible = ac.Expanded
                ad.ClipsDescendants = true
            end

            if sizeTween then
                sizeTween.Completed:Once(
                    finishCategoryTransition
                )
            else
                finishCategoryTransition()
            end
        end

        local maxCanvasY = math.max(
            0,
            aj.AbsoluteCanvasSize.Y - aj.AbsoluteWindowSize.Y
        )

        aj.CanvasPosition = Vector2.new(
            0,
            math.clamp(
                aj.CanvasPosition.Y,
                0,
                maxCanvasY
            )
        )

        ak.Visible = aj.CanvasPosition.Y > 10 and aj.Visible
        updateCategoryVisual(false, instant or not d.Loaded)
    end

    function ac.Expand(am, an, instant)
        if an ~= nil then
            if an == am.Expanded then
                refreshCategoryLayout(instant == true)
                return
            end
            am.Expanded = an
        else
            am.Expanded = not am.Expanded
        end

        refreshCategoryLayout(instant == true)
    end

    if ab.Visible then
        ac:Expand(true, true)
    else
        updateCategoryVisual(false, true)
    end

    ag.Activated:Connect(function()
        if not ah() then
            return
        end
        ac:Expand()
    end)
    ag.MouseEnter:Connect(function()
        updateCategoryVisual(true)
        playV9Sweep(categorySweep)
        n:Spring(categoryScale, o.SpringInteractive, { Scale = 1.004 })
    end)
    ag.MouseLeave:Connect(function()
        updateCategoryVisual(false)
        n:Spring(categoryScale, o.SpringInteractive, { Scale = 1 })
    end)
    ag.MouseButton1Down:Connect(function()
        n:Spring(categoryScale, o.SpringInteractive, { Scale = 0.997 })
    end)
    ag.MouseButton1Up:Connect(function()
        n:Spring(categoryScale, o.SpringInteractive, { Scale = 1 })
    end)

    ad:GetPropertyChangedSignal("Visible"):Connect(function()
        if not ad.Visible then
            return
        end

        categoryScale.Scale = 1
        updateCategoryVisual(false, true)

        if d._InitialLayoutReady then
            refreshCategoryLayout(true)
        end
    end)
    aj:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if aa.ThreadFix then
            setthreadidentity(8)
        end
        ak.Visible = aj.CanvasPosition.Y > 10 and aj.Visible
    end)
    connectDeferredPropertyChanged(al, "AbsoluteContentSize", function()
        if aa.ThreadFix then
            setthreadidentity(8)
        end
        refreshCategoryLayout(not d._InitialLayoutReady)
    end)

    B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if ac.Expanded then
            task.defer(refreshCategoryLayout, true)
        end
    end)

    A:GetPropertyChangedSignal("Scale"):Connect(function()
        if ac.Expanded then
            task.defer(refreshCategoryLayout, true)
        end
    end)

    function ac.SetVisible(am, an)
        if an == nil then
            an = not am.Object.Visible
        end
        am.LockedVisibility = an
        am.Object.Visible = an
        if an == false then
            pcall(function()
                am.Button.Object.Visible = false
            end)
        end
    end

    function ac.CreateModuleCategory(am, an)
        local ao, ap = pcall(function()
            local ao = {
                Type = "ModuleCategory",
                Expanded = false,
                Modules = {},
                Name = an.Name,
                CategoryApi = ac,
                ExpandEvent = c(`ModuleCategory_ExpandEvent_{tostring(an.Name)}_{tostring(ac.Name)}`),
                UpExpand = an.UpExpand or false,
            }

            local ap
            success, err = pcall(function()
                ap = Instance.new("Frame")
                ap.Name = an.Name .. "ModuleCategory"
                ap.Size = UDim2.fromOffset(220, 46)
                ap.BackgroundColor3 = an.BackgroundColor or o.Surface
                ap.BorderSizePixel = 0
                if not (aj ~= nil and aj.Parent ~= nil) then
                    error(`{an.Name}: Category Children are invalid!`)
                    return
                end
                ap.Parent = aj
            end)
            if not success then
                bwarn("[ModuleCategory] Frame creation failed:", err)
                return
            end

            success, err = pcall(function()
                addTooltip(ap, an.Name .. " " .. (an.Name ~= "Special" and "Special Category" or "Category"))
            end)
            if not success then
                bwarn("[ModuleCategory] Tooltip failed:", err)
            end

            if an.StrokeColor then
                success, err = pcall(function()
                    local aq = Instance.new("UIStroke")
                    aq.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    aq.Color = an.StrokeColor
                    aq.Thickness = an.StrokeThickness or 1
                    aq.Transparency = an.StrokeTransparency or 0.5
                    aq.Parent = ap
                    if an.GuiColorSync then
                        connectguicolorchange(function(ar, as, at)
                            aq.Color = Color3.fromHSV(ar, as, at)
                        end)
                    end
                end)
                if not success then
                    bwarn("[ModuleCategory] Stroke creation failed:", err)
                end
            end

            success, err = pcall(function()
                addCorner(ap, o.Radius)
            end)
            if not success then
                bwarn("[ModuleCategory] Corner failed:", err)
            end

            local moduleCategoryStroke = addStroke(ap, o.Border, 0.84, 1, "ModuleCategoryStroke")
            local moduleCategoryScale = addScale(ap)

            local aq
            success, err = pcall(function()
                aq = Instance.new("TextButton")
                aq.Name = "Header"
                aq.Size = UDim2.fromOffset(220, 46)

                if ao.UpExpand then
                    aq.AnchorPoint = Vector2.new(0, 1)
                    aq.Position = UDim2.new(0, 0, 1, 0)
                else
                    aq.Position = UDim2.fromOffset(0, 0)
                end

                aq.BackgroundTransparency = 1
                aq.BorderSizePixel = 0
                aq.AutoButtonColor = false
                aq.Text = ""
                aq.Parent = ap
            end)
            if not success then
                bwarn("[ModuleCategory] Header button creation failed:", err)
                return
            end

            local ar
            success, err = pcall(function()
                ar = Instance.new("Frame")
                ar.Name = "AccentBar"
                ar.Size = UDim2.new(0, 3, 1, -12)

                ar.Position = ao.UpExpand and UDim2.new(0, 0, 0, 6) or UDim2.fromOffset(0, 6)

                ar.BackgroundColor3 = an.AccentColor or an.StrokeColor or Color3.fromRGB(100, 150, 255)
                ar.BorderSizePixel = 0
                ar.Parent = ap

                if an.GuiColorSync then
                    connectguicolorchange(function(as, at, au)
                        ar.BackgroundColor3 = Color3.fromHSV(as, at, au)
                    end)
                end

                local as = Instance.new("UICorner")
                as.CornerRadius = UDim.new(0, 4)
                as.Parent = ar
            end)
            if not success then
                bwarn("[ModuleCategory] Accent bar creation failed:", err)
            end

            local as
            success, err = pcall(function()
                as = Instance.new("ImageLabel")
                as.Name = "Icon"
                as.Size = an.Size or UDim2.fromOffset(20, 20)
                as.Position = UDim2.fromOffset(15, 13)
                as.BackgroundTransparency = 1
                as.Image = an.Icon or ""
                as.ImageColor3 = o.Text
                as.Parent = aq
            end)
            if not success then
                bwarn("[ModuleCategory] Icon creation failed:", err)
            end

            local at
            success, err = pcall(function()
                at = Instance.new("TextLabel")
                at.Name = "Title"
                at.Size = UDim2.new(1, -90, 0, 46)
                at.Position = UDim2.fromOffset(45, 0)
                at.BackgroundTransparency = 1
                at.Text = an.Name
                at.TextXAlignment = Enum.TextXAlignment.Left
                at.TextColor3 = o.Text
                at.TextSize = 14
                at.FontFace = Font.new(o.Font.Family, Enum.FontWeight.SemiBold)
                at.Parent = aq
            end)
            if not success then
                bwarn("[ModuleCategory] Title creation failed:", err)
            end

            local au
            success, err = pcall(function()
                au = Instance.new("TextLabel")
                au.Name = "Count"
                au.Size = UDim2.fromOffset(40, 46)
                au.Position = UDim2.new(1, -85, 0, 0)
                au.BackgroundTransparency = 1
                au.Text = "0"
                au.TextXAlignment = Enum.TextXAlignment.Right
                au.TextColor3 = o.FaintText
                au.TextSize = 12
                au.FontFace = o.Font
                au.Parent = aq
            end)
            if not success then
                bwarn("[ModuleCategory] Count label creation failed:", err)
            end

            local av, aw
            success, err = pcall(function()
                av = Instance.new("TextButton")
                av.Name = "Arrow"
                av.Size = UDim2.fromOffset(45, 46)
                av.Position = UDim2.new(1, -45, 0, 0)
                av.BackgroundTransparency = 1
                av.Text = ""
                av.Parent = aq

                aw = Instance.new("ImageLabel")
                aw.Name = "Arrow"
                aw.Size = UDim2.fromOffset(12, 7)
                aw.Position = UDim2.fromOffset(17, 20)
                aw.BackgroundTransparency = 1
                aw.Image = u("badscript/assets/new/expandup.png")
                aw.ImageColor3 = o.MutedText

                aw.Rotation = ao.UpExpand and 0 or 180

                aw.Parent = av
            end)
            if not success then
                bwarn("[ModuleCategory] Arrow button creation failed:", err)
            end

            aq.MouseEnter:Connect(function()
                if not ao.Expanded then
                    n:Tween(ap, o.TweenFast, { BackgroundColor3 = o.SurfaceHover })
                end
                n:Tween(moduleCategoryStroke, o.TweenFast, {
                    Color = o.BorderStrong,
                    Transparency = 0.62,
                })
                n:Spring(moduleCategoryScale, o.SpringInteractive, { Scale = 1 })
                at.TextColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                aw.ImageColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            end)
            aq.MouseLeave:Connect(function()
                if not ao.Expanded then
                    n:Tween(ap, o.TweenFast, { BackgroundColor3 = o.Surface })
                end
                n:Tween(moduleCategoryStroke, o.TweenFast, {
                    Color = o.Border,
                    Transparency = 0.84,
                })
                n:Spring(moduleCategoryScale, o.SpringInteractive, { Scale = 1 })
                at.TextColor3 = ao.Expanded and o.TextStrong or o.MutedText
                aw.ImageColor3 = ao.Expanded
                    and Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                    or o.MutedText
            end)
            aq.MouseButton1Down:Connect(function()
                n:Spring(moduleCategoryScale, o.SpringInteractive, { Scale = 0.99 })
            end)
            aq.MouseButton1Up:Connect(function()
                n:Spring(moduleCategoryScale, o.SpringInteractive, { Scale = 1 })
            end)

            success, err = pcall(function()
                local ax = Instance.new("UIGradient")
                ax.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, o.Elevated),
                    ColorSequenceKeypoint.new(0.55, o.SurfaceSoft),
                    ColorSequenceKeypoint.new(1, o.Surface),
                })
                ax.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.04),
                    NumberSequenceKeypoint.new(1, 0.12),
                })
                ax.Rotation = 90
                ax.Parent = ap
            end)
            if not success then
                bwarn("[ModuleCategory] Gradient creation failed:", err)
            end

            local ax, ay
            success, err = pcall(function()
                ax = Instance.new("Frame")
                ax.Name = "ModulesContainer"
                ax.Size = UDim2.new(1, 0, 0, 0)

                if ao.UpExpand then
                    ax.AnchorPoint = Vector2.new(0, 1)
                    ax.Position = UDim2.new(0, 0, 1, -46)
                else
                    ax.Position = UDim2.fromOffset(0, 46)
                end

                ax.BackgroundTransparency = 1
                ax.BorderSizePixel = 0
                ax.Visible = false
                ax.ClipsDescendants = true
                ax.Parent = ap

                ay = Instance.new("UIListLayout")
                ay.SortOrder = Enum.SortOrder.LayoutOrder
                ay.HorizontalAlignment = Enum.HorizontalAlignment.Center
                ay.Padding = UDim.new(0, 2)

                ay.VerticalAlignment = ao.UpExpand and Enum.VerticalAlignment.Bottom or Enum.VerticalAlignment.Top

                ay.Parent = ax
            end)
            if not success then
                bwarn("[ModuleCategory] Modules container creation failed:", err)
                return
            end

            local function updateCount()
                success, err = pcall(function()
                    local az = 0
                    local aA = {}
                    for _, aB in ao.Modules do
                        if not aA[aB] then
                            aA[aB] = true
                            az += 1
                        end
                    end
                    au.Text = tostring(az)
                end)
                if not success then
                    bwarn("[ModuleCategory] updateCount failed:", err)
                end
            end

            local function refreshModuleCategory()
                success, err = pcall(function()
                    local az = ay.AbsoluteContentSize.Y / A.Scale
                    if ao.Expanded then
                        ax.Visible = true
                        ax.Size = UDim2.new(1, 0, 0, az)
                        ap.Size = UDim2.fromOffset(220, 46 + az)
                        if ao.UpExpand then
                            ap.Position = UDim2.fromOffset(0, -az)
                        end
                    else
                        ax.Size = UDim2.new(1, 0, 0, 0)
                        ap.Size = UDim2.fromOffset(220, 46)
                        if ao.UpExpand then
                            ap.Position = UDim2.fromOffset(0, 0)
                        end
                    end
                    aj.CanvasSize = UDim2.fromOffset(0, al.AbsoluteContentSize.Y / A.Scale)
                    if ac.Expanded then
                        ad.Size = UDim2.fromOffset(220, math.min(41 + al.AbsoluteContentSize.Y / A.Scale, 601))
                    end
                end)
                if not success then
                    bwarn("[ModuleCategory] refresh failed:", err)
                end
            end

            ao.Refresh = refreshModuleCategory

            local moduleCategoryAnimationId = 0

            function ao.Toggle(az, aA)
                success, err = pcall(function()
                    moduleCategoryAnimationId += 1
                    local animationId = moduleCategoryAnimationId
                    if aA ~= nil then
                        if aA == az.Expanded then
                            return
                        end
                        az.Expanded = aA
                    else
                        az.Expanded = not az.Expanded
                    end

                    ao.ExpandEvent:Fire()

                    local aB = az.Expanded and ay.AbsoluteContentSize.Y / A.Scale or 0

                    local aC = az.UpExpand and 180 or 0
                    local I = az.UpExpand and 0 or 180

                    n:Tween(aw, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                        Rotation = az.Expanded and aC or I,
                        ImageColor3 = az.Expanded
                                and (an.AccentColor or an.StrokeColor or Color3.fromRGB(100, 150, 255))
                            or o.Text,
                    })

                    n:Tween(as, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        ImageColor3 = az.Expanded
                                and (an.AccentColor or an.StrokeColor or Color3.fromRGB(100, 150, 255))
                            or o.Text,
                    })

                    n:Tween(ap, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = az.Expanded and m.Dark(o.Main, 0.12)
                            or (an.BackgroundColor or m.Dark(o.Main, 0.08)),
                    })

                    ax.Visible = true
                    n:Tween(ax, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, aB),
                    })

                    if az.UpExpand then
                        n:Tween(ap, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                            Size = UDim2.fromOffset(220, 45 + aB),
                            Position = UDim2.fromOffset(0, -(az.Expanded and aB or 0)),
                        })
                    else
                        n:Tween(ap, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                            Size = UDim2.fromOffset(220, 45 + aB),
                        })
                    end

                    if not az.Expanded then
                        task.delay(0.3, function()
                            if animationId == moduleCategoryAnimationId and not az.Expanded then
                                ax.Visible = false
                            end
                        end)
                    end
                end)
                if not success then
                    bwarn("[ModuleCategory] Toggle failed:", err)
                end
            end

            function ao.Expand(az)
                az:Toggle()
            end

            function ao.Load(az, aA)
                success, err = pcall(function()
                    for aB, aC in aA do
                        local I = d.Modules[aC]
                        if I then
                            az:AddModule(I)
                        end
                    end
                end)
                if not success then
                    bwarn("[ModuleCategory] Load failed:", err)
                end
            end

            function ao.AddModule(az, aA)
                success, err = pcall(function()
                    if not aA or not aA.Object then
                        return
                    end

                    local aB = aA.SavingID or aA.Name or tostring(aA)
                    az.Modules[aB] = aA
                    if aA.Name and aA.Name ~= aB then
                        az.Modules[aA.Name] = aA
                    end

                    aA.Object.Parent = ax
                    if aA.Children then
                        aA.Children.Parent = ax
                    end
                    aA.Category = az.Name
                    aA.CategoryApi = ac
                    aA.ModuleCategory = ao
                    updateCount()
                    task.defer(refreshModuleCategory)
                end)
                if not success then
                    bwarn("[ModuleCategory] AddModule failed:", err)
                end

                return aA
            end

            function ao.AddToggle(az, aA)
                local aB
                aB = ac:CreateModule({
                    Name = aA.Name,
                    Function = function(aC)
                        task.spawn(function()
                            if aA.Enabled ~= aC then
                                aA:Toggle()
                            end
                        end)
                    end,
                    Default = aA.Enabled,
                    Tooltip = aA.Name,
                    NoSave = true,
                })
                aA.Toggled:Connect(function()
                    if aB.Enabled ~= aA.Enabled then
                        aB:Toggle()
                    end
                end)
                az:AddModule(aB)
            end

            function ao.SetVisible(az, aA)
                success, err = pcall(function()
                    if aA == nil then
                        aA = not ap.Visible
                    end
                    ap.Visible = aA
                end)
                if not success then
                    bwarn("[ModuleCategory] SetVisible failed:", err)
                end
            end

            ao.Button = { Toggle = function() end }

            function ao.CreateModule(az, aA)
                local aB
                success, err = pcall(function()
                    aB = ac:CreateModule(aA)
                    az:AddModule(aB)
                end)
                if not success then
                    bwarn("[ModuleCategory] CreateModule failed:", err)
                end
                return aB
            end

            success, err = pcall(function()
                aq.Activated:Connect(function()
                    ao:Toggle()
                end)

                av.Activated:Connect(function()
                    ao:Toggle()
                end)

                connectDeferredPropertyChanged(ay, "AbsoluteContentSize", function()
                    refreshModuleCategory()
                end)
            end)
            if not success then
                bwarn("[ModuleCategory] Event connections failed:", err)
            end

            ao.Object = ap
            ao.Container = ax

            return ao
        end)

        if not ao then
            bwarn("[ModuleCategory] CreateModuleCategory failed:", ap)
            return nil
        end
        return ao and ap
    end

    ad:GetPropertyChangedSignal("Visible"):Connect(function()
        local am = ac
        if am.LockedVisibility == nil then
            return
        end
        if ad.Visible ~= am.LockedVisibility then
            ad.Visible = am.LockedVisibility
        end
    end)

    ac.Button = aa.Categories.Main:CreateButton({
        Name = ab.Name,
        Icon = ab.Icon,
        Size = ab.Size,
        Window = ad,
        Default = ab.Visible,
    })
    function ac.ToggleCategoryButton(am, an)
        ac.Button:Toggle(an)
    end
    if ac.Button ~= nil and ac.Button.Object ~= nil and ac.Button.Object.Parent ~= nil then
        ac.Button.Object:GetPropertyChangedSignal("Visible"):Connect(function()
            local am = ac
            if am.LockedVisibility == nil then
                return
            end
            if am.LockedVisibility then
                return
            end
            ac.Button.Object.Visible = false
        end)
    end

    ac.Object = ad
    ac.Scroll = aj
    ac.Layout = al
    ac.RefreshLayout = refreshCategoryLayout
    aa.Categories[ab.Name] = ac

    return ac
end

local aa = shared.LANGUAGE_FLAGS_CACHE
    or F(
        function()
            return game:GetService("HttpService"):JSONDecode(
                d.http_function(
                    `https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/translations/LanguageFlags.json`,
                    true
                )
            )
        end,
        10,
        function(aa, ab)
            if not (aa and ab ~= nil and type(ab) == "table") then
                return F(
                    function()
                        return game:GetService("HttpService")
                            :JSONDecode(readfile(`badwars_translations/LanguageFlags.json`))
                    end,
                    10,
                    function(ac, ad)
                        if not (ac and ad ~= nil and type(ad) == "table") then
                            return { en = "US" }
                        else
                            return ad
                        end
                    end
                )
            else
                F(function()
                    if not isfolder("badwars_translations") then
                        makefolder("badwars_translations")
                    end
                    safeWriteFile(`badwars_translations/LanguageFlags.json`, game:GetService("HttpService"):JSONEncode(ab), "translation-flags")
                end, 5)
                shared.LANGUAGE_FLAGS_CACHE = ab
                return ab
            end
        end
    )
d.LanguageFlags = aa

local ab = shared.TargetLanguage and tostring(shared.TargetLanguage)
    or F(
        function()
            return readfile("badwars_translations/lang.txt")
        end,
        10,
        function(ab, ac)
            if ab then
                return ac
            else
                pcall(function()
                    if not isfolder("badwars_translations") then
                        makefolder("badwars_translations")
                    end
                    safeWriteFile("badwars_translations/lang.txt", "en", "translation-language")
                end)
                return "en"
            end
        end
    )
local function populateLanguages(ac)
    if
        tostring(shared.environment) == "translator_env"
        and shared.language ~= nil
        and type(shared.language) == "table"
    then
        for ad, ae in shared.language do
            ac[ad] = ae
        end
    end
    return ac
end
if tostring(shared.environment) == "translator_env" then
    shared[`TRANSLATION_API_LANGUAGE_CACHE_{tostring(ab)}`] = nil
end
shared.TargetLanguage = ab
local ac = {
    lang = ab,
    languages = shared.LANGUAGES_TRANSLATION_API_CACHE
        or F(
            function()
                return game:GetService("HttpService"):JSONDecode(
                    d.http_function(
                        `https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/translations/Languages.json`,
                        true
                    )
                )
            end,
            10,
            function(ac, ad)
                if not (ac and ad ~= nil and type(ad) == "table") then
                    return F(
                        function()
                            return game:GetService("HttpService")
                                :JSONDecode(readfile(`badwars_translations/Languages.json`))
                        end,
                        10,
                        function(ae, af)
                            if not (ae and af ~= nil and type(af) == "table") then
                                return populateLanguages({ "en" })
                            else
                                return populateLanguages(af)
                            end
                        end
                    )
                else
                    F(function()
                        if not isfolder("badwars_translations") then
                            makefolder("badwars_translations")
                        end
                        safeWriteFile(`badwars_translations/Languages.json`, game:GetService("HttpService"):JSONEncode(ad), "translation-index")
                    end, 5)
                    local ae = populateLanguages(ad)
                    shared.LANGUAGES_TRANSLATION_API_CACHE = ae
                    return ae
                end
            end
        ),
    data = shared[`TRANSLATION_API_LANGUAGE_CACHE_{tostring(ab)}`]
        or F(
            function()
                if ab == "en" then
                    return {}
                end
                if
                    tostring(shared.environment) == "translator_env"
                    and isfolder("badwars_translations")
                    and D(`badwars_translations/{ab}.json`)
                then
                    return decode(readfile(`badwars_translations/{ab}.json`))
                end
                return decode(
                    d.http_function(
                        `https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/translations/locales/{ab}.json`,
                        true
                    )
                )
            end,
            10,
            function(ac, ad)
                if not (ac and ad ~= nil and type(ad) == "table") then
                    return F(
                        function()
                            return game:GetService("HttpService"):JSONDecode(readfile(`badwars_translations/{ab}.json`))
                        end,
                        10,
                        function(ae, af)
                            if not (ae and af ~= nil and type(af) == "table") then
                                return {}
                            else
                                return af
                            end
                        end
                    )
                else
                    F(function()
                        if not isfolder("badwars_translations") then
                            makefolder("badwars_translations")
                        end
                        safeWriteFile(`badwars_translations/{ab}.json`, game:GetService("HttpService"):JSONEncode(ad), "translation-locale")
                    end, 5)
                    shared[`TRANSLATION_API_LANGUAGE_CACHE_{tostring(ab)}`] = ad
                    return ad
                end
            end
        ),
}
d.TranslationAPI = ac

shared.REVERT_TRANSLATION_META = {}

local ad = {}
local ae = {}
function d.GetTranslation(af, ag)
    if ag == "Information" then
        return "Information"
    end
    if ac.lang == "en" then
        return ag
    end
    if ae[ag] then
        return ae[ag]
    end
    local ah = ac.data or {}
    local ai = ah[ag]
    if not ai then
        local aj = {}
        for ak in string.gmatch(ag, "%S+") do
            table.insert(aj, ah[ak] or ak)
        end
        ai = table.concat(aj, " ")
    end
    shared.REVERT_TRANSLATION_META[ai] = ag
    ae[ag] = ai
    if ag == ai and not table.find(ad, ag) and shared.VoidDev then
        table.insert(ad, ag)
        safeWriteFile("FAILED_TRANSLATION.json", encode(ad), "translation-debug")
    end
    return ai
end

local function customHook(af, ag, ah)
    return function(...)
        local ai = { ... }
        ai = ag(unpack(ai))
        local aj = af(unpack(ai))
        if ah then
            aj = ah(aj, unpack(ai))
        end
        return aj
    end
end

d.CreateCategory = customHook(d.CreateCategory, function(af, ag)
    if ag.Name then
    end
    return { af, ag }
end, function(af)
    af.CreateModule = customHook(af.CreateModule, function(ag, ah)
        if ah.Name then
            ah.SavingID = ah.Name
        end
        if ah.Tooltip then
            ah.Tooltip = d:GetTranslation(ah.Tooltip)
        end
        return { ag, ah }
    end)
    af.CreateModuleCategory = customHook(af.CreateModuleCategory, function(ag, ah)
        if ah.Name then
            ah.SavingID = ah.Name
        end
        return { ag, ah }
    end)
    return af
end)

shared.TRANSLATION_FUNCTION = function(af)
    return Library:GetTranslation(af)
end

function d.CreateOverlay(af, ag)
    ag = type(ag) == "table" and ag or {}
    assert(type(ag.Name) == "string" and ag.Name ~= "", "CreateOverlay requires a name")

    ag.Size = ag.Size or UDim2.fromOffset(14, 14)
    ag.Position = ag.Position or UDim2.fromOffset(12, 14)
    if ag.CustomOverlay then
        ag.Pinned = true
        ag.CategorySize = ag.CategorySize or 100
        ag.ContentHeight = ag.ContentHeight or 40
    end

    af.Overlays = type(af.Overlays) == "table" and af.Overlays or {}
    local previous = af.Overlays[ag.Name]
    if previous then
        if previous.Connections then
            for _, connection in previous.Connections do
                pcall(function()
                    connection:Disconnect()
                end)
            end
            table.clear(previous.Connections)
        end
        if previous._FunctionThread then
            pcall(task.cancel, previous._FunctionThread)
            previous._FunctionThread = nil
        end

        -- Destroy the floating display before removing the normal module row.
        -- d:Remove clears table fields recursively, so doing this afterward can
        -- lose the only reference to the old HUD and leave it on screen.
        for _, candidate in {
            previous.Object,
            previous.Children,
        } do
            if typeof(candidate) == "Instance" then
                pcall(function()
                    candidate:Destroy()
                end)
            end
        end

        pcall(function()
            af:Remove(ag.Name)
        end)
        af.Overlays[ag.Name] = nil
        if af.Categories[ag.Name] == previous then
            af.Categories[ag.Name] = nil
        end
    end

    local renderCategory = af.Categories and af.Categories.Render
    assert(
        renderCategory and type(renderCategory.CreateModule) == "function",
        "Render category must exist before CreateOverlay"
    )

    local ah
    local ai = {
        Type = "Overlay",
        Name = ag.Name,
        Category = "Render",
        Expanded = false,
        UpExpand = false,
        Pinned = ag.Pinned == true,
        Enabled = false,
        Options = {},
    }
    addMaid(ai)

    local function cleanOverlayConnections()
        if type(ai.Cleanup) == "function" then
            ai:Cleanup()
        end
    end

    local moduleApi
    moduleApi = renderCategory:CreateModule({
        Name = ag.Name,
        DisplayName = ag.DisplayName,
        SavingID = ag.SavingID or ag.Name,
        Tooltip = ag.Tooltip or ("Shows " .. ag.Name .. " on screen"),
        Function = function(enabled)
            ai.Enabled = enabled == true

            if ai._FunctionThread then
                pcall(task.cancel, ai._FunctionThread)
                ai._FunctionThread = nil
            end

            if not enabled then
                cleanOverlayConnections()
            end

            if ah and ah.Parent then
                ai:Update()
            end

            if type(ag.Function) == "function" then
                local callbackThread = task.spawn(ag.Function, enabled)
                if enabled then
                    ai._FunctionThread = callbackThread
                end
            end
        end,
    })

    ai.Button = moduleApi
    ai.Module = moduleApi
    ai.Options = moduleApi.Options
    moduleApi.Overlay = ai

    local width = math.max(72, tonumber(ag.CategorySize) or 220)
    local contentHeight = math.max(1, tonumber(ag.ContentHeight) or (ag.CustomOverlay and 40 or 200))

    ah = Instance.new("TextButton")
    ah.Name = ag.Name .. "Overlay"
    ah.Size = UDim2.fromOffset(width, 41)
    ah.Position = UDim2.fromOffset(240, 46)
    ah.BackgroundColor3 = o.MainSoft
    ah.AutoButtonColor = false
    ah.Visible = false
    ah.Text = ""
    ah.ClipsDescendants = false
    ah.Parent = w

    ai.WindowXOffset = width

    local overlayShadow = addBlur(ah)
    addCorner(ah, o.RadiusLarge)
    addSurfaceGradient(ah)
    local overlayStroke = addStroke(ah, o.BorderStrong, 0.66, 1, "OverlayStroke")
    addV9Chrome(ah)

    local overlayAccent = Instance.new("Frame")
    overlayAccent.Name = "OverlayAccent"
    overlayAccent.Size = UDim2.new(1, -18, 0, 1)
    overlayAccent.Position = UDim2.fromOffset(9, 1)
    overlayAccent.BorderSizePixel = 0
    overlayAccent.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
    overlayAccent.BackgroundTransparency = 0.28
    overlayAccent.ZIndex = ah.ZIndex + 1
    overlayAccent.Parent = ah
    addCorner(overlayAccent, UDim.new(1, 0))
    connectguicolorchange(function(hue, saturation, value)
        if overlayAccent.Parent then
            overlayAccent.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
        end
    end)

    makeDraggable(ah)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = ag.Size
    icon.Position = UDim2.fromOffset(12, (icon.Size.X.Offset > 14 and 14 or 13))
    icon.BackgroundTransparency = 1
    icon.Image = ag.Icon or u("badscript/assets/new/textguiicon.png")
    icon.ImageColor3 = o.Text
    icon.Parent = ah

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -64, 0, 41)
    title.Position = UDim2.fromOffset(36, 0)
    title.BackgroundTransparency = 1
    title.Text = ag.DisplayName or ag.Name
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = o.TextStrong
    title.TextSize = 13
    title.FontFace = o.FontSemiBold
    title.Parent = ah

    local pin = Instance.new("ImageButton")
    pin.Name = "Pin"
    pin.Size = UDim2.fromOffset(18, 18)
    pin.Position = UDim2.new(1, -28, 0, 11)
    pin.BackgroundTransparency = 1
    pin.AutoButtonColor = false
    pin.Image = u("badscript/assets/new/pin.png")
    pin.ImageColor3 = ai.Pinned and o.Text or o.FaintText
    pin.Visible = not ag.Pinned
    pin.Parent = ah
    addTooltip(pin, "Keep this display visible while the menu is closed")

    local content = Instance.new("Frame")
    content.Name = "CustomChildren"
    content.Size = UDim2.new(1, 0, 0, contentHeight)
    content.Position = UDim2.fromScale(0, 1)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ClipsDescendants = false
    content.Parent = ah

    ah.MouseEnter:Connect(function()
        n:Tween(ah, o.TweenFast, { BackgroundColor3 = o.Elevated })
        n:Tween(overlayStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.38,
        })
    end)
    ah.MouseLeave:Connect(function()
        n:Tween(ah, o.TweenFast, { BackgroundColor3 = o.MainSoft })
        n:Tween(overlayStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.58,
        })
    end)

    for componentName in H do
        ai["Create" .. componentName] = function(_, settings)
            local creator = moduleApi["Create" .. componentName]
            if type(creator) ~= "function" then
                return nil
            end
            local option = creator(moduleApi, settings)
            ai.Options = moduleApi.Options
            return option
        end
        ai["Add" .. componentName] = ai["Create" .. componentName]
    end

    function ai.Expand()
        -- Overlay settings live in the ordinary Render module options pane.
        return false
    end

    function ai.Pin(self, forced)
        local nextPinned = forced
        if nextPinned == nil then
            nextPinned = not self.Pinned
        end
        if ag.Pinned then
            nextPinned = true
        end
        self.Pinned = nextPinned == true
        pin.ImageColor3 = self.Pinned and o.Text or o.FaintText
        self:Update()
    end

    function ai.Update(self)
        local enabled = moduleApi.Enabled == true
        local showChrome = v.Visible == true

        ah.Visible = enabled and (showChrome or self.Pinned)
        content.Visible = enabled
        ah.Size = UDim2.fromOffset(width, showChrome and 41 or 0)
        ah.BackgroundTransparency = showChrome and 0 or 1
        overlayStroke.Enabled = showChrome
        overlayShadow.Visible = showChrome
        overlayAccent.Visible = showChrome
        icon.Visible = showChrome
        title.Visible = showChrome
        pin.Visible = showChrome and not ag.Pinned
    end

    pin.Activated:Connect(function()
        ai:Pin()
    end)

    af:Clean(v:GetPropertyChangedSignal("Visible"):Connect(function()
        ai:Update()
    end))

    ah.Destroying:Once(function()
        cleanOverlayConnections()
        if ai._FunctionThread then
            pcall(task.cancel, ai._FunctionThread)
            ai._FunctionThread = nil
        end
    end)

    ai.Object = ah
    ai.Children = content
    af.Overlays[ag.Name] = ai
    af.Categories[ag.Name] = ai

    ai:Update()
    return ai
end

local af = Instance.new("BindableEvent")

-- BADWARS_PUBLIC_CONFIGS_DISABLED_V1_BEGIN
function d.CreateProfilesGUI(ag, ah)
    ag.PublicConfigs = nil
    d.ConfigsAPIRefresh = function() end
    shared.BadWarsPublicConfigsEnabled = false
    return nil
end
-- BADWARS_PUBLIC_CONFIGS_DISABLED_V1_END

function d.CreateCategoryList(ag, ah)
    local ai = {
        Type = "CategoryList",
        Expanded = false,
        List = {},
        ListEnabled = {},
        Objects = {},
        Options = {},
    }
    ah.Color = ah.Color or Color3.fromRGB(5, 134, 105)

    local aj = Instance.new("TextButton")
    aj.Name = ah.Name .. "CategoryList"
    aj.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, UI_HEADER_HEIGHT)
    aj.Position = UDim2.fromOffset(240, 46)
    aj.BackgroundColor3 = o.MainSoft
    aj.AutoButtonColor = false
    aj.Visible = false
    local ak
    if ah.Profiles then
        aj.AnchorPoint = Vector2.new(0.5, 0.5)
        aj.Position = UDim2.fromScale(0.5, 0.5)
        aj.Visible = true
        local al = Instance.new("UIScale")
        al.Scale = 1
        al.Parent = aj
        local am = Instance.new("UIStroke")
        am.Parent = aj
        am.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        am.Thickness = 0
        connectguicolorchange(function(an, ao, ap)
            local aq = Color3.fromHSV(an, ao, ap)
            if not ag.NewUser then
                am.Color = m.Light(aq, 0.2)
            else
                am.Color = Color3.fromRGB(255, 255, 255)
            end
        end)
        local an = false

        d.ProfilesCategoryListWindow = {
            window = aj,
            scale = al,
            stroke = am,
            globeicon = ak,
            setup = function(ao)
                aj.AnchorPoint = Vector2.new(0.5, 0.5)
                aj.Position = UDim2.fromScale(0.5, 0.5)
                aj.Visible = true
                al.Scale = 1
                am.Thickness = 0
                ao.globeicon = ak
                if not an then
                    an = true
                    aj.MouseEnter:Connect(function()
                        n:Tween(am, TweenInfo.new(0.15), {
                            Thickness = 3,
                        })
                    end)
                    aj.MouseLeave:Connect(function()
                        n:Tween(am, TweenInfo.new(0.15), {
                            Thickness = 0,
                        })
                    end)
                end
                return ao
            end,
        }
    end
    aj.Text = ""
    aj.Parent = v
    addShadow(aj)
    addCorner(aj, o.RadiusLarge)
    local categoryListStroke = addStroke(aj, o.BorderStrong, 0.3, 1, "CategoryListStroke")
    addSurfaceGradient(aj)
    local categoryListAccent = addAccentLine(aj, 2)
    addV9Chrome(aj)
    local categoryListScale = addScale(aj)
    makeDraggable(aj)

    aj:GetPropertyChangedSignal("Visible"):Connect(function()
        if aj.Visible then
            categoryListScale.Scale = 0.975
            categoryListAccent.BackgroundTransparency = 1
            n:Spring(categoryListScale, o.SpringPanel, { Scale = 1 })
            n:Tween(categoryListAccent, o.TweenSlow, { BackgroundTransparency = 0 })
        end
    end)
    local al = Instance.new("ImageLabel")
    al.Name = "Icon"
    al.Size = ah.Size
    al.Position = ah.Position or UDim2.fromOffset(12, (ah.Size.X.Offset > 20 and 13 or 12))
    al.BackgroundTransparency = 1
    al.Image = ah.Icon
    al.ImageColor3 = o.Text
    al.Parent = aj
    local am = Instance.new("TextLabel")
    am.Name = "Title"
    am.Size = UDim2.new(1, -(ah.Size.X.Offset > 20 and 44 or 36), 0, 20)
    am.Position = UDim2.fromOffset(math.abs(am.Size.X.Offset) + 2, 12)
    am.BackgroundTransparency = 1
    am.Text = ah.Name
    am.TextXAlignment = Enum.TextXAlignment.Left
    am.TextColor3 = o.Text
    am.TextSize = 14
    am.FontFace = o.FontSemiBold
    am.Parent = aj
    local an = Instance.new("TextButton")
    an.Name = "Arrow"
    an.Size = UDim2.fromOffset(46, 46)
    an.Position = UDim2.new(1, -48, 0, 5)
    an.BackgroundTransparency = 1
    an.Text = ""
    an.Parent = aj
    local ao = Instance.new("ImageLabel")
    ao.Name = "Arrow"
    ao.Size = UDim2.fromOffset(9, 4)
    ao.Position = UDim2.fromOffset(18, 19)
    ao.BackgroundTransparency = 1
    ao.Image = u("badscript/assets/new/expandup.png")
    ao.ImageColor3 = o.FaintText
    ao.Rotation = 180
    ao.Parent = an
    local ap = Instance.new("ScrollingFrame")
    ap.Name = "Children"
    ap.Size = UDim2.new(1, 0, 1, -UI_HEADER_HEIGHT)
    ap.Position = UDim2.fromOffset(0, UI_HEADER_HEIGHT)
    ap.BackgroundTransparency = 1
    ap.BorderSizePixel = 0
    ap.Visible = false
    ap.ScrollBarThickness = d.isMobile and 7 or 3
    ap.ScrollBarImageTransparency = d.isMobile and 0.35 or 0.58
    ap.ScrollBarImageColor3 = o.MutedText
    ap.CanvasSize = UDim2.new()
    ap.AutomaticCanvasSize = Enum.AutomaticSize.None
    ap.ScrollingDirection = Enum.ScrollingDirection.Y
    ap.ScrollingEnabled = true
    ap.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    ap.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    ap.Active = true
    ap.Selectable = true
    ap.ClipsDescendants = true
    ap.Parent = aj
    local aq = Instance.new("Frame")
    aq.BackgroundTransparency = 1
    aq.BackgroundColor3 = m.Dark(o.Main, 0.02)
    aq.Visible = false
    aq.Parent = ap
    local ar = Instance.new("ImageButton")
    ar.Name = "Settings"
    ar.Size = UDim2.fromOffset(16, 16)
    ar.Position = UDim2.new(1, -56, 0, 16)
    ar.BackgroundTransparency = 1
    ar.AutoButtonColor = false
    ar.Image = ah.Name ~= "Profiles" and u("badscript/assets/new/customsettings.png")
        or u("badscript/assets/new/worldicon.png")
    ar.ImageColor3 = o.FaintText
    ar.Parent = aj
    if ah.Profiles then
        ak = ar
        ar.Visible = false
        ar.Active = false
        ar.Selectable = false
        ar.Image = ""
    end
    local as = Instance.new("Frame")
    as.Name = "Divider"
    as.Size = UDim2.new(1, -20, 0, 1)
    as.Position = UDim2.fromOffset(10, UI_HEADER_HEIGHT - 2)
    as.BorderSizePixel = 0
    as.Visible = false
    as.BackgroundColor3 = Color3.new(1, 1, 1)
    as.BackgroundTransparency = 0.928
    as.Parent = aj
    local at = Instance.new("UIListLayout")
    at.SortOrder = Enum.SortOrder.LayoutOrder
    at.HorizontalAlignment = Enum.HorizontalAlignment.Center
    at.Padding = UDim.new(0, 3)
    at.Parent = ap
    local au = Instance.new("UIListLayout")
    au.SortOrder = Enum.SortOrder.LayoutOrder
    au.HorizontalAlignment = Enum.HorizontalAlignment.Center
    au.Parent = aq

    function ai.RefreshScroll(aC)
        local scale = getGuiScale()
        local contentHeight = math.max(0, math.ceil(at.AbsoluteContentSize.Y / scale) + 8)
        local viewport = (B and B.AbsoluteSize)
            or (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize)
            or Vector2.new(1280, 720)
        local viewportHeight = viewport.Y / scale
        local maximumHeight = math.max(176, math.min(614, viewportHeight - 72))
        local targetHeight = aC.Expanded and math.min(UI_HEADER_HEIGHT + contentHeight + 6, maximumHeight) or UI_HEADER_HEIGHT

        ap.CanvasSize = UDim2.fromOffset(0, contentHeight)
        local visibleCanvasHeight = math.max(0, targetHeight - UI_HEADER_HEIGHT)
        local maximumCanvasY = math.max(0, contentHeight - visibleCanvasHeight)
        if ap.CanvasPosition.Y > maximumCanvasY then
            ap.CanvasPosition = Vector2.new(0, maximumCanvasY)
        end

        if aC.Expanded then
            aj.Size = UDim2.fromOffset(UI_WINDOW_WIDTH, targetHeight)
        end
        return targetHeight
    end

    local av
    local aw
    if ah.Profiles then
        av = H.Button({
            Name = "Sync to 'default' profile",
            Function = function()
                local ax = d.Profile
                d.Profile = "default"
                d:Save("default")
                d:Load(true, "default")
                local ay = Color3ToHex(Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value))
                local az = "#ffffff"
                local aA = ([[Transferred Data from <font color="%s"><b>%s</b></font> to <font color="%s"><b>default</b></font> Profile]]):format(
                    ay,
                    tostring(ax),
                    az
                )
                d:CreateNotification("BadWars", aA, 3)
            end,
            Tooltip = "Transfers your current profile to the 'default' one",
            Visible = false,
            BackgroundTransparency = 1,
        }, ap, { Options = {} })
        aw = H.Button({
            Name = "Create new profile",
            Function = function()
                d:CreatePrompt({
                    Title = "Create Profile",
                    Text = "Choose a name for your new profile.",
                    Input = true,
                    InputPlaceholder = "What should the profile be called?",
                    OnConfirm = function(ax)
                        if ax and ax ~= "" then
                            for ay, az in d.Profiles do
                                if tostring(az.Name) == ax then
                                    d:CreateNotification("BadWars", `Profile {tostring(ax)} already exists!`, 3)
                                    return
                                end
                            end
                            table.insert(d.Profiles, { Name = ax, Bind = {} })
                            d:Save(ax, true)
                            d:Load(ax)
                        else
                            d:CreateNotification("BadWars", "No Profile Name given", 3)
                        end
                    end,
                })
            end,
            Tooltip = "Creates a brand new profile",
            Visible = false,
            BackgroundTransparency = 1,
        }, ap, { Options = {} })
        H.Button({
            Name = "Reset current profile",
            Function = function()
                d:CreatePrompt({
                    Title = "Reset Profile",
                    Text = "Are you sure you want to <b><font color='#ff5a5a'>delete</font></b> your current profile?\n<font color='#ff7777'><i>This action cannot be undone.</i></font>",
                    ConfirmText = "Yes",
                    CancelText = "Nevermind",
                    ConfirmColor = Color3.fromRGB(120, 40, 40),
                    ConfirmHoverColor = Color3.fromRGB(170, 60, 60),
                    CancelColor = Color3.fromRGB(40, 120, 40),
                    CancelHoverColor = Color3.fromRGB(60, 170, 60),
                    OnConfirm = function()
                        d.Save = function() end
                        if D("badscript/profiles/" .. d.Profile .. d.Place .. ".txt") and delfile then
                            delfile("badscript/profiles/" .. d.Profile .. d.Place .. ".txt")
                        end
                        shared.BadReload = true
                        if shared.BadDeveloper then
                            loadstring(readfile("badscript/loader.lua"), "loader")()
                        else
                            loadstring(
                                d.http_function(
                                    "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua",
                                    true
                                ),
                                "loader"
                            )()
                        end
                    end,
                    OnCancel = function() end,
                })
            end,
            Tooltip = "This will set your profile to the default BadWars settings",
            BackgroundTransparency = 1,
        }, ap, { Options = {} })
    end
    local ax = Instance.new("Frame")
    ax.Name = "Add"
    ax.Size = UDim2.new(1, -20, 0, 36)
    ax.Position = UDim2.fromOffset(10, 48)
    ax.BackgroundColor3 = o.Surface
    ax.Parent = ap
    addCorner(ax, o.Radius)
    addStroke(ax, o.Border, 0.62, 1, "AddFieldStroke")
    local ay = ax:Clone()
    ay.Size = UDim2.new(1, -2, 1, -2)
    ay.Position = UDim2.fromOffset(1, 1)
    ay.BackgroundTransparency = 1
    ay.Parent = ax
    local az = Instance.new("TextBox")
    az.Size = UDim2.new(1, -35, 1, 0)
    az.Position = UDim2.fromOffset(10, 0)
    az.BackgroundTransparency = 1
    az.Text = ""
    az.PlaceholderText = ah.Placeholder or "Add entry..."
    az.TextXAlignment = Enum.TextXAlignment.Left
    az.TextColor3 = Color3.new(1, 1, 1)
    az.TextSize = 15
    az.FontFace = o.Font
    az.ClearTextOnFocus = false
    az.Parent = ax
    local aA = Instance.new("ImageButton")
    aA.Name = "AddButton"
    aA.Size = UDim2.fromOffset(16, 16)
    aA.Position = UDim2.new(1, -26, 0, 8)
    aA.BackgroundTransparency = 1
    aA.Image = u("badscript/assets/new/add.png")
    aA.ImageColor3 = ah.Color
    aA.ImageTransparency = 0.3
    aA.Parent = ax
    local aB = Instance.new("Frame")
    aB.Size = UDim2.fromOffset()
    aB.BackgroundTransparency = 1
    aB.Parent = ap
    ah.Function = ah.Function or function() end

    local function profilesButtonRefresh()
        if not ah.Profiles then
            return
        end
        local aC = ag.Profile
        if not aC then
            if shared.VoidDev then
                bwarn("profilesButtonRefresh: local profile not found!")
            end
            return
        end
        av:SetVisible(aC ~= "default")
        aw:SetVisible(aC == "default")
    end

    function ai.ChangeValue(aC, aD)
        if aD then
            if ah.Profiles then
                local aE = aC:GetValue(aD)
                if aE then
                    if aD ~= "default" then
                        table.remove(d.Profiles, aE)
                        if D("badscript/profiles/" .. aD .. d.Place .. ".txt") and delfile then
                            delfile("badscript/profiles/" .. aD .. d.Place .. ".txt")
                        end
                    end
                else
                    table.insert(d.Profiles, { Name = aD, Bind = {} })
                end
                if d.ConfigsAPIRefresh then
                    pcall(d.ConfigsAPIRefresh)
                end
                profilesButtonRefresh()
            else
                local aE = table.find(aC.List, aD)
                if aE then
                    table.remove(aC.List, aE)
                    aE = table.find(aC.ListEnabled, aD)
                    if aE then
                        table.remove(aC.ListEnabled, aE)
                    end
                else
                    table.insert(aC.List, aD)
                    table.insert(aC.ListEnabled, aD)
                end
            end
        end

        ah.Function()
        if ah.Profiles then
            profilesButtonRefresh()
        end
        for aE, aF in aC.Objects do
            aF:Destroy()
        end
        table.clear(aC.Objects)
        aC.Selected = nil

        for aE, aF in (ah.Profiles and d.Profiles or aC.List) do
            if ah.Profiles then
                local aH = Instance.new("TextButton")
                aH.Name = aF.Name
                aH.Size = UDim2.fromOffset(200, 33)
                aH.BackgroundColor3 = m.Light(o.Main, 0.02)
                aH.AutoButtonColor = false
                aH.Text = ""
                aH.Parent = ap
                addCorner(aH)
                local aI = Instance.new("UIStroke")
                aI.Color = m.Light(o.Main, 0.1)
                aI.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                aI.Enabled = false
                aI.Parent = aH
                local aJ = Instance.new("TextLabel")
                aJ.Name = "Title"
                aJ.Size = UDim2.new(1, -10, 1, 0)
                aJ.Position = UDim2.fromOffset(10, 0)
                aJ.BackgroundTransparency = 1
                aJ.Text = aF.Name
                aJ.TextTruncate = Enum.TextTruncate.AtEnd
                aJ.TextXAlignment = Enum.TextXAlignment.Left
                aJ.TextColor3 = m.Dark(o.Text, 0.4)
                aJ.TextSize = 15
                aJ.FontFace = o.Font
                aJ.Parent = aH
                local aK = Instance.new("TextButton")
                aK.Name = "Dots"
                aK.Size = UDim2.fromOffset(25, 33)
                aK.Position = UDim2.new(1, -25, 0, 0)
                aK.BackgroundTransparency = 1
                aK.Text = ""
                aK.Parent = aH
                local aL = Instance.new("ImageLabel")
                aL.Name = "Dots"
                aL.Size = UDim2.fromOffset(3, 16)
                aL.Position = UDim2.fromOffset(10, 9)
                aL.BackgroundTransparency = 1
                aL.Image = u("badscript/assets/new/dots.png")
                aL.ImageColor3 = m.Light(o.Main, 0.37)
                aL.Parent = aK
                local aM = Instance.new("TextButton")
                addTooltip(aM, "Click to bind")
                aM.Name = "Bind"
                aM.Size = UDim2.fromOffset(20, 21)
                aM.Position = UDim2.new(1, -30, 0, 6)
                aM.AnchorPoint = Vector2.new(1, 0)
                aM.BackgroundColor3 = Color3.new(1, 1, 1)
                aM.BackgroundTransparency = 0.92
                aM.BorderSizePixel = 0
                aM.AutoButtonColor = false
                aM.Visible = false
                aM.Text = ""
                addCorner(aM, UDim.new(0, 4))
                local aN = Instance.new("ImageLabel")
                aN.Name = "Icon"
                aN.Size = UDim2.fromOffset(12, 12)
                aN.Position = UDim2.new(0.5, -6, 0, 5)
                aN.BackgroundTransparency = 1
                aN.Image = u("badscript/assets/new/bind.png")
                aN.ImageColor3 = m.Dark(o.Text, 0.43)
                aN.Parent = aM
                local aO = Instance.new("TextLabel")
                aO.Size = UDim2.fromScale(1, 1)
                aO.Position = UDim2.fromOffset(0, 1)
                aO.BackgroundTransparency = 1
                aO.Visible = false
                aO.Text = ""
                aO.TextColor3 = m.Dark(o.Text, 0.43)
                aO.TextSize = 12
                aO.FontFace = o.Font
                aO.Parent = aM
                aM.MouseEnter:Connect(function()
                    aO.Visible = false
                    aN.Visible = not aO.Visible
                    aN.Image = u("badscript/assets/new/edit.png")
                    if aF.Name ~= d.Profile then
                        aN.ImageColor3 = m.Dark(o.Text, 0.16)
                    end
                end)
                aM.MouseLeave:Connect(function()
                    aO.Visible = #aF.Bind > 0
                    aN.Visible = not aO.Visible
                    aN.Image = u("badscript/assets/new/bind.png")
                    if aF.Name ~= d.Profile then
                        aN.ImageColor3 = m.Dark(o.Text, 0.43)
                    end
                end)
                local aP = Instance.new("ImageLabel")
                aP.Name = "Cover"
                aP.Size = UDim2.fromOffset(154, 33)
                aP.BackgroundTransparency = 1
                aP.Visible = false
                aP.Image = u("badscript/assets/new/bindbkg.png")
                aP.ScaleType = Enum.ScaleType.Slice
                aP.SliceCenter = Rect.new(0, 0, 141, 40)
                aP.Parent = aH
                local aQ = Instance.new("TextLabel")
                aQ.Name = "Text"
                aQ.Size = UDim2.new(1, -10, 1, -3)
                aQ.BackgroundTransparency = 1
                aQ.Text = "PRESS A KEY TO BIND"
                aQ.TextColor3 = o.Text
                aQ.TextSize = 11
                aQ.FontFace = o.Font
                aQ.Parent = aP
                aM.Parent = aH
                aK.MouseEnter:Connect(function()
                    if aF.Name ~= d.Profile then
                        aL.ImageColor3 = o.Text
                    end
                end)
                aK.MouseLeave:Connect(function()
                    if aF.Name ~= d.Profile then
                        aL.ImageColor3 = m.Light(o.Main, 0.37)
                    end
                end)
                aK.Activated:Connect(function()
                    if aF.Name ~= d.Profile then
                        ai:ChangeValue(aF.Name)
                    end
                end)
                aH.Activated:Connect(function()
                    d:Save(aF.Name, not D("badscript/profiles/" .. aF.Name .. d.Place .. ".txt"))
                    d:Load(true, aF.Name)
                end)
                aH.MouseEnter:Connect(function()
                    aM.Visible = true
                    if aF.Name ~= d.Profile then
                        aI.Enabled = true
                        aJ.TextColor3 = m.Dark(o.Text, 0.16)
                    end
                end)
                aH.MouseLeave:Connect(function()
                    aM.Visible = #aF.Bind > 0
                    if aF.Name ~= d.Profile then
                        aI.Enabled = false
                        aJ.TextColor3 = m.Dark(o.Text, 0.4)
                    end
                end)

                local function bindFunction(aR, aS, aT)
                    aF.Bind = table.clone(aS)
                    if aT then
                        aQ.Text = #aS <= 0 and "BIND REMOVED" or "BOUND TO " .. table.concat(aS, " + "):upper()
                        aP.Size = UDim2.fromOffset(E(aQ.Text, aQ.TextSize).X + 20, 40)
                        task.delay(1, function()
                            aP.Visible = false
                        end)
                    end

                    if #aS <= 0 then
                        aO.Visible = false
                        aN.Visible = true
                        aM.Size = UDim2.fromOffset(20, 21)
                    else
                        aM.Visible = true
                        aO.Visible = true
                        aN.Visible = false
                        aO.Text = table.concat(aS, " + "):upper()
                        aM.Size = UDim2.fromOffset(math.max(E(aO.Text, aO.TextSize, aO.Font).X + 10, 20), 21)
                    end
                end

                bindFunction({}, aF.Bind)
                aM.Activated:Connect(function()
                    aQ.Text = "PRESS A KEY TO BIND"
                    aP.Size = UDim2.fromOffset(E(aQ.Text, aQ.TextSize).X + 20, 40)
                    aP.Visible = true
                    table.clear(d.HeldKeybinds)
                    d.Binding = { SetBind = bindFunction, Bind = aF.Bind }
                end)
                if aF.Name == d.Profile then
                    aC.Selected = aH
                end
                table.insert(aC.Objects, aH)
            else
                local aH = table.find(aC.ListEnabled, aF)
                local aI = Instance.new("TextButton")
                aI.Name = aF
                aI.Size = UDim2.fromOffset(200, 32)
                aI.BackgroundColor3 = m.Light(o.Main, 0.02)
                aI.AutoButtonColor = false
                aI.Text = ""
                aI.Parent = ap
                addCorner(aI)
                local aJ = Instance.new("Frame")
                aJ.Name = "BKG"
                aJ.Size = UDim2.new(1, -2, 1, -2)
                aJ.Position = UDim2.fromOffset(1, 1)
                aJ.BackgroundColor3 = o.Main
                aJ.Visible = false
                aJ.Parent = aI
                addCorner(aJ)
                local aK = Instance.new("Frame")
                aK.Name = "Dot"
                aK.Size = UDim2.fromOffset(10, 11)
                aK.Position = UDim2.fromOffset(10, 12)
                aK.BackgroundColor3 = aH and ah.Color or m.Light(o.Main, 0.37)
                aK.Parent = aI
                addCorner(aK, UDim.new(1, 0))
                local aL = aK:Clone()
                aL.Size = UDim2.fromOffset(8, 9)
                aL.Position = UDim2.fromOffset(1, 1)
                aL.BackgroundColor3 = aH and ah.Color or m.Light(o.Main, 0.02)
                aL.Parent = aK
                local aM = Instance.new("TextLabel")
                aM.Name = "Title"
                aM.Size = UDim2.new(1, -30, 1, 0)
                aM.Position = UDim2.fromOffset(30, 0)
                aM.BackgroundTransparency = 1
                aM.Text = aF
                aM.TextXAlignment = Enum.TextXAlignment.Left
                aM.TextColor3 = m.Dark(o.Text, 0.16)
                aM.TextSize = 15
                aM.FontFace = o.Font
                aM.Parent = aI
                if d.ThreadFix then
                    setthreadidentity(8)
                end
                local aN = Instance.new("ImageButton")
                aN.Name = "Close"
                aN.Size = UDim2.fromOffset(16, 16)
                aN.Position = UDim2.new(1, -23, 0, 8)
                aN.BackgroundColor3 = Color3.new(1, 1, 1)
                aN.BackgroundTransparency = 1
                aN.AutoButtonColor = false
                aN.Image = u("badscript/assets/new/closemini.png")
                aN.ImageColor3 = m.Light(o.Text, 0.2)
                aN.ImageTransparency = 0.5
                aN.Parent = aI
                addCorner(aN, UDim.new(1, 0))
                aN.MouseEnter:Connect(function()
                    aN.ImageTransparency = 0.3
                    n:Tween(aN, o.Tween, {
                        BackgroundTransparency = 0.6,
                    })
                end)
                aN.MouseLeave:Connect(function()
                    aN.ImageTransparency = 0.5
                    n:Tween(aN, o.Tween, {
                        BackgroundTransparency = 1,
                    })
                end)
                aN.Activated:Connect(function()
                    ai:ChangeValue(aF)
                end)
                aI.MouseEnter:Connect(function()
                    aJ.Visible = true
                end)
                aI.MouseLeave:Connect(function()
                    aJ.Visible = false
                end)
                aI.Activated:Connect(function()
                    local aO = table.find(aC.ListEnabled, aF)
                    if aO then
                        table.remove(aC.ListEnabled, aO)
                        aK.BackgroundColor3 = m.Light(o.Main, 0.37)
                        aL.BackgroundColor3 = m.Light(o.Main, 0.02)
                    else
                        table.insert(aC.ListEnabled, aF)
                        aK.BackgroundColor3 = ah.Color
                        aL.BackgroundColor3 = ah.Color
                    end
                    ah.Function()
                end)
                table.insert(aC.Objects, aI)
            end
        end
        d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        task.defer(function()
            if ap.Parent then
                ai:RefreshScroll()
            end
        end)
    end

    function ai.Expand(aC)
        aC.Expanded = not aC.Expanded
        if aC.Expanded then
            ap.Visible = true
        end

        n:Tween(ao, o.TweenFast, {
            Rotation = aC.Expanded and 0 or 180,
            ImageColor3 = aC.Expanded and o.Text or o.FaintText,
        })

        local targetHeight = aC:RefreshScroll()

        local tween = n:Tween(aj, o.TweenSlow, {
            Size = UDim2.fromOffset(UI_WINDOW_WIDTH, targetHeight),
        })

        if not aC.Expanded and tween then
            tween.Completed:Once(function(playbackState)
                if playbackState == Enum.PlaybackState.Completed and not aC.Expanded then
                    ap.Visible = false
                end
            end)
        end

        as.Visible = ap.CanvasPosition.Y > 10 and ap.Visible
    end

    function ai.GetValue(aC, aD)
        for aE, aF in d.Profiles do
            if aF.Name == aD then
                return aE
            end
        end
    end

    for aC, aD in H do
        ai["Create" .. aC] = function(aE, aF)
            return aD(aF, aq, ai)
        end
        ai["Add" .. aC] = ai["Create" .. aC]
    end

    aA.MouseEnter:Connect(function()
        aA.ImageTransparency = 0
    end)
    aA.MouseLeave:Connect(function()
        aA.ImageTransparency = 0.3
    end)
    aA.Activated:Connect(function()
        if not table.find(ai.List, az.Text) then
            if az.Text == "" or az.Text == "Invalid Name!" then
                d:CreateNotification("BadWars", "You need to specify a value!", 3)
                flickerTextEffect(az, true, "Invalid Name!")
                task.delay(0.5, function()
                    flickerTextEffect(az, true, "")
                end)
                return
            end
            ai:ChangeValue(az.Text)
            az.Text = ""
        end
    end)
    an.MouseEnter:Connect(function()
        ao.ImageColor3 = o.TextStrong
        n:Tween(categoryListStroke, o.TweenFast, {
            Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
            Transparency = 0.16,
        })
        n:Spring(categoryListScale, o.SpringInteractive, { Scale = 1.008 })
    end)
    an.MouseLeave:Connect(function()
        ao.ImageColor3 = o.FaintText
        n:Tween(categoryListStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.3,
        })
        n:Spring(categoryListScale, o.SpringInteractive, { Scale = 1 })
    end)
    an.MouseButton1Down:Connect(function()
        n:Spring(categoryListScale, o.SpringInteractive, { Scale = 0.992 })
    end)
    an.MouseButton1Up:Connect(function()
        n:Spring(categoryListScale, o.SpringInteractive, { Scale = 1.008 })
    end)
    an.Activated:Connect(function()
        ai:Expand()
    end)
    az.FocusLost:Connect(function(aC)
        if aC and not table.find(ai.List, az.Text) then
            ai:ChangeValue(az.Text)
            az.Text = ""
        end
    end)
    az.MouseEnter:Connect(function()
        n:Tween(ax, o.Tween, {
            BackgroundColor3 = m.Light(o.Main, 0.14),
        })
    end)
    az.MouseLeave:Connect(function()
        n:Tween(ax, o.Tween, {
            BackgroundColor3 = m.Light(o.Main, 0.02),
        })
    end)
    ap:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        as.Visible = ap.CanvasPosition.Y > 10 and ap.Visible
    end)
    ap.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseWheel or not ai.Expanded then
            return
        end

        local before = ap.CanvasPosition.Y
        local wheelDelta = input.Position.Z
        task.defer(function()
            if not ap.Parent or ap.CanvasPosition.Y ~= before then
                return
            end
            local maximum = math.max(0, ap.AbsoluteCanvasSize.Y - ap.AbsoluteWindowSize.Y)
            ap.CanvasPosition = Vector2.new(0, math.clamp(before - (wheelDelta * 42), 0, maximum))
        end)
    end)
    ar.MouseEnter:Connect(function()
        ar.ImageColor3 = o.Text
    end)
    ar.MouseLeave:Connect(function()
        ar.ImageColor3 = m.Light(o.Main, 0.37)
    end)

    if ah.Profiles then
        ag.PublicConfigs = nil
        d.ConfigsAPIRefresh = function() end
    end

    ar.Activated:Connect(function()
        if ah.Profiles then
            return
        end
        aq.Visible = not aq.Visible
    end)
    connectDeferredPropertyChanged(at, "AbsoluteContentSize", function()
        if ag.ThreadFix then
            setthreadidentity(8)
        end
        ai:RefreshScroll()
    end)
    connectDeferredPropertyChanged(au, "AbsoluteContentSize", function()
        if ag.ThreadFix then
            setthreadidentity(8)
        end
        local targetSize = UDim2.fromOffset(220, au.AbsoluteContentSize.Y)
        if aq.Size ~= targetSize then
            aq.Size = targetSize
        end
    end)

    ai.Button = ag.Categories.Main:CreateButton({
        Name = ah.Name,
        Icon = ah.CategoryIcon,
        Size = ah.CategorySize,
        Window = aj,
        Default = ah.Profiles,
    })

    ai.Object = aj
    ag.Categories[ah.Name] = ai

    if ah.Profiles and not ai.Expanded then
        ai:Expand()
    else
        task.defer(function()
            if ap.Parent then
                ai:RefreshScroll()
            end
        end)
    end

    return ai
end

local function removeSpaces(ag)
    return (ag:gsub("%s+", ""))
end

local function highlightIgnoringSpaces(ag, ah)
    if not ah or ah == "" then
        return ag
    end
    local ai = removeSpaces(ag):lower()
    local aj = removeSpaces(ah):lower()
    local ak, al = ai:find(aj, 1, true)
    if not ak then
        return ag
    end

    local am, an
    local ao = 0
    for ap = 1, #ag do
        local aq = ag:sub(ap, ap)
        if aq ~= " " then
            ao += 1
            if ao == ak and not am then
                am = ap
            end
            if ao == al then
                an = ap
                break
            end
        end
    end
    if not am or not an then
        return ag
    end
    local ap = ag:sub(1, am - 1)
    local aq = ag:sub(am, an)
    local ar = ag:sub(an + 1)
    return ap .. `<font color="#ffffff"><b>{aq}</b></font>` .. ar
end

local function createHighlight(ag)
    local ah = Instance.new("Frame")
    ah.Size = UDim2.fromScale(1, 1)
    ah.BackgroundColor3 = Color3.new(1, 1, 1)
    ah.BackgroundTransparency = 0.6
    ah.BorderSizePixel = 0
    ah.Parent = ag
    n:Tween(ah, TweenInfo.new(0.5), {
        BackgroundTransparency = 1,
    })
    task.delay(0.5, ah.Destroy, ah)
end

function d.CreateSearch(ag)
    local ah = Instance.new("Frame")
    ah.Name = "Search"
    ah.Size = UDim2.fromOffset(260, 42)
    ah.Position = UDim2.new(0.5, 0, 0, 13)
    ah.AnchorPoint = Vector2.new(0.5, 0)
    ah.BackgroundColor3 = o.Surface
    ah.Parent = v

    local ai = addScale(ah)
    ai.Scale = 1

    local aj = Instance.new("ImageLabel")
    aj.Name = "Icon"
    aj.Size = UDim2.fromOffset(14, 14)
    aj.Position = UDim2.new(1, -28, 0, 14)
    aj.BackgroundTransparency = 1
    aj.Image = u("badscript/assets/new/search.png")
    aj.ImageColor3 = o.FaintText
    aj.Parent = ah

    local ak = Instance.new("ImageButton")
    ak.Name = "Legit"
    ak.Size = UDim2.fromOffset(29, 16)
    ak.Position = UDim2.fromOffset(10, 13)
    ak.BackgroundTransparency = 1
    ak.Image = u("badscript/assets/new/legit.png")
    ak.Parent = ah

    local al = Instance.new("Frame")
    al.Name = "LegitDivider"
    al.Size = UDim2.fromOffset(2, 12)
    al.Position = UDim2.fromOffset(46, 15)
    al.BackgroundColor3 = o.Border
    al.BorderSizePixel = 0
    al.Parent = ah

    addShadow(ah)
    addCorner(ah, o.RadiusLarge)
    addSurfaceGradient(ah)
    local searchStroke = addStroke(ah, o.BorderStrong, 0.36, 1, "SearchStroke")
    local searchAccent = addAccentLine(ah, 2)
    addV9Chrome(ah)
    local am

    if not d.isMobile then
        ah.MouseEnter:Connect(function()
            n:Spring(ai, o.SpringInteractive, { Scale = 1.016 })
            n:Tween(searchStroke, o.TweenFast, {
                Color = o.BorderStrong,
                Transparency = 0.2,
            })
        end)
        ah.MouseLeave:Connect(function()
            if not am or not am:IsFocused() then
                n:Spring(ai, o.SpringInteractive, { Scale = 1 })
                n:Tween(searchStroke, o.TweenFast, {
                    Color = o.BorderStrong,
                    Transparency = 0.36,
                })
            end
        end)
    end

    am = Instance.new("TextBox")
    am.Size = UDim2.new(1, -60, 0, 42)
    am.Position = UDim2.fromOffset(54, 0)
    am.BackgroundTransparency = 1
    am.Text = ""
    am.PlaceholderText = ""
    am.TextXAlignment = Enum.TextXAlignment.Left
    am.TextColor3 = o.Text
    am.TextSize = 13
    am.FontFace = o.FontSemiBold
    am.ClearTextOnFocus = false
    am.Parent = ah

    local an = Instance.new("ScrollingFrame")
    an.Name = "Children"
    an.Size = UDim2.new(1, 0, 1, -42)
    an.Position = UDim2.fromOffset(0, 40)
    an.BackgroundTransparency = 1
    an.BorderSizePixel = 0
    an.ScrollBarThickness = d.isMobile and 8 or 2
    an.ScrollBarImageTransparency = d.isMobile and 0.4 or 0.75
    an.CanvasSize = UDim2.new()
    an.Parent = ah

    local ao = Instance.new("Frame")
    ao.Name = "Divider"
    ao.Size = UDim2.new(1, -24, 0, 1)
    ao.Position = UDim2.fromOffset(12, 40)
    ao.BackgroundColor3 = o.Border
    ao.BackgroundTransparency = 0.72
    ao.BorderSizePixel = 0
    ao.Visible = false
    ao.Parent = ah

    local ap = Instance.new("UIListLayout")
    ap.SortOrder = Enum.SortOrder.LayoutOrder
    ap.HorizontalAlignment = Enum.HorizontalAlignment.Center
    ap.Padding = UDim.new(0, 2)
    ap.Parent = an

    an:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        ao.Visible = an.CanvasPosition.Y > 10 and an.Visible
    end)

    ak.Activated:Connect(function()
        v.Visible = false
        local legitCategory = ag.Categories and ag.Categories.Legit
        if legitCategory and legitCategory.Button then
            legitCategory.Button:Toggle(true)
        elseif ag.Legit and ag.Legit.Window then
            ag.Legit.Window.Visible = true
        end
        if ag.Legit and ag.Legit.Window then
            ag.Legit.Window.Position = UDim2.new(0.5, -350, 0.5, -194)
        end
    end)

    local aq = false
    local ar

    am:GetPropertyChangedSignal("Text"):Connect(function()
        if ar ~= nil then
            pcall(task.cancel, ar)
            ar = nil
        end

        for as, at in an:GetChildren() do
            if at:IsA("TextButton") then
                at:Destroy()
            end
        end

        if am.Text == "Type to search..." then
            return
        end
        if am.Text == "" then
            if not aq then
                flickerTextEffect(am, true, "Type to search...")
            end
            return
        end

        local as = am.Text

        ar = task.spawn(function()
            for at, au in ag.Modules do
                if not (au.Object and au.Object.Parent and au.Object:FindFirstChild("Bind")) then
                    continue
                end

                local av = removeSpaces(as:lower())
                local aw = removeSpaces(au.Name:lower())

                local ax = aw:find(av, 1, true)

                local ay
                if not ax and au.SearchKeys then
                    for az, aA in au.SearchKeys do
                        if removeSpaces(aA:lower()):find(av, 1, true) then
                            ay = aA
                            break
                        end
                    end
                end

                if not ax and not ay then
                    continue
                end

                local az = au.Object:Clone()
                az.RichText = true

                if ax then
                    az.Text = "            " .. highlightIgnoringSpaces(au.Name, as)
                else
                    local aA = math.floor(az.TextSize * 0.8)
                    az.Text = "            "
                        .. `<font size="{aA}" color="#AAAAAA">{au.Name}</font> `
                        .. highlightIgnoringSpaces(ay, as)
                end

                local aA = az:FindFirstChild("Bind")
                if aA then
                    aA:Destroy()
                end

                az.Activated:Connect(function()
                    au:Toggle()
                end)

                local function navigateToModule()
                    au.Object.Parent.Parent.Visible = true
                    local aB = au.Object.Parent
                    createHighlight(au.Object)
                    local aC = au.ModuleCategory
                    if aC ~= nil then
                        aC:Toggle(true)
                    end
                    local aD = au.CategoryApi
                    if aD ~= nil then
                        aD:ToggleCategoryButton(true)
                    end
                    n:Tween(aB, TweenInfo.new(0.5), {
                        CanvasPosition = Vector2.new(
                            0,
                            (au.Object.LayoutOrder * 40) - (math.min(aB.CanvasSize.Y.Offset, 600) / 2)
                        ),
                    })
                end
                az.MouseButton2Click:Connect(function()
                    if d.HideTooltip then
                        d.HideTooltip(true)
                    end
                    navigateToModule()
                end)

                if d.isMobile then
                    local aB
                    az.InputBegan:Connect(function(aC)
                        if aC.UserInputType == Enum.UserInputType.Touch then
                            aB = tick()
                        end
                    end)
                    az.InputEnded:Connect(function(aC)
                        if aC.UserInputType == Enum.UserInputType.Touch and aB then
                            if tick() - aB >= 0.5 then
                                navigateToModule()
                            end
                            aB = nil
                        end
                    end)
                end

                az.Parent = an
                az.Name = at:lower()

                task.spawn(function()
                    repeat
                        pcall(function()
                            for aB, aC in { "TextColor3", "BackgroundColor3" } do
                                az[aC] = au.Object[aC]
                            end
                            local aB = az:FindFirstChildOfClass("UIGradient")
                            local aC = au.Object:FindFirstChildOfClass("UIGradient")
                            if aB and aC then
                                aB.Color = aC.Color
                                aB.Enabled = aC.Enabled
                            end
                            local aD = az:FindFirstChild("Dots")
                            local aE = au.Object:FindFirstChild("Dots")
                            if aD and aE and aD:FindFirstChild("Dots") and aE:FindFirstChild("Dots") then
                                aD.Dots.ImageColor3 = aE.Dots.ImageColor3
                            end
                        end)
                        task.wait()
                    until not az.Parent
                end)
            end
        end)
    end)

    am.Focused:Connect(function()
        aq = true
        if am.Text == "Type to search..." then
            am.Text = ""
        end
        n:Spring(ai, o.SpringInteractive, { Scale = 1.018 })
        n:Tween(searchStroke, o.TweenFast, {
            Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
            Transparency = 0.12,
        })
        n:Tween(searchAccent, o.TweenFast, { BackgroundTransparency = 0 })
        aj.ImageColor3 = o.Text
    end)

    d:Clean(d.VisibilityChanged:Connect(function()
        if not aq and v.Visible then
            flickerTextEffect(am, true, "Type to search...")
        end
    end))

    am.FocusLost:Connect(function()
        aq = false
        if am.Text == "" then
            flickerTextEffect(am, true, "Type to search...")
        end
        n:Spring(ai, o.SpringInteractive, { Scale = 1 })
        n:Tween(searchStroke, o.TweenFast, {
            Color = o.BorderStrong,
            Transparency = 0.36,
        })
        aj.ImageColor3 = o.FaintText
    end)

    connectDeferredPropertyChanged(ap, "AbsoluteContentSize", function()
        if ag.ThreadFix then
            setthreadidentity(8)
        end
        local targetCanvasSize = UDim2.fromOffset(0, ap.AbsoluteContentSize.Y / A.Scale)
        if an.CanvasSize ~= targetCanvasSize then
            an.CanvasSize = targetCanvasSize
        end
        local targetSize = UDim2.fromOffset(260, math.min(42 + ap.AbsoluteContentSize.Y / A.Scale, 462))
        if ah.Size ~= targetSize then
            ah.Size = targetSize
        end
    end)

    d:Clean(d.PreloadEvent:Connect(function()
        flickerTextEffect(am, true, "Type to search...")
    end))

    ag.Legit.Icon = ak
end

function d.CreateLegit(ag)
    local ah = { Modules = {} }

    local ai = ag.Categories.Legit
    if not ai then
        bwarn("Legit category must be created before CreateLegit()")
        return
    end

    local aj = Instance.new("Frame")
    aj.Name = "LegitGUI"
    aj.Size = UDim2.fromOffset(700, 389)
    aj.Position = UDim2.new(0.5, -350, 0.5, -194)
    aj.BackgroundColor3 = o.MainSoft
    aj.Visible = false
    aj.Parent = w
    addShadow(aj)
    addCorner(aj, o.RadiusLarge)
    local legitStroke = addStroke(aj, o.BorderStrong, 0.24, 1, "LegitStroke")
    addSurfaceGradient(aj)
    local legitAccent = addAccentLine(aj, 3)
    addV9Chrome(aj)
    local legitScale = addScale(aj)
    makeDraggable(aj)

    aj:GetPropertyChangedSignal("Visible"):Connect(function()
        if aj.Visible then
            legitScale.Scale = 0.97
            legitAccent.BackgroundTransparency = 1
            n:Spring(legitScale, o.SpringPanel, { Scale = 1 })
            n:Tween(legitAccent, o.TweenSlow, { BackgroundTransparency = 0 })
        end
    end)

    local ak = Instance.new("TextButton")
    ak.BackgroundTransparency = 1
    ak.Text = ""
    ak.Modal = true
    ak.Parent = aj

    local al = Instance.new("ImageLabel")
    al.Name = "Icon"
    al.Size = UDim2.fromOffset(16, 16)
    al.Position = UDim2.fromOffset(18, 13)
    al.BackgroundTransparency = 1
    al.Image = u("badscript/assets/new/legittab.png")
    al.ImageColor3 = o.Text
    al.Parent = aj

    local am = addCloseButton(aj)

    local an = Instance.new("ScrollingFrame")
    an.Name = "Children"
    an.Size = UDim2.fromOffset(684, 340)
    an.Position = UDim2.fromOffset(14, 41)
    an.BackgroundTransparency = 1
    an.BorderSizePixel = 0
    an.ScrollBarThickness = 3
    an.ScrollBarImageTransparency = 0.35
    an.CanvasSize = UDim2.new()
    an.Parent = aj

    local ao = Instance.new("UIGridLayout")
    ao.SortOrder = Enum.SortOrder.LayoutOrder
    ao.FillDirectionMaxCells = 4
    ao.CellSize = UDim2.fromOffset(163, 114)
    ao.CellPadding = UDim2.fromOffset(6, 5)
    ao.Parent = an

    ah.Window = aj
    ah.Category = ai
    table.insert(d.Windows, aj)

    function ah.CreateModule(ap, aq)
        d:Remove(aq.Name)

        local ar = {
            Enabled = false,
            Options = {},
            Name = aq.Name,
            Legit = true,
            Category = "Legit",
            CategoryModule = ai,
            _syncing = false,
        }
        local as = function(as)
            if ar.Enabled ~= as and ar.Toggle ~= nil then
                ar:Toggle()
            end
        end

        local at = table.clone(aq)
        at.Function = as
        local au = ai:CreateModule(at)

        local av = Instance.new("TextButton")
        av.Name = aq.Name
        av.BackgroundColor3 = o.Surface
        av.BorderSizePixel = 0
        av.Text = ""
        av.AutoButtonColor = false
        av.ClipsDescendants = true
        av.Parent = an
        addTooltip(av, aq.Tooltip)
        addCorner(av, o.RadiusLarge)
        local cardStroke = addStroke(av, o.Border, 0.68, 1, "LegitCardStroke")
        addSurfaceGradient(av)
        local cardScale = addScale(av)
        local cardAccent = Instance.new("Frame")
        cardAccent.Name = "Accent"
        cardAccent.Size = UDim2.new(1, -20, 0, 2)
        cardAccent.Position = UDim2.fromOffset(10, 0)
        cardAccent.BorderSizePixel = 0
        cardAccent.Visible = false
        cardAccent.Parent = av
        addCorner(cardAccent, UDim.new(1, 0))
        connectguicolorchange(function(hue, saturation, value)
            cardAccent.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
            if ar.Enabled then
                cardStroke.Color = cardAccent.BackgroundColor3
            end
        end)

        local aw = Instance.new("TextLabel")
        aw.Name = "Title"
        aw.Size = UDim2.new(1, -16, 0, 20)
        aw.Position = UDim2.fromOffset(16, 81)
        aw.BackgroundTransparency = 1
        aw.Text = aq.Name
        aw.TextXAlignment = Enum.TextXAlignment.Left
        aw.TextColor3 = o.MutedText
        aw.TextSize = 13
        aw.FontFace = o.FontSemiBold
        aw.Parent = av

        local ax = Instance.new("Frame")
        ax.Name = "Knob"
        ax.Size = UDim2.fromOffset(22, 12)
        ax.Position = UDim2.new(1, -57, 0, 14)
        ax.BackgroundColor3 = o.Elevated
        ax.Parent = av
        addCorner(ax, UDim.new(1, 0))

        local ay = ax:Clone()
        ay.Size = UDim2.fromOffset(8, 8)
        ay.Position = UDim2.fromOffset(2, 2)
        ay.BackgroundColor3 = o.MutedText
        ay.Parent = ax

        local az = Instance.new("TextButton")
        az.Name = "Dots"
        az.Size = UDim2.fromOffset(14, 24)
        az.Position = UDim2.new(1, -27, 0, 8)
        az.BackgroundTransparency = 1
        az.Text = ""
        az.Parent = av

        local aA = Instance.new("ImageLabel")
        aA.Name = "Dots"
        aA.Size = UDim2.fromOffset(2, 12)
        aA.Position = UDim2.fromOffset(6, 6)
        aA.BackgroundTransparency = 1
        aA.Image = u("badscript/assets/new/dots.png")
        aA.ImageColor3 = m.Light(o.Main, 0.37)
        aA.Parent = az

        local aB = Instance.new("TextButton")
        aB.Name = "Shadow"
        aB.Size = UDim2.new(1, 0, 1, -5)
        aB.BackgroundColor3 = Color3.new()
        aB.BackgroundTransparency = 1
        aB.AutoButtonColor = false
        aB.ClipsDescendants = true
        aB.Visible = false
        aB.Text = ""
        aB.Parent = aj
        addCorner(aB)

        local aC = Instance.new("TextButton")
        aC.Size = UDim2.new(0, 220, 1, 0)
        aC.Position = UDim2.fromScale(1, 0)
        aC.BackgroundColor3 = o.MainSoft
        aC.AutoButtonColor = false
        aC.Text = ""
        aC.Parent = aB

        local aD = Instance.new("TextLabel")
        aD.Name = "Title"
        aD.Size = UDim2.new(1, -36, 0, 20)
        aD.Position = UDim2.fromOffset(36, 12)
        aD.BackgroundTransparency = 1
        aD.Text = aq.Name
        aD.TextXAlignment = Enum.TextXAlignment.Left
        aD.TextColor3 = o.Text
        aD.TextSize = 13
        aD.FontFace = o.FontSemiBold
        aD.Parent = aC

        local aE = Instance.new("ImageButton")
        aE.Name = "Back"
        aE.Size = UDim2.fromOffset(16, 16)
        aE.Position = UDim2.fromOffset(11, 13)
        aE.BackgroundTransparency = 1
        aE.Image = u("badscript/assets/new/back.png")
        aE.ImageColor3 = m.Light(o.Main, 0.37)
        aE.Parent = aC
        addCorner(aC)

        local legitOptionsGeneration = 0
        local legitOptionsTransition = TweenInfo.new(
            0.13,
            Enum.EasingStyle.Quint,
            Enum.EasingDirection.Out
        )
        local closeLegitOptions

        local function openLegitOptions()
            if d.HideTooltip then
                d.HideTooltip(true)
            end
            if d._OpenDropdown then
                pcall(d._OpenDropdown, true)
                d._OpenDropdown = nil
            end
            if d._OpenModuleOptions then
                pcall(d._OpenModuleOptions, true)
                d._OpenModuleOptions = nil
            end
            if
                d._OpenLegitOptions
                and d._OpenLegitOptions ~= closeLegitOptions
            then
                pcall(d._OpenLegitOptions, true)
            end

            d._OpenLegitOptions = closeLegitOptions
            legitOptionsGeneration += 1
            aB.Visible = true
            aB.Active = true
            aB.BackgroundTransparency = 1
            aC.Position = UDim2.fromScale(1, 0)

            n:Tween(aB, legitOptionsTransition, {
                BackgroundTransparency = 0.5,
            })
            n:Tween(aC, legitOptionsTransition, {
                Position = UDim2.new(1, -220, 0, 0),
            })
        end

        closeLegitOptions = function(instant)
            legitOptionsGeneration += 1
            local generation = legitOptionsGeneration
            if d._OpenLegitOptions == closeLegitOptions then
                d._OpenLegitOptions = nil
            end

            if not aB.Visible then
                return
            end

            aB.Active = false

            local function finishClose()
                if generation == legitOptionsGeneration then
                    aB.Visible = false
                    aB.BackgroundTransparency = 1
                    aC.Position = UDim2.fromScale(1, 0)
                end
            end

            if instant or not d.Loaded then
                finishClose()
                return
            end

            local fadeTween = n:Tween(aB, legitOptionsTransition, {
                BackgroundTransparency = 1,
            })
            n:Tween(aC, legitOptionsTransition, {
                Position = UDim2.fromScale(1, 0),
            })

            if fadeTween then
                fadeTween.Completed:Once(finishClose)
            else
                task.delay(0.19, finishClose)
            end
        end

        local aF = Instance.new("ScrollingFrame")
        aF.Name = "Children"
        aF.Size = UDim2.new(1, 0, 1, -45)
        aF.Position = UDim2.fromOffset(0, 41)
        aF.BackgroundColor3 = o.MainSoft
        aF.BorderSizePixel = 0
        aF.ScrollBarThickness = 2
        aF.ScrollBarImageTransparency = 0.75
        aF.CanvasSize = UDim2.new()
        aF.Parent = aC

        local aH = Instance.new("UIListLayout")
        aH.SortOrder = Enum.SortOrder.LayoutOrder
        aH.HorizontalAlignment = Enum.HorizontalAlignment.Center
        aH.Parent = aF

        if aq.Size then
            ah.WidgetCount = (ah.WidgetCount or 0) + 1
            local widgetIndex = ah.WidgetCount
            local aI = Instance.new("Frame")
            aI.Name = aq.Name .. "Widget"
            aI.Size = aq.Size

            local widgetWidth = math.max(aq.Size.X.Offset, 100)
            local widgetHeight = math.max(aq.Size.Y.Offset, 41)
            local widgetColumn = math.floor((widgetIndex - 1) / 7)
            local widgetRow = (widgetIndex - 1) % 7
            aI.Position = UDim2.new(
                1,
                -(widgetWidth + 18 + (widgetColumn * (widgetWidth + 10))),
                0,
                72 + (widgetRow * (widgetHeight + 8))
            )

            aI.BackgroundColor3 = o.MainSoft
            aI.BackgroundTransparency = 0.03
            aI.BorderSizePixel = 0
            aI.Active = true
            aI.ClipsDescendants = false
            aI.Visible = false
            aI.Parent = w
            aI:SetAttribute("PremiumLegitWidget", true)

            addCorner(aI, o.Radius)
            addSurfaceGradient(aI)
            addShadow(aI)
            local widgetStroke = addStroke(aI, o.BorderStrong, 0.58, 1, "LegitWidgetStroke")

            local widgetTint = Instance.new("Frame")
            widgetTint.Name = "WidgetTint"
            widgetTint.Size = UDim2.fromScale(1, 1)
            widgetTint.BackgroundColor3 = o.Main
            widgetTint.BackgroundTransparency = 0.86
            widgetTint.BorderSizePixel = 0
            widgetTint.ZIndex = aI.ZIndex
            widgetTint:SetAttribute("PremiumWidgetInternal", true)
            widgetTint.Parent = aI
            addCorner(widgetTint, o.Radius)

            local widgetAccent = Instance.new("Frame")
            widgetAccent.Name = "WidgetAccent"
            widgetAccent.Size = UDim2.new(1, -16, 0, 2)
            widgetAccent.Position = UDim2.fromOffset(8, 1)
            widgetAccent.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            widgetAccent.BackgroundTransparency = 0.26
            widgetAccent.BorderSizePixel = 0
            widgetAccent.ZIndex = aI.ZIndex + 4
            widgetAccent:SetAttribute("PremiumWidgetInternal", true)
            widgetAccent.Parent = aI
            addCorner(widgetAccent, UDim.new(1, 0))

            local widgetTitle = Instance.new("TextLabel")
            widgetTitle.Name = "WidgetTitle"
            widgetTitle.Size = UDim2.new(1, -30, 0, 11)
            widgetTitle.Position = UDim2.fromOffset(9, 4)
            widgetTitle.BackgroundTransparency = 1
            widgetTitle.Text = string.upper(aq.Name)
            widgetTitle.TextColor3 = o.FaintText
            widgetTitle.TextSize = 8
            widgetTitle.TextXAlignment = Enum.TextXAlignment.Left
            widgetTitle.FontFace = o.FontBold
            widgetTitle.ZIndex = aI.ZIndex + 5
            widgetTitle:SetAttribute("PremiumWidgetInternal", true)
            widgetTitle.Parent = aI

            local grip = Instance.new("Frame")
            grip.Name = "DragGrip"
            grip.Size = UDim2.fromOffset(18, 12)
            grip.Position = UDim2.new(1, -23, 0, 4)
            grip.BackgroundTransparency = 1
            grip.ZIndex = aI.ZIndex + 5
            grip:SetAttribute("PremiumWidgetInternal", true)
            grip.Parent = aI

            for dotIndex = 0, 2 do
                local dot = Instance.new("Frame")
                dot.Size = UDim2.fromOffset(2, 2)
                dot.Position = UDim2.fromOffset(4 + (dotIndex * 5), 5)
                dot.BackgroundColor3 = o.FaintText
                dot.BackgroundTransparency = 0.2
                dot.BorderSizePixel = 0
                dot.ZIndex = grip.ZIndex
                dot:SetAttribute("PremiumWidgetInternal", true)
                dot.Parent = grip
                addCorner(dot, UDim.new(1, 0))
            end

            connectguicolorchange(function(hue, saturation, value)
                if widgetAccent.Parent then
                    widgetAccent.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
                end
            end)

            local metricModules = {
                Clock = true,
                FPS = true,
                Memory = true,
                Ping = true,
                Speedmeter = true,
            }

            local function styleWidgetChild(child)
                if child:GetAttribute("PremiumWidgetInternal") then
                    return
                end

                if child:IsA("TextLabel") then
                    local syncingBackground = false
                    local function syncBackground()
                        if syncingBackground or not child.Parent then
                            return
                        end
                        local requestedTransparency = child.BackgroundTransparency
                        widgetTint.BackgroundColor3 = child.BackgroundColor3
                        widgetTint.BackgroundTransparency =
                            math.clamp(0.94 - ((1 - requestedTransparency) * 0.38), 0.54, 0.94)
                        syncingBackground = true
                        child.BackgroundTransparency = 1
                        syncingBackground = false
                    end

                    child.TextColor3 = o.TextStrong
                    child.TextStrokeTransparency = 1
                    child.ZIndex = aI.ZIndex + 3

                    if metricModules[aq.Name] then
                        child.Position = UDim2.fromOffset(10, 12)
                        child.Size = UDim2.new(1, -20, 1, -14)
                        child.TextXAlignment = Enum.TextXAlignment.Left
                        child.TextYAlignment = Enum.TextYAlignment.Center
                        child.TextSize = math.min(math.max(child.TextSize, 13), 15)
                        child.FontFace = o.FontSemiBold
                        child.RichText = false
                        child.TextTruncate = Enum.TextTruncate.AtEnd
                    end

                    child:GetPropertyChangedSignal("BackgroundColor3"):Connect(syncBackground)
                    child:GetPropertyChangedSignal("BackgroundTransparency"):Connect(syncBackground)
                    task.defer(syncBackground)
                end
            end

            for _, child in ipairs(aI:GetChildren()) do
                styleWidgetChild(child)
            end
            aI.ChildAdded:Connect(styleWidgetChild)

            aI.MouseEnter:Connect(function()
                local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
                n:Tween(aI, o.TweenFast, { BackgroundColor3 = o.Elevated })
                n:Tween(widgetStroke, o.TweenFast, {
                    Color = accent:Lerp(o.BorderStrong, 0.5),
                    Transparency = 0.52,
                })
            end)

            aI.MouseLeave:Connect(function()
                n:Tween(aI, o.TweenFast, { BackgroundColor3 = o.MainSoft })
                n:Tween(widgetStroke, o.TweenFast, {
                    Color = o.BorderStrong,
                    Transparency = 0.62,
                })
            end)

            addTooltip(aI, "Drag to reposition " .. aq.Name)
            makeDraggable(aI)

            ar.Children = aI
            ar.WidgetStroke = widgetStroke
            ar.WidgetAccent = widgetAccent
        end

        aq.Function = aq.Function or function() end
        addMaid(ar)

        function ar.Toggle(aI)
            if aI._syncing then
                return
            end

            aI._syncing = true
            ar.Enabled = not ar.Enabled

            if ar.Children then
                ar.Children.Visible = ar.Enabled
            end

            if au and au.Enabled ~= ar.Enabled then
                au._syncing = true
                au:Toggle()
                au._syncing = false
            end

            local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            local dimAccent = accent:Lerp(o.MutedText, 0.2)
            local enabledSurface = o.Elevated:Lerp(accent, 0.18)
            cardAccent.Visible = ar.Enabled
            n:Tween(aw, o.TweenFast, {
                TextColor3 = ar.Enabled and o.TextStrong:Lerp(accent, 0.44) or o.MutedText,
            })
            n:Tween(av, o.TweenFast, {
                BackgroundColor3 = ar.Enabled and enabledSurface or o.Surface,
            })
            n:Tween(cardStroke, o.TweenFast, {
                Color = ar.Enabled and accent or o.Border,
                Transparency = ar.Enabled and 0.28 or 0.82,
            })
            n:Spring(cardScale, o.SpringInteractive, { Scale = 1 })
            n:Tween(ax, o.Tween, {
                BackgroundColor3 = ar.Enabled and accent or o.Elevated,
            })
            n:Tween(ay, o.Tween, {
                Position = UDim2.fromOffset(ar.Enabled and 12 or 2, 2),
                BackgroundColor3 = ar.Enabled and dimAccent or o.MutedText,
            })

            if not ar.Enabled then
                for aJ, aK in ar.Connections do
                    aK:Disconnect()
                end
                table.clear(ar.Connections)
            end

            aI._syncing = false
            d._PendingModuleCallbacks += 1
            task.spawn(function()
                local success, callbackError = xpcall(
                    function()
                        aq.Function(ar.Enabled)
                    end,
                    debug and debug.traceback
                        or function(err)
                            return tostring(err)
                        end
                )

                d._PendingModuleCallbacks = math.max(
                    0,
                    d._PendingModuleCallbacks - 1
                )

                if not success then
                    a:report({
                        type = "legit-toggle-callback",
                        err = callbackError,
                        args = { tostring(aq.Name), ar.Enabled },
                    })
                end
            end)
        end

        local function createSyncedOption(aI, aJ, aK, aL, aM, aN)
            local aO = aI(aJ, aK, aM)
            local aP = aI(table.clone(aJ), aL, aN)

            aO._syncing = false
            aP._syncing = false

            local aQ = { "ChangeValue", "Color", "SetValue", "Toggle", "ConnectCallback", "SetValues" }

            for aR, aS in aQ do
                if aO[aS] and type(aO[aS]) == "function" then
                    local aT = aO[aS]
                    aO[aS] = function(aU, ...)
                        if aU._syncing then
                            return aT(aU, ...)
                        end

                        aU._syncing = true
                        local aV = { ... }
                        local aW = aT(aU, unpack(aV))

                        if aP[aS] and type(aP[aS]) == "function" and not aP._syncing then
                            pcall(function()
                                aP._syncing = true
                                aP[aS](aP, unpack(aV))
                                aP._syncing = false
                            end)
                        end

                        aU._syncing = false
                        return aW
                    end
                end
            end

            for aR, aS in aQ do
                if aP[aS] and type(aP[aS]) == "function" then
                    local aT = aP[aS]
                    aP[aS] = function(aU, ...)
                        if aU._syncing then
                            return aT(aU, ...)
                        end

                        aU._syncing = true
                        local aV = { ... }
                        local aW = aT(aU, unpack(aV))

                        if aO[aS] and type(aO[aS]) == "function" and not aO._syncing then
                            pcall(function()
                                aO._syncing = true
                                aO[aS](aO, unpack(aV))
                                aO._syncing = false
                            end)
                        end

                        aU._syncing = false
                        return aW
                    end
                end
            end

            for aR, aS in { "Load", "Save" } do
                if aO[aS] and type(aO[aS]) == "function" then
                    local aT = aO[aS]
                    aO[aS] = function(aU, ...)
                        return aT(aU, ...)
                    end
                end
            end

            aO.CategoryComponent = aP
            aP.LegitComponent = aO

            return aO
        end

        for aI, aJ in H do
            ar["Create" .. aI] = function(aK, aL)
                return createSyncedOption(aJ, aL, aF, au.Children, ar, au)
            end
            ar["Add" .. aI] = ar["Create" .. aI]
        end

        aE.MouseEnter:Connect(function()
            aE.ImageColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        end)
        aE.MouseLeave:Connect(function()
            aE.ImageColor3 = m.Light(o.Main, 0.37)
        end)
        aE.Activated:Connect(function()
            closeLegitOptions(false)
        end)

        az.Activated:Connect(function()
            ar._SuppressPrimaryUntil = os.clock() + 0.12
            openLegitOptions()
        end)

        az.MouseEnter:Connect(function()
            local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            aA.ImageColor3 = accent:Lerp(o.MutedText, 0.28)
        end)
        az.MouseLeave:Connect(function()
            aA.ImageColor3 = m.Light(o.Main, 0.37)
        end)

        av.MouseEnter:Connect(function()
            local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            local hoverAccent = accent:Lerp(o.MutedText, 0.3)
            n:Tween(av, o.TweenFast, {
                BackgroundColor3 = ar.Enabled and o.Elevated or o.SurfaceHover,
            })
            n:Tween(cardStroke, o.TweenFast, {
                Color = accent,
                Transparency = ar.Enabled and 0.46 or 0.64,
            })
            aw.TextColor3 = hoverAccent
            n:Spring(cardScale, o.SpringInteractive, { Scale = 1 })
        end)
        av.MouseLeave:Connect(function()
            local accent = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            n:Tween(av, o.TweenFast, {
                BackgroundColor3 = ar.Enabled and o.Elevated or o.Surface,
            })
            n:Tween(cardStroke, o.TweenFast, {
                Color = ar.Enabled and accent or o.Border,
                Transparency = ar.Enabled and 0.5 or 0.78,
            })
            aw.TextColor3 = ar.Enabled and accent or o.MutedText
            n:Spring(cardScale, o.SpringInteractive, { Scale = 1 })
        end)
        av.MouseButton1Down:Connect(function()
            n:Spring(cardScale, o.SpringInteractive, { Scale = 0.996 })
        end)
        av.MouseButton1Up:Connect(function()
            n:Spring(cardScale, o.SpringInteractive, { Scale = 1 })
        end)

        av.Activated:Connect(function(inputObject)
            if
                os.clock() < (ar._SuppressPrimaryUntil or 0)
                or ar._PrimaryClickBusy
                or (
                    inputObject
                    and inputObject.UserInputType
                        == Enum.UserInputType.MouseButton2
                )
            then
                return
            end

            ar._PrimaryClickBusy = true
            task.delay(0.075, function()
                ar._PrimaryClickBusy = false
            end)

            ar:Toggle()
        end)

        av.MouseButton2Click:Connect(function()
            ar._SuppressPrimaryUntil = os.clock() + 0.12

            if d.HideTooltip then
                d.HideTooltip(true)
            end

            openLegitOptions()
        end)

        aB.Activated:Connect(function()
            closeLegitOptions(false)
        end)

        av.Destroying:Once(function()
            closeLegitOptions(true)
        end)

        connectDeferredPropertyChanged(aH, "AbsoluteContentSize", function()
            if d.ThreadFix then
                setthreadidentity(8)
            end
            local targetCanvasSize = UDim2.fromOffset(0, aH.AbsoluteContentSize.Y / A.Scale)
            if aF.CanvasSize ~= targetCanvasSize then
                aF.CanvasSize = targetCanvasSize
            end
        end)

        ar.Object = av
        ar.LegitTabModule = ar
        au.LegitTabModule = ar
        au._syncing = false

        ah.Modules[aq.Name] = ar

        local aI = {}
        for aJ, aK in ah.Modules do
            table.insert(aI, aK.Name)
        end
        table.sort(aI)

        for aJ, aK in aI do
            ah.Modules[aK].Object.LayoutOrder = aJ
        end

        return ar
    end

    local function visibleCheck()
        for ap, aq in ah.Modules do
            if aq.Children then
                local ar = v.Visible
                for as, at in ag.Windows do
                    ar = ar or at.Visible
                end
                aq.Children.Visible = (not ar or aj.Visible) and aq.Enabled
            end
        end
    end

    am.Activated:Connect(function()
        aj.Visible = false
        v.Visible = true
    end)

    ag:Clean(v:GetPropertyChangedSignal("Visible"):Connect(visibleCheck))
    aj:GetPropertyChangedSignal("Visible"):Connect(function()
        ag:UpdateGUI(ag.GUIColor.Hue, ag.GUIColor.Sat, ag.GUIColor.Value)
        visibleCheck()
    end)

    connectDeferredPropertyChanged(ao, "AbsoluteContentSize", function()
        if ag.ThreadFix then
            setthreadidentity(8)
        end
        local targetCanvasSize = UDim2.fromOffset(0, ao.AbsoluteContentSize.Y / A.Scale)
        if an.CanvasSize ~= targetCanvasSize then
            an.CanvasSize = targetCanvasSize
        end
    end)

    ag.Legit = ah

    return ah
end

function d.CreateNotification(ag, ah, ai, aj, ak)
    if not ag.Notifications or not ag.Notifications.Enabled then
        return
    end

    ah = tostring(ah or "BadWars")
    ai = tostring(ai or "")
    aj = math.clamp(tonumber(aj) or 5, 1.5, 30)
    ak = string.lower(tostring(ak or "info"))

    task.defer(function()
        if ag.ThreadFix then
            setthreadidentity(8)
        end
        if not q or not q.Parent then
            return
        end
        ag._NotificationDismissers = ag._NotificationDismissers or setmetatable({}, { __mode = "k" })

        local function cards()
            local result = {}
            for _, child in ipairs(q:GetChildren()) do
                if child:IsA("GuiObject") and child.Name == "Notification" then
                    result[#result + 1] = child
                end
            end
            table.sort(result, function(left, right)
                return (left.LayoutOrder or 0) > (right.LayoutOrder or 0)
            end)
            return result
        end

        local function layout(animated)
            local offset = d.isMobile and 14 or 18
            for _, card in ipairs(cards()) do
                local height = card:GetAttribute("NotifHeight") or card.AbsoluteSize.Y
                local target = UDim2.new(1, d.isMobile and -10 or -18, 1, -(offset + height))
                if animated then
                    n:Tween(card, o.Tween, { Position = target }, n.tweenstwo)
                else
                    card.Position = target
                end
                offset += height + 8
            end
        end

        local function restart(existing)
            local generation = (existing:GetAttribute("LifeGeneration") or 0) + 1
            existing:SetAttribute("LifeGeneration", generation)
            existing.LayoutOrder = math.floor(os.clock() * 100000)
            local count = (existing:GetAttribute("DuplicateCount") or 1) + 1
            existing:SetAttribute("DuplicateCount", count)
            local badge = existing:FindFirstChild("Count")
            if badge and badge:IsA("TextLabel") then
                badge.Text = tostring(count)
                badge.Visible = true
            end
            local progress = existing:FindFirstChild("Progress", true)
            if progress and progress:IsA("Frame") then
                progress.Size = UDim2.fromScale(1, 1)
                n:Tween(progress, TweenInfo.new(aj, Enum.EasingStyle.Linear), {
                    Size = UDim2.fromScale(0, 1),
                }, n.tweenstwo)
            end
            local scale = existing:FindFirstChildOfClass("UIScale")
            if scale then
                scale.Scale = 0.985
                n:Spring(scale, o.SpringInteractive, { Scale = 1 })
            end
            layout(true)
            task.delay(aj, function()
                if existing.Parent and existing:GetAttribute("LifeGeneration") == generation then
                    local dismissExisting = ag._NotificationDismissers[existing]
                    if type(dismissExisting) == "function" then
                        dismissExisting()
                    else
                        existing:Destroy()
                        layout(true)
                    end
                end
            end)
            return true
        end

        for _, existing in ipairs(cards()) do
            if existing:GetAttribute("NotifTitle") == ah and existing:GetAttribute("NotifText") == ai then
                restart(existing)
                return
            end
        end

        local current = cards()
        local limit = d.isMobile and 3 or 4
        while #current >= limit do
            current[#current]:Destroy()
            current = cards()
        end

        local styleColor = ak == "alert" and o.Danger
            or ak == "warning" and o.Warning
            or ak == "success" and o.Success
            or Color3.fromHSV(ag.GUIColor.Hue, ag.GUIColor.Sat, ag.GUIColor.Value)
        local iconName = ak == "alert" and "alert" or ak == "warning" and "warning" or ak == "success" and "success" or "info"
        local maxWidth = d.isMobile and 326 or 384
        local minWidth = d.isMobile and 296 or 320
        local bodyBounds = E(removeTags(ai), d.isMobile and 12 or 11, o.Font, maxWidth - 66) or Vector2.zero
        local titleBounds = E(removeTags(ah), d.isMobile and 13 or 12, o.FontSemiBold, maxWidth - 96) or Vector2.zero
        local width = math.clamp(math.max(minWidth, math.max(bodyBounds.X + 66, titleBounds.X + 96)), minWidth, maxWidth)
        local wrapped = E(removeTags(ai), d.isMobile and 12 or 11, o.Font, width - 66) or Vector2.zero
        local height = math.clamp(66 + math.max(0, wrapped.Y - 14), 74, d.isMobile and 126 or 120)

        local card = Instance.new("CanvasGroup")
        card.Name = "Notification"
        card.Size = UDim2.fromOffset(width, height)
        card.AnchorPoint = Vector2.new(1, 0)
        card.Position = UDim2.new(1, width + 24, 1, -(height + 18))
        card.LayoutOrder = math.floor(os.clock() * 100000)
        card.BackgroundColor3 = o.MainSoft
        card.BackgroundTransparency = 0.005
        card.BorderSizePixel = 0
        card.GroupTransparency = 1
        card.Active = true
        card.ZIndex = 130
        card:SetAttribute("NotifHeight", height)
        card:SetAttribute("NotifTitle", ah)
        card:SetAttribute("NotifText", ai)
        card:SetAttribute("DuplicateCount", 1)
        card:SetAttribute("LifeGeneration", 1)
        card.Parent = q
        addCorner(card, o.RadiusLarge)
        addSurfaceGradient(card)
        addShadow(card, true)
        local stroke = addStroke(card, o.BorderStrong, 0.38, 1, "NotificationStroke")
        local scale = addScale(card)
        scale.Scale = 0.975

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.Size = UDim2.new(1, -28, 0, 2)
        accent.Position = UDim2.fromOffset(14, 0)
        accent.BackgroundColor3 = styleColor
        accent.BorderSizePixel = 0
        accent.ZIndex = 132
        accent.Parent = card
        addCorner(accent, UDim.new(1, 0))

        local iconShell = Instance.new("Frame")
        iconShell.Name = "IconShell"
        iconShell.Size = UDim2.fromOffset(36, 36)
        iconShell.Position = UDim2.fromOffset(16, 18)
        iconShell.BackgroundColor3 = styleColor
        iconShell.BackgroundTransparency = 0.88
        iconShell.BorderSizePixel = 0
        iconShell.ZIndex = 132
        iconShell.Parent = card
        addCorner(iconShell, o.RadiusSmall)

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(14, 14)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = u("badscript/assets/new/" .. iconName .. ".png")
        if icon.Image == "" then
            icon.Image = u("badscript/assets/new/info.png")
        end
        icon.ImageColor3 = styleColor
        icon.ZIndex = 133
        icon.Parent = iconShell

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -100, 0, 20)
        title.Position = UDim2.fromOffset(64, 15)
        title.BackgroundTransparency = 1
        title.Text = ah
        title.TextColor3 = o.TextStrong
        title.TextSize = d.isMobile and 13 or 12
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.RichText = true
        title.FontFace = o.FontSemiBold
        title.ZIndex = 132
        title.Parent = card

        local body = Instance.new("TextLabel")
        body.Name = "Text"
        body.Size = UDim2.new(1, -80, 1, -44)
        body.Position = UDim2.fromOffset(64, 37)
        body.BackgroundTransparency = 1
        body.Text = ai
        body.TextColor3 = o.MutedText
        body.TextSize = d.isMobile and 12 or 11
        body.TextXAlignment = Enum.TextXAlignment.Left
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.TextWrapped = true
        body.TextTruncate = Enum.TextTruncate.AtEnd
        body.RichText = true
        body.FontFace = o.Font
        body.ZIndex = 132
        body.Parent = card

        local count = Instance.new("TextLabel")
        count.Name = "Count"
        count.Size = UDim2.fromOffset(22, 18)
        count.Position = UDim2.new(1, -50, 0, 10)
        count.BackgroundColor3 = o.Elevated
        count.BackgroundTransparency = 0.08
        count.BorderSizePixel = 0
        count.Visible = false
        count.Text = "2"
        count.TextColor3 = o.MutedText
        count.TextSize = 9
        count.FontFace = o.FontBold
        count.ZIndex = 134
        count.Parent = card
        addCorner(count, UDim.new(1, 0))

        local close = Instance.new("TextButton")
        close.Name = "Dismiss"
        close.Size = UDim2.fromOffset(24, 24)
        close.Position = UDim2.new(1, -30, 0, 7)
        close.BackgroundTransparency = 1
        close.BorderSizePixel = 0
        close.AutoButtonColor = false
        close.Text = "X"
        close.TextColor3 = o.FaintText
        close.TextSize = 18
        close.FontFace = o.FontSemiBold
        close.ZIndex = 135
        close.Parent = card

        local track = Instance.new("Frame")
        track.Name = "ProgressTrack"
        track.Size = UDim2.new(1, -32, 0, 2)
        track.Position = UDim2.new(0, 16, 1, -8)
        track.BackgroundColor3 = o.Elevated
        track.BackgroundTransparency = 0.12
        track.BorderSizePixel = 0
        track.ZIndex = 132
        track.Parent = card
        addCorner(track, UDim.new(1, 0))

        local progress = Instance.new("Frame")
        progress.Name = "Progress"
        progress.Size = UDim2.fromScale(1, 1)
        progress.BackgroundColor3 = styleColor
        progress.BorderSizePixel = 0
        progress.ZIndex = 133
        progress.Parent = track
        addCorner(progress, UDim.new(1, 0))

        local dismissed = false
        local function dismiss()
            if dismissed then
                return
            end
            dismissed = true
            ag._NotificationDismissers[card] = nil
            n:Tween(card, TweenInfo.new(0.145, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, width + 24, 1, card.Position.Y.Offset),
                GroupTransparency = 1,
            }, n.tweenstwo)
            n:Tween(scale, TweenInfo.new(0.145, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 0.975 })
            task.delay(0.15, function()
                if card.Parent then
                    card:Destroy()
                end
                layout(true)
            end)
        end

        ag._NotificationDismissers[card] = dismiss
        close.Activated:Connect(dismiss)
        close.MouseEnter:Connect(function()
            n:Tween(close, o.TweenFast, { TextColor3 = o.TextStrong })
        end)
        close.MouseLeave:Connect(function()
            n:Tween(close, o.TweenFast, { TextColor3 = o.FaintText })
        end)
        card.MouseEnter:Connect(function()
            n:Spring(scale, o.SpringInteractive, { Scale = 1.006 })
            n:Tween(stroke, o.TweenFast, { Transparency = 0.3, Color = styleColor:Lerp(o.BorderStrong, 0.62) })
        end)
        card.MouseLeave:Connect(function()
            n:Spring(scale, o.SpringInteractive, { Scale = 1 })
            n:Tween(stroke, o.TweenFast, { Transparency = 0.48, Color = o.BorderStrong })
        end)
        if d.isMobile then
            local swipe = Instance.new("TextButton")
            swipe.Name = "SwipeDismiss"
            swipe.Size = UDim2.fromScale(1, 1)
            swipe.BackgroundTransparency = 1
            swipe.Text = ""
            swipe.ZIndex = 131
            swipe.Parent = card
            setupMobileSwipeDismiss(swipe, dismiss)
        end

        layout(true)
        n:Tween(card, o.TweenSpring, {
            GroupTransparency = 0,
        }, n.tweenstwo)
        n:Spring(scale, o.SpringSoft, { Scale = 1 })
        n:Tween(progress, TweenInfo.new(aj, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }, n.tweenstwo)

        local generation = card:GetAttribute("LifeGeneration")
        task.delay(aj, function()
            if card.Parent and not dismissed and card:GetAttribute("LifeGeneration") == generation then
                dismiss()
            end
        end)
    end)
end

local ag
function d.CreatePrompt(ah, ai)
    if ag then
        pcall(ag)
        ag = nil
    end

    ai = ai or {}

    local titleText = tostring(ai.Title or "Confirm")
    local bodyText = tostring(ai.Text or "Are you sure?")
    local confirmText = tostring(ai.ConfirmText or "Confirm")
    local cancelText = tostring(ai.CancelText or "Cancel")
    local onConfirm = ai.OnConfirm
    local onCancel = ai.OnCancel
    local hasInput = ai.Input
    local inputPlaceholder = tostring(ai.InputPlaceholder or "")
    local inputDefault = tostring(ai.InputDefault or "")

    task.defer(function()
        if d.ThreadFix then
            setthreadidentity(8)
        end

        local closed = false
        local panelHeight = hasInput and 236 or 202

        local backdrop = Instance.new("TextButton")
        backdrop.Name = "PromptBackdrop"
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.Position = UDim2.fromScale(0, 0)
        backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
        backdrop.BackgroundTransparency = 1
        backdrop.BorderSizePixel = 0
        backdrop.AutoButtonColor = false
        backdrop.Text = ""
        backdrop.ZIndex = 100
        backdrop.Parent = s

        local panel = Instance.new("Frame")
        panel.Name = "Prompt"
        panel.Size = UDim2.fromOffset(d.isMobile and 340 or 400, panelHeight)
        panel.AnchorPoint = Vector2.new(0.5, 0.5)
        panel.Position = UDim2.fromScale(0.5, 0.48)
        panel.BackgroundColor3 = o.MainSoft
        panel.BorderSizePixel = 0
        panel.ClipsDescendants = false
        panel.ZIndex = 101
        panel.Parent = backdrop
        addCorner(panel, o.RadiusLarge)
        addSurfaceGradient(panel)
        addShadow(panel, true)
        local panelStroke = addStroke(panel, o.BorderStrong, 0.2, 1, "PromptStroke")
        local panelScale = addScale(panel)
        panelScale.Scale = 0.92
        local accent = addAccentLine(panel, 3)
        addV9Chrome(panel, "CONFIRM")

        local iconContainer = Instance.new("Frame")
        iconContainer.Name = "IconContainer"
        iconContainer.Size = UDim2.fromOffset(38, 38)
        iconContainer.Position = UDim2.fromOffset(18, 18)
        iconContainer.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        iconContainer.BackgroundTransparency = 0.84
        iconContainer.BorderSizePixel = 0
        iconContainer.ZIndex = 103
        iconContainer.Parent = panel
        addCorner(iconContainer, o.Radius)
        local iconStroke = addStroke(
            iconContainer,
            Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
            0.46,
            1,
            "IconStroke"
        )

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(18, 18)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = u("badscript/assets/new/info.png")
        icon.ImageColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        icon.ZIndex = 104
        icon.Parent = iconContainer

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -86, 0, 28)
        title.Position = UDim2.fromOffset(70, 18)
        title.BackgroundTransparency = 1
        title.Text = titleText
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Center
        title.TextColor3 = o.TextStrong
        title.TextSize = d.isMobile and 17 or 16
        title.FontFace = o.FontSemiBold
        title.RichText = true
        title.ZIndex = 103
        title.Parent = panel

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Body"
        subtitle.Size = UDim2.new(1, -36, 0, hasInput and 70 or 78)
        subtitle.Position = UDim2.fromOffset(18, 70)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = bodyText
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.TextColor3 = o.MutedText
        subtitle.TextSize = d.isMobile and 14 or 13
        subtitle.FontFace = o.Font
        subtitle.RichText = true
        subtitle.ZIndex = 103
        subtitle.Parent = panel

        local input
        if hasInput then
            local inputFrame = Instance.new("Frame")
            inputFrame.Name = "InputFrame"
            inputFrame.Size = UDim2.new(1, -36, 0, 38)
            inputFrame.Position = UDim2.fromOffset(18, 138)
            inputFrame.BackgroundColor3 = o.Surface
            inputFrame.BorderSizePixel = 0
            inputFrame.ZIndex = 103
            inputFrame.Parent = panel
            addCorner(inputFrame, o.Radius)
            local inputStroke = addStroke(inputFrame, o.Border, 0.58, 1, "InputStroke")

            input = Instance.new("TextBox")
            input.Name = "Input"
            input.Size = UDim2.new(1, -24, 1, 0)
            input.Position = UDim2.fromOffset(12, 0)
            input.BackgroundTransparency = 1
            input.PlaceholderText = inputPlaceholder
            input.PlaceholderColor3 = o.FaintText
            input.Text = inputDefault
            input.TextColor3 = o.Text
            input.TextSize = 14
            input.FontFace = o.Font
            input.ClearTextOnFocus = false
            input.ZIndex = 104
            input.Parent = inputFrame

            input.Focused:Connect(function()
                n:Tween(inputStroke, o.TweenFast, {
                    Color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value),
                    Transparency = 0.16,
                })
            end)
            input.FocusLost:Connect(function()
                n:Tween(inputStroke, o.TweenFast, {
                    Color = o.Border,
                    Transparency = 0.58,
                })
            end)
        end

        local buttonRow = Instance.new("Frame")
        buttonRow.Name = "Buttons"
        buttonRow.Size = UDim2.new(1, -36, 0, 42)
        buttonRow.Position = UDim2.new(0, 18, 1, -58)
        buttonRow.BackgroundTransparency = 1
        buttonRow.ZIndex = 103
        buttonRow.Parent = panel

        local cancel = Instance.new("TextButton")
        cancel.Name = "Cancel"
        cancel.Size = UDim2.new(0.5, -6, 1, 0)
        cancel.Position = UDim2.new(0, 0, 0, 0)
        cancel.BackgroundColor3 = o.Elevated
        cancel.BorderSizePixel = 0
        cancel.AutoButtonColor = false
        cancel.Text = cancelText
        cancel.TextColor3 = o.MutedText
        cancel.TextSize = 14
        cancel.FontFace = o.FontSemiBold
        cancel.ZIndex = 104
        cancel.Parent = buttonRow
        addCorner(cancel, o.Radius)
        local cancelStroke = addStroke(cancel, o.Border, 0.52, 1, "CancelStroke")
        bindPremiumMotion(cancel, cancel, cancelStroke, {
            HoverScale = 1.006,
            PressScale = 0.985,
            HoverStroke = o.BorderStrong,
            NormalStroke = o.Border,
            HoverTransparency = 0.22,
            NormalTransparency = 0.52,
        })

        local confirm = Instance.new("TextButton")
        confirm.Name = "Confirm"
        confirm.Size = UDim2.new(0.5, -6, 1, 0)
        confirm.Position = UDim2.new(0.5, 6, 0, 0)
        confirm.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        confirm.BorderSizePixel = 0
        confirm.AutoButtonColor = false
        confirm.Text = confirmText
        confirm.TextColor3 = d:TextColor(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value, d.GUIColor.Value)
        confirm.TextSize = 14
        confirm.FontFace = o.FontSemiBold
        confirm.ZIndex = 104
        confirm.Parent = buttonRow
        addCorner(confirm, o.Radius)
        local confirmStroke = addStroke(confirm, o.TextStrong, 0.74, 1, "ConfirmStroke")
        bindPremiumMotion(confirm, confirm, confirmStroke, {
            HoverScale = 1.008,
            PressScale = 0.98,
            HoverStroke = o.TextStrong,
            NormalStroke = o.TextStrong,
            HoverTransparency = 0.48,
            NormalTransparency = 0.74,
        })

        connectguicolorchange(function(hue, saturation, value)
            local color = Color3.fromHSV(hue, saturation, value)
            accent.BackgroundColor3 = color
            iconContainer.BackgroundColor3 = color
            iconStroke.Color = color
            icon.ImageColor3 = color
            confirm.BackgroundColor3 = color
            confirm.TextColor3 = d:TextColor(hue, saturation, value, value)
        end)

        local escapeConnection
        local function closePrompt(confirmed)
            if closed then
                return
            end
            closed = true
            ag = nil

            if escapeConnection then
                escapeConnection:Disconnect()
                escapeConnection = nil
            end

            n:Tween(backdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                BackgroundTransparency = 1,
            })
            n:Tween(panelScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Scale = 0.92,
            })
            n:Tween(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.fromScale(0.5, 0.48),
            })

            local value = input and input.Text or nil
            task.delay(0.18, function()
                if backdrop.Parent then
                    backdrop:Destroy()
                end
            end)

            if confirmed then
                if typeof(onConfirm) == "function" then
                    task.spawn(onConfirm, value)
                end
            elseif typeof(onCancel) == "function" then
                task.spawn(onCancel)
            end
        end

        ag = function()
            closePrompt(false)
        end

        cancel.Activated:Connect(function()
            closePrompt(false)
        end)
        confirm.Activated:Connect(function()
            closePrompt(true)
        end)
        backdrop.Activated:Connect(function()
            closePrompt(false)
        end)

        escapeConnection = h.InputBegan:Connect(function(inputObject)
            if inputObject.KeyCode == Enum.KeyCode.Escape then
                closePrompt(false)
            end
        end)

        backdrop.BackgroundTransparency = 1
        n:Tween(backdrop, o.TweenSlow, {
            BackgroundTransparency = 0.45,
        })
        n:Spring(panelScale, o.SpringPanel, {
            Scale = 1,
        })
        n:Tween(panel, o.TweenBack, {
            Position = UDim2.fromScale(0.5, 0.5),
        })
        n:Tween(panelStroke, o.TweenSlow, {
            Color = o.BorderStrong,
            Transparency = 0.18,
        })

        if input then
            task.defer(function()
                input:CaptureFocus()
            end)
        end
    end)
end

function d.RepairModuleCategories(ah)
    local ai = {}
    for aj, ak in ah.Categories do
        if type(ak) == "table" and ak.Type == "ModuleCategory" and type(ak.AddModule) == "function" then
            ai[aj] = ak
        end
    end
    for aj, ak in ah.Modules do
        local al = ak and ak.Category
        local am = al and ai[al]
        if am then
            am:AddModule(ak)
        end
    end
    for aj, ak in ai do
        if type(ak.Refresh) == "function" then
            ak:Refresh()
        end
    end
end

function d.Load(ah, ai, aj)
    if not ah._profile_loaded then
        ah.PreloadEvent:Fire()
    end
    ah._profile_loaded = true
    if not ai then
        ah.GUIColor:SetValue(nil, nil, nil, 4)
    end
    local ak = {}
    local al = true

    local am = "badscript/profiles/" .. str(game.GameId) .. "_" .. str(ah.Place) .. ".gui.txt"
    if not D(am) then
        am = "badscript/profiles/" .. str(game.GameId) .. ".gui.txt"
    end
    if D(am) then
        ak = loadJson(am)
        if not ak then
            ak = { Categories = {} }
            ah:CreateNotification("BadWars", "Failed to load GUI settings.", 10, "alert")
            al = false
        end
        ah.Profile = aj or ak.Profile or "default"

        local an = shared[`FORCE_PROFILE_GUI_COLOR_SET_{tostring(ah.Profile)}`]
            or (ak.GUIColor ~= nil and type(ak.GUIColor) == "table" and ak.GUIColor[ah.Profile])
        if an then
            ah.GUIColor:SetValue(an.Hue, an.Sat, an.Value)
            shared[`FORCE_PROFILE_GUI_COLOR_SET_{tostring(ah.Profile)}`] = nil
        end

        local ao = shared[`FORCE_PROFILE_TEXT_GUI_CUSTOM_TEXT_{tostring(ah.Profile)}`]
        if ao then
            d.settextguicustomtext(ao)
            shared[`FORCE_PROFILE_TEXT_GUI_CUSTOM_TEXT_{tostring(ah.Profile)}`] = nil
        end

        if not ai then
            ah.Keybind = ak.Keybind
            for ap, aq in ak.Categories do
                local ar = ah.Categories[ap]
                if not ar then
                    continue
                end
                if ar.Options and aq.Options then
                    ah:LoadOptions(ar, aq.Options)
                    task.wait(0.1)
                end
                if ar.Button ~= nil and aq.Enabled ~= nil and (ar.Button.Enabled ~= aq.Enabled) then
                    ar.Button:Toggle()
                end
                if aq.Pinned ~= ar.Pinned then
                    ar:Pin()
                end
                if aq.Expanded ~= nil and aq.Expanded ~= ar.Expanded and ar.Expand ~= nil then
                    ar:Expand()
                end
                if aq.List and (#ar.List > 0 or #aq.List > 0) then
                    ar.List = aq.List or {}
                    ar.ListEnabled = aq.ListEnabled or {}
                    ar:ChangeValue()
                end
                if aq.Position then
                    d:LoadPosition(ar.Object, aq.Position)
                end
            end
        end
    end
    ah.GUI_DATA = ak

    ah.Profile = aj or ak.Profile or "default"
    ah.Profiles = ak.Profiles or { {
        Name = "default",
        Bind = {},
    } }

    if ah.Categories.Profiles then
        ah.Categories.Profiles:ChangeValue()
    end
    if ah.ProfileLabel then
        ah.ProfileLabel.Text = #ah.Profile > 10 and ah.Profile:sub(1, 10) .. "..." or ah.Profile
        ah.ProfileLabel.Size =
            UDim2.fromOffset(E(ah.ProfileLabel.Text, ah.ProfileLabel.TextSize, ah.ProfileLabel.Font).X + 16, 24)
    end

    local an = D("badscript/profiles/" .. ah.Profile .. ah.Place .. ".txt")

    if an then
        local ao = loadJson("badscript/profiles/" .. ah.Profile .. ah.Place .. ".txt")
        if not ao then
            ao = { Categories = {}, Modules = {}, Legit = {} }
            ah:CreateNotification("BadWars", "Failed to load " .. ah.Profile .. " profile.", 10, "alert")
            if ah.Profile ~= "default" then
                pcall(function()
                    local ap
                    for aq, ar in d.Profiles do
                        if ar.Name == ah.Profile then
                            ap = aq
                        end
                    end
                    if ap then
                        table.remove(d.Profiles, ap)
                    end
                end)
                d:Load(true, "default")
            end
            al = false
        else
            for ap, aq in ao.Categories do
                local ar = ah.Categories[ap]
                if not ar then
                    continue
                end
                if ar.Options and aq.Options then
                    ah:LoadOptions(ar, aq.Options)
                end
                if aq.Pinned ~= ar.Pinned then
                    ar:Pin()
                end
                if aq.Expanded ~= nil and aq.Expanded ~= ar.Expanded and ar.Expand ~= nil then
                    ar:Expand()
                end
                if ar.Button ~= nil and aq.Enabled ~= nil and (ar.Button.Enabled ~= aq.Enabled) then
                    ar.Button:Toggle()
                end
                if aq.List and (#ar.List > 0 or #aq.List > 0) then
                    ar.List = aq.List or {}
                    ar.ListEnabled = aq.ListEnabled or {}
                    ar:ChangeValue()
                end
                if aq.Position then
                    d:LoadPosition(ar.Object, aq.Position)
                end
            end

            for ap, aq in ao.Modules do
                local ar = ah.Modules[ap]
                if not ar then
                    continue
                end
                if ar.Options and aq.Options then
                    ah:LoadOptions(ar, aq.Options)
                end
                if
                    ar.StarActive ~= nil
                    and aq.Favorited ~= nil
                    and ar.StarActive ~= aq.Favorited
                    and ar.ToggleStar ~= nil
                    and type(ar.ToggleStar) == "function"
                then
                    ar:ToggleStar(true)
                end
                if aq.Enabled ~= ar.Enabled then
                    if ai then
                        if ah.ToggleNotifications.Enabled then
                            ah:CreateNotification(
                                "Module Toggled",
                                ap
                                    .. "<font color='#FFFFFF'> has been </font>"
                                    .. (aq.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>")
                                    .. "<font color='#FFFFFF'>!</font>",
                                0.75
                            )
                        end
                    end
                    ar:Toggle(true)
                end
                ar:SetBind(aq.Bind, nil, true)
                ar.Object.Bind.Visible = #aq.Bind > 0
            end

            for ap, aq in ao.Legit do
                local overlay = ah.Overlays and ah.Overlays[ap]
                local ar = ah.Legit.Modules[ap]
                    or (overlay and overlay.Button)
                    or ah.Modules[ap]
                if not ar then
                    continue
                end
                if ar.Options and aq.Options then
                    ah:LoadOptions(ar, aq.Options)
                end
                if ar.Enabled ~= aq.Enabled then
                    ar:Toggle()
                end
                if aq.Position then
                    if overlay and overlay.Object then
                        overlay.Object.Position = UDim2.fromOffset(aq.Position.X, aq.Position.Y)
                    elseif ar.Children then
                        ar.Children.Position = UDim2.fromOffset(aq.Position.X, aq.Position.Y)
                    end
                end
            end
        end
        ah:UpdateTextGUI(true)
        if type(ah.RepairModuleCategories) == "function" then
            ah:RepairModuleCategories()
        end
    else
        ah:Save(ah.Profile, true)
    end

    ah.NewUser = false
    if ah.TutorialAPI and ah.TutorialAPI.isActive then
        ah.TutorialAPI:revertTutorialMode(false)
    end

    if ah.Downloader then
        ah.Downloader:Destroy()
        ah.Downloader = nil
    end
    ah.Loaded = al
    ah.Categories.Main.Options.Bind:SetBind(ah.Keybind)

    if d.isMobile then
        local ao = Instance.new("TextButton")
        ao.Size = UDim2.fromOffset(40, 40)

        local ap = j:GetGuiInset().Y
        ao.Position = UDim2.new(1, -90, 0, math.max(4, ap + 4))
        ao.BackgroundColor3 = Color3.new()
        ao.BackgroundTransparency = 0.5
        ao.Text = ""
        ao.Parent = B
        local aq = Instance.new("ImageLabel")
        aq.Size = UDim2.fromOffset(26, 26)
        aq.Position = UDim2.fromOffset(3, 3)
        aq.BackgroundTransparency = 1
        aq.Image = u("badscript/assets/new/vape.png")
        aq.Parent = ao
        local ar = Instance.new("UICorner")
        ar.Parent = ao
        ah.MobileToggleButton = ao
        local function toggleGui()
            if ah.ThreadFix then
                setthreadidentity(8)
            end
            for as, at in ah.Windows do
                at.Visible = false
            end
            for as, at in ah.Modules do
                if at.Bind.Button then
                    at.Bind.Button.Visible = v.Visible
                end
            end
            ah:SetClickGuiVisible(not v.Visible)
            z.Visible = false
            ah:BlurCheck()
        end
        ao.Activated:Connect(toggleGui)

        setupMobileSwipeDismiss(v, function()
            if v.Visible then
                toggleGui()
            end
        end)
    end
    ah:onload()
end

function d.LoadOptions(ah, ai, aj)
    for ak, al in aj do
        local am = ai.Options[ak]
        if not am then
            continue
        end
        if am.NoSave then
            continue
        end
        am:Load(al)
    end
end

function d.CheckBounds(ah, ai, aj)
    for ak, al in ah.Modules do
        if al.Name == aj then
            continue
        end
        if not al.Bind then
            continue
        end
        if type(al.Bind) ~= "table" then
            continue
        end

        local am = table.concat(al.Bind, " + "):upper()

        if am == ai then
            local an = ([[<font color="#ffd966"><b>%s</b></font>]]):format(am)
            local ao = ([[<font color="#6ab7ff"><b>%s</b></font>]]):format(al.Name)

            local ap = ([[<b><font color="#ffb347">Duplicate Bind:</font></b> %s <font color="#ffb347">is already used in</font> %s <font color="#ffb347"></font>]]):format(
                an,
                ao
            )

            d:CreateNotification("BadWars", ap, 10, "warning")
        end
    end
end

function d.Remove(ah, ai)
    local aj = (ah.Modules[ai] and ah.Modules or ah.Legit.Modules[ai] and ah.Legit.Modules)
    local ak = ah.Modules[ai] and "Modules" or ah.Legit.Modules[ai] and "Legit" or ah.Categories and "Categories"
    if aj and aj[ai] then
        local al = aj[ai]
        if ah.ThreadFix then
            setthreadidentity(8)
        end

        for am, an in { "Object", "Children", "Toggle", "Button" } do
            local ao = typeof(al[an]) == "table" and al[an].Object or al[an]
            if typeof(ao) == "Instance" then
                ao:Destroy()
                ao:ClearAllChildren()
            end
        end

        loopClean(al)
        aj[ai] = nil
    end
end

function d.SavePosition(ah, ai)
    if not ai then
        return nil
    end
    return {
        X = {
            Scale = ai.Position.X.Scale,
            Offset = ai.Position.X.Offset,
        },
        Y = {
            Scale = ai.Position.Y.Scale,
            Offset = ai.Position.Y.Offset,
        },
    }
end

function d.LoadPosition(ah, ai, aj)
    if not aj then
        bwarn(`LoadPositions: {tostring(ai)} has INVALID DATA!`)
        return
    end
    local ak = { X = { Scale = 0, Offset = 0 }, Y = { Scale = 0, Offset = 0 } }
    local function load(al, am)
        for an, ao in { "Scale", "Offset" } do
            if not am[ao] then
                continue
            end
            ak[al][ao] = am[ao]
        end
    end
    for al, am in { "X", "Y" } do
        if aj[am] ~= nil then
            if type(aj[am]) == "table" then
                load(am, aj[am])
            else
                ak[am].Offset = aj[am]
            end
        end
    end
    ai.Position = UDim2.new(ak.X.Scale, ak.X.Offset, ak.Y.Scale, ak.Y.Offset)
end

function d.Save(ah, ai, aj)
    if not ah.Loaded then
        return
    end
    local ak = {
        Categories = {},
        Profile = ai or ah.Profile,
        Profiles = ah.Profiles,
        Keybind = ah.Keybind,
    }
    ak.GUIColor = ah.GUI_DATA and ah.GUI_DATA.GUIColor or {}
    ak.GUIColor[ah.Profile] = {
        Hue = ah.GUIColor.Hue,
        Sat = ah.GUIColor.Sat,
        Value = ah.GUIColor.Value,
    }
    local al = {
        Modules = {},
        Categories = {},
        Legit = {},
    }

    if not aj then
        for am, an in ah.Categories do
            (an.Type ~= "Category" and am ~= "Main" and al or ak).Categories[am] = {
                Enabled = am ~= "Main" and an.Button and an.Button.Enabled or nil,
                Expanded = an.Type ~= "Overlay" and an.Type ~= "ModuleCategory" and an.Expanded or nil,
                Pinned = an.Pinned,
                Position = an.Type ~= "ModuleCategory" and ah:SavePosition(an.Object) or nil,
                Options = d:SaveOptions(an, an.Options),
                List = an.List,
                ListEnabled = an.ListEnabled,
            }
        end

        for am, an in ah.Modules do
            if an.NoSave then
                continue
            end
            al.Modules[an.SavingID or am] = {
                Enabled = an.Enabled,
                Favorited = an.StarActive,
                Bind = an.Bind.Button
                        and { Mobile = true, X = an.Bind.Button.Position.X.Offset, Y = an.Bind.Button.Position.Y.Offset }
                    or an.Bind,
                Options = d:SaveOptions(an, true),
            }
        end

        for am, an in ah.Legit.Modules do
            if an.NoSave then
                continue
            end
            al.Legit[am] = {
                Enabled = an.Enabled,
                Position = an.Children and { X = an.Children.Position.X.Offset, Y = an.Children.Position.Y.Offset }
                    or nil,
                Options = d:SaveOptions(an, an.Options),
            }
        end
    end

    local guiSaved, guiSaveError = safeWriteFile(
        "badscript/profiles/" .. str(game.GameId) .. "_" .. str(ah.Place) .. ".gui.txt",
        l:JSONEncode(ak),
        "gui-profile"
    )
    local profileSaved, profileSaveError = safeWriteFile(
        "badscript/profiles/" .. ah.Profile .. ah.Place .. ".txt",
        l:JSONEncode(al),
        "module-profile"
    )

    if not guiSaved or not profileSaved then
        if not ah._saveFailureNotified then
            ah._saveFailureNotified = true
            task.delay(30, function()
                ah._saveFailureNotified = false
            end)
            pcall(function()
                ah:CreateNotification(
                    "BadWars",
                    "Profile saving is temporarily unavailable. BadWars will keep running without repeating the error.",
                    6,
                    "warning"
                )
            end)
        end

        return false, guiSaveError or profileSaveError
    end

    ah._saveFailureNotified = false
    return true
end

function d.DisableSaving(ah)
    d:CreateNotification("BadWars", "Saving is disabled due to an error in BadWars!", 30, "warning")
    ah.Loaded = false
    ah.Save = function() end
end

function d.SaveOptions(ah, ai, aj)
    if not aj then
        return
    end
    aj = {}
    for ak, al in ai.Options do
        if not al.Save then
            continue
        end
        if al.NoSave then
            continue
        end
        al:Save(aj)
    end
    return aj
end

function d.Uninject(ah, ai)
    if ah._uninjecting then
        return
    end
    ah._uninjecting = true

    if not ai then
        pcall(function()
            ah:Save()
        end)
    end
    ah.Loaded = nil
    pcall(function()
        ah.SelfDestructEvent:Fire()
    end)

    for _, module in ah.Modules do
        if module.Enabled then
            pcall(function()
                module:Toggle()
            end)
        end
    end
    for _, module in ah.Legit.Modules do
        if module.Enabled then
            pcall(function()
                module:Toggle()
            end)
        end
    end
    for _, category in ah.Categories do
        if category.Type == "Overlay" and category.Button and category.Button.Enabled then
            pcall(function()
                category.Button:Toggle()
            end)
        end
    end

    if ah._OpenDropdown then
        pcall(ah._OpenDropdown)
        ah._OpenDropdown = nil
    end
    ah._tooltipOwner = nil
    if z then
        z.Visible = false
    end

    local tweenTargets = {}
    for instance in pairs(n.tweens) do
        tweenTargets[#tweenTargets + 1] = instance
    end
    for _, instance in tweenTargets do
        n:Cancel(instance, n.tweens)
    end
    table.clear(tweenTargets)
    for instance in pairs(n.tweenstwo) do
        tweenTargets[#tweenTargets + 1] = instance
    end
    for _, instance in tweenTargets do
        n:Cancel(instance, n.tweenstwo)
    end
    for target, thread in pairs(activeTextFlickers) do
        pcall(task.cancel, thread)
        activeTextFlickers[target] = nil
    end
    for target, state in pairs(activeImageFlickers) do
        pcall(state.cleanup)
        activeImageFlickers[target] = nil
    end
    for tween, connection in pairs(n.completionConnections) do
        pcall(function()
            connection:Disconnect()
        end)
        n.completionConnections[tween] = nil
    end
    table.clear(ah.RainbowTable)
    table.clear(ah.HeldKeybinds)

    ah:Cleanup()

    if ah.ThreadFix then
        pcall(setthreadidentity, 8)
    end
    pcall(function()
        if v then
            v.Visible = false
        end
        ah:BlurCheck()
    end)
    pcall(function()
        if ah.gui then
            ah.gui:Destroy()
            ah.gui = nil
        end
    end)

    table.clear(ah.Libraries)
    shared.vape = nil
    shared.BadReload = nil
    shared.BadIndependent = nil
end

B = Instance.new("ScreenGui")
B.Name = randomString()
B.DisplayOrder = 9999999
B.ZIndexBehavior = Enum.ZIndexBehavior.Global
B.IgnoreGuiInset = true
pcall(function()
    B.OnTopOfCoreBlur = true
end)

B.Parent = e(game:GetService("Players")).LocalPlayer.PlayerGui
B.ResetOnSpawn = false

d.gui = B
-- BADWARS_ASCII_TEXT_SANITIZER_V3_BEGIN
local TextSanitizer = {
    Connections = setmetatable({}, { __mode = "k" }),
    Updating = setmetatable({}, { __mode = "k" }),
}

local function bytes(...)
    return string.char(...)
end

local BYTE_REPLACEMENTS = {
    { bytes(0xC3, 0x97), "x" },
    { bytes(0xC3, 0x83, 0xE2, 0x80, 0x94), "x" },
    { bytes(0xC3, 0x82, 0xC3, 0x97), "x" },

    { bytes(0xC2, 0xB7), "-" },
    { bytes(0xE2, 0x80, 0xA2), "-" },
    { bytes(0xE2, 0x80, 0x93), "-" },
    { bytes(0xE2, 0x80, 0x94), "-" },

    { bytes(0xE2, 0x86, 0x90), "<-" },
    { bytes(0xE2, 0x86, 0x92), "->" },
    { bytes(0xE2, 0x86, 0x94), "<->" },

    { bytes(0xE2, 0x9C, 0x93), "OK" },
    { bytes(0xE2, 0x9C, 0x94), "OK" },
    { bytes(0xE2, 0x9C, 0x95), "x" },
    { bytes(0xE2, 0x9C, 0x96), "x" },

    { bytes(0xE2, 0x80, 0xA6), "..." },
    { bytes(0xE2, 0x80, 0x98), "'" },
    { bytes(0xE2, 0x80, 0x99), "'" },
    { bytes(0xE2, 0x80, 0x9C), "\"" },
    { bytes(0xE2, 0x80, 0x9D), "\"" },
    { bytes(0xC2, 0xA0), " " },
}

local CODEPOINT_REPLACEMENTS = {
    [0x00A0] = " ",
    [0x00A3] = "GBP",
    [0x00D7] = "x",

    [0x2013] = "-",
    [0x2014] = "-",
    [0x2018] = "'",
    [0x2019] = "'",
    [0x201C] = "\"",
    [0x201D] = "\"",
    [0x2022] = "-",
    [0x2026] = "...",

    [0x2190] = "<-",
    [0x2192] = "->",
    [0x2194] = "<->",

    [0x231F] = "+",
    [0x2713] = "OK",
    [0x2714] = "OK",
    [0x2715] = "x",
    [0x2716] = "x",
}

local function sanitizeDisplayText(value)
    local text = tostring(value or "")

    for _, replacement in ipairs(BYTE_REPLACEMENTS) do
        text = string.gsub(text, replacement[1], replacement[2])
    end

    local output = {}
    local decoded = pcall(function()
        for _, codepoint in utf8.codes(text) do
            if
                codepoint == 9
                or codepoint == 10
                or codepoint == 13
            then
                output[#output + 1] = utf8.char(codepoint)
            elseif codepoint >= 32 and codepoint <= 126 then
                output[#output + 1] = string.char(codepoint)
            else
                output[#output + 1] =
                    CODEPOINT_REPLACEMENTS[codepoint]
                    or "?"
            end
        end
    end)

    if decoded then
        return table.concat(output)
    end

    output = {}

    for index = 1, #text do
        local byte = string.byte(text, index)

        if
            byte == 9
            or byte == 10
            or byte == 13
            or (byte >= 32 and byte <= 126)
        then
            output[#output + 1] = string.char(byte)
        elseif byte < 128 then
            output[#output + 1] = "?"
        end
    end

    return table.concat(output)
end

local function sanitizeProperty(object, property)
    if TextSanitizer.Updating[object] then
        return
    end

    local readable, current = pcall(function()
        return object[property]
    end)

    if not readable or type(current) ~= "string" then
        return
    end

    local cleaned = sanitizeDisplayText(current)

    if cleaned == current then
        return
    end

    TextSanitizer.Updating[object] = true

    pcall(function()
        object[property] = cleaned
    end)

    TextSanitizer.Updating[object] = nil
end

local function watchTextObject(object)
    if TextSanitizer.Connections[object] then
        return
    end

    local isTextLabel = object:IsA("TextLabel")
    local isTextButton = object:IsA("TextButton")
    local isTextBox = object:IsA("TextBox")

    if not isTextLabel and not isTextButton and not isTextBox then
        return
    end

    local connections = {}

    if isTextBox then
        sanitizeProperty(object, "PlaceholderText")

        connections[#connections + 1] =
            object:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
                sanitizeProperty(object, "PlaceholderText")
            end)

        connections[#connections + 1] =
            object.FocusLost:Connect(function()
                sanitizeProperty(object, "Text")
            end)
    else
        sanitizeProperty(object, "Text")

        connections[#connections + 1] =
            object:GetPropertyChangedSignal("Text"):Connect(function()
                sanitizeProperty(object, "Text")
            end)
    end

    TextSanitizer.Connections[object] = connections

    object.Destroying:Once(function()
        local stored = TextSanitizer.Connections[object]

        if stored then
            for _, connection in ipairs(stored) do
                pcall(function()
                    connection:Disconnect()
                end)
            end
        end

        TextSanitizer.Connections[object] = nil
        TextSanitizer.Updating[object] = nil
    end)
end

d.SanitizeText = sanitizeDisplayText
shared.BadSanitizeText = sanitizeDisplayText

for _, descendant in ipairs(B:GetDescendants()) do
    watchTextObject(descendant)
end

d:Clean(B.DescendantAdded:Connect(watchTextObject))
-- BADWARS_ASCII_TEXT_SANITIZER_V3_END

w = Instance.new("Frame")
w.Name = "ScaledGui"
w.Size = UDim2.fromScale(1, 1)
w.BackgroundTransparency = 1
w.Parent = B
v = Instance.new("CanvasGroup")
v.Name = "ClickGui"
v.Size = UDim2.fromScale(1, 1)
v.BackgroundTransparency = 1
v.GroupTransparency = 0
v.Interactable = true
v.Active = true
v.Visible = false
v.Parent = w

local clickGuiVisibilityGeneration = 0
function d.SetClickGuiVisible(self, visible, instant)
    visible = visible == true
    clickGuiVisibilityGeneration += 1
    local generation = clickGuiVisibilityGeneration

    if visible then
        v.Visible = true
        v.Active = true
        v.Interactable = true

        if instant then
            n:Cancel(v)
            v.GroupTransparency = 0
        else
            v.GroupTransparency = math.max(v.GroupTransparency, 0.08)
            n:Tween(v, o.TweenFast, {
                GroupTransparency = 0,
            })
        end
        return
    end

    v.Active = false
    v.Interactable = false

    if instant or not v.Visible then
        n:Cancel(v)
        v.GroupTransparency = 1
        v.Visible = false
        return
    end

    local fade = n:Tween(v, o.TweenFast, {
        GroupTransparency = 1,
    })

    local function finish()
        if generation == clickGuiVisibilityGeneration
            and not v.Interactable
        then
            v.Visible = false
        end
    end

    if fade then
        fade.Completed:Once(finish)
    else
        finish()
    end
end

LayoutIntelligence:Start()
d:Clean(B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    LayoutIntelligence:RequestResolve()
end))
d:Clean(v:GetPropertyChangedSignal("Visible"):Connect(function()
    if v.Visible and v.GroupTransparency >= 0.99 then
        v.Active = true
        v.Interactable = true
        v.GroupTransparency = 0.08
        n:Tween(v, o.TweenFast, {
            GroupTransparency = 0,
        })
    end
    d.VisibilityChanged:Fire(v.Visible)
end))
local ah = Instance.new("TextLabel")
ah.Size = UDim2.fromScale(1, 0.02)
ah.Position = UDim2.fromScale(0, 0.97)
ah.BackgroundTransparency = 1
ah.Text = "BadWars support"
ah.TextScaled = true
ah.TextColor3 = Color3.new(1, 1, 1)
ah.TextStrokeTransparency = 0.5
ah.FontFace = o.Font
ah.Parent = v
d.TutorialAPI = {
    tutorialType = 2,
    isActive = false,
    label = ah,
    defaultText = "",
    cleanTutorialLabel = function(ai)
        if ai.addedBlur then
            pcall(function()
                ai.addedBlur:Destroy()
            end)
            ai.addedBlur = nil
        end
        ai.isActive = false
        ai.GlobeIconWait = false
        ai.label.Visible = false
        ai.label.Text = ""
    end,
    activateTutorial = function(ai)
        ai:cleanTutorialLabel()
    end,
    tweenToSecondPosition = function(ai)
        ai:cleanTutorialLabel()
    end,
    revertTutorialMode = function(ai)
        ai:cleanTutorialLabel()
    end,
    setText = function(ai)
        ai:cleanTutorialLabel()
    end,
}
ah.Visible = false
ah.Text = ""
local ai = Instance.new("TextButton")
ai.Name = "TutorialBlockerDisabled"
ai.Size = UDim2.fromOffset(0, 0)
ai.BackgroundTransparency = 1
ai.Modal = false
ai.Active = false
ai.Visible = false
ai.Text = ""
ai.Parent = v
local aj = Instance.new("ImageLabel")
aj.Size = UDim2.fromOffset(64, 64)
aj.BackgroundTransparency = 1
aj.Visible = false
aj.Image = "rbxasset://textures/Cursors/KeyboardMouse/ArrowFarCursor.png"
aj.Parent = B
q = Instance.new("Folder")
q.Name = "Notifications"
q.Parent = w
s = Instance.new("Folder")
s.Name = "Prompts"
s.Parent = w

local premiumStrokeMinimums = {
    MainStroke = 0.42,
    NavigationStroke = 0.72,
    CategoryStroke = 0.42,
    ModuleStroke = 0.82,
    ModuleCategoryStroke = 0.82,
    LegitStroke = 0.42,
    LegitCardStroke = 0.72,
    LegitWidgetStroke = 0.58,
    OptionsStroke = 0.9,
    TextBoxStroke = 0.72,
    OverlayStroke = 0.58,
    NotificationStroke = 0.52,
    TooltipStroke = 0.38,
}

local function normalizePremiumStroke(instance)
    if not instance:IsA("UIStroke") then
        return
    end

    local minimumTransparency = premiumStrokeMinimums[instance.Name]
    if minimumTransparency == nil then
        return
    end

    instance.Thickness = 1
    instance.LineJoinMode = Enum.LineJoinMode.Round
    instance.Transparency = math.max(instance.Transparency, minimumTransparency)
end

for _, descendant in ipairs(B:GetDescendants()) do
    normalizePremiumStroke(descendant)
end
d:Clean(B.DescendantAdded:Connect(normalizePremiumStroke))

z = Instance.new("TextLabel")
z.Name = "Tooltip"
z.Position = UDim2.fromScale(-1, -1)
z.ZIndex = 100000
z.BackgroundColor3 = o.Elevated
z.Visible = false
z.Text = ""
z.TextColor3 = o.TextStrong
z.TextStrokeColor3 = o.Main
z.TextStrokeTransparency = 0.82
z.TextSize = d.isMobile and 14 or 13
z.TextWrapped = true
z.RichText = false
z.TextXAlignment = Enum.TextXAlignment.Left
z.TextYAlignment = Enum.TextYAlignment.Center
z.FontFace = o.FontSemiBold
z.BackgroundTransparency = 1
z.Parent = w
addCorner(z, o.Radius)
tooltipStroke = addStroke(z, o.BorderStrong, 1, 1, "TooltipStroke")
y = addShadow(z, true)
y.ImageTransparency = 1
tooltipScale = addScale(z)
tooltipScale.Scale = 0.985
tooltipAccent = Instance.new("Frame")
tooltipAccent.Name = "Accent"
tooltipAccent.Size = UDim2.new(0, 2, 1, -12)
tooltipAccent.Position = UDim2.fromOffset(5, 6)
tooltipAccent.BorderSizePixel = 0
tooltipAccent.BackgroundColor3 = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
tooltipAccent.BackgroundTransparency = 1
tooltipAccent.ZIndex = z.ZIndex + 1
tooltipAccent.Parent = z
addCorner(tooltipAccent, UDim.new(1, 0))
connectguicolorchange(function(hue, saturation, value)
    if tooltipAccent.Parent then
        tooltipAccent.BackgroundColor3 = Color3.fromHSV(hue, saturation, value)
    end
end)

local tooltipPadding = Instance.new("UIPadding")
tooltipPadding.PaddingLeft = UDim.new(0, 14)
tooltipPadding.PaddingRight = UDim.new(0, 11)
tooltipPadding.PaddingTop = UDim.new(0, 7)
tooltipPadding.PaddingBottom = UDim.new(0, 7)
tooltipPadding.Parent = z
d:Clean(h.InputBegan:Connect(function(input)
    if
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseButton2
        or input.UserInputType == Enum.UserInputType.Touch
    then
        hideTooltip(true)
    end
end))

d:Clean(h.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        hideTooltip(true)
    end
end))
local ak = Instance.new("Frame")
ak.Size = UDim2.fromScale(1, 1)
ak.Position = UDim2.fromOffset(0, 0)
ak.ZIndex = 79
ak.BackgroundTransparency = 1
ak.Parent = z
addCorner(ak, o.Radius)
A = Instance.new("UIScale")
local function responsiveScale()
    local viewport = B.AbsoluteSize
    local width = viewport.X > 0 and viewport.X or 1920
    local height = viewport.Y > 0 and viewport.Y or 1080

    if d.isMobile then
        return math.clamp(
            math.min(width / 820, height / 620),
            0.58,
            0.9
        )
    end

    return math.clamp(
        math.min(width / 1920, height / 1080),
        0.62,
        1.05
    )
end
A.Scale = responsiveScale()
A.Parent = w
d.guiscale = A
w.Size = UDim2.fromScale(1 / A.Scale, 1 / A.Scale)

local resizeGeneration = 0

d:Clean(B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    resizeGeneration += 1
    local generation = resizeGeneration

    task.delay(0.08, function()
        if generation ~= resizeGeneration then
            return
        end

        if d.Scale.Enabled then
            A.Scale = responsiveScale()
        end

        if d._InitialLayoutReady and d.FinalizeInitialLayout then
            d:FinalizeInitialLayout(true)
        end
    end)
end))

d:Clean(A:GetPropertyChangedSignal("Scale"):Connect(function()
    A.Scale = math.clamp(A.Scale, 0.5, 2)
    w.Size = UDim2.fromScale(1 / A.Scale, 1 / A.Scale)
    if z then
        z.Visible = false
    end
    task.defer(function()
        if not B or not B.Parent then
            return
        end
        for _, window in d.Windows do
            if typeof(window) == "Instance" and window:IsA("GuiObject") and window.Parent then
                local clamped = clampGuiObjectToViewport(window, window.AbsolutePosition)
                if (clamped - window.AbsolutePosition).Magnitude > 0.5 then
                    setGuiAbsolutePosition(window, clamped)
                end
            end
        end
    end)
end))

local cursorConnection
local function stopCursorTracking()
    if cursorConnection then
        cursorConnection:Disconnect()
        cursorConnection = nil
    end
    aj.Visible = false
end

local function startCursorTracking()
    stopCursorTracking()
    if not v.Visible or not h.MouseEnabled then
        return
    end

    cursorConnection = k.RenderStepped:Connect(function()
        if not v.Visible or d.Loaded == nil then
            stopCursorTracking()
            return
        end

        local anyVisible = v.Visible
        for _, window in d.Windows do
            anyVisible = anyVisible or window.Visible
        end
        if not anyVisible then
            stopCursorTracking()
            return
        end

        aj.Visible = not h.MouseIconEnabled
        if aj.Visible then
            local mouse = h:GetMouseLocation()
            aj.Position = UDim2.fromOffset(mouse.X - 31, mouse.Y - 32)
        end
    end)
end

d:Clean(function()
    stopCursorTracking()
end)

d:Clean(v:GetPropertyChangedSignal("Visible"):Connect(function()
    if not v.Visible then
        if d.HideTooltip then
            d.HideTooltip(true)
        end
        if d._OpenDropdown then
            pcall(d._OpenDropdown, true)
            d._OpenDropdown = nil
        end
        if d._OpenModuleOptions then
            pcall(d._OpenModuleOptions, true)
            d._OpenModuleOptions = nil
        end
        if d._OpenLegitOptions then
            pcall(d._OpenLegitOptions, true)
            d._OpenLegitOptions = nil
        end
        stopCursorTracking()
    else
        startCursorTracking()
    end

    d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value, true)
end))


d:CreateGUI()
d.Categories.Main:CreateDivider()
d.Categories.Main:CreateSettingsDivider()

local am = d.Categories.Main:CreateSettingsPane({ Name = "General" })
d.MultiKeybind = am:CreateToggle({
    Name = "Enable Multi-Keybinding",
    Tooltip = "Allows multiple keys to be bound to a module (eg. G + H)",
})
d.QueueTeleportEnabledToggle = am:CreateToggle({
    Name = "Queue On Teleport",
    Default = true,
    Tooltip = "Makes BadWars auto execute every time you teleport",
    Function = function(an)
        shared.DISABLED_QUEUE_ON_TELEPORT = not an
        if not d.Notifications then
            return
        end
        d:CreateNotification(
            "BadWars",
            "Auto Execute"
                .. "<font color='#FFFFFF'> was </font>"
                .. (an and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>")
                .. "<font color='#FFFFFF'>!</font>",
            5
        )
    end,
})
d.TranslationDropdown = am:CreateDropdown({
    Name = "Language",
    Tooltip = "Choose your language :D",
    List = {},
    Function = function() end,
    NoSave = true,
})
F(function()
    d.Languages = {}
    local an = {}
    local ao
    for ap, aq in ac.languages do
        ap = tostring(ap)
        local ar = aa[ap] or ""
        local as = `{ap} {tostring(ar)}`
        d.Languages[as] = ap
        if shared.TargetLanguage == ap then
            ao = as
        end
        if table.find(an, as) then
            continue
        end
        table.insert(an, as)
    end
    d.TranslationDropdown:SetValues(an, ab)
    if ao then
        d.TranslationDropdown:SetValue(ao)
    end
    d.TranslationDropdown:SetCallback(function(ap)
        local aq = d.Languages[ap]
        if aq then
            shared.TargetLanguage = aq

            pcall(function()
                if not isfolder("badwars_translations") then
                    makefolder("badwars_translations")
                end
                safeWriteFile("badwars_translations/lang.txt", tostring(shared.TargetLanguage), "translation-language")
            end)

            local ar = aa[aq] or ""
            local as = ([[<font color="#6ab7ff"><b>%s</b></font>]]):format(aq)
            local at = ([[<font color="#ffffff"><b>%s</b></font>]]):format(ar)

            local au = ([[<b><font color="#7df9ff">Language switched to:</font></b> %s %s]]):format(as, at)

            d:CreateNotification("Language Updated", au, 3, "info")
        end
    end)
end)
am:CreateButton({
    Name = "Reset current profile",
    Function = function()
        d.Save = function() end
        if D("badscript/profiles/" .. d.Profile .. d.Place .. ".txt") and delfile then
            delfile("badscript/profiles/" .. d.Profile .. d.Place .. ".txt")
        end
        shared.BadReload = true
        if shared.BadDeveloper then
            loadstring(readfile("badscript/loader.lua"), "loader")()
        else
            loadstring(
                d.http_function(
                    "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua",
                    true
                ),
                "loader"
            )()
        end
    end,
    Tooltip = "This will set your profile to the default BadWars settings",
})
am:CreateButton({
    Name = "Self destruct",
    Function = function()
        d:Uninject()
    end,
    Tooltip = "Removes BadWars from the current game",
})
am:CreateButton({
    Name = "Reinject",
    Function = function()
        shared.BadReload = true
        if shared.BadDeveloper then
            loadstring(readfile("badscript/loader.lua"), "loader")()
        else
            loadstring(
                d.http_function(
                    "https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua",
                    true
                ),
                "loader"
            )()
        end
    end,
    Tooltip = "Reloads BadWars for debugging purposes",
})

d:CreateCategory({
    Name = "Combat",
    Icon = u("badscript/assets/new/combaticon.png"),
    Size = UDim2.fromOffset(13, 14),
    Visible = true,
})
d:CreateCategory({
    Name = "Blatant",
    Icon = u("badscript/assets/new/blatanticon.png"),
    Size = UDim2.fromOffset(14, 14),
    Visible = true,
})
d:CreateCategory({
    Name = "Render",
    Icon = u("badscript/assets/new/rendericon.png"),
    Size = UDim2.fromOffset(15, 14),
    Visible = true,
})
d:CreateCategory({
    Name = "Utility",
    Icon = u("badscript/assets/new/utilityicon.png"),
    Size = UDim2.fromOffset(15, 14),
    Visible = true,
})
d:CreateCategory({
    Name = "World",
    Icon = u("badscript/assets/new/worldicon.png"),
    Size = UDim2.fromOffset(14, 14),
    Visible = true,
})
for an, ao in
    {
        {
            Name = "Inventory",
            Icon = u("badscript/assets/new/inventoryicon.png"),
            Size = UDim2.fromOffset(15, 14),
            GuiColorSync = true,
        },
        {
            Name = "Minigames",
            Icon = u("badscript/assets/new/miniicon.png"),
            Size = UDim2.fromOffset(19, 12),
            GuiColorSync = true,
        },
    }
do
    d.Categories[ao.Name] = d.Categories.World:CreateModuleCategory(ao)
end
d:CreateCategory({
    Name = "Legit",
    Icon = u("badscript/assets/new/legittab.png"),
    Size = UDim2.fromOffset(14, 14),
    Visible = true,
})
d.Categories.Main:CreateDivider("misc")
d:Clean(d.PreloadEvent:Connect(function()
    d.SortGuiCallback(true)
end))

local an
local ao = {
    Hue = 1,
    Sat = 1,
    Value = 1,
}
local ap = {
    Name = "Friends",
    Icon = u("badscript/assets/new/friendstab.png"),
    Size = UDim2.fromOffset(17, 16),
    Placeholder = "Roblox username",
    Color = Color3.fromRGB(5, 134, 105),
    Function = function()
        an.Update:Fire()
        an.ColorUpdate:Fire(ao.Hue, ao.Sat, ao.Value)
    end,
}
an = d:CreateCategoryList(ap)
an.Update = Instance.new("BindableEvent")
an.ColorUpdate = Instance.new("BindableEvent")
an:CreateToggle({
    Name = "Recolor visuals",
    Darker = true,
    Default = true,
    Function = function()
        an.Update:Fire()
        an.ColorUpdate:Fire(ao.Hue, ao.Sat, ao.Value)
    end,
})
ao = an:CreateColorSlider({
    Name = "Friends color",
    Darker = true,
    Function = function(aq, ar, as)
        for at, au in an.Object.Children:GetChildren() do
            local av = au:FindFirstChild("Dot")
            if av and av.BackgroundColor3 ~= m.Light(o.Main, 0.37) then
                av.BackgroundColor3 = Color3.fromHSV(aq, ar, as)
                av.Dot.BackgroundColor3 = av.BackgroundColor3
            end
        end
        ap.Color = Color3.fromHSV(aq, ar, as)
        an.ColorUpdate:Fire(aq, ar, as)
    end,
})
an:CreateToggle({
    Name = "Use friends",
    Darker = true,
    Default = true,
    Function = function()
        an.Update:Fire()
        an.ColorUpdate:Fire(ao.Hue, ao.Sat, ao.Value)
    end,
})
d:Clean(an.Update)
d:Clean(an.ColorUpdate)

if d.ProfilesEnabled then
    d:CreateCategoryList({
        Name = "Profiles",
        Icon = u("badscript/assets/new/profilesicon.png"),
        Size = UDim2.fromOffset(17, 10),
        Position = UDim2.fromOffset(12, 16),
        Placeholder = "Type name",
        Profiles = true,
    })
end

if d.TutorialEnabled then
d:connectOnLoad(function(aq)
    if aq.NewUser then
        task.spawn(function()
            task.wait(1.5)
            if v.Visible then
                v.Visible = false
            end
            task.wait(0.1)
            aq:CreatePrompt({
                Title = "Welcome to BadWars",
                Text = "Would you like to pick out a pre made config?",
                ConfirmText = "Yeah",
                CancelText = "No, Thank you",
                CancelColor = Color3.fromRGB(120, 40, 40),
                CancelHoverColor = Color3.fromRGB(170, 60, 60),
                ConfirmColor = Color3.fromRGB(40, 120, 40),
                ConfirmHoverColor = Color3.fromRGB(60, 170, 60),
                OnConfirm = function()
                    local ar = d.ProfilesCategoryListWindow
                    if ar then
                        d.TutorialAPI:activateTutorial()
                        ar:setup()
                        n:Tween(ar.scale, TweenInfo.new(0.15), {
                            Scale = 1.1,
                        })
                        n:Tween(ar.stroke, TweenInfo.new(0.15), {
                            Thickness = 3,
                        })
                        ar.window.MouseLeave:Once(function()
                            n:Tween(ar.scale, TweenInfo.new(0.15), {
                                Scale = 1,
                            })
                        end)
                        v.Visible = true
                        task.delay(0.1, function()
                            d.TutorialAPI.GlobeIconWait = true
                            d.TutorialAPI:setText("Click on the globe icon to open the configs window")
                            flickerImageEffect(ar.globeicon, 5, 0.22)
                        end)
                    end
                end,
                OnCancel = function()
                    v.Visible = true
                    d.TutorialAPI:activateTutorial()
                    d.TutorialAPI:tweenToSecondPosition()
                    task.wait(1)
                    d.TutorialAPI:setText(
                        d.MobileToggleButton and "Press the button in the top right to open GUI"
                            or "Press " .. table.concat(d.Keybind, " + "):upper() .. " to open & close the GUI"
                    )
                    task.wait(3)
                    d.TutorialAPI:revertTutorialMode(true)
                end,
            })
        end)
    end
end)
end

local aq
aq = d:CreateCategoryList({
    Name = "Targets",
    Icon = u("badscript/assets/new/friendstab.png"),
    Size = UDim2.fromOffset(17, 16),
    Placeholder = "Roblox username",
    Function = function()
        aq.Update:Fire()
    end,
})
aq.Update = Instance.new("BindableEvent")
d:Clean(aq.Update)

d:CreateLegit()
d:CreateSearch()
-- HUD/display features are ordinary Render modules.  There is intentionally
-- no Overlays sidebar entry, module-category expander, page, or input blocker.
d.OverlaysModuleCategory = nil

local as = d.Categories.Main:CreateSettingsPane({ Name = "Modules" })
as:CreateToggle({
    Name = "Teams by server",
    Tooltip = "Ignore players on your team designated by the server",
    Default = true,
    Function = function()
        if d.Libraries.entity and d.Libraries.entity.Running then
            d.Libraries.entity.refresh()
        end
    end,
})
as:CreateToggle({
    Name = "Use team color",
    Tooltip = "Uses the TeamColor property on players for render modules",
    Default = true,
    Function = function()
        if d.Libraries.entity and d.Libraries.entity.Running then
            d.Libraries.entity.refresh()
        end
    end,
})

local at = d.Categories.Main:CreateSettingsPane({ Name = "GUI" })
d.Blur = at:CreateToggle({
    Name = "Blur background",
    Function = function()
        d:BlurCheck()
    end,
    Default = false,
    Tooltip = "Blur the background of the GUI",
})
at:CreateToggle({
    Name = "GUI bind indicator",
    Default = true,
    Tooltip = "Displays a message indicating your GUI upon injecting.\nI.E. 'Press RSHIFT to open GUI'",
})
at:CreateToggle({
    Name = "Show tooltips",
    Function = function(au)
        d.TooltipsEnabled = au
        z.Visible = false
        y.Visible = au
    end,
    Default = true,
    Tooltip = "Toggles visibility of these",
})
at:CreateToggle({
    Name = "Show legit mode",
    Function = function(au)
        v.Search.Legit.Visible = au
        v.Search.LegitDivider.Visible = au
        v.Search.TextBox.Size = UDim2.new(1, au and -50 or -10, 0, 37)
        v.Search.TextBox.Position = UDim2.fromOffset(au and 50 or 10, 0)
    end,
    Default = true,
    Tooltip = "Shows the button to change to Legit Mode",
})
local au = { Object = {}, Value = 1 }
d.Scale = at:CreateToggle({
    Name = "Auto rescale",
    Default = true,
    Function = function(av)
        au.Object.Visible = not av
        if av then
            A.Scale = responsiveScale()
        else
            A.Scale = au.Value
        end
    end,
    Tooltip = "Automatically rescales the gui using the screens resolution",
})
au = at:CreateSlider({
    Name = "Scale",
    Min = 0.5,
    Max = 2,
    Decimal = 10,
    Function = function(av, aw)
        if aw and not d.Scale.Enabled then
            A.Scale = av
        end
    end,
    Default = 1,
    Darker = true,
    Visible = false,
})
d.RainbowMode = at:CreateDropdown({
    Name = "Rainbow Mode",
    List = { "Normal", "Gradient", "Retro" },
    Tooltip = "Normal - Smooth color fade\nGradient - Gradient color fade\nRetro - Static color",
})
d.RainbowSpeed = at:CreateSlider({
    Name = "Rainbow speed",
    Min = 0.1,
    Max = 10,
    Decimal = 10,
    Default = 1,
    Tooltip = "Adjusts the speed of rainbow values",
})
d.RainbowUpdateSpeed = at:CreateSlider({
    Name = "Rainbow update rate",
    Min = 1,
    Max = 144,
    Default = 60,
    Tooltip = "Adjusts the update rate of rainbow values",
    Suffix = "hz",
})
d.TooltipSlider = at:CreateSlider({
    Name = "Tooltip Text Size",
    Min = 5,
    Max = 30,
    Default = 15,
    Tooltip = "Adjusts the tooltip's text size",
    Function = function(av)
        z.TextSize = av
    end,
})
at:CreateButton({
    Name = "Reset GUI positions",
    Function = function()
        for av, aw in d.Categories do
            aw.Object.Position = UDim2.fromOffset(6, 42)
        end
    end,
    Tooltip = "This will reset your GUI back to default",
})
d.SortGuiCallback = function(av)
    local aw = {
        GUICategory = 1,
        CombatCategory = 2,
        BlatantCategory = 3,
        RenderCategory = 4,
        UtilityCategory = 5,
        WorldCategory = 6,
        InventoryCategory = 7,
        MinigamesCategory = 8,
        LegitCategory = 9,
        ProfilesCategoryList = 10,
        TargetsCategoryList = 11,
        FriendsCategoryList = 12,
    }
    local ax = {}
    for ay, az in d.Categories do
        if az.Type == "Overlay" then
            continue
        end
        if av and az.Object.Name == "ProfilesCategoryList" then
            continue
        end
        table.insert(ax, az)
    end
    table.sort(ax, function(ay, az)
        return (aw[ay.Object.Name] or 99) < (aw[az.Object.Name] or 99)
    end)

    local ay = 0
    for az, aA in ax do
        if aA.Object.Visible then
            aA.Object.Position = UDim2.fromOffset(6 + (ay % 8 * (UI_WINDOW_WIDTH + UI_WINDOW_GAP)), 60 + (ay > 7 and 360 or 0))
            ay += 1
        end
    end
end

function d.WaitForModuleReadiness(self, timeoutSeconds)
    local deadline = os.clock() + (tonumber(timeoutSeconds) or 4)

    repeat
        task.wait()
    until
        self._PendingModuleCallbacks <= 0
        or os.clock() >= deadline
        or self.Loaded == nil

    task.wait()
    return self._PendingModuleCallbacks <= 0
end

function d.FinalizeInitialLayout(self, resizeOnly)
    self._SuppressEntryAnimation = true
    if self._OpenDropdown then pcall(self._OpenDropdown, true); self._OpenDropdown = nil end
    pcall(function() self:RepairModuleCategories() end)
    pcall(function() self:SortAllModules() end)

    local pendingVisibility = {}
    for _, category in self.Categories do
        if type(category) == "table" and category.OriginalCategory and category.Object and category.Object.Parent then
            local shouldShow = not category.Button or category.Button.Enabled ~= false
            pendingVisibility[#pendingVisibility + 1] = { Category = category, Visible = shouldShow }
            if not resizeOnly then category.Object.Visible = false end
            if shouldShow and category.Expand then category:Expand(true, true) end
            if category.Scroll then category.Scroll.CanvasPosition = resizeOnly and category.Scroll.CanvasPosition or Vector2.zero end
            if category.RefreshLayout then category.RefreshLayout(true) end
        end
    end

    if self.SortGuiCallback then self.SortGuiCallback(false) end
    if not resizeOnly then task.wait() end
    for _, entry in ipairs(pendingVisibility) do
        if entry.Category.Object and entry.Category.Object.Parent then entry.Category.Object.Visible = entry.Visible end
    end

    local mainCategory = self.Categories.Main
    if mainCategory and mainCategory.Object then mainCategory.Object.Visible = true end
    for _, window in self.Windows do
        if typeof(window) == "Instance" and window:IsA("GuiObject") and window.Parent then
            local scale = window:FindFirstChildOfClass("UIScale")
            if scale then scale.Scale = 1 end
        end
    end
    self._InitialLayoutReady = true
    self._SuppressEntryAnimation = false
end
at:CreateButton({
    Name = "Sort GUI",
    Function = d.SortGuiCallback,
    Tooltip = "Sorts GUI",
})

local av = d.Categories.Main:CreateSettingsPane({ Name = "Notifications" })
d.NotificationsBackground = av:CreateToggle({
    Name = "GUI Theme Background",
    Tooltip = "Syncs the Background with the GUI Theme",
    Default = false,
    Darker = true,
})
d.Notifications = av:CreateToggle({
    Name = "Notifications",
    Function = function(aw)
        if d.ToggleNotifications.Object then
            d.ToggleNotifications.Object.Visible = aw
        end
    end,
    Tooltip = "Shows notifications",
    Default = true,
})
d.ToggleNotifications = av:CreateToggle({
    Name = "Toggle alert",
    Tooltip = "Notifies you if a module is enabled/disabled.",
    Default = true,
    Darker = true,
})
d.FavoriteNotifications = av:CreateToggle({
    Name = "Favorite notify",
    Tooltip = "Notifies you if when you favorite a module.",
    Default = true,
    Darker = true,
})
d.BindNotifications = av:CreateToggle({
    Name = "Bind notify",
    Tooltip = "Notifies you if when you bind a module.",
    Default = true,
    Darker = true,
})

d.GUIColor = d.Categories.Main:CreateGUISlider({
    Name = "GUI Theme",
    Function = function(aw, ax, ay)
        d:UpdateGUI(aw, ax, ay, true)
    end,
})
d.Categories.Main:CreateBind()

local aw = d:CreateOverlay({
    Name = "Text GUI",
    Icon = u("badscript/assets/new/textguiicon.png"),
    Size = UDim2.fromOffset(16, 12),
    Position = UDim2.fromOffset(12, 14),
    Function = function()
        d:UpdateTextGUI()
    end,
})
local ax = aw:CreateDropdown({
    Name = "Sort",
    List = { "Alphabetical", "Length" },
    Default = "Length",
    Function = function()
        d:UpdateTextGUI()
    end,
})
local ay = aw:CreateFont({
    Name = "Font",
    Blacklist = "Arial",
    Function = function()
        d:UpdateTextGUI()
    end,
})
local az
local aA = aw:CreateDropdown({
    Name = "Color Mode",
    List = { "Match GUI color", "Custom color" },
    Function = function(aA)
        az.Object.Visible = aA == "Custom color"
        d:UpdateTextGUI()
    end,
})
az = aw:CreateColorSlider({
    Name = "Text GUI color",
    Function = function()
        d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
    end,
    Darker = true,
    Visible = false,
})
local aB = Instance.new("UIScale")
aB.Parent = aw.Children
aw:CreateSlider({
    Name = "Scale",
    Min = 0,
    Max = 2,
    Decimal = 10,
    Default = 1,
    Function = function(aC)
        aB.Scale = aC
        d:UpdateTextGUI()
    end,
})
local aC = aw:CreateToggle({
    Name = "Shadow",
    Tooltip = "Renders shadowed text.",
    Default = true,
    NoDefaultCallback = true,
    Function = function()
        d:UpdateTextGUI()
    end,
})
local aD
local aE = aw:CreateToggle({
    Name = "Gradient",
    Tooltip = "Renders a gradient",
    Default = true,
    NoDefaultCallback = true,
    Function = function(aE)
        aD.Object.Visible = aE
        d:UpdateTextGUI()
    end,
})
aD = aw:CreateToggle({
    Name = "V4 Gradient",
    Function = function()
        d:UpdateTextGUI()
    end,
    Default = true,
    NoDefaultCallback = true,
    Darker = true,
    Visible = aE.Enabled,
})
local aF = aw:CreateToggle({
    Name = "Animations",
    Tooltip = "Use animations on text gui",
    Function = function()
        d:UpdateTextGUI()
    end,
})
local aH = aw:CreateToggle({
    Name = "Watermark",
    Tooltip = "Renders a BadWars watermark",
    Default = true,
    NoDefaultCallback = true,
    Function = function()
        d:UpdateTextGUI()
    end,
})
local aI = {
    Value = 0.5,
    Object = { Visible = {} },
}
local aJ = { Enabled = false }
local aK = aw:CreateToggle({
    Name = "Render background",
    Default = true,
    NoDefaultCallback = true,
    Function = function(aK)
        aI.Object.Visible = aK
        aJ.Object.Visible = aK
        d:UpdateTextGUI()
    end,
})
aI = aw:CreateSlider({
    Name = "Transparency",
    Min = 0,
    Max = 1,
    Default = 0.6,
    Decimal = 10,
    Function = function()
        d:UpdateTextGUI()
    end,
    Darker = true,
    Visible = aK.Enabled,
})
aJ = aw:CreateToggle({
    Name = "Tint",
    Function = function()
        d:UpdateTextGUI()
    end,
    Default = true,
    NoDefaultCallback = true,
    Darker = true,
    Visible = aK.Enabled,
})
local aL
local aM = aw:CreateToggle({
    Name = "Hide modules",
    Tooltip = "Allows you to blacklist certain modules from being shown.",
    Function = function(aM)
        aL.Object.Visible = aM
        d:UpdateTextGUI()
    end,
})
aL = aw:CreateTextList({
    Name = "Blacklist",
    Tooltip = "Name of module to hide.",
    Icon = u("badscript/assets/new/blockedicon.png"),
    Tab = u("badscript/assets/new/blockedtab.png"),
    TabSize = UDim2.fromOffset(21, 16),
    Color = Color3.fromRGB(250, 50, 56),
    Function = function()
        d:UpdateTextGUI()
    end,
    Visible = false,
    Darker = true,
})
local aN = aw:CreateToggle({
    Name = "Hide render",
    Function = function()
        d:UpdateTextGUI()
    end,
})
local aO
local aP
local aQ
local aR
local aS = aw:CreateToggle({
    Name = "Add custom text",
    Function = function(aS)
        aO.Object.Visible = aS
        aP.Object.Visible = aS
        aQ.Object.Visible = aS
        aR.Object.Visible = aQ.Enabled and aS
        d:UpdateTextGUI()
    end,
})
aO = aw:CreateTextBox({
    Name = "Custom text",
    Function = function()
        d:UpdateTextGUI()
    end,
    Darker = true,
    Visible = false,
})
d.settextguicustomtext = function(aT)
    aS:SetValue(true)
    aO:SetValue(tostring(aT or ""), true)
    aO.Object.Visible = true
    aP.Object.Visible = true
    aQ.Object.Visible = true
    aR.Object.Visible = aQ.Enabled
    d:UpdateTextGUI()
end
aP = aw:CreateFont({
    Name = "Custom Font",
    Blacklist = "Arial",
    Function = function()
        d:UpdateTextGUI()
    end,
    Darker = true,
    Visible = false,
})
aQ = aw:CreateToggle({
    Name = "Set custom text color",
    Function = function(aT)
        aR.Object.Visible = aT
        d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
    end,
    Darker = true,
    Visible = false,
})
aR = aw:CreateColorSlider({
    Name = "Color of custom text",
    Function = function()
        d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
    end,
    Darker = true,
    Visible = false,
})

local aT = {}
local aU = Instance.new("ImageLabel")
aU.Name = "Logo"
aU.Size = UDim2.fromOffset(80, 21)
aU.Position = UDim2.new(1, -142, 0, 3)
aU.BackgroundTransparency = 1
aU.BorderSizePixel = 0
aU.Visible = false
aU.BackgroundColor3 = Color3.new()
aU.Image = u("badscript/assets/new/textvape.png")
aU.Parent = aw.Children

local aV = aw.Children.AbsolutePosition.X > (B.AbsoluteSize.X / 2)
d:Clean(connectDeferredPropertyChanged(aw.Children, "AbsolutePosition", function()
    if d.ThreadFix then
        setthreadidentity(8)
    end
    local aW = aw.Children.AbsolutePosition.X > (B.AbsoluteSize.X / 2)
    if aV ~= aW then
        aV = aW
        d:UpdateTextGUI()
    end
end))

local aW = Instance.new("ImageLabel")
aW.Name = "Logo2"
aW.Size = UDim2.fromOffset(33, 18)
aW.Position = UDim2.new(1, 1, 0, 1)
aW.BackgroundColor3 = Color3.new()
aW.BackgroundTransparency = 1
aW.BorderSizePixel = 0
aW.Image = u("badscript/assets/new/textv4.png")
aW.Parent = aU
local aX = aU:Clone()
aX.Position = UDim2.fromOffset(1, 1)
aX.ZIndex = 0
aX.Visible = true
aX.ImageColor3 = Color3.new()
aX.ImageTransparency = 0.65
aX.Parent = aU
aX.Logo2.ZIndex = 0
aX.Logo2.ImageColor3 = Color3.new()
aX.Logo2.ImageTransparency = 0.65
local aY = Instance.new("UIGradient")
aY.Rotation = 90
aY.Parent = aU
local aZ = Instance.new("UIGradient")
aZ.Rotation = 90
aZ.Parent = aW
local a_ = Instance.new("TextLabel")
a_.Position = UDim2.fromOffset(5, 2)
a_.BackgroundTransparency = 1
a_.BorderSizePixel = 0
a_.Visible = false
a_.Text = ""
a_.TextSize = 25
a_.FontFace = aP.Value
a_.RichText = true
local a0 = a_:Clone()
a_:GetPropertyChangedSignal("Position"):Connect(function()
    a0.Position = UDim2.new(a_.Position.X.Scale, a_.Position.X.Offset + 1, 0, a_.Position.Y.Offset + 1)
end)
a_:GetPropertyChangedSignal("FontFace"):Connect(function()
    a0.FontFace = a_.FontFace
end)
a_:GetPropertyChangedSignal("Text"):Connect(function()
    a0.Text = removeTags(a_.Text)
end)
a_:GetPropertyChangedSignal("Size"):Connect(function()
    a0.Size = a_.Size
end)
a0.TextColor3 = Color3.new()
a0.TextTransparency = 0.65
a0.Parent = aw.Children
a_.Parent = aw.Children
local a1 = Instance.new("Frame")
a1.Name = "Holder"
a1.Size = UDim2.fromScale(1, 1)
a1.Position = UDim2.fromOffset(5, 37)
a1.BackgroundTransparency = 1
a1.Parent = aw.Children
local a2 = Instance.new("UIListLayout")
a2.HorizontalAlignment = Enum.HorizontalAlignment.Right
a2.VerticalAlignment = Enum.VerticalAlignment.Top
a2.SortOrder = Enum.SortOrder.LayoutOrder
a2.Parent = a1

do
local function createTargetInfo()
local a3
local a4
local a5
a4 = d:CreateOverlay({
    Name = "Target Info",
    Icon = u("badscript/assets/new/targetinfoicon.png"),
    Size = UDim2.fromOffset(14, 14),
    Position = UDim2.fromOffset(12, 14),
    CategorySize = 240,
    Function = function(a6)
        if a6 then
            task.spawn(function()
                repeat
                    a3:UpdateInfo()
                    task.wait()
                until not a4.Button or not a4.Button.Enabled
            end)
        end
    end,
})

local a6 = Instance.new("Frame")
a6.Size = UDim2.fromOffset(240, 89)
a6.BackgroundColor3 = m.Dark(o.Main, 0.1)
a6.BackgroundTransparency = 0.5
a6.Parent = a4.Children
local a7 = addBlur(a6)
a7.Visible = false
addCorner(a6)
local a8 = Instance.new("ImageLabel")
a8.Size = UDim2.fromOffset(26, 27)
a8.Position = UDim2.fromOffset(19, 17)
a8.BackgroundColor3 = o.Main
a8.Image = "rbxthumb://type=AvatarHeadShot&id=1&w=420&h=420"
a8.Parent = a6
local a9 = Instance.new("Frame")
a9.Size = UDim2.fromScale(1, 1)
a9.BackgroundTransparency = 1
a9.BackgroundColor3 = Color3.new(1, 0, 0)
a9.Parent = a8
addCorner(a9)
local ba = addBlur(a8)
ba.Visible = false
addCorner(a8)
local bb = Instance.new("TextLabel")
bb.Size = UDim2.fromOffset(145, 20)
bb.Position = UDim2.fromOffset(54, 20)
bb.BackgroundTransparency = 1
bb.Text = "Target name"
bb.TextXAlignment = Enum.TextXAlignment.Left
bb.TextYAlignment = Enum.TextYAlignment.Top
bb.TextScaled = true
bb.TextColor3 = m.Light(o.Text, 0.4)
bb.TextStrokeTransparency = 1
bb.FontFace = o.Font
local bc = bb:Clone()
bc.Position = UDim2.fromOffset(55, 21)
bc.TextColor3 = Color3.new()
bc.TextTransparency = 0.65
bc.Visible = false
bc.Parent = a6
bb:GetPropertyChangedSignal("Size"):Connect(function()
    bc.Size = bb.Size
end)
bb:GetPropertyChangedSignal("Text"):Connect(function()
    bc.Text = bb.Text
end)
bb:GetPropertyChangedSignal("FontFace"):Connect(function()
    bc.FontFace = bb.FontFace
end)
bb.Parent = a6
local bd = Instance.new("Frame")
bd.Name = "HealthBKG"
bd.Size = UDim2.fromOffset(200, 9)
bd.Position = UDim2.fromOffset(20, 56)
bd.BackgroundColor3 = o.Main
bd.BorderSizePixel = 0
bd.Parent = a6
addCorner(bd, UDim.new(1, 0))
local be = bd:Clone()
be.Size = UDim2.fromScale(0.8, 1)
be.Position = UDim2.new()
be.BackgroundColor3 = Color3.fromHSV(0.4, 0.89, 0.75)
be.Parent = bd
be:GetPropertyChangedSignal("Size"):Connect(function()
    be.Visible = be.Size.X.Scale > 0.01
end)
local bf = be:Clone()
bf.Size = UDim2.new()
bf.Position = UDim2.fromScale(1, 0)
bf.AnchorPoint = Vector2.new(1, 0)
bf.BackgroundColor3 = Color3.fromRGB(255, 170, 0)
bf.Visible = false
bf.Parent = bd
bf:GetPropertyChangedSignal("Size"):Connect(function()
    bf.Visible = bf.Size.X.Scale > 0.01
end)
local bg = addBlur(bd)
bg.SliceCenter = Rect.new(52, 31, 261, 510)
bg.ImageColor3 = Color3.new()
bg.Visible = false
local bh = Instance.new("UIStroke")
bh.Enabled = false
bh.Color = Color3.fromHSV(0.44, 1, 1)
bh.Parent = a6

a4:CreateFont({
    Name = "Font",
    Blacklist = "Arial",
    Function = function(bi)
        bb.FontFace = bi
    end,
})
local bi = {
    Value = 0.5,
    Object = { Visible = {} },
}
local bj = a4:CreateToggle({
    Name = "Use Displayname",
    Default = true,
})
a4:CreateToggle({
    Name = "Render Background",
    Function = function(bk)
        a6.BackgroundTransparency = bk and bi.Value or 1
        bc.Visible = not bk
        a7.Visible = bk
        bg.Visible = not bk
        ba.Visible = not bk
        bi.Object.Visible = bk
    end,
    Default = true,
})
bi = a4:CreateSlider({
    Name = "Transparency",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Decimal = 10,
    Function = function(bk)
        a6.BackgroundTransparency = bk
    end,
    Darker = true,
})
local bk
local bl = a4:CreateToggle({
    Name = "Custom Color",
    Function = function(bl)
        bk.Object.Visible = bl
        if bl then
            a6.BackgroundColor3 = Color3.fromHSV(bk.Hue, bk.Sat, bk.Value)
            a8.BackgroundColor3 = Color3.fromHSV(bk.Hue, bk.Sat, math.max(bk.Value - 0.1, 0.075))
            bd.BackgroundColor3 = a8.BackgroundColor3
        else
            a6.BackgroundColor3 = m.Dark(o.Main, 0.1)
            a8.BackgroundColor3 = o.Main
            bd.BackgroundColor3 = o.Main
        end
    end,
})
bk = a4:CreateColorSlider({
    Name = "Color",
    Function = function(bm, bn, I)
        if bl.Enabled then
            a6.BackgroundColor3 = Color3.fromHSV(bm, bn, I)
            a8.BackgroundColor3 = Color3.fromHSV(bm, bn, math.max(I - 0.1, 0))
            bd.BackgroundColor3 = a8.BackgroundColor3
        end
    end,
    Darker = true,
    Visible = false,
})
d:setupguicolorsync(a4, {
    Color1 = bk,
    Default = true,
})
a4:CreateToggle({
    Name = "Border",
    Function = function(bm)
        bh.Enabled = bm
        a5.Object.Visible = bm
    end,
})
a5 = a4:CreateColorSlider({
    Name = "Border Color",
    Function = function(bm, bn, I, J)
        local opacity = tonumber(J) or 1
        bh.Color = Color3.fromHSV(bm, bn, I)
        bh.Transparency = 1 - opacity
    end,
    Darker = true,
    Visible = false,
})

local bm = 0
local bn = 0
a3 = {
    Targets = {},
    Object = a6,
    UpdateInfo = function(I)
        local J = d.Libraries
        if not J then
            return
        end

        for K, L in I.Targets do
            if L < tick() then
                I.Targets[K] = nil
            end
        end

        local K, L = (tick())
        for M, N in I.Targets do
            if N > K then
                L = M
                K = N
            end
        end

        a6.Visible = L ~= nil or v.Visible
        if L then
            bb.Text = L.Player and (bj.Enabled and L.Player.DisplayName or L.Player.Name)
                or L.Character and L.Character.Name
                or bb.Text
            a8.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (L.Player and L.Player.UserId or 1) .. "&w=420&h=420"

            if not L.Character then
                L.Health = L.Health or 0
                L.MaxHealth = L.MaxHealth or 100
            end

            if L.Health ~= bm or L.MaxHealth ~= bn then
                local M = math.max(L.Health / L.MaxHealth, 0)
                n:Tween(be, TweenInfo.new(0.3), {
                    Size = UDim2.fromScale(math.min(M, 1), 1),
                    BackgroundColor3 = Color3.fromHSV(math.clamp(M / 2.5, 0, 1), 0.89, 0.75),
                })
                n:Tween(bf, TweenInfo.new(0.3), {
                    Size = UDim2.fromScale(math.clamp(M - 1, 0, 0.8), 1),
                })
                if bm > L.Health and I.LastTarget == L then
                    n:Cancel(a9)
                    a9.BackgroundTransparency = 0.3
                    n:Tween(a9, TweenInfo.new(0.5), {
                        BackgroundTransparency = 1,
                    })
                end
                bm = L.Health
                bn = L.MaxHealth
            end

            if not L.Character then
                table.clear(L)
            end
            I.LastTarget = L
        end
        return L
    end,
}
d.Libraries.targetinfo = a3
end
createTargetInfo()
end

function d.UpdateTextGUI(I, J)
    if not J and not d.Loaded then
        return
    end
    if aw.Button.Enabled then
        local K = aw.Children.AbsolutePosition.X > (B.AbsoluteSize.X / 2)
        aU.Visible = aH.Enabled
        aU.Position = K and UDim2.new(1 / aB.Scale, -113, 0, 6) or UDim2.fromOffset(0, 6)
        aX.Visible = aC.Enabled
        a_.Text = aO.Value
        a_.FontFace = aP.Value
        a_.Visible = a_.Text ~= "" and aS.Enabled
        a0.Visible = a_.Visible and aC.Enabled
        a2.HorizontalAlignment = K and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
        a1.Size = UDim2.fromScale(1 / aB.Scale, 1)
        a1.Position = UDim2.fromOffset(
            K and 3 or 0,
            11 + (aU.Visible and aU.Size.Y.Offset or 0) + (a_.Visible and 28 or 0) + (aK.Enabled and 3 or 0)
        )
        if a_.Visible then
            local L = E(removeTags(a_.Text), a_.TextSize, a_.FontFace)
            a_.Size = UDim2.fromOffset(L.X, L.Y)
            a_.Position = UDim2.new(K and 1 / aB.Scale or 0, K and -L.X or 0, 0, (aU.Visible and 32 or 8))
        end

        local L = {}
        for M, N in aT do
            if N.Enabled then
                table.insert(L, N.Object.Name)
            end
            N.Object:Destroy()
        end
        table.clear(aT)

        local M = TweenInfo.new(0.3, Enum.EasingStyle.Exponential)
        for N, O in d.Modules do
            if aM.Enabled and table.find(aL.ListEnabled, N) then
                continue
            end
            if aN.Enabled and O.Category == "Render" then
                continue
            end
            if O.Enabled or table.find(L, N) then
                local P = Instance.new("Frame")
                P.Name = N
                P.Size = UDim2.fromOffset()
                P.BackgroundTransparency = 1
                P.ClipsDescendants = true
                P.Parent = a1
                local Q
                local R
                if aK.Enabled then
                    Q = Instance.new("Frame")
                    Q.Size = UDim2.new(1, 3, 1, 0)
                    Q.BackgroundColor3 = m.Dark(o.Main, 0.15)
                    Q.BackgroundTransparency = aI.Value
                    Q.BorderSizePixel = 0
                    Q.Parent = P
                    local S = Instance.new("Frame")
                    S.Size = UDim2.new(1, 0, 0, 1)
                    S.Position = UDim2.new(0, 0, 1, -1)
                    S.BackgroundColor3 = Color3.new()
                    S.BackgroundTransparency = 0.928 + (0.072 * math.clamp((aI.Value - 0.5) / 0.5, 0, 1))
                    S.BorderSizePixel = 0
                    S.Parent = Q
                    local T = S:Clone()
                    T.Name = "Line"
                    T.Position = UDim2.new()
                    T.Parent = Q
                    R = Instance.new("Frame")
                    R.Size = UDim2.new(0, 2, 1, 0)
                    R.Position = K and UDim2.new(1, -5, 0, 0) or UDim2.new()
                    R.BorderSizePixel = 0
                    R.Parent = Q
                end
                local S = Instance.new("TextLabel")
                S.Position = UDim2.fromOffset(K and 3 or 6, 2)
                S.BackgroundTransparency = 1
                S.BorderSizePixel = 0
                S.Text = N .. (O.ExtraText and " <font color='#A8A8A8'>" .. O.ExtraText() .. "</font>" or "")
                S.TextSize = 15
                S.FontFace = ay.Value
                S.RichText = true
                local T = E(removeTags(S.Text), S.TextSize, S.FontFace)
                S.Size = UDim2.fromOffset(T.X, T.Y)
                if aC.Enabled then
                    local U = S:Clone()
                    U.Position = UDim2.fromOffset(S.Position.X.Offset + 1, S.Position.Y.Offset + 1)
                    U.Text = removeTags(S.Text)
                    U.TextColor3 = Color3.new()
                    U.Parent = P
                end
                S.Parent = P
                local U = UDim2.fromOffset(T.X + 10, T.Y + (aK.Enabled and 5 or 3))
                if aF.Enabled then
                    if not table.find(L, N) then
                        n:Tween(P, M, {
                            Size = U,
                        })
                    else
                        P.Size = U
                        if not O.Enabled then
                            n:Tween(P, M, {
                                Size = UDim2.fromOffset(),
                            })
                        end
                    end
                else
                    P.Size = O.Enabled and U or UDim2.fromOffset()
                end
                table.insert(aT, {
                    Object = P,
                    Text = S,
                    Background = Q,
                    Color = R,
                    Enabled = O.Enabled,
                })
            end
        end

        if ax.Value == "Alphabetical" then
            table.sort(aT, function(N, O)
                return N.Text.Text < O.Text.Text
            end)
        else
            table.sort(aT, function(N, O)
                return N.Text.Size.X.Offset > O.Text.Size.X.Offset
            end)
        end

        for N, O in aT do
            if O.Color then
                O.Color.Parent.Line.Visible = N ~= 1
            end
            O.Object.LayoutOrder = N
        end
    end

    d:UpdateGUI(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value, true)
end

function d.UpdateGUI(I, J, K, L, M)
    if d.Loaded == nil then
        return
    end
    d.GUIColorChanged:Fire(J, K, L, M)
    if not M and d.GUIColor.Rainbow then
        return
    end
    if aw.Button.Enabled then
        aY.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(J, K, L)),
            ColorSequenceKeypoint.new(
                1,
                aE.Enabled and Color3.fromHSV(d:Color((J - 0.075) % 1)) or Color3.fromHSV(J, K, L)
            ),
        })
        aZ.Color = aE.Enabled and aD.Enabled and aY.Color
            or ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
            })
        a_.TextColor3 = aQ.Enabled and Color3.fromHSV(aR.Hue, aR.Sat, aR.Value) or aY.Color.Keypoints[2].Value

        local N = aA.Value == "Custom color" and Color3.fromHSV(az.Hue, az.Sat, az.Value) or nil
        for O, P in aT do
            P.Text.TextColor3 = N
                or (
                    d.GUIColor.Rainbow and Color3.fromHSV(d:Color((J - ((aE and O + 2 or O) * 0.025)) % 1))
                    or aY.Color.Keypoints[2].Value
                )
            if P.Color then
                P.Color.BackgroundColor3 = P.Text.TextColor3
            end
            if aJ.Enabled and P.Background then
                P.Background.BackgroundColor3 = m.Dark(P.Text.TextColor3, 0.75)
            end
        end
    end

    local legitWindow = d.Legit and d.Legit.Window
    if not v.Visible and not (legitWindow and legitWindow.Visible) then
        return
    end
    local N = d.GUIColor.Rainbow and d.RainbowMode.Value ~= "Retro"

    for O, P in d.Categories do
        if O == "Main" then
            local mainObject = P.Object
            local brand = mainObject and mainObject:FindFirstChild("BrandLogo")
            local accent = Color3.fromHSV(J, K, L)

            if brand and brand:IsA("TextLabel") then
                brand.TextColor3 = o.TextStrong
            end
            for Q, R in P.Buttons do
                if R.Enabled then
                    R.Object.TextColor3 = N and Color3.fromHSV(d:Color((J - (R.Index * 0.025)) % 1))
                        or Color3.fromHSV(J, K, L)
                    if R.Icon then
                        R.Icon.ImageColor3 = R.Object.TextColor3
                    end
                end
            end
        end

        if P.Options then
            for Q, R in P.Options do
                if R.Color then
                    R:Color(J, K, L, N)
                end
            end
        end

        if P.Type == "CategoryList" then
            P.Object.Children.Add.AddButton.ImageColor3 = N and Color3.fromHSV(d:Color(J % 1))
                or Color3.fromHSV(J, K, L)
            if P.Selected then
                P.Selected.BackgroundColor3 = N and Color3.fromHSV(d:Color(J % 1)) or Color3.fromHSV(J, K, L)
                P.Selected.Title.TextColor3 = d.GUIColor.Rainbow and Color3.new(0.19, 0.19, 0.19)
                    or d:TextColor(J, K, L)
                P.Selected.Dots.Dots.ImageColor3 = P.Selected.Title.TextColor3
                P.Selected.Bind.Icon.ImageColor3 = P.Selected.Title.TextColor3
                P.Selected.Bind.TextLabel.TextColor3 = P.Selected.Title.TextColor3
            end
        end
    end

    for O, P in d.Modules do
        local object = P and P.Object
        if typeof(object) == "Instance" and object.Parent then
            local rail = object:FindFirstChild("ActiveRail")
            local moduleStroke = object:FindFirstChild("ModuleStroke")

            if not rail then
                rail = Instance.new("Frame")
                rail.Name = "ActiveRail"
                rail.Size = UDim2.new(0, 2, 1, -14)
                rail.Position = UDim2.fromOffset(0, 7)
                rail.BorderSizePixel = 0
                rail.ZIndex = object.ZIndex + 1
                rail.Parent = object
                addCorner(rail, UDim.new(1, 0))
            end

            local gradient = object:FindFirstChildOfClass("UIGradient")
            if gradient then
                gradient.Enabled = false
            end

            local accent = N and Color3.fromHSV(d:Color((J - (P.Index * 0.025)) % 1)) or Color3.fromHSV(J, K, L)

            if P.Enabled then
                rail.BackgroundColor3 = accent
                rail.Visible = true

                object.BackgroundColor3 = o.Elevated
                object.TextColor3 = o.TextStrong

                local bind = object:FindFirstChild("Bind")
                if bind then
                    local bindIcon = bind:FindFirstChild("Icon")
                    local bindText = bind:FindFirstChildOfClass("TextLabel")
                    if bindIcon and bindIcon:IsA("ImageLabel") then
                        bindIcon.ImageColor3 = o.Text
                    end
                    if bindText then
                        bindText.TextColor3 = o.Text
                    end
                end

                local dots = object:FindFirstChild("Dots")
                local dotsIcon = dots and dots:FindFirstChild("Dots")
                if dotsIcon and dotsIcon:IsA("ImageLabel") then
                    dotsIcon.ImageColor3 = o.Text
                end

                if moduleStroke and moduleStroke:IsA("UIStroke") then
                    moduleStroke.Color = o.BorderStrong
                    moduleStroke.Transparency = 0.58
                end
            else
                rail.Visible = false
                object.BackgroundColor3 = o.Surface
                object.TextColor3 = o.MutedText

                if moduleStroke and moduleStroke:IsA("UIStroke") then
                    moduleStroke.Color = o.Border
                    moduleStroke.Transparency = 0.88
                end
            end
        end

        if P and type(P.Options) == "table" then
            for Q, R in P.Options do
                if R and R.Color then
                    pcall(R.Color, R, J, K, L, N)
                end
            end
        end
    end
    if d.Legit.Icon then
        d.Legit.Icon.ImageColor3 = Color3.fromHSV(J, K, L)
    end

    if d.Legit and d.Legit.Window and d.Legit.Window.Visible and type(d.Legit.Modules) == "table" then
        for O, P in d.Legit.Modules do
            if P.Enabled then
                local accent = Color3.fromHSV(J, K, L)
                local cardAccent = P.Object and P.Object:FindFirstChild("ActiveRail", true)
                if cardAccent and cardAccent:IsA("GuiObject") then
                    cardAccent.BackgroundColor3 = accent
                end

                local track = P.Object and P.Object:FindFirstChild("Track", true)
                if track and track:IsA("GuiObject") then
                    track.BackgroundColor3 = accent
                end
            end

            for Q, R in P.Options do
                if R.Color then
                    R:Color(J, K, L, N)
                end
            end
        end
    end
end

d:Clean(q.ChildRemoved:Connect(function()
    local notifications = {}
    for _, child in q:GetChildren() do
        if child:IsA("GuiObject") then
            notifications[#notifications + 1] = child
        end
    end
    table.sort(notifications, function(left, right)
        return (left.LayoutOrder or 0) < (right.LayoutOrder or 0)
    end)
    local offset = d.isMobile and 36 or 29
    for _, notification in notifications do
        offset += (notification:GetAttribute("NotifHeight") or notification.AbsoluteSize.Y) + 6
        if n.Tween then
            n:Tween(notification, TweenInfo.new(0.32, Enum.EasingStyle.Exponential), {
                Position = UDim2.new(1, 0, 1, -offset),
            })
        end
    end
end))

-- BADWARS_HELD_KEY_SCOPE_V2_BEGIN
function d.SetupHeldKeyTracking()
    local function addHeldKey(keyName)
        if keyName and keyName ~= "Unknown" and not table.find(d.HeldKeybinds, keyName) then
            table.insert(d.HeldKeybinds, keyName)
        end
    end

    local function removeHeldKey(keyName)
        local index = table.find(d.HeldKeybinds, keyName)
        if index then
            table.remove(d.HeldKeybinds, index)
        end
    end

    local function clearHeldKeys()
        table.clear(d.HeldKeybinds)
    end

    d:Clean(h.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or h:GetFocusedTextBox() or input.KeyCode == Enum.KeyCode.Unknown then
            return
        end
        local keyName = input.KeyCode.Name
        if table.find(d.HeldKeybinds, keyName) then
            return
        end
        addHeldKey(keyName)

        if input.KeyCode == Enum.KeyCode.Escape then
            if d._OpenDropdown then
                pcall(d._OpenDropdown)
                d._OpenDropdown = nil
                return
            end
            if d.Binding then
                d.Binding = nil
                clearHeldKeys()
                return
            end
            if z then
                z.Visible = false
            end
        end

        if d.Binding then
            return
        end

        if checkKeybinds(d.HeldKeybinds, d.Keybind, keyName) then
            if d.ThreadFix then
                pcall(setthreadidentity, 8)
            end
            for _, window in d.Windows do
                window.Visible = false
            end
            d:SetClickGuiVisible(not v.Visible)
            z.Visible = false
            d:BlurCheck()
            return
        end

        local toggled = false
        for moduleName, module in d.Modules do
            if checkKeybinds(d.HeldKeybinds, module.Bind, keyName) then
                toggled = true
                if d.ToggleNotifications.Enabled then
                    d:CreateNotification(
                        "Module Toggled",
                        moduleName
                            .. "<font color='#FFFFFF'> has been </font>"
                            .. (not module.Enabled and "<font color='#5AFF5A'>Enabled</font>" or "<font color='#FF5A5A'>Disabled</font>")
                            .. "<font color='#FFFFFF'>!</font>",
                        0.75
                    )
                end
                module:Toggle(true)
            end
        end
        if toggled then
            d:UpdateTextGUI()
        end

        if d.ProfilesEnabled then
            for _, profile in d.Profiles do
                if checkKeybinds(d.HeldKeybinds, profile.Bind, keyName) and profile.Name ~= d.Profile then
                    d:Save(profile.Name)
                    d:Load(true)
                    break
                end
            end
        end
    end))

    d:Clean(h.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Unknown then
            return
        end
        local keyName = input.KeyCode.Name
        if d.Binding and not h:GetFocusedTextBox() then
            local captured
            if d.MultiKeybind.Enabled then
                captured = table.clone(d.HeldKeybinds)
            else
                captured = { keyName }
            end
            d.Binding:SetBind(captured, true)
            d.Binding = nil
        end
        removeHeldKey(keyName)
    end))

    pcall(function()
        d:Clean(h.WindowFocusReleased:Connect(clearHeldKeys))
    end)
end

d.SetupHeldKeyTracking()
d.SetupHeldKeyTracking = nil
-- BADWARS_HELD_KEY_SCOPE_V2_END

if d.Blur then
    d.Blur.Default = false
end


-- BADWARS_FINAL_DESIGN_SCOPE_V15_BEGIN
task.defer(function()
    local quietStrokeNames = {
        MainStroke = 0.7,
        NavigationStroke = 0.88,
        CategoryStroke = 0.78,
        ModuleStroke = 0.9,
        ModuleCategoryStroke = 0.88,
        LegitStroke = 0.72,
        LegitCardStroke = 0.82,
        LegitWidgetStroke = 0.74,
        OptionsStroke = 0.94,
        TextBoxStroke = 0.86,
        OverlayStroke = 0.74,
        NotificationStroke = 0.68,
        TooltipStroke = 0.58,
    }

    local function addCleanMotion(instance)
        if instance:GetAttribute("BadWarsV15Motion") then
            return
        end

        instance:SetAttribute("BadWarsV15Motion", true)

        local scale = instance:FindFirstChild("V15Scale")
        if not scale then
            scale = Instance.new("UIScale")
            scale.Name = "V15Scale"
            scale.Scale = 1
            scale.Parent = instance
        end

        local baseTransparency = instance.BackgroundTransparency

        instance.MouseEnter:Connect(function()
            if not instance.Parent then
                return
            end

            pcall(function()
                n:Tween(scale, o.TweenFast, { Scale = 1.004 })
                if instance.BackgroundTransparency < 1 then
                    n:Tween(
                        instance,
                        o.TweenFast,
                        { BackgroundTransparency = math.max(baseTransparency - 0.012, 0) }
                    )
                end
            end)
        end)

        instance.MouseLeave:Connect(function()
            if not instance.Parent then
                return
            end

            pcall(function()
                n:Spring(scale, o.SpringInteractive, { Scale = 1 })
                if instance.BackgroundTransparency < 1 then
                    n:Tween(instance, o.TweenFast, { BackgroundTransparency = baseTransparency })
                end
            end)
        end)
    end

    local function applyFrameDesign(instance)
        if instance.Name == "V9Sweep" or instance.Name == "SignalNodes" then
            instance:Destroy()
            return
        end

        if instance:IsA("UIStroke") then
            local minimum = quietStrokeNames[instance.Name]
            if minimum then
                instance.Thickness = 1
                instance.LineJoinMode = Enum.LineJoinMode.Round
                instance.Transparency = math.max(instance.Transparency, minimum)
            end
            return
        end

        if instance:IsA("UICorner") then
            local parent = instance.Parent
            if parent and parent:IsA("GuiObject") then
                local height = parent.AbsoluteSize.Y
                if height > 0 and height <= 46 then
                    instance.CornerRadius = o.RadiusSmall
                elseif height > 46 and height <= 120 then
                    instance.CornerRadius = o.Radius
                else
                    instance.CornerRadius = o.RadiusLarge
                end
            end
            return
        end

        if instance:IsA("UIGradient") and instance.Name == "SurfaceGradient" then
            instance.Rotation = 90
        end

        if
            instance:IsA("TextButton")
            or instance:IsA("ImageButton")
        then
            addCleanMotion(instance)
        end
    end

    for _, descendant in ipairs(B:GetDescendants()) do
        applyFrameDesign(descendant)
    end

    d:Clean(B.DescendantAdded:Connect(function(descendant)
        task.defer(applyFrameDesign, descendant)
    end))
end)
-- BADWARS_FINAL_DESIGN_SCOPE_V15_END

-- BADWARS_LOCAL_REGISTER_SCOPE_FIX_V1
return (function(...)
-- BADWARS_FUSION_DESIGN_RUNTIME_V21_BEGIN
-- Fusion-inspired local runtime. It mirrors Fusion's declarative/reactive shape
-- without adding a network/package dependency to this single-file executor GUI.
do
    d.Version = "21.0"
    d.PremiumBuild = "2026.07.06-V21-FUSION-DESIGN-RUNTIME"

    local Fusion = {}
    local cleanupBucket = {}
    local SPECIAL_CHILDREN = {}
    local SPECIAL_ON_EVENT = {}
    local SPECIAL_ON_CHANGE = {}
    local SPECIAL_OUT = {}

    Fusion.Children = SPECIAL_CHILDREN
    Fusion.OnEvent = function(eventName)
        return { SPECIAL_ON_EVENT, tostring(eventName or "") }
    end
    Fusion.OnChange = function(propertyName)
        return { SPECIAL_ON_CHANGE, tostring(propertyName or "") }
    end
    Fusion.Out = function(propertyName)
        return { SPECIAL_OUT, tostring(propertyName or "") }
    end

    local function addRuntimeCleanup(taskObject)
        cleanupBucket[#cleanupBucket + 1] = taskObject
        if d.Clean then
            pcall(function()
                d:Clean(taskObject)
            end)
        end
        return taskObject
    end

    local function isState(value)
        return type(value) == "table" and value.__BadWarsFusionState == true
    end

    local function readState(value)
        if isState(value) then
            return value:get()
        end
        if type(value) == "function" then
            local ok, result = pcall(value)
            if ok then
                return result
            end
            bwarn("[Fusion runtime]: computed read failed", result)
            return nil
        end
        return value
    end

    function Fusion.Value(initialValue)
        local state = {
            __BadWarsFusionState = true,
            _value = initialValue,
            _connections = {},
        }

        function state.get(self)
            return self._value
        end

        function state.set(self, nextValue)
            if self._value == nextValue then
                return nextValue
            end
            self._value = nextValue
            for callback in pairs(self._connections) do
                task.defer(callback, nextValue)
            end
            return nextValue
        end

        function state.onChange(self, callback)
            if type(callback) ~= "function" then
                return nil
            end
            self._connections[callback] = true
            callback(self._value)
            return {
                Disconnect = function()
                    self._connections[callback] = nil
                end,
            }
        end

        return state
    end

    function Fusion.Computed(dependencies, processor)
        dependencies = type(dependencies) == "table" and dependencies or {}
        processor = type(processor) == "function" and processor or function()
            return nil
        end

        local computed = Fusion.Value(nil)
        local function refresh()
            local values = {}
            for index, dependency in ipairs(dependencies) do
                values[index] = readState(dependency)
            end
            local ok, result = pcall(processor, unpack(values))
            if ok then
                computed:set(result)
            else
                bwarn("[Fusion runtime]: computed update failed", result)
            end
        end

        for _, dependency in ipairs(dependencies) do
            if isState(dependency) then
                addRuntimeCleanup(dependency:onChange(refresh))
            end
        end
        refresh()
        return computed
    end

    local function bindProperty(instance, property, value)
        if isState(value) then
            local function assign(nextValue)
                pcall(function()
                    instance[property] = nextValue
                end)
            end
            assign(value:get())
            addRuntimeCleanup(value:onChange(assign))
            return
        end

        pcall(function()
            instance[property] = readState(value)
        end)
    end

    local function parentChild(parent, child)
        if child == nil then
            return
        end
        if typeof(child) == "Instance" then
            child.Parent = parent
            return
        end
        if type(child) == "table" then
            for _, nested in pairs(child) do
                parentChild(parent, nested)
            end
        end
    end

    local function applySpecial(instance, key, value)
        if key == SPECIAL_CHILDREN then
            parentChild(instance, value)
            return true
        end

        if type(key) == "table" and key[1] == SPECIAL_ON_EVENT then
            local eventName = key[2]
            local event = instance[eventName]
            if event and type(value) == "function" then
                addRuntimeCleanup(event:Connect(value))
            end
            return true
        end

        if type(key) == "table" and key[1] == SPECIAL_ON_CHANGE then
            local propertyName = key[2]
            if propertyName ~= "" and type(value) == "function" then
                addRuntimeCleanup(instance:GetPropertyChangedSignal(propertyName):Connect(function()
                    value(instance[propertyName])
                end))
            end
            return true
        end

        if type(key) == "table" and key[1] == SPECIAL_OUT then
            local propertyName = key[2]
            if isState(value) and propertyName ~= "" then
                value:set(instance[propertyName])
                addRuntimeCleanup(instance:GetPropertyChangedSignal(propertyName):Connect(function()
                    value:set(instance[propertyName])
                end))
            end
            return true
        end

        return false
    end

    function Fusion.New(className)
        return function(properties)
            properties = type(properties) == "table" and properties or {}
            local instance = Instance.new(className)

            for key, value in pairs(properties) do
                if not applySpecial(instance, key, value) then
                    bindProperty(instance, key, value)
                end
            end

            return instance
        end
    end

    function Fusion.Hydrate(instance)
        return function(properties)
            if typeof(instance) ~= "Instance" then
                return instance
            end
            properties = type(properties) == "table" and properties or {}
            for key, value in pairs(properties) do
                if not applySpecial(instance, key, value) then
                    bindProperty(instance, key, value)
                end
            end
            return instance
        end
    end

    function Fusion.Spring(state, profile)
        profile = type(profile) == "table" and profile or o.SpringSoft
        local output = Fusion.Value(readState(state))
        if not isState(state) then
            return output
        end
        addRuntimeCleanup(state:onChange(function(value)
            output:set(value)
        end))
        output.Profile = profile
        return output
    end

    function Fusion.cleanup()
        for _, taskObject in ipairs(cleanupBucket) do
            pcall(function()
                if type(taskObject) == "function" then
                    taskObject()
                elseif type(taskObject) == "table" and type(taskObject.Disconnect) == "function" then
                    taskObject:Disconnect()
                elseif typeof(taskObject) == "Instance" then
                    taskObject:Destroy()
                end
            end)
        end
        table.clear(cleanupBucket)
    end

    d.Fusion = Fusion
    d.Libraries.Fusion = Fusion
    d.Libraries.fusion = Fusion
end

do
    local Fusion = d.Fusion
    local function addRuntimeCleanup(taskObject)
        if d.Clean then
            pcall(function()
                d:Clean(taskObject)
            end)
        end
        return taskObject
    end

    local function accentColor(alpha)
        local color = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        if alpha then
            return color:Lerp(o.TextStrong, alpha)
        end
        return color
    end

    local function ensureCorner(instance, radius)
        local corner = instance:FindFirstChildOfClass("UICorner")
        if not corner then
            corner = Instance.new("UICorner")
            corner.Parent = instance
        end
        corner.CornerRadius = radius or o.Radius
        return corner
    end

    local function ensureStroke(instance, color, transparency, thickness, name)
        local stroke = name and instance:FindFirstChild(name) or instance:FindFirstChildOfClass("UIStroke")
        if not stroke then
            stroke = Instance.new("UIStroke")
            stroke.Name = name or "FusionStroke"
            stroke.Parent = instance
        end
        stroke.Color = color or o.Border
        stroke.Transparency = transparency or 0.75
        stroke.Thickness = thickness or 1
        stroke.LineJoinMode = Enum.LineJoinMode.Round
        return stroke
    end

    local function attachScaleMotion(instance, amount)
        if typeof(instance) ~= "Instance" or not instance:IsA("GuiObject") then
            return nil
        end
        if instance:GetAttribute("BadWarsFusionMotion") then
            return instance:FindFirstChild("FusionScale")
        end

        instance:SetAttribute("BadWarsFusionMotion", true)
        local scale = instance:FindFirstChild("FusionScale") or Instance.new("UIScale")
        scale.Name = "FusionScale"
        scale.Scale = 1
        scale.Parent = instance
        amount = amount or 1.006

        local baseTransparency = instance.BackgroundTransparency
        addRuntimeCleanup(instance.MouseEnter:Connect(function()
            if not instance.Parent then
                return
            end
            n:Tween(scale, o.TweenFast, { Scale = amount })
            if instance.BackgroundTransparency < 1 then
                n:Tween(instance, o.TweenFast, {
                    BackgroundTransparency = math.clamp(baseTransparency - 0.018, 0, 1),
                })
            end
        end))

        addRuntimeCleanup(instance.MouseLeave:Connect(function()
            if not instance.Parent then
                return
            end
            n:Tween(scale, o.TweenFast, { Scale = 1 })
            if instance.BackgroundTransparency < 1 then
                n:Tween(instance, o.TweenFast, { BackgroundTransparency = baseTransparency })
            end
        end))

        return scale
    end

    local function stabilizeTextLabel(label)
        if not label:IsA("TextLabel") and not label:IsA("TextButton") and not label:IsA("TextBox") then
            return
        end
        if label:GetAttribute("BadWarsFusionTextStable") then
            return
        end
        label:SetAttribute("BadWarsFusionTextStable", true)
        label.TextWrapped = label.AbsoluteSize.X > 180 and label.TextWrapped or false
        label.TextTruncate = Enum.TextTruncate.AtEnd
        label.ClipsDescendants = true
        if label.TextXAlignment == Enum.TextXAlignment.Center and label.AbsoluteSize.X > 120 then
            local parentName = label.Parent and label.Parent.Name or ""
            if parentName:find("Button") or parentName:find("Module") or parentName:find("Card") then
                label.TextXAlignment = Enum.TextXAlignment.Left
            end
        end
    end

    local function stretchGuiObject(instance)
        if typeof(instance) ~= "Instance" or not instance:IsA("GuiObject") then
            return
        end
        local parent = instance.Parent
        if not parent or not parent:IsA("GuiObject") then
            return
        end
        local name = instance.Name
        if name == "Title" or name == "Text" or name == "Label" or name == "Value" or name == "DisplayName" then
            if instance.Size.X.Scale == 0 and instance.AbsoluteSize.X > 0 then
                local left = instance.Position.X.Offset
                local right = math.max(12, parent.AbsoluteSize.X - left - instance.AbsoluteSize.X)
                if parent.AbsoluteSize.X > 80 and right > 0 then
                    instance.Size = UDim2.new(1, -(left + right), instance.Size.Y.Scale, instance.Size.Y.Offset)
                end
            end
        end
    end

    local function normalizeButton(instance)
        if not (instance:IsA("TextButton") or instance:IsA("ImageButton")) then
            return
        end
        instance.AutoButtonColor = false
        instance.ClipsDescendants = true
        ensureCorner(instance, instance.AbsoluteSize.Y <= 36 and o.RadiusSmall or o.Radius)
        attachScaleMotion(instance, 1.004)
    end

    local metricNames = {
        Clock = true,
        FPS = true,
        Memory = true,
        Ping = true,
        Speedmeter = true,
    }

    local function normalizeMetricWidget(widget)
        if not widget:IsA("GuiObject") then
            return
        end
        local title = widget:FindFirstChild("WidgetTitle")
        local inferredName = title and title:IsA("TextLabel") and title.Text or widget.Name
        inferredName = tostring(inferredName):gsub("%s+", "")
        if not metricNames[inferredName] and not metricNames[widget.Name] then
            return
        end
        if widget:GetAttribute("BadWarsFusionMetricFixed") then
            return
        end
        widget:SetAttribute("BadWarsFusionMetricFixed", true)
        widget.ClipsDescendants = false
        widget.BackgroundTransparency = math.min(widget.BackgroundTransparency, 0.04)
        widget.BackgroundColor3 = o.MainSoft
        ensureCorner(widget, o.Radius)
        local stroke = ensureStroke(widget, o.BorderStrong, 0.58, 1, "FusionMetricStroke")

        for _, child in ipairs(widget:GetChildren()) do
            if child:IsA("TextLabel") and not child:GetAttribute("PremiumWidgetInternal") then
                child.Visible = true
                child.BackgroundTransparency = 1
                child.TextTransparency = 0
                child.TextColor3 = o.TextStrong
                child.TextStrokeTransparency = 1
                child.Position = UDim2.fromOffset(10, 12)
                child.Size = UDim2.new(1, -20, 1, -14)
                child.TextXAlignment = Enum.TextXAlignment.Left
                child.TextYAlignment = Enum.TextYAlignment.Center
                child.TextWrapped = false
                child.TextTruncate = Enum.TextTruncate.AtEnd
                child.FontFace = o.FontSemiBold
                child.ZIndex = widget.ZIndex + 8
            end
        end

        addRuntimeCleanup(widget.MouseEnter:Connect(function()
            widget.Visible = true
            n:Tween(widget, o.TweenFast, {
                BackgroundTransparency = 0,
                BackgroundColor3 = o.Elevated,
            })
            n:Tween(stroke, o.TweenFast, {
                Color = accentColor(0.1),
                Transparency = 0.34,
            })
            for _, child in ipairs(widget:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Visible = true
                    child.TextTransparency = 0
                end
            end
        end))

        addRuntimeCleanup(widget.MouseLeave:Connect(function()
            n:Tween(widget, o.TweenFast, {
                BackgroundTransparency = 0.03,
                BackgroundColor3 = o.MainSoft,
            })
            n:Tween(stroke, o.TweenFast, {
                Color = o.BorderStrong,
                Transparency = 0.58,
            })
        end))
    end

    local function createFusionNotification(api, titleText, bodyText, lifetime, kind)
        if not q or not q.Parent then
            return nil
        end

        api._FusionNotificationDismissers = api._FusionNotificationDismissers or setmetatable({}, { __mode = "k" })
        local accent = kind == "alert" and o.Danger
            or kind == "warning" and o.Warning
            or kind == "success" and o.Success
            or accentColor()
        local iconName = kind == "alert" and "alert"
            or kind == "warning" and "warning"
            or kind == "success" and "notification"
            or "info"
        local width = d.isMobile and 304 or 348
        local textWidth = width - 72
        local bounds = E(removeTags(bodyText), d.isMobile and 12 or 11, o.Font, textWidth) or Vector2.zero
        local height = math.clamp(58 + bounds.Y, 68, d.isMobile and 112 or 104)
        local transparency = Fusion.Value(1)
        local progressSize = Fusion.Value(UDim2.fromScale(1, 1))
        local scaleState = Fusion.Value(0.984)

        local cardScale = Fusion.New("UIScale")({
            Name = "FusionNotificationScale",
            Scale = scaleState,
        })

        local card = Fusion.New("CanvasGroup")({
            Name = "Notification",
            Size = UDim2.fromOffset(width, height),
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, width + 18, 1, -(height + 14)),
            LayoutOrder = math.floor(os.clock() * 100000),
            BackgroundColor3 = o.MainSoft,
            BackgroundTransparency = 0,
            GroupTransparency = transparency,
            BorderSizePixel = 0,
            Active = true,
            ClipsDescendants = true,
            ZIndex = 130,
            [Fusion.Children] = {
                cardScale,
                Fusion.New("UICorner")({
                    CornerRadius = o.Radius,
                }),
                Fusion.New("UIStroke")({
                    Name = "NotificationStroke",
                    Color = o.BorderStrong,
                    Transparency = 0.62,
                    Thickness = 1,
                    LineJoinMode = Enum.LineJoinMode.Round,
                }),
                Fusion.New("Frame")({
                    Name = "Accent",
                    Size = UDim2.new(0, 3, 1, -18),
                    Position = UDim2.fromOffset(10, 9),
                    BackgroundColor3 = accent,
                    BorderSizePixel = 0,
                    ZIndex = 132,
                    [Fusion.Children] = {
                        Fusion.New("UICorner")({
                            CornerRadius = UDim.new(1, 0),
                        }),
                    },
                }),
                Fusion.New("ImageLabel")({
                    Name = "Icon",
                    Size = UDim2.fromOffset(16, 16),
                    Position = UDim2.fromOffset(22, 17),
                    BackgroundTransparency = 1,
                    Image = u("badscript/assets/new/" .. iconName .. ".png"),
                    ImageColor3 = accent,
                    ImageTransparency = 0,
                    ZIndex = 133,
                }),
                Fusion.New("TextLabel")({
                    Name = "Title",
                    Size = UDim2.new(1, -84, 0, 18),
                    Position = UDim2.fromOffset(48, 11),
                    BackgroundTransparency = 1,
                    Text = titleText,
                    TextColor3 = o.TextStrong,
                    TextSize = d.isMobile and 13 or 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    RichText = true,
                    FontFace = o.FontSemiBold,
                    ZIndex = 133,
                }),
                Fusion.New("TextLabel")({
                    Name = "Text",
                    Size = UDim2.new(1, -66, 1, -38),
                    Position = UDim2.fromOffset(48, 31),
                    BackgroundTransparency = 1,
                    Text = bodyText,
                    TextColor3 = o.MutedText,
                    TextSize = d.isMobile and 12 or 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Top,
                    TextWrapped = true,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    RichText = true,
                    FontFace = o.Font,
                    ZIndex = 133,
                }),
                Fusion.New("TextButton")({
                    Name = "Dismiss",
                    Size = UDim2.fromOffset(26, 26),
                    Position = UDim2.new(1, -31, 0, 6),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Text = "x",
                    TextColor3 = o.FaintText,
                    TextSize = 16,
                    FontFace = o.FontSemiBold,
                    ZIndex = 136,
                }),
                Fusion.New("Frame")({
                    Name = "ProgressTrack",
                    Size = UDim2.new(1, -30, 0, 2),
                    Position = UDim2.new(0, 15, 1, -7),
                    BackgroundColor3 = o.Elevated,
                    BackgroundTransparency = 0.15,
                    BorderSizePixel = 0,
                    ZIndex = 132,
                    [Fusion.Children] = {
                        Fusion.New("UICorner")({
                            CornerRadius = UDim.new(1, 0),
                        }),
                        Fusion.New("Frame")({
                            Name = "Progress",
                            Size = progressSize,
                            BackgroundColor3 = accent,
                            BorderSizePixel = 0,
                            ZIndex = 133,
                            [Fusion.Children] = {
                                Fusion.New("UICorner")({
                                    CornerRadius = UDim.new(1, 0),
                                }),
                            },
                        }),
                    },
                }),
            },
        })

        card:SetAttribute("NotifHeight", height)
        card:SetAttribute("NotifTitle", titleText)
        card:SetAttribute("NotifText", bodyText)
        card:SetAttribute("LifeGeneration", 1)
        card:SetAttribute("DuplicateCount", 1)
        card.Parent = q

        local dismissButton = card:FindFirstChild("Dismiss")
        local progress = card:FindFirstChild("Progress", true)
        local stroke = card:FindFirstChild("NotificationStroke")
        local dismissed = false

        local function listCards()
            local list = {}
            for _, child in ipairs(q:GetChildren()) do
                if child:IsA("GuiObject") and child.Name == "Notification" then
                    list[#list + 1] = child
                end
            end
            table.sort(list, function(left, right)
                return (left.LayoutOrder or 0) > (right.LayoutOrder or 0)
            end)
            return list
        end

        local function relayout(animated)
            local offset = d.isMobile and 12 or 16
            for _, otherCard in ipairs(listCards()) do
                local otherHeight = otherCard:GetAttribute("NotifHeight") or otherCard.AbsoluteSize.Y
                local target = UDim2.new(1, d.isMobile and -10 or -18, 1, -(offset + otherHeight))
                if animated then
                    n:Tween(otherCard, o.Tween, { Position = target }, n.tweenstwo)
                else
                    otherCard.Position = target
                end
                offset += otherHeight + 8
            end
        end

        local function dismiss()
            if dismissed then
                return
            end
            dismissed = true
            api._FusionNotificationDismissers[card] = nil
            n:Tween(card, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Position = UDim2.new(1, width + 18, 1, card.Position.Y.Offset),
                GroupTransparency = 1,
            }, n.tweenstwo)
            n:Tween(cardScale, TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Scale = 0.982,
            })
            task.delay(0.14, function()
                if card.Parent then
                    card:Destroy()
                end
                relayout(true)
            end)
        end

        api._FusionNotificationDismissers[card] = dismiss
        if dismissButton then
            addRuntimeCleanup(dismissButton.Activated:Connect(dismiss))
            addRuntimeCleanup(dismissButton.MouseEnter:Connect(function()
                n:Tween(dismissButton, o.TweenFast, { TextColor3 = o.TextStrong })
            end))
            addRuntimeCleanup(dismissButton.MouseLeave:Connect(function()
                n:Tween(dismissButton, o.TweenFast, { TextColor3 = o.FaintText })
            end))
        end

        addRuntimeCleanup(card.MouseEnter:Connect(function()
            n:Tween(cardScale, o.TweenFast, { Scale = 1.004 })
            if stroke then
                n:Tween(stroke, o.TweenFast, { Color = accent:Lerp(o.TextStrong, 0.16), Transparency = 0.38 })
            end
        end))
        addRuntimeCleanup(card.MouseLeave:Connect(function()
            n:Tween(cardScale, o.TweenFast, { Scale = 1 })
            if stroke then
                n:Tween(stroke, o.TweenFast, { Color = o.BorderStrong, Transparency = 0.62 })
            end
        end))

        relayout(true)
        n:Tween(card, o.TweenSpring, { GroupTransparency = 0 }, n.tweenstwo)
        n:Tween(cardScale, o.TweenSpring, { Scale = 1 })
        if progress then
            n:Tween(progress, TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {
                Size = UDim2.fromScale(0, 1),
            }, n.tweenstwo)
        end

        local generation = card:GetAttribute("LifeGeneration")
        task.delay(lifetime, function()
            if card.Parent and not dismissed and card:GetAttribute("LifeGeneration") == generation then
                dismiss()
            end
        end)

        return card
    end

    d._FusionCreateNotificationV21 = createFusionNotification
end

do
    local createFusionNotification = d._FusionCreateNotificationV21
    local previousNotification = d.CreateNotification
    function d.CreateNotification(api, titleText, bodyText, lifetime, kind)
        if not api.Notifications or not api.Notifications.Enabled then
            return
        end

        titleText = tostring(titleText or "BadWars")
        bodyText = tostring(bodyText or "")
        lifetime = math.clamp(tonumber(lifetime) or 5, 1.25, 30)
        kind = string.lower(tostring(kind or "info"))

        task.defer(function()
            if api.ThreadFix then
                pcall(setthreadidentity, 8)
            end
            local ok, result = pcall(createFusionNotification, api, titleText, bodyText, lifetime, kind)
            if not ok then
                bwarn("[Fusion notification]: fallback", result)
                pcall(previousNotification, api, titleText, bodyText, lifetime, kind)
            end
        end)
    end
end
-- BADWARS_FUSION_DESIGN_RUNTIME_V21_END

-- BADWARS_FUSION_COMPONENT_KIT_V21_BEGIN
;(function()
    local Fusion = d.Fusion
    if type(Fusion) == "table" then
        local Kit = {}
        local Layout = {}
        local Motion = {}
        local Registry = {
            Components = {},
            Rules = {},
            Metrics = {
                Applied = 0,
                TextRepairs = 0,
                HitboxRepairs = 0,
                LayoutRepairs = 0,
                MotionRepairs = 0,
            },
        }

        local function isGuiObject(instance)
            return typeof(instance) == "Instance" and instance:IsA("GuiObject")
        end

        local function safeTween(instance, tweenInfo, properties, registry)
            if not isGuiObject(instance) and not (typeof(instance) == "Instance" and instance:IsA("UIScale")) then
                return nil
            end
            if type(properties) ~= "table" then
                return nil
            end
            return n:Tween(instance, tweenInfo or o.TweenFast, properties, registry)
        end

        local function makeState(value)
            return Fusion.Value(value)
        end

        local function makeComputed(dependencies, callback)
            return Fusion.Computed(dependencies, callback)
        end

        local function makeCorner(radius)
            return Fusion.New("UICorner")({
                CornerRadius = radius or o.Radius,
            })
        end

        local function makeStroke(name, color, transparency, thickness)
            return Fusion.New("UIStroke")({
                Name = name or "Stroke",
                Color = color or o.Border,
                Transparency = transparency or 0.72,
                Thickness = thickness or 1,
                LineJoinMode = Enum.LineJoinMode.Round,
            })
        end

        local function makePadding(left, right, top, bottom)
            return Fusion.New("UIPadding")({
                PaddingLeft = UDim.new(0, left or 0),
                PaddingRight = UDim.new(0, right or left or 0),
                PaddingTop = UDim.new(0, top or 0),
                PaddingBottom = UDim.new(0, bottom or top or 0),
            })
        end

        local function makeListLayout(direction, padding, alignment)
            return Fusion.New("UIListLayout")({
                FillDirection = direction or Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, padding or 0),
                HorizontalAlignment = alignment or Enum.HorizontalAlignment.Left,
                VerticalAlignment = Enum.VerticalAlignment.Top,
            })
        end

        local function readThemeColor(name, fallback)
            local value = o[name]
            if typeof(value) == "Color3" then
                return value
            end
            return fallback or o.Text
        end

        local function currentAccent()
            return Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
        end

        local function ensureScale(instance, name)
            local scale = instance:FindFirstChild(name or "FusionKitScale")
            if not scale then
                scale = Instance.new("UIScale")
                scale.Name = name or "FusionKitScale"
                scale.Scale = 1
                scale.Parent = instance
            end
            return scale
        end

        local function setAttributes(instance, attributes)
            if typeof(instance) ~= "Instance" or type(attributes) ~= "table" then
                return instance
            end
            for key, value in pairs(attributes) do
                pcall(function()
                    instance:SetAttribute(tostring(key), value)
                end)
            end
            return instance
        end

        function Motion.profile(name)
            local profiles = {
                instant = TweenInfo.new(0.001, Enum.EasingStyle.Linear),
                press = o.TweenPress,
                fast = o.TweenFast,
                smooth = o.Tween,
                slow = o.TweenSlow,
                spring = o.TweenSpring,
                back = o.TweenBack,
                panel = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                dismiss = TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                meter = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                linear = TweenInfo.new(0.25, Enum.EasingStyle.Linear),
            }
            return profiles[name] or profiles.smooth
        end

        function Motion.hover(instance, options)
            if not isGuiObject(instance) then
                return nil
            end
            if instance:GetAttribute("FusionKitHover") then
                return instance
            end
            instance:SetAttribute("FusionKitHover", true)
            options = type(options) == "table" and options or {}
            local scale = ensureScale(instance, "FusionKitHoverScale")
            local baseColor = instance.BackgroundColor3
            local baseTransparency = instance.BackgroundTransparency
            local hoverColor = options.Color or readThemeColor("SurfaceHover", baseColor)
            local hoverTransparency = options.Transparency or math.clamp(baseTransparency - 0.02, 0, 1)
            local hoverScale = options.Scale or 1.004
            local profile = options.Profile or Motion.profile("fast")

            d:Clean(instance.MouseEnter:Connect(function()
                if not instance.Parent then
                    return
                end
                Registry.Metrics.MotionRepairs += 1
                safeTween(scale, profile, { Scale = hoverScale })
                if baseTransparency < 1 then
                    safeTween(instance, profile, {
                        BackgroundColor3 = hoverColor,
                        BackgroundTransparency = hoverTransparency,
                    })
                end
            end))

            d:Clean(instance.MouseLeave:Connect(function()
                if not instance.Parent then
                    return
                end
                safeTween(scale, profile, { Scale = 1 })
                if baseTransparency < 1 then
                    safeTween(instance, profile, {
                        BackgroundColor3 = baseColor,
                        BackgroundTransparency = baseTransparency,
                    })
                end
            end))

            return instance
        end

        function Motion.press(instance, options)
            if not isGuiObject(instance) then
                return nil
            end
            if instance:GetAttribute("FusionKitPress") then
                return instance
            end
            instance:SetAttribute("FusionKitPress", true)
            options = type(options) == "table" and options or {}
            local scale = ensureScale(instance, "FusionKitPressScale")
            local downScale = options.DownScale or 0.992
            local upScale = options.UpScale or 1

            if instance:IsA("TextButton") or instance:IsA("ImageButton") then
                d:Clean(instance.MouseButton1Down:Connect(function()
                    safeTween(scale, Motion.profile("press"), { Scale = downScale })
                end))
                d:Clean(instance.MouseButton1Up:Connect(function()
                    safeTween(scale, Motion.profile("fast"), { Scale = upScale })
                end))
                d:Clean(instance.MouseLeave:Connect(function()
                    safeTween(scale, Motion.profile("fast"), { Scale = upScale })
                end))
            end

            return instance
        end

        function Motion.reveal(instance, options)
            if not isGuiObject(instance) then
                return instance
            end
            options = type(options) == "table" and options or {}
            local scale = ensureScale(instance, "FusionKitRevealScale")
            scale.Scale = options.StartScale or 0.985
            if instance:IsA("CanvasGroup") then
                instance.GroupTransparency = options.StartTransparency or 1
                safeTween(instance, options.TweenInfo or Motion.profile("spring"), {
                    GroupTransparency = options.EndTransparency or 0,
                }, n.tweenstwo)
            elseif instance.BackgroundTransparency < 1 then
                local targetTransparency = instance.BackgroundTransparency
                instance.BackgroundTransparency = 1
                safeTween(instance, options.TweenInfo or Motion.profile("spring"), {
                    BackgroundTransparency = targetTransparency,
                }, n.tweenstwo)
            end
            safeTween(scale, options.TweenInfo or Motion.profile("spring"), {
                Scale = options.EndScale or 1,
            }, n.tweenstwo)
            return instance
        end

        function Layout.measureText(text, size, font, width)
            return E(removeTags(tostring(text or "")), size or 12, font or o.Font, width or 1000) or Vector2.zero
        end

        function Layout.fitText(label, options)
            if not (typeof(label) == "Instance" and (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox"))) then
                return label
            end
            options = type(options) == "table" and options or {}
            local minSize = options.MinSize or 9
            local maxSize = options.MaxSize or label.TextSize
            local width = math.max(label.AbsoluteSize.X - (options.Padding or 0), 1)
            local height = math.max(label.AbsoluteSize.Y, 1)
            local selected = maxSize
            for size = maxSize, minSize, -1 do
                local bounds = Layout.measureText(label.Text, size, label.FontFace or o.Font, width)
                if bounds.X <= width and bounds.Y <= height + 4 then
                    selected = size
                    break
                end
            end
            if selected ~= label.TextSize then
                label.TextSize = selected
                Registry.Metrics.TextRepairs += 1
            end
            label.TextTruncate = Enum.TextTruncate.AtEnd
            return label
        end

        function Layout.stretchBetween(label, left, right)
            if not isGuiObject(label) then
                return label
            end
            left = left or label.Position.X.Offset
            right = right or 12
            label.Position = UDim2.new(0, left, label.Position.Y.Scale, label.Position.Y.Offset)
            label.Size = UDim2.new(1, -(left + right), label.Size.Y.Scale, label.Size.Y.Offset)
            if label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox") then
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
            end
            Registry.Metrics.LayoutRepairs += 1
            return label
        end

        function Layout.ensureHitbox(button, minWidth, minHeight)
            if not isGuiObject(button) then
                return button
            end
            minWidth = minWidth or (d.isMobile and 44 or 32)
            minHeight = minHeight or (d.isMobile and 44 or 32)
            local width = math.max(button.Size.X.Offset, minWidth)
            local height = math.max(button.Size.Y.Offset, minHeight)
            if button.Size.X.Scale == 0 or button.Size.Y.Scale == 0 then
                button.Size = UDim2.new(button.Size.X.Scale, width, button.Size.Y.Scale, height)
                Registry.Metrics.HitboxRepairs += 1
            end
            return button
        end

        function Layout.keepInsideViewport(instance, margin)
            if not isGuiObject(instance) or not B then
                return instance
            end
            margin = margin or 8
            local viewport = B.AbsoluteSize
            local size = instance.AbsoluteSize
            local position = instance.AbsolutePosition
            local x = instance.Position.X.Offset
            local y = instance.Position.Y.Offset
            if position.X < margin then
                x += margin - position.X
            elseif position.X + size.X > viewport.X - margin then
                x -= (position.X + size.X) - (viewport.X - margin)
            end
            if position.Y < margin then
                y += margin - position.Y
            elseif position.Y + size.Y > viewport.Y - margin then
                y -= (position.Y + size.Y) - (viewport.Y - margin)
            end
            instance.Position = UDim2.new(instance.Position.X.Scale, x, instance.Position.Y.Scale, y)
            return instance
        end

        function Layout.installListAutoCanvas(scroller, layout, padding)
            if not (typeof(scroller) == "Instance" and scroller:IsA("ScrollingFrame")) then
                return nil
            end
            layout = layout or scroller:FindFirstChildOfClass("UIListLayout") or scroller:FindFirstChildOfClass("UIGridLayout")
            if not layout then
                return nil
            end
            padding = padding or 8
            local function refresh()
                if not scroller.Parent then
                    return
                end
                local scale = A and A.Scale or 1
                local content = layout.AbsoluteContentSize
                scroller.CanvasSize = UDim2.fromOffset(
                    math.max(0, content.X / math.max(scale, 0.01)),
                    math.max(0, (content.Y + padding) / math.max(scale, 0.01))
                )
            end
            refresh()
            d:Clean(connectDeferredPropertyChanged(layout, "AbsoluteContentSize", refresh))
            d:Clean(connectDeferredPropertyChanged(scroller, "AbsoluteWindowSize", refresh))
            return refresh
        end

        function Kit.Text(props)
            props = type(props) == "table" and props or {}
            local label = Fusion.New("TextLabel")({
                Name = props.Name or "Text",
                Size = props.Size or UDim2.new(1, 0, 0, props.Height or 18),
                Position = props.Position or UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1,
                Text = props.Text or "",
                TextColor3 = props.Color or o.Text,
                TextSize = props.TextSize or 12,
                TextXAlignment = props.XAlignment or Enum.TextXAlignment.Left,
                TextYAlignment = props.YAlignment or Enum.TextYAlignment.Center,
                TextWrapped = props.Wrapped == true,
                TextTruncate = Enum.TextTruncate.AtEnd,
                RichText = props.RichText == true,
                FontFace = props.Font or o.Font,
                ZIndex = props.ZIndex or 1,
            })
            setAttributes(label, props.Attributes)
            return label
        end

        function Kit.Icon(props)
            props = type(props) == "table" and props or {}
            local icon = Fusion.New("ImageLabel")({
                Name = props.Name or "Icon",
                Size = props.Size or UDim2.fromOffset(16, 16),
                Position = props.Position or UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1,
                Image = props.Image or "",
                ImageColor3 = props.Color or o.Text,
                ImageTransparency = props.Transparency or 0,
                ScaleType = props.ScaleType or Enum.ScaleType.Fit,
                ZIndex = props.ZIndex or 1,
            })
            setAttributes(icon, props.Attributes)
            return icon
        end

        function Kit.Surface(props)
            props = type(props) == "table" and props or {}
            local surface = Fusion.New("Frame")({
                Name = props.Name or "Surface",
                Size = props.Size or UDim2.fromScale(1, 1),
                Position = props.Position or UDim2.fromOffset(0, 0),
                AnchorPoint = props.AnchorPoint or Vector2.zero,
                BackgroundColor3 = props.Color or o.Surface,
                BackgroundTransparency = props.Transparency or 0,
                BorderSizePixel = 0,
                ClipsDescendants = props.ClipsDescendants ~= false,
                ZIndex = props.ZIndex or 1,
                [Fusion.Children] = {
                    makeCorner(props.Radius or o.Radius),
                    props.Stroke ~= false and makeStroke(props.StrokeName or "SurfaceStroke", props.StrokeColor or o.Border, props.StrokeTransparency or 0.78, props.StrokeThickness or 1) or nil,
                    props.Padding and makePadding(props.Padding, props.Padding, props.PaddingY or props.Padding, props.PaddingY or props.Padding) or nil,
                    props.Children,
                },
            })
            setAttributes(surface, props.Attributes)
            if props.Motion ~= false then
                Motion.hover(surface, {
                    Color = props.HoverColor or o.SurfaceHover,
                    Transparency = props.HoverTransparency,
                    Scale = props.HoverScale or 1.002,
                })
            end
            return surface
        end

        function Kit.Button(props)
            props = type(props) == "table" and props or {}
            local hovered = makeState(false)
            local accent = props.Accent or currentAccent()
            local button = Fusion.New("TextButton")({
                Name = props.Name or "Button",
                Size = props.Size or UDim2.new(1, 0, 0, d.isMobile and 42 or 34),
                Position = props.Position or UDim2.fromOffset(0, 0),
                BackgroundColor3 = makeComputed({ hovered }, function(isHovered)
                    return isHovered and (props.HoverColor or o.SurfaceHover) or (props.Color or o.Surface)
                end),
                BackgroundTransparency = props.Transparency or 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true,
                ZIndex = props.ZIndex or 1,
                [Fusion.OnEvent("MouseEnter")] = function()
                    hovered:set(true)
                end,
                [Fusion.OnEvent("MouseLeave")] = function()
                    hovered:set(false)
                end,
                [Fusion.OnEvent("Activated")] = function(...)
                    if type(props.Activated) == "function" then
                        props.Activated(...)
                    end
                end,
                [Fusion.Children] = {
                    makeCorner(props.Radius or o.RadiusSmall),
                    makeStroke(props.StrokeName or "ButtonStroke", makeComputed({ hovered }, function(isHovered)
                        return isHovered and accent or (props.StrokeColor or o.Border)
                    end), props.StrokeTransparency or 0.76, 1),
                    makePadding(props.PaddingLeft or 12, props.PaddingRight or 12, 0, 0),
                    props.Icon and Kit.Icon({
                        Name = "ButtonIcon",
                        Image = props.Icon,
                        Size = UDim2.fromOffset(16, 16),
                        Position = UDim2.fromOffset(10, 9),
                        Color = props.IconColor or o.MutedText,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }) or nil,
                    Kit.Text({
                        Name = "ButtonLabel",
                        Text = props.Text or "Button",
                        Size = UDim2.new(1, props.Icon and -34 or -4, 1, 0),
                        Position = UDim2.fromOffset(props.Icon and 34 or 2, 0),
                        Color = props.TextColor or o.TextStrong,
                        TextSize = props.TextSize or 12,
                        Font = props.Font or o.FontSemiBold,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                    props.Children,
                },
            })
            Layout.ensureHitbox(button)
            Motion.press(button)
            setAttributes(button, props.Attributes)
            return button
        end

        function Kit.ToggleShell(props)
            props = type(props) == "table" and props or {}
            local enabled = props.EnabledState or makeState(props.Enabled == true)
            local hovered = makeState(false)
            local accent = props.Accent or currentAccent()
            local shell = Fusion.New("TextButton")({
                Name = props.Name or "ToggleShell",
                Size = props.Size or UDim2.new(1, 0, 0, d.isMobile and 48 or 40),
                BackgroundColor3 = makeComputed({ enabled, hovered }, function(isEnabled, isHovered)
                    if isEnabled then
                        return o.Elevated:Lerp(accent, 0.16)
                    end
                    return isHovered and o.SurfaceHover or o.Surface
                end),
                BackgroundTransparency = 0,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true,
                ZIndex = props.ZIndex or 1,
                [Fusion.OnEvent("MouseEnter")] = function()
                    hovered:set(true)
                end,
                [Fusion.OnEvent("MouseLeave")] = function()
                    hovered:set(false)
                end,
                [Fusion.OnEvent("Activated")] = function()
                    enabled:set(not enabled:get())
                    if type(props.Changed) == "function" then
                        props.Changed(enabled:get())
                    end
                end,
                [Fusion.Children] = {
                    makeCorner(props.Radius or o.RadiusSmall),
                    makeStroke("ToggleShellStroke", makeComputed({ enabled, hovered }, function(isEnabled, isHovered)
                        if isEnabled then
                            return accent
                        end
                        return isHovered and o.BorderStrong or o.Border
                    end), makeComputed({ enabled }, function(isEnabled)
                        return isEnabled and 0.42 or 0.82
                    end), 1),
                    Kit.Text({
                        Name = "ToggleLabel",
                        Text = props.Text or "Toggle",
                        Size = UDim2.new(1, -64, 1, 0),
                        Position = UDim2.fromOffset(12, 0),
                        Color = makeComputed({ enabled }, function(isEnabled)
                            return isEnabled and o.TextStrong or o.MutedText
                        end),
                        Font = o.FontSemiBold,
                        TextSize = props.TextSize or 12,
                        ZIndex = (props.ZIndex or 1) + 2,
                    }),
                    Fusion.New("Frame")({
                        Name = "SwitchTrack",
                        Size = UDim2.fromOffset(34, 18),
                        Position = UDim2.new(1, -46, 0.5, -9),
                        BackgroundColor3 = makeComputed({ enabled }, function(isEnabled)
                            return isEnabled and accent or o.Elevated
                        end),
                        BorderSizePixel = 0,
                        ZIndex = (props.ZIndex or 1) + 2,
                        [Fusion.Children] = {
                            makeCorner(UDim.new(1, 0)),
                            Fusion.New("Frame")({
                                Name = "SwitchKnob",
                                Size = UDim2.fromOffset(14, 14),
                                Position = makeComputed({ enabled }, function(isEnabled)
                                    return UDim2.fromOffset(isEnabled and 18 or 2, 2)
                                end),
                                BackgroundColor3 = makeComputed({ enabled }, function(isEnabled)
                                    return isEnabled and o.TextStrong or o.MutedText
                                end),
                                BorderSizePixel = 0,
                                ZIndex = (props.ZIndex or 1) + 3,
                                [Fusion.Children] = {
                                    makeCorner(UDim.new(1, 0)),
                                },
                            }),
                        },
                    }),
                    props.Children,
                },
            })
            Motion.press(shell)
            return shell
        end

        function Kit.StatChip(props)
            props = type(props) == "table" and props or {}
            local valueState = props.ValueState or makeState(props.Value or "")
            local labelText = props.Label or "Stat"
            local chip = Kit.Surface({
                Name = props.Name or "StatChip",
                Size = props.Size or UDim2.fromOffset(props.Width or 132, props.Height or 44),
                Color = props.Color or o.MainSoft,
                StrokeColor = props.StrokeColor or o.BorderStrong,
                StrokeTransparency = props.StrokeTransparency or 0.64,
                Radius = props.Radius or o.RadiusSmall,
                Motion = true,
                Children = {
                    Kit.Text({
                        Name = "StatLabel",
                        Text = string.upper(labelText),
                        Size = UDim2.new(1, -18, 0, 13),
                        Position = UDim2.fromOffset(9, 5),
                        Color = props.LabelColor or o.FaintText,
                        TextSize = 8,
                        Font = o.FontBold,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                    Kit.Text({
                        Name = "StatValue",
                        Text = valueState,
                        Size = UDim2.new(1, -18, 0, 20),
                        Position = UDim2.fromOffset(9, 20),
                        Color = props.ValueColor or o.TextStrong,
                        TextSize = props.ValueSize or 13,
                        Font = o.FontSemiBold,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                },
            })
            chip:SetAttribute("BadWarsFusionStatChip", true)
            return chip
        end

        function Kit.Toolbar(props)
            props = type(props) == "table" and props or {}
            local toolbar = Fusion.New("Frame")({
                Name = props.Name or "Toolbar",
                Size = props.Size or UDim2.new(1, 0, 0, d.isMobile and 46 or 38),
                Position = props.Position or UDim2.fromOffset(0, 0),
                BackgroundTransparency = 1,
                ZIndex = props.ZIndex or 1,
                [Fusion.Children] = {
                    makeListLayout(Enum.FillDirection.Horizontal, props.Gap or 8, props.Alignment or Enum.HorizontalAlignment.Left),
                    props.Padding and makePadding(props.Padding, props.Padding, 0, 0) or nil,
                    props.Children,
                },
            })
            return toolbar
        end

        function Kit.SectionHeader(props)
            props = type(props) == "table" and props or {}
            return Fusion.New("Frame")({
                Name = props.Name or "SectionHeader",
                Size = props.Size or UDim2.new(1, 0, 0, 34),
                BackgroundTransparency = 1,
                ZIndex = props.ZIndex or 1,
                [Fusion.Children] = {
                    Kit.Text({
                        Name = "SectionTitle",
                        Text = props.Title or "Section",
                        Size = UDim2.new(1, -80, 1, 0),
                        Position = UDim2.fromOffset(0, 0),
                        Color = props.Color or o.TextStrong,
                        TextSize = props.TextSize or 14,
                        Font = o.FontBold,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                    props.Action and Kit.Button({
                        Name = "SectionAction",
                        Text = props.ActionText or "Action",
                        Size = UDim2.fromOffset(props.ActionWidth or 76, 28),
                        Position = UDim2.new(1, -(props.ActionWidth or 76), 0.5, -14),
                        Activated = props.Action,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }) or nil,
                },
            })
        end

        function Kit.EmptyState(props)
            props = type(props) == "table" and props or {}
            return Kit.Surface({
                Name = props.Name or "EmptyState",
                Size = props.Size or UDim2.new(1, 0, 0, 96),
                Color = props.Color or o.MainSoft,
                Transparency = props.Transparency or 0.12,
                StrokeTransparency = 0.88,
                Motion = false,
                Children = {
                    Kit.Text({
                        Name = "EmptyTitle",
                        Text = props.Title or "Nothing here",
                        Size = UDim2.new(1, -24, 0, 22),
                        Position = UDim2.fromOffset(12, 24),
                        Color = o.TextStrong,
                        TextSize = 13,
                        Font = o.FontSemiBold,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                    Kit.Text({
                        Name = "EmptyText",
                        Text = props.Text or "",
                        Size = UDim2.new(1, -24, 0, 30),
                        Position = UDim2.fromOffset(12, 48),
                        Color = o.MutedText,
                        TextSize = 11,
                        Wrapped = true,
                        ZIndex = (props.ZIndex or 1) + 1,
                    }),
                },
            })
        end

        local ruleId = 0
        function Registry.addRule(name, predicate, apply)
            ruleId += 1
            Registry.Rules[#Registry.Rules + 1] = {
                Id = ruleId,
                Name = tostring(name or ("Rule" .. ruleId)),
                Predicate = predicate,
                Apply = apply,
            }
            return ruleId
        end

        function Registry.apply(instance)
            if typeof(instance) ~= "Instance" then
                return
            end
            for _, rule in ipairs(Registry.Rules) do
                local ok, matches = pcall(rule.Predicate, instance)
                if ok and matches then
                    local applied, err = pcall(rule.Apply, instance)
                    if applied then
                        Registry.Metrics.Applied += 1
                    else
                        bwarn("[Fusion Kit rule failed]", rule.Name, err)
                    end
                end
            end
        end

        Registry.addRule("TextOverflowRepair", function(instance)
            return instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
        end, function(instance)
            instance.ClipsDescendants = true
            instance.TextTruncate = Enum.TextTruncate.AtEnd
            if instance.AbsoluteSize.X > 0 and instance.AbsoluteSize.Y > 0 then
                Layout.fitText(instance, {
                    MinSize = d.isMobile and 10 or 9,
                    MaxSize = math.max(instance.TextSize, d.isMobile and 12 or 11),
                    Padding = 8,
                })
            end
        end)

        Registry.addRule("ButtonHitboxRepair", function(instance)
            return instance:IsA("TextButton") or instance:IsA("ImageButton")
        end, function(instance)
            instance.AutoButtonColor = false
            Layout.ensureHitbox(instance)
            Motion.hover(instance)
            Motion.press(instance)
        end)

        Registry.addRule("ScrollingCanvasRepair", function(instance)
            return instance:IsA("ScrollingFrame")
        end, function(instance)
            local layout = instance:FindFirstChildOfClass("UIListLayout") or instance:FindFirstChildOfClass("UIGridLayout")
            if layout then
                Layout.installListAutoCanvas(instance, layout, d.isMobile and 18 or 12)
            end
            instance.ScrollBarThickness = math.clamp(instance.ScrollBarThickness, 2, d.isMobile and 5 or 4)
            instance.ScrollingDirection = instance.ScrollingDirection == Enum.ScrollingDirection.X
                and Enum.ScrollingDirection.X
                or Enum.ScrollingDirection.Y
        end)

        Registry.addRule("MetricVisibilityRepair", function(instance)
            if not isGuiObject(instance) then
                return false
            end
            local name = instance.Name
            if name == "FPS" or name == "Ping" or name == "Memory" or name == "Clock" or name == "Speedmeter" then
                return true
            end
            local title = instance:FindFirstChild("WidgetTitle")
            return title and title:IsA("TextLabel") and ({
                FPS = true,
                PING = true,
                MEMORY = true,
                CLOCK = true,
                SPEEDMETER = true,
            })[title.Text] == true
        end, function(instance)
            instance.Visible = true
            instance.BackgroundTransparency = math.min(instance.BackgroundTransparency, 0.08)
            instance.ClipsDescendants = false
            local stroke = instance:FindFirstChild("FusionKitMetricStroke") or Instance.new("UIStroke")
            stroke.Name = "FusionKitMetricStroke"
            stroke.Color = o.BorderStrong
            stroke.Transparency = 0.58
            stroke.Thickness = 1
            stroke.Parent = instance
            for _, child in ipairs(instance:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Visible = true
                    child.TextTransparency = 0
                    child.TextColor3 = child:GetAttribute("PremiumWidgetInternal") and child.TextColor3 or o.TextStrong
                end
            end
        end)

        Registry.addRule("LeftRightStretchRepair", function(instance)
            if not (instance:IsA("TextLabel") or instance:IsA("TextButton")) then
                return false
            end
            local parent = instance.Parent
            if not (parent and parent:IsA("GuiObject")) then
                return false
            end
            local name = instance.Name
            return name:find("Label") ~= nil
                or name:find("Title") ~= nil
                or name:find("Text") ~= nil
                or name:find("Value") ~= nil
        end, function(instance)
            local parent = instance.Parent
            if not parent then
                return
            end
            local left = math.max(0, instance.Position.X.Offset)
            local reservedRight = 12
            for _, sibling in ipairs(parent:GetChildren()) do
                if sibling ~= instance and sibling:IsA("GuiObject") and sibling.Visible then
                    local siblingLeft = sibling.Position.X.Offset
                    if siblingLeft > left and sibling.AbsoluteSize.X > 0 then
                        reservedRight = math.max(reservedRight, parent.AbsoluteSize.X - siblingLeft + 8)
                    end
                end
            end
            if parent.AbsoluteSize.X > left + reservedRight + 24 then
                Layout.stretchBetween(instance, left, reservedRight)
            end
        end)

        d.FusionKit = Kit
        d.FusionLayout = Layout
        d.FusionMotion = Motion
        d.FusionRegistry = Registry
        d.Libraries.FusionKit = Kit
        d.Libraries.FusionLayout = Layout
        d.Libraries.FusionMotion = Motion
        d.Libraries.FusionRegistry = Registry

        task.defer(function()
            if not B or not B.Parent then
                return
            end
            for _, descendant in ipairs(B:GetDescendants()) do
                Registry.apply(descendant)
            end
            d:Clean(B.DescendantAdded:Connect(function(descendant)
                task.defer(Registry.apply, descendant)
            end))
        end)
    end
end)()
-- BADWARS_FUSION_COMPONENT_KIT_V21_END

-- BADWARS_FUSION_STYLE_RECIPES_V21_BEGIN
;(function()
    local Kit = d.FusionKit
    local Layout = d.FusionLayout
    local Motion = d.FusionMotion
    local Registry = d.FusionRegistry
    if type(Kit) == "table" and type(Layout) == "table" and type(Motion) == "table" and type(Registry) == "table" then
        local Recipes = {}
        local RoleMatchers = {}

        local function color(name, fallback)
            local value = o[name]
            if typeof(value) == "Color3" then
                return value
            end
            return fallback or o.Text
        end

        local function accent(alpha)
            local value = Color3.fromHSV(d.GUIColor.Hue, d.GUIColor.Sat, d.GUIColor.Value)
            if alpha then
                return value:Lerp(o.TextStrong, alpha)
            end
            return value
        end

        local function addRecipe(name, recipe)
            recipe = type(recipe) == "table" and recipe or {}
            recipe.Name = tostring(name)
            Recipes[recipe.Name] = recipe
            return recipe
        end

        local function addMatcher(name, predicate)
            RoleMatchers[#RoleMatchers + 1] = {
                Name = tostring(name),
                Predicate = predicate,
            }
        end

        addRecipe("window", {
            Radius = o.RadiusLarge,
            StrokeName = "FusionWindowStroke",
            StrokeTransparency = 0.58,
            Background = "MainSoft",
            HoverBackground = "Surface",
            Padding = 0,
            MotionScale = 1,
        })

        addRecipe("category", {
            Radius = o.Radius,
            StrokeName = "FusionCategoryStroke",
            StrokeTransparency = 0.68,
            Background = "Surface",
            HoverBackground = "SurfaceHover",
            MotionScale = 1.001,
        })

        addRecipe("module", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionModuleStroke",
            StrokeTransparency = 0.84,
            Background = "Surface",
            HoverBackground = "SurfaceHover",
            MotionScale = 1.003,
            MinHeight = d.isMobile and 46 or 36,
            TextLeft = 12,
            TextRight = 54,
        })

        addRecipe("moduleEnabled", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionModuleEnabledStroke",
            StrokeTransparency = 0.46,
            BackgroundColor = function()
                return o.Elevated:Lerp(accent(), 0.16)
            end,
            HoverBackgroundColor = function()
                return o.Elevated:Lerp(accent(), 0.23)
            end,
            MotionScale = 1.003,
            MinHeight = d.isMobile and 46 or 36,
            TextLeft = 12,
            TextRight = 54,
        })

        addRecipe("settingRow", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionSettingStroke",
            StrokeTransparency = 0.88,
            Background = "Surface",
            HoverBackground = "SurfaceHover",
            MotionScale = 1.002,
            MinHeight = d.isMobile and 44 or 34,
            TextLeft = 10,
            TextRight = 66,
        })

        addRecipe("dropdown", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionDropdownStroke",
            StrokeTransparency = 0.72,
            Background = "Elevated",
            HoverBackground = "ElevatedHover",
            MotionScale = 1.002,
            MinHeight = d.isMobile and 42 or 34,
            TextLeft = 12,
            TextRight = 30,
        })

        addRecipe("input", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionInputStroke",
            StrokeTransparency = 0.72,
            Background = "MainSoft",
            HoverBackground = "Elevated",
            MotionScale = 1,
            MinHeight = d.isMobile and 42 or 34,
            TextLeft = 10,
            TextRight = 10,
        })

        addRecipe("compactButton", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionCompactButtonStroke",
            StrokeTransparency = 0.76,
            Background = "Surface",
            HoverBackground = "SurfaceHover",
            MotionScale = 1.006,
            MinWidth = d.isMobile and 44 or 30,
            MinHeight = d.isMobile and 40 or 30,
        })

        addRecipe("primaryButton", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionPrimaryButtonStroke",
            StrokeTransparency = 0.38,
            BackgroundColor = function()
                return accent():Lerp(o.Elevated, 0.16)
            end,
            HoverBackgroundColor = function()
                return accent():Lerp(o.TextStrong, 0.08)
            end,
            MotionScale = 1.004,
            MinHeight = d.isMobile and 44 or 34,
            TextLeft = 12,
            TextRight = 12,
        })

        addRecipe("dangerButton", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionDangerButtonStroke",
            StrokeTransparency = 0.48,
            BackgroundColor = function()
                return o.Danger:Lerp(o.MainSoft, 0.64)
            end,
            HoverBackgroundColor = function()
                return o.Danger:Lerp(o.MainSoft, 0.52)
            end,
            MotionScale = 1.004,
            MinHeight = d.isMobile and 44 or 34,
            TextLeft = 12,
            TextRight = 12,
        })

        addRecipe("statWidget", {
            Radius = o.Radius,
            StrokeName = "FusionStatWidgetStroke",
            StrokeTransparency = 0.56,
            Background = "MainSoft",
            HoverBackground = "Elevated",
            MotionScale = 1.004,
            MinWidth = d.isMobile and 120 or 112,
            MinHeight = d.isMobile and 46 or 38,
            TextLeft = 10,
            TextRight = 10,
        })

        addRecipe("notification", {
            Radius = o.Radius,
            StrokeName = "NotificationStroke",
            StrokeTransparency = 0.62,
            Background = "MainSoft",
            HoverBackground = "Elevated",
            MotionScale = 1.004,
            TextLeft = 48,
            TextRight = 36,
        })

        addRecipe("tooltip", {
            Radius = o.RadiusSmall,
            StrokeName = "TooltipStroke",
            StrokeTransparency = 0.48,
            Background = "Elevated",
            HoverBackground = "Elevated",
            MotionScale = 1,
            TextLeft = 12,
            TextRight = 12,
        })

        addRecipe("navigation", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionNavigationStroke",
            StrokeTransparency = 0.84,
            Background = "MainSoft",
            HoverBackground = "SurfaceHover",
            MotionScale = 1.002,
            MinHeight = d.isMobile and 46 or 36,
            TextLeft = 36,
            TextRight = 12,
        })

        addRecipe("search", {
            Radius = o.RadiusSmall,
            StrokeName = "FusionSearchStroke",
            StrokeTransparency = 0.72,
            Background = "MainSoft",
            HoverBackground = "Elevated",
            MotionScale = 1,
            MinHeight = d.isMobile and 42 or 34,
            TextLeft = 34,
            TextRight = 12,
        })

        addRecipe("overlay", {
            Radius = o.Radius,
            StrokeName = "FusionOverlayStroke",
            StrokeTransparency = 0.62,
            Background = "MainSoft",
            HoverBackground = "Elevated",
            MotionScale = 1.002,
            TextLeft = 12,
            TextRight = 12,
        })

        addMatcher("notification", function(instance)
            return instance.Name == "Notification"
        end)

        addMatcher("tooltip", function(instance)
            return instance.Name == "Tooltip"
        end)

        addMatcher("search", function(instance)
            local name = instance.Name:lower()
            return name:find("search") ~= nil
        end)

        addMatcher("statWidget", function(instance)
            if not instance:IsA("GuiObject") then
                return false
            end
            if ({
                FPS = true,
                Ping = true,
                Memory = true,
                Clock = true,
                Speedmeter = true,
            })[instance.Name] then
                return true
            end
            local widgetTitle = instance:FindFirstChild("WidgetTitle")
            return widgetTitle and widgetTitle:IsA("TextLabel") and ({
                FPS = true,
                PING = true,
                MEMORY = true,
                CLOCK = true,
                SPEEDMETER = true,
            })[widgetTitle.Text] == true
        end)

        addMatcher("navigation", function(instance)
            local name = instance.Name:lower()
            return name:find("navigation") ~= nil
                or name:find("nav") ~= nil
                or name:find("tab") ~= nil
        end)

        addMatcher("dropdown", function(instance)
            local name = instance.Name:lower()
            return name:find("dropdown") ~= nil
                or name:find("option") ~= nil
        end)

        addMatcher("input", function(instance)
            return instance:IsA("TextBox")
                or instance.Name:lower():find("input") ~= nil
                or instance.Name:lower():find("textbox") ~= nil
        end)

        addMatcher("primaryButton", function(instance)
            local name = instance.Name:lower()
            return name:find("save") ~= nil
                or name:find("confirm") ~= nil
                or name:find("apply") ~= nil
        end)

        addMatcher("dangerButton", function(instance)
            local name = instance.Name:lower()
            return name:find("delete") ~= nil
                or name:find("reset") ~= nil
                or name:find("remove") ~= nil
        end)

        addMatcher("compactButton", function(instance)
            if not (instance:IsA("TextButton") or instance:IsA("ImageButton")) then
                return false
            end
            return instance.AbsoluteSize.X <= 54 or instance.AbsoluteSize.Y <= 32
        end)

        addMatcher("moduleEnabled", function(instance)
            if not instance:IsA("GuiObject") then
                return false
            end
            return instance:GetAttribute("Enabled") == true
                or instance:GetAttribute("ModuleEnabled") == true
        end)

        addMatcher("module", function(instance)
            local name = instance.Name:lower()
            return name:find("module") ~= nil
                or name:find("toggle") ~= nil
        end)

        addMatcher("settingRow", function(instance)
            local name = instance.Name:lower()
            return name:find("setting") ~= nil
                or name:find("row") ~= nil
                or name:find("slider") ~= nil
                or name:find("bind") ~= nil
        end)

        addMatcher("category", function(instance)
            local name = instance.Name:lower()
            return name:find("category") ~= nil
                or name:find("pane") ~= nil
        end)

        addMatcher("overlay", function(instance)
            local name = instance.Name:lower()
            return name:find("overlay") ~= nil
                or name:find("prompt") ~= nil
        end)

        addMatcher("window", function(instance)
            local name = instance.Name:lower()
            return name:find("window") ~= nil
                or name == "main"
        end)

        local function findRole(instance)
            if not instance:IsA("GuiObject") then
                return nil
            end
            for _, matcher in ipairs(RoleMatchers) do
                local ok, matched = pcall(matcher.Predicate, instance)
                if ok and matched then
                    return matcher.Name
                end
            end
            return nil
        end

        local function ensureCorner(instance, radius)
            local corner = instance:FindFirstChildOfClass("UICorner")
            if not corner then
                corner = Instance.new("UICorner")
                corner.Name = "FusionRecipeCorner"
                corner.Parent = instance
            end
            corner.CornerRadius = radius or o.RadiusSmall
            return corner
        end

        local function ensureStroke(instance, recipe)
            if recipe.StrokeName == false then
                return nil
            end
            local stroke = instance:FindFirstChild(recipe.StrokeName or "FusionRecipeStroke")
                or instance:FindFirstChildOfClass("UIStroke")
            if not stroke then
                stroke = Instance.new("UIStroke")
                stroke.Name = recipe.StrokeName or "FusionRecipeStroke"
                stroke.Parent = instance
            end
            stroke.Color = recipe.StrokeColor or accent(0.08)
            stroke.Transparency = recipe.StrokeTransparency or 0.78
            stroke.Thickness = recipe.StrokeThickness or 1
            stroke.LineJoinMode = Enum.LineJoinMode.Round
            return stroke
        end

        local function resolveBackground(recipe, hovered)
            local direct = hovered and recipe.HoverBackgroundColor or recipe.BackgroundColor
            if type(direct) == "function" then
                local ok, value = pcall(direct)
                if ok and typeof(value) == "Color3" then
                    return value
                end
            elseif typeof(direct) == "Color3" then
                return direct
            end
            local named = hovered and recipe.HoverBackground or recipe.Background
            return color(named, hovered and o.SurfaceHover or o.Surface)
        end

        local function repairTextChildren(instance, recipe)
            local left = recipe.TextLeft
            local right = recipe.TextRight
            for _, child in ipairs(instance:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
                    child.TextTruncate = Enum.TextTruncate.AtEnd
                    child.ClipsDescendants = true
                    if left and right and child.AbsoluteSize.X > 0 then
                        Layout.stretchBetween(child, math.max(left, child.Position.X.Offset), right)
                    end
                    if child.TextXAlignment == Enum.TextXAlignment.Center and child.AbsoluteSize.X > 84 then
                        child.TextXAlignment = Enum.TextXAlignment.Left
                    end
                    if child.AbsoluteSize.X > 0 and child.AbsoluteSize.Y > 0 then
                        Layout.fitText(child, {
                            MinSize = d.isMobile and 10 or 9,
                            MaxSize = math.max(child.TextSize, d.isMobile and 12 or 11),
                            Padding = 8,
                        })
                    end
                end
            end
        end

        local function applyRecipe(instance, role)
            local recipe = Recipes[role]
            if not recipe or not instance:IsA("GuiObject") then
                return
            end
            if instance:GetAttribute("FusionRecipeApplied") == role then
                repairTextChildren(instance, recipe)
                return
            end
            instance:SetAttribute("FusionRecipeApplied", role)
            instance.ClipsDescendants = role == "statWidget" and false or instance.ClipsDescendants
            if recipe.MinWidth or recipe.MinHeight then
                Layout.ensureHitbox(instance, recipe.MinWidth, recipe.MinHeight)
            end
            if instance.BackgroundTransparency < 1 then
                instance.BackgroundColor3 = resolveBackground(recipe, false)
            end
            ensureCorner(instance, recipe.Radius)
            local stroke = ensureStroke(instance, recipe)
            repairTextChildren(instance, recipe)
            if recipe.MotionScale and recipe.MotionScale ~= 1 then
                Motion.hover(instance, {
                    Color = resolveBackground(recipe, true),
                    Scale = recipe.MotionScale,
                })
                if instance:IsA("TextButton") or instance:IsA("ImageButton") then
                    Motion.press(instance)
                end
            end
            if stroke and role == "statWidget" then
                d:Clean(instance.MouseEnter:Connect(function()
                    n:Tween(stroke, o.TweenFast, {
                        Color = accent(0.12),
                        Transparency = 0.34,
                    })
                end))
                d:Clean(instance.MouseLeave:Connect(function()
                    n:Tween(stroke, o.TweenFast, {
                        Color = o.BorderStrong,
                        Transparency = recipe.StrokeTransparency or 0.56,
                    })
                end))
            end
        end

        function Recipes.Apply(instance)
            if typeof(instance) ~= "Instance" or not instance:IsA("GuiObject") then
                return nil
            end
            local role = findRole(instance)
            if role then
                applyRecipe(instance, role)
            end
            return role
        end

        function Recipes.Refresh(root)
            root = root or B
            if not root then
                return 0
            end
            local count = 0
            if root:IsA("GuiObject") then
                if Recipes.Apply(root) then
                    count += 1
                end
            end
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiObject") and Recipes.Apply(descendant) then
                    count += 1
                end
            end
            return count
        end

        function Recipes.Register(name, recipe, predicate)
            addRecipe(name, recipe)
            if type(predicate) == "function" then
                addMatcher(name, predicate)
            end
            return Recipes[name]
        end

        d.FusionStyleRecipes = Recipes
        d.Libraries.FusionStyleRecipes = Recipes

        task.defer(function()
            if not B or not B.Parent then
                return
            end
            Recipes.Refresh(B)
            d:Clean(B.DescendantAdded:Connect(function(descendant)
                task.defer(function()
                    if descendant and descendant.Parent then
                        Recipes.Apply(descendant)
                    end
                end)
            end))
            d:Clean(B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                task.delay(0.05, function()
                    if B and B.Parent then
                        Recipes.Refresh(B)
                    end
                end)
            end))
        end)
    end
end)()
-- BADWARS_FUSION_STYLE_RECIPES_V21_END

-- BADWARS_FUSION_AUDIT_REPAIR_V21_BEGIN
;(function()
    local Layout = d.FusionLayout
    local Motion = d.FusionMotion
    local Recipes = d.FusionStyleRecipes
    if type(Layout) == "table" and type(Motion) == "table" then
        local Audit = {
            Enabled = true,
            LastRun = 0,
            MinimumInterval = 0.2,
            Reports = {},
            Counters = {
                Runs = 0,
                OverlapFixes = 0,
                ContrastFixes = 0,
                ViewportFixes = 0,
                TextFixes = 0,
                MotionSkips = 0,
            },
        }

        local function now()
            return os.clock()
        end

        local function pushReport(kind, instance, message)
            local report = {
                Time = now(),
                Kind = tostring(kind or "info"),
                Name = typeof(instance) == "Instance" and instance:GetFullName() or tostring(instance),
                Message = tostring(message or ""),
            }
            Audit.Reports[#Audit.Reports + 1] = report
            if #Audit.Reports > 80 then
                table.remove(Audit.Reports, 1)
            end
            return report
        end

        local function isVisibleGui(instance)
            return typeof(instance) == "Instance"
                and instance:IsA("GuiObject")
                and instance.Visible
                and instance.AbsoluteSize.X > 0
                and instance.AbsoluteSize.Y > 0
        end

        local function rectOf(instance)
            local position = instance.AbsolutePosition
            local size = instance.AbsoluteSize
            return {
                Left = position.X,
                Top = position.Y,
                Right = position.X + size.X,
                Bottom = position.Y + size.Y,
                Width = size.X,
                Height = size.Y,
            }
        end

        local function intersects(aRect, bRect, padding)
            padding = padding or 0
            return aRect.Left < bRect.Right - padding
                and aRect.Right > bRect.Left + padding
                and aRect.Top < bRect.Bottom - padding
                and aRect.Bottom > bRect.Top + padding
        end

        local function luminance(colorValue)
            if typeof(colorValue) ~= "Color3" then
                return 1
            end
            local function channel(value)
                if value <= 0.03928 then
                    return value / 12.92
                end
                return ((value + 0.055) / 1.055) ^ 2.4
            end
            return 0.2126 * channel(colorValue.R)
                + 0.7152 * channel(colorValue.G)
                + 0.0722 * channel(colorValue.B)
        end

        local function contrastRatio(aColor, bColor)
            local aLum = luminance(aColor)
            local bLum = luminance(bColor)
            local lighter = math.max(aLum, bLum)
            local darker = math.min(aLum, bLum)
            return (lighter + 0.05) / (darker + 0.05)
        end

        local function nearestBackground(instance)
            local cursor = instance.Parent
            while cursor do
                if cursor:IsA("GuiObject") and cursor.BackgroundTransparency < 0.96 then
                    return cursor.BackgroundColor3
                end
                cursor = cursor.Parent
            end
            return o.Main
        end

        local function repairContrast(label)
            if not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
                return false
            end
            local background = nearestBackground(label)
            local ratio = contrastRatio(label.TextColor3, background)
            if ratio >= 3.8 then
                return false
            end
            local lightRatio = contrastRatio(o.TextStrong, background)
            local mutedRatio = contrastRatio(o.MutedText, background)
            if lightRatio >= mutedRatio then
                label.TextColor3 = o.TextStrong
            else
                label.TextColor3 = o.MutedText
            end
            label.TextStrokeTransparency = 1
            Audit.Counters.ContrastFixes += 1
            pushReport("contrast", label, "Raised text contrast for readability")
            return true
        end

        local function repairText(label)
            if not (label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("TextBox")) then
                return false
            end
            local changed = false
            if label.TextXAlignment == Enum.TextXAlignment.Center and label.AbsoluteSize.X > 96 then
                local parentName = label.Parent and label.Parent.Name:lower() or ""
                if parentName:find("module") or parentName:find("row") or parentName:find("setting") or parentName:find("button") then
                    label.TextXAlignment = Enum.TextXAlignment.Left
                    changed = true
                end
            end
            if label.TextTruncate ~= Enum.TextTruncate.AtEnd then
                label.TextTruncate = Enum.TextTruncate.AtEnd
                changed = true
            end
            if label.AbsoluteSize.X > 0 and label.AbsoluteSize.Y > 0 then
                Layout.fitText(label, {
                    MinSize = d.isMobile and 10 or 9,
                    MaxSize = math.max(label.TextSize, d.isMobile and 12 or 11),
                    Padding = 8,
                })
            end
            if changed then
                Audit.Counters.TextFixes += 1
                pushReport("text", label, "Repaired text alignment/truncation")
            end
            repairContrast(label)
            return changed
        end

        local function repairViewport(instance)
            if not isVisibleGui(instance) or not B then
                return false
            end
            local before = instance.Position
            Layout.keepInsideViewport(instance, d.isMobile and 6 or 8)
            if instance.Position ~= before then
                Audit.Counters.ViewportFixes += 1
                pushReport("viewport", instance, "Clamped object into viewport")
                return true
            end
            return false
        end

        local function canMove(instance)
            if not isVisibleGui(instance) then
                return false
            end
            if instance.AnchorPoint.X ~= 0 or instance.AnchorPoint.Y ~= 0 then
                return false
            end
            if instance.Position.X.Scale ~= 0 or instance.Position.Y.Scale ~= 0 then
                return false
            end
            local name = instance.Name:lower()
            if name:find("drag") or name:find("resize") or name:find("shadow") then
                return false
            end
            return true
        end

        local function repairSiblingOverlaps(parent)
            if not (typeof(parent) == "Instance" and parent:IsA("GuiObject")) then
                return 0
            end
            local children = {}
            for _, child in ipairs(parent:GetChildren()) do
                if canMove(child) then
                    children[#children + 1] = child
                end
            end
            table.sort(children, function(left, right)
                if left.LayoutOrder == right.LayoutOrder then
                    return left.AbsolutePosition.Y < right.AbsolutePosition.Y
                end
                return left.LayoutOrder < right.LayoutOrder
            end)

            local fixes = 0
            for index = 2, #children do
                local previous = children[index - 1]
                local current = children[index]
                local previousRect = rectOf(previous)
                local currentRect = rectOf(current)
                if intersects(previousRect, currentRect, 2) then
                    local delta = (previousRect.Bottom - currentRect.Top) + 6
                    current.Position = UDim2.fromOffset(current.Position.X.Offset, current.Position.Y.Offset + delta)
                    fixes += 1
                    Audit.Counters.OverlapFixes += 1
                    pushReport("overlap", current, "Separated overlapping sibling controls")
                end
            end
            return fixes
        end

        local function repairButton(button)
            if not (button:IsA("TextButton") or button:IsA("ImageButton")) then
                return false
            end
            button.AutoButtonColor = false
            Layout.ensureHitbox(button, d.isMobile and 44 or 32, d.isMobile and 40 or 30)
            if not button:GetAttribute("BadWarsAuditMotion") then
                button:SetAttribute("BadWarsAuditMotion", true)
                Motion.hover(button, {
                    Scale = 1.003,
                })
                Motion.press(button, {
                    DownScale = 0.992,
                })
            else
                Audit.Counters.MotionSkips += 1
            end
            return true
        end

        local function repairMetric(instance)
            if not (typeof(instance) == "Instance" and instance:IsA("GuiObject")) then
                return false
            end
            local name = instance.Name
            local title = instance:FindFirstChild("WidgetTitle")
            local titleText = title and title:IsA("TextLabel") and title.Text or ""
            local metric = ({
                FPS = true,
                Ping = true,
                Memory = true,
                Clock = true,
                Speedmeter = true,
            })[name] or ({
                FPS = true,
                PING = true,
                MEMORY = true,
                CLOCK = true,
                SPEEDMETER = true,
            })[titleText]
            if not metric then
                return false
            end
            instance.Visible = true
            instance.Active = true
            instance.BackgroundTransparency = math.min(instance.BackgroundTransparency, 0.06)
            instance.ClipsDescendants = false
            for _, child in ipairs(instance:GetChildren()) do
                if child:IsA("TextLabel") and not child:GetAttribute("PremiumWidgetInternal") then
                    child.Visible = true
                    child.TextTransparency = 0
                    child.BackgroundTransparency = 1
                    child.TextColor3 = o.TextStrong
                    child.TextStrokeTransparency = 1
                    child.Position = UDim2.fromOffset(10, 12)
                    child.Size = UDim2.new(1, -20, 1, -14)
                    child.TextXAlignment = Enum.TextXAlignment.Left
                    child.TextYAlignment = Enum.TextYAlignment.Center
                    child.TextTruncate = Enum.TextTruncate.AtEnd
                end
            end
            return true
        end

        function Audit.Scan(root)
            if not Audit.Enabled then
                return Audit.Counters
            end
            local stamp = now()
            if stamp - Audit.LastRun < Audit.MinimumInterval then
                return Audit.Counters
            end
            Audit.LastRun = stamp
            Audit.Counters.Runs += 1
            root = root or B
            if not root then
                return Audit.Counters
            end
            local parents = {}
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiObject") then
                    if Recipes and type(Recipes.Apply) == "function" then
                        pcall(Recipes.Apply, descendant)
                    end
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox") then
                        repairText(descendant)
                    end
                    if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                        repairButton(descendant)
                    end
                    repairMetric(descendant)
                    local parent = descendant.Parent
                    if parent and parent:IsA("GuiObject") then
                        parents[parent] = true
                    end
                end
            end
            for parent in pairs(parents) do
                repairSiblingOverlaps(parent)
            end
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiObject") then
                    local name = descendant.Name:lower()
                    if name:find("window") or name:find("notification") or name:find("prompt") or name:find("tooltip") then
                        repairViewport(descendant)
                    end
                end
            end
            return Audit.Counters
        end

        function Audit.Repair(instance)
            if typeof(instance) ~= "Instance" then
                return false
            end
            if instance:IsA("GuiObject") then
                if Recipes and type(Recipes.Apply) == "function" then
                    pcall(Recipes.Apply, instance)
                end
                repairMetric(instance)
                repairViewport(instance)
                if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
                    repairText(instance)
                end
                if instance:IsA("TextButton") or instance:IsA("ImageButton") then
                    repairButton(instance)
                end
            end
            for _, descendant in ipairs(instance:GetDescendants()) do
                Audit.Repair(descendant)
            end
            return true
        end

        function Audit.Snapshot(root)
            root = root or B
            local snapshot = {
                Windows = 0,
                Buttons = 0,
                Labels = 0,
                Scrollers = 0,
                Notifications = 0,
                Metrics = 0,
                InvisibleText = 0,
                TinyButtons = 0,
            }
            if not root then
                return snapshot
            end
            for _, descendant in ipairs(root:GetDescendants()) do
                if descendant:IsA("GuiObject") then
                    local lowerName = descendant.Name:lower()
                    if lowerName:find("window") then
                        snapshot.Windows += 1
                    end
                    if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                        snapshot.Buttons += 1
                        if descendant.AbsoluteSize.X < 28 or descendant.AbsoluteSize.Y < 28 then
                            snapshot.TinyButtons += 1
                        end
                    end
                    if descendant:IsA("TextLabel") or descendant:IsA("TextBox") then
                        snapshot.Labels += 1
                        if descendant.Visible and descendant.TextTransparency >= 0.98 then
                            snapshot.InvisibleText += 1
                        end
                    end
                    if descendant:IsA("ScrollingFrame") then
                        snapshot.Scrollers += 1
                    end
                    if descendant.Name == "Notification" then
                        snapshot.Notifications += 1
                    end
                    if ({
                        FPS = true,
                        Ping = true,
                        Memory = true,
                        Clock = true,
                        Speedmeter = true,
                    })[descendant.Name] then
                        snapshot.Metrics += 1
                    end
                end
            end
            return snapshot
        end

        function Audit.Describe()
            local snapshot = Audit.Snapshot(B)
            return {
                Snapshot = snapshot,
                Counters = table.clone(Audit.Counters),
                RecentReports = table.clone(Audit.Reports),
            }
        end

        function Audit.SetEnabled(enabled)
            Audit.Enabled = enabled == true
            return Audit.Enabled
        end

        d.FusionAudit = Audit
        d.Libraries.FusionAudit = Audit

        task.defer(function()
            if not B or not B.Parent then
                return
            end
            Audit.Scan(B)
            d:Clean(B.DescendantAdded:Connect(function(descendant)
                task.defer(function()
                    if descendant and descendant.Parent then
                        Audit.Repair(descendant)
                    end
                end)
            end))
            local pending = false
            d:Clean(B:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                if pending then
                    return
                end
                pending = true
                task.delay(0.12, function()
                    pending = false
                    if B and B.Parent then
                        Audit.Scan(B)
                    end
                end)
            end))
        end)
    end
end)()
-- BADWARS_FUSION_AUDIT_REPAIR_V21_END

return d
end)(...)
