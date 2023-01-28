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
local LIB_MINOR = 3; -- bump on changes

if (not LibStub) then
	error(LIB_NAME .. " requires LibStub.");
end
-- local ldb = LibStub("LibDataBroker-1.1", true)
-- if not ldb then error(LIB_NAME .. " requires LibDataBroker-1.1.") end

local LibFroznFunctions = LibStub:NewLibrary(LIB_NAME, LIB_MINOR);

if (not LibFroznFunctions) then
	return;
end

----------------------------------------------------------------------------------------------------
--                                        Classic Support                                         --
----------------------------------------------------------------------------------------------------

-- WoW flavor
--
-- @return .ClassicEra = true/false for Classic Era
--         .BCC        = true/false for BCC
--         .WotLKC     = true/false for WotLKC
--         .SL         = true/false for SL
--         .DF         = true/false for DF
LibFroznFunctions.isWoWFlavor = {
	ClassicEra = false,
	BCC = false,
	WotLKC = false,
	SL = false,
	DF = false
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

-- is unit a battle pet
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return true if it's a battle pet unit, false otherwise.
function LibFroznFunctions:UnitIsBattlePet(unitID)
	if (UnitIsBattlePet) then
		return UnitIsBattlePet(unitID);
	end
	
	return false;
end

-- is unit a wild/tameable battle pet
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return true if it's a wild/tameable battle pet, false otherwise.
function LibFroznFunctions:UnitIsWildBattlePet(unitID)
	if (UnitIsWildBattlePet) then
		return UnitIsWildBattlePet(unitID);
	end
	
	return false;
end

-- is unit a battle pet summoned by a player
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return true if it's a battle pet summoned by a player, false otherwise.
function LibFroznFunctions:UnitIsBattlePetCompanion(unitID)
	if (UnitIsBattlePetCompanion) then
		return UnitIsBattlePetCompanion(unitID);
	end
	
	return false;
end

-- create color from hex string
--
-- @param  hexColor  color represented by hexadecimal digits in format AARRGGBB, e.g. "FFFF7C0A" (orange color for druid)
-- @return ColorMixin
function LibFroznFunctions:CreateColorFromHexString(hexColor)
	if (CreateColorFromHexString) then
		return CreateColorFromHexString(hexColor);
	end
	
	if (#hexColor == 8) then
		local function ExtractColorValueFromHex(str, index)
			return tonumber(str:sub(index, index + 1), 16) / 255;
		end
		
		local a, r, g, b = ExtractColorValueFromHex(hexColor, 1), ExtractColorValueFromHex(hexColor, 3), ExtractColorValueFromHex(hexColor, 5), ExtractColorValueFromHex(hexColor, 7);
		
		return CreateColor(r, g, b, a);
	else
		error("CreateColorFromHexString input must be hexadecimal digits in this format: AARRGGBB.");
	end
end

-- get unit from tooltip
--
-- @param  tooltip  tooltip
-- @return name, unit id[, unit guid]
function LibFroznFunctions:GetUnitFromTooltip(tooltip)
	if (TooltipUtil) then
		return TooltipUtil.GetDisplayedUnit(tooltip);
	else
		return tooltip:GetUnit();
	end
end

-- hook tooltip's OnTooltipSetUnit
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetUnit(tip, callback)
	if (TooltipDataProcessor) then -- since df 10.0.2
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
	else -- before df 10.0.2
		tip:HookScript("OnTooltipSetUnit", callback);
	end
end

-- get item from tooltip
--
-- @param  tooltip  tooltip
-- @return itemName, itemLink[, item id]
function LibFroznFunctions:GetItemFromTooltip(tooltip)
	if (TooltipUtil) then
		if (tooltip:IsTooltipType(Enum.TooltipDataType.Toy)) then -- see TooltipUtil.GetDisplayedItem() in "TooltipUtil.lua"
			local tooltipData = tooltip:GetTooltipData();
			local itemLink = C_ToyBox.GetToyLink(tooltipData.id);
			if (itemLink) then
				local name = GetItemInfo(itemLink);
				return name, itemLink, tooltipData.id;
			end
		else
			return TooltipUtil.GetDisplayedItem(tooltip);
		end
	else
		return tooltip:GetItem();
	end
end

-- hook tooltip's OnTooltipSetItem
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetItem(tip, callback)
	if (TooltipDataProcessor) then -- since df 10.0.2
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
	else -- before df 10.0.2
		tip:HookScript("OnTooltipSetItem", callback);
	end
end

-- get spell from tooltip
--
-- @param  tooltip  tooltip
-- @return spellName, spellID
function LibFroznFunctions:GetSpellFromTooltip(tooltip)
	if (TooltipUtil) then
		return TooltipUtil.GetDisplayedSpell(tooltip);
	else
		return tooltip:GetSpell();
	end
end

-- hook tooltip's OnTooltipSetSpell
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetSpell(tip, callback)
	if (TooltipDataProcessor) then -- since df 10.0.2
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
	else -- before df 10.0.2
		tip:HookScript("OnTooltipSetSpell", callback);
	end
end

----------------------------------------------------------------------------------------------------
--                                        Helper Functions                                        --
----------------------------------------------------------------------------------------------------

-- replace parts in text
--
-- @param  text            text to replace parts in, e.g. "Hello %s!"
-- @param  replacements[]  replacements, e.g. { ["Hello"] = "Welcome" }
-- @param  ...             values, e.g. "Bob"
-- @return text with replaced parts
function LibFroznFunctions:ReplaceText(text, replacements, ...)
	local newText = tostring(text);
	
	if (type(replacements) == "table") then
		for key, replacement in pairs(replacements) do
			newText = string.gsub(newText, key, replacement);
		end
	end
	
	return string.format(newText, ...);
end

-- format text
--
-- @param  text            text to format, e.g. "Hello {unitName}! Health: %d"
-- @param  replacements[]  replacements or nil, e.g. { unitName = UnitName("player") }
-- @param  ...             values, e.g. UnitHealth("player")
-- @return formatted text
function LibFroznFunctions:FormatText(text, replacements, ...)
	local newText = tostring(text);
	
	if (type(replacements) == "table") then
		for key, replacement in pairs(replacements) do
			newText = string.gsub(newText, "{" .. key .. "}", replacement);
		end
	end
	
	return string.format(newText, ...);
end

-- convert to table
--
-- @param  obj   object
-- @return object as table
function LibFroznFunctions:ConvertToTable(obj)
	return (type(obj) == "table") and obj or { obj };
end

-- check if table is empty
--
-- @param  tab[]  table to check if it's empty
-- @return true if table is empty, false otherwise. returns nil if table is missing/invalid.
function LibFroznFunctions:IsTableEmpty(tab)
	-- no table
	if (type(tab) ~= "table") then
		return nil;
	end
	
	-- check if table is empty
	return (next(tab) == nil);
end

-- remove items from table
--
-- @param  tab[]     table to remove items from
-- @param  removeFn  function to determine which items should be removed. if function returns true for the current item, it will be removed.
-- @return number of removed items
function LibFroznFunctions:removeFromTable(tab, removeFn)
	-- no table
	if (type(tab) ~= "table") then
		return 0;
	end
	
	-- remove items from table
	local tabLength = #tab;
	local secondIndex = 0;
	
	for index = 1, tabLength do
		if (removeFn(tab[index])) then
			tab[index] = nil;
		else
			secondIndex = secondIndex + 1;
			
			if (index ~= secondIndex) then
				tab[secondIndex] = tab[index];
				tab[index] = nil;
			end
		end
	end
	
	return tabLength - secondIndex;
end

-- remove all items from table
--
-- @param tab[]  table to remove all items from
function LibFroznFunctions:removeAllFromTable(tab)
	-- no table
	if (type(tab) ~= "table") then
		return;
	end
	
	-- remove all items from table
	for key, value in pairs(tab) do
		if (type(value) == "table") then
			self:removeAllFromTable(value);
		end
	end
	
	wipe(tab);
end

-- chain tables
--
-- @param  leadingTable[]    leading table
-- @param  alternateTable[]  alternate table
-- @return chained table[]
function LibFroznFunctions:ChainTables(leadingTable, alternateTable)
	local oldLeadingTableMetatable = getmetatable(leadingTable);
	
	return setmetatable(leadingTable, {
		__index = function(tab, index)
			-- check if value exists in alternate table
			local value = alternateTable[index];
			
			if (value) then
				return value;
			end
			
			-- check if value exists in old metatable of leading table
			if (not oldLeadingTableMetatable) or (not oldLeadingTableMetatable.__index) then
				return nil;
			end
			
			if (type(oldLeadingTableMetatable.__index) == "table") then
				return oldLeadingTableMetatable.__index[index];
			end
			
			return oldLeadingTableMetatable.__index(tab, index);
		end
	});
end

-- create push array
--
-- keeps track of the array count internally to avoid the constant
-- use of the length operator (#) recounting the array over and over.
--
-- @param  optionalTable[]  optional table
-- @return pushArray[]                       push array
--         pushArray:Clear()                 wipes push array
--         pushArray:Push(value)             push item in push array
--         pushArray:PushUnique(value)       push item in push array if it doesn't already exist
--         pushArray:PushUniqueOnTop(value)  push item in push array. if it already exists, it will be removed before so that the value is unique and on top.
--         pushArray:GetCount()              returns number of items in push array
--         pushArray:Contains(value)         returns true if push array contains the item, false otherwise.
--         pushArray:Pop()                   pop item out of push array
--         pushArray:Remove(value)           remove item from push array. returns number of removed items
--         pushArray:Concat(sep)             joins push array items, optional with given separator
-- @usage  local pushArray = LibFroznFunctions:CreatePushArray();
--         pushArray:Push("Hello");
--         pushArray:Push("World");
--         pushArray:Push("xxx");
--         if (pushArray:GetCount() > 2) then
--             pushArray:Pop(); -- remove last item
--         end
--         print(pushArray:Concat(" ")); -- output: "Hello World"
--         pushArray:Clear();
local pushArray = {
	__index = {
		Clear = function(tab)
			wipe(tab);
		end,
		Push = function(tab, value)
			tab.next = value;
		end,
		PushUnique = function(tab, value)
			if (tab:Contains(value)) then
				return;
			end
			tab.next = value;
		end,
		PushUniqueOnTop = function(tab, value)
			tab:Remove(value);
			tab.next = value;
		end,
		count = 0,
		GetCount = function(tab)
			return tab.count;
		end,
		Contains = function(tab, value)
			for _, _value in ipairs(tab) do
				if (_value == value) then
					return true;
				end
			end
			return false;
		end,
		Pop = function(tab)
			if (tab.count > 0) then
				local value = rawget(tab, tab.count);
				tab.last = nil;
				return value;
			end
		end,
		Remove = function(tab, value)
			local itemsRemoved = LibFroznFunctions:removeFromTable(tab, function(_value)
				return (_value == value);
			end);
			tab.count = tab.count - itemsRemoved;
			return itemsRemoved;
		end,
		Concat = function(tab, sep)
			return table.concat(tab, sep);
		end
	},
	__newindex = function(tab, key, value)
		if (key == "next") then
			if (value ~= nil) then
				tab.count = tab.count + 1;
				tab.last = value;
			end
		elseif (key == "last") then
			if (tab.count > 0) then
				rawset(tab, tab.count, value);
				
				if (value == nil) then
					tab.count = tab.count - 1;
				end
			end
		else
			rawset(tab, key, value);
		end
	end
};

function LibFroznFunctions:CreatePushArray(optionalTable)
	return setmetatable(optionalTable or {}, pushArray);
end

-- check if item exists in table
--
-- @param  value  item to check if it exists in table
-- @param  tab[]  table to check if item exists in
-- @return true if item exists in table, false otherwise.
function LibFroznFunctions:ExistsInTable(value, tab)
	-- no table
	if (type(tab) ~= "table") then
		return;
	end
	
	-- check if item exists in table
	for _, _value in ipairs(tab) do
		if (_value == value) then
			return true;
		end
	end
	
	return false;
end

-- check if table equals table
--
-- @param  tab[]       table
-- @param  otherTab[]  table
-- @param  shallow     optional. true if only values on the first level should be compared, false/nil if deeper nested values should also be compared.
-- @return true if table equals table, false otherwise.
function LibFroznFunctions:TableEqualsTable(tab, otherTab, shallow)
	-- no table
	if (type(tab) ~= "table") then
		return false;
	end
	if (type(otherTab) ~= "table") then
		return false;
	end
	
	-- check if table equals table
	for key, value in pairs(tab) do
		local otherValue = otherTab[key];
		
		if (value ~= otherValue) then
			return false;
		end
		if (not shallow) and (type(value) == "table") then
			if (not LibFroznFunctions:TableEqualsTable(value, otherValue)) then
				return false;
			end
		end
	end
	for otherKey, otherValue in pairs(otherTab) do
		local value = tab[otherKey];
		
		if (otherValue ~= value) then
			return false;
		end
		if (type(otherValue) == "table") then
			if (not shallow) and (not LibFroznFunctions:TableEqualsTable(otherValue, value)) then
				return false;
			end
		end
	end
	
	return true;
end

-- call function and suppress error message and speech
--
-- @param  func()  function to call
-- @return return values of function to call. returns nil if function to call is missing/invalid.
function LibFroznFunctions:CallFunctionAndSuppressErrorMessageAndSpeech(func)
	-- no function to call
	if (type(func) ~= "function") then
		return nil;
	end
	
	-- call function and suppress error message and speech
	local oldCVarSound_EnableErrorSpeech = GetCVar("Sound_EnableErrorSpeech");
	
	SetCVar("Sound_EnableErrorSpeech", 0);
	
	local values = { func() };
	
	UIErrorsFrame:Clear();
	SetCVar("Sound_EnableErrorSpeech", oldCVarSound_EnableErrorSpeech);
	
	return unpack(values);
end

-- get value from object by path
--
-- @param  obj   object
-- @param  path  path into object, e.g. "info.tooltipData.type"
-- @return return value from path into object, nil otherwise.
function LibFroznFunctions:GetValueFromObjectByPath(obj, path)
	local currentObject = obj;
	
	for partOfPath in tostring(path):gmatch("([^.]+)") do
		if (type(currentObject) ~= "table") then
			return nil;
		end
		
		currentObject = currentObject[partOfPath];
	end
	
	return currentObject;
end

-- mixin missing objects
--
-- @param  obj   object
-- @param  ...   mixins to mixin
-- @return object with mixins excluding already existing objects
function LibFroznFunctions:MixinMissingObjects(obj, ...)
	for i = 1, select("#", ...) do -- see "Mixin.lua"
		local mixin = select(i, ...);
		
		for k, v in pairs(mixin) do
			if (obj[k] == nil) then
				obj[k] = v;
			end
		end
	end

	return obj;
end

-- mixin differing objects
--
-- @param  obj   object
-- @param  ...   mixins to mixin
-- @return object with mixins excluding already existing objects
function LibFroznFunctions:MixinDifferingObjects(obj, ...)
	for i = 1, select("#", ...) do -- see "Mixin.lua"
		local mixin = select(i, ...);
		
		for k, v in pairs(mixin) do
			if (obj[k] ~= v) then
				obj[k] = v;
			end
		end
	end

	return obj;
end

-- call of function delayed
--
-- @param waitSeconds  optional. seconds to wait.
-- @param fn           function to call delayed
function LibFroznFunctions:CallFunctionDelayed(waitSeconds, fn)
	if (waitSeconds) then
		C_Timer.After(waitSeconds, fn);
	else
		fn();
	end
end

-- hook secure func if exists
--
-- @param tab           optional. table to hook the param "functionName" key in. if omitted, defaults to the global table (_G).
-- @param functionName  name of the function being hooked
-- @param hookfunc      hook function
function LibFroznFunctions:HookSecureFuncIfExists(tab, functionName, hookfunc)
	local realTab, realFunctionName;
	
	if (type(tab) == "table") then
		realTab = tab;
		realFunctionName = functionName;
	else
		realTab = _G;
		realFunctionName = tab;
	end
	
	if (type(realTab[realFunctionName]) ~= "function") then
		return;
	end
	
	hooksecurefunc(tab, functionName, hookfunc);
end

----------------------------------------------------------------------------------------------------
--                                         Custom Events                                          --
----------------------------------------------------------------------------------------------------

-- register for group events
--
-- @param  group                string with group name
-- @param  callbacksForEvent[]  table with callback functions ("key = event name" and "value = callback function"). parameters: self, ... (event payload)
-- @param  name                 optional. string with name of group item.
-- @param  disabled             optional. true if item is disabled, false/nil otherwise.
local groupsWithItemsForGroupEvents = {};

function LibFroznFunctions:RegisterForGroupEvents(group, callbacksForEvent, name, disabled)
	-- one of the parameters are invalid
	if (type(group) ~= "string") or (group == "") or (type(callbacksForEvent) ~= "table") then
		return;
	end
	
	-- get group
	local itemGroup;
	
	if (not groupsWithItemsForGroupEvents[group]) then
		-- create group
		groupsWithItemsForGroupEvents[group] = LibFroznFunctions:CreatePushArray();
		itemGroup = groupsWithItemsForGroupEvents[group];
	else
		itemGroup = groupsWithItemsForGroupEvents[group];
	end
	
	-- add item to group
	itemGroup:Push({
		name = name,
		disabled = disabled,
		callbacks = callbacksForEvent
	});
end

-- fire group event
--
-- @param group      string with group name
-- @param eventName  event name
-- @param ...        event payload
function LibFroznFunctions:FireGroupEvent(group, eventName, ...)
	-- one of the parameters are invalid
	if (type(group) ~= "string") or (group == "") or (type(eventName) ~= "string") then
		return;
	end
	
	-- get group
	local itemGroup = groupsWithItemsForGroupEvents[group];
	
	if (not itemGroup) then
		return;
	end
	
	-- fire event for group
	for _, item in ipairs(itemGroup) do
		if (not item.disabled) and (item.callbacks) and (item.callbacks[eventName]) then
			item.callbacks[eventName](item.callbacks, ...);
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                              Chat                                              --
----------------------------------------------------------------------------------------------------

-- add message to (selected) chat frame
--
-- @param  message  message to add to (selected) chat frame
-- @param  ...      additional params (r, g, b, messageID)
function LibFroznFunctions:AddMessageToChatFrame(message, ...)
	(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME):AddMessage(message, ...);
end

----------------------------------------------------------------------------------------------------
--                                         Slash Handling                                         --
----------------------------------------------------------------------------------------------------

-- register new slash commands
--
-- @param modName                   mod name with/without command name, e.g. "TipTac" or "TipTac_Reset"
-- @param slashCommands             table or string with slash commands, e.g. "/tiptac"
-- @param callbackForSlashCommands  callback function for slash commands. parameters: msg, editBox
function LibFroznFunctions:RegisterNewSlashCommands(modName, slashCommands, callbackForSlashCommands)
	-- one of the parameters are invalid
	if (type(modName) ~= "string") or (modName == "") or (type(slashCommands) ~= "string") and (type(slashCommands) ~= "table") or (type(callbackForSlashCommands) ~= "function") then
		return;
	end
	
	-- register new slash commands
	local preparedModName = modName:gsub(" ", ""):upper(); -- see RegisterNewSlashCommand() in "ChatFrame.lua"
	local preparedSlashCommands = LibFroznFunctions:ConvertToTable(slashCommands);
	local index = 0;
	local keyForPreparedSlashCommand;
	
	for _, slashCommand in ipairs(preparedSlashCommands) do
		if (type(slashCommand) == "string") then
			local preparedSlashCommand = slashCommand:gsub(" ", ""):gsub("/", ""):lower();
			
			if (preparedSlashCommand ~= "") then
				-- find next free index for mod name
				repeat
					index = index + 1;
					keyForPreparedSlashCommand = "SLASH_" .. preparedModName .. index;
				until (not _G[keyForPreparedSlashCommand]);
				
				-- set command
				_G[keyForPreparedSlashCommand] = "/" .. preparedSlashCommand;
			end
		end
	end
	
	-- register callback for commands if some were added
	if (index > 0) then
		SlashCmdList[preparedModName] = callbackForSlashCommands;
	end
end

----------------------------------------------------------------------------------------------------
--                                             Addons                                             --
----------------------------------------------------------------------------------------------------

-- is addon finished loading
--
-- @param  indexOrName  index or name of the addon (as in TOC/folder filename), case insensitive
-- @return true if the addon finished loading, false otherwise.
function LibFroznFunctions:IsAddOnFinishedLoading(indexOrName)
	local loaded, finished = IsAddOnLoaded(indexOrName)
	
	return loaded and finished;
end

----------------------------------------------------------------------------------------------------
--                                             Colors                                             --
----------------------------------------------------------------------------------------------------

-- create color smart
--
-- @param  colorDefinition  table or string. formats:
--                            { r = <r value>, g = <g value>, b = <b value>[, a = <a value>] }
--                            { <r value>, <g value>, <b value>[, <a value> }
--                            [|c]<2 hex digits for a value><2 hex digits for r value><2 hex digits for g value><2 hex digits for b value>
-- @param  asBytes          if param "colorDefinition" is a table, the value range for r/g/b/a is treated as 0-255 instead of 0-1.
-- @return ColorMixin  returns nil of no valid color definition with param "colorDefinition" is specified.
function LibFroznFunctions:CreateColorSmart(colorDefinition, asBytes)
	if (type(colorDefinition) == "table") then
		if (colorDefinition.r) and (colorDefinition.g) and (colorDefinition.b) then
			return asBytes and CreateColorFromBytes(colorDefinition.r, colorDefinition.g, colorDefinition.b, colorDefinition.a or 255) or CreateColor(colorDefinition.r, colorDefinition.g, colorDefinition.b, colorDefinition.a or 1);
		end
		
		local r, g, b, a = unpack(colorDefinition);
		
		return asBytes and CreateColorFromBytes(r, g, b, a or 255) or CreateColor(r, g, b, a or 1);
	end
	
	if (type(colorDefinition) ~= "string") then
		return nil;
	end
	
	local hexA, hexR, hexG, hexB = colorDefinition:gsub("|c", ""):match("(%2x)(%2x)(%2x)(%2x)");
	
	return hexA and CreateColorFromBytes(tonumber("0x" .. hexR), tonumber("0x" .. hexG), tonumber("0x" .. hexB), tonumber("0x" .. hexA));
end

-- get class color
--
-- @param  classID                     class id of unit
-- @param  alternateClassIDIfNotFound  alternate class id if color for param "classID" doesn't exist
-- @return ColorMixin  returns nil if class file for param "classID" and "alternateClassIDIfNotFound" doesn't exist.
local LFF_CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS; -- see "ColorUtil.lua"

function LibFroznFunctions:GetClassColor(classID, alternateClassIDIfNotFound)
	local classInfo = (classID and C_CreatureInfo.GetClassInfo(classID)) or (alternateClassIDIfNotFound and C_CreatureInfo.GetClassInfo(alternateClassIDIfNotFound));
	
	return classInfo and LFF_CLASS_COLORS[classInfo.classFile];
end

-- get class color by class file
--
-- @param  classFile                     locale-independent class file of unit, e.g. "WARRIOR"
-- @param  alternateClassFileIfNotFound  alternate class file if color for param "classFile" doesn't exist
-- @return ColorMixin  returns nil if class file for param "classFile" and "alternateClassFileIfNotFound" doesn't exist.
function LibFroznFunctions:GetClassColorByClassFile(classFile, alternateClassFileIfNotFound)
	return LFF_CLASS_COLORS[classFile] or LFF_CLASS_COLORS[alternateClassFileIfNotFound];
end

-- get power color
--
-- @param  powerType                     power type of unit, e.g. 0 (Mana) or (1) Rage, see "Enum.PowerType"
-- @param  alternatePowerTypeIfNotFound  alternate power type if color for param "powerType" doesn't exist
-- @return ColorMixin  returns nil if power type for param "powerType" and "alternatePowerTypeIfNotFound" doesn't exist.
local powerTypeToPowerTokenLookup = { -- see powerTypeToStringLookup in "Blizzard_CombatLog.lua"
	[Enum.PowerType.Mana] = "MANA",
	[Enum.PowerType.Rage] = "RAGE",
	[Enum.PowerType.Focus] = "FOCUS",
	[Enum.PowerType.Energy] = "ENERGY",
	[Enum.PowerType.ComboPoints] = "COMBO_POINTS",
	[Enum.PowerType.Runes] = "RUNES",
	[Enum.PowerType.RunicPower] = "RUNIC_POWER",
	[Enum.PowerType.SoulShards] = "SOUL_SHARDS",
	[Enum.PowerType.LunarPower] = "LUNAR_POWER",
	[Enum.PowerType.HolyPower] = "HOLY_POWER",
	[Enum.PowerType.Maelstrom] = "MAELSTROM",
	[Enum.PowerType.Chi] = "CHI",
	[Enum.PowerType.Insanity] = "INSANITY",
	[Enum.PowerType.ArcaneCharges] = "ARCANE_CHARGES",
	[Enum.PowerType.Fury] = "FURY",
	[Enum.PowerType.Pain] = "PAIN"
};

if (Enum.PowerType.Essence) then
	powerTypeToPowerTokenLookup[Enum.PowerType.Essence] = POWER_TYPE_ESSENCE;
end

function LibFroznFunctions:GetPowerColor(powerType, alternatePowerTypeIfNotFound)
	return LibFroznFunctions:CreateColorSmart((powerTypeToPowerTokenLookup[powerType] and PowerBarColor[powerTypeToPowerTokenLookup[powerType]]) or (powerTypeToPowerTokenLookup[alternatePowerTypeIfNotFound] and PowerBarColor[powerTypeToPowerTokenLookup[alternatePowerTypeIfNotFound]]));
end

-- get item quality color
--
-- @param  quality                     item quality, e.g. 0 (poor), 3 (rare), 4 (epic), see "Enum.ItemQuality"
-- @param  alternateQualityIfNotFound  alternate quality if color for param "quality" doesn't exist
-- @return ColorMixin  returns nil if quality for param "quality" and "alternateQualityIfNotFound" doesn't exist.
function LibFroznFunctions:GetItemQualityColor(quality, alternateQualityIfNotFound)
	return (ITEM_QUALITY_COLORS[quality] and ITEM_QUALITY_COLORS[quality].color) or (ITEM_QUALITY_COLORS[alternateQualityIfNotFound] and ITEM_QUALITY_COLORS[alternateQualityIfNotFound].color); -- see "UIParent.lua"
end

-- get difficulty color for unit compared to the player level
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return ColorMixin  difficulty color. returns nil if no unit id is supplied.
function LibFroznFunctions:GetDifficultyColorForUnit(unitID)
	-- no unit id
	if (not unitID) then
		return nil;
	end
	
	-- get difficulty color for unit compared to the player level
	local isBattlePet = LibFroznFunctions:UnitIsBattlePet(unitID);
	local unitLevel = isBattlePet and UnitBattlePetLevel(unitID) or UnitLevel(unitID) or -1;
	
	local difficultyColor;
	
	if (unitLevel == -1) then
		difficultyColor = QuestDifficultyColors["impossible"]; -- see "Constants.lua"
	else
		difficultyColor = GetDifficultyColor and GetDifficultyColor(C_PlayerInfo.GetContentDifficultyCreatureForPlayer(unitID)) or GetCreatureDifficultyColor(unitLevel); -- see "UIParent.lua"
	end
	
	return LibFroznFunctions:CreateColorSmart(difficultyColor);
end

-- get difficulty color for quest compared to the player level
--
-- @param  questID     quest id
-- @param  questLevel  quest level
-- @return ColorMixin  difficulty color. returns nil if no quest id is supplied or quest level is invalid.
function LibFroznFunctions:GetDifficultyColorForQuest(questID, questLevel)
	-- no quest id or invalid number
	if (not questID) or (type(questLevel) ~= "number") then
		return nil;
	end
	
	-- world quests
	if (C_QuestLog.IsWorldQuest) and (C_QuestLog.IsWorldQuest(questID)) then -- see GameTooltip_AddQuest()
		local tagInfo = C_QuestLog.GetQuestTagInfo(questID);
		local worldQuestQuality = tagInfo and tagInfo.quality or Enum.WorldQuestQuality.Common;
		
		return WORLD_QUEST_QUALITY_COLORS[worldQuestQuality].color; -- see "UIParent.lua"
	end
	
	-- other quests
	local difficultyColor = GetDifficultyColor and GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID)) or GetQuestDifficultyColor(questLevel); -- see "UIParent.lua"
	
	return LibFroznFunctions:CreateColorSmart(difficultyColor);
end

----------------------------------------------------------------------------------------------------
--                                             Icons                                              --
----------------------------------------------------------------------------------------------------

-- create markup for role icon
--
-- @param  role  "DAMAGER", "TANK" or "HEALER"
-- @return markup for role icon to use in text. returns nil for invalid roles.
function LibFroznFunctions:CreateMarkupForRoleIcon(role)
	if (role == "TANK") then
		return CreateAtlasMarkup("roleicon-tiny-tank");
	elseif (role == "DAMAGER") then
		return CreateAtlasMarkup("roleicon-tiny-dps");
	elseif (role == "HEALER") then
		return CreateAtlasMarkup("roleicon-tiny-healer");
	else
		return nil;
	end
end

-- create markup for class icon
--
-- @param  classIcon  file id/path for class icon
-- @return markup for class icon to use in text. returns nil if class icon is invalid.
function LibFroznFunctions:CreateMarkupForClassIcon(classIcon)
	-- invalid class icon
	if (type(classIcon) ~= "number") and (type(classIcon) ~= "string") then
		return nil;
	end
	
	-- create markup for class icon
	return CreateTextureMarkup(classIcon, 64, 64, nil, nil, 0.07, 0.93, 0.07, 0.93);
end

----------------------------------------------------------------------------------------------------
--                                           Anchoring                                            --
----------------------------------------------------------------------------------------------------

-- mirror anchor point vertically
--
-- @param  anchorPoint  anchor point, e.g. "TOP" or "BOTTOMRIGHT"
-- @return vertically mirrored anchor point.
--         returns nil if no valid anchor point is supplied.
local anchorToVerticallyMirroredAnchorPointLookup = {
	TOP = "BOTTOM",
	TOPLEFT = "TOPRIGHT",
	TOPRIGHT = "TOPLEFT",
	BOTTOM = "TOP",
	BOTTOMLEFT = "BOTTOMRIGHT",
	BOTTOMRIGHT = "BOTTOMLEFT",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	CENTER = "CENTER"
};

function LibFroznFunctions:MirrorAnchorPointVertically(anchorPoint)
	return anchorToVerticallyMirroredAnchorPointLookup[anchorPoint];
end

-- mirror anchor point horizontally
--
-- @param  anchorPoint  anchor point, e.g. "TOP" or "BOTTOMRIGHT"
-- @return horizontally mirrored anchor point.
--         returns nil if no valid anchor point is supplied.
local anchorToHorizontallyMirroredAnchorPointLookup = {
	TOP = "BOTTOM",
	TOPLEFT = "BOTTOMLEFT",
	TOPRIGHT = "BOTTOMRIGHT",
	BOTTOM = "TOP",
	BOTTOMLEFT = "TOPLEFT",
	BOTTOMRIGHT = "TOPRIGHT",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	CENTER = "CENTER"
};

function LibFroznFunctions:MirrorAnchorPointHorizontally(anchorPoint)
	return anchorToHorizontallyMirroredAnchorPointLookup[anchorPoint];
end

-- mirror anchor point centered
--
-- @param  anchorPoint  anchor point, e.g. "TOP" or "BOTTOMRIGHT"
-- @return centered mirrored anchor point.
--         returns nil if no valid anchor point is supplied.

local anchorToCenteredMirroredAnchorPointLookup = {
	TOP = "BOTTOM",
	TOPLEFT = "BOTTOMRIGHT",
	TOPRIGHT = "BOTTOMLEFT",
	BOTTOM = "TOP",
	BOTTOMLEFT = "TOPRIGHT",
	BOTTOMRIGHT = "TOPLEFT",
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	CENTER = "CENTER"
};

function LibFroznFunctions:MirrorAnchorPointCentered(anchorPoint)
	return anchorToCenteredMirroredAnchorPointLookup[anchorPoint];
end

-- get offsets for anchor point between two frames
--
-- @param  anchorPoint  anchor point, e.g. "TOP" or "BOTTOMRIGHT"
-- @param  frame           frame
-- @param  frameReference  reference frame
-- @return left offset, right offset. nil, nil if no valid anchor point is supplied.
function LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, anchorFrame, targetFrame, referenceFrame)
	local effectiveScaleTargetFrame = targetFrame:GetEffectiveScale();
	local UIScale = UIParent:GetEffectiveScale();
	
	local totalEffectiveScaleTargetFrame = effectiveScaleTargetFrame / UIScale;
	
	if (anchorPoint == "TOPLEFT") then
		return (anchorFrame:GetLeft() - referenceFrame:GetLeft()) / totalEffectiveScaleTargetFrame, (anchorFrame:GetTop() - referenceFrame:GetTop()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "TOPRIGHT") then
		return (anchorFrame:GetRight() - referenceFrame:GetRight()) / totalEffectiveScaleTargetFrame, (anchorFrame:GetTop() - referenceFrame:GetTop()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOMLEFT") then
		return (anchorFrame:GetLeft() - referenceFrame:GetLeft()) / totalEffectiveScaleTargetFrame, (anchorFrame:GetBottom() - referenceFrame:GetBottom()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOMRIGHT") then
		return (anchorFrame:GetRight() - referenceFrame:GetRight()) / totalEffectiveScaleTargetFrame, (anchorFrame:GetBottom() - referenceFrame:GetBottom()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "TOP") then
		return (((anchorFrame:GetLeft() + anchorFrame:GetRight()) - (referenceFrame:GetLeft() + referenceFrame:GetRight())) / totalEffectiveScaleTargetFrame) / 2, (anchorFrame:GetTop() - referenceFrame:GetTop()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOM") then
		return (((anchorFrame:GetLeft() + anchorFrame:GetRight()) - (referenceFrame:GetLeft() + referenceFrame:GetRight())) / totalEffectiveScaleTargetFrame) / 2, (anchorFrame:GetBottom() - referenceFrame:GetBottom()) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "LEFT") then
		return (anchorFrame:GetLeft() - referenceFrame:GetLeft()) / totalEffectiveScaleTargetFrame, (((anchorFrame:GetTop() + anchorFrame:GetBottom()) - (referenceFrame:GetTop() + referenceFrame:GetBottom())) / totalEffectiveScaleTargetFrame) / 2;
	end
	if (anchorPoint == "RIGHT") then
		return (anchorFrame:GetRight() - referenceFrame:GetRight()) / totalEffectiveScaleTargetFrame, (((anchorFrame:GetTop() + anchorFrame:GetBottom()) - (referenceFrame:GetTop() + referenceFrame:GetBottom())) / totalEffectiveScaleTargetFrame) / 2;
	end
	if (anchorPoint == "CENTER") then
		return (((anchorFrame:GetLeft() + anchorFrame:GetRight()) - (referenceFrame:GetLeft() + referenceFrame:GetRight())) / totalEffectiveScaleTargetFrame) / 2, (((anchorFrame:GetTop() + anchorFrame:GetBottom()) - (referenceFrame:GetTop() + referenceFrame:GetBottom())) / totalEffectiveScaleTargetFrame) / 2;
	end
	
	return nil, nil;
end

----------------------------------------------------------------------------------------------------
--                                             Frames                                             --
----------------------------------------------------------------------------------------------------

-- strip textures from object
--
-- @param obj  object to strip textures from
function LibFroznFunctions:StripTextures(obj)
	local nineSlicePieces = { -- keys have to match pieceNames in nineSliceSetup table in "NineSlice.lua"
		"TopLeftCorner",
		"TopRightCorner",
		"BottomLeftCorner",
		"BottomRightCorner",
		"TopEdge",
		"BottomEdge",
		"LeftEdge",
		"RightEdge",
		"Center"
	};

	for index, pieceName in ipairs(nineSlicePieces) do
		local region = obj[pieceName];
		
		if (region) then
			region:SetTexture(nil);
			region:SetAtlas(nil);
		end
	end
end

-- check if frame exists back in frame chain
--
-- @param  referenceFrame         frame to start searching in
-- @param  framesAndNamePatterns  frame or pattern to search back in frame chain, or a table of this.
-- @param  maxLevelBack           optional. max level to search back in frame chain, e.g. 1 = actual level, 2 = actual and one level back.
-- @return true if frame or pattern in frame chain exists
function LibFroznFunctions:IsFrameBackInFrameChain(referenceFrame, framesAndNamePatterns, maxLevel)
	local currentFrame = referenceFrame;
	local currentLevel = 1;
	
	while (currentFrame) do
		for _, frameAndNamePattern in ipairs(LibFroznFunctions:ConvertToTable(framesAndNamePatterns)) do
			if (type(frameAndNamePattern) == "table") then
				if (currentFrame == patternOrFrame) then
					return true;
				end
			elseif (type(frameAndNamePattern) == "string") then
				if (type(currentFrame.GetName) == "function") then
					local currentFrameName = currentFrame:GetName();
				
					if (currentFrameName) and (currentFrameName:match(frameAndNamePattern)) then
						return true;
					end
				end
			end
		end
		
		if (maxLevel) and (currentLevel == maxLevel) then
			return false;
		end
		
		if (type(currentFrame.GetParent) ~= "function") then
			return false;
		end
		
		currentFrame = currentFrame:GetParent();
		currentLevel = currentLevel + 1;
	end
	
	return false;
end

-- recalculate size of GameTooltip
--
-- @param tip  GameTooltip
function LibFroznFunctions:RecalculateSizeOfGameTooltip(tip)
	if (type(tip.GetObjectType) ~= "function") or (tip:GetObjectType() ~= "GameTooltip") then
		return;
	end
	
	tip:SetPadding(tip:GetPadding());
end

----------------------------------------------------------------------------------------------------
--                                             Fonts                                              --
----------------------------------------------------------------------------------------------------

-- check if font exists
--
-- @param  fontFile  path to a font file
-- @return true if font exists, false otherwise.
local fontExistsFrame, fontExistsFontString;

function LibFroznFunctions:FontExists(fontFile)
	-- invalid font file
	if (type(fontFile) ~= "string") then
		return false;
	end
	
	-- create frame
	if (not fontExistsFrame) then
		fontExistsFrame = CreateFrame("Frame");
	end
	
	-- create font string
	if (not fontExistsFontString) then
		fontExistsFontString = fontExistsFrame:CreateFontString();
	end
	
	-- check if font exists
	fontExistsFontString:SetFont(fontFile, 10, "");
	
	return (not not fontExistsFontString:GetFont());
end

----------------------------------------------------------------------------------------------------
--                                            Textures                                            --
----------------------------------------------------------------------------------------------------

-- check if texture exists
--
-- @param  textureFile  path to a texture (usually in Interface\\) or a FileDataID
-- @return true if texture exists, false otherwise.
local textureExistsFrame, textureExistsTexture;

function LibFroznFunctions:TextureExists(textureFile)
	-- invalid texture file
	if (type(textureFile) ~= "string") and (type(textureFile) ~= "number") then
		return false;
	end
	
	-- create frame
	if (not textureExistsFrame) then
		textureExistsFrame = CreateFrame("Frame");
	end
	
	-- create texture
	if (not textureExistsTexture) then
		textureExistsTexture = textureExistsFrame:CreateTexture();
	end
	
	-- check if texture exists
	textureExistsTexture:SetTexture("?");
	textureExistsTexture:SetTexture(textureFile);
	
	return (textureExistsTexture:GetTexture() ~= "?");
end

----------------------------------------------------------------------------------------------------
--                                             Units                                              --
----------------------------------------------------------------------------------------------------

-- get unit id from unit guid
--
-- @param  unit guid  unit guid
-- @return unit id, unit name. nil, unit name otherwise.
function LibFroznFunctions:GetUnitIDFromGUID(unitGUID)
	-- no unit guid
	if (not unitGUID) then
		return nil, nil;
	end
	
    local unitName = select(6, GetPlayerInfoByGUID(unitGUID));
	
	-- no unit name
	if (not unitName) then
		return nil, nil;
	end
	
	-- use blizzard function, since df 10.0.2
	if (UnitTokenFromGUID) then
		local unitID = UnitTokenFromGUID(unitGUID);
		
		if (unitID) then
			return unitID, unitName;
		end
		
		return nil, unitName;
	end
	
	-- check unit name if unit is in the current zone
    if (UnitExists(unitName)) then
        return unitName, unitName;
	end
	
	-- check fixed unit ids
	local checkUnitIDs = {
		"player", "mouseover", "target", "focus", "npc", "softenemy", "softfriend", "softinteract", "pet", "vehicle"
	};
	
	for _, checkUnitID in ipairs(checkUnitIDs) do
		if (UnitGUID(checkUnitID) == unitGUID) then
			return checkUnitID, unitName;
		end
	end
	
	-- check party/raid unit ids
	local numMembers = GetNumGroupMembers();
	local isInRaid = IsInRaid();
	local checkUnitID;
	
	if (numMembers > 0) then
		for i = 1, numMembers do
			checkUnitID = (inRaid and "raid" .. i or "party" .. i);
			
			if (UnitGUID(checkUnitID) == unitGUID) then
				return checkUnitID, unitName;
			end
		end
	end
	
	-- check nameplate unit ids
	local nameplates = C_NamePlate.GetNamePlates();
	local numNameplates = #nameplates;
	
	if (numNameplates > 0) then
		for i = 1, numNameplates do
			checkUnitID = (nameplates[i].namePlateUnitToken or "nameplate" .. i);
			
			if (UnitGUID(checkUnitID) == unitGUID) then
				return checkUnitID, unitName;
			end
		end
	end
	
    -- no unit id found
    return nil, unitName;
end

-- get unit reaction index from unit id
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return reaction index, see LFF_UNIT_REACTION_INDEX
--         returns nil if no unit id is supplied.
LFF_UNIT_REACTION_INDEX = {
	tapped = 1,            -- Tapped by other Player
	hostile = 2,           -- Hostile             (unit can attack the player and vice versa)
	caution = 3,           -- Caution             (unit can attack the player but the player not the unit)
	neutral = 4,           -- Neutral             (unit can't attack the player but the player can)
	friendlyPlayer = 5,    -- Friendly Player     (unit can't attack the player and vice versa and isn't flagged for PvP)
	friendlyPvPPlayer = 6, -- Friendly PvP Player (unit can't attack the player and vice versa and is flagged for PvP)
	friendlyNPC = 7,       -- Friendly NPC        (unit can't attack the player and vice versa and isn't a player or player controlled aka a NPC)
	honoredNPC = 8,        -- Honored NPC         (unit can't attack the player and vice versa and isn't a player or player controlled aka a NPC)
	reveredNPC = 9,        -- Revered NPC         (unit can't attack the player and vice versa and isn't a player or player controlled aka a NPC)
	exaltedNPC = 10,       -- Exalted NPC         (unit can't attack the player and vice versa and isn't a player or player controlled aka a NPC)
	dead = 11              -- Dead
};

function LibFroznFunctions:GetUnitReactionIndex(unitID)
	-- no unit id
	if (not unitID) then
		return nil;
	end
	
	-- dead unit
	if (UnitIsDead(unitID)) then
		return LFF_UNIT_REACTION_INDEX.dead; -- 11 = Dead
	end
	
	-- player or player controlled unit
	if (UnitIsPlayer(unitID)) or (UnitPlayerControlled(unitID)) then -- can't rely on UnitPlayerControlled() alone, since it always returns nil on units out of range.
		if (UnitCanAttack(unitID, "player")) then
			return (UnitCanAttack("player", unitID) and LFF_UNIT_REACTION_INDEX.hostile or LFF_UNIT_REACTION_INDEX.caution); -- 2 = Hostile, 3 = Caution
		end
		
		if (UnitCanAttack("player", unitID)) then
			return LFF_UNIT_REACTION_INDEX.neutral; -- 4 = Neutral
		end
		
		if (UnitIsPVP(unitID)) and (not UnitIsPVPSanctuary(unitID)) and (not UnitIsPVPSanctuary("player")) then
			return LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer; -- 6 = Friendly PvP Player
		end
		
		return LFF_UNIT_REACTION_INDEX.friendlyPlayer; -- 5 = Friendly Player
	end
	
	-- tapped unit
	if (UnitIsTapDenied(unitID)) then
		return LFF_UNIT_REACTION_INDEX.tapped; -- 1 = Tapped by other Player
	end
	
	-- NPC / other
	--
	-- 1. Hated      ->  2 = Hostile
	-- 2. Hostile    ->  2 = Hostile
	-- 3. Unfriendly ->  3 = Caution
	-- 4. Neutral    ->  4 = Neutral
	-- 5. Friendly   ->  7 = Friendly NPC
	-- 6. Honored    ->  8 = Honored NPC
	-- 7. Revered    ->  9 = Revered NPC
	-- 8. Exalted    -> 10 = Exalted NPC
	local reaction = (UnitReaction(unitID, "player") or 3); -- default: 3 = Caution
	
	if (reaction <= 2) then
		return LFF_UNIT_REACTION_INDEX.hostile;
	end
	if (reaction == 3) then
		return LFF_UNIT_REACTION_INDEX.caution;
	end
	if (reaction == 4) then
		return LFF_UNIT_REACTION_INDEX.neutral;
	end
	if (reaction == 5) then
		return LFF_UNIT_REACTION_INDEX.friendlyNPC;
	end
	if (reaction == 6) then
		return LFF_UNIT_REACTION_INDEX.honoredNPC;
	end
	if (reaction == 7) then
		return LFF_UNIT_REACTION_INDEX.reveredNPC;
	end
	
	return LFF_UNIT_REACTION_INDEX.exaltedNPC;
end

-- create unit record
--
-- @param  unitID    unit id, e.g. "player", "target" or "mouseover"
-- @param  unitGUID  optional. unit guid
-- @return unitRecord
--           .guid                         guid of unit
--           .id                           id of unit
--           .timestamp                    timestamp of last update of record, 0 otherwise.
--           .isPlayer                     true if it's a player unit, false otherwise.
--           .isSelf                       true if it's the player unit, false otherwise.
--           .isOtherPlayer                true if it's a player unit but not the player unit, false otherwise.
--           .isPet                        true if it's not a player unit but player controlled aka a pet, false otherwise.
--           .isBattlePet                  true if it's a battle pet unit, false otherwise.
--           .isWildBattlePet              true if it's a wild/tameable battle pet, false otherwise.
--           .isBattlePetCompanion         true if it's a battle pet summoned by a player, false otherwise.
--           .isNPC                        true if it's not a player unit, pet or battle pet. false otherwise.
--           .level                        level of unit
--           .name                         name of unit, e.g. "Rugnaer"
--           .nameWithForeignServerSuffix  name of unit with additional foreign server suffix if needed, e.g. "Rugnaer (*)"
--           .nameWithServerName           name with server name of unit, e.g. "Rugnaer-DunMorogh"
--           .nameWithTitle                name with title of unit, e.g. "Sternenrufer Rugnaer"
--           .serverName                   server name of unit, e.g. "DunMorogh"
--           .className                    localized class name of unit, e.g. "Warrior" or "Guerrier"
--           .classFile                    locale-independent class file of unit, e.g. "WARRIOR"
--           .classID                      class id of unit
--           .classification               classification of unit, values "worldboss", "rareelite", "elite", "rare", "normal", "trivial" or "minus"
--           .reactionIndex                reaction index of unit, see LFF_UNIT_REACTION_INDEX
--           .health                       health of unit
--           .healthMax                    max health of unit
--           .powerType                    power type of unit, e.g. 0 (Mana) or (1) Rage, see "Enum.PowerType"
--           .power                        power of unit
--           .powerMax                     max power of unit
--         returns nil if no unit id is supplied
function LibFroznFunctions:CreateUnitRecord(unitID, unitGUID)
	-- no unit id
	if (not unitID) then
		return nil;
	end
	
	-- create unit record
	local unitRecord = {};
	
	unitRecord.guid = unitGUID or UnitGUID(unitID);
	unitRecord.id = unitID;
	
	unitRecord.timestamp = 0;
	
	unitRecord.isPlayer = UnitIsPlayer(unitID);
	unitRecord.isSelf = unitRecord.isPlayer and UnitIsUnit(unitID, "player");
	unitRecord.isOtherPlayer = unitRecord.isPlayer and (not unitRecord.isSelf);
	unitRecord.isPet = (not unitRecord.isPlayer) and UnitPlayerControlled(unitID);
	unitRecord.isBattlePet = LibFroznFunctions:UnitIsBattlePet(unitID);
	unitRecord.isWildBattlePet = LibFroznFunctions:UnitIsWildBattlePet(unitID);
	unitRecord.isBattlePetCompanion = LibFroznFunctions:UnitIsBattlePetCompanion(unitID);
	unitRecord.isNPC = (not unitRecord.isPlayer) and (not unitRecord.isPet) and (not unitRecord.isBattlePet);
	
	unitRecord.name, unitRecord.serverName = UnitName(unitID);
	unitRecord.nameWithForeignServerSuffix = GetUnitName(unitID);
	unitRecord.nameWithServerName = GetUnitName(unitID, true);
	unitRecord.nameWithTitle = UnitPVPName(unitID);
	
	unitRecord.className, unitRecord.classFile, unitRecord.classID = UnitClass(unitID);
	
	unitRecord.classification = UnitClassification(unitID);
	
	self:UpdateUnitRecord(unitRecord);
	
	return unitRecord;
end

function LibFroznFunctions:UpdateUnitRecord(unitRecord)
	-- no valid unit any more e.g. during fading out
	local unitID = unitRecord.id;
	
	if (not UnitGUID(unitID)) then
		return;
	end
	
	-- update unit record
	unitRecord.level = unitRecord.isBattlePet and UnitBattlePetLevel(unitID) or UnitLevel(unitID) or -1;
	unitRecord.reactionIndex = LibFroznFunctions:GetUnitReactionIndex(unitID);
	
	unitRecord.health = UnitHealth(unitID);
	unitRecord.healthMax = UnitHealthMax(unitID);
	
	unitRecord.powerType = UnitPowerType(unitID);
	unitRecord.power = UnitPower(unitID);
	unitRecord.powerMax = UnitPowerMax(unitID);
end

----------------------------------------------------------------------------------------------------
--                                           Inspecting                                           --
----------------------------------------------------------------------------------------------------

-- config
local LFF_INSPECT_TIMEOUT = 2; -- safety cap on how often the api will allow us to call NotifyInspect without issues
local LFF_INSPECT_FAIL_TIMEOUT = 1; -- time to wait for event INSPECT_READY with inspect data
local LFF_CACHE_TIMEOUT = 5; -- seconds to keep stale information before issuing a new inspect

-- create frame for delayed inspection
local frameForDelayedInspection = CreateFrame("Frame", LIB_NAME .. "_DelayedInspection");
frameForDelayedInspection:Hide();

frameForDelayedInspection:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...);
end);

-- inspect unit
--
-- @param  unitID                                    unit id, e.g. "player", "target" or "mouseover"
-- @param  callbackForInspectData()                  callback function if inspect data is available. parameters: unitCacheRecord
-- @param  removeCallbackFromQueuedInspectCallbacks  optional. true if callback function should be removed from all queued inspect callbacks.
-- @param  bypassUnitCacheTimeout                    true to bypass unit cache timeout
-- @return unitCacheRecord
--           see LibFroznFunctuions:CreateUnitRecord()
--           additionally:
--           .needsInspect        true if a delayed inspect is needed, false if inspecting the player or the unit cache hasn't been timed out yet.
--           .canInspect          true if inspecting is possible, false otherwise. nil initially.
--           .inspectStatus       inspect status, see LFF_INSPECT_STATUS. nil otherwise.
--           .inspectTimestamp    inspect timestamp, nil otherwise.
--           .callbacks[]         push array with callbacks for inspect data if available
--           .talents             see LibFroznFunctions:GetTalents()
--           .averageItemLevel    see LibFroznFunctions:GetAverageItemLevel()
--         returns nil if no unit id is supplied or unit isn't a player.
local unitCache = {};
local eventsForInspectingRegistered = false;

LFF_INSPECT_STATUS = {
	queuedForNextInspect = 1, -- queued for next inspection
	waitingForInspectData = 2 -- waiting for inspect data
};

function LibFroznFunctions:InspectUnit(unitID, callbackForInspectData, removeCallbackFromQueuedInspectCallbacks, bypassUnitCacheTimeout)
	-- register events for inspecting
	if (not eventsForInspectingRegistered) then
		frameForDelayedInspection:RegisterEvent("INSPECT_READY");
		eventsForInspectingRegistered = true;
	end
	
	-- remove callback function from all queued inspect callbacks if requested
	if (removeCallbackFromQueuedInspectCallbacks) then
		LibFroznFunctions:RemoveCallbackFromQueuedInspectCallbacks(callbackForInspectData);
	end
	
	-- no unit id or not a player
	local isValidUnitID = (unitID) and (UnitIsPlayer(unitID));
	
	if (not isValidUnitID) then
		return nil;
	end
	
	-- get record in unit cache
	local unitGUID = UnitGUID(unitID);
	local unitCacheRecord = frameForDelayedInspection:GetUnitCacheRecord(unitID, unitGUID);
	
	if (not unitCacheRecord) then
		return nil;
	end
	
	-- no need for a delayed inspect request on the player unit
	if (unitCacheRecord.isSelf) then
		frameForDelayedInspection:InspectDataAvailable(unitID, unitCacheRecord);
	
	-- reinspect only if enough time has been elapsed
	elseif (not bypassUnitCacheTimeout) and (GetTime() - unitCacheRecord.timestamp <= LFF_CACHE_TIMEOUT) then
		frameForDelayedInspection:FinishInspect(unitCacheRecord, true);
	
	-- schedule a delayed inspect request
	else
		frameForDelayedInspection:InitiateInspectRequest(unitID, unitCacheRecord, callbackForInspectData);
	end
	
	return unitCacheRecord;
end

-- remove callback function from all queued inspect callbacks if requested
--
-- @param  callbackForInspectData()  callback function if inspect data is available which should be removed from all queued inspect callbacks
function LibFroznFunctions:RemoveCallbackFromQueuedInspectCallbacks(callbackForInspectData)
	for _, unitCacheRecord in ipairs(unitCache) do
		unitCacheRecord.callbacks:Remove(callbackForInspectData);
	end
end

-- get record in unit cache
function frameForDelayedInspection:GetUnitCacheRecord(unitID, unitGUID)
	-- no unit guid
	if (not unitGUID) then
		return nil;
	end
	
	-- get record in unit cache
	local unitCacheRecord;
	local isValidUnitID = (unitID) and (UnitIsPlayer(unitID));
	
	if (not unitCache[unitGUID]) then
		-- create record in unit cache if a valid unit id is available
		if (isValidUnitID) then
			unitCacheRecord = frameForDelayedInspection:CreateUnitCacheRecord(unitID, unitGUID);
		end
	else
		unitCacheRecord = unitCache[unitGUID];
	end
	
	-- update record in unit cache if a valid unit id is available
	if (unitCacheRecord) and (isValidUnitID) then
		unitCacheRecord.level = UnitLevel(unitID);
	end
	
	return unitCacheRecord;
end

-- create record in unit cache
function frameForDelayedInspection:CreateUnitCacheRecord(unitID, unitGUID)
	unitCache[unitGUID] = LibFroznFunctions:CreateUnitRecord(unitID, unitGUID);
	unitCacheRecord = unitCache[unitGUID];
	
	unitCacheRecord.needsInspect = false;
	unitCacheRecord.canInspect = nil;
	unitCacheRecord.inspectStatus = nil;
	unitCacheRecord.inspectTimestamp = 0;
	unitCacheRecord.callbacks = LibFroznFunctions:CreatePushArray();
	
	unitCacheRecord.talents = LibFroznFunctions:AreTalentsAvailable(unitID);
	unitCacheRecord.averageItemLevel = LibFroznFunctions:IsAverageItemLevelAvailable(unitID);
	
	return unitCacheRecord;
end

-- determine if an "Inspect Frame" is open. native inspect as well as addon Examiner are supported.
--
-- @return true if inspect frame is open, false otherwise.
function LibFroznFunctions:IsInspectFrameOpen()
	return (InspectFrame and InspectFrame:IsShown()) or (Examiner and Examiner:IsShown());
end

-- check if inspection is possible
--
-- @param  unitID  unit id, e.g. "player", "target" or "mouseover"
-- @return true if inspection is possible, false otherwise.
function LibFroznFunctions:CanInspect(unitID)
	-- no unit id or not a player
	local isValidUnitID = (unitID) and (UnitIsPlayer(unitID));
	
	if (not isValidUnitID) then
		return false;
	end
	
	-- check if inspection is possible
	local function checkFn()
		return (not LibFroznFunctions:IsInspectFrameOpen()) and (CanInspect(unitID));
	end
	
	-- suppress error message and speech in Classic Era, BCC and WotLKC
	if (LibFroznFunctions.isWoWFlavor.ClassicEra) or (LibFroznFunctions.isWoWFlavor.BCC) or (LibFroznFunctions.isWoWFlavor.WotLKC) then
		return LibFroznFunctions:CallFunctionAndSuppressErrorMessageAndSpeech(checkFn);
	end
	
	return checkFn();
end

-- initiate inspect request
local unitCacheQueuedForNextInspect = LibFroznFunctions:CreatePushArray();

function frameForDelayedInspection:InitiateInspectRequest(unitID, unitCacheRecord, callbackForInspectData)
	-- check if inspect isn't possible
	unitCacheRecord.canInspect = LibFroznFunctions:CanInspect(unitID);
	
	if (not unitCacheRecord.canInspect) then
		frameForDelayedInspection:FinishInspect(unitCacheRecord, true);
		
		return;
	end
	
	-- don't inspect if we're already waiting for inspect data and it hasn't been timed out yet
	if (unitCacheRecord.inspectStatus == LFF_INSPECT_STATUS.waitingForInspectData) and (GetTime() - unitCacheRecord.inspectTimestamp <= LFF_INSPECT_FAIL_TIMEOUT) then
		return;
	end
	
	-- add callback for inspect data
	unitCacheRecord.needsInspect = true;
	unitCacheRecord.callbacks:PushUnique(callbackForInspectData);
	
	-- schedule a delayed inspect request
	unitCacheRecord.inspectStatus = LFF_INSPECT_STATUS.queuedForNextInspect;
	unitCacheRecord.inspectTimestamp = 0;
	
	frameForDelayedInspection:AddQueuedInspectRequest(unitCacheRecord);
end

-- schedule a delayed inspect request
function frameForDelayedInspection:AddQueuedInspectRequest(unitCacheRecord)
	unitCacheQueuedForNextInspect:PushUniqueOnTop(unitCacheRecord);
	
	frameForDelayedInspection:Show();
end

-- remove queued inspect request
function frameForDelayedInspection:RemoveQueuedInspectRequest(unitCacheRecord)
	local itemsRemoved = unitCacheQueuedForNextInspect:Remove(unitCacheRecord);
	
	if (itemsRemoved > 0) then
		-- check if there are no more queued inspect requests available
		if (unitCacheQueuedForNextInspect:GetCount() == 0) then
			frameForDelayedInspection:Hide();
		end
	end
end

-- HOOK: frameForDelayedInspection's OnUpdate -- sends the inspect request after a delay
frameForDelayedInspection.NextNotifyInspectTimestamp = GetTime();

frameForDelayedInspection:SetScript("OnUpdate", function(self, elapsed)
	if (self.NextNotifyInspectTimestamp <= GetTime()) then
		-- send next queued inspect request
		local unitCacheRecord, unitID, unitIDForNotifyInspectFound;
		
		repeat
			unitCacheRecord = unitCacheQueuedForNextInspect:Pop();
			
			-- check if there are no more queued inspect requests available
			if (not unitCacheRecord) then
				self:Hide();
				return;
			end
			
			-- get unit id from unit guid and check if inspect is possible
			unitID = LibFroznFunctions:GetUnitIDFromGUID(unitCacheRecord.guid);
			unitIDForNotifyInspectFound = true;
			
			if (not unitID) then
				frameForDelayedInspection:FinishInspect(unitCacheRecord, true);
				unitIDForNotifyInspectFound = false;
			else
				unitCacheRecord.canInspect = LibFroznFunctions:CanInspect(unitID);
				
				if (not unitCacheRecord.canInspect) then
					frameForDelayedInspection:FinishInspect(unitCacheRecord, true);
					unitIDForNotifyInspectFound = false;
				end
			end
		until (unitIDForNotifyInspectFound);
		
		NotifyInspect(unitID);
		
		-- check if there are no more queued inspect requests available
		if (unitCacheQueuedForNextInspect:GetCount() == 0) then
			self:Hide();
		end
	end
end);

-- HOOK: NotifyInspect to monitor inspect requests
hooksecurefunc("NotifyInspect", function(unitID)
	-- set queued inspect request to inspect requests waiting for inspect data
	local unitGUID = UnitGUID(unitID);
	local unitCacheRecord = frameForDelayedInspection:GetUnitCacheRecord(unitID, unitGUID);
	
	if (unitCacheRecord) then
		unitCacheRecord.inspectStatus = LFF_INSPECT_STATUS.waitingForInspectData;
		unitCacheRecord.inspectTimestamp = GetTime();
		
		frameForDelayedInspection:RemoveQueuedInspectRequest(unitCacheRecord);
	end
	
	-- set timestamp for next inspect request
	frameForDelayedInspection.NextNotifyInspectTimestamp = GetTime() + LFF_INSPECT_TIMEOUT;
end);

-- EVENT: INSPECT_READY - inspect data available
function frameForDelayedInspection:INSPECT_READY(event, unitGUID)
	-- no unit guid
	if (not unitGUID) then
		return nil;
	end
	
	local unitID = LibFroznFunctions:GetUnitIDFromGUID(unitGUID);
	local unitCacheRecord = frameForDelayedInspection:GetUnitCacheRecord(unitID, unitGUID);
	
	if (unitCacheRecord) then
		self:InspectDataAvailable(unitID, unitCacheRecord);
	end
end

-- inspect data available
function frameForDelayedInspection:InspectDataAvailable(unitID, unitCacheRecord)
	if (not unitID) then
		frameForDelayedInspection:FinishInspect(unitCacheRecord, true);
		return;
	end
	
	unitCacheRecord.talents = LibFroznFunctions:GetTalents(unitID);
	unitCacheRecord.averageItemLevel = LibFroznFunctions:GetAverageItemLevel(unitID, function(averageItemLevel)
		unitCacheRecord.averageItemLevel = averageItemLevel;
		
		frameForDelayedInspection:FinishInspectDataAvailable(unitCacheRecord);
	end);
	
	frameForDelayedInspection:FinishInspectDataAvailable(unitCacheRecord);
end

-- finish inspect data available
function frameForDelayedInspection:FinishInspectDataAvailable(unitCacheRecord)
	-- check which data is set
	local numDataIsSet = 0;
	
	if (unitCacheRecord.talents ~= LFF_TALENTS.available) and (unitCacheRecord.talents ~= LFF_TALENTS.na) then
		numDataIsSet = numDataIsSet + 1;
	end
	if (unitCacheRecord.averageItemLevel ~= LFF_AVERAGE_ITEM_LEVEL.available) and (unitCacheRecord.averageItemLevel ~= LFF_AVERAGE_ITEM_LEVEL.na) then
		numDataIsSet = numDataIsSet + 1;
	end
	
	-- finish inspect data available
	if (numDataIsSet == 0) then
		frameForDelayedInspection:FinishInspect(unitCacheRecord, true, true);
	elseif (numDataIsSet < 2) then
		frameForDelayedInspection:FinishInspect(unitCacheRecord, false, true);
	else
		unitCacheRecord.timestamp = GetTime();
		
		frameForDelayedInspection:FinishInspect(unitCacheRecord);
	end
end

-- finish inspect
function frameForDelayedInspection:FinishInspect(unitCacheRecord, noInspectDataAvailable, noClearCallbacksForInspectData)
	-- send unit cache record to callbacks if inspect data is available
	if (not noInspectDataAvailable) then
		for _, callback in ipairs(unitCacheRecord.callbacks) do
			callback(unitCacheRecord);
		end
	end
	
	if (not noClearCallbacksForInspectData) then
		unitCacheRecord.callbacks:Clear();
	end
	
	-- finish inspect request
	unitCacheRecord.needsInspect = false;
	unitCacheRecord.inspectStatus = nil;
	unitCacheRecord.inspectTimestamp = 0;
	
	frameForDelayedInspection:RemoveQueuedInspectRequest(unitCacheRecord);
end

-- check if talents are available
--
-- @param  unitID  unit id for unit, e.g. "player", "target" or "mouseover"
-- @return returns "LFF_TALENTS.available" if talents are available.
--         returns "LFF_TALENTS.na" if no talents are available.
--         returns nil if unit id is missing or not a player
LFF_TALENTS = {
	available = 1, -- talents available
	na = 2, -- no talents available
	none = 3 -- no talents found
};

function LibFroznFunctions:AreTalentsAvailable(unitID)
	-- no unit id or not a player
	local isValidUnitID = (unitID) and (UnitIsPlayer(unitID));
	
	if (not isValidUnitID) then
		return nil;
	end
	
	 -- no need to display talent/specialization for players who hasn't yet gotten talent tabs or a specialization
	local unitLevel = UnitLevel(unitID);
	
	if (unitLevel < 10 and unitLevel ~= -1) then
		return LFF_TALENTS.na;
	end
	
	-- getting talents from other players isn't available in classic era
	if (not isSelf) and (LibFroznFunctions.isWoWFlavor.ClassicEra) then
		return LFF_TALENTS.na;
	end
	
	return LFF_TALENTS.available;
end

-- get talents
--
-- @param  unitID  unit id for unit, e.g. "player", "target" or "mouseover"
-- @return .name           talent/specialization name, e.g. "Elemental"
--         .iconFileID     talent/specialization icon file id, e.g. 135770
--         .role           role ("DAMAGER", "TANK" or "HEALER"
--         .pointsSpent[]  talent points spent, e.g. { 57, 14, 0 }. nil if no talent points spent has been found.
--         returns "LFF_TALENTS.none" if no talents have been found.
--         returns "LFF_TALENTS.na" if no talents are available.
--         returns nil if unit id is missing or not a player
function LibFroznFunctions:GetTalents(unitID)
	-- check if talents are available
	local areTalentsAvailable = LibFroznFunctions:AreTalentsAvailable(unitID);
	
	if (areTalentsAvailable ~= LFF_TALENTS.available) then
		return areTalentsAvailable;
	end
	
	-- get talents
	local talents = {};
	local isSelf = UnitIsUnit(unitID, "player");
	
	if (GetSpecialization) then -- retail
		local specializationName, specializationIcon, role;
		
		if (isSelf) then -- player
			local specIndex = GetSpecialization();
			
			if (not specIndex) then
				return LFF_TALENTS.none;
			end
			
			_, specializationName, _, specializationIcon, role = GetSpecializationInfo(specIndex);
		else -- inspecting
			local specializationID = GetInspectSpecialization(unitID);
			
			if (specializationID == 0) then
				return LFF_TALENTS.none;
			end
			
			_, specializationName, _, specializationIcon, role = GetSpecializationInfoByID(specializationID);
		end
		
		if (specializationName ~= "") then
			talents.name = specializationName;
		end
		
		talents.role = role;
		talents.iconFileID = specializationIcon;
		
		local pointsSpent = {};
		
		if (isSelf) and (C_SpecializationInfo.CanPlayerUseTalentSpecUI()) or (not isSelf) and (C_Traits.HasValidInspectData()) then
			local configID = (isSelf) and (C_ClassTalents.GetActiveConfigID()) or (not isSelf) and (Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID);
			
			if (configID) then
				local configInfo = C_Traits.GetConfigInfo(configID);
				
				if (configInfo) and (configInfo.treeIDs) then
					local treeID = configInfo.treeIDs[1];
					if (treeID) then
						local treeCurrencyInfo = C_Traits.GetTreeCurrencyInfo(configID, treeID, false);
						
						if (treeCurrencyInfo) then
							for _, treeCurrencyInfoItem in ipairs(treeCurrencyInfo) do
								if (treeCurrencyInfoItem.spent) then
									pointsSpent[#pointsSpent + 1] = treeCurrencyInfoItem.spent;
								end
							end
						end
					end
				end
			end
		end
		
		if (#pointsSpent > 0) then
			talents.pointsSpent = pointsSpent;
		end
	else -- classic
		-- inspect functions will always use the active spec when not inspecting
		local activeTalentGroup = GetActiveTalentGroup and GetActiveTalentGroup(not isSelf);
		local numTalentTabs = GetNumTalentTabs(not isSelf);
		
		if (not numTalentTabs) then
			return LFF_TALENTS.none;
		end
		
		local talentTabName, talentTabIcon;
		local pointsSpent = {};
		local maxPointsSpent;
		
		for tabIndex = 1, numTalentTabs do
			_talentTabName, _talentTabIcon, _pointsSpent = GetTalentTabInfo(tabIndex, not isSelf, nil, activeTalentGroup);
			pointsSpent[#pointsSpent + 1] = _pointsSpent;
			
			if (not maxPointsSpent) or (_pointsSpent > maxPointsSpent) then
				maxPointsSpent = _pointsSpent;
				talentTabName, talentTabIcon = _talentTabName, _talentTabIcon;
			end
		end
		
		if (talentTabName ~= "") then
			talents.name = talentTabName;
		end
		
		talents.iconFileID = talentTabIcon;
		
		if (#pointsSpent > 0) then
			talents.pointsSpent = pointsSpent;
		end
	end
	
	return talents;
end

-- check if average item level is available
--
-- @param  unitID  unit id for unit, e.g. "player", "target" or "mouseover"
-- @return returns "LFF_AVERAGE_ITEM_LEVEL.available" if average item level is available.
--         returns "LFF_AVERAGE_ITEM_LEVEL.na" if no average item level is available.
--         returns nil if unit id is missing or not a player
LFF_AVERAGE_ITEM_LEVEL = {
	available = 1, -- average item level available
	na = 2, -- no average item level available
	none = 3 -- no average item level found
};

function LibFroznFunctions:IsAverageItemLevelAvailable(unitID)
	-- no unit id or not a player
	local isValidUnitID = (unitID) and (UnitIsPlayer(unitID));
	
	if (not isValidUnitID) then
		return nil;
	end
	
	 -- consider minimum player level to display average item level, see MIN_PLAYER_LEVEL_FOR_ITEM_LEVEL_DISPLAY in "PaperDollFrame.lua"
	local unitLevel = UnitLevel(unitID);
	
	if (unitLevel < 10 and unitLevel ~= -1) then
		return LFF_AVERAGE_ITEM_LEVEL.na;
	end
	
	return LFF_AVERAGE_ITEM_LEVEL.available;
end

-- get average item level
--
-- @param  unitID                    unit id for unit, e.g. "player", "target" or "mouseover"
-- @param  callbackForInspectData()  callback function if all item data is available. parameters: unitCacheRecord
-- @return .value         average item level
--         .qualityColor  ColorMixin with total quality color
--         .totalItems    total items
--         returns "LFF_AVERAGE_ITEM_LEVEL.available" if average item level is available
--         returns "LFF_AVERAGE_ITEM_LEVEL.none" if no average item level has been found.
--         returns nil if unit id is missing or not a player
function LibFroznFunctions:GetAverageItemLevel(unitID, callbackForItemData)
	-- check if average item level is available
	local isAverageItemLevelAvailable = LibFroznFunctions:IsAverageItemLevelAvailable(unitID);
	
	if (isAverageItemLevelAvailable ~= LFF_AVERAGE_ITEM_LEVEL.available) then
		return isAverageItemLevelAvailable;
	end
	
	-- check if item data for all items is available and queried from server
	local itemCountWaitingForData = 0;
	local unitGUID = UnitGUID(unitID);
	
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemID = GetInventoryItemID(unitID, i);
		
		if (itemID) then
			local item = Item:CreateFromItemID(itemID);
			
			if (not item:IsItemEmpty()) and (not item:IsItemDataCached()) then
				itemCountWaitingForData = itemCountWaitingForData + 1;
				
				item:ContinueOnItemLoad(function()
					itemCountWaitingForData = itemCountWaitingForData - 1;
					
					if (itemCountWaitingForData == 0) then
						LFF_GetAverageItemLevelFromItemData(unitID, callbackForItemData, unitGUID);
					end
				end);
			end
		end
	end
	
	if (itemCountWaitingForData > 0) then
		return LFF_AVERAGE_ITEM_LEVEL.available;
	end
	
	-- item data for all items is already available
	return LFF_GetAverageItemLevelFromItemData(unitID);
end

-- get average item level from item data
function LFF_GetAverageItemLevelFromItemData(unitID, callbackForItemData, unitGUID)
	-- check if unit guid from unit id is still the same if waiting for item data
	if (callbackForItemData) and (unitGUID) then
		local _unitGUID = UnitGUID(unitID);
		
		if (_unitGUID ~= unitGUID) then
			return nil;
		end
	end
	
	-- get items
	local items = {};
	local itemCount = 0;
	
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local itemLink = GetInventoryItemLink(unitID, i);
		
		if (itemLink) then
			local item = Item:CreateFromItemLink(itemLink);
			
			if (not item:IsItemEmpty()) then
				local effectiveILvl = item:GetCurrentItemLevel();
				local quality = item:GetItemQuality();
				local inventoryType = item:GetInventoryType();
				
				items[i] = {
					effectiveILvl = effectiveILvl or 0,
					quality = quality or 0,
					inventoryType = inventoryType
				};
				
				itemCount = itemCount + 1;
			end
		end
	end
	
	if (itemCount == 0) then
		if (callbackForItemData) then
			callbackForItemData(LFF_AVERAGE_ITEM_LEVEL.none);
		end
		
		return LFF_AVERAGE_ITEM_LEVEL.none;
	end
	
	-- calculate average item level
	local totalScore = 0;
	local totalItems = 0;
	local totalQuality = 0;
	local totalItemsForQuality = 0;
	local averageItemLevel;
	local totalQualityColor;
	
	local ignoreInventorySlots = {
		[INVSLOT_BODY] = true, -- shirt
		[INVSLOT_TABARD] = true, -- tabard
		[INVSLOT_RANGED] = true -- ranged
	};
	
	local twoHandedInventoryTypes = {
		[Enum.InventoryType.IndexRangedType] = true,
		[Enum.InventoryType.IndexRangedrightType] = true,
		[Enum.InventoryType.Index2HweaponType] = true
	};
	
	-- to check if main hand only
	local itemMainHand = items[INVSLOT_MAINHAND];
	local itemOffHand = items[INVSLOT_OFFHAND];
	
	local isMainHandOnly = (itemMainHand) and (not itemOffHand);
	
	-- to check if main or off hand are artifacts
	local isMainHandArtifact = (itemMainHand) and (itemMainHand.quality == Enum.ItemQuality.Artifact);
	local itemMainHandEffectiveILvl = (itemMainHand) and (itemMainHand.effectiveILvl);
	
	local isOffHandArtifact = (itemOffHand) and (itemOffHand.quality == Enum.ItemQuality.Artifact);
	local itemOffHandEffectiveILvl = (itemOffHand) and (itemOffHand.effectiveILvl);
	
	-- calculate average item level
	for i, item in pairs(items) do
		-- map Heirloom and WoWToken to Rare
		local quality = item.quality;
		
		if (quality == 7) or (quality == 8) then
			quality = 3;
		end
		
		if (not ignoreInventorySlots[i]) then -- ignore shirt, tabard and ranged
			totalItems = totalItems + 1;
			
			if (i == INVSLOT_MAINHAND) or (i == INVSLOT_OFFHAND) then -- handle main and off hand
				if (isMainHandOnly) then -- main hand only
					if (twoHandedInventoryTypes[item.inventoryType]) then -- two handed
						totalItems = totalItems + 1;
						totalScore = totalScore + item.effectiveILvl * 2;
					else -- one handed
						totalScore = totalScore + item.effectiveILvl;
					end
				else -- main and/or off hand
					if (isMainHandArtifact) or (isOffHandArtifact) then -- main or off hand is artifact
						if (itemMainHandEffectiveILvl > itemOffHandEffectiveILvl) then
							totalScore = totalScore + itemMainHandEffectiveILvl;
						else
							totalScore = totalScore + itemOffHandEffectiveILvl;
						end
					else -- main and off hand are non-artifacts
						totalScore = totalScore + item.effectiveILvl;
					end
				end
			else -- other items
				totalScore = totalScore + item.effectiveILvl;
			end
			
			totalItemsForQuality = totalItemsForQuality + 1;
			totalQuality = totalQuality + quality;
		end
	end
	
	if (totalItems == 0) then
		if (callbackForItemData) then
			callbackForItemData(LFF_AVERAGE_ITEM_LEVEL.none);
		end

		return LFF_AVERAGE_ITEM_LEVEL.none;
	end
	
	-- set average item level and total quality color
	local isSelf = UnitIsUnit(unitID, "player");
	
	if (isSelf) and (GetAverageItemLevel) then
		local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel();
		
		averageItemLevel = floor(avgItemLevelEquipped);
		
		if (GetItemLevelColor) then
			totalQualityColor = LibFroznFunctions:CreateColorSmart(GetItemLevelColor());
		end
	elseif (C_PaperDollInfo) and (C_PaperDollInfo.GetInspectItemLevel) then
		averageItemLevel = C_PaperDollInfo.GetInspectItemLevel(unitID);
	end
	
	if (not averageItemLevel) or (averageItemLevel == 0) then
		averageItemLevel = floor(totalScore / 16);
	end
	
	if (not totalQualityColor) then
		totalQualityColor = LibFroznFunctions:GetItemQualityColor(floor(totalQuality / totalItemsForQuality + 0.5), Enum.ItemQuality.Common);
	end
	
	local returnAverageItemLevel = {
		value = averageItemLevel,
		qualityColor = totalQualityColor,
		totalItems = totalItemsForQuality
	};
	
	if (callbackForItemData) then
		callbackForItemData(returnAverageItemLevel);
	end
	
	return returnAverageItemLevel;
end
