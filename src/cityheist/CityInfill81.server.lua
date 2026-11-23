-- CITY HEIST / STEP 81: small-scale infill district (Studio preview).
-- Reuses imported Creator Store prefab models, not arbitrary new towers.
-- Keeps the proven 20 buildings and ALL roads / gameplay models unchanged.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=game:GetService("Workspace")
local SS=game:GetService("ServerStorage")
if W:GetAttribute("CityInfill81Running") then return end
W:SetAttribute("CityInfill81Running",true)

local city=W:WaitForChild("CityBlockout",30)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
local existing=W:WaitForChild("CityHeistPrefabCity74",105)
local stage=SS:WaitForChild("CityHeistAssetStaging",45)
local kit=stage and stage:WaitForChild("ModernCityModularKit",90)
local source=kit and kit:FindFirstChild("PrefabBuildings",true)
if not (roads and ground and existing and source) then
    warn("[CityInfill81] Map or imported kit unavailable; no changes made")
    return
end
local waited=0
while not existing:GetAttribute("PlacementComplete") and waited<40 do
    task.wait(.5);waited+=.5
end
if not existing:GetAttribute("PlacementComplete") then
    warn("[CityInfill81] Main buildings not complete; skipping infill")
    return
end

local candidates={}
for _,m in ipairs(source:GetDescendants()) do
    if m:IsA("Model") then
        local count=0
        local nested=0
        for _,obj in ipairs(m:GetDescendants()) do
            if obj:IsA("BasePart") then count+=1
            elseif obj:IsA("Model") then nested+=1 end
        end
        if count>=12 and count<=650 and nested<=6 then
            local ok,box,size=pcall(function()return m:GetBoundingBox()end)
            if ok and size and size.X>=12 and size.Z>=12
                and size.X<=85 and size.Z<=85
                and size.Y>=10 and size.Y<=100 then
                table.insert(candidates,{model=m,size=size,height=size.Y,count=count})
            end
        end
    end
end
-- The accessible kit might contain no full low-rise prefabs. In that case
-- skip rather than misusing a wall fragment as an entire building.
table.sort(candidates,function(a,b)
    if a.height==b.height then return a.model.Name<b.model.Name end
    return a.height<b.height
end)
if #candidates==0 then
    warn("[CityInfill81] No small COMPLETE prefab models available in current kit; no buildings added")
    return
end

local old=W:FindFirstChild("CityHeistInfill81")
if old then old:Destroy() end
local result=Instance.new("Folder")
result.Name="CityHeistInfill81"
result:SetAttribute("StudioPreview",true)
result.Parent=W

local roadParts={}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>6 and p.Size.Z>6 then
        table.insert(roadParts,p)
        for _,x in ipairs({-p.Size.X/2,p.Size.X/2}) do
            for _,z in ipairs({-p.Size.Z/2,p.Size.Z/2}) do
                local corner=p.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
                minX=math.min(minX,corner.X);maxX=math.max(maxX,corner.X)
                minZ=math.min(minZ,corner.Z);maxZ=math.max(maxZ,corner.Z)
            end
        end
    end
end
if #roadParts<4 then result:Destroy();return end
local blocked={roads,existing,result}
for _,key in ipairs({"GameplayLocations","CityLocations","Downtown","CityGarages","CityDecorativeHomes"}) do
    local folder=city:FindFirstChild(key)
    if folder then table.insert(blocked,folder) end
end
for _,key in ipairs({"CityHeistStreetscape79","CityPrison","CityHeistGarageSpawned"}) do
    local folder=W:FindFirstChild(key)
    if folder then table.insert(blocked,folder) end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=blocked
local rayParams=RaycastParams.new()
rayParams.FilterType=Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances={ground}
local function surface(x,z)
    local hit=W:Raycast(Vector3.new(x,450,z),Vector3.new(0,-1000,0),rayParams)
    return hit and hit.Normal.Y>.88 and hit.Position.Y or nil
end
local function empty(x,y,z,size)
    local hits=W:GetPartBoundsInBox(CFrame.new(x,y+math.min(15,size.Y/2),z),
        Vector3.new(size.X+17,30,size.Z+17),overlap)
    return #hits==0
end
local cx,cz=(minX+maxX)/2,(minZ+maxZ)/2
local points={}
for x=minX+43,maxX-43,25 do
    for z=minZ+43,maxZ-43,25 do
        -- Prefer low-density blocks toward the city's outer ring,
        -- still INSIDE the existing street grid.
        local dist=math.max(math.abs(x-cx)/(maxX-minX),
            math.abs(z-cz)/(maxZ-minZ))
        table.insert(points,{x=x,z=z,score=-dist})
    end
end
table.sort(points,function(a,b)
    if a.score==b.score then
        if a.x==b.x then return a.z<b.z end
        return a.x<b.x
    end
    return a.score<b.score
end)

local count=0
local MAX=8
local attempts=math.min(#candidates,18)
for _,pt in ipairs(points) do
    if count>=MAX then break end
    local y=surface(pt.x,pt.z)
    if y then
        for j=1,attempts do
            local entry=candidates[(count+j-1)%attempts+1]
            local sz=entry.size
            local flat=true
            for _,dx in ipairs({-sz.X/2-3,sz.X/2+3}) do
                for _,dz in ipairs({-sz.Z/2-3,sz.Z/2+3}) do
                    local yy=surface(pt.x+dx,pt.z+dz)
                    if not yy or math.abs(yy-y)>1.5 then flat=false end
                end
            end
            if flat and empty(pt.x,y,pt.z,sz) then
                local model=entry.model:Clone()
                for _,desc in ipairs(model:GetDescendants()) do
                    if desc:IsA("LuaSourceContainer") then desc:Destroy()
                    elseif desc:IsA("BasePart") then desc.Anchored=true end
                end
                model.Name=string.format("Infill_%02d_%s",count+1,entry.model.Name)
                model.Parent=result
                local pivot=model:GetPivot()
                local _,heading,_=pivot:ToOrientation()
                model:PivotTo(CFrame.new(pt.x,y,pt.z)*CFrame.Angles(0,heading,0))
                local box,actual=model:GetBoundingBox()
                local bottom=box.Position.Y-actual.Y/2
                model:PivotTo(model:GetPivot()+Vector3.new(0,y-bottom+.1,0))
                count+=1
                print(string.format("[CityInfill81] PLACED %02d %s | %.0fx%.0fx%.0f | X %.0f Z %.0f",
                    count,entry.model.Name,sz.X,sz.Y,sz.Z,pt.x,pt.z))
                break
            end
        end
    end
end
result:SetAttribute("PlacementComplete",true)
result:SetAttribute("BuildingCount",count)
print(string.format(
    "[CityInfill81] DONE: %d extra lower-rise prefab buildings, %d eligible prefabs; original 20 and city roads unchanged",
    count,#candidates))
