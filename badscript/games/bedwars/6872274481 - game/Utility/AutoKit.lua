local AutoKit
local Legit
local supported = {
    beekeeper = {tag = "bee", remote = "BeePickup", attribute = "BeeId", key = "beeId", range = 18},
    bigman = {tag = "treeOrb", remote = "ConsumeTreeOrb", attribute = "TreeOrbSecret", key = "treeOrbSecret", range = 12},
    metal_detector = {tag = "hidden-metal", remote = "PickupMetal", attribute = "Id", key = "id", range = 20},
}

local function runPickup(config)
    repeat
        if entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
            local origin = entitylib.character.RootPart.Position
            for _, object in ipairs(collectionService:GetTagged(config.tag)) do
                local part = object:IsA("BasePart") and object or object.PrimaryPart
                if part and (part.Position - origin).Magnitude <= config.range then
                    local payload = {[config.key] = object:GetAttribute(config.attribute)}
                    pcall(function() bedwars.Client:Get(remotes[config.remote]):SendToServer(payload) end)
                end
            end
        end
        task.wait(Legit.Enabled and 0.22 or 0.1)
    until not AutoKit.Enabled
end

AutoKit = Bad.Categories.Utility:CreateModule({
    Name = "AutoKit",
    Function = function(callback)
        if not callback then return end
        local kit = tostring(store.equippedKit or "")
        local config = supported[kit]
        if not bedwars.RawClient then
            return Bad.BedWarsCompatibility.Unavailable(AutoKit, "BedWars remotes are unavailable in this build.")
        end
        if not config then
            return Bad.BedWarsCompatibility.Unavailable(AutoKit, "This kit does not have a verified V10 automation yet.")
        end
        runPickup(config)
    end,
    Tooltip = "Uses verified kit interactions without outdated controller hooks.",
})
Legit = AutoKit:CreateToggle({Name = "Human timing", Default = true})
