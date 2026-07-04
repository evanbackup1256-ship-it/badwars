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
$newGui = Read-ProjectFile "badscript\guis\new\gui.lua"
$hashLib = Read-ProjectFile "badscript\libraries\hash.lua"
$predictionLib = Read-ProjectFile "badscript\libraries\prediction.lua"
$entityLib = Read-ProjectFile "badscript\libraries\entity.lua"
$universalBase = Read-ProjectFile "badscript\games\universal - base\base.lua"
$universalManifest = Read-ProjectFile "badscript\games\universal - base\files.txt"
$universalBundle = Read-ProjectFile "badscript\games\universal - base\bundle.lua"

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

if ($newGui -match "function at\.SetValue\(Z,_,aA,aB,aC,aD\)[\s\S]{0,1600}if not aD then[\s\S]{0,80}as\.Function") {
    Pass "Fallback color slider refresh is silent"
} else {
    Fail "Fallback color slider refresh may recurse through callbacks"
}

if ($newGui -match "type\(aC\) ~= 'number'[\s\S]{0,80}aC = nil") {
    Pass "Native GUI color slider ignores boolean rainbow refresh flags"
} else {
    Fail "Native GUI color slider may treat refresh flags as color notches"
}

if ($newGui -match "local opacity = tonumber\([^)]+\) or 1") {
    Pass "Target Info border color callback guards missing opacity"
} else {
    Fail "Target Info border color callback can still receive nil opacity"
}

if ($newGui -match "Name\s*=\s*`"Blur background`"[\s\S]{0,260}Default\s*=\s*false" -or $newGui -match "Name\s*=\s*'Blur background'[\s\S]{0,260}Default\s*=\s*false") {
    Pass "Blur background defaults off"
} else {
    Fail "Blur background default is not clearly false"
}

if ($main -match "ERROR empty file" -and $loader -match "ERROR empty file" -and $newMain -match "ERROR empty file") {
    Pass "Empty cache/download files are rejected"
} else {
    Fail "Empty cache/download rejection is incomplete"
}

if ($hashLib -match "sha512" -and $predictionLib -match "Prediction Library" -and $entityLib -match "entitylib") {
    Pass "Universal runtime libraries are present"
} else {
    Fail "Universal runtime libraries are missing or incomplete"
}

if ($main -match "local function loadLuaBundle" -and $universalManifest -match "Combat/AutoClicker.lua" -and $universalManifest -match "Render/ESP.lua") {
    Pass "Universal feature modules are bundled with base"
} else {
    Fail "Universal feature modules are not bundled with base"
}

if ($main -match "loadPrebuiltBundle\('universal'" -and $universalBundle -match "Combat/AutoClicker.lua" -and $universalBundle -match "Render/ESP.lua") {
    Pass "Prebuilt universal bundle is present"
} else {
    Fail "Prebuilt universal bundle is missing or unused"
}

if ($main -match "local gameModulePaths" -and $main -match "6872274481.*bedwars/6872274481 - game/base.lua" -and $main -match "resolveGameModulePath" -and $main -match "game module ready") {
    Pass "Game-specific modules resolve nested place paths"
} else {
    Fail "Game-specific module resolver is missing nested place paths"
}

if ($main -match "selecting current GUI profile" -and $main -match "writefile\('badscript/profiles/gui.txt', 'new'\)") {
    Pass "Current GUI profile is forced to the new UI"
} else {
    Fail "Current GUI profile is not forced to the new UI"
}

$unescapedPathDownloads = Get-ChildItem -Path "$Root\badscript" -Recurse -File -Include "*.lua" |
    Select-String -Pattern "raw\.githubusercontent\.com/evanbackup1256-ship-it/badwars/main/' \.\. path, true" -SimpleMatch
if ($unescapedPathDownloads) {
    Fail "Found raw GitHub path downloads without space escaping"
    $unescapedPathDownloads | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber) $($_.Line.Trim())" -ForegroundColor DarkYellow }
} else {
    Pass "Raw GitHub path downloads escape spaces"
}

if (
    $universalBundle -match "__badwars_universal_modules" -and
    $universalBundle -match "task\.wait\(0\.06\)" -and
    $universalBundle -match "for __badwars_universal_index, __badwars_universal_module in ipairs" -and
    $universalBundle -notmatch "task\.spawn\(function\(\)\s*local __badwars_universal_total" -and
    $universalBase -match "Crash command is disabled"
) {
    Pass "Universal module startup is throttled"
} else {
    Fail "Universal module startup is not throttled"
}

if ($loader -match "shared\.BadStatus" -and $newMain -match "shared\.BadStatus" -and $main -match "shared\.BadStatus") {
    Pass "Startup status surface is wired through loader and main"
} else {
    Fail "Startup status surface is not wired through every entry point"
}

if ($loader -match "shared\.BadWarsStatusApi" -and $loader -match "Roblox update watch" -and $loader -match "JSONDecode") {
    Pass "Loader can show Roblox update warnings from the website API"
} else {
    Fail "Loader Roblox update warning integration is missing"
}

if (
    -not (Test-Path -LiteralPath (Join-Path $Root "badscript\security.lua")) -and
    $main -notmatch "security:Start\(Bad\)" -and
    $main -notmatch "badscript/security.lua" -and
    $newGui -notmatch "IsModuleAllowed" -and
    $newGui -notmatch "Blocked unauthorized module"
) {
    Pass "Runtime security gate is removed"
} else {
    Fail "Runtime security gate references remain"
}

if ($main -match "universal modules ready" -and $main -match "universal active; no game-specific module found") {
    Pass "Universal-only fallback status is explicit"
} else {
    Fail "Universal-only fallback status is unclear"
}

if ($newGui -match "d\.Logs") {
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
$brandingMatches = Get-ChildItem -Recurse -File -Path $Root -Include "*.lua","*.ts","*.tsx","*.mjs","*.json","*.md","*.txt","*.ps1","*.css" | Where-Object { $_.FullName -notmatch '\\(\.git|voidware|node_modules|package-lock\.json)\\' } | Select-String -Pattern ($oldBrandTerms -join "|") -SimpleMatch
if ($brandingMatches) {
    Fail "Found old branding in tracked project files outside the legacy archive"
    $brandingMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "No old branding remains outside the legacy archive"
}

if ($script:Failed) {
    exit 1
}

Write-Host "Runtime validation completed." -ForegroundColor Cyan
