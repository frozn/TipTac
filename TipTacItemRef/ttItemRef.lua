local AceHook = LibStub("AceHook-3.0");
local format = string.format;
local unpack = unpack;
local gtt = GameTooltip;
local bptt = BattlePetTooltip;
local fbptt = FloatingBattlePetTooltip;
local pjpatt = PetJournalPrimaryAbilityTooltip;
local pjsatt = PetJournalSecondaryAbilityTooltip;
local fpbatt = FloatingPetBattleAbilityTooltip;
local ejtt = EncounterJournalTooltip;

-- classic support
local isWoWClassic, isWoWBcc, isWoWRetail = false, false, false
if (_G["WOW_PROJECT_ID"] == _G["WOW_PROJECT_CLASSIC"]) then
	isWoWClassic = true
elseif (_G["WOW_PROJECT_ID"] == _G["WOW_PROJECT_BURNING_CRUSADE_CLASSIC"]) then
	isWoWBcc = true
else
	isWoWRetail = true
end

local CreateColorFromHexString = CreateColorFromHexString;

if (CreateColorFromHexString == nil) then
	CreateColorFromHexString = function(hexColor)
		return CreateColor(tonumber(hexColor:sub(3, 4), 16) / 255, tonumber(hexColor:sub(5, 6), 16) / 255, tonumber(hexColor:sub(7, 8), 16) / 255, tonumber(hexColor:sub(1, 2), 16) / 255);
	end
end

-- Addon
local modName = ...;
local ttif = CreateFrame("Frame", modName);

-- Register with TipTac core addon if available
if (TipTac) then
	TipTac:RegisterElement(ttif,"ItemRef");
end

-- Options without TipTac. If the base TipTac addon is used, the global TipTac_Config table is used instead
local cfg = {
	if_enable = true,
	if_infoColor = { 0.2, 0.6, 1 },

	if_itemQualityBorder = true,
	if_showItemLevel = false,					-- Used to be true, but changed due to the itemLevel issues
	if_showItemId = false,
	if_spellColoredBorder = true,
	if_showSpellIdAndRank = false,
	if_showAuraCaster = true,
	if_questDifficultyBorder = true,
	if_showQuestLevel = false,
	if_showQuestId = false,
	if_currencyQualityBorder = true,
	if_showCurrencyId = false,
	if_achievmentColoredBorder = true,
	if_showAchievementIdAndCategoryId = false,
	if_modifyAchievementTips = true,
	if_battlePetQualityBorder = true,
	if_showBattlePetLevel = false,
	if_showBattlePetId = false,
	if_battlePetAbilityColoredBorder = true,
	if_showBattlePetAbilityId = false,
	if_transmogIllusionColoredBorder = true,
	if_showTransmogIllusionId = false,
	if_conduitQualityBorder = true,
	if_showConduitItemLevel = false,
	if_showConduitId = false,
	if_runeforgePowerColoredBorder = true,
	if_showRuneforgePowerId = false,
	if_guildChallengeColoredBorder = true,
	if_pvpEnlistmentBonusColoredBorder = true,

	if_showIcon = true,
	if_smartIcons = true,
	if_borderlessIcons = false,
	if_iconSize = 42,
};

-- Tooltips to Hook into -- MUST be a GameTooltip widget -- If the main TipTac is installed, the TT_TipsToModify is used instead
local tipsToModify = {
	"GameTooltip",
	"ItemRefTooltip",
	"BattlePetTooltip",
	"FloatingBattlePetTooltip",
	"PetJournalPrimaryAbilityTooltip",
	"PetJournalSecondaryAbilityTooltip",
	"FloatingPetBattleAbilityTooltip",
	--"EncounterJournalTooltip", -- commented out for embedded tooltips, see description in tt:SetPadding()
};

local addOnsLoaded = {
	["Blizzard_Collections"] = false,
	["Blizzard_Communities"] = false,
	["Blizzard_EncounterJournal"] = false,
	["Blizzard_GuildUI"] = false,
	["Blizzard_PVPUI"] = false
};

-- Tips which will have an icon
local tipsToAddIcon = {
	["GameTooltip"] = true,
	["ItemRefTooltip"] = true,
	["BattlePetTooltip"] = true,
	["FloatingBattlePetTooltip"] = true,
	["PetJournalPrimaryAbilityTooltip"] = true,
	["PetJournalSecondaryAbilityTooltip"] = true,
	["FloatingPetBattleAbilityTooltip"] = true,
	--["EncounterJournalTooltip"] = true, -- commented out for embedded tooltips, see description in tt:SetPadding()
};

-- Tables
local LinkTypeFuncs = {};
local CustomTypeFuncs = {};
local criteriaList = {};	-- Used for Achievement criterias
local tipDataAdded = {};	-- Sometimes, OnTooltipSetItem/Spell is called before the tip has been filled using SetHyperlink, we use the array to test if the tooltip has had data added

-- Colors for achivements
local COLOR_COMPLETE = { 0.25, 0.75, 0.25 };
local COLOR_INCOMPLETE = { 0.5, 0.5, 0.5 };

-- Colored text string (red/green)
local BoolCol = { [false] = "|cffff8080", [true] = "|cff80ff80" };

--------------------------------------------------------------------------------------------------------
--                                         Create Tooltip Icon                                        --
--------------------------------------------------------------------------------------------------------

-- Set Texture and Text
local function ttSetIconTextureAndText(self, texture, count)
	if (texture) then
		self.ttIcon:SetTexture(texture ~= "" and texture or "Interface\\Icons\\INV_Misc_QuestionMark");
		if (count) and (count ~= "") and (tonumber(count) > 0) then
			self.ttCount:SetText(count);
		else
			self.ttCount:SetText("");
		end
		self.ttIcon:Show();
	else
		self.ttIcon:Hide();
		self.ttCount:SetText("");
	end
end

-- Create Icon with Counter Text for Tooltip
function ttif:CreateTooltipIcon(tip)
	tip.ttIcon = tip:CreateTexture(nil,"BACKGROUND");
	tip.ttIcon:SetPoint("BOTTOMLEFT",tip,"TOPLEFT",0,-2.5);
	tip.ttIcon:Hide();

	tip.ttCount = tip:CreateFontString(nil,"ARTWORK");
	tip.ttCount:SetTextColor(1,1,1);
	tip.ttCount:SetPoint("BOTTOMRIGHT",tip.ttIcon,"BOTTOMRIGHT",-3,3);
end

--------------------------------------------------------------------------------------------------------
--                                         TipTacItemRef Frame                                        --
--------------------------------------------------------------------------------------------------------

ttif:SetScript("OnEvent",function(self,event,...) self[event](self,event,...); end);

ttif:RegisterEvent("VARIABLES_LOADED");
ttif:RegisterEvent("ADDON_LOADED");

-- Resolves the given table array of string names into their global objects
local function ResolveGlobalNamedObjects(tipTable)
	local resolved = {};
	for index, tipName in ipairs(tipTable) do
		-- lookup the global object from this name, assign false if nonexistent, to preserve the table entry
		local tip = (_G[tipName] or false);

		-- Check if this object has already been resolved. This can happen for thing like AtlasLoot, which sets AtlasLootTooltip = GameTooltip
		if (resolved[tip]) then
			tip = false;
		elseif (tip) then
			if (type(tip) == "table" and BackdropTemplateMixin and "BackdropTemplate") then
				Mixin(tip, BackdropTemplateMixin);
			end
			resolved[tip] = index;
		end

		-- Assign the resolved object or false back into the table array
		tipTable[index] = tip;
	end
end

-- Variables Loaded [One-Time-Event]
function ttif:VARIABLES_LOADED(event)
	-- What tipsToModify to use, TipTac's main addon, or our own?
	local resolveGlobalNamedObjects = true;
	if (TipTac and TipTac.tipsToModify) then
		tipsToModify = TipTac.tipsToModify;
		resolveGlobalNamedObjects = false;
	end

	-- Use TipTac settings if installed
	if (TipTac_Config) then
		cfg = TipTac_Config;
	end

	-- Hook Tips & Apply Settings
	self:HookTips(resolveGlobalNamedObjects);
	self:OnApplyConfig();
	
	-- Cleanup
	self:UnregisterEvent(event);
	self[event] = nil;
end

-- Apply Settings -- It seems this may be called from TipTac:OnApplyConfig() before we have received our VARIABLES_LOADED, so ensure we have created the tip objects
function ttif:OnApplyConfig()
	local gameFont = GameFontNormal:GetFont();
	for index, tip in ipairs(tipsToModify) do
		if (type(tip) == "table") and (tipsToAddIcon[tip:GetName()]) and (tip.ttIcon) then
			if (cfg.if_showIcon) then
				tip.ttIcon:SetSize(cfg.if_iconSize,cfg.if_iconSize);
				tip.ttCount:SetFont(gameFont,(cfg.if_iconSize / 3),"OUTLINE");
				tip.ttSetIconTextureAndText = ttSetIconTextureAndText;
				if (cfg.if_borderlessIcons) then
					tip.ttIcon:SetTexCoord(0.07,0.93,0.07,0.93);
				else
					tip.ttIcon:SetTexCoord(0,1,0,1);
				end
			elseif (tip.ttSetIconTextureAndText) then
				tip.ttIcon:Hide();
				tip.ttSetIconTextureAndText = nil;
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                       HOOK: Tooltip Functions                                      --
--------------------------------------------------------------------------------------------------------

-- add text line to PetJournalPrimaryAbilityTooltip, PetJournalSecondaryAbilityTooltip, FloatingPetBattleAbilityTooltip and EncounterJournalTooltip (see BattlePetTooltipTemplate_AddTextLine() in "FloatingPetBattleTooltip.lua")
local function PJATT_EJTT_AddTextLine(self, text, r, g, b, wrap)
	local linePadding = 2;
	local anchorXOfs = 0;
	local anchorYOfs = 0;
	local anchorXOfsWrap = 0;
	
	if not r then
		r, g, b = NORMAL_FONT_COLOR:GetRGB();
	end
	
	local anchor = self.textLineAnchor;
	if not anchor then
		if (self == pjpatt or self == pjsatt or self == fpbatt) then
			anchor = self.bottomFrame;
			linePadding = 5;
			anchorXOfsWrap = -10;
		elseif (self == ejtt) then
			if (self.Item2:IsShown()) then
				anchor = self.Item2;
			else
				anchor = self.Item1.tooltip;
			end
			anchorXOfs = 10; -- see AdventureJournal_Reward_OnEnter() in "Blizzard_EncounterJournal/Blizzard_EncounterJournal.lua"
			anchorYOfs = 6;
		end
	end
	
	local line = self.linePool:Acquire();
	line:SetText(text);
	line:SetTextColor(r, g, b);
	line:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", anchorXOfs, -linePadding + anchorYOfs);
	
	if wrap then
		line:SetPoint("RIGHT", self, "RIGHT", anchorXOfsWrap, -linePadding + anchorYOfs);
	end
	
	line:Show();
	
	self.textLineAnchor = line;
	
	self:SetHeight(self:GetHeight() + line:GetHeight() + linePadding);
	
	if (self == pjpatt or self == pjsatt or self == fpbatt) then
		self.bottomFrame = line;
	end
end

-- HOOK: PetJournalPrimaryAbilityTooltip:OnLoad + PetJournalSecondaryAbilityTooltip:OnLoad + FloatingPetBattleAbilityTooltip:OnLoad + EncounterJournalTooltip:OnLoad (see BattlePetTooltip_OnLoad() in "FloatingPetBattleTooltip.lua")
local function PJATT_EJTT_OnLoad_Hook(self)
	local subLayer = 0;
	self.linePool = CreateFontStringPool(self, "ARTWORK", subLayer, "GameTooltipText");
	self.AddLine = PJATT_EJTT_AddTextLine;
end

-- HOOK: PetJournalPrimaryAbilityTooltip:OnShow + PetJournalSecondaryAbilityTooltip:OnShow + FloatingPetBattleAbilityTooltip:OnShow + EncounterJournalTooltip:OnShow (see BattlePetTooltipTemplate_SetBattlePet() in "FloatingPetBattleTooltip.lua")
local function PJATT_EJTT_OnShow_Hook(self)
	self.linePool:ReleaseAll();
	self.textLineAnchor = nil;
end

--
-- main hooking functions
-- 

-- HOOK: ItemRefTooltip + GameTooltip:SetHyperlink
function ttif:SetHyperlink_Hook(self, hyperlink)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local refString = hyperlink:match("|H([^|]+)|h") or hyperlink;
		local linkType = refString:match("^[^:]+");
		-- Call Tip Type Func
		if (LinkTypeFuncs[linkType]) and (self:NumLines() > 0) then
			tipDataAdded[self] = "hyperlink";
			LinkTypeFuncs[linkType](self, refString,(":"):split(refString));
		end
	end
end

-- HOOK: SetUnitAura -- Adds both name of "Caster" and "SpellID"
local function SetUnitAura_Hook(self,unit,index,filter)
	if (cfg.if_enable) and (cfg.if_showSpellIdAndRank or cfg.if_showAuraCaster) then
		local _, _, _, _, _, _, casterUnit, _, _, spellId = UnitAura(unit,index,filter);	-- [18.07.19] 8.0/BfA: "dropped second parameter"
		-- format the info line for spellID and caster -- pre-16.08.25 only caster was formatted as this: "<Applied by %s>"
		local tipInfoLine = "";
		if (cfg.if_showAuraCaster) and (UnitExists(casterUnit)) then
			tipInfoLine = tipInfoLine..format("Caster: %s",UnitName(casterUnit) or UNKNOWNOBJECT);
		end
		if (cfg.if_showSpellIdAndRank) and (spellId) and (spellId ~= 0) then
			if (tipInfoLine ~= "") then
				tipInfoLine = tipInfoLine..", ";
			end
			tipInfoLine = tipInfoLine..format("SpellID: %d",spellId);
		end
		-- add line to tooltip if it contains info
		if (tipInfoLine ~= "") then
			self:AddLine(tipInfoLine,unpack(cfg.if_infoColor));
			self:Show();	-- call Show() to resize tip after adding lines
		end
	end
end

-- HOOK: GameTooltip:SetCompanionPet
local function SetCompanionPet_Hook(self, petID)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(petID);
		local health, maxHealth, power, speed, breedQuality = C_PetJournal.GetPetStats(petID);
		tipDataAdded[self] = "battlepet";
		LinkTypeFuncs.battlepet(self, nil, "battlepet", speciesID, level, breedQuality - 1, maxHealth, power, speed, nil, displayID);
	end
end

-- HOOK: ItemRefTooltip + GameTooltip:SetAction
local function SetAction_Hook(self, slot)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local actionType, id, subType = GetActionInfo(slot);
		if (actionType == "item") then
			local _, link = self:GetItem();
			if (link) then
				local linkType, itemID = link:match("H?(%a+):(%d+)");
				if (itemID) then
					tipDataAdded[self] = linkType;
					LinkTypeFuncs.item(self, link, linkType, itemID);
				end
			end
		elseif (actionType == "summonpet") then
			local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType, creatureID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoByPetID(id);
			local health, maxHealth, power, speed, breedQuality = C_PetJournal.GetPetStats(id);
			tipDataAdded[self] = "battlepet";
			LinkTypeFuncs.battlepet(self, nil, "battlepet", speciesID, level, breedQuality - 1, maxHealth, power, speed, nil, displayID);
		end
	end
end

-- HOOK: GameTooltip:SetRecipeReagentItem
local function SetRecipeReagentItem_Hook(self, recipeID, reagentIndex)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local link = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, reagentIndex);
		if (link) then
			local linkType, itemID = link:match("H?(%a+):(%d+)");
			if (itemID) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.item(self, link, linkType, itemID);
			end
		end
	end
end

-- HOOK: GameTooltip:SetToyByItemID
local function SetToyByItemID_Hook(self, itemID)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local _, link = self:GetItem();
		if (link) then
			local linkType, itemID = link:match("H?(%a+):(%d+)");
			if (itemID) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.item(self, link, linkType, itemID);
				
				-- workaround for the following "bug": on first mouseover over toy the gtt will be cleared (OnTooltipCleared) and internally set again. There ist no immediately following SetToyByItemID() (only approx. 1 second later), but on the next OnUpdate the GetItem() is set again.
				-- ttSetToyByItemIDWorkaroundStatus:
				-- nil = no hooks set (initial status)
				-- 1   = hooks GameTooltip:OnTooltipCleared and ToySpellButton:OnLeave set
				-- 2   = hooks GameTooltip:OnUpdate and ToySpellButton:OnLeave set
				-- 3   = no hooks set respectively not needed any more
				local owner = self:GetOwner();
				
				if (not owner.ttSetToyByItemIDWorkaroundStatus) then
					AceHook:HookScript(gtt, "OnTooltipCleared", function(self)
						AceHook:HookScript(gtt, "OnUpdate", function(self)
							tipDataAdded[self] = linkType;
							LinkTypeFuncs.item(self, link, linkType, itemID);

							AceHook:Unhook(gtt, "OnUpdate");
							owner.ttSetToyByItemIDWorkaroundStatus = 3;
						end);
						AceHook:Unhook(gtt, "OnTooltipCleared");
						owner.ttSetToyByItemIDWorkaroundStatus = 2;
					end);
					AceHook:HookScript(owner, "OnLeave", function(self)
						if (self.ttSetToyByItemIDWorkaroundStatus == 1) then
							AceHook:Unhook(gtt, "OnTooltipCleared");
						elseif (owner.ttSetToyByItemIDWorkaroundStatus == 2) then
							AceHook:Unhook(gtt, "OnUpdate");
						end
						AceHook:Unhook(self, "OnLeave");
						self.ttSetToyByItemIDWorkaroundStatus = nil;
					end);
					owner.ttSetToyByItemIDWorkaroundStatus = 1;
				else
					if (owner.ttSetToyByItemIDWorkaroundStatus == 1) then
						AceHook:Unhook(gtt, "OnTooltipCleared");
					elseif (owner.ttSetToyByItemIDWorkaroundStatus == 2) then
						AceHook:Unhook(gtt, "OnUpdate");
					end
					owner.ttSetToyByItemIDWorkaroundStatus = 3;
				end
			end
		end
	end
end

-- HOOK: GameTooltip:SetLFGDungeonReward
local function SetLFGDungeonReward_Hook(self, dungeonID, rewardIndex)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local name, texture, numItems, isBonusReward, rewardType, rewardID, quality = GetLFGDungeonRewardInfo(dungeonID, rewardIndex); -- see LFGDungeonReadyDialogReward_OnEnter in "LFGFrame.lua"
		if (rewardType == "item") then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(rewardID);
			if (itemLink) then
				local linkType, itemID = itemLink:match("H?(%a+):(%d+)");
				if (itemID) then
					tipDataAdded[self] = linkType;
					LinkTypeFuncs.item(self, itemLink, linkType, itemID);
				end
			end
		elseif (rewardType == "currency") then
			local link = C_CurrencyInfo.GetCurrencyLink(rewardID, numItems);
			if (link) then
				local linkType, currencyID, quantity = link:match("H?(%a+):(%d+):(%d+)");
				if (currencyID) then
					tipDataAdded[self] = linkType;
					LinkTypeFuncs.currency(self, link, linkType, currencyID, quantity);
				end
			end
		end
	end
end

-- HOOK: GameTooltip:SetLFGDungeonShortageReward
local function SetLFGDungeonShortageReward_Hook(self, dungeonID, rewardArg, rewardIndex)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local name, texture, numItems, isBonusReward, rewardType, rewardID, quality = GetLFGDungeonShortageRewardInfo(dungeonID, rewardArg, rewardIndex); -- see LFGDungeonReadyDialogReward_OnEnter in "LFGFrame.lua"
		if (rewardType == "item") then
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(rewardID);
			if (itemLink) then
				local linkType, itemID = itemLink:match("H?(%a+):(%d+)");
				if (itemID) then
					tipDataAdded[self] = linkType;
					LinkTypeFuncs.item(self, itemLink, linkType, itemID);
				end
			end
		elseif (rewardType == "currency") then
			local link = C_CurrencyInfo.GetCurrencyLink(rewardID, numItems);
			if (link) then
				local linkType, currencyID, quantity = link:match("H?(%a+):(%d+):(%d+)");
				if (currencyID) then
					tipDataAdded[self] = linkType;
					LinkTypeFuncs.currency(self, link, linkType, currencyID, quantity);
				end
			end
		end
	end
end

-- HOOK: GameTooltip:SetCurrencyToken
local function SetCurrencyToken_Hook(self, currencyIndex)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local link = C_CurrencyInfo.GetCurrencyListLink(currencyIndex);
		if (link) then
			local linkType, currencyID, quantity = link:match("H?(%a+):(%d+):(%d+)");
			if (currencyID) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.currency(self, link, linkType, currencyID, quantity);
			end
		end
	end
end

-- HOOK: GameTooltip:SetConduit
local function SetConduit_Hook(self, conduitID, conduitRank)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local link = C_Soulbinds.GetConduitHyperlink(conduitID, conduitRank);
		if (link) then
			local linkType, _conduitID, _conduitRank = link:match("H?(%a+):(%d+):(%d+)");
			if (_conduitID) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.conduit(self, link, linkType, _conduitID, _conduitRank);
			end
		end
	end
end

-- HOOK: BattlePetToolTip_Show
local function BPTT_Show_Hook(speciesID, level, breedQuality, maxHealth, power, speed, customName)
	if (cfg.if_enable) and (not tipDataAdded[bptt]) and (bptt:IsShown()) then
		tipDataAdded[bptt] = "battlepet";
		local speciesName, speciesIcon, petType, creatureID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, displayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
		LinkTypeFuncs.battlepet(bptt, nil, "battlepet", speciesID, level, breedQuality, maxHealth, power, speed, nil, displayID);
	end
end

-- HOOK: FloatingBattlePet_Show
local function FBP_Show_Hook(speciesID, level, breedQuality, maxHealth, power, speed, customName, petID)
	if (cfg.if_enable) and (not tipDataAdded[fbptt]) and (fbptt:IsShown()) then
		local speciesName, speciesIcon, petType, creatureID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, displayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID);
		LinkTypeFuncs.battlepet(fbptt, nil, "battlepet", speciesID, level, breedQuality, maxHealth, power, speed, nil, displayID);
	end
end

-- HOOK: PetJournal_ShowAbilityTooltip
local function PJ_ShowAbilityTooltip_Hook(self, abilityID, speciesID, petID, additionalText)
	if (cfg.if_enable) and (not tipDataAdded[pjpatt]) and (pjpatt:IsShown()) then
		tipDataAdded[pjpatt] = "battlePetAbil";
		LinkTypeFuncs.battlePetAbil(pjpatt, nil, "battlePetAbil", abilityID, speciesID, petID, additionalText);
	end
end

-- HOOK: PetJournal_ShowAbilityCompareTooltip
local function PJ_ShowAbilityCompareTooltip_Hook(abilityID1, abilityID2, speciesID, petID)
	if (cfg.if_enable) then
		if (not tipDataAdded[pjpatt]) and (pjpatt:IsShown()) then
			tipDataAdded[pjpatt] = "battlePetAbil";
			LinkTypeFuncs.battlePetAbil(pjpatt, nil, "battlePetAbil", abilityID1, speciesID, petID, nil);
		end
		if (not tipDataAdded[pjsatt]) and (pjsatt:IsShown()) then
			tipDataAdded[pjsatt] = "battlePetAbil";
			LinkTypeFuncs.battlePetAbil(pjsatt, nil, "battlePetAbil", abilityID2, speciesID, petID, nil);
		end
	end
end

-- HOOK: FloatingPetBattleAbility_Show
local function FPBA_Show_Hook(abilityID, maxHealth, power, speed)
	if (cfg.if_enable) and (fpbatt:IsShown()) then
		if (tipDataAdded[fpbatt]) then -- fire OnShow handler if hyperlink clicked repeatedly. The FloatingPetBattleAbilityTooltip doesn't toggle the tooltip like a FloatingBattlePetTooltip.
			PJATT_EJTT_OnShow_Hook(fpbatt);
		end
		tipDataAdded[fpbatt] = "battlePetAbil";
		LinkTypeFuncs.battlePetAbil(fpbatt, nil, "battlePetAbil", abilityID, nil, nil, nil);
	end
end

-- OnTooltipSetItem
local function OnTooltipSetItem(self,...)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local _, link = self:GetItem();
		if (link) then
			local linkType, itemID = link:match("H?(%a+):(%d+)");
			if (itemID) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.item(self, link, linkType, itemID);
			end
		end
	end
end

-- OnTooltipSetSpell
local function OnTooltipSetSpell(self,...)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local _, id = self:GetSpell();	-- [18.07.19] 8.0/BfA: "dropped second parameter (nameSubtext)"
		if (id) then
			tipDataAdded[self] = "spell";
			LinkTypeFuncs.spell(self,nil,"spell",id);
		end
	end
end

-- HOOK: QuestMapLogTitleButton_OnEnter
local function QMLTB_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local info = C_QuestLog.GetInfo(self.questLogIndex);
		local questID = info.questID;
		local link = GetQuestLink(questID);
		local level = link:match("H?%a+:%d+:(%d+)");
		tipDataAdded[gtt] = "quest";
		LinkTypeFuncs.quest(gtt, nil, "quest", questID, level);
	end
end

-- HOOK: TaskPOI_OnEnter
local function TPOI_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local questID = self.questID;
		local link = GetQuestLink(questID);
		if (link) then
			local level = link:match("H?%a+:%d+:(%d+)");
			LinkTypeFuncs.quest(gtt, nil, "quest", questID, level);
		else
			LinkTypeFuncs.quest(gtt, nil, "quest", questID, nil);
		end
		tipDataAdded[gtt] = "quest";
	end
end

-- HOOK: QuestPinMixin:OnMouseEnter + StorylineQuestPinMixin:OnMouseEnter
local function QPM_OnMouseEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local questID = self.questID;
		local link = GetQuestLink(questID);
		if (link) then
			local level = link:match("H?%a+:%d+:(%d+)");
			LinkTypeFuncs.quest(gtt, nil, "quest", questID, level);
		else
			LinkTypeFuncs.quest(gtt, nil, "quest", questID, nil);
		end
		tipDataAdded[gtt] = "quest";
	end
end

-- HOOK: QuestInfoRewardsFrame.RewardButtons:OnEnter + MapQuestInfoRewardsFrame.RewardButtons:OnEnter, see QuestInfoRewardItemCodeTemplate_OnEnter() in "QuestInfo.lua"
local function QIRFRB_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		if (self.objectType == "questSessionBonusReward") then -- bonus reward for quest sessions
			local itemID = self:GetID();
			local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemID);
			if (itemLink) then
				local linkType, _itemID = itemLink:match("H?(%a+):(%d+)");
				if (_itemID) then
					tipDataAdded[gtt] = linkType;
					LinkTypeFuncs.item(gtt, itemLink, linkType, _itemID);
				end
			end
		else
			local questID = self.questID;
			local index = self:GetID();
			local isChoice = (self.type == "choice");
			
			if (self.objectType == "item") then -- item
				local itemID;
				local numItems;
				if (QuestInfoFrame.questLog) then
					if (isChoice) then
						_, _, numItems, _, _, itemID = GetQuestLogChoiceInfo(index);
					else
						_, _, numItems, _, _, itemID = GetQuestLogRewardInfo(index);
					end
				else
					_, _, numItems, _, _, itemID = GetQuestItemInfo(self.type, index);
				end
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(itemID);
				if (itemLink) then
					local linkType, _itemID = itemLink:match("H?(%a+):(%d+)");
					if (_itemID) then
						tipDataAdded[gtt] = linkType;
						LinkTypeFuncs.item(gtt, itemLink, linkType, _itemID);
					end
				end
			elseif (self.objectType == "currency") then -- currency
				local currencyID;
				local quantity;
				if (QuestInfoFrame.questLog) then
					_, _, quantity, currencyID = GetQuestLogRewardCurrencyInfo(index, questID, isChoice);
				else
					currencyID = GetQuestCurrencyID(self.type, index);
					_, _, quantity = GetQuestCurrencyInfo(self.type, index);
				end
				
				local link = C_CurrencyInfo.GetCurrencyLink(currencyID, quantity);
				if (link) then
					local linkType, _currencyID, _quantity = link:match("H?(%a+):(%d+):(%d+)");
					if (_currencyID) then
						tipDataAdded[gtt] = linkType;
						LinkTypeFuncs.currency(gtt, link, linkType, _currencyID, _quantity);
					end
				end
			end
		end
	end
end

-- HOOK: RuneforgePowerBaseMixin:OnEnter
local function RPBM_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local runeforgePowerID = self:GetPowerID();
		if (runeforgePowerID) then
			tipDataAdded[gtt] = "runeforgePower";
			CustomTypeFuncs.runeforgePower(gtt, nil, "runeforgePower", runeforgePowerID);
		end
	end
end

-- HOOK: GameTooltip_AddQuestRewardsToTooltip
local function GTT_AddQuestRewardsToTooltip(self, questID, style)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local link = GetQuestLink(questID);
		if (link) then
			local level = link:match("H?%a+:%d+:(%d+)");
			LinkTypeFuncs.quest(self, nil, "quest", questID, level);
		else
			LinkTypeFuncs.quest(self, nil, "quest", questID, nil);
		end
		tipDataAdded[self] = "quest";
	end
end

-- HOOK: HonorFrame.BonusFrame.Buttons:OnEnter
local function HFBFB_OnEnter(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) then
		tipDataAdded[gtt] = "pvpEnlistmentBonus";
		CustomTypeFuncs.pvpEnlistmentBonus(gtt, nil, "pvpEnlistmentBonus");
	end
end

-- HOOK: AdventureJournal_Reward_OnEnter
local function AJR_OnEnter_Hook(self)
	if (cfg.if_enable) and (ejtt:IsShown()) then
		local rewardData = self.data;
		if (rewardData) then
			-- item and currency can both exist. In this case currency is the second item.
			if (rewardData.currencyType) or (rewardData.itemLink) then
				if (tipDataAdded[ejtt]) then -- fire OnShow handler to reset line pool. AdventureJournal_Reward_OnEnter will be called multiple times without OnHide.
					PJATT_EJTT_OnShow_Hook(ejtt);
				end
			end
			if (rewardData.currencyType) then -- currency
				local currencyLink = C_CurrencyInfo.GetCurrencyLink(rewardData.currencyType, rewardData.currencyQuantity)
				if (currencyLink) then
					local linkType, currencyID, quantity = currencyLink:match("H?(%a+):(%d+):(%d+)");
					if (currencyID) then
						tipDataAdded[ejtt] = linkType;
						LinkTypeFuncs.currency(ejtt, currencyLink, linkType, currencyID, quantity);
					end
				end
			end
			if (rewardData.itemLink) then -- item
				local linkType, itemID = rewardData.itemLink:match("H?(%a+):(%d+)");
				if (itemID) then
					tipDataAdded[ejtt] = linkType;
					LinkTypeFuncs.item(ejtt, rewardData.itemLink, linkType, itemID);
				end
			end
		end
	end
end

-- HOOK: CommunitiesGuildNewsButton_OnEnter / GuildNewsButton_OnEnter
local function GNB_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local newsType = self.newsType;
		
		if (newsType == NEWS_PLAYER_ACHIEVEMENT or newsType == NEWS_GUILD_ACHIEVEMENT) then
			local achievementId = self.id;
			local link = GetAchievementLink(achievementId);
			local refString = link:match("|H([^|]+)|h") or link;
			tipDataAdded[gtt] = "achievement";
			LinkTypeFuncs.achievement(gtt, refString, (":"):split(refString));
		end
	end
end

-- HOOK: CommunitiesGuildInfoFrame.Challenges:OnEnter / GuildInfoFrameInfoChallenge:OnEnter
local function GIFC_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		tipDataAdded[gtt] = "guildChallenge";
		CustomTypeFuncs.guildChallenge(gtt, nil, "guildChallenge");
	end
end

-- HOOK: WardrobeCollectionFrame.ItemsCollectionFrame.Models:OnEnter, see WardrobeItemsModelMixin:OnEnter() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
local function WCFICFM_OnEnter_Hook(self)
	if (cfg.if_enable) and (not tipDataAdded[gtt]) and (gtt:IsShown()) then
		local itemsCollectionFrame = self:GetParent();
		if (itemsCollectionFrame.transmogLocation:IsIllusion()) then -- illusion
			local illusionID = self.visualInfo.sourceID;
			local name, hyperlink, sourceText = C_TransmogCollection.GetIllusionStrings(illusionID);
			if (hyperlink) then
				local linkType, illusionID = hyperlink:match("H?(%a+):(%d+)");
				if (illusionID) then
					tipDataAdded[gtt] = linkType;
					LinkTypeFuncs.transmogillusion(gtt, hyperlink, linkType, illusionID);
				end
			end
		else -- item, see WardrobeCollectionFrameMixin:GetAppearanceItemHyperlink() + WardrobeItemsModelMixin:OnMouseDown() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
			local wardrobeCollectionFrame = itemsCollectionFrame:GetParent();
			if (wardrobeCollectionFrame.tooltipSourceIndex) then
				local sources = CollectionWardrobeUtil.GetSortedAppearanceSources(self.visualInfo.visualID, itemsCollectionFrame:GetActiveCategory());
				local index = CollectionWardrobeUtil.GetValidIndexForNumSources(wardrobeCollectionFrame.tooltipSourceIndex, #sources);
				local sourceID = sources[index].sourceID;
				local link = select(6, C_TransmogCollection.GetAppearanceSourceInfo(sourceID));
				if (link) then
					local linkType, itemID = link:match("H?(%a+):(%d+)");
					if (itemID) then
						tipDataAdded[gtt] = linkType;
						LinkTypeFuncs.item(gtt, link, linkType, itemID);
					end
				end
			end
		end
	end
end

-- OnTooltipCleared
local function OnTooltipCleared(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- HOOK: BattlePetTooltip:OnHide
local function BPTT_OnHide_Hook(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- HOOK: FloatingBattlePetTooltip:OnHide
local function FBPTT_OnHide_Hook(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- HOOK: PetJournalPrimaryAbilityTooltip:OnHide + PetJournalSecondaryAbilityTooltip:OnHide
local function PJATT_OnHide_Hook(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- HOOK: FloatingPetBattleAbilityTooltip:OnHide
local function FPBATT_OnHide_Hook(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- HOOK: EncounterJournalTooltip:OnHide
local function EJTT_OnHide_Hook(self)
	tipDataAdded[self] = nil;
	if (self.ttSetIconTextureAndText) then
		self:ttSetIconTextureAndText();
	end
end

-- Function to apply necessary hooks to tips
function ttif:ApplyHooksToTips(tips, resolveGlobalNamedObjects, lateHook)
	-- Resolve the TipsToModify strings into actual objects
	if (resolveGlobalNamedObjects) then
		ResolveGlobalNamedObjects(tips);
	end
	
	-- apply necessary hooks to tips
	for index, tip in ipairs(tips) do
		if (type(tip) == "table") and (type(tip.GetObjectType) == "function") then
			local tipName = tip:GetName();
			local tipHooked = false;
			
			if (lateHook) then
				tipsToModify[#tipsToModify + 1] = tip;
			end
			
			if (tip:GetObjectType() == "GameTooltip") then
				hooksecurefunc(tip, "SetHyperlink", function(self, ...)
					ttif:SetHyperlink_Hook(self, ...)
				end);
				hooksecurefunc(tip, "SetUnitAura", SetUnitAura_Hook);
				hooksecurefunc(tip, "SetUnitBuff", SetUnitAura_Hook);
				hooksecurefunc(tip, "SetUnitDebuff", SetUnitAura_Hook);
				hooksecurefunc(tip, "SetAction", SetAction_Hook);
				if (isWoWRetail) then
					hooksecurefunc(tip, "SetConduit", SetConduit_Hook);
					hooksecurefunc(tip, "SetEnhancedConduit",SetConduit_Hook);
					hooksecurefunc(tip, "SetCurrencyToken", SetCurrencyToken_Hook);
					hooksecurefunc(tip, "SetCompanionPet", SetCompanionPet_Hook);
					hooksecurefunc(tip, "SetRecipeReagentItem", SetRecipeReagentItem_Hook);
					hooksecurefunc(tip, "SetToyByItemID", SetToyByItemID_Hook);
					hooksecurefunc(tip, "SetLFGDungeonReward", SetLFGDungeonReward_Hook);
					hooksecurefunc(tip, "SetLFGDungeonShortageReward", SetLFGDungeonShortageReward_Hook);
				end
				tip:HookScript("OnTooltipSetItem", OnTooltipSetItem);
				tip:HookScript("OnTooltipSetSpell", OnTooltipSetSpell);
				tip:HookScript("OnTooltipCleared", OnTooltipCleared);
				if (tipName == "GameTooltip") then
					hooksecurefunc(QuestPinMixin, "OnMouseEnter", QPM_OnMouseEnter_Hook);
					hooksecurefunc(StorylineQuestPinMixin, "OnMouseEnter", QPM_OnMouseEnter_Hook);
					hooksecurefunc("GameTooltip_AddQuestRewardsToTooltip", GTT_AddQuestRewardsToTooltip);
					-- quest (log) rewards
					hooksecurefunc("QuestInfo_GetRewardButton", function(rewardsFrame, index)
						ttif:ApplyHooksToQIRFRB(rewardsFrame, index);
					end);
					hooksecurefunc("QuestInfoRewardItemCodeTemplate_OnEnter", QIRFRB_OnEnter_Hook);
					-- classic support
					if (isWoWRetail) then
						hooksecurefunc("QuestMapLogTitleButton_OnEnter", QMLTB_OnEnter_Hook);
						hooksecurefunc("TaskPOI_OnEnter", TPOI_OnEnter_Hook);
						hooksecurefunc(RuneforgePowerBaseMixin, "OnEnter", RPBM_OnEnter_Hook);
					end
				end
				tipHooked = true;
			else
				if (tip:GetObjectType() == "Frame") then
					if (tipName == "BattlePetTooltip") then
						hooksecurefunc("BattlePetToolTip_Show", BPTT_Show_Hook);
						tip:HookScript("OnHide", BPTT_OnHide_Hook);
						tipHooked = true;
					elseif (tipName == "FloatingBattlePetTooltip") then
						hooksecurefunc("FloatingBattlePet_Show", FBP_Show_Hook);
						tip:HookScript("OnHide", FBPTT_OnHide_Hook);
						tipHooked = true;
					elseif (IsAddOnLoaded("Blizzard_Collections")) and ((tipName == "PetJournalPrimaryAbilityTooltip") or (tipName == "PetJournalSecondaryAbilityTooltip")) then
						if (tipName == "PetJournalPrimaryAbilityTooltip") then
							hooksecurefunc("PetJournal_ShowAbilityTooltip", PJ_ShowAbilityTooltip_Hook);
							hooksecurefunc("PetJournal_ShowAbilityCompareTooltip", PJ_ShowAbilityCompareTooltip_Hook);
						end
						tip:HookScript("OnHide", PJATT_OnHide_Hook);
						-- add function Addline() (see BattlePetTooltipTemplate_AddTextLine() in "FloatingPetBattleTooltip.lua")
						tip:HookScript("OnLoad", PJATT_EJTT_OnLoad_Hook);
						tip:HookScript("OnShow", PJATT_EJTT_OnShow_Hook);
						if (tip.strongAgainstTextures) then -- fire OnLoad handler if already loaded
							PJATT_EJTT_OnLoad_Hook(tip);
						end
						tipHooked = true;
					elseif (tipName == "FloatingPetBattleAbilityTooltip") then
						hooksecurefunc("FloatingPetBattleAbility_Show", FPBA_Show_Hook);
						tip:HookScript("OnHide", FPBATT_OnHide_Hook);
						-- add function Addline() (see BattlePetTooltipTemplate_AddTextLine() in "FloatingPetBattleTooltip.lua")
						tip:HookScript("OnLoad", PJATT_EJTT_OnLoad_Hook);
						tip:HookScript("OnShow", PJATT_EJTT_OnShow_Hook);
						if (tip.strongAgainstTextures) then -- fire OnLoad handler if already loaded
							PJATT_EJTT_OnLoad_Hook(tip);
						end
						tipHooked = true;
					elseif (IsAddOnLoaded("Blizzard_EncounterJournal")) and (tipName == "EncounterJournalTooltip") then
						hooksecurefunc("AdventureJournal_Reward_OnEnter", AJR_OnEnter_Hook);
						tip:HookScript("OnHide", EJTT_OnHide_Hook);
						-- add function Addline() (see BattlePetTooltipTemplate_AddTextLine() in "FloatingPetBattleTooltip.lua")
						tip:HookScript("OnLoad", PJATT_EJTT_OnLoad_Hook);
						tip:HookScript("OnShow", PJATT_EJTT_OnShow_Hook);
						if (tip.headerText) then -- fire OnLoad handler if already loaded
							PJATT_EJTT_OnLoad_Hook(tip);
						end
						-- tipHooked = true;
					end
				end
			end
			
			if (tipHooked) then
				if (tipsToAddIcon[tipName]) then
					self:CreateTooltipIcon(tip);
				end
			end
		end
	end
end

-- Function to apply necessary hooks to CommunitiesFrameGuildDetailsFrameInfo
local CFGDFIChooked = {};

function ttif:ApplyHooksToCFGDFI()
	local numChallenges = GetNumGuildChallenges(); -- see CommunitiesGuildInfoFrame_UpdateChallenges() in "Blizzard_Communities/GuildInfo.lua"
	for i = 1, numChallenges do
		local frame = CommunitiesFrameGuildDetailsFrameInfo.Challenges[i];
		if (frame) and (not CFGDFIChooked[frame]) then
			frame:HookScript("OnEnter", GIFC_OnEnter_Hook);
			CFGDFIChooked[frame] = true;
		end
	end
end

-- Function to apply necessary hooks to GuildInfoFrameInfoChallenge
local GIFIChooked = {};

function ttif:ApplyHooksToGIFIC()
	local numChallenges = GetNumGuildChallenges(); -- see GuildInfoFrame_UpdateChallenges() in "Blizzard_GuildUI/Blizzard_GuildInfo.lua"
	for i = 1, numChallenges do
		local index, current, max = GetGuildChallengeInfo(i);
		local frame = _G["GuildInfoFrameInfoChallenge"..index];
		if (frame) and (not GIFIChooked[frame]) then
			frame:HookScript("OnEnter", GIFC_OnEnter_Hook);
			GIFIChooked[frame] = true;
		end
	end
end

-- Function to apply necessary hooks to QuestInfoRewardsFrame.RewardButtons + MapQuestInfoRewardsFrame.RewardButtons
local QIRFRBhooked = {};

function ttif:ApplyHooksToQIRFRB(rewardsFrame, index)
	local rewardButtons = rewardsFrame.RewardButtons; -- see QuestInfo_ShowRewards() + QuestInfo_GetRewardButton() in "QuestInfo.lua"
	
	for i = 1, #rewardButtons do
		local rewardButton = rewardButtons[i];
		if (not QIRFRBhooked[rewardButton]) then
			rewardButton:HookScript("OnEnter", QIRFRB_OnEnter_Hook);
			QIRFRBhooked[rewardButton] = true;
		end
	end
end

-- Apply hooks for all the tooltips to modify during VARIABLES_LOADED -- Only hook GameTooltip objects
function ttif:HookTips(resolveGlobalNamedObjects)
	self:ApplyHooksToTips(tipsToModify, resolveGlobalNamedObjects);
end

-- AddOn Loaded
function ttif:ADDON_LOADED(event, addOnName)
	-- check if addon is already loaded
	if (addOnsLoaded[addOnName] == nil) or (addOnsLoaded[addOnName]) then
		return;
	end
	
	-- now PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip exist
	if (addOnName == "Blizzard_Collections") then
		pjpatt = PetJournalPrimaryAbilityTooltip;
		pjsatt = PetJournalSecondaryAbilityTooltip;
		
		-- Hook Tips & Apply Settings
		self:ApplyHooksToTips({
			"PetJournalPrimaryAbilityTooltip",
			"PetJournalSecondaryAbilityTooltip"
		}, true, true);

		self:OnApplyConfig();
		
		-- Function to apply necessary hooks to WardrobeCollectionFrame.ItemsCollectionFrame, see WardrobeItemsCollectionMixin:UpdateItems() in "Blizzard_Collections/Blizzard_Wardrobe.lua"
		local itemsCollectionFrame = WardrobeCollectionFrame.ItemsCollectionFrame;
		for i = 1, itemsCollectionFrame.PAGE_SIZE do
			local model = itemsCollectionFrame.Models[i];
			model:HookScript("OnEnter", WCFICFM_OnEnter_Hook);
		end
	-- now CommunitiesGuildNewsFrame exists
	elseif (addOnName == "Blizzard_Communities") then
		hooksecurefunc("CommunitiesGuildNewsButton_OnEnter", GNB_OnEnter_Hook);

		-- Function to apply necessary hooks to CommunitiesFrameGuildDetailsFrameInfo
		ttif:ApplyHooksToCFGDFI();
		
		hooksecurefunc("CommunitiesGuildInfoFrame_UpdateChallenges", function()
			ttif:ApplyHooksToCFGDFI();
		end);
	-- now EncounterJournalTooltip exists
	elseif (addOnName == "Blizzard_EncounterJournal") then
		ejtt = EncounterJournalTooltip;
		
		-- Hook Tips & Apply Settings
		-- commented out for embedded tooltips, see description in tt:SetPadding()
		-- self:ApplyHooksToTips({
			-- "EncounterJournalTooltip"
		-- }, true, true);

		-- self:OnApplyConfig();
	-- now GuildNewsButton exists
	elseif (addOnName == "Blizzard_GuildUI") then
		hooksecurefunc("GuildNewsButton_OnEnter", GNB_OnEnter_Hook);
		
		-- Function to apply necessary hooks to GuildInfoFrameInfoChallenge
		ttif:ApplyHooksToGIFIC();
		
		hooksecurefunc("GuildInfoFrame_UpdateChallenges", function()
			ttif:ApplyHooksToGIFIC();
		end);
	-- now PVPRewardTemplate exists
	elseif (addOnName == "Blizzard_PVPUI") then
		-- Function to apply necessary hooks to PVPRewardTemplate, see HonorFrameBonusFrame_Update() in "Blizzard_PVPUI/Blizzard_PVPUI.lua"
		local buttons = {
			HonorFrame.BonusFrame.RandomBGButton,
			HonorFrame.BonusFrame.Arena1Button,
			HonorFrame.BonusFrame.RandomEpicBGButton,
			HonorFrame.BonusFrame.BrawlButton
		};
		
		for i, button in pairs(buttons) do
			button.Reward.EnlistmentBonus:HookScript("OnEnter", HFBFB_OnEnter);
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
--                                        Smart Icon Evaluation                                       --
--------------------------------------------------------------------------------------------------------

-- returns true if an icon should be displayed
local function SmartIconEvaluation(tip,linkType)
	if (tip == bptt or tip == fbptt) then -- BattlePetTooltip and FloatingBattlePetTooltip
		return true;
	end

	if (linkType == "battlePetAbil") then
		if (tip.anchoredTo and tip.anchoredTo.icon) then
			return false;
		end
		return true;
	end
	
	if (tip == ejtt) then -- EncounterJournalTooltip
		return false;
	end
	
	local owner = tip:GetOwner();

	-- No Owner?
	if (not owner) then
		return false;
	-- Item
	elseif (linkType == "item") then
		if (owner.hasItem or owner.action or owner.icon or owner.Icon or owner.texture or owner.lootFrame or owner.ItemIcon or owner.iconTexture) then
			return false;
		end
	-- Spell
	elseif (linkType == "spell") then
		if (owner.action or owner.icon or owner.Icon) then -- mount tooltip in action bar
			return false;
		end
		if (owner.ActiveTexture) then -- mount tooltip in mount journal list
			local ownerParent = owner:GetParent();
			if (ownerParent and owner:GetParent().icon) then
				return false;
			end
		end
	-- Achievement
--	elseif (linkType == "achievement") then
--		if (owner.icon) then
--			return false;
--		end
	-- Battle pet
	elseif (linkType == "battlepet") then
		if (owner.action or owner.icon) then -- pet tooltip in action bar
			return false;
		end
		local ownerParent = owner:GetParent(); -- pet tooltip in pet journal list
		if (ownerParent and ownerParent.petTypeIcon and ownerParent.icon) then
			return false;
		end
	-- Runeforge power
	elseif (linkType == "runeforgePower") then
		if (owner.Icon) then
			return false;
		end
	-- Conduit
	elseif (linkType == "conduit") then
		if (owner.Icon) then
			return false;
		end
		local ownerParent = owner:GetParent();
		if (ownerParent and ownerParent.Icon) then
			return false;
		end
	end

	-- IconTexture sub texture
	local ownerName = owner:GetName();
	if (ownerName) then
		if (_G[ownerName.."IconTexture"]) or (ownerName:match("SendMailAttachment(%d+)")) then
			return false;
		end
	end

	-- If we passed all checks, return true to show an icon
	return true;
end

--------------------------------------------------------------------------------------------------------
--                                       Tip LinkType Functions                                       --
--------------------------------------------------------------------------------------------------------

-- Sets backdrop border color
function ttif:SetBackdropBorderColor(tip, r, g, b, a)
	tip.ttSetBackdropBorderColorLocked = false;
	tip:SetBackdropBorderColor(r, g, b, a);
	tip.ttSetBackdropBorderColorLocked = true;
	tip.ttBackdropBorderColorApplied = true;
end

-- instancelock
function LinkTypeFuncs:instancelock(link,linkType,guid,mapId,difficulty,encounterBits)
	--AzDump(guid,mapId,difficulty,encounterBits)
  	-- TipType Border Color -- Disable these 3 lines to color border. Az: Work into options?
--	if (cfg.if_itemQualityBorder) then
--      ttif:SetBackdropBorderColor(self, 1, .5, 0, 1);
--	end
end

-- item
function LinkTypeFuncs:item(link,linkType,id)
	local _, _, itemRarity, itemLevel, _, _, _, itemStackCount, _, itemTexture = GetItemInfo(link);
	itemLevel = LibItemString:GetTrueItemLevel(link);
	
	-- Add Keystone Icon / Quality
	if linkType == "keystone" then
		itemRarity = 4;
		if id == "187786" then
			itemTexture = 531324;
		else
			itemTexture = 525134;
		end
	end
	
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		local count = (itemStackCount and itemStackCount > 1 and (itemStackCount == 0x7FFFFFFF and "#" or itemStackCount) or "");
		self:ttSetIconTextureAndText(itemTexture,count);
	end

	-- Quality Border
	if (cfg.if_itemQualityBorder) then
		local itemQualityColor = CreateColorFromHexString(select(4, GetItemQualityColor(itemRarity or 0)));
		ttif:SetBackdropBorderColor(self, itemQualityColor:GetRGBA());
	end

	-- level + id -- Only alter the tip if we got either a valid "itemLevel" or "id"
	local showLevel = (itemLevel and cfg.if_showItemLevel);
	local showId = (id and cfg.if_showItemId);
	local linePadding = 2;

	if (showLevel or showId) then
		local targetTooltip = self;
		if (showLevel) then
			if (self == ejtt) then
				targetTooltip = self.Item1.tooltip;
				if (targetTooltip:IsShown()) then
					-- remove level from embedded tip
					for i = 2, min(targetTooltip:NumLines(), LibItemString.TOOLTIP_MAXLINE_LEVEL) do
						local line = _G[targetTooltip:GetName().."TextLeft"..i];
						if (line and (line:GetText() or ""):match(ITEM_LEVEL_PLUS)) then
							line:SetText(nil);
							break;
						end
					end
				else 
					-- remove level from tip's line pool
					for line in self.linePool:EnumerateActive() do
						if (line and (line:GetText() or ""):match(ITEM_LEVEL_PLUS)) then
							local linePredecessorPoint, linePredecessorRelativeTo, linePredecessorRelativePoint, linePredecessorXOfs, linePredecessorYOfs = line:GetPoint(1);
							
							if (line == self.textLineAnchor) then
								-- last line in line pool
								self.textLineAnchor = linePredecessorRelativeTo;
							else
								-- re-anchor successor line
								for successorLine in self.linePool:EnumerateActive() do
									local successorLinePredecessorPoint, successorLinePredecessorRelativeTo, successorLinePredecessorRelativePoint, successorLinePredecessorXOfs, successorLinePredecessorYOfs = successorLine:GetPoint(1);
									
									if (successorLinePredecessorRelativeTo == line) then
										local successorLineNumPoints = successorLine:GetNumPoints();
										local successorLineLeftPoint, successorLineLeftRelativeTo, successorLineLeftRelativePoint, successorLineLeftXOfs, successorLineLeftYOfs = successorLine:GetPoint(2);
										local successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs;
										if (successorLineNumPoints > 2) then
											successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs = successorLine:GetPoint(3);
										end
										successorLinePredecessorRelativeTo = linePredecessorRelativeTo;
										
										successorLine:ClearAllPoints();
										successorLine:SetPoint(successorLinePredecessorPoint, successorLinePredecessorRelativeTo, successorLinePredecessorRelativePoint, successorLinePredecessorXOfs, successorLinePredecessorYOfs);
										successorLine:SetPoint(successorLineLeftPoint, successorLineLeftRelativeTo, successorLineLeftRelativePoint, successorLineLeftXOfs, successorLineLeftYOfs);
										if (successorLineNumPoints > 2) then
											successorLine:SetPoint(successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs);
										end
										break;
									end
								end
							end
							
							-- remove level from tip's line pool
							self:SetHeight(self:GetHeight() - line:GetHeight() - linePadding);
							line:ClearAllPoints();
							self.linePool:Release(line);
							
							break;
						end
					end
				end
			else
				for i = 2, min(self:NumLines(),LibItemString.TOOLTIP_MAXLINE_LEVEL) do
					local line = _G[self:GetName().."TextLeft"..i];
					if (line and (line:GetText() or ""):match(ITEM_LEVEL_PLUS)) then
						line:SetText(nil);
						break;
					end
				end
			end
		end

		if (not showLevel) then
			targetTooltip:AddLine(format("ItemID: %d",id),unpack(cfg.if_infoColor));
		elseif (showId) then
			targetTooltip:AddLine(format("ItemLevel: %d, ItemID: %d",itemLevel,id),unpack(cfg.if_infoColor));
		else
			targetTooltip:AddLine(format("ItemLevel: %d",itemLevel),unpack(cfg.if_infoColor));
		end
		targetTooltip:Show();	-- call Show() to resize tip after adding lines. only necessary for items in toy box.
	end
end

-- spell
function LinkTypeFuncs:spell(link, linkType, spellID)
	local name, _, icon, castTime, minRange, maxRange, _spellID = GetSpellInfo(spellID);	-- [18.07.19] 8.0/BfA: 2nd param "rank/nameSubtext" now returns nil
	local rank = GetSpellSubtext(spellID);	-- will return nil at first unless its locally cached
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		self:ttSetIconTextureAndText(icon);
	end
	-- SpellID + Rank
	if (cfg.if_showSpellIdAndRank) then
		rank = (rank and rank ~= "" and ", "..rank or "");
		self:AddLine("SpellID: "..spellID..rank,unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end
  	-- Colored Border
	if (cfg.if_spellColoredBorder) then
		local spellColor = CreateColorFromHexString("FF71D5FF"); -- see GetSpellLink(). extraction of color code from this function not used, because in classic it only returns the spell name instead of a link.
		ttif:SetBackdropBorderColor(self, spellColor:GetRGBA());
	end
end

-- quest
function LinkTypeFuncs:quest(link, linkType, questID, level)
	-- QuestLevel + QuestID
	local showLevel = (level and cfg.if_showQuestLevel);
	local showId = (questID and cfg.if_showQuestId);

	if (showLevel or showId) then
		if (not showLevel) then
			self:AddLine(format("QuestID: %d", questID or 0), unpack(cfg.if_infoColor));
		elseif (showId) then
			self:AddLine(format("QuestLevel: %d, QuestID: %d", level or 0, questID or 0), unpack(cfg.if_infoColor));
		else
			self:AddLine(format("QuestLevel: %d", level or 0), unpack(cfg.if_infoColor));
		end
		self:Show();	-- call Show() to resize tip after adding lines
	end
  	-- Difficulty Border
	if (cfg.if_questDifficultyBorder) then
		local difficultyColor = GetDifficultyColor(C_PlayerInfo.GetContentDifficultyQuestForPlayer(questID));
		local difficultyColorMixin = CreateColor(difficultyColor.r, difficultyColor.g, difficultyColor.b, 1);
		ttif:SetBackdropBorderColor(self, difficultyColorMixin:GetRGBA());
	end
end

-- currency -- Thanks to Vladinator for adding this!
function LinkTypeFuncs:currency(link, linkType, currencyID, quantity)
	local currencyInfo = C_CurrencyInfo.GetCurrencyInfo(currencyID);
	
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		if (currencyInfo) then
			local displayQuantity = nil;
			self:ttSetIconTextureAndText(currencyInfo.iconFileID, quantity);	-- As of 5.2 GetCurrencyInfo() now returns full texture path. Previously you had to prefix it with "Interface\\Icons\\"
		end
	end

	-- CurrencyID
	if (cfg.if_showCurrencyId) then
		self:AddLine(format("CurrencyID: %d", currencyID), unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end

  	-- Quality Border
	if (cfg.if_currencyQualityBorder) then
		if (currencyInfo) then
			local quality = currencyInfo.quality;
			if (tonumber(currencyID) == 1822) then -- switch "Renown" from artifact (6) to legendary (5)
				quality = 5;
			end
			local currencyQualityColor = CreateColorFromHexString(select(4, GetItemQualityColor(quality)));
			ttif:SetBackdropBorderColor(self, currencyQualityColor:GetRGBA());
		end
	end
end

-- achievement
function LinkTypeFuncs:achievement(link, linkType, achievementID, guid, completed, month, day, year, criteria1, criteria2, criteria3, criteria4)
	if (cfg.if_modifyAchievementTips) then
		completed = (tonumber(completed) == 1);
		local tipName = self:GetName();
		local isPlayer = (UnitGUID("player"):sub(3) == guid);
		-- Get category
		local catId = GetAchievementCategory(achievementID);
		local category, catParent = GetCategoryInfo(catId);
		local catName;
		while (catParent > 0) do
			catName, catParent = GetCategoryInfo(catParent);
			category = catName.." - "..category;
		end
		-- Get Criteria
		wipe(criteriaList);
		local criteriaComplete = 0;
		for i = 6, self:NumLines() do
			local left = _G[tipName.."TextLeft"..i];
			local right = _G[tipName.."TextRight"..i];
			local leftText = left:GetText();
			local rightText = right:GetText();
			if (leftText and leftText ~= " ") then
				criteriaList[#criteriaList + 1] = { label = leftText, done = left:GetTextColor() < 0.5 };
				if (criteriaList[#criteriaList].done) then
					criteriaComplete = (criteriaComplete + 1);
				end
			end
			if (rightText and rightText ~= " ") then
				criteriaList[#criteriaList + 1] = { label = rightText, done = right:GetTextColor() < 0.5 };
				if (criteriaList[#criteriaList].done) then
					criteriaComplete = (criteriaComplete + 1);
				end
			end
		end
		-- Cache Info
		local progressText = _G[tipName.."TextLeft3"]:GetText() or "";
		local _, title, points, _, _, _, _, description, _, icon, reward = GetAchievementInfo(achievementID);
		-- Rebuild Tip
		self:ClearLines();
		local stat = isPlayer and GetStatistic(achievementID);
		self:AddDoubleLine(title,(stat ~= "0" and stat ~= "--" and stat),nil,nil,nil,1,1,1);
		self:AddLine("<"..category..">");
		if (reward) then
			self:AddLine(reward,unpack(cfg.if_infoColor));
		end
		self:AddLine(description,1,1,1,1);
		if (progressText ~= "") then
			self:AddLine(BoolCol[completed]..progressText);
		end
		if (#criteriaList > 0) then
			self:AddLine(" ");
			self:AddLine("Achievement Criteria |cffffffff"..criteriaComplete.."|r of |cffffffff"..#criteriaList);
			local r1, g1, b1, r2, g2, b2;
			local myDone1, myDone2;
			for i = 1, #criteriaList, 2 do
				r1, g1, b1 = unpack(criteriaList[i].done and COLOR_COMPLETE or COLOR_INCOMPLETE);
				if (criteriaList[i + 1]) then
					r2, g2, b2 = unpack(criteriaList[i + 1].done and COLOR_COMPLETE or COLOR_INCOMPLETE);
				end
				if (not isPlayer) then
					local success, _, _, completed = pcall(GetAchievementCriteriaInfo,achievementID,i);
					myDone1 = (success and completed);
					--myDone1 = select(3,GetAchievementCriteriaInfo(achievementID,i));
					if (i + 1 <= #criteriaList) then
						local success, _, _, completed = pcall(GetAchievementCriteriaInfo,achievementID,i + 1);
						myDone2 = (success and completed);
						--myDone2 = select(3,GetAchievementCriteriaInfo(achievementID,i + 1));
					end
				end
				myDone1 = (isPlayer and "" or BoolCol[myDone1].."*|r")..criteriaList[i].label;
				myDone2 = criteriaList[i + 1] and criteriaList[i + 1].label..(isPlayer and "" or BoolCol[myDone2].."*");
				self:AddDoubleLine(myDone1,myDone2,r1,g1,b1,r2,g2,b2);
			end
		end
		-- AchievementID + Category
		if (cfg.if_showAchievementIdAndCategoryId) then
			self:AddLine(format("AchievementID: %d, CategoryID: %d",achievementID or 0,catId or 0),unpack(cfg.if_infoColor));
		end
		-- Icon
		if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
			self:ttSetIconTextureAndText(icon,points);
		end
		-- Show
		self:Show();	-- call Show() to resize tip after adding lines
	else
		-- Icon
		if (self.ttSetIconTextureAndText) then
			local _, _, points, _, _, _, _, _, _, icon = GetAchievementInfo(achievementID);
			self:ttSetIconTextureAndText(icon,points);
		end
		-- AchievementID + Category
		if (cfg.if_showAchievementIdAndCategoryId) then
			local catId = GetAchievementCategory(achievementID);
			self:AddLine(format("AchievementID: %d, CategoryID: %d",achievementID or 0,catId or 0),unpack(cfg.if_infoColor));
			self:Show();	-- call Show() to resize tip after adding lines
		end
	end
  	--  Colored Border
	if (cfg.if_achievmentColoredBorder) then
		local achievementColor = ACHIEVEMENT_COLOR_CODE:match("|c(%x+)");
		local achievementColorMixin = CreateColorFromHexString(achievementColor);
		ttif:SetBackdropBorderColor(self, achievementColorMixin:GetRGBA());
	end
end

-- battle pet
function LinkTypeFuncs:battlepet(link, linkType, speciesID, level, breedQuality, maxHealth, power, speed, petID, displayID)
	local speciesName, speciesIcon, petType, creatureID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, _displayID = C_PetJournal.GetPetInfoBySpeciesID(speciesID);

	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self, linkType)) then
		self:ttSetIconTextureAndText(speciesIcon);
	end

	-- Quality Border
	if (cfg.if_battlePetQualityBorder) then
		local battlePetQualityColor = CreateColorFromHexString(select(4, GetItemQualityColor(breedQuality or 0)));
		ttif:SetBackdropBorderColor(self, battlePetQualityColor:GetRGBA());
	end

	-- level + creatureID -- Only alter the tip if we got either a valid "level" or "creatureID"
	local showLevel = (level and cfg.if_showBattlePetLevel);
	local showId = (creatureID and cfg.if_showBattlePetId);
	local linePadding = 2;

	if (showLevel or showId) then
		if (showLevel) then
			if (self == bptt or self == fbptt) then
				-- remove level from tip
				self:SetHeight(self:GetHeight() - self.Level:GetHeight() - linePadding);
				self.Level:SetText(nil);
				
				-- re-anchor successor node
				local levelPoint, levelRelativeTo, levelRelativePoint, levelXOfs, levelYOfs = self.Level:GetPoint();
				local healthTexturePoint, healthTextureRelativeTo, healthTextureRelativePoint, healthTextureXOfs, healthTextureYOfs = self.HealthTexture:GetPoint();
				healthTextureRelativeTo = levelRelativeTo;
				
				self.HealthTexture:ClearAllPoints();
				self.HealthTexture:SetPoint(healthTexturePoint, healthTextureRelativeTo, healthTextureRelativePoint, healthTextureXOfs, healthTextureYOfs);
				
				-- remove level from tip's line pool
				for line in self.linePool:EnumerateActive() do
					if (line and (line:GetText() or ""):match(BATTLE_PET_CAGE_TOOLTIP_LEVEL)) then
						local linePredecessorPoint, linePredecessorRelativeTo, linePredecessorRelativePoint, linePredecessorXOfs, linePredecessorYOfs = line:GetPoint(1);
						
						if (line == self.textLineAnchor) then
							-- last line in line pool
							self.textLineAnchor = linePredecessorRelativeTo;
						else
							-- re-anchor successor line
							for successorLine in self.linePool:EnumerateActive() do
								local successorLinePredecessorPoint, successorLinePredecessorRelativeTo, successorLinePredecessorRelativePoint, successorLinePredecessorXOfs, successorLinePredecessorYOfs = successorLine:GetPoint(1);
								
								if (successorLinePredecessorRelativeTo == line) then
									local successorLineNumPoints = successorLine:GetNumPoints();
									local successorLineLeftPoint, successorLineLeftRelativeTo, successorLineLeftRelativePoint, successorLineLeftXOfs, successorLineLeftYOfs = successorLine:GetPoint(2);
									local successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs;
									if (successorLineNumPoints > 2) then
										successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs = successorLine:GetPoint(3);
									end
									successorLinePredecessorRelativeTo = linePredecessorRelativeTo;
									
									successorLine:ClearAllPoints();
									successorLine:SetPoint(successorLinePredecessorPoint, successorLinePredecessorRelativeTo, successorLinePredecessorRelativePoint, successorLinePredecessorXOfs, successorLinePredecessorYOfs);
									successorLine:SetPoint(successorLineLeftPoint, successorLineLeftRelativeTo, successorLineLeftRelativePoint, successorLineLeftXOfs, successorLineLeftYOfs);
									if (successorLineNumPoints > 2) then
										successorLine:SetPoint(successorLineRightPoint, successorLineRightRelativeTo, successorLineRightRelativePoint, successorLineRightXOfs, successorLineRightYOfs);
									end
									break;
								end
							end
						end
						
						-- remove level from tip's line pool
						self:SetHeight(self:GetHeight() - line:GetHeight() - linePadding);
						line:ClearAllPoints();
						self.linePool:Release(line);
						
						break;
					end
				end
			else
				for i = 2, min(self:NumLines(),LibItemString.TOOLTIP_MAXLINE_LEVEL) do
					local line = _G[self:GetName().."TextLeft"..i];
					if (line and (line:GetText() or ""):match(BATTLE_PET_CAGE_TOOLTIP_LEVEL)) then
						line:SetText(nil);
						break;
					end
				end
			end
		end
		
		if (not showLevel) then
			self:AddLine(format("NPC ID: %d", tonumber(creatureID)), unpack(cfg.if_infoColor));
		elseif (showId) then
			self:AddLine(format("PetLevel: %d, NPC ID: %d", level, tonumber(creatureID)), unpack(cfg.if_infoColor));
		else
			self:AddLine(format("PetLevel: %d", level), unpack(cfg.if_infoColor));
		end

		if (self ~= bptt and self ~= fbptt) then
			self:Show();	-- call Show() to resize tip after adding lines. only necessary for pet tooltip in action bar.
		end
	end
	
	if (not showLevel) then
		if (self == bptt or self == fbptt) then
			-- re-anchor successor node if necessary
			local healthTexturePoint, healthTextureRelativeTo, healthTextureRelativePoint, healthTextureXOfs, healthTextureYOfs = self.HealthTexture:GetPoint();
			
			if (healthTextureRelativeTo ~= self.Level) then
				healthTextureRelativeTo = self.Level;
				
				self.HealthTexture:ClearAllPoints();
				self.HealthTexture:SetPoint(healthTexturePoint, healthTextureRelativeTo, healthTextureRelativePoint, healthTextureXOfs, healthTextureYOfs);
			end
		end
	end
end

-- battle pet ability
function LinkTypeFuncs:battlePetAbil(link, linkType, abilityID, speciesID, petID, additionalText)
	local abilityName, abilityIcon, abilityType = C_PetJournal.GetPetAbilityInfo(abilityID)

	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self, linkType)) then
		self:ttSetIconTextureAndText(abilityIcon);
	end

	-- AbilityID
	if (cfg.if_showBattlePetAbilityId) then
		self:AddLine("AbilityID: "..abilityID, unpack(cfg.if_infoColor));
		-- self:Show();	-- call Show() to resize tip after adding lines
	end

	-- Colored Border
	if (cfg.if_battlePetAbilityColoredBorder) then
		local abilityColor = CreateColorFromHexString("FF4E96F7"); -- see GetBattlePetAbilityHyperlink() in "ItemRef.lua"
		ttif:SetBackdropBorderColor(self, abilityColor:GetRGBA());
	end
end

-- transmog illusion
function LinkTypeFuncs:transmogillusion(link, linkType, illusionID)
	local illusionInfo = C_TransmogCollection.GetIllusionInfo(illusionID);
	
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self, linkType)) then
		self:ttSetIconTextureAndText(illusionInfo.icon);
	end

	-- IllusionID
	if (cfg.if_showTransmogIllusionId) then
		self:AddLine(format("IllusionID: %d", illusionID), unpack(cfg.if_infoColor));
		-- self:Show();	-- call Show() to resize tip after adding lines
	end

  	-- Colored Border
	if (cfg.if_transmogIllusionColoredBorder) then
		local name, hyperlink, sourceText = C_TransmogCollection.GetIllusionStrings(illusionID);
		local illusionColor = hyperlink:match("|c(%x+)");
		local illusionColorMixin = CreateColorFromHexString(illusionColor);
		ttif:SetBackdropBorderColor(self, illusionColorMixin:GetRGBA());
	end
end

-- conduit -- Thanks to hobulian for code example
function LinkTypeFuncs:conduit(link, linkType, conduitID, conduitRank)
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self, linkType)) then
		local spellID = C_Soulbinds.GetConduitSpellID(conduitID, conduitRank);
		local name, _, icon, castTime, minRange, maxRange, _spellID = GetSpellInfo(spellID);
		self:ttSetIconTextureAndText(icon);
	end

	-- ItemLevel + ConduitID
	local conduitCollectionData = C_Soulbinds.GetConduitCollectionData(conduitID)
	local conduitItemLevel = conduitCollectionData.conduitItemLevel;
	
	local showLevel = (conduitItemLevel and cfg.if_showConduitItemLevel);
	local showId = (conduitID and cfg.if_showConduitId);

	if (showLevel or showId) then
		if (showLevel) then
			for i = 2, min(self:NumLines(),LibItemString.TOOLTIP_MAXLINE_LEVEL) do
				local line = _G[self:GetName().."TextLeft"..i];
				if (line and (line:GetText() or ""):match(ITEM_LEVEL_PLUS)) then
					line:SetText(nil);
					break;
				end
			end
		end
		
		if (not showLevel) then
			self:AddLine(format("ConduitID: %d", conduitID), unpack(cfg.if_infoColor));
		elseif (showId) then
			self:AddLine(format("ItemLevel: %d, ConduitID: %d", conduitItemLevel, conduitID), unpack(cfg.if_infoColor));
		else
			self:AddLine(format("ItemLevel: %d", conduitItemLevel), unpack(cfg.if_infoColor));
		end
		-- self:Show();	-- call Show() to resize tip after adding lines. only necessary for items in toy box.
	end

  	-- Quality Border
	if (cfg.if_conduitQualityBorder) then
		local conduitQuality = C_Soulbinds.GetConduitQuality(conduitID, conduitRank);
		local conduitQualityColor = CreateColorFromHexString(select(4, GetItemQualityColor(conduitQuality or 0)));
		ttif:SetBackdropBorderColor(self, conduitQualityColor:GetRGBA());
	end
end

--------------------------------------------------------------------------------------------------------
--                                      Tip CustomType Functions                                      --
--------------------------------------------------------------------------------------------------------

-- runeforge power
function CustomTypeFuncs:runeforgePower(link, linkType, runeforgePowerID)
	local powerInfo = C_LegendaryCrafting.GetRuneforgePowerInfo(runeforgePowerID);
	
	-- Icon
	if (self.ttSetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self, linkType)) then
		self:ttSetIconTextureAndText(powerInfo.iconFileID);
	end

	-- RuneforgePowerID
	if (cfg.if_showRuneforgePowerId) then
		self:AddLine(format("RuneforgePowerID: %d", runeforgePowerID), unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end

  	-- Colored Border
	if (cfg.if_runeforgePowerColoredBorder) then
		local runeforgePowerColor = CreateColor(LEGENDARY_ORANGE_COLOR.r, LEGENDARY_ORANGE_COLOR.g, LEGENDARY_ORANGE_COLOR.b, 1); -- see RuneforgePowerBaseMixin:OnEnter() in "RuneforgeUtil.lua"
		ttif:SetBackdropBorderColor(self, runeforgePowerColor:GetRGBA());
	end
end

-- guild challenge
function CustomTypeFuncs:guildChallenge(link, linkType)
  	-- Colored Border
	if (cfg.if_guildChallengeColoredBorder) then
		local guildChallengeColor = CreateColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1); -- see CommunitiesGuildChallengeTemplate:OnEnter() / GuildChallengeTemplate:OnEnter() in "Blizzard_Communities/GuildInfo.xml" / "Blizzard_GuildUI/Blizzard_GuildInfo.xml"
		ttif:SetBackdropBorderColor(self, guildChallengeColor:GetRGBA());
	end
end

-- pvp enlistment bonus
function CustomTypeFuncs:pvpEnlistmentBonus(link, linkType)
  	-- Colored Border
	if (cfg.if_pvpEnlistmentBonusColoredBorder) then
		local pvpEnlistmentBonusColor = CreateColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1); -- see PVPRewardEnlistmentBonus_OnEnter() in "Blizzard_PVPUI/Blizzard_PVPUI.lua"
		ttif:SetBackdropBorderColor(self, pvpEnlistmentBonusColor:GetRGBA());
	end
end
