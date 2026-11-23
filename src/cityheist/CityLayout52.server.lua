-- City Heist step 53: road-aware building placement (Studio Play preview only).
-- Never changes Roads, and never commits placement into the saved Studio map.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local workspace=game:GetService("Workspace")
local city=workspace:WaitForChild("CityBlockout",20)
local locations=city and city:WaitForChild("GameplayLocations",20)
local roads=city and city:FindFirstChild("Roads")
if not locations or not roads then
    warn("[CityLayout53] Missing GameplayLocations or Roads; preserving original positions")
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
    warn("[CityLayout53] No road parts detected: no buildings moved")
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

local function overlapsOther(cf,size,occupied)
    local p=cf.Position
    for _,other in ipairs(occupied) do
        local q=other.cf.Position
        local clearance=math.max(size.X,size.Z)/2+math.max(other.size.X,other.size.Z)/2+16
        if (Vector2.new(p.X-q.X,p.Z-q.Z)).Magnitude<clearance then return true end
    end
    return false
end

-- Preserve existing buildings as obstacles until they are relocated.
local occupied={}
for _,name in ipairs(names) do
    local m=models[name]
    if m then
        local cf,size=m:GetBoundingBox()
        occupied[name]={cf=cf,size=size}
    end
end
local moved=0
for _,name in ipairs(names) do
    local m=models[name]
    if m then
        local old=m:GetPivot()
        local offset,size=footprint(m)
        occupied[name]=nil
        local goal=targets[name]
        local chosen=nil
        -- First try the desired district, then search nearby grid plots.
        -- Every candidate must avoid road surfaces and all other buildings.
        for radius=0,660,110 do
            for dx=-radius,radius,110 do
                for dz=-radius,radius,110 do
                    if math.max(math.abs(dx),math.abs(dz))==radius then
                        local p=Vector3.new(center.X+goal.X+dx,old.Position.Y,center.Z+goal.Y+dz)
                        local pivot=CFrame.new(p)*old.Rotation
                        local boundsCF=pivot*offset
                        if not intersectsRoad(boundsCF,size) and not overlapsOther(boundsCF,size,occupied) then
                            chosen=pivot
                            break
                        end
                    end
                end
                if chosen then break end
            end
            if chosen then break end
        end
        if chosen then
            m:PivotTo(chosen)
            m:SetAttribute("CityLayout53Moved",true)
            local cf,newSize=m:GetBoundingBox()
            occupied[name]={cf=cf,size=newSize}
            moved+=1
            print(string.format("[CityLayout53] %s moved to X %.0f Z %.0f (road clear)",name,cf.Position.X,cf.Position.Z))
        else
            occupied[name]={cf=old*offset,size=size}
            warn("[CityLayout53] No safe plot for "..name.."; original location preserved")
        end
    end
end
print(string.format("[CityLayout53] %d/%d relocated; roads unchanged; preview only",moved,count))
