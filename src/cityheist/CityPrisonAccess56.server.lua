-- City Heist / Krok 62: parking BESIDE the prison, never inside its walls.
-- Studio Play preview only; preserves CityPrison and existing roads.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local W = game:GetService("Workspace")
local city = W:WaitForChild("CityBlockout", 25)
local prison = W:WaitForChild("CityPrison", 25)
local roads = city and city:FindFirstChild("Roads")
if not (city and prison and roads) then
    warn("[Prison62] Missing prison or roads")
    return
end
if W:GetAttribute("CityPrisonParking62Started") then return end
W:SetAttribute("CityPrisonParking62Started", true)

-- Wait for the separate step-57 prison-position controller.
local elapsed = 0
while not prison:GetAttribute("CityPrison55Moved") and elapsed < 15 do
    task.wait(0.25)
    elapsed += 0.25
end
if not prison:GetAttribute("CityPrison55Moved") then
    warn("[Prison62] Prison relocation not confirmed. No parking generated.")
    return
end
task.wait(0.4)

for _,name in ipairs({"CityPrisonGenerated","CityPrisonAccess56"}) do
    local obj = W:FindFirstChild(name)
    if obj then obj:Destroy() end
end
local folder = Instance.new("Folder")
folder.Name = "CityPrisonGenerated"
folder.Parent = W

local asphalt = Color3.fromRGB(38,45,51)
local white = Color3.fromRGB(242,239,229)
local yellow = Color3.fromRGB(245,200,67)
local concrete = Color3.fromRGB(172,181,187)
local function create(name, size, cf, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.Size = size
    p.CFrame = cf
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = folder
    return p
end
local function horizontal(v)
    return Vector3.new(v.X,0,v.Z)
end
local left = prison:FindFirstChild("GatePillarL", true)
local right = prison:FindFirstChild("GatePillarR", true)
if not (left and left:IsA("BasePart") and right and right:IsA("BasePart")) then
    warn("[Prison62] No gate pillars")
    folder:Destroy()
    return
end
local gate = (left.Position + right.Position) * 0.5
local across = horizontal(right.Position - left.Position)
if across.Magnitude < 2 then
    warn("[Prison62] Cannot determine left/right side")
    folder:Destroy()
    return
end
across = across.Unit

local roadParts = {}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X > 5 and p.Size.Z > 5 then
        table.insert(roadParts,p)
    end
end
if #roadParts == 0 then folder:Destroy(); return end

local function closestOnRoad(road,point)
    local localP = road.CFrame:PointToObjectSpace(point)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(localP.X, -road.Size.X / 2, road.Size.X / 2),
        road.Size.Y / 2,
        math.clamp(localP.Z, -road.Size.Z / 2, road.Size.Z / 2)))
end
local function closestCityRoad(point)
    local best,bestDist
    bestDist = math.huge
    for _,road in ipairs(roadParts) do
        local p = closestOnRoad(road,point)
        local d = horizontal(p - point).Magnitude
        if d < bestDist then
            bestDist = d
            best = p
        end
    end
    return best,bestDist
end

-- Gate orientation comes from the two actual pillars. Select the perpendicular
-- that faces the city, not a vector derived from the prison bounding-box center.
local cityPoint = closestCityRoad(gate)
local towardCity = horizontal(cityPoint - gate)
local outward = Vector3.new(-across.Z,0,across.X)
if towardCity:Dot(outward) < 0 then outward = -outward end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {folder}
rayParams.IgnoreWater = true
local function surfaceAt(pos)
    local startY = math.max(350,gate.Y + 170)
    local ray = W:Raycast(Vector3.new(pos.X,startY,pos.Z), Vector3.new(0,-1200,0),rayParams)
    if ray and ray.Normal.Y > 0.65 then return ray end
    return nil
end
local function groundAt(pos)
    local ray=surfaceAt(pos)
    return ray and ray.Position.Y or nil
end

local targets = {}
local buildingFolders = {}
for _,n in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local f=city:FindFirstChild(n)
    if f then table.insert(buildingFolders,f) end
end
local prisonParams = OverlapParams.new()
prisonParams.FilterType = Enum.RaycastFilterType.Include
prisonParams.FilterDescendantsInstances = {prison}
local cityParams = OverlapParams.new()
cityParams.FilterType = Enum.RaycastFilterType.Include
cityParams.FilterDescendantsInstances = buildingFolders

local function blockingPart(p)
    if not p.CanCollide then return false end
    -- Large ground slabs are not a wall; leave them beneath the new asphalt.
    local n = p.Name:lower()
    if p.Size.Y <= 2.5 or n:find("ground",1,true)
        or n:find("floor",1,true) or n:find("baseplate",1,true)
        or n:find("foundation",1,true) or n:find("terrain",1,true) then
        return false
    end
    return true
end
local function blockedByBuildings(cf, size)
    local testCF = cf * CFrame.new(0,2.5,0)
    local testSize = Vector3.new(size.X + 5,8,size.Z + 5)
    for _,p in ipairs(W:GetPartBoundsInBox(testCF,testSize,prisonParams)) do
        if blockingPart(p) then return true end
    end
    for _,p in ipairs(W:GetPartBoundsInBox(testCF,testSize,cityParams)) do
        if blockingPart(p) then return true end
    end
    return false
end
local function overlapsRoad(cf,size)
    -- Treat actual road parts, not their names, as existing infrastructure.
    local cfPoint = cf.Position
    for _,road in ipairs(roadParts) do
        local localPoint = road.CFrame:PointToObjectSpace(cfPoint)
        local distX = math.abs(localPoint.X)
        local distZ = math.abs(localPoint.Z)
        local generousRadius = math.max(size.X,size.Z)/2 + 6
        if distX < road.Size.X/2 + generousRadius
            and distZ < road.Size.Z/2 + generousRadius then
            return true
        end
    end
    return false
end

local WIDTH,DEPTH = 140,112
local chosen,chosenScore
for _,side in ipairs({-1,1}) do
    for _,distance in ipairs({140,170,195,220,260,300}) do
        for _,ahead in ipairs({-5,15,35}) do
            -- This is intentionally HORIZONTAL/LATERAL to the prison gate.
            -- Both candidate sides are outside the prison, never in its courtyard.
            local rawCenter = gate + across * (side * distance) + outward * ahead
            local surface = surfaceAt(rawCenter)
            local floor = surface and surface.Position.Y
            if floor then
                local center = Vector3.new(rawCenter.X,floor + 0.42,rawCenter.Z)
                local cf = CFrame.lookAt(center,center + outward)
                local size=Vector3.new(WIDTH,0.75,DEPTH)
                local stable=true
                for _,corner in ipairs({
                    Vector3.new(-WIDTH/2,0,-DEPTH/2),
                    Vector3.new(WIDTH/2,0,-DEPTH/2),
                    Vector3.new(-WIDTH/2,0,DEPTH/2),
                    Vector3.new(WIDTH/2,0,DEPTH/2)
                }) do
                    local loc=cf:PointToWorldSpace(corner)
                    local level=groundAt(loc)
                    if not level or math.abs(level-floor)>3.5 then
                        stable=false
                        break
                    end
                end
                if stable and not blockedByBuildings(cf,size) and not overlapsRoad(cf,size) then
                    local cityRoad,roadDist = closestCityRoad(center)
                    -- The marked destination is the wide GREY paved apron BESIDE the prison.
                    -- Heavily penalize green grass so we do not pick the crossed-out
                    -- parking across the street again.
                    local part=surface.Instance
                    local col=part.Color
                    local grey=math.abs(col.R-col.G)<0.10 and math.abs(col.G-col.B)<0.10
                    local grass=(surface.Material==Enum.Material.Grass or
                        col.G>col.R*1.16 and col.G>col.B*1.10)
                    local apronBonus=(grey and -2500 or 0)
                    local grassPenalty=(grass and 5000 or 0)
                    local score=distance*1.8 + roadDist*0.15 + math.abs(ahead)*0.4
                        + apronBonus + grassPenalty
                    if not chosen or score < chosenScore then
                        chosen={cf=cf,ground=floor,side=side,offset=distance,roadPoint=cityRoad}
                        chosenScore=score
                    end
                end
            end
        end
    end
end

if not chosen then
    warn("[Prison62] No free plot BESIDE the prison: leaving prison and city untouched")
    folder:Destroy()
    return
end
local lotCF=chosen.cf
local floor=chosen.ground
print(string.format("[Prison62] Parking placed %s of the prison, lateral offset %d studs",
    chosen.side==1 and "RIGHT" or "LEFT",chosen.offset))

create("ParkingBesidePrison",Vector3.new(WIDTH,0.75,DEPTH),
    lotCF,asphalt,Enum.Material.Asphalt,true)

-- Clear two parking rows with a wide center aisle.
for _,z in ipairs({-35,35}) do
    for i=0,8 do
        local x=-62 + i*15.5
        create("ParkingBayLine",Vector3.new(0.24,0.06,24),
            lotCF*CFrame.new(x,0.41,z),white,nil,false)
    end
    create("ParkingRowEnd",Vector3.new(124,0.06,0.25),
        lotCF*CFrame.new(0,0.41,z+(z < 0 and -12 or 12)),white,nil,false)
end
for _,x in ipairs({-WIDTH/2+2,WIDTH/2-2}) do
    create("ParkingSideCurb",Vector3.new(1.2,0.5,DEPTH),
        lotCF*CFrame.new(x,0.38,0),concrete,Enum.Material.Concrete,true)
end
for z=-33,35,22 do
    create("CenterLaneMarking",Vector3.new(0.28,0.06,8),
        lotCF*CFrame.new(0,0.42,z),yellow,nil,false)
end

local function roadway(name,a,b,w,color)
    local horizontalVec=horizontal(b-a)
    if horizontalVec.Magnitude<1 then return end
    local midpoint=(a+b)*0.5
    local cf=CFrame.lookAt(midpoint,b)
    local length=(b-a).Magnitude + 2
    create(name,Vector3.new(w,0.4,length),cf,color,Enum.Material.Asphalt,true)
    for _,side in ipairs({-1,1}) do
        create("RoadEdge",Vector3.new(0.22,0.05,length-1),cf*CFrame.new(side*(w/2-1.1),0.23,0),
            white,nil,false)
    end
end

-- The red sketch connects the parking SIDE facing the city road, not a
-- driveway aimed away from the prison or through the entrance courtyard.
local closestForEntrance=closestCityRoad(lotCF.Position)
local localDirection=lotCF:VectorToObjectSpace(horizontal(closestForEntrance-lotCF.Position))
local sideExit
if math.abs(localDirection.X)>math.abs(localDirection.Z) then
    sideExit=Vector3.new((localDirection.X>=0 and 1 or -1)*(WIDTH/2-2),0,0)
else
    sideExit=Vector3.new(0,0,(localDirection.Z>=0 and 1 or -1)*(DEPTH/2-2))
end
local cityEdge=lotCF:PointToWorldSpace(sideExit)
local start=Vector3.new(cityEdge.X,floor+0.45,cityEdge.Z)

local roadOptions={}
for _,road in ipairs(roadParts) do
    local destination=closestOnRoad(road,start)
    local d=horizontal(destination-start)
    if d.Magnitude>8 and d.Magnitude<630 and d.Unit:Dot(outward)>-0.55 then
        table.insert(roadOptions,{dest=destination,road=road,dist=d.Magnitude})
    end
end
table.sort(roadOptions,function(a,b)return a.dist<b.dist end)
local function clearRoad(a,b)
    local d=horizontal(b-a)
    if d.Magnitude<5 then return true end
    local mid=(a+b)*0.5
    local cf=CFrame.lookAt(mid,mid+d)
    return not blockedByBuildings(cf,Vector3.new(23,0.5,math.max(1,d.Magnitude-8)))
end
local route=nil
for _,option in ipairs(roadOptions) do
    if clearRoad(start,option.dest) then
        route={start,option.dest};break
    end
    for _,leg in ipairs({55,105,155}) do
        local corner=start+outward*leg
        if clearRoad(start,corner) and clearRoad(corner,option.dest) then
            route={start,corner,option.dest}
            break
        end
    end
    if route then break end
end
if route then
    for i=1,#route-1 do
        local a=route[i]
        local b=route[i+1]
        local distance=horizontal(b-a).Magnitude
        local n=math.max(1,math.ceil(distance/28))
        for k=0,n-1 do
            local p=a:Lerp(b,k/n)
            local q=a:Lerp(b,(k+1)/n)
            local py=groundAt(p) or floor
            local qy=groundAt(q) or floor
            roadway("CityPrisonAccessRoad",Vector3.new(p.X,py+0.5,p.Z),
                Vector3.new(q.X,qy+0.5,q.Z),26,asphalt)
        end
    end
    print("[Prison62] Parking connected to city road")
else
    warn("[Prison62] Side parking works; separate city access route not yet clear")
end

-- Do not build the old long diagonal bridge between the parking and gate.
-- Preserve the prison walls. Add only a short pedestrian exit on the lot's
-- outer edge; the rest of the sidewalk network will be fitted with the map.
local sidewalkEnd=lotCF:PointToWorldSpace(Vector3.new(-chosen.side*(WIDTH/2+1),0,0))
local sidewalkStart=lotCF:PointToWorldSpace(Vector3.new(-chosen.side*(WIDTH/2-9),0,0))
local pathY=groundAt(sidewalkEnd) or floor
local a=Vector3.new(sidewalkStart.X,pathY+0.35,sidewalkStart.Z)
local b=Vector3.new(sidewalkEnd.X,pathY+0.35,sidewalkEnd.Z)
local d=horizontal(b-a)
if d.Magnitude>2 then
    local cf=CFrame.lookAt((a+b)*0.5,b)
    create("ParkingPedestrianExit",Vector3.new(6,0.26,d.Magnitude+1),
        cf,concrete,Enum.Material.Concrete,true)
end

local function scenery(localX,localZ)
    local pos=lotCF:PointToWorldSpace(Vector3.new(localX,0,localZ))
    local gy=groundAt(pos) or floor
    local stem=Vector3.new(pos.X,gy,pos.Z)
    create("TreeTrunk",Vector3.new(1.2,5,1.2),
        CFrame.new(stem+Vector3.new(0,2.5,0)),
        Color3.fromRGB(103,76,46),Enum.Material.Wood)
    local crown=create("TreeCrown",Vector3.new(6,6,6),
        CFrame.new(stem+Vector3.new(0,7.1,0)),
        Color3.fromRGB(55,125,67),Enum.Material.Grass,false)
    crown.Shape=Enum.PartType.Ball
end
for _,x in ipairs({-WIDTH/2-8,WIDTH/2+8}) do
    for _,z in ipairs({-DEPTH/2+8,DEPTH/2-8}) do
        scenery(x,z)
    end
end
local function lamp(localX,localZ)
    local pos=lotCF:PointToWorldSpace(Vector3.new(localX,0,localZ))
    local gy=groundAt(pos) or floor
    local base=Vector3.new(pos.X,gy,pos.Z)
    create("ParkingLampPole",Vector3.new(0.6,11,0.6),
        CFrame.new(base+Vector3.new(0,5.5,0)),
        Color3.fromRGB(62,72,81),Enum.Material.Metal)
    local head=create("ParkingLampHead",Vector3.new(2.5,0.5,2.5),
        CFrame.new(base+Vector3.new(0,11.3,0)),
        Color3.fromRGB(255,234,174),Enum.Material.Neon,false)
    local light=Instance.new("PointLight")
    light.Range=34;light.Brightness=2;light.Parent=head
end
for _,x in ipairs({-WIDTH/2-2,WIDTH/2+2}) do
    lamp(x,-43)
    lamp(x,43)
end
print("[Prison64] Side apron location prioritizes GREY land beside prison, not crossed-out grass parking.")
