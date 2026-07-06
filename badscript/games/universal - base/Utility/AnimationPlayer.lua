local AnimationPlayer
local IDBox
local Priority
local Speed
local anim, animobject
local rejectedIds = {}

local function stopAnimation()
	if anim then pcall(function() anim:Stop() end) end
	anim = nil
end

local function disableAfterFailure()
	task.defer(function()
		if AnimationPlayer and AnimationPlayer.Enabled then AnimationPlayer:Toggle() end
	end)
end

local function playAnimation(char)
	if not char or not char.Humanoid or not animobject then return end
	local assetId = tostring(animobject.AnimationId or '')
	if rejectedIds[assetId] then disableAfterFailure() return end
	stopAnimation()
	local animator = char.Humanoid:FindFirstChildOfClass('Animator')
	if not animator then animator = Instance.new('Animator') animator.Parent = char.Humanoid end
	local suc, result = pcall(function() return animator:LoadAnimation(animobject) end)
	if suc and result then
		anim = result
		local currentanim = result
		anim.Priority = Enum.AnimationPriority[Priority and Priority.Value or 'Action']
		anim:Play()
		anim:AdjustSpeed(Speed and Speed.Value or 1)
		AnimationPlayer:Clean(anim.Stopped:Connect(function()
			if currentanim == anim and AnimationPlayer.Enabled then pcall(function() currentanim:Play() end) end
		end))
		return
	end
	rejectedIds[assetId] = true
	notif('AnimationPlayer', 'Animation ' .. assetId .. ' is invalid, private, or not usable in this experience', 5, 'warning')
	disableAfterFailure()
end

AnimationPlayer = Bad.Categories.Utility:CreateModule({
	Name = 'AnimationPlayer',
	Function = function(callback)
		if callback then
			local rawId = tostring(IDBox and IDBox.Value or '')
			local numericId = rawId:match('^(%d+)$') or rawId:match('rbxassetid://(%d+)') or rawId:match('asset/?.*%?id=(%d+)')
			if not numericId or numericId == '' or #numericId < 5 then
				notif('AnimationPlayer', 'Invalid animation ID: ' .. rawId, 5, 'warning')
				disableAfterFailure()
				return
			end
			animobject = Instance.new('Animation')
			animobject.AnimationId = 'rbxassetid://' .. numericId
			if rejectedIds[animobject.AnimationId] then
				notif('AnimationPlayer', 'Animation ' .. animobject.AnimationId .. ' was already rejected by Roblox', 5, 'warning')
				disableAfterFailure()
				return
			end
			if entitylib.isAlive and entitylib.character then playAnimation(entitylib.character) end
			AnimationPlayer:Clean(entitylib.Events.LocalAdded:Connect(playAnimation))
			AnimationPlayer:Clean(animobject)
		else
			stopAnimation()
			animobject = nil
		end
	end,
	Tooltip = 'Plays a specific animation of your choosing at a certain speed'
})
IDBox = AnimationPlayer:CreateTextBox({
	Name = 'Animation',
	Placeholder = 'anim (num only)',
	Function = function(enter)
		if enter then table.clear(rejectedIds) end
		if enter and AnimationPlayer.Enabled then AnimationPlayer:Toggle() AnimationPlayer:Toggle() end
	end
})
local prio = {'Action4'}
for _, v in Enum.AnimationPriority:GetEnumItems() do if v.Name ~= 'Action4' then table.insert(prio, v.Name) end end
Priority = AnimationPlayer:CreateDropdown({
	Name = 'Priority',
	List = prio,
	Function = function(val) if anim then anim.Priority = Enum.AnimationPriority[val] end end
})
Speed = AnimationPlayer:CreateSlider({
	Name = 'Speed',
	Function = function(val) if anim then anim:AdjustSpeed(val) end end,
	Min = 0.1,
	Max = 2,
	Decimal = 10
})
