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
			AutoToxic:Clean(BadEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
				if Toggles.BedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute('Team') then
					sendMessage('BedDestroyed', (bedTable.player.DisplayName or bedTable.player.Name), 'how dare you >:( | <obj>')
				elseif Toggles.Bed.Enabled and bedTable.player.UserId == lplr.UserId then
					local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
					sendMessage('Bed', team and team.displayName:lower() or 'white', 'nice bed lul | <obj>')
				end
			end))
			AutoToxic:Clean(BadEvents.EntityDeathEvent.Event:Connect(function(deathTable)
				if deathTable.finalKill then
					local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
					local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
					if not killed or not killer then return end
					if killed == lplr then
						if (not dead) and killer ~= lplr and Toggles.Death.Enabled then
							dead = true
							sendMessage('Death', (killer.DisplayName or killer.Name), 'my gaming chair subscription expired :( | <obj>')
						end
					elseif killer == lplr and Toggles.Kill.Enabled then
						sendMessage('Kill', (killed.DisplayName or killed.Name), 'BadWars on top | <obj>')
					end
				end
			end))
			AutoToxic:Clean(BadEvents.MatchEndEvent.Event:Connect(function(winstuff)
				if GG.Enabled then
					local ok, err = false, 'chat helper unavailable'
					if Bad.SendChatMessage then ok, err = Bad.SendChatMessage('gg') end
					if not ok then notif('AutoToxic', 'chat unavailable: '..tostring(err), 5, 'warning') end
				end
				
				local myTeam = bedwars.Store:getState().Game.myTeam
				if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
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
for _, v in {'Kill', 'Death', 'Bed', 'BedDestroyed', 'Win'} do
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





