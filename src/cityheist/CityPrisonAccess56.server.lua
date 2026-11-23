-- City Heist / Step 66: visible prison access connection to the city grid.
-- No parking, no walls or buildings are modified. Studio Play preview only.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
local prison=W:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (city and prison and roads) then warn("[Prison66] Missing required model");return end
if W:GetAttribute("CityPrisonRoad66Started") then return end
W:SetAttribute("CityPrisonRoad66Started",true)

local waited=0
while not prison:GetAttribute("CityPrison55Moved") and waited<16 do
    task.wait(0.25);waited+=0.25
end
if not prison:GetAttribute("CityPrison55Moved") then
    warn("[Prison66] Prison placement not confirmed; no road generated")
    return
end
task.wait(0.25)

for _,name in ipairs({"CityPrisonAccessRoad","CityPrisonGenerated","CityPrisonAccess56"}) do
    local old=W:FindFirstChild(name)
    if old then old:Destroy() end
end

local left=prison:FindFirstChild("GatePillarL",true)
local right=prison:FindFirstChild("GatePillarR",true)
if not (left and right and left:IsA("BasePart") and right:IsA("BasePart")) then
    warn("[Prison66] Missing gate pillars")
    return
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local gate=(left.Position+right.Position)/2
local axis=flat(right.Position-left.Position)
if axis.Magnitude<1 then return end
axis=axis.Unit
local outward=Vector3.new(-axis.Z,0,axis.X)

local roadParts={}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>5 and p.Size.Z>5 then table.insert(roadParts,p) end
end
if #roadParts==0 then warn("[Prison66] Roads folder contains no road parts");return end
local function roadPoint(p,world)
    local q=p.CFrame:PointToObjectSpace(world)
    return p.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(q.X,-p.Size.X/2,p.Size.X/2),
        p.Size.Y/2,
        math.clamp(q.Z,-p.Size.Z/2,p.Size.Z/2)
    ))
end
local cityPoint=nil
local cityDist=math.huge
for _,road in ipairs(roadParts) do
    local q=roadPoint(road,gate)
    local d=flat(q-gate).Magnitude
    if d<cityDist then cityDist=d;cityPoint=q end
end
if not cityPoint then return end
if outward:Dot(flat(cityPoint-gate))<0 then outward=-outward end

-- Preserve existing prison driveway and begin at its visible end.
local nearestEnd=gate+outward*25
local bestForward=25
local bestSource="gate offset"
for _,p in ipairs(prison:GetDescendants()) do
    if p:IsA("BasePart") then
        local n=p.Name:lower()
        if (n:find("road",1,true) or n:find("drive",1,true)
            or n:find("access",1,true)) and p.Size.X>3 and p.Size.Z>3 then
            local forward=flat(p.Position-gate):Dot(outward)
            local side=math.abs(flat(p.Position-gate):Dot(axis))
            if forward>=0 and forward<350 and side<35 then
                for _,corner in ipairs({
                    Vector3.new(-p.Size.X/2,0,-p.Size.Z/2),
                    Vector3.new(-p.Size.X/2,0,p.Size.Z/2),
                    Vector3.new(p.Size.X/2,0,-p.Size.Z/2),
                    Vector3.new(p.Size.X/2,0,p.Size.Z/2)
                }) do
                    local point=p.CFrame:PointToWorldSpace(corner)
                    local distance=flat(point-gate):Dot(outward)
                    local lateral=math.abs(flat(point-gate):Dot(axis))
                    if distance>bestForward and distance<450 and lateral<40 then
                        bestForward=distance
                        nearestEnd=point
                        bestSource=p.Name
                    end
                end
            end
        end
    end
end
local startXZ=gate+outward*(bestForward-2)

-- Choose the actual closest segment of city street near the prison's
-- driveway, not a generic location 200+ studs away.
local candidates={}
for _,p in ipairs(roadParts) do
    local q=roadPoint(p,startXZ)
    local v=flat(q-startXZ)
    local forward=v:Dot(outward)
    local across=v:Dot(axis)
    local distance=v.Magnitude
    if distance>=3 and distance<900 then
        -- Prefer a perpendicular city connection (the rightward leg in the sketch).
        local score=distance + math.abs(forward)*0.45
        table.insert(candidates,{point=q,road=p,forward=forward,across=across,score=score})
    end
end
table.sort(candidates,function(a,b)return a.score<b.score end)
if #candidates==0 then warn("[Prison66] No suitable road segment found");return end

local objects={}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local f=city:FindFirstChild(folderName)
    if f then
        for _,m in ipairs(f:GetChildren()) do if m:IsA("Model") then table.insert(objects,m) end end
    end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=objects
local function clear(a,b)
    local delta=flat(b-a)
    if delta.Magnitude<6 then return true end
    local cf=CFrame.lookAt((a+b)/2+Vector3.new(0,3,0), (a+b)/2+Vector3.new(0,3,0)+delta)
    for _,p in ipairs(W:GetPartBoundsInBox(cf,Vector3.new(25,8,math.max(1,delta.Magnitude-12)),overlap)) do
        if p.CanCollide and p.Size.Y>5 then return false end
    end
    return true
end

local selected=nil
for _,candidate in ipairs(candidates) do
    local target=candidate.point
    -- First travel away from the gate, then turn perpendicularly toward city.
    local far=math.max(bestForward+25,flat(target-gate):Dot(outward))
    local corner=gate+outward*far
    if clear(startXZ,corner) and clear(corner,target) then
        selected={startXZ,corner,target}
        print("[Prison66] City road:",candidate.road.Name,"prison source:",bestSource)
        break
    end
end
-- If tight routing fails, still connect the closest unobstructed city road.
if not selected then
    for _,candidate in ipairs(candidates) do
        if clear(startXZ,candidate.point) then
            selected={startXZ,candidate.point}
            print("[Prison66] Direct connection to",candidate.road.Name)
            break
        end
    end
end
if not selected then
    warn("[Prison66] All city routes intersect buildings; no road built")
    return
end

local folder=Instance.new("Folder")
folder.Name="CityPrisonAccessRoad"
folder.Parent=W
local asphalt=Color3.fromRGB(47,51,57)
local line=Color3.fromRGB(236,205,70)
local function part(name,sz,cf,color,collide)
    local p=Instance.new("Part")
    p.Name=name;p.Anchored=true;p.CanCollide=collide~=false
    p.Size=sz;p.CFrame=cf;p.Color=color;p.Material=Enum.Material.Asphalt
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=folder
    return p
end
local groundParams=RaycastParams.new()
groundParams.FilterType=Enum.RaycastFilterType.Exclude
groundParams.FilterDescendantsInstances={prison,folder}
local defaultY=math.min(left.Position.Y-left.Size.Y/2,right.Position.Y-right.Size.Y/2)
local function surfaceHeight(p)
    local originY=math.max(250,p.Y+140)
    local hit=W:Raycast(Vector3.new(p.X,originY,p.Z),Vector3.new(0,-800,0),groundParams)
    if hit and hit.Normal.Y>0.6 then return hit.Position.Y end
    return defaultY
end
local function buildRoad(a,b)
    local delta=flat(b-a)
    if delta.Magnitude<1 then return end
    local pieces=math.max(1,math.ceil(delta.Magnitude/30))
    for i=0,pieces-1 do
        local va=a:Lerp(b,i/pieces)
        local vb=a:Lerp(b,(i+1)/pieces)
        local ya=surfaceHeight(va)
        local yb=surfaceHeight(vb)
        -- The road top should sit slightly above the real visible surface.
        local aa=Vector3.new(va.X,ya+0.24,va.Z)
        local bb=Vector3.new(vb.X,yb+0.24,vb.Z)
        local cf=CFrame.lookAt((aa+bb)/2,bb)
        local length=(bb-aa).Magnitude+2
        part("PrisonRoadExtension",Vector3.new(24,0.45,length),cf,asphalt,true)
        local mark=part("YellowCenterMarking",Vector3.new(0.32,0.055,math.min(9,length-0.8)),
            cf*CFrame.new(0,0.29,0),line,false)
    end
end
for i=1,#selected-1 do
    if flat(selected[i+1]-selected[i]).Magnitude>3 then
        buildRoad(selected[i],selected[i+1])
    end
end
print(string.format("[Prison66] Visible road created: %d section(s), from distance %.0f studs outside gate",
    #selected-1,bestForward))
