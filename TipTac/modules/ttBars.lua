-----------------------------------------------------------------------
-- TipTac - Bars
--
-- Shows the health, mana/power and cast bar of the target unit.
--

-- create addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- register with TipTac core addon
local tt = _G[MOD_NAME];
local ttBars = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttBars, MOD_NAME .. " - Bars Module");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- constants
local TT_GTT_BARS_MARGIN_X = 11 + LibFroznFunctions.hasWoWFlavor.barMarginAdjustment;
local TT_GTT_BARS_MARGIN_Y = 11 + LibFroznFunctions.hasWoWFlavor.barMarginAdjustment;
local TT_GTT_BARS_SPACING = 7;
local TT_GTT_BARS_TEXT_OFFSET_X = 8;
local TT_GTT_BARS_FADING_TIME = 0.5; -- fading time for bars in seconds

-- colors
local TT_COLOR = {
	text = {
		default = HIGHLIGHT_FONT_COLOR -- white
	}
};

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

-- config settings need to be applied
function ttBars:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set default font if font in config is not valid
	if (not LibFroznFunctions:FontExists(cfg.barFontFace)) then
		cfg.barFontFace = nil;
		tt:AddMessageToChatFrame("{caption:" .. MOD_NAME .. "}: {error:No valid Font set in option tab {highlight:Bars}. Switching to default Font.}");
	end
	
	-- set default texture if texture in config is not valid
	if (not LibFroznFunctions:TextureExists(cfg.barTexture)) then
		cfg.barTexture = nil;
		tt:AddMessageToChatFrame("{caption:" .. MOD_NAME .. "}: {error:No valid texture set in option tab {highlight:Bars}. Switching to default texture.}");
	end
	
	-- set texture and height of GameTooltip's standard status bar
	local statusBarTexture = GameTooltipStatusBar:GetStatusBarTexture();
	
	if (not statusBarTexture) then -- repeatedly calling SetStatusBarTexture() causes flickering of bar. repeatedly calling SetTexture() on already available bar texture instead works fine.
		GameTooltipStatusBar:SetStatusBarTexture(cfg.barTexture);
		statusBarTexture = GameTooltipStatusBar:GetStatusBarTexture();
	else
		statusBarTexture:SetTexture(cfg.barTexture);
	end
	
	statusBarTexture:SetHorizTile(false); -- Az: 3.3.3 fix
	statusBarTexture:SetVertTile(false);  -- Az: 3.3.3 fix
	GameTooltipStatusBar:SetHeight(cfg.barHeight);
	
	-- set texture, height and font of bars
	for _, barsPool in pairs(self.barPools) do
		for bar, _ in barsPool:EnumerateActive() do
			bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
		end
	end
	
	-- setup active tip's bars
	local tipsProcessed = {};
	
	for _, barsPool in pairs(self.barPools) do
		for bar, _ in barsPool:EnumerateActive() do
			local tip = bar:GetParent();
			
			if (not tipsProcessed[tip]) then
				-- register/unregister unit events
				if (cfg.enableBars) and (cfg.castBar) then
					self:RegisterUnitEvents(tip);
				else
					self:UnregisterUnitEvents(tip);
				end
				
				-- update unit tip's bars
				self:UpdateUnitTipsBars(tip);
				
				tipsProcessed[tip] = true;
			end
		end
	end
end

-- tooltip's current display parameters has to be set
function ttBars:OnTipSetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams, tipContent)
	-- unregister unit events
	if (tip:IsForbidden()) or (not tip:IsShown()) then -- unregister unit events only if tip isn't visible any more. needed to finish fading out the cast bar.
		self:UnregisterUnitEvents(tip);
	end
	
	-- register unit events
	self:RegisterUnitEvents(tip);
end

-- before unit tooltip is being styled
function ttBars:OnUnitTipPreStyle(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- hide GameTooltip's standard status bar if needed
	if (cfg.hideDefaultBar) and (first) then
		GameTooltipStatusBar:Hide();
	end
	
	-- setup unit tip's bars
	self:SetupUnitTipsBars(tip);
end

-- unit tooltip is being resized

-- consider minimum width for bars, so that numbers are not out of bounds.
local function setExtraPaddingRightForMinimumWidth(self, TT_CacheForFrames, tip, currentDisplayParams, first)
	if (not cfg.barEnableTipMinimumWidth) then
		currentDisplayParams.extraPaddingRightForMinimumWidth = nil;
		return;
	end
	
	local breakFor = false;
	
	for _, barsPool in pairs(self.barPools) do
		for bar, _ in barsPool:EnumerateActive() do
			if (bar:GetParent() == tip) and (bar:IsShown()) then
				local barWidth = bar:GetWidth();
				
				if (barWidth > 0) then -- bar width of health bar is 0 after fading out the cast bar
					local newExtraPaddingRightForMinimumWidth = cfg.barTipMinimumWidth - barWidth + (currentDisplayParams.extraPaddingRightForMinimumWidth or 0);
					
					if (newExtraPaddingRightForMinimumWidth <= 0) then
						newExtraPaddingRightForMinimumWidth = nil;
					end
					
					local tipEffectiveScale = tip:GetEffectiveScale();
					
					if (not newExtraPaddingRightForMinimumWidth) or (not currentDisplayParams.extraPaddingRightForMinimumWidth) or (math.abs((newExtraPaddingRightForMinimumWidth - currentDisplayParams.extraPaddingRightForMinimumWidth) * tipEffectiveScale) > 0.5) then
						currentDisplayParams.extraPaddingRightForMinimumWidth = newExtraPaddingRightForMinimumWidth;
					end
				end
				
				breakFor = true;
				break;
			end
		end
		
		if (breakFor) then
			break;
		end
	end
end

function ttBars:OnUnitTipResize(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- consider minimum width for bars, so that numbers are not out of bounds.
	setExtraPaddingRightForMinimumWidth(self, TT_CacheForFrames, tip, currentDisplayParams, first);
end

-- tooltip has been resized
function ttBars:OnTipResized(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- consider minimum width for bars, so that numbers are not out of bounds.
	setExtraPaddingRightForMinimumWidth(self, TT_CacheForFrames, tip, currentDisplayParams, first);
end

-- tooltip's current display parameters has to be reset
function ttBars:OnTipResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- unregister unit events
	if (tip:IsForbidden()) or (not tip:IsShown()) then -- unregister unit events only if tip isn't visible any more. needed to finish fading out the cast bar.
		self:UnregisterUnitEvents(tip);
	end
	
	-- hide unit tip's bars
	self:HideUnitTipsBars(tip);
end

----------------------------------------------------------------------------------------------------
--                                          Setup Module                                          --
----------------------------------------------------------------------------------------------------

-- setup unit tip's bars
function ttBars:SetupUnitTipsBars(tip)
	-- hide unit tip's bars
	self:HideUnitTipsBars(tip);
	
	-- check if bars are enabled
	if (not cfg.enableBars) then
		return;
	end
	
	-- get frame and current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- no unit record
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- display tip's bars (in opposite vertical direction)
	currentDisplayParams.extraPaddingBottomForBars = 0;
	
	local offsetY = TT_GTT_BARS_MARGIN_Y;
	
	if (cfg.castBar) then
		offsetY = self:DisplayUnitTipsBar(self.barPools.castBarsPool, frameParams, tip, unitRecord, offsetY);
	end
	
	if (cfg.manaBar) or (cfg.powerBar) then
		offsetY = self:DisplayUnitTipsBar(self.barPools.powerBarsPool, frameParams, tip, unitRecord, offsetY);
	end
	
	if (cfg.healthBar) then
		offsetY = self:DisplayUnitTipsBar(self.barPools.healthBarsPool, frameParams, tip, unitRecord, offsetY);
	end
end

-- display unit tip's bar
function ttBars:DisplayUnitTipsBar(barsPool, frameParams, tip, unitRecord, offsetY)
	-- set anchoring position and color for each bar and update its value
	local bar = barsPool:Acquire();
	
	bar:SetParent(tip);
	bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	
	local newOffsetY = offsetY;
	
	if (bar:GetVisibility(tip, unitRecord)) then
		-- initialize anchoring position and color
		bar:ClearAllPoints();
		
		bar:SetPoint("BOTTOMLEFT", tip, TT_ExtendedConfig.tipPaddingForGameTooltip.left + TT_GTT_BARS_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
		bar:SetPoint("BOTTOMRIGHT", tip, -TT_ExtendedConfig.tipPaddingForGameTooltip.right + -TT_GTT_BARS_MARGIN_X, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom + offsetY);
		
		newOffsetY = newOffsetY + cfg.barHeight + TT_GTT_BARS_SPACING;
		
		frameParams.currentDisplayParams.extraPaddingBottomForBars = frameParams.currentDisplayParams.extraPaddingBottomForBars + cfg.barHeight + TT_GTT_BARS_SPACING;
		
		-- update value
		bar:UpdateValue(tip, unitRecord);
		
		bar:Show();
	end
	
	return newOffsetY;
end

-- create bar with the given mixins

-- bar initialization function
local function barInitFunc(bar, tblMixin)
	-- bar:SetWidth(0); -- Az: As of patch 3.3.3, setting the initial size will somehow mess up the texture. Previously this initilization was needed to fix an anchoring issue.
	-- bar:SetHeight(0);
	
	bar.bg = bar:CreateTexture(nil, "BACKGROUND");
	bar.bg:SetColorTexture(0.3, 0.3, 0.3, 0.6);
	bar.bg:SetAllPoints();
	
	bar.text = bar:CreateFontString(nil, "ARTWORK");
	bar.text:SetTextColor(TT_COLOR.text.default:GetRGBA());
	bar.text:SetPoint("TOPLEFT", TT_GTT_BARS_TEXT_OFFSET_X, 0);
	bar.text:SetPoint("BOTTOMRIGHT", -TT_GTT_BARS_TEXT_OFFSET_X, 0);
	bar.text:SetWordWrap(false);
	
	-- config settings need to be applied
	function bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- set texture and height of bar
		local statusBarTexture = self:GetStatusBarTexture();
		
		if (not statusBarTexture) then -- repeatedly calling SetStatusBarTexture() causes flickering of bar. repeatedly calling SetTexture() on already available bar texture instead works fine.
			self:SetStatusBarTexture(cfg.barTexture);
			statusBarTexture = self:GetStatusBarTexture();
		else
			statusBarTexture:SetTexture(cfg.barTexture);
		end
		
		statusBarTexture:SetHorizTile(false); -- Az: 3.3.3 fix
		statusBarTexture:SetVertTile(false);  -- Az: 3.3.3 fix
		self:SetHeight(cfg.barHeight);
		
		-- set font of bar
		self.text:SetFont(cfg.barFontFace, cfg.barFontSize, cfg.barFontFlags);
	end
	
	bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	
	Mixin(bar, tblMixin);
end

-- update bar value
local function barUpdateValueFunc(bar)
	local tip = bar:GetParent();
	
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- no unit record
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- get frame for unit events
	local frameForUnitEvents = ttBars:GetFrameForUnitEvents(tip);
	
	-- no update value of bar needed if there is no active spell cast
	if (not frameForUnitEvents) or (not frameForUnitEvents:IsActiveSpellCast()) then
		return;
	end
	
	-- update value or hide bar
	if (bar:GetVisibility(tip, unitRecord)) then
		bar:UpdateValue(tip, unitRecord);
	else
		ttBars:UpdateUnitTipsBars(tip);
	end
end

ttBars.barPools = {
	healthBarsPool = CreateFramePool("StatusBar", nil, nil, nil, false, function(bar)
		barInitFunc(bar, ttBars.HealthBarMixin);
	end),
	
	powerBarsPool = CreateFramePool("StatusBar", nil, nil, nil, false, function(bar)
		barInitFunc(bar, ttBars.PowerBarMixin);
	end),
	
	castBarsPool = CreateFramePool("StatusBar", nil, nil, nil, false, function(bar)
		barInitFunc(bar, ttBars.CastBarMixin);
		
		-- add spark
		bar.spark = bar:CreateTexture(nil, "ARTWORK");
		bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
		bar.spark:SetBlendMode("ADD");
		bar.spark:SetWidth(16);
		
		-- config settings needs to be applied
		local oldBarOnApplyConfig = bar.OnApplyConfig;
		
		function bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
			oldBarOnApplyConfig(self, TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- set color and height of spark
			self.spark:SetVertexColor(unpack(cfg.castBarSparkColor));
			self.spark:SetHeight(cfg.barHeight * 2);
		end
		
		bar:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
		
		-- update bar value
		bar:HookScript("OnUpdate", barUpdateValueFunc);
	end)
};

-- get frame for unit events
function ttBars:GetFrameForUnitEvents(tip)
	for frameForUnitEvents, _ in self.unitEventsPool:EnumerateActive() do
		local _tip = frameForUnitEvents:GetParent();
		
		if (_tip == tip) then
			return frameForUnitEvents;
		end
	end
end

-- check if active spell cast is available
function ttBars:IsActiveSpellCast(unitCastingSpell)
	return (unitCastingSpell and ((unitCastingSpell.isCasting) or (unitCastingSpell.isChanneling) or (unitCastingSpell.isCharging)) and
		((LibFroznFunctions:IsSecretValue(unitCastingSpell.spellID)) or (unitCastingSpell.startTime) and (unitCastingSpell.endTime) and (unitCastingSpell.spellID)));
end

-- update unit tip's bars
function ttBars:UpdateUnitTipsBars(tip)
	-- setup unit tip's bars
	self:SetupUnitTipsBars(tip);
	
	-- set padding to tip
	tt:SetPaddingToTip(tip);
end

-- hide unit tip's bars
function ttBars:HideUnitTipsBars(tip)
	for _, barsPool in pairs(self.barPools) do
		for bar, _ in barsPool:EnumerateActive() do
			if (bar:GetParent() == tip) then
				barsPool:Release(bar);
			end
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                          Unit Events                                           --
----------------------------------------------------------------------------------------------------

-- config unit events
local TT_ConfigUnitEvents = {
	UNIT_SPELLCAST_START = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_CHANNEL_START = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_EMPOWER_START = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_DELAYED = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_CHANNEL_UPDATE = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_EMPOWER_UPDATE = {
		startCast = true,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_INTERRUPTIBLE = {
		startCast = nil,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_NOT_INTERRUPTIBLE = {
		startCast = nil,
		interruptedOrFailed = nil,
		fadeOutEnabled = nil,
		fadeOutGenericStopEvent = nil,
		fadeOutCastSuccess = nil
	},
	UNIT_SPELLCAST_INTERRUPTED = {
		startCast = nil,
		interruptedOrFailed = true,
		fadeOutEnabled = true,
		fadeOutGenericStopEvent = false,
		fadeOutCastSuccess = false
	},
	UNIT_SPELLCAST_FAILED = {
		startCast = nil,
		interruptedOrFailed = true,
		fadeOutEnabled = true,
		fadeOutGenericStopEvent = false,
		fadeOutCastSuccess = false
	},
	UNIT_SPELLCAST_STOP = {
		startCast = nil,
		interruptedOrFailed = nil,
		fadeOutEnabled = true,
		fadeOutGenericStopEvent = true,
		fadeOutCastSuccess = true
	},
	UNIT_SPELLCAST_CHANNEL_STOP = {
		startCast = nil,
		interruptedOrFailed = nil,
		fadeOutEnabled = true,
		fadeOutGenericStopEvent = true,
		fadeOutCastSuccess = true
	},
	UNIT_SPELLCAST_EMPOWER_STOP = {
		startCast = nil,
		interruptedOrFailed = nil,
		fadeOutEnabled = true,
		fadeOutGenericStopEvent = true,
		fadeOutCastSuccess = true
	}
};

-- create frame for unit events
ttBars.unitEventsPool = CreateFramePool("Frame", nil, nil, nil, false, function(frameForUnitEvents)
	-- try enabling fading out after spell cast
	function frameForUnitEvents:TryEnablingFadingOut(unitEventConfig, spellID)
		-- check if fading out is already enabled
		if (self:IsFadingOut(unitEventConfig)) then
			return;
		end

		-- no fading out if there is no active spell cast, different spell or interrupted/failed channeling spell
		if (unitEventConfig.fadeOutEnabled) and ((not self:IsActiveSpellCast()) or ((not LibFroznFunctions:IsSecretValue(self.unitCastingSpell.spellID)) and (self.unitCastingSpell.spellID ~= spellID)) or (unitEventConfig.interruptedOrFailed and self.unitCastingSpell.isChanneling)) then
			return;
		end
		
		-- enable fading out after spell cast
		self.castBarFadeOutEnabled = unitEventConfig.fadeOutEnabled;
		self.castBarFadeOutTimestamp = (unitEventConfig.fadeOutEnabled and GetTime() or nil);
		self.castBarFadeOutGenericStopEvent = unitEventConfig.fadeOutGenericStopEvent;
		self.castBarFadeOutCastSuccess = unitEventConfig.fadeOutCastSuccess;
	end
	
	-- check if fading out is already enabled
	function frameForUnitEvents:IsFadingOut(unitEventConfig)
		return (unitEventConfig.fadeOutEnabled) and (self.castBarFadeOutEnabled) and ((unitEventConfig.fadeOutGenericStopEvent == self.castBarFadeOutGenericStopEvent) or (unitEventConfig.fadeOutGenericStopEvent == true) and (self.castBarFadeOutGenericStopEvent == false));
	end
	
	-- set active spell cast
	function frameForUnitEvents:SetActiveSpellCast(unitCastingSpell, unitRecord)
		self.unitCastingSpell = unitCastingSpell;
		self.unitCastingSpell.endTime = (frameForUnitEvents.unitCastingSpell.endTime) and (frameForUnitEvents.unitCastingSpell.endTime + (self.unitCastingSpell.isCharging and (GetUnitEmpowerHoldAtMaxTime(unitRecord.id) * 1000) or 0)) or nil;
	end
	
	-- check if active spell cast is available
	function frameForUnitEvents:IsActiveSpellCast()
		return ttBars:IsActiveSpellCast(self.unitCastingSpell);
	end
	
	-- disable fading out
	function frameForUnitEvents:DisableFadingOut()
		-- disable fading out by resetting cast bar data
		self:ResetCastBarData();
	end
	
	-- reset cast bar data
	function frameForUnitEvents:ResetCastBarData()
		self.unitCastingSpell = nil;
		
		self.castBarFadeOutEnabled = nil;
		self.castBarFadeOutTimestamp = nil;
		self.castBarFadeOutGenericStopCast = nil;
		self.castBarFadeOutCastSuccess = nil;
	end
	
	-- register events
	frameForUnitEvents:SetScript("OnEvent", function(self, event, ...)
		-- no valid unit event config
		local unitEventConfig = TT_ConfigUnitEvents[event];
		
		if (not unitEventConfig) then
			return;
		end
		
		-- reset cast bar data if spell cast is started
		if (unitEventConfig.startCast) then
			self:ResetCastBarData();
		end
		
		-- try enabling fading out after spell cast
		local spellID = select(3, ...);
		
		self:TryEnablingFadingOut(unitEventConfig, spellID);
		
		-- update unit tip's bars
		local tip = self:GetParent();
		
		ttBars:UpdateUnitTipsBars(tip);
	end);
end);

-- register unit events
function ttBars:RegisterUnitEvents(tip)
	-- register unit events only needed if cast bar is enabled
	if (not cfg.enableBars) or (not cfg.castBar) then
		return;
	end
	
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- no unit record
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- get frame for unit events
	local frameForUnitEvents = self:GetFrameForUnitEvents(tip);
	
	if (not frameForUnitEvents) then
		frameForUnitEvents = self.unitEventsPool:Acquire();
		
		frameForUnitEvents:SetParent(tip);
	end
	
	-- register unit events
	if (not frameForUnitEvents.unitEventsHooked) and (unitRecord ~= LFF_UNIT_RECORD.SecretValue) then
		for unitEvent, unitEventConfig in pairs(TT_ConfigUnitEvents) do
			LibFroznFunctions:RegisterUnitEventIfExists(frameForUnitEvents, unitEvent, unitRecord.id);
		end
		
		frameForUnitEvents.unitEventsHooked = true;
	end
end

-- unregister unit events
function ttBars:UnregisterUnitEvents(tip)
	-- get frame for unit events
	local frameForUnitEvents = self:GetFrameForUnitEvents(tip);
	
	if (not frameForUnitEvents) then
		return;
	end
	
	-- unregister unit events
	if (frameForUnitEvents.unitEventsHooked) then
		for unitEvent, unitEventConfig in pairs(TT_ConfigUnitEvents) do
			LibFroznFunctions:UnregisterEventIfExists(frameForUnitEvents, unitEvent);
		end
	end
	
	frameForUnitEvents.unitEventsHooked = nil;
	
	-- reset cast bar data
	frameForUnitEvents:ResetCastBarData();
	
	-- release frame for unit events
	self.unitEventsPool:Release(frameForUnitEvents);
end

----------------------------------------------------------------------------------------------------
--                                  Helper Functions for Mixins                                   --
----------------------------------------------------------------------------------------------------

-- set formatted bar values
--
-- @param self                                 bar
-- @param valueParams                          value parameters
--          .valueType                           value type
--          .value                               value
--          .maxValue                            max value
--          .valueIsSecretValue                  true if value is a secret value, false otherwise.
--          .valuePercentIfValueIsSecretValue    value percent if value is a secret value
--          .valueMissingIfValueIsSecretValue    value missing if value is a secret value
local function barSetFormattedBarValues(self, valueParams)
	local barText = self.text;
	
	if (valueParams.valueType == "none") then
		barText:SetText("");
	elseif (valueParams.valueType == "value") or (not valueParams.valueIsSecretValue) and (valueParams.maxValue == 0) then -- maxValue should never be zero, but if it is, don't let it pass through to the "percent" value type, or there will be an error.
		barText:SetFormattedText("%s / %s",
			LibFroznFunctions:FormatNumber(valueParams.value, cfg.barsCondenseValues, valueParams.valueIsSecretValue),
			LibFroznFunctions:FormatNumber(valueParams.maxValue, cfg.barsCondenseValues, valueParams.valueIsSecretValue)
		);
	elseif (valueParams.valueType == "current") then
		barText:SetFormattedText("%s", LibFroznFunctions:FormatNumber(valueParams.value, cfg.barsCondenseValues, valueParams.valueIsSecretValue));
	elseif (valueParams.valueType == "full") then
		barText:SetFormattedText("%s / %s (%.0f%%)",
			LibFroznFunctions:FormatNumber(valueParams.value, cfg.barsCondenseValues, valueParams.valueIsSecretValue),
			LibFroznFunctions:FormatNumber(valueParams.maxValue, cfg.barsCondenseValues, valueParams.valueIsSecretValue),
			valueParams.valueIsSecretValue and valueParams.valuePercentIfValueIsSecretValue or (valueParams.value / valueParams.maxValue * 100)
		);
	elseif (valueParams.valueType == "deficit") then
		if (valueParams.valueIsSecretValue) then
			barText:SetFormattedText("-%s", valueParams.valueMissingIfValueIsSecretValue);
		else
			if (valueParams.valueIsSecretValue) or (valueParams.value ~= valueParams.maxValue) then
				barText:SetFormattedText("-%s", LibFroznFunctions:FormatNumber(valueParams.valueIsSecretValue and valueParams.valueMissingIfValueIsSecretValue or (valueParams.maxValue - valueParams.value), cfg.barsCondenseValues, valueParams.valueIsSecretValue));
			else
				barText:SetText("");
			end
		end
	elseif (valueParams.valueType == "percent") then
		barText:SetFormattedText("%.0f%%", valueParams.valueIsSecretValue and valueParams.valuePercentIfValueIsSecretValue or (valueParams.value / valueParams.maxValue * 100));
	end
end

----------------------------------------------------------------------------------------------------
--                                       Mixin: Health Bar                                        --
----------------------------------------------------------------------------------------------------

ttBars.HealthBarMixin = {};

-- get visibility of bar
function ttBars.HealthBarMixin:GetVisibility(tip, unitRecord)
	return cfg.healthBar and (unitRecord ~= LFF_UNIT_RECORD.SecretValue);
end

-- get color of bar
function ttBars.HealthBarMixin:GetColor(tip, unitRecord)
	if (unitRecord ~= LFF_UNIT_RECORD.SecretValue) and (unitRecord.isPlayer) and (cfg.healthBarClassColor) then
		local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
		
		return classColor:GetRGBA();
	else
		return unpack(cfg.healthBarColor);
	end
end

-- update value
function ttBars.HealthBarMixin:UpdateValue(tip, unitRecord)
	self:SetStatusBarColor(self:GetColor(tip, unitRecord));
	
	if (unitRecord == LFF_UNIT_RECORD.SecretValue) then
		return;
	end
	
	local valueParams = {
		valueType = cfg.healthBarText,
		value = unitRecord.health,
		maxValue = unitRecord.healthMax,
		valueIsSecretValue = unitRecord.healthIsSecretValue,
		valuePercentIfValueIsSecretValue = unitRecord.healthPercentIfHealthIsSecretValue,
		valueMissingIfValueIsSecretValue = unitRecord.healthMissingIfHealthIsSecretValue
	};
	
	if (valueParams.value) then
		self:SetMinMaxValues(0, valueParams.maxValue);
		self:SetValue(valueParams.value);
		self:SetFormattedBarValues(valueParams);
	end
end

-- set formatted bar values
ttBars.HealthBarMixin.SetFormattedBarValues = barSetFormattedBarValues;

----------------------------------------------------------------------------------------------------
--                                        Mixin: Power Bar                                        --
----------------------------------------------------------------------------------------------------

ttBars.PowerBarMixin = {};

-- get visibility of bar
function ttBars.PowerBarMixin:GetVisibility(tip, unitRecord)
	return (unitRecord ~= LFF_UNIT_RECORD.SecretValue) and ((unitRecord.powerIsSecretValue) or (unitRecord.powerMax ~= 0)) and (cfg.manaBar and unitRecord.powerType == 0 or cfg.powerBar and unitRecord.powerType ~= 0);
end

-- get color of bar
function ttBars.PowerBarMixin:GetColor(tip, unitRecord)
	-- mana
	if (unitRecord.powerType == 0) then
		return unpack(cfg.manaBarColor);
	end
	
	-- other power types
	local powerColor = LibFroznFunctions:GetPowerColor(unitRecord.powerType, Enum.PowerType.Runes);
	
	return powerColor:GetRGBA();
end

-- update value
function ttBars.PowerBarMixin:UpdateValue(tip, unitRecord)
	self:SetStatusBarColor(self:GetColor(tip, unitRecord));
	
	if (unitRecord == LFF_UNIT_RECORD.SecretValue) then
		return;
	end
	
	local valueParams = {
		valueType = (unitRecord.powerType == 0 and cfg.manaBarText or cfg.powerBarText),
		value = unitRecord.power,
		maxValue = unitRecord.powerMax,
		valueIsSecretValue = unitRecord.powerIsSecretValue,
		valuePercentIfValueIsSecretValue = unitRecord.powerPercentIfPowerIsSecretValue,
		valueMissingIfValueIsSecretValue = unitRecord.powerMissingIfPowerIsSecretValue
	};
	
	if (valueParams.value) then
		self:SetMinMaxValues(0, valueParams.maxValue);
		self:SetValue(valueParams.value);
		self:SetFormattedBarValues(valueParams);
	end
end

-- set formatted bar values
ttBars.PowerBarMixin.SetFormattedBarValues = barSetFormattedBarValues;

----------------------------------------------------------------------------------------------------
--                                       Mixin: Casting Bar                                       --
----------------------------------------------------------------------------------------------------

ttBars.CastBarMixin = {};

-- get visibility of bar
function ttBars.CastBarMixin:GetVisibility(tip, unitRecord)
	-- get frame for unit events
	local frameForUnitEvents = ttBars:GetFrameForUnitEvents(tip);
	
	-- get visibility of bar if fade out is enabled
	if (frameForUnitEvents) and (frameForUnitEvents.castBarFadeOutEnabled) then
		local fadingOut = ((frameForUnitEvents.castBarFadeOutTimestamp - GetTime() + TT_GTT_BARS_FADING_TIME) > 0);
		
		if (not fadingOut) then
			-- disable fading out
			frameForUnitEvents:DisableFadingOut();
		end
		
		return (fadingOut or cfg.castBarAlwaysShow);
	end
	
	-- get visibility of bar if there is an active spell cast
	if (frameForUnitEvents) and (frameForUnitEvents:IsActiveSpellCast()) then
		-- check if end time has been reached without stop event
		if (frameForUnitEvents.unitCastingSpell.endTime) then
			if (frameForUnitEvents.unitCastingSpell.endTime <= GetTime()) then
				-- try enabling fading out after spell cast
				frameForUnitEvents:TryEnablingFadingOut({
					fadeOutEnabled = true,
					fadeOutGenericStopEvent = true,
					fadeOutCastSuccess = true
				}, frameForUnitEvents.unitCastingSpell.spellID);
			end
			
			return true;
		end
	end
	
	-- get information about the new spell currently being cast/channeled
	local unitCastingSpell = (unitRecord ~= LFF_UNIT_RECORD.SecretValue) and LibFroznFunctions:GetUnitCastingSpell(unitRecord.id);
	
	if (not ttBars:IsActiveSpellCast(unitCastingSpell)) then
		return cfg.castBarAlwaysShow;
	end
	
	if (frameForUnitEvents) then
		frameForUnitEvents:SetActiveSpellCast(unitCastingSpell, unitRecord);
	end
	
	return true;
end

-- get color of bar
function ttBars.CastBarMixin:GetColor(tip, unitRecord)
	-- get frame for unit events
	local frameForUnitEvents = ttBars:GetFrameForUnitEvents(tip);
	
	-- get color of bar if fade out is enabled
	if (frameForUnitEvents) and (frameForUnitEvents.castBarFadeOutEnabled) then
		return unpack(frameForUnitEvents.castBarFadeOutCastSuccess and cfg.castBarCompleteColor or cfg.castBarFailColor);
	end
	
	-- get color of bar if there is an active spell cast
	if (frameForUnitEvents) and (frameForUnitEvents:IsActiveSpellCast()) then
		return unpack(frameForUnitEvents.unitCastingSpell.isCharging and cfg.castBarChargingColor or (frameForUnitEvents.unitCastingSpell.isChanneling and cfg.castBarChannelingColor) or cfg.castBarCastingColor);
	end
	
	return unpack(cfg.castBarCastingColor);
end

-- update value
function ttBars.CastBarMixin:UpdateValue(tip, unitRecord)
	self:SetStatusBarColor(self:GetColor(tip, unitRecord));
	
	-- get frame for unit events
	local frameForUnitEvents = ttBars:GetFrameForUnitEvents(tip);
	
	-- set value of bar if fade out is enabled
	if (frameForUnitEvents) and (frameForUnitEvents.castBarFadeOutEnabled) then
		local minValue, maxValue = self:GetMinMaxValues();
		
		self:SetValue(frameForUnitEvents.unitCastingSpell.isChanneling and minValue or maxValue);
		self.spark:Hide();
		
		return;
	end
	
	-- don't set value of bar if there is no active spell cast
	if (not frameForUnitEvents) or (not frameForUnitEvents:IsActiveSpellCast()) then
		if (cfg.castBarAlwaysShow) then
			self:SetMinMaxValues(0, 1);
			self:SetValue(0);
			self.text:SetText("");
			self.spark:Hide();
		end
		
		return;
	end
	
	-- set value of bar if there is an active spell cast
	local value, maxValue;
	
	if (frameForUnitEvents.unitCastingSpell.startTime) and (frameForUnitEvents.unitCastingSpell.endTime) then
		value, maxValue =
			frameForUnitEvents.unitCastingSpell.isChanneling and (frameForUnitEvents.unitCastingSpell.endTime - GetTime()) or (GetTime() - frameForUnitEvents.unitCastingSpell.startTime),
			frameForUnitEvents.unitCastingSpell.endTime - frameForUnitEvents.unitCastingSpell.startTime;
	end
	
	local text = LibFroznFunctions:CreatePushArray();
	local spacer;
	
	if (not LibFroznFunctions:IsSecretValue(frameForUnitEvents.unitCastingSpell.notInterruptible)) and (frameForUnitEvents.unitCastingSpell.notInterruptible) then
		text:Push(CreateAtlasMarkup("nameplates-InterruptShield"));
	end
	
	if (frameForUnitEvents.unitCastingSpell.textureFile) then
		text:Push(CreateTextureMarkup(frameForUnitEvents.unitCastingSpell.textureFile, 64, 64, nil, nil, 0.07, 0.93, 0.07, 0.93));
	end
	
	if (frameForUnitEvents.unitCastingSpell.displayName) then
		spacer = (text:GetCount() > 0) and " " or "";
		
		text:Push(spacer .. frameForUnitEvents.unitCastingSpell.displayName);
	end
	
	-- update value
	self:SetMinMaxValues(0, maxValue or 1);
	self:SetValue(value or 1);
	self.text:SetText(text:Concat());
	
	if (value) and (maxValue) then
		self.spark:ClearAllPoints();
		self.spark:SetPoint("CENTER", self, "LEFT", value / maxValue * self:GetWidth(), 0);
		self.spark:Show();
	else
		self.spark:Hide();
	end
end
