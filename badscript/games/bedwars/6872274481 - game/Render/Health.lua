local Health
local lplr = game:GetService('Players').LocalPlayer

Health = Bad.Categories.Render:CreateModule({
	Name = 'Health',
	Function = function(callback)
		if callback then
			local label = Instance.new('TextLabel')
			label.Size = UDim2.fromOffset(100, 20)
			label.Position = UDim2.new(0.5, 6, 0.5, 30)
			label.BackgroundTransparency = 1
			label.AnchorPoint = Vector2.new(0.5, 0)
			label.TextColor3 = Color3.new()
			label.TextSize = 18
			label.Font = Enum.Font.Arial
			label.Parent = Bad.gui
			Health:Clean(label)

			local function updateHealth()
				pcall(function()
					local char = lplr.Character
					if not char then label.Text = '' return end
					local hum = char:FindFirstChildOfClass('Humanoid')
					if not hum then label.Text = '' return end
					local hp = hum.Health
					local maxHp = hum.MaxHealth
					if type(hp) ~= 'number' or type(maxHp) ~= 'number' then label.Text = '' return end
					label.Text = math.round(hp) .. ' ?'
					local ratio = maxHp > 0 and hp / maxHp or 0
					label.TextColor3 = Color3.fromHSV(ratio / 2.8, 0.86, 1)
				end)
			end

			updateHealth()
			Health:Clean(lplr.CharacterAdded:Connect(function()
				task.wait(0.5)
				updateHealth()
			end))
			if lplr.Character then
				local hum = lplr.Character:FindFirstChildOfClass('Humanoid')
				if hum then
					Health:Clean(hum.HealthChanged:Connect(updateHealth))
				end
			end
		end
	end,
	Tooltip = 'Displays your health in the center of your screen.'
})
