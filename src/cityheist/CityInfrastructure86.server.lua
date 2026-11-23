-- CITY HEIST / STEP 86: safe infill parking and fuel station preview.
-- Creates NEW decorative objects only; never edits roads, heists, police or garage scripts.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=game:GetService("Workspace")
if W:GetAttribute("CityInfrastructure86Running") then return end
W:SetAttribute("CityInfrastructure86Running",true)
print("[CityInfra86] START")

local city=W:WaitForChild("CityBlockout",30)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
local main=W:WaitForChild("CityHeistPrefabCity74",90)
local extra=W:WaitForChild("CityHeistInfill81",90)
if not (city and roads and ground and main and extra) then
    warn("[CityInfra86] Missing map / prefab infrastructure, skipped")
    return
end

local elapsed=0
while elapsed<60 and not (main:GetAttribute("PlacementComplete") and extra:GetAttribute("PlacementComplete")) do
    task.wait(.5)
    elapsed+=.5
end
if not (main:GetAttribute("PlacementComplete") and extra:GetAttribute("PlacementComplete")) then
    warn("[CityInfra86] Prefab placement did not complete; skipped to avoid overlap")
    return
end
-- Decoration generator already has a defined finish point when its parent
-- folder exists and was populated; existing decorations are blockers too.
local prior=W:FindFirstChild("CityHeistInfrastructure86")
if prior then prior:Destroy() end
local root=Instance.new("Folder")
root.Name="CityHeistInfrastructure86"
root:SetAttribute("StudioPreview",true)
root.Parent=W

local blockers={roads,main,extra,root}
for _,name in ipairs({"GameplayLocations","CityLocations","Downtown","CityGarages","CityDecorativeHomes"}) do
    local obj=city:FindFirstChild(name)
    if obj then table.insert(blockers,obj) end
end
for _,name in ipairs({"CityHeistStreetscape79","CityPrison","CityHeistGarageSpawned"}) do
    local obj=W:FindFirstChild(name)
    if obj then table.insert(blockers,obj) end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=blockers
local groundRay=RaycastParams.new()
groundRay.FilterType=Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances={ground}
local function groundY(x,z)
    local hit=W:Raycast(Vector3.new(x,420,z),Vector3.new(0,-900,0),groundRay)
    return hit and hit.Normal.Y>.9 and hit.Position.Y or nil
end
local function vacant(x,y,z,w,d)
    local hits=W:GetPartBoundsInBox(CFrame.new(x,y+9,z),Vector3.new(w+12,20,d+12),overlap)
    return #hits==0
end

local allRoads={}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,part in ipairs(roads:GetDescendants()) do
    if part:IsA("BasePart") and part.Size.X>6 and part.Size.Z>6 then
        table.insert(allRoads,part)
        for _,dx in ipairs({-part.Size.X/2,part.Size.X/2}) do
            for _,dz in ipairs({-part.Size.Z/2,part.Size.Z/2}) do
                local v=part.CFrame:PointToWorldSpace(Vector3.new(dx,0,dz))
                minX=math.min(minX,v.X);maxX=math.max(maxX,v.X)
                minZ=math.min(minZ,v.Z);maxZ=math.max(maxZ,v.Z)
            end
        end
    end
end
if #allRoads<4 then warn("[CityInfra86] Invalid road bounds; skipped");root:Destroy();return end

-- Near-street sites: measure horizontal distance to the actual road
-- rectangles rather than assuming a regular grid or building a new road.
local function roadDistance(x,z)
    local nearest=math.huge
    for _,road in ipairs(allRoads) do
        local q=road.CFrame:PointToObjectSpace(Vector3.new(x,road.Position.Y,z))
        local ox=math.max(math.abs(q.X)-road.Size.X/2,0)
        local oz=math.max(math.abs(q.Z)-road.Size.Z/2,0)
        local dist=math.sqrt(ox*ox+oz*oz)
        if dist<nearest then nearest=dist end
    end
    return nearest
end
local palettes={
    asphalt=Color3.fromRGB(53,57,62),
    line=Color3.fromRGB(238,238,230),
    concrete=Color3.fromRGB(169,176,174),
    frame=Color3.fromRGB(65,76,86),
    petrol=Color3.fromRGB(24,124,165),
    petrolLight=Color3.fromRGB(28,178,209),
}
local function part(parent,name,size,cf,color,mat,solid)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf
    p.Color=color;p.Anchored=true;p.CanCollide=solid~=false
    p.Material=mat or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function makeParking(index,x,y,z)
    local m=Instance.new("Model")
    m.Name="PublicParking_"..index;m.Parent=root
    part(m,"ParkingSurface",Vector3.new(60,.28,40),
        CFrame.new(x,y+.12,z),palettes.asphalt,Enum.Material.Asphalt)
    -- Six visible bays, each 9 studs wide, with a maneuvering aisle.
    for slot=0,6 do
        local sx=x-27+slot*9
        part(m,"BayStripe",Vector3.new(.22,.04,17),
            CFrame.new(sx,y+.29,z-9),palettes.line,nil,false)
    end
    part(m,"BayRearStripe",Vector3.new(54,.04,.22),
        CFrame.new(x,y+.29,z-17.5),palettes.line,nil,false)
    for _,sx in ipairs({-25,25}) do
        part(m,"Bollard",Vector3.new(.85,3,.85),
            CFrame.new(x+sx,y+1.5,z+17),
            Color3.fromRGB(238,192,80),Enum.Material.Metal)
    end
    m:SetAttribute("DecorativeOnly",true)
end
local function makeFuelStation(x,y,z)
    local m=Instance.new("Model")
    m.Name="FuelStation";m.Parent=root
    part(m,"Forecourt",Vector3.new(70,.3,54),
        CFrame.new(x,y+.15,z),palettes.concrete,Enum.Material.Concrete)
    -- Clear drive-through forecourt. Pumps and supports stay at the edges.
    for _,dx in ipairs({-21,21}) do
        part(m,"CanopyColumn",Vector3.new(2,15,2),
            CFrame.new(x+dx,y+7.7,z),palettes.frame,Enum.Material.Metal)
    end
    part(m,"FuelCanopy",Vector3.new(57,2,36),
        CFrame.new(x,y+16,z),palettes.petrol,Enum.Material.Metal)
    part(m,"FuelCanopyTrim",Vector3.new(59,.8,37),
        CFrame.new(x,y+17.35,z),palettes.petrolLight,Enum.Material.Neon,false)
    for _,dx in ipairs({-12,12}) do
        for _,dz in ipairs({-7,7}) do
            part(m,"PumpIsland",Vector3.new(4,.5,9),
                CFrame.new(x+dx,y+.55,z+dz),
                palettes.concrete,Enum.Material.Concrete)
            local pump=part(m,"FuelPump",Vector3.new(2.7,5.7,3.1),
                CFrame.new(x+dx,y+3.7,z+dz),
                palettes.petrol,Enum.Material.Metal)
            pump:SetAttribute("VisualOnly",true)
            part(m,"PumpDisplay",Vector3.new(2.1,1.4,.1),
                CFrame.new(x+dx,y+4.6,z+dz-1.6),
                Color3.fromRGB(173,222,231),Enum.Material.Glass,false)
        end
    end
    m:SetAttribute("DecorativeOnly",true)
end

local points={}
for x=minX+51,maxX-51,24 do
    for z=minZ+51,maxZ-51,24 do
        local street=roadDistance(x,z)
        if street>=9 and street<=47 then
            table.insert(points,{x=x,z=z,street=street,
                ring=math.abs(x-(minX+maxX)/2)+math.abs(z-(minZ+maxZ)/2)})
        end
    end
end
table.sort(points,function(a,b)
    if a.street==b.street then return a.ring>b.ring end
    return a.street<b.street
end)

local parking,fuel=0,0
for _,v in ipairs(points) do
    if parking>=2 and fuel>=1 then break end
    local y=groundY(v.x,v.z)
    if y then
        local kind
        local w,d
        if parking<2 then kind="parking";w=60;d=40
        else kind="fuel";w=70;d=54 end
        local flat=true
        for _,dx in ipairs({-w/2-3,w/2+3}) do
            for _,dz in ipairs({-d/2-3,d/2+3}) do
                local yy=groundY(v.x+dx,v.z+dz)
                if not yy or math.abs(yy-y)>1.3 then flat=false end
            end
        end
        if flat and vacant(v.x,y,v.z,w,d) then
            if kind=="parking" then
                parking+=1;makeParking(parking,v.x,y,v.z)
                print(string.format("[CityInfra86] PARKING %d X %.0f Z %.0f",
                    parking,v.x,v.z))
            else
                fuel+=1;makeFuelStation(v.x,y,v.z)
                print(string.format("[CityInfra86] FUEL STATION X %.0f Z %.0f",
                    v.x,v.z))
            end
        end
    end
end
print(string.format("[CityInfra86] DONE: %d parking lots, %d fuel stations; existing 28 prefab buildings and road grid unchanged",
    parking,fuel))
