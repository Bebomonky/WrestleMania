function WrestleMania:OnGlobalMessage(message, object) self:HandleMessage(message, object) end
function WrestleMania:OnMessage(message, object) self:HandleMessage(message, object) end

function WrestleMania:HandleMessage(message, object)
	if message == "WrestleMania_ItemData" then --table
		for i, item in pairs(self.ItemList) do
			if object.Name == item.Name then
				if (item.ApplyToActor) then
					if object.Effect then
						if not item.InEffect then --! Prevent stacking
							self.GameChar[object.Player]:SetNumberValue(object.Effect, i)
							item.ApplyToActor(self.GameChar[object.Player])
							item.InEffect = true
						end
					else
						item.ApplyToActor(self.GameChar[object.Player])
					end
				end
				if (item.OnReset) then
					--! Don't let the same effect happen twice
					if object.EffectLength then
						if not self[item.Effect .. "- Timer"] then
							self[item.Effect .. "- Timer"] = Timer()
							self[item.Effect .. "- Timer"]:SetSimTimeLimitMS(object.EffectLength)
						end
					else
						item.OnReset(self.GameChar[object.Player])
					end
				end
			end
		end
	end
end