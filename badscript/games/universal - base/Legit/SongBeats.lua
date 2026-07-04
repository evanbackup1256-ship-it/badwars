local SongBeats
local List
local FOV
local FOVValue = {}
local Volume
local alreadypicked = {}
local beattick = tick()
local oldfov, songobj, songbpm, songtween

local function choosesong()
	local list = List and List.ListEnabled or {}
	if #alreadypicked >= #list then
		table.clear(alreadypicked)
	end

	if #list <= 0 then
		notif('SongBeats', 'no songs', 10)
		SongBeats:Toggle()
		return
	end

	local chosensong = list[math.random(1, #list)]
	if #list > 1 and table.find(alreadypicked, chosensong) then
		repeat
			task.wait()
			chosensong = list[math.random(1, #list)]
		until not table.find(alreadypicked, chosensong) or not SongBeats or not SongBeats.Enabled
	end
	if not SongBeats or not SongBeats.Enabled then return end

	local split = chosensong:split('/')
	if not isfile(split[1]) then
		notif('SongBeats', 'Missing song ('..split[1]..')', 10)
		SongBeats:Toggle()
		return
	end

	if songobj then
		songobj.SoundId = assetfunction and assetfunction(split[1]) or split[1]
	end
	repeat
		task.wait()
	until (songobj and songobj.IsLoaded) or not SongBeats or not SongBeats.Enabled

	if SongBeats and SongBeats.Enabled then
		beattick = tick() + (tonumber(split[3]) or 0)
		songbpm = 60 / (tonumber(split[2]) or 50)
		if songobj then
			songobj:Play()
		end
	end
end

SongBeats = Bad.Legit:CreateModule({
	Name = 'Song Beats',
	Function = function(callback)
		if callback then
			songobj = Instance.new('Sound')
			songobj.Volume = (Volume and Volume.Value or 100) / 100
			songobj.Parent = workspace
			oldfov = gameCamera and gameCamera.FieldOfView

			repeat
				if songobj and not songobj.Playing then
					choosesong()
				end

				if beattick < tick() and SongBeats and SongBeats.Enabled and FOV and FOV.Enabled and gameCamera then
					beattick = tick() + songbpm
					gameCamera.FieldOfView = oldfov - (FOVValue and FOVValue.Value or 5)
					if tweenService then
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {
							FieldOfView = oldfov
						})
						songtween:Play()
					end
				end

				task.wait()
			until not SongBeats or not SongBeats.Enabled
		else
			if songobj then
				songobj:Destroy()
			end

			if songtween then
				songtween:Cancel()
			end

			if oldfov and gameCamera then
				gameCamera.FieldOfView = oldfov
			end

			table.clear(alreadypicked)
		end
	end,
	Tooltip = 'Built in mp3 player'
})
List = SongBeats:CreateTextList({
	Name = 'Songs',
	Placeholder = 'filepath/bpm/start'
})
FOV = SongBeats:CreateToggle({
	Name = 'Beat FOV',
	Function = function(callback)
		if FOVValue.Object then
			FOVValue.Object.Visible = callback
		end

		if SongBeats.Enabled then
			SongBeats:Toggle()
			SongBeats:Toggle()
		end
	end,
	Default = true
})
FOVValue = SongBeats:CreateSlider({
	Name = 'Adjustment',
	Min = 1,
	Max = 30,
	Default = 5,
	Darker = true
})
Volume = SongBeats:CreateSlider({
	Name = 'Volume',
	Function = function(val)
		if songobj then
			songobj.Volume = val / 100
		end
	end,
	Min = 1,
	Max = 100,
	Default = 100,
	Suffix = '%'
})





