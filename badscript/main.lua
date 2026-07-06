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
-- BadWars Main v20.0 - Atlas UI pipeline
repeat
    task.wait()
until game:IsLoaded()
if shared.Bad then
    pcall(function()
        shared.Bad:Uninject()
    end)
end

local os_clock = os.clock
local pipelineStart = os_clock()
local collectgarbage = collectgarbage
local __mainwarn = warn
local MAIN_VERBOSE_LOGS = false
local function mwarn(...)
    if MAIN_VERBOSE_LOGS then
        __mainwarn(...)
    end
end

-- Error tracker
-- Start each injection with a clean diagnostic set so errors from an older
-- failed run do not make a repaired run look broken.
local __rtErrs = {}
shared.__badwars_runtime_errors = __rtErrs
local function recordErr(mod, err)
    table.insert(__rtErrs, { module = tostring(mod), error = tostring(err), time = os_clock() })
end

-- URL configuration (consistent with entry.lua and loader.lua)
local CFG = { repo = "evanbackup1256-ship-it", name = "badwars", branch = "main" }
local function rawUrls(path)
    local repo = CFG.repo .. "/" .. CFG.name
    local p = path:gsub(" ", "%%20")
    local query = "?bwui=v20-atlas-1"
    return {
        "https://github.com/" .. repo .. "/raw/" .. CFG.branch .. "/" .. p .. query,
        "https://raw.githubusercontent.com/" .. repo .. "/" .. CFG.branch .. "/" .. p .. query,
    }
end
-- Safe helpers
local function typeName(v)
    return typeof(v)
end
local function safeStr(v)
    if v == nil then
        return ""
    end
    if type(v) ~= "table" then
        return tostring(v)
    end
    local o, r = pcall(function()
        return table.concat(v, ", ")
    end)
    if o then
        return r
    end
    return "<table>"
end
local function safeConcat(...)
    local r = {}
    for _, p in ipairs({ ... }) do
        table.insert(r, safeStr(p))
    end
    return table.concat(r)
end

-- Feature state: ensures every option has {Enabled, Value, ...}
-- Profile data sometimes stores booleans instead of {Enabled=true}
local function normalize(v)
    if type(v) == "boolean" then
        return { Enabled = v }
    end
    if type(v) ~= "table" then
        return { Enabled = false }
    end
    return v
end
-- Safe option read: option.Value or option.Enabled with fallback
local function optVal(t, key, default)
    if type(t) ~= "table" then
        return default
    end
    local v = t[key]
    if v == nil then
        return default
    end
    return v
end
local function optEnabled(t, default)
    if type(t) ~= "table" then
        return default or false
    end
    if type(t.Enabled) == "boolean" then
        return t.Enabled
    end
    return default or false
end
-- Safe toggle/dropdown read (handles both table and saved boolean state)
local function safeOption(v)
    v = normalize(v)
    if type(v.Enabled) ~= "boolean" then
        v.Enabled = false
    end
    return v
end
-- Safe module reference: Bad.Modules.Fly.Enabled -> check cascade
local function moduleEnabled(modName)
    if not shared.Bad or type(shared.Bad.Modules) ~= "table" then
        return false
    end
    local m = shared.Bad.Modules[modName]
    if type(m) ~= "table" then
        return false
    end
    return optEnabled(m, false)
end

local function ensureRuntimeCategories(api)
    if type(api) ~= "table" then
        return
    end
    api.Categories = type(api.Categories) == "table" and api.Categories or {}
    local function makeToggle(value)
        return { Enabled = value == nil and false or value }
    end
    local function ensureEvent(owner, key)
        if type(owner[key]) ~= "table" or not owner[key].Event or type(owner[key].Fire) ~= "function" then
            owner[key] = Instance.new("BindableEvent")
            if shared.BadwarsLoadingDebug then
                mwarn(
                    "BadWars: [PREFLIGHT] registered missing "
                        .. tostring(owner.Name or "service")
                        .. "."
                        .. key
                        .. " event"
                )
            end
            if type(api.Clean) == "function" then
                pcall(function()
                    api:Clean(owner[key])
                end)
            end
        end
    end
    api.Categories.Main = type(api.Categories.Main) == "table" and api.Categories.Main
        or { Type = "ServiceCategory", Name = "Main", Options = {} }
    api.Categories.Main.Type = api.Categories.Main.Type or "ServiceCategory"
    api.Categories.Main.Name = api.Categories.Main.Name or "Main"
    api.Categories.Main.Options = type(api.Categories.Main.Options) == "table" and api.Categories.Main.Options or {}
    api.Categories.Main.Options["GUI bind indicator"] = normalize(api.Categories.Main.Options["GUI bind indicator"])
    api.Categories.Main.Options["Teams by server"] = normalize(api.Categories.Main.Options["Teams by server"])
    api.Categories.Main.Options["Use team color"] = normalize(api.Categories.Main.Options["Use team color"])

    api.Categories.Friends = type(api.Categories.Friends) == "table" and api.Categories.Friends
        or { Type = "ServiceCategory", Name = "Friends", Options = {}, ListEnabled = {} }
    api.Categories.Friends.Type = api.Categories.Friends.Type or "ServiceCategory"
    api.Categories.Friends.Name = api.Categories.Friends.Name or "Friends"
    api.Categories.Friends.Options = type(api.Categories.Friends.Options) == "table" and api.Categories.Friends.Options
        or {}
    api.Categories.Friends.ListEnabled = type(api.Categories.Friends.ListEnabled) == "table"
            and api.Categories.Friends.ListEnabled
        or {}
    api.Categories.Friends.Options["Use friends"] = normalize(api.Categories.Friends.Options["Use friends"])
    api.Categories.Friends.Options["Recolor visuals"] = normalize(api.Categories.Friends.Options["Recolor visuals"])
    api.Categories.Friends.Options["Friends color"] = type(api.Categories.Friends.Options["Friends color"]) == "table"
            and api.Categories.Friends.Options["Friends color"]
        or { Hue = 1, Sat = 1, Value = 1 }
    ensureEvent(api.Categories.Friends, "Update")
    ensureEvent(api.Categories.Friends, "ColorUpdate")

    api.Categories.Targets = type(api.Categories.Targets) == "table" and api.Categories.Targets
        or { Type = "ServiceCategory", Name = "Targets", Options = {}, ListEnabled = {} }
    api.Categories.Targets.Type = api.Categories.Targets.Type or "ServiceCategory"
    api.Categories.Targets.Name = api.Categories.Targets.Name or "Targets"
    api.Categories.Targets.Options = type(api.Categories.Targets.Options) == "table" and api.Categories.Targets.Options
        or {}
    api.Categories.Targets.ListEnabled = type(api.Categories.Targets.ListEnabled) == "table"
            and api.Categories.Targets.ListEnabled
        or {}
    ensureEvent(api.Categories.Targets, "Update")
end

-- Status & notify
local function setStatus(msg, isErr)
    if shared.BadStatus then
        pcall(function()
            shared.BadStatus(msg, isErr)
        end)
    end
end
local function notify(title, text, dur)
    pcall(function()
        game:GetService("StarterGui")
            :SetCore("SendNotification", { Title = safeStr(title), Text = safeStr(text), Duration = dur or 8 })
    end)
end
local __logHistory = {}
local function logMod(stage, name, elapsed, success, detail)
    local key = safeStr(name) .. "|" .. safeStr(detail)
    if __logHistory[key] then
        __logHistory[key] = __logHistory[key] + 1
        return
    end
    __logHistory[key] = 1
    -- Logging intentionally muted for the premium UX build.
end

-- Download
local _loadstring
pcall(function()
    local g = getgenv
    if type(g) == "function" then
        g = g()
    end
    _loadstring = (g and g.loadstring) or loadstring
end)
if not _loadstring then
    _loadstring = function(s)
        error("loadstring unavailable")
    end
end
isfile = isfile or function(f)
    local s, r = pcall(readfile, f)
    return s and r ~= nil and r ~= ""
end
local nativeDelfileAvailable = type(delfile) == "function"
delfile = delfile or function()
    return false, "delfile unavailable"
end
isfolder = isfolder or function()
    return false
end
makefolder = makefolder or function() end
listfiles = listfiles or function()
    return {}
end
readfile = readfile or function()
    return ""
end
writefile = writefile or function() end
cloneref = cloneref or function(o)
    return o
end
setthreadidentity = setthreadidentity or function() end
local queueTeleport = queue_on_teleport
    or queueonteleport
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)
    or function() end

local BadwarsLoader
local function createCustomSignal(key, delay)
    key = tostring(key or "Unknown")
    delay = delay or 0
    return setmetatable({ __conns = {}, __args = true, __delay = delay, __lastFire = nil }, {
        __index = function(self, k)
            if k == "Event" then
                return self
            end
            if k == "Destroy" then
                return function()
                    for i in pairs(self.__conns or {}) do
                        self.__conns[i] = nil
                    end
                    self.__conns = nil
                end
            end
            return rawget(self, k)
        end,
        __tostring = function()
            return "BADWARS_INTERNAL_EVENT_" .. key
        end,
    })
end
local signalApi = {
    Connect = function(self, func)
        if BadwarsLoader and BadwarsLoader.Unloaded then
            return
        end
        assert(type(func) == "function", "req not met")
        local conn = { func = func, once = false }
        table.insert(self.__conns, conn)
        return {
            Disconnect = function()
                local id = table.find(self.__conns, conn)
                if id then
                    table.remove(self.__conns, id)
                    return true
                end
                return false
            end,
        }
    end,
    Once = function(self, func)
        if BadwarsLoader and BadwarsLoader.Unloaded then
            return
        end
        assert(type(func) == "function", "req not met")
        local conn = { func = func, once = true }
        table.insert(self.__conns, conn)
        return {
            Disconnect = function()
                local id = table.find(self.__conns, conn)
                if id then
                    table.remove(self.__conns, id)
                    return true
                end
                return false
            end,
        }
    end,
    Fire = function(self, ...)
        if BadwarsLoader and BadwarsLoader.Unloaded then
            return
        end
        if type(self.__conns) ~= "table" then
            return
        end
        local args = { ... }
        local bypass = not self.__args and args[1]
        if not bypass and self.__lastFire and tick() - self.__lastFire < self.__delay then
            return
        end
        self.__lastFire = tick()
        local remove = {}
        for i, conn in ipairs(self.__conns) do
            if shared.BadDiagnostics then shared.BadDiagnostics:Capture(conn.func,{subsystem='Signal',module=key,stage='signal-callback'},unpack(args)) else pcall(conn.func,unpack(args)) end
            if conn.once then
                table.insert(remove, i)
            end
        end
        for i = #remove, 1, -1 do
            table.remove(self.__conns, remove[i])
        end
        return self
    end,
    SetCooldown = function(self, val)
        self.__delay = val or 0
        return self
    end,
    ArgCheck = function(self, val)
        if val == nil then
            val = not self.__args
        end
        self.__args = val
        return self
    end,
}
local function installBadWarsLoaderShim()
    BadwarsLoader = setmetatable({
        Unloaded = false,
        Services = setmetatable({}, {
            __index = function(self, key)
                key = tostring(key)
                if key == "InputService" then
                    key = "UserInputService"
                end
                local ok, svc = pcall(function()
                    return game:GetService(key)
                end)
                if not ok then
                    return nil
                end
                local okClone, cloned = pcall(cloneref, svc)
                if okClone then
                    svc = cloned
                end
                rawset(self, key, svc)
                return svc
            end,
        }),
        createCustomSignal = function(_, key, delay)
            local sig = createCustomSignal(key, delay)
            for k, v in pairs(signalApi) do
                sig[k] = v
            end
            return sig
        end,
        setupDecoratedCustomSignal = function(self, id)
            id = tostring(id)
            return function(sigName)
                return self:createCustomSignal(id .. "_" .. tostring(sigName))
            end
        end,
        BadwarsEvents = setmetatable({}, {
            __index = function(self, key)
                local sig = BadwarsLoader:createCustomSignal(key)
                rawset(self, key, sig)
                return sig
            end,
        }),
        wrap = function(self, func, decorator)
            if not func then
                return
            end
            if type(func) ~= "function" then
                return func
            end
            return function(...)
                local ok, res = xpcall(func, function(err) local d=shared.BadDiagnostics return d and d:Traceback(err,3) or ((debug and debug.traceback) and debug.traceback(tostring(err),3) or tostring(err)) end, ...)
                if not ok then
                    local report = { err = res }
                    if type(decorator) == "table" then
                        for k, v in pairs(decorator) do
                            report[k] = v
                        end
                    end
                    self:report(report)
                end
                return ok and res
            end
        end,
        report = function(_, report)
            mwarn(
                "BadWars: [UI] "
                    .. safeStr(report and (report.name or report.type) or "Error")
                    .. " "
                    .. safeStr(report and report.err or "")
            )
        end,
        throw = function(self, err)
            self:report({ name = "Badwars Error", err = err })
        end,
    }, {
        __index = function(_, key)
            error("BadwarsLoader: Invalid key " .. tostring(key) .. "!", 0)
        end,
    })
    shared.BadWarsLoader = BadwarsLoader
    shared.BadwarsLoader = BadwarsLoader
end

local function callWithTimeout(callback, timeoutSeconds)
    local finished = false
    local success = false
    local result
    local worker = task.spawn(function()
        if shared.BadDiagnostics then success,result=shared.BadDiagnostics:Capture(callback,{subsystem='TimeoutWorker',stage='http-timeout'}) else success,result=pcall(callback) end
        finished = true
    end)

    local deadline = os.clock() + (tonumber(timeoutSeconds) or 12)
    repeat
        task.wait(0.05)
    until finished or os.clock() >= deadline

    if not finished then
        pcall(task.cancel, worker)
        return false, "request timed out"
    end

    return success, result
end

local function httpGetMulti(urls)
    for _, url in ipairs(urls) do
        local fn = (game and game.HttpGet)
        if type(fn) ~= "function" then
            local env = getgenv and type(getgenv) == "function" and getgenv()
            fn = env and env.HttpGet
        end
        if type(fn) == "function" then
            local ok, res = callWithTimeout(function()
                return fn(game, url, true)
            end, 12)
            if ok and type(res) == "string" and #res > 0 then
                return res
            end
        end
        local ok, res = callWithTimeout(function()
            return cloneref(game:GetService("HttpService")):GetAsync(url, true)
        end, 12)
        if ok and type(res) == "string" and #res > 0 then
            return res
        end
    end
    return nil
end

local function httpGet(url)
    return httpGetMulti({ url })
end
HttpGet = httpGet

local function isNotFoundBody(body)
    if type(body) ~= "string" then
        return false
    end
    local trimmed = body:match("^%s*(.-)%s*$")
    return trimmed == "404: Not Found"
        or trimmed == '{"message":"Not Found"}'
        or (#trimmed < 200 and trimmed:find('"message"%s*:%s*"Not Found"') ~= nil)
end

local function isStaleGuiCache(path, body)
    if path ~= "badscript/guis/new/gui.lua" then
        return false
    end

    if type(body) ~= "string" or body == "" then
        return true
    end

    return body:find("BADWARS_UI_V20_ATLAS", 1, true) == nil
        or body:find("BADWARS_UI_V20_ATLAS_RUNTIME_BEGIN", 1, true) == nil
        or body:find("Version = \"20.0\"", 1, true) == nil
end
local function isStaleMotionCache(path, body)
    if path ~= "badscript/libraries/spr.lua" then
        return false
    end
    if type(body) ~= "string" or body == "" then
        return true
    end
    return not (
        body:find("Spring-driven motion library", 1, true) ~= nil
        and body:find("function spr.target", 1, true) ~= nil
        and body:find("function spr.stop", 1, true) ~= nil
    )
end

local function downloadFile(path)
    if not HttpGet then
        return nil, "HttpGet nil"
    end
    local cached = isfile(path) and readfile(path)
    if isStaleGuiCache(path, cached) or isStaleMotionCache(path, cached) then
        pcall(function()
            if isfile(path) then
                delfile(path)
            end
        end)
        cached = nil
    end
    if type(cached) == "string" and #cached > 0 then
        return cached
    end
    setStatus("downloading required files")
    local urls = rawUrls(path)
    local res = httpGetMulti(urls)
    if type(res) ~= "string" or #res == 0 then
        return nil, "ERROR empty file: empty response from " .. urls[1]
    end
    if isNotFoundBody(res) then
        return nil, "FILE NOT FOUND: " .. urls[1]
    end
    if path:find(".lua") then
        res = "-- BadWars by usingINales\n" .. res
    end
    pcall(function()
        writefile(path, res)
    end)
    return res
end

local function splitLines(t)
    local result = {}
    for line in tostring(t):gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:find("^#") then
            table.insert(result, line)
        end
    end
    return result
end

-- Supports both newline manifests and a single line containing multiple paths.
-- Paths may contain spaces, so splitting on whitespace is not safe.
local function splitManifest(t)
    local result = {}
    for path in tostring(t):gmatch("([^\r\n]-%.lua)") do
        path = path:match("^%s*(.-)%s*$")
        if path ~= "" and not path:find("^#") then
            table.insert(result, path)
        end
    end
    if #result == 0 then
        return splitLines(t)
    end
    return result
end

local function replacePlainOnce(source, needle, replacement)
    local first, last = source:find(needle, 1, true)
    if not first then
        return source, 0
    end
    return source:sub(1, first - 1) .. replacement .. source:sub(last + 1), 1
end

local function repairKnownSourceDefects(path, source)
    if type(source) ~= "string" then
        return source, 0
    end
    local repaired = source
    local fixes = 0

    -- The current universal base contains an accidental literal newline inside
    -- the server-hop notification string, which prevents the whole bundle from compiling.
    if path == "badscript/games/universal - base/base.lua" then
        local changed
        repaired, changed = replacePlainOnce(
            repaired,
            "Failed to grab servers.\n('..errDetail..')",
            "Failed to grab servers.\\n('..errDetail..')"
        )
        fixes += changed

        if changed == 0 then
            repaired, changed = replacePlainOnce(
                repaired,
                "Failed to grab servers.\r\n('..errDetail..')",
                "Failed to grab servers.\\n('..errDetail..')"
            )
            fixes += changed
        end
    end

    if path:find("badscript/games/bedwars/6872274481 %- game/", 1, false) then
        local changed

        if path:sub(-21) == "Utility/Scaffold.lua" then
            repaired, changed = replacePlainOnce(
                repaired,
                "else Label = nil end",
                "else label = nil end"
            )
            fixes += changed

            repaired, changed = replacePlainOnce(
                repaired,
                "else label:Destroy() label = nil end",
                "else if label then label:Destroy() end label = nil end"
            )
            fixes += changed

            repaired, changed = replacePlainOnce(
                repaired,
                "if store.hand.toolType == 'block' then",
                "if store.hand and store.hand.toolType == 'block' and store.hand.tool then"
            )
            fixes += changed
        end

        if path:sub(-27) == "Utility/ShopTierBypass.lua" then
            repaired, changed = replacePlainOnce(
                repaired,
                "for _, v in bedwars.Shop.ShopItems do",
                "for _, v in ((bedwars.Shop and bedwars.Shop.ShopItems) or {}) do"
            )
            fixes += changed
        end

        repaired, changed = repaired:gsub(
            "([%w_]+):Destroy%(%)(%s+)([%w_]+)%s*=%s*nil",
            "if %1 then %1:Destroy() end%2%3 = nil"
        )
        fixes += changed

        repaired, changed = repaired:gsub(
            "physicsService:SetPartCollisionGroup%(([%w_%.%[%]'\\\"]+),%s*([%w_%.%[%]'\\\"]+)%)",
            "%1.CollisionGroup = %2"
        )
        fixes += changed
    end

    if fixes > 0 then
        mwarn("BadWars: [SOURCE REPAIR] " .. tostring(path) .. " repaired " .. tostring(fixes) .. " known defect(s)")
    end
    return repaired, fixes
end

local __repoTree
local function repoTreeFiles(prefix)
    if type(prefix) ~= "string" or prefix == "" then
        return {}
    end
    if not __repoTree then
        local repo = CFG.repo .. "/" .. CFG.name
        local url = "https://api.github.com/repos/" .. repo .. "/git/trees/" .. CFG.branch .. "?recursive=1"
        local body = httpGetMulti({ url })
        local ok, res = pcall(function()
            return cloneref(game:GetService("HttpService")):JSONDecode(body or "")
        end)
        __repoTree = ok and type(res) == "table" and type(res.tree) == "table" and res.tree or {}
    end
    local files = {}
    local normalizedPrefix = prefix:gsub("\\", "/")
    for _, item in ipairs(__repoTree) do
        local path = type(item) == "table" and tostring(item.path or "") or ""
        if
            type(item) == "table"
            and item.type == "blob"
            and path:find(normalizedPrefix, 1, true) == 1
            and path:sub(-4) == ".lua"
        then
            table.insert(files, path)
        end
    end
    table.sort(files, function(a, b)
        if a:sub(-8) == "base.lua" then
            return true
        end
        if b:sub(-8) == "base.lua" then
            return false
        end
        return a < b
    end)
    return files
end

-- Universal module bundle loader (tries prebuilt first, then builds dynamically)
local function loadPrebuiltBundle(name)
    if name ~= "universal" then
        return nil
    end
    local bundlePath = "badscript/games/universal - base/bundle.lua"
    if isfile(bundlePath) then
        local bundled = readfile(bundlePath)
        if type(bundled) == "string" and bundled ~= "" then
            return bundled, "prebuilt"
        end
    end
    return nil, "not found"
end

-- Forward-declared so compatibility callers resolve the local builder,
-- rather than an accidental global named buildBundle.
local buildBundle

local function loadLuaBundle(name, basePath, manifestPath)
    return buildBundle(name, basePath, manifestPath)
end

-- Universal module bundle builder. Each feature file is syntax-checked before
-- insertion so one malformed module cannot make every category empty.
buildBundle = function(name, basePath, manifestPath)
    local baseCode = downloadFile(basePath)
    if type(baseCode) ~= "string" or baseCode == "" then
        return nil, "missing base"
    end
    baseCode = repairKnownSourceDefects(basePath, baseCode)
    baseCode = baseCode:gsub("%s*return%s+[^%c]+%s*$", "")
    local parts = { baseCode }
    local manifest = downloadFile(manifestPath)
    local preamble = {
        "",
        "local __m_ok={}",
        "local __m_meta={}",
        "local __m_path_by_name={}",
        "local function __preflight_m(idx,path,kind,category,moduleName,hasInit,hasUpdate)",
        "  local issues={}",
        '  kind=type(kind)=="string" and kind or "Module"',
        '  if kind~="Overlay" and (type(category)~="string" or category=="") then table.insert(issues,"category missing") end',
        '  if type(moduleName)~="string" or moduleName=="" then table.insert(issues,"name missing") end',
        '  if hasInit==nil then table.insert(issues,"enabled/init state unknown") end',
        '  if hasUpdate==nil then table.insert(issues,"update contract unknown") end',
        "  __m_meta[idx]={path=path,kind=kind,category=category,name=moduleName,hasInit=hasInit,hasUpdate=hasUpdate,issues=issues}",
        "  __m_path_by_name[moduleName]=path",
        "  if #issues>0 and shared then shared.__badwars_preflight_issues=shared.__badwars_preflight_issues or {}; table.insert(shared.__badwars_preflight_issues,{path=path,name=moduleName,issues=issues}) end",
        "end",
        "local function __postflight_m()",
        "  local bad=shared and shared.Bad",
        '  if type(bad)~="table" then return end',
        "  for _,meta in pairs(__m_meta) do",
        "    local mod",
        '    if meta.kind=="Overlay" then',
        "      mod=bad.Overlays and bad.Overlays[meta.name]",
        '    elseif meta.kind=="Legit" then',
        "      mod=bad.Legit and bad.Legit.Modules and bad.Legit.Modules[meta.name]",
        "    else",
        "      mod=bad.Modules and bad.Modules[meta.name]",
        "    end",
        "    local compat=bad.BedWarsCompatibility",
        "    if mod and type(compat)=='table' and type(compat.Decorate)=='function' then pcall(compat.Decorate,compat,mod,meta) end",
        "    local issues={}",
        '    if not mod then table.insert(issues,"module not registered")',
        "    else",
        '      if meta.kind~="Overlay" and (type(mod.Category)~="string" or mod.Category=="") then table.insert(issues,"category missing") end',
        '      local regName=meta.kind=="Overlay" and (mod.Name or meta.name) or mod.Name',
        '      if type(regName)~="string" or regName=="" then table.insert(issues,"name missing") end',
        "      local enabled,toggle",
        '      if meta.kind=="Overlay" then',
        "        enabled=mod.Button and mod.Button.Enabled",
        "        toggle=mod.Button and mod.Button.Toggle",
        "      else",
        "        enabled=mod.Enabled",
        "        toggle=mod.Toggle",
        "      end",
        '      if type(enabled)~="boolean" then table.insert(issues,"enabled state invalid") end',
        '      if type(toggle)~="function" then table.insert(issues,"init/toggle function missing") end',
        '      if type(mod.Options)~="table" then table.insert(issues,"config/options invalid") end',
        '      if meta.hasUpdate==false then table.insert(issues,"required update function/event missing") end',
        "    end",
        "    if #issues>0 and shared then shared.__badwars_preflight_issues=shared.__badwars_preflight_issues or {}; table.insert(shared.__badwars_preflight_issues,{path=meta.path,name=meta.name,issues=issues}) end",
        "  end",
        "end",
        "local function __run_m(idx,name,fn)",
        "  local bad=shared and shared.Bad",
        "  local beforeModules={} local beforeLegit={}",
        "  if bad and bad.Modules then for key in pairs(bad.Modules) do beforeModules[key]=true end end",
        "  if bad and bad.Legit and bad.Legit.Modules then for key in pairs(bad.Legit.Modules) do beforeLegit[key]=true end end",
        "  local ok,err=pcall(fn)",
        "  if not ok then",
        "    local meta=__m_meta[idx]",
        '    local label=meta and ((meta.name or "?").." @ "..(meta.path or name)) or name',
        "    if bad and bad.Modules then for key,mod in pairs(bad.Modules) do if not beforeModules[key] then pcall(function() if mod.Object then mod.Object:Destroy() end if mod.Children then mod.Children:Destroy() end end); bad.Modules[key]=nil end end end",
        "    if bad and bad.Legit and bad.Legit.Modules then for key,mod in pairs(bad.Legit.Modules) do if not beforeLegit[key] then pcall(function() if mod.Object then mod.Object:Destroy() end if mod.Children then mod.Children:Destroy() end end); bad.Legit.Modules[key]=nil end end end",
        "    if shared then shared.__badwars_runtime_errors=shared.__badwars_runtime_errors or {}; table.insert(shared.__badwars_runtime_errors,{module=label,error=tostring(err),path=meta and meta.path,time=os.clock()}) end",
        "    local compat=bad and bad.BedWarsCompatibility",
        "    if type(compat)=='table' and type(compat.RecordFailure)=='function' then pcall(compat.RecordFailure,compat,meta and meta.name or name,meta and meta.path or name,err) end",
        "  end",
        "  __m_ok[idx]=ok",
        "end",
        "",
    }
    table.insert(parts, table.concat(preamble, "\n"))
    local loaded = 0
    local skipped = 0
    local mi = 1
    local manifestFiles = type(manifest) == "string" and splitManifest(manifest)
        or repoTreeFiles((basePath:match("^(.*[/\\])base%.lua$") or ""):gsub("\\", "/"))
    if type(manifestFiles) == "table" then
        for _, mp in ipairs(manifestFiles) do
            if mp ~= basePath then
                setStatus("loading core modules")
                local code = downloadFile(mp)
                if type(code) == "string" and code ~= "" then
                    code = repairKnownSourceDefects(mp, code)
                    local syntaxProbe, syntaxErr =
                        _loadstring("return function()\n" .. code .. "\nend", "module-preflight:" .. tostring(mp))
                    if not syntaxProbe then
                        skipped += 1
                        local detail = "syntax error: " .. tostring(syntaxErr)
                        mwarn("BadWars: [MODULE SKIP] " .. tostring(mp) .. " - " .. detail)
                        recordErr(mp, detail)
                    else
                        local isOverlay = code:match("Bad%s*:%s*CreateOverlay%s*%(") ~= nil
                        local isLegit = code:match("Bad%.Legit%s*:%s*CreateModule%s*%(") ~= nil
                        local kind = isOverlay and "Overlay" or (isLegit and "Legit" or "Module")
                        local category = isOverlay and "Overlays"
                            or code:match("Bad%.Categories%.([%w_]+)%s*:%s*CreateModule%s*%(")
                            or (isLegit and "Legit")
                            or ""
                        local moduleName = code:match("Name%s*=%s*'([^']+)'")
                            or code:match('Name%s*=%s*"([^"]+)"')
                            or mp:match("([^/\\]+)%.lua$")
                            or mp
                        local hasInit = code:match("CreateModule%s*%(") ~= nil or isOverlay
                        local requiresUpdate = code:match("%.Update") ~= nil
                        local hasUpdate = not requiresUpdate
                            or code:match("Update%s*=") ~= nil
                            or code:find("BindableEvent", 1, true) ~= nil

                        local sourceRisks = {}
                        local riskPatterns = {
                            {"debug mutation", "debug%.setup"},
                            {"fixed debug constants", "debug%.getconstant"},
                            {"raw controller access", "bedwars%.[%w_]+[:%.]"},
                            {"raw store access", "store%.[%w_]+"},
                            {"manual module loop", "repeat.-until%s+not%s+[%w_]+%.Enabled"},
                            {"direct destroy", ":[Dd]estroy%(%).-[Nn]il"},
                        }
                        for _, risk in ipairs(riskPatterns) do
                            if code:match(risk[2]) then
                                table.insert(sourceRisks, risk[1])
                            end
                        end
                        shared.__badwars_static_audit = shared.__badwars_static_audit or {}
                        shared.__badwars_static_audit[moduleName] = {
                            path = mp,
                            category = category,
                            kind = kind,
                            bytes = #code,
                            risks = sourceRisks,
                        }

                        table.insert(
                            parts,
                            "\n__preflight_m("
                                .. tostring(mi)
                                .. ","
                                .. string.format("%q", mp)
                                .. ","
                                .. string.format("%q", kind)
                                .. ","
                                .. string.format("%q", category)
                                .. ","
                                .. string.format("%q", moduleName)
                                .. ","
                                .. tostring(hasInit)
                                .. ","
                                .. tostring(hasUpdate)
                                .. ")"
                        )
                        table.insert(
                            parts,
                            "\n-- module "
                                .. tostring(mi)
                                .. ": "
                                .. mp
                                .. "\n__run_m("
                                .. tostring(mi)
                                .. ","
                                .. string.format("%q", mp)
                                .. ",function()\n"
                                .. code
                                .. "\nend)"
                        )
                        loaded += 1
                        mi += 1
                    end
                else
                    skipped += 1
                    local detail = "download returned no source"
                    mwarn("BadWars: [MODULE SKIP] " .. tostring(mp) .. " - " .. detail)
                    recordErr(mp, detail)
                end
            end
        end
    end
    setStatus(
        "bundled "
            .. tostring(loaded)
            .. " "
            .. tostring(name)
            .. " modules"
            .. (skipped > 0 and " (" .. tostring(skipped) .. " skipped)" or "")
    )
    if loaded == 0 then
        return nil, "bundle contains zero valid modules"
    end
    local summary = '\n__postflight_m()\nlocal __ok=0;local __fail=0\nfor _,v in ipairs(__m_ok) do if v then __ok=__ok+1 else __fail=__fail+1 end end\nif shared then shared.__badwars_bundle_summary={name='
        .. string.format("%q", tostring(name))
        .. ',ok=__ok,fail=__fail} end'
    table.insert(parts, summary)
    local bundle = table.concat(parts, "\n")
    local compileProbe, compileErr = _loadstring(bundle, "bundle-preflight:" .. tostring(name))
    if not compileProbe then
        return nil, "bundle compile failed: " .. tostring(compileErr)
    end
    return bundle, "built " .. tostring(loaded) .. " module(s), skipped " .. tostring(skipped)
end

-- Game module path map
local gameModulePaths = {
    [606849621] = "badscript/games/jailbreak/606849621 - main/base.lua",
    [893973440] = "badscript/games/893973440 - flee the facility/base.lua",
    [6872265039] = "badscript/games/bedwars/6872265039 - lobby/base.lua",
    [6872274481] = "badscript/games/bedwars/6872274481 - game/base.lua",
    [8444591321] = "badscript/games/bedwars/8444591321 - mega.lua",
    [8560631822] = "badscript/games/bedwars/8560631822 - micro.lua",
    [77790193039862] = "badscript/games/1.8arena/77790193039862 - game/base.lua",
    [80041634734121] = "badscript/games/1.8arena/80041634734121 - duel.lua",
    [139566161526375] = "badscript/games/bridge duel/139566161526375 - game/base.lua",
    [16483433878] = "badscript/games/blocktales/16483433878 - blocktales/base.lua",
    [5938036553] = "badscript/games/frontlines/5938036553 - game/base.lua",
    [155615604] = "badscript/games/prison life/155615604 - main/base.lua",
    [115875349872417] = "badscript/games/redliner/115875349872417 - game/base.lua",
    [8768229691] = "badscript/games/skywars voxel/8768229691 - skywars game/base.lua",
    [8542259458] = "badscript/games/skywars voxel/8542259458 - skywars lobby.lua",
}

local function resolveGameModulePath(placeId)
    return gameModulePaths[tonumber(placeId)] or ("badscript/games/" .. tostring(placeId) .. ".lua")
end

local function gamePath(placeId)
    return resolveGameModulePath(placeId)
end

local function runGameMod(path, label)
    setStatus("loading game module: " .. tostring(path))
    local start = os_clock()
    local manifest = path:match("^(.*[/\\])base%.lua$")
    manifest = manifest and (manifest .. "files.txt") or nil
    local code
    if manifest then
        local bundled, bundleErr = buildBundle("game", path, manifest)
        code = type(bundled) == "string" and bundled or nil
        if not code and bundleErr then
            mwarn("BadWars: game bundle unavailable for " .. tostring(path) .. ": " .. tostring(bundleErr))
        end
    end
    code = code or downloadFile(path)
    if type(code) ~= "string" or code == "" then
        return false, "download failed"
    end
    local fn, err = _loadstring(code, tostring(game.PlaceId))
    if not fn then
        return false, err or "compile failed"
    end
    local ok, runErr = xpcall(fn,function(err) local d=shared.BadDiagnostics return d and d:Traceback(err,2) or ((debug and debug.traceback) and debug.traceback(tostring(err),2) or tostring(err)) end)
    local el = os_clock() - start
    if not ok then
        logMod("Game", path, el, false, runErr)
        recordErr(path, runErr)
        return false, runErr
    end
    logMod("Game", path, el, true)
    return true
end

local function countEntries(value)
    local total = 0
    if type(value) ~= "table" then
        return total
    end
    for _, entry in pairs(value) do
        if type(entry) == "table" then
            total += 1
        end
    end
    return total
end

local function registrationSnapshot(api)
    api = type(api) == "table" and api or {}
    local modules = countEntries(api.Modules)
    local overlays = countEntries(api.Overlays)
    local legit = countEntries(api.Legit and api.Legit.Modules)
    return {
        modules = modules,
        overlays = overlays,
        legit = legit,
        total = modules + overlays + legit,
    }
end

local function registrationDelta(before, after)
    return {
        modules = math.max(0, (after.modules or 0) - (before.modules or 0)),
        overlays = math.max(0, (after.overlays or 0) - (before.overlays or 0)),
        legit = math.max(0, (after.legit or 0) - (before.legit or 0)),
        total = math.max(0, (after.total or 0) - (before.total or 0)),
    }
end

local function refreshOriginalCategories()
    local B = shared.Bad
    if type(B) ~= "table" or type(B.Categories) ~= "table" then
        return
    end
    for _, category in pairs(B.Categories) do
        if type(category) == "table" and category.Type == "Category" and type(category.Expand) == "function" then
            local expanded = category.Expanded == true
            if expanded then
                pcall(function()
                    category:Expand(false)
                    category:Expand(true)
                end)
            end
        end
    end
end

local function repairModuleCategories(stage)
    local B = shared.Bad
    if type(B) ~= "table" then
        return
    end
    if type(B.RepairModuleCategories) == "function" then
        local ok, err = pcall(function()
            B:RepairModuleCategories()
        end)
        if not ok then
            mwarn("BadWars: [CATEGORY REPAIR] " .. tostring(stage) .. " failed: " .. tostring(err))
        end
    end
    local counts = {}
    if type(B.Categories) == "table" and type(B.Modules) == "table" then
        for name, cat in pairs(B.Categories) do
            if type(cat) == "table" and (cat.Type == "Category" or cat.Type == "ModuleCategory") then
                counts[name] = 0
            end
        end
        for _, mod in pairs(B.Modules) do
            if type(mod) == "table" and counts[mod.Category] ~= nil then
                counts[mod.Category] += 1
            end
        end
        for name, count in pairs(counts) do
            mwarn(
                "BadWars: [CATEGORY] "
                    .. tostring(name)
                    .. " modules registered="
                    .. tostring(count)
                    .. " stage="
                    .. tostring(stage)
            )
        end
    end
    refreshOriginalCategories()
    pcall(function()
        if type(B.SortAllModules) == "function" then
            B:SortAllModules()
        end
    end)
end

local function runUniversalCandidate(code, source)
    local before = registrationSnapshot(shared.Bad)
    if type(code) ~= "string" or code == "" then
        return false, "empty universal source", registrationDelta(before, before)
    end

    local fn, compileErr = _loadstring(code, "universal:" .. tostring(source))
    if not fn then
        return false, "compile failure: " .. tostring(compileErr), registrationDelta(before, before)
    end

    local trace = debug and debug.traceback or function(err)
        return tostring(err)
    end
    local ok, runErr = xpcall(fn, trace)
    local after = registrationSnapshot(shared.Bad)
    local delta = registrationDelta(before, after)

    if not ok then
        return false, "runtime failure: " .. tostring(runErr), delta
    end
    if delta.total <= 0 then
        return false, "bundle executed but registered zero modules", delta
    end
    return true,
        "registered "
            .. tostring(delta.total)
            .. " feature(s): "
            .. tostring(delta.modules)
            .. " modules, "
            .. tostring(delta.legit)
            .. " legit, "
            .. tostring(delta.overlays)
            .. " overlays",
        delta
end

-- Health check
local function healthCheck()
    local issues = {}
    local warns = {}
    if not shared.Bad then
        table.insert(issues, "Bad API nil")
        return issues, warns
    end
    local B = shared.Bad
    if type(B.CreateNotification) ~= "function" then
        table.insert(issues, "CreateNotification missing")
    end
    if type(B.Save) ~= "function" then
        table.insert(issues, "Save missing")
    end
    if type(B.Load) ~= "function" then
        table.insert(issues, "Load missing")
    end
    if type(B.Clean) ~= "function" then
        table.insert(issues, "Clean missing")
    end
    if not B.Categories then
        table.insert(warns, "Categories missing")
    elseif not B.Categories.Main then
        table.insert(warns, "Main category missing")
    end
    if type(B.Modules) ~= "table" then
        table.insert(issues, "Modules missing")
    elseif countEntries(B.Modules) == 0 then
        table.insert(issues, "No module buttons registered")
    end
    if type(B.Libraries) ~= "table" then
        table.insert(warns, "Libraries missing")
    end
    pcall(function()
        collectgarbage("collect")
        local m = collectgarbage("count")
        if m > 50000 then
            table.insert(warns, "High memory: " .. string.format("%.1f", m) .. " KB")
        end
    end)
    return issues, warns
end

-- Finish loading
local function installModuleHealthAPI()
    local api = shared.Bad
    if type(api) ~= "table" then
        return
    end

    function api:GetBedWarsModuleHealth()
        local compatibility = self.BedWarsCompatibility
        if type(compatibility) == "table" and type(compatibility.AuditAll) == "function" then
            local ok, report = pcall(compatibility.AuditAll, compatibility)
            if ok then
                return report
            end
        end
        return shared.__badwars_module_health or {
            Total = 0,
            Ready = 0,
            Failed = 0,
            Issues = {},
            Modules = {},
        }
    end

    function api:CopyBedWarsModuleHealth()
        local report = self:GetBedWarsModuleHealth()
        local encoded
        pcall(function()
            encoded = cloneref(game:GetService("HttpService")):JSONEncode(report)
        end)
        encoded = encoded or tostring(report)

        pcall(function()
            if type(setclipboard) == "function" then
                setclipboard(encoded)
            elseif type(toclipboard) == "function" then
                toclipboard(encoded)
            end
        end)
        return encoded
    end
end

installModuleHealthAPI()

local function finish()
    local api = shared.Bad
    if type(api) ~= "table" then
        recordErr("finish", "Bad API disappeared before profile loading")
        setStatus("ERROR: GUI API unavailable during finalization", true)
        return
    end

    setStatus("loading profile")

    local loaded, loadError = pcall(function()
        api:Load()
    end)
    if not loaded then
        recordErr("profile-load", loadError)
        setStatus("ERROR profile: " .. tostring(loadError), true)
    end

    api.Init = nil

    pcall(function()
        if type(api.SortAllModules) == "function" then
            api:SortAllModules()
        end
    end)

    task.spawn(function()
        while shared.Bad == api and api.Loaded do
            local saved, saveError = pcall(function()
                api:Save()
            end)

            if not saved then
                recordErr("profile-autosave", saveError)
                break
            end

            task.wait(10)
        end
    end)

    local teleported = false
    local playersService = cloneref(game:GetService("Players"))
    local teleportService = cloneref(game:GetService("TeleportService"))
    local localPlayer = playersService.LocalPlayer or playersService.PlayerAdded:Wait()
    local loaderUrl = rawUrls("badscript/loader.lua")[1]

    local function buildTeleportScript()
        local developerPrefix = shared.BadDeveloper and "shared.BadDeveloper=true\n" or ""
        return developerPrefix
            .. "shared.BadReload=nil; shared.BadTeleportReload=true\n"
            .. "repeat task.wait() until game:IsLoaded()\n"
            .. "local ok,src=pcall(function() return game:HttpGet('"
            .. loaderUrl
            .. "?v=13&t='..tostring(os.time()),true) end)\n"
            .. "if ok and type(src)=='string' then local fn=loadstring(src,'badwars-loader'); if fn then fn() end end"
    end

    local function queueReload()
        if teleported or shared.BadIndependent or shared.DISABLED_QUEUE_ON_TELEPORT then
            return
        end
        teleported = true
        pcall(function()
            api:Save()
        end)
        pcall(queueTeleport, buildTeleportScript())
    end

    local teleportConnection = localPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
            queueReload()
        end
    end)
    api:Clean(teleportConnection)

    pcall(function()
        api:Clean(teleportService.LocalPlayerArrivedFromTeleport:Connect(function()
            task.delay(1.5, function()
                if not shared.Bad and not shared.DISABLED_QUEUE_ON_TELEPORT then
                    local ok, source = pcall(function()
                        return game:HttpGet(loaderUrl .. "?v=13&arrival=" .. tostring(os.time()), true)
                    end)
                    if ok and type(source) == "string" then
                        local fn = _loadstring(source, "badwars-arrival-loader")
                        if fn then
                            fn()
                        end
                    end
                end
            end)
        end))
    end)

    return api
end

local function showInterface(api)
    if type(api) ~= "table" then
        return false
    end

    if type(api.WaitForModuleReadiness) == "function" then
        pcall(api.WaitForModuleReadiness, api, 4)
    end

    local runService = cloneref(game:GetService("RunService"))
    pcall(function()
        runService.Heartbeat:Wait()
        runService.Heartbeat:Wait()
    end)

    if type(api.FinalizeInitialLayout) == "function" then
        pcall(api.FinalizeInitialLayout, api, false)
    end

    local clickGui =
        api.gui
        and api.gui:FindFirstChild("ScaledGui")
        and api.gui.ScaledGui:FindFirstChild("ClickGui")

    if not clickGui then
        return false
    end

    clickGui.Visible = true

    if
        api.Categories
        and api.Categories.Main
        and api.Categories.Main.Options
        and api.Categories.Main.Options["GUI bind indicator"]
        and api.Categories.Main.Options["GUI bind indicator"].Enabled
        and type(api.CreateNotification) == "function"
    then
        task.defer(function()
            api:CreateNotification(
                "BadWars",
                "The interface is ready.",
                4,
                "success"
            )
        end)
    end

    return true
end

-- ============ PIPELINE ============

-- Stage 1: Deps
setStatus("pipeline: dependencies")
local deps = {
    "Players",
    "RunService",
    "UserInputService",
    "TweenService",
    "Lighting",
    "HttpService",
    "GuiService",
    "ReplicatedStorage",
    "TeleportService",
    "MarketplaceService",
}
local missing = {}
for _, d in ipairs(deps) do
    local ok, sv = pcall(function()
        return game:GetService(d)
    end)
    if not ok or not sv then
        table.insert(missing, d)
    end
end
if #missing > 0 then
    mwarn("BadWars: Missing services: " .. table.concat(missing, ", "))
end

-- Stage 2: Notify
pcall(function()
    game:GetService("StarterGui")
        :SetCore("SendNotification", { Title = "BadWars", Text = "by usingINales | Dev Mode Active", Duration = 6 })
end)

-- Stage 3: GUI Profile
local defaultGui = "new"
local gui = defaultGui
local savedGui = isfile("badscript/profiles/gui.txt") and readfile("badscript/profiles/gui.txt") or ""
savedGui = tostring(savedGui):lower():gsub("%s+", "")
setStatus("selecting interface")
if savedGui ~= gui then
    -- Production is fail-closed to the current UI generation. Legacy UI
    -- selectors are overwritten before any presentation source is loaded.
    writefile("badscript/profiles/gui.txt", gui)
end
if not isfolder("badscript/assets/" .. gui) then
    makefolder("badscript/assets/" .. gui)
end

-- Stage 4: Load GUI
setStatus("loading interface")
installBadWarsLoaderShim()

do
    local existing = shared.BadWarsSpr
    local valid = type(existing) == "table"
        and type(existing.target) == "function"
        and type(existing.stop) == "function"

    if not valid then
        local source, sourceErr = downloadFile("badscript/libraries/spr.lua")
        if type(source) == "string" and source ~= "" then
            local motionFn, compileErr = _loadstring(source, "badwars-spr")
            if motionFn then
                local ok, library = pcall(motionFn)
                if ok
                    and type(library) == "table"
                    and type(library.target) == "function"
                    and type(library.stop) == "function"
                then
                    shared.BadWarsSpr = library
                else
                    mwarn("BadWars: spr motion library runtime fallback: " .. safeStr(library))
                end
            else
                mwarn("BadWars: spr motion library compile fallback: " .. safeStr(compileErr))
            end
        else
            mwarn("BadWars: spr motion library unavailable; using TweenService fallback: " .. safeStr(sourceErr))
        end
    end
end

local guiStart = os_clock()
local guiCode = downloadFile("badscript/guis/" .. gui .. "/gui.lua")
if type(guiCode) ~= "string" or guiCode == "" then
    error("GUI download failed", 0)
end
local guiFn, guiErr = _loadstring(guiCode, "gui")
if not guiFn then
    error("GUI compile: " .. tostring(guiErr), 0)
end
local traceback = debug and debug.traceback or function(message)
    return tostring(message)
end

local ok, api = xpcall(guiFn, traceback)
if not ok then
    error("GUI runtime failure:\n" .. tostring(api), 0)
end

if type(api) ~= "table" then
    error("GUI returned invalid API type: " .. typeof(api), 0)
end

if type(api.CreateNotification) ~= "function" then
    error(
        "GUI API is missing CreateNotification; Build="
            .. tostring(api.PremiumBuild)
            .. ", Version="
            .. tostring(api.Version),
        0
    )
end
shared.Bad = api
local Bad = api
ensureRuntimeCategories(api)
logMod("GUI", gui, os_clock() - guiStart, true)
setStatus("interface ready")

-- Stage 5: Universal Modules
if not shared.BadIndependent then
    setStatus("loading core modules")
    local uniStart = os_clock()
    local universalReady = false
    local universalDetail = "not attempted"
    local universalSource = "none"
    local universalDelta = { modules = 0, overlays = 0, legit = 0, total = 0 }
    local attemptErrors = {}

    -- Build from individual source files first. This applies source repairs,
    -- validates every module, and prevents a stale prebuilt bundle from hiding fixes.
    local dynamicCode, dynamicInfo = buildBundle(
        "universal",
        "badscript/games/universal - base/base.lua",
        "badscript/games/universal - base/files.txt"
    )
    if dynamicCode then
        local okRun, detail, delta = runUniversalCandidate(dynamicCode, "dynamic")
        universalReady = okRun
        universalDetail = detail
        universalSource = "dynamic"
        universalDelta = delta
        if not okRun then
            table.insert(attemptErrors, "dynamic: " .. tostring(detail))
        end
    else
        table.insert(attemptErrors, "dynamic build: " .. tostring(dynamicInfo))
    end

    -- Only try the prebuilt fallback when the failed dynamic attempt registered
    -- nothing. Retrying after partial registration can create duplicate controls.
    if not universalReady and (universalDelta.total or 0) == 0 then
        local prebuiltCode, prebuiltInfo = loadPrebuiltBundle("universal")
        if prebuiltCode then
            local okRun, detail, delta = runUniversalCandidate(prebuiltCode, "prebuilt")
            universalReady = okRun
            universalDetail = detail
            universalSource = "prebuilt"
            universalDelta = delta
            if not okRun then
                table.insert(attemptErrors, "prebuilt: " .. tostring(detail))
            end
        else
            table.insert(attemptErrors, "prebuilt unavailable: " .. tostring(prebuiltInfo))
        end
    end

    shared.__badwars_universal_report = {
        source = universalSource,
        ready = universalReady,
        detail = universalDetail,
        registered = universalDelta,
        attemptErrors = attemptErrors,
        failed = attemptErrors,
    }

    if universalReady then
        repairModuleCategories("universal")
        setStatus("universal modules ready - " .. tostring(universalDelta.total) .. " registered")
        logMod("Universal", universalSource, os_clock() - uniStart, true, universalDetail)
    else
        local failure = #attemptErrors > 0 and table.concat(attemptErrors, " | ") or universalDetail
        setStatus("ERROR universal: " .. tostring(failure), true)
        recordErr("universal", failure)
        logMod("Universal", universalSource, os_clock() - uniStart, false, failure)
        mwarn("BadWars: Universal module registration failed: " .. tostring(failure))
    end

    -- Stage 7: Game Module
    local gPath = gamePath(game.PlaceId)
    if gameModulePaths[tonumber(game.PlaceId)] then
        local gameOk, gameErr = runGameMod(gPath, isfile(gPath) and "cached" or "remote")
        if gameOk then
            repairModuleCategories("game")
            setStatus("game module ready")
            task.defer(function()
                local current = shared.Bad
                local compatibility = current and current.BedWarsCompatibility
                if type(compatibility) == "table" and type(compatibility.AuditAll) == "function" then
                    pcall(compatibility.AuditAll, compatibility)
                end
            end)
        else
            recordErr(gPath, gameErr)
            setStatus("ERROR game module: " .. tostring(gameErr), true)
        end
    elseif universalReady then
        setStatus("universal active; no game-specific module found")
    else
        setStatus("ERROR: no modules registered", true)
    end

    -- Stage 8: Finish
    setStatus("finalizing launch")
    local finalizedApi = finish()
    repairModuleCategories("profile")

    -- Stage 9: Health Check
    local issues, warns = healthCheck()
    if #issues > 0 then
        mwarn("BadWars: [HEALTH] Issues:")
        for _, i in ipairs(issues) do
            mwarn("  x " .. i)
        end
    end
    if #warns > 0 then
        mwarn("BadWars: [HEALTH] Warnings:")
        for _, w in ipairs(warns) do
            mwarn("  ! " .. w)
        end
    end

    -- Stage 10: Summary
    local report = shared.__badwars_universal_report
    local uniFail = 0
    if type(report) == "table" then
        local fc = type(report.failed) == "table" and #report.failed or 0
        if fc > 0 then
            mwarn("BadWars: Failed modules:")
            for _, e in ipairs(report.failed) do
                if type(e) == "table" then
                    mwarn("  x " .. tostring(e.name) .. " [" .. tostring(e.error) .. "]")
                else
                    mwarn("  x " .. tostring(e))
                end
            end
        end
        uniFail = fc
    end
    local rtCount = #__rtErrs
    local totalErr = #issues + uniFail + rtCount
    local el = os_clock() - pipelineStart
    if rtCount > 0 then
        for _, e in ipairs(__rtErrs) do
            mwarn("BadWars: [RUNTIME] " .. tostring(e.module) .. ": " .. tostring(e.error))
        end
    end
    showInterface(finalizedApi or api)
    setStatus("ready - " .. string.format("%.2f", el) .. "s")

    if totalErr > 0 and api and type(api.CreateNotification) == "function" then
        api:CreateNotification(
            "Compatibility",
            tostring(totalErr)
                .. " outdated feature"
                .. (totalErr == 1 and " was" or "s were")
                .. " isolated.",
            6,
            "warning"
        )
    end
    mwarn(
        "BadWars: Pipeline "
            .. (totalErr == 0 and "OK" or "ISSUES")
            .. " in "
            .. string.format("%.2f", el)
            .. "s"
            .. (totalErr > 0 and " (" .. totalErr .. " error(s))" or "")
    )
else
    shared.Bad.Init = finish
    setStatus("independent mode")
    return api
end
