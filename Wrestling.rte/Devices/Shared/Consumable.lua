function Create(self)
	self.confirmSound = CreateSoundContainer("Base.rte/Confirm")
	self.confirmSound.Immobile = false
	self.IsConsumed = false
	self.Activity = ActivityMan:GetActivity()
end
function OnFire(self)
	local object = {}
	object.Name = self.PresetName
	object.Effect = self:StringValueExists("EffectName") and self:GetStringValue("EffectName") or nil
	object.EffectLength = self:NumberValueExists("EffectLength") and self:GetNumberValue("EffectLength") or nil
	object.Player = ToActor(self:GetRootParent()):GetController().Player
	local parent = self:GetRootParent()
	if parent and IsActor(parent) then
		parent = ToActor(parent)
		if (parent.Health < parent.MaxHealth or parent.WoundCount > 0) then
			Heal(self, parent)
		end
	end
	self.Activity:SendMessage("WrestleMania_ItemData", object)
	self.IsConsumed = true
end

function Update(self)
	if self.IsConsumed then
		self.ToDelete = true
	end
end

function Heal(self, actor)
	actor:FlashWhite(50)
	actor.Health = math.min(actor.Health + 15, actor.MaxHealth)
	self.confirmSound:Play(self.Pos)
	local particleCount = math.ceil(1 + actor.Radius * 0.5)
	for i = 1, particleCount do
		local part = CreateMOPixel("Base.rte/Heal Glow")
		local vec = Vector(particleCount * 2, 0):RadRotate(math.pi * 2 * i / particleCount)
		part.Pos = actor.Pos + Vector(0, -particleCount * 0.3):RadRotate(actor.RotAngle) + vec
		part.Vel = actor.Vel * 0.5 - Vector(vec.X, vec.Y) * 0.25
		MovableMan:AddParticle(part)
	end
	local cross = CreateMOSParticle("Base.rte/Particle Heal Effect")
	cross.Pos = actor.AboveHUDPos + Vector(0, 5)
	MovableMan:AddParticle(cross)
end