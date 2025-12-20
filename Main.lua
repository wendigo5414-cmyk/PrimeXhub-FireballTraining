
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

if player.PlayerGui:FindFirstChild("PRIMEHubGUI") then return end

-- ============================================
-- KILL FARM CONFIGURATION
-- ============================================
local loopDelay = 0.1  -- Default delay between each player target
local killFarmActive = false

-- ============================================
-- POWER FARM CONFIGURATION
-- ============================================
local powerFarmActive = false
local powerAmount = 99999999999
local powerMultiplier = 1
local powerFarmThreads = {}

-- ============================================
-- DAILY CLAIM CONFIGURATION
-- ============================================
local dailyClaimActive = false
local dailyClaimCount = 0
local dailyClaimDelay = 0.1
local dailyClaimMultiplier = 1
local dailyClaimThreads = {}

-- ============================================
-- GET SPINS CONFIGURATION
-- ============================================
local getSpinsActive = false
local getSpinsCount = 0
local getSpinsThread = nil

-- ============================================
-- KILL FARM BACKEND LOGIC
-- ============================================

-- Automatic Safe Zone Detection from workspace
local safeZones = {}

-- Function to load safe zones from workspace
local function loadSafeZones()
  safeZones = {}  -- Clear existing zones

  -- Load from SafeZones folder
  local safeZonesFolder = workspace:FindFirstChild("IgnoreParts")
  if safeZonesFolder then
      local safeZonesPath = safeZonesFolder:FindFirstChild("SafeZones")
      if safeZonesPath then
          for _, part in pairs(safeZonesPath:GetDescendants()) do
              if part:IsA("BasePart") and part.Name == "Safe" then
                  table.insert(safeZones, {
                      Type = "Box",
                      Position = part.Position,
                      Size = part.Size,
                      Part = part
                  })
              end
          end
      end

      -- Load from TrainingAreas folder
      local trainingAreasPath = safeZonesFolder:FindFirstChild("TrainingAreas")
      if trainingAreasPath then
          for _, part in pairs(trainingAreasPath:GetDescendants()) do
              if part:IsA("BasePart") and part.Name == "Safe" then
                  table.insert(safeZones, {
                      Type = "Box",
                      Position = part.Position,
                      Size = part.Size,
                      Part = part
                  })
              end
          end
      end
  end

  print("[PRIME Hub] Loaded " .. #safeZones .. " safe zones automatically!")
end

-- Load safe zones on start
loadSafeZones()

-- Reload safe zones every 30 seconds
task.spawn(function()
  while true do
      wait(30)
      loadSafeZones()
  end
end)

-- Loop control
local killFarmThread = nil

-- Function to check if a position is in a safe zone
local function isInSafeZone(position)
  for _, zone in pairs(safeZones) do
      if zone.Type == "Box" then
          local halfSize = zone.Size / 2
          local relativePos = position - zone.Position

          if math.abs(relativePos.X) <= halfSize.X and
             math.abs(relativePos.Y) <= halfSize.Y and
             math.abs(relativePos.Z) <= halfSize.Z then
              return true
          end
      end
  end
  return false
end

-- Function to get all valid player positions (excluding safe zones)
local function getAllTargetPositions()
  local positions = {}

  for _, targetPlayer in pairs(Players:GetPlayers()) do
      if targetPlayer ~= player and targetPlayer.Character then
          local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
          if hrp then
              -- Only add player if they're NOT in a safe zone
              if not isInSafeZone(hrp.Position) then
                  table.insert(positions, {
                      player = targetPlayer,
                      position = hrp.Position
                  })
              end
          end
      end
  end

  return positions
end

-- Main kill farm loop function
local function startKillFarm()
  if killFarmThread then return end

  killFarmThread = task.spawn(function()
      while killFarmActive do
          local targetPositions = getAllTargetPositions()

          if #targetPositions > 0 then
              for _, data in pairs(targetPositions) do
                  if not killFarmActive then break end

                  local targetPos = data.position
                  local args = {
                      vector.create(targetPos.X, targetPos.Y, targetPos.Z)
                  }

                  pcall(function()
                      player:WaitForChild("Backpack"):WaitForChild("Holy"):WaitForChild("Event"):FireServer(unpack(args))
                  end)

                  wait(loopDelay)
              end
          else
              wait(1)  -- Wait longer if no valid targets found
          end
      end
  end)
end

local function stopKillFarm()
  killFarmActive = false
  if killFarmThread then
      task.cancel(killFarmThread)
      killFarmThread = nil
  end
end

-- ============================================
-- POWER FARM BACKEND FUNCTIONS
-- ============================================

local function startPowerFarm()
    for i, thread in pairs(powerFarmThreads) do
        if thread then task.cancel(thread) end
    end
    powerFarmThreads = {}
    
    for i = 1, powerMultiplier do
        local thread = task.spawn(function()
            while powerFarmActive do
                local args = {"Power", powerAmount}
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("AddWheelSpinValue"):FireServer(unpack(args))
                end)
                wait(0.1)
            end
        end)
        table.insert(powerFarmThreads, thread)
    end
end

local function stopPowerFarm()
    powerFarmActive = false
    for i, thread in pairs(powerFarmThreads) do
        if thread then task.cancel(thread) end
    end
    powerFarmThreads = {}
end

-- ============================================
-- DAILY CLAIM BACKEND FUNCTIONS
-- ============================================

local function startDailyClaim()
    for i, thread in pairs(dailyClaimThreads) do
        if thread then task.cancel(thread) end
    end
    dailyClaimThreads = {}
    
    for i = 1, dailyClaimMultiplier do
        local thread = task.spawn(function()
            while dailyClaimActive do
                pcall(function()
                    game:GetService("ReplicatedStorage"):WaitForChild("DailyEvents"):WaitForChild("ClaimDaily"):FireServer()
                    dailyClaimCount = dailyClaimCount + 1
                end)
                wait(dailyClaimDelay)
            end
        end)
        table.insert(dailyClaimThreads, thread)
    end
end

local function stopDailyClaim()
    dailyClaimActive = false
    for i, thread in pairs(dailyClaimThreads) do
        if thread then task.cancel(thread) end
    end
    dailyClaimThreads = {}
end

-- ============================================
-- GET SPINS BACKEND FUNCTIONS
-- ============================================

local function startGetSpins()
    if getSpinsThread then return end
    
    getSpinsThread = task.spawn(function()
        while getSpinsActive do
            pcall(function()
                local args = {"Spins", 10}
                game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("AddWheelSpinValue"):FireServer(unpack(args))
                getSpinsCount = getSpinsCount + 1
            end)
            wait(0.1)
        end
    end)
end

local function stopGetSpins()
    getSpinsActive = false
    if getSpinsThread then
        task.cancel(getSpinsThread)
        getSpinsThread = nil
    end
end

-- KEY SYSTEM SETTINGS
local KeySystemEnabled = true
local KeySettings = {
Title = "PRIME Hub",
Subtitle = "Key System",
Note = "Click 'Get Key' button to obtain the key",
FileName = "PRIMEHub_Key",
SaveKey = true,
GrabKeyFromSite = true,
Key = {"https://pastebin.com/raw/CD4DyVWc"}
}

local function getSavedKey()
if readfile then
local success, result = pcall(function()
    return readfile(KeySettings.FileName .. ".txt")
end)
if success and result then
    return result
end
end
return nil
end

local function saveKeyToFile(key)
if writefile then
pcall(function()
    writefile(KeySettings.FileName .. ".txt", key)
end)
end
end

local function getKeyFromSite(url)
local success, result = pcall(function()
return game:HttpGet(url, true)
end)
if success and result then
return result:gsub("%s+", ""):gsub("\n", ""):gsub("\r", "")
end
return nil
end

local savedKey = getSavedKey()

-- Key GUI
local KeyGui = Instance.new("ScreenGui")
KeyGui.Name = "PRIMEHubKeyGUI"
KeyGui.ResetOnSpawn = false
KeyGui.Parent = player:WaitForChild("PlayerGui")

local KeyFrame = Instance.new("Frame")
KeyFrame.Size = UDim2.new(0, 400, 0, 250)
KeyFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
KeyFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
KeyFrame.BorderSizePixel = 0
KeyFrame.Parent = KeyGui

Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 12)

local KeyStroke = Instance.new("UIStroke")
KeyStroke.Thickness = 2
KeyStroke.Color = Color3.fromRGB(0, 255, 255)
KeyStroke.Parent = KeyFrame

local KeyGradient = Instance.new("UIGradient")
KeyGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
KeyGradient.Rotation = 45
KeyGradient.Parent = KeyFrame

local KeyTitle = Instance.new("TextLabel")
KeyTitle.Size = UDim2.new(1, 0, 0, 50)
KeyTitle.BackgroundTransparency = 1
KeyTitle.Text = KeySettings.Title .. " - " .. KeySettings.Subtitle
KeyTitle.Font = Enum.Font.GothamBold
KeyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyTitle.TextSize = 20
KeyTitle.Parent = KeyFrame

local KeyNote = Instance.new("TextLabel")
KeyNote.Size = UDim2.new(1, -20, 0, 30)
KeyNote.Position = UDim2.new(0, 10, 0, 50)
KeyNote.BackgroundTransparency = 1
KeyNote.Text = KeySettings.Note
KeyNote.Font = Enum.Font.Gotham
KeyNote.TextColor3 = Color3.fromRGB(200, 200, 200)
KeyNote.TextSize = 12
KeyNote.TextWrapped = true
KeyNote.Parent = KeyFrame

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(0, 350, 0, 40)
KeyBox.Position = UDim2.new(0.5, -175, 0, 90)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeyBox.BorderSizePixel = 0
KeyBox.PlaceholderText = "Enter Key Here..."
KeyBox.Text = ""
KeyBox.Font = Enum.Font.Gotham
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 16
KeyBox.Parent = KeyFrame

Instance.new("UICorner", KeyBox).CornerRadius = UDim.new(0, 8)

-- Auto-remove spaces when typing
KeyBox:GetPropertyChangedSignal("Text"):Connect(function()
local text = KeyBox.Text
local cleanText = text:gsub(" ", "")
if text ~= cleanText then
    KeyBox.Text = cleanText
end
end)

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0, 350, 0, 40)
GetKeyBtn.Position = UDim2.new(0.5, -175, 0, 145)
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
GetKeyBtn.Text = "Get Key"
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetKeyBtn.TextSize = 18
GetKeyBtn.BorderSizePixel = 0
GetKeyBtn.Parent = KeyFrame

Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 8)

local SubmitKeyBtn = Instance.new("TextButton")
SubmitKeyBtn.Size = UDim2.new(0, 350, 0, 40)
SubmitKeyBtn.Position = UDim2.new(0.5, -175, 0, 200)
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
SubmitKeyBtn.Text = "Submit Key"
SubmitKeyBtn.Font = Enum.Font.GothamBold
SubmitKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubmitKeyBtn.TextSize = 18
SubmitKeyBtn.BorderSizePixel = 0
SubmitKeyBtn.Parent = KeyFrame

Instance.new("UICorner", SubmitKeyBtn).CornerRadius = UDim.new(0, 8)

GetKeyBtn.MouseButton1Click:Connect(function()
setclipboard("https://direct-link.net/1462308/RRaO8s6Woee8")
game.StarterGui:SetCore("SendNotification", {
Title = "PRIME Hub",
Text = "Key link copied to clipboard!",
Duration = 5
})
end)

local function verifyKey(inputKey)
local cleanInput = inputKey:gsub("%s+", ""):gsub("\n", ""):gsub("\r", "")

for _, keyValue in pairs(KeySettings.Key) do
if KeySettings.GrabKeyFromSite then
    local siteKey = getKeyFromSite(keyValue)
    if siteKey and cleanInput == siteKey then
        return true
    end
else
    local cleanKey = keyValue:gsub("%s+", ""):gsub("\n", ""):gsub("\r", "")
    if cleanInput == cleanKey then
        return true
    end
end
end

return false
end

local keyVerified = false

if KeySettings.SaveKey and savedKey and verifyKey(savedKey) then
keyVerified = true
KeyGui:Destroy()
else
SubmitKeyBtn.MouseButton1Click:Connect(function()
SubmitKeyBtn.Text = "Checking..."
SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(200, 150, 0)

wait(0.3)

local inputKey = KeyBox.Text
if verifyKey(inputKey) then
    keyVerified = true
    if KeySettings.SaveKey then
        saveKeyToFile(inputKey:gsub("%s+", ""))
    end
    game.StarterGui:SetCore("SendNotification", {
        Title = "PRIME Hub",
        Text = "Key Verified! Loading...",
        Duration = 3
    })
    wait(0.3)
    KeyGui:Destroy()
else
    SubmitKeyBtn.Text = "Submit Key"
    SubmitKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 220, 50)
    game.StarterGui:SetCore("SendNotification", {
        Title = "PRIME Hub",
        Text = "Invalid Key! Check Pastebin link",
        Duration = 3
    })
end
end)

repeat wait() until keyVerified
end

-- Main Script
game.StarterGui:SetCore("SendNotification", {
Title = "PRIME Hub",
Text = "Loaded | By WENDIGO",
Duration = 7
})

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PRIMEHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 500, 0, 350)
MainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 3
MainStroke.Color = Color3.fromRGB(0, 255, 255)
MainStroke.Transparency = 0.3
MainStroke.Parent = MainFrame

local MainStrokeGradient = Instance.new("UIGradient")
MainStrokeGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 255))
})
MainStrokeGradient.Rotation = 45
MainStrokeGradient.Parent = MainStroke

local Gradient = Instance.new("UIGradient")
Gradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 25)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 10, 15)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
})
Gradient.Rotation = 90
Gradient.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(0, 200, 200)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 220, 220)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 180, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 150, 255))
})
TopGradient.Rotation = 45
TopGradient.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 200, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PRIME Hub"
Title.Font = Enum.Font.GothamBold
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 30, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -70, 0.5, -15)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
MinimizeBtn.Text = "-"
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 20
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Parent = TopBar

Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TopBar

Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

local draggingMain = false
local dragInputMain
local dragStartMain
local startPosMain

local function updateMain(input)
local delta = input.Position - dragStartMain
MainFrame.Position = UDim2.new(startPosMain.X.Scale, startPosMain.X.Offset + delta.X, startPosMain.Y.Scale, startPosMain.Y.Offset + delta.Y)
end

TopBar.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
draggingMain = true
dragStartMain = input.Position
startPosMain = MainFrame.Position

input.Changed:Connect(function()
    if input.UserInputState == Enum.UserInputState.End then
        draggingMain = false
    end
end)
end
end)

TopBar.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInputMain = input
end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
if input == dragInputMain and draggingMain then
updateMain(input)
end
end)

local LeftSection = Instance.new("ScrollingFrame")
LeftSection.Size = UDim2.new(0, 150, 1, -50)
LeftSection.Position = UDim2.new(0, 5, 0, 45)
LeftSection.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
LeftSection.BackgroundTransparency = 0.2
LeftSection.BorderSizePixel = 0
LeftSection.ScrollBarThickness = 6
LeftSection.CanvasSize = UDim2.new(0, 0, 0, 0)
LeftSection.Parent = MainFrame

Instance.new("UICorner", LeftSection).CornerRadius = UDim.new(0, 8)

local LeftSectionGradient = Instance.new("UIGradient")
LeftSectionGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 35)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 25))
})
LeftSectionGradient.Rotation = 90
LeftSectionGradient.Parent = LeftSection

local LeftListLayout = Instance.new("UIListLayout")
LeftListLayout.Padding = UDim.new(0, 5)
LeftListLayout.Parent = LeftSection

local RightSection = Instance.new("Frame")
RightSection.Size = UDim2.new(0, 330, 1, -50)
RightSection.Position = UDim2.new(0, 160, 0, 45)
RightSection.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
RightSection.BackgroundTransparency = 0.2
RightSection.BorderSizePixel = 0
RightSection.Visible = false
RightSection.Parent = MainFrame

Instance.new("UICorner", RightSection).CornerRadius = UDim.new(0, 8)

local RightGradient = Instance.new("UIGradient")
RightGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 30, 40)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(15, 20, 30)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 35, 45))
})
RightGradient.Rotation = 135
RightGradient.Parent = RightSection

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -10, 1, -10)
ContentFrame.Position = UDim2.new(0, 5, 0, 5)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.ScrollBarThickness = 6
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = RightSection

local ContentListLayout = Instance.new("UIListLayout")
ContentListLayout.Padding = UDim.new(0, 10)
ContentListLayout.Parent = ContentFrame

local ToggleButton = Instance.new("TextButton")
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 10, 0.5, -30)
ToggleButton.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
ToggleButton.Text = "P"
ToggleButton.Font = Enum.Font.GothamBold
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.TextSize = 28
ToggleButton.BorderSizePixel = 0
ToggleButton.Parent = ScreenGui

Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 30)

local ToggleBtnGradient = Instance.new("UIGradient")
ToggleBtnGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
})
ToggleBtnGradient.Rotation = 45
ToggleBtnGradient.Parent = ToggleButton

local dragging = false
local dragInput
local dragStart
local startPos

local function update(input)
local delta = input.Position - dragStart
ToggleButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

ToggleButton.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
dragging = true
dragStart = input.Position
startPos = ToggleButton.Position

input.Changed:Connect(function()
    if input.UserInputState == Enum.UserInputState.End then
        dragging = false
    end
end)
end
end)

ToggleButton.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
dragInput = input
end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
if input == dragInput and dragging then
update(input)
end
end)

ToggleButton.MouseButton1Click:Connect(function()
MainFrame.Visible = not MainFrame.Visible
end)

local isMinimized = false
local originalSize = MainFrame.Size

MinimizeBtn.MouseButton1Click:Connect(function()
isMinimized = not isMinimized
if isMinimized then
MainFrame:TweenSize(UDim2.new(0, 500, 0, 40), "Out", "Quad", 0.3, true)
wait(0.3)
LeftSection.Visible = false
RightSection.Visible = false
else
MainFrame:TweenSize(originalSize, "Out", "Quad", 0.3, true)
wait(0.3)
LeftSection.Visible = true
end
end)

CloseBtn.MouseButton1Click:Connect(function()
ScreenGui:Destroy()
end)

-- THEME SYSTEM
local ThemeColors = {
Default = {
    Primary = Color3.fromRGB(0, 220, 220),
    Secondary = Color3.fromRGB(100, 200, 255),
    Accent = Color3.fromRGB(255, 100, 255),
    Background = Color3.fromRGB(15, 15, 25),
    ButtonGradientStart = Color3.fromRGB(0, 200, 200),
    ButtonGradientEnd = Color3.fromRGB(0, 150, 200),
    TextColor = Color3.fromRGB(255, 255, 255),
    Highlight = Color3.fromRGB(0, 255, 255)
},
["Dark Green"] = {
    Primary = Color3.fromRGB(0, 220, 120),
    Secondary = Color3.fromRGB(50, 200, 150),
    Accent = Color3.fromRGB(100, 255, 150),
    Background = Color3.fromRGB(10, 25, 15),
    ButtonGradientStart = Color3.fromRGB(0, 200, 100),
    ButtonGradientEnd = Color3.fromRGB(0, 150, 80),
    TextColor = Color3.fromRGB(200, 255, 200),
    Highlight = Color3.fromRGB(0, 255, 150)
},
["Dark Blue"] = {
    Primary = Color3.fromRGB(50, 100, 255),
    Secondary = Color3.fromRGB(100, 150, 255),
    Accent = Color3.fromRGB(150, 200, 255),
    Background = Color3.fromRGB(10, 15, 30),
    ButtonGradientStart = Color3.fromRGB(40, 80, 220),
    ButtonGradientEnd = Color3.fromRGB(80, 120, 255),
    TextColor = Color3.fromRGB(200, 220, 255),
    Highlight = Color3.fromRGB(100, 180, 255)
},
["Purple Rose"] = {
    Primary = Color3.fromRGB(200, 50, 200),
    Secondary = Color3.fromRGB(255, 100, 255),
    Accent = Color3.fromRGB(255, 150, 255),
    Background = Color3.fromRGB(25, 10, 25),
    ButtonGradientStart = Color3.fromRGB(180, 40, 180),
    ButtonGradientEnd = Color3.fromRGB(220, 80, 220),
    TextColor = Color3.fromRGB(255, 200, 255),
    Highlight = Color3.fromRGB(255, 100, 255)
},
Skeet = {
    Primary = Color3.fromRGB(150, 220, 50),
    Secondary = Color3.fromRGB(200, 255, 100),
    Accent = Color3.fromRGB(255, 255, 150),
    Background = Color3.fromRGB(15, 20, 10),
    ButtonGradientStart = Color3.fromRGB(130, 200, 40),
    ButtonGradientEnd = Color3.fromRGB(170, 240, 80),
    TextColor = Color3.fromRGB(220, 255, 180),
    Highlight = Color3.fromRGB(180, 255, 80)
}
}

local currentTheme = "Default"
local ButtonGradients = {}
local ButtonTexts = {}
local SectionTitles = {}

local function applyTheme(themeName)
local theme = ThemeColors[themeName]
if not theme then return end

currentTheme = themeName

Gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.Background),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(theme.Background.R * 0.8, theme.Background.G * 0.8, theme.Background.B * 0.8)),
    ColorSequenceKeypoint.new(1, theme.Background)
})

MainStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.Primary),
    ColorSequenceKeypoint.new(0.5, theme.Secondary),
    ColorSequenceKeypoint.new(1, theme.Accent)
})

TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.Primary),
    ColorSequenceKeypoint.new(0.5, theme.Secondary),
    ColorSequenceKeypoint.new(1, theme.Accent)
})

LeftSectionGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(theme.Background.R * 1.5, theme.Background.G * 1.5, theme.Background.B * 1.5)),
    ColorSequenceKeypoint.new(1, theme.Background)
})

RightGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(theme.Background.R * 1.8, theme.Background.G * 1.8, theme.Background.B * 1.8)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(theme.Background.R * 1.2, theme.Background.G * 1.2, theme.Background.B * 1.2)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(theme.Background.R * 1.5, theme.Background.G * 1.5, theme.Background.B * 1.5))
})

ToggleBtnGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, theme.Secondary),
    ColorSequenceKeypoint.new(1, theme.Accent)
})

for _, gradient in pairs(ButtonGradients) do
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.ButtonGradientStart),
        ColorSequenceKeypoint.new(1, theme.ButtonGradientEnd)
    })
end

for _, textLabel in pairs(ButtonTexts) do
    textLabel.TextColor3 = theme.TextColor
end

for _, titleLabel in pairs(SectionTitles) do
    titleLabel.TextColor3 = theme.Highlight
end

game.StarterGui:SetCore("SendNotification", {
    Title = "PRIME Hub",
    Text = "Theme changed to " .. themeName,
    Duration = 2
})
end

-- GAME SECTION BUTTON
local GameBtn = Instance.new("TextButton")
GameBtn.Size = UDim2.new(1, -10, 0, 35)
GameBtn.Text = "Game"
GameBtn.Font = Enum.Font.GothamBold
GameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GameBtn.TextSize = 16
GameBtn.BorderSizePixel = 0
GameBtn.Parent = LeftSection

Instance.new("UICorner", GameBtn).CornerRadius = UDim.new(0, 6)

local GameBtnGradient = Instance.new("UIGradient")
GameBtnGradient.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
})
GameBtnGradient.Rotation = 45
GameBtnGradient.Parent = GameBtn

ButtonGradients["Game"] = GameBtnGradient
ButtonTexts["Game"] = GameBtn

local GameContainer = Instance.new("Frame")
GameContainer.Size = UDim2.new(1, -20, 1, -60)
GameContainer.Position = UDim2.new(0, 10, 0, 50)
GameContainer.BackgroundTransparency = 1
GameContainer.BorderSizePixel = 0
GameContainer.Visible = false
GameContainer.Parent = ContentFrame

local GameContent = Instance.new("TextLabel")
GameContent.Size = UDim2.new(1, 0, 1, 0)
GameContent.BackgroundTransparency = 1
GameContent.TextColor3 = Color3.fromRGB(200, 200, 200)
GameContent.TextSize = 14
GameContent.Font = Enum.Font.Gotham
GameContent.TextWrapped = true
GameContent.TextXAlignment = Enum.TextXAlignment.Left
GameContent.TextYAlignment = Enum.TextYAlignment.Top
GameContent.Text = ""
GameContent.Parent = GameContainer

-- KILL FARM SECTION BUTTON
local KillFarmBtn = Instance.new("TextButton")
KillFarmBtn.Size = UDim2.new(1, -10, 0, 35)
KillFarmBtn.Text = "Kill Farm"
KillFarmBtn.Font = Enum.Font.GothamBold
KillFarmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillFarmBtn.TextSize = 16
KillFarmBtn.BorderSizePixel = 0
KillFarmBtn.Parent = LeftSection

Instance.new("UICorner", KillFarmBtn).CornerRadius = UDim.new(0, 6)

local KillFarmBtnGradient = Instance.new("UIGradient")
KillFarmBtnGradient.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 50))
})
KillFarmBtnGradient.Rotation = 45
KillFarmBtnGradient.Parent = KillFarmBtn

ButtonGradients["KillFarm"] = KillFarmBtnGradient
ButtonTexts["KillFarm"] = KillFarmBtn

local KillFarmContainer = Instance.new("Frame")
KillFarmContainer.Size = UDim2.new(1, -20, 1, -60)
KillFarmContainer.Position = UDim2.new(0, 10, 0, 50)
KillFarmContainer.BackgroundTransparency = 1
KillFarmContainer.BorderSizePixel = 0
KillFarmContainer.Visible = false
KillFarmContainer.Parent = ContentFrame

-- Kill Farm Toggle Button
local KillFarmToggleBtn = Instance.new("TextButton")
KillFarmToggleBtn.Size = UDim2.new(1, 0, 0, 40)
KillFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
KillFarmToggleBtn.Text = "Start Kill Farm"
KillFarmToggleBtn.Font = Enum.Font.GothamBold
KillFarmToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KillFarmToggleBtn.TextSize = 14
KillFarmToggleBtn.BorderSizePixel = 0
KillFarmToggleBtn.Parent = KillFarmContainer

Instance.new("UICorner", KillFarmToggleBtn).CornerRadius = UDim.new(0, 6)

-- Kill Farm Status Label
local KillFarmStatusLabel = Instance.new("TextLabel")
KillFarmStatusLabel.Size = UDim2.new(1, -20, 0, 30)
KillFarmStatusLabel.Position = UDim2.new(0, 10, 0, 50)
KillFarmStatusLabel.BackgroundTransparency = 1
KillFarmStatusLabel.Text = "Status: Inactive"
KillFarmStatusLabel.Font = Enum.Font.GothamBold
KillFarmStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
KillFarmStatusLabel.TextSize = 12
KillFarmStatusLabel.Parent = KillFarmContainer

-- Delay Label
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(1, -20, 0, 20)
DelayLabel.Position = UDim2.new(0, 10, 0, 85)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Delay: 0.1s"
DelayLabel.Font = Enum.Font.GothamBold
DelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayLabel.TextSize = 13
DelayLabel.Parent = KillFarmContainer

-- Slider Background
local SliderBg = Instance.new("Frame")
SliderBg.Size = UDim2.new(1, -20, 0, 20)
SliderBg.Position = UDim2.new(0, 10, 0, 110)
SliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SliderBg.BorderSizePixel = 0
SliderBg.Parent = KillFarmContainer

Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(0, 10)

local SliderStroke = Instance.new("UIStroke")
SliderStroke.Thickness = 1
SliderStroke.Color = Color3.fromRGB(80, 80, 120)
SliderStroke.Transparency = 0.5
SliderStroke.Parent = SliderBg

-- Slider Fill
local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.2, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBg

Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(0, 10)

local FillGradient = Instance.new("UIGradient")
FillGradient.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 200))
})
FillGradient.Rotation = 45
FillGradient.Parent = SliderFill

-- Slider Button
local SliderButton = Instance.new("TextButton")
SliderButton.Size = UDim2.new(0, 30, 0, 30)
SliderButton.Position = UDim2.new(0.2, -15, 0.5, -15)
SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderButton.Text = ""
SliderButton.BorderSizePixel = 0
SliderButton.Parent = SliderBg

Instance.new("UICorner", SliderButton).CornerRadius = UDim.new(1, 0)

local ButtonInnerStroke = Instance.new("UIStroke")
ButtonInnerStroke.Thickness = 3
ButtonInnerStroke.Color = Color3.fromRGB(100, 150, 255)
ButtonInnerStroke.Parent = SliderButton

-- Slider Logic
local draggingSlider = false
local minDelay = 0.1
local maxDelay = 1.0

local function updateSlider(input)
  local relativeX = math.clamp(input.Position.X - SliderBg.AbsolutePosition.X, 0, SliderBg.AbsoluteSize.X)
  local percentage = relativeX / SliderBg.AbsoluteSize.X

  SliderButton.Position = UDim2.new(percentage, -15, 0.5, -15)
  SliderFill.Size = UDim2.new(percentage, 0, 1, 0)

  loopDelay = minDelay + (percentage * (maxDelay - minDelay))
  DelayLabel.Text = string.format("Delay: %.2fs", loopDelay)
end

SliderButton.MouseButton1Down:Connect(function()
  draggingSlider = true
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
      draggingSlider = false
  end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
  if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
      updateSlider(input)
  end
end)

SliderBg.InputBegan:Connect(function(input)
  if input.UserInputType == Enum.UserInputType.MouseButton1 then
      updateSlider(input)
  end
end)

-- Kill Farm Toggle Logic
KillFarmToggleBtn.MouseButton1Click:Connect(function()
  killFarmActive = not killFarmActive

  if killFarmActive then
      KillFarmToggleBtn.Text = "Stop Kill Farm"
      KillFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
      KillFarmStatusLabel.Text = "Status: Active - Targeting Players"
      startKillFarm()

      game.StarterGui:SetCore("SendNotification", {
          Title = "PRIME Hub",
          Text = "Kill Farm Started!",
          Duration = 2
      })
  else
      KillFarmToggleBtn.Text = "Start Kill Farm"
      KillFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
      KillFarmStatusLabel.Text = "Status: Inactive"
      stopKillFarm()

      game.StarterGui:SetCore("SendNotification", {
          Title = "PRIME Hub",
          Text = "Kill Farm Stopped!",
          Duration = 2
      })
  end
end)

-- GET ITEMS SECTION BUTTON
local GetItemsBtn = Instance.new("TextButton")
GetItemsBtn.Size = UDim2.new(1, -10, 0, 35)
GetItemsBtn.Text = "Get Items"
GetItemsBtn.Font = Enum.Font.GothamBold
GetItemsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetItemsBtn.TextSize = 16
GetItemsBtn.BorderSizePixel = 0
GetItemsBtn.Parent = LeftSection

Instance.new("UICorner", GetItemsBtn).CornerRadius = UDim.new(0, 6)

local GetItemsBtnGradient = Instance.new("UIGradient")
GetItemsBtnGradient.Color = ColorSequence.new({
  ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 100)),
  ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 50))
})
GetItemsBtnGradient.Rotation = 45
GetItemsBtnGradient.Parent = GetItemsBtn

ButtonGradients["GetItems"] = GetItemsBtnGradient
ButtonTexts["GetItems"] = GetItemsBtn

local GetItemsContainer = Instance.new("ScrollingFrame")
GetItemsContainer.Size = UDim2.new(1, -20, 1, -60)
GetItemsContainer.Position = UDim2.new(0, 10, 0, 50)
GetItemsContainer.BackgroundTransparency = 1
GetItemsContainer.BorderSizePixel = 0
GetItemsContainer.Visible = false
GetItemsContainer.ScrollBarThickness = 8
GetItemsContainer.CanvasSize = UDim2.new(0, 0, 0, 900)
GetItemsContainer.Parent = ContentFrame

-- ============================================
-- POWER FARM UI ELEMENTS
-- ============================================

local PowerFarmToggleBtn = Instance.new("TextButton")
PowerFarmToggleBtn.Size = UDim2.new(1, 0, 0, 45)
PowerFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
PowerFarmToggleBtn.Text = "Get Power - OFF"
PowerFarmToggleBtn.Font = Enum.Font.GothamBold
PowerFarmToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PowerFarmToggleBtn.TextSize = 16
PowerFarmToggleBtn.BorderSizePixel = 0
PowerFarmToggleBtn.Parent = GetItemsContainer

Instance.new("UICorner", PowerFarmToggleBtn).CornerRadius = UDim.new(0, 8)

local PowerToggleGradient = Instance.new("UIGradient")
PowerToggleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
})
PowerToggleGradient.Rotation = 45
PowerToggleGradient.Parent = PowerFarmToggleBtn

local DividerLine = Instance.new("Frame")
DividerLine.Size = UDim2.new(1, 0, 0, 2)
DividerLine.Position = UDim2.new(0, 0, 0, 55)
DividerLine.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
DividerLine.BorderSizePixel = 0
DividerLine.Parent = GetItemsContainer

local WarningLabel = Instance.new("TextLabel")
WarningLabel.Size = UDim2.new(1, -20, 0, 25)
WarningLabel.Position = UDim2.new(0, 10, 0, 65)
WarningLabel.BackgroundTransparency = 1
WarningLabel.Text = "⚠️ Can create lag depending on device"
WarningLabel.Font = Enum.Font.GothamBold
WarningLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
WarningLabel.TextSize = 11
WarningLabel.Parent = GetItemsContainer

local PowerAmountLabel = Instance.new("TextLabel")
PowerAmountLabel.Size = UDim2.new(1, -20, 0, 20)
PowerAmountLabel.Position = UDim2.new(0, 10, 0, 100)
PowerAmountLabel.BackgroundTransparency = 1
PowerAmountLabel.Text = "Power Amount: 99999999999"
PowerAmountLabel.Font = Enum.Font.GothamBold
PowerAmountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
PowerAmountLabel.TextSize = 13
PowerAmountLabel.TextXAlignment = Enum.TextXAlignment.Left
PowerAmountLabel.Parent = GetItemsContainer

local PowerAmountSliderBg = Instance.new("Frame")
PowerAmountSliderBg.Size = UDim2.new(1, -20, 0, 20)
PowerAmountSliderBg.Position = UDim2.new(0, 10, 0, 125)
PowerAmountSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
PowerAmountSliderBg.BorderSizePixel = 0
PowerAmountSliderBg.Parent = GetItemsContainer

Instance.new("UICorner", PowerAmountSliderBg).CornerRadius = UDim.new(0, 10)

local PowerAmountSliderStroke = Instance.new("UIStroke")
PowerAmountSliderStroke.Thickness = 1
PowerAmountSliderStroke.Color = Color3.fromRGB(80, 80, 120)
PowerAmountSliderStroke.Transparency = 0.5
PowerAmountSliderStroke.Parent = PowerAmountSliderBg

local PowerAmountSliderFill = Instance.new("Frame")
PowerAmountSliderFill.Size = UDim2.new(1, 0, 1, 0)
PowerAmountSliderFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
PowerAmountSliderFill.BorderSizePixel = 0
PowerAmountSliderFill.Parent = PowerAmountSliderBg

Instance.new("UICorner", PowerAmountSliderFill).CornerRadius = UDim.new(0, 10)

local PowerAmountFillGradient = Instance.new("UIGradient")
PowerAmountFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
})
PowerAmountFillGradient.Rotation = 45
PowerAmountFillGradient.Parent = PowerAmountSliderFill

local PowerAmountSliderButton = Instance.new("TextButton")
PowerAmountSliderButton.Size = UDim2.new(0, 30, 0, 30)
PowerAmountSliderButton.Position = UDim2.new(1, -15, 0.5, -15)
PowerAmountSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PowerAmountSliderButton.Text = ""
PowerAmountSliderButton.BorderSizePixel = 0
PowerAmountSliderButton.Parent = PowerAmountSliderBg

Instance.new("UICorner", PowerAmountSliderButton).CornerRadius = UDim.new(1, 0)

local PowerAmountButtonStroke = Instance.new("UIStroke")
PowerAmountButtonStroke.Thickness = 3
PowerAmountButtonStroke.Color = Color3.fromRGB(255, 200, 0)
PowerAmountButtonStroke.Parent = PowerAmountSliderButton

local MultiplierLabel = Instance.new("TextLabel")
MultiplierLabel.Size = UDim2.new(1, -20, 0, 20)
MultiplierLabel.Position = UDim2.new(0, 10, 0, 155)
MultiplierLabel.BackgroundTransparency = 1
MultiplierLabel.Text = "Multiplier: x1"
MultiplierLabel.Font = Enum.Font.GothamBold
MultiplierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MultiplierLabel.TextSize = 13
MultiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
MultiplierLabel.Parent = GetItemsContainer

local MultiplierSliderBg = Instance.new("Frame")
MultiplierSliderBg.Size = UDim2.new(1, -20, 0, 20)
MultiplierSliderBg.Position = UDim2.new(0, 10, 0, 180)
MultiplierSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
MultiplierSliderBg.BorderSizePixel = 0
MultiplierSliderBg.Parent = GetItemsContainer

Instance.new("UICorner", MultiplierSliderBg).CornerRadius = UDim.new(0, 10)

local MultiplierSliderStroke = Instance.new("UIStroke")
MultiplierSliderStroke.Thickness = 1
MultiplierSliderStroke.Color = Color3.fromRGB(80, 80, 120)
MultiplierSliderStroke.Transparency = 0.5
MultiplierSliderStroke.Parent = MultiplierSliderBg

local MultiplierSliderFill = Instance.new("Frame")
MultiplierSliderFill.Size = UDim2.new(0, 0, 1, 0)
MultiplierSliderFill.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
MultiplierSliderFill.BorderSizePixel = 0
MultiplierSliderFill.Parent = MultiplierSliderBg

Instance.new("UICorner", MultiplierSliderFill).CornerRadius = UDim.new(0, 10)

local MultiplierFillGradient = Instance.new("UIGradient")
MultiplierFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 100))
})
MultiplierFillGradient.Rotation = 45
MultiplierFillGradient.Parent = MultiplierSliderFill

local MultiplierSliderButton = Instance.new("TextButton")
MultiplierSliderButton.Size = UDim2.new(0, 30, 0, 30)
MultiplierSliderButton.Position = UDim2.new(0, -15, 0.5, -15)
MultiplierSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MultiplierSliderButton.Text = ""
MultiplierSliderButton.BorderSizePixel = 0
MultiplierSliderButton.Parent = MultiplierSliderBg

Instance.new("UICorner", MultiplierSliderButton).CornerRadius = UDim.new(1, 0)

local MultiplierButtonStroke = Instance.new("UIStroke")
MultiplierButtonStroke.Thickness = 3
MultiplierButtonStroke.Color = Color3.fromRGB(100, 255, 150)
MultiplierButtonStroke.Parent = MultiplierSliderButton

local MultiplierWarning = Instance.new("TextLabel")
MultiplierWarning.Size = UDim2.new(1, -20, 0, 20)
MultiplierWarning.Position = UDim2.new(0, 10, 0, 205)
MultiplierWarning.BackgroundTransparency = 1
MultiplierWarning.Text = "⚠️ Higher multiplier = More lag"
MultiplierWarning.Font = Enum.Font.Gotham
MultiplierWarning.TextColor3 = Color3.fromRGB(255, 150, 0)
MultiplierWarning.TextSize = 10
MultiplierWarning.Parent = GetItemsContainer

local PowerStatusLabel = Instance.new("TextLabel")
PowerStatusLabel.Size = UDim2.new(1, -20, 0, 30)
PowerStatusLabel.Position = UDim2.new(0, 10, 0, 235)
PowerStatusLabel.BackgroundTransparency = 1
PowerStatusLabel.Text = "Status: Inactive"
PowerStatusLabel.Font = Enum.Font.GothamBold
PowerStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PowerStatusLabel.TextSize = 12
PowerStatusLabel.Parent = GetItemsContainer

-- Power Amount Slider Logic
local draggingPowerSlider = false
local minPower = 0
local maxPower = 99999999999

local function updatePowerSlider(input)
    local relativeX = math.clamp(input.Position.X - PowerAmountSliderBg.AbsolutePosition.X, 0, PowerAmountSliderBg.AbsoluteSize.X)
    local percentage = relativeX / PowerAmountSliderBg.AbsoluteSize.X
    
    PowerAmountSliderButton.Position = UDim2.new(percentage, -15, 0.5, -15)
    PowerAmountSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    
    powerAmount = math.floor(minPower + (percentage * (maxPower - minPower)))
    PowerAmountLabel.Text = string.format("Power Amount: %d", powerAmount)
end

PowerAmountSliderButton.MouseButton1Down:Connect(function()
    draggingPowerSlider = true
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingPowerSlider = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingPowerSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updatePowerSlider(input)
    end
end)

PowerAmountSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updatePowerSlider(input)
    end
end)

-- Multiplier Slider Logic
local draggingMultiplierSlider = false
local minMultiplier = 1
local maxMultiplier = 200

local function updateMultiplierSlider(input)
    local relativeX = math.clamp(input.Position.X - MultiplierSliderBg.AbsolutePosition.X, 0, MultiplierSliderBg.AbsoluteSize.X)
    local percentage = relativeX / MultiplierSliderBg.AbsoluteSize.X
    
    MultiplierSliderButton.Position = UDim2.new(percentage, -15, 0.5, -15)
    MultiplierSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    
    powerMultiplier = math.floor(minMultiplier + (percentage * (maxMultiplier - minMultiplier)))
    MultiplierLabel.Text = string.format("Multiplier: x%d", powerMultiplier)
end

MultiplierSliderButton.MouseButton1Down:Connect(function()
    draggingMultiplierSlider = true
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingMultiplierSlider = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingMultiplierSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateMultiplierSlider(input)
    end
end)

MultiplierSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updateMultiplierSlider(input)
    end
end)

-- Toggle Button Logic
PowerFarmToggleBtn.MouseButton1Click:Connect(function()
    powerFarmActive = not powerFarmActive
    
    if powerFarmActive then
        PowerFarmToggleBtn.Text = "Get Power - ON"
        PowerFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        PowerToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 200, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 150, 30))
        })
        PowerStatusLabel.Text = string.format("Status: Running x%d threads", powerMultiplier)
        
        startPowerFarm()
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = string.format("Power Farm Started! (x%d)", powerMultiplier),
            Duration = 2
        })
    else
        PowerFarmToggleBtn.Text = "Get Power - OFF"
        PowerFarmToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        PowerToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
        })
        
        stopPowerFarm()
        PowerStatusLabel.Text = "Status: Inactive"
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = "Power Farm Stopped!",
            Duration = 2
        })
    end
end)

-- ============================================
-- DAILY CLAIM SECTION
-- ============================================

-- Spacer
local DailyClaimSpacer = Instance.new("Frame")
DailyClaimSpacer.Size = UDim2.new(1, 0, 0, 20)
DailyClaimSpacer.Position = UDim2.new(0, 0, 0, 270)
DailyClaimSpacer.BackgroundTransparency = 1
DailyClaimSpacer.Parent = GetItemsContainer

-- Title
local DailyClaimTitle = Instance.new("TextLabel")
DailyClaimTitle.Size = UDim2.new(1, -20, 0, 25)
DailyClaimTitle.Position = UDim2.new(0, 10, 0, 290)
DailyClaimTitle.BackgroundTransparency = 1
DailyClaimTitle.Text = "━━━━━ Daily Claim ━━━━━"
DailyClaimTitle.Font = Enum.Font.GothamBold
DailyClaimTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
DailyClaimTitle.TextSize = 14
DailyClaimTitle.Parent = GetItemsContainer

-- Toggle Button
local DailyClaimToggleBtn = Instance.new("TextButton")
DailyClaimToggleBtn.Size = UDim2.new(1, 0, 0, 45)
DailyClaimToggleBtn.Position = UDim2.new(0, 0, 0, 320)
DailyClaimToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
DailyClaimToggleBtn.Text = "Auto Claim - OFF"
DailyClaimToggleBtn.Font = Enum.Font.GothamBold
DailyClaimToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
DailyClaimToggleBtn.TextSize = 16
DailyClaimToggleBtn.BorderSizePixel = 0
DailyClaimToggleBtn.Parent = GetItemsContainer

Instance.new("UICorner", DailyClaimToggleBtn).CornerRadius = UDim.new(0, 8)

local DailyClaimToggleGradient = Instance.new("UIGradient")
DailyClaimToggleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
})
DailyClaimToggleGradient.Rotation = 45
DailyClaimToggleGradient.Parent = DailyClaimToggleBtn

-- Divider
local DailyClaimDivider = Instance.new("Frame")
DailyClaimDivider.Size = UDim2.new(1, 0, 0, 2)
DailyClaimDivider.Position = UDim2.new(0, 0, 0, 375)
DailyClaimDivider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
DailyClaimDivider.BorderSizePixel = 0
DailyClaimDivider.Parent = GetItemsContainer

-- Warning Label
local DailyClaimWarning = Instance.new("TextLabel")
DailyClaimWarning.Size = UDim2.new(1, -20, 0, 20)
DailyClaimWarning.Position = UDim2.new(0, 10, 0, 385)
DailyClaimWarning.BackgroundTransparency = 1
DailyClaimWarning.Text = "⚠️ Can create lag depending on device"
DailyClaimWarning.Font = Enum.Font.GothamBold
DailyClaimWarning.TextColor3 = Color3.fromRGB(255, 200, 0)
DailyClaimWarning.TextSize = 11
DailyClaimWarning.Parent = GetItemsContainer

-- Delay Label
local DailyClaimDelayLabel = Instance.new("TextLabel")
DailyClaimDelayLabel.Size = UDim2.new(1, -20, 0, 20)
DailyClaimDelayLabel.Position = UDim2.new(0, 10, 0, 415)
DailyClaimDelayLabel.BackgroundTransparency = 1
DailyClaimDelayLabel.Text = "Delay: 0.1s"
DailyClaimDelayLabel.Font = Enum.Font.GothamBold
DailyClaimDelayLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DailyClaimDelayLabel.TextSize = 13
DailyClaimDelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DailyClaimDelayLabel.Parent = GetItemsContainer

-- Delay Slider Background
local DailyClaimDelaySliderBg = Instance.new("Frame")
DailyClaimDelaySliderBg.Size = UDim2.new(1, -20, 0, 20)
DailyClaimDelaySliderBg.Position = UDim2.new(0, 10, 0, 440)
DailyClaimDelaySliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
DailyClaimDelaySliderBg.BorderSizePixel = 0
DailyClaimDelaySliderBg.Parent = GetItemsContainer

Instance.new("UICorner", DailyClaimDelaySliderBg).CornerRadius = UDim.new(0, 10)

local DailyClaimDelaySliderStroke = Instance.new("UIStroke")
DailyClaimDelaySliderStroke.Thickness = 1
DailyClaimDelaySliderStroke.Color = Color3.fromRGB(80, 80, 120)
DailyClaimDelaySliderStroke.Transparency = 0.5
DailyClaimDelaySliderStroke.Parent = DailyClaimDelaySliderBg

-- Delay Slider Fill
local DailyClaimDelaySliderFill = Instance.new("Frame")
DailyClaimDelaySliderFill.Size = UDim2.new(0.2, 0, 1, 0)
DailyClaimDelaySliderFill.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
DailyClaimDelaySliderFill.BorderSizePixel = 0
DailyClaimDelaySliderFill.Parent = DailyClaimDelaySliderBg

Instance.new("UICorner", DailyClaimDelaySliderFill).CornerRadius = UDim.new(0, 10)

local DailyClaimDelayFillGradient = Instance.new("UIGradient")
DailyClaimDelayFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 120, 200))
})
DailyClaimDelayFillGradient.Rotation = 45
DailyClaimDelayFillGradient.Parent = DailyClaimDelaySliderFill

-- Delay Slider Button
local DailyClaimDelaySliderButton = Instance.new("TextButton")
DailyClaimDelaySliderButton.Size = UDim2.new(0, 30, 0, 30)
DailyClaimDelaySliderButton.Position = UDim2.new(0.2, -15, 0.5, -15)
DailyClaimDelaySliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DailyClaimDelaySliderButton.Text = ""
DailyClaimDelaySliderButton.BorderSizePixel = 0
DailyClaimDelaySliderButton.Parent = DailyClaimDelaySliderBg

Instance.new("UICorner", DailyClaimDelaySliderButton).CornerRadius = UDim.new(1, 0)

local DailyClaimDelayButtonStroke = Instance.new("UIStroke")
DailyClaimDelayButtonStroke.Thickness = 3
DailyClaimDelayButtonStroke.Color = Color3.fromRGB(100, 150, 255)
DailyClaimDelayButtonStroke.Parent = DailyClaimDelaySliderButton

-- Multiplier Label
local DailyClaimMultiplierLabel = Instance.new("TextLabel")
DailyClaimMultiplierLabel.Size = UDim2.new(1, -20, 0, 20)
DailyClaimMultiplierLabel.Position = UDim2.new(0, 10, 0, 470)
DailyClaimMultiplierLabel.BackgroundTransparency = 1
DailyClaimMultiplierLabel.Text = "Multiplier: x1"
DailyClaimMultiplierLabel.Font = Enum.Font.GothamBold
DailyClaimMultiplierLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DailyClaimMultiplierLabel.TextSize = 13
DailyClaimMultiplierLabel.TextXAlignment = Enum.TextXAlignment.Left
DailyClaimMultiplierLabel.Parent = GetItemsContainer

-- Multiplier Slider Background
local DailyClaimMultiplierSliderBg = Instance.new("Frame")
DailyClaimMultiplierSliderBg.Size = UDim2.new(1, -20, 0, 20)
DailyClaimMultiplierSliderBg.Position = UDim2.new(0, 10, 0, 495)
DailyClaimMultiplierSliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
DailyClaimMultiplierSliderBg.BorderSizePixel = 0
DailyClaimMultiplierSliderBg.Parent = GetItemsContainer

Instance.new("UICorner", DailyClaimMultiplierSliderBg).CornerRadius = UDim.new(0, 10)

local DailyClaimMultiplierSliderStroke = Instance.new("UIStroke")
DailyClaimMultiplierSliderStroke.Thickness = 1
DailyClaimMultiplierSliderStroke.Color = Color3.fromRGB(80, 80, 120)
DailyClaimMultiplierSliderStroke.Transparency = 0.5
DailyClaimMultiplierSliderStroke.Parent = DailyClaimMultiplierSliderBg

-- Multiplier Slider Fill
local DailyClaimMultiplierSliderFill = Instance.new("Frame")
DailyClaimMultiplierSliderFill.Size = UDim2.new(0, 0, 1, 0)
DailyClaimMultiplierSliderFill.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
DailyClaimMultiplierSliderFill.BorderSizePixel = 0
DailyClaimMultiplierSliderFill.Parent = DailyClaimMultiplierSliderBg

Instance.new("UICorner", DailyClaimMultiplierSliderFill).CornerRadius = UDim.new(0, 10)

local DailyClaimMultiplierFillGradient = Instance.new("UIGradient")
DailyClaimMultiplierFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 150)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 200, 100))
})
DailyClaimMultiplierFillGradient.Rotation = 45
DailyClaimMultiplierFillGradient.Parent = DailyClaimMultiplierSliderFill

-- Multiplier Slider Button
local DailyClaimMultiplierSliderButton = Instance.new("TextButton")
DailyClaimMultiplierSliderButton.Size = UDim2.new(0, 30, 0, 30)
DailyClaimMultiplierSliderButton.Position = UDim2.new(0, -15, 0.5, -15)
DailyClaimMultiplierSliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
DailyClaimMultiplierSliderButton.Text = ""
DailyClaimMultiplierSliderButton.BorderSizePixel = 0
DailyClaimMultiplierSliderButton.Parent = DailyClaimMultiplierSliderBg

Instance.new("UICorner", DailyClaimMultiplierSliderButton).CornerRadius = UDim.new(1, 0)

local DailyClaimMultiplierButtonStroke = Instance.new("UIStroke")
DailyClaimMultiplierButtonStroke.Thickness = 3
DailyClaimMultiplierButtonStroke.Color = Color3.fromRGB(100, 255, 150)
DailyClaimMultiplierButtonStroke.Parent = DailyClaimMultiplierSliderButton

-- Multiplier Warning
local DailyClaimMultiplierWarning = Instance.new("TextLabel")
DailyClaimMultiplierWarning.Size = UDim2.new(1, -20, 0, 20)
DailyClaimMultiplierWarning.Position = UDim2.new(0, 10, 0, 520)
DailyClaimMultiplierWarning.BackgroundTransparency = 1
DailyClaimMultiplierWarning.Text = "⚠️ Higher multiplier = More lag"
DailyClaimMultiplierWarning.Font = Enum.Font.Gotham
DailyClaimMultiplierWarning.TextColor3 = Color3.fromRGB(255, 150, 0)
DailyClaimMultiplierWarning.TextSize = 10
DailyClaimMultiplierWarning.Parent = GetItemsContainer

-- Status Label
local DailyClaimStatusLabel = Instance.new("TextLabel")
DailyClaimStatusLabel.Size = UDim2.new(1, -20, 0, 25)
DailyClaimStatusLabel.Position = UDim2.new(0, 10, 0, 545)
DailyClaimStatusLabel.BackgroundTransparency = 1
DailyClaimStatusLabel.Text = "Status: Inactive"
DailyClaimStatusLabel.Font = Enum.Font.GothamBold
DailyClaimStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DailyClaimStatusLabel.TextSize = 12
DailyClaimStatusLabel.Parent = GetItemsContainer

-- Delay Slider Logic
local draggingDailyClaimDelaySlider = false
local minDailyClaimDelay = 0.1
local maxDailyClaimDelay = 1.0

local function updateDailyClaimDelaySlider(input)
    local relativeX = math.clamp(input.Position.X - DailyClaimDelaySliderBg.AbsolutePosition.X, 0, DailyClaimDelaySliderBg.AbsoluteSize.X)
    local percentage = relativeX / DailyClaimDelaySliderBg.AbsoluteSize.X
    
    DailyClaimDelaySliderButton.Position = UDim2.new(percentage, -15, 0.5, -15)
    DailyClaimDelaySliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    
    dailyClaimDelay = minDailyClaimDelay + (percentage * (maxDailyClaimDelay - minDailyClaimDelay))
    DailyClaimDelayLabel.Text = string.format("Delay: %.2fs", dailyClaimDelay)
end

DailyClaimDelaySliderButton.MouseButton1Down:Connect(function()
    draggingDailyClaimDelaySlider = true
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingDailyClaimDelaySlider = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingDailyClaimDelaySlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDailyClaimDelaySlider(input)
    end
end)

DailyClaimDelaySliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updateDailyClaimDelaySlider(input)
    end
end)

-- Multiplier Slider Logic
local draggingDailyClaimMultiplierSlider = false
local minDailyClaimMultiplier = 1
local maxDailyClaimMultiplier = 200

local function updateDailyClaimMultiplierSlider(input)
    local relativeX = math.clamp(input.Position.X - DailyClaimMultiplierSliderBg.AbsolutePosition.X, 0, DailyClaimMultiplierSliderBg.AbsoluteSize.X)
    local percentage = relativeX / DailyClaimMultiplierSliderBg.AbsoluteSize.X
    
    DailyClaimMultiplierSliderButton.Position = UDim2.new(percentage, -15, 0.5, -15)
    DailyClaimMultiplierSliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    
    dailyClaimMultiplier = math.floor(minDailyClaimMultiplier + (percentage * (maxDailyClaimMultiplier - minDailyClaimMultiplier)))
    DailyClaimMultiplierLabel.Text = string.format("Multiplier: x%d", dailyClaimMultiplier)
end

DailyClaimMultiplierSliderButton.MouseButton1Down:Connect(function()
    draggingDailyClaimMultiplierSlider = true
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingDailyClaimMultiplierSlider = false
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if draggingDailyClaimMultiplierSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateDailyClaimMultiplierSlider(input)
    end
end)

DailyClaimMultiplierSliderBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        updateDailyClaimMultiplierSlider(input)
    end
end)

-- Toggle Button Logic
DailyClaimToggleBtn.MouseButton1Click:Connect(function()
    dailyClaimActive = not dailyClaimActive
    
    if dailyClaimActive then
        DailyClaimToggleBtn.Text = "Auto Claim - ON"
        DailyClaimToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        DailyClaimToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 200, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 150, 30))
        })
        DailyClaimStatusLabel.Text = string.format("Status: Running x%d threads", dailyClaimMultiplier)
        
        startDailyClaim()
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = string.format("Daily Claim Started! (x%d)", dailyClaimMultiplier),
            Duration = 2
        })
    else
        DailyClaimToggleBtn.Text = "Auto Claim - OFF"
        DailyClaimToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        DailyClaimToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
        })
        
        stopDailyClaim()
        DailyClaimStatusLabel.Text = "Status: Inactive"
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = "Daily Claim Stopped!",
            Duration = 2
        })
    end
end)

-- Real-time Counter Update
task.spawn(function()
    while wait(0.5) do
        if dailyClaimActive then
            DailyClaimStatusLabel.Text = string.format("Status: Running x%d | Claimed: %d", dailyClaimMultiplier, dailyClaimCount)
        end
    end
end)

-- ============================================
-- GET SPINS SECTION
-- ============================================

-- Spacer
local GetSpinsSpacer = Instance.new("Frame")
GetSpinsSpacer.Size = UDim2.new(1, 0, 0, 20)
GetSpinsSpacer.Position = UDim2.new(0, 0, 0, 575)
GetSpinsSpacer.BackgroundTransparency = 1
GetSpinsSpacer.Parent = GetItemsContainer

-- Title Label
local GetSpinsTitle = Instance.new("TextLabel")
GetSpinsTitle.Size = UDim2.new(1, -20, 0, 25)
GetSpinsTitle.Position = UDim2.new(0, 10, 0, 595)
GetSpinsTitle.BackgroundTransparency = 1
GetSpinsTitle.Text = "━━━━━ Get Spins ━━━━━"
GetSpinsTitle.Font = Enum.Font.GothamBold
GetSpinsTitle.TextColor3 = Color3.fromRGB(255, 180, 100)
GetSpinsTitle.TextSize = 14
GetSpinsTitle.Parent = GetItemsContainer

-- Get Spins Toggle Button
local GetSpinsToggleBtn = Instance.new("TextButton")
GetSpinsToggleBtn.Size = UDim2.new(1, 0, 0, 40)
GetSpinsToggleBtn.Position = UDim2.new(0, 0, 0, 625)
GetSpinsToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
GetSpinsToggleBtn.Text = "Get Spins - OFF"
GetSpinsToggleBtn.Font = Enum.Font.GothamBold
GetSpinsToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GetSpinsToggleBtn.TextSize = 14
GetSpinsToggleBtn.BorderSizePixel = 0
GetSpinsToggleBtn.Parent = GetItemsContainer

Instance.new("UICorner", GetSpinsToggleBtn).CornerRadius = UDim.new(0, 8)

local GetSpinsToggleGradient = Instance.new("UIGradient")
GetSpinsToggleGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
})
GetSpinsToggleGradient.Rotation = 45
GetSpinsToggleGradient.Parent = GetSpinsToggleBtn

-- Spins Counter Label
local GetSpinsCountLabel = Instance.new("TextLabel")
GetSpinsCountLabel.Size = UDim2.new(1, -20, 0, 25)
GetSpinsCountLabel.Position = UDim2.new(0, 10, 0, 675)
GetSpinsCountLabel.BackgroundTransparency = 1
GetSpinsCountLabel.Text = "Spins Obtained: 0"
GetSpinsCountLabel.Font = Enum.Font.Gotham
GetSpinsCountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
GetSpinsCountLabel.TextSize = 13
GetSpinsCountLabel.Parent = GetItemsContainer

-- Get Spins Toggle Logic
GetSpinsToggleBtn.MouseButton1Click:Connect(function()
    getSpinsActive = not getSpinsActive
    
    if getSpinsActive then
        GetSpinsToggleBtn.Text = "Get Spins - ON"
        GetSpinsToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        GetSpinsToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 200, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 150, 30))
        })
        
        startGetSpins()
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = "Get Spins Started!",
            Duration = 2
        })
    else
        GetSpinsToggleBtn.Text = "Get Spins - OFF"
        GetSpinsToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        GetSpinsToggleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 30, 30))
        })
        
        stopGetSpins()
        
        game.StarterGui:SetCore("SendNotification", {
            Title = "PRIME Hub",
            Text = "Get Spins Stopped!",
            Duration = 2
        })
    end
end)

-- Real-time Spins Counter Update
task.spawn(function()
    while wait(0.5) do
        if getSpinsActive then
            GetSpinsCountLabel.Text = "Spins Obtained: " .. getSpinsCount
        end
    end
end)

-- UI THEMES SECTION
local ThemesBtn = Instance.new("TextButton")
ThemesBtn.Size = UDim2.new(1, -10, 0, 35)
ThemesBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 180)
ThemesBtn.Text = "UI Themes"
ThemesBtn.Font = Enum.Font.GothamBold
ThemesBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemesBtn.TextSize = 16
ThemesBtn.BorderSizePixel = 0
ThemesBtn.Parent = LeftSection

Instance.new("UICorner", ThemesBtn).CornerRadius = UDim.new(0, 6)

local ThemesBtnGradient = Instance.new("UIGradient")
ThemesBtnGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 200)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 200))
})
ThemesBtnGradient.Rotation = 45
ThemesBtnGradient.Parent = ThemesBtn

ButtonGradients["Themes"] = ThemesBtnGradient
ButtonTexts["Themes"] = ThemesBtn

local ThemesContainer = Instance.new("Frame")
ThemesContainer.Size = UDim2.new(1, -20, 0, 270)
ThemesContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ThemesContainer.BackgroundTransparency = 0.1
ThemesContainer.BorderSizePixel = 0
ThemesContainer.Visible = false
ThemesContainer.Parent = ContentFrame

Instance.new("UICorner", ThemesContainer).CornerRadius = UDim.new(0, 8)

local ThemesStroke = Instance.new("UIStroke")
ThemesStroke.Thickness = 2
ThemesStroke.Color = Color3.fromRGB(255, 120, 80)
ThemesStroke.Transparency = 0.3
ThemesStroke.Parent = ThemesContainer

local ThemesContainerGradient = Instance.new("UIGradient")
ThemesContainerGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 35)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 25, 30)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 30, 35))
})
ThemesContainerGradient.Rotation = 135
ThemesContainerGradient.Parent = ThemesContainer

local ThemesTitle = Instance.new("TextLabel")
ThemesTitle.Size = UDim2.new(1, -20, 0, 35)
ThemesTitle.Position = UDim2.new(0, 10, 0, 10)
ThemesTitle.BackgroundTransparency = 1
ThemesTitle.Text = "Select Theme"
ThemesTitle.Font = Enum.Font.GothamBold
ThemesTitle.TextColor3 = Color3.fromRGB(0, 255, 255)
ThemesTitle.TextSize = 16
ThemesTitle.Parent = ThemesContainer

SectionTitles["Themes"] = ThemesTitle

local ThemesListFrame = Instance.new("ScrollingFrame")
ThemesListFrame.Size = UDim2.new(1, -20, 0, 210)
ThemesListFrame.Position = UDim2.new(0, 10, 0, 50)
ThemesListFrame.BackgroundTransparency = 1
ThemesListFrame.BorderSizePixel = 0
ThemesListFrame.ScrollBarThickness = 6
ThemesListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ThemesListFrame.Parent = ThemesContainer

local ThemesListLayout = Instance.new("UIListLayout")
ThemesListLayout.Padding = UDim.new(0, 8)
ThemesListLayout.FillDirection = Enum.FillDirection.Vertical
ThemesListLayout.Parent = ThemesListFrame

wait(0.1)
-- Update canvas size after themes load
ThemesListFrame.CanvasSize = UDim2.new(0, 0, 0, ThemesListLayout.AbsoluteContentSize.Y + 16)

for themeName, _ in pairs(ThemeColors) do
local ThemeBtn = Instance.new("TextButton")
ThemeBtn.Size = UDim2.new(1, 0, 0, 30)
ThemeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
ThemeBtn.Text = themeName
ThemeBtn.Font = Enum.Font.Gotham
ThemeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ThemeBtn.TextSize = 14
ThemeBtn.BorderSizePixel = 0
ThemeBtn.Parent = ThemesListFrame

Instance.new("UICorner", ThemeBtn).CornerRadius = UDim.new(0, 6)

ThemeBtn.MouseButton1Click:Connect(function()
    applyTheme(themeName)
end)
end

-- ABOUT US SECTION
local AboutBtn = Instance.new("TextButton")
AboutBtn.Size = UDim2.new(1, -10, 0, 35)
AboutBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
AboutBtn.Text = "About Us"
AboutBtn.Font = Enum.Font.GothamBold
AboutBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AboutBtn.TextSize = 16
AboutBtn.BorderSizePixel = 0
AboutBtn.Parent = LeftSection

Instance.new("UICorner", AboutBtn).CornerRadius = UDim.new(0, 6)

local AboutBtnGradient = Instance.new("UIGradient")
AboutBtnGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 150, 255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 100, 255))
})
AboutBtnGradient.Rotation = 45
AboutBtnGradient.Parent = AboutBtn

ButtonGradients["About"] = AboutBtnGradient
ButtonTexts["About"] = AboutBtn

local AboutContainer = Instance.new("Frame")
AboutContainer.Size = UDim2.new(1, -20, 0, 270)
AboutContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AboutContainer.BackgroundTransparency = 0.1
AboutContainer.BorderSizePixel = 0
AboutContainer.Visible = false
AboutContainer.Parent = ContentFrame

Instance.new("UICorner", AboutContainer).CornerRadius = UDim.new(0, 8)

local AboutStroke = Instance.new("UIStroke")
AboutStroke.Thickness = 2
AboutStroke.Color = Color3.fromRGB(100, 200, 255)
AboutStroke.Transparency = 0.3
AboutStroke.Parent = AboutContainer

local AboutContainerGradient = Instance.new("UIGradient")
AboutContainerGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 40, 50)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 30, 45)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 35, 50))
})
AboutContainerGradient.Rotation = 135
AboutContainerGradient.Parent = AboutContainer

local AboutTitle = Instance.new("TextLabel")
AboutTitle.Size = UDim2.new(1, -20, 0, 35)
AboutTitle.Position = UDim2.new(0, 10, 0, 10)
AboutTitle.BackgroundTransparency = 1
AboutTitle.Text = "About PRIME Hub"
AboutTitle.Font = Enum.Font.GothamBold
AboutTitle.TextColor3 = Color3.fromRGB(100, 200, 255)
AboutTitle.TextSize = 16
AboutTitle.Parent = AboutContainer

SectionTitles["About"] = AboutTitle

local AboutContent = Instance.new("TextLabel")
AboutContent.Size = UDim2.new(1, -20, 0, 210)
AboutContent.Position = UDim2.new(0, 10, 0, 50)
AboutContent.BackgroundTransparency = 1
AboutContent.TextColor3 = Color3.fromRGB(200, 200, 200)
AboutContent.TextSize = 12
AboutContent.Font = Enum.Font.Gotham
AboutContent.TextWrapped = true
AboutContent.TextXAlignment = Enum.TextXAlignment.Left
AboutContent.TextYAlignment = Enum.TextYAlignment.Top
AboutContent.Text = "PRIME Hub v1.0\n\nCreated by: WENDIGO\n\nA premium UI library for Roblox games with advanced theming and customization.\n\nFeatures:\n• Multiple color themes\n• Smooth animations\n• Modern UI design\n• Easy to customize\n\nJoin our community for updates and support!"
AboutContent.Parent = AboutContainer

-- Prevent drag interference with scrolling on mobile
ContentFrame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.Touch then
    dragging = false
end
end)

-- Toggle sections
ThemesBtn.MouseButton1Click:Connect(function()
ThemesContainer.Visible = true
AboutContainer.Visible = false
GameContainer.Visible = false
KillFarmContainer.Visible = false
GetItemsContainer.Visible = false
RightSection.Visible = true
end)

AboutBtn.MouseButton1Click:Connect(function()
ThemesContainer.Visible = false
AboutContainer.Visible = true
GameContainer.Visible = false
KillFarmContainer.Visible = false
GetItemsContainer.Visible = false
RightSection.Visible = true
end)

GameBtn.MouseButton1Click:Connect(function()
ThemesContainer.Visible = false
AboutContainer.Visible = false
GameContainer.Visible = true
KillFarmContainer.Visible = false
GetItemsContainer.Visible = false
RightSection.Visible = true
end)

KillFarmBtn.MouseButton1Click:Connect(function()
ThemesContainer.Visible = false
AboutContainer.Visible = false
GameContainer.Visible = false
KillFarmContainer.Visible = true
GetItemsContainer.Visible = false
RightSection.Visible = true
end)

GetItemsBtn.MouseButton1Click:Connect(function()
ThemesContainer.Visible = false
AboutContainer.Visible = false
GameContainer.Visible = false
KillFarmContainer.Visible = false
GetItemsContainer.Visible = true
RightSection.Visible = true
end)

-- ============================================
-- STATUS UPDATE LOOPwwwww
-- ============================================
task.spawn(function()
  while wait(1) do
      if killFarmActive then
          local count = #getAllTargetPositions()
          KillFarmStatusLabel.Text = "Status: Active - Targeting " .. count .. " player(s)"
      end
  end
end)
