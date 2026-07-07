local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}

local AutoShoot
local old
local shooting = false

local function getCrossbows()
    local result = {}
    for index, slot in ipairs(store.inventory.hotbar or {}) do
        local item = slot and slot.item
        if item and tostring(item.itemType):find("crossbow") and index ~= ((store.inventory.hotbarSlot or 0) + 1) then
            table.insert(result, index - 1)
        end
    end
    return result
end

AutoShoot = Bad.Categories.Utility:CreateModule({
    Name = "AutoShoot",
    Function = function(callback)
        local controller = bedwars.ProjectileController
        if callback then
            if not Bad.BedWarsCompatibility.Has("ProjectileController") or type(controller.createLocalProjectile) ~= "function" then
                return Bad.BedWarsCompatibility.Unavailable(AutoShoot, "Projectile controller is unavailable in this BedWars build.")
            end
            old = controller.createLocalProjectile
            controller.createLocalProjectile = function(...)
                local arguments = {...}
                local source, _, projectile = arguments[1], arguments[2], arguments[3]
                if source and (projectile == "arrow" or projectile == "fireball") and not shooting then
                    task.spawn(function()
                        local bows = getCrossbows()
                        if #bows == 0 then return end
                        shooting = true
                        task.wait(0.15)
                        local selected = store.inventory.hotbarSlot or 0
                        for _, slot in ipairs(bows) do
                            if hotbarSwitch(slot) then
                                task.wait(0.05)
                                pcall(mouse1click)
                                task.wait(0.05)
                            end
                        end
                        hotbarSwitch(selected)
                        shooting = false
                    end)
                end
                return old(...)
            end
        elseif old and controller then
            controller.createLocalProjectile = old
            old = nil
            shooting = false
        end
    end,
    Tooltip = "Cycles available crossbows after firing.",
})
