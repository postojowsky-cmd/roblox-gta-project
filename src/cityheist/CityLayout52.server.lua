-- City Heist step 54: bounded road-aware building placement (Studio Play preview only).
-- Never changes Roads, and never commits placement into the saved Studio map.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local workspace=game:GetService("Workspace")
local city=workspace:WaitForChild("CityBlockout",20)
local locations=city and city:WaitForChild("GameplayLocations",20)
local roads=city and city:FindFirstChild("Roads")
if not locations or not roads then
    warn("[CityLayout54] Missing GameplayLocations or Roads; preserving original positions")
    return
end

local names={"Bank_1","Bank_2","Bank_3","Shop_1","Shop_2","Shop_3","Shop_4","Police_1","Police_2","Dealership_1","Dealership_2"}
local targets={
    Bank_1=Vector2.new(-450,-380),Bank_2=Vector2.new(430,-350),
    Bank_3=Vector2.new(400,420),
    Shop_1=Vector2.new(-200,-400),Shop_2=Vector2.new(220,-120),
    Shop_3=Vector2.new(-400,190),Shop_4=Vector2.new(120,410),
    Police_1=Vector2.new(-430,420),Police_2=Vector2.new(460,100),
    Dealership_1=Vector2.new(-110,120),Dealership_2=Vector2.new(200,-460)
}
local models={}
local center=Vector3.zero
local count=0
for _,name in ipairs(names) do
    local m=locations:FindFirstChild(name)
    if m and m:IsA("Model") then
        models[name]=m
        center+=m:GetPivot().Position
        count+=1
    end
end
if count==0 then return end
center/=count

-- Use all road BaseParts, regardless of their names; transform footprint
-- corners into each road part's local coordinates for rotated roads.
local roadParts={}
for _,obj in ipairs(roads:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Size.X>1 and obj.Size.Z>1 then
        table.insert(roadParts,obj)
    end
end
if #roadParts==0 then
    warn("[CityLayout54] No road parts detected: no buildings moved")
    return
end

local function footprint(model)
    local cf,size=model:GetBoundingBox()
    local pivot=model:GetPivot()
    local offset=pivot:ToObjectSpace(cf)
    return offset,size
end
local function corners(cf,size,margin)
    local x=size.X/2+margin
    local z=size.Z/2+margin
    return {
        cf:PointToWorldSpace(Vector3.new(-x,0,-z)),
        cf:PointToWorldSpace(Vector3.new(-x,0,z)),
        cf:PointToWorldSpace(Vector3.new(x,0,-z)),
        cf:PointToWorldSpace(Vector3.new(x,0,z))
    }
end
local function intersectsRoad(cf,size)
    local pts=corners(cf,size,7)
    for _,road in ipairs(roadParts) do
        local hx=road.Size.X/2+3
        local hz=road.Size.Z/2+3
        -- SAT in XZ: project road rectangle and building rectangle onto
        -- both sets of local horizontal axes. Conservative for yawed models.
        local axes={
            Vector2.new(cf.RightVector.X,cf.RightVector.Z),
            Vector2.new(cf.LookVector.X,cf.LookVector.Z),
            Vector2.new(road.CFrame.RightVector.X,road.CFrame.RightVector.Z),
            Vector2.new(road.CFrame.LookVector.X,road.CFrame.LookVector.Z)
        }
        local roadPoints=corners(road.CFrame,road.Size,3)
        local collision=true
        for _,axis in ipairs(axes) do
            local len=axis.Magnitude
            if len>0.001 then
                axis/=len
                local amin,amax=math.huge,-math.huge
                local bmin,bmax=math.huge,-math.huge
                for _,p in ipairs(pts) do
                    local d=p.X*axis.X+p.Z*axis.Y
                    amin=math.min(amin,d);amax=math.max(amax,d)
                end
                for _,p in ipairs(roadPoints) do
                    local d=p.X*axis.X+p.Z*axis.Y
                    bmin=math.min(bmin,d);bmax=math.max(bmax,d)
                end
                if amax<bmin or bmax<amin then collision=false;break end
            end
        end
        if collision then return true end
    end
    return false
end

-- Use actual road network bounds, not the original cluster's center.
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,road in ipairs(roadParts) do
    for _,p in ipairs(corners(road.CFrame,road.Size,0)) do
        minX=math.min(minX,p.X);maxX=math.max(maxX,p.X)
        minZ=math.min(minZ,p.Z);maxZ=math.max(maxZ,p.Z)
    end
end
local mapCenter=Vector2.new((minX+maxX)/2,(minZ+maxZ)/2)
local mapHalf=Vector2.new((maxX-minX)/2,(maxZ-minZ)/2)
local inset=65
print(string.format("[CityLayout54] Road area X %.0f..%.0f Z %.0f..%.0f",minX,maxX,minZ,maxZ))

-- Static buildings and other gameplay structures must remain untouched.
local obstacles={}
local function registerObstacle(model)
    if not model:IsA("Model") then return end
    local ok,cf,size=pcall(function()return model:GetBoundingBox() end)
    if ok and size.X>3 and size.Z>3 then
        table.insert(obstacles,{cf=cf,size=size})
    end
end
for _,folderName in ipairs({"Downtown","CityLocations"}) do
    local folder=city:FindFirstChild(folderName)
    if folder then
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") then registerObstacle(obj) end
        end
    end
end
for _,obj in ipairs(locations:GetChildren()) do
    if obj:IsA("Model") and not models[obj.Name] then registerObstacle(obj) end
end

-- SAT rectangle intersection, including rotations.
local function overlaps(cf,size,other,margin)
    local a=corners(cf,size,margin)
    local b=corners(other.cf,other.size,margin)
    local axes={
        Vector2.new(cf.RightVector.X,cf.RightVector.Z),
        Vector2.new(cf.LookVector.X,cf.LookVector.Z),
        Vector2.new(other.cf.RightVector.X,other.cf.RightVector.Z),
        Vector2.new(other.cf.LookVector.X,other.cf.LookVector.Z)
    }
    for _,axis in ipairs(axes) do
        if axis.Magnitude>0.001 then
            axis=axis.Unit
            local amin,amax,bmin,bmax=math.huge,-math.huge,math.huge,-math.huge
            for _,p in ipairs(a) do
                local d=p.X*axis.X+p.Z*axis.Y
                amin=math.min(amin,d);amax=math.max(amax,d)
            end
            for _,p in ipairs(b) do
                local d=p.X*axis.X+p.Z*axis.Y
                bmin=math.min(bmin,d);bmax=math.max(bmax,d)
            end
            if amax<bmin or bmax<amin then return false end
        end
    end
    return true
end

local function insideCity(cf,size)
    for _,p in ipairs(corners(cf,size,15)) do
        if p.X<minX+inset or p.X>maxX-inset
            or p.Z<minZ+inset or p.Z>maxZ-inset then return false end
    end
    return true
end

local occupied={}
for _,name in ipairs(names) do
    local m=models[name]
    if m then
        local cf,size=m:GetBoundingBox()
        occupied[name]={cf=cf,size=size}
    end
end

-- Grid of candidates across real city blocks, rather than expanding outside
-- the map. Prefer the requested quadrant, but only accept clear plots.
local moved=0
for _,name in ipairs(names) do
    local m=models[name]
    if m then
        local old=m:GetPivot()
        local offset,size=footprint(m)
        occupied[name]=nil
        local goal=targets[name]
        local desired=Vector2.new(
            mapCenter.X+goal.X/550*mapHalf.X*0.72,
            mapCenter.Y+goal.Y/550*mapHalf.Y*0.72
        )
        local candidates={}
        for x=minX+inset,maxX-inset,45 do
            for z=minZ+inset,maxZ-inset,45 do
                local p=Vector2.new(x,z)
                local distance=(p-desired).Magnitude
                table.insert(candidates,{x=x,z=z,score=distance})
            end
        end
        table.sort(candidates,function(a,b)return a.score<b.score end)
        local chosen=nil
        for _,candidate in ipairs(candidates) do
            local pivot=CFrame.new(candidate.x,old.Position.Y,candidate.z)*old.Rotation
            local cf=pivot*offset
            if insideCity(cf,size) and not intersectsRoad(cf,size) then
                local blocked=false
                for _,other in ipairs(obstacles) do
                    if overlaps(cf,size,other,12) then blocked=true;break end
                end
                if not blocked then
                    for _,other in pairs(occupied) do
                        if overlaps(cf,size,other,14) then blocked=true;break end
                    end
                end
                if not blocked then chosen=pivot;break end
            end
        end
        if chosen then
            m:PivotTo(chosen)
            m:SetAttribute("CityLayout54Moved",true)
            local cf,newSize=m:GetBoundingBox()
            occupied[name]={cf=cf,size=newSize}
            moved+=1
            print(string.format("[CityLayout54] %s -> X %.0f Z %.0f",name,cf.Position.X,cf.Position.Z))
        else
            occupied[name]={cf=old*offset,size=size}
            warn("[CityLayout54] No safe city plot for "..name.."; left unchanged")
        end
    end
end
print(string.format("[CityLayout54] %d/%d moved; road and downtown footprints protected; preview only",moved,count))
