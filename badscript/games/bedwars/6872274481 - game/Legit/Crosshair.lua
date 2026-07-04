local Crosshair
local Image
local originals = {}
local connections = {}

local function imageId()
    local value = tostring(Image and Image.Value or "")
    if value == "" then return "" end
    if value:find("rbxassetid://", 1, true) then return value end
    local number = value:match("%d+")
    return number and ("rbxassetid://" .. number) or value
end

local function isCrosshair(object)
    if not object:IsA("ImageLabel") and not object:IsA("ImageButton") then return false end
    local name = string.lower(object.Name)
    return name:find("crosshair", 1, true) ~= nil or name:find("reticle", 1, true) ~= nil
end

local function apply(object)
    if not isCrosshair(object) then return false end
    if originals[object] == nil then originals[object] = object.Image end
    object.Image = imageId()
    return true
end

local function refresh()
    local found = 0
    local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, object in ipairs(playerGui:GetDescendants()) do
            if apply(object) then found += 1 end
        end
    end
    local camera = workspace.CurrentCamera
    if camera then
        for _, object in ipairs(camera:GetDescendants()) do
            if apply(object) then found += 1 end
        end
    end
    return found
end

Crosshair = Bad.Legit:CreateModule({
    Name = "Crosshair",
    Function = function(callback)
        if callback then
            local found = refresh()
            local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if playerGui then
                table.insert(connections, playerGui.DescendantAdded:Connect(function(object) task.defer(apply, object) end))
            end
            if found == 0 and Bad.BedWarsCompatibility then
                Bad.BedWarsCompatibility.Unavailable(Crosshair, "The current BedWars crosshair UI was not found.")
            end
        else
            for _, connection in ipairs(connections) do pcall(function() connection:Disconnect() end) end
            table.clear(connections)
            for object, oldImage in pairs(originals) do
                if object.Parent then pcall(function() object.Image = oldImage end) end
            end
            table.clear(originals)
        end
    end,
    Tooltip = "Changes the first-person crosshair image.",
})

Image = Crosshair:CreateTextBox({
    Name = "Image",
    Placeholder = "Roblox image ID",
    Function = function(enter)
        if enter and Crosshair.Enabled then refresh() end
    end,
})
