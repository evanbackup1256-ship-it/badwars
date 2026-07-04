local AutoToxic
local GG
local Toggles, Lists, said, dead = {}, {}, {}

local function sendMessage(name, obj, default)
	local tab = Lists[name].ListEnabled
	local custommsg = #tab > 0 and tab[math.random(1, #tab)] or default
	if not custommsg then return end
	if #tab > 1 and custommsg == said[name] then
		repeat
			task.wait()
			custommsg = tab[math.random(1, #tab)]
		until custommsg ~= said[name]
	end
	said[name] = custommsg

	custommsg = custommsg and custommsg:gsub('<obj>', obj or '') or ''
	local ok, err = false, 'chat helper unavailable'
	if Bad.SendChatMessage then ok, err = Bad.SendChatMessage(custommsg) end
	if not ok then notif('AutoToxic', 'chat unavailable: '..tostring(err), 5, 'warning') end
end

AutoToxic = Bad.Categories.Utility:CreateModule({
	Name = 'AutoToxic',
	Function = function(callback)
		if callback then
			AutoToxic:Clean(BadEvents.MatchEnded.Event:Connect(function(won)
				if GG.Enabled then
					local ok, err = false, 'chat helper unavailable'
					if Bad.SendChatMessage then ok, err = Bad.SendChatMessage('gg') end
					if not ok then notif('AutoToxic', 'chat unavailable: '..tostring(err), 5, 'warning') end
				end

				if won then
					if Toggles.Win.Enabled then
						sendMessage('Win', nil, 'yall garbage')
					end
				end
			end))
		end
	end,
	Tooltip = 'Says a message after a certain action'
})
GG = AutoToxic:CreateToggle({
	Name = 'AutoGG',
	Default = true
})
for _, v in {'Win'} do
	Toggles[v] = AutoToxic:CreateToggle({
		Name = v..' ',
		Function = function(callback)
			if Lists[v] then
				Lists[v].Object.Visible = callback
			end
		end
	})
	Lists[v] = AutoToxic:CreateTextList({
		Name = v,
		Darker = true,
		Visible = false
	})
end





