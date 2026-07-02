# Engineering Audit

Date: 2026-07-01

## Scope

This pass focused on the active runtime that users execute through the loader. The repository also contains a large legacy/reference archive, but that code is not in the normal live path and should be changed only when a specific migration is planned.

## Key Findings

- The live product path is `badscript`, not the placeholder project shape described by the old README.
- Runtime failures were concentrated around loader cache state, GUI component compatibility, asset download handling, and missing visible diagnostics.
- The new loader/main flow now exposes visible status and specific errors, which is the right direction for field debugging.
- The repo did not have a local validation command for the recent regressions, so the same classes of issue could be reintroduced accidentally.

## Fixed Or Hardened In Recent Runtime Work

- Loader progress now appears on screen through `shared.BadStatus`.
- Empty cached/downloaded files are rejected instead of compiled.
- GUI runtime and compile failures are wrapped with clearer messages.
- GUI asset paths mapped under `badscript/assets` are not downloaded as empty remote files.
- Missing option APIs such as toggles, fonts, color sliders, and common fallback controls have compatibility implementations.
- Blur defaults off so a GUI issue does not leave the whole game view blurred.

## Remaining Risks

- There is no real Lua parser or executor-backed CI in this repo, so local validation is static.
- Several place-specific game modules still contain copied loader helpers. Future cleanup should centralize those helpers after the active GUI path is stable.
- The active runtime still uses remote raw-file loading. That is expected for this project, but it makes cache invalidation and visible diagnostics important.
- The reference/archive tree is very large compared to the active product tree. Keep product fixes scoped to `badscript` unless there is a deliberate migration plan.

## Validation Command

Run this from the repository root:

```powershell
.\scripts\check-runtime.ps1
```

The script checks cache-version sync, required GUI fallback components, blur default, startup status wiring, empty-file rejection, old pinned raw URL references, and old branding outside the legacy archive.
