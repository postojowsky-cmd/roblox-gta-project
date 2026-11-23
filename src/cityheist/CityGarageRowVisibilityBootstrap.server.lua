-- Bootstrap isolated visibility fix, without changing existing garage scripts.
local Players = game:GetService("Players")
local template = script.Parent:WaitForChild("CityGarageRowVisibilityFix")
local function setup(player)
    local gui = player:WaitForChild("PlayerGui")
    if gui:FindFirstChild(template.Name) then return end
    local copy = template:Clone()
    copy.Parent = gui
end
Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(setup, player) end
