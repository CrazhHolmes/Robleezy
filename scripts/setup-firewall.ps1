# Setup Windows Firewall for Kimi Proxy on port 8080
# Run as Administrator

param(
    [switch]$Remove
)

$RuleName = "Kimi Proxy 8080"
$Port = 8080

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "[X] This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "   Right-click -> Run as Administrator" -ForegroundColor Yellow
    exit 1
}

if ($Remove) {
    Write-Host "Removing firewall rule '$RuleName'..." -ForegroundColor Yellow
    Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
    Write-Host "[OK] Rule removed (if it existed)" -ForegroundColor Green
    exit 0
}

# Check if rule already exists
$existingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

if ($existingRule) {
    Write-Host "Firewall rule '$RuleName' already exists" -ForegroundColor Cyan
    
    # Show current settings
    $portFilter = Get-NetFirewallPortFilter -AssociatedNetFirewallRule $existingRule
    Write-Host "   Current port: $($portFilter.LocalPort)" -ForegroundColor Gray
    
    $response = Read-Host "   Update it? (y/N)"
    if ($response -ne 'y') {
        Write-Host "   Keeping existing rule. Exiting." -ForegroundColor Gray
        exit 0
    }
    
    Remove-NetFirewallRule -DisplayName $RuleName
}

Write-Host "Creating firewall rule for port $Port..." -ForegroundColor Cyan

# Create the inbound rule
New-NetFirewallRule `
    -DisplayName $RuleName `
    -Description "Allow inbound connections to Kimi AI Proxy on port 8080" `
    -Direction Inbound `
    -LocalPort $Port `
    -Protocol TCP `
    -Action Allow `
    -Profile Domain,Private `
    -Enabled True

Write-Host ""
Write-Host "[OK] Firewall rule created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Rule Details:" -ForegroundColor Cyan
Write-Host "  Name:    $RuleName" -ForegroundColor Gray
Write-Host "  Port:    $Port/tcp" -ForegroundColor Gray
Write-Host "  Action:  Allow" -ForegroundColor Gray
Write-Host "  Profile: Domain, Private" -ForegroundColor Gray
