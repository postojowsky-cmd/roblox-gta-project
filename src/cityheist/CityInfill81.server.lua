-- CITY HEIST / STEP 84: diagnosed optional prefab infill (Studio preview).
-- Reuses imported Creator Store prefab models, not arbitrary new towers.
-- Keeps the proven 20 buildings and ALL roads / gameplay models unchanged.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end

-- Step 90: preserve explicitly baked city geometry; never regenerate over it.
local bakedWorld = game:GetService("Workspace")
local bakedReady = true
for _, name in ipairs({"CityHeistPrefabCity74","CityHeistInfill81","CityHeistStreetscape79","CityHeistInfrastructure86","CityHeistAccess88"}) do
    local folder = bakedWorld:FindFirstChild(name)
    if not folder or folder:GetAttribute("CityHeistBaked90") ~= true or #folder:GetChildren() == 0 then
        bakedReady = false
        break
    end
end
if bakedReady then
    print("[CityBake90] Saved city retained: " .. script.Name)
    return
end
-- Fail closed on a partial baked import rather than deleting saved geometry.
for _, name in ipairs({"CityHeistPrefabCity74","CityHeistInfill81","CityHeistStreetscape79","CityHeistInfrastructure86","CityHeistAccess88"}) do
    local folder = bakedWorld:FindFirstChild(name)
    if folder and folder:GetAttribute("CityHeistBaked90") == true then
        warn("[CityBake90] Partial baked city; generation blocked: " .. script.Name)
        return
    end
end
local W=game:GetService("Workspace")
local SS=game:GetService("ServerStorage")
print("[CityInfill85] START: script launched in Studio")
if W:GetAttribute("CityInfill85Running") then
    print("[CityInfill85] DUPLICATE: already running; skipping")
    return
end
W:SetAttribute("CityInfill85Running",true)
print("[CityInfill85] Waiting for map, original buildings and asset kit")

-- Poll all dependencies together so a missing one cannot silently
-- stall for several sequential 30/45/90/105-second timeouts.
local city,roads,ground,existing,stage,kit,source
local ready=false
for attempt=1,50 do
    city=W:FindFirstChild("CityBlockout")
    roads=city and city:FindFirstChild("Roads")
    ground=city and city:FindFirstChild("Ground")
    existing=W:FindFirstChild("CityHeistPrefabCity74")
    stage=SS:FindFirstChild("CityHeistAssetStaging")
    kit=stage and stage:FindFirstChild("ModernCityModularKit")
    source=kit and kit:FindFirstChild("PrefabBuildings",true)
    ready=roads~=nil and ground~=nil and existing~=nil and source~=nil
        and existing:GetAttribute("PlacementComplete")==true
    if ready then break end
    if attempt==1 or attempt%5==0 then
        print(string.format("[CityInfill85] WAIT %ds | roads=%s ground=%s original=%s placed=%s import=%s kit=%s prefabFolder=%s",
            attempt-1,tostring(roads~=nil),tostring(ground~=nil),
            tostring(existing~=nil),
            tostring(existing and existing:GetAttribute("PlacementComplete")),
            tostring(stage and stage:GetAttribute("ImportStatus")),
            tostring(kit~=nil),tostring(source~=nil)))
    end
    task.wait(1)
end
if not ready then
    warn("[CityInfill85] Missing readiness after 50s, skipping only optional infill")
    return
end
print("[CityInfill85] READY: all source assets and main buildings loaded")

print("[CityInfill85] Inputs ready; scanning prefab catalog")
local candidates={}
local function register(m)
    if not m:IsA("Model") then return end
    local count=0
    for _,obj in ipairs(m:GetDescendants()) do
        if obj:IsA("BasePart") then
            count+=1
            if count>800 then return end
        end
    end
    if count<8 then return end
    local ok,box,size=pcall(function()return m:GetBoundingBox()end)
    if not ok or not size then return end
    if size.X<9 or size.Z<9 or size.Y<8
        or size.X>105 or size.Z>105 or size.Y>150 then return end
    table.insert(candidates,{model=m,size=size,height=size.Y,count=count})
end
-- Mirror the proven primary builder: try nested individual models first.
local scanned=0
for _,m in ipairs(source:GetDescendants()) do
    scanned+=1
    if scanned%250==0 then task.wait() end
    if m:IsA("Model") then
        local nested=0
        for _,obj in ipairs(m:GetDescendants()) do
            if obj:IsA("Model") then nested+=1 end
            if nested>6 then break end
        end
        if nested<=6 then register(m) end
    end
end
local selection="nested"
if #candidates==0 then
    selection="root fallback"
    print("[CityInfill85] No nested complete prefabs; trying kit root models, as in CityPrefab79")
    for _,m in ipairs(source:GetChildren()) do register(m) end
end
print(string.format("[CityInfill85] Selection=%s | usable=%d",selection,#candidates))
-- Match the dimensions already proven by the main city builder and then
-- sort by height; the first models are the shortest *available* buildings.
table.sort(candidates,function(a,b)
    if a.height==b.height then return a.model.Name<b.model.Name end
    return a.height<b.height
end)
print(string.format("[CityInfill85] %d usable candidates; height range %.0f..%.0f",
    #candidates,#candidates>0 and candidates[1].height or 0,
    #candidates>0 and candidates[#candidates].height or 0))
if #candidates==0 then
    warn("[CityInfill85] No complete prefab buildings match proven city generator criteria; no buildings added")
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
if #roadParts<4 then warn("[CityInfill85] No valid road grid");result:Destroy();return end
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

print(string.format("[CityInfill85] Found %d roads, %d candidate plots; checking free sites",#roadParts,#points))
local count=0
local MAX=8
local attempts=math.min(#candidates,18)
for _,pt in ipairs(points) do
    if count>=MAX then break end
    local y=surface(pt.x,pt.z)
    if y then
        for j=1,attempts do
            local entry=candidates[(j-1)%attempts+1]
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
                print(string.format("[CityInfill85] PLACED %02d %s | %.0fx%.0fx%.0f | X %.0f Z %.0f",
                    count,entry.model.Name,sz.X,sz.Y,sz.Z,pt.x,pt.z))
                break
            end
        end
    end
end
result:SetAttribute("PlacementComplete",true)
result:SetAttribute("BuildingCount",count)
print(string.format(
    "[CityInfill85] DONE: %d extra prefabs selected shortest-first, %d eligible prefabs; original 20 and city roads unchanged",
    count,#candidates))
