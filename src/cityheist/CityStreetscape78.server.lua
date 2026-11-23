-- CITY HEIST / Step 78: streetscape details around verified prefab buildings.
-- Studio preview only. Never changes street geometry or gameplay buildings.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Workspace = game:GetService("Workspace")
local city = Workspace:WaitForChild("CityBlockout",30)
if not city then return end

-- Non-yielding guard: some old Studio copies coexist with Rojo scripts.
if Workspace:GetAttribute("CityStreetscape78Running") then return end
Workspace:SetAttribute("CityStreetscape78Running",true)

local roads = city:WaitForChild("Roads",30)
local ground = city:WaitForChild("Ground",30)
local prefabs = Workspace:WaitForChild("CityHeistPrefabCity74",105)
if not (roads and ground and prefabs) then
    warn("[CityStreetscape78] Map or new prefab folder not available; skipped")
    return
end

-- Prefab folder is created before its 12 models finish placing.
local waited = 0
while #prefabs:GetChildren() < 12 and waited < 18 do
    task.wait(.5)
    waited += .5
end

local old=Workspace:FindFirstChild("CityHeistStreetscape78")
if old then old:Destroy() end
local folder=Instance.new("Folder")
folder.Name="CityHeistStreetscape78"
folder:SetAttribute("StudioPreview",true)
folder.Parent=Workspace

local includes={roads,prefabs}
for _,name in ipairs({"GameplayLocations","CityLocations","Downtown","CityGarages","CityDecorativeHomes"}) do
    local obj=city:FindFirstChild(name)
    if obj then table.insert(includes,obj) end
end
local prison=Workspace:FindFirstChild("CityPrison")
if prison then table.insert(includes,prison) end
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances=includes
local terrainParams=RaycastParams.new()
terrainParams.FilterType=Enum.RaycastFilterType.Include
terrainParams.FilterDescendantsInstances={ground}
local function floorAt(x,z)
    local result=Workspace:Raycast(Vector3.new(x,400,z),
        Vector3.new(0,-1000,0),terrainParams)
    if result and result.Normal.Y>.85 then return result.Position.Y end
    return nil
end
local function hasBlockingObject(x,y,z,r,h)
    -- Test the whole vertical volume so trees and lamps do not overlap facades,
    -- sidewalks, road markings, underground structures, or existing buildings.
    local hits=Workspace:GetPartBoundsInBox(
        CFrame.new(x,y+h*.5,z),
        Vector3.new(r*2,h,r*2),params)
    for _,p in ipairs(hits) do
        if p:IsA("BasePart") and p.CanCollide then return true end
    end
    for _,p in ipairs(folder:GetDescendants()) do
        if p:IsA("BasePart") and p.Name=="StreetDetailFootprint" then
            local d=(Vector3.new(x,0,z)-Vector3.new(p.Position.X,0,p.Position.Z)).Magnitude
            if d < r+p.Size.X*.5 then return true end
        end
    end
    return false
end

local function p(name,size,pos,color,material,collides)
    local obj=Instance.new("Part")
    obj.Name=name
    obj.Anchored=true
    obj.CanCollide=collides~=false
    obj.Material=material or Enum.Material.SmoothPlastic
    obj.Size=size
    obj.CFrame=CFrame.new(pos)
    obj.Color=color
    obj.TopSurface=Enum.SurfaceType.Smooth
    obj.BottomSurface=Enum.SurfaceType.Smooth
    obj.Parent=folder
    return obj
end
local function footprint(x,y,z,r)
    local f=p("StreetDetailFootprint",Vector3.new(r*2,.1,r*2),
        Vector3.new(x,y-.3,z),Color3.fromRGB(90,115,93),
        Enum.Material.Grass,false)
    f.Transparency=1
end

local palette={
    trunk=Color3.fromRGB(96,70,48),
    canopy=Color3.fromRGB(66,133,78),
    frame=Color3.fromRGB(58,68,75),
    wood=Color3.fromRGB(132,103,78),
    lamp=Color3.fromRGB(255,240,185),
    stone=Color3.fromRGB(168,174,175)
}

local function tree(x,y,z)
    footprint(x,y,z,4.5)
    p("TreePlanter",Vector3.new(9,.55,9),Vector3.new(x,y+.28,z),
        palette.stone,Enum.Material.Concrete)
    p("TreeSoil",Vector3.new(7.8,.16,7.8),Vector3.new(x,y+.62,z),
        Color3.fromRGB(84,97,69),Enum.Material.Grass)
    p("TreeTrunk",Vector3.new(1.35,9,1.35),Vector3.new(x,y+5.1,z),
        palette.trunk,Enum.Material.Wood)
    local crown=p("TreeCrown",Vector3.new(8.5,8.5,8.5),
        Vector3.new(x,y+12,z),palette.canopy,Enum.Material.Grass,false)
    crown.Shape=Enum.PartType.Ball
end
local function lamp(x,y,z)
    footprint(x,y,z,2)
    p("StreetLampBase",Vector3.new(2,.55,2),Vector3.new(x,y+.28,z),
        palette.stone,Enum.Material.Concrete)
    p("StreetLampPole",Vector3.new(.6,13,.6),Vector3.new(x,y+6.8,z),
        palette.frame,Enum.Material.Metal)
    local head=p("StreetLampHead",Vector3.new(3,.6,3),
        Vector3.new(x,y+13.45,z),palette.lamp,Enum.Material.Neon,false)
    local light=Instance.new("PointLight")
    light.Range=35
    light.Brightness=1.7
    light.Shadows=true
    light.Parent=head
end
local function bench(x,y,z)
    footprint(x,y,z,3)
    for _,dx in ipairs({-2.3,2.3}) do
        p("BenchLeg",Vector3.new(.5,2,.6),
            Vector3.new(x+dx,y+1,z),palette.frame,Enum.Material.Metal)
    end
    p("BenchSeat",Vector3.new(6,.5,2.3),Vector3.new(x,y+2.2,z),
        palette.wood,Enum.Material.Wood)
    p("BenchBack",Vector3.new(6,2,.4),Vector3.new(x,y+3.1,z+1),
        palette.wood,Enum.Material.Wood)
end

local placed={tree=0,lamp=0,bench=0}
local buildings={}
for _,obj in ipairs(prefabs:GetChildren()) do
    if obj:IsA("Model") then table.insert(buildings,obj) end
end
table.sort(buildings,function(a,b)return a.Name<b.Name end)

-- Four corner zones per city building; pick candidates from outside the
-- actual world-space bounds and validate every site against roads/structures.
for index,model in ipairs(buildings) do
    local box,size=model:GetBoundingBox()
    local x,z=box.Position.X,box.Position.Z
    local maxX=size.X*.5
    local maxZ=size.Z*.5
    local attempts={
        {x-maxX-13,z-maxZ-13,"tree",5,17},
        {x+maxX+13,z+maxZ+13,"tree",5,17},
        {x-maxX-12,z+maxZ+12,"lamp",3,16},
        {x+maxX+12,z-maxZ-12,"lamp",3,16},
        {x,z-maxZ-12,"bench",3.5,7},
    }
    for _,item in ipairs(attempts) do
        local cx,cz,typ,r,h=item[1],item[2],item[3],item[4],item[5]
        local gy=floorAt(cx,cz)
        if gy and not hasBlockingObject(cx,gy,cz,r,h) then
            if typ=="tree" and placed.tree<14 then
                tree(cx,gy,cz);placed.tree+=1
            elseif typ=="lamp" and placed.lamp<16 then
                lamp(cx,gy,cz);placed.lamp+=1
            elseif typ=="bench" and placed.bench<8 then
                bench(cx,gy,cz);placed.bench+=1
            end
        end
    end
end
print(string.format(
    "[CityStreetscape78] %d prefab buildings checked. Added %d trees, %d lamps, %d benches; existing roads and buildings unchanged.",
    #buildings,placed.tree,placed.lamp,placed.bench))
