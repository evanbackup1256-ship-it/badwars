# BedWars Module Audit V11

- Manifest files: **71**
- Feature modules: **70**
- Registered: **70**
- Replaced or upgraded: **11**
- Syntax validator: **not installed**

## Categories

| Category | Modules |
|---|---:|
| Blatant | 12 |
| Combat | 7 |
| Inventory | 7 |
| Legit | 16 |
| Minigames | 2 |
| Render | 5 |
| Utility | 15 |
| World | 6 |

## File audit

| Module | Category | Registered | Syntax | Patched | Review notes |
|---|---|---:|---|---:|---|
| AntiFall | Blatant | True | not-tested | False | controller dependency, store dependency |
| FastBreak | Blatant | True | not-tested | False | controller dependency |
| Fly | Blatant | True | not-tested | False | controller dependency, store dependency |
| HitBoxes | Blatant | True | not-tested | False | debug mutation, controller dependency |
| KeepSprint | Blatant | True | not-tested | False | debug mutation, controller dependency |
| Killaura | Blatant | True | not-tested | False | debug mutation, controller dependency, store dependency, long-running loop |
| LongJump | Blatant | True | not-tested | False | controller dependency, store dependency |
| NoFall | Blatant | True | not-tested | False | controller dependency |
| NoSlowdown | Blatant | True | not-tested | False | controller dependency |
| ProjectileAimbot | Blatant | True | not-tested | False | controller dependency |
| ProjectileAura | Blatant | True | not-tested | False | controller dependency, store dependency |
| Speed | Blatant | True | not-tested | False | debug mutation, controller dependency |
| AimAssist | Combat | True | not-tested | False | controller dependency, store dependency |
| AutoClicker | Combat | True | not-tested | False | controller dependency, store dependency |
| NoClickDelay | Combat | True | not-tested | False | controller dependency |
| Reach | Combat | True | not-tested | False | controller dependency |
| Sprint | Combat | True | not-tested | False | controller dependency |
| TriggerBot | Combat | True | not-tested | False | controller dependency, store dependency |
| Velocity | Combat | True | not-tested | False | controller dependency |
| Amount | Inventory | True | not-tested | False | controller dependency, store dependency |
| ArmorSwitch | Inventory | True | not-tested | False | controller dependency, store dependency, long-running loop |
| AutoBuy | Inventory | True | not-tested | False | controller dependency, store dependency, long-running loop |
| AutoConsume | Inventory | True | not-tested | False | controller dependency |
| AutoHotbar | Inventory | True | not-tested | True | controller dependency, store dependency |
| FastConsume | Inventory | True | not-tested | False | debug mutation, controller dependency |
| FastDrop | Inventory | True | not-tested | False | controller dependency, store dependency, long-running loop |
| Bed Break Effect | Legit | True | not-tested | True | controller dependency |
| Clean Kit | Legit | True | not-tested | False | controller dependency |
| Crosshair | Legit | True | not-tested | True | connection cleanup review |
| Damage Indicator | Legit | True | not-tested | False | debug mutation, controller dependency |
| FOV | Legit | True | not-tested | False | controller dependency |
| FPS Boost | Legit | True | not-tested | False | controller dependency, store dependency |
| Hit Color | Legit | True | not-tested | False | long-running loop |
| HitFix | Legit | True | not-tested | False | debug mutation, controller dependency |
| Interface | Legit | True | not-tested | False | debug mutation |
| Kill Effect | Legit | True | not-tested | False | controller dependency |
| Reach Display | Legit | True | not-tested | False | store dependency, long-running loop |
| Song Beats | Legit | True | not-tested | False | controller dependency, long-running loop |
| SoundChanger | Legit | True | not-tested | False | controller dependency |
| UI Cleanup | Legit | True | not-tested | False | debug mutation, controller dependency |
| Viewmodel | Legit | True | not-tested | False | controller dependency |
| WinEffect | Legit | True | not-tested | False | controller dependency |
| BadWarsBedPlates | Minigames | True | not-tested | True | controller dependency |
| Breaker | Minigames | True | not-tested | False | controller dependency, store dependency, long-running loop |
| BedESP | Render | True | not-tested | False | none |
| chest | Render | True | not-tested | False | controller dependency |
| Health | Render | True | not-tested | False | non-ASCII source |
| KitESP | Render | True | not-tested | False | controller dependency, store dependency |
| NameTags | Render | True | not-tested | False | controller dependency, store dependency |
| AutoBalloon | Utility | True | not-tested | False | controller dependency, store dependency, long-running loop |
| AutoKit | Utility | True | not-tested | True | controller dependency, store dependency, long-running loop |
| AutoPearl | Utility | True | not-tested | False | controller dependency, store dependency, long-running loop |
| AutoPlay | Utility | True | not-tested | False | controller dependency, store dependency |
| AutoShoot | Utility | True | not-tested | True | controller dependency, store dependency |
| AutoToxic | Utility | True | not-tested | False | controller dependency, store dependency |
| AutoVoidDrop | Utility | True | not-tested | False | controller dependency, store dependency, long-running loop |
| MissileTP | Utility | True | not-tested | False | controller dependency |
| ModuleDiagnostics | Utility | True | not-tested | True | none |
| PickupRange | Utility | True | not-tested | False | controller dependency, long-running loop |
| RavenTP | Utility | True | not-tested | False | controller dependency |
| Scaffold | Utility | True | not-tested | True | controller dependency, store dependency, long-running loop |
| ShopTierBypass | Utility | True | not-tested | True | controller dependency, store dependency |
| StaffDetector | Utility | True | not-tested | True | none |
| TrapDisabler | Utility | True | not-tested | False | none |
| Anti-AFK | World | True | not-tested | False | debug mutation, controller dependency |
| AutoSuffocate | World | True | not-tested | False | controller dependency, store dependency, long-running loop |
| AutoTool | World | True | not-tested | False | controller dependency, store dependency |
| BedProtector | World | True | not-tested | False | controller dependency, store dependency |
| ChestSteal | World | True | not-tested | False | controller dependency, store dependency, long-running loop |
| Schematica | World | True | not-tested | False | controller dependency |

## Runtime protections

- Every module registration is isolated from every other module.
- Toggle and option callbacks are guarded with tracebacks.
- A failing module is disabled and cleaned instead of crashing the full bundle.
- Controller and remote resolution retries after Knit initialization.
- Runtime and static health reports are exposed through Bad:GetBedWarsModuleHealth().
- ModuleDiagnostics shows a summary and can copy the JSON report.
