-----------------------------------------------------------------------------------------
-- Save / Load System
-----------------------------------------------------------------------------------------
local sls = {}

function sls:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function sls:Initialize(activity)
	self.Activity = activity
end

function sls:LoadDataFile()
	self.Settings = self:GetDataFile()
end

--[[---------------------------------------------------------
	Name: GetDataFile()
	Desc: Internally uses LuaMan and loadstring() from filemanager module, and returns information from file or recreates it from game module
------------------------------------------------------------]]
function sls:GetDataFile()
	return self.Activity.FileManager:ReadOrWriteTable(self.Activity.ModuleName .. "/" .. "Settings/Settings.save", self.Activity.Game.Settings)
end

function sls:GameVolume()
	for i = 1, 4 do
		self.Activity.SFXTracks[i].Volume = self.Cache.Options.AnnouncerVolume
		if self.Activity.SFXTracks[i].Volume == 1 then
			self.Activity.SFXTracks[i].Volume = 5
		end
	end
	for i = 5, 7 do
		self.Activity.SFXTracks[i].Volume = self.Cache.Options.CheerVolume
	end
end

function sls:ResetSettings(reset_type)
	if reset_type == 1 then
		self.Cache.GameOptions = table.Copy(self.Activity.Game.Settings.GameOptions)
		ExtensionMan.print_notice("Resetting...", "Game Options")
		self:SaveSettings(reset_type)
		self:LoadGameSettings()
	elseif reset_type == 2 then
		self.Cache.Options = table.Copy(self.Activity.Game.Settings.Options)
		ExtensionMan.print_notice("Resetting...", "Options")
		self:SaveSettings(reset_type)
		self:LoadSettings()
	end
end

function sls:SaveSettings(save_type)
	if save_type == 1 then
		self.Settings.GameOptions = table.Copy(self.Cache.GameOptions)
		ExtensionMan.print_notice("Saving...", "Game Options")
	elseif save_type == 2 then
		self.Settings.Options = table.Copy(self.Cache.Options)
		ExtensionMan.print_notice("Saving...", "Options")
	else
		self.Settings.GameOptions = table.Copy(self.Cache.GameOptions)
		self.Settings.Options = table.Copy(self.Cache.Options)
		ExtensionMan.print_notice("Saving...", "All Options")
	end

	self:SaveDataToFile(self.Settings, "Settings")
end

function sls:LoadSettings()
	self.Cache.Options = table.Copy(self.Settings.Options)
	self:GameVolume()
	self.AnnouncerVolumeText[1] = "Announcer\nVolume " .. tostring(math.floor(self.Cache.Options.AnnouncerVolume * 100)) .. "%"

	self.CheerVolumeText[1] = "Cheer\nVolume " .. tostring(math.floor(self.Cache.Options.CheerVolume * 100)) .. "%"
end

function sls:LoadGameSettings()
	self.Cache.GameOptions = table.Copy(self.Settings.GameOptions)

	self.LivesText[1] = "Total Lives\n" .. self.PlayerLives[self.Cache.GameOptions.PlayerLives + 1]

	self.HealthText[1] = "Total Health\n" .. self.PlayerHealth[self.Cache.GameOptions.PlayerHealth + 1] * self.Activity.Config.HealthMultiplier

	self.CrateSpawnText[1] = "Crate Rate\n" .. self.CrateRespawnTime[self.Cache.GameOptions.CrateRespawnTime + 1]

	self.PlayerSpawnText[1] = "Spawn Time\n" .. self.PlayerRespawnTime[self.Cache.GameOptions.PlayerRespawnTime + 1] .. " Seconds"

	self.MatchTimeText[1] = "Match Time\n" .. self.MatchTime[self.Cache.GameOptions.MatchTime + 1] .. " Minutes"

	local ld = { [true] = "No Lives\nON", [false] = "No Lives\nOFF" }
	self.LivesDisabledText[1] = ld[self.Cache.GameOptions.LivesDisabled]

	local rhp = { [true] = "RegenHP\nON", [false] = "RegenHP\nOFF" }
	self.RegenHPText[1] = rhp[self.Cache.GameOptions.RegenHP]

	for i, item in pairs(self.Activity.BaseItemList) do
		if not self.Cache.GameOptions.Items.Base[item.ID] then
			if item.Blacklisted then
				item.Blacklisted = false
			end
		end
	end


	--?When the activity is started for the first time, this will not work (GOOD THING)
	--?When you resetgame data then it'll work
	for i, category in pairs(self.Activity.Menu.ItemCategory) do
		if self.Activity.Menu.MenuData[self.Activity.Menu.GameNavigator][category] then
			for ii, item in pairs(self.Activity.CacheDLCItemList[category]) do
				if not self.Cache.GameOptions.Items.DLC[item.ID] then
					if item.Blacklisted then
						item.Blacklisted = false
					end
				end
			end
		end
	end

	self.CacheItemListText = "Item\nWhitelist"
end

--This is specifcally for item checking for when dlc items are added
function sls:CheckItemLists()
	self.RemovingNonExistantItems = false
	--This is so that once they are removed we can just setup a timer to just save it afterwards!
	for id, v in pairs(self.Cache.GameOptions.Items.DLC) do
		if not self.Activity.DLCItemList[id] and self.Cache.GameOptions.Items.DLC[id] then
			self.Cache.GameOptions.Items.DLC[id] = nil
			ExtensionMan.print_notice("Removing...", "This ID: " .. id .. " no longer truly exists!")
			self.RemovingNonExistantItems = true
		end
	end

	if self.RemovingNonExistantItems then
		self.SaveTimer = Timer()
		self.SaveTimer:SetSimTimeLimitMS(1000)
		ExtensionMan.print_notice("Running...",
		"Save timer is active due to cache data being modified! It'll be done in "
		.. -math.floor(self.SaveTimer:LeftTillSimTimeLimitMS()) .. " Second(s)")
	end
end

function sls:InitData()
	--Options
	--Local data that is to be saved
	self.Cache = {}
	self.Cache.GameOptions = {}
	self.Cache.Options = {}

	self.Cache.Options.AnnouncerVolume = 1
	self.AnnouncerVolumeText = { "Announcer\nVolume 100%" }

	self.Cache.Options.CheerVolume = 1
	self.CheerVolumeText = { "Cheer\nVolume 100%" }

	self.PlayerLives = {2, 3, 4, 5}
	self.Cache.GameOptions.PlayerLives = 0
	self.LivesText = { "Total Lives\n" .. self.PlayerLives[self.Cache.GameOptions.PlayerLives + 1] }

	self.PlayerHealth = {1, 2, 3, 4, 5}
	self.Cache.GameOptions.PlayerHealth = 0
	self.HealthText = { "Total Health\n" .. self.PlayerHealth[self.Cache.GameOptions.PlayerHealth + 1] * self.Activity.Config.HealthMultiplier }

	self.CrateRespawnTime = { "None", "Low", "Normal", "High" }
	self.Cache.GameOptions.CrateRespawnTime = 2
	self.CrateSpawnText = { "Crate Rate\n" .. self.CrateRespawnTime[self.Cache.GameOptions.CrateRespawnTime + 1] }

	self.PlayerRespawnTime = {2, 3, 4, 5}
	self.Cache.GameOptions.PlayerRespawnTime = 0
	self.PlayerSpawnText = {"Spawn Time\n" .. self.PlayerRespawnTime[self.Cache.GameOptions.PlayerRespawnTime + 1] .. " Seconds" }

	self.MatchTime = {5, 10}
	self.Cache.GameOptions.MatchTime = 0
	self.MatchTimeText = { "Match Time\n" .. self.MatchTime[self.Cache.GameOptions.MatchTime + 1] .. " Minutes" }

	self.Cache.GameOptions.LivesDisabled = false
	self.LivesDisabledText = { "LivesDisabled Mode" }

	self.Cache.GameOptions.RegenHP = false
	self.RegenHPText = { "RegenHP Mode" }

	self.Cache.GameOptions.Items = {}
	self.Cache.GameOptions.Items.Base = {}
	self.Cache.GameOptions.Items.DLC = {}
	self.CacheItemListText = "Item\nWhitelist"
end

function sls:SaveDataToFile(data, file)
	assert(type(data) == "table", "The data you have provided is not a actual table! No data saved...")

	local filepath = self.Activity.ModuleName .. "/" .. "Settings/" .. file .. ".save"
	self.Activity.FileManager:WriteTableToFile(filepath, data)
	ExtensionMan.print_done("Data saved to " .. file)
end

return sls:Create()