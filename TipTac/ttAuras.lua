local gtt = GameTooltip;

-- TipTac refs
local tt = TipTac;
local cfg;

-- actual pixel perfect scale
local ui_scale = UIParent:GetEffectiveScale()
local height = select(2, GetPhysicalScreenSize())
local ppScale = (768 / height) / ui_scale

-- element registration
local ttAuras = tt:RegisterElement({ auras = {} },"Auras");
local auras = ttAuras.auras;

-- Valid units to filter the auras in DisplayAuras() with the "cfg.selfAurasOnly" setting on
local validSelfCasterUnits = {
	player = true,
	pet = true,
	vehicle = true,
};

--------------------------------------------------------------------------------------------------------
--                                                Misc                                                --
--------------------------------------------------------------------------------------------------------

local function CreateAuraFrame(parent)
	local aura = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate");
	aura:SetSize(cfg.auraSize*ppScale, cfg.auraSize*ppScale);

	aura.count = aura:CreateFontString(nil,"OVERLAY");
	aura.count:SetPoint("BOTTOMRIGHT",1,0);
	aura.count:SetFont(GameFontNormal:GetFont(),(cfg.auraSize / 2),"OUTLINE");

	aura.icon = aura:CreateTexture(nil,"BACKGROUND");
	aura.icon:SetAllPoints();
	aura.icon:SetTexCoord(0.07,0.93,0.07,0.93);

	aura.cooldown = CreateFrame("Cooldown",nil,aura,"CooldownFrameTemplate");
	aura.cooldown:SetReverse(1);
	aura.cooldown:SetAllPoints();
	aura.cooldown:SetFrameLevel(aura:GetFrameLevel());
	aura.cooldown.noCooldownCount = cfg.noCooldownCount or nil;

	aura.border = CreateFrame("Frame", nil, aura, BackdropTemplateMixin and "BackdropTemplate");
	aura.border:SetSize(cfg.auraSize*ppScale, cfg.auraSize*ppScale);
	aura.border:SetPoint("CENTER", aura, "CENTER");
	aura.border:SetBackdrop(aura:GetParent().backdropInfo);
	aura.border:SetBackdropColor(0, 0, 0, 0);
	aura.border:SetFrameLevel(aura.cooldown:GetFrameLevel()+1);

	auras[#auras + 1] = aura;
	return aura;
end

-- querires auras of the specific auraType, and sets up the aura frame and anchors it in the desired place
function ttAuras:DisplayAuras(tip,auraType,startingAuraFrameIndex)
	-- want them to be flush with the tooltips borders, means we subtract 1 offset since the very last one doesn't need to be there
	local aurasPerRow = floor((tip:GetWidth() - cfg.auraOffsetX*ppScale) / ((cfg.auraSize + cfg.auraOffsetX)*ppScale));	-- auras we can fit into one row based on the current size of the tooltip
	local xOffsetBasis = (auraType == "HELPFUL" and cfg.auraOffsetX or -cfg.auraOffsetX) * ppScale;				-- is +1 or -1 based on horz anchoring

	local queryIndex = 1;							-- aura query index for this auraType
	local auraFrameIndex = startingAuraFrameIndex;	-- array index for the next aura frame, initialized to the starting index

	-- anchor calculation based on "auraType" and "cfg.aurasAtBottom"
	local horzAnchor1 = (auraType == "HELPFUL" and "LEFT" or "RIGHT");
	local horzAnchor2 = tt.MirrorAnchors[horzAnchor1];

	local vertAnchor = (cfg.aurasAtBottom and "TOP" or "BOTTOM");
	local anchor1 = vertAnchor..horzAnchor1;
	local anchor2 = tt.MirrorAnchors[vertAnchor]..horzAnchor1;

	-- query auras
	while (true) do
		local _, iconTexture, count, debuffType, duration, endTime, casterUnit = UnitAura(tip.ttUnit.token,queryIndex,auraType);	-- [18.07.19] 8.0/BfA: "dropped second parameter"
		if (not iconTexture) or (auraFrameIndex / aurasPerRow > cfg.auraMaxRows) then
			break;
		end

		if (not cfg.selfAurasOnly or validSelfCasterUnits[casterUnit]) then
			local aura = auras[auraFrameIndex] or CreateAuraFrame(tip);

			-- Anchor It
			aura:ClearAllPoints();
			if ((auraFrameIndex - 1) % aurasPerRow == 0) or (auraFrameIndex == startingAuraFrameIndex) then
				-- new aura line
				local x = 0;
				local y = (cfg.auraSize*ppScale + 2) * floor((auraFrameIndex - 1) / aurasPerRow) + cfg.auraOffsetY*ppScale;
				y = (cfg.aurasAtBottom and -y or y);
				aura:SetPoint(anchor1,tip,anchor2,x,y);
			else
				-- anchor to last
				aura:SetPoint(horzAnchor1, auras[auraFrameIndex - 1], horzAnchor2, (xOffsetBasis), 0);
			end

			-- Cooldown
			if (cfg.showAuraCooldown) and (duration and duration > 0 and endTime and endTime > 0) then
				aura.cooldown:SetCooldown(endTime - duration,duration);
			else
				aura.cooldown:Hide();
			end

			-- Set Texture + Count
			aura.icon:SetTexture(iconTexture);
			aura.count:SetText(count and count > 1 and count or "");

			-- Border -- Only shown for debuffs
			if (cfg.auraCustomBorder) then
				if (cfg.auraBorderUseParentColor) then
					aura.border:SetBackdropBorderColor(tip:GetBackdropBorderColor());
				else
					if (auraType == "HARMFUL") then
						aura.border:SetBackdropBorderColor(unpack(cfg.auraBorderDebuffColor));
					else
						aura.border:SetBackdropBorderColor(unpack(cfg.auraBorderBuffColor));
					end
				end
			else
				if (auraType == "HARMFUL") then
					local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
					aura.border:SetBackdropBorderColor(unpack(cfg.auraBorderDebuffColor));
				else
					aura.border:Hide();
				end
			end

			-- Show + Next, Break if exceed max desired rows of aura
			aura:Show();
			auraFrameIndex = (auraFrameIndex + 1);
		end
		queryIndex = (queryIndex + 1);
	end

	-- return the number of auras displayed
	return (auraFrameIndex - startingAuraFrameIndex);
end

-- display buffs and debuffs and hide unused aura frames
function ttAuras:SetupAuras(tip)
--printf("[%.2f] %-24s %d x %d",GetTime(),"SetupAuras",tip:GetWidth(),tip:GetHeight())
	local auraCount = 0;
	if (cfg.showBuffs) then
		auraCount = auraCount + self:DisplayAuras(tip,"HELPFUL",auraCount + 1);
	end
	if (cfg.showDebuffs) then
		auraCount = auraCount + self:DisplayAuras(tip,"HARMFUL",auraCount + 1);
	end

	-- Hide the Unused
	for i = (auraCount + 1), #auras do
		auras[i]:Hide();
	end
end

--------------------------------------------------------------------------------------------------------
--                                           Element Events                                           --
--------------------------------------------------------------------------------------------------------

function ttAuras:OnLoad()
	cfg = TipTac_Config;
end

function ttAuras:OnApplyConfig(cfg)
	-- If disabled, hide auras, else set their size
	local gameFont = GameFontNormal:GetFont();
	for _, aura in ipairs(auras) do
		if (cfg.showBuffs or cfg.showDebuffs) then
			aura:SetSize(cfg.auraSize*ppScale,cfg.auraSize*ppScale);
			aura.border:SetSize(cfg.auraSize*ppScale,cfg.auraSize*ppScale);
			aura.border:Show();
			aura.count:SetFont(gameFont,(cfg.auraSize*ppScale / 2),"OUTLINE");
			aura.cooldown.noCooldownCount = cfg.noCooldownCount;
		else
			aura:Hide();
		end
	end
end

-- Auras - Has to be updated last because it depends on the tips new dimention
function ttAuras:OnPostStyleTip(tip,first)
	-- Check token, because if the GTT was hidden in OnShow (called in ApplyUnitAppearance),
	-- it would be nil here due to "tip.ttUnit" being wiped in OnTooltipCleared()
	if (tip.ttUnit.token) and (cfg.showBuffs or cfg.showDebuffs) then
		self:SetupAuras(tip);
	end
end

--function ttAuras:OnShow(tip)
--	if (tip.ttUnit.token) and (cfg.showBuffs or cfg.showDebuffs) then
--		self:SetupAuras(tip);
--	end
--end

function ttAuras:OnCleared(tip)
	for _, aura in ipairs(auras) do
		if (aura:GetParent() == tip) then
			aura:Hide();
		end
	end
end