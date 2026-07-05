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
    MaxVisibleEntries = 300,
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
    createStroke(button, Color3.fromRGB(64, 78, 92), 0.68, 1)
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

-- BADWARS_CONSOLE_UI_V1_BEGIN
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

    local gui = Instance.new("ScreenGui")
    gui.Name = "BadWarsDiagnostics"
    gui.DisplayOrder = 9999999
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local viewport = workspace.CurrentCamera
        and workspace.CurrentCamera.ViewportSize
        or Vector2.new(1280, 720)

    local initialWidth = math.clamp(viewport.X - 32, 480, 780)
    local initialHeight = math.clamp(viewport.Y - 48, 320, 470)
    local minSize = Vector2.new(440, 300)
    local maxSize = Vector2.new(1180, 780)

    local opener = Instance.new("TextButton")
    opener.Name = "DiagnosticsButton"
    opener.AnchorPoint = Vector2.new(1, 0)
    opener.Position = UDim2.new(1, -14, 0, 14)
    opener.Size = UDim2.fromOffset(94, 28)
    opener.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
    opener.BorderSizePixel = 0
    opener.AutoButtonColor = false
    opener.Font = Enum.Font.GothamMedium
    opener.Text = ">_  Console"
    opener.TextSize = 10
    opener.TextColor3 = Color3.fromRGB(184, 188, 197)
    opener.Parent = gui
    createCorner(opener, 6)
    createStroke(opener, Color3.fromRGB(55, 59, 68), 0.38, 1)

    local badge = Instance.new("TextLabel")
    badge.Name = "Unread"
    badge.AnchorPoint = Vector2.new(1, 0)
    badge.Position = UDim2.new(1, 6, 0, -6)
    badge.Size = UDim2.fromOffset(18, 18)
    badge.BackgroundColor3 = Color3.fromRGB(218, 83, 94)
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.GothamSemibold
    badge.Text = "0"
    badge.TextSize = 9
    badge.TextColor3 = Color3.fromRGB(255, 245, 246)
    badge.Visible = false
    badge.Parent = opener
    createCorner(badge, 99)

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.Size = UDim2.fromOffset(initialWidth, initialHeight)
    window.BackgroundColor3 = Color3.fromRGB(12, 14, 17)
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Visible = false
    window.Parent = gui
    createCorner(window, 8)
    createStroke(window, Color3.fromRGB(50, 54, 63), 0.24, 1)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 42)
    header.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
    header.BorderSizePixel = 0
    header.Parent = window

    local headerLine = Instance.new("Frame")
    headerLine.AnchorPoint = Vector2.new(0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, 0)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.BackgroundColor3 = Color3.fromRGB(47, 50, 58)
    headerLine.BackgroundTransparency = 0.32
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(14, 0)
    title.Size = UDim2.new(0, 220, 1, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.Text = "BadWars Console"
    title.TextSize = 13
    title.TextColor3 = Color3.fromRGB(232, 234, 239)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local liveDot = Instance.new("Frame")
    liveDot.Position = UDim2.fromOffset(133, 18)
    liveDot.Size = UDim2.fromOffset(6, 6)
    liveDot.BackgroundColor3 = Color3.fromRGB(70, 196, 150)
    liveDot.BorderSizePixel = 0
    liveDot.Parent = header
    createCorner(liveDot, 99)

    local counters = Instance.new("TextLabel")
    counters.Name = "Counters"
    counters.AnchorPoint = Vector2.new(1, 0.5)
    counters.Position = UDim2.new(1, -46, 0.5, 0)
    counters.Size = UDim2.fromOffset(260, 24)
    counters.BackgroundTransparency = 1
    counters.Font = Enum.Font.Code
    counters.Text = "0 errors  -  0 warnings"
    counters.TextSize = 10
    counters.TextColor3 = Color3.fromRGB(107, 112, 123)
    counters.TextXAlignment = Enum.TextXAlignment.Right
    counters.Parent = header

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -10, 0.5, 0)
    close.Size = UDim2.fromOffset(26, 26)
    close.BackgroundTransparency = 1
    close.BorderSizePixel = 0
    close.AutoButtonColor = false
    close.Font = Enum.Font.GothamMedium
    close.Text = "x"
    close.TextSize = 17
    close.TextColor3 = Color3.fromRGB(139, 144, 154)
    close.Parent = header

    local toolbar = Instance.new("Frame")
    toolbar.Name = "Toolbar"
    toolbar.Position = UDim2.fromOffset(12, 52)
    toolbar.Size = UDim2.new(1, -24, 0, 66)
    toolbar.BackgroundTransparency = 1
    toolbar.Parent = window

    local function makeInput(name, placeholder, position, size)
        local box = Instance.new("TextBox")
        box.Name = name
        box.Position = position
        box.Size = size
        box.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
        box.BorderSizePixel = 0
        box.ClearTextOnFocus = false
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(89, 94, 104)
        box.Font = Enum.Font.Gotham
        box.Text = ""
        box.TextSize = 10
        box.TextColor3 = Color3.fromRGB(205, 208, 215)
        box.TextXAlignment = Enum.TextXAlignment.Left
        box.Parent = toolbar
        createCorner(box, 5)
        createStroke(box, Color3.fromRGB(50, 54, 63), 0.48, 1)

        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 9)
        padding.PaddingRight = UDim.new(0, 9)
        padding.Parent = box

        return box
    end

    local search = makeInput(
        "Search",
        "Search output",
        UDim2.fromOffset(0, 0),
        UDim2.new(0.42, -4, 0, 28)
    )

    local sourceFilter = makeInput(
        "SourceFilter",
        "Source",
        UDim2.new(0.42, 4, 0, 0),
        UDim2.new(0.2, -4, 0, 28)
    )

    local moduleFilter = makeInput(
        "ModuleFilter",
        "Module",
        UDim2.new(0.62, 8, 0, 0),
        UDim2.new(0.2, -4, 0, 28)
    )

    local function makeToolbarButton(name, text, xOffset, width)
        local button = Instance.new("TextButton")
        button.Name = name
        button.AnchorPoint = Vector2.new(1, 0)
        button.Position = UDim2.new(1, xOffset, 0, 0)
        button.Size = UDim2.fromOffset(width, 28)
        button.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamMedium
        button.Text = text
        button.TextSize = 10
        button.TextColor3 = Color3.fromRGB(164, 168, 177)
        button.Parent = toolbar
        createCorner(button, 5)
        createStroke(button, Color3.fromRGB(50, 54, 63), 0.48, 1)
        return button
    end

    local pause = makeToolbarButton("Pause", "Pause", 0, 58)

    local filters = Instance.new("Frame")
    filters.Name = "Filters"
    filters.Position = UDim2.fromOffset(0, 38)
    filters.Size = UDim2.new(1, 0, 0, 28)
    filters.BackgroundTransparency = 1
    filters.Parent = toolbar

    local enabledLevels = {}
    local filterButtons = {}
    local filterOrder = { "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR", "FATAL" }

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 4)
    filterLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    filterLayout.Parent = filters

    for _, level in ipairs(filterOrder) do
        enabledLevels[level] = true

        local button = Instance.new("TextButton")
        button.Name = level
        button.Size = UDim2.fromOffset(level == "SUCCESS" and 66 or 52, 24)
        button.BackgroundColor3 = Color3.fromRGB(17, 19, 23)
        button.BackgroundTransparency = 0
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Font = Enum.Font.Code
        button.Text = string.lower(level)
        button.TextSize = 9
        button.TextColor3 = LEVEL_COLORS[level]
        button.Parent = filters
        createCorner(button, 4)
        createStroke(button, Color3.fromRGB(45, 49, 57), 0.58, 1)

        filterButtons[level] = button

        button.Activated:Connect(function()
            enabledLevels[level] = not enabledLevels[level]
            button.TextTransparency = enabledLevels[level] and 0 or 0.58
            button.BackgroundTransparency = enabledLevels[level] and 0 or 0.46
            self:_scheduleRender()
        end)
    end

    local actionHolder = Instance.new("Frame")
    actionHolder.AnchorPoint = Vector2.new(1, 0)
    actionHolder.Position = UDim2.new(1, 0, 0, 38)
    actionHolder.Size = UDim2.fromOffset(250, 28)
    actionHolder.BackgroundTransparency = 1
    actionHolder.Parent = toolbar

    local actionLayout = Instance.new("UIListLayout")
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionLayout.Padding = UDim.new(0, 4)
    actionLayout.Parent = actionHolder

    local function makeAction(name, text, width)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.fromOffset(width, 24)
        button.BackgroundTransparency = 1
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Font = Enum.Font.GothamMedium
        button.Text = text
        button.TextSize = 9
        button.TextColor3 = Color3.fromRGB(128, 133, 144)
        button.Parent = actionHolder
        return button
    end

    local autoScroll = makeAction("AutoScroll", "Auto-scroll: on", 92)
    local copySelected = makeAction("CopySelected", "Copy entry", 64)
    local copyAll = makeAction("CopyAll", "Copy all", 52)
    local clear = makeAction("Clear", "Clear", 38)

    local list = Instance.new("ScrollingFrame")
    list.Name = "Entries"
    list.Position = UDim2.fromOffset(12, 126)
    list.Size = UDim2.new(1, -24, 1, -156)
    list.BackgroundColor3 = Color3.fromRGB(10, 12, 15)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = Color3.fromRGB(77, 81, 91)
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = window
    createCorner(list, 5)
    createStroke(list, Color3.fromRGB(43, 46, 54), 0.42, 1)

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 4)
    listPadding.PaddingBottom = UDim.new(0, 4)
    listPadding.Parent = list

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 0)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local footer = Instance.new("TextLabel")
    footer.Name = "Footer"
    footer.Position = UDim2.new(0, 14, 1, -25)
    footer.Size = UDim2.new(1, -52, 0, 18)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Code
    footer.Text = "F8  -  0 entries"
    footer.TextSize = 9
    footer.TextColor3 = Color3.fromRGB(78, 83, 93)
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.Parent = window

    local resize = Instance.new("TextButton")
    resize.Name = "Resize"
    resize.AnchorPoint = Vector2.new(1, 1)
    resize.Position = UDim2.fromScale(1, 1)
    resize.Size = UDim2.fromOffset(24, 24)
    resize.BackgroundTransparency = 1
    resize.BorderSizePixel = 0
    resize.AutoButtonColor = false
    resize.Font = Enum.Font.Code
    resize.Text = "a?Y"
    resize.TextSize = 14
    resize.TextColor3 = Color3.fromRGB(88, 93, 103)
    resize.Parent = window

    self._ui = {
        gui = gui,
        opener = opener,
        badge = badge,
        window = window,
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
    }

    opener.MouseEnter:Connect(function()
        opener.TextColor3 = Color3.fromRGB(209, 212, 218)
    end)
    opener.MouseLeave:Connect(function()
        opener.TextColor3 = Color3.fromRGB(184, 188, 197)
    end)
    close.MouseEnter:Connect(function()
        close.TextColor3 = Color3.fromRGB(213, 216, 222)
    end)
    close.MouseLeave:Connect(function()
        close.TextColor3 = Color3.fromRGB(139, 144, 154)
    end)

    opener.Activated:Connect(function()
        self:Toggle()
    end)
    close.Activated:Connect(function()
        self:Close()
    end)
    clear.Activated:Connect(function()
        self:Clear(false)
    end)
    copySelected.Activated:Connect(function()
        local ok, err = self:CopyEntry()
        if not ok then
            self:Warn(err, {
                subsystem = "DiagnosticsUI",
                native = false,
            })
        end
    end)
    copyAll.Activated:Connect(function()
        local ok, err = self:CopyAll()
        if not ok then
            self:Warn(err, {
                subsystem = "DiagnosticsUI",
                native = false,
            })
        end
    end)
    pause.Activated:Connect(function()
        self.Paused = not self.Paused
        pause.Text = self.Paused and "Resume" or "Pause"
        pause.TextColor3 = self.Paused
            and LEVEL_COLORS.WARN
            or Color3.fromRGB(164, 168, 177)

        if not self.Paused then
            self:_scheduleRender()
        end
    end)
    autoScroll.Activated:Connect(function()
        self._ui.autoScrollEnabled = not self._ui.autoScrollEnabled
        autoScroll.Text = self._ui.autoScrollEnabled
            and "Auto-scroll: on"
            or "Auto-scroll: off"
        autoScroll.TextColor3 = self._ui.autoScrollEnabled
            and Color3.fromRGB(128, 133, 144)
            or Color3.fromRGB(91, 96, 106)
    end)

    search:GetPropertyChangedSignal("Text"):Connect(function()
        self:_scheduleRender()
    end)
    sourceFilter:GetPropertyChangedSignal("Text"):Connect(function()
        self:_scheduleRender()
    end)
    moduleFilter:GetPropertyChangedSignal("Text"):Connect(function()
        self:_scheduleRender()
    end)

    local userInput = game:GetService("UserInputService")

    local dragging = false
    local dragStart
    local startPosition

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end)

    local resizing = false
    local resizeStart
    local startSize

    resize.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            resizing = true
            resizeStart = input.Position
            startSize = window.AbsoluteSize
        end
    end)

    local changedConnection = userInput.InputChanged:Connect(function(input)
        if dragging
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch)
        then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end

        if resizing
            and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch)
        then
            local delta = input.Position - resizeStart
            local currentViewport = workspace.CurrentCamera
                and workspace.CurrentCamera.ViewportSize
                or Vector2.new(1280, 720)
            local width = math.clamp(
                startSize.X + delta.X,
                math.min(minSize.X, currentViewport.X - 16),
                math.min(maxSize.X, currentViewport.X - 16)
            )
            local height = math.clamp(
                startSize.Y + delta.Y,
                math.min(minSize.Y, currentViewport.Y - 16),
                math.min(maxSize.Y, currentViewport.Y - 16)
            )
            window.Size = UDim2.fromOffset(width, height)
        end
    end)

    local endedConnection = userInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            dragging = false
            resizing = false
        end
    end)

    local keyConnection = userInput.InputBegan:Connect(function(input, processed)
        if processed then
            return
        end

        if input.KeyCode == Enum.KeyCode.F8 then
            self:Toggle()
        end
    end)

    table.insert(self.Connections, changedConnection)
    table.insert(self.Connections, endedConnection)
    table.insert(self.Connections, keyConnection)

    self:_scheduleRender()
    return self._ui
end
-- BADWARS_CONSOLE_UI_V1_END
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

    ui.counters.Text = string.format(
        "%d errors  -  %d warnings",
        errorCount,
        warningCount
    )

    if ui.footer then
        ui.footer.Text = string.format(
            "F8  -  %d entries  -  %s",
            #self.Entries,
            self.Paused and "paused" or "live"
        )
    end

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
        local rowHeight = expanded and 132 or 36
        local severityColor = LEVEL_COLORS[entry.severity]
            or Color3.fromRGB(120, 125, 135)

        local row = Instance.new("TextButton")
        row.Name = "Entry_" .. tostring(entry.id)
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, rowHeight)
        row.BackgroundColor3 = selected
            and Color3.fromRGB(20, 22, 27)
            or Color3.fromRGB(12, 14, 17)
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = ui.list

        local separator = Instance.new("Frame")
        separator.AnchorPoint = Vector2.new(0, 1)
        separator.Position = UDim2.new(0, 0, 1, 0)
        separator.Size = UDim2.new(1, 0, 0, 1)
        separator.BackgroundColor3 = Color3.fromRGB(36, 39, 46)
        separator.BackgroundTransparency = 0.36
        separator.BorderSizePixel = 0
        separator.Parent = row

        local dot = Instance.new("Frame")
        dot.Position = UDim2.fromOffset(10, 15)
        dot.Size = UDim2.fromOffset(6, 6)
        dot.BackgroundColor3 = severityColor
        dot.BorderSizePixel = 0
        dot.Parent = row
        createCorner(dot, 99)

        local timestamp = Instance.new("TextLabel")
        timestamp.Position = UDim2.fromOffset(25, 0)
        timestamp.Size = UDim2.fromOffset(58, 36)
        timestamp.BackgroundTransparency = 1
        timestamp.Font = Enum.Font.Code
        timestamp.Text = entry.timestamp or "--:--:--"
        timestamp.TextSize = 9
        timestamp.TextColor3 = Color3.fromRGB(90, 95, 105)
        timestamp.TextXAlignment = Enum.TextXAlignment.Left
        timestamp.Parent = row

        local sourceText = entry.subsystem ~= "" and entry.subsystem or "runtime"
        if entry.module and entry.module ~= "" then
            sourceText = sourceText .. "/" .. entry.module
        end

        local source = Instance.new("TextLabel")
        source.Position = UDim2.fromOffset(87, 0)
        source.Size = UDim2.fromOffset(132, 36)
        source.BackgroundTransparency = 1
        source.Font = Enum.Font.Code
        source.Text = sourceText
        source.TextSize = 9
        source.TextColor3 = Color3.fromRGB(114, 119, 129)
        source.TextXAlignment = Enum.TextXAlignment.Left
        source.TextTruncate = Enum.TextTruncate.AtEnd
        source.Parent = row

        local repeatSuffix = (entry.repeatCount or 1) > 1
            and ("  x" .. tostring(entry.repeatCount))
            or ""

        local message = Instance.new("TextLabel")
        message.Position = UDim2.fromOffset(225, 0)
        message.Size = UDim2.new(1, -239, 0, 36)
        message.BackgroundTransparency = 1
        message.Font = Enum.Font.Gotham
        message.Text = tostring(entry.message or "") .. repeatSuffix
        message.TextSize = 10
        message.TextColor3 = Color3.fromRGB(193, 197, 205)
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextTruncate = Enum.TextTruncate.AtEnd
        message.Parent = row

        if expanded then
            message.TextColor3 = Color3.fromRGB(219, 222, 228)

            local details = Instance.new("TextLabel")
            details.Position = UDim2.fromOffset(25, 42)
            details.Size = UDim2.new(1, -39, 0, 80)
            details.BackgroundColor3 = Color3.fromRGB(9, 11, 14)
            details.BorderSizePixel = 0
            details.Font = Enum.Font.Code
            details.Text = self:FormatEntry(entry, true)
            details.TextSize = 9
            details.TextColor3 = Color3.fromRGB(126, 131, 142)
            details.TextXAlignment = Enum.TextXAlignment.Left
            details.TextYAlignment = Enum.TextYAlignment.Top
            details.TextWrapped = true
            details.Parent = row
            createCorner(details, 4)
            createStroke(details, Color3.fromRGB(39, 42, 49), 0.46, 1)

            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 7)
            padding.PaddingBottom = UDim.new(0, 7)
            padding.PaddingLeft = UDim.new(0, 8)
            padding.PaddingRight = UDim.new(0, 8)
            padding.Parent = details
        end

        row.Activated:Connect(function()
            self._selectedId = entry.id
            ui.expanded[entry.id] = not ui.expanded[entry.id]
            self:_scheduleRender()
        end)
    end

    if ui.window.Visible
        and ui.autoScrollEnabled
        and #visible > 0
    then
        task.defer(function()
            if ui.list and ui.list.Parent then
                ui.list.CanvasPosition = Vector2.new(
                    0,
                    math.max(0, ui.list.AbsoluteCanvasSize.Y)
                )
            end
        end)
    end
end
-- BADWARS_CONSOLE_RENDER_V1_END
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
    ui.window.Visible = true
    self.Unread = 0
    self:_scheduleRender()
end

function Diagnostics:Close()
    local ui = self:EnsureUI()
    if ui then
        ui.window.Visible = false
    end
end

function Diagnostics:Toggle()
    local ui = self:EnsureUI()
    if not ui then
        return
    end
    if ui.window.Visible then
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
