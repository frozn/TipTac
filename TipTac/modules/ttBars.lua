-----------------------------------------------------------------------
-- TipTac - Bars
--
-- Shows the buffs and debuffs of the target unit with cooldown models. #test
--

-- create addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- register with TipTac core addon
local tt = _G[MOD_NAME];
local ttBars = { bars = {} };

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttBars, "Bars");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- constants
local TT_GTT_BARS_MARGIN_X = 7 + LibFroznFunctions.hasWoWFlavor.barMarginAdjustment;
local TT_GTT_BARS_MARGIN_Y = 8 + LibFroznFunctions.hasWoWFlavor.barMarginAdjustment;
local TT_GTT_BARS_SPACING = 7;

local TT_GTT_BARS_MINIMUM_WIDTH_FOR = 110; -- minimum width for bars, so that numbers are not out of bounds.

----------------------------------------------------------------------------------------------------
--                                         Element Events                                         --
----------------------------------------------------------------------------------------------------

-- config has been loaded
function ttBars:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	-- set config
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

-- config settings needs to be applied
function ttBars:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set default font if font in config is not valid
	if (not LibFroznFunctions:FontExists(cfg.barFontFace)) then
		cfg.barFontFace = nil;
		tt:AddMessageToChatFrame(MOD_NAME .. ": {error:No valid Font set in option tab {highlight:Bars}. Switching to default Font.}");
	end
	
	-- set default texture if texture in config is not valid
	if (not LibFroznFunctions:TextureExists(cfg.barTexture)) then
		cfg.barTexture = nil;
		tt:AddMessageToChatFrame(MOD_NAME .. ": {error:No valid texture set in option tab {highlight:Bars}. Switching to default texture.}");
	end
	
	-- set texture and height of GameTooltip's standard status bar
	GameTooltipStatusBar:SetStatusBarTexture(cfg.barTexture);
	GameTooltipStatusBar:GetStatusBarTexture():SetHorizTile(false); -- Az: 3.3.3 fix
	GameTooltipStatusBar:GetStatusBarTexture():SetVertTile(false);  -- Az: 3.3.3 fix
	GameTooltipStatusBar:SetHeight(cfg.barHeight);
	
	for _, bar in ipairs(self.bars) do
		-- set texture, height and font of status bar
		bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	end
end

-- before tooltip is being styled
function ttBars:OnTipPreStyle(TT_CacheForFrames, tip, first)
	-- for the first time styling, we want to initialize the bars.
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	if (first) then
		self:SetupBars(TT_CacheForFrames, tip, unitRecord);

		-- hide GameTooltip's standard status bar if needed
		if (cfg.hideDefaultBar) then
			GameTooltipStatusBar:Hide();
		end
	end
	
	-- update value of each shown bar
	for _, bar in ipairs(self.bars) do
		if (bar:IsShown()) then
			local value, maxValue, valueType = bar:GetValueParams(unitRecord);
			
			bar:SetMinMaxValues(0, maxValue);
			bar:SetValue(value);
			bar:SetFormattedBarValues(value, maxValue, valueType);
		end
	end
end

-- tooltip is being resized
function ttBars:OnTipResize(TT_CacheForFrames, tip, first)
	-- set minimum width for bars, so that numbers are not out of bounds.
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	for _, bar in ipairs(self.bars) do
		if (bar:GetVisibility(unitRecord)) then
			if (tip:GetWidth() < TT_GTT_BARS_MINIMUM_WIDTH_FOR) then
				tip:SetMinimumWidth(TT_GTT_BARS_MINIMUM_WIDTH_FOR);
			end
			
			break;
		end
	end
end

-- after tooltip's current display parameters has to be reset
function ttBars:OnTipPostResetCurrentDisplayParams(TT_CacheForFrames, tip)
	-- hide tip's bars
	for _, bar in ipairs(self.bars) do
		if (bar:GetParent() == tip) then
			bar:Hide();
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                         Main Functions                                         --
----------------------------------------------------------------------------------------------------

-- setup bars. initializes the anchoring position and color for each bar.
function ttBars:SetupBars(TT_CacheForFrames, tip, unitRecord)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- make two bars: health & power
	if (#self.bars == 0) then
		local tip = GameTooltip;
		
		self.bars[#self.bars + 1] = self:CreateBar(tip, self.PowerBarMixin);
		self.bars[#self.bars + 1] = self:CreateBar(tip, self.HealthBarMixin);
		
		if (self.CastBarMixin) then -- #test
			self.bars[#self.bars + 1] = self:CreateBar(tip, self.CastBarMixin);
		end
	end
	
	-- setup bars. initializes the anchoring position and color for each bar.
	local offsetY = TT_GTT_BARS_MARGIN_Y;
	
	frameParams.currentDisplayParams.extraPaddingBottomForBars = 0;
	
	for index, bar in ipairs(self.bars) do
		bar:ClearAllPoints();
		
		if (bar:GetVisibility(unitRecord)) then
			bar:SetPoint("BOTTOMLEFT", tip.NineSlice.Center, TT_ExtendedConfig.tipPaddingForGameTooltip.left + TT_GTT_BARS_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
			bar:SetPoint("BOTTOMRIGHT", tip.NineSlice.Center, -TT_ExtendedConfig.tipPaddingForGameTooltip.right + -TT_GTT_BARS_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
			
			bar:SetStatusBarColor(bar:GetColor(unitRecord));
			
			offsetY = offsetY + cfg.barHeight + TT_GTT_BARS_SPACING;
			
			frameParams.currentDisplayParams.extraPaddingBottomForBars = frameParams.currentDisplayParams.extraPaddingBottomForBars + cfg.barHeight + TT_GTT_BARS_SPACING;
			
			bar:Show();
		else
			bar:Hide();
		end
	end
end

-- creates a bar with the given mixins

-- config settings needs to be applied
local function barOnApplyConfig(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set texture and height of status bar
	self:SetStatusBarTexture(cfg.barTexture);
	self:GetStatusBarTexture():SetHorizTile(false); -- Az: 3.3.3 fix
	self:GetStatusBarTexture():SetVertTile(false);  -- Az: 3.3.3 fix
	self:SetHeight(cfg.barHeight);
	
	-- set font of status bar
	self.text:SetFont(cfg.barFontFace, cfg.barFontSize, cfg.barFontFlags);
end

-- format bar text
local function barSetFormattedBarValues(self, value, maxValue, valueType)
	local barText = self.text;
	
	if (valueType == "none") then
		barText:SetText("");
	elseif (valueType == "value") or (maxValue == 0) then -- maxValue should never be zero, but if it is, don't let it pass through to the "percent" value type, or there will be an error.
		barText:SetFormattedText("%s / %s", LibFroznFunctions:FormatNumber(value, true), LibFroznFunctions:FormatNumber(maxValue, true));
	elseif (valueType == "current") then
		barText:SetFormattedText("%s", LibFroznFunctions:FormatNumber(value, true));
	elseif (valueType == "full") then
		barText:SetFormattedText("%s / %s (%.0f%%)", LibFroznFunctions:FormatNumber(value, true), LibFroznFunctions:FormatNumber(maxValue, true), value / maxValue * 100);
	elseif (valueType == "deficit") then
		if (value ~= maxValue) then
			barText:SetFormattedText("-%s", LibFroznFunctions:FormatNumber(maxValue - value, true));
		else
			barText:SetText("");
		end
	elseif (valueType == "percent") then
		barText:SetFormattedText("%.0f%%", value / maxValue * 100);
	end
end

function ttBars:CreateBar(parent, tblMixin)
	local bar = CreateFrame("StatusBar",nil,parent);
	bar:Hide();
	
	-- bar:SetWidth(0); -- Az: As of patch 3.3.3, setting the initial size will somehow mess up the texture. Previously this initilization was needed to fix an anchoring issue.
	-- bar:SetHeight(0);
	
	bar.bg = bar:CreateTexture(nil, "BACKGROUND");
	bar.bg:SetColorTexture(0.3, 0.3, 0.3, 0.6);
	bar.bg:SetAllPoints();
	
	bar.text = bar:CreateFontString(nil, "ARTWORK");
	bar.text:SetPoint("CENTER");
	bar.text:SetTextColor(1, 1, 1);
	
	bar.SetFormattedBarValues = barSetFormattedBarValues;
	
	bar.OnApplyConfig = barOnApplyConfig;
	bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	
	return Mixin(bar, tblMixin);
end

----------------------------------------------------------------------------------------------------
--                                       Mixin: Health Bar                                        --
----------------------------------------------------------------------------------------------------

ttBars.HealthBarMixin = {};

-- get visibility of bar
function ttBars.HealthBarMixin:GetVisibility(unitRecord)
	return cfg.healthBar;
end

-- get color of bar
function ttBars.HealthBarMixin:GetColor(unitRecord)
	if (unitRecord.isPlayer) and (cfg.healthBarClassColor) then
		local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
		
		return classColor:GetRGBA();
	else
		return unpack(cfg.healthBarColor);
	end
end

-- get value parameters
function ttBars.HealthBarMixin:GetValueParams(unitRecord)
	local value, maxValue, valueType = unitRecord.health, unitRecord.healthMax, cfg.healthBarText;
	
	-- consider unit health from addon RealMobHealth
	if (RealMobHealth) then
		local rmhValue, rmhMaxValue = RealMobHealth.GetUnitHealth(unitRecord.id);
		
		if (rmhValue) and (rmhMaxValue) then
			value = rmhValue;
			maxValue = rmhMaxValue;
		end
	end
	
	return value, maxValue, valueType;
end

----------------------------------------------------------------------------------------------------
--                                        Mixin: Power Bar                                        --
----------------------------------------------------------------------------------------------------

ttBars.PowerBarMixin = {};

-- get visibility of bar
function ttBars.PowerBarMixin:GetVisibility(unitRecord)
	return (unitRecord.powerMax ~= 0) and (cfg.manaBar and unitRecord.powerType == 0 or cfg.powerBar and unitRecord.powerType ~= 0);
end

-- get color of bar
function ttBars.PowerBarMixin:GetColor(unitRecord)
	-- mana
	if (unitRecord.powerType == 0) then
		return unpack(cfg.manaBarColor);
	end
	
	-- other power types
	local powerColor = LibFroznFunctions:GetPowerColor(unitRecord.powerType, Enum.PowerType.Runes);
	
	return powerColor:GetRGBA();
end

-- get value parameters
function ttBars.PowerBarMixin:GetValueParams(unitRecord)
	-- verify unit is still using the same power type, if not, update the bar color.
	self:SetStatusBarColor(self:GetColor(unitRecord));
	
	local value, maxValue, valueType = unitRecord.power, unitRecord.powerMax, (unitRecord.powerType == 0 and cfg.manaBarText or cfg.powerBarText);
	
	return value, maxValue, valueType;
end

----------------------------------------------------------------------------------------------------
--                                       Mixin: Casting Bar                                       --
----------------------------------------------------------------------------------------------------

--[[ #test
local ttBars.CastBarMixin = {};

-- get visibility of bar
function ttBars.CastBarMixin:GetVisibility(unitRecord)
	if (UnitCastingInfo(unitRecord.id)) then
		self.castType = "cast";
	elseif (UnitCastingInfo(unitRecord.id)) then
		self.castType = "channel";
	else
		self.castType = nil;
	end
	return (self.castType ~= nil);
end

-- get color of bar
function ttBars.CastBarMixin:GetColor(unitRecord)
	return CastingBarFrame.startChannelColor:GetRGBA();
end

-- get value parameters
function ttBars.CastBarMixin:GetValueParams(unitRecord)
	local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible;
	local castID, notInterruptible, spellId;
	if (self.castType == "cast") then
		name, text, texture, startTimeMS, endTimeMS, isTradeSkill, notInterruptible = UnitCastingInfo(unitRecord.id);
	elseif (self.castType == "channel") then
		name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitChannelInfo(unitRecord.id);
	end

	if (not name) then
		return 0, 0, "percent"
	end

	local val = (GetTime() - startTimeMS / 1000);
	local max = (endTimeMS - startTimeMS) / 1000;
	local fmt = cfg.healthBarText;
	return val, max, fmt;
end
--]]
