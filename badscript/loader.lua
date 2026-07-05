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

-- Status GUI (BadWars Studio V13)
local statusGui
local statusCard
local statusLabel
local stageLabel
local detailLabel
local percentLabel
local progressFill
local statusDot
local stepFrames = {}
local statusProgress = 0
local statusError = false
local statusBackdrop
local loaderCreatedAt = os.clock()
local loaderStatusGeneration = 0
local loaderDismissScheduled = false
local MINIMUM_VISIBLE_SECONDS = 2.6
local loaderTweenService = cloneref(game:GetService("TweenService"))

local function loaderTween(object, info, properties)
	if not object or not object.Parent then
		return nil
	end

	local success, tween = pcall(function()
		return loaderTweenService:Create(object, info, properties)
	end)

	if success and tween then
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
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness or 1
	stroke.Parent = parent
	return stroke
end

local function isTerminalStatus(message)
	local lower = string.lower(tostring(message or ""))
	return lower == "ready" or string.sub(lower, 1, 7) == "ready -"
end

local function resolveStatusProgress(message)
	local lower = string.lower(tostring(message or ""))

	if isTerminalStatus(lower) then
		return 1
	end

	local stages = {
		{ "cache", 0.08 },
		{ "self-test", 0.16 },
		{ "validating orchestrator", 0.22 },
		{ "downloading", 0.34 },
		{ "loading interface", 0.48 },
		{ "interface ready", 0.58 },
		{ "loading core modules", 0.72 },
		{ "universal modules ready", 0.8 },
		{ "loading game module", 0.86 },
		{ "game module ready", 0.9 },
		{ "loading profile", 0.94 },
		{ "finalizing", 0.98 },
	}

	for _, stage in ipairs(stages) do
		if string.find(lower, stage[1], 1, true) then
			return stage[2]
		end
	end

	return math.min(math.max(statusProgress + 0.012, 0.02), 0.985)
end

local function updateSteps()
	local thresholds = { 0.24, 0.78, 0.94 }

	for index, frame in ipairs(stepFrames) do
		local active = statusProgress >= thresholds[index] and not statusError
		local dot = frame:FindFirstChild("Dot")
		local label = frame:FindFirstChild("Label")

		if dot then
			loaderTween(
				dot,
				TweenInfo.new(
					0.14,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				),
				{
					BackgroundColor3 = active
						and Color3.fromRGB(62, 205, 160)
						or Color3.fromRGB(69, 82, 97),
					BackgroundTransparency = active and 0 or 0.35,
				}
			)
		end

		if label then
			label.TextColor3 = active
				and Color3.fromRGB(218, 226, 234)
				or Color3.fromRGB(116, 130, 146)
		end
	end
end

local function createBadWarsLoader()
	pcall(function()
		local old = shared.BadStatusGui
		if old and typeof(old) == "Instance" then
			old:Destroy()
		end
	end)

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
	if not parent then
		return
	end

	local old = parent:FindFirstChild("BadWarsLoaderStatus")
	if old then
		old:Destroy()
	end

	statusGui = Instance.new("ScreenGui")
	statusGui.Name = "BadWarsLoaderStatus"
	statusGui.DisplayOrder = 10000000
	statusGui.IgnoreGuiInset = true
	statusGui.ResetOnSpawn = false
	statusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	statusGui.Parent = parent

	statusBackdrop = Instance.new("Frame")
	statusBackdrop.Size = UDim2.fromScale(1, 1)
	statusBackdrop.BackgroundColor3 = Color3.fromRGB(4, 7, 10)
	statusBackdrop.BackgroundTransparency = 1
	statusBackdrop.BorderSizePixel = 0
	statusBackdrop.Parent = statusGui
	loaderTween(
		statusBackdrop,
		TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.36 }
	)

	statusCard = Instance.new("Frame")
	statusCard.Name = "BadWarsLoader"
	statusCard.AnchorPoint = Vector2.new(0.5, 0.5)
	statusCard.Position = UDim2.fromScale(0.5, 0.515)
	statusCard.Size = UDim2.fromOffset(472, 252)
	statusCard.BackgroundColor3 = Color3.fromRGB(10, 14, 18)
	statusCard.BackgroundTransparency = 0.01
	statusCard.BorderSizePixel = 0
	statusCard.ClipsDescendants = true
	statusCard.Parent = statusGui
	loaderCorner(statusCard, 12)
	loaderStroke(statusCard, Color3.fromRGB(65, 78, 94), 0.38, 1)

	local scale = Instance.new("UIScale")
	scale.Scale = 0.97
	scale.Parent = statusCard
	loaderTween(
		scale,
		TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Scale = 1 }
	)
	loaderTween(
		statusCard,
		TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.5) }
	)

	local surface = Instance.new("UIGradient")
	surface.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 22, 28)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 13, 17)),
	})
	surface.Rotation = 90
	surface.Parent = statusCard

	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(3, 32)
	accent.Position = UDim2.fromOffset(1, 24)
	accent.BackgroundColor3 = Color3.fromRGB(62, 205, 160)
	accent.BorderSizePixel = 0
	accent.Parent = statusCard
	loaderCorner(accent, 99)

	local logo = Instance.new("TextLabel")
	logo.Size = UDim2.fromOffset(260, 30)
	logo.Position = UDim2.fromOffset(24, 22)
	logo.BackgroundTransparency = 1
	logo.Font = Enum.Font.GothamBold
	logo.Text = "BADWARS"
	logo.TextSize = 23
	logo.TextColor3 = Color3.fromRGB(241, 245, 248)
	logo.TextXAlignment = Enum.TextXAlignment.Left
	logo.Parent = statusCard

	local version = Instance.new("TextLabel")
	version.Size = UDim2.fromOffset(34, 18)
	version.Position = UDim2.fromOffset(146, 28)
	version.BackgroundColor3 = Color3.fromRGB(25, 33, 42)
	version.BorderSizePixel = 0
	version.Font = Enum.Font.GothamBold
	version.Text = "13"
	version.TextSize = 10
	version.TextColor3 = Color3.fromRGB(156, 171, 188)
	version.Parent = statusCard
	loaderCorner(version, 5)

	stageLabel = Instance.new("TextLabel")
	stageLabel.Size = UDim2.new(1, -48, 0, 20)
	stageLabel.Position = UDim2.fromOffset(24, 68)
	stageLabel.BackgroundTransparency = 1
	stageLabel.Font = Enum.Font.GothamSemibold
	stageLabel.Text = "STARTING"
	stageLabel.TextSize = 12
	stageLabel.TextColor3 = Color3.fromRGB(216, 224, 233)
	stageLabel.TextXAlignment = Enum.TextXAlignment.Left
	stageLabel.Parent = statusCard

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -72, 0, 34)
	statusLabel.Position = UDim2.fromOffset(24, 91)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.Text = "Preparing the client..."
	statusLabel.TextSize = 13
	statusLabel.TextWrapped = true
	statusLabel.TextColor3 = Color3.fromRGB(148, 160, 174)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextYAlignment = Enum.TextYAlignment.Top
	statusLabel.Parent = statusCard

	statusDot = Instance.new("Frame")
	statusDot.Size = UDim2.fromOffset(8, 8)
	statusDot.AnchorPoint = Vector2.new(0.5, 0.5)
	statusDot.Position = UDim2.new(1, -28, 0, 78)
	statusDot.BackgroundColor3 = Color3.fromRGB(62, 205, 160)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = statusCard
	loaderCorner(statusDot, 99)

	local stepHolder = Instance.new("Frame")
	stepHolder.Size = UDim2.new(1, -48, 0, 34)
	stepHolder.Position = UDim2.fromOffset(24, 136)
	stepHolder.BackgroundTransparency = 1
	stepHolder.Parent = statusCard

	local stepLayout = Instance.new("UIListLayout")
	stepLayout.FillDirection = Enum.FillDirection.Horizontal
	stepLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	stepLayout.Padding = UDim.new(0, 24)
	stepLayout.Parent = stepHolder

	for _, text in ipairs({ "Boot", "Modules", "Profile" }) do
		local step = Instance.new("Frame")
		step.Size = UDim2.fromOffset(104, 30)
		step.BackgroundTransparency = 1
		step.Parent = stepHolder

		local dot = Instance.new("Frame")
		dot.Name = "Dot"
		dot.Size = UDim2.fromOffset(7, 7)
		dot.Position = UDim2.fromOffset(0, 11)
		dot.BackgroundColor3 = Color3.fromRGB(69, 82, 97)
		dot.BackgroundTransparency = 0.35
		dot.BorderSizePixel = 0
		dot.Parent = step
		loaderCorner(dot, 99)

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.Size = UDim2.new(1, -18, 1, 0)
		label.Position = UDim2.fromOffset(17, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamMedium
		label.Text = text
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(116, 130, 146)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = step

		table.insert(stepFrames, step)
	end

	local progressTrack = Instance.new("Frame")
	progressTrack.Size = UDim2.new(1, -96, 0, 6)
	progressTrack.Position = UDim2.fromOffset(24, 190)
	progressTrack.BackgroundColor3 = Color3.fromRGB(30, 38, 48)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = statusCard
	loaderCorner(progressTrack, 99)

	progressFill = Instance.new("Frame")
	progressFill.Size = UDim2.fromScale(0.02, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(62, 205, 160)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack
	loaderCorner(progressFill, 99)

	percentLabel = Instance.new("TextLabel")
	percentLabel.Size = UDim2.fromOffset(54, 20)
	percentLabel.Position = UDim2.new(1, -70, 0, 182)
	percentLabel.BackgroundTransparency = 1
	percentLabel.Font = Enum.Font.GothamSemibold
	percentLabel.Text = "2%"
	percentLabel.TextSize = 11
	percentLabel.TextColor3 = Color3.fromRGB(166, 178, 191)
	percentLabel.TextXAlignment = Enum.TextXAlignment.Right
	percentLabel.Parent = statusCard

	detailLabel = Instance.new("TextLabel")
	detailLabel.Size = UDim2.new(1, -48, 0, 18)
	detailLabel.Position = UDim2.fromOffset(24, 216)
	detailLabel.BackgroundTransparency = 1
	detailLabel.Font = Enum.Font.Code
	detailLabel.Text = "loading required files"
	detailLabel.TextSize = 10
	detailLabel.TextColor3 = Color3.fromRGB(87, 100, 114)
	detailLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailLabel.Parent = statusCard

	shared.BadStatusGui = statusGui
	updateSteps()
end

createBadWarsLoader()

shared.BadStatus = function(msg, isErr)
	local message = tostring(msg or "Working...")
	local terminalStatus = isTerminalStatus(message)

	loaderStatusGeneration += 1
	local statusGeneration = loaderStatusGeneration
	statusError = isErr == true if statusError then shared.__badwars_fatal_error=true end if shared.BadDiagnostics then shared.BadDiagnostics:SetStage(message); if statusError then shared.BadDiagnostics:Error(message, shared.BadDiagnostics:Traceback(message,3), {subsystem='LoaderStatus',file='badscript/loader.lua',fatal=false}) else shared.BadDiagnostics:Info(message,{subsystem='LoaderStatus',file='badscript/loader.lua',native=false}) end end

	local nextProgress = resolveStatusProgress(message)
	if terminalStatus and not statusError then
		statusProgress = 1
	else
		statusProgress = math.min(math.max(statusProgress, nextProgress), 0.985)
		loaderDismissScheduled = false
	end

	if not statusGui or not statusGui.Parent then
		return
	end

	statusGui.Enabled = true

	local accentColor = statusError
		and Color3.fromRGB(239, 91, 104)
		or Color3.fromRGB(62, 205, 160)

	local upper = string.upper(message)
	if #upper > 36 then
		upper = string.sub(upper, 1, 36) .. "..."
	end

	if stageLabel then
		stageLabel.Text = statusError and "ERROR" or upper
		stageLabel.TextColor3 = statusError
			and Color3.fromRGB(244, 128, 138)
			or Color3.fromRGB(216, 224, 233)
	end

	if statusLabel then
		statusLabel.Text = message
		statusLabel.TextColor3 = statusError
			and Color3.fromRGB(242, 148, 156)
			or Color3.fromRGB(148, 160, 174)
	end

	if detailLabel then
		detailLabel.Text = statusError
			and "loading paused"
			or "loading required files"
	end

	if progressFill then
		progressFill.BackgroundColor3 = accentColor
		loaderTween(
			progressFill,
			TweenInfo.new(
				0.22,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				Size = UDim2.fromScale(
					math.clamp(statusProgress, 0.02, 1),
					1
				),
			}
		)
	end

	if statusDot then
		statusDot.BackgroundColor3 = accentColor
	end

	if percentLabel then
		percentLabel.Text =
			tostring(math.floor(statusProgress * 100 + 0.5)) .. "%"
	end

	updateSteps()

	if
		terminalStatus
		and not statusError
		and not loaderDismissScheduled
		and statusGui
		and statusGui.Parent
	then
		loaderDismissScheduled = true

		if stageLabel then
			stageLabel.Text = "READY"
			stageLabel.TextColor3 = Color3.fromRGB(62, 205, 160)
		end

		if statusLabel then
			statusLabel.Text = "BadWars is ready."
		end

		local visibleFor = os.clock() - loaderCreatedAt
		local completionHold =
			math.max(MINIMUM_VISIBLE_SECONDS - visibleFor, 0) + 0.55

		task.delay(completionHold, function()
			if
				statusGeneration ~= loaderStatusGeneration
				or statusError
				or not statusGui
				or not statusGui.Parent
			then
				loaderDismissScheduled = false
				return
			end

			if statusCard and statusCard.Parent then
				loaderTween(
					statusCard,
					TweenInfo.new(
						0.22,
						Enum.EasingStyle.Quart,
						Enum.EasingDirection.In
					),
					{
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.485),
					}
				)
			end

			if statusBackdrop and statusBackdrop.Parent then
				loaderTween(
					statusBackdrop,
					TweenInfo.new(
						0.24,
						Enum.EasingStyle.Quart,
						Enum.EasingDirection.In
					),
					{ BackgroundTransparency = 1 }
				)
			end

			task.delay(0.26, function()
				if
					statusGeneration == loaderStatusGeneration
					and statusGui
					and statusGui.Parent
				then
					statusGui:Destroy()
				end
			end)
		end)
	end
end

local setStatus=shared.BadStatus
setStatus('pipeline: ready')

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

local cacheVersion = 'badwars-premium-stability-2026-07-04-08'
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
