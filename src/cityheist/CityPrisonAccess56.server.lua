-- CITY HEIST
-- CityPrisonAccess.server.lua
-- Stabilna wersja:
-- 1) wykrywa więzienie
-- 2) szuka najbliższej drogi w CityBlockout.Roads
-- 3) generuje DUŻY parking przed bramą
-- 4) buduje pełną drogę dojazdową do miasta
-- 5) dodaje otoczenie: chodnik, lampy, budkę, zieleń

local Workspace = game:GetService("Workspace")

local CITY = Workspace:WaitForChild("CityBlockout")
local ROADS = CITY:WaitForChild("Roads")
local PRISON = Workspace:WaitForChild("CityPrison")

local GENERATED_NAME = "CityPrisonGenerated"

local PARKING_WIDTH = 76
local PARKING_LENGTH = 100
local ROAD_WIDTH = 18
local SIDEWALK_WIDTH = 6

local function log(...)
	print("[PrisonAccessFixed]", ...)
end

local function clearGenerated()
	local old = Workspace:FindFirstChild(GENERATED_NAME)
	if old then
		old:Destroy()
	end
end

local function makeFolder()
	local folder = Instance.new("Folder")
	folder.Name = GENERATED_NAME
	folder.Parent = Workspace
	return folder
end

local function createPart(parent, name, size, cf, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = true
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.fromRGB(120, 120, 120)
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function createModel(parent, name)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local function gatherRoadParts(root, out)
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(out, child)
		else
			gatherRoadParts(child, out)
		end
	end
end

local function findNearestPointOnPartXZ(part, worldPoint)
	local localPoint = part.CFrame:PointToObjectSpace(worldPoint)
	local sx = part.Size.X * 0.5
	local sz = part.Size.Z * 0.5

	local clampedX = math.clamp(localPoint.X, -sx, sx)
	local clampedZ = math.clamp(localPoint.Z, -sz, sz)

	local result = part.CFrame:PointToWorldSpace(Vector3.new(clampedX, 0, clampedZ))
	return Vector3.new(result.X, part.Position.Y + part.Size.Y * 0.5, result.Z)
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function distanceXZ(a, b)
	return (flat(a) - flat(b)).Magnitude
end

local function findGateCenter()
	local left = PRISON:FindFirstChild("GatePillarL", true)
	local right = PRISON:FindFirstChild("GatePillarR", true)

	if left and right and left:IsA("BasePart") and right:IsA("BasePart") then
		return (left.Position + right.Position) * 0.5
	end

	local gate = PRISON:FindFirstChild("Gate", true)
		or PRISON:FindFirstChild("MainGate", true)
		or PRISON:FindFirstChild("Entrance", true)

	if gate and gate:IsA("BasePart") then
		return gate.Position
	end

	local cf = PRISON:GetPivot()
	return cf.Position
end

local function findNearestRoadPoint(fromPoint)
	local roads = {}
	gatherRoadParts(ROADS, roads)

	local bestPart = nil
	local bestPoint = nil
	local bestDistance = math.huge

	for _, road in ipairs(roads) do
		local p = findNearestPointOnPartXZ(road, fromPoint)
		local d = distanceXZ(fromPoint, p)
		if d < bestDistance then
			bestDistance = d
			bestDistance = d
			bestPart = road
			bestPoint = p
		end
	end

	return bestPart, bestPoint, bestDistance
end

local function midpoint(a, b)
	return (a + b) * 0.5
end

local function buildRectBetween(parent, name, a, b, width, thickness, color, material)
	local dir = flat(b - a)
	local len = dir.Magnitude
	if len < 1 then
		return nil
	end

	local center = midpoint(a, b)
	local look = CFrame.lookAt(center, center + dir.Unit)
	local cf = look
	local size = Vector3.new(width, thickness, len)

	return createPart(parent, name, size, cf, color, material)
end

local function buildAxisRoad(parent, a, b, namePrefix)
	local ax = Vector3.new(a.X, a.Y, a.Z)
	local bx = Vector3.new(b.X, a.Y, a.Z)
	local cx = Vector3.new(b.X, a.Y, b.Z)

	if math.abs(a.X - b.X) > 0.5 then
		buildRectBetween(
			parent,
			namePrefix .. "_A",
			ax,
			bx,
			ROAD_WIDTH,
			1,
			Color3.fromRGB(58, 58, 62),
			Enum.Material.Asphalt
		)
	end

	if math.abs(a.Z - b.Z) > 0.5 then
		buildRectBetween(
			parent,
			namePrefix .. "_B",
			bx,
			cx,
			ROAD_WIDTH,
			1,
			Color3.fromRGB(58, 58, 62),
			Enum.Material.Asphalt
		)
	end
end

local function createParkingLines(parent, parkingCenter, forward, right, width, length)
	local linesModel = createModel(parent, "ParkingLines")
	local rows = 2
	local spacesPerRow = 8
	local rowOffset = length * 0.22
	local usableWidth = width - 14
	local spacing = usableWidth / spacesPerRow

	for row = 1, rows do
		local sign = row == 1 and -1 or 1
		local zBase = sign * rowOffset

		for i = 1, spacesPerRow do
			local x = -usableWidth * 0.5 + spacing * (i - 0.5)
			local pos = parkingCenter + right * x + forward * zBase

			local stripe1 = createPart(
				linesModel,
				"Stripe",
				Vector3.new(0.25, 0.08, 8),
				CFrame.lookAt(pos, pos + forward),
				Color3.fromRGB(240, 240, 240),
				Enum.Material.Neon
			)

			local stripe2 = createPart(
				linesModel,
				"Stripe",
				Vector3.new(0.25, 0.08, 8),
				CFrame.lookAt(pos + right * (spacing * 0.45), pos + right * (spacing * 0.45) + forward),
				Color3.fromRGB(240, 240, 240),
				Enum.Material.Neon
			)

			stripe1.CanCollide = false
			stripe2.CanCollide = false
		end
	end
end

local function createLamp(parent, position)
	local model = createModel(parent, "LampPost")

	local pole = createPart(
		model,
		"Pole",
		Vector3.new(0.7, 10, 0.7),
		CFrame.new(position + Vector3.new(0, 5, 0)),
		Color3.fromRGB(70, 70, 75),
		Enum.Material.Metal
	)

	local arm = createPart(
		model,
		"Arm",
		Vector3.new(3, 0.35, 0.35),
		CFrame.new(position + Vector3.new(1.2, 9.6, 0)),
		Color3.fromRGB(70, 70, 75),
		Enum.Material.Metal
	)

	local light = createPart(
		model,
		"Light",
		Vector3.new(1.4, 0.2, 0.8),
		CFrame.new(position + Vector3.new(2.3, 9.35, 0)),
		Color3.fromRGB(255, 245, 170),
		Enum.Material.Neon
	)

	pole.CanCollide = true
	arm.CanCollide = true
	light.CanCollide = false
end

local function createTree(parent, position)
	local model = createModel(parent, "Tree")

	createPart(
		model,
		"Trunk",
		Vector3.new(1.2, 6, 1.2),
		CFrame.new(position + Vector3.new(0, 3, 0)),
		Color3.fromRGB(96, 66, 38),
		Enum.Material.Wood
	)

	local crown = Instance.new("Part")
	crown.Name = "Crown"
	crown.Shape = Enum.PartType.Ball
	crown.Anchored = true
	crown.CanCollide = true
	crown.Size = Vector3.new(6, 6, 6)
	crown.CFrame = CFrame.new(position + Vector3.new(0, 7.5, 0))
	crown.Color = Color3.fromRGB(64, 124, 64)
	crown.Material = Enum.Material.Grass
	crown.Parent = model
end

local function createBush(parent, position, sizeX, sizeZ)
	local bush = createPart(
		parent,
		"Bush",
		Vector3.new(sizeX, 2, sizeZ),
		CFrame.new(position + Vector3.new(0, 1, 0)),
		Color3.fromRGB(72, 125, 70),
		Enum.Material.Grass
	)
	bush.Shape = Enum.PartType.Ball
	return bush
end

local function createGuardBooth(parent, position, forward)
	local model = createModel(parent, "GuardBooth")

	local base = createPart(
		model,
		"Base",
		Vector3.new(8, 0.6, 8),
		CFrame.new(position + Vector3.new(0, 0.3, 0)),
		Color3.fromRGB(145, 145, 145),
		Enum.Material.Concrete
	)

	local booth = createPart(
		model,
		"Booth",
		Vector3.new(6, 5, 6),
		CFrame.lookAt(position + Vector3.new(0, 2.8, 0), position + Vector3.new(0, 2.8, 0) + forward),
		Color3.fromRGB(210, 220, 230),
		Enum.Material.SmoothPlastic
	)

	local roof = createPart(
		model,
		"Roof",
		Vector3.new(7, 0.4, 7),
		CFrame.lookAt(position + Vector3.new(0, 5.4, 0), position + Vector3.new(0, 5.4, 0) + forward),
		Color3.fromRGB(55, 60, 70),
		Enum.Material.Metal
	)

	base.CanCollide = true
	booth.CanCollide = true
	roof.CanCollide = true
end

local function createSidewalk(parent, a, b)
	buildRectBetween(
		parent,
		"Sidewalk",
		a,
		b,
		SIDEWALK_WIDTH,
		0.5,
		Color3.fromRGB(185, 185, 185),
		Enum.Material.Concrete
	)
end

local function createEnvironment(parent, parkingCenter, forward, right, width, length)
	-- Lampy parkingowe
	createLamp(parent, parkingCenter + right * (-width * 0.42) + forward * (-length * 0.38))
	createLamp(parent, parkingCenter + right * ( width * 0.42) + forward * (-length * 0.38))
	createLamp(parent, parkingCenter + right * (-width * 0.42) + forward * ( length * 0.38))
	createLamp(parent, parkingCenter + right * ( width * 0.42) + forward * ( length * 0.38))

	-- Drzewka
	createTree(parent, parkingCenter + right * (-width * 0.60) + forward * (-length * 0.55))
	createTree(parent, parkingCenter + right * ( width * 0.60) + forward * (-length * 0.55))
	createTree(parent, parkingCenter + right * (-width * 0.60) + forward * ( length * 0.55))
	createTree(parent, parkingCenter + right * ( width * 0.60) + forward * ( length * 0.55))

	-- Krzaki
	createBush(parent, parkingCenter + right * (-width * 0.52), 6, 3)
	createBush(parent, parkingCenter + right * ( width * 0.52), 6, 3)
end

clearGenerated()
local generated = makeFolder()

local prisonCF, prisonSize = PRISON:GetBoundingBox()
local prisonCenter = prisonCF.Position
local gateCenter = findGateCenter()

local _, nearestRoadPoint, nearestDistance = findNearestRoadPoint(gateCenter)
if not nearestRoadPoint then
	warn("[PrisonAccessFixed] Nie znaleziono drogi w CityBlockout.Roads")
	return
end

local outward = flat(gateCenter - prisonCenter)
if outward.Magnitude < 0.1 then
	outward = flat(nearestRoadPoint - gateCenter)
end
if outward.Magnitude < 0.1 then
	outward = Vector3.new(0, 0, -1)
else
	outward = outward.Unit
end

-- Jeśli skierowane "do środka", odwróć na miasto
local toRoad = flat(nearestRoadPoint - gateCenter)
if toRoad.Magnitude > 0.1 and outward:Dot(toRoad.Unit) < 0 then
	outward = -outward
end

local right = Vector3.new(-outward.Z, 0, outward.X)

-- DUŻY parking bezpośrednio przed bramą
local parkingBackEdgeOffset = 16
local parkingCenter =
	Vector3.new(gateCenter.X, nearestRoadPoint.Y + 0.55, gateCenter.Z)
	+ outward * (parkingBackEdgeOffset + PARKING_LENGTH * 0.5)

local parking = createPart(
	generated,
	"VisitorParking",
	Vector3.new(PARKING_WIDTH, 1, PARKING_LENGTH),
	CFrame.lookAt(parkingCenter, parkingCenter + outward),
	Color3.fromRGB(65, 67, 70),
	Enum.Material.Asphalt
)

-- Chodnik od parkingu do bramy
local walkwayStart = parkingCenter - outward * (PARKING_LENGTH * 0.5 - 8)
local walkwayEnd = Vector3.new(gateCenter.X, parkingCenter.Y, gateCenter.Z) + outward * 2
createSidewalk(generated, walkwayStart, walkwayEnd)

-- Budka ochrony
local boothPos = parkingCenter + right * (PARKING_WIDTH * 0.34) - outward * (PARKING_LENGTH * 0.22)
createGuardBooth(generated, boothPos, outward)

-- Linie parkingowe
createParkingLines(generated, parkingCenter, outward, right, PARKING_WIDTH, PARKING_LENGTH)

-- Droga dojazdowa z miasta do parkingu
local roadEntry = parkingCenter - outward * (PARKING_LENGTH * 0.5 + 8)
roadEntry = Vector3.new(roadEntry.X, nearestRoadPoint.Y + 0.5, roadEntry.Z)

buildAxisRoad(generated, nearestRoadPoint + Vector3.new(0, 0.1, 0), roadEntry + Vector3.new(0, 0.1, 0), "AccessRoad")

-- Mały plac łączący drogę z parkingiem
createPart(
	generated,
	"ParkingConnector",
	Vector3.new(ROAD_WIDTH + 4, 1, 16),
	CFrame.lookAt(roadEntry + outward * 8, roadEntry + outward * 20),
	Color3.fromRGB(65, 67, 70),
	Enum.Material.Asphalt
)

-- Lampy i zieleń
createEnvironment(generated, parkingCenter, outward, right, PARKING_WIDTH, PARKING_LENGTH)

log("Więzienie naprawione.")
log("Gate center:", gateCenter)
log("Nearest road point:", nearestRoadPoint)
log("Distance to city road:", math.floor(nearestDistance + 0.5), "studs")
log("Parking:", PARKING_WIDTH .. "x" .. PARKING_LENGTH)
log("Wygenerowano folder:", GENERATED_NAME)