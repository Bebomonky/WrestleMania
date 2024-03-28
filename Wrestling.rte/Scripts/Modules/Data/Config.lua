local config = {}

function config:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function config:Initialize()
	self.DebugMode = false
	--Ability Lengths in Milliseconds
	self.BoostLength = 5000

	--Everything below this comment actually does something
	self.HealthMultiplier = 100

	--Crate Spawn in Milliseconds
	self.CrateHighTime = 9000
	self.CrateNormalTime = 15000
	self.CrateLowTime = 25000
end

return config:Create()