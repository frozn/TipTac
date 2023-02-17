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
local ttBars = { bars = {} };
local bars = ttBars.bars;

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttBars, "Bars");

-- Constants
local BAR_MARGIN_X = ((LibFroznFunctions.isWoWFlavor.ClassicEra) or (LibFroznFunctions.isWoWFlavor.BCC) or (LibFroznFunctions.isWoWFlavor.WotLKC)) and 5 or 7;
local BAR_MARGIN_Y = ((LibFroznFunctions.isWoWFlavor.ClassicEra) or (LibFroznFunctions.isWoWFlavor.BCC) or (LibFroznFunctions.isWoWFlavor.WotLKC)) and 6 or 8;
local BAR_SPACING = 7;

local TT_GTT_MINIMUM_WIDTH_FOR_BARS = 110; -- minimum width for bars, so that numbers are not out of bounds

--------------------------------------------------------------------------------------------------------
--                                         Mixin: Health Bar                                          --
--------------------------------------------------------------------------------------------------------

local HealthBarMixin = {};

function HealthBarMixin:GetVisibility(unitRecord)
	return cfg.healthBar;
end

function HealthBarMixin:GetColor(unitRecord)
	if (unitRecord.isPlayer) and (cfg.healthBarClassColor) then
		local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5);
		return classColor:GetRGBA();
	else
		return unpack(cfg.healthBarColor);
	end
end

if (RealMobHealth) then
	local RMH = RealMobHealth;
	function HealthBarMixin:GetValueParams(unitRecord)
		local val, max = RMH.GetUnitHealth(unitRecord.id);
		if (not val) or (not max) then
			val = unitRecord.health;
			max = unitRecord.healthMax;
		end
		
		return val, max, cfg.healthBarText;
	end
else
	function HealthBarMixin:GetValueParams(unitRecord)
		local val = unitRecord.health;
		local max = unitRecord.healthMax;
		
		return val, max, cfg.healthBarText;
	end
end

--------------------------------------------------------------------------------------------------------
--                                          Mixin: Power Bar                                          --
--------------------------------------------------------------------------------------------------------

local PowerBarMixin = {};

function PowerBarMixin:GetVisibility(unitRecord)
	return (unitRecord.powerMax ~= 0) and (cfg.manaBar and unitRecord.powerType == 0 or cfg.powerBar and unitRecord.powerType ~= 0);
end

function PowerBarMixin:GetColor(unitRecord)
	if (unitRecord.powerType == 0) then
		return unpack(cfg.manaBarColor);
	end
	
	local powerColor = LibFroznFunctions:GetPowerColor(unitRecord.powerType, Enum.PowerType.Runes);
	
	return powerColor:GetRGBA();
end

function PowerBarMixin:GetValueParams(unitRecord)
	-- verify unit is still using the same power type, if not, update the bar color
	self:SetStatusBarColor(self:GetColor(unitRecord));
	
	local val = unitRecord.power;
	local max = unitRecord.powerMax;
	local fmt = (unitRecord.powerType == 0 and cfg.manaBarText) or (cfg.powerBarText);
	
	return val, max, fmt;
end

--------------------------------------------------------------------------------------------------------
--                                         Mixin: Casting Bar                                         --
--------------------------------------------------------------------------------------------------------

--[[
local CastBarMixin = {};

function CastBarMixin:GetVisibility(unitRecord)
	if (UnitCastingInfo(unitRecord.id)) then
		self.castType = "cast";
	elseif (UnitCastingInfo(unitRecord.id)) then
		self.castType = "channel";
	else
		self.castType = nil;
	end
	return (self.castType ~= nil);
end

function CastBarMixin:GetColor(unitRecord)
	return CastingBarFrame.startChannelColor:GetRGBA();
end

function CastBarMixin:GetValueParams(unitRecord)
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
--------------------------------------------------------------------------------------------------------
--                                       Bar Setup & Formatting                                       --
--------------------------------------------------------------------------------------------------------

-- Format Number Value -- kilo, mega, giga
local function FormatValue(val)
	if (not cfg.barsCondenseValues) or (val < 10000) then
		return tostring(floor(val));
	elseif (val < 1000000) then
		return ("%.1fk"):format(val / 1000);
	elseif (val < 1000000000) then
		return ("%.2fm"):format(val / 1000000);
	else
		return ("%.2fg"):format(val / 1000000000);
	end
end

-- Format Bar Text
local function SetFormattedBarValues(self,val,max,type)
	local fs = self.text;
	if (type == "none") then
		fs:SetText("");
	elseif (type == "value") or (max == 0) then -- max should never be zero, but if it is, dont let it pass through to the "percent" type, or there will be an error
		fs:SetFormattedText("%s / %s",FormatValue(val),FormatValue(max));
	elseif (type == "current") then
		fs:SetFormattedText("%s",FormatValue(val));
	elseif (type == "full") then
		fs:SetFormattedText("%s / %s (%.0f%%)",FormatValue(val),FormatValue(max),val / max * 100);
	elseif (type == "deficit") then
		if (val ~= max) then
			fs:SetFormattedText("-%s",FormatValue(max - val));
		else
			fs:SetText("");
		end
	elseif (type == "percent") then
		fs:SetFormattedText("%.0f%%",val / max * 100);
	end
end

-- Creates a bar with the given mixins
function ttBars:CreateBar(parent,tblMixin)
	local bar = CreateFrame("StatusBar",nil,parent);
	bar:Hide();

--	bar:SetWidth(0);	-- Az: As of patch 3.3.3, setting the initial size will somehow mess up the texture. Previously this initilization was needed to fix an anchoring issue.
--	bar:SetHeight(0);

	bar.bg = bar:CreateTexture(nil,"BACKGROUND");
	bar.bg:SetColorTexture(0.3,0.3,0.3,0.6);
	bar.bg:SetAllPoints();

	bar.text = bar:CreateFontString(nil,"ARTWORK");
	bar.text:SetPoint("CENTER");
	bar.text:SetTextColor(1,1,1);

	bar.SetFormattedBarValues = SetFormattedBarValues;

	return Mixin(bar,tblMixin);
end

-- setup bars. initializes the anchoring position and color for each bar.
function ttBars:SetupBars(TT_CacheForFrames, tip, unitRecord)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- setup bars
	local offsetY = BAR_MARGIN_Y;
	
	frameParams.currentDisplayParams.extraPaddingBottomForBars = 0;
	
	for index, bar in ipairs(bars) do
		bar:ClearAllPoints();
		
		if (bar:GetVisibility(unitRecord)) then
			bar:SetPoint("BOTTOMLEFT", tip.NineSlice.Center, TT_ExtendedConfig.tipPaddingForGameTooltip.left + BAR_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
			bar:SetPoint("BOTTOMRIGHT", tip.NineSlice.Center, -TT_ExtendedConfig.tipPaddingForGameTooltip.right + -BAR_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
			
			bar:SetStatusBarColor(bar:GetColor(unitRecord));
			
			offsetY = offsetY + cfg.barHeight + BAR_SPACING;
			
			frameParams.currentDisplayParams.extraPaddingBottomForBars = frameParams.currentDisplayParams.extraPaddingBottomForBars + cfg.barHeight + BAR_SPACING;
			
			bar:Show();
		else
			bar:Hide();
		end
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttBars:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;

	-- Make two bars: Health & Power
	local tip = GameTooltip;
	bars[#bars + 1] = self:CreateBar(tip,PowerBarMixin);
	bars[#bars + 1] = self:CreateBar(tip,HealthBarMixin);
	if (CastBarMixin) then
		bars[#bars + 1] = self:CreateBar(tip,CastBarMixin);
	end
end

function ttBars:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	GameTooltipStatusBar:SetStatusBarTexture(cfg.barTexture);
	GameTooltipStatusBar:GetStatusBarTexture():SetHorizTile(false);	-- Az: 3.3.3 fix
	GameTooltipStatusBar:GetStatusBarTexture():SetVertTile(false);	-- Az: 3.3.3 fix
	GameTooltipStatusBar:SetHeight(cfg.barHeight);

	for _, bar in ipairs(bars) do
		-- set default texture if texture in config is not valid
		if (not LibFroznFunctions:TextureExists(cfg.barTexture)) then
			cfg.barTexture = nil;
			tt:AddMessageToChatFrame(MOD_NAME .. ": {error:No valid texture set in option tab {highlight:Bars}. Switching to default texture.}");
		end
		
		-- set texture
		bar:SetStatusBarTexture(cfg.barTexture);
		bar:GetStatusBarTexture():SetHorizTile(false);	-- Az: 3.3.3 fix
		bar:GetStatusBarTexture():SetVertTile(false);	-- Az: 3.3.3 fix
		bar:SetHeight(cfg.barHeight);
		
		-- set default font if font in config is not valid
		if (not LibFroznFunctions:FontExists(cfg.barFontFace)) then
			cfg.barFontFace = nil;
			tt:AddMessageToChatFrame(MOD_NAME .. ": {error:No valid Font set in option tab {highlight:Bars}. Switching to default Font.}");
		end
		
		-- set font
		bar.text:SetFont(cfg.barFontFace, cfg.barFontSize, cfg.barFontFlags);
	end
end

function ttBars:OnTipPreStyle(TT_CacheForFrames, tip, first)
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	-- for the first time styling, we want to initialize the bars
	if (first) then
		self:SetupBars(TT_CacheForFrames, tip, unitRecord);

		-- Hide GTT Status bar, we have our own, which is prettier!
		if (cfg.hideDefaultBar) then
			GameTooltipStatusBar:Hide();
		end
	end

	-- update each shown bar
	for _, bar in ipairs(bars) do
		if (bar:IsShown()) then
			local val, max, fmt = bar:GetValueParams(unitRecord);
			
			bar:SetMinMaxValues(0,max);
			bar:SetValue(val);
			bar:SetFormattedBarValues(val,max,fmt);
		end
	end
end

function ttBars:OnTipResize(TT_CacheForFrames, tip, first)
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	-- set minimum width for bars, so that numbers are not out of bounds
	for index, bar in ipairs(bars) do
		if (bar:GetVisibility(unitRecord)) then
			if (tip:GetWidth() < TT_GTT_MINIMUM_WIDTH_FOR_BARS) then
				tip:SetMinimumWidth(TT_GTT_MINIMUM_WIDTH_FOR_BARS);
			end
			
			break;
		end
	end
end

function ttBars:OnTipPostResetCurrentDisplayParams(TT_CacheForFrames, tip)
	for _, bar in ipairs(bars) do
		if (bar:GetParent() == tip) then
			bar:Hide();
		end
	end
end