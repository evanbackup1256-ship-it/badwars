local KitESP
local Background
local Color = {}
local Reference = {}
local Folder = Instance.new('Folder')
Folder.Parent = Bad.gui
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local collectionService = game:GetService('CollectionService')
local addBlur = (shared.Bad and shared.Bad.addBlur) or function() return Instance.new('Frame') end

local ESPKits = {
	alchemist = {'alchemist_ingedients', 'wild_flower'},
	beekeeper = {'bee', 'bee'},
	bigman = {'treeOrb', 'natures_essence_1'},
	ghost_catcher = {'ghost', 'ghost_orb'},
	metal_detector = {'hidden-metal', 'iron'},
	sheep_herder = {'SheepModel', 'purple_hay_bale'},
	sorcerer = {'alchemy_crystal', 'wild_flower'},
	star_collector = {'stars', 'crit_star'}
}

local function Added(v, icon)
	if not v then return end
	local billboard = Instance.new('BillboardGui')
	billboard.Parent = Folder
	billboard.Name = icon
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	billboard.Size = UDim2.fromOffset(36, 36)
	billboard.AlwaysOnTop = true
	billboard.ClipsDescendants = false
	billboard.Adornee = v
	local blur = addBlur(billboard)
	blur.Visible = Background and Background.Enabled
	local image = Instance.new('ImageLabel')
	image.Size = UDim2.fromOffset(36, 36)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.BackgroundColor3 = Color3.fromHSV(Color.Hue or 0.44, Color.Sat or 1, Color.Value or 1)
	image.BackgroundTransparency = 1 - ((Background and Background.Enabled and Color.Opacity) or 0)
	image.BorderSizePixel = 0
	if bedwars.getIcon then
		pcall(function() image.Image = bedwars.getIcon({itemType = icon}, true) end)
	end
	image.Parent = billboard
	local uicorner = Instance.new('UICorner')
	uicorner.CornerRadius = UDim.new(0, 4)
	uicorner.Parent = image
	Reference[v] = billboard
end

local function addKit(tag, icon)
	KitESP:Clean(collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
		if v and v.PrimaryPart then
			Added(v.PrimaryPart, icon)
		end
	end))
	KitESP:Clean(collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
		if v and v.PrimaryPart and Reference[v.PrimaryPart] then
			Reference[v.PrimaryPart]:Destroy()
			Reference[v.PrimaryPart] = nil
		end
	end))
	for _, v in collectionService:GetTagged(tag) do
		if v and v.PrimaryPart then
			Added(v.PrimaryPart, icon)
		end
	end
end

KitESP = Bad.Categories.Render:CreateModule({
	Name = 'KitESP',
	Function = function(callback)
		if callback then
			local store = (shared.Bad and shared.Bad.store) or {}
			repeat task.wait() until (store.equippedKit ~= '') or (not KitESP.Enabled)
			local kit = KitESP.Enabled and ESPKits[store.equippedKit] or nil
			if kit then
				addKit(kit[1], kit[2])
			end
		else
			Folder:ClearAllChildren()
			table.clear(Reference)
		end
	end,
	Tooltip = 'ESP for certain kit related objects'
})
Background = KitESP:CreateToggle({
	Name = 'Background',
	Function = function(callback)
		if Color.Object then Color.Object.Visible = callback end
		for _, v in Reference do
			if v:FindFirstChild('ImageLabel') then
				v.ImageLabel.BackgroundTransparency = 1 - (callback and (Color.Opacity or 0.5) or 0)
			end
			if v:FindFirstChild('Blur') then
				v.Blur.Visible = callback
			end
		end
	end,
	Default = true
})
Color = KitESP:CreateColorSlider({
	Name = 'Background Color',
	DefaultValue = 0,
	DefaultOpacity = 0.5,
	Function = function(hue, sat, val, opacity)
		for _, v in Reference do
			if v:FindFirstChild('ImageLabel') then
				v.ImageLabel.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.ImageLabel.BackgroundTransparency = 1 - opacity
			end
		end
	end,
	Darker = true
})





