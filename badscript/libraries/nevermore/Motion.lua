--!strict
-- BadWars adapter built on Quenty/Nevermore Spring.
-- Runs only while one or more properties are actively settling.

shared = type(shared) == "table" and shared or {}
local dependencies = assert(shared.__BadWarsNevermoreModules, "Nevermore dependency table missing")
local Maid = assert(dependencies.Maid, "Maid missing")
local Spring = assert(dependencies.Spring, "Spring missing")
local RunService = game:GetService("RunService")

local Motion = {}
local registry = setmetatable({}, { __mode = "k" })
local renderMaid = Maid.new()
local activeCount = 0
local runnerActive = false

local Vec4 = {}
Vec4.__index = Vec4
function Vec4.new(a, b, c, d)
    return setmetatable({ a = a, b = b, c = c, d = d }, Vec4)
end
function Vec4.__add(x, y)
    return Vec4.new(x.a + y.a, x.b + y.b, x.c + y.c, x.d + y.d)
end
function Vec4.__sub(x, y)
    return Vec4.new(x.a - y.a, x.b - y.b, x.c - y.c, x.d - y.d)
end
function Vec4.__mul(x, y)
    if type(x) == "number" then
        return Vec4.new(x * y.a, x * y.b, x * y.c, x * y.d)
    elseif type(y) == "number" then
        return Vec4.new(x.a * y, x.b * y, x.c * y, x.d * y)
    end
    error("Vec4 multiplication expects a number", 2)
end
function Vec4.__div(x, y)
    return Vec4.new(x.a / y, x.b / y, x.c / y, x.d / y)
end

local function encode(value)
    local kind = typeof(value)
    if kind == "UDim2" then
        return Vec4.new(value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset), "UDim2"
    elseif kind == "UDim" then
        return Vector2.new(value.Scale, value.Offset), "UDim"
    elseif kind == "Color3" then
        return Vector3.new(value.R, value.G, value.B), "Color3"
    elseif kind == "number" or kind == "Vector2" or kind == "Vector3" then
        return value, kind
    end
    return nil, nil
end

local function decode(value, kind)
    if kind == "UDim2" then
        return UDim2.new(value.a, value.b, value.c, value.d)
    elseif kind == "UDim" then
        return UDim.new(value.X, value.Y)
    elseif kind == "Color3" then
        return Color3.new(
            math.clamp(value.X, 0, 1),
            math.clamp(value.Y, 0, 1),
            math.clamp(value.Z, 0, 1)
        )
    end
    return value
end

local function magnitude(value)
    if getmetatable(value) == Vec4 then
        return math.sqrt(value.a * value.a + value.b * value.b + value.c * value.c + value.d * value.d)
    end
    local kind = typeof(value)
    if kind == "number" then
        return math.abs(value)
    elseif kind == "Vector2" or kind == "Vector3" then
        return value.Magnitude
    end
    return math.huge
end

local function ensureRunner()
    if runnerActive then
        return
    end
    runnerActive = true
    renderMaid.Render = RunService.RenderStepped:Connect(function()
        if activeCount <= 0 then
            activeCount = 0
            runnerActive = false
            renderMaid.Render = nil
            return
        end

        for instance, properties in pairs(registry) do
            if not instance.Parent then
                registry[instance] = nil
                for _ in pairs(properties) do
                    activeCount = math.max(activeCount - 1, 0)
                end
                continue
            end

            for property, state in pairs(properties) do
                local spring = state.Spring
                local current = spring.Position
                local velocity = spring.Velocity
                local target = spring.Target
                local ok = pcall(function()
                    instance[property] = decode(current, state.Kind)
                end)

                if not ok or (magnitude(current - target) <= state.PositionEpsilon and magnitude(velocity) <= state.VelocityEpsilon) then
                    pcall(function()
                        instance[property] = state.TargetValue
                    end)
                    properties[property] = nil
                    activeCount = math.max(activeCount - 1, 0)
                end
            end

            if next(properties) == nil then
                registry[instance] = nil
            end
        end
    end)
end

function Motion.target(instance, damping, frequency, properties)
    assert(typeof(instance) == "Instance", "Instance expected")
    assert(type(properties) == "table", "Properties expected")

    local states = registry[instance]
    if not states then
        states = {}
        registry[instance] = states
    end

    for property, targetValue in pairs(properties) do
        local ok, currentValue = pcall(function()
            return instance[property]
        end)
        if not ok then
            continue
        end
        local currentEncoded, kind = encode(currentValue)
        local targetEncoded, targetKind = encode(targetValue)
        if currentEncoded == nil or targetEncoded == nil or kind ~= targetKind then
            pcall(function()
                instance[property] = targetValue
            end)
            continue
        end

        local state = states[property]
        if not state then
            local spring = Spring.new(currentEncoded)
            state = {
                Spring = spring,
                Kind = kind,
                TargetValue = targetValue,
                PositionEpsilon = kind == "Color3" and 0.0015 or 0.002,
                VelocityEpsilon = kind == "Color3" and 0.012 or 0.02,
            }
            states[property] = state
            activeCount += 1
        end

        state.Spring.Position = currentEncoded
        state.Spring.Damper = math.clamp(tonumber(damping) or 1, 0, 2)
        state.Spring.Speed = math.max(tonumber(frequency) or 20, 0.01)
        state.Spring.Target = targetEncoded
        state.TargetValue = targetValue
        state.Kind = kind
    end

    if next(states) == nil then
        registry[instance] = nil
    else
        ensureRunner()
    end
end

function Motion.stop(instance, property)
    local states = registry[instance]
    if not states then
        return
    end
    if property ~= nil then
        if states[property] then
            states[property] = nil
            activeCount = math.max(activeCount - 1, 0)
        end
    else
        for _ in pairs(states) do
            activeCount = math.max(activeCount - 1, 0)
        end
        registry[instance] = nil
    end
    if states and next(states) == nil then
        registry[instance] = nil
    end
end

function Motion.stopAll()
    table.clear(registry)
    activeCount = 0
    runnerActive = false
    renderMaid:DoCleaning()
end

function Motion.isAnimating(instance, property)
    local states = registry[instance]
    return states ~= nil and (property == nil or states[property] ~= nil)
end

Motion.Destroy = Motion.stopAll
return Motion
