-- create addon
local MOD_NAME = ...;
local PARENT_MOD_NAME = "TipTac";
local TipTac = _G[PARENT_MOD_NAME];
TipTacLayouts = {};

-- get libs
local LibFroznFunctions = LibStub:GetLibrary("LibFroznFunctions-1.0");
local LibSerialize = LibStub:GetLibrary("LibSerialize");
local LibDeflate = LibStub:GetLibrary("LibDeflate");

-- set config
local configDb, cfg = LibFroznFunctions:CreateDbWithLibAceDB("TipTac_Config");

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
		pixelPerfectBackdrop = false,
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
		pixelPerfectBackdrop = false,
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
		pixelPerfectBackdrop = false,
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
		pixelPerfectBackdrop = false,
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
		pixelPerfectBackdrop = true,
		backdropEdgeSize = 1,
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
		pixelPerfectBackdrop = false,
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
	dropDown:SetText("|cffff0000Delete Layout...");
end

local function SwitchProfile_SelectValue(dropDown,entry,index)
	configDb:SetProfile(entry.value);
	TipTac:ApplyConfig();
	local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
	TipTacOptions:BuildCategoryPage(true);
	TipTacOptions:BuildCategoryList();
	dropDown:SetText("|cff80ff80Profile Set");
end

local function CopyProfile_SelectValue(dropDown,entry,index)
	configDb:CopyProfile(entry.value);
	TipTac:ApplyConfig();
	local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
	TipTacOptions:BuildCategoryPage(true);
	TipTacOptions:BuildCategoryList();
	dropDown:SetText("|cff80ff80Profile Copied");
end

function TipTacLayouts.CreateProfile_SelectValue(self, var, value, noBuildCategoryPage)
	configDb:SetProfile(value);
	TipTac:ApplyConfig();
	local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
	TipTacOptions:BuildCategoryPage(true);
	TipTacOptions:BuildCategoryList();
end

function TipTacLayouts.ExportSettings_SelectValue(self, option)
	-- build export string with current config
	local serializedConfig = LibSerialize:Serialize(cfg.__GetLinkedTable);
	local compressedConfig = LibDeflate:CompressDeflate(serializedConfig);
	local encodedConfig = LibDeflate:EncodeForPrint(compressedConfig);
	
	-- open popup with export string with current config
	if (encodedConfig) then
		LibFroznFunctions:ShowPopupWithText({
			prompt = "Copy this export string with current config:",
			lockedText = encodedConfig,
			iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents",
			iconTexCoord = { 0.924316, 0.942871, 0.000976562, 0.0361328 },
			acceptButtonText = "Close",
			onShowHandler = function(self, data)
				-- fix icon position
				local alertIcon = (self.AlertIcon or _G[self:GetName() .. "AlertIcon"]);
				
				if (not alertIcon) then
					return;
				end
				
				alertIcon:ClearAllPoints();
				
				if (self.Resize) then -- GameDialogMixin:Resize() available since tww 11.2.0
					alertIcon:SetPoint("LEFT", 24, 6);
				else
					alertIcon:SetPoint("LEFT", 24, 3);
				end
			end
		});
	end
end

function TipTacLayouts.ImportSettings_SelectValue(self, option)
	-- open popup to get import string with new config
	LibFroznFunctions:ShowPopupWithText({
		prompt = "Paste export string with new config:",
		iconFile = "Interface\\AddOns\\" .. PARENT_MOD_NAME .. "\\media\\Talents",
		iconTexCoord = { 0.924316, 0.944824, 0.0380859, 0.0771484 },
		acceptButtonText = "Import",
		cancelButtonText = "Cancel",
		onShowHandler = function(self, data)
			-- fix icon position
			local alertIcon = (self.AlertIcon or _G[self:GetName() .. "AlertIcon"]);
			
			if (not alertIcon) then
				return;
			end
			
			alertIcon:ClearAllPoints();
			
			if (self.Resize) then -- GameDialogMixin:Resize() available since tww 11.2.0
				alertIcon:SetPoint("LEFT", 24, 7);
			else
				alertIcon:SetPoint("LEFT", 24, 4);
			end
		end,
		onAcceptHandler = function(self, data)
			-- import export string with new config
			local editBox = (self.GetEditBox and self:GetEditBox() or self.editBox); -- acccessor method GetEditBox() available since tww 11.2.0
			local encodedConfig = editBox:GetText();
			local compressedConfig = LibDeflate:DecodeForPrint(encodedConfig);
			
			local function addFailedMessageToChatFrame()
				TipTac:AddMessageToChatFrame("{caption:" .. PARENT_MOD_NAME .. "}: {error:Couldn't import new config. Export string may be corrupt.}");
			end
			
			if (not compressedConfig) then
				addFailedMessageToChatFrame();
				return;
			end
			
			local serializedConfig = LibDeflate:DecompressDeflate(compressedConfig);
			
			if (not serializedConfig) then
				addFailedMessageToChatFrame();
				return;
			end
			
			local success, newCfg = LibSerialize:Deserialize(serializedConfig);
			
			if (not success) or (type(newCfg) ~= "table") then
				addFailedMessageToChatFrame();
				return;
			end
			
			-- apply new config
			LibFroznFunctions:MixinWholeObjects(cfg, newCfg);
			
			-- inform group that the config has been loaded
			-- LibFroznFunctions:FireGroupEvent(PARENT_MOD_NAME, "OnConfigLoaded", TT_CacheForFrames, configDb, cfg, TT_ExtendedConfig);
			
			-- apply config
			TipTac:ApplyConfig();
			local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
			TipTacOptions:BuildCategoryPage(true);
			TipTacOptions:BuildCategoryList();
			
			TipTac:AddMessageToChatFrame("{caption:" .. PARENT_MOD_NAME .. "}: Successfully imported new config.");
		end
	});
end

function TipTacLayouts.ResetProfile_SelectValue(self, option)
	configDb:ResetProfile();
	
	-- inform group that the config has been loaded
	-- LibFroznFunctions:FireGroupEvent(PARENT_MOD_NAME, "OnConfigFullyResetted", TT_CacheForFrames, cfg, TT_ExtendedConfig);
	TipTac:ClearAllPoints();
	TipTac:SetPoint("CENTER");
	
	TipTac:ApplyConfig();
	local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
	TipTacOptions:BuildCategoryPage(true);
	TipTacOptions:BuildCategoryList();
	TipTac:AddMessageToChatFrame("{caption:" .. PARENT_MOD_NAME .. "}: Successfully resetted current profile.");
end

local function DeleteProfile_SelectValue(dropDown,entry,index)
	configDb:DeleteProfile(entry.value);
	local TipTacOptions = _G[PARENT_MOD_NAME .. "Options"];
	TipTacOptions:BuildCategoryPage(true);
	TipTacOptions:BuildCategoryList();
	dropDown:SetText("|cffff8080Profile Deleted");
end

function TipTacLayouts.SwitchProfile_Init(dropDown,list)
	local profiles = LibFroznFunctions:GetProfilesFromDbFromLibAceDB(configDb, true);
	dropDown.selectValueFunc = SwitchProfile_SelectValue;
	for _, name in ipairs(profiles) do
		local tbl = list[#list + 1];
		tbl.text = name;
		tbl.value = name;
	end
	if (dropDown.button:IsEnabled()) then
		dropDown:SetText("|cff00ff00Pick Profile...");
	else
		dropDown:SetText("Pick Profile...");
		dropDown.label:SetTextColor(0.5, 0.5, 0.5);
	end
end

function TipTacLayouts.CopyProfile_Init(dropDown,list)
	local profiles = LibFroznFunctions:GetProfilesFromDbFromLibAceDB(configDb, true);
	dropDown.selectValueFunc = CopyProfile_SelectValue;
	for _, name in ipairs(profiles) do
		local tbl = list[#list + 1];
		tbl.text = name;
		tbl.value = name;
	end
	if (dropDown.button:IsEnabled()) then
		dropDown:SetText("|cff00ff00Pick Profile...");
	else
		dropDown:SetText("Pick Profile...");
		dropDown.label:SetTextColor(0.5, 0.5, 0.5);
	end
end

function TipTacLayouts.DeleteProfile_Init(dropDown,list)
	local profiles = LibFroznFunctions:GetProfilesFromDbFromLibAceDB(configDb, true, true);
	dropDown.selectValueFunc = DeleteProfile_SelectValue;
	for _, name in ipairs(profiles) do
		local tbl = list[#list + 1];
		tbl.text = name;
		tbl.value = name;
	end
	if (dropDown.button:IsEnabled()) then
		dropDown:SetText("|cffff0000Delete Profile...");
	else
		dropDown:SetText("Delete Profile...");
		dropDown.label:SetTextColor(0.5, 0.5, 0.5);
	end
end