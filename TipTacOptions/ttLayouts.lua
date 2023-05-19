local cfg = TipTac_Config;
local MOD_NAME = ...;
local PARENT_MOD_NAME = "TipTac";

TipTacLayouts = {};

--------------------------------------------------------------------------------------------------------
--                                           Layout Presets                                           --
--------------------------------------------------------------------------------------------------------

local layout_presets = {
	-- TipTac Layout (New)
	["TipTac New Style"] = {
		showTarget = "last",
		targetYouText = "<<YOU>>",

		tipBackdropBG = "Interface\\Buttons\\WHITE8X8",
		tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
		backdropEdgeSize = 14,
		backdropInsets = 2.5,
		tipColor = { 0.1, 0.1, 0.2, 1.0 },
		tipBorderColor = { 0.3, 0.3, 0.4, 1.0 },
		gradientTip = true,
		gradientColor = { 0.8, 0.8, 0.8, 0.15 },

		reactColoredBackdrop = false,

		colorSameGuild = { 1, 0.2, 1, 1 },
		colorRace = { 1, 1, 1, 1},
		colorLevel = { 0.75, 0.75, 0.75, 1},

		colorNameByClass = false,
		classColoredBorder = false,

		barFontFace = "Fonts\\ARIALN.TTF",
		barFontSize = 10,
		barFontFlags = "OUTLINE",
		barHeight = 6,

		classification_minus = "-%s",
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

		hideDefaultBar = true,
		healthBar = true,
		healthBarClassColor = true,
		healthBarText = "value",
		healthBarColor = { 0.3, 0.9, 0.3, 1 },
		manaBar = false,
		powerBar = false,
	},
	-- TipTac Layout (Old)
	["TipTac Old Style"] = {
		showTarget = "belowNameRealm",
		targetYouText = "<<YOU>>",

		reactColoredBackdrop = false,

		tipBackdropBG = "Interface\\Tooltips\\UI-Tooltip-Background",
		tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
		backdropEdgeSize = 16,
		backdropInsets = 4,
		tipColor = { 0.1, 0.1, 0.2, 1.0 },
		tipBorderColor = { 0.3, 0.3, 0.4, 1.0 },
		gradientTip = false,

		colorSameGuild = { 1, 0.2, 1, 1 },
		colorRace = { 1, 1, 1, 1},
		colorLevel = { 0.75, 0.75, 0.75, 1},

		colorNameByClass = false,
		classColoredBorder = false,

		barFontFace = "Fonts\\FRIZQT__.TTF",
		barFontSize = 12,
		barFontFlags = "OUTLINE",
		barHeight = 6,

		classification_minus = "-%s",
		classification_trivial = "~%s",
		classification_normal = "%s",
		classification_elite = "+%s",
		classification_worldboss = "%s|r (Boss)",
		classification_rare = "%s|r (Rare)",
		classification_rareelite = "+%s|r (Rare)",

		hideDefaultBar = true,
		healthBar = true,
		healthBarClassColor = true,
		healthBarText = "value",
		healthBarColor = { 0.3, 0.9, 0.3, 1 },
		manaBar = false,
		powerBar = false,
	},
	-- TipBuddy Layout
	["TipBuddy"] = {
		showTarget = "afterName",
		targetYouText = "[YOU]",

		tipBackdropBG = "Interface\\Tooltips\\UI-Tooltip-Background",
		tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
		backdropEdgeSize = 16,
		backdropInsets = 4,
		tipColor = { 0.1, 0.1, 0.1, 0.8 },
		tipBorderColor = { 0.8, 0.8, 0.9, 1.0 },

		reactColoredBackdrop = false,

		colorSameGuild = { 1, 0.2, 1, 1 },
		colorRace = { 1, 1, 1, 1},
		colorLevel = { 0.75, 0.75, 0.75, 1},

		colorNameByClass = false,
		classColoredBorder = false,

		barFontFace = "Fonts\\ARIALN.TTF",
		barFontSize = 12,
		barFontFlags = "OUTLINE",
		barHeight = 6,

		classification_minus = "-%s",
		classification_trivial = "~%s",
		classification_normal = "%s",
		classification_elite = "+%s",
		classification_worldboss = "%s|r (Boss)",
		classification_rare = "%s|r (Rare)",
		classification_rareelite = "+%s|r (Rare)",

		hideDefaultBar = false,
		healthBar = false,
		manaBar = false,
		powerBar = false,
	},
	-- TinyTip Layout
	["TinyTip"] = {
		showTarget = "last",
		targetYouText = "<<YOU>>",

		tipBackdropBG = "Interface\\Tooltips\\UI-Tooltip-Background",
		tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
		backdropEdgeSize = 16,
		backdropInsets = 4,
		tipColor = { 0, 0, 0, 1 },
		tipBorderColor = { 0, 0, 0, 1 },

		reactColoredBackdrop = true,

		colorRace = { 0.87, 0.93, 1, 0.67},
		colorLevel = { 1, 0.8, 0, 1},

		classification_minus = "Level -%s",
		classification_trivial = "Level ~%s",
		classification_normal = "Level %s",
		classification_elite = "Level %s|cffffcc00 Elite",
		classification_worldboss = "Level %s|cffff0000 Boss",
		classification_rare = "Level %s|cffff66ff Rare",
		classification_rareelite = "Level %s|cffffaaff Rare Elite",

		hideDefaultBar = false,
		healthBar = false,
		manaBar = false,
		powerBar = false,
	},
	-- Solid Border Layout
	["Solid Border"] = {
		showTarget = "last",
		targetYouText = "|cffff0000<<YOU>>",

		tipBackdropBG = "Interface\\Buttons\\WHITE8X8",
		tipBackdropEdge = "Interface\\Buttons\\WHITE8X8",
		backdropEdgeSize = 2.5,
		backdropInsets = 0,
		tipColor = { 0.09, 0.09, 0.19, 1.0 },
		tipBorderColor = { 0.6, 0.6, 0.6, 1.0 },

		reactColoredBackdrop = false,

		colorNameByClass = false,
		classColoredBorder = true,
	},
	-- Solid Border Layout
	["Blizzard"] = {
		colorGuildByReaction = true,
		colorSameGuild = { 1, 0.2, 1, 1 },
		colorRace = { 1, 1, 1, 1},
		colorLevel = { 0.75, 0.75, 0.75, 1},
		colorNameByClass = false,
		classColoredBorder = false,

		reactColoredBackdrop = false,
		reactColoredBorder = false,

		tipBackdropBG = "Interface\\Tooltips\\UI-Tooltip-Background",
		tipBackdropEdge = "Interface\\Tooltips\\UI-Tooltip-Border",
		backdropEdgeSize = 16,
		backdropInsets = 5,
		tipColor = { TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b, 1 },
		tipBorderColor = { 1, 1, 1, 1 },
		gradientTip = false,

		fontFace = "Fonts\\FRIZQT__.TTF",
		fontSize = 12,
		fontFlags = "",
		fontSizeDelta = 2,

		classification_minus = "|rLevel -%s",
		classification_trivial = "|rLevel ~%s",
		classification_normal = "|rLevel %s",
		classification_elite = "|rLevel %s (Elite)",
		classification_worldboss = "|rLevel %s (Boss)",
		classification_rare = "|rLevel %s (Rare)",
		classification_rareelite = "|rLevel %s (Rare Elite)",

		overrideFade = false,
		hideWorldTips = false,

		hideDefaultBar = false,
		healthBar = false,
		manaBar = false,
		powerBar = false,
	},
};

local function LoadLayout_SelectValue(dropDown,entry,index)
	for name, value in next, layout_presets[entry.value] do
		cfg[name] = value;
	end
	local TipTac = _G[PARENT_MOD_NAME];
	TipTac:ApplyConfig();
	dropDown:SetText("|cff80ff80Layout Loaded");
end

local function DeleteLayout_SelectValue(dropDown,entry,index)
	layout_presets[entry.value] = nil;
	dropDown:SetText("|cffff8080Layout Deleted!");
end

function TipTacLayouts.LoadLayout_Init(dropDown,list)
	dropDown.selectValueFunc = LoadLayout_SelectValue;
	for name, cfgTable in next, layout_presets do
		local tbl = list[#list + 1];
		tbl.text = name;
		tbl.value = name;
		local count = 0;
		table.foreach(cfgTable,function() count = count + 1; end);
		tbl.tip = ("%d config variables will be applied"):format(count);
	end
	dropDown:SetText("|cff00ff00Pick Layout...");
end

function TipTacLayouts.DeleteLayout_Init(dropDown,list)
	dropDown.selectValueFunc = DeleteLayout_SelectValue;
	for name in next, layout_presets do
		local tbl = list[#list + 1];
		tbl.text = name; tbl.value = name;
	end
	dropDown:SetText("|cff00ff00Delete Layout...");
end