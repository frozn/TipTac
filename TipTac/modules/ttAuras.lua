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
local ttAuras = { auras = {} };

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttAuras, "Auras");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

-- valid units to filter the auras in DisplayAuras() with the "cfg.selfAurasOnly" setting on
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
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

-- config settings needs to be applied
function ttAuras:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set size of auras. hide auras if showing buffs/debuffs are disabled.
	local gameFontNormal = GameFontNormal:GetFont();
	
	for _, aura in ipairs(self.auras) do
		if (cfg.showBuffs) or (cfg.showDebuffs) then
			aura:SetWidth(cfg.auraSize, cfg.auraSize);
			aura.count:SetFont(gameFontNormal, (cfg.auraSize / 2), "OUTLINE");
			aura.cooldown.noCooldownCount = cfg.noCooldownCount;
		else
			aura:Hide();
		end
	end
end

-- after tooltip has been styled and has the final size
--
-- hint: auras has to be updated last because it depends on the tip's new dimension
function ttAuras:OnTipPostStyle(TT_CacheForFrames, tip, first)
	-- check if showing buffs/debuffs are disabled
	if (not cfg.showBuffs) and (not cfg.showDebuffs) then
		return;
	end
	
	-- setup auras
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	self:SetupAuras(tip, unitRecord);
end

-- after tooltip's current display parameters has to be reset
function ttAuras:OnTipPostResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- hide tip's auras
	for _, aura in ipairs(self.auras) do
		if (aura:GetParent() == tip) then
			aura:Hide();
		end
	end
end

----------------------------------------------------------------------------------------------------
--                                         Main Functions                                         --
----------------------------------------------------------------------------------------------------

-- setup auras
function ttAuras:SetupAuras(tip, unitRecord)
	-- display buffs and debuffs
	local auraCount = 0;
	
	if (cfg.showBuffs) then
		auraCount = auraCount + self:DisplayAuras(tip, unitRecord, "HELPFUL", auraCount + 1);
	end
	if (cfg.showDebuffs) then
		auraCount = auraCount + self:DisplayAuras(tip, unitRecord, "HARMFUL", auraCount + 1);
	end
	
	-- hide the unused aura frames
	for i = (auraCount + 1), #self.auras do
		self.auras[i]:Hide();
	end
end

-- display buffs and debuffs
function ttAuras:DisplayAuras(tip, unitRecord, auraType, startingAuraFrameIndex)
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
	local anchor2 = (LibFroznFunctions:MirrorAnchorPointVertically(vertAnchor) .. horzAnchor1);
	
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
			
			local aura = (self.auras[auraFrameIndex] or self:CreateAuraFrame(tip));
			
			-- anchor aura frame
			aura:ClearAllPoints();
			
			if ((auraFrameIndex - 1) % aurasPerRow == 0) or (auraFrameIndex == startingAuraFrameIndex) then
				-- new aura line
				local x = (xOffsetBasis * 2);
				local y = (cfg.auraSize + 2) * floor((auraFrameIndex - 1) / aurasPerRow) + 1;
				y = (cfg.aurasAtBottom and -y or y);
				aura:SetPoint(anchor1, tip, anchor2, x, y);
			else
				-- anchor to last
				aura:SetPoint(horzAnchor1, self.auras[auraFrameIndex - 1], horzAnchor2, xOffsetBasis * 2, 0);
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
		end
	end
	
	-- return the number of auras displayed
	return (auraFrameIndex - startingAuraFrameIndex + 1);
end

-- create aura frame
function ttAuras:CreateAuraFrame(parent)
	local aura = CreateFrame("Frame", nil, parent);
	
	aura:SetSize(cfg.auraSize, cfg.auraSize);
	
	aura.count = aura:CreateFontString(nil, "OVERLAY");
	aura.count:SetPoint("BOTTOMRIGHT", 1, 0);
	aura.count:SetFont(GameFontNormal:GetFont(), cfg.auraSize / 2, "OUTLINE");
	
	aura.icon = aura:CreateTexture(nil, "BACKGROUND");
	aura.icon:SetAllPoints();
	aura.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	
	aura.cooldown = CreateFrame("Cooldown", nil, aura, "CooldownFrameTemplate");
	aura.cooldown:SetReverse(1);
	aura.cooldown:SetAllPoints();
	aura.cooldown:SetFrameLevel(aura:GetFrameLevel());
	aura.cooldown.noCooldownCount = cfg.noCooldownCount;
	
	aura.border = aura:CreateTexture(nil, "OVERLAY");
	aura.border:SetPoint("TOPLEFT", -1, 1);
	aura.border:SetPoint("BOTTOMRIGHT", 1, -1);
	aura.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays");
	aura.border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625);
	
	self.auras[#self.auras + 1] = aura;
	
	return aura;
end
