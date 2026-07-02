param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path,
    [string]$Output = "dist\badscript"
)

$ErrorActionPreference = "Stop"

$source = Join-Path $Root "badscript"
$target = Join-Path $Root $Output
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$targetParent = Split-Path -Parent $target
New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
$resolvedTargetParent = (Resolve-Path -LiteralPath $targetParent).Path
if (-not $resolvedTargetParent.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to write outside repository root: $target"
}
if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $target | Out-Null

function Minify-Lua($text) {
    $lines = $text -split "`r?`n"
    $result = foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("--")) {
            continue
        }
        $line -replace "\s+--.*$", ""
    }
    ($result -join "`n").Trim() + "`n"
}

$manifest = [ordered]@{
    buildId = "badwars-production-" + (Get-Date -Format "yyyyMMddHHmmss")
    generatedAt = (Get-Date).ToUniversalTime().ToString("o")
    files = @()
}

Get-ChildItem -LiteralPath $source -Recurse -File | ForEach-Object {
    $relative = $_.FullName.Substring($source.Length).TrimStart("\", "/")
    $outPath = Join-Path $target $relative
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outPath) | Out-Null

    if ($_.Extension -eq ".lua") {
        $content = Get-Content -LiteralPath $_.FullName -Raw
        Set-Content -LiteralPath $outPath -Value (Minify-Lua $content) -NoNewline
    } else {
        Copy-Item -LiteralPath $_.FullName -Destination $outPath
    }

    $hash = Get-FileHash -LiteralPath $outPath -Algorithm SHA256
    $manifest.files += [ordered]@{
        path = $relative.Replace("\", "/")
        sha256 = $hash.Hash.ToLowerInvariant()
        bytes = (Get-Item -LiteralPath $outPath).Length
    }
}

$manifestPath = Join-Path $target "manifest.json"
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath
Write-Host "Production build written to $target" -ForegroundColor Cyan
