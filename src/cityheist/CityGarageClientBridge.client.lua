-- City Heist: most do istniejacego GUI bez modyfikacji VehicleGarageGUI.
-- Skrypt jest kopiowany do PlayerGui przez CityGarageClientBootstrap.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local event = ReplicatedStorage:WaitForChild("CityHeistGarageSpawnRequest")
local TARGET = "Saab 9-3 Turbo X"
local wired = setmetatable({}, {__mode = "k"})
local busy = false
local spawned = workspace:WaitForChild("CityHeistGarageSpawned")
local vehicleId = "Vehicle_" .. player.UserId
local function hasVehicle()
    return spawned:FindFirstChild(vehicleId) ~= nil
end
local function refreshButtons()
    for button in pairs(wired) do
        if button.Parent then
            button.Active = not busy
            button.AutoButtonColor = not busy
            button.Text = busy and "PROSZE CZEKAC..." or (hasVehicle() and "SCHOWAJ POJAZD" or "WYCIAGNIJ POJAZD")
        end
    end
end

local function connectButton(obj)
    if not obj:IsA("TextButton") or wired[obj] then return end
    if obj.Text ~= "WYCIAGNIJ POJAZD (WKROTCE)" then return end
    local row = obj.Parent
    if not row or not row:IsA("Frame") then return end
    local matches = false
    for _, child in ipairs(row:GetChildren()) do
        if child:IsA("TextLabel") and child.Text == TARGET then
            matches = true
            break
        end
    end
    if not matches then return end
    wired[obj] = true
    refreshButtons()
    obj.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true
        refreshButtons()
        event:FireServer(TARGET)
        task.delay(4, function()
            if busy then
                busy = false
                refreshButtons()
            end
        end)
    end)
end

local gui = player:WaitForChild("PlayerGui")
for _, obj in ipairs(gui:GetDescendants()) do
    connectButton(obj)
end
gui.DescendantAdded:Connect(function(obj)
    -- Button moze zostac utworzony przed etykieta pojazdu.
    task.defer(function()
        if obj.Parent then
            connectButton(obj)
            if obj:IsA("TextLabel") and obj.Parent then
                for _, sibling in ipairs(obj.Parent:GetChildren()) do
                    connectButton(sibling)
                end
            end
        end
    end)
end)
spawned.ChildAdded:Connect(function() task.defer(refreshButtons) end)
spawned.ChildRemoved:Connect(function() task.defer(refreshButtons) end)
event.OnClientEvent:Connect(function(ok, message, isSpawned)
    busy = false
    refreshButtons()
    if ok then
        print("[CityGarage] " .. tostring(message))
    else
        warn("[CityGarage] " .. tostring(message))
    end
end)
print("[CityGarage] Przyciski WYCIAGNIJ/SCHOWAJ podlaczone")
