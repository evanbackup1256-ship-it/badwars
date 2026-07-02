param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"

function Fail($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
    $script:Failed = $true
}

function Pass($message) {
    Write-Host "[ OK ] $message" -ForegroundColor Green
}

function Read-ProjectFile($relativePath) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing required file: $relativePath"
        return ""
    }

    return Get-Content -LiteralPath $path -Raw
}

$script:Failed = $false

$loader = Read-ProjectFile "badscript\loader.lua"
$newMain = Read-ProjectFile "badscript\NewMainScript.lua"
$main = Read-ProjectFile "badscript\main.lua"
$security = Read-ProjectFile "badscript\security.lua"
$newGui = Read-ProjectFile "badscript\guis\new\gui.lua"

$cacheVersions = @()
foreach ($content in @($loader, $newMain)) {
    $match = [regex]::Match($content, "local cacheVersion = '([^']+)'")
    if ($match.Success) {
        $cacheVersions += $match.Groups[1].Value
    }
}

if ($cacheVersions.Count -eq 2 -and $cacheVersions[0] -eq $cacheVersions[1]) {
    Pass "Loader cache versions are synchronized"
} else {
    Fail "Loader cache versions are missing or out of sync"
}

$requiredComponents = @(
    "Button",
    "Toggle",
    "Slider",
    "Dropdown",
    "TextBox",
    "TextList",
    "ColorSlider",
    "Font",
    "TwoSlider",
    "Targets",
    "HotbarList"
)

foreach ($component in $requiredComponents) {
    if ($newGui -match "registerSimpleComponent\('$component'") {
        Pass "Fallback component present: $component"
    } else {
        Fail "Missing fallback component: $component"
    }
}

if ($newGui -match "function optionapi:CreateToggle") {
    Pass "Native CreateToggle API is present"
} else {
    Fail "Native CreateToggle API is missing"
}

if ($newGui -match "registerSimpleComponent\('Font'") {
    Pass "CreateFont compatibility API is present"
} else {
    Fail "CreateFont compatibility API is missing"
}

if ($newGui -match "function api:Color\(hue, sat, val\)[\s\S]{0,80}self:SetValue\(hue, sat, val, true\)") {
    Pass "Fallback color slider refresh is silent"
} else {
    Fail "Fallback color slider refresh may recurse through callbacks"
}

if ($newGui -match "type\(n\) ~= 'number'[\s\S]{0,80}n = nil") {
    Pass "Native GUI color slider ignores boolean rainbow refresh flags"
} else {
    Fail "Native GUI color slider may treat refresh flags as color notches"
}

if ($newGui -match "opacity = tonumber\(opacity\) or 1") {
    Pass "Target Info border color callback guards missing opacity"
} else {
    Fail "Target Info border color callback can still receive nil opacity"
}

if ($newGui -match "Name = 'Blur background'[\s\S]{0,240}Default = false") {
    Pass "Blur background defaults off"
} else {
    Fail "Blur background default is not clearly false"
}

if ($main -match "ERROR empty file" -and $loader -match "ERROR empty file" -and $newMain -match "ERROR empty file") {
    Pass "Empty cache/download files are rejected"
} else {
    Fail "Empty cache/download rejection is incomplete"
}

if ($loader -match "shared\.BadStatus" -and $newMain -match "shared\.BadStatus" -and $main -match "shared\.BadStatus") {
    Pass "Startup status surface is wired through loader and main"
} else {
    Fail "Startup status surface is not wired through every entry point"
}

if ($main -match "security:Start\(Bad\)" -and $main.IndexOf("security:Start(Bad)") -lt $main.IndexOf("loading universal modules")) {
    Pass "Security gate runs before feature modules"
} else {
    Fail "Security gate is missing or runs after feature modules"
}

if ($security -match "Mode = mode" -and $security -match "ApiUrl" -and $security -match "LicenseKey") {
    Pass "Security gate has configurable API licensing"
} else {
    Fail "Security gate licensing configuration is incomplete"
}

if ($security -match "nonce" -and $security -match "timestamp" -and $security -match "VerifySignature") {
    Pass "Security API response validation includes nonce, timestamp, and signature hook"
} else {
    Fail "Security API response validation is incomplete"
}

if ($newGui -match "function mainapi:IsModuleAllowed" -and $newGui -match "Blocked unauthorized module") {
    Pass "GUI module creation honors security permissions"
} else {
    Fail "GUI module permission enforcement is missing"
}

if ($newGui -match "mainapi\.Logs") {
    Pass "Custom console log storage is initialized"
} else {
    Fail "Custom console log storage is missing"
}

$oldPinnedCommit = "b0898d95476b5a8da7cd2f37578b16ec70af95430"
$activeRuntime = @($loader, $newMain, $main, $newGui) -join "`n"
if ($activeRuntime -notmatch [regex]::Escape($oldPinnedCommit)) {
    Pass "Active runtime does not reference the old pinned commit"
} else {
    Fail "Active runtime still references the old pinned commit"
}

$oldBrandTerms = @("Void" + "ware", "VOID" + "WARE", "Void" + "Ware", "vape" + "void" + "ware", "Vape" + "Void" + "ware")
$oldBrandPattern = $oldBrandTerms -join "|"
$brandingMatches = & rg -n $oldBrandPattern "$Root" --glob "!.git/**" --glob "!voidware/**" --glob "!scripts/check-runtime.ps1" 2>$null
if ($LASTEXITCODE -eq 0 -and $brandingMatches) {
    Fail "Found old branding in tracked project files outside the legacy archive"
    $brandingMatches | ForEach-Object { Write-Host "       $_" -ForegroundColor DarkYellow }
} else {
    Pass "No old branding remains outside the legacy archive"
}

if ($script:Failed) {
    exit 1
}

Write-Host "Runtime validation completed." -ForegroundColor Cyan
