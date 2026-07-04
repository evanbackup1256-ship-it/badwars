local AutoRejoin
local Sort

AutoRejoin = Bad.Categories.Utility:CreateModule({
	Name = 'AutoRejoin',
	Function = function(callback)
		if callback and guiService then
			local check
			AutoRejoin:Clean(guiService.ErrorMessageChanged:Connect(function(str)
				if (not check or guiService:GetErrorCode() ~= Enum.ConnectionError.DisconnectLuaKick) and guiService:GetErrorCode() ~= Enum.ConnectionError.DisconnectConnectionLost and str and not str:lower():find('ban') then
					check = true
					serverHop(nil, Sort and Sort.Value or 'Descending')
				end
			end))
		end
	end,
	Tooltip = 'Automatically rejoins into a new server if you get disconnected / kicked'
})
Sort = AutoRejoin:CreateDropdown({
	Name = 'Sort',
	List = {'Descending', 'Ascending'},
	Tooltip = 'Descending - Prefers full servers\nAscending - Prefers empty servers'
})





