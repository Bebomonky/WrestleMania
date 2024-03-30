local function addBaseItem(self, id, device, path, icon, effect)
	local item = {}
	item.Device = device
	item.Name = path
	item.Icon = icon
	item.Effect = effect
	item.InEffect = false
	item.ApplyToActor = function() end
	item.OnReset = function() end
	item.ID = id
	item.Blacklisted = false

	self.BaseItemList[#self.BaseItemList + 1] = item

	return item
end

function WrestleMania:Load_Base_Items()
	self.CacheItemList = {}; self.BaseItemList = {}; self.DLCItemList = {}; self.CacheDLCItemList = {}

	local potion_of_heal = addBaseItem(self, "POH", CreateHDFirearm, "Potion of Healing", "Wrestling.rte/Health Icon", "Wrestle Mania - Regenerate Arms")

	function potion_of_heal:ApplyToActor()
		if self.FGArm == nil then self.FGArm = self.StoredFGArm end
		if self.BGArm == nil then self.BGArm = self.StoredBGArm end
	end

	local coffee = addBaseItem(self, "COF", CreateHDFirearm, "Coffee", "Wrestling.rte/JumpBoost Icon", "Wrestle Mania - JumpBoost")

	function coffee:ApplyToActor()
		self:SetNumberValue("MaxJumpForce", self:GetNumberValue("MaxJumpForce") + 5)
	end

	function coffee:OnReset()
		self:SetNumberValue("MaxJumpForce", 15)
	end

	addBaseItem(self, "BOMB_MAN_BOMB", CreateTDExplosive, "Wrestling.rte/Bomberman Bomb", nil, nil)

	local melon = addBaseItem(self, "MELON_REGEN", CreateHDFirearm, "Melon of Regeneration", "Wrestling.rte/Health Icon", nil)

	function melon:ApplyToActor()
		if self.FGArm == nil then self.FGArm = self.StoredFGArm end
		if self.BGArm == nil then self.BGArm = self.StoredBGArm end
		if self.FGLeg == nil then self.FGLeg = self.StoredFGLeg end
		if self.BGLeg == nil then self.BGLeg = self.StoredBGLeg end
	end
end

function WrestleMania:Load_Base_Categorys()

	self.BaseCharList =
	{	--22 Wrestlers MAX (Because of Page Button and Exit Button)
		"Wrestling.rte/El Luchador Muy Loco",
		"Wrestling.rte/Bomberman",
	}

	self.DisplayRandoChar = {}
	for _, BASE in pairs(self.BaseCharList) do
		table.insert(self.DisplayRandoChar, BASE)
	end

	self.BaseLevels = {}
	self.BaseLevels[1] = {"Stadium", "The Stadium", "Stadium Preview", "Wrestling.rte/Scenes/Maps/Stadium/Music/Speed_It_Up.ogg", "Stadium/Stadium.lua"}
	self.BaseLevels[2] = {"Volcano", "The Volcano", "Volcano Preview", "Wrestling.rte/Scenes/Maps/Volcano/Music/Uno_Aestas_Electro.ogg", "Volcano/Volcano.lua"}
	--self.BaseLevels[3] = {"Volcano Extended", "The Volcano\nExtended", "VolcanoExtended Preview", "Wrestling.rte/Scenes/Maps/Stadium/Music/Speed_It_Up.ogg", "Volcano Extended/Volcano Extended.lua"}

	for _, map in ipairs(self.BaseLevels) do
		self:AddLevel(map[1], map[2], map[3], map[4], map[5], map[6], map[7])
	end
end

function WrestleMania:AddLevel(scene, map_name, preview, song, custom_script)
	local new_level =
	{
		SceneName = scene,
		MapName = map_name,
		PreviewImage = preview,
		Music = song,
		Script = custom_script
	}
	table.insert(self.SceneData, new_level)
	return new_level
end

function WrestleMania:AddItem(id, device, path, icon, effect)
	local item = {}
	item.Device = device
	item.Name = path
	item.Icon = icon
	item.Effect = effect
	item.InEffect = false
	item.ApplyToActor = function() end
	item.OnReset = function() end
	item.ID = id
	item.Blacklisted = false

	return item
end

function WrestleMania:AddScore(player, num)
	self.PlayerScore[player] = self.PlayerScore[player] + num
end

function WrestleMania:GetScore(player)
	return self.PlayerScore[player]
end

function WrestleMania:GetSpawn(player)
	local spawn
	if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
		spawn = self.PlayerPos[self.Map.SceneName].Spawn[math.random(1, #self.PlayerPos[self.Map.SceneName].Spawn)]
	else
		spawn = Vector(self.PlayerPos[self.Map.SceneName].Spawn.X + (player * self.PlayerPos[self.Map.SceneName].Distance), self.PlayerPos[self.Map.SceneName].Spawn.Y)
	end
	return spawn
end

--This is the greatest CollectGibs of all time
function WrestleMania:CollectGibs()
	for gibs in MovableMan.Particles do
		if gibs.PresetName:find("Box Gib") then
			if ToMOSRotating(gibs):NumberValueExists("WMCrateGarbage") then
				self.GibsCount = self.GibsCount + 1
				ToMOSRotating(gibs):RemoveNumberValue("WMCrateGarbage")
			end
			if self.CleanGibsTimer:IsPastSimMS(self.GibsRemovalDelay) then
				for i = 1, self.GibsCount do --Grab all of it and then REMOVE IT MUAHAHAHAHAHA
					MovableMan:RemoveParticle(ToMOSRotating(gibs))
				end
			end
		end
	end

	if not self.CleanGibsTimer:IsPastSimMS(self.GibsRemovalDelay) then
		self.ResetGibsTimer:Reset()
	elseif self.ResetGibsTimer:IsPastSimMS(self.GibsRemovalDelay - 500) then
		self.GibsCount = 0
	end
	if self.GibsCount == 0 then
		self.CleanGibsTimer:Reset()
		self.ResetGibsTimer:Reset()
	end
end

-----------------------------------------------------------------------------------------
-- Scene Stuff
-----------------------------------------------------------------------------------------
local function UpdatePlayerPos(self)
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			for actor in MovableMan.Actors do
				if actor then
					if actor:IsInGroup("Wrestle Mania - Wrestler") then
						local closestActor = MovableMan:GetClosestActor(actor.Pos, 1, Vector(), actor)
						if closestActor then
							ExtensionMan.print_debug("TOO CLOSE! Updating Position for player... " .. player)
							--Update Wrestler spawn
							self.Spawns[player] = self:GetSpawn()
							actor.Pos = self.Spawns[player]
							self.MoveCollidedPlayers = true
						end
					end
				end
			end
		end
	end
end

function WrestleMania:CoreCreate_Idle()
	self:InitializeGameplayData()
	if self.Map.Script then
		self.LevelScript = self.Map.Script
		self.CurrentLevel = self:LoadModule(self.LevelScript:gsub( "%.lua$", ""), true)
		self.CurrentLevel:StartScript(self)
		print("Runnng Data Script for Scene: " .. self.Map.SceneName)
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
			ghost.PlayerControllable = true
			ghost.AIMode = Actor.AIMODE_SENTRY
			ghost.HUDVisible = false
			ghost:SetNumberValue("ViewerMode", 1)
			ghost:SetNumberValue("FixPosition", 1)
			ghost:AddToGroup("Wrestle Mania - Camera")
			self:SetScript(ghost, "Wrestling.rte/Actors/Shared/Scripts/Base/Spectator.lua", false)

			--for pie in ghost.PieMenu.PieSlices do ghost.PieMenu:RemovePieSlice(pie) end
			self.GhostPlayer[player] = ghost
			MovableMan:AddActor(ghost)
			self:SwitchToActor(ghost, player, team)

			self:SetupSpawns(player)
			self:CreateWrestler(player, true)
			self.DebugSpawn[player] = Vector(self.Spawns[player].X, self.Spawns[player].Y)
		end
	end
	self:StartGamemode()
	self.MoveCollidedPlayers = false
	AudioMan:PlayMusic("Base.rte/Music/dBSoundworks/ccambient4.ogg", -1, -1)
	self.CurrentSceneStage = self.SceneStage.Idle
end

function WrestleMania:CoreUpdate_Idle()

	if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
		if not self.MoveCollidedPlayers then
			UpdatePlayerPos(self)
		end
	end

	if UInputMan:KeyPressed(Key["O"]) then
		self:RestartViewer()
		self.ShouldStopUpdatingSpawn = false
		self.UpdatePlayerPosTimer:Reset()
	end

	if UInputMan:KeyPressed(Key["P"]) then
		self:CrateDrop(self.GameSettings.CrateRespawnTime)
	end

	if not self.ShouldStopUpdatingSpawn then
		if not self.UpdatePlayerPosTimer:IsPastSimMS(500) then --I think the shorter the better, why? incase I guess
			if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
				UpdatePlayerPos(self)
			end
		else
			self.ShouldStopUpdatingSpawn = true
		end
	end
	--I don't fucking know why but player 1 pos is broken so we fix!
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if self.GhostPlayer[player]:NumberValueExists("FixPosition") then
				self.GhostPlayer[player].Pos = Vector(320, 240)
				self.GhostPlayer[player]:RemoveNumberValue("FixPosition")
			end
			FrameMan:SetScreenText("Press O to Restart Viewer\nPress P to spawn crate", self:ScreenOfPlayer(player), 0, -1, false)
		end
	end
	self:CollectGibs()
end

function WrestleMania:RestartViewer()
	for actor in MovableMan.Actors do
		if actor then
			if not actor:IsInGroup("Wrestle Mania - Camera") then
				actor.ToDelete = true
			end
		end
	end
	--Reset table information
	--We assume this exist because how else are you going to play? lol
	table.Empty(self.PlayerPos[self.Map.SceneName])
	if self.Crates[self.Map.SceneName] then
		table.Empty(self.Crates[self.Map.SceneName])
	end
	if self.Spectators[self.Map.SceneName] then
		table.Empty(self.Spectators[self.Map.SceneName])
	end

	--Since modules automatically reload, we can update stuff on the fly!
	self.CurrentLevel = self:LoadModule(self.LevelScript:gsub( "%.lua$", ""), true)
	self.CurrentLevel:StartScript(self)

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self:SetupSpawns(player)
			self:CreateWrestler(player, true)
			self.DebugSpawn[player] = Vector(self.Spawns[player].X, self.Spawns[player].Y)
		end
	end
end

function WrestleMania:SetupSpawns(player)
	-- Wrestler spawns
	if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
		--Random
		self.Spawns[player] = self:GetSpawn()
		self.DisplaySpawns[player] = self.Spawns[player]
	else
		--Static
		self.Spawns[player] = self:GetSpawn(player)
		self.DisplaySpawns[player] = self.Spawns[player]
	end
end

function WrestleMania:CheckTimeLimit()
	if self.RunTime ~= 0 then return false end

	local winner = self:FindHighestScore()
	self:CoreVictory(winner)
	return true
end

function WrestleMania:GetDeathCount(player)
	return self.DeathCount[player]
end

function WrestleMania:SetSpawn(pos, dist)
	self.PlayerPos[self.Map.SceneName] = {

		Spawn = pos,
		Distance = dist ~= nil and dist or nil,
	}
end

function WrestleMania:SetCrate(crate, list)
	self.CrateName = crate
	self.Crates[self.Map.SceneName] = list
end

--This is the greatest SpawnSpectator of all time
function WrestleMania:SpawnSpectator(actor, pos, is_HFlipped)
	local npc = CreateAHuman(actor)
	npc.Team = -1
	npc.PlayerControllable = false
	npc:AddToGroup("Wrestle Mania - Spectator")
	npc.Pos = pos
	npc.HFlipped = is_HFlipped
	npc:GetController().InputMode = Controller.CIM_DISABLED
	MovableMan:AddActor(npc)

	--This works, fuck you
	if not self.Spectators[self.Map.SceneName] then
		self.Spectators[self.Map.SceneName] = {}
	end
	table.insert(self.Spectators[self.Map.SceneName], Vector(npc.Pos.X, npc.Pos.Y))
end

--This is the greatest FakeBanner of all time
function WrestleMania:FakeBanner(player, color, timer, text, direction)
	if timer:IsPastSimMS(string.len(text) * 1000) then
		self:GetBanner(GUIBanner[color], player):ShowText(text, direction, 1000, Vector(FrameMan.PlayerScreenWidth, FrameMan.PlayerScreenHeight), 0.5, 1500, 400)
		timer:Reset()
	end
end

--This is the greatest Debugging of all time
function WrestleMania:Debugging()
	if self.Crates[self.Map.SceneName] then
		for i = 1, #self.Crates[self.Map.SceneName] do
			local boxLocale = self.Crates[self.Map.SceneName][i]
			PrimitiveMan:DrawLinePrimitive(Vector(boxLocale, SceneMan.SceneHeight), Vector(boxLocale, 0), 13)
			PrimitiveMan:DrawTextPrimitive(Vector(boxLocale - 2, 0), i .. "\n " .. boxLocale, false, 0)
		end
	end
	if self.Spectators[self.Map.SceneName] then
		for i = 1, #self.Spectators[self.Map.SceneName] do
			local npcLocale = self.Spectators[self.Map.SceneName][i]
			PrimitiveMan:DrawBoxFillPrimitive(npcLocale, npcLocale + Vector(5, 5), 162)
			PrimitiveMan:DrawTextPrimitive(npcLocale - Vector(1, 10), tostring(i), false, 0)
		end
	end
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			if type(self.PlayerPos[self.Map.SceneName].Spawn) == "table" then
				for i, vect in pairs(self.PlayerPos[self.Map.SceneName].Spawn) do
					PrimitiveMan:DrawBoxFillPrimitive(vect, vect + Vector(5, 5), 244)
					PrimitiveMan:DrawTextPrimitive(vect, tostring(i), false, 0)
				end
			else
				local playerLocale = self.DebugSpawn[player]
				PrimitiveMan:DrawBoxFillPrimitive(playerLocale, playerLocale + Vector(5, 5), 244)
				PrimitiveMan:DrawTextPrimitive(Vector(playerLocale.X - 8, playerLocale.Y - 3.5), "Ply:" .. player, false, 0)
			end
		end
	end
end