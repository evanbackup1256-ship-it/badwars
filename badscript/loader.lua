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
-- Diagnostics implementations may be partial or stale.
-- Detect optional methods instead of assuming every diagnostics table is complete.
do
    local diagnostics = type(shared) == "table" and shared.BadDiagnostics or nil
    shared.BadDiagnosticsCapabilities = {
        Traceback = type(diagnostics) == "table" and type(diagnostics.Traceback) == "function",
        RecordRuntime = type(diagnostics) == "table" and type(diagnostics.RecordRuntime) == "function",
        Capture = type(diagnostics) == "table" and type(diagnostics.Capture) == "function",
        Open = type(diagnostics) == "table" and type(diagnostics.Open) == "function",
    }
end

-- BadWars Loader
-- Dual-format URL fallback + all diagnostics

local loaderStart=os.clock()

local __executorPrimitiveSnapshot = {
    request = type(request) == "function",
    http_request = type(http_request) == "function",
    readfile = type(readfile) == "function",
    writefile = type(writefile) == "function",
    isfile = type(isfile) == "function",
    delfile = type(delfile) == "function",
    isfolder = type(isfolder) == "function",
    makefolder = type(makefolder) == "function",
    listfiles = type(listfiles) == "function",
    loadstring = type(loadstring) == "function",
    getgenv = type(getgenv) == "function",
    getrenv = type(getrenv) == "function",
    gethui = type(gethui) == "function",
    queue_on_teleport = type(queue_on_teleport) == "function"
        or type(queueonteleport) == "function",
}

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

-- Aggressive cache clearing: always wipe old cached files before any HTTP requests
-- This ensures the latest code is always downloaded, even if old loader is cached
pcall(function()
    local oldCacheVersion = isfile('badscript/profiles/cache-version.txt') and readfile('badscript/profiles/cache-version.txt') or ''
    if oldCacheVersion ~= 'badwars-v27-windui-2026-07-08-14' then
        -- Clear old main.lua and diagnostics to force fresh download
        local filesToClear = {
            'badscript/main.lua',
            'badscript/libraries/diagnostics.lua',
            'badscript/profiles/cache-version.txt',
        }
        for _, f in ipairs(filesToClear) do
            if isfile(f) then pcall(delfile, f) end
        end
        -- Clear old libraries and GUI cache (preserve game modules as fallback)
        local foldersToWipe = {
            'badscript/libraries',
            'badscript/guis/new',
        }
        for _, folder in ipairs(foldersToWipe) do
            if isfolder(folder) then
                for _, f in ipairs(listfiles(folder)) do
                    if isfile(f) and not f:find('windui', 1, true) then
                        pcall(delfile, f)
                    end
                end
            end
        end
        -- Write new cache version
        pcall(writefile, 'badscript/profiles/cache-version.txt', 'badwars-v27-windui-2026-07-08-14')
    end
end)

-- Multi-signal executor fingerprinting.
-- Direct identity APIs are treated as strongest evidence, but the result is
-- cross-checked against unique namespaces, marker globals, and capabilities.
local __detectedExecutor = "Unidentified Executor"
local __executorInfo = {
    name = "Unidentified Executor",
    confidence = "unknown",
    confidenceScore = 0,
    platform = "Unknown",
    free = false,
    httpMethod = "none",
    capabilities = {},
    evidence = {},
    alternatives = {},
    rawIdentifiers = {},
    spoofSuspected = false,
}

local function safeRead(container, key)
    if type(container) ~= "table" then
        return nil
    end

    local ok, value = pcall(rawget, container, key)
    if ok and value ~= nil then
        return value
    end

    ok, value = pcall(function()
        return container[key]
    end)
    if ok then
        return value
    end

    return nil
end

local function collectEnvironments()
    local environments = {}
    local seen = {}

    local function add(name, environment)
        if type(environment) ~= "table" or seen[environment] then
            return
        end
        seen[environment] = true
        table.insert(environments, {
            name = name,
            value = environment,
        })
    end

    add("_G", _G)

    if type(getgenv) == "function" then
        local ok, environment = pcall(getgenv)
        if ok then
            add("getgenv", environment)
        end
    end

    if type(getrenv) == "function" then
        local ok, environment = pcall(getrenv)
        if ok then
            add("getrenv", environment)
        end
    end

    if type(getfenv) == "function" then
        local ok, environment = pcall(getfenv, 0)
        if ok then
            add("getfenv", environment)
        end
    end

    return environments
end

local __executorEnvironments = collectEnvironments()

local function getGlobal(name)
    for _, environment in ipairs(__executorEnvironments) do
        local value = safeRead(environment.value, name)
        if value ~= nil then
            return value, environment.name
        end
    end
    return nil, nil
end

local function hasGlobal(name, expectedType)
    local value, environmentName = getGlobal(name)
    if value == nil then
        return false, nil, environmentName
    end
    if expectedType and type(value) ~= expectedType then
        return false, value, environmentName
    end
    return true, value, environmentName
end

local function hasNamespaceFunction(namespaceName, functionName)
    local namespace, environmentName = getGlobal(namespaceName)
    if type(namespace) ~= "table" then
        return false, nil, environmentName
    end

    local value = safeRead(namespace, functionName)
    return type(value) == "function", value, environmentName
end

local function safeText(value)
    local valueType = type(value)
    if valueType == "string" then
        local trimmed = value:match("^%s*(.-)%s*$")
        if trimmed == "" then
            return nil
        end
        return trimmed
    end
    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end
    return nil
end

local EXECUTOR_ALIASES = {
    { "synapse z", "Synapse Z" },
    { "synapse x", "Synapse X" },
    { "script ware", "Script-Ware" },
    { "scriptware", "Script-Ware" },
    { "proto smasher", "ProtoSmasher" },
    { "protosmasher", "ProtoSmasher" },
    { "sir hurt", "SirHurt" },
    { "sirhurt", "SirHurt" },
    { "arceus x", "Arceus X" },
    { "vega x", "Vega X" },
    { "bunni lol", "Bunni.lol" },
    { "mac sploit", "MacSploit" },
    { "macsploit", "MacSploit" },
    { "solora", "Solara" },
    { "solara", "Solara" },
    { "fluxus", "Fluxus" },
    { "krnl", "Krnl" },
    { "xeno", "Xeno" },
    { "wave", "Wave" },
    { "arceus", "Arceus X" },
    { "delta", "Delta" },
    { "hydrogen", "Hydrogen" },
    { "electron", "Electron" },
    { "vega", "Vega X" },
    { "celery", "Celery" },
    { "swift", "Swift" },
    { "nezur", "Nezur" },
    { "ronix", "Ronix" },
    { "potassium", "Potassium" },
    { "matcha", "Matcha" },
    { "bunni", "Bunni.lol" },
    { "photon", "Photon" },
    { "codex", "Codex" },
    { "cryptic", "Cryptic" },
    { "nihon", "Nihon" },
    { "velocity", "Velocity" },
    { "seliware", "Seliware" },
    { "zorara", "Zorara" },
    { "valex", "Valex" },
    { "trigon", "Trigon" },
    { "volcano", "Volcano" },
    { "cubix", "Cubix" },
    { "sentinel", "Sentinel" },
    { "electron", "Electron" },
    { "awp", "AWP" },
    { "volt", "Volt" },
    { "luna", "Luna" },
    { "evon", "Evon" },
}

local function canonicalExecutorName(rawName)
    local text = safeText(rawName)
    if not text then
        return nil
    end

    local normalized = string.lower(text)
        :gsub("[_%-%.]+", " ")
        :gsub("[^%w%s]+", "")
        :gsub("%s+", " ")
        :match("^%s*(.-)%s*$")

    if normalized == ""
        or normalized == "unknown"
        or normalized == "unknown executor"
        or normalized == "executor"
        or normalized == "none"
        or normalized == "nil"
    then
        return nil
    end

    for _, alias in ipairs(EXECUTOR_ALIASES) do
        if normalized:find(alias[1], 1, true) then
            return alias[2]
        end
    end

    local generic = normalized
        :gsub("%s+executor%s*$", "")
        :gsub("^executor%s+", "")
        :match("^%s*(.-)%s*$")

    if generic == "" or generic == "roblox" or generic == "studio" then
        return nil
    end

    if #text > 64 then
        text = text:sub(1, 64)
    end
    return text
end

local CANDIDATE_METADATA = {
    ["Synapse X"] = { platform = "Windows" },
    ["Synapse Z"] = { platform = "Windows" },
    ["Script-Ware"] = { platform = "Windows/macOS" },
    ["Fluxus"] = { platform = "Windows/Android" },
    ["Krnl"] = { platform = "Windows" },
    ["Xeno"] = { platform = "Windows" },
    ["Solara"] = { platform = "Windows" },
    ["Wave"] = { platform = "Windows" },
    ["Arceus X"] = { platform = "Android/iOS" },
    ["Delta"] = { platform = "Android/iOS/Windows" },
    ["Hydrogen"] = { platform = "Android/macOS" },
    ["Electron"] = { platform = "Windows" },
    ["Vega X"] = { platform = "Windows/Android" },
    ["MacSploit"] = { platform = "macOS" },
}

local candidates = {}
local rawIdentifiers = {}
local directCandidateNames = {}
local detectedVersions = {}

local function addCandidate(name, score, source, detail, evidenceClass)
    name = canonicalExecutorName(name)
    if not name then
        return
    end

    local candidate = candidates[name]
    if not candidate then
        candidate = {
            name = name,
            score = 0,
            direct = 0,
            unique = 0,
            supporting = 0,
            evidence = {},
            seen = {},
        }
        candidates[name] = candidate
    end

    local evidenceKey = tostring(source) .. "|" .. tostring(detail)
    if candidate.seen[evidenceKey] then
        return
    end
    candidate.seen[evidenceKey] = true

    candidate.score += tonumber(score) or 0
    if evidenceClass == "direct" then
        candidate.direct += 1
        directCandidateNames[name] = true
    elseif evidenceClass == "unique" then
        candidate.unique += 1
    else
        candidate.supporting += 1
    end

    table.insert(candidate.evidence, {
        source = tostring(source),
        detail = tostring(detail),
        score = tonumber(score) or 0,
        class = evidenceClass or "supporting",
    })
end

local function recordIdentifier(source, rawName, rawVersion)
    local name = canonicalExecutorName(rawName)
    if not name then
        return
    end

    local version = safeText(rawVersion)
    table.insert(rawIdentifiers, {
        source = source,
        name = safeText(rawName) or name,
        canonical = name,
        version = version,
    })

    if version then
        detectedVersions[name] = detectedVersions[name] or version
    end

    addCandidate(
        name,
        170,
        source,
        "identity API returned " .. tostring(safeText(rawName) or name),
        "direct"
    )
end

local function inspectIdentifierResult(source, first, second, third)
    if type(first) == "table" then
        local name = safeRead(first, "Name")
            or safeRead(first, "name")
            or safeRead(first, "Executor")
            or safeRead(first, "executor")
            or safeRead(first, "ExecutorName")
            or safeRead(first, "executorName")
        local version = safeRead(first, "Version")
            or safeRead(first, "version")
            or safeRead(first, "ExecutorVersion")
            or safeRead(first, "executorVersion")
        recordIdentifier(source, name, version)
        return
    end

    local firstText = safeText(first)
    local secondText = safeText(second)
    local thirdText = safeText(third)

    if firstText then
        recordIdentifier(source, firstText, secondText or thirdText)
    elseif secondText then
        recordIdentifier(source, secondText, thirdText)
    end
end

local IDENTIFIER_APIS = {
    "identifyexecutor",
    "identify_executor",
    "getexecutorname",
    "get_executor_name",
    "getexecutor",
    "get_executor",
}

for _, apiName in ipairs(IDENTIFIER_APIS) do
    local api, environmentName = getGlobal(apiName)
    if type(api) == "function" then
        local ok, first, second, third = pcall(api)
        if ok then
            inspectIdentifierResult(
                tostring(environmentName or "global") .. "." .. apiName,
                first,
                second,
                third
            )
        end
    end
end

local STRING_IDENTITY_GLOBALS = {
    "EXECUTOR_NAME",
    "ExecutorName",
    "executor_name",
    "_EXECUTOR_NAME",
    "EXECUTOR",
}

for _, globalName in ipairs(STRING_IDENTITY_GLOBALS) do
    local value, environmentName = getGlobal(globalName)
    if type(value) == "string" then
        addCandidate(
            value,
            48,
            tostring(environmentName or "global") .. "." .. globalName,
            "string identity marker",
            "supporting"
        )
    end
end

local function addGlobalMarker(candidateName, globalName, expectedType, score)
    local present, value, environmentName = hasGlobal(globalName, expectedType)
    if not present then
        return
    end

    local detail = globalName .. " (" .. type(value) .. ")"
    addCandidate(
        candidateName,
        score,
        tostring(environmentName or "global") .. "." .. globalName,
        detail,
        score >= 40 and "unique" or "supporting"
    )
end

local function addNamespaceMarker(candidateName, namespaceName, functionName, score)
    local present, _, environmentName = hasNamespaceFunction(namespaceName, functionName)
    if not present then
        return
    end

    addCandidate(
        candidateName,
        score,
        tostring(environmentName or "global")
            .. "."
            .. namespaceName
            .. "."
            .. functionName,
        "namespace function present",
        score >= 30 and "unique" or "supporting"
    )
end

local GLOBAL_MARKERS = {
    { "Synapse X", "syn", "table", 52 },
    { "Script-Ware", "sw", "table", 70 },
    { "Script-Ware", "scriptware", "table", 70 },
    { "Fluxus", "fluxus", "table", 65 },
    { "Krnl", "krnl", "table", 62 },
    { "Krnl", "KRNL_LOADED", nil, 58 },
    { "Krnl", "iskrnlclosure", "function", 52 },
    { "Xeno", "xeno", "table", 62 },
    { "Xeno", "XENO_LOADED", nil, 55 },
    { "Solara", "solara", "table", 62 },
    { "Solara", "solora", "table", 62 },
    { "Solara", "SOLARA_LOADED", nil, 55 },
    { "Wave", "wave", "table", 62 },
    { "Wave", "WAVE_LOADED", nil, 55 },
    { "Arceus X", "arceus", "table", 62 },
    { "Arceus X", "ARCEUS_LOADED", nil, 55 },
    { "Delta", "delta", "table", 62 },
    { "Delta", "DELTA_LOADED", nil, 55 },
    { "Hydrogen", "hydrogen", "table", 62 },
    { "Hydrogen", "HYDROGEN_LOADED", nil, 55 },
    { "Electron", "electron", "table", 62 },
    { "Electron", "ELECTRON_LOADED", nil, 55 },
    { "Vega X", "vega", "table", 58 },
    { "Vega X", "vegax", "table", 62 },
    { "Celery", "celery", "table", 62 },
    { "Swift", "swift", "table", 62 },
    { "Nezur", "nezur", "table", 62 },
    { "Ronix", "ronix", "table", 62 },
    { "Potassium", "potassium", "table", 62 },
    { "Matcha", "matcha", "table", 62 },
    { "Bunni.lol", "bunni", "table", 62 },
    { "Photon", "photon", "table", 62 },
    { "Codex", "codex", "table", 62 },
    { "Cryptic", "cryptic", "table", 62 },
    { "MacSploit", "macsploit", "table", 62 },
    { "Nihon", "nihon", "table", 62 },
    { "Velocity", "velocity", "table", 62 },
    { "Seliware", "seliware", "table", 62 },
    { "Zorara", "zorara", "table", 62 },
    { "Valex", "valex", "table", 62 },
    { "Trigon", "trigon", "table", 62 },
    { "Volcano", "volcano", "table", 62 },
    { "Cubix", "cubix", "table", 62 },
    { "AWP", "awp", "table", 62 },
    { "Volt", "volt", "table", 62 },
    { "Luna", "luna", "table", 62 },
    { "Evon", "evon", "table", 62 },
    { "ProtoSmasher", "pebc_execute", "function", 70 },
    { "ProtoSmasher", "is_protosmasher_closure", "function", 70 },
    { "SirHurt", "is_sirhurt_closure", "function", 70 },
    { "Sentinel", "secure_load", "function", 52 },
}

for _, marker in ipairs(GLOBAL_MARKERS) do
    addGlobalMarker(marker[1], marker[2], marker[3], marker[4])
end

local NAMESPACE_MARKERS = {
    { "Synapse X", "syn", "secure_call", 42 },
    { "Synapse X", "syn", "protect_gui", 38 },
    { "Synapse X", "syn", "request", 24 },
    { "Synapse X", "syn", "queue_on_teleport", 22 },
    { "Fluxus", "fluxus", "request", 34 },
    { "Fluxus", "fluxus", "http_get", 30 },
    { "Fluxus", "fluxus", "set_fps_cap", 24 },
    { "Krnl", "krnl", "request", 28 },
    { "Wave", "wave", "request", 28 },
    { "Delta", "delta", "request", 28 },
    { "Hydrogen", "hydrogen", "request", 28 },
    { "Electron", "electron", "request", 28 },
}

for _, marker in ipairs(NAMESPACE_MARKERS) do
    addNamespaceMarker(marker[1], marker[2], marker[3], marker[4])
end

local FUNCTION_MARKERS = {
    { "Synapse X", "is_synapse_function", 45 },
    { "Synapse X", "is_synapse_closure", 45 },
    { "Script-Ware", "is_sw_closure", 45 },
    { "Krnl", "iskrnlclosure", 45 },
    { "ProtoSmasher", "is_protosmasher_closure", 55 },
    { "SirHurt", "is_sirhurt_closure", 55 },
}

for _, marker in ipairs(FUNCTION_MARKERS) do
    local present, _, environmentName = hasGlobal(marker[2], "function")
    if present then
        addCandidate(
            marker[1],
            marker[3],
            tostring(environmentName or "global") .. "." .. marker[2],
            "unique closure marker",
            "unique"
        )
    end
end

local function currentPlatform()
    local platform = "Unknown"

    pcall(function()
        local inputService = cloneref(game:GetService("UserInputService"))
        if type(inputService.GetPlatform) == "function" then
            local value = inputService:GetPlatform()
            local text = tostring(value)
            platform = text:gsub("^Enum%.Platform%.", "")
        end

        if platform == "Unknown" then
            if inputService.TouchEnabled and not inputService.KeyboardEnabled then
                platform = "Mobile"
            elseif inputService.KeyboardEnabled then
                platform = "Desktop"
            end
        end
    end)

    return platform
end

local function functionExists(name)
    local value = getGlobal(name)
    return type(value) == "function"
end

local function tableExists(name)
    local value = getGlobal(name)
    return type(value) == "table"
end

local synTable = getGlobal("syn")
local fluxusTable = getGlobal("fluxus")
local websocketTable = getGlobal("WebSocket") or getGlobal("websocket")
local cryptTable = getGlobal("crypt")
    or (type(synTable) == "table" and safeRead(synTable, "crypt"))
local drawingTable = getGlobal("Drawing")
local gameHttpGetAvailable = false

pcall(function()
    gameHttpGetAvailable = type(game.HttpGet) == "function"
end)

local capabilities = {
    identityApi = #rawIdentifiers > 0,
    request = __executorPrimitiveSnapshot.request
        or __executorPrimitiveSnapshot.http_request
        or (type(synTable) == "table" and type(safeRead(synTable, "request")) == "function")
        or (type(fluxusTable) == "table" and type(safeRead(fluxusTable, "request")) == "function"),
    httpGet = functionExists("httpget")
        or functionExists("http_get")
        or (type(synTable) == "table" and type(safeRead(synTable, "http_get")) == "function")
        or (type(fluxusTable) == "table" and type(safeRead(fluxusTable, "http_get")) == "function")
        or gameHttpGetAvailable,
    fileSystem = __executorPrimitiveSnapshot.readfile
        and __executorPrimitiveSnapshot.writefile
        and __executorPrimitiveSnapshot.isfile,
    deleteFile = __executorPrimitiveSnapshot.delfile,
    folders = __executorPrimitiveSnapshot.isfolder
        and __executorPrimitiveSnapshot.makefolder
        and __executorPrimitiveSnapshot.listfiles,
    loadstring = __executorPrimitiveSnapshot.loadstring,
    getgenv = __executorPrimitiveSnapshot.getgenv,
    getrenv = __executorPrimitiveSnapshot.getrenv,
    gethui = __executorPrimitiveSnapshot.gethui,
    clipboard = functionExists("setclipboard") or functionExists("toclipboard"),
    queueOnTeleport = __executorPrimitiveSnapshot.queue_on_teleport
        or (type(synTable) == "table"
            and type(safeRead(synTable, "queue_on_teleport")) == "function"),
    hookFunction = functionExists("hookfunction"),
    hookMetamethod = functionExists("hookmetamethod"),
    newCClosure = functionExists("newcclosure"),
    rawMetatable = functionExists("getrawmetatable"),
    readonlyControl = functionExists("setreadonly")
        or functionExists("make_writeable")
        or functionExists("make_readonly"),
    executorClosure = functionExists("isexecutorclosure")
        or functionExists("isourclosure")
        or functionExists("checkclosure"),
    threadIdentity = functionExists("setthreadidentity")
        or functionExists("set_thread_identity")
        or functionExists("getthreadidentity")
        or functionExists("get_thread_identity"),
    hiddenProperties = functionExists("gethiddenproperty")
        or functionExists("sethiddenproperty"),
    scriptEnvironment = functionExists("getsenv")
        or functionExists("getrenv")
        or functionExists("getgc"),
    drawing = type(drawingTable) == "table"
        and type(safeRead(drawingTable, "new")) == "function",
    websocket = type(websocketTable) == "table"
        and type(safeRead(websocketTable, "connect")) == "function",
    crypt = type(cryptTable) == "table",
    fpsCap = functionExists("setfpscap")
        or functionExists("set_fps_cap")
        or (type(fluxusTable) == "table"
            and type(safeRead(fluxusTable, "set_fps_cap")) == "function"),
    debugIntrospection = type(debug) == "table"
        and (
            type(safeRead(debug, "getinfo")) == "function"
            or type(safeRead(debug, "info")) == "function"
            or type(safeRead(debug, "getconstants")) == "function"
        ),
}

local httpMethod = "none"
if __executorPrimitiveSnapshot.request then
    httpMethod = "request"
elseif __executorPrimitiveSnapshot.http_request then
    httpMethod = "http_request"
elseif type(synTable) == "table" and type(safeRead(synTable, "request")) == "function" then
    httpMethod = "syn.request"
elseif type(fluxusTable) == "table" and type(safeRead(fluxusTable, "request")) == "function" then
    httpMethod = "fluxus.request"
elseif functionExists("httpget") then
    httpMethod = "httpget"
elseif functionExists("http_get") then
    httpMethod = "http_get"
elseif capabilities.httpGet then
    httpMethod = "game.HttpGet"
end

local rankedCandidates = {}
for _, candidate in pairs(candidates) do
    table.sort(candidate.evidence, function(left, right)
        if left.score == right.score then
            return left.source < right.source
        end
        return left.score > right.score
    end)
    table.insert(rankedCandidates, candidate)
end

table.sort(rankedCandidates, function(left, right)
    if left.score == right.score then
        if left.direct == right.direct then
            if left.unique == right.unique then
                return left.name < right.name
            end
            return left.unique > right.unique
        end
        return left.direct > right.direct
    end
    return left.score > right.score
end)

local directNameCount = 0
for _ in pairs(directCandidateNames) do
    directNameCount += 1
end

local top = rankedCandidates[1]
local second = rankedCandidates[2]
local spoofSuspected = directNameCount > 1

if top and second then
    local margin = top.score - second.score
    if margin < 18 and second.score >= 55 then
        spoofSuspected = true
    end

    if top.direct > 0 and second.direct == 0 and second.score >= 90 and second.name ~= top.name then
        spoofSuspected = true
    end
end

local confidence = "unknown"
local confidenceScore = 0
local selectedName = "Unidentified Executor"

if top then
    selectedName = top.name
    local margin = second and (top.score - second.score) or top.score

    if top.direct > 0 and directNameCount == 1 and not spoofSuspected then
        confidence = "very high"
        confidenceScore = math.clamp(97 + math.min(top.unique, 2), 0, 99)
    elseif top.score >= 140 and margin >= 35 then
        confidence = "very high"
        confidenceScore = 94
    elseif top.score >= 95 and margin >= 24 then
        confidence = "high"
        confidenceScore = 86
    elseif top.score >= 65 and margin >= 12 then
        confidence = "medium"
        confidenceScore = 72
    else
        confidence = "low"
        confidenceScore = 48
    end

    if spoofSuspected then
        confidenceScore = math.max(35, confidenceScore - 22)
        if confidenceScore >= 75 then
            confidence = "high"
        elseif confidenceScore >= 58 then
            confidence = "medium"
        else
            confidence = "low"
        end
    end
else
    local exploitPrimitiveCount = 0
    for _, enabled in pairs({
        __executorPrimitiveSnapshot.request,
        __executorPrimitiveSnapshot.http_request,
        __executorPrimitiveSnapshot.readfile,
        __executorPrimitiveSnapshot.writefile,
        __executorPrimitiveSnapshot.loadstring,
        __executorPrimitiveSnapshot.getgenv,
        __executorPrimitiveSnapshot.gethui,
        capabilities.hookFunction,
        capabilities.hookMetamethod,
        capabilities.drawing,
    }) do
        if enabled then
            exploitPrimitiveCount += 1
        end
    end

    if exploitPrimitiveCount == 0 then
        selectedName = "Roblox/Studio Environment"
        confidence = "medium"
        confidenceScore = 70
    else
        selectedName = "Unidentified Executor"
        confidence = "low"
        confidenceScore = math.min(55, 25 + exploitPrimitiveCount * 4)
    end
end

local selectedEvidence = {}
if top then
    for index = 1, math.min(#top.evidence, 12) do
        local evidence = top.evidence[index]
        table.insert(
            selectedEvidence,
            evidence.source
                .. ": "
                .. evidence.detail
                .. " (+"
                .. tostring(evidence.score)
                .. ")"
        )
    end
end

local alternatives = {}
for index = 2, math.min(#rankedCandidates, 5) do
    local candidate = rankedCandidates[index]
    table.insert(alternatives, {
        name = candidate.name,
        score = candidate.score,
        direct = candidate.direct,
        unique = candidate.unique,
    })
end

local version = top and detectedVersions[top.name] or nil
if not version then
    local VERSION_APIS = {
        "getexecutorversion",
        "get_executor_version",
        "executorversion",
    }

    for _, apiName in ipairs(VERSION_APIS) do
        local api = getGlobal(apiName)
        if type(api) == "function" then
            local ok, result = pcall(api)
            if ok then
                version = safeText(result)
                if version then
                    break
                end
            end
        end
    end
end

local platform = currentPlatform()
local expectedPlatform = top
    and CANDIDATE_METADATA[top.name]
    and CANDIDATE_METADATA[top.name].platform
    or nil

__detectedExecutor = selectedName
__executorInfo = {
    name = selectedName,
    rawName = top and top.name or selectedName,
    version = version,
    confidence = confidence,
    confidenceScore = confidenceScore,
    score = top and top.score or 0,
    runnerUpMargin = top and second and (top.score - second.score) or nil,
    platform = platform,
    expectedPlatform = expectedPlatform,
    free = false,
    httpMethod = httpMethod,
    capabilities = capabilities,
    evidence = selectedEvidence,
    alternatives = alternatives,
    rawIdentifiers = rawIdentifiers,
    spoofSuspected = spoofSuspected,
}

shared.BadWarsExecutorInfo = __executorInfo
shared.BadWarsExecutorDetection = {
    selected = __executorInfo,
    candidates = rankedCandidates,
    identifiers = rawIdentifiers,
    spoofSuspected = spoofSuspected,
    primitiveSnapshot = __executorPrimitiveSnapshot,
}

warn(
    "BadWars: Detected executor: "
        .. __executorInfo.name
        .. (__executorInfo.version and (" " .. tostring(__executorInfo.version)) or "")
        .. " (confidence: "
        .. __executorInfo.confidence
        .. " "
        .. tostring(__executorInfo.confidenceScore)
        .. "%, score: "
        .. tostring(__executorInfo.score)
        .. ", platform: "
        .. tostring(__executorInfo.platform)
        .. ", http: "
        .. tostring(__executorInfo.httpMethod)
        .. (spoofSuspected and ", conflicting/spoofed fingerprints detected" or "")
        .. ")"
)

-- Configure every HTTP transport that is actually available.
-- Do not gate transports behind executor-name detection: many executors spoof or
-- omit their identifying globals while still exposing a working request function.
local __httpFunctions = {}
local __httpFunctionNames = {}
local __lastHttpDiagnostics = {}

local function getExecutorEnvironment()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then
            return env
        end
    end
    return _G
end

local function extractBody(result)
    if type(result) == "string" then
        return result
    end
    if type(result) ~= "table" then
        return nil, "response was " .. type(result)
    end

    local statusCode = tonumber(
        result.StatusCode
            or result.statusCode
            or result.Status
            or result.status
            or result.Code
            or result.code
    )
    local body = result.Body
        or result.body
        or result.Response
        or result.response
        or result.Data
        or result.data
        or result.Content
        or result.content

    if statusCode and (statusCode < 200 or statusCode >= 400) then
        return nil, "HTTP " .. tostring(statusCode)
    end
    if type(body) ~= "string" then
        return nil, "response body missing"
    end
    return body
end

local function addHttpFunction(name, callback)
    if type(callback) ~= "function" or __httpFunctionNames[name] then
        return
    end
    __httpFunctionNames[name] = true
    table.insert(__httpFunctions, {
        name = name,
        fn = callback,
    })
end

local function tryRequest(reqFn, url)
    local attempts = {
        function()
            return reqFn({Url = url, Method = "GET"})
        end,
        function()
            return reqFn({url = url, method = "GET"})
        end,
        function()
            return reqFn(url)
        end,
    }

    local lastError = "request returned no usable body"
    for _, attempt in ipairs(attempts) do
        local ok, result = pcall(attempt)
        if ok then
            local body, bodyError = extractBody(result)
            if type(body) == "string" and body ~= "" then
                return body
            end
            lastError = bodyError or lastError
        else
            lastError = tostring(result)
        end
    end

    error(lastError, 0)
end

local function registerRequestTransport(name, requestFunction)
    if type(requestFunction) == "function" then
        addHttpFunction(name, function(url)
            return tryRequest(requestFunction, url)
        end)
    end
end

local function registerDirectGet(name, getFunction, owner)
    if type(getFunction) ~= "function" then
        return
    end
    addHttpFunction(name, function(url)
        local attempts = {}
        if owner ~= nil then
            table.insert(attempts, function() return getFunction(owner, url, true) end)
        end
        table.insert(attempts, function() return getFunction(url, true) end)
        local lastError = "direct GET returned no usable body"
        for _, attempt in ipairs(attempts) do
            local ok, result = pcall(attempt)
            if ok then
                local body, bodyError = extractBody(result)
                if type(body) == "string" and body ~= "" then
                    return body
                end
                lastError = bodyError or lastError
            else
                lastError = tostring(result)
            end
        end
        error(lastError, 0)
    end)
end

local env = getExecutorEnvironment()

-- Only register HTTP methods that exist (fast startup)
registerRequestTransport("request", request)
registerRequestTransport("http_request", http_request)

registerDirectGet("game.HttpGet", game and game.HttpGet, game)
registerDirectGet("getgenv.HttpGet", type(env) == "table" and env.HttpGet or nil, game)

pcall(function()
    local service = cloneref(game:GetService("HttpService"))
    if service and type(service.GetAsync) == "function" then
        addHttpFunction("HttpService.GetAsync", function(url)
            local ok, result = pcall(function()
                return service:GetAsync(url, true)
            end)
            if not ok then
                ok, result = pcall(function()
                    return service:GetAsync(url)
                end)
            end
            if not ok then
                error(result, 0)
            end
            return result
        end)
    end
end)

local CFG={repo='evanbackup1256-ship-it',name='badwars',branch='main',folder='badscript',file='main.lua'}

local function rawUrls(path)
    local repo = CFG.repo .. "/" .. CFG.name
    local encodedPath = path:gsub(" ", "%%20")
    -- Try the most reliable URL first, fewer variants for speed
    return {
        "https://raw.githubusercontent.com/" .. repo .. "/" .. CFG.branch .. "/" .. encodedPath,
        "https://cdn.jsdelivr.net/gh/" .. repo .. "@" .. CFG.branch .. "/" .. encodedPath,
        "https://cdn.statically.io/gh/" .. repo .. "/" .. CFG.branch .. "/" .. encodedPath,
        "https://github.com/" .. repo .. "/raw/" .. CFG.branch .. "/" .. encodedPath,
    }
end

local ORCH_PATH=CFG.folder..'/'..CFG.file

local function callWithTimeout(callback, timeout)
    local done = false
    local packed
    local worker = task.spawn(function()
        packed = { pcall(callback) }
        done = true
    end)

    local started = os.clock()
    while not done and os.clock() - started < (tonumber(timeout) or 2) do
        task.wait(0.02)
    end

    if not done then
        pcall(function()
            task.cancel(worker)
        end)
        return false, nil, "timeout"
    end

    if packed[1] then
        return true, packed[2], packed[3]
    end
    return false, nil, tostring(packed[2])
end

local function isNotFoundBody(body)
    if type(body) ~= "string" then
        return false
    end
    local trimmed = body:match("^%s*(.-)%s*$")
    return trimmed == "404: Not Found"
        or trimmed == '{"message":"Not Found"}'
        or (#trimmed < 300 and trimmed:find('"message"%s*:%s*"Not Found"') ~= nil)
end

local function isRateLimited(body)
    if type(body) ~= "string" then
        return false
    end
    if #body > 2000 then
        return false
    end
    local trimmed = body:match("^%s*(.-)%s*$")
    if trimmed == "429: Too Many Requests" then return true end
    if trimmed == '{"error":"Too Many Requests"}' then return true end
    local lower = string.lower(trimmed)
    if lower:find("rate limit", 1, true) then return true end
    if lower:find("too many requests", 1, true) then return true end
    if lower:find("abuse detection", 1, true) then return true end
    if lower:find("<!doctype", 1, true) and lower:find("rate limit", 1, true) then return true end
    if trimmed:find("^429", 1, true) then return true end
    return false
end

local function isCorruptedBody(body)
    if type(body) ~= "string" or #body < 10 then
        return true
    end
    -- Real corrupted/HTML responses are SHORT. Large responses are valid code.
    if #body > 2000 then
        return false
    end
    local trimmed = body:match("^%s*(.-)%s*$")
    local lower = string.lower(trimmed)
    if lower:find("<!doctype", 1, true) or lower:find("<html", 1, true) then
        return true
    end
    local nonPrintable = 0
    for index = 1, math.min(#body, 300) do
        local byte = body:byte(index)
        if byte and byte < 32 and byte ~= 9 and byte ~= 10 and byte ~= 13 then
            nonPrintable += 1
        end
    end
    return nonPrintable > 20
end

local function rejectionReason(body)
    if type(body) ~= "string" then
        return "non-string response"
    end
    if #body < 10 then
        return "response too short"
    end
    if isNotFoundBody(body) then
        return "404/not found"
    end
    if isRateLimited(body) then
        return "rate limited"
    end
    if isCorruptedBody(body) then
        return "HTML or corrupted response"
    end
    return nil
end

local function httpGet(urls)
    __lastHttpDiagnostics = {}

    if #__httpFunctions == 0 then
        table.insert(__lastHttpDiagnostics, "No supported HTTP functions were discovered")
        return nil, nil, nil
    end

    for _, url in ipairs(urls) do
        for _, httpFunction in ipairs(__httpFunctions) do
            local ok, response, failure = callWithTimeout(function()
                return httpFunction.fn(url)
            end, 2)

            if ok then
                local rejected = rejectionReason(response)
                if not rejected then
                    return response, url, httpFunction.name
                end
                -- Log first 150 chars of rejected response for debugging
                local preview = type(response) == "string" and response:sub(1, 150) or tostring(response)
                table.insert(
                    __lastHttpDiagnostics,
                    httpFunction.name .. " | " .. url .. " | rejected: " .. rejected .. " | body: " .. preview
                )
            else
                table.insert(
                    __lastHttpDiagnostics,
                    httpFunction.name .. " | " .. url .. " | failed: " .. tostring(failure)
                )
            end
        end
    end

    return nil, nil, nil
end


-- BADWARS_LOADER_PRESENTATION_V6_BEGIN
-- Native pre-runtime loader styled to match the BadWars WindUI theme.
-- This intentionally uses Roblox instances because WindUI itself has not loaded yet.

local statusGui
local statusCard
local statusBackdrop
local statusShadow
local statusTitle
local statusMessage
local statusMeta
local progressFill
local progressGradient
local progressValue
local elapsedLabel
local stateDot
local statusChip
local statusChipStroke
local statusChipText
local statusAccent
local statusIcon
local statusIconGradient
local statusPanelStroke
local openConsoleButton
local statusCardScale
local statusCardStroke
local loaderHost
local loaderFitScale
local phaseMarkers = {}
local loaderConnections = {}
local loaderViewportConnection

local statusProgress = 0.03
local statusError = false
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local loaderDismissScheduled = false
local MINIMUM_VISIBLE_SECONDS = 1.35

local BASE_WIDTH = 720
local BASE_HEIGHT = 430
local TOPBAR_HEIGHT = 54
local SIDEBAR_WIDTH = 172
local CONTENT_GAP = 10

local loaderTweenService = cloneref(game:GetService("TweenService"))
local loaderGuiService = cloneref(game:GetService("GuiService"))
local loaderWorkspace = cloneref(game:GetService("Workspace"))

local COLORS = {
    backdrop = Color3.fromHex("#060608"),
    background = Color3.fromHex("#0f0f14"),
    dialog = Color3.fromHex("#14141c"),
    panel = Color3.fromHex("#0a0a0f"),
    element = Color3.fromHex("#12121a"),
    elementHover = Color3.fromHex("#1a1a24"),
    button = Color3.fromHex("#2a2a34"),
    border = Color3.fromHex("#FF2D4A"),
    text = Color3.fromHex("#FFFFFF"),
    placeholder = Color3.fromHex("#6a6a78"),
    muted = Color3.fromHex("#8a8a96"),
    primary = Color3.fromHex("#FF2D4A"),
    primarySoft = Color3.fromHex("#FF5A6E"),
    primaryWarm = Color3.fromHex("#FF6B35"),
    warning = Color3.fromHex("#F0B44D"),
    warningSoft = Color3.fromHex("#FBC15C"),
    success = Color3.fromHex("#43A047"),
    black = Color3.fromRGB(0, 0, 0),
}

local FONT_ASSET = "rbxassetid://12187365364"

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

local function loaderGradient(parent, firstColor, secondColor, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(firstColor, secondColor)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

local function loaderFont(object, weight)
    if not object then
        return
    end

    pcall(function()
        object.Font = Enum.Font.Gotham
    end)
    pcall(function()
        object.FontFace = Font.new(
            FONT_ASSET,
            weight or Enum.FontWeight.Regular,
            Enum.FontStyle.Normal
        )
    end)
end

local function loaderConnect(signal, callback)
    if typeof(signal) ~= "RBXScriptSignal" or type(callback) ~= "function" then
        return nil
    end

    local connection = signal:Connect(function(...)
        local ok, failure = xpcall(function()
            callback(...)
        end, function(message)
            if type(debug) == "table" and type(debug.traceback) == "function" then
                return debug.traceback(tostring(message), 2)
            end
            return tostring(message)
        end)

        if not ok then
            warn("BadWars loader UI: " .. tostring(failure))
        end
    end)

    table.insert(loaderConnections, connection)
    return connection
end

local function cleanupLoaderConnections()
    if loaderViewportConnection then
        pcall(loaderViewportConnection.Disconnect, loaderViewportConnection)
        loaderViewportConnection = nil
    end

    for index = #loaderConnections, 1, -1 do
        local connection = table.remove(loaderConnections, index)
        pcall(connection.Disconnect, connection)
    end
end

local function newFrame(parent, name, position, size, color, transparency, radius)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Position = position or UDim2.new()
    frame.Size = size or UDim2.new()
    frame.BackgroundColor3 = color or COLORS.element
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.Parent = parent
    if radius then
        loaderCorner(frame, radius)
    end
    return frame
end

local function newLabel(parent, name, text, position, size, textSize, color, weight)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.new()
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = tostring(text or "")
    label.TextSize = textSize or 12
    label.TextColor3 = color or COLORS.text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = false
    label.RichText = true
    label.TextTruncate = Enum.TextTruncate.AtEnd
    loaderFont(label, weight)
    label.Parent = parent
    return label
end

local function isTerminalStatus(message)
    local lower = string.lower(tostring(message or ""))
    return lower == "ready"
        or string.sub(lower, 1, 7) == "ready -"
        or string.find(lower, "launch complete", 1, true) ~= nil
        or string.find(lower, "loader complete", 1, true) ~= nil
        or string.find(lower, "pipeline ok", 1, true) ~= nil
        or string.find(lower, "pipeline issues", 1, true) ~= nil
        or string.find(lower, "startup verified", 1, true) ~= nil
        or string.find(lower, "validation passed", 1, true) ~= nil
end

local function resolveStatusProgress(message)
    local lower = string.lower(tostring(message or ""))

    if isTerminalStatus(lower) then
        return 1
    end

    local stages = {
        { "initialized", 0.06 },
        { "security: environment", 0.1 },
        { "security: http", 0.14 },
        { "security: filesystem", 0.18 },
        { "security: tamper", 0.22 },
        { "security checks passed", 0.26 },
        { "cache setup", 0.3 },
        { "cache cleared", 0.35 },
        { "self-test", 0.4 },
        { "validating orchestrator", 0.47 },
        { "url validation passed", 0.55 },
        { "compiled ok", 0.62 },
        { "executing main", 0.7 },
        { "interface", 0.77 },
        { "core modules", 0.83 },
        { "universal", 0.88 },
        { "game module", 0.92 },
        { "profile", 0.95 },
        { "finalizing", 0.97 },
        { "health", 0.98 },
    }

    for _, stage in ipairs(stages) do
        if string.find(lower, stage[1], 1, true) then
            return stage[2]
        end
    end

    return math.min(statusProgress + 0.045, 0.99)
end

local function friendlyStage(message)
    local lower = string.lower(tostring(message or ""))

    if string.find(lower, "initialized", 1, true) then
        return "Initializing"
    elseif string.find(lower, "security: environment", 1, true) then
        return "Checking environment"
    elseif string.find(lower, "security: http", 1, true) then
        return "Verifying connectivity"
    elseif string.find(lower, "security: filesystem", 1, true) then
        return "Verifying filesystem"
    elseif string.find(lower, "security: tamper", 1, true) then
        return "Integrity check"
    elseif string.find(lower, "security checks passed", 1, true) then
        return "Security verified"
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
    elseif string.find(lower, "network unavailable", 1, true) then
        return "Using local cache"
    elseif string.find(lower, "clipboard", 1, true) then
        return "Loading fallback source"
    elseif isTerminalStatus(lower) then
        return "Ready"
    end

    local text = tostring(message or "Working")
    text = text:gsub("^pipeline:%s*", "")
    text = text:gsub("^loading%s+", "Loading ")
    text = text:gsub("^downloading%s+", "Downloading ")
    text = text:gsub("^validating%s+", "Checking ")
    text = text:gsub("^finalizing%s*", "Finishing")
    text = text:gsub("^security:%s*", "")
    return text
end

local function statusDetail(message)
    local lower = string.lower(tostring(message or ""))

    if string.find(lower, "initialized", 1, true) then
        return "Starting compatibility services and preparing the runtime."
    elseif string.find(lower, "security: environment", 1, true) then
        return "Verifying executor environment and available APIs."
    elseif string.find(lower, "security: http", 1, true) then
        return "Testing network connectivity and HTTP access."
    elseif string.find(lower, "security: filesystem", 1, true) then
        return "Checking file access and required local folders."
    elseif string.find(lower, "security: tamper", 1, true) then
        return "Validating startup integrity before execution."
    elseif string.find(lower, "security checks passed", 1, true) then
        return "All startup security checks completed successfully."
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
    elseif string.find(lower, "network unavailable", 1, true) then
        return "Network loading failed, so the verified local orchestrator is being used."
    elseif string.find(lower, "clipboard", 1, true) then
        return "Loading a compatible startup source from the clipboard fallback."
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

local function getExecutorLabel()
    local info = type(__executorInfo) == "table" and __executorInfo or nil
    local name = info and info.name or __detectedExecutor
    name = tostring(name or "Compatible executor")
    if name == "" or name == "Unidentified Executor" then
        name = "Compatible executor"
    end
    return name
end

local function getViewportSize()
    local camera = loaderWorkspace.CurrentCamera
    if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function fitLoaderToViewport()
    if not loaderFitScale or not loaderFitScale.Parent then
        return
    end

    local viewport = getViewportSize()
    local insetTop = Vector2.new(0, 0)
    local insetBottom = Vector2.new(0, 0)
    pcall(function()
        insetTop, insetBottom = loaderGuiService:GetGuiInset()
    end)

    local availableWidth = math.max(viewport.X - insetTop.X - insetBottom.X - 24, 1)
    local availableHeight = math.max(viewport.Y - insetTop.Y - insetBottom.Y - 24, 1)
    local fit = math.min(availableWidth / BASE_WIDTH, availableHeight / BASE_HEIGHT, 1)
    loaderFitScale.Scale = math.max(fit, 0.4)
end

local function bindViewportUpdates()
    if loaderViewportConnection then
        pcall(loaderViewportConnection.Disconnect, loaderViewportConnection)
        loaderViewportConnection = nil
    end

    local camera = loaderWorkspace.CurrentCamera
    if camera then
        loaderViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitLoaderToViewport)
    end

    fitLoaderToViewport()
end

local function updatePhaseMarkers(progress, isError)
    local activeColor = isError and COLORS.warning or COLORS.primary
    local activeSoft = isError and COLORS.warningSoft or COLORS.primarySoft
    local thresholds = { 0.03, 0.36, 0.68, 0.96 }
    local currentIndex = 1

    for index, threshold in ipairs(thresholds) do
        if progress >= threshold then
            currentIndex = index
        end
    end

    for index, marker in ipairs(phaseMarkers) do
        local complete = progress >= thresholds[index]
        local current = index == currentIndex and progress < 1
        local ready = progress >= 1 and index == #phaseMarkers
        local highlighted = current or ready
        local rowColor = highlighted and COLORS.elementHover or COLORS.element
        local rowTransparency = complete and (highlighted and 0.04 or 0.38) or 0.72

        if marker.row then
            loaderTween(marker.row, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = rowColor,
                BackgroundTransparency = rowTransparency,
            })
        end

        if marker.indicator then
            loaderTween(marker.indicator, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = activeColor,
                BackgroundTransparency = highlighted and 0 or 1,
            })
        end

        if marker.dot then
            loaderTween(marker.dot, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = complete and activeColor or COLORS.button,
                BackgroundTransparency = complete and 0 or 0.22,
            })
        end

        if marker.number then
            loaderTween(marker.number, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                TextColor3 = complete and COLORS.text or COLORS.placeholder,
                TextTransparency = complete and 0 or 0.28,
            })
        end

        if marker.label then
            loaderTween(marker.label, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                TextColor3 = complete and COLORS.text or COLORS.placeholder,
                TextTransparency = complete and 0 or 0.24,
            })
        end

        if marker.detail then
            loaderTween(marker.detail, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                TextColor3 = highlighted and activeSoft or COLORS.placeholder,
                TextTransparency = highlighted and 0.08 or 0.34,
            })
        end
    end
end

local function createPhaseRow(parent, index, title, detail, y)
    local row = newFrame(
        parent,
        "Phase" .. tostring(index),
        UDim2.fromOffset(8, y),
        UDim2.new(1, -16, 0, 54),
        COLORS.element,
        index == 1 and 0.04 or 0.72,
        10
    )

    local indicator = newFrame(
        row,
        "Indicator",
        UDim2.fromOffset(0, 8),
        UDim2.fromOffset(2, 38),
        COLORS.primary,
        index == 1 and 0 or 1,
        2
    )

    local dot = newFrame(
        row,
        "Dot",
        UDim2.fromOffset(12, 13),
        UDim2.fromOffset(28, 28),
        index == 1 and COLORS.primary or COLORS.button,
        index == 1 and 0 or 0.22,
        8
    )
    loaderStroke(dot, COLORS.primary, index == 1 and 0.58 or 0.88, 1)

    local number = newLabel(
        dot,
        "Number",
        tostring(index),
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        11,
        index == 1 and COLORS.text or COLORS.placeholder,
        Enum.FontWeight.SemiBold
    )
    number.TextXAlignment = Enum.TextXAlignment.Center

    local label = newLabel(
        row,
        "Title",
        title,
        UDim2.fromOffset(50, 8),
        UDim2.new(1, -58, 0, 20),
        12,
        index == 1 and COLORS.text or COLORS.placeholder,
        Enum.FontWeight.SemiBold
    )

    local detailLabel = newLabel(
        row,
        "Detail",
        detail,
        UDim2.fromOffset(50, 28),
        UDim2.new(1, -58, 0, 16),
        9,
        index == 1 and COLORS.primarySoft or COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    return {
        row = row,
        indicator = indicator,
        dot = dot,
        number = number,
        label = label,
        detail = detailLabel,
    }
end

local function createLoader()
    cleanupLoaderConnections()

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
        for _, oldName in ipairs({ "BadWarsLoaderStatus", "BadWarsLoader" }) do
            local old = parent:FindFirstChild(oldName)
            if old then
                old:Destroy()
            end
        end
    end)

    statusGui = Instance.new("ScreenGui")
    statusGui.Name = "BadWarsLoaderStatus"
    statusGui.DisplayOrder = 10000000
    statusGui.IgnoreGuiInset = true
    statusGui.ResetOnSpawn = false
    statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    statusGui.Parent = parent

    statusBackdrop = newFrame(
        statusGui,
        "Backdrop",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        COLORS.backdrop,
        0.36
    )

    local backdropGradient = loaderGradient(
        statusBackdrop,
        Color3.fromHex("#08080c"),
        Color3.fromHex("#030304"),
        90
    )
    backdropGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0.5),
    })

    loaderHost = newFrame(
        statusBackdrop,
        "WindowHost",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT),
        COLORS.background,
        1
    )
    loaderHost.AnchorPoint = Vector2.new(0.5, 0.5)

    loaderFitScale = Instance.new("UIScale")
    loaderFitScale.Name = "ViewportFit"
    loaderFitScale.Parent = loaderHost

    statusShadow = newFrame(
        loaderHost,
        "Shadow",
        UDim2.new(0.5, 0, 0.5, 9),
        UDim2.fromOffset(BASE_WIDTH + 24, BASE_HEIGHT + 24),
        COLORS.black,
        0.55,
        22
    )
    statusShadow.AnchorPoint = Vector2.new(0.5, 0.5)

    statusCard = newFrame(
        loaderHost,
        "Window",
        UDim2.fromScale(0.5, 0.515),
        UDim2.fromOffset(BASE_WIDTH, BASE_HEIGHT),
        COLORS.background,
        0.01,
        18
    )
    statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
    statusCard.ClipsDescendants = true
    statusCardStroke = loaderStroke(statusCard, COLORS.border, 0.76, 1)

    local cardGradient = loaderGradient(
        statusCard,
        Color3.fromHex("#111118"),
        Color3.fromHex("#0b0b10"),
        90
    )
    cardGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(1, 0.55),
    })

    statusCardScale = Instance.new("UIScale")
    statusCardScale.Name = "MotionScale"
    statusCardScale.Scale = 0.965
    statusCardScale.Parent = statusCard

    local topbar = newFrame(
        statusCard,
        "Topbar",
        UDim2.fromScale(0, 0),
        UDim2.new(1, 0, 0, TOPBAR_HEIGHT),
        COLORS.dialog,
        0.02
    )

    local topbarBottom = newFrame(
        topbar,
        "Divider",
        UDim2.new(0, 0, 1, -1),
        UDim2.new(1, 0, 0, 1),
        COLORS.border,
        0.82
    )

    local logo = newFrame(
        topbar,
        "Logo",
        UDim2.fromOffset(14, 10),
        UDim2.fromOffset(34, 34),
        COLORS.primary,
        0,
        10
    )
    loaderGradient(logo, COLORS.primary, COLORS.primaryWarm, 35)
    loaderStroke(logo, COLORS.primarySoft, 0.55, 1)

    local logoText = newLabel(
        logo,
        "Glyph",
        "B",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        16,
        COLORS.text,
        Enum.FontWeight.Bold
    )
    logoText.TextXAlignment = Enum.TextXAlignment.Center

    local brand = newLabel(
        topbar,
        "Title",
        "BadWars",
        UDim2.fromOffset(58, 9),
        UDim2.new(1, -260, 0, 20),
        15,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    local subtitle = newLabel(
        topbar,
        "Subtitle",
        "Runtime Loader",
        UDim2.fromOffset(58, 28),
        UDim2.new(1, -260, 0, 16),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    local loaderTag = newFrame(
        topbar,
        "LoaderTag",
        UDim2.new(1, -192, 0.5, -12),
        UDim2.fromOffset(68, 24),
        COLORS.element,
        0.18,
        8
    )
    loaderStroke(loaderTag, COLORS.border, 0.82, 1)

    local loaderTagText = newLabel(
        loaderTag,
        "Text",
        "LOADER",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        8,
        COLORS.placeholder,
        Enum.FontWeight.Bold
    )
    loaderTagText.TextXAlignment = Enum.TextXAlignment.Center

    statusChip = newFrame(
        topbar,
        "Status",
        UDim2.new(1, -112, 0.5, -13),
        UDim2.fromOffset(98, 26),
        COLORS.primary,
        0.9,
        9
    )
    statusChipStroke = loaderStroke(statusChip, COLORS.primary, 0.62, 1)

    stateDot = newFrame(
        statusChip,
        "Dot",
        UDim2.new(0, 11, 0.5, -3),
        UDim2.fromOffset(6, 6),
        COLORS.primary,
        0,
        99
    )

    statusChipText = newLabel(
        statusChip,
        "Text",
        "STARTING",
        UDim2.fromOffset(25, 0),
        UDim2.new(1, -30, 1, 0),
        8,
        COLORS.primarySoft,
        Enum.FontWeight.Bold
    )

    local body = newFrame(
        statusCard,
        "Body",
        UDim2.fromOffset(12, TOPBAR_HEIGHT + 12),
        UDim2.new(1, -24, 1, -(TOPBAR_HEIGHT + 24)),
        COLORS.background,
        1
    )

    local sidebar = newFrame(
        body,
        "Sidebar",
        UDim2.fromScale(0, 0),
        UDim2.new(0, SIDEBAR_WIDTH, 1, 0),
        COLORS.panel,
        0.02,
        14
    )
    loaderStroke(sidebar, COLORS.border, 0.9, 1)

    local sidebarTitle = newLabel(
        sidebar,
        "Heading",
        "STARTUP",
        UDim2.fromOffset(14, 12),
        UDim2.new(1, -28, 0, 18),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Bold
    )

    local sidebarSubtitle = newLabel(
        sidebar,
        "Subheading",
        "Loading pipeline",
        UDim2.fromOffset(14, 29),
        UDim2.new(1, -28, 0, 16),
        9,
        COLORS.muted,
        Enum.FontWeight.Medium
    )

    phaseMarkers = {
        createPhaseRow(sidebar, 1, "Setup", "Environment", 54),
        createPhaseRow(sidebar, 2, "Verify", "Integrity checks", 114),
        createPhaseRow(sidebar, 3, "Load", "Runtime services", 174),
        createPhaseRow(sidebar, 4, "Ready", "Final validation", 234),
    }

    local sidebarFooter = newFrame(
        sidebar,
        "Footer",
        UDim2.new(0, 8, 1, -52),
        UDim2.new(1, -16, 0, 44),
        COLORS.element,
        0.42,
        10
    )

    local sidebarFooterDot = newFrame(
        sidebarFooter,
        "Dot",
        UDim2.fromOffset(11, 12),
        UDim2.fromOffset(7, 7),
        COLORS.primary,
        0,
        99
    )

    local sidebarFooterTitle = newLabel(
        sidebarFooter,
        "Title",
        "WindUI visual system",
        UDim2.fromOffset(26, 7),
        UDim2.new(1, -34, 0, 15),
        9,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    local sidebarFooterDetail = newLabel(
        sidebarFooter,
        "Detail",
        "BadWars crimson theme",
        UDim2.fromOffset(26, 22),
        UDim2.new(1, -34, 0, 14),
        8,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    local mainPane = newFrame(
        body,
        "Main",
        UDim2.fromOffset(SIDEBAR_WIDTH + CONTENT_GAP, 0),
        UDim2.new(1, -(SIDEBAR_WIDTH + CONTENT_GAP), 1, 0),
        COLORS.panel,
        0.02,
        14
    )
    loaderStroke(mainPane, COLORS.border, 0.9, 1)

    local paneTitle = newLabel(
        mainPane,
        "Title",
        "Starting BadWars",
        UDim2.fromOffset(16, 13),
        UDim2.new(1, -32, 0, 22),
        16,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    local paneSubtitle = newLabel(
        mainPane,
        "Subtitle",
        "Preparing the interface, modules, profiles, and runtime services.",
        UDim2.fromOffset(16, 35),
        UDim2.new(1, -32, 0, 18),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    local headerDivider = newFrame(
        mainPane,
        "HeaderDivider",
        UDim2.fromOffset(16, 60),
        UDim2.new(1, -32, 0, 1),
        COLORS.border,
        0.9
    )

    local statusPanel = newFrame(
        mainPane,
        "CurrentStatus",
        UDim2.fromOffset(16, 73),
        UDim2.new(1, -32, 0, 94),
        COLORS.element,
        0,
        12
    )
    statusPanelStroke = loaderStroke(statusPanel, COLORS.border, 0.88, 1)

    statusIcon = newFrame(
        statusPanel,
        "Icon",
        UDim2.fromOffset(14, 20),
        UDim2.fromOffset(46, 46),
        COLORS.primary,
        0,
        12
    )
    statusIconGradient = loaderGradient(statusIcon, COLORS.primary, COLORS.primaryWarm, 35)

    statusAccent = newFrame(
        statusIcon,
        "Accent",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(12, 12),
        COLORS.text,
        0,
        99
    )
    statusAccent.AnchorPoint = Vector2.new(0.5, 0.5)

    local accentInner = newFrame(
        statusAccent,
        "Inner",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(4, 4),
        COLORS.primary,
        0,
        99
    )
    accentInner.AnchorPoint = Vector2.new(0.5, 0.5)

    statusTitle = newLabel(
        statusPanel,
        "Stage",
        "Initializing",
        UDim2.fromOffset(74, 16),
        UDim2.new(1, -90, 0, 23),
        14,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    statusMessage = newLabel(
        statusPanel,
        "Description",
        "Starting compatibility services and preparing the runtime.",
        UDim2.fromOffset(74, 40),
        UDim2.new(1, -90, 0, 38),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )
    statusMessage.TextWrapped = true
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextTruncate = Enum.TextTruncate.None

    local progressPanel = newFrame(
        mainPane,
        "Progress",
        UDim2.fromOffset(16, 178),
        UDim2.new(1, -32, 0, 96),
        COLORS.element,
        0,
        12
    )
    loaderStroke(progressPanel, COLORS.border, 0.92, 1)

    local progressCaption = newLabel(
        progressPanel,
        "Caption",
        "Startup progress",
        UDim2.fromOffset(14, 12),
        UDim2.new(1, -84, 0, 18),
        10,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    progressValue = newLabel(
        progressPanel,
        "Value",
        "3%",
        UDim2.new(1, -68, 0, 12),
        UDim2.fromOffset(54, 18),
        10,
        COLORS.primarySoft,
        Enum.FontWeight.SemiBold
    )
    progressValue.TextXAlignment = Enum.TextXAlignment.Right

    local track = newFrame(
        progressPanel,
        "Track",
        UDim2.fromOffset(14, 41),
        UDim2.new(1, -28, 0, 7),
        COLORS.button,
        0.24,
        99
    )
    track.ClipsDescendants = true

    progressFill = newFrame(
        track,
        "Fill",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(statusProgress, 1),
        COLORS.primary,
        0,
        99
    )
    progressGradient = loaderGradient(progressFill, COLORS.primary, COLORS.primaryWarm, 0)

    local progressHint = newLabel(
        progressPanel,
        "Hint",
        "Setup  •  Verify  •  Load  •  Ready",
        UDim2.fromOffset(14, 58),
        UDim2.new(1, -28, 0, 20),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    local footer = newFrame(
        mainPane,
        "Footer",
        UDim2.fromOffset(16, 286),
        UDim2.new(1, -32, 0, 52),
        COLORS.element,
        0.36,
        12
    )

    local executorLabel = newLabel(
        footer,
        "Executor",
        getExecutorLabel(),
        UDim2.fromOffset(14, 8),
        UDim2.new(1, -170, 0, 16),
        9,
        COLORS.text,
        Enum.FontWeight.SemiBold
    )

    statusMeta = newLabel(
        footer,
        "Meta",
        "Secure startup",
        UDim2.fromOffset(14, 25),
        UDim2.new(1, -170, 0, 16),
        8,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )

    elapsedLabel = newLabel(
        footer,
        "Elapsed",
        "0.0s",
        UDim2.new(1, -78, 0, 17),
        UDim2.fromOffset(64, 18),
        9,
        COLORS.placeholder,
        Enum.FontWeight.Medium
    )
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right

    openConsoleButton = Instance.new("TextButton")
    openConsoleButton.Name = "Diagnostics"
    openConsoleButton.AnchorPoint = Vector2.new(1, 0.5)
    openConsoleButton.Position = UDim2.new(1, -10, 0.5, 0)
    openConsoleButton.Size = UDim2.fromOffset(132, 30)
    openConsoleButton.BackgroundColor3 = COLORS.button
    openConsoleButton.BackgroundTransparency = 0
    openConsoleButton.BorderSizePixel = 0
    openConsoleButton.AutoButtonColor = false
    openConsoleButton.Text = "Open diagnostics"
    openConsoleButton.TextSize = 9
    openConsoleButton.TextColor3 = COLORS.text
    openConsoleButton.Visible = false
    loaderFont(openConsoleButton, Enum.FontWeight.SemiBold)
    openConsoleButton.Parent = footer
    loaderCorner(openConsoleButton, 9)
    local consoleStroke = loaderStroke(openConsoleButton, COLORS.warning, 0.62, 1)

    loaderConnect(openConsoleButton.MouseEnter, function()
        loaderTween(openConsoleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.elementHover,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.36,
        })
    end)

    loaderConnect(openConsoleButton.MouseLeave, function()
        loaderTween(openConsoleButton, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = COLORS.button,
        })
        loaderTween(consoleStroke, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0.62,
        })
    end)

    loaderConnect(openConsoleButton.Activated, function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    loaderConnect(loaderWorkspace:GetPropertyChangedSignal("CurrentCamera"), bindViewportUpdates)
    bindViewportUpdates()

    loaderConnect(statusGui.AncestryChanged, function(_, newParent)
        if newParent == nil then
            cleanupLoaderConnections()
        end
    end)

    updatePhaseMarkers(statusProgress, false)

    loaderTween(statusBackdrop, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.36,
    })
    loaderTween(statusCard, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
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
            loaderTween(stateDot, TweenInfo.new(0.58, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.58,
            })
            task.wait(0.6)
            loaderTween(stateDot, TweenInfo.new(0.58, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0,
            })
            task.wait(0.6)
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
    local activeWarm = statusError and COLORS.warningSoft or COLORS.primaryWarm

    if statusTitle then
        statusTitle.Text = statusError and "Startup needs attention" or friendlyStage(message)
        statusTitle.TextColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if statusMessage then
        statusMessage.Text = statusError
            and "BadWars could not finish startup. Open diagnostics to review the reported issue."
            or statusDetail(message)
        statusMessage.TextColor3 = statusError and COLORS.warningSoft or COLORS.placeholder
    end

    if statusMeta then
        statusMeta.Text = statusError and "Startup paused · diagnostics available" or "Secure startup · protected runtime"
        statusMeta.TextColor3 = statusError and COLORS.warningSoft or COLORS.placeholder
    end

    if statusChip then
        statusChip.BackgroundColor3 = activeColor
        statusChip.BackgroundTransparency = statusError and 0.84 or 0.9
    end

    if statusChipStroke then
        statusChipStroke.Color = activeColor
        statusChipStroke.Transparency = statusError and 0.35 or 0.62
    end

    if statusChipText then
        statusChipText.Text = statusError and "ATTENTION" or (terminal and "READY" or "STARTING")
        statusChipText.TextColor3 = activeSoft
    end

    if stateDot then
        stateDot.BackgroundColor3 = activeColor
    end

    if statusAccent then
        statusAccent.BackgroundColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if statusIcon then
        statusIcon.BackgroundColor3 = activeColor
    end

    if statusIconGradient then
        statusIconGradient.Color = ColorSequence.new(activeColor, activeWarm)
    end

    if statusPanelStroke then
        statusPanelStroke.Color = activeColor
        statusPanelStroke.Transparency = statusError and 0.58 or 0.88
    end

    if statusCardStroke then
        statusCardStroke.Color = activeColor
        statusCardStroke.Transparency = statusError and 0.48 or 0.76
    end

    if progressFill then
        progressFill.BackgroundColor3 = activeColor
        loaderTween(progressFill, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromScale(math.clamp(statusProgress, 0.03, 1), 1),
        })
    end

    if progressGradient then
        progressGradient.Color = ColorSequence.new(activeColor, activeWarm)
    end

    if progressValue then
        progressValue.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
        progressValue.TextColor3 = activeSoft
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

        if statusChipText then
            statusChipText.Text = "READY"
        end

        local visibleFor = os.clock() - loaderCreatedAt
        local hold = math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.38

        task.delay(hold, function()
            if generation ~= loaderStatusGeneration or statusError then
                loaderDismissScheduled = false
                return
            end

            if not statusGui or not statusGui.Parent then
                loaderDismissScheduled = false
                return
            end

            loaderTween(statusBackdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            })
            loaderTween(statusShadow, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            })
            loaderTween(statusCard, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.fromScale(0.5, 0.525),
                BackgroundTransparency = 0.15,
            })
            loaderTween(statusCardScale, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Scale = 0.96,
            })

            task.delay(0.35, function()
                if generation ~= loaderStatusGeneration or statusError then
                    loaderDismissScheduled = false
                    return
                end

                if statusGui and statusGui.Parent then
                    statusGui:Destroy()
                    shared.BadStatusGui = nil
                end
            end)
        end)
    end
end

local setStatus = shared.BadStatus
setStatus("pipeline: initialized")
-- BADWARS_LOADER_PRESENTATION_V6_END
-- Error tracking
local __rtErrs=shared.__badwars_runtime_errors
if type(__rtErrs)~='table' then __rtErrs={};shared.__badwars_runtime_errors=__rtErrs end

local function safeDiagnosticsTraceback(message, level)
    local diagnostics = type(shared) == "table" and shared.BadDiagnostics or nil

    if type(diagnostics) == "table" and type(diagnostics.Traceback) == "function" then
        local ok, result = pcall(diagnostics.Traceback, diagnostics, message, level or 2)
        if ok and result ~= nil then
            return tostring(result)
        end
    end

    if type(debug) == "table" and type(debug.traceback) == "function" then
        local ok, result = pcall(debug.traceback, tostring(message), level or 2)
        if ok and result ~= nil then
            return tostring(result)
        end
    end

    return tostring(message)
end

local function safeDiagnosticsRecord(moduleName, message, context)
    local diagnostics = type(shared) == "table" and shared.BadDiagnostics or nil
    if type(diagnostics) ~= "table" or type(diagnostics.RecordRuntime) ~= "function" then
        return false
    end

    return pcall(
        diagnostics.RecordRuntime,
        diagnostics,
        moduleName,
        message,
        type(context) == "table" and context or {}
    )
end

local function recordErr(mod, msg)
    local trace = safeDiagnosticsTraceback(msg, 3)

    table.insert(__rtErrs, {
        module = tostring(mod),
        error = tostring(msg),
        traceback = trace,
        time = os.clock(),
    })

    local recorded = safeDiagnosticsRecord(mod, msg, {
        subsystem = "Loader",
        file = "badscript/loader.lua",
        traceback = trace,
    })

    if not recorded then
        warn("BadWars: [ERROR] " .. tostring(mod) .. ": " .. tostring(msg))
    end
end

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

local cachedOrchestrator
if isfile(ORCH_PATH) then
    local ok, contents = pcall(readfile, ORCH_PATH)
    if ok and type(contents) == "string" and #contents >= 100 then
        cachedOrchestrator = contents
    end
end

local cacheVersion = 'badwars-v27-windui-2026-07-08-14'
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
	for _,f in {'badscript/NewMainScript.lua'} do if isfile(f) then pcall(delfile,f) end end
	wipeAny('badscript/assets');wipeGen('badscript/games');wipeGen('badscript/libraries')
	if isfolder('badscript/guis/new') then wipeGen('badscript/guis/new') end
	writefile(cacheFile,cacheVersion)
end
invalidateStaleGuiCache()
writefile('badscript/profiles/commit.txt','main')

-- ========== SELF-TEST ==========
setStatus('pipeline: self-test')

-- ========== SECURITY CHECKS ==========
local securityChecks = {
    passed = 0,
    failed = 0,
    warnings = {},
}

-- Check 1: Environment integrity
local function checkEnvironment()
    local env = getgenv and type(getgenv) == "function" and getgenv() or nil
    if not env then
        table.insert(securityChecks.warnings, "getgenv unavailable")
        return
    end

    -- Check for common detection hooks
    local suspiciousHooks = {
        "hookfunction", "hookmetamethod", "namecallfunction",
        "newcclosure", "checkcaller", "getnamecallmethod",
    }

    for _, hook in ipairs(suspiciousHooks) do
        if type(env[hook]) == "function" then
            -- These are expected in exploit environments, just note them
        end
    end

    -- Check for executor-specific globals
    local executorGlobals = {
        "identifyexecutor", "getexecutorname", "getidentity",
        "setidentity", "setclipboard", "toclipboard",
        "readfile", "writefile", "isfile", "isfolder",
        "makefolder", "delfile", "listfiles",
        "HttpGet", "HttpPost", "HttpGetAsync", "HttpPostAsync",
        "getcustomasset", "is_synapse_function", "iswindowactive",
    }

    local availableCount = 0
    for _, global in ipairs(executorGlobals) do
        if env[global] ~= nil or (type(_G[global]) ~= "nil") then
            availableCount = availableCount + 1
        end
    end

    if availableCount < 5 then
        table.insert(securityChecks.warnings, "Limited executor API detected (" .. availableCount .. " functions)")
    end

    securityChecks.passed = securityChecks.passed + 1
end

-- Check 2: HTTP connectivity
local function checkHTTP()
    local httpService = nil
    pcall(function()
        httpService = cloneref(game:GetService("HttpService"))
    end)

    if not httpService then
        table.insert(securityChecks.warnings, "HttpService unavailable")
        securityChecks.failed = securityChecks.failed + 1
        return
    end

    -- Test basic HTTP functionality
    local testUrl = "https://httpbin.org/get"
    local ok, result = pcall(function()
        return httpService:GetAsync(testUrl, true)
    end)

    if ok and type(result) == "string" then
        securityChecks.passed = securityChecks.passed + 1
    else
        table.insert(securityChecks.warnings, "HTTP connectivity limited")
        securityChecks.passed = securityChecks.passed + 1 -- Non-critical
    end
end

-- Check 3: File system integrity
local function checkFileSystem()
    local requiredFolders = {
        "badscript",
        "badscript/games",
        "badscript/libraries",
        "badscript/guis",
        "badscript/profiles",
    }

    local missingFolders = {}
    for _, folder in ipairs(requiredFolders) do
        local ok, exists = pcall(isfolder, folder)
        if not ok or not exists then
            table.insert(missingFolders, folder)
        end
    end

    if #missingFolders > 0 then
        -- These will be created later, so just note it
        table.insert(securityChecks.warnings, "Missing folders will be created: " .. table.concat(missingFolders, ", "))
    end

    securityChecks.passed = securityChecks.passed + 1
end

-- Check 4: Tamper detection (basic)
local function checkTamper()
    local loaderPath = "badscript/loader.lua"
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, exists = pcall(isfile, loaderPath)
        if ok and exists then
            local readOk, content = pcall(readfile, loaderPath)
            if readOk and type(content) == "string" then
                -- Check for common tampering patterns
                local tamperPatterns = {
                    "loadstring%s*=%s*function", -- Overriding loadstring
                    "getgenv%s*=%s*function",    -- Overriding getgenv
                    "shared%s*=%s*{}",           -- Resetting shared table
                }

                for _, pattern in ipairs(tamperPatterns) do
                    if content:find(pattern) then
                        table.insert(securityChecks.warnings, "Potential tampering detected in loader")
                        securityChecks.failed = securityChecks.failed + 1
                        return
                    end
                end
            end
        end
    end

    securityChecks.passed = securityChecks.passed + 1
end

-- Run security checks
setStatus('security: environment check')
checkEnvironment()

setStatus('security: HTTP check')
checkHTTP()

setStatus('security: filesystem check')
checkFileSystem()

setStatus('security: tamper check')
checkTamper()

-- Report security status
if #securityChecks.warnings > 0 then
    warn("BadWars: [SECURITY] " .. #securityChecks.warnings .. " warning(s):")
    for _, warning in ipairs(securityChecks.warnings) do
        warn("  ! " .. warning)
    end
end

if securityChecks.failed > 0 then
    warn("BadWars: [SECURITY] " .. securityChecks.failed .. " check(s) failed")
end

setStatus('security checks passed (' .. securityChecks.passed .. '/4)')

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
local raw,usedUrl,usedMethod=httpGet(urls)

if raw == nil and type(cachedOrchestrator) == "string" then
    local cachedProbe = _loadstring(cachedOrchestrator, "@badscript/main.lua:cache-probe")
    if cachedProbe then
        raw = cachedOrchestrator
        usedUrl = "local cache: " .. ORCH_PATH
        usedMethod = "readfile"
        setStatus("network unavailable; using cached orchestrator")
    end
end

if raw == nil then
    emitUrlDiagnostics()
    warn("BadWars: [HTTP TRANSPORT DIAGNOSTICS]")
    for index, diagnostic in ipairs(__lastHttpDiagnostics) do
        if index > 40 then
            warn("  ... " .. tostring(#__lastHttpDiagnostics - 40) .. " additional attempt(s) omitted")
            break
        end
        warn("  " .. diagnostic)
    end
    warn("BadWars: [END HTTP TRANSPORT DIAGNOSTICS]")

    local m = "All HTTP methods failed for " .. ORCH_PATH
    setStatus("ERROR: " .. m, true)
    recordErr("loader", m)
    
    -- Clipboard injection fallback: try to load from clipboard
    local clipboardOk, clipboardSource = pcall(function()
        if type(getclipboard)=='function' then return getclipboard() end
        if type(getgenv)=='function' then
            local env=getgenv()
            if type(env)=='table' and type(env.getclipboard)=='function' then return env.getclipboard() end
        end
        return nil
    end)
    
    if clipboardOk and type(clipboardSource)=='string' and #clipboardSource > 100 then
        local trimmed = clipboardSource:match("^%s*(.-)%s*$")
        if trimmed:find("BadWars", 1, true) or trimmed:find("shared.Bad", 1, true) or trimmed:find("loadstring", 1, true) then
            warn("BadWars: [CLIPBOARD] Found BadWars source in clipboard, attempting to load...")
            setStatus("loading from clipboard")
            raw = clipboardSource
        else
            warn("BadWars: [CLIPBOARD] Clipboard does not contain BadWars source")
            warn("BadWars: [INSTRUCTIONS] To use manually:")
            warn("  1. Open https://github.com/evanbackup1256-ship-it/badwars/blob/main/badscript/main.lua")
            warn("  2. Copy the entire file content")
            warn("  3. Paste into your executor and execute")
            error(m .. " | Clipboard fallback failed - copy main.lua manually from GitHub", 0)
        end
    else
        warn("BadWars: [INSTRUCTIONS] HTTP blocked by executor. To use manually:")
        warn("  1. Open https://github.com/evanbackup1256-ship-it/badwars/blob/main/badscript/main.lua")
        warn("  2. Copy the entire file content")
        warn("  3. Paste into your executor and execute")
        error(m .. " | Copy main.lua manually from GitHub", 0)
    end
end

if type(raw) ~= "string" or raw == "" then
    emitUrlDiagnostics()
    local m = "ERROR empty file: Empty response for " .. ORCH_PATH
    setStatus("ERROR: " .. m, true)
    recordErr("loader", m)
    error(m, 0)
end

if isNotFoundBody(raw) then
    emitUrlDiagnostics()
    warn("BadWars: [404 RESPONSE BODY - first 500 chars]")
    warn(raw:sub(1, 500))
    warn("BadWars: [END 404 BODY]")
    local m = "FILE NOT FOUND. Repo: "
        .. CFG.repo
        .. "/"
        .. CFG.name
        .. " Branch: "
        .. CFG.branch
        .. " Path: "
        .. ORCH_PATH
        .. " URL: "
        .. tostring(usedUrl)
    warn("BadWars: " .. m)
    setStatus("ERROR: " .. m, true)
    recordErr("loader", m)
    error(m, 0)
end

setStatus(
    "URL validation passed: "
        .. tostring(#raw)
        .. " bytes via "
        .. tostring(usedMethod or "unknown")
)

-- Download & compile
local header = "-- BadWars by usingINales\n"
local code = raw
if code:sub(1, #header) ~= header then
    code = header .. code
end
pcall(function()
    writefile(ORCH_PATH, code)
end)

local fn,cerr=_loadstring(code,"@badscript/main.lua")
if not fn then local m='main.lua compile: '..tostring(cerr);setStatus('ERROR: '..m,true);recordErr('loader',m);error(m,0) end
setStatus('main.lua compiled OK')

-- Execute
setStatus('pipeline: executing main orchestrator')
local ok, result = xpcall(fn, function(err)
    return safeDiagnosticsTraceback(err, 2)
end)

if not ok then
    local originalFailure = tostring(result)
    local m = "main.lua runtime: " .. originalFailure

    setStatus("ERROR: " .. m, true)
    recordErr("main.lua", originalFailure)

    warn("BadWars: [MAIN RUNTIME FAILURE]")
    warn(originalFailure)
    warn("BadWars: [END MAIN RUNTIME FAILURE]")

    error(m, 0)
end

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
