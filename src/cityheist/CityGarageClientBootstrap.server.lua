-- Kopiuje LocalScript z bezpiecznego folderu Rojo do PlayerGui.
-- Nie zmienia oryginalnego VehicleGarageGUI.
local Players = game:GetService("Players")
local template = script.Parent:WaitForChild("CityGarageClientBridge")
local function setup(player)
    local gui = player:WaitForChild("PlayerGui")
    if gui:FindFirstChild(template.Name) then return end
    local copy = template:Clone()
    copy.Parent = gui
end
Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(setup, player)
end
