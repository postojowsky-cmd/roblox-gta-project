-- CITY HEIST / Step 72: first prefab-based neighborhood preview.
-- Reuses ACTUAL Roblox Creator Store meshes from the imported modular kit.
-- Runs only in Studio Play, away from the existing city. No gameplay replaced.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Workspace=game:GetService("Workspace")
local ServerStorage=game:GetService("ServerStorage")
if Workspace:GetAttribute("CityPrefab72Running") then return end
Workspace:SetAttribute("CityPrefab72Running",true)

-- Existing road grid occupies approximately X -364..1136, Z -773..727.
-- Keep the preview outside it, away from the prison (east of city).
local SITE=Vector3.new(320,2,1190)
local MAX_BUILDINGS=3
local MAX_PARTS_PER_BUILDING=850

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
local walkColor=Color3.fromRGB(170,175,176)
-- A small connected street with proper sidewalks and foundations.
basePart("MainStreet",Vector3.new(375,1,29),CFrame.new(SITE.X,SITE.Y-0.5,SITE.Z),
    roadColor,Enum.Material.Asphalt)
for _,side in ipairs({-1,1}) do
    basePart("Sidewalk",Vector3.new(375,0.7,8),
        CFrame.new(SITE.X,SITE.Y-0.35,SITE.Z+side*19),
        walkColor,Enum.Material.Concrete)
end
for x=-170,170,20 do
    basePart("LaneMarking",Vector3.new(10,0.06,0.4),
        CFrame.new(SITE.X+x,SITE.Y+0.06,SITE.Z),
        Color3.fromRGB(245,207,80),nil,false)
end

local used=0
local seen={}
for _,entry in ipairs(candidates) do
    if used>=MAX_BUILDINGS then break end
    -- avoid three near-identical copies of the same prefab name
    if not seen[entry.model.Name] then
        seen[entry.model.Name]=true
        local clone=entry.model:Clone()
        -- double protection: regardless of staging, never run foreign scripts.
        for _,node in ipairs(clone:GetDescendants()) do
            if node:IsA("LuaSourceContainer") then node:Destroy()
            elseif node:IsA("BasePart") then node.Anchored=true end
        end
        clone.Name="Prefab_"..(used+1).."_"..entry.model.Name
        clone.Parent=preview
        local ok,box,size=pcall(function()return clone:GetBoundingBox()end)
        if not ok or not size then
            clone:Destroy()
        else
            local x=SITE.X+(used-1)*117
            local z=SITE.Z-60
            local originalPivot=clone:GetPivot()
            local rotation=originalPivot.Rotation
            local offsetFromBottom=originalPivot.Position.Y-(box.Position.Y-size.Y/2)
            local target=CFrame.new(x,SITE.Y+offsetFromBottom,z)*rotation
            clone:PivotTo(target)
            -- Safe single-lot slab below the prefab building.
            basePart("BuildingParcel",Vector3.new(108,0.6,98),
                CFrame.new(x,SITE.Y-0.3,z),Color3.fromRGB(113,128,121),
                Enum.Material.Concrete)
            used+=1
            print(string.format("[CityPrefab72] PLACED %s | %d parts",clone.Name,entry.parts))
        end
    end
end
print(string.format(
    "[CityPrefab72] Preview built: %d authentic prefab buildings, site X=%.0f Z=%.0f. Existing city untouched.",
    used,SITE.X,SITE.Z))
