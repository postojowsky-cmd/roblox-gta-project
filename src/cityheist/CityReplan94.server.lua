-- Step 94: transactional Studio-only city replan using the saved prefab library.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=workspace
local SS=game:GetService("ServerStorage")
if W:GetAttribute("CityReplan94Running") then return end
W:SetAttribute("CityReplan94Running",true)
local names={"CityHeistPrefabCity74","CityHeistInfill81","CityHeistStreetscape79","CityHeistInfrastructure86","CityHeistAccess88"}
local old={}
for _,n in ipairs(names) do
    local f=W:FindFirstChild(n)
    if not f or not f:GetAttribute("CityHeistBaked90") then
        warn("[CityReplan94] Saved source missing: "..n);return
    end
    table.insert(old,f)
end
local city=W:WaitForChild("CityBlockout",30)
local roads=city and city:WaitForChild("Roads",30)
local ground=city and city:WaitForChild("Ground",30)
if not roads or not ground then warn("[CityReplan94] Missing roads/ground");return end
task.wait(12)
local function bounds(obj)
    local lo=Vector3.new(math.huge,math.huge,math.huge)
    local hi=-lo
    local parts=obj:IsA("BasePart") and {obj} or obj:GetDescendants()
    for _,p in ipairs(parts) do
        if p:IsA("BasePart") then
            local h=p.Size/2
            for _,x in ipairs({-h.X,h.X}) do
                for _,y in ipairs({-h.Y,h.Y}) do
                    for _,z in ipairs({-h.Z,h.Z}) do
                        local v=p.CFrame:PointToWorldSpace(Vector3.new(x,y,z))
                        lo=Vector3.new(math.min(lo.X,v.X),math.min(lo.Y,v.Y),math.min(lo.Z,v.Z))
                        hi=Vector3.new(math.max(hi.X,v.X),math.max(hi.Y,v.Y),math.max(hi.Z,v.Z))
                    end
                end
            end
        end
    end
    return lo,hi
end
local function rect(lo,hi)
    return {x1=lo.X,x2=hi.X,z1=lo.Z,z2=hi.Z}
end
local function intersects(a,b,pad)
    return a.x1<b.x2+pad and a.x2>b.x1-pad and a.z1<b.z2+pad and a.z2>b.z1-pad
end
local function insideOld(p)
    for _,f in ipairs(old) do if p:IsDescendantOf(f) then return true end end
    return false
end
local roadRects,segments={},{}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>6 and p.Size.Z>6 then
        local lo,hi=bounds(p)
        local r=rect(lo,hi)
        table.insert(roadRects,r)
        minX=math.min(minX,r.x1);maxX=math.max(maxX,r.x2)
        minZ=math.min(minZ,r.z1);maxZ=math.max(maxZ,r.z2)
        local dx,dz=r.x2-r.x1,r.z2-r.z1
        if math.max(dx,dz)>=35 and math.max(dx,dz)>=math.min(dx,dz)*2 and math.min(dx,dz)>=10 then
            r.y=hi.Y
            r.horizontal=dx>dz
            table.insert(segments,r)
        end
    end
end
if #segments<4 then warn("[CityReplan94] No usable street segments");return end
local static={}
local outer={x1=minX,x2=maxX,z1=minZ,z2=maxZ}
for _,p in ipairs(W:GetDescendants()) do
    if p:IsA("BasePart") and p.Anchored and not insideOld(p)
        and not p:IsDescendantOf(ground) and not p:IsDescendantOf(roads) then
        local lo,hi=bounds(p)
        -- Ignore only broad, flat ground slabs, not building walls or props.
        if not (p.Size.Y<=3 and p.Size.X>=150 and p.Size.Z>=150 and hi.Y<=3) then
            if p.CanCollide or p.Transparency<0.95 then
                table.insert(static,rect(lo,hi))
                outer.x1=math.min(outer.x1,lo.X);outer.x2=math.max(outer.x2,hi.X)
                outer.z1=math.min(outer.z1,lo.Z);outer.z2=math.max(outer.z2,hi.Z)
            end
        end
    end
end
local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances={ground}
local function surface(x,z)
    local hit=W:Raycast(Vector3.new(x,500,z),Vector3.new(0,-1200,0),ray)
    return hit and hit.Normal.Y>.9 and hit.Position.Y or nil
end
local reserved={}
local function clear(r,roadCheck,pad)
    for _,b in ipairs(static) do if intersects(r,b,pad) then return false end end
    for _,b in ipairs(reserved) do if intersects(r,b,pad) then return false end end
    if roadCheck then
        for _,b in ipairs(roadRects) do if intersects(r,b,pad) then return false end end
    end
    return true
end
local function flat(r)
    local y=surface((r.x1+r.x2)/2,(r.z1+r.z2)/2)
    if not y then return nil end
    for _,x in ipairs({r.x1,r.x2}) do
        for _,z in ipairs({r.z1,r.z2}) do
            local v=surface(x,z)
            if not v or math.abs(v-y)>.65 then return nil end
        end
    end
    return y
end
local slots={}
for _,r in ipairs(segments) do
    local a,b=r.horizontal and r.x1 or r.z1,r.horizontal and r.x2 or r.z2
    for t=a+18,b-18,12 do
        for _,side in ipairs({-1,1}) do
            local x,z,normal
            if r.horizontal then
                x=t;z=side==1 and r.z2 or r.z1;normal=Vector3.new(0,0,side)
            else
                x=side==1 and r.x2 or r.x1;z=t;normal=Vector3.new(side,0,0)
            end
            table.insert(slots,{edge=Vector3.new(x,0,z),normal=normal,y=r.y})
        end
    end
end
table.sort(slots,function(a,b)
    local cx,cz=(minX+maxX)/2,(minZ+maxZ)/2
    local da=(a.edge.X-cx)^2+(a.edge.Z-cz)^2
    local db=(b.edge.X-cx)^2+(b.edge.Z-cz)^2
    if da~=db then return da<db end
    if a.edge.X~=b.edge.X then return a.edge.X<b.edge.X end
    return a.edge.Z<b.edge.Z
end)
local stage=Instance.new("Folder")
stage.Name="CityReplan94Staging"
stage.Parent=SS
local groups={}
for _,n in ipairs(names) do
    local f=Instance.new("Folder");f.Name=n;f.Parent=stage
    f:SetAttribute("CityHeistBaked90",true)
    groups[n]=f
end
local function abort(reason)
    warn("[CityReplan94] ABORT: "..reason.."; original city retained")
    stage:Destroy()
end
local function part(parent,name,size,cf,color,material,solid)
    local p=Instance.new("Part")
    p.Name=name;p.Size=size;p.CFrame=cf;p.Anchored=true
    p.Color=color;p.Material=material;p.CanCollide=solid~=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent
    return p
end
local function place(source,dest,service)
    local m=source:Clone()
    for _,p in ipairs(m:GetDescendants()) do
        if p:IsA("LuaSourceContainer") then p:Destroy()
        elseif p:IsA("BasePart") then p.Anchored=true end
    end
    local lastHeading=nil
    for _,s in ipairs(slots) do
        -- +Z points toward the street for parking aisle access.
        local heading=CFrame.lookAt(Vector3.zero,s.normal)
        if lastHeading~=s.normal then
            m:PivotTo(heading)
            lastHeading=s.normal
        end
        local lo,hi=bounds(m)
        local size=hi-lo
        local depth=s.normal.X~=0 and size.X or size.Z
        local gap=service and 9 or 12
        local center=s.edge+s.normal*(depth/2+gap)
        local r={x1=center.X-size.X/2,x2=center.X+size.X/2,z1=center.Z-size.Z/2,z2=center.Z+size.Z/2}
        if r.x1>=minX and r.x2<=maxX and r.z1>=minZ and r.z2<=maxZ and clear(r,true,4) then
            local y=flat(r)
            local corridor=nil
            if service and y then
                local a=s.edge+s.normal*.4
                local b=s.edge+s.normal*(gap+.8)
                corridor={x1=math.min(a.X,b.X)-(s.normal.Z~=0 and 8 or 0),
                    x2=math.max(a.X,b.X)+(s.normal.Z~=0 and 8 or 0),
                    z1=math.min(a.Z,b.Z)-(s.normal.X~=0 and 8 or 0),
                    z2=math.max(a.Z,b.Z)+(s.normal.X~=0 and 8 or 0)}
                if not clear(corridor,true,0) or not flat(corridor) or math.abs(s.y-y)>1.2 then y=nil end
            end
            if y then
                local delta=Vector3.new(center.X-(lo.X+hi.X)/2,y-lo.Y+.05,center.Z-(lo.Z+hi.Z)/2)
                m:PivotTo(m:GetPivot()+delta)
                m.Parent=dest
                table.insert(reserved,r)
                if corridor then
                    table.insert(reserved,corridor)
                    local p=s.edge+s.normal*(gap/2)
                    local cf=CFrame.lookAt(Vector3.new(p.X,y+.14,p.Z),Vector3.new(p.X,y+.14,p.Z)+s.normal)
                    part(groups.CityHeistAccess88,"Driveway_"..m.Name,Vector3.new(16,.24,gap+1),cf,Color3.fromRGB(55,58,61),Enum.Material.Asphalt)
                    local anchor=part(groups.CityHeistAccess88,"Sign_"..m.Name,Vector3.one,CFrame.new(center.X,y+22,center.Z),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false)
                    anchor.Transparency=1;anchor.CanQuery=false
                    local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(160,42);gui.AlwaysOnTop=true;gui.MaxDistance=350;gui.Parent=anchor
                    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(25,40,55);label.TextColor3=Color3.new(1,1,1);label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Text=m.Name=="FuelStation" and "STACJA PALIW" or m.Name:gsub("PublicParking_","PARKING ");label.Parent=gui
                end
                print(string.format("[CityReplan94] PLACED %s X %.1f Z %.1f",m.Name,center.X,center.Z))
                return true
            end
        end
    end
    m:Destroy()
    return false
end
local infra=old[4]
for _,n in ipairs({"FuelStation","PublicParking_1","PublicParking_2"}) do
    local source=infra:FindFirstChild(n)
    if not source or not source:IsA("Model") or not place(source,groups.CityHeistInfrastructure86,true) then abort("No safe connected plot for "..n);return end
end
local total=0
for i=1,2 do
    local models={}
    for _,m in ipairs(old[i]:GetChildren()) do if m:IsA("Model") then table.insert(models,m) end end
    table.sort(models,function(a,b)
        local al,ah=bounds(a);local bl,bh=bounds(b)
        local av=(ah.X-al.X)*(ah.Z-al.Z);local bv=(bh.X-bl.X)*(bh.Z-bl.Z)
        if av==bv then return a.Name<b.Name end
        return av>bv
    end)
    for _,m in ipairs(models) do
        if not place(m,groups[names[i]],false) then abort("No safe plot for "..m.Name);return end
        total+=1
    end
    groups[names[i]]:SetAttribute("PlacementComplete",true)
    groups[names[i]]:SetAttribute("BuildingCount",#models)
end
if total~=28 then abort("Expected 28 buildings, found "..total);return end
-- Place trees/lights/benches only on verified roadside pockets, reusing saved models.
local decor=0
for _,obj in ipairs(old[3]:GetChildren()) do
    if obj:IsA("Model") then
        if place(obj,groups.CityHeistStreetscape79,false) then decor+=1 end
    end
end
-- Keep a reversible original snapshot in ServerStorage for this Play session.
local backup=Instance.new("Folder");backup.Name="CityReplan94Original";backup.Parent=SS
for _,f in ipairs(old) do f.Parent=backup end
for _,n in ipairs(names) do groups[n].Parent=W end
stage:Destroy()
-- Natural perimeter outside ALL detected static geometry, including prison.
-- Terrain is preview-only; no Terrain:Clear and no changes inside the city.
local terrain=W.Terrain
local x1,x2,z1,z2=outer.x1-180,outer.x2+180,outer.z1-180,outer.z2+180
local rng=Random.new(94)
local hills=0
local function hill(x,z)
    local radius=rng:NextNumber(68,94)
    terrain:FillBall(Vector3.new(x,20,z),radius,Enum.Material.Rock)
    terrain:FillBall(Vector3.new(x,radius*.48,z),radius*.65,Enum.Material.Grass)
    hills+=1
end
if x2-x1<5000 and z2-z1<5000 then
    for x=x1,x2,55 do hill(x,z1);hill(x,z2) end
    for z=z1,z2,55 do hill(x1,z);hill(x2,z) end
    hill(x2,z2)
else
    warn("[CityReplan94] Perimeter skipped: anomalous world extent")
end
print(string.format("[CityReplan94] DONE: %d buildings, 2 parking lots, 1 fuel station, 3 driveways, %d decorations, %d mountain clusters",total,decor,hills))
