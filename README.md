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
- change between normal and mouse anchors works now while moving your mouse over the corresponding elements.
- prevented flickering of tooltips over buffs if "Anchors->Frame Tip Type" = "Mouse Anchor"
- added restoring to default font settings when disabling "Font->Modify the GameTooltip Font Templates" without the need to reload the ui for the setting to take effect.

What isn't fixed:

- The fix doesn't include the new NineSlice layout style. This is needed for further styling (background/border texture and backdrop edge size). The blizzard API function SetBackdrop(backdropInfo) for example currently sets only the default tooltip layout without using the desired settings in backdropInfo.
- It seems, that the default tooltip with NineSlice layout has a certain minimum transparency since patch 9.1.5. actually you can't set 100% opaque for the background.

But for me 98% is working now...

If there are additional fixes in the future, I update this note accordingly.
