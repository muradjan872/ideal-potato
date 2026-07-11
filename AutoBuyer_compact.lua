-- Auto Buyer GUI (Fully Separated Teleport + Buy Counter)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local purchaseItem = remotes:WaitForChild("PurchaseShopItem")
local openShop = remotes:WaitForChild("OpenShop")
local shopRestocked = remotes:WaitForChild("ShopRestocked")

local SEED_POS = Vector3.new(176.70, 201.05, 672)
local GEAR_POS = Vector3.new(212.10, 204.02, 610.38)

local teleportEnabled = true
local guiVisible = true

local seedState = {
    buying = false,
    lastBuy = 0,
    auto = false,
    bought = 0,
    status = nil,
    counterLabel = nil,
}

local gearState = {
    buying = false,
    lastBuy = 0,
    auto = false,
    bought = 0,
    status = nil,
    counterLabel = nil,
}

local seedList = {
    { name = "Carrot Seed",     enabled = true },
    { name = "Corn Seed",       enabled = true },
    { name = "Onion Seed",      enabled = true },
    { name = "Strawberry Seed", enabled = true },
    { name = "Mushroom Seed",   enabled = true },
    { name = "Beetroot Seed",   enabled = true },
    { name = "Tomato Seed",     enabled = true },
    { name = "Apple Seed",      enabled = true },
    { name = "Rose Seed",       enabled = true },
    { name = "Wheat Seed",      enabled = true },
    { name = "Banana Seed",     enabled = true },
    { name = "Plum Seed",       enabled = true },
    { name = "Potato Seed",     enabled = true },
    { name = "Cabbage Seed",    enabled = true },
    { name = "Cherry Seed",     enabled = true },
    { name = "Bamboo Seed",     enabled = true },
    { name = "Mango Seed",      enabled = true },
    { name = "Watermelon Seed", enabled = true },
    { name = "Pineapple Seed",  enabled = true },
}

local gearList = {
    { name = "Watering Can",        enabled = true },
    { name = "Super Watering Can",  enabled = true },
    { name = "Favorite Tool",       enabled = true },
    { name = "Basic Sprinkler",     enabled = true },
    { name = "Super Sprinkler",     enabled = true },
    { name = "Turbo Sprinkler",     enabled = true },
    { name = "Harvest Bell",        enabled = true },
    { name = "Trowel",              enabled = true },
    { name = "Reverter",            enabled = true },
    { name = "Magnifying Glass",    enabled = true },
}

local function setStatus(lbl, msg, color)
    if lbl then
        lbl.Text = msg
        lbl.TextColor3 = color or Color3.fromRGB(130, 130, 150)
    end
end

local function updateCounter(state)
    if state.counterLabel then
        state.counterLabel.Text = "🧺 Bought this session: " .. state.bought
    end
end

local function teleportTo(pos)
    if not teleportEnabled then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = CFrame.new(pos)
    task.wait(0.4)
end

local function buyItems(list, shopName, state)
    if state.buying then return end
    if os.clock() - state.lastBuy < 0.5 then return end
    state.buying = true
    state.lastBuy = os.clock()

    setStatus(state.status, "⚡ Buying...", Color3.fromRGB(100, 180, 255))
    pcall(function() openShop:FireServer() end)
    task.wait(0.15)

    local enabled = {}
    for _, item in ipairs(list) do
        if item.enabled then table.insert(enabled, item) end
    end

    if #enabled == 0 then
        setStatus(state.status, "⚠️ All off!", Color3.fromRGB(255, 180, 0))
        state.buying = false
        return
    end

    local sessionBought = 0
    local done = 0

    for _, item in ipairs(enabled) do
        task.spawn(function()
            local subDone = 0
            for i = 1, 50 do
                task.spawn(function()
                    local ok, result = pcall(function()
                        return purchaseItem:InvokeServer(shopName, item.name)
                    end)
                    if ok and result ~= nil and result ~= false then
                        sessionBought += 1
                        state.bought += 1
                        updateCounter(state)
                    end
                    subDone += 1
                end)
                task.wait(0.03)
            end
            local t = 0
            while subDone < 50 and t < 5 do task.wait(0.1) t += 0.1 end
            done += 1
        end)
    end

    local t = 0
    while done < #enabled and t < 10 do task.wait(0.1) t += 0.1 end

    setStatus(state.status, "✅ Done! +" .. sessionBought, Color3.fromRGB(80, 200, 120))
    state.buying = false
end


-- GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoBuyerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local mainFrame -- forward declaration for hide callback

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function addStroke(parent, thickness, transparency, color)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.4
    s.Color = color or Color3.fromRGB(100, 110, 160)
    s.Parent = parent
    return s
end

local function addGradient(parent, rotation, c1, c2)
    local g = Instance.new("UIGradient")
    g.Rotation = rotation or 0
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1 or Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, c2 or Color3.fromRGB(180, 180, 180)),
    })
    g.Parent = parent
    return g
end

local function clampToViewport(guiObject, x, y)
    local cam = workspace.CurrentCamera
    if not cam then
        return x, y
    end

    local vp = cam.ViewportSize
    local size = guiObject.AbsoluteSize
    local maxX = math.max(0, vp.X - size.X)
    local maxY = math.max(0, vp.Y - size.Y)

    return math.clamp(x, 0, maxX), math.clamp(y, 0, maxY)
end

local function makeDraggable(handle, target, clampToScreen)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragInput = nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.AbsolutePosition

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not dragStart or not startPos then
            return
        end

        local delta = input.Position - dragStart
        local newX = startPos.X + delta.X
        local newY = startPos.Y + delta.Y

        if clampToScreen then
            newX, newY = clampToViewport(target, newX, newY)
        end

        target.Position = UDim2.fromOffset(newX, newY)
    end)
end

local function styleGlassFrame(frame, strokeColor, transparency)
    frame.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
    frame.BackgroundTransparency = transparency or 0.08
    addCorner(frame, 16)
    addStroke(frame, 1, 0.45, strokeColor or Color3.fromRGB(110, 120, 170))
end

local function styleButton(btn, color, hoverColor)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    addCorner(btn, 8)
    btn.MouseEnter:Connect(function()
        if btn.Visible and hoverColor then
            btn.BackgroundColor3 = hoverColor
        end
    end)
    btn.MouseLeave:Connect(function()
        if btn.Visible then
            btn.BackgroundColor3 = color
        end
    end)
end

local isTouch = UserInputService.TouchEnabled
local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local panelWidth = isTouch and math.clamp(math.floor(viewport.X * 0.80), 220, 260) or 270
local panelHeight = isTouch and math.clamp(math.floor(viewport.Y * 0.68), 340, 430) or 440

-- Floating hide pill
local floatFrame = Instance.new("TextButton")
floatFrame.Name = "FloatButton"
floatFrame.Size = isTouch and UDim2.fromOffset(46, 46) or UDim2.fromOffset(48, 48)
floatFrame.Position = UDim2.fromOffset(12, 196)
floatFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 42)
floatFrame.BackgroundTransparency = 0.05
floatFrame.BorderSizePixel = 0
floatFrame.Text = ""
floatFrame.Active = true
floatFrame.AutoButtonColor = false
floatFrame.ZIndex = 20
floatFrame.Parent = screenGui
addCorner(floatFrame, 999)
addStroke(floatFrame, 2, 0.18, Color3.fromRGB(100, 110, 170))
addGradient(floatFrame, 45, Color3.fromRGB(35, 38, 60), Color3.fromRGB(18, 18, 26))

local floatIcon = Instance.new("TextLabel")
floatIcon.Size = UDim2.new(1, 0, 1, 0)
floatIcon.BackgroundTransparency = 1
floatIcon.Text = "🛒"
floatIcon.TextSize = 24
floatIcon.Font = Enum.Font.GothamBold
floatIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
floatIcon.ZIndex = 21
floatIcon.Parent = floatFrame

local function refreshFloatState()
    if guiVisible then
        floatIcon.Text = "🛒"
        floatFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 42)
        floatFrame.BackgroundTransparency = 0.05
    else
        floatIcon.Text = "👁"
        floatFrame.BackgroundColor3 = Color3.fromRGB(96, 44, 140)
        floatFrame.BackgroundTransparency = 0.02
    end
end

local floatStart, floatStartPos, floatMoved = nil, nil, false
local TAP_THRESHOLD = 8

floatFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        floatStart = input.Position
        floatStartPos = floatFrame.AbsolutePosition
        floatMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not floatStart or not floatStartPos then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - floatStart
        if delta.Magnitude > TAP_THRESHOLD then
            floatMoved = true
            local x, y = clampToViewport(floatFrame, floatStartPos.X + delta.X, floatStartPos.Y + delta.Y)
            floatFrame.Position = UDim2.fromOffset(x, y)
        end
    end
end)

floatFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if not floatMoved then
            guiVisible = not guiVisible
            if mainFrame then
                mainFrame.Visible = guiVisible
            end
            refreshFloatState()
        end
        floatStart = nil
        floatStartPos = nil
        floatMoved = false
    end
end)

-- Main panel
mainFrame = Instance.new("Frame")
mainFrame.Name = "MainPanel"
mainFrame.Size = UDim2.fromOffset(panelWidth, panelHeight)
mainFrame.Position = isTouch and UDim2.fromOffset(58, 78) or UDim2.fromOffset(72, 108)
mainFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 28)
mainFrame.BackgroundTransparency = 0.04
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui
styleGlassFrame(mainFrame, Color3.fromRGB(105, 115, 165), 0.04)

local mainGradient = addGradient(mainFrame, 90, Color3.fromRGB(20, 22, 34), Color3.fromRGB(12, 12, 18))
mainGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.02),
    NumberSequenceKeypoint.new(1, 0.08),
})

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 38)
topBar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
topBar.BackgroundTransparency = 0.02
topBar.BorderSizePixel = 0
topBar.Active = true
topBar.Parent = mainFrame
addCorner(topBar, 14)
addStroke(topBar, 1, 0.6, Color3.fromRGB(100, 110, 150))

local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.fromOffset(4, 20)
accentBar.Position = UDim2.fromOffset(10, 9)
accentBar.BackgroundColor3 = Color3.fromRGB(110, 130, 255)
accentBar.BorderSizePixel = 0
accentBar.Parent = topBar
addCorner(accentBar, 999)

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -160, 1, 0)
titleText.Position = UDim2.fromOffset(22, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Auto Buyer"
titleText.TextColor3 = Color3.fromRGB(240, 242, 255)
titleText.TextSize = isTouch and 12 or 13
titleText.Font = Enum.Font.GothamBold
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = topBar

local subtitleText = Instance.new("TextLabel")
subtitleText.Size = UDim2.new(1, -160, 0, 11)
subtitleText.Position = UDim2.fromOffset(22, 18)
subtitleText.BackgroundTransparency = 1
subtitleText.Text = "Glass UI • drag the header"
subtitleText.TextColor3 = Color3.fromRGB(140, 146, 170)
subtitleText.TextSize = 8
subtitleText.Font = Enum.Font.Gotham
subtitleText.TextXAlignment = Enum.TextXAlignment.Left
subtitleText.Parent = topBar

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.fromOffset(24, 22)
hideBtn.Position = UDim2.new(1, -58, 0, 7)
hideBtn.BackgroundColor3 = Color3.fromRGB(50, 56, 76)
hideBtn.Text = "–"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.TextSize = 18
hideBtn.Font = Enum.Font.GothamBold
hideBtn.BorderSizePixel = 0
hideBtn.AutoButtonColor = false
hideBtn.Parent = topBar
addCorner(hideBtn, 7)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(24, 22)
closeBtn.Position = UDim2.new(1, -26, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 48, 58)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 18
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = topBar
addCorner(closeBtn, 7)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -14, 0, 30)
tabBar.Position = UDim2.fromOffset(7, 42)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local seedTabBtn = Instance.new("TextButton")
seedTabBtn.Size = UDim2.new(0.5, -4, 1, 0)
seedTabBtn.Position = UDim2.fromOffset(0, 0)
seedTabBtn.BackgroundColor3 = Color3.fromRGB(28, 96, 52)
seedTabBtn.Text = "🌱 Seeds"
seedTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
seedTabBtn.TextSize = 10
seedTabBtn.Font = Enum.Font.GothamBold
seedTabBtn.BorderSizePixel = 0
seedTabBtn.AutoButtonColor = false
seedTabBtn.Parent = tabBar
addCorner(seedTabBtn, 8)

local gearTabBtn = Instance.new("TextButton")
gearTabBtn.Size = UDim2.new(0.5, -4, 1, 0)
gearTabBtn.Position = UDim2.new(0.5, 4, 0, 0)
gearTabBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 62)
gearTabBtn.Text = "⚙ Gear"
gearTabBtn.TextColor3 = Color3.fromRGB(190, 194, 210)
gearTabBtn.TextSize = 10
gearTabBtn.Font = Enum.Font.GothamBold
gearTabBtn.BorderSizePixel = 0
gearTabBtn.AutoButtonColor = false
gearTabBtn.Parent = tabBar
addCorner(gearTabBtn, 8)

local infoBar = Instance.new("Frame")
infoBar.Size = UDim2.new(1, -14, 0, 24)
infoBar.Position = UDim2.fromOffset(7, 72)
infoBar.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
infoBar.BackgroundTransparency = 0.06
infoBar.BorderSizePixel = 0
infoBar.Parent = mainFrame
addCorner(infoBar, 10)
addStroke(infoBar, 1, 0.72, Color3.fromRGB(95, 105, 145))

local tpLabel = Instance.new("TextLabel")
tpLabel.Size = UDim2.new(1, -60, 1, 0)
tpLabel.Position = UDim2.fromOffset(10, 0)
tpLabel.BackgroundTransparency = 1
tpLabel.Text = "🚀 Rotate shops"
tpLabel.TextColor3 = Color3.fromRGB(180, 180, 255)
tpLabel.TextSize = 9
tpLabel.Font = Enum.Font.GothamBold
tpLabel.TextXAlignment = Enum.TextXAlignment.Left
tpLabel.Parent = infoBar

local tpToggle = Instance.new("TextButton")
tpToggle.Size = UDim2.fromOffset(40, 16)
tpToggle.Position = UDim2.new(1, -44, 0, 4)
tpToggle.BackgroundColor3 = Color3.fromRGB(0, 150, 70)
tpToggle.Text = "ON"
tpToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
tpToggle.TextSize = 10
tpToggle.Font = Enum.Font.GothamBold
tpToggle.BorderSizePixel = 0
tpToggle.AutoButtonColor = false
tpToggle.Parent = infoBar
addCorner(tpToggle, 6)

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(1, -14, 0, 16)
timerLabel.Position = UDim2.fromOffset(7, 98)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "⏱ Rotation: --"
timerLabel.TextColor3 = Color3.fromRGB(140, 140, 180)
timerLabel.TextSize = 10
timerLabel.Font = Enum.Font.Gotham
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -14, 1, -118)
content.Position = UDim2.fromOffset(7, 114)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local function buildPanel(list, shopName, state, accentColor, offColor, baseTextColor)
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.BackgroundTransparency = 1
    panel.Parent = content

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, 0, 0, 14)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "Idle"
    statusLbl.TextColor3 = baseTextColor
    statusLbl.TextSize = 9
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.Parent = panel
    state.status = statusLbl

    local counterLbl = Instance.new("TextLabel")
    counterLbl.Size = UDim2.new(1, 0, 0, 14)
    counterLbl.Position = UDim2.fromOffset(0, 14)
    counterLbl.BackgroundTransparency = 1
    counterLbl.Text = "🧺 Bought this session: 0"
    counterLbl.TextColor3 = Color3.fromRGB(180, 220, 140)
    counterLbl.TextSize = 9
    counterLbl.Font = Enum.Font.GothamBold
    counterLbl.TextXAlignment = Enum.TextXAlignment.Left
    counterLbl.Parent = panel
    state.counterLabel = counterLbl

    local actionCard = Instance.new("Frame")
    actionCard.Size = UDim2.new(1, 0, 0, 56)
    actionCard.Position = UDim2.fromOffset(0, 27)
    actionCard.BackgroundColor3 = Color3.fromRGB(20, 22, 34)
    actionCard.BackgroundTransparency = 0.04
    actionCard.BorderSizePixel = 0
    actionCard.Parent = panel
    addCorner(actionCard, 12)
    addStroke(actionCard, 1, 0.7, accentColor)

    local buyBtn = Instance.new("TextButton")
    buyBtn.Size = UDim2.new(0.5, -4, 0, 26)
    buyBtn.Position = UDim2.fromOffset(0, 16)
    buyBtn.BackgroundColor3 = accentColor
    buyBtn.Text = "▶ Buy Now"
    buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    buyBtn.TextSize = 10
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.BorderSizePixel = 0
    buyBtn.AutoButtonColor = false
    buyBtn.Parent = actionCard
    addCorner(buyBtn, 8)

    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(0.5, -4, 0, 26)
    autoBtn.Position = UDim2.new(0.5, 4, 0, 16)
    autoBtn.BackgroundColor3 = offColor
    autoBtn.Text = "AUTO: OFF"
    autoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoBtn.TextSize = 10
    autoBtn.Font = Enum.Font.GothamBold
    autoBtn.BorderSizePixel = 0
    autoBtn.AutoButtonColor = false
    autoBtn.Parent = actionCard
    addCorner(autoBtn, 8)

    local section = Instance.new("TextLabel")
    section.Size = UDim2.new(1, 0, 0, 12)
    section.Position = UDim2.fromOffset(0, 86)
    section.BackgroundTransparency = 1
    section.Text = string.upper(shopName) .. " TOGGLES"
    section.TextColor3 = baseTextColor
    section.TextSize = 8
    section.Font = Enum.Font.GothamBold
    section.TextXAlignment = Enum.TextXAlignment.Left
    section.Parent = panel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -98)
    scroll.Position = UDim2.fromOffset(0, 98)
    scroll.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
    scroll.BackgroundTransparency = 0.06
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = accentColor
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.Parent = panel
    addCorner(scroll, 10)
    addStroke(scroll, 1, 0.65, accentColor)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)
    pad.Parent = scroll

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)

    for _, item in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 26)
        row.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
        row.BackgroundTransparency = 0.05
        row.BorderSizePixel = 0
        row.Parent = scroll
        addCorner(row, 8)
        addStroke(row, 1, 0.76, Color3.fromRGB(88, 96, 128))

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.fromOffset(7, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = item.name
        lbl.TextColor3 = Color3.fromRGB(228, 230, 240)
        lbl.TextSize = 9
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextTruncate = Enum.TextTruncate.AtEnd
        lbl.Parent = row

        local tog = Instance.new("TextButton")
        tog.Size = UDim2.fromOffset(36, 18)
        tog.Position = UDim2.new(1, -40, 0, 4)
        tog.BackgroundColor3 = accentColor
        tog.Text = "ON"
        tog.TextColor3 = Color3.fromRGB(255, 255, 255)
        tog.TextSize = 9
        tog.Font = Enum.Font.GothamBold
        tog.BorderSizePixel = 0
        tog.AutoButtonColor = false
        tog.Parent = row
        addCorner(tog, 5)

        tog.MouseButton1Click:Connect(function()
            item.enabled = not item.enabled
            if item.enabled then
                tog.Text = "ON"
                tog.BackgroundColor3 = accentColor
                lbl.TextColor3 = Color3.fromRGB(228, 230, 240)
                row.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
            else
                tog.Text = "OFF"
                tog.BackgroundColor3 = Color3.fromRGB(145, 45, 45)
                lbl.TextColor3 = Color3.fromRGB(95, 95, 105)
                row.BackgroundColor3 = Color3.fromRGB(16, 18, 24)
            end
        end)
    end

    buyBtn.MouseButton1Click:Connect(function()
        task.spawn(function()
            buyItems(list, shopName, state)
        end)
    end)

    autoBtn.MouseButton1Click:Connect(function()
        state.auto = not state.auto
        if state.auto then
            autoBtn.Text = "AUTO: ON"
            autoBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        else
            autoBtn.Text = "AUTO: OFF"
            autoBtn.BackgroundColor3 = offColor
            state.buying = false
            setStatus(state.status, "Idle", baseTextColor)
        end
    end)

    return panel
end

local seedPanel = buildPanel(seedList, "SeedShop", seedState, Color3.fromRGB(0, 150, 60), Color3.fromRGB(0, 100, 40), Color3.fromRGB(130, 175, 130))
local gearPanel = buildPanel(gearList, "GearShop", gearState, Color3.fromRGB(0, 110, 200), Color3.fromRGB(0, 80, 160), Color3.fromRGB(130, 145, 170))
gearPanel.Visible = false

seedTabBtn.MouseButton1Click:Connect(function()
    seedPanel.Visible = true
    gearPanel.Visible = false
    seedTabBtn.BackgroundColor3 = Color3.fromRGB(28, 96, 52)
    seedTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    gearTabBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 62)
    gearTabBtn.TextColor3 = Color3.fromRGB(190, 194, 210)
end)

gearTabBtn.MouseButton1Click:Connect(function()
    seedPanel.Visible = false
    gearPanel.Visible = true
    gearTabBtn.BackgroundColor3 = Color3.fromRGB(30, 76, 132)
    gearTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedTabBtn.BackgroundColor3 = Color3.fromRGB(42, 42, 62)
    seedTabBtn.TextColor3 = Color3.fromRGB(190, 194, 210)
end)

hideBtn.MouseButton1Click:Connect(function()
    guiVisible = false
    mainFrame.Visible = false
    refreshFloatState()
end)

closeBtn.MouseButton1Click:Connect(function()
    seedState.auto = false
    gearState.auto = false
    screenGui:Destroy()
end)

tpToggle.MouseButton1Click:Connect(function()
    teleportEnabled = not teleportEnabled
    tpToggle.Text = teleportEnabled and "ON" or "OFF"
    tpToggle.BackgroundColor3 = teleportEnabled and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(130, 35, 35)
end)

makeDraggable(topBar, mainFrame, true)
makeDraggable(floatFrame, floatFrame, true)

refreshFloatState()

-- Auto buy poll every 1 second
task.spawn(function()
    while true do
        task.wait(1)

        if seedState.auto and not seedState.buying then
            task.spawn(function()
                buyItems(seedList, "SeedShop", seedState)
            end)
        end

        if gearState.auto and not gearState.buying then
            task.spawn(function()
                buyItems(gearList, "GearShop", gearState)
            end)
        end
    end
end)

-- Teleport loop (completely separate)
task.spawn(function()
    local INTERVAL = 60
    local STAY = 10
    local nextTP = os.clock() + INTERVAL

    while true do
        task.wait(1)

        local remaining = math.max(0, math.floor(nextTP - os.clock()))

        if not teleportEnabled or (not seedState.auto and not gearState.auto) then
            timerLabel.Text = "⏱ Teleport: " .. (teleportEnabled and "waiting for AUTO..." or "OFF")
            timerLabel.TextColor3 = Color3.fromRGB(100, 100, 120)
            nextTP = os.clock() + INTERVAL
            continue
        end

        timerLabel.Text = "⏱ Next rotation in: " .. remaining .. "s"
        timerLabel.TextColor3 = remaining < 10
            and Color3.fromRGB(255, 150, 50)
            or Color3.fromRGB(140, 140, 180)

        if os.clock() < nextTP then continue end

        if seedState.auto then
            timerLabel.Text = "🚀 Teleporting to Seed Shop..."
            timerLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
            teleportTo(SEED_POS)
            for i = STAY, 1, -1 do
                timerLabel.Text = "🌱 At Seed Shop: " .. i .. "s"
                task.wait(1)
            end
        end

        if gearState.auto then
            timerLabel.Text = "🚀 Teleporting to Gear Shop..."
            timerLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
            teleportTo(GEAR_POS)
            for i = STAY, 1, -1 do
                timerLabel.Text = "⚙️ At Gear Shop: " .. i .. "s"
                task.wait(1)
            end
        end

        nextTP = os.clock() + INTERVAL
    end
end)

-- Main drag
local mDrag, mStart, mPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        mDrag = true
        mStart = input.Position
        mPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not mDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - mStart
        mainFrame.Position = UDim2.new(
            mPos.X.Scale, mPos.X.Offset + d.X,
            mPos.Y.Scale, mPos.Y.Offset + d.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        mDrag = false
    end
end)

print("🛒 Auto Buyer loaded!")
