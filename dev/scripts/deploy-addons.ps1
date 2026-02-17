# TipTac Addon Deployment Script
# This script copies TipTac addons to your World of Warcraft addons folder

# Get the source directory (repository root)
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$SourceRoot = Split-Path -Parent $ScriptRoot

# Path to store the saved WoW path
$ConfigFile = Join-Path $PSScriptRoot "wow-path.txt"

# List of addons to deploy
$Addons = @(
    "TipTac",
    "TipTacItemRef",
    "TipTacOptions",
    "TipTacTalents"
)

Write-Host "TipTac Addon Deployment" -ForegroundColor Cyan
Write-Host "=======================" -ForegroundColor Cyan
Write-Host ""

# Function to find WoW AddOns folder
function Find-WoWAddonsPath {
    # Check if we have a saved path
    if (Test-Path $ConfigFile) {
        $SavedPath = Get-Content $ConfigFile -Raw
        $SavedPath = $SavedPath.Trim()
        if (Test-Path $SavedPath) {
            return $SavedPath
        }
    }
    
    # Common installation paths to check
    $CommonPaths = @(
        "${env:ProgramFiles(x86)}\World of Warcraft\_retail_\Interface\AddOns",
        "${env:ProgramFiles(x86)}\World of Warcraft\_classic_\Interface\AddOns",
        "${env:ProgramFiles(x86)}\World of Warcraft\_anniversary_\Interface\AddOns",
        "${env:ProgramFiles(x86)}\World of Warcraft\_classic_era_\Interface\AddOns",
        "$env:USERPROFILE\_World_of_Warcraft\_retail_\Interface\AddOns",
        "$env:USERPROFILE\_World_of_Warcraft\_classic_\Interface\AddOns",
        "$env:USERPROFILE\_World_of_Warcraft\_anniversary_\Interface\AddOns",
        "$env:USERPROFILE\_World_of_Warcraft\_classic_era_\Interface\AddOns"
    )
    
    # Try to find an existing path
    foreach ($Path in $CommonPaths) {
        if (Test-Path $Path) {
            Write-Host "Found WoW AddOns folder: $Path" -ForegroundColor Green
            $Response = Read-Host "Use this path? (Y/n)"
            if ($Response -eq "" -or $Response -match "^[Yy]") {
                # Save the path for next time
                Set-Content -Path $ConfigFile -Value $Path
                return $Path
            }
        }
    }
    
    # Ask user to provide the path
    Write-Host "Please enter the path to your WoW AddOns folder" -ForegroundColor Yellow
    Write-Host "Example: C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns" -ForegroundColor Gray
    $UserPath = Read-Host "Path"
    
    if (-not (Test-Path $UserPath)) {
        Write-Host "ERROR: Path not found: $UserPath" -ForegroundColor Red
        exit 1
    }
    
    # Save the path for next time
    Set-Content -Path $ConfigFile -Value $UserPath
    return $UserPath
}

# Get the WoW AddOns path
$WoWAddonsPath = Find-WoWAddonsPath

Write-Host ""
Write-Host "Source: $SourceRoot" -ForegroundColor Yellow
Write-Host "Target: $WoWAddonsPath" -ForegroundColor Yellow
Write-Host ""

# Deploy each addon
foreach ($Addon in $Addons) {
    Write-Host "Deploying $Addon..." -ForegroundColor Green
    
    $SourcePath = Join-Path $SourceRoot $Addon
    $DestPath = Join-Path $WoWAddonsPath $Addon
    
    # Check if source exists
    if (-not (Test-Path $SourcePath)) {
        Write-Host "  WARNING: Source folder not found: $SourcePath" -ForegroundColor Yellow
        continue
    }
    
    # Delete old version if it exists
    if (Test-Path $DestPath) {
        Write-Host "  Removing old version..." -ForegroundColor Gray
        Remove-Item -Path $DestPath -Recurse -Force
    }
    
    # Copy new version
    Write-Host "  Copying files..." -ForegroundColor Gray
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
    
    Write-Host "  ✓ $Addon deployed successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "Deployment complete!" -ForegroundColor Cyan
Write-Host ""
