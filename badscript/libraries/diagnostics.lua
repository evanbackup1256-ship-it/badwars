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
        local old = parent:FindFirstChild("BadWarsDiagnostics")
        if old then
            old:Destroy()
        end
    end)

    local gui = Instance.new("ScreenGui")
    gui.Name = "BadWarsDiagnostics"
    gui.DisplayOrder = 9999999
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local opener = Instance.new("TextButton")
    opener.Name = "DiagnosticsButton"
    opener.AnchorPoint = Vector2.new(1, 0)
    opener.Position = UDim2.new(1, -16, 0, 16)
    opener.Size = UDim2.fromOffset(116, 34)
    opener.BackgroundColor3 = Color3.fromRGB(13, 19, 24)
    opener.BorderSizePixel = 0
    opener.AutoButtonColor = false
    opener.Font = Enum.Font.GothamBold
    opener.Text = "CONSOLE"
    opener.TextSize = 11
    opener.TextColor3 = Color3.fromRGB(84, 204, 163)
    opener.Parent = gui
    createCorner(opener, 9)
    createStroke(opener, Color3.fromRGB(59, 171, 136), 0.45, 1)

    local badge = Instance.new("TextLabel")
    badge.Name = "Unread"
    badge.AnchorPoint = Vector2.new(1, 0.5)
    badge.Position = UDim2.new(1, 8, 0.5, 0)
    badge.Size = UDim2.fromOffset(22, 22)
    badge.BackgroundColor3 = Color3.fromRGB(239, 91, 104)
    badge.BorderSizePixel = 0
    badge.Font = Enum.Font.GothamBold
    badge.TextSize = 10
    badge.TextColor3 = Color3.fromRGB(255, 240, 242)
    badge.Visible = false
    badge.Parent = opener
    createCorner(badge, 99)

    local window = Instance.new("Frame")
    window.Name = "Window"
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.Size = UDim2.fromOffset(820, 540)
    window.BackgroundColor3 = Color3.fromRGB(8, 12, 16)
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Visible = false
    window.Parent = gui
    createCorner(window, 12)
    createStroke(window, Color3.fromRGB(68, 82, 97), 0.35, 1)

    local minSize = Vector2.new(520, 340)
    local maxSize = Vector2.new(1200, 820)

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 54)
    header.BackgroundColor3 = Color3.fromRGB(13, 18, 23)
    header.BorderSizePixel = 0
    header.Parent = window

    local accent = Instance.new("Frame")
    accent.Size = UDim2.fromOffset(3, 24)
    accent.Position = UDim2.fromOffset(16, 15)
    accent.BackgroundColor3 = Color3.fromRGB(62, 205, 160)
    accent.BorderSizePixel = 0
    accent.Parent = header
    createCorner(accent, 99)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 260, 1, 0)
    title.Position = UDim2.fromOffset(30, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "BADWARS  /  DIAGNOSTICS"
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(235, 241, 246)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local counters = Instance.new("TextLabel")
    counters.Name = "Counters"
    counters.AnchorPoint = Vector2.new(1, 0.5)
    counters.Position = UDim2.new(1, -94, 0.5, 0)
    counters.Size = UDim2.fromOffset(250, 28)
    counters.BackgroundTransparency = 1
    counters.Font = Enum.Font.Code
    counters.Text = "0 errors  •  0 warnings"
    counters.TextSize = 11
    counters.TextColor3 = Color3.fromRGB(126, 141, 156)
    counters.TextXAlignment = Enum.TextXAlignment.Right
    counters.Parent = header

    local close = makeButton(header, "Close", "×", UDim2.fromOffset(34, 30))
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -14, 0.5, 0)
    close.TextSize = 18

    local toolbar = Instance.new("Frame")
    toolbar.Name = "Toolbar"
    toolbar.Position = UDim2.fromOffset(14, 64)
    toolbar.Size = UDim2.new(1, -28, 0, 72)
    toolbar.BackgroundTransparency = 1
    toolbar.Parent = window

    local search = Instance.new("TextBox")
    search.Name = "Search"
    search.Size = UDim2.new(0.36, -6, 0, 32)
    search.BackgroundColor3 = Color3.fromRGB(16, 22, 28)
    search.BorderSizePixel = 0
    search.ClearTextOnFocus = false
    search.PlaceholderText = "Search messages and tracebacks"
    search.PlaceholderColor3 = Color3.fromRGB(91, 105, 119)
    search.Font = Enum.Font.Gotham
    search.Text = ""
    search.TextSize = 11
    search.TextColor3 = Color3.fromRGB(207, 217, 227)
    search.TextXAlignment = Enum.TextXAlignment.Left
    search.Parent = toolbar
    createCorner(search, 8)
    createStroke(search, Color3.fromRGB(60, 73, 87), 0.72, 1)
    local searchPad = Instance.new("UIPadding")
    searchPad.PaddingLeft = UDim.new(0, 10)
    searchPad.PaddingRight = UDim.new(0, 10)
    searchPad.Parent = search

    local sourceFilter = search:Clone()
    sourceFilter.Name = "SourceFilter"
    sourceFilter.Position = UDim2.new(0.36, 4, 0, 0)
    sourceFilter.Size = UDim2.new(0.22, -4, 0, 32)
    sourceFilter.PlaceholderText = "Source filter"
    sourceFilter.Text = ""
    sourceFilter.Parent = toolbar

    local moduleFilter = search:Clone()
    moduleFilter.Name = "ModuleFilter"
    moduleFilter.Position = UDim2.new(0.58, 8, 0, 0)
    moduleFilter.Size = UDim2.new(0.22, -4, 0, 32)
    moduleFilter.PlaceholderText = "Module filter"
    moduleFilter.Text = ""
    moduleFilter.Parent = toolbar

    local pause = makeButton(toolbar, "Pause", "PAUSE", UDim2.new(0.2, -8, 0, 32))
    pause.Position = UDim2.new(0.8, 8, 0, 0)

    local filters = Instance.new("Frame")
    filters.Name = "Filters"
    filters.Position = UDim2.fromOffset(0, 40)
    filters.Size = UDim2.new(1, 0, 0, 30)
    filters.BackgroundTransparency = 1
    filters.Parent = toolbar

    local filterLayout = Instance.new("UIListLayout")
    filterLayout.FillDirection = Enum.FillDirection.Horizontal
    filterLayout.Padding = UDim.new(0, 6)
    filterLayout.Parent = filters

    local enabledLevels = {}
    local filterButtons = {}
    for _, level in ipairs({ "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR", "FATAL" }) do
        enabledLevels[level] = true
        local button = makeButton(filters, level, level, UDim2.fromOffset(level == "SUCCESS" and 74 or 60, 28))
        button.TextColor3 = LEVEL_COLORS[level]
        filterButtons[level] = button
        button.MouseButton1Click:Connect(function()
            enabledLevels[level] = not enabledLevels[level]
            button.BackgroundTransparency = enabledLevels[level] and 0 or 0.55
            button.TextTransparency = enabledLevels[level] and 0 or 0.45
            self:_scheduleRender()
        end)
    end

    local actions = Instance.new("Frame")
    actions.Name = "Actions"
    actions.AnchorPoint = Vector2.new(1, 0)
    actions.Position = UDim2.new(1, 0, 0, 0)
    actions.Size = UDim2.fromOffset(278, 30)
    actions.BackgroundTransparency = 1
    actions.Parent = filters

    local actionLayout = Instance.new("UIListLayout")
    actionLayout.FillDirection = Enum.FillDirection.Horizontal
    actionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    actionLayout.Padding = UDim.new(0, 6)
    actionLayout.Parent = actions

    local clear = makeButton(actions, "Clear", "CLEAR", UDim2.fromOffset(60, 28))
    local copySelected = makeButton(actions, "CopySelected", "COPY ENTRY", UDim2.fromOffset(92, 28))
    local copyAll = makeButton(actions, "CopyAll", "COPY ALL", UDim2.fromOffset(76, 28))

    local list = Instance.new("ScrollingFrame")
    list.Name = "Entries"
    list.Position = UDim2.fromOffset(14, 146)
    list.Size = UDim2.new(1, -28, 1, -184)
    list.BackgroundColor3 = Color3.fromRGB(10, 15, 19)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 4
    list.ScrollBarImageColor3 = Color3.fromRGB(62, 205, 160)
    list.CanvasSize = UDim2.fromOffset(0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.Parent = window
    createCorner(list, 9)
    createStroke(list, Color3.fromRGB(54, 67, 79), 0.75, 1)

    local listPadding = Instance.new("UIPadding")
    listPadding.PaddingTop = UDim.new(0, 7)
    listPadding.PaddingBottom = UDim.new(0, 7)
    listPadding.PaddingLeft = UDim.new(0, 7)
    listPadding.PaddingRight = UDim.new(0, 7)
    listPadding.Parent = list

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local footer = Instance.new("TextLabel")
    footer.Position = UDim2.new(0, 16, 1, -30)
    footer.Size = UDim2.new(1, -62, 0, 20)
    footer.BackgroundTransparency = 1
    footer.Font = Enum.Font.Code
    footer.Text = "F8 toggles diagnostics  •  entries persist until cleared"
    footer.TextSize = 10
    footer.TextColor3 = Color3.fromRGB(83, 97, 111)
    footer.TextXAlignment = Enum.TextXAlignment.Left
    footer.Parent = window

    local resize = Instance.new("TextButton")
    resize.Name = "Resize"
    resize.AnchorPoint = Vector2.new(1, 1)
    resize.Position = UDim2.fromScale(1, 1)
    resize.Size = UDim2.fromOffset(28, 28)
    resize.BackgroundTransparency = 1
    resize.BorderSizePixel = 0
    resize.AutoButtonColor = false
    resize.Font = Enum.Font.Code
    resize.Text = "◢"
    resize.TextSize = 16
    resize.TextColor3 = Color3.fromRGB(73, 190, 151)
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
        list = list,
        listLayout = listLayout,
        enabledLevels = enabledLevels,
        filterButtons = filterButtons,
        expanded = {},
        minSize = minSize,
        maxSize = maxSize,
    }

    connectHover(opener, Color3.fromRGB(84, 204, 163), Color3.fromRGB(69, 177, 142))
    connectHover(close, Color3.fromRGB(168, 181, 195), Color3.fromRGB(141, 156, 170))

    opener.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    close.MouseButton1Click:Connect(function()
        self:Close()
    end)
    clear.MouseButton1Click:Connect(function()
        self:Clear(false)
    end)
    copySelected.MouseButton1Click:Connect(function()
        local ok, err = self:CopyEntry()
        if not ok then
            self:Warn(err, { subsystem = "DiagnosticsUI", native = false })
        end
    end)
    copyAll.MouseButton1Click:Connect(function()
        local ok, err = self:CopyAll()
        if not ok then
            self:Warn(err, { subsystem = "DiagnosticsUI", native = false })
        end
    end)
    pause.MouseButton1Click:Connect(function()
        self.Paused = not self.Paused
        pause.Text = self.Paused and "RESUME" or "PAUSE"
        pause.TextColor3 = self.Paused and LEVEL_COLORS.WARN or Color3.fromRGB(168, 181, 195)
        if not self.Paused then
            self:_scheduleRender()
        end
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
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = window.Position
        end
    end)
    userInput.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)
    userInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local resizing = false
    local resizeStart
    local startSize
    resize.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startSize = window.AbsoluteSize
        end
    end)
    userInput.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local width = math.clamp(startSize.X + delta.X, minSize.X, math.min(maxSize.X, viewport.X - 24))
            local height = math.clamp(startSize.Y + delta.Y, minSize.Y, math.min(maxSize.Y, viewport.Y - 24))
            window.Size = UDim2.fromOffset(width, height)
        end
    end)
    userInput.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
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
    table.insert(self.Connections, keyConnection)

    self:_scheduleRender()
    return self._ui
end

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

function Diagnostics:_render()
    local ui = self._ui
    if not ui or not ui.gui.Parent then
        return
    end

    ui.badge.Visible = self.Unread > 0
    ui.badge.Text = self.Unread > 99 and "99+" or tostring(self.Unread)
    ui.counters.Text = string.format(
        "%d errors  •  %d warnings  •  %d total",
        (self.Counts.ERROR or 0) + (self.Counts.FATAL or 0),
        self.Counts.WARN or 0,
        #self.Entries
    )

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
        local repeatSuffix = (entry.repeatCount or 1) > 1 and ("  ×" .. tostring(entry.repeatCount)) or ""

        local row = Instance.new("TextButton")
        row.Name = "Entry_" .. tostring(entry.id)
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, expanded and 142 or 54)
        row.AutomaticSize = expanded and Enum.AutomaticSize.Y or Enum.AutomaticSize.None
        row.BackgroundColor3 = selected and Color3.fromRGB(24, 33, 41) or Color3.fromRGB(15, 21, 27)
        row.BorderSizePixel = 0
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = ui.list
        createCorner(row, 8)
        createStroke(
            row,
            selected and LEVEL_COLORS[entry.severity] or Color3.fromRGB(55, 68, 81),
            selected and 0.38 or 0.76,
            1
        )

        local rail = Instance.new("Frame")
        rail.Size = UDim2.new(0, 3, 1, -14)
        rail.Position = UDim2.fromOffset(0, 7)
        rail.BackgroundColor3 = LEVEL_COLORS[entry.severity]
        rail.BorderSizePixel = 0
        rail.Parent = row
        createCorner(rail, 99)

        local meta = Instance.new("TextLabel")
        meta.Position = UDim2.fromOffset(13, 8)
        meta.Size = UDim2.new(1, -24, 0, 16)
        meta.BackgroundTransparency = 1
        meta.Font = Enum.Font.Code
        meta.Text = string.format(
            "%s  %s%s  %s  %s",
            entry.timestamp or "?",
            entry.severity,
            repeatSuffix,
            entry.subsystem ~= "" and entry.subsystem or "Runtime",
            entry.module ~= "" and entry.module or entry.file
        )
        meta.TextSize = 10
        meta.TextColor3 = LEVEL_COLORS[entry.severity]
        meta.TextXAlignment = Enum.TextXAlignment.Left
        meta.TextTruncate = Enum.TextTruncate.AtEnd
        meta.Parent = row

        local message = Instance.new("TextLabel")
        message.Position = UDim2.fromOffset(13, 27)
        message.Size = UDim2.new(1, -26, 0, expanded and 38 or 20)
        message.BackgroundTransparency = 1
        message.Font = Enum.Font.Gotham
        message.Text = entry.message
        message.TextSize = 11
        message.TextColor3 = Color3.fromRGB(205, 215, 225)
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextYAlignment = Enum.TextYAlignment.Top
        message.TextWrapped = expanded
        message.TextTruncate = expanded and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd
        message.Parent = row

        if expanded then
            local trace = Instance.new("TextLabel")
            trace.Position = UDim2.fromOffset(13, 70)
            trace.Size = UDim2.new(1, -26, 0, 62)
            trace.AutomaticSize = Enum.AutomaticSize.Y
            trace.BackgroundColor3 = Color3.fromRGB(9, 14, 18)
            trace.BorderSizePixel = 0
            trace.Font = Enum.Font.Code
            trace.Text = self:FormatEntry(entry, true)
            trace.TextSize = 10
            trace.TextColor3 = Color3.fromRGB(145, 158, 171)
            trace.TextXAlignment = Enum.TextXAlignment.Left
            trace.TextYAlignment = Enum.TextYAlignment.Top
            trace.TextWrapped = true
            trace.Parent = row
            createCorner(trace, 6)
            local padding = Instance.new("UIPadding")
            padding.PaddingTop = UDim.new(0, 7)
            padding.PaddingBottom = UDim.new(0, 7)
            padding.PaddingLeft = UDim.new(0, 8)
            padding.PaddingRight = UDim.new(0, 8)
            padding.Parent = trace
        end

        row.MouseButton1Click:Connect(function()
            self._selectedId = entry.id
            ui.expanded[entry.id] = not ui.expanded[entry.id]
            self:_scheduleRender()
        end)
    end

    if ui.window.Visible and #visible > 0 then
        task.defer(function()
            if ui.list and ui.list.Parent then
                ui.list.CanvasPosition = Vector2.new(0, math.max(0, ui.list.AbsoluteCanvasSize.Y))
            end
        end)
    end
end

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
