-----------------------------------------------------------------------
-- TipTacTalents
--
-- Show player talents/specialization including role and talent/specialization icon and the average item level in the tooltip.
--

-- create addon
local MOD_NAME = ...;
local ttt = CreateFrame("Frame", MOD_NAME, nil, BackdropTemplateMixin and "BackdropTemplate");
ttt:Hide();

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;

-- default config
local TTT_DefaultConfig = {
	t_enable = true,                      -- "main switch", addon does nothing if false
	t_showTalents = true,                 -- show talents
	t_talentOnlyInParty = false,          -- only show talents/AIL for party/raid members
	
	t_showRoleIcon = true,                -- show role icon
	t_showTalentIcon = true,              -- show talent icon
	
	t_showTalentText = true,              -- show talent text
	t_colorTalentTextByClass = true,      -- color specialization text by class color
	t_talentFormat = 1,                   -- talent Format
	
	t_showAverageItemLevel = true,        -- show average item level (AIL)
	t_showGearScore = false,              -- show GearScore
	t_gearScoreAlgorithm =                -- GearScore algorithm
		((LibFroznFunctions.isWoWFlavor.SL or LibFroznFunctions.isWoWFlavor.DF) and 2 or 1),
	t_colorAILAndGSTextByQuality = true   -- color average item level and GearScore text by average quality
};

----------------------------------------------------------------------------------------------------
--                                           Variables                                            --
----------------------------------------------------------------------------------------------------

-- text constants
local TTT_TEXT = {
	talentsPrefix = ((LibFroznFunctions.isWoWFlavor.SL or LibFroznFunctions.isWoWFlavor.DF) and SPECIALIZATION or TALENTS), -- MoP: Could be changed from TALENTS (Talents) to SPECIALIZATION (Specialization)
	ailAndGSPrefix = STAT_AVERAGE_ITEM_LEVEL, -- Item Level
	onlyGSPrefix = "GearScore",
	loading = SEARCH_LOADING_TEXT, -- Loading...
	outOfRange = ERR_SPELL_OUT_OF_RANGE:sub(1, -2), -- Out of range.
	none = NONE_KEY, -- None
	-- na = NOT_APPLICABLE:lower() -- N/A
};

-- colors
local TTT_COLOR = {
	text = {
		default = HIGHLIGHT_FONT_COLOR, -- white
		spec = HIGHLIGHT_FONT_COLOR, -- white
		pointsSpent = LIGHTYELLOW_FONT_COLOR,
		ail = HIGHLIGHT_FONT_COLOR, -- white
		inlineGSPrefix = LIGHTYELLOW_FONT_COLOR
	}
};

----------------------------------------------------------------------------------------------------
--                                          Setup Addon                                           --
----------------------------------------------------------------------------------------------------

-- EVENT: addon loaded (one-time-event)
function ttt:ADDON_LOADED(event, addOnName, containsBindings)
	-- not this addon
	if (addOnName ~= MOD_NAME) then
		return;
	end
	
	-- setup config
	self:SetupConfig();
	
	-- apply hooks for inspecting
	self:ApplyHooksForInspecting();
	
	-- remove this event handler as it's not needed anymore
	self:UnregisterEvent(event);
	self[event] = nil;
end

-- register events
ttt:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...);
end);

ttt:RegisterEvent("ADDON_LOADED");

-- setup config
function ttt:SetupConfig()
	-- use TipTac config if installed
	if (TipTac_Config) then
		cfg = LibFroznFunctions:ChainTables(TipTac_Config, TTT_DefaultConfig);
	else
		cfg = TTT_DefaultConfig;
	end
end

----------------------------------------------------------------------------------------------------
--                                           Inspecting                                           --
----------------------------------------------------------------------------------------------------

-- HOOK: GameTooltip's OnTooltipSetUnit -- will schedule a delayed inspect request
local tttTipLineIndexTalents, tttTipLineIndexAILAndGS;

local function GTT_OnTooltipSetUnit(self, ...)
	-- exit if "main switch" isn't enabled
	if (not cfg.t_enable) then
		return;
	end
	
	-- get the unit id -- check the UnitFrame unit if this tip is from a concated unit, such as "targettarget".
	local _, unitID = LibFroznFunctions:GetUnitFromTooltip(self);
	
	if (not unitID) then
		local mouseFocus = GetMouseFocus();
		if (mouseFocus) and (mouseFocus.unit) then
			unitID = mouseFocus.unit;
		end
	end
	
	-- no unit id
	if (not unitID) then
		return;
	end
	
	-- check if only talents for people in your party/raid should be shown
	if (cfg.t_talentOnlyInParty) and (not UnitInParty(unitID)) and (not UnitInRaid(unitID)) then
		return;
	end
	
	-- invalidate line indexes
	tttTipLineIndexTalents = nil;
	tttTipLineIndexAILAndGS = nil;
	
	-- inspect unit
	local unitCacheRecord = LibFroznFunctions:InspectUnit(unitID, TTT_UpdateTooltip, true);
	
	if (unitCacheRecord) then
		TTT_UpdateTooltip(unitCacheRecord);
	end
end

-- apply hooks for inspecting during event ADDON_LOADED (one-time-function)
function ttt:ApplyHooksForInspecting()
	-- hooks needs to be applied as late as possible during load, as we want to try and be the
	-- last addon to hook GameTooltip's OnTooltipSetUnit so we always have a "completed" tip to work on.
	
	-- HOOK: GameTooltip's OnTooltipSetUnit -- will schedule a delayed inspect request
	LibFroznFunctions:HookScriptOnTooltipSetUnit(GameTooltip, GTT_OnTooltipSetUnit);
	
	-- remove this function as it's not needed anymore
	self.ApplyHooksForInspecting = nil;
end

----------------------------------------------------------------------------------------------------
--                                         Main Functions                                         --
----------------------------------------------------------------------------------------------------

-- update tooltip with the unit cache record
function TTT_UpdateTooltip(unitCacheRecord)
	-- exit if "main switch" isn't enabled
	if (not cfg.t_enable) then
		return;
	end
	
	-- exit if unit from unit cache record doesn't match the current displaying unit
	local _, unitID = LibFroznFunctions:GetUnitFromTooltip(GameTooltip);
	
	if (not unitID) then
		return;
	end
	
	local unitGUID = UnitGUID(unitID);
	
	if (unitGUID ~= unitCacheRecord.guid) then
		return;
	end
	
	-- update tooltip with the unit cache record
	
	-- talents
	if (cfg.t_showTalents) and (unitCacheRecord.talents) then
		local specText = LibFroznFunctions:CreatePushArray();
		
		-- talents available but no inspect data
		if (unitCacheRecord.talents == LFF_TALENTS.available) then
			if (unitCacheRecord.canInspect) then
				specText:Push(TTT_TEXT.loading);
			else
				specText:Push(TTT_TEXT.outOfRange);
			end
		
		-- no talents available
		elseif (unitCacheRecord.talents == LFF_TALENTS.na) then
			specText:Clear();
		
		-- no talents found
		elseif (unitCacheRecord.talents == LFF_TALENTS.none) then
			specText:Push(TTT_TEXT.none);
		
		-- talents found
		else
			local spacer, color;
			local talentFormat = (cfg.t_talentFormat or 1);
			local specNameAdded = false;
			
			if (cfg.t_showRoleIcon) and (unitCacheRecord.talents.role) then
				specText:Push(LibFroznFunctions:CreateMarkupForRoleIcon(unitCacheRecord.talents.role));
			end
			
			if (cfg.t_showTalentIcon) and (unitCacheRecord.talents.iconFileID) then
				specText:Push(LibFroznFunctions:CreateMarkupForClassIcon(unitCacheRecord.talents.iconFileID));
			end
			
			if (cfg.t_showTalentText) and ((talentFormat == 1) or (talentFormat == 2)) and (unitCacheRecord.talents.name) then
				spacer = (specText:GetCount() > 0) and " " or "";

				if (cfg.t_colorTalentTextByClass) then
					local classColor = LibFroznFunctions:GetClassColor(unitCacheRecord.classID, 5);
					specText:Push(spacer .. classColor:WrapTextInColorCode(unitCacheRecord.talents.name));
				else
					specText:Push(spacer .. unitCacheRecord.talents.name);
				end
				
				specNameAdded = true;
			end
			
			if (cfg.t_showTalentText) and ((talentFormat == 1) or (talentFormat == 3)) and (unitCacheRecord.talents.pointsSpent) then
				spacer = (specText:GetCount() > 0) and " " or "";
				
				if (specNameAdded) then
					specText:Push(spacer .. TTT_COLOR.text.pointsSpent:WrapTextInColorCode("(" .. table.concat(unitCacheRecord.talents.pointsSpent, "/") .. ")"));
				else
					specText:Push(spacer .. TTT_COLOR.text.pointsSpent:WrapTextInColorCode(table.concat(unitCacheRecord.talents.pointsSpent, "/")));
				end
			end
		end
		
		-- show spec text
		if (specText:GetCount() > 0) then
			local tipLineTextTalents = LibFroznFunctions:FormatText("{prefix}: {specText}", {
				prefix = TTT_TEXT.talentsPrefix,
				specText = TTT_COLOR.text.spec:WrapTextInColorCode(specText:Concat())
			});
			
			if (tttTipLineIndexTalents) then
				_G["GameTooltipTextLeft" .. tttTipLineIndexTalents]:SetText(tipLineTextTalents);
			else
				GameTooltip:AddLine(tipLineTextTalents);
				tttTipLineIndexTalents = GameTooltip:NumLines();
			end
		end
	end
	
	-- average item level and GearScore
	if ((cfg.t_showAverageItemLevel) or (cfg.t_showGearScore)) and (unitCacheRecord.averageItemLevel) then
		local ailAndGSText = LibFroznFunctions:CreatePushArray();
		local useOnlyGSPrefix = false;
		
		-- average item level available or no item data
		if (unitCacheRecord.averageItemLevel == LFF_AVERAGE_ITEM_LEVEL.available) then
			if (unitCacheRecord.canInspect) then
				ailAndGSText:Push(TTT_TEXT.loading);
			else
				ailAndGSText:Push(TTT_TEXT.outOfRange);
			end
		
		-- no average item level available
		elseif (unitCacheRecord.averageItemLevel == LFF_AVERAGE_ITEM_LEVEL.na) then
			ailAndGSText:Clear();
		
		-- no average item level found
		elseif (unitCacheRecord.averageItemLevel == LFF_AVERAGE_ITEM_LEVEL.none) then
			ailAndGSText:Push(TTT_TEXT.none);
		
		-- average item level found
		elseif (unitCacheRecord.averageItemLevel) then
			local spacer;
			
			-- average item level
			if (cfg.t_showAverageItemLevel) then
				if (cfg.t_colorAILAndGSTextByQuality) then
					ailAndGSText:Push(unitCacheRecord.averageItemLevel.qualityColor:WrapTextInColorCode(unitCacheRecord.averageItemLevel.value));
				else
					ailAndGSText:Push(unitCacheRecord.averageItemLevel.value);
				end
			end
			
			-- GearScore
			if (cfg.t_showGearScore) then
				spacer = (ailAndGSText:GetCount() > 0) and ("  " .. TTT_COLOR.text.inlineGSPrefix:WrapTextInColorCode("GS: ")) or "";
				
				if (ailAndGSText:GetCount() == 0) then
					useOnlyGSPrefix = true;
				end
				
				if (cfg.t_gearScoreAlgorithm == 1) then -- TacoTip's GearScore algorithm
					if (cfg.t_colorAILAndGSTextByQuality) then
						ailAndGSText:Push(spacer .. unitCacheRecord.averageItemLevel.TacoTipGearScoreQualityColor:WrapTextInColorCode(unitCacheRecord.averageItemLevel.TacoTipGearScore));
					else
						ailAndGSText:Push(spacer .. unitCacheRecord.averageItemLevel.TacoTipGearScore);
					end
				else -- TipTac's GearScore algorithm
					if (cfg.t_colorAILAndGSTextByQuality) then
						ailAndGSText:Push(spacer .. unitCacheRecord.averageItemLevel.TipTacGearScoreQualityColor:WrapTextInColorCode(unitCacheRecord.averageItemLevel.TipTacGearScore));
					else
						ailAndGSText:Push(spacer .. unitCacheRecord.averageItemLevel.TipTacGearScore);
					end
				end
			end
		end
		
		-- show ail and GS text
		if (ailAndGSText:GetCount() > 0) then
			local tipLineTextAverageItemLevel = LibFroznFunctions:FormatText("{prefix}: {averageItemLevelAndGearScore}", {
				prefix = useOnlyGSPrefix and TTT_TEXT.onlyGSPrefix or TTT_TEXT.ailAndGSPrefix,
				averageItemLevelAndGearScore = TTT_COLOR.text.ail:WrapTextInColorCode(ailAndGSText:Concat())
			});
			
			if (tttTipLineIndexAILAndGS) then
				_G["GameTooltipTextLeft" .. tttTipLineIndexAILAndGS]:SetText(tipLineTextAverageItemLevel);
			else
				GameTooltip:AddLine(tipLineTextAverageItemLevel);
				tttTipLineIndexAILAndGS = GameTooltip:NumLines();
			end
		end
	end
	
	-- recalculate size of tip to ensure that it has the correct dimensions
	LibFroznFunctions:RecalculateSizeOfGameTooltip(GameTooltip);
end
