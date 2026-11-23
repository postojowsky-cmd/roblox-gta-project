-- Independent garage return controller. Does not change the working spawn controller.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local remote = ReplicatedStorage:FindFirstChild("CityHeistGarageStoreRequest")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "CityHeistGarageStoreRequest"
    remote.Parent = ReplicatedStorage
end
local active = Workspace:WaitForChild("CityHeistGarageSpawned")
local lastRequest = {}
local MAX_DISTANCE = 28

local function closeToGarage(position)
    local city = Workspace:FindFirstChild("CityBlockout")
    local garages = city and city:FindFirstChild("CityGarages")
    if not garages then return false end
    for _, garage in ipairs(garages:GetChildren()) do
        local terminal = garage:FindFirstChild("GarageTerminal", true)
        local part = terminal and (terminal:IsA("BasePart") and terminal or terminal:FindFirstChildWhichIsA("BasePart", true))
        if part and (part.Position - position).Magnitude <= MAX_DISTANCE then
            return true
        end
    end
    return false
end

remote.OnServerEvent:Connect(function(player)
    local now = os.clock()
    if lastRequest[player] and now - lastRequest[player] < 2 then return end
    lastRequest[player] = now
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not closeToGarage(root.Position) then
        remote:FireClient(player, false, "Podejdz do terminala garazu")
        return
    end
    local car = active:FindFirstChild("Vehicle_" .. player.UserId)
    if not car or not car:IsA("Model") or car:GetAttribute("OwnerUserId") ~= player.UserId then
        remote:FireClient(player, false, "Nie masz aktywnego samochodu")
        return
    end
    -- Do not delete a car while anyone is seated inside.
    for _, inst in ipairs(car:GetDescendants()) do
        if inst:IsA("Seat") or inst:IsA("VehicleSeat") then
            if inst.Occupant then
                remote:FireClient(player, false, "Najpierw wszyscy musza wysiasc")
                return
            end
        end
    end
    car:Destroy()
    remote:FireClient(player, true, "Samochod schowany do garazu")
    print("[CityGarageStore]", player.Name)
end)
Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
end)
print("[CityGarageStore] Oddzielny kontroler gotowy")
