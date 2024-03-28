-----------------------------------------------------------------------------------------
-- Start Activity
-----------------------------------------------------------------------------------------
function WrestleMania:CoreCreate()

	self:InitializeGameplayData()

	--Splitscreen pos
	local splitPos = self.Misc.Splitscreen_Resolution[self.PlayerCount ~= 2 and "Player_HUD_2P+" or "Player_HUD_2P"][FrameMan.PlayerScreenHeight]
	local splitMiddlePos = self.Misc.Splitscreen_Resolution[self.PlayerCount ~= 2 and "Center_HUD_2P+" or "Center_HUD_2P"][FrameMan.PlayerScreenHeight]

	local splitscreen_HudPos = splitPos and splitPos or Vector()
	local splitscreen_MiddlePos = splitMiddlePos and splitMiddlePos or Vector()

	--Multiplayer pos
	local res = self.Misc.Multiplayer_Resolution[FrameMan.PlayerScreenHeight]
	local multiplayer_HudPos = res and self.Misc.Multiplayer_Resolution[FrameMan.PlayerScreenHeight].Profile or Vector() --self.Misc.Multiplayer_Resolution[540].Profile
	local multiplayer_MiddlePos = res and self.Misc.Multiplayer_Resolution[FrameMan.PlayerScreenHeight].Middle or Vector() --self.Misc.Multiplayer_Resolution[540].Middle

	self.HudPos = self.IsMultiplayer and multiplayer_HudPos or splitscreen_HudPos

	self.MiddlePos = self.IsMultiplayer and multiplayer_MiddlePos or splitscreen_MiddlePos

	if self.Map.Script then
		self.LevelScript = self.Map.Script
		self.CurrentLevel = self:LoadModule(self.LevelScript:gsub( "%.lua$", ""), true)
		self.CurrentLevel:StartScript(self)
		print("Runnng Script for Scene: " .. self.Map.SceneName)
	else
		error("No Script found for Scene: " .. self.Map.SceneName .. " is it invalid?")
	end

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)

			local ghost = CreateActor("Base.rte/Null Actor")
			ghost.Pos = Vector(320, 240)
			ghost.Scale = 0
			ghost.Team = team

			--Incase for some reason they get hit by something? If yes it's so joever
			ghost.HitsMOs = false
			ghost.GetsHitByMOs = false
			ghost.PlayerControllable = false
			ghost.AIMode = Actor.AIMODE_SENTRY
			ghost.HUDVisible = false
			ghost:AddToGroup("Wrestle Mania - Camera")
			self:SetScript(ghost, "Wrestling.rte/Actors/Shared/Scripts/Base/Spectator.lua", false)

			--for pie in ghost.PieMenu.PieSlices do ghost.PieMenu:RemovePieSlice(pie) end
			self.GhostPlayer[player] = ghost
			MovableMan:AddActor(ghost)
			--self:SwitchToActor(ghost, player, team)

			self:SetupSpawns(player)

			self:CreateWrestler(player, false)

			self.IsDead[player] = false --doing self.GameChar[player]:IsDead() can be unreliable, it is also const for a little bit, we have a seperate table to check more effectively
			self.DeathCount[player] = 0

			--Timers
			self.RespawnTimer[player] = Timer()
			self.WaitTimer[player] = Timer()
			self.EffectTimer[player] = Timer()
			self.FakeWinTimer[player] = Timer()
			self.FakeFailTimer[player] = Timer()
			self.FakeDrawTimer[player] = Timer()
			self.WaitCount[player] = self.GameSettings.PlayerRespawnTime

			if not self.ProfileAlive[player] then self.ProfileAlive[player] = CreateMOSRotating(self.WrestlerIcon[player]) end
			if not self.ProfileDead[player] then self.ProfileDead[player] = CreateMOSRotating(self.DeadIcon[player]) end

			self.Winner[player] = false

			ExtensionMan.print_done("WrestlerData setup for Player " .. player)

			self.ItemIcons[player] = {}
			for i, item in pairs(self.ItemList) do
				if item then
					if item.Icon then
						self.ItemIcons[player][i] = CreateMOSRotating(item.Icon) --or CreateMOSRotating("Wrestling.rte/Missing Item Icon")
					end
				end
			end

			--Misc
			self.FunnyDeathTexts[player] = self:GetFunnyDeathTexts()
			self.CurrentFunnyText[player] = ""

			self:GetBanner(GUIBanner.YELLOW, player):ClearText()
			self:GetBanner(GUIBanner.RED, player):ClearText()
		end
	end

	self:StartGamemode()

	self.CurrentSceneStage = self.SceneStage.Gameplay
end

--This is the greatest CreateWrestler of all time
function WrestleMania:CreateWrestler(player, isDebug)
	if isDebug then
		self.GameChar[player] = CreateAHuman("Wrestling.rte/El Luchador Muy Loco")
		self.GameChar[player].Team = -1
		self.GameChar[player].Pos = self.Spawns[player]
		self.GameChar[player].HUDVisible = false

		--1984
		self.GameChar[player]:GetController().InputMode = Controller.CIM_DISABLED
		self.GameChar[player].PlayerControllable = false
		self.GameChar[player]:AddToGroup("Wrestle Mania - Wrestler")
		MovableMan:AddActor(self.GameChar[player])
		return
	end

	--Initialize module + Create actor
	self.GameChar[player] = self:LoadModule("Game/Player"):Initialize(self, CreateAHuman(self.SelectedWrestler[player]))
	--Initialize the actor
	self.GameChar[player]:Initialize()
	--TODO Either do self.GameChar[player]:StringValueExists("WrestlerScript") and self.GameChar[player]:GetStringValue("WrestlerScript") or "Wrestling.rte/Actors/Shared/Scripts/Base/WrestlerBase.lua"
	--TODO or have it done by gamemode!
	self:SetScript(self.GameChar[player], "Wrestling.rte/Actors/Shared/Scripts/Base/WrestlerBase.lua", false) --! Harcoded
	self.GameChar[player].Team = self:GetTeamOfPlayer(player)
	self.GameChar[player].Pos = self.Spawns[player]
	self.GameChar[player].MaxHealth = self.GameSettings.PlayerHealth * self.Config.HealthMultiplier
	self.GameChar[player].Health = self.GameSettings.PlayerHealth * self.Config.HealthMultiplier
	self.GameChar[player].HUDVisible = false

	--1984
	self.GameChar[player]:GetController().InputMode = Controller.CIM_DISABLED
	self.GameChar[player].PlayerControllable = false

	self.GameChar[player]:AddToGroup("Wrestle Mania - Wrestler")
	self.GameChar[player]:OnSpawn() --AddActor
end
-----------------------------------------------------------------------------------------
-- Update Activity
-----------------------------------------------------------------------------------------
function WrestleMania:CoreUpdate()
	if not self.GameSetup then
		--What we are doing during the Setup
		if not self.StartTime:IsPastSimMS(--[[self.Config.DebugMode and 100 or]] self.StartTimeDelay) then

			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					if self.GameChar[player] then
						CameraMan:SetScrollTarget(self.GameChar[player].Pos, 1, self:ScreenOfPlayer(player))
						self:SetActorSelectCursor(self.GameChar[player].Pos, player)
						self:SetObservationTarget(self.GameChar[player].Pos, player)
					end
					self:SetViewState(Activity.OBSERVE, player)
				end
			end

			--if not self.Config.DebugMode then
				--Countdown
				if self.GameCountDownTimer:IsPastSimMS(self.GameCountDownDelay) then
					if self.CountdownCount ~= 0 then
						self.SFXTracks[self.CountdownCount]:Play(self.CenterScene)
					end
					for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
						if self:PlayerActive(player) and self:PlayerHuman(player) then
							if self.CountdownCount ~= 0 then
								self:GetBanner(GUIBanner.YELLOW, player):ShowText(tostring(self.CountdownCount), GUIBanner.FLYBYLEFTWARD, 800,
								Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight + 100), 0.1, 99999, 25)
							end
						end
					end
					self.CountdownCount = self.CountdownCount - 1
					self.GameCountDownTimer:Reset()
				end
			--end

			--Reset the Timers to prevent issues
			self.ItemCrateTimer:Reset()
			self.CleanGibsTimer:Reset()
			self.ResetGibsTimer:Reset()
			self.GameTimer:Reset()

			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					self.RespawnTimer[player]:Reset()
					self.FakeWinTimer[player]:Reset()
					self.FakeFailTimer[player]:Reset()
					self.FakeDrawTimer[player]:Reset()
					self.GameChar[player]:ResetTimers()
				end
			end

			for actor in MovableMan.Actors do
				if actor then
					if actor:IsInGroup("Wrestle Mania - Wrestler") then
						if actor:NumberValueExists("GameSetup") then
							actor.PinStrength = 10000
							actor.Vel = Vector()
						end
					end
				end
			end

			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
						for actor in MovableMan.Actors do
							if actor then
								if actor:IsInGroup("Wrestle Mania - Wrestler") then
									local closestActor = MovableMan:GetClosestActor(actor.Pos, 1, Vector(), actor)
									if closestActor then
										ExtensionMan.print_debug("TOO CLOSE! Updating Position for player... " .. player)
										--Update Wrestler spawn
										self.Spawns[player] = self:GetSpawn()
										actor.Pos = self.Spawns[player]
									end
								end
							end
						end
					end
					--self.GameChar[player]:UpdateSetup()
				end
			end

			if (self.CurrentLevel and self.CurrentLevel.InitSetup) then
				self.CurrentLevel:InitSetup(self)
			end
		else
			--Mark that it's setup and that we shouldn't run this again after it's done.
			self.GameSetup = true
		end
	else
		if not self.GameStart then
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self:PlayerActive(player) and self:PlayerHuman(player) then
					local team = self:GetTeamOfPlayer(player)
					self.GameChar[player].PlayerControllable = true
					self:SwitchToActor(self.GameChar[player], player, team)
					self:GetBanner(GUIBanner.YELLOW, player):ShowText("GO!", GUIBanner.FLYBYLEFTWARD, 800, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.1, 99999, 25)
				end
			end
			self.SFXTracks[8]:Play(self.CenterScene)
			self.SFXTracks[4]:Play(self.CenterScene)
			AudioMan:PlayMusic(self.LevelMusic, -1, -1)
			self.GameStart = true
		end
	end

	--Game hasn't started
	if not self.GameStart then return end
	--Game has Started

	--Cheer on various occasions.
	self.TotalSpectators = 0
	self.TotalHealth = 0
	self.TotalWrestlers = 0

	if self.GameTimer:IsPastSimMS(1000) then
		self.GameTimer_Counter = self.GameTimer_Counter + 1
		self.GameTimer:Reset()
	end

	self.RunTime = self.GameLength - self.GameTimer_Counter
	self.IsDraw = false
	for actor in MovableMan.Actors do
		if actor then
			if actor:IsInGroup("Wrestle Mania - Wrestler") then
				if actor.PinStrength ~= 0 then
					actor.PinStrength = 0
				end
				self.TotalWrestlers = self.TotalWrestlers + 1
				self.TotalHealth = self.TotalHealth + actor.Health
			end
			if actor:IsInGroup("Wrestle Mania - Spectator") then
				self.TotalSpectators = self.TotalSpectators + 1
			end
			if actor:IsInGroup("Wrestle Mania - Container") then
				for team = Activity.TEAM_1, Activity.TEAM_4 do
					if self:TeamActive(team) then
						self:AddObjectivePoint("INCOMING CRATE!", actor.AboveHUDPos - Vector(0, 25), team, GameActivity.ARROWDOWN)
					end
				end
			end
		end
	end

	if self.LastTotalSpectators > self.TotalSpectators then
		self.SFXTracks[9]:Play(self.CenterScene)
	elseif self.LastTotalWrestlers > self.TotalWrestlers then
		self.SFXTracks[5]:Play(self.CenterScene)
	elseif self.LastTotalHealth - self.TotalHealth > 15 then
		self.SFXTracks[6]:Play(self.CenterScene)
	elseif self.LastTotalHealth - self.TotalHealth > 5 then
		self.SFXTracks[7]:Play(self.CenterScene)
	end

	self.LastTotalHealth = self.TotalHealth
	self.LastTotalSpectators = self.TotalSpectators
	self.LastTotalWrestlers = self.TotalWrestlers

	self:CrateDrop(self.GameSettings.CrateRespawnTime)

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)
			if self.MatchEnded then return end
			if self.RunTime ~= 0 then
				self:DrawBitmapText(player, string.ToMinutesSeconds(self.RunTime), self.MiddlePos)
			end
			self:UpdatePlayer(player, team)
			self:UpdatePlayerHUD(player, team)
		end
	end

	if (self.CurrentLevel and self.CurrentLevel.ActiveGame) then
		self.CurrentLevel:ActiveGame(self)
	end

	self:UpdateGamemode()
	if (self.CurrentLevel and self.CurrentLevel.UpdateScript) then
		self.CurrentLevel:UpdateScript(self)
	end

	--TODO Make condition for infinite time
	local gameTimerEnded = self:CheckTimeLimit()
	if not gameTimerEnded then
		self:CheckWinConditions()
	end
end

function WrestleMania:UpdatePlayerHUD(player, team)

	if not self.GameStart then return end
	--Actual Position
	local screen = self:ScreenOfPlayer(player)
	local profilePos = self.HUDHandler:MakeRelativeToScreenPos(screen, self.HudPos)
	local healthPos = profilePos + Vector(65, 14)
	local textPos = profilePos + Vector(26, -20)
	local hpFac = not self.IsDead[player] and math.max(math.min((self.GameChar[player].Health / self.GameChar[player].MaxHealth), 1), 0) or 0
	local xOffsetHP, yOffsetHP = Vector(45 * self.HUDHealth.Width, 0), Vector(0, 7 * self.HUDHealth.Height)

	PrimitiveMan:DrawBoxFillPrimitive(screen,
	healthPos - xOffsetHP - yOffsetHP,
	healthPos - xOffsetHP + Vector(xOffsetHP.X * 2, yOffsetHP.Y),
	self.HUDHealth.BackgroundColor
	)
	PrimitiveMan:DrawBoxPrimitive(screen,
	healthPos - xOffsetHP - yOffsetHP,
	healthPos - xOffsetHP + Vector(xOffsetHP.X * 2, yOffsetHP.Y),
	self.HUDHealth.OutlineBackgroundColor
	)
	PrimitiveMan:DrawBoxFillPrimitive(screen,
	healthPos - xOffsetHP - yOffsetHP,
	healthPos - xOffsetHP + Vector(xOffsetHP.X * 2 * hpFac, yOffsetHP.Y),
	self.HUDHealth.OutlineHealthColor
	)
	PrimitiveMan:DrawBoxPrimitive(screen,
	healthPos - xOffsetHP - yOffsetHP,
	healthPos - xOffsetHP + Vector(xOffsetHP.X * 2 * hpFac, yOffsetHP.Y),
	self.HUDHealth.HealthColor
	)
	PrimitiveMan:DrawBoxPrimitive(screen,
	healthPos - xOffsetHP - yOffsetHP,
	healthPos - xOffsetHP + Vector(xOffsetHP.X * 2 * hpFac, yOffsetHP.Y),
	self.HUDHealth.OutlineColor
	)

	if self.IsDead[player] then
		PrimitiveMan:DrawBitmapPrimitive(screen, profilePos, self.ProfileDead[player], 0, 0)
	else
		PrimitiveMan:DrawBitmapPrimitive(screen, profilePos, self.ProfileAlive[player], 0, 0)
	end

	PrimitiveMan:DrawTextPrimitive(screen, textPos, "TEAM: " .. team + 1, false, 0)

	--God have mercy on reading this code
	local lifeCount
	local text
	if self.LivesDisabled then
		text = self.IsDead[player] and self.CurrentFunnyText[player] or ""
		PrimitiveMan:DrawTextPrimitive(screen, textPos + Vector(0, 10), text, false, 0)
	else
		lifeCount = self:GetLives(player) > -1 and (self:GetLives(player) > 0 and "LIVES LEFT: " .. tostring(self:GetLives(player)) or "No Lives Left!")
		text = self.IsDead[player] and self.CurrentFunnyText[player] or not self.IsDead[player] and (lifeCount ~= nil and tostring(lifeCount) or "")
		PrimitiveMan:DrawTextPrimitive(screen, textPos + Vector(0, 10), text, false, 0)
	end

	local itemIconCount = 0 --This is better than using i
	for _, item in pairs(self.ItemList) do
		if item then
			if MovableMan:ValidMO(self.GameChar[player]) then
				if item.Effect then
					if self.GameChar[player]:GetNumberValue(item.Effect) > 0 then
						local itemPos = Vector(-10 + (35 * itemIconCount), 43)
						PrimitiveMan:DrawBitmapPrimitive(screen, profilePos + itemPos, self.ItemIcons[player][self.GameChar[player]:GetNumberValue(item.Effect)], 0, 0)
						itemIconCount = itemIconCount + 1
					end
				end
			end
		end
	end
end

function WrestleMania:UpdatePlayer(player, team)
	if MovableMan:ValidMO(self.GameChar[player]) then
		self.GameChar[player].OriginalPlayer = player
		self.GameChar[player]:Update()
	elseif (not MovableMan:ValidMO(self.GameChar[player]) or self.GameChar[player].Health <= 0) and not self.IsDead[player] then--elseif (self.GameChar[player]:IsDead() or not MovableMan:ValidMO(self.GameChar[player])) and not self.IsDead[player] then
		ExtensionMan.print_debug("PLAYER: " .. player + 1 .. " IS DEAD FROM TEAM: " .. team)

		local duration = 1500
		local yPos = 0.1

		self:GetBanner(GUIBanner.YELLOW, player):ShowText("KNOCK", GUIBanner.FLYBYLEFTWARD, duration,
		Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), yPos, 1000, 25)

		self:GetBanner(GUIBanner.RED, player):ShowText("OUT!", GUIBanner.FLYBYLEFTWARD, duration,
		Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), yPos + 0.17, 1000, 25)

		if not self.LivesDisabled then
			if self:GetLives(player) > -1 then
				self:RemoveLives(player, 1)
				ExtensionMan.print_debug("PLAYER: " .. player + 1 .. " HAS THIS MANY LIVES LEFT: " .. self:GetLives(player))
			end
		end

		-- Wrestler spawn
		self:SetupSpawns(player)

		self.CurrentFunnyText[player] = self.FunnyDeathTexts[player][math.random(1, #self.FunnyDeathTexts[player])]
		self.RespawnTimer[player]:Reset()
		self.WaitTimer[player]:Reset()
		self.WaitCount[player] = self.GameSettings.PlayerRespawnTime
		self.GhostPlayer[player]:SetNumberValue("PlayerIsDead", 1)

		self.DeathCount[player] = self.DeathCount[player] + 1
		self.IsDead[player] = true
	end

	if self.IsDead[player] then
		if self.WaitTimer[player]:IsPastSimMS(1000) then
			self.WaitCount[player] = self.WaitCount[player] - 1
			self.WaitTimer[player]:Reset()
		end
		FrameMan:SetScreenText(
		self:GetLives(player) > -1 and "S P E C T A T I N G\n Respawning In: " .. self.WaitCount[player] or "S P E C T A T I N G",
		player,
		self:GetLives(player) > -1 and 0 or 2000,
		-1,
		true)
		if not self.GhostPlayer[player]:IsPlayerControlled() then
			self.GhostPlayer[player].Pos = Vector(320, 240)
			self.GhostPlayer[player].PlayerControllable = true
			self:SwitchToActor(self.GhostPlayer[player], player, team)
		end
		local function respawnPlayer()
			self:AddObjectivePoint("YOUR\nSPAWN!", self.DisplaySpawns[player], team, GameActivity.ARROWDOWN)
			if self.RespawnTimer[player]:IsPastSimMS(self.GameSettings.PlayerRespawnTime * 1000) then
				self:CreateWrestler(player, false)
				self.GhostPlayer[player].PlayerControllable = false
				self.GameChar[player].PlayerControllable = true
				self:SwitchToActor(self.GameChar[player], player, team)
				self.IsDead[player] = false -- This will stop it from running multiple times
			end
		end
		if self.LivesDisabled or self.ForceLivesDisabled then
			respawnPlayer()
		else
			if self:GetLives(player) ~= -1 then
				respawnPlayer()
			end
		end
	else
		if self.GhostPlayer[player]:NumberValueExists("PlayerIsDead") then
			self.GhostPlayer[player]:RemoveNumberValue("PlayerIsDead")
		end
	end
end

local function createBox(name, pos)
	local crate = CreateACRocket(name or "Wrestling.rte/Wooden Crate")
	crate.Team = -1
	crate.Pos = pos
	crate.HitsMOs = false
	crate.GetsHitByMOs = false
	crate.IgnoresTeamHits = true
	crate.HUDVisible = false
	crate.PlayerControllable = false
	return crate
end
function WrestleMania:CrateDrop(spawntype)

	if self.ViewerMode then
		if self.Crates[self.Map.SceneName] then
			local pos = Vector(self.Crates[self.Map.SceneName][math.random(1, #self.Crates[self.Map.SceneName])], 0)
			local debug_crate = createBox(self.CrateName, pos)
			self:SetScript(debug_crate, "Wrestling.rte/Craft/Shared/GibOnTouch.lua", false)
			ExtensionMan.print_debug("DEBUG CRATE CREATED: " .. "POS: " .. tostring(debug_crate.Pos))
			MovableMan:AddActor(debug_crate)
		end
		return
	end

	--if self.GameSettings.CrateRespawnTime * 1000 <= 999 then return end

	if spawntype == "None" or table.IsEmpty(self.ItemList) then return end
	local dropTime = 0
	if spawntype == "High" then
		dropTime = self.Config.CrateHighTime or 9000
	elseif spawntype == "Normal" then
		dropTime = self.Config.CrateNormalTime or 15000
	elseif spawntype == "Low" then
		dropTime = self.Config.CrateLowTime or 25000
	end

	if self.ItemCrateTimer:IsPastSimMS(dropTime--[[self.GameSettings.CrateRespawnTime * 1000]]) then
		if self.Crates[self.Map.SceneName] then
			local pos = Vector(self.Crates[self.Map.SceneName][math.random(1, #self.Crates[self.Map.SceneName])], 0)
			local container = createBox(self.CrateName, pos)

			--Why do this instead of adding it to the Base? (Sometimes the Script doesn't pass through)
			--If you do have it, it'll just Enable it
			self:SetScript(container, "Wrestling.rte/Craft/Shared/GibOnTouch.lua", false)

			local item = self.ItemList[math.random(1, #self.ItemList)]

			container:AddInventoryItem(item.Device(item.Name))

			self:CrateInventory(container)

			ExtensionMan.print_debug("CONTAINER CREATED: " .. "POS: " .. tostring(container.Pos) .. " ITEM: " .. item.Name)
			MovableMan:AddActor(container)
			self.ItemCrateTimer:Reset()
		end
	end
	self:CollectGibs()
end

function WrestleMania:CrateInventory(container)
	for item in container.Inventory do
		if item:IsInGroup("Wrestle Mania - Consumable") then
			ExtensionMan.print_debug("Giving Script to Consumable")
			self:SetScript(item, "Wrestling.rte/Devices/Shared/Consumable.lua", false)

		--[[
		elseif item:IsInGroup("Wrestle Mania - Throwable") then

			if item:IsInGroup("Wrestle Mania - Explosive") then
				ExtensionMan.print_debug("Giving Script to Explosive")

			elseif item:IsInGroup("Wrestle Mania - BombermanCollection") then
				ExtensionMan.print_debug("Giving Script to Bomberman Collection Bombs")
				self:SetScript(item, "Wrestling.rte/Devices/Shared/Bomb.lua", false)

			end
		]]
		end
	end
end

-----------------------------------------------------------------------------------------
-- End Activity
-----------------------------------------------------------------------------------------
--WIN GO RIGHT
--FAIL GOES LEFT

function WrestleMania:CoreEnd()
	AudioMan:StopMusic(); AudioMan:ClearMusicQueue()

	--Switch the players back to their Camera.
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)
			self:GetBanner(GUIBanner.YELLOW, player):ClearText()
			self:GetBanner(GUIBanner.RED, player):ClearText()

			local wrestler = self:GetControlledActor(player)
			self:SetScript(wrestler, "Wrestling.rte/Actors/Shared/Scripts/Base/WrestlerBase.lua", true)
			wrestler.PlayerControllable = false

			self.GhostPlayer[player].PlayerControllable = true
			self.GhostPlayer[player]:RemoveNumberValue("PlayerIsDead")
			self.GhostPlayer[player]:SetNumberValue("GameEnded", 1)
			self:SwitchToActor(self.GhostPlayer[player], player, team)
		end
	end
	if (self.CurrentLevel and self.CurrentLevel.EndScript) then
		self.CurrentLevel:EndScript(self)
	end
end
function WrestleMania:CoreUpdate_End()
	--if not self.MatchEnded then return end

	if self.IsDraw then
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				self:FakeBanner(player, "RED", self.FakeDrawTimer[player], "DRAW", GUIBanner.FLYBYLEFTWARD)
			end
		end
	else
		for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
			if self:PlayerActive(player) and self:PlayerHuman(player) then
				if self.Winner[player] then
					self:FakeBanner(player, "YELLOW", self.FakeWinTimer[player], "WINNER", GUIBanner.FLYBYRIGHTWARD)
				else
					self:FakeBanner(player, "RED", self.FakeFailTimer[player], "LOSER", GUIBanner.FLYBYLEFTWARD)
				end
			end
		end
	end

	if (self.CurrentLevel and self.CurrentLevel.UpdateEndScript) then
		self.CurrentLevel:UpdateEndScript(self)
	end

	if self.GhostPlayer[0]:IsPlayerControlled() then
		if self.GhostPlayer[0]:GetController():IsState(Controller.WEAPON_FIRE) then
			self:StartActivity() --:sunglasses:
		else
			FrameMan:SetScreenText("Press FIRE/ACTIVATE to restart", self:ScreenOfPlayer(0), 2000, -1, false);
		end
	end
end
function WrestleMania:CoreVictory(player)
	if not self.MatchEnded then
		self:HideHud(false); self.ShouldShowHud = true

		if player == -1 then
			ExtensionMan.print_debug("NO WINNERS")
			if (self.CurrentLevel and self.CurrentLevel.Draw) then
				self.CurrentLevel:Draw(self)
			end
			self.SFXTracks[10]:Play(self.CenterScene)
		else
			if (self.CurrentLevel and self.CurrentLevel.Victory) then
				self.CurrentLevel:Victory(self)
			end
			self.SFXTracks[8]:Play(self.CenterScene)
			self.SFXTracks[11]:Play(self.CenterScene)
			self.Winner[player] = true
			--self.WinnerTeam = team
			--ExtensionMan.print_debug("TEAM " .. team .. " HAS WON!")
			--ActivityMan:EndActivity()
		end
		self:CoreEnd()
		self.CurrentSceneStage = self.SceneStage.End
		self.MatchEnded = true
	end
end
-----------------------------------------------------------------------------------------
-- Miscellaneous
-----------------------------------------------------------------------------------------

--We call this regardless for both idle and gameplay, so we don't have duplicate information? Also it's better to have this either way incase we need it
function WrestleMania:InitializeGameplayData()
	AudioMan:StopMusic(); AudioMan:ClearMusicQueue()

	--The actual values that are in the save file are indexs, we fix em here
	--k is getting the name of it (EX: LivesDisabled)
	--v is getting the value of it (EX: value of LivesDisabled = false or true)
	--look at Settings.save to know what I mean!
	self.GameSettings = self.SLS:GetDataFile().GameOptions
	for k, v in pairs(self.GameSettings) do
		if (type(v) ~= "boolean" and type(v) ~= "table") and not string.find(k, "Volume") then
			self.GameSettings[k] = self.SLS[k][self.SLS.Cache.GameOptions[k] + 1]
		end
	end

	for i, map in pairs(self.SceneData) do
		if SceneMan.Scene.PresetName == map.SceneName then
			self.Map = table.Copy(map)
			break
		end
	end
	--Scene Info
	self.LevelMusic = ""
	self.CenterScene = Vector(SceneMan.SceneWidth / 2, SceneMan.SceneHeight / 2) --Center of the Scene
	self.MatchEnded = false --Whether the Match has ended.
	self.LevelMusic = self.Map.Music ~= nil and self.Map.Music or "Base.rte/Music/dBSoundworks/ccambient4.ogg"

	self.PlayerPos = {} --for player spawns positions
	self.Spectators = {} --Actors with Controller.CIM_DISABLED
	self.GhostPlayer = {} -- CreateActor() Camera

	self.ItemList = {}
	for _, item in pairs(self.CacheItemList) do
		table.insert(self.ItemList, item)
	end

	self.StartTime = Timer() --Time since the match has started.  This way music can be set and AI can be told to stay in place.

	--Countdown Info
	self.GameCountDownTimer = Timer()
	self.GameCountDownDelay = 1120 --Time in Milliseconds until Game Starts
	self.CountdownCount = 3

	self.StartTimeDelay = 4500 --Time during Setup

	--Cheers
	self.LastTotalSpectators = 0 --The amount of other actors last frame.
	self.LastTotalHealth = 0 --The total health last frame.
	self.LastTotalWrestlers = 0 --The amount of wrestlers last frame.

	--Game Information
	self.GameSetup = false --What happens pre game
	self.GameStart = false --Whether the round has started.

	--Game Time Information
	self.GameTimer = Timer()
	self.GameTimer_Counter = 0
	self.GameLength = self.Menu.TimerLength ~= "" and (tonumber(self.Menu.TimerLength)) or self.GameSettings.MatchTime * 60

	self.LivesDisabled = self.ForceLivesDisabled ~= nil and self.ForceLivesDisabled or self.GameSettings.LivesDisabled

	--Garbage Info
	self.CleanGibsTimer = Timer()
	self.ResetGibsTimer = Timer()
	self.GibsCount = 0
	self.GibsRemovalDelay = 1000 --Time in Milliseconds until Gibs removed

	--Information per player
	self.GameChar = {} -- AHuman() Current Actor
	self.Spawns = {} -- Vector() Actor Location
	self.DisplaySpawns = {} -- Vector() NEW Actor Location
	self.IsDead = {} -- Bool
	self.DeathCount = {} -- Number
	self.RespawnTimer = {} -- Timer()
	self.WaitTimer = {} -- Timer()
	self.WaitCount = {} -- Number
	self.ProfileAlive = {} -- MOSRotating() Alive
	self.ProfileDead = {} -- MOSRotating() Dead
	self.ItemIcons = {} -- MOSRotating() Active Item
	self.EffectTimer = {}
	self.FakeWinTimer = {}
	self.FakeFailTimer = {}
	self.FakeDrawTimer = {}
	self.Winner = {}

	--Crate stuff
	self.Crates = {} --For crate spawn positions
	self.ItemCrateTimer = Timer() -- Timer for when Item Crates are deployed

	--Refer to Palette Index if you want to customize this
	self.HUDHealth = {
		BackgroundColor = 13,
		OutlineBackgroundColor = 254,
		OutlineHealthColor = 122,
		HealthColor = 122,
		OutlineColor = 254,
		Width = 1,
		Height = 1.5
	}

	--Debugging
	self.DebugSpawn = {}
	self.UpdatePlayerPosTimer = Timer()
	self.ShouldStopUpdatingSpawn = true

	--The Funny
	self.FunnyDeathTexts = {}
	self.CurrentFunnyText = {}
end
function WrestleMania:SetScript(actor, script, disable)
	if disable then
		if actor:HasScript(script) then
			actor:DisableScript(script)
		end
	else
		if actor:HasScript(script) then
			actor:EnableScript(script)
		else
			actor:AddScript(script)
		end
	end
end

function WrestleMania:GetFunnyDeathTexts()
	return
	{
		"RTE Aborted! (x_x)", "LMAO", "WHAT???", "WTF", ":V",
		"HOW???", "LOL", "ZZZZ....", "DESTROYED", "CRUSHED",
		"WTF", "?WDJALWDWDAWD", "AbortScreen.bmp", "CAUGHT IN 4K", "Runtime Error",
		"look sir, free crabs!", "DIRT", "Cortec Coma", "Can we pretend that airplanes...",
		"OMGGGGGG", "The CrabNADO!", "Also Check Weegee Mods!", "BASED????", "\xC2Data Realms!\xC2",
		"\xD9\xD9\xD9\xD9\xD9", "Day Is Ruined...", "RTE CATASTROPHIC ERROR!!! (X_X)",
	}
end