-- Step 56: Studio-only, non-destructive prison entrance landscaping.
-- Does not change prison logic, roads, gates or saved Studio geometry.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
local prison=W:WaitForChild("CityPrison",20)
local roads=city and city:FindFirstChild("Roads")
if not (prison and roads) then return end
task.wait(6) -- after CityPrisonPlacement55

local previous=W:FindFirstChild("CityPrisonAccess56")
if previous then previous:Destroy() end
local folder=Instance.new("Folder")
folder.Name="CityPrisonAccess56"
folder.Parent=W

local function flatDistance(a,b)
    return (Vector2.new(a.X,a.Z)-Vector2.new(b.X,b.Z)).Magnitude
end
local cf,size=prison:GetBoundingBox()
local center=cf.Position
local candidates={}
-- Four possible entrances; search for a genuine gate before choosing a side.
for _,obj in ipairs(prison:GetDescendants()) do
    if obj:IsA("BasePart") then
        local name=obj.Name:lower()
        if name:find("gate",1,true) or name:find("brama",1,true)
            or name:find("entrance",1,true) then
            table.insert(candidates,obj)
        end
    end
end
local gate=nil
for _,part in ipairs(candidates) do
    if not gate or flatDistance(part.Position,center)>flatDistance(gate.Position,center) then
        gate=part
    end
end
if not gate then
    warn("[Prison56] Gate not identified; leaving entrance untouched")
    folder:Destroy()
    return
end
-- Determine the closest accessible road surface to the gate.
local bestRoad=nil
local bestPoint=nil
local bestDistance=math.huge
for _,part in ipairs(roads:GetDescendants()) do
    if part:IsA("BasePart") and part.Size.X>3 and part.Size.Z>3 then
        local localPoint=part.CFrame:PointToObjectSpace(gate.Position)
        local x=math.clamp(localPoint.X,-part.Size.X/2,part.Size.X/2)
        local z=math.clamp(localPoint.Z,-part.Size.Z/2,part.Size.Z/2)
        local point=part.CFrame:PointToWorldSpace(Vector3.new(x,part.Size.Y/2,z))
        local distance=flatDistance(gate.Position,point)
        if distance<bestDistance then
            bestDistance=distance
            bestRoad=part
            bestPoint=point
        end
    end
end
if not bestRoad or bestDistance>75 then
    warn("[Prison56] No nearby road within 75 studs; not generating a disconnected driveway")
    folder:Destroy()
    return
end
-- Place a short driveway only if it does not cross the prison itself or
-- an unrelated building. Use the closest point on the road as destination.
local direction=Vector3.new(bestPoint.X-gate.Position.X,0,bestPoint.Z-gate.Position.Z)
local length=direction.Magnitude
if length<8 then
    print("[Prison56] Entrance already adjacent to road; no extra pavement needed")
    folder:Destroy()
    return
end
local unit=direction.Unit
local gateStart=Vector3.new(gate.Position.X, bestPoint.Y+0.13,gate.Position.Z)+unit*5
local roadEnd=Vector3.new(bestPoint.X,bestPoint.Y+0.13,bestPoint.Z)
local mid=(gateStart+roadEnd)/2
local span=flatDistance(gateStart,roadEnd)
if span<3 then folder:Destroy();return end
local pavementCF=CFrame.lookAt(mid,roadEnd)
local obstacles={}
for _,container in ipairs({city:FindFirstChild("GameplayLocations"),city:FindFirstChild("Downtown"),city:FindFirstChild("CityLocations")}) do
    if container then
        for _,model in ipairs(container:GetChildren()) do
            if model:IsA("Model") then table.insert(obstacles,model) end
        end
    end
end
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances=obstacles
local test=W:GetPartBoundsInBox(pavementCF,Vector3.new(17,6,span),params)
if #test>0 then
    warn("[Prison56] Access path intersects another building; skipped")
    folder:Destroy()
    return
end
local driveway=Instance.new("Part")
driveway.Name="PrisonDriveway"
driveway.Anchored=true
driveway.CanCollide=true
driveway.Material=Enum.Material.Asphalt
driveway.Color=Color3.fromRGB(63,68,73)
driveway.Size=Vector3.new(16,0.26,span)
driveway.CFrame=pavementCF
driveway.Parent=folder
local function marking(offset)
    local line=Instance.new("Part")
    line.Name="DrivewayEdgeLine"
    line.Anchored=true
    line.CanCollide=false
    line.Material=Enum.Material.SmoothPlastic
    line.Color=Color3.fromRGB(227,222,181)
    line.Size=Vector3.new(0.3,0.05,span-1)
    line.CFrame=pavementCF*CFrame.new(offset,0.17,0)
    line.Parent=folder
end
marking(-7.2);marking(7.2)
print(string.format("[Prison56] Safe entrance driveway: %.1f studs from %s",span,bestRoad.Name))
