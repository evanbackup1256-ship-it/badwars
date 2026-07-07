local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local compat = Bad.BedWarsCompatibility or {}
local lplr = Bad.lplr or game:GetService("Players").LocalPlayer
local runService = game:GetService('RunService')
local remotes = Bad.remotes or {}

Bad.Categories.World:CreateModule({
	Name = 'Anti-AFK',
	Function = function(callback)
		if callback then
			local connections = (compat.SafeGetConnections and compat:SafeGetConnections(lplr.Idled)) or {}
			for _, v in ipairs(connections) do
				pcall(function() v:Disconnect() end)
			end

			local afkRemote = remotes.AfkStatus or "AfkStatus"
			local hbConnections = (compat.SafeGetConnections and compat:SafeGetConnections(runService.Heartbeat)) or {}
			for _, v in ipairs(hbConnections) do
				if type(v) == "table" and type(v.Function) == 'function' then
					local constants = (compat.SafeGetConstants and compat:SafeGetConstants(v.Function)) or {}
					if table.find(constants, afkRemote) then
						pcall(function() if v.Disconnect then v:Disconnect() end end)
					end
				end
			end

			if compat.FireRemote then
				compat:FireRemote(afkRemote, 'SendToServer', {afk = false})
			else
				pcall(function()
					local r = bedwars.Client and bedwars.Client:Get(afkRemote)
					if r and r.SendToServer then r:SendToServer({afk = false}) end
				end)
			end
		end
	end,
	Tooltip = 'Lets you stay ingame without getting kicked'
})