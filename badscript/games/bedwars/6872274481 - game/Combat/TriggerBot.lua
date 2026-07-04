local TriggerBot
local CPS
local rayParams = RaycastParams.new()
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local store = (shared.Bad and shared.Bad.store) or {}

TriggerBot = Bad.Categories.Combat:CreateModule({
	Name = 'TriggerBot',
	Function = function(callback)
		if callback then
			repeat
				local doAttack = false
				local layerOpen = false
				if bedwars.AppController and bedwars.UILayers then
					pcall(function() layerOpen = bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) end)
				end
				if not layerOpen then
					if entitylib.isAlive and entitylib.character and entitylib.character.RootPart and store.hand and store.hand.toolType == 'sword' then
						local chargingMaid = nil
						if bedwars.DaoController then
							pcall(function() chargingMaid = bedwars.DaoController.chargingMaid end)
						end
						if chargingMaid == nil then
							local attackRange = 14.4
							if bedwars.ItemMeta and store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name] and bedwars.ItemMeta[store.hand.tool.Name].sword then
								attackRange = bedwars.ItemMeta[store.hand.tool.Name].sword.attackRange or 14.4
							end
							rayParams.FilterDescendantsInstances = {lplr.Character}

							local unit = lplr:GetMouse().UnitRay
							local localPos = entitylib.character.RootPart.Position
							local rayRange = attackRange or 14.4
							local ray = nil
							if bedwars.QueryUtil then
								pcall(function() ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams) end)
							end
							if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
								local limit = attackRange
								for _, ent in entitylib.List do
									doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
									if doAttack then
										break
									end
								end
							end

							if not doAttack and bedwars.SwordController then
								pcall(function() doAttack = bedwars.SwordController:getTargetInRegion((attackRange or 3.8) * 3, 0) end)
							end
							if doAttack and bedwars.SwordController then
								pcall(function() bedwars.SwordController:swingSwordAtMouse() end)
							end
						end
					end
				end

				local cpsVal = CPS and CPS.GetRandomValue and CPS.GetRandomValue() or 7
				task.wait(doAttack and 1 / cpsVal or 0.016)
			until not TriggerBot or not TriggerBot.Enabled
		end
	end,
	Tooltip = 'Automatically swings when hovering over a entity'
})
CPS = TriggerBot:CreateTwoSlider({
	Name = 'CPS',
	Min = 1,
	Max = 9,
	DefaultMin = 7,
	DefaultMax = 7
})





