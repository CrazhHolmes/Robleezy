# DuckDNS Updater for robleezy-ai.duckdns.org
# This script updates DuckDNS with your current public IP
# It will prompt for your auth token on first run and save it securely

param(
    [string]$Token = "",
    [switch]$ShowStatus
)

$Subdomain = "robleezy-ai"
$TokenFile = "$env:USERPROFILE\.duckdns_token_robleezy"

# Function to save token securely (encrypted)
function Save-Token($token) {
    $secureToken = ConvertTo-SecureString $token -AsPlainText -Force
    $encryptedToken = ConvertFrom-SecureString $secureToken
    Set-Content -Path $TokenFile -Value $encryptedToken
    Write-Host "✅ Token saved securely to $TokenFile" -ForegroundColor Green
}

# Function to load token
function Load-Token() {
    if (Test-Path $TokenFile) {
        $encryptedToken = Get-Content $TokenFile
        $secureToken = ConvertTo-SecureString $encryptedToken
        $token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
        )
        return $token
    }
    return $null
}

# Check if token is provided or saved
if (-not $Token) {
    $savedToken = Load-Token
    if ($savedToken) {
        $Token = $savedToken
    } else {
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  DuckDNS Auth Token Required for robleezy-ai.duckdns.org" -ForegroundColor Yellow
        Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Please enter your DuckDNS auth token (from https://www.duckdns.org):" -ForegroundColor White
        $secureInput = Read-Host -AsSecureString
        $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureInput)
        )
        
        if ($Token) {
            Save-Token $Token
        } else {
            Write-Host "❌ No token provided. Exiting." -ForegroundColor Red
            exit 1
        }
    }
}

# Show status only
if ($ShowStatus) {
    Write-Host "📊 DuckDNS Status for $Subdomain.duckdns.org" -ForegroundColor Cyan
    Write-Host "─────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # Get current public IP
    try {
        $publicIP = Invoke-RestMethod -Uri "https://checkip.amazonaws.com/" -UseBasicParsing -TimeoutSec 10
        $publicIP = $publicIP.Trim()
        Write-Host "🌐 Your Public IP:    $publicIP" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to get public IP" -ForegroundColor Red
    }
    
    # Check DNS resolution
    try {
        $resolvedIP = [System.Net.Dns]::GetHostAddresses("$Subdomain.duckdns.org") | 
                      Where-Object { $_.AddressFamily -eq 'InterNetwork' } | 
                      Select-Object -First 1
        if ($resolvedIP) {
            Write-Host "📡 DNS resolves to:   $($resolvedIP.IPAddressToString)" -ForegroundColor Green
        }
    } catch {
        Write-Host "📡 DNS not resolving: Domain may not be set up yet" -ForegroundColor Yellow
    }
    
    # Check if token is saved
    if (Test-Path $TokenFile) {
        Write-Host "🔐 Token status:      Saved securely" -ForegroundColor Green
    } else {
        Write-Host "🔐 Token status:      Not saved (will prompt on next run)" -ForegroundColor Yellow
    }
    
    exit 0
}

# Update DuckDNS
$UpdateUrl = "https://www.duckdns.org/update?domains=$Subdomain&token=$Token&ip="

try {
    $response = Invoke-WebRequest -Uri $UpdateUrl -UseBasicParsing -TimeoutSec 30
    $result = $response.Content.Trim()
    
    if ($result -eq "OK") {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp] ✅ DuckDNS updated successfully" -ForegroundColor Green
    } elseif ($result -eq "KO") {
        Write-Host "❌ DuckDNS update failed (invalid token?)" -ForegroundColor Red
        # Clear saved token if it fails
        if (Test-Path $TokenFile) {
            Remove-Item $TokenFile -Force
            Write-Host "🗑️  Cleared saved token. Please run again with correct token." -ForegroundColor Yellow
        }
        exit 1
    } else {
        Write-Host "⚠️  Unexpected response: $result" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error updating DuckDNS: $_" -ForegroundColor Red
    exit 1
}
