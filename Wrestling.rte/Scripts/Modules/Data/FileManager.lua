-----------------------------------------------------------------------------------------
-- Save/Load Manager
-----------------------------------------------------------------------------------------

-- Thank you MyNameIsTrez / StackOverflow!

--[[
Example usage:
s = serializeTable({a = "foo", b = {c = 123, d = "foo"}})
print(s)
a = loadstring(s)()
]]
--

--[[
Returns the entire file as a string.
]]
--
local fileManager = {}

function fileManager:Create()
	local members = {}
	setmetatable(members, self)
	self.__index = self

	return members
end

function fileManager:SerializeTable(val, name, skipnewlines, depth)
	skipnewlines = skipnewlines or false
	depth = depth or 0

	local tmp = string.rep(" ", depth)

	if name then
		if type(name) == "number" then
			tmp = tmp .. "[" .. name .. "]" .. " = "
		else
			tmp = tmp .. name .. " = "
		end
	end

	if type(val) == "table" then
		tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

		for k, v in pairs(val) do
			tmp = tmp
				.. self:SerializeTable(v, k, skipnewlines, depth + 1)
				.. ","
				.. (not skipnewlines and "\n" or "")
		end

		tmp = tmp .. string.rep(" ", depth) .. "}"
	elseif type(val) == "number" then
		tmp = tmp .. tostring(val)
	elseif type(val) == "string" then
		tmp = tmp .. string.format("%q", val)
	elseif type(val) == "boolean" then
		tmp = tmp .. (val and "true" or "false")
	else
		tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
	end

	return tmp
end

--Custom Save / Load System
function fileManager:ReadOrWriteTable(path, tab)
	if LuaMan:FileExists(path) then
		ExtensionMan.print_notice("Reading", "File: " .. path:match("[^/]+$"))
		tab = self:ReadFileAsTable("Mods/" .. path)
		ExtensionMan.print_done("File: " .. path:match("[^/]+$"))
	else
		self:WriteTableToFile("Mods/" .. path, tab)
		ExtensionMan.print_done("File: " .. path)
	end
	return tab
end

function fileManager:ReadFile(path)
	local fileID = LuaMan:FileOpen(path, "r")
	local strTab = {}
	local i = 1
	while not LuaMan:FileEOF(fileID) do
		strTab[i] = LuaMan:FileReadLine(fileID)
		i = i + 1
	end
	LuaMan:FileClose(fileID)
	return table.concat(strTab)
end

function fileManager:ReadFileAsTable(file)
	local fileStr = self:ReadFile(file)
	if fileStr == "" or fileStr == nil then
		fileStr = "{}"
	end
	return loadstring("return " .. fileStr)()
end

function fileManager:WriteToFile(path, str)
	local fileID = LuaMan:FileOpen(path, "w")
	LuaMan:FileWriteLine(fileID, str)
	LuaMan:FileClose(fileID)
	ExtensionMan.print_notice("Writing", "File: " .. path)
end

function fileManager:WriteTableToFile(path, tab)
	local tabStr = self:SerializeTable(tab)
	self:WriteToFile(path, tabStr)
end

return fileManager:Create()