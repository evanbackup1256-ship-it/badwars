local FastBreak
local Time
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}

FastBreak = Bad.Categories.Blatant:CreateModule({
	Name = 'FastBreak',
	Function = function(callback)
		if callback then
			repeat
				if bedwars.BlockBreakController and bedwars.BlockBreakController.blockBreaker then
					pcall(function()
						bedwars.BlockBreakController.blockBreaker:setCooldown(Time and Time.Value or 0.25)
					end)
				end
				task.wait(0.1)
			until not FastBreak or not FastBreak.Enabled
		else
			if bedwars.BlockBreakController and bedwars.BlockBreakController.blockBreaker then
				pcall(function()
					bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
				end)
			end
		end
	end,
	Tooltip = 'Decreases block hit cooldown'
})
Time = FastBreak:CreateSlider({
	Name = 'Break speed',
	Min = 0,
	Max = 0.3,
	Default = 0.25,
	Decimal = 100,
	Suffix = 'seconds'
})





