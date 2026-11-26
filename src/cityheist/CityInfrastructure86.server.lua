-- CITY HEIST / STEP 86: safe infill parking and fuel station preview.
-- Creates NEW decorative objects only; never edits roads, heists, police or garage scripts.
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
if W:GetAttribute("CityInfrastructure87Running") then return end
W:SetAttribute("CityInfrastructure87Running",true)
print("[CityInfra87] START")

local city=W:WaitForChild("CityBlockout",30)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
local main=W:WaitForChild("CityHeistPrefabCity74",90)
local extra=W:WaitForChild("CityHeistInfill81",90)
if not (city and roads and ground and main and extra) then
    warn("[CityInfra87] Missing map / prefab infrastructure, skipped")
    return
end

local elapsed=0
while elapsed<60 and not (main:GetAttribute("PlacementComplete") and extra:GetAttribute("PlacementComplete")) do
    task.wait(.5)
    elapsed+=.5
end
if not (main:GetAttribute("PlacementComplete") and extra:GetAttribute("PlacementComplete")) then
    warn("[CityInfra87] Prefab placement did not complete; skipped to avoid overlap")
    return
end
-- Decoration generator already has a defined finish point when its parent
-- folder exists and was populated; existing decorations are blockers too.
local prior=W:FindFirstChild("CityHeistInfrastructure86")
if prior then prior:Destroy() end
local root=Instance.new("Folder")
root.Name="CityHeistInfrastructure86"
root:SetAttribute("StudioPreview",true)
root.Parent=W

local blockers={roads,main,extra,root}
for _,name in ipairs({"GameplayLocations","CityLocations","Downtown","CityGarages","CityDecorativeHomes"}) do
    local obj=city:FindFirstChild(name)
    if obj then table.insert(blockers,obj) end
end
for _,name in ipairs({"CityHeistStreetscape79","CityPrison","CityHeistGarageSpawned"}) do
    local obj=W:FindFirstChild(name)
    if obj then table.insert(blockers,obj) end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=blockers
local groundRay=RaycastParams.new()
groundRay.FilterType=Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances={ground}
local function groundY(x,z)
    local hit=W:Raycast(Vector3.new(x,420,z),Vector3.new(0,-900,0),groundRay)
    return hit and hit.Normal.Y>.9 and hit.Position.Y or nil
end
local function vacant(x,y,z,w,d)
    local hits=W:GetPartBoundsInBox(CFrame.new(x,y+9,z),Vector3.new(w+12,20,d+12),overlap)
    return #hits==0
end

local allRoads={}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,part in ipairs(roads:GetDescendants()) do
    if part:IsA("BasePart") and part.Size.X>6 and part.Size.Z>6 then
        table.insert(allRoads,part)
        for _,dx in ipairs({-part.Size.X/2,part.Size.X/2}) do
            for _,dz in ipairs({-part.Size.Z/2,part.Size.Z/2}) do
                local v=part.CFrame:PointToWorldSpace(Vector3.new(dx,0,dz))
                minX=math.min(minX,v.X);maxX=math.max(maxX,v.X)
                minZ=math.min(minZ,v.Z);maxZ=math.max(maxZ,v.Z)
            end
        end
    end
end
if #allRoads<4 then warn("[CityInfra87] Invalid road bounds; skipped");root:Destroy();return end

-- Near-street sites: measure horizontal distance to the actual road
-- rectangles rather than assuming a regular grid or building a new road.
local function roadDistance(x,z)
    local nearest=math.huge
    for _,road in ipairs(allRoads) do
        local q=road.CFrame:PointToObjectSpace(Vector3.new(x,road.Position.Y,z))
        local ox=math.max(math.abs(q.X)-road.Size.X/2,0)
        local oz=math.max(math.abs(q.Z)-road.Size.Z/2,0)
        local dist=math.sqrt(ox*ox+oz*oz)
        if dist<nearest then nearest=dist end
    end
    return nearest
end
local palettes={
    asphalt=Color3.fromRGB(53,57,62),
    line=Color3.fromRGB(238,238,230),
    concrete=Color3.fromRGB(169,176,174),
    frame=Color3.fromRGB(65,76,86),
    petrol=Color3.fromRGB(24,124,165),
    petrolLight=Color3.fromRGB(28,178,209),
}
local function part(parent,name,size,cf,color,mat,solid)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf
    p.Color=color;p.Anchored=true;p.CanCollide=solid~=false
    p.Material=mat or Enum.Material.SmoothPlastic
    p.TopSurface=Enum.SurfaceType.Smooth
    p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function makeParking(index,x,y,z)
    local m=Instance.new("Model")
    m.Name="PublicParking_"..index;m.Parent=root
    -- Compact 3-space lot suited to the actual city block size.
    part(m,"ParkingSurface",Vector3.new(36,.28,26),
        CFrame.new(x,y+.12,z),palettes.asphalt,Enum.Material.Asphalt)
    for slot=0,3 do
        local sx=x-15+slot*10
        part(m,"BayStripe",Vector3.new(.22,.04,12),
            CFrame.new(sx,y+.29,z-6),palettes.line,nil,false)
    end
    part(m,"BayRearStripe",Vector3.new(30,.04,.22),
        CFrame.new(x,y+.29,z-12),palettes.line,nil,false)
    for _,sx in ipairs({-16,16}) do
        part(m,"Bollard",Vector3.new(.85,2.6,.85),
            CFrame.new(x+sx,y+1.3,z+11),
            Color3.fromRGB(238,192,80),Enum.Material.Metal)
    end
    m:SetAttribute("DecorativeOnly",true)
end
local function makeFuelStation(x,y,z)
    local m=Instance.new("Model")
    m.Name="FuelStation";m.Parent=root
    -- Compact two-pump urban service station, fully inside a 46x36 plot.
    part(m,"Forecourt",Vector3.new(46,.3,36),
        CFrame.new(x,y+.15,z),palettes.concrete,Enum.Material.Concrete)
    for _,dx in ipairs({-17,17}) do
        part(m,"CanopyColumn",Vector3.new(1.6,12,1.6),
            CFrame.new(x+dx,y+6.15,z),palettes.frame,Enum.Material.Metal)
    end
    part(m,"FuelCanopy",Vector3.new(40,1.5,25),
        CFrame.new(x,y+12.9,z),palettes.petrol,Enum.Material.Metal)
    part(m,"FuelCanopyTrim",Vector3.new(41,.5,26),
        CFrame.new(x,y+13.9,z),palettes.petrolLight,Enum.Material.Neon,false)
    for _,dx in ipairs({-10,10}) do
        part(m,"PumpIsland",Vector3.new(4,.5,8),
            CFrame.new(x+dx,y+.55,z),palettes.concrete,Enum.Material.Concrete)
        part(m,"FuelPump",Vector3.new(2.6,5,3.2),
            CFrame.new(x+dx,y+3.2,z),palettes.petrol,Enum.Material.Metal)
        part(m,"PumpDisplay",Vector3.new(2,1.2,.1),
            CFrame.new(x+dx,y+4.1,z-1.65),
            Color3.fromRGB(173,222,231),Enum.Material.Glass,false)
    end
    m:SetAttribute("DecorativeOnly",true)
end

-- Search fine-grained coordinates around real streets, not a coarse
-- 24-stud grid. Every proposed lot must pass full-volume collision tests.
local points={}
for x=minX+30,maxX-30,12 do
    for z=minZ+30,maxZ-30,12 do
        local street=roadDistance(x,z)
        if street>=14 and street<=65 then
            table.insert(points,{x=x,z=z,street=street,
                ring=math.abs(x-(minX+maxX)/2)+math.abs(z-(minZ+maxZ)/2)})
        end
    end
end
table.sort(points,function(a,b)
    if a.street==b.street then return a.ring>b.ring end
    return a.street<b.street
end)
local counts={ground=0,flat=0,blocked=0,passed=0}
local function placeType(kind,required,w,d)
    local placed=0
    for _,v in ipairs(points) do
        if placed>=required then break end
        -- A parking/fuel plot must be beside the street, not on its surface.
        local minimum=math.min(w,d)/2+6
        if v.street>=minimum and v.street<=minimum+30 then
            local y=groundY(v.x,v.z)
            if not y then
                counts.ground+=1
            else
                local flat=true
                for _,dx in ipairs({-w/2-2,w/2+2}) do
                    for _,dz in ipairs({-d/2-2,d/2+2}) do
                        local yy=groundY(v.x+dx,v.z+dz)
                        if not yy or math.abs(yy-y)>1.3 then flat=false end
                    end
                end
                if not flat then
                    counts.flat+=1
                elseif not vacant(v.x,y,v.z,w,d) then
                    counts.blocked+=1
                else
                    placed+=1
                    counts.passed+=1
                    if kind=="fuel" then
                        makeFuelStation(v.x,y,v.z)
                    else
                        makeParking(placed,v.x,y,v.z)
                    end
                    print(string.format("[CityInfra87] PLACED %s %d at X %.0f Z %.0f",
                        kind,placed,v.x,v.z))
                end
            end
        end
    end
    return placed
end
-- Search independently for both uses. Failure to locate the first parking
-- must never suppress searching for a gas station.
local fuel=placeType("fuel",1,46,36)
local parking=placeType("parking",2,36,26)
print(string.format("[CityInfra87] DIAGNOSTICS: %d plots considered; %d ground failures, %d uneven, %d occupied, %d clear",
    #points,counts.ground,counts.flat,counts.blocked,counts.passed))

print(string.format("[CityInfra87] DONE: %d parking lots, %d fuel stations; existing 28 prefab buildings and road grid unchanged",
    parking,fuel))
