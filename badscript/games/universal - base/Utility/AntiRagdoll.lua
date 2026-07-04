local AntiRagdoll

AntiRagdoll = Bad.Categories.Utility:CreateModule({
	Name = 'AntiRagdoll',
	Function = function(callback)
		if entitylib.isAlive and entitylib.character and entitylib.character.Humanoid then
			entitylib.character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not callback)
		end

		if callback then
			AntiRagdoll:Clean(entitylib.Events.LocalAdded:Connect(function(char)
				if char and char.Humanoid then
					char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				end
			end))
		end
	end,
	Tooltip = 'Prevents you from getting knocked down in a ragdoll state'
})





