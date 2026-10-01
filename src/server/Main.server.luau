local Players = game:GetService("Players")

local EconomyService = require(script.Parent.EconomyService)

print("Roblox City Heist - serwer uruchomiony!")

Players.PlayerAdded:Connect(function(player)
	EconomyService.SetupPlayer(player)
end)