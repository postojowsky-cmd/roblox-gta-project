local EconomyService = {}

local STARTING_MONEY = 5000

function EconomyService.SetupPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = STARTING_MONEY
	money.Parent = leaderstats

	print("Utworzono konto gracza:", player.Name, "Saldo:", money.Value)
end

function EconomyService.GetMoney(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return 0
	end

	local money = leaderstats:FindFirstChild("Money")
	if not money then
		return 0
	end

	return money.Value
end

function EconomyService.AddMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if money then
		money.Value += amount
	end
end

function EconomyService.RemoveMoney(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	local money = leaderstats and leaderstats:FindFirstChild("Money")

	if not money or money.Value < amount then
		return false
	end

	money.Value -= amount
	return true
end

return EconomyService