# BadWars

BadWars is a Roblox Lua client runtime with a remote loader, GUI layer, universal modules, and place-specific game modules.

## Active Runtime

- `badscript/entry.lua`: short public entry point.
- `badscript/loader.lua`: primary loader and cache refresh path.
- `badscript/NewMainScript.lua`: alternate loader entry path.
- `badscript/main.lua`: GUI selection, universal module load, and game-module dispatch.
- `badscript/guis/new/gui.lua`: current GUI implementation.
- `badscript/games`: universal and place-specific runtime modules.

The loader writes visible progress and exact failure messages through the `BadWars:` status label. If a user reports a freeze, the label text and Developer Console error should point to the failing stage.

## Loadstring

Use the branch loader for normal testing:

```lua
if delfolder and isfolder and isfolder("badscript") then
    delfolder("badscript")
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/evanbackup1256-ship-it/badwars/main/badscript/loader.lua", true), "badwars-loader")()
```

For emergency testing, use a commit-pinned raw URL from the latest pushed commit.

## Validation

Run the runtime checks before pushing loader or GUI changes:

```powershell
.\scripts\check-runtime.ps1
```

The check covers cache-version sync, required GUI fallback APIs, blur default, startup status wiring, empty-file rejection, old pinned raw URL references, and old branding outside the legacy archive.

## Documentation

- [Runtime Architecture](docs/ARCHITECTURE.md)
- [Engineering Audit](docs/ENGINEERING_AUDIT.md)
- [Security Gate](docs/SECURITY.md)

## Development Notes

- Keep changes to the active product path scoped to `badscript` unless intentionally migrating reference code.
- Bump the `cacheVersion` in both loader entry files when changing cached runtime behavior.
- Avoid adding silent fallbacks for loader failures. Surface the exact stage and error so in-game reports are actionable.
