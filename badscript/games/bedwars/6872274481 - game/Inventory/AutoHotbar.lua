local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}
local BadEvents = Bad.BadEvents or {}

local AutoHotbar
local Mode
local Clear
local Order
local Active = false

local function normalizedOrder()
    local result = {}
    for _, value in ipairs(Order.ListEnabled or {}) do
        local item = tostring(value):match("^%s*(.-)%s*$")
        if item ~= "" then table.insert(result, item) end
    end
    return result
end

local function findInventoryItem(itemType)
    for _, item in ipairs(store.inventory.inventory.items or {}) do
        if item.itemType == itemType then return item end
    end
end

local function dispatch(action)
    local redux = bedwars.Store
    if not redux or type(redux.dispatch) ~= "function" then return false end
    local ok = pcall(redux.dispatch, redux, action)
    if ok and BadEvents.InventoryChanged and BadEvents.InventoryChanged.Event then
        task.wait(0.03)
    end
    return ok
end

local function sortHotbar()
    if Active or not AutoHotbar.Enabled then return end
    if not store.inventory or not store.inventory.hotbar then
        return Bad.BedWarsCompatibility.Unavailable(AutoHotbar, "Inventory state is unavailable in this BedWars build.")
    end
    if not Bad.BedWarsCompatibility.Has("Store") or not bedwars.Store or type(bedwars.Store.dispatch) ~= "function" then
        return Bad.BedWarsCompatibility.Unavailable(AutoHotbar, "Hotbar dispatch is unavailable in this BedWars build.")
    end

    Active = true
    local ok = pcall(function()
        for desiredSlot, itemType in ipairs(normalizedOrder()) do
            if desiredSlot > 9 then break end
            local item = findInventoryItem(itemType)
            if item then
                local current = store.inventory.hotbar[desiredSlot]
                if not current or not current.item or current.item.itemType ~= itemType then
                    for index, slot in ipairs(store.inventory.hotbar) do
                        if slot and slot.item and slot.item.itemType == itemType then
                            dispatch({type = "InventoryRemoveFromHotbar", slot = index - 1})
                            break
                        end
                    end
                    if current and current.item then
                        dispatch({type = "InventoryRemoveFromHotbar", slot = desiredSlot - 1})
                    end
                    dispatch({type = "InventoryAddToHotbar", item = item, slot = desiredSlot - 1})
                end
            end
        end

        if Clear.Enabled then
            local keep = {}
            for _, itemType in ipairs(normalizedOrder()) do keep[itemType] = true end
            for index, slot in ipairs(store.inventory.hotbar) do
                if slot and slot.item and not keep[slot.item.itemType] then
                    dispatch({type = "InventoryRemoveFromHotbar", slot = index - 1})
                end
            end
        end
    end)
    Active = false
    if not ok then
        Bad.BedWarsCompatibility.Unavailable(AutoHotbar, "The BedWars hotbar API changed.")
    end
end

AutoHotbar = Bad.Categories.Inventory:CreateModule({
    Name = "AutoHotbar",
    Function = function(callback)
        if callback then
            task.defer(sortHotbar)
            if Mode.Value == "On Key" then AutoHotbar:Toggle() return end
            local event = BadEvents.InventoryAmountChanged and BadEvents.InventoryAmountChanged.Event
            if event then AutoHotbar:Clean(event:Connect(sortHotbar)) end
        end
    end,
    Tooltip = "Arranges the hotbar using the item order below.",
})
Mode = AutoHotbar:CreateDropdown({Name = "Activation", List = {"Toggle", "On Key"}})
Clear = AutoHotbar:CreateToggle({Name = "Clear unlisted slots"})
Order = AutoHotbar:CreateTextList({
    Name = "Item order",
    Default = {"diamond_sword", "diamond_pickaxe", "diamond_axe", "shears", "wood_bow", "wool_white"},
    Function = function() if AutoHotbar.Enabled then task.defer(sortHotbar) end end,
})
