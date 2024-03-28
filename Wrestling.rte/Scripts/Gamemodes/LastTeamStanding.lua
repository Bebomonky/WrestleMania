function WrestleMania:StartGamemode()
	print("LAST TEAM STANDING GAMEMODE START")
	self.TeamLives = {}

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)
			self.TeamLives[team] = {}
			self.TeamLives[team][player] = self.GameSettings.PlayerLives
			--print("PLAYER: " .. player + 1 .. " HAS THIS MANY LIVES: " .. self.TeamLives[team][player])
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
	local maxLivesTeam = nil
	local maxLives = nil
	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)
			local teamLives = self:GetLives(player)
			print(teamLives)
			if (not maxLives or maxLives < teamLives) then
				self.IsDraw = false
				maxLives = teamLives
				maxLivesTeam = team
			elseif (maxLives == teamLives) then
				self.IsDraw = true
			end
		end
	end

	if self.IsDraw then
		return -1
	end
	return maxLivesTeam

	--[[
	local minDeaths = nil
	local minDeathsPlayer = nil

	for player = Activity.PLAYER_1, Activity.MAXPLAYERCOUNT - 1 do
		if self:PlayerActive(player) and self:PlayerHuman(player) then
			local team = self:GetTeamOfPlayer(player)
			local teamLives = self.TeamLives[team][player]
			if (teamLives == maxLivesPlayer) then
				local deaths = self:GetDeathCount(player)
				if (not minDeaths or deaths < minDeaths) then
					draw = false
					minDeaths = deaths
					minDeathsPlayer = team
				elseif (minDeaths == deaths) then
					draw = true
				end
			end
		end
	end

	if draw then
		return minDeathsPlayer
	end
	]]
end

function WrestleMania:GetLives(player)
	return self.TeamLives[self:GetTeamOfPlayer(player)][player]
end

function WrestleMania:AddLives(player, num)
	self.TeamLives[self:GetTeamOfPlayer(player)][player] = self.TeamLives[self:GetTeamOfPlayer(player)][player] + 1
end

function WrestleMania:RemoveLives(player, num)
	self.TeamLives[self:GetTeamOfPlayer(player)][player] = self.TeamLives[self:GetTeamOfPlayer(player)][player] - 1
end

function WrestleMania:CheckWinConditions()
	--[[
	local teamCounter = {}
	for playerTeam, playerLives in pairs(self.TeamLives) do
		local activeTeam = false --Always false until we run out of Lives
		for player, lives in pairs(playerLives) do
			if lives > -1 then
				activeTeam = true
				break
			end
		end
		if activeTeam then
			table.insert(teamCounter, playerTeam)
		end
	end
	if #teamCounter == 1 then
		self:CoreVictory(teamCounter[1])
	elseif #teamCounter == 0 then
		ExtensionMan.print_debug("NO WINNERS")
		self.WinnerTeam = -1
		if (self.CurrentLevel and self.CurrentLevel.Draw) then
			self.CurrentLevel:Draw(self)
		end
		self.SFXTracks[10]:Play(self.CenterScene)
		ActivityMan:EndActivity()
	end
	]]

	local teamCounter = {}
	for playerTeam, playerLives in pairs(self.TeamLives) do
		local activeTeam = false
		for player, lives in pairs(playerLives) do
			if lives > -1 then
				activeTeam = true
				break
			end
		end
		if activeTeam then
			table.insert(teamCounter, playerTeam)
		end
	end
	if #teamCounter == 1 then
		self:CoreVictory(teamCounter[1])
	elseif #teamCounter == 0 then
		self:CoreVictory(-1)
	end
end