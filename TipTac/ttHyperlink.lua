local AceHook = LibStub("AceHook-3.0");

-- Addon
local MOD_NAME = ...;
local ttHyperlink = CreateFrame("Frame", MOD_NAME .. "Hyperlink");

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- TipTac refs
local tt = _G[MOD_NAME];
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- element registration
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttHyperlink, "Hyperlink");

-- Hyperlinks which are supported
local supportedHyperLinks = {
	item = true,
	spell = true,
	unit = true,
	quest = true,
	enchant = true,
	achievement = true,
	instancelock = true,
	talent = true,
	glyph = true,
	battlepet = true,
	battlePetAbil = true,
	transmogappearance = true,
	transmogillusion = true,
	transmogset = true,
	conduit = true,
	currency = true,
	azessence = true,
	mawpower = true,
	dungeonScore = true,
	keystone = true,
};

local addOnsLoaded = {
	[MOD_NAME] = false,
	["Blizzard_Communities"] = false
};

local itemsCollectionFrame = nil;

--------------------------------------------------------------------------------------------------------
--                                       TipTac Hyperlink Frame                                       --
--------------------------------------------------------------------------------------------------------

ttHyperlink:SetScript("OnEvent",function(self,event,...) self[event](self,event,...); end);

ttHyperlink:RegisterEvent("VARIABLES_LOADED");
ttHyperlink:RegisterEvent("ADDON_LOADED");

-- Variables Loaded [One-Time-Event]
function ttHyperlink:VARIABLES_LOADED(event)
	-- Re-Trigger event ADDON_LOADED for TipTac if config wasn't ready
	self:ADDON_LOADED("ADDON_LOADED", MOD_NAME);
	
	-- Cleanup
	self:UnregisterEvent(event);
	self[event] = nil;
end

-- AddOn Loaded
function ttHyperlink:ADDON_LOADED(event, addOnName, containsBindings)
	if (not cfg) then return end;
	
	-- check if addon is already loaded
	if (addOnsLoaded[addOnName] == nil) or (addOnsLoaded[addOnName]) then
		return;
	end
	
	-- now CommunitiesGuildNewsFrame exists
	if (addOnName == "Blizzard_Communities") or ((addOnName == MOD_NAME) and (LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Communities")) and (not addOnsLoaded['Blizzard_Communities'])) then
		self:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
		
		if (addOnName == MOD_NAME) then
			addOnsLoaded["Blizzard_Communities"] = true;
		end
	end
	
	addOnsLoaded[addOnName] = true;
	
	-- Cleanup if all addons are loaded
	local allAddOnsLoaded = true;
	
	for addOn, isLoaded in pairs(addOnsLoaded) do
		if (not isLoaded) then
			allAddOnsLoaded = false;
			break;
		end
	end
	
	if (allAddOnsLoaded) then
		self:UnregisterEvent(event);
		self[event] = nil;

		-- we no longer need to receive any events
		self:UnregisterAllEvents();
		self:SetScript("OnEvent", nil);
	end
end

--------------------------------------------------------------------------------------------------------
--                                              Scripts                                               --
--------------------------------------------------------------------------------------------------------

-- ChatFrame:OnHyperlinkEnter
local showingTooltip = false;

local function OnHyperlinkEnter(self, refString, text)
	if (not cfg.enableChatHoverTips) then
		return;
	end
	
	local linkToken = refString:match("^([^:]+)");
	if (supportedHyperLinks[linkToken]) then
		-- set default anchor to tip
		GameTooltip_SetDefaultAnchor(GameTooltip, self);
		
		if (linkToken == "battlepet") then
			-- show tooltip
			showingTooltip = BattlePetTooltip;
			BattlePetToolTip_ShowLink(text);
			LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetDefaultAnchorHook", showingTooltip, self);
		elseif (linkToken == "battlePetAbil") then
			-- makes shure that PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip exist
			if (not LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Collections")) then
				LoadAddOn("Blizzard_Collections");
			end
			
			-- show tooltip
			local link, abilityID, maxHealth, power, speed = (":"):split(refString);
			showingTooltip = PetJournalPrimaryAbilityTooltip;
			PetJournal_ShowAbilityTooltip(GameTooltip, tonumber(abilityID));
			showingTooltip:ClearAllPoints();
			showingTooltip:SetPoint(GameTooltip:GetPoint());
			LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetDefaultAnchorHook", showingTooltip, self);
		elseif (linkToken == "transmogappearance") then -- WardrobeItemsCollectionMixin:RefreshAppearanceTooltip() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			local linkType, sourceID = (":"):split(refString);
			local sourceInfo = C_TransmogCollection.GetSourceInfo(sourceID);
			local name, nameColor = CollectionWardrobeUtil.GetAppearanceNameTextAndColor(sourceInfo);
			GameTooltip_SetTitle(GameTooltip, name, nameColor);
			showingTooltip = GameTooltip;
			GameTooltip:Show();
			local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
			if (TipTacItemRef) then
				TipTacItemRef:SetHyperlink_Hook(GameTooltip, refString);
			end
		elseif (linkToken == "transmogillusion") then -- see WardrobeItemsModelMixin:OnEnter() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			local linkType, illusionID = (":"):split(refString);
			local name, hyperlink, sourceText = C_TransmogCollection.GetIllusionStrings(illusionID);
			GameTooltip:SetText(name);
			if (sourceText) then
				GameTooltip:AddLine(sourceText, 1, 1, 1, 1);
			end
			showingTooltip = GameTooltip;
			GameTooltip:Show();
			local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
			if (TipTacItemRef) then
				TipTacItemRef:SetHyperlink_Hook(GameTooltip, hyperlink);
			end
		elseif (linkToken == "transmogset") then -- WardrobeSetsTransmogModelMixin:RefreshTooltip() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			-- makes shure that WardrobeCollectionFrame exists
			if (not LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Collections")) then
				LoadAddOn("Blizzard_Collections");
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
			local TipTacItemRef = _G[MOD_NAME .. "ItemRef"];
			if (TipTacItemRef) then
				TipTacItemRef:SetHyperlink_Hook(GameTooltip, refString);
			end
		elseif (linkToken == "dungeonScore") then -- GetDungeonScoreLink() + DisplayDungeonScoreLink() in "ItemRef.lua"
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
			local classColor = LibFroznFunctions:GetClassColor(playerClass, 5);
			local runsThisSeason = tonumber(splits[8]);
			
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
			
			local color = C_ChallengeMode.GetDungeonScoreRarityColor(dungeonScore);
			if (not color) then
				color = HIGHLIGHT_FONT_COLOR;
			end
			
			GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_RATING:format(color:WrapTextInColorCode(dungeonScore)));
			GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_LINK_RUNS_SEASON:format(runsThisSeason));
			GameTooltip_AddBlankLineToTooltip(GameTooltip);
			
			local sortTable = { };
			local DUNGEON_SCORE_LINK_INDEX_START = 9;
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
			
			-- Backdrop Border Color: By Class
			if (cfg.classColoredBorder) then
				tt:SetBackdropBorderColorLocked(GameTooltip, true, classColor.r, classColor.g, classColor.b);
			end
			
			showingTooltip = GameTooltip;
			GameTooltip:Show();
		else
			showingTooltip = GameTooltip;
			GameTooltip:SetHyperlink(refString);
			GameTooltip:Show();
		end
	end
end

-- ChatFrame:OnHyperlinkLeave
local function OnHyperlinkLeave(self)
	if (not cfg.enableChatHoverTips) then
		return;
	end
	
	if (showingTooltip) then
		showingTooltip:Hide();
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttHyperlink:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

function ttHyperlink:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- ChatFrame Hyperlink Hover -- Az: this may need some more testing, code seems wrong. e.g. why only on first window? -- Frozn45: completely rewritten.
	if (not self.hookedHoverHyperlinks) then
		for i = 1, NUM_CHAT_WINDOWS do
			local chat = _G["ChatFrame"..i];
			AceHook:SecureHookScript(chat, "OnHyperlinkEnter", OnHyperlinkEnter);
			AceHook:SecureHookScript(chat, "OnHyperlinkLeave", OnHyperlinkLeave);
		end
		self.hookedHoverHyperlinks = true;
	end
	if (not self.hookedHoverHyperlinksOnCFCMF) then
		if (LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Communities")) then
			AceHook:SecureHookScript(_G.CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkEnter", OnHyperlinkEnter);
			AceHook:SecureHookScript(_G.CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkLeave", OnHyperlinkLeave);
			self.hookedHoverHyperlinksOnCFCMF = true;
		end
	end
end