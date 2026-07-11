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
Assert-Match $adapter 'Version\s*=\s*"WindUI-Adapter-2\.1"' `
    "WindUI adapter version is current"
Assert-Match $adapter 'Name\s*=\s*"BadWars-WindUI"' `
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

Assert-Match $adapter 'BADWARS_RUNTIME_COMPAT_V28' `
    "Runtime compatibility libraries are installed"
Assert-Match $adapter 'd\.Libraries\.getcustomasset\s*=\s*compatGetCustomAsset' `
    "getcustomasset compatibility is exported"
Assert-Match $adapter 'd\.Libraries\.getfontsize\s*=\s*compatGetFontSize' `
    "getfontsize compatibility is exported"
Assert-Match $adapter 'd\.Libraries\.tween\s*=\s*compatTween' `
    "tween compatibility is exported"
Assert-Match $adapter 'BADWARS_OVERLAY_RUNTIME_V2' `
    "Legacy overlay runtime is installed"
Assert-Match $adapter 'overlay\.Children\s*=\s*root' `
    "Overlay Children container is present"
Assert-Match $adapter 'overlay\.Button\s*=\s*overlay' `
    "Overlay Button compatibility object is present"
Assert-Match $adapter 'BADWARS_TARGETS_COMPAT_V2' `
    "Targets wrappers expose Enabled state"
Assert-Match $adapter 'BADWARS_FONT_COMPAT_V2' `
    "Font controls return Font values"
Assert-Match $adapter 'BADWARS_TEXTLIST_LISTENABLED_V1' `
    "TextList ListEnabled compatibility is present"
Assert-Match $adapter 'BADWARS_SHORT_MODULE_ALIASES_V1' `
    "Short module aliases are restored"
Assert-Match $adapter 'BADWARS_MOTION_SETTINGS_V1' `
    "Motion settings controls are present"
Assert-NoMatch $adapter '\bendreturn\b' `
    "Joined Luau keywords are absent"
Assert-Match $adapter 'BADWARS_CINEMATIC_MOTION_V4' `
    "Cinematic motion engine is installed"
Assert-Match $adapter 'local function applyProximityField' `
    "Neighboring rows react through real layout reflow"
Assert-Match $adapter 'local function createKineticGlow' `
    "Cursor-following kinetic light is present"
Assert-Match $adapter 'local function createEchoRing' `
    "Double click echo rings are present"
Assert-Match $adapter 'local function morphCorner' `
    "Corner-radius morphing is present"
Assert-Match $adapter 'local function cascadeContainer' `
    "Staggered tab and section choreography is present"
Assert-Match $adapter 'stroke\.Parent\s*=\s*surface' `
    "Animated borders use the real rounded surface"
Assert-Match $adapter 'layer\.ClipsDescendants\s*=\s*true' `
    "All cinematic effects remain clipped"
Assert-Match $adapter 'RunService\.RenderStepped:Connect' `
    "Kinetic light uses frame-smoothed pointer tracking"
Assert-Match $adapter 'Title\s*=\s*"Cinematic Cursor Light"' `
    "Cinematic cursor light can be configured"
Assert-Match $adapter 'Title\s*=\s*"Morphing Corners"' `
    "Corner morphing can be configured"
Assert-Match $adapter 'Title\s*=\s*"Choreographed Reveals"' `
    "Reveal choreography can be configured"
Assert-Match $adapter 'Title\s*=\s*"Proximity Reflow"' `
    "Proximity reflow can be configured"
Assert-NoMatch $adapter 'baseRotation\s*=' `
    "Button motion does not rotate controls"
Assert-NoMatch $adapter 'Rotation\s*=\s*tilt' `
    "Overlay dragging does not apply tilt"
Assert-NoMatch $adapter '\bendreturn\b' `
    "Joined Luau keywords are absent"
if ($script:Failed) {
    Write-Host ""
    Write-Host "WindUI validation failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "WindUI validation passed." -ForegroundColor Green