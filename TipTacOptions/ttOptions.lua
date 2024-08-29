local cfg = TipTac_Config;
local MOD_NAME = ...;
local PARENT_MOD_NAME = "TipTac";

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");
local LibSerialize = LibStub:GetLibrary("LibSerialize");
local LibDeflate = LibStub:GetLibrary("LibDeflate");

-- constants
local TT_OPTIONS_CATEGORY_LIST_WIDTH = 117;

-- DropDown Lists
local DROPDOWN_FONTFLAGS = {
	["|cffffa0a0None"] = "",
	["Outline"] = "OUTLINE",
	["Thick Outline"] = "THICKOUTLINE",
};
local DROPDOWN_ANCHORTYPE = {
	["Normal Anchor"] = "normal",
	["Mouse Anchor"] = "mouse",
	["Parent Anchor"] = "parent",
};

local DROPDOWN_ANCHORPOS = {
	["Top"] = "TOP",
	["Top Left"] = "TOPLEFT",
	["Top Right"] = "TOPRIGHT",
	["Bottom"] = "BOTTOM",
	["Bottom Left"] = "BOTTOMLEFT",
	["Bottom Right"] = "BOTTOMRIGHT",
	["Left"] = "LEFT",
	["Right"] = "RIGHT",
	["Center"] = "CENTER",
};

local DROPDOWN_ANCHORHALIGN = {
	["Left"] = "LEFT",
	["Center"] = "CENTER",
	["Right"] = "RIGHT",
};

local DROPDOWN_ANCHORVALIGN = {
	["Top"] = "TOP",
	["Middle"] = "MIDDLE",
	["Bottom"] = "BOTTOM",
};

local DROPDOWN_ANCHORGROWDIRECTION = {
	["Up"] = "UP",
	["Right"] = "RIGHT",
	["Down"] = "DOWN",
	["Left"] = "LEFT",
};

local DROPDOWN_BARTEXTFORMAT = {
	["|cffffa0a0None"] = "none",
	["Percentage"] = "percent",
	["Current Only"] = "current",
	["Values"] = "value",
	["Values & Percent"] = "full",
	["Deficit"] = "deficit",
};

-- Options -- The "y" value of a category subtable, will further increase the vertical offset position of the item
--
-- hint for layouting options:
-- to set pixel perfect scale for options to adjust option elements:
-- /run local psw, psh = GetPhysicalScreenSize(); local uf = 768 / psh; local uis = UIParent:GetEffectiveScale(); local ttos = uf / uis; _G["TipTacOptions"]:SetScale(ttos);
local activePage = 1;
local options = {};
local option;

-- General
local ttOptionsGeneral = {
	{ type = "Check", var = "showMinimapIcon", label = "Enable Minimap Icon", tip = "Will show a minimap icon for " .. PARENT_MOD_NAME },
	{ type = "Slider", var = "gttScale", label = "Tooltip Scale", min = 0.2, max = 4, step = 0.05, y = 10 },
	
	{ type = "Header", label = "Unit Tip Appearance" },
	{ type = "Check", var = "showUnitTip", label = "Enable " .. PARENT_MOD_NAME .. " Unit Tip Appearance", tip = "Will change the appearance of how unit tips look. Many options in " .. PARENT_MOD_NAME .. " only work with this setting enabled.\nNOTE: Using this options with a non English client may cause issues!" },
	
	{ type = "Check", var = "showStatus", label = "Show DC, AFK and DND Status", tip = "Will show the <DC>, <AFK> and <DND> status after the player name", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 },
	{ type = "Check", var = "showTargetedBy", label = "Show Who Targets the Unit", tip = "When in a raid or party, the tip will show who from your group is targeting the unit.\nWhen ungrouped, the visible nameplates (can be enabled under WoW options 'Game->Gameplay->Interface->Nameplates') are evaluated instead.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	{ type = "Check", var = "showPlayerGender", label = "Show Player Gender", tip = "This will show the gender of the player. E.g. \"85 Female Blood Elf Paladin\".", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	{ type = "Check", var = "showCurrentUnitSpeed", label = "Show Current Unit Speed", tip = "This will show the current speed of the unit after race & class.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end }
};

if (C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
	tinsert(ttOptionsGeneral, { type = "Check", var = "showMythicPlusDungeonScore", label = "Show Mythic+ Dungeon Score", tip = "This will show the mythic+ dungeon score of the player.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });
	tinsert(ttOptionsGeneral, { type = "DropDown", var = "mythicPlusDungeonScoreFormat", label = "Format Dungeon Score", list = { ["Dungeon Score only"] = "dungeonScore", ["Dungeon Score + Highest successfull run"] = "both", ["Highest successfull run only"] = "highestSuccessfullRun" }, enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });
end

tinsert(ttOptionsGeneral, { type = "Check", var = "showMount", label = "Show Mount", tip = "This will show the current mount of the player.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });
tinsert(ttOptionsGeneral, { type = "Check", var = "showMountCollected", label = "Collected", tip = "This option makes the tip show an icon indicating if you already have collected the mount.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showMount") end, x = 122 });
tinsert(ttOptionsGeneral, { type = "Check", var = "showMountIcon", label = "Icon", tip = "This option makes the tip show the mount icon.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showMount") end, x = 210 });
tinsert(ttOptionsGeneral, { type = "Check", var = "showMountText", label = "Text", tip = "This option makes the tip show the mount text.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showMount") end, x = 122 });
tinsert(ttOptionsGeneral, { type = "Check", var = "showMountSpeed", label = "Speed", tip = "This option makes the tip show the mount speed.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showMount") end, x = 210 });

tinsert(ttOptionsGeneral, { type = "DropDown", var = "nameType", label = "Name & Title", list = { ["Name only"] = "normal", ["Name + title"] = "title", ["Copy from original tip"] = "original", ["Mary Sue Protocol"] = "marysueprot" }, enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });
tinsert(ttOptionsGeneral, { type = "DropDown", var = "showRealm", label = "Show Unit Realm", list = { ["|cffffa0a0Do not show realm"] = "none", ["Show realm"] = "show", ["Show realm in new line"] = "showInNewLine", ["Show (*) instead"] = "asterisk" }, enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });
tinsert(ttOptionsGeneral, { type = "DropDown", var = "showTarget", label = "Show Unit Target", list = { ["|cffffa0a0Do not show target"] = "none", ["After name"] = "afterName", ["Below name/realm"] = "belowNameRealm", ["Last line"] = "last" }, enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });

tinsert(ttOptionsGeneral, { type = "Text", var = "targetYouText", label = "Targeting You Text", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });

tinsert(ttOptionsGeneral, { type = "Check", var = "showGuild", label = "Show Player Guild", tip = "This will show the guild of the player.", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });
tinsert(ttOptionsGeneral, { type = "Check", var = "showGuildRank", label = "Show Player Guild Rank", tip = "In addition to the guild name, with this option on, you will also see their guild rank by title and/or level", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showGuild") end });
tinsert(ttOptionsGeneral, { type = "DropDown", var = "guildRankFormat", label = "Format Guild Rank", list = { ["Title only"] = "title", ["Title + level"] = "both", ["Level only"] = "level" }, enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showGuild") and factory:GetConfigValue("showGuildRank") end });

tinsert(ttOptionsGeneral, { type = "Check", var = "showBattlePetTip", label = "Enable Battle Pet Tips", tip = "Will show a special tip for both wild and companion battle pets. Might need to be disabled for certain non-English clients", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 });

tinsert(ttOptionsGeneral, { type = "Header", label = "Strip default text from tooltip", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });

tinsert(ttOptionsGeneral, { type = "Check", var = "hidePvpText", label = "Hide PvP Text", tip = "Strips the PvP line from the tooltip", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });

if (LibFroznFunctions.hasWoWFlavor.specializationAndClassTextInPlayerUnitTip) then
	tinsert(ttOptionsGeneral, { type = "Check", var = "hideSpecializationAndClassText", label = "Hide Specialization & Class Text", tip = "Strips the Specialization & Class text from the tooltip", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end });
end

-- Colors
local ttOptionsColors = {
	{ type = "Check", var = "enableColorName", label = "Enable Coloring of Name", tip = "Turns on or off coloring names", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	{ type = "Color", var = "colorName", label = "Name Color", tip = "Color of the name, when not using the option to make it the same as reaction color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("enableColorName") end },
	{ type = "Check", var = "colorNameByReaction", label = "Color Name by Reaction", tip = "Name color will have the same color as the reaction\nNOTE: This option is overridden by class colored name for players", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	{ type = "Check", var = "colorNameByClass", label = "Color Player Names by Class Color", tip = "With this option on, player names are colored by their class color\nNOTE: This option overrides reaction colored name for players", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	
	{ type = "Color", var = "colorGuild", label = "Guild Color", tip = "Color of the guild name, when not using the option to make it the same as reaction color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showGuild") end, y = 10 },
	{ type = "Color", var = "colorSameGuild", label = "Your Guild Color", tip = "To better recognise players from your guild, you can configure the color of your guild name individually", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showGuild") end, x = 120 },
	{ type = "Check", var = "colorGuildByReaction", label = "Color Guild by Reaction", tip = "Guild color will have the same color as the reacion", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("showGuild") end },
	
	{ type = "Color", var = "colorRace", label = "Race & Creature Type Color", tip = "The color of the race and creature type text", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 },
	{ type = "Color", var = "colorLevel", label = "Neutral Level Color", tip = "Units you cannot attack will have their level text shown in this color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
	
	{ type = "Check", var = "factionText", label = "Show the unit's Faction Text", tip = "With this option on, the faction text of the unit will be shown as text below the level line", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 },
	{ type = "Check", var = "enableColorFaction", label = "Enable Coloring of Faction Text", tip = "Turns on or off coloring faction texts", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("factionText") end },
	{ type = "Color", var = "colorFactionAlliance", label = "Alliance Faction Text Color", tip = "Color of the Alliance faction text", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("factionText") and factory:GetConfigValue("enableColorFaction") end },
	{ type = "Color", var = "colorFactionHorde", label = "Horde Faction Text Color", tip = "Color of the Horde faction text", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("factionText") and factory:GetConfigValue("enableColorFaction") end },
	{ type = "Color", var = "colorFactionNeutral", label = "Neutral Faction Text Color", tip = "Color of the Neutral faction text", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("factionText") and factory:GetConfigValue("enableColorFaction") end },
	
	{ type = "Check", var = "classColoredBorder", label = "Color Tip Border by Class Color", tip = "For players, the border color will be colored to match the color of their class\nNOTE: This option overrides reaction colored border", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end, y = 10 },
	
	{ type = "Header", label = "Custom Class Colors" },
	
	{ type = "Check", var = "enableCustomClassColors", label = "Enable Custom Class Colors", tip = "Turns on or off custom class colors" }
};

local numClasses = GetNumClasses();
local firstClass = true;

for i = 1, numClasses do
	local className, classFile = GetClassInfo(i);
	
	if (classFile) then
		local camelCasedClassFile = LibFroznFunctions:CamelCaseText(classFile);
		
		tinsert(ttOptionsColors, { type = "Color", var = "colorCustomClass" .. camelCasedClassFile, label = camelCasedClassFile .. " Color", enabled = function(factory) return factory:GetConfigValue("enableCustomClassColors") end, y = (firstClass and 10 or nil) });
		
		firstClass = false;
	end
end

-- Anchors
local ttOptionsAnchors = {
	{ type = "DropDown", var = "anchorWorldUnitType", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end },
	{ type = "DropDown", var = "anchorWorldUnitPoint", label = "World Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end },
	
	{ type = "DropDown", var = "anchorWorldTipType", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 },
	{ type = "DropDown", var = "anchorWorldTipPoint", label = "World Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end },
	
	{ type = "DropDown", var = "anchorFrameUnitType", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 },
	{ type = "DropDown", var = "anchorFrameUnitPoint", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end },
	
	{ type = "DropDown", var = "anchorFrameTipType", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 },
	{ type = "DropDown", var = "anchorFrameTipPoint", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end }
};

local priority = 0;

if (LibFroznFunctions.hasWoWFlavor.challengeMode) then
	priority = priority + 1;
	tinsert(ttOptionsAnchors, { type = "Header", label = "Prio #" .. priority .. ": Anchor Overrides During Challenge Mode", tip = "Special anchor overrides during challenge mode (mythic+)", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldUnitDuringChallengeMode", label = "World Unit during challenge mode", tip = "This option will override the anchor for World Unit during challenge mode (mythic+)", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitTypeDuringChallengeMode", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitDuringChallengeMode") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitPointDuringChallengeMode", label = "World Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitDuringChallengeMode") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldTipDuringChallengeMode", label = "World Tip during challenge mode", tip = "This option will override the anchor for World Tip during challenge mode (mythic+)", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipTypeDuringChallengeMode", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipDuringChallengeMode") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipPointDuringChallengeMode", label = "World Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipDuringChallengeMode") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameUnitDuringChallengeMode", label = "Frame Unit during challenge mode", tip = "This option will override the anchor for Frame Unit during challenge mode (mythic+)", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitTypeDuringChallengeMode", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitDuringChallengeMode") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitPointDuringChallengeMode", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitDuringChallengeMode") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameTipDuringChallengeMode", label = "Frame Tip during challenge mode", tip = "This option will override the anchor for Frame Tip during challenge mode (mythic+)", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipTypeDuringChallengeMode", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipDuringChallengeMode") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipPointDuringChallengeMode", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipDuringChallengeMode") end });
end

if (LibFroznFunctions.hasWoWFlavor.skyriding) then
	priority = priority + 1;
	tinsert(ttOptionsAnchors, { type = "Header", label = "Prio #" .. priority .. ": Anchor Overrides During Skyriding", tip = "Special anchor overrides during skyriding", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldUnitDuringSkyriding", label = "World Unit during skyriding", tip = "This option will override the anchor for World Unit during skyriding", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitTypeDuringSkyriding", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitDuringSkyriding") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitPointDuringSkyriding", label = "World Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitDuringSkyriding") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldTipDuringSkyriding", label = "World Tip during skyriding", tip = "This option will override the anchor for World Tip during skyriding", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipTypeDuringSkyriding", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipDuringSkyriding") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipPointDuringSkyriding", label = "World Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipDuringSkyriding") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameUnitDuringSkyriding", label = "Frame Unit during skyriding", tip = "This option will override the anchor for Frame Unit during skyriding", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitTypeDuringSkyriding", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitDuringSkyriding") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitPointDuringSkyriding", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitDuringSkyriding") end });
	
	tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameTipDuringSkyriding", label = "Frame Tip during skyriding", tip = "This option will override the anchor for Frame Tip during skyriding", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipTypeDuringSkyriding", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipDuringSkyriding") end });
	tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipPointDuringSkyriding", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipDuringSkyriding") end });
end

priority = priority + 1;
tinsert(ttOptionsAnchors, { type = "Header", label = (priority > 1 and "Prio #" .. priority .. ": " or "") .. "Anchor Overrides For In Combat", tip = "Special anchor overrides for in combat", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldUnitInCombat", label = "World Unit in combat", tip = "This option will override the anchor for World Unit in combat", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitTypeInCombat", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitInCombat") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldUnitPointInCombat", label = "World Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldUnitInCombat") end });

tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideWorldTipInCombat", label = "World Tip in combat", tip = "This option will override the anchor for World Tip in combat", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipTypeInCombat", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipInCombat") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorWorldTipPointInCombat", label = "World Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideWorldTipInCombat") end });

tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameUnitInCombat", label = "Frame Unit in combat", tip = "This option will override the anchor for Frame Unit in combat", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitTypeInCombat", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitInCombat") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameUnitPointInCombat", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameUnitInCombat") end });

tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideFrameTipInCombat", label = "Frame Tip in combat", tip = "This option will override the anchor for Frame Tip in combat", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end, y = 10 });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipTypeInCombat", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipInCombat") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorFrameTipPointInCombat", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideFrameTipInCombat") end });

tinsert(ttOptionsAnchors, { type = "Header", label = "Other Anchor Overrides", tip = "Other special anchor overrides", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

tinsert(ttOptionsAnchors, { type = "Check", var = "enableAnchorOverrideCF", label = "(Guild & Community) ChatFrame", tip = "This option will override the anchor for (Guild & Community) ChatFrame", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorOverrideCFType", label = "Tip Type", list = DROPDOWN_ANCHORTYPE, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideCF") end });
tinsert(ttOptionsAnchors, { type = "DropDown", var = "anchorOverrideCFPoint", label = "Tip Point", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableAnchor") and factory:GetConfigValue("enableAnchorOverrideCF") end });

tinsert(ttOptionsAnchors, { type = "Header", label = "Mouse Settings", enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

tinsert(ttOptionsAnchors, { type = "Slider", var = "mouseOffsetX", label = "Mouse Anchor X Offset", min = -200, max = 200, step = 1, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });
tinsert(ttOptionsAnchors, { type = "Slider", var = "mouseOffsetY", label = "Mouse Anchor Y Offset", min = -200, max = 200, step = 1, enabled = function(factory) return factory:GetConfigValue("enableAnchor") end });

-- Hiding
local ttOptionsHiding = {};
priority = 0;

if (LibFroznFunctions.hasWoWFlavor.challengeMode) then
	priority = priority + 1;
	tinsert(ttOptionsHiding, { type = "Header", label = "Prio #" .. priority .. ": Hide Tips During Challenge Mode" });
	
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden during challenge mode (mythic+)." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden during challenge mode (mythic+).", x = 160 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden during challenge mode (mythic+)." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden during challenge mode (mythic+).", x = 160 });
	
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden during challenge mode (mythic+).", y = 10 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden during challenge mode (mythic+).", x = 160 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden during challenge mode (mythic+)." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeActionTips", label = "Hide Action Bar Tips", tip = "When you have this option checked, Action Bar Tips will be hidden during challenge mode (mythic+)." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringChallengeModeExpBarTips", label = "Hide Exp Bar Tips", tip = "When you have this option checked, Experience Bar Tips will be hidden during challenge mode (mythic+).", x = 160 });
end

if (LibFroznFunctions.hasWoWFlavor.skyriding) then
	priority = priority + 1;
	tinsert(ttOptionsHiding, { type = "Header", label = "Prio #" .. priority .. ": Hide Tips During Skyriding" });
	
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden during skyriding." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden during skyriding.", x = 160 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden during skyriding." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden during skyriding.", x = 160 });
	
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden during skyriding.", y = 10 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden during skyriding.", x = 160 });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden during skyriding." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingActionTips", label = "Hide Action Bar Tips", tip = "When you have this option checked, Action Bar Tips will be hidden during skyriding." });
	tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsDuringSkyridingExpBarTips", label = "Hide Exp Bar Tips", tip = "When you have this option checked, Experience Bar Tips will be hidden during skyriding.", x = 160 });
end

priority = priority + 1;
tinsert(ttOptionsHiding, { type = "Header", label = (priority > 1 and "Prio #" .. priority .. ": " or "") .. "Hide Tips In Combat" });

tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden in combat." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden in combat.", x = 160 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden in combat." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden in combat.", x = 160 });

tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden in combat.", y = 10 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden in combat.", x = 160 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden in combat." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatActionTips", label = "Hide Action Bar Tips", tip = "When you have this option checked, Action Bar Tips will be hidden in combat." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsInCombatExpBarTips", label = "Hide Exp Bar Tips", tip = "When you have this option checked, Experience Bar Tips will be hidden in combat.", x = 160 });

tinsert(ttOptionsHiding, { type = "Header", label = (priority > 1 and "Prio #" .. priority .. ": " or "") .. "Hide Tips Out Of Combat" });

tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden.", x = 160 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden.", x = 160 });

tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden.", y = 10 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden.", x = 160 });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsActionTips", label = "Hide Action Bar Tips", tip = "When you have this option checked, Action Bar Tips will be hidden." });
tinsert(ttOptionsHiding, { type = "Check", var = "hideTipsExpBarTips", label = "Hide Exp Bar Tips", tip = "When you have this option checked, Experience Bar Tips will be hidden.", x = 160 });

tinsert(ttOptionsHiding, { type = "Header", label = "Others" });

tinsert(ttOptionsHiding, { type = "DropDown", var = "showHiddenModifierKey", label = "Still Show Hidden Tips\nwhen Holding\nModifier Key", list = { ["Shift"] = "shift", ["Ctrl"] = "ctrl", ["Alt"] = "alt", ["|cffffa0a0None"] = "none" } });
tinsert(ttOptionsHiding, { type = "TextOnly", label = "", y = -12 }); -- spacer for multi-line label above

-- build options
local options = {
	-- General
	{
		category = "General",
		options = ttOptionsGeneral
	},
	-- Colors
	{
		category = "Colors",
		options = ttOptionsColors
	},
	-- Reactions
	{
		category = "Reactions",
		options = {
			{ type = "Check", var = "reactColoredBorder", label = "Color border based on the unit's reaction", tip = "Same as the above option, just for the border\nNOTE: This option is overridden by class colored border", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			{ type = "Check", var = "reactIcon", label = "Show the unit's reaction as icon", tip = "This option makes the tip show the unit's reaction as an icon right behind the level", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			
			{ type = "Check", var = "reactText", label = "Show the unit's reaction as text", tip = "With this option on, the reaction of the unit will be shown as text below the level line", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 },
			{ type = "Color", var = "colorReactText", label = "Color of unit's reaction as text", tip = "Color of the unit's reaction as text, when not using the option to make it the same as reaction color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("reactText") end },
			{ type = "Check", var = "reactColoredText", label = "Color unit's reaction as text based on unit's reaction", tip = "With this option on, the unit's reaction as text will be based on unit's reaction", enabled = function(factory) return factory:GetConfigValue("showUnitTip") and factory:GetConfigValue("reactText") end },
			
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.tapped, label = "Tapped Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end, y = 10 },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.hostile, label = "Hostile Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.caution, label = "Caution Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.neutral, label = "Neutral Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer, label = "Friendly Player Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer, label = "Friendly PvP Player Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyNPC, label = "Friendly NPC Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.honoredNPC, label = "Honored NPC Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.reveredNPC, label = "Revered NPC Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.exaltedNPC, label = "Exalted NPC Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
			{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.dead, label = "Dead Color", enabled = function(factory) return factory:GetConfigValue("showUnitTip") end },
		}
	},
	-- BG Color
	{
		category = "BG Color",
		options = {
			{ type = "Check", var = "reactColoredBackdrop", label = "Color backdrop based on the unit's reaction", tip = "If you want the tip's background color to be determined by the unit's reaction towards you, enable this. With the option off, the background color will be the one selected on the 'Backdrop' page", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.tapped, label = "Tapped Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end, y = 10 },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.hostile, label = "Hostile Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.caution, label = "Caution Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.neutral, label = "Neutral Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer, label = "Friendly Player Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer, label = "Friendly PvP Player Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyNPC, label = "Friendly NPC Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.honoredNPC, label = "Honored NPC Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.reveredNPC, label = "Revered NPC Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.exaltedNPC, label = "Exalted NPC Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
			{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.dead, label = "Dead Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("reactColoredBackdrop") end },
		}
	},
	-- Backdrop
	{
		category = "Backdrop",
		enabled = { type = "Check", var = "enableBackdrop", tip = "Turns on or off all modifications of the backdrop\nNOTE: A Reload of the UI (/reload) is required for the setting to take affect" },
		options = {
			{ type = "DropDown", var = "tipBackdropBG", label = "Background Texture", media = "background", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			{ type = "DropDown", var = "tipBackdropBGLayout", label = "BG Texture Layout", list = { ["Repeat to fit tip"] = "tile", ["Stretch to fit tip"] = "stretch" }, enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			{ type = "DropDown", var = "tipBackdropEdge", label = "Border Texture", media = "border", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			
			{ type = "Slider", var = "backdropEdgeSize", label = "Backdrop Edge Size", min = -20, max = 64, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end, y = 10 },
			{ type = "Slider", var = "backdropInsets", label = "Backdrop Insets", min = -20, max = 20, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			{ type = "Check", var = "pixelPerfectBackdrop", label = "Pixel Perfect Backdrop Edge Size and Insets", tip = "Backdrop Edge Size and Insets corresponds to real pixels", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			
			{ type = "Color", var = "tipColor", label = "Tip Background Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end, y = 10 },
			{ type = "Color", var = "tipBorderColor", label = "Tip Border Color", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end, x = 160 },
			{ type = "Check", var = "gradientTip", label = "Show Gradient Tooltips", tip = "Display a small gradient area at the top of the tip to add a minor 3D effect to it. If you have an addon like Skinner, you may wish to disable this to avoid conflicts", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") end },
			{ type = "Color", var = "gradientColor", label = "Gradient Color", tip = "Select the base color for the gradient", enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("gradientTip") end, x = 160 },
			{ type = "Slider", var = "gradientHeight", label = "Gradient Height", min = 0, max = 64, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableBackdrop") and factory:GetConfigValue("gradientTip") end },
		}
	},
	-- Font
	{
		category = "Font",
		enabled = { type = "Check", var = "modifyFonts", tip = "For " .. PARENT_MOD_NAME .. " to change the GameTooltip font templates, and thus all tooltips in the User Interface, you have to enable this option.\nNOTE: If you have an addon such as ClearFont, it might conflict with this option." },
		options = {
			{ type = "DropDown", var = "fontFace", label = "Font Face", media = "font", enabled = function(factory) return factory:GetConfigValue("modifyFonts") end },
			{ type = "DropDown", var = "fontFlags", label = "Font Flags", list = DROPDOWN_FONTFLAGS, enabled = function(factory) return factory:GetConfigValue("modifyFonts") end },
			{ type = "Slider", var = "fontSize", label = "Font Size", min = 6, max = 29, step = 1, enabled = function(factory) return factory:GetConfigValue("modifyFonts") end },
			
			{ type = "Slider", var = "fontSizeDeltaHeader", label = "Font Size Header Delta", min = -10, max = 10, step = 1, enabled = function(factory) return factory:GetConfigValue("modifyFonts") end, y = 10 },
			{ type = "Slider", var = "fontSizeDeltaSmall", label = "Font Size Small Delta", min = -10, max = 10, step = 1, enabled = function(factory) return factory:GetConfigValue("modifyFonts") end },
		}
	},
	-- Classify
	{
		category = "Classify",
		options = {
			{ type = "Text", var = "classification_minus", label = "Minus" },
			{ type = "Text", var = "classification_trivial", label = "Trivial" },
			{ type = "Text", var = "classification_normal", label = "Normal" },
			{ type = "Text", var = "classification_elite", label = "Elite" },
			{ type = "Text", var = "classification_worldboss", label = "Boss" },
			{ type = "Text", var = "classification_rare", label = "Rare" },
			{ type = "Text", var = "classification_rareelite", label = "Rare Elite" },
		}
	},
	-- Fading
	{
		category = "Fading",
		options = {
			{ type = "Header", label = "Fading for Unit Tooltips" },
			
			{ type = "Check", var = "overrideFade", label = "Enable Override Default GameTooltip Fade for Unit Tooltips", tip = "Overrides the default fadeout function of the GameTooltip for units. If you are seeing problems regarding fadeout, please disable." },
			
			{ type = "Slider", var = "preFadeTime", label = "Prefade Time", min = 0, max = 5, step = 0.05, enabled = function(factory) return factory:GetConfigValue("overrideFade") end, y = 10 },
			{ type = "Slider", var = "fadeTime", label = "Fadeout Time", min = 0, max = 5, step = 0.05, enabled = function(factory) return factory:GetConfigValue("overrideFade") end },
			
			{ type = "Header", label = "Others" },
			
			{ type = "Check", var = "hideWorldTips", label = "Instantly Hide World Frame Tips", tip = "This option will make most tips which appear from objects in the world disappear instantly when you take the mouse off the object. Examples such as mailboxes, herbs or chests.\nNOTE: Does not work for all world objects." },
		}
	},
	-- Bars
	{
		category = "Bars",
		enabled = { type = "Check", var = "enableBars", tip = "Enable bars for unit tooltips" },
		options = {
			{ type = "Header", label = "Unit Tip Bars: Health Bar", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			
			{ type = "Check", var = "healthBar", label = "Show Health Bar", tip = "Will show a health bar of the unit.", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			{ type = "DropDown", var = "healthBarText", label = "Health Bar Text", list = DROPDOWN_BARTEXTFORMAT, enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("healthBar") end },
			{ type = "Color", var = "healthBarColor", label = "Health Bar Color", tip = "The color of the health bar. Has no effect for players with the option above enabled", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("healthBar") end },
			{ type = "Check", var = "healthBarClassColor", label = "Class Colored Health Bar", tip = "This options colors the health bar in the same color as the player class", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("healthBar") end, y = 2, x = 130 },
			{ type = "Check", var = "hideDefaultBar", label = "Hide the Default Health Bar", tip = "Check this to hide the default health bar", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			
			{ type = "Header", label = "Unit Tip Bars: Mana Bar", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			
			{ type = "Check", var = "manaBar", label = "Show Mana Bar", tip = "If the unit has mana, a mana bar will be shown.", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			{ type = "DropDown", var = "manaBarText", label = "Mana Bar Text", list = DROPDOWN_BARTEXTFORMAT, enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("manaBar") end },
			{ type = "Color", var = "manaBarColor", label = "Mana Bar Color", tip = "The color of the mana bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("manaBar") end },
			
			{ type = "Header", label = "Unit Tip Bars: Bar for other Power Types", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			
			{ type = "Check", var = "powerBar", label = "Show Bar for other Power Types\n(e.g. Energy, Rage, Runic Power or Focus)", tip = "If the unit uses other power types than mana (e.g. energy, rage, runic power or focus), a bar for that will be shown.", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			{ type = "DropDown", var = "powerBarText", label = "Power Bar Text", list = DROPDOWN_BARTEXTFORMAT, enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("powerBar") end },
			
			{ type = "Header", label = "Unit Tip Bars: Cast Bar", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			
			{ type = "Check", var = "castBar", label = "Show Cast Bar", tip = "Will show a cast bar of the unit.", enabled = function(factory) return factory:GetConfigValue("enableBars") end },
			{ type = "Check", var = "castBarAlwaysShow", label = "Always Show Cast Bar", tip = "Check this to always show the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end, x = 130 },
			{ type = "Color", var = "castBarCastingColor", label = "Cast Bar Casting Color", tip = "The casting color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end, y = 10 },
			{ type = "Color", var = "castBarChannelingColor", label = "Cast Bar Channeling Color", tip = "The channeling color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end },
			{ type = "Color", var = "castBarChargingColor", label = "Cast Bar Charging Color", tip = "The charging color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end },
			{ type = "Color", var = "castBarCompleteColor", label = "Cast Bar Complete Color", tip = "The complete color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end },
			{ type = "Color", var = "castBarFailColor", label = "Cast Bar Fail Color", tip = "The fail color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end },
			{ type = "Color", var = "castBarSparkColor", label = "Cast Bar Spark Color", tip = "The spark color of the cast bar", enabled = function(factory) return factory:GetConfigValue("enableBars") and factory:GetConfigValue("castBar") end },
			
			{ type = "Header", label = "Unit Tip Bars: Others", enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end },
			
			{ type = "Check", var = "barsCondenseValues", label = "Show Condensed Bar Values", tip = "You can enable this option to condense values shown on the bars. It does this by showing 57254 as 57.3k as an example", enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end },
			
			{ type = "DropDown", var = "barFontFace", label = "Font Face", media = "font", enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end, y = 10 },
			{ type = "DropDown", var = "barFontFlags", label = "Font Flags", list = DROPDOWN_FONTFLAGS, enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end },
			{ type = "Slider", var = "barFontSize", label = "Font Size", min = 6, max = 29, step = 1, enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end },
			
			{ type = "DropDown", var = "barTexture", label = "Bar Texture", media = "statusbar", enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end, y = 10 },
			{ type = "Slider", var = "barHeight", label = "Bar Height", min = 1, max = 50, step = 1, enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end },
			
			{ type = "Check", var = "barEnableTipMinimumWidth", label = "Enable Minimum Width for Tooltip If Showing Bars", tip = "Check this to enable a minimum width for the tooltip if showing bars, so that numbers are not cut off.", enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) end, y = 10 },
			{ type = "Slider", var = "barTipMinimumWidth", label = "Minimum Width for Tooltip", min = 10, max = 500, step = 5, enabled = function(factory) return factory:GetConfigValue("enableBars") and (factory:GetConfigValue("healthBar") or factory:GetConfigValue("manaBar") or factory:GetConfigValue("powerBar") or factory:GetConfigValue("castBar")) and factory:GetConfigValue("barEnableTipMinimumWidth") end },
		}
	},
	-- Auras
	{
		category = "Auras",
		enabled = { type = "Check", var = "enableAuras", tip = "Enable auras for unit tooltips" },
		options = {
			{ type = "Header", label = "Unit Tip Auras", enabled = function(factory) return factory:GetConfigValue("enableAuras") end },
			
			{ type = "Check", var = "showBuffs", label = "Show Unit Buffs", tip = "Show buffs of the unit", enabled = function(factory) return factory:GetConfigValue("enableAuras") end },
			{ type = "Check", var = "showDebuffs", label = "Show Unit Debuffs", tip = "Show debuffs of the unit", enabled = function(factory) return factory:GetConfigValue("enableAuras") end },
			
			{ type = "Check", var = "selfAurasOnly", label = "Only Show Auras Coming from You", tip = "This will filter out and only display auras you cast yourself", enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end, y = 10 },
			
			{ type = "Check", var = "showAuraCooldown", label = "Show Cooldown Models", tip = "With this option on, you will see a visual progress of the time left on the buff", enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end, y = 10 },
			{ type = "Check", var = "noCooldownCount", label = "No Cooldown Count Text", tip = "Tells cooldown enhancement addons, such as OmniCC, not to display cooldown text", enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end },
			
			{ type = "Slider", var = "auraSize", label = "Aura Icon Dimension", min = 8, max = 60, step = 1, enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end, y = 10 },
			{ type = "Slider", var = "auraMaxRows", label = "Max Aura Rows", min = 1, max = 8, step = 1, enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end },
		
			{ type = "Check", var = "aurasAtBottom", label = "Put Aura Icons at the Bottom Instead of Top", tip = "Puts the aura icons at the bottom of the tip instead of the default top", enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end, y = 10 },
			{ type = "Slider", var = "auraOffset", label = "Aura Offset", min = 0, max = 200, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableAuras") and (factory:GetConfigValue("showBuffs") or factory:GetConfigValue("showDebuffs")) end },
		}
	},
	-- Icons
	{
		category = "Icons",
		enabled = { type = "Check", var = "enableIcons", tip = "Turns on or off all additional icons next to the tooltip" },
		options = {
			{ type = "Header", label = "Unit Tip Icons", enabled = function(factory) return factory:GetConfigValue("enableIcons") end },
			
			{ type = "Check", var = "iconRaid", label = "Show Raid Icon", tip = "Shows the raid icon next to the tip", enabled = function(factory) return factory:GetConfigValue("enableIcons") end },
			{ type = "Check", var = "iconFaction", label = "Show Faction Icon", tip = "Shows the faction icon next to the tip, if the unit is flagged for PvP", enabled = function(factory) return factory:GetConfigValue("enableIcons") end },
			{ type = "Check", var = "iconCombat", label = "Show Combat Icon", tip = "Shows a combat icon next to the tip, if the unit is in combat", enabled = function(factory) return factory:GetConfigValue("enableIcons") end },
			{ type = "Check", var = "iconClass", label = "Show Class Icon", tip = "For players, this will display the class icon next to the tooltip", enabled = function(factory) return factory:GetConfigValue("enableIcons") end },
			
			{ type = "Slider", var = "iconSize", label = "Icon Size", min = 8, max = 100, step = 1, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end },
			{ type = "Slider", var = "iconMaxIcons", label = "Max Icons", min = 1, max = 4, step = 1, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end },
			{ type = "DropDown", var = "iconAnchor", label = "Icon Anchor", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end, y = 10 },
			{ type = "DropDown", var = "iconAnchorHorizontalAlign", label = "Horizontal Alignment", list = DROPDOWN_ANCHORHALIGN, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) and (factory:GetConfigValue("iconAnchor") == "TOP" or factory:GetConfigValue("iconAnchor") == "BOTTOM") end },
			{ type = "DropDown", var = "iconAnchorVerticalAlign", label = "Vertical Alignment", list = DROPDOWN_ANCHORVALIGN, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) and (factory:GetConfigValue("iconAnchor") == "LEFT" or factory:GetConfigValue("iconAnchor") == "RIGHT") end },
			{ type = "DropDown", var = "iconAnchorGrowDirection", label = "Grow Direction", list = DROPDOWN_ANCHORGROWDIRECTION, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end },
			{ type = "Slider", var = "iconOffsetX", label = "Icon X Offset", min = -200, max = 200, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end },
			{ type = "Slider", var = "iconOffsetY", label = "Icon Y Offset", min = -200, max = 200, step = 0.5, enabled = function(factory) return factory:GetConfigValue("enableIcons") and (factory:GetConfigValue("iconRaid") or factory:GetConfigValue("iconFaction") or factory:GetConfigValue("iconCombat") or factory:GetConfigValue("iconClass")) end },
		}
	},
	-- Anchors
	{
		category = "Anchors",
		enabled = { type = "Check", var = "enableAnchor", tip = "Turns on or off all modifications of the anchor" },
		options = ttOptionsAnchors
	},
	-- Hiding
	{
		category = "Hiding",
		options = ttOptionsHiding
	},
	-- Hyperlink
	{
		category = "Hyperlink",
		enabled = { type = "Check", var = "enableChatHoverTips", label = "Enable (Guild & Community) ChatFrame Hover Hyperlinks", tip = "When hovering the mouse over a link in the (Guild & Community) Chatframe, show the tooltip without having to click on it" }
 	},
	-- Layouts
	{
		category = "Layouts",
		options = {
			{ type = "DropDown", label = "Layout Template", init = TipTacLayouts.LoadLayout_Init },
--			{ type = "Text", label = "Save Layout", func = nil },
--			{ type = "DropDown", label = "Delete Layout", init = TipTacLayouts.DeleteLayout_Init },
		}
	},
};

-- TipTacTalents Support
local TipTacTalents = _G[PARENT_MOD_NAME .. "Talents"];

if (TipTacTalents) then
	local tttOptions = {
		{ type = "Header", label = "Talents", enabled = function(factory) return factory:GetConfigValue("t_enable") end }
	};
	
	tinsert(tttOptions, { type = "Check", var = "t_talentOnlyInParty", label = "Only Show Talents and Average Item Level\nfor Party and Raid Members", tip = "When you enable this, only talents and average item level of players in your party or raid will be requested and shown", enabled = function(factory) return factory:GetConfigValue("t_enable") end, y = 5 });
	
	option = { type = "Check", var = "t_showTalents", label = "Show Talents", tip = "This option makes the tip show the talent specialization of other players", enabled = function(factory) return factory:GetConfigValue("t_enable") end, y = 10 };
	if (not LibFroznFunctions.hasWoWFlavor.talentsAvailableForInspectedUnit) then
		option.tip = option.tip .. ".\nNOTE: Inspecting other players' talents isn't available in Classic Era. Only own talents (available at level 10) will be shown.";
	end
	tinsert(tttOptions, option);
	
	if (LibFroznFunctions.hasWoWFlavor.roleIconAvailable) then
		tinsert(tttOptions, { type = "Check", var = "t_showRoleIcon", label = "Show Role Icon", tip = "This option makes the tip show the role icon (tank, damager, healer)", enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") end });
	end
	if (LibFroznFunctions.hasWoWFlavor.talentIconAvailable) then
		tinsert(tttOptions, { type = "Check", var = "t_showTalentIcon", label = "Show Talent Icon", tip = "This option makes the tip show the talent icon", enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") end });
	end
	
	tinsert(tttOptions, { type = "Check", var = "t_showTalentText", label = "Show Talent Text", tip = "This option makes the tip show the talent text", enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") end, y = 10 });
	tinsert(tttOptions, { type = "Check", var = "t_colorTalentTextByClass", label = "Color Talent Text by Class Color", tip = "With this option on, talent text is colored by their class color", enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") and factory:GetConfigValue("t_showTalentText") end });
	
	if (LibFroznFunctions.hasWoWFlavor.numTalentTrees > 0) then
		if (LibFroznFunctions.hasWoWFlavor.numTalentTrees == 2) then
			tinsert(tttOptions, { type = "DropDown", var = "t_talentFormat", label = "Talent Text Format", list = { ["Elemental (31/30)"] = 1, ["Elemental"] = 2, ["31/30"] = 3,}, enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") and factory:GetConfigValue("t_showTalentText") end }); -- not supported with MoP changes
		else
			tinsert(tttOptions, { type = "DropDown", var = "t_talentFormat", label = "Talent Text Format", list = { ["Elemental (57/14/0)"] = 1, ["Elemental"] = 2, ["57/14/0"] = 3,}, enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showTalents") and factory:GetConfigValue("t_showTalentText") end }); -- not supported with MoP changes
		end
	end
	
	tinsert(tttOptions, { type = "Header", label = "Average Item Level", enabled = function(factory) return factory:GetConfigValue("t_enable") end });
	
	tinsert(tttOptions, { type = "Check", var = "t_showAverageItemLevel", label = "Show Average Item Level (AIL)", tip = "This option makes the tip show the average item level (AIL) of other players", enabled = function(factory) return factory:GetConfigValue("t_enable") end });
	
	tinsert(tttOptions, { type = "Check", var = "t_showGearScore", label = "Show GearScore", tip = "This option makes the tip show the GearScore of other players", enabled = function(factory) return factory:GetConfigValue("t_enable") end, y = 10 });
	tinsert(tttOptions, { type = "DropDown", var = "t_gearScoreAlgorithm", label = "GearScore Algorithm", list = { ["TacoTip"] = { value = 1, tip = "The de-facto standard algorithm from addon TacoTip" }, ["TipTac"] = { value = 2, tip = PARENT_MOD_NAME .. "'s own implementation to simply calculate the GearScore is used here. This is the sum of all item levels weighted by performance per item level above/below base level of first tier set of current expansion, inventory type and item quality. Inventory slots for shirt, tabard and ranged are excluded." },}, tip = "Switch between different GearScore implementations", enabled = function(factory) return factory:GetConfigValue("t_enable") and factory:GetConfigValue("t_showGearScore") end });
	
	tinsert(tttOptions, { type = "Check", var = "t_colorAILAndGSTextByQuality", label = "Color Average Item Level and GearScore Text\nby Quality Color", tip = "With this option on, average item level and GearScore text is colored by the quality", enabled = function(factory) return factory:GetConfigValue("t_enable") and (factory:GetConfigValue("t_showAverageItemLevel") or factory:GetConfigValue("t_showGearScore")) end, y = 10 });
	
	tinsert(options, {
		category = "Talents/AIL",
		enabled = { type = "Check", var = "t_enable", tip = "Turns on or off all features of the TipTacTalents addon" },
		options = tttOptions
	});
end

-- TipTacItemRef Support -- Az: this category page is full -- Frozn45: added scroll frame to config options. the scroll bar appears automatically, if content doesn't fit completely on the page.
local TipTacItemRef = _G[PARENT_MOD_NAME .. "ItemRef"];

if (TipTacItemRef) then
	local ttifOptions = {
		{ type = "Color", var = "if_infoColor", label = "Information Color", tip = "The color of the various tooltip lines added by these options", enabled = function(factory) return factory:GetConfigValue("if_enable") end },

		{ type = "Check", var = "if_itemQualityBorder", label = "Show Item Tips with Quality Colored Border", tip = "When enabled and the tip is showing an item, the tip border will have the color of the item's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 },
		{ type = "Check", var = "if_showItemLevel", label = "Show Item Level", tip = "For item tooltips, show their itemLevel (Combines with itemID).\nNOTE: This will remove the default itemLevel text shown in tooltips", enabled = function(factory) return factory:GetConfigValue("if_enable") end },
		{ type = "Check", var = "if_showItemId", label = "Show Item ID", tip = "For item tooltips, show their itemID (Combines with itemLevel)", enabled = function(factory) return factory:GetConfigValue("if_enable") end, x = 160 }
	};
	
	if (LibFroznFunctions.hasWoWFlavor.relatedExpansionForItemAvailable) then
		tinsert(ttifOptions, { type = "Check", var = "if_showExpansionIcon", label = "Show Expansion Icon", tip = "For item tooltips, show their expansion icon", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
		tinsert(ttifOptions, { type = "Check", var = "if_showExpansionName", label = "Show Expansion Name", tip = "For item tooltips, show their expansion name", enabled = function(factory) return factory:GetConfigValue("if_enable") end, x = 160 });
	end
	
	tinsert(ttifOptions, { type = "Check", var = "if_showKeystoneRewardLevel", label = "Show Keystone (Weekly) Reward Level", tip = "For keystone tooltips, show their rewardLevel and weeklyRewardLevel", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showKeystoneTimeLimit", label = "Show Keystone Time Limit", tip = "For keystone tooltips, show the instance timeLimit", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showKeystoneAffixInfo", label = "Show Keystone Affix Infos", tip = "For keystone tooltips, show the affix infos", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_modifyKeystoneTips", label = "Modify Keystone Tooltips", tip = "Changes the keystone tooltips to show a bit more information\nWarning: Might conflict with other keystone addons", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_spellColoredBorder", label = "Show Spell Tips with Colored Border", tip = "When enabled and the tip is showing a spell, the tip border will have the standard spell color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showSpellIdAndRank", label = "Show Spell ID & Rank/Subtext", tip = "For spell tooltips, show their spellID and spellRank/subtext", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_auraSpellColoredBorder", label = "Show Aura Tips with Colored Border", tip = "When enabled and the tip is showing a buff or debuff, the tip border will have the standard spell color", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showAuraSpellIdAndRank", label = "Show Aura Spell ID & Rank/Subtext", tip = "For buff and debuff tooltips, show their spellID and spellRank/subtext", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showMawPowerId", label = "Show Maw Power ID", tip = "For spell and aura tooltips, show their mawPowerID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_showAuraCaster", label = "Show Aura Tooltip Caster", tip = "When showing buff and debuff tooltips, it will add an extra line, showing who cast the specific aura", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_colorAuraCasterByReaction", label = "Color Aura Tooltip Caster by Reaction", tip = "Aura tooltip caster color will have the same color as the reaction\nNOTE: This option is overridden by class colored aura tooltip caster for players", enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showAuraCaster") end });
	tinsert(ttifOptions, { type = "Check", var = "if_colorAuraCasterByClass", label = "Color Aura Tooltip Caster for Player by Class Color", tip = "With this option on, color aura tooltip caster for players are colored by their class color\nNOTE: This option overrides reaction colored aura tooltip caster for players", enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showAuraCaster") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_showNpcId", label = "Show NPC ID", tip = "For npc or battle pet tooltips, show their npcID", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showMountId", label = "Show Mount ID", tip = "For item, spell and aura tooltips, show their mountID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_questDifficultyBorder", label = "Show Quest Tips with Difficulty Colored Border", tip = "When enabled and the tip is showing a quest, the tip border will have the color of the quest's difficulty", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showQuestLevel", label = "Show Quest Level", tip = "For quest tooltips, show their questLevel (Combines with questID)", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showQuestId", label = "Show Quest ID", tip = "For quest tooltips, show their questID (Combines with questLevel)", enabled = function(factory) return factory:GetConfigValue("if_enable") end, x = 160 });
	
	tinsert(ttifOptions, { type = "Check", var = "if_currencyQualityBorder", label = "Show Currency Tips with Quality Colored Border", tip = "When enabled and the tip is showing a currency, the tip border will have the color of the currency's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showCurrencyId", label = "Show Currency ID", tip = "Currency items will now show their ID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_achievmentColoredBorder", label = "Show Achievement Tips with Colored Border", tip = "When enabled and the tip is showing an achievement, the tip border will have the the standard achievement color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showAchievementIdAndCategoryId", label = "Show Achievement ID & Category", tip = "On achievement tooltips, the achievement ID as well as the category will be shown", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_modifyAchievementTips", label = "Modify Achievement Tooltips", tip = "Changes the achievement tooltips to show a bit more information\nWarning: Might conflict with other achievement addons", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_battlePetQualityBorder", label = "Show Battle Pet Tips with Quality Colored Border", tip = "When enabled and the tip is showing a battle pet, the tip border will have the color of the battle pet's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showBattlePetLevel", label = "Show Battle Pet Level", tip = "For battle bet tooltips, show their petLevel (Combines with npcID)", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_battlePetAbilityColoredBorder", label = "Show Battle Pet Ability Tips with Colored Border", tip = "When enabled and the tip is showing a battle pet ability, the tip border will have the the standard battle pet ability color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showBattlePetAbilityId", label = "Show Battle Pet Ability ID", tip = "For battle bet ability tooltips, show their abilityID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_transmogAppearanceItemQualityBorder", label = "Show Transmog Appearance Item Tips with Quality Colored Border", tip = "When enabled and the tip is showing an transmog appearance item, the tip border will have the color of the transmog appearance item's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showTransmogAppearanceItemId", label = "Show Transmog Appearance Item ID", tip = "For transmog appearance item tooltips, show their itemID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_transmogIllusionColoredBorder", label = "Show Transmog Illusion Tips with Colored Border", tip = "When enabled and the tip is showing a transmog illusion, the tip border will have the the standard transmog illusion color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showTransmogIllusionId", label = "Show Transmog Illusion ID", tip = "For transmog illusion tooltips, show their illusionID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_transmogSetQualityBorder", label = "Show Transmog Set Tips with Quality Colored Border", tip = "When enabled and the tip is showing an transmog set, the tip border will have the color of the transmog set's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showTransmogSetId", label = "Show Transmog Set ID", tip = "For transmog set tooltips, show their setID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_conduitQualityBorder", label = "Show Conduit Tips with Quality Colored Border", tip = "When enabled and the tip is showing a conduit, the tip border will have the color of the conduit's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showConduitItemLevel", label = "Show Conduit Item Level", tip = "For conduit tooltips, show their itemLevel (Combines with conduitID)", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showConduitId", label = "Show Conduit ID", tip = "For conduit tooltips, show their conduitID (Combines with conduit itemLevel)", enabled = function(factory) return factory:GetConfigValue("if_enable") end, x = 160 });
	
	tinsert(ttifOptions, { type = "Check", var = "if_azeriteEssenceQualityBorder", label = "Show Azerite Essence Tips with Quality Colored Border", tip = "When enabled and the tip is showing an azerite essence, the tip border will have the color of the azerite essence's quality", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showAzeriteEssenceId", label = "Show Azerite Essence ID", tip = "For azerite essence tooltips, show their essenceID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_runeforgePowerColoredBorder", label = "Show Runeforge Power Tips with Colored Border", tip = "When enabled and the tip is showing a runeforge power, the tip border will have the the standard runeforge power color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showRuneforgePowerId", label = "Show Runeforge Power ID", tip = "For runeforge power tooltips, show their runeforgePowerID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_flyoutColoredBorder", label = "Show Flyout Tips with Colored Border", tip = "When enabled and the tip is showing a flyout, the tip border will have the the standard spell color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showFlyoutId", label = "Show Flyout ID", tip = "For flyout tooltips, show their flyoutID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_petActionColoredBorder", label = "Show Pet Action Tips with Colored Border", tip = "When enabled and the tip is showing a pet action, the tip border will have the the standard spell color", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	tinsert(ttifOptions, { type = "Check", var = "if_showPetActionId", label = "Show Pet Action ID", tip = "For flyout tooltips, show their petActionID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_showInstanceLockDifficulty", label = "Show Instance Lock Difficulty", tip = "For instance lock tooltips, show their difficulty", enabled = function(factory) return factory:GetConfigValue("if_enable") end, y = 10 });
	
	tinsert(ttifOptions, { type = "Header", label = "Icon", tip = "Settings about tooltip icon", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	
	tinsert(ttifOptions, { type = "Check", var = "if_showIcon", label = "Show Icon Texture and Stack Count (when available)", tip = "Shows an icon next to the tooltip. For items, the stack count will also be shown", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_smartIcons", label = "Smart Icon Appearance", tip = "When enabled, TipTacItemRef will determine if an icon is needed, based on where the tip is shown. It will not be shown on actionbars or bag slots for example, as they already show an icon", enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "DropDown", var = "if_stackCountToTooltip", label = "Show Stack Count in\nTooltip", list = { ["|cffffa0a0Do not show"] = "none", ["Always"] = "always", ["Only if icon is not shown"] = "noicon" }, enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_showIconId", label = "Show Icon ID", tip = "For tooltips with icon, show their iconID", enabled = function(factory) return factory:GetConfigValue("if_enable") end });
	tinsert(ttifOptions, { type = "Check", var = "if_borderlessIcons", label = "Borderless Icons", tip = "Turn off the border on icons", enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "Slider", var = "if_iconSize", label = "Icon Size", min = 16, max = 128, step = 1, enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "DropDown", var = "if_iconAnchor", label = "Icon Anchor", tip = "The anchor of the icon", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "DropDown", var = "if_iconTooltipAnchor", label = "Icon Tooltip Anchor", tip = "The anchor of the tooltip that the icon should anchor to.", list = DROPDOWN_ANCHORPOS, enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "Slider", var = "if_iconOffsetX", label = "Icon X Offset", min = -200, max = 200, step = 0.5, enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	tinsert(ttifOptions, { type = "Slider", var = "if_iconOffsetY", label = "Icon Y Offset", min = -200, max = 200, step = 0.5, enabled = function(factory) return factory:GetConfigValue("if_enable") and factory:GetConfigValue("if_showIcon") end });
	
	tinsert(options, {
		category = "ItemRef",
		enabled = { type = "Check", var = "if_enable", tip = "Turns on or off all features of the TipTacItemRef addon" },
		options = ttifOptions
	});
end

--------------------------------------------------------------------------------------------------------
--                                          Initialize Frame                                          --
--------------------------------------------------------------------------------------------------------

local f = CreateFrame("Frame",MOD_NAME,UIParent,BackdropTemplateMixin and "BackdropTemplate");	-- 9.0.1: Using BackdropTemplate

tinsert(UISpecialFrames, f:GetName()); -- hopefully no taint

f.options = options;

f:SetSize(360 + TT_OPTIONS_CATEGORY_LIST_WIDTH,378);
f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = 1, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } });
f:SetBackdropColor(0.1,0.22,0.35,1);
f:SetBackdropBorderColor(0.1,0.1,0.1,1);
f:EnableMouse(true);
f:SetMovable(true);
f:SetFrameStrata("DIALOG");
f:SetToplevel(true);
f:SetClampedToScreen(true);
f:SetScript("OnShow",function(self) self:BuildCategoryList(); self:BuildCategoryPage(); end);
f:Hide();

f.outline = CreateFrame("Frame",nil,f,BackdropTemplateMixin and "BackdropTemplate");	-- 9.0.1: Using BackdropTemplate
f.outline:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = 1, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } });
f.outline:SetBackdropColor(0.1,0.1,0.2,1);
f.outline:SetBackdropBorderColor(0.8,0.8,0.9,0.4);
f.outline:SetPoint("TOPLEFT",12,-12);
f.outline:SetPoint("BOTTOMLEFT",12,12);
f.outline:SetWidth(TT_OPTIONS_CATEGORY_LIST_WIDTH);

f:SetScript("OnMouseDown",f.StartMoving);
f:SetScript("OnMouseUp",function(self) self:StopMovingOrSizing(); cfg.optionsLeft = self:GetLeft(); cfg.optionsBottom = self:GetBottom(); end);

if (cfg.optionsLeft) and (cfg.optionsBottom) then
	f:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",cfg.optionsLeft,cfg.optionsBottom);
else
	f:SetPoint("CENTER");
end

f.header = f:CreateFontString(nil,"ARTWORK","GameFontHighlight");
f.header:SetFont(GameFontNormal:GetFont(),22,"THICKOUTLINE");
f.header:SetPoint("TOPLEFT",f.outline,"TOPRIGHT",9,-4);
f.header:SetText(CreateTextureMarkup("Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\tiptac_logo", 256, 256, nil, nil, 0, 1, 0, 1) .. " " .. PARENT_MOD_NAME.." Options");

f.vers = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall");
f.vers:SetPoint("TOPRIGHT",-15,-15);
local versionTipTac = C_AddOns.GetAddOnMetadata(PARENT_MOD_NAME, "Version");
local versionWoW, build = GetBuildInfo();
f.vers:SetText(PARENT_MOD_NAME .. ": " .. versionTipTac .. "\nWoW: " .. versionWoW);
f.vers:SetTextColor(1,1,0.5);

local function Anchor_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Anchor", 1, 1, 1);
	GameTooltip:AddLine("Click to toggle visibility of " .. PARENT_MOD_NAME .. "'s anchor to set the position for default anchored tooltips.", nil, nil, nil, 1);
	GameTooltip:Show();
end

local function Anchor_OnLeave(self)
	GameTooltip:Hide();
end

f.btnAnchor = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnAnchor:SetSize(75,24);
f.btnAnchor:SetPoint("BOTTOMLEFT",f.outline,"BOTTOMRIGHT",9,1);
local TipTac = _G[PARENT_MOD_NAME];
f.btnAnchor:SetScript("OnClick",function() TipTac:SetShown(not TipTac:IsShown()) end);
f.btnAnchor:SetScript("OnEnter", Anchor_OnEnter);
f.btnAnchor:SetScript("OnLeave", Anchor_OnLeave);
f.btnAnchor:SetText("Anchor");

local function Reset_OnClick(self)
	for index, option in ipairs(f.options[activePage].options or {}) do
		if (option.var) then
			cfg[option.var] = nil;	-- when cleared, they will read the default value from the metatable
		end
	end
	TipTac:ApplyConfig();
	f:BuildCategoryPage();
	f:BuildCategoryList();
end

local function Reset_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Defaults", 1, 1, 1);
	GameTooltip:AddLine("Reset options of current page to default settings.", nil, nil, nil, 1);
	GameTooltip:Show();
end

local function Reset_OnLeave(self)
	GameTooltip:Hide();
end

f.btnMisc = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnMisc:SetSize(75,24);
f.btnMisc:SetPoint("LEFT",f.btnAnchor,"RIGHT",9,0);
f.btnMisc:SetScript("OnClick",Reset_OnClick);
f.btnMisc:SetScript("OnEnter", Reset_OnEnter);
f.btnMisc:SetScript("OnLeave", Reset_OnLeave);
f.btnMisc:SetText("Defaults");

local function Misc_OnClick(self)
	ToggleDropDownMenu(1, nil, f.btnReport.dropDownMenu, f.btnReport, 0, 0);
end

local function Misc_SettingsDropDownOnClick(dropDownMenuButton, arg1, arg2)
	if (arg1 == "settingsImport") then
		-- open popup to get import string with new config
		LibFroznFunctions:ShowPopupWithText({
			prompt = "Paste export string with new config:",
			iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents",
			iconTexCoord = { 0.924316, 0.944824, 0.0380859, 0.0771484 },
			acceptButtonText = "Import",
			cancelButtonText = "Cancel",
			onShowHandler = function(self, data)
				-- fix icon position
				local alertIcon = _G[self:GetName() .. "AlertIcon"];
				
				if (not alertIcon) then
					return;
				end
				
				alertIcon:ClearAllPoints();
				alertIcon:SetPoint("LEFT", 24, 4);
			end,
			onAcceptHandler = function(self, data)
				-- import export string with new config
				local encodedConfig = self.editBox:GetText();
				local compressedConfig = LibDeflate:DecodeForPrint(encodedConfig);
				
				local function addFailedMessageToChatFrame()
					TipTac:AddMessageToChatFrame("{caption:" .. PARENT_MOD_NAME .. "}: {error:Couldn't import new config. Export string may be corrupt.}");
				end
				
				if (not compressedConfig) then
					addFailedMessageToChatFrame();
					return;
				end
				
				local serializedConfig = LibDeflate:DecompressDeflate(compressedConfig);
				
				if (not serializedConfig) then
					addFailedMessageToChatFrame();
					return;
				end
				
				local success, newCfg = LibSerialize:Deserialize(serializedConfig);
				
				if (not success) or (type(newCfg) ~= "table") then
					addFailedMessageToChatFrame();
					return;
				end
				
				-- apply new config
				LibFroznFunctions:MixinWholeObjects(cfg, newCfg);
				
				-- inform group that the config has been loaded
				-- LibFroznFunctions:FireGroupEvent(PARENT_MOD_NAME, "OnConfigLoaded", TT_CacheForFrames, cfg, TT_ExtendedConfig);
				
				-- apply config
				TipTac:ApplyConfig();
				f:BuildCategoryPage();
				f:BuildCategoryList();
				
				TipTac:AddMessageToChatFrame("{caption:" .. PARENT_MOD_NAME .. "}: Successfully imported new config.");
			end
		});
	elseif (arg1 == "settingsExport") then
		-- build export string with current config
		local serializedConfig = LibSerialize:Serialize(cfg);
		local compressedConfig = LibDeflate:CompressDeflate(serializedConfig);
		local encodedConfig = LibDeflate:EncodeForPrint(compressedConfig);
		
		-- open popup with export string with current config
		if (encodedConfig) then
			LibFroznFunctions:ShowPopupWithText({
				prompt = "Copy this export string with current config:",
				lockedText = encodedConfig,
				iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents",
				iconTexCoord = { 0.924316, 0.942871, 0.000976562, 0.0361328 },
				acceptButtonText = "Close",
				onShowHandler = function(self, data)
					-- fix icon position
					local alertIcon = _G[self:GetName() .. "AlertIcon"];
					
					if (not alertIcon) then
						return;
					end
					
					alertIcon:ClearAllPoints();
					alertIcon:SetPoint("LEFT", 24, 3);
				end
			});
		end
	end
	
	-- close dropdown
	CloseDropDownMenus();
end

local function Misc_ReportDropDownOnClick(dropDownMenuButton, arg1, arg2)
	-- build url
	local url;
	
	if (arg1 == "reportBug") then
		if (arg2 == "onGitHub") then
			url = LibFroznFunctions:ReplaceText("https://github.com/frozn/TipTac/issues/new?template=1_bug_report.yml&labels=1_bug&version-tiptac={versionTipTac}&version-wow={versionWoW}", {
				["{versionTipTac}"] = versionTipTac,
				["{versionWoW}"] = versionWoW
			});
		elseif (arg2 == "onCurseForge") then
			url = "https://www.curseforge.com/wow/addons/tiptac-reborn/comments";
		end
	elseif (arg1 == "requestFeature") then
		if (arg2 == "onGitHub") then
			url = "https://github.com/frozn/TipTac/issues/new?template=2_feature_request.yml&labels=1_enhancement";
		elseif (arg2 == "onCurseForge") then
			url = "https://www.curseforge.com/wow/addons/tiptac-reborn/comments";
		end
	end
	
	-- set icon
	local iconFile;
	
	if (arg2 == "onGitHub") then
		iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\github";
	elseif (arg2 == "onCurseForge") then
		iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\curseforge";
	end
	
	-- open popup with url
	if (url) then
		LibFroznFunctions:ShowPopupWithText({
			prompt = "Open this link in your web browser:",
			lockedText = url,
			iconFile = iconFile,
			acceptButtonText = "Close",
			onShowHandler = function(self, data)
				-- fix icon position
				local alertIcon = _G[self:GetName() .. "AlertIcon"];
				
				if (not alertIcon) then
					return;
				end
				
				alertIcon:ClearAllPoints();
				alertIcon:SetPoint("LEFT", 24, 5);
			end
		});
	end
	
	-- close dropdown
	CloseDropDownMenus();
end

local function Misc_DropDownOnInitialize(dropDownMenu, level, menuList)
	local list = LibFroznFunctions:CreatePushArray();
	
	if (level == 1) then
		list:Push({
			iconText = { "Interface\\HelpFrame\\HelpIcon-CharacterStuck", 64, 64, nil, nil, 0.1875, 0.796875, 0.203125, 0.796875 },
			text = "Settings",
			menuList = "settings"
		});
		list:Push({
			iconText = { "Interface\\HelpFrame\\ReportLagIcon-Mail", 64, 64, nil, nil, 0.171875, 0.828125, 0.21875, 0.78125 },
			text = "Report",
			menuList = "report"
		});
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\CommonIcons", 64, 64, nil, nil, 0.126465, 0.251465, 0.504883, 0.754883 },
			text = "Cancel",
			func = Misc_SettingsDropDownOnClick,
			arg1 = "cancel"
		});
	elseif (menuList == "settings") then
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents", 2048, 1024, nil, nil, 0.924316, 0.944824, 0.0380859, 0.0771484 },
			text = "Import",
			func = Misc_SettingsDropDownOnClick,
			arg1 = "settingsImport"
		});
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents", 2048, 1024, nil, nil, 0.924316, 0.942871, 0.000976562, 0.0361328 },
			text = "Export",
			func = Misc_SettingsDropDownOnClick,
			arg1 = "settingsExport"
		});
	elseif (menuList == "report") then
		list:Push({
			iconText = { "Interface\\HelpFrame\\HelpIcon-Bug", 64, 64, nil, nil, 0.1875, 0.78125, 0.1875, 0.78125 },
			text = "Report bug",
			menuList = "reportBug"
		});
		list:Push({
			iconText = { "Interface\\HelpFrame\\HelpIcon-Suggestion", 64, 64, nil, nil, 0.21875, 0.765625, 0.234375, 0.78125 },
			text = "Request feature",
			menuList = "requestFeature"
		});
	elseif (menuList == "reportBug") then
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\github", 32, 32, nil, nil, 0, 1, 0, 1 },
			text = "on GitHub (preferred)",
			func = Misc_ReportDropDownOnClick,
			arg1 = "reportBug",
			arg2 = "onGitHub"
		});
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\curseforge", 32, 32, nil, nil, 0, 1, 0, 1 },
			text = "on CurseForge",
			func = Misc_ReportDropDownOnClick,
			arg1 = "reportBug",
			arg2 = "onCurseForge"
		});
	elseif (menuList == "requestFeature") then
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\github", 32, 32, nil, nil, 0, 1, 0, 1 },
			text = "on GitHub (preferred)",
			func = Misc_ReportDropDownOnClick,
			arg1 = "requestFeature",
			arg2 = "onGitHub"
		});
		list:Push({
			iconText = { "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\curseforge", 32, 32, nil, nil, 0, 1, 0, 1 },
			text = "on CurseForge",
			func = Misc_ReportDropDownOnClick,
			arg1 = "requestFeature",
			arg2 = "onCurseForge"
		});
	end
	
	if (list:GetCount() > 0) then
		for _, item in ipairs(list) do
			local info = UIDropDownMenu_CreateInfo();
			
			info.text = (item.iconText and (CreateTextureMarkup(unpack(item.iconText)) .. " ") or "") .. item.text;
			
			if (item.menuList) then
				info.hasArrow = true;
				info.menuList = item.menuList;
				info.keepShownOnClick = true;
			else
				info.func = item.func;
				info.arg1 = item.arg1;
				info.arg2 = item.arg2;
			end
			
			info.notCheckable = true;
			
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

local function Misc_OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	GameTooltip:AddLine("Misc", 1, 1, 1);
	GameTooltip:AddLine("Import/Export settings, report bugs or request features.", nil, nil, nil, 1);
	GameTooltip:Show();
end

local function Misc_OnLeave(self)
	GameTooltip:Hide();
end

f.btnReport = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnReport:SetSize(75,24);
f.btnReport:SetPoint("LEFT",f.btnMisc,"RIGHT",9,0);
f.btnReport:SetScript("OnClick", Misc_OnClick);
f.btnReport:SetScript("OnEnter", Misc_OnEnter);
f.btnReport:SetScript("OnLeave", Misc_OnLeave);
f.btnReport:SetText("Misc");

f.btnReport.dropDownMenu = CreateFrame("Frame", nil, f.btnReport, "UIDropDownMenuTemplate");
UIDropDownMenu_Initialize(f.btnReport.dropDownMenu, Misc_DropDownOnInitialize, "MENU");

f.btnClose = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnClose:SetSize(75,24);
f.btnClose:SetPoint("LEFT",f.btnReport,"RIGHT",10,0);
f.btnClose:SetScript("OnClick",function() f:Hide(); end);
f.btnClose:SetText("Close");

local function SetScroll(value)
	local status = f.scrollFrame.status or f.scrollFrame.localstatus;
	local viewheight = f.scrollFrame:GetHeight();
	local height = f.content:GetHeight();
	local offset;

	if viewheight > height then
		offset = 0;
	else
		offset = floor((height - viewheight) / 1000.0 * value);
	end
	f.content:ClearAllPoints();
	f.content:SetPoint("TOPLEFT", 0, offset);
	f.content:SetPoint("TOPRIGHT", 0, offset);
	status.offset = offset;
	status.scrollvalue = value;
end

local function MoveScroll(self, value)
	local status = f.scrollFrame.status or f.scrollFrame.localstatus;
	local height, viewheight = f.scrollFrame:GetHeight(), f.content:GetHeight();

	if self.scrollBarShown then
		local diff = height - viewheight;
		local delta = 1;
		if value < 0 then
			delta = -1;
		end
		f.scrollBar:SetValue(min(max(status.scrollvalue + delta*(1000/(diff/45)),0), 1000));
	end
end

local function FixScroll(self)
	if self.updateLock then return end
	self.updateLock = true;
	local status = f.scrollFrame.status or f.scrollFrame.localstatus;
	local height, viewheight = f.scrollFrame:GetHeight(), f.content:GetHeight();
	local offset = status.offset or 0;
	-- Give us a margin of error of 2 pixels to stop some conditions that i would blame on floating point inaccuracys
	-- No-one is going to miss 2 pixels at the bottom of the frame, anyhow!
	if viewheight < height + 2 then
		if self.scrollBarShown then
			self.scrollBarShown = nil;
			f.scrollBar:Hide();
			f.scrollBar:SetValue(0);
			local scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs = f.scrollFrame:GetPoint(3);
			scrollFrameBottomRightXOfs = -13;
			f.scrollFrame:SetPoint(scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs);
			if f.content.original_width then
				f.content:SetWidth(f.content.original_width);
			end
		end
	else
		if not self.scrollBarShown then
			self.scrollBarShown = true;
			f.scrollBar:Show();
			local scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs = f.scrollFrame:GetPoint(3);
			scrollFrameBottomRightXOfs = -33;
			f.scrollFrame:SetPoint(scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs);
			if f.content.original_width then
				f.content:SetWidth(f.content.original_width - 20);
			end
		end
		local value = (offset / (viewheight - height) * 1000);
		if value > 1000 then value = 1000 end
		f.scrollBar:SetValue(value);
		SetScroll(value);
		if value < 1000 then
			f.content:ClearAllPoints();
			f.content:SetPoint("TOPLEFT", 0, offset);
			f.content:SetPoint("TOPRIGHT", 0, offset);
			status.offset = offset;
		end
	end
	self.updateLock = nil;
end

local function FixScrollOnUpdate(frame)
	frame:SetScript("OnUpdate", nil);
	FixScroll(frame);
end

local function ScrollFrame_OnMouseWheel(frame, value)
	MoveScroll(frame, value);
end

local function ScrollFrame_OnSizeChanged(frame)
	frame:SetScript("OnUpdate", FixScrollOnUpdate);
end

f.scrollFrame = CreateFrame("ScrollFrame", nil, f);
f.scrollFrame.status = {};
f.scrollFrame:SetPoint("TOP", f.header, "BOTTOM", 0, -12);
f.scrollFrame:SetPoint("LEFT", f.outline, "RIGHT", 0, 9);
f.scrollFrame:SetPoint("BOTTOM", f.btnClose, "TOP", 0, 9);
f.scrollFrame:SetPoint("RIGHT", f, "RIGHT", -13, 0);
f.scrollFrame:EnableMouseWheel(true);
f.scrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
f.scrollFrame:SetScript("OnSizeChanged", ScrollFrame_OnSizeChanged);

local function ScrollBar_OnScrollValueChanged(frame, value)
	SetScroll(value);
end

f.scrollBar = CreateFrame("Slider", nil, f.scrollFrame, "UIPanelScrollBarTemplate");
f.scrollBar:SetPoint("TOPLEFT", f.scrollFrame, "TOPRIGHT", 4, -16);
f.scrollBar:SetPoint("BOTTOMLEFT", f.scrollFrame, "BOTTOMRIGHT", 4, 16);
f.scrollBar:SetMinMaxValues(0, 1000);
f.scrollBar:SetValueStep(1);
f.scrollBar:SetValue(0);
f.scrollBar:SetWidth(16);
f.scrollBar:Hide();
-- set the script as the last step, so it doesn't fire yet
f.scrollBar:SetScript("OnValueChanged", ScrollBar_OnScrollValueChanged);

f.scrollBg = f.scrollBar:CreateTexture(nil, "BACKGROUND");
f.scrollBg:SetAllPoints(f.scrollBar);
f.scrollBg:SetColorTexture(0, 0, 0, 0.4);

--Container Support
f.content = CreateFrame("Frame", nil, f.scrollFrame)
f.content:SetHeight(400);
f.content:SetScript("OnSizeChanged", function(self, ...)
	ScrollFrame_OnSizeChanged(f.scrollFrame, ...);
end);
f.scrollFrame:SetScrollChild(f.content);
f.content:SetPoint("TOPLEFT");
f.content:SetPoint("TOPRIGHT");

--------------------------------------------------------------------------------------------------------
--                                        Build Option Category                                       --
--------------------------------------------------------------------------------------------------------

-- Get Setting
local function GetConfigValue(self,var)
	return cfg[var];
end

-- called when a setting is changed, do not allow
local function SetConfigValue(self,var,value,noBuildCategoryPage)
	if (not self.isBuildingOptions) then
		cfg[var] = value;
		local TipTac = _G[PARENT_MOD_NAME];
		TipTac:ApplyConfig();
		if (not noBuildCategoryPage) then
			f:BuildCategoryPage(true);
			f:BuildCategoryList();
		end
	end
end

-- create new factory instance
local factory = AzOptionsFactory:New(f.content,GetConfigValue,SetConfigValue);
f.factory = factory; 

-- Build Page
function f:BuildCategoryPage(noUpdateScrollFrame)
	-- update scroll frame
	if (not noUpdateScrollFrame) then
		f.scrollBar:SetValue(0);
	end
	
	-- build page
	factory:BuildOptionsPage(f.options[activePage].options, f.content, 0, 0);
	
	-- set new content height
	local contentChildren = { f.content:GetChildren() };
	local newContentHeight = nil;
	local contentChildMostBottom = nil;
	
	for index, contentChild in ipairs(contentChildren) do
		local contentChildTopLeftPoint, contentChildTopLeftRelativeTo, contentChildTopLeftRelativePoint, contentChildTopLeftXOfs, contentChildTopLeftYOfs = contentChild:GetPoint();
		if (contentChild:IsShown()) and ((not newContentHeight) or (-contentChildTopLeftYOfs >= newContentHeight)) then
			newContentHeight = -contentChildTopLeftYOfs;
			contentChildMostBottom = contentChild;
		end
	end
	
	local finalContentHeight = (newContentHeight or 0) + (contentChildMostBottom and contentChildMostBottom:GetHeight() or 0);
	
	f.content:SetHeight(finalContentHeight > 0 and finalContentHeight or 1);
end

--------------------------------------------------------------------------------------------------------
--                                        Options Category List                                       --
--------------------------------------------------------------------------------------------------------

local listButtons = {};

local function CategoryButton_OnClick(self,button)
	if (not listButtons[activePage].check.option) or (GetConfigValue(f.factory, listButtons[activePage].check.option.var)) then
		listButtons[activePage].text:SetTextColor(1, 0.82, 0);
	else
		listButtons[activePage].text:SetTextColor(0.5, 0.5, 0.5);
	end
	listButtons[activePage]:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight");
	listButtons[activePage]:GetHighlightTexture():SetAlpha(0.3);
	listButtons[activePage]:UnlockHighlight();
	activePage = self.index;
	if (not self.check.option) or (GetConfigValue(f.factory, self.check.option.var)) then
		self.text:SetTextColor(1, 1, 1);
	else
		self.text:SetTextColor(0.5, 0.5, 0.5);
	end
	self:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	self:GetHighlightTexture():SetAlpha(0.7);
	self:LockHighlight();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);	-- "igMainMenuOptionCheckBoxOn"
	f:BuildCategoryPage();
end

local function CheckButton_OnClick(self, button)
	local checked = (self:GetChecked() and true or false); -- WoD patch made GetChecked() return bool instead of 1/nil
	local b = self:GetParent();
	
	SetConfigValue(f.factory, self.option.var, checked);
	
	CategoryButton_OnClick(b, button);
	
	if (checked) then
		b.text:SetTextColor(1, 1, 1);
	else
		b.text:SetTextColor(0.5, 0.5, 0.5);
	end
end

local function CheckButton_OnEnter(self)
	if (self.option.tip) then
		GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
		GameTooltip:AddLine(self.option.label,1,1,1);
		GameTooltip:AddLine(self.option.tip,nil,nil,nil,1);
		GameTooltip:Show();
	end
end

local function CheckButton_OnLeave(self)
	GameTooltip:Hide();
end

local buttonWidth = (f.outline:GetWidth() - 8);
local function CreateCategoryButtonEntry(parent)
	local b = CreateFrame("Button",nil,parent);
	b:SetSize(buttonWidth,18);
	b:SetScript("OnClick",CategoryButton_OnClick);
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight");
	b:GetHighlightTexture():SetAlpha(0.3);
	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormal");
	b.text:SetPoint("LEFT",3,0);
	b.check = CreateFrame("CheckButton", nil, b);
	b.check:SetPoint("TOPLEFT", buttonWidth - 22, 2);
	b.check:SetPoint("BOTTOMRIGHT", 0, -2);
	b.check:SetScript("OnClick", CheckButton_OnClick);
	b.check:SetScript("OnEnter", CheckButton_OnEnter);
	b.check:SetScript("OnLeave", CheckButton_OnLeave);
	b.check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up");
	b.check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down");
	b.check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight");
	b.check:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled");
	b.check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check");
	b.check:Hide();
	tinsert(listButtons, b);
	return b;
end

-- Build Category List
function f:BuildCategoryList()
	for index, table in ipairs(f.options) do
		local button = listButtons[index] or CreateCategoryButtonEntry(f.outline);
		button.text:SetText(table.category);
		button.text:SetTextColor(1,0.82,0);
		if (table.enabled) then
			local option = table.enabled;
			local cfgValue = GetConfigValue(f.factory, option.var);
			button.check.option = option;
			if (not option.label) then
				option.label = table.category;
			end
			button.check:SetChecked(cfgValue);
			local enabled = (not option.enabled) or (not not option.enabled(f.factory, button.check, option, cfgValue));
			button.check:SetEnabled(enabled);
			if (not cfgValue) or (not enabled) then
				button.text:SetTextColor(0.5, 0.5, 0.5);
			end
			button.check:Show();
		end
		button.index = index;
		if (index == 1) then
			button:SetPoint("TOPLEFT",f.outline,"TOPLEFT",5,-6);
		else
			button:SetPoint("TOPLEFT",listButtons[index - 1],"BOTTOMLEFT");
		end
		if (index == activePage) then
			if (not button.check.option) or (GetConfigValue(f.factory, button.check.option.var)) then
				button.text:SetTextColor(1, 1, 1);
			else
				button.text:SetTextColor(0.5, 0.5, 0.5);
			end
			button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
			button:GetHighlightTexture():SetAlpha(0.7);
			button:LockHighlight();
		end
	end
end
