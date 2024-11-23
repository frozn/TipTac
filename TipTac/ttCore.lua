-----------------------------------------------------------------------
-- TipTac - Core
--
-- TipTac is a tooltip enchancement addon, it allows you to configure various aspects of the tooltip, such as moving where it's shown, the font, the scale of tips, plus many more features.
--

-- create addon
local MOD_NAME = ...;
local tt = CreateFrame("Frame", MOD_NAME, UIParent, BackdropTemplateMixin and "BackdropTemplate");
tt:Hide();

-- get libs
local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1");
local LibDBIcon = LibStub:GetLibrary("LibDBIcon-1.0");
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");

----------------------------------------------------------------------------------------------------
--                                             Config                                             --
----------------------------------------------------------------------------------------------------

-- config
local cfg;

-- default config
local TT_DefaultConfig = {
	-- TipTac anchor
	left = nil,  -- set during event ADDON_LOADED
	top = nil,   -- set during event ADDON_LOADED
	
	-- general
	showMinimapIcon = true,
	minimapConfig = {},  -- set in LibDBIcon-1.0
	gttScale = 1,
	
	showUnitTip = true,
	showStatus = true,
	showTargetedBy = true,
	showPlayerGender = false,
	showCurrentUnitSpeed = true,
	showMythicPlusDungeonScore = true,
	mythicPlusDungeonScoreFormat = "both",
	showMount = true,
	showMountCollected = true,
	showMountIcon = true,
	showMountText = true,
	showMountSpeed = true,
	nameType = "title",
	showRealm = "show",
	showTarget = "last",
	targetYouText = "<<YOU>>",
	showGuild = true,
	showGuildRank = true,
	guildRankFormat = "both",
	showBattlePetTip = true,
	hidePvpText = true,
	hideSpecializationAndClassText = true,
	highlightTipTacDeveloper = true, -- hidden
	
	-- colors
	enableColorName = true,
	colorName = { HIGHLIGHT_FONT_COLOR:GetRGBA() }, -- white
	colorNameByReaction = true,
	colorNameByClass = false,
	
	colorGuild = { 0, 0.5, 0.8, 1 },
	colorSameGuild = { 1, 0.2, 1, 1 },
	colorGuildByReaction = true,
	
	colorRace = { HIGHLIGHT_FONT_COLOR:GetRGBA() }, -- white
	colorLevel = { 0.8, 0.8, 0.8, 1 }, -- light+ grey (QUEST_OBJECTIVE_FONT_COLOR)
	
	factionText = true,
	enableColorFaction = false,
	colorFactionAlliance = { PLAYER_FACTION_COLOR_ALLIANCE:GetRGBA() },
	colorFactionHorde = { PLAYER_FACTION_COLOR_HORDE:GetRGBA() },
	colorFactionNeutral = { HIGHLIGHT_FONT_COLOR:GetRGBA() }, -- white
	colorFactionOther = { HIGHLIGHT_FONT_COLOR:GetRGBA() }, -- white
	
	classColoredBorder = true,
	
	enableCustomClassColors = false,
	colorCustomClassWarrior = {},      -- set during event ADDON_LOADED
	colorCustomClassPaladin = {},      -- set during event ADDON_LOADED
	colorCustomClassHunter = {},       -- set during event ADDON_LOADED
	colorCustomClassRogue = {},        -- set during event ADDON_LOADED
	colorCustomClassPriest = {},       -- set during event ADDON_LOADED
	colorCustomClassDeathknight = {},  -- set during event ADDON_LOADED
	colorCustomClassShaman = {},       -- set during event ADDON_LOADED
	colorCustomClassMage = {},         -- set during event ADDON_LOADED
	colorCustomClassWarlock = {},      -- set during event ADDON_LOADED
	colorCustomClassMonk = {},         -- set during event ADDON_LOADED
	colorCustomClassDruid = {},        -- set during event ADDON_LOADED
	colorCustomClassDemonhunter = {},  -- set during event ADDON_LOADED
	colorCustomClassEvoker = {},       -- set during event ADDON_LOADED
	
	-- reactions
	reactColoredBorder = false,
	reactIcon = false,
	
	reactText = false,
	colorReactText = { HIGHLIGHT_FONT_COLOR:GetRGBA() }, -- white
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
	
	-- backdrop
	enableBackdrop = true,
	tipBackdropBG = "Interface\\Buttons\\WHITE8X8",
	tipBackdropBGLayout = "tile",
	tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
	pixelPerfectBackdrop = false,
	backdropEdgeSize = 14,
	backdropInsets = 2.5,
	
	tipColor = { 0.1, 0.1, 0.2, 1 },        -- UI default: for most: (0.1, 0.1, 0.2, 1), world objects?: (0, 0.2, 0.35, 1)
	tipBorderColor = { 0.3, 0.3, 0.4, 1 },  -- UI default: (1, 1, 1, 1)
	gradientTip = true,
	gradientColor = { 0.8, 0.8, 0.8, 0.15 },
	gradientHeight = 32,
	
	-- font
	modifyFonts = false,
	fontFace = "",   -- set during event ADDON_LOADED
	fontSize = 0,    -- set during event ADDON_LOADED
	fontFlags = "",	 -- set during event ADDON_LOADED
	fontSizeDeltaHeader = 2,
	fontSizeDeltaSmall = -2,
	
	-- classify
	classification_minus = "-%s",  -- new classification in MoP. used for minion mobs that typically have less health than normal mobs of their level, but engage the player in larger numbers. example of use: the "Sha Haunts" early in the horde's quests in thunder hold.
	classification_trivial = "~%s",
	classification_normal = "%s",
	classification_elite = "+%s",
	classification_worldboss = "%s|r (Boss)",
	classification_rare = "%s|r (Rare)",
	classification_rareelite = "+%s|r (Rare)",
	
	-- fading
	overrideFade = true,
	preFadeTime = 0.1,
	fadeTime = 0.1,
	hideWorldTips = true,
	
	-- bars
	enableBars = true,
	healthBar = true,
	healthBarText = "full",
	healthBarColor = { 0.3, 0.9, 0.3, 1 },
	healthBarClassColor = true,
	hideDefaultBar = true,
	manaBar = false,
	manaBarText = "full",
	manaBarColor = { 0.3, 0.55, 0.9, 1 },
	powerBar = false,
	powerBarText = "current",
	castBar = false,
	castBarAlwaysShow = false,
	castBarCastingColor = { YELLOW_THREAT_COLOR:GetRGBA() }, -- light yellow
	castBarChannelingColor = { 0.32, 0.3, 1, 1},
	castBarChargingColor = { ORANGE_THREAT_COLOR:GetRGBA() }, -- light orange
	castBarCompleteColor = { 0.12, 0.86, 0.15, 1},
	castBarFailColor = { 1, 0.09, 0, 1},
	castBarSparkColor = {1, 1, 1, 0.75},
	barsCondenseValues = true,
	barFontFace = "",          -- set during event ADDON_LOADED
	barFontFlags = "",         -- set during event ADDON_LOADED
	barFontSize = 0,           -- set during event ADDON_LOADED
	barTexture = "Interface\\TargetingFrame\\UI-StatusBar",
	barHeight = 6,
	barEnableTipMinimumWidth = true,
	barTipMinimumWidth = 180,
	
	-- auras
	enableAuras = true,
	showBuffs = true,
	showDebuffs = true,
	selfAurasOnly = false,
	showAuraCooldown = true,
	noCooldownCount = false,
	auraSize = 16,
	auraMaxRows = 2,
	aurasAtBottom = false,
	auraOffset = 0,
	
	-- icons
	enableIcons = true,
	iconRaid = true,
	iconFaction = false,
	iconCombat = false,
	iconClass = false,
	iconSize = 24,
	iconMaxIcons = 4,
	iconAnchor = "LEFT",
	iconAnchorHorizontalAlign = "LEFT",
	iconAnchorVerticalAlign = "TOP",
	iconAnchorGrowDirection = "DOWN",
	iconOffsetX = 0,
	iconOffsetY = 0,
	
	-- anchors
	enableAnchor = true,
	
	anchorWorldUnitType = "normal",
	anchorWorldUnitPoint = "BOTTOMRIGHT",
	anchorWorldTipType = "normal",
	anchorWorldTipPoint = "BOTTOMRIGHT",
	anchorFrameUnitType = "normal",
	anchorFrameUnitPoint = "BOTTOMRIGHT",
	anchorFrameTipType = "normal",
	anchorFrameTipPoint = "BOTTOMRIGHT",
	
	enableAnchorOverrideWorldUnitDuringChallengeMode = false,
	anchorWorldUnitTypeDuringChallengeMode = "normal",
	anchorWorldUnitPointDuringChallengeMode = "BOTTOMRIGHT",
	enableAnchorOverrideWorldTipDuringChallengeMode = false,
	anchorWorldTipTypeDuringChallengeMode = "normal",
	anchorWorldTipPointDuringChallengeMode = "BOTTOMRIGHT",
	enableAnchorOverrideFrameUnitDuringChallengeMode = false,
	anchorFrameUnitTypeDuringChallengeMode = "normal",
	anchorFrameUnitPointDuringChallengeMode = "BOTTOMRIGHT",
	enableAnchorOverrideFrameTipDuringChallengeMode = false,
	anchorFrameTipTypeDuringChallengeMode = "normal",
	anchorFrameTipPointDuringChallengeMode = "BOTTOMRIGHT",
	
	enableAnchorOverrideWorldUnitDuringSkyriding = false,
	anchorWorldUnitTypeDuringSkyriding = "normal",
	anchorWorldUnitPointDuringSkyriding = "BOTTOMRIGHT",
	enableAnchorOverrideWorldTipDuringSkyriding = false,
	anchorWorldTipTypeDuringSkyriding = "normal",
	anchorWorldTipPointDuringSkyriding = "BOTTOMRIGHT",
	enableAnchorOverrideFrameUnitDuringSkyriding = false,
	anchorFrameUnitTypeDuringSkyriding = "normal",
	anchorFrameUnitPointDuringSkyriding = "BOTTOMRIGHT",
	enableAnchorOverrideFrameTipDuringSkyriding = false,
	anchorFrameTipTypeDuringSkyriding = "normal",
	anchorFrameTipPointDuringSkyriding = "BOTTOMRIGHT",
	
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
	
	-- hiding
	hideTipsDuringChallengeModeWorldUnits = false,
	hideTipsDuringChallengeModeWorldTips = false,
	hideTipsDuringChallengeModeFrameUnits = false,
	hideTipsDuringChallengeModeFrameTips = false,
	hideTipsDuringChallengeModeUnitTips = false,
	hideTipsDuringChallengeModeSpellTips = false,
	hideTipsDuringChallengeModeItemTips = false,
	hideTipsDuringChallengeModeActionTips = false,
	hideTipsDuringChallengeModeExpBarTips = false,
	
	hideTipsDuringSkyridingWorldUnits = false,
	hideTipsDuringSkyridingWorldTips = false,
	hideTipsDuringSkyridingFrameUnits = false,
	hideTipsDuringSkyridingFrameTips = false,
	hideTipsDuringSkyridingUnitTips = false,
	hideTipsDuringSkyridingSpellTips = false,
	hideTipsDuringSkyridingItemTips = false,
	hideTipsDuringSkyridingActionTips = false,
	hideTipsDuringSkyridingExpBarTips = false,
	
	hideTipsInCombatWorldUnits = false,
	hideTipsInCombatWorldTips = false,
	hideTipsInCombatFrameUnits = false,
	hideTipsInCombatFrameTips = false,
	hideTipsInCombatUnitTips = false,
	hideTipsInCombatSpellTips = false,
	hideTipsInCombatItemTips = false,
	hideTipsInCombatActionTips = false,
	hideTipsInCombatExpBarTips = false,
	
	hideTipsWorldUnits = false,
	hideTipsWorldTips = false,
	hideTipsFrameUnits = false,
	hideTipsFrameTips = false,
	hideTipsUnitTips = false,
	hideTipsSpellTips = false,
	hideTipsItemTips = false,
	hideTipsActionTips = false,
	hideTipsExpBarTips = false,
	
	showHiddenModifierKey = "shift",
	
	-- hyperlink
	enableChatHoverTips = true
};

-- extended config
local TT_ExtendedConfig = {};

-- custom class colors config
TT_ExtendedConfig.customClassColors = {}; -- set during event ADDON_LOADED and tt:ApplyConfig()

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
	tile = true,                                           -- set during event ADDON_LOADED and tt:ApplyConfig()
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
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. this call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					-- update: fixed in df 10.1.5, but not in catac 4.4.0 or classic era 1.15.2.
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnTooltipCleared", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ShoppingTooltip2"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. this call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					-- update: fixed in df 10.1.5, but not in catac 4.4.0 or classic era 1.15.2.
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnTooltipCleared", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ItemRefTooltip"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- HOOK: DisplayDungeonScoreLink() to set class colors to backdrop border, see "ItemRef.lua"
					LibFroznFunctions:HookSecureFuncIfExists("DisplayDungeonScoreLink", function(link)
						if (cfg.classColoredBorder) and (tip:IsShown()) then
							local splits = StringSplitIntoTable(":", link);
							
							-- bad link, return.
							if (not splits) then
								return;
							end
							
							local classID = splits[5];
							local classColor = LibFroznFunctions:GetClassColor(classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
							
							tt:SetBackdropBorderColorLocked(tip, classColor.r, classColor.g, classColor.b);
						end
					end);
					
					-- HOOK: ItemRefTooltipMixin:ItemRefSetHyperlink() to adjust padding for close button if needed. additionally considering TextRight1 here.
					LibFroznFunctions:HookSecureFuncIfExists(ItemRefTooltip, "ItemRefSetHyperlink", function(self, link)
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
			},
			["ItemRefShoppingTooltip1"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. this call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					-- update: fixed in df 10.1.5, but not in catac 4.4.0 or classic era 1.15.2.
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnTooltipCleared", function(tip)
							tip:ClearHandlerInfo();
						end);
					end
				end
			},
			["ItemRefShoppingTooltip2"] = {
				applyAppearance = true, applyScaling = true, applyAnchor = false,
				hookFnForFrame = function(TT_CacheForFrames, tip)
					-- workaround for blizzard bug in df 10.1.0: tooltipData won't be reset for (ItemRef)ShoopingTooltip1/2 because ClearHandlerInfo() won't be called in event OnHide. this call is missing in script handlers of ShoppingTooltipTemplate (see GameTooltip.xml). For GameTooltip this is included in function GameTooltip_OnHide().
					-- update: fixed in df 10.1.5, but not in catac 4.4.0 or classic era 1.15.2.
					
					-- since df 10.0.2
					if (TooltipUtil) then
						tip:HookScript("OnTooltipCleared", function(tip)
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
			["SettingsTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			
			-- 3rd party addon tooltips
			["AceConfigDialogTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["LibDBIconTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["AtlasLootTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["QuestHelperTooltip"] = { applyAppearance = true, applyAnchor = true, applyScaling = true },
			["QuestGuru_QuestWatchTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["PlaterNamePlateAuraTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		},
		hookFnForAddOn = function(TT_CacheForFrames)
			-- HOOK: LFGListFrame.ApplicationViewer.ScrollBox:OnEnter() respectively LFGListApplicantMember_OnEnter() to set class colors to backdrop border, see "LFGList.lua"
			if (LFGListFrame) then
				local function LFGLFAVSB_OnEnter_Hook(self)
					if (cfg.classColoredBorder) and (GameTooltip:IsShown()) then
						local applicantID = self:GetParent().applicantID;
						local memberIdx = self.memberIdx;
						
						local name, classFile, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dungeonScore, pvpItemLevel = C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx);
						
						if (name) then
							local classColor = LibFroznFunctions:GetClassColorByClassFile(classFile, "PRIEST", cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
							
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
			
			-- UIDropDownMenu
			
			-- add UIDropDownMenu frames
			local function addUIDropDownMenuFrames(last_UIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_MAXLEVELS, prefixName)
				local UIDROPDOWNMENU_MAXLEVELS = _G[nameUIDROPDOWNMENU_MAXLEVELS];
				
				for i = last_UIDROPDOWNMENU_MAXLEVELS + 1, UIDROPDOWNMENU_MAXLEVELS do -- see "UIDropDownMenu.lua"
					tt:AddModifiedTip(prefixName .. i);
				end
				
				return UIDROPDOWNMENU_MAXLEVELS;
			end
			
			-- reapply appearance to UIDropDownMenu
			local function reapplyAppearanceToUIDropDownMenu(nameUIDROPDOWNMENU_OPEN_MENU, prefixName, level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode)
				-- check if insecure interaction with the tip is currently forbidden
				local _level = (level or 1);
				local tip = _G[prefixName .. _level];
				
				if (tip:IsForbidden()) then
					return;
				end
				
				-- reapply appearance to tip
				tt:SetAppearanceToTip(tip);
				
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
				
				-- check if tip is shown
				if (not tip:IsShown()) then
					return;
				end
				
				-- fix anchoring because of different scale, see ToggleDropDownMenu() in "UIDropDownMenu.lua"
				local UIDROPDOWNMENU_OPEN_MENU = _G[nameUIDROPDOWNMENU_OPEN_MENU];
				local TT_UIScale = UIParent:GetEffectiveScale();
				local tipEffectiveScale = tip:GetEffectiveScale();
				local point, relativePoint, relativeTo;
				
				local function GetChild(frame, name, key)
					if (frame[key]) then
						return frame[key];
					else
						return _G[name..key];
					end
				end
				
				-- adjust xOffset for addon "Titan Panel"
				if (type(anchorName) == "string") and (anchorName:match("^Titan_Bar__Display_Bar(%d*)")) then
					xOffset = xOffset * TT_UIScale;
				end
				
				-- frame to anchor the dropdown menu to
				local anchorFrame;
				
				-- display stuff
				-- level specific stuff
				if (_level == 1) then
					-- UIDropDownMenuDelegate:SetAttribute("openmenu", dropDownFrame);
					tip:ClearAllPoints();
					
					-- if there's no specified anchorName then use left side of the dropdown menu
					if (not anchorName) then
						-- see if the anchor was set manually using setanchor
						if (dropDownFrame.xOffset) then
							xOffset = dropDownFrame.xOffset;
						end
						if (dropDownFrame.yOffset) then
							yOffset = dropDownFrame.yOffset;
						end
						if (dropDownFrame.point) then
							point = dropDownFrame.point;
						end
						if (dropDownFrame.relativeTo) then
							relativeTo = dropDownFrame.relativeTo;
						else
							relativeTo = GetChild(UIDROPDOWNMENU_OPEN_MENU, UIDROPDOWNMENU_OPEN_MENU:GetName(), "Left");
						end
						if (dropDownFrame.relativePoint) then
							relativePoint = dropDownFrame.relativePoint;
						end
					elseif (anchorName == "cursor") then
						relativeTo = nil;
						local cursorX, cursorY = LibFroznFunctions:GetCursorPosition();
						-- cursorX = cursorX/uiScale;
						-- cursorY =  cursorY/uiScale;
						
						if (not xOffset) then
							xOffset = 0;
						end
						if (not yOffset) then
							yOffset = 0;
						end
						
						xOffset = cursorX + xOffset;
						yOffset = cursorY + yOffset;
					else
						-- see if the anchor was set manually using setanchor
						if (dropDownFrame.xOffset) then
							xOffset = dropDownFrame.xOffset;
						end
						if (dropDownFrame.yOffset) then
							yOffset = dropDownFrame.yOffset;
						end
						if (dropDownFrame.point) then
							point = dropDownFrame.point;
						end
						if (dropDownFrame.relativeTo) then
							relativeTo = dropDownFrame.relativeTo;
						else
							relativeTo = anchorName;
						end
						if (dropDownFrame.relativePoint) then
							relativePoint = dropDownFrame.relativePoint;
						end
					end
					if (not xOffset or not yOffset) then
						xOffset = 8;
						yOffset = 22;
					end
					if (not point) then
						point = "TOPLEFT";
					end
					if (not relativePoint) then
						relativePoint = "BOTTOMLEFT";
					end
					-- tip:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset);
					tip:SetPoint(point, relativeTo, relativePoint, xOffset / tipEffectiveScale, yOffset / tipEffectiveScale);
				else
					if (not dropDownFrame) then
						dropDownFrame = UIDROPDOWNMENU_OPEN_MENU;
					end
					tip:ClearAllPoints();
					-- if this is a dropdown button, not the arrow anchor it to itself
					if (strsub(button:GetParent():GetName(), 0, prefixName:len()) == prefixName and strlen(button:GetParent():GetName()) == prefixName:len() + 1) then
						anchorFrame = button;
					else
						anchorFrame = button:GetParent();
					end
					point = "TOPLEFT";
					relativePoint = "TOPRIGHT";
					tip:SetPoint(point, anchorFrame, relativePoint, 0, 0);
				end
				
				-- hack since GetCenter() is returning coords relative to 1024x768
				local x, y = tip:GetCenter();
				-- hack will fix this in next revision of dropdowns
				-- if (not x or not y) then
					-- listFrame:Hide();
					-- return;
				-- end
				
				-- we just move level 1 enough to keep it on the screen. we don't necessarily change the anchors.
				if (_level == 1) then
					-- local offLeft = listFrame:GetLeft()/uiScale;
					-- local offRight = (GetScreenWidth() - listFrame:GetRight())/uiScale;
					-- local offTop = (GetScreenHeight() - listFrame:GetTop())/uiScale;
					-- local offBottom = listFrame:GetBottom()/uiScale;
					local offLeft = tip:GetLeft() * tipEffectiveScale;
					local offRight = GetScreenWidth() * TT_UIScale - tip:GetRight() * tipEffectiveScale;
					local offTop = GetScreenHeight() * TT_UIScale - tip:GetTop() * tipEffectiveScale;
					local offBottom = tip:GetBottom() * tipEffectiveScale;
					
					local xAddOffset, yAddOffset = 0, 0;
					if (offLeft < 0) then
						xAddOffset = -offLeft;
					elseif (offRight < 0) then
						xAddOffset = offRight;
					end
					
					if (offTop < 0) then
						yAddOffset = offTop;
					elseif (offBottom < 0) then
						yAddOffset = -offBottom;
					end
					
					tip:ClearAllPoints();
					if (anchorName == "cursor") then
						-- tip:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
						tip:SetPoint(point, relativeTo, relativePoint, (xOffset + xAddOffset) / tipEffectiveScale, (yOffset + yAddOffset) / tipEffectiveScale);
					else
						-- tip:SetPoint(point, relativeTo, relativePoint, xOffset + xAddOffset, yOffset + yAddOffset);
						tip:SetPoint(point, relativeTo, relativePoint, (xOffset + xAddOffset) / tipEffectiveScale, (yOffset + yAddOffset) / tipEffectiveScale);
					end
				else
					-- determine whether the menu is off the screen or not
					local offscreenY, offscreenX;
					if ((y - tip:GetHeight()/2) < 0) then
						offscreenY = 1;
					end
					-- if (tip:GetRight() > GetScreenWidth()) then
					if (tip:GetRight() * tipEffectiveScale > GetScreenWidth() * TT_UIScale) then
						offscreenX = 1;
					end
					if (offscreenY and offscreenX) then
						point = gsub(point, "TOP(.*)", "BOTTOM%1");
						point = gsub(point, "(.*)LEFT", "%1RIGHT");
						relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
						relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
						xOffset = -11;
						yOffset = -14;
					elseif (offscreenY) then
						point = gsub(point, "TOP(.*)", "BOTTOM%1");
						relativePoint = gsub(relativePoint, "TOP(.*)", "BOTTOM%1");
						xOffset = 0;
						yOffset = -14;
					elseif (offscreenX) then
						point = gsub(point, "(.*)LEFT", "%1RIGHT");
						relativePoint = gsub(relativePoint, "(.*)RIGHT", "%1LEFT");
						xOffset = -11;
						yOffset = 14;
					else
						xOffset = 0;
						yOffset = 14;
					end
					
					tip:ClearAllPoints();
					-- listFrame.parentLevel = tonumber(strmatch(anchorFrame:GetName(), "DropDownList(%d+)"));
					-- listFrame.parentID = anchorFrame:GetID();
					-- tip:SetPoint(point, anchorFrame, relativePoint, xOffset, yOffset);
					tip:SetPoint(point, anchorFrame, relativePoint, xOffset / TT_UIScale, yOffset / TT_UIScale);
				end
			end
			
			-- style UIDropDownMenu
			local function styleUIDropDownMenu(nameUIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_OPEN_MENU, tbl, returningSelf, prefixName)
				local last_UIDROPDOWNMENU_MAXLEVELS = 0;
				
				last_UIDROPDOWNMENU_MAXLEVELS = addUIDropDownMenuFrames(last_UIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_MAXLEVELS, prefixName);
				
				-- HOOK: UIDropDownMenu_CreateFrames() to add the new frames
				if (tbl) then
					if (returningSelf) then
						hooksecurefunc(tbl, "UIDropDownMenu_CreateFrames", function(self, level, index)
							last_UIDROPDOWNMENU_MAXLEVELS = addUIDropDownMenuFrames(last_UIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_MAXLEVELS, prefixName);
						end);
					else
						hooksecurefunc(tbl, "UIDropDownMenu_CreateFrames", function(level, index)
							last_UIDROPDOWNMENU_MAXLEVELS = addUIDropDownMenuFrames(last_UIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_MAXLEVELS, prefixName);
						end);
					end
				else
					hooksecurefunc("UIDropDownMenu_CreateFrames", function(level, index)
						last_UIDROPDOWNMENU_MAXLEVELS = addUIDropDownMenuFrames(last_UIDROPDOWNMENU_MAXLEVELS, nameUIDROPDOWNMENU_MAXLEVELS, prefixName);
					end);
				end
				
				-- HOOK: ToggleDropDownMenu() to reapply appearance because e.g. 1-pixel borders sometimes aren't displayed correctly and to reapply scale
				if (tbl) then
					if (returningSelf) then
						hooksecurefunc(tbl, "ToggleDropDownMenu", function(self, level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode)
							-- reapply appearance to UIDropDownMenu
							reapplyAppearanceToUIDropDownMenu(nameUIDROPDOWNMENU_OPEN_MENU, prefixName, level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode);
						end);
					else
						hooksecurefunc(tbl, "ToggleDropDownMenu", function(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode)
							-- reapply appearance to UIDropDownMenu
							reapplyAppearanceToUIDropDownMenu(nameUIDROPDOWNMENU_OPEN_MENU, prefixName, level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode);
						end);
					end
				else
					hooksecurefunc("ToggleDropDownMenu", function(level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode)
						-- reapply appearance to UIDropDownMenu
						reapplyAppearanceToUIDropDownMenu(nameUIDROPDOWNMENU_OPEN_MENU, prefixName, level, value, dropDownFrame, anchorName, xOffset, yOffset, menuList, button, autoHideDelay, overrideDisplayMode);
					end);
				end
			end
			
			-- style UIDropDownMenu
			styleUIDropDownMenu("UIDROPDOWNMENU_MAXLEVELS", "UIDROPDOWNMENU_OPEN_MENU", nil, nil, "DropDownList");
			
			-- LibUIDropDownMenu-4.0, e.g used by addon BetterBags
			local LibUIDropDownMenu = LibStub:GetLibrary("LibUIDropDownMenu-4.0", true);
			
			if (LibUIDropDownMenu) then
				-- style LibUIDropDownMenu-4.0
				styleUIDropDownMenu("L_UIDROPDOWNMENU_MAXLEVELS", "L_UIDROPDOWNMENU_OPEN_MENU", LibUIDropDownMenu, true, "L_DropDownList");
			end
			
			-- LibDropDownMenu, e.g used by addon Broker_Everything
			local LibDropDownMenu = LibStub:GetLibrary("LibDropDownMenu", true);
			
			if (LibDropDownMenu) then
				-- style LibDropDownMenu
				styleUIDropDownMenu("UIDROPDOWNMENU_MAXLEVELS", "UIDROPDOWNMENU_OPEN_MENU", LibDropDownMenu, false, "LibDropDownMenu_List");
			end
			
			-- LibDropdown-1.0, e.g used by addon Recount
			local LibDropdown = LibStub:GetLibrary("LibDropdown-1.0", true);
			
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
			local LibDropdownMC = LibStub:GetLibrary("LibDropdownMC-1.0", true);
			
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
			
			-- LibQTip-1.0, e.g. used by addon Broker_Location
			local LibQTip = LibStub:GetLibrary("LibQTip-1.0", true);
			
			if (LibQTip) then
				local oldLibQTipAcquire = LibQTip.Acquire;
				
				LibQTip.Acquire = function(self, key, ...)
					local tooltip = oldLibQTipAcquire(self, key, ...);
					
					tt:AddModifiedTipExtended(tooltip, {
						applyAppearance = true,
						applyScaling = true,
						applyAnchor = false,
						isFromLibQTip = true
					});
					
					return tooltip;
				end
				
				-- disable error message on HookScript()
				LibQTip.tipPrototype.HookScript = nil;
			end
			
			-- LibExtraTip-1, e.g used by addon BiS-Tooltip
			local LibExtraTip = LibStub:GetLibrary("LibExtraTip-1", true);
			
			if (LibExtraTip) then
				local oldLibExtraTipGetFreeExtraTipObject = LibExtraTip.GetFreeExtraTipObject;
				local LETEThooked = {};
				
				LibExtraTip.GetFreeExtraTipObject = function(self, ...)
					local extraTip = oldLibExtraTipGetFreeExtraTipObject(self, ...);
					
					if (not LETEThooked[extraTip]) then
						tt:AddModifiedTip(extraTip);
						LETEThooked[extraTip] = true;
					end
					
					return extraTip;
				end
			end
		end
	},
	["Blizzard_CharacterCustomize"] = {
		frames = {
			["CharCustomizeTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true },
			["CharCustomizeNoHeaderTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		}
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
						
						classColor = LibFroznFunctions:GetClassColor(classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
					else
						classColor = LibFroznFunctions:GetClassColor(5, nil, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
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
	["ElvUI"] = {
		frames = {
			["ElvUI_SpellBookTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = true }
		}
	},
	["OPie"] = {
		hookFnForAddOn = function(TT_CacheForFrames)
			local OPie = _G["OPie"];
			
			if (OPie) and (OPie.NotGameTooltip) then
				tt:AddModifiedTipExtended(OPie.NotGameTooltip, {
					applyAppearance = true,
					applyScaling = true,
					applyAnchor = true
				});
			end
		end
	},
	["RaiderIO"] = {
		frames = {
			["RaiderIO_ProfileTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = false, waitSecondsForLookupFrameName = 1 },
			["RaiderIO_SearchTooltip"] = { applyAppearance = true, applyScaling = true, applyAnchor = false, waitSecondsForLookupFrameName = 1 }
		}
	}
};

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
-- frameName                                       frame name, nil for anonymous frames without a parent.
-- config                                          see params from "TT_ExtendedConfig.tipsToModify"
-- originalOffsetsForPreventingOffScreenAvailable  original offsets for preventing additional elements from moving off-screen available
-- originalLeftOffsetForPreventingOffScreen        original left offset for preventing additional elements from moving off-screen
-- originalRightOffsetForPreventingOffScreen       original right offset for preventing additional elements from moving off-screen
-- originalTopOffsetForPreventingOffScreen         original top offset for preventing additional elements from moving off-screen
-- originalBottomOffsetForPreventingOffScreen      original bottom offset for preventing additional elements from moving off-screen
-- currentDisplayParams                            current display parameters
-- gradient                                        optional. gradient texture for frame

-- params for 2nd key (currentDisplayParams):
-- isSet                                         true if current display parameters are set, false otherwise.
-- isSetTemporarily                              true if current display parameters are temporarily set, false otherwise.
--
-- isSetTimestamp                                timestamp of current display parameters were set, nil otherwise.
--
-- tipContent                                    see TT_TIP_CONTENT
-- hideTip                                       true if tip will be hidden, false otherwise.
-- ignoreNextSetCurrentDisplayParams             true if ignoring next tooltip's current display parameters to be set, nil otherwise.
-- ignoreSetCurrentDisplayParamsOnTimestamp      timestamp of ignoring tooltip's current display parameters to be set, nil otherwise.
--
-- lockedBackdropInfo                            locked backdropInfo, nil otherwise.
-- lockedBackdropColor                           locked backdrop color, nil otherwise.
-- lockedBackdropBorderColor                     locked backdrop border color, nil otherwise.
--
-- extraPaddingRightForMinimumWidth              value for extra padding right for minimum width, nil otherwise.
-- extraPaddingRightForCloseButton               value for extra padding right to fit close button, nil otherwise.
-- extraPaddingBottomForBars                     value for extra padding bottom to fit health/power bars, nil otherwise.
--
-- modifiedOffsetsForPreventingOffScreen         modified offsets for preventing additional elements from moving off-screen
--
-- defaultAnchored                               true if tip is default anchored, false otherwise.
-- defaultAnchoredParentFrame                    tip's parent frame if default anchored, nil otherwise.
-- anchorFrameName                               anchor frame name of tip, values "WorldUnit", "WorldTip", "FrameUnit", "FrameTip"
-- anchorType                                    anchor type for tip
-- anchorPoint                                   anchor point for tip
--
-- unitRecord                                    table with information about the displayed unit, nil otherwise.
--   .guid                                       guid of unit
--   .id                                         id of unit
--   .isPlayer                                   true if it's a player unit, false for other units.
--   .name                                       name of unit
--   .nameWithTitle                              name with title of unit
--   .rpName                                     role play name of unit (Mary Sue Protocol)
--   .originalName                               original name of unit in GameTooltip
--
--   .className                                  localized class name of unit, e.g. "Warrior" or "Guerrier"
--   .classFile                                  locale-independent class file of unit, e.g. "WARRIOR"
--   .classID                                    class id of unit
--
--   .reactionIndex                              unit reaction index, see LFF_UNIT_REACTION_INDEX
--   .health                                     unit health
--   .healthMax                                  unit max health
--
--   .powerType                                  unit power type
--   .power                                      unit power
--   .powerMax                                   unit max power
--
--   .isColorBlind                               true if color blind mode is enabled, false otherwise.
--   .isTipTacDeveloper                          true if it's a unit of a TipTac developer, false for other units.
--
-- firstCallDoneUnitAppearance                   true if first call of unit appearace is done, false otherwise.
-- timestampStartUnitAppearance                  timestamp of start of unit appearance, nil otherwise.
-- timestampStartCustomUnitFadeout               timestamp of start of custom unit fadeout, nil otherwise.
--
-- tipLineInfoIndex                              line index of ttStyle's info for tip, nil otherwise.
-- tipLineTargetedByIndex                        line index of ttStyle's target by for tip, nil otherwise.
-- petLineLevelIndex                             line index of ttStyle's level for pet, nil otherwise.
-- mergeLevelLineWithGuildName                   true if there is no separate line for the guild name. in this case the guild name has to be merged with the level line if not in color blind mode. nil otherwise.
-- isSetTopOverlayToHighlightTipTacDeveloper     true if the top overlay has been set to highlight TipTac developer, nil otherwise.
-- isSetBottomOverlayToHighlightTipTacDeveloper  true if the bottom overlay has been set to highlight TipTac developer, nil otherwise.
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

-- TipTac developer
local TT_TipTacDeveloper = {
	-- Frozn45
	{
		regionID = 3, -- Europe
		guid = "Player-1099-00D6E047" -- Camassea - Rexxar
	}, {
		regionID = 3, -- Europe
		guid = "Player-1099-006E9FB3" -- Valadenya - Rexxar
	}, {
		regionID = 3, -- Europe
		guid = "Player-1099-025F2F49" -- Gorath - Rexxar
	}
};

-- others
local TT_IsConfigLoaded = false;
local TT_IsApplyTipAppearanceAndHooking = false;
local TT_CurrentRegionID = GetCurrentRegion();

----------------------------------------------------------------------------------------------------
--                                        Helper Functions                                        --
----------------------------------------------------------------------------------------------------

-- add message to (selected) chat frame
local replacementsForChatFrame = {
	["{caption:"] = TT_COLOR.text.caption:GenerateHexColorMarkup(),
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
}, MOD_NAME .. " - TipTac Anchor");

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
	
	-- inform group that the config is about to be loaded
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnConfigPreLoaded", TT_CacheForFrames, cfg, TT_ExtendedConfig);
	
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
-- eventName                           description                                                                             additional payload
-- ----------------------------------  --------------------------------------------------------------------------------------  ------------------------------------------------------------
-- OnConfigPreLoaded                   before config has been loaded                                                           TT_CacheForFrames, cfg, TT_ExtendedConfig
-- OnConfigLoaded                      config has been loaded                                                                  TT_CacheForFrames, cfg, TT_ExtendedConfig
-- OnApplyConfig                       config settings need to be applied                                                      TT_CacheForFrames, cfg, TT_ExtendedConfig
-- OnApplyTipAppearanceAndHooking      every tooltip's appearance and hooking needs to be applied                              TT_CacheForFrames, cfg, TT_ExtendedConfig
--                                                                                                                             
-- OnTipAddedToCache                   tooltip has been added to cache for frames                                              TT_CacheForFrames, tooltip
--                                                                                                                             
-- OnTipSetCurrentDisplayParams        tooltip's current display parameters has to be set                                      TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
-- OnTipPostSetCurrentDisplayParams    after tooltip's current display parameters has to be set                                TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
--                                                                                                                             
-- OnTipSetHidden                      check if tooltip needs to be hidden                                                     TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
-- OnTipSetStyling                     tooltip's styling needs to be set                                                       TT_CacheForFrames, tooltip, currentDisplayParams, tipContent
--                                                                                                                             
-- OnUnitTipPreStyle                   before unit tooltip is being styled                                                     TT_CacheForFrames, tooltip, currentDisplayParams, first
-- OnUnitTipStyle                      unit tooltip is being styled                                                            TT_CacheForFrames, tooltip, currentDisplayParams, first
-- OnUnitTipResize                     unit tooltip is being resized                                                           TT_CacheForFrames, tooltip, currentDisplayParams, first
-- OnUnitTipPostStyle                  after unit tooltip has been styled and has the final size                               TT_CacheForFrames, tooltip, currentDisplayParams, first
--                                                                                                                             
-- OnTipResized                        tooltip has been resized                                                                TT_CacheForFrames, tooltip, currentDisplayParams
-- OnTipRescaled                       tooltip has been rescaled                                                               TT_CacheForFrames, tooltip, currentDisplayParams
--                                                                                                                             
-- OnTipResetCurrentDisplayParams      tooltip's current display parameters has to be reset                                    TT_CacheForFrames, tooltip, currentDisplayParams
-- OnTipPostResetCurrentDisplayParams  after tooltip's current display parameters has to be reset                              TT_CacheForFrames, tooltip, currentDisplayParams
--                                                                                                                             
-- SetDefaultAnchorHook                hook for set default anchor to tip                                                      tooltip, parent
-- SetClampRectInsetsToTip             set clamp rect insets to tip for preventing additional elements from moving off-screen  tooltip, left, right, top, bottom
-- SetBackdropBorderColorLocked        set backdrop border color locked to tip                                                 tooltip, r, g, b, a
--                                                                                                                             
-- OnPlayerRegenEnabled                player regen has been enabled (after ending combat)                                     TT_CacheForFrames
-- OnPlayerRegenDisabled               player regen has been disabled (whenever entering combat)                               TT_CacheForFrames
-- OnUpdateBonusActionbar              bonus bar has been updated                                                              TT_CacheForFrames
-- OnModifierStateChanged              modifier state has been changed (shift/ctrl/alt keys are pressed or released)           TT_CacheForFrames

----------------------------------------------------------------------------------------------------
--                                       Interface Options                                        --
----------------------------------------------------------------------------------------------------

-- toggle options
function tt:ToggleOptions()
	local addOnName = MOD_NAME .. "Options";
	local loaded, reason = C_AddOns.LoadAddOn(addOnName);
	
	if (loaded) then
		local TipTacOptions = _G[addOnName];
		TipTacOptions:SetShown(not TipTacOptions:IsShown());
	else
		tt:AddMessageToChatFrame("{caption:" .. MOD_NAME .. "}: {error:Couldn't open " .. MOD_NAME .. " Options: [{highlight:" .. _G["ADDON_" .. reason] .. "}]. Please make sure the addon is enabled in the character selection screen.}"); -- see UIParentLoadAddOn()
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
		self.vers2:SetText(C_AddOns.GetAddOnMetadata(MOD_NAME, "Version") .. "\n" .. GetBuildInfo());
		
		self.notes = self:CreateFontString(nil, "ARTWORK");
		self.notes:SetFontObject(GameFontHighlight);
		self.notes:SetPoint("TOPLEFT", self.vers1, "BOTTOMLEFT", 0, -8);
		self.notes:SetText(C_AddOns.GetAddOnMetadata(MOD_NAME, "Notes"));
		
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
function tt:SetAddonCompartmentText(tip)
	tip:SetText(MOD_NAME);
	tip:AddLine(TT_COLOR.text.default:WrapTextInColorCode("Click to toggle options"));
end

function TipTac_OnAddonCompartmentClick(addonName, mouseButton)
	-- toggle options
	tt:ToggleOptions();
end

function TipTac_OnAddonCompartmentEnter(addonName, button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT");
	tt:SetAddonCompartmentText(GameTooltip);
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
		tt:AddMessageToChatFrame("{caption:" .. MOD_NAME .. "}: All {highlight:" .. MOD_NAME .. "} settings has been reset to their default values.");
		return;
	end
	
	-- invalid command
	local versionWoW, build = GetBuildInfo();
	local versionTipTac = C_AddOns.GetAddOnMetadata(MOD_NAME, "Version");
	
	UpdateAddOnMemoryUsage();
	
	tt:AddMessageToChatFrame("----- {highlight:%s %s} ----- {highlight:%.2f kb} ----- {highlight:WoW " .. versionWoW .. "} ----- ", MOD_NAME, versionTipTac, GetAddOnMemoryUsage(MOD_NAME));
	tt:AddMessageToChatFrame("The following {highlight:parameters} are valid for this addon:");
	tt:AddMessageToChatFrame("  {highlight:anchor} = Shows the anchor where the tooltip appears");
	tt:AddMessageToChatFrame("  {highlight:reset} = Resets all settings back to their default values");
end);

----------------------------------------------------------------------------------------------------
--                                     LibDataBroker Support                                      --
----------------------------------------------------------------------------------------------------

TT_LDB_DataObject = LibDataBroker:NewDataObject(MOD_NAME, {
	type = "launcher",
	icon = "Interface\\AddOns\\" .. MOD_NAME .. "\\media\\tiptac_logo",
	label = MOD_NAME,
	text = MOD_NAME,
	OnTooltipShow = function(tip)
		-- set text to tip
		tt:SetAddonCompartmentText(tip);
	end,
	OnClick = function(self, mouseButton)
		-- toggle options
		tt:ToggleOptions();
	end
});

----------------------------------------------------------------------------------------------------
--                                          Minimap Icon                                          --
----------------------------------------------------------------------------------------------------

-- register for group events
local minimapIconRegistered = false;

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnConfigLoaded = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- minimap icon already registered to LibDBIcon-1.0
		if (minimapIconRegistered) then
			return;
		end
		
		-- creation of new table needed so that saving of minimap config is possible
		if (LibFroznFunctions:IsTableEmpty(cfg.minimapConfig)) then
			cfg.minimapConfig = {};
		end
		
		-- register minimap icon to LibDBIcon-1.0
		LibDBIcon:Register(MOD_NAME, TT_LDB_DataObject, cfg.minimapConfig);
		
		minimapIconRegistered = true;
	end,
	OnApplyConfig = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- show/hide minimap icon
		if (cfg.showMinimapIcon) then
			local minimapButton = LibDBIcon:GetMinimapButton(MOD_NAME);
			
			if (minimapButton) and (not minimapButton:IsShown()) then
				LibDBIcon:Show(MOD_NAME);
			end
		else
			local minimapButton = LibDBIcon:GetMinimapButton(MOD_NAME);
			
			if (minimapButton) and (minimapButton:IsShown()) then
				LibDBIcon:Hide(MOD_NAME);
			end
		end
	end
}, MOD_NAME .. " - Minimap Icon");

----------------------------------------------------------------------------------------------------
--                                      Pixel Perfect Scale                                       --
----------------------------------------------------------------------------------------------------

-- get nearest pixel size (e.g. to avoid 1-pixel borders which are sometimes 0/2-pixels wide)
--
-- description:
-- - instead of pixels, lengths measure in scaled units equal to 1/768 of the screen height multiplied by a ratio.
-- - the ratio for frames can be determined with frame:GetEffectiveScale().
-- - the effective scale is the scale of the frame multiplied by all individual parent frame scales. if scale propagation on a frame in this chain has been disabled by calling SetIgnoreParentScale(true), the chain ends there.
--
-- - calculation to determine the pixel perfect size needed for given pixels:                                              PixelUtil.GetNearestPixelSize(pixels * TT_UIUnitFactor, 1) / frame:GetEffectiveScale()
-- - calculation to determine the pixel perfect size needed for given pixels shrinking/expanding with frame's scale:       PixelUtil.GetNearestPixelSize(pixels * TT_UIUnitFactor, frame:GetEffectiveScale())
-- - calculation to determine the pixel perfect size needed for given scaled units:                                        PixelUtil.GetNearestPixelSize(scaledUnits, 1) / frame:GetEffectiveScale()
-- - calculation to determine the pixel perfect size needed for given scaled units shrinking/expanding with frame's scale: PixelUtil.GetNearestPixelSize(scaledUnits, frame:GetEffectiveScale())
local TT_PhysicalScreenWidth, TT_PhysicalScreenHeight, TT_UIUnitFactor, TT_UIScale;

function tt:GetNearestPixelSize(tip, size, pixelPerfect, ignoreScale)
	local tipEffectiveScale = tip:GetEffectiveScale();
	local realSize = ((pixelPerfect and (size * TT_UIUnitFactor)) or size);
	local targetScale = (ignoreScale and 1 or tipEffectiveScale);
	local frameScaleAdjustmentToAchieveTargetScale = (ignoreScale and tip:GetEffectiveScale() or 1);
	
	return PixelUtil.GetNearestPixelSize(realSize, targetScale) / frameScaleAdjustmentToAchieveTargetScale;
end

-- update pixel perfect scale
function tt:UpdatePixelPerfectScale()
	local currentConfig = (TT_IsConfigLoaded and cfg or TT_DefaultConfig);
	
	TT_PhysicalScreenWidth, TT_PhysicalScreenHeight = GetPhysicalScreenSize();
	TT_UIUnitFactor = 768.0 / TT_PhysicalScreenHeight;
	TT_UIScale = UIParent:GetEffectiveScale();
end

tt:UpdatePixelPerfectScale();

-- EVENT: UI scale changed
function tt:UI_SCALE_CHANGED(event)
	-- apply config
	self:ApplyConfig();
end

-- HOOK: UIParent scale changed
hooksecurefunc(UIParent, "SetScale", function()
	-- apply config
	tt:ApplyConfig();
end);

-- EVENT: display size changed
function tt:DISPLAY_SIZE_CHANGED(event)
	-- apply config
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
	-- update default config for custom class colors
	local numClasses = GetNumClasses();
	
	for i = 1, numClasses do
		local className, classFile = GetClassInfo(i);
		
		if (classFile) then
			local camelCasedClassFile = LibFroznFunctions:CamelCaseText(classFile);
			local classColor = RAID_CLASS_COLORS[classFile];
			
			-- make shure that ColorMixin methods are available
			if (type(classColor.WrapTextInColorCode) ~= "function") then
				classColor = CreateColor(classColor.r, classColor.g, classColor.b, classColor.a);
			end
			
			TT_DefaultConfig["colorCustomClass" .. camelCasedClassFile] = {
				classColor:GetRGBA()
			};
		end
	end
	
	-- update default config for fonts
	TT_DefaultConfig.fontFace, TT_DefaultConfig.fontSize, TT_DefaultConfig.fontFlags = GameFontNormal:GetFont();
	TT_DefaultConfig.fontSize = Round(TT_DefaultConfig.fontSize);
	TT_DefaultConfig.fontFlags = TT_DefaultConfig.fontFlags:match("^[^,]*");
	
	TT_DefaultConfig.barFontFace, TT_DefaultConfig.barFontSize, TT_DefaultConfig.barFontFlags = NumberFontNormalSmall:GetFont();
	TT_DefaultConfig.barFontSize = Round(TT_DefaultConfig.barFontSize);
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
	
	-- set custom class colors config
	self:SetCustomClassColorsConfig();
	
	-- set tooltip backdrop config
	self:SetTipBackdropConfig();
end

-- set custom class colors config
function tt:SetCustomClassColorsConfig()
	local currentConfig = (TT_IsConfigLoaded and cfg or TT_DefaultConfig);
	local numClasses = GetNumClasses();
	
	for i = 1, numClasses do
		local className, classFile = GetClassInfo(i);
		
		if (classFile) then
			local camelCasedClassFile = LibFroznFunctions:CamelCaseText(classFile);
			
			TT_ExtendedConfig.customClassColors[classFile] = CreateColor(unpack(currentConfig["colorCustomClass" .. camelCasedClassFile]));
		end
	end
end

-- set tooltip backdrop config (examples see "Backdrop.lua")
function tt:SetTipBackdropConfig()
	local currentConfig = (TT_IsConfigLoaded and cfg or TT_DefaultConfig);
	
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
	
	TT_ExtendedConfig.tipBackdrop.tile = (currentConfig.tipBackdropBGLayout == "tile");
	TT_ExtendedConfig.tipBackdrop.edgeSize = currentConfig.backdropEdgeSize;
	
	TT_ExtendedConfig.tipBackdrop.insets.left = currentConfig.backdropInsets;
	TT_ExtendedConfig.tipBackdrop.insets.right = currentConfig.backdropInsets;
	TT_ExtendedConfig.tipBackdrop.insets.top = currentConfig.backdropInsets;
	TT_ExtendedConfig.tipBackdrop.insets.bottom = currentConfig.backdropInsets;
	
	TT_ExtendedConfig.backdropColor:SetRGBA(unpack(currentConfig.tipColor));
	TT_ExtendedConfig.backdropBorderColor:SetRGBA(unpack(currentConfig.tipBorderColor));
	
	-- set tooltip padding config for GameTooltip
	self:SetTipPaddingConfig();
end

-- set tooltip padding config for GameTooltip
function tt:SetTipPaddingConfig()
	local currentConfig = (TT_IsConfigLoaded and cfg or TT_DefaultConfig);
	
	if (currentConfig.enableBackdrop) then
		TT_ExtendedConfig.tipPaddingForGameTooltip.right, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom, TT_ExtendedConfig.tipPaddingForGameTooltip.left, TT_ExtendedConfig.tipPaddingForGameTooltip.top = TT_ExtendedConfig.tipBackdrop.insets.right + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.bottom + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.left + TT_ExtendedConfig.tipPaddingForGameTooltip.offset, TT_ExtendedConfig.tipBackdrop.insets.top + TT_ExtendedConfig.tipPaddingForGameTooltip.offset;
		
		-- no padding if GameTooltip:SetPadding() doesn't have the optional left and top parameters (available since BfA 8.2.0)
		if (not LibFroznFunctions.hasWoWFlavor.GameTooltipSetPaddingWithLeftAndTop) then
			TT_ExtendedConfig.tipPaddingForGameTooltip.right = 0;
			TT_ExtendedConfig.tipPaddingForGameTooltip.bottom = 0;
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
	
	-- set custom class colors config
	self:SetCustomClassColorsConfig();
	
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
		self.ADDON_LOADED = nil;
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
			self:AddMessageToChatFrame("{caption:" .. MOD_NAME .. "}: {error:No valid Font set in option tab {highlight:Font}. Switching to default Font.}");
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
	self:SetScaleToTip(tip, true);
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
			
			-- remove addon config from tips to modify
			local addOnConfig_hookFnForAddOn = addOnConfig.hookFnForAddOn;
			local addOnConfig_waitSecondsForHooking = addOnConfig.waitSecondsForHooking;
			
			wipe(addOnConfig);
			TT_ExtendedConfig.tipsToModify[addOnName] = nil;
			
			-- apply hooks for addon
			-- hint:
			-- function hookFnForAddOn() needs to be called after removing addon config from tips to modify (see above),
			-- because immediately calling tt:AddModifiedTipExtended() within hookFnForAddOn() leads to an infinite loop
			-- because of calling tt:ApplyConfig() within tt:AddModifiedTipExtended() which leads to another call of tt:ResolveTipsToModify() and so on.
			if (addOnConfig_hookFnForAddOn) then
				LibFroznFunctions:CallFunctionDelayed(addOnConfig_waitSecondsForHooking, function()
					addOnConfig_hookFnForAddOn(TT_CacheForFrames);
				end);
			end
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
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				tip:HookScript("OnSizeChanged", function(...)
					-- check if insecure interaction with the tip is currently forbidden
					if (tip:IsForbidden()) then
						return;
					end
					
					tip.OnBackdropSizeChanged(...);
				end);
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
			-- check if insecure interaction with the tip is currently forbidden
			if (tip:IsForbidden()) then
				return;
			end
			
			tip:HookScript("OnShow", function(tip)
				tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unknownOnShow);
			end);
			
			if (tip:GetObjectType() == "GameTooltip") then
				LibFroznFunctions:HookSecureFuncIfExists(tip, "Show", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unknownOnShow);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnit", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.unit);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnitAura", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnitBuff", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.aura);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetUnitDebuff", function(tip)
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
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetAction", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.action);
				end);
				LibFroznFunctions:HookSecureFuncIfExists(tip, "SetHyperlink", function(tip)
					tt:SetCurrentDisplayParams(tip, TT_TIP_CONTENT.others);
				end);
				
				tip:HookScript("OnTooltipCleared", function(tip)
					if (not tip:IsForbidden()) and (tip:IsShown()) and (tip:GetObjectType() == "GameTooltip") and (tip.shouldRefreshData) then
						return;
					end
					
					tt:ResetCurrentDisplayParams(tip);
					
					if (not tip:IsForbidden()) and (tip:IsShown()) then
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
	
	-- ignore next setting tip's current display parameters
	if (currentDisplayParams.ignoreNextSetCurrentDisplayParams) then
		currentDisplayParams.ignoreNextSetCurrentDisplayParams = nil;
		
		return;
	end
	
	-- ignore setting tip's current display parameters on timestamp
	local currentTime = GetTime();
	
	if (currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp == currentTime) then
		return;
	end
	
	currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp = nil;
	
	-- consider missing reset of tip's current display parameters
	-- - e.g. if hovering over unit auras which will be hidden. there will be subsequent calls of GameTooltip:SetUnitAura() without a new GameTooltip:OnShow().
	-- - e.g. if hovering over empty action bar buttons the GameTooltip:SetAction() will be called, but there's no tooltip. therefore no OnTooltipCleared() will
	--	      be fired if leaving the button and the currentDisplayParams are still set. afterwards if moving to a world unit, we need firing the group event.
	if ((currentDisplayParams.isSet) or (currentDisplayParams.isSetTemporarily)) and (currentDisplayParams.isSetTimestamp ~= currentTime) then
		self:ResetCurrentDisplayParams(tip, true); -- necessary to fire no group events here, e.g because "currentDisplayParams.defaultAnchored" will be lost.
	end
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		self:HideTip(tip);
		return;
	end
	
	-- current display parameters aren't set yet
	local tipContentUnknown = LibFroznFunctions:ExistsInTable(tipContent, { TT_TIP_CONTENT.unknownOnShow, TT_TIP_CONTENT.unknownOnCleared });
	
	if (not ((currentDisplayParams.isSet) or (currentDisplayParams.isSetTemporarily) and (tipContentUnknown))) then
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
	end
	
	-- inform group that the tip has to be checked if it needs to be hidden
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetHidden", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		self:HideTip(tip);
		return;
	end
	
	-- inform group that the tip's styling needs to be set
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetStyling", TT_CacheForFrames, tip, currentDisplayParams, tipContent);
	
	-- recalculate size of tip to ensure that it has the correct dimensions
	if (tipContent ~= TT_TIP_CONTENT.unknownOnCleared) then -- prevent recalculating size of tip on tip content "unknownOnCleared" to prevent accidentally reducing tip's width/height to a tiny square e.g. on individual GameTooltips with tip:ClearLines(). test case: addon "Titan Panel" with broker addon "Profession Cooldown".
		LibFroznFunctions:RecalculateSizeOfGameTooltip(tip);
	end
end

-- reset tip's current display parameters
function tt:ResetCurrentDisplayParams(tip, noFireGroupEvent)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- current display parameters are already resetted
	if (not currentDisplayParams.isSet) and (not currentDisplayParams.isSetTemporarily) then
		return;
	end
	
	-- inform group that the tip's current display parameters has to be reset
	if (not noFireGroupEvent) then
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipResetCurrentDisplayParams", TT_CacheForFrames, tip, currentDisplayParams);
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipPostResetCurrentDisplayParams", TT_CacheForFrames, tip, currentDisplayParams);
	end
	
	currentDisplayParams.isSet = false;
	currentDisplayParams.isSetTemporarily = false;
	
	currentDisplayParams.isSetTimestamp = nil;
	
	currentDisplayParams.hideTip = false;
	currentDisplayParams.ignoreNextSetCurrentDisplayParams = nil;
end

-- hide tip
function tt:HideTip(tip)
	if (not tip:IsForbidden()) and (tip:IsShown()) then
		tip:Hide();
		TT_CacheForFrames[tip].currentDisplayParams.ignoreSetCurrentDisplayParamsOnTimestamp = GetTime();
	end
end

-- hide tips if need to be hidden
function tt:HideTipsIfNeedToBeHidden()
	-- hide tip if needs to be hidden
	for tip, frameParams in pairs(TT_CacheForFrames) do
		self:HideTipIfNeedsToBeHidden(tip);
	end
end

-- hide tip if needs to be hidden
function tt:HideTipIfNeedsToBeHidden(tip)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- current display parameters aren't set
	if (not currentDisplayParams.isSet) and (not currentDisplayParams.isSetTemporarily) then
		return;
	end
	
	-- tip already hidden
	if (currentDisplayParams.hideTip) then
		return;
	end
	
	-- inform group that the tip has to be checked if it needs to be hidden
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipSetHidden", TT_CacheForFrames, tip, currentDisplayParams, currentDisplayParams.tipContent);
	
	-- tip will be hidden
	if (currentDisplayParams.hideTip) then
		self:HideTip(tip);
	end
end

-- set scale to tip
--
-- use isSettingScaleToTip to prevent endless loop when calling tt:SetScaleToTip()
local isSettingScaleToTip = false;

function tt:SetScaleToTip(tip, noFireGroupEvent)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- check if we're already setting scale to tip
	if (isSettingScaleToTip) then
		return;
	end
	
	isSettingScaleToTip = false;
	
	-- get current display and tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
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
		local LibQTip = LibStub:GetLibrary("LibQTip-1.0", true);
		
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
	
	-- consider min/max scale from inherited DefaultScaleFrame, see DefaultScaleFrameMixin:UpdateScale() in "SharedUIPanelTemplates.lua"
	if (DefaultScaleFrameMixin) and (DefaultScaleFrameMixin.UpdateScale == tip.UpdateScale) then
		if (tip.minScale) then
			newTipScale = math.max(newTipScale, tip.minScale);
		end

		if (tip.maxScale) then
			newTipScale = math.min(newTipScale, tip.maxScale);
		end
	end
	
	-- don't set scale to tip if change results in less than 0.5 pixels difference
	local tipWidth = tip:GetWidth() * tipEffectiveScale;
	local tipHeight = tip:GetHeight() * tipEffectiveScale;
	
	if (tipWidth > 0) and (math.abs((newTipScale / tipScale - 1) * tipWidth) <= 0.5) and (tipHeight > 0) and (math.abs((newTipScale / tipScale - 1) * tipHeight) <= 0.5) then
		return;
	end
	
	-- set scale to tip
	isSettingScaleToTip = true;
	tip:SetScale(newTipScale);
	isSettingScaleToTip = false;
	
	-- inform group that the tip has been rescaled
	if (not noFireGroupEvent) then
		LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipRescaled", TT_CacheForFrames, tip, currentDisplayParams);
	end
end

-- set gradient to tip
function tt:SetGradientToTip(tip)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- get tip parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local tipParams = frameParams.config;
	
	-- set gradient to tip not possible
	local gradientForFrame = frameParams.gradient;
	
	if (not cfg.enableBackdrop) or (not cfg.gradientTip) or (not tipParams.applyAppearance) then
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
	
	gradientForFrame:SetPoint("TOPLEFT", self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipBackdrop.insets.left, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop), -self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipBackdrop.insets.top, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop));
	gradientForFrame:SetPoint("BOTTOMRIGHT", tip, "TOPRIGHT", -self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipBackdrop.insets.right, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop), -cfg.gradientHeight);
	
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

-- EVENT: player regen enabled (after ending combat)
function tt:PLAYER_REGEN_ENABLED(event)
	-- inform group that the player regen has been enabled (after ending combat)
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnPlayerRegenEnabled", TT_CacheForFrames);
end

-- EVENT: player regen disabled (whenever entering combat)
function tt:PLAYER_REGEN_DISABLED(event)
	-- inform group that the player regen has been disabled (whenever entering combat)
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnPlayerRegenDisabled", TT_CacheForFrames);
end

-- EVENT: bonus bar updated
function tt:UPDATE_BONUS_ACTIONBAR(event)
	-- inform group that the bonus bar has been updated
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnUpdateBonusActionbar", TT_CacheForFrames);
end

-- EVENT: modifier state changed (shift/ctrl/alt keys are pressed or released)
function tt:MODIFIER_STATE_CHANGED(event)
	-- inform group that the modifier state has been changed (shift/ctrl/alt keys are pressed or released)
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnModifierStateChanged", TT_CacheForFrames);
end

-- register events
tt:RegisterEvent("PLAYER_REGEN_ENABLED");
tt:RegisterEvent("PLAYER_REGEN_DISABLED");
tt:RegisterEvent("UPDATE_BONUS_ACTIONBAR");
tt:RegisterEvent("MODIFIER_STATE_CHANGED");

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
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
		
		-- HOOK: tip's SetScale() to reapply scale to tip. test case: install addons "Bulk Mail" and "Bulk Mail Inbox" and open mail inbox. tips are mostly empty. the downside of this reapply scale is, that e.g. the individual scale of LibQTip from addon "Broker_Currencyflow" is overriden.
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			hooksecurefunc(tip, "SetScale", function(tip)
				-- reapply scale to tip
				tt:SetScaleToTip(tip);
			end);
		end);
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- reapply scale to tip
		tt:SetScaleToTip(tip);
	end,
	OnTipRescaled = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reapply gradient to tip
		tt:SetGradientToTip(tip);
	end,
	OnPlayerRegenEnabled = function(self, TT_CacheForFrames)
		-- hide tips if need to be hidden
		tt:HideTipsIfNeedToBeHidden();
	end,
	OnPlayerRegenDisabled = function(self, TT_CacheForFrames)
		-- hide tips if need to be hidden
		tt:HideTipsIfNeedToBeHidden();
	end,
	OnUpdateBonusActionbar = function(self, TT_CacheForFrames)
		-- hide tips if need to be hidden
		tt:HideTipsIfNeedToBeHidden();
	end,
	OnModifierStateChanged = function(self, TT_CacheForFrames)
		-- hide tips if need to be hidden
		tt:HideTipsIfNeedToBeHidden();
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
	
	-- workaround for addon AddOnSkins to prevent styling of frame
	local isAddOnAddOnSkinsLoaded = LibFroznFunctions:IsAddOnFinishedLoading("AddOnSkins");
	
	if (isAddOnAddOnSkinsLoaded) then
		tip.isSkinned = true;
	end
	
	-- extra handling of blizzards UIDropDownMenu and LibDropDownMenu
	local tipName = tip:GetName();
	
	if (tipName) then
		if (tipName:match("^DropDownList(%d+)")) or (tipName:match("^L_DropDownList(%d+)")) or (tipName:match("^LibDropDownMenu_List(%d+)")) then
			local dropDownListBackdrop = _G[tipName.."Backdrop"];
			local dropDownListMenuBackdrop = _G[tipName.."MenuBackdrop"];
			
			LibFroznFunctions:StripTextures(dropDownListBackdrop);
			if (dropDownListBackdrop.Bg) then
				dropDownListBackdrop.Bg:SetTexture(nil);
				dropDownListBackdrop.Bg:SetAtlas(nil);
			end
			
			if (dropDownListMenuBackdrop.NineSlice) then
				LibFroznFunctions:StripTextures(dropDownListMenuBackdrop.NineSlice);
			else
				LibFroznFunctions:StripTextures(dropDownListMenuBackdrop);
			end
			
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- check if we're already setting padding to tip
	if (isSettingPaddingToTip) then
		return;
	end
	
	isSettingPaddingToTip = false;
	
	-- SetPadding() isn't available for e.g. BattlePetTooltip, FloatingBattlePetTooltip, PetJournalPrimaryAbilityTooltip, PetJournalSecondaryAbilityTooltip, PetBattlePrimaryUnitTooltip, PetBattlePrimaryAbilityTooltip, FloatingPetBattleAbilityTooltip, EncounterJournalTooltip and DropDownList
	if (tip:GetObjectType() ~= "GameTooltip") then
		return;
	end
	
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- calculate new padding for tip
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
	
	newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop = newPaddingRight + self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipPaddingForGameTooltip.right, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop), newPaddingBottom + self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipPaddingForGameTooltip.bottom, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop), newPaddingLeft + self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipPaddingForGameTooltip.left, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop), newPaddingTop + self:GetNearestPixelSize(tip, TT_ExtendedConfig.tipPaddingForGameTooltip.top, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	
	newPaddingRight = newPaddingRight + (currentDisplayParams.extraPaddingRightForMinimumWidth or 0) + (currentDisplayParams.extraPaddingRightForCloseButton or 0);
	newPaddingBottom = newPaddingBottom + (currentDisplayParams.extraPaddingBottomForBars or 0);
	
	newPaddingRight, newPaddingBottom, newPaddingLeft, newPaddingTop = self:GetNearestPixelSize(tip, newPaddingRight), self:GetNearestPixelSize(tip, newPaddingBottom), self:GetNearestPixelSize(tip, newPaddingLeft), self:GetNearestPixelSize(tip, newPaddingTop);
	
	-- don't set padding to tip if change results in less than 0.5 pixels difference
	local tipEffectiveScale = tip:GetEffectiveScale();
	
	if (math.abs((newPaddingRight - oldPaddingRight) * tipEffectiveScale) <= 0.5) and (math.abs((newPaddingBottom - oldPaddingBottom) * tipEffectiveScale) <= 0.5) and (math.abs((newPaddingLeft - oldPaddingLeft) * tipEffectiveScale) <= 0.5) and (math.abs((newPaddingTop - oldPaddingTop) * tipEffectiveScale) <= 0.5) then
		isSettingPaddingToTip = false;
		return;
	end
	
	-- set padding to tip
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
--
-- use isHandlingSizeChange to prevent endless loop when handling size change
local isHandlingSizeChange = false;
 
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
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
		
		-- HOOK: tip's OnSizeChanged to monitor size changes
		LibFroznFunctions:CallFunctionDelayed(tipParams.waitSecondsForHooking, function()
			-- check if insecure interaction with the tip is currently forbidden
			if (tip:IsForbidden()) then
				return;
			end
			
			tip:HookScript("OnSizeChanged", function(tip)
				-- check if we're currently handling size change
				if (isHandlingSizeChange) then
					return;
				end
				
				isHandlingSizeChange = false;
				
				-- get current display parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				local currentDisplayParams = frameParams.currentDisplayParams;
				
				-- current display parameters aren't set
				if (not currentDisplayParams.isSet) and (not currentDisplayParams.isSetTemporarily) then
					return;
				end
				
				-- inform group that the tip has been resized
				isHandlingSizeChange = true;
				
				LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnTipResized", TT_CacheForFrames, tip, currentDisplayParams);
				
				-- set padding to tip
				tt:SetPaddingToTip(tip);
				
				-- recalculate size of tip to ensure that it has the correct dimensions
				LibFroznFunctions:RecalculateSizeOfGameTooltip(tip);
				
				isHandlingSizeChange = false;
			end);
		end);
	end,
	OnApplyTipAppearanceAndHooking = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- HOOK: SharedTooltip_SetBackdropStyle() to reapply backdrop and padding if necessary (e.g. needed for OnTooltipSetItem() or AreaPOIPinMixin:OnMouseEnter() on world map (e.g. Torghast) or VignettePin on world map (e.g. weekly event in Maw))
		hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tip, style, embedded)
			-- set backdrop to tip
			tt:SetBackdropToTip(tip);
		end);
		
		-- HOOK: GameTooltip_CalculatePadding() to reapply padding
		hooksecurefunc("GameTooltip_CalculatePadding", function(tip)
			-- set padding to tip
			tt:SetPaddingToTip(tip);
		end);
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- reapply padding to tip
		if (LibFroznFunctions:ExistsInTable(tipContent, { TT_TIP_CONTENT.unit, TT_TIP_CONTENT.unknownOnShow })) then
			-- set padding to tip
			tt:SetPaddingToTip(tip);
		end
	end,
	OnTipRescaled = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reapply backdrop to tip
		tt:SetBackdropToTip(tip);
		
		-- reapply padding to tip
		tt:SetPaddingToTip(tip);
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
		currentDisplayParams.extraPaddingRightForMinimumWidth = nil;
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
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdrop) then
			hooksecurefunc(tip.NineSlice, "SetBackdrop", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.ClearBackdrop) then
			hooksecurefunc(tip.NineSlice, "ClearBackdrop", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForApplySetClearBackdrop(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdropColor) then
			hooksecurefunc(tip.NineSlice, "SetBackdropColor", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForSetBackdropColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBackdropBorderColor) then
			hooksecurefunc(tip.NineSlice, "SetBackdropBorderColor", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForSetBackdropBorderColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetCenterColor) then
			hooksecurefunc(tip.NineSlice, "SetCenterColor", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
				colorLockingFnForSetCenterColor(tip:GetParent(), tip);
			end);
		end
		if (tip.NineSlice.SetBorderColor) then
			hooksecurefunc(tip.NineSlice, "SetBorderColor", function(tip)
				-- check if insecure interaction with the tip is currently forbidden
				if (tip:IsForbidden()) then
					return;
				end
				
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- check if we're already setting backdrop color locked
	if (isSettingBackdropLocked) then
		return;
	end
	
	isSettingBackdropLocked = false;
	
	-- set locked backdrop info
	local frameParams = TT_CacheForFrames[tip];
	
	if (frameParams) then
		frameParams.currentDisplayParams.lockedBackdropInfo = backdropInfo;
	end
	
	-- create new backdrop info with nearest pixel size for insets and edgeSize
	local newBackDropInfo = CopyTable(backdropInfo);
	
	newBackDropInfo.edgeSize = self:GetNearestPixelSize(tip, newBackDropInfo.edgeSize, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	
	newBackDropInfo.insets.left = self:GetNearestPixelSize(tip, newBackDropInfo.insets.left, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	newBackDropInfo.insets.right = self:GetNearestPixelSize(tip, newBackDropInfo.insets.right, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	newBackDropInfo.insets.top = self:GetNearestPixelSize(tip, newBackDropInfo.insets.top, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	newBackDropInfo.insets.bottom = self:GetNearestPixelSize(tip, newBackDropInfo.insets.bottom, cfg.pixelPerfectBackdrop, cfg.pixelPerfectBackdrop);
	
	-- set backdrop locked
	isSettingBackdropLocked = true;
	tip:SetBackdrop(newBackDropInfo);
	isSettingBackdropLocked = false;
end

-- set backdrop color locked
--
-- use isSettingBackdropColorLocked to prevent endless loop when calling tt:SetBackdropColorLocked()
local isSettingBackdropColorLocked = false;

function tt:SetBackdropColorLocked(tip, r, g, b, a)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
		-- set backdrop border color locked
		tt:SetBackdropBorderColorLocked(tip, r, g, b, a);
	end
}, MOD_NAME .. " - Color Locking Feature");

----------------------------------------------------------------------------------------------------
--                       Prevent additional elements from moving off-screen                       --
----------------------------------------------------------------------------------------------------

-- set clamp rect insets to tip for preventing additional elements from moving off-screen
function tt:SetClampRectInsetsToTip(tip, left, right, top, bottom)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- don't set clamp rect insets to tip if original offsets for preventing additional elements from moving off-screen aren't available
	if (not frameParams.originalOffsetsForPreventingOffScreenAvailable) then
		return;
	end
	
	-- set current display params for preventing additional elements from moving off-screen
	currentDisplayParams.modifiedOffsetsForPreventingOffScreen = true;
	
	-- set clamp rect insets to tip for preventing additional elements from moving off-screen
	tip:SetClampRectInsets(left, right, top, bottom);
end

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- check if insecure interaction with the tip is currently forbidden
		if (tip:IsForbidden()) then
			return;
		end
		
		-- get frame parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		-- set original left/right/top/bottom offset for preventing additional elements from moving off-screen
		local leftOffset, rightOffset, topOffset, bottomOffset = tip:GetClampRectInsets();
		
		if (leftOffset) and (rightOffset) and (topOffset) and (bottomOffset) then
			frameParams.originalOffsetsForPreventingOffScreenAvailable = true;
			frameParams.originalLeftOffsetForPreventingOffScreen, frameParams.originalRightOffsetForPreventingOffScreen, frameParams.originalTopOffsetForPreventingOffScreen, frameParams.originalBottomOffsetForPreventingOffScreen = leftOffset, rightOffset, topOffset, bottomOffset;
		end
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- get current display parameters
		local frameParams = TT_CacheForFrames[tip];
		
		if (not frameParams) then
			return;
		end
		
		local currentDisplayParams = frameParams.currentDisplayParams;
		
		-- restore original offsets for preventing additional elements from moving off-screen
		if (not tip:IsForbidden()) and (not frameParams.originalOffsetsForPreventingOffScreenAvailable) and (currentDisplayParams.modifiedOffsetsForPreventingOffScreen) then
			tip:SetClampRectInsets(frameParams.originalLeftOffsetForPreventingOffScreen, frameParams.originalRightOffsetForPreventingOffScreen, frameParams.originalTopOffsetForPreventingOffScreen, frameParams.originalBottomOffsetForPreventingOffScreen);
		end
		
		-- reset current display params for preventing additional elements from moving off-screen
		currentDisplayParams.modifiedOffsetsForPreventingOffScreen = nil;
	end,
	SetClampRectInsetsToTip = function(self, tip, left, right, top, bottom)
		-- set clamp rect insets to tip for preventing additional elements from moving off-screen
		tt:SetClampRectInsetsToTip(tip, left, right, top, bottom);
	end
}, MOD_NAME .. " - Preventing Off-Screen");

----------------------------------------------------------------------------------------------------
--                                           Anchoring                                            --
----------------------------------------------------------------------------------------------------

-- set anchor to tip
function tt:SetAnchorToTip(tip)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
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
		
		return;
	elseif (anchorType == "parent") then
		tip:ClearAllPoints();
		
		local parentFrame = currentDisplayParams.defaultAnchoredParentFrame;
		
		if (parentFrame) and (parentFrame ~= UIParent) then
			-- anchor to the opposite edge of the parent frame
			local offsetX, offsetY = LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, parentFrame, tip, UIParent);
			
			tip:SetPoint(LibFroznFunctions:MirrorAnchorPointCentered(anchorPoint), UIParent, anchorPoint, offsetX, offsetY);
		else
			-- fallback to "normal" anchor in case parent frame isn't available or is UIParent
			local offsetX, offsetY = LibFroznFunctions:GetOffsetsForAnchorPoint(anchorPoint, tt, tip, UIParent);
			
			tip:SetPoint(anchorPoint, UIParent, offsetX, offsetY);
		end
	end
	
	-- refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
	LibFroznFunctions:RefreshAnchorShoppingTooltips(tip);
end

-- anchor tip to mouse position
function tt:AnchorTipToMouse(tip)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- set anchor to tip not possible
	local tipParams = frameParams.config;
	
	if (not cfg.enableAnchor) or (not tipParams.applyAnchor) then
		return;
	end
	
	-- tip not default anchored
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
		local x, y = LibFroznFunctions:GetCursorPosition();
		
		tip:ClearAllPoints();
		tip:SetPoint(anchorPoint, UIParent, "BOTTOMLEFT", self:GetNearestPixelSize(tip, x + cfg.mouseOffsetX, false, true), self:GetNearestPixelSize(tip, y + cfg.mouseOffsetY, false, true));
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
	
	local mouseFocus = LibFroznFunctions:GetMouseFocus();
	
	if (isUnit == nil) then
		isUnit = (UnitExists("mouseover")) and (not UnitIsUnit("mouseover", "player")) or (mouseFocus and mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit")); -- GetAttribute("unit") here is bad, as that will find things like buff frames too.
	end
	
	local anchorFrameName = (mouseFocus == WorldFrame and "World" or "Frame") .. (isUnit and "Unit" or "Tip");
	local var = "anchor" .. anchorFrameName;
	
	-- consider anchor override during challenge mode, during skyriding or in combat
	local anchorOverride = "";
	
	if (cfg["enableAnchorOverride" .. anchorFrameName .. "DuringChallengeMode"]) and (LibFroznFunctions.hasWoWFlavor.challengeMode) and (C_ChallengeMode.IsChallengeModeActive()) then
		local difficultyID = select(3, GetInstanceInfo());
		
		if (difficultyID) then
			local isChallengeMode = select(4, GetDifficultyInfo(difficultyID));
			
			if (isChallengeMode) then
				local timerID = GetWorldElapsedTimers();
				local _, elapsedTime, timerType = GetWorldElapsedTime(timerID);
				
				if (timerType == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE) and (elapsedTime >= 0) then
					anchorOverride = "DuringChallengeMode";
				end
			end
		end
	end
	
	if (anchorOverride == "") and (cfg["enableAnchorOverride" .. anchorFrameName .. "DuringSkyriding"]) and (LibFroznFunctions.hasWoWFlavor.skyriding) then
		local bonusBarIndex = GetBonusBarIndex(); -- skyriding bonus bar is 11
		
		if (bonusBarIndex == 11) then
			anchorOverride = "DuringSkyriding";
		end
	end
	
	if (anchorOverride == "") and (cfg["enableAnchorOverride" .. anchorFrameName .. "InCombat"]) and (UnitAffectingCombat("player")) then
		anchorOverride = "InCombat";
	end
	
	-- get anchor position
	local anchorType, anchorPoint = cfg[var .. "Type" .. anchorOverride], cfg[var .. "Point" .. anchorOverride];
	
	-- check for other GameTooltip anchor overrides
	if (tip == GameTooltip) then
		-- override GameTooltip anchor for (Guild & Community) ChatFrame
		if (not tip:IsForbidden()) then
			local tipOwner = tip:GetOwner();
			
			if (cfg.enableAnchorOverrideCF) and (anchorFrameName == "FrameTip") and (LibFroznFunctions:IsFrameBackInFrameChain(tipOwner, {
						"^ChatFrame(%d+)",
						(LibFroznFunctions:IsAddOnFinishedLoading("Blizzard_Communities") and CommunitiesFrame.Chat.MessageFrame)
					}, 1)) then
				
				return anchorFrameName, cfg.anchorOverrideCFType, cfg.anchorOverrideCFPoint;
			end
		end
	end
	
	return anchorFrameName, anchorType, anchorPoint;
end

-- HOOK: tip's OnUpdate for anchoring to mouse
function tt:AnchorTipToMouseOnUpdate(tip)
	-- check if insecure interaction with the tip is currently forbidden
	if (tip:IsForbidden()) then
		return;
	end
	
	tip:HookScript("OnUpdate", function(tip)
		-- anchor tip to mouse position
		tt:AnchorTipToMouse(tip);
	end);
end

-- HOOK: GameTooltip_SetDefaultAnchor() after set default anchor to tip
function tt:SetDefaultAnchorHook(tip, parent)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- set current display params for anchoring
	currentDisplayParams.defaultAnchored = true;
	currentDisplayParams.defaultAnchoredParentFrame = parent;
	
	-- set anchor to tip
	self:SetAnchorToTip(tip);
end

-- set anchor to tips if need to be set
function tt:SetAnchorToTipsIfNeedToBeSet()
	-- set anchor to tip if needs to be set
	for tip, frameParams in pairs(TT_CacheForFrames) do
		self:SetAnchorToTipIfNeedsToBeSet(tip);
	end
end

-- set anchor to tip if needs to be set
function tt:SetAnchorToTipIfNeedsToBeSet(tip)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- current display parameters aren't set
	if (not currentDisplayParams.isSet) and (not currentDisplayParams.isSetTemporarily) then
		return;
	end
	
	-- set anchor to tip not possible
	local tipParams = frameParams.config;
	
	if (not cfg.enableAnchor) or (not tipParams.applyAnchor) then
		return;
	end
	
	-- tip not default anchored
	if (not currentDisplayParams.defaultAnchored) then
		return;
	end
	
	-- get anchor position
	currentDisplayParams.anchorFrameName, currentDisplayParams.anchorType, currentDisplayParams.anchorPoint = self:GetAnchorPosition(tip);
	
	-- set anchor to tip
	self:SetAnchorToTip(tip);
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
	if (tip:IsForbidden()) or (not tip:IsShown()) then
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
			-- check if insecure interaction with the tip is currently forbidden
			if (tip:IsForbidden()) then
				return;
			end
			
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
		
		-- refreshing anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips,
		-- because after GameTooltip_ShowCompareItem() (hook see below) has been called within TooltipDataRules.FinalizeItemTooltip(), the tooltip isn't finished yet, e.g. if hovering over monthly activities reward button.
		-- so the tooltip may change in size after finishing the remaining TooltipDataHandler calls/callbacks to finalize the tooltip.
		LibFroznFunctions:RefreshAnchorShoppingTooltips(tip);
	end,
	OnTipRescaled = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reapply anchor tip to mouse position
		tt:AnchorTipToMouse(tip);
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
	OnPlayerRegenEnabled = function(self, TT_CacheForFrames)
		-- set anchor to tips if need to be set
		tt:SetAnchorToTipsIfNeedToBeSet();
	end,
	OnPlayerRegenDisabled = function(self, TT_CacheForFrames)
		-- set anchor to tips if need to be set
		tt:SetAnchorToTipsIfNeedToBeSet();
	end,
	OnUpdateBonusActionbar = function(self, TT_CacheForFrames)
		-- set anchor to tips if need to be set
		tt:SetAnchorToTipsIfNeedToBeSet();
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
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- set unit record from tip
	local _, unitID = LibFroznFunctions:GetUnitFromTooltip(tip);
	
	-- concated unit tokens such as "targettarget" cannot be returned as the unit id by GameTooltip:GetUnit() aka TooltipUtil.GetDisplayedUnit(GameTooltip),
	-- and it will return as "mouseover", but the "mouseover" unit id is still invalid at this point for those unitframes!
	-- to overcome this problem, we look if the mouse is over a unitframe, and if that unitframe has a unit attribute set?
	if (not unitID) then
		local mouseFocus = LibFroznFunctions:GetMouseFocus();
		
		unitID = mouseFocus and mouseFocus.GetAttribute and mouseFocus:GetAttribute("unit");
	end
	
	-- a mage's mirror images sometimes doesn't return a unit id, this would fix it.
	if (not unitID) and (UnitExists("mouseover")) and (not UnitIsUnit("mouseover", "player")) then
		unitID = "mouseover";
	end
	
	-- sometimes when you move your mouse quickly over units in the worldframe, we can get here without a unit id.
	if (not unitID) then
		currentDisplayParams.unitRecord = nil;
		return;
	end
	
	-- a "mouseover" unitID is better to have as we can then safely say the tip should no longer show when it becomes invalid. Harder to say with a "party2" unit.
	-- this also helps fix the problem that "mouseover" units aren't valid for group members out of range, a bug that has been in WoW since about 3.0.2.
	if (UnitIsUnit(unitID, "mouseover")) then
		unitID = "mouseover";
	end
	
	-- set unit record
	local unitRecord = LibFroznFunctions:CreateUnitRecord(unitID);
	
	if (unitRecord.isPlayer) then
		local _msp = (msp or msptrp);
		
		if (_msp) then
			local field = "NA"; -- Name
			
			_msp:Request(unitRecord.name, field);
			
			if (_msp.char[unitRecord.name] ~= nil) and (_msp.char[unitRecord.name].field[field] ~= "") then
				unitRecord.rpName = _msp.char[unitRecord.name].field[field];
			end
		end
	end
	
	unitRecord.originalName = GameTooltipTextLeft1:GetText();
	unitRecord.isColorBlind = (GetCVar("colorblindMode") == "1");
	
	-- check if it's a unit of a TipTac developer
	unitRecord.isTipTacDeveloper = false;
	
	for _, tipTacDeveloper in ipairs(TT_TipTacDeveloper) do
		if (tipTacDeveloper.regionID == TT_CurrentRegionID) and (tipTacDeveloper.guid == unitRecord.guid) then
			unitRecord.isTipTacDeveloper = true;
			break;
		end
	end
	
	currentDisplayParams.unitRecord = unitRecord;
end

-- set unit appearance to tip
function tt:SetUnitAppearanceToTip(tip, first)
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
	
	-- no valid unit any more e.g. during fading out
	if (not UnitGUID(unitRecord.id)) then
		return;
	end
	
	-- inform group that the unit tip is about to be styled
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnUnitTipPreStyle", TT_CacheForFrames, tip, currentDisplayParams, first);
	
	-- set backdrop color to tip by unit reaction index
	if (cfg.reactColoredBackdrop) then
		self:SetBackdropColorLocked(tip, unpack(cfg["colorReactBack" .. unitRecord.reactionIndex]));
	end

	-- set backdrop border color to tip by unit class or by unit reaction index
	if (cfg.classColoredBorder) and (unitRecord.isPlayer) then
		local classColor = LibFroznFunctions:GetClassColor(unitRecord.classID, 5, cfg.enableCustomClassColors and TT_ExtendedConfig.customClassColors or nil);
		
		self:SetBackdropBorderColorLocked(tip, classColor:GetRGBA());
	elseif (cfg.reactColoredBorder) then
		self:SetBackdropBorderColorLocked(tip, unpack(cfg["colorReactText" .. unitRecord.reactionIndex]));
	end
	
	-- inform group that the unit tip has to be styled
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnUnitTipStyle", TT_CacheForFrames, tip, currentDisplayParams, first);
	
	-- recalculate size of tip to ensure that it has the correct dimensions
	LibFroznFunctions:RecalculateSizeOfGameTooltip(tip);
	
	-- inform group that the unit tip has to be resized
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnUnitTipResize", TT_CacheForFrames, tip, currentDisplayParams, first);
	
	-- inform group that the unit tip has been styled and has the final size
	LibFroznFunctions:FireGroupEvent(MOD_NAME, "OnUnitTipPostStyle", TT_CacheForFrames, tip, currentDisplayParams, first);
	
	-- set padding to tip. padding might have been modified to fit health/power bars.
	self:SetPaddingToTip(tip);
end

-- update unit appearance to tip
function tt:UpdateUnitAppearanceToTip(tip, force)
	-- get current display parameters
	local frameParams = TT_CacheForFrames[tip];
	
	if (not frameParams) then
		return;
	end
	
	local currentDisplayParams = frameParams.currentDisplayParams;
	
	-- no unit appearance
	local timestampStartUnitAppearance = currentDisplayParams.timestampStartUnitAppearance;
	
	if (not timestampStartUnitAppearance) then
		return;
	end
	
	-- no unit record
	local unitRecord = currentDisplayParams.unitRecord;
	
	if (not unitRecord) then
		return;
	end
	
	-- consider update interval
	if (not force) and (GetTime() - timestampStartUnitAppearance < TOOLTIP_UPDATE_TIME) then
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
		-- check if insecure interaction with the tip is currently forbidden
		if (tip:IsForbidden()) then
			return;
		end
		
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
		
		currentDisplayParams.firstCallDoneUnitAppearance = false;
		currentDisplayParams.timestampStartUnitAppearance = nil;
	end,
	OnTipSetStyling = function(self, TT_CacheForFrames, tip, currentDisplayParams, tipContent)
		-- set unit appearance to tip
		tt:SetUnitAppearanceToTip(tip, not currentDisplayParams.firstCallDoneUnitAppearance);
		currentDisplayParams.firstCallDoneUnitAppearance = true;
		currentDisplayParams.timestampStartUnitAppearance = GetTime();
	end,
	OnTipResetCurrentDisplayParams = function(self, TT_CacheForFrames, tip, currentDisplayParams)
		-- reset current display params for unit appearance
		currentDisplayParams.unitRecord = nil;
		currentDisplayParams.firstCallDoneUnitAppearance = false;
		currentDisplayParams.timestampStartUnitAppearance = nil;
	end
}, MOD_NAME .. " - Unit Appearance");

----------------------------------------------------------------------------------------------------
--                                      Custom Unit Fadeout                                       --
----------------------------------------------------------------------------------------------------

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnTipAddedToCache = function(self, TT_CacheForFrames, tip)
		-- check if insecure interaction with the tip is currently forbidden
		if (tip:IsForbidden()) then
			return;
		end
		
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
				
				-- instant unit fadeout
				if (cfg.preFadeTime == 0) and (cfg.fadeTime == 0) then
					tip:Hide();
					return;
				end
				
				-- enable custom unit fadeout
				currentDisplayParams.ignoreNextSetCurrentDisplayParams = true;
				tip:Show(); -- cancels default unit fadeout
				currentDisplayParams.timestampStartCustomUnitFadeout = GetTime();
			end);
			
			tip:HookScript("OnUpdate", function(tip)
				-- get current display parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				local currentDisplayParams = frameParams.currentDisplayParams;
				
				-- no custom unit fadeout
				local timestampStartCustomUnitFadeout = currentDisplayParams.timestampStartCustomUnitFadeout;
				
				if (not timestampStartCustomUnitFadeout) then
					-- no override of default unit fadeout
					if (not cfg.overrideFade) then
						return;
					end
					
					-- consider if FadeOut() for worldframe unit tips will not be called
					local unitRecord = currentDisplayParams.unitRecord;
					
					if (LibFroznFunctions.hasWoWFlavor.GameTooltipFadeOutNotBeCalledForWorldFrameUnitTips) and
							(unitRecord) and (not UnitExists(unitRecord.id)) then
						
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
	-- hide world tips instantly
	self:HideWorldTipsInstantly();
end

-- register for group events
local eventsForHideWorldTipsHooked = false;

LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnApplyConfig = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- register/unregister cursor changed event
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
		-- check if insecure interaction with the tip is currently forbidden
		if (tip:IsForbidden()) then
			return;
		end
		
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
				-- get current display parameters
				local frameParams = TT_CacheForFrames[tip];
				
				if (not frameParams) then
					return;
				end
				
				local currentDisplayParams = frameParams.currentDisplayParams;
				
				-- unit record exists
				local unitRecord = currentDisplayParams.unitRecord;
				
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
		-- determine if tip comes from experience bar
		local isTipFromExpBar = false;
		
		if (tip == GameTooltip) then
			if (LibFroznFunctions.hasWoWFlavor.experienceBarDockedToInterfaceBar) then
				if (not tip:IsForbidden()) then
					local tipOwner = tip:GetOwner();
					
					if (tipOwner == LibFroznFunctions.hasWoWFlavor.experienceBarFrame) then
						isTipFromExpBar = true;
					end
				end
			else
				local mouseFocus = LibFroznFunctions:GetMouseFocus();
				
				if (mouseFocus) and (not mouseFocus:IsForbidden()) and (LibFroznFunctions:IsFrameBackInFrameChain(mouseFocus, { LibFroznFunctions.hasWoWFlavor.experienceBarFrame }, 2)) then
					isTipFromExpBar = true;
				end
			end
		end
		
		-- unhandled tip content
		if (not LibFroznFunctions:ExistsInTable(tipContent, { TT_TIP_CONTENT.unit, TT_TIP_CONTENT.aura, TT_TIP_CONTENT.spell, TT_TIP_CONTENT.item, TT_TIP_CONTENT.action })) and (not isTipFromExpBar) then
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
		
		-- consider hiding tips during challenge mode, during skyriding or in combat
		local hidingTip = "";
		
		if (LibFroznFunctions.hasWoWFlavor.challengeMode) and (C_ChallengeMode.IsChallengeModeActive()) then
			local difficultyID = select(3, GetInstanceInfo());
			
			if (difficultyID) then
				local isChallengeMode = select(4, GetDifficultyInfo(difficultyID));
				
				if (isChallengeMode) then
					local timerID = GetWorldElapsedTimers();
					local _, elapsedTime, timerType = GetWorldElapsedTime(timerID);
					
					if (timerType == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE) and (elapsedTime >= 0) then
						hidingTip = "DuringChallengeMode";
					end
				end
			end
		end
		
		if (hidingTip == "") and (LibFroznFunctions.hasWoWFlavor.skyriding) then
			local bonusBarIndex = GetBonusBarIndex(); -- skyriding bonus bar is 11
			
			if (bonusBarIndex == 11) then
				hidingTip = "DuringSkyriding";
			end
		end
		
		if (hidingTip == "") and (UnitAffectingCombat("player")) then
			hidingTip = "InCombat";
		end
		
		-- check if tooltip needs to be hidden
		if (currentDisplayParams.anchorFrameName) then
			if (cfg["hideTips" .. hidingTip .. currentDisplayParams.anchorFrameName .. "s"]) then
				currentDisplayParams.hideTip = true;
				return;
			end
		end
		
		local tipContentName = ((tipContent == TT_TIP_CONTENT.unit) and "Unit") or (((tipContent == TT_TIP_CONTENT.aura) or (tipContent == TT_TIP_CONTENT.spell)) and "Spell") or ((tipContent == TT_TIP_CONTENT.item) and "Item") or ((tipContent == TT_TIP_CONTENT.action) and "Action") or (isTipFromExpBar and "ExpBar");
		
		if (cfg["hideTips" .. hidingTip .. tipContentName .. "Tips"]) then
			currentDisplayParams.hideTip = true;
			return;
		end
	end
}, MOD_NAME .. " - Hide Tips");

----------------------------------------------------------------------------------------------------
--                                    Upgrading TipTac_Config                                     --
----------------------------------------------------------------------------------------------------

-- register for group events
LibFroznFunctions:RegisterForGroupEvents(MOD_NAME, {
	OnConfigPreLoaded = function(self, TT_CacheForFrames, cfg, TT_ExtendedConfig)
		-- consider upgrading TipTac_Config on version change (necessary if e.g. options are renamed or reused differently)
		local versionTipTacWithConfigChanges;
		
		-- changes in config with 24.08.05:
		--
		-- - renamed options with "Dragonriding" to "Skyriding":
		--   enableAnchorOverrideWorldUnitDuringDragonriding -> enableAnchorOverrideWorldUnitDuringSkyriding
		--   anchorWorldUnitTypeDuringDragonriding           -> anchorWorldUnitTypeDuringSkyriding
		--   anchorWorldUnitPointDuringDragonriding          -> anchorWorldUnitPointDuringSkyriding
		--   enableAnchorOverrideWorldTipDuringDragonriding  -> enableAnchorOverrideWorldTipDuringSkyriding
		--   anchorWorldTipTypeDuringDragonriding            -> anchorWorldTipTypeDuringSkyriding
		--   anchorWorldTipPointDuringDragonriding           -> anchorWorldTipPointDuringSkyriding
		--   enableAnchorOverrideFrameUnitDuringDragonriding -> enableAnchorOverrideFrameUnitDuringSkyriding
		--   anchorFrameUnitTypeDuringDragonriding           -> anchorFrameUnitTypeDuringSkyriding
		--   anchorFrameUnitPointDuringDragonriding          -> anchorFrameUnitPointDuringSkyriding
		--   enableAnchorOverrideFrameTipDuringDragonriding  -> enableAnchorOverrideFrameTipDuringSkyriding
		--   anchorFrameTipTypeDuringDragonriding            -> anchorFrameTipTypeDuringSkyriding
		--   anchorFrameTipPointDuringDragonriding           -> anchorFrameTipPointDuringSkyriding
		--
		--   hideTipsDuringDragonridingWorldUnits -> hideTipsDuringSkyridingWorldUnits
		--   hideTipsDuringDragonridingFrameUnits -> hideTipsDuringSkyridingFrameUnits
		--   hideTipsDuringDragonridingWorldTips  -> hideTipsDuringSkyridingWorldTips
		--   hideTipsDuringDragonridingFrameTips  -> hideTipsDuringSkyridingFrameTips
		--   hideTipsDuringDragonridingUnitTips   -> hideTipsDuringSkyridingUnitTips
		--   hideTipsDuringDragonridingSpellTips  -> hideTipsDuringSkyridingSpellTips
		--   hideTipsDuringDragonridingItemTips   -> hideTipsDuringSkyridingItemTips
		--   hideTipsDuringDragonridingActionTips -> hideTipsDuringSkyridingActionTips
		versionTipTacWithConfigChanges = "24.08.05";
		
		if (not cfg.version_TipTac_Config) or (cfg.version_TipTac_Config < versionTipTacWithConfigChanges) then
			-- changes in config with 24.08.05
			cfg.enableAnchorOverrideWorldUnitDuringSkyriding = cfg.enableAnchorOverrideWorldUnitDuringDragonriding;
			cfg.enableAnchorOverrideWorldUnitDuringDragonriding = nil;
			cfg.anchorWorldUnitTypeDuringSkyriding = cfg.anchorWorldUnitTypeDuringDragonriding;
			cfg.anchorWorldUnitTypeDuringDragonriding = nil;
			cfg.anchorWorldUnitPointDuringSkyriding = cfg.anchorWorldUnitPointDuringDragonriding;
			cfg.anchorWorldUnitPointDuringDragonriding = nil;
			cfg.enableAnchorOverrideWorldTipDuringSkyriding = cfg.enableAnchorOverrideWorldTipDuringDragonriding;
			cfg.enableAnchorOverrideWorldTipDuringDragonriding = nil;
			cfg.anchorWorldTipTypeDuringSkyriding = cfg.anchorWorldTipTypeDuringDragonriding;
			cfg.anchorWorldTipTypeDuringDragonriding = nil;
			cfg.anchorWorldTipPointDuringSkyriding = cfg.anchorWorldTipPointDuringDragonriding;
			cfg.anchorWorldTipPointDuringDragonriding = nil;
			cfg.enableAnchorOverrideFrameUnitDuringSkyriding = cfg.enableAnchorOverrideFrameUnitDuringDragonriding;
			cfg.enableAnchorOverrideFrameUnitDuringDragonriding = nil;
			cfg.anchorFrameUnitTypeDuringSkyriding = cfg.anchorFrameUnitTypeDuringDragonriding;
			cfg.anchorFrameUnitTypeDuringDragonriding = nil;
			cfg.anchorFrameUnitPointDuringSkyriding = cfg.anchorFrameUnitPointDuringDragonriding;
			cfg.anchorFrameUnitPointDuringDragonriding = nil;
			cfg.enableAnchorOverrideFrameTipDuringSkyriding = cfg.enableAnchorOverrideFrameTipDuringDragonriding;
			cfg.enableAnchorOverrideFrameTipDuringDragonriding = nil;
			cfg.anchorFrameTipTypeDuringSkyriding = cfg.anchorFrameTipTypeDuringDragonriding;
			cfg.anchorFrameTipTypeDuringDragonriding = nil;
			cfg.anchorFrameTipPointDuringSkyriding = cfg.anchorFrameTipPointDuringDragonriding;
			cfg.anchorFrameTipPointDuringDragonriding = nil;
			
			cfg.hideTipsDuringSkyridingWorldUnits = cfg.hideTipsDuringDragonridingWorldUnits;
			cfg.hideTipsDuringDragonridingWorldUnits = nil;
			cfg.hideTipsDuringSkyridingFrameUnits = cfg.hideTipsDuringDragonridingFrameUnits;
			cfg.hideTipsDuringDragonridingFrameUnits = nil;
			cfg.hideTipsDuringSkyridingWorldTips = cfg.hideTipsDuringDragonridingWorldTips;
			cfg.hideTipsDuringDragonridingWorldTips = nil;
			cfg.hideTipsDuringSkyridingFrameTips = cfg.hideTipsDuringDragonridingFrameTips;
			cfg.hideTipsDuringDragonridingFrameTips = nil;
			cfg.hideTipsDuringSkyridingUnitTips = cfg.hideTipsDuringDragonridingUnitTips;
			cfg.hideTipsDuringDragonridingUnitTips = nil;
			cfg.hideTipsDuringSkyridingSpellTips = cfg.hideTipsDuringDragonridingSpellTips;
			cfg.hideTipsDuringDragonridingSpellTips = nil;
			cfg.hideTipsDuringSkyridingItemTips = cfg.hideTipsDuringDragonridingItemTips;
			cfg.hideTipsDuringDragonridingItemTips = nil;
			cfg.hideTipsDuringSkyridingActionTips = cfg.hideTipsDuringDragonridingActionTips;
			cfg.hideTipsDuringDragonridingActionTips = nil;
			
			-- set version of TipTac_Config to version with config changes
			cfg.version_TipTac_Config = versionTipTacWithConfigChanges;
		end
		
		-- set version of TipTac_Config to current version
		local versionTipTac = C_AddOns.GetAddOnMetadata(MOD_NAME, "Version");
		
		cfg.version_TipTac_Config = versionTipTac;
	end
}, MOD_NAME .. " - Options Module TEMP");
