function Create(self) end

local function FuseEffect(self)
	local spark = CreateMOPixel("Base.rte/Spark Yellow " .. math.random(2))
	spark.Pos = self.Pos - Vector(5 * self.FlipFactor, 6):RadRotate(self.RotAngle)
	spark.Vel = self.Vel - Vector(5 * self.FlipFactor, 8):RadRotate(self.RotAngle):SetMagnitude(10 / (1 + math.abs(RangeRand(-0.3, 0.3))))
	spark.Lifetime = 250

	local glow = CreateMOPixel("Wrestling.rte/" .. self.PresetName .. " Flash")
	glow.Pos = self.Pos - Vector(5 * self.FlipFactor, 8):RadRotate(self.RotAngle)

	MovableMan:AddParticle(spark)
	MovableMan:AddParticle(glow)

	--wtf (Doing this prevent it from going crazy!)
	if not MovableMan:IsParticle(self.FuseSound) then
		self.FuseSound = CreateAEmitter("Wrestling.rte/" .. self.PresetName .. " Sound")
		self.FuseSound.Pos = self.Pos
		MovableMan:AddParticle(self.FuseSound)
	end
	self:Activate()
end
function Update(self)
	local parent = self:GetRootParent()
	if parent and IsActor(parent) then
		parent = ToActor(parent)
		FuseEffect(self)
	end
	if self:IsActivated() then
		FuseEffect(self)
	end
end