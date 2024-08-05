-----------------------------------------------------------------------
-- TipTac - Auras
--
-- Shows the buffs and debuffs of the target unit with cooldown models.
--

-- create addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- register with TipTac core addon
local tt = _G[MOD_NAME];
local ttAuras = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttAuras, MOD_NAME .. " - Auras Module");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- valid units to filter the auras in DisplayUnitTipsAuras() with the "cfg.selfAurasOnly" setting on
local validSelfCasterUnits = {
	player = true,
	pet = true,
	vehicle = true
};

----------------------------------------------------------------------------------------------------
--                                         Element Events                                         --
----------------------------------------------------------------------------------------------------

-- config has been loaded
function ttAuras:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	-- set config
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

-- config settings need to be applied
function ttAuras:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set size of auras
	for aura, _ in self.aurasPool:EnumerateActive() do
		aura:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	end
	
	-- setup active unit tip's auras
	local tipsProcessed = {};
	
	for aura, _ in self.aurasPool:EnumerateActive() do
		local tip = aura:GetParent();
		
		if (not tipsProcessed[tip]) then
			self:SetupUnitTipsAuras(tip);
			
			tipsProcessed[tip] = true;
		end
	end
end

-- after unit tooltip has been styled and has the final size
--
-- hint: auras has to be updated last because it depends on the tip's new dimension
function ttAuras:OnUnitTipPostStyle(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- setup unit tip's auras
	self:SetupUnitTipsAuras(tip);
end

-- tooltip's current display parameters has to be reset
function ttAuras:OnTipResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- hide unit tip's auras
	self:HideUnitTipsAuras(tip);
end

----------------------------------------------------------------------------------------------------
--                                          Setup Module                                          --
----------------------------------------------------------------------------------------------------

-- setup unit tip's auras
function ttAuras:SetupUnitTipsAuras(tip)
	-- hide tip's auras
	self:HideUnitTipsAuras(tip);
	
	-- check if auras are enabled
	if (not cfg.enableAuras) then
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
	
	-- display tip's buffs and debuffs
	local currentAuraCount = 0;
	local auraCount, lastAura;
	local offsetForClampRectInsets = 0;
	
	if (cfg.showBuffs) then
		auraCount, lastAura, offsetForClampRectInsets = self:DisplayUnitTipsAuras(tip, currentDisplayParams, "HELPFUL", currentAuraCount + 1, lastAura, offsetForClampRectInsets);
		currentAuraCount = currentAuraCount + auraCount;
	end
	if (cfg.showDebuffs) then
		auraCount, lastAura, offsetForClampRectInsets = self:DisplayUnitTipsAuras(tip, currentDisplayParams, "HARMFUL", currentAuraCount + 1, lastAura, offsetForClampRectInsets);
		currentAuraCount = currentAuraCount + auraCount;
	end
	
	-- prevent auras from moving off-screen
	if (offsetForClampRectInsets > 0) then
		local leftOffset, rightOffset, topOffset, bottomOffset = tip:GetClampRectInsets();
		
		if (cfg.aurasAtBottom) then
			if (bottomOffset > -offsetForClampRectInsets) then
				-- set clamp rect insets to tip for preventing additional elements from moving off-screen
				LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetClampRectInsetsToTip", tip, leftOffset, rightOffset, topOffset, -offsetForClampRectInsets);
			end
		else
			if (topOffset < offsetForClampRectInsets) then
				-- set clamp rect insets to tip for preventing additional elements from moving off-screen
				LibFroznFunctions:FireGroupEvent(MOD_NAME, "SetClampRectInsetsToTip", tip, leftOffset, rightOffset, offsetForClampRectInsets, bottomOffset);
			end
		end
	end
end

-- display unit tip's buffs and debuffs
function ttAuras:DisplayUnitTipsAuras(tip, currentDisplayParams, auraType, startingAuraFrameIndex, lastAura, offsetForClampRectInsets)
	local unitRecord = currentDisplayParams.unitRecord;
	
	-- queries auras of the specific auraType, sets up the aura frame and anchors it in the desired place.
	local aurasPerRow = floor((tip:GetWidth() - 4) / (cfg.auraSize + 2)); -- auras we can fit into one row based on the current size of the tooltip
	local xOffsetBasis = (auraType == "HELPFUL" and 1 or -1);             -- is +1 or -1 based on horz anchoring
	
	local queryIndex = 0;                              -- aura query index for this auraType
	local auraFrameIndex = startingAuraFrameIndex - 1; -- array index for the next aura frame, initialized to the starting index
	
	-- anchor calculation based on auraType and "cfg.aurasAtBottom"
	local horzAnchor1 = (auraType == "HELPFUL" and "LEFT" or "RIGHT");
	local horzAnchor2 = LibFroznFunctions:MirrorAnchorPointVertically(horzAnchor1);
	
	local vertAnchor = (cfg.aurasAtBottom and "TOP" or "BOTTOM");
	local anchor1 = (vertAnchor .. horzAnchor1);
	local anchor2 = (LibFroznFunctions:MirrorAnchorPointHorizontally(vertAnchor) .. horzAnchor1);
	
	-- query auras
	while (true) do
		queryIndex = queryIndex + 1;
		
		local unitAuraData = LibFroznFunctions:GetAuraDataByIndex(unitRecord.id, queryIndex, auraType);
		
		-- no more auras available or aura rows exceed max desired rows of auras
		if (not unitAuraData) or (not unitAuraData.name) or (not unitAuraData.icon) or ((auraFrameIndex - 1) / aurasPerRow > cfg.auraMaxRows) then
			break;
		end
		
		-- setup aura fram if it needs to be shown
		if (not cfg.selfAurasOnly) or (validSelfCasterUnits[unitAuraData.sourceUnit]) then
			auraFrameIndex = auraFrameIndex + 1;
			
			local aura = self.aurasPool:Acquire();
			
			aura:SetParent(tip);
			aura:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- anchor aura frame
			aura:ClearAllPoints();
			
			if ((auraFrameIndex - 1) % aurasPerRow == 0) or (auraFrameIndex == startingAuraFrameIndex) then
				-- new aura line
				local x = (xOffsetBasis * 2);
				local y = (cfg.auraSize + 2) * floor((auraFrameIndex - 1) / aurasPerRow) + 1 + cfg.auraOffset;
				
				if (cfg.aurasAtBottom) then
					if (currentDisplayParams.isSetBottomOverlayToHighlightTipTacDeveloper) then
						y = y + (math.max(4 - cfg.auraOffset, 0));
					end
				else
					if (currentDisplayParams.isSetTopOverlayToHighlightTipTacDeveloper) then
						y = y + (math.max(9 - cfg.auraOffset, 0));
					end
				end
				
				aura:SetPoint(anchor1, tip, anchor2, x, cfg.aurasAtBottom and -y or y);
				
				-- set offset to prevent auras from moving off-screen
				local newOffsetForClampRectInsets = y + (cfg.auraSize + 2);
				
				if (newOffsetForClampRectInsets > offsetForClampRectInsets) then
					offsetForClampRectInsets = newOffsetForClampRectInsets;
				end
			else
				-- anchor to last
				aura:SetPoint(horzAnchor1, lastAura, horzAnchor2, xOffsetBasis * 2, 0);
			end
			
			-- show cooldown model if enabled and aura duration is available
			if (cfg.showAuraCooldown) and (unitAuraData.duration and (unitAuraData.duration > 0) and unitAuraData.expirationTime and (unitAuraData.expirationTime > 0)) then
				aura.cooldown:SetCooldown(unitAuraData.expirationTime - unitAuraData.duration, unitAuraData.duration);
			else
				aura.cooldown:Hide();
			end
			
			-- set texture and count
			aura.icon:SetTexture(unitAuraData.icon);
			aura.count:SetText(unitAuraData.applications and (unitAuraData.applications > 1) and unitAuraData.applications or "");
			
			-- show border, only for debuffs
			if (auraType == "HARMFUL") then
				local color = (DebuffTypeColor[unitAuraData.dispelName] or DebuffTypeColor["none"]);
				
				aura.border:SetVertexColor(color.r, color.g, color.b);
				aura.border:Show();
			else
				aura.border:Hide();
			end
			
			-- show aura
			aura:Show();
			
			lastAura = aura;
		end
	end
	
	-- return the number of auras displayed
	local auraCount = auraFrameIndex - startingAuraFrameIndex + 1;
	
	return auraCount, lastAura, offsetForClampRectInsets;
end

-- create aura frame
ttAuras.aurasPool = CreateFramePool("Frame", nil, nil, nil, false, function(aura)
	aura.count = aura:CreateFontString(nil, "OVERLAY");
	aura.count:SetPoint("BOTTOMRIGHT", 1, 0);
	
	aura.icon = aura:CreateTexture(nil, "BACKGROUND");
	aura.icon:SetAllPoints();
	aura.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	
	aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate");
	aura.cooldown:SetReverse(1);
	aura.cooldown:SetAllPoints();
	aura.cooldown:SetFrameLevel(aura:GetFrameLevel());
	
	aura.border = aura:CreateTexture(nil, "OVERLAY");
	aura.border:SetPoint("TOPLEFT", -1, 1);
	aura.border:SetPoint("BOTTOMRIGHT", 1, -1);
	aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays");
	aura.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625);
	
	-- config settings need to be applied
	function aura:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- set size of auras
		self:SetSize(cfg.auraSize, cfg.auraSize);
		self.count:SetFont(GameFontNormal:GetFont(), cfg.auraSize / 2, "OUTLINE");
		self.cooldown.noCooldownCount = cfg.noCooldownCount;
	end
	
	aura:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
end);

-- hide unit tip's auras
function ttAuras:HideUnitTipsAuras(tip)
	for aura, _ in self.aurasPool:EnumerateActive() do
		if (aura:GetParent() == tip) then
			self.aurasPool:Release(aura);
		end
	end
end
