local StateSpoofer
local State
local hook

StateSpoofer = Bad.Categories.Utility:CreateModule({
	Name = 'StateSpoofer',
	Function = function(callback)
		if callback then
			if not rakNetCheck or not rakNetCheck('StateSpoofer') then
				StateSpoofer:Toggle()
				return
			end

			hook = function(packet)
				if packet and packet.AsArray and packet.AsArray[1] == 0x1b and packet.AsBuffer then
					local data = packet.AsBuffer
					if State and State.Value and Enum.HumanoidStateType[State.Value] then
						buffer.writeu8(data, 25, Enum.HumanoidStateType[State.Value].Value + 32)
						packet:SetData(data)
					end
				end
			end

			if raknet and raknet.add_send_hook then
				raknet.add_send_hook(hook)
			end
		elseif hook then
			if raknet and raknet.remove_send_hook then
				raknet.remove_send_hook(hook)
			end
			hook = nil
		end
	end,
	Tooltip = 'Spoof humanoid states on the server.'
})
local states = {}
for _, v in Enum.HumanoidStateType:GetEnumItems() do
	if v.Name ~= 'None' then
		table.insert(states, v.Name)
	end
end
State = StateSpoofer:CreateDropdown({
	Name = 'Humanoid State',
	List = states
})





