-- City Heist MVP Shops v1 UI. Cloned to PlayerGui by server bootstrap.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = RS:WaitForChild("CityHeistShopEvent")
local gui = Instance.new("ScreenGui")
gui.Name = "CityHeistShopGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.Name = "ShopPanel"
panel.Size = UDim2.fromOffset(340, 290)
panel.Position = UDim2.new(0.5, -170, 0.5, -145)
panel.BackgroundColor3 = Color3.fromRGB(17, 23, 32)
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
local function label(text, y, height, color)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -28, 0, height)
    l.Position = UDim2.fromOffset(14, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(240, 245, 255)
    l.TextScaled = true
    l.Font = Enum.Font.GothamBold
    l.Text = text
    l.Parent = panel
    return l
end
local title = label("SKLEP", 15, 36)
local info = label("Kup przedmioty przywracajace zdrowie", 56, 26, Color3.fromRGB(175, 190, 205))
local result = label("", 234, 35, Color3.fromRGB(90, 220, 170))
local activeShop = nil
local function button(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -28, 0, 46)
    b.Position = UDim2.fromOffset(14, y)
    b.BackgroundColor3 = Color3.fromRGB(29, 110, 105)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.TextScaled = true
    b.Font = Enum.Font.GothamBold
    b.Text = text
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(callback)
end
button("Przekaska +20 HP | 75 Money", 100, function()
    if activeShop then event:FireServer("Buy", activeShop, "Snack") end
end)
button("Apteczka +75 HP | 250 Money", 155, function()
    if activeShop then event:FireServer("Buy", activeShop, "Medkit") end
end)
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(30, 30)
close.Position = UDim2.new(1, -38, 0, 9)
close.BackgroundColor3 = Color3.fromRGB(145, 45, 55)
close.TextColor3 = Color3.new(1, 1, 1)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextSize = 20
close.Parent = panel
close.MouseButton1Click:Connect(function() panel.Visible = false end)
event.OnClientEvent:Connect(function(action, a, b)
    if action == "Open" then
        activeShop = a
        title.Text = "SKLEP " .. tostring(a)
        result.Text = ""
        panel.Visible = true
    elseif action == "Result" then
        result.TextColor3 = a and Color3.fromRGB(90, 220, 170) or Color3.fromRGB(255, 120, 120)
        result.Text = tostring(b)
    end
end)
