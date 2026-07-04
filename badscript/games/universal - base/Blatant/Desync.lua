local Desync
local hook

Desync = Bad.Categories.Blatant:CreateModule({
	Name = 'Desync',
	Function = function(callback)
		if callback then
			if not rakNetCheck or not rakNetCheck('Desync') then
				Desync:Toggle()
				return
			end

			hook = function(packet)
				if packet and packet.AsArray and packet.AsArray[1] == 0x1b and packet.AsBuffer then
					local data = packet.AsBuffer
					if buffer and buffer.writeu32 then
						buffer.writeu32(data, 1, 0xFFFFFFFF)
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
	Tooltip = 'Prevent the server from replicating your current position to other players.'
})





