
-----------------------------------------------------------------------
-- LibFroznFunctions-1.0
--
-- Frozn's utility functions for WoW development
--
-- Example:
-- /run DevTools_Dump(LibStub:GetLibrary("LibFroznFunctions-1.0", true).isWoWFlavor)
--

-- create new library
local LIB_NAME = "LibFroznFunctions-1.0";
local LIB_MINOR = 1; -- bump on changes

if (not LibStub) then
	error(LIB_NAME .. " requires LibStub.");
end
-- local ldb = LibStub("LibDataBroker-1.1", true)
-- if not ldb then error(LIB_NAME .. " requires LibDataBroker-1.1.") end

local LibFroznFunctions = LibStub:NewLibrary(LIB_NAME, LIB_MINOR)

if (not LibFroznFunctions) then
	return;
end

----------------------------------------------------------------------------------------------------
--                                        Classic Support                                         --
----------------------------------------------------------------------------------------------------

-- WoW flavor
LibFroznFunctions.isWoWFlavor = {
	["ClassicEra"] = false,
	["BCC"] = false,
	["WotLKC"] = false,
	["SL"] = false,
	["DF"] = false
};

if (_G["WOW_PROJECT_ID"] == _G["WOW_PROJECT_CLASSIC"]) then
	LibFroznFunctions.isWoWFlavor.ClassicEra = true;
elseif (_G["WOW_PROJECT_ID"] == _G["WOW_PROJECT_BURNING_CRUSADE_CLASSIC"]) then
	LibFroznFunctions.isWoWFlavor.BCC = true;
elseif (_G["WOW_PROJECT_ID"] == _G["WOW_PROJECT_WRATH_CLASSIC"]) then
	LibFroznFunctions.isWoWFlavor.WotLKC = true;
else -- retail
	if (_G["LE_EXPANSION_LEVEL_CURRENT"] == _G["LE_EXPANSION_SHADOWLANDS"]) then
		LibFroznFunctions.isWoWFlavor.SL = true;
	else
		LibFroznFunctions.isWoWFlavor.DF = true;
	end
end

-- create color from hex string
LibFroznFunctions.CreateColorFromHexString = CreateColorFromHexString;

if (not LibFroznFunctions.CreateColorFromHexString) then
	local function ExtractColorValueFromHex(str, index)
		return tonumber(str:sub(index, index + 1), 16) / 255;
	end
	
	LibFroznFunctions.CreateColorFromHexString = function(hexColor)
		if (#hexColor == 8) then
			local a, r, g, b = ExtractColorValueFromHex(hexColor, 1), ExtractColorValueFromHex(hexColor, 3), ExtractColorValueFromHex(hexColor, 5), ExtractColorValueFromHex(hexColor, 7);
			return CreateColor(r, g, b, a);
		else
			error("CreateColorFromHexString input must be hexadecimal digits in this format: AARRGGBB.");
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                             Colors                                             --
----------------------------------------------------------------------------------------------------

-- class colors
local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;

function LibFroznFunctions.GetClassColor(classFile, alternateClassFileIfNotFound)
	return CLASS_COLORS[classFile] or CLASS_COLORS[alternateClassFileIfNotFound];
end
