local misc = {}

function misc:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function misc:Initialize(activity)
	self.Act = activity
end

function misc:Load_Misc()
	--If you don't have these resolutions then oh well ¯\_(ツ)_/¯
	--I can't bother with resolutions
	self.Splitscreen_Resolution =
	{
		["Player_HUD_2P"] = {
		[288] = Vector(219, 40),
		[360] = Vector(345, 40),
		},
		["Center_HUD_2P"] = {
		[288] = Vector(680, 15),
		[360] = Vector(930, 15),
		},

		["Player_HUD_2P+"] = {
		[288] = Vector(25, 40),
		[360] = Vector(25, 40),
		},

		["Center_HUD_2P+"] = {
		[288] = Vector(219, 15),
		[360] = Vector(295, 15),
		}
	}

	self.Multiplayer_Resolution = {
		[540] = {Profile = Vector(185, 70), Middle = Vector(615, 40)},
		[576] = {Profile = Vector(218, 89), Middle = Vector(680, 60)},
		[720] = {Profile = Vector(345, 160), Middle = Vector(930, 135)}
	}

	self.SoundList =
	{--DO NOT CHANGE THE ORDER
		"WM Countdown 1", -- 1
		"WM Countdown 2", -- 2
		"WM Countdown 3", -- 3
		"WM Countdown Go", -- 4
		"WM Heavy Cheering", -- 5
		"WM Medium Cheering", -- 6
		"WM Light Cheering", -- 7
		"WM Boxing Bell", -- 8
		"WM Gasp", -- 9
		"WM Draw Boo", -- 10
		"WM Victory", -- 11
	}
end

return misc:Create()