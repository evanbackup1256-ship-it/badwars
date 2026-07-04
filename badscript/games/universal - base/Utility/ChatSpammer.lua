local ChatSpammer
local Lines
local Mode
local Delay
local Hide
local oldchat

ChatSpammer = Bad.Categories.Utility:CreateModule({
	Name = 'ChatSpammer',
	Function = function(callback)
		if callback then
			if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				if Hide.Enabled and coreGui:FindFirstChild('ExperienceChat') then
					local scroll = coreGui.ExperienceChat:FindFirstChild('RCTScrollContentView', true)
					if scroll and scroll.ChildAdded then
						ChatSpammer:Clean(scroll.ChildAdded:Connect(function(msg)
							if msg.Name:sub(1, 2) == '0-' and msg.ContentText == 'You must wait before sending another message.' then
								msg.Visible = false
							end
						end))
					else
						notif('ChatSpammer', 'chat flood message container unavailable; continuing without hide filter', 5, 'warning')
					end
				end
			elseif replicatedStorage:FindFirstChild('DefaultChatSystemChatEvents') then
				if Hide.Enabled then
					local conns = getconnections and getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnNewSystemMessage.OnClientEvent)
					if hookfunction and conns and conns[1] and conns[1].Function then
						oldchat = hookfunction(conns[1].Function, function(data, ...)
							if type(data) == 'table' and type(data.Message) == 'string' and data.Message:find('ChatFloodDetector') then return end
							return oldchat(data, ...)
						end)
					else
						notif('ChatSpammer', 'legacy chat hook unavailable; continuing without hide filter', 5, 'warning')
					end
				end
			else
				notif('ChatSpammer', 'unsupported chat', 5, 'warning')
				ChatSpammer:Toggle()
				return
			end
			
			local ind = 1
			repeat
				local message = (#Lines.ListEnabled > 0 and Lines.ListEnabled[math.random(1, #Lines.ListEnabled)] or 'BadWars on top')
				if Mode.Value == 'Order' and #Lines.ListEnabled > 0 then
					message = Lines.ListEnabled[ind] or Lines.ListEnabled[1]
					ind = (ind % #Lines.ListEnabled) + 1
				end

				local ok, err = false, 'chat helper unavailable'
				if Bad.SendChatMessage then ok, err = Bad.SendChatMessage(message) end
				if not ok then
					notif('ChatSpammer', 'chat unavailable: '..tostring(err), 5, 'warning')
					ChatSpammer:Toggle()
					return
				end

				task.wait(math.max(tonumber(Delay.Value) or 1, 0.1))
			until not ChatSpammer.Enabled
		else
			if oldchat then
				local conns = getconnections and getconnections(replicatedStorage.DefaultChatSystemChatEvents.OnNewSystemMessage.OnClientEvent)
				if hookfunction and conns and conns[1] and conns[1].Function then
					hookfunction(conns[1].Function, oldchat)
				end
				oldchat = nil
			end
		end
	end,
	Tooltip = 'Automatically types in chat'
})
Lines = ChatSpammer:CreateTextList({Name = 'Lines'})
Mode = ChatSpammer:CreateDropdown({
	Name = 'Mode',
	List = {'Random', 'Order'}
})
Delay = ChatSpammer:CreateSlider({
	Name = 'Delay',
	Min = 0.1,
	Max = 10,
	Default = 1,
	Decimal = 10,
	Suffix = function(val)
		return val == 1 and 'second' or 'seconds'
	end
})
Hide = ChatSpammer:CreateToggle({
	Name = 'Hide Flood Message',
	Default = true,
	Function = function()
		if ChatSpammer.Enabled then
			ChatSpammer:Toggle()
			ChatSpammer:Toggle()
		end
	end
})





