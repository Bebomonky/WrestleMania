dofile("Mods/Wrestling.rte/Scripts/Modules/Core/ModuleManagement.lua")
dofile("Mods/Wrestling.rte/Scripts/Modules/Core/GameplayUtility.lua")
dofile("Mods/Wrestling.rte/Scripts/Modules/Core/Gameplay.lua")
dofile("Mods/Wrestling.rte/Scripts/Modules/Core/GameMessages.lua")
dofile("Mods/Wrestling.rte/Scripts/Modules/Core/GameManager_Functions.lua")
require("Scripts/Shared/SecretCodeEntry")

function WrestleMania:StartActivity()
	self.IsMultiplayer = true
	self:InitializeActivity()
end

function WrestleMania:UpdateActivity()
	--* Doing this magically fix's this error
	--WARNING: Could not find the requested Scene Area named : WrestleManiaAntiBugZone
	if not self._WrestleManiaAntiBugZone then
		self._WrestleManiaAntiBugZone = SceneMan.Scene:GetArea("WrestleManiaAntiBugZone")
	end
	self:CheckCurrentStage()
end

function WrestleMania:PauseActivity(pause)
	self.pause = pause
	if self.MatchEnded then self:HideHud(false) return end

	if self.ShouldShowHud then return end --Gameplay
	if self:IsMenu() then
		if self.Menu.InputCombo then
			self.Menu.InputCombo = false
		end
	end
	self:HideHud(not pause)
end

--Useless until further notice
function WrestleMania:EndActivity()
	--[[
	self:ClearObjectivePoints()
	self:CoreEnd()
	]]
end