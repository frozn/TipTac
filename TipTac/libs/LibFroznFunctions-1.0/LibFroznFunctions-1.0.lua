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
local LIB_MINOR = 15; -- bump on changes

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
--                                           Table API                                            --
----------------------------------------------------------------------------------------------------

LibFroznFunctions.TableRegistry = LibFroznFunctions.TableRegistry or {};

-- register table version
--
-- @param name     table name
-- @param version  table version
function LibFroznFunctions:RegisterTableVersion(name, version)
	local oldVersion = LibFroznFunctions.TableRegistry[name];
	
	if (oldVersion) and (oldVersion >= version) then
		return;
	end
	
	LibFroznFunctions.TableRegistry[name] = version;
end

-- get table version
--
-- @param name  table name
function LibFroznFunctions:GetTableVersion(name)
	return LibFroznFunctions.TableRegistry[name];
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

-- get addon metadata
--
-- @param  indexOrName  index in the addon list (cannot query Blizzard addons by index) or name of the addon (case insensitive)
-- @param  field        field name (case insensitive), e.g. "Title", "Version" or "Notes"
-- @return value of the field in TOC metadata of an addon
function LibFroznFunctions:GetAddOnMetadata(indexOrName, field)
	-- since df 10.1.0
	if (C_AddOns) and (C_AddOns.GetAddOnMetadata) then
		return C_AddOns.GetAddOnMetadata(indexOrName, field);
	end
	
	-- before df 10.1.0
	return GetAddOnMetadata(indexOrName, field);
end

-- aura filters, see "AuraUtil.lua"
LFF_AURA_FILTERS = (AuraUtil) and (AuraUtil.AuraFilters) or {
	Helpful = "HELPFUL",
	Harmful = "HARMFUL",
	Raid = "RAID",
	IncludeNameplateOnly = "INCLUDE_NAME_PLATE_ONLY",
	Player = "PLAYER",
	Cancelable = "CANCELABLE",
	NotCancelable = "NOT_CANCELABLE",
	Maw = "MAW",
};

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

-- get global string
--
-- @param  str  name of localized global string constant
-- @return localized global string constant, false/nil otherwise.
function LibFroznFunctions:GetGlobalString(str)
	if (_G[str]) then
		return _G[str];
	end
	
	-- fallback if global string doesn't exist in classic
	local locale = GetLocale();
	
	return LFF_GLOBAL_STRINGS[locale] and LFF_GLOBAL_STRINGS[locale][str];
end

-- get unit from tooltip
--
-- @param  tooltip  tooltip
-- @return name, unit id[, unit guid]
function LibFroznFunctions:GetUnitFromTooltip(tooltip)
	-- since df 10.0.2
	if (TooltipUtil) then
		return TooltipUtil.GetDisplayedUnit(tooltip);
	end
	
	-- before df 10.0.2
	return tooltip:GetUnit();
end

-- hook tooltip's OnTooltipSetUnit
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetUnit(tip, callback)
	-- since df 10.0.2
	if (TooltipDataProcessor) then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
		
		return;
	end
	
	-- before df 10.0.2
	tip:HookScript("OnTooltipSetUnit", callback);
end

-- get item from tooltip
--
-- @param  tooltip  tooltip
-- @return itemName, itemLink[, item id]
function LibFroznFunctions:GetItemFromTooltip(tooltip)
	-- since df 10.0.2
	if (TooltipUtil) then
		if (tooltip:IsTooltipType(Enum.TooltipDataType.Toy)) then -- see TooltipUtil.GetDisplayedItem() in "TooltipUtil.lua"
			local tooltipData = tooltip:GetTooltipData();
			local itemLink = C_ToyBox.GetToyLink(tooltipData.id);
			if (itemLink) then
				local name = GetItemInfo(itemLink);
				return name, itemLink, tooltipData.id;
			end
		end
		
		return TooltipUtil.GetDisplayedItem(tooltip);
	end
	
	-- before df 10.0.2
	return tooltip:GetItem();
end

-- hook tooltip's OnTooltipSetItem
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetItem(tip, callback)
	-- since df 10.0.2
	if (TooltipDataProcessor) then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
		
		return;
	end
	
	-- before df 10.0.2
	tip:HookScript("OnTooltipSetItem", callback);
end

-- get spell from tooltip
--
-- @param  tooltip  tooltip
-- @return spellName, spellID
function LibFroznFunctions:GetSpellFromTooltip(tooltip)
	-- since df 10.0.2
	if (TooltipUtil) then
		return TooltipUtil.GetDisplayedSpell(tooltip);
	end
	
	-- before df 10.0.2
	return tooltip:GetSpell();
end

-- hook tooltip's OnTooltipSetSpell
--
-- @param tip       tooltip
-- @param callback  callback function. parameters: self, ... (additional payload)
function LibFroznFunctions:HookScriptOnTooltipSetSpell(tip, callback)
	-- since df 10.0.2
	if (TooltipDataProcessor) then
		TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(self, ...)
			if (self == tip) then
				callback(self, ...);
			end
		end);
		
		return;
	end
	
	-- before df 10.0.2
	tip:HookScript("OnTooltipSetSpell", callback);
end

-- get mount from tooltip
--
-- @param  tooltip  tooltip
-- @return mountName, mountID
function LibFroznFunctions:GetMountFromTooltip(tooltip)
	-- since df 10.0.2
	if (TooltipUtil) then
		if tooltip:IsTooltipType(Enum.TooltipDataType.Mount) then -- see TooltipUtil.GetDisplayedSpell() in "TooltipUtil.lua"
			local tooltipData = tooltip:GetTooltipData();
			local id = tooltipData.id;
			local name = C_MountJournal.GetMountInfoByID(id);
			return name, id;
		end
		
		return;
	end
	
	-- before df 10.0.2
	local spellName, spellID = tooltip:GetSpell();
	local mountID = LibFroznFunctions:GetMountFromSpell(spellID);
	
	return spellName, mountID;
end

-- get mount from spell
--
-- @param  spellID  spell id
-- @return mountID  mount id
--         returns 0 if the spell/aura is from a mount, but there is not specific mount, e.g. "Running Wild" for worgen.
--         returns nil if spell/aura doesn't belong to a mount.
function LibFroznFunctions:GetMountFromSpell(spellID)
	-- since BfA 8.0.1
	if (C_MountJournal) and (C_MountJournal.GetMountFromSpell) then
		return C_MountJournal.GetMountFromSpell(spellID) or LFF_SPELLID_TO_MOUNTID_LOOKUP[tonumber(spellID)]; -- also check LFF_SPELLID_TO_MOUNTID_LOOKUP, because some mounted auras doesn't belong to a mount, e.g. "Running Wild" for worgen
	end
	
	-- before BfA 8.0.1
	return LFF_SPELLID_TO_MOUNTID_LOOKUP[tonumber(spellID)];
end

-- get mount from item
--
-- @param  itemID  item id
-- @return mountID  mount id
--         returns 0 if the spell/aura is from a mount, but there is not specific mount, e.g. "Running Wild" for worgen.
--         returns nil if spell/aura doesn't belong to a mount.
function LibFroznFunctions:GetMountFromItem(itemID)
	-- since BfA 8.1.0
	if (C_MountJournal) and (C_MountJournal.GetMountFromItem) then
		return C_MountJournal.GetMountFromItem(itemID) or LFF_ITEMID_TO_MOUNTID_LOOKUP[tonumber(itemID)]; -- also check LFF_ITEMID_TO_MOUNTID_LOOKUP, because some mount items doesn't belong to a mount, e.g. "Clutch of Ha-Li" (ItemID 173887)
	end
	
	-- before BfA 8.1.0
	return LFF_ITEMID_TO_MOUNTID_LOOKUP[tonumber(itemID)];
end

-- check if mount is collected
--
-- @param  mountID  mount id
-- @return true if mount is collected, false otherwise. returns nil if it can't be determined if the mount is collected.
function LibFroznFunctions:IsMountCollected(mountID)
	-- since Legion 7.0.3
	if (C_MountJournal) and (C_MountJournal.GetMountInfoByID) then
		return select(11, C_MountJournal.GetMountInfoByID(mountID));
	end
	
	-- before Legion 7.0.3
	if (GetNumCompanions) then
		local numCompanionsOfMount = GetNumCompanions("MOUNT");
		
		if (numCompanionsOfMount) then -- function exists in classic era since 1.14.4 but returns nil
			for index = 1, numCompanionsOfMount do
				local creatureID = GetCompanionInfo("MOUNT", index);
				
				if (creatureID == mountID) then
					return true;
				end
			end
			
			return false;
		end
	end
	
	-- before WotLK 3.0.2
	if (C_Container) and (C_Container.GetContainerNumSlots) then
		local lastBankBagSlot = ITEM_INVENTORY_BANK_BAG_OFFSET + NUM_BANKBAGSLOTS;
		local firstReagentBagSlot, lastReagentBagSlot = NUM_BAG_SLOTS + 1, ITEM_INVENTORY_BANK_BAG_OFFSET;
		
		for bagID = BANK_CONTAINER, lastBankBagSlot do
			if (bagID <= firstReagentBagSlot) or (bagID >= lastReagentBagSlot) then -- ignore reagent bags
				local numSlots = C_Container.GetContainerNumSlots(bagID);
				
				for slotIndex = 1, numSlots do
					local itemLink = C_Container.GetContainerItemLink(bagID, slotIndex);
					
					if (itemLink) then
						local linkType, itemID = itemLink:match("H?(%a+):(%d+)");
						
						if (itemID) then
							local mountIDFromItem = LibFroznFunctions:GetMountFromItem(itemID);
							
							if (mountIDFromItem == mountID) then
								return true;
							end
						end
					end
				end
			end
		end
		
		return false;
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
		return;
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
				return;
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
		return;
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
			return;
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
--                                       Interface Options                                        --
----------------------------------------------------------------------------------------------------

-- register addon category
--
-- @param frame               frame with options
-- @param categoryName        name of category
-- @param parentCategoryName  optional. name of parent category
function LibFroznFunctions:RegisterAddOnCategory(frame, categoryName, parentCategoryName)
	-- since df 10.0.0 and wotlkc 3.4.2
	if (Settings) and (Settings.RegisterAddOnCategory) then -- see "\SharedXML\Settings\Blizzard_Deprecated.lua" for df 10.0.0
		-- cancel is no longer a default option. may add menu extension for this.
		frame.OnCommit = frame.okay;
		frame.OnDefault = frame.default;
		frame.OnRefresh = frame.refresh;
		
		if (parentCategoryName) then
			local category = Settings.GetCategory(parentCategoryName);
			local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(category, frame, categoryName, categoryName);
			subcategory.ID = categoryName;
		else
			local category, layout = Settings.RegisterCanvasLayoutCategory(frame, categoryName, categoryName);
			category.ID = categoryName;
			
			Settings.RegisterAddOnCategory(category);
		end
		
		return;
	end
	
	-- before df 10.0.0
	frame.name = categoryName;
	frame.parent = parentCategoryName;
	
	InterfaceOptions_AddCategory(frame);
end

-- open addon category
--
-- @param categoryName     name of category
-- @param subcategoryName  name of subcategory
function LibFroznFunctions:OpenAddOnCategory(categoryName, subcategoryName)
	-- since df 10.0.0 and wotlkc 3.4.2
	if (Settings) and (Settings.OpenToCategory) then
		for index, tbl in ipairs(SettingsPanel:GetCategoryList().groups) do -- see SettingsPanelMixin:OpenToCategory() in "Blizzard_SettingsPanel.lua"
			for index, category in ipairs(tbl.categories) do
				if (category:GetName() == categoryName) then
					Settings.OpenToCategory(category:GetID(), category:GetName());
					
					if (subcategoryName) then
						for index, subcategory in ipairs(category:GetSubcategories()) do
							if (subcategory:GetName() == subcategoryName) then
								SettingsPanel:SelectCategory(subcategory);
								return;
							end
						end
					end
					
					return;
				end
			end
		end
		
		return;
	end
	
	-- before df 10.0.0
	if (not InterfaceOptionsFrame:IsShown()) then
		InterfaceOptionsFrame_Show();
	end
	
	InterfaceOptionsFrame_OpenToCategory(categoryName);
	
	if (subcategoryName) then
		InterfaceOptionsFrame_OpenToCategory(subcategoryName);
	end
end

-- expand addon category
--
-- @param categoryName  name of category
function LibFroznFunctions:ExpandAddOnCategory(categoryName)
	-- since df 10.0.0 and wotlkc 3.4.2
	if (Settings) and (Settings.CreateCategories) then
		for index, tbl in ipairs(SettingsPanel:GetCategoryList().groups) do -- see SettingsPanelMixin:OpenToCategory() in "Blizzard_SettingsPanel.lua"
			for index, category in ipairs(tbl.categories) do
				if (category:GetName() == categoryName) then
					if (not category.expanded) then
						category.expanded = true;
						SettingsPanel:GetCategoryList():CreateCategories();
					end
					
					return;
				end
			end
		end
		
		return;
	end
	
	-- before df 10.0.0
	local function SecureNext(elements, key)
		return securecall(next, elements, key);
	end
	
	local elementToDisplay; -- see InterfaceOptionsFrame_OpenToCategory() in "InterfaceOptionsFrame.lua"
	
	for i, element in SecureNext, INTERFACEOPTIONS_ADDONCATEGORIES do
		if (categoryName) and (element.name) and (element.name == categoryName) then
			elementToDisplay = element;
			break;
		end
	end
	
	if (not elementToDisplay) then
		return;
	end
	
	local buttons = InterfaceOptionsFrameAddOns.buttons;
	
	for i, button in SecureNext, buttons do
		if (elementToDisplay.name) and (button.element) and ((button.element.name == elementToDisplay.name) and (button.element.collapsed)) then
			OptionsListButtonToggle_OnClick(button.toggle);
		end
	end
end

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
		return;
	end
	
	local hexA, hexR, hexG, hexB = colorDefinition:gsub("|c", ""):match("(%2x)(%2x)(%2x)(%2x)");
	
	return hexA and CreateColorFromBytes(tonumber("0x" .. hexR), tonumber("0x" .. hexG), tonumber("0x" .. hexB), tonumber("0x" .. hexA));
end

-- get class color
--
-- @param  classID                     class id of unit
-- @param  alternateClassIDIfNotFound  alternate class id if color for param "classID" doesn't exist
-- @return ColorMixin  returns nil if class file for param "classID" and "alternateClassIDIfNotFound" doesn't exist.
local function getClassColor(classFile)
	local classColor; -- see "ColorUtil.lua"
	
	if (CUSTOM_CLASS_COLORS) then
		-- custom class color
		classColor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFile];
		
		if (classColor) then
			-- make shure that ColorMixin methods are available
			if (classColor) and (type(classColor.WrapTextInColorCode) ~= "function") then
				LibFroznFunctions:MixinDifferingObjects(classColor, ColorMixin);
			end
		else
			-- fallback to default class color
			classColor = RAID_CLASS_COLORS[classFile];
		end
	else
		-- default class color
		classColor = RAID_CLASS_COLORS[classFile];
	end
	
	return classColor;
end

function LibFroznFunctions:GetClassColor(classID, alternateClassIDIfNotFound)
	local classInfo = (classID and C_CreatureInfo.GetClassInfo(classID)) or (alternateClassIDIfNotFound and C_CreatureInfo.GetClassInfo(alternateClassIDIfNotFound));
	
	return classInfo and getClassColor(classInfo.classFile);
end

-- get class color by class file
--
-- @param  classFile                     locale-independent class file of unit, e.g. "WARRIOR"
-- @param  alternateClassFileIfNotFound  alternate class file if color for param "classFile" doesn't exist
-- @return ColorMixin  returns nil if class file for param "classFile" and "alternateClassFileIfNotFound" doesn't exist.
function LibFroznFunctions:GetClassColorByClassFile(classFile, alternateClassFileIfNotFound)
	return getClassColor(classFile) or getClassColor(alternateClassFileIfNotFound);
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
		return;
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
		return;
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
		return;
	end
end

-- create markup for class icon
--
-- @param  classIcon  file id/path for class icon
-- @return markup for class icon to use in text. returns nil if class icon is invalid.
function LibFroznFunctions:CreateMarkupForClassIcon(classIcon)
	-- invalid class icon
	if (type(classIcon) ~= "number") and (type(classIcon) ~= "string") then
		return;
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
-- @param  anchorPoint     anchor point, e.g. "TOP" or "BOTTOMRIGHT"
-- @param  anchorFrame     anchor frame
-- @param  targetFrame     target frame
-- @param  frameReference  reference frame
-- @return left offset, right offset. nil, nil if no valid anchor point is supplied.
function LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, anchorFrame, targetFrame, referenceFrame)
	local effectiveScaleAnchorFrame = anchorFrame:GetEffectiveScale();
	local effectiveScaleTargetFrame = targetFrame:GetEffectiveScale();
	local effectiveScaleReferenceFrame = referenceFrame:GetEffectiveScale();
	local UIScale = UIParent:GetEffectiveScale();
	
	local totalEffectiveScaleAnchorFrame = effectiveScaleAnchorFrame / UIScale;
	local totalEffectiveScaleTargetFrame = effectiveScaleTargetFrame / UIScale;
	local totalEffectiveScaleReferenceFrame = effectiveScaleReferenceFrame / UIScale;
	
	if (anchorPoint == "TOPLEFT") then
		return ((anchorFrame:GetLeft() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetLeft() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetTop() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetTop() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "TOPRIGHT") then
		return ((anchorFrame:GetRight() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetRight() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetTop() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetTop() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOMLEFT") then
		return ((anchorFrame:GetLeft() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetLeft() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetBottom() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetBottom() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOMRIGHT") then
		return ((anchorFrame:GetRight() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetRight() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetBottom() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetBottom() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "TOP") then
		return ((((anchorFrame:GetLeft() + anchorFrame:GetRight()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetLeft() + referenceFrame:GetRight()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetTop() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetTop() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "BOTTOM") then
		return ((((anchorFrame:GetLeft() + anchorFrame:GetRight()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetLeft() + referenceFrame:GetRight()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame, ((anchorFrame:GetBottom() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetBottom() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "LEFT") then
		return ((anchorFrame:GetLeft() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetLeft() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((((anchorFrame:GetTop() + anchorFrame:GetBottom()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetTop() + referenceFrame:GetBottom()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "RIGHT") then
		return ((anchorFrame:GetRight() * totalEffectiveScaleAnchorFrame) - (referenceFrame:GetRight() * totalEffectiveScaleReferenceFrame)) / totalEffectiveScaleTargetFrame, ((((anchorFrame:GetTop() + anchorFrame:GetBottom()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetTop() + referenceFrame:GetBottom()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame;
	end
	if (anchorPoint == "CENTER") then
		return ((((anchorFrame:GetLeft() + anchorFrame:GetRight()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetLeft() + referenceFrame:GetRight()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame, ((((anchorFrame:GetTop() + anchorFrame:GetBottom()) * totalEffectiveScaleAnchorFrame) - ((referenceFrame:GetTop() + referenceFrame:GetBottom()) * totalEffectiveScaleReferenceFrame)) / 2) / totalEffectiveScaleTargetFrame;
	end
	
	return nil, nil;
end

-- refresh anchor shopping tooltips
--
-- modded copy of TooltipComparisonManager:AnchorShoppingTooltips() in "TooltipComparisonManager.lua" (since df 10.0.2) aka GameTooltip_AnchorComparisonTooltips in "GameTooltip.lua" (before df 10.0.2) for:
-- 1. consider scaling to choose left or right side
-- 2. calling ClearAllPoints() to refresh anchoring of shopping tooltips after re-anchoring of tip
function LibFroznFunctions:RefreshAnchorShoppingTooltips(tip)
	local primaryTooltip = ShoppingTooltip1;
	local secondaryTooltip = ShoppingTooltip2;
	
	local primaryShown = primaryTooltip:IsShown();
	local secondaryShown = secondaryTooltip:IsShown();
	
	-- no shopping tooltip visible
	if (not primaryShown) and (not secondaryShown) then
		return;
	end
	
	-- refresh anchor of shopping tooltips
	local self;
	
	if (TooltipComparisonManager) then -- since df 10.0.2
		self = TooltipComparisonManager;
	else -- before df 10.0.2
		local primaryTooltipPoint1 = (primaryTooltip:GetNumPoints() >= 1) and select(2, primaryTooltip:GetPoint(1));
		local secondaryTooltipPoint1 = (secondaryTooltip:GetNumPoints() >= 1) and select(2, secondaryTooltip:GetPoint(1));
		
		self = { 
			tooltip = primaryTooltip:GetOwner(),
			anchorFrame = (primaryTooltipPoint1 ~= secondaryTooltip) and primaryTooltipPoint1 or (primaryTooltipPoint1 == secondaryTooltip) and secondaryTooltipPoint1 or primaryTooltip:GetOwner(),
			comparisonItem = (primaryTooltip:IsShown())
		};
	end
	
	-- not the affected tip or no comparison item
	if (self.tooltip ~= tip) or (not self.comparisonItem) then
		return;
	end
	
	-- start of original TooltipComparisonManager:AnchorShoppingTooltips()
	local tooltip = self.tooltip;
	-- local primaryTooltip = tooltip.shoppingTooltips[1]; -- removed
	-- local secondaryTooltip = tooltip.shoppingTooltips[2]; -- removed
	
	local sideAnchorFrame = self.anchorFrame;
	if self.anchorFrame.IsEmbedded then
		sideAnchorFrame = self.anchorFrame:GetParent():GetParent();
	end
	
	-- local leftPos = sideAnchorFrame:GetLeft(); -- removed
	-- local rightPos = sideAnchorFrame:GetRight(); -- removed
	local leftPos = (sideAnchorFrame:GetLeft() ~= nil) and (sideAnchorFrame:GetLeft() * sideAnchorFrame:GetEffectiveScale()); -- added
	local rightPos = (sideAnchorFrame:GetRight() ~= nil) and (sideAnchorFrame:GetRight() * sideAnchorFrame:GetEffectiveScale()); -- added
	
	-- local selfLeftPos = tooltip:GetLeft(); -- removed
	-- local selfRightPos = tooltip:GetRight(); -- removed
	local selfLeftPos = (tooltip:GetLeft() ~= nil) and (tooltip:GetLeft() * tooltip:GetEffectiveScale()); -- added
	local selfRightPos = (tooltip:GetRight() ~= nil) and (tooltip:GetRight() * tooltip:GetEffectiveScale()); -- added
	
	-- if we get the Left, we have the Right
	if leftPos and selfLeftPos then
		leftPos = math.min(selfLeftPos, leftPos);-- get the left most bound
		rightPos = math.max(selfRightPos, rightPos);-- get the right most bound
	else
		leftPos = leftPos or selfLeftPos or 0;
		rightPos = rightPos or selfRightPos or 0;
	end
	
	-- sometimes the sideAnchorFrame is an actual tooltip, and sometimes it's a script region, so make sure we're getting the actual anchor type
	local anchorType = sideAnchorFrame.GetAnchorType and sideAnchorFrame:GetAnchorType() or tooltip:GetAnchorType();
	
	local totalWidth = 0;
	if primaryShown then
		totalWidth = totalWidth + primaryTooltip:GetWidth() * primaryTooltip:GetEffectiveScale();
	end
	if secondaryShown then
		totalWidth = totalWidth + secondaryTooltip:GetWidth() * primaryTooltip:GetEffectiveScale();
	end
	
	local rightDist = 0;
	-- local screenWidth = GetScreenWidth(); -- removed
	local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale(); -- added
	rightDist = screenWidth - rightPos;
	
	-- find correct side
	local side;
	if anchorType and (totalWidth < leftPos) and (anchorType == "ANCHOR_LEFT" or anchorType == "ANCHOR_TOPLEFT" or anchorType == "ANCHOR_BOTTOMLEFT") then
		side = "left";
	elseif anchorType and (totalWidth < rightDist) and (anchorType == "ANCHOR_RIGHT" or anchorType == "ANCHOR_TOPRIGHT" or anchorType == "ANCHOR_BOTTOMRIGHT") then
		side = "right";
	elseif rightDist < leftPos then
		side = "left";
	else
		side = "right";
	end
	
	-- see if we should slide the tooltip
	if totalWidth > 0 and (anchorType and anchorType ~= "ANCHOR_PRESERVE") then --we never slide a tooltip with a preserved anchor
		local slideAmount = 0;
		if ( (side == "left") and (totalWidth > leftPos) ) then
			slideAmount = totalWidth - leftPos;
		elseif ( (side == "right") and (rightPos + totalWidth) >  screenWidth ) then
			slideAmount = screenWidth - (rightPos + totalWidth);
		end

		if slideAmount ~= 0 then -- if we calculated a slideAmount, we need to slide
			if sideAnchorFrame.SetAnchorType then
				sideAnchorFrame:SetAnchorType(anchorType, slideAmount, 0);
			else
				tooltip:SetAnchorType(anchorType, slideAmount, 0);
			end
		end
	end
	
	primaryTooltip:ClearAllPoints(); -- added
	
	if secondaryShown then
		secondaryTooltip:ClearAllPoints(); -- added
		
		primaryTooltip:SetPoint("TOP", self.anchorFrame, 0, -10);
		secondaryTooltip:SetPoint("TOP", self.anchorFrame, 0, -10);
		if side and side == "left" then
			primaryTooltip:SetPoint("RIGHT", sideAnchorFrame, "LEFT");
		else
			secondaryTooltip:SetPoint("LEFT", sideAnchorFrame, "RIGHT");
		end
		
		if side and side == "left" then
			secondaryTooltip:SetPoint("TOPRIGHT", primaryTooltip, "TOPLEFT");
		else
			primaryTooltip:SetPoint("TOPLEFT", secondaryTooltip, "TOPRIGHT");
		end
	else
		primaryTooltip:SetPoint("TOP", self.anchorFrame, 0, -10);
		if side and side == "left" then
			primaryTooltip:SetPoint("RIGHT", sideAnchorFrame, "LEFT");
		else
			primaryTooltip:SetPoint("LEFT", sideAnchorFrame, "RIGHT");
		end
	end
	
	-- primaryTooltip:SetShown(primaryShown); -- removed
	-- secondaryTooltip:SetShown(secondaryShown); -- removed
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

----------------------------------------------------------------------------------------------------
--                                            Tooltips                                            --
----------------------------------------------------------------------------------------------------

-- recalculate size of GameTooltip
--
-- @param tip  GameTooltip
function LibFroznFunctions:RecalculateSizeOfGameTooltip(tip)
	if (type(tip.GetObjectType) ~= "function") or (tip:GetObjectType() ~= "GameTooltip") then
		return;
	end
	
	tip:SetPadding(tip:GetPadding());
end

-- get aura description
--
-- @param  unitID                 unit id, e.g. "player", "target" or "mouseover"
-- @param  index                  index of an aura to query
-- @param  filter                 a list of filters, separated by pipe chars or spaces, see LFF_AURA_FILTERS
-- @param  callbackForAuraData()  callback function if aura data is available. parameters: auraDescription
-- @return aura description
--         returns "LFF_AURA_DESCRIPTION.available" if aura description is available.
--         returns "LFF_AURA_DESCRIPTION.none" if no aura description has been found.
--         returns nil if spell id can't be determined from aura
LFF_AURA_DESCRIPTION = {
	available = 1, -- aura description available
	none = 2 -- no aura description found
};

local getAuraDescriptionFromTooltipScanTip;

function LibFroznFunctions:GetAuraDescription(unitID, index, filter, callbackForAuraData)
	-- check if spell data for aura is available and queried from server
	local spellID = select(10, UnitAura(unitID, index, filter));
	
	if (not spellID) then
		return;
	end
	
	local spell = Spell:CreateFromSpellID(spellID);
	
	if (spell:IsSpellEmpty()) then
		return LFF_AURA_DESCRIPTION.none;
	end
	
	-- spell data for aura is already available
	if (spell:IsSpellDataCached()) then
		return LFF_GetAuraDescriptionFromSpellData(unitID, index, filter);
	end
	
	-- spell data for aura isn't available
	local unitGUID = UnitGUID(unitID);
	
	spell:ContinueOnSpellLoad(function()
		LFF_GetAuraDescriptionFromSpellData(unitID, index, filter, callbackForAuraData, unitGUID);
	end);
	
	return LFF_AURA_DESCRIPTION.available;
end

function LFF_GetAuraDescriptionFromSpellData(unitID, index, filter, callbackForAuraData, unitGUID)
	-- check if unit guid from unit id is still the same when waiting for spell data
	if (callbackForAuraData) and (unitGUID) then
		local _unitGUID = UnitGUID(unitID);
		
		if (_unitGUID ~= unitGUID) then
			return;
		end
	end
	
	-- get aura description
	
	-- since df 10.0.2
	if (C_TooltipInfo) then
		local tooltipData = C_TooltipInfo.GetUnitAura(unitID, index, filter);
		
		if (tooltipData) then
			-- line 1 is aura name. line 2 is aura description.
			local line = tooltipData.lines[2];
			
			if (line) then
				local auraDescription = line.leftText;
				
				if (callbackForAuraData) then
					callbackForAuraData(auraDescription);
				end
				
				return auraDescription;
			end
		end
		
		return LFF_AURA_DESCRIPTION.none;
	end
	
	-- before df 10.0.2
	
	-- create scanning tooltip
	local scanTipName = LIB_NAME .. "_GetAuraDescription";
	
	if (not getAuraDescriptionFromTooltipScanTip) then
		getAuraDescriptionFromTooltipScanTip = CreateFrame("GameTooltip", scanTipName, nil, "GameTooltipTemplate");
		getAuraDescriptionFromTooltipScanTip:SetOwner(UIParent, "ANCHOR_NONE");
	end
	
	-- get aura description from tooltip
	getAuraDescriptionFromTooltipScanTip:ClearLines();
	getAuraDescriptionFromTooltipScanTip:SetUnitAura(unitID, index, filter);
	
	-- line 1 is aura name. line 2 is aura description.
	local leftText2 = _G[scanTipName .. "TextLeft2"];
	local auraDescription = (leftText2 and leftText2:GetText() or LFF_AURA_DESCRIPTION.none);
	
	if (callbackForAuraData) then
		callbackForAuraData(auraDescription);
	end
	
	return auraDescription;
end

----------------------------------------------------------------------------------------------------
--                                             Fonts                                              --
----------------------------------------------------------------------------------------------------

-- check if font exists
--
-- @param  fontFile  path to a font file
-- @return true if font exists, false otherwise.
local fontExistsFont;

function LibFroznFunctions:FontExists(fontFile)
	-- invalid font file
	if (type(fontFile) ~= "string") then
		return false;
	end
	
	-- create font
	if (not fontExistsFont) then
		fontExistsFont = CreateFont(LIB_NAME .. "FontExists");
	end
	
	-- check if font exists
	fontExistsFont:SetFont(fontFile, 10, "");
	
	return (not not fontExistsFont:GetFont());
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

-- create texture markup with aspect ratio
--
-- @param  textureFile    path to a texture (usually in Interface\\) or a FileDataID
-- @param  textureWidth   width of the source image in pixels
-- @param  textureHeight  height of the source image in pixels
-- @param  aspectRatio    aspect ratio
-- @param  leftTexel      coordinate that identifies the left edge in pixels
-- @param  rightTexel     coordinate that identifies the right edge in pixels
-- @param  topTexel       coordinate that identifies the top edge in pixels
-- @param  bottomTexel    coordinate that identifies the bottom edge in pixels
-- @param  xOffset        x offset for the rendered image in pixels
-- @param  yOffset        y offset for the rendered image in pixels (< 0 = move top, >0 = move bottom)
-- @return texture markup with vertex color
function LibFroznFunctions:CreateTextureMarkupWithAspectRatio(textureFile, textureWidth, textureHeight, aspectRatio, leftTexel, rightTexel, topTexel, bottomTexel, xOffset, yOffset)
	-- see CreateTextureMarkup() in "TextureUtil.lua"
	return ("|T%s:%d:%f:%d:%d:%d:%d:%d:%d:%d:%d|t"):format(
		  textureFile
		, 0
		, aspectRatio
		, xOffset or 0
		, yOffset or 0
		, textureWidth
		, textureHeight
		, leftTexel * textureWidth
		, rightTexel * textureWidth
		, topTexel * textureHeight
		, bottomTexel * textureHeight
	);
end

-- create texture markup with vertex color
--
-- @param  textureFile    path to a texture (usually in Interface\\) or a FileDataID
-- @param  textureWidth   width of the source image in pixels
-- @param  textureHeight  height of the source image in pixels
-- @param  width          width in pixels
-- @param  height         height in pixels
-- @param  leftTexel      coordinate that identifies the left edge in pixels
-- @param  rightTexel     coordinate that identifies the right edge in pixels
-- @param  topTexel       coordinate that identifies the top edge in pixels
-- @param  bottomTexel    coordinate that identifies the bottom edge in pixels
-- @param  xOffset        x offset for the rendered image in pixels
-- @param  yOffset        y offset for the rendered image in pixels (< 0 = move top, >0 = move bottom)
-- @param  rVertexColor   optional. R color value in the range 0-1 that is used to tint the texture
-- @param  gVertexColor   optional. G color value in the range 0-1 that is used to tint the texture
-- @param  bVertexColor   optional. B color value in the range 0-1 that is used to tint the texture
-- @return texture markup with vertex color
function LibFroznFunctions:CreateTextureMarkupWithVertexColor(textureFile, textureWidth, textureHeight, width, height, leftTexel, rightTexel, topTexel, bottomTexel, xOffset, yOffset, rVertexColor, gVertexColor, bVertexColor)
	local textureMarkup = CreateTextureMarkup(textureFile, textureWidth, textureHeight, width, height, leftTexel, rightTexel, topTexel, bottomTexel, xOffset, yOffset);
	
	if (rVertexColor) or (gVertexColor) or (bVertexColor) then
		textureMarkup = format(textureMarkup:sub(1, -3) .. ":%d:%d:%d|t", (rVertexColor or 0) * 255, (gVertexColor or 0) * 255, (bVertexColor or 0) * 255);
	end
	
	return textureMarkup;
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
		return;
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
--           .sex                          sex of unit, e.g. 1 (neutrum / unknown), 2 (male) or 3 (female)
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
		return;
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
	
	unitRecord.sex = UnitSex(unitID);
	unitRecord.className, unitRecord.classFile, unitRecord.classID = UnitClass(unitID);
	unitRecord.classification = UnitClassification(unitID);
	
	self:UpdateUnitRecord(unitRecord);
	
	return unitRecord;
end

-- update unit record
--
-- @param  unitRecord  see LibFroznFunctions:CreateUnitRecord()
-- @param  newUnitID   optional. new unit id, e.g. "player", "target" or "mouseover".
-- @return unitRecord, see LibFroznFunctions:CreateUnitRecord()
function LibFroznFunctions:UpdateUnitRecord(unitRecord, newUnitID)
	-- no valid unit any more e.g. during fading out
	local unitID = newUnitID or unitRecord.id;
	
	if (not UnitGUID(unitID)) then
		return;
	end
	
	-- update unit record
	unitRecord.id = unitID;
	
	unitRecord.level = unitRecord.isBattlePet and UnitBattlePetLevel(unitID) or UnitLevel(unitID) or -1;
	unitRecord.reactionIndex = LibFroznFunctions:GetUnitReactionIndex(unitID);
	
	unitRecord.health = UnitHealth(unitID);
	unitRecord.healthMax = UnitHealthMax(unitID);
	
	unitRecord.powerType = UnitPowerType(unitID);
	unitRecord.power = UnitPower(unitID);
	unitRecord.powerMax = UnitPowerMax(unitID);
end

-- iterate through unit's auras
--
-- @param unitID        unit id, e.g. "player", "target" or "mouseover"
-- @param filter        a list of filters, separated by pipe chars or spaces, see LFF_AURA_FILTERS
-- @param maxCount      optional. max count of auras to iterate through.
-- @param func          callback function for each aura. iteration of unit's auras cancelable with returning true.
-- @param usePackedAura optional. if true, aura infos will be passed to callback function "func" as a table of type UnitAuraInfo. otherwise aura infos from UnitAuraBySlot() / UnitAura() will be passed as multiple return values.
function LibFroznFunctions:ForEachAura(unitID, filter, maxCount, func, usePackedAura)
	-- see SecureAuraHeader_Update() in "SecureGroupHeaders.lua"
	
	-- since df 10.0.0
	if (AuraUtil) and (AuraUtil.ForEachAura) then
		local function callbackFunc(nameOrUnitAuraInfo, ...)
			if (usePackedAura) then
				if (not nameOrUnitAuraInfo) or (not nameOrUnitAuraInfo.name) then
					return;
				end
			else
				if (not nameOrUnitAuraInfo) then
					return;
				end
			end
			
			func(nameOrUnitAuraInfo, ...);
		end
		
		AuraUtil.ForEachAura(unitID, filter, maxCount, callbackFunc, usePackedAura);
		return;
	end
	
	-- before df 10.0.0
	if (maxCount) and (maxCount <= 0) then
		return;
	end
	
	local index = 0;
	
	while (true) do
		index = index + 1;
		
		local unitAura = { UnitAura(unitID, index, filter) };
		
		-- no more auras available
		local name = unitAura[1];
		
		if (not name) then
			break;
		end
		
		-- call func
		local done = false;
		
		if (usePackedAura) then
			done = func({
				name = unitAura[1],
				icon = unitAura[2],
				applications = unitAura[3],
				dispelName = unitAura[4],
				duration = unitAura[5],
				expirationTime = unitAura[6],
				sourceUnit = unitAura[7],
				isStealable = unitAura[8],
				nameplateShowPersonal = unitAura[9],
				spellId = unitAura[10],
				canApplyAura = unitAura[11],
				isBossAura = unitAura[12],
				isFromPlayerOrPlayerPet = unitAura[13],
				nameplateShowAll = unitAura[14],
				timeMod = unitAura[15],
				points = { select(16, unitAura) },
				
				-- not available
				auraInstanceID = nil,
				isHarmful = nil,
				isHelpful = nil,
				isNameplateOnly = nil,
				isRaid = nil,
				charges = nil,
				maxCharges = nil
			});
		else
			done = func(unpack(unitAura));
		end
		
		if (done) then
			break;
		end
		
		-- max count of auras reached
		if (maxCount) and (index == maxCount) then
			return;
		end
	end
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
		return;
	end
	
	-- get record in unit cache
	local unitGUID = UnitGUID(unitID);
	local unitCacheRecord = frameForDelayedInspection:GetUnitCacheRecord(unitID, unitGUID);
	
	if (not unitCacheRecord) then
		return;
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
		return;
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
		LibFroznFunctions:UpdateUnitRecord(unitCacheRecord, unitID);
	end
	
	return unitCacheRecord;
end

-- create record in unit cache
function frameForDelayedInspection:CreateUnitCacheRecord(unitID, unitGUID)
	unitCache[unitGUID] = LibFroznFunctions:CreateUnitRecord(unitID, unitGUID);
	local unitCacheRecord = unitCache[unitGUID];
	
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
		return;
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
		return;
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
--         returns "LFF_TALENTS.available" if talents are available.
--         returns "LFF_TALENTS.na" if no talents are available.
--         returns "LFF_TALENTS.none" if no talents have been found.
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
		local specializationName, specializationIcon, role, _;
		
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
			local _talentTabName, _talentTabIcon, _pointsSpent = GetTalentTabInfo(tabIndex, not isSelf, nil, activeTalentGroup);
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
		return;
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
-- @param  unitID                 unit id for unit, e.g. "player", "target" or "mouseover"
-- @param  callbackForItemData()  callback function if all item data is available. parameters: unitCacheRecord
-- @return .value                         average item level
--         .qualityColor                  ColorMixin with quality color
--         .totalItems                    total items
--         .TacoTipGearScore              TacoTip's GearScore
--         .TacoTipGearScoreQualityColor  ColorMixin with TacoTip's GearScore quality color
--         .TipTacGearScore               TipTac's GearScore
--         .TipTacGearScoreQualityColor   ColorMixin with TipTac's GearScore quality color
--         returns "LFF_AVERAGE_ITEM_LEVEL.available" if average item level is available.
--         returns "LFF_AVERAGE_ITEM_LEVEL.na" if no average item level is available.
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
LFF_BASE_LEVEL_FOR_TIPTAC_GEAR_SCORE =
	LibFroznFunctions.isWoWFlavor.ClassicEra and  66 or -- Cenarion Vestments (Druid, Tier 1)
	LibFroznFunctions.isWoWFlavor.BCC        and 120 or -- Chestguard of Malorne (Druid, Tier 4)
	LibFroznFunctions.isWoWFlavor.WotLKC     and 213 or -- Valorous Dreamwalker Robe (Druid, Tier 7)
	LibFroznFunctions.isWoWFlavor.DF         and 395;   -- Lost Landcaller's Robes (Druid, Tier 23)

function LFF_GetAverageItemLevelFromItemData(unitID, callbackForItemData, unitGUID)
	-- check if unit guid from unit id is still the same when waiting for item data
	if (callbackForItemData) and (unitGUID) then
		local _unitGUID = UnitGUID(unitID);
		
		if (_unitGUID ~= unitGUID) then
			return;
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
					item = item,
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
	
	-- calculate average item level and TipTac's GearScore
	local totalScore = 0;
	local totalItems = 0;
	local totalQuality = 0;
	local totalItemsForQuality = 0;
	local averageItemLevel;
	local totalQualityColor;
	local TacoTipGearScore = 0;
	local TacoTipGearScoreQualityColor;
	local TipTacGearScore = 0;
	local TipTacGearScoreQualityColor;
	
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
	
	local slotModForTipTacGearScore = {
		[Enum.InventoryType.IndexNeckType] = 0.5625,
		[Enum.InventoryType.IndexShoulderType] = 0.75,
		[Enum.InventoryType.IndexBodyType] = 0,
		[Enum.InventoryType.IndexWaistType] = 0.75,
		[Enum.InventoryType.IndexFeetType] = 0.75,
		[Enum.InventoryType.IndexWristType] = 0.5625,
		[Enum.InventoryType.IndexHandType] = 0.75,
		[Enum.InventoryType.IndexFingerType] = 0.5625,
		[Enum.InventoryType.IndexTrinketType] = 0.5625,
		[Enum.InventoryType.IndexRangedType] = 0.3164,
		[Enum.InventoryType.IndexCloakType] = 0.5625,
		[Enum.InventoryType.IndexThrownType] = 0.3164,
		[Enum.InventoryType.IndexRangedrightType] = 0.3164,
		[Enum.InventoryType.IndexRelicType] = 0.3164
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
	
	-- calculate average item level and GearScore
	for i, item in pairs(items) do
		-- map Heirloom and WoWToken to Rare
		local quality = item.quality;
		
		if (quality == 7) or (quality == 8) then
			quality = 3;
		end
		
		if (not ignoreInventorySlots[i]) then -- ignore shirt, tabard and ranged
			local twoHandedMainHandOnly = false;
			local iLvlToAdd;
			
			totalItems = totalItems + 1;
			
			if (i == INVSLOT_MAINHAND) or (i == INVSLOT_OFFHAND) then -- handle main and off hand
				if (isMainHandOnly) then -- main hand only
					if (twoHandedInventoryTypes[item.inventoryType]) then -- two handed
						iLvlToAdd = item.effectiveILvl * 2;
						totalItems = totalItems + 1;
						twoHandedMainHandOnly = true;
					else -- one handed
						iLvlToAdd = item.effectiveILvl;
					end
				else -- main and/or off hand
					if (isMainHandArtifact) or (isOffHandArtifact) then -- main or off hand is artifact
						if (itemMainHandEffectiveILvl > itemOffHandEffectiveILvl) then
							iLvlToAdd = itemMainHandEffectiveILvl;
						else
							iLvlToAdd = itemOffHandEffectiveILvl;
						end
					else -- main and off hand are non-artifacts
						iLvlToAdd = item.effectiveILvl;
					end
				end
			else -- other items
				iLvlToAdd = item.effectiveILvl;
			end
			
			totalScore = totalScore + iLvlToAdd;
			totalItemsForQuality = totalItemsForQuality + 1;
			totalQuality = totalQuality + quality;
			
			-- TipTac's own implementation to simply calculate the GearScore:
			-- 1. weighted item level by performance per item level above/below base level of first tier set of current expansion
			-- 2. weighted item level by inventory type
			-- 3. weighted item level by item quality
			-- 4. sum it all up
			local performancePerILvlForTipTacGearScore = LFF_BASE_LEVEL_FOR_TIPTAC_GEAR_SCORE and math.pow(1.01, (twoHandedMainHandOnly and (iLvlToAdd / 2) or iLvlToAdd) - LFF_BASE_LEVEL_FOR_TIPTAC_GEAR_SCORE) or 1; -- +1 iLvl = +1% performance, source: https://www.wowhead.com/news/gear-inflation-on-target-1-item-level-should-result-in-roughly-1-increased-322062
			local qualityModForTipTacGearScore = LibFroznFunctions:ExistsInTable(quality, { 0, 1 }) and 0.005 or (quality == 5) and 1.3 or (quality == 6) and 1.69 or 1;
			
			TipTacGearScore = TipTacGearScore + (LFF_BASE_LEVEL_FOR_TIPTAC_GEAR_SCORE or iLvlToAdd) * performancePerILvlForTipTacGearScore * (slotModForTipTacGearScore[item.inventoryType] or 1) * (LibFroznFunctions:ExistsInTable(quality, { 0, 1 }) and 0.005 or (quality == 5) and 1.3 or (quality == 6) and 1.69 or 1);
		end
	end
	
	if (totalItems == 0) then
		if (callbackForItemData) then
			callbackForItemData(LFF_AVERAGE_ITEM_LEVEL.none);
		end

		return LFF_AVERAGE_ITEM_LEVEL.none;
	end
	
	-- set average item level and quality color
	local isSelf = UnitIsUnit(unitID, "player");
	
	if (isSelf) and (GetAverageItemLevel) then
		local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel();
		
		averageItemLevel = math.floor(avgItemLevelEquipped);
		
		if (GetItemLevelColor) then
			totalQualityColor = LibFroznFunctions:CreateColorSmart(GetItemLevelColor());
		end
	elseif (C_PaperDollInfo) and (C_PaperDollInfo.GetInspectItemLevel) then
		averageItemLevel = C_PaperDollInfo.GetInspectItemLevel(unitID);
	end
	
	if (not averageItemLevel) or (averageItemLevel == 0) then
		averageItemLevel = math.floor(totalScore / 16);
	end
	
	if (not totalQualityColor) then
		totalQualityColor = LibFroznFunctions:GetItemQualityColor(math.floor(totalQuality / totalItemsForQuality + 0.5), Enum.ItemQuality.Common);
	end
	
	-- set GearScore and quality color
	TacoTipGearScore, TacoTipGearScoreQualityColor = LFF_GetTacoTipGearScoreFromItemData(unitID, (unitGUID or UnitGUID(unitID)), items);
	TipTacGearScore = math.floor(TipTacGearScore);
	TipTacGearScoreQualityColor = totalQualityColor;
	
	-- return average item level
	local returnAverageItemLevel = {
		value = averageItemLevel,
		qualityColor = totalQualityColor,
		totalItems = totalItemsForQuality,
		TacoTipGearScore = TacoTipGearScore,
		TacoTipGearScoreQualityColor = TacoTipGearScoreQualityColor,
		TipTacGearScore = TipTacGearScore,
		TipTacGearScoreQualityColor = TipTacGearScoreQualityColor
	};
	
	if (callbackForItemData) then
		callbackForItemData(returnAverageItemLevel);
	end
	
	return returnAverageItemLevel;
end

-- get TacoTip's GearScore from item data (from "gearscore.lua" of TacoTip v0.4.3)
function LFF_GetTacoTipGearScoreFromItemData(unitID, unitGUID, items)
	local BRACKET_SIZE = 1000

	-- if (CI:IsWotlk()) then
	if (LibFroznFunctions.isWoWFlavor.WotLKC) then -- added
		BRACKET_SIZE = 1000
	-- elseif (CI:IsTBC()) then
	elseif (LibFroznFunctions.isWoWFlavor.BCC) then -- added
		BRACKET_SIZE = 400
	-- elseif (CI:IsClassic()) then
	elseif (LibFroznFunctions.isWoWFlavor.ClassicEra) then -- added
		BRACKET_SIZE = 200
	end

	local MAX_SCORE = BRACKET_SIZE*6-1

	local GS_ItemTypes = {
		["INVTYPE_RELIC"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false},
		["INVTYPE_TRINKET"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 33, ["Enchantable"] = false },
		["INVTYPE_2HWEAPON"] = { ["SlotMOD"] = 2.000, ["ItemSlot"] = 16, ["Enchantable"] = true },
		["INVTYPE_WEAPONMAINHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 16, ["Enchantable"] = true },
		["INVTYPE_WEAPONOFFHAND"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
		["INVTYPE_RANGED"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = true },
		["INVTYPE_THROWN"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
		["INVTYPE_RANGEDRIGHT"] = { ["SlotMOD"] = 0.3164, ["ItemSlot"] = 18, ["Enchantable"] = false },
		["INVTYPE_SHIELD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = true },
		["INVTYPE_WEAPON"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 36, ["Enchantable"] = true },
		["INVTYPE_HOLDABLE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 17, ["Enchantable"] = false },
		["INVTYPE_HEAD"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 1, ["Enchantable"] = true },
		["INVTYPE_NECK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 2, ["Enchantable"] = false },
		["INVTYPE_SHOULDER"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 3, ["Enchantable"] = true },
		["INVTYPE_CHEST"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
		["INVTYPE_ROBE"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 5, ["Enchantable"] = true },
		["INVTYPE_WAIST"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 6, ["Enchantable"] = false },
		["INVTYPE_LEGS"] = { ["SlotMOD"] = 1.0000, ["ItemSlot"] = 7, ["Enchantable"] = true },
		["INVTYPE_FEET"] = { ["SlotMOD"] = 0.75, ["ItemSlot"] = 8, ["Enchantable"] = true },
		["INVTYPE_WRIST"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 9, ["Enchantable"] = true },
		["INVTYPE_HAND"] = { ["SlotMOD"] = 0.7500, ["ItemSlot"] = 10, ["Enchantable"] = true },
		["INVTYPE_FINGER"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 31, ["Enchantable"] = false },
		["INVTYPE_CLOAK"] = { ["SlotMOD"] = 0.5625, ["ItemSlot"] = 15, ["Enchantable"] = true },
		["INVTYPE_BODY"] = { ["SlotMOD"] = 0, ["ItemSlot"] = 4, ["Enchantable"] = false },
	}

	local GS_Rarity = {
		[0] = {Red = 0.55, Green = 0.55, Blue = 0.55 },
		[1] = {Red = 1.00, Green = 1.00, Blue = 1.00 },
		[2] = {Red = 0.12, Green = 1.00, Blue = 0.00 },
		[3] = {Red = 0.00, Green = 0.50, Blue = 1.00 },
		[4] = {Red = 0.69, Green = 0.28, Blue = 0.97 },
		[5] = {Red = 0.94, Green = 0.09, Blue = 0.00 },
		[6] = {Red = 1.00, Green = 0.00, Blue = 0.00 },
		[7] = {Red = 0.90, Green = 0.80, Blue = 0.50 },
	}

	local GS_Formula = {
		["A"] = {
			[4] = { ["A"] = 91.4500, ["B"] = 0.6500 },
			[3] = { ["A"] = 81.3750, ["B"] = 0.8125 },
			[2] = { ["A"] = 73.0000, ["B"] = 1.0000 }
		},
		["B"] = {
			[4] = { ["A"] = 26.0000, ["B"] = 1.2000 },
			[3] = { ["A"] = 0.7500, ["B"] = 1.8000 },
			[2] = { ["A"] = 8.0000, ["B"] = 2.0000 },
			[1] = { ["A"] = 0.0000, ["B"] = 2.2500 }
		}
	}

	local GS_Quality = {
		[BRACKET_SIZE*6] = {
			["Red"] = { ["A"] = 0.94, ["B"] = BRACKET_SIZE*5, ["C"] = 0.00006, ["D"] = 1 },
			["Blue"] = { ["A"] = 0.47, ["B"] = BRACKET_SIZE*5, ["C"] = 0.00047, ["D"] = -1 },
			["Green"] = { ["A"] = 0, ["B"] = 0, ["C"] = 0, ["D"] = 0 },
			["Description"] = "Legendary"
		},
		[BRACKET_SIZE*5] = {
			["Red"] = { ["A"] = 0.69, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00025, ["D"] = 1 },
			["Blue"] = { ["A"] = 0.28, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00019, ["D"] = 1 },
			["Green"] = { ["A"] = 0.97, ["B"] = BRACKET_SIZE*4, ["C"] = 0.00096, ["D"] = -1 },
			["Description"] = "Epic"
		},
		[BRACKET_SIZE*4] = {
			["Red"] = { ["A"] = 0.0, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00069, ["D"] = 1 },
			["Blue"] = { ["A"] = 0.5, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00022, ["D"] = -1 },
			["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE*3, ["C"] = 0.00003, ["D"] = -1 },
			["Description"] = "Superior"
		},
		[BRACKET_SIZE*3] = {
			["Red"] = { ["A"] = 0.12, ["B"] = BRACKET_SIZE*2, ["C"] = 0.00012, ["D"] = -1 },
			["Blue"] = { ["A"] = 1, ["B"] = BRACKET_SIZE*2, ["C"] = 0.00050, ["D"] = -1 },
			["Green"] = { ["A"] = 0, ["B"] = BRACKET_SIZE*2, ["C"] = 0.001, ["D"] = 1 },
			["Description"] = "Uncommon"
		},
		[BRACKET_SIZE*2] = {
			["Red"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.00088, ["D"] = -1 },
			["Blue"] = { ["A"] = 1, ["B"] = 000, ["C"] = 0.00000, ["D"] = 0 },
			["Green"] = { ["A"] = 1, ["B"] = BRACKET_SIZE, ["C"] = 0.001, ["D"] = -1 },
			["Description"] = "Common"
		},
		[BRACKET_SIZE] = {
			["Red"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
			["Blue"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
			["Green"] = { ["A"] = 0.55, ["B"] = 0, ["C"] = 0.00045, ["D"] = 1 },
			["Description"] = "Trash"
		},
	}
	
	local function GetQuality(ItemScore)
		ItemScore = tonumber(ItemScore)
		if (not ItemScore) then
			return 0, 0, 0, "Trash"
		end
		--if (not CI:IsWotlk()) then
			--return 1, 1, 1, "Common"
		--end
		if (ItemScore > MAX_SCORE) then
			ItemScore = MAX_SCORE
		end
		local Red = 0.1
		local Blue = 0.1
		local Green = 0.1
		local GS_QualityDescription = "Legendary"
		for i = 0,6 do
			if ((ItemScore > i * BRACKET_SIZE) and (ItemScore <= ((i + 1) * BRACKET_SIZE))) then
				local Red = GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Red["D"])
				local Blue = GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Green["D"])
				local Green = GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["A"] + (((ItemScore - GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["B"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["C"])*GS_Quality[( i + 1 ) * BRACKET_SIZE].Blue["D"])
				return Red, Green, Blue, GS_Quality[( i + 1 ) * BRACKET_SIZE].Description
			end
		end
		return 0.1, 0.1, 0.1, "Trash"
	end

	local function GetItemScore(ItemLink)
		if not (ItemLink) then
			return 0, 0, 0.1, 0.1, 0.1
		end
		local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(ItemLink)
		if (ItemLink and ItemRarity and ItemLevel and ItemEquipLoc and GS_ItemTypes[ItemEquipLoc]) then
			local Table
			local QualityScale = 1
			local GearScore = 0
			local Scale = 1.8618
			if (ItemRarity == 5) then 
				QualityScale = 1.3
				ItemRarity = 4
			elseif (ItemRarity == 1) then
				QualityScale = 0.005
				ItemRarity = 2
			elseif (ItemRarity == 0) then
				QualityScale = 0.005
				ItemRarity = 2
			elseif (ItemRarity == 7) then
				ItemRarity = 3
				ItemLevel = 187.05
			end
			if (ItemLevel > 120) then
				Table = GS_Formula["A"]
			else
				Table = GS_Formula["B"]
			end
			if ((ItemRarity >= 2) and (ItemRarity <= 4)) then
				local Red, Green, Blue = GetQuality((floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * 1 * Scale)) * 11.25)
				GearScore = floor(((ItemLevel - Table[ItemRarity].A) / Table[ItemRarity].B) * GS_ItemTypes[ItemEquipLoc].SlotMOD * Scale * QualityScale)
				if (ItemLevel == 187.05) then
					ItemLevel = 0
				end
				if (GearScore < 0) then
					GearScore = 0
					Red, Green, Blue = GetQuality(1)
				end
				return GearScore, ItemLevel, Red, Green, Blue, ItemEquipLoc
			end
		end
		return 0, 0, 0.1, 0.1, 0.1, 0
	end
	
	local function GetScore(unitorguid, useCallback)
		-- local guid = getPlayerGUID(unitorguid)
		local guid = unitorguid -- added
		-- if (guid) then
			-- if (guid ~= UnitGUID("player")) then
				-- local _, invTime = CI:GetLastCacheTime(guid)
				-- if(invTime == 0) then
					-- return 0,0
				-- end
			-- end

			local PlayerClass, PlayerEnglishClass = GetPlayerInfoByGUID(guid)
			local GearScore = 0
			local ItemCount = 0
			local LevelTotal = 0
			local TitanGrip = 1
			local IsReady = true

			-- local mainHandItem = CI:GetInventoryItemMixin(guid, 16)
			-- local offHandItem = CI:GetInventoryItemMixin(guid, 17)
			local mainHandItem = items[16] and items[16].item -- added
			local offHandItem = items[17] and items[17].item -- added
			local mainHandLink
			local offHandLink
			
			local cb_table
			
			if (useCallback) then
				cb_table = {["guid"] = guid, ["items"] = {}}
			end

			if (mainHandItem) then
				if (mainHandItem:IsItemDataCached()) then
					mainHandLink = mainHandItem:GetItemLink()
				else
					IsReady = false
					local itemID = mainHandItem:GetItemID()
					if (itemID) then
						if (useCallback) then
							table.insert(cb_table.items, itemID)
							mainHandItem:ContinueOnItemLoad(function()
								itemcacheCB(cb_table, itemID)
							end)
						else
							C_Item.RequestLoadItemDataByID(itemID)
						end
					end
				end
			end
			if (offHandItem) then
				if (offHandItem:IsItemDataCached()) then
					offHandLink = offHandItem:GetItemLink()
				else
					IsReady = false
					local itemID = offHandItem:GetItemID()
					if (itemID) then
						if (useCallback) then
							table.insert(cb_table.items, itemID)
							offHandItem:ContinueOnItemLoad(function()
								itemcacheCB(cb_table, itemID)
							end)
						else
							C_Item.RequestLoadItemDataByID(itemID)
						end
					end
				end
			end

			if (mainHandLink and offHandLink) then
				local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(mainHandLink)
				if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
					TitanGrip = 0.5
				end
			end

			if (offHandLink) then
				local ItemName, ItemLink, ItemRarity, ItemLevel, ItemMinLevel, ItemType, ItemSubType, ItemStackCount, ItemEquipLoc, ItemTexture = GetItemInfo(offHandLink)
				if (ItemEquipLoc == "INVTYPE_2HWEAPON") then
					TitanGrip = 0.5
				end
				local TempScore, ItemLevel = GetItemScore(offHandLink)
				if (PlayerEnglishClass == "HUNTER") then
					TempScore = TempScore * 0.3164
				end
				GearScore = GearScore + TempScore * TitanGrip
				ItemCount = ItemCount + 1
				LevelTotal = LevelTotal + ItemLevel
			end

			for i = 1, 18 do
				if ( i ~= 4 ) and ( i ~= 17 ) then
					-- local item = CI:GetInventoryItemMixin(guid, i)
					local item = items[i] and items[i].item -- added
					if (item) then
						if (item:IsItemDataCached()) then
							local TempScore, ItemLevel = GetItemScore(item:GetItemLink())
							if (PlayerEnglishClass == "HUNTER") then
								if (i == 16) then
									TempScore = TempScore * 0.3164
								elseif (i == 18) then
									TempScore = TempScore * 5.3224
								end
							end
							if ( i == 16 ) then
								TempScore = TempScore * TitanGrip
							end
							GearScore = GearScore + TempScore
							ItemCount = ItemCount + 1
							LevelTotal = LevelTotal + ItemLevel
						else
							IsReady = false
							local itemID = item:GetItemID()
							if (itemID) then
								if (useCallback) then
									table.insert(cb_table.items, itemID)
									item:ContinueOnItemLoad(function()
										itemcacheCB(cb_table, itemID)
									end)
								else
									C_Item.RequestLoadItemDataByID(itemID)
								end
							end
						end
					end
				end
			end
			if (IsReady and GearScore > 0 and ItemCount > 0) then
				return floor(GearScore), floor(LevelTotal/ItemCount)
			end
		-- end
		-- return 0,0
	end
	
	-- return GearScore and quality color
	local gearScore = GetScore(unitGUID);
	local qualityColorR, qualityColorG, qualityColorB = GetQuality(gearScore);
	local qualityColor = CreateColor(qualityColorR, qualityColorG, qualityColorB, 1);
	
	return gearScore, qualityColor;
end
