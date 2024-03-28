local game = {}

function game:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function game:Initialize()
	-- System Settings
	self.Settings = {
		GameOptions =
		{
			PlayerLives = 0,
			PlayerHealth = 0,
			CrateRespawnTime = 2,
			PlayerRespawnTime = 0,
			MatchTime = 0,
			LivesDisabled = false,
			RegenHP = true,
			Items = {Base = {}, DLC = {}},
		},

		Options =
		{
			--Volume
			--SFXVolume = 1,
			AnnouncerVolume = 1,
			CheerVolume = 1,
		}
	}
end

return game:Create()