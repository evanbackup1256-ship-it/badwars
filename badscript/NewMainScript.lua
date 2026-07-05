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
-- BADWARS_DIAGNOSTICS_BOOTSTRAP_ENDlocal function safeHttpGet(inst, url, nocache)
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
delfile = delfile or function(file)
	writefile(file, '')
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

-- BADWARS_EARLY_LOADER_PRESENTATION_V1_BEGIN
local function createStatusLabel()
    local statusGui
    local card
    local stageText
    local detailText
    local lineFill
    local stateDot

    local function getParent()
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

    local parent = getParent()

    if parent then
        pcall(function()
            local previous = parent:FindFirstChild("BadWarsLoaderStatus")
            if previous then
                previous:Destroy()
            end
        end)

        statusGui = Instance.new("ScreenGui")
        statusGui.Name = "BadWarsLoaderStatus"
        statusGui.DisplayOrder = 10000000
        statusGui.IgnoreGuiInset = true
        statusGui.ResetOnSpawn = false
        statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        statusGui.Parent = parent

        local backdrop = Instance.new("Frame")
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundColor3 = Color3.fromRGB(5, 6, 8)
        backdrop.BackgroundTransparency = 0.3
        backdrop.BorderSizePixel = 0
        backdrop.Parent = statusGui

        card = Instance.new("Frame")
        card.Name = "Loader"
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.5)
        card.Size = UDim2.fromOffset(396, 132)
        card.BackgroundColor3 = Color3.fromRGB(15, 17, 21)
        card.BorderSizePixel = 0
        card.Parent = statusGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(48, 52, 61)
        stroke.Transparency = 0.35
        stroke.Thickness = 1
        stroke.Parent = card

        local title = Instance.new("TextLabel")
        title.Position = UDim2.fromOffset(18, 15)
        title.Size = UDim2.new(1, -72, 0, 20)
        title.BackgroundTransparency = 1
        title.Font = Enum.Font.GothamSemibold
        title.Text = "BadWars"
        title.TextSize = 15
        title.TextColor3 = Color3.fromRGB(235, 237, 241)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = card

        local context = Instance.new("TextLabel")
        context.Position = UDim2.fromOffset(18, 35)
        context.Size = UDim2.new(1, -72, 0, 16)
        context.BackgroundTransparency = 1
        context.Font = Enum.Font.Gotham
        context.Text = "Starting"
        context.TextSize = 11
        context.TextColor3 = Color3.fromRGB(120, 126, 138)
        context.TextXAlignment = Enum.TextXAlignment.Left
        context.Parent = card

        stateDot = Instance.new("Frame")
        stateDot.AnchorPoint = Vector2.new(1, 0)
        stateDot.Position = UDim2.new(1, -18, 0, 19)
        stateDot.Size = UDim2.fromOffset(8, 8)
        stateDot.BackgroundColor3 = Color3.fromRGB(70, 196, 150)
        stateDot.BorderSizePixel = 0
        stateDot.Parent = card

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = stateDot

        stageText = Instance.new("TextLabel")
        stageText.Position = UDim2.fromOffset(18, 62)
        stageText.Size = UDim2.new(1, -36, 0, 18)
        stageText.BackgroundTransparency = 1
        stageText.Font = Enum.Font.GothamMedium
        stageText.Text = "Preparing loader"
        stageText.TextSize = 13
        stageText.TextColor3 = Color3.fromRGB(211, 214, 220)
        stageText.TextXAlignment = Enum.TextXAlignment.Left
        stageText.Parent = card

        detailText = Instance.new("TextLabel")
        detailText.Position = UDim2.fromOffset(18, 82)
        detailText.Size = UDim2.new(1, -36, 0, 18)
        detailText.BackgroundTransparency = 1
        detailText.Font = Enum.Font.Code
        detailText.Text = "bootstrap"
        detailText.TextSize = 10
        detailText.TextColor3 = Color3.fromRGB(109, 115, 127)
        detailText.TextXAlignment = Enum.TextXAlignment.Left
        detailText.TextTruncate = Enum.TextTruncate.AtEnd
        detailText.Parent = card

        local line = Instance.new("Frame")
        line.Position = UDim2.fromOffset(18, 112)
        line.Size = UDim2.new(1, -36, 0, 3)
        line.BackgroundColor3 = Color3.fromRGB(33, 36, 43)
        line.BorderSizePixel = 0
        line.Parent = card

        local lineCorner = Instance.new("UICorner")
        lineCorner.CornerRadius = UDim.new(1, 0)
        lineCorner.Parent = line

        lineFill = Instance.new("Frame")
        lineFill.Size = UDim2.fromScale(0.08, 1)
        lineFill.BackgroundColor3 = Color3.fromRGB(70, 196, 150)
        lineFill.BorderSizePixel = 0
        lineFill.Parent = line

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = lineFill
    end

    local progress = 0.08

    shared.BadStatusGui = statusGui
    shared.BadStatus = function(message, isError)
        local text = tostring(message or "Working")
        warn("BadWars: " .. text)

        if not statusGui or not statusGui.Parent then
            return
        end

        statusGui.Enabled = true
        progress = math.min(progress + 0.08, 0.92)

        if stageText then
            stageText.Text = isError and "Loader stopped" or text
            stageText.TextColor3 = isError
                and Color3.fromRGB(239, 105, 116)
                or Color3.fromRGB(211, 214, 220)
        end

        if detailText then
            detailText.Text = isError and text or "bootstrap / " .. string.lower(text)
        end

        if stateDot then
            stateDot.BackgroundColor3 = isError
                and Color3.fromRGB(239, 105, 116)
                or Color3.fromRGB(70, 196, 150)
        end

        if lineFill then
            lineFill.BackgroundColor3 = isError
                and Color3.fromRGB(239, 105, 116)
                or Color3.fromRGB(70, 196, 150)
            lineFill.Size = UDim2.fromScale(isError and 1 or progress, 1)
        end
    end

    return shared.BadStatus
end
-- BADWARS_EARLY_LOADER_PRESENTATION_V1_END
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

local cacheVersion = 'badwars-v2-bedwars-lobby-services-2026-07-04-05'
local cacheVersionPath = 'badscript/profiles/cache-version.txt'
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
	wipeFolder('badscript/libraries')
	writefile(cacheVersionPath, cacheVersion)
end

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
		wipeFolder('badscript/libraries')
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












