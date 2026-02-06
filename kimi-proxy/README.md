# Kimi AI Proxy for Roblox

This Flask service acts as a bridge between your Roblox game and the Kimi AI API (Moonshot AI).

## Setup on Replit

1. **Create a new Repl**
   - Go to [replit.com](https://replit.com)
   - Click "Create Repl"
   - Select "Python" template
   - Name it "kimi-proxy"

2. **Upload these files**
   - `app.py`
   - `requirements.txt`
   - `.replit`

3. **Configure Secrets**
   - Click the "Secrets" tab (lock icon) in the left sidebar
   - Add a new secret:
     - Key: `KIMI_API_KEY`
     - Value: Your Kimi API key from [platform.moonshot.cn](https://platform.moonshot.cn)

4. **Run the service**
   - Click the "Run" button
   - Copy the HTTPS URL (e.g., `https://kimi-proxy.yourusername.repl.co`)

5. **Keep it alive** (Optional but recommended)
   - Go to [uptimerobot.com](https://uptimerobot.com)
   - Create a free account
   - Add a new monitor:
     - Type: HTTP(s)
     - URL: Your Replit URL + `/health` (e.g., `https://kimi-proxy.yourusername.repl.co/health`)
     - Interval: Every 5 minutes

## Updating Your Roblox Game

Once deployed, update the proxy URL in your Roblox server script:

```lua
-- In src/server/KimiHandler.server.luau
KIMI_PROXY_URL = "https://kimi-proxy.yourusername.repl.co/ask"
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/health` | GET | Detailed health status |
| `/ask` | POST | Send message to Kimi AI |

## Testing

You can test the proxy with curl:

```bash
curl -X POST https://kimi-proxy.yourusername.repl.co/ask \
  -H "Content-Type: application/json" \
  -d '{"msg":"build me a pineapple car","playerId":"123","playerName":"TestPlayer"}'
```

## Free Tier Limits

- **Replit**: Free tier includes always-on for 1 Repl
- **Kimi API**: Check current pricing at [platform.moonshot.cn](https://platform.moonshot.cn)
