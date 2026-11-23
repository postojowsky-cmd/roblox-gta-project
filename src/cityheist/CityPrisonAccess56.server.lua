-- CITY HEIST: Prison Visitor Area v3 (Studio preview).
-- Wait for prison placement, preserve prison internals, and create one coherent
-- visitor parking / entry apron / city access with roadside greenery.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Workspace = game:GetService("Workspace")
local city = Workspace:WaitForChild("CityBlockout", 25)
local prison = Workspace:WaitForChild("CityPrison", 25)
local roads = city and city:FindFirstChild("Roads")
if not (city and prison and roads) then
    warn("[Prison60] Missing CityBlockout, CityPrison, or Roads")
    return
end

-- CityPrisonPlacement55 waits 4 seconds before relocating the entire model.
task.wait(8)

for _, oldName in ipairs({"CityPrisonGenerated", "CityPrisonAccess56"}) do
    local old = Workspace:FindFirstChild(oldName)
    if old then old:Destroy() end
end

local generated = Instance.new("Folder")
generated.Name = "CityPrisonGenerated"
generated.Parent = Workspace

local function part(name, parent, size, cf, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Size = size
    p.CFrame = cf
    p.Parent = parent
    return p
end

local asphalt = Color3.fromRGB(59, 64, 70)
local white = Color3.fromRGB(231, 232, 224)
local concrete = Color3.fromRGB(173, 180, 182)
local green = Color3.fromRGB(63, 121, 67)

local left = prison:FindFirstChild("GatePillarL", true)
local right = prison:FindFirstChild("GatePillarR", true)
if not (left and right and left:IsA("BasePart") and right:IsA("BasePart")) then
    warn("[Prison60] GatePillarL/R unavailable; nothing generated")
    generated:Destroy()
    return
end

local gate = (left.Position + right.Position) / 2
local bounds = prison:GetBoundingBox()
local outward = Vector3.new(gate.X - bounds.Position.X, 0, gate.Z - bounds.Position.Z)
if outward.Magnitude < 2 then
    warn("[Prison60] Cannot determine the gate's outside direction")
    generated:Destroy()
    return
end
outward = outward.Unit

-- Ground level at the actual gate, never the height of a distant city road.
local gateGround = math.min(left.Position.Y - left.Size.Y / 2, right.Position.Y - right.Size.Y / 2)
local y = gateGround + 0.13
local width, depth = 102, 82
local gapToGate = 12
local middle = Vector3.new(gate.X, y, gate.Z) + outward * (gapToGate + depth / 2)
-- CFrame.LookVector points OUTWARD (local negative Z toward the city).
local parkingCF = CFrame.lookAt(middle, middle + outward)
local parking = part("VisitorParking", generated, Vector3.new(width, 0.30, depth),
    parkingCF, asphalt, Enum.Material.Asphalt)

-- Keep parking rows on both outer thirds, leaving the middle clear for cars.
for _, z in ipairs({-25, 25}) do
    for i = 0, 8 do
        local x = -44 + i * 11
        part("BayDivider", generated, Vector3.new(0.24, 0.05, 19),
            parkingCF * CFrame.new(x, 0.19, z), white, nil, false)
    end
    part("BayEnd", generated, Vector3.new(88, 0.05, 0.25),
        parkingCF * CFrame.new(0, 0.19, z + (z < 0 and -9.5 or 9.5)),
        white, nil, false)
end

local function strip(name, a, b, w, thickness, material, color)
    local difference = b - a
    if difference.Magnitude < 1.5 then return nil end
    local midpoint = (a + b) / 2
    local cf = CFrame.lookAt(midpoint, b)
    return part(name, generated, Vector3.new(w, thickness, difference.Magnitude + 2.5),
        cf, color or asphalt, material or Enum.Material.Asphalt)
end

local toXZ = function(v) return Vector3.new(v.X, 0, v.Z) end
local gatePoint = Vector3.new(gate.X, y, gate.Z)
local lotBack = parkingCF:PointToWorldSpace(Vector3.new(0, 0, depth / 2 - 1))
local lotFront = parkingCF:PointToWorldSpace(Vector3.new(0, 0, -depth / 2 + 1))
strip("GateWalkway", gatePoint, lotBack, 13, 0.26, Enum.Material.Concrete, concrete)

local roadParts = {}
for _, p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X > 5 and p.Size.Z > 5 then
        table.insert(roadParts, p)
    end
end

local obstacles = {}
for _, folderName in ipairs({"GameplayLocations", "Downtown", "CityLocations", "CityGarages"}) do
    local folder = city:FindFirstChild(folderName)
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") then table.insert(obstacles, model) end
        end
    end
end
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances = obstacles

local function roadSurfacePoint(road, from)
    local localPoint = road.CFrame:PointToObjectSpace(from)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(localPoint.X, -road.Size.X / 2, road.Size.X / 2),
        road.Size.Y / 2,
        math.clamp(localPoint.Z, -road.Size.Z / 2, road.Size.Z / 2)
    ))
end
local function segmentIsClear(a, b)
    local direction = toXZ(b - a)
    if direction.Magnitude < 4 then return true end
    local midpoint = (a + b) / 2
    local cf = CFrame.lookAt(midpoint, midpoint + direction)
    -- Collisions with the movable buildings; roads and ground are excluded.
    return #Workspace:GetPartBoundsInBox(cf,
        Vector3.new(22, 7, math.max(1, direction.Magnitude - 6)), overlap) == 0
end

local start = Vector3.new(lotFront.X, y, lotFront.Z) + outward * 2
local proposals = {}
for _, road in ipairs(roadParts) do
    local pt = roadSurfacePoint(road, start)
    local horizontal = toXZ(pt - start)
    local dist = horizontal.Magnitude
    if dist > 8 and dist < 650 and horizontal.Unit:Dot(outward) > -0.2 then
        table.insert(proposals, {road = road, pt = pt, distance = dist})
    end
end
table.sort(proposals, function(a, b) return a.distance < b.distance end)

local route = nil
for _, candidate in ipairs(proposals) do
    local dest = candidate.pt + Vector3.new(0, 0.16, 0)
    if segmentIsClear(start, dest) then
        route = {start, dest}
        break
    end
    -- An outward leg followed by a turn can avoid a building on the direct line.
    for _, initial in ipairs({45, 80, 115}) do
        local bend = start + outward * initial
        if segmentIsClear(start, bend) and segmentIsClear(bend, dest) then
            route = {start, bend, dest}
            break
        end
    end
    if route then break end
end

if route then
    -- Draw a connected carriageway; ramp segments follow any small height difference.
    for i = 1, #route - 1 do
        strip("CityAccessRoad_" .. i, route[i], route[i + 1], 18,
            0.36, Enum.Material.Asphalt, asphalt)
    end
    print(string.format("[Prison60] Road connected: %d sections, %.0f studs from parking",
        #route - 1, (toXZ(route[#route] - route[1])).Magnitude))
else
    warn("[Prison60] No clear road route found; parking built, city connection skipped")
end

local function lamp(position)
    local post = part("LightPole", generated, Vector3.new(0.65, 11, 0.65),
        CFrame.new(position + Vector3.new(0, 5.5, 0)),
        Color3.fromRGB(65, 74, 79), Enum.Material.Metal)
    local head = part("LightHead", generated, Vector3.new(2.5, 0.55, 2.5),
        CFrame.new(position + Vector3.new(0, 11.2, 0)),
        Color3.fromRGB(244, 234, 181), Enum.Material.Neon, false)
    local light = Instance.new("PointLight")
    light.Range = 36
    light.Brightness = 1.7
    light.Parent = head
end
local function tree(position)
    part("TreeTrunk", generated, Vector3.new(1.5, 6, 1.5),
        CFrame.new(position + Vector3.new(0, 3, 0)),
        Color3.fromRGB(103, 78, 55), Enum.Material.Wood)
    local leaves = part("TreeLeaves", generated, Vector3.new(7, 7, 7),
        CFrame.new(position + Vector3.new(0, 8, 0)),
        green, Enum.Material.Grass, false)
    leaves.Shape = Enum.PartType.Ball
end

for _, x in ipairs({-width / 2 - 7, width / 2 + 7}) do
    for _, z in ipairs({-depth / 2 + 8, depth / 2 - 8}) do
        local pos = parkingCF:PointToWorldSpace(Vector3.new(x, 0, z))
        lamp(Vector3.new(pos.X, gateGround, pos.Z))
    end
end
for _, x in ipairs({-width / 2 - 14, width / 2 + 14}) do
    for _, z in ipairs({-depth / 2 + 12, depth / 2 - 12}) do
        local pos = parkingCF:PointToWorldSpace(Vector3.new(x, 0, z))
        tree(Vector3.new(pos.X, gateGround, pos.Z))
    end
end

-- Security booth is outside the parking bays and clear of the central drive aisle.
local boothPos = parkingCF:PointToWorldSpace(Vector3.new(width / 2 + 9, 0, depth / 2 - 18))
part("GuardBoothBase", generated, Vector3.new(9, 0.5, 9),
    CFrame.new(boothPos + Vector3.new(0, 0.1, 0)), concrete, Enum.Material.Concrete)
for _, dx in ipairs({-4, 4}) do
    for _, dz in ipairs({-4, 4}) do
        part("BoothCorner", generated, Vector3.new(0.6, 7, 0.6),
            CFrame.new(boothPos + Vector3.new(dx, 3.7, dz)),
            Color3.fromRGB(74, 89, 96), Enum.Material.Metal)
    end
end
part("BoothRoof", generated, Vector3.new(10, 0.6, 10),
    CFrame.new(boothPos + Vector3.new(0, 7.5, 0)),
    Color3.fromRGB(48, 58, 65), Enum.Material.Metal)
for _, dx in ipairs({-4, 4}) do
    part("BoothWindow", generated, Vector3.new(0.25, 5, 7),
        CFrame.new(boothPos + Vector3.new(dx, 4.2, 0)),
        Color3.fromRGB(132, 211, 232), Enum.Material.Glass, true).Transparency = 0.5
end
for _, dz in ipairs({-4, 4}) do
    part("BoothWindow", generated, Vector3.new(7, 5, 0.25),
        CFrame.new(boothPos + Vector3.new(0, 4.2, dz)),
        Color3.fromRGB(132, 211, 232), Enum.Material.Glass, true).Transparency = 0.5
end
print(string.format("[Prison60] Visitor area ready, parking %dx%d, gate Y %.1f",
    width, depth, gateGround))
