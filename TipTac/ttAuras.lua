local gtt = GameTooltip;

-- TipTac refs
local tt = TipTac;
local cfg;

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
	local aura = CreateFrame("Frame", nil, parent);
	if (cfg.auraPixelPerfectPositioning) then
		aura:SetScale(tt.ppScale / cfg.gttScale);
	end
	aura:SetSize(cfg.auraSize, cfg.auraSize);

	aura.count = aura:CreateFontString(nil,"OVERLAY");
	aura.count:SetPoint("BOTTOMRIGHT",1,0);
	aura.count:SetFont(GameFontNormal:GetFont(),(cfg.auraSize / 2),"OUTLINE");

	aura.icon = CreateFrame("Frame", nil, aura);
	aura.icon:SetPoint("CENTER",aura,"CENTER");
	aura.icon:SetSize(cfg.auraSize, cfg.auraSize);

	aura.icon.texture = aura:CreateTexture(nil,"BACKGROUND");
	aura.icon.texture:SetPoint("CENTER",aura.icon,"CENTER");
	aura.icon.texture:SetTexCoord(0.07,0.93,0.07,0.93);
	ttAuras:ApplyInsetsToIconTexture(aura.icon.texture, aura:GetParent().backdropInfo);

	aura.icon.cooldown = CreateFrame("Cooldown",nil,aura.icon,"CooldownFrameTemplate");
	aura.icon.cooldown:SetReverse(1);
	aura.icon.cooldown:SetPoint("CENTER",aura.icon,"CENTER");
	aura.icon.cooldown:SetFrameLevel(aura:GetFrameLevel());
	aura.icon.cooldown.noCooldownCount = cfg.noCooldownCount or nil;

	ttAuras:ApplyInsetsToIconTexture(aura.icon, aura:GetParent().backdropInfo);

	aura.border = CreateFrame("Frame", nil, aura, BackdropTemplateMixin and "BackdropTemplate");
	aura.border:SetAllPoints();
	ttAuras:ApplyParentBackdropToAura(aura.border, aura:GetParent())
	aura.border:SetFrameLevel(aura.icon.cooldown:GetFrameLevel()+1);

	auras[#auras + 1] = aura;
	return aura;
end

function ttAuras:ApplyParentBackdropToAura(aura, parent)
	-- using the normal values here since the entire aura is scaled already
	local parentBackdropInfo = parent.backdropInfo;
	local backdropInfo;
	if (cfg.auraPixelPerfectPositioning) then
		local parentBackdropInfo = parent.backdropInfo;
		backdropInfo = {
			bgFile = parentBackdropInfo.bgFile,
			edgeFile = parentBackdropInfo.edgeFile,
			edgeSize = cfg.backdropEdgeSize,
			insets = {left = cfg.backdropInsets, right = cfg.backdropInsets, top = cfg.backdropInsets, bottom = cfg.backdropInsets},
		}
	else
		backdropInfo = parentBackdropInfo
	end

	aura:SetBackdrop(backdropInfo);
	aura:SetBackdropColor(0, 0, 0, 0);
end

function ttAuras:ApplyInsetsToIconTexture(texture, backdropInfo)
	-- manually implementing border insets because otherwise we cant remove the ugly default border
	-- assumes symmetrical insets
	if (cfg.auraPixelPerfectPositioning) then
		texture:SetSize(cfg.auraSize - cfg.backdropInsets * 2, cfg.auraSize - cfg.backdropInsets * 2);
	else
		texture:SetSize(cfg.auraSize - backdropInfo.insets.left * 2, cfg.auraSize - backdropInfo.insets.top * 2);
	end
end

function ttAuras:ConvertToRealPixels(pos)
	if (cfg.auraPixelPerfectPositioning) then
		return (pos / tt.ppScale * cfg.gttScale)
	else
		return pos
	end
end

function ttAuras:ConvertToFakePixels(pos)
	if (cfg.auraPixelPerfectPositioning) then
		return (pos * tt.ppScale / cfg.gttScale)
	else
		return pos
	end
end

function ttAuras:SetClamp(tip, furthestAuraIcon)
	local basicOffset = 5;
	local left, right, top, bottom = -basicOffset, basicOffset, basicOffset, -basicOffset;
		
	if(furthestAuraIcon ~= nil) then
		local leftDistance = ttAuras:ConvertToRealPixels(tip:GetLeft()) - furthestAuraIcon:GetLeft();
		local rightDistance = furthestAuraIcon:GetRight() - ttAuras:ConvertToRealPixels(tip:GetRight());
		local topDistance = furthestAuraIcon:GetTop() - ttAuras:ConvertToRealPixels(tip:GetTop());
		local bottomDistance = ttAuras:ConvertToRealPixels(tip:GetBottom()) - furthestAuraIcon:GetBottom();

		left = left + ((leftDistance > 0) and -leftDistance or 0);
		right = right + ((rightDistance > 0) and rightDistance or 0);
		top = top + ((topDistance > 0) and topDistance or 0);
		bottom = bottom + ((bottomDistance > 0) and -bottomDistance or 0);
	end

	tip:SetClampedToScreen(true);
	tip:SetClampRectInsets(ttAuras:ConvertToFakePixels(left), ttAuras:ConvertToFakePixels(right), ttAuras:ConvertToFakePixels(top), ttAuras:ConvertToFakePixels(bottom));
end

-- querires auras of the specific auraType, and sets up the aura frame and anchors it in the desired place
function ttAuras:DisplayAuras(tip,auraType,startingAuraFrameIndex)
	-- want them to be flush with the tooltips borders, means we subtract 1 offset since the very last one doesn't need to be there
	-- aura icons don't scale because we need the exact width, have to change the size manually in the options instead.
	local tooltipWidth = ttAuras:ConvertToRealPixels(tip:GetWidth());
	local aurasPerRow = floor((tooltipWidth + cfg.auraOffsetX) / (cfg.auraSize + cfg.auraOffsetX));	-- auras we can fit into one row based on the current size of the tooltip
	local xOffsetBasis = auraType == "HELPFUL" and cfg.auraOffsetX or -cfg.auraOffsetX;				-- is +1 or -1 based on horz anchoring

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
				local y = (cfg.auraSize + cfg.auraOffsetY) * floor((auraFrameIndex - 1) / aurasPerRow) + cfg.auraOffsetY;
				y = (cfg.aurasAtBottom and -y or y);
				aura:SetPoint(anchor1, tip, anchor2, x, y);
			else
				-- anchor to last
				aura:SetPoint(horzAnchor1, auras[auraFrameIndex - 1], horzAnchor2, xOffsetBasis, 0);
			end

			-- Cooldown
			if (cfg.showAuraCooldown) and (duration and duration > 0 and endTime and endTime > 0) then
				aura.icon.cooldown:SetCooldown(endTime - duration,duration);
			else
				aura.icon.cooldown:Hide();
			end

			-- Set Texture + Count
			aura.icon.texture:SetTexture(iconTexture);
			aura.count:SetText(count and count > 1 and count or "");

			-- Border
			if (cfg.auraCustomBorder) then
				if (cfg.auraBorderUseParentColor) then
					aura.border:SetBackdropBorderColor(tip:GetBackdropBorderColor());
				else
					if (auraType == "HARMFUL") then
						if (cfg.auraBorderUseDebuffTypeColors) then
							local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
							aura.border:SetBackdropBorderColor(color.r, color.g, color.b);
						else
							aura.border:SetBackdropBorderColor(unpack(cfg.auraBorderDebuffColor));
						end
					else
						aura.border:SetBackdropBorderColor(unpack(cfg.auraBorderBuffColor));
					end
				end
				aura.border:Show();
			else
				-- old way (only debuffs)
				if (auraType == "HARMFUL") then
					local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
					aura.border:SetBackdropBorderColor(color.r, color.g, color.b);
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
	if (cfg.showDebuffs) then
		auraCount = auraCount + self:DisplayAuras(tip,"HARMFUL",auraCount + 1);
	end
	if (cfg.showBuffs) then
		auraCount = auraCount + self:DisplayAuras(tip,"HELPFUL",auraCount + 1);
	end

	ttAuras:SetClamp(tip, auras[auraCount]); -- last one should be the furthest out

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
			if (cfg.auraPixelPerfectPositioning) then
				aura:SetScale(tt.ppScale / cfg.gttScale);
			else
				aura:SetScale(1);
			end
			aura:SetSize(cfg.auraSize, cfg.auraSize);
			aura.border:SetBackdrop(nil);
			ttAuras:ApplyParentBackdropToAura(aura.border, aura:GetParent())
			aura.border:SetAllPoints();
			ttAuras:ApplyInsetsToIconTexture(aura.icon, aura:GetParent().backdropInfo);
			ttAuras:ApplyInsetsToIconTexture(aura.icon.texture, aura:GetParent().backdropInfo);
			aura.count:SetFont(gameFont,(cfg.auraSize / 2),"OUTLINE");
			aura.icon.cooldown.noCooldownCount = cfg.noCooldownCount;
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