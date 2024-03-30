local volcano = {}

function volcano:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function volcano:StartScript(activity)
	self.Activity = activity

	local player_spawns = {Vector(225, 370), Vector(250, 200), Vector(300, 200), Vector(350, 210), Vector(500, 320), Vector(550, 310), Vector(110, 340), Vector(300, 385), Vector(170, 360)}
	self.Activity:SetSpawn(player_spawns)

	self.Activity:SetCrate("Wrestling.rte/Wooden Crate", {-250, -200, -135, -100, -50, 0, 50, 78, 165, 200, 250})
end

function volcano:UpdateScript()
end

return volcano:Create()