-- CITY HEIST: testowa wersja Saaba uruchamiana tylko w Play.
-- Oryginal w ServerStorage i istniejace pojazdy pozostaja nietkniete.
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Fix = require(script.Parent:WaitForChild("SaabVisualFix"))
local Placement = require(script.Parent:WaitForChild("GroundPlacement"))

local source = ServerStorage:WaitForChild("CityHeistVehicles"):WaitForChild("Saab_9_3_Turbo_X_Driveable")
local name = "CityHeist_SaabVisualTest"
local existing = Workspace:FindFirstChild(name)
if existing then
    warn("[SaabVisualTest] Test juz istnieje; nie tworze drugiego")
    return
end

local car = source:Clone()
car.Name = name

-- Z poprzednich pomiarow: kola sa 1.716 studa ponizej PhysicsSupport.
-- Przesuwamy tylko wizualna karoserie; naped, fotel i podpora bez zmian.
local delta = 1.71623
local count, removed = Fix.raiseBody(car, delta)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances = {car}
local hit = Workspace:Raycast(Vector3.new(0, 500, 0), Vector3.new(0, -1000, 0), params)
if not hit then
    warn("[SaabVisualTest] Brak podloza w centrum mapy; test pominiety")
    car:Destroy()
    return
end

Placement.place(car, hit.Position, 0.3)
car.Parent = Workspace
print(("[SaabVisualTest] Gotowe: %s | przesunieto %d czesci | usunieto %d spawow | delta=%.3f"):format(name, count, removed, delta))
print("[SaabVisualTest] Wsiadz do testowego Saaba i sprawdz wyglad oraz jazde. Zmiany nie zapisuja sie po Stop.")
