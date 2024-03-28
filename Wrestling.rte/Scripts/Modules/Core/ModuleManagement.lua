--[[---------------------------------------------------------
	Name: LoadModule( Path, IsLevel )
	Desc: returns loaded module.
		Module must be a metatable to begin with, to be loaded.
		[BAD IDEA] -> Or if the module is to be loaded everytime via dofile
------------------------------------------------------------]]
function WrestleMania:LoadModule(path, isLevel)
	local MODULE_PATH
	if isLevel then
		MODULE_PATH = "Scenes/Maps/"
	else
		MODULE_PATH = "Scripts/Modules/"
	end

	ExtensionMan.print_debug("Loading Module: " .. path)
	self:UnloadModule_require(path, isLevel)
	return require(MODULE_PATH .. path)
end

--[[---------------------------------------------------------
	Name: UnloadModule_require( Path )
	Desc: Unloads module from the the package.loaders array.
------------------------------------------------------------]]
function WrestleMania:UnloadModule_require(path, isLevel)
	local MODULE_PATH
	if isLevel then
		MODULE_PATH = "Scenes/Maps/"
	else
		MODULE_PATH = "Scripts/Modules/"
	end
	if package.loaded[MODULE_PATH .. path] ~= nil then
		package.loaded[MODULE_PATH .. path] = nil
	end
end

--[[---------------------------------------------------------
	Name: UnloadModule_dofile( Path )
	Desc: Sets module to nil (not to be confused with UnloadModule_require)
------------------------------------------------------------]]
function WrestleMania:UnloadModule_dofile(module)
	if self[module] ~= nil then
		ExtensionMan.print_debug("Unloading Module_dofile: " .. module)
		self[module] = nil
	end
end

--[[---------------------------------------------------------
	Name: GameModules()
	Desc: Modules for the game ONLY
------------------------------------------------------------]]
function WrestleMania:GameModules()
	self.DLC_Category = self:LoadModule("Game/Categorys")
	self.DLC_Category:Initialize(self)

	self:Load_Base_Items()
end

--[[---------------------------------------------------------
	Name: LoadCoreModules()
	Desc: Core Modules (Always just be loaded first)
        Even if they aren't in the "Core" folder they are stll important!
------------------------------------------------------------]]
function WrestleMania:LoadCoreModules()

	self.Game = self:LoadModule("Data/Game")
	self.Game:Initialize()

	--Game stuff
	self.Config = self:LoadModule("Data/Config")
	self.Config:Initialize()

	--Data Management
	self.FileManager = self:LoadModule("Data/FileManager")

	self.SLS = self:LoadModule("Data/SaveLoadSystem")
	self.SLS:Initialize(self)
	--? This isn't actual game data, this is cache data, it's safe to load this first
	self.SLS:InitData()

	self.Misc = self:LoadModule("Data/Misc")
	self.Misc:Load_Misc() -- Resolution, soundlist, etc

	self.HUDHandler = require("Activities/Utility/HUDHandler")
	self.HUDHandler:Initialize(self, false, false)
end

--[[---------------------------------------------------------
	Name: MenuModules()
	Desc: Modules for the Menu ONLY
------------------------------------------------------------]]
function WrestleMania:MenuModules()
	--self:UnloadModule("MainMenu/Menu")

	self.Menu = self:LoadModule("MainMenu/Menu")
	self.Menu:Initialize(self)
end