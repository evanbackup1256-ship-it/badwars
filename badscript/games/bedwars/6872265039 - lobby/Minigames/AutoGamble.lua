local AutoGamble

AutoGamble = Bad.Categories.Minigames:CreateModule({
	Name = 'AutoGamble',
	Function = function(callback)
		if callback then
			local rewardCrate
			pcall(function()
				rewardCrate = bedwars.Client and bedwars.Client:GetNamespace('RewardCrate')
			end)
			local crateOpened = rewardCrate and rewardCrate:Get('CrateOpened')
			local openRewardCrate = rewardCrate and rewardCrate:Get('OpenRewardCrate')
			if not rewardCrate or not crateOpened or not openRewardCrate or not bedwars.CrateAltarController or type(bedwars.CrateAltarController.pickCrate) ~= 'function' or not bedwars.Store or type(bedwars.Store.getState) ~= 'function' then
				notif('AutoGamble', 'Crate services are not loaded yet.', 5, 'warning')
				if type(AutoGamble.Toggle) == 'function' then
					AutoGamble:Toggle(false)
				else
					AutoGamble.Enabled = false
				end
				return
			end

			AutoGamble:Clean(crateOpened:Connect(function(data)
				local reward = data and data.reward or {}
				if data and data.openingPlayer == lplr then
					local tab = (bedwars.CrateItemMeta and bedwars.CrateItemMeta[reward.itemType]) or {displayName = reward.itemType or 'unknown'}
					notif('AutoGamble', 'Won '..tab.displayName, 5)
				end
			end))

			repeat
				local activeCrates = bedwars.CrateAltarController.activeCrates or {}
				local state = bedwars.Store:getState()
				local inventory = state and state.Consumable and state.Consumable.inventory or {}
				if not activeCrates[1] then
					for _, v in inventory do
						local consumable = v and v.consumable
						if type(consumable) == 'string' and consumable:find('crate') then
							pcall(function()
								bedwars.CrateAltarController:pickCrate(consumable, 1)
							end)
							task.wait(1.2)
							activeCrates = bedwars.CrateAltarController.activeCrates or {}
							if activeCrates[1] and activeCrates[1][2] and activeCrates[1][2].attributes then
								pcall(function()
									openRewardCrate:SendToServer({
										crateId = activeCrates[1][2].attributes.crateId
									})
								end)
							end
							break
						end
					end
				end
				task.wait(1)
			until not AutoGamble.Enabled
		end
	end,
	Tooltip = 'Automatically opens lucky crates, piston inspired!'
})





