-- BADWARS_WINDOW_MANAGER_V19_2
-- Adaptive, low-overhead window manager for drag, resize, focus and persistence.

local WindowManager = {}
WindowManager.__index = WindowManager

local LAYOUT_VERSION = 2

local function disconnect(connection)
    if connection then
        pcall(function()
            connection:Disconnect()
        end)
    end
end

local function cancel(thread)
    if thread then
        pcall(task.cancel, thread)
    end
end

local function finite(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value or value == math.huge or value == -math.huge then
        return fallback
    end
    return value
end

local function vector(value, fallback)
    return typeof(value) == "Vector2" and value or fallback
end

local function rounded(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function corner(parent, radius)
    local object = Instance.new("UICorner")
    object.CornerRadius = UDim.new(0, radius or 6)
    object.Parent = parent
    return object
end

local function stroke(parent, color, transparency, thickness)
    local object = Instance.new("UIStroke")
    object.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    object.Color = color or Color3.fromRGB(64, 82, 96)
    object.Transparency = transparency == nil and 0.5 or transparency
    object.Thickness = thickness or 1
    object.Parent = parent
    return object
end

local function readJson(path, httpService)
    if type(path) ~= "string" or path == "" or type(isfile) ~= "function" or type(readfile) ~= "function" then
        return nil
    end
    local existsOk, exists = pcall(isfile, path)
    if not existsOk or not exists then
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

local function copyWindowState(source)
    if type(source) ~= "table" then
        return nil
    end
    return {
        X = finite(source.X, nil),
        Y = finite(source.Y, nil),
        Width = finite(source.Width, nil),
        Height = finite(source.Height, nil),
        LockPosition = source.LockPosition == true,
        LockSize = source.LockSize == true,
    }
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
    self.PersistencePath = config.PersistencePath or "badscript/profiles/ui-layout-v19.2.json"
    self.LegacyPersistencePaths = type(config.LegacyPersistencePaths) == "table" and config.LegacyPersistencePaths or {}
    self.TouchEnabled = config.TouchEnabled == true
    self.Accent = typeof(config.Accent) == "Color3" and config.Accent or Color3.fromRGB(72, 214, 170)
    self.Surface = typeof(config.Surface) == "Color3" and config.Surface or Color3.fromRGB(15, 23, 30)
    self.Border = typeof(config.Border) == "Color3" and config.Border or Color3.fromRGB(62, 82, 96)
    self.Windows = setmetatable({}, { __mode = "v" })
    self.Entries = {}
    self.SaveThread = nil
    self.ViewportThread = nil
    self.ViewportConnection = nil
    self.FocusCounter = 0
    self.Destroyed = false

    local loaded = readJson(self.PersistencePath, self.HttpService)
    if not loaded then
        for _, path in ipairs(self.LegacyPersistencePaths) do
            loaded = readJson(path, self.HttpService)
            if loaded then
                break
            end
        end
    end

    self.Layout = { Version = LAYOUT_VERSION, Windows = {} }
    if type(loaded) == "table" and type(loaded.Windows) == "table" then
        for id, saved in pairs(loaded.Windows) do
            local copied = copyWindowState(saved)
            if copied then
                self.Layout.Windows[tostring(id)] = copied
            end
        end
    end
    return self
end

function WindowManager:_scale()
    return math.max(finite(self.GetScale(), 1), 0.01)
end

function WindowManager:_viewport()
    local current = self.GetViewport()
    if typeof(current) ~= "Vector2" or current.X <= 0 or current.Y <= 0 then
        current = Vector2.new(1280, 720)
    end
    return current / self:_scale()
end

function WindowManager:_topLeft(object)
    return object.AbsolutePosition / self:_scale()
end

function WindowManager:_size(object)
    return object.AbsoluteSize / self:_scale()
end

function WindowManager:_parentOrigin(object)
    local parent = object.Parent
    if parent and parent:IsA("GuiObject") then
        return parent.AbsolutePosition / self:_scale()
    end
    return Vector2.zero
end

function WindowManager:_setTopLeft(object, topLeft, size)
    local anchor = object.AnchorPoint
    local origin = self:_parentOrigin(object)
    object.Position = UDim2.fromOffset(
        topLeft.X - origin.X + size.X * anchor.X,
        topLeft.Y - origin.Y + size.Y * anchor.Y
    )
end

function WindowManager:_minimum(entry)
    local minimum = vector(entry.Options.MinSize, Vector2.new(240, 170))
    if type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true then
        minimum = Vector2.new(minimum.X, finite(entry.Options.CollapsedHeight, 52))
    end
    local viewport = self:_viewport()
    local margin = finite(entry.Options.Margin, self.TouchEnabled and 5 or 8)
    local available = Vector2.new(
        math.max(96, viewport.X - margin * 2),
        math.max(72, viewport.Y - margin * 2)
    )
    return Vector2.new(
        math.min(math.max(120, minimum.X), available.X),
        math.min(math.max(44, minimum.Y), available.Y)
    )
end

function WindowManager:_maximum(entry)
    local viewport = self:_viewport()
    local margin = finite(entry.Options.Margin, self.TouchEnabled and 5 or 8)
    local minimum = self:_minimum(entry)
    local configured = vector(entry.Options.MaxSize, Vector2.new(1600, 1200))
    return Vector2.new(
        math.max(minimum.X, math.min(configured.X, viewport.X - margin * 2)),
        math.max(minimum.Y, math.min(configured.Y, viewport.Y - margin * 2))
    ), viewport, margin
end

function WindowManager:_sanitize(entry, topLeft, requestedSize)
    local minimum = self:_minimum(entry)
    local maximum, viewport, margin = self:_maximum(entry)
    local width = math.clamp(finite(requestedSize.X, minimum.X), minimum.X, maximum.X)
    local height = math.clamp(finite(requestedSize.Y, minimum.Y), minimum.Y, maximum.Y)
    local size = Vector2.new(width, height)
    local maxX = math.max(margin, viewport.X - width - margin)
    local maxY = math.max(margin, viewport.Y - height - margin)
    local x = math.clamp(finite(topLeft.X, margin), margin, maxX)
    local y = math.clamp(finite(topLeft.Y, margin), margin, maxY)
    return Vector2.new(x, y), size
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

function WindowManager:_setHandleState(entry, active)
    local hidden = entry.LockSize or (type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true)
    if entry.Grip then
        entry.Grip.Visible = not hidden
    end
    if entry.Right then
        entry.Right.Visible = not hidden
    end
    if entry.Bottom then
        entry.Bottom.Visible = not hidden
    end
    if entry.GripVisual then
        entry.GripVisual.BackgroundTransparency = active and 0.06 or (entry.Hovered and 0.34 or 0.72)
    end
    if entry.GripStroke then
        entry.GripStroke.Color = active and self.Accent or self.Border
        entry.GripStroke.Transparency = active and 0.08 or (entry.Hovered and 0.34 or 0.72)
    end
end

function WindowManager:_snap(entry)
    if entry.Options.Snap == false then
        return
    end
    local viewport = self:_viewport()
    local margin = finite(entry.Options.Margin, self.TouchEnabled and 5 or 8)
    local distance = finite(entry.Options.SnapDistance, 14)
    local grid = finite(entry.Options.SnapGrid, 0)
    local position = self:_topLeft(entry.Object)
    local size = self:_size(entry.Object)
    local x, y = position.X, position.Y

    if math.abs(x - margin) <= distance then
        x = margin
    elseif math.abs(x + size.X - (viewport.X - margin)) <= distance then
        x = viewport.X - margin - size.X
    end
    if math.abs(y - margin) <= distance then
        y = margin
    elseif math.abs(y + size.Y - (viewport.Y - margin)) <= distance then
        y = viewport.Y - margin - size.Y
    end
    if grid and grid > 1 then
        x = math.round(x / grid) * grid
        y = math.round(y / grid) * grid
    end

    local safePosition, safeSize = self:_sanitize(entry, Vector2.new(x, y), size)
    self:_setTopLeft(entry.Object, safePosition, safeSize)
end

function WindowManager:_saveEntry(entry)
    if not entry or entry.Destroyed or not entry.Object or not entry.Object.Parent then
        return
    end
    local position, size = self:_sanitize(entry, self:_topLeft(entry.Object), self:_size(entry.Object))
    local collapsed = type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true
    local storedWidth = finite(entry.Object:GetAttribute("BadWarsUserWidth"), size.X)
    local storedHeight = finite(entry.Object:GetAttribute("BadWarsUserHeight"), size.Y)
    if not collapsed then
        storedWidth = size.X
        storedHeight = size.Y
    end
    self.Layout.Windows[entry.Id] = {
        X = rounded(position.X),
        Y = rounded(position.Y),
        Width = rounded(storedWidth),
        Height = rounded(storedHeight),
        LockPosition = entry.LockPosition == true,
        LockSize = entry.LockSize == true,
    }
    self:QueueSave()
end

function WindowManager:QueueSave()
    cancel(self.SaveThread)
    self.SaveThread = task.delay(0.18, function()
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

function WindowManager:_restore(entry)
    local object = entry.Object
    if not object or not object.Parent then
        return
    end
    local defaultSize = vector(entry.Options.DefaultSize, self:_size(object))
    local defaultPosition = vector(entry.Options.DefaultPosition, self:_topLeft(object))
    local saved = self.Layout.Windows[entry.Id]
    local position = defaultPosition
    local size = defaultSize

    if type(saved) == "table" then
        position = Vector2.new(finite(saved.X, defaultPosition.X), finite(saved.Y, defaultPosition.Y))
        size = Vector2.new(finite(saved.Width, defaultSize.X), finite(saved.Height, defaultSize.Y))
        entry.LockPosition = saved.LockPosition == true
        entry.LockSize = saved.LockSize == true
        object:SetAttribute("BadWarsUserResized", true)
    else
        object:SetAttribute("BadWarsUserResized", false)
    end

    position, size = self:_sanitize(entry, position, size)
    object.Size = UDim2.fromOffset(size.X, size.Y)
    object:SetAttribute("BadWarsUserWidth", size.X)
    object:SetAttribute("BadWarsUserHeight", size.Y)
    self:_setTopLeft(object, position, size)
    self:_setHandleState(entry, false)
    self:_queueReflow(entry, true)
end

function WindowManager:_makeGrip(entry)
    local object = entry.Object
    local hitSize = self.TouchEnabled and 38 or 26
    local button = Instance.new("TextButton")
    button.Name = "AdaptiveResizeGrip"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.fromScale(1, 1)
    button.Size = UDim2.fromOffset(hitSize, hitSize)
    button.BackgroundTransparency = 1
    button.BorderSizePixel = 0
    button.AutoButtonColor = false
    button.Text = ""
    button.ZIndex = object.ZIndex + 500
    button.Parent = object

    local visual = Instance.new("Frame")
    visual.Name = "Visual"
    visual.AnchorPoint = Vector2.new(1, 1)
    visual.Position = UDim2.new(1, -3, 1, -3)
    visual.Size = UDim2.fromOffset(self.TouchEnabled and 24 or 18, self.TouchEnabled and 24 or 18)
    visual.BackgroundColor3 = self.Surface
    visual.BackgroundTransparency = 0.72
    visual.BorderSizePixel = 0
    visual.ZIndex = button.ZIndex + 1
    visual.Parent = button
    corner(visual, self.TouchEnabled and 8 or 6)
    local visualStroke = stroke(visual, self.Border, 0.72, 1)

    for index = 0, 2 do
        local dot = Instance.new("Frame")
        dot.Name = "GripDot" .. tostring(index + 1)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Position = UDim2.new(1, -(5 + index * 4), 1, -(5 + (2 - index) * 4))
        dot.Size = UDim2.fromOffset(2, 2)
        dot.BackgroundColor3 = self.Border
        dot.BackgroundTransparency = 0.16 + index * 0.12
        dot.BorderSizePixel = 0
        dot.ZIndex = visual.ZIndex + 1
        dot.Parent = visual
        corner(dot, 99)
    end

    entry.Grip = button
    entry.GripVisual = visual
    entry.GripStroke = visualStroke

    if not self.TouchEnabled then
        entry.Connections[#entry.Connections + 1] = button.MouseEnter:Connect(function()
            entry.Hovered = true
            self:_setHandleState(entry, entry.Resizing)
        end)
        entry.Connections[#entry.Connections + 1] = button.MouseLeave:Connect(function()
            entry.Hovered = false
            self:_setHandleState(entry, entry.Resizing)
        end)
    end
    return button
end

function WindowManager:_makeEdge(entry, name, direction)
    local object = entry.Object
    local thickness = self.TouchEnabled and 18 or 8
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
        button.Size = UDim2.new(0, thickness, 1, -(self.TouchEnabled and 34 or 24))
    else
        button.AnchorPoint = Vector2.new(0, 1)
        button.Position = UDim2.fromScale(0, 1)
        button.Size = UDim2.new(1, -(self.TouchEnabled and 34 or 24), 0, thickness)
    end
    button.Parent = object
    return button
end

function WindowManager:_stop(entry, shouldSave)
    if not entry then
        return
    end
    disconnect(entry.MoveConnection)
    disconnect(entry.EndConnection)
    entry.MoveConnection = nil
    entry.EndConnection = nil
    entry.ActiveInput = nil
    local wasResizing = entry.Resizing
    entry.Resizing = false
    if entry.Object and entry.Object.Parent then
        entry.Object:SetAttribute("BadWarsResizing", false)
    end
    self:_setHandleState(entry, false)
    if wasResizing and entry.Object and entry.Object.Parent then
        self:Clamp(entry.Id, false)
        self:_snap(entry)
        self:_queueReflow(entry, true)
        if shouldSave then
            self:_saveEntry(entry)
        end
    end
end

function WindowManager:_beginResize(entry, input, direction)
    if entry.Destroyed or entry.LockSize then
        return
    end
    local inputType = input.UserInputType
    if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
        return
    end

    self:Clamp(entry.Id, false)
    self:_stop(entry, false)
    entry.Resizing = true
    entry.ActiveInput = input
    entry.Direction = direction
    entry.StartPointer = input.Position
    entry.StartSize = self:_size(entry.Object)
    entry.StartTopLeft = self:_topLeft(entry.Object)
    entry.ExpectedMovement = inputType == Enum.UserInputType.MouseButton1 and Enum.UserInputType.MouseMovement or Enum.UserInputType.Touch
    entry.Object:SetAttribute("BadWarsResizing", true)
    self:BringToFront(entry.Id)
    self:_setHandleState(entry, true)

    if type(entry.Options.OnResizeStart) == "function" then
        pcall(entry.Options.OnResizeStart, entry.Object, entry)
    end

    local maximum, viewport, margin = self:_maximum(entry)
    local maxFromPosition = Vector2.new(
        math.min(maximum.X, math.max(self:_minimum(entry).X, viewport.X - entry.StartTopLeft.X - margin)),
        math.min(maximum.Y, math.max(self:_minimum(entry).Y, viewport.Y - entry.StartTopLeft.Y - margin))
    )

    entry.MoveConnection = self.UserInputService.InputChanged:Connect(function(changed)
        if not entry.Resizing or not entry.Object.Parent or changed.UserInputType ~= entry.ExpectedMovement then
            return
        end
        if inputType == Enum.UserInputType.Touch and changed ~= entry.ActiveInput then
            return
        end

        local delta = (changed.Position - entry.StartPointer) / self:_scale()
        local width, height = entry.StartSize.X, entry.StartSize.Y
        if direction == "right" or direction == "corner" then
            width = entry.StartSize.X + delta.X
        end
        if direction == "bottom" or direction == "corner" then
            height = entry.StartSize.Y + delta.Y
        end

        local minimum = self:_minimum(entry)
        width = math.clamp(width, minimum.X, maxFromPosition.X)
        height = math.clamp(height, minimum.Y, maxFromPosition.Y)

        if direction == "corner" and inputType == Enum.UserInputType.MouseButton1 and self.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            local aspect = entry.StartSize.X / math.max(entry.StartSize.Y, 1)
            if math.abs(delta.X) >= math.abs(delta.Y) then
                height = math.clamp(width / aspect, minimum.Y, maxFromPosition.Y)
            else
                width = math.clamp(height * aspect, minimum.X, maxFromPosition.X)
            end
        end

        local size = Vector2.new(width, height)
        entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
        entry.Object:SetAttribute("BadWarsUserResized", true)
        entry.Object:SetAttribute("BadWarsUserWidth", size.X)
        entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
        self:_queueReflow(entry, false)
    end)

    entry.EndConnection = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
            self:_stop(entry, true)
        end
    end)
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
        BaseZIndex = object.ZIndex,
    }
    self.Entries[id] = entry
    self.Windows[id] = object
    object:SetAttribute("BadWarsWindowId", id)
    object:SetAttribute("BadWarsResizing", false)

    local grip = self:_makeGrip(entry)
    local right = options.RightEdge == false and nil or self:_makeEdge(entry, "AdaptiveResizeRight", "right")
    local bottom = options.BottomEdge == false and nil or self:_makeEdge(entry, "AdaptiveResizeBottom", "bottom")
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
    entry.Connections[#entry.Connections + 1] = object.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self:BringToFront(id)
        end
    end)
    entry.Connections[#entry.Connections + 1] = object.Destroying:Once(function()
        self:Unregister(id)
    end)
    entry.Connections[#entry.Connections + 1] = object:GetPropertyChangedSignal("Visible"):Connect(function()
        if object.Visible then
            task.defer(function()
                if not entry.Destroyed and object.Parent then
                    self:Clamp(id, false)
                    self:_setHandleState(entry, false)
                end
            end)
        end
    end)

    task.defer(function()
        if not entry.Destroyed and object.Parent then
            self:_restore(entry)
        end
    end)
    return entry
end

function WindowManager:BringToFront(id)
    local entry = self.Entries[id]
    if not entry or entry.Destroyed or not entry.Object.Parent then
        return
    end
    self.FocusCounter = (self.FocusCounter % 20) + 1
    entry.Object.ZIndex = entry.BaseZIndex + self.FocusCounter
    entry.Object:SetAttribute("BadWarsFocused", true)
    for otherId, other in pairs(self.Entries) do
        if otherId ~= id and other.Object and other.Object.Parent then
            other.Object:SetAttribute("BadWarsFocused", false)
        end
    end
end

function WindowManager:Clamp(id, shouldSave)
    local entry = self.Entries[id]
    if not entry or entry.Destroyed or not entry.Object.Parent then
        return
    end
    local position, size = self:_sanitize(entry, self:_topLeft(entry.Object), self:_size(entry.Object))
    entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
    self:_setTopLeft(entry.Object, position, size)
    entry.Object:SetAttribute("BadWarsUserWidth", size.X)
    if not (type(entry.Options.IsCollapsed) == "function" and entry.Options.IsCollapsed() == true) then
        entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
    end
    self:_setHandleState(entry, false)
    if shouldSave then
        self:_saveEntry(entry)
    end
end

function WindowManager:NotifyMoved(id)
    local entry = self.Entries[id]
    if not entry or entry.Destroyed or entry.LockPosition then
        return
    end
    self:Clamp(id, false)
    self:_snap(entry)
    self:_saveEntry(entry)
end

function WindowManager:SetLocked(id, kind, locked)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    if kind == "size" then
        entry.LockSize = locked == true
        self:_setHandleState(entry, false)
    elseif kind == "position" then
        entry.LockPosition = locked == true
    else
        return false
    end
    self:_saveEntry(entry)
    return true
end

function WindowManager:ResetSize(id)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    local saved = self.Layout.Windows[id]
    if type(saved) ~= "table" then
        saved = {}
        self.Layout.Windows[id] = saved
    end
    local defaultSize = vector(entry.Options.DefaultSize, self:_size(entry.Object))
    local position, size = self:_sanitize(entry, self:_topLeft(entry.Object), defaultSize)
    entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
    self:_setTopLeft(entry.Object, position, size)
    entry.Object:SetAttribute("BadWarsUserWidth", size.X)
    entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
    entry.Object:SetAttribute("BadWarsUserResized", false)
    saved.Width = nil
    saved.Height = nil
    self:_queueReflow(entry, true)
    self:_saveEntry(entry)
    return true
end

function WindowManager:ResetPosition(id)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    local defaultPosition = vector(entry.Options.DefaultPosition, self:_topLeft(entry.Object))
    local position, size = self:_sanitize(entry, defaultPosition, self:_size(entry.Object))
    self:_setTopLeft(entry.Object, position, size)
    self:_saveEntry(entry)
    return true
end

function WindowManager:Reset(id)
    local entry = self.Entries[id]
    if not entry then
        return false
    end
    self.Layout.Windows[id] = nil
    entry.LockPosition = entry.Options.LockPosition == true
    entry.LockSize = entry.Options.LockSize == true
    local defaultSize = vector(entry.Options.DefaultSize, self:_size(entry.Object))
    local defaultPosition = vector(entry.Options.DefaultPosition, self:_topLeft(entry.Object))
    local position, size = self:_sanitize(entry, defaultPosition, defaultSize)
    entry.Object.Size = UDim2.fromOffset(size.X, size.Y)
    self:_setTopLeft(entry.Object, position, size)
    entry.Object:SetAttribute("BadWarsUserWidth", size.X)
    entry.Object:SetAttribute("BadWarsUserHeight", size.Y)
    entry.Object:SetAttribute("BadWarsUserResized", false)
    self:_setHandleState(entry, false)
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
    disconnect(self.ViewportConnection)
    if not signal then
        return
    end
    self.ViewportConnection = signal:Connect(function()
        cancel(self.ViewportThread)
        self.ViewportThread = task.delay(0.06, function()
            self.ViewportThread = nil
            for id, entry in pairs(self.Entries) do
                self:Clamp(id, false)
                self:_queueReflow(entry, true)
                self:_saveEntry(entry)
            end
        end)
    end)
end

function WindowManager:Unregister(id)
    local entry = self.Entries[id]
    if not entry then
        return
    end
    entry.Destroyed = true
    self:_stop(entry, false)
    for _, connection in ipairs(entry.Connections) do
        disconnect(connection)
    end
    table.clear(entry.Connections)
    for _, handle in ipairs({ entry.Grip, entry.Right, entry.Bottom }) do
        if handle and handle.Parent then
            handle:Destroy()
        end
    end
    self.Entries[id] = nil
    self.Windows[id] = nil
end

function WindowManager:Destroy()
    if self.Destroyed then
        return
    end
    self.Destroyed = true
    cancel(self.SaveThread)
    cancel(self.ViewportThread)
    disconnect(self.ViewportConnection)
    local ids = {}
    for id in pairs(self.Entries) do
        ids[#ids + 1] = id
    end
    for _, id in ipairs(ids) do
        self:Unregister(id)
    end
end

return WindowManager
