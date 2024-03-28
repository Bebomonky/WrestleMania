function Create(self)
	self.KeyMovementSpeed = 5

	--Where the cursor is.
	self.CursorPos = self.Pos
	self.Wrapped = false

	self.Keylr = 0
	self.Keyud = 0
end
function Update(self)
	local screen = ActivityMan:GetActivity():ScreenOfPlayer(self:GetController().Player)
	if self:IsPlayerControlled() then
		PrimitiveMan:DrawTextPrimitive(screen, self.Pos, "CAM", true, 0)
		self.Keylr = 0
		self.Keyud = 0
		local controller = self:GetController()
		if controller:IsState(Controller.MOVE_LEFT) then
			self.Keylr = -1
		elseif controller:IsState(Controller.MOVE_RIGHT) then
			self.Keylr = 1
		end

		if controller:IsState(Controller.MOVE_UP) then
			self.Keyud = -1
		elseif controller:IsState(Controller.MOVE_DOWN) then
			self.Keyud = 1
		end
	end

	local keyMovement = Vector(
		self.Keylr * self.KeyMovementSpeed,
		self.Keyud * self.KeyMovementSpeed
	)
	local desiredPos = self.CursorPos + keyMovement
	--Wrap around.
	self.Wrapped = false
	if desiredPos.X > SceneMan.SceneWidth then
		if SceneMan.SceneWrapsX then
			desiredPos.X = desiredPos.X % SceneMan.SceneWidth
			self.Wrapped = true
		else
			desiredPos.X = SceneMan.SceneWidth
		end
	end
	if desiredPos.X < 0 then
		if SceneMan.SceneWrapsX then
			desiredPos.X = desiredPos.X + SceneMan.SceneWidth
			self.Wrapped = true
		else
			desiredPos.X = 0
		end
	end
	if desiredPos.Y > SceneMan.SceneHeight then
		if SceneMan.SceneWrapsY then
			desiredPos.Y = desiredPos.Y % SceneMan.SceneHeight
			self.Wrapped = true
		else
			desiredPos.Y = SceneMan.SceneHeight
		end
	end
	if desiredPos.Y < 0 then
		if SceneMan.SceneWrapsY then
			desiredPos.Y = desiredPos.Y + SceneMan.SceneHeight
			self.Wrapped = true
		else
			desiredPos.Y = 0
		end
	end
	if self:NumberValueExists("PlayerIsDead") or self:NumberValueExists("GameEnded") or self:NumberValueExists("ViewerMode") then
		--Set the cursor's position.
		self.CursorPos = desiredPos
		self.Pos = self.CursorPos
	else
		--When you aren't dead we have to reset it
		self.CursorPos = self.Pos
	end
end