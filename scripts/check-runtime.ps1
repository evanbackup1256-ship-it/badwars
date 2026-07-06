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
$bedwarsBase = Read-ProjectFile "badscript\games\bedwars\6872274481 - game\base.lua"
$hashLib = Read-ProjectFile "badscript\libraries\hash.lua"
$predictionLib = Read-ProjectFile "badscript\libraries\prediction.lua"
$sprLib = Read-ProjectFile "badscript\libraries\spr.lua"
$sprLicense = Read-ProjectFile "badscript\libraries\spr.LICENSE.txt"
$diagnostics = Read-ProjectFile "badscript\libraries\diagnostics.lua"
$phaseModule = Read-ProjectFile "badscript\games\universal - base\Blatant\Phase.lua"
$swimModule = Read-ProjectFile "badscript\games\universal - base\Blatant\Swim.lua"
$animationModule = Read-ProjectFile "badscript\games\universal - base\Utility\AnimationPlayer.lua"
$entityLib = Read-ProjectFile "badscript\libraries\entity.lua"
$universalBase = Read-ProjectFile "badscript\games\universal - base\base.lua"
$universalManifest = Read-ProjectFile "badscript\games\universal - base\files.txt"
$universalBundle = Read-ProjectFile "badscript\games\universal - base\bundle.lua"
$languageFlags = Read-ProjectFile "badscript\translations\LanguageFlags.json"
$languagesIndex = Read-ProjectFile "badscript\translations\Languages.json"
$robloxVersionStatus = Read-ProjectFile "badscript\profiles\roblox-version.txt"

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

if (
    $newGui -match 'Version\s*=\s*"19\.0"' -and
    $newGui -match 'PremiumBuild\s*=\s*"2026\.07\.06-V19-OBSIDIAN-OVERHAUL"' -and
    $newGui -match 'BADWARS_UI_V19_OBSIDIAN_OVERHAUL' -and
    $main -match "BadWars Main v19\.0" -and
    $loader -match "BadWars Loader v19\.0" -and
    $bedwarsBase -match 'compatibility\.Version\s*=\s*"19\.0"'
) {
    Pass "V19 runtime versions are synchronized"
} else {
    Fail "V19 runtime versions are not synchronized"
}


if (
    $sprLib -match 'Spring-driven motion library' -and
    $sprLib -match 'function spr\.target' -and
    $sprLib -match 'function spr\.stop' -and
    $sprLicense -match 'MIT License' -and
    $sprLicense -match 'Copyright \(c\) 2023 Fractality' -and
    $main -match 'badscript/libraries/spr\.lua' -and
    $main -match 'shared\.BadWarsSpr' -and
    $newGui -match 'MotionLibrary\s*=\s*shared\.BadWarsSpr' -and
    $newGui -match 'function n\.Spring' -and
    $newGui -match 'n:Spring\('
) {
    Pass "Public spr motion library is vendored and integrated"
} else {
    Fail "Public spr motion integration is incomplete"
}


if (
    $newGui -match 'SpringInteractive.*Public\s*=\s*false' -and
    $newGui -match 'local function bindDirectDrag' -and
    $newGui -match 'ResizeThread\s*=\s*nil' -and
    $newGui -match 'ScrollingEnabled\s*=\s*true' -and
    $newGui -match 'function ai\.RefreshScroll' -and
    $diagnostics -match 'BADWARS_DIAGNOSTICS_V19_OBSIDIAN_OVERHAUL' -and
    $diagnostics -notmatch 'local openerDot'
) {
    Pass "V19 Obsidian overhaul and stability repairs are present"
} else {
    Fail "V19 Obsidian overhaul or stability repairs are incomplete"
}


if (
    $newGui -notmatch '(?m)^\s*popup\.ClipsDescendants\s*=' -and
    $newGui -notmatch '(?m)^\s*card\.ClipsDescendants\s*=' -and
    $loader -notmatch '(?m)^\s*statusCard\.ClipsDescendants\s*=' -and
    $diagnostics -notmatch '(?m)^\s*window\.ClipsDescendants\s*=' -and
    $diagnostics -match 'ClipsDescendants is always true on CanvasGroup' -and
    $diagnostics -match 'Roblox rejected animation asset'
) {
    Pass "CanvasGroup warnings and native animation noise are handled"
} else {
    Fail "CanvasGroup or native animation diagnostics handling is incomplete"
}

if (
    $phaseModule -match "local handler = Functions\[Mode and Mode\.Value\]" -and
    $phaseModule -match "type\(setfflag\) ~= 'function'" -and
    $phaseModule -match 'Character\s*=\s*function' -and
    $swimModule -notmatch 'Region3\.new\(Vector3\.zero, Vector3\.zero\)' -and
    $swimModule -match 'local function clearLastRegion' -and
    $animationModule -match 'local rejectedIds = \{\}' -and
    $animationModule -match 'disableAfterFailure'
) {
    Pass "Phase, Swim, and AnimationPlayer runtime faults are guarded"
} else {
    Fail "Universal module runtime guards are incomplete"
}

$requiredComponentApis = @(
    "CreateButton",
    "CreateToggle",
    "CreateSlider",
    "CreateDropdown",
    "CreateTextBox",
    "CreateTextList",
    "CreateColorSlider",
    "CreateFont",
    "CreateTwoSlider",
    "CreateTargetsButton"
)

foreach ($api in $requiredComponentApis) {
    $componentName = $api -replace "^Create", ""
    if ($newGui -match "[:.]$api\(" -or $newGui -match "\b$componentName\s*=\s*function" -or $newGui -match "\.$componentName\(") {
        Pass "GUI component API present: $api"
    } else {
        Fail "Missing GUI component API: $api"
    }
}

if ($newGui -match "[:.]CreateToggle\(") {
    Pass "Native CreateToggle API is present"
} else {
    Fail "Native CreateToggle API is missing"
}

if ($newGui -match "[:.]CreateFont\(") {
    Pass "CreateFont compatibility API is present"
} else {
    Fail "CreateFont compatibility API is missing"
}

if ($newGui -match "NoDefaultCallback" -and $newGui -match "CreateColorSlider") {
    Pass "Color slider supports silent/default-safe refresh patterns"
} else {
    Fail "Color slider refresh/default guard is missing"
}

if ($newGui -match "CreateColorSlider" -and $newGui -match "Darker") {
    Pass "Native GUI color slider options are present"
} else {
    Fail "Native GUI color slider options are missing"
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

if ($main -match "loadPrebuiltBundle\(`"universal`"" -and $universalBundle -match "Combat/AutoClicker.lua" -and $universalBundle -match "Render/ESP.lua") {
    Pass "Prebuilt universal bundle is present"
} else {
    Fail "Prebuilt universal bundle is missing or unused"
}

if ($main -match "local gameModulePaths" -and $main -match "6872274481.*bedwars/6872274481 - game/base.lua" -and $main -match "resolveGameModulePath" -and $main -match "game module ready") {
    Pass "Game-specific modules resolve nested place paths"
} else {
    Fail "Game-specific module resolver is missing nested place paths"
}

if ($main -match "selecting interface" -and $main -match 'writefile\("badscript/profiles/gui.txt", "new"\)') {
    Pass "Current GUI profile is forced to the new UI"
} else {
    Fail "Current GUI profile is not forced to the new UI"
}

$legacyGuiPaths = @(
    "badscript\guis\old",
    "badscript\guis\rise",
    "badscript\guis\wurst",
    "badscript\guis\liquidbounce"
)
$presentLegacyGuiPaths = @($legacyGuiPaths | Where-Object { Test-Path -LiteralPath (Join-Path $Root $_) })
if ($presentLegacyGuiPaths.Count -eq 0 -and $main -match 'local gui = defaultGui' -and $main -notmatch 'validGuis') {
    Pass "Legacy UI implementations are absent and unreachable"
} else {
    Fail "A legacy UI implementation or selector remains reachable"
}

if (
    $newGui -match 'HUD/display features are ordinary Render modules' -and
    $newGui -match 'renderCategory:CreateModule' -and
    $newGui -notmatch 'Name\s*=\s*"Overlays"' -and
    $newGui -notmatch 'CreateOverlayBar\(\{\s*Hidden\s*=\s*true'
) {
    Pass "Overlay navigation is removed and HUDs register in Render"
} else {
    Fail "Overlay navigation or special overlay registration still exists"
}

if (
    $newGui -match 'local aw = Instance\.new\("Frame"\)[\s\S]{0,260}SettingsPane' -and
    $newGui -match 'BADWARS_SETTINGS_PAGE_MANAGER_V3' -and
    $newGui -notmatch 'aw\.GroupTransparency'
) {
    Pass "Settings pages use visible frame state instead of shared CanvasGroup fading"
} else {
    Fail "Settings page visibility architecture is still vulnerable to blank panes"
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

if (
    $loader -match "shared\.BadWarsStatusApi" -and
    $loader -match "Roblox update watch" -and
    $loader -match "JSONDecode" -and
    $loader -match "raw\.githubusercontent\.com/evanbackup1256-ship-it/badwars/main/badscript/profiles/roblox-version\.txt" -and
    $loader -notmatch "api\.github\.com/repos/evanbackup1256-ship-it/badwars/raw" -and
    $robloxVersionStatus -match '"status"\s*:\s*"ok"'
) {
    Pass "Loader can show Roblox update warnings from the website API"
} else {
    Fail "Loader Roblox update warning integration is missing"
}

if ($loader -match "shared\.__badwars_update_watch\s*=\s*token" -and $loader -match "while shared\.__badwars_update_watch==token do") {
    Pass "Loader update watch is reinjection-safe"
} else {
    Fail "Loader update watch can duplicate across reinjections"
}

if ($loader -notmatch "delfile=delfile or function\(f\)writefile\(f,''\)end" -and $main -notmatch "writefile\(f,\s*`"`"\s*\)") {
    Pass "Delete fallbacks do not write empty files"
} else {
    Fail "Delete fallback can create repeated empty-file writes"
}

if (
    $loader -match "invalidateStaleGuiCache" -and
    $newMain -match "invalidateStaleGuiCache" -and
    $main -match "isStaleGuiCache" -and
    $loader -match 'V18%.4%-RUNTIME%-STABILITY%-FIX' -and
    $newMain -match 'V18%.4%-RUNTIME%-STABILITY%-FIX'
) {
    Pass "Loadstring rejects stale GUI cache automatically"
} else {
    Fail "Loadstring can reuse stale cached GUI versions"
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

if ($newGui -match "Logs" -or $newGui -match "Console") {
    Pass "Custom console log storage is initialized"
} else {
    Fail "Custom console log storage is missing"
}

if ($newGui -notmatch "\bendak\b" -and $newGui -notmatch "\$[0-9]+") {
    Pass "GUI source has no glued end tokens or replacement artifacts"
} else {
    Fail "GUI source contains a likely syntax artifact"
}

$activeLuaFiles = Get-ChildItem -Path "$Root\badscript" -Recurse -File -Include "*.lua"
$syntaxArtifactMatches = $activeLuaFiles |
    Where-Object { $_.FullName -notmatch '\\(\.git|voidware|v11-module-backup|\.badwars-[^\\]+-backup)\\' } |
    Select-String -Pattern "\bendak\b|\$[0-9]+"
if ($syntaxArtifactMatches) {
    Fail "Active Lua files contain likely pasted syntax artifacts"
    $syntaxArtifactMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "Active Lua files are free of known pasted syntax artifacts"
}

if ($newGui -notmatch "ap\.ScrollingEnabled\s*=" -and $newGui -match "setScrollEnabledIfSupported\(ap") {
    Pass "Settings pane scroll state is guarded by instance type"
} else {
    Fail "Settings pane scroll state can target a non-scrolling Frame"
}

if ($newGui -match "BadWarsV15Motion" -and $newGui -match "addCleanMotion" -and $newGui -match "V15Scale") {
    Pass "V15 guarded motion layer is present"
} else {
    Fail "V15 guarded motion layer is missing"
}

if (
    $newGui -match "badscript/translations/LanguageFlags\.json" -and
    $newGui -match "badscript/translations/Languages\.json" -and
    $newGui -match "badscript/translations/locales/\{ab\}\.json" -and
    $newGui -notmatch "vapevoidware|VapeVoidware" -and
    $languageFlags -match '"en"\s*:\s*"US"' -and
    $languagesIndex -match '"en"'
) {
    Pass "GUI translations use first-party BadWars fallbacks"
} else {
    Fail "GUI translations still depend on legacy external endpoints"
}

if ($newGui -match "BrandLogo" -and $newGui -match "MobileToggleButton" -and $newGui -notmatch "VapeLogo|VapeButton") {
    Pass "Active GUI branding identifiers are BadWars-native"
} else {
    Fail "Active GUI still contains legacy branding identifiers"
}

$legacyRuntimeMatches = $activeLuaFiles |
    Where-Object { $_.FullName -notmatch '\\(\.git|voidware|v11-module-backup|\.badwars-[^\\]+-backup)\\' } |
    Select-String -Pattern "vapevoidware|VapeVoidware|VapeLogo|VapeButton"
if ($legacyRuntimeMatches) {
    Fail "Active Lua runtime contains legacy external branding references"
    $legacyRuntimeMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "Active Lua runtime avoids legacy external branding references"
}

if ($newGui -match "function\s+ab\.CreateOverlayBar\(ar\)" -and $newGui -match "ar\s+and\s+ar\.Hidden" -and $newGui -match "CreateOverlayBar\(\{\s*Hidden\s*=\s*true\s*\}\)") {
    Pass "Overlay manager is internal to avoid duplicate sidebar rows"
} else {
    Fail "Overlay manager can render as a duplicate sidebar row"
}

if ($newGui -match "Replaced duplicate overlay" -and $newGui -match "af\.Overlays\[ag\.Name\]\s*=\s*nil") {
    Pass "Overlay registry replaces duplicate overlay definitions"
} else {
    Fail "Overlay registry lacks duplicate cleanup"
}

if ($newGui -match "local function restoreSettingsRows\(\)" -and $newGui -match "restoreSettingsRows\(\)" -and $newGui -match "TextTransparency\s*=\s*math\.min") {
    Pass "Settings panel restores visible rows when opened"
} else {
    Fail "Settings panel can open with hidden or collapsed rows"
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
