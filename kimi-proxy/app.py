"""
Kimi AI DDNS Proxy with Shared-Secret Authentication
Self-hosted solution for Roblox games with secure access
"""

from flask import Flask, request, jsonify
from functools import wraps
import os
import requests
import re
from datetime import datetime
from dotenv import load_dotenv

# Load environment variables from .env file
env_path = os.path.join(os.path.dirname(__file__), '.env')
load_dotenv(env_path)

app = Flask(__name__)

# Configuration from environment
KIMI_API_URL = os.getenv("KIMI_API_URL", "https://api.moonshot.cn/v1/chat/completions")
KIMI_API_KEY = os.getenv("KIMI_API_KEY", "")
SHARED_SECRET = os.getenv("SHARED_SECRET", "")

if not SHARED_SECRET:
    raise ValueError("SHARED_SECRET environment variable must be set!")

if not KIMI_API_KEY:
    print("⚠️  Warning: KIMI_API_KEY not set. Proxy will return fallback responses.")

# Racing context for Kimi AI
RACING_CONTEXT = """You are Kimi, an enthusiastic AI co-driver and car designer in a Roblox racing game.
Keep responses short (under 150 tokens), fun, and racing-themed.

When players ask for car modifications, mention relevant keywords naturally:
- For spikes: mention "spikes" 
- For speed boosts: mention "rockets" or "boost"
- For wide cars: mention "wide"
- For low cars: mention "low" or "lowered"
- For colorful cars: mention "rainbow" or specific colors
- For icy tracks: mention "icy" or "ice"
- For bumpy tracks: mention "bump" or "rough"

Examples:
- "Build me a pineapple car" → "Sure! Adding spikes and yellow paint to make it look like a pineapple! 🍍"
- "Make my car fast" → "Adding rockets for extra speed! Hold on tight! 🚀"
- "Surprise me" → "How about a wide, low-rider with rainbow paint? Let's do it! 🌈"

Always be encouraging and fun!"""


def require_secret(f):
    """Decorator to require X-Secret header on endpoints"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        provided_secret = request.headers.get('X-Secret')
        
        if not provided_secret:
            return jsonify({
                "success": False,
                "error": "Missing X-Secret header",
                "reply": "❌ Authentication required"
            }), 401
        
        if provided_secret != SHARED_SECRET:
            return jsonify({
                "success": False,
                "error": "Invalid secret",
                "reply": "❌ Invalid authentication"
            }), 403
        
        return f(*args, **kwargs)
    return decorated_function


def format_response(text: str) -> str:
    """Clean and format the AI response"""
    text = re.sub(r'\*\*|\*|__|_|`', '', text)
    if len(text) > 500:
        text = text[:497] + "..."
    return text.strip()


@app.route("/ping", methods=["GET"])
@require_secret
def ping():
    """Health check endpoint - requires secret"""
    return jsonify({
        "status": "online",
        "service": "Kimi AI DDNS Proxy",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat(),
        "api_configured": bool(KIMI_API_KEY)
    })


@app.route("/ask", methods=["POST"])
@require_secret
def ask():
    """
    Main endpoint for Roblox to ask Kimi AI
    Requires X-Secret header for authentication
    """
    try:
        data = request.get_json()
        
        if not data or "msg" not in data:
            return jsonify({
                "success": False,
                "reply": "No message provided",
                "error": "Missing 'msg' field"
            }), 400
        
        user_message = data.get("msg", "").strip()
        player_id = data.get("playerId", "unknown")
        player_name = data.get("playerName", "Racer")
        
        if not user_message:
            return jsonify({
                "success": False,
                "reply": "Empty message",
                "error": "Message cannot be empty"
            }), 400
        
        print(f"[{datetime.now()}] {player_name} ({player_id}): {user_message}")
        
        # Fallback if no API key configured
        if not KIMI_API_KEY:
            fallback_replies = [
                f"Hey {player_name}! I'd love to help you customize your ride! Adding some cool features now! 🏎️✨",
                f"Great idea, {player_name}! Let's make your car stand out on the track! 🚀",
                f"{player_name}, that's a creative request! I'm on it! 🎨",
            ]
            import random
            return jsonify({
                "success": True,
                "reply": random.choice(fallback_replies),
                "note": "Using fallback (no API key configured)"
            })
        
        # Call Kimi API
        headers = {
            "Authorization": f"Bearer {KIMI_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "moonshot-v1-8k",
            "messages": [
                {"role": "system", "content": RACING_CONTEXT},
                {"role": "user", "content": f"Player {player_name} says: {user_message}"}
            ],
            "max_tokens": 150,
            "temperature": 0.8
        }
        
        response = requests.post(
            KIMI_API_URL,
            headers=headers,
            json=payload,
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            ai_message = result["choices"][0]["message"]["content"]
            formatted_reply = format_response(ai_message)
            
            print(f"[{datetime.now()}] Kimi response: {formatted_reply[:100]}...")
            
            return jsonify({
                "success": True,
                "reply": formatted_reply
            })
        else:
            print(f"Kimi API error: {response.status_code} - {response.text}")
            return jsonify({
                "success": False,
                "reply": "Kimi's having a pit stop, try again soon! 🏁",
                "error": f"API returned {response.status_code}"
            }), 500
            
    except requests.Timeout:
        return jsonify({
            "success": False,
            "reply": "Kimi's taking too long to respond, try again! ⏱️",
            "error": "Request timeout"
        }), 504
        
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        return jsonify({
            "success": False,
            "reply": "Something went wrong in the pit lane! 🛠️",
            "error": str(e)
        }), 500


@app.route("/", methods=["GET"])
def root():
    """Root endpoint - no auth required for basic check"""
    return jsonify({
        "status": "online",
        "service": "Kimi AI DDNS Proxy",
        "version": "2.0.0",
        "note": "Use /ping or /ask with X-Secret header"
    })


if __name__ == "__main__":
    print("🚀 Starting Kimi AI DDNS Proxy...")
    print(f"   Secret configured: {'✅' if SHARED_SECRET else '❌'}")
    print(f"   Kimi API configured: {'✅' if KIMI_API_KEY else '⚠️  (fallback mode)'}")
    print("   Listening on 0.0.0.0:8080")
    app.run(host="0.0.0.0", port=8080, debug=False)
