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
local ttIcons = {};

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, ttIcons, "Icons");

--ttIcons.icons = {};

--------------------------------------------------------------------------------------------------------
--                                                Misc                                                --
--------------------------------------------------------------------------------------------------------

function ttIcons:SetIcon(icon, unitRecord)
	if (not UnitExists(unitRecord.id)) then
		return;
	end
	
	local raidIconIndex = GetRaidTargetIndex(unitRecord.id);
	local englishFaction = UnitFactionGroup(unitRecord.id);

	if (cfg.iconRaid) and (raidIconIndex) then
		icon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
		SetRaidTargetIconTexture(icon,raidIconIndex);
	elseif (cfg.iconFaction) and (UnitIsPVPFreeForAll(unitRecord.id)) then
		icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-FFA");
		icon:SetTexCoord(0, 0.62, 0, 0.62);
	elseif (cfg.iconFaction) and (UnitIsPVP(unitRecord.id)) and (englishFaction) and (englishFaction ~= "Neutral") then
		icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. englishFaction);
		icon:SetTexCoord(0, 0.62, 0, 0.62);
	elseif (cfg.iconCombat) and (UnitAffectingCombat(unitRecord.id)) then
		icon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon");
		icon:SetTexCoord(0.5, 1, 0, 0.5);
	elseif (unitRecord.isPlayer) and (cfg.iconClass) then
		local texCoord = CLASS_ICON_TCOORDS[unitRecord.classFile];
		if (texCoord) then
			icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles");
			icon:SetTexCoord(unpack(texCoord));
		end
	else
		return false;
	end

	return true;
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttIcons:OnConfigLoaded(_TT_CacheForFrames, _cfg, _TT_ExtendedConfig)
	TT_CacheForFrames = _TT_CacheForFrames;
	cfg = _cfg;
	TT_ExtendedConfig = _TT_ExtendedConfig;
end

function ttIcons:OnApplyConfig(TT_CacheForFrames, cfg, TT_ExtendedConfig)
	self.wantIcon = (cfg.iconRaid or cfg.iconFaction or cfg.iconCombat or cfg.iconClass);

	if (self.wantIcon) then
		if (not self.icon) then
			self.icon = GameTooltip:CreateTexture(nil,"BACKGROUND");
		end
		self.icon:SetSize(cfg.iconSize,cfg.iconSize);
		self.icon:ClearAllPoints();
		self.icon:SetPoint(LibFroznFunctions:MirrorAnchorPointVertically(cfg.iconAnchor),GameTooltip,cfg.iconAnchor);
	elseif (self.icon) then
		self.icon:Hide();
	end
end

function ttIcons:OnTipPostStyle(TT_CacheForFrames, tip, first)
	if (not self.wantIcon) then
		return;
	end
	
	local unitRecord = TT_CacheForFrames[tip].currentDisplayParams.unitRecord;
	
	-- show icon
	self.icon:SetShown(self:SetIcon(self.icon, unitRecord));
end

function ttIcons:OnTipPostResetCurrentDisplayParams(TT_CacheForFrames, tip, currentDisplayParams)
	if (self.icon) and (tip == GameTooltip) then
		self.icon:Hide();
	end
end