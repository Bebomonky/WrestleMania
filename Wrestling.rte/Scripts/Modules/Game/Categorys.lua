local category = {}

function category:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function category:Initialize(activity)
	self.Act = activity
end

function category:Load_DLC_Categorys(menu)

end

return category:Create()

--[[
	!TEMPLATES
	Maps
	6 Maps MAX per Category (Any more than that will not be added)
	menu:NewLevelCategory(
	self.Act:AddLevel("Stadium", "The Stadium", "Stadium Preview", "Wrestling.rte/Scenes/Maps/Stadium/Music/Speed_It_Up.ogg", "Stadium/Stadium.lua") --Last one cannot have a comma ","
	)
	Characters
	23 Wrestlers MAX per Category

	menu:NewCharacterCategory(
	"Base.rte/Culled Clone", "Base.rte/Fat Culled Clone" --Last one cannot have a comma ","
	)

	Don't have the same effects!, reskin? NUH UH change the png you weirdo
		!	TUTORIAL
		* 	ID = value (num) [It is best to have each item have a uniqueID so that it doesn't break!]
		*	device = CreateHDFirearm / CreateTDExplosive / CreateHeldDevice (CreateHeldDevice IS NOT CURRENTLY SUPPORTED!)
		*	path = PresetName
		*	icon = MOSRotating
		*	effect = EffectName (StringValue)
		*	local myItem = self.Act:AddItem(ID, device, path, icon, effect)

		!	(OPTIONAL FUNCTIONS)
			self is the actor!

			What to do when item is in use (ONCE)
			function myItem:ApplyToActor()
				self.Health = self.Health + 200
			end

			OnReset only runs on a timer using EffectLength (you can add it from items ini)
			When the length of the effect is over, OnReset runs (ONCE)
			function myItem:OnReset()
				self.Health = self.Health - 200 --This will kill you lol
			end

		Once you setup your item
		Make sure to add it to a new category!
		23 Items MAX per Category
		menu:NewItemCategory(
			myItem --Last one cannot have a comma ","
		)

		!To TOP it all off it should look like this if you get stuck!
		!↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
		local myItem = self.Act:AddItem("POH1", CreateHDFirearm, "Potion of Healing", "Wrestling.rte/Health Icon", "Wrestle Mania - Regenerate Arms")
		function myItem:ApplyToActor()
			self.Health = self.Health + 200
		end

		menu:NewItemCategory(
			myItem --Last one cannot have a comma ","
		)

	!↓↓↓↓ ADD YOUR CATEGORYS BELOW THIS ↓↓↓↓
	]]

	--[[
	local myItem = self.Act:AddItem("POH1", CreateHDFirearm, "Potion of Healing", "Wrestling.rte/Health Icon", "Wrestle Mania - Regenerate Arms")
	function myItem:ApplyToActor()
		self.Health = self.Health + 200
	end

	local myItem2 = self.Act:AddItem("POH2", CreateHDFirearm, "Potion of Healing", "Wrestling.rte/Health Icon", "Wrestle Mania - Regenerate Arms")
	function myItem2:ApplyToActor()
		self.Health = self.Health + 200
	end

	menu:NewItemCategory(
		myItem2 --Last one cannot have a comma ","
	)
]]