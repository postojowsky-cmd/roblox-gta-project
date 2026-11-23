-- Step 59: spacious prison visitor parking, replacing the long road.
-- Studio-only preview. Never touches prison logic or permanent Studio objects.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
local prison=W:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (prison and roads) then return end
task.wait(7)

local old=W:FindFirstChild("CityPrisonAccess56")
if old then old:Destroy() end

local bounds,size=prison:GetBoundingBox()
local prisonCenter=bounds.Position
local pillars={}
for _,obj in ipairs(prison:GetDescendants()) do
    if obj:IsA("BasePart") then
        local n=obj.Name:lower()
        if n:find("gatepillar",1,true) or n:find("gate_pillar",1,true) then
            table.insert(pillars,obj)
        end
    end
end
if #pillars<2 then
    warn("[Prison59] Gate pillars missing; parking skipped to avoid wrong placement")
    return
end
-- Prefer matching L/R pillars rather than unrelated decorative parts.
local left,right
for _,p in ipairs(pillars) do
    local n=p.Name:lower()
    if n:find("gatepillarl",1,true) then left=p end
    if n:find("gatepillarr",1,true) then right=p end
end
if not left or not right then
    table.sort(pillars,function(a,b)
        return (a.Position-prisonCenter).Magnitude>(b.Position-prisonCenter).Magnitude
    end)
    left,right=pillars[1],pillars[2]
end
local gate=(left.Position+right.Position)/2
local outward=Vector3.new(gate.X-prisonCenter.X,0,gate.Z-prisonCenter.Z)
if outward.Magnitude<2 then warn("[Prison59] Gate direction ambiguous");return end
outward=outward.Unit
local parkingCenter=gate+outward*48
local parkingWidth=100
local parkingDepth=76

local bestRoad,bestPoint,bestDist
bestDist=math.huge
for _,road in ipairs(roads:GetDescendants()) do
    if road:IsA("BasePart") and road.Size.X>5 and road.Size.Z>5 then
        local p=road.CFrame:PointToObjectSpace(parkingCenter)
        local x=math.clamp(p.X,-road.Size.X/2,road.Size.X/2)
        local z=math.clamp(p.Z,-road.Size.Z/2,road.Size.Z/2)
        local point=road.CFrame:PointToWorldSpace(Vector3.new(x,road.Size.Y/2,z))
        local distance=(Vector3.new(point.X,0,point.Z)-Vector3.new(parkingCenter.X,0,parkingCenter.Z)).Magnitude
        if distance<bestDist then
            bestDist=distance;bestRoad=road;bestPoint=point
        end
    end
end
local surfaceY=bestPoint and bestPoint.Y+0.12 or gate.Y-3
local center=Vector3.new(parkingCenter.X,surfaceY,parkingCenter.Z)
-- Local +Z faces the prison's opposite direction, leaving the entry open.
local facing=CFrame.lookAt(center,Vector3.new(gate.X,surfaceY,gate.Z))
local obstacles={}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local folder=city:FindFirstChild(folderName)
    if folder then
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") then table.insert(obstacles,obj) end
        end
    end
end
if #obstacles>0 then
    local overlap=OverlapParams.new()
    overlap.FilterType=Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances=obstacles
    if #W:GetPartBoundsInBox(facing,Vector3.new(parkingWidth,8,parkingDepth),overlap)>0 then
        warn("[Prison59] Parking conflicts with a city building; skipped")
        return
    end
end
local folder=Instance.new("Folder")
folder.Name="CityPrisonAccess56"
folder.Parent=W
local function part(name,sz,cf,color,material,collide)
    local p=Instance.new("Part")
    p.Name=name
    p.Anchored=true
    p.CanCollide=collide
    p.Material=material or Enum.Material.SmoothPlastic
    p.Color=color
    p.Size=sz
    p.CFrame=cf
    p.Parent=folder
    return p
end
local asphalt=Color3.fromRGB(58,62,69)
local white=Color3.fromRGB(230,231,225)
part("PrisonVisitorParking",Vector3.new(parkingWidth,0.32,parkingDepth),facing,asphalt,Enum.Material.Asphalt,true)
-- Two rows of 8 spaces; a wide central maneuvering aisle remains free.
for _,z in ipairs({-23,23}) do
    for i=0,8 do
        local x=-44+i*11
        part("ParkingBayDivider",Vector3.new(0.23,0.04,19),
            facing*CFrame.new(x,0.20,z),white,nil,false)
    end
    part("ParkingBayBackLine",Vector3.new(88,0.04,0.23),
        facing*CFrame.new(0,0.20,z+(z<0 and -9.5 or 9.5)),white,nil,false)
end
-- Broad, short apron between prison entrance and parking; no 218-stud strip.
local entryPoint=Vector3.new(gate.X,surfaceY,gate.Z)
local nearEdge=facing:PointToWorldSpace(Vector3.new(0,0,-parkingDepth/2+2))
local delta=Vector3.new(nearEdge.X-entryPoint.X,0,nearEdge.Z-entryPoint.Z)
if delta.Magnitude>3 and delta.Magnitude<45 then
    local middle=(entryPoint+nearEdge)/2
    local linkCF=CFrame.lookAt(middle,nearEdge)
    part("GateApron",Vector3.new(23,0.32,delta.Magnitude+3),
        linkCF,asphalt,Enum.Material.Asphalt,true)
end
-- Entrance-side bollards and soft lights, kept away from the drive aisle.
for _,x in ipairs({-45,45}) do
    local base=facing:PointToWorldSpace(Vector3.new(x,0,-34))
    local post=part("ParkingLightPost",Vector3.new(0.7,12,0.7),
        CFrame.new(base+Vector3.new(0,6,0)),Color3.fromRGB(65,70,77),Enum.Material.Metal,true)
    local lamp=part("ParkingLamp",Vector3.new(2.8,0.5,2.8),
        CFrame.new(base+Vector3.new(0,12.3,0)),Color3.fromRGB(245,239,196),Enum.Material.Neon,false)
    local light=Instance.new("PointLight")
    light.Range=38;light.Brightness=2;light.Parent=lamp
end
print(string.format("[Prison59] Parking 100x76 placed at prison gate; nearest road %.0f studs away",bestDist))
