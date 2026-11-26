-- Step 94: transactional Studio-only city replan using the saved prefab library.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=workspace
local SS=game:GetService("ServerStorage")
if W:GetAttribute("CityReplan94Running") then return end
print("[CityReplan94] REVISION 101: joined pavements, mountain ridges and forest")
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
-- Only decorative models in the explicitly named Downtown folder may be replaced.
local downtown=city:FindFirstChild("Downtown")
local replaceable={}
if downtown then
    for _,m in ipairs(downtown:GetChildren()) do
        if m:IsA("Model") then
            local safe=true
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("LuaSourceContainer") or v:IsA("ProximityPrompt") or v:IsA("ClickDetector") or v:IsA("Seat") or v:IsA("SpawnLocation") then safe=false;break end
            end
            if safe then table.insert(replaceable,m) end
        end
    end
end
print("[CityReplan94] DOWNTOWN decorative models eligible:",#replaceable)
local function insideOld(p)
    for _,m in ipairs(replaceable) do if p:IsDescendantOf(m) then return true end end
    for _,f in ipairs(old) do if p:IsDescendantOf(f) then return true end end
    return false
end
local roadRects,segments,roadSurfaces={},{},{}
local minX,maxX,minZ,maxZ=math.huge,-math.huge,math.huge,-math.huge
for _,p in ipairs(roads:GetDescendants()) do
    if p:IsA("BasePart") and p.Size.X>6 and p.Size.Z>6 then
        local lo,hi=bounds(p)
        local r=rect(lo,hi)
        local dx,dz=r.x2-r.x1,r.z2-r.z1
        local n=p.Name:lower()
        local plot=n:find("sidewalk",1,true) or n:find("pavement",1,true) or n:find("plot",1,true) or n:find("block",1,true) or n:find("curb",1,true)
        local strip=math.max(dx,dz)>=35 and math.max(dx,dz)>=math.min(dx,dz)*2 and math.min(dx,dz)>=10
        local junction=n:find("intersection",1,true) or n:find("junction",1,true) or n:find("crossroad",1,true)
        -- Large square block slabs are buildable surfaces, not traffic lanes.
        local slab=not strip and not junction and math.min(dx,dz)>=55 and math.max(dx,dz)/math.min(dx,dz)<2 and hi.Y-lo.Y<=3
        if (plot or slab) and hi.Y-lo.Y<=3 then
            if p.CanQuery then table.insert(roadSurfaces,p) end
            print("[CityReplan94] PLOT SURFACE",p.Name,math.floor(dx),math.floor(dz))
        else
            table.insert(roadRects,r)
            minX=math.min(minX,r.x1);maxX=math.max(maxX,r.x2)
            minZ=math.min(minZ,r.z1);maxZ=math.max(maxZ,r.z2)
            if strip then
                r.y=hi.Y;r.horizontal=dx>dz
                table.insert(segments,r)
            end
        end
    end
end
if #segments<4 then warn("[CityReplan94] No usable street segments");return end
-- Relocate existing gameplay models, never clone or replace their scripts/prompts.
-- Translate by whole plot offsets to preserve entrance orientation and relative elevation.
local locations=city:FindFirstChild("GameplayLocations")
local servicePlots={}
for _,p in ipairs(roadSurfaces) do
    if p.Size.X>=100 and p.Size.Z>=100 then
        local lo,hi=bounds(p)
        table.insert(servicePlots,{x=(lo.X+hi.X)/2,z=(lo.Z+hi.Z)/2,r=rect(lo,hi)})
    end
end
local serviceMoved=0
if locations then
    local serviceTargets={Bank_1={-500,-500},Bank_2={500,-500},Bank_3={500,500},
        Shop_1={-500,500},Shop_2={-300,-300},Shop_3={300,300},Shop_4={300,-300},
        Police_1={-500,100},Police_2={500,100},Dealership_1={-100,-500},Dealership_2={100,500}}
    local keys={}
    for n in pairs(serviceTargets) do table.insert(keys,n) end
    table.sort(keys)
    for _,n in ipairs(keys) do
        local m=locations:FindFirstChild(n)
        if not m or not m:IsA("Model") then continue end
        local lo,hi=bounds(m)
        local center=(lo+hi)/2
        local origin=nil;local dist=math.huge
        for _,p in ipairs(servicePlots) do
            local d=(p.x-center.X)^2+(p.z-center.Z)^2
            if d<dist then origin=p;dist=d end
        end
        if not origin then continue end
        local target=serviceTargets[n]
        local candidates=table.clone(servicePlots)
        table.sort(candidates,function(a,b)
            return (a.x-target[1])^2+(a.z-target[2])^2<(b.x-target[1])^2+(b.z-target[2])^2
        end)
        local obstacles={}
        for _,p in ipairs(W:GetDescendants()) do
            if p:IsA("BasePart") and not p:IsA("Terrain") and p.Anchored and not insideOld(p)
                and not p:IsDescendantOf(m) and not p:IsDescendantOf(roads) and not p:IsDescendantOf(ground) then
                local l,h=bounds(p)
                if h.Y>lo.Y+.6 and l.Y<hi.Y and not (h.Y-l.Y<1 and p.Size.X>=100 and p.Size.Z>=100) then
                    table.insert(obstacles,rect(l,h))
                end
            end
        end
        local moved=false
        for _,p in ipairs(candidates) do
            local dx,dz=p.x-origin.x,p.z-origin.z
            local rr={x1=lo.X+dx,x2=hi.X+dx,z1=lo.Z+dz,z2=hi.Z+dz}
            local blocked=false
            for _,b in ipairs(roadRects) do if intersects(rr,b,0) then blocked=true;break end end
            if not blocked then
                for _,b in ipairs(obstacles) do if intersects(rr,b,3) then blocked=true;break end end
            end
            if not blocked then
                for _,other in ipairs(locations:GetChildren()) do
                    if other~=m and other:IsA("Model") and other.Name:match("^"..n:match("^%a+").."_") then
                        local ol,oh=bounds(other)
                        local oc=(ol+oh)/2
                        if Vector2.new(center.X+dx-oc.X,center.Z+dz-oc.Z).Magnitude<260 then blocked=true;break end
                    end
                end
            end
            if not blocked then
                if dx~=0 or dz~=0 then m:PivotTo(m:GetPivot()+Vector3.new(dx,0,dz));serviceMoved+=1 end
                print(string.format("[CityReplan94] SERVICE100 %s X %.0f Z %.0f",n,center.X+dx,center.Z+dz))
                moved=true;break
            end
        end
        if not moved then warn("[CityReplan94] SERVICE100 retained (no safe separated plot): "..n) end
        task.wait()
    end
end
local static={}
local support={ground,W.Terrain}
for _,p in ipairs(roadSurfaces) do table.insert(support,p) end
local elevations={}
for _,s in ipairs(segments) do table.insert(elevations,s.y) end
table.sort(elevations)
local streetY=elevations[math.ceil(#elevations/2)]
local ignored=0
local largest={}
local function isFlatSurface(p,lo,hi)
    if hi.Y-lo.Y>3 or p.Size.X<4 or p.Size.Z<4 or hi.Y>streetY+2 or hi.Y<streetY-5 then return false end
    local n=p.Name:lower()
    if p:IsDescendantOf(city:FindFirstChild("GameplayLocations") or ground) and not p:IsDescendantOf(ground) then return false end
    return n:find("sidewalk",1,true) or n:find("pavement",1,true) or n:find("plot",1,true) or n:find("ground",1,true) or n:find("baseplate",1,true) or n:find("lot",1,true) or n:find("curb",1,true) or (p.Parent==city and p.Size.X>=20 and p.Size.Z>=20)
end
local outer={x1=minX,x2=maxX,z1=minZ,z2=maxZ}
for _,p in ipairs(W:GetDescendants()) do
    if p:IsA("BasePart") and not p:IsA("Terrain") and p.Anchored and not insideOld(p)
        and not p:IsDescendantOf(ground) and not p:IsDescendantOf(roads) then
        local lo,hi=bounds(p)
        local dx,dz=hi.X-lo.X,hi.Z-lo.Z
        local broadFloor=dx>=100 and dz>=100 and hi.Y<=streetY+.8 and hi.Y>=streetY-5
        local skyOrEffect=not p.CanCollide and (dx>=200 or dz>=200 or p.Transparency>=.95)
        if isFlatSurface(p,lo,hi) or broadFloor then
            if p.CanQuery then table.insert(support,p) end
            ignored+=1
        elseif hi.Y<=streetY-.15 or lo.Y>streetY+150 or skyOrEffect then
            ignored+=1
        elseif p.CanCollide or p.Transparency<.95 then
            local b=rect(lo,hi)
            b.name=p:GetFullName()
            b.loY=lo.Y;b.hiY=hi.Y
            table.insert(static,b)
            if dx*dz>10000 then table.insert(largest,b) end
            outer.x1=math.min(outer.x1,lo.X);outer.x2=math.max(outer.x2,hi.X)
            outer.z1=math.min(outer.z1,lo.Z);outer.z2=math.max(outer.z2,hi.Z)
        end
    end
end
table.sort(largest,function(a,b)return (a.x2-a.x1)*(a.z2-a.z1)>(b.x2-b.x1)*(b.z2-b.z1) end)
print(string.format("[CityReplan94] FILTER streetY=%.2f ignored=%d",streetY,ignored))
for i=1,math.min(8,#largest) do
    local b=largest[i]
    print(string.format("[CityReplan94] LARGE %s | X %.0f..%.0f Z %.0f..%.0f Y %.1f..%.1f",b.name,b.x1,b.x2,b.z1,b.z2,b.loY,b.hiY))
end
local ray=RaycastParams.new()
ray.FilterType=Enum.RaycastFilterType.Include
ray.FilterDescendantsInstances=support
local function surface(x,z)
    local hit=W:Raycast(Vector3.new(x,500,z),Vector3.new(0,-1200,0),ray)
    return hit and hit.Normal.Y>.9 and hit.Position.Y or nil
end
local reserved={}
-- Spatial hash: inspect only obstacles in cells touched by the candidate.
local CELL=64
local function indexRect(index,b)
    for x=math.floor(b.x1/CELL),math.floor(b.x2/CELL) do
        for z=math.floor(b.z1/CELL),math.floor(b.z2/CELL) do
            local key=x..":"..z
            local bucket=index[key]
            if not bucket then bucket={};index[key]=bucket end
            table.insert(bucket,b)
        end
    end
end
local staticIndex,roadIndex,reservedIndex={},{},{}
for i,b in ipairs(static) do
    indexRect(staticIndex,b)
    if i%300==0 then task.wait() end
end
for _,b in ipairs(roadRects) do indexRect(roadIndex,b) end
local function reserve(b)
    table.insert(reserved,b)
    indexRect(reservedIndex,b)
end
local function collision(index,r,pad,ignoreWalk)
    for x=math.floor((r.x1-pad)/CELL),math.floor((r.x2+pad)/CELL) do
        for z=math.floor((r.z1-pad)/CELL),math.floor((r.z2+pad)/CELL) do
            local bucket=index[x..":"..z]
            if bucket then
                for _,b in ipairs(bucket) do
                    if not (ignoreWalk and b.walk) and intersects(r,b,pad) then return b end
                end
            end
        end
    end
    return nil
end
local rejectReasons={}
local function blockedBy(key)
    rejectReasons[key]=(rejectReasons[key] or 0)+1
    return false
end
local function clear(r,roadCheck,pad)
    if roadCheck and collision(roadIndex,r,pad) then return blockedBy("Road footprint") end
    if collision(reservedIndex,r,pad) then return blockedBy("Reserved plot") end
    local b=collision(staticIndex,r,pad)
    if b then return blockedBy(b.name) end
    return true
end
local function flat(r)
    local y=surface((r.x1+r.x2)/2,(r.z1+r.z2)/2)
    if not y then return nil end
    for _,x in ipairs({r.x1,r.x2}) do
        for _,z in ipairs({r.z1,r.z2}) do
            local v=surface(x,z)
            if not v or math.abs(v-y)>1.5 then return nil end
        end
    end
    return y
end
-- Connect street ends with a perimeter loop where the existing map is clear.
local ring={}
local function ringSegment(horizontal,a,b,axis)
    local width=26
    local rr=horizontal and {x1=a,x2=b,z1=axis-width/2,z2=axis+width/2}
        or {x1=axis-width/2,x2=axis+width/2,z1=a,z2=b}
    if collision(staticIndex,rr,2) then return end
    rr.horizontal=horizontal;rr.y=streetY
    table.insert(ring,rr);table.insert(segments,rr);table.insert(roadRects,rr);indexRect(roadIndex,rr)
end
local lx,hx,lz,hz=minX+15,maxX-15,minZ+15,maxZ-15
ringSegment(true,lx-13,hx+13,lz)
ringSegment(true,lx-13,hx+13,hz)
ringSegment(false,lz+13,hz-13,lx)
ringSegment(false,lz+13,hz-13,hx)
local slots={}
for _,r in ipairs(segments) do
    local a,b=r.horizontal and r.x1 or r.z1,r.horizontal and r.x2 or r.z2
    for t=a+12,b-12,6 do
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
local ringFolder=Instance.new("Folder");ringFolder.Name="PerimeterRoads100";ringFolder.Parent=groups.CityHeistInfrastructure86
for _,s in ipairs(ring) do
    local x,z=(s.x1+s.x2)/2,(s.z1+s.z2)/2
    part(ringFolder,"LoopRoad",Vector3.new(s.x2-s.x1,.35,s.z2-s.z1),CFrame.new(x,streetY+.025-.175,z),Color3.fromRGB(62,64,68),Enum.Material.Asphalt,true)
    local a,b=s.horizontal and s.x1 or s.z1,s.horizontal and s.x2 or s.z2
    for t=a+18,b-18,24 do
        local px,pz=s.horizontal and t or x,s.horizontal and z or t
        local rr={x1=px-1,x2=px+1,z1=pz-1,z2=pz+1}
        local crossing=false
        for _,other in ipairs(roadRects) do if other~=s and intersects(rr,other,8) then crossing=true;break end end
        if not crossing then part(ringFolder,"LaneMark",s.horizontal and Vector3.new(10,.04,.3) or Vector3.new(.3,.04,10),CFrame.new(px,streetY+.05,pz),Color3.fromRGB(230,205,105),Enum.Material.SmoothPlastic,false) end
    end
end
print("[CityReplan94] LOOP100 sides:",#ring)
local function place(source,dest,service,plot)
    table.clear(rejectReasons)
    local rejected={bounds=0,blocked=0,ground=0,access=0}
    local m=source:Clone()
    for _,p in ipairs(m:GetDescendants()) do
        if p:IsA("LuaSourceContainer") then p:Destroy()
        elseif p:IsA("BasePart") then p.Anchored=true end
    end
    local orientations={}
    for _,normal in ipairs({Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis}) do
        local heading=CFrame.lookAt(Vector3.zero,normal)
        m:PivotTo(heading)
        local lo,hi=bounds(m)
        orientations[normal.X~=0 and (normal.X>0 and 1 or 2) or (normal.Z>0 and 3 or 4)]={heading=heading,lo=lo,hi=hi}
    end
    for slotIndex,s in ipairs(slots) do
        if plot and (s.edge.X<plot.x1-8 or s.edge.X>plot.x2+8 or s.edge.Z<plot.z1-8 or s.edge.Z>plot.z2+8) then continue end
        if slotIndex%100==0 then task.wait() end
        -- +Z points toward the street for parking aisle access.
        local orientation=orientations[s.normal.X~=0 and (s.normal.X>0 and 1 or 2) or (s.normal.Z>0 and 3 or 4)]
        local lo,hi=orientation.lo,orientation.hi
        local size=hi-lo
        local depth=s.normal.X~=0 and size.X or size.Z
        for _,gap in ipairs(service and {4,9,15,24,36} or {5,12,20,30}) do
        local center=s.edge+s.normal*(depth/2+gap)
        local r={x1=center.X-size.X/2,x2=center.X+size.X/2,z1=center.Z-size.Z/2,z2=center.Z+size.Z/2}
        if r.x1>=minX and r.x2<=maxX and r.z1>=minZ and r.z2<=maxZ and (not plot or (r.x1>=plot.x1+4 and r.x2<=plot.x2-4 and r.z1>=plot.z1+4 and r.z2<=plot.z2-4)) and clear(r,true,2) then
            local y=flat(r)
            if not y then rejected.ground+=1 end
            local corridor=nil
            if service and y then
                local a=s.edge+s.normal*.4
                local b=s.edge+s.normal*(gap+.8)
                corridor={x1=math.min(a.X,b.X)-(s.normal.Z~=0 and 8 or 0),
                    x2=math.max(a.X,b.X)+(s.normal.Z~=0 and 8 or 0),
                    z1=math.min(a.Z,b.Z)-(s.normal.X~=0 and 8 or 0),
                    z2=math.max(a.Z,b.Z)+(s.normal.X~=0 and 8 or 0)}
                if not clear(corridor,false,0) or math.abs(s.y-y)>3 then
                    rejected.access+=1;y=nil
                end
            end
            if y then
                local delta=Vector3.new(center.X-(lo.X+hi.X)/2,y-lo.Y+.05,center.Z-(lo.Z+hi.Z)/2)
                m:PivotTo(orientation.heading+delta)
                m.Parent=dest
                reserve(r)
                if corridor then
                    reserve(corridor)
                    local p=s.edge+s.normal*(gap/2)
                    local a=Vector3.new(s.edge.X,s.y+.10,s.edge.Z)
                    local endPos=s.edge+s.normal*(gap+.6)
                    local b=Vector3.new(endPos.X,y+.19,endPos.Z)
                    local cf=CFrame.lookAt((a+b)/2,b)
                    part(groups.CityHeistAccess88,"Driveway_"..m.Name,Vector3.new(16,.22,(b-a).Magnitude+.5),cf,Color3.fromRGB(55,58,61),Enum.Material.Asphalt)
                    local anchor=part(groups.CityHeistAccess88,"Sign_"..m.Name,Vector3.one,CFrame.new(center.X,y+22,center.Z),Color3.new(1,1,1),Enum.Material.SmoothPlastic,false)
                    anchor.Transparency=1;anchor.CanQuery=false
                    local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(160,42);gui.AlwaysOnTop=true;gui.MaxDistance=350;gui.Parent=anchor
                    local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundColor3=Color3.fromRGB(25,40,55);label.TextColor3=Color3.new(1,1,1);label.TextScaled=true;label.Font=Enum.Font.GothamBold;label.Text=m.Name=="FuelStation" and "STACJA PALIW" or m.Name:gsub("PublicParking_","PARKING ");label.Parent=gui
                end
                print(string.format("[CityReplan94] PLACED %s X %.1f Z %.1f",m.Name,center.X,center.Z))
                return true
            end
        else
            rejected.blocked+=1
        end
        end
    end
    warn(string.format("[CityReplan94] REJECT %s | slots=%d blocked/bounds=%d ground=%d access=%d",source.Name,#slots,rejected.blocked,rejected.ground,rejected.access))
    local reasons={}
    for name,count in pairs(rejectReasons) do table.insert(reasons,{name=name,count=count}) end
    table.sort(reasons,function(a,b)return a.count>b.count end)
    for i=1,math.min(5,#reasons) do
        print("[CityReplan94] BLOCKER",reasons[i].count,reasons[i].name)
    end
    m:Destroy()
    return false
end
print(string.format('[CityReplan94] GRID X %.0f..%.0f Z %.0f..%.0f | roads=%d slots=%d obstacles=%d support=%d',minX,maxX,minZ,maxZ,#roadRects,#slots,#static,#support))
local infra=old[4]
for _,n in ipairs({"FuelStation","PublicParking_1","PublicParking_2"}) do
    local source=infra:FindFirstChild(n)
    if not source or not source:IsA("Model") or not place(source,groups.CityHeistInfrastructure86,true) then abort("No safe connected plot for "..n);return end
end
local parkingCount=2
-- Spread additional lots over outer quadrants before decorative construction.
for i,goal in ipairs({{-450,-450},{450,-450},{-450,450},{450,450},{600,0},{-600,0}}) do
    local candidates=table.clone(servicePlots)
    table.sort(candidates,function(a,b)return (a.x-goal[1])^2+(a.z-goal[2])^2<(b.x-goal[1])^2+(b.z-goal[2])^2 end)
    local source=infra.PublicParking_1:Clone()
    source.Name="PublicParking_"..(i+2)
    source:ScaleTo(source:GetScale()*.72)
    for j=1,math.min(3,#candidates) do
        if place(source,groups.CityHeistInfrastructure86,true,candidates[j].r) then parkingCount+=1;break end
    end
    source:Destroy()
end
print("[CityReplan94] PARKING100 total:",parkingCount)
local total=0
local centerCount=0
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
        task.wait()
        if not place(m,groups[names[i]],false) then abort("No safe plot for "..m.Name);return end
        total+=1
        local placed=groups[names[i]]:FindFirstChild(m.Name)
        if placed then
            local low,high=bounds(placed)
            local pos=(low+high)/2
            if math.abs(pos.X-(minX+maxX)/2)<450 and math.abs(pos.Z-(minZ+maxZ)/2)<450 then centerCount+=1 end
        end
    end
    groups[names[i]]:SetAttribute("PlacementComplete",true)
    groups[names[i]]:SetAttribute("BuildingCount",#models)
end
if #replaceable==0 then abort("No verified decorative Downtown models; refusing edge-only rebuild");return end
if centerCount<8 then abort("Only "..centerCount.." new buildings in center; refusing edge-only rebuild");return end
if total~=28 then abort("Expected 28 buildings, found "..total);return end
-- Add original, asset-independent architectural models to individual city blocks.
local rng=Random.new(9601)
local palettes={
    Color3.fromRGB(192,183,165),Color3.fromRGB(135,147,155),
    Color3.fromRGB(155,99,76),Color3.fromRGB(218,215,205),
    Color3.fromRGB(106,117,128),Color3.fromRGB(171,160,139)
}
local types={"Apartment","Office","Townhouse","Retail","Hotel","Warehouse"}
local function architecture(kind,id,central,compact)
    local m=Instance.new("Model")
    m.Name=kind.."_"..string.format("%03d",id)
    local w=compact and 24 or rng:NextInteger(32,48)
    local d=compact and 24 or rng:NextInteger(28,42)
    local floors=kind=="Office" and (central and rng:NextInteger(6,10) or rng:NextInteger(3,5))
        or kind=="Hotel" and rng:NextInteger(4,6)
        or kind=="Apartment" and rng:NextInteger(3,5)
        or kind=="Townhouse" and rng:NextInteger(2,3) or 1
    local fh=kind=="Warehouse" and 13 or 8
    local h=floors*fh
    local wall=palettes[rng:NextInteger(1,#palettes)]
    local trim=Color3.fromRGB(55,62,68)
    local glass=Color3.fromRGB(77,119,143)
    local function p(n,s,x,y,z,col,mat,solid)
        return part(m,n,s,CFrame.new(x,y,z),col,mat,solid)
    end
    p("Foundation",Vector3.new(w+2,.5,d+2),0,.25,0,trim,Enum.Material.Concrete)
    p("Structure",Vector3.new(w,h,d),0,h/2+.5,0,wall,kind=="Townhouse" and Enum.Material.Brick or Enum.Material.Concrete)
    p("Roof",Vector3.new(w+1,.8,d+1),0,h+.9,0,trim,Enum.Material.Concrete)
    for level=1,floors do
        local y=(level-.5)*fh+.5
        for _,side in ipairs({-1,1}) do
            for j=1,math.floor(w/7) do
                local x=(j-(math.floor(w/7)+1)/2)*7
                p("WindowFrame",Vector3.new(4.8,5,.22),x,y,side*(d/2+.12),trim,Enum.Material.Metal,false)
                p("Glazing",Vector3.new(4.2,4.4,.24),x,y,side*(d/2+.28),glass,Enum.Material.Glass,false)
                if kind=="Apartment" and level>1 and side==1 and j%2==1 then
                    p("Balcony",Vector3.new(6,.4,3),x,y-2.7,d/2+1.5,wall,Enum.Material.Concrete)
                    p("BalconyRail",Vector3.new(6,2,.18),x,y-1.5,d/2+3,trim,Enum.Material.Metal)
                end
            end
            for j=1,math.floor(d/8) do
                local z=(j-(math.floor(d/8)+1)/2)*8
                p("SideWindow",Vector3.new(.25,4.5,4.5),side*(w/2+.15),y,z,glass,Enum.Material.Glass,false)
            end
        end
        if level>1 then
            p("FacadeBand",Vector3.new(w+.5,.35,d+.5),0,(level-1)*fh+.5,0,trim,Enum.Material.Concrete,false)
        end
    end
    p("Entrance",Vector3.new(kind=="Warehouse" and 12 or 5,6,.5),0,3.5,d/2+.4,trim,Enum.Material.Metal,false)
    p("Canopy",Vector3.new(9,.5,3),0,7,d/2+1.5,trim,Enum.Material.Metal)
    if kind=="Retail" or kind=="Hotel" or kind=="Warehouse" then
        local sign=p("Sign",Vector3.new(w*.7,2.8,.4),0,math.min(h-1,7.5),d/2+.7,trim,Enum.Material.SmoothPlastic,false)
        local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Back;gui.Parent=sign
        local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.TextColor3=Color3.new(1,1,1);label.TextScaled=true;label.Font=Enum.Font.GothamBold
        label.Text=kind=="Hotel" and "CITY HOTEL" or kind=="Warehouse" and "LOGISTICS" or ({"CAFE","MARKET","BISTRO","PHARMACY"})[id%4+1];label.Parent=gui
    end
    if floors>1 then
        p("RoofEquipment",Vector3.new(8,3,6),w*.2,h+2.5,-d*.2,trim,Enum.Material.Metal)
    end
    m.WorldPivot=CFrame.new(0,0,0)
    return m
end
local plots={}
for _,p in ipairs(roadSurfaces) do
    if p.Name:lower():find("sidewalk",1,true) and p.Size.X>=100 and p.Size.Z>=100 then
        local lo,hi=bounds(p);local b=rect(lo,hi)
        b.name=p.Name
        b.distance=math.max(math.abs((lo.X+hi.X)/2),math.abs((lo.Z+hi.Z)/2))
        table.insert(plots,b)
    end
end
table.sort(plots,function(a,b) if a.distance==b.distance then return a.name<b.name end return a.distance>b.distance end)
local extra=0
for pass=1,3 do
    for i,plot in ipairs(plots) do
        if total>=110 then break end
        local central=plot.distance<350
        local kind=types[(i+pass*2-1)%#types+1]
        if central and kind=="Warehouse" then kind="Office" end
        if not central and kind=="Office" then kind="Apartment" end
        local source=architecture(kind,extra+1,central,pass==3)
        if place(source,groups.CityHeistInfill81,false,plot) then
            extra+=1;total+=1
            if central then centerCount+=1 end
        end
        source:Destroy()
        task.wait()
    end
end
groups.CityHeistInfill81:SetAttribute("BuildingCount",#groups.CityHeistInfill81:GetChildren())
print("[CityReplan94] DENSITY96 extra:",extra,"total:",total,"blocks:",#plots)
-- Step 98: fill unused interiors of outer plots, not just roadside strips.
local residentialRng=Random.new(9801)
local function residential(kind,id)
    local m=Instance.new("Model")
    m.Name=kind.."_"..string.format("%03d",id)
    local house=kind=="DetachedHouse"
    local block=kind=="CourtyardBlock"
    local w=house and residentialRng:NextInteger(20,26) or block and 42 or 28
    local d=house and 22 or block and 24 or 26
    local floors=house and residentialRng:NextInteger(1,2) or block and residentialRng:NextInteger(4,6) or 3
    local h=floors*8
    local wall=palettes[residentialRng:NextInteger(1,#palettes)]
    local trim=Color3.fromRGB(62,66,70)
    local glass=Color3.fromRGB(74,110,132)
    local function p(n,s,x,y,z,col,mat,solid,rot)
        return part(m,n,s,CFrame.new(x,y,z)*(rot or CFrame.identity),col,mat,solid)
    end
    p("Lot",Vector3.new(w+8,.35,d+12),0,.175,2,house and Color3.fromRGB(91,117,71) or Color3.fromRGB(151,151,146),house and Enum.Material.Grass or Enum.Material.Concrete)
    p("Building",Vector3.new(w,h,d),0,h/2+.35,0,wall,block and Enum.Material.Brick or Enum.Material.Concrete)
    if house then
        local rise=5
        local half=w/2+1
        local slope=math.atan2(rise,half)
        local roofColor=({Color3.fromRGB(94,53,42),trim,Color3.fromRGB(113,78,62)})[id%3+1]
        for _,s in ipairs({-1,1}) do
            p("PitchedRoof",Vector3.new(math.sqrt(half^2+rise^2),.65,d+2),s*half/2,h+.35+rise/2,0,roofColor,Enum.Material.Slate,true,CFrame.Angles(0,0,-s*slope))
            local gable=Instance.new("WedgePart")
            gable.Name="Gable";gable.Anchored=true;gable.Size=Vector3.new(d,rise,w/2)
            gable.Color=wall;gable.Material=Enum.Material.Brick
            gable.CFrame=CFrame.new(s*w/4,h+.35+rise/2,0)*CFrame.Angles(0,-s*math.pi/2,0)
            gable.Parent=m
        end
        p("Chimney",Vector3.new(2.5,5,2.5),w*.22,h+4,-d*.22,wall,Enum.Material.Brick)
        p("FrontWalk",Vector3.new(4,.12,7),0,.42,d/2+3,trim,Enum.Material.Concrete)
        p("GarageDoor",Vector3.new(7,5,.25),-w*.26,3,d/2+.15,trim,Enum.Material.Metal,false)
    else
        p("FlatRoof",Vector3.new(w+1,.8,d+1),0,h+.75,0,trim,Enum.Material.Concrete)
        p("RoofPlant",Vector3.new(7,2.5,5),w*.25,h+2,-d*.2,trim,Enum.Material.Metal)
    end
    for level=1,floors do
        local y=(level-.5)*8+.35
        for _,s in ipairs({-1,1}) do
            for j=1,math.floor(w/7) do
                local x=(j-(math.floor(w/7)+1)/2)*7
                if not (level==1 and s==1 and (math.abs(x)<3 or (house and x<0))) then
                    p("WindowFrame",Vector3.new(4.8,4.8,.2),x,y,s*(d/2+.13),trim,Enum.Material.Metal,false)
                    p("Window",Vector3.new(4.1,4.1,.22),x,y,s*(d/2+.27),glass,Enum.Material.Glass,false)
                end
                if block and level>1 and j%2==1 then
                    p("Balcony",Vector3.new(6,.35,3),x,y-2.5,s*(d/2+1.5),trim,Enum.Material.Concrete)
                    p("Rail",Vector3.new(6,1.8,.18),x,y-1.45,s*(d/2+3),trim,Enum.Material.Metal)
                end
            end
            for j=1,math.floor(d/8) do
                local z=(j-(math.floor(d/8)+1)/2)*8
                p("SideWindow",Vector3.new(.24,4,4),s*(w/2+.15),y,z,glass,Enum.Material.Glass,false)
            end
        end
        if block and level>1 then
            p("FloorBand",Vector3.new(w+.4,.3,d+.4),0,(level-1)*8+.35,0,Color3.fromRGB(184,179,168),Enum.Material.Concrete,false)
        end
    end
    p("Entry",Vector3.new(4.5,6,.3),0,3.35,d/2+.2,trim,Enum.Material.Metal,false)
    p("EntryCanopy",Vector3.new(6,.35,2),0,6.7,d/2+1,trim,Enum.Material.Metal)
    m.WorldPivot=CFrame.identity
    return m
end
local function placeInterior(m,plot,house)
    local lo,hi=bounds(m)
    local sx,sz=hi.X-lo.X,hi.Z-lo.Z
    local candidates={}
    for x=plot.x1+9+sx/2,plot.x2-9-sx/2,8 do
        for z=plot.z1+9+sz/2,plot.z2-9-sz/2,8 do
            local cx,cz=(plot.x1+plot.x2)/2,(plot.z1+plot.z2)/2
            local distance=math.abs(x-cx)+math.abs(z-cz)
            table.insert(candidates,{x=x,z=z,score=house and -distance or distance})
        end
    end
    table.sort(candidates,function(a,b) if a.score==b.score then if a.x==b.x then return a.z<b.z end return a.x<b.x end return a.score<b.score end)
    for _,v in ipairs(candidates) do
        local r={x1=v.x-sx/2,x2=v.x+sx/2,z1=v.z-sz/2,z2=v.z+sz/2}
        if clear(r,true,house and 3 or 5) then
            local y=flat(r)
            if y then
                m:PivotTo(CFrame.new(v.x-(lo.X+hi.X)/2,y-lo.Y+.05,v.z-(lo.Z+hi.Z)/2))
                m.Parent=groups.CityHeistInfill81
                reserve(r)
                return true
            end
        end
    end
    return false
end
local added98=0
local counts98={DetachedHouse=0,CourtyardBlock=0,NeighborhoodApartment=0}
-- Outer corner neighborhoods favor houses; outer side blocks favor brick apartments.
-- Reserve a generous gap between buildings and leave existing gameplay parcels intact.
for pass=1,4 do
    for _,plot in ipairs(plots) do
        if plot.distance<350 or added98>=80 then continue end
        local px,pz=(plot.x1+plot.x2)/2,(plot.z1+plot.z2)/2
        local corner=math.abs(px)>350 and math.abs(pz)>350
        local kind=corner and "DetachedHouse" or (pass<=2 and "CourtyardBlock" or "NeighborhoodApartment")
        local m=residential(kind,added98+1)
        if placeInterior(m,plot,kind=="DetachedHouse") then
            added98+=1;total+=1;counts98[kind]+=1
        else
            m:Destroy()
        end
        task.wait()
    end
end
groups.CityHeistInfill81:SetAttribute("BuildingCount",#groups.CityHeistInfill81:GetChildren())
print(string.format("[CityReplan94] DISTRICTS98 added=%d houses=%d blocks=%d apartments=%d total=%d",added98,counts98.DetachedHouse,counts98.CourtyardBlock,counts98.NeighborhoodApartment,total))
-- Place trees/lights/benches only on verified roadside pockets, reusing saved models.
local decor=0
-- Spread existing street details across the map rather than filling the center first.
local decorRng=Random.new(9602)
for i=#slots,2,-1 do local j=decorRng:NextInteger(1,i);slots[i],slots[j]=slots[j],slots[i] end
local details=old[3]:GetChildren()
local assigned={}
for detailIndex,obj in ipairs(details) do
    if detailIndex%20==0 then task.wait() end
    if obj:IsA("Model") then
        if place(obj,groups.CityHeistStreetscape79,false) then decor+=1 end
    elseif obj:IsA("BasePart") and obj.Name=="StreetDetailFootprint" then
        local m=Instance.new("Model");m.Name="StreetDetail_"..tostring(decor+1)
        for _,p in ipairs(details) do
            if p:IsA("BasePart") and p.Name~="StreetDetailFootprint" and not assigned[p] then
                local d=Vector2.new(p.Position.X-obj.Position.X,p.Position.Z-obj.Position.Z).Magnitude
                if d<=obj.Size.X/2+.2 then p:Clone().Parent=m;assigned[p]=true end
            end
        end
        if #m:GetChildren()>0 then
            m.WorldPivot=CFrame.new(obj.Position)
            if place(m,groups.CityHeistStreetscape79,false) then decor+=1 end
        end
        m:Destroy()
    end
end
-- Step 99: raised sidewalks on clear roadside strips, then outer frontage infill.
local walks=Instance.new("Folder")
walks.Name="RaisedSidewalks101"
walks.Parent=groups.CityHeistStreetscape79
local walkCount,walkLength=0,0
local walkRuns={}
local function sidewalkRun(s,side,a,b,y)
    if b-a<2 then return end
    local edge=s.horizontal and (side==1 and s.z2 or s.z1) or (side==1 and s.x2 or s.x1)
    local mid=(a+b)/2
    local width=6
    local x,z=s.horizontal and mid or edge+side*(width/2+.2),s.horizontal and edge+side*(width/2+.2) or mid
    local size=s.horizontal and Vector3.new(b-a,.9,width) or Vector3.new(width,.9,b-a)
    part(walks,"Sidewalk",size,CFrame.new(x,y-.45,z),Color3.fromRGB(170,169,164),Enum.Material.Concrete,true)
    local kx,kz=s.horizontal and mid or edge+side*.48,s.horizontal and edge+side*.48 or mid
    local ks=s.horizontal and Vector3.new(b-a,.72,.55) or Vector3.new(.55,.72,b-a)
    part(walks,"Curb",ks,CFrame.new(kx,y-.29,kz),Color3.fromRGB(180,180,176),Enum.Material.Concrete,true)
    table.insert(walkRuns,{horizontal=s.horizontal,x=x,z=z,a=a,b=b,y=y})
    walkCount+=1;walkLength+=b-a
end
-- Explicitly protect named vehicle access surfaces, even when the earlier scan
-- classified them as flat support.
local accessIndex={}
for _,p in ipairs(W:GetDescendants()) do
    if p:IsA("BasePart") and not insideOld(p) and not p:IsA("Terrain") then
        local n=p.Name:lower()
        if n:find("driveway",1,true) or n:find("entrancepath",1,true) or n:find("parking",1,true) or n:find("accessroad",1,true) then
            local lo,hi=bounds(p)
            indexRect(accessIndex,rect(lo,hi))
        end
    end
end
-- East apron: buildings and small lots only on verified clear, flat land
-- near the new loop. Keep prison access and the entire prison footprint clear.
local apronCount=0
local apron=Instance.new("Folder");apron.Name="EastDistrict100";apron.Parent=groups.CityHeistInfrastructure86
if #ring==4 then
    for _,z in ipairs({-660,-540,-420,360,480,600}) do
        local x=maxX+42
        local rr={x1=x-22,x2=x+22,z1=z-23,z2=z+23}
        local link={x1=maxX-2,x2=x-22+.5,z1=z-8,z2=z+8}
        local y=flat(rr)
        if y and math.abs(y-streetY)<1 and clear(rr,true,8) and clear(link,false,2)
            and not collision(accessIndex,rr,10) and not collision(accessIndex,link,4) then
            local m=residential(apronCount%2==0 and "DetachedHouse" or "NeighborhoodApartment",2000+apronCount)
            local lo,hi=bounds(m)
            if hi.X-lo.X<=44 and hi.Z-lo.Z<=46 then
                m:PivotTo(CFrame.new(x-(lo.X+hi.X)/2,y-lo.Y+.05,z-(lo.Z+hi.Z)/2))
                m.Parent=groups.CityHeistInfill81;reserve(rr);reserve(link);indexRect(accessIndex,link)
                part(apron,"Access",Vector3.new(link.x2-link.x1,.25,16),CFrame.new((link.x1+link.x2)/2,streetY-.08,z),Color3.fromRGB(64,65,68),Enum.Material.Asphalt,true)
                apronCount+=1;total+=1
            else m:Destroy() end
        end
    end
end
print("[CityReplan94] APRON100 buildings:",apronCount,"services moved:",serviceMoved)
for _,s in ipairs(segments) do
    local first,last=s.horizontal and s.x1 or s.z1,s.horizontal and s.x2 or s.z2
    for _,side in ipairs({-1,1}) do
        local edge=s.horizontal and (side==1 and s.z2 or s.z1) or (side==1 and s.x2 or s.x1)
        local start,finish,top=nil,nil,nil
        local function flush()
            if start then
                sidewalkRun(s,side,start,finish,top)
                local e1,e2=math.min(edge+side*.2,edge+side*6.2),math.max(edge+side*.2,edge+side*6.2)
                local rr=s.horizontal and {x1=start,x2=finish,z1=e1,z2=e2} or {x1=e1,x2=e2,z1=start,z2=finish}
                rr.walk=true;reserve(rr)
            end
            start,finish,top=nil,nil,nil
        end
        for a=first,last-.01,2 do
            local b=math.min(a+2,last)
            local e1,e2=math.min(edge+side*.2,edge+side*6.2),math.max(edge+side*.2,edge+side*6.2)
            local r=s.horizontal and {x1=a,x2=b,z1=e1,z2=e2} or {x1=e1,x2=e2,z1=a,z2=b}
            -- Do not reserve individual samples: neighboring samples share a boundary.
            local y=clear(r,true,.1) and not collision(accessIndex,r,1) and flat(r) or nil
            if y and math.abs(y-s.y)<=.65 then
                local t=math.max(s.y+.48,y+.22)
                if start and math.abs(t-top)>.12 then flush() end
                if not start then start=a;top=t end
                finish=b
            else
                flush()
            end
        end
        flush()
    end
    task.wait()
end
print(string.format("[CityReplan94] SIDEWALKS100 runs=%d length=%.0f studs",walkCount,walkLength))
local perimeter={}
local mx,mz=(minX+maxX)/2,(minZ+maxZ)/2
for _,s in ipairs(slots) do
    local axis=s.normal.X~=0 and s.edge.X-mx or s.edge.Z-mz
    local sign=s.normal.X~=0 and s.normal.X or s.normal.Z
    if axis*sign>=550 then table.insert(perimeter,s) end
end
table.sort(perimeter,function(a,b)
    if a.edge.X~=b.edge.X then return a.edge.X<b.edge.X end
    if a.edge.Z~=b.edge.Z then return a.edge.Z<b.edge.Z end
    if a.normal.X~=b.normal.X then return a.normal.X<b.normal.X end
    return a.normal.Z<b.normal.Z
end)
local edgeCount=0
local edgeKinds={DetachedHouse=0,CourtyardBlock=0,NeighborhoodApartment=0,Retail=0}
local function edgePlace(m,s)
    local heading=CFrame.lookAt(Vector3.zero,s.normal)
    m:PivotTo(heading)
    local lo,hi=bounds(m)
    local size=hi-lo
    local depth=s.normal.X~=0 and size.X or size.Z
    for _,gap in ipairs({10,18,28,40}) do
        local v=s.edge+s.normal*(depth/2+gap)
        local r={x1=v.X-size.X/2,x2=v.X+size.X/2,z1=v.Z-size.Z/2,z2=v.Z+size.Z/2}
        if r.x1>=minX-25 and r.x2<=maxX+25 and r.z1>=minZ-25 and r.z2<=maxZ+25
            and clear(r,true,4) and not collision(accessIndex,r,6) then
            local y=flat(r)
            if y and math.abs(y-s.y)<=1.5 then
                m:PivotTo(heading+Vector3.new(v.X-(lo.X+hi.X)/2,y-lo.Y+.05,v.Z-(lo.Z+hi.Z)/2))
                m.Parent=groups.CityHeistInfill81
                reserve(r)
                return true
            end
        end
    end
    return false
end
-- Round-robin sides so one neighborhood cannot consume the entire budget.
local sides={{},{},{},{}}
for _,s in ipairs(perimeter) do
    local i=s.normal.X~=0 and (s.normal.X>0 and 1 or 2) or (s.normal.Z>0 and 3 or 4)
    table.insert(sides[i],s)
end
local maxSlots=0
for _,side in ipairs(sides) do maxSlots=math.max(maxSlots,#side) end
for i=1,maxSlots,4 do
    if edgeCount>=64 then break end
    for _,side in ipairs(sides) do
        local s=side[i]
        if not s or edgeCount>=64 then continue end
        local id=1000+edgeCount
        local kind=({"DetachedHouse","CourtyardBlock","DetachedHouse","NeighborhoodApartment","Retail"})[math.floor(i/4)%5+1]
        local m=kind=="Retail" and architecture("Retail",id,false,true) or residential(kind,id)
        if edgePlace(m,s) then
            edgeCount+=1;total+=1;edgeKinds[kind]+=1
        else
            m:Destroy()
        end
    end
    task.wait()
end
groups.CityHeistInfill81:SetAttribute("BuildingCount",#groups.CityHeistInfill81:GetChildren())
print(string.format("[CityReplan94] EDGE99 added=%d houses=%d blocks=%d apartments=%d retail=%d total=%d",edgeCount,edgeKinds.DetachedHouse,edgeKinds.CourtyardBlock,edgeKinds.NeighborhoodApartment,edgeKinds.Retail,total))
-- Finish the public realm after all buildings have been placed.
do
    local corners=0
    local seen={}
    for _,h in ipairs(walkRuns) do
        if not h.horizontal then continue end
        for _,v in ipairs(walkRuns) do
            if v.horizontal or math.abs(h.y-v.y)>.15 then continue end
            local x,z=v.x,h.z
            local dx=math.max(h.a-x,0,x-h.b)
            local dz=math.max(v.a-z,0,z-v.b)
            if dx>10 or dz>10 then continue end
            local r={x1=math.min(x-3,h.b),x2=math.max(x+3,h.a),z1=math.min(z-3,v.b),z2=math.max(z+3,v.a)}
            local key=string.format("%.1f:%.1f",x,z)
            if not seen[key] and not collision(roadIndex,r,0) and not collision(staticIndex,r,0)
                and not collision(reservedIndex,r,0,true) and not collision(accessIndex,r,0) then
                local y=math.min(h.y,v.y)-.015
                part(walks,"JoinedCorner",Vector3.new(r.x2-r.x1,.9,r.z2-r.z1),CFrame.new((r.x1+r.x2)/2,y-.45,(r.z1+r.z2)/2),Color3.fromRGB(170,169,164),Enum.Material.Concrete,true)
                seen[key]=true;corners+=1
            end
        end
    end
    -- Existing plot slabs retain their exact height and footprint, including
    -- the support beneath buildings. Remove stud/grid surface styling.
    local paved=0
    for _,p in ipairs(roadSurfaces) do
        if p:IsA("Part") then p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth end
        p.Material=Enum.Material.Concrete
        p.Color=Color3.fromRGB(157,158,155)
        paved+=1
    end
    print("[CityReplan94] PAVEMENT101 corners:",corners,"paved plots:",paved)
end
-- Keep a reversible original snapshot in ServerStorage for this Play session.
local backup=Instance.new("Folder");backup.Name="CityReplan94Original";backup.Parent=SS
for _,f in ipairs(old) do f.Parent=backup end
local retired=Instance.new("Folder");retired.Name="OriginalDowntown";retired.Parent=backup
for _,m in ipairs(replaceable) do m.Parent=retired end
print("[CityReplan94] DOWNTOWN replaced:",#replaceable,"new central buildings:",centerCount)
for _,n in ipairs(names) do groups[n].Parent=W end
stage:Destroy()
-- Step 97: continuous foundation and asymmetrical mountain foothills.
local terrain=W.Terrain
local x1,x2,z1,z2=outer.x1-35,outer.x2+35,outer.z1-35,outer.z2+35
-- Explicitly include the complete relocated prison and its parking/driveway.
for _,name in ipairs({"CityPrison","CityPrisonGenerated"}) do
    local obj=W:FindFirstChild(name)
    if obj then
        local lo,hi=bounds(obj)
        if lo.X<hi.X and lo.Z<hi.Z then
            x1=math.min(x1,lo.X-35);x2=math.max(x2,hi.X+35)
            z1=math.min(z1,lo.Z-35);z2=math.max(z2,hi.Z+35)
        end
    end
end
local step=64
local extent=760
local chunks=0
local floorY=streetY-.25
local floorColor=Color3.fromRGB(112,116,122)
local floorMaterial=Enum.Material.Concrete
local bestArea=0
local groundParts=ground:IsA("BasePart") and {ground} or ground:GetDescendants()
for _,p in ipairs(groundParts) do
    if p:IsA("BasePart") and p.Anchored and p.CanCollide then
        local lo,hi=bounds(p)
        local area=(hi.X-lo.X)*(hi.Z-lo.Z)
        if hi.Y<=streetY+.02 and hi.Y>=streetY-3 and area>bestArea and p.Material~=Enum.Material.Grass then
            bestArea=area
            floorY=math.min(hi.Y-.035,streetY-.12)
            floorColor=Color3.fromRGB(145,147,145);floorMaterial=Enum.Material.Concrete
        end
    end
end
local cx,cz=(x1+x2)/2,(z1+z2)/2
local function height(x,z)
    local dx=math.max(x1-x,0,x-x2)
    local dz=math.max(z1-z,0,z-z2)
    local d=math.sqrt(dx*dx+dz*dz)
    if d<=0 then
        -- Green foothill fingers in the empty east apron, not on prison/access.
        if x>maxX+95 and math.abs(z)>360 then
            local r={x1=x-14,x2=x+14,z1=z-14,z2=z+14}
            if not collision(staticIndex,r,12) and not collision(reservedIndex,r,12) and not collision(roadIndex,r,12) and not collision(accessIndex,r,12) then
                local fade=math.clamp((x-maxX-95)/160,0,1)*math.clamp((math.abs(z)-360)/170,0,1)
                fade=fade*fade*(3-2*fade)
                return floorY+fade*(115+55*math.noise(x/100,z/100,17)+25*math.noise(x/45,z/45,8))
            end
        end
        return nil
    end
    local a=math.atan2(z-cz,x-cx)
    -- Different ridge distances and lengths around the city, not a uniform ring.
    local reach=550+105*math.sin(a*3+.7)+65*math.cos(a*5-1.1)
    if d>reach then return nil end
    local ridge=240+95*math.sin(a*2+.4)+55*math.noise(x/390,z/390,9)
    local width=120+45*math.noise(x/260,z/260,3)
    local envelope=math.exp(-((d-ridge)/width)^2)
    local peak=190+115*math.noise(x/210,z/210,14)+65*math.noise(x/95,z/95,7)
    local fade=math.clamp(d/100,0,1)*math.clamp((reach-d)/110,0,1)
    local spur=math.max(0,math.sin(a*4+1.2))*55*math.exp(-((d-390)/150)^2)
    return floorY-.4+fade*(5+math.max(0,peak)*envelope+spur+16*math.noise(x/55,z/55,5))
end
if x2-x1<4000 and z2-z1<4000 then
    local foundation=Instance.new("Folder")
    foundation.Name="CityLandscape97"
    foundation.Parent=W
    -- One continuous low slab beneath all existing city and prison surfaces.
    -- Existing roads, foundations and parking remain above it.
    part(foundation,"ContinuousCityFoundation",Vector3.new(x2-x1,6,z2-z1),
        CFrame.new(cx,floorY-3,cz),floorColor,floorMaterial,true)
    print(string.format("[CityReplan94] FOUNDATION97 X %.0f..%.0f Z %.0f..%.0f top %.2f",x1,x2,z1,z2,floorY))
    for x=math.floor((x1-extent)/step)*step,x2+extent,step do
        for z=math.floor((z1-extent)/step)*step,z2+extent,step do
            -- Process boundary-crossing chunks too, but never change protected columns.
            if x+step>maxX+95 or not (x>=x1 and x+step<=x2 and z>=z1 and z+step<=z2) then
                local region=Region3.new(Vector3.new(x,-12,z),Vector3.new(x+step,320,z+step)):ExpandToGrid(4)
                local materials,occupancy=terrain:ReadVoxels(region,4)
                local changed=false
                for ix=1,#materials do
                    for iz=1,#materials[ix][1] do
                        local wx,wz=x+(ix-.5)*4,z+(iz-.5)*4
                        local h=height(wx,wz)
                        if h then
                            for iy=1,#materials[ix] do
                                local wy=-12+(iy-.5)*4
                                local fill=math.clamp((h-wy)/4+.5,0,1)
                                if fill>occupancy[ix][iy][iz] then
                                    occupancy[ix][iy][iz]=fill
                                    materials[ix][iy][iz]=(wy>115 and wy<h-6) and Enum.Material.Rock or Enum.Material.Grass
                                    changed=true
                                end
                            end
                        end
                    end
                end
                if changed then terrain:WriteVoxels(region,4,materials,occupancy);chunks+=1 end
                task.wait()
            end
        end
    end
    print("[CityReplan94] LANDSCAPE101 irregular foothills complete:",chunks)
    -- Reuse complete tree models already available in the place. Prefer mesh
    -- trees; never import an unverified asset ID or copy foreign scripts.
    do
        local templates={}
        local function consider(m)
            if not m:IsA("Model") or not m.Name:lower():find("tree",1,true) then return end
            local lo,hi=bounds(m)
            if hi.Y-lo.Y<5 or hi.Y-lo.Y>100 or hi.X-lo.X>60 or hi.Z-lo.Z>60 then return end
            local mesh=false
            for _,p in ipairs(m:GetDescendants()) do
                if p:IsA("LuaSourceContainer") or p:IsA("ProximityPrompt") or p:IsA("Seat") then return end
                if p:IsA("MeshPart") or p:IsA("SpecialMesh") then mesh=true end
            end
            if mesh and m.Archivable and #templates<12 then table.insert(templates,m) end
        end
        for _,root in ipairs({SS,W}) do
            for _,m in ipairs(root:GetDescendants()) do consider(m) end
        end
        local meshCount=#templates
        local fallback
        if #templates==0 then
            -- Saved streetscape tree geometry, without urban planter or soil.
            local source=old[3]
            local trunk=source:FindFirstChild("TreeTrunk",true)
            if trunk and trunk:IsA("BasePart") then
                local crown
                for _,p in ipairs(source:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name=="TreeCrown" and (p.Position-trunk.Position).Magnitude<15 then crown=p;break end
                end
                if crown then
                    fallback=Instance.new("Model");fallback.Name="SavedTree"
                    trunk:Clone().Parent=fallback;crown:Clone().Parent=fallback
                    table.insert(templates,fallback)
                end
            end
        end
        local forest=Instance.new("Folder");forest.Name="MountainForest101";forest.Parent=foundation
        local rng=Random.new(10127)
        local terrainRay=RaycastParams.new()
        terrainRay.FilterType=Enum.RaycastFilterType.Include
        terrainRay.FilterDescendantsInstances={terrain}
        local count=0
        if #templates>0 then
            for x=x1-extent,x2+extent,30 do
                for z=z1-extent,z2+extent,30 do
                    local wx,wz=x+rng:NextNumber(-10,10),z+rng:NextNumber(-10,10)
                    local h=height(wx,wz)
                    if not h or h<floorY+3 then continue end
                    local rr={x1=wx-12,x2=wx+12,z1=wz-12,z2=wz+12}
                    if collision(staticIndex,rr,10) or collision(roadIndex,rr,10) or collision(reservedIndex,rr,5) or collision(accessIndex,rr,10) then continue end
                    local hit=W:Raycast(Vector3.new(wx,400,wz),Vector3.new(0,-430,0),terrainRay)
                    if not hit or hit.Normal.Y<.48 or hit.Position.Y<floorY+3 then continue end
                    local m=templates[rng:NextInteger(1,#templates)]:Clone()
                    if not m then continue end
                    m:ScaleTo(m:GetScale()*rng:NextNumber(.8,1.55))
                    m:PivotTo(CFrame.Angles(0,rng:NextNumber(0,math.pi*2),0))
                    local lo,hi=bounds(m)
                    m:PivotTo(m:GetPivot()+Vector3.new(wx-(lo.X+hi.X)/2,hit.Position.Y-lo.Y-.35,wz-(lo.Z+hi.Z)/2))
                    for _,p in ipairs(m:GetDescendants()) do
                        if p:IsA("BasePart") then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end
                    end
                    m.Parent=forest;count+=1
                    if count>=1800 then break end
                end
                if count>=1800 then break end
                task.wait()
            end
        end
        if fallback then fallback:Destroy() end
        print("[CityReplan94] FOREST101 trees:",count,"mesh templates:",meshCount)
    end
else
    warn("[CityReplan94] Landscape skipped: anomalous extent")
end
print(string.format("[CityReplan94] DONE: %d buildings, %d central, %d parking lots, 1 fuel station, %d decorations, %d landscape chunks",total,centerCount,parkingCount,decor,chunks))
