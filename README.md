# TipTac Reborn (patched fork)

A patched copy of [TipTac Reborn](https://github.com/frozn/TipTac) by Frozn45, the tooltip enhancement addon. It lets you move, restyle, rescale and extend every tooltip in the game.

This fork tracks upstream and adds fixes for Midnight's secret values and taint, plus support for **WoW Forever**. It isn't a separate project. Upstream does the feature work, and this fork keeps it working on the current clients until those fixes land upstream.

Current version: **26.09.03** (upstream) + local fixes.

## Supported clients

| Client | Version | `## Interface` | TOC used |
|---|---|---|---|
| Retail (Midnight) | 12.1.0, 12.1.5 | `120100, 120105` | `<Addon>.toc` |
| WoW Forever | 1.60.1 | `16001` | `<Addon>.toc` |
| Mists of Pandaria Classic | 5.5.4 | `50504` | `<Addon>_Mists.toc` |
| Burning Crusade Anniversary | 2.5.6 | `20506` | `<Addon>_TBC.toc` |
| Classic Era | 1.15.9 | `11509` | `<Addon>_Vanilla.toc` |

WoW Forever (game type `camelot`, `WOW_PROJECT_ID` 18) runs on the Midnight client and loads the mainline UI. So it uses the same base TOC and the same code paths as retail. See [WoW Forever notes](#wow-forever-notes).

## Installation

The addon is four folders, and all four go in `Interface\AddOns`:

- `TipTac`: core tooltip handling, anchoring, bars, auras
- `TipTacItemRef`: item, spell, currency and other reference tooltips
- `TipTacTalents`: spec, talents and average item level on player tooltips
- `TipTacOptions`: the options window (`/tip`), loaded on demand

AddOns folder per client:

```
World of Warcraft\_retail_\Interface\AddOns
World of Warcraft\_forever_\Interface\AddOns
World of Warcraft\_classic_\Interface\AddOns        (MoP Classic)
World of Warcraft\_anniversary_\Interface\AddOns    (TBC Anniversary)
World of Warcraft\_classic_era_\Interface\AddOns
```

Copy the folders from this repo, leaving out `.git`:

```powershell
robocopy <repo>\TipTac "<WoW>\_retail_\Interface\AddOns\TipTac" /E /XD .git
```

Do the same for `TipTacItemRef`, `TipTacTalents` and `TipTacOptions`.

> **Don't update through CurseForge or WowUp.** They install the upstream release over these folders and silently remove the local fixes.

## Local fixes

These fixes are on top of upstream v26.09.03. Most of them guard calls that started throwing under Midnight's secret values when TipTac's execution is tainted. Upstream checks whether a *value* is secret. That misses the case where the value is fine but the *execution context* is tainted, so these fixes wrap the call in `pcall` and skip the line on failure.

| Fix | File(s) | Symptom it prevents |
|---|---|---|
| Guard `GetAuraDataByAuraInstanceID` in the aura-instance hook against a secret `auraInstanceID` | `TipTacItemRef/ttItemRef.lua` | "Auras cannot be accessed when secret" on mouseover of nameplate auras in combat |
| Wrap the same call in `pcall` for tainted execution | `TipTacItemRef/ttItemRef.lua` | The same error from Blizzard_CooldownViewer tooltips on the player's own auras |
| Wrap `C_UnitAuras.GetAuraApplicationDisplayCount` in `pcall`; hide the stack count on failure | `TipTac/modules/ttAuras.lua` | "bad argument #1" from the mouseover aura display (12.1.0) |
| Guard `petOrBattlePetOrNPCTitle` comparisons with `IsSecretValue` and then `pcall` | `TipTac/modules/ttStyle.lua` | "attempt to compare … a secret string value" on pets and vehicles in raids, hundreds of times per session |
| Bail out of `GetTalents` on a secret or invalid unit id | `*/libs/LibFroznFunctions-1.0/LibFroznFunctions-1.0.lua` (all 4 copies) | "Secret values are only allowed during untainted execution" from `UnitIsUnit` |
| Use `C_Item.GetItemInfo` for the macro item lookup | `TipTacItemRef/ttItemRef.lua` | Calls to the deprecated global `GetItemInfo` |
| Add 12.1.5 (`120105`) to the base TOCs | `*/<Addon>.toc` | "Out of date" on 12.1.5 |
| WoW Forever support: `16001` in the base TOCs, Forever detection in LibFroznFunctions (library minor bumped to 68) | `*/<Addon>.toc`, all 4 LibFroznFunctions copies | "Out of date" on Forever; Forever being classified by expansion level |

Run `git log upstream/main..main` for the full reasoning behind each fix. Each commit message records the error it fixes.

## WoW Forever notes

- **Detection:** `LibFroznFunctions.isWoWFlavor.Forever` is true when `WOW_PROJECT_ID == WOW_PROJECT_CAMELOT`. `isWoWFlavor.MN` is set as well, so Forever keeps the Midnight API behaviour and the Midnight lookup tables (enchants, mounts). Without those tables the enchant lookup errors.
- **GearScore:** Forever has vanilla-era item levels, so it doesn't use the Midnight tier-set baseline (219). `itemLevelOfFirstRaidTierSet` is `false` there, which means plain item level sums, so the number isn't comparable with retail.
- **Talents on other players:** Forever has one spec per class, and its inspect window has no talent tab. Tooltips for other players will probably show only the class spec name, with no point breakdown.
- Forever is new. The game type might be renamed from `camelot` to `forever`, and the interface number will change with patches. Check the TOC and the detection after each Forever patch.

## Updating to a new upstream version

1. Fetch and merge upstream:
   ```
   git fetch upstream
   git merge upstream/main
   ```
2. Resolve any conflicts. The fixes touch the files listed above. Keep upstream's change, then re-apply the guard if the call is still unguarded.
3. LibFroznFunctions is bundled four times, under `TipTac`, `TipTacItemRef`, `TipTacTalents` and `TipTacOptions`. All four copies must stay byte-identical. Edit one, copy it over the other three, and bump `LIB_MINOR` if you changed it. LibStub loads only the highest version.
4. Check that the base TOCs still list every client's interface number (`120100, 120105, 16001`, plus any new patch).
5. Check syntax with `luac -p` on the changed files, then deploy.

## Deploying from this repo

Before copying over an existing install, do a dry run to see whether the game folder has files the repo doesn't:

```powershell
robocopy <repo>\TipTac "<WoW>\_retail_\Interface\AddOns\TipTac" /E /XD .git /L
```

robocopy keeps no backup. When it reports *Older* files, compare their contents with `Get-FileHash` before overwriting. They're often just newer timestamps, but they can be edits that never made it into the repo.

## Troubleshooting

**`Font not set`**
Set both **Font → Font Face** and **Bars → Font Face** to a valid font.

**`Action[SetPoint] failed because [SetPoint would result in anchor family connection]: attempted from: GameTooltip:SetPoint`**
Delete `WTF\Account\<Account>\<Server>\<Character>\layout-local.txt` for the affected character.

**Lua errors**
Install BugGrabber and BugSack. Errors are saved to `WTF\Account\<Account>\SavedVariables\!BugGrabber.lua` on `/reload` or logout. If an error comes from upstream code rather than one of the fixes above, check [upstream's issues](https://github.com/frozn/TipTac/issues) first.

## Credits

- **Frozn45:** [TipTac Reborn](https://github.com/frozn/TipTac), which this fork is based on and which does nearly all the work. If you'd like to support the addon, [donate to the upstream author](https://www.paypal.com/donate/?hosted_button_id=X5Y2RAL3PTP6W).
- **Aezay:** the original [TipTac](https://www.curseforge.com/wow/addons/tip-tac), abandoned in 2020 and continued by Frozn45.

Licensed under the same terms as upstream. See [LICENSE](LICENSE).
