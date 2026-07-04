local StaffDetector
local Mode
local Profile
local Users
local Group
local Role

local detectedPlayers = {}

local function isBlank(value)
	return value == nil or tostring(value):match("^%s*$") ~= nil
end

local function safeNotify(title, message, duration, icon)
	if type(notif) == "function" then
		pcall(notif, title, message, duration or 8, icon)
	end
end

local function getRole(player, groupId)
	groupId = tonumber(groupId)
	if not player or not groupId or groupId <= 0 then
		return 0
	end

	for _ = 1, 3 do
		local success, rank = pcall(function()
			return player:GetRankInGroup(groupId)
		end)

		if success then
			return tonumber(rank) or 0
		end

		task.wait(0.15)
	end

	return 0
end

local function getLowestStaffRole(roles)
	local lowestRank

	for _, roleInfo in ipairs(roles or {}) do
		local name = tostring(roleInfo.Name or ""):lower()
		local rank = tonumber(roleInfo.Rank)

		local looksLikeStaff = name:find("admin", 1, true)
			or name:find("mod", 1, true)
			or name:find("dev", 1, true)
			or name:find("staff", 1, true)

		if looksLikeStaff and rank and (not lowestRank or rank < lowestRank) then
			lowestRank = rank
		end
	end

	return lowestRank
end

local function addStaffTag(player)
	if type(whitelist) ~= "table" then
		return
	end

	whitelist.customtags = type(whitelist.customtags) == "table" and whitelist.customtags or {}
	whitelist.customtags[player.Name] = {
		{
			text = "GAME STAFF",
			color = Color3.new(1, 0, 0),
		},
	}
end

local function runDetectionMode(player)
	local selectedMode = Mode and Mode.Value or "Notify"

	if selectedMode == "Uninject" then
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", {
				Title = "StaffDetector",
				Text = "Staff Detected\n" .. player.Name,
				Duration = 60,
			})
		end)

		task.spawn(function()
			if Bad and type(Bad.Uninject) == "function" then
				Bad:Uninject()
			end
		end)
	elseif selectedMode == "ServerHop" then
		if type(serverHop) == "function" then
			task.spawn(serverHop)
		else
			safeNotify("StaffDetector", "ServerHop is unavailable.", 8, "warning")
		end
	elseif selectedMode == "Profile" then
		local profileName = Profile and tostring(Profile.Value or "") or ""

		if isBlank(profileName) then
			safeNotify("StaffDetector", "No profile was selected.", 8, "warning")
			return
		end

		if Bad then
			Bad.Save = function() end

			if Bad.Profile ~= profileName and type(Bad.Load) == "function" then
				Bad.Profile = profileName
				Bad:Load(true, profileName)
			end
		end
	elseif selectedMode == "AutoConfig" then
		if Bad then
			Bad.Save = function() end

			for _, module in pairs(Bad.Modules or {}) do
				if type(module) == "table" and module.Enabled and type(module.Toggle) == "function" then
					pcall(function()
						module:Toggle()
					end)
				end
			end
		end
	end
end

local function playerAdded(player)
	while not Bad or not Bad.Loaded do
		task.wait()
	end

	if not player or detectedPlayers[player.UserId] then
		return
	end

	local userId = tostring(player.UserId)
	local manuallyListed = Users
		and type(Users.ListEnabled) == "table"
		and table.find(Users.ListEnabled, userId) ~= nil

	local groupId = tonumber(Group and Group.Value)
	local minimumRank = tonumber(Role and Role.Value)
	local staffByRank = groupId
		and groupId > 0
		and minimumRank
		and minimumRank > 0
		and getRole(player, groupId) >= minimumRank

	if not manuallyListed and not staffByRank then
		return
	end

	detectedPlayers[player.UserId] = true

	local reason = manuallyListed and "blacklisted_user" or "staff_role"
	safeNotify(
		"StaffDetector",
		"Staff Detected (" .. reason .. "): " .. player.Name,
		60,
		"alert"
	)

	addStaffTag(player)
	runDetectionMode(player)
end

local function findGroupIdFromPlace()
	local success, placeInfo = pcall(function()
		return marketplaceService:GetProductInfo(game.PlaceId)
	end)

	if not success or type(placeInfo) ~= "table" then
		return nil, "Unable to retrieve place information."
	end

	local creator = placeInfo.Creator
	if type(creator) == "table" and creator.CreatorType == "Group" then
		return tonumber(creator.CreatorTargetId)
	end

	local description = tostring(placeInfo.Description or "")
	local groupId = description:match("roblox%.com/groups/(%d+)")

	if groupId then
		return tonumber(groupId)
	end

	return nil, "No Roblox group was found for this experience."
end

local function configureGroupAndRole()
	local groupId = tonumber(Group and Group.Value)

	if not groupId or groupId <= 0 then
		local errorMessage
		groupId, errorMessage = findGroupIdFromPlace()

		if not groupId then
			safeNotify(
				"StaffDetector",
				"Automatic Setup Failed (" .. tostring(errorMessage) .. ")",
				60,
				"warning"
			)
			return false
		end
	end

	local success, groupInfo = pcall(function()
		return groupService:GetGroupInfoAsync(groupId)
	end)

	if not success or type(groupInfo) ~= "table" then
		safeNotify(
			"StaffDetector",
			"Automatic Setup Failed (unable to load group roles)",
			60,
			"warning"
		)
		return false
	end

	local lowestStaffRank = getLowestStaffRole(groupInfo.Roles)
	if not lowestStaffRank then
		safeNotify(
			"StaffDetector",
			"Automatic Setup Failed (no staff role detected)",
			60,
			"warning"
		)
		return false
	end

	Group:SetValue(tostring(groupId))
	Role:SetValue(tostring(lowestStaffRank))
	return true
end

StaffDetector = Bad.Categories.Utility:CreateModule({
	Name = "StaffDetector",
	Function = function(callback)
		if not callback then
			return
		end

		detectedPlayers = {}

		if isBlank(Group and Group.Value) or isBlank(Role and Role.Value) then
			if not configureGroupAndRole() then
				return
			end
		end

		if isBlank(Group and Group.Value) or isBlank(Role and Role.Value) then
			safeNotify(
				"StaffDetector",
				"Group ID and role rank are required.",
				8,
				"warning"
			)
			return
		end

		StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))

		for _, player in ipairs(playersService:GetPlayers()) do
			task.spawn(playerAdded, player)
		end
	end,
	Tooltip = "Detects players with a configured staff rank in-game.",
})

Mode = StaffDetector:CreateDropdown({
	Name = "Mode",
	List = {
		"Uninject",
		"ServerHop",
		"Profile",
		"AutoConfig",
		"Notify",
	},
	Function = function(value)
		if Profile and Profile.Object then
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
	Placeholder = "player (userid)",
})

Group = StaffDetector:CreateTextBox({
	Name = "Group",
	Placeholder = "Group ID",
})

Role = StaffDetector:CreateTextBox({
	Name = "Role",
	Placeholder = "Role rank",
})
