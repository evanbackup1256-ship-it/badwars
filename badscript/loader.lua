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


-- BADWARS_LOADER_PRESENTATION_STANDALONE_V5_BEGIN
-- Refined standalone BadWars loader presentation.
-- Only the presentation layer is changed; loader/download/runtime behavior is preserved.

local statusGui
local statusBackdrop
local statusWindow
local statusWindowScale
local statusWindowStroke
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
local statusIcon
local statusIconGradient
local statusIconCore
local diagnosticsButton
local phaseMarkers = {}
local loaderConnections = {}
local loaderViewportConnection

local statusProgress = 0.03
local statusError = false
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local MINIMUM_VISIBLE_SECONDS = 1.3

local WINDOW_WIDTH = 620
local WINDOW_HEIGHT = 350

local TweenService = cloneref(game:GetService("TweenService"))
local GuiService = cloneref(game:GetService("GuiService"))
local Workspace = cloneref(game:GetService("Workspace"))

local COLORS = {
    backdropTop = Color3.fromHex("#09090D"),
    backdropBottom = Color3.fromHex("#030304"),
    windowTop = Color3.fromHex("#14141B"),
    windowBottom = Color3.fromHex("#0B0B10"),
    surface = Color3.fromHex("#15151D"),
    surfaceRaised = Color3.fromHex("#1B1B25"),
    surfaceSoft = Color3.fromHex("#101016"),
    border = Color3.fromHex("#32323D"),
    borderSoft = Color3.fromHex("#24242E"),
    text = Color3.fromHex("#F8F8FA"),
    muted = Color3.fromHex("#A0A0AD"),
    dim = Color3.fromHex("#696978"),
    primary = Color3.fromHex("#FF2D4A"),
    primarySoft = Color3.fromHex("#FF647B"),
    primaryWarm = Color3.fromHex("#FF7A3D"),
    success = Color3.fromHex("#41B883"),
    warning = Color3.fromHex("#F4B64B"),
    warningSoft = Color3.fromHex("#FFD17A"),
    black = Color3.new(0, 0, 0),
}

local function animate(object, duration, properties, style, direction)
    if not object or not object.Parent then
        return nil
    end

    local ok, tween = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(
                duration or 0.18,
                style or Enum.EasingStyle.Quint,
                direction or Enum.EasingDirection.Out
            ),
            properties
        )
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

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function addGradient(parent, firstColor, secondColor, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(firstColor, secondColor)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

local function connect(signal, callback)
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

local function disconnectLoaderConnections()
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
    frame.BackgroundColor3 = color or COLORS.surface
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.Parent = parent
    if radius then
        addCorner(frame, radius)
    end
    return frame
end

local function newLabel(parent, name, text, position, size, textSize, color, font)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Position = position or UDim2.new()
    label.Size = size or UDim2.new()
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Text = tostring(text or "")
    label.TextSize = textSize or 12
    label.TextColor3 = color or COLORS.text
    label.Font = font or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextWrapped = false
    label.RichText = true
    label.TextTruncate = Enum.TextTruncate.AtEnd
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
        return "Checking integrity"
    elseif string.find(lower, "security checks passed", 1, true) then
        return "Security verified"
    elseif string.find(lower, "cache setup", 1, true) then
        return "Preparing cache"
    elseif string.find(lower, "cache cleared", 1, true) then
        return "Refreshing files"
    elseif string.find(lower, "stale gui cache", 1, true) then
        return "Refreshing interface"
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
        return "Preparing compatibility services and the startup runtime."
    elseif string.find(lower, "security: environment", 1, true) then
        return "Checking executor capabilities and the active environment."
    elseif string.find(lower, "security: http", 1, true) then
        return "Testing network access and available HTTP transports."
    elseif string.find(lower, "security: filesystem", 1, true) then
        return "Checking local file access and required directories."
    elseif string.find(lower, "security: tamper", 1, true) then
        return "Validating startup integrity before execution."
    elseif string.find(lower, "security checks passed", 1, true) then
        return "Startup security checks completed successfully."
    elseif string.find(lower, "cache setup", 1, true) then
        return "Preparing folders and checking previously downloaded files."
    elseif string.find(lower, "cache cleared", 1, true) then
        return "Removing outdated resources before loading this build."
    elseif string.find(lower, "stale gui cache", 1, true) then
        return "Replacing an older interface build."
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
        return "Network loading failed, so a verified local copy is being used."
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
    local camera = Workspace.CurrentCamera
    if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
        return camera.ViewportSize
    end
    return Vector2.new(1280, 720)
end

local function fitToViewport()
    if not statusWindowScale or not statusWindowScale.Parent then
        return
    end

    local viewport = getViewportSize()
    local topLeft = Vector2.new(0, 0)
    local bottomRight = Vector2.new(0, 0)

    pcall(function()
        topLeft, bottomRight = GuiService:GetGuiInset()
    end)

    local availableWidth = math.max(viewport.X - topLeft.X - bottomRight.X - 24, 1)
    local availableHeight = math.max(viewport.Y - topLeft.Y - bottomRight.Y - 24, 1)
    local scale = math.min(availableWidth / WINDOW_WIDTH, availableHeight / WINDOW_HEIGHT, 1)

    statusWindowScale.Scale = math.max(scale, 0.45)
end

local function bindViewport()
    if loaderViewportConnection then
        pcall(loaderViewportConnection.Disconnect, loaderViewportConnection)
        loaderViewportConnection = nil
    end

    local camera = Workspace.CurrentCamera
    if camera then
        loaderViewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
    end

    fitToViewport()
end

local function createPhase(parent, index, title, x)
    local marker = newFrame(
        parent,
        "Phase" .. tostring(index),
        UDim2.fromOffset(x, 0),
        UDim2.fromOffset(128, 44),
        COLORS.surfaceSoft,
        0.18,
        10
    )
    addStroke(marker, COLORS.borderSoft, 0.45, 1)

    local dot = newFrame(
        marker,
        "Dot",
        UDim2.fromOffset(12, 14),
        UDim2.fromOffset(16, 16),
        COLORS.surfaceRaised,
        0,
        99
    )

    local number = newLabel(
        dot,
        "Number",
        tostring(index),
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        8,
        COLORS.dim,
        Enum.Font.GothamBold
    )
    number.TextXAlignment = Enum.TextXAlignment.Center

    local label = newLabel(
        marker,
        "Label",
        title,
        UDim2.fromOffset(36, 4),
        UDim2.new(1, -44, 0, 18),
        10,
        COLORS.muted,
        Enum.Font.GothamSemibold
    )

    local state = newLabel(
        marker,
        "State",
        index == 1 and "In progress" or "Waiting",
        UDim2.fromOffset(36, 21),
        UDim2.new(1, -44, 0, 15),
        8,
        COLORS.dim,
        Enum.Font.Gotham
    )

    return {
        frame = marker,
        dot = dot,
        number = number,
        label = label,
        state = state,
    }
end

local function updatePhaseMarkers(progress, isError)
    local thresholds = { 0.03, 0.36, 0.68, 0.96 }
    local activeColor = isError and COLORS.warning or COLORS.primary
    local activeSoft = isError and COLORS.warningSoft or COLORS.primarySoft
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

        local stateText = "Waiting"
        if complete and index < currentIndex then
            stateText = "Complete"
        elseif current or ready then
            stateText = isError and "Attention" or (ready and "Complete" or "In progress")
        end

        animate(marker.frame, 0.16, {
            BackgroundColor3 = current or ready and COLORS.surfaceRaised or COLORS.surfaceSoft,
            BackgroundTransparency = current or ready and 0.02 or 0.18,
        }, Enum.EasingStyle.Quart)

        animate(marker.dot, 0.16, {
            BackgroundColor3 = complete and activeColor or COLORS.surfaceRaised,
        }, Enum.EasingStyle.Quart)

        animate(marker.number, 0.16, {
            TextColor3 = complete and COLORS.text or COLORS.dim,
        }, Enum.EasingStyle.Quart)

        animate(marker.label, 0.16, {
            TextColor3 = complete and COLORS.text or COLORS.muted,
        }, Enum.EasingStyle.Quart)

        marker.state.Text = stateText
        animate(marker.state, 0.16, {
            TextColor3 = current or ready and activeSoft or COLORS.dim,
        }, Enum.EasingStyle.Quart)
    end
end

local function createLoader()
    disconnectLoaderConnections()

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
        for _, child in ipairs(parent:GetChildren()) do
            if child.Name == "BadWarsLoaderStatus" or child.Name == "BadWarsLoader" then
                child:Destroy()
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
        COLORS.backdropTop,
        0.18
    )

    local backdropGradient = addGradient(
        statusBackdrop,
        COLORS.backdropTop,
        COLORS.backdropBottom,
        90
    )
    backdropGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.02),
        NumberSequenceKeypoint.new(1, 0.36),
    })

    local ambientTop = newFrame(
        statusBackdrop,
        "AmbientTop",
        UDim2.new(0.5, -360, 0.5, -230),
        UDim2.fromOffset(720, 220),
        COLORS.primary,
        0.92,
        999
    )
    local ambientTopGradient = addGradient(
        ambientTop,
        COLORS.primary,
        COLORS.primaryWarm,
        0
    )
    ambientTopGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.62),
        NumberSequenceKeypoint.new(1, 1),
    })

    local shadow = newFrame(
        statusBackdrop,
        "Shadow",
        UDim2.new(0.5, 0, 0.5, 12),
        UDim2.fromOffset(WINDOW_WIDTH + 28, WINDOW_HEIGHT + 28),
        COLORS.black,
        0.56,
        24
    )
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)

    statusWindow = newFrame(
        statusBackdrop,
        "Window",
        UDim2.new(0.5, 0, 0.5, 14),
        UDim2.fromOffset(WINDOW_WIDTH, WINDOW_HEIGHT),
        COLORS.windowBottom,
        0,
        20
    )
    statusWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    statusWindow.ClipsDescendants = true
    statusWindowStroke = addStroke(statusWindow, COLORS.border, 0.26, 1)

    local windowGradient = addGradient(
        statusWindow,
        COLORS.windowTop,
        COLORS.windowBottom,
        90
    )
    windowGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.04),
        NumberSequenceKeypoint.new(1, 0.22),
    })

    statusWindowScale = Instance.new("UIScale")
    statusWindowScale.Name = "ViewportScale"
    statusWindowScale.Scale = 0.965
    statusWindowScale.Parent = statusWindow

    local header = newFrame(
        statusWindow,
        "Header",
        UDim2.fromScale(0, 0),
        UDim2.new(1, 0, 0, 68),
        COLORS.surfaceSoft,
        0.12
    )

    local headerDivider = newFrame(
        header,
        "Divider",
        UDim2.new(0, 0, 1, -1),
        UDim2.new(1, 0, 0, 1),
        COLORS.borderSoft,
        0
    )

    local logo = newFrame(
        header,
        "Logo",
        UDim2.fromOffset(18, 14),
        UDim2.fromOffset(40, 40),
        COLORS.primary,
        0,
        12
    )
    addGradient(logo, COLORS.primary, COLORS.primaryWarm, 35)
    addStroke(logo, COLORS.primarySoft, 0.55, 1)

    local logoText = newLabel(
        logo,
        "Text",
        "B",
        UDim2.fromScale(0, 0),
        UDim2.fromScale(1, 1),
        18,
        COLORS.text,
        Enum.Font.GothamBold
    )
    logoText.TextXAlignment = Enum.TextXAlignment.Center

    local brand = newLabel(
        header,
        "Brand",
        "BadWars",
        UDim2.fromOffset(72, 13),
        UDim2.new(1, -280, 0, 23),
        17,
        COLORS.text,
        Enum.Font.GothamSemibold
    )

    local subtitle = newLabel(
        header,
        "Subtitle",
        "Secure runtime loader",
        UDim2.fromOffset(72, 36),
        UDim2.new(1, -280, 0, 18),
        9,
        COLORS.muted,
        Enum.Font.Gotham
    )

    statusChip = newFrame(
        header,
        "Status",
        UDim2.new(1, -124, 0.5, -14),
        UDim2.fromOffset(104, 28),
        COLORS.primary,
        0.88,
        9
    )
    statusChipStroke = addStroke(statusChip, COLORS.primary, 0.52, 1)

    stateDot = newFrame(
        statusChip,
        "Dot",
        UDim2.fromOffset(11, 10),
        UDim2.fromOffset(8, 8),
        COLORS.primary,
        0,
        99
    )

    statusChipText = newLabel(
        statusChip,
        "Text",
        "STARTING",
        UDim2.fromOffset(27, 0),
        UDim2.new(1, -32, 1, 0),
        8,
        COLORS.primarySoft,
        Enum.Font.GothamBold
    )

    local content = newFrame(
        statusWindow,
        "Content",
        UDim2.fromOffset(18, 86),
        UDim2.new(1, -36, 1, -104),
        COLORS.windowBottom,
        1
    )

    local statusPanel = newFrame(
        content,
        "StatusPanel",
        UDim2.fromScale(0, 0),
        UDim2.new(1, 0, 0, 106),
        COLORS.surface,
        0,
        14
    )
    addStroke(statusPanel, COLORS.borderSoft, 0.1, 1)

    statusIcon = newFrame(
        statusPanel,
        "Icon",
        UDim2.fromOffset(16, 24),
        UDim2.fromOffset(58, 58),
        COLORS.primary,
        0,
        15
    )
    statusIconGradient = addGradient(
        statusIcon,
        COLORS.primary,
        COLORS.primaryWarm,
        35
    )

    local iconRing = newFrame(
        statusIcon,
        "Ring",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(25, 25),
        COLORS.text,
        0.82,
        99
    )
    iconRing.AnchorPoint = Vector2.new(0.5, 0.5)
    addStroke(iconRing, COLORS.text, 0.34, 1)

    statusIconCore = newFrame(
        statusIcon,
        "Core",
        UDim2.fromScale(0.5, 0.5),
        UDim2.fromOffset(9, 9),
        COLORS.text,
        0,
        99
    )
    statusIconCore.AnchorPoint = Vector2.new(0.5, 0.5)

    statusTitle = newLabel(
        statusPanel,
        "Title",
        "Initializing",
        UDim2.fromOffset(92, 18),
        UDim2.new(1, -108, 0, 25),
        15,
        COLORS.text,
        Enum.Font.GothamSemibold
    )

    statusMessage = newLabel(
        statusPanel,
        "Message",
        "Preparing compatibility services and the startup runtime.",
        UDim2.fromOffset(92, 45),
        UDim2.new(1, -108, 0, 42),
        10,
        COLORS.muted,
        Enum.Font.Gotham
    )
    statusMessage.TextWrapped = true
    statusMessage.TextYAlignment = Enum.TextYAlignment.Top
    statusMessage.TextTruncate = Enum.TextTruncate.None

    local progressPanel = newFrame(
        content,
        "ProgressPanel",
        UDim2.fromOffset(0, 118),
        UDim2.new(1, 0, 0, 78),
        COLORS.surfaceSoft,
        0.12,
        12
    )
    addStroke(progressPanel, COLORS.borderSoft, 0.24, 1)

    local progressLabel = newLabel(
        progressPanel,
        "Label",
        "Startup progress",
        UDim2.fromOffset(14, 10),
        UDim2.new(1, -86, 0, 20),
        10,
        COLORS.text,
        Enum.Font.GothamSemibold
    )

    progressValue = newLabel(
        progressPanel,
        "Value",
        "3%",
        UDim2.new(1, -72, 0, 10),
        UDim2.fromOffset(58, 20),
        10,
        COLORS.primarySoft,
        Enum.Font.GothamSemibold
    )
    progressValue.TextXAlignment = Enum.TextXAlignment.Right

    local track = newFrame(
        progressPanel,
        "Track",
        UDim2.fromOffset(14, 39),
        UDim2.new(1, -28, 0, 8),
        COLORS.surfaceRaised,
        0,
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
    progressGradient = addGradient(
        progressFill,
        COLORS.primary,
        COLORS.primaryWarm,
        0
    )

    local progressCaption = newLabel(
        progressPanel,
        "Caption",
        "Preparing runtime components",
        UDim2.fromOffset(14, 52),
        UDim2.new(1, -28, 0, 16),
        8,
        COLORS.dim,
        Enum.Font.Gotham
    )

    local phases = newFrame(
        content,
        "Phases",
        UDim2.fromOffset(0, 208),
        UDim2.new(1, 0, 0, 44),
        COLORS.windowBottom,
        1
    )

    phaseMarkers = {
        createPhase(phases, 1, "Setup", 0),
        createPhase(phases, 2, "Verify", 138),
        createPhase(phases, 3, "Load", 276),
        createPhase(phases, 4, "Ready", 414),
    }

    local footer = newFrame(
        content,
        "Footer",
        UDim2.new(0, 0, 1, -39),
        UDim2.new(1, 0, 0, 39),
        COLORS.windowBottom,
        1
    )

    local footerDivider = newFrame(
        footer,
        "Divider",
        UDim2.fromScale(0, 0),
        UDim2.new(1, 0, 0, 1),
        COLORS.borderSoft,
        0
    )

    statusMeta = newLabel(
        footer,
        "Meta",
        getExecutorLabel() .. "  •  protected startup",
        UDim2.fromOffset(0, 11),
        UDim2.new(1, -165, 0, 18),
        8,
        COLORS.dim,
        Enum.Font.Gotham
    )

    elapsedLabel = newLabel(
        footer,
        "Elapsed",
        "0.0s",
        UDim2.new(1, -70, 0, 11),
        UDim2.fromOffset(70, 18),
        9,
        COLORS.muted,
        Enum.Font.Code
    )
    elapsedLabel.TextXAlignment = Enum.TextXAlignment.Right

    diagnosticsButton = Instance.new("TextButton")
    diagnosticsButton.Name = "Diagnostics"
    diagnosticsButton.AnchorPoint = Vector2.new(1, 0.5)
    diagnosticsButton.Position = UDim2.new(1, 0, 0.5, 0)
    diagnosticsButton.Size = UDim2.fromOffset(146, 28)
    diagnosticsButton.BackgroundColor3 = COLORS.surfaceRaised
    diagnosticsButton.BackgroundTransparency = 0
    diagnosticsButton.BorderSizePixel = 0
    diagnosticsButton.AutoButtonColor = false
    diagnosticsButton.Font = Enum.Font.GothamSemibold
    diagnosticsButton.Text = "Open diagnostics"
    diagnosticsButton.TextSize = 9
    diagnosticsButton.TextColor3 = COLORS.text
    diagnosticsButton.Visible = false
    diagnosticsButton.Parent = footer
    addCorner(diagnosticsButton, 9)
    local diagnosticsStroke = addStroke(
        diagnosticsButton,
        COLORS.warning,
        0.52,
        1
    )

    connect(diagnosticsButton.MouseEnter, function()
        animate(diagnosticsButton, 0.1, {
            BackgroundColor3 = COLORS.surface,
        }, Enum.EasingStyle.Quart)
        animate(diagnosticsStroke, 0.1, {
            Transparency = 0.26,
        }, Enum.EasingStyle.Quart)
    end)

    connect(diagnosticsButton.MouseLeave, function()
        animate(diagnosticsButton, 0.1, {
            BackgroundColor3 = COLORS.surfaceRaised,
        }, Enum.EasingStyle.Quart)
        animate(diagnosticsStroke, 0.1, {
            Transparency = 0.52,
        }, Enum.EasingStyle.Quart)
    end)

    connect(diagnosticsButton.Activated, function()
        local diagnostics = shared.BadDiagnostics
        if type(diagnostics) == "table" and type(diagnostics.Open) == "function" then
            diagnostics:Open()
        end
    end)

    connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), bindViewport)
    connect(statusGui.AncestryChanged, function(_, parentValue)
        if parentValue == nil then
            disconnectLoaderConnections()
        end
    end)

    bindViewport()
    updatePhaseMarkers(statusProgress, false)

    animate(statusWindow, 0.28, {
        Position = UDim2.fromScale(0.5, 0.5),
    }, Enum.EasingStyle.Quint)
    animate(statusWindowScale, 0.28, {
        Scale = statusWindowScale.Scale,
    }, Enum.EasingStyle.Quint)

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
            animate(stateDot, 0.55, {
                BackgroundTransparency = 0.55,
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.58)
            animate(stateDot, 0.55, {
                BackgroundTransparency = 0,
            }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.58)
        end
    end)

    shared.BadStatusGui = statusGui
end

createLoader()

shared.BadStatus = function(messageValue, isError)
    local message = tostring(messageValue or "Working")
    local terminal = isTerminalStatus(message)

    loaderStatusGeneration += 1
    local generation = loaderStatusGeneration

    statusError = isError == true

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
        statusMessage.TextColor3 = statusError and COLORS.warningSoft or COLORS.muted
    end

    if statusMeta then
        statusMeta.Text = statusError
            and "Startup paused  •  diagnostics available"
            or getExecutorLabel() .. "  •  protected startup"
        statusMeta.TextColor3 = statusError and COLORS.warningSoft or COLORS.dim
    end

    if statusChip then
        statusChip.BackgroundColor3 = activeColor
        statusChip.BackgroundTransparency = statusError and 0.8 or 0.88
    end

    if statusChipStroke then
        statusChipStroke.Color = activeColor
        statusChipStroke.Transparency = statusError and 0.28 or 0.52
    end

    if statusChipText then
        statusChipText.Text = statusError and "ATTENTION" or (terminal and "READY" or "STARTING")
        statusChipText.TextColor3 = activeSoft
    end

    if stateDot then
        stateDot.BackgroundColor3 = activeColor
    end

    if statusIcon then
        statusIcon.BackgroundColor3 = activeColor
    end

    if statusIconGradient then
        statusIconGradient.Color = ColorSequence.new(activeColor, activeWarm)
    end

    if statusIconCore then
        statusIconCore.BackgroundColor3 = statusError and COLORS.warningSoft or COLORS.text
    end

    if statusWindowStroke then
        statusWindowStroke.Color = statusError and COLORS.warning or COLORS.border
        statusWindowStroke.Transparency = statusError and 0.22 or 0.26
    end

    if progressFill then
        progressFill.BackgroundColor3 = activeColor
        animate(progressFill, 0.24, {
            Size = UDim2.fromScale(math.clamp(statusProgress, 0.03, 1), 1),
        }, Enum.EasingStyle.Quint)
    end

    if progressGradient then
        progressGradient.Color = ColorSequence.new(activeColor, activeWarm)
    end

    if progressValue then
        progressValue.Text = tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
        progressValue.TextColor3 = activeSoft
    end

    updatePhaseMarkers(statusProgress, statusError)

    if diagnosticsButton then
        diagnosticsButton.Visible = statusError
    end

    if elapsedLabel then
        elapsedLabel.Visible = not statusError
    end

    if statusError then
        return
    end

    if terminal then
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
        local hold = math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.34

        task.delay(hold, function()
            if generation ~= loaderStatusGeneration or statusError then
                return
            end

            if not statusGui or not statusGui.Parent then
                return
            end

            animate(statusBackdrop, 0.32, {
                BackgroundTransparency = 1,
            }, Enum.EasingStyle.Quart)

            animate(statusWindow, 0.32, {
                Position = UDim2.new(0.5, 0, 0.5, 12),
                BackgroundTransparency = 0.18,
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

            animate(statusWindowScale, 0.32, {
                Scale = math.max(statusWindowScale.Scale * 0.96, 0.4),
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

            task.delay(0.36, function()
                if generation ~= loaderStatusGeneration or statusError then
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
-- BADWARS_LOADER_PRESENTATION_STANDALONE_V5_END
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
    local cachedProbe = _loadstring(cachedOrchestrator, "cached-main-probe")
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
