-- Install the shop UI in a client-executable location.
local Players = game:GetService("Players")
local source = script.Parent:WaitForChild("CityHeistShopClient")
local function install(player)
    local gui = player:WaitForChild("PlayerGui")
    if gui:FindFirstChild("CityHeistShopClient") then return end
    local copy = source:Clone()
    copy.Name = "CityHeistShopClient"
    copy.Parent = gui
    copy.Enabled = true
end
Players.PlayerAdded:Connect(install)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(install, player) end
