-- City Heist / Krok 61: one cohesive prison forecourt.
-- Studio preview only. Works on the relocated CityPrison; never edits the
-- prison's mechanics, city streets, or original map parts.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local Workspace = game:GetService("Workspace")
local city = Workspace:WaitForChild("CityBlockout", 25)
local prison = Workspace:WaitForChild("CityPrison", 25)
local roads = city and city:FindFirstChild("Roads")
if not (city and prison and roads) then
    warn("[Prison61] Missing CityBlockout / CityPrison / Roads")
    return
end

-- Prevent duplicate Rojo/Studio script copies from building two overlapping lots.
-- Attribute assignment has no yield, so only the first running copy builds.
if Workspace:GetAttribute("CityPrisonAccess61Started") then
    print("[Prison61] Duplicate builder suppressed")
    return
end
Workspace:SetAttribute("CityPrisonAccess61Started", true)

-- The prison-placement script moves the model 4 seconds after startup.
-- Build this layout only after the new site has been decided.
local elapsed = 0
while not prison:GetAttribute("CityPrison55Moved") and elapsed < 12 do
    task.wait(0.5)
    elapsed += 0.5
end
if not prison:GetAttribute("CityPrison55Moved") then
    warn("[Prison61] Prison not relocated; forecourt skipped to prevent misplaced parts")
    return
end
task.wait(0.35)

for _, oldName in ipairs({"CityPrisonGenerated", "CityPrisonAccess56"}) do
    local previous = Workspace:FindFirstChild(oldName)
    if previous then previous:Destroy() end
end
local folder = Instance.new("Folder")
folder.Name = "CityPrisonGenerated"
folder.Parent = Workspace

local DARK = Color3.fromRGB(34, 40, 47)
local ASPHALT = Color3.fromRGB(43, 48, 54)
local WHITE = Color3.fromRGB(241, 238, 224)
local YELLOW = Color3.fromRGB(237, 193, 54)
local CURB = Color3.fromRGB(183, 188, 185)
local GREEN = Color3.fromRGB(66, 116, 62)

local function make(name, size, cf, color, material, collide)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.CanCollide = collide ~= false
    p.CastShadow = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Color = color
    p.Size = size
    p.CFrame = cf
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = folder
    return p
end

local left = prison:FindFirstChild("GatePillarL", true)
local right = prison:FindFirstChild("GatePillarR", true)
if not (left and left:IsA("BasePart") and right and right:IsA("BasePart")) then
    warn("[Prison61] Actual gate pillars unavailable; nothing built")
    folder:Destroy()
    return
end
local gate = (left.Position + right.Position) / 2
local prisonCF = prison:GetBoundingBox()
local out = Vector3.new(gate.X - prisonCF.Position.X, 0, gate.Z - prisonCF.Position.Z)
if out.Magnitude < 2 then
    warn("[Prison61] Invalid gate direction")
    folder:Destroy()
    return
end
out = out.Unit

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {folder}
rayParams.IgnoreWater = true
local function groundY(worldPos)
    local originY = math.max(200, worldPos.Y + 160)
    local result = Workspace:Raycast(
        Vector3.new(worldPos.X, originY, worldPos.Z),
        Vector3.new(0, -900, 0), rayParams)
    if result and result.Normal.Y > 0.65 then return result.Position.Y end
    return nil
end

local footprintWidth, footprintDepth = 130, 96
local gateGap = 15
local lotXZ = gate + out * (gateGap + footprintDepth / 2)
-- Prefer the REAL surface at the parking site, not pillar bottom or road elevation.
local ground = groundY(lotXZ)
if not ground then
    warn("[Prison61] Parking site ground not detected; no geometry generated")
    folder:Destroy()
    return
end
local parkingTop = ground + 0.65
local parkingCenter = Vector3.new(lotXZ.X, parkingTop - 0.38, lotXZ.Z)
-- LookVector = outside / city direction, local -Z = outer parking entrance.
local lotCF = CFrame.lookAt(parkingCenter, parkingCenter + out)

-- Preflight: don't bury the forecourt under any other city building.
local cityObjects = {}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local container = city:FindFirstChild(folderName)
    if container then
        for _,obj in ipairs(container:GetChildren()) do
            if obj:IsA("Model") then table.insert(cityObjects,obj) end
        end
    end
end
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = cityObjects
if #cityObjects > 0 then
    local overlaps = Workspace:GetPartBoundsInBox(
        lotCF, Vector3.new(footprintWidth + 3, 8, footprintDepth + 3), params)
    if #overlaps > 0 then
        warn("[Prison61] Parking area collides with existing city building; skipped")
        folder:Destroy()
        return
    end
end

make("Parking_Asphalt", Vector3.new(footprintWidth,0.76,footprintDepth),
    lotCF, DARK, Enum.Material.Asphalt, true)

-- Two banks of clearly painted spaces flanking a wide CENTER driving aisle.
-- The lane aligns with both the city road and the prison's main gate.
for _,side in ipairs({-1,1}) do
    for i=0,7 do
        local z=-41 + i*11.7
        make("ParkingWhiteLine",Vector3.new(35,0.055,0.22),
            lotCF*CFrame.new(side*40,0.42,z),WHITE,nil,false)
    end
    make("BayOuterLine",Vector3.new(0.25,0.055,82),
        lotCF*CFrame.new(side*57,0.42,0),WHITE,nil,false)
    make("CenterLaneEdge",Vector3.new(0.20,0.055,85),
        lotCF*CFrame.new(side*17,0.42,0),YELLOW,nil,false)
    -- Raised curb next to landscaped border, outside the parked cars.
    make("ParkingCurb",Vector3.new(2,0.65,footprintDepth),
        lotCF*CFrame.new(side*(footprintWidth/2+1),0.55,0),
        CURB,Enum.Material.Concrete)
end
-- Front and back curbs leave the 28-stud central entrance lane open.
for _,side in ipairs({-1,1}) do
    for _,z in ipairs({-footprintDepth/2-1,footprintDepth/2+1}) do
        make("ParkingEndCurb",Vector3.new(49,0.60,2),
            lotCF*CFrame.new(side*39.5,0.52,z),
            CURB,Enum.Material.Concrete)
    end
end
-- Yellow center line is broken, like a real access lane.
for z=-31,34,18 do
    make("ParkingCenterMark",Vector3.new(0.32,0.055,8),
        lotCF*CFrame.new(0,0.43,z),YELLOW,nil,false)
end

local gateGround = groundY(gate + out * 8) or ground
local gateEntry = Vector3.new(gate.X,gateGround+0.62,gate.Z) + out*2
local backPoint=lotCF:PointToWorldSpace(Vector3.new(0,0,footprintDepth/2-1))
local frontPoint=lotCF:PointToWorldSpace(Vector3.new(0,0,-footprintDepth/2+1))
backPoint=Vector3.new(backPoint.X,parkingTop,backPoint.Z)
frontPoint=Vector3.new(frontPoint.X,parkingTop,frontPoint.Z)

local function roadPiece(name,a,b,width,color,withMarkings)
    local diff=b-a
    if diff.Magnitude<1 then return end
    local cf=CFrame.lookAt((a+b)/2,b)
    local length=diff.Magnitude+2.2
    make(name,Vector3.new(width,0.52,length),cf,color,Enum.Material.Asphalt,true)
    if withMarkings then
        for _,side in ipairs({-1,1}) do
            make("RoadEdgeWhite",Vector3.new(0.28,0.055,length-1),
                cf*CFrame.new(side*(width/2-1.2),0.30,0),WHITE,nil,false)
        end
        for z=-length/2+9,length/2-7,22 do
            make("RoadCenterYellow",Vector3.new(0.35,0.055,9),
                cf*CFrame.new(0,0.30,z),YELLOW,nil,false)
        end
    end
end
roadPiece("GateToParkingWalkway",gateEntry,backPoint,16,CURB,false)

local roadParts = {}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>6 and p.Size.Z>6 then
        table.insert(roadParts,p)
    end
end
local function closestRoadSurface(road,worldPos)
    local p=road.CFrame:PointToObjectSpace(worldPos)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(p.X,-road.Size.X/2,road.Size.X/2),
        road.Size.Y/2,
        math.clamp(p.Z,-road.Size.Z/2,road.Size.Z/2)))
end
local function xz(v) return Vector3.new(v.X,0,v.Z) end
local start=frontPoint+out*1.5
local proposals={}
for _,road in ipairs(roadParts) do
    local p=closestRoadSurface(road,start)
    local travel=xz(p-start)
    if travel.Magnitude>6 and travel.Magnitude<700
        and travel.Unit:Dot(out)>-0.25 then
        table.insert(proposals,{road=road,dest=p,dist=travel.Magnitude})
    end
end
table.sort(proposals,function(a,b)return a.dist<b.dist end)

local function clearPath(a,b)
    local delta=xz(b-a)
    if delta.Magnitude<3 then return true end
    local center=(a+b)/2
    local cf=CFrame.lookAt(center,center+delta)
    return #Workspace:GetPartBoundsInBox(cf,
        Vector3.new(29,9,math.max(1,delta.Magnitude-7)),params)==0
end
local route=nil
local selectedRoad=nil
for _,candidate in ipairs(proposals) do
    local p=candidate.dest
    if clearPath(start,p) then
        route={start,p};selectedRoad=candidate.road;break
    end
    for _,d in ipairs({55,110,165}) do
        local bend=start+out*d
        if clearPath(start,bend) and clearPath(bend,p) then
            route={start,bend,p};selectedRoad=candidate.road;break
        end
    end
    if route then break end
end

if route then
    for j=1,#route-1 do
        local a,b=route[j],route[j+1]
        local distance=xz(b-a).Magnitude
        -- Short connected sections conform to the terrain instead of clipping
        -- beneath it or floating above it along a 200+ stud straight segment.
        local segments=math.max(1,math.ceil(distance/32))
        local previousTop=nil
        for k=0,segments-1 do
            local va=a:Lerp(b,k/segments)
            local vb=a:Lerp(b,(k+1)/segments)
            local ya=groundY(va) or a.Y-0.65
            local yb=groundY(vb) or b.Y-0.65
            local aa=Vector3.new(va.X,ya+0.66,va.Z)
            local bb=Vector3.new(vb.X,yb+0.66,vb.Z)
            if j==1 and k==0 then aa=start end
            if j==#route-1 and k==segments-1 then
                bb=Vector3.new(vb.X,b.Y+0.45,vb.Z)
            end
            roadPiece("CityAccessRoad",aa,bb,26,ASPHALT,true)
        end
    end
    print(string.format("[Prison61] Wide access road generated to %s (%d segments)",
        selectedRoad.Name,#route-1))
else
    warn("[Prison61] Road route obstructed; no unsafe connection generated")
end

local function greenStrip(side)
    local cf=lotCF*CFrame.new(side*(footprintWidth/2+9),0.12,0)
    make("GreenVerge",Vector3.new(14,0.35,footprintDepth+8),
        cf,GREEN,Enum.Material.Grass,true)
end
greenStrip(-1);greenStrip(1)

local function treeAt(worldXZ)
    local floor=groundY(worldXZ) or ground
    local stem=Vector3.new(worldXZ.X,floor,worldXZ.Z)
    make("TreeTrunk",Vector3.new(1.5,7,1.5),
        CFrame.new(stem+Vector3.new(0,3.5,0)),
        Color3.fromRGB(96,70,48),Enum.Material.Wood,true)
    local foliage=make("TreeCrown",Vector3.new(7.5,7.5,7.5),
        CFrame.new(stem+Vector3.new(0,9.1,0)),
        Color3.fromRGB(55,126,68),Enum.Material.Grass,false)
    foliage.Shape=Enum.PartType.Ball
end
local function lightAt(worldXZ)
    local floor=groundY(worldXZ) or ground
    local p=Vector3.new(worldXZ.X,floor,worldXZ.Z)
    make("LampPost",Vector3.new(0.65,12,0.65),
        CFrame.new(p+Vector3.new(0,6,0)),
        Color3.fromRGB(65,76,84),Enum.Material.Metal,true)
    local head=make("LampHead",Vector3.new(2.7,0.5,2.7),
        CFrame.new(p+Vector3.new(0,12.3,0)),
        Color3.fromRGB(255,239,182),Enum.Material.Neon,false)
    local lamp=Instance.new("PointLight")
    lamp.Brightness=2;lamp.Range=34;lamp.Parent=head
end

for _,side in ipairs({-1,1}) do
    for _,z in ipairs({-34,0,34}) do
        local pos=lotCF:PointToWorldSpace(Vector3.new(side*(footprintWidth/2+12),0,z))
        treeAt(pos)
    end
    for _,z in ipairs({-42,42}) do
        local pos=lotCF:PointToWorldSpace(Vector3.new(side*(footprintWidth/2+2.5),0,z))
        lightAt(pos)
    end
end

-- Visitor check-in booth, outside the parking bays.
local booth=lotCF:PointToWorldSpace(Vector3.new(footprintWidth/2+20,0,footprintDepth/2-16))
local boothY=groundY(booth) or ground
booth=Vector3.new(booth.X,boothY,booth.Z)
make("GuardBoothFloor",Vector3.new(10,0.5,10),
    CFrame.new(booth+Vector3.new(0,0.25,0)),CURB,Enum.Material.Concrete,true)
for _,x in ipairs({-4.5,4.5}) do
    for _,z in ipairs({-4.5,4.5}) do
        make("BoothFrame",Vector3.new(0.65,7,0.65),
            CFrame.new(booth+Vector3.new(x,4,z)),
            Color3.fromRGB(54,68,76),Enum.Material.Metal,true)
    end
end
make("BoothRoof",Vector3.new(11,0.6,11),
    CFrame.new(booth+Vector3.new(0,7.6,0)),
    Color3.fromRGB(36,53,65),Enum.Material.Metal,true)
for _,z in ipairs({-4.5,4.5}) do
    local glass=make("BoothWindow",Vector3.new(8,6,0.22),
        CFrame.new(booth+Vector3.new(0,4,z)),
        Color3.fromRGB(111,193,214),Enum.Material.Glass,true)
    glass.Transparency=0.48
end
print(string.format("[Prison61] Forecourt built: 130x96, road: %s, ground Y %.2f, lot top Y %.2f",
    route and "generated" or "blocked",ground,parkingTop))
