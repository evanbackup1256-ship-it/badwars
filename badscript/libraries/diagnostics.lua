-- BADWARS_DIAGNOSTICS_V18_3_PERFORMANCE_FIX
-- BadWars centralized runtime diagnostics
-- Loaded before the normal loader whenever possible.

shared = type(shared) == "table" and shared or {}
shared.__badwars_diagnostic_buffer = type(shared.__badwars_diagnostic_buffer) == "table"
    and shared.__badwars_diagnostic_buffer
    or {}

local VERSION = "1.0.0"
local existing = shared.BadDiagnostics
if type(existing) == "table" and existing.Version == VERSION and not existing.Destroyed then
    return existing
end
if type(existing) == "table" and type(existing.Destroy) == "function" then
    pcall(function()
        existing:Destroy("upgrade")
    end)
end

local unpackArgs = table.unpack or unpack
local packArgs = table.pack or function(...)
    return { n = select("#", ...), ... }
end

local function nowClock()
    local ok, value = pcall(os.clock)
    return ok and value or 0
end

local function nowText()
    local ok, value = pcall(os.date, "%H:%M:%S")
    if ok and type(value) == "string" then
        return value
    end
    return string.format("%.3f", nowClock())
end

local function safeString(value)
    local ok, result = pcall(tostring, value)
    return ok and result or "<unprintable>"
end

local function copyTable(source)
    local out = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            out[key] = value
        end
    end
    return out
end

local Diagnostics = {
    Version = VERSION,
    Entries = {},
    Subscribers = {},
    Connections = {},
    MaxEntries = 750,
    MaxVisibleEntries = 140,
    DuplicateWindow = 3,
    CurrentStage = "bootstrap",
    Destroyed = false,
    Paused = false,
    Unread = 0,
    Counts = {
        DEBUG = 0,
        INFO = 0,
        SUCCESS = 0,
        WARN = 0,
        ERROR = 0,
        FATAL = 0,
    },
    _id = 0,
    _duplicateIndex = {},
    _nativeDepth = 0,
    _renderPending = false,
    _selectedId = nil,
    _ui = nil,
}

local LEVELS = {
    DEBUG = true,
    INFO = true,
    SUCCESS = true,
    WARN = true,
    ERROR = true,
    FATAL = true,
}

local LEVEL_COLORS = {
    DEBUG = Color3.fromRGB(112, 123, 137),
    INFO = Color3.fromRGB(146, 184, 224),
    SUCCESS = Color3.fromRGB(76, 207, 157),
    WARN = Color3.fromRGB(239, 177, 72),
    ERROR = Color3.fromRGB(239, 91, 104),
    FATAL = Color3.fromRGB(255, 68, 92),
}

local function normalizeLevel(level)
    level = string.upper(safeString(level or "INFO"))
    return LEVELS[level] and level or "INFO"
end

function Diagnostics:Traceback(err, level)
    local message = safeString(err)
    local debugger = rawget(_G, "debug") or debug
    if type(debugger) == "table" and type(debugger.traceback) == "function" then
        local ok, trace = pcall(debugger.traceback, message, tonumber(level) or 2)
        if ok and type(trace) == "string" and trace ~= "" then
            return trace
        end
    end
    return message
end

function Diagnostics:SetStage(stage)
    self.CurrentStage = safeString(stage or "unknown")
end

function Diagnostics:_makeKey(entry)
    return table.concat({
        entry.severity,
        entry.message,
        entry.traceback or "",
        entry.subsystem or "",
        entry.module or "",
        entry.file or "",
        entry.stage or "",
        entry.fatal and "fatal" or "caught",
    }, "\31")
end

function Diagnostics:_trim()
    while #self.Entries > self.MaxEntries do
        local removeIndex
        for index, entry in ipairs(self.Entries) do
            if not entry.fatal then
                removeIndex = index
                break
            end
        end
        removeIndex = removeIndex or 1
        local removed = table.remove(self.Entries, removeIndex)
        if removed then
            self._duplicateIndex[removed.key] = nil
            if self._selectedId == removed.id then
                self._selectedId = nil
            end
        end
    end
end

function Diagnostics:_emitNative(entry)
    if entry.native == false or self._nativeDepth > 0 then
        return
    end

    self._nativeDepth = self._nativeDepth + 1
    local prefix = string.format(
        "[BadWars][%s][%s][%s]",
        entry.severity,
        entry.subsystem or "Runtime",
        entry.module or "-"
    )
    local text = prefix .. " " .. entry.message
    if entry.traceback and entry.traceback ~= "" and entry.traceback ~= entry.message then
        text = text .. "\n" .. entry.traceback
    end

    pcall(function()
        if entry.severity == "WARN" or entry.severity == "ERROR" or entry.severity == "FATAL" then
            warn(text)
        elseif entry.severity ~= "DEBUG" then
            print(text)
        end
    end)
    self._nativeDepth = math.max(self._nativeDepth - 1, 0)
end

function Diagnostics:_notify(entry, repeated)
    for _, callback in pairs(self.Subscribers) do
        pcall(callback, entry, repeated == true)
    end
    self:_scheduleRender()
end

function Diagnostics:_push(level, message, trace, context)
    if self.Destroyed then
        return nil
    end

    context = copyTable(context)
    level = normalizeLevel(level)
    message = safeString(message)
    trace = trace and safeString(trace) or nil

    local placeId = 0
    local gameId = 0
    pcall(function()
        placeId = game.PlaceId
        gameId = game.GameId
    end)

    local entry = {
        id = self._id + 1,
        clock = nowClock(),
        timestamp = nowText(),
        severity = level,
        message = message,
        traceback = trace,
        subsystem = safeString(context.subsystem or context.sourceSubsystem or "Runtime"),
        module = safeString(context.module or context.moduleName or ""),
        file = safeString(context.file or context.path or ""),
        stage = safeString(context.stage or self.CurrentStage or "unknown"),
        placeId = tonumber(context.placeId) or placeId,
        gameId = tonumber(context.gameId) or gameId,
        fatal = context.fatal == true or level == "FATAL",
        caught = context.caught ~= false,
        native = context.native ~= false,
        repeatCount = 1,
        firstTimestamp = nowText(),
        lastTimestamp = nowText(),
        details = context.details,
    }
    self._id = entry.id
    entry.key = self:_makeKey(entry)

    local duplicate = self._duplicateIndex[entry.key]
    if duplicate and (entry.clock - duplicate.clock) <= self.DuplicateWindow then
        duplicate.clock = entry.clock
        duplicate.timestamp = entry.timestamp
        duplicate.lastTimestamp = entry.timestamp
        duplicate.repeatCount = (duplicate.repeatCount or 1) + 1
        self:_notify(duplicate, true)
        return duplicate
    end

    table.insert(self.Entries, entry)
    self._duplicateIndex[entry.key] = entry
    self.Counts[level] = (self.Counts[level] or 0) + 1
    if level == "WARN" or level == "ERROR" or level == "FATAL" then
        if not self._ui or not self._ui.window.Visible then
            self.Unread = self.Unread + 1
        end
    end

    self:_trim()
    self:_emitNative(entry)
    self:_notify(entry, false)
    return entry
end

function Diagnostics:Log(message, context)
    return self:_push("INFO", message, nil, context)
end

function Diagnostics:Info(message, context)
    return self:_push("INFO", message, nil, context)
end

function Diagnostics:Success(message, context)
    return self:_push("SUCCESS", message, nil, context)
end

function Diagnostics:Debug(message, context)
    context = copyTable(context)
    context.native = context.native == true
    return self:_push("DEBUG", message, nil, context)
end

function Diagnostics:Warn(message, context)
    return self:_push("WARN", message, nil, context)
end

function Diagnostics:Error(message, trace, context)
    context = copyTable(context)
    return self:_push("ERROR", message, trace or self:Traceback(message, 3), context)
end

function Diagnostics:Fatal(message, trace, context)
    context = copyTable(context)
    context.fatal = true
    context.caught = context.caught ~= false
    shared.__badwars_fatal_error = true
    local entry = self:_push("FATAL", message, trace or self:Traceback(message, 3), context)
    self:Open()
    return entry
end

function Diagnostics:RecordRuntime(moduleName, err, context)
    context = copyTable(context)
    context.module = context.module or moduleName
    context.subsystem = context.subsystem or "Module"
    context.caught = context.caught ~= false

    shared.__badwars_runtime_errors = type(shared.__badwars_runtime_errors) == "table"
        and shared.__badwars_runtime_errors
        or {}

    local record = {
        module = safeString(moduleName),
        error = safeString(err),
        traceback = context.traceback or self:Traceback(err, 3),
        path = context.file or context.path,
        category = context.category,
        kind = context.kind,
        stage = context.stage or self.CurrentStage,
        time = nowClock(),
        failureCount = tonumber(context.failureCount) or 1,
    }
    table.insert(shared.__badwars_runtime_errors, record)
    return self:Error(record.error, record.traceback, context)
end

function Diagnostics:Capture(callback, context, ...)
    context = copyTable(context)
    if type(callback) ~= "function" then
        local message = "Capture expected a function, got " .. type(callback)
        self:Error(message, self:Traceback(message, 3), context)
        return false, message
    end

    local args = packArgs(...)
    local results = packArgs(xpcall(function()
        return callback(unpackArgs(args, 1, args.n))
    end, function(err)
        return self:Traceback(err, 3)
    end))

    if not results[1] then
        local trace = results[2]
        local message = safeString(trace):match("^[^\n]+") or safeString(trace)
        self:Error(message, trace, context)
        return false, trace
    end

    return true, unpackArgs(results, 2, results.n)
end

function Diagnostics:Spawn(callback, context, ...)
    local args = packArgs(...)
    return task.spawn(function()
        self:Capture(callback, context, unpackArgs(args, 1, args.n))
    end)
end

function Diagnostics:Defer(callback, context, ...)
    local args = packArgs(...)
    return task.defer(function()
        self:Capture(callback, context, unpackArgs(args, 1, args.n))
    end)
end

function Diagnostics:Compile(source, chunkName, context)
    context = copyTable(context)
    context.subsystem = context.subsystem or "Compiler"
    context.module = context.module or chunkName
    context.file = context.file or chunkName

    local env = getgenv and type(getgenv) == "function" and getgenv() or nil
    local compiler = (env and env.loadstring) or loadstring
    if type(compiler) ~= "function" then
        local message = "loadstring is unavailable in this executor"
        self:Error(message, self:Traceback(message, 3), context)
        return nil, message
    end

    local fn, err = compiler(source, chunkName)
    if not fn then
        self:Error("Compilation failed: " .. safeString(err), safeString(err), context)
        return nil, err
    end
    return fn
end

function Diagnostics:OnEntry(callback)
    if type(callback) ~= "function" then
        return { Disconnect = function() end }
    end
    local token = {}
    self.Subscribers[token] = callback
    return {
        Disconnect = function()
            self.Subscribers[token] = nil
        end,
    }
end

function Diagnostics:FormatEntry(entry, includeTrace)
    if type(entry) ~= "table" then
        return ""
    end
    local repeatSuffix = (entry.repeatCount or 1) > 1 and (" x" .. tostring(entry.repeatCount)) or ""
    local header = string.format(
        "[%s] [%s%s] [%s] stage=%s module=%s file=%s place=%s game=%s %s",
        entry.timestamp or "?",
        entry.severity or "INFO",
        repeatSuffix,
        entry.subsystem or "Runtime",
        entry.stage or "unknown",
        entry.module ~= "" and entry.module or "-",
        entry.file ~= "" and entry.file or "-",
        tostring(entry.placeId or 0),
        tostring(entry.gameId or 0),
        entry.fatal and "FATAL" or (entry.caught and "CAUGHT" or "UNCAUGHT")
    )
    local text = header .. "\n" .. safeString(entry.message)
    if includeTrace ~= false and entry.traceback and entry.traceback ~= "" then
        text = text .. "\n" .. entry.traceback
    end
    return text
end

function Diagnostics:CopyEntry(entry)
    entry = entry or self:GetSelectedEntry()
    if not entry then
        return false, "No diagnostic entry selected"
    end
    local text = self:FormatEntry(entry, true)
    local clipboard = setclipboard or toclipboard
    if type(clipboard) == "function" then
        local ok, err = pcall(clipboard, text)
        return ok, err
    end
    return false, "Clipboard API unavailable"
end

function Diagnostics:CopyAll()
    local chunks = {}
    for _, entry in ipairs(self.Entries) do
        table.insert(chunks, self:FormatEntry(entry, true))
    end
    local text = table.concat(chunks, "\n\n")
    local clipboard = setclipboard or toclipboard
    if type(clipboard) == "function" then
        local ok, err = pcall(clipboard, text)
        return ok, err
    end
    return false, "Clipboard API unavailable"
end

function Diagnostics:GetSelectedEntry()
    if not self._selectedId then
        return nil
    end
    for _, entry in ipairs(self.Entries) do
        if entry.id == self._selectedId then
            return entry
        end
    end
end

function Diagnostics:Clear(includeFatal)
    local kept = {}
    if includeFatal ~= true then
        for _, entry in ipairs(self.Entries) do
            if entry.fatal then
                table.insert(kept, entry)
            end
        end
    end
    self.Entries = kept
    self._duplicateIndex = {}
    self.Counts = { DEBUG = 0, INFO = 0, SUCCESS = 0, WARN = 0, ERROR = 0, FATAL = 0 }
    for _, entry in ipairs(self.Entries) do
        self._duplicateIndex[entry.key] = entry
        self.Counts[entry.severity] = (self.Counts[entry.severity] or 0) + 1
    end
    self._selectedId = nil
    self.Unread = 0
    self:_scheduleRender()
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function createStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function makeButton(parent, name, text, size)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size or UDim2.fromOffset(84, 30)
    button.BackgroundColor3 = Color3.fromRGB(20, 27, 34)
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Font = Enum.Font.GothamSemibold
    button.Text = text
    button.TextSize = 11
    button.TextColor3 = Color3.fromRGB(168, 181, 195)
    button.Parent = parent
    createCorner(button, 7)
    createStroke(button, Color3.fromRGB(61, 83, 100), 0.68, 1)
    return button
end

local function connectHover(button, baseColor, hoverColor)
    button.MouseEnter:Connect(function()
        button.TextColor3 = hoverColor
    end)
    button.MouseLeave:Connect(function()
        button.TextColor3 = baseColor
    end)
end

function Diagnostics:_getParent()
    local parent
    pcall(function()
        if type(gethui) == "function" then
            parent = gethui()
        end
    end)
    if not parent then
        pcall(function()
            local coreGui = game:GetService("CoreGui")
            parent = type(cloneref) == "function" and cloneref(coreGui) or coreGui
        end)
    end
    if not parent then
        pcall(function()
            parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        end)
    end
    return parent
end

-- BADWARS_CONSOLE_UI_V3_BEGIN
function Diagnostics:EnsureUI()
    if self.Destroyed then
        return nil
    end
    if self._ui and self._ui.gui and self._ui.gui.Parent then
        return self._ui
    end

    local parent = self:_getParent()
    if not parent then
        return nil
    end

    pcall(function()
        local previous = parent:FindFirstChild("BadWarsDiagnostics")
        if previous then
            previous:Destroy()
        end
    end)

    local tweenService = game:GetService("TweenService")
    local activeTweens = setmetatable({}, { __mode = "k" })
    local function animate(object, duration, properties, style, direction)
        if not object or not object.Parent then
            return nil
        end
        local old = activeTweens[object]
        if old then
            pcall(function()
                old:Cancel()
            end)
        end
        local ok, tween = pcall(function()
            return tweenService:Create(
                object,
                TweenInfo.new(duration or 0.1, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
                properties
            )
        end)
        if ok and tween then
            activeTweens[object] = tween
            tween.Completed:Once(function()
                if activeTweens[object] == tween then
                    activeTweens[object] = nil
                end
            end)
            tween:Play()
            return tween
        end
        for property, value in pairs(properties) do
            pcall(function()
                object[property] = value
            end)
        end
    end

    local function spring(object, profile, properties)
        if not object or not object.Parent then
            return false
        end

        local motion = shared and shared.BadWarsSpr
        if type(motion) ~= "table"
            or type(motion.target) ~= "function"
            or type(motion.stop) ~= "function"
        then
            animate(object, 0.12, properties, Enum.EasingStyle.Quint)
            return false
        end

        for property in pairs(properties) do
            pcall(motion.stop, object, property)
        end

        local ok = pcall(
            motion.target,
            object,
            profile and profile.Damping or 1,
            profile and profile.Frequency or 18,
            properties
        )
        if not ok then
            animate(object, 0.12, properties, Enum.EasingStyle.Quint)
        end
        return ok
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BadWarsDiagnostics"
    gui.DisplayOrder = 9999999
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local initialWidth = math.clamp(viewport.X - 24, 360, 960)
    local initialHeight = math.clamp(viewport.Y - 44, 380, 620)
    local minSize = Vector2.new(math.min(340, viewport.X - 16), math.min(320, viewport.Y - 16))
    local maxSize = Vector2.new(1280, 820)
    local compact = viewport.X < 720

    local opener = Instance.new("TextButton")
    opener.Name = "DiagnosticsButton"
    opener.AnchorPoint = Vector2.new(1, 0)
    opener.Position = UDim2.new(1, -16, 0, 14)
    opener.Size = UDim2.fromOffset(112, 34)
    opener.BackgroundColor3 = Color3.fromRGB(9, 14, 19)
    opener.BackgroundTransparency = 0.03
    opener.BorderSizePixel = 0
    opener.AutoButtonColor = false
    opener.Font = Enum.Font.GothamSemibold
    opener.Text = "Diagnostics"
    opener.TextSize = 10
    opener.TextColor3 = Color3.fromRGB(178, 191, 204)
    opener.TextXAlignment = Enum.TextXAlignment.Center
    opener.Parent = gui
    createCorner(opener, 9)
    local openerStroke = createStroke(opener, Color3.fromRGB(62, 77, 91), 0.58, 1)

    local badge = Instance.new("TextLabel")
    badge.Name = "Unread"
    badge.AnchorPoint = Vector2.new(1, 0)
    badge.Position = UDim2.new(1, 6, 0, -6)
    badge.Size = UDim2.fromOffset(20, 20)
    badge.BackgroundColor3 = Color3.fromRGB(244, 92, 115)
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.GothamBold
    badge.Text = "0"
    badge.TextSize = 9
    badge.TextColor3 = Color3.fromRGB(255, 255, 255)
    badge.Visible = false
    badge.Parent = opener
    createCorner(badge, 99)

    local backdrop = Instance.new("TextButton")
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(2, 4, 7)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel = 0
    backdrop.AutoButtonColor = false
    backdrop.Text = ""
    backdrop.Visible = false
    backdrop.Parent = gui

    local window = Instance.new("CanvasGroup")
    window.Name = "Window"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.Size = UDim2.fromOffset(initialWidth, initialHeight)
    window.BackgroundColor3 = Color3.fromRGB(7, 11, 15)
    window.BackgroundTransparency = 0.005
    window.BorderSizePixel = 0
    window.ClipsDescendants = false
    window.GroupTransparency = 1
    window.Visible = false
    window.Parent = gui
    createCorner(window, 16)
    createStroke(window, Color3.fromRGB(66, 82, 96), 0.42, 1)

    local windowScale = Instance.new("UIScale")
    windowScale.Scale = 0.975
    windowScale.Parent = window

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 58)
    header.BackgroundColor3 = Color3.fromRGB(10, 15, 20)
    header.BorderSizePixel = 0
    header.Parent = window

    local accent = Instance.new("Frame")
    accent.Position = UDim2.fromOffset(16, 14)
    accent.Size = UDim2.fromOffset(4, 27)
    accent.BackgroundColor3 = Color3.fromRGB(66, 214, 153)
    accent.BorderSizePixel = 0
    accent.Parent = header
    createCorner(accent, 99)

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(30, 8)
    title.Size = UDim2.fromOffset(220, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "RUNTIME CONSOLE"
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(241, 245, 248)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Position = UDim2.fromOffset(30, 29)
    subtitle.Size = UDim2.fromOffset(260, 16)
    subtitle.BackgroundTransparency = 1
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = "Live events, warnings, errors, and execution context"
    subtitle.TextSize = 9
    subtitle.TextColor3 = Color3.fromRGB(103, 117, 131)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    local counters = Instance.new("TextLabel")
    counters.Name = "Counters"
    counters.AnchorPoint = Vector2.new(1, 0.5)
    counters.Position = UDim2.new(1, -52, 0.5, 0)
    counters.Size = UDim2.fromOffset(250, 24)
    counters.BackgroundTransparency = 1
    counters.Font = Enum.Font.GothamMedium
    counters.Text = "0 errors   0 warnings"
    counters.TextSize = 9
    counters.TextColor3 = Color3.fromRGB(116, 130, 143)
    counters.TextXAlignment = Enum.TextXAlignment.Right
    counters.Parent = header

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -12, 0.5, 0)
    close.Size = UDim2.fromOffset(28, 28)
    close.BackgroundColor3 = Color3.fromRGB(244, 92, 115)
    close.BackgroundTransparency = 0.9
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Font = Enum.Font.GothamSemibold
    close.Text = "X"
    close.TextSize = 14
    close.TextColor3 = Color3.fromRGB(169, 177, 186)
    close.Parent = header
    createCorner(close, 7)

    local toolbar = Instance.new("Frame")
    toolbar.Name = "Toolbar"
    toolbar.Position = UDim2.fromOffset(16, 72)
    toolbar.Size = UDim2.new(1, -32, 0, compact and 116 or 80)
    toolbar.BackgroundTransparency = 1
    toolbar.Parent = window

    local function makeInput(name, placeholder, position, size)
        local box = Instance.new("TextBox")
        box.Name = name
        box.Position = position
        box.Size = size
        box.BackgroundColor3 = Color3.fromRGB(12, 18, 24)
        box.BorderSizePixel = 0
        box.ClearTextOnFocus = false
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(82, 96, 109)
        box.Font = Enum.Font.Gotham
        box.Text = ""
        box.TextSize = 10
        box.TextColor3 = Color3.fromRGB(208, 216, 224)
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.Parent = toolbar
        createCorner(box, 8)
        local boxStroke = createStroke(box, Color3.fromRGB(54, 68, 81), 0.62, 1)
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 11)
        padding.PaddingRight = UDim.new(0, 11)
        padding.Parent = box
        box.Focused:Connect(function()
            animate(boxStroke, 0.08, { Transparency = 0.2, Color = Color3.fromRGB(66, 214, 153) })
        end)
        box.FocusLost:Connect(function()
            animate(boxStroke, 0.08, { Transparency = 0.62, Color = Color3.fromRGB(54, 68, 81) })
        end)
        return box
    end

    local search = makeInput(
        "Search",
        "Search logs",
        UDim2.fromOffset(0, 0),
        compact and UDim2.new(1, -74, 0, 32) or UDim2.new(0.46, -4, 0, 32)
    )
    local sourceFilter = makeInput("SourceFilter", "Subsystem", UDim2.new(0.46, 4, 0, 0), UDim2.new(0.22, -4, 0, 32))
    local moduleFilter = makeInput("ModuleFilter", "Module or file", UDim2.new(0.68, 8, 0, 0), UDim2.new(0.2, -4, 0, 32))
    sourceFilter.Visible = not compact
    moduleFilter.Visible = not compact

    local pause = makeButton(toolbar, "Pause", "Pause", UDim2.fromOffset(66, 32))
    pause.AnchorPoint = Vector2.new(1, 0)
    pause.Position = UDim2.new(1, 0, 0, 0)

    local filters = Instance.new("Frame")
    filters.Name = "Filters"
    filters.Position = UDim2.fromOffset(0, 42)
    filters.Size = compact and UDim2.new(1, 0, 0, 26) or UDim2.new(1, -278, 0, 26)
    filters.BackgroundTransparency = 1
    filters.Parent = toolbar

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 5)
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Parent = filters

    local enabledLevels = {}
    local filterButtons = {}
    local filterOrder = { "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR", "FATAL" }
    for _, level in ipairs(filterOrder) do
        enabledLevels[level] = true
        local button = Instance.new("TextButton")
        button.Name = level
        button.Size = UDim2.fromOffset(
            compact and (level == "SUCCESS" and 54 or 39) or (level == "SUCCESS" and 66 or 52),
            24
        )
        button.BackgroundColor3 = Color3.fromRGB(12, 18, 24)
        button.BackgroundTransparency = 0.02
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamSemibold
        button.Text = string.lower(level)
        button.TextSize = 9
        button.TextColor3 = LEVEL_COLORS[level]
        button.Parent = filters
        createCorner(button, 7)
        local levelStroke = createStroke(button, LEVEL_COLORS[level], 0.76, 1)
        filterButtons[level] = button
        button.MouseEnter:Connect(function()
            animate(button, 0.075, { BackgroundTransparency = 0 })
            animate(levelStroke, 0.075, { Transparency = 0.44 })
        end)
        button.MouseLeave:Connect(function()
            animate(button, 0.075, { BackgroundTransparency = enabledLevels[level] and 0.02 or 0.5 })
            animate(levelStroke, 0.075, { Transparency = enabledLevels[level] and 0.76 or 0.92 })
        end)
        button.Activated:Connect(function()
            enabledLevels[level] = not enabledLevels[level]
            animate(button, 0.075, {
                BackgroundTransparency = enabledLevels[level] and 0.02 or 0.5,
                TextTransparency = enabledLevels[level] and 0 or 0.55,
            })
            animate(levelStroke, 0.075, { Transparency = enabledLevels[level] and 0.76 or 0.92 })
            self:_scheduleRender()
        end)
    end

    local actions = Instance.new("Frame")
    actions.AnchorPoint = Vector2.new(1, 0)
    actions.Position = compact and UDim2.new(1, 0, 0, 78) or UDim2.new(1, 0, 0, 42)
    actions.Size = compact and UDim2.new(1, 0, 0, 26) or UDim2.fromOffset(270, 26)
    actions.BackgroundTransparency = 1
    actions.Parent = toolbar
    local actionLayout = Instance.new("UIListLayout")
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionLayout.Padding = UDim.new(0, 5)
    actionLayout.Parent = actions

    local function action(name, text, width)
        local button = makeButton(actions, name, text, UDim2.fromOffset(width, 24))
        button.BackgroundTransparency = 1
        button.TextColor3 = Color3.fromRGB(122, 136, 149)
        button.TextSize = 9
        return button
    end
    local autoScroll = action("AutoScroll", "Auto-scroll", 76)
    local copySelected = action("CopySelected", "Copy entry", 68)
    local copyAll = action("CopyAll", "Copy all", 52)
    local clear = action("Clear", "Clear", 44)

    local list = Instance.new("ScrollingFrame")
    list.Name = "Entries"
    list.Position = UDim2.fromOffset(14, compact and 190 or 154)
    list.Size = UDim2.new(1, -28, 1, compact and -224 or -188)
    list.BackgroundColor3 = Color3.fromRGB(7, 11, 15)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = Color3.fromRGB(69, 84, 97)
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = window
    createCorner(list, 10)
    createStroke(list, Color3.fromRGB(45, 58, 70), 0.58, 1)

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 6)
    listPadding.PaddingBottom = UDim.new(0, 6)
    listPadding.PaddingLeft = UDim.new(0, 6)
    listPadding.PaddingRight = UDim.new(0, 6)
    listPadding.Parent = list

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 5)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Position = UDim2.new(0, 16, 1, -28)
    footer.Size = UDim2.new(1, -58, 0, 18)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Gotham
    footer.Text = "F8  |  0 entries"
    footer.TextSize = 9
    footer.TextColor3 = Color3.fromRGB(76, 90, 103)
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.Parent = window

    local resize = Instance.new("TextButton")
    resize.Name = "Resize"
    resize.AnchorPoint = Vector2.new(1, 1)
    resize.Position = UDim2.fromScale(1, 1)
    resize.Size = UDim2.fromOffset(30, 30)
    resize.BackgroundTransparency = 1
    resize.BorderSizePixel = 0
    resize.AutoButtonColor = false
    resize.Font = Enum.Font.Code
    resize.Text = "//"
    resize.TextSize = 13
    resize.TextColor3 = Color3.fromRGB(82, 96, 109)
    resize.Parent = window

    self._ui = {
        gui = gui,
        opener = opener,
        badge = badge,
        backdrop = backdrop,
        window = window,
        windowScale = windowScale,
        header = header,
        counters = counters,
        close = close,
        search = search,
        sourceFilter = sourceFilter,
        moduleFilter = moduleFilter,
        pause = pause,
        clear = clear,
        copySelected = copySelected,
        copyAll = copyAll,
        autoScroll = autoScroll,
        autoScrollEnabled = true,
        list = list,
        listLayout = listLayout,
        footer = footer,
        enabledLevels = enabledLevels,
        filterButtons = filterButtons,
        expanded = {},
        minSize = minSize,
        maxSize = maxSize,
        animate = animate,
        spring = spring,
        openGeneration = 0,
        isOpen = false,
        compact = compact,
    }

    opener.MouseEnter:Connect(function()
        animate(opener, 0.08, { BackgroundColor3 = Color3.fromRGB(17, 24, 31), TextColor3 = Color3.fromRGB(230, 236, 242) })
        animate(openerStroke, 0.08, { Transparency = 0.28 })
    end)
    opener.MouseLeave:Connect(function()
        animate(opener, 0.08, { BackgroundColor3 = Color3.fromRGB(10, 15, 20), TextColor3 = Color3.fromRGB(178, 191, 204) })
        animate(openerStroke, 0.08, { Transparency = 0.58 })
    end)
    close.MouseEnter:Connect(function()
        animate(close, 0.075, { BackgroundTransparency = 0.72, TextColor3 = Color3.fromRGB(255, 255, 255) })
    end)
    close.MouseLeave:Connect(function()
        animate(close, 0.075, { BackgroundTransparency = 0.9, TextColor3 = Color3.fromRGB(169, 177, 186) })
    end)

    opener.Activated:Connect(function() self:Toggle() end)
    close.Activated:Connect(function() self:Close() end)
    backdrop.Activated:Connect(function() self:Close() end)
    clear.Activated:Connect(function() self:Clear(false) end)
    copySelected.Activated:Connect(function()
        local ok, err = self:CopyEntry()
        if not ok then
            self:Warn(err, { subsystem = "DiagnosticsUI", native = false })
        end
    end)
    copyAll.Activated:Connect(function()
        local ok, err = self:CopyAll()
        if not ok then
            self:Warn(err, { subsystem = "DiagnosticsUI", native = false })
        end
    end)
    pause.Activated:Connect(function()
        self.Paused = not self.Paused
        pause.Text = self.Paused and "Resume" or "Pause"
        pause.TextColor3 = self.Paused and LEVEL_COLORS.WARN or Color3.fromRGB(168, 181, 195)
        if not self.Paused then
            self:_scheduleRender()
        end
    end)
    autoScroll.Activated:Connect(function()
        self._ui.autoScrollEnabled = not self._ui.autoScrollEnabled
        autoScroll.TextColor3 = self._ui.autoScrollEnabled and Color3.fromRGB(122, 136, 149) or Color3.fromRGB(75, 88, 100)
    end)

    search:GetPropertyChangedSignal("Text"):Connect(function() self:_scheduleRender() end)
    sourceFilter:GetPropertyChangedSignal("Text"):Connect(function() self:_scheduleRender() end)
    moduleFilter:GetPropertyChangedSignal("Text"):Connect(function() self:_scheduleRender() end)

    local userInput = game:GetService("UserInputService")
    local activeInteraction
    local changedConnection
    local endedConnection

    local function stopInteraction()
        activeInteraction = nil
        if changedConnection then
            changedConnection:Disconnect()
            changedConnection = nil
        end
        if endedConnection then
            endedConnection:Disconnect()
            endedConnection = nil
        end
    end

    local function beginInteraction(input, mode)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch
        then
            return
        end

        stopInteraction()
        local expectedMovement = input.UserInputType == Enum.UserInputType.MouseButton1
                and Enum.UserInputType.MouseMovement
            or Enum.UserInputType.Touch
        local currentViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)

        activeInteraction = {
            Mode = mode,
            StartPointer = input.Position,
            StartPosition = window.Position,
            StartSize = window.AbsoluteSize,
            ExpectedMovement = expectedMovement,
            Viewport = currentViewport,
            MinWidth = math.min(minSize.X, currentViewport.X - 16),
            MaxWidth = math.min(maxSize.X, currentViewport.X - 16),
            MinHeight = math.min(minSize.Y, currentViewport.Y - 16),
            MaxHeight = math.min(maxSize.Y, currentViewport.Y - 16),
        }

        changedConnection = userInput.InputChanged:Connect(function(changed)
            local state = activeInteraction
            if not state or changed.UserInputType ~= state.ExpectedMovement then
                return
            end

            local delta = changed.Position - state.StartPointer
            if state.Mode == "drag" then
                window.Position = UDim2.new(
                    state.StartPosition.X.Scale,
                    state.StartPosition.X.Offset + delta.X,
                    state.StartPosition.Y.Scale,
                    state.StartPosition.Y.Offset + delta.Y
                )
            else
                window.Size = UDim2.fromOffset(
                    math.clamp(state.StartSize.X + delta.X, state.MinWidth, state.MaxWidth),
                    math.clamp(state.StartSize.Y + delta.Y, state.MinHeight, state.MaxHeight)
                )
            end
        end)

        endedConnection = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End
                or input.UserInputState == Enum.UserInputState.Cancel
            then
                stopInteraction()
            end
        end)
    end

    header.InputBegan:Connect(function(input)
        beginInteraction(input, "drag")
    end)

    resize.InputBegan:Connect(function(input)
        beginInteraction(input, "resize")
    end)
    gui.Destroying:Once(stopInteraction)

    local keyConnection = userInput.InputBegan:Connect(function(input, processed)
        if not processed and input.KeyCode == Enum.KeyCode.F8 then
            self:Toggle()
        end
    end)
    table.insert(self.Connections, keyConnection)

    self:_scheduleRender()
    return self._ui
end
-- BADWARS_CONSOLE_UI_V3_END
function Diagnostics:_entryMatches(entry)
    local ui = self._ui
    if not ui then
        return true
    end
    if not ui.enabledLevels[entry.severity] then
        return false
    end

    local search = string.lower(ui.search.Text or "")
    local sourceFilter = string.lower(ui.sourceFilter.Text or "")
    local moduleFilter = string.lower(ui.moduleFilter.Text or "")
    local haystack = string.lower(table.concat({
        entry.message or "",
        entry.traceback or "",
        entry.subsystem or "",
        entry.module or "",
        entry.file or "",
        entry.stage or "",
    }, "\n"))

    if search ~= "" and not string.find(haystack, search, 1, true) then
        return false
    end
    if sourceFilter ~= "" and not string.find(string.lower(entry.subsystem or ""), sourceFilter, 1, true) then
        return false
    end
    if moduleFilter ~= "" and not string.find(string.lower((entry.module or "") .. " " .. (entry.file or "")), moduleFilter, 1, true) then
        return false
    end
    return true
end

-- BADWARS_CONSOLE_RENDER_V1_BEGIN
function Diagnostics:_render()
    local ui = self._ui
    if not ui or not ui.gui.Parent then
        return
    end

    ui.badge.Visible = self.Unread > 0
    ui.badge.Text = self.Unread > 99 and "99+" or tostring(self.Unread)
    local errorCount = (self.Counts.ERROR or 0) + (self.Counts.FATAL or 0)
    local warningCount = self.Counts.WARN or 0
    ui.counters.Text = string.format("%d errors   %d warnings", errorCount, warningCount)
    ui.footer.Text = string.format("F8  |  %d entries  |  %s", #self.Entries, self.Paused and "paused" or "live")
    if self.Paused then
        return
    end

    for _, child in ipairs(ui.list:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local visible = {}
    for index = #self.Entries, 1, -1 do
        local entry = self.Entries[index]
        if self:_entryMatches(entry) then
            table.insert(visible, 1, entry)
            if #visible >= self.MaxVisibleEntries then
                break
            end
        end
    end

    for order, entry in ipairs(visible) do
        local expanded = ui.expanded[entry.id] == true
        local selected = self._selectedId == entry.id
        local rowHeight = ui.compact and (expanded and 164 or 58) or (expanded and 150 or 44)
        local severityColor = LEVEL_COLORS[entry.severity] or Color3.fromRGB(120, 135, 148)

        local row = Instance.new("TextButton")
        row.Name = "Entry_" .. tostring(entry.id)
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, rowHeight)
        row.BackgroundColor3 = selected and Color3.fromRGB(17, 24, 31) or Color3.fromRGB(10, 15, 20)
        row.BackgroundTransparency = selected and 0 or 0.08
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = ui.list
        createCorner(row, 8)
        local rowStroke = createStroke(row, selected and severityColor or Color3.fromRGB(42, 55, 67), selected and 0.42 or 0.78, 1)

        local accent = Instance.new("Frame")
        accent.Position = UDim2.fromOffset(0, 8)
        accent.Size = UDim2.new(0, 3, 0, ui.compact and 42 or 28)
        accent.BackgroundColor3 = severityColor
        accent.BorderSizePixel = 0
        accent.Parent = row
        createCorner(accent, 99)

        local timestamp = Instance.new("TextLabel")
        timestamp.Position = UDim2.fromOffset(14, 0)
        timestamp.Size = UDim2.fromOffset(58, ui.compact and 28 or 44)
        timestamp.BackgroundTransparency = 1
        timestamp.Font = Enum.Font.Code
        timestamp.Text = entry.timestamp or "--:--:--"
        timestamp.TextSize = 9
        timestamp.TextColor3 = Color3.fromRGB(86, 101, 114)
        timestamp.TextXAlignment = Enum.TextXAlignment.Left
        timestamp.Parent = row

        local sourceText = entry.subsystem ~= "" and entry.subsystem or "runtime"
        if entry.module and entry.module ~= "" then
            sourceText = sourceText .. "/" .. entry.module
        end
        local source = Instance.new("TextLabel")
        source.Position = UDim2.fromOffset(76, 0)
        source.Size = ui.compact and UDim2.new(1, -90, 0, 28) or UDim2.fromOffset(145, 44)
        source.BackgroundTransparency = 1
        source.Font = Enum.Font.GothamMedium
        source.Text = sourceText
        source.TextSize = 9
        source.TextColor3 = severityColor:Lerp(Color3.fromRGB(165, 177, 188), 0.55)
        source.TextXAlignment = Enum.TextXAlignment.Left
        source.TextTruncate = Enum.TextTruncate.AtEnd
        source.Parent = row

        local repeatSuffix = (entry.repeatCount or 1) > 1 and ("  x" .. tostring(entry.repeatCount)) or ""
        local message = Instance.new("TextLabel")
        message.Position = ui.compact and UDim2.fromOffset(14, 27) or UDim2.fromOffset(226, 0)
        message.Size = ui.compact and UDim2.new(1, -28, 0, 27) or UDim2.new(1, -240, 0, 44)
        message.BackgroundTransparency = 1
        message.Font = Enum.Font.Gotham
        message.Text = tostring(entry.message or "") .. repeatSuffix
        message.TextSize = 10
        message.TextColor3 = Color3.fromRGB(198, 208, 217)
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextTruncate = Enum.TextTruncate.AtEnd
        message.Parent = row

        if expanded then
            local details = Instance.new("TextLabel")
            details.Position = UDim2.fromOffset(14, ui.compact and 64 or 50)
            details.Size = UDim2.new(1, -28, 0, ui.compact and 88 or 88)
            details.BackgroundColor3 = Color3.fromRGB(6, 10, 14)
            details.BorderSizePixel = 0
            details.Font = Enum.Font.Code
            details.Text = self:FormatEntry(entry, true)
            details.TextSize = 9
            details.TextColor3 = Color3.fromRGB(126, 143, 157)
            details.TextXAlignment = Enum.TextXAlignment.Left
            details.TextYAlignment = Enum.TextYAlignment.Top
            details.TextWrapped = true
            details.Parent = row
            createCorner(details, 7)
            createStroke(details, Color3.fromRGB(40, 53, 65), 0.58, 1)
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 8)
            padding.PaddingBottom = UDim.new(0, 8)
            padding.PaddingLeft = UDim.new(0, 9)
            padding.PaddingRight = UDim.new(0, 9)
            padding.Parent = details
        end

        row.MouseEnter:Connect(function()
            ui.animate(row, 0.075, { BackgroundColor3 = Color3.fromRGB(17, 24, 31), BackgroundTransparency = 0 })
            ui.animate(rowStroke, 0.075, { Transparency = 0.48, Color = severityColor:Lerp(Color3.fromRGB(66, 82, 96), 0.55) })
        end)
        row.MouseLeave:Connect(function()
            ui.animate(row, 0.075, { BackgroundColor3 = selected and Color3.fromRGB(17, 24, 31) or Color3.fromRGB(10, 15, 20), BackgroundTransparency = selected and 0 or 0.08 })
            ui.animate(rowStroke, 0.075, { Transparency = selected and 0.42 or 0.78, Color = selected and severityColor or Color3.fromRGB(42, 55, 67) })
        end)
        row.Activated:Connect(function()
            self._selectedId = entry.id
            ui.expanded[entry.id] = not ui.expanded[entry.id]
            self:_scheduleRender()
        end)
    end

    if ui.window.Visible and ui.autoScrollEnabled and #visible > 0 then
        task.defer(function()
            if ui.list and ui.list.Parent then
                ui.list.CanvasPosition = Vector2.new(0, math.max(0, ui.list.AbsoluteCanvasSize.Y))
            end
        end)
    end
end
-- BADWARS_CONSOLE_RENDER_V2_END
function Diagnostics:_scheduleRender()
    if self._renderPending then
        return
    end
    self._renderPending = true
    task.defer(function()
        self._renderPending = false
        self:EnsureUI()
        self:_render()
    end)
end

function Diagnostics:Open()
    local ui = self:EnsureUI()
    if not ui then
        return
    end
    ui.openGeneration += 1
    ui.isOpen = true
    ui.backdrop.Visible = true
    ui.window.Visible = true
    ui.window.GroupTransparency = 1
    ui.windowScale.Scale = 0.975
    ui.animate(ui.backdrop, 0.14, { BackgroundTransparency = 0.38 }, Enum.EasingStyle.Quart)
    ui.animate(ui.window, 0.16, { GroupTransparency = 0 }, Enum.EasingStyle.Quint)
    ui.spring(ui.windowScale, { Damping = 1, Frequency = 18 }, { Scale = 1 })
    self.Unread = 0
    self:_scheduleRender()
end

function Diagnostics:Close()
    local ui = self:EnsureUI()
    if not ui or not ui.window.Visible then
        return
    end
    ui.openGeneration += 1
    ui.isOpen = false
    local generation = ui.openGeneration
    ui.animate(ui.backdrop, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    ui.animate(ui.window, 0.13, { GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    ui.spring(ui.windowScale, { Damping = 1, Frequency = 22 }, { Scale = 0.985 })
    task.delay(0.14, function()
        if self._ui == ui and ui.openGeneration == generation then
            ui.window.Visible = false
            ui.backdrop.Visible = false
        end
    end)
end

function Diagnostics:Toggle()
    local ui = self:EnsureUI()
    if not ui then
        return
    end
    if ui.isOpen then
        self:Close()
    else
        self:Open()
    end
end

function Diagnostics:AttachToBadGui(api)
    if type(api) ~= "table" then
        return false
    end
    api.Diagnostics = self
    api.OpenDiagnostics = function()
        self:Open()
    end
    api.ToggleDiagnostics = function()
        self:Toggle()
    end
    return true
end

function Diagnostics:InstallNativeCapture()
    if self._messageConnection then
        return true
    end
    local ok, logService = pcall(function()
        return game:GetService("LogService")
    end)
    if not ok or not logService or not logService.MessageOut then
        self:Debug("LogService.MessageOut is unavailable", {
            subsystem = "Diagnostics",
            native = false,
        })
        return false
    end

    local connected, connection = pcall(function()
        return logService.MessageOut:Connect(function(message, messageType)
            if self.Destroyed or self._nativeDepth > 0 then
                return
            end

            local typeText = safeString(messageType)
            local level = "INFO"
            if string.find(typeText, "Warning", 1, true) then
                level = "WARN"
            elseif string.find(typeText, "Error", 1, true) then
                level = "ERROR"
            elseif string.find(typeText, "Info", 1, true) then
                level = "INFO"
            end

            self:_push(level, message, level == "ERROR" and self:Traceback(message, 3) or nil, {
                subsystem = "RobloxLog",
                stage = self.CurrentStage,
                caught = false,
                native = false,
            })
        end)
    end)

    if connected then
        self._messageConnection = connection
        table.insert(self.Connections, connection)
        return true
    end
    return false
end

function Diagnostics:RunSelfTests()
    self:Warn("Self-test warning", {
        subsystem = "DiagnosticsSelfTest",
        module = "Warning",
        native = true,
    })

    self:Capture(function()
        error("Self-test runtime error")
    end, {
        subsystem = "DiagnosticsSelfTest",
        module = "Runtime",
        file = "diagnostics.lua",
    })

    self:Compile("local =", "diagnostics-self-test-compile", {
        subsystem = "DiagnosticsSelfTest",
        module = "Compile",
        file = "diagnostics-self-test.lua",
    })

    self:Spawn(function()
        error("Self-test asynchronous callback error")
    end, {
        subsystem = "DiagnosticsSelfTest",
        module = "Async",
        file = "diagnostics.lua",
    })

    self:Error("Self-test simulated download failure", "HTTP 599 simulated failure", {
        subsystem = "HTTP",
        module = "Download",
        file = "https://invalid.badwars.local/self-test",
    })

    for _ = 1, 5 do
        self:Error("Self-test duplicate error", "duplicate trace", {
            subsystem = "DiagnosticsSelfTest",
            module = "Duplicate",
            file = "diagnostics.lua",
            native = false,
        })
    end
end

function Diagnostics:Destroy(reason)
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(self.Connections)
    table.clear(self.Subscribers)
    if self._ui and self._ui.gui then
        pcall(function()
            self._ui.gui:Destroy()
        end)
    end
    self._ui = nil
    if shared.BadDiagnostics == self then
        shared.BadDiagnostics = nil
    end
end

shared.BadDiagnostics = Diagnostics
Diagnostics:InstallNativeCapture()

local earlyBuffer = shared.__badwars_diagnostic_buffer
shared.__badwars_diagnostic_buffer = {}
for _, buffered in ipairs(earlyBuffer) do
    if type(buffered) == "table" then
        Diagnostics:_push(
            buffered.severity or buffered.level or "ERROR",
            buffered.message or buffered.error or "Buffered startup error",
            buffered.traceback,
            {
                subsystem = buffered.subsystem or "Bootstrap",
                module = buffered.module,
                file = buffered.file or buffered.path,
                stage = buffered.stage or "bootstrap",
                fatal = buffered.fatal,
                caught = buffered.caught ~= false,
                native = buffered.native ~= false,
            }
        )
    else
        Diagnostics:Error(safeString(buffered), nil, {
            subsystem = "Bootstrap",
            stage = "bootstrap",
        })
    end
end

task.defer(function()
    Diagnostics:EnsureUI()
    for _ = 1, 120 do
        if Diagnostics.Destroyed then
            return
        end
        if type(shared.Bad) == "table" then
            Diagnostics:AttachToBadGui(shared.Bad)
            break
        end
        task.wait(0.5)
    end
end)

if shared.BadDiagnosticsSelfTest == true then
    task.defer(function()
        Diagnostics:RunSelfTests()
    end)
end

return Diagnostics
