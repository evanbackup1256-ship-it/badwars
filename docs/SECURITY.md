# BadWars Security Gate

The runtime includes a defensive license and integrity gate at `badscript/security.lua`.

## Startup Order

The active load path is:

1. Loader initializes filesystem/cache and downloads `main.lua`.
2. Main loads the GUI API so diagnostics can be shown.
3. Main loads and runs `security.lua`.
4. Security validates environment, required cached files, and license/API state.
5. Universal and game modules load only after the gate passes.

## Development Mode

If no API URL is configured, the gate defaults to development mode and logs:

```text
development mode - license API not enforced
```

This keeps local testing usable while making the mode explicit in the console.

## Production Mode

Configure production verification before running the loader:

```lua
shared.BadWarsSecurity = {
    Mode = "production",
    ApiUrl = "https://your-domain.example/verify",
    LicenseKey = "USER_LICENSE_KEY",
    ReleaseChannel = "main",
    RequireSignature = true,
    VerifySignature = function(response)
        -- Verify response.signature using your public-key verifier.
        -- Do not put backend secrets in client code.
        return true
    end
}
```

Production mode fails closed for missing API, missing license, expired, banned, revoked, rate-limited, unsupported, malformed, stale, replayed, or unsigned responses when signatures are required.

## API Response Shape

Expected JSON:

```json
{
  "status": "valid",
  "message": "license verified",
  "nonce": "echo request nonce",
  "timestamp": 1782950400,
  "signature": "optional signature",
  "permissions": {
    "modules": {
      "allowAll": true
    }
  }
}
```

Supported non-valid states are `expired`, `banned`, `revoked`, `rate_limited`, `unsupported`, and `api_unavailable`.

## Permissions

The security gate can block module registration before feature UI or logic is created.

Examples:

```json
{
  "status": "valid",
  "permissions": {
    "games": {
      "allowed": ["6872265039"]
    },
    "modules": {
      "allowedCategories": ["Render", "Utility"],
      "blocked": ["Killaura"]
    }
  }
}
```

## Production Build

Run:

```powershell
.\scripts\build-production.ps1
```

The build writes `dist/badscript`, strips simple Lua comments/blank lines, and generates `dist/badscript/manifest.json` with SHA-256 hashes. `dist/` is ignored by Git.
