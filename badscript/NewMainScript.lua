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
local function safeHttpGet(inst, url, nocache)
	local g = inst or game
	local httpget = g.HttpGet or (getgenv and getgenv().HttpGet)
	if httpget then
		return httpget(g, url, nocache)
	end
	local httpService = cloneref(game:GetService("HttpService"))
	return httpService:GetAsync(url, nocache)
end
isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local __nativeDelfile = type(delfile) == 'function'
delfile = delfile or function()
	return false
end
isfolder = isfolder or function() return false end
makefolder = makefolder or function() end
listfiles = listfiles or function() return {} end
readfile = readfile or function() return '' end
writefile = writefile or function() end
cloneref = cloneref or function(obj) return obj end
setthreadidentity = setthreadidentity or function() end
queue_on_teleport = queue_on_teleport or function() end

local g = getgenv; if type(g) == 'function' then g = g() end; local _loadstring = (g and g.loadstring) or loadstring or function(s) error("loadstring not available in executor") end


-- BADWARS_NEVERMORE_BOOTSTRAP_BEGIN
local function loadNevermoreRuntime()
    if type(shared.BadWarsNevermore) == 'table' and shared.BadWarsNevermore.Ready == true then
        return shared.BadWarsNevermore
    end
    local path = 'badscript/libraries/nevermore/NevermoreRuntime.lua'
    local source
    if type(isfile) == 'function' and type(readfile) == 'function' then
        local ok, exists = pcall(isfile, path)
        if ok and exists then
            local readOk, body = pcall(readfile, path)
            if readOk and type(body) == 'string' and body:find('BADWARS_NEVERMORE_RUNTIME_V19_3', 1, true) then source = body end
        end
    end
    if not source then
        for _, url in ipairs({
            'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/'..path,
            'https://github.com/evanbackup1256-ship-it/badwars/raw/main/'..path,
        }) do
            local ok, body = pcall(safeHttpGet, game, url, true)
            if ok and type(body) == 'string' and body ~= '' and body ~= '404: Not Found' then
                source = body
                break
            end
        end
    end
    assert(type(source) == 'string' and source ~= '', 'Unable to load NevermoreRuntime.lua')
    local chunk, compileError = _loadstring(source, '@'..path)
    assert(chunk, compileError)
    local ok, runtime = xpcall(chunk, function(err)
        return debug and debug.traceback and debug.traceback(tostring(err), 2) or tostring(err)
    end)
    assert(ok, runtime)
    assert(type(runtime) == 'table' and runtime.Ready == true, 'NevermoreRuntime returned invalid API')
    return runtime
end
local Nevermore = loadNevermoreRuntime()
if type(shared.BadDiagnostics) == 'table' and type(shared.BadDiagnostics.AttachNevermore) == 'function' then
    pcall(shared.BadDiagnostics.AttachNevermore, shared.BadDiagnostics, Nevermore)
end
-- BADWARS_NEVERMORE_BOOTSTRAP_END

-- BADWARS_EARLY_LOADER_PRESENTATION_V3_BEGIN
local function createStatusLabel()
    local tweenService = cloneref(game:GetService("TweenService"))
    local existingGui
    pcall(function()
        local parent = cloneref(game:GetService("CoreGui"))
        existingGui = parent:FindFirstChild("BadWarsLoaderStatus")
    end)
    if existingGui then
        local loader = existingGui:FindFirstChild("Loader", true)
        local stage = loader and loader:FindFirstChild("Stage")
        local detail = loader and loader:FindFirstChild("Detail")
        local fill = loader and loader:FindFirstChild("Fill", true)
        if stage then
            shared.BadStatusGui = existingGui
            return function(message, isError)
                local text = tostring(message or "Working")
                stage.Text = isError and "Unable to finish loading" or text
                if detail then
                    detail.Text = text
                end
                if fill then
                    fill.BackgroundColor3 = isError and Color3.fromRGB(244, 92, 115) or Color3.fromRGB(66, 214, 153)
                    pcall(function()
                        tweenService:Create(fill, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromScale(isError and 1 or math.min(fill.Size.X.Scale + 0.075, 0.94), 1),
                        }):Play()
                    end)
                end
            end
        end
    end

    local function parentForUi()
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

    local parent = parentForUi()
    if not parent then
        return function(message)
            warn("BadWars: " .. tostring(message or "Working"))
        end
    end

    pcall(function()
        local old = parent:FindFirstChild("BadWarsLoaderStatus")
        if old then
            old:Destroy()
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "BadWarsLoaderStatus"
    gui.DisplayOrder = 10000000
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(2, 4, 7)
    backdrop.BackgroundTransparency = 0.38
    backdrop.BorderSizePixel = 0
    backdrop.Parent = gui

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local cardWidth = math.clamp(viewport.X - 28, 344, 480)

    local card = Instance.new("CanvasGroup")
    card.Name = "Loader"
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.Size = UDim2.fromOffset(cardWidth, 188)
    card.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
    card.BorderSizePixel = 0
    card.GroupTransparency = 1
    card.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(70, 93, 109)
    stroke.Transparency = 0.36
    stroke.Thickness = 1
    stroke.Parent = card

    local scale = Instance.new("UIScale")
    scale.Scale = 0.975
    scale.Parent = card

    local accent = Instance.new("Frame")
    accent.Position = UDim2.fromOffset(18, 18)
    accent.Size = UDim2.fromOffset(4, 34)
    accent.BackgroundColor3 = Color3.fromRGB(75, 222, 168)
    accent.BorderSizePixel = 0
    accent.Parent = card
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(34, 16)
    title.Size = UDim2.new(1, -52, 0, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "BadWars"
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(244, 247, 250)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = card

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(34, 38)
    subtitle.Size = UDim2.new(1, -52, 0, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "Preparing your control center"
    subtitle.TextSize = 10
    subtitle.TextColor3 = Color3.fromRGB(116, 130, 145)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = card

    local stage = Instance.new("TextLabel")
    stage.Name = "Stage"
    stage.Position = UDim2.fromOffset(18, 76)
    stage.Size = UDim2.new(1, -36, 0, 22)
    stage.BackgroundTransparency = 1
    stage.Font = Enum.Font.GothamSemibold
    stage.Text = "Starting"
    stage.TextSize = 14
    stage.TextColor3 = Color3.fromRGB(226, 232, 238)
    stage.TextXAlignment = Enum.TextXAlignment.Left
    stage.TextTruncate = Enum.TextTruncate.AtEnd
    stage.Parent = card

    local detail = Instance.new("TextLabel")
    detail.Name = "Detail"
    detail.Position = UDim2.fromOffset(18, 101)
    detail.Size = UDim2.new(1, -36, 0, 18)
    detail.BackgroundTransparency = 1
    detail.Font = Enum.Font.Gotham
    detail.Text = "Starting interface services"
    detail.TextSize = 10
    detail.TextColor3 = Color3.fromRGB(119, 132, 147)
    detail.TextXAlignment = Enum.TextXAlignment.Left
    detail.TextTruncate = Enum.TextTruncate.AtEnd
    detail.Parent = card

    local track = Instance.new("Frame")
    track.Name = "ProgressTrack"
    track.Position = UDim2.fromOffset(18, 147)
    track.Size = UDim2.new(1, -36, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(28, 37, 46)
    track.BorderSizePixel = 0
    track.Parent = card
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0.08, 1)
    fill.BackgroundColor3 = Color3.fromRGB(75, 222, 168)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    pcall(function()
        tweenService:Create(card, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            GroupTransparency = 0,
        }):Play()
        tweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Scale = 1,
        }):Play()
    end)

    local progress = 0.08
    shared.BadStatusGui = gui
    shared.BadStatus = function(message, isError)
        local text = tostring(message or "Working")
        warn("BadWars: " .. text)
        if not gui.Parent then
            return
        end
        progress = math.min(progress + 0.075, 0.94)
        stage.Text = isError and "Unable to finish loading" or text
        stage.TextColor3 = isError and Color3.fromRGB(245, 115, 136) or Color3.fromRGB(226, 232, 238)
        detail.Text = text
        fill.BackgroundColor3 = isError and Color3.fromRGB(244, 92, 115) or Color3.fromRGB(66, 214, 153)
        pcall(function()
            tweenService:Create(fill, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromScale(isError and 1 or progress, 1),
            }):Play()
        end)
    end
    return shared.BadStatus
end
-- BADWARS_EARLY_LOADER_PRESENTATION_V3_END
local setStatus = shared.BadStatus or createStatusLabel()
setStatus('starting loader')

local function downloadFile(path, func)
	local cached = isfile(path) and readfile(path) or nil
	if type(cached) ~= 'string' or cached == '' then
		setStatus('downloading ' .. tostring(path))
		local suc, res = pcall(function()
			-- Fixed for self-hosted: direct main branch + full path
			return safeHttpGet(game, 'https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/' .. path:gsub(' ', '%%20'), true)
		end)
		if not suc or res == '404: Not Found' then
			setStatus('ERROR downloading ' .. tostring(path) .. ': ' .. tostring(res), true)
			error(res)
		end
		if path:find('.lua') then
			res = '-- BadWars by usingINales (rebranded, no watermark)\n' .. res
		end
		writefile(path, res)
		cached = res
	end
	if type(cached) ~= 'string' or cached == '' then
		setStatus('ERROR empty file: ' .. tostring(path), true)
		return nil, 'empty file: ' .. tostring(path)
	end
	setStatus('loaded ' .. tostring(path))
	return func and func(path) or cached
end

local badwarsCacheHeader = '-- BadWars by usingINales'
local vapeCacheHeader = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.'

local function isGeneratedCache(contents)
	return type(contents) == 'string'
		and (
			contents:find(badwarsCacheHeader, 1, true) == 1
			or contents:find(vapeCacheHeader, 1, true) == 1
		)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfolder(file) then
			wipeFolder(file)
		end
		if isfile(file) and isGeneratedCache(readfile(file)) then
			delfile(file)
		end
	end
end

local function wipeAnyFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if isfolder(file) then
			wipeAnyFolder(file)
		elseif isfile(file) then
			delfile(file)
		end
	end
end

for _, folder in {'badscript', 'badscript/games', 'badscript/profiles', 'badscript/assets', 'badscript/libraries', 'badscript/guis'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

local cacheVersion = 'badwars-v20-nevermore-foundation-2026-07-06-01'
local cacheVersionPath = 'badscript/profiles/cache-version.txt'
local function isCurrentGuiCache(contents)
	return type(contents) == 'string'
		and contents:find('Version%s*=%s*"20%.0"') ~= nil
		and contents:find('PremiumBuild%s*=%s*"2026%.07%.06%-V20%-NEVERMORE%-FOUNDATION"') ~= nil
end
local function invalidateStaleGuiCache()
	local guiPath = 'badscript/guis/new/gui.lua'
	if isfile(guiPath) and not isCurrentGuiCache(readfile(guiPath)) then
		setStatus('clearing stale GUI cache')
		if __nativeDelfile then
			pcall(delfile, guiPath)
		end
		if isfile(guiPath) and type(writefile) == 'function' then
			pcall(writefile, guiPath, '')
		end
	end
end
if (isfile(cacheVersionPath) and readfile(cacheVersionPath) or '') ~= cacheVersion then
	setStatus('clearing old cache')
	if isfile('badscript/main.lua') then delfile('badscript/main.lua') end
	if isfile('badscript/loader.lua') then delfile('badscript/loader.lua') end
	if isfile('badscript/games/universal - base/bundle.lua') then delfile('badscript/games/universal - base/bundle.lua') end
	if isfile('badscript/games/universal - base/base.lua') then delfile('badscript/games/universal - base/base.lua') end
	if isfile('badscript/games/universal - base/files.txt') then delfile('badscript/games/universal - base/files.txt') end
	wipeAnyFolder('badscript/assets')
	wipeFolder('badscript/games')
	wipeFolder('badscript/guis')
	for _,file in {'badscript/libraries/spr.lua','badscript/libraries/spr.LICENSE.txt'} do if isfile(file) then pcall(delfile,file) end end
	writefile(cacheVersionPath, cacheVersion)
end
invalidateStaleGuiCache()

if not shared.BadDeveloper then
	local _, subbed = pcall(function()
		return safeHttpGet(game, 'https://github.com/evanbackup1256-ship-it/badwars')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('badscript/profiles/commit.txt') and readfile('badscript/profiles/commit.txt') or '') ~= commit then
		wipeFolder('badscript/games')
		wipeFolder('badscript/guis')
		for _,file in {'badscript/libraries/spr.lua','badscript/libraries/spr.LICENSE.txt'} do if isfile(file) then pcall(delfile,file) end end
	end
	writefile('badscript/profiles/commit.txt', commit)
end

game:GetService("StarterGui"):SetCore("SendNotification", {
	Title = "BadWars",
	Text = "Entirely by usingINales - Dev Build",
	Duration = 4
})

setStatus('loading main.lua')
local mainCode = downloadFile('badscript/main.lua')
if type(mainCode) ~= 'string' or mainCode == '' then
	setStatus('ERROR: failed to download/read badscript/main.lua', true)
	error('Failed to download/read badscript/main.lua', 0)
end

setStatus('compiling main.lua')
local mainFunc, mainErr = _loadstring(mainCode, 'main')
if not mainFunc then
	setStatus('ERROR compiling main.lua: ' .. tostring(mainErr), true)
	error('Failed to compile badscript/main.lua: ' .. tostring(mainErr), 0)
end

setStatus('running main.lua')
local ok, result = xpcall(mainFunc, function(err) local d=shared.BadDiagnostics return d and d:Traceback(err, 2) or ((debug and debug.traceback) and debug.traceback(tostring(err), 2) or tostring(err)) end)
if not ok then
	setStatus('ERROR running main.lua: ' .. tostring(result), true)
	error(result, 0)
end

return result












