# BadWars Runtime Architecture

This repository contains one active runtime and several reference/archive areas. The live client path is the `badscript` tree.

## Runtime Entry Points

- `badscript/entry.lua` is the short public entry point.
- `badscript/loader.lua` is the primary loader. It creates the visible `BadWars:` status label, refreshes stale cache files, downloads `badscript/main.lua`, compiles it, and runs it through `xpcall`.
- `badscript/NewMainScript.lua` mirrors the loader flow for alternate executor entry paths.
- `badscript/main.lua` selects and runs the configured GUI, loads universal modules, then tries the current place-specific module.

The loader and main runtime intentionally surface progress and failures through `shared.BadStatus`, so Roblox console screenshots show a specific stage instead of a silent freeze.

## Active Product Tree

- `badscript/guis/new/gui.lua`: current GUI implementation and compatibility fallbacks.
- `badscript/games/universal - base/base.lua`: universal module loaded for every supported game.
- `badscript/games/<game>/<place>.lua`: place-specific runtime modules.
- `badscript/libraries`: shared Lua helpers downloaded by game modules.
- `badscript/assets`: local GUI/image assets that should not be fetched through the raw-file downloader.

## Reference Tree

The large legacy archive at the repository root is not part of the live loader path. Treat it as upstream/reference material unless a task explicitly says to migrate code from it. Broad rewrites there are high risk because the active runtime does not execute those files directly.

## Cache Strategy

The loader stores files under `badscript` inside the executor filesystem. `loader.lua` and `NewMainScript.lua` must keep the same `cacheVersion` value. When a runtime fix changes cached behavior, bump both strings so old cached files are cleared on the next load.

## GUI Compatibility

The new GUI has native option APIs plus fallback components for modules that expect older option names. The minimum fallback surface is:

- `Button`
- `Toggle`
- `Slider`
- `Dropdown`
- `TextBox`
- `TextList`
- `ColorSlider`
- `Font`
- `TwoSlider`
- `Targets`
- `HotbarList`

Run `scripts/check-runtime.ps1` before pushing changes that touch `badscript/loader.lua`, `badscript/NewMainScript.lua`, `badscript/main.lua`, or `badscript/guis/new/gui.lua`.

## Operational Notes

- The current loader fetches from the `main` branch raw URL. For emergency user testing, a commit-pinned loadstring can be provided, but committed source should not permanently depend on an old commit.
- Roblox warnings for invalid animations or temporary font reads are not loader failures by themselves. A real loader failure should now appear in the status label as `BadWars: ERROR ...`.
- Blur is defaulted off in the new GUI to avoid trapping users behind a full-screen blur if a later GUI update errors.
