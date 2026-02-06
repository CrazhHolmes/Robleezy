--[[
    Kimi Car Integration Module
    Connects Kimi AI responses to your car building system
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local KimiCarIntegration = {}

-- Configuration
local CAR_TAG = "PlayerCar"
local SPIKE_TEMPLATE = ReplicatedStorage:FindFirstChild("SpikePart")
local ROCKET_TEMPLATE = ReplicatedStorage:FindFirstChild("RocketPart")

--[[
    Apply spikes to a car
]]
local function addSpikesToCar(car: Model)
	local body = car:FindFirstChild("Body") or car:FindFirstChild("Chassis") or car:FindFirstChildWhichIsA("BasePart")
	if not body then return end
	
	-- Add spikes around the car
	local spikePositions = {
		{0, 0, 1},   -- Front
		{0, 0, -1},  -- Back
		{1, 0, 0},   -- Right
		{-1, 0, 0},  -- Left
	}
	
	for _, offset in ipairs(spikePositions) do
		local spike = Instance.new("Part")
		spike.Name = "Spike"
		spike.Shape = Enum.PartType.Cone
		spike.Size = Vector3.new(0.5, 1, 0.5)
		spike.Color = Color3.fromRGB(100, 100, 100)
		spike.Material = Enum.Material.Metal
		spike.Anchored = false
		spike.CanCollide = false
		spike.Parent = car
		
		-- Weld to body
		local weld = Instance.new("Weld")
		weld.Part0 = body
		weld.Part1 = spike
		weld.C0 = CFrame.new(
			body.Size.X/2 * offset[1],
			body.Size.Y/2,
			body.Size.Z/2 * offset[3]
		) * CFrame.Angles(math.rad(90), 0, 0)
		weld.Parent = spike
	end
end

--[[
    Add rocket boosters to a car
]]
local function addRocketsToCar(car: Model)
	local body = car:FindFirstChild("Body") or car:FindFirstChild("Chassis") or car:FindFirstChildWhichIsA("BasePart")
	if not body then return end
	
	-- Add rockets at the back
	local rocket = Instance.new("Part")
	rocket.Name = "Rocket"
	rocket.Size = Vector3.new(0.8, 0.8, 1.5)
	rocket.Color = Color3.fromRGB(255, 100, 50)
	rocket.Material = Enum.Material.SmoothPlastic
	rocket.Anchored = false
	rocket.CanCollide = false
	rocket.Parent = car
	
	local weld = Instance.new("Weld")
	weld.Part0 = body
	weld.Part1 = rocket
	weld.C0 = CFrame.new(0, 0, body.Size.Z/2 + 0.5)
	weld.Parent = rocket
	
	-- Add fire effect
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 10
	fire.Color = Color3.fromRGB(100, 150, 255)
	fire.SecondaryColor = Color3.fromRGB(0, 100, 255)
	fire.Enabled = false -- Only enable when boosting
	fire.Name = "RocketFire"
	fire.Parent = rocket
end

--[[
    Make car wider
]]
local function makeCarWide(car: Model)
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Rocket" and part.Name ~= "Spike" then
			part.Size = Vector3.new(
				part.Size.X * 1.5,
				part.Size.Y,
				part.Size.Z
			)
		end
	end
end

--[[
    Make car lower (low-rider style)
]]
local function makeCarLow(car: Model)
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Rocket" and part.Name ~= "Spike" then
			part.Size = Vector3.new(
				part.Size.X,
				part.Size.Y * 0.6,
				part.Size.Z
			)
		end
	end
end

--[[
    Apply rainbow paint job
]]
local function applyRainbowPaint(car: Model)
	local hue = 0
	local connections = {}
	
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Rocket" and part.Name ~= "Spike" then
			local connection = RunService.Heartbeat:Connect(function()
				hue = (hue + 0.01) % 1
				part.Color = Color3.fromHSV(hue, 1, 1)
			end)
			table.insert(connections, connection)
		end
	end
	
	-- Store connections for cleanup
	car:SetAttribute("RainbowConnections", #connections)
end

--[[
    Apply yellow paint
]]
local function applyYellowPaint(car: Model)
	for _, part in ipairs(car:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Rocket" and part.Name ~= "Spike" then
			part.Color = Color3.fromRGB(255, 200, 50)
		end
	end
end

--[[
    Get a player's car
]]
local function getPlayerCar(player: Player): Model?
	-- Try to find car by ownership attribute
	for _, car in ipairs(CollectionService:GetTagged(CAR_TAG)) do
		if car:GetAttribute("Owner") == player.UserId then
			return car
		end
	end
	
	-- Fallback: find car in workspace with player name
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == player.Name .. "Car" then
			return obj
		end
	end
	
	return nil
end

--[[
    Apply features to a player's car based on Kimi's response
    
    Usage:
        local KimiIntegration = require(ReplicatedStorage.Shared.KimiCarIntegration)
        KimiIntegration.ApplyFeatures(player, {
            addSpikes = true,
            addRockets = true,
            rainbowPaint = true
        })
]]
function KimiCarIntegration.ApplyFeatures(player: Player, features: { [string]: any })
	local car = getPlayerCar(player)
	
	if not car then
		warn("[KimiCarIntegration] No car found for player:", player.Name)
		return false
	end
	
	print("[KimiCarIntegration] Applying features to", player.Name .. "'s car:", features)
	
	-- Apply each feature
	if features.addSpikes then
		addSpikesToCar(car)
	end
	
	if features.addRockets then
		addRocketsToCar(car)
	end
	
	if features.makeWide then
		makeCarWide(car)
	end
	
	if features.makeLow then
		makeCarLow(car)
	end
	
	if features.rainbowPaint then
		applyRainbowPaint(car)
	end
	
	if features.yellowPaint then
		applyYellowPaint(car)
	end
	
	return true
end

--[[
    Apply track modifications
    
    Usage:
        KimiIntegration.ApplyTrackFeatures({
            icyTrack = true,
            bumpyTrack = true
        })
]]
function KimiCarIntegration.ApplyTrackFeatures(features: { [string]: any })
	if features.icyTrack then
		-- Apply low friction to track parts
		for _, part in ipairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") and part.Name:find("Track") or part.Name:find("Road") then
				part.CustomPhysicalProperties = PhysicalProperties.new(
					0.01,  -- Friction
					0.1,   -- FrictionWeight
					1,     -- Elasticity
					1      -- ElasticityWeight
				)
				part.Color = Color3.fromRGB(200, 230, 255) -- Ice color
			end
		end
		print("[KimiCarIntegration] Track is now icy! ❄️")
	end
	
	if features.bumpyTrack then
		-- Add random bumps to track
		for _, part in ipairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") and (part.Name:find("Track") or part.Name:find("Road")) then
				-- Create bump
				local bump = Instance.new("Part")
				bump.Size = Vector3.new(
					math.random(2, 5),
					0.5,
					math.random(2, 5)
				)
				bump.Position = part.Position + Vector3.new(
					math.random(-part.Size.X/2, part.Size.X/2),
					part.Size.Y/2 + 0.25,
					math.random(-part.Size.Z/2, part.Size.Z/2)
				)
				bump.Color = Color3.fromRGB(100, 80, 60)
				bump.Material = Enum.Material.Rock
				bump.Anchored = true
				bump.Parent = workspace
				bump.Name = "Bump"
			end
		end
		print("[KimiCarIntegration] Track is now bumpy! 🪨")
	end
end

--[[
    Register a car with the system
    Call this when a player spawns/creates a car
    
    Usage:
        KimiIntegration.RegisterCar(player, carModel)
]]
function KimiCarIntegration.RegisterCar(player: Player, car: Model)
	car:SetAttribute("Owner", player.UserId)
	CollectionService:AddTag(car, CAR_TAG)
	print("[KimiCarIntegration] Registered car for", player.Name)
end

return KimiCarIntegration
