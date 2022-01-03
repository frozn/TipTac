# TipTac
WoW AddOn TipTac

* based on latest version v20.11.04 from Nov 4, 2020
* added fixes for wow patch 9.1.5

Replace the folders "TipTac", "TipTacItemRef", "TipTacOptions" and "TipTacTalents" with those from the zip file:

shadowlands: "World of Warcraft\_retail_\Interface\AddOns"  
burning crusade classic: "World of Warcraft\_classic_\Interface\AddOns"  
classic: "World of Warcraft\_classic_era_\Interface\AddOns"  

The following problems are fixed:

- lua errors regarding setBackdropColor(), setBackdropBorderColor(), GetRaidTargetIndex() (if icons are enabled), SetPoint()
- background colors
- border colors, also based on unit class or item quality. Additionally the border colors are now "non sticky" if you move your mouse e.g. over items and then over spells.
- backdrop of compare item tooltips, item links and other addons using tiptac to modify tooltips or frames.
- considered new nineslice layout. default tooltip backdrop will be changed with configured backdrop. further styling (background/border texture and backdrop edge size) and 100% solid background is now possible again.
- change between normal and mouse anchors works now while moving your mouse over the corresponding elements.
- prevented flickering of tooltips over buffs if "Anchors->Frame Tip Type" = "Mouse Anchor"
- fixed wrong placement for item comparison tooltips if "Anchors->Frame Tip Type" = "Mouse Anchor".
- added restoring to default font settings when disabling "Font->Modify the GameTooltip Font Templates" without the need to reload the ui for the setting to take effect.
- added styling of battle pet and battle pet ability tooltips
- changes regarding config option "Special->Enable ChatFrame Hover Hyperlinks":
  - fixed hooking/unhooking of chatframe if toggling option
  - added mouseover for guild/community->chat, battle pets, battle pet abilities and illusions (from Wardrobe)
- added class border color for member list in guild/community->chat and guild/community->guild roster if config option "Colors->Color Tip Border by Class Color" is checked
- changes regarding (added) config options under "ItemRef":
  - added border color for spells, tradeskills, currencies (in chatframe), achievements, guild challenges (in guild/community->info) and pvp enlistment bonus (in pvp->quick match)
  - added border color and infos for battle pet, battle pet abilities, (world) quests in worldmap/questlog/questtracker, trade skill reagents (in TradeSkillUI), toys (in ToyBox), items and illusions (in Wardrobe), currencies, achievements in guild/community->info->news, rewards in quest(log)/LFG-browser, runeforge power (in adventure journal), conduits
  - fixed "Smart Icon Appearance" for mounts and mount equipment (in mount journal), items (in adventure journal), spells and items (in guild/community->perks)
- added scroll frame to config options. the scroll bar appears automatically, if content doesn't fit completely on the page.

But for me 99,9% is working now...

If there are additional fixes in the future, I update this note accordingly.
