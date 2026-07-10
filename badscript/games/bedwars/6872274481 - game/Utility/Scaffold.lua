local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}

local Scaffold
local Expand
local Tower
local Downwards
local Diagonal
local LimitItem
local Mouse
local Count
local label
local lastPosition = Vector3.zero

local compatibility = Bad.BedWarsCompatibility

local adjacent = {}
for x = -3, 3, 3 do
    for y = -3, 3, 3 do
        for z = -3, 3, 3 do
            local offset = Vector3.new(x, y, z)
            if offset ~= Vector3.zero then
                table.insert(adjacent, offset)
            end
        end
    end
end

local function currentItems()
    if compatibility and type(compatibility.InventoryItems) == "function" then
        return compatibility:InventoryItems()
    end
    local inventory = store
        and store.inventory
        and store.inventory.inventory
    return inventory and inventory.items or {}
end

local function getScaffoldBlock()
    local hand = store and store.hand
    if
        hand
        and hand.toolType == "block"
        and hand.tool
    then
        return hand.tool.Name, tonumber(hand.amount) or 0
    end

    if LimitItem and LimitItem.Enabled then
        return nil, 0
    end

    local wool, woolAmount
    if type(getWool) == "function" then
        local ok, itemType = pcall(getWool)
        if ok and itemType then
            wool = itemType
            woolAmount = 0
        end
    end
    if wool then
        return wool, tonumber(woolAmount) or 0
    end

    for _, item in ipairs(currentItems()) do
        local meta = bedwars.ItemMeta
            and bedwars.ItemMeta[item.itemType]
        if meta and meta.block then
            return item.itemType, tonumber(item.amount) or 0
        end
    end

    return nil, 0
end

local function placed(position)
    if type(getPlacedBlock) ~= "function" then
        return nil, position / 3
    end
    local ok, block, blockPosition = pcall(getPlacedBlock, position)
    if ok then
        return block, blockPosition or position / 3
    end
    return nil, position / 3
end

local function checkAdjacent(position)
    for _, offset in ipairs(adjacent) do
        local block = placed(position + offset)
        if block then
            return true
        end
    end
    return false
end

local function nearCorner(blockPosition, position)
    local startPosition = blockPosition - Vector3.new(3, 3, 3)
    local endPosition = blockPosition + Vector3.new(3, 3, 3)
    local delta = position - blockPosition
    if delta.Magnitude <= 0.001 then
        return blockPosition
    end
    local check = blockPosition + delta.Unit * 100
    return Vector3.new(
        math.clamp(check.X, startPosition.X, endPosition.X),
        math.clamp(check.Y, startPosition.Y, endPosition.Y),
        math.clamp(check.Z, startPosition.Z, endPosition.Z)
    )
end

local function blockProximity(position)
    if
        type(getBlocksInPoints) ~= "function"
        or not bedwars.BlockController
        or type(bedwars.BlockController.getBlockPosition) ~= "function"
    then
        return nil
    end

    local ok, blocks = pcall(
        getBlocksInPoints,
        bedwars.BlockController:getBlockPosition(
            position - Vector3.new(21, 21, 21)
        ),
        bedwars.BlockController:getBlockPosition(
            position + Vector3.new(21, 21, 21)
        )
    )
    if not ok or type(blocks) ~= "table" then
        return nil
    end

    local closestDistance = 60
    local closest
    for _, blockPosition in ipairs(blocks) do
        local corner = nearCorner(blockPosition, position)
        local distance = (position - corner).Magnitude
        if distance < closestDistance then
            closestDistance = distance
            closest = corner
        end
    end
    table.clear(blocks)
    return closest
end

local function updateCounter(amount)
    if not label then
        return
    end
    amount = math.max(tonumber(amount) or 0, 0)
    label.Text = tostring(amount) .. "  BLOCKS"
    label.TextColor3 = Color3.fromHSV(
        math.clamp((amount / 128) / 2.8, 0, 0.44),
        0.78,
        1
    )
end

local function placeAt(position, itemType)
    if type(bedwars.placeBlock) ~= "function" then
        return false
    end
    local ok = pcall(bedwars.placeBlock, position, itemType, false)
    return ok
end

Scaffold = Bad.Categories.Utility:CreateModule({
    Name = "Scaffold",
    Function = function(callback)
        if label then
            label.Visible = callback
        end

        if not callback then
            lastPosition = Vector3.zero
            return
        end

        if
            not entitylib
            or type(bedwars.placeBlock) ~= "function"
            or not bedwars.BlockController
        then
            if compatibility then
                compatibility:Unavailable(
                    Scaffold,
                    "Block placement is unavailable in this BedWars build."
                )
            end
            return
        end

        repeat
            local ok, failure = xpcall(function()
                if
                    not entitylib.isAlive
                    or not entitylib.character
                    or not entitylib.character.RootPart
                    or not entitylib.character.Humanoid
                then
                    return
                end

                local itemType, amount = getScaffoldBlock()
                updateCounter(amount)

                if
                    Mouse.Enabled
                    and not inputService:IsMouseButtonPressed(0)
                then
                    itemType = nil
                end
                if not itemType then
                    return
                end

                local root = entitylib.character.RootPart
                local humanoid = entitylib.character.Humanoid

                if
                    Tower.Enabled
                    and inputService:IsKeyDown(Enum.KeyCode.Space)
                    and not inputService:GetFocusedTextBox()
                then
                    local velocity = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity =
                        Vector3.new(velocity.X, 38, velocity.Z)
                end

                for distance = Expand.Value, 1, -1 do
                    local downward =
                        Downwards.Enabled
                        and inputService:IsKeyDown(
                            Enum.KeyCode.LeftShift
                        )

                    local currentPosition = roundPos(
                        root.Position
                            - Vector3.new(
                                0,
                                humanoid.HipHeight
                                    + (downward and 4.5 or 1.5),
                                0
                            )
                            + humanoid.MoveDirection
                                * (distance * 3)
                    )

                    if
                        Diagonal.Enabled
                        and lastPosition ~= Vector3.zero
                    then
                        local angle = math.abs(
                            math.round(
                                math.deg(
                                    math.atan2(
                                        -humanoid.MoveDirection.X,
                                        -humanoid.MoveDirection.Z
                                    )
                                ) / 45
                            ) * 45
                        )
                        local delta = lastPosition - currentPosition
                        if
                            angle % 90 == 45
                            and (
                                (delta.X == 0 and delta.Z ~= 0)
                                or (
                                    delta.X ~= 0
                                    and delta.Z == 0
                                )
                            )
                            and (
                                (lastPosition - root.Position)
                                * Vector3.new(1, 0, 1)
                            ).Magnitude < 2.5
                        then
                            currentPosition = lastPosition
                        end
                    end

                    local block, blockPosition = placed(currentPosition)
                    if not block then
                        local worldPosition = blockPosition * 3
                        worldPosition =
                            checkAdjacent(worldPosition)
                                and worldPosition
                                or blockProximity(currentPosition)
                        if worldPosition then
                            task.spawn(placeAt, worldPosition, itemType)
                        end
                    end

                    lastPosition = currentPosition
                end
            end, debug.traceback)

            if not ok then
                if compatibility then
                    compatibility:RecordFailure(
                        Scaffold,
                        Scaffold.SourcePath,
                        failure
                    )
                end
                break
            end

            task.wait(0.03)
        until not Scaffold.Enabled
    end,
    Tooltip = "Places blocks beneath and ahead of you.",
})

Expand = Scaffold:CreateSlider({
    Name = "Expand",
    Min = 1,
    Max = 6,
    Default = 1,
})
Tower = Scaffold:CreateToggle({
    Name = "Tower",
    Default = true,
})
Downwards = Scaffold:CreateToggle({
    Name = "Downwards",
    Default = true,
})
Diagonal = Scaffold:CreateToggle({
    Name = "Diagonal",
    Default = true,
})
LimitItem = Scaffold:CreateToggle({
    Name = "Limit to held block",
})
Mouse = Scaffold:CreateToggle({
    Name = "Require mouse down",
})
Count = Scaffold:CreateToggle({
    Name = "Block counter",
    Function = function(callback)
        if callback then
            if label then
                label:Destroy()
            end

            label = Instance.new("TextLabel")
            label.Name = "ScaffoldCounter"
            label.Size = UDim2.fromOffset(124, 26)
            label.Position = UDim2.new(0.5, 0, 0.5, 66)
            label.AnchorPoint = Vector2.new(0.5, 0)
            label.BackgroundColor3 = Color3.fromRGB(8, 12, 18)
            label.BackgroundTransparency = 0.16
            label.BorderSizePixel = 0
            label.Text = "0  BLOCKS"
            label.TextColor3 = Color3.fromRGB(46, 220, 170)
            label.TextSize = 13
            label.Font = Enum.Font.GothamSemibold
            label.Visible = Scaffold.Enabled
            label.Parent = Bad.gui

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 8)
            corner.Parent = label

            local stroke = Instance.new("UIStroke")
            stroke.Color = Color3.fromRGB(54, 78, 101)
            stroke.Transparency = 0.5
            stroke.Thickness = 1
            stroke.Parent = label
        else
            if label then
                label:Destroy()
                label = nil
            end
        end
    end,
})
