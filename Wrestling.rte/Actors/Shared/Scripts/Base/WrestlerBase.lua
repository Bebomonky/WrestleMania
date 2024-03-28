function Create(self)
	--! M O D I F I E R S
	--Maximum head smash force.
	self.MaxHeadForce = 35 -- Default 50

	--How quickly to charge the jump.
	self.JumpChargeSpeed = 0.3 -- Default 0.3

	--Maximum stamina.
	self.MaxStamina = 100 -- Default 100

	--The actor's stamina (%).
	self.Stamina = self.MaxStamina

	--How quickly to recharge stamina.
	self.StaminaRechargeRate = 0.7 -- Default 0.2

	--How much to jump relative to horizontal force.  Ex: 5 would mean 1/5th of the horizontal force.
	self.SlamJumpRatio = 3 -- Default 3

	--How quickly to charge the body slam.
	self.TackleChargeSpeed = 0.3 -- Default 0.3

	--How much to go forward relative to verical force.  Ex: 5 would mean 1/5th of the vertical force.
	self.JumpForwardRatio = 4 -- Default 4

	--Maximum amount of stamina used by head smashing.
	self.HeadStaminaEffect = 50 -- Default 50

	--Maximum amount of stamina used by tackling/body slamming.
	self.TackleStaminaEffect = 50 -- Default 50

	--Maximum amount of stamina used by jumping.
	self.JumpStaminaEffect = 25 -- Default 25
	--! M O D I F I E R S

	--! S M A S H
	--How long to smash for before resetting.
	self.SmashTime = 500 -- Default 500

	--Timer for the aforementioned.
	self.SmashTimer = Timer()
	--! S M A S H

	--! S P E C I A L
	--How much special power is stored up.
	self.Special = 0 -- Default 0

	--The maximum amount of special power.
	self.MaxSpecial = 100 -- Default 100

	--Speed with which to charge special power.
	self.SpecialChargeSpeed = 0.9 -- Default 0.2

	--How much stamina to consume relative to charge speed.
	self.SpecialStaminaConsumption = 0.4 -- Default 0.4

	--Maximum distance to grab an enemy at.
	self.GrabDist = 25 -- Default 25

	--The grabbed enemy.
	self.GrabEnemy = nil

	--How far away to hold the enemy.
	self.HoldDist = 5 -- Default 5

	--How far from the ground to stop the smash.
	self.GroundHeight = 30 -- Default 30

	--Power of the grab jump.
	self.GrabJumpPower = 15 -- Default 15

	--How much to move horizontally while piledriving.
	self.GrabHorizMovement = 1 -- Default 1

	--Time between spinning while using special power.
	self.SpinTime = 100 -- Default 100

	--Timer for the aforementioned.
	self.SpinTimer = Timer()
	--! S P E C I A L


	--! M I S C

	--Current head smash force.
	self.HeadForce = 0

	--How far back the head should snap.
	self.HeadMaxBack = math.pi / 5

	--How quickly to charge the head smash force.
	self.HeadChargeSpeed = 0.8 -- Default 0.8

	--Max angle before head smash stops (radians).
	self.HeadSmashStopAngle = math.pi / 1.8

	--If we're head smashing or not.
	self.HeadSmashing = false

	--If the actor was flipped last frame.
	self.WasFlipped = false

	--Max tackle force.
	self.MaxTackleForce = 14 -- Default 14

	--Current tackle force.
	self.TackleForce = 0

	--Current jump force.
	self.JumpForce = 0

	--Max jump force.
	self:SetNumberValue("MaxJumpForce", 15) -- Default 15
	self.MaxJumpForce = 15
	--! M I S C

	self:SetNumberValue("SpecialFull", 0)

	--Originally self.AboveHUDPos
	self.DrawPos = Vector(self.Head.Pos.X, self.Head.Pos.Y) - Vector(5, 15)

	self.GibImpulseLimit = self.GibImpulseLimit * 1.5
	self.GibWoundLimit = self.GibWoundLimit * 1.5

	self.StaminaHUD = {
		Symbol = CreateMOSRotating("Wrestling.rte/Stamina Symbol"),
		Bar = CreateMOSRotating("Wrestling.rte/Stamina Bar"),
		Glow = CreateMOSRotating("Wrestling.rte/Stamina Full Glow")
	}

	self.SpecialHUD = {
		Symbol = CreateMOSRotating("Wrestling.rte/Special Symbol"),
		Bar = CreateMOSRotating("Wrestling.rte/Special Bar"),
		Glow = CreateMOSRotating("Wrestling.rte/Special Full Glow")
	}

	self.HeadSmashHUD = {
		Symbol = CreateMOSRotating("Wrestling.rte/Head Smash Symbol"),
		Bar = CreateMOSRotating("Wrestling.rte/Head Smash Bar"),
		Glow = CreateMOSRotating("Wrestling.rte/Head Smash Full Glow")
	}

	self.TackleHUD = {
		Symbol = CreateMOSRotating("Wrestling.rte/Tackle Symbol"),
		Bar = CreateMOSRotating("Wrestling.rte/Tackle Bar"),
		Glow = CreateMOSRotating("Wrestling.rte/Tackle Full Glow")
	}

	self.JumpHUD = {
		Symbol = CreateMOSRotating("Wrestling.rte/Jump Symbol"),
		Bar = CreateMOSRotating("Wrestling.rte/Jump Bar"),
		Glow = CreateMOSRotating("Wrestling.rte/Jump Full Glow")
	}
end

function Update(self)
	self.MaxJumpForce = self:GetNumberValue("MaxJumpForce") --Leave me alone!!!!!!

	--Originally self.AboveHUDPos
	--Apperently it says head is nil? we check if it exists for incase
	if self.Head and SceneMan:ShortestDistance(self.DrawPos, Vector(self.Head.Pos.X, self.Head.Pos.Y) - Vector(5, 15), false):MagnitudeIsGreaterThan(2) then
		self.DrawPos = Vector(self.Head.Pos.X, self.Head.Pos.Y) - Vector(5, 15)
	end

	--[[
	if self:NumberValueExists("GameReady") then PrimitiveMan:DrawTextPrimitive(self.AboveHUDPos - Vector(10, -2), "READY!", true, 0)
		return
	end
	]]

	--? Once this is removed, everything below runs
	if self:NumberValueExists("GameSetup") then return end

	--Get the controller.
	self.Ctrl = self:GetController()
	--Store the player since we will know it's from them
	if not self.ActualPlayer then
		self.ActualPlayer = self.Ctrl.Player
	end

	local screen = ActivityMan:GetActivity():ScreenOfPlayer(self.ActualPlayer)

	--? I think this can be obnoxious
	--PrimitiveMan:DrawTextPrimitive(screen, self.DrawPos + Vector(-5, 10), "You", true, 0)

	--Is the player charging anything?
	local isCharging = false

	--If the player is holding jump...
	if self.Ctrl:IsState(Controller.BODY_JUMP) then
		--Charge the jump.
		if self.JumpForce < self.MaxJumpForce * (self.Stamina / self.MaxStamina) then
			self.JumpForce = self.JumpForce + self.JumpChargeSpeed
		end

		--Mark that it's charging.
		isCharging = true
	else
		--Release the jump!

		self.Vel.Y = self.Vel.Y - self.JumpForce

		--Use up stamina.
		self.Stamina = self.Stamina - (self.JumpForce / self.MaxJumpForce) * self.JumpStaminaEffect

		--Also move a bit horizontally.
		if self.HFlipped then
			self.Vel.X = self.Vel.X - self.JumpForce / self.JumpForwardRatio
		else
			self.Vel.X = self.Vel.X + self.JumpForce / self.JumpForwardRatio
		end

		--Reset the jump force.
		self.JumpForce = 0
	end

	--If the player is holding fire...
	if not self.EquippedItem then
		if self.Ctrl:IsState(Controller.WEAPON_FIRE) then
			if self.Ctrl:IsState(Controller.BODY_JUMP) then
				--If jump is also being held, charge body slam.
				if self.TackleForce < self.MaxTackleForce * (self.Stamina / self.MaxStamina) then
					self.TackleForce = self.TackleForce + self.TackleChargeSpeed
					--Mark that it's charging.
					isCharging = true
				end

				--Reset the jump charge so it doesn't combine with this.
				self.JumpForce = 0
			else
				--If charging hasn't started yet, snap to position.
				if self.HeadForce == 0 then
					self.RotAngle = 0
				end

				--Charge head smash.
				if self.HeadForce < self.MaxHeadForce * (self.Stamina / self.MaxStamina) then
					self.HeadForce = self.HeadForce + self.HeadChargeSpeed
				end

				--Mark that it's charging.
				isCharging = true

				--If the actor has flipped, adjust rotation accordingly.
				if self.WasFlipped ~= self.HFlipped then
					self.RotAngle = -self.RotAngle
				end

				--Bend back in the right direction.
				if self.HFlipped then
					if self.RotAngle > -self.HeadMaxBack * (self.HeadForce / self.MaxHeadForce) then
						self.AngularVel = (self.RotAngle - self.HeadMaxBack) * (self.HeadForce / self.MaxHeadForce)
					else
						self.RotAngle = -self.HeadMaxBack * (self.HeadForce / self.MaxHeadForce)
					end
				else
					if self.RotAngle < self.HeadMaxBack * (self.HeadForce / self.MaxHeadForce) then
						self.AngularVel = (self.RotAngle + self.HeadMaxBack) * (self.HeadForce / self.MaxHeadForce)
					else
						self.RotAngle = self.HeadMaxBack * (self.HeadForce / self.MaxHeadForce)
					end
				end
			end
		elseif self.TackleForce ~= 0 then
			if self.HFlipped then
				self.Vel.X = self.Vel.X - self.TackleForce -
					((self.HeadForce / self.MaxHeadForce) * self.MaxTackleForce)
			else
				self.Vel.X = self.Vel.X + self.TackleForce +
					((self.HeadForce / self.MaxHeadForce) * self.MaxTackleForce)
			end

			--Use up stamina.
			self.Stamina = self.Stamina - (self.TackleForce / self.MaxTackleForce) * self.TackleStaminaEffect

			--Jump a bit as well.
			self.Vel.Y = self.Vel.Y - self.TackleForce / self.SlamJumpRatio

			--Reset the body slam force.
			self.TackleForce = 0
		elseif self.HeadForce ~= 0 then
			--Release the smash!
			if self.HFlipped then
				self.AngularVel = self.HeadForce
			else
				self.AngularVel = -self.HeadForce
			end

			--Use up stamina.
			self.Stamina = self.Stamina - (self.HeadForce / self.MaxHeadForce) * self.HeadStaminaEffect

			--Reset the charge.
			self.HeadForce = 0

			--(Re)start the smash timer.
			self.SmashTimer:Reset()

			--Note that the head smash is being performed.
			self.HeadSmashing = true

			--Put head into smashing position.
			if self.HFlipped then
				self:SetAimAngle(math.pi)
			else
				self:SetAimAngle(-math.pi)
			end
		end
	end

	--If the player is holding crouch and isn't moving or charging anything and is on the ground...
	local isMoving = false

	if self.Ctrl:IsState(Controller.MOVE_LEFT) or self.Ctrl:IsState(Controller.MOVE_RIGHT) then
		isMoving = true
	end

	if self.Ctrl:IsState(Controller.BODY_CROUCH) and isMoving == false and isCharging == false and self:GetAltitude(0, 0) < 20 then
		--If special is not at max...
		if self.Special < self.MaxSpecial then
			--If there is stamina to use...
			if self.Stamina > 0 then
				--Charge special power and consume stamina.
				self.Special = self.Special + self.SpecialChargeSpeed
				self.Stamina = self.Stamina - self.SpecialStaminaConsumption
			end

			--Mark that it's charging.
			isCharging = true
		end
	end

	--If the player is pressing the pie menu button...
	if self.Ctrl:IsState(Controller.PIE_MENU_ACTIVE) then
		--If the special bar is full...
		if self.Special >= self.MaxSpecial then
			local actor = MovableMan:GetClosestActor(self.Pos, 25, Vector(), self)
			if actor and IsActor(actor) then
				self.GrabEnemy = ToActor(actor)

				--Don't let any collision with the enemy.
				self:SetWhichMOToNotHit(self.GrabEnemy, -1)

				--Do the same for the enemy.
				self.GrabEnemy:SetWhichMOToNotHit(self, -1)

				--Jump into the air.
				self.Vel.Y = -self.GrabJumpPower

				--Move a bit horizontally.
				if self.HFlipped then
					self.Vel.X = self.Vel.X - self.GrabHorizMovement
				else
					self.Vel.X = self.Vel.X + self.GrabHorizMovement
				end
			end
			--Reset the special bar.
			self.Special = 0

			--Flash white.
			self:FlashWhite(500)
		end
	end

	--If a head smash is being performed...
	if self.HeadSmashing then
		--If the head has gone too far, stop.
		if (self.HFlipped and self.RotAngle > self.HeadSmashStopAngle) or (not self.HFlipped and self.RotAngle < -self.HeadSmashStopAngle) then
			self.AngularVel = 0
			self.HeadSmashing = false
		end

		--If the smash has gone on long enough, reset.
		if self.SmashTimer:IsPastSimMS(self.SmashTime) then
			self.HeadSmashing = false
		end
	else
		--Move the head into the right place.
		if self.HFlipped then
			self:SetAimAngle(-self.RotAngle)
		else
			self:SetAimAngle(self.RotAngle)
		end
	end

	--If an enemy has been grabbed...
	if self.GrabEnemy ~= nil and MovableMan:IsActor(self.GrabEnemy) then
		--Move the enemy into place.
		self.GrabEnemy.Vel = Vector(0, 0)
		if self.HFlipped then
			self.GrabEnemy.Pos = self.Pos - Vector(self.HoldDist, 0)
			self.GrabEnemy.RotAngle = math.atan2(self.Vel.X, self.Vel.Y) + math.pi
		else
			self.GrabEnemy.Pos = self.Pos + Vector(self.HoldDist, 0)
			self.GrabEnemy.RotAngle = math.atan2(self.Vel.X, self.Vel.Y) + math.pi
		end
		self.GrabEnemy.HFlipped = self.HFlipped

		--Don't rotate, this can cause bugs.
		self.AngularVel = 0
		self.GrabEnemy.AngularVel = 0

		--If we're moving downward...
		if self.Vel.Y > 0 then
			--Spin.
			if self.SpinTimer:IsPastSimMS(self.SpinTime) then
				self.HFlipped = not self.HFlipped
				self.SpinTimer:Reset()
			end
			--If we've hit the ground...
			if self:GetAltitude(0, 0) < self.GroundHeight then
				--Try to find the enemy's legs, and make them stick up in the air.
				for att in self.GrabEnemy.Attachables do
					if att.ClassName == "Leg" then
						att.RotTarget = 0
					end
				end

				--Don't cause fall damage.
				self.Vel = Vector(0, 0)

				if self.GrabEnemy.BodyHitSound then
					self.GrabEnemy.BodyHitSound:Play(self.GrabEnemy.Pos);
				end

				--Kill the enemy.
				self.GrabEnemy.Health = -100

				--Stick the enemy in the ground.
				self.GrabEnemy.Pos = SceneMan:MovePointToGround(self.GrabEnemy.Pos, 0, 0) - Vector(0, 5)

				--Turn the enemy to terrain.
				self.GrabEnemy.ToSettle = true

				--Turn off the throw.
				self.GrabEnemy = nil
			end
		end
	end

	--Gradually increase stamina.
	if self.Stamina < self.MaxStamina and isCharging == false then
		self.Stamina = self.Stamina + self.StaminaRechargeRate
	end

	UpdateHUD(self, screen)

	--Update whether the actor was flipped or not.
	self.WasFlipped = self.HFlipped
end

function UpdateHUD(self, screen)
	--Draw the various bars and symbol.
	local totalBars = 1
	local barHeight = 0

	local function Element(symbol, symbolPos, bar, barPos, abilityFull, glow, glowPos, ability, maxAbility)
		if ability ~= 0 then
			local newFrame = math.ceil((ability / maxAbility) * 10)
			PrimitiveMan:DrawBitmapPrimitive(screen, symbolPos, symbol, 0, 0)
			PrimitiveMan:DrawBitmapPrimitive(screen, barPos, bar, 0, newFrame, false, false)
			if abilityFull then
				PrimitiveMan:DrawBitmapPrimitive(screen, glowPos, glow, 0, 0)
			end
			totalBars = totalBars + 1
		end
	end

	PrimitiveMan:DrawBitmapPrimitive(screen, self.DrawPos + Vector(-7, barHeight), self.StaminaHUD.Symbol, 0, 0)
	PrimitiveMan:DrawBitmapPrimitive(screen, self.DrawPos + Vector(8, barHeight), self.StaminaHUD.Bar, 0, math.ceil((self.Stamina / self.MaxStamina) * 10), false, false)
	if self.Stamina >= self.MaxStamina then
		PrimitiveMan:DrawBitmapPrimitive(screen, self.DrawPos + Vector(8, barHeight), self.StaminaHUD.Glow, 0, 0)
	end

	Element(self.SpecialHUD.Symbol, self.DrawPos + Vector(-7, barHeight - 13 * totalBars),
	self.SpecialHUD.Bar, self.DrawPos + Vector(8, barHeight - 13 * totalBars),

	self.Special >= self.MaxSpecial,
	self.SpecialHUD.Glow, self.DrawPos + Vector(8, barHeight - 13 * totalBars),
	self.Special, self.MaxSpecial
	)

	Element(self.HeadSmashHUD.Symbol, self.DrawPos + Vector(-7, barHeight - 13 * totalBars),
	self.HeadSmashHUD.Bar, self.DrawPos + Vector(8, barHeight - 13 * totalBars),

	self.HeadForce >= self.MaxHeadForce * (self.Stamina / self.MaxStamina),
	self.HeadSmashHUD.Glow, self.DrawPos + Vector(8, barHeight - 13 * totalBars),
	self.HeadForce, self.MaxHeadForce
	)

	Element(self.TackleHUD.Symbol, self.DrawPos + Vector(-7, barHeight - 13 * totalBars),
	self.TackleHUD.Bar, self.DrawPos + Vector(8, barHeight - 13 * totalBars),

	self.TackleForce >= self.MaxTackleForce * (self.Stamina / self.MaxStamina),
	self.TackleHUD.Glow, self.DrawPos + Vector(8, barHeight - 13 * totalBars),
	self.TackleForce, self.MaxTackleForce
	)

	Element(self.JumpHUD.Symbol, self.DrawPos + Vector(-7, barHeight - 13 * totalBars),
	self.JumpHUD.Bar, self.DrawPos + Vector(8, barHeight - 13 * totalBars),

	self.JumpForce >= self.MaxJumpForce * (self.Stamina / self.MaxStamina),
	self.JumpHUD.Glow, self.DrawPos + Vector(8, barHeight - 13 * totalBars),
	self.JumpForce, self.MaxJumpForce
	)
end

--[[
function GetEnemy(self)
	local startPos = self.EyePos + Vector(0 * self.Head.FlipFactor, -3):RadRotate(self.Head.RotAngle)
	local hitPos = Vector()
	local skipPx = 10
	local trace = Vector(500 + math.sqrt(FrameMan.PlayerScreenWidth^2 + FrameMan.PlayerScreenHeight^2) * 0.5 * self.Head.FlipFactor, 0):RadRotate(self.Head.RotAngle)
	local obstRay = SceneMan:CastObstacleRay(startPos, trace, hitPos, Vector(), self.ID, self.Team, rte.airID, skipPx)
	local enemy
	if obstRay >= 0 then
		obstRay = obstRay - skipPx + SceneMan:CastObstacleRay(hitPos - trace:SetMagnitude(skipPx), trace, hitPos, Vector(), self.ID, self.Team, rte.airID, 1)
		local endPos = startPos + trace:SetMagnitude(obstRay)
		local moCheck = SceneMan:GetMOIDPixel(hitPos.X, hitPos.Y)
		if moCheck ~= rte.NoMOID then
			local mo = ToMOSRotating(MovableMan:GetMOFromID(MovableMan:GetMOFromID(moCheck).RootID))
			if mo and mo.ClassName ~= "ADoor" and mo.Team ~= self.Team then
				enemy = IsACrab(mo) and ToACrab(mo) or mo
				PrimitiveMan:DrawLinePrimitive(screen, startPos, endPos, 13)
			end
		end
	end

	return enemy
end
]]