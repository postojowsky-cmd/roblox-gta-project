-- CITY HEIST: step 65 - EXTEND THE EXISTING PRISON DRIVEWAY TO CITY ROADS.
-- There is deliberately NO parking generation in this script.
-- Preview only in Roblox Studio; keeps CityPrison, garages, shops and banks intact.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end

local W = game:GetService("Workspace")
local city = W:WaitForChild("CityBlockout", 25)
local prison = W:WaitForChild("CityPrison", 25)
local roads = city and city:FindFirstChild("Roads")
if not (city and prison and roads) then
    warn("[Prison65] Missing prison or Roads")
    return
end
if W:GetAttribute("PrisonDrive65Running") then return end
W:SetAttribute("PrisonDrive65Running", true)

-- Layout system relocates the prison after 4 seconds.
local waited = 0
while not prison:GetAttribute("CityPrison55Moved") and waited < 18 do
    task.wait(0.25)
    waited += 0.25
end
if not prison:GetAttribute("CityPrison55Moved") then
    warn("[Prison65] Prison relocation not finished: refusing to build misplaced road")
    return
end
task.wait(0.3)

for _,name in ipairs({"CityPrisonGenerated","CityPrisonAccess56"}) do
    local old=W:FindFirstChild(name)
    if old then old:Destroy() end
end
local folder=Instance.new("Folder")
folder.Name="CityPrisonAccessRoad"
folder.Parent=W
local oldRoad=W:FindFirstChild("CityPrisonAccessRoad")
-- Folder is intentionally named for easy identification in Explorer.

local function flat(v)
    return Vector3.new(v.X,0,v.Z)
end
local left=prison:FindFirstChild("GatePillarL",true)
local right=prison:FindFirstChild("GatePillarR",true)
if not (left and left:IsA("BasePart") and right and right:IsA("BasePart")) then
    warn("[Prison65] Gate pillars not found")
    folder:Destroy()
    return
end
local gate=(left.Position+right.Position)/2
local span=flat(right.Position-left.Position)
if span.Magnitude<1 then folder:Destroy();return end
local across=span.Unit

local roadParts={}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>5 and p.Size.Z>5 then
        table.insert(roadParts,p)
    end
end
if #roadParts==0 then folder:Destroy();return end

local function closestPointOnRoad(road,world)
    local loc=road.CFrame:PointToObjectSpace(world)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(loc.X,-road.Size.X/2,road.Size.X/2),
        road.Size.Y/2,
        math.clamp(loc.Z,-road.Size.Z/2,road.Size.Z/2)))
end
-- Determine which side of the gate faces the city, using actual road network.
local closestGateRoad=nil
local closestDistance=math.huge
for _,road in ipairs(roadParts) do
    local p=closestPointOnRoad(road,gate)
    local d=flat(p-gate).Magnitude
    if d<closestDistance then
        closestDistance=d
        closestGateRoad=p
    end
end
local outward=Vector3.new(-across.Z,0,across.X)
if outward:Dot(flat(closestGateRoad-gate))<0 then outward=-outward end

-- Find the END of the existing prison entry-road, so the new road starts
-- exactly where the old one ends instead of building on the courtyard.
local startDistance=12
local sourceRoad=nil
for _,p in ipairs(prison:GetDescendants()) do
    if p:IsA("BasePart") then
        local n=p.Name:lower()
        if n:find("road",1,true) or n:find("drive",1,true)
           or n:find("access",1,true) then
            local dx,dz=p.Size.X,p.Size.Z
            if math.max(dx,dz)>14 and math.min(dx,dz)>3 then
                local dir=p.CFrame.RightVector
                if dz>=dx then dir=p.CFrame.LookVector end
                local half=math.max(dx,dz)/2
                for _,sign in ipairs({-1,1}) do
                    local edge=p.Position+flat(dir)*half*sign
                    local forward=flat(edge-gate):Dot(outward)
                    local lateral=math.abs(flat(edge-gate):Dot(across))
                    if forward>startDistance and forward<450 and lateral<27 then
                        startDistance=forward
                        sourceRoad=p
                    end
                end
            end
        end
    end
end
local start=gate+outward*math.max(10,startDistance-2)

-- Candidate city connections: keep the prison drive STRAIGHT first; turn only
-- at an orthogonal junction when the existing city road is off-axis.
local candidates={}
for _,road in ipairs(roadParts) do
    for _,distance in ipairs({startDistance+25,startDistance+60,startDistance+120,startDistance+200,startDistance+320,startDistance+450}) do
        local probe=gate+outward*distance
        local point=closestPointOnRoad(road,probe)
        local d=flat(point-gate)
        local longitudinal=d:Dot(outward)
        local lateral=d:Dot(across)
        if longitudinal>startDistance+8 and longitudinal<850
            and math.abs(lateral)<450 then
            local score=longitudinal*0.22+math.abs(lateral)*1.0
            table.insert(candidates,{
                point=point,forward=longitudinal,side=lateral,
                score=score,road=road
            })
        end
    end
end
table.sort(candidates,function(a,b) return a.score<b.score end)

-- Check unrelated building walls, but not pavement, for both route segments.
local obstacles={}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local group=city:FindFirstChild(folderName)
    if group then
        for _,obj in ipairs(group:GetChildren()) do
            if obj:IsA("Model") then table.insert(obstacles,obj) end
        end
    end
end
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances=obstacles
local function clearSegment(a,b)
    local v=flat(b-a)
    if v.Magnitude<5 then return true end
    local midpoint=(a+b)/2+Vector3.new(0,3,0)
    local checkCF=CFrame.lookAt(midpoint,midpoint+v)
    for _,p in ipairs(W:GetPartBoundsInBox(checkCF,
        Vector3.new(24,7,math.max(1,v.Magnitude-6)),params)) do
        if p.CanCollide and p.Size.Y>4 then return false end
    end
    return true
end

local selected=nil
for _,candidate in ipairs(candidates) do
    local corner=gate+outward*candidate.forward
    if clearSegment(start,corner) and clearSegment(corner,candidate.point) then
        selected={start,corner,candidate.point}
        print("[Prison65] Selected city road:",candidate.road.Name,
            "forward",math.floor(candidate.forward),"lateral",math.floor(candidate.side))
        break
    end
end
if not selected then
    warn("[Prison65] No collision-free road connection found; no geometry built")
    folder:Destroy()
    return
end

local asphalt=Color3.fromRGB(45,49,55)
local yellow=Color3.fromRGB(235,198,63)
local white=Color3.fromRGB(236,237,230)
local function create(name,size,cf,color,collidable)
    local p=Instance.new("Part")
    p.Name=name
    p.Anchored=true
    p.CanCollide=collidable~=false
    p.Color=color
    p.Material=Enum.Material.Asphalt
    p.Size=size
    p.CFrame=cf
    p.Parent=folder
    return p
end

local function groundHeight(pos)
    local gateY=math.min(left.Position.Y-left.Size.Y/2,right.Position.Y-right.Size.Y/2)
    local probe=Vector3.new(pos.X,math.max(180,gateY+140),pos.Z)
    local opts=RaycastParams.new()
    opts.FilterType=Enum.RaycastFilterType.Exclude
    opts.FilterDescendantsInstances={folder,prison}
    local ray=W:Raycast(probe,Vector3.new(0,-700,0),opts)
    if ray and ray.Normal.Y>0.75 then return ray.Position.Y end
    return gateY
end

local function pavedSegment(a,b,first)
    local v=flat(b-a)
    if v.Magnitude<2 then return end
    local count=math.max(1,math.ceil(v.Magnitude/36))
    for i=1,count do
        local p=a:Lerp(b,(i-1)/count)
        local q=a:Lerp(b,i/count)
        local groundP=groundHeight(p)
        local groundQ=groundHeight(q)
        -- All road pieces use the same top-level height as the ground,
        -- avoiding the floating planks visible in earlier screenshots.
        local aa=Vector3.new(p.X,groundP+0.2,p.Z)
        local bb=Vector3.new(q.X,groundQ+0.2,q.Z)
        local vector=bb-aa
        local cf=CFrame.lookAt((aa+bb)/2,bb)
        local length=vector.Magnitude+1.5
        create("PrisonRoadExtension",Vector3.new(22,0.5,length),cf,asphalt,true)
        for _,side in ipairs({-1,1}) do
            create("RoadEdgeWhite",Vector3.new(0.28,0.06,length-0.5),
                cf*CFrame.new(side*10,0.30,0),white,false)
        end
        if i%2==1 then
            create("RoadCenterDashes",Vector3.new(0.28,0.06,math.min(9,length-0.5)),
                cf*CFrame.new(0,0.30,0),yellow,false)
        end
    end
end

for i=1,#selected-1 do
    pavedSegment(selected[i],selected[i+1],i==1)
end
print("[Prison65] Existing prison driveway extended and connected to the city; no parking created")
