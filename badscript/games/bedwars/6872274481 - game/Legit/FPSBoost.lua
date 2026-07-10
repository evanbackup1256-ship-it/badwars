local Bad = shared.Bad or {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local store = (shared.Bad and shared.Bad.store) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local compat = Bad.BedWarsCompatibility or {}

local FPSBoost
local Kill
local Visualizer
local effects, util = {}, {}

FPSBoost = Bad.Legit:CreateModule({
	Name = 'FPS Boost',
	Function = function(callback)
		if callback then
			if Kill.Enabled and bedwars.KillEffectController and bedwars.KillEffectController.killEffects then
				for i, v in pairs(bedwars.KillEffectController.killEffects) do
					if not tostring(i):find('Custom') then
						effects[i] = v
						bedwars.KillEffectController.killEffects[i] = {
							new = function() 
								return {
									onKill = function() end, 
									isPlayDefaultKillEffect = function() 
										return true 
									end
								} 
							end
						}
					end
				end
			end

			if Visualizer.Enabled and bedwars.VisualizerUtils then
				for i, v in pairs(bedwars.VisualizerUtils) do
					util[i] = v
					bedwars.VisualizerUtils[i] = function() end
				end
			end

			repeat task.wait() until store.matchState ~= 0
			if not bedwars.AppController then return end
			if bedwars.NametagController then
				bedwars.NametagController.addGameNametag = function() end
			end
			pcall(function()
				for _, v in bedwars.AppController:getOpenApps() do
					if tostring(v):find('Nametag') then
						bedwars.AppController:closeApp(tostring(v))
					end
				end
			end)
		else
			for i, v in pairs(effects) do 
				if bedwars.KillEffectController and bedwars.KillEffectController.killEffects then
					bedwars.KillEffectController.killEffects[i] = v 
				end
			end
			for i, v in pairs(util) do 
				if bedwars.VisualizerUtils then
					bedwars.VisualizerUtils[i] = v 
				end
			end
			table.clear(effects)
			table.clear(util)
		end
	end,
	Tooltip = 'Improves the framerate by turning off certain effects'
})
Kill = FPSBoost:CreateToggle({
	Name = 'Kill Effects',
	Function = function()
		if FPSBoost.Enabled then
			FPSBoost:Toggle()
			FPSBoost:Toggle()
		end
	end,
	Default = true
})
Visualizer = FPSBoost:CreateToggle({
	Name = 'Visualizer',
	Function = function()
		if FPSBoost.Enabled then
			FPSBoost:Toggle()
			FPSBoost:Toggle()
		end
	end,
	Default = true
})





