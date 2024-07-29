-----------------------------------------------------------------------
-- TipTac - Hyperlink
--
-- Shows the corresponding tooltips if hovering over hyperlinks.
--

-- create addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- register with TipTac core addon
local tt = _G[MOD_NAME];
local ttHyperlink = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttHyperlink, MOD_NAME .. " - Hyperlink Module");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- hyperlink types which are supported
local supportedHyperLinkTypes = {
	achievement = "default",
	azessence = "default",
	battlepet = "custom",
	battlePetAbil = "custom",
	conduit = "default",
	currency = "default",
	dungeonScore = "custom",
	enchant = "default",
	glyph = "default",
	instancelock = "default",
	item = "default",
	keystone = "default",
	mawpower = "default",
	pvptal = "custom",
	quest = "default",
	spell = "default",
	talent = "default",
	transmogappearance = "custom",
	transmogillusion = "custom",
	transmogset = "custom",
	unit = "default"
};

----------------------------------------------------------------------------------------------------
--                                         Element Events                                         --
----------------------------------------------------------------------------------------------------

-- config has been loaded
function ttHyperlink:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	-- set config
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

-- config settings need to be applied
local eventsForChatFrameHooked = false;
local eventsForCommunitiesChatFrameHooked = false;

local function hookChatFrameFn(chatFrame)
	chatFrame:HookScript("OnHyperlinkEnter", function(...)
		ttHyperlink:ShowTip(...);
	end);
	
	chatFrame:HookScript("OnHyperlinkLeave", function(...)
		ttHyperlink:HideTip(...);
	end);
end

function ttHyperlink:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- hook chat frames for hovering over hyperlinks
	if (not eventsForChatFrameHooked) then
		for i = 1, NUM_CHAT_WINDOWS do
			local chatFrame = _G["ChatFrame" .. i];
			
			hookChatFrameFn(chatFrame);
		end
		
		eventsForChatFrameHooked = true;
	end
	
	if (not eventsForCommunitiesChatFrameHooked) then
		if (LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Communities")) then
			local chatFrame = CommunitiesFrame.Chat.MessageFrame;
			
			hookChatFrameFn(chatFrame);
			
			eventsForCommunitiesChatFrameHooked = true;
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                          Setup Module                                          --
----------------------------------------------------------------------------------------------------

-- show tip
local showingTooltip;

function ttHyperlink:ShowTip(chatFrame, refString, text)
	-- check if corresponding tooltips for hovering over hyperlinks are enabled
	if (not cfg.enableChatHoverTips) then
		return;
	end
	
	-- not supported hyperlink type
	local linkType = refString:match("^[^:]+");
	
	if (not supportedHyperLinkTypes[linkType]) then
		return;
	end
	
	-- set default anchor to GameTooltip
	GameTooltip_SetDefaultAnchor(GameTooltip, chatFrame);
	
	-- show tip for hyperlink type
	if (supportedHyperLinkTypes[linkType] == "default") then
		ttHyperlink:ShowDefaultTipForTypes(chatFrame, refString, text);
	else
		ttHyperlink["ShowTipForType" .. LibFroznFunctions:CamelCaseText(linkType)](self, chatFrame, refString, text);
	end
end

-- hide tip
function ttHyperlink:HideTip(chatFrame)
	-- currently no showing tooltip
	if (not showingTooltip) then
		return;
	end
	
	-- hide tip
	showingTooltip:Hide();
	
	showingTooltip = nil;
end

----------------------------------------------------------------------------------------------------
--                                    Tips For Hyperlink Types                                    --
----------------------------------------------------------------------------------------------------

-- show default tip for hyperlink types
function ttHyperlink:ShowDefaultTipForTypes(chatFrame, refString, text)
	showingTooltip = GameTooltip;
	
	GameTooltip:SetHyperlink(refString);
	GameTooltip:Show();
end

-- show tip for hyperlink type "battlepet"
function ttHyperlink:ShowTipForTypeBattlepet(chatFrame, refString, text)
	showingTooltip = BattlePetTooltip;
	
	BattlePetToolTip_ShowLink(text);
	
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetDefaultAnchorHook", showingTooltip, chatFrame);
end

-- show tip for hyperlink type "battlePetAbil"
function ttHyperlink:ShowTipForTypeBattlepetabil(chatFrame, refString, text)
	-- make shure that PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip exist
	if (not LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Collections")) then
		C_AddOns.LoadAddOn("Blizzard_Collections");
	end
	
	-- show tip
	showingTooltip = PetJournalPrimaryAbilityTooltip;
	
	local link, abilityID, maxHealth, power, speed = (":"):split(refString);
	
	PetJournal_ShowAbilityTooltip(GameTooltip, tonumber(abilityID));
	showingTooltip:ClearAllPoints();
	showingTooltip:SetPoint(GameTooltip:GetPoint());
	
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetDefaultAnchorHook", showingTooltip, chatFrame);
end

-- show tip for hyperlink type "dungeonScore"
function ttHyperlink:ShowTipForTypeDungeonscore(chatFrame, refString, text)
	-- see GetDungeonScoreLink() + DisplayDungeonScoreLink() in "ItemRef.lua"
	local splits = StringSplitIntoTable(":", refString);
	
	--Bad Link, Return.
	if (not splits) then
		return;
	end
	
	local dungeonScore = tonumber(splits[2]);
	local playerName = splits[4];
	local playerClass = splits[5];
	local playerItemLevel = tonumber(splits[6]);
	local playerLevel = tonumber(splits[7]);
	local className, classFileName = GetClassInfo(playerClass);
	local classColor = LibFroznFunctions:GetClassColor(playerClass, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
	local runsThisSeason = tonumber(splits[8]);
	local bestSeasonScore = tonumber(splits[9]);
	local bestSeasonNumber = tonumber(splits[10]);
	
	--Bad Link..
	if (not playerName or not playerClass or not playerItemLevel or not playerLevel) then
		return;
	end
	
	--Bad Link..
	if (not className or not classFileName or not classColor) then
		return;
	end
	
	GameTooltip_SetTitle(GameTooltip, classColor:WrapTextInColorCode(playerName));
	GameTooltip_AddColoredLine(GameTooltip, DUNGEON_SCORE_LINK_LEVEL_CLASS_FORMAT_STRING:format(playerLevel, className), HIGHLIGHT_FONT_COLOR);
	GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_ITEM_LEVEL:format(playerItemLevel));
	
	local color = C_ChallengeMode.GetDungeonScoreRarityColor(dungeonScore) or HIGHLIGHT_FONT_COLOR;
	
	GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_RATING:format(color:WrapTextInColorCode(dungeonScore)));
	GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_RUNS_SEASON:format(runsThisSeason));
	
	if (bestSeasonScore ~= 0) then
		local bestSeasonColor = C_ChallengeMode.GetDungeonScoreRarityColor(bestSeasonScore) or HIGHLIGHT_FONT_COLOR;
		
		GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_PREVIOUS_HIGH:format(bestSeasonColor:WrapTextInColorCode(bestSeasonScore), bestSeasonNumber));
	end
	
	GameTooltip_AddBlankLineToTooltip(GameTooltip);
	
	local sortTable = { };
	local DUNGEON_SCORE_LINK_INDEX_START = 11;
	local DUNGEON_SCORE_LINK_ITERATE = 3;
	
	for i = DUNGEON_SCORE_LINK_INDEX_START, (#splits), DUNGEON_SCORE_LINK_ITERATE do
		local mapChallengeModeID = tonumber(splits[i]);
		local completedInTime = tonumber(splits[i + 1]);
		local level = tonumber(splits[i + 2]);
		
		local mapName = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID);
		
		--If any of the maps don't exist.. this is a bad link
		if (not mapName) then
			return;
		end
		
		table.insert(sortTable, { mapName = mapName, completedInTime = completedInTime, level = level });
	end
	
	-- Sort Alphabetically.
	table.sort(sortTable, function(a, b) strcmputf8i(a.mapName, b.mapName); end);
	
	for i = 1, #sortTable do
		local textColor = sortTable[i].completedInTime and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR;
		GameTooltip_AddColoredDoubleLine(GameTooltip, DUNGEON_SCORE_LINK_TEXT1:format(sortTable[i].mapName), (sortTable[i].level > 0 and  DUNGEON_SCORE_LINK_TEXT2:format(sortTable[i].level) or DUNGEON_SCORE_LINK_NO_SCORE), NORMAL_FONT_COLOR, textColor);
	end
	
	-- consider backdrop border color by Class
	if (cfg.classColoredBorder) then
		tt:SetBackdropBorderColorLocked(GameTooltip, classColor.r, classColor.g, classColor.b);
	end
	
	showingTooltip = GameTooltip;
	GameTooltip:Show();
end

-- show tip for hyperlink type "pvptal"
function ttHyperlink:ShowTipForTypePvptal(chatFrame, refString, text)
	-- see PvPTalentSlotButtonMixin:OnEnter() in "Blizzard_ClassTalentUI/Blizzard_PvPTalentSlotTemplates.lua"
	local splits = StringSplitIntoTable(":", refString);
	
	--Bad Link, Return.
	if (not splits) then
		return;
	end
	
	local talentID = tonumber(splits[2]);
	
	--Bad Link..
	if (not talentID) then
		return;
	end
	
	GameTooltip:SetPvpTalent(talentID);
	
	showingTooltip = GameTooltip;
	GameTooltip:Show();
end

-- show tip for hyperlink type "transmogappearance"
function ttHyperlink:ShowTipForTypeTransmogappearance(chatFrame, refString, text)
	-- see WardrobeItemsCollectionMixin:RefreshAppearanceTooltip() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
	local linkType, sourceID = (":"):split(refString);
	local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
	local name, nameColor = CollectionWardrobeUtil.GetAppearanceNameTextAndColor(sourceInfo);
	
	GameTooltip_SetTitle(GameTooltip, name, nameColor);
	
	showingTooltip = GameTooltip;
	GameTooltip:Show();
	
	-- consider TipTacItemRef
	local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
	
	if (TipTacItemRef) then
		TipTacItemRef:SetHyperlink_Hook(GameTooltip, refString);
	end
end

-- show tip for hyperlink type "transmogillusion"
function ttHyperlink:ShowTipForTypeTransmogillusion(chatFrame, refString, text)
	-- see WardrobeItemsModelMixin:OnEnter() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
	local linkType, illusionID = (":"):split(refString);
	local name, hyperlink, sourceText = C_TransmogCollection.GetIllusionStrings(illusionID);
	
	GameTooltip:SetText(name);
	
	if (sourceText) then
		GameTooltip:AddLine(sourceText, 1, 1, 1, 1);
	end
	
	showingTooltip = GameTooltip;
	GameTooltip:Show();
	
	-- consider TipTacItemRef
	local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
	
	if (TipTacItemRef) then
		TipTacItemRef:SetHyperlink_Hook(GameTooltip, hyperlink);
	end
end

-- show tip for hyperlink type "transmogset"
function ttHyperlink:ShowTipForTypeTransmogset(chatFrame, refString, text)
	-- see WardrobeSetsTransmogModelMixin:RefreshTooltip() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
	
	-- makes shure that WardrobeCollectionFrame exists
	if (not LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Collections")) then
		C_AddOns.LoadAddOn("Blizzard_Collections");
	end
	
	-- show tooltip
	local linkType, setID = (":"):split(refString);
	
	local totalQuality = 0;
	local numTotalSlots = 0;
	local waitingOnQuality = false;
	local sourceQualityTable = {};
	local primaryAppearances = C_TransmogSets.GetSetPrimaryAppearances(setID);
	
	for i, primaryAppearance in pairs(primaryAppearances) do
		numTotalSlots = numTotalSlots + 1;
		
		local sourceID = primaryAppearance.appearanceID;
		
		if (sourceQualityTable[sourceID]) then
			totalQuality = totalQuality + sourceQualityTable[sourceID];
		else
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
			
			if (sourceInfo and sourceInfo.quality) then
				sourceQualityTable[sourceID] = sourceInfo.quality;
				totalQuality = totalQuality + sourceInfo.quality;
			else
				waitingOnQuality = true;
			end
		end
	end
	
	showingTooltip = GameTooltip;
	
	if (waitingOnQuality) then
		GameTooltip:SetText(RETRIEVING_ITEM_INFO, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
	else
		local setQuality = (numTotalSlots > 0 and totalQuality > 0) and Round(totalQuality / numTotalSlots) or Enum.ItemQuality.Common;
		local color = ITEM_QUALITY_COLORS[setQuality];
		local setInfo = C_TransmogSets.GetSetInfo(setID);
		
		GameTooltip:SetText(setInfo.name, color.r, color.g, color.b);
		
		if (setInfo.label) then
			GameTooltip:AddLine(setInfo.label);
			GameTooltip:Show();
		end
	end
	
	-- consider TipTacItemRef
	local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
	
	if (TipTacItemRef) then
		TipTacItemRef:SetHyperlink_Hook(GameTooltip, refString);
	end
end
