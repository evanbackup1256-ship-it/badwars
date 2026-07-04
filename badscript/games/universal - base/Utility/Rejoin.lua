local Rejoin

Rejoin = Bad.Categories.Utility:CreateModule({
	Name = 'Rejoin',
	Function = function(callback)
		if callback then
			notif('Rejoin', 'Rejoining...', 5)
			Rejoin:Toggle()

			if teleportService then
				if playersService and playersService.NumPlayers > 1 then
					teleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
				else
					teleportService:Teleport(game.PlaceId)
				end
			end
		end
	end,
	Tooltip = 'Rejoins the server'
})





