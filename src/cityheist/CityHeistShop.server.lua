-- City Heist MVP Shops v1: 4 stores, server-authoritative purchases.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local locations = Workspace:WaitForChild("CityBlockout"):WaitForChild("GameplayLocations")
local event = RS:FindFirstChild("CityHeistShopEvent") or Instance.new("RemoteEvent")
event.Name = "CityHeistShopEvent"
event.Parent = RS
local items = {
    Snack = {price = 75, heal = 20, label = "Przekaska"},
    Medkit = {price = 250, heal = 75, label = "Apteczka"},
}
local terminals = {}
local lastPurchase = {}

local function playerNear(player, part)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return root and hum and hum.Health > 0 and (root.Position - part.Position).Magnitude <= 18
end

local interiorBuilder = require(script.Parent:WaitForChild("CityHeistShopInterior"))

for i = 1, 4 do
    local shop = locations:FindFirstChild("Shop_" .. i)
    if shop and shop:IsA("Model") then
        local ok, terminal = pcall(function()
            return interiorBuilder.build(shop, i)
        end)
        if ok and terminal then
            terminals[i] = terminal
            local prompt = terminal:FindFirstChild("OpenShop")
            prompt.Triggered:Connect(function(player)
                if playerNear(player, terminal) then
                    event:FireClient(player, "Open", i)
                end
            end)
            print("[CityHeistShop] Sklep " .. i .. ": wnetrze, kasa i zaplecze gotowe")
        else
            warn("[CityHeistShop] Blad budowania sklepu " .. i .. ": " .. tostring(terminal))
        end
    else
        warn("[CityHeistShop] Nie znaleziono Shop_" .. i)
    end
end

event.OnServerEvent:Connect(function(player, action, shopId, itemId)
    if action ~= "Buy" or type(shopId) ~= "number" or shopId % 1 ~= 0 then return end
    local terminal = terminals[shopId]
    local item = items[itemId]
    if not terminal or not item or not playerNear(player, terminal) then return end
    local now = os.clock()
    if now - (lastPurchase[player] or 0) < 0.7 then return end
    lastPurchase[player] = now
    local stats = player:FindFirstChild("leaderstats")
    local money = stats and stats:FindFirstChild("Money")
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if not money or not money:IsA("IntValue") or not humanoid then return end
    if money.Value < item.price then
        event:FireClient(player, "Result", false, "Za malo pieniedzy!")
        return
    end
    if humanoid.Health >= humanoid.MaxHealth then
        event:FireClient(player, "Result", false, "Masz pelne zdrowie!")
        return
    end
    money.Value -= item.price
    humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + item.heal)
    event:FireClient(player, "Result", true, item.label .. " kupiona! -" .. item.price .. " Money")
    print("[CityHeistShop]", player.Name, "kupil", itemId, "w Shop_" .. shopId)
end)
Players.PlayerRemoving:Connect(function(player) lastPurchase[player] = nil end)
