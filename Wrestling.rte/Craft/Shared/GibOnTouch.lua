function Create(self)
	self.Activity = ToGameActivity(ActivityMan:GetActivity())
	self.Vel = Vector()
	self.UpRightTimer = Timer()
	self.UpRightTimer:SetSimTimeLimitMS(200)
	MovableMan:ChangeActorTeam(self, Activity.NOTEAM)
	self.AIMode = Actor.AIMODE_STAY

	self.FallSpeed = 6
	self.Length = ToMOSprite(self):GetSpriteHeight() - 10
end
function Update(self)
	if self.TerrainFound then --During the landing
		self.Vel = Vector() --Reset Velocity
		self:GibThis() --Ded
	else
		self.Vel = Vector(self.Vel.X, self.Vel.Y - self.Vel.Y + self.FallSpeed)
	end

	local startPos = self.Pos
	local trace = self.Length
	local mat = nil
	local terraCheck = SceneMan:GetTerrMatter(startPos.X, startPos.Y + trace)
	if terraCheck ~= 0 then
		mat = SceneMan:GetMaterialFromID(terraCheck)
	else
		--Debug
		--PrimitiveMan:DrawLinePrimitive(startPos, startPos + trace, 254)
	end
	if mat ~= nil then
		--Before it lands
		self:OpenHatch()
	end
end
function OnCollideWithTerrain(self, terrainID)
	self.TerrainFound = terrainID --Indicator that we landed
end
function Destroy(self)
	ActivityMan:GetActivity():ReportDeath(self.Team, -1)
end