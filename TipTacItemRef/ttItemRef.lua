local format = string.format;
local unpack = unpack;

-- Addon
local modName = ...;
local ttif = CreateFrame("Frame",modName,nil,BackdropTemplateMixin and "BackdropTemplate");	-- 9.0.1: Using BackdropTemplate

-- Register with TipTac core addon if available
if (TipTac) then
	TipTac:RegisterElement(ttif,"ItemRef");
end

-- Options without TipTac. If the base TipTac addon is used, the global TipTac_Config table is used instead
local cfg = {
	if_enable = true,
	if_infoColor = { 0.2, 0.6, 1 },
	if_itemQualityBorder = true,
	if_showAuraCaster = true,

	if_showItemLevel = false,					-- Used to be true, but changed due to the itemLevel issues
	if_showItemId = false,
	if_showQuestLevelAndId = true,
	if_showSpellIdAndRank = false,
	if_showCurrencyId = true,					-- Az: no option for this added to TipTac/options yet!
	if_showAchievementIdAndCategory = false,	-- Az: no option for this added to TipTac/options yet!

	if_modifyAchievementTips = true,
	if_showIcon = true,
	if_smartIcons = true,
	if_borderlessIcons = false,
	if_iconSize = 42,
};

-- Tooltips to Hook into -- MUST be a GameTooltip widget -- If the main TipTac is installed, the TT_TipsToModify is used instead
local tipsToModify = {
	"GameTooltip",
	"ItemRefTooltip",
};
-- Tips which will have an icon
local tipsToAddIcon = {
	["GameTooltip"] = true,
	["ItemRefTooltip"] = true,
};

-- Tables
local LinkTypeFuncs = {};
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
local function SetIconTextureAndText(self,texture,count)
	if (texture) then
		self.ttIcon:SetTexture(texture ~= "" and texture or "Interface\\Icons\\INV_Misc_QuestionMark");
		self.ttCount:SetText(count);
		self.ttIcon:Show();
	else
		self.ttIcon:Hide();
		self.ttCount:SetText("");
	end
end

-- Create Icon with Counter Text for Tooltip
function ttif:CreateTooltipIcon(tip)
	tip.ttIcon = tip:CreateTexture(nil,"BACKGROUND");
	tip.ttIcon:SetPoint("TOPRIGHT",tip,"TOPLEFT",0,-2.5);
	tip.ttIcon:Hide();

	tip.ttCount = tip:CreateFontString(nil,"ARTWORK");
	tip.ttCount:SetTextColor(1,1,1);
	tip.ttCount:SetPoint("BOTTOMRIGHT",tip.ttIcon,"BOTTOMRIGHT",-3,3);
end

--------------------------------------------------------------------------------------------------------
--                                         TipTacItemRef Frame                                        --
--------------------------------------------------------------------------------------------------------

ttif:RegisterEvent("VARIABLES_LOADED");

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
			if (type(tip) == "table" and type(tip.SetBackdrop) ~= "function" and BackdropTemplateMixin and "BackdropTemplate") then
				Mixin(tip, BackdropTemplateMixin);
			end
			resolved[tip] = index;
		end

		-- Assign the resolved object or false back into the table array
		tipTable[index] = tip;
	end
end

-- OnEvent
ttif:SetScript("OnEvent",function(self,event,...)
	-- What tipsToModify to use, TipTac's main addon, or our own?
	if (TipTac and TipTac.tipsToModify) then
		tipsToModify = TipTac.tipsToModify;
	else
		ResolveGlobalNamedObjects(tipsToModify)
	end

	-- Use TipTac settings if installed
	if (TipTac_Config) then
		cfg = TipTac_Config;
	end

	-- Hook tips and apply settings
	self:DoHooks();
	self:OnApplyConfig();

	-- Cleanup; we no longer need to receive any events
	self:UnregisterAllEvents();
	self:SetScript("OnEvent",nil);
end);

-- Apply Settings -- It seems this may be called from TipTac:OnApplyConfig() before we have received our VARIABLES_LOADED, so ensure we have created the tip objects
function ttif:OnApplyConfig()
	local gameFont = GameFontNormal:GetFont();
	for index, tip in ipairs(tipsToModify) do
		if (type(tip) == "table") and (tipsToAddIcon[tip:GetName()]) and (tip.ttIcon) then
			if (cfg.if_showIcon) then
				tip.ttIcon:SetSize(cfg.if_iconSize,cfg.if_iconSize);
				tip.ttCount:SetFont(gameFont,(cfg.if_iconSize / 3),"OUTLINE");
				tip.SetIconTextureAndText = SetIconTextureAndText;
				if (cfg.if_borderlessIcons) then
					tip.ttIcon:SetTexCoord(0.07,0.93,0.07,0.93);
				else
					tip.ttIcon:SetTexCoord(0,1,0,1);
				end
			elseif (tip.SetIconTextureAndText) then
				tip.ttIcon:Hide();
				tip.SetIconTextureAndText = nil;
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                       HOOK: Tooltip Functions                                      --
--------------------------------------------------------------------------------------------------------

-- HOOK: ItemRefTooltip + GameTooltip: SetHyperlink
local function SetHyperlink_Hook(self,hyperLink)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local refString = hyperLink:match("|H([^|]+)|h") or hyperLink;
		local linkType = refString:match("^[^:]+");
		-- Call Tip Type Func
		if (LinkTypeFuncs[linkType]) and (self:NumLines() > 0) then
			tipDataAdded[self] = "hyperlink";
			LinkTypeFuncs[linkType](self,refString,(":"):split(refString));
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

-- HOOK: SetAction
local function SetAction_Hook(self,slot)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local kind, id = GetActionInfo(slot)
		if (kind == "item" and id) then
			tipDataAdded[self] = "toy";
			LinkTypeFuncs.toy(self,nil,"toy",id);
		end
	end
end

-- HOOK: SetToyByItemID_Hook
local function SetToyByItemID_Hook(self,id)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		if (id) then
			tipDataAdded[self] = "toy";
			LinkTypeFuncs.toy(self,nil,"toy",id);
		end
	end
end

-- HOOK: SetSpellByID_Hook
local function SetSpellByID_Hook(self,...)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local id = self.spell and self.spell:GetSpellID()
		if (id) then
			tipDataAdded[self] = "spell";
			LinkTypeFuncs.spell(self,nil,"spell",id);
		end
	end
end

-- HOOK: SetCouduitByID_Hook
local function SetCouduitByID_Hook(self,id,rank)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		if (id and rank) then
			tipDataAdded[self] = "conduit";
			LinkTypeFuncs.conduit(self,nil,"conduit",id,rank);
		end
	end
end

-- HOOK: SetCurrencyByID_Hook
local function SetCurrencyByID_Hook(self,id,...)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		if (id) then
			tipDataAdded[self] = "currency";
			LinkTypeFuncs.currency(self,nil,"currency",id);
		end
	end
end

-- HOOK: SetQuestCurrency_Hook
local function SetQuestCurrency_Hook(self,type,id)
	local Owner = self:GetOwner()
	local questId = Owner.questID
	
	if (cfg.if_enable) and (not tipDataAdded[self]) and questId then
		local currencyId
		if (QuestInfoFrame.questLog) then
			currencyId = select(4,GetQuestLogRewardCurrencyInfo(id, questId, type=="choice"));
		else
			currencyId = GetQuestCurrencyID(type, id);
		end
		
		if (currencyId) then
			tipDataAdded[self] = "currency";
			LinkTypeFuncs.currency(self,nil,"currency",currencyId);
		end
	end
end		
	
-- HOOK: SetCurrencyToken_Hook
local function SetCurrencyToken_Hook(self,id)
	local link = C_CurrencyInfo.GetCurrencyListLink(id)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local currencyId = tonumber(string.match(link,"currency:(%d+)"))
		if (currencyId) then
			tipDataAdded[self] = "currency";
			LinkTypeFuncs.currency(self,link,"currency",currencyId);
		end
	end
end

-- OnTooltipSetItem
local function OnTooltipSetItem(self,...)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		if (TipTac) then
			TipTac:ApplyTipBackdrop(self);
		end
		local _, link = self:GetItem();
		if (link) then
			local linkType, id = link:match("H?(%a+):(%d+)");
			if (id) then
				tipDataAdded[self] = linkType;
				LinkTypeFuncs.item(self,link,linkType,id);
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

-- Add Quality Border for Legendary Items
local function AddLine_Hook(self,text,color,wrap,leftOffset)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		-- Quality Border
		if (cfg.if_itemQualityBorder) and (text == RUNEFORGE_LEGENDARY_POWER_LABEL) then
			tipDataAdded[self] = "spell";
			local itemQualityColor = CreateColor(GetItemQualityColor(5));
			self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
			self.ttBackdropBorderColor = itemQualityColor;
		end
	end
end

-- AddC Quality Border for WorldQuests
local function AddQuestTimeToTooltip(self,id)
	if (cfg.if_enable) and (not tipDataAdded[self]) then
		local tagInfo = C_QuestLog.GetQuestTagInfo(id);
		-- Quality Border
		if (cfg.if_itemQualityBorder) and (tagInfo and tagInfo.quality) then
			tipDataAdded[self] = "quest";
			local itemQualityColor = CreateColor(GetItemQualityColor((tagInfo.quality == 1 and 3) or (tagInfo.quality == 2 and 4) or 1));
			self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
			self.ttBackdropBorderColor = itemQualityColor;
		end
	end
end

-- OnTooltipCleared
local function OnTooltipCleared(self)
	tipDataAdded[self] = nil;
	if (self.SetIconTextureAndText) then
		self:SetIconTextureAndText();
	end
end

-- HOOK: Apply hooks for all the tooltips to modify -- Only hook GameTooltip objects
function ttif:DoHooks()
	for index, tip in ipairs(tipsToModify) do
		if (type(tip) == "table") and (type(tip.GetObjectType) == "function") and (tip:GetObjectType() == "GameTooltip") then
			if (tipsToAddIcon[tip:GetName()]) then
				self:CreateTooltipIcon(tip);
			end
			hooksecurefunc(tip,"SetHyperlink",SetHyperlink_Hook);
			hooksecurefunc(tip,"SetUnitAura",SetUnitAura_Hook);
			hooksecurefunc(tip,"SetUnitBuff",SetUnitAura_Hook);
			hooksecurefunc(tip,"SetUnitDebuff",SetUnitAura_Hook);
			hooksecurefunc(tip,"SetConduit",SetCouduitByID_Hook);
			hooksecurefunc(tip,"SetEnhancedConduit",SetCouduitByID_Hook);
			hooksecurefunc(tip,"SetSpellByID",SetSpellByID_Hook);
			hooksecurefunc(tip,"SetToyByItemID",SetToyByItemID_Hook);
			hooksecurefunc(tip,"SetAction",SetAction_Hook);
			hooksecurefunc(tip,"SetCurrencyByID",SetCurrencyByID_Hook);
			hooksecurefunc(tip,"SetCurrencyToken",SetCurrencyToken_Hook);
			hooksecurefunc(tip,"SetQuestCurrency",SetQuestCurrency_Hook);
			hooksecurefunc(tip,"SetQuestLogCurrency",SetQuestCurrency_Hook);
			hooksecurefunc(tip,"AddLine",AddLine_Hook);
			hooksecurefunc("GameTooltip_AddQuestTimeToTooltip", AddQuestTimeToTooltip);	
			tip:HookScript("OnTooltipSetItem",OnTooltipSetItem);
			tip:HookScript("OnTooltipSetSpell",OnTooltipSetSpell);
			tip:HookScript("OnTooltipCleared",OnTooltipCleared);
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                        Smart Icon Evaluation                                       --
--------------------------------------------------------------------------------------------------------

-- returns true if an icon should be displayed
local function SmartIconEvaluation(tip,linkType)
	local owner = tip:GetOwner();
	-- No Owner?
	if (not owner) then
		return false;
	-- Item
	elseif (linkType == "item") then
		if (owner.hasItem or owner.action or owner.icon or owner.texture) then
			return false;
		end
	-- Spell
	elseif (linkType == "spell") then
		if (owner.action or owner.icon) then
			return false;
		end
	-- Conduit, Toy, Currency
	elseif (linkType == "conduit") or (linkType == "toy") or (linkType == "currency") then
		if (owner.icon) then
			return false;
		end		
	-- Achievement
--	elseif (linkType == "achievement") then
--		if (owner.icon) then
--			return false;
--		end
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

-- instancelock
function LinkTypeFuncs:instancelock(link,linkType,guid,mapId,difficulty,encounterBits)
	--AzDump(guid,mapId,difficulty,encounterBits)
  	-- TipType Border Color -- Disable these 3 lines to color border. Az: Work into options?
--	if (cfg.if_itemQualityBorder) then
--		self:SetBackdropBorderColor(1, .5, 0, 1);
--	end
end

-- item
function LinkTypeFuncs:item(link,linkType,id)
	local _, _, itemRarity, itemLevel, _, _, _, itemStackCount, _, itemTexture = GetItemInfo(link);
	itemLevel = LibItemString:GetTrueItemLevel(link);

	if linkType == "keystone" then
		itemRarity = 4;
		if id == "187786" then
			itemTexture = 531324;
		else
			itemTexture = 525134;
		end
	end
	
	-- Icon
	if (self.SetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		local count = (itemStackCount and itemStackCount > 1 and (itemStackCount == 0x7FFFFFFF and "#" or itemStackCount) or "");
		self:SetIconTextureAndText(itemTexture,count);
	end

	-- Quality Border
	if (cfg.if_itemQualityBorder) then
		local itemQualityColor = CreateColor(GetItemQualityColor(itemRarity or 0));
		self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
		self.ttBackdropBorderColor = itemQualityColor;
	end

	-- level + id -- Only alter the tip if we got either a valid "itemLevel" or "id"
	local showLevel = (itemLevel and cfg.if_showItemLevel);
	local showId = (id and cfg.if_showItemId);
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
			self:AddLine(format("ItemID: %d",id),unpack(cfg.if_infoColor));
		elseif (showId) then
			self:AddLine(format("ItemLevel: %d, ItemID: %d",itemLevel,id),unpack(cfg.if_infoColor));
		else
			self:AddLine(format("ItemLevel: %d",itemLevel),unpack(cfg.if_infoColor));
		end
--		self:Show();	-- call Show() to resize tip after adding lines
	end
end

-- spell
function LinkTypeFuncs:spell(link,linkType,id)
	local name, _, icon = GetSpellInfo(id);	-- [18.07.19] 8.0/BfA: 2nd param "rank/nameSubtext" now returns nil
	local rank = GetSpellSubtext(id);	-- will return nil at first unless its locally cached
	-- Icon
	if (self.SetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		self:SetIconTextureAndText(icon);
	end
	-- Id + Rank
	if (cfg.if_showSpellIdAndRank) then
		rank = (rank and rank ~= "" and ", "..rank or "");
		self:AddLine("SpellID: "..id..rank,unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end
  	-- TipType Border Color -- Disable these 3 lines to color border. Az: Work into options?
--	if (cfg.if_itemQualityBorder) then
--		self:SetBackdropBorderColor(.44, .84, 1, 1);
--	end
end

-- toy
function LinkTypeFuncs:toy(link,linkType,id)
	local _, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(id);
	-- Icon
	if (self.SetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		self:SetIconTextureAndText(icon);
	end
	-- Quality Border
	if (cfg.if_itemQualityBorder) then
		local itemQualityColor = CreateColor(GetItemQualityColor(itemRarity or 0));
		self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
		self.ttBackdropBorderColor = itemQualityColor;
	end
	self:Show();
end

-- conduit
function LinkTypeFuncs:conduit(link,linkType,id,rank)
	local spellId = C_Soulbinds.GetConduitSpellID(id, rank);
	local name, _, icon = GetSpellInfo(spellId);
	local quality = C_Soulbinds.GetConduitQuality(id, rank);
	-- Icon
	if (self.SetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
		self:SetIconTextureAndText(icon);
	end
	-- Quality Border
	if (cfg.if_itemQualityBorder) then
		local itemQualityColor = CreateColor(GetItemQualityColor(quality or 0));
		self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
		self.ttBackdropBorderColor = itemQualityColor;
	end
	-- Id + Rank
	if (cfg.if_showSpellIdAndRank) then
		rank = (rank and rank ~= "" and ", "..rank or "");
		self:AddLine("SpellID: "..id..rank,unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end	
end

-- quest
function LinkTypeFuncs:quest(link,linkType,id,level)
	if (cfg.if_showQuestLevelAndId) then
		self:AddLine(format("QuestLevel: %d, QuestID: %d",level or 0,id or 0),unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end
  	-- TipType Border Color -- Disable these 3 lines to color border. Az: Work into options?
--	if (cfg.if_itemQualityBorder) then
--		self:SetBackdropBorderColor(1, 1, 0, 1);
--	end
end

-- currency -- Thanks to Vladinator for adding this!
function LinkTypeFuncs:currency(link,linkType,id)
	local info = C_CurrencyInfo.GetCurrencyInfo(id);
	if not (info) then return end
	
	if (self.SetIconTextureAndText) then
		self:SetIconTextureAndText(info.iconFileID,info.quantity);	-- As of 5.2 GetCurrencyInfo() now returns full texture path. Previously you had to prefix it with "Interface\\Icons\\"
	end
	-- Quality Border
	if (cfg.if_itemQualityBorder) then	
		local quality = ((id == 1822) and 4) or info.quality
		local itemQualityColor = CreateColor(GetItemQualityColor(quality or 0));
		self:SetBackdropBorderColor(itemQualityColor:GetRGBA());
		self.ttBackdropBorderColor = itemQualityColor;
	end
	-- ID
	if (cfg.if_showCurrencyId) then
		self:AddLine(format("CurrencyID: %d",id),unpack(cfg.if_infoColor));
		self:Show();	-- call Show() to resize tip after adding lines
	end
end

-- achievement
function LinkTypeFuncs:achievement(link,linkType,id,guid,completed,month,day,year,unknown1,unknown2,unknown3,unknown4)
	if (cfg.if_modifyAchievementTips) then
		completed = (tonumber(completed) == 1);
		local tipName = self:GetName();
		local isPlayer = (UnitGUID("player"):sub(3) == guid);
		-- Get category
		local catId = GetAchievementCategory(id);
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
		local _, title, points, _, _, _, _, description, _, icon, reward = GetAchievementInfo(id);
		-- Rebuild Tip
		self:ClearLines();
		local stat = isPlayer and GetStatistic(id);
		self:AddDoubleLine(title,(stat ~= "0" and stat ~= "--" and stat),nil,nil,nil,1,1,1);
		self:AddLine("<"..category..">");
		if (reward) then
			self:AddLine(reward,unpack(cfg.if_infoColor));
		end
		self:AddLine(description,1,1,1,1);
		self:AddLine(BoolCol[completed]..progressText);
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
					local success, _, _, completed = pcall(GetAchievementCriteriaInfo,id,i);
					myDone1 = (success and completed);
					--myDone1 = select(3,GetAchievementCriteriaInfo(id,i));
					if (i + 1 <= #criteriaList) then
						local success, _, _, completed = pcall(GetAchievementCriteriaInfo,id,i + 1);
						myDone2 = (success and completed);
						--myDone2 = select(3,GetAchievementCriteriaInfo(id,i + 1));
					end
				end
				myDone1 = (isPlayer and "" or BoolCol[myDone1].."*|r")..criteriaList[i].label;
				myDone2 = criteriaList[i + 1] and criteriaList[i + 1].label..(isPlayer and "" or BoolCol[myDone2].."*");
				self:AddDoubleLine(myDone1,myDone2,r1,g1,b1,r2,g2,b2);
			end
		end
		-- ID + Category
		if (cfg.if_showAchievementIdAndCategory) then
			self:AddLine(format("AchievementID: %d, CategoryID: %d",id or 0,catId or 0),unpack(cfg.if_infoColor));
		end
		-- Icon
--		if (self.SetIconTextureAndText) then
		if (self.SetIconTextureAndText) and (not cfg.if_smartIcons or SmartIconEvaluation(self,linkType)) then
			self:SetIconTextureAndText(icon,points);
		end
		-- Show
		self:Show();	-- call Show() to resize tip after adding lines
	else
		-- Icon
		if (self.SetIconTextureAndText) then
			local _, _, points, _, _, _, _, _, _, icon = GetAchievementInfo(id);
			self:SetIconTextureAndText(icon,points);
		end
		-- ID + Category
		if (cfg.if_showAchievementIdAndCategory) then
			local catId = GetAchievementCategory(id);
			self:AddLine(format("AchievementID: %d, CategoryID: %d",id or 0,catId or 0),unpack(cfg.if_infoColor));
			self:Show();	-- call Show() to resize tip after adding lines
		end
	end
  	-- TipType Border Color -- Disable these 3 lines to color border. Az: Work into options?
--	if (cfg.if_itemQualityBorder) then
--		self:SetBackdropBorderColor(1, 1, 0, 1);
--	end
end
