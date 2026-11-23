-- City Heist: bezpieczne wyciaganie zakupionego Saaba z garazu.
-- Uruchamiane przez Rojo w ServerScriptService.CityHeistRojo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Placement = require(script.Parent:WaitForChild("GroundPlacement"))

local EVENT_NAME = "CityHeistGarageSpawnRequest"
local MODEL_NAME = "Saab_9_3_Turbo_X_Ready"
local VEHICLE_NAME = "Saab 9-3 Turbo X"
local MAX_DISTANCE = 28
local COOLDOWN = 3

local event = ReplicatedStorage:FindFirstChild(EVENT_NAME)
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = EVENT_NAME
    event.Parent = ReplicatedStorage
end

local active = Workspace:FindFirstChild("CityHeistGarageSpawned")
if not active then
    active = Instance.new("Folder")
    active.Name = "CityHeistGarageSpawned"
    active.Parent = Workspace
end

local cooldowns = {}
local function getGarages()
    local city = Workspace:FindFirstChild("CityBlockout")
    return city and city:FindFirstChild("CityGarages")
end

local function nearestGarage(position)
    local garages = getGarages()
    if not garages then return nil end
    local best, distance = nil, math.huge
    for _, garage in ipairs(garages:GetChildren()) do
        local terminal = garage:FindFirstChild("GarageTerminal", true)
        local anchor = terminal and (terminal:IsA("BasePart") and terminal or terminal:FindFirstChildWhichIsA("BasePart", true))
        if anchor then
            local d = (anchor.Position - position).Magnitude
            if d < distance then best, distance = garage, d end
        end
    end
    if distance > MAX_DISTANCE then return nil end
    return best
end

local function freeSlot(garage)
    for _, slot in ipairs(garage:GetDescendants()) do
        if slot:IsA("BasePart") and slot.Name:match("^VehicleSpawn_%d+$") then
            local occupied = false
            for _, vehicle in ipairs(active:GetChildren()) do
                if vehicle:IsA("Model") and vehicle.PrimaryPart then
                    local p = vehicle.PrimaryPart.Position
                    if (Vector3.new(p.X, 0, p.Z) - Vector3.new(slot.Position.X, 0, slot.Position.Z)).Magnitude < 11 then
                        occupied = true
                        break
                    end
                end
            end
            if not occupied then return slot end
        end
    end
end

local function respond(player, ok, message)
    local car = active:FindFirstChild("Vehicle_" .. player.UserId)
    event:FireClient(player, ok, message, car ~= nil)
end

event.OnServerEvent:Connect(function(player, vehicleName)
    if typeof(vehicleName) ~= "string" or vehicleName ~= VEHICLE_NAME then
        respond(player, false, "Ten pojazd nie jest jeszcze obslugiwany")
        return
    end
    local now = os.clock()
    if cooldowns[player] and now - cooldowns[player] < COOLDOWN then return end
    cooldowns[player] = now

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then respond(player, false, "Brak postaci"); return end
    local owned = player:FindFirstChild("OwnedVehicles")
    if not owned or not owned:FindFirstChild(vehicleName) then
        respond(player, false, "Nie posiadasz tego samochodu")
        return
    end
    local garage = nearestGarage(root.Position)
    if not garage then
        respond(player, false, "Podejdz do terminala garazu")
        return
    end
    local previous = active:FindFirstChild("Vehicle_" .. player.UserId)
    if previous then
        previous:Destroy()
        respond(player, true, "Samochod schowany do garazu")
        print("[CityGarageStore]", player.Name, garage.Name)
        return
    end
    local slot = freeSlot(garage)
    if not slot then
        respond(player, false, "Brak wolnych miejsc")
        return
    end
    local sourceFolder = ServerStorage:FindFirstChild("CityHeistVehicles")
    local source = sourceFolder and sourceFolder:FindFirstChild(MODEL_NAME)
    if not source or not source:IsA("Model") then
        respond(player, false, "Brak modelu Saab Ready na serwerze")
        return
    end

    local car = source:Clone()
    car.Name = "Vehicle_" .. player.UserId
    car:SetAttribute("OwnerUserId", player.UserId)
    car.Parent = active
    local ok, err = pcall(function()
        -- Slot ma srodek ~0.65 nad podlozem; umieszczamy podstawe
        -- PhysicsSupport nieco nad gorna powierzchnia slotu.
        local top = slot.Position.Y + slot.Size.Y / 2
        Placement.place(car, Vector3.new(slot.Position.X, top, slot.Position.Z), 0.3)
    end)
    if not ok then
        car:Destroy()
        warn("[CityGarageSpawn] " .. tostring(err))
        respond(player, false, "Nie udalo sie ustawic pojazdu")
        return
    end
    respond(player, true, "Saab wyciagniety z garazu")
    print("[CityGarageSpawn]", player.Name, garage.Name, slot.Name)
end)

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
    local car = active:FindFirstChild("Vehicle_" .. player.UserId)
    if car then car:Destroy() end
end)
print("[CityGarageSpawn] Kontroler Saaba gotowy")
