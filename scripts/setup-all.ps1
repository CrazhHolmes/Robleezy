# Master Setup Script for Kimi Proxy on robleezy-ai.duckdns.org
# Run this as Administrator to set up everything automatically

param(
    [switch]$SkipFirewall,
    [switch]$SkipDDNS,
    [switch]$SkipService
)

$ErrorActionPreference = "Stop"

# Colors
$Cyan = "Cyan"
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Gray = "Gray"

function Write-Header($text) {
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor $Cyan
    Write-Host "  $text" -ForegroundColor White
    Write-Host "===========================================================" -ForegroundColor $Cyan
    Write-Host ""
}

function Write-Success($text) {
    Write-Host "[OK] $text" -ForegroundColor $Green
}

function Write-Warning($text) {
    Write-Host "[!] $text" -ForegroundColor $Yellow
}

function Write-Error($text) {
    Write-Host "[X] $text" -ForegroundColor $Red
}

function Write-Info($text) {
    Write-Host "[i] $text" -ForegroundColor $Gray
}

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Error "This script must be run as Administrator!"
    Write-Info "Right-click PowerShell -> Run as Administrator"
    exit 1
}

$RepoPath = Split-Path -Parent $PSScriptRoot

Write-Header "Kimi Proxy Setup for robleezy-ai.duckdns.org"

Write-Host "This script will set up your self-hosted Kimi AI proxy." -ForegroundColor White
Write-Host ""
Write-Host "Requirements:" -ForegroundColor Yellow
Write-Host "  - DuckDNS account with subdomain 'robleezy-ai'" -ForegroundColor $Gray
Write-Host "  - DuckDNS auth token (from https://www.duckdns.org)" -ForegroundColor $Gray
Write-Host "  - Kimi API key (from https://platform.moonshot.cn)" -ForegroundColor $Gray
Write-Host "  - Python 3.9+ installed" -ForegroundColor $Gray
Write-Host ""

$response = Read-Host "Continue? (Y/n)"
if ($response -eq 'n') {
    exit 0
}

# Step 1: Check Python
Write-Header "Step 1: Checking Python Installation"

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
}

if (-not $pythonCmd) {
    Write-Error "Python not found!"
    Write-Info "Please install Python from https://python.org"
    Write-Info "Make sure to check 'Add Python to PATH' during installation"
    exit 1
}

$pythonVersion = & $pythonCmd.Source --version
Write-Success "Found $pythonVersion at $($pythonCmd.Source)"

# Step 2: Install Python dependencies
Write-Header "Step 2: Installing Python Dependencies"

$requirementsPath = Join-Path $RepoPath "kimi-proxy\requirements.txt"
if (Test-Path $requirementsPath) {
    Write-Info "Installing from $requirementsPath..."
    & $pythonCmd.Source -m pip install -r $requirementsPath
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Dependencies installed"
    } else {
        Write-Warning "Some dependencies may have failed to install"
    }
} else {
    Write-Info "Installing flask and requests directly..."
    & $pythonCmd.Source -m pip install flask requests
    Write-Success "Dependencies installed"
}

# Step 3: Setup Environment File
Write-Header "Step 3: Environment Configuration"

$envPath = Join-Path $RepoPath "kimi-proxy\.env"

if (-not (Test-Path $envPath)) {
    Write-Info "Creating .env file..."
    
    Write-Host ""
    Write-Host "Enter your Kimi API Key (from https://platform.moonshot.cn):" -ForegroundColor Yellow
    $kimiKeySecure = Read-Host -AsSecureString
    $kimiKey = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($kimiKeySecure)
    )
    
    Write-Host ""
    Write-Host "Enter your Shared Secret (or press Enter for default):" -ForegroundColor Yellow
    Write-Host "   This is used to authenticate Roblox requests to your proxy" -ForegroundColor $Gray
    $secretSecure = Read-Host -AsSecureString
    $secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretSecure)
    )
    
    if (-not $secret) {
        $secret = "super-secret-string-42"
        Write-Info "Using default shared secret"
    }
    
    $envContent = "KIMI_API_KEY=$kimiKey`nSHARED_SECRET=$secret"
    
    Set-Content -Path $envPath -Value $envContent
    Write-Success "Created .env file at $envPath"
} else {
    Write-Info ".env file already exists"
    Write-Info "Edit $envPath to update your configuration"
}

# Step 4: Setup DuckDNS
if (-not $SkipDDNS) {
    Write-Header "Step 4: DuckDNS Auto-Updater Setup"
    
    Write-Host "This will create a scheduled task to update DuckDNS every 5 minutes." -ForegroundColor White
    Write-Host ""
    
    $ddnsResponse = Read-Host "Setup DuckDNS auto-updater? (Y/n)"
    if ($ddnsResponse -ne 'n') {
        & "$PSScriptRoot\setup-ddns.ps1"
    } else {
        Write-Info "Skipped DuckDNS setup"
    }
} else {
    Write-Info "Skipped DuckDNS setup (flag set)"
}

# Step 5: Setup Firewall
if (-not $SkipFirewall) {
    Write-Header "Step 5: Windows Firewall Setup"
    
    Write-Host "This will open port 8080 in Windows Firewall." -ForegroundColor White
    Write-Host ""
    
    $fwResponse = Read-Host "Open firewall port 8080? (Y/n)"
    if ($fwResponse -ne 'n') {
        & "$PSScriptRoot\setup-firewall.ps1"
    } else {
        Write-Info "Skipped firewall setup"
    }
} else {
    Write-Info "Skipped firewall setup (flag set)"
}

# Step 6: Install Service
if (-not $SkipService) {
    Write-Header "Step 6: Install Windows Service"
    
    Write-Host "This will install Kimi Proxy as a Windows service." -ForegroundColor White
    Write-Host "The service will start automatically on boot." -ForegroundColor White
    Write-Host ""
    
    $svcResponse = Read-Host "Install Windows service? (Y/n)"
    if ($svcResponse -ne 'n') {
        & "$PSScriptRoot\install-service.ps1"
    } else {
        Write-Info "Skipped service installation"
        Write-Info "You can run the proxy manually:"
        Write-Info "  cd $RepoPath\kimi-proxy"
        Write-Info "  python app.py"
    }
} else {
    Write-Info "Skipped service installation (flag set)"
}

# Summary
Write-Header "Setup Complete!"

Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Domain:     https://robleezy-ai.duckdns.org:8080" -ForegroundColor $Gray
Write-Host "  Repo Path:  $RepoPath" -ForegroundColor $Gray
Write-Host ""

Write-Host "Testing Checklist:" -ForegroundColor Yellow
Write-Host "  [ ] Port forwarded on router (manual step - see ddns-setup.md)" -ForegroundColor $Gray
Write-Host "  [ ] DuckDNS updater running (check with: .\duckdns-updater.ps1 -ShowStatus)" -ForegroundColor $Gray
Write-Host "  [ ] Firewall port 8080 open" -ForegroundColor $Gray
Write-Host "  [ ] Windows service running (check with: Get-Service KimiProxy)" -ForegroundColor $Gray
Write-Host ""

Write-Host "Test Commands:" -ForegroundColor Cyan
Write-Host "  Check DuckDNS:  .\duckdns-updater.ps1 -ShowStatus" -ForegroundColor $Gray
Write-Host "  Test proxy:     curl https://robleezy-ai.duckdns.org:8080/ping -H 'X-Secret: YOUR_SECRET'" -ForegroundColor $Gray
Write-Host "  View logs:      notepad '$RepoPath\kimi-proxy\logs\service.log'" -ForegroundColor $Gray
Write-Host ""

Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "  Full setup guide: $RepoPath\ddns-setup.md" -ForegroundColor $Gray
Write-Host "  This README:      $PSScriptRoot\SETUP-README.md" -ForegroundColor $Gray
Write-Host ""

Write-Warning "Don't forget to forward port 8080 on your router!"
Write-Info "See ddns-setup.md for router-specific instructions."
