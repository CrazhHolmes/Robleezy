# DDNS Self-Hosted Proxy Setup Guide

This guide walks you through setting up your own Kimi AI proxy with a static domain name using free DDNS (Dynamic DNS) service.

## Overview

Instead of using Replit or cloud hosting, you'll run the proxy on your own PC and access it via a domain like `yourname.duckdns.org`.

---

## Step 1: Port Forwarding on Your Router

You need to open port 8080 on your router so external requests can reach your PC.

### Find Your PC's Local IP
```powershell
# Windows PowerShell
ipconfig | findstr "IPv4"
# Example output: 192.168.1.42
```

### Router Configuration
1. Open your router admin page (usually `http://192.168.1.1` or `http://192.168.0.1`)
2. Log in (check router sticker for credentials)
3. Find "Port Forwarding" or "Virtual Servers" section
4. Add a new rule:
   - **Service Name**: KimiProxy
   - **External Port**: 8080
   - **Internal Port**: 8080
   - **Internal IP**: Your PC's IP (e.g., 192.168.1.42)
   - **Protocol**: TCP
5. Save and apply

### Verify Port is Open
Visit https://canyouseeme.org and enter port 8080 to test.

---

## Step 2: Create Free DuckDNS Hostname

DuckDNS provides free dynamic DNS hostnames that point to your changing home IP.

### Sign Up
1. Go to https://www.duckdns.org
2. Sign in with Google, GitHub, Twitter, or Reddit
3. Choose a subdomain name (e.g., `robleezy-ai`)
4. Your hostname will be: `robleezy-ai.duckdns.org`

### Add Your Current IP
1. In the DuckDNS dashboard, find your subdomain
2. The IP field should auto-fill with your current IP
3. Click "update ip" to save

---

## Step 3: Install DDNS Updater

Your home IP changes periodically. You need software to update DuckDNS automatically.

### Option A: ddclient (Recommended)

**Windows (with Chocolatey):**
```powershell
# Install Chocolatey if needed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install ddclient
choco install ddclient
```

**Create config file** at `C:\ProgramData\ddclient\ddclient.conf`:
```
daemon=300
syslog=yes
protocol=duckdns
use=web, web=https://checkip.amazonaws.com/
ssl=yes
server=www.duckdns.org
login=your-token-here
password=your-token-here
robleezy-ai.duckdns.org
```

Get your token from https://www.duckdns.org (shown after login)

**Start ddclient:**
```powershell
# Run manually first to test
ddclient -daemon=0 -verbose

# Then install as service
nssm install ddclient "C:\ProgramData\chocolatey\bin\ddclient.exe"
nssm start ddclient
```

### Option B: Built-in Router DDNS

Many routers have DDNS built-in:
1. Go to router admin → Dynamic DNS / DDNS
2. Select provider: DuckDNS
3. Enter your domain and token
4. Enable and save

### Option C: Simple PowerShell Script

Create `update-ddns.ps1`:
```powershell
$token = "your-token-here"
$domain = "robleezy-ai"
Invoke-RestMethod -Uri "https://www.duckdns.org/update?domains=$domain&token=$token&ip="
```

Add to Task Scheduler to run every 5 minutes.

---

## Step 4: Set Environment Variables

Your proxy needs two secrets to run.

### Windows (PowerShell as Admin)
```powershell
# Set system environment variables (persistent)
[Environment]::SetEnvironmentVariable("KIMI_API_KEY", "your-kimi-api-key-here", "User")
[Environment]::SetEnvironmentVariable("SHARED_SECRET", "your-super-secret-string-42", "User")

# Reload environment variables in current session
$env:KIMI_API_KEY = "your-kimi-api-key-here"
$env:SHARED_SECRET = "your-super-secret-string-42"
```

### Linux/macOS
```bash
# Add to ~/.bashrc or ~/.zshrc
export KIMI_API_KEY="your-kimi-api-key-here"
export SHARED_SECRET="your-super-secret-string-42"

# Apply immediately
source ~/.bashrc
```

### Using .env File (Alternative)
```bash
# Copy the example file
cp .env.example .env

# Edit with your values
notepad .env
```

---

## Step 5: Run the Proxy

### Install Dependencies
```bash
cd kimi-proxy
pip install -r requirements.txt
```

### Start the Server
```bash
python app.py
```

You should see:
```
🚀 Starting Kimi AI DDNS Proxy...
   Secret configured: ✅
   Kimi API configured: ✅
   Listening on 0.0.0.0:8080
```

### Test Local Access
```bash
curl http://localhost:8080/
# Expected: {"status": "online", ...}
```

### Test with Secret
```bash
curl -H "X-Secret: your-super-secret-string-42" \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"msg":"test","playerId":"123","playerName":"Test"}' \
     http://localhost:8080/ask
```

---

## Step 6: Test External Access

### From Another Device/Network
```bash
curl https://robleezy-ai.duckdns.org:8080/
```

If this works, your setup is complete! 🎉

---

## Step 7: Update Roblox Game

Edit `src/server/KimiHandler.server.luau`:

```lua
-- Change this line
local KIMI_PROXY_URL = "https://robleezy-ai.duckdns.org:8080/ask"

-- Add this constant
local SHARED_SECRET = "your-super-secret-string-42"

-- Update the HttpService call to include the header
local success, response = pcall(function()
    return HttpService:PostAsync(
        CONFIG.KIMI_PROXY_URL,
        payload,
        Enum.HttpContentType.ApplicationJson,
        false,
        {["X-Secret"] = SHARED_SECRET}
    )
end)
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Connection refused" | Check port forwarding, firewall, and that proxy is running |
| "Missing X-Secret header" | Make sure Roblox script sends the header |
| "Invalid secret" | Verify SHARED_SECRET matches in both .env and Roblox |
| DDNS not updating | Check ddclient logs or router DDNS settings |
| HTTPS errors | Use http:// for local, https:// may need certificate setup |

### Windows Firewall
Allow Python through the firewall:
```powershell
# Run as admin
New-NetFirewallRule -DisplayName "Kimi Proxy" -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow
```

---

## Security Notes

⚠️ **Important:**
- Keep your `SHARED_SECRET` private - anyone with it can use your proxy
- Keep your `KIMI_API_KEY` private - it has billing implications
- Consider using HTTPS with Let's Encrypt for production
- Monitor your Kimi API usage to avoid unexpected charges

---

## Alternative DDNS Providers

- **No-IP**: https://www.noip.com (free tier requires monthly confirmation)
- **Dynu**: https://www.dynu.com (free, no confirmation needed)
- **Afraid.org**: https://freedns.afraid.org (free, many domains)

The setup process is similar for all providers.
