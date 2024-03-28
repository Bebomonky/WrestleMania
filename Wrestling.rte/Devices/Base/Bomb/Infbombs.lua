function Update(self)
	if self:HasObject("Bomberman Bomb") == false and self.Health > 0 then
		self:AddInventoryItem(CreateTDExplosive("Bomberman Bomb"));
	end
end