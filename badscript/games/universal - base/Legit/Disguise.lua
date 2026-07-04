local Disguise
local Mode
local IDBox
local desc

local function itemAdded(v, manual)
	if (not v:GetAttribute('Disguise')) and ((v:IsA('Accessory') and (not v:GetAttribute('InvItem')) and (not v:GetAttribute('ArmorSlot'))) or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors') or manual) then
		repeat
			task.wait()
			v.Parent = game
		until v.Parent == game

		v:ClearAllChildren()
		v:Destroy()
	end
end

local function characterAdded(char)
	if not char or not char.Character then return end
	if Mode and Mode.Value == 'Character' then
		task.wait(0.1)
		if char.Character then
			char.Character.Archivable = true
		end

		local clone = char.Character and char.Character:Clone()
		if not clone then return end
		repeat
			if pcall(function()
				desc = playersService:GetHumanoidDescriptionFromUserId(IDBox and IDBox.Value == '' and 239702688 or tonumber(IDBox and IDBox.Value))
			end) and desc then break end
			task.wait(1)
		until not Disguise or not Disguise.Enabled

		if not Disguise or not Disguise.Enabled then
			clone:ClearAllChildren()
			clone:Destroy()
			clone = nil
			if desc then
				desc:Destroy()
				desc = nil
			end
			return
		end

		clone.Parent = game

		local originalDesc = char.Humanoid and char.Humanoid:WaitForChild('HumanoidDescription', 2) or {
			HeightScale = 1,
			SetEmotes = function() end,
			SetEquippedEmotes = function() end
		}
		if desc and originalDesc then
			originalDesc.JumpAnimation = desc.JumpAnimation
			desc.HeightScale = originalDesc.HeightScale
		end

		for _, v in clone:GetChildren() do
			if v:IsA('Accessory') or v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') then
				v:ClearAllChildren()
				v:Destroy()
			end
		end

		pcall(function()
			if clone and clone:FindFirstChildOfClass('Humanoid') and desc then
				clone:FindFirstChildOfClass('Humanoid'):ApplyDescription(desc)
			end
		end)
		if char.Character then
			for _, v in char.Character:GetChildren() do
				itemAdded(v)
			end
			Disguise:Clean(char.Character.ChildAdded:Connect(itemAdded))
		end

		local animateClone = clone:FindFirstChild('Animate')
		if animateClone and char.Character then
			for _, v in animateClone:GetChildren() do
				if not char.Character:FindFirstChild('Animate') then return end
				local real = char.Character.Animate and char.Character.Animate:FindFirstChild(v.Name)
				if v and real then
					local anim = v:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					local realanim = real:FindFirstChildWhichIsA('Animation') or {AnimationId = ''}
					if realanim then
						realanim.AnimationId = anim.AnimationId
					end
				end
			end
		end

		for _, v in clone:GetChildren() do
			v:SetAttribute('Disguise', true)
			if v:IsA('Accessory') then
				for _, v2 in v:GetDescendants() do
					if v2:IsA('Weld') and v2.Part1 and char.Character then
						local targetPart = char.Character:FindFirstChild(v2.Part1.Name)
						if targetPart then
							v2.Part1 = targetPart
						end
					end
				end
				if char.Character then v.Parent = char.Character end
			elseif (v:IsA('ShirtGraphic') or v:IsA('Shirt') or v:IsA('Pants') or v:IsA('BodyColors')) and char.Character then
				v.Parent = char.Character
			elseif v.Name == 'Head' and char.Head and char.Head:IsA('MeshPart') and not char.Head:FindFirstChild('FaceControls') then
				char.Head.MeshId = v.MeshId
			end
		end

		if char.Character then
			local localface = char.Character:FindFirstChild('face', true)
			local cloneface = clone:FindFirstChild('face', true)
			if localface and cloneface then
				itemAdded(localface, true)
				if char.Head then cloneface.Parent = char.Head end
			end
		end
		if originalDesc and desc and type(originalDesc.SetEmotes) == 'function' and type(desc.GetEmotes) == 'function' then
			originalDesc:SetEmotes(desc:GetEmotes())
		end
		if originalDesc and desc and type(originalDesc.SetEquippedEmotes) == 'function' and type(desc.GetEquippedEmotes) == 'function' then
			originalDesc:SetEquippedEmotes(desc:GetEquippedEmotes())
		end
		clone:ClearAllChildren()
		clone:Destroy()
		clone = nil

		if desc then
			desc:Destroy()
			desc = nil
		end
	else
		local data
		repeat
			if pcall(function()
				data = marketplaceService:GetProductInfo(IDBox.Value == '' and 43 or tonumber(IDBox.Value), Enum.InfoType.Bundle)
			end) then break end
			task.wait(1)
		until not Disguise.Enabled

		if not Disguise.Enabled then
			if data then
				table.clear(data)
				data = nil
			end
			return
		end

		if data.BundleType == 'AvatarAnimations' then
			local animate = char.Character:FindFirstChild('Animate')
			if not animate then return end

			for _, v in desc.Items do
				local animtype = v.Name:split(' ')[2]:lower()
				if animtype ~= 'animation' then
					local suc, res = pcall(function()
						return game:GetObjects('rbxassetid://'..v.Id)
					end)

					if suc then
						animate[animtype]:FindFirstChildWhichIsA('Animation').AnimationId = res[1]:FindFirstChildWhichIsA('Animation', true).AnimationId
					end
				end
			end
		else
			notif('Disguise', 'that\'s not an animation pack', 5, 'warning')
		end
	end
end

Disguise = Bad.Legit:CreateModule({
	Name = 'Disguise',
	Function = function(callback)
		if callback then
			Disguise:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
			if entitylib.isAlive then
				characterAdded(entitylib.character)
			end
		end
	end,
	Tooltip = 'Changes your character or animation to a specific ID (animation packs or userid\'s only)'
})
Mode = Disguise:CreateDropdown({
	Name = 'Mode',
	List = {'Character', 'Animation'},
	Function = function()
		if Disguise.Enabled then
			Disguise:Toggle()
			Disguise:Toggle()
		end
	end
})
IDBox = Disguise:CreateTextBox({
	Name = 'Disguise',
	Placeholder = 'Disguise User Id',
	Function = function()
		if Disguise.Enabled then
			Disguise:Toggle()
			Disguise:Toggle()
		end
	end
})





