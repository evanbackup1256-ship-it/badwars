local AutoClicker
local CPS
local BlockCPS = {}
local Thread
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local lplr = game:GetService('Players').LocalPlayer
local inputService = game:GetService('UserInputService')
local store = (shared.Bad and shared.Bad.store) or {}

local function AutoClick()
	if Thread then
		task.cancel(Thread)
	end

	Thread = task.delay(1 / 7, function()
		repeat
			local layerOpen = false
			if bedwars.AppController and bedwars.UILayers then
				pcall(function() layerOpen = bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) end)
			end
			if not layerOpen then
				if store.hand and store.hand.toolType == 'block' then
					if bedwars.BlockPlacementController and bedwars.BlockPlacementController.blockPlacer then
						local blockPlacer = bedwars.BlockPlacementController.blockPlacer
						local canPlace = true
						if bedwars.BlockCpsController then
							pcall(function() canPlace = (workspace:GetServerTimeNow() - (bedwars.BlockCpsController.lastPlaceTimestamp or 0)) >= ((1 / 12) * 0.5) end)
						end
						if canPlace and blockPlacer.clientManager then
							pcall(function()
								local mouseinfo = blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
								if mouseinfo and mouseinfo.placementPosition == mouseinfo.placementPosition then
									task.spawn(blockPlacer.placeBlock, blockPlacer, mouseinfo.placementPosition)
								end
							end)
						end
					end
				elseif store.hand and store.hand.toolType == 'sword' then
					if bedwars.SwordController then
						pcall(function() bedwars.SwordController:swingSwordAtMouse() end)
					end
				end
			end

			local cpsObj = (store.hand and store.hand.toolType == 'block' and BlockCPS) or CPS
			local cpsVal = cpsObj and cpsObj.GetRandomValue and cpsObj.GetRandomValue() or 7
			task.wait(1 / cpsVal)
		until not AutoClicker or not AutoClicker.Enabled
	end)
end

AutoClicker = Bad.Categories.Combat:CreateModule({
	Name = 'AutoClicker',
	Function = function(callback)
		if callback then
			AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					AutoClick()
				end
			end))

			AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread then
					task.cancel(Thread)
					Thread = nil
				end
			end))

			if inputService.TouchEnabled then
				pcall(function()
					if lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('MobileUI') then
						AutoClicker:Clean(lplr.PlayerGui.MobileUI['2'].MouseButton1Down:Connect(AutoClick))
						AutoClicker:Clean(lplr.PlayerGui.MobileUI['2'].MouseButton1Up:Connect(function()
							if Thread then
								task.cancel(Thread)
								Thread = nil
							end
						end))
					end
				end)
			end
		else
			if Thread then
				task.cancel(Thread)
				Thread = nil
			end
		end
	end,
	Tooltip = 'Hold attack button to automatically click'
})
CPS = AutoClicker:CreateTwoSlider({
	Name = 'CPS',
	Min = 1,
	Max = 9,
	DefaultMin = 7,
	DefaultMax = 7
})
AutoClicker:CreateToggle({
	Name = 'Place Blocks',
	Default = true,
	Function = function(callback)
		if BlockCPS.Object then
			BlockCPS.Object.Visible = callback
		end
	end
})
BlockCPS = AutoClicker:CreateTwoSlider({
	Name = 'Block CPS',
	Min = 1,
	Max = 12,
	DefaultMin = 12,
	DefaultMax = 12,
	Darker = true
})





