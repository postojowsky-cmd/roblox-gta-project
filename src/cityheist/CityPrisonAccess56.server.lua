-- City Heist step 67: ONE parking on the grey apron marked by the user.
-- The existing prison driveway remains; connect its dead end to this parking,
-- then connect the parking's right/city side to the street. Studio preview only.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
local prison=W:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (city and prison and roads) then return end
if W:GetAttribute("PrisonParking67Started") then return end
W:SetAttribute("PrisonParking67Started",true)
local t=0
while not prison:GetAttribute("CityPrison55Moved") and t<18 do task.wait(.25);t+=.25 end
if not prison:GetAttribute("CityPrison55Moved") then warn("[Prison67] Prison not moved");return end
task.wait(.4)
for _,name in ipairs({"CityPrisonGenerated","CityPrisonAccessRoad","CityPrisonAccess56"}) do
    local old=W:FindFirstChild(name)
    if old then old:Destroy() end
end
local generated=Instance.new("Folder")
generated.Name="CityPrisonGenerated";generated.Parent=W
local function make(name,size,cf,color,material,collides)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Anchored=true
    p.CanCollide=collides~=false;p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=generated
    return p
end
local flat=function(v)return Vector3.new(v.X,0,v.Z)end
local l=prison:FindFirstChild("GatePillarL",true)
local r=prison:FindFirstChild("GatePillarR",true)
if not (l and r and l:IsA("BasePart") and r:IsA("BasePart")) then
    warn("[Prison67] Gate pillars unavailable");generated:Destroy();return
end
local gate=(l.Position+r.Position)/2
local across=flat(r.Position-l.Position)
if across.Magnitude<1 then generated:Destroy();return end
across=across.Unit
local outward=Vector3.new(-across.Z,0,across.X)
local roadParts={}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>5 and p.Size.Z>5 then table.insert(roadParts,p) end
end
if #roadParts==0 then generated:Destroy();return end
local function roadPoint(road,pos)
    local q=road.CFrame:PointToObjectSpace(pos)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(q.X,-road.Size.X/2,road.Size.X/2),
        road.Size.Y/2,
        math.clamp(q.Z,-road.Size.Z/2,road.Size.Z/2)))
end
local closestCity=nil
local best=math.huge
for _,road in ipairs(roadParts) do
    local p=roadPoint(road,gate)
    local d=flat(p-gate).Magnitude
    if d<best then closestCity=p;best=d end
end
if closestCity and flat(closestCity-gate):Dot(outward)<0 then outward=-outward end
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances={generated,prison}
local function ground(pos)
    local y=math.max(350,pos.Y+170)
    local hit=W:Raycast(Vector3.new(pos.X,y,pos.Z),Vector3.new(0,-1100,0),rayParams)
    if hit and hit.Normal.Y>.65 then return hit.Position.Y end
    return math.min(l.Position.Y-l.Size.Y/2,r.Position.Y-r.Size.Y/2)
end
-- Look along the original straight driveway, visible down the GREY slab.
local endDistance=70
for _,p in ipairs(prison:GetDescendants()) do
    if p:IsA("BasePart") then
        local n=p.Name:lower()
        if (n:find("road",1,true) or n:find("drive",1,true)) and p.Size.X>3 and p.Size.Z>3 then
            local fwd=flat(p.Position-gate):Dot(outward)
            if fwd>0 and fwd<260 and math.abs(flat(p.Position-gate):Dot(across))<30 then
                endDistance=math.max(endDistance,fwd+math.max(p.Size.X,p.Size.Z)/2)
            end
        end
    end
end
-- Center exactly over the large grey apron below the prison, rather than the
-- small existing parking on the grass at the opposite side of the street.
local width,depth=175,165
local centerXZ=gate+outward*math.max(140,endDistance+40)
local surface=ground(centerXZ)
local y=surface+.34
local center=Vector3.new(centerXZ.X,y,centerXZ.Z)
local cf=CFrame.lookAt(center,center+outward)
local asphalt=Color3.fromRGB(45,49,55)
local white=Color3.fromRGB(239,238,229)
local yellow=Color3.fromRGB(235,198,69)
make("MainGreyApronParking",Vector3.new(width,.65,depth),
    cf,asphalt,Enum.Material.Asphalt)
-- Keep the center longitudinal lane clear, with spaces on left/right.
for _,side in ipairs({-1,1}) do
    for _,z in ipairs({-57,-10,37}) do
        for i=0,5 do
            local x=side*(22+i*12)
            make("ParkingStripe",Vector3.new(.25,.06,21),
                cf*CFrame.new(x,.37,z),white,nil,false)
        end
        make("ParkingEndLine",Vector3.new(65,.06,.25),
            cf*CFrame.new(side*52,.37,z+10),white,nil,false)
    end
end
local function connect(name,a,b,width)
    local diff=b-a
    if flat(diff).Magnitude<1.5 then return end
    local lineCF=CFrame.lookAt((a+b)/2,b)
    local length=diff.Magnitude+3
    make(name,Vector3.new(width,.45,length),lineCF,asphalt,Enum.Material.Asphalt)
    for _,side in ipairs({-1,1}) do
        make("RoadEdge",Vector3.new(.25,.06,length-1),
            lineCF*CFrame.new(side*(width/2-1),.26,0),white,nil,false)
    end
end
local gateRoadEnd=gate+outward*endDistance
local back=cf:PointToWorldSpace(Vector3.new(0,0,depth/2-2))
connect("ExistingDriveToParking",
    Vector3.new(gateRoadEnd.X,y,gateRoadEnd.Z),
    Vector3.new(back.X,y,back.Z),24)
-- Exit straight from the parking side nearest the city street.
local chosenSide=1
local nearest=math.huge
for _,side in ipairs({-1,1}) do
    local edge=cf:PointToWorldSpace(Vector3.new(side*(width/2-3),0,-10))
    for _,road in ipairs(roadParts) do
        local q=roadPoint(road,edge)
        local d=flat(q-edge).Magnitude
        if d<nearest then nearest=d;chosenSide=side end
    end
end
local exit=cf:PointToWorldSpace(Vector3.new(chosenSide*(width/2-3),0,-10))
local destination=nil
local distance=math.huge
for _,road in ipairs(roadParts) do
    local q=roadPoint(road,exit)
    local d=flat(q-exit).Magnitude
    if d<distance then destination=q;distance=d end
end
if destination then
    connect("ParkingExitToCity",
        Vector3.new(exit.X,y,exit.Z),
        Vector3.new(destination.X,y,destination.Z),24)
    print(string.format("[Prison67] Exit to city road: %.0f studs",distance))
end
print("[Prison67] ONE parking generated on GREY apron; no grass parking")
