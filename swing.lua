local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- Variables
local loopEnabled = false
local loopConnection
local currentToolName = "Scythe"

-- Function to recursively check for ImportantTool in all children
local function checkForImportantTool()
	if LocalPlayer.Backpack then
		for _, item in pairs(LocalPlayer.Backpack:GetChildren()) do
			-- Check the item itself
			if item.Name == "ImportantTool" then
				currentToolName = item.Parent.Name
				return true
			end
			
			-- Recursively check all descendants
			for _, descendant in pairs(item:GetDescendants()) do
				if descendant.Name == "ImportantTool" then
					currentToolName = item.Name
					return true
				end
			end
		end
	end
	
	-- Also check equipped tool in character
	if LocalPlayer.Character then
		for _, item in pairs(LocalPlayer.Character:GetChildren()) do
			if item:IsA("Tool") then
				-- Check the tool itself
				if item.Name == "ImportantTool" then
					currentToolName = item.Name
					return true
				end
				
				-- Recursively check all descendants
				for _, descendant in pairs(item:GetDescendants()) do
					if descendant.Name == "ImportantTool" then
						currentToolName = item.Name
						return true
					end
				end
			end
		end
	end
	
	return false
end

-- Function to fire the event
local function fireEvent()
	if LocalPlayer.Character then
		local tool = LocalPlayer.Character:FindFirstChild(currentToolName)
		if tool then
			local event = tool:FindFirstChild("Event")
			if event then
				event:FireServer()
			end
		end
	end
end

-- Function to start the loop
local function startLoop()
	loopEnabled = true
	spawn(function()
		while loopEnabled do
			checkForImportantTool()  -- Check and update tool name
			fireEvent()
			wait(0.05)  -- Fast event firing
		end
	end)
end

-- Function to stop the loop
local function stopLoop()
	loopEnabled = false
end

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EventFireGui"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -40)
mainFrame.Size = UDim2.new(0, 200, 0, 80)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 2

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(0, 255, 255)
MainStroke.Transparency = 0.3
MainStroke.Parent = mainFrame

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
})
Gradient.Rotation = 90
Gradient.Parent = mainFrame

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 3
closeBtn.Parent = mainFrame

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)

-- Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Parent = mainFrame
toggleButton.Position = UDim2.new(0.5, -85, 0.5, -15)
toggleButton.Size = UDim2.new(0, 170, 0, 40)
toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 16
toggleButton.Text = "Start Loop"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.ZIndex = 2

Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

local ToggleGradient = Instance.new("UIGradient")
ToggleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
})
ToggleGradient.Rotation = 45
ToggleGradient.Parent = toggleButton

-- Status Label (Tool Name)
local statusLabel = Instance.new("TextLabel")
statusLabel.Parent = mainFrame
statusLabel.Position = UDim2.new(0.5, 0, 0, 5)
statusLabel.Size = UDim2.new(0, 140, 0, 20)
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.Text = "Tool: Scythe"
statusLabel.ZIndex = 2

-- Make GUI draggable
local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local delta = input.Position - dragStart
	mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

-- Toggle button functionality
toggleButton.MouseButton1Click:Connect(function()
	if loopEnabled then
		stopLoop()
		toggleButton.Text = "Start Loop"
		toggleButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		ToggleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
		})
	else
		startLoop()
		toggleButton.Text = "Stop Loop"
		toggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
		ToggleGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 200, 50)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 150, 30))
		})
	end
end)

-- Check for ImportantTool every 1 second and update tool name
spawn(function()
	while wait(1) do
		checkForImportantTool()
		statusLabel.Text = "Tool: " .. currentToolName
	end
end)
