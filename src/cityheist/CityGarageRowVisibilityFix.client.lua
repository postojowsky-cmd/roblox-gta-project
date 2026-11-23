-- City Heist: naprawa ukrytych wierszy listy pojazdow.
-- Oddzielny LocalScript uruchamiany w PlayerGui.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local function repair(obj)
    if not obj:IsA("Frame") or not obj.Name:match("^Vehicle_%d+$") then return end
    local list = obj.Parent
    if not list or list.Name ~= "VehicleList" or not list:IsA("ScrollingFrame") then return end
    local panel = list.Parent
    if not panel or panel.Name ~= "GaragePanel" then return end
    if not obj.Visible then
        obj.Visible = true
        print("[GarageRowFix] Przywrocono widocznosc:", obj.Name)
    end
end
for _, obj in ipairs(gui:GetDescendants()) do repair(obj) end
gui.DescendantAdded:Connect(function(obj)
    task.defer(function()
        if obj.Parent then repair(obj) end
    end)
end)
