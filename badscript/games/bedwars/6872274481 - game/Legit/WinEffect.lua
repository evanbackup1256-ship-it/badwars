local Bad = shared.Bad or {}
local bedwars = Bad.bedwars or {}
local store = Bad.store or {}
local entitylib = Bad.entitylib or {}
local compat = Bad.BedWarsCompatibility or {}
local BadEvents = Bad.BadEvents or {}

local WinEffect
local List
local NameToId = {}

WinEffect = Bad.Legit:CreateModule({
	Name = 'WinEffect',
	Function = function(callback)
		if callback then
			WinEffect:Clean(BadEvents.MatchEndEvent.Event:Connect(function()
				local gc = Bad.getconnections or getconnections or function() return {} end
				for i, v in gc(bedwars.Client:Get('WinEffectTriggered').instance.OnClientEvent) do
					if v.Function then
						v.Function({
							winEffectType = NameToId[List.Value],
							winningPlayer = lplr
						})
					end
				end
			end))
		end
	end,
	Tooltip = 'Allows you to select any clientside win effect'
})
local WinEffectName = {}
for i, v in bedwars.WinEffectMeta do
	table.insert(WinEffectName, v.name)
	NameToId[v.name] = i
end
table.sort(WinEffectName)
List = WinEffect:CreateDropdown({
	Name = 'Effects',
	List = WinEffectName
})





