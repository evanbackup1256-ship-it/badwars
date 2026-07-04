local ShopTierBypass
local originalTiered = setmetatable({}, {__mode = "k"})
local originalNextTier = setmetatable({}, {__mode = "k"})
local compatibility = Bad.BedWarsCompatibility

local function shopItems()
    local shop = bedwars.Shop
    if type(shop) ~= "table" then
        return {}
    end
    if type(shop.ShopItems) == "table" then
        return shop.ShopItems
    end
    if type(shop.items) == "table" then
        return shop.items
    end
    return {}
end

local function restore()
    for item, value in pairs(originalTiered) do
        if type(item) == "table" then
            item.tiered = value
        end
    end
    for item, value in pairs(originalNextTier) do
        if type(item) == "table" then
            item.nextTier = value
        end
    end
    table.clear(originalTiered)
    table.clear(originalNextTier)
end

ShopTierBypass = Bad.Categories.Utility:CreateModule({
    Name = "ShopTierBypass",
    Function = function(callback)
        if not callback then
            restore()
            return
        end

        local ready = false
        if compatibility and type(compatibility.WaitFor) == "function" then
            ready = compatibility:WaitFor(function()
                return store.shopLoaded or #shopItems() > 0
            end, 8, 0.15)
        else
            local deadline = os.clock() + 8
            repeat
                ready = store.shopLoaded or #shopItems() > 0
                if ready then
                    break
                end
                task.wait(0.15)
            until os.clock() >= deadline or not ShopTierBypass.Enabled
        end

        if not ShopTierBypass.Enabled then
            return
        end

        local items = shopItems()
        if not ready or #items == 0 then
            if compatibility then
                compatibility:Unavailable(
                    ShopTierBypass,
                    "Shop metadata is unavailable in this BedWars build."
                )
            end
            return
        end

        for _, item in ipairs(items) do
            if type(item) == "table" then
                originalTiered[item] = item.tiered
                originalNextTier[item] = item.nextTier
                item.tiered = nil
                item.nextTier = nil
            end
        end
    end,
    Tooltip = "Removes local shop tier restrictions when metadata is available.",
})
