-- BadWars V14 BedWars compatibility and module-health bootstrap
local Bad = shared.Bad
if type(Bad) ~= "table" then
    return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local lplr = Players.LocalPlayer or Players.PlayerAdded:Wait()
local gameCamera = Workspace.CurrentCamera
local collectionService = CollectionService
local tweenService = TweenService
local httpService = HttpService

local function safeRequire(module)
    if not module or not module:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, module)
    return ok and result or nil
end

local function findModule(root, names)
    if not root then
        return nil
    end
    local wanted = {}
    for _, name in ipairs(names) do
        wanted[string.lower(name)] = true
    end
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("ModuleScript") and wanted[string.lower(descendant.Name)] then
            return descendant
        end
    end
end

local function makeSignal()
    local bindable = Instance.new("BindableEvent")
    return {
        Event = bindable.Event,
        Fire = function(_, ...)
            bindable:Fire(...)
        end,
        Destroy = function()
            bindable:Destroy()
        end,
    }
end

local nullRemoteSignal = makeSignal()
local nullRemote = {
    instance = {
        OnClientEvent = nullRemoteSignal.Event,
        OnServerEvent = nullRemoteSignal.Event,
    },
    FireServer = function() return nil end,
    InvokeServer = function() return nil end,
    SendToServer = function() return nil end,
    CallServer = function() return nil end,
    Connect = function(_, callback)
        return nullRemoteSignal.Event:Connect(callback)
    end,
}
local nullNamespace = {
    Get = function() return nullRemote end,
}

local bedwars = Bad.bedwars or {}
Bad.bedwars = bedwars
bedwars.Game = "BedWars"
bedwars.PlaceId = game.PlaceId
bedwars.Phase = "loading"
bedwars.Map = "unknown"
bedwars.Modules = bedwars.Modules or {}
bedwars.Missing = bedwars.Missing or {}

local clientModule = findModule(ReplicatedStorage, {"remotes"})
local clientLibrary = safeRequire(clientModule)
local realClient = type(clientLibrary) == "table" and (clientLibrary.default and clientLibrary.default.Client or clientLibrary.Client) or nil
local safeClient = {}
function safeClient:Get(name)
    if realClient and type(realClient.Get) == "function" and name ~= nil then
        local ok, result = pcall(realClient.Get, realClient, name)
        if ok and result then return result end
    end
    return nullRemote
end
function safeClient:GetNamespace(name)
    if realClient and type(realClient.GetNamespace) == "function" then
        local ok, result = pcall(realClient.GetNamespace, realClient, name)
        if ok and result then return result end
    end
    return nullNamespace
end
bedwars.Client = safeClient
bedwars.RawClient = realClient

local knit
pcall(function()
    local scripts = lplr:WaitForChild("PlayerScripts", 8)
    local knitModule = scripts and findModule(scripts, {"knit"})
    local knitSource = safeRequire(knitModule)
    if type(knitSource) == "table" then
        knit = knitSource.Controllers and knitSource or nil
        if not knit and type(knitSource.setup) == "function" and debug and debug.getupvalue then
            local ok, value = pcall(debug.getupvalue, knitSource.setup, 9)
            if ok and type(value) == "table" then knit = value end
        end
    end
end)
bedwars.Knit = knit

local controllerNames = {
    "AbilityController",
    "AppController",
    "ArmorController",
    "BalloonController",
    "BatteryEffectsController",
    "BedController",
    "BlockBreakController",
    "BlockController",
    "BlockKickerKitController",
    "BlockPlacementController",
    "CannonHandController",
    "CatController",
    "ChestController",
    "CombatController",
    "DamageController",
    "DaoController",
    "DragonSlayerController",
    "FishingMinigameController",
    "GrimReaperController",
    "HealthController",
    "HotbarController",
    "InventoryController",
    "ItemDropController",
    "KitController",
    "LaunchPadController",
    "MatchController",
    "PearlController",
    "PickupController",
    "ProjectileController",
    "QueueController",
    "ScytheController",
    "ShopController",
    "SoundController",
    "SoundManager",
    "SpiritAssassinController",
    "SprintController",
    "StarCollectorController",
    "Store",
    "StoreController",
    "SwordController",
    "TeamController",
    "TeleportController",
    "TrapController",
    "ViewmodelController",
    "VoidDragonController",
}
for _, name in ipairs(controllerNames) do
    if bedwars[name] == nil and knit and type(knit.Controllers) == "table" then
        bedwars[name] = knit.Controllers[name]
    end
end

local function resolveDataModule(names)
    local module = findModule(ReplicatedStorage, names)
    local value = safeRequire(module)
    if type(value) == "table" and value.default then value = value.default end
    return type(value) == "table" and value or nil
end

bedwars.ItemMeta = bedwars.ItemMeta or resolveDataModule({"item-meta", "itemmeta"}) or {}
bedwars.ProjectileMeta = bedwars.ProjectileMeta or resolveDataModule({"projectile-meta", "projectilemeta"}) or {}
bedwars.BedBreakEffectMeta = bedwars.BedBreakEffectMeta or resolveDataModule({"bed-break-effect-meta", "bedbreakeffectmeta"}) or {}
bedwars.BedwarsKitMeta = bedwars.BedwarsKitMeta or resolveDataModule({"bedwars-kit-meta", "kit-meta"}) or {}
bedwars.BlockMeta = bedwars.BlockMeta or resolveDataModule({"block-meta", "blockmeta"}) or {}
bedwars.KnockbackTable = bedwars.KnockbackTable or resolveDataModule({"knockback-meta", "knockbacktable"}) or {}
bedwars.QueueMeta = bedwars.QueueMeta or resolveDataModule({"queue-meta", "queuemeta"}) or {}
bedwars.Shop = bedwars.Shop or resolveDataModule({"shop", "shop-items", "shopitems"}) or {}
bedwars.UILayers = bedwars.UILayers or resolveDataModule({"ui-layers", "uilayers"}) or {MAIN = "MAIN"}

local controllerFallback = setmetatable({}, {
    __index = function(_, key)
        if key == "lastAttack" then return 0 end
        return function() return nil end
    end,
})
for _, name in ipairs(controllerNames) do
    if bedwars[name] == nil then
        bedwars[name] = controllerFallback
        bedwars.Missing[name] = true
    end
end

local storeModule
pcall(function()
    local scripts = lplr:FindFirstChild("PlayerScripts")
    storeModule = scripts and findModule(scripts, {"store", "client-store"})
end)
local resolvedStore = safeRequire(storeModule)
if type(resolvedStore) == "table" and resolvedStore.default then resolvedStore = resolvedStore.default end
if type(resolvedStore) == "table" and type(resolvedStore.dispatch) == "function" then
    bedwars.Store = resolvedStore
    bedwars.Missing.Store = nil
end

local store = Bad.store or bedwars.Store or {}
store.inventory = store.inventory or {}
store.inventory.hotbar = store.inventory.hotbar or {}
store.inventory.inventory = store.inventory.inventory or {items = {}}
store.inventory.inventory.items = store.inventory.inventory.items or {}
store.inventory.hotbarSlot = store.inventory.hotbarSlot or 0
store.inventory.chest = store.inventory.chest or {}
store.hand = store.hand or {}
store.tools = store.tools or {}
store.blocks = store.blocks or {}
store.shopLoaded = store.shopLoaded == true
store.matchState = tonumber(store.matchState) or 0
store.queueType = tostring(store.queueType or "")
store.equippedKit = tostring(store.equippedKit or "")
store.localInventory = store.localInventory or store.inventory.inventory
store.KillauraTarget = store.KillauraTarget
Bad.store = store

local remotes = Bad.remotes or setmetatable({}, {
    __index = function(_, key) return tostring(key) end,
})
Bad.remotes = remotes

local BadEvents = Bad.BadEvents or {}
for _, name in ipairs({
    "BedwarsBedBreak", "PlaceBlockEvent", "BreakBlockEvent", "InventoryChanged",
    "InventoryAmountChanged", "CatPounce"
}) do
    if type(BadEvents[name]) ~= "table" or BadEvents[name].Event == nil then
        BadEvents[name] = makeSignal()
    end
end
Bad.BadEvents = BadEvents

local entitylib = Bad.entitylib or (Bad.Libraries and Bad.Libraries.entity) or {
    isAlive = false,
    List = {},
    character = {},
    EntityPosition = function() return nil end,
    EntityMouse = function() return nil end,
    AllPosition = function() return {} end,
}
Bad.entitylib = entitylib
local targetinfo = Bad.targetinfo or {Targets = {}}
Bad.targetinfo = targetinfo
local prediction = (Bad.libraries and Bad.libraries.prediction) or (Bad.Libraries and Bad.Libraries.prediction) or {}
local sortmethods = Bad.sortmethods or {Health = function() return false end}

local function notif(title, text, duration, style)
    if type(Bad.CreateNotification) == "function" then
        Bad:CreateNotification(title, text, duration or 4, style or "warning")
    end
end

local function dependencyAvailable(name)
    return bedwars[name] ~= nil and bedwars[name] ~= controllerFallback and not bedwars.Missing[name]
end

local function unavailable(module, reason)
    notif(module and module.Name or "Module unavailable", reason, 5, "warning")
    task.defer(function()
        if module and module.Enabled and type(module.Toggle) == "function" then
            module:Toggle(true)
        end
    end)
    return false
end

Bad.BedWarsCompatibility = {
    Has = dependencyAvailable,
    Unavailable = unavailable,
    Client = safeClient,
    Missing = bedwars.Missing,
}

local function collection(tag, maid, callback)
    local list = CollectionService:GetTagged(tag)
    if callback then
        local filtered = {}
        for _, object in ipairs(list) do callback(filtered, object) end
        list = filtered
    end
    if maid and type(maid.Clean) == "function" then
        maid:Clean(CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
            if callback then callback(list, object) else table.insert(list, object) end
        end))
        maid:Clean(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(object)
            local index = table.find(list, object)
            if index then table.remove(list, index) end
        end))
    end
    return list
end

local sides = {
    Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
}
local function getPlacedBlock(position)
    local controller = bedwars.BlockController
    if controller and type(controller.getStore) == "function" then
        local ok, storeObject = pcall(controller.getStore, controller)
        if ok and storeObject and type(storeObject.getBlockAt) == "function" then
            local blockPosition = type(controller.getBlockPosition) == "function" and controller:getBlockPosition(position) or position / 3
            local success, block = pcall(storeObject.getBlockAt, storeObject, blockPosition)
            if success and block then return block end
        end
    end
    return nil
end
local function getWool()
    for _, item in ipairs(store.inventory.inventory.items) do
        local meta = bedwars.ItemMeta[item.itemType]
        if meta and meta.block then return item.itemType end
    end
end
local function getBow() return nil end
if type(bedwars.getIcon) ~= "function" then
    bedwars.getIcon = function(item)
        local itemType = type(item) == "table" and item.itemType or tostring(item or "")
        local meta = bedwars.ItemMeta[itemType]
        return type(meta) == "table" and (meta.image or meta.icon) or ""
    end
end
local function hotbarSwitch(slot)
    if bedwars.Store and type(bedwars.Store.dispatch) == "function" then
        return pcall(bedwars.Store.dispatch, bedwars.Store, {type = "InventorySelectHotbarSlot", slot = slot})
    end
    return false
end
local function switchItem() return false end
local function getItem(itemType)
    for _, item in ipairs(store.inventory.inventory.items) do
        if item.itemType == itemType then return item end
    end
end

local uipallet = Bad.uipallet or {
    Main = Color3.fromRGB(8, 12, 18), Text = Color3.fromRGB(225, 232, 242), Font = Font.fromEnum(Enum.Font.Gotham),
}
local color = Bad.color or {
    Light = function(c, amount) return c:Lerp(Color3.new(1,1,1), amount or 0) end,
    Dark = function(c, amount) return c:Lerp(Color3.new(), amount or 0) end,
}
local tween = Bad.tween or {Tween = function(_, object, info, props) return TweenService:Create(object, info, props):Play() end}
local function addBlur(parent)
    local blur = Instance.new("Frame")
    blur.Name = "Blur"
    blur.Size = UDim2.fromScale(1, 1)
    blur.BackgroundTransparency = 1
    blur.BorderSizePixel = 0
    blur.Visible = true
    blur.Parent = parent
    return blur
end
local executorAsset = getcustomasset
local function getcustomasset(path)
    return type(executorAsset) == "function" and executorAsset(path) or path
end

local function detectPhase()
    bedwars.Phase = ReplicatedStorage:FindFirstChild("GameInProgress") and "game" or "lobby"
end
detectPhase()
local phaseConnection = RunService.Heartbeat:Connect(function()
    if not Bad.Loaded then phaseConnection:Disconnect() return end
    detectPhase()
end)
if type(Bad.Clean) == "function" then Bad:Clean(phaseConnection) end


-- V14 shared compatibility, runtime guards, and module health.
local compatibility = Bad.BedWarsCompatibility or {}
compatibility.Version = "17.0"
compatibility.Missing = bedwars.Missing
compatibility.Modules = compatibility.Modules or {}
compatibility.Notified = compatibility.Notified or {}
compatibility.ControllerAliases = compatibility.ControllerAliases or {
    BlockController = {"BlockController", "BlockBreakController", "BlockPlacementController"},
    SoundManager = {"SoundManager", "SoundController"},
    Store = {"Store", "StoreController"},
}

local function traceError(message)
    if debug and type(debug.traceback) == "function" then
        return debug.traceback(tostring(message), 2)
    end
    return tostring(message)
end

local function shallowCopy(value)
    local result = {}
    if type(value) == "table" then
        for key, entry in pairs(value) do
            result[key] = entry
        end
    end
    return result
end

local function safeDisconnect(value)
    if type(value) == "function" then
        pcall(value)
        return
    end
    if typeof(value) == "RBXScriptConnection" then
        pcall(function()
            value:Disconnect()
        end)
        return
    end
    if type(value) == "table" and type(value.Disconnect) == "function" then
        pcall(value.Disconnect, value)
    end
end

function compatibility:NotifyOnce(key, title, message, style)
    key = tostring(key or title or message)
    if self.Notified[key] then
        return
    end
    self.Notified[key] = true
    notif(
        tostring(title or "BedWars"),
        tostring(message or ""),
        5,
        style or "warning"
    )
end

function compatibility:SafeCall(target, method, ...)
    if type(target) ~= "table" and typeof(target) ~= "Instance" then
        return false, "target unavailable"
    end

    local callback = method
    if type(method) == "string" then
        local ok, resolved = pcall(function()
            return target[method]
        end)
        callback = ok and resolved or nil
    end

    if type(callback) ~= "function" then
        return false, "method unavailable"
    end

    return xpcall(callback, traceError, target, ...)
end

function compatibility:SafeConnect(signal, callback, maid)
    if type(callback) ~= "function" then
        return nil
    end

    local connect
    local signalType = typeof(signal)
    if signalType == "RBXScriptSignal" then
        connect = function()
            return signal:Connect(callback)
        end
    elseif type(signal) == "table" and type(signal.Connect) == "function" then
        connect = function()
            return signal:Connect(callback)
        end
    elseif type(signal) == "table" and signal.Event then
        connect = function()
            return signal.Event:Connect(callback)
        end
    end

    if not connect then
        return nil
    end

    local ok, connection = pcall(connect)
    if not ok then
        return nil
    end

    if maid and type(maid.Clean) == "function" then
        maid:Clean(connection)
    end
    return connection
end

function compatibility:WaitFor(predicate, timeout, interval)
    if type(predicate) ~= "function" then
        return false, nil
    end

    local deadline = os.clock() + (tonumber(timeout) or 8)
    local delay = math.max(tonumber(interval) or 0.1, 0.03)
    repeat
        local ok, value = pcall(predicate)
        if ok and value ~= nil and value ~= false then
            return true, value
        end
        task.wait(delay)
    until os.clock() >= deadline or not Bad.Loaded

    return false, nil
end

function compatibility:ResolveController(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    local aliases = self.ControllerAliases[name] or {name}
    for _, alias in ipairs(aliases) do
        local current = rawget(bedwars, alias)
        if current and current ~= controllerFallback then
            bedwars[name] = current
            bedwars.Missing[name] = nil
            return current
        end

        if knit and type(knit.Controllers) == "table" then
            current = knit.Controllers[alias]
            if current then
                bedwars[name] = current
                bedwars.Missing[name] = nil
                return current
            end
        end
    end

    return nil
end

function compatibility:ResolveRemote(name)
    if name == nil then
        return nullRemote
    end
    local remote = safeClient:Get(name)
    return remote or nullRemote
end

function compatibility:Has(name)
    return self:ResolveController(name) ~= nil
        or (
            rawget(bedwars, name) ~= nil
            and rawget(bedwars, name) ~= controllerFallback
        )
end

function compatibility:InventoryItems()
    local inventory = store
        and store.inventory
        and store.inventory.inventory
    local items = inventory and inventory.items
    return type(items) == "table" and items or {}
end

function compatibility:GetItem(itemType)
    if itemType == nil then
        return nil
    end

    for _, item in ipairs(self:InventoryItems()) do
        if item and item.itemType == itemType then
            return item
        end
    end
    return nil
end

function compatibility:GetMeta(item)
    local itemType = type(item) == "table"
        and (item.itemType or (item.tool and item.tool.Name))
        or tostring(item or "")
    return bedwars.ItemMeta[itemType]
end

function compatibility:CleanupModule(module)
    if type(module) ~= "table" then
        return
    end

    for _, connection in pairs(module.Connections or {}) do
        safeDisconnect(connection)
    end
    if type(module.Connections) == "table" then
        table.clear(module.Connections)
    end

    for _, key in ipairs({"Tasks", "Threads"}) do
        local tasks = module[key]
        if type(tasks) == "table" then
            for _, thread in pairs(tasks) do
                if type(thread) == "thread" then
                    pcall(task.cancel, thread)
                elseif type(thread) == "function" then
                    pcall(thread)
                end
            end
            table.clear(tasks)
        end
    end
end

function compatibility:RecordFailure(module, sourcePath, failure)
    local moduleName = type(module) == "table"
        and tostring(module.Name or "Unknown")
        or tostring(module or "Unknown")
    local record = self.Modules[moduleName] or {
        Name = moduleName,
        Failures = 0,
        Health = "unknown",
    }

    record.SourcePath = sourcePath or record.SourcePath
    record.Failures += 1
    record.Health = "failed"
    record.LastError = tostring(failure)
    record.LastFailure = os.clock()
    self.Modules[moduleName] = record

    if type(module) == "table" then
        module.Health = "failed"
        module.LastError = record.LastError
        module.FailureCount = record.Failures
        module.Enabled = false
        self:CleanupModule(module)

        pcall(function()
            if module.Object and module.Object:IsA("GuiObject") then
                module.Object:SetAttribute("ModuleHealth", "failed")
            end
        end)
    end

    self:NotifyOnce(
        "module-failure:" .. moduleName,
        moduleName,
        "Disabled after a compatibility error. Open Module Diagnostics for details.",
        "warning"
    )
end

function compatibility:Decorate(module, metadata)
    if type(module) ~= "table" then
        return module
    end
    if module.__BedWarsV14Decorated then
        return module
    end

    module.__BedWarsV14Decorated = true
    module.SourcePath = metadata and metadata.path or module.SourcePath
    module.Health = module.Health or "ready"
    module.FailureCount = tonumber(module.FailureCount) or 0

    local record = self.Modules[tostring(module.Name)] or {}
    record.Name = tostring(module.Name or metadata and metadata.name or "Unknown")
    record.SourcePath = module.SourcePath
    record.Category = tostring(module.Category or metadata and metadata.category or "")
    record.Health = "ready"
    record.Failures = tonumber(record.Failures) or 0
    self.Modules[record.Name] = record

    local rawToggle = module.Toggle
    if type(rawToggle) == "function" then
        module.Toggle = function(selfModule, ...)
            if selfModule.__BedWarsV14ToggleBusy then
                return false
            end

            selfModule.__BedWarsV14ToggleBusy = true
            local results = table.pack(xpcall(
                rawToggle,
                traceError,
                selfModule,
                ...
            ))
            selfModule.__BedWarsV14ToggleBusy = false

            if not results[1] then
                compatibility:RecordFailure(
                    selfModule,
                    selfModule.SourcePath,
                    results[2]
                )
                return false
            end

            selfModule.Health = "ready"
            local health = compatibility.Modules[tostring(selfModule.Name)]
            if health then
                health.Health = "ready"
            end
            return table.unpack(results, 2, results.n)
        end
    end

    for _, option in pairs(module.Options or {}) do
        if
            type(option) == "table"
            and type(option.Function) == "function"
            and not option.__BedWarsV14Decorated
        then
            option.__BedWarsV14Decorated = true
            local rawFunction = option.Function
            option.Function = function(...)
                local results = table.pack(xpcall(
                    rawFunction,
                    traceError,
                    ...
                ))
                if not results[1] then
                    compatibility:RecordFailure(
                        module,
                        module.SourcePath,
                        results[2]
                    )
                    return nil
                end
                return table.unpack(results, 2, results.n)
            end
        end
    end

    return module
end

function compatibility:AuditModule(module, metadata)
    local issues = {}
    if type(module) ~= "table" then
        table.insert(issues, "module not registered")
        return issues
    end
    if type(module.Name) ~= "string" or module.Name == "" then
        table.insert(issues, "name missing")
    end
    if type(module.Toggle) ~= "function" then
        table.insert(issues, "toggle function missing")
    end
    if type(module.Options) ~= "table" then
        table.insert(issues, "options table missing")
    end
    if
        metadata
        and metadata.kind ~= "Overlay"
        and (type(module.Category) ~= "string" or module.Category == "")
    then
        table.insert(issues, "category missing")
    end
    return issues
end

function compatibility:AuditAll()
    local report = {
        Version = self.Version,
        Total = 0,
        Ready = 0,
        Failed = 0,
        Issues = {},
        Modules = {},
    }

    local function collect(module, kind)
        if type(module) ~= "table" then
            return
        end
        report.Total += 1
        local name = tostring(module.Name or kind or "Unknown")
        local issues = self:AuditModule(module, {kind = kind})
        local record = shallowCopy(self.Modules[name])
        record.Name = name
        record.Kind = kind
        record.Enabled = module.Enabled == true
        record.Issues = issues
        record.Health = module.Health or record.Health or (#issues == 0 and "ready" or "warning")
        report.Modules[name] = record

        if record.Health == "failed" then
            report.Failed += 1
        else
            report.Ready += 1
        end
        if #issues > 0 then
            report.Issues[name] = issues
        end
    end

    for _, module in pairs(Bad.Modules or {}) do
        collect(module, "Module")
    end
    for _, module in pairs(Bad.Legit and Bad.Legit.Modules or {}) do
        collect(module, "Legit")
    end

    shared.__badwars_module_health = report
    return report
end

function compatibility:Unavailable(module, reason)
    self:RecordFailure(
        module,
        type(module) == "table" and module.SourcePath or nil,
        reason or "required BedWars dependency is unavailable"
    )
    return false
end

Bad.BedWarsCompatibility = compatibility

-- Resolve controllers again after Knit finishes initializing.
task.spawn(function()
    local deadline = os.clock() + 12
    repeat
        for _, controllerName in ipairs(controllerNames) do
            compatibility:ResolveController(controllerName)
        end
        task.wait(0.35)
    until os.clock() >= deadline or not Bad.Loaded

    compatibility.Ready = true
    compatibility:AuditAll()
end)

return bedwars
