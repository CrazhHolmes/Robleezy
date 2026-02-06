# Setup DuckDNS Auto-Updater for robleezy-ai.duckdns.org
# Creates a scheduled task that updates DuckDNS every 5 minutes

param(
    [switch]$Remove,
    [string]$Token = ""
)

$Subdomain = "robleezy-ai"
$TaskName = "DuckDNS Update - robleezy-ai"
$UpdaterScript = "$env:USERPROFILE\duckdns_updater_robleezy-ai.ps1"

# Remove if requested
if ($Remove) {
    Write-Host "🗑️  Removing scheduled task '$TaskName'..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    if (Test-Path $UpdaterScript) {
        Remove-Item $UpdaterScript -Force
        Write-Host "🗑️  Removed updater script" -ForegroundColor Yellow
    }
    
    Write-Host "✅ DDNS updater removed" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  DuckDNS Auto-Updater Setup" -ForegroundColor White
Write-Host "  Domain: $Subdomain.duckdns.org" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Get token if not provided
if (-not $Token) {
    Write-Host "🔐 Please enter your DuckDNS auth token:" -ForegroundColor Yellow
    Write-Host "   (Get it from https://www.duckdns.org after logging in)" -ForegroundColor Gray
    $secureToken = Read-Host -AsSecureString
    $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
    )
}

if (-not $Token) {
    Write-Host "❌ No token provided. Exiting." -ForegroundColor Red
    exit 1
}

# Test the token first
Write-Host ""
Write-Host "🧪 Testing token with DuckDNS..." -ForegroundColor Cyan
$testUrl = "https://www.duckdns.org/update?domains=$Subdomain&token=$Token&ip="
try {
    $testResponse = Invoke-WebRequest -Uri $testUrl -UseBasicParsing -TimeoutSec 30
    if ($testResponse.Content.Trim() -eq "OK") {
        Write-Host "✅ Token is valid!" -ForegroundColor Green
    } elseif ($testResponse.Content.Trim() -eq "KO") {
        Write-Host "❌ Token is invalid. Please check your token on https://www.duckdns.org" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "⚠️  Unexpected response from DuckDNS. Continuing anyway..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not test token (network error?). Continuing anyway..." -ForegroundColor Yellow
}

# Create the updater script
$scriptContent = @"
# DuckDNS Updater for $Subdomain - Auto-generated
`$Token = "$Token"
`$Subdomain = "$Subdomain"
`$LogFile = "`$env:USERPROFILE\duckdns_`$Subdomain.log"

try {
    `$Url = "https://www.duckdns.org/update?domains=`$Subdomain&token=`$Token&ip="
    `$Response = Invoke-WebRequest -Uri `$Url -UseBasicParsing -TimeoutSec 30
    `$Result = `$Response.Content.Trim()
    `$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    if (`$Result -eq "OK") {
        "[`$Timestamp] ✅ Updated successfully" | Out-File -FilePath `$LogFile -Append
    } else {
        "[`$Timestamp] ❌ Update failed: `$Result" | Out-File -FilePath `$LogFile -Append
    }
} catch {
    `$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[`$Timestamp] ❌ Error: `$_" | Out-File -FilePath `$LogFile -Append
}
"@

Set-Content -Path $UpdaterScript -Value $scriptContent
Write-Host ""
Write-Host "📝 Created updater script: $UpdaterScript" -ForegroundColor Green

# Remove existing task if it exists
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "🔄 Removing existing scheduled task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Create the scheduled task
Write-Host "⏰ Creating scheduled task..." -ForegroundColor Cyan

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$UpdaterScript`""

# Trigger: Run immediately, then every 5 minutes
$Trigger1 = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 9999)

# Also run on startup
$Trigger2 = New-ScheduledTaskTrigger -AtStartup

# Settings
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

# Principal (run as current user with highest privileges)
$Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType S4U -RunLevel Highest

# Register the task
Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger @($Trigger1, $Trigger2) -Settings $Settings -Principal $Principal -Force | Out-Null

# Start the task immediately
Start-ScheduledTask -TaskName $TaskName

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ DuckDNS Auto-Updater Installed!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Task Details:" -ForegroundColor Cyan
Write-Host "  Name:        $TaskName" -ForegroundColor Gray
Write-Host "  Frequency:   Every 5 minutes" -ForegroundColor Gray
Write-Host "  Log file:    $env:USERPROFILE\duckdns_$Subdomain.log" -ForegroundColor Gray
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "  View task:   Get-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Run now:     Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Disable:     Disable-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Gray
Write-Host "  Remove:      .\setup-ddns.ps1 -Remove" -ForegroundColor Gray
Write-Host ""
Write-Host "🌐 Your domain will stay updated:" -ForegroundColor Cyan
Write-Host "   https://$Subdomain.duckdns.org → Your Home IP" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Next steps:" -ForegroundColor Yellow
Write-Host "   1. Setup port forwarding on your router (see ddns-setup.md)" -ForegroundColor Gray
Write-Host "   2. Open Windows firewall port 8080 (run setup-firewall.ps1)" -ForegroundColor Gray
Write-Host "   3. Start the Kimi Proxy service (run install-service.ps1)" -ForegroundColor Gray
