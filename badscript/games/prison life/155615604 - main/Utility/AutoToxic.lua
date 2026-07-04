local AutoToxic
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
			AutoToxic:Clean(BadEvents.CheaterKicked.Event:Connect(function(plr)
				sendMessage('Kicked', plr, 'skill issue cheat | <obj>')
			end))
		end
	end,
	Tooltip = 'Says a message after a certain action'
})
for _, v in {'Kicked'} do
	Toggles[v] = AutoToxic:CreateToggle({
		Name = v..' ',
		Function = function(callback)
			if Lists[v] then
				Lists[v].Object.Visible = callback
			end
		end,
		Default = true
	})
	Lists[v] = AutoToxic:CreateTextList({
		Name = v,
		Darker = true,
		Visible = false
	})
end





