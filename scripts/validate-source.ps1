param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$script:Failed = $false
$script:Warned = $false

function Fail($message) {
    Write-Host "[FAIL] $message" -ForegroundColor Red
    $script:Failed = $true
}

function Warn($message) {
    Write-Host "[WARN] $message" -ForegroundColor Yellow
    $script:Warned = $true
}

function Pass($message) {
    Write-Host "[ OK ] $message" -ForegroundColor Green
}

function Read-Text($relativePath) {
    $path = Join-Path $Root $relativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing file: $relativePath"
        return ""
    }
    return Get-Content -LiteralPath $path -Raw
}

function Get-ActiveLuaFiles {
    Get-ChildItem -LiteralPath (Join-Path $Root "badscript") -Recurse -File -Include "*.lua" |
        Where-Object {
            $_.Extension -eq ".lua" -and
            $_.Name -notlike "*.bak" -and
            $_.FullName -notmatch '\\(\.git|voidware|v11-module-backup|\.badwars-[^\\]+-backup)\\' -and
            $_.FullName -notmatch '\\badscript\\guis\\(old|rise|wurst|liquidbounce)\\'
        }
}

$gui = Read-Text "badscript\guis\new\gui.lua"
$loader = Read-Text "badscript\loader.lua"
$main = Read-Text "badscript\main.lua"
$diagnostics = Read-Text "badscript\libraries\diagnostics.lua"
$packageJson = Read-Text "package.json"
$gitignore = Read-Text ".gitignore"
$activeLuaFiles = @(Get-ActiveLuaFiles)

$legacyMatches = $activeLuaFiles | Select-String -Pattern "vapevoidware|VapeVoidware|configs\.vape|public-config|VapeLogo|VapeButton"
if ($legacyMatches) {
    Fail "Active Lua contains legacy public-config or old branding references"
    $legacyMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "Active Lua avoids legacy public-config and old branding references"
}

$mojibakePatterns = @('\u00C3', '\u00C2', '\u00E2\u20AC\u2122', '\u00E2\u20AC\u0153', '\u00E2\u20AC\u009D', '\uFFFD')
$mojibakeMatches = $activeLuaFiles | Select-String -Pattern $mojibakePatterns
if ($mojibakeMatches) {
    Fail "Active Lua contains likely mojibake text"
    $mojibakeMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "Active Lua has no known mojibake markers"
}

$patchArtifactMatches = $activeLuaFiles | Select-String -Pattern '\bendak\b|\$[0-9]+|^(<<<<<<<|=======|>>>>>>>)'
if ($patchArtifactMatches) {
    Fail "Active Lua contains pasted patch or conflict artifacts"
    $patchArtifactMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "Active Lua has no known pasted patch artifacts"
}

$guiLines = ($gui -split "`r?`n").Count
$guiTopLevelLocals = ([regex]::Matches($gui, "(?m)^\s*local\s+(function\s+)?[A-Za-z_]")).Count
if ($guiLines -gt 12000 -or $guiTopLevelLocals -gt 250) {
    Warn ("Active GUI remains oversized: " + $guiLines + " lines, " + $guiTopLevelLocals + " top-level-looking local declarations; continue extracting systems before major feature work")
} else {
    Pass "Active GUI source size is within the current register-risk budget"
}

$visibleOverlayCalls = ([regex]::Matches($gui, "CreateOverlayBar\(\s*\)")).Count
$hiddenOverlayCalls = ([regex]::Matches($gui, "CreateOverlayBar\(\{\s*Hidden\s*=\s*true\s*\}\)")).Count
if ($hiddenOverlayCalls -eq 1 -and $visibleOverlayCalls -eq 0) {
    Pass "Exactly one internal overlay controller is created"
} else {
    Fail "Overlay controller registration is ambiguous (hidden=$hiddenOverlayCalls visible=$visibleOverlayCalls)"
}

$messageOutConnections = ([regex]::Matches($diagnostics, "MessageOut:Connect")).Count
if ($messageOutConnections -le 1) {
    Pass "Diagnostics owns a single LogService.MessageOut hook site"
} else {
    Fail "Diagnostics has duplicate LogService.MessageOut hook sites"
}

if ($loader -match "raw\.githubusercontent\.com/evanbackup1256-ship-it/badwars/main/badscript/profiles/roblox-version\.txt" -and $loader -notmatch "api\.github\.com/repos/.+/raw") {
    Pass "Loader update watch uses raw GitHub content URL"
} else {
    Fail "Loader update watch URL can still 404"
}

if ($loader -match "shared\.__badwars_update_watch\s*=\s*token" -and $loader -match "while shared\.__badwars_update_watch==token do") {
    Pass "Loader update watcher is single-owner across reinjection"
} else {
    Fail "Loader update watcher can duplicate across reinjection"
}

if ($loader -notmatch 'writefile\(f,''\)' -and $main -notmatch 'writefile\(f,\s*""\s*\)') {
    Pass "Delete fallbacks avoid empty-file write spam"
} else {
    Fail "Delete fallback still writes empty files"
}

if ($main -match "ERROR empty file" -and $main -match "isNotFoundBody" -and $loader -match "ERROR empty file" -and $loader -match "isNotFoundBody") {
    Pass "Empty/HTML source rejection is present in active loader pipeline"
} else {
    Fail "Source rejection checks are incomplete in loader/main"
}

if ($main -match "failed\s*=\s*attemptErrors") {
    Pass "Universal failure summary includes attempt errors"
} else {
    Fail "Universal failure summary can hide attempt errors"
}

if ($packageJson -match '"lint"\s*:\s*"eslint \. --max-warnings=0"') {
    Pass "Lint script is non-interactive"
} else {
    Fail "Lint script is interactive or missing"
}

if ($packageJson -match '"validate"' -and $packageJson -match "npm run build") {
    Pass "Package validation includes website build"
} else {
    Fail "Package validation does not include the full website build"
}

if ($gitignore -match "(?m)^\.badwars-\*/\r?$" -and $gitignore -match "v11-module-backup") {
    Pass "Backup directories are ignored by policy"
} else {
    Fail "Backup directory ignore policy is incomplete"
}

$secretFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -Include "*.ts","*.tsx","*.mjs","*.js","*.json","*.lua","*.ps1","*.md","*.yml","*.yaml" |
    Where-Object { $_.FullName -notmatch '\\(node_modules|\.git|\.next|tmp|voidware|v11-module-backup|\.badwars-[^\\]+-backup)\\' -and $_.Name -notmatch 'package-lock\.json' }
$secretPatterns = @('sk-[A-Za-z0-9_-]{20,}', 'ghp_[A-Za-z0-9]{20,}', 'github_pat_[A-Za-z0-9_]{20,}', 'xox[baprs]-[A-Za-z0-9-]{20,}')
$secretMatches = $secretFiles | Select-String -Pattern $secretPatterns
if ($secretMatches) {
    Fail "Potential secrets found in tracked text sources"
    $secretMatches | ForEach-Object { Write-Host "       $($_.Path):$($_.LineNumber)" -ForegroundColor DarkYellow }
} else {
    Pass "No common secret token patterns found"
}

$trackedBackupStatus = git -C $Root status --short --ignored=no 2>$null | Select-String -Pattern "^\s*[AMDRC?]{1,2}\s+(\.badwars-|tmp/|tmp\\)"
if ($trackedBackupStatus) {
    Fail "Backup/cache directory is staged or untracked outside ignored policy"
    $trackedBackupStatus | ForEach-Object { Write-Host "       $($_.Line)" -ForegroundColor DarkYellow }
} else {
    Pass "No backup/cache directory is staged by git status"
}

if ($script:Failed) {
    exit 1
}

if ($script:Warned) {
    Write-Host "Source validation completed with warnings." -ForegroundColor Yellow
} else {
    Write-Host "Source validation completed." -ForegroundColor Cyan
}
