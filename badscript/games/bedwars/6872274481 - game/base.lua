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
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local lplr = Players.LocalPlayer or Players.PlayerAdded:Wait()
local inputService = UserInputService
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

local function resolveNamedExport(names, exportName)
    local module = findModule(ReplicatedStorage, names)
    local value = safeRequire(module)
    if type(value) == "table" and value.default then value = value.default end
    if type(value) ~= "table" then
        return nil
    end
    if exportName and value[exportName] ~= nil then
        return value[exportName]
    end
    return value
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
bedwars.KnockbackUtil = bedwars.KnockbackUtil or resolveNamedExport({"knockback-util", "knockbackutil"}, "KnockbackUtil")
bedwars.SoundList = bedwars.SoundList or resolveNamedExport({"game-sound", "gamesound"}, "GameSound")
bedwars.BlockPlacer = bedwars.BlockPlacer or resolveNamedExport({"block-placer", "blockplacer"}, "BlockPlacer")
bedwars.BlockEngine = bedwars.BlockEngine or resolveNamedExport({"block-engine", "blockengine"}, "BlockEngine")

local function isControllerFallback(controller)
    return type(controller) == "table" and controller.__IsBedWarsFallback == true
end

local function makeControllerFallback()
    return setmetatable({
        __IsBedWarsFallback = true,
    }, {
        __index = function(_, key)
            if key == "lastAttack" or key == "lastSwing" then
                return 0
            end
            return function() return nil end
        end,
    })
end

for _, name in ipairs(controllerNames) do
    if bedwars[name] == nil then
        bedwars[name] = makeControllerFallback()
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
store.shop = store.shop or {}
store.tools = store.tools or {}
Bad.store = store

local remotes = Bad.remotes or setmetatable({}, {
    __index = function(_, key) return tostring(key) end,
})
Bad.remotes = remotes

local BadEvents = Bad.BadEvents or {}
for _, name in ipairs({
    "BedwarsBedBreak", "PlaceBlockEvent", "BreakBlockEvent", "InventoryChanged",
    "InventoryAmountChanged", "CatPounce", "MatchEndEvent", "EntityDeathEvent",
    "EntityDamageEvent", "AttributeChanged", "GrapplingHookFunctions", "BalloonPopped", "AngelProgress",
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
    local controller = bedwars[name]
    return controller ~= nil and not isControllerFallback(controller) and not bedwars.Missing[name]
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

local function getItem(itemType)
    for _, item in ipairs(store.inventory.inventory.items) do
        if item.itemType == itemType then return item end
    end
end

local function switchItem(tool, delayTime)
    delayTime = delayTime or 0.05
    local character = lplr.Character
    local hand = character and character:FindFirstChild("HandInvItem")
    if not hand or not tool or tool.Parent == nil then
        return false
    end
    if hand.Value == tool then
        return true
    end
    task.spawn(function()
        local remote = remotes.EquipItem
        if bedwars.Client and remote then
            pcall(function()
                bedwars.Client:Get(remote):CallServerAsync({hand = tool})
            end)
        end
    end)
    hand.Value = tool
    if delayTime > 0 then
        task.wait(delayTime)
    end
    return true
end

local function traceError(message)
    if debug and type(debug.traceback) == "function" then
        return debug.traceback(tostring(message), 2)
    end
    return tostring(message)
end

local function run(callback)
    if type(callback) ~= "function" then
        return
    end
    local ok, err = xpcall(callback, traceError)
    if not ok then
        warn("[BedWars] " .. tostring(err))
    end
end

local function syncStoreFromState(newState, oldState)
    if type(newState) ~= "table" then
        return
    end
    oldState = type(oldState) == "table" and oldState or {}

    local newBedwars = newState.Bedwars
    local oldBedwars = oldState.Bedwars
    if newBedwars ~= oldBedwars then
        store.equippedKit = newBedwars and newBedwars.kit ~= "none" and newBedwars.kit or ""
    end

    local newGame = newState.Game
    local oldGame = oldState.Game
    if newGame ~= oldGame and type(newGame) == "table" then
        store.matchState = tonumber(newGame.matchState) or store.matchState
        store.queueType = tostring(newGame.queueType or store.queueType)
    end

    local newInventory = newState.Inventory
    local oldInventory = oldState.Inventory
    if newInventory ~= oldInventory then
        local observed = newInventory and newInventory.observedInventory
        if type(observed) == "table" then
            store.inventory = observed
            store.localInventory = observed.inventory or store.localInventory

            local handItem = observed.inventory and observed.inventory.hand
            local toolType = ""
            if handItem and bedwars.ItemMeta[handItem.itemType] then
                local meta = bedwars.ItemMeta[handItem.itemType]
                toolType = meta.sword and "sword"
                    or meta.block and "block"
                    or (tostring(handItem.itemType):find("bow") and "bow")
                    or ""
            end
            store.hand = {
                tool = handItem and handItem.tool,
                amount = handItem and handItem.amount or 0,
                toolType = toolType,
            }
        end

        if BadEvents.InventoryChanged and BadEvents.InventoryChanged.Event then
            BadEvents.InventoryChanged:Fire()
        end
    end
end

local function ensureBlockPlacer(defaultType)
    if store.blockPlacer and type(store.blockPlacer.placeBlock) == "function" then
        return store.blockPlacer
    end
    if bedwars.BlockPlacer and bedwars.BlockEngine and type(bedwars.BlockPlacer.new) == "function" then
        local ok, placer = pcall(bedwars.BlockPlacer.new, bedwars.BlockEngine, defaultType or "wool_white")
        if ok and type(placer) == "table" then
            store.blockPlacer = placer
            return placer
        end
    end
    return nil
end

bedwars.placeBlock = function(pos, itemType)
    itemType = tostring(itemType or "")
    if itemType == "" or not getItem(itemType) then
        return false
    end

    local blockController = bedwars.BlockController
    if not blockController or isControllerFallback(blockController) then
        return false
    end

    local placer = ensureBlockPlacer(itemType)
    if placer then
        placer.blockType = itemType
        if type(blockController.getBlockPosition) == "function" and type(placer.placeBlock) == "function" then
            local ok = pcall(placer.placeBlock, placer, blockController:getBlockPosition(pos))
            return ok
        end
    end

    local placement = bedwars.BlockPlacementController
    if placement and not isControllerFallback(placement) and type(placement.placeBlock) == "function" then
        return pcall(placement.placeBlock, placement, pos, itemType)
    end

    return false
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

task.spawn(function()
    local deadline = os.clock() + 15
    repeat
        if bedwars.Store and type(bedwars.Store.getState) == "function" then
            local ok, state = pcall(bedwars.Store.getState, bedwars.Store)
            if ok then
                syncStoreFromState(state, {})
            end
            if type(bedwars.Store.changed) == "table" and type(bedwars.Store.changed.connect) == "function" then
                local connection = bedwars.Store.changed:connect(function(newState, oldState)
                    syncStoreFromState(newState, oldState)
                end)
                if type(Bad.Clean) == "function" then
                    Bad:Clean(connection)
                end
                break
            end
        end
        task.wait(0.35)
    until os.clock() >= deadline or not Bad.Loaded
end)

task.defer(function()
    if type(collection) == "function" then
        store.shop = collection({"BedwarsItemShop", "TeamUpgradeShopkeeper"}, nil, function(list, object)
            table.insert(list, {
                Id = object.Name,
                RootPart = object,
                Shop = object:HasTag("BedwarsItemShop"),
                Upgrades = object:HasTag("TeamUpgradeShopkeeper"),
            })
        end)
    end
end)

-- V14 module runtime: legacy globals, game libraries, and safe helpers.
local StarterGui = game:GetService("StarterGui")
starterGui = StarterGui
oldinvrender = oldinvrender

local function safeRequireModule(module)
    if not module or not module:IsA("ModuleScript") then
        return nil
    end
    local ok, result = pcall(require, module)
    if not ok then
        return nil
    end
    if type(result) == "table" and result.default ~= nil then
        return result.default
    end
    return result
end

local function safeRequirePath(root, pathParts)
    if not root then
        return nil
    end
    local current = root
    for _, part in ipairs(pathParts) do
        if type(part) ~= "string" or part == "" then
            return nil
        end
        current = current:FindFirstChild(part)
        if not current then
            return nil
        end
    end
    return safeRequireModule(current)
end

function getRoactRender(func)
    if type(func) ~= "function" or not debug or type(debug.getupvalue) ~= "function" then
        return function() end
    end
    local ok, result = pcall(function()
        return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
    end)
    return ok and type(result) == "function" and result or function() end
end

local function getBestArmor(slot)
    local closest, bestReduction = nil, 0
    for _, item in ipairs(store.inventory.inventory.items) do
        local meta = item and bedwars.ItemMeta[item.itemType]
        if meta and meta.armor and meta.armor.slot == slot then
            local reduction = meta.armor.damageReductionMultiplier or 0
            if reduction > bestReduction then
                closest = item
                bestReduction = reduction
            end
        end
    end
    return closest
end

local function getSpeed()
    local sprint = bedwars.SprintController
    if not sprint or isControllerFallback(sprint) or type(sprint.getMovementStatusModifier) ~= "function" then
        return 20
    end

    local ok, modifiers = pcall(function()
        return sprint:getMovementStatusModifier():getModifiers()
    end)
    if not ok or type(modifiers) ~= "table" then
        return 20
    end

    local multi, increase = 0, true
    for _, modifier in modifiers do
        local constant = modifier.constantSpeedMultiplier or 0
        if constant > math.max(multi, 1) then
            increase = false
            multi = constant - (0.06 * math.round(constant))
        end
    end
    for _, modifier in modifiers do
        multi += math.max((modifier.moveSpeedMultiplier or 0) - 1, 0)
    end
    if multi > 0 and increase then
        multi += 0.16 + (0.02 * math.round(multi))
    end
    return 20 * (multi + 1)
end

Bad.getSpeed = getSpeed
Bad.getItem = getItem
Bad.getBestArmor = getBestArmor

if type(bedwars.breakBlock) ~= "function" then
    bedwars.breakBlock = function(block, effects, anim, customHealthbar, instantBreak)
        if not block or not entitylib.isAlive or not entitylib.character or not entitylib.character.RootPart then
            return
        end

        local denied = false
        pcall(function()
            denied = lplr:GetAttribute("DenyBlockBreak") == true
        end)
        if denied then
            return
        end

        local blockController = bedwars.BlockController
        if not blockController or isControllerFallback(blockController) then
            return
        end

        local root = entitylib.character.RootPart
        local worldPos = block.Position
        if (root.Position - worldPos).Magnitude > 30 then
            return
        end

        local blockPosition
        pcall(function()
            blockPosition = blockController:getBlockPosition(worldPos)
        end)
        if not blockPosition then
            return
        end

        if bedwars.SwordController and not isControllerFallback(bedwars.SwordController) then
            pcall(function()
                if (workspace:GetServerTimeNow() - (bedwars.SwordController.lastAttack or 0)) > 0.4 then
                    local meta = bedwars.ItemMeta[block.Name]
                    local breakType = meta and meta.block and meta.block.breakType
                    local tool = breakType and store.tools and store.tools[breakType]
                    if tool then
                        switchItem(tool.tool)
                    end
                end
            end)
        end

        local damageRemote = bedwars.ClientDamageBlock
        if damageRemote and type(damageRemote.Get) == "function" then
            pcall(function()
                damageRemote:Get("DamageBlock"):CallServerAsync({
                    blockRef = {blockPosition = blockPosition},
                    hitPosition = worldPos,
                    hitNormal = Vector3.FromNormalId(Enum.NormalId.Top),
                })
            end)
        elseif bedwars.BlockBreakController and not isControllerFallback(bedwars.BlockBreakController) then
            pcall(function()
                if bedwars.BlockBreakController.blockBreaker and type(bedwars.BlockBreakController.blockBreaker.breakBlock) == "function" then
                    bedwars.BlockBreakController.blockBreaker:breakBlock(block)
                end
            end)
        end

        if effects then
            return worldPos, {}, worldPos
        end
    end
end

local function resolveBedWarsGameLibraries()
    local rbxtsInclude = ReplicatedStorage:FindFirstChild("rbxts_include")
    if rbxtsInclude then
        local gameCore = safeRequirePath(rbxtsInclude, {"node_modules", "@easy-games", "game-core", "out"})
        if type(gameCore) == "table" then
            bedwars.QueryUtil = bedwars.QueryUtil or gameCore.GameQueryUtil
            bedwars.RuntimeLib = bedwars.RuntimeLib or rbxtsInclude:FindFirstChild("RuntimeLib") and safeRequireModule(rbxtsInclude.RuntimeLib) or gameCore.RuntimeLib
            local clickHold = safeRequirePath(rbxtsInclude, {"node_modules", "@easy-games", "game-core", "out", "client", "ui", "lib", "util", "click-hold"})
            if type(clickHold) == "table" then
                bedwars.ClickHold = bedwars.ClickHold or clickHold.ClickHold
            end
            local roactModule = rbxtsInclude:FindFirstChild("node_modules")
            roactModule = roactModule and roactModule:FindFirstChild("@rbxts")
            roactModule = roactModule and roactModule:FindFirstChild("roact")
            roactModule = roactModule and roactModule:FindFirstChild("src")
            bedwars.Roact = bedwars.Roact or safeRequireModule(roactModule)
            bedwars.ClientDamageBlock = bedwars.ClientDamageBlock or safeRequirePath(rbxtsInclude, {
                "node_modules", "@easy-games", "block-engine", "out", "shared", "remotes",
            })
            if type(bedwars.ClientDamageBlock) == "table" and bedwars.ClientDamageBlock.BlockEngineRemotes then
                bedwars.ClientDamageBlock = bedwars.ClientDamageBlock.BlockEngineRemotes.Client
            end
        end
    end

    local tsFolder = ReplicatedStorage:FindFirstChild("TS")
    if tsFolder then
        bedwars.WinEffectMeta = bedwars.WinEffectMeta or safeRequirePath(tsFolder, {"locker", "win-effect", "win-effect-meta"})
        if type(bedwars.WinEffectMeta) == "table" and bedwars.WinEffectMeta.WinEffectMeta then
            bedwars.WinEffectMeta = bedwars.WinEffectMeta.WinEffectMeta
        end
        bedwars.KillEffectMeta = bedwars.KillEffectMeta or safeRequirePath(tsFolder, {"locker", "kill-effect", "kill-effect-meta"})
        if type(bedwars.KillEffectMeta) == "table" and bedwars.KillEffectMeta.KillEffectMeta then
            bedwars.KillEffectMeta = bedwars.KillEffectMeta.KillEffectMeta
        end
    end

    local playerScripts = lplr:FindFirstChild("PlayerScripts")
    local tsScripts = playerScripts and playerScripts:FindFirstChild("TS")
    if tsScripts then
        local queueCard = safeRequirePath(tsScripts, {"controllers", "global", "queue", "ui", "queue-card"})
        if type(queueCard) == "table" then
            bedwars.QueueCard = bedwars.QueueCard or queueCard.QueueCard
        end
    end

    if knit and type(knit.Controllers) == "table" then
        local damageController = knit.Controllers.DamageIndicatorController
        if damageController and type(damageController.spawnDamageIndicator) == "function" then
            bedwars.DamageIndicator = bedwars.DamageIndicator or damageController.spawnDamageIndicator
        end
        bedwars.KillEffectController = bedwars.KillEffectController or knit.Controllers.KillEffectController
        bedwars.KillFeedController = bedwars.KillFeedController or knit.Controllers.KillFeedController
        bedwars.GuidedProjectileController = bedwars.GuidedProjectileController or knit.Controllers.GuidedProjectileController
        bedwars.QueueController = bedwars.QueueController or knit.Controllers.QueueController
    end

    local flamework = rbxtsInclude and safeRequirePath(rbxtsInclude, {"node_modules", "@flamework", "core", "out"})
    if type(flamework) == "table" and type(flamework.Flamework.resolveDependency) == "function" then
        pcall(function()
            bedwars.KillFeedController = bedwars.KillFeedController or flamework.Flamework.resolveDependency(
                "client/controllers/game/kill-feed/kill-feed-controller@KillFeedController"
            )
        end)
    end
end

task.spawn(function()
    local deadline = os.clock() + 20
    repeat
        resolveBedWarsGameLibraries()
        task.wait(0.35)
    until os.clock() >= deadline or not Bad.Loaded

    local wiredEvents = {
        MatchEndEvent = "MatchEndEvent",
        EntityDeathEvent = "EntityDeathEvent",
    }
    for signalName, remoteName in pairs(wiredEvents) do
        local eventSignal = BadEvents[signalName]
        if eventSignal and realClient and type(realClient.WaitFor) == "function" then
            pcall(function()
                realClient:WaitFor(remoteName):andThen(function(connection)
                    if type(connection.Connect) == "function" and type(Bad.Clean) == "function" then
                        Bad:Clean(connection:Connect(function(...)
                            eventSignal:Fire(...)
                        end))
                    end
                end)
            end)
        end
    end
end)

-- V14 shared compatibility, runtime guards, and module health.
local compatibility = Bad.BedWarsCompatibility or {}
compatibility.Version = "19.0"
compatibility.Missing = bedwars.Missing
compatibility.Modules = compatibility.Modules or {}
compatibility.Notified = compatibility.Notified or {}
compatibility.ControllerAliases = compatibility.ControllerAliases or {
    BlockController = {"BlockController", "BlockBreakController", "BlockPlacementController"},
    SoundManager = {"SoundManager", "SoundController"},
    Store = {"Store", "StoreController"},
}

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

function compatibility:SafeGetUpvalue(func, index)
    if type(func) ~= "function" or not debug or type(debug.getupvalue) ~= "function" then
        return false, nil
    end
    return pcall(debug.getupvalue, func, index)
end

function compatibility:SafeGetConstant(func, index)
    if type(func) ~= "function" or not debug or type(debug.getconstant) ~= "function" then
        return false, nil
    end
    return pcall(debug.getconstant, func, index)
end

function compatibility:SafeSetConstant(func, index, value)
    if type(func) ~= "function" or not debug or type(debug.setconstant) ~= "function" then
        return false
    end
    return pcall(debug.setconstant, func, index, value)
end

function compatibility:SafeSetupValue(func, index, value)
    if type(func) ~= "function" or not debug or type(debug.setupvalue) ~= "function" then
        return false
    end
    return pcall(debug.setupvalue, func, index, value)
end

function compatibility:SafeGetConnections(signal)
    if type(getconnections) ~= "function" then
        return {}
    end
    local ok, connections = pcall(getconnections, signal)
    return ok and type(connections) == "table" and connections or {}
end

function compatibility:SafeGetConstants(func)
    if type(func) ~= "function" or not debug or type(debug.getconstants) ~= "function" then
        return {}
    end
    local ok, constants = pcall(debug.getconstants, func)
    return ok and type(constants) == "table" and constants or {}
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
        if current and not isControllerFallback(current) then
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
            and not isControllerFallback(rawget(bedwars, name))
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

function compatibility:GetStoreState()
    local redux = bedwars.Store
    if redux and not isControllerFallback(redux) and type(redux.getState) == "function" then
        local ok, state = pcall(redux.getState, redux)
        if ok and type(state) == "table" then
            return state
        end
    end
    return {}
end

function compatibility:FireRemote(remoteName, method, ...)
    method = method or "SendToServer"
    local remote = self:ResolveRemote(remoteName)
    if not remote or type(remote[method]) ~= "function" then
        return false
    end
    return pcall(remote[method], remote, ...)
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

-- Export common helpers for modules (prevents bare global errors in modules)
Bad.addBlur = addBlur
Bad.collectionService = collectionService
Bad.lplr = lplr
Bad.RunService = RunService
Bad.Players = Players
Bad.ReplicatedStorage = ReplicatedStorage
Bad.Workspace = Workspace
Bad.tweenService = tweenService
Bad.httpService = httpService

-- Provide common globals used by modules for compatibility
if type(getconnections) == "function" then
	Bad.getconnections = getconnections
end
_G.getconnections = _G.getconnections or getconnections
if not _G.lplr then _G.lplr = lplr end

Bad.BadEvents = Bad.BadEvents or BadEvents
Bad.remotes = Bad.remotes or remotes
Bad.getPlacedBlock = Bad.getPlacedBlock or getPlacedBlock
Bad.getNearGround = Bad.getNearGround or (function() return nil end)
Bad.roundPos = Bad.roundPos or (function(p) return p end)

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
