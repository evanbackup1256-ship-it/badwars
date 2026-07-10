local Bad = shared.Bad or {}
local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
local store = (shared.Bad and shared.Bad.store) or {}
local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
local compat = Bad.BedWarsCompatibility or {}
local isfile = type(isfile) == 'function' and isfile or function() return false end
local assetfunction = type(assetfunction) == 'function' and assetfunction or type(getcustomasset) == 'function' and getcustomasset or function() return '' end

local SoundChanger
local List
local soundlist = {}
local old

SoundChanger = Bad.Legit:CreateModule({
	Name = 'SoundChanger',
	Function = function(callback)
		if callback then
			old = bedwars.SoundManager.playSound
			bedwars.SoundManager.playSound = function(self, id, ...)
				if soundlist[id] then
					id = soundlist[id]
				end

				return old(self, id, ...)
			end
		else
			bedwars.SoundManager.playSound = old
			old = nil
		end
	end,
	Tooltip = 'Change ingame sounds to custom ones.'
})
List = SoundChanger:CreateTextList({
	Name = 'Sounds',
	Placeholder = '(DAMAGE_1/ben.mp3)',
	Function = function()
		table.clear(soundlist)
		for _, entry in List.ListEnabled do
			local split = entry:split('/')
			local id = bedwars.SoundList[split[1]]
			if id and #split > 1 then
				soundlist[id] = split[2]:find('rbxasset') and split[2] or isfile(split[2]) and assetfunction(split[2]) or ''
			end
		end
	end
})





