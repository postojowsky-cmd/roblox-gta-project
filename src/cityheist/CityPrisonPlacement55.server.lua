-- City Heist step 55: preview-only prison placement.
-- Move the entire prison model without rebuilding guards, cells or scripts.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local W=game:GetService("Workspace")
local city=W:WaitForChild("CityBlockout",20)
if not city then return end
local roads=city:FindFirstChild("Roads")
local prison=W:FindFirstChild("CityPrison")
if not roads or not prison or not prison:IsA("Model") then
    warn("[Prison55] Missing road network or CityPrison; no changes")
    return
end
-- Let the city-layout script finish moving other buildings.
task.wait(4)
local roadParts={}
for _,part in ipairs(roads:GetDescendants()) do
    if part:IsA("BasePart") and part.Size.X>2 and part.Size.Z>2 then
        table.insert(roadParts,part)
    end
end
if #roadParts==0 then return end
local function rectangle(cf,size,extra)
    local hx=size.X/2+extra
    local hz=size.Z/2+extra
    return {
        cf:PointToWorldSpace(Vector3.new(-hx,0,-hz)),
        cf:PointToWorldSpace(Vector3.new(-hx,0,hz)),
        cf:PointToWorldSpace(Vector3.new(hx,0,-hz)),
        cf:PointToWorldSpace(Vector3.new(hx,0,hz))
    }
end
local function collides(aCF,aSize,bCF,bSize,margin)
    local a=rectangle(aCF,aSize,margin)
    local b=rectangle(bCF,bSize,margin)
    local axes={
        Vector2.new(aCF.RightVector.X,aCF.RightVector.Z),
        Vector2.new(aCF.LookVector.X,aCF.LookVector.Z),
        Vector2.new(bCF.RightVector.X,bCF.RightVector.Z),
        Vector2.new(bCF.LookVector.X,bCF.LookVector.Z)
    }
    for _,axis in ipairs(axes) do
        if axis.Magnitude>0.0001 then
            axis=axis.Unit
            local aMin,aMax,bMin,bMax=math.huge,-math.huge,math.huge,-math.huge
            for _,p in ipairs(a) do
                local v=p.X*axis.X+p.Z*axis.Y
                aMin=math.min(aMin,v);aMax=math.max(aMax,v)
            end
            for _,p in ipairs(b) do
                local v=p.X*axis.X+p.Z*axis.Y
                bMin=math.min(bMin,v);bMax=math.max(bMax,v)
            end
            if aMax<bMin or bMax<aMin then return false end
        end
    end
    return true
end
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,road in ipairs(roadParts) do
    for _,p in ipairs(rectangle(road.CFrame,road.Size,0)) do
        minX=math.min(minX,p.X);maxX=math.max(maxX,p.X)
        minZ=math.min(minZ,p.Z);maxZ=math.max(maxZ,p.Z)
    end
end
local original=prison:GetPivot()
local originalBounds,size=prison:GetBoundingBox()
local offset=original:ToObjectSpace(originalBounds)
local obstacleModels={}
for _,folderName in ipairs({"GameplayLocations","Downtown","CityLocations","CityGarages"}) do
    local folder=city:FindFirstChild(folderName)
    if folder then
        for _,obj in ipairs(folder:GetChildren()) do
            if obj:IsA("Model") then
                local cf,s=obj:GetBoundingBox()
                if s.X>3 and s.Z>3 then table.insert(obstacleModels,{cf=cf,size=s}) end
            end
        end
    end
end
local centerX=(minX+maxX)/2
local centerZ=(minZ+maxZ)/2
local candidates={}
local step=45
for x=minX+35,maxX-35,step do
    for z=minZ+35,maxZ-35,step do
        local nx=(x-centerX)/math.max(1,(maxX-minX)/2)
        local nz=(z-centerZ)/math.max(1,(maxZ-minZ)/2)
        local radial=math.sqrt(nx*nx+nz*nz)
        -- Prefer edge districts but not the literal edge of the world.
        local score=math.abs(radial-0.70)*500
        -- Prefer the prison's original side of the city where possible.
        score+=Vector2.new(x-original.Position.X,z-original.Position.Z).Magnitude*0.08
        table.insert(candidates,{x=x,z=z,score=score})
    end
end
table.sort(candidates,function(a,b)return a.score<b.score end)
local chosen=nil
for _,candidate in ipairs(candidates) do
    local pivot=CFrame.new(candidate.x,original.Position.Y,candidate.z)*original.Rotation
    local bounds=pivot*offset
    local valid=true
    -- The whole prison must be inside the mapped road network's perimeter.
    for _,p in ipairs(rectangle(bounds,size,20)) do
        if p.X<minX+35 or p.X>maxX-35 or p.Z<minZ+35 or p.Z>maxZ-35 then
            valid=false;break
        end
    end
    if valid then
        for _,road in ipairs(roadParts) do
            if collides(bounds,size,road.CFrame,road.Size,5) then valid=false;break end
        end
    end
    if valid then
        for _,other in ipairs(obstacleModels) do
            if collides(bounds,size,other.cf,other.size,10) then valid=false;break end
        end
    end
    if valid then
        -- Avoid isolated fields: require a road near the perimeter.
        local nearest=math.huge
        for _,road in ipairs(roadParts) do
            local dx=bounds.Position.X-road.Position.X
            local dz=bounds.Position.Z-road.Position.Z
            local d=math.sqrt(dx*dx+dz*dz)-math.max(size.X,size.Z)/2-math.max(road.Size.X,road.Size.Z)/2
            nearest=math.min(nearest,d)
        end
        if nearest<90 then chosen=pivot;break end
    end
end
if chosen then
    prison:PivotTo(chosen)
    prison:SetAttribute("CityPrison55Moved",true)
    print(string.format("[Prison55] Relocated entire prison to X %.0f Z %.0f; roads and buildings clear",chosen.Position.X,chosen.Position.Z))
else
    warn("[Prison55] No safe parcel for complete prison. Original position preserved; no forced overlap.")
end
