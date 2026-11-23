-- CITY HEIST / Step 72: first prefab-based neighborhood preview.
-- Reuses ACTUAL Roblox Creator Store meshes from the imported modular kit.
-- Runs only in Studio Play, away from the existing city. No gameplay replaced.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
if Workspace:GetAttribute("CityPrefab73Running") then return end
Workspace:SetAttribute("CityPrefab73Running",true)

-- Existing road grid occupies approximately X -364..1136, Z -773..727.
-- Keep the preview outside it, away from the prison (east of city).
local SITE=Vector3.new(320,2,1380)
local MAX_BUILDINGS=12
local MAX_PARTS_PER_BUILDING=850
local COLUMNS=4
local ROWS=3
local BLOCK=140
local stage=ServerStorage:WaitForChild("CityHeistAssetStaging",30)
if not stage then warn("[CityPrefab72] Asset staging missing");return end
local kit=stage:WaitForChild("ModernCityModularKit",30)
if not kit then warn("[CityPrefab72] Imported kit missing");return end
local prefabFolder=kit:FindFirstChild("PrefabBuildings",true)
if not prefabFolder then warn("[CityPrefab72] PrefabBuildings not found");return end

local old=Workspace:FindFirstChild("CityHeistPrefabPreview72")
if old then old:Destroy() end
local preview=Instance.new("Model")
preview.Name="CityHeistPrefabPreview72"
preview:SetAttribute("StudioOnly",true)
preview.Parent=Workspace

local function basePart(name,size,cf,color,material,collide)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.CanCollide=collide~=false;p.Color=color
    p.Material=material or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=preview
    return p
end
local function isPrefab(model)
    if not model:IsA("Model") then return nil end
    local pieces=0
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then pieces+=1 end
        if pieces>MAX_PARTS_PER_BUILDING then return nil end
    end
    if pieces<8 then return nil end
    local ok,cf,dimensions=pcall(function()
        local bound,size=model:GetBoundingBox()
        return bound,size
    end)
    if not ok or not dimensions then return nil end
    local x,z=dimensions.X,dimensions.Z
    if x<9 or z<9 or x>110 or z>110 or dimensions.Y<7 or dimensions.Y>180 then
        return nil
    end
    return {model=model,parts=pieces,size=dimensions,cf=cf}
end
local candidates={}
-- The root contains a mix of folders, group models and individual prefabs.
-- Prefer direct children; use nested models only if no direct candidate exists.
local function collect(children)
    for _,obj in ipairs(children) do
        local candidate=isPrefab(obj)
        if candidate then table.insert(candidates,candidate) end
    end
end
collect(prefabFolder:GetChildren())
if #candidates==0 then
    for _,obj in ipairs(prefabFolder:GetDescendants()) do
        local candidate=isPrefab(obj)
        if candidate then table.insert(candidates,candidate) end
    end
end
table.sort(candidates,function(a,b)
    if a.parts==b.parts then return a.model.Name<b.model.Name end
    return a.parts>b.parts
end)

print(string.format("[CityPrefab72] PrefabBuildings: %d usable candidates",#candidates))
for i=1,math.min(#candidates,12) do
    local item=candidates[i]
    print(string.format("[CityPrefab72] CANDIDATE %02d %s | %.0f x %.0f x %.0f | %d parts",
        i,item.model:GetFullName(),item.size.X,item.size.Y,item.size.Z,item.parts))
end
if #candidates==0 then
    warn("[CityPrefab72] No complete prefabs matched safe bounds; no sample district made")
    preview:Destroy()
    return
end

local roadColor=Color3.fromRGB(49,54,61)
local walkColor=Color3.fromRGB(169,176,181)
local vergeColor=Color3.fromRGB(118,141,125)
local white=Color3.fromRGB(233,235,227)
local yellow=Color3.fromRGB(239,205,93)
local minX=SITE.X-COLUMNS*BLOCK/2
local minZ=SITE.Z-ROWS*BLOCK/2
local totalW=COLUMNS*BLOCK
local totalD=ROWS*BLOCK

-- Continuous orthogonal network: roads are centered on block BOUNDARIES,
-- so prefab parcels sit in the centers and don't overlap traffic lanes.
for j=0,ROWS do
    local z=minZ+j*BLOCK
    basePart("EastWestRoad_"..j,Vector3.new(totalW+30,.7,25),
        CFrame.new(SITE.X,SITE.Y-.34,z),roadColor,Enum.Material.Asphalt)
    for _,side in ipairs({-1,1}) do
        basePart("EastWestPavement_"..j,Vector3.new(totalW+30,.35,5),
            CFrame.new(SITE.X,SITE.Y-.13,z+side*15.3),walkColor,Enum.Material.Concrete)
    end
    for x=minX+14,minX+totalW-12,26 do
        basePart("RoadDashEW",Vector3.new(11,.04,.36),
            CFrame.new(x,SITE.Y+.06,z),yellow,nil,false)
    end
end
for i=0,COLUMNS do
    local x=minX+i*BLOCK
    basePart("NorthSouthRoad_"..i,Vector3.new(25,.7,totalD+30),
        CFrame.new(x,SITE.Y-.34,SITE.Z),roadColor,Enum.Material.Asphalt)
    for _,side in ipairs({-1,1}) do
        basePart("NorthSouthPavement_"..i,Vector3.new(5,.35,totalD+30),
            CFrame.new(x+side*15.3,SITE.Y-.13,SITE.Z),walkColor,Enum.Material.Concrete)
    end
    for z=minZ+14,minZ+totalD-12,26 do
        basePart("RoadDashNS",Vector3.new(.36,.04,11),
            CFrame.new(x,SITE.Y+.06,z),yellow,nil,false)
    end
end

local used=0
local candidateCount=#candidates
-- Reuse distinct genuine prefabs when the catalog has fewer than 12 choices.
-- Layout is deterministic and cells are nonoverlapping.
for row=1,ROWS do
    for col=1,COLUMNS do
        local ordinal=(row-1)*COLUMNS+col
        local entry=candidates[((ordinal-1)%candidateCount)+1]
        local x=minX+(col-.5)*BLOCK
        local z=minZ+(row-.5)*BLOCK
        local clone=entry.model:Clone()
        for _,node in ipairs(clone:GetDescendants()) do
            if node:IsA("LuaSourceContainer") then node:Destroy()
            elseif node:IsA("BasePart") then node.Anchored=true end
        end
        clone.Name=string.format("Building_%02d_%s",ordinal,entry.model.Name)
        clone.Parent=preview
        local ok,box,size=pcall(function() return clone:GetBoundingBox() end)
        if ok and size then
            local pivot=clone:GetPivot()
            local offset=pivot.Position.Y-(box.Position.Y-size.Y/2)
            -- Rotate full prefabs by 180 on alternate rows, without modifying
            -- their interior structure or scaling/distorting mesh geometry.
            local rotate=(row%2==0) and CFrame.Angles(0,math.pi,0) or CFrame.new()
            clone:PivotTo(CFrame.new(x,SITE.Y+offset,z)*rotate*pivot.Rotation)
            basePart("BuildingParcel_"..ordinal,Vector3.new(112,.5,111),
                CFrame.new(x,SITE.Y-.3,z),vergeColor,Enum.Material.Concrete)
            used+=1
            print(string.format("[CityPrefab73] PLACED %02d | %s | %d parts",
                ordinal,entry.model.Name,entry.parts))
        else
            clone:Destroy()
            warn("[CityPrefab73] Could not bound prefab: "..entry.model.Name)
        end
    end
end
print(string.format(
    "[CityPrefab73] 4x3 district: %d prefab buildings; %d available distinct prefabs; crossroads and sidewalks generated. Preview near X=%.0f, Z=%.0f. Live city unchanged.",
    used,candidateCount,SITE.X,SITE.Z))
