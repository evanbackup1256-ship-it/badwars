local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}
local collectionService = Bad.collectionService or game:GetService("CollectionService")
local BadEvents = Bad.BadEvents or {}
local getPlacedBlock = bedwars.getPlacedBlock or function() return nil end

local sides = {
    Vector3.new(1, 0, 0),
    Vector3.new(-1, 0, 0),
    Vector3.new(0, 0, 1),
    Vector3.new(0, 0, -1),
}

local BedPlates
local Background
local Color
local Folder = Instance.new("Folder")
Folder.Name = "BadWarsBedPlates"
Folder.Parent = Bad.gui
local references = {}

local function itemHealth(name)
    local meta = bedwars.ItemMeta and bedwars.ItemMeta[name]
    return meta and meta.block and tonumber(meta.block.health) or 0
end

local function icon(name)
    if type(bedwars.getIcon) == "function" then
        local ok, result = pcall(bedwars.getIcon, {itemType = name}, true)
        if ok then return result end
    end
    local meta = bedwars.ItemMeta and bedwars.ItemMeta[name]
    return meta and meta.image or ""
end

local function scanSide(bed, start, output)
    for _, side in ipairs(sides) do
        for distance = 1, 15 do
            local block = getPlacedBlock(start + (side * distance))
            if not block or block == bed then break end
            if not block:GetAttribute("NoBreak") and not table.find(output, block.Name) then
                table.insert(output, block.Name)
            end
        end
    end
end

local function refresh(gui)
    if not gui or not gui.Adornee or not gui:FindFirstChild("Frame") then return end
    for _, object in ipairs(gui.Frame:GetChildren()) do
        if object:IsA("ImageLabel") then object:Destroy() end
    end
    local blocks = {}
    scanSide(gui.Adornee, gui.Adornee.Position, blocks)
    scanSide(gui.Adornee, gui.Adornee.Position + Vector3.new(0, 0, 3), blocks)
    table.sort(blocks, function(a, b) return itemHealth(a) > itemHealth(b) end)
    gui.Enabled = #blocks > 0
    for _, blockName in ipairs(blocks) do
        local image = Instance.new("ImageLabel")
        image.Size = UDim2.fromOffset(30, 30)
        image.BackgroundTransparency = 1
        image.Image = icon(blockName)
        image.Parent = gui.Frame
    end
end

local function added(bed)
    if references[bed] then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "BedPlates"
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
    billboard.Size = UDim2.fromOffset(36, 36)
    billboard.AlwaysOnTop = true
    billboard.Adornee = bed
    billboard.Parent = Folder
    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.fromScale(1, 1)
    frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
    frame.BackgroundTransparency = Background.Enabled and (1 - Color.Opacity) or 1
    frame.Parent = billboard
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 7)
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 4)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Parent = frame
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 8, 36), 36)
    end)
    references[bed] = billboard
    refresh(billboard)
end

local function refreshNear(data)
    local position = data and data.blockRef and data.blockRef.blockPosition
    if not position then return end
    position *= 3
    for bed, gui in pairs(references) do
        if bed.Parent and (position - bed.Position).Magnitude <= 30 then refresh(gui) end
    end
end

BedPlates = Bad.Categories.Minigames:CreateModule({
    Name = "BedPlates",
    Function = function(callback)
        if callback then
            for _, bed in ipairs(collectionService:GetTagged("bed")) do task.defer(added, bed) end
            BedPlates:Clean(collectionService:GetInstanceAddedSignal("bed"):Connect(added))
            BedPlates:Clean(collectionService:GetInstanceRemovedSignal("bed"):Connect(function(bed)
                if references[bed] then references[bed]:Destroy() references[bed] = nil end
            end))
            if BadEvents.PlaceBlockEvent and BadEvents.PlaceBlockEvent.Event then BedPlates:Clean(BadEvents.PlaceBlockEvent.Event:Connect(refreshNear)) end
            if BadEvents.BreakBlockEvent and BadEvents.BreakBlockEvent.Event then BedPlates:Clean(BadEvents.BreakBlockEvent.Event:Connect(refreshNear)) end
        else
            table.clear(references)
            Folder:ClearAllChildren()
        end
    end,
    Tooltip = "Shows the protective blocks surrounding beds.",
})
Background = BedPlates:CreateToggle({Name = "Background", Default = true})
Color = BedPlates:CreateColorSlider({Name = "Background color", DefaultValue = 0.45, DefaultOpacity = 0.5})
