"""
Kimi AI Proxy Service for Roblox
Deploy this to Replit or any cloud platform to bridge Roblox with Kimi AI API
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import os
import re
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all domains

# Configuration
KIMI_API_URL = os.getenv("KIMI_API_URL", "https://api.moonshot.cn/v1/chat/completions")
KIMI_API_KEY = os.getenv("KIMI_API_KEY", "")  # Set this in Replit Secrets

# Racing context for better responses
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


def format_response(text: str) -> str:
    """Clean and format the AI response"""
    # Remove any markdown formatting
    text = re.sub(r'\*\*|\*|__|_|`', '', text)
    # Limit length
    if len(text) > 500:
        text = text[:497] + "..."
    return text.strip()


@app.route("/", methods=["GET"])
def home():
    """Health check endpoint"""
    return jsonify({
        "status": "online",
        "service": "Kimi AI Proxy for Roblox",
        "version": "1.0.0"
    })


@app.route("/ask", methods=["POST"])
def ask():
    """
    Main endpoint for Roblox to ask Kimi AI
    
    Expected JSON body:
    {
        "msg": "player's message",
        "playerId": "12345",
        "playerName": "PlayerName"
    }
    
    Returns:
    {
        "reply": "Kimi's response",
        "success": true
    }
    """
    try:
        # Get request data
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
        
        # Check if API key is configured
        if not KIMI_API_KEY:
            # Fallback response for demo/testing without API key
            fallback_replies = [
                f"Hey {player_name}! I'd love to help you customize your ride! Adding some cool features now! 🏎️✨",
                f"Great idea, {player_name}! Let's make your car stand out on the track! 🚀",
                f"{player_name}, that's a creative request! I'm on it! Adding those features to your vehicle! 🎨",
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
            "model": "moonshot-v1-8k",  # Kimi model
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


@app.route("/health", methods=["GET"])
def health():
    """Health check for uptime monitoring"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "api_configured": bool(KIMI_API_KEY)
    })


# For local testing
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=True)
