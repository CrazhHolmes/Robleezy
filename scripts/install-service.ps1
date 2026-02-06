# Install Kimi Proxy as a Windows Service using nssm
# This keeps the proxy running even after reboot
# Run as Administrator

param(
    [switch]$Uninstall,
    [string]$PythonPath = "",
    [string]$AppPath = ""
)

$ServiceName = "KimiProxy"
$RepoPath = Split-Path -Parent $PSScriptRoot

# Auto-detect paths if not provided
if (-not $PythonPath) {
    # Try to find Python
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonCmd) {
        $pythonCmd = Get-Command python3 -ErrorAction SilentlyContinue
    }
    if ($pythonCmd) {
        $PythonPath = $pythonCmd.Source
    } else {
        # Check common locations
        $commonPaths = @(
            "C:\Python311\python.exe",
            "C:\Python310\python.exe",
            "C:\Python39\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe",
            "$env:LOCALAPPDATA\Programs\Python\Python310\python.exe"
        )
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                $PythonPath = $path
                break
            }
        }
    }
}

if (-not $AppPath) {
    $AppPath = Join-Path $RepoPath "kimi-proxy\app.py"
}

$AppDirectory = Join-Path $RepoPath "kimi-proxy"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click → Run as Administrator" -ForegroundColor Yellow
    exit 1
}

# Uninstall if requested
if ($Uninstall) {
    Write-Host "🛑 Stopping service $ServiceName..." -ForegroundColor Yellow
    Stop-Service $ServiceName -ErrorAction SilentlyContinue
    
    Write-Host "🗑️  Removing service $ServiceName..." -ForegroundColor Yellow
    $nssm = Get-Command nssm -ErrorAction SilentlyContinue
    if ($nssm) {
        & nssm remove $ServiceName confirm
    } else {
        sc.exe delete $ServiceName
    }
    
    Write-Host "✅ Service removed" -ForegroundColor Green
    exit 0
}

# Check if nssm is installed
$nssmCmd = Get-Command nssm -ErrorAction SilentlyContinue

if (-not $nssmCmd) {
    Write-Host "📦 nssm not found. Installing via Chocolatey..." -ForegroundColor Yellow
    
    # Check if Chocolatey is installed
    $choco = Get-Command choco -ErrorAction SilentlyContinue
    if (-not $choco) {
        Write-Host "🍫 Chocolatey not found. Installing..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    
    # Install nssm
    choco install nssm -y
    
    # Refresh PATH again
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    $nssmCmd = Get-Command nssm -ErrorAction SilentlyContinue
}

if (-not $nssmCmd) {
    Write-Host "❌ Failed to install nssm. Please install manually from https://nssm.cc/" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Installing Kimi Proxy as Windows Service" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "📁 Configuration:" -ForegroundColor Yellow
Write-Host "  Service Name:  $ServiceName" -ForegroundColor Gray
Write-Host "  Python Path:   $PythonPath" -ForegroundColor Gray
Write-Host "  App Path:      $AppPath" -ForegroundColor Gray
Write-Host "  Working Dir:   $AppDirectory" -ForegroundColor Gray
Write-Host ""

# Validate paths
if (-not (Test-Path $PythonPath)) {
    Write-Host "❌ Python not found at: $PythonPath" -ForegroundColor Red
    $customPath = Read-Host "Enter full path to python.exe"
    if (Test-Path $customPath) {
        $PythonPath = $customPath
    } else {
        exit 1
    }
}

if (-not (Test-Path $AppPath)) {
    Write-Host "❌ app.py not found at: $AppPath" -ForegroundColor Red
    exit 1
}

# Check if service already exists
$existingService = Get-Service $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "⚠️  Service '$ServiceName' already exists" -ForegroundColor Yellow
    $response = Read-Host "   Remove and reinstall? (y/N)"
    if ($response -eq 'y') {
        Stop-Service $ServiceName -ErrorAction SilentlyContinue
        & nssm remove $ServiceName confirm
    } else {
        Write-Host "   Keeping existing service. Exiting." -ForegroundColor Gray
        exit 0
    }
}

Write-Host "🔧 Installing service..." -ForegroundColor Cyan

# Install the service
& nssm install $ServiceName $PythonPath $AppPath
& nssm set $ServiceName DisplayName "Kimi AI Proxy for Robleezy"
& nssm set $ServiceName Description "Secure Flask proxy for Kimi AI integration with Roblox"
& nssm set $ServiceName AppDirectory $AppDirectory
& nssm set $ServiceName Start SERVICE_AUTO_START
& nssm set $ServiceName AppStdout "$AppDirectory\logs\service.log"
& nssm set $ServiceName AppStderr "$AppDirectory\logs\service-error.log"
& nssm set $ServiceName AppRotateFiles 1
& nssm set $ServiceName AppRotateBytes 1048576

# Create logs directory
$logsDir = Join-Path $AppDirectory "logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

# Start the service
Write-Host "🚀 Starting service..." -ForegroundColor Cyan
Start-Service $ServiceName

Start-Sleep -Seconds 2

# Check status
$service = Get-Service $ServiceName
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  Service Status: $($service.Status)" -ForegroundColor $(if($service.Status -eq 'Running'){'Green'}else{'Red'})
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Cyan
Write-Host "  Check status:  Get-Service $ServiceName" -ForegroundColor Gray
Write-Host "  Stop:          Stop-Service $ServiceName" -ForegroundColor Gray
Write-Host "  Start:         Start-Service $ServiceName" -ForegroundColor Gray
Write-Host "  Restart:       Restart-Service $ServiceName" -ForegroundColor Gray
Write-Host "  View logs:     notepad '$AppDirectory\logs\service.log'" -ForegroundColor Gray
Write-Host "  Remove:        .\install-service.ps1 -Uninstall" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Your proxy should now be accessible at:" -ForegroundColor Cyan
Write-Host "   https://robleezy-ai.duckdns.org:8080/ask" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Remember to:" -ForegroundColor Yellow
Write-Host "   1. Set up DuckDNS updater (run setup-ddns.ps1)" -ForegroundColor Gray
Write-Host "   2. Configure your .env file with KIMI_API_KEY and SHARED_SECRET" -ForegroundColor Gray
Write-Host "   3. Open port 8080 on your router (see ddns-setup.md)" -ForegroundColor Gray
