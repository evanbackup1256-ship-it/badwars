local Health

Health = Bad.Categories.Render:CreateModule({
	Name = 'Health',
	Function = function(callback)
		if callback then
			local label = Instance.new('TextLabel')
			label.Size = UDim2.fromOffset(100, 20)
			label.Position = UDim2.new(0.5, 6, 0.5, 30)
			label.AnchorPoint = Vector2.new(0.5, 0)
			label.BackgroundTransparency = 1
			label.Text = '100 ❤️'
			label.TextSize = 18
			label.Font = Enum.Font.Arial
			label.Parent = Bad.gui
			Health:Clean(label)

			local function updateHealth()
				pcall(function()
					if not entitylib.isAlive or not entitylib.character or not entitylib.character.Humanoid then
						label.Text = ''
						return
					end
					local hp = entitylib.character.Humanoid.Health
					local maxHp = entitylib.character.Humanoid.MaxHealth
					if type(hp) ~= 'number' or type(maxHp) ~= 'number' then
						label.Text = ''
						return
					end
					label.Text = math.round(hp) .. ' ❤️'
					local ratio = maxHp > 0 and hp / maxHp or 0
					label.TextColor3 = Color3.fromHSV(ratio / 2.8, 0.86, 1)
				end)
			end

			updateHealth()
			Health:Clean(runService.RenderStepped:Connect(updateHealth))
		end
	end,
	Tooltip = 'Displays your health in the center of your screen.'
})