local stadium = {}

function stadium:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function stadium:StartScript(activity)
	self:ScriptData(activity)
end

function stadium:ScriptData(activity)
	activity:SetSpawn(Vector(225, 417), 55)

	local npcs = {
		{actor = "Coalition.rte/Soldier Light", 		Pos = Vector(13, 262), 	HFlipped = false},
		{actor = "Ronin.rte/Bandit", 					Pos = Vector(42, 288), 	HFlipped = false},
		{actor = "Coalition.rte/Soldier Light", 		Pos = Vector(71, 314), 	HFlipped = false},
		{actor = "Imperatus.rte/All Purpose Robot", 	Pos = Vector(103, 337), HFlipped = false},
		{actor = "Ronin.rte/Bandit", 					Pos = Vector(129, 366), HFlipped = false},
		{actor = "Imperatus.rte/Combat Robot", 			Pos = Vector(161, 385), HFlipped = false},
		{actor = "Coalition.rte/Soldier Light", 		Pos = Vector(626, 262), HFlipped = true},
		{actor = "Ronin.rte/Bandit", 					Pos = Vector(597, 288), HFlipped = true},
		{actor = "Coalition.rte/Soldier Light", 		Pos = Vector(568, 314), HFlipped = true},
		{actor = "Imperatus.rte/All Purpose Robot", 	Pos = Vector(545, 337), HFlipped = true},
		{actor = "Ronin.rte/Bandit",					Pos = Vector(510, 366), HFlipped = true},
		{actor = "Imperatus.rte/Combat Robot", 			Pos = Vector(478, 385), HFlipped = true}
	}

	for k, list in pairs(npcs) do
		activity:SpawnSpectator(list.actor, list.Pos, list.HFlipped)
	end

	activity:SetCrate("Wrestling.rte/Wooden Crate", {50, 100, 150, 200, 250, 300, 350, 400, 500, 550, 600})
end

function stadium:UpdateScript(activity)
end

return stadium:Create()