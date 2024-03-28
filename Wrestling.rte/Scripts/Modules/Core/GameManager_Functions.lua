function WrestleMania:InitializeActivity()
	self:EnableSaving(false) --Activity is not meant to ever save!
	self.MenuScene = "Wrestle Mania Main Menu"
	if not self:IsMenu() then
		SceneMan:LoadScene("Wrestle Mania Main Menu", true, true)
	end
	self:LoadCoreModules()
	self:GameModules()
	self:MenuModules()
	self._WrestleManiaAntiBugZone = nil
	self:HideHud(true); self.ShouldShowHud = false
end

--[[---------------------------------------------------------
	Name: UpdatePaletteOnPause( num )
	Desc: Undo's changes made by the activity, to prevent them from carrying on to
		other activities!
		Unload / Reload palette determined when game is paused.
		This is helpful to prevent the palette from being incorrect when you pause the game
------------------------------------------------------------]]
function WrestleMania:UpdateGameOnPause(num)
	if self.pause then
		--Reset anything that we need, so it doesn't break!
		self.CustomPalette = false
		self:LoadNewPalette(1) --Base.rte
	else
		if not self.CustomPalette then
			self:LoadNewPalette(num)
			self.CustomPalette = true
		end
	end
end

--[[---------------------------------------------------------
	Name: CheckCurrentStage()
	Desc: checks the game stage and what to do for each stage
------------------------------------------------------------]]
function WrestleMania:CheckCurrentStage()
	if self.CurrentSceneStage == self.SceneStage.Menu then
		self.Menu:Update()
		if self.SecretIndex and SecretCodeEntry.IsValid(self.SecretIndex) then SecretCodeEntry.Update(self.SecretIndex) end
	elseif self.CurrentSceneStage == self.SceneStage.Gameplay then
		self:ClearObjectivePoints()
		self:CoreUpdate()
	elseif self.CurrentSceneStage == self.SceneStage.Idle then
		self:CoreUpdate_Idle()
		self:Debugging()
	elseif self.CurrentSceneStage == self.SceneStage.End then
		self:ClearObjectivePoints()
		self:CoreUpdate_End()
	end
end

--[[---------------------------------------------------------
	Name: LaunchLevel( Scene, Script, Mode )
	Desc: Information is retrieved from Menu.lua
		loads gamemodescript
		loads the scenes objects and actors (actors in the ini, not the script!)
		adjusts SFXTracks volume for announcer
		regardless makes the palette to base.rte because incase of DebugMode
------------------------------------------------------------]]
function WrestleMania:LaunchLevel(scene, script, mode)
	self.Menu.InitiateGame = false --! Doing this should prevent this code from running more than once!
	ExtensionMan.print_debug("PREVIOUS SCENE: " .. SceneMan.Scene.PresetName)

	--Clear previous functions
	self.StartGamemode = nil
	self.UpdateGamemode = nil

	dofile("Mods/Wrestling.rte/Scripts/Gamemodes/" .. script)
	self.GamemodeType = mode
	if scene ~= nil then
		ExtensionMan.print_debug("NEW SCENE: " .. scene)
		SceneMan:LoadScene(scene, true, true)
	end

	for i = 1, 4 do
		if self.SFXTracks[i].Volume == 1 then
			self.SFXTracks[i].Volume = 5
		end
	end

	self:LoadNewPalette(1)
	self:HideHud(false); self.ShouldShowHud = true
	if self.ViewerMode then
		self:CoreCreate_Idle()
	else
		self:CoreCreate()
	end
end

--[[---------------------------------------------------------
	Name: IsMenu()
	Desc: return true / false if we are on the actual menu scene
------------------------------------------------------------]]
function WrestleMania:IsMenu()
	if SceneMan.Scene.PresetName == self.MenuScene then
		return true
	end
	return false
end

function WrestleMania:EnableSaving(bool) if ActivityMan:GetActivity().AllowsUserSaving ~= bool then ActivityMan:GetActivity().AllowsUserSaving = bool end end

--[[---------------------------------------------------------
	Name: HideHud( Bool )
	Desc: loops through all real players (no AI)
		and enables / disables the UI (everything)
------------------------------------------------------------]]
function WrestleMania:HideHud(bool)
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			FrameMan:SetHudDisabled(bool, self:ScreenOfPlayer(player))
		end
	end
end

--[[---------------------------------------------------------
	Name: DrawText( Txt, Pos, Dist )
	Desc: Draws text on screen via bitmap,
		Distance between each
		Position of the text
------------------------------------------------------------]]
function WrestleMania:DrawBitmapText(player, txt, pos, dist)
	txt = string.upper(txt)
	for i = 1, string.len(txt) do
		local letter = string.sub(txt, i, i)
		local digit = self.LetterMap[letter]
		local word = CreateMOSRotating("Wrestling.rte/Letter " .. digit)

		PrimitiveMan:DrawBitmapPrimitive(self:ScreenOfPlayer(player), self.HUDHandler:MakeRelativeToScreenPos(player, pos + Vector((i - 1) * (dist or 13), 0)), word, 0, 0)
	end
end

function WrestleMania:EnableDebugMode()
	local gameNav = 0
	table.insert(self.Menu.MenuData[gameNav].Main.Buttons, #self.Menu.MenuData[gameNav].Main.Buttons + 1,
	{
		Text = "DEBUG MODE",
		Hint = "This is where I put stuff",
		HintOffsetY = 18,
		OnPress = function()
			self.Menu:MenuOnMenuChange(gameNav, self.Menu.MenuData[gameNav].DebugPage)
		end,
	}
	)
	self.Config.DebugMode = true
	self.SecretIndex = nil
end

----------------------------------------------------------------------------------------
-- Palette Handler
----------------------------------------------------------------------------------------

function WrestleMania:InitCustomPalette()
	--CustomPalette is set to false by default (make it true afterwards)
	self.CustomPalette = false

	local FilePath = "Wrestling.rte/Sprites/Materials/"
	self.PaletteList =
	{
		"Base.rte/palette.bmp", -- 1
		FilePath .. "paletteNight1.png", -- 2
		FilePath .. "paletteNight2.png", -- 3
		FilePath .. "paletteNight3.png" -- 4
	}
end

--[[---------------------------------------------------------
	Name: LoadNewPalette( new )
	Desc: Load new palette via sprite path
------------------------------------------------------------]]
function WrestleMania:LoadNewPalette(new)
	local newPalette = self.PaletteList[new]
	FrameMan:LoadPalette(newPalette)
end