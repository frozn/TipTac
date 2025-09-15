-- Addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- TipTac refs
local tt = _G[MOD_NAME];
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- element registration
local ttStyle = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttStyle, "Style");

-- vars
local lineName = LibFroznFunctions:CreatePushArray();
local lineRealm = LibFroznFunctions:CreatePushArray();
local lineLevel = LibFroznFunctions:CreatePushArray();
local lineInfo = LibFroznFunctions:CreatePushArray();
local lineTargetedBy = LibFroznFunctions:CreatePushArray();

-- String Constants
local TT_LevelMatch = "^"..TOOLTIP_UNIT_LEVEL:gsub("%%[^s ]*s",".+"); -- "Level %s" -> "^Level .+" Was changed to match other localizations properly, used to match: "^"..LEVEL.." .+" -- Doesn't actually match the level line on the russian client! [14.02.24] Doesn't match for Italian client either. [18.07.27] changed the pattern, might match non-english clients now
local TT_LevelMatchPet = "^"..TOOLTIP_WILDBATTLEPET_LEVEL_CLASS:gsub("%%[^s ]*s",".+");	-- "Pet Level %s %s" -> "^Pet Level .+ .+"
local TT_Unknown = UNKNOWN; -- "Unknown"
local TT_UnknownObject = UNKNOWNOBJECT; -- "Unknown"
local TT_Targeting = BINDING_HEADER_TARGETING;	-- "Targeting"
local TT_TargetedBy = LibFroznFunctions:GetGlobalString("TIPTAC_TARGETED_BY") or "Targeted by"; -- "Targeted by"
local TT_PlayerMap = BRAWL_TOOLTIP_MAP; -- "Map"
local TT_PlayerZone = FRIENDS_LIST_ZONE; -- "Zone: "
local TT_PlayerSubzone = LibFroznFunctions:GetGlobalString("TIPTAC_SUBZONE") or "Subzone"; -- "Subzone"
local TT_MythicPlusDungeonScore = CHALLENGE_COMPLETE_DUNGEON_SCORE; -- "Mythic+ Rating: %s"
local TT_Mount = LibFroznFunctions:GetGlobalString("RENOWN_REWARD_MOUNT_NAME_FORMAT") or "Mount: %s"; -- "Mount: %s"
local TT_PlayerGuildMemberNote = GUILD .. " " .. LABEL_NOTE; -- "Guild" "Note"
local TT_PlayerGuildOfficerNote = GUILD .. " " .. OFFICER_NOTE_COLON; -- "Guild" "Officer's Note"
local TT_ReactionIcon = {
	[LFF_UNIT_REACTION_INDEX.hostile] = "unit_reaction_hostile",             -- Hostile
	[LFF_UNIT_REACTION_INDEX.caution] = "unit_reaction_caution",             -- Unfriendly
	[LFF_UNIT_REACTION_INDEX.neutral] = "unit_reaction_neutral",             -- Neutral
	[LFF_UNIT_REACTION_INDEX.friendlyPlayer] = "unit_reaction_friendly",     -- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer] = "unit_reaction_friendly",  -- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyNPC] = "unit_reaction_friendly",        -- Friendly
	[LFF_UNIT_REACTION_INDEX.honoredNPC] = "unit_reaction_honored",          -- Honored
	[LFF_UNIT_REACTION_INDEX.reveredNPC] = "unit_reaction_revered",          -- Revered
	[LFF_UNIT_REACTION_INDEX.exaltedNPC] = "unit_reaction_exalted",          -- Exalted
};
local TT_ReactionText = {
	[LFF_UNIT_REACTION_INDEX.tapped] = "Tapped",                            -- no localized string of this
	[LFF_UNIT_REACTION_INDEX.hostile] = FACTION_STANDING_LABEL2,            -- Hostile
	[LFF_UNIT_REACTION_INDEX.caution] = FACTION_STANDING_LABEL3,            -- Unfriendly
	[LFF_UNIT_REACTION_INDEX.neutral] = FACTION_STANDING_LABEL4,            -- Neutral
	[LFF_UNIT_REACTION_INDEX.friendlyPlayer] = FACTION_STANDING_LABEL5,     -- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer] = FACTION_STANDING_LABEL5,	-- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyNPC] = FACTION_STANDING_LABEL5,        -- Friendly
	[LFF_UNIT_REACTION_INDEX.honoredNPC] = FACTION_STANDING_LABEL6,         -- Honored
	[LFF_UNIT_REACTION_INDEX.reveredNPC] = FACTION_STANDING_LABEL7,         -- Revered
	[LFF_UNIT_REACTION_INDEX.exaltedNPC] = FACTION_STANDING_LABEL8,         -- Exalted
	[LFF_UNIT_REACTION_INDEX.dead] = DEAD                                   -- Dead
};
local TT_TipTacDeveloper = LibFroznFunctions:GetGlobalString("TIPTAC_TIPTAC_DEVELOPER") or "Developer of %s"; -- "Developer of %s"

-- colors
local TT_COLOR = {
	text = {
		default = HIGHLIGHT_FONT_COLOR, -- white
		targeting = HIGHLIGHT_FONT_COLOR, -- white
		targetedBy = HIGHLIGHT_FONT_COLOR, -- white
		guildRank = CreateColor(0.8, 0.8, 0.8, 1), -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
		unitSpeed = CreateColor(0.8, 0.8, 0.8, 1), -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
		mythicPlusPercentMaxCountEnemyForces = LIGHTYELLOW_FONT_COLOR,
		mountName = HIGHLIGHT_FONT_COLOR, -- white
		mountSpeed = LIGHTYELLOW_FONT_COLOR,
		mountSource = LIGHTYELLOW_FONT_COLOR,
		mountLore = LIGHTYELLOW_FONT_COLOR,
		tipTacDeveloper = RED_FONT_COLOR,
		tipTacDeveloperTipTac = EPIC_PURPLE_COLOR
	}
};

--------------------------------------------------------------------------------------------------------
--                                         Style Unit Tooltip                                         --
--------------------------------------------------------------------------------------------------------

-- structure of unit tooltips:
--
-- GameTooltip lines of the player (determined via: UnitIsUnit(unitID, "player")):
--
-- content                                           color                                                                    example
-- ------------------------------------------------  -----------------------------------------------------------------------  ---------------------------------------------------------------------------------------------------
--  1. <name with optional title>                    white (HIGHLIGHT_FONT_COLOR), color based on reaction if PvP is enabled  "Camassea", "Camassea, Hand von A'dal", "Camassea die Ehrfurchtgebietende" or "Chefköchin Camassea"
-- [2. since bc: <guild>]                            white (HIGHLIGHT_FONT_COLOR)                                             "Blood Omen"
-- [3. <reaction, only colorblind mode>]             white (HIGHLIGHT_FONT_COLOR)                                             "Freundlich"
--  4. <level> - <race>, <class> (Spieler)           white (HIGHLIGHT_FONT_COLOR)                                             "Stufe 60 - Nachtelfe, Druidin (Spieler)"
-- [5. since df 10.1.5: [<specialization> ]<class>]  white (HIGHLIGHT_FONT_COLOR)                                             "Gleichgewicht Druidin"
-- [6. <faction>]                                    white (HIGHLIGHT_FONT_COLOR)                                             "Allianz" or "Horde"
-- [7. PvP]                                          white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of other player (determined via: UnitIsPlayer(unitID) and not UnitIsUnit(unitID, "player")):
--
-- content                                           color                                                                    example
-- ------------------------------------------------  -----------------------------------------------------------------------  ------------------------------------------
--  1. <name with optional title>[-<realm>]          white (HIGHLIGHT_FONT_COLOR), color based on reaction if PvP is enabled  "Zoodirektorin Silvette-Alleria"
-- [2. since bc: <guild>[-<realm>]]                  white (HIGHLIGHT_FONT_COLOR)                                             "Die teuflischen Engel-Alleria"
-- [3. <reaction, only colorblind mode>]             white (HIGHLIGHT_FONT_COLOR)                                             "Freundlich"
--  4. <level> - <race>, <class> (Spieler)           white (HIGHLIGHT_FONT_COLOR)                                             "Stufe 70 - Leerenelfe, Jägerin (Spieler)"
-- [5. since df 10.1.5: [<specialization> ]<class>]  white (HIGHLIGHT_FONT_COLOR)                                             "Verwüstung Dämonenjäger" or "Druidin"
-- [6. <faction>]                                    white (HIGHLIGHT_FONT_COLOR)                                             "Allianz" or "Horde"
-- [7. PvP]                                          white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of NPC (determined via: not UnitIsPlayer(unitID) and not UnitPlayerControlled(unitID) and not UnitIsBattlePet(unitID)):
--
-- content                                color                         example
-- -------------------------------------  ----------------------------  ----------------------------------------------
--  1. <name>                             color based on reaction       "Melris Malagan" or "Stadtwache von Sturmwind" or "Versuchter Unterwerfer" or "Beckenvulpin"
-- [2. <reaction, only colorblind mode>]  white (HIGHLIGHT_FONT_COLOR)  "Ehrfürchtig" or "Neutral"
-- [3. <title>]                           white (HIGHLIGHT_FONT_COLOR)  "Hauptmann der Wache"
--  4. <level>                            white (HIGHLIGHT_FONT_COLOR)  "Stufe 70" or "Stufe 30 (Elite)"
--  5. <faction or creature type>         white (HIGHLIGHT_FONT_COLOR)  "Sturmwind" or "Entartung" or "Humanoid" or "Wildtier". currently unknown if creature type replaces the faction or belongs to a separate line.
-- [6. PvP]                               white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of pet (determined via: not UnitIsPlayer(unitID) and UnitPlayerControlled(unitID)):
--
-- content                                                                     color                                                                    example
-- --------------------------------------------------------------------------  -----------------------------------------------------------------------  ------------------------------------------
--  1. <name>                                                                  white (HIGHLIGHT_FONT_COLOR), color based on reaction if PvP is enabled  "Grimkresh" or "Wildwichtel"
-- [2. <reaction, only colorblind mode>]                                       white (HIGHLIGHT_FONT_COLOR)                                             "Freundlich"
--  3. <"Diener von" or "Wächter von"> <name of controlling player>[-<realm>]  white (HIGHLIGHT_FONT_COLOR)                                             "Diener von Eliyanna-Alleria" or "Wächter von Nijra-Alleria"
--  4. <level>                                                                 white (HIGHLIGHT_FONT_COLOR)                                             "Stufe 69"
-- [5. PvP]                                                                    white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of battle pet (determined via: UnitIsBattlePetCompanion(unitID)):
--
-- content                                                                     color                         example
-- --------------------------------------------------------------------------  ----------------------------  ------------------------------------------
--  1. <name>                                                                  color based on quality        "Schössling von Teldrassil"
-- [2. <reaction, only colorblind mode>]                                       white (HIGHLIGHT_FONT_COLOR)  "Freundlich"
--  3. Gefährte von <name of controlling player>[-<realm>]                     white (HIGHLIGHT_FONT_COLOR)  "Gefährte von Camassea"
--  4. <level>, <type>                                                         white (HIGHLIGHT_FONT_COLOR)  "Haustierstufe 1, Elementar"
--
-- GameTooltip lines of wild/tameable battle pet (determined via: UnitIsWildBattlePet(unitID)):
--
-- content                                                                     color                         example
-- --------------------------------------------------------------------------  ----------------------------  ------------------------------------------
--  1. <name>                                                                  color based on reaction       "Kaninchen"
-- [2. <reaction, only colorblind mode>]                                       white (HIGHLIGHT_FONT_COLOR)  "Neutral"
--  3. <level>, <type>                                                         white (HIGHLIGHT_FONT_COLOR)  "Haustierstufe 1, Kleintier"
--

-- remove unwanted lines from tip, such as "Alliance", "Horde", "PvP" and "Shadow Priest".
function ttStyle:RemoveUnwantedLinesFromTip(tip, unitRecord)
	local creatureFamily = UnitCreatureFamily(unitRecord.id);
	local creatureType = UnitCreatureType(unitRecord.id);
	
	local hideCreatureTypeIfNoCreatureFamily = ((not unitRecord.isPlayer) or (unitRecord.isWildBattlePet)) and (not creatureFamily) and (creatureType);
	local hideSpecializationAndClassText = (cfg.hideSpecializationAndClassText) and (unitRecord.isPlayer) and (LibFroznFunctions.hasWoWFlavor.specializationAndClassTextInPlayerUnitTip) and (unitRecord.className);
	local hideRightClickForFrameSettingsTextInUnitTip = (cfg.hideRightClickForFrameSettingsTextInUnitTip) and (LibFroznFunctions.hasWoWFlavor.rightClickForFrameSettingsTextInUnitTip) and (UNIT_POPUP_RIGHT_CLICK);
	
	local specNames = LibFroznFunctions:CreatePushArray();
	
	if (hideSpecializationAndClassText) then
		local specCount = C_SpecializationInfo.GetNumSpecializationsForClassID(unitRecord.classID);
		
		for i = 1, specCount do
			local specID, specName = GetSpecializationInfoForClassID(unitRecord.classID, i, unitRecord.sex);
			
			specNames:Push(specName);
		end
	end
	
	for i = 2, tip:NumLines() do
		local gttLine = _G["GameTooltipTextLeft" .. i];
		local gttLineText = gttLine:GetText();
		
		if (type(gttLineText) == "string") then
			local isGttLineTextUnitPopupRightClick = (hideRightClickForFrameSettingsTextInUnitTip) and (gttLineText == UNIT_POPUP_RIGHT_CLICK);
			
			if (isGttLineTextUnitPopupRightClick) or
					((gttLineText == FACTION_ALLIANCE) or (gttLineText == FACTION_HORDE) or (gttLineText == FACTION_NEUTRAL)) or
					(cfg.hidePvpText) and (gttLineText == PVP_ENABLED) or
					(hideCreatureTypeIfNoCreatureFamily) and (gttLineText == creatureType) or
					(hideSpecializationAndClassText) and ((gttLineText == unitRecord.className) or (specNames:Contains(gttLineText:match("^(.+) " .. unitRecord.className .. "$")))) then
				
				gttLine:SetText(nil);
				
				if (isGttLineTextUnitPopupRightClick) and (i > 1) then
					_G["GameTooltipTextLeft" .. (i - 1)]:SetText(nil);
				end
			end
		end
	end
end

-- Add target
local function AddTarget(lineList,target,targetName)
	if (UnitIsUnit("player",target)) then
		lineList:Push(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(cfg.targetYouText));
	else
		local targetReactionColor = CreateColor(unpack(cfg["colorReactText"..LibFroznFunctions:GetUnitReactionIndex(target)]));
		lineList:Push(targetReactionColor:WrapTextInColorCode("["));
		if (UnitIsPlayer(target)) then
			local targetClassID = select(3, UnitClass(target));
			local targetClassColor = LibFroznFunctions:GetClassColor(targetClassID, nil, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil) or TT_COLOR.text.targeting;
			lineList:Push(targetClassColor:WrapTextInColorCode(targetName));
		else
			lineList:Push(targetReactionColor:WrapTextInColorCode(targetName));
		end
		lineList:Push(targetReactionColor:WrapTextInColorCode("]"));
	end
end

-- TARGET
function ttStyle:GenerateTargetLines(unitRecord, method)
	local target = unitRecord.id .."target";
	local targetName = UnitName(target);
	if (targetName) and (targetName ~= TT_UnknownObject and targetName ~= "" or UnitExists(target)) then
		if (method == "afterName") then
			lineName:Push(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(" : "));
			AddTarget(lineName,target,targetName);
		elseif (method == "belowNameRealm") then
			if (lineRealm:GetCount() > 0) then
				lineRealm:Push("\n");
			end
			lineRealm:Push("  ");
			AddTarget(lineRealm,target,targetName);
		else
			if (lineInfo:GetCount() > 0) then
				lineInfo:Push("\n");
			end
			lineInfo:Push("|cffffd100");
			lineInfo:Push(TT_Targeting);
			lineInfo:Push(": ");
			AddTarget(lineInfo,target,targetName);
		end
	end
end

-- TARGETTED BY
function ttStyle:GenerateTargetedByLines(unitRecord)
	local numUnits, inGroup, inRaid, nameplates;
	
	local numGroup = GetNumGroupMembers();
	if (numGroup) and (numGroup >= 1) then
		numUnits = numGroup;
		inGroup = true;
		inRaid = IsInRaid();
	else
		nameplates = C_NamePlate.GetNamePlates();
		numUnits = #nameplates;
		inGroup = false;
	end
	
	for i = 1, numUnits do
		local unit = inGroup and (inRaid and "raid"..i or "party"..i) or (nameplates[i].namePlateUnitToken or "nameplate"..i);
		if (UnitIsUnit(unit.."target", unitRecord.id)) and (not UnitIsUnit(unit, "player")) then
			local unitName = UnitName(unit);
			
			if (UnitIsPlayer(unit)) then
				local unitClassID = select(3, UnitClass(unit));
				local unitClassColor = LibFroznFunctions:GetClassColor(unitClassID, nil, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil) or TT_COLOR.text.targetedBy;
				lineTargetedBy:Push(unitClassColor:WrapTextInColorCode(unitName));
			else
				local unitReactionColor = CreateColor(unpack(cfg["colorReactText"..LibFroznFunctions:GetUnitReactionIndex(unit)]));
				lineTargetedBy:Push(unitReactionColor:WrapTextInColorCode(unitName));
			end
		end
	end
end

-- highlight TipTac developer
function ttStyle:HighlightTipTacDeveloper(tip, currentDisplayParams, unitRecord, first)
	-- no highlighting of TipTac developer
	if (not cfg.highlightTipTacDeveloper) then
		return;
	end
	
	-- no TipTac developer
	if (not unitRecord.isTipTacDeveloper) then
		return;
	end
	
	-- set top/bottom overlay, only necessary when the tip is first displayed.
	if (first) then
		local style = { -- top overlay from GAME_TOOLTIP_BACKDROP_STYLE_RUNEFORGE_LEGENDARY and bottom overlay from GAME_TOOLTIP_BACKDROP_STYLE_AZERITE_ITEM, see "GameTooltip.lua"
			-- overlayAtlasTop = "AzeriteTooltip-Topper", -- available in DF, but not available in WotLKC
			overlayTextureTop = "Interface\\AddOns\\" .. MOD_NAME .. "\\media\\AzeriteTooltip",
			overlayTextureTopWidth = 95,
			overlayTextureTopHeight = 27,
			overlayTextureTopLeftTexel = 0.0078125,
			overlayTextureTopRightTexel = 0.75,
			overlayTextureTopTopTexel = 0.2265625,
			overlayTextureTopBottomTexel = 0.4375,
			
			overlayAtlasTopScale = 0.75,
			overlayAtlasTopYOffset = 1 - ((cfg.enableBackdrop and TT_ExtendedConfig.tipBackdrop.insets.top or 0) + TT_ExtendedConfig.tipPaddingForGameTooltip.offset),
			
			-- overlayAtlasBottom = "AzeriteTooltip-Bottom", -- available in DF, but not available in WotLKC
			overlayTextureBottom = "Interface\\AddOns\\" .. MOD_NAME .. "\\media\\AzeriteTooltip",
			overlayTextureBottomWidth = 43,
			overlayTextureBottomHeight = 11,
			overlayTextureBottomLeftTexel = 0.539062,
			overlayTextureBottomRightTexel = 0.875,
			overlayTextureBottomTopTexel = 0.453125,
			overlayTextureBottomBottomTexel = 0.539062,
			
			overlayAtlasBottomYOffset = 2 + ((cfg.enableBackdrop and TT_ExtendedConfig.tipBackdrop.insets.bottom or 0) + TT_ExtendedConfig.tipPaddingForGameTooltip.offset)
		};
		
		if (tip.TopOverlay) then
			local isTopOverlayShown = tip.TopOverlay:IsShown();
		
			if (style) and (style.overlayTextureTop) and (not isTopOverlayShown) then -- part from SharedTooltip_SetBackdropStyle() only for top overlay
				-- tip.TopOverlay:SetAtlas(style.overlayAtlasTop, true); -- available in DF, but not available in WotLKC
				tip.TopOverlay:SetTexture(style.overlayTextureTop);
				tip.TopOverlay:SetSize(style.overlayTextureTopWidth, style.overlayTextureTopHeight);
				tip.TopOverlay:SetTexCoord(style.overlayTextureTopLeftTexel, style.overlayTextureTopRightTexel, style.overlayTextureTopTopTexel, style.overlayTextureTopBottomTexel);
				
				tip.TopOverlay:SetScale(style.overlayAtlasTopScale or 1.0);
				tip.TopOverlay:SetPoint("CENTER", tip, "TOP", style.overlayAtlasTopXOffset or 0, style.overlayAtlasTopYOffset or 0);
				tip.TopOverlay:Show();
				
				currentDisplayParams.isSetTopOverlayToHighlightTipTacDeveloper = true;
			end
		end
		
		if (tip.BottomOverlay) then
			local isBottomOverlayShown = tip.BottomOverlay:IsShown();
			
			if (style) and (style.overlayTextureBottom) and (not isBottomOverlayShown) then -- part from SharedTooltip_SetBackdropStyle() only for bottom overlay
				-- tip.BottomOverlay:SetAtlas(style.overlayAtlasBottom, true); -- available in DF, but not available in WotLKC
				tip.BottomOverlay:SetTexture(style.overlayTextureBottom);
				tip.BottomOverlay:SetSize(style.overlayTextureBottomWidth, style.overlayTextureBottomHeight);
				tip.BottomOverlay:SetTexCoord(style.overlayTextureBottomLeftTexel, style.overlayTextureBottomRightTexel, style.overlayTextureBottomTopTexel, style.overlayTextureBottomBottomTexel);
				
				tip.BottomOverlay:SetScale(style.overlayAtlasBottomScale or 1.0);
				tip.BottomOverlay:SetPoint("CENTER", tip, "BOTTOM", style.overlayAtlasBottomXOffset or 0, style.overlayAtlasBottomYOffset or 0);
				tip.BottomOverlay:Show();
				
				currentDisplayParams.isSetBottomOverlayToHighlightTipTacDeveloper = true;
			end
		end
	end
	
	-- add text to level
	-- local tipTacDeveloperIcon = CreateAtlasMarkup("UI-QuestPoiLegendary-QuestBang"); -- available in DF, but not available in WotLKC
	local tipTacDeveloperIcon = CreateTextureMarkup("Interface\\AddOns\\" .. MOD_NAME .. "\\media\\QuestLegendaryMapIcons", 256, 128, nil, nil, 0.26953125, 0.37890625, 0.0390625, 0.2421875);
	local tipTacDeveloperText = (tipTacDeveloperIcon .. " " .. TT_TipTacDeveloper .. " " .. tipTacDeveloperIcon);
	local modNameText = TT_COLOR.text.tipTacDeveloperTipTac:WrapTextInColorCode(MOD_NAME);
	
	lineLevel:Push(TT_COLOR.text.tipTacDeveloper:WrapTextInColorCode(tipTacDeveloperText:format(modNameText)));
	lineLevel:Push("\n");
end

-- PLAYER Styling
function ttStyle:GeneratePlayerLines(tip, currentDisplayParams, unitRecord, first)
	-- gender
	if (cfg.showPlayerGender) then
		local sex = unitRecord.sex;
		if (sex == 2) or (sex == 3) then
			lineLevel:Push(" ");
			lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(sex == 3 and FEMALE or MALE));
		end
	end
	-- race
	local race = UnitRace(unitRecord.id) or TT_Unknown;
	lineLevel:Push(" ");
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(race));
	-- class
	local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
	lineLevel:Push(" ");
	lineLevel:Push(classColor:WrapTextInColorCode(unitRecord.className or TT_Unknown));
	-- name
	local nameColor = (cfg.colorNameByClass and classColor) or unitRecord.nameColor;
	local name = (cfg.nameType == "marysueprot" and unitRecord.rpName) or (cfg.nameType == "original" and unitRecord.originalName) or (cfg.nameType == "title" and unitRecord.nameWithTitle) or unitRecord.name;
	if (unitRecord.normalizedForeignRealmName) and (cfg.showRealm ~= "none") then
		if (cfg.showRealm == "show") then
			name = name .. " - " .. unitRecord.normalizedForeignRealmName;
		elseif (cfg.showRealm == "showInNewLine") then
			lineRealm:Push(nameColor:WrapTextInColorCode(unitRecord.normalizedForeignRealmName));
		else
			name = name .. " (*)";
		end
	end
	lineName:Push(nameColor:WrapTextInColorCode(name));
	-- dc, afk or dnd
	if (cfg.showStatus) then
		local status = (not UnitIsConnected(unitRecord.id) and " <DC>") or (UnitIsAFK(unitRecord.id) and " <AFK>") or (UnitIsDND(unitRecord.id) and " <DND>");
		if (status) then
			lineName:Push(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(status));
		end
	end
	-- map, zone and subzone
	if (cfg.showMapAndZoneAndSubzone ~= "none") then
		-- determine map, zone and subzone text
		local mapText, zoneText, subzoneText;
		
		if (unitRecord.map) and (LibFroznFunctions:ExistsInTable(cfg.showMapAndZoneAndSubzone, { "mapAndZoneAndSubzone", "mapAndZone", "map" })) then
			mapText = unitRecord.map;
		end
		
		if (unitRecord.zone) and (LibFroznFunctions:ExistsInTable(cfg.showMapAndZoneAndSubzone, { "mapAndZoneAndSubzone", "mapAndZone", "zoneAndSubzone", "zone" })) then
			zoneText = unitRecord.zone;
			
			if (unitRecord.subzone) and (LibFroznFunctions:ExistsInTable(cfg.showMapAndZoneAndSubzone, { "mapAndZoneAndSubzone", "zoneAndSubzone" })) then
				subzoneText = unitRecord.subzone;
			end
		end
		
		-- add map, zone and subzone text
		if (mapText) and (mapText ~= zoneText) then
			if (lineInfo:GetCount() > 0) then
				lineInfo:Push("\n");
			end
			
			lineInfo:Push("|cffffd100");
			lineInfo:Push(TT_PlayerMap .. ": " .. TT_COLOR.text.default:WrapTextInColorCode(mapText));
		end
		
		if (zoneText) then
			if (lineInfo:GetCount() > 0) then
				lineInfo:Push("\n");
			end
			
			lineInfo:Push("|cffffd100");
			lineInfo:Push(TT_PlayerZone .. TT_COLOR.text.default:WrapTextInColorCode(zoneText));
			
			if (subzoneText) then
				lineInfo:Push("\n");
				lineInfo:Push(TT_PlayerSubzone .. ": " .. TT_COLOR.text.default:WrapTextInColorCode(subzoneText));
			end
		end
	end
	-- guild
	local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unitRecord.id);
	if (guildName) then
		local playerGuildName, playerGuildRankName, playerGuildRankIndex, playerGuildRealm = GetGuildInfo("player");
		local isPlayerGuild = (guildName == playerGuildName) and (guildRealm == playerGuildRealm);
		if (cfg.showGuild) then -- show guild
			local textGuildRealm = "";
			if (guildRealm) and (cfg.showGuildRealm ~= "none") then
				if (cfg.showGuildRealm == "show") then
					textGuildRealm = " - " .. guildRealm;
				elseif (cfg.showGuildRealm == "asterisk") then
					textGuildRealm = " (*)";
				end
			end
			local guildColor = (isPlayerGuild and CreateColor(unpack(cfg.colorSameGuild)) or cfg.colorGuildByReaction and unitRecord.reactionColor or CreateColor(unpack(cfg.colorGuild)));
			local text = guildColor:WrapTextInColorCode(format("<%s>", guildName .. textGuildRealm));
			
			if (cfg.showGuildRank and guildRankName) then
				if (cfg.guildRankFormat == "title") then
					text = text .. " " .. TT_COLOR.text.guildRank:WrapTextInColorCode(format("%s", guildRankName));
				elseif (cfg.guildRankFormat == "both") then
					text = text .. " " .. TT_COLOR.text.guildRank:WrapTextInColorCode(format("%s (%s)", guildRankName, guildRankIndex));
				elseif (cfg.guildRankFormat == "level") then
					text = text .. " " .. TT_COLOR.text.guildRank:WrapTextInColorCode(format("%s", guildRankIndex));
				end
			end
			if (guildRealm) and (cfg.showGuildRealm == "showInNewLine") then
				text = text .. "\n" .. guildColor:WrapTextInColorCode(guildRealm);
			end
			currentDisplayParams.mergeLevelLineWithGuildName = false;
			if (not LibFroznFunctions.hasWoWFlavor.guildNameInPlayerUnitTip) then -- no separate line for guild name. merge with reaction (only color blind mode) or level line.
				if (unitRecord.isColorBlind) then
					GameTooltipTextLeft2:SetText(text .. "\n" .. unitRecord.reactionTextInColorBlindMode);
				else
					GameTooltipTextLeft2:SetText(text);
					currentDisplayParams.mergeLevelLineWithGuildName = true;
				end
			else
				GameTooltipTextLeft2:SetText(text);
				lineLevel.Index = (lineLevel.Index + 1);
			end
		else -- don't show guild
			if (LibFroznFunctions.hasWoWFlavor.guildNameInPlayerUnitTip) then -- separate line for guild name
				GameTooltipTextLeft2:SetText(nil);
				lineLevel.Index = (lineLevel.Index + 1);
			end
		end
		-- show member/officer note for player guild
		if (isPlayerGuild) and ((cfg.showGuildMemberNote) or (cfg.showGuildOfficerNote)) then
			local playerGuildClubMemberInfo = LibFroznFunctions:GetPlayerGuildClubMemberInfo(unitRecord.guid);
			
			if (playerGuildClubMemberInfo) then
				if (cfg.showGuildMemberNote) and (playerGuildClubMemberInfo.memberNote) then
					if (lineInfo:GetCount() > 0) then
						lineInfo:Push("\n");
					end
					lineInfo:Push("|cffffd100");
					lineInfo:Push(TT_PlayerGuildMemberNote);
					lineInfo:Push(": ");
					lineInfo:Push(TT_COLOR.text.default:WrapTextInColorCode(playerGuildClubMemberInfo.memberNote));
				end
				
				if (cfg.showGuildOfficerNote) and (playerGuildClubMemberInfo.officerNote) then
					if (lineInfo:GetCount() > 0) then
						lineInfo:Push("\n");
					end
					lineInfo:Push("|cffffd100");
					lineInfo:Push(TT_PlayerGuildOfficerNote);
					lineInfo:Push(": ");
					lineInfo:Push(TT_COLOR.text.default:WrapTextInColorCode(playerGuildClubMemberInfo.officerNote));
				end
			end
		end
	end
end

-- PET Styling
function ttStyle:GeneratePetLines(tip, currentDisplayParams, unitRecord, first)
	lineName:Push(unitRecord.nameColor:WrapTextInColorCode(unitRecord.name));
	lineLevel:Push(" ");
	local petType = UnitBattlePetType(unitRecord.id) or 5;
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(_G["BATTLE_PET_NAME_"..petType] or TT_Unknown));

	if (unitRecord.isWildBattlePet) then
		local race = UnitCreatureFamily(unitRecord.id) or UnitCreatureType(unitRecord.id) or TT_Unknown;
		lineLevel:Push(" ");
		lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(race));
	else -- unitRecord.isBattlePetCompanion
		lineLevel.Index = currentDisplayParams.petLineLevelIndex or 2;
		local expectedLine = 3 + (unitRecord.isColorBlind and 1 or 0);
		if (lineLevel.Index > expectedLine) then
			GameTooltipTextLeft2:SetText(unitRecord.nameColor:WrapTextInColorCode(format("<%s>",unitRecord.petOrBattlePetOrNPCTitle)));
		end
	end
end

-- NPC Styling
function ttStyle:GenerateNpcLines(tip, currentDisplayParams, unitRecord, first)
	-- name
	lineName:Push(unitRecord.nameColor:WrapTextInColorCode(unitRecord.name));

	-- guild/title -- since WoD, npc title can be a single space character
	if (unitRecord.petOrBattlePetOrNPCTitle) and (unitRecord.petOrBattlePetOrNPCTitle ~= " ") then
		-- Az: this doesn't work with "Mini Diablo" or "Mini Thor", which has the format: 1) Mini Diablo 2) Lord of Terror 3) Player's Pet 4) Level 1 Non-combat Pet
		local gttLine = unitRecord.isColorBlind and GameTooltipTextLeft3 or GameTooltipTextLeft2;
		gttLine:SetText(unitRecord.nameColor:WrapTextInColorCode(format("<%s>",unitRecord.petOrBattlePetOrNPCTitle)));
		lineLevel.Index = (lineLevel.Index + 1);
	end

	-- race
	local race = UnitCreatureFamily(unitRecord.id) or UnitCreatureType(unitRecord.id) or TT_Unknown;
	lineLevel:Push(" ");
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(race));
end

-- Modify Tooltip Lines (name + info)
local mapChallengeModeIDToDungeonIndexLookup = {};
local npcIDToEnemyIdxLookup = {};

function ttStyle:ModifyUnitTooltip(tip, currentDisplayParams, unitRecord, first)
	-- obtain unit properties
	unitRecord.reactionColor = CreateColor(unpack(cfg["colorReactText" .. unitRecord.reactionIndex]));
	unitRecord.nameColor = ((not cfg.enableColorName) and CreateColor(GameTooltipTextLeft1:GetTextColor())) or (cfg.colorNameByReaction and unitRecord.reactionColor) or CreateColor(unpack(cfg.colorName));

	-- this is the line index where the level and unit type info is
	lineLevel.Index = 2 + (unitRecord.isColorBlind and UnitIsVisible(unitRecord.id) and 1 or 0);
	
	-- remove unwanted lines from tip
	self:RemoveUnwantedLinesFromTip(tip, unitRecord);
	
	-- highlight TipTac developer
	if (unitRecord.isPlayer) then
		self:HighlightTipTacDeveloper(tip, currentDisplayParams, unitRecord, first);
	end
	
	-- Level + Classification
	lineLevel:Push(((UnitCanAttack(unitRecord.id, "player") or UnitCanAttack("player", unitRecord.id)) and LibFroznFunctions:GetDifficultyColorForUnit(unitRecord.id) or CreateColor(unpack(cfg.colorLevel))):WrapTextInColorCode((cfg["classification_".. (unitRecord.classification or "")] or "%s? "):format(unitRecord.level == -1 and "??" or unitRecord.level)));
	
	-- Reaction Icon
	if (cfg.reactIcon) and (TT_ReactionIcon[unitRecord.reactionIndex]) then
		lineLevel:Push(" " .. LibFroznFunctions:CreateTextureMarkupWithVertexColor("Interface\\AddOns\\" .. MOD_NAME .. "\\media\\" .. TT_ReactionIcon[unitRecord.reactionIndex], 32, 32, nil, nil, 0.219, 0.75, 0.219, 0.75, nil, nil, unitRecord.reactionColor:GetRGB()));
	end
	
	-- Generate Line Modification
	if (unitRecord.isPlayer) then
		self:GeneratePlayerLines(tip, currentDisplayParams, unitRecord, first);
	elseif (cfg.showBattlePetTip) and (unitRecord.isWildBattlePet or unitRecord.isBattlePetCompanion) then
		self:GeneratePetLines(tip, currentDisplayParams, unitRecord, first);
	else
		self:GenerateNpcLines(tip, currentDisplayParams, unitRecord, first);
	end

	-- Current Unit Speed
	if (cfg.showCurrentUnitSpeed) then
		local currentUnitSpeed = GetUnitSpeed(unitRecord.id);
		if (currentUnitSpeed > 0) then
			lineLevel:Push(" " .. CreateAtlasMarkup("glueannouncementpopup-arrow"));
			lineLevel:Push(TT_COLOR.text.unitSpeed:WrapTextInColorCode(format("%.0f%%", currentUnitSpeed / BASE_MOVEMENT_SPEED * 100)));
		end
	end
	
	-- Reaction Text
	if (cfg.reactText) then
		local reactTextColor = (cfg.reactColoredText and unitRecord.reactionColor) or CreateColor(unpack(cfg.colorReactText));
		
		lineLevel:Push("\n");
		lineLevel:Push(reactTextColor:WrapTextInColorCode(TT_ReactionText[unitRecord.reactionIndex]));
	end

	-- Faction Text
	if (unitRecord.isPlayer) and (cfg.factionText) then
		local englishFaction, localizedFaction = LibFroznFunctions:GetUnitFactionGroup(unitRecord.id);
		
		if (englishFaction) then
			local factionTextColor = (cfg.enableColorFaction and cfg["colorFaction" .. englishFaction] and CreateColor(unpack(cfg["colorFaction" .. englishFaction]))) or TT_COLOR.text.default;
			
			lineLevel:Push("\n");
			lineLevel:Push(factionTextColor:WrapTextInColorCode(localizedFaction));
		end
	end

	-- Mythic+ Dungeon Score
	if (unitRecord.isPlayer) and (cfg.showMythicPlusDungeonScore) and (C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
		local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unitRecord.id);
		if (ratingSummary) then
			local mythicPlusDungeonScore = ratingSummary.currentSeasonScore;
			local mythicPlusBestRunLevel;
			if (ratingSummary.runs) then
				for _, ratingMapSummary in ipairs(ratingSummary.runs or {}) do
					if (ratingMapSummary.finishedSuccess) and ((not mythicPlusBestRunLevel) or (mythicPlusBestRunLevel < ratingMapSummary.bestRunLevel)) then
						mythicPlusBestRunLevel = ratingMapSummary.bestRunLevel;
					end
				end
			end
			
			local mythicPlusDungeonScoreText = LibFroznFunctions:CreatePushArray();
			if (cfg.mythicPlusDungeonScoreFormat == "highestSuccessfullRun") then
				if (mythicPlusBestRunLevel) then
					mythicPlusDungeonScoreText:Push(TT_COLOR.text.default:WrapTextInColorCode("+" .. mythicPlusBestRunLevel));
				end
			else
				if (mythicPlusDungeonScore > 0) then
					local mythicPlusDungeonScoreColor = (C_ChallengeMode.GetDungeonScoreRarityColor(mythicPlusDungeonScore) or TT_COLOR.text.default);
					mythicPlusDungeonScoreText:Push(mythicPlusDungeonScoreColor:WrapTextInColorCode(mythicPlusDungeonScore));
				end
			end
			if (mythicPlusDungeonScoreText:GetCount() > 0) then
				if (lineInfo:GetCount() > 0) then
					lineInfo:Push("\n");
				end
				lineInfo:Push("|cffffd100");
				lineInfo:Push(TT_MythicPlusDungeonScore:format(mythicPlusDungeonScoreText:Concat()));
				
				if (cfg.mythicPlusDungeonScoreFormat == "both") and (mythicPlusBestRunLevel) then
					lineInfo:Push(" |cffffff99(+" .. mythicPlusBestRunLevel .. ")|r");
				end
			end
		end
	end

	-- Mythic+ Forces from addon "Mythic Dungeon Tools" (MDT) for NPCs
	if (MDT) and (unitRecord.isNPC) and (cfg.showMythicPlusForcesFromMDT) and (C_MythicPlus.IsMythicPlusActive()) and (UnitCanAttack("player", unitRecord.id)) then
		local mapChallengeModeID = C_ChallengeMode.GetActiveChallengeMapID();
		
		if (mapChallengeModeID) then
			local dungeonIndex = mapChallengeModeIDToDungeonIndexLookup[mapChallengeModeID];
			
			if (not dungeonIndex) then
				for _dungeonIndex, mapInfo in pairs(MDT.mapInfo) do
					if (mapInfo.mapID == mapChallengeModeID) then
						dungeonIndex = _dungeonIndex;
						mapChallengeModeIDToDungeonIndexLookup[mapChallengeModeID] = dungeonIndex;
						break;
					end
				end
			end
			
			if (dungeonIndex) then
				local dungeonEnemies = MDT.dungeonEnemies[dungeonIndex];
				
				if (dungeonEnemies) then
					local enemyIdx = (npcIDToEnemyIdxLookup[mapChallengeModeID] and npcIDToEnemyIdxLookup[mapChallengeModeID][unitRecord.npcID]);
					
					if (not enemyIdx) then
						for _enemyIdx, _dungeonEnemy in pairs(dungeonEnemies) do
							if (_dungeonEnemy.id == unitRecord.npcID) then
								enemyIdx = _enemyIdx;
								
								if (not npcIDToEnemyIdxLookup[mapChallengeModeID]) then
									npcIDToEnemyIdxLookup[mapChallengeModeID] = {};
								end
								
								npcIDToEnemyIdxLookup[mapChallengeModeID][unitRecord.npcID] = enemyIdx;
								
								break;
							end
						end
					end
					
					if (enemyIdx) then
						local dungeonEnemy = MDT.dungeonEnemies[dungeonIndex][enemyIdx];
						
						if (dungeonEnemy) then
							local dungeonTotalCount = MDT.dungeonTotalCount[dungeonIndex];
							local isTeeming = false;
							local activeKeystoneLevel, activeAffixIDs, wasActiveKeystoneCharged = C_ChallengeMode.GetActiveKeystoneInfo();
							
							if (activeAffixIDs) then
								for _, activeAffixID in ipairs(activeAffixIDs) do
									if (activeAffixID == 5) then -- teeming
										isTeeming = true;
										break;
									end
								end
							end
							
							local countEnemyForces = (isTeeming and dungeonEnemy.teemingCount or dungeonEnemy.count);
							local maxCountEnemyForces = (dungeonTotalCount) and (isTeeming and dungeonTotalCount.teeming or dungeonTotalCount.normal);
							
							if (countEnemyForces) then
								if (lineInfo:GetCount() > 0) then
									lineInfo:Push("\n");
								end
								
								lineInfo:Push("|cffffd100");
								lineInfo:Push(MDT.L["Forces"] .. " (MDT): " .. TT_COLOR.text.default:WrapTextInColorCode(countEnemyForces));
								
								if (maxCountEnemyForces) then
									lineInfo:Push(TT_COLOR.text.mythicPlusPercentMaxCountEnemyForces:WrapTextInColorCode(format(" (%.2f%%)", (countEnemyForces / maxCountEnemyForces) * 100)));
								end
							end
						end
					end
				end
			end
		end
	end

	-- Mount
	local lineMount = LibFroznFunctions:CreatePushArray();
	local lineMountLore = LibFroznFunctions:CreatePushArray();
	
	if (unitRecord.isPlayer) and (cfg.showMount) then
		local unitID, filter = unitRecord.id, LFF_AURA_FILTERS.Helpful;
		local index = 0;
		
		LibFroznFunctions:ForEachAura(unitID, filter, nil, function(unitAuraInfo)
			index = index + 1;
			
			local spellID = unitAuraInfo.spellId;
			
			if (spellID) then
				local mountID = LibFroznFunctions:GetMountFromSpell(spellID);
				
				if (mountID) then
					-- determine if mount has already been collected
					local mountText = LibFroznFunctions:CreatePushArray();
					local spacer;
					local mountIsCollected;
					local mountNameAdded = false;
					local mountSourceAdded = false;
					
					if (cfg.showMountCollected) or (cfg.showMountSourceIfNotCollected) then
						mountIsCollected = LibFroznFunctions:IsMountCollected(mountID);
					end
					
					if (cfg.showMountCollected) then
						if (mountIsCollected) then
							-- mountText:Push(CreateAtlasMarkup("common-icon-checkmark")); -- available in DF, but not available in WotLKC
							mountText:Push(CreateTextureMarkup("Interface\\AddOns\\" .. MOD_NAME .. "\\media\\CommonIcons", 64, 64, 0, 0, 0.000488281, 0.125488, 0.504883, 0.754883));
						else
							-- mountText:Push(CreateAtlasMarkup("common-icon-redx")); -- available in DF, but not available in WotLKC
							mountText:Push(CreateTextureMarkup("Interface\\AddOns\\" .. MOD_NAME .. "\\media\\CommonIcons", 64, 64, 0, 0, 0.126465, 0.251465, 0.504883, 0.754883));
						end
					end
					
					-- determine mount icon
					if (cfg.showMountIcon) and (unitAuraInfo.icon) then
						mountText:Push(CreateTextureMarkup(unitAuraInfo.icon, 64, 64, 0, 0, 0.07, 0.93, 0.07, 0.93));
					end
					
					-- determine mount name
					if (cfg.showMountText) and (unitAuraInfo.name) then
						spacer = (mountText:GetCount() > 0) and " " or "";
						
						mountText:Push(spacer .. TT_COLOR.text.mountName:WrapTextInColorCode(unitAuraInfo.name));
						
						mountNameAdded = true;
					end
					
					-- determine mount speed
					if (cfg.showMountSpeed) then
						spacer = (mountText:GetCount() > 0) and " " or "";
						
						local auraDescription = LibFroznFunctions:GetAuraDescription(unitID, index, filter, function(_auraDescription)
							if (_auraDescription) and (not LibFroznFunctions:ExistsInTable(_auraDescription, { LFF_AURA_DESCRIPTION.available, LFF_AURA_DESCRIPTION.none })) then
								tt:UpdateUnitAppearanceToTip(tip, true);
							end
						end);
						
						local mountSpeeds = LibFroznFunctions:CreatePushArray();
						
						if (auraDescription) and (not LibFroznFunctions:ExistsInTable(auraDescription, { LFF_AURA_DESCRIPTION.available, LFF_AURA_DESCRIPTION.none })) then
							for mountSpeed in auraDescription:gmatch("(%d+)%%") do
								mountSpeeds:Push(mountSpeed);
							end
						end
						
						if (mountSpeeds:GetCount() > 0) then
							if (mountNameAdded) then
								mountText:Push(spacer .. TT_COLOR.text.mountSpeed:WrapTextInColorCode("(" .. mountSpeeds:Concat("/") .. "%)"));
							else
								mountText:Push(spacer .. TT_COLOR.text.mountSpeed:WrapTextInColorCode(mountSpeeds:Concat("/") .. "%"));
							end
						end
					end
					
					-- determine mount source and lore
					if (cfg.showMountSourceIfNotCollected) or (cfg.showMountSource) or (cfg.showMountLore) then
						local _, description, source = C_MountJournal.GetMountInfoExtraByID(mountID);
						
						spacer = string.rep(" ", 4);
						
						if (cfg.showMountSourceIfNotCollected) and (not mountIsCollected) or (cfg.showMountSource) then
							local cleanedSource = "";
							
							if (type(source) == "string") then
								cleanedSource = strtrim(source);
								
								if (cleanedSource ~= "") then
									cleanedSource = LibFroznFunctions:RemovePatternFromEndOfTextMultipleTimes(cleanedSource, "|n");
									cleanedSource = LibFroznFunctions:RemoveColorsFromText(cleanedSource);
								end
							end
							
							if (cleanedSource ~= "") then
								if (mountText:GetCount() > 0) then
									mountText:Push("\n");
								end
								
								mountText:Push(spacer .. TT_COLOR.text.mountSource:WrapTextInColorCode(cleanedSource:gsub("|n", "|n" .. spacer)));
								
								mountSourceAdded = true;
							end
						end
						
						if (cfg.showMountLore) then
							local cleanedDescription = "";
							
							if (type(description) == "string") then
								cleanedDescription = strtrim(description);
								
								if (cleanedDescription ~= "") then
									cleanedDescription = LibFroznFunctions:RemovePatternFromEndOfTextMultipleTimes(cleanedDescription, "|n");
									cleanedDescription = LibFroznFunctions:RemoveColorsFromText(cleanedDescription);
								end
							end
							
							if (cleanedDescription ~= "") then
								local mountLoreText = TT_COLOR.text.mountLore:WrapTextInColorCode(cleanedDescription:gsub("|n", "|n" .. spacer));
								
								if (mountText:GetCount() > 0) then
									if (mountSourceAdded) then
										lineMountLore:Push("\n" .. spacer .. mountLoreText);
									else
										lineMountLore:Push(spacer .. mountLoreText);
									end
								else
									lineMountLore:Push(TT_Mount:format(mountLoreText));
								end
							end
						end
					end
					
					-- set mount text
					if (mountText:GetCount() > 0) then
						lineMount:Push(TT_Mount:format(mountText:Concat()));
					end
					
					return true;
				end
			end
		end, true);
	end

	-- Target
	if (cfg.showTarget ~= "none") then
		self:GenerateTargetLines(unitRecord, cfg.showTarget);
	end

	-- Targeted by
	if (cfg.showTargetedBy) then
		self:GenerateTargetedByLines(unitRecord);
	end

	-- Name Line
	local tipLineNameText = lineName:Concat();
	
	if (lineRealm:GetCount() > 0) then
		tipLineNameText = tipLineNameText .. "\n" .. lineRealm:Concat();
	end
	
	GameTooltipTextLeft1:SetText(tipLineNameText);
	lineName:Clear();
	lineRealm:Clear();

	-- Level Line
	for i = (GameTooltip:NumLines() + 1), lineLevel.Index do
		GameTooltip:AddLine(" ");
	end
	
	local gttLine = _G["GameTooltipTextLeft" .. lineLevel.Index];
	
	-- 8.2 made the default XML template have only 2 lines, so it's possible to get here without the desired line existing (yet?)
	-- Frozn45: The problem showed up in classic. Fixed it with adding the missing lines (see for-loop with GameTooltip:AddLine() above).
	if (gttLine) then
		local tipLineLevelText = TT_COLOR.text.default:WrapTextInColorCode(lineLevel:Concat());
		
		if (currentDisplayParams.mergeLevelLineWithGuildName) then
			local gttLineText = gttLine:GetText();
			
			gttLine:SetText((gttLineText) and (gttLineText ~= " ") and (gttLineText .. "\n" .. tipLineLevelText) or tipLineLevelText);
		else
			gttLine:SetText(tipLineLevelText);
		end
	end

	lineLevel:Clear();
	
	-- Info Line
	if (lineInfo:GetCount() > 0) then
		local tipLineInfoText = lineInfo:Concat();
		
		if (currentDisplayParams.tipLineInfoIndex) then
			_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineInfoIndex]:SetText(tipLineInfoText);
		else
			GameTooltip:AddLine(tipLineInfoText);
			currentDisplayParams.tipLineInfoIndex = GameTooltip:NumLines();
		end
		
		lineInfo:Clear();
	elseif (currentDisplayParams.tipLineInfoIndex) then
		_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineInfoIndex]:SetText(nil);
	end
	
	-- Mount Line
	if (lineMount:GetCount() > 0) then
		local tipLineMountText = lineMount:Concat();
		
		if (currentDisplayParams.tipLineMountIndex) then
			_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineMountIndex]:SetText(tipLineMountText);
		else
			GameTooltip:AddLine(tipLineMountText);
			currentDisplayParams.tipLineMountIndex = GameTooltip:NumLines();
		end
		
		lineMount:Clear();
	elseif (currentDisplayParams.tipLineMountIndex) then
		_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineMountIndex]:SetText(nil);
	end
	
	-- Mount Lore Line
	if (lineMountLore:GetCount() > 0) then
		local tipLineMountLoreText = lineMountLore:Concat();
		
		if (currentDisplayParams.tipLineMountLoreIndex) then
			_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineMountLoreIndex]:SetText(tipLineMountLoreText);
		else
			GameTooltip:AddLine(tipLineMountLoreText, nil, nil, nil, true);
			currentDisplayParams.tipLineMountLoreIndex = GameTooltip:NumLines();
		end
		
		lineMountLore:Clear();
	elseif (currentDisplayParams.tipLineMountLoreIndex) then
		_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineMountLoreIndex]:SetText(nil);
	end
	
	-- Targeted By Line
	if (lineTargetedBy:GetCount() > 0) then
		local tipLineTargetedByText = format(TT_TargetedBy .. " (" .. TT_COLOR.text.default:WrapTextInColorCode(format("%d", lineTargetedBy:GetCount())) .. "): %s", TT_COLOR.text.default:WrapTextInColorCode(lineTargetedBy:Concat(", ")));
		
		if (currentDisplayParams.tipLineTargetedByIndex) then
			_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineTargetedByIndex]:SetText(tipLineTargetedByText);
		else
			GameTooltip:AddLine(tipLineTargetedByText, nil, nil, nil, true);
			currentDisplayParams.tipLineTargetedByIndex = GameTooltip:NumLines();
		end
		
		lineTargetedBy:Clear();
	elseif (currentDisplayParams.tipLineTargetedByIndex) then
		_G["GameTooltipTextLeft" .. currentDisplayParams.tipLineTargetedByIndex]:SetText(nil);
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttStyle:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

function ttStyle:OnTipSetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams, tipContent)
	-- set current display params for unit appearance
	currentDisplayParams.tipLineInfoIndex = nil;
	currentDisplayParams.tipLineMountIndex = nil;
	currentDisplayParams.tipLineMountLoreIndex = nil;
	currentDisplayParams.tipLineTargetedByIndex = nil;
	currentDisplayParams.petLineLevelIndex = nil;
	currentDisplayParams.mergeLevelLineWithGuildName = nil;
	currentDisplayParams.isSetTopOverlayToHighlightTipTacDeveloper = nil;
	currentDisplayParams.isSetBottomOverlayToHighlightTipTacDeveloper = nil;
end

function ttStyle:OnUnitTipStyle(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- check if modification of unit tip content is enabled
	if (not cfg.showUnitTip) then
		return;
	end
	
	-- some things only need to be done once initially when the tip is first displayed
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (first) then
		-- get unit tooltip data because current unit tip may already have been manipulated (e.g. by addon "ElvUI")
		local unitTooltipData = LibFroznFunctions:GetTooltipInfo("GetUnit", unitRecord.id)
		
		unitRecord.isColorBlind = (GetCVar("colorblindMode") == "1");
		unitRecord.originalName = (unitTooltipData) and (unitTooltipData.lines[1]) and (unitTooltipData.lines[1].leftText);
		
		-- find pet, battle pet or NPC title
		if (unitRecord.isPet) or (unitRecord.isBattlePet) or (unitRecord.isNPC) then
			unitRecord.petOrBattlePetOrNPCTitle = nil;
			
			if (unitTooltipData) then
				if (unitRecord.isColorBlind) then
					if (unitTooltipData.lines[3]) then
						unitRecord.petOrBattlePetOrNPCTitle = unitTooltipData.lines[3].leftText;
					end
				else
					if (unitTooltipData.lines[2]) then
						unitRecord.petOrBattlePetOrNPCTitle = unitTooltipData.lines[2].leftText;
					end
				end
			end
			
			if (type(unitRecord.petOrBattlePetOrNPCTitle) == "string") and (unitRecord.petOrBattlePetOrNPCTitle:find(TT_LevelMatch)) then
				unitRecord.petOrBattlePetOrNPCTitle = nil;
			end
		
		-- find battle pet companion level line
		elseif (unitRecord.isBattlePetCompanion) then
			for i = 2, min(#unitTooltipData.lines, 4) do
				local gttLineText = unitTooltipData.lines[i].leftText;
				if (type(gttLineText) == "string") and (gttLineText:find(TT_LevelMatchPet)) then
					currentDisplayParams.petLineLevelIndex = i;
					break;
				end
			end
		end

		-- remember reaction in color blind mode if there is no separate line for guild name
		if (not LibFroznFunctions.hasWoWFlavor.guildNameInPlayerUnitTip) and (unitRecord.isColorBlind) and (unitTooltipData) and (unitTooltipData.lines[2]) then
			unitRecord.reactionTextInColorBlindMode = unitTooltipData.lines[2].leftText;
		end
	end

	self:ModifyUnitTooltip(tip, currentDisplayParams, unitRecord, first);
end

function ttStyle:OnTipResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- hide tip's top/bottom overlay currently highlighting TipTac developer
	if (currentDisplayParams.isSetTopOverlayToHighlightTipTacDeveloper) and (tip.TopOverlay) then
		tip.TopOverlay:Hide();
	end
	if (currentDisplayParams.isSetBottomOverlayToHighlightTipTacDeveloper) and (tip.BottomOverlay) then
		tip.BottomOverlay:Hide();
	end
	
	-- reset current display params for unit appearance
	currentDisplayParams.tipLineInfoIndex = nil;
	currentDisplayParams.tipLineMountIndex = nil;
	currentDisplayParams.tipLineMountLoreIndex = nil;
	currentDisplayParams.tipLineTargetedByIndex = nil;
	currentDisplayParams.petLineLevelIndex = nil;
	currentDisplayParams.mergeLevelLineWithGuildName = nil;
	currentDisplayParams.isSetTopOverlayToHighlightTipTacDeveloper = nil;
	currentDisplayParams.isSetBottomOverlayToHighlightTipTacDeveloper = nil;
end
