local FastDrop

FastDrop = Bad.Categories.Inventory:CreateModule({
	Name = 'FastDrop',
	Function = function(callback)
		if not callback then return end
		local dropController = bedwars.ItemDropController
		if not dropController or type(dropController.dropItemInHand) ~= 'function' then
			if Bad.BedWarsCompatibility then
				Bad.BedWarsCompatibility:Unavailable(FastDrop, 'Item drop controller is unavailable in this BedWars build.')
			end
			return
		end
		repeat
			if entitylib.isAlive
				and store.inventory
				and not store.inventory.opened
				and (inputService:IsKeyDown(Enum.KeyCode.H) or inputService:IsKeyDown(Enum.KeyCode.Backspace))
				and inputService:GetFocusedTextBox() == nil
			then
				pcall(dropController.dropItemInHand, dropController)
				task.wait()
			else
				task.wait(0.1)
			end
		until not FastDrop.Enabled
	end,
	Tooltip = 'Drops items fast when you hold H or Backspace'
})





