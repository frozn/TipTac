![TipTac Reborn](https://github.com/user-attachments/assets/69b67fe4-4922-48c4-8ea7-bf83ec3b9a5d)

![Available for](https://img.shields.io/badge/available%20for-retail/MN%20%2B%20classic/MoPC%20%2B%20anniversary/TBC%20%2B%20classic%20era/Vanilla-brightgreen)

[![Install CurseForge](https://img.shields.io/badge/install-curseforge-F16436)](https://www.curseforge.com/wow/addons/tiptac-reborn/files)
&nbsp; 
[![CurseForge all releases](https://cf.way2muchnoise.eu/short_695153_downloads.svg)](https://www.curseforge.com/wow/addons/tiptac-reborn/files)  
[![Install GitHub](https://img.shields.io/badge/install-github-24292f)](https://github.com/frozn/TipTac/releases)
&nbsp; 
[![GitHub all releases](https://img.shields.io/github/downloads/frozn/TipTac/total?label=github%20downloads&color=24292f)](https://github.com/frozn/TipTac/releases)

[![PayPal](https://img.shields.io/badge/PayPal-Donate-blue)](https://www.paypal.com/donate/?hosted_button_id=X5Y2RAL3PTP6W&item_name=TipTac%20Reborn%20%28from%20curseforge.com%29&cmd=_s-xclick)

# TipTac Reborn
WoW AddOn TipTac Reborn [retail/MN] [classic/MoPC] [anniversary/TBC] [classic era/Vanilla]

TipTac Reborn is a tooltip enhancement addon, it allows you to configure various aspects of the tooltip, such as moving where it's shown, the font, the scale of tips, plus a lot more. It's the successor of the original [TipTac by Aezay](https://www.curseforge.com/wow/addons/tip-tac) (abandoned since Nov 2020) with massive modifications since then.

It's also available on [CurseForge](https://www.curseforge.com/wow/addons/tiptac-reborn).

* based on latest version v20.11.04 from Nov 4, 2020 of the original [TipTac by Aezay](https://www.curseforge.com/wow/addons/tip-tac)
* added fixes for WoW patch ...
  * 12.0.7 - The War Within [retail/MN]
  * 5.5.4 - Mists of Pandaria Classic [classic/MoPC]
  * 2.5.5 - Burning Crusade Classic [anniversary/TBC]
  * 1.15.8 - Vanilla [classic era/Vanilla]
* added many enhancements

## Install with CurseForge app

In [CurseForge app](https://download.curseforge.com/), go to `World of Warcraft`, choose your flavor (Retail, Cataclysm Classic, Classic) and search for `TipTac Reborn`. Hit `Install` button.

## Install with WowUp.io

In [WowUp](https://wowup.io/), go to `Get Addons->Install From URL` and enter `https://github.com/frozn/TipTac`

## Manual Installation

Get [latest release](https://github.com/frozn/TipTac/releases) and replace the folders `TipTac`, `TipTacItemRef`, `TipTacOptions` and `TipTacTalents` with those from the zip file.

The War Within: `\World of Warcraft\_retail_\Interface\AddOns`  
Cataclysm Classic: `\World of Warcraft\_classic_\Interface\AddOns`  
Classic Era: `\World of Warcraft\_classic_era_\Interface\AddOns`  

## Buy me a coffee
Donations are welcome to appreciate my work to keep this addon alive, but isn't required at all. If you would like to donate (as requested to me), you can do so down below:

[![paypal](https://img.shields.io/badge/PayPal-Donate-blue)](https://www.paypal.com/donate/?hosted_button_id=X5Y2RAL3PTP6W&item_name=TipTac%20Reborn%20%28from%20curseforge.com%29&cmd=_s-xclick)

After using many WoW addons in the last years I decided to give something back to the mod/addon community and continued the one or other not longer supported/maintained projects (see [here](https://www.curseforge.com/members/frozn45/projects)) including TipTac.

## Common issues

#### Error message: `Font not set`
**Solution:** Make sure both the `Font->Font Face`, as well as the `Bars->Font Face` are properly set to a valid font.

#### Error message: `Action[SetPoint] failed because[SetPoint would result in anchor family connection]: attempted from: GameTooltip:SetPoint`
**Solution:** Delete file `World of Warcraft\__<Flavor>__\WTF\<Account>\<Server>\<Character>\layout-local.txt`
