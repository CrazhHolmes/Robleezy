--[[
    Kimi AI Handler Server Script
    Handles AI requests with rate limiting and safety filtering
]]

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Load the car integration module
local KimiCarIntegration = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KimiCarIntegration"))

-- Configuration
local CONFIG = {
	-- DDNS self-hosted proxy URL - UPDATE THIS with your DuckDNS hostname
	KIMI_PROXY_URL = "https://yourhostname.duckdns.org:8080/ask",
	
	-- Shared secret for proxy authentication - MUST match your .env SHARED_SECRET
	SHARED_SECRET = "super-secret-string-42",
	
	-- Rate limiting: 1 request per player per 10 seconds
	RATE_LIMIT_SECONDS = 10,
	
	-- Maximum prompt length
	MAX_PROMPT_LENGTH = 500,
	
	-- Request timeout
	REQUEST_TIMEOUT = 15,
	
	-- Whether to automatically apply car features from Kimi's response
	AUTO_APPLY_FEATURES = true,
}

-- State
local lastRequestTime: { [Player]: number } = {}

-- Get the RemoteFunction
local remoteFunctions = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteFunctions")
local askKimiFunction = remoteFunctions:WaitForChild("AskKimi") :: RemoteFunction

--[[
    Check if player is rate limited
]]
local function isRateLimited(player: Player): boolean
	local now = tick()
	local lastRequest = lastRequestTime[player]
	
	if lastRequest and (now - lastRequest) < CONFIG.RATE_LIMIT_SECONDS then
		return true
	end
	
	return false
end

--[[
    Update player's last request time
]]
local function updateRateLimit(player: Player)
	lastRequestTime[player] = tick()
end

--[[
    Clean up disconnected players from rate limit table
]]
local function cleanupPlayer(player: Player)
	lastRequestTime[player] = nil
end

--[[
    Filter text using Roblox's TextService
]]
local function filterText(player: Player, text: string): (boolean, string)
	local success, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	
	if success then
		return true, result
	else
		return false, "Text filtering failed"
	end
end

--[[
    Parse Kimi's response for actionable keywords
    Returns the reply and a table of detected features
]]
local function parseResponse(response: string): (string, { [string]: any })
	local features = {}
	local lowerResponse = string.lower(response)
	
	-- Detect car customization keywords
	if string.find(lowerResponse, "spike") then
		features.addSpikes = true
	end
	if string.find(lowerResponse, "rocket") or string.find(lowerResponse, "boost") then
		features.addRockets = true
	end
	if string.find(lowerResponse, "wide") then
		features.makeWide = true
	end
	if string.find(lowerResponse, "low") or string.find(lowerResponse, "lower") then
		features.makeLow = true
	end
	if string.find(lowerResponse, "rainbow") or string.find(lowerResponse, "colorful") then
		features.rainbowPaint = true
	end
	if string.find(lowerResponse, "yellow") then
		features.yellowPaint = true
	end
	
	-- Detect track modifiers
	if string.find(lowerResponse, "icy") or string.find(lowerResponse, "ice") then
		features.icyTrack = true
	end
	if string.find(lowerResponse, "bump") or string.find(lowerResponse, "rough") then
		features.bumpyTrack = true
	end
	
	return response, features
end

--[[
    Apply features to the game world
]]
local function applyFeatures(player: Player, features: { [string]: any })
	-- Apply car features
	local carFeatures = {}
	for key, value in pairs(features) do
		if key ~= "icyTrack" and key ~= "bumpyTrack" then
			carFeatures[key] = value
		end
	end
	
	if next(carFeatures) then
		local success = KimiCarIntegration.ApplyFeatures(player, carFeatures)
		if success then
			print("[KimiHandler] Applied car features for", player.Name)
		end
	end
	
	-- Apply track features
	local trackFeatures = {}
	if features.icyTrack then trackFeatures.icyTrack = true end
	if features.bumpyTrack then trackFeatures.bumpyTrack = true end
	
	if next(trackFeatures) then
		KimiCarIntegration.ApplyTrackFeatures(trackFeatures)
		print("[KimiHandler] Applied track features")
	end
end

--[[
    Main handler for Kimi requests
]]
local function onAskKimi(player: Player, prompt: string): (boolean, string, { [string]: any }?)
	-- Validate input
	if typeof(prompt) ~= "string" then
		return false, "Invalid prompt type", nil
	end
	
	if #prompt > CONFIG.MAX_PROMPT_LENGTH then
		return false, "Prompt too long (max " .. CONFIG.MAX_PROMPT_LENGTH .. " characters)", nil
	end
	
	if #prompt == 0 then
		return false, "Prompt cannot be empty", nil
	end
	
	-- Check rate limit
	if isRateLimited(player) then
		local timeLeft = math.ceil(CONFIG.RATE_LIMIT_SECONDS - (tick() - lastRequestTime[player]))
		return false, "Please wait " .. timeLeft .. " seconds before asking again", nil
	end
	
	-- Filter the prompt for safety
	local filterSuccess, filteredPrompt = filterText(player, prompt)
	if not filterSuccess then
		return false, "Failed to filter text", nil
	end
	
	-- Check if text was filtered
	if filteredPrompt ~= prompt then
		return false, "Prompt contained inappropriate content", nil
	end
	
	-- Update rate limit
	updateRateLimit(player)
	
	-- Prepare request
	local payload = HttpService:JSONEncode({
		msg = filteredPrompt,
		playerId = tostring(player.UserId),
		playerName = player.Name
	})
	
	-- Make request to proxy with X-Secret header
	local success, response = pcall(function()
		return HttpService:PostAsync(
			CONFIG.KIMI_PROXY_URL,
			payload,
			Enum.HttpContentType.ApplicationJson,
			false,
			{["X-Secret"] = CONFIG.SHARED_SECRET}
		)
	end)
	
	if not success then
		warn("[KimiHandler] HTTP Error:", response)
		return false, "Kimi took a pit-stop, try again!", nil
	end
	
	-- Parse response
	local decodeSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(response)
	end)
	
	if not decodeSuccess then
		warn("[KimiHandler] JSON Decode Error:", decoded)
		return false, "Error understanding Kimi's response", nil
	end
	
	local reply = decoded.reply or decoded.message or decoded.response or "Kimi is thinking..."
	local _, features = parseResponse(reply)
	
	-- Apply features automatically if enabled
	if CONFIG.AUTO_APPLY_FEATURES and next(features) then
		applyFeatures(player, features)
	end
	
	return true, reply, features
end

-- Connect handler
askKimiFunction.OnServerInvoke = onAskKimi

-- Cleanup on player leave
Players.PlayerRemoving:Connect(cleanupPlayer)

print("[KimiHandler] Initialized and ready for AI requests")
print("[KimiHandler] DDNS Proxy URL:", CONFIG.KIMI_PROXY_URL)
