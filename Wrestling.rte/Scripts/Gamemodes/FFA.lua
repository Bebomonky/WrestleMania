function WrestleMania:StartGamemode()
	print("FREE FOR ALL GAMEMODE START")
	self.PlayerLives = {}

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			self.PlayerLives[player] = self.GameSettings.PlayerLives
		end
	end
end

function WrestleMania:UpdateGamemode()
	for actor in MovableMan.Actors do
		if actor then
			if actor:IsInGroup("Wrestle Mania - Wrestler") then
				if actor:NumberValueExists("GameSetup") then
					actor:RemoveNumberValue("GameSetup")
				end
			end
		end
	end
end

function WrestleMania:FindHighestScore()
	local maxLivesPlayer = nil
	local maxLives = nil
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local lives = self:GetLives(player)
			if (not maxLives or maxLives < lives) then
				self.IsDraw = false
				maxLives = lives
				maxLivesPlayer = player
			elseif (maxLives == lives) then
				self.IsDraw = true
			end
		end
	end

	if self.IsDraw then
		return -1
	end
	return maxLivesPlayer

	--[[
	--TODO NEW GAMEMODE IDEA, GET THE LEAST DEATHS??
	local draw = false

	local minDeaths = nil
	local minDeathsPlayer = nil

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local deaths = self:GetDeathCount(player)
			if (not minDeaths or deaths < minDeaths) then
				draw = false
				minDeaths = deaths
				minDeathsPlayer = player
			elseif (minDeaths == deaths) then
				draw = true
			end
		end
	end

	if draw then
		return -1
	end
	return minDeathsPlayer
	]]
end

function WrestleMania:GetLives(player)
	return self.PlayerLives[player]
end

function WrestleMania:AddLives(player, num)
	self.PlayerLives[player] = self.PlayerLives[player] + 1
end

function WrestleMania:RemoveLives(player, num)
	self.PlayerLives[player] = self.PlayerLives[player] - 1
end

function WrestleMania:CheckWinConditions()
	local playerCounter = {}

	for player, lives in pairs(self.PlayerLives) do
		local activePlayer = false
		if lives > -1 then
			activePlayer = true
		end
		if activePlayer then
			table.insert(playerCounter, player)
		end
	end
	if #playerCounter == 1 then
		self:CoreVictory(playerCounter[1])
	elseif #playerCounter == 0 then
		self:CoreVictory(-1)
	end
end