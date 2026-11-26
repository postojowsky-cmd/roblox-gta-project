-- Step 94: transactional Studio-only city replan using the saved prefab library.
local RS=game:GetService("RunService")
if not RS:IsStudio() then return end
local W=workspace
local SS=game:GetService("ServerStorage")
if W:GetAttribute("CityReplan94Running") then return end
print("[CityReplan94] REVISION 96: distributed city density and architectural variety")
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
local function collision(index,r,pad)
    for x=math.floor((r.x1-pad)/CELL),math.floor((r.x2+pad)/CELL) do
        for z=math.floor((r.z1-pad)/CELL),math.floor((r.z2+pad)/CELL) do
            local bucket=index[x..":"..z]
            if bucket then
                for _,b in ipairs(bucket) do
                    if intersects(r,b,pad) then return b end
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
-- Keep a reversible original snapshot in ServerStorage for this Play session.
local backup=Instance.new("Folder");backup.Name="CityReplan94Original";backup.Parent=SS
for _,f in ipairs(old) do f.Parent=backup end
local retired=Instance.new("Folder");retired.Name="OriginalDowntown";retired.Parent=backup
for _,m in ipairs(replaceable) do m.Parent=retired end
print("[CityReplan94] DOWNTOWN replaced:",#replaceable,"new central buildings:",centerCount)
for _,n in ipairs(names) do groups[n].Parent=W end
stage:Destroy()
-- Continuous terrain heightfield, with a broad green valley and irregular ridges.
-- Never write voxels inside the protected city/prison rectangle.
local terrain=W.Terrain
local x1,x2,z1,z2=outer.x1-55,outer.x2+55,outer.z1-55,outer.z2+55
local step=64
local extent=480
local chunks=0
local function height(x,z)
    local dx=math.max(x1-x,0,x-x2)
    local dz=math.max(z1-z,0,z-z2)
    local d=math.sqrt(dx*dx+dz*dz)
    if d<16 or d>extent then return nil end
    local ridge=215+65*math.noise(x/370,z/370,9)
    local width=105+25*math.noise(x/250,z/250,3)
    local envelope=math.exp(-((d-ridge)/width)^2)
    local peak=155+105*math.noise(x/210,z/210,14)+45*math.noise(x/85,z/85,7)
    local fade=math.clamp((d-16)/65,0,1)*math.clamp((extent-d)/80,0,1)
    return streetY-1+fade*(7+math.max(0,peak)*envelope+12*math.noise(x/42,z/42,5))
end
if x2-x1<4000 and z2-z1<4000 then
    for x=math.floor((x1-extent)/step)*step,x2+extent,step do
        for z=math.floor((z1-extent)/step)*step,z2+extent,step do
            if x+step<=x1 or x>=x2 or z+step<=z1 or z>=z2 then
                local region=Region3.new(Vector3.new(x,-8,z),Vector3.new(x+step,240,z+step)):ExpandToGrid(4)
                local materials,occupancy=terrain:ReadVoxels(region,4)
                local changed=false
                for ix=1,#materials do
                    for iz=1,#materials[ix][1] do
                        local wx,wz=x+(ix-.5)*4,z+(iz-.5)*4
                        local h=height(wx,wz)
                        if h then
                            for iy=1,#materials[ix] do
                                local wy=-8+(iy-.5)*4
                                local fill=math.clamp((h-wy)/4+.5,0,1)
                                if fill>occupancy[ix][iy][iz] then
                                    occupancy[ix][iy][iz]=fill
                                    materials[ix][iy][iz]=(wy>100 and wy<h-7) and Enum.Material.Rock or Enum.Material.Grass
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
else
    warn("[CityReplan94] Landscape skipped: anomalous extent")
end
print(string.format("[CityReplan94] DONE: %d buildings, %d central, 2 parking lots, 1 fuel station, 3 driveways, %d decorations, %d landscape chunks",total,centerCount,decor,chunks))
