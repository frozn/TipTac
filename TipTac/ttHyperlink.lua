local AceHook = LibStub("AceHook-3.0");
local gtt = GameTooltip;
local bptt = BattlePetTooltip;

-- Addon
local modName = ...;
local ttHyperlink = CreateFrame("Frame", modName);

-- TipTac refs
local tt = TipTac;
local cfg;

-- element registration
tt:RegisterElement(ttHyperlink, "Hyperlink");

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
	mawpower = true,
};

local addOnsLoaded = {
	["Blizzard_Communities"] = false
};

local itemsCollectionFrame = nil;

--------------------------------------------------------------------------------------------------------
--                                       TipTac Hyperlink Frame                                       --
--------------------------------------------------------------------------------------------------------

ttHyperlink:SetScript("OnEvent",function(self,event,...) self[event](self,event,...); end);

ttHyperlink:RegisterEvent("ADDON_LOADED");

-- AddOn Loaded
function ttHyperlink:ADDON_LOADED(event, addOnName)
	-- check if addon is already loaded
	if (addOnsLoaded[addOnName] == nil) or (addOnsLoaded[addOnName]) then
		return;
	end
	
	-- now CommunitiesGuildNewsFrame exists
	if (addOnName == "Blizzard_Communities") then
		self:OnApplyConfig(cfg);
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
	local linkToken = refString:match("^([^:]+)");
	if (supportedHyperLinks[linkToken]) then
		GameTooltip_SetDefaultAnchor(gtt, self);
		
		if (linkToken == "battlepet") then
			showingTooltip = bptt;
			BattlePetToolTip_ShowLink(text);
		elseif (linkToken == "battlePetAbil") then
			-- makes shure that PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip exist
			if (not IsAddOnLoaded("Blizzard_Collections")) then
				LoadAddOn("Blizzard_Collections");
			end
			
			-- show tooltip
			local link, abilityID, maxHealth, power, speed = (":"):split(refString);
			showingTooltip = PetJournalPrimaryAbilityTooltip;
			PetJournal_ShowAbilityTooltip(gtt, tonumber(abilityID));
			PetJournalPrimaryAbilityTooltip:ClearAllPoints();
			PetJournalPrimaryAbilityTooltip:SetPoint(gtt:GetPoint());
		elseif (linkToken == "transmogappearance") then -- see WardrobeCollectionFrameMixin:GetAppearanceItemHyperlink() + WardrobeItemsModelMixin:OnMouseDown() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			local linkType, sourceID = (":"):split(refString);
			local link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
			if (link) then
				showingTooltip = gtt;
				gtt:SetHyperlink(link);
				gtt:Show();
			end
		elseif (linkToken == "transmogillusion") then -- see WardrobeItemsModelMixin:OnEnter() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			local linkType, illusionID = (":"):split(refString);
			local name, hyperlink, sourceText = C_TransmogCollection.GetIllusionStrings(illusionID);
			gtt:SetText(name);
			if (sourceText) then
				gtt:AddLine(sourceText, 1, 1, 1, 1);
			end
			showingTooltip = gtt;
			gtt:Show();
			if (TipTacItemRef) then
				TipTacItemRef:SetHyperlink_Hook(gtt, hyperlink);
			end
		elseif (linkToken == "transmogset") then -- WardrobeSetsTransmogModelMixin:RefreshTooltip() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			-- makes shure that WardrobeCollectionFrame exists
			if (not IsAddOnLoaded("Blizzard_Collections")) then
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
			
			showingTooltip = gtt;
			if (waitingOnQuality) then
				gtt:SetText(RETRIEVING_ITEM_INFO, RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
			else
				local setQuality = (numTotalSlots > 0 and totalQuality > 0) and Round(totalQuality / numTotalSlots) or Enum.ItemQuality.Common;
				local color = ITEM_QUALITY_COLORS[setQuality];
				local setInfo = C_TransmogSets.GetSetInfo(setID);
				gtt:SetText(setInfo.name, color.r, color.g, color.b);
				if (setInfo.label) then
					gtt:AddLine(setInfo.label);
					gtt:Show();
				end
			end
			if (TipTacItemRef) then
				TipTacItemRef:SetHyperlink_Hook(gtt, refString);
			end
		else
			showingTooltip = gtt;
			gtt:SetHyperlink(refString);
			gtt:Show();
		end
	end
end

-- ChatFrame:OnHyperlinkLeave
local function OnHyperlinkLeave(self)
	if (showingTooltip) then
		showingTooltip:Hide();
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttHyperlink:OnLoad()
	cfg = TipTac_Config;
end

function ttHyperlink:OnApplyConfig(cfg)
	-- ChatFrame Hyperlink Hover -- Az: this may need some more testing, code seems wrong. e.g. why only on first window? -- Frozn45: completely rewritten.
	if (cfg.enableChatHoverTips) then
		if (not self.hookedHoverHyperlinks) then
			for i = 1, NUM_CHAT_WINDOWS do
				local chat = _G["ChatFrame"..i];
				AceHook:HookScript(chat, "OnHyperlinkEnter", OnHyperlinkEnter);
				AceHook:HookScript(chat, "OnHyperlinkLeave", OnHyperlinkLeave);
			end
			self.hookedHoverHyperlinks = true;
		end
		if (not self.hookedHoverHyperlinks) or (not self.hookedHoverHyperlinksOnCFCMF) then
			if (IsAddOnLoaded("Blizzard_Communities")) then
				AceHook:HookScript(CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkEnter", OnHyperlinkEnter);
				AceHook:HookScript(CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkLeave", OnHyperlinkLeave);
				self.hookedHoverHyperlinksOnCFCMF = true;
			end
		end
	else
		if (self.hookedHoverHyperlinks) then
			for i = 1, NUM_CHAT_WINDOWS do
				local chat = _G["ChatFrame"..i];
				AceHook:Unhook(chat, "OnHyperlinkEnter");
				AceHook:Unhook(chat, "OnHyperlinkLeave");
			end
			self.hookedHoverHyperlinks = false;
			AceHook:Unhook(CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkEnter");
			AceHook:Unhook(CommunitiesFrame.Chat.MessageFrame, "OnHyperlinkLeave");
			self.hookedHoverHyperlinksOnCFCMF = false;
		end
	end
end