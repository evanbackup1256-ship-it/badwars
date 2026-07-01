Bad.Categories.Utility:CreateModule({
	Name = 'Panic',
	Function = function(callback)
		if callback then
			for _, v in Bad.Modules do
				if v.Enabled then
					v:Toggle()
				end
			end
		end
	end,
	Tooltip = 'Disables all currently enabled modules'
})




