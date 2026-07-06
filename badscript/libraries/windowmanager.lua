-- BADWARS_WINDOW_MANAGER_V19_1
-- Reusable low-overhead drag/resize/persistence manager for BadWars UI windows.

local WindowManager = {}
WindowManager.__index = WindowManager

local function clampNumber(value, minimum, maximum)
    if maximum < minimum then
        maximum = minimum
    end
    return math.clamp(tonumber(value) or minimum, minimum, maximum)
end

local function copyVector(value, fallback)
    return typeof(value) == "Vector2" and value or fallback
end

local function safeDisconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function safeCancel(thread)
    if thread then
        pcall(task.cancel, thread)
    end
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 5)
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = color or Color3.fromRGB(75, 95, 110)
    stroke.Transparency = transparency == nil and 0.45 or transparency
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function getFileTable(path, httpService)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    local ok, exists = pcall(isfile, path)
    if not ok or not exists then
        return nil
    end
    local readOk, body = pcall(readfile, path)
    if not readOk or type(body) ~= "string" or body == "" then
        return nil
    end
    local decodeOk, decoded = pcall(function()
        return httpService:JSONDecode(body)
    end)
    return decodeOk and type(decoded) == "table" and decoded or nil
end

function WindowManager.new(config)
    config = type(config) == "table" and config or {}
    local self = setmetatable({}, WindowManager)
    self.UserInputService = config.UserInputService or game:GetService("UserInputService")
    self.HttpService = config.HttpService or game:GetService("HttpService")
    self.GetScale = type(config.GetScale) == "function" and config.GetScale or function()
        return 1
    end
    self.GetViewport = type(config.GetViewport) == "function" and config.GetViewport or function()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(1280, 720)
    end
    self.PersistencePath = config.PersistencePath or "badscript/profiles/ui-layout.json"
    self.TouchEnabled = config.TouchEnabled == true
    self.Accent = typeof(config.Accent) == "Color3" and config.Accent or Color3.fromRGB(65, 204, 162)
    self.Surface = typeof(config.Surface) == "Color3" and config.Surface or Color3.fromRGB(17, 25, 32)
    self.Border = typeof(config.Border) == "Color3" and config.Border or Color3.fromRGB(61, 82, 96)
    self.Windows = setmetatable({}, { __mode = "v" })
    self.Entries = {}
    self.Layout = getFileTable(self.PersistencePath, self.HttpService) or { Version = 1, Windows = {} }
    self.Layout.Version = 1
    self.Layout.Windows = type(self.Layout.Windows) == "table" and self.Layout.Windows or {}
    self.SaveThread = nil
    self.ViewportConnection = nil
    self.Destroyed = false
    return self
end

function WindowManager:_scale()
    return math.max(tonumber(self.GetScale()) or 1, 0.01)
end

function WindowManager:_viewportLogical()
    local viewport = self.GetViewport()
    if typeof(viewport) ~= "Vector2" then
        viewport = Vector2.new(1280, 720)
    end
    return viewport / self:_scale()
end

function WindowManager:_logicalTopLeft(object)
    return object.AbsolutePosition / self:_scale()
end

function WindowManager:_logicalSize(object)
    return object.AbsoluteSize / self:_scale()
end

function WindowManager:_setTopLeft(object, topLeft, logicalSize)
    local scale = self:_scale()
    local parent = object.Parent
    local parentAbsolute = parent and parent:IsA("GuiObject") and parent.AbsolutePosition or Vector2.zero
    local parentLogical = parentAbsolute / scale
    local anchor = object.AnchorPoint
    object.Position = UDim2.fromOffset(
        topLeft.X - parentLogical.X + logicalSize.X * anchor.X,
        topLeft.Y - parentLogical.Y + logicalSize.Y * anchor.Y
    )
end

function WindowManager:_limits(entry, topLeft)
    local viewport = self:_viewportLogical()
    local margin = entry.Options.Margin or (self.TouchEnabled and 5 or 8)
    local minimum = copyVector(entry.Options.MinSize, Vector2.new(220, 150))
    local collapsed = type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true
    if collapsed then
        minimum = Vector2.new(minimum.X, tonumber(entry.Options.CollapsedHeight) or 52)
    end
    local configuredMaximum = copyVector(entry.Options.MaxSize, Vector2.new(1600, 1200))
    local available = Vector2.new(
        math.max(minimum.X, viewport.X - topLeft.X - margin),
        math.max(minimum.Y, viewport.Y - topLeft.Y - margin)
    )
    local maximum = Vector2.new(
        math.min(configuredMaximum.X, available.X),
        math.min(configuredMaximum.Y, available.Y)
    )
    return minimum, maximum, viewport, margin
end

function WindowManager:_clampState(entry, topLeft, logicalSize)
    local minimum, maximum, viewport, margin = self:_limits(entry, topLeft)
    local size = Vector2.new(
        clampNumber(logicalSize.X, minimum.X, maximum.X),
        clampNumber(logicalSize.Y, minimum.Y, maximum.Y)
    )
    local maxX = math.max(margin, viewport.X - size.X - margin)
    local maxY = math.max(margin, viewport.Y - size.Y - margin)
    local position = Vector2.new(
        clampNumber(topLeft.X, margin, maxX),
        clampNumber(topLeft.Y, margin, maxY)
    )
    return position, size
end

function WindowManager:_queueReflow(entry, final)
    if not entry or entry.Destroyed then
        return
    end
    entry.ReflowFinal = entry.ReflowFinal or final == true
    if entry.ReflowQueued then
        return
    end
    entry.ReflowQueued = true
    task.defer(function()
        if entry.Destroyed then
            return
        end
        entry.ReflowQueued = false
        local isFinal = entry.ReflowFinal == true
        entry.ReflowFinal = false
        if type(entry.Options.OnResize) == "function" then
            pcall(entry.Options.OnResize, entry.Object, isFinal, entry)
        end
        if isFinal and type(entry.Options.OnResizeEnd) == "function" then
            pcall(entry.Options.OnResizeEnd, entry.Object, entry)
        end
    end)
end

function WindowManager:_snapEntry(entry)
    if not entry or entry.Options.Snap == false or not entry.Object or not entry.Object.Parent then
        return
    end
    local viewport = self:_viewportLogical()
    local margin = entry.Options.Margin or (self.TouchEnabled and 5 or 8)
    local distance = tonumber(entry.Options.SnapDistance) or 14
    local topLeft = self:_logicalTopLeft(entry.Object)
    local size = self:_logicalSize(entry.Object)
    local x = topLeft.X
    local y = topLeft.Y
    if math.abs(x - margin) <= distance then
        x = margin
    elseif math.abs((x + size.X) - (viewport.X - margin)) <= distance then
        x = viewport.X - margin - size.X
    end
    if math.abs(y - margin) <= distance then
        y = margin
    elseif math.abs((y + size.Y) - (viewport.Y - margin)) <= distance then
        y = viewport.Y - margin - size.Y
    end
    local grid = tonumber(entry.Options.SnapGrid)
    if grid and grid > 1 then
        x = math.round(x / grid) * grid
        y = math.round(y / grid) * grid
    end
    local clamped, clampedSize = self:_clampState(entry, Vector2.new(x, y), size)
    self:_setTopLeft(entry.Object, clamped, clampedSize)
end

function WindowManager:_saveEntry(entry)
    if not entry or entry.Destroyed or not entry.Object or not entry.Object.Parent then
        return
    end
    local topLeft, size = self:_clampState(entry, self:_logicalTopLeft(entry.Object), self:_logicalSize(entry.Object))
    local preferredWidth = tonumber(entry.Object:GetAttribute("BadWarsUserWidth")) or size.X
    local preferredHeight = tonumber(entry.Object:GetAttribute("BadWarsUserHeight")) or size.Y
    self.Layout.Windows[entry.Id] = {
        X = math.floor(topLeft.X * 100 + 0.5) / 100,
        Y = math.floor(topLeft.Y * 100 + 0.5) / 100,
        Width = math.floor(preferredWidth * 100 + 0.5) / 100,
        Height = math.floor(preferredHeight * 100 + 0.5) / 100,
        LockPosition = entry.LockPosition == true,
        LockSize = entry.LockSize == true,
    }
    self:QueueSave()
end

function WindowManager:QueueSave()
    safeCancel(self.SaveThread)
    self.SaveThread = task.delay(0.2, function()
        self.SaveThread = nil
        if self.Destroyed or type(writefile) ~= "function" then
            return
        end
        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("badscript/profiles") then
                makefolder("badscript/profiles")
            end
            writefile(self.PersistencePath, self.HttpService:JSONEncode(self.Layout))
        end)
    end)
end

function WindowManager:_restoreEntry(entry)
    local object = entry.Object
    if not object or not object.Parent then
        return
    end
    local saved = self.Layout.Windows[entry.Id]
    local defaultSize = copyVector(entry.Options.DefaultSize, self:_logicalSize(object))
    local defaultTopLeft = self:_logicalTopLeft(object)
    local topLeft = defaultTopLeft
    local size = defaultSize
    if type(saved) == "table" then
        topLeft = Vector2.new(tonumber(saved.X) or defaultTopLeft.X, tonumber(saved.Y) or defaultTopLeft.Y)
        size = Vector2.new(tonumber(saved.Width) or defaultSize.X, tonumber(saved.Height) or defaultSize.Y)
        entry.LockPosition = saved.LockPosition == true
        entry.LockSize = saved.LockSize == true
        object:SetAttribute("BadWarsUserResized", true)
    else
        object:SetAttribute("BadWarsUserResized", false)
    end
    topLeft, size = self:_clampState(entry, topLeft, size)
    object.Size = UDim2.fromOffset(size.X, size.Y)
    object:SetAttribute("BadWarsUserWidth", size.X)
    object:SetAttribute("BadWarsUserHeight", size.Y)
    self:_setTopLeft(object, topLeft, size)
    self:_queueReflow(entry, true)
end

function WindowManager:_createGrip(entry)
    local object = entry.Object
    local size = self.TouchEnabled and 32 or 24
    local button = Instance.new("TextButton")
    button.Name = "SmartResizeGrip"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.fromScale(1, 1)
    button.Size = UDim2.fromOffset(size, size)
    button.BackgroundColor3 = self.Surface
    button.BackgroundTransparency = 0.35
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = object.ZIndex + 500
    button.Parent = object
    makeCorner(button, self.TouchEnabled and 9 or 7)
    local stroke = makeStroke(button, self.Border, 0.6, 1)

    for index = 0, 2 do
        local line = Instance.new("Frame")
        line.Name = "GripLine" .. tostring(index + 1)
        line.AnchorPoint = Vector2.new(1, 1)
        line.Position = UDim2.new(1, -(5 + index * 4), 1, -5)
        line.Size = UDim2.fromOffset(7 + index * 3, 1)
        line.Rotation = -45
        line.BackgroundColor3 = self.Border
        line.BackgroundTransparency = 0.1 + index * 0.16
        line.BorderSizePixel = 0
        line.ZIndex = button.ZIndex + 1
        line.Parent = button
        makeCorner(line, 99)
    end

    if not self.TouchEnabled then
        button.MouseEnter:Connect(function()
            button.BackgroundTransparency = 0.08
            stroke.Color = self.Accent
            stroke.Transparency = 0.18
        end)
        button.MouseLeave:Connect(function()
            if not entry.Resizing then
                button.BackgroundTransparency = 0.35
                stroke.Color = self.Border
                stroke.Transparency = 0.6
            end
        end)
    end
    entry.Grip = button
    entry.GripStroke = stroke
    return button
end

function WindowManager:_createEdge(entry, name, direction)
    local object = entry.Object
    local thickness = self.TouchEnabled and 18 or 10
    local button = Instance.new("TextButton")
    button.Name = name
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = object.ZIndex + 499
    if direction == "right" then
        button.AnchorPoint = Vector2.new(1, 0)
        button.Position = UDim2.fromScale(1, 0)
        button.Size = UDim2.new(0, thickness, 1, -(self.TouchEnabled and 30 or 22))
    else
        button.AnchorPoint = Vector2.new(0, 1)
        button.Position = UDim2.fromScale(0, 1)
        button.Size = UDim2.new(1, -(self.TouchEnabled and 30 or 22), 0, thickness)
    end
    button.Parent = object
    return button
end

function WindowManager:_beginResize(entry, input, direction)
    if entry.LockSize or entry.Destroyed then
        return
    end
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
        return
    end
    self:_stopInteraction(entry, false)
    entry.Resizing = true
    entry.ActiveInput = input
    entry.Direction = direction
    entry.StartPointer = input.Position
    entry.StartSize = self:_logicalSize(entry.Object)
    entry.StartTopLeft = self:_logicalTopLeft(entry.Object)
    entry.ExpectedMovement = inputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch
    if entry.Grip then
        entry.Grip.BackgroundTransparency = 0.02
        entry.GripStroke.Color = self.Accent
        entry.GripStroke.Transparency = 0.05
    end
    if type(entry.Options.OnResizeStart) == "function" then
        pcall(entry.Options.OnResizeStart, entry.Object, entry)
    end

    entry.MoveConnection = self.UserInputService.InputChanged:Connect(function(changed)
        if not entry.Resizing or not entry.Object.Parent or changed.UserInputType ~= entry.ExpectedMovement then
            return
        end
        if inputType == Enum.UserInputType.Touch and changed ~= entry.ActiveInput then
            return
        end
        local delta = (changed.Position - entry.StartPointer) / self:_scale()
        local requested = entry.StartSize
        if direction == "right" or direction == "corner" then
            requested = Vector2.new(entry.StartSize.X + delta.X, requested.Y)
        end
        if direction == "bottom" or direction == "corner" then
            requested = Vector2.new(requested.X, entry.StartSize.Y + delta.Y)
        end
        local _, size = self:_clampState(entry, entry.StartTopLeft, requested)
        entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
        entry.Object:SetAttribute("BadWarsUserResized", true)
        entry.Object:SetAttribute("BadWarsUserWidth", size.X)
        entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
        self:_queueReflow(entry, false)
    end)

    entry.EndConnection = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
            self:_stopInteraction(entry, true)
        end
    end)
end

function WindowManager:_stopInteraction(entry, save)
    if not entry then
        return
    end
    safeDisconnect(entry.MoveConnection)
    safeDisconnect(entry.EndConnection)
    entry.MoveConnection = nil
    entry.EndConnection = nil
    entry.ActiveInput = nil
    local wasResizing = entry.Resizing
    entry.Resizing = false
    if entry.Grip and entry.Grip.Parent then
        entry.Grip.BackgroundTransparency = 0.35
        entry.GripStroke.Color = self.Border
        entry.GripStroke.Transparency = 0.6
    end
    if wasResizing then
        self:Clamp(entry.Id, false)
        self:_snapEntry(entry)
        self:_queueReflow(entry, true)
        if save then
            self:_saveEntry(entry)
        end
    end
end

function WindowManager:Register(id, object, options)
    assert(type(id) == "string" and id ~= "", "Window id required")
    assert(typeof(object) == "Instance" and object:IsA("GuiObject"), "GuiObject required")
    options = type(options) == "table" and options or {}
    if self.Entries[id] then
        self:Unregister(id)
    end
    local entry = {
        Id = id,
        Object = object,
        Options = options,
        LockSize = options.LockSize == true,
        LockPosition = options.LockPosition == true,
        Connections = {},
        Destroyed = false,
    }
    self.Entries[id] = entry
    self.Windows[id] = object
    object:SetAttribute("BadWarsWindowId", id)

    local grip = self:_createGrip(entry)
    local right = options.RightEdge == false and nil or self:_createEdge(entry, "SmartResizeRight", "right")
    local bottom = options.BottomEdge == false and nil or self:_createEdge(entry, "SmartResizeBottom", "bottom")
    entry.Right = right
    entry.Bottom = bottom

    entry.Connections[#entry.Connections + 1] = grip.InputBegan:Connect(function(input)
        self:_beginResize(entry, input, "corner")
    end)
    if right then
        entry.Connections[#entry.Connections + 1] = right.InputBegan:Connect(function(input)
            self:_beginResize(entry, input, "right")
        end)
    end
    if bottom then
        entry.Connections[#entry.Connections + 1] = bottom.InputBegan:Connect(function(input)
            self:_beginResize(entry, input, "bottom")
        end)
    end
    entry.Connections[#entry.Connections + 1] = object.Destroying:Once(function()
        self:Unregister(id)
    end)
    entry.Connections[#entry.Connections + 1] = object:GetPropertyChangedSignal("Visible"):Connect(function()
        if object.Visible then
            task.defer(function()
                if not entry.Destroyed and object.Parent then
                    self:Clamp(id, false)
                end
            end)
        end
    end)

    task.defer(function()
        if not entry.Destroyed and object.Parent then
            self:_restoreEntry(entry)
        end
    end)
    return entry
end

function WindowManager:Clamp(id, save)
    local entry = self.Entries[id]
    if not entry or entry.Destroyed or not entry.Object.Parent then
        return
    end
    local topLeft, size = self:_clampState(entry, self:_logicalTopLeft(entry.Object), self:_logicalSize(entry.Object))
    entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
    self:_setTopLeft(entry.Object, topLeft, size)
    entry.Object:SetAttribute("BadWarsUserWidth", size.X)
    local collapsed = type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true
    if not collapsed then
        entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
    end
    if save then
        self:_saveEntry(entry)
    end
end

function WindowManager:NotifyMoved(id)
    local entry = self.Entries[id]
    if not entry or entry.Destroyed or entry.LockPosition then
        return
    end
    self:Clamp(id, false)
    self:_snapEntry(entry)
    self:_saveEntry(entry)
end

function WindowManager:SetLocked(id, kind, locked)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    if kind == "size" then
        entry.LockSize = locked == true
        if entry.Grip then
            entry.Grip.Visible = not entry.LockSize
        end
        if entry.Right then
            entry.Right.Visible = not entry.LockSize
        end
        if entry.Bottom then
            entry.Bottom.Visible = not entry.LockSize
        end
    elseif kind == "position" then
        entry.LockPosition = locked == true
    else
        return false
    end
    self:_saveEntry(entry)
    return true
end

function WindowManager:Reset(id)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    self.Layout.Windows[id] = nil
    local defaultSize = copyVector(entry.Options.DefaultSize, self:_logicalSize(entry.Object))
    local defaultPosition = copyVector(entry.Options.DefaultPosition, self:_logicalTopLeft(entry.Object))
    local topLeft, size = self:_clampState(entry, defaultPosition, defaultSize)
    entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
    self:_setTopLeft(entry.Object, topLeft, size)
    entry.Object:SetAttribute("BadWarsUserResized", false)
    self:_queueReflow(entry, true)
    self:QueueSave()
    return true
end

function WindowManager:ResetAll()
    for id in pairs(self.Entries) do
        self:Reset(id)
    end
end

function WindowManager:BindViewportSignal(signal)
    safeDisconnect(self.ViewportConnection)
    if signal then
        self.ViewportConnection = signal:Connect(function()
            if self.ViewportThread then
                safeCancel(self.ViewportThread)
            end
            self.ViewportThread = task.delay(0.08, function()
                self.ViewportThread = nil
                for id in pairs(self.Entries) do
                    self:Clamp(id, false)
                    local entry = self.Entries[id]
                    if entry then
                        self:_queueReflow(entry, true)
                    end
                end
            end)
        end)
    end
end

function WindowManager:Unregister(id)
    local entry = self.Entries[id]
    if not entry then
        return
    end
    entry.Destroyed = true
    self:_stopInteraction(entry, false)
    for _, connection in ipairs(entry.Connections) do
        safeDisconnect(connection)
    end
    table.clear(entry.Connections)
    self.Entries[id] = nil
    self.Windows[id] = nil
end

function WindowManager:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    safeCancel(self.SaveThread)
    safeCancel(self.ViewportThread)
    safeDisconnect(self.ViewportConnection)
    for id in pairs(self.Entries) do
        self:Unregister(id)
    end
end

return WindowManager
