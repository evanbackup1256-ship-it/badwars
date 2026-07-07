local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}

local BedBreakEffect
local List
local NameToId = {}

local function buildEffects()
    local names = {}
    for id, meta in pairs(bedwars.BedBreakEffectMeta or {}) do
        if type(meta) == "table" and type(meta.name) == "string" then
            NameToId[meta.name] = id
            table.insert(names, meta.name)
        end
    end
    table.sort(names)
    if #names == 0 then table.insert(names, "Default") NameToId.Default = "default" end
    return names
end

BedBreakEffect = Bad.Legit:CreateModule({
    Name = "Bed Break Effect",
    Function = function(callback)
        if not callback then return end
        local event = BadEvents and BadEvents.BedwarsBedBreak and BadEvents.BedwarsBedBreak.Event
        if not event or not bedwars.RawClient then
            return Bad.BedWarsCompatibility.Unavailable(BedBreakEffect, "Bed break events are not available in this BedWars build.")
        end
        local remote = bedwars.Client:Get("BedBreakEffectTriggered")
        local onClient = remote and remote.instance and remote.instance.OnClientEvent
        if remote == nullRemote or not onClient or type(firesignal) ~= "function" then
            return Bad.BedWarsCompatibility.Unavailable(BedBreakEffect, "The bed break effect remote changed in this BedWars update.")
        end
        BedBreakEffect:Clean(event:Connect(function(data)
            if type(data) ~= "table" then return end
            pcall(function()
                firesignal(onClient, {
                    player = data.player,
                    position = data.bedBlockPosition and data.bedBlockPosition * 3 or Vector3.zero,
                    effectType = NameToId[List.Value],
                    teamId = data.brokenBedTeam and data.brokenBedTeam.id,
                    centerBedPosition = data.bedBlockPosition and data.bedBlockPosition * 3 or Vector3.zero,
                })
            end)
        end))
    end,
    Tooltip = "Changes the effect shown when a bed is destroyed.",
})

List = BedBreakEffect:CreateDropdown({Name = "Effect", List = buildEffects()})
