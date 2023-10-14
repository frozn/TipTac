-----------------------------------------------------------------------
-- TipTac
--
-- Show player talents/specialization including role and talent/specialization icon and the average item level in the tooltip.
--

-- create addon
local MOD_NAME = ...;
local tt = CreateFrame("Frame", MOD_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate");
tt:Hide();

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;

-- default config
local TT_DefaultConfig = {
	showUnitTip = true,
	showStatus = true,
	showGuild = true,
	showGuildRank = true,
	guildRankFormat = "both",
	showTargetedBy = true,
	showPlayerGender = false,
	nameType = "title",
	showRealm = "show",
	showTarget = "last",
	targetYouText = "<<YOU>>",
	showCurrentUnitSpeed = true,
	showMythicPlusDungeonScore = true,
	showMount = true,
	showMountCollected = true,
	showMountIcon = true,
	showMountText = true,
	showMountSpeed = true,
	
	showBattlePetTip = true,
	gttScale = 1,
	updateFreq = 0.5,
	enableChatHoverTips = true,
	hideFactionText = false,
	hidePvpText = true,
	hideSpecializationAndClassText = true,
	
	-- colors
	enableColorName = true,
	colorName = { 1, 1, 1, 1 },
	colorNameByReaction = true,
	colorNameByClass = false,
	
	colorGuild = { 0, 0.5, 0.8, 1 },
	colorSameGuild = { 1, 0.2, 1, 1 },
	colorGuildByReaction = true,
	
	colorRace = { 1, 1, 1, 1 },
	colorLevel = { 0.75, 0.75, 0.75, 1 },
	
	classColoredBorder = true,
	
	-- reactions
	reactColoredBorder = false,
	reactIcon = false,
	
	reactText = false,
	colorReactText = { 1, 1, 1, 1 },
	reactColoredText = true,
	
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.tapped] = { 0.75, 0.75, 0.75, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.hostile] = { 1, 0, 0, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.caution] = { 1, 0.5, 0, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.neutral] = { 1, 1, 0, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer] = { 0.15, 0.76, 0.92, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer] = { 0, 1, 0, 1},
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.friendlyNPC] = { 0, 0.76, 0, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.honoredNPC] = { 0, 0.76, 0.36, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.reveredNPC] = { 0, 0.76, 0.56, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.exaltedNPC] = { 0, 0.76, 0.76, 1 },
	["colorReactText" .. LFF_UNIT_REACTION_INDEX.dead] = { 0.5, 0.5, 0.5, 1 },
	
	-- bg color
	reactColoredBackdrop = false,
	
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.tapped] = { 0.2, 0.2, 0.2, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.hostile] = { 0.3, 0, 0, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.caution] = { 0.3, 0.15, 0, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.neutral] = { 0.3, 0.3, 0, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPlayer] = { 0, 0.2, 0.3, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyPvPPlayer] = { 0, 0.3, 0, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.friendlyNPC] = { 0, 0.2, 0, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.honoredNPC] = { 0, 0.2, 0.1, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.reveredNPC] = { 0, 0.2, 0.15, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.exaltedNPC] = { 0, 0.2, 0.2, 1 },
	["colorReactBack" .. LFF_UNIT_REACTION_INDEX.dead] = { 0.1, 0.1, 0.1, 1 },
	
	enableBackdrop = true,
	tipBackdropBG = "Interface\\Buttons\\WHITE8X8",
	tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
	pixelPerfectBackdrop = false,
	backdropEdgeSize = 14,
	backdropInsets = 2.5,
	
	tipColor = { 0.1, 0.1, 0.2, 1 },        -- UI default: for most: (0.1, 0.1, 0.2, 1), world objects?: (0, 0.2, 0.35, 1)
	tipBorderColor = { 0.3, 0.3, 0.4, 1 },  -- UI default: (1, 1, 1, 1)
	gradientTip = true,
	gradientHeight = 32,
	gradientColor = { 0.8, 0.8, 0.8, 0.15 },
	
	modifyFonts = false,
	fontFace = "",   -- set during event ADDON_LOADED
	fontSize = 0,    -- set during event ADDON_LOADED
	fontFlags = "",	 -- set during event ADDON_LOADED
	fontSizeDeltaHeader = 2,
	fontSizeDeltaSmall = -2,
	
	classification_minus = "-%s",  -- new classification in MoP. used for minion mobs that typically have less health than normal mobs of their level, but engage the player in larger numbers. example of use: the "Sha Haunts" early in the horde's quests in thunder hold.
	classification_trivial = "~%s",
	classification_normal = "%s",
	classification_elite = "+%s",
	classification_worldboss = "%s|r (Boss)",
	classification_rare = "%s|r (Rare)",
	classification_rareelite = "+%s|r (Rare)",
	
	overrideFade = true,
	preFadeTime = 0.1,
	fadeTime = 0.1,
	hideWorldTips = true,
	
	barFontFace = "",          -- set during event ADDON_LOADED
	barFontSize = 0,           -- set during event ADDON_LOADED
	barFontFlags = "",         -- set during event ADDON_LOADED
	barHeight = 6,
	barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
	
	hideDefaultBar = true,
	barsCondenseValues = true,
	healthBar = true,
	healthBarClassColor = true,
	healthBarText = "value",
	healthBarColor = { 0.3, 0.9, 0.3, 1 },
	manaBar = false,
	manaBarText = "value",
	manaBarColor = { 0.3, 0.55, 0.9, 1 },
	powerBar = false,
	powerBarText = "value",
	
	aurasAtBottom = false,
	showBuffs = true,
	showDebuffs = true,
	selfAurasOnly = false,
	auraSize = 20,
	auraMaxRows = 2,
	showAuraCooldown = true,
	noCooldownCount = false,
	
	iconRaid = true,
	iconFaction = false,
	iconCombat = false,
	iconClass = false,
	iconAnchor = "TOPLEFT",
	iconSize = 24,
	
	enableAnchor = true,
	anchorWorldUnitType = "normal",
	anchorWorldUnitPoint = "BOTTOMRIGHT",
	anchorWorldTipType = "normal",
	anchorWorldTipPoint = "BOTTOMRIGHT",
	anchorFrameUnitType = "normal",
	anchorFrameUnitPoint = "BOTTOMRIGHT",
	anchorFrameTipType = "normal",
	anchorFrameTipPoint = "BOTTOMRIGHT",
	
	enableAnchorOverrideWorldUnitInCombat = false,
	anchorWorldUnitTypeInCombat = "normal",
	anchorWorldUnitPointInCombat = "BOTTOMRIGHT",
	enableAnchorOverrideWorldTipInCombat = false,
	anchorWorldTipTypeInCombat = "normal",
	anchorWorldTipPointInCombat = "BOTTOMRIGHT",
	enableAnchorOverrideFrameUnitInCombat = false,
	anchorFrameUnitTypeInCombat = "normal",
	anchorFrameUnitPointInCombat = "BOTTOMRIGHT",
	enableAnchorOverrideFrameTipInCombat = false,
	anchorFrameTipTypeInCombat = "normal",
	anchorFrameTipPointInCombat = "BOTTOMRIGHT",
	
	enableAnchorOverrideCF = false,
	anchorOverrideCFType = "normal",
	anchorOverrideCFPoint = "BOTTOMRIGHT",
	
	mouseOffsetX = 0,
	mouseOffsetY = 0,
	
	hideTipsWorldUnits = false,
	hideTipsWorldTips = false,
	hideTipsFrameUnits = false,
	hideTipsFrameTips = false,
	hideTipsUnitTips = false,
	hideTipsSpellTips = false,
	hideTipsItemTips = false,
	hideTipsActionTips = false,
	hideTipsInCombatWorldUnits = false,
	hideTipsInCombatWorldTips = false,
	hideTipsInCombatFrameUnits = false,
	hideTipsInCombatFrameTips = false,
	hideTipsInCombatUnitTips = false,
	hideTipsInCombatSpellTips = false,
	hideTipsInCombatItemTips = false,
	hideTipsInCombatActionTips = false,
	showHiddenModifierKey = "shift"
};

-- extended config
local TT_ExtendedConfig = {};

-- original GameTooltip fonts
TT_ExtendedConfig.oldGameTooltipText = {        -- set during tt:ApplyConfig()
	fontFace = "",
	fontSize = 0,
	fontFlags = ""
};
TT_ExtendedConfig.oldGameTooltipHeaderText = {  -- set during tt:ApplyConfig()
	fontFace = "",
	fontSize = 0,
	fontFlags = ""
};
TT_ExtendedConfig.oldGameTooltipTextSmall = {   -- set during tt:ApplyConfig()
	fontFace = "",
	fontSize = 0,
	fontFlags = ""
};

TT_ExtendedConfig.oldGameTooltipFontsRemembered = false;

-- tooltip backdrop config (examples see "Backdrop.lua")
TT_ExtendedConfig.tipBackdrop = {
	bgFile = "",                                           -- set during event ADDON_LOADED and tt:ApplyConfig()
	edgeFile = "",                                         -- set during event ADDON_LOADED and tt:ApplyConfig()
	tile = true,
	tileSize = 16,
	tileEdge = false,
	edgeSize = 0,                                          -- set during event ADDON_LOADED and tt:ApplyConfig()
	insets = { left = 0, right = 0, top = 0, bottom = 0 }  -- set during event ADDON_LOADED and tt:ApplyConfig()
};

TT_ExtendedConfig.backdropColor = CreateColor(0, 0, 0, 0);        -- set during event ADDON_LOADED and tt:ApplyConfig()
TT_ExtendedConfig.backdropBorderColor = CreateColor(0, 0, 0, 0);  -- set during event ADDON_LOADED and tt:ApplyConfig()

-- tooltip padding config for GameTooltip
TT_ExtendedConfig.tipPaddingForGameTooltip = {
	right = 0,   -- set during event ADDON_LOADED and tt:ApplyConfig()
	bottom = 0,  -- set during event ADDON_LOADED and tt:ApplyConfig()
	left = 0,    -- set during event ADDON_LOADED and tt:ApplyConfig()
	top = 0,     -- set during event ADDON_LOADED and tt:ApplyConfig()
	offset = -TT_DefaultConfig.backdropInsets  -- default backdropInsets should result in no additional padding applied
};

-- tooltip default anchor type and anchor point
TT_ExtendedConfig.defaultAnchorType = "normal";
TT_ExtendedConfig.defaultAnchorPoint = "BOTTOMRIGHT";

-- tips to modify in appearance and hooking config. other mods can use TipTac:AddModifiedTip(tip, noHooks) or TipTac:AddModifiedTipExtended(tip, tipParams) to register their own tooltips.
--
-- 1st key = addon name
-- 3rd key = frame name
--
-- params for 1st key:
-- frames                 optional. frames to modify in appearance and hooking config
-- hookFnForAddOn         optional. individual function for hooking for addon, nil otherwise. parameters: TT_CacheForFrames
-- waitSecondsForHooking  optional. float with number of seconds to wait before hooking for addon, nil otherwise.
--
-- params for 3rd key:
-- applyAppearance                true if appearance should be applied, false/nil otherwise.
-- applyScaling                   true if scaling should be applied, false/nil otherwise.
-- applyAnchor                    true if anchoring should be applied, false/nil otherwise.
-- waitSecondsForLookupFrameName  optional. float with number of seconds to wait before looking up frame name, nil otherwise.
-- noHooks                        optional. true if no hooks should be applied to the frame directly, false/nil otherwise.
-- hookFnForFrame                 optional. individual function for hooking for frame, nil otherwise. parameters: TT_CacheForFrames, tip
-- waitSecondsForHooking          optional. float with number of seconds to wait before hooking for frame, nil otherwise.
-- isFromLibQTip                  optional. true if frame belongs to LibQTip, false/nil otherwise.
--
-- hint: determined frames will be added to TT_CacheForFrames with key as resolved real frame. The params will be added under ".config", the frame name under ".frameName".
TT_ExtendedConfig.tipsToModify = {
	[MOD_NAME] = {
		frames = {
			["GameTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["ShoppingTooltip1"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. This call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnHide", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ShoppingTooltip2"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. This call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnHide", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ItemRefTooltip"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- HOOK: DisplayDungeonScoreLink() to set class colors to backdrop border, see "ItemRef.lua"
					if (DisplayDungeonScoreLink) then
						hooksecurefunc("DisplayDungeonScoreLink", function(link)
							if (cfg.classColoredBorder) and (tip:IsShown()) then
								local splits = StringSplitIntoTable(":", link);
								
								-- bad link, return.
								if (not splits) then
									return;
								end
								
								local classID = splits[5];
								local classColor = LibFroznFunctions:GetClassColor(classID, 5);
								
								tt:SetBackdropBorderColorLocked(tip, classColor.r, classColor.g, classColor.b);
							end
						end);
					end
					
					-- HOOK: ItemRefTooltipMixin:ItemRefSetHyperlink() to adjust padding for close button if needed. additionally considering TextRight1 here.
					if (ItemRefTooltip.ItemRefSetHyperlink) then
						hooksecurefunc(ItemRefTooltip, "ItemRefSetHyperlink", function(self, link)
							-- get current display parameters
							local frameParams = TT_CacheForFrames[self];
							
							if (not frameParams) then
								return;
							end
							
							local currentDisplayParams = frameParams.currentDisplayParams;
							
							-- adjust padding for close button if needed. additionally considering TextRight1 here.
							local titleRight = _G[self:GetName() .. "TextRight1"];
							local titleLeft = _G[self:GetName() .. "TextLeft1"];
							
							if (titleRight) and (titleRight:GetText()) and (titleRight:GetRight() - self.CloseButton:GetLeft() > 0) or (titleLeft) and (titleLeft:GetRight() - self.CloseButton:GetLeft() > 0) then
								local xPadding = 16;
								currentDisplayParams.extraPaddingRightForCloseButton = xPadding;
								
								-- set padding to tip
								tt:SetPaddingToTip(self);
							end
						end);
					end
				end
			},
			["ItemRefShoppingTooltip1"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. This call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnHide", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ItemRefShoppingTooltip2"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. This call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnHide", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["EmbeddedItemTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["NamePlateTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["BattlePetTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["FloatingBattlePetTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["FloatingPetBattleAbilityTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["FriendsTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["QueueStatusFrame"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["QuestScrollFrame.StoryTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["QuestScrollFrame.CampaignTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["WorldMapTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			
			-- 3rd party addon tooltips
			["LibDBIconTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["AtlasLootTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["QuestHelperTooltip"] = { applyAppearance = true, applyAnchor = true, applyScaling = true },
			["QuestGuru_QuestWatchTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["PlaterNamePlateAuraTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		},
		hookFnForAddOn = function(TT_CacheForFrames)
			-- LibQTip-1.0, e.g. used by addon Broker_Location
			local LibQTip = LibStub("LibQTip-1.0", true);
			
			if (LibQTip) then
				local oldLibQTipAcquire = LibQTip.Acquire;
				
				LibQTip.Acquire = function(self, key, ...)
					local tooltip = oldLibQTipAcquire(self, key, ...);
					
					tt:AddModifiedTipExtended(tooltip, {
						applyAppearance = true,
						applyScaling = true,
						applyAnchor = false,
						noHooks = noHooks,
						isFromLibQTip = true
					});
					
					return tooltip;
				end
				
				-- disable error message on HookScript()
				LibQTip.tipPrototype.HookScript = nil;
			end
			
			-- LibDropdown-1.0, e.g used by addon Recount
			local LibDropdown = LibStub("LibDropdown-1.0", true);
			
			if (LibDropdown) then
				local oldLibDropdownOpenAce3Menu = LibDropdown.OpenAce3Menu;
				local LDDOAMBhooked = {};
				
				LibDropdown.OpenAce3Menu = function(self, t, parent, ...)
					local openMenu = oldLibDropdownOpenAce3Menu(self, t, parent, ...);
					
					if (openMenu) then
						local function hookLibDropdownButtons(frame)
							for _, button in ipairs(frame.buttons) do
								if (not LDDOAMBhooked[button]) then
									button:HookScript("OnEnter", function(button)
										local frame = button.groupFrame;
										
										if (not frame) then
											return;
										end
										
										tt:AddModifiedTip(frame);
										hookLibDropdownButtons(frame);
									end);
									
									LDDOAMBhooked[button] = true;
								end
							end
						end
						
						tt:AddModifiedTip(openMenu);
						hookLibDropdownButtons(openMenu);
					end
					
					return openMenu;
				end
			end
			
			-- LibDropdownMC-1.0, e.g used by addon Outfitter
			local LibDropdownMC = LibStub("LibDropdownMC-1.0", true);
			
			if (LibDropdownMC) then
				local oldLibDropdownMCOpenAce3Menu = LibDropdownMC.OpenAce3Menu;
				local LDDMCOAMBhooked = {};
				
				LibDropdownMC.OpenAce3Menu = function(self, t, parent, ...)
					local openMenu = oldLibDropdownMCOpenAce3Menu(self, t, parent, ...);
					
					if (openMenu) then
						local function hookLibDropdownMCButtons(frame)
							for _, button in ipairs(frame.buttons) do
								if (not LDDMCOAMBhooked[button]) then
									button:HookScript("OnEnter", function(button)
										local frame = button.groupFrame;
										
										if (not frame) then
											return;
										end
										
										tt:AddModifiedTip(frame);
										hookLibDropdownMCButtons(frame);
									end);
									
									LDDMCOAMBhooked[button] = true;
								end
							end
						end
						
						tt:AddModifiedTip(openMenu);
						hookLibDropdownMCButtons(openMenu);
					end
					
					return openMenu;
				end
			end
			
			-- HOOK: LFGListFrame.ApplicationViewer.ScrollBox:OnEnter() respectively LFGListApplicantMember_OnEnter() to set class colors to backdrop border, see "LFGList.lua"
			if (LFGListFrame) then
				local function LFGLFAVSB_OnEnter_Hook(self)
					if (cfg.classColoredBorder) and (GameTooltip:IsShown()) then
						local applicantID = self:GetParent().applicantID;
						local memberIdx = self.memberIdx;
						
						local name, classFile, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dungeonScore, pvpItemLevel = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx);
						
						if (name) then
							local classColor = LibFroznFunctions:GetClassColorByClassFile(classFile, "PRIEST");
							
							tt:SetBackdropBorderColorLocked(GameTooltip, classColor.r, classColor.g, classColor.b);
						end
					end
				end
				
				local LFGLFAVSBhooked = {};
				
				local function applyHooksToLFGLFAVSBFn(button, applicantID)
					local applicantInfo = C_LFGList.GetApplicantInfo(applicantID);
					
					for i = 1, applicantInfo.numMembers do
						local member = button.Members[i];
						
						if (not LFGLFAVSBhooked[member]) then
							member:HookScript("OnEnter", LFGLFAVSB_OnEnter_Hook);
							LFGLFAVSBhooked[member] = true;
						end
					end
				end
				
				local function applyHooksToLFGLFAVSBFn2(button, applicantID)
					if (button) then
						applyHooksToLFGLFAVSBFn(button, applicantID); -- see LFGListApplicationViewer_UpdateApplicant() in "LFGList.lua"
					else
						local self = LFGListFrame.ApplicationViewer; -- see LFGListApplicationViewer_UpdateResults() and LFGListApplicationViewer_OnEvent() in "LFGList.lua"
						if (self.applicants) then
							for index = 1, #self.applicants do
								local applicantID = self.applicants[index];
								local frame = self.ScrollBox:FindFrameByPredicate(function(frame, elementData)
									return elementData.id == applicantID;
								end);
								
								if (frame) then
									applyHooksToLFGLFAVSBFn(button, applicantID);
								end
							end
						end
					end
				end
				
				applyHooksToLFGLFAVSBFn2();
				hooksecurefunc("LFGListApplicationViewer_UpdateApplicant", applyHooksToLFGLFAVSBFn2);
				hooksecurefunc("LFGListApplicantMember_OnEnter", LFGLFAVSB_OnEnter_Hook);
			end
		end
	},
	["Blizzard_Collections"] = {
		frames = {
			["PetJournalPrimaryAbilityTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["PetJournalSecondaryAbilityTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		},
		hookFnForAddOn = function(TT_CacheForFrames)
			-- HOOK: SharedPetBattleAbilityTooltip_UpdateSize() to re-hook OnUpdate for PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip
			LibFroznFunctions:HookSecureFuncIfExists("SharedPetBattleAbilityTooltip_UpdateSize", function(self)
				-- re-hook OnUpdate for PetJournalPrimaryAbilityTooltip and PetJournalSecondaryAbilityTooltip to anchor tip to mouse position
				if (LibFroznFunctions:ExistsInTable(self, { PetJournalPrimaryAbilityTooltip, PetJournalSecondaryAbilityTooltip })) then
					tt:AnchorTipToMouseOnUpdate(self);
				end
			end);
		end
	},
	["Blizzard_Communities"] = {
		hookFnForAddOn = function(TT_CacheForFrames)
			-- CommunitiesFrame.MemberList
			--
			-- HOOK: CommunitiesFrame.MemberList:OnEnter() to set class colors to backdrop border
			hooksecurefunc(CommunitiesMemberListEntryMixin, "OnEnter", function(self)
				if (cfg.classColoredBorder) and (GameTooltip:IsShown()) then
					local classColor;
					local memberInfo = self.memberInfo;
					
					if (memberInfo) then
						local classID = memberInfo.classID;
						
						classColor = LibFroznFunctions:GetClassColor(classID, 5);
					else
						classColor = LibFroznFunctions:GetClassColor(5);
					end
					
					tt:SetBackdropBorderColorLocked(GameTooltip, classColor.r, classColor.g, classColor.b);
				end
			end);
		end
	},
	["Blizzard_Contribution"] = {
		frames = {
			["ContributionBuffTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		}
	},
	["Blizzard_EncounterJournal"] = {
		frames = {
			["EncounterJournalTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		}
	},
	["Blizzard_PerksProgram"] = {
		frames = {
			["PerksProgramTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		}
	},
	["Blizzard_PetBattleUI"] = {
		frames = {
			["PetBattlePrimaryUnitTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["PetBattlePrimaryAbilityTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		},
		hookFnForAddOn = function(TT_CacheForFrames)
			-- HOOK: PetBattleAbilityButton_OnEnter to re-anchor tooltip of pet ability buttons in bottom frame, so that they are anchored the same way like "switch pet" or "give up" button
			hooksecurefunc("PetBattleAbilityButton_OnEnter", function(self)
				if (PetBattlePrimaryAbilityTooltip:IsShown()) then
					PetBattlePrimaryAbilityTooltip:ClearAllPoints();
					PetBattlePrimaryAbilityTooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
				end
			end);
		end
	},
	
	-- 3rd party addon tooltips
	["RaiderIO"] = {
		frames = {
			["RaiderIO_ProfileTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = false, waitSecondsForLookupFrameName = 1 },
			["RaiderIO_SearchTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = false, waitSecondsForLookupFrameName = 1 }
		}
	}
};

for i = 1, UIDROPDOWNMENU_MAXLEVELS do -- see "UIDropDownMenu.lua"
	TT_ExtendedConfig.tipsToModify[MOD_NAME].frames["DropDownList" .. i] = { applyAppearance = true, applyScaling = false, applyAnchor = true }; -- #test: switch applyScaling from "false" to "true", but needed more coding to consider call of SetScale() in ToggleDropDownMenu() in "UIDropDownMenu.lua"
end

----------------------------------------------------------------------------------------------------
--                                           Variables                                            --
----------------------------------------------------------------------------------------------------

-- colors
local TT_COLOR = {
	text = {
		default = HIGHLIGHT_FONT_COLOR, -- white
		highlight = LIGHTYELLOW_FONT_COLOR,
		caption = NORMAL_FONT_COLOR, -- yellow
		chat = BRIGHTBLUE_FONT_COLOR,
		error = RED_FONT_COLOR
	},
	anchor = {
		backdrop = CreateColor(0.1, 0.1, 0.2, 1),
		backdropBorder = CreateColor(0.1, 0.1, 0.1, 1)
	}
};

-- tips to modify from other mods with TipTac:AddModifiedTip()
--
-- key = real frame
--
-- params: see params for 3rd key from "TT_ExtendedConfig.tipsToModify"
--
-- hint: frames will be added to TT_CacheForFrames. The params will be added under ".config", the frame name under ".frameName".
local TT_TipsToModifyFromOtherMods = {};

-- cache for frames
--
-- 1st key = real frame
--
-- params for 1st key:
-- frameName             frame name, nil for anonymous frames without a parent.
-- config                see params from "TT_ExtendedConfig.tipsToModify"
-- currentDisplayParams  current display parameters
-- gradient              optional. gradient texture for frame

-- params for 2nd key (currentDisplayParams):
-- isSet                                     true if current display parameters are set, false otherwise.
-- isSetTemporarily                          true if current display parameters are temporarily set, false otherwise.
--
-- isSetTimestamp                            timestamp of current display parameters were set, nil otherwise.
--
-- tipContent                                see TT_TIP_CONTENT
-- hideTip                                   true if tip will be hidden, false otherwise.
-- ignoreSetCurrentDisplayParamsOnTimestamp  timestamp of ignoring tooltip's current display parameters to be set, nil otherwise.
--
-- lockedBackdropInfo                        locked backdropInfo, nil otherwise.
-- lockedBackdropColor                       locked backdrop color, nil otherwise.
-- lockedBackdropBorderColor                 locked backdrop border color, nil otherwise.
--
-- extraPaddingRightForCloseButton           value for extra padding right to fit close button, nil otherwise.
-- extraPaddingBottomForBars                 value for extra padding bottom to fit health/power bars, nil otherwise.
--
-- defaultAnchored                           true if tip is default anchored, false otherwise.
-- defaultAnchoredParentFrame                tip's parent frame if default anchored, nil otherwise.
-- anchorFrameName                           anchor frame name of tip, values "WorldUnit", "WorldTip", "FrameUnit", "FrameTip"
-- anchorType                                anchor type for tip
-- anchorPoint                               anchor point for tip
--
-- unitRecord                                table with information about the displayed unit, nil otherwise.
--   .guid                                   guid of unit
--   .id                                     id of unit
--   .isPlayer                               true if it's a player unit, false for other units.
--   .name                                   name of unit
--   .nameWithTitle                          name with title of unit
--   .rpName                                 role play name of unit (Mary Sue Protocol)
--   .originalName                           original name of unit in GameTooltip
--
--   .className                              localized class name of unit, e.g. "Warrior" or "Guerrier"
--   .classFile                              locale-independent class file of unit, e.g. "WARRIOR"
--   .classID                                class id of unit
--
--   .reactionIndex                          unit reaction index, see LFF_UNIT_REACTION_INDEX
--   .health                                 unit health
--   .healthMax                              unit max health
--
--   .powerType                              unit power type
--   .power                                  unit power
--   .powerMax                               unit max power
--
--   .isColorBlind                           true if color blind mode is enabled, false otherwise.
--
-- timestampStartUnitAppearance              timestamp of start of unit appearance, nil otherwise.
-- timestampStartCustomUnitFadeout           timestamp of start of custom unit fadeout, nil otherwise.
--
-- tipLineInfoIndex                          line index of ttStyle's info for tip, nil otherwise.
-- tipLineTargetedByIndex                    line index of ttStyle's target by for tip, nil otherwise.
-- petLineLevelIndex                         line index of ttStyle's level for pet, nil otherwise.
--
-- hint: resolved frames from "TT_ExtendedConfig.tipsToModify" will be added here. frames from other mods added with TipTac:AddModifiedTip(tip, noHooks) will be added here, too.
local TT_CacheForFrames = {};

-- tip content
local TT_TIP_CONTENT = {
	unit = 1,
	aura = 2,
	spell = 3,
	item = 4,
	action = 5,
	others = 6,
	unknownOnShow = 7,
	unknownOnCleared = 8
};

-- others
local TT_IsConfigLoaded = false;
local TT_IsApplyTipAppearanceAndHooking = false;

----------------------------------------------------------------------------------------------------
--                                        Helper Functions                                        --
----------------------------------------------------------------------------------------------------

-- add message to (selected) chat frame
local replacementsForChatFrame = {
	["{highlight:"] = TT_COLOR.text.highlight:GenerateHexColorMarkup(),
	["{error:"] = TT_COLOR.text.error:GenerateHexColorMarkup(),
	["}"] = FONT_COLOR_CODE_CLOSE
};

function tt:AddMessageToChatFrame(message, ...)
	LibFroznFunctions:AddMessageToChatFrame(LibFroznFunctions:ReplaceText(message, replacementsForChatFrame, ...), TT_COLOR.text.chat:GetRGB());
end

----------------------------------------------------------------------------------------------------
--                                  Setup Frames - TipTac anchor                                  --
----------------------------------------------------------------------------------------------------

tt:SetSize(114, 24);
tt:SetBackdrop({
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 8,
	tileEdge = false,
	edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 }
});
tt:SetBackdropColor(TT_COLOR.anchor.backdrop:GetRGBA());
tt:SetBackdropBorderColor(TT_COLOR.anchor.backdropBorder:GetRGBA());
tt:SetMovable(true);
tt:EnableMouse(true);
tt:SetToplevel(true);
tt:SetClampedToScreen(true);
tt:SetPoint("CENTER");

tt.text = tt:CreateFontString(nil, "ARTWORK", "GameFontHighlight");
tt.text:SetText(MOD_NAME .. "Anchor");
tt.text:SetPoint("LEFT", 6, 0);

tt.close = CreateFrame("Button", nil, tt, "UIPanelCloseButton");
tt.close:SetSize(24, 24);
tt.close:SetPoint("RIGHT");

-- handlers
tt:SetScript("OnShow", function(self)
	cfg.left, cfg.top = self:GetLeft(), self:GetTop();
end);

tt:SetScript("OnMouseDown", function(self)
	self:StartMoving();
end);

tt:SetScript("OnMouseUp", function(self)
	self:StopMovingOrSizing();
	cfg.left, cfg.top = self:GetLeft(), self:GetTop();
end);

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnConfigLoaded = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- set position of TipTac anchor
		if (cfg.left) and (cfg.top) then
			tt:ClearAllPoints();
			tt:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cfg.left, cfg.top);
		end
	end
}, MOD_NAME .. " - TipTac anchor");

tt:Hide();

----------------------------------------------------------------------------------------------------
--                                          Setup Addon                                           --
----------------------------------------------------------------------------------------------------

-- EVENT: addon loaded
function tt:ADDON_LOADED(event, addOnName, containsBindings)
	if (TT_IsConfigLoaded) then
		-- apply config
		self:ApplyConfig();
		return;
	end
	
	-- not this addon
	if (addOnName ~= MOD_NAME) then
		return;
	end
	
	-- setup config
	self:SetupConfig();
	
	-- inform group that the config has been loaded
	TT_IsConfigLoaded = true;
	
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnConfigLoaded", TT_CacheForFrames, cfg, TT_ExtendedConfig);
end

-- EVENT: player login (one-time-event)
function tt:PLAYER_LOGIN(event)
	TT_IsApplyTipAppearanceAndHooking = true;
	
	-- apply config
	self:ApplyConfig();
	
	-- inform group that the tooltip's appearance and hooking needs to be applied
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnApplyTipAppearanceAndHooking", TT_CacheForFrames, cfg, TT_ExtendedConfig);
	
	-- cleanup
	self:UnregisterEvent(event);
	self[event] = nil;
end

-- register events
tt:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...);
end);

tt:RegisterEvent("ADDON_LOADED");
tt:RegisterEvent("PLAYER_LOGIN");

----------------------------------------------------------------------------------------------------
--                                         Custom Events                                          --
----------------------------------------------------------------------------------------------------

-- group events: TipTac (see MOD_NAME)
--
-- eventName                           description                                                 additional payload
-- ----------------------------------  ----------------------------------------------------------  ------------------------------------------------------------
-- OnConfigLoaded                      config has been loaded                                      TT_CacheForFrames, cfg, TT_ExtendedConfig
-- OnApplyConfig                       config settings needs to be applied                         TT_CacheForFrames, cfg, TT_ExtendedConfig
-- OnApplyTipAppearanceAndHooking      every tooltip's appearance and hooking needs to be applied  TT_CacheForFrames, cfg, TT_ExtendedConfig
--
-- OnTipAddedToCache                   tooltip has been added to cache for frames                  TT_CacheForFrames, tooltip
--
-- OnTipSetCurrentDisplayParams        tooltip's current display parameters has to be set          TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
-- OnTipPostSetCurrentDisplayParams    after tooltip's current display parameters has to be set    TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
--
-- OnTipSetHidden                      check if tooltip needs to be hidden                         TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
-- OnTipSetStyling                     tooltip's styling needs to be set                           TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
--
-- OnTipPreStyle                       before tooltip is being styled                              TT_CacheForFrames, tooltip, first
-- OnTipStyle                          tooltip is being styled                                     TT_CacheForFrames, tooltip, first
-- OnTipResize                         tooltip is being resized                                    TT_CacheForFrames, tooltip, first
-- OnTipPostStyle                      after tooltip has been styled and has the final size        TT_CacheForFrames, tooltip, first
--
-- OnTipResetCurrentDisplayParams      tooltip's current display parameters has to be reset        TT_CacheForFrames, tooltip, currentDisplayParams
-- OnTipPostResetCurrentDisplayParams  after tooltip's current display parameters has to be reset  TT_CacheForFrames, tooltip, currentDisplayParams
--
-- SetDefaultAnchorHook                hook for set default anchor to tip                          tooltip, parent
-- SetBackdropBorderColorLocked        set backdrop border color locked to tip                     tooltip, r, g, b, a

----------------------------------------------------------------------------------------------------
--                                       Interface Options                                        --
----------------------------------------------------------------------------------------------------

-- toggle options
function tt:ToggleOptions()
	local addOnName = MOD_NAME .. "Options";
	local loaded, reason = LoadAddOn(addOnName);
	
	if (loaded) then
		local TipTacOptions = _G[addOnName];
		TipTacOptions:SetShown(not TipTacOptions:IsShown());
	else
		tt:AddMessageToChatFrame(MOD_NAME .. ": {error:Couldn't open " .. MOD_NAME .. " Options: [{highlight:" .. _G["ADDON_" .. reason] .. "}]. Please make sure the addon is enabled in the character selection screen.}"); -- see UIParentLoadAddOn()
	end
end

-- register addon category
LibFroznFunctions:RegisterAddOnCategory((function()
	local frame = CreateFrame("Frame");
	
	frame:SetScript("OnShow", function(self)
		self.header = self:CreateFontString(nil, "ARTWORK");
		self.header:SetFontObject(GameFontNormalLarge);
		self.header:SetPoint("TOPLEFT", 16, -16);
		self.header:SetText(TT_COLOR.text.caption:WrapTextInColorCode(MOD_NAME));
		
		self.vers1 = self:CreateFontString(nil, "ARTWORK");
		self.vers1:SetFontObject(GameFontHighlight);
		self.vers1:SetJustifyH("LEFT");
		self.vers1:SetPoint("TOPLEFT", self.header, "BOTTOMLEFT", 0, -8);
		self.vers1:SetText(TT_COLOR.text.highlight:WrapTextInColorCode(MOD_NAME .. ": \nWoW: "));
		
		self.vers2 = self:CreateFontString(nil, "ARTWORK");
		self.vers2:SetFontObject(GameFontHighlight);
		self.vers2:SetJustifyH("LEFT");
		self.vers2:SetPoint("TOPLEFT", self.vers1, "TOPRIGHT");
		self.vers2:SetText(LibFroznFunctions:GetAddOnMetadata(MOD_NAME, "Version") .. "\n" .. GetBuildInfo());
		
		self.notes = self:CreateFontString(nil, "ARTWORK");
		self.notes:SetFontObject(GameFontHighlight);
		self.notes:SetPoint("TOPLEFT", self.vers1, "BOTTOMLEFT", 0, -8);
		self.notes:SetText(LibFroznFunctions:GetAddOnMetadata(MOD_NAME, "Notes"));
		
		self.btnOptions = CreateFrame("Button", nil, self, "UIPanelButtonTemplate");
		self.btnOptions:SetPoint("TOPLEFT", self.notes, "BOTTOMLEFT", -2, -8);
		self.btnOptions:SetText(GAMEOPTIONS_MENU);
		self.btnOptions:SetWidth(math.max(120, self.btnOptions:GetTextWidth() + 20));
		self.btnOptions:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self.btnOptions, "ANCHOR_RIGHT");
			GameTooltip:SetText("Slash commands");
			GameTooltip:AddLine(TT_COLOR.text.default:WrapTextInColorCode("/tip\n/tiptac"), nil, nil, nil, true);
			GameTooltip:Show();
		end);
		self.btnOptions:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end);
		self.btnOptions:SetScript("OnClick", function()
			tt:ToggleOptions();
		end);
		
		-- cleanup
		self:SetScript("OnShow", nil);
	end);
	
	frame:Hide();
	
	return frame;
end)(), MOD_NAME);

-- addon compartment
function TipTac_OnAddonCompartmentClick(addonName, mouseButton)
	-- toggle options
	tt:ToggleOptions();
end

function TipTac_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	GameTooltip:SetText(MOD_NAME);
	GameTooltip:AddLine(TT_COLOR.text.default:WrapTextInColorCode("Click to toggle options"));
	GameTooltip:Show();
end

function TipTac_OnAddonCompartmentLeave(addonName, button)
	GameTooltip:Hide();
end

-- register new slash commands
LibFroznFunctions:RegisterNewSlashCommands(MOD_NAME, { "/tip", "/tiptac" }, function(msg)
	-- extract parameters
	local parameters = LibFroznFunctions:CreatePushArray();
	
	for parameter in tostring(msg):gmatch("([^%s]+)") do
		parameters:Push(parameter:lower());
	end
	
	-- toggle options
	if (parameters:GetCount() == 0) then
		tt:ToggleOptions();
		return;
	end
	
	-- show TipTac anchor
	if (parameters[1] == "anchor") then
		tt:SetShown(not tt:IsShown());
		return;
	end
	
	-- reset settings
	if (parameters[1] == "reset") then
		wipe(cfg);
		tt:ApplyConfig();
		tt:AddMessageToChatFrame(MOD_NAME .. ": All {highlight:" .. MOD_NAME .. "} settings has been reset to their default values.");
		return;
	end
	
	-- invalid command
	local version, build = GetBuildInfo();
	
	UpdateAddOnMemoryUsage();
	
	tt:AddMessageToChatFrame("----- {highlight:%s %s} ----- {highlight:%.2f kb} ----- {highlight:WoW " .. version .. "} ----- ", MOD_NAME, LibFroznFunctions:GetAddOnMetadata(MOD_NAME, "Version"), GetAddOnMemoryUsage(MOD_NAME));
	tt:AddMessageToChatFrame("The following {highlight:parameters} are valid for this addon:");
	tt:AddMessageToChatFrame("  {highlight:anchor} = Shows the anchor where the tooltip appears");
	tt:AddMessageToChatFrame("  {highlight:reset} = Resets all settings back to their default values");
end);

----------------------------------------------------------------------------------------------------
--                                      Pixel Perfect Scale                                       --
----------------------------------------------------------------------------------------------------

-- get nearest pixel size (e.g. to avoid 1-pixel borders which are sometimes 0/2-pixels wide)
local TT_PhysicalScreenWidth, TT_PhysicalScreenHeight, TT_UIUnitFactor, TT_UIScale, TT_MouseOffsetX, TT_MouseOffsetY;

function tt:GetNearestPixelSize(size, pixelPerfect)
	local currentConfig = TT_IsConfigLoaded and cfg or TT_DefaultConfig;
	local realSize = ((pixelPerfect and (size * TT_UIUnitFactor)) or size);
	
	return PixelUtil.GetNearestPixelSize(realSize, 1) / TT_UIScale / currentConfig.gttScale;
end

-- update pixel perfect scale
function tt:UpdatePixelPerfectScale()
	local currentConfig = TT_IsConfigLoaded and cfg or TT_DefaultConfig;
	
	TT_PhysicalScreenWidth, TT_PhysicalScreenHeight = GetPhysicalScreenSize();
	TT_UIUnitFactor = 768.0 / TT_PhysicalScreenHeight;
	TT_UIScale = UIParent:GetEffectiveScale();
	TT_MouseOffsetX, TT_MouseOffsetY = self:GetNearestPixelSize(currentConfig.mouseOffsetX), self:GetNearestPixelSize(currentConfig.mouseOffsetY);
end

tt:UpdatePixelPerfectScale();

-- EVENT: UI scale changed
function tt:UI_SCALE_CHANGED(event)
	self:ApplyConfig();
end

-- HOOK: UIParent scale changed
hooksecurefunc(UIParent, "SetScale", function()
	tt:ApplyConfig();
end);

-- EVENT: display size changed
function tt:DISPLAY_SIZE_CHANGED(event)
	self:ApplyConfig();
end

-- register events
tt:RegisterEvent("UI_SCALE_CHANGED");
tt:RegisterEvent("DISPLAY_SIZE_CHANGED");

----------------------------------------------------------------------------------------------------
--                                          Setup Config                                          --
----------------------------------------------------------------------------------------------------

-- setup config
function tt:SetupConfig()
	-- update default config for fonts
	TT_DefaultConfig.fontFace, TT_DefaultConfig.fontSize, TT_DefaultConfig.fontFlags = GameFontNormal:GetFont();
	TT_DefaultConfig.fontSize = math.floor(TT_DefaultConfig.fontSize + 0.5);
	TT_DefaultConfig.fontFlags = TT_DefaultConfig.fontFlags:match("^[^,]*");
	
	TT_DefaultConfig.barFontFace, TT_DefaultConfig.barFontSize, TT_DefaultConfig.barFontFlags = NumberFontNormalSmall:GetFont();
	TT_DefaultConfig.barFontSize = math.floor(TT_DefaultConfig.barFontSize + 0.5);
	TT_DefaultConfig.barFontFlags = TT_DefaultConfig.barFontFlags:match("^[^,]*");

	-- set config
	if (not TipTac_Config) then
		-- create config
		TipTac_Config = {};
	end
	
	cfg = LibFroznFunctions:ChainTables(TipTac_Config, TT_DefaultConfig);

	-- show TipTac anchor if no position for it is set
	if (not cfg.left) or (not cfg.top) then
		self:Show();
	end
	
	-- set tooltip backdrop config
	self:SetTipBackdropConfig();
end

-- set tooltip backdrop config (examples see "Backdrop.lua")
function tt:SetTipBackdropConfig()
	local currentConfig = TT_IsConfigLoaded and cfg or TT_DefaultConfig;
	
	if (currentConfig.tipBackdropBG == "nil") then
		TT_ExtendedConfig.tipBackdrop.bgFile = nil;
	else
		TT_ExtendedConfig.tipBackdrop.bgFile = currentConfig.tipBackdropBG;
	end
	if (currentConfig.tipBackdropEdge == "nil") then
		TT_ExtendedConfig.tipBackdrop.edgeFile = nil;
	else
		TT_ExtendedConfig.tipBackdrop.edgeFile = currentConfig.tipBackdropEdge;
	end
	
	local edgeSize = ((currentConfig.pixelPerfectBackdrop and self:GetNearestPixelSize(currentConfig.backdropEdgeSize, true)) or currentConfig.backdropEdgeSize);
	TT_ExtendedConfig.tipBackdrop.edgeSize = edgeSize;
	
	local insets = ((currentConfig.pixelPerfectBackdrop and self:GetNearestPixelSize(currentConfig.backdropInsets, true)) or currentConfig.backdropInsets);
	TT_ExtendedConfig.tipBackdrop.insets.left = insets;
	TT_ExtendedConfig.tipBackdrop.insets.right = insets;
	TT_ExtendedConfig.tipBackdrop.insets.top = insets;
	TT_ExtendedConfig.tipBackdrop.insets.bottom = insets;
	
	TT_ExtendedConfig.backdropColor:SetRGBA(unpack(currentConfig.tipColor));
	TT_ExtendedConfig.backdropBorderColor:SetRGBA(unpack(currentConfig.tipBorderColor));
	
	-- set tooltip padding config for GameTooltip
	self:SetTipPaddingConfig();
end

-- set tooltip padding config for GameTooltip
function tt:SetTipPaddingConfig()
	local currentConfig = TT_IsConfigLoaded and cfg or TT_DefaultConfig;
	
	if (currentConfig.enableBackdrop) then
		TT_ExtendedConfig.tipPaddingForGameTooltip.right, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom, TT_ExtendedConfig.tipPaddingForGameTooltip.left, TT_ExtendedConfig.tipPaddingForGameTooltip.top = TT_ExtendedConfig.tipBackdrop.insets.right + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.bottom + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.left + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.top + TT_ExtendedConfig.tipPaddingForGameTooltip.offset;
		
		if (LibFroznFunctions.isWoWFlavor.ClassicEra) or (LibFroznFunctions.isWoWFlavor.BCC) or (LibFroznFunctions.isWoWFlavor.WotLKC) then
			TT_ExtendedConfig.tipPaddingForGameTooltip.left = 0;
			TT_ExtendedConfig.tipPaddingForGameTooltip.top = 0;
		end
	else
		TT_ExtendedConfig.tipPaddingForGameTooltip.right, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom, TT_ExtendedConfig.tipPaddingForGameTooltip.left, TT_ExtendedConfig.tipPaddingForGameTooltip.top = 0, 0, 0, 0;
	end
end

----------------------------------------------------------------------------------------------------
--                                          Apply Config                                          --
----------------------------------------------------------------------------------------------------

function tt:ApplyConfig()
	-- update pixel perfect scale
	self:UpdatePixelPerfectScale();
	
	-- set tooltip backdrop config
	self:SetTipBackdropConfig();
	
	-- not ready to apply tip appearance and hooking
	if (not TT_IsApplyTipAppearanceAndHooking) then
		return;
	end;
	
	-- set font to GameTooltip
	self:SetFontToGameTooltip();
	
	-- set appearance to tip
	for tip, frameParams in pairs(TT_CacheForFrames) do
		self:SetAppearanceToTip(tip);
	end
	
	-- resolve tips to modify to determine the real frame
	self:ResolveTipsToModify();
	
	-- unregister event "ADDON_LOADED" if all tips to modify are resolved
	if (LibFroznFunctions:IsTableEmpty(TT_ExtendedConfig.tipsToModify)) then
		self:UnregisterEvent("ADDON_LOADED");
	end
	
	-- inform group that the config has been applied
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnApplyConfig", TT_CacheForFrames, cfg, TT_ExtendedConfig);
end

-- set font to GameTooltip
function tt:SetFontToGameTooltip()
	-- remember original GameTooltip fonts
	if (not TT_ExtendedConfig.oldGameTooltipFontsRemembered) then
		TT_ExtendedConfig.oldGameTooltipText.fontFace, TT_ExtendedConfig.oldGameTooltipText.fontSize, TT_ExtendedConfig.oldGameTooltipText.fontFlags = GameTooltipText:GetFont();
		TT_ExtendedConfig.oldGameTooltipHeaderText.fontFace, TT_ExtendedConfig.oldGameTooltipHeaderText.fontSize, TT_ExtendedConfig.oldGameTooltipHeaderText.fontFlags = GameTooltipHeaderText:GetFont();
		TT_ExtendedConfig.oldGameTooltipTextSmall.fontFace, TT_ExtendedConfig.oldGameTooltipTextSmall.fontSize, TT_ExtendedConfig.oldGameTooltipTextSmall.fontFlags = GameTooltipTextSmall:GetFont();
		
		TT_ExtendedConfig.oldGameTooltipFontsRemembered = true;
	end
	
	-- set font to GameTooltip
	if (cfg.modifyFonts) then
		-- set default font if font in config is not valid
		if (not LibFroznFunctions:FontExists(cfg.fontFace)) then
			cfg.fontFace = nil;
			self:AddMessageToChatFrame(MOD_NAME .. ": {error:No valid Font set in option tab {highlight:Font}. Switching to default Font.}");
		end
		
		-- set font to GameTooltip
		GameTooltipText:SetFont(cfg.fontFace, cfg.fontSize, cfg.fontFlags);
		GameTooltipHeaderText:SetFont(cfg.fontFace, cfg.fontSize + cfg.fontSizeDeltaHeader, cfg.fontFlags);
		GameTooltipTextSmall:SetFont(cfg.fontFace, cfg.fontSize + cfg.fontSizeDeltaSmall, cfg.fontFlags);
	else
		if (LibFroznFunctions:FontExists(TT_ExtendedConfig.oldGameTooltipText.fontFace)) then
			GameTooltipText:SetFont(TT_ExtendedConfig.oldGameTooltipText.fontFace, TT_ExtendedConfig.oldGameTooltipText.fontSize, TT_ExtendedConfig.oldGameTooltipText.fontFlags);
		end
		if (LibFroznFunctions:FontExists(TT_ExtendedConfig.oldGameTooltipHeaderText.fontFace)) then
			GameTooltipHeaderText:SetFont(TT_ExtendedConfig.oldGameTooltipHeaderText.fontFace, TT_ExtendedConfig.oldGameTooltipHeaderText.fontSize, TT_ExtendedConfig.oldGameTooltipHeaderText.fontFlags);
		end
		if (LibFroznFunctions:FontExists(TT_ExtendedConfig.oldGameTooltipTextSmall.fontFace)) then
			GameTooltipTextSmall:SetFont(TT_ExtendedConfig.oldGameTooltipTextSmall.fontFace, TT_ExtendedConfig.oldGameTooltipTextSmall.fontSize, TT_ExtendedConfig.oldGameTooltipTextSmall.fontFlags);
		end
	end
	
	-- recalculate size of GameTooltip to ensure that it has the correct dimensions e.g. if enabling/disabling "Font->Modify the GameTooltip Font Templates"
	LibFroznFunctions:RecalculateSizeOfGameTooltip(GameTooltip);
end

-- set appearance to tip
function tt:SetAppearanceToTip(tip)
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set appearance to tip not possible
	if (not tipParams.applyAppearance) then
		return;
	end
	
	-- set scale, gradient and backdrop to tip
	self:SetScaleToTip(tip);
	self:SetGradientToTip(tip);
	self:SetBackdropToTip(tip);
end

-- resolve tips to modify to determine the real frame
function tt:ResolveTipsToModify()
	-- not ready to apply tip appearance and hooking
	if (not TT_IsApplyTipAppearanceAndHooking) then
		return;
	end;
	
	-- tips to modify
	for addOnName, addOnConfig in pairs(TT_ExtendedConfig.tipsToModify) do
		if (LibFroznFunctions:IsAddOnFinishedLoading(addOnName)) then
			if (addOnConfig.frames) then
				for frameName, tipParams in pairs(addOnConfig.frames) do
					LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForLookupFrameName, function()
						-- lookup the global object for this frame name
						local tip = LibFroznFunctions:GetValueFromObjectByPath(_G, frameName);
						
						-- add tip to cache
						tt:AddTipToCache(tip, frameName, tipParams);
					end);
				end
				
				-- remove frames from addon config
				wipe(addOnConfig.frames);
			end
			
			-- apply hooks for addon
			if (addOnConfig.hookFnForAddOn) then
				LibFroznFunctions:CallFunctionDelayed(addOnConfig.waitSecondsForHooking, function()
					addOnConfig.hookFnForAddOn(TT_CacheForFrames);
				end);
			end
			
			-- remove addon config from tips to modify
			wipe(addOnConfig);
			TT_ExtendedConfig.tipsToModify[addOnName] = nil;
		end
	end
	
	-- tips to modify from other mods with TipTac:AddModifiedTip()
	for tip, tipParams in pairs(TT_TipsToModifyFromOtherMods) do
		-- add tip to cache
		self:AddTipToCache(tip, tip:GetDebugName(), tipParams);
	end
	
	-- remove frames from tips to modify from other mods with TipTac:AddModifiedTip()
	wipe(TT_TipsToModifyFromOtherMods);
end

-- add tip to cache
function tt:AddTipToCache(tip, frameName, tipParams)
	-- not ready to apply tip appearance and hooking
	if (not TT_IsApplyTipAppearanceAndHooking) then
		return;
	end;
	
	-- check if frame hasn't been resolved or frame already exists in cache for frames
	if (type(tip) ~= "table") or (type(tip.GetObjectType) ~= "function") or (TT_CacheForFrames[tip]) then
		return;
	end
	
	-- add tip to cache
	TT_CacheForFrames[tip] = {
		frameName = frameName,
		config = ((type(tipParams) == "table") and tipParams or {}),
		currentDisplayParams = {
			isSet = false
		}
	};
	
	-- apply BackdropTemplate to real frame
	if (tipParams.applyAppearance) and (BackdropTemplateMixin) then
		-- Mixin(tip, BackdropTemplateMixin);
		LibFroznFunctions:MixinDifferingObjects(tip, BackdropTemplateMixin);
		
		if (not tipParams.noHooks) then
			LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
				-- tip:HookScript("OnSizeChanged", function(tip, ...)
					-- tip.OnBackdropSizeChanged(tip, ...);
				-- end);
				tip:HookScript("OnSizeChanged", tip.OnBackdropSizeChanged);
			end);
		end
		
		if (tip.NineSlice) then
			-- Mixin(tip.NineSlice, BackdropTemplateMixin);
			LibFroznFunctions:MixinDifferingObjects(tip.NineSlice, BackdropTemplateMixin);
		end
	end
	
	-- set appearance to tip
	self:SetAppearanceToTip(tip);
	
	-- apply hooks for frame to set/reset current display parameters
	self:ResetCurrentDisplayParams(tip);
	
	if (not tipParams.noHooks) then
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			tip:HookScript("OnShow", function(tip)
				tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unknownOnShow);
			end);
			
			if (tip:GetObjectType() == "GameTooltip") then
				hooksecurefunc(tip, "SetUnit", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unit);
				end);
				hooksecurefunc(tip, "SetUnitAura", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				hooksecurefunc(tip, "SetUnitBuff", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				hooksecurefunc(tip, "SetUnitDebuff", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnitBuffByAuraInstanceID", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnitDebuffByAuraInstanceID", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				LibFroznFunctions:HookScriptOnTooltipSetUnit(tip, function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unit);
				end);
				LibFroznFunctions:HookScriptOnTooltipSetItem(tip, function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.item);
				end);
				LibFroznFunctions:HookScriptOnTooltipSetSpell(tip, function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.spell);
				end);
				hooksecurefunc(tip, "SetAction", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.action);
				end);
				hooksecurefunc(tip, "SetHyperlink", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.others);
				end);
				
				tip:HookScript("OnTooltipCleared", function(tip)
					if (tip:IsShown()) and (tip:GetObjectType() == "GameTooltip") and (tip.shouldRefreshData) then
						return;
					end
					
					tt:ResetCurrentDisplayParams(tip);
					
					if (tip:IsShown()) then
						tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unknownOnCleared);
					end
				end);
			end
			
			tip:HookScript("OnHide", function(tip)
				tt:ResetCurrentDisplayParams(tip);
			end);
		end);
	end
	
	-- apply individual function for hooking for frame
	if (tipParams.hookFnForFrame) then
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			tipParams.hookFnForFrame(TT_CacheForFrames, tip);
		end);
	end
	
	-- apply hooks for frame to add a color locking feature for ApplyBackdrop, SetBackdrop, ClearBackdrop, SetBackdropColor, SetBackdropBorderColor, SetCenterColor and SetBorderColor
	LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
		tt:ApplyColorLockingFeature(tip);
	end);
	
	-- inform group that the tip has been added to cache for frames
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipAddedToCache", TT_CacheForFrames, tip);
end

-- set tip's current display parameters
function tt:SetCurrentDisplayParams(tip, tipContent)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- ignore setting tip's current display parameters on timestamp
	local currentTime = GetTime();
	
	if (currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp == currentTime) then
		return;
	end
	
	currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp = nil;
	
	-- consider missing reset of tip's current display parameters, e.g. if hovering over unit auras which will be hidden. there will be subsequent calls of GameTooltip:SetUnitAura() without a new GameTooltip:OnShow().
	if ((currentDisplayParams.isSet) or (currentDisplayParams.isSetTemporarily)) and (currentDisplayParams.isSetTimestamp ~= currentTime) then
		self:ResetCurrentDisplayParams(tip, true);
	end
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		self:HideTip(tip);
		return;
	end
	
	-- current display parameters are already set
	local tipContentUnknown = LibFroznFunctions:ExistsInTable(tipContent, { TT_TIP_CONTENT.unknownOnShow, TT_TIP_CONTENT.unknownOnCleared });
	
	if (currentDisplayParams.isSet) or (currentDisplayParams.isSetTemporarily) and (tipContentUnknown) then
		-- consider tip content "action" firing after e.g. "spell" or "item" to check if the tip needs to be hidden
		if (currentDisplayParams.isSet) and (currentDisplayParams.tipContent ~= TT_TIP_CONTENT.action) and (tipContent == TT_TIP_CONTENT.action) then
			-- inform group that the tip has to be checked if it needs to be hidden
			LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetHidden", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
			
			-- tip will be hidden
			if (currentDisplayParams.hideTip) then
				self:HideTip(tip);
				return;
			end
		end
		
		return;
	end
	
	-- set tip content
	currentDisplayParams.tipContent = tipContent;
	
	-- inform group that the tip's current display parameters has to be set
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetCurrentDisplayParams", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipPostSetCurrentDisplayParams", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
	
	if (tipContentUnknown) then
		currentDisplayParams.isSetTemporarily = true;
	else
		currentDisplayParams.isSet = true;
	end
	
	currentDisplayParams.isSetTimestamp = currentTime;
	
	-- inform group that the tip has to be checked if it needs to be hidden
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetHidden", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		self:HideTip(tip);
		return;
	end
	
	-- inform group that the tip's styling needs to be set
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetStyling", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
end

-- reset tip's current display parameters
function tt:ResetCurrentDisplayParams(tip, noFireGroupEvent)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- current display parameters are already resetted
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	if (not currentDisplayParams.isSet) and (not currentDisplayParams.isSetTemporarily) then
		return;
	end
	
	-- inform group that the tip's current display parameters has to be reset
	if (not noFireGroupEvent) then
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipResetCurrentDisplayParams", TT_CacheForFrames, tip, frameParams.currentDisplayParams);
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipPostResetCurrentDisplayParams", TT_CacheForFrames, tip, frameParams.currentDisplayParams);
	end
	
	currentDisplayParams.isSet = false;
	currentDisplayParams.isSetTemporarily = false;
	
	currentDisplayParams.isSetTimestamp = nil;
	
	currentDisplayParams.hideTip = false;
end

-- hide tip
function tt:HideTip(tip)
	if (tip:IsShown()) then
		tip:Hide();
		TT_CacheForFrames[tip].currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp = GetTime();
	end
end

-- set scale to tip
function tt:SetScaleToTip(tip)
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set scale to tip not possible
	if (not tipParams.applyAppearance) or (not tipParams.applyScaling) then
		return;
	end
	
	-- calculate new scale for tip
	local tipScale = tip:GetScale();
	local tipEffectiveScale = tip:GetEffectiveScale();
	
	local newTipScale = cfg.gttScale * TT_UIScale / (tipEffectiveScale / tipScale); -- consider applied SetIgnoreParentScale() on tip regarding scaling
	local newTipEffectiveScale = tipEffectiveScale * newTipScale / tipScale;
	
	-- reduce scale if tip exceeds UIParent width/height
	if (tipParams.isFromLibQTip) then
		local LibQTip = LibStub("LibQTip-1.0", true);
		
		if (LibQTip) then
			LibQTip.layoutCleaner:CleanupLayouts();
		end
	end
	
	local tipWidthWithNewScaling = tip:GetWidth() * newTipEffectiveScale;
	local tipHeightWithNewScaling = tip:GetHeight() * newTipEffectiveScale;
	
	local UIParentWidth = UIParent:GetWidth() * TT_UIScale;
	local UIParentHeight = UIParent:GetHeight() * TT_UIScale;
	
	if (tipWidthWithNewScaling > UIParentWidth) or (tipHeightWithNewScaling > UIParentHeight) then
        newTipScale = newTipScale / math.max(tipWidthWithNewScaling / UIParentWidth, tipHeightWithNewScaling / UIParentHeight) * 0.95; -- 95% of maximum UIParent width/height
	end
	
	-- set scale to tip
	tip:SetScale(newTipScale);
end

-- set gradient to tip
function tt:SetGradientToTip(tip)
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set gradient to tip not possible
	local gradientForFrame = frameParams.gradient;
	
	if (not cfg.enableBackdrop) or (not cfg.gradientTip) or (not tipParams.applyAppearance) or (not tipParams.applyAppearance) then
		if (gradientForFrame) then
			gradientForFrame:Hide();
		end
		
		return;
	end
	
	-- create gradient if it doesn't already exist for the frame
	if (not gradientForFrame) then
		gradientForFrame = tip:CreateTexture();
		
		if (gradientForFrame.SetGradientAlpha) then -- before df 10.0.0
			gradientForFrame:SetColorTexture(1, 1, 1, 1);
		elseif (gradientForFrame.SetGradient) then -- since df 10.0.0
			gradientForFrame:SetColorTexture(1, 1, 1, 1);
		else -- general fallback
			gradientForFrame:SetTexture("Interface\\AddOns\\" .. MOD_NAME .. "\\media\\gradient");
		end
		
		frameParams.gradient = gradientForFrame;
	end
	
	-- set gradient to tip
	if (gradientForFrame.SetGradientAlpha) then -- before df 10.0.0
		gradientForFrame:SetGradientAlpha("VERTICAL", 0, 0, 0, 0, unpack(cfg.gradientColor));
	elseif (gradientForFrame.SetGradient) then -- since df 10.0.0
		gradientForFrame:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(unpack(cfg.gradientColor)));
	else
		gradientForFrame:SetVertexColor(unpack(cfg.gradientColor));
	end
	
	gradientForFrame:SetPoint("TOPLEFT", TT_ExtendedConfig.tipBackdrop.insets.left, -TT_ExtendedConfig.tipBackdrop.insets.top);
	gradientForFrame:SetPoint("BOTTOMRIGHT", tip, "TOPRIGHT", -TT_ExtendedConfig.tipBackdrop.insets.right, -cfg.gradientHeight);
	
	gradientForFrame:Show();
end

-- add modified tip from other mods. they can "register" tooltips or frames to be modified by TipTac.
function tt:AddModifiedTip(tipNameOrFrame, noHooks)
	self:AddModifiedTipExtended(tipNameOrFrame, {
		applyAppearance = true,
		applyScaling = true,
		applyAnchor = false,
		noHooks = noHooks
	});
end

-- add modified tip extended from other mods. they can "register" tooltips or frames to be modified by TipTac.
--
-- tipParams: see params for 3rd key from "TT_ExtendedConfig.tipsToModify"
function tt:AddModifiedTipExtended(tipNameOrFrame, tipParams)
	local tip;
	
	if (type(tipNameOrFrame) == "string") then
		-- lookup the global object for this frame name
		tip = LibFroznFunctions:GetValueFromObjectByPath(_G, tipNameOrFrame);
	else
		tip = tipNameOrFrame;
	end
	
	-- check if frame hasn't been resolved or frame already exists in cache for frames
	if (type(tip) ~= "table") or (type(tip.GetObjectType) ~= "function") or (TT_CacheForFrames[tip]) then
		return;
	end
	
	-- add tip to tips to modify from other mods with TipTac:AddModifiedTip()
	TT_TipsToModifyFromOtherMods[tip] = tipParams;
	
	-- apply config
	self:ApplyConfig();
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- reapply scale to tip
		tt:SetScaleToTip(tip);
	end
}, MOD_NAME .. " - Apply Config");

----------------------------------------------------------------------------------------------------
--                                        Tooltip Backdrop                                        --
----------------------------------------------------------------------------------------------------

-- set backdrop to tip
--
-- use isSettingBackdropToTip to prevent endless loop when calling tt:SetBackdropToTip()
local isSettingBackdropToTip = false;

function tt:SetBackdropToTip(tip)
	-- check if we're already setting backdrop to tip
	if (isSettingBackdropToTip) then
		return;
	end
	
	isSettingBackdropToTip = false;
	
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set backdrop to tip not possible
	if (not cfg.enableBackdrop) or (not tipParams.applyAppearance) then
		return;
	end
	
	-- remove default tip backdrop
	if (tip.NineSlice) then
		LibFroznFunctions:StripTextures(tip.NineSlice);
		
		tip.NineSlice.layoutType = nil;
		tip.NineSlice.layoutTextureKit = nil;
		tip.NineSlice.backdropInfo = nil;
	end
	
	tip.layoutType = nil;
	tip.layoutTextureKit = nil;
	tip.backdropInfo = nil;
	
	-- workaround for addon MerathilisUI in ElvUI to prevent styling of frame
	local isAddOnElvUI_MerathilisUILoaded = LibFroznFunctions:IsAddOnFinishedLoading("ElvUI_MerathilisUI");
	
	if (isAddOnElvUI_MerathilisUILoaded) then
		tip.__shadow = true;
		tip.__MERSkin = true;
	end
	
	-- extra handling of blizzard drop down list
	local tipName = tip:GetName();
	
	if (tipName) and (tipName:match("DropDownList(%d+)")) then
		local dropDownListBackdrop = _G[tipName.."Backdrop"];
		local dropDownListMenuBackdrop = _G[tipName.."MenuBackdrop"];
		
		LibFroznFunctions:StripTextures(dropDownListBackdrop);
		if (dropDownListBackdrop.Bg) then
			dropDownListBackdrop.Bg:SetTexture(nil);
			dropDownListBackdrop.Bg:SetAtlas(nil);
		end
		LibFroznFunctions:StripTextures(dropDownListMenuBackdrop.NineSlice);
		
		-- workaround for addon ElvUI to prevent applying of frame:StripTextures()
		local isAddOnElvUILoaded = LibFroznFunctions:IsAddOnFinishedLoading("ElvUI");
		
		if (isAddOnElvUILoaded) then
			tip.template = "Default";
			dropDownListBackdrop.template = "Default";
			dropDownListMenuBackdrop.template = "Default";
		end
		
		-- workaround for addon MerathilisUI in ElvUI to prevent styling of frame
		if (isAddOnElvUI_MerathilisUILoaded) then
			dropDownListBackdrop.__MERSkin = true;
			dropDownListMenuBackdrop.__MERSkin = true;
		end
	end
	
	-- set backdrop to tip
	isSettingBackdropToTip = true;
	self:SetBackdropLocked(tip, TT_ExtendedConfig.tipBackdrop);
	isSettingBackdropToTip = false;
	
	-- set backdrop and backdrop border color to tip
	self:SetBackdropAndBackdropBorderColorToTip(tip)
	
	-- set padding to tip
	self:SetPaddingToTip(tip);
end

-- set backdrop and backdrop border color to tip
--
-- use isSettingBackdropAndBackdropBorderColorToTip to prevent endless loop when calling tt:isSettingBackdropAndBackdropBorderColorToTip()
local isSettingBackdropAndBackdropBorderColorToTip = false;

function tt:SetBackdropAndBackdropBorderColorToTip(tip)
	-- check if we're already setting backdrop to tip
	if (isSettingBackdropAndBackdropBorderColorToTip) then
		return;
	end
	
	isSettingBackdropAndBackdropBorderColorToTip = false;
	
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set backdrop to tip not possible
	if (not cfg.enableBackdrop) or (not tipParams.applyAppearance) then
		return;
	end
	
	-- set backdrop and backdrop border color to tip
	local backdropColor = frameParams.currentDisplayParams.lockedBackdropColor and frameParams.currentDisplayParams.lockedBackdropColor or TT_ExtendedConfig.backdropColor;
	local backdropBorderColor = frameParams.currentDisplayParams.lockedBackdropBorderColor and frameParams.currentDisplayParams.lockedBackdropBorderColor or TT_ExtendedConfig.backdropBorderColor;
	
	isSettingBackdropAndBackdropBorderColorToTip = true;
	self:SetBackdropColorLocked(tip, backdropColor:GetRGBA());
	self:SetBackdropBorderColorLocked(tip, backdropBorderColor:GetRGBA());
	isSettingBackdropAndBackdropBorderColorToTip = false;
end

-- set padding to tip, so that the tooltip text is still in the center piece, see GameTooltip_CalculatePadding() in "GameTooltip.lua"
--
-- use isSettingPaddingToTip to prevent endless loop when calling tt:SetPaddingToTip()
local isSettingPaddingToTip = false;
 
function tt:SetPaddingToTip(tip)
	-- check if we're already setting padding to tip
	if (isSettingPaddingToTip) then
		return;
	end
	
	isSettingPaddingToTip = false;
	
	-- SetPadding() isn't available for e.g. BattlePetTooltip, FloatingBattlePetTooltip, PetJournalPrimaryAbilityTooltip, PetJournalSecondaryAbilityTooltip, PetBattlePrimaryUnitTooltip, PetBattlePrimaryAbilityTooltip, FloatingPetBattleAbilityTooltip, EncounterJournalTooltip and DropDownList
	if (tip:GetObjectType() ~= "GameTooltip") then
		return;
	end
	
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- set padding to tip
	local oldPaddingRight, oldPaddingBottom, oldPaddingLeft, oldPaddingTop = tip:GetPadding();
	oldPaddingLeft = oldPaddingLeft or 0;
	oldPaddingTop = oldPaddingTop or 0;
	
	local newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop;
	
	local itemTooltip = tip.ItemTooltip;
	local isItemTooltipShown = (itemTooltip and itemTooltip:IsShown());
	local isBottomFontStringShown = (tip.BottomFontString and tip.BottomFontString:IsShown());
	
	isSettingPaddingToTip = true;
	
	if (isItemTooltipShown) then
		tip:SetPadding(0, 0, 0, 0);
		
		GameTooltip_CalculatePadding(tip);
		
		newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop = tip:GetPadding();
		newPaddingLeft = newPaddingLeft or 0;
		newPaddingTop = newPaddingTop or 0;
	else
		newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop = 0, 0, 0, 0;
	end
	
	newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop = newPaddingRight + TT_ExtendedConfig.tipPaddingForGameTooltip.right, newPaddingBottom + TT_ExtendedConfig.tipPaddingForGameTooltip.bottom, newPaddingLeft + TT_ExtendedConfig.tipPaddingForGameTooltip.left, newPaddingTop + TT_ExtendedConfig.tipPaddingForGameTooltip.top;
	
	newPaddingRight = newPaddingRight + (frameParams.currentDisplayParams.extraPaddingRightForCloseButton or 0);
	newPaddingBottom = newPaddingBottom + (frameParams.currentDisplayParams.extraPaddingBottomForBars or 0);
	
	if (math.abs(newPaddingRight - oldPaddingRight) <= 0.5) and (math.abs(newPaddingBottom - oldPaddingBottom) <= 0.5) and (math.abs(newPaddingLeft - oldPaddingLeft) <= 0.5) and (math.abs(newPaddingTop - oldPaddingTop) <= 0.5) then
		isSettingPaddingToTip = false;
		return;
	end
	
	tip:SetPadding(newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop);
	
	if (isItemTooltipShown) then
		if (isBottomFontStringShown) then
			itemTooltip:SetPoint("BOTTOMLEFT", tip.BottomFontString, "TOPLEFT", 0 + TT_ExtendedConfig.tipPaddingForGameTooltip.left, 10 + TT_ExtendedConfig.tipPaddingForGameTooltip.bottom);
		else
			itemTooltip:SetPoint("BOTTOMLEFT", 10 + TT_ExtendedConfig.tipPaddingForGameTooltip.left, 13 + TT_ExtendedConfig.tipPaddingForGameTooltip.bottom);
		end
	end
	
	isSettingPaddingToTip = false;
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnApplyTipAppearanceAndHooking = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- HOOK: SharedTooltip_SetBackdropStyle() to reapply backdrop and padding if necessary (e.g. needed for OnTooltipSetItem() or AreaPOIPinMixin:OnMouseEnter() on world map (e.g. Torghast) or VignettePin on world map (e.g. weekly event in Maw))
		hooksecurefunc("SharedTooltip_SetBackdropStyle", function(self, style, embedded)
			for tip, frameParams in pairs(TT_CacheForFrames) do
				if (tip == self) then
					-- set backdrop to tip
					tt:SetBackdropToTip(tip);
				end
			end
		end);
		
		-- HOOK: GameTooltip_CalculatePadding() to reapply padding
		hooksecurefunc("GameTooltip_CalculatePadding", function(tip)
			-- set padding to tip
			tt:SetPaddingToTip(tip);
		end);
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- reapply padding to tip
		if (tipContent == TT_TIP_CONTENT.unknownOnShow) then
			-- set padding to tip
			tt:SetPaddingToTip(tip);
		end
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset current display parameters for backdrop
		currentDisplayParams.lockedBackdropInfo = TT_ExtendedConfig.tipBackdrop;
		
		if (currentDisplayParams.lockedBackdropColor) then
			currentDisplayParams.lockedBackdropColor:SetRGBA(TT_ExtendedConfig.backdropColor:GetRGBA());
		else
			currentDisplayParams.lockedBackdropColor = CreateColor(TT_ExtendedConfig.backdropColor:GetRGBA());
		end
		
		if (currentDisplayParams.lockedBackdropBorderColor) then
			currentDisplayParams.lockedBackdropBorderColor:SetRGBA(TT_ExtendedConfig.backdropBorderColor:GetRGBA());
		else
			currentDisplayParams.lockedBackdropBorderColor = CreateColor(TT_ExtendedConfig.backdropBorderColor:GetRGBA());
		end
		
		-- reset current display parameters for padding
		currentDisplayParams.extraPaddingRightForCloseButton = nil;
		currentDisplayParams.extraPaddingBottomForBars = nil;
	end,
	OnTipPostResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset backdrop and backdrop border color to tip
		tt:SetBackdropAndBackdropBorderColorToTip(tip);
		
		-- reset padding to tip. padding might have been modified to fit health/power bars.
		tt:SetPaddingToTip(tip);
	end
}, MOD_NAME .. " - Tooltip Backdrop");

----------------------------------------------------------------------------------------------------
--                                     Color Locking Feature                                      --
----------------------------------------------------------------------------------------------------

-- apply hooks for frame to add a color locking feature for ApplyBackdrop, SetBackdrop, ClearBackdrop, SetBackdropColor, SetBackdropBorderColor, SetCenterColor and SetBorderColor
function tt:ApplyColorLockingFeature(tip)
	-- color locking functions
	local function colorLockingFnForApplySetClearBackdrop(tip, frame)
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) or (not frameParams.currentDisplayParams.lockedBackdropInfo) then
			return;
		end
		
		tt:SetBackdropLocked(frame or tip, frameParams.currentDisplayParams.lockedBackdropInfo);
	end
	
	local function colorLockingFnForSetBackdropColor(tip, frame)
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) or (not frameParams.currentDisplayParams.lockedBackdropColor) then
			return;
		end
		
		tt:SetBackdropColorLocked(frame or tip, frameParams.currentDisplayParams.lockedBackdropColor:GetRGBA());
	end
	
	local function colorLockingFnForSetBackdropBorderColor(tip, frame)
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) or (not frameParams.currentDisplayParams.lockedBackdropBorderColor) then
			return;
		end
		
		tt:SetBackdropBorderColorLocked(frame or tip, frameParams.currentDisplayParams.lockedBackdropBorderColor:GetRGBA());
	end
	
	local function colorLockingFnForSetCenterColor(tip, frame)
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) or (not frameParams.currentDisplayParams.lockedBackdropColor) then
			return;
		end
		
		tt:SetCenterColorLocked(frame or tip, frameParams.currentDisplayParams.lockedBackdropColor:GetRGBA());
	end
	
	local function colorLockingFnForSetBorderColor(tip, frame)
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) or (not frameParams.currentDisplayParams.lockedBackdropBorderColor) then
			return;
		end
		
		tt:SetBorderColorLocked(frame or tip, frameParams.currentDisplayParams.lockedBackdropBorderColor:GetRGBA());
	end
	
	-- apply hooks for frame to add a color locking feature
	if (tip.ApplyBackdrop) then
		hooksecurefunc(tip, "ApplyBackdrop", function(tip)
			colorLockingFnForApplySetClearBackdrop(tip);
		end);
	end
	if (tip.SetBackdrop) then
		hooksecurefunc(tip, "SetBackdrop", function(tip)
			colorLockingFnForApplySetClearBackdrop(tip);
		end);
	end
	if (tip.ClearBackdrop) then
		hooksecurefunc(tip, "ClearBackdrop", function(tip)
			colorLockingFnForApplySetClearBackdrop(tip);
		end);
	end
	if (tip.SetBackdropColor) then
		hooksecurefunc(tip, "SetBackdropColor", function(tip)
			colorLockingFnForSetBackdropColor(tip);
		end);
	end
	if (tip.SetBackdropBorderColor) then
		hooksecurefunc(tip, "SetBackdropBorderColor", function(tip)
			colorLockingFnForSetBackdropBorderColor(tip);
		end);
	end
	if (tip.SetCenterColor) then
		hooksecurefunc(tip, "SetCenterColor", function(tip)
			colorLockingFnForSetCenterColor(tip);
		end);
	end
	if (tip.SetBorderColor) then
		hooksecurefunc(tip, "SetBorderColor", function(tip)
			colorLockingFnForSetBorderColor(tip);
		end);
	end
	
	if (tip.NineSlice) then
		if (tip.NineSlice.ApplyBackdrop) then
			hooksecurefunc(tip.NineSlice, "ApplyBackdrop", function(tip)
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdrop) then
			hooksecurefunc(tip.NineSlice, "SetBackdrop", function(tip)
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.ClearBackdrop) then
			hooksecurefunc(tip.NineSlice, "ClearBackdrop", function(tip)
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdropColor) then
			hooksecurefunc(tip.NineSlice, "SetBackdropColor", function(tip)
				colorLockingFnForSetBackdropColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdropBorderColor) then
			hooksecurefunc(tip.NineSlice, "SetBackdropBorderColor", function(tip)
				colorLockingFnForSetBackdropBorderColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetCenterColor) then
			hooksecurefunc(tip.NineSlice, "SetCenterColor", function(tip)
				colorLockingFnForSetCenterColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBorderColor) then
			hooksecurefunc(tip.NineSlice, "SetBorderColor", function(tip)
				colorLockingFnForSetBorderColor(tip:GetParent(), tip);
			end);
		end
	end
end

-- set backdrop locked
--
-- use isSettingBackdropLocked to prevent endless loop when calling tt:SetBackdropLocked()
local isSettingBackdropLocked = false;

function tt:SetBackdropLocked(tip, backdropInfo)
	-- check if we're already setting backdrop color locked
	if (isSettingBackdropLocked) then
		return;
	end
	
	isSettingBackdropLocked = false;
	
	-- set backdrop locked
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		frameParams.currentDisplayParams.lockedBackdropInfo = backdropInfo;
	end
	
	-- set backdrop locked
	isSettingBackdropLocked = true;
	tip:SetBackdrop(backdropInfo);
	isSettingBackdropLocked = false;
end

-- set backdrop color locked
--
-- use isSettingBackdropColorLocked to prevent endless loop when calling tt:SetBackdropColorLocked()
local isSettingBackdropColorLocked = false;

function tt:SetBackdropColorLocked(tip, r, g, b, a)
	-- check if we're already setting backdrop color locked
	if (isSettingBackdropColorLocked) then
		return;
	end
	
	isSettingBackdropColorLocked = false;
	
	-- set backdrop color locked
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		if (frameParams.currentDisplayParams.lockedBackdropColor) then
			frameParams.currentDisplayParams.lockedBackdropColor:SetRGBA(r, g, b, a);
		else
			frameParams.currentDisplayParams.lockedBackdropColor = CreateColor(r, g, b, a);
		end
	end
	
	isSettingBackdropColorLocked = true;
	tip:SetBackdropColor(r, g, b, a);
	isSettingBackdropColorLocked = false;
end

-- set backdrop border color locked
--
-- use isSettingBackdropBorderColorLocked to prevent endless loop when calling tt:SetBackdropBorderColorLocked()
local isSettingBackdropBorderColorLocked = false;

function tt:SetBackdropBorderColorLocked(tip, r, g, b, a)
	-- check if we're already setting backdrop border color locked
	if (isSettingBackdropBorderColorLocked) then
		return;
	end
	
	isSettingBackdropBorderColorLocked = false;
	
	-- set backdrop border color locked
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		if (frameParams.currentDisplayParams.lockedBackdropBorderColor) then
			frameParams.currentDisplayParams.lockedBackdropBorderColor:SetRGBA(r, g, b, a);
		else
			frameParams.currentDisplayParams.lockedBackdropBorderColor = CreateColor(r, g, b, a);
		end
	end
	
	isSettingBackdropBorderColorLocked = true;
	tip:SetBackdropBorderColor(r, g, b, a);
	isSettingBackdropBorderColorLocked = false;
end

-- set center color locked
--
-- use isSettingCenterColorLocked to prevent endless loop when calling tt:SetCenterColorLocked()
local isSettingCenterColorLocked = false;

function tt:SetCenterColorLocked(tip, r, g, b, a)
	-- check if we're already setting center color locked
	if (isSettingCenterColorLocked) then
		return;
	end
	
	isSettingCenterColorLocked = false;
	
	-- set center color locked
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		if (frameParams.currentDisplayParams.lockedBackdropColor) then
			frameParams.currentDisplayParams.lockedBackdropColor:SetRGBA(r, g, b, a);
		else
			frameParams.currentDisplayParams.lockedBackdropColor = CreateColor(r, g, b, a);
		end
	end
	
	isSettingCenterColorLocked = true;
	tip:SetCenterColor(r, g, b, a);
	isSettingCenterColorLocked = false;
end

-- set border color locked
--
-- use isSettingBorderColorLocked to prevent endless loop when calling tt:SetBorderColorLocked()
local isSettingBorderColorLocked = false;

function tt:SetBorderColorLocked(tip, r, g, b, a)
	-- check if we're already setting border color locked
	if (isSettingBorderColorLocked) then
		return;
	end
	
	isSettingBorderColorLocked = false;
	
	-- set border color locked
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		if (frameParams.currentDisplayParams.lockedBackdropBorderColor) then
			frameParams.currentDisplayParams.lockedBackdropBorderColor:SetRGBA(r, g, b, a);
		else
			frameParams.currentDisplayParams.lockedBackdropBorderColor = CreateColor(r, g, b, a);
		end
	end
	
	isSettingBorderColorLocked = true;
	tip:SetBorderColor(r, g, b, a);
	isSettingBorderColorLocked = false;
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	SetBackdropBorderColorLocked = function(self, tip, r, g, b, a)
		tt:SetBackdropBorderColorLocked(tip, r, g, b, a);
	end
}, MOD_NAME .. " - Color Locking Feature");

----------------------------------------------------------------------------------------------------
--                                           Anchoring                                            --
----------------------------------------------------------------------------------------------------

-- set anchor to tip
function tt:SetAnchorToTip(tip)
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set anchor to tip not possible
	if (not cfg.enableAnchor) or (not tipParams.applyAnchor) then
		return;
	end
	
	-- tip not default anchored
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	if (not currentDisplayParams.defaultAnchored) then
		return;
	end
	
	-- set anchor type and anchor point
	local anchorFrameName, anchorType, anchorPoint = currentDisplayParams.anchorFrameName, currentDisplayParams.anchorType or TT_ExtendedConfig.defaultAnchorType, currentDisplayParams.anchorPoint or TT_ExtendedConfig.defaultAnchorPoint;
	
	-- set anchor to tip
	if (tip:GetObjectType() == "GameTooltip") then
		local tipAnchorType = tip:GetAnchorType();
		
		-- ignore world tips
		if (tipAnchorType == "ANCHOR_CURSOR") or (tipAnchorType == "ANCHOR_CURSOR_RIGHT") then
			return;
		end
		
		-- set anchor type to tip
		if (anchorType == "normal") or (anchorType == "mouse") or (anchorType == "parent") then
			if (tipAnchorType ~= "ANCHOR_NONE") then
				tip:SetAnchorType("ANCHOR_NONE");
			end
		end
	end
	
	if (anchorType == "normal") then
		-- "normal" anchor
		tip:ClearAllPoints();
		
		local offsetX, offsetY = LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, tt, tip, UIParent);
		
		tip:SetPoint(anchorPoint, UIParent, offsetX, offsetY);
	elseif (anchorType == "mouse") then
		-- although we anchor the tip continuously in OnUpdate, we must anchor it initially here to avoid flicker on the first frame its being shown.
		self:AnchorTipToMouse(tip);
	elseif (anchorType == "parent") then
		tip:ClearAllPoints();
		
		local parentFrame = currentDisplayParams.defaultAnchoredParentFrame;
		
		if (parentFrame ~= UIParent) then
			-- anchor to the opposite edge of the parent frame
			local offsetX, offsetY = LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, parentFrame, tip, UIParent);
			
			tip:SetPoint(LibFroznFunctions:MirrorAnchorPointCentered(anchorPoint), UIParent, anchorPoint, offsetX, offsetY);
		else
			-- fallback to "normal" anchor in case parent frame is UIParent
			local offsetX, offsetY = LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, tt, tip, UIParent);
			
			tip:SetPoint(anchorPoint, UIParent, offsetX, offsetY);
		end
	end
	
	-- refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
	LibFroznFunctions:RefreshAnchorShoppingTooltips(tip);
end

-- anchor tip to mouse position
function tt:AnchorTipToMouse(tip)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end

	local tipParams = frameParams.config;
	
	-- set anchor to tip not possible
	if (not cfg.enableAnchor) or (not tipParams.applyAnchor) then
		return;
	end
	
	-- tip not default anchored
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	if (not currentDisplayParams.defaultAnchored) then
		return;
	end
	
	-- set anchor type and anchor point
	local anchorFrameName, anchorType, anchorPoint = currentDisplayParams.anchorFrameName, currentDisplayParams.anchorType or TT_ExtendedConfig.defaultAnchorType, currentDisplayParams.anchorPoint or TT_ExtendedConfig.defaultAnchorPoint;
	
	-- set anchor to tip
	if (tip:GetObjectType() == "GameTooltip") then
		local tipAnchorType = tip:GetAnchorType();
		
		-- ignore world tips
		if (tipAnchorType == "ANCHOR_CURSOR") or (tipAnchorType == "ANCHOR_CURSOR_RIGHT") then
			return;
		end
		
		-- set anchor type to tip
		if (anchorType == "mouse") then
			if (tipAnchorType ~= "ANCHOR_NONE") then
				tip:SetAnchorType("ANCHOR_NONE");
			end
		end
	end
	
	-- anchor tip to mouse position
	if (anchorType == "mouse") then
		local x, y = GetCursorPosition();
		local effScale = tip:GetEffectiveScale();
		
		tip:ClearAllPoints();
		tip:SetPoint(anchorPoint, UIParent, "BOTTOMLEFT", (x / effScale + TT_MouseOffsetX), (y / effScale + TT_MouseOffsetY));
	end
	
	-- refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
	LibFroznFunctions:RefreshAnchorShoppingTooltips(tip);
end

-- get anchor position
function tt:GetAnchorPosition(tip)
	local frameParams = TT_CacheForFrames[tip];
	
	local isUnit;
	
	if (frameParams) then
		if (frameParams.currentDisplayParams.tipContent == TT_TIP_CONTENT.unit) then
			isUnit = true;
		elseif (frameParams.currentDisplayParams.tipContent == TT_TIP_CONTENT.aura) then
			isUnit = false;
		end
	end
	
	local mouseFocus = GetMouseFocus();
	
	if (isUnit == nil) then
		isUnit = (UnitExists("mouseover")) and (not UnitIsUnit("mouseover", "player")) or (mouseFocus and mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit")); -- GetAttribute("unit") here is bad, as that will find things like buff frames too.
	end
	
	local anchorFrameName = (mouseFocus == WorldFrame and "World" or "Frame") .. (isUnit and "Unit" or "Tip");
	local var = "anchor" .. anchorFrameName;
	local anchorOverrideInCombat = (cfg["enableAnchorOverride" .. anchorFrameName .. "InCombat"] and UnitAffectingCombat("player") and "InCombat" or "");
	
	local anchorType, anchorPoint = cfg[var .. "Type" .. anchorOverrideInCombat], cfg[var .. "Point" .. anchorOverrideInCombat];
	
	-- check for GameTooltip anchor overrides
	if (tip == GameTooltip) then
		-- override GameTooltip anchor for (Guild & Community) ChatFrame
		if (cfg.enableAnchorOverrideCF) and (LibFroznFunctions:IsFrameBackInFrameChain(tip:GetOwner(), {
					"ChatFrame(%d+)",
					(LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Communities") and CommunitiesFrame.Chat.MessageFrame)
				}, 1)) then
			return anchorFrameName, cfg.anchorOverrideCFType, cfg.anchorOverrideCFPoint;
		end
	end
	
	return anchorFrameName, anchorType, anchorPoint;
end

-- HOOK: tip's OnUpdate for anchoring to mouse
function tt:AnchorTipToMouseOnUpdate(tip)
	tip:HookScript("OnUpdate", function(tip)
		-- anchor tip to mouse position
		tt:AnchorTipToMouse(tip);
	end);
end

-- HOOK: GameTooltip_SetDefaultAnchor() after set default anchor to tip
function tt:SetDefaultAnchorHook(tip, parent)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- set current display params for anchoring
	frameParams.currentDisplayParams.defaultAnchored = true;
	frameParams.currentDisplayParams.defaultAnchoredParentFrame = parent;
	
	-- set anchor to tip
	tt:SetAnchorToTip(tip);
end

-- reset current display params for anchoring
function tt:ResetCurrentDisplayParamsForAnchoring(tip, resetOnlyDefaultAnchor)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- reset current display params for anchoring
	if (not tip:IsShown()) then
		currentDisplayParams.defaultAnchored = false;
		currentDisplayParams.defaultAnchoredParentFrame = nil;
	end
	
	if (resetOnlyDefaultAnchor) then
		return;
	end
	
	currentDisplayParams.anchorFrameName, currentDisplayParams.anchorType, currentDisplayParams.anchorPoint = nil, nil, nil;
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- get tip parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		local tipParams = frameParams.config;
		
		-- set anchor to tip not possible
		if (not tipParams.applyAnchor) then
			return;
		end
		
		-- no hooking allowed
		if (tipParams.noHooks) then
			return;
		end
		
		-- HOOK: tip's SetOwner to reset current display params for anchoring
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			if (tip:GetObjectType() == "GameTooltip") then
				hooksecurefunc(tip, "SetOwner", function(tip, owner, anchor, xOffset, yOffset)
					tt:ResetCurrentDisplayParamsForAnchoring(tip, true);
				end);
			end
		end);
		
		-- HOOK: tip's OnUpdate for anchoring to mouse
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			tt:AnchorTipToMouseOnUpdate(tip);
		end);
	end,
	OnTipSetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set current display params for anchoring
		currentDisplayParams.defaultAnchored = not not currentDisplayParams.defaultAnchored;
		
		currentDisplayParams.anchorFrameName, currentDisplayParams.anchorType, currentDisplayParams.anchorPoint = tt:GetAnchorPosition(tip);
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set anchor to tip
		tt:SetAnchorToTip(tip);
	end,
	OnApplyTipAppearanceAndHooking = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- HOOK: GameTooltip_SetDefaultAnchor() for re-anchoring
		hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tip, parent)
			tt:SetDefaultAnchorHook(tip, parent);
		end);
		
		-- HOOK: GameTooltip_ShowCompareItem() to refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
		hooksecurefunc("GameTooltip_ShowCompareItem", function(self, anchorFrame)
			-- refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
			local tip = self or GameTooltip;
			
			LibFroznFunctions:RefreshAnchorShoppingTooltips(tip);
		end);
	end,
	SetDefaultAnchorHook = function(self, tip, parent)
		-- hook after set default anchor to tip
		tt:SetDefaultAnchorHook(tip, parent);
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset current display params for anchoring
		tt:ResetCurrentDisplayParamsForAnchoring(tip);
	end
}, MOD_NAME .. " - Anchoring");

----------------------------------------------------------------------------------------------------
--                                        Unit Appearance                                         --
----------------------------------------------------------------------------------------------------

--[[
	GameTooltip construction call order for unit tips
	-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	- GameTooltip_SetDefaultAnchor()    -- called e.g. for units and mailboxes using the default anchor. won't initially be called for buffs or vendor signs.
	- GameTooltip:OnTooltipSetUnit()    -- GetUnit() aka TooltipUtil.GetDisplayedUnit() becomes valid here
	- GameTooltip:Show()                -- will resize the tip
	- GameTooltip:OnShow()              -- event triggered in response to the Show() function. won't be called if tooltip of world unit isn't faded out yet and moving mouse over it again or someone else.
	- GameTooltip:OnTooltipCleared()    -- tooltip has been cleared and is ready to show new information. doesn't mean it's hidden.
--]]

-- set unit record from tip
function tt:SetUnitRecordFromTip(tip)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- set unit record from tip
	local _, unitID = LibFroznFunctions:GetUnitFromTooltip(tip);
	
	-- concated unit tokens such as "targettarget" cannot be returned as the unit id by GameTooltip:GetUnit() aka TooltipUtil.GetDisplayedUnit(GameTooltip),
	-- and it will return as "mouseover", but the "mouseover" unit id is still invalid at this point for those unitframes!
	-- to overcome this problem, we look if the mouse is over a unitframe, and if that unitframe has a unit attribute set?
	if (not unitID) then
		local mouseFocus = GetMouseFocus();
		
		unitID = mouseFocus and mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit");
	end
	
	-- a mage's mirror images sometimes doesn't return a unit id, this would fix it.
	if (not unitID) and (UnitExists("mouseover")) and (not UnitIsUnit("mouseover", "player")) then
		unitID = "mouseover";
	end
	
	-- sometimes when you move your mouse quickly over units in the worldframe, we can get here without a unit id.
	if (not unitID) then
		frameParams.currentDisplayParams.unitRecord = nil;
		return;
	end
	
	-- a "mouseover" unitID is better to have as we can then safely say the tip should no longer show when it becomes invalid. Harder to say with a "party2" unit.
	-- this also helps fix the problem that "mouseover" units aren't valid for group members out of range, a bug that has been in WoW since about 3.0.2.
	if (UnitIsUnit(unitID, "mouseover")) then
		unitID = "mouseover";
	end
	
	-- set unit record
	local unitRecord = LibFroznFunctions:CreateUnitRecord(unitID);
	
	local rpName;
	
	if (unitRecord.isPlayer) then
		if (msp) then
			local field = "NA"; -- Name
			
			msp:Request(unitRecord.name, field);
			
			if (msp.char[unitRecord.name] ~= nil) and (msp.char[unitRecord.name].field[field] ~= "") then
				unitRecord.rpName = msp.char[unitRecord.name].field[field];
			end
		elseif (msptrp) then
			local field = "NA"; -- Name
			
			msptrp:Request(unitRecord.name, field);
			
			if (msptrp.char[unitRecord.name] ~= nil) and (msptrp.char[unitRecord.name].field[field] ~= "") then
				unitRecord.rpName = msptrp.char[unitRecord.name].field[field];
			end
		end
	end
	
	unitRecord.originalName = GameTooltipTextLeft1:GetText();
	unitRecord.isColorBlind = (GetCVar("colorblindMode") == "1");
	
	frameParams.currentDisplayParams.unitRecord = unitRecord;
end

-- set unit appearance to tip
function tt:SetUnitAppearanceToTip(tip, first)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- no unit record
	local unitRecord = frameParams.currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- no valid unit any more e.g. during fading out
	if (not UnitGUID(unitRecord.id)) then
		return;
	end
	
	-- inform group that the tip is about to be styled
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipPreStyle", TT_CacheForFrames, tip, first);
	
	-- set backdrop color to tip by unit reaction index
	if (cfg.reactColoredBackdrop) then
		self:SetBackdropColorLocked(tip, unpack(cfg["colorReactBack" .. unitRecord.reactionIndex]));
	end

	-- set backdrop border color to tip by unit class or by unit reaction index
	if (cfg.classColoredBorder) and (unitRecord.isPlayer) then
		local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5);
		
		self:SetBackdropBorderColorLocked(tip, classColor:GetRGBA());
	elseif (cfg.reactColoredBorder) then
		self:SetBackdropBorderColorLocked(tip, unpack(cfg["colorReactText" .. unitRecord.reactionIndex]));
	end
	
	-- inform group that the tip has to be styled
	if (cfg.showUnitTip) then
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipStyle", TT_CacheForFrames, tip, first);
	end
	
	-- recalculate size of tip to ensure that it has the correct dimensions
	LibFroznFunctions:RecalculateSizeOfGameTooltip(tip);
	
	-- inform group that the tip has to be resized
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipResize", TT_CacheForFrames, tip, first);
	
	-- inform group that the tip has been styled and has the final size
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipPostStyle", TT_CacheForFrames, tip, first);
	
	-- set padding to tip. padding might have been modified to fit health/power bars.
	self:SetPaddingToTip(tip);
end

-- update unit appearance to tip
function tt:UpdateUnitAppearanceToTip(tip, force)
	-- get frame parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	-- no unit appearance
	local timestampStartUnitAppearance = frameParams.currentDisplayParams.timestampStartUnitAppearance;
	
	if (not timestampStartUnitAppearance) then
		return;
	end
	
	-- no unit record
	local currentDisplayParams = frameParams.currentDisplayParams;
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- consider update interval
	if (not force) and (GetTime() - timestampStartUnitAppearance < cfg.updateFreq) then
		return;
	end
	
	-- inform group that the tip has to be checked if it needs to be hidden
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetHidden", TT_CacheForFrames, tip, currentDisplayParams, currentDisplayParams.tipContent);
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		tt:HideTip(tip);
		return;
	end
	
	-- update unit record
	LibFroznFunctions:UpdateUnitRecord(unitRecord);
	
	-- set unit appearance to tip
	tt:SetUnitAppearanceToTip(tip);
	currentDisplayParams.timestampStartUnitAppearance = GetTime();
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- only for GameTooltip tips
		if (tip:GetObjectType() ~= "GameTooltip") then
			return;
		end
		
		-- get tip parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		local tipParams = frameParams.config;
		
		-- no hooking allowed
		if (tipParams.noHooks) then
			return;
		end
		
		-- HOOK: tip's OnUpdate to update unit appearance
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			tip:HookScript("OnUpdate", function(tip)
				tt:UpdateUnitAppearanceToTip(tip);
			end);
		end);
	end,
	OnTipSetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set current display params for unit appearance
		if (tipContent == TT_TIP_CONTENT.unit) then
			tt:SetUnitRecordFromTip(tip);
		else
			currentDisplayParams.unitRecord = nil;
		end
		
		currentDisplayParams.timestampStartUnitAppearance = nil;
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set unit appearance to tip
		tt:SetUnitAppearanceToTip(tip, true);
		currentDisplayParams.timestampStartUnitAppearance = GetTime();
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset current display params for unit appearance
		currentDisplayParams.unitRecord = nil;
		currentDisplayParams.timestampStartUnitAppearance = nil;
	end
}, MOD_NAME .. " - Unit Appearance");

----------------------------------------------------------------------------------------------------
--                                      Custom Unit Fadeout                                       --
----------------------------------------------------------------------------------------------------

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- only for GameTooltip tips
		if (tip:GetObjectType() ~= "GameTooltip") then
			return;
		end
		
		-- get tip parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		local tipParams = frameParams.config;
		
		-- no hooking allowed
		if (tipParams.noHooks) then
			return;
		end
		
		-- HOOK: tip's FadeOut() and OnUpdate for custom unit fadeout
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			hooksecurefunc(tip, "FadeOut", function(tip)
				-- no override of default unit fadeout
				if (not cfg.overrideFade) then
					return;
				end
				
				-- get frame parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				-- no unit record
				local unitRecord = frameParams.currentDisplayParams.unitRecord;
				
				if (not unitRecord) then
					return;
				end
				
				-- instant unit fadeout
				if (cfg.preFadeTime == 0) and (cfg.fadeTime == 0) then
					tip:Hide();
					return;
				end
				
				-- enable custom unit fadeout
				tip:Show(); -- cancels default unit fadeout
				frameParams.currentDisplayParams.timestampStartCustomUnitFadeout = GetTime();
			end);
			
			tip:HookScript("OnUpdate", function(tip)
				-- get frame parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				-- no custom unit fadeout
				local timestampStartCustomUnitFadeout = frameParams.currentDisplayParams.timestampStartCustomUnitFadeout;
				
				if (not timestampStartCustomUnitFadeout) then
					-- no override of default unit fadeout
					if (not cfg.overrideFade) then
						return;
					end
					
					-- only needed for Classic Era and WotLKC: FadeOut() for worldframe unit tips will not be called
					local unitRecord = frameParams.currentDisplayParams.unitRecord;
					
					if ((LibFroznFunctions.isWoWFlavor.ClassicEra) or (LibFroznFunctions.isWoWFlavor.BCC) or (LibFroznFunctions.isWoWFlavor.WotLKC)) and
							(unitRecord) and ((IsMouseButtonDown()) or (not UnitExists(unitRecord.id))) then
						
						tip:FadeOut();
					end
					
					return;
				end
				
				-- pre fade time
				local fadingTime = GetTime() - timestampStartCustomUnitFadeout;
				
				if (fadingTime <= cfg.preFadeTime) then
					return;
				end
				
				-- time for custom unit fadeout expired
				if (fadingTime >= cfg.preFadeTime + cfg.fadeTime) then
					tip:Hide();
					return;
				end
				
				-- set tip's alpha during fading time
				tip:SetAlpha(1 - (fadingTime - cfg.preFadeTime) / cfg.fadeTime);
			end);
		end);
	end,
	OnTipSetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set current display params for custom unit fadeout
		currentDisplayParams.timestampStartCustomUnitFadeout = nil;
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset current display params for custom unit fadeout
		currentDisplayParams.timestampStartCustomUnitFadeout = nil;
	end
}, MOD_NAME .. " - Custom Unit Fadeout");

----------------------------------------------------------------------------------------------------
--                                   Hide World Tips Instantly                                    --
----------------------------------------------------------------------------------------------------

-- hide world tips instantly
function tt:HideWorldTipsInstantly()
	if (cfg.hideWorldTips) and (GameTooltip:IsShown()) and (GameTooltip:IsOwned(UIParent)) and (not TT_CacheForFrames[GameTooltip].currentDisplayParams.unitRecord) then
		-- restoring the text of the first line is a workaround so that gatherer addons can get the name of nodes
		local oldGameTooltipTextLeft1Text = GameTooltipTextLeft1:GetText();
		
		GameTooltip:Hide();
		
		GameTooltipTextLeft1:SetText(oldGameTooltipTextLeft1Text);
	end
end

-- EVENT: cursor changed
function tt:CURSOR_CHANGED(event)
	self:HideWorldTipsInstantly();
end

-- register for group events
local eventsForHideWorldTipsHooked = false;

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnApplyConfig = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		if (cfg.hideWorldTips) then
			if (not eventsForHideWorldTipsHooked) then
				tt:RegisterEvent("CURSOR_CHANGED");
				eventsForHideWorldTipsHooked = true;
			end
		else
			if (eventsForHideWorldTipsHooked) then
				tt:UnregisterEvent("CURSOR_CHANGED");
				eventsForHideWorldTipsHooked = false;
			end
		end
	end,
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- only for GameTooltip tips
		if (tip:GetObjectType() ~= "GameTooltip") then
			return;
		end
		
		-- get tip parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		local tipParams = frameParams.config;
		
		-- no hooking allowed
		if (tipParams.noHooks) then
			return;
		end
		
		-- HOOK: tip's FadeOut() to hide world tips instantly
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			hooksecurefunc(tip, "FadeOut", function(tip)
				-- get frame parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				-- unit record exists
				local unitRecord = frameParams.currentDisplayParams.unitRecord;
				
				if (unitRecord) then
					return;
				end
				
				-- hide world tips instantly
				tt:HideWorldTipsInstantly();
			end);
		end);
	end
}, MOD_NAME .. " - Hide World Tips Instantly");

----------------------------------------------------------------------------------------------------
--                                           Hide Tips                                            --
----------------------------------------------------------------------------------------------------

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipSetHidden = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- unhandled tip content
		if (not LibFroznFunctions:ExistsInTable(tipContent, { TT_TIP_CONTENT.unit, TT_TIP_CONTENT.aura, TT_TIP_CONTENT.spell, TT_TIP_CONTENT.item, TT_TIP_CONTENT.action })) then
			return;
		end
		
		-- modifier key set and pressed to still show hidden tips
		if (cfg.showHiddenModifierKey == "shift") and (IsShiftKeyDown()) then
			return;
		end
		if (cfg.showHiddenModifierKey == "ctrl") and (IsControlKeyDown()) then
			return;
		end
		if (cfg.showHiddenModifierKey == "alt") and (IsAltKeyDown()) then
			return;
		end
		
		-- hide tips
		local inCombat = (UnitAffectingCombat("player") and "InCombat" or "");
		
		if (currentDisplayParams.anchorFrameName) then
			if (cfg["hideTips" .. inCombat .. currentDisplayParams.anchorFrameName .. "s"]) then
				currentDisplayParams.hideTip = true;
				return;
			end
		end
		
		local tipContentName = ((tipContent == TT_TIP_CONTENT.unit) and "Unit") or (((tipContent == TT_TIP_CONTENT.aura) or (tipContent == TT_TIP_CONTENT.spell)) and "Spell") or ((tipContent == TT_TIP_CONTENT.item) and "Item") or ((tipContent == TT_TIP_CONTENT.action) and "Action");
		
		if (cfg["hideTips" .. inCombat .. tipContentName .. "Tips"]) then
			currentDisplayParams.hideTip = true;
			return;
		end
	end
}, MOD_NAME .. " - Hide Tips");
