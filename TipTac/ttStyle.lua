-- Addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- TipTac refs
local tt = _G[MOD_NAME];
local cfg;
local TT_CacheForFrames;

-- element registration
local ttStyle = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttStyle, "Style");

-- vars
local lineName = LibFroznFunctions:CreatePushArray();
local lineLevel = LibFroznFunctions:CreatePushArray();
local lineInfo = LibFroznFunctions:CreatePushArray();
local lineTargetedBy = LibFroznFunctions:CreatePushArray();

-- String Constants
local TT_LevelMatch = "^"..TOOLTIP_UNIT_LEVEL:gsub("%%[^s ]*s",".+"); -- Was changed to match other localizations properly, used to match: "^"..LEVEL.." .+" -- Doesn't actually match the level line on the russian client! [14.02.24] Doesn't match for Italian client either. [18.07.27] changed the pattern, might match non-english clients now
local TT_LevelMatchPet = "^"..TOOLTIP_WILDBATTLEPET_LEVEL_CLASS:gsub("%%[^s ]*s",".+");	-- "^Pet Level .+ .+"
local TT_NotSpecified = "Not specified";
local TT_Targeting = BINDING_HEADER_TARGETING;	-- "Targeting"
local TT_TargetedBy = "Targeted by";
local TT_MythicPlusDungeonScore = CHALLENGE_COMPLETE_DUNGEON_SCORE; -- "Mythic+ Rating"
local TT_Reaction = {
	[LFF_UNIT_REACTION_INDEX.tapped] = "Tapped",                            -- no localized string of this
	[LFF_UNIT_REACTION_INDEX.hostile] = FACTION_STANDING_LABEL2,            -- Hostile
	[LFF_UNIT_REACTION_INDEX.caution] = FACTION_STANDING_LABEL3,            -- Unfriendly
	[LFF_UNIT_REACTION_INDEX.neutral] = FACTION_STANDING_LABEL4,            -- Neutral
	[LFF_UNIT_REACTION_INDEX.friendlyPlayer] = FACTION_STANDING_LABEL5,	    -- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer] = FACTION_STANDING_LABEL5,	-- Friendly
	[LFF_UNIT_REACTION_INDEX.friendlyNPC] = FACTION_STANDING_LABEL5,        -- Friendly
	[LFF_UNIT_REACTION_INDEX.honoredNPC] = FACTION_STANDING_LABEL6,         -- Honored
	[LFF_UNIT_REACTION_INDEX.reveredNPC] = FACTION_STANDING_LABEL7,         -- Revered
	[LFF_UNIT_REACTION_INDEX.exaltedNPC] = FACTION_STANDING_LABEL8,         -- Exalted
	[LFF_UNIT_REACTION_INDEX.dead] = DEAD                                   -- Dead
};

-- colors
local TT_COLOR = {
	text = {
		default = HIGHLIGHT_FONT_COLOR, -- white
		targeting = CreateColor(0.8, 0.8, 0.8, 1), -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
		targetedBy = CreateColor(0.8, 0.8, 0.8, 1), -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
		guildRank = CreateColor(0.8, 0.8, 0.8, 1), -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
		unitSpeed = CreateColor(0.8, 0.8, 0.8, 1) -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
	}
};

local TT_COLOR_TEXT = HIGHLIGHT_FONT_COLOR; -- white
local TT_COLOR_TEXT_TARGETING = CreateColor(0.8, 0.8, 0.8, 1); -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
local TT_COLOR_TEXT_TARGETED_BY = CreateColor(0.8, 0.8, 0.8, 1); -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
local TT_COLOR_TEXT_GUILD_RANK = CreateColor(0.8, 0.8, 0.8, 1); -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
local TT_COLOR_TEXT_UNIT_SPEED = CreateColor(0.8, 0.8, 0.8, 1); -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)

--------------------------------------------------------------------------------------------------------
--                                         Style Unit Tooltip                                         --
--------------------------------------------------------------------------------------------------------

-- structure of unit tooltips:
--
-- GameTooltip lines of the player (determined via: UnitIsUnit(unitID, "player")):
--
-- content                                  color                                                                    example
-- ---------------------------------------  -----------------------------------------------------------------------  ---------------------------------------------------------------------------------------------------
--  1. <name with optional title>           white (HIGHLIGHT_FONT_COLOR), color based on reaction if PvP is enabled  "Camassea", "Camassea, Hand von A'dal", "Camassea die Ehrfurchtgebietende" or "Chefköchin Camassea"
-- [2. <guild>]                             white (HIGHLIGHT_FONT_COLOR)                                             "Blood Omen"
-- [3. <reaction, only colorblind mode>]    white (HIGHLIGHT_FONT_COLOR)                                             "Freundlich"
--  4. <level> - <race>, <class> (Spieler)  white (HIGHLIGHT_FONT_COLOR)                                             "Stufe 60 - Nachtelfe, Druidin (Spieler)"
-- [5. <faction>]                           white (HIGHLIGHT_FONT_COLOR)                                             "Allianz" or "Horde"
-- [6. PvP]                                 white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of other player (determined via: UnitIsPlayer(unitID) and not UnitIsUnit(unitID, "player")):
--
-- content                                  color                                                                    example
-- ---------------------------------------  -----------------------------------------------------------------------  ------------------------------------------
--  1. <name with optional title>[-<realm>] white (HIGHLIGHT_FONT_COLOR), color based on reaction if PvP is enabled  "Zoodirektorin Silvette-Alleria"
-- [2. <guild>[-<realm>]]                   white (HIGHLIGHT_FONT_COLOR)                                             "Die teuflischen Engel-Alleria"
-- [3. <reaction, only colorblind mode>]    white (HIGHLIGHT_FONT_COLOR)                                             "Freundlich"
--  4. <level> - <race>, <class> (Spieler)  white (HIGHLIGHT_FONT_COLOR)                                             "Stufe 70 - Leerenelfe, Jägerin (Spieler)"
--  5. <faction>                            white (HIGHLIGHT_FONT_COLOR)                                             "Allianz" or "Horde"
-- [6. PvP]                                 white (HIGHLIGHT_FONT_COLOR)
--
-- GameTooltip lines of NPC (determined via: not UnitIsPlayer(unitID) and not UnitPlayerControlled(unitID) and not UnitIsBattlePet(unitID)):
--
-- content                                color                         example
-- -------------------------------------  ----------------------------  ----------------------------------------------
--  1. <name>                             color based on reaction       "Melris Malagan" or "Stadtwache von Sturmwind"
-- [2. <reaction, only colorblind mode>]  white (HIGHLIGHT_FONT_COLOR)  "Ehrfürchtig" or "Neutral"
-- [3. <title>]                           white (HIGHLIGHT_FONT_COLOR)  "Hauptmann der Wache"
--  4. <level>                            white (HIGHLIGHT_FONT_COLOR)  "Stufe 70" or "Stufe 30 (Elite)"
--  5. <faction>                          white (HIGHLIGHT_FONT_COLOR)  "Sturmwind"
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

-- remove unwanted lines from tip, such as "PvP", "Alliance" and "Horde".
function ttStyle:RemoveUnwantedLinesFromTip(tip)
	if (not cfg.hidePvpText) and (not cfg.hideFactionText) then
		return;
	end
	
	for i = 2, tip:NumLines() do
		local line = _G["GameTooltipTextLeft" .. i];
		local text = line:GetText();
		
		if (cfg.hidePvpText) and (text == PVP_ENABLED) or (cfg.hideFactionText) and ((text == FACTION_ALLIANCE) or (text == FACTION_HORDE)) then
			line:SetText(nil);
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
			local targetClassColor = LibFroznFunctions:GetClassColor(targetClassID) or TT_COLOR.text.targeting;
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
	if (targetName) and (targetName ~= UNKNOWNOBJECT and targetName ~= "" or UnitExists(target)) then
		if (method == "first") then
			lineName:Push(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(" : "));
			AddTarget(lineName,target,targetName);
		elseif (method == "second") then
			lineName:Push("\n  ");
			AddTarget(lineName,target,targetName);
		elseif (method == "last") then
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
				local unitClassColor = LibFroznFunctions:GetClassColor(unitClassID) or TT_COLOR.text.targetedBy;
				lineTargetedBy:Push(unitClassColor:WrapTextInColorCode(unitName));
			else
				local unitReactionColor = CreateColor(unpack(cfg["colorReactText"..LibFroznFunctions:GetUnitReactionIndex(unit)]));
				lineTargetedBy:Push(unitReactionColor:WrapTextInColorCode(unitName));
			end
		end
	end
end

-- PLAYER Styling
function ttStyle:GeneratePlayerLines(currentDisplayParams, unitRecord, first)
	-- gender
	if (cfg.showPlayerGender) then
		local sex = UnitSex(unitRecord.id);
		if (sex == 2) or (sex == 3) then
			lineLevel:Push(" ");
			lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(sex == 3 and FEMALE or MALE));
		end
	end
	-- race
	lineLevel:Push(" ");
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(UnitRace(unitRecord.id)));
	-- class
	local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5);
	lineLevel:Push(" ");
	lineLevel:Push(classColor:WrapTextInColorCode(unitRecord.className));
	-- name
	local name = (cfg.nameType == "marysueprot" and unitRecord.rpName) or (cfg.nameType == "original" and unitRecord.originalName) or (cfg.nameType == "title" and UnitPVPName(unitRecord.id)) or unitRecord.name;
	if (unitRecord.serverName) and (unitRecord.serverName ~= "") and (cfg.showRealm ~= "none") then
		if (cfg.showRealm == "show") then
			name = name .. " - " .. unitRecord.serverName;
		else
			name = name .. " (*)";
		end
	end
	lineName:Push(cfg.colorNameByClass and classColor:WrapTextInColorCode(name) or unitRecord.reactionColor:WrapTextInColorCode(name));
	-- dc, afk or dnd
	if (cfg.showStatus) then
		local status = (not UnitIsConnected(unitRecord.id) and " <DC>") or (UnitIsAFK(unitRecord.id) and " <AFK>") or (UnitIsDND(unitRecord.id) and " <DND>");
		if (status) then
			lineName:Push(HIGHLIGHT_FONT_COLOR:WrapTextInColorCode(status));
		end
	end
	-- guild
	-- local guild, guildRank = GetGuildInfo(unitRecord.id);
	local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo(unitRecord.id);
	if (guildName) then
		local playerGuildName = GetGuildInfo("player");
		local guildColor = (guildName == playerGuildName and CreateColor(unpack(cfg.colorSameGuild)) or cfg.colorGuildByReaction and unitRecord.reactionColor or CreateColor(unpack(cfg.colorGuild)));
		local text = guildColor:WrapTextInColorCode(format("<%s>", guildName));
		if (cfg.showGuildRank and guildRankName) then
			if (cfg.guildRankFormat == "title") then
				text = text .. TT_COLOR.text.guildRank:WrapTextInColorCode(format(" %s", guildRankName));
			elseif (cfg.guildRankFormat == "both") then
				text = text .. TT_COLOR.text.guildRank:WrapTextInColorCode(format(" %s (%s)", guildRankName, guildRankIndex));
			elseif (cfg.guildRankFormat == "level") then
				text = text .. TT_COLOR.text.guildRank:WrapTextInColorCode(format(" %s", guildRankIndex));
			end
		end
		GameTooltipTextLeft2:SetText(text);
		lineLevel.Index = (lineLevel.Index + 1);
	end
end

-- PET Styling
function ttStyle:GeneratePetLines(currentDisplayParams, unitRecord, first)
	lineName:Push(unitRecord.reactionColor:WrapTextInColorCode(unitRecord.name));
	lineLevel:Push(" ");
	local petType = UnitBattlePetType(unitRecord.id) or 5;
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(_G["BATTLE_PET_NAME_"..petType]));

	if (unitRecord.isWildBattlePet) then
		lineLevel:Push(" ");
		lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(UnitCreatureFamily(unitRecord.id) or UnitCreatureType(unitRecord.id)));
	else
		if not (currentDisplayParams.petLineLevelIndex) then
			for i = 2, GameTooltip:NumLines() do
				local gttLineText = _G["GameTooltipTextLeft"..i]:GetText();
				if (type(gttLineText) == "string") and (gttLineText:find(TT_LevelMatchPet)) then
					currentDisplayParams.petLineLevelIndex = i;
					break;
				end
			end
		end
		lineLevel.Index = currentDisplayParams.petLineLevelIndex or 2;
		local expectedLine = 3 + (unitRecord.isColorBlind and 1 or 0);
		if (lineLevel.Index > expectedLine) then
			GameTooltipTextLeft2:SetText(unitRecord.reactionColor:WrapTextInColorCode(format("<%s>",unitRecord.battlePetOrNPCTitle)));
		end
	end
end

-- NPC Styling
function ttStyle:GenerateNpcLines(currentDisplayParams, unitRecord, first)
	-- name
	lineName:Push(unitRecord.reactionColor:WrapTextInColorCode(unitRecord.name));

	-- guild/title -- since WoD, npc title can be a single space character
	if (unitRecord.battlePetOrNPCTitle) and (unitRecord.battlePetOrNPCTitle ~= " ") then
		-- Az: this doesn't work with "Mini Diablo" or "Mini Thor", which has the format: 1) Mini Diablo 2) Lord of Terror 3) Player's Pet 4) Level 1 Non-combat Pet
		local gttLine = unitRecord.isColorBlind and GameTooltipTextLeft3 or GameTooltipTextLeft2;
		gttLine:SetText(unitRecord.reactionColor:WrapTextInColorCode(format("<%s>",unitRecord.battlePetOrNPCTitle)));
		lineLevel.Index = (lineLevel.Index + 1);
	end

	-- class
	local class = UnitCreatureFamily(unitRecord.id) or UnitCreatureType(unitRecord.id);
	if (not class or class == TT_NotSpecified) then
		class = UNKNOWN;
	end
	lineLevel:Push(" ");
	lineLevel:Push(CreateColor(unpack(cfg.colorRace)):WrapTextInColorCode(class));
end

-- Modify Tooltip Lines (name + info)
function ttStyle:ModifyUnitTooltip(tip, currentDisplayParams, unitRecord, first)
	-- obtain unit properties
	unitRecord.reactionColor = CreateColor(unpack(cfg["colorReactText" .. unitRecord.reactionIndex]));

	-- this is the line index where the level and unit type info is
	lineLevel.Index = 2 + (unitRecord.isColorBlind and UnitIsVisible(unitRecord.id) and 1 or 0);
	
	-- remove unwanted lines from tip
	self:RemoveUnwantedLinesFromTip(tip);
	
	-- Level + Classification
	lineLevel:Push(((UnitCanAttack(unitRecord.id, "player") or UnitCanAttack("player", unitRecord.id)) and LibFroznFunctions:GetDifficultyColorForUnit(unitRecord.id) or CreateColor(unpack(cfg.colorLevel))):WrapTextInColorCode((cfg["classification_".. (unitRecord.classification or "")] or "%s? "):format(unitRecord.level == -1 and "??" or unitRecord.level)));
	
	-- Generate Line Modification
	if (unitRecord.isPlayer) then
		self:GeneratePlayerLines(currentDisplayParams, unitRecord, first);
	elseif (cfg.showBattlePetTip) and (unitRecord.isWildBattlePet or unitRecord.isBattlePetCompanion) then
		self:GeneratePetLines(currentDisplayParams, unitRecord, first);
	else
		self:GenerateNpcLines(currentDisplayParams, unitRecord, first);
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
		lineLevel:Push(reactTextColor:WrapTextInColorCode(TT_Reaction[unitRecord.reactionIndex]));
	end

	-- Mythic+ Dungeon Score
	if (unitRecord.isPlayer) and (cfg.showMythicPlusDungeonScore) and (C_PlayerInfo.GetPlayerMythicPlusRatingSummary) then
		local ratingSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unitRecord.id);
		if (ratingSummary) then
			local mythicPlusDungeonScore = ratingSummary.currentSeasonScore;
			local mythicPlusBestRunLevel;
			for _, ratingMapSummary in ipairs(ratingSummary.runs or {}) do
				if (ratingMapSummary.finishedSuccess) and ((not mythicPlusBestRunLevel) or (mythicPlusBestRunLevel < ratingMapSummary.bestRunLevel)) then
					mythicPlusBestRunLevel = ratingMapSummary.bestRunLevel;
				end
			end
			if (mythicPlusDungeonScore > 0) then
				if (lineInfo:GetCount() > 0) then
					lineInfo:Push("\n");
				end
				lineInfo:Push("|cffffd100");
				lineInfo:Push(TT_MythicPlusDungeonScore:format(C_ChallengeMode.GetDungeonScoreRarityColor(mythicPlusDungeonScore):WrapTextInColorCode(mythicPlusDungeonScore) .. (mythicPlusBestRunLevel and " |cffffff99(+" .. mythicPlusBestRunLevel .. ")|r" or "")));
			end
		end
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
	GameTooltipTextLeft1:SetText(lineName:Concat());
	lineName:Clear();

	-- Level Line
	for i = (GameTooltip:NumLines() + 1), lineLevel.Index do
		GameTooltip:AddLine(" ");
	end
	
	local gttLine = _G["GameTooltipTextLeft" .. lineLevel.Index];
	
	-- 8.2 made the default XML template have only 2 lines, so it's possible to get here without the desired line existing (yet?)
	-- Frozn45: The problem showed up in classic. Fixed it with adding the missing lines (see for-loop with GameTooltip:AddLine() above).
	if (gttLine) then
		gttLine:SetText(TT_COLOR.text.default:WrapTextInColorCode(lineLevel:Concat()));
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
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttStyle:OnConfigLoaded(_TT_CacheForFrames, _cfg)
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
end

function ttStyle:OnTipSetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams, tipContent)
	-- set current display params for unit appearance
	currentDisplayParams.tipLineInfoIndex = nil;
	currentDisplayParams.tipLineTargetedByIndex = nil;
	currentDisplayParams.petLineLevelIndex = nil;
end

function ttStyle:OnTipStyle(TT_CacheForFrames, tip, first)
	local currentDisplayParams = TT_CacheForFrames[tip].currentDisplayParams;
	local unitRecord = currentDisplayParams.unitRecord;
	
	-- some things only need to be done once initially when the tip is first displayed
	if (first) then
		-- find battle pet or NPC title
		if (unitRecord.isBattlePet) or (unitRecord.isNPC) then
			unitRecord.battlePetOrNPCTitle = (unitRecord.isColorBlind and GameTooltipTextLeft3 or GameTooltipTextLeft2):GetText();
			if (unitRecord.battlePetOrNPCTitle) and (unitRecord.battlePetOrNPCTitle:find(TT_LevelMatch)) then
				unitRecord.battlePetOrNPCTitle = nil;
			end
		end
	end

	self:ModifyUnitTooltip(tip, currentDisplayParams, unitRecord, first);
end

function ttStyle:OnTipResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- reset current display params for unit appearance
	currentDisplayParams.tipLineInfoIndex = nil;
	currentDisplayParams.tipLineTargetedByIndex = nil;
	currentDisplayParams.petLineLevelIndex = nil;
end
