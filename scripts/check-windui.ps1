param(
    [string]$Root = (Resolve-Path "$PSScriptRoot\..").Path
)

$ErrorActionPreference = "Stop"
$script:Failed = $false

function Fail([string]$Message) {
    Write-Host "[FAIL] $Message" -ForegroundColor Red
    $script:Failed = $true
}

function Pass([string]$Message) {
    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Read-ProjectFile([string]$RelativePath) {
    $path = Join-Path $Root $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        Fail "Missing required file: $RelativePath"
        return ""
    }

    return Get-Content -LiteralPath $path -Raw
}

function Assert-Match(
    [string]$Content,
    [string]$Pattern,
    [string]$Message
) {
    if ($Content -match $Pattern) {
        Pass $Message
    } else {
        Fail $Message
    }
}

function Assert-NoMatch(
    [string]$Content,
    [string]$Pattern,
    [string]$Message
) {
    if ($Content -notmatch $Pattern) {
        Pass $Message
    } else {
        Fail $Message
    }
}

$adapter = Read-ProjectFile "badscript\guis\windui\gui.lua"
$library = Read-ProjectFile "badscript\guis\windui\WindUI.lua"

Assert-Match $adapter 'BADWARS_WINDUI_INTEGRATION' `
    "WindUI adapter integration marker is present"
Assert-Match $adapter 'Version\s*=\s*"WindUI-Adapter-3\.0"' `
    "WindUI adapter version is current"
Assert-Match $adapter 'Name\s*=\s*"BadWars-WindUI-V3"' `
    "WindUI adapter identity is present"

$requiredApis = @(
    "CreateButton",
    "CreateToggle",
    "CreateSlider",
    "CreateDropdown",
    "CreateTextBox",
    "CreateTextList",
    "CreateColorSlider",
    "CreateFont",
    "CreateTwoSlider"
)

foreach ($api in $requiredApis) {
    Assert-Match $adapter ([regex]::Escape($api)) "WindUI compatibility API is present: $api"
}

Assert-Match $library 'FindFirstChild\("GetIcons"\)' `
    "GetIcons lookup is non-blocking"
Assert-NoMatch $library 'WaitForChild\("GetIcons"' `
    "GetIcons cannot cause a long startup wait"
Assert-Match $library 'BADWARS_WINDUI_VISIBLE_ICONS_V2' `
    "Visible icon repair marker is present"
Assert-Match $library 'local DEFAULT_ICON_TYPE = "lucide"' `
    "Lucide is the default icon pack"
Assert-Match $library 'local function normalizeImageAsset' `
    "Icon values are normalized to Roblox asset strings"
Assert-Match $library 'local builtInLucide\s*=' `
    "Built-in Lucide fallback assets are present"
Assert-Match $library 'function r\.SafeIcon' `
    "SafeIcon public fallback is present"
Assert-Match $library 'local iconPack = d\.Icons\[e\]' `
    "AddIcons normalizes existing icon-pack formats"
Assert-Match $library 'local image = mappedImage or directImage' `
    "Structured icon aliases resolve only to valid assets"
Assert-NoMatch $library 'p\.Spritesheets\[tostring\(iconData\.Image\)\]\s+or\s+image' `
    "Unresolved aliases are never returned as image assets"

$requiredIcons = @(
    "swords",
    "badge-check",
    "home",
    "list",
    "flame",
    "sword",
    "eye",
    "wrench",
    "globe",
    "gamepad-2",
    "user-check",
    "users",
    "crosshair",
    "bell",
    "settings",
    "folder"
)

foreach ($iconName in $requiredIcons) {
    $escapedName = [regex]::Escape($iconName)
    Assert-Match $library ('(?:\["' + $escapedName + '"\]|' + $escapedName + ')\s*=\s*"rbxassetid://\d+"') `
        "Required WindUI icon is bundled: $iconName"
}

Assert-Match $adapter 'BADWARS_VISUAL_REVAMP_V5' `
    "Big visual revamp marker is present"
Assert-Match $library 'BADWARS_VISUAL_METRICS_V5' `
    "WindUI visual metrics are installed"
Assert-Match $adapter 'SideBarWidth\s*=\s*232' `
    "Desktop sidebar width is configured"
Assert-Match $adapter 'ElementsRadius\s*=\s*12' `
    "Consistent element corner radius is configured"
Assert-Match $adapter 'BoxBorder\s*=\s*settings\.BoxBorder\s*~=\s*false' `
    "Module cards use bordered surfaces"
Assert-Match $adapter 'createAccentRail' `
    "Branded accent rail is installed"
Assert-Match $adapter 'createSidebarDivider' `
    "Sidebar and content hierarchy are separated"
Assert-Match $adapter 'ScrollBarThickness\s*=\s*3' `
    "Slim visible scrollbars are installed"
Assert-NoMatch $adapter 'BADWARS_(?:EXTREME|CINEMATIC|SMART_LAYOUT|MOTION_STABILITY|SAFE_VISUAL)_MOTION' `
    "Custom motion engines remain absent"
Assert-NoMatch $adapter 'RunService\.RenderStepped:Connect' `
    "Visual revamp does not add a per-frame loop"
Assert-NoMatch $adapter '\bendreturn\b' `
    "Joined Luau keywords are absent"
if ($script:Failed) {
    Write-Host ""
    Write-Host "WindUI validation failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "WindUI validation passed." -ForegroundColor Green