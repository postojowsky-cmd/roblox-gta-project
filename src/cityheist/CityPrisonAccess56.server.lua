-- CITY HEIST / Step 68. One clearly visible parking on the existing GREY
-- prison forecourt. The walls and the existing prison driveway remain intact.
-- Studio Play preview; no random city-wide parking-site selection.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
local prison=W:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (city and prison and roads) then return end
if W:GetAttribute("PrisonParking68Started") then return end
W:SetAttribute("PrisonParking68Started",true)

local elapsed=0
while not prison:GetAttribute("CityPrison55Moved") and elapsed<18 do
    task.wait(0.25);elapsed+=0.25
end
if not prison:GetAttribute("CityPrison55Moved") then
    warn("[Prison68] Prison not relocated; nothing changed")
    return
end
task.wait(0.5)
for _,name in ipairs({"CityPrisonGenerated","CityPrisonAccess56","CityPrisonAccessRoad"}) do
    local old=W:FindFirstChild(name)
    if old then old:Destroy() end
end
local folder=Instance.new("Folder")
folder.Name="CityPrisonGenerated"
folder.Parent=W
local function part(name,size,cf,color,material,canCollide)
    local p=Instance.new("Part")
    p.Name=name;p.Anchored=true;p.CanCollide=canCollide~=false
    p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=folder
    return p
end
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local left=prison:FindFirstChild("GatePillarL",true)
local right=prison:FindFirstChild("GatePillarR",true)
if not (left and right and left:IsA("BasePart") and right:IsA("BasePart")) then
    warn("[Prison68] Actual gate pillars missing")
    folder:Destroy();return
end
local gate=(left.Position+right.Position)/2
local across=flat(right.Position-left.Position)
if across.Magnitude<2 then folder:Destroy();return end
across=across.Unit
local normal=Vector3.new(-across.Z,0,across.X)

-- Find the grey paved parcel, instead of estimating elevation from pillar
-- bottoms. Include CityPrison in the raycast so its ground base can be detected.
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances={folder}
local function surfaceAt(point)
    local ray=W:Raycast(Vector3.new(point.X,math.max(400,gate.Y+180),point.Z),
        Vector3.new(0,-1100,0),rayParams)
    if not ray or ray.Normal.Y<0.92 then return nil end
    return ray
end
local function greySurface(hit)
    local p=hit.Instance
    if not p or not p:IsA("BasePart") then return false end
    local c=p.Color
    local grey=math.abs(c.R-c.G)<0.16 and math.abs(c.G-c.B)<0.16
    return grey and p.Material~=Enum.Material.Grass and
        (p.Size.X>80 and p.Size.Z>80)
end

-- Identify the existing dead-end road on the apron. This establishes which
-- side of the gate is OUTSIDE, even if the closest city street is lateral.
local bestDirection=nil
local bestRoadDistance=-1
for _,p in ipairs(prison:GetDescendants()) do
    if p:IsA("BasePart") then
        local n=p.Name:lower()
        if (n:find("road",1,true) or n:find("drive",1,true)
            or n:find("access",1,true)) and p.Size.X>3 and p.Size.Z>3 then
            local v=flat(p.Position-gate)
            if v.Magnitude>15 and v.Magnitude<420 then
                local projection=math.abs(v:Dot(normal))
                if projection>bestRoadDistance then
                    bestRoadDistance=projection
                    bestDirection=v:Dot(normal)>=0 and normal or -normal
                end
            end
        end
    end
end
-- Compare bare exterior surfaces along both normals if no road marker exists.
local function scoreDirection(dir)
    local score=0
    for _,d in ipairs({55,95,130,165,205}) do
        local hit=surfaceAt(gate+dir*d)
        if hit and greySurface(hit) then score+=1 end
    end
    return score
end
local outward=bestDirection
if not outward then
    outward=scoreDirection(normal)>=scoreDirection(-normal) and normal or -normal
end

-- The red sketch covers the broad grey rectangle immediately OUTSIDE the
-- prison, with the existing narrow entry road running down its middle.
local width,depth=170,145
local selected=nil
for _,distance in ipairs({125,150,175,200,225,250}) do
    local center=gate+outward*distance
    local hit=surfaceAt(center)
    if hit and greySurface(hit) then
        local cf=CFrame.lookAt(Vector3.new(center.X,hit.Position.Y+0.43,center.Z),
            Vector3.new(center.X,hit.Position.Y+0.43,center.Z)+outward)
        local sameSurface=true
        for _,x in ipairs({-width/2+5,width/2-5}) do
            for _,z in ipairs({-depth/2+5,depth/2-5}) do
                local point=cf:PointToWorldSpace(Vector3.new(x,0,z))
                local at=surfaceAt(point)
                if not at or not greySurface(at)
                    or math.abs(at.Position.Y-hit.Position.Y)>2 then
                    sameSurface=false
                end
            end
        end
        -- Prevent overlay on the enclosed prison campus.
        local prisonBounds=prison:GetBoundingBox()
        if sameSurface and flat(cf.Position-prisonBounds.Position).Magnitude>30 then
            selected={cf=cf,top=hit.Position.Y+.8,distance=distance}
            break
        end
    end
end
if not selected then
    warn("[Prison68] Grey forecourt could not be validated. No misplaced parking created.")
    folder:Destroy();return
end
local cf=selected.cf
local asphalt=Color3.fromRGB(37,42,49)
local white=Color3.fromRGB(243,243,230)
local yellow=Color3.fromRGB(234,198,66)
part("Parking_ON_GREY_PRISON_APRON",Vector3.new(width,0.8,depth),
    cf,asphalt,Enum.Material.Asphalt,true)

-- Rows perpendicular to the old prison entry road; central maneuvering aisle.
for _,side in ipairs({-1,1}) do
    for _,z in ipairs({-51,-4,43}) do
        for i=0,5 do
            local x=side*(20+i*11)
            part("ParkingSpaceDivider",Vector3.new(0.28,0.06,20),
                cf*CFrame.new(x,0.44,z),white,nil,false)
        end
        part("ParkingBayEnd",Vector3.new(64,0.06,0.25),
            cf*CFrame.new(side*51,0.44,z+10),white,nil,false)
    end
end
for z=-45,46,21 do
    part("CenterLaneDashes",Vector3.new(0.3,0.07,9),
        cf*CFrame.new(0,0.45,z),yellow,nil,false)
end

-- Driveway already exists; don't draw a second road over it. Place a
-- connection only along the city's direction from the RIGHT edge of the lot.
local roadParts={}
for _,obj in ipairs(roads:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Size.X>6 and obj.Size.Z>6 then
        table.insert(roadParts,obj)
    end
end
local function roadPoint(road,point)
    local p=road.CFrame:PointToObjectSpace(point)
    return road.CFrame:PointToWorldSpace(Vector3.new(
        math.clamp(p.X,-road.Size.X/2,road.Size.X/2),
        road.Size.Y/2,
        math.clamp(p.Z,-road.Size.Z/2,road.Size.Z/2)))
end
local side,exit,finish
local distance=math.huge
for _,s in ipairs({-1,1}) do
    local edge=cf:PointToWorldSpace(Vector3.new(s*(width/2-2),0,-10))
    for _,road in ipairs(roadParts) do
        local target=roadPoint(road,edge)
        local d=flat(target-edge).Magnitude
        if d<distance then side=s;exit=edge;finish=target;distance=d end
    end
end
if exit and finish then
    local a=Vector3.new(exit.X,selected.top,exit.Z)
    local b=Vector3.new(finish.X,selected.top,finish.Z)
    local delta=flat(b-a)
    if delta.Magnitude>2 and delta.Magnitude<260 then
        local roadCF=CFrame.lookAt((a+b)/2,b)
        part("ParkingExit_To_CityStreet",Vector3.new(24,0.5,delta.Magnitude+3),
            roadCF,asphalt,Enum.Material.Asphalt,true)
        for _,s in ipairs({-1,1}) do
            part("ExitEdgeLine",Vector3.new(0.25,0.06,delta.Magnitude+2),
                roadCF*CFrame.new(s*11,0.3,0),white,nil,false)
        end
    end
end
print(string.format("[Prison68] Parking visible on grey apron: %dx%d, %d studs from gate",
    width,depth,selected.distance))
