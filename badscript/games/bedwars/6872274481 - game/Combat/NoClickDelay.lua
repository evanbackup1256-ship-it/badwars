local old
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}

Bad.Categories.Combat:CreateModule({
	Name = 'NoClickDelay',
	Function = function(callback)
		if bedwars.SwordController then
			if callback then
				old = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
					self.lastSwing = os.clock()
					return false
				end
			else
				if old then
					bedwars.SwordController.isClickingTooFast = old
				end
			end
		end
	end,
	Tooltip = 'Remove the CPS cap'
})





