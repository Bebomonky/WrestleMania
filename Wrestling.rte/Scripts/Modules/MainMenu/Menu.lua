-----------------------------------------------------------------------------------------
-- Menu
-----------------------------------------------------------------------------------------
local menu = {}

function menu:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function menu:Initialize(activity)
	self.Activity = activity
	self.BASE_PATH = self.Activity.ModuleName .. "/"

	self.Config = self.Activity.Config
	self.SLS = self.Activity.SLS

	self:InitializeTables()
	self:LoadMenu()
	self:SpawnActors()
	ExtensionMan.print_done("Main Menu")
end

function menu:InitializeTables()

	--DrawText
	self.Activity.LetterMap =
	{
		A = 0,
		B = 1, C = 2, D = 3, E = 4, F = 5,
		G = 6, H = 7, I = 8, J = 9, K = 10,
		L = 11, M = 12, N = 13, O = 14, P = 15,
		Q = 16, R = 17, S = 18, T = 19, U = 20,
		V = 21, W = 22, X = 23, Y = 24, Z = 25,
		[" "] = 26,
		["0"] = 27, ["1"] = 28, ["2"] = 29, ["3"] = 30, ["4"] = 31, ["5"] = 32, ["6"] = 33, ["7"] = 34, ["8"] = 35, ["9"] = 36,
		["!"] = 37, ["'"] = 38, ["#"] = 39, ["$"] = 40, ["%"] = 41, ["&"] = 42, ["."] = 43, [":"] = 44, ["?"] = 45, ["_"] = 46, ["/"] = 47,
	}

	--Input per player
	self.ctlr = {}
	self.lastInputVector = {}
	self.lastInputPress = {}
	self.lastReturnInputPress = {}
	self.InputPress = {}
	self.ReturnInputPress = {}
	self.JustPressed = {}
	self.InputVector = {}

	--Actor
	self.SceneChar = {}
	self.Cursors = {}

	--Actor.Age
	self.randomFacA = {}
	self.randomFacB = {}
	self.randomFacC = {}

	--CharacterSelect
	self.Activity.SelectedWrestler = {}
	self.Activity.WrestlerIcon = {}
	self.Activity.DeadIcon = {}
	self.OnCharacterMenu = {}

	--BASE
	self.BaseActor = {}
	self.BaseAHuman = {}
	self.BaseIcon = {}

	--Scenes
	self.Activity.SceneStage = { Menu = 0, Gameplay = 1, Idle = 2, Over = 3 }

	self.Activity.PlayerPos = {}
	self.Activity.SceneData = {}

	--SelectLevel
	--BASE
	self.BackToSelectLevel = {}
	self.BasePreview = {}
	self.BaseMap = {}

	--DLC
	self.CharCategory = {}
	self.DLCActor = {}
	self.DLCAHuman = {}
	self.DLCIcon = {}

	--DLC
	self.LevelCategory = {}
	self.DebugLevelCategory = {}
	self.DLCPreview = {}
	self.DLCMap = {}

	--BASE
	self.BaseItem = {}
	self.BaseDevice = {}
	self.BaseItemIcon = {}

	--DLC
	self.ItemCategory = {}
	self.DLCItem = {}
	self.DLCDevice = {}
	self.DLCItemIcon = {}

	--Player Status
	self.Lockedin = {}

	--Menu
	self.MenuData = {}
	self.MenuCenter = {}
	self.MenuHistory = {} --Keep a history on how to return backwards
	self.MenuCurrent = {}
	self.MenuPos = {}
	self.MenuActor = {}
	self.MenuActorUID = {}
	self.MenuCurrentButton = {}
	self.MenuSelectAnimationFactor = {}
	self.TempText = {}
	self.BlacklistedReturns = {}
	self.TempMessages =
	{
		"Save Settings?",
		"Return Back?",
		"Reset Game Options?",
		"Reset Options?",
		"Picked the right map to view?"
	}

	--Audio
	self.Activity.SFXTracks = {}
	for i, Track in pairs(self.Activity.Misc.SoundList) do
		self.Activity.SFXTracks[i] = CreateSoundContainer("Wrestling.rte/" .. Track)
	end

	--I can't figure out how to make the buttonPos not retarded
	--This is for fixed buttons of maps
	self.FixedBackTable = {
		[-1] = 10,
		[0] = 10,
		[1] = 10,
		[2] = 10, --30 when view pages
		[3] = 30,
		[4] = 40,
		[5] = 40,
		[6] = 60
	}

	self.FixedPageTable = {
		[0] = 10,
		[1] = 10,
		[2] = 10,
		[3] = 10,
		[4] = 40,
		[5] = 40,
		[6] = 60
	}
	--Unused
	--self.LevelList = {}
end

function menu:MenuOnMenuChange(player, newMenu, skip, isback)
	self.MenuCurrentButton[player] = 0

	if not skip then --An extra layer so that it works with BlacklistedReturns table
		table.insert(self.MenuHistory[player], self.MenuCurrent[player])
	end

	--If it is a back button, then we must decrement the history to prevent stacking
	if isback then
		table.remove(self.MenuHistory[player])
	end
	self.MenuCurrent[player] = newMenu
end

function menu:PlayerMovement(player, giveinput)
	if giveinput then
		self.InputVector[player] = Vector(
			(self.ctlr[player]:IsState(Controller.MOVE_RIGHT) and 1 or 0) - (self.ctlr[player]:IsState(Controller.MOVE_LEFT) and 1 or 0),
			(self.ctlr[player]:IsState(Controller.BODY_CROUCH) and 1 or 0) - (self.ctlr[player]:IsState(Controller.BODY_JUMP) and 1 or 0)
		)
	else
		self.InputVector[player] = Vector()
	end
end

function menu:TempTextDisplay(player, text)
	PrimitiveMan:DrawTextPrimitive(self.Activity:ScreenOfPlayer(player),
	self.MenuPos[player] + Vector(0, FrameMan.PlayerScreenHeight * -0.5 + 95 + (self.LogoSpriteBig and 41 or -4)),
	text,
	false,
	1)
end

function menu:InsertCodeDisplay(condition, color, direction, custom_text, custom_textPos)
	self.Activity:HideHud(not condition)
	if condition then
		self.Activity:GetBanner(GUIBanner[color], 0):ShowText(custom_text, GUIBanner[direction], 99999 * 99,
		Vector(FrameMan.PlayerScreenWidth + custom_textPos.X, FrameMan.PlayerScreenHeight), custom_textPos.Y, 99999, 9999)
	else
		self.Activity:GetBanner(GUIBanner[color], 0):ClearText()
	end
end

local function getSoundList(BASE_PATH)
	local soundList = {}
	soundList.MenuSwitch = CreateSoundContainer(BASE_PATH .. "WM Switch")
	soundList.MenuSwitch.Volume = 2
	soundList.MenuSelect = CreateSoundContainer(BASE_PATH .. "WM Select")
	soundList.MenuSelect.Volume = 4

	soundList.MenuMove = CreateSoundContainer(BASE_PATH .. "WM Scroll")
	soundList.MenuMove.Volume = 1
	soundList.MenuMove.Pitch = 4

	soundList.DefaultError = CreateSoundContainer("Base.rte/Error")

	--[[
	soundList.Confirm = CreateSoundContainer(BASE_PATH .. "WM Confirm")
	soundList.Confirm.Pitch = 2
	soundList.Confirm.Volume = 2
	]]

	soundList.Access = CreateSoundContainer(BASE_PATH .. "WM Access")
	soundList.Access.Pitch = 3
	soundList.Access.Volume = 2

	soundList.Error = CreateSoundContainer(BASE_PATH .. "WM Error")
	soundList.Error.Volume = 2
	soundList.Error.Pitch = 3

	soundList.SecretKey = CreateSoundContainer(BASE_PATH .. "WM Secret Key")
	soundList.SecretKey.Volume = 2
	soundList.SecretKey.Pitch = 2.5

	soundList.InputVoice = CreateSoundContainer(BASE_PATH .. "WM Input Code Voice_1")
	soundList.InputVoice.Volume = 5
	soundList.InputVoice.Pitch = 1

	soundList.InputVoice_2 = CreateSoundContainer(BASE_PATH .. "WM Input Code Voice_2")
	soundList.InputVoice_2.Volume = soundList.InputVoice.Volume
	soundList.InputVoice_2.Pitch = 1

	soundList.InputVoice_3 = CreateSoundContainer(BASE_PATH .. "WM Input Code Voice_3")
	soundList.InputVoice_3.Volume = soundList.InputVoice.Volume
	soundList.InputVoice_3.Pitch = 1

	soundList.InputVoice_4 = CreateSoundContainer(BASE_PATH .. "WM Input Code Voice_4")
	soundList.InputVoice_4.Volume = soundList.InputVoice.Volume
	soundList.InputVoice_4.Pitch = 1

	--Funny
	soundList.Debug = CreateSoundContainer("Base.rte/Human Death")
	soundList.Debug.Volume = 5

	return soundList
end

function menu:LoadMenu()
	AudioMan:StopMusic(); AudioMan:ClearMusicQueue()
	AudioMan:PlayMusic("Wrestling.rte/Scenes/Maps/Menu/Music/main-menuV2.ogg", -1, -1)

	self.FlipDirection = false
	self.FloatDirection = math.random(0, 1) == 0 and -1 or 1
	for BG in SceneMan.Scene.BackgroundLayers do
		BG.AutoScrollStepX = self.FloatDirection - -self.FloatDirection
	end

	--Pages
	self.PageLevelCount = 0
	self.PageCharCount = 0
	self.PageItemCount = 0

	if self.Activity.IsMultiplayer then
		self.LogoSpriteBig = CreateMOSRotating(self.BASE_PATH .. "Wrestle Mania Logo Big")
		self.LogoSize = self.LogoSpriteBig
	else
		if FrameMan.PlayerScreenHeight * 2 >= 720 then
			self.LogoSpriteBig = CreateMOSRotating(self.BASE_PATH .. "Wrestle Mania Logo Big")
			self.LogoSize = self.LogoSpriteBig
		else
			self.LogoSpriteSmall = CreateMOSRotating(self.BASE_PATH .. "Wrestle Mania Logo Small")
			self.LogoSize = self.LogoSpriteSmall
		end
	end

	self.GameNavigator = Activity.PLAYER_1 -- Don't touch this!

	self.Sound = getSoundList(self.BASE_PATH)

	self.MenuIntroFactor = 0
	self.MenuOutroFactor = 0

	self.SceneToLoad = nil
	self.ScriptToLoad = nil
	self.GamemodeToLoad = nil

	self.InitiateGame = false

	--For Viewonly scenes
	self.IgnoreCharacterSelect = false
	self.CanReturn = true

	--? Settings Data (Read / Create and write to file)
	self.SLS:LoadDataFile(self.Activity)

	--? Load all possible Data
	self.SLS:LoadSettings()
	self.SLS:LoadGameSettings()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			local team = self.Activity:GetTeamOfPlayer(player)
			self.Activity:SetTeamFunds(0, team)

			--Input
			self.lastInputVector[player] = Vector(0, 0)
			self.lastInputPress[player] = false
			self.lastReturnInputPress[player] = false

			--Mods
			self.OnCharacterMenu[player] = false

			--Scenes
			self.BackToSelectLevel[player] = false
			self.Lockedin[player] = false

			--CharacterSelect
			self.Activity.SelectedWrestler[player] = ""
			self.Activity.WrestlerIcon[player] = ""
			self.Activity.DeadIcon[player] = ""

			--Menu
			if self.Activity.IsMultiplayer then
				self.MenuCenter[player] = Vector(SceneMan.SceneWidth, SceneMan.SceneHeight) * 0.5
			else
				self.MenuCenter[player] = Vector(SceneMan.SceneWidth, SceneMan.SceneHeight - (FrameMan.PlayerScreenHeight * 2 == 720 and 920 or 1007)) * 0.5
			end
			self.MenuData[player] = self:BuildMenu(player)

			--Menus that you cannot return from
			--This is to help prevent players from breaking the menu

			if player == self.GameNavigator then
				self.BlacklistedReturns[player] = {
					"ResetGSettings",
					"SaveOptions",
					"ReturnToSelectLevel",
					"SaveOptions",
					"ResetOptions",
					"DebugLevelConfirm"
				}
			else
				self.BlacklistedReturns[player] = {
					"CharacterSelect"
				}
			end
			self.MenuHistory[player] = {}
			self.MenuCurrent[player] = self.MenuData[player].Main
			self.MenuCurrentButton[player] = 0
			self.MenuSelectAnimationFactor[player] = 0
			self.TempText[player] = 0
		end
	end

	--Debug Stuff
	self.InputCombo = false
	self.ButtonSwitch = false

	self.SpawnFloatyGuyTimer = Timer()
	self.InputComboTimer = Timer() --500 Seconds after to complete so it doesn't look weird I guess?
	self.DebugMusicTimer = Timer()
	self.PalettePhaseTimer = Timer()
	self.PalettePhaseCount = 1
	self.DebugModeActivated = false

	self.Activity:InitCustomPalette()
	self.Activity:LoadNewPalette(1)
	self.TimerLength = ""

	self.MenuFlybyAnimation = 0

	self.Activity:Load_Base_Categorys() --Maps and Wrestler

	self:NavigatorButtons(self.GameNavigator)

	self:CharacterButtons()
	self.Activity.CurrentSceneStage = self.Activity.SceneStage.Menu

	self:InsertKeyToAllButtons(self.GameNavigator, "JustPress")
end

function menu:Update()
	--[[
	if not self.Activity.Config.DebugMode then
		for k, v in pairs(self.MenuData[self.GameNavigator].Main.Buttons) do
			if v.Text == "DEBUG MODE" then
				print("YPPIE")
			end
		end
	end
	]]
	self.Activity:UpdateGameOnPause(self.PalettePhaseCount)
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then

			if self.MenuActorUID[player] then
				if not MovableMan:FindObjectByUniqueID(self.MenuActorUID[player]) then
					self.MenuActor[player] = nil
				end
			else
				self.MenuActorUID[player] = nil
			end
		end
	end

	if self.Activity.Config.DebugMode then
		if self.DebugMusicTimer:IsPastSimMS(300) then
			if not self.DebugModeActivated then
				self:OnDebugModeActivation()
				self.DebugModeActivated = true
			end
		end
		if self.PalettePhaseCount ~= #self.Activity.PaletteList and self.PalettePhaseTimer:IsPastSimMS(950) then
			self.PalettePhaseCount = self.PalettePhaseCount + 1
			self.Activity:LoadNewPalette(self.PalettePhaseCount)
			self.PalettePhaseTimer:Reset()
		end
	end

	self.MenuIntroFactor = math.min(self.MenuIntroFactor + TimerMan.DeltaTimeSecs * 0.3, 1)
	self.MenuFlybyAnimation = (self.MenuFlybyAnimation - TimerMan.DeltaTimeSecs * 3) % 2

	local allLockedIn = true
	for player, checkedIn in pairs(self.Lockedin) do
		if not checkedIn then
			allLockedIn = false
			break
		end
	end

	--!It has to be constantly true or else it fucking kills itself
	--if self.Activity.ViewerMode then
		--self.InitiateGame = true
	--else
		if allLockedIn and not self.InitiateGame then
		    self.InitiateGame = true
		end
	--end

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			local team = self.Activity:GetTeamOfPlayer(player)
			local screen = self.Activity:ScreenOfPlayer(player)

			self.MenuPos[player] = self.MenuCenter[player] + Vector(0, -FrameMan.PlayerScreenHeight * -1.5 * math.pow(1 - self.MenuIntroFactor, 3))
			+ Vector(0, FrameMan.PlayerScreenHeight * 1.1 * math.pow(self.MenuOutroFactor, 3))
			if self.InitiateGame then
				if self.SceneToLoad then
					self.MenuOutroFactor = math.min(self.MenuOutroFactor + TimerMan.DeltaTimeSecs, 3)
					if self.MenuOutroFactor > 1.99 then
						self.Activity:LaunchLevel(self.SceneToLoad, self.ScriptToLoad, self.GamemodeToLoad)
					end
				end
			end
			if self.MenuActor[player] then
				self:MenuLogic(screen, player, team)
			end
		else
			CameraMan:SetScrollTarget(Vector(0, 1000), 1, player)
		end
	end

	--Refer to CheckItemLists() to know more
	if self.SLS.RemovingNonExistantItems and self.SLS.SaveTimer:IsPastSimTimeLimit() then
		self.SLS:SaveSettings(1)
		self.SLS.RemovingNonExistantItems = false
		ExtensionMan.print_done("Non existant ID's should be fleshed out! [If you see this more than once REPORT IT!]")
	end

	self:ButtonLogic()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		local screen = self.Activity:ScreenOfPlayer(player)
		if self.MenuActor[player] then
			if self.MenuCurrent[player] == self.MenuData[player].Info then
				for i, line in ipairs(self.MenuCurrent[player].Text) do
					PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(0, 15 + 14 * (i - 1) + self.MenuCurrent[player].InfoTextOffsetY), line, false, 1)
				end
			end

			if self.MenuCurrent[player] == self.MenuData[player].Credits then
				local lines = {}

				for i, line in ipairs(self.MenuCurrent[player].Text) do
					if i > self.MenuCurrent[player].TextScroll and #lines < self.MenuCurrent[player].TextScrollMaxLines then
						table.insert(lines, line)
					end
				end

				for i, line in ipairs(lines) do
					PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(0, 15 + 14 * (i - 1) + self.MenuCurrent[player].TextScrollOffsetY), line, false, 1)
				end
			end
		end
	end
end

function menu:MenuLogic(screen, player, team)
	if self.SpawnFloatyGuyTimer:IsPastSimMS(40000 * RangeRand(0.2, 5)) then
		self:SpawnFloater(player, nil)
		self.SpawnFloatyGuyTimer:Reset()
	end

	self.randomFacA[player] = math.sin(self.SceneChar[player].Age / 1000) * 0.75
	+ math.cos(self.SceneChar[player].Age / 2000 + 5)
	+ math.cos(-self.SceneChar[player].Age / 500 + 1) * 0.5
	+ math.sin(-self.SceneChar[player].Age / 3000 + 15) * 2
	+ math.sin(self.SceneChar[player].Age / 9000 + 99) * 2
	self.randomFacB[player] = math.sin(self.SceneChar[player].Age / 1100 + 15) * 0.6
	+ math.cos(self.SceneChar[player].Age / 1700 - 77) * 0.4
	+ math.cos(-self.SceneChar[player].Age / 600 + 1) * 0.8
	+ math.sin(-self.SceneChar[player].Age / 3500 + 66) * 1.5
	+ math.sin(-self.SceneChar[player].Age / 8000 + 59) * 2
	self.randomFacC[player] = math.sin(self.SceneChar[player].Age / 800 - 5) * 0.6
	+ math.sin(self.SceneChar[player].Age / 1700 - 77) * 0.4
	+ math.cos(-self.SceneChar[player].Age / 1300 + 55) * 0.7
	+ math.cos(-self.SceneChar[player].Age / 600 + 5) * 1.1
	+ math.sin(-self.SceneChar[player].Age / 8000 + 3) * 1.5

	if self.SceneChar[player]:IsPlayerControlled() then
		self.Activity:SwitchToActor(self.MenuActor[player], player, team)
	end

	if not self.SceneCharXOffset then
		self.SceneCharXOffset = {}
		self.SceneCharXOffset[0] = -190
		self.SceneCharXOffset[1] = 190
		self.SceneCharXOffset[2] = 150
		self.SceneCharXOffset[3] = -150
	end

	self.SceneChar[player].Pos = self.MenuCenter[player] + Vector(self.SceneCharXOffset[player], self.Activity.IsMultiplayer and 50 or self.MenuCenter[player].Y)
	+ Vector(0, -50)
	+ Vector(self.randomFacA[player] * 6, self.randomFacB[player] * 3)
	+ Vector(0, FrameMan.PlayerScreenHeight * 1.1 * math.pow(math.max((self.MenuOutroFactor - 1) / 2, 0), 3))
	self.SceneChar[player].RotAngle = math.rad(self.randomFacC[player] * 7)
	self.SceneChar[player].Vel = self.SceneChar[player].Vel * 0.9

	if math.random() < 0.001 then
		self.SceneChar[player].HFlipped = math.random() < 0.5
	end

	--Set Camera
	local pos = self.MenuCenter[player]

	self.Activity:SetActorSelectCursor(self.SceneChar[player].Pos, player)
	self.Activity:SetObservationTarget(self.SceneChar[player].Pos, player)
	self.MenuActor[player].Pos = self.SceneChar[player].Pos
	CameraMan:SetScrollTarget(pos, 1, player)

	--Input
	self.ctlr[player] = self.MenuActor[player]:GetController()
	self.InputPress[player] = self.ctlr[player]:IsState(Controller.WEAPON_FIRE) --Continue
	self.ReturnInputPress[player] = self.ctlr[player]:IsState(Controller.WEAPON_RELOAD) --Back
	self.InputVector[player] = Vector()

	if player == self.GameNavigator then
		if self.Activity.Config.DebugMode then
			self:DebugKeyCombo_Activated(player)
		else
			self:DebugKeyCombo_NotActivated(player)
		end
	else
		self:PlayerMovement(player, true)
	end

	self.JustPressed[player] = false

	if self.SceneToLoad then
		if not self.IgnoreCharacterSelect then
			if not self.OnCharacterMenu[player] then
				self:MenuOnMenuChange(player, self.MenuData[player].CharacterSelect, true)
				self.OnCharacterMenu[player] = true
			end
		end
	else
		if self.OnCharacterMenu[player] then
			if player ~= self.GameNavigator then
				self:MenuOnMenuChange(player, self.MenuData[player].Main)
			end
			self.OnCharacterMenu[player] = false
			self.BackToSelectLevel[player] = false
		end
		if self.Lockedin[player] then
			self.Activity.SelectedWrestler[player] = ""
			self.Activity.WrestlerIcon[player] = ""
			self.Activity.DeadIcon[player] = ""
			self.Lockedin[player] = false
		end
	end

	if not self.InitiateGame then
		--?Know what button we currently are on (Unused, just for testing)
		--[[
		for i, button in ipairs(self.MenuCurrent[player].Buttons) do
			if player == self.GameNavigator then
				if i == (self.MenuCurrentButton[player] + 1) then
					if button.IsPage then
						print(button.Text)
					end
				end
			end
		end
		]]

		--Disable player input when inputting something
		self:Debug_PlayerSignal(player)

		if self.lastInputVector[player].X ~= self.InputVector[player].X or self.lastInputVector[player].Y ~= self.InputVector[player].Y then
			self.lastInputVector[player] = Vector(self.InputVector[player].X, self.InputVector[player].Y)

			--Special credits behaviour
			if self.MenuCurrent[player] == self.MenuData[player].Credits then
				--if self.MenuCurrent[player].TextScrollTimer:IsPastSimMS(1000) then
				self.MenuCurrent[player].TextScrollTimer:Reset()
				self.MenuCurrent[player].TextScroll = (self.MenuCurrent[player].TextScroll + self.InputVector[player].Y) % #self.MenuCurrent[player].Text
				--end
			end

			--Navigate around!
			if self.MenuCurrent[player].Mode == "Vertical" then
				if self.InputVector[player].Y ~= 0 then
					self.Sound.MenuMove:Play(-1)
					self.MenuCurrentButton[player] = (self.MenuCurrentButton[player] + self.InputVector[player].Y) % #self.MenuCurrent[player].Buttons
					self.MenuSelectAnimationFactor[player] = 0
				end
			elseif self.MenuCurrent[player].Mode == "Horizontal" then
				if self.InputVector[player].Y ~= 0 and self.MenuCurrent[player] == self.MenuData[player].LevelSelect then
					if self.MenuData[player].LevelSelect.LevelIndex == -1 then
						self.MenuData[player].LevelSelect.LevelIndex = self.InputVector[player].Y % self.MenuData[player].LevelSelect.LevelCount
					else
						self.MenuData[player].LevelSelect.LevelIndex = (
								self.MenuData[player].LevelSelect.LevelIndex + self.InputVector[player].Y
							) % self.MenuData[player].LevelSelect.LevelCount
					end

					self.Sound.MenuMove:Play(-1)
					self.MenuCurrentButton[player] = -1
				end

				if self.InputVector[player].X ~= 0 then
					self.Sound.MenuMove:Play(-1)
					self.MenuData[player].LevelSelect.LevelIndex = -1
					self.MenuCurrentButton[player] = (self.MenuCurrentButton[player] + self.InputVector[player].X) % #self.MenuCurrent[player].Buttons
					self.MenuSelectAnimationFactor[player] = 0
				end
			elseif self.MenuCurrent[player].Mode == "Rows" then
				if self.InputVector[player].X ~= 0 or self.InputVector[player].Y ~= 0 then
					self.Sound.MenuMove:Play(-1)
					self.MenuCurrentButton[player] = (
							self.MenuCurrentButton[player]
							+ self.InputVector[player].X
							+ self.InputVector[player].Y * self.MenuCurrent[player].ButtonsPerRow
						) % #self.MenuCurrent[player].Buttons
					self.MenuSelectAnimationFactor[player] = 0
				end
			end
		end
	end

	if self.MenuCurrent[player] == self.MenuData[player].Credits and self.MenuCurrent[player].TextScrollTimer:IsPastSimMS(200) then
		self.MenuCurrent[player].TextScrollTimer:Reset()
		self.MenuCurrent[player].TextScroll = (self.MenuCurrent[player].TextScroll + self.InputVector[player].Y) % #self.MenuCurrent[player].Text
	end

	---Draw
	self.MenuSelectAnimationFactor[player] = math.min(self.MenuSelectAnimationFactor[player] + TimerMan.DeltaTimeSecs * 5, 1)

	PrimitiveMan:DrawBitmapPrimitive(screen,
	self.MenuPos[player] + Vector(0, FrameMan.PlayerScreenHeight * -0.5 + (self.LogoSpriteBig and 85 or 70)),
	self.LogoSize,
	0,
	0
	)

	if self.TempText[player] == 0 then
		if self.OnCharacterMenu[player] == false then
			PrimitiveMan:DrawTextPrimitive(screen,
				self.MenuPos[player] + Vector(0, FrameMan.PlayerScreenHeight * -0.5 + 88 + (self.LogoSpriteBig and 41 or 0)),
				self.DebugModeActivated and "-- WELCOME TO THE TWILIGHT ZONE --" or "-- Version 0.1 --",
				true,
				1
			)
		end
	end

	if self.TempMessages[self.TempText[player]] then
		self:TempTextDisplay(player, self.TempMessages[self.TempText[player]])
	end

	if self.MenuCurrent[player] then
		-- Menu buttons
		for i, button in ipairs(self.MenuCurrent[player].Buttons) do
			local buttonText = type(button.Text) == "table" and button.Text[1] or button.Text
			local selected = i == (self.MenuCurrentButton[player] + 1)
			local selectFactor = math.sin(math.sin(self.MenuSelectAnimationFactor[player] * math.pi * 0.5) * math.pi * 0.5) * 0.5
			local buttonWidth
			local buttonHeight
			local buttonPos

			if button.IsLevel then
				buttonWidth = button.Width or 88
				buttonHeight = button.Height or 54
				buttonPos = self.MenuPos[player] + self.MenuCurrent[player].Offset + Vector(10, 10)
			elseif button.MiniButton then
				buttonWidth = button.Width or (self.MenuCurrent[player].ButtonWidth or 39)
				buttonHeight = button.Height or (self.MenuCurrent[player].ButtonHeight or 28.9)
				buttonPos = self.MenuPos[player] + self.MenuCurrent[player].Offset + Vector(-90, self.MenuCurrent[player].ButtonsPerRowPosY or 40)
			else
				buttonWidth = self.MenuCurrent[player].ButtonWidth or 25 + 6 * 20
				buttonHeight = self.MenuCurrent[player].ButtonHeight or 28.9
				buttonPos = self.MenuPos[player] + self.MenuCurrent[player].Offset
			end

			if button.ButtonPos then
				buttonPos = self.MenuPos[player] + self.MenuCurrent[player].Offset + (button.ButtonPos or Vector())
			end

			if self.MenuCurrent[player].Mode == "Vertical" then
				buttonPos = buttonPos
				+ Vector(self.MenuCurrent[player].DistanceBetweenButtonsX or 0,
				(buttonHeight + (self.MenuCurrent[player].DistanceBetweenButtonsY or 20)) * (i - 1))

			elseif self.MenuCurrent[player].Mode == "Horizontal" then
				buttonPos = buttonPos + Vector((buttonWidth * 1.25 + 20) * ((i - #self.MenuCurrent[player].Buttons * 0.5) - 0.5), 0)
			elseif self.MenuCurrent[player].Mode == "Rows" then
				local perRow = self.MenuCurrent[player].ButtonsPerRow
				local row = math.floor((i - 1) / perRow)
				local j = ((i - 1) % perRow) - (self.MenuCurrent[player].ButtonsPerRowPosX or 0.5)

				buttonPos = buttonPos
				+ Vector(((self.MenuCurrent[player].DistanceBetweenButtonsX or buttonWidth) * 1.25 + 20) * j,
				(buttonHeight + 20) * row + (self.MenuCurrent[player].DistanceBetweenButtonsY or 0))

			end

			if selected then
				buttonWidth = buttonWidth * (1 + 0.5 * selectFactor)
			end

			if button.IsLevel then
				self:MenuDrawBox(screen, player,
					buttonPos + Vector(buttonWidth * -0.5, buttonHeight * -0.5),
					buttonPos + Vector(buttonWidth * 0.5, buttonHeight * 0.5),
					selected, 3
				)
			else
				self:MenuDrawBox(screen, player,
					buttonPos + Vector(buttonWidth * -0.5, buttonHeight * -0.5),
					buttonPos + Vector(buttonWidth * 0.5, buttonHeight * 0.5),
					selected, 1
				)
				PrimitiveMan:DrawTextPrimitive(screen, buttonPos + Vector(0, button.TextOffsetY or -8), buttonText, false, 1)
			end

			if selected then
				if button.Hint then
					PrimitiveMan:DrawTextPrimitive(screen,
						self.MenuPos[player] + Vector(0, FrameMan.PlayerScreenHeight * 0.5 + (button.HintOffsetY or 28)),
						button.Hint,
						true,
						1
					)
				end
				if button.BigHint then
					PrimitiveMan:DrawTextPrimitive(screen,
						self.MenuPos[player] + Vector(0, FrameMan.PlayerScreenHeight * 0.5 + (button.BigHintOffsetY or 15)),
						button.BigHint,
						false,
						1
					)
				end
			end
		end
	end
end

function menu:ButtonLogic()
	self:UpdateNavigatorLevel("SelectLevel", self.LevelCategory, false)
	self:UpdateNavigatorLevel("DebugSelectLevel", self.DebugLevelCategory, true)

	--No Pages
	if self.MenuCurrent[self.GameNavigator] == self.MenuData[self.GameNavigator]["BaseItemList"] then
		local screen = self.Activity:ScreenOfPlayer(self.GameNavigator)
		for i, item in pairs(self.Activity.BaseItemList) do
			local selected = i == (self.MenuCurrentButton[self.GameNavigator] + 1)

			local button = self:PageData(self.GameNavigator, i, 39, 28.9, Vector(-90, self.MenuCurrent[self.GameNavigator].ButtonsPerRowPosY))

			PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos, self.BaseItemIcon[i], 0, 0)

			if selected then
				local namePos = self.MenuPos[self.GameNavigator] + Vector(-1, self.Activity.IsMultiplayer and -150 or -45)
				local descriptionPos = namePos - Vector(0, -15)
				PrimitiveMan:DrawTextPrimitive(screen, namePos, item.Name:gsub(".+/", ""), false, 1)
				PrimitiveMan:DrawTextPrimitive(screen, descriptionPos,
				"Desc: " .. (self.BaseDevice[i].Description ~= "" and self.BaseDevice[i].Description or "None") .. "\nBlacklisted: " .. (item.Blacklisted and "Yes" or "No"), true, 1)
			end
		end
		PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[self.GameNavigator] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), "Main Page", false, 1)
	end

	for i, category in pairs(self.ItemCategory) do
		if self.MenuData[self.GameNavigator][category] then
			local screen = self.Activity:ScreenOfPlayer(self.GameNavigator)
			if self.MenuCurrent[self.GameNavigator] == self.MenuData[self.GameNavigator][category] then
				for ii, item in pairs(self.Activity.CacheDLCItemList[category]) do
					local selected = ii == (self.MenuCurrentButton[self.GameNavigator] + 1)

					local button = self:PageData(self.GameNavigator, ii, 39, 28.9, Vector(-90, self.MenuCurrent[self.GameNavigator].ButtonsPerRowPosY))

					PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos, self.DLCItemIcon[category][ii], 0, 0)

					if selected then
						local namePos = self.MenuPos[self.GameNavigator] + Vector(-1, self.Activity.IsMultiplayer and -150 or -45)
						local descriptionPos = namePos - Vector(0, -15)
						PrimitiveMan:DrawTextPrimitive(screen, namePos, item.Name:gsub(".+/", ""), false, 1)
						PrimitiveMan:DrawTextPrimitive(screen, descriptionPos,
						"Desc: " .. (self.DLCDevice[category][ii].Description ~= "" and self.DLCDevice[category][ii].Description or "None") .. "\nBlacklisted: " .. (item.Blacklisted and "Yes" or "No"), true, 1)
					end
				end
				PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[self.GameNavigator] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), "Page: " .. tostring(i), false, 1)
			end
		end
	end

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			local screen = self.Activity:ScreenOfPlayer(player)
			--No Pages
			if self.MenuCurrent[player] == self.MenuData[player].CharacterSelect then

				for i, char in pairs(self.BaseAHuman) do
					local text
					local selected = i == (self.MenuCurrentButton[player] + 1)
					if char and selected then
						text = char
					end
					local button = self:PageData(player, i, 39, 28.9, Vector(-90, self.MenuCurrent[player].ButtonsPerRowPosY))

					PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos, self.BaseIcon[i], 0, 0)

					local textPos = Vector(0, self.Activity.IsMultiplayer and -150 or -55)
					if selected then
						PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + textPos, tostring(text):gsub(", AHuman", ""), false, 1)
					end

					if self.Lockedin[player] then
						PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + textPos + Vector(-1, 15),
						"LOCKED IN!! \n YOUR WRESTLER: "
						.. tostring(self.Activity.SelectedWrestler[player]):gsub(".+/", ""), false, 1)
					end
				end
				PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), "Main Page", false, 1)
			end

			for i, category in pairs(self.CharCategory) do
				if self.MenuData[player][category] then
					if self.MenuCurrent[player] == self.MenuData[player][category] then

						for ii, char in pairs(self.DLCActor[category]) do
							local text
							local selected = ii == (self.MenuCurrentButton[player] + 1)
							if char and selected then
								text = char
							end

							local button = self:PageData(player, ii, 39, 28.9, Vector(-90, self.MenuCurrent[player].ButtonsPerRowPosY))

							PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos + Vector(-2, 0), self.DLCIcon[category][ii], 0, 0)

							if selected then
								PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(0, self.Activity.IsMultiplayer and -150 or -55), tostring(text):gsub(", AHuman", ""), false, 1)
							end

							if self.Lockedin[player] then
								PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(-1, -36),
								"LOCKED IN!! \n YOUR WRESTLER: "
								.. tostring(self.Activity.SelectedWrestler[player]):gsub(".+/", ""), false, 1)
							end
						end
						PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[player] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), "Page: " .. tostring(i), false, 1)
					end
				end
			end
		end
	end
end

--[[---------------------------------------------------------
	Name: NavigatorButtons( Player )
	Desc: Builds menu(s) exclusively for the gameNavigator
		We have gameNav as a parameter for no apparent reason (but I find it good either way)
------------------------------------------------------------]]
function menu:NavigatorButtons(gameNav)
	self.MenuData[gameNav]["Gamemodes"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Rows",
		ButtonsPerRow = 2,
		Buttons = {
			{
				Text = "Free For All",
				Hint = "Everyone to them selves! (Last Player Alive)",
				BigHint = "REQUIRES 1 PLAYER PER TEAM",
				OnPress = function()
					self.ScriptToLoad = "FFA.lua"
					self.GamemodeToLoad = "FFA"
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].SelectLevel)
				end,
			},
			{
				Text = "Last Team Standing",
				Hint = "Fight in a 1v1! Or a 2V2! OR A 3V1!",
				BigHint = "NO REQUIREMENTS",
				OnPress = function()
					self.ScriptToLoad = "LastTeamStanding.lua"
					self.GamemodeToLoad = "LTS"
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].SelectLevel)
				end,
			},
			{
				Text = "Go Back",
				OnPress = function()
					self.ScriptToLoad = nil
					self.GamemodeToLoad = nil
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Main, true, true)
				end,
			},
		},
	}

	table.insert(self.MenuData[gameNav].Main.Buttons, 1,
	{
		Text = "Multiplayer",
		BigHint = "Fun with Friends!",
		OnPress = function()
			self.IgnoreCharacterSelect = false
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Gamemodes)
		end,
	})
	table.insert(self.MenuData[gameNav].Main.Buttons, 2,
	{
		Text = "Settings",
		Hint = "Something not right? Well you can change it here!",
		OnPress = function()
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Settings)
		end,
	})

	self.MenuData[gameNav]["SelectLevel"] = {
		Offset = Vector(0, self:ResOffsetY(0, -10, -100)),
		Mode = "Rows",
		ButtonsPerRow = 3,
		ButtonsPerRowPosX = 1.1,
		Buttons = {},
	}

	self.MenuData[gameNav]["DebugSelectLevel"] = table.Copy(self.MenuData[gameNav]["SelectLevel"])

	self.MenuData[gameNav]["LevelPages"] = {
		Offset = Vector(0, self:ResOffsetY(10, 8, -100)),
		Mode = "Rows",
		ButtonsPerRow = 3,
		ButtonsPerRowPosX = 1.1,
		ButtonsPerRowPosY = 1.1,
		Buttons = {},
	}

	self.MenuData[gameNav]["DebugLevelPages"] = table.Copy(self.MenuData[gameNav]["LevelPages"])

	table.insert(self.MenuData[gameNav].LevelPages.Buttons,
	{
		Text = "Go\nBack",
		TextOffsetY = -15,
		MiniButton = true,
		OnPress = function()
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].SelectLevel, true, true)
		end,
	})

	table.insert(self.MenuData[gameNav].DebugLevelPages.Buttons,
	{
		Text = "Go\nBack",
		TextOffsetY = -15,
		MiniButton = true,
		OnPress = function()
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugSelectLevel, true, true)
		end,
	})

	for i, LB in pairs(self.Activity.BaseLevels) do
		if i <= 6 then
			table.insert(self.MenuData[gameNav].SelectLevel.Buttons,
			{
				Text = LB[2], --map_name
				IsLevel = true,
				OnPress = function()
					self.SceneToLoad = LB[1] --scene
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].CharacterSelect, true)
				end,
			})
			table.insert(self.MenuData[gameNav].DebugSelectLevel.Buttons,
			{
				Text = LB[2], --map_name
				IsLevel = true,
				OnPress = function()
					self.SceneToLoad = LB[1] --scene
					self.TempText[gameNav] = 5
					self.IgnoreCharacterSelect = true
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugLevelConfirm, true)
				end,
			})
			self.BaseMap[i] = self.MenuData[gameNav].SelectLevel.Buttons[i].Text
			self.BasePreview[i] = CreateMOSRotating("Wrestling.rte/" .. self.Activity.SceneData[i].PreviewImage)
		end
	end

	self.MenuData[gameNav]["ItemPages"] = {
		Offset = Vector(0, self:ResOffsetY(10, 8, -90)),
		Mode = "Rows",
		ButtonsPerRow = 6,
		ButtonsPerRowPosX = 1.1,
		ButtonsPerRowPosY = 1.1,
		Buttons = {
			{
				Text = "Go\nBack",
				TextOffsetY = -15,
				MiniButton = true,
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].BaseItemList, true, true)
				end,
			}
		},
	}

	self.Activity.DLC_Category:Load_DLC_Categorys(self) --Maps and Wrestler
	self.SLS:CheckItemLists()

	local readjust_backButton = false

	if self.PageLevelCount > 0 then
		self.FixedPageTable[2] = 15
		self.FixedPageTable[3] = #self.MenuData[gameNav].SelectLevel.Buttons == 4 and 30 or 10
		table.insert(self.MenuData[gameNav].SelectLevel.Buttons,
		{
			Text = "View Pages",
			MiniButton = true,
			Width = 88,
			ButtonPos = Vector(10, self.FixedPageTable[#self.MenuData[gameNav].SelectLevel.Buttons - 1]),
			OnPress = function()
				self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].LevelPages)
			end,
		})

		table.insert(self.MenuData[gameNav].DebugSelectLevel.Buttons,
		{
			Text = "View Pages",
			MiniButton = true,
			Width = 88,
			ButtonPos = Vector(10, self.FixedPageTable[#self.MenuData[gameNav].DebugSelectLevel.Buttons - 1]),
			OnPress = function()
				self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugLevelPages)
			end,
		})
		readjust_backButton = true
	end

	if readjust_backButton then
		self.FixedBackTable[1] = 15
		self.FixedBackTable[2] = 15
		self.FixedBackTable[4] = #self.MenuData[gameNav].SelectLevel.Buttons == 6 and 40 or 30
	else
		self.FixedBackTable[1] = 15
		self.FixedBackTable[2] = 30
	end

	table.insert(self.MenuData[gameNav].SelectLevel.Buttons,
	{
		Text = "Go Back to\nGamemode",
		TextOffsetY = -15,
		MiniButton = true,
		Width = 88,
		ButtonPos = Vector(10, self.FixedBackTable[#self.MenuData[gameNav].SelectLevel.Buttons - 2]),
		OnPress = function()
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Gamemodes, true, true)
		end,
	})

	table.insert(self.MenuData[gameNav].DebugSelectLevel.Buttons,
	{
		Text = "Go Back to\nDebug Page",
		TextOffsetY = -15,
		MiniButton = true,
		Width = 88,
		ButtonPos = Vector(10, self.FixedBackTable[#self.MenuData[gameNav].DebugSelectLevel.Buttons - 2]),
		OnPress = function()
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugPage, true, true)
		end,
	})

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			if self.PageCharCount > 0 then
				table.insert(self.MenuData[player].CharacterSelect.Buttons,
				{
					Text = "View\nPages",
					TextOffsetY = -16,
					MiniButton = true,
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].CharPages)
					end,
				})
			end
		end
	end

	self.MenuData[gameNav]["ReturnToSelectLevel"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		--DisableBackButton = true,
		Buttons = {
			{
				Text = "Yes",
				BigHint = "\xDB All players will return back! \xDB",
				BigHintOffsetY = 23,
				OnPress = function()
					self.CanReturn = true
					self.SceneToLoad = nil
					self.TempText[gameNav] = 0
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].SelectLevel, true)
				end,
			},
			{
				Text = "No",
				OnPress = function()
					self.TempText[gameNav] = 0
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].CharacterSelect, true)
				end,
			},
		},
	}
	self.MenuData[gameNav]["BaseItemList"] = {
		Offset = Vector(0, self:ResOffsetY(10, 8, -90)),
		Mode = "Rows",
		ButtonsPerRow = 6,
		ButtonsPerRowPosX = 1.1,
		ButtonsPerRowPosY = 1.1,
		Buttons = {
			{
				Text = "Go\nBack",
				TextOffsetY = -15,
				MiniButton = true,
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].GSettings, true, true)
				end,
			}
		},
	}

	for i, item in pairs(self.Activity.BaseItemList) do
		self.BaseDevice[i] = item.Device(item.Name)

		--It's technically already false by default, but just for incase :)
		item.Blacklisted = self.SLS.Cache.GameOptions.Items.Base[item.ID] and self.SLS.Cache.GameOptions.Items.Base[item.ID].Blacklisted or false

		if not item.Blacklisted then self.Activity.CacheItemList[item.ID] = item end
		table.insert(self.MenuData[self.GameNavigator].BaseItemList.Buttons, i,
		{
			Text = "",
			MiniButton = true,
			OnPress = function()
				item.Blacklisted = not item.Blacklisted
				if item.Blacklisted then
					self.Activity.CacheItemList[item.ID] = nil
					self.SLS.Cache.GameOptions.Items.Base[item.ID] = {Name = item.Name, Blacklisted = true}
					return
				end

				self.Activity.CacheItemList[item.ID] = item
				self.SLS.Cache.GameOptions.Items.Base[item.ID] = nil
			end,
		})
		self.BaseItem[i] = self.BaseDevice[i].PresetName
		self.BaseItemIcon[i] = ToMOSprite(self.BaseDevice[i])
	end

	if self.PageItemCount > 0 then
		table.insert(self.MenuData[gameNav].BaseItemList.Buttons, #self.MenuData[gameNav].BaseItemList.Buttons,
		{
			Text = "View\nPages",
			TextOffsetY = -16,
			MiniButton = true,
			OnPress = function()
				self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].ItemPages)
			end,
		})
	end

	table.insert(self.MenuData[gameNav].CharacterSelect.Buttons,
	{
		Text = "Go\nBack",
		TextOffsetY = -15,
		MiniButton = true,
		OnPress = function()
			self.TempText[gameNav] = 2
			self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].ReturnToSelectLevel, true)
		end,
	})

	self.MenuData[gameNav]["Settings"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		Buttons = {
			{
				Text = "Options",
				Hint = "Normal Options",
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].NSettings)
				end,
			},
			{
				Text = "Game\nOptions",
				TextOffsetY = -15,
				Hint = "Applies to 'all' gamemodes",
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].GSettings)
				end,
			},
			{
				Text = "Go Back",
				OnPress = function()
					if self:NotEqualData() then
						self.TempText[self.GameNavigator] = 1
						self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].SaveOptions, true)
					else
						self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].Main, true, true)
					end
				end,
			},
		},
	}

	self.MenuData[gameNav]["GSettings"] = {
		Offset = Vector(0, self:ResOffsetY(-10, -10, -100)),
		Mode = "Rows",
		ButtonsPerRow = 5,
		ButtonsPerRowPosX = 2,
		DistanceBetweenButtonsX = 58,
		ButtonWidth = 65,
		ButtonHeight = 28.9,
		Buttons = {
			{
				Text = self.SLS.LivesText,
				TextOffsetY = -15,
				Hint = "Amount of lives EVERY player should have",
				OnPress = function()
					self.SLS.Cache.GameOptions.PlayerLives = self.SLS.Cache.GameOptions.PlayerLives + 1
					if self.SLS.Cache.GameOptions.PlayerLives >= #self.SLS.PlayerLives then
						self.SLS.Cache.GameOptions.PlayerLives = 0
					end
					self.SLS.LivesText[1] = "Total Lives\n" .. self.SLS.PlayerLives[self.SLS.Cache.GameOptions.PlayerLives + 1]
				end,
			},
			{
				Text = self.SLS.HealthText,
				TextOffsetY = -15,
				Hint = "Amount of HP a player should have",
				OnPress = function()
					self.SLS.Cache.GameOptions.PlayerHealth = self.SLS.Cache.GameOptions.PlayerHealth + 1
					if self.SLS.Cache.GameOptions.PlayerHealth >= #self.SLS.PlayerHealth then
						self.SLS.Cache.GameOptions.PlayerHealth = 0
					end
					self.SLS.HealthText[1] = "Total Health\n" .. self.SLS.PlayerHealth[self.SLS.Cache.GameOptions.PlayerHealth + 1] * self.Config.HealthMultiplier
				end,
			},
			{
				Text = self.SLS.CrateSpawnText,
				TextOffsetY = -15,
				Hint = "How often a Crate should spawn",
				OnPress = function()
					self.SLS.Cache.GameOptions.CrateRespawnTime = self.SLS.Cache.GameOptions.CrateRespawnTime + 1
					if self.SLS.Cache.GameOptions.CrateRespawnTime >= #self.SLS.CrateRespawnTime then
						self.SLS.Cache.GameOptions.CrateRespawnTime = 0
					end
					self.SLS.CrateSpawnText[1] = "Crate Rate\n" .. self.SLS.CrateRespawnTime[self.SLS.Cache.GameOptions.CrateRespawnTime + 1]
				end,
			},
			{
				Text = self.SLS.PlayerSpawnText,
				TextOffsetY = -15,
				Hint = "How long until a Player can spawn",
				OnPress = function()
					self.SLS.Cache.GameOptions.PlayerRespawnTime = self.SLS.Cache.GameOptions.PlayerRespawnTime + 1
					if self.SLS.Cache.GameOptions.PlayerRespawnTime >= #self.SLS.PlayerRespawnTime then
						self.SLS.Cache.GameOptions.PlayerRespawnTime = 0
					end
					self.SLS.PlayerSpawnText[1] = "Spawn Time\n" .. self.SLS.PlayerRespawnTime[self.SLS.Cache.GameOptions.PlayerRespawnTime + 1] .. " Seconds"
				end,
			},
			{
				Text = self.SLS.MatchTimeText,
				TextOffsetY = -15,
				Hint = "How long a match should last for",
				OnPress = function()
					self.SLS.Cache.GameOptions.MatchTime = self.SLS.Cache.GameOptions.MatchTime + 1
					if self.SLS.Cache.GameOptions.MatchTime >= #self.SLS.MatchTime then
						self.SLS.Cache.GameOptions.MatchTime = 0
					end
					self.SLS.MatchTimeText[1] = "Match Time\n" .. self.SLS.MatchTime[self.SLS.Cache.GameOptions.MatchTime + 1] .. " Minutes"
				end,
			},
			{
				Text = self.SLS.LivesDisabledText,
				TextOffsetY = -15,
				Hint = "Diasble lives and play on a score system!\nWill ignore 'Total Lives' option!",
				HintOffsetY = 18,
				OnPress = function()
					self.SLS.Cache.GameOptions.LivesDisabled = not self.SLS.Cache.GameOptions.LivesDisabled
					local t = { [true] = "No Lives\nON", [false] = "No Lives\nOFF" }
					self.SLS.LivesDisabledText[1] = t[self.SLS.Cache.GameOptions.LivesDisabled]
				end,
			},
			{
				Text = self.SLS.RegenHPText,
				TextOffsetY = -15,
				Hint = "Regenerate HP over time",
				OnPress = function()
					self.SLS.Cache.GameOptions.RegenHP = not self.SLS.Cache.GameOptions.RegenHP
					local t = { [true] = "RegenHP\nON", [false] = "RegenHP\nOFF" }
					self.SLS.RegenHPText[1] = t[self.SLS.Cache.GameOptions.RegenHP]
				end,
			},
			{
				Text = self.SLS.CacheItemListText,
				TextOffsetY = -15,
				Hint = "Allow items to spawn or not\nWill prevent crates from spawning!",
				HintOffsetY = 18,
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].BaseItemList)
				end,
			},
			{
				Text = "Reset Game\nOptions",
				TextOffsetY = -15,
				Hint = "Reset all Game settings to default!",
				OnPress = function()
					self.TempText[gameNav] = 3
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].ResetGSettings, true)
				end,
			},
			{
				Text = "Go Back",
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Settings, true, true)
				end,
			},
		},
	}
	self.MenuData[gameNav]["NSettings"] = {
		Offset = Vector(0, self:ResOffsetY(-10, -10, -100)),
		Mode = "Rows",
		ButtonsPerRow = 5,
		ButtonsPerRowPosX = 2,
		DistanceBetweenButtonsX = 58,
		ButtonWidth = 64,
		ButtonHeight = 28.9,
		Buttons = {
			{
				Text = self.SLS.AnnouncerVolumeText,
				TextOffsetY = -15,
				Hint = "Announcer too EPIC or too Quiet for you?",
				OnPress = function()
					self.SLS.Cache.Options.AnnouncerVolume = (string.format("%.1f", self.SLS.Cache.Options.AnnouncerVolume) - 0.1) % 1.1
					self.SLS.AnnouncerVolumeText[1] = "Announcer\nVolume " .. tostring(math.floor(self.SLS.Cache.Options.AnnouncerVolume * 100)) .. "%"
					for i = 1, 4 do
						self.Activity.SFXTracks[i].Volume = self.SLS.Cache.Options.AnnouncerVolume
					end
				end,
			},
			{
				Text = self.SLS.CheerVolumeText,
				TextOffsetY = -15,
				Hint = "and the Crowd goes wild!",
				OnPress = function()
					self.SLS.Cache.Options.CheerVolume = (string.format("%.1f", self.SLS.Cache.Options.CheerVolume) - 0.1) % 1.1
					self.SLS.CheerVolumeText[1] = "Cheer\nVolume " .. tostring(math.floor(self.SLS.Cache.Options.CheerVolume * 100)) .. "%"
					for i = 5, 7 do
						self.Activity.SFXTracks[i].Volume = self.SLS.Cache.Options.CheerVolume
					end
				end,
			},
			{
				Text = "Reset\nOptions",
				TextOffsetY = -15,
				Hint = "Reset all non Game settings to default!",
				OnPress = function()
					self.TempText[gameNav] = 4
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].ResetOptions)
				end,
			},
			{
				Text = "Go Back",
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Settings, true, true)
				end,
			},
		},
	}
	self.MenuData[gameNav]["SaveOptions"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		Buttons = {
			{
				Text = "Yes",
				OnPress = function()
					self.TempText[gameNav] = 0
					if (self.TableToSave_A and self.TableToSave_B) then
						self.SLS:SaveSettings()
						self.TableToSave_A = nil; self.TableToSave_B = nil
					elseif self.TableToSave_A then
						self.SLS:SaveSettings(1)
						self.TableToSave_A = nil
					elseif self.TableToSave_B then
						self.SLS:SaveSettings(2)
						self.TableToSave_B = nil
					end
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Main, true)
				end,
			},
			{
				Text = "No",
				Hint = "Any unsaved Settings will be lost",
				OnPress = function()
					self.TempText[gameNav] = 0
					--We do the same operation but instead to load,
					--Since we already know what we tried to save, it'll reload instead of everything
					--?Maybe this is a good idea? who knows
					if (self.TableToSave_A and self.TableToSave_B) then
						self.SLS:LoadGameSettings(); self.SLS:LoadSettings()
						self.TableToSave_A = nil; self.TableToSave_B = nil
					elseif self.TableToSave_A then
						self.SLS:LoadGameSettings()
						self.TableToSave_A = nil
					elseif self.TableToSave_B then
						self.SLS:LoadSettings()
						self.TableToSave_B = nil
					end
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Main, true, true)
				end,
			},
		}
	}
	self.MenuData[gameNav]["ResetGSettings"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		Buttons = {
			{
				Text = "Yes",
				BigHint = "All Saved Game Settings will be lost",
				OnPress = function()
					self.TempText[gameNav] = 0
					self.SLS:ResetSettings(1)
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].GSettings, true)
				end,
			},
			{
				Text = "No",
				OnPress = function()
					self.TempText[gameNav] = 0
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].GSettings, true)
				end,
			},
		}
	}
	self.MenuData[gameNav]["ResetOptions"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		Buttons = {
			{
				Text = "Yes",
				BigHint = "All Saved Regular Settings will be lost",
				OnPress = function()
					self.TempText[gameNav] = 0
					self.SLS:ResetSettings(2)
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].NSettings, true)
				end,
			},
			{
				Text = "No",
				OnPress = function()
					self.TempText[gameNav] = 0
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].NSettings, true)
				end,
			},
		}
	}

	self.MenuData[gameNav]["DebugLevelConfirm"] = {
		Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
		Mode = "Vertical",
		Buttons = {
			{
				Text = "Yes",
				OnPress = function()
					self.ScriptToLoad = "Viewer.lua"
					self.GamemodeToLoad = 0 --Viewer
					self.InitiateGame = true
					self.Activity.ViewerMode = true
				end,
			},
			{
				Text = "No",
				OnPress = function()
					self.CanReturn = true
					self.TempText[gameNav] = 0
					self.SceneToLoad = nil
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugSelectLevel, true)
				end,
			},
		}
	}
	self.MenuData[gameNav]["DebugPage"] = {
		Offset = Vector(0, self:ResOffsetY(10, 8, -100)),
		Mode = "Rows",
		ButtonsPerRow = 5,
		ButtonsPerRowPosX = 1.1,
		ButtonsPerRowPosY = 1.1,
		ButtonWidth = 64,
		ButtonHeight = 28.9,
		IsDebug = true,
		Buttons = {
			{
				Text = "Floater",
				MiniButton = true,
				OnPress = function()
					self:SpawnFloater(gameNav, 700)
				end,
			},
			{
				Text = "BG Direction",
				MiniButton = true,
				OnPress = function()
					self.FlipDirection = not self.FlipDirection
					for BG in SceneMan.Scene.BackgroundLayers do
						self.FloatDirection = self.FlipDirection and -1 or 1
						BG.AutoScrollStepX = self.FlipDirection and -0.5 or 0.5
					end
				end,
			},
			{
				Text = "Timer Length",
				BigHint = "(EX: 120 seconds = 2 minutes)",
				MiniButton = true,
				HasInput = true,
				Special = 2,
				SpecialText = {"GAME TIME:"},
				DisableButton = false,
				SpecialTextPos = {Vector(10, 0.1 + 0.23), Vector(10, 0.1 + 0.50)},
				OnPress = function()
					if self.ButtonSwitch then
						self.Sound.InputVoice_3:Play(-1)
					end
					self:InsertCodeDisplay(self.ButtonSwitch, "YELLOW", "FLYBYLEFTWARD",
					self.MenuData[gameNav].DebugPage.Buttons[3].SpecialText[1], self.MenuData[gameNav].DebugPage.Buttons[3].SpecialTextPos[1])
					self.CanReturn = not self.CanReturn
				end,
				OnUpdate = function()
					for k, number in pairs({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}) do
						if UInputMan:GetTextInput() ~= "" then
							if UInputMan:GetTextInput() == number then
								self.TimerLength = self.TimerLength .. UInputMan:GetTextInput()
								self:InsertCodeDisplay(false, "RED")
								self:InsertCodeDisplay(true, "RED", "FLYBYLEFTWARD", self.TimerLength, self.MenuData[gameNav].DebugPage.Buttons[3].SpecialTextPos[2])
							end
						end
					end
					if UInputMan:KeyPressed(Key.BACKSPACE) then
						self.TimerLength = string.sub(self.TimerLength, 1, -2)
						self:InsertCodeDisplay(false, "RED")
						self:InsertCodeDisplay(true, "RED", "FLYBYLEFTWARD", self.TimerLength, self.MenuData[gameNav].DebugPage.Buttons[3].SpecialTextPos[2])
					end
				end,
			},
			{
				Text = "View Scene",
				Hint = "View a scene without gameplay",
				MiniButton = true,
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].DebugSelectLevel)
				end,
			},
			{
				Text = "NO MINI",
				ButtonPos = Vector(-150, 0),
				IsLevel = true,
				OnPress = function()
				end,
			},
			{
				Text = "Go Back",
				MiniButton = true,
				OnPress = function()
					self:MenuOnMenuChange(gameNav, self.MenuData[gameNav].Main, true, true)
				end,
			}
		},
	}
end

--[[---------------------------------------------------------
	Name: BuildMenu( Player )
	Desc: Builds a menu for all players including the gameNavigator
------------------------------------------------------------]]
function menu:BuildMenu(player)
	return {
		Main = {
			Offset = Vector(0, self:ResOffsetY(30, -10, -100)),
			Mode = "Vertical",
			DistanceBetweenButtonsY = 15,
			Buttons = {
				{
					Text = "About",
					Hint = "Information regarding the mod.",
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].Info)
					end,
				},
				{
					Text = "Credits",
					Hint = "Credits to everything that particpated in this mod!\n If you weren't credited let me know!",
					HintOffsetY = 18,
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].Credits)
						self.MenuCurrent[player].TextScrollTimer:Reset()
					end,
				},
			},
		},
		Credits = {
			Offset = Vector(0, self:ResOffsetY(190, 135, 100)),
			Mode = "Horizontal",
			Text = {
				"--Developed By--",
				"\xCD Bebomonky \xCD", -- \xC9 Third \xCA Second \xCB First
				"",
				"--Originally By--",
				"\xC2 The Last Banana \xC2", -- \xC9 Third \xCA Second \xCB First
				"",
				"--\xC2Supporters\xC2--",
				"BadBeaver | The greatest Beaver that has ever lived",
				"Naitor295 | 1984",
				"PawnisHoovy | I gotta go but you have my full approval",
				"PyromaniacPT | Napalm Sticks to Kids",
				"",
				"--Beta Testers--",
				"BadBeaver",
				"Naitor295",
				"PyromaniacPT",
				"",
				"--Audio Engineer--",
				"PawnisHoovy | Guy who asked to be in the credits",
				"",
				"--Music--",
				"All music is created by their rightful owner's",
				"Direct Links can be found in Credits.txt",
				"These Album(s) or Song(s) can be found on newgrounds!",
				"Go Go Gadget Kono Taiken | Trofflessy and SiIvaGunner",
				"Uno Aestas Electro | Rajunen",
				"Speed It Up | Drawoh",
				"Submissive | Monodrone",
				"",
				"--Mods--",
				"4zK's Global Script Collection, Food Mod | 4zK",
				"Brain Wrestling MK2 | The Last Banana",
				"More Drop Crates | AzerathAngelwolf",
				"ULTRAKILL | Fil aka Filipe aka Filipex2000",
			},
			TextScroll = 0,
			TextScrollMaxLines = self:ResOffsetY(13, 9, 15), -- 10
			TextScrollOffsetY = self.Activity.IsMultiplayer and -150 or -35,
			TextScrollTimer = Timer(),
			Buttons = {
				{
					Text = "Go Back",
					Hint = "Use arrow keys (up | down) to scroll.", -- Hack
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].Main, true, true)
					end,
				},
			},
		},
		Info = {
			Offset = Vector(0, self:ResOffsetY(190, 150, 0)),
			Mode = "Vertical",
			Text = {
				"Welcome... TO WRESTLE MANIA!",
				"This is originated by a older mod called 'Brain Wrestling MK2'",
				"Made by the one and only 'The Last Banana'. Very Talented Modder!",
				"I hope you can appreciate my work and making the experience better!",
				"Till next time we meet!",
				"Maybe in a dark and horric world...",
				"",
				"-Bebomonky",
			},
			InfoTextOffsetY = self.Activity.IsMultiplayer and -150 or -35,
			Buttons = {
				{
					Text = "Go Back",
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].Main, true, true)
					end,
				},
			},
		},
		CharacterSelect = {
			Offset = Vector(0, self:ResOffsetY(10, 8, -85)),
			Mode = "Rows",
			ButtonsPerRow = 6,
			ButtonsPerRowPosX = 1.1,
			ButtonsPerRowPosY = 1.1,
			--DisableBackButton = true,
			Buttons = {
				--[[
				{
					Text = "View\nPages",
					TextOffsetY = -16,
					MiniButton = true,
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].CharPages)
					end,
				}
				]]
			},
		},
		CharPages = {
			Offset = Vector(0, self:ResOffsetY(10, 8, -85)),
			Mode = "Rows",
			ButtonsPerRow = 6,
			ButtonsPerRowPosX = 1.1,
			ButtonsPerRowPosY = 1.1,
			Buttons = {
				{
					Text = "Go\nBack",
					TextOffsetY = -15,
					MiniButton = true,
					OnPress = function()
						self:MenuOnMenuChange(player, self.MenuData[player].CharacterSelect, true, true)
					end,
				}
			},
		},
	}
end

-----------------------------------------------------------------------------------------
-- Misc
-----------------------------------------------------------------------------------------

function menu:PressSignal(player)
	--Constantly updates the first press, stops on the second
	--! YOU must use this carefully
	for i, button in ipairs(self.MenuCurrent[player].Buttons) do
		if i == (self.MenuCurrentButton[player] + 1) and button.OnUpdate then
			if button.JustPress then
				button.OnUpdate()
			end
		end
	end

	if self.lastReturnInputPress[player] ~= self.ReturnInputPress[player] then
		self.lastReturnInputPress[player] = self.ReturnInputPress[player]
		if self.ReturnInputPress[player] then
			self.JustPressed[player] = true

			for i, blacklisted_name in pairs(self.BlacklistedReturns[player]) do
				if self.MenuCurrent[player] == self.MenuData[player][blacklisted_name] then
					self.CanReturn = false
					break
				end
			end

			if self.CanReturn then
				if #self.MenuHistory[player] > 0 then
					if self.MenuCurrent[player] == self.MenuData[player]["Settings"] then
						if self:NotEqualData() then
							self.TempText[self.GameNavigator] = 1
							self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].SaveOptions, true)
							self.Sound.MenuSwitch:Play(-1)
						end
					elseif self.MenuCurrent[player] == self.MenuData[player]["CharacterSelect"] then
						self.TempText[self.GameNavigator] = 2
						self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].ReturnToSelectLevel, true)
					else
						self.MenuCurrentButton[player] = 0
						self.MenuCurrent[player] = table.remove(self.MenuHistory[player])
						self.Sound.MenuSwitch:Play(-1)
					end
				end
			else
				self.Sound.Error:Play(-1)
			end
		end
	end
	-- Just pressed signal!
	if self.lastInputPress[player] ~= self.InputPress[player] then
		self.lastInputPress[player] = self.InputPress[player]

		if self.InputPress[player] then
			self.JustPressed[player] = true

			for i, button in ipairs(self.MenuCurrent[player].Buttons) do
				if i == (self.MenuCurrentButton[player] + 1) and button.OnPress then
					button.JustPress = not button.JustPress
					--This is just for static, no updates!
					if button.Special == 1 then
						self.ButtonSwitch = not self.ButtonSwitch
						self:InsertCodeDisplay(self.ButtonSwitch, "YELLOW", "FLYBYRIGHTWARD", button.SpecialText[1] or "NO TEXT 01", button.SpecialTextPos[1] or Vector(225, 0.1 + 0.23))
						self:InsertCodeDisplay(self.ButtonSwitch, "RED", "FLYBYLEFTWARD", button.SpecialText[2] or "NO TEXT 02", button.SpecialTextPos[2] or Vector(220, 0.1 + 0.23))
					elseif button.Special == 2 then
						--Only just for ButtonSwitch
						self.ButtonSwitch = not self.ButtonSwitch
					end
					button.OnPress()
					if self.MenuCurrent[player].IsDebug then
						self.Sound.Debug:Play(-1)
						self.Sound.Debug.Pitch = math.random()
					else
						self.Sound.MenuSelect:Play(-1)
					end
				end
			end
		end
	end
end

function menu:NewCharacterCategory(...)
	self.PageCharCount = self.PageCharCount + 1
	--Hit the Max, no more Pages (How the fuck would you hit this limit anyway?)
	if self.PageCharCount > 23 then return end
	local category = "DLC_Char_Page " .. self.PageCharCount
	self.DLCAHuman[category] = {}
	self.DLCActor[category] = {}
	self.DLCIcon[category] = {}

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			self.MenuData[player][category] =
			{
				Offset = Vector(0, self:ResOffsetY(10, 8, -85)),
				Mode = "Rows",
				ButtonsPerRow = 6,
				ButtonsPerRowPosX = 1.1,
				ButtonsPerRowPosY = 1.1,
				Buttons = {
					{
						Text = "Go\nBack",
						TextOffsetY = -15,
						MiniButton = true,
						OnPress = function()
							self:MenuOnMenuChange(player, self.MenuData[player].CharPages, true, true)
						end,
					},
				}
			}
			table.insert(self.MenuData[player].CharPages.Buttons, #self.MenuData[player].CharPages.Buttons,
			{
				Text = "Page " .. tostring(self.PageCharCount),
				MiniButton = true,
				IsPage = true,
				OnPress = function()
					self:MenuOnMenuChange(player, self.MenuData[player][category])
				end,
			})

			--For the Category Names
			self.CharCategory[self.PageCharCount] = category
		end
	end

	for i, wrestler in pairs({...}) do
		self.DLCAHuman[category][i] = CreateAHuman(wrestler)
		table.insert(self.Activity.DisplayRandoChar, wrestler)
		if i <= 23 then
			for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
				if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
					table.insert(self.MenuData[player][category].Buttons, #self.MenuData[player][category].Buttons,
					{
						Text = "",
						MiniButton = true,
						OnPress = function()
							self.Lockedin[player] = true
							self.Activity.SelectedWrestler[player] = wrestler
							self.Activity.WrestlerIcon[player] = self.DLCAHuman[category][i]:StringValueExists("WrestlerIcon")
							and self.DLCAHuman[category][i]:GetStringValue("WrestlerIcon")
							or "Wrestling.rte/Unknown Icon"

							self.Activity.DeadIcon[player] = self.DLCAHuman[category][i]:StringValueExists("DeadWrestlerIcon")
							and self.DLCAHuman[category][i]:GetStringValue("DeadWrestlerIcon")
							or "Wrestling.rte/Dead Icon"
						end,
					})
				end
			end
			self.DLCActor[category][i] = self.DLCAHuman[category][i].PresetName
			self.DLCIcon[category][i] = ToMOSRotating(self.DLCAHuman[category][i].Head)
		end
	end
end
function menu:NewLevelCategory(...)
	self.PageLevelCount = self.PageLevelCount + 1
	--Hit the Max, no more Pages (How the fuck would you hit this limit anyway?)
	if self.PageLevelCount > 23 then return end
	local category = "DLC_Level_Page " .. self.PageLevelCount
	local category_debug = category .. "_DEBUG"
	self.DLCPreview[category] = {}
	self.DLCMap[category] = {}

	self.DLCPreview[category_debug] = {}
	self.DLCMap[category_debug] = {}

	self.MenuData[self.GameNavigator][category] =
	{
		Offset = Vector(0, self:ResOffsetY(0, -10, -100)),
		Mode = "Rows",
		ButtonsPerRow = 3,
		ButtonsPerRowPosX = 1.1,
		Buttons = {}
	}
	self.MenuData[self.GameNavigator][category_debug] = table.Copy(self.MenuData[self.GameNavigator][category])

	table.insert(self.MenuData[self.GameNavigator].LevelPages.Buttons, #self.MenuData[self.GameNavigator].LevelPages.Buttons,
	{
		Text = "Page " .. tostring(self.PageLevelCount),
		MiniButton = true,
		IsPage = true,
		OnPress = function()
			self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator][category])
		end,
	})

	table.insert(self.MenuData[self.GameNavigator].DebugLevelPages.Buttons, #self.MenuData[self.GameNavigator].DebugLevelPages.Buttons,
	{
		Text = "Page " .. tostring(self.PageLevelCount),
		MiniButton = true,
		IsPage = true,
		OnPress = function()
			self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator][category_debug])
		end,
	})

	--For the Category Names
	self.LevelCategory[self.PageLevelCount] = category
	self.DebugLevelCategory[self.PageLevelCount] = category_debug

	for i, map_button in pairs({...}) do
		if i <= 6 then
			--[[
			if self.MenuData[self.GameNavigator][category].ButtonsPerRow ~= 3 then
				self.MenuData[self.GameNavigator][category].ButtonsPerRow = i
			end
			if self.MenuData[self.GameNavigator][category_debug].ButtonsPerRow ~= 3 then
				self.MenuData[self.GameNavigator][category_debug].ButtonsPerRow = i
			end
			]]
			table.insert(self.MenuData[self.GameNavigator][category].Buttons,
			{
				Text = "",
				IsLevel = true,
				OnPress = function()
					self.SceneToLoad = map_button.SceneName
					self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].CharacterSelect)
				end,
			})
			self.DLCMap[category][i] = map_button.MapName
			self.DLCPreview[category][i] = CreateMOSRotating("Wrestling.rte/" .. map_button.PreviewImage)

			table.insert(self.MenuData[self.GameNavigator][category_debug].Buttons,
			{
				Text = "",
				IsLevel = true,
				OnPress = function()
					self.SceneToLoad = map_button.SceneName
					self.TempText[self.GameNavigator] = 5
					self.IgnoreCharacterSelect = true
					self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].DebugLevelConfirm)
				end,
			})
			self.DLCMap[category_debug][i] = map_button.MapName
			self.DLCPreview[category_debug][i] = CreateMOSRotating("Wrestling.rte/" .. map_button.PreviewImage)
		end
	end

	table.insert(self.MenuData[self.GameNavigator][category].Buttons,
	{
		Text = "Go Back to list",
		MiniButton = true,
		Width = 88,
		ButtonPos = Vector(10, self.FixedBackTable[#self.MenuData[self.GameNavigator][category].Buttons]),
		OnPress = function()
			self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].LevelPages, true, true)
		end
	})

	table.insert(self.MenuData[self.GameNavigator][category_debug].Buttons,
	{
		Text = "Go Back to list",
		MiniButton = true,
		Width = 88,
		ButtonPos = Vector(10, self.FixedBackTable[#self.MenuData[self.GameNavigator][category_debug].Buttons]),
		OnPress = function()
			self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].DebugLevelPages, true, true)
		end
	})
end

function menu:NewItemCategory(...)
	self.PageItemCount = self.PageItemCount + 1
	--Hit the Max, no more Pages (How the fuck would you hit this limit anyway?)
	if self.PageItemCount > 23 then return end
	local category = "DLC_Item_Page " .. self.PageItemCount

	self.DLCDevice[category] = {}
	self.DLCItem[category] = {}
	self.DLCItemIcon[category] = {}
	self.Activity.CacheDLCItemList[category] = {}

	self.MenuData[self.GameNavigator][category] =
	{
		Offset = Vector(0, self:ResOffsetY(10, 8, -90)),
		Mode = "Rows",
		ButtonsPerRow = 6,
		ButtonsPerRowPosX = 1.1,
		ButtonsPerRowPosY = 1.1,
		Buttons = {
			{
				Text = "Go\nBack",
				TextOffsetY = -15,
				MiniButton = true,
				OnPress = function()
					self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator].ItemPages, true, true)
				end,
			},
		}
	}

	table.insert(self.MenuData[self.GameNavigator].ItemPages.Buttons, #self.MenuData[self.GameNavigator].ItemPages.Buttons,
	{
		Text = "Page " .. tostring(self.PageItemCount),
		MiniButton = true,
		IsPage = true,
		OnPress = function()
			self:MenuOnMenuChange(self.GameNavigator, self.MenuData[self.GameNavigator][category])
		end,
	})

	--For the Category Names
	self.ItemCategory[self.PageItemCount] = category

	for i, item in pairs({...}) do
		self.Activity.DLCItemList[item.ID] = item
		self.Activity.CacheDLCItemList[category][#self.Activity.CacheDLCItemList[category] + 1] = item
		self.DLCDevice[category][i] = item.Device(item.Name)

		--It's technically already false by default, but just for incase :)
		item.Blacklisted = self.SLS.Cache.GameOptions.Items.DLC[item.ID] and self.SLS.Cache.GameOptions.Items.DLC[item.ID].Blacklisted or false

		if not item.Blacklisted then self.Activity.CacheItemList[item.ID] = item end
		table.insert(self.MenuData[self.GameNavigator][category].Buttons, i,
		{
			Text = "",
			MiniButton = true,
			OnPress = function()
				item.Blacklisted = not item.Blacklisted
				if item.Blacklisted then
					self.Activity.CacheItemList[item.ID] = nil
					self.SLS.Cache.GameOptions.Items.DLC[item.ID] = {Name = item.Name, Blacklisted = true}
					return
				end

				self.Activity.CacheItemList[item.ID] = item
				self.SLS.Cache.GameOptions.Items.DLC[item.ID] = nil
			end,
		})
		self.DLCItem[category][i] = self.DLCDevice[category][i].PresetName
		self.DLCItemIcon[category][i] = ToMOSprite(self.DLCDevice[category][i])
	end
end

function menu:ResOffsetY(regularOffset, raisedOffset, multiplayerOffset)
	--regularX2, raisedX2
	if self.Activity.IsMultiplayer then
		return multiplayerOffset
	end
	--regular, raised
	return FrameMan.PlayerScreenHeight * 2 >= 720 and regularOffset or raisedOffset
end

function menu:MenuDrawBox(screen, player, posA, posB, selected, design)
	if design == 1 then -- Default
		local arrorColor = 174

		local colors = { 70, 76, 246, 245, 246 }

		if selected then
			colors = { 110, 5, 5, 250, 247 }
		end

		PrimitiveMan:DrawBoxFillPrimitive(screen, posA, posB, colors[1])
		PrimitiveMan:DrawBoxPrimitive(screen, posA, posB, colors[4])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1), posB + Vector(1, 1), colors[3])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 2, posB + Vector(1, 1) * 2, colors[2])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 3, posB + Vector(1, 1) * 3, colors[4])
		PrimitiveMan:DrawBoxFillPrimitive(screen, posA + Vector(-1, -1), posA + Vector(-2, -2), colors[5])
		PrimitiveMan:DrawBoxFillPrimitive(screen,
			Vector(posB.X, posA.Y) + Vector(1, -1),
			Vector(posB.X, posA.Y) + Vector(2, -2),
			colors[5]
		)
		PrimitiveMan:DrawBoxFillPrimitive(screen,
			Vector(posA.X, posB.Y) + Vector(-1, 1),
			Vector(posA.X, posB.Y) + Vector(-2, 2),
			colors[5]
		)
		PrimitiveMan:DrawBoxFillPrimitive(screen, posB + Vector(1, 1), posB + Vector(2, 2), colors[5])
		arrorColor = 251

		if selected then
			local factor = math.sin(self.MenuSelectAnimationFactor[player] * math.pi * 0.5)
			local center = (posA.Y + posB.Y) * 0.5
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posA.X - 15 * factor, center - 5 * factor),
				Vector(posA.X - 15 * factor, center + 5 * factor),
				Vector(posA.X - 10 * factor, center),
				arrorColor
			)
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posB.X + 15 * factor, center - 5 * factor),
				Vector(posB.X + 15 * factor, center + 5 * factor),
				Vector(posB.X + 10 * factor, center),
				arrorColor
			)
		end
	elseif design == 2 then -- Error
		local arrorColor = 174

		local colors = { 248, 1, 249, 248, 249 }

		if selected then
			colors = { 247, 13, 13, 250, 247 }
		end

		PrimitiveMan:DrawBoxFillPrimitive(screen, posA, posB, colors[1])
		PrimitiveMan:DrawBoxPrimitive(screen, posA, posB, colors[4])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1), posB + Vector(1, 1), colors[3])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 2, posB + Vector(1, 1) * 2, colors[2])
		PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 3, posB + Vector(1, 1) * 3, colors[4])
		PrimitiveMan:DrawBoxFillPrimitive(screen, posA + Vector(-1, -1), posA + Vector(-2, -2), colors[5])
		PrimitiveMan:DrawBoxFillPrimitive(screen,
			Vector(posB.X, posA.Y) + Vector(1, -1),
			Vector(posB.X, posA.Y) + Vector(2, -2),
			colors[5]
		)
		PrimitiveMan:DrawBoxFillPrimitive(screen,
			Vector(posA.X, posB.Y) + Vector(-1, 1),
			Vector(posA.X, posB.Y) + Vector(-2, 2),
			colors[5]
		)
		PrimitiveMan:DrawBoxFillPrimitive(screen, posB + Vector(1, 1), posB + Vector(2, 2), colors[5])
		arrorColor = 251

		if selected then
			local factor = math.sin(self.MenuSelectAnimationFactor[player] * math.pi * 0.5)
			local center = (posA.Y + posB.Y) * 0.5
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posA.X - 15 * factor, center - 5 * factor),
				Vector(posA.X - 15 * factor, center + 5 * factor),
				Vector(posA.X - 10 * factor, center),
				arrorColor
			)
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posB.X + 15 * factor, center - 5 * factor),
				Vector(posB.X + 15 * factor, center + 5 * factor),
				Vector(posB.X + 10 * factor, center),
				arrorColor
			)
		end
	elseif design == 3 then
		local arrorColor = 174

		if selected then
			local colors = { 218, 122, 87, 177, 122 }

			PrimitiveMan:DrawBoxFillPrimitive(screen, posA, posB, colors[1])
			PrimitiveMan:DrawBoxPrimitive(screen, posA, posB, colors[4])
			PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1), posB + Vector(1, 1), colors[3])
			PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 2, posB + Vector(1, 1) * 2, colors[2])
			PrimitiveMan:DrawBoxPrimitive(screen, posA + Vector(-1, -1) * 3, posB + Vector(1, 1) * 3, colors[4])
			PrimitiveMan:DrawBoxFillPrimitive(screen, posA + Vector(-1, -1), posA + Vector(-2, -2), colors[5])
			PrimitiveMan:DrawBoxFillPrimitive(screen,
				Vector(posB.X, posA.Y) + Vector(1, -1),
				Vector(posB.X, posA.Y) + Vector(2, -2),
				colors[5]
			)
			PrimitiveMan:DrawBoxFillPrimitive(screen,
				Vector(posA.X, posB.Y) + Vector(-1, 1),
				Vector(posA.X, posB.Y) + Vector(-2, 2),
				colors[5]
			)
			PrimitiveMan:DrawBoxFillPrimitive(screen, posB + Vector(1, 1), posB + Vector(2, 2), colors[5])
			arrorColor = 87

			local factor = math.sin(self.MenuSelectAnimationFactor[player] * math.pi * 0.5)
			local center = (posA.Y + posB.Y) * 0.5
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posA.X - 15 * factor, center - 5 * factor),
				Vector(posA.X - 15 * factor, center + 5 * factor),
				Vector(posA.X - 10 * factor, center),
				arrorColor
			)
			PrimitiveMan:DrawTriangleFillPrimitive(screen,
				Vector(posB.X + 15 * factor, center - 5 * factor),
				Vector(posB.X + 15 * factor, center + 5 * factor),
				Vector(posB.X + 10 * factor, center),
				arrorColor
			)
		end
	end
end

function menu:CharacterButtons()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then

			for i, wrestler in pairs(self.Activity.BaseCharList) do
				self.BaseAHuman[i] = CreateAHuman(wrestler)
				table.insert(self.MenuData[player].CharacterSelect.Buttons, i,
				{
					Text = "",
					MiniButton = true,
					OnPress = function()
						self.Lockedin[player] = true
						self.Activity.SelectedWrestler[player] = wrestler
						self.Activity.WrestlerIcon[player] = self.BaseAHuman[i]:StringValueExists("WrestlerIcon")
						and self.BaseAHuman[i]:GetStringValue("WrestlerIcon")
						or "Wrestling.rte/Unknown Icon"

						self.Activity.DeadIcon[player] = self.BaseAHuman[i]:StringValueExists("DeadWrestlerIcon")
						and self.BaseAHuman[i]:GetStringValue("DeadWrestlerIcon")
						or "Wrestling.rte/Dead Icon"
					end,
				})
				self.BaseActor[i] = self.BaseAHuman[i].PresetName
				self.BaseIcon[i] = ToMOSRotating(self.BaseAHuman[i].Head)
			end
		end
	end
end

function menu:SpawnActors()
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self.Activity:PlayerActive(player) and self.Activity:PlayerHuman(player) then
			local team = self.Activity:GetTeamOfPlayer(player)
			self.MenuActor[player] = nil
			self.MenuActorUID[player] = nil

			local randoChar = self.Activity.DisplayRandoChar[math.random(1, #self.Activity.DisplayRandoChar)]

			self.SceneChar[player] = math.random(0.00, 150.00) < 0.01 and CreateACrab("Crab", "Base.rte") or CreateAHuman(randoChar)
			self.SceneChar[player].Pos = Vector(self.MenuCenter[player].X * 0.75, self.MenuCenter[player].Y * 1.325)
			self.SceneChar[player].Team = -1
			self.SceneChar[player]:GetController().InputMode = Controller.CIM_NETWORK
			self.SceneChar[player].IgnoresTeamHits = true
			self.SceneChar[player].HUDVisible = false
			self.SceneChar[player].PinStrength = 10000
			self.SceneChar[player].HitsMOs = false
			self.SceneChar[player].GetsHitByMOs = false


			for att in self.SceneChar[player].Attachables do
				if string.find(tostring(att), "AEJetpack") then
					att.ToDelete = true
				end
				att.HitsMOs = false
				att.GetsHitByMOs = false
			end

			MovableMan:AddActor(self.SceneChar[player])

			-- Cursor!
			self.Cursors[player] = CreateActor(self.BASE_PATH .. "WM Cursor")
			self.Cursors[player].Pos = self.SceneChar[player].Pos + Vector(0, 0)
			self.Cursors[player].Team = team
			self.Cursors[player].IgnoresTeamHits = true
			self.Cursors[player].HUDVisible = false
			MovableMan:AddActor(self.Cursors[player])
			self.Activity:SwitchToActor(self.Cursors[player], player, team)

			self.MenuActor[player] = self.Cursors[player]
			self.MenuActorUID[player] = self.Cursors[player].UniqueID
		end
	end
end

function menu:SpawnFloater(player, force)
	local randoChar = self.Activity.DisplayRandoChar[math.random(1, #self.Activity.DisplayRandoChar)]

	local floater = math.random(0.00, 150.00) < 0.01 and CreateACrab("Base.rte/Crab") or CreateAHuman(randoChar)
	local floaterVel
	if self.DebugModeActivated then
		floaterVel = 3.5
	else
		floaterVel = 10
	end
	if self.FloatDirection == 1 then
		floater.Pos = Vector(force ~= nil and (force + self.MenuCenter[player].X) or self.MenuCenter[player].X + FrameMan.PlayerScreenWidth + 100, self.MenuCenter[player].Y)
		floater.Vel = Vector(RangeRand(0.75, 2.0) * (floaterVel * -1), RangeRand(-1, 1) * 1)
	else
		floater.Pos = Vector(force ~= nil and (-force + self.MenuCenter[player].X) or self.MenuCenter[player].X + -FrameMan.PlayerScreenWidth + 100, self.MenuCenter[player].Y)
		floater.Vel = Vector(RangeRand(0.75, 2.0) * floaterVel, RangeRand(-1, 1) * 1)
	end
	floater.Team = -1
	floater.PlayerControllable = false
	floater.RotAngle = RangeRand(-2, 2) * math.pi
	floater.AngularVel = RangeRand(-1, 1) * 30
	floater.GlobalAccScalar = 0.0
	floater.HitsMOs = false
	floater.GetsHitByMOs = false
	floater.IgnoresTeamHits = true
	floater.HUDVisible = false
	floater:GetController().InputMode = Controller.CIM_DISABLED
	floater.Status = Actor.INACTIVE

	for att in floater.Attachables do
		if string.find(tostring(att), "AEJetpack") then
			att.ToDelete = true
		end
		att.HitsMOs = false
		att.GetsHitByMOs = false
	end

	MovableMan:AddActor(floater)
end

--[[---------------------------------------------------------
	Name: DebugKeyCombo_NotActivated( Player )
	Desc: Events that will happen when we successfully inputed the debug combo
		Debug_PlayerSignal() is not involved in this code!
		Not to be confused with self.Activity.EnableDebugMode
------------------------------------------------------------]]
function menu:DebugKeyCombo_Activated(player)
	if self.InputComboTimer:IsPastSimMS(300) then
		self.InputCombo = false
		self:PlayerMovement(player, true)
		return
	end

	self:PlayerMovement(player, false)
end

--[[---------------------------------------------------------
	Name: DebugKeyCombo_NotActivated( Player )
	Desc: Events that will happen when we never completed the debug combo
		Debug_PlayerSignal() is not involved in this code!
------------------------------------------------------------]]
function menu:DebugKeyCombo_NotActivated(player)
	self.DebugMusicTimer:Reset()
	self.InputComboTimer:Reset()

	if UInputMan:KeyPressed(Key.P) then
		self.Sound.Access:Play(-1)
		self.InputCombo = not self.InputCombo
		if self.InputCombo then
			self.Sound.InputVoice:Play(-1)
		end
		self:InsertCodeDisplay(self.InputCombo, "YELLOW", "FLYBYRIGHTWARD", "INPUT", Vector(-225, 0.1 + 0.23))
		self:InsertCodeDisplay(self.InputCombo, "RED", "FLYBYLEFTWARD", "CODE", Vector(220, 0.1 + 0.23))
	end

	if self.InputCombo then
		if not self.Activity.SecretIndex then
			self.Activity.SecretIndex = SecretCodeEntry.Setup(self.Activity.EnableDebugMode, self.Activity, {37, 38, 36, 35, 38, 37}, self.Sound.SecretKey, self.Sound.SecretKey, self.Sound.InputVoice_4, self.Sound.InputVoice_2)
		end
		self:PlayerMovement(player, false)
		if self.Activity.IsMultiplayer then
			self.Activity:DrawBitmapText(player, "Press P to EXIT", Vector(200, 330), 13)
		else
			self.Activity:DrawBitmapText(player, "Press P to EXIT", self.Activity.PlayerCount ~= 2 and Vector(25, 160) or Vector(310, 160), 13)
		end
		return
	end
	if self.Activity.SecretIndex then
		self.Activity.SecretIndex = nil
	end
end

function menu:Debug_PlayerSignal(player)
	--This code is so fucking funky, it works I guess lmao
	if player == self.GameNavigator then
		if not self.InputCombo then
			for i, button in ipairs(self.MenuCurrent[player].Buttons) do
				if i == (self.MenuCurrentButton[player] + 1) then
					if (button.HasInput ~= nil and button.DisableButton ~= nil) then
						button.DisableButton = button.JustPress
					end
					self:PlayerMovement(player, not button.DisableButton)
				end
			end
			self:PressSignal(player)
		end
	else
		self:PressSignal(player)
	end
end

--[[---------------------------------------------------------
	Name: InsertKeyToAllButtons( Player, New_key )
	Desc: Iterate through all menus, to each and every button
		This makes it easier so that you don't to go around and giving 1 extra key to EVERYTHING
------------------------------------------------------------]]
function menu:InsertKeyToAllButtons(player, new_key)
	for currentMenu, v in pairs(self.MenuData[player]) do
		for k, button_table in pairs(self.MenuData[player][currentMenu]) do
			if type(button_table) == "table" then
				for i, button in pairs(self.MenuData[player][currentMenu][k]) do
					if type(button) == "table" then
						if button[new_key] == nil then
							button[new_key] = false
						end
					end
				end
			end
		end
	end
end

function menu:OnDebugModeActivation()
	AudioMan:StopMusic(); AudioMan:ClearMusicQueue()
	AudioMan:PlayMusic("Wrestling.rte/Scenes/Maps/Menu/Music/main-menu-Debug.mp3", -1, -1)
	for BG in SceneMan.Scene.BackgroundLayers do
		if self.FloatDirection == -1 then
			BG.AutoScrollStepX = -0.5
		elseif self.FloatDirection == 1 then
			BG.AutoScrollStepX = 0.5
		end
	end
	self.Sound.MenuMove.Pitch = self.Sound.MenuMove.Pitch / 3
	self.Sound.Access.Pitch = self.Sound.Access.Pitch / 3
	self.Sound.Error.Pitch = self.Sound.Error.Pitch / 3
	self.Sound.SecretKey.Pitch = self.Sound.SecretKey.Pitch / 3
	self.Sound.MenuSelect.Pitch = self.Sound.MenuSelect.Pitch / 1.5
	self.Sound.MenuSelect.Volume = 4
	self:InsertCodeDisplay(false, "YELLOW")
	self:InsertCodeDisplay(false, "RED")
end

function menu:UpdateNavigatorLevel(table_name, table_name_2, isDebug)
	--No Pages
	local screen = self.Activity:ScreenOfPlayer(self.GameNavigator)
	if self.MenuCurrent[self.GameNavigator] == self.MenuData[self.GameNavigator][table_name] then

		for i, level in pairs(self.BaseMap) do
			local text

			if level then
				text = level
			end

			local button = self:PageData(self.GameNavigator, i, 88, 54, Vector(10, 10))

			PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos, self.BasePreview[i], 0, 0)
			PrimitiveMan:DrawTextPrimitive(screen, button.Pos + Vector(0, -7), text, false, 1)
		end
		PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[self.GameNavigator] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), isDebug and "DEBUG Main Page" or "Main Page", false, 1)
	end

	for i, category in pairs(table_name_2) do
		if self.MenuData[self.GameNavigator][category] then
			if self.MenuCurrent[self.GameNavigator] == self.MenuData[self.GameNavigator][category] then

				for ii, level in pairs(self.DLCMap[category]) do
					local text

					if level then
						text = level
					end

					local button = self:PageData(self.GameNavigator, ii, 88, 54, Vector(10, 10))

					PrimitiveMan:DrawBitmapPrimitive(screen, button.Pos, self.DLCPreview[category][ii], 0, 0)
					PrimitiveMan:DrawTextPrimitive(screen, button.Pos + Vector(0, -7), text, false, 1)
				end
				PrimitiveMan:DrawTextPrimitive(screen, self.MenuPos[self.GameNavigator] + Vector(-170, self.Activity.IsMultiplayer and -150 or -50), (isDebug and "Debug Page: " or "Page: ") .. tostring(i), false, 1)
			end
		end
	end
end

function menu:PageData(player, index, w, h, pos)
	local data = {}
	data.Width = w
	data.Height = h
	data.Pos = self.MenuPos[player] + self.MenuCurrent[player].Offset + pos
	data.PerRow = self.MenuCurrent[player].ButtonsPerRow
	data.Row = math.floor((index - 1) / data.PerRow)
	data.Column = ((index - 1) % data.PerRow) - (self.MenuCurrent[player].ButtonsPerRowPosX or 0.5)
	data.Pos = data.Pos + Vector((data.Width * 1.25 + 20) * data.Column, (data.Height + 20) * data.Row)

	return data
end

function menu:NotEqualData()
	local hasChanges = false

	local localGameList = table.Copy(self.SLS.Cache.GameOptions)
	local localOptionList = table.Copy(self.SLS.Cache.Options)
	local settingGameList = table.Copy(self.SLS.Settings.GameOptions)
	local settingOptionList = table.Copy(self.SLS.Settings.Options)

	--[[
	TableToSave_A: GameOption | TableToSave_B: Option
	Since local data could get changed, we see if it matches the saved data
	Items table is treated different since it's more of actually checking if it exists rather than just value
	]]
	for local_game_key, local_game_value in pairs(localGameList) do
		if type(local_game_value) ~= "table" then
			if settingGameList[local_game_key] ~= local_game_value then
				hasChanges = true
				self.TableToSave_A = true
				break
			end
		end

		if local_game_key == "Items" then
			--[[
			We have to do a loop for both, because quirky ass behavior
			I kept trying to do inverse with only one table, but we need to compare both or else it'll keep
			Asking the player if they want to save their god damn changes
			]]
			local function itemTableA(table_type)
				for id, data in pairs(settingGameList.Items[table_type]) do
					if not local_game_value[table_type][id] then
						hasChanges = true
						self.TableToSave_A = true
						break
					end
				end
			end

			local function itemTableB(table_type)
				for id, data in pairs(local_game_value[table_type]) do
					if not settingGameList.Items[table_type][id] then
						hasChanges = true
						self.TableToSave_A = true
						break
					end
				end
			end

			itemTableA("Base")
			itemTableA("DLC")

			itemTableB("Base")
			itemTableB("DLC")
		end
	end

	--Since local data could get changed, we see if it matches the saved data
	for local_setting_key, local_setting_value in pairs(localOptionList) do
		if settingOptionList[local_setting_key] ~= local_setting_value then
			hasChanges = true
			self.TableToSave_B = true
			break
		end
	end

	return hasChanges
end

return menu