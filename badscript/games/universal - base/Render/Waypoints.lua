local Waypoints
local FontOption
local List
local Color = {Hue = 0.44, Sat = 1, Value = 1, Opacity = 0.5}
local Scale
local Background
local WaypointFolder = Instance.new('Folder')
WaypointFolder.Parent = Bad.gui

Waypoints = Bad.Categories.Render:CreateModule({
	Name = 'Waypoints',
	Function = function(callback)
		if callback then
			for _, v in List and List.ListEnabled or {} do
				local split = v:split('/')
				local tagSize = getfontsize and getfontsize(removeTags(split[2]), 14 * (Scale and Scale.Value or 1), FontOption and FontOption.Value or Enum.Font.Arial, Vector2.new(100000, 100000)) or Vector2.new(100, 20)
				local billboard = Instance.new('BillboardGui')
				billboard.Size = UDim2.fromOffset(tagSize.X + 8, tagSize.Y + 7)
				billboard.StudsOffsetWorldSpace = Vector3.new(unpack(split[1]:split(',')))
				billboard.AlwaysOnTop = true
				billboard.Parent = WaypointFolder
				local tag = Instance.new('TextLabel')
				tag.BackgroundColor3 = Color3.new()
				tag.BorderSizePixel = 0
				tag.Visible = true
				tag.RichText = true
				tag.FontFace = FontOption and FontOption.Value or Enum.Font.Arial
				tag.TextSize = 14 * (Scale and Scale.Value or 1)
				tag.BackgroundTransparency = Background and Background.Value or 0.5
				tag.Size = billboard.Size
				tag.Text = split[2]
				tag.TextColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
				tag.Parent = billboard
			end
		else
			WaypointFolder:ClearAllChildren()
		end
	end,
	Tooltip = 'Mark certain spots with a visual indicator'
})
FontOption = Waypoints:CreateFont({
	Name = 'Font',
	Blacklist = 'Arial',
	Function = function()
		if Waypoints.Enabled then
			Waypoints:Toggle()
			Waypoints:Toggle()
		end
	end,
})
List = Waypoints:CreateTextList({
	Name = 'Points',
	Placeholder = 'x, y, z/name',
	Function = function()
		if Waypoints.Enabled then
			Waypoints:Toggle()
			Waypoints:Toggle()
		end
	end
})
Waypoints:CreateButton({
	Name = 'Add current position',
	Function = function()
		if entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
			local pos = entitylib.character.RootPart.Position // 1
			if List then
				List:ChangeValue(pos.X..','..pos.Y..','..pos.Z..'/Waypoint '..(#List.List + 1))
			end
		end
	end
})
Color = Waypoints:CreateColorSlider({
	Name = 'Color',
	Function = function(hue, sat, val)
		for _, v in WaypointFolder:GetChildren() do
			v.TextLabel.TextColor3 = Color3.fromHSV(hue, sat, val)
		end
	end
})
Scale = Waypoints:CreateSlider({
	Name = 'Scale',
	Function = function()
		if Waypoints.Enabled then
			Waypoints:Toggle()
			Waypoints:Toggle()
		end
	end,
	Default = 1,
	Min = 0.1,
	Max = 1.5,
	Decimal = 10
})
Background = Waypoints:CreateSlider({
	Name = 'Transparency',
	Function = function()
		if Waypoints.Enabled then
			Waypoints:Toggle()
			Waypoints:Toggle()
		end
	end,
	Default = 0.5,
	Min = 0,
	Max = 1,
	Decimal = 10
})






