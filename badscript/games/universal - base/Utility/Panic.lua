Bad.Categories.Utility:CreateModule({
	Name = 'Panic',
	Function = function(callback)
		if callback and Bad and Bad.Modules then
			for _, v in Bad.Modules do
				if v and v.Enabled then
					v:Toggle()
				end
			end
		end
	end,
	Tooltip = 'Disables all currently enabled modules'
})





