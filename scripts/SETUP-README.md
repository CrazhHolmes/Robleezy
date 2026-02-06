# 🚀 Kimi Proxy Setup for robleezy-ai.duckdns.org

This folder contains automated setup scripts for your DuckDNS self-hosted proxy.

## 📋 Prerequisites

Before running these scripts, you need:
1. **DuckDNS Account** with subdomain `robleezy-ai` ✅ (you have this)
2. **DuckDNS Auth Token** (from https://www.duckdns.org) ⏳ (you have this ready)
3. **Kimi API Key** (from https://platform.moonshot.cn) ⏳ (need to get this)
4. **Python 3.9+** installed ⏳ (will check)

## 🎯 Quick Start

### Step 1: Run the master setup script
```powershell
# Open PowerShell as Administrator
# Right-click Start → Windows PowerShell (Admin) or Windows Terminal (Admin)

cd C:\path\to\Robleezy\scripts
.\setup-all.ps1
```

This will guide you through:
1. 🔐 Setting up DuckDNS auto-updater (NEEDS YOUR AUTH TOKEN)
2. 🔓 Opening Windows Firewall port 8080
3. 📦 Installing Python dependencies
4. ⚙️ Creating the Windows service

### Step 2: Port Forward on Your Router

You'll need to forward port 8080 from your router to your PC.

See `..\ddns-setup.md` for detailed router instructions.

### Step 3: Test Everything

```powershell
# Test DuckDNS
.\duckdns-updater.ps1 -ShowStatus

# Test the proxy (after starting the service)
curl -X POST https://robleezy-ai.duckdns.org:8080/ask `
     -H "Content-Type: application/json" `
     -H "X-Secret: super-secret-string-42" `
     -d '{"msg":"test"}'
```

## 📁 Script Reference

| Script | Purpose | Run As Admin? |
|--------|---------|---------------|
| `setup-all.ps1` | Master setup - runs everything in order | ✅ Yes |
| `setup-ddns.ps1` | Sets up DuckDNS auto-updater scheduled task | No |
| `setup-firewall.ps1` | Opens Windows Firewall port 8080 | ✅ Yes |
| `install-service.ps1` | Installs Kimi Proxy as Windows service | ✅ Yes |
| `duckdns-updater.ps1` | Manual DuckDNS update / status check | No |

## 🔧 Individual Commands

### DuckDNS
```powershell
# Setup auto-updater (prompts for token)
.\setup-ddns.ps1

# Check status
.\duckdns-updater.ps1 -ShowStatus

# Manual update (if you saved token)
.\duckdns-updater.ps1

# Remove auto-updater
.\setup-ddns.ps1 -Remove
```

### Firewall
```powershell
# Open port 8080
.\setup-firewall.ps1

# Close port 8080
.\setup-firewall.ps1 -Remove
```

### Service
```powershell
# Install and start service
.\install-service.ps1

# Uninstall service
.\install-service.ps1 -Uninstall

# Check service status
Get-Service KimiProxy
```

## ⚙️ Configuration Files

After setup, edit these files:

### `..\kimi-proxy\.env`
```env
KIMI_API_KEY=your-kimi-api-key-here
SHARED_SECRET=super-secret-string-42
```

### `..\src\server\KimiHandler.server.luau`
The URL is already set to `https://robleezy-ai.duckdns.org:8080/ask` ✅

Just update the `SHARED_SECRET` constant if you changed it from the default.

## 🆘 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Not running as Administrator" | Right-click PowerShell → Run as Administrator |
| "Python not found" | Install Python from https://python.org (check "Add to PATH") |
| "DuckDNS update failed" | Check your token on https://www.duckdns.org |
| "Port checker shows closed" | Check router port forwarding and Windows Firewall |
| "Service won't start" | Check logs at `..\kimi-proxy\logs\service-error.log` |

## 📞 Next Steps

1. Run `setup-all.ps1` as Administrator
2. Enter your DuckDNS token when prompted
3. Enter your Kimi API key when prompted
4. Configure port forwarding on your router
5. Test with `curl` or in Roblox Studio

Good luck! 🎮🏎️
