<picture><img alt="Tooltip" src="https://user-images.githubusercontent.com/5655881/219820911-344b64c3-8aab-43e3-abbc-6bf79c6d85b7.jpg" align="right"></picture>
<picture><img alt="available for" src="https://img.shields.io/badge/available%20for-retail%20(df)%20%2B%20classic%20(wotlkc)%20%2B%20classic%20era%20(vanilla)-brightgreen"></picture>

[![Install](https://img.shields.io/badge/install-curseforge-F16436)](https://www.curseforge.com/wow/addons/tiptac-reborn/files)
&nbsp; 
[![CurseForge all releases](https://cf.way2muchnoise.eu/short_695153_downloads.svg)](https://www.curseforge.com/wow/addons/tiptac-reborn/files)  
[![Install](https://img.shields.io/badge/install-github-24292f)](https://github.com/frozn/TipTac/releases)
&nbsp; 
[![GitHub all releases](https://img.shields.io/github/downloads/frozn/TipTac/total?label=github%20downloads&color=24292f)](https://github.com/frozn/TipTac/releases)

[![paypal](https://img.shields.io/badge/PayPal-Donate-blue)](https://www.paypal.com/donate/?hosted_button_id=X5Y2RAL3PTP6W&item_name=TipTac%20Reborn%20%28from%20curseforge.com%29&cmd=_s-xclick)

# TipTac Reborn
WoW AddOn TipTac Reborn [DF] [WotLKC] [Classic Era]

TipTac Reborn is a tooltip enchancement addon, it allows you to configure various aspects of the tooltip, such as moving where it's shown, the font, the scale of tips, plus a lot more. It's the successor of the original [TipTac by Aezay](https://www.curseforge.com/wow/addons/tip-tac) (abandoned since Nov 2020) with massive modifications since then.

It's also available on [CurseForge](https://www.curseforge.com/wow/addons/tiptac-reborn).

* based on latest version v20.11.04 from Nov 4, 2020 of the original [TipTac by Aezay](https://www.curseforge.com/wow/addons/tip-tac)
* added fixes for WoW patch ...
  * 10.1.0 - Dragonflight [DF]
  * 3.4.1 - Wrath of the Lich King Classic [WotLKC]
  * 1.14.3 - Classic Era / Vanilla [Classic Era]
* added many enhancements

### The following problems are fixed respectively enhancements were added

- lua errors regarding SetBackdropColor(), SetBackdropBorderColor(), GetRaidTargetIndex() (if icons are enabled), SetPoint()
- background colors
- border colors, also based on unit class or item quality. Additionally the border colors are now "non sticky" if you move your mouse e.g. over items and then over spells.
- backdrop of compare item tooltips, item links and other addons using tiptac to modify tooltips or frames.
- considered new nineslice layout. default tooltip backdrop will be changed with configured backdrop. further styling (background/border texture and backdrop edge size) and 100% solid background is now possible again.
- change between normal and mouse anchors works now while moving your mouse over the corresponding elements.
- prevented flickering of tooltips over buffs if "Anchors->Frame Tip Type" = "Mouse Anchor"
- fixed flickering of tooltip when selecting an item or illusion at transmogrifier if "Anchors->Frame Tip Type" = "Mouse Anchor"
- fixed wrong placement for item comparison tooltips if "Anchors->Frame Tip Type" = "Mouse Anchor".
- added restoring to default font settings when disabling "Font->Modify the GameTooltip Font Templates" without the need to reload the ui for the setting to take effect.
- added styling of tooltips for battle pet, battle pet ability, auras from standard nameplate, DropDownList1/2, FriendsTooltip, embedded tooltip, contribution buff (e.g. for contribution reward at legionfall construction table), LibQTip, LibDBIcon, LibDropdown, LibDropdownMC, auras from addon Plater, tooltips from addon RaiderIO, queue status frame (e.g. for lfg/lfr)
- changes regarding config option "Special->Enable ChatFrame Hover Hyperlinks":
  - fixed hooking/unhooking of chatframe if toggling option
  - added mouseover for guild/community->chat, battle pets, battle pet abilities, illusions (from Wardrobe)
  - added mouseover for chatlinks: torghast anima power, transmog item/set, azerite essences and dungeon score
- added class border color for member list in guild/community->chat and guild/community->guild roster, dungeon score tooltip and attendees in LFG list if config option "Colors->Color Tip Border by Class Color" is checked
- changes regarding (added) config options under "ItemRef":
  - added border color for spells, unit auras, tradeskills, currencies (in chatframe), achievements, guild challenges (in guild/community->info) and pvp enlistment bonus (in pvp->quick match)
  - added border color and infos for battle pet, battle pet abilities, (world/party) quests in worldmap/questlog/questtracker, questtracker of addon WorldQuestTracker, trade skill reagents (in TradeSkillUI), toys (in ToyBox), items, illusions and sets (in Wardrobe), sets (at Transmogrifier), currencies, achievements in guild/community->info->news, rewards in quest(log)/LFG-browser, azerite essences, runeforge power (in adventure journal), (enhanced) conduits, spells in macros on action bar, torghast anima powers, mini achievement shields in achievement buttons, items/illusions in dress up frame, flyouts (e.g. mage portals), pet actions, keystones (including RewardLevel, WeeklyRewardLevel, ItemID, TimeLimit and AffixInfos)
  - fixed "Smart Icon Appearance" for mounts and mount equipment (in mount journal), items (in adventure journal), spells and items (in guild/community->perks)
- added scroll frame to config options. the scroll bar appears automatically, if content doesn't fit completely on the page.
- applied transparency from standard backdrop and backdrop border to special backdrop and backdrop border
- fixed timewalking enemy tooltip level color
- added option for pixel perfect tooltip backdrop (edge size and insets) to fix 1-pixel borders which are sometimes 2 pixels wide
- added icons to item comparison tooltips (ShoppingTooltip1/ShoppingTooltip2 and ItemRefShoppingTooltip1/ItemRefShoppingTooltip2)
- fixed fading issues with tooltip
- fixed hooking tips if event VARIABLES_LOADED from TipTacItemRef fired before the one from TipTac
- fixed sometimes flickering tooltip if moving with flying mount and "Anchors->Frame Tip Type" = "Mouse Anchor"
- added anchors and offsets for ItemRef icon (thx to NoBetaBoredom for PR)
- added showing of role and talent/specialization icon, coloring talents by class color, average item level and TipTac's own implementation of GearScore to TipTacTalents. scanning/inspecting of units completely rewritten.
- completely rewritten ttCore. also applied necessary changes to ttStyle, ttBars, ttAuras and ttIcons.
- scanning/inspecting of talents and average item level completely rewritten
- added option in "Anchors" to override GTT anchor for world/frame units/tips in combat and (Guild & Community) ChatFrame
- added option "Backdrop->Enable Backdrop Modifications" to enable/disable all backdrop modifications
- added option "Combat->Hide Tips" and "Combat->Hide Tips In Combat" to hide frame and/or world unit tips or all tips in or out of combat
- added option "General->Show Mythic+ Dungeon Score" to show mythic+ dungeon score and best run
- added option "General->Show Current Unit Speed" to show current unit speed after race & class
- added option "General->Show Player Guild Rank Title->Format" to also show player guild rank level in addition to guild rank title
- added option "General->Show Mount" to show the player's mount icon/name/speed and an icon indicating if you already have collected the mount
- added option "ItemRef->Show Mount ID" to show the mount id
- added option "ItemRef->Show Icon ID" to show the icon id
- added option in "ItemRef" to show stack count of items in tooltip
- added options "ItemRef->Show Expansion Icon/Name" to show the expansion icon/name of the item. This feature is only available in retail and not in WotLKC or classic era.
- added refresh anchoring of shopping tooltips after re-anchoring of tip to prevent overlapping tooltips
- considered debuff border for aura positions
- splitted options for auras from spells
- automatically reduce tip's scale if its size exceeds UIParent width/height
- option "General->Show Who Targets the Unit" now evaluates the visible nameplates when ungrouped
- added option "Reactions->Show the unit's reaction as icon"
- added unit reaction for honored, revered and exalted NPCs
- added showing/hiding of options to WoW's interface options
- classic era: fixed lua errors in talents module regarding GetSpecialization() and GetInspectSpecialization()
- classic era: added missing styling of auras
- classic era: reactivated talent format option
- classic era: suppressed error speech/message when calling CanInspect(unit) within TipTacTalents
- classic era: fixed sometimes missing displaying of level, race, class and talents for unit tooltips

### The following problems aren't fixed

- Padding for embedded tooltips and battle pet (ability) tooltips doesn't work. However, this only becomes a problem if a particularly thick border is set.

If there are additional fixes in the future, I update this note accordingly.

## Install with CurseForge app

In [CurseForge app](https://download.curseforge.com/), go to `World of Warcraft`, choose your flavor (Retail, WotLK Classic, Classic) and search for `TipTac Reborn`. Hit `Install` button.

## Install with WowUp.io

In [WowUp](https://wowup.io/), go to `Get Addons->Install From URL` and enter `https://github.com/frozn/TipTac`

## Manual Installation

Get [latest release](https://github.com/frozn/TipTac/releases) and replace the folders `TipTac`, `TipTacItemRef`, `TipTacOptions` and `TipTacTalents` with those from the zip file.

Dragonflight: `\World of Warcraft\_retail_\Interface\AddOns`  
Wrath of the Lich King Classic: `\World of Warcraft\_classic_\Interface\AddOns`  
Classic Era: `\World of Warcraft\_classic_era_\Interface\AddOns`  

## Buy me a coffee
Donations are welcome to appreciate my work to keep this addon alive, but isn't required at all. If you would like to donate (as requested to me), you can do so down below:

[![paypal](https://img.shields.io/badge/PayPal-Donate-blue)](https://www.paypal.com/donate/?hosted_button_id=X5Y2RAL3PTP6W&item_name=TipTac%20Reborn%20%28from%20curseforge.com%29&cmd=_s-xclick)

After using many WoW addons in the last years I decided to give something back to the mod/addon community and continued the one or other not longer supported/maintained projects (see [here](https://www.curseforge.com/members/frozn45/projects)) including TipTac.

## Common issues

#### Error message: `Font not set`
**Solution:** Make sure both the `Font->Font Face`, as well as the `Bars->Font Face` are properly set to a valid font.

#### Error message: `Action[SetPoint] failed because[SetPoint would result in anchor family connection]: attempted from: GameTooltip:SetPoint`
**Solution:** Delete file `World of Warcraft\__<Edition>__\WTF\<Account>\<Server>\<Character>\layout-local.txt`
