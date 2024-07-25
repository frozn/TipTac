-----------------------------------------------------------------------
-- TipTac - Icons
--
-- Shows icons next to the tooltip.
--

-- create addon
local MOD_NAME = ...;

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

-- register with TipTac core addon
local tt = _G[MOD_NAME];
local ttIcons = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttIcons, MOD_NAME .. " - Icons Module");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;
local TT_ExtendedConfig;
local TT_CacheForFrames;

----------------------------------------------------------------------------------------------------
--                                         Element Events                                         --
----------------------------------------------------------------------------------------------------

-- config has been loaded
function ttIcons:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	-- set config
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

-- config settings need to be applied
function ttIcons:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	-- set size of icons
	for icon, _ in self.iconPool:EnumerateActive() do
		icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
	end
	
	-- setup active tip's icons
	local tipsProcessed = {};
	
	for icon, _ in self.iconPool:EnumerateActive() do
		local tip = icon:GetParent();
		
		if (not tipsProcessed[tip]) then
			self:SetupTipsIcon(tip);
			
			tipsProcessed[tip] = true;
		end
	end
end

-- unit tooltip is being styled
function ttIcons:OnUnitTipStyle(TT_CacheForFrames, tip, currentDisplayParams, first)
	-- setup tip's icon
	self:SetupTipsIcon(tip);
end

-- tooltip's current display parameters has to be reset
function ttIcons:OnTipResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	-- hide tip's icon
	self:HideTipsIcon(tip);
end

----------------------------------------------------------------------------------------------------
--                                          Setup Module                                          --
----------------------------------------------------------------------------------------------------

-- setup tip's icon
function ttIcons:SetupTipsIcon(tip)
	-- hide tip's icon
	self:HideTipsIcon(tip);
	
	-- check if icons are enabled
	if (not cfg.enableIcons) then
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
	
	-- display tip's icons
	local currentIconCount = 0;
	local iconCount;
	
	if (cfg.iconRaid) then
		iconCount = self:DisplayTipsIcon(tip, currentDisplayParams, "RAID", currentIconCount + 1);
		currentIconCount = currentIconCount + iconCount;
	end
	if (cfg.iconFaction) and (currentIconCount < cfg.iconMaxIcons) then
		iconCount = self:DisplayTipsIcon(tip, currentDisplayParams, "FACTION", currentIconCount + 1);
		currentIconCount = currentIconCount + iconCount;
	end
	if (cfg.iconCombat) and (currentIconCount < cfg.iconMaxIcons) then
		iconCount = self:DisplayTipsIcon(tip, currentDisplayParams, "COMBAT", currentIconCount + 1);
		currentIconCount = currentIconCount + iconCount;
	end
	if (cfg.iconClass) and (currentIconCount < cfg.iconMaxIcons) then
		iconCount = self:DisplayTipsIcon(tip, currentDisplayParams, "CLASS", currentIconCount + 1);
		currentIconCount = currentIconCount + iconCount;
	end
end

-- display tip's icon
function ttIcons:DisplayTipsIcon(tip, currentDisplayParams, iconType, startingIconFrameIndex)
	local unitRecord = currentDisplayParams.unitRecord;
	
	-- unit doesn't exist
	if (not UnitExists(unitRecord.id)) then
		return 0;
	end
	
	-- display tip's raid icon
	local iconFrameIndex = startingIconFrameIndex - 1;
	local icon;
	
	if (iconType == "RAID") then
		local raidIconIndex = GetRaidTargetIndex(unitRecord.id);
		
		if (raidIconIndex) then
			-- acquire icon frame
			iconFrameIndex = iconFrameIndex + 1;
			
			icon = self.iconPool:Acquire();
			
			icon:SetParent(tip);
			icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- set icon
			icon.icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
			SetRaidTargetIconTexture(icon.icon, raidIconIndex);
		end
	
	-- display tip's faction icon
	elseif (iconType == "FACTION") then
		if (UnitIsPVPFreeForAll(unitRecord.id)) then
			-- acquire icon frame
			iconFrameIndex = iconFrameIndex + 1;
			
			icon = self.iconPool:Acquire();
			
			icon:SetParent(tip);
			icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- set icon
			icon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
			icon.icon:SetTexCoord(0, 0.62, 0, 0.62);
		elseif (UnitIsPVP(unitRecord.id)) then
			-- get english faction
			local englishFaction = UnitFactionGroup(unitRecord.id);
			
			if (englishFaction) and (LibFroznFunctions:UnitIsMercenary(unitRecord.id)) then
				if (englishFaction == "Horde") then
					englishFaction = "Alliance";
				elseif (englishFaction == "Alliance") then
					englishFaction = "Horde";
				end
			end
			
			-- set icon if faction isn't neutral
			if (englishFaction) and (englishFaction ~= "Neutral") then
				-- acquire icon frame
				iconFrameIndex = iconFrameIndex + 1;
				
				icon = self.iconPool:Acquire();
				
				icon:SetParent(tip);
				icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
				
				-- set icon
				icon.icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. englishFaction);
				icon.icon:SetTexCoord(0, 0.62, 0, 0.62);
			end
		end
	
	-- display tip's combat icon
	elseif (iconType == "COMBAT") then
		if (UnitAffectingCombat(unitRecord.id)) then
			-- acquire icon frame
			iconFrameIndex = iconFrameIndex + 1;
			
			icon = self.iconPool:Acquire();
			
			icon:SetParent(tip);
			icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- set icon
			icon.icon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon");
			icon.icon:SetTexCoord(0.5, 1, 0, 0.5);
		end
	
	-- display tip's class icon
	elseif (iconType == "CLASS") then
		if (unitRecord.isPlayer) then
			-- acquire icon frame
			iconFrameIndex = iconFrameIndex + 1;
			
			icon = self.iconPool:Acquire();
			
			icon:SetParent(tip);
			icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
			
			-- set icon
			local texCoord = CLASS_ICON_TCOORDS[unitRecord.classFile];
			
			if (texCoord) then
				icon.icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
				icon.icon:SetTexCoord(unpack(texCoord));
			end
		end
	end
	
	-- anchor and show icon frame
	if (icon) then
		-- anchor icon frame
		local iconAnchor, tipAnchor = LibFroznFunctions:GetAnchorPointsByAnchorPointAndAlignment(cfg.iconAnchor, cfg.iconAnchorHorizontalAlign, cfg.iconAnchorVerticalAlign);
		
		if (iconAnchor) and (tipAnchor) then
			local offsetForIconFrameIndex = (cfg.iconSize + 2) * (iconFrameIndex - 1);
			local xOffset, yOffset = LibFroznFunctions:GetOffsetsByAnchorPointAndOffsetsAndGrowDirection(cfg.iconAnchor, 1, cfg.iconOffsetX, cfg.iconOffsetY, cfg.iconAnchorGrowDirection, offsetForIconFrameIndex);
			
			icon:ClearAllPoints();
			icon:SetPoint(iconAnchor, tip, tipAnchor, xOffset, yOffset);
			
			-- show icon frame
			icon:Show();
		else
			iconFrameIndex = iconFrameIndex - 1;
			
			self.iconPool:Release(icon);
		end
	end
	
	return iconFrameIndex - startingIconFrameIndex + 1;
end

-- create icon frame
ttIcons.iconPool = CreateFramePool("Frame", nil, nil, nil, false, function(icon)
	icon.icon = icon:CreateTexture(nil, "BACKGROUND");
	icon.icon:SetAllPoints();
	
	-- config settings need to be applied
	function icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- set size of icons
		self:SetSize(cfg.iconSize, cfg.iconSize);
	end
	
	icon:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig);
end);

-- hide tip's icon
function ttIcons:HideTipsIcon(tip)
	for icon, _ in self.iconPool:EnumerateActive() do
		if (icon:GetParent() == tip) then
			self.iconPool:Release(icon);
		end
	end
end
