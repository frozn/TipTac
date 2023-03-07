local cfg = TipTac_Config;
local MOD_NAME = ...;
local PARENT_MOD_NAME = "TipTac";

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

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

local DROPDOWN_BARTEXTFORMAT = {
	["|cffffa0a0None"] = "none",
	["Percentage"] = "percent",
	["Current Only"] = "current",
	["Values"] = "value",
	["Values & Percent"] = "full",
	["Deficit"] = "deficit",
};

-- Options -- The "y" value of a category subtable, will further increase the vertical offset position of the item
local activePage = 1;
local options = {};

-- General
local ttOptionsGeneral = {
	{ type = "Check", var = "showUnitTip", label = "Enable TipTac Unit Tip Appearance", tip = "Will change the appearance of how unit tips look. Many options in TipTac only work with this setting enabled.\nNOTE: Using this options with a non English client may cause issues!" },
	{ type = "Check", var = "showStatus", label = "Show DC, AFK and DND Status", tip = "Will show the <DC>, <AFK> and <DND> status after the player name", y = 8 },
	{ type = "Check", var = "showTargetedBy", label = "Show Who Targets the Unit", tip = "When in a raid or party, the tip will show who from your group is targeting the unit.\nWhen ungrouped, the visible nameplates (can be enabled under WoW options '"..(LibFroznFunctions.isWoWFlavor.DF and "Game->Gameplay->Interface->Nameplates" or "Interface->Names").."') are evaluated instead." },
	{ type = "Check", var = "showPlayerGender", label = "Show Player Gender", tip = "This will show the gender of the player. E.g. \"85 Female Blood Elf Paladin\"." },
	{ type = "Check", var = "showCurrentUnitSpeed", label = "Show Current Unit Speed", tip = "This will show the current speed of the unit after race & class." }
};

if (C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
	ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showMythicPlusDungeonScore", label = "Show Mythic+ Dungeon Score", tip = "This will show the mythic+ dungeon score of the player." };
end

ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showMount", label = "Show Mount", tip = "This will show the current mount of the player.", y = 16 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showMountIcon", label = "Icon", tip = "This option makes the tip show the mount icon.", x = 100 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showMountText", label = "Text", tip = "This option makes the tip show the mount text.", x = 165 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showMountSpeed", label = "Speed", tip = "This option makes the tip show the mount speed.", x = 230 };

ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "DropDown", var = "nameType", label = "Name & Title", list = { ["Name only"] = "normal", ["Name + title"] = "title", ["Copy from original tip"] = "original", ["Mary Sue Protocol"] = "marysueprot" }, y = 16 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "DropDown", var = "showRealm", label = "Show Unit Realm", list = { ["|cffffa0a0Do not show realm"] = "none", ["Show realm"] = "show", ["Show (*) instead"] = "asterisk" } };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "DropDown", var = "showTarget", label = "Show Unit Target", list = { ["|cffffa0a0Do not show target"] = "none", ["First line"] = "first", ["Second line"] = "second", ["Last line"] = "last" } };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Text", var = "targetYouText", label = "Targeting You Text", y = 16 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "Check", var = "showGuildRank", label = "Show Player Guild Rank Title", tip = "In addition to the guild name, with this option on, you will also see their guild rank by title and/or level", y = 16 };
ttOptionsGeneral[#ttOptionsGeneral + 1] = { type = "DropDown", var = "guildRankFormat", label = "Format", list = { ["Title only"] = "title", ["Title + level"] = "both", ["Level only"] = "level" }, y = 8 };

local options = {
	-- General
	{
		[0] = "General",
		unpack(ttOptionsGeneral)
	},
	-- Special
	{
		[0] = "Special",
		{ type = "Check", var = "showBattlePetTip", label = "Enable Battle Pet Tips", tip = "Will show a special tip for both wild and companion battle pets. Might need to be disabled for certain non-English clients" },
		{ type = "Slider", var = "gttScale", label = "Tooltip Scale", min = 0.2, max = 4, step = 0.05, y = 8 },
		{ type = "Slider", var = "updateFreq", label = "Tip Update Frequency", min = 0, max = 5, step = 0.05 },
		{ type = "Check", var = "enableChatHoverTips", label = "Enable ChatFrame Hover Hyperlinks", tip = "When hovering the mouse over a link in the chatframe, show the tooltip without having to click on it", y = 24 },
		{ type = "Check", var = "hidePvpText", label = "Hide PvP Text", tip = "Strips the PvP line from the tooltip", y = 10 },
		{ type = "Check", var = "hideFactionText", label = "Hide Faction Text", tip = "Strips the Alliance or Horde faction text from the tooltip", x = 170 },
 	},
	-- Colors
	{
		[0] = "Colors",
		{ type = "Color", var = "colorName", label = "Name Color", tip = "Color of the name, when not using the option to make it the same as reaction color" },
		{ type = "Check", var = "colorNameByReaction", label = "Color Name by Reaction", tip = "Name color will have the same color as the reacion\nNOTE: This option is overridden by class colored name for players" },
		{ type = "Check", var = "colorNameByClass", label = "Color Player Names by Class Color", tip = "With this option on, player names are colored by their class color\nNOTE: This option overrides reaction colored name for players" },
		
		{ type = "Color", var = "colorGuild", label = "Guild Color", tip = "Color of the guild name, when not using the option to make it the same as reaction color", y = 20 },
		{ type = "Color", var = "colorSameGuild", label = "Your Guild Color", tip = "To better recognise players from your guild, you can configure the color of your guild name individually", x = 120 },
		{ type = "Check", var = "colorGuildByReaction", label = "Color Guild by Reaction", tip = "Guild color will have the same color as the reacion" },
		
		{ type = "Color", var = "colorRace", label = "Race & Creature Type Color", tip = "The color of the race and creature type text", y = 20 },
		{ type = "Color", var = "colorLevel", label = "Neutral Level Color", tip = "Units you cannot attack will have their level text shown in this color" },
		
		{ type = "Check", var = "classColoredBorder", label = "Color Tip Border by Class Color", tip = "For players, the border color will be colored to match the color of their class\nNOTE: This option overrides reaction colored border", y = 12 },
	},
	-- Reactions
	{
		[0] = "Reactions",
		{ type = "Check", var = "reactColoredBorder", label = "Color border based on the unit's reaction", tip = "Same as the above option, just for the border\nNOTE: This option is overridden by class colored border" },
		{ type = "Check", var = "reactIcon", label = "Show the unit's reaction as icon", tip = "This option makes the tip show the unit's reaction as an icon right behind the level" },
		
		{ type = "Check", var = "reactText", label = "Show the unit's reaction as text", tip = "With this option on, the reaction of the unit will be shown as text on the last line", y = 12 },
		{ type = "Color", var = "colorReactText", label = "Color of unit's reaction as text", tip = "Color of the unit's reaction as text, when not using the option to make it the same as reaction color", y = 8 },
		{ type = "Check", var = "reactColoredText", label = "Color unit's reaction as text based on unit's reaction", tip = "With this option on, the unit's reaction as text will be based on unit's reaction" },
		
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.tapped, label = "Tapped Color", y = 20 },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.hostile, label = "Hostile Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.caution, label = "Caution Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.neutral, label = "Neutral Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer, label = "Friendly Player Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer, label = "Friendly PvP Player Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyNPC, label = "Friendly NPC Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.honoredNPC, label = "Honored NPC Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.reveredNPC, label = "Revered NPC Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.exaltedNPC, label = "Exalted NPC Color" },
		{ type = "Color", var = "colorReactText" .. LFF_UNIT_REACTION_INDEX.dead, label = "Dead Color" },
	},
	-- BG Color
	{
		[0] = "BG Color",
		{ type = "Check", var = "reactColoredBackdrop", label = "Color backdrop based on the unit's reaction", tip = "If you want the tip's background color to be determined by the unit's reaction towards you, enable this. With the option off, the background color will be the one selected on the 'Backdrop' page" },
		
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.tapped, label = "Tapped Color", y = 20 },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.hostile, label = "Hostile Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.caution, label = "Caution Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.neutral, label = "Neutral Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer, label = "Friendly Player Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer, label = "Friendly PvP Player Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyNPC, label = "Friendly NPC Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.honoredNPC, label = "Honored NPC Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.reveredNPC, label = "Revered NPC Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.exaltedNPC, label = "Exalted NPC Color" },
		{ type = "Color", var = "colorReactBack" .. LFF_UNIT_REACTION_INDEX.dead, label = "Dead Color" },
	},
	-- Backdrop
	{
		[0] = "Backdrop",
		{ type = "Check", var = "enableBackdrop", label = "Enable Backdrop Modifications", tip = "Turns on or off all modifications of the backdrop\nNOTE: A Reload of the UI (/reload) is required for the setting to take affect" },
		{ type = "DropDown", var = "tipBackdropBG", label = "Background Texture", media = "background", y = 8 },
		{ type = "DropDown", var = "tipBackdropEdge", label = "Border Texture", media = "border" },
		{ type = "Check", var = "pixelPerfectBackdrop", label = "Pixel Perfect Backdrop Edge Size and Insets", tip = "Backdrop Edge Size and Insets corresponds to real pixels", y = 6 },
		{ type = "Slider", var = "backdropEdgeSize", label = "Backdrop Edge Size", min = -20, max = 64, step = 0.5, y = 8 },
		{ type = "Slider", var = "backdropInsets", label = "Backdrop Insets", min = -20, max = 20, step = 0.5 },
		{ type = "Color", var = "tipColor", label = "Tip Background Color", y = 16 },
		{ type = "Color", var = "tipBorderColor", label = "Tip Border Color", x = 160 },
		{ type = "Check", var = "gradientTip", label = "Show Gradient Tooltips", tip = "Display a small gradient area at the top of the tip to add a minor 3D effect to it. If you have an addon like Skinner, you may wish to disable this to avoid conflicts", y = 8 },
		{ type = "Color", var = "gradientColor", label = "Gradient Color", tip = "Select the base color for the gradient", x = 160 },
		{ type = "Slider", var = "gradientHeight", label = "Gradient Height", min = 0, max = 64, step = 0.5, y = 8 },
	},
	-- Font
	{
		[0] = "Font",
		{ type = "Check", var = "modifyFonts", label = "Modify the GameTooltip Font Templates", tip = "For TipTac to change the GameTooltip font templates, and thus all tooltips in the User Interface, you have to enable this option.\nNOTE: If you have an addon such as ClearFont, it might conflict with this option." },
		{ type = "DropDown", var = "fontFace", label = "Font Face", media = "font", y = 32 },
		{ type = "DropDown", var = "fontFlags", label = "Font Flags", list = DROPDOWN_FONTFLAGS },
		{ type = "Slider", var = "fontSize", label = "Font Size", min = 6, max = 29, step = 1, y = 4 },
		{ type = "Slider", var = "fontSizeDeltaHeader", label = "Font Size Header Delta", min = -10, max = 10, step = 1, y = 20 },
		{ type = "Slider", var = "fontSizeDeltaSmall", label = "Font Size Small Delta", min = -10, max = 10, step = 1 },
	},
	-- Classify
	{
		[0] = "Classify",
		{ type = "Text", var = "classification_minus", label = "Minus" },
		{ type = "Text", var = "classification_trivial", label = "Trivial" },
		{ type = "Text", var = "classification_normal", label = "Normal" },
		{ type = "Text", var = "classification_elite", label = "Elite" },
		{ type = "Text", var = "classification_worldboss", label = "Boss" },
		{ type = "Text", var = "classification_rare", label = "Rare" },
		{ type = "Text", var = "classification_rareelite", label = "Rare Elite" },
	},
	-- Fading
	{
		[0] = "Fading",
		{ type = "Check", var = "overrideFade", label = "Override Default GameTooltip Fade for Units", tip = "Overrides the default fadeout function of the GameTooltip for units. If you are seeing problems regarding fadeout, please disable." },
		{ type = "Slider", var = "preFadeTime", label = "Prefade Time", min = 0, max = 5, step = 0.05, y = 8 },
		{ type = "Slider", var = "fadeTime", label = "Fadeout Time", min = 0, max = 5, step = 0.05 },
		{ type = "Check", var = "hideWorldTips", label = "Instantly Hide World Frame Tips", tip = "This option will make most tips which appear from objects in the world disappear instantly when you take the mouse off the object. Examples such as mailboxes, herbs or chests.\nNOTE: Does not work for all world objects.", y = 16 },
	},
	-- Bars
	{
		[0] = "Bars",
		{ type = "DropDown", var = "barFontFace", label = "Font Face", media = "font" },
		{ type = "DropDown", var = "barFontFlags", label = "Font Flags", list = DROPDOWN_FONTFLAGS },
		{ type = "Slider", var = "barFontSize", label = "Font Size", min = 6, max = 29, step = 1 },
		{ type = "DropDown", var = "barTexture", label = "Bar Texture", media = "statusbar", y = 36 },
		{ type = "Slider", var = "barHeight", label = "Bar Height", min = 1, max = 50, step = 1 },
	},
	-- Bar Types
	{
		[0] = "Bar Types",
		{ type = "Check", var = "hideDefaultBar", label = "Hide the Default Health Bar", tip = "Check this to hide the default health bar" },
		{ type = "Check", var = "barsCondenseValues", label = "Show Condensed Bar Values", tip = "You can enable this option to condense values shown on the bars. It does this by showing 57254 as 57.3k as an example" },
		{ type = "Check", var = "healthBar", label = "Show Health Bar", tip = "Will show a health bar of the unit.", y = 12 },
		{ type = "DropDown", var = "healthBarText", label = "Health Bar Text", list = DROPDOWN_BARTEXTFORMAT },
		{ type = "Color", var = "healthBarColor", label = "Health Bar Color", tip = "The color of the health bar. Has no effect for players with the option above enabled" },
		{ type = "Check", var = "healthBarClassColor", label = "Class Colored Health Bar", tip = "This options colors the health bar in the same color as the player class", x = 130 },
		{ type = "Check", var = "manaBar", label = "Show Mana Bar", tip = "If the unit has mana, a mana bar will be shown.", y = 12 },
		{ type = "DropDown", var = "manaBarText", label = "Mana Bar Text", list = DROPDOWN_BARTEXTFORMAT },
		{ type = "Color", var = "manaBarColor", label = "Mana Bar Color", tip = "The color of the mana bar" },
		{ type = "Check", var = "powerBar", label = "Show Bar for other Power Types\n(e.g. Energy, Rage, Runic Power or Focus)", tip = "If the unit uses other power types than mana (e.g. energy, rage, runic power or focus), a bar for that will be shown.", y = 12 },
		{ type = "DropDown", var = "powerBarText", label = "Power Bar Text", list = DROPDOWN_BARTEXTFORMAT, y = 6 },
	},
	-- Auras
	{
		[0] = "Auras",
		{ type = "Check", var = "aurasAtBottom", label = "Put Aura Icons at the Bottom Instead of Top", tip = "Puts the aura icons at the bottom of the tip instead of the default top" },
		{ type = "Check", var = "showBuffs", label = "Show Unit Buffs", tip = "Show buffs of the unit", y = 12 },
		{ type = "Check", var = "showDebuffs", label = "Show Unit Debuffs", tip = "Show debuffs of the unit" },
		{ type = "Check", var = "selfAurasOnly", label = "Only Show Auras Coming from You", tip = "This will filter out and only display auras you cast yourself", y = 12 },
		{ type = "Slider", var = "auraSize", label = "Aura Icon Dimension", min = 8, max = 60, step = 1, y = 12 },
		{ type = "Slider", var = "auraMaxRows", label = "Max Aura Rows", min = 1, max = 8, step = 1 },
		{ type = "Check", var = "showAuraCooldown", label = "Show Cooldown Models", tip = "With this option on, you will see a visual progress of the time left on the buff", y = 8 },
		{ type = "Check", var = "noCooldownCount", label = "No Cooldown Count Text", tip = "Tells cooldown enhancement addons, such as OmniCC, not to display cooldown text" },
	},
	-- Icon
	{
		[0] = "Icon",
		{ type = "Check", var = "iconRaid", label = "Show Raid Icon", tip = "Shows the raid icon next to the tip" },
		{ type = "Check", var = "iconFaction", label = "Show Faction Icon", tip = "Shows the faction icon next to the tip" },
		{ type = "Check", var = "iconCombat", label = "Show Combat Icon", tip = "Shows a combat icon next to the tip, if the unit is in combat" },
		{ type = "Check", var = "iconClass", label = "Show Class Icon", tip = "For players, this will display the class icon next to the tooltip" },
		{ type = "DropDown", var = "iconAnchor", label = "Icon Anchor", list = DROPDOWN_ANCHORPOS, y = 12 },
		{ type = "Slider", var = "iconSize", label = "Icon Dimension", min = 8, max = 100, step = 1 },
	},
	-- Anchors
	{
		[0] = "Anchors",
		{ type = "Check", var = "enableAnchor", label = "Enable Anchor Modifications", tip = "Turns on or off all modifications of the anchor" },
		{ type = "DropDown", var = "anchorWorldUnitType", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE, y = 12 },
		{ type = "DropDown", var = "anchorWorldUnitPoint", label = "World Unit Point", list = DROPDOWN_ANCHORPOS },
		{ type = "DropDown", var = "anchorWorldTipType", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE, y = 12 },
		{ type = "DropDown", var = "anchorWorldTipPoint", label = "World Tip Point", list = DROPDOWN_ANCHORPOS },
		{ type = "DropDown", var = "anchorFrameUnitType", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE, y = 12 },
		{ type = "DropDown", var = "anchorFrameUnitPoint", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS },
		{ type = "DropDown", var = "anchorFrameTipType", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE, y = 12 },
		{ type = "DropDown", var = "anchorFrameTipPoint", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS },

		{ type = "Header", label = "Anchor Overrides", tip = "Enable/Disable special anchor overrides", y = 12 },

		{ type = "Check", var = "enableAnchorOverrideWorldUnitInCombat", label = "World Unit in combat", tip = "This option will override the anchor for World Unit in combat" },
		{ type = "DropDown", var = "anchorWorldUnitTypeInCombat", label = "World Unit Type", list = DROPDOWN_ANCHORTYPE },
		{ type = "DropDown", var = "anchorWorldUnitPointInCombat", label = "World Unit Point", list = DROPDOWN_ANCHORPOS },
		{ type = "Check", var = "enableAnchorOverrideWorldTipInCombat", label = "World Tip in combat", tip = "This option will override the anchor for World Tip in combat", y = 8 },
		{ type = "DropDown", var = "anchorWorldTipTypeInCombat", label = "World Tip Type", list = DROPDOWN_ANCHORTYPE },
		{ type = "DropDown", var = "anchorWorldTipPointInCombat", label = "World Tip Point", list = DROPDOWN_ANCHORPOS },
		{ type = "Check", var = "enableAnchorOverrideFrameUnitInCombat", label = "Frame Unit in combat", tip = "This option will override the anchor for Frame Unit in combat", y = 8 },
		{ type = "DropDown", var = "anchorFrameUnitTypeInCombat", label = "Frame Unit Type", list = DROPDOWN_ANCHORTYPE },
		{ type = "DropDown", var = "anchorFrameUnitPointInCombat", label = "Frame Unit Point", list = DROPDOWN_ANCHORPOS },
		{ type = "Check", var = "enableAnchorOverrideFrameTipInCombat", label = "Frame Tip in combat", tip = "This option will override the anchor for Frame Tip in combat", y = 8 },
		{ type = "DropDown", var = "anchorFrameTipTypeInCombat", label = "Frame Tip Type", list = DROPDOWN_ANCHORTYPE },
		{ type = "DropDown", var = "anchorFrameTipPointInCombat", label = "Frame Tip Point", list = DROPDOWN_ANCHORPOS },

		{ type = "Check", var = "enableAnchorOverrideCF", label = "(Guild & Community) ChatFrame", tip = "This option will override the anchor for (Guild & Community) ChatFrame", y = 8 },
		{ type = "DropDown", var = "anchorOverrideCFType", label = "Tip Type", list = DROPDOWN_ANCHORTYPE },
		{ type = "DropDown", var = "anchorOverrideCFPoint", label = "Tip Point", list = DROPDOWN_ANCHORPOS },
	},
	-- Mouse
	{
		[0] = "Mouse",
		{ type = "Slider", var = "mouseOffsetX", label = "Mouse Anchor X Offset", min = -200, max = 200, step = 1 },
		{ type = "Slider", var = "mouseOffsetY", label = "Mouse Anchor Y Offset", min = -200, max = 200, step = 1 },
	},
	-- Combat
	{
		[0] = "Combat",
		{ type = "Header", label = "Hide Tips Out Of Combat" },
		{ type = "Check", var = "hideTipsWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden." },
		{ type = "Check", var = "hideTipsFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden.", x = 160 },
		{ type = "Check", var = "hideTipsWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden." },
		{ type = "Check", var = "hideTipsFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden.", x = 160 },
		
		{ type = "Check", var = "hideTipsUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden.", y = 10 },
		{ type = "Check", var = "hideTipsSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden.", x = 160 },
		{ type = "Check", var = "hideTipsItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden." },
		{ type = "Check", var = "hideTipsActionTips", label = "Hide Other Action Bar Tips", tip = "When you have this option checked, other Action Bar Tips will be hidden." },
		
		{ type = "Header", label = "Hide Tips In Combat", y = 12 },
		{ type = "Check", var = "hideTipsInCombatWorldUnits", label = "Hide World Units", tip = "When you have this option checked, World Units will be hidden in combat." },
		{ type = "Check", var = "hideTipsInCombatFrameUnits", label = "Hide Frame Units", tip = "When you have this option checked, Frame Units will be hidden in combat.", x = 160 },
		{ type = "Check", var = "hideTipsInCombatWorldTips", label = "Hide World Tips", tip = "When you have this option checked, World Tips will be hidden in combat." },
		{ type = "Check", var = "hideTipsInCombatFrameTips", label = "Hide Frame Tips", tip = "When you have this option checked, Frame Tips will be hidden in combat.", x = 160 },
		
		{ type = "Check", var = "hideTipsInCombatUnitTips", label = "Hide Unit Tips", tip = "When you have this option checked, Unit Tips will be hidden in combat.", y = 10 },
		{ type = "Check", var = "hideTipsInCombatSpellTips", label = "Hide Spell Tips", tip = "When you have this option checked, Spell Tips will be hidden in combat.", x = 160 },
		{ type = "Check", var = "hideTipsInCombatItemTips", label = "Hide Item Tips", tip = "When you have this option checked, Item Tips will be hidden in combat." },
		{ type = "Check", var = "hideTipsInCombatActionTips", label = "Hide Other Action Bar Tips", tip = "When you have this option checked, other Action Bar Tips will be hidden in combat." },
		
		{ type = "Header", label = "Others", y = 12 },
		{ type = "DropDown", var = "showHiddenModifierKey", label = "Still Show Hidden Tips\nwhen Holding\nModifier Key", list = { ["Shift"] = "shift", ["Ctrl"] = "ctrl", ["Alt"] = "alt", ["|cffffa0a0None"] = "none" }, y = 8 },
		{ type = "TextOnly", label = "", y = -14 }, -- spacer for multi-line label above
	},
	-- Layouts
	{
		[0] = "Layouts",
		{ type = "DropDown", label = "Layout Template", init = TipTacLayouts.LoadLayout_Init },
--		{ type = "Text", label = "Save Layout", func = nil },
--		{ type = "DropDown", label = "Delete Layout", init = TipTacLayouts.DeleteLayout_Init },
	},
};

-- TipTacTalents Support
local TipTacTalents = _G[PARENT_MOD_NAME .. "Talents"];

if (TipTacTalents) then
	local tttOptions = {
		{ type = "Check", var = "t_enable", label = "Enable TipTacTalents", tip = "Turns on or off all features of the TipTacTalents addon" },
		{ type = "Header", label = "Talents", y = 12 },
		{ type = "Check", var = "t_showTalents", label = "Show Talents", tip = "This option makes the tip show the talent specialization of other players" },
		{ type = "Check", var = "t_talentOnlyInParty", label = "Only Show Talents and Average Item Level\nfor Party and Raid Members", tip = "When you enable this, only talents and average item level of players in your party or raid will be requested and shown", y = 12 }
	};
	
	if (not LibFroznFunctions.isWoWFlavor.ClassicEra) then
		if (not LibFroznFunctions.isWoWFlavor.WotLKC) then
			tttOptions[#tttOptions + 1] = { type = "Check", var = "t_showRoleIcon", label = "Show Role Icon", tip = "This option makes the tip show the role icon (tank, damager, healer)" };
		end
		
		tttOptions[#tttOptions + 1] = { type = "Check", var = "t_showTalentIcon", label = "Show Talent Icon", tip = "This option makes the tip show the talent icon" };
	end
	
	tttOptions[#tttOptions + 1] = { type = "Check", var = "t_showTalentText", label = "Show Talent Text", tip = "This option makes the tip show the talent text", y = 12 };
	tttOptions[#tttOptions + 1] = { type = "Check", var = "t_colorTalentTextByClass", label = "Color Talent Text by Class Color", tip = "With this option on, talent text is colored by their class color" };
	
	if (not LibFroznFunctions.isWoWFlavor.SL) then
		if (LibFroznFunctions.isWoWFlavor.DF) then
			tttOptions[#tttOptions + 1] = { type = "DropDown", var = "t_talentFormat", label = "Talent Text Format", list = { ["Elemental (31/30)"] = 1, ["Elemental"] = 2, ["31/30"] = 3,}, y = 8 }; -- not supported with MoP changes
		else
			tttOptions[#tttOptions + 1] = { type = "DropDown", var = "t_talentFormat", label = "Talent Text Format", list = { ["Elemental (57/14/0)"] = 1, ["Elemental"] = 2, ["57/14/0"] = 3,}, y = 8 }; -- not supported with MoP changes
		end
	end
	
	tttOptions[#tttOptions + 1] = { type = "Header", label = "Average Item Level", y = 12 };
	tttOptions[#tttOptions + 1] = { type = "Check", var = "t_showAverageItemLevel", label = "Show Average Item Level (AIL)", tip = "This option makes the tip show the average item level (AIL) of other players" };
	tttOptions[#tttOptions + 1] = { type = "Check", var = "t_showGearScore", label = "Show TipTac's GearScore", tip = "This option makes the tip show TipTac's GearScore of other players.\nNOTE: TipTac's own implementation to simply calculate the GearScore is used here. This is the sum of all item levels weighted by performance per item level above/below base level of first tier set of current expansion, inventory type and item quality. Inventory slots for shirt, tabard and ranged are excluded." };
	tttOptions[#tttOptions + 1] = { type = "Check", var = "t_colorAILAndGSTextByQuality", label = "Color Average Item Level and GearScore Text\nby Quality Color", tip = "With this option on, average item level and GearScore text is colored by the average quality of the items" };
	
	options[#options + 1] = {
		[0] = "Talents/AIL",
		unpack(tttOptions)
	};
end

-- TipTacItemRef Support -- Az: this category page is full -- Frozn45: added scroll frame to config options. the scroll bar appears automatically, if content doesn't fit completely on the page.
local TipTacItemRef = _G[PARENT_MOD_NAME .. "ItemRef"];

if (TipTacItemRef) then
	options[#options + 1] = {
		[0] = "ItemRef",
		{ type = "Check", var = "if_enable", label = "Enable ItemRefTooltip Modifications", tip = "Turns on or off all features of the TipTacItemRef addon" },
		{ type = "Color", var = "if_infoColor", label = "Information Color", tip = "The color of the various tooltip lines added by these options", y = 8 },

		{ type = "Check", var = "if_itemQualityBorder", label = "Show Item Tips with Quality Colored Border", tip = "When enabled and the tip is showing an item, the tip border will have the color of the item's quality", y = 12 },
		{ type = "Check", var = "if_showItemLevel", label = "Show Item Level", tip = "For item tooltips, show their itemLevel (Combines with itemID).\nNOTE: This will remove the default itemLevel text shown in tooltips" },
		{ type = "Check", var = "if_showItemId", label = "Show Item ID", tip = "For item tooltips, show their itemID (Combines with itemLevel)", x = 160 },

		{ type = "Check", var = "if_showKeystoneRewardLevel", label = "Show Keystone (Weekly) Reward Level", tip = "For keystone tooltips, show their rewardLevel and weeklyRewardLevel", y = 12 },
		{ type = "Check", var = "if_showKeystoneTimeLimit", label = "Show Keystone Time Limit", tip = "For keystone tooltips, show the instance timeLimit" },
		{ type = "Check", var = "if_showKeystoneAffixInfo", label = "Show Keystone Affix Infos", tip = "For keystone tooltips, show the affix infos" },
		{ type = "Check", var = "if_modifyKeystoneTips", label = "Modify Keystone Tooltips", tip = "Changes the keystone tooltips to show a bit more information\nWarning: Might conflict with other keystone addons" },

		{ type = "Check", var = "if_spellColoredBorder", label = "Show Spell Tips with Colored Border", tip = "When enabled and the tip is showing a spell, the tip border will have the standard spell color", y = 12 },
		{ type = "Check", var = "if_showSpellIdAndRank", label = "Show Spell ID & Rank", tip = "For spell tooltips, show their spellID and spellRank" },
		{ type = "Check", var = "if_auraSpellColoredBorder", label = "Show Aura Tips with Colored Border", tip = "When enabled and the tip is showing a buff or debuff, the tip border will have the standard spell color" },
		{ type = "Check", var = "if_showAuraSpellIdAndRank", label = "Show Aura Spell ID & Rank", tip = "For buff and debuff tooltips, show their spellID and spellRank" },
		{ type = "Check", var = "if_showAuraCaster", label = "Show Aura Tooltip Caster", tip = "When showing buff and debuff tooltips, it will add an extra line, showing who cast the specific aura" },
		{ type = "Check", var = "if_casterClassColor", label = "Use Class Color for Aura Caster", tip = "Use the class color for the caster of the aura" },
		{ type = "Check", var = "if_showMawPowerId", label = "Show Maw Power ID", tip = "For spell and aura tooltips, show their mawPowerID" },
		{ type = "Check", var = "if_showMountId", label = "Show Mount ID", tip = "For spell and aura tooltips, show their mountID" },

		{ type = "Check", var = "if_questDifficultyBorder", label = "Show Quest Tips with Difficulty Colored Border", tip = "When enabled and the tip is showing a quest, the tip border will have the color of the quest's difficulty", y = 12 },
		{ type = "Check", var = "if_showQuestLevel", label = "Show Quest Level", tip = "For quest tooltips, show their questLevel (Combines with questID)" },
		{ type = "Check", var = "if_showQuestId", label = "Show Quest ID", tip = "For quest tooltips, show their questID (Combines with questLevel)", x = 160 },

		{ type = "Check", var = "if_currencyQualityBorder", label = "Show Currency Tips with Quality Colored Border", tip = "When enabled and the tip is showing a currency, the tip border will have the color of the currency's quality", y = 12 },
		{ type = "Check", var = "if_showCurrencyId", label = "Show Currency ID", tip = "Currency items will now show their ID" },

		{ type = "Check", var = "if_achievmentColoredBorder", label = "Show Achievement Tips with Colored Border", tip = "When enabled and the tip is showing an achievement, the tip border will have the the standard achievement color", y = 12 },
		{ type = "Check", var = "if_showAchievementIdAndCategoryId", label = "Show Achievement ID & Category", tip = "On achievement tooltips, the achievement ID as well as the category will be shown" },
		{ type = "Check", var = "if_modifyAchievementTips", label = "Modify Achievement Tooltips", tip = "Changes the achievement tooltips to show a bit more information\nWarning: Might conflict with other achievement addons" },

		{ type = "Check", var = "if_battlePetQualityBorder", label = "Show Battle Pet Tips with Quality Colored Border", tip = "When enabled and the tip is showing a battle pet, the tip border will have the color of the battle pet's quality", y = 12 },
		{ type = "Check", var = "if_showBattlePetLevel", label = "Show Battle Pet Level", tip = "For battle bet tooltips, show their petLevel (Combines with petID)" },
		{ type = "Check", var = "if_showBattlePetId", label = "Show Battle Pet ID", tip = "For battle bet tooltips, show their npcID (Combines with petLevel)", x = 160 },

		{ type = "Check", var = "if_battlePetAbilityColoredBorder", label = "Show Battle Pet Ability Tips with Colored Border", tip = "When enabled and the tip is showing a battle pet ability, the tip border will have the the standard battle pet ability color", y = 12 },
		{ type = "Check", var = "if_showBattlePetAbilityId", label = "Show Battle Pet Ability ID", tip = "For battle bet ability tooltips, show their abilityID" },

		{ type = "Check", var = "if_transmogAppearanceItemQualityBorder", label = "Show Transmog Appearance Item Tips with Quality Colored Border", tip = "When enabled and the tip is showing an transmog appearance item, the tip border will have the color of the transmog appearance item's quality", y = 12 },
		{ type = "Check", var = "if_showTransmogAppearanceItemId", label = "Show Transmog Appearance Item ID", tip = "For transmog appearance item tooltips, show their itemID" },

		{ type = "Check", var = "if_transmogIllusionColoredBorder", label = "Show Transmog Illusion Tips with Colored Border", tip = "When enabled and the tip is showing a transmog illusion, the tip border will have the the standard transmog illusion color", y = 12 },
		{ type = "Check", var = "if_showTransmogIllusionId", label = "Show Transmog Illusion ID", tip = "For transmog illusion tooltips, show their illusionID" },

		{ type = "Check", var = "if_transmogSetQualityBorder", label = "Show Transmog Set Tips with Quality Colored Border", tip = "When enabled and the tip is showing an transmog set, the tip border will have the color of the transmog set's quality", y = 12 },
		{ type = "Check", var = "if_showTransmogSetId", label = "Show Transmog Set ID", tip = "For transmog set tooltips, show their setID" },

		{ type = "Check", var = "if_conduitQualityBorder", label = "Show Conduit Tips with Quality Colored Border", tip = "When enabled and the tip is showing a conduit, the tip border will have the color of the conduit's quality", y = 12 },
		{ type = "Check", var = "if_showConduitItemLevel", label = "Show Conduit Item Level", tip = "For conduit tooltips, show their itemLevel (Combines with conduitID)" },
		{ type = "Check", var = "if_showConduitId", label = "Show Conduit ID", tip = "For conduit tooltips, show their conduitID (Combines with conduit itemLevel)", x = 160 },

		{ type = "Check", var = "if_azeriteEssenceQualityBorder", label = "Show Azerite Essence Tips with Quality Colored Border", tip = "When enabled and the tip is showing an azerite essence, the tip border will have the color of the azerite essence's quality", y = 12 },
		{ type = "Check", var = "if_showAzeriteEssenceId", label = "Show Azerite Essence ID", tip = "For azerite essence tooltips, show their essenceID" },

		{ type = "Check", var = "if_runeforgePowerColoredBorder", label = "Show Runeforge Power Tips with Colored Border", tip = "When enabled and the tip is showing a runeforge power, the tip border will have the the standard runeforge power color", y = 12 },
		{ type = "Check", var = "if_showRuneforgePowerId", label = "Show Runeforge Power ID", tip = "For runeforge power tooltips, show their runeforgePowerID" },

		{ type = "Check", var = "if_flyoutColoredBorder", label = "Show Flyout Tips with Colored Border", tip = "When enabled and the tip is showing a flyout, the tip border will have the the standard spell color", y = 12 },
		{ type = "Check", var = "if_showFlyoutId", label = "Show Flyout ID", tip = "For flyout tooltips, show their flyoutID" },

		{ type = "Check", var = "if_petActionColoredBorder", label = "Show Pet Action Tips with Colored Border", tip = "When enabled and the tip is showing a pet action, the tip border will have the the standard spell color", y = 12 },
		{ type = "Check", var = "if_showPetActionId", label = "Show Pet Action ID", tip = "For flyout tooltips, show their petActionID" },

		{ type = "Header", label = "Icon", tip = "Settings about tooltip icon", y = 12 },
		{ type = "Check", var = "if_showIconId", label = "Show Icon ID", tip = "Show the iconID in the tooltip", y = 12 },
		{ type = "Check", var = "if_showIcon", label = "Show Icon Texture and Stack Count (when available)", tip = "Shows an icon next to the tooltip. For items, the stack count will also be shown" },
		{ type = "Check", var = "if_smartIcons", label = "Smart Icon Appearance", tip = "When enabled, TipTacItemRef will determine if an icon is needed, based on where the tip is shown. It will not be shown on actionbars or bag slots for example, as they already show an icon" },
		{ type = "DropDown", var = "if_stackCountToTooltip", label = "Show Stack Count in\nTooltip", list = { ["|cffffa0a0Do not show"] = "none", ["Always"] = "always", ["Only if icon is not shown"] = "noicon" }, y = 8 },
		{ type = "Check", var = "if_borderlessIcons", label = "Borderless Icons", tip = "Turn off the border on icons", y = 8 },
		{ type = "Slider", var = "if_iconSize", label = "Icon Size", min = 16, max = 128, step = 1 },
		{ type = "DropDown", var = "if_iconAnchor", label = "Icon Anchor", tip = "The anchor of the icon", list = DROPDOWN_ANCHORPOS },
		{ type = "DropDown", var = "if_iconTooltipAnchor", label = "Icon Tooltip Anchor", tip = "The anchor of the tooltip that the icon should anchor to.", list = DROPDOWN_ANCHORPOS },
		{ type = "Slider", var = "if_iconOffsetX", label = "Icon X Offset", min = -200, max = 200, step = 0.5 },
		{ type = "Slider", var = "if_iconOffsetY", label = "Icon Y Offset", min = -200, max = 200, step = 0.5 },
	};
end

--------------------------------------------------------------------------------------------------------
--                                          Initialize Frame                                          --
--------------------------------------------------------------------------------------------------------

local f = CreateFrame("Frame",MOD_NAME,UIParent,BackdropTemplateMixin and "BackdropTemplate");	-- 9.0.1: Using BackdropTemplate

UISpecialFrames[#UISpecialFrames + 1] = f:GetName();

f.options = options;

f:SetSize(449,378);
f:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = 1, tileSize = 16, edgeSize = 16, insets = { left = 3, right = 3, top = 3, bottom = 3 } });
f:SetBackdropColor(0.1,0.22,0.35,1);
f:SetBackdropBorderColor(0.1,0.1,0.1,1);
f:EnableMouse(true);
f:SetMovable(true);
f:SetFrameStrata("DIALOG");
f:SetToplevel(true);
f:SetClampedToScreen(true);
f:SetScript("OnShow",function(self) self:BuildCategoryPage(); end);
f:Hide();

f.outline = CreateFrame("Frame",nil,f,BackdropTemplateMixin and "BackdropTemplate");	-- 9.0.1: Using BackdropTemplate
f.outline:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = 1, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } });
f.outline:SetBackdropColor(0.1,0.1,0.2,1);
f.outline:SetBackdropBorderColor(0.8,0.8,0.9,0.4);
f.outline:SetPoint("TOPLEFT",12,-12);
f.outline:SetPoint("BOTTOMLEFT",12,12);
f.outline:SetWidth(89);

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
f.header:SetText(PARENT_MOD_NAME.." Options");

f.vers = f:CreateFontString(nil,"ARTWORK","GameFontNormalSmall");
f.vers:SetPoint("TOPRIGHT",-15,-15);
local version, build = GetBuildInfo();
f.vers:SetText(PARENT_MOD_NAME .. ": " .. GetAddOnMetadata(PARENT_MOD_NAME, "Version") .. "\nWoW: " .. version);
f.vers:SetTextColor(1,1,0.5);

f.btnAnchor = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnAnchor:SetSize(75,24);
f.btnAnchor:SetPoint("BOTTOMLEFT",f.outline,"BOTTOMRIGHT",12,2);
local TipTac = _G[PARENT_MOD_NAME];
f.btnAnchor:SetScript("OnClick",function() TipTac:SetShown(not TipTac:IsShown()) end);
f.btnAnchor:SetText("Anchor");

local function Reset_OnClick(self)
	for index, option in ipairs(options[activePage]) do
		if (option.var) then
			cfg[option.var] = nil;	-- when cleared, they will read the default value from the metatable
		end
	end
	TipTac:ApplyConfig();
	f:BuildCategoryPage();
end

f.btnReset = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnReset:SetSize(75,24);
f.btnReset:SetPoint("LEFT",f.btnAnchor,"RIGHT",49,0);
f.btnReset:SetScript("OnClick",Reset_OnClick);
f.btnReset:SetText("Defaults");

f.btnClose = CreateFrame("Button",nil,f,"UIPanelButtonTemplate");
f.btnClose:SetSize(75,24);
f.btnClose:SetPoint("LEFT",f.btnReset,"RIGHT",49,0);
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
			local scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs = f.scrollFrame:GetPoint(2);
			scrollFrameBottomRightXOfs = 0;
			f.scrollFrame:SetPoint(scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs);
			if f.content.original_width then
				f.content:SetWidth(f.content.original_width);
			end
		end
	else
		if not self.scrollBarShown then
			self.scrollBarShown = true;
			f.scrollBar:Show();
			local scrollFrameBottomRightPoint, scrollFrameBottomRightRelativeTo, scrollFrameBottomRightRelativePoint, scrollFrameBottomRightXOfs, scrollFrameBottomRightYOfs = f.scrollFrame:GetPoint(2);
			scrollFrameBottomRightXOfs = -20;
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
f.scrollFrame:SetPoint("TOPLEFT", f.outline, "TOPRIGHT", 0, -38);
f.scrollFrame:SetPoint("BOTTOMRIGHT", f.btnClose, "TOPRIGHT", 0, 8);
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
--                                        Options Category List                                       --
--------------------------------------------------------------------------------------------------------

local listButtons = {};

local function CategoryButton_OnClick(self,button)
	listButtons[activePage].text:SetTextColor(1,0.82,0);
	listButtons[activePage]:UnlockHighlight();
	activePage = self.index;
	self.text:SetTextColor(1,1,1);
	self:LockHighlight();
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);	-- "igMainMenuOptionCheckBoxOn"
	f:BuildCategoryPage();
end

local buttonWidth = (f.outline:GetWidth() - 8);
local function CreateCategoryButtonEntry(parent)
	local b = CreateFrame("Button",nil,parent);
	b:SetSize(buttonWidth,18);
	b:SetScript("OnClick",CategoryButton_OnClick);
	b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
	b:GetHighlightTexture():SetAlpha(0.7);
	b.text = b:CreateFontString(nil,"ARTWORK","GameFontNormal");
	b.text:SetPoint("LEFT",3,0);
	listButtons[#listButtons + 1] = b;
	return b;
end

for index, table in ipairs(options) do
	local button = listButtons[index] or CreateCategoryButtonEntry(f.outline);
	button.text:SetText(table[0]);
	button.index = index;
	if (index == 1) then
		button:SetPoint("TOPLEFT",f.outline,"TOPLEFT",5,-6);
	else
		button:SetPoint("TOPLEFT",listButtons[index - 1],"BOTTOMLEFT");
	end
	if (index == activePage) then
		button.text:SetTextColor(1,1,1);
		button:LockHighlight();
	end
end

--------------------------------------------------------------------------------------------------------
--                                        Build Option Category                                       --
--------------------------------------------------------------------------------------------------------

-- Get Setting
local function GetConfigValue(self,var)
	return cfg[var];
end

-- called when a setting is changed, do not allow
local function SetConfigValue(self,var,value)
	if (not self.isBuildingOptions) then
		cfg[var] = value;
		local TipTac = _G[PARENT_MOD_NAME];
		TipTac:ApplyConfig();
	end
end

-- create new factory instance
local factory = AzOptionsFactory:New(f.content,GetConfigValue,SetConfigValue);
f.factory = factory; 

-- Build Page
function f:BuildCategoryPage()
	-- update scroll frame
	f.scrollBar:SetValue(0);
	
	-- build page
	factory:BuildOptionsPage(options[activePage], f.content, 0, 0);
	
	-- set new content height
	local contentChildren = { f.content:GetChildren() };
	local newContentHeight = 0;
	local contentChildMostBottom = nil;
	
	for index, contentChild in ipairs(contentChildren) do
		local contentChildTopLeftPoint, contentChildTopLeftRelativeTo, contentChildTopLeftRelativePoint, contentChildTopLeftXOfs, contentChildTopLeftYOfs = contentChild:GetPoint();
		
		if (contentChild:IsShown() and -contentChildTopLeftYOfs >= newContentHeight) then
			newContentHeight = -contentChildTopLeftYOfs;
			contentChildMostBottom = contentChild;
		end
	end
	
	f.content:SetHeight(newContentHeight + contentChildMostBottom:GetHeight());
end