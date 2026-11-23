-- Step 58: long access road for the relocated prison (Studio preview only).
-- Runs after prison placement, never moves the prison or changes its logic.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Workspace=game:GetService("Workspace")
local city=Workspace:WaitForChild("CityBlockout",20)
local prison=Workspace:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (prison and roads) then return end
task.wait(7)

local old=Workspace:FindFirstChild("CityPrisonAccess56")
if old then old:Destroy() end

local cf,size=prison:GetBoundingBox()
local center=cf.Position
local roadParts={}
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>5 and p.Size.Z>5 then
        table.insert(roadParts,p)
    end
end
if #roadParts==0 then warn("[Prison58] No road parts");return end

local function horizontal(a,b)
    return Vector3.new(b.X-a.X,0,b.Z-a.Z)
end
local function roadPoint(road,point)
    local localPoint=road.CFrame:PointToObjectSpace(point)
    local x=math.clamp(localPoint.X,-road.Size.X/2,road.Size.X/2)
    local z=math.clamp(localPoint.Z,-road.Size.Z/2,road.Size.Z/2)
    return road.CFrame:PointToWorldSpace(Vector3.new(x,road.Size.Y/2,z))
end
-- Locate the actual entry side from named gate parts, without choosing the
-- most distant decorative tower or wall segment.
local gates={}
for _,p in ipairs(prison:GetDescendants()) do
    if p:IsA("BasePart") then
        local n=p.Name:lower()
        if n:find("gate",1,true) or n:find("brama",1,true) or n:find("entrance",1,true) then
            table.insert(gates,p)
        end
    end
end
if #gates==0 then
    warn("[Prison58] Gate not found; access road skipped")
    return
end
local obstacles={}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local folder=city:FindFirstChild(folderName)
    if folder then
        for _,m in ipairs(folder:GetChildren()) do
            if m:IsA("Model") then table.insert(obstacles,m) end
        end
    end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=obstacles
local function clearSegment(a,b)
    local d=horizontal(a,b)
    if d.Magnitude<2 then return true end
    local middle=(a+b)/2
    local checkCF=CFrame.lookAt(middle,Vector3.new(b.X,middle.Y,b.Z))
    return #Workspace:GetPartBoundsInBox(checkCF,Vector3.new(18,8,d.Magnitude),overlap)==0
end

local best=nil
for _,gate in ipairs(gates) do
    local outward=horizontal(center,gate.Position)
    if outward.Magnitude>2 then
        local outwardUnit=outward.Unit
        -- Start just outside the prison walls, so pavement doesn't cross the courtyard.
        local start=Vector3.new(gate.Position.X,center.Y,gate.Position.Z)+outwardUnit*10
        for _,road in ipairs(roadParts) do
            local finish=roadPoint(road,start)
            local d=horizontal(start,finish)
            if d.Magnitude>=3 and d.Magnitude<=320 then
                -- Only connect roads on the outside of the gate, not through prison walls.
                if d.Unit:Dot(outwardUnit)>0.15 and clearSegment(start,finish) then
                    local score=d.Magnitude
                    if not best or score<best.score then
                        best={start=start,finish=finish,road=road,score=score,gate=gate}
                    end
                end
            end
        end
    end
end
if not best then
    warn("[Prison58] No clear outward route to road (up to 320 studs); prison left untouched")
    return
end

local folder=Instance.new("Folder")
folder.Name="CityPrisonAccess56"
folder.Parent=Workspace
local y=best.finish.Y+0.18
local start=Vector3.new(best.start.X,y,best.start.Z)
local finish=Vector3.new(best.finish.X,y,best.finish.Z)
local direction=horizontal(start,finish)
local distance=direction.Magnitude
local midpoint=(start+finish)/2
local pavementCF=CFrame.lookAt(midpoint,finish)
local function makePart(name,sz,partCF,color,material,collide)
    local p=Instance.new("Part")
    p.Name=name
    p.Anchored=true
    p.CanCollide=collide
    p.Material=material
    p.Color=color
    p.Size=sz
    p.CFrame=partCF
    p.Parent=folder
    return p
end
makePart("PrisonAccessRoad",Vector3.new(17,0.35,distance+3),pavementCF,
    Color3.fromRGB(61,65,71),Enum.Material.Asphalt,true)
for _,side in ipairs({-7.9,7.9}) do
    makePart("RoadEdge",Vector3.new(0.3,0.05,distance),pavementCF*CFrame.new(side,0.22,0),
        Color3.fromRGB(231,228,197),Enum.Material.SmoothPlastic,false)
end
for z=-distance/2+12,distance/2-8,22 do
    makePart("CenterMarking",Vector3.new(0.25,0.05,8),pavementCF*CFrame.new(0,0.22,z),
        Color3.fromRGB(235,209,78),Enum.Material.SmoothPlastic,false)
end
print(string.format("[Prison58] Prison road connected: %.0f studs, gate %s, road %s",
    distance,best.gate.Name,best.road.Name))
