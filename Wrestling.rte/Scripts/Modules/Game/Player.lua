--This is the greatest player of all time
local player = {}
player.func = {} --All the functions will be stored here, to then be passed onto the actor

function player:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function player:Initialize(activity, actor)
	--[[
		For every function from the player table gets passed to the actor,
		the actor becomes the new player table for ALL the functions below, therefore self.actor isn't needed, self will equal the actor!
		So now doing print(self) will print the actor, but if you print from the loadmodule, it will print the player table instead
	]]
	for k, v in pairs(self.func) do
		if type(v) == "function" then
			if string.find(k, "Initialize") then
				--Create a new Initialize function for the actor
				actor.Initialize = function()
					actor:SetupData() --!Careful running this again!
				end
				--Pass the activity to the actor [MUAHAHAHAHAHA]
				actor.Activity = activity
			else
				--print(tostring(k) .. " " .. tostring(v))
				actor[k] = v
			end
		end
	end
	return actor
end

--[[---------------------------------------------------------
	Name: SetupData()
	Desc: Creates Get / Set functions aswell as variables if included
	See AccessorFunc for more information
------------------------------------------------------------]]
function player:SetupData()
	if not self.Activity.GameSetup then
		--Initial Creation
		self:SetNumberValue("GameSetup", 1)
	end

	--util.AccessorFunc(self, "Score", "Score")
	--util.AccessorFunc(self, "DeathText", "DeathText")

	--Clone is 100% a better method so limbs don't look weird
	self.StoredFGArm = self.FGArm:Clone(); self.StoredFGArmOffset = self.FGArm.ParentOffset
	self.StoredBGArm = self.BGArm:Clone(); self.StoredBGArmOffset = self.BGArm.ParentOffset
	self.StoredFGLeg = self.FGLeg:Clone(); self.StoredFGLegOffset = self.FGLeg.ParentOffset
	self.StoredBGLeg = self.BGLeg:Clone(); self.StoredBGLegOffset = self.BGLeg.ParentOffset

	--Consistant Creation
	self:RemoveMisc()
	if self.Activity.GameSettings.RegenHP then
		self.RegenTimer = Timer()
		self.RegenTime = 2000 --Every 2 seconds heal the actor
		self.RegenTimer:SetSimTimeLimitMS(self.RegenTime)
	end
	self:GetController().InputMode = Controller.CIM_DISABLED
	--self:SetDeathText("")
end

function player:RemoveMisc()
	for pie_slice in self.PieMenu.PieSlices do
		self.PieMenu:RemovePieSlice(pie_slice)
	end

	for att in self.Attachables do
		if string.find(tostring(att), "AEJetpack") then
			att.ToDelete = true
		end
	end
end

--[[---------------------------------------------------------
	Name: Update()
	Desc: Updates everything player related
------------------------------------------------------------]]
function player:Update()
	for _, item in pairs(self.Activity.ItemList) do
		if item.InEffect then
			if self.Activity[item.Effect .. "- Timer"] then
				if self:NumberValueExists(item.Effect) then
					if self.Activity[item.Effect .. "- Timer"]:IsPastSimTimeLimit() then
						item.OnReset(self)
						self:RemoveNumberValue(item.Effect)
						item.InEffect = false
						self.Activity[item.Effect .. "- Timer"] = nil
					end
				end
			else
				if self:NumberValueExists(item.Effect) then
					item.OnReset(self)
					self:RemoveNumberValue(item.Effect)
					item.InEffect = false
				end
			end
		end
	end

	if self.OriginalPlayer then
		self.Activity:SetActorSelectCursor(self.Pos, self.OriginalPlayer)
		self.Activity:SetObservationTarget(self.Pos, self.OriginalPlayer)
	end

	self:RegenHP()
end

function player:RegenHP()
	if not self.Activity.GameSettings.RegenHP then return end
	if self.RegenTimer:IsPastSimTimeLimit() then
		if self.WoundCount > 0 then
			self:RemoveWounds(1, true, false, false)
		elseif self.Health < self.MaxHealth then
			self.Health = math.min(self.Health + 1, self.MaxHealth)
		end
		self.RegenTimer:Reset()
	end
end
--[[---------------------------------------------------------
	Name: OnSpawn( script )
	Desc: What happens when the player spawns
------------------------------------------------------------]]
function player:OnSpawn()
	if self.Activity.GamemodeType == "FFA" then
		self.IgnoresTeamHits = false
		self.HitsMOs = true
		self.GetsHitByMOs = true
	end
	MovableMan:AddActor(self)
end

function player:UpdateSetup()
	self.RegenTimer:Reset()
end

function player:ResetTimers()
	self.RegenTimer:Reset()
end

--[[
function player:AddScore(num)
	self:SetScore(self:GetScore() + num)
end
]]

for k, v in pairs(player) do player.func[k] = v end
return player:Create()