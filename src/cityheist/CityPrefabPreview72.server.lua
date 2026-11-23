-- CITY HEIST / Step 74: move real prefab buildings ONTO EXISTING CITY PLOTS.
-- No duplicate road system and no distant floating test district.
-- Does not touch existing skyscrapers, gameplay buildings or road geometry.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local SS=game:GetService("ServerStorage")
if W:GetAttribute("CityPrefab79Running") then return end
W:SetAttribute("CityPrefab77Running",true)

local city=W:WaitForChild("CityBlockout",30)
local stage=SS:WaitForChild("CityHeistAssetStaging",45)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
if not (stage and roads and ground) then
    warn(string.format("[CityPrefab75] Missing map dependency: stage=%s roads=%s ground=%s",
        tostring(stage~=nil),tostring(roads~=nil),tostring(ground~=nil)))
    return
end
-- The importer creates the staging folder BEFORE LoadAssetAsync finishes.
-- Wait for the actual populated kit, not just the empty staging folder.
local kit=stage:WaitForChild("ModernCityModularKit",90)
if not kit then
    warn("[CityPrefab75] Import did not finish. status="..
        tostring(stage:GetAttribute("ImportStatus")))
    return
end
local prefabs=kit:FindFirstChild("PrefabBuildings",true)
if not prefabs then
    warn("[CityPrefab75] Imported kit has no PrefabBuildings folder")
    return
end
print("[CityPrefab75] Imported prefabs ready; building on existing city grid")
-- Layout scripts create the map during server startup.
task.wait(8)

for _,name in ipairs({"CityHeistPrefabPreview72","CityHeistPrefabCity74"}) do
    local prior=W:FindFirstChild(name)
    if prior then prior:Destroy() end
end
local target=Instance.new("Folder")
target.Name="CityHeistPrefabCity74"
target:SetAttribute("TestPlacement",true)
target.Parent=W

local MAX_BUILDINGS=20
local MAX_PARTS_PER_BUILDING=800
local candidates={}
local function register(m)
    if not m:IsA("Model") then return end
    local count=0
    for _,v in ipairs(m:GetDescendants()) do
        if v:IsA("BasePart") then count+=1 end
        if count>MAX_PARTS_PER_BUILDING then return end
    end
    if count<8 then return end
    local ok,cf,size=pcall(function()return m:GetBoundingBox()end)
    if not ok or not size then return end
    if size.X<9 or size.Z<9 or size.Y<8 or
       size.X>105 or size.Z>105 or size.Y>150 then return end
    table.insert(candidates,{model=m,count=count,size=size})
end
-- Include nested prefab Models, not only the root-level group "Model"/"A".
-- Prefer individual building models; avoid nesting one prefab inside another.
for _,obj in ipairs(prefabs:GetDescendants()) do
    if obj:IsA("Model") then
        local nestedModels=0
        for _,child in ipairs(obj:GetDescendants()) do
            if child:IsA("Model") then nestedModels+=1 end
            if nestedModels>6 then break end
        end
        if nestedModels<=6 then register(obj) end
    end
end
-- Fallback to grouped models only when the asset does not expose units.
if #candidates==0 then
    for _,obj in ipairs(prefabs:GetChildren()) do register(obj) end
end
table.sort(candidates,function(a,b)
    if a.count==b.count then return a.model.Name<b.model.Name end
    return a.count>b.count
end)
if #candidates==0 then warn("[CityPrefab75] No usable prefab models");return end

local roadParts={}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>6 and p.Size.Z>6 then
        table.insert(roadParts,p)
        for _,x in ipairs({-p.Size.X/2,p.Size.X/2}) do
            for _,z in ipairs({-p.Size.Z/2,p.Size.Z/2}) do
                local pt=p.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
                minX=math.min(minX,pt.X);maxX=math.max(maxX,pt.X)
                minZ=math.min(minZ,pt.Z);maxZ=math.max(maxZ,pt.Z)
            end
        end
    end
end
if #roadParts<4 then warn("[CityPrefab74] Road grid not detected");return end

local occupied={}
for _,folderName in ipairs({"GameplayLocations","CityLocations","Downtown","CityGarages"}) do
    local f=city:FindFirstChild(folderName)
    if f then table.insert(occupied,f) end
end
for _,name in ipairs({"CityPrison","CityHeistGarageSpawned","CityDecorativeHomes"}) do
    local instance=W:FindFirstChild(name) or city:FindFirstChild(name)
    if instance then table.insert(occupied,instance) end
end
-- Do not construct over existing city roads or important gameplay objects.
table.insert(occupied,roads)
local overlaps=OverlapParams.new()
overlaps.FilterType=Enum.RaycastFilterType.Include
overlaps.FilterDescendantsInstances=occupied
overlaps.MaxParts=1
local groundRay=RaycastParams.new()
groundRay.FilterType=Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances={ground}

local function surface(x,z)
    local ray=W:Raycast(Vector3.new(x,350,z),Vector3.new(0,-800,0),groundRay)
    if ray and ray.Normal.Y>.88 then return ray.Position.Y end
    return nil
end
local function free(x,y,z,w,d)
    local origin=CFrame.new(x,y+12,z)
    local found=W:GetPartBoundsInBox(origin,Vector3.new(w+14,26,d+14),overlaps)
    if #found>0 then return false end
    for _,item in ipairs(target:GetChildren()) do
        if item:IsA("Model") then
            local bounds,size=item:GetBoundingBox()
            if math.abs(bounds.Position.X-x)<(size.X+w)/2+12
               and math.abs(bounds.Position.Z-z)<(size.Z+d)/2+12 then
                return false
            end
        end
    end
    return true
end
local plots={}
local centerX=(minX+maxX)/2
local centerZ=(minZ+maxZ)/2
-- Search only the city's own road-grid extent. A broad grid gives genuine
-- vacant lots, unlike the previous floating satellite district.
for x=minX+40,maxX-40,28 do
    for z=minZ+40,maxZ-40,28 do
        local dx=(x-centerX)/(maxX-minX)
        local dz=(z-centerZ)/(maxZ-minZ)
        local distance=math.sqrt(dx*dx+dz*dz)
        -- Mixture of center/outer plots, but no extra far-away island.
        table.insert(plots,{x=x,z=z,priority=distance})
    end
end
table.sort(plots,function(a,b)
    if a.priority==b.priority then
        if a.x==b.x then return a.z<b.z end
        return a.x<b.x
    end
    return a.priority<b.priority
end)

local built=0
local skippedTerrain=0
local usedNames={}
local limitScans=math.min(30,#candidates)
-- Find a suitable building FOR EACH PLOT, not a plot for one oversized
-- candidate repeatedly. Include several smaller prefabs where space is tight.
for _,plot in ipairs(plots) do
    if built>=MAX_BUILDINGS then break end
    local y=surface(plot.x,plot.z)
    if y then
        local found=nil
        local pickedSize=nil
        for index=1,limitScans do
            local candidateIndex=(built+index-1)%limitScans+1
            local entry=candidates[candidateIndex]
            local size=entry.size
            local level=true
            for _,dx in ipairs({-size.X/2-4,size.X/2+4}) do
                for _,dz in ipairs({-size.Z/2-4,size.Z/2+4}) do
                    local y2=surface(plot.x+dx,plot.z+dz)
                    if not y2 or math.abs(y2-y)>2 then level=false end
                end
            end
            if level and free(plot.x,y,plot.z,size.X,size.Z) then
                found=entry
                pickedSize=size
                break
            end
        end
        if found then
            local copy=found.model:Clone()
            for _,child in ipairs(copy:GetDescendants()) do
                if child:IsA("LuaSourceContainer") then child:Destroy() end
                if child:IsA("BasePart") then child.Anchored=true end
            end
            copy.Name=string.format("CityPrefab_%02d_%s",built+1,found.model.Name)
            copy.Parent=target
            local ok,bounds,realSize=pcall(function()return copy:GetBoundingBox()end)
            if ok and realSize then
                -- Source prefab pivots can include pitch/roll, causing entire
                -- towers to lean. Retain only their heading around world Y.
                local pivot=copy:GetPivot()
                local _,yaw,_=pivot:ToOrientation()
                local upright=CFrame.new(plot.x,y,plot.z)*CFrame.Angles(0,yaw,0)
                copy:PivotTo(upright)
                -- Re-evaluate the TRUE world bounding box after rotation;
                -- anchor its lowest point to the original ground surface.
                local correctedBox,correctedSize=copy:GetBoundingBox()
                local bottom=correctedBox.Position.Y-correctedSize.Y/2
                copy:PivotTo(copy:GetPivot()+Vector3.new(0,y-bottom+0.1,0))
                built+=1
                usedNames[found.model.Name]=true
                print(string.format(
                    "[CityPrefab79] PLACED %02d %s at X %.0f Z %.0f | %.0fx%.0f",
                    built,found.model.Name,plot.x,plot.z,pickedSize.X,pickedSize.Z))
            else
                copy:Destroy()
            end
        end
    else
        skippedTerrain+=1
    end
end
target:SetAttribute("PlacementComplete",true)
target:SetAttribute("BuildingCount",built)
print(string.format(
    "[CityPrefab79] DONE: %d buildings, %d prefab candidates, %d terrain-missing plots; roads and gameplay buildings unchanged",
    built,#candidates,skippedTerrain))
