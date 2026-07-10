local Attacking
run(function()
	local Killaura
	local Targets
	local Sort
	local SwingRange
	local AttackRange
	local ChargeTime
	local UpdateRate
	local AngleSlider
	local MaxTargets
	local Mouse
	local Swing
	local GUI
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local Limit
	local LegitAura
	local Particles, Boxes = {}, {}
	local anims, AnimDelay, AnimTween, armC0 = (Bad.Libraries and Bad.Libraries.auraanims) or {}, tick()
	local AttackRemote = {FireServer = function() end}
	local store = (shared.Bad and shared.Bad.store) or {}
	local bedwars = (shared.Bad and shared.Bad.bedwars) or {}
	local remotes = (shared.Bad and shared.Bad.remotes) or {}
	local lplr = game:GetService('Players').LocalPlayer
	local inputService = game:GetService('UserInputService')
	local tweenService = game:GetService('TweenService')
	local gameCamera = workspace.CurrentCamera
	local targetinfo = (shared.Bad and shared.Bad.targetinfo) or {Targets = {}}
	local sortmethods = (shared.Bad and shared.Bad.sortmethods) or {}
	local entitylib = (shared.Bad and shared.Bad.entitylib) or {}
	local switchItem = (shared.Bad and shared.Bad.switchItem) or nil
	local oldSwing
	task.spawn(function()
		if bedwars.Client and remotes and remotes.AttackEntity then
			pcall(function()
				AttackRemote = bedwars.Client:Get(remotes.AttackEntity).instance
			end)
		end
	end)

	local function getAttackData()
		if Mouse and Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		if GUI and GUI.Enabled then
			if bedwars.AppController and bedwars.UILayers and bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end

		local sword = Limit and Limit.Enabled and store.hand or (store.tools and store.tools.sword)
		if not sword or not sword.tool then return false end

		local meta = bedwars.ItemMeta and bedwars.ItemMeta[sword.tool.Name]
		if Limit and Limit.Enabled then
			if (store.hand and store.hand.toolType ~= 'sword') or (bedwars.DaoController and bedwars.DaoController.chargingMaid) then return false end
		end

		if LegitAura and LegitAura.Enabled then
			if bedwars.SwordController and (tick() - (bedwars.SwordController.lastSwing or 0)) > 0.2 then return false end
		end

		return sword, meta
	end

	Killaura = Bad.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						if lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('MobileUI') then
							lplr.PlayerGui.MobileUI['2'].Visible = Limit and Limit.Enabled
						end
					end)
				end

				local execName = ''
				pcall(function() if type(identifyexecutor) == 'function' then execName = identifyexecutor() end end)
				if Animation and Animation.Enabled and not table.find({'Argon', 'Delta'}, execName) then
					local fake = {
						Controllers = {
							ViewmodelController = {
								isVisible = function()
									return not Attacking
								end,
								playAnimation = function(...)
									if not Attacking and bedwars.ViewmodelController then
										pcall(function() bedwars.ViewmodelController:playAnimation(select(2, ...)) end)
									end
								end
							}
						}
					}
					if oldSwing or (bedwars.SwordController and bedwars.SwordController.playSwordEffect) then
						pcall(function() debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, fake) end)
					end
					if bedwars.ScytheController and bedwars.ScytheController.playLocalAnimation then
						pcall(function() debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, fake) end)
					end

					task.spawn(function()
						local started = false
						repeat
							if Attacking then
								if not armC0 and gameCamera and gameCamera.Viewmodel then
									pcall(function()
										armC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
									end)
								end
								local first = not started
								started = true

								if AnimationMode and AnimationMode.Value == 'Random' then
									anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
								end

								for _, v in anims[AnimationMode and AnimationMode.Value or 'Default'] or {} do
									if gameCamera and gameCamera.Viewmodel then
										pcall(function()
											AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and (AnimationTween and AnimationTween.Enabled and 0.001 or 0.1) or v.Time / (AnimationSpeed and AnimationSpeed.Value or 1), Enum.EasingStyle.Linear), {
												C0 = armC0 * v.CFrame
											})
											AnimTween:Play()
											AnimTween.Completed:Wait()
										end)
									end
									first = false
									if (not Killaura.Enabled) or (not Attacking) then break end
								end
							elseif started then
								started = false
								if gameCamera and gameCamera.Viewmodel then
									pcall(function()
										AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween and AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
											C0 = armC0
										})
										AnimTween:Play()
									end)
								end
							end

							if not started then
								task.wait(1 / (UpdateRate and UpdateRate.Value or 60))
							end
						until (not Killaura.Enabled) or (not Animation or not Animation.Enabled)
					end)
				end

				repeat
					local attacked, sword, meta = {}, getAttackData()
					Attacking = false
					if store then store.KillauraTarget = nil end
					if sword then
						local plrs = entitylib.AllPosition({
							Range = SwingRange and SwingRange.Value or 28,
							Wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets and Targets.Players and Targets.Players.Enabled,
							NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled,
							Limit = MaxTargets and MaxTargets.Value or 5,
							Sort = sortmethods[Sort and Sort.Value or 'Distance']
						})

						if #plrs > 0 and entitylib.character and entitylib.character.RootPart then
							if switchItem then pcall(function() switchItem(sword.tool, 0) end) end
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

							for _, v in plrs do
								if not v.RootPart then continue end
								local delta = (v.RootPart.Position - selfpos)
								local flatDelta = delta * Vector3.new(1, 0, 1)
								local dot = localfacing:Dot(flatDelta.Unit)
								dot = math.clamp(dot, -1, 1)
								local angle = math.acos(dot)
								if angle > (math.rad(AngleSlider and AngleSlider.Value or 360) / 2) then continue end

								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > (AttackRange and AttackRange.Value or 28) and (BoxSwingColor or {Hue=0.6,Sat=1,Value=1,Opacity=0.5}) or (BoxAttackColor or {Hue=0.44,Sat=1,Value=1,Opacity=0.5})
								})
								if targetinfo and targetinfo.Targets then targetinfo.Targets[v] = tick() + 1 end

								if not Attacking then
									Attacking = true
									if store then store.KillauraTarget = v end
									if not Swing or not Swing.Enabled then
										if AnimDelay < tick() and (not LegitAura or not LegitAura.Enabled) then
											AnimDelay = tick() + (meta and meta.sword and meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed or 0.11)
											if bedwars.SwordController then
												pcall(function() bedwars.SwordController:playSwordEffect(meta, false) end)
											end
											if meta and meta.displayName and meta.displayName:find(' Scythe') and bedwars.ScytheController then
												pcall(function() bedwars.ScytheController:playLocalAnimation() end)
											end

											if Bad.ThreadFix then
												setthreadidentity(8)
											end
										end
									end
								end

								if delta.Magnitude > (AttackRange and AttackRange.Value or 28) then continue end

								local actualRoot = v.Character and v.Character.PrimaryPart
								if actualRoot then
									local dir = CFrame.lookAt(selfpos, actualRoot.Position).LookVector
									local pos = selfpos + dir * math.max(delta.Magnitude - 14.399, 0)
									if bedwars.SwordController then
										pcall(function() bedwars.SwordController.lastAttack = workspace:GetServerTimeNow() end)
									end
									if store then
										store.attackReach = (delta.Magnitude * 100) // 1 / 100
										store.attackReachUpdate = tick() + 1
									end

									pcall(function()
										AttackRemote:FireServer({
											weapon = sword.tool,
											chargedAttack = {chargeRatio = 0},
											entityInstance = v.Character,
											validate = {
												raycast = {
													cameraPosition = {value = pos},
													cursorDirection = {value = dir}
												},
												targetPosition = {value = actualRoot.Position},
												selfPosition = {value = pos}
											}
										})
									end)
								end
							end
						end
					end

					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity and attacked[i].Entity.RootPart or nil
						if v.Adornee and attacked[i] and attacked[i].Check then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end

					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity and attacked[i].Entity.RootPart and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end

					if Face and Face.Enabled and attacked[1] and attacked[1].Entity and attacked[1].Entity.RootPart and entitylib.character and entitylib.character.RootPart then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.001, vec.Z))
					end

					task.wait(#attacked > 0 and #attacked * 0.02 or 1 / (UpdateRate and UpdateRate.Value or 60))
				until not Killaura.Enabled
			else
				if store then store.KillauraTarget = nil end
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
				if inputService.TouchEnabled then
					pcall(function()
						if lplr.PlayerGui and lplr.PlayerGui:FindFirstChild('MobileUI') then
							lplr.PlayerGui.MobileUI['2'].Visible = true
						end
					end)
				end
				if oldSwing or (bedwars.SwordController and bedwars.SwordController.playSwordEffect) then
					pcall(function() debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, bedwars.Knit or {}) end)
				end
				if bedwars.ScytheController and bedwars.ScytheController.playLocalAnimation then
					pcall(function() debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, bedwars.Knit or {}) end)
				end
				Attacking = false
				if armC0 and gameCamera and gameCamera.Viewmodel then
					pcall(function()
						AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween and AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
							C0 = armC0
						})
						AnimTween:Play()
					end)
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 28,
		Default = 28,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 28,
		Default = 28,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	UpdateRate = Killaura:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	MaxTargets = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 5,
		Default = 5
	})
	Sort = Killaura:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	GUI = Killaura:CreateToggle({Name = 'GUI check'})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = Bad.gui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	Face = Killaura:CreateToggle({Name = 'Face target'})
	Animation = Killaura:CreateToggle({
		Name = 'Custom Animation',
		Function = function(callback)
			AnimationMode.Object.Visible = callback
			AnimationTween.Object.Visible = callback
			AnimationSpeed.Object.Visible = callback
			if Killaura.Enabled then
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = Killaura:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true,
		Visible = false
	})
	AnimationSpeed = Killaura:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true,
		Visible = false
	})
	AnimationTween = Killaura:CreateToggle({
		Name = 'No Tween',
		Darker = true,
		Visible = false
	})
	Limit = Killaura:CreateToggle({
		Name = 'Limit to items',
		Function = function(callback)
			if inputService.TouchEnabled and Killaura.Enabled then
				pcall(function()
					lplr.PlayerGui.MobileUI['2'].Visible = callback
				end)
			end
		end,
		Tooltip = 'Only attacks when the sword is held'
	})
	LegitAura = Killaura:CreateToggle({
		Name = 'Swing only',
		Tooltip = 'Only attacks while swinging manually'
	})
end)





