--[[
    Kimi AI UI Client Script
    Handles the chat interface for interacting with Kimi
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Configuration
local UI_CONFIG = {
	MAX_PROMPT_LENGTH = 500,
	COOLDOWN_SECONDS = 10,
}

-- State
local isCooldown = false
local cooldownConnection: RBXScriptConnection?

-- Get RemoteFunction
local remoteFunctions = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteFunctions")
local askKimiFunction = remoteFunctions:WaitForChild("AskKimi") :: RemoteFunction

--[[
    Create the Kimi Chat UI
]]
local function createKimiUI(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "KimiAIInterface"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- Main Container
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, -200, 0.8, -150)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	mainFrame.BorderSizePixel = 0
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = mainFrame
	
	-- Shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 40, 1, 40)
	shadow.Position = UDim2.new(0, -20, 0, -20)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(20, 20, 280, 280)
	shadow.Parent = mainFrame
	
	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 40)
	header.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	header.BorderSizePixel = 0
	header.Parent = mainFrame
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 12)
	headerCorner.Parent = header
	
	-- Fix bottom corners of header
	local headerFix = Instance.new("Frame")
	headerFix.Name = "Fix"
	headerFix.Size = UDim2.new(1, 0, 0, 12)
	headerFix.Position = UDim2.new(0, 0, 1, -12)
	headerFix.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	headerFix.BorderSizePixel = 0
	headerFix.Parent = header
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 15, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🏎️ Kimi AI Co-Driver"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 18
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header
	
	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = header
	
	-- Chat Display
	local chatDisplay = Instance.new("ScrollingFrame")
	chatDisplay.Name = "ChatDisplay"
	chatDisplay.Size = UDim2.new(1, -20, 1, -90)
	chatDisplay.Position = UDim2.new(0, 10, 0, 50)
	chatDisplay.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	chatDisplay.BorderSizePixel = 0
	chatDisplay.ScrollBarThickness = 6
	chatDisplay.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	chatDisplay.AutomaticCanvasSize = Enum.AutomaticSize.Y
	chatDisplay.CanvasSize = UDim2.new(0, 0, 0, 0)
	chatDisplay.Parent = mainFrame
	
	local displayCorner = Instance.new("UICorner")
	displayCorner.CornerRadius = UDim.new(0, 8)
	displayCorner.Parent = chatDisplay
	
	-- Chat layout
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = chatDisplay
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.Parent = chatDisplay
	
	-- Input Container
	local inputContainer = Instance.new("Frame")
	inputContainer.Name = "InputContainer"
	inputContainer.Size = UDim2.new(1, -20, 0, 40)
	inputContainer.Position = UDim2.new(0, 10, 1, -50)
	inputContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	inputContainer.BorderSizePixel = 0
	inputContainer.Parent = mainFrame
	
	local inputCorner = Instance.new("UICorner")
	inputCorner.CornerRadius = UDim.new(0, 8)
	inputCorner.Parent = inputContainer
	
	-- TextBox
	local textBox = Instance.new("TextBox")
	textBox.Name = "InputBox"
	textBox.Size = UDim2.new(1, -90, 1, -10)
	textBox.Position = UDim2.new(0, 10, 0, 5)
	textBox.BackgroundTransparency = 1
	textBox.Text = ""
	textBox.PlaceholderText = "Ask Kimi to design your car..."
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
	textBox.TextSize = 14
	textBox.Font = Enum.Font.Gotham
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.ClearTextOnFocus = false
	textBox.Parent = inputContainer
	
	-- Character limit indicator
	local charLimit = Instance.new("TextLabel")
	charLimit.Name = "CharLimit"
	charLimit.Size = UDim2.new(0, 40, 0, 20)
	charLimit.Position = UDim2.new(1, -80, 0, 10)
	charLimit.BackgroundTransparency = 1
	charLimit.Text = "0/500"
	charLimit.TextColor3 = Color3.fromRGB(120, 120, 120)
	charLimit.TextSize = 10
	charLimit.Font = Enum.Font.Gotham
	charLimit.Parent = inputContainer
	
	-- Send Button
	local sendBtn = Instance.new("TextButton")
	sendBtn.Name = "SendButton"
	sendBtn.Size = UDim2.new(0, 60, 0, 30)
	sendBtn.Position = UDim2.new(1, -70, 0, 5)
	sendBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	sendBtn.BorderSizePixel = 0
	sendBtn.Text = "Send"
	sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	sendBtn.TextSize = 14
	sendBtn.Font = Enum.Font.GothamBold
	sendBtn.Parent = inputContainer
	
	local sendCorner = Instance.new("UICorner")
	sendCorner.CornerRadius = UDim.new(0, 6)
	sendCorner.Parent = sendBtn
	
	-- Toggle Button (always visible)
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "KimiToggleButton"
	toggleBtn.Size = UDim2.new(0, 50, 0, 50)
	toggleBtn.Position = UDim2.new(1, -60, 0.5, -25)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	toggleBtn.BorderSizePixel = 0
	toggleBtn.Text = "🤖"
	toggleBtn.TextSize = 24
	toggleBtn.Parent = screenGui
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(1, 0)
	toggleCorner.Parent = toggleBtn
	
	local toggleShadow = Instance.new("ImageLabel")
	toggleShadow.Name = "Shadow"
	toggleShadow.Size = UDim2.new(1, 20, 1, 20)
	toggleShadow.Position = UDim2.new(0, -10, 0, -10)
	toggleShadow.BackgroundTransparency = 1
	toggleShadow.Image = "rbxassetid://5554236805"
	toggleShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	toggleShadow.ImageTransparency = 0.7
	toggleShadow.ScaleType = Enum.ScaleType.Slice
	toggleShadow.SliceCenter = Rect.new(20, 20, 280, 280)
	toggleShadow.Parent = toggleBtn
	
	return screenGui, {
		mainFrame = mainFrame,
		chatDisplay = chatDisplay,
		textBox = textBox,
		sendBtn = sendBtn,
		closeBtn = closeBtn,
		toggleBtn = toggleBtn,
		charLimit = charLimit,
	}
end

--[[
    Add a message to the chat display
]]
local function addMessage(chatDisplay: ScrollingFrame, sender: string, message: string, isPlayer: boolean)
	local messageFrame = Instance.new("Frame")
	messageFrame.Name = "Message_" .. sender
	messageFrame.Size = UDim2.new(1, 0, 0, 0)
	messageFrame.AutomaticSize = Enum.AutomaticSize.Y
	messageFrame.BackgroundTransparency = 1
	messageFrame.LayoutOrder = #chatDisplay:GetChildren() - 2 -- Account for UIListLayout and UIPadding
	messageFrame.Parent = chatDisplay
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent = messageFrame
	
	-- Avatar/Sender label
	local avatar = Instance.new("TextLabel")
	avatar.Name = "Avatar"
	avatar.Size = UDim2.new(0, 30, 0, 30)
	avatar.Position = isPlayer and UDim2.new(1, -30, 0, 0) or UDim2.new(0, 0, 0, 0)
	avatar.BackgroundColor3 = isPlayer and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(0, 170, 255)
	avatar.BorderSizePixel = 0
	avatar.Text = isPlayer and "👤" or "🤖"
	avatar.TextSize = 16
	avatar.Parent = messageFrame
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatar
	
	-- Message bubble
	local bubble = Instance.new("TextLabel")
	bubble.Name = "Bubble"
	bubble.Size = UDim2.new(1, -50, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.Y
	bubble.Position = isPlayer and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 40, 0, 0)
	bubble.BackgroundColor3 = isPlayer and Color3.fromRGB(60, 60, 70) or Color3.fromRGB(0, 130, 200)
	bubble.BorderSizePixel = 0
	bubble.Text = message
	bubble.TextColor3 = Color3.fromRGB(255, 255, 255)
	bubble.TextSize = 14
	bubble.Font = Enum.Font.Gotham
	bubble.TextWrapped = true
	bubble.TextXAlignment = isPlayer and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	bubble.Parent = messageFrame
	
	local bubbleCorner = Instance.new("UICorner")
	bubbleCorner.CornerRadius = UDim.new(0, 8)
	bubbleCorner.Parent = bubble
	
	local bubblePadding = Instance.new("UIPadding")
	bubblePadding.PaddingTop = UDim.new(0, 8)
	bubblePadding.PaddingBottom = UDim.new(0, 8)
	bubblePadding.PaddingLeft = UDim.new(0, 12)
	bubblePadding.PaddingRight = UDim.new(0, 12)
	bubblePadding.Parent = bubble
	
	-- Scroll to bottom
	chatDisplay.CanvasPosition = Vector2.new(0, chatDisplay.AbsoluteCanvasSize.Y)
end

--[[
    Show cooldown indicator
]]
local function showCooldown(sendBtn: TextButton, duration: number)
	isCooldown = true
	sendBtn.Text = tostring(duration)
	sendBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	sendBtn.Active = false
	
	local timeLeft = duration
	cooldownConnection = task.spawn(function()
		while timeLeft > 0 do
			task.wait(1)
			timeLeft -= 1
			sendBtn.Text = tostring(timeLeft)
		end
		
		isCooldown = false
		sendBtn.Text = "Send"
		sendBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
		sendBtn.Active = true
	end)
end

--[[
    Apply features to player's car based on Kimi's response
]]
local function applyCarFeatures(features: { [string]: any })
	-- This would connect to your existing car building system
	-- For now, we'll just print the features
	print("[KimiUI] Applying features:")
	for feature, value in pairs(features) do
		print("  -", feature, value)
		
		-- Fire events that your car building system can listen to
		local featureEvent = Instance.new("BindableEvent")
		featureEvent.Name = "KimiFeature_" .. feature
		featureEvent:Fire(value)
	end
end

--[[
    Main initialization
]]
local function init()
	local ui, elements = createKimiUI()
	ui.Parent = playerGui
	
	local mainFrame = elements.mainFrame
	local chatDisplay = elements.chatDisplay
	local textBox = elements.textBox
	local sendBtn = elements.sendBtn
	local closeBtn = elements.closeBtn
	local toggleBtn = elements.toggleBtn
	local charLimit = elements.charLimit
	
	-- Start hidden
	mainFrame.Visible = false
	
	-- Toggle button functionality
	toggleBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = not mainFrame.Visible
		
		-- Animate
		if mainFrame.Visible then
			mainFrame.Size = UDim2.new(0, 400, 0, 0)
			TweenService:Create(mainFrame, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 400, 0, 300)
			}):Play()
			textBox:CaptureFocus()
		end
	end)
	
	-- Close button
	closeBtn.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
	end)
	
	-- Character limit update
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		local length = #textBox.Text
		charLimit.Text = length .. "/" .. UI_CONFIG.MAX_PROMPT_LENGTH
		
		if length > UI_CONFIG.MAX_PROMPT_LENGTH then
			charLimit.TextColor3 = Color3.fromRGB(255, 100, 100)
		else
			charLimit.TextColor3 = Color3.fromRGB(120, 120, 120)
		end
	end)
	
	-- Send message function
	local function sendMessage()
		if isCooldown then return end
		
		local prompt = textBox.Text
		if #prompt == 0 then return end
		if #prompt > UI_CONFIG.MAX_PROMPT_LENGTH then
			addMessage(chatDisplay, "System", "Message too long!", false)
			return
		end
		
		-- Add player message to UI
		addMessage(chatDisplay, player.Name, prompt, true)
		textBox.Text = ""
		
		-- Show cooldown
		showCooldown(sendBtn, UI_CONFIG.COOLDOWN_SECONDS)
		
		-- Send to server
		task.spawn(function()
			local success, reply, features = askKimiFunction:InvokeServer(prompt)
			
			if success then
				-- Add Kimi's response
				addMessage(chatDisplay, "Kimi", reply, false)
				
				-- Apply features if any
				if features and next(features) then
					applyCarFeatures(features)
				end
			else
				-- Show error
				addMessage(chatDisplay, "System", "Error: " .. reply, false)
			end
		end)
	end
	
	-- Send button click
	sendBtn.MouseButton1Click:Connect(sendMessage)
	
	-- Enter key to send
	textBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			sendMessage()
			textBox:CaptureFocus()
		end
	end)
	
	-- Welcome message
	addMessage(chatDisplay, "Kimi", 
		"Hey there! I'm Kimi, your AI co-driver! 🏎️\n" ..
		"Ask me to customize your car or track:\n" ..
		"• 'Build me a pineapple car'\n" ..
		"• 'Make the track icy'\n" ..
		"• 'Add rockets to my car'", false)
	
	print("[KimiUI] Interface initialized")
end

-- Initialize when ready
init()
