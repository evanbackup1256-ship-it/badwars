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
Assert-Match $library 'local builtInLucide\s*=' `
    "Built-in Lucide fallback assets are present"
Assert-Match $library 'function r\.SafeIcon' `
    "SafeIcon public fallback is present"
Assert-Match $library 'local iconPack = d\.Icons\[e\]' `
    "AddIcons normalizes existing icon-pack formats"
Assert-Match $library 'image = p\.Spritesheets\[tostring\(iconData\.Image\)\] or image' `
    "Icon lookup falls back when a spritesheet entry is missing"

if ($script:Failed) {
    Write-Host ""
    Write-Host "WindUI validation failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "WindUI validation passed." -ForegroundColor Green