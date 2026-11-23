-- City Heist: decorative residential districts (Studio preview).
-- Empty plots only. Never moves roads, gameplay buildings, police or garages.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",25)
if not city then return end
local roads=city:FindFirstChild("Roads")
local ground=city:FindFirstChild("Ground")
if not (roads and ground) then warn("[CityHomes] Missing road/ground data");return end
task.wait(7) -- let city layout finish

local prior=city:FindFirstChild("CityDecorativeHomes")
if prior then prior:Destroy() end
local folder=Instance.new("Folder")
folder.Name="CityDecorativeHomes"
folder.Parent=city

local roadParts={}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>4 and p.Size.Z>4 then
        table.insert(roadParts,p)
        for _,x in ipairs({-p.Size.X/2,p.Size.X/2}) do
            for _,z in ipairs({-p.Size.Z/2,p.Size.Z/2}) do
                local q=p.CFrame:PointToWorldSpace(Vector3.new(x,0,z))
                minX=math.min(minX,q.X);maxX=math.max(maxX,q.X)
                minZ=math.min(minZ,q.Z);maxZ=math.max(maxZ,q.Z)
            end
        end
    end
end
if #roadParts<4 then warn("[CityHomes] Too few roads");return end

local collisionObjects={roads,city:FindFirstChild("GameplayLocations"),
    city:FindFirstChild("CityLocations"),city:FindFirstChild("Downtown"),
    city:FindFirstChild("CityGarages"),W:FindFirstChild("CityPrison")}
local collisionList={}
for _,item in ipairs(collisionObjects) do
    if item then table.insert(collisionList,item) end
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances=collisionList
local groundRay=RaycastParams.new()
groundRay.FilterType=Enum.RaycastFilterType.Include
groundRay.FilterDescendantsInstances={ground}
local function groundAt(x,z)
    local hit=W:Raycast(Vector3.new(x,300,z),Vector3.new(0,-800,0),groundRay)
    if hit and hit.Normal.Y>.8 then return hit.Position.Y end
    return nil
end
local function occupied(x,y,z,w,d)
    local cf=CFrame.new(x,y+10,z)
    for _,p in ipairs(W:GetPartBoundsInBox(cf,Vector3.new(w+16,30,d+16),overlap)) do
        -- Only ground is ignored; roads, buildings, prison and garages block.
        if p:IsA("BasePart") and (p.Size.X>2 or p.Size.Z>2) then return true end
    end
    for _,m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then
            local cf2,s=m:GetBoundingBox()
            if math.abs(cf2.Position.X-x)<(w+s.X)/2+9
                and math.abs(cf2.Position.Z-z)<(d+s.Z)/2+9 then
                return true
            end
        end
    end
    return false
end
local colors={
    Color3.fromRGB(197,177,146),Color3.fromRGB(174,193,199),
    Color3.fromRGB(209,187,169),Color3.fromRGB(178,197,173),
    Color3.fromRGB(191,183,203),Color3.fromRGB(214,208,188)
}
local roofs={
    Color3.fromRGB(83,77,76),Color3.fromRGB(117,69,60),
    Color3.fromRGB(58,73,83),Color3.fromRGB(87,92,89)
}
local function part(parent,name,size,cf,color,mat,collide,trans)
    local p=Instance.new("Part")
    p.Name=name;p.Anchored=true;p.CanCollide=collide~=false
    p.Size=size;p.CFrame=cf;p.Color=color
    p.Material=mat or Enum.Material.SmoothPlastic
    p.Transparency=trans or 0;p.Parent=parent
    return p
end
local function house(index,x,y,z)
    local m=Instance.new("Model")
    m.Name=string.format("ResidentialHouse_%02d",index)
    m.Parent=folder
    local color=colors[(index-1)%#colors+1]
    local roofColor=roofs[(index-1)%#roofs+1]
    local origin=CFrame.new(x,y,z)
    local at=function(a,b,c)return origin*CFrame.new(a,b,c)end
    part(m,"Foundation",Vector3.new(39,.7,34),at(0,.35,0),
        Color3.fromRGB(159,158,153),Enum.Material.Concrete)
    part(m,"Facade",Vector3.new(33,16,28),at(0,8.8,0),
        color,Enum.Material.Concrete)
    part(m,"Roof",Vector3.new(38,2,33),at(0,17.8,0),
        roofColor,Enum.Material.Slate)
    part(m,"RoofRidge",Vector3.new(37,1,2.2),at(0,19.1,0),
        roofColor,Enum.Material.Slate)
    -- The door and windows are facade decorations; interiors come later.
    part(m,"FrontDoor",Vector3.new(4.5,8,.3),at(0,4,-14.2),
        Color3.fromRGB(90,69,53),Enum.Material.Wood,false)
    part(m,"DoorFrame",Vector3.new(5.3,.45,.65),at(0,8.25,-14.2),
        Color3.fromRGB(238,237,227),Enum.Material.Wood,false)
    part(m,"DoorHandle",Vector3.new(.35,.55,.4),at(1.7,3.8,-14.5),
        Color3.fromRGB(234,215,156),Enum.Material.Metal,false)
    for _,xx in ipairs({-10,10}) do
        for _,yy in ipairs({6,12}) do
            part(m,"WindowGlass",Vector3.new(5.7,3.3,.3),
                at(xx,yy,-14.3),Color3.fromRGB(116,191,214),
                Enum.Material.Glass,false,.24)
            for _,zsize in ipairs({0}) do
                part(m,"WindowMullion",Vector3.new(.25,3.4,.5),
                    at(xx,yy,-14.5),Color3.fromRGB(239,239,232),
                    Enum.Material.Metal,false)
            end
        end
    end
    part(m,"FrontSteps",Vector3.new(7,.5,4),at(0,.6,-16.7),
        Color3.fromRGB(177,178,174),Enum.Material.Concrete)
    part(m,"FrontPath",Vector3.new(6,.2,12),at(0,.18,-22),
        Color3.fromRGB(175,176,170),Enum.Material.Concrete)
    -- Small mailbox and porch light, with no gameplay scripting.
    part(m,"MailboxPost",Vector3.new(.45,3,.45),at(12,1.6,-18),
        Color3.fromRGB(75,78,83),Enum.Material.Metal)
    part(m,"Mailbox",Vector3.new(2,1.2,1.5),at(12,3.2,-18),
        Color3.fromRGB(70,84,96),Enum.Material.Metal)
    local porch=part(m,"PorchLight",Vector3.new(1,.6,.6),at(3.3,8.8,-14.6),
        Color3.fromRGB(245,235,186),Enum.Material.Neon,false)
    local light=Instance.new("PointLight");light.Range=15;light.Brightness=.7
    light.Parent=porch
end

local plots={}
local midX=(minX+maxX)/2
local midZ=(minZ+maxZ)/2
-- Favor the outer residential blocks, away from the skyscraper core.
for x=minX+85,maxX-85,66 do
    for z=minZ+85,maxZ-85,66 do
        local edge=math.max(math.abs(x-midX)/(maxX-minX),
            math.abs(z-midZ)/(maxZ-minZ))
        table.insert(plots,{x=x,z=z,edge=edge})
    end
end
table.sort(plots,function(a,b)
    if a.edge==b.edge then return a.x<b.x end
    return a.edge>b.edge
end)
local count=0
for _,plot in ipairs(plots) do
    if count>=18 then break end
    local y=groundAt(plot.x,plot.z)
    if y then
        local flatPlot=true
        for _,dx in ipairs({-23,23}) do
            for _,dz in ipairs({-26,26}) do
                local cornerY=groundAt(plot.x+dx,plot.z+dz)
                if not cornerY or math.abs(cornerY-y)>1.5 then flatPlot=false end
            end
        end
        if flatPlot and not occupied(plot.x,y,plot.z,42,48) then
            count+=1
            house(count,plot.x,y,plot.z)
        end
    end
end
print(string.format("[CityHomes] Added %d decorative houses on road-free plots; no existing map objects moved",count))
