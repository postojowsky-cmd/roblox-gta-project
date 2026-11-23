-- Separate STORE button. Existing spawn bridge and button remain unchanged.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("CityHeistGarageStoreRequest")
local active = workspace:WaitForChild("CityHeistGarageSpawned")
local vehicleId = "Vehicle_" .. player.UserId
local hooked = setmetatable({}, {__mode = "k"})
local buttons = setmetatable({}, {__mode = "k"})
local pending = false

local function update()
    local available = active:FindFirstChild(vehicleId) ~= nil
    for button in pairs(buttons) do
        if button.Parent then
            button.Visible = available
            button.Active = available and not pending
            button.Text = pending and "CHOWANIE..." or "SCHOWAJ POJAZD"
        end
    end
end

local function tryAttach(row)
    if not row or not row:IsA("Frame") or hooked[row] then return end
    local correct = false
    local spawnButton
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == "Saab 9-3 Turbo X" then correct = true end
        if child:IsA("TextButton") and (child.Text:find("WYCIAGNIJ", 1, true) or child.Text == "WYCIAGANIE...") then
            spawnButton = child
        end
    end
    if not correct or not spawnButton then return end
    hooked[row] = true
    -- Keep the original spawn button and its click connection intact.
    spawnButton.Size = UDim2.new(0.5, -18, 0, 28)
    local button = Instance.new("TextButton")
    button.Name = "CityHeistStoreButton"
    button.Text = "SCHOWAJ POJAZD"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.TextColor3 = Color3.fromRGB(235, 245, 255)
    button.BackgroundColor3 = Color3.fromRGB(75, 93, 115)
    button.BorderSizePixel = 0
    button.Position = UDim2.new(0.5, 4, 1, -37)
    button.Size = UDim2.new(0.5, -18, 0, 28)
    button.Parent = row
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button
    buttons[button] = true
    button.MouseButton1Click:Connect(function()
        if pending or not active:FindFirstChild(vehicleId) then return end
        pending = true
        update()
        remote:FireServer()
        task.delay(4, function()
            if pending then pending = false; update() end
        end)
    end)
    update()
end

local function inspect(obj)
    if obj:IsA("Frame") then
        tryAttach(obj)
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        tryAttach(obj.Parent)
    end
end

for _, obj in ipairs(gui:GetDescendants()) do inspect(obj) end
gui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then inspect(obj) end
    end)
end)
active.ChildAdded:Connect(function() task.defer(update) end)
active.ChildRemoved:Connect(function() task.defer(update) end)
remote.OnClientEvent:Connect(function(ok, message)
    pending = false
    update()
    if ok then print("[CityGarageStore] " .. tostring(message))
    else warn("[CityGarageStore] " .. tostring(message)) end
end)
print("[CityGarageStore] Oddzielny przycisk gotowy")
