local Bad = shared.Bad or {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local store = (shared.Bad and shared.Bad.store) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local compat = Bad.BedWarsCompatibility or {}
local marketplaceService = game:GetService('MarketplaceService')
local groupService = game:GetService('GroupService')
local lplr = game:GetService('Players').LocalPlayer

local StaffDetector
local Mode
local Profile
local Users
local Group
local Role

local compatibility = Bad.BedWarsCompatibility

local function getRole(player, groupId)
    groupId = tonumber(groupId)
    if not groupId or groupId <= 0 then
        return 0
    end

    for _ = 1, 3 do
        local success, result = pcall(
            player.GetRankInGroup,
            player,
            groupId
        )
        if success then
            return tonumber(result) or 0
        end
        task.wait(0.15)
    end
    return 0
end

local function lowestStaffRole(roles)
    local lowest = math.huge
    for _, role in ipairs(roles or {}) do
        local name = string.lower(tostring(role.Name or ""))
        local rank = tonumber(role.Rank)
        if
            rank
            and (
                string.find(name, "admin", 1, true)
                or string.find(name, "mod", 1, true)
                or string.find(name, "dev", 1, true)
                or string.find(name, "staff", 1, true)
            )
            and rank < lowest
        then
            lowest = rank
        end
    end
    return lowest ~= math.huge and lowest or 255
end

local function isListed(player)
    local list = Users and Users.ListEnabled
    return type(list) == "table"
        and table.find(list, tostring(player.UserId)) ~= nil
end

local function notifyStaff(player, reason)
    Bad:CreateNotification(
        "Staff Detector",
        string.format(
            "%s detected (%s).",
            player.Name,
            reason
        ),
        12,
        "warning"
    )
end

local function playerAdded(player)
    if not Bad.Loaded then
        return
    end

    local listed = isListed(player)
    local requiredRole = tonumber(Role and Role.Value) or 1
    local groupId = tonumber(Group and Group.Value) or 0
    local ranked = groupId > 0
        and getRole(player, groupId) >= requiredRole

    if not listed and not ranked then
        return
    end

    local reason = listed and "listed user" or "staff role"
    notifyStaff(player, reason)

    if whitelist and whitelist.customtags then
        whitelist.customtags[player.Name] = {
            {
                text = "GAME STAFF",
                color = Color3.fromRGB(255, 78, 91),
            },
        }
    end

    local selectedMode = Mode and Mode.Value or "Notify"
    if selectedMode == "Uninject" then
        pcall(function()
            game:GetService("StarterGui"):SetCore(
                "SendNotification",
                {
                    Title = "Staff Detector",
                    Text = "Staff detected\n" .. player.Name,
                    Duration = 15,
                }
            )
        end)
        task.defer(function()
            if Bad and type(Bad.Uninject) == "function" then
                Bad:Uninject()
            end
        end)
    elseif selectedMode == "ServerHop" then
        if type(serverHop) == "function" then
            task.spawn(serverHop)
        end
    elseif selectedMode == "Profile" then
        if
            Bad
            and Profile
            and type(Bad.Load) == "function"
            and Bad.Profile ~= Profile.Value
        then
            Bad.Profile = Profile.Value
            Bad:Load(true, Profile.Value)
        end
    elseif selectedMode == "AutoConfig" then
        for _, module in pairs(Bad.Modules or {}) do
            if
                module ~= StaffDetector
                and module.Enabled
                and type(module.Toggle) == "function"
            then
                pcall(module.Toggle, module)
            end
        end
    end
end

local function automaticSetup()
    local groupValue = tonumber(Group.Value)
    local roleValue = tonumber(Role.Value)
    if groupValue and groupValue > 0 and roleValue then
        return true
    end

    local success, placeInfo = pcall(
        marketplaceService.GetProductInfo,
        marketplaceService,
        game.PlaceId
    )
    if not success or type(placeInfo) ~= "table" then
        return false
    end

    local creator = placeInfo.Creator or {}
    local groupId = creator.CreatorType == "Group"
        and tonumber(creator.CreatorTargetId)
        or nil

    if not groupId then
        return false
    end

    local infoSuccess, groupInfo = pcall(
        groupService.GetGroupInfoAsync,
        groupService,
        groupId
    )
    if not infoSuccess or type(groupInfo) ~= "table" then
        return false
    end

    Group:SetValue(groupId)
    Role:SetValue(lowestStaffRole(groupInfo.Roles))
    return true
end

StaffDetector = Bad.Categories.Utility:CreateModule({
    Name = "StaffDetector",
    Function = function(callback)
        if not callback then
            return
        end

        if not automaticSetup() then
            Bad:CreateNotification(
                "Staff Detector",
                "Automatic setup could not find a group.",
                6,
                "warning"
            )
            if StaffDetector.Enabled then
                StaffDetector:Toggle()
            end
            return
        end

        StaffDetector:Clean(
            playersService.PlayerAdded:Connect(playerAdded)
        )

        for _, player in ipairs(playersService:GetPlayers()) do
            task.spawn(playerAdded, player)
        end
    end,
    Tooltip = "Detects listed users and group staff.",
})

Mode = StaffDetector:CreateDropdown({
    Name = "Mode",
    List = {
        "Notify",
        "Uninject",
        "ServerHop",
        "Profile",
        "AutoConfig",
    },
    Function = function(value)
        if Profile.Object then
            Profile.Object.Visible = value == "Profile"
        end
    end,
})

Profile = StaffDetector:CreateTextBox({
    Name = "Profile",
    Default = "default",
    Darker = true,
    Visible = false,
})

Users = StaffDetector:CreateTextList({
    Name = "Users",
    Placeholder = "player userid",
})

Group = StaffDetector:CreateTextBox({
    Name = "Group",
    Placeholder = "Group ID",
})

Role = StaffDetector:CreateTextBox({
    Name = "Role",
    Placeholder = "Minimum rank",
})
